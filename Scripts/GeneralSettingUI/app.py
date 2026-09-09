import os, sys, json, copy, argparse
import webview
from datetime import datetime

FILE = os.path.abspath(__file__)
ROOT = os.path.dirname(FILE)

parser = argparse.ArgumentParser()
parser.add_argument('--settings-dir', dest='settings_dir', default=None)
args, _unknown = parser.parse_known_args()

SETTINGS_DIR = os.path.abspath(args.settings_dir) if args.settings_dir else os.path.join(ROOT, "Settings")
if not os.path.exists(SETTINGS_DIR):
    os.makedirs(SETTINGS_DIR)

LOG_FILE = os.path.join(ROOT, 'GeneralSettingUI.log')
def log(msg: str):
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(f'[{datetime.now().isoformat()}] {msg}\n')
    except Exception as e:
        pass


class API:

    def __init__(self):   
        self.last_action = False   # True: 保存ボタン経由で正常終了 | False: ×ボタン等で閉じた場合
        self._window = None
    
    # --- JSONファイルを読み込む ---
    def load_json(self, src):
        with open(src, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return {'ok': True, 'data': data, 'path': src}

    # --- JSONファイルを書き込む ---
    def write_json(self, dst, data):
        with open(dst, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
        return {'ok': True, 'path': dst}

    # --- ファイルダイアログを開く ---
    def open_file(self, options={}):
        if 'file_types' in options and not isinstance(options['file_types'], tuple):
            options['file_types'] = tuple(options['file_types'])
        res = self._window.create_file_dialog(webview.FileDialog.OPEN, **options)
        if res:
            return res[0]
        raise Exception('No file selected')

    # --- ディレクトリダイアログを開く ---
    def open_dir(self, options={}):
        if 'file_types' in options and not isinstance(options['file_types'], tuple):
            options['file_types'] = tuple(options['file_types'])
        res = self._window.create_file_dialog(webview.FileDialog.FOLDER, **options)
        if res and len(res) > 0:
            return res[0]
        raise Exception('No file selected')

    # --- ファイル保存ダイアログを開く ---
    def save_file(self, options={}):
        if 'file_types' in options and not isinstance(options['file_types'], tuple):
            options['file_types'] = tuple(options['file_types'])
        res = self._window.create_file_dialog(webview.FileDialog.OPEN.SAVE, **options)
        if res:
            return res[0]
        raise Exception('No file selected')

    # --- 設定保存 ---
    def save_settings(self, payload, filename='settings.json'):
        try:
            dst = os.path.join(SETTINGS_DIR, filename)
            res = self.write_json(dst, payload)
            log(f'save_settings -> {res}')
            self.set_last_action(True)
            self.quit()
            return res
        except Exception as e:
            log(f'save_settings exception: {e}')
            return {'ok': False, 'error': str(e)}

    # --- 任意に設定保存 ---
    def save_settings_as(self, payload, filename='settings.json'):
        try:    
            file = self.save_file(options={
                'save_filename': filename,
                'file_types': ("JSON files (*.json)", "All Files (*.*)")
            })
            res = self.write_json(file, payload)
            log(f'save_settings_as -> {res}')
            return res
        except Exception as e:
            log(f'save_settings_as exception: {e}')
            return {'ok': False, 'error': str(e)}

    # --- 設定読み込み ---
    def load_settings(self, filename='settings.json'):
        try:
            src = os.path.join(SETTINGS_DIR, filename)
            if not os.path.isfile(src):
                return {'ok': False, 'error': f'Not found: {src}'}
            res = self.load_json(src)
            log(f'load_settings -> {res}')
            return res
        except Exception as e:
            log(f'load_settings exception: {e}')
            return {'ok': False, 'error': str(e)}

    # --- 任意の設定読み込み ---
    def load_settings_from(self):
        try:
            file = self.open_file(options={
                'file_types': ("JSON files (*.json)", "All Files (*.*)")
            })
            res = self.load_json(file)
            log(f'load_settings_from -> {res}')
            return res
        except Exception as e:
            log(f'load_settings_from exception: {e}')
            return {'ok': False, 'error': str(e)}

    # --- 最後のアクションをセットする ---
    def set_last_action(self, action: bool):
        self.last_action = action

    # --- ウィンドウをセットする ---
    def set_window(self, window):
        self._window = window

    # --- ウィンドウを閉じる ---
    def quit(self):
        if self._window:
            self._window.destroy()

    # --- ウィンドウを閉じるときに呼ばれる関数 ---
    def save_close(self):
        try:
            dst = os.path.join(SETTINGS_DIR, 'settings.json')
            data = { 'cancelled': True }
            self.write_json(dst, data)
            log(f'mark closed_by_x -> {dst}')
        except Exception as e:
            log(f'mark closed_by_x write failed: {e}')

if __name__ == '__main__':
    api = API()
    window = webview.create_window(
        title='General Setting UI', 
        url=os.path.join(ROOT, 'index.html'),
        js_api=api,
        width=800, height=600, resizable=True, 
        )
    api.set_window(window)
    webview.start(debug=False, http_server=True)

    if not api.last_action:
        api.save_close()