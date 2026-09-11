function Combustion_Simulator()
    % このファイルがあるディレクトリ（CombustionSimulatorフォルダ）を取得
    [root, ~, ~] = fileparts(mfilename('fullpath'));
    
    % gsオブジェクトの作成と初期化
    gs = GeneralSetting(root);

    % settings.jsonのパスを取得
    % gs.settingsPath(root);
    gs.jsonPath; % ここで正確なパスを渡す
    
    % UI起動
    gs.launchUI();
    
    %JSONを読み込む
    gs.load();

    if gs.cancelled
        disp('設定画面がキャンセルされたため、シミュレーションを実行しません。');
        return;
    end

    choice = questdlg('シミュレーションを実行しますか？', ...
        '実行確認', ...
        '実行する', 'キャンセル', '実行する');
    
    if ~strcmp(choice, '実行する')
        disp('シミュレーションをキャンセルしました。');
        return; % ここで処理を終了する
    end
    
    % 4. 実行 (Mode1などはパスが通っているので直接呼び出せる)
    % mode = gs.execution_mode;
    mode = str2double(string(gs.execution_mode));
    if ~isscalar(mode) || ~isfinite(mode) || ~ismember(mode, 1:5)
        error('CombustionSimulator:InvalidMode', ...
            '実行モードが不正です。設定画面からモード1～5を選択して保存してください。');
    end
    
    fprintf('モード %d を実行します。\n', mode);

    % old = pwd; % 今いるパスを保存


    % gs.ScriptsPath(root);
    cd(gs.scriptsPath) % Scriptsパスに移動
    
    tic
    switch mode
        case 1
            Mode1_Organize_data().run(gs);
            
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

    cd(root) % 元のフォルダに戻る
    
    disp('終了');
end
