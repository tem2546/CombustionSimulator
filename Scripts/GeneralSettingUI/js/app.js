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

// ---- 既存のセクション処理を画面要素がなくても安全に実行・スルーするための安全ラッパー ----
function safeApplyDefaults(sec) {
  try {
    if (typeof sec?.applyDefaults === "function") sec.applyDefaults();
  } catch (e) {
    console.warn("セクションの既定値適用をスキップしました (一部の画面要素がありません):", e);
  }
}

function safeCollectPayload(sec) {
  try {
    if (typeof sec?.collectPayload === "function") return sec.collectPayload() ?? {};
  } catch (e) {
    console.warn("セクションのデータ回収をスキップしました (一部の画面要素がありません):", e);
  }
  return {};
}

function safeCheckValidity(sec, payload) {
  try {
    if (typeof sec?.checkValidity === "function") return sec.checkValidity(payload) ?? [];
  } catch (e) {
    console.warn("セクションのバリデーションをスキップしました (一部の画面要素がありません):", e);
  }
  return [];
}

// 一連の画面同期処理を一括して安全に実行
function refreshAllSectionUi() {
  const sections = [model, cond, roll, option, output];
  for (const sec of sections) {
    safeApplyDefaults(sec);
  }
}

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
  const sections = [model, cond, roll, option, output];
  for (const sec of sections) {
    try {
      if (typeof sec?.init === "function") sec.init(store);
    } catch (e) {
      console.warn("イベント登録をスキップしました (一部の画面要素がありません):", e);
    }
  }

  // B-2) 言語を先に確定（applyDefaults がファイルラベルを t() で出すため）
  initLang();
  initInfoButtons();
  byId("langToggle")?.addEventListener("click", () => {
    toggleLang();
    refreshInfoOnLangChange();
  });

  // C) 既定値反映は段階適用（reflow 分散）
  store.resetToDefaults();
  refreshAllSectionUi();

  // ==== 以下、各ボタンのハンドラ ====

  // 読み込み（Settings/settings.json）
  byId("loadBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");
    const res = await window.pywebview.api.load_settings("settings.json");
    if (!res?.ok) {
      if (msg) {
        msg.textContent = t("msg.loadFail", { err: res?.error ?? "" });
        msg.style.color = "#b00020";
      }
      return;
    }
    const cleaned = sanitizeFileFields(res.data ?? {});
    store.apply(cleaned);
    refreshAllSectionUi();
    if (msg) {
      msg.textContent = t("msg.loadOk");
      msg.style.color = "#1a7f37";
    }
  });

  // 前回設定を読み込み（端末ローカル PreSettings.json、ファイル/フォルダパス込みで反映）
  byId("loadPreBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");
    const res = await window.pywebview.api.load_presettings();
    if (!res?.ok) {
      if (msg) {
        msg.textContent = t("msg.preFail", { err: res?.error ?? "" });
        msg.style.color = "#b00020";
      }
      return;
    }
    // パスをサニタイズせずそのまま反映
    store.apply(res.data ?? {});
    refreshAllSectionUi();

    // 各セクションの applyDefaults はファイル系ラベルを「(未選択)」に固定する箇所があるため、
    // 前回設定読み込み時のみ store の fn 値でラベルを上書きする
    try {
      const s = store.get();
      const setSel = (id, name) => { setText(id, t("msg.selected", { name })); byId(id)?.classList.add("selected"); };
      if (s.multi_stage) {
        const fnArr = Array.isArray(s.param?.fn) ? s.param.fn : ["", "", ""];
        ["param1_fn_label","param2_fn_label","param3_fn_label"].forEach((id, i) => {
          if (fnArr[i] && byId(id)) setSel(id, fnArr[i]);
        });
      } else {
        const fn = Array.isArray(s.param?.fn) ? (s.param.fn[0] ?? "") : (s.param?.fn ?? "");
        if (fn && byId("param_fn_label")) setSel("param_fn_label", fn);
      }
      if (s.thrust?.fn && byId("thrust_fn_label")) setSel("thrust_fn_label", s.thrust.fn);
      if (s.Mx_csv?.fn && byId("mx_fn")) setVal("mx_fn", t("msg.selected", { name: s.Mx_csv.fn }));
      if (Array.isArray(s.aero_db?.files)) {
        s.aero_db.files.forEach((f, i) => {
          if (f?.fn && byId(`aero_fn_label_${i}`)) setSel(`aero_fn_label_${i}`, f.fn);
        });
      }
      if (s.result_path && byId("result_path_label")) setSel("result_path_label", s.result_path);
    } catch (e) {
      console.warn("前回設定のラベル反映を一部スキップしました:", e);
    }

    if (msg) {
      msg.textContent = t("msg.preOk");
      msg.style.color = "#1a7f37";
    }
  });

  // 現在の設定を保存して終了
  byId("saveBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");
    const ok = confirm(t("msg.confirmSave"));
    if (!ok) {
      if (msg) {
        msg.textContent = t("msg.saveCancel");
        msg.style.color = "#b00020";
      }
      return;
    }

    const payload = {
      ...safeCollectPayload(model),
      ...safeCollectPayload(cond),
      ...safeCollectPayload(roll),
      ...safeCollectPayload(option),
      ...safeCollectPayload(output),
    };

    // バリデーション
    const errs = [
      ...safeCheckValidity(model, payload),
      ...safeCheckValidity(cond, payload),
      ...safeCheckValidity(roll, payload),
      ...safeCheckValidity(option, payload),
      ...safeCheckValidity(output, payload)
    ];

    if (errs.length) {
      if (msg) {
        msg.textContent = t("ui.inputError") + ": " + errs.join(" / ");
        msg.style.color = "#b00020";
      }
      return;
    }

    // Roll 無効時の正規化（既存仕様のまま。execute_contが画面に無ければ強制的に安全側の値をセットする）
    const executeContEl = byId("execute_cont");
    const executeContVal = executeContEl ? !!executeContEl.checked : false;
    if (executeContVal === false) {
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
      if (msg) {
        msg.textContent = t("msg.saveFail", { err: res?.error ?? "" });
        msg.style.color = "#b00020";
      }
    }
  });

  // 名前を付けて保存（保存後は終了）
  byId("saveAsBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");

    const payload = {
      ...safeCollectPayload(model),
      ...safeCollectPayload(cond),
      ...safeCollectPayload(roll),
      ...safeCollectPayload(option),
      ...safeCollectPayload(output),
    };
    const errs = pack(
      safeCheckValidity(model, payload),
      safeCheckValidity(cond, payload),
      safeCheckValidity(roll, payload),
      safeCheckValidity(option, payload),
      safeCheckValidity(output, payload)
    );
    if (errs.length) {
      if (msg) {
        msg.textContent = t("ui.inputError") + ": " + errs.join(" / ");
        msg.style.color = "#b00020";
      }
      return;
    }
    
    const executeContEl = byId("execute_cont");
    const executeContVal = executeContEl ? !!executeContEl.checked : false;
    if (executeContVal === false) {
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
      if (msg) {
        msg.textContent = t("msg.saveFail", { err: res?.error ?? "" });
        msg.style.color = "#b00020";
      }
    }
  });

  // 任意ファイルから読み込み
  byId("openFileBtn")?.addEventListener("click", async () => {
    const msg = byId("msg");
    try {
      const res = await window.pywebview.api.load_settings_from();
      if (!res?.ok) {
        if (msg) {
          msg.textContent = t("msg.openFail", { err: res?.error ?? "" });
          msg.style.color = "#b00020";
        }
        return;
      }
      const cleaned = sanitizeFileFields(res.data ?? {});
      store.apply(cleaned);
      refreshAllSectionUi();
      if (msg) {
        msg.textContent = t("msg.openOk", { path: res.path });
        msg.style.color = "#1a7f37";
      }
    } catch (e) {
      if (msg) {
        msg.textContent = t("msg.openFail", { err: String(e) });
        msg.style.color = "#b00020";
      }
    }
  });
}

bootstrap().catch(err => console.error('[bootstrap]', err));