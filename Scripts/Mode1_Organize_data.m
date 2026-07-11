classdef Mode1_Organize_data < BaseSystem

    %データ整理モード用.
    %Output関数の他、choiceを読み込み、保存する関数を保有.
    methods
        %手続き関数.
        %main関数ではこれが呼び出される.
        function [Class, output] = run(Class,gs)
            Class.choice = gs; % GUIの設定をここに流し込む！
            % データの取り込み
            disp('データの取り込みを開始します。')
            Class = Class.Input(gs); % Inputにもgsを渡してパスを制御
            disp('データの取り込みが完了しました。')
            % 設定読み込み（自動判定）
            Class = Class.Load_choice(gs);
            %設定の再利用
            Class = Class.Load_choice(gs);
            %推力データのカット
            disp('推力データのカットを開始します。')
            Class = Class.History(gs);
            disp('推力データのカットが完了しました。')
            %グラフの出力
            disp('グラフの出力を開始します。')
            Class = Class.Graph(gs);
            disp('グラフの出力を完了しました。')
            %結果の出力
            [Class,output] = Class.Output(Class.output, gs);
            Class = Class.csvout(gs);
            %設定の保存
            %Class.Save_choice();
        end

        %結果表示関数
        function [Class,msg] = Output(Class,Class_output, gs)

            % 1. gs (GeneralSetting) から設定を取得、なければデフォルト値を設定
            if nargin >= 3 && ~isempty(gs)
                % JSONから読み込んだ設定を優先
                noiseremoved = gs.noiseremoved;
                spikecut = gs.spikecut;
            elseif isfield(Class.choice, 'noiseremoved')
                % 既存のchoiceがあればそれを使用
                noiseremoved = Class.choice.noiseremoved;
                spikecut = Class.choice.spikecut;
            else
                % どちらもなければデフォルト値を代入
                noiseremoved = "No";
                spikecut = "No";
            end
            
            Class.choice.noiseremoved = noiseremoved;
            Class.choice.spikecut = spikecut;

            msg.origin = Output@BaseSystem(Class,Class_output.origin);

            if(gs.noiseremoved == "Yes" && isfield(Class_output,'noiseremoved'))
                disp("ノイズ除去後");
                msg.noiseremoved = Output@BaseSystem(Class,Class_output.noiseremoved);
            end

            if(gs.spikecut == "Yes" && isfield(Class_output,'noiseremoved'))
                disp("スパイクカット後");
                msg.spikecut = Output@BaseSystem(Class,Class_output.spikecut);
            end
        end

        %設定読み込み関数。何度も選択肢を押すのが億劫なため用意.
        function Class = Load_choice(Class, gs)
            % 1. 基準となるルートディレクトリを取得
            % (mfilename('fullpath')で自身のパスを特定し、そこからルートに戻る)
            root = fileparts(fileparts(mfilename('fullpath')));
            saveDir = fullfile(root, 'SaveData');
            filename = fullfile(saveDir, strcat(Class.info.engine, '_savedata.xml'));
        
            % 2. ファイルの存在確認
            if exist(filename, "file")
                % GUI設定から「前回の設定を使う」というフラグが立っているかチェック
                use_auto_load = isfield(Class.choice, 'use_previous') && ...
                                strcmp(Class.choice.use_previous, "Yes");
                
                % 「自動使用」がONならダイアログを出さずに読み込む
                if use_auto_load
                    savedata = readstruct(filename, "FileType", "xml");
                    Class.choice = savedata;
                    disp("前回の設定を自動適用しました。");
                %else
                    % それ以外（GUIで設定がない/Noの場合）はダイアログを出す
               %     savedata = readstruct(filename, "FileType", "xml");
               %     h = helpdlg(evalc("disp(savedata)"), "前回 設定");
               %     answer = questdlg("前回の設定を利用しますか?", 'Use SaveData?', "Yes", "No", "No");
               %     if strcmp(answer, "Yes")
               %         Class.choice = savedata;
               %     end
                    delete(h);
                end
            else
                disp("保存された設定ファイルが見つかりません。");
            end
        end

        %設定保存関数。何度も選択肢を押すのが億劫なため用意.
        %function Save_choice(Class)
        %    root = fileparts(fileparts(mfilename('fullpath')));
        %    filename = fullfile(root, 'SaveData', strcat(Class.info.engine, '_savedata.xml'));
        %    writestruct(Class.choice, filename);
        %end

    end
end