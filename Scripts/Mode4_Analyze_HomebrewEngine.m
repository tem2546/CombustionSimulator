classdef Mode4_Analyze_HomebrewEngine < BaseSystem

    %自作エンジン解析用
    %SUBARUのシミュレーションを用いてエンジン推力を推定する際、
    %流量係数や酸化剤流束係数、酸化剤流束指数、c*効率の4つのパラメータを知っている必要がある.
    %この4つのパラメータを自作エンジンから得たデータから推定するモード.
    %推定対象のパラメータが多すぎるため、精度の評価もままならない.
    properties
        pt=0;           %タンク圧
        mg=0;           %気体質量
        ml=0;           %液体質量
        Vg=0;           %気体体積
        Vl=0;           %液体体積
        mdot_ox=0;      %質量流量@オリフィス
        mdot_vent=0;    %質量流量@ベントチューブ
        Tl=0;           %液体温度
        Tg=0;           %気体温度
        dthetadt=0;     %過熱度 
        dt=0;           %時間
        x=0;            %気相存在比
        pc          %燃焼圧[i]
        pe          %ノズル出口圧[i-1/2]
        df          %燃料ポート径[i]
        dnt         %ノズルスロート径[i-1/2]
        dne         %ノズル出口径[i-1/2]
        mdot_f      %燃料流量[i-1/2]
        of          %O/F比[i-1/2]
        cstar       %特性排気速度[i-1/2]
        gamma       %比熱比[i-1/2]
        cf          %推力係数[i-1/2]
        thrust      %推力[i-1/2]
    end

    methods
        %手続き関数.
        %main関数ではこれが呼び出される.
        function Class = run(Class, gs)
            %データの取り込み
            disp('データの取り込みを開始します。')
            Class = Class.Input(gs);
            disp('データの取り込みが完了しました。')
            %推力データのカット
            disp('推力データのカットを開始します。')
            Class = Class.History(gs);
            disp('推力データのカットが完了しました。')
            if(isfield(Class.output.origin,'ResidualTime'))
                Class.data.tank.t_liquid = Class.output.origin.ResidualTime;
            end
            %タンク計算
            disp('タンク計算を開始します。')
            [tank,constant,result] = Class.Tank();
            disp('タンク計算が完了しました。')

            %燃焼室計算
            disp('燃焼室計算を開始します。')
            [chamber,~,result] = Class.Chamber(tank,constant,result);
            disp('燃焼室計算が完了しました。')
            % %グラフの出力
            % disp('グラフの出力を開始します。')
            % choice.graph = Graph(Class);
            % disp('グラフの出力を完了しました。')
            Class.Output(tank,chamber,result);
            
        end

        %自作エンジン解析用入力
        function Class = Input(Class, gs)
            %自作エンジン用
            %ファイル読み込み
            [Class,enginedata,thrustdata,CEAdata,oxiddata,choice] = Class.Infile(gs);
            choice.load = "No";
            %tankインスタンス
            data.tank.vt=enginedata(1,4)*10^-6;              %タンク容量[m^3]
            data.tank.pto=thrustdata(5,6)*10^6;              %初期タンク圧[Pa]

            data.tank.flow.do=enginedata(2,4)*25.4*10^-3;    %オリフィス径[m]
            data.tank.flow.dvent=thrustdata(14,6)*10^-3;     %ベントチューブ代表内径[m]
            data.tank.flow.Ao=data.tank.flow.do^2*pi/4;       %オリフィス断面積[m^2]
            data.tank.flow.Avent=data.tank.flow.dvent^2*pi/4; %ベントチューブ断面積[m^2]
            %obj.tank.flow.Cd=flow.Cd;                       %オリフィスの流量係数
            data.tank.flow.Cdvent=0;                         %ベントチューブの流量係数

            data.tank.A=(enginedata(3,4)*10^-3)^2*pi/4;      %配管代表面積[m^2]
            data.tank.t_liquid=thrustdata(15,6);             %液体存在時間[s]

            data.tank.oxid.gamma=thrustdata(12,6);           %酸化剤比熱比
            data.tank.oxid.n=thrustdata(13,6);               %酸化剤ポリトロープ指数
            data.tank.oxid.pa=thrustdata(4,6)*10^6;          %背圧[Pa]

            data.tank.oxiddata.T=oxiddata(:,1);              %温度
            data.tank.oxiddata.p=oxiddata(:,2);              %圧力
            data.tank.oxiddata.rhol=oxiddata(:,3);           %液体密度
            data.tank.oxiddata.rhog=oxiddata(:,4);           %気体密度
            data.tank.oxiddata.deltahsat=oxiddata(:,5);      %蒸発熱
            data.tank.oxiddata.cpl=oxiddata(:,6);            %定圧比熱（液相）
            data.tank.oxiddata.cpg=oxiddata(:,7);            %定圧比熱（気相）
            data.tank.oxiddata.hl=oxiddata(:,11);            %比エンタルピー（液相）
            data.tank.oxiddata.hg=oxiddata(:,12);            %比エンタルピー（気相）

            %chamberインスタンス
            data.chamber.fuel.l=enginedata(4,4)*10^-3;       %グレイン長[m]
            data.chamber.dfi=enginedata(5,4)*10^-3;          %初期グレイン内径[m]
            data.chamber.dti=enginedata(7,4)*10^-3;          %ノズルスロート径[m]
            data.chamber.de=enginedata(8,4)*10^-3;           %ノズル出口径[m]
            data.chamber.alpha=enginedata(9,4)/360*2*pi;     %半頂角[deg]
            data.chamber.ros=enginedata(10,4)*10^-3;         %エロージョン速度[m/s]
            data.chamber.vt=data.tank.vt;

            data.chamber.pse=thrustdata(4,6)*10^6;           %背圧[Pa]
            data.chamber.mff=thrustdata(8,6);                %燃料消費量[kg]
            data.chamber.fuel.rho=thrustdata(9,6);           %燃料密度[kg/m^3]

            data.chamber.gamma=CEAdata.gamma;                %比熱比@燃焼室
            data.chamber.cstar=CEAdata.cstar;                %特性排気速度

            %obj.chamber.cstar_eff=cstar_eff;                %特性排気速度効率
            data.chamber.a=0;                                %酸化剤流束係数
            data.chamber.n=thrustdata(11,6);                 %酸化剤流束指数

            %historyインスタンス
            data.t=thrustdata(:,1);                          %時刻[s]
            data.pt=thrustdata(:,2).*10^6.+data.chamber.pse;  %タンク圧力履歴[Pa]
            data.pc=thrustdata(:,3).*10^6.+data.chamber.pse;  %燃焼室圧力履歴[Pa]
            data.thrust=thrustdata(:,4);                     %推力履歴[N]
            Class.data = data;
            Class.choice = choice;
        end

        %自作エンジンファイル入力関数
        function [Class,enginedata,thrustdata,CEAdata,oxiddata,choice] = Infile(Class, gs)

            %解析するエンジンを選択
            % [infile_indxs.engine]=listdlg('PromptString','エンジンを選択',...
            %     'Name','Engine Selection',...
            %     'SelectionMode','Single',...
            %     'ListString',list.engine);
            if isprop(gs, 'm4_engine_select') && ~isempty(gs.m4_engine_select)
                choice.engine = string(gs.m4_engine_select);
            else
                msg = 'エンジンの型が指定されていません。';
                error(msg)
            end
            % choice.engine=list.engine{infile_indxs.engine};
            infile.engine=strcat(choice.engine,'_datasheet.xlsx');
            msg1=strcat('選択したエンジン：',choice.engine);
            disp(msg1)

            %解析する推力データを選択
            if isprop(gs, 'm4_thrust_file_select') && ~isempty(gs.m4_thrust_file_select)
                thrustFileObj = gs.m4_thrust_file_select;
                if isstruct(thrustFileObj) && isfield(thrustFileObj, 'fn') && ~isempty(thrustFileObj.fn)
                    infile.thrust = thrustFileObj.fn;
                    thrustFilePath = fullfile(thrustFileObj.path, infile.thrust);
                elseif ischar(thrustFileObj) || isstring(thrustFileObj)
                    thrustFilePath = char(thrustFileObj);
                    [~, name, ext] = fileparts(thrustFilePath);
                    infile.thrust = [name, ext];
                else
                    error('推力データファイルの指定が不正です。');
                end
            else
                error('推力データファイルが選択されていません。');
            end

            % cd('../Thrustdata')
            % infile.thrust=uigetfile("*.xlsx");
            % cd('../Scripts')

            filename=erase(infile.thrust,".xlsx");
            choice.thrust=cell2mat(extract(filename,digitsPattern + textBoundary));
            msg2=strcat('読み込む推力データファイル：',infile.thrust);
            disp(msg2)

            %酸化剤を選択
            % [infile_indxs.oxidant]=listdlg('PromptString','酸化剤を選択',...
            %     'Name','Oxidant Selection',...
            %     'SelectionMode','Single',...
            %     'ListString',list.oxidant);
            % choice.oxidant=list.oxidant{infile_indxs.oxidant};
            if isprop(gs, 'm4_oxidant_select') && ~isempty(gs.m4_oxidant_select)
                choice.oxidant = string(gs.m4_oxidant_select);
            else
                error('酸化剤が指定されていません。');
            end
            infile.oxidant=strcat(choice.oxidant,'_data.xlsx');
            msg3=strcat('選択した酸化剤：',choice.oxidant);
            disp(msg3)


            %燃料を選択
            % [infile_indxs.fuel]=listdlg('PromptString','燃料を選択',...
            %     'Name','Fuel Selection',...
            %     'SelectionMode','Single',...
            %     'ListString',list.fuel);
            % choice.fuel=list.fuel{infile_indxs.fuel};
            if isprop(gs, 'm4_fuel_select') && ~isempty(gs.m4_fuel_select)
                choice.fuel = string(gs.m4_fuel_select);
            else
                error('燃料が指定されていません。');
            end
            msg4=strcat('選択した燃料：',choice.fuel);
            disp(msg4)

            infile.cstar=strcat(choice.fuel,choice.oxidant,'_cstar.csv');
            infile.gamma=strcat(choice.fuel,choice.oxidant,'_gamma.csv');

            %ファイルの読み込み
            % cd('../Engine_datasheet');
            % enginedata=readmatrix(infile.engine);       %エンジンデータ
            % cd('../Thrustdata');
            % thrustdata=readmatrix(infile.thrust);       %推力データ
            % cd('../CEAdata');
            % CEAdata.cstar=readmatrix(infile.cstar);     %特性排気速度
            % CEAdata.gamma=readmatrix(infile.gamma);     %比熱比@燃焼室
            % cd('../Oxidantdata');
            % oxiddata=readmatrix(infile.oxidant);        %酸化剤データ
            % cd('../Scripts');
            enginedata = readmatrix(fullfile('../Engine_datasheet', infile.engine));
            thrustdata = readmatrix(thrustFilePath);
            CEAdata.cstar = readmatrix(fullfile('../CEAdata', infile.cstar));
            CEAdata.gamma = readmatrix(fullfile('../CEAdata', infile.gamma));
            oxiddata = readmatrix(fullfile('../Oxidantdata', infile.oxidant));
        end

        %タンク圧データを基に流量係数を推定.
        function [tank,constant,result] = Tank(Class)
            if(isfield(Class.history,'pt') == false)
                error('圧力履歴がないため燃焼解析ができません。')
            end
            tank = Class.data.tank;
            history = Class.history;

            initialx=0.01;                                                              %酸化剤の気体存在比
            ti=interp1(tank.oxiddata.p,tank.oxiddata.T,tank.pto,'makima');              %初期タンク圧における酸化剤温度
            initial.pt=history.pt(1);                                                   %推力データの初期タンク圧
            initial.ml=interp1(tank.oxiddata.p,tank.oxiddata.rhol,tank.pto,'makima')*tank.vt*(1-initialx);  %初期タンク圧における酸化剤の液体質量
            initial.Vg=tank.vt*initialx;                                                %初期タンク圧における酸化剤の気体体積
            initial.mg=interp1(tank.oxiddata.p,tank.oxiddata.rhog,tank.pto,'makima')*tank.vt*initialx;      %初期タンク圧における酸化剤の気体質量
            initial.Vl=tank.vt*(1-initialx);                                            %初期タンク圧における酸化剤の液体体積
            initial.Tl=ti;                                                              %初期タンク圧における酸化剤の液体温度
            initial.Tg=ti;                                                              %初期タンク圧における酸化剤の気体温度

            %オリフィスの流量係数推定(Cdを0-1の幅で動かし、誤差が最小となるように与える)
            determine_Cd=@(Cd)(Class.evaluate_Cd(initial,tank,history,Cd));
            tank.flow.Cd=fminbnd(determine_Cd,0,1,optimset('Display','iter'));
            %初期値設定
            i=1;        %インデックス
            flag=1;     %計算ループ用
            gasflag=1;  %気体フラグ（酸化剤を気体のみとみなすフラグ）
            x=0;        %気体存在比
            dtheta=0;   %温度変化

            %各パラメータを入力
            constant.tank = tank;
            constant.chamber.pse=tank.oxid.pa;                           %背圧(大気圧)
            constant.tank.flow.Avent=tank.flow.dvent^2*pi/4;             %ベントチューブ断面積
            constant.tank.flow.Ao=tank.flow.do^2*pi/4;                   %オリフィス断面積
            constant.dt=history.t(:,1);
            constant.chamber.t_liquid=tank.t_liquid;
            tankinfo(1:2*length(history.pc(:)))=Mode4_Analyze_HomebrewEngine;

            %タンク計算
            while(flag==1)
                %推力データ数以内では時刻の差を時間とする
                if(length(history.pt(:))>i)
                    constant.dt=history.t(i+1)-history.t(i);
                end

                %タンク関係パラメータの入力
                if(i==1)    %最初
                    tankinfo(i)=calculate_tank(tankinfo(i),initial,constant,x,dtheta,history.pc(i),history.pc(i));
                    result.pt(i,1)=tankinfo(i).pt;  %タンク圧
                elseif(gasflag==1)
                    tank.oxid.gamma=1;
                    tank.oxid.n=tank.oxid.gamma;
                    %tankinfo(i-1).pt = history.pt(i-1);
                    tankinfo(i)=calculate_tank(tankinfo(i),tankinfo(i-1),constant,x,dtheta,history.pc(i),history.pc(i));
                    result.pt(i,1)=tankinfo(i).pt;  %タンク圧
                else
                    %tankinfo(i-1).pt = history.pt(i-1);
                    tankinfo(i)=calculate_gas(tankinfo(i),tankinfo(i-1),constant,history.pc(i),history.pc(i));
                    result.pt(i,1)=tankinfo(i).pt;  %タンク圧
                end

                %計算結果記入
                %result.pt(i,1)=tankinfo(i).pt;  %タンク圧
                result.ml(i,1)=tankinfo(i).ml;  %液体質量
                result.mg(i,1)=tankinfo(i).mg;  %気体質量
                result.Vl(i,1)=tankinfo(i).Vl;  %液体体積
                result.Vg(i,1)=tankinfo(i).Vg;  %気体体積
                result.Tl(i,1)=tankinfo(i).Tl;  %液体温度
                result.Tg(i,1)=tankinfo(i).Tg;  %気体温度

                %液体の体積存在比が非常に低い時
                if(tankinfo(i).Vl/(result.Vl(i)+result.Vg(i))<0.01)%
                    gasflag=0;
                end

                %推力データ数を超えたらループ終了
                if(length(history.pt(:))<=i)

                    flag=0;
                end

                i=i+1;
            end

            tank.tankinfo=tankinfo;
            tank.Cd=tank.flow.Cd;
            tank.t_liquid = tank.t_liquid;
            figure
            hold on
            plot(history.pt)
            plot(abs(result.pt))
            hold off
        end

        %流量係数用評価関数
        function error = evaluate_Cd(~,initial,tank,history,Cd)
            %初期値設定
            i=1;                    %インデックス用
            flag=1;                 %ループ用
            x=0;                    %気相比
            dtheta=0;               %温度変化
            error=0;                %誤差
            tank.flow.Cd=Cd;        %流量係数
            pse=tank.oxid.pa;       %背圧
            t_liquid=tank.t_liquid; %液体存在時間

            constant.tank = tank;
            constant.chamber.pse=tank.oxid.pa;                           %背圧(大気圧)
            constant.tank.flow.Avent=tank.flow.dvent^2*pi/4;             %ベントチューブ断面積
            constant.tank.flow.Ao=tank.flow.do^2*pi/4;                   %オリフィス断面積

            tankinfo(1:2*length(history.pc(:))) = Mode4_Analyze_HomebrewEngine;   %構造体tankinfoを時間ごとのタンクデータ出力用に用意
            result = history.pt;
            while(flag==1)

                if length(history.pt(:))>i
                    constant.dt = history.t(i+1) - history.t(i);      %時間差を出力
                end

                if(i==1)    %最初
                    tankinfo(i)=calculate_tank(tankinfo(i),initial,constant,x,dtheta,history.pc(i),history.pc(i));
                elseif(i>length(history.pc(:)))    %データの範囲外
                    %tankinfo(i-1).pt = history.pt(i-1);
                    tankinfo(i)=calculate_tank(tankinfo(i),tankinfo(i-1),constant,x,dtheta,pse,pse);
                    result(i) = tankinfo(i).pt;
                else        %途中
                    %tankinfo(i-1).pt = history.pt(i-1);
                    tankinfo(i)=calculate_tank(tankinfo(i),tankinfo(i-1),constant,x,dtheta,history.pc(i),history.pc(i));
                    result(i) = tankinfo(i).pt;
                end

                %酸化剤の液体体積が小さい場合ループ終了
                if(tankinfo(i).Vl/(tankinfo(i).Vl+tankinfo(i).Vg)<0.01)
                    flag=0;
                end

                %推力データ数を超えたらループ終了
                if(length(history.t(:))<=i)
                    flag=0;
                end
                if(t_liquid*180 > i)
                    error = error + abs(history.pt(i) - abs(result(i)))/abs(history.pt(i));
                end
                i=i+1;
            end


        end

        %燃料消費量の誤差を求める関数
        function error=evaluate_mf(~,tankinfo,constant,data,chamber,a)
            %初期値設定
            i=1;        %インデックス用
            flag=1;     %ループ用
            constant.chamber.a=a;        %酸化剤流束係数
            initialchamberinfo=Mode4_Analyze_HomebrewEngine; %燃焼室関係パラメータ（初期値）の入力
            initialchamberinfo.df=chamber.dfi;      %燃料ポート径
            mff=chamber.mff;

            %燃焼室関係パラメータの入力
            chamberinfo(1:length(data.pc(:)))=Mode4_Analyze_HomebrewEngine;

            %最初のデータの燃料ポート径
            chamberinfo(i)=analyze_df(chamberinfo(1),initialchamberinfo,tankinfo(1),constant);

            while(flag==1)
                i=i+1;
                constant.dt=data.t(i)-data.t(i-1);

                %燃料ポート径
                chamberinfo(i)=analyze_df(chamberinfo(i),chamberinfo(i-1),tankinfo(i),constant);

                %推力データ数を超えたらループ終了
                if(length(data.t(:))<=i)
                    break;
                end
            end

            %燃料消費量
            mf=(chamberinfo(i).df^2-chamberinfo(1).df^2)*pi*constant.chamber.lf*constant.chamber.rhof/4;
            %燃料消費量の誤差
            error=abs(mff-mf);
        end

        function [obj,constant,result] = Chamber(Class,tank,constant,result)
            chamber = Class.data.chamber;
            history = Class.history;
            tankinfo=tank.tankinfo;

            %燃焼室パラメータの量
            imax=3000;

            %燃焼室関係パラメータの入力
            constant.chamber.gamma=chamber.gamma;                %比熱比@燃焼室
            constant.chamber.cstar=chamber.cstar;                %特性排気速度
            constant.chamber.cstar_eff=1;                        %特性排気速度効率
            constant.chamber.a=chamber.a;                        %酸化剤流束係数
            constant.chamber.n=chamber.n;                        %酸化剤流束指数
            constant.chamber.lf=chamber.fuel.l;                  %グレイン長
            constant.chamber.rhof=chamber.fuel.rho;              %グレイン密度
            constant.chamber.alpha=chamber.alpha;                %ノズル半頂角
            chamberinfo(2:imax)=Mode4_Analyze_HomebrewEngine;

            %燃料消費量の誤差が最小になるような酸化剤流束係数
            determine_a=@(a)(Class.evaluate_mf(tankinfo,constant,history,chamber,a));
            constant.chamber.a=fminbnd(determine_a,0,0.001, optimset('Display','iter','Tolx',1.0e-10));

            i=1;
            chamberinfo(i).df=chamber.dfi;      %初期ポート径
            chamberinfo(i).dnt=chamber.dti;     %初期ノズルスロート径

            i=i+1;
            cstar_eff=0;         %特性排気速度効率
            cf_eff=0;            %推力係数効率
            mpropellant=0;       %推進剤消費量
            combustion_flag=1;   %燃焼室計算用フラグ

            %燃焼室計算
            while(combustion_flag==1)
                %時間
                constant.dt=history.t(i)-history.t(i-1);
                %ノズルスロート径
                chamberinfo(i).dnt=chamber.dti+chamber.ros*constant.dt*(i-3/2);
                %ノズル出口径
                chamberinfo(i).dne=chamber.de;
                %燃焼室圧力
                chamberinfo(i).pc=history.pc(i);
                %燃焼室関係パラメータ
                chamberinfo(i)=calculate_chamber(chamberinfo(i),chamberinfo(i-1),tankinfo(i),constant);
                %酸化剤流束
                Gox(i)=tankinfo(i).mdot_ox/(pi*chamberinfo(i).df^2/4);

                %推進剤質量
                mpropellant=mpropellant+(chamberinfo(i).mdot_f+tankinfo(i).mdot_ox)*constant.dt;

                %特性排気速度効率
                cstar_eff=cstar_eff+constant.dt*history.pc(i)*(pi*(chamberinfo(i).dnt^2)/4)/chamberinfo(i).cstar;
                %推力係数効率
                cf_eff=cf_eff+(chamberinfo(i).mdot_f+tankinfo(i).mdot_ox)*constant.dt*history.thrust(i)/chamberinfo(i).thrust;

                %推力データ数を上回ったらループ終了
                if(length(history.pt(:))<=i)
                    combustion_flag=0;
                end

                i=i+1;
            end

            %結果入力用
            for m=1:i-1
                if(m==1)    %最初
                    %トータルインパルス
                    result.impulse(m,1)=0;
                else        %途中
                    if(m==2)
                        %酸化剤消費量
                        result.mox(m,1)=tankinfo(m).mdot_ox*constant.dt;
                    end

                    %酸化剤消費量
                    result.mox(m,1)=result.mox(m-1)+tankinfo(m).mdot_ox*constant.dt;
                    %トータルインパルス
                    result.impulse(m,1)=result.impulse(m-1)+chamberinfo(m).thrust*constant.dt;
                    %obj.total_impulse=result(m,1);
                    %燃料質量流量
                    result.mdot_f(m,1)=chamberinfo(m).mdot_f;
                    %燃料ポート径
                    result.df(m,1)=chamberinfo(m).df;
                    %燃料消費量
                    result.mf(m,1)=(chamberinfo(m).df^2-chamber.dfi^2)*pi*constant.chamber.lf*constant.chamber.rhof/4;
                    %燃焼室圧力
                    result.pc(m,1)=chamberinfo(m).pc;
                    %O/F比
                    result.of(m,1)=chamberinfo(m).of;
                    %特性排気速度
                    result.cstar(m,1)=chamberinfo(m).cstar;
                    %推力係数
                    result.cf(m,1)=chamberinfo(m).cf;
                    %ノズル出口圧力
                    result.pe(m,1)=chamberinfo(m).pe;
                    %推力
                    result.thrust(m,1)=chamberinfo(m).thrust;
                end
            end

            obj.chamberinfo = chamberinfo;
            obj.a=constant.chamber.a;
            obj.n=constant.chamber.n;

            %特性排気速度効率
            obj.cstar_eff=cstar_eff/mpropellant;
            %推力係数効率
            obj.cf_eff=cf_eff/mpropellant;
        end
        
        function obj = Output(Class,tank,chamber,result)

            choice = Class.choice;
            history = Class.history;
            output = Class.output.origin;

            figure
            hold on
            plot(history.thrust);
            plot(result.thrust);
            hold off
            disp('**********************エンジン情報**********************')
            obj.type = "自作エンジン";
            msg.engine = strcat('使用したエンジン：',choice.engine);
            disp(msg.engine)
            msg.date = strcat('実験日：',choice.thrust);
            disp(msg.date)
            msg.oxidant = strcat('使用した酸化剤：',choice.oxidant);
            disp(msg.oxidant)
            msg.fuel = strcat('使用した燃料：',choice.fuel);
            disp(msg.fuel)
            msg.max_thrust = strcat('最大推力：',num2str(output.max_thrust),'[N]');
            disp(msg.max_thrust)
            msg.average_thrust = strcat('平均推力：',num2str(output.average_thrust),'[N]');
            disp(msg.average_thrust)
            msg.burning_time = strcat('燃焼時間：',num2str(output.burning_time),'[s]');
            disp(msg.burning_time)
            msg.max_pc = strcat('最大燃焼室圧力：',num2str(output.max_pc),'[Pa]');
            disp(msg.max_pc)
            msg.total_impulse1 = strcat('トータルインパルス（実測値）：',num2str(output.total_impulse),'[Ns]');
            disp(msg.total_impulse1)
            msg.t_liquid = strcat('液体存在時間：',num2str(tank.t_liquid),'[s]');
            disp(msg.t_liquid)
            disp('************************推定結果************************')
            msg.Cd = strcat('オリフィス流量係数：',num2str(tank.Cd));
            disp(msg.Cd)
            msg.a = strcat('酸化剤流量係数：',num2str(chamber.a));
            disp(msg.a)
            msg.n = strcat('酸化剤流量指数：',num2str(chamber.n));
            disp(msg.n)
            msg.cstar_eff = strcat('特性排気速度効率：',num2str(chamber.cstar_eff));
            disp(msg.cstar_eff)
            msg.cf_eff = strcat('推定精度率：',num2str(chamber.cf_eff));
            disp(msg.cf_eff)
            msg.total_impulse2 = strcat('トータルインパルス（再現値）：',num2str(result.impulse(end)),'[Ns]');
            disp(msg.total_impulse2)
            msg.average_thrust3 = strcat('平均推力（再現値）：',num2str(mean(result.thrust(2:end))),'[N]');
            disp(msg.average_thrust3)

            disp('********************************************************')
            obj.msg = msg;

        end

        %タンク関係パラメータ計算用
        function obj = calculate_tank(obj,preobj,constant,x,dthetadt,prepc,pc)
            %それぞれのフィールドに値を入力
            obj.dt=constant.dt;     %時間
            obj.x=x;                %気相比
            obj.dthetadt=dthetadt;  %過熱度
            
            %初期値を設定
            prey=[preobj.pt,preobj.ml,preobj.Vg,preobj.Tl,preobj.Tg,preobj.mg,preobj.Vl,0,0];
            
            %Runge-Kuttaに乗っ取った式でパラメータを出力
            y=rungekutta(obj,constant,prey,prepc,pc);
            
            %更新式で算出したパラメータを更新
            obj.pt=y(1);                %タンク圧
            obj.ml=y(2);                %液体質量            
            obj.Vg=y(3);                %気体体積
            obj.Tl=y(4);                %液体温度
            obj.Tg=y(5);                %気体温度
            obj.mg=y(6);                %気体質量            
            obj.Vl=y(7);                %液体体積
            obj.mdot_ox=y(8)/obj.dt;    %質量流量@オリフィス
            obj.mdot_vent=y(9)/obj.dt;  %質量流量@ベントチューブ
        end
        
        %タンク関係パラメータ計算用（酸化剤が気体のみの時）
        function obj = calculate_gas(obj,preobj,constant,prepc,pc)
            %各パラメータの収納
            obj.dt=constant.dt;
            centerpc=(prepc+pc)/2;
            oxid=constant.tank.oxid;
            flow=constant.tank.flow;
            
            %気体密度
            rhog=(preobj.mg+preobj.ml)/(preobj.Vg+preobj.Vl);
            
            %酸化剤質量流量
            obj.mdot_ox=flow.Cd*flow.Ao*sqrt(2*rhog*(preobj.pt-centerpc));
            %タンク圧
            obj.pt=preobj.pt*(preobj.Vg/(preobj.Vg+obj.mdot_ox*constant.dt/rhog))^oxid.gamma;
            %気体質量
            obj.mg=preobj.mg+preobj.ml-obj.mdot_ox*constant.dt;
            %気体体積
            obj.Vg=preobj.Vg+preobj.Vl;
            %液体体積
            preobj.Vl=0;
            %液体質量
            obj.ml=0;
        end
        
        %Runge-Kutta法(タンク関係パラメータ計算用)
        function y=rungekutta(obj,constant,prey,prepc,pc)
            %区間の最初における勾配
            k1 = f(prey,constant,obj.x,obj.dthetadt,prepc);
            secondinfo=prey+constant.dt*k1/2;
            %区間の中央における勾配の近似値
            k2=f(secondinfo,constant,obj.x,obj.dthetadt,(prepc+pc)/2);
            thirdinfo=prey+constant.dt*k2/2;
            %区間の中央における勾配の近似値
            k3=f(thirdinfo,constant,obj.x,obj.dthetadt,(prepc+pc)/2);
            lastinfo=prey+constant.dt*k3;
            %区間の最後における勾配の近似値
            k4=f(lastinfo,constant,obj.x,obj.dthetadt,pc);
            %最終的な計算値
            y=prey+(k1+2*k2+2*k3+k4)*constant.dt/6;
        end 

        %燃焼室パラメータ計算用
        function obj=calculate_chamber(obj,preobj,tankobj,constant)
            %燃焼室圧力
            centerpc=obj.pc;
            %燃焼室関係パラメータ
            combustion=constant.chamber;

            %燃料ポート径
            obj.df=rungekutta_df(preobj,tankobj,combustion,constant.dt);
            %燃料消費量
            obj.mdot_f=pi*(obj.df^2-preobj.df^2)*combustion.lf*combustion.rhof/(4*constant.dt);
            %O/F比
            obj.of=tankobj.mdot_ox/obj.mdot_f;

            %比熱比
            obj.gamma=interpolate(centerpc,obj.of,combustion.gamma);
            %特性排気速度
            obj.cstar=interpolate(centerpc,obj.of,combustion.cstar);

            %ノズル計算
            fun2=@(pe)abs(nozzle(centerpc,obj.gamma,pe)-(obj.dne/obj.dnt)^2);
            %出口圧力
            obj.pe=max(0.4*combustion.pse,fminsearch(fun2,0.4*combustion.pse));

            %推力係数
            obj.cf=((1+cos(deg2rad(combustion.alpha)))/2)*sqrt(2*(obj.gamma^2)/...
                (obj.gamma-1)*((2/(obj.gamma+1))^((obj.gamma+1)/...
                (obj.gamma-1)))*(1-(obj.pe/centerpc)^...
                ((obj.gamma-1)/obj.gamma)))+((obj.pe-combustion.pse)/...
                obj.pc)*((obj.dne^2)/(obj.dnt^2));

            %推力
            obj.thrust=obj.cf*centerpc*(pi*(obj.dnt^2)/4);
        end

        %燃料ポート径計算＆収納用
        function obj=analyze_df(obj,preobj,tankobj,constant)
           combustion=constant.chamber; 
           obj.df=rungekutta_df(preobj,tankobj,combustion,constant.dt);
        end 
        
        %Runge-Kutta法（燃料ポート径計算用）
        function dff=rungekutta_df(chamberobj,tankobj,combustion,dt)
            %燃料後退速度式
            rdot=@(df)(2*combustion.a*(tankobj.mdot_ox*4/(pi*df^2))^combustion.n);
          
            df1=chamberobj.df;
            k1=rdot(df1);        %区間の最初における勾配
            df2=df1+k1*dt/2;
            k2=rdot(df2);        %区間の中央における勾配の近似値
            df3=df1+k2*dt/2;
            k3=rdot(df3);        %区間の中央における勾配の近似値
            df4=df1+k3*dt;
            k4=rdot(df4);        %区間の最後における勾配の近似値
            %最終的な燃料ポート径
            dff=df1+(k1+2*k2+2*k3+k4)*dt/6;
        end   
    end
end

%Runge-Kutta法用
%おそらく更新式、ルンゲクッタ法の知識必須。
function kn=f(y,constant,x,dthetadt,pc)
    %データの移し替え
    oxid=constant.tank.oxid;
    flow=constant.tank.flow;
    oxidant=constant.tank.oxiddata;
    
    p=y(1);          %タンク圧力
    ml=y(2);         %液体質量
    Vg=y(3);         %気体体積
    Tl=y(4);         %液体温度
    Tg=y(5);         %気体温度
    mg=y(6);         %気体質量
    Vl=y(7);         %液体体積
    
    gamma=oxid.gamma;   %酸化剤の比熱比
    n=oxid.n;           %酸化剤のポリトロープ指数
    
    %液体密度
    rhol=ml/Vl;
    %rhol=interp1(oxidant.T,oxidant.rhol,Tl,'makima');
    %気体密度
    rhog=mg/Vg;

    %飽和気体密度
    rhogsat=interp1(oxidant.T,oxidant.rhog,Tl,'makima');

    %定圧比熱（液体）
    cpl=interp1(oxidant.T,oxidant.cpl,Tl,'makima');

    %定圧比熱（気体）
    cpg=interp1(oxidant.T,oxidant.cpg,Tg,'makima');

    %蒸発熱
    deltahsat=interp1(oxidant.T,oxidant.deltahsat,Tl,'makima');
    
    %比エンタルピー
    hgl=interp1(oxidant.T,oxidant.hg,Tl,'makima');
    hgg=interp1(oxidant.T,oxidant.hg,Tg,'makima');

    dTsatdpdeta=gradient(oxidant.p(:),5);
    dTsatdp=1/interp1(oxidant.p(:),dTsatdpdeta(:),p,'makima');
    drholdTldeta=gradient(oxidant.rhol(:),5);
    drholdTl=interp1(oxidant.T(:),drholdTldeta(:),Tl,'makima');
    
    %酸化剤質量流量@ベントチューブ
    mdot_vent=flow.Cdvent*flow.Avent*sqrt(2*rhog*(p-oxid.pa));

    %酸化剤質量流量@オリフィス
    mdot_ox=flow.Cd*flow.Ao*multiphase(p,pc,x,rhog,rhol);

    %
    alpha=(x/rhog)/((1-x)/rhol+x/rhog);
    
    %タンク圧OK(式32)
    kn(1)=(mdot_ox/((1-alpha)*rhol+alpha*rhog)...
         -(1/rhol-Tg/(Tl*rhogsat))*dthetadt*cpl*ml/(deltahsat+hgl-hgg)...
         +ml*dthetadt*drholdTl/(rhol*rhol))...
         /(-(Tg/(Tl*rhogsat)-1/rhol)*(dTsatdp*cpl*ml+(n-gamma)*Tg*cpg*mg/(n*gamma*p))/...
         (deltahsat+hgl-hgg)-ml*dTsatdp*drholdTl/(rhol*rhol)-Vg/(n*p));

     %液体質量OK(式33)
     kn(2)=((dTsatdp*kn(1)+dthetadt)*cpl*ml+(n-gamma)*Tg*cpg/(n*gamma*p))/(deltahsat+hgl-hgg)-(1-x)*mdot_ox;

     %気体体積
     kn(3)=-kn(2)/rhol;

     %気体体積
     kn(3)=-kn(2)/rhol+ml*drholdTl*(dTsatdp*kn(1)+dthetadt)/(rhol*rhol);
 
     %液体温度OK(式41)
     kn(4)=dTsatdp*kn(1)+dthetadt;
     
     %気体温度OK(式42)
     kn(5)=(n-1)/n*Tg/p*kn(1);
     
     %気体質量OK
     kn(6)=-(n-gamma)*Tg*cpg*kn(1)*mg/(n*gamma*p)/(deltahsat+hgl-hgg)-x*mdot_ox-mdot_vent;

     %気体質量
     kn(6)=-(kn(4)*cpl*ml+(n-gamma)*Tg*cpg*kn(1)/(n*gamma*p))/(deltahsat+hgl-hgg)-x*mdot_ox-mdot_vent;
     
     %液体体積OK
     kn(7)=kn(2)/rhol;
     %液体体積OK
     kn(7)=kn(2)/rhol-ml*drholdTl*(dTsatdp*kn(1)+dthetadt)/(rhol*rhol);     
     %酸化剤質量流量@オリフィス
     kn(8)=mdot_ox;
     
     %酸化剤質量流量@ベントチューブ
     kn(9)=mdot_vent;
end

%混相流計算用
function dm=multiphase(p,pc,x,rhog,rhol)
    alpha=(x/rhog)/((1-x)/rhol+x/rhog);
    if(x==0)
        failo=1;
    else
        kai=rhog/rhol*(1-x)/x;
        if(kai<=1)
            K=(rhol/rhog)^(1/4);
        else
            K=(1+x*(rhol/rhog-1))^(1/2);
        end
        
        C=1/K*(rhol/rhog)^(1/2)+K*(rhog/rhol)^(1/2);
        failo=(1+C/kai+1/kai^2)*(1-x)^2;
    end
    
    if(p-pc>0)
        dm=(rhol+alpha*(rhog-rhol))*(2/failo*(p-pc)/rhol)^(1/2);
    else
        dm=-(rhol+alpha*(rhog-rhol))*(2/failo*(pc-p)/rhol)^(1/2);
    end
end

%開口比計算(ノズル出口圧力計算用)
function ratio = nozzle(pc,g,pe)
ratio=((2/(g+1))^(1/(g-1)))*((pc/pe)^(1/g))  /  sqrt(((g+1)/(g-1))*(1-(pe/pc)^((g-1)/g)));
end

%線形補間を用いて燃焼室圧、O/F比にあったCEAデータを取り出す
function y=interpolate(pc,of,data)
% 計算誤差による微小な虚数成分や不整合を排除するため実数に変換する
pc = real(pc);
of = real(of);
%CEAの燃焼室圧のサンプリングレート
sample.pc=[0.004,0.01,0.2,0.4,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.0,2.2,2.4,2.6,2.8,3.0].*(10^6);
%CEAのO/F比のサンプリングレート
sample.of=[0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,8.5,9,9.5,10,100];

if(of>=100)         %O/F比が100を超える場合
    of = 100;
end
sample.data=zeros(1,length(sample.pc));
for i=1:length(sample.pc)
    sample.data(i)=interp1(sample.of,data(:,i),of,'makima');
end
y=interp1(sample.pc,sample.data,pc,'makima');
end
