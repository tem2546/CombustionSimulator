classdef GeneralSetting < handle
    properties
        jsonPath
        current_mode = 1
        modeSelect = "mode1"
        thrust
        noiseremoved = "Yes"
        spikecut = "Yes"
        csvout = "Yes"
        residual_time = "Yes"
        compareDataNumSelect = "2"
        customDataNumInput = 4
        compare_sync_spike = "Yes"
        compare_graphs
        compare_files = []
        m3_fuel_select = "PP"
        m3_oxidant_select = "N2O"
        m3_hkj = -713
        m3_c_atom = 3
        m3_o_atom = 0
        m3_h_atom = 6
        m3_n_atom = 0
        m3_tk = 298.15
        m4_engine_select = "EngineA"
        m4_thrust_file_select = ""
        m4_oxidant_select = "N2O"
        m4_fuel_select = "PP"
        m5_oxidant_select = "N2O"
        m5_fuel_select = "PP"
        m5_F_req = 250
        m5_I_req = 1500
        m5_vt = 2000
        m5_pti = 5
        m5_cstar_eff = 0.85
        m5_Cd = 0.7
        m5_do = 3.5
        m5_df = 15
        m5_Df_outer = 50
        m5_Lf_max = 0.5
        m5_Lstar = 2
        outputModeSelect = "auto"
        result_path = ""
      
    end
    
    methods
        % コンストラクタを空にする（引数エラーを物理的に消す）
        function obj = GeneralSetting()
        end
        
        % 設定用のメソッド
        function setRoot(obj, root)
            obj.jsonPath = fullfile(root, 'Settings', 'settings.json');
        end
        
        function launchUI(obj)
            root = fileparts(fileparts(obj.jsonPath));
            pyScript = fullfile(root, 'Scripts', 'GeneralSettingUI', 'app.py');
            settingsDir = fullfile(root, 'Settings');
            command = ['python "', pyScript, '" --settings-dir "', settingsDir, '"'];
            system(command);
            obj.load();
        end
        
        function load(obj)
            if exist(obj.jsonPath, 'file')
                % JSONを構造体として読み込む
                data = jsondecode(fileread(obj.jsonPath));
                
                % フィールドを一つずつではなく、構造体全体からマッチするものを適用する
                fields = fieldnames(data);
                for i = 1:numel(fields)
                    propName = fields{i};
                    if isprop(obj, propName)
                        obj.(propName) = data.(propName);
                    end
                end
                disp('settings.json を正常に読み込みました。');
            else
                error(['ファイルが見つかりません: ', obj.jsonPath]);
            end
        end
    end
end