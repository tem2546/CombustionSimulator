function result = Mode5_DesignDashboard(data, gs)
%Mode5_DesignDashboard  エンジンパラメータ設計モード(Mode5)の対話UI.
%
%供給系・燃料系のパラメータを編集する度に「計算する」ボタンで
%Mode5_Design_HomebrewEngine.ComputeDesignを呼び直し、結果と制約の
%充足状況を即座に表示する。かつてのMATLABコンソールinput()の連鎖を
%置き換えるもの。
%
%戻り値 result:
%   result.cancelled  - true:キャンセル/未確定で終了, false:設計を確定
%   result.parameters - 確定したparameters構造体(cancelled=falseの時のみ)

result = struct('parameters', [], 'cancelled', true);
lastReport = [];

fig = uifigure('Name', 'Mode5: エンジンパラメータ設計', 'Position', [80 60 1040 740]);
fig.CloseRequestFcn = @(~,~) onClose();

mainGrid = uigridlayout(fig, [1 2]);
mainGrid.ColumnWidth = {380, '1x'};
mainGrid.ColumnSpacing = 12;

% ================= 左側: パラメータ入力 =================
inputPanel = uipanel(mainGrid, 'Title', '設計パラメータ');
inputGrid = uigridlayout(inputPanel, [18 2]);
inputGrid.RowHeight = repmat({26}, 1, 18);
inputGrid.ColumnWidth = {'1.3x', '1x'};

row = 1;
fields = struct();

[fields.of_method, row] = addDropdown(inputGrid, row, 'O/F決定方法', ...
    {'自動', '手動'}, {'auto', 'manual'}, 'auto');
[fields.manual_of, row] = addNumeric(inputGrid, row, '手動O/F比', 5, [0.1 100]);
[fields.F_req, row] = addNumeric(inputGrid, row, '要求推力 F_req [N]', gs.m5_F_req, [0 Inf]);
[fields.I_req, row] = addNumeric(inputGrid, row, '要求トータルインパルス I_req [Ns]', gs.m5_I_req, [0 Inf]);
[fields.vt, row] = addNumeric(inputGrid, row, 'タンク容積 vt [cc]', gs.m5_vt, [0 Inf]);
[fields.pti, row] = addNumeric(inputGrid, row, '初期タンク圧 pti [MPa]', gs.m5_pti, [0 Inf]);
[fields.final_pt, row] = addNumeric(inputGrid, row, '最終タンク圧 [MPa]', max(gs.m5_pti*0.6, 0.1), [0 Inf]);
[fields.cstar_eff, row] = addNumeric(inputGrid, row, '特性排気速度効率', gs.m5_cstar_eff, [0 1]);
[fields.Cd, row] = addNumeric(inputGrid, row, 'オリフィス流量係数 Cd', gs.m5_Cd, [0 1]);
[fields.do, row] = addNumeric(inputGrid, row, 'オリフィス径 do [mm]', gs.m5_do, [0 Inf]);
[fields.df, row] = addNumeric(inputGrid, row, '初期ポート径 df [mm]', gs.m5_df, [0 Inf]);
[fields.Df_outer, row] = addNumeric(inputGrid, row, '燃料外径 Df [mm]', gs.m5_Df_outer, [0 Inf]);
[fields.Lf_max, row] = addNumeric(inputGrid, row, '最大燃料長さ Lf_max [m]', gs.m5_Lf_max, [0 Inf]);
[fields.Lstar, row] = addNumeric(inputGrid, row, '必要特性長 L* [m]', gs.m5_Lstar, [0 Inf]);

calcBtn = uibutton(inputGrid, 'Text', '計算する', 'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(~,~) onCalculate());
calcBtn.Layout.Row = row; calcBtn.Layout.Column = [1 2];
row = row + 1;

exportChk = uicheckbox(inputGrid, 'Text', 'グレイン履歴をCSV出力する', 'Value', true);
exportChk.Layout.Row = row; exportChk.Layout.Column = [1 2];
row = row + 1;

finishBtn = uibutton(inputGrid, 'Text', '設計を確定して終了', 'Enable', 'off', ...
    'ButtonPushedFcn', @(~,~) onFinish());
finishBtn.Layout.Row = row; finishBtn.Layout.Column = [1 2];
row = row + 1;

cancelBtn = uibutton(inputGrid, 'Text', 'キャンセル', ...
    'ButtonPushedFcn', @(~,~) onClose());
cancelBtn.Layout.Row = row; cancelBtn.Layout.Column = [1 2];

% ================= 右側: 計算結果 =================
resultArea = uitextarea(mainGrid, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 13);
resultArea.Value = {'左側のパラメータを確認し、「計算する」を押してください。'};

% 起動時に初期値で1回計算しておく
onCalculate();

uiwait(fig);

    function [fld, nextRow] = addLabel(parentGrid, r, text)
        lbl = uilabel(parentGrid, 'Text', text);
        lbl.Layout.Row = r; lbl.Layout.Column = 1;
        fld = lbl;
        nextRow = r;
    end

    function [fld, nextRow] = addNumeric(parentGrid, r, labelText, initVal, limits)
        addLabel(parentGrid, r, labelText);
        fld = uieditfield(parentGrid, 'numeric', 'Value', initVal, 'Limits', limits);
        fld.Layout.Row = r; fld.Layout.Column = 2;
        nextRow = r + 1;
    end

    function [fld, nextRow] = addDropdown(parentGrid, r, labelText, items, itemsData, defaultData)
        addLabel(parentGrid, r, labelText);
        fld = uidropdown(parentGrid, 'Items', items, 'ItemsData', itemsData, 'Value', defaultData);
        fld.Layout.Row = r; fld.Layout.Column = 2;
        nextRow = r + 1;
    end

    function p = collectParams()
        p.of_method = fields.of_method.Value;
        p.manual_of = fields.manual_of.Value;
        p.F_req = fields.F_req.Value;
        p.I_req = fields.I_req.Value;
        p.vt = fields.vt.Value;
        p.pti = fields.pti.Value;
        p.final_pt = fields.final_pt.Value;
        p.cstar_eff = fields.cstar_eff.Value;
        p.Cd = fields.Cd.Value;
        p.do = fields.do.Value;
        p.df = fields.df.Value;
        p.Df_outer = fields.Df_outer.Value;
        p.Lf_max = fields.Lf_max.Value;
        p.Lstar = fields.Lstar.Value;
    end

    function onCalculate()
        calcBtn.Enable = 'off';
        drawnow;
        try
            p = collectParams();
            report = Mode5_Design_HomebrewEngine.ComputeDesign(data, p);
            lastReport = report;
            resultArea.Value = formatReport(report);
            if report.ok
                finishBtn.Enable = 'on';
            else
                finishBtn.Enable = 'off';
            end
        catch ME
            lastReport = [];
            finishBtn.Enable = 'off';
            resultArea.Value = {'計算中にエラーが発生しました:', ME.message};
        end
        calcBtn.Enable = 'on';
    end

    function onFinish()
        if isempty(lastReport) || ~lastReport.ok
            return
        end
        if exportChk.Value
            root = fileparts(fileparts(mfilename('fullpath')));
            outputDir = fullfile(root, 'Output');
            Mode5_Design_HomebrewEngine.ExportGrainHistory( ...
                lastReport.dfs, lastReport.time_step, ...
                lastReport.fuel.a, lastReport.fuel.n, lastReport.fuel.ave.mdot_ox, outputDir);
        end
        result.parameters = lastReport.parameters;
        result.cancelled = false;
        uiresume(fig);
        delete(fig);
    end

    function onClose()
        uiresume(fig);
        delete(fig);
    end

end

function lines = formatReport(report)
lines = {};

lines{end+1} = sprintf('初期O/F比: %.3f', report.of);
lines{end+1} = '';

lines{end+1} = '=== 供給系 ===';
if report.supplyStatus.ok
    s = report.supply;
    lines{end+1} = sprintf('初期燃焼室圧力: %.3f MPa', s.pc*10^(-6));
    lines{end+1} = sprintf('初期推力: %.1f N', s.F);
    lines{end+1} = sprintf('特性排気速度: %.1f m/s   比熱比: %.3f', s.cstar, s.gamma);
    lines{end+1} = sprintf('推力係数: %.4f', s.Cf);
    lines{end+1} = sprintf('酸化剤流量: %.4f kg/s   推進剤流量: %.4f kg/s', s.mdot_ox, s.mdot_p);
    lines{end+1} = sprintf('ノズルスロート径: %.2f mm   ノズル出口径: %.2f mm   開口比: %.3f', ...
        s.dthroat*10^3, s.de*10^3, s.Epsilon);
else
    lines{end+1} = ['⚠ ' report.supplyStatus.message];
end

if isfield(report, 'fuelStatus')
    lines{end+1} = '';
    lines{end+1} = '=== 燃料系 ===';
    if report.fuelStatus.ok
        f = report.fuel;
        lines{end+1} = sprintf('燃焼予定時間: %.2f s', f.planed_burning_time);
        lines{end+1} = sprintf('燃料長さ: %.3f m (必要最小: %.3f m)', f.Lf, f.Lf_min);
        lines{end+1} = sprintf('スライバ率: %.1f %%', f.phi);
        lines{end+1} = sprintf('最終タンク圧: %.3f MPa   最終燃焼室圧: %.3f MPa', ...
            f.final.pt*10^(-6), f.final.pc*10^(-6));
    else
        lines{end+1} = ['⚠ ' report.fuelStatus.message];
    end
end

if isfield(report, 'final') && report.ok
    lines{end+1} = '';
    lines{end+1} = '=== 最終性能 ===';
    lines{end+1} = sprintf('最終推力: %.1f N', report.final.F);
    lines{end+1} = sprintf('平均推力: %.1f N', report.ave_F);
    lines{end+1} = sprintf('トータルインパルス: %.1f Ns (目標 %.1f Ns)', report.I, report.I_req);
    if report.achieved
        lines{end+1} = '✅ 要求トータルインパルスを達成しました。「設計を確定して終了」で確定できます。';
    end
end

if ~isempty(report.warnings)
    lines{end+1} = '';
    lines{end+1} = '=== 警告 ===';
    for i = 1:numel(report.warnings)
        lines{end+1} = ['⚠ ' report.warnings{i}]; %#ok<AGROW>
    end
end
end
