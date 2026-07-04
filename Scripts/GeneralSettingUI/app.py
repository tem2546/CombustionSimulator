
# app.py — HTTPサーバー＋Excel解析＋ダイアログ安定＋保存API
import os, sys, json, argparse, shutil, mimetypes, math, logging, copy
import webview
import tkinter as tk
from tkinter import filedialog
from datetime import datetime
import pandas as pd

# pywebview Windows バックエンドのネイティブオブジェクト走査エラーを抑制
class _SuppressNativeWindowErrors(logging.Filter):
    def filter(self, record):
        return 'window.native' not in record.getMessage()

logging.getLogger('pywebview').addFilter(_SuppressNativeWindowErrors())

parser = argparse.ArgumentParser(description="General Settings UI (pywebview)")
parser.add_argument("--settings-dir", type=str, default=None)
parser.add_argument("--presettings-file", type=str, default=None)
parser.add_argument("--debug", action="store_true")
args, _ = parser.parse_known_args()

def APP_BASE():
    return os.path.dirname(os.path.abspath(__file__))

BASE = APP_BASE()
SETTINGS_DIR = args.settings_dir or os.path.join(BASE, 'CurrentSetting')
os.makedirs(SETTINGS_DIR, exist_ok=True)

PRESETTINGS_FILE = args.presettings_file or os.path.join(BASE, 'PreSettings', 'PreSettings.json')

UPLOAD_DIR = os.path.join(BASE, 'assets', 'uploads')
os.makedirs(UPLOAD_DIR, exist_ok=True)

LOG_FILE = os.path.join(BASE, 'GeneralSettingUI.log')
def log(msg: str):
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(f'[{datetime.now().isoformat()}] {msg}\n')
    except Exception:
        pass

def _with_tk_dialog(dialog_fn):
    root = None
    try:
        root = tk.Tk(); root.withdraw()
        try:
            root.attributes('-topmost', True); root.update()
        except Exception:
            pass
        return dialog_fn(root)
    finally:
        if root is not None:
            try: root.destroy()
            except Exception: pass

class API:

    def __init__(self):   
        self.last_action = False   # True | False(=×で閉じた場合)

    # ---- 絶対パスのファイル選択 ----
    def open_file(self, filters=None, multiple=False):
        def _ft(filters):
            if not filters: return [('All Files', '*.*')]
            out = []
            for f in filters:
                desc = f.get('description', 'Files'); exts = f.get('extensions', ['*'])
                out.append((desc, tuple(f'*.{e}' for e in exts)))
            return out
        try:
            filetypes = _ft(filters)
            def _dlg(root):
                if multiple:
                    paths = filedialog.askopenfilenames(parent=root, filetypes=filetypes)
                    return list(paths) or None
                else:
                    path = filedialog.askopenfilename(parent=root, filetypes=filetypes)
                    return path or None
            res = _with_tk_dialog(_dlg)
            log(f'open_file -> {res}')
            return res
        except Exception as e:
            log(f'open_file exception: {e}')
            return {'ok': False, 'error': str(e)}

    def open_dir(self):
        try:
            def _dlg(root):
                path = filedialog.askdirectory(parent=root)
                return path or None
            res = _with_tk_dialog(_dlg)
            log(f'open_dir -> {res}')
            return res
        except Exception as e:
            log(f'open_dir exception: {e}')
            return {'ok': False, 'error': str(e)}

    # ---- 保存（Settings/{filename}）----
    def save_settings(self, payload, filename='settings.json'):
        try:
            dst = os.path.join(SETTINGS_DIR, filename)
            with open(dst, 'w', encoding='utf-8') as f:
                json.dump(payload, f, ensure_ascii=False, indent=2)
            log(f'save_settings -> {dst}')
            self.last_action = True 
            if self.window is not None:
                self.window.destroy()
            return {'ok': True, 'path': dst}
        except Exception as e:
            log(f'save_settings exception: {e}')
            return {'ok': False, 'error': str(e)}

    def save_settings_as(self, payload, default_filename='settings.json'):
        try:
            def _dlg(root):
                initdir = SETTINGS_DIR if os.path.isdir(SETTINGS_DIR) else BASE
                path = filedialog.asksaveasfilename(
                    parent=root, title='Save settings as...',
                    initialdir=initdir, initialfile=default_filename,
                    defaultextension='.json',
                    filetypes=[('JSON files', '*.json'), ('All Files', '*.*')]
                )
                return path
            path = _with_tk_dialog(_dlg)
            if not path:
                return {'ok': False, 'error': 'User cancelled'}
            # ファイルパスを削除してから保存（共有時の個人情報保護）
            cleaned = copy.deepcopy(payload)
            for key in ('param', 'thrust', 'fp', 'MSM', 'wind_csv', 'Mx_csv'):
                if key in cleaned and isinstance(cleaned[key], dict):
                    for sub in ('fn', 'path'):
                        v = cleaned[key].get(sub)
                        if isinstance(v, list):
                            cleaned[key][sub] = [''] * len(v)
                        else:
                            cleaned[key][sub] = ''
            # 動翼空力DB（files 配列）も fn/path を空に（use/v は保持）
            adb = cleaned.get('aero_db')
            if isinstance(adb, dict) and isinstance(adb.get('files'), list):
                for f in adb['files']:
                    if isinstance(f, dict):
                        f['fn'] = ''
                        f['path'] = ''
            # パーツ別空力（comp_aero）も fn/path を空に（use/delta_fixed は保持）
            ca = cleaned.get('comp_aero')
            if isinstance(ca, dict):
                ca['fn'] = ''
                ca['path'] = ''
            if 'result_path' in cleaned:
                cleaned['result_path'] = ''
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(cleaned, f, ensure_ascii=False, indent=2)
            log(f'save_settings_as -> {path}')
            return {'ok': True, 'path': path}
        except Exception as e:
            log(f'save_settings_as exception: {e}')
            return {'ok': False, 'error': str(e)}

    # ---- 読み込み（Settings/{filename}）----
    def load_settings(self, filename='settings.json'):
        try:
            src = os.path.join(SETTINGS_DIR, filename)
            if not os.path.isfile(src):
                log(f'load_settings not found: {src}')
                return {'ok': False, 'error': f'Not found: {src}'}
            with open(src, 'r', encoding='utf-8') as f:
                data = json.load(f)
            log(f'load_settings <- {src} (keys: {list(data.keys())})')
            return {'ok': True, 'data': data}
        except Exception as e:
            log(f'load_settings exception: {e}')
            return {'ok': False, 'error': str(e)}

    # ---- 端末ローカルの前回設定を読み込み（パス込み）----
    def load_presettings(self):
        try:
            src = PRESETTINGS_FILE
            if not os.path.isfile(src):
                log(f'load_presettings not found: {src}')
                return {'ok': False, 'error': f'Not found: {src}'}
            with open(src, 'r', encoding='utf-8') as f:
                data = json.load(f)
            log(f'load_presettings <- {src} (keys: {list(data.keys())})')
            return {'ok': True, 'data': data, 'path': src}
        except Exception as e:
            log(f'load_presettings exception: {e}')
            return {'ok': False, 'error': str(e)}

    # ---- 任意ファイルから読み込み（ダイアログ）----
    def load_settings_from(self):
        try:
            def _dlg(root):
                initdir = SETTINGS_DIR if os.path.isdir(SETTINGS_DIR) else BASE
                path = filedialog.askopenfilename(
                    parent=root, title='Open settings file...',
                    initialdir=initdir,
                    filetypes=[('JSON files', '*.json'), ('All Files', '*.*')]
                )
                return path
            path = _with_tk_dialog(_dlg)
            if not path:
                return {'ok': False, 'error': 'User cancelled'}
            with open(path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            log(f'load_settings_from <- {path} (keys: {list(data.keys())})')
            return {'ok': True, 'data': data, 'path': path}
        except Exception as e:
            log(f'load_settings_from exception: {e}')
            return {'ok': False, 'error': str(e)}

    # ---- 画像を公開ルートへコピーして相対URLで返す ----
    def import_image_to_public(self, abs_path: str):
        try:
            if not abs_path or not os.path.isfile(abs_path):
                return {'ok': False, 'error': 'Not a file'}
            fname = os.path.basename(abs_path)
            base, ext = os.path.splitext(fname)
            i, dst = 0, os.path.join(UPLOAD_DIR, fname)
            while os.path.exists(dst):
                i += 1
                dst = os.path.join(UPLOAD_DIR, f'{base}_{i}{ext}')
            shutil.copy2(abs_path, dst)
            rel_url = '/assets/uploads/' + os.path.basename(dst)
            mime, _ = mimetypes.guess_type(dst)
            log(f'Imported image: {dst} (mime={mime}) -> {rel_url}')
            return {'ok': True, 'url': rel_url}
        except Exception as e:
            log(f'import_image_to_public exception: {e}')
            return {'ok': False, 'error': str(e)}

def main():

    api = API()
    window = webview.create_window(
        title='General Settings UI',
        url=os.path.join(BASE, 'index.html'),
        js_api=api,
        width=1100, height=800, resizable=True
    )

    def on_loaded(win=None):
        # _pywebviewready を経た後なので evaluate_js を安全に呼べる
        window.evaluate_js("""
            (function(){
              // Python 準備完了の合図（複数回投げても害がないよう冪等化）
              if (!window.__PY_READY__) {
                window.__PY_READY__ = true;
                window.dispatchEvent(new CustomEvent('py-ready'));
              }
            })();
        """)  # evaluate_js は _pywebviewready 以降が要件[1](https://deepwiki.com/r0x0r/pywebview/5.2-window-methods-and-operations)

    window.events.loaded += on_loaded  # loaded は shown/_pywebviewready の後段[2](https://pywebview.idepy.com/en/guide/api)

    api.window = window

    webview.start(debug=False, http_server=True)

    if api.last_action is False:
        dst = os.path.join(SETTINGS_DIR, 'settings.json')
        marker = {'closed_by_x': True}
        try:
            if os.path.isfile(dst):
                with open(dst, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                data.update(marker)
                payload = data
            else:
                payload = marker
            with open(dst, 'w', encoding='utf-8') as f:
                json.dump(payload, f, ensure_ascii=False, indent=2)
            log(f'post-start -> mark closed_by_x in {dst}')
        except Exception as e:
            log(f'post-start marker write failed: {e}')

if __name__ == '__main__':
    main()
