function Combustion_Simulator()
    % このファイルがあるディレクトリ（CombustionSimulatorフォルダ）を取得
    [root, ~, ~] = fileparts(mfilename('fullpath'));
    
    jsonPath = fullfile(root, 'Settings', 'settings.json');
    
    % gsオブジェクトの作成と初期化
    gs = GeneralSetting();
    gs.setRoot(root);
    gs.jsonPath = jsonPath; % ここで正確なパスを渡す
    
    % UI起動
    gs.launchUI();
    
    %JSONを読み込む
    gs.load();

    
    
    % 4. 実行 (Mode1などはパスが通っているので直接呼び出せる)
    mode = gs.current_mode;
    
    fprintf('モード %d を実行します。\n', mode);
    
    tic
    switch mode
        case 1
            obj = Mode1_Organize_data();
            obj.run(gs);
        case 2
            Mode2_Compare_data().run(gs);
        case 3
            Mode3_CEA_GUI().run(gs);
        case 4
            Mode4_Analyze_HomebrewEngine().run(gs);
        case 5
            Mode5_Design_HomebrewEngine().run(gs);
    end
    toc
    
    disp('終了');
end