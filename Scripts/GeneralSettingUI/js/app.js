import { byId, setText, setVal } from "./core/dom.js";
import { SettingsStore } from "./core/store.js";
import { ModelSettings } from "./sections/model-settings.js";
import { CondSettings } from "./sections/cond-settings.js";
import { RollSettings } from "./sections/roll-settings.js";
import { OptionSettings } from "./sections/option-settings.js";
import { OutputSettings } from "./sections/output-settings.js";
import { initLang, toggleLang, t } from "./core/i18n.js";
import { initInfoButtons, refreshInfoOnLangChange } from "./core/info.js";

const FILE_KEYS = ["param","thrust","MSM","wind_csv","Mx_csv"];
const DIR_KEYS  = ["result_path"];

const store  = new SettingsStore();
const model  = new ModelSettings();
const cond   = new CondSettings();
const roll   = new RollSettings();
const option = new OptionSettings();
const output = new OutputSettings();

// ---- 共有ユーティリティ ----
function sanitizeFileFields(data) {
  const cleaned = { ...data };
  // ファイル系は UI 上では常に「未選択」に戻す
  for (const k of FILE_KEYS) {
    if (cleaned[k]) cleaned[k] = { ...(cleaned[k] ?? {}), fn: "", path: "" };
  }
  // 動翼空力DB（ファイル配列構造）も fn/path を空に戻す（use/v は保持）
  if (cleaned.aero_db && Array.isArray(cleaned.aero_db.files)) {
    cleaned.aero_db = {
      ...cleaned.aero_db,
      files: cleaned.aero_db.files.map(f => ({ ...(f ?? {}), fn: "", path: "" })),
    };
  }
  // ディレクトリ系は空文字へ
  for (const k of DIR_KEYS) {
    if (k in cleaned) cleaned[k] = "";
  }
  return cleaned;
}
// 防御的集約：配列/文字列/undefined をひとまとめに
const pack = (...xs) => xs.flatMap(x => (Array.isArray(x) ? x : (x ? [String(x)] : [])));

// ---- 握手：pywebviewready と py-ready の両方を待つ ----
function whenPywebviewReady() {
  if (window.pywebview && window.pywebview.api) return Promise.resolve();
  return new Promise((resolve) => {
    const h = () => { window.removeEventListener('pywebviewready', h); resolve(); };
    window.addEventListener('pywebviewready', h, { once: true });
  });
}
function whenPythonReady() {
  if (window.__PY_READY__) return Promise.resolve();
  return new Promise((resolve) => {
    const h = () => { window.removeEventListener('py-ready', h); resolve(); };
    window.addEventListener('py-ready', h, { once: true });
  });
}
const afterPaint = (fn) => requestAnimationFrame(() => requestAnimationFrame(fn));

// ---- 段階初期化（重い処理を描画後に分散）----
async function bootstrap() {
  // A) 揃うまで何もしない
  await Promise.all([ whenPywebviewReady(), whenPythonReady() ]);

  // B) まずは init（軽い）
  model.init(store);
  cond.init(store);
  roll.init(store);
  option.init(store);
  output.init(store);

  // B-2) 言語を先に確定（applyDefaults がファイルラベルを t() で出すため）
  initLang();
  initInfoButtons();
  byId("langToggle")?.addEventListener("click", () => {
    toggleLang();
    refreshInfoOnLangChange();
  });

  // C) 既定値反映は段階適用（reflow 分散）
  store.resetToDefaults();
  model.applyDefaults();
  cond.applyDefaults();
  roll.applyDefaults();
  option.applyDefaults();
  output.applyDefaults();

  // ==== 以下、各ボタンのハンドラ ====

  // 読み込み（Settings/settings.json）
  byId("loadBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");
    const res = await window.pywebview.api.load_settings("settings.json");
    if (!res?.ok) {
      msg.textContent = t("msg.loadFail", { err: res?.error ?? "" });
      msg.style.color = "#b00020";
      return;
    }
    const cleaned = sanitizeFileFields(res.data ?? {});
    store.apply(cleaned);
    model.applyDefaults();
    cond.applyDefaults();
    roll.applyDefaults();
    option.applyDefaults();
    output.applyDefaults();
    msg.textContent = t("msg.loadOk");
    msg.style.color = "#1a7f37";
  });

  // 前回設定を読み込み（端末ローカル PreSettings.json、ファイル/フォルダパス込みで反映）
  byId("loadPreBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");
    const res = await window.pywebview.api.load_presettings();
    if (!res?.ok) {
      msg.textContent = t("msg.preFail", { err: res?.error ?? "" });
      msg.style.color = "#b00020";
      return;
    }
    // パスをサニタイズせずそのまま反映
    store.apply(res.data ?? {});
    model.applyDefaults();
    cond.applyDefaults();
    roll.applyDefaults();
    option.applyDefaults();
    output.applyDefaults();

    // 各セクションの applyDefaults はファイル系ラベルを「(未選択)」に固定する箇所があるため、
    // 前回設定読み込み時のみ store の fn 値でラベルを上書きする
    const s = store.get();
    const setSel = (id, name) => { setText(id, t("msg.selected", { name })); byId(id)?.classList.add("selected"); };
    if (s.multi_stage) {
      const fnArr = Array.isArray(s.param?.fn) ? s.param.fn : ["", "", ""];
      ["param1_fn_label","param2_fn_label","param3_fn_label"].forEach((id, i) => {
        if (fnArr[i]) setSel(id, fnArr[i]);
      });
    } else {
      const fn = Array.isArray(s.param?.fn) ? (s.param.fn[0] ?? "") : (s.param?.fn ?? "");
      if (fn) setSel("param_fn_label", fn);
    }
    if (s.thrust?.fn) setSel("thrust_fn_label", s.thrust.fn);
    if (s.Mx_csv?.fn) setVal("mx_fn", t("msg.selected", { name: s.Mx_csv.fn }));
    if (Array.isArray(s.aero_db?.files)) {
      s.aero_db.files.forEach((f, i) => {
        if (f?.fn) setSel(`aero_fn_label_${i}`, f.fn);
      });
    }
    if (s.result_path) setSel("result_path_label", s.result_path);

    msg.textContent = t("msg.preOk");
    msg.style.color = "#1a7f37";
  });

  // 現在の設定を保存して終了
  byId("saveBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");
    const ok = confirm(t("msg.confirmSave"));
    if (!ok) {
      msg.textContent = t("msg.saveCancel");
      msg.style.color = "#b00020";
      return;
    }

    const payload = {
      ...model.collectPayload(),
      ...cond.collectPayload(),
      ...roll.collectPayload(),
      ...option.collectPayload(),
      ...output.collectPayload(),
    };

    // バリデーション
    const errs = [];
    
    const modelErrs = model.checkValidity(payload);
    const condErrs = cond.checkValidity(payload);
    const rollErrs = roll.checkValidity(payload);
    const optionErrs = option.checkValidity(payload);
    const outputErrs = output.checkValidity(payload);

    errs.push(...modelErrs, ...condErrs, ...rollErrs, ...optionErrs, ...outputErrs);
    if (errs.length) {
      msg.textContent = t("ui.inputError") + ": " + errs.join(" / ");
      msg.style.color = "#b00020";
      return;
    }

    // Roll 無効時の正規化（既存仕様のまま）
    if (payload.execute_cont === false) {
      Object.assign(payload, {
        control_func: "",
        simu_mode: "Launch",
        roll_factor: "Coefficience",
        Cl0: 0,
        rot_cond: { Va: undefined, z: undefined },
        Mx_csv: { fn: "", path: "" },
      });
    }

    // 保存 → 成功時は Python 側が destroy() を遅延実行
    const res = await window.pywebview.api.save_settings(payload, "settings.json");
    if (!res?.ok) {
      msg.textContent = t("msg.saveFail", { err: res?.error ?? "" });
      msg.style.color = "#b00020";
    }
  });

  // 名前を付けて保存（保存後は終了）
  byId("saveAsBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");

    const payload = {
      ...model.collectPayload(),
      ...cond.collectPayload(),
      ...roll.collectPayload(),
      ...option.collectPayload(),
      ...output.collectPayload(),
    };
    const errs = pack(
      model.checkValidity(payload),
      cond.checkValidity(payload),
      roll.checkValidity(payload),
      option.checkValidity(payload),
      output.checkValidity(payload),
    );
    if (errs.length) {
      msg.textContent = t("ui.inputError") + ": " + errs.join(" / ");
      msg.style.color = "#b00020";
      return;
    }
    if (payload.execute_cont === false) {
      Object.assign(payload, {
        control_func: "",
        simu_mode: "Launch",
        roll_factor: "Coefficience",
        Cl0: 0,
        rot_cond: { Va: undefined, z: undefined },
        Mx_csv: { fn: "", path: "" },
      });
    }

    const res = await window.pywebview.api.save_settings_as(payload, "settings.json");
    if (!res?.ok) {
      msg.textContent = t("msg.saveFail", { err: res?.error ?? "" });
      msg.style.color = "#b00020";
    }
  });

  // 任意ファイルから読み込み
  byId("openFileBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");
    try {
      const res = await window.pywebview.api.load_settings_from();
      if (!res?.ok) {
        msg.textContent = t("msg.openFail", { err: res?.error ?? "" });
        msg.style.color = "#b00020";
        return;
      }
      const cleaned = sanitizeFileFields(res.data ?? {});
      store.apply(cleaned);
      model.applyDefaults();
      cond.applyDefaults();
      roll.applyDefaults();
      option.applyDefaults();
      output.applyDefaults();
      msg.textContent = t("msg.openOk", { path: res.path });
      msg.style.color = "#1a7f37";
    } catch (e) {
      msg.textContent = t("msg.openFail", { err: String(e) });
      msg.style.color = "#b00020";
    }
  });
}

bootstrap().catch(err => console.error('[bootstrap]', err));