// js/sections/mode4-settings.js
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

export class Mode4Settings {
  init(store) {
    this.store = store;

    // ファイル選択ボタンのイベント登録
    const pickBtn = byId("m4_pick_thrust_btn");
    pickBtn?.addEventListener("click", async (e) => {
      if (e.target.disabled) return;
      e.target.disabled = true;

      try {
        if (!window.pywebview?.api) return;
        const abs = await window.pywebview.api.open_file(
          { file_types: [`Excel Data (*.xlsx)`, `All files (*.*)`] }
        );
        if (!abs) return;

        const fname = abs.split(/[\\/]/).pop();
        const dir = abs.slice(0, -(fname.length + 1));

        setLabel("m4_thrust_fn_label", fname);
        this.store.apply({ m4_thrust: { fn: fname, path: dir } });
      } catch (err) {
        console.error(err);
      } finally {
        e.target.disabled = false;
      }
    });
  }

  collectPayload() {
    const s = this.store.get();
    return {
      m4_engine_select: getVal("m4_engine_select") || "j-2i",
      m4_oxidant_select: getVal("m4_oxidant_select") || "N2O",
      m4_fuel_select: getVal("m4_fuel_select") || "PP",
      m4_spikecut: getVal("m4_spikecut") || "Yes",
      m4_thrust_file_select: s.m4_thrust || { fn: "", path: "" }
    };
  }

  apply(data) {
    if (!data) return;
    unsetLabel("m4_thrust_fn_label");
    setVal("m4_engine_select", data.m4_engine_select ?? "j-2i");
    setVal("m4_oxidant_select", data.m4_oxidant_select ?? "N2O");
    setVal("m4_fuel_select", data.m4_fuel_select ?? "PP");
    setVal("m4_spikecut", data.m4_spikecut ?? "Yes");

    if (data.m4_thrust?.fn) {
      this.store?.apply({ m4_thrust: data.m4_thrust });
      setLabel("m4_thrust_fn_label", data.m4_thrust.fn || "");
    }
  }

  checkValidity(payload) {
    const errs = [];
    return errs;
  }
}