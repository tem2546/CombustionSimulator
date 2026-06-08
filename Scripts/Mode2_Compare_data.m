classdef Mode2_Compare_data < BaseSystem

    properties %利用するデータ.
        datanum
    end

    %データ比較用
    %Graph関数以外はfor文を用いて、エンジンごとに繰り返しているだけ.
    methods
        %手続き関数.
        %main関数ではこれが呼び出される.
        function Class = run(Class,~)
            %データの取り込み
            disp('データの取り込みを開始します。')
            Class = Class.Input();
            disp('データの取り込みが完了しました。')
            %推力データのカット
            disp('推力データのカットを開始します。')
            Class = Class.History();
            disp('推力データのカットが完了しました。')
            %グラフの出力
            disp('グラフの出力を開始します。')
            Class.Graph();
            disp('グラフの出力を完了しました。')
            %結果の出力
            Class.Output();
        end
        
        %複数データ対応入力関数
        function Class = Input(Class)
            %データ数選択
            choice = questdlg( ...
                '比較するデータ数を選択して下さい', ...
                'Select the Number of Data', ...
                "2", "3", "その他", ...
                "2");  % デフォルトは2個
            if(choice == "その他")
                Class.datanum = str2double(inputdlg( ...
                    '比較するデータ数を入力して下さい', ...
                    'Select the Number of Data'));
            else
                Class.datanum = str2double(choice);
            end
            cd('../Thrustdata');
            %データの取り込み
            infile = strings(1,Class.datanum);

            for ind = 1:Class.datanum
                infile(ind) = uigetfile('*.xlsx', ...
                    'Select a thrustdata file');
            end
            cd('../Scripts');
            for ind = 1:Class.datanum
                fieldname = strcat("engine",num2str(ind));
                msg = strcat(num2str(ind),'台目推力データファイル：', ...
                    infile(ind),'読み込み開始');
                disp(msg);
                [infotemp,thrustdata] = Infile(Class,char(infile(ind)));
                VariableNames = thrustdata.Properties.VariableNames;
                atmrow = find(VariableNames == "実験機",1);
                dataname = table2array(thrustdata(:,'実験機'));
                atmcol = find(dataname == "実験日の大気圧[MPa]",1);
                atm = table2array(thrustdata(atmcol, atmrow + 1));
                Class.data.(fieldname).t = table2array(thrustdata(:,'時刻[s]'));%時刻[s]
                Class.data.(fieldname).thrust = table2array(thrustdata(:,'推力[N]'));%推力[N]
                if(isempty(rmmissing(table2array(thrustdata(:,'タンク圧[MPa]')))) == false)
                    Class.data.(fieldname).pt = (table2array(thrustdata(:,'タンク圧[MPa]')) + atm);  %タンク圧力履歴[MPa]
                end
                if(find(VariableNames=="燃焼室圧[MPa]"))
                    if(isempty(rmmissing(table2array(thrustdata(:,'燃焼室圧[MPa]')))) == false)
                        Class.data.(fieldname).pc = (table2array(thrustdata(:,'燃焼室圧[MPa]')) + atm);  %燃焼室圧力履歴[MPa]
                    end
                end
                Class.info.(fieldname) = infotemp;
                disp("読み込み終了");
            end
        end

        %複数データ対応推力履歴関数
        function Class = History(Class)
            question = strcat(['推力のスパイクと燃焼室圧力のスパイクにずれがある場合、' ...
                '修正しますか？']);
            Class.choice.modifications = questdlg(question,'Error of Spike',"Yes","No","Yes");
            %question = strcat('燃料残留時間を計算しますか？');
            Class.choice.residual_time = "No";%questdlg(question,'Calc_Residual_Time',"Yes","No","Yes");
            for ind = 1:Class.datanum
                msg = strcat(num2str(ind),'台目履歴算出開始');
                disp(msg);
                TempClass = BaseSystem;%1台ごとの履歴生成のための一時的なクラス.
                fieldname = strcat("engine",num2str(ind));
                TempClass.info = Class.info.(fieldname);
                TempClass.data = Class.data.(fieldname);
                TempClass.choice = Class.choice;
                TempClass = History(TempClass);
                Class.history.(fieldname) = TempClass.history;
                Class.output.(fieldname) = TempClass.output;
                disp("履歴算出完了");
            end
        end

        %複数データ対応グラフ描画関数
        function graph = Graph(Class)
            label = strings(1,Class.datanum);
            tankcheck = "Yes";
            chambercheck = "Yes";
            graph.pt = "No";
            graph.pc = "No";
            graph.thrust = "No";

            for ind = 1:Class.datanum
                fieldname = strcat("engine",num2str(ind));
                Class.info.(fieldname).thrustdate = num2str(Class.info.(fieldname).thrustdate);
                label(ind) = strcat(Class.info.(fieldname).engine, ...
                    '(',Class.info.(fieldname).thrustdate,')');
                if(isfield(Class.history.(fieldname),'pt') == false)
                    tankcheck = "No";
                end

                if(isfield(Class.history.(fieldname),'pc') == false)
                    chambercheck = "No";
                end
            end

            %出力グラフリスト
            graph_list = ["thrust","pt","pc"];
            yaxis_list = {'推力[N]','タンク圧力[MPa]','燃焼室圧力[MPa]'};
            title_list = {'推力履歴','タンク圧力履歴','燃焼室圧力履歴'};
            if(chambercheck == "No")
                list = {'推力','タンク圧力'};
            else
                list = {'推力','タンク圧力','燃焼室圧力'};
            end
            %自作エンジン用
            if(tankcheck == "Yes")
                indx = listdlg('PromptString','出力するグラフをすべて選択',...
                    'Name','Select mode',...
                    'SelectionMode','Multiple',...
                    'ListString',list);
            else
                answer = questdlg('推力履歴のグラフを出力しますか？','Output the Gragh?',"Yes","No","Yes");
                if(answer == "Yes")
                    indx = 1;
                end
            end

            for i = 1:length(indx)
                figure
                hold on
                for ind = 1:Class.datanum
                    fieldname = strcat("engine",num2str(ind));
                    plot(Class.history.(fieldname).t, ...
                        Class.history.(fieldname).(graph_list(indx(i))))
                end
                title(title_list(indx(i)))
                xlabel('時間[s]')
                ylabel(yaxis_list(indx(i)))
                legend(label)
                graph.(graph_list(indx(i)))="Yes";
                hold off
            end
        end

        %結果表示関数(typeだけ違う)
        function output = Output(Class)
            for ind = 1:Class.datanum
                disp(strcat(num2str(ind),"機目"))
                fieldname = strcat("engine",num2str(ind));
                TempClass = BaseSystem;
                TempClass.info = Class.info.(fieldname);
                TempClass.history = Class.history.(fieldname);
                TempClass.output = Class.output.(fieldname).origin;
                output.(fieldname).msg = Output(TempClass, TempClass.output);
            end
        end
    end
end

