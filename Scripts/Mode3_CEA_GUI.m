classdef Mode3_CEA_GUI

    %CEA用
    %CEA_CUI版の手続きをほぼ自動化したCEA_GUIを大部分そのままmatlabに移植したもの.
    %違いとして、窒素と温度の入力、また酸化剤と燃料を区別して入力するなどの対応を行った.
    %改良としては、更に柔軟な入力モードとして、カスタム入力(残りの要素や追加元素を含めて入力可能)モードを作るという案がある.
    %作業自体は.inpファイルを作ってFCEA2を実行し、.outからCstarとgammaを作る、と全く変わらない.
    
    properties
        filename
    end

    methods
        %手続き関数.
        %main関数ではこれが呼び出される.
        function Class = run(Class,~)
            %.inpファイル生成のためのデータ取得.
            disp('CEAの入力ファイル作成操作を開始します。')
            Class = Class.Input();
            disp('CEAの入力ファイル作成操作が完了しました。')
            %FCEA2.exeの遠隔操作+ファイル抽出.
            disp('CEA.exeを実行します。')
            Class = Class.CEA();
            disp('CEA_GUIモードが完了しました。')
        end

        function Class = Input(Class)
            %入力ダイアログの生成.
            prompt = {'燃料:','酸化剤:','h,kj/mol:','C:','O:','H:','N:','t,k:'};
            dlgtitle = '入力';
            def = {'PP','N2O','-713.01204','30','0','60','0','297'};
            answ = inputdlg(prompt, dlgtitle, [1 40], def);
            if isempty(answ); return; end
            Class.filename = string(answ{1})+string(answ{2});
            E = answ{3}; C = answ{4}; O = answ{5}; H = answ{6}; N = answ{7}; T = answ{8};
            textTag  = ".inp";

            % 確認ダイアログ（Yes/No）
            answer = questdlg(Class.filename + textTag + "を生成します。よろしいですか？", ...
                "確認", "Yes", "No", "No");
            if answer ~= "Yes"; return; end

            % CEAText（C#の "    h,kj/mol=..." と同じ並び）
            ceaText = "    h,kj/mol=" + string(E) + "  C " + string(C) + ...
                " O " + string(O) + " H " + string(H) + " N " + string(N);

            filePath = "../CEAexec-win/" + Class.filename + textTag;
            % Shift_JISで書き込み
            fid = fopen(filePath, 'w', 'n', 'Shift_JIS');
            if fid < 0
                error("ファイルを作成できませんでした: %s", filePath);
            end
            cleaner = onCleanup(@() fclose(fid)); % 例外でも確実に閉じる

            fprintf(fid, "%s\n", "problem  case=test  o/f=0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,8.5,9,9.5,10,100");
            fprintf(fid, "%s\n", "    rocket  frozen  nfz=2  tcest,k=3800");
            fprintf(fid, "%s\n", "  p,bar=0.04,0.1,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30");
            fprintf(fid, "%s\n", "react");
            fprintf(fid, "%s\n", "  oxid=" + string(answ{2}) +" wt=100  t,k=" + string(T));
            fprintf(fid, "%s\n", "  fuel=" + string(answ{1}) +"  wt=100  t,k=" + string(T));
            fprintf(fid, "%s\n", ceaText);
            fprintf(fid, "%s\n", "end");
        end

        function Class = CEA(Class)
            cd('../CEAexec-win');
            command  = "cmd /c echo " + Class.filename + " | FCEA2.exe";
            system(command);
            outPath   = Class.filename + ".out";
            gammaPath = "../CEAdata/" + Class.filename + "_gamma.csv";
            cstarPath = "../CEAdata/" + Class.filename + "_cstar.csv";
            
            fin = fopen(outPath, 'r');
            cfin = onCleanup(@() fclose(fin));
            fg = fopen(gammaPath, 'w');
            cfg = onCleanup(@() fclose(fg));
            fc = fopen(cstarPath, 'w');
            cfc = onCleanup(@() fclose(fc));

            gcount = 0;
            ccount = 0;

            while true
                line = fgetl(fin);
                if ~ischar(line)
                    break;
                end

                % --- GAMMAs 行（Cコード: strncmp(buf," GAMMAs",7)==0）
                if startsWith(line, " GAMMAs")
                    toks = split(string(line));     % 空白区切り（連続空白もOK）
                    toks(toks=="") = [];            % 念のため空要素除去
                    if numel(toks) >= 2
                        val = toks(2);              % Cコードと同じく2番目
                        gcount = gcount + 1;
                        if gcount == 17
                            fprintf(fg, "%s\n", val);
                            gcount = 0;
                        else
                            fprintf(fg, "%s,", val);
                        end
                    end
                end

                % --- CSTAR 行（Cコード: strncmp(buf," CSTAR",6)==0）
                if startsWith(line, " CSTAR")
                    toks = split(string(line));
                    toks(toks=="") = [];
                    if numel(toks) >= 3
                        val = toks(3);              % Cコードと同じく3番目
                        ccount = ccount + 1;
                        if ccount == 17
                            fprintf(fc, "%s\n", val);
                            ccount = 0;
                        else
                            fprintf(fc, "%s,", val);
                        end
                    end
                end
            end

            fprintf("出力しました:\n  %s\n  %s\n", gammaPath, cstarPath);
            cd('../Scripts');
        end
    end
end