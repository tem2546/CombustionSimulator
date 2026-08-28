// js/sections/output-settings.js
import { byId, setVal, setText } from "../core/dom.js";
import { t } from "../core/i18n.js";

const selLabel = (id, name) => {
  setText(id, name);
  byId(id)?.classList.add("selected");
};
const unselLabel = (id) => {
  setText(id, t("status.unselected") || "(未選択)");
  byId(id)?.classList.remove("selected");
};

export class OutputSettings {
  init(store) {
    this.store = store;

    const modeSelect = byId("outputModeSelect");
    
    this.toggleOutputRow = () => {
      const currentVal = modeSelect ? modeSelect.value : "auto";
      const isManual = (currentVal === "manual");
      const row = byId("manual_path_row");
      if (row) {
        row.style.display = isManual ? "block" : "none";
      }
    };

    if (modeSelect) {
      modeSelect.addEventListener("change", this.toggleOutputRow);
    }

    // ---- 【重要】保存先フォルダ選択を確実にバインド ----
    const pickBtn = byId("pickDirBtn");
    if (pickBtn) {
      pickBtn.addEventListener("click", async (e) => {
        if (e.target.disabled) return;
        e.target.disabled = true;

        try {
          if (!window.pywebview?.api) return;
          
          // Python側のフォルダ選択を開く
          const absDir = await window.pywebview.api.open_dir();
          if (!absDir) return;

          selLabel("result_path_label", absDir);
          this.store.apply({ result_path: absDir });
        } catch (err) {
          console.error(err);
        } finally {
          e.target.disabled = false;
        }
      });
    }

    this.toggleOutputRow();
  }

  applyDefaults() {
    unselLabel("result_path_label");
    const s = this.store.get();

    setVal("outputModeSelect", s.outputModeSelect || "auto");
    
    if (typeof this.toggleOutputRow === "function") {
      this.toggleOutputRow();
    }

    if (s.result_path) {
      selLabel("result_path_label", s.result_path);
    }
  }

  collectPayload() {
    const s = this.store.get();
    const modeSelect = byId("outputModeSelect");
    const isManual = modeSelect ? (modeSelect.value === "manual") : false;
    
    return {
      outputModeSelect: modeSelect ? modeSelect.value : "auto",
      result_path: isManual ? (s.result_path || "") : ""
    };
  }

  checkValidity(payload) {
    const errs = [];
    if (payload.outputModeSelect === "manual" && !payload.result_path) {
      errs.push("出力先ディレクトリを指定してください。");
    }
    return errs;
  }
}