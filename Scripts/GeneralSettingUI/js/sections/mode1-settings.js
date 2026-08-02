// js/sections/model-settings.js
import { byId, setVal, setText } from "../core/dom.js";
import { t } from "../core/i18n.js";

const selLabel = (id, name) => {
  setText(id, t("msg.selected", { name }) || `選択中: ${name}`);
  byId(id)?.classList.add("selected");
};
const unselLabel = (id) => {
  setText(id, t("status.unselected") || "(未選択)");
  byId(id)?.classList.remove("selected");
};

export class ModelSettings {
  init(store) {
    this.store = store;

    const modeSelect = byId("modeSelect");
    
    this.toggleModePanels = () => {
      const selectedMode = modeSelect?.value || "mode1";
      for (let i = 1; i <= 5; i++) {
        const panel = byId(`panel_mode${i}`);
        if (panel) {
          const targetDisplay = (i === parseInt(selectedMode.replace("mode", ""))) ? "block" : "none";
          if (panel.style.display !== targetDisplay) {
            panel.style.display = targetDisplay;
          }
        }
      }
    };

    if (modeSelect) {
      modeSelect.addEventListener("change", this.toggleModePanels);
    }

    // ---- 推力履歴データのファイル選択をバインド ----
    const pickThrustBtn = byId("pickThrustBtn");
    if (pickThrustBtn) {
      pickThrustBtn.addEventListener("click", async (e) => {
        if (e.target.disabled) return;
        e.target.disabled = true;

        try {
          if (!window.pywebview?.api) return;
          const abs = await window.pywebview.api.open_file(
            [{ description: "Data", extensions: ["xlsx", "csv", "txt"] }], false
          );
          if (!abs) return;
          
          const fname = abs.split(/[\\/]/).pop();
          const dir = abs.slice(0, -(fname.length + 1));
          
          selLabel("thrust_fn_label", fname);
          this.store.apply({ thrust: { fn: fname, path: dir } });
        } catch (err) {
          console.error(err);
        } finally {
          e.target.disabled = false;
        }
      });
    }

    this.toggleModePanels();
  }

  applyDefaults() {
    unselLabel("thrust_fn_label");
    const s = this.store.get();

    setVal("modeSelect", s.modeSelect || "mode1");
    
    if (typeof this.toggleModePanels === "function") {
      this.toggleModePanels();
    }

    if (s.thrust?.fn) {
      selLabel("thrust_fn_label", s.thrust.fn);
    }

    setVal("noiseremoved", s.noiseremoved || "No");
    setVal("spikecut",     s.spikecut     || "No");
    setVal("csvout",       s.csvout       || "Yes");
    setVal("calc_residual_time", s.residual_time || "Yes");

    // 保存されていた execution_mode をラジオボタンに反映
    // const s = this.store.get();
    const execMode = s.execution_mode || "1";
    const radio = document.querySelector(`input[name="execution_mode"][value="${execMode}"]`);
    if (radio) radio.checked = true;
  }

  collectPayload() {
    const s = this.store.get();

    // 現在選択されているラジオボタンの値を取得
    const checkedRadio = document.querySelector('input[name="execution_mode"]:checked');
    const executionMode = checkedRadio ? checkedRadio.value : "1";

    return {
      modeSelect:   byId("modeSelect")?.value || "mode1",
      thrust:       { fn: s.thrust?.fn ?? "", path: s.thrust?.path ?? "" },
      noiseremoved: byId("noiseremoved")?.value || "No",
      spikecut:     byId("spikecut")?.value || "No",
      csvout:       byId("csvout")?.value || "Yes",
      residual_time: byId("calc_residual_time")?.value || "Yes",
      execution_mode: executionMode, // 実行モードの値を追加
    };
  }

  checkValidity(payload) {
    const errs = [];
    if (payload.modeSelect === "mode1" && !payload.thrust?.fn) {
      errs.push("推力履歴データを選択してください。");
    }
    return errs;
  }
}