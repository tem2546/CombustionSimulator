classdef BaseSystem
    %全てのデータを扱うときの共通部分関数をまとめたもの.
    %全ての関数の親クラス.こいつから直接派生させることは稀.
    %こいつによってサブタイピング多相を実装。(サブタイピング多相はポリモーフィズムの仕組みの一つ).

    properties %利用するデータ.
        info
        %選んだエンジンの情報を格納する.
        %名前、実験の日付、種別(自作なのかHyperTEKなのか)など.
        choice %シミュレータの選択肢を格納する.
        data %取り込んだデータ.
        history %燃焼データの推力、タンク圧、燃焼室圧といった履歴を格納する.
        output %推力や燃焼開始時間といった計算結果を格納する.
    end
    properties(Constant)
        condition_percent = 5;    %推力が出ているとみなす領域.
    end

    methods
        %データ読み込み関数(内部でInfile関数を呼び出す).
        function Class = Input(Class)
            %推力データファイルを選択
            cd('../Thrustdata');
            infile = uigetfile('*.xlsx','Select a thrustdata file');
            cd('../Scripts');
            [Class.info,thrustdata] = Infile(Class,infile);
            ColNames = thrustdata.Properties.VariableNames;%列の名前
            Otherdataind = table2array(thrustdata(:,'実験機'));%実験機データの位置を探索
            atmrow = find(ColNames == "実験機",1);
            atmind = find(Otherdataind == "実験日の大気圧[MPa]",1);%大気圧がある行の探索
            atm = table2array(thrustdata(atmind, atmrow + 1));%大気圧
            Class.data.t = table2array(thrustdata(:,'時刻[s]'));%時刻[s]
            Class.data.thrust = table2array(thrustdata(:,'推力[N]'));%推力[N]
            %タンク圧があるならば、タンク圧のデータを格納する.
            if(isempty(rmmissing(table2array(thrustdata(:,'タンク圧[MPa]')))) == false)
                Class.data.pt = (table2array(thrustdata(:,'タンク圧[MPa]')) + atm);  %タンク圧力履歴[MPa]
            end
            %燃焼室圧があるならば、燃焼室圧のデータを格納する.
            if(find(ColNames == "燃焼室圧[MPa]"))
                if(isempty(rmmissing(table2array(thrustdata(:,'燃焼室圧[MPa]')))) == false)%燃焼室圧があるならば、タンク圧のデータを格納する.
                    Class.data.pc = (table2array(thrustdata(:,'燃焼室圧[MPa]')) + atm);%燃焼室圧力履歴[MPa]
                end
            end
        end

        %ファイル読み込み関数.
        function [info,thrustdata] = Infile(~,infile)
            filename = erase(infile,".xlsx");
            info.thrustdate = cell2mat(extract(filename,digitsPattern + textBoundary));
            info.engine = extractBefore(filename,"_thrustdata");
            info.type = extractBefore(filename,"_");
            msg = strcat('読み込む推力データファイル：',filename);
            disp(msg);
            msg = strcat('読み込むエンジンタイプ：',info.type);
            disp(msg);
            %推力データファイルの読み込み
            cd('../Thrustdata');
            thrustdata = readtable(infile,"VariableNamingRule","preserve", ...
                'DataRange','A2','VariableNamesRange',"1:1");
            cd('../Scripts');
        end

        %履歴等の重要情報を算出・記録する関数.
        %(内部でThrust_History,Tank_Chamber_History関数を呼び出す).
        function Class = History(Class)
            %必要なデータを変数へ格納
            t = Class.data.t;             %時間データ
            thrust = Class.data.thrust;   %推力データ
            %推力データから修正なしの生データによる結果を算出.
            Class.output.origin = Thrust_History(Class,t,thrust);
            %推力データから得た結果から必要なものを格納.
            initial_i = Class.output.origin.initial_i;   %燃焼開始時のindex
            spike_i = Class.output.origin.spike_i;       %スパイク終了時のindex
            end_i = Class.output.origin.end_i;           %燃焼終了時のindex

            %圧力履歴の格納. 可能な場合はスパイクのずれを修正.
            Class = Tank_Chamber_History(Class);
            %推力データのノイズを除去.
            removed_thrust = (medfilt1(thrust,3) + ...
                medfilt1(thrust,8))/2;%ノイズ除去(平滑化)した推力データ

            %カットした時間データ
            Class.history.t = t(initial_i:end_i) - t(initial_i);
            %カットした推力データ
            Class.history.thrust = thrust(initial_i:end_i);
            %スパイクカットした時間データ
            Class.history.spikecut_t = t(spike_i:end_i) - t(spike_i);
            %スパイクカットした推力データ
            Class.history.spikecut_thrust = thrust(spike_i:end_i);
            %スパイクカット推力から得られたデータ
            Class.output.spikecut = Thrust_History(Class,Class.history.spikecut_t,Class.history.spikecut_thrust);
            %カットしたノイズ除去後推力データ
            Class.history.removed_thrust = removed_thrust(initial_i:end_i);
            %ノイズ除去後推力から得られたデータ
            Class.output.noiseremoved = Thrust_History(Class,t,removed_thrust);
            
            %燃料残留時間を算出.
            if(isfield(Class.choice,'residual_time'))
                residual_time = Class.choice.residual_time;
            else
                question = strcat('燃料残留時間を計算しますか？');
                residual_time = questdlg(question,'Calc_Residual_Time',"Yes","No","Yes");
            end
            Class.choice.residual_time = residual_time;
            if(residual_time == "Yes")
                Class.output.origin.ResidualTime = Estimate_Residual_Time(Class);
                
            end
        end

        %推力履歴による情報を格納する関数.
        %返り値がOutPutなことに注意.
        function output = Thrust_History(Class,t,thrust)
            %推力最大値の探索.
            [max_thrust,max_i] = max(thrust);
            msg = strcat('最大推力：',num2str(max_thrust),'[N]');
            disp(msg)

            %推力最小値の決定.
            min_thrust = max_thrust * Class.condition_percent / 100;
            msg = strcat('最大推力の',num2str(Class.condition_percent),...
                '%(',num2str(min_thrust), ...
                '[N])以上を推力が出ているとみなして計算します。');
            disp(msg)

            %燃焼開始時刻の添字(index)を探索.
            initial_i = find(thrust >= min_thrust,1,'first');
            %燃焼終了時刻の添字(index)を探索.
            end_i = find(thrust >= min_thrust,1,'last');
            %スパイク終了時刻の添字(index)を計算.
            %スパイクは燃焼開始から推力最大値になるまでかかった時間の2倍になると仮定.
            %この仮定には根拠ないため、考察・修正の余地あり.
            %ver3.0.7以前は別の方法で算出している.
            spike_i = initial_i + 2 * (max_i - initial_i);
            %end_iより大きくなったとき用.
            spike_i = min(spike_i,end_i);

            %燃焼開始時刻.
            t_initial = t(initial_i);
            %燃焼終了時刻.
            t_end = t(end_i);
            %燃焼時間.
            burning_time = t_end - t_initial;
            %トータルインパルス（実測）
            % 早い話が積分
            % 積分をする関数自体は存在するが、
            % 時間データに細かいズレが起きているため、関数の利用が難しかった。
            % そのため丁寧に計算している。行列計算に書き換えてもよい.
            I = 0;
            for i = initial_i:end_i - 1
                I = I + (thrust(i + 1) + thrust(i)) * (t(i + 1) - t(i)) / 2;
            end
            output.max_thrust = max_thrust;             %最大推力
            output.max_i = max_i;                       %最大推力のindex
            output.max_t = t(max_i) - t_initial;        %最大推力の燃焼開始からの時間
            output.initial_i = initial_i;               %燃焼開始時のindex
            output.spike_i = spike_i;                   %スパイク終了時のindex
            output.end_i = end_i;                       %燃焼終了時のindex
            output.burning_time = burning_time;         %燃焼時間
            output.total_impulse = I;                   %トータルインパルス
            output.average_thrust = I / burning_time;   %平均推力
        end

        %タンク圧・燃焼室圧履歴による情報を格納する関数.
        function Class = Tank_Chamber_History(Class)
            %必要な情報の読み込み
            %最大推力のindex
            max_i = Class.output.origin.max_i;
            %燃焼開始時のindex
            initial_i = Class.output.origin.initial_i;
            %燃焼終了時のindex
            end_i = Class.output.origin.end_i;

            %タンク・燃焼室両方ある時、スパイクのずれを確認調整する.
            if(isfield(Class.data,'pc') && isfield(Class.data,'pt'))
                %燃焼室圧最大値
                [max_pc,max_ipc] = max(Class.data.pc);

                %スパイクのずれ算出
                error_i = max_ipc - max_i;
                error_spike = Class.data.t(max_ipc) - Class.data.t(max_i);

                if(error_i == 0)
                    modifications = "No";
                elseif(isfield(Class.choice,'modifications'))
                    modifications = Class.choice.modifications;
                else
                    question = strcat('推力のスパイクに対し燃焼室圧力のスパイクに', ...
                        num2str(error_spike),'[s]のずれがあります。修正しますか？');
                    modifications = questdlg(question,'Error of Spike',"Yes","No","Yes");
                end

                %ずれ修正
                if(modifications == "Yes")
                    %圧力データ抽出位置の調整
                    initial_i = initial_i + error_i;
                    %スパイクのずれが正な場合の対策.
                    %基本的には起こりづらい.
                    end_i = min(length(Class.data.pt) , end_i + error_i);
                end
                Class.history.pt = Class.data.pt(initial_i:end_i);%タンク圧力のデータ
                Class.history.pc = Class.data.pc(initial_i:end_i);%燃焼室圧力のデータ
                Class.choice.modifications = modifications;%誤差修正の有無
                Class.output.error_spike = error_spike;%スパイクの誤差時間
                Class.output.origin.max_pc = max_pc;%最大燃焼室圧力
            else
                %タンク圧・燃焼室圧のどちらかが無いとき.
                if(isfield(Class.data,'pt'))%タンク圧力履歴
                    Class.history.pt = Class.data.pt(initial_i:end_i);%タンク圧力のデータ
                else
                    disp("タンクの圧力履歴が存在しません。");
                end

                if(isfield(Class.data,'pc'))%燃焼室圧力履歴
                    Class.history.pc = Class.data.pc(initial_i:end_i);%燃焼室圧力のデータ
                else
                    disp("燃焼室の圧力履歴が存在しません。");
                end
            end
        end

        %燃料残留時間を推定する関数、精度は低め.
        %目視と大きく変わらない程度であるため採用.
        %ver4.0.1以前にあった燃料残留時間モードで詳細なデバッグ可能.
        function Residual_Time = Estimate_Residual_Time(Class)
            [~,max_i] = max(Class.history.thrust);
            
            if(2 * max_i < length(Class.history.t))
                %スパイク前後のデータは除外する。
                t = Class.history.t(2 * max_i:end);
                thrust = Class.history.thrust(2 * max_i:end);
            else
                t = Class.history.t;
                thrust = Class.history.thrust;                
            end

            %平滑化した推力の急激な変化点を探索
            %(これだけでも大雑把な残量時間は測れるが、精度はとても悪い。)
            TSInd = ischange(smoothdata(thrust),'mean','MaxNumChanges',1);
            TS = find(TSInd == 1);
            %近似直線用の配列作成
            StraightX = t(1:TS);
            StraightY = thrust(1:TS);

            %近似直線の生成
            StraightP = polyfit(StraightX,StraightY,1);

            %平滑化した推力の急激な変化点を範囲を狭めて再度探索
            TSInd = ischange(smoothdata(thrust(TS:end)),'mean','MaxNumChanges',1);
            end_i = TS + find(TSInd == 1);
            %近似曲線用の配列作成
            CurveX = t(TS:end_i);
            CurveY = thrust(TS:end_i);

            %近似曲線の生成。10次以上は過学習が起きるが、
            % 次数が適切でないとちゃんと算出できない。
            % 現在の次数2は恣意的に決めたものであり、
            % 合わないのならばより良い修正法を考案する必要がある。
            CurveP = polyfit(CurveX,CurveY,2);

            %近似曲線の微分
            DifCurveP = polyder(CurveP);
            DifCurve = polyval(DifCurveP,CurveX);
            %近似の曲線の傾きの最小値
            [LineA,Index] = min(DifCurve);

            %液体残量時間決定のための直線を計算
            LineY = polyval(CurveP,CurveX(Index));
            LineB = LineY - LineA*CurveX(Index);

            %液体残量時間を計算(近似直線と直前で求めた直線の交点)
            Residual_Time = (LineB - StraightP(2))/(StraightP(1) - LineA);
            disp(strcat("液体残量時間:",num2str(Residual_Time),"[s]"));
        end

        %グラフ表示関数.
        function Class = Graph(Class)
            %作成可能なグラフリストの製作.
            graphlist = ["推力" ,"ノイズ除去後推力","スパイクカット後推力"];
            timelist = ["t","t","spikecut_t"];
            outputlist = ["thrust","removed_thrust","spikecut_thrust"];
            yaxislist = ["推力[N]","推力[N]","推力[N]"];
            titlelist = ["推力履歴","ノイズ除去後推力履歴","スパイクカット後推力履歴"];

            if(isfield(Class.history,'pt'))%タンク圧がある場合.
                graphlist = [graphlist,"タンク圧力"];
                timelist = [timelist,"t"];
                outputlist = [outputlist,"pt"];
                yaxislist = [yaxislist,"タンク圧力[MPa]"];
                titlelist = [titlelist,"タンク圧力履歴"];
            end

            if(isfield(Class.history,'pc'))%燃焼室圧がある場合.
                graphlist = [graphlist,"燃焼室圧力"];
                timelist = [timelist,"t"];
                outputlist = [outputlist,"pc"];
                yaxislist = [yaxislist,"燃焼室圧力[MPa]"];
                titlelist = [titlelist,"燃焼室圧力履歴"];
            end

            %描画するグラフの選択.
            if(length(graphlist) > 1)
                if(isfield(Class.choice,'indx'))%選択肢が記録されている場合.
                    indx = Class.choice.indx;
                else
                    indx = listdlg('PromptString','出力するグラフをすべて選択',...
                        'Name','Select mode',...
                        'SelectionMode','Multiple',...
                        'ListString',graphlist);
                    Class.choice.indx = indx;
                end
            end

            if(indx > 0)
                for i=1:length(indx)
                    figure
                    plot(Class.history.(timelist(indx(i))),Class.history.(outputlist(indx(i))))
                    title(titlelist(indx(i)))
                    if(isfield(Class.output.origin,'ResidualTime')&&indx(i) == 1)
                        xline(Class.output.origin.ResidualTime);
                        xticks(Class.output.origin.ResidualTime);
                    end
                    xlabel('時間[s]')
                    ylabel(yaxislist(indx(i)))
                end
            end
        end

        %結果表示関数.
        function [Class,msg] = Output(Class,Class_output)

            disp('************************計算結果************************')
            msg.engine = strcat('使用したエンジン：',Class.info.engine);
            disp(msg.engine)
            msg.date = strcat('実験日：',num2str(Class.info.thrustdate));
            disp(msg.date)
            msg.max_thrust = strcat('最大推力：',num2str(Class_output.max_thrust),'[N]');
            disp(msg.max_thrust)
            msg.average_thrust = strcat('平均推力：',num2str(Class_output.average_thrust),'[N]');
            disp(msg.average_thrust)
            msg.burning_time = strcat('燃焼時間：',num2str(Class_output.burning_time),'[s]');
            disp(msg.burning_time)
            msg.total_impulse = strcat('トータルインパルス：',num2str(Class_output.total_impulse),'[Ns]');
            disp(msg.total_impulse)
            disp('********************************************************')
            Class_output.msg = msg;
            Class_output.type = Class.info.type;
        end

        %CSVファイル出力関数.
        function Class = csvout(Class)
            cd('../Output')
            Class.choice.csvout = questdlg('推力履歴をcsv出力しますか？', ...
                'Output the csv File?',"Yes","No","Yes");
            if(Class.choice.csvout == "Yes")
                varNames = {'time[s]','thrust[N]','removed_thrust[N]'};
                time = Class.history.t;
                thrust = Class.history.thrust;
                removed_thrust = Class.history.removed_thrust;

                filedata = table(time,thrust,removed_thrust,'VariableNames',varNames);

                Class.info.filename = strcat(Class.info.engine,'_thrustdata_', ...
                    num2str(Class.info.thrustdate),'.csv');

                writetable(filedata,Class.info.filename)
            end
            cd('../Scripts')
        end
    end
end
