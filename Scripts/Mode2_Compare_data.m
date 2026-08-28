classdef Mode2_Compare_data < BaseSystem
    properties
        datanum
    end
    
    methods
        % 手続き関数
        function Class = run(Class, gs)
            disp('データの取り込みを開始します。')
            Class = Class.Input(gs);
            disp('データの取り込みが完了しました。')
            
            disp('推力データのカットを開始します。')
            Class = Class.History(gs);
            disp('推力データのカットが完了しました。')
            
            disp('グラフの出力を開始します。')
            Class.Graph(gs);
            disp('グラフの出力を完了しました。')
            
            Class.Output(gs);
        end
        
        % 複数データ対応入力関数
        function Class = Input(Class, gs)
            % 1. 比較データ数の取得
            if gs.compareDataNumSelect == "その他"
                Class.datanum = gs.customDataNumInput;
            else
                Class.datanum = str2double(gs.compareDataNumSelect);
            end
            
            root = fileparts(fileparts(gs.jsonPath));
            thrustDir = fullfile(root, 'Thrustdata');
            
            infile = strings(1, Class.datanum);
            
            % 2. GeneralSettingの compare_files からファイル名を取得
            for ind = 1:Class.datanum
                if length(gs.compare_files) >= ind && ~isempty(gs.compare_files(ind))
                    fileName = string(gs.compare_files(ind).fn);
                else
                    error('settings.json の compare_files に必要なファイル数が設定されていません。');
                end
                infile(ind) = fullfile(thrustDir, fileName);
            end
            
            for ind = 1:Class.datanum
                fieldname = strcat("engine", num2str(ind));
                [~, name, ext] = fileparts(infile(ind));
                msg = strcat(num2str(ind), '台目推力データファイル：', name, ext, ' 読み込み開始');
                disp(msg);
                
                [infotemp, thrustdata] = Infile(Class, infile(ind), strcat(name, ext));
                
                VariableNames = thrustdata.Properties.VariableNames;
                atmrow = find(VariableNames == "実験機", 1);
                dataname = table2array(thrustdata(:, '実験機'));
                atmcol = find(dataname == "実験日の大気圧[MPa]", 1);
                atm = table2array(thrustdata(atmcol, atmrow + 1));
                
                Class.data.(fieldname).t = table2array(thrustdata(:, '時刻[s]'));
                Class.data.(fieldname).thrust = table2array(thrustdata(:, '推力[N]'));
                
                if(isempty(rmmissing(table2array(thrustdata(:, 'タンク圧[MPa]')))) == false)
                    Class.data.(fieldname).pt = (table2array(thrustdata(:, 'タンク圧[MPa]')) + atm);
                end
                if(find(VariableNames == "燃焼室圧[MPa]"))
                    if(isempty(rmmissing(table2array(thrustdata(:, '燃焼室圧[MPa]')))) == false)
                        Class.data.(fieldname).pc = (table2array(thrustdata(:, '燃焼室圧[MPa]')) + atm);
                    end
                end
                Class.info.(fieldname) = infotemp;
                disp("読み込み終了");
            end
        end
        
        % 複数データ対応推力履歴関数
        function Class = History(Class, gs)
            % GeneralSetting の compare_sync_spike の設定を反映
            Class.choice.modifications = gs.compare_sync_spike;
            Class.choice.residual_time = "No";
            
            for ind = 1:Class.datanum
                msg = strcat(num2str(ind), '台目履歴算出開始');
                disp(msg);
                TempClass = BaseSystem;
                fieldname = strcat("engine", num2str(ind));
                TempClass.info = Class.info.(fieldname);
                TempClass.data = Class.data.(fieldname);
                TempClass.choice = Class.choice;
                TempClass = History(TempClass, gs);
                Class.history.(fieldname) = TempClass.history;
                Class.output.(fieldname) = TempClass.output;
                disp("履歴算出完了");
            end
        end
        
        % 複数データ対応グラフ描画関数
        function graph = Graph(Class, gs)
            label = strings(1, Class.datanum);
            tankcheck = "Yes";
            chambercheck = "Yes";
            graph.pt = "No";
            graph.pc = "No";
            graph.thrust = "No";
            

            for ind = 1:Class.datanum
                fieldname = strcat("engine", num2str(ind));
                Class.info.(fieldname).thrustdate = num2str(Class.info.(fieldname).thrustdate);
                label(ind) = strcat(Class.info.(fieldname).engine, ...
                    '(', Class.info.(fieldname).thrustdate, ')');
                if(isfield(Class.history.(fieldname), 'pt') == false)
                    tankcheck = "No";
                end
                if(isfield(Class.history.(fieldname), 'pc') == false)
                    chambercheck = "No";
                end
            end
            
            graph_list = ["thrust", "pt", "pc"];
            yaxis_list = {'推力[N]', 'タンク圧力[MPa]', '燃焼室圧力[MPa]'};
            title_list = {'推力履歴', 'タンク圧力履歴', '燃焼室圧力履歴'};
            
            % % GeneralSetting の compare_graphs プロパティを使用する
            % indx = [];
            % if isprop(gs, 'compare_graphs') && isstruct(gs.compare_graphs)
            %     if isfield(gs.compare_graphs, 'thrust') && gs.compare_graphs.thrust
            %         indx(end+1) = 1; % "thrust"
            %     end
            %     % 必要に応じて他のグラフの判定もここに追加できます
            % end
            % 
            % if isempty(indx)
            %     indx = 1; % デフォルトで thrust を描画
            % end

            indx = 1:3;
            
            for i = 1:length(indx)
                % figure
                % hold on
                % for ind = 1:Class.datanum
                %     fieldname = strcat("engine", num2str(ind));
                %     plot(Class.history.(fieldname).t, ...
                %         Class.history.(fieldname).(graph_list(indx(i))))
                % end
                % title(title_list(indx(i)))
                % xlabel('時間[s]')
                % ylabel(yaxis_list(indx(i)))
                % legend(label)
                % graph.(graph_list(indx(i))) = "Yes";
                % hold off

                target_field = graph_list(indx(i));
                canPlot = true;
                for ind = 1:Class.datanum
                    fieldname = strcat("engine", num2str(ind));
                    if ~isfield(Class.history.(fieldname), target_field)
                        canPlot = false;
                        break;
                    end
                end
                
                % 存在する場合のみグラフを描画する
                if canPlot
                    figure
                    hold on
                    for ind = 1:Class.datanum
                        fieldname = strcat("engine", num2str(ind));
                        plot(Class.history.(fieldname).t, ...
                            Class.history.(fieldname).(target_field))
                    end
                    title(title_list(indx(i)))
                    xlabel('時間[s]')
                    ylabel(yaxis_list(indx(i)))
                    legend(label)
                    graph.(target_field) = "Yes";
                    hold off
                else
                    disp([title_list{indx(i)} ' のデータが存在しないため、グラフの描画をスキップします。']);
                end
            end
        end
        
        % 結果表示関数
        function output = Output(Class, ~)
            for ind = 1:Class.datanum
                disp(strcat(num2str(ind), "機目"))
                fieldname = strcat("engine", num2str(ind));
                TempClass = BaseSystem;
                TempClass.info = Class.info.(fieldname);
                TempClass.history = Class.history.(fieldname);
                TempClass.output = Class.output.(fieldname).origin;
                output.(fieldname).msg = Output(TempClass, TempClass.output);
            end
        end
    end
end