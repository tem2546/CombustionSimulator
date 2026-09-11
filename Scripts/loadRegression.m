function reg = loadRegression(root, oxidizer, fuel, port)
%LOADREGRESSION Load one fuel regression-rate coefficient set.
%   The coefficient file uses SI units: regression rate in m/s and
%   oxidizer mass flux in kg/(m^2 s). Port defaults to circle for settings
%   files created before regression model selection was added.

if nargin < 4 || strlength(strtrim(string(port))) == 0
    port = "circle";
end

file = fullfile(root, 'Data', 'regression.csv');
if ~isfile(file)
    error('Regression:FileNotFound', ...
        '燃料後退速度係数ファイルが見つかりません: %s', file);
end

params = readtable(file, 'TextType', 'string');
required = ["id", "oxidizer", "fuel", "port", "a_SI", "n"];
missing = setdiff(required, string(params.Properties.VariableNames));
if ~isempty(missing)
    error('Regression:InvalidFile', ...
        '燃料後退速度係数ファイルに必要な列がありません: %s', ...
        strjoin(missing, ', '));
end

if ~isnumeric(params.a_SI) || ~isnumeric(params.n)
    error('Regression:InvalidFile', 'a_SIとnは数値で指定してください。');
end

ids = strtrim(string(params.id));
oxidizers = upper(strtrim(string(params.oxidizer)));
fuels = upper(strtrim(string(params.fuel)));
ports = lower(strtrim(string(params.port)));

if any(ismissing(ids) | strlength(ids) == 0)
    error('Regression:InvalidFile', '空のidは使用できません。');
end
if numel(unique(lower(ids))) ~= numel(ids)
    error('Regression:DuplicateId', '重複したidがあります。');
end

if any(ismissing(ports) | strlength(ports) == 0)
    error('Regression:InvalidFile', '空のportは使用できません。');
end

keys = oxidizers + "/" + fuels + "/" + ports;
if numel(unique(keys)) ~= numel(keys)
    error('Regression:DuplicateSet', ...
        '酸化剤、燃料、ポートモデルの組み合わせが重複しています。');
end

if any(~isfinite(params.a_SI) | params.a_SI <= 0) || ...
        any(~isfinite(params.n) | params.n <= 0)
    error('Regression:InvalidValue', 'a_SIとnは有限の正数にしてください。');
end

target = upper(strtrim(string(oxidizer))) + "/" + ...
    upper(strtrim(string(fuel))) + "/" + ...
    lower(strtrim(string(port)));
match = keys == target;
if ~any(match)
    available = strjoin(keys, ', ');
    error('Regression:NotFound', ...
        ['%sの燃料後退速度係数が登録されていません。' ...
        ' Data/regression.csvを確認してください。登録済み: %s'], ...
        target, available);
end

row = find(match, 1);
reg.id = ids(row);
reg.a = params.a_SI(row);
reg.n = params.n(row);
reg.oxidizer = oxidizers(row);
reg.fuel = fuels(row);
reg.port = ports(row);
end
