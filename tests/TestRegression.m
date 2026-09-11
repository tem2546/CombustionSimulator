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
verifyEqual(testCase, reg.a, 1.16e-4, 'AbsTol', eps);
verifyEqual(testCase, reg.n, 0.33, 'AbsTol', eps);
end

function testRejectsUnregisteredCombination(testCase)
loader = @() loadRegression(testCase.TestData.root, 'N2O', 'ABS');
verifyError(testCase, loader, 'Regression:NotFound');
end

function testAbsOptionUsesAbsValue(testCase)
sourceHtml = fileread(fullfile(testCase.TestData.root, ...
    'Scripts', 'GeneralSettingUI', 'index.html'));
packagedHtml = fileread(fullfile(testCase.TestData.root, ...
    'Scripts', 'GeneralSettingUI', 'dist', 'GeneralSettingUI', ...
    '_internal', 'index.html'));

expected = '<option value="ABS">ABS</option>';
verifySubstring(testCase, sourceHtml, expected);
verifySubstring(testCase, packagedHtml, expected);
end
