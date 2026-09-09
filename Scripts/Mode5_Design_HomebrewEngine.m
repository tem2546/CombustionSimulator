classdef Mode5_Design_HomebrewEngine < BaseSystem
    %自作エンジン設計用ver2.3.0(開発中)からそのまま持ってきた。
    %パラメータ設計を行うモード。
    %
    %計算ロジックは全てinput()/questdlgを持たない純粋関数にしてあり、
    %対話部分はMode5_DesignDashboard.mのuifigureが担当する。
    properties %利用するデータ.
        parameters
    end

    methods
        %手続き関数.
        %main関数ではこれが呼び出される.
        function [Class] = run(Class, gs)
            %データの取り込み
            disp('データの取り込みを開始します。')
            [data,Class.choice] = Class.Input(gs);
            disp('データの取り込みが完了しました。')

            %エンジン設計（対話式ダッシュボード）
            disp('設計モードを開始します')
            result = Mode5_DesignDashboard(data, gs);
            if ~isempty(result) && ~result.cancelled
                Class.parameters = result.parameters;
                disp('設計が確定しました。')
            else
                disp('設計モードがキャンセルされました。')
            end
            disp('設計モードを終了します')
        end
    end

    methods (Static)
        %エンジン設計用データ読み込み
        function [data,choice] = Input(gs)
            [filedata,choice] = Mode5_Design_HomebrewEngine.Infile(gs);
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
        end

        %設計用ファイル読み込み
        function [filedata,choice] = Infile(gs)
            % UIから選択された酸化剤・燃料を直接取得
            choice.oxidant = gs.m5_oxidant_select;
            choice.fuel = gs.m5_fuel_select;

            disp(strcat('選択した酸化剤：', choice.oxidant));
            disp(strcat('選択した燃料：', choice.fuel));

            infile.oxidant = strcat(choice.oxidant, '_data.xlsx');
            infile.fuel = 'Fuel_data.xlsx';
            infile.cstar = strcat(choice.fuel, choice.oxidant, '_cstar.csv');
            infile.gamma = strcat(choice.fuel, choice.oxidant, '_gamma.csv');

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

        %======================================================
        % ダッシュボードから1クリックごとに呼ばれる、設計計算の一連の流れ.
        % input()/questdlgを一切持たない純粋関数.
        % p: ダッシュボードで編集された全パラメータをまとめた構造体.
        %======================================================
        function report = ComputeDesign(data, p)
            cstar = data.chamber.cstar;     %特性排気速度
            gamma = data.chamber.gamma;     %比熱比
            rho_f = data.chamber.rho_f;     %燃料密度
            rho_ox = 852.2;                 %酸化剤密度
            pe = 1.013*10^5;                %大気圧

            report.warnings = {};
            report.ok = false;
            report.parameters = [];

            F_req = p.F_req;
            I_req = p.I_req;
            vt = p.vt*10^(-6);           %cc → m^3
            pti = p.pti*10^6;            %MPa → Pa
            final_pt = p.final_pt*10^6;  %MPa → Pa
            do = p.do*10^(-3);           %mm → m
            df = p.df*10^(-3);           %mm → m
            Df = p.Df_outer*10^(-3);     %mm → m

            of = Mode5_Design_HomebrewEngine.Calc_of(cstar, p.of_method, p.manual_of);
            report.of = of;

            [supply, supplyStatus] = Mode5_Design_HomebrewEngine.Calc_Supply_System( ...
                cstar, gamma, pe, rho_ox, F_req, of, pti, p.cstar_eff, p.Cd, do);
            report.supply = supply;
            report.supplyStatus = supplyStatus;
            if ~supplyStatus.ok
                report.warnings{end+1} = supplyStatus.message;
                return
            end

            [fuel, fuelStatus] = Mode5_Design_HomebrewEngine.Calc_Fuel_System( ...
                supply, vt, rho_ox, rho_f, p.Cd, do, final_pt, p.Lf_max, p.Lstar, df, Df);
            report.fuel = fuel;
            report.fuelStatus = fuelStatus;
            if ~fuelStatus.ok
                report.warnings{end+1} = fuelStatus.message;
                return
            end

            %燃焼終了時の各質量流量・最終推力（design_parameter旧コードの後半部分）
            final = fuel.final;
            deltaP_final = final.pt - final.pc;
            if ~isreal(deltaP_final) || ~isfinite(deltaP_final) || deltaP_final <= 0
                report.warnings{end+1} = '最終時刻の供給差圧が正ではありません。最終タンク圧力を見直してください。';
                return
            end

            final.mdot_ox = p.Cd*pi/4*do^2*sqrt(2*rho_ox*deltaP_final);
            final.mdot_f = rho_f*fuel.Lf*pi*fuel.dfs(end,1)*fuel.a* ...
                (4*final.mdot_ox/(pi*fuel.dfs(end,1)^2))^fuel.n;
            final.mdot_p = final.mdot_ox+final.mdot_f;
            final.of = final.mdot_ox/final.mdot_f;
            final.cstar = interpolate(final.pc,final.of,cstar);
            final.gamma = interpolate(final.pc,final.of,gamma);
            final.Cf = sqrt(2*final.gamma^2/(final.gamma-1)* ...
                (2/(final.gamma+1))^((final.gamma+1)/(final.gamma-1))* ...
                (1-(pe/final.pc)^((final.gamma-1)/final.gamma)));
            final.F = final.Cf*p.cstar_eff*final.cstar*final.mdot_p;

            ave_F = (supply.F+final.F)/2;
            I = ave_F*fuel.planed_burning_time;

            report.final = final;
            report.ave_F = ave_F;
            report.I = I;
            report.I_req = I_req;
            report.achieved = I >= I_req;

            if ~report.achieved
                vt_predicted = (I_req * fuel.ave.mdot_ox) / (rho_ox * ave_F);
                report.warnings{end+1} = sprintf( ...
                    ['要求トータルインパルス未達（現在 %.1f Ns / 目標 %.1f Ns）。' ...
                     'タンク容量を%.0f cc以上にするか、要求推力・要求トータルインパルスを見直してください。'], ...
                    I, I_req, vt_predicted*10^6);
            end

            %結果パラメータの割り当て(元のdesign_parameterと同じフィールド構成).
            parameters.pti=supply.pt;               %初期タンク圧
            parameters.ptf=final.pt;                %最終タンク圧
            parameters.pci=supply.pc;               %初期燃焼室圧
            parameters.pbt=fuel.planed_burning_time;%燃焼予定時間
            parameters.vt=vt;                       %酸化剤充填量
            parameters.rho_ox=rho_ox;               %酸化剤密度
            parameters.gamma_ox=10;                 %酸化剤比熱比
            parameters.do=do;                       %オリフィス内径
            parameters.Cd=p.Cd;                     %流量係数
            parameters.rho_f=rho_f;                 %燃料密度
            parameters.Lf=fuel.Lf;                  %燃料長さ
            parameters.dfi=fuel.dfs(1,1);           %初期ポート径
            parameters.port=1;                      %ポート数
            parameters.a=fuel.a;                    %酸化剤流束係数
            parameters.n=fuel.n;                    %酸化剤流束指数
            parameters.cstar_eff=p.cstar_eff;       %特性排気速度効率
            parameters.pse=pe;                      %背圧
            parameters.dti=supply.dthroat;          %初期スロート径
            parameters.de=0.02;                     %ノズル出口径(元コード踏襲、算出値はsupply.deに別途格納)
            parameters.alpha=15;                    %ノズル半頂角
            parameters.ros=0;                       %エロ―ジョン速度
            parameters.cstar=cstar;                 %特性排気速度
            parameters.gamma=gamma;                 %比熱比

            report.parameters = parameters;
            report.dfs = fuel.dfs;
            report.time_step = fuel.time_step;
            report.ok = true;
        end

        %======================================================
        % 純粋関数群（inputやquestdlgを持たない）
        %======================================================

        %初期O/F比の決定.
        function of = Calc_of(cstar, method, manual_of)
            sample_of_rev = [0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,8.5,9,9.5,10];
            if method == "manual"
                of = manual_of;
            else
                [~,i_max] = max(cstar);
                %CEAグリッドの最終行(O/F=100)はsample_of_revの対象外のため、
                %表の範囲内にクランプする(元コードにあった潜在的な範囲外参照を防止).
                i_max = min(i_max, numel(sample_of_rev));
                of = mean(sample_of_rev(i_max)) + 0.5;
            end
        end

        %供給系設計（オリフィス径・タンク圧等から初期状態を算出）.
        %ofi,pti,cstar_eff,Cd,doは全てダッシュボード側の入力値.
        function [supply, status] = Calc_Supply_System(cstar,gamma,pe,rho_ox,F_req,ofi,pti,cstar_eff,Cd,do)
            status.ok = false;
            status.message = '';
            supply = struct();

            pressure_step = 10^3;
            pci = Mode5_Design_HomebrewEngine.CeaSearchSeedPressure(pti,pressure_step);

            mdot_pi = 0;
            mdot_pmin = 0;
            found = true;
            cstari = NaN; gammai = NaN; Cfi = NaN; mdot_oxi = NaN;

            while(mdot_pi <= mdot_pmin)
                pci = pci - pressure_step;
                if(pci <= pe)
                    pci = pci + pressure_step;
                    found = false;
                    break;
                end
                cstari = interpolate(pci,ofi,cstar);
                gammai = interpolate(pci,ofi,gamma);
                Cfi = sqrt(2*gammai^2/(gammai - 1)* ...
                    (2/(gammai + 1))^((gammai + 1)/(gammai - 1))* ...
                    (1-(pe/pci)^((gammai - 1)/gammai)));
                mdot_pmin = F_req/(Cfi*cstar_eff*cstari);
                mdot_oxi = Cd*pi/4*do^2*sqrt(2*rho_ox*(pti - pci));
                mdot_pi = (1 + 1/ofi) * mdot_oxi;
            end

            if ~found
                %必要な流量を達成できない場合の改善案を算出（元コードのo/c/e/f分岐に相当）.
                cstar_eff_predicted = mdot_pmin*cstar_eff/mdot_pi;
                Cd_predicted = mdot_pmin*Cd/mdot_pi;
                do_predicted = sqrt(mdot_pmin*(do^2)/mdot_pi);
                F_achievable = search_max_thrust(cstar,gamma,pe,rho_ox,ofi,pti,cstar_eff,Cd,do,F_req);

                status.message = sprintf( ...
                    ['供給系が必要流量を達成できません。改善案: ' ...
                     '特性排気速度効率を%.3f超に / 流量係数を%.3f超に / オリフィス径を%.2fmm超に、' ...
                     'のいずれかにするか、要求推力を%.0fN以下に見直してください。'], ...
                    cstar_eff_predicted, Cd_predicted, do_predicted*10^3, F_achievable);
                return
            end

            %初期推力
            Fi = Cfi*cstar_eff*cstari*mdot_pi;
            %ノズルスロート径(算出値→製造値へ丸め)
            dthroat_calc = sqrt(4*cstar_eff*cstari*mdot_pi/(pi*pci));
            dthroat = round(dthroat_calc*10^3,2)*10^(-3);
            %開口比
            Epsilon = ((2/(gammai + 1))^(1/(gammai - 1))*(pci/pe)^(1/gammai))/ ...
                sqrt((gammai + 1)/(gammai - 1)*(1 - (pe/pci)^((gammai - 1)/gammai)));
            %ノズル出口径
            de = round(dthroat*sqrt(Epsilon)*10^3,2)*10^(-3);

            supply.F = Fi;
            supply.cstar = cstari;
            supply.gamma = gammai;
            supply.of = ofi;
            supply.pc = pci;
            supply.pt = pti;
            supply.Cf = Cfi;
            supply.mdot_ox = mdot_oxi;
            supply.mdot_p = mdot_pi;
            supply.dthroat = dthroat;
            supply.Epsilon = Epsilon;
            supply.de = de;

            status.ok = true;
            status.message = 'OK';
        end

        %燃料ポート径の時間変化（ルンゲクッタ）とスライバ率を算出.
        function [lf, status] = Calc_Lf(initial, rho_f, planed_burning_time, ave, df, Df)
            status.ok = false;
            status.message = '';
            lf = struct();

            a=1.16*10^(-4);   %酸化剤流束係数
            n=0.33;           %酸化剤流束指数
            time_step=0.005;  %タイムサンプリングレート

            i_max = round(planed_burning_time/time_step);
            i_max = min(max(i_max,1),200000); %安全上限（GUIが固まらないようにするための上限）

            dfs=zeros(i_max,1);
            for i=1:i_max
                if(i==1)
                    dfs(i,1)=df;
                else
                    dfs(i,1)=rungekutta(dfs(i-1,1),ave.mdot_ox,a,n,time_step);
                end
            end

            df_initial = dfs(1,1);
            df_final = dfs(end,1);
            phi=(Df^2 - df_final^2)/(Df^2 - df_initial^2)*100;

            lf.dfs = dfs;
            lf.a = a;
            lf.n = n;
            lf.time_step = time_step;
            lf.phi = phi;

            if(phi > 100 || 0 > phi)
                status.message = sprintf( ...
                    'スライバ率が異常です(%.1f%%)。初期ポート径を%.2fmm以上にしてください。', ...
                    phi, df*10^3);
                lf.Lf = NaN;
                return
            end

            Lf=(initial.mdot_ox/initial.of)/(pi*df*rho_f*a)* ...
                (4*initial.mdot_ox/(pi*df^2))^(-n);
            lf.Lf = round(Lf,3);

            status.ok = true;
            status.message = 'OK';
        end

        %燃料系設計（最終圧力・燃料長さ・特性長の整合性チェック）.
        function [fuel, status] = Calc_Fuel_System(initial, vt, rho_ox, rho_f, Cd, do, final_pt, Lf_max, Lstar_min, df, Df)
            status.ok = false;
            status.message = '';
            fuel = struct();

            final_pt_min = initial.pc^2/initial.pt;
            if ~(isscalar(final_pt) && isreal(final_pt) && isfinite(final_pt) && final_pt > final_pt_min)
                status.message = sprintf( ...
                    '最終タンク圧力では供給差圧を確保できません。%.3fMPaより大きく設定してください。', ...
                    final_pt_min*10^(-6));
                return
            end

            final.pc = initial.pc*sqrt(final_pt/initial.pt);
            final.pt = final_pt;

            if(final.pt <= final.pc)
                status.message = '最終タンク圧が最終燃焼室圧以下です。最終タンク圧力を見直してください。';
                return
            end

            %平均圧力・平均酸化剤流量・予定燃焼時間
            ave.pt=(initial.pt+final.pt)/2;
            ave.pc=(initial.pc+final.pc)/2;
            ave.mdot_ox=Cd*pi/4*do^2*sqrt(2*rho_ox*(ave.pt-ave.pc));

            if ~isfinite(ave.mdot_ox) || ave.mdot_ox <= 0
                status.message = '平均酸化剤流量が算出できません。オリフィス径・タンク圧力を見直してください。';
                return
            end

            planed_burning_time=vt*rho_ox/ave.mdot_ox;
            if ~isfinite(planed_burning_time) || planed_burning_time <= 0
                status.message = '燃焼予定時間が算出できません。タンク容量・流量を見直してください。';
                return
            end

            [lf, lfStatus] = Mode5_Design_HomebrewEngine.Calc_Lf(initial, rho_f, planed_burning_time, ave, df, Df);
            if ~lfStatus.ok
                status.message = lfStatus.message;
                return
            end

            Lf = lf.Lf;
            dthroat = initial.dthroat;
            Lf_min = Lstar_min*dthroat^2/df^2;

            fuel.Lf = Lf;
            fuel.Lf_min = Lf_min;
            fuel.dfs = lf.dfs;
            fuel.a = lf.a;
            fuel.n = lf.n;
            fuel.time_step = lf.time_step;
            fuel.phi = lf.phi;
            fuel.planed_burning_time = planed_burning_time;
            fuel.ave = ave;
            fuel.final = final;

            if(Lf_min > Lf_max)
                %必要最小燃料長さが最大燃料長さを超えている＝現設定では原理的に不可能.
                Lstar_min_predict = Lf_max * df^2/dthroat^2;
                Initialof_predict = sqrt((Lstar_min * dthroat^2)/Lf_max);
                status.message = sprintf( ...
                    ['必要最小燃料長さ(%.3fm)が最大燃料長さ(%.3fm)を超えています。' ...
                     '必要燃焼室特性長を%.3fm未満にするか、初期ポート径を%.2fmm以上にしてください。'], ...
                    Lf_min, Lf_max, Lstar_min_predict, Initialof_predict*10^3);
                return
            elseif(Lf > Lf_max)
                Initialof_predict = nthroot(Lf*df^(1-2*lf.n)/Lf_max,1-2*lf.n);
                mdot_f_needed = Lf_max*pi*df*rho_f*lf.a*(4*initial.mdot_ox/(pi*df^2))^lf.n;
                of_suggested = initial.mdot_ox/mdot_f_needed;
                status.message = sprintf( ...
                    ['燃料長さ(%.3fm)が最大燃料長さ(%.3fm)を超えています。' ...
                     '初期ポート径を%.2fmm以下にするか、初期O/F比を%.2f以上にしてください。'], ...
                    Lf, Lf_max, Initialof_predict*10^3, of_suggested);
                return
            elseif(Lf_min > Lf)
                Lstar_min_predict = Lf * df^2/dthroat^2;
                status.message = sprintf( ...
                    ['燃料長さ(%.3fm)が必要最小燃料長さ(%.3fm)を下回っています。' ...
                     '初期ポート径を大きくするか、必要燃焼室特性長を%.3fm未満にしてください。'], ...
                    Lf, Lf_min, Lstar_min_predict);
                return
            end

            status.ok = true;
            status.message = 'OK';
        end

        %グレインのポート径・後退速度の時間変化をCSV出力.
        function ExportGrainHistory(dfs, time_step, a, n, ave_mdot_ox, outputDir)
            time = (0:length(dfs)-1)'*time_step;         %時間[s]
            rdot = 2*a*(4*ave_mdot_ox./(pi*dfs.^2)).^n;   %燃料後退速度[m/s]

            if ~exist(outputDir, 'dir')
                mkdir(outputDir);
            end

            dfTable = table(time,dfs,'VariableNames',{'time[s]','df[m]'});
            writetable(dfTable,fullfile(outputDir,'DesignEngine_df_history.csv'));

            rdotTable = table(time,rdot,'VariableNames',{'time[s]','rdot[m/s]'});
            writetable(rdotTable,fullfile(outputDir,'DesignEngine_rdot_history.csv'));

            disp(['CSVを出力しました: ', outputDir]);
        end

        function pc_grid = CeaPressureGrid()
            pc_grid = [0.004,0.01,0.2,0.4,0.6,0.8,1.0,1.2, ...
                1.4,1.6,1.8,2.0,2.2,2.4,2.6,2.8,3.0].*(10^6);
        end

        function pci = CeaSearchSeedPressure(pti,pressure_step)
            if ~isnumeric(pti) || ~isscalar(pti) || ~isreal(pti) || ~isfinite(pti)
                error("初期タンク圧力ptiが不正です。");
            end

            if ~isnumeric(pressure_step) || ~isscalar(pressure_step) || ...
                    ~isreal(pressure_step) || ~isfinite(pressure_step) || pressure_step <= 0
                error("燃焼室圧力の探索刻みが不正です。");
            end

            pc_grid = Mode5_Design_HomebrewEngine.CeaPressureGrid();
            pci = min(pti,max(pc_grid)+pressure_step);
        end

    end
end

%達成可能な最大要求推力を探索（Calc_Supply_Systemの改善案表示用）.
%GUIが固まらないよう反復回数に上限を設ける.
function F_achievable = search_max_thrust(cstar,gamma,pe,rho_ox,ofi,pti,cstar_eff,Cd,do,F_req_start)
F_req_temp = F_req_start;
max_outer_iter = 100000;
outer_iter = 0;

while(outer_iter < max_outer_iter)
    outer_iter = outer_iter + 1;
    F_req_temp = F_req_temp - 1;
    if(F_req_temp <= 0)
        F_achievable = 0;
        return
    end

    pressure_step_temp = 10^5;
    pci = Mode5_Design_HomebrewEngine.CeaSearchSeedPressure(pti,pressure_step_temp);
    mdot_pi = 0;
    mdot_pmin = 0;
    found = true;

    while(mdot_pi <= mdot_pmin)
        pci = pci - pressure_step_temp;
        if(pci <= pe)
            found = false;
            break;
        end
        cstari = interpolate(pci,ofi,cstar);
        gammai = interpolate(pci,ofi,gamma);
        Cfi = sqrt(2*gammai^2/(gammai - 1)* ...
            (2/(gammai + 1))^((gammai + 1)/(gammai - 1))* ...
            (1-(pe/pci)^((gammai - 1)/gammai)));
        mdot_pmin = F_req_temp/(Cfi*cstar_eff*cstari);
        mdot_oxi = Cd*pi/4*do^2*sqrt(2*rho_ox*(pti - pci));
        mdot_pi = (1 + 1/ofi) * mdot_oxi;
    end

    if(found)
        F_achievable = F_req_temp;
        return
    end
end

F_achievable = 0;
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
sample.pc=Mode5_Design_HomebrewEngine.CeaPressureGrid();
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
