// js/sections/model-settings.js
import { byId, setVal, getVal, setText } from "../core/dom.js";
import { t } from "../core/i18n.js";

const setLabel = (id, name) => {
  setText(id, t("msg.selected", { name }) || `選択中: ${name}`);
  byId(id)?.classList.add("selected");
};
const unsetLabel = (id) => {
  setText(id, t("status.unselected") || "(未選択)");
  byId(id)?.classList.remove("selected");
};

export class Mode1Settings {
  init(store) {
    this.store = store;

    // ---- 推力履歴データのファイル選択をバインド ----
    const pickThrustBtn = byId("pickThrustBtn");
    pickThrustBtn.addEventListener("click", async (e) => {
      if (e.target.disabled) return;
      e.target.disabled = true;

      try {
        if (!window.pywebview?.api) return;
        const abs = await window.pywebview.api.open_file(
          { file_types: [`Excel Types (*.xlsx;*.csv;*.txt)`, `All files (*.*)`] }
        );
        if (!abs) return;
        
        const fname = abs.split(/[\\/]/).pop();
        const dir = abs.slice(0, -(fname.length + 1));
        
        setLabel("thrust_fn_label", fname);
        this.store.apply({ m1_thrust: { fn: fname, path: dir } });
      } catch (err) {
        console.error(err);
      } finally {
        e.target.disabled = false;
      }
    });
  }
  
  apply(data) {
    unsetLabel("thrust_fn_label");
    setVal("noiseremoved", data.m1_noiseremoved ?? "No");
    setVal("spikecut", data.m1_spikecut ?? "No");
    setVal("csvout", data.m1_csvout ?? "Yes");
    setVal("calc_residual_time", data.m1_calc_residual_time ?? "Yes");
  
    if (data.m1_thrust?.fn) {
      setLabel("thrust_fn_label", data.m1_thrust.fn);
    }
  }

  collectPayload() {
    const s = this.store.get();

    // 現在選択されているラジオボタンの値を取得
    return {
      thrust:       s.m1_thrust || { fn: "", path: "" },
      noiseremoved: getVal("noiseremoved") || "No",
      spikecut:     getVal("spikecut") || "No",
      csvout:       getVal("csvout") || "Yes",
      residual_time: getVal("calc_residual_time") || "Yes",
    };
  }

  checkValidity(payload) {
    const errs = [];
    if (payload.modeSelect === "1" && !payload.thrust?.fn) {
      errs.push("推力履歴データを選択してください。");
    }
    return errs;
  }
}