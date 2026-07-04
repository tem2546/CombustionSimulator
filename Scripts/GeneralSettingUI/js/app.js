// js/app.js
import { byId } from "./core/dom.js";
import { SettingsStore } from "./core/store.js";
import { ModelSettings } from "./sections/model-settings.js";
import { CondSettings } from "./sections/cond-settings.js";
import { RollSettings } from "./sections/roll-settings.js";
import { OutputSettings } from "./sections/output-settings.js";
import { initLang, toggleLang } from "./core/i18n.js";
import { Mode2Settings } from "./sections/mode2-settings.js";

const FILE_KEYS = ["thrust"];

const store  = new SettingsStore();
const model  = new ModelSettings();
const cond   = new CondSettings();
const roll   = new RollSettings();
const output = new OutputSettings();
const mode2  = new Mode2Settings();

function sanitizeFileFields(data) {
  const cleaned = { ...data };
  for (const k of FILE_KEYS) {
    if (cleaned[k]) cleaned[k] = { ...(cleaned[k] ?? {}), fn: "", path: "" };
  }
  return cleaned;
}

function safeApplyDefaults(sec) {
  if (typeof sec?.applyDefaults === "function") sec.applyDefaults();
}
function safeCollectPayload(sec) {
  return typeof sec?.collectPayload === "function" ? sec.collectPayload() ?? {} : {};
}
function safeCheckValidity(sec, payload) {
  return typeof sec?.checkValidity === "function" ? sec.checkValidity(payload) ?? [] : [];
}

function refreshAllSectionUi() {
  requestAnimationFrame(() => {
    const sections = [model, mode2, cond, roll, output];
    for (const sec of sections) {
      safeApplyDefaults(sec);
    }
  });
}

// ---- PythonのAPIが存在するかどうかを定期チェックする安全な関数 ----
function whenPywebviewReady() {
  return new Promise((resolve) => {
    if (window.pywebview && window.pywebview.api) {
      resolve();
      return;
    }
    const timer = setInterval(() => {
      if (window.pywebview && window.pywebview.api) {
        clearInterval(timer);
        resolve();
      }
    }, 10);
  });
}

async function bootstrap() {
  // 1. まずAPIの出現を待つ
  await whenPywebviewReady();

  // 2. 各セクションの初期化処理
  const sections = [model, mode2, cond, roll, output];
  for (const sec of sections) {
    if (typeof sec?.init === "function") sec.init(store);
  }

  initLang();
  
  const langBtn = byId("langToggle");
  if (langBtn) {
    langBtn.addEventListener("click", toggleLang);
  }

  store.resetToDefaults();
  refreshAllSectionUi();

  // 3. 完全に準備が整ったので上部ツールバーのロックを解除
  const targetButtons = ["loadBtn", "loadPreBtn", "saveBtn", "saveAsBtn", "openFileBtn"];
  targetButtons.forEach(id => {
    const btn = byId(id);
    if (btn) btn.disabled = false;
  });

  // ---- 連打ガード用関数 ----
  const withLock = (btnId, callback) => {
    const btn = byId(btnId);
    return async () => {
      if (!btn || btn.disabled) return;
      btn.disabled = true;
      try {
        await callback();
      } catch (err) {
        console.error(err);
      } finally {
        btn.disabled = false;
      }
    };
  };

  // ==========================================
  // 1. 初期値を読み込む
  // ==========================================
  byId("loadBtn")?.addEventListener("click", withLock("loadBtn", async () => {
    const res = await window.pywebview.api.load_settings("settings.json");
    if (!res?.ok) return;
    store.apply(sanitizeFileFields(res.data ?? {}));
    refreshAllSectionUi();
  }));

  // ==========================================
  // 2. 前回設定を読み込み
  // ==========================================
  byId("loadPreBtn")?.addEventListener("click", withLock("loadPreBtn", async () => {
    const res = await window.pywebview.api.load_presettings();
    if (!res?.ok) return;
    store.apply(res.data ?? {});
    refreshAllSectionUi();
  }));

  // ==========================================
  // 3. 現在の設定を保存して終了
  // ==========================================
  byId("saveBtn")?.addEventListener("click", withLock("saveBtn", async () => {
    const payload = { 
      ...safeCollectPayload(model),
      ...safeCollectPayload(mode2),
      ...safeCollectPayload(output)
    };
    
    const errs = [
      ...safeCheckValidity(model, payload),
      ...safeCheckValidity(mode2, payload),
      ...safeCheckValidity(output, payload)
    ];

    if (errs.length) {
      const msg = byId("msg");
      if (msg) msg.textContent = "エラー: " + errs.join(" / ");
      return;
    }
    await window.pywebview.api.save_settings(payload, "settings.json");
  }));

  // ==========================================
  // 4. 名前を付けて保存
  // ==========================================
  byId("saveAsBtn")?.addEventListener("click", withLock("saveAsBtn", async () => {
    const payload = { 
      ...safeCollectPayload(model),
      ...safeCollectPayload(mode2),
      ...safeCollectPayload(output)
    };
    
    const errs = [
      ...safeCheckValidity(model, payload),
      ...safeCheckValidity(mode2, payload),
      ...safeCheckValidity(output, payload)
    ];

    if (errs.length) {
      const msg = byId("msg");
      if (msg) msg.textContent = "エラー: " + errs.join(" / ");
      return;
    }
    await window.pywebview.api.save_settings_as(payload, "settings.json");
  }));

  // ==========================================
  // 5. 設定ファイルを開く
  // ==========================================
  byId("openFileBtn")?.addEventListener("click", withLock("openFileBtn", async () => {
    const res = await window.pywebview.api.load_settings_from();
    if (!res?.ok) return;
    store.apply(sanitizeFileFields(res.data ?? {}));
    refreshAllSectionUi();
  }));
}

bootstrap().catch(err => console.error(err));