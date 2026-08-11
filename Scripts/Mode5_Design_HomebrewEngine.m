classdef Mode5_Design_HomebrewEngine < BaseSystem
    %自作エンジン設計用ver2.3.0(開発中)からそのまま持ってきた。
    %パラメータ設計を行うモード。
    %具体的何をしているか、ちゃんと動くのか含めて詳細不明。
    %頑張って解析してくれ。
    properties %利用するデータ.
        parameters
    end

    methods
        %手続き関数.
        %main関数ではこれが呼び出される.
        function [Class] = run(Class,list)
            %データの取り込み
            disp('データの取り込みを開始します。')
            [data,Class.choice] = Class.Input(list);
            disp('データの取り込みが完了しました。')

            %エンジン設計
            disp('設計モードを開始します')
            Class = Class.Design(data);
            disp('設計モードを終了します')
        end
    end

    methods (Static)
        %エンジン設計用データ読み込み
        function [data,choice] = Input(list)
            [filedata,choice] = Mode5_Design_HomebrewEngine.Infile(list);
            CEAdata = filedata.CEAdata;
            Oxiddata = filedata.oxiddata;
            Fueldata = filedata.fueldata;

            %酸化剤データ
            oxiddata.T = table2array(Oxiddata(:,"温度[K]"));                     %温度
            oxiddata.p = table2array(Oxiddata(:,"圧力[Pa]"));                    %圧力
            oxiddata.rhol = table2array(Oxiddata(:,"液体密度[kg/m^3]"));         %液体密度
            oxiddata.rhog = table2array(Oxiddata(:,"気体密度[kg/m^3]"));         %気体密度
            oxiddata.deltahsat = table2array(Oxiddata(:,"蒸発熱[kJ/kg]"));       %蒸発熱
            oxiddata.cpl = table2array(Oxiddata(:,"定圧比熱(液体)[kJ/kg/K]"));   %定圧比熱（液相）
            oxiddata.cpg = table2array(Oxiddata(:,"定圧比熱(気体)[kJ/kg/K]"));   %定圧比熱（気相）
            oxiddata.hl = table2array(Oxiddata(:,"比エンタルピー(液体)[kJ/kg]"));%比エンタルピー（液相）
            oxiddata.hg = table2array(Oxiddata(:,"比エンタルピー(気体)[kJ/kg]"));%比エンタルピー（気相）
            data.tank.oxiddata = oxiddata;
            %CEAデータ
            data.chamber.cstar = CEAdata.cstar;              %特性排気速度
            data.chamber.gamma = CEAdata.gamma;              %比熱比

            %燃料データ%燃料密度
            data.chamber.rho_f = table2array(Fueldata(choice.fuel,"密度[kg/m^3]"));%燃料密度

            disp("==== rho_f DEBUG ====")%20260508のデバッグにて4行追加
            disp(choice.fuel)
            disp(Fueldata)
            disp(data.chamber.rho_f)
        end

        %設計用ファイル読み込み
        function [filedata,choice] = Infile(list)
            %酸化剤を選択
            [infile_indxs.oxidant]=listdlg('PromptString','酸化剤を選択',...
                'Name','Oxidant Selection',...
                'SelectionMode','Single',...
                'ListString',list.oxidant);
            choice.oxidant=list.oxidant{infile_indxs.oxidant};
            infile.oxidant=strcat(choice.oxidant,'_data.xlsx');
            msg=strcat('選択した酸化剤：',choice.oxidant);
            disp(msg)

            %燃料を選択
            [infile_indxs.fuel]=listdlg('PromptString','燃料を選択',...
                'Name','Fuel Selection',...
                'SelectionMode','Single',...
                'ListString',list.fuel);
            infile.fuel='Fuel_data.xlsx';
            choice.fuel=list.fuel{infile_indxs.fuel};
            msg=strcat('選択した燃料：',choice.fuel);
            disp(msg)

            infile.cstar=strcat(choice.fuel,choice.oxidant,'_cstar.csv');
            infile.gamma=strcat(choice.fuel,choice.oxidant,'_gamma.csv');

            %ファイルの読み込み
            cd('../CEAdata');
            CEAdata.cstar=readmatrix(infile.cstar);     %特性排気速度
            CEAdata.gamma=readmatrix(infile.gamma);     %比熱比@燃焼室
            cd('../Otherdata');
            oxiddata = readtable(infile.oxidant, ...
                "VariableNamingRule","preserve", ...
                'VariableNamesRange',"1:1");
            fueldata = readtable(infile.fuel, ...
                "VariableNamingRule","preserve", ...
                'ReadRowNames',true, ...
                'ReadVariableNames',true);
            cd('../Scripts');
            filedata.CEAdata = CEAdata;
            filedata.oxiddata = oxiddata;%酸化剤データ
            filedata.fueldata = fueldata;%燃料データ
        end

        function Class = Design(data)

            Class.parameters = design_parameter(data.chamber);

        end

        function of = Calc_of(cstar)
            %CEAのO/F比のサンプリングレート
            sample.of_rev=[0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,8.5,9,9.5,10];
            while(true)
                option.of_i = input('初期O/F比の決定方法を選択。(自動→a、手動→m と入力):','s');
                if(option.of_i == "a")
                    msg.option.of_i = '初期O/F比の決定方法：自動';
                    disp(msg.option.of_i)
                    [~,i_max] = max(cstar);
                    of = mean(sample.of_rev(i_max)) + 0.5;
                    return;
                elseif(option.of_i == "m")
                    msg.option.of_i = '初期O/F比の決定方法：手動';
                    disp(msg.option.of_i);
                    of = input('初期O/F比:');
                    return;
                else
                    disp('aかmで入力してください。')
                end
            end
        end


        function [initial,dthroat,cstar_eff,Cd,do,F_req] = Calc_Supply_System(cstar,gamma,pe,rho_ox,F_req)

            %初期O/F比の決定
            ofi = Mode5_Design_HomebrewEngine.Calc_of(cstar);
            msg.ofi=strcat('初期O/F比は',num2str(ofi),'に設定します。');
            disp(msg.ofi);

            disp('供給系が必要な流量を計算します。');
            disp('必要情報を入力してください。')
            %必要事項入力
            %初期タンク圧力の入力
            pti = input('初期タンク圧力[MPa]:')*10^6;
            %初期燃焼室圧力を仮決定
            pci = pti;
            %特性排気速度効率の入力
            cstar_eff = input('特性排気速度効率:');
            %流量係数の決定
            Cd = input('オリフィス流量係数:');
            %オリフィス径の決定
            do = input('オリフィス径[mm]:')*10^(-3);
            %燃料供給量計算
            flag.pci = true;
            while(flag.pci)
                mdot_pi = 0;
                mdot_pmin = 0;
                while(mdot_pi <= mdot_pmin)
                    pci = pci - 10^3;
                    if(pci <= pe)
                        pci = pci + 10^3;
                        disp("現在の設定では必要最低流量を満たせません。" + ...
                            newline + "初期燃焼室以外の設定を見直してください。" + ...
                            newline + "要求推力の見直しも考慮に入れてください。");
                        break;
                    end
                    %初期状態における特性排気速度と比熱比
                    cstari = interpolate(pci,ofi,cstar);
                    gammai = interpolate(pci,ofi,gamma);
                    %推力係数
                    Cfi = sqrt(2*gammai^2/(gammai - 1)* ...
                        (2/(gammai + 1))^((gammai + 1)/(gammai - 1))* ...
                        (1-(pe/pci)^((gammai - 1)/gammai)));
                    %必要最低流量
                    mdot_pmin = F_req/(Cfi*cstar_eff*cstari);
                    %供給系が必要最低流量を達成できるか。
                    mdot_oxi = Cd*pi/4*do^2*sqrt(2*rho_ox*(pti - pci));
                    mdot_pi = (1 + 1/ofi) * mdot_oxi;

                end
                msg.cstari = strcat('初期特性排気速度：',num2str(cstari),'[m/s]');
                msg.gammai = strcat('初期比熱比：',num2str(gammai));
                disp(msg.cstari)
                disp(msg.gammai)
                msg.Cfi = strcat('初期推力係数：',num2str(Cfi));
                disp(msg.Cfi)
                disp(strcat('算出した初期燃焼室圧力:', ...
                    num2str(pci*10^(-6)), ...
                    '[MPa]'));
                option.sup2 = input('初期燃焼室圧力を手動で変更しますか？(y/n)','s');
                if(option.sup2 == "y")
                    pci = input('初期燃焼室圧力[MPa]:')*10^6;
                    %初期状態における特性排気速度と比熱比
                    cstari = interpolate(pci,ofi,cstar);
                    gammai = interpolate(pci,ofi,gamma);
                    %推力係数
                    Cfi = sqrt(2*gammai^2/(gammai - 1)* ...
                        (2/(gammai + 1))^((gammai + 1)/(gammai - 1))* ...
                        (1-(pe/pci)^((gammai - 1)/gammai)));
                    %必要最低流量
                    mdot_pmin = F_req/(Cfi*cstar_eff*cstari);
                    %供給系が必要最低流量を達成できるか。
                    mdot_oxi = Cd*pi/4*do^2*sqrt(2*rho_ox*(pti - pci));
                    mdot_pi = (1 + 1/ofi) * mdot_oxi;
                end
                msg.mdot_pmin = strcat('必要最低推進剤流量[kg/s]:',num2str(mdot_pmin));
                disp(msg.mdot_pmin)
                msg.mdot_p=strcat('供給可能な推進剤流量[kg/s]:',num2str(mdot_pi));
                disp(msg.mdot_p)
                if(mdot_pi > mdot_pmin)
                    disp('供給系が必要な流量を達成しました。')
                    flag.pci = false;
                else
                    disp('供給系が必要な流量を達成していません。')
                    disp(['オリフィス径を変更する(o)/オリフィス流量係数を変更する(c)/' ...
                        '特性排気効率を変更する(e)/現在の設定で可能な最大推力を計算する(f)'])
                    option.sup = input('→','s');
                    switch option.sup
                        case "f"
                            F_req_temp = F_req;
                            while(mdot_pi <= mdot_pmin)
                                F_req_temp = F_req_temp - 1;
                                disp(F_req_temp);
                                pci = pti;
                                while(mdot_pi <= mdot_pmin)
                                    pci = pci - 10^5;
                                    if(pci <= pe)
                                        break;
                                    end
                                    cstari = interpolate(pci,ofi,cstar);
                                    gammai = interpolate(pci,ofi,gamma);
                                    Cfi = sqrt(2*gammai^2/(gammai - 1)* ...
                                        (2/(gammai + 1))^((gammai + 1)/(gammai - 1))* ...
                                        (1-(pe/pci)^((gammai - 1)/gammai)));
                                    %必要最低流量
                                    mdot_pmin = F_req_temp/(Cfi*cstar_eff*cstari);
                                    %供給系が必要最低流量を達成できるか。
                                    mdot_oxi = Cd*pi/4*do^2*sqrt(2*rho_ox*(pti - pci));
                                    mdot_pi = (1 + 1/ofi) * mdot_oxi;

                                end
                            end

                            disp(strcat('現在の設定で可能な最大推力:', ...
                                num2str(F_req_temp), ...
                                '[N]'));
                            option.sup2 = input('要求推力を上記の数値に変更しますか？(y/n)','s');
                            if(option.sup2 == "y")
                                F_req = F_req_temp;
                            end
                        case "e"
                            cstar_eff_predicted = mdot_pmin*cstar_eff/mdot_pi;
                            if(1 > cstar_eff_predicted)
                                disp(strcat(num2str(cstar_eff_predicted), ...
                                    'より大きければ必要な流量になります。'));
                            else
                                disp("特性排気効率が1になっても要求値に達しません。");
                            end

                            cstar_eff = input('特性排気効率:');

                        case "c"
                            Cd_predicted = mdot_pmin*Cd/mdot_pi;
                            if(1 > Cd_predicted)
                                disp(strcat(num2str(Cd_predicted), ...
                                    'より大きければ必要な流量になります。'));
                            else
                                disp("オリフィス流量係数が1になっても要求値に達しません。");
                            end
                            Cd = input('オリフィス流量係数:');

                        case "o"
                            msg.re_do = strcat('オリフィス径を', ...
                                num2str(do*10^3), ...
                                '[mm]以上の値で再決定してください。');
                            disp(msg.re_do);

                            do_predicted = sqrt(mdot_pmin*(do^2)/mdot_pi);
                            disp(strcat(num2str(do_predicted*10^3), ...
                                '[mm]より大きければ必要な流量になります。'));

                            do = input('オリフィス径[mm]:')*10^(-3);

                        otherwise
                            disp('o,c,pいずれかの入力をお願いします。');
                    end
                end
            end

            %初期推力
            Fi = Cfi*cstar_eff*cstari*mdot_pi;
            msg.Fi = strcat('初期推力:',num2str(Fi),'[N]');
            disp(msg.Fi)

            %ノズルスロート径
            dthroat = sqrt(4*cstar_eff*cstari*mdot_pi/(pi*pci));
            msg.dthroat = strcat('ノズルスロート径推定最適値:',num2str(dthroat*10^3),'[mm]');
            disp(msg.dthroat)
            dthroat = round(dthroat*10^3,2)*10^(-3);
            msg.dthroat = strcat('ノズルスロート径製造値:',num2str(dthroat*10^3),'[mm]');
            disp(msg.dthroat)
            %開口比
            Epsilon = ((2/(gammai + 1))^(1/(gammai - 1))*(pci/pe)^(1/gammai))/ ...
                sqrt((gammai + 1)/(gammai - 1)*(1 - (pe/pci)^((gammai - 1)/gammai)));
            msg.Epsilon = strcat('開口比:',num2str(Epsilon));
            disp(msg.Epsilon)

            %ノズル出口径
            de = round(dthroat*sqrt(Epsilon)*10^3,2)*10^(-3);
            msg.de = strcat('ノズル出口径製造値:',num2str(de*10^3),'[mm]');
            disp(msg.de)

            %初期状態数値格納
            initial.F = Fi;
            initial.cstar = cstari;
            initial.gamma = gammai;
            initial.of = ofi;
            initial.pc = pci;
            initial.pt = pti;
            initial.Cf = Cfi;
            initial.mdot_ox = mdot_oxi;
            initial.mdot_p = mdot_pi;
            initial.dthroat = dthroat;
        end
        
        function [initial,dthroat] = Recalc_Supply_System(cstar,gamma,pe,rho_ox,F_req,initial,cstar_eff,Cd,do)

        % 補正済みのO/Fと、既に決まっている初期タンク圧を使用する
        ofi = initial.of;
        pti = initial.pt;

        disp(strcat('再計算に使用する初期O/F比：', num2str(ofi)));
        disp(strcat('再計算に使用する初期タンク圧力：', num2str(pti*10^(-6)), '[MPa]'));

        % 初期燃焼室圧力をタンク圧から探索開始
        pci = pti;

        mdot_pi = 0;
        mdot_pmin = 0;

        while(mdot_pi <= mdot_pmin)
            pci = pci - 10^3;

            if(pci <= pe)
                error("O/F補正後の供給系再計算に失敗しました。現在の設定では必要最低流量を満たせません。");
            end

            % 初期状態における特性排気速度と比熱比
            cstari = interpolate(pci,ofi,cstar);
            gammai = interpolate(pci,ofi,gamma);

            % 推力係数
            Cfi = sqrt(2*gammai^2/(gammai - 1)* ...
                (2/(gammai + 1))^((gammai + 1)/(gammai - 1))* ...
                (1-(pe/pci)^((gammai - 1)/gammai)));

            % 必要最低推進剤流量
            mdot_pmin = F_req/(Cfi*cstar_eff*cstari);

            % 供給可能な酸化剤流量・推進剤流量
            mdot_oxi = Cd*pi/4*do^2*sqrt(2*rho_ox*(pti - pci));
            mdot_pi = (1 + 1/ofi) * mdot_oxi;
        end

        % 初期推力
        Fi = Cfi*cstar_eff*cstari*mdot_pi;

        % ノズルスロート径
        dthroat = sqrt(4*cstar_eff*cstari*mdot_pi/(pi*pci));
        dthroat = round(dthroat*10^3,2)*10^(-3);

        % 結果表示
        disp(strcat('再計算後 初期特性排気速度：', num2str(cstari), '[m/s]'));
        disp(strcat('再計算後 初期比熱比：', num2str(gammai)));
        disp(strcat('再計算後 初期推力係数：', num2str(Cfi)));
        disp(strcat('再計算後 初期燃焼室圧力：', num2str(pci*10^(-6)), '[MPa]'));
        disp(strcat('再計算後 必要最低推進剤流量：', num2str(mdot_pmin), '[kg/s]'));
        disp(strcat('再計算後 供給可能推進剤流量：', num2str(mdot_pi), '[kg/s]'));
        disp(strcat('再計算後 初期推力：', num2str(Fi), '[N]'));
        disp(strcat('再計算後 ノズルスロート径：', num2str(dthroat*10^3), '[mm]'));

        % initialを更新
        initial.F = Fi;
        initial.cstar = cstari;
        initial.gamma = gammai;
        initial.of = ofi;
        initial.pc = pci;
        initial.pt = pti;
        initial.Cf = Cfi;
        initial.mdot_ox = mdot_oxi;
        initial.mdot_p = mdot_pi;
        initial.dthroat = dthroat;

    end

        function [df,dfs,a,n,time_step,Lf] = Calc_Lf(initial,rho_f,planed_burning_time,ave,df,Df)
            while(true)

                %酸化剤流束係数
                %a=1.31*10^(-4);
                %a=3.4713*10^(-6);
                %a=2.764*10^(-6);
                a=1.16*10^(-4);
                %酸化剤流束指数
                %n=0.95;
                n=0.33;

                %タイムサンプリングレート
                time_step=0.005;
                i_max=round(planed_burning_time/time_step);

                %ポート径
                dfs=zeros(i_max,1);

                for i=1:i_max
                    if(i==1)
                        dfs(i,1)=df;
                    else
                        dfs(i,1)=rungekutta(dfs(i-1,1),ave.mdot_ox,a,n,time_step);
                    end
                end
                disp(strcat("最終ポート径",num2str(dfs(end,1)*10^3)))
                %スライパ率
                df_initial = dfs(1,1);
                df_final = dfs(end,1);
                df_outer = Df;
                phi=(df_outer^2 - df_final^2)/(df_outer^2 - df_initial^2)*100;
                msg.phi=strcat('スライパ率',num2str(phi),'%');
                disp(msg.phi)

                if(phi > 100 || 0 > phi)
                    disp("スライバ率が異常です。")
                    msg.dfi=strcat('初期ポート径を',num2str(df*10^3),'[mm]以上にしてください。');
                    disp(msg.dfi)
                    %初期ポート径
                    df=input('初期ポート径[mm]：')*10^(-3);
                else
                    option.phi=input('スライパ率が適正値か？(y/n)','s');
                    if(option.phi=="y")
                        %燃料長さ
                        Lf=(initial.mdot_ox/initial.of)/(pi*df*rho_f*a)* ...
                            (4*initial.mdot_ox/(pi*df^2))^(-n);

                        Lf=round(Lf,3);
                        msg.Lf=strcat('燃料長さ：',num2str(Lf*10^3),'[mm]');
                        disp(msg.Lf)
                        return
                    elseif(option.phi=="n")
                        msg.dfi=strcat('初期ポート径を',num2str(df*10^3),'[mm]以上にしてください。');
                        disp(msg.dfi)
                        %初期ポート径
                        df=input('初期ポート径[mm]：')*10^(-3);
                        %燃料外径
                        Df = input('燃料外径[mm]：')*10^(-3);
                    end
                end
            end
        end

        function [initial,final,ave,planed_burning_time,dfs,Lf,a,n,time_step] = Calc_Fuel_System(cstar,gamma,initial,vt,pe,rho_ox,rho_f,F_req,cstar_eff,Cd,do)
            while(true)
                %以下燃料設計
                %最終圧力推定
                final_pt_min = initial.pc^2/initial.pt;
                disp(strcat("最終タンク圧力[MPa]を",num2str(final_pt_min*10^(-6)),"MPaより大きく設定してください。"))
                final.pt=input('最終タンク圧力[MPa]:')*10^6;

                while ~(isscalar(final.pt) && isreal(final.pt) && isfinite(final.pt) && final.pt > final_pt_min)
                    disp("入力された最終タンク圧力では供給差圧を確保できません。");
                    final.pt=input('最終タンク圧力[MPa]:')*10^6;
                end

                final.pc=initial.pc*sqrt(final.pt/initial.pt);

                msg.final.pc=strcat('最終燃焼室圧力推定値：',num2str(final.pc*10^(-6)),'[MPa]');
                disp(msg.final.pc)

                if(final.pt <= final.pc)
                    error("最終タンク圧が最終燃焼室圧以下です。");
                end

                %平均圧力推定
                ave.pt=(initial.pt+final.pt)/2;
                ave.pc=(initial.pc+final.pc)/2;
                msg.ave.pt=strcat('平均タンク圧力推定値：',num2str(ave.pt*10^(-6)),'[MPa]');
                msg.ave.pc=strcat('平均燃焼室圧力推定値：',num2str(ave.pc*10^(-6)),'[MPa]');
                disp(msg.ave.pt)
                disp(msg.ave.pc)

                %平均酸化剤流量
                ave.mdot_ox=Cd*pi/4*do^2*sqrt(2*rho_ox*(ave.pt-ave.pc));
                msg.ave.mdot_ox=strcat('平均酸化剤流量：',num2str(ave.mdot_ox),'[kg/s]');
                disp(msg.ave.mdot_ox)

                %予定燃焼時間
                planed_burning_time=vt*rho_ox/ave.mdot_ox;
                msg.pbt=strcat('燃焼予定時間:',num2str(planed_burning_time),'[s]');
                disp(msg.pbt)

                %必要情報入力
                %最大燃料長さ
                Lf_max=input('最大燃料長さ[m]:');
                %燃焼室特性長
                option.Lfstar=input('必要な燃焼室特性長がわかっているか？(y/n)：','s');
                if(option.Lfstar=="y")
                    Lstar_min = input('必要な燃焼室特性長[m]:');
                elseif(option.Lfstar=="n")
                    Lstar_min = 2;
                    disp('必要な燃焼室特性長を2[m]として計算します。')
                end

                %初期ポート径
                df=input('初期ポート径[mm]：')*10^(-3);
                %燃料外径
                Df = input('燃料外径[mm]：')*10^(-3);

                %燃料長さ
                [initial.df,dfs,a,n,time_step,Lf] = Mode5_Design_HomebrewEngine.Calc_Lf(initial,rho_f,planed_burning_time,ave,df,Df);
                dthroat = initial.dthroat;

                flag.Lfstar=true;
                while(flag.Lfstar)
                    %必要最小燃料長さ
                    Lf_min=Lstar_min*dthroat^2/initial.df^2;
                    msg.Lf_min=strcat('必要最小燃料長さ：',num2str(Lf_min),'[m]');
                    disp(msg.Lf_min)
                    if(Lf_min > Lf_max)
                        disp('必要最小燃料長さが最大燃料長さを凌駕しています。');
                        disp(strcat('最大燃料長さ:',num2str(Lf_max),'[m]'));
                        disp(strcat('最小燃料長さ:',num2str(Lf_min),'[m]'));
                        %燃焼室特性長
                        Lstar_min_predict = Lf_max * initial.df^2/dthroat^2;
                        disp(strcat('現在の初期ポート径だと燃焼室特性長が', ...
                            num2str(Lstar_min_predict), ...
                            '[m]未満じゃないと最大燃料長さを凌駕します。'));
                        %初期ポート径
                        Initialof_predict = sqrt((Lstar_min * dthroat^2)/Lf_max);
                        disp(strcat('現在の燃焼室特性長だと初期ポート径が', ...
                            num2str(Initialof_predict*10^3), ...
                            '[mm]以上じゃないと最大燃料長さを凌駕します。'));

                        disp(['初期ポート径を大きくする(d)/' ...
                            '必要な燃焼室特性長を引き下げる(l)'])
                        option.reLf = input('→','s');
                    elseif(Lf > Lf_max)
                        disp('燃料長さが最大燃料長さを凌駕しています。');
                        disp(strcat('最大燃料長さ:',num2str(Lf_max),'[m]'));
                        disp(strcat('燃料長さ:',num2str(Lf),'[m]'));
                        %初期ポート径
                        Initialof_predict = nthroot(Lf*initial.df^(1-2*n)/Lf_max,1-2*n);
                        disp(strcat('初期ポート径が', ...
                            num2str(Initialof_predict*10^3), ...
                            '[mm]以下じゃないと最大燃料長さを凌駕します。'));
                        disp(['初期ポート径を小さくする(d)/' ...
                            '初期O/F比を大きくする(o)'])
                        option.reLf = input('→','s');
                    elseif(Lf_min > Lf)
                        disp('燃料長さが必要最小燃料長さを下回っています。')
                        disp(strcat('最小燃料長さ:',num2str(Lf_min),'[m]'));
                        disp(strcat('燃料長さ:',num2str(Lf),'[m]'));
                        Lstar_min_predict = Lf * initial.df^2/dthroat^2;
                        disp(strcat('現在の初期ポート径だと燃焼室特性長が', ...
                            num2str(Lstar_min_predict), ...
                            '[m]未満じゃないと必要最小燃料長さを下回ります。'));

                        disp(['初期ポート径を大きくする(d)/' ...
                            '必要な燃焼室特性長を引き下げる(l)/' ...
                            '初期O/F比を大きくする(o)'])
                        option.reLf = input('→','s');
                    else
                        disp('必要な燃料長さを確保できています。')
                        option.reLf = "end";
                    end

                    switch option.reLf
                        case "d"
                            msg.dfi=strcat('現在の初期ポート径：',num2str(initial.df*10^3),'[mm]');
                            disp(msg.dfi);
                            df=input('新しい初期ポート径[mm]：')*10^(-3);
                            [initial.df,dfs,a,n,time_step,Lf] = Mode5_Design_HomebrewEngine.Calc_Lf(initial,rho_f,planed_burning_time,ave,df,Df);
                        case "l"
                            option.Lfstar='y';
                            Lstar_min = input('必要な燃焼室特性長[m]:');

                        case "o"
                            flag.Lfstar = 0;
                            disp('O/F比を補正します。');

                            initial.mdot_f = Lf_max*pi*initial.df*rho_f*a*(4*initial.mdot_ox/(pi*initial.df^2))^n;
                            initial.of = initial.mdot_ox/initial.mdot_f;

                            disp(strcat('補正後の初期O/F比：', num2str(initial.of)));

                            disp('供給系の計算をやり直します。');
                            [initial,~] = Mode5_Design_HomebrewEngine.Recalc_Supply_System( ...
                                cstar,gamma,pe,rho_ox,F_req,initial,cstar_eff,Cd,do);
                            disp('<供給系再設計完了>');
                        case "end"
                            disp("全ての入力が完了しました。")
                            return;
                        otherwise
                            disp("選択肢のどれかを選択してください。")
                    end

                end
            end
        end

    end
end

%パラメータ設計
function parameters = design_parameter(data)

cstar = data.cstar;     %特性排気速度
gamma = data.gamma;     %比熱比
rho_f = data.rho_f;     %燃料密度
rho_ox = 852.2;         %酸化剤密度
pe = 1.013*10^5;          %大気圧

disp("===== DEBUG =====")
disp(size(cstar))       %20260508のデバッグにて二行追加
disp(size(gamma))

%要求値設定
%要求推力
F_req = input('要求推力[N]:');
%要求トータルインパルス
I_req=input('トータルインパルスの要求値[Ns]:');
%タンク容積
vt=input('タンク容積[cc]:')*10^(-6);

flag.req=1;
while(flag.req==1)
    %供給系計算
    disp('<供給系設計開始>')
    [initial,~,cstar_eff,Cd,do,F_req] = Mode5_Design_HomebrewEngine.Calc_Supply_System(cstar,gamma,pe,rho_ox,F_req);
    disp('<供給系設計完了>');

    disp('<燃料系設計開始>')
    [initial,final,ave,planed_burning_time,dfs,Lf,a,n,time_step] = Mode5_Design_HomebrewEngine.Calc_Fuel_System(cstar,gamma,initial,vt,pe,rho_ox,rho_f,F_req,cstar_eff,Cd,do);
    dthroat = initial.dthroat;
    disp('<燃料系設計完了>')
   
    disp('====final_p_DEBUG====') %20260508のデバッグにて10行追加
    disp(final.pt)
    disp(final.pc)
    disp(final.pt - final.pc)
    disp("==== mdot_f DEBUG ====")
    disp(rho_f)
    disp(Lf)
    disp(dfs(end,1))
    disp(a)
    disp(n) %デバッグ行終わり

    %燃焼終了時の各質量流量
    deltaP_final = final.pt - final.pc;
    if ~isreal(deltaP_final) || ~isfinite(deltaP_final) || deltaP_final <= 0
        error("最終時刻の供給差圧が正ではありません。");
    end
    final.mdot_ox=Cd*pi/4*do^2*sqrt(2*rho_ox*deltaP_final);
    final.mdot_f=rho_f*Lf*pi*dfs(end,1)*a*(4*final.mdot_ox/(pi*dfs(end,1)^2))^n;
    final.mdot_p=final.mdot_ox+final.mdot_f;


    disp("===== FLOW DEBUG =====")%20260508のデバッグにて5行追加
    disp(final.mdot_ox)
    disp(final.mdot_f)
    disp(final.mdot_ox)
    term = 4*final.mdot_ox/(pi*dfs(end,1)^2);
    disp(term)%デバッグ行終わり

    final.of=final.mdot_ox/final.mdot_f;

    disp("===== DEBUG =====") %20260508のデバッグにて2行追加
    disp(final.of)
    disp(final.pc)%デバッグ行終わり

    final.cstar=interpolate(final.pc,final.of,cstar);
    final.gamma=interpolate(final.pc,final.of,gamma);

    msg.final.mdot_ox=strcat('最終酸化剤流量',num2str(final.mdot_ox),'[kg/s]');
    msg.final.mdot_f=strcat('最終燃料流量',num2str(final.mdot_f),'[kg/s]');
    msg.final.mdot_p=strcat('最終推進剤流量',num2str(final.mdot_p),'[kg/s]');
    msg.final.of=strcat('最終O/F比',num2str(final.of));
    msg.final.cstar=strcat('最終特性排気速度',num2str(final.cstar),'[m/s]');
    msg.final.gamma=strcat('最終比熱比',num2str(final.gamma));

    disp(msg.final.mdot_ox)
    disp(msg.final.mdot_f)
    disp(msg.final.mdot_p)
    disp(msg.final.of)
    disp(msg.final.cstar)
    disp(msg.final.gamma)


    %最終推力
    final.Cf=sqrt(2*final.gamma^2/(final.gamma-1)* ...
        (2/(final.gamma+1))^((final.gamma+1)/(final.gamma-1))* ...
        (1-(pe/final.pc)^((final.gamma-1)/final.gamma)));

    final.F=final.Cf*cstar_eff*final.cstar*final.mdot_p;

    msg.final.Cf=strcat('最終推力係数',num2str(final.Cf));
    msg.final.F=strcat('最終推力',num2str(final.F),'[N]');
    disp(msg.final.Cf)
    disp(msg.final.F)

    %トータルインパルス
    ave.F=(initial.F+final.F)/2;
    I=ave.F*planed_burning_time;

    msg.ave.F=strcat('平均推力',num2str(ave.F),'[N]');
    msg.I=strcat('トータルインパルス',num2str(I),'[Ns]');
    disp(msg.ave.F)
    disp(msg.I)

    flag.I_req=1;
    while(flag.I_req==1)

        if(I_req < I)
            disp('要求トータルインパルスを達成しました。')
            flag.req=0;
            flag.I_req=0;
            disp('酸化剤,トータルインパルス等そのままでやり直す場合→f')
            disp('終わる場合→a')
            option.req=input('→','s');
        else
            disp('要求トータルインパルスを達成していません。')
            disp('要求推力を上げる場合(最初からやり直す)→f')
            disp('タンクを大型化する場合→t')
            disp('要求トータルインパルスを下げる場合→i')
            option.req=input('→','s');
        end

        if(option.req=="f")
            flag.I_req=0;
            disp("注意!:要求推力を変えてもトータルインパルスが変化することはありません。");
            disp("供給系のパラメータを変更するところから始めてください。");
            msg.F_req=strcat('現在の要求推力：',num2str(F_req),'[N]');
            disp(msg.F_req)
            F_req=input('再決定した要求推力[N]：');
        elseif(option.req=="t")
            msg.vt=strcat('現在のタンク容量：',num2str(vt*10^6),'[cc]');
            disp(msg.vt)
            vt_predicted = (I_req * ave.mdot_ox) / (rho_ox * ave.F);

            disp(strcat('現在のトータルインパルスを満たすには',num2str(vt_predicted * 10^6),'cc以上の容量が必要です。'))
            vt=input('再決定したタンク容量[cc]：')*10^(-6);
            planed_burning_time=vt*rho_ox/ave.mdot_ox;
            I=ave.F*planed_burning_time;
            msg.I=strcat('トータルインパルス',num2str(I),'[Ns]');
            disp(msg.ave.F)
            disp(msg.I)

        elseif(option.req=="i")
            msg.I_req=strcat('現在の要求トータルインパルス：',num2str(I_req),'[Ns]');
            disp(msg.I_req)
            I_req=input('再決定した要求トータルインパルス[Ns]：');
        end
    end
end

%グレインの燃料内径・燃料後退速度の時間変化をCSV出力
time = (0:length(dfs)-1)'*time_step;         %時間[s]
rdot = 2*a*(4*ave.mdot_ox./(pi*dfs.^2)).^n;  %燃料後退速度[m/s]

exportcsv = questdlg('グレインの燃料内径・燃料後退速度の時間変化をcsv出力しますか？', ...
    'Output the csv File?',"Yes","No","Yes");
if(exportcsv == "Yes")
    cd('../Output')

    dfTable = table(time,dfs,'VariableNames',{'time[s]','df[m]'});
    writetable(dfTable,'DesignEngine_df_history.csv')

    rdotTable = table(time,rdot,'VariableNames',{'time[s]','rdot[m/s]'});
    writetable(rdotTable,'DesignEngine_rdot_history.csv')

    cd('../Scripts')
end

%パラメータ割り当て
parameters.pti=initial.pt;              %初期タンク圧
parameters.ptf=final.pt;                %最終タンク圧
parameters.pci=initial.pc;              %初期燃焼室圧
parameters.pbt=planed_burning_time;     %燃焼予定時間
parameters.vt=vt;                       %酸化剤充填量
parameters.rho_ox=rho_ox;               %酸化剤密度
parameters.gamma_ox=10;                 %酸化剤比熱比
parameters.do=do;                       %オリフィス内径
parameters.Cd=Cd;                       %流量係数

parameters.pci=initial.pc;              %初期燃焼室圧力
parameters.rho_f=rho_f;                 %燃料密度
parameters.Lf=Lf;                       %燃料長さ
parameters.dfi=dfs(1,1);                 %初期ポート径
parameters.port=1;                      %ポート数
parameters.a=a;                         %酸化剤流束係数
parameters.n=n;                         %酸化剤流束指数

parameters.cstar_eff=cstar_eff;         %特性排気速度効率
parameters.pse=pe;                      %背圧
parameters.dti=dthroat;                %初期スロート径
parameters.de=0.02;                     %ノズル出口径
parameters.alpha=15;                    %ノズル半頂角
parameters.ros=0;                       %エロ―ジョン速度

parameters.cstar=cstar;                 %特性排気速度
parameters.gamma=gamma;                 %比熱比
end

%runge-kutta法
function dff=rungekutta(df1,mdot_ox,a,n,time_step)
%燃料後退速度式
rdot=@(df)(2*a*(mdot_ox*4/(pi*df^2))^n);

k1=rdot(df1);        %区間の最初における勾配
df2=df1+k1*time_step/2;
k2=rdot(df2);        %区間の中央における勾配の近似値
df3=df1+k2*time_step/2;
k3=rdot(df3);        %区間の中央における勾配の近似値
df4=df1+k3*time_step;
k4=rdot(df4);        %区間の最後における勾配の近似値

%最終的な燃料ポート径
dff=df1+(k1+2*k2+2*k3+k4)*time_step/6;
end

%線形補間関数
function y=interpolate(pc,of,data)
%CEAの燃焼室圧のサンプリングレート
sample.pc=[0.004,0.01,0.2,0.4,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.0,2.2,2.4,2.6,2.8,3.0].*(10^6);
%CEAのO/F比のサンプリングレート
sample.of=[0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,8.5,9,9.5,10,100];

if ~isnumeric(pc) || ~isscalar(pc) || ~isreal(pc) || ~isfinite(pc)
    error("CEA補間の燃焼室圧力pcが不正です。");
end

if ~isnumeric(of) || ~isscalar(of) || ~isreal(of) || ~isfinite(of)
    error("CEA補間のO/Fが不正です。");
end

if ~isnumeric(data) || ~ismatrix(data)
    error("CEA補間データが数値行列ではありません。");
end

if size(data,1) ~= length(sample.of) || size(data,2) ~= length(sample.pc)
    error("CEA補間データのサイズがサンプル格子と一致しません。");
end

if ~isreal(data) || any(~isfinite(data(:)))
    error("CEA補間データに非実数または非有限値が含まれています。");
end

if of < min(sample.of)
    error("O/FがCEAテーブル下限を下回っています。");
elseif of > max(sample.of)
    warning('O/FがCEAテーブル上限の100を超えたため、O/F=100として補間します。');
    of = max(sample.of);
end

if pc < min(sample.pc) || pc > max(sample.pc)
    error("燃焼室圧力pcがCEAテーブル範囲外です。");
end

sample.data = zeros(1,length(sample.pc));
for i = 1:length(sample.pc)
    sample.data(i) = interp1(sample.of,data(:,i),of,'makima');
end
y = interp1(sample.pc,sample.data,pc,'makima');
end
