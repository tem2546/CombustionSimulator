# app.py — HTTPサーバー＋ダイアログ安定＋保存API
import os, sys, json, argparse, shutil, mimetypes, math, logging, copy, traceback
import webview
from datetime import datetime

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
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))

# 起動引数 --settings-dir があればそれを使用、なければ従来通り
SETTINGS_DIR = args.settings_dir or os.path.join(PROJECT_ROOT, 'Settings')
# 念のため作成
if not os.path.exists(SETTINGS_DIR):
    os.makedirs(SETTINGS_DIR, exist_ok=True)

PRESETTINGS_FILE = args.presettings_file or os.path.join(PROJECT_ROOT, 'PreSettings', 'PreSettings.json')

UPLOAD_DIR = os.path.join(PROJECT_ROOT, 'assets', 'uploads')
os.makedirs(UPLOAD_DIR, exist_ok=True)

LOG_FILE = os.path.join(PROJECT_ROOT, 'GeneralSettingUI.log')
def log(msg: str):
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(f'[{datetime.now().isoformat()}] {msg}\n')
    except Exception:
        pass

class API:

    def __init__(self):   
        self.last_action = False   # True: 保存ボタン経由で正常終了 | False: ×ボタン等で閉じた場合
        self.window = None         # main()で現在のウインドウが代入されます

    # ---- 修正: window を経由してダイアログを呼ぶ ----
    def open_file(self, *args):
        if not self.window:
            return None
        # webview.create_file_dialog ではなく self.window を使う
        result = self.window.create_file_dialog(webview.FileDialog.OPEN)
        if result:
            return result[0]
        return None

    def open_dir(self, *args):
        if not self.window:
            return None
        # フォルダ選択も同様
        res = self.window.create_file_dialog(webview.FOLDER_DIALOG)
        if res and len(res) > 0:
            return res[0]
        return None

    # ---- ✨ 統合保存API（すべてのモードのパラメータをsettings.jsonへ一括出力） ----
    def save_settings(self, payload, filename='settings.json'):
        try:
            dst = os.path.join(SETTINGS_DIR, filename)
            
            # JSから送られてきた統合payload（全モード内包）を上書き保存
            with open(dst, 'w', encoding='utf-8') as f:
                json.dump(payload, f, ensure_ascii=False, indent=2)
                
            log(f'save_settings -> {dst}')
            
            # ボタン押下による正常保存フラグを立てる
            self.last_action = True 
            
            if self.window is not None:
                self.window.destroy()  # UIを消滅させ、MATLABのsystem待機を突破させる
            return {'ok': True, 'path': dst}
        except Exception as e:
            log(f'save_settings exception: {e}')
            return {'ok': False, 'error': str(e)}

    # ---- 名前を付けて保存 ----
    def save_settings_as(self, payload, default_filename='settings.json'):
        try:
            if not self.window:
                return {'ok': False, 'error': 'Window not found'}
                
            initdir = SETTINGS_DIR if os.path.isdir(SETTINGS_DIR) else BASE
            
            res = self.window.create_file_dialog(
                webview.SAVE_DIALOG,
                directory=initdir,
                save_filename=default_filename,
                file_types=("JSON files (*.json)", "All Files (*.*)")
            )
            
            if not res:
                return {'ok': False, 'error': 'User cancelled'}
                
            path = res
            cleaned = copy.deepcopy(payload)
            for key in ('param', 'thrust', 'fp', 'MSM', 'wind_csv', 'Mx_csv'):
                if key in cleaned and isinstance(cleaned[key], dict):
                    for sub in ('fn', 'path'):
                        v = cleaned[key].get(sub)
                        if isinstance(v, list):
                            cleaned[key][sub] = [''] * len(v)
                        else:
                            cleaned[key][sub] = ''
            adb = cleaned.get('aero_db')
            if isinstance(adb, dict) and isinstance(adb.get('files'), list):
                for f in adb['files']:
                    if isinstance(f, dict):
                        f['fn'] = ''
                        f['path'] = ''
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

    # ---- 前回設定を読み込み ----
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

    # ---- 任意ファイルから読み込み ----
    def load_settings_from(self):
        try:
            if not self.window:
                return {'ok': False, 'error': 'Window not found'}
                
            initdir = SETTINGS_DIR if os.path.isdir(SETTINGS_DIR) else BASE
            res = self.window.create_file_dialog(
                webview.FileDialog.OPEN,
                directory=initdir,
                file_types=("JSON files (*.json)", "All Files (*.*)")
            )
            if not res:
                return {'ok': False, 'error': 'User cancelled'}
                
            path = res[0]
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
        window.evaluate_js("""
            (function(){
              if (!window.__PY_READY__) {
                window.__PY_READY__ = true;
                window.dispatchEvent(new CustomEvent('py-ready'));
              }
            })();
        """)

    window.events.loaded += on_loaded
    api.window = window

    webview.start(debug=False, http_server=True)

    # 💡 【セーフティ】ユーザーが右上「×ボタン」で強制終了した場合のフォールバック
    if api.last_action is False:
        dst = os.path.join(SETTINGS_DIR, 'settings.json')
        marker = {
            'closed_by_x': True,
            'cancelled': True,
            'current_mode': 1  # MATLAB側のパースエラーを防ぐためのセーフ値
        }
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
    try:
        main()
    except Exception:
        # console=False build swallows tracebacks otherwise, making startup
        # failures (e.g. missing WebView2 runtime) look like silent hangs.
        log('FATAL startup exception:\n' + traceback.format_exc())
        sys.exit(1)