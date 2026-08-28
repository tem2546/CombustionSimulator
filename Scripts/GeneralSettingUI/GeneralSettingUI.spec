# -*- mode: python ; coding: utf-8 -*-

from pathlib import Path

PROJECT_DIR = Path(SPECPATH)


a = Analysis(
    [str(PROJECT_DIR / 'app.py')],
    pathex=[str(PROJECT_DIR)],
    binaries=[],
    datas=[
        (str(PROJECT_DIR / 'index.html'), '.'),
        (str(PROJECT_DIR / 'js'), 'js'),
        (str(PROJECT_DIR / 'assets'), 'assets'),
    ],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

# onedir build: exe + libs sit side-by-side in dist/GeneralSettingUI/ instead of
# being unpacked to a fresh %TEMP%\_MEIxxxxxx folder on every launch (--onefile).
# That unpack-per-run was the main source of slow/heavy startups and made the
# process an easy target for AV to lock mid-extraction.
exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='GeneralSettingUI',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['assets\\icon.ico'],
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='GeneralSettingUI',
)
