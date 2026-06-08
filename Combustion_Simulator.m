clearvars;
%CREATE自作燃焼シミュレータ
%ver4.1.0からファイル名とファイル構成再編.
%各種リスト。追加はココ
list.mode={'データ整理','データ比較(複数データ整理)'...
    ,'CEA_GUI','自作エンジン解析(4パラメータ同定)','エンジンパラメータ設計'...
    };
list.HyperTEK={'J-250'};
list.engine={'J-2i','J-3i'};
%酸化剤と燃料のリスト.
list.oxidant={'N2O'}; list.fuel={'PE','PP','ABS'};
%以下メインスクリプト
%-----------------------------------------------------------------------------------------------------%
cd('Scripts');

%モードの選択
mode = listdlg('PromptString','モードを選択',...
    'Name','Select mode','SelectionMode','Single',...
    'ListString',list.mode);
disp(strcat(list.mode(mode),'モードを実行します。'))

switch mode
    case 1 %データ整理用
        Class = Mode1_Organize_data().run();
    case 2 %データ比較用
        Class = Mode2_Compare_data().run();
    case 3 %CEA_GUI操作用
        Class = Mode3_CEA_GUI().run();
    case 4 %自作エンジン解析用
        Class = Mode4_Analyze_HomebrewEngine().run(list);
    case 5 %自作エンジン設計用
        Class = Mode5_Design_HomebrewEngine().run(list);        
end
cd('../');
disp('終了');