classdef Mode1_Organize_data < BaseSystem

    %データ整理モード用.
    %Output関数の他、choiceを読み込み、保存する関数を保有.
    methods
        %手続き関数.
        %main関数ではこれが呼び出される.
        function [Class, output] = run(Class,~)
            %データの取り込み
            disp('データの取り込みを開始します。')
            Class = Class.Input();
            disp('データの取り込みが完了しました。')
            %設定の再利用
            Class = Class.Load_choice();
            %推力データのカット
            disp('推力データのカットを開始します。')
            Class = Class.History();
            disp('推力データのカットが完了しました。')
            %グラフの出力
            disp('グラフの出力を開始します。')
            Class = Class.Graph();
            disp('グラフの出力を完了しました。')
            %結果の出力
            [Class,output] = Class.Output(Class.output);
            Class = Class.csvout();
            %設定の保存
            Class.Save_choice();
        end

        %結果表示関数
        function [Class,msg] = Output(Class,Class_output)

            if(isfield(Class.choice,'noiseremoved'))
                noiseremoved = Class.choice.noiseremoved;
                spikecut = Class.choice.spikecut;
            else
                noiseremoved = questdlg('ノイズ除去を行った結果も表示しますか？', ...
                    'Remove noise?',"Yes","No","No");
                Class.choice.noiseremoved = noiseremoved;
                spikecut = questdlg('スパイクカットを行った結果も表示しますか？', ...
                    'Remove noise?',"Yes","No","No");
                Class.choice.spikecut = spikecut;
            end
            Class.choice.noiseremoved = noiseremoved;
            Class.choice.spikecut = spikecut;

            msg.origin = Output@BaseSystem(Class,Class_output.origin);

            if(isfield(Class_output,'noiseremoved'))
                disp("ノイズ除去後");
                msg.noiseremoved = Output@BaseSystem(Class,Class_output.noiseremoved);
            end

            if(isfield(Class_output,'noiseremoved'))
                disp("スパイクカット後");
                msg.spikecut = Output@BaseSystem(Class,Class_output.spikecut);
            end
        end

        %設定読み込み関数。何度も選択肢を押すのが億劫なため用意.
        function Class = Load_choice(Class)
            cd('../SaveData')
            filename = strcat(Class.info.engine,'_savedata.xml');

            if(exist(filename,"file"))
                savedata = readstruct(filename,"FileType","xml");
                % 前回の設定をUIで表示
                h = helpdlg(evalc("disp(savedata)"), "前回 設定");
                msg = "前回の設定を利用しますか?";
                answer = questdlg(msg,'Use SaveData?',"Yes","No","No");
                if(answer == "Yes")
                    Class.choice = savedata;
                end
                delete(h);
            end
            cd('../Scripts')
        end

        %設定保存関数。何度も選択肢を押すのが億劫なため用意.
        function Save_choice(Class)
            cd('../SaveData')
            filename = strcat(Class.info.engine,'_savedata.xml');
            writestruct(Class.choice,filename);
            cd('../Scripts')
        end

    end
end