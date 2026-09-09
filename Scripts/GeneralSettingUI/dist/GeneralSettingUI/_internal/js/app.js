import { byId } from "./core/dom.js";
import { SettingsStore } from "./core/store.js";
import { Mode1Settings } from "./sections/mode1-settings.js";
import { Mode2Settings } from "./sections/mode2-settings.js";
import { Mode3Settings } from "./sections/mode3-settings.js";
import { Mode4Settings } from "./sections/mode4-settings.js";
import { Mode5Settings } from "./sections/mode5-settings.js";
import { OutputSettings } from "./sections/output-settings.js";

import { initLang, toggleLang } from "./core/i18n.js";

const store  = new SettingsStore();
const mode1  = new Mode1Settings();
const mode2  = new Mode2Settings();
const mode3  = new Mode3Settings();
const mode4  = new Mode4Settings();
const mode5  = new Mode5Settings();
const output = new OutputSettings();
const modeSections = [mode1, mode2, mode3, mode4, mode5];
const allSections = [...modeSections, output];

const panelModeSelector = byId("modeSelect");
const allModes = [byId("panel_mode1"), byId("panel_mode2"), byId("panel_mode3"), byId("panel_mode4"), byId("panel_mode5")];

// pywebviewのAPIが利用可能になるまで待つ関数
function whenPywebviewReady() {
    if (window.pywebview?.api) return Promise.resolve();

    return new Promise((resolve, reject) => {
        const startedAt = Date.now();
        const checkReady = () => {
            if (window.pywebview?.api) {
                resolve();
                return;
            }
            if (Date.now() - startedAt >= 10000) {
                reject(new Error("pywebview API did not become ready"));
                return;
            }
            window.setTimeout(checkReady, 50);
        };

        window.addEventListener("py-ready", checkReady, { once: true });
        checkReady();
    });
}

// 収集したデータをまとめて返す関数
function collectSelectedPayload() {
    const selectedMode = Number.parseInt(panelModeSelector.value);
    if(selectedMode < 1 || selectedMode > modeSections.length) {
        alert("モードを選択してください");
        return output.collectPayload();
    }

    const errs = [ 
        ...modeSections[selectedMode - 1].checkValidity(store.get()),
        ...output.checkValidity(store.get())
    ];
    if (errs.length > 0) {
        return { cancelled: true, errors: errs };
    }

    return {
        cancelled: false,
        modeSelect: selectedMode.toString(),
        execution_mode: selectedMode.toString(),
        ...modeSections[selectedMode - 1].collectPayload(),
        ...output.collectPayload()
    };
}

// 外部からデータを読み込んだときに、各クラスの画面反映メソッド (apply または applyDefaults) を安全に叩く関数
function refreshAllSectionUi() {
    const currentStoreData = store.get();
    requestAnimationFrame(() => allSections.forEach(sec => sec.apply(currentStoreData)));
}

// モード選択が変更されたときの処理
function onModeChange() {
    const mode = panelModeSelector.value;

    allModes.forEach((modeEl, index) => {
        if (modeEl) {
            const isSelected = index + 1 === Number.parseInt(mode, 10);
            modeEl.hidden = !isSelected;
            modeEl.style.display = isSelected ? "block" : "none";
        }
    });
}

async function bootstrap() {
    // ==========================================
    // 1. まずAPIの出現を待つ
    // ==========================================
    await whenPywebviewReady();

    // ==========================================
    // 2. 各セクションの初期化処理
    // ==========================================
    allSections.forEach(sec => sec.init(store));
    refreshAllSectionUi();

    initLang();
    const langBtn = byId("langToggle");
    if (langBtn) {
        langBtn.addEventListener("click", toggleLang);
    }

    // ==========================================
    // 3. 完全に準備が整ったので上部ツールバーのロックを解除
    // ==========================================
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
        store.resetToDefaults();
        refreshAllSectionUi();
        console.info("初期値を読み込みました。");
    }));

    // ==========================================
    // 2. 前回設定を読み込み
    // ==========================================
    byId("loadPreBtn")?.addEventListener("click", withLock("loadPreBtn", async () => {
        const res = await window.pywebview.api.load_settings();
        if (!res?.ok) return;
        store.apply(res.data ?? {});
        refreshAllSectionUi();
        console.info("前回設定を読み込みました。");
    }));

    // ==========================================
    // 3. 現在の設定を保存して終了
    // ==========================================
    byId("saveBtn")?.addEventListener("click", withLock("saveBtn", async () => {
        const payload = collectSelectedPayload();
        if (payload.cancelled) {
            alert("保存処理がキャンセルされました。エラー:", payload.errors);
            return;
        }
        await window.pywebview.api.save_settings(payload, "settings.json");
    }));

    // ==========================================
    // 4. 名前を付けて保存
    // ==========================================
    byId("saveAsBtn")?.addEventListener("click", withLock("saveAsBtn", async () => {
        const payload = collectSelectedPayload();
        if (payload.cancelled) {
            alert("保存処理がキャンセルされました。エラー:", payload.errors);
            return;
        }
        await window.pywebview.api.save_settings_as(payload, "settings.json");
        console.info("設定を保存しました。");
    }));

    // ==========================================
    // 5. 設定ファイルを開く
    // ==========================================
    byId("openFileBtn")?.addEventListener("click", withLock("openFileBtn", async () => {
        const res = await window.pywebview.api.load_settings_from();
        if (!res?.ok) {
            alert("設定ファイルの読み込みに失敗しました。");
            return;
        }
        store.apply(res.data ?? {});
        refreshAllSectionUi();
        console.info("設定ファイルを読み込みました。");
    }));

    // ==========================================
    // 設定するモードの選択が変更されたときの処理
    // ==========================================
    panelModeSelector.addEventListener("change", onModeChange);
}

bootstrap().catch(err => console.error(err));