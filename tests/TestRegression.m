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
verifyEqual(testCase, circle.a, 8.70e-6, 'AbsTol', eps);
verifyEqual(testCase, circle.n, 0.930, 'AbsTol', eps);
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
