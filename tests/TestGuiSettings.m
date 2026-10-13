function tests = TestGuiSettings
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.root = fileparts(fileparts(mfilename('fullpath')));
addpath(testCase.TestData.root);
end

function teardownOnce(testCase)
rmpath(testCase.TestData.root);
end

function testSourceAndPackagedScriptsMatch(testCase)
source = fileread(fullfile(testCase.TestData.root, ...
    'Scripts', 'GeneralSettingUI', 'js', 'app.js'));
packaged = fileread(fullfile(testCase.TestData.root, ...
    'Scripts', 'GeneralSettingUI', 'dist', 'GeneralSettingUI', ...
    '_internal', 'js', 'app.js'));

verifyEqual(testCase, packaged, source);
end

function testSaveFlowHasNoBareJapaneseIdentifier(testCase)
source = fileread(fullfile(testCase.TestData.root, ...
    'Scripts', 'GeneralSettingUI', 'js', 'app.js'));

bareLabel = regexp(source, ...
    '(?m)^\s*全モードの入力値バリデーションを実行\s*$', 'once');
verifyEmpty(testCase, bareLabel);
verifySubstring(testCase, source, 'cancelled: false');
verifySubstring(testCase, source, ...
    'safeCheckValidity(modeSections[selectedMode - 1], payload)');
verifySubstring(testCase, source, 'if (!res?.ok)');
end

function testGeneralSettingDefaultsToNotCancelled(testCase)
gs = GeneralSetting(testCase.TestData.root);
verifyFalse(testCase, gs.cancelled);
end

function testSimulatorGuardsCancelledAndInvalidMode(testCase)
source = fileread(fullfile(testCase.TestData.root, ...
    'Combustion_Simulator.m'));

verifySubstring(testCase, source, 'if gs.cancelled');
verifySubstring(testCase, source, 'CombustionSimulator:InvalidMode');
end
