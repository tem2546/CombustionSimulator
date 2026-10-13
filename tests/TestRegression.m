function tests = TestRegression
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.root = root;
addpath(fullfile(root, 'Scripts'));
end

function teardownOnce(testCase)
rmpath(fullfile(testCase.TestData.root, 'Scripts'));
end

function testLoadsN2oPeCoefficients(testCase)
reg = loadRegression(testCase.TestData.root, 'N2O', 'PE');

verifyEqual(testCase, reg.id, "n2o_pe");
verifyEqual(testCase, reg.oxidizer, "N2O");
verifyEqual(testCase, reg.fuel, "PE");
verifyEqual(testCase, reg.port, "circle");
verifyEqual(testCase, reg.a, 1.16e-4, 'AbsTol', eps);
verifyEqual(testCase, reg.n, 0.33, 'AbsTol', eps);
end

function testLoadsN2oPpEstimate(testCase)
reg = loadRegression(testCase.TestData.root, 'N2O', 'PP', 'circle');

verifyEqual(testCase, reg.id, "n2o_pp");
verifyEqual(testCase, reg.a, 7.49e-5, 'AbsTol', eps);
verifyEqual(testCase, reg.n, 0.68, 'AbsTol', eps);
end

function testLoadsBothN2oAbsModels(testCase)
circle = loadRegression(testCase.TestData.root, 'N2O', 'ABS', 'circle');
star = loadRegression(testCase.TestData.root, 'N2O', 'ABS', 'star_swirl');

verifyEqual(testCase, circle.id, "n2o_abs");
verifyEqual(testCase, circle.a, 1.18e-5, 'AbsTol', eps);
verifyEqual(testCase, circle.n, 0.799, 'AbsTol', eps);
verifyEqual(testCase, star.id, "n2o_abs_sf");
verifyEqual(testCase, star.port, "star_swirl");
verifyEqual(testCase, star.a, 1.07e-5, 'AbsTol', eps);
verifyEqual(testCase, star.n, 1.02, 'AbsTol', eps);
end

function testRejectsUnregisteredPortModel(testCase)
loader = @() loadRegression(testCase.TestData.root, 'N2O', 'ABS', 'unknown');
verifyError(testCase, loader, 'Regression:NotFound');
end

function testAbsOptionUsesAbsValue(testCase)
sourceHtml = fileread(fullfile(testCase.TestData.root, ...
    'Scripts', 'GeneralSettingUI', 'index.html'));
packagedHtml = fileread(fullfile(testCase.TestData.root, ...
    'Scripts', 'GeneralSettingUI', 'dist', 'GeneralSettingUI', ...
    '_internal', 'index.html'));

expected = '<option value="ABS">ABS</option>';
circleOption = '<option value="circle">円形ポート</option>';
starOption = '<option value="star_swirl">星形旋回（円形近似）</option>';
verifySubstring(testCase, sourceHtml, expected);
verifySubstring(testCase, packagedHtml, expected);
verifySubstring(testCase, sourceHtml, circleOption);
verifySubstring(testCase, sourceHtml, starOption);
verifySubstring(testCase, packagedHtml, circleOption);
verifySubstring(testCase, packagedHtml, starOption);
end

function testDashboardFuelCalculationUsesSelectedCoefficients(testCase)
models = {'PE', 'circle'; 'PP', 'circle'; ...
    'ABS', 'circle'; 'ABS', 'star_swirl'};
initial = struct('mdot_ox', 0.1, 'of', 5);
ave = struct('mdot_ox', 0.08);
df = 0.03;
rho_f = 1050;

for i = 1:size(models, 1)
    reg = loadRegression(testCase.TestData.root, 'N2O', ...
        models{i, 1}, models{i, 2});
    [fuel, status] = Mode5_Design_HomebrewEngine.Calc_Lf( ...
        initial, rho_f, 0.2, ave, df, 0.2, reg);

    verifyTrue(testCase, status.ok);
    verifyEqual(testCase, fuel.a, reg.a);
    verifyEqual(testCase, fuel.n, reg.n);

    elapsed = (numel(fuel.dfs) - 1)*fuel.time_step;
    expectedDiameter = (df^(2*reg.n + 1) + ...
        (2*reg.n + 1)*2*reg.a*(4*ave.mdot_ox/pi)^reg.n*elapsed) ...
        ^(1/(2*reg.n + 1));
    verifyEqual(testCase, fuel.dfs(end), expectedDiameter, 'RelTol', 1e-8);

    expectedLength = round((initial.mdot_ox/initial.of)/ ...
        (pi*df*rho_f*reg.a)*(4*initial.mdot_ox/(pi*df^2))^(-reg.n), 3);
    verifyEqual(testCase, fuel.Lf, expectedLength);
end
end

function testDashboardReportPreservesRegressionModelAndDensity(testCase)
reg = loadRegression(testCase.TestData.root, 'N2O', 'ABS', 'circle');
data.chamber = struct('cstar', 1595.8519*ones(21, 17), ...
    'gamma', 1.1553*ones(21, 17), 'rho_f', 1050, 'reg', reg);
p = struct('F_req', 1400, 'I_req', 8000, 'vt', 4700, ...
    'pti', 4, 'final_pt', 2.3, 'do', 7, 'df', 45, ...
    'Df_outer', 60, 'of_method', 'manual', 'manual_of', 6, ...
    'cstar_eff', 0.9, 'Cd', 0.33, 'Lf_max', 0.5, 'Lstar', 0.5);

report = Mode5_Design_HomebrewEngine.ComputeDesign(data, p);

verifyTrue(testCase, report.ok);
verifyEqual(testCase, report.parameters.regression_id, reg.id);
verifyEqual(testCase, report.parameters.regression_port, reg.port);
verifyEqual(testCase, report.parameters.a, reg.a);
verifyEqual(testCase, report.parameters.n, reg.n);
verifyEqual(testCase, report.parameters.rho_ox, 830);
expectedFinalFlow = data.chamber.rho_f*report.fuel.Lf*pi*report.dfs(end)* ...
    reg.a*(4*report.final.mdot_ox/(pi*report.dfs(end)^2))^reg.n;
verifyEqual(testCase, report.final.mdot_f, expectedFinalFlow, 'RelTol', 1e-12);
end

function testCsvExportUsesRadialRegressionRate(testCase)
fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
reg = loadRegression(testCase.TestData.root, 'N2O', 'ABS', 'circle');
diameters = [0.045; 0.05; 0.055];
time_step = 0.005;
mdot_ox = 0.42629;

Mode5_Design_HomebrewEngine.ExportGrainHistory( ...
    diameters, time_step, reg.a, reg.n, mdot_ox, fixture.Folder);
history = readtable(fullfile(fixture.Folder, 'DesignEngine_rdot_history.csv'), ...
    'VariableNamingRule', 'preserve');
expectedRate = reg.a*(4*mdot_ox./(pi*diameters.^2)).^reg.n;

verifyEqual(testCase, history.Properties.VariableNames, ...
    {'time[s]', 'regression_rate[m/s]'});
verifyEqual(testCase, history{:, 1}, [0; time_step; 2*time_step]);
verifyEqual(testCase, history{:, 2}, expectedRate, 'RelTol', 1e-12);
end
