// js/sections/mode4-settings.js
import { byId, setVal } from "../core/dom.js";

export class Mode4Settings {
  init(store) {
    this.store = store;

    // ファイル選択ボタンのイベント登録
    const pickBtn = byId("m4_pick_thrust_btn");
    pickBtn?.addEventListener("click", async () => {
      try {
        if (!window.pywebview?.api) return;
        const abs = await window.pywebview.api.open_file(
          [{ description: "Excel Data", extensions: ["xlsx"] }], false
        );
        if (!abs) return;

        const fname = abs.split(/[\\/]/).pop();
        const dir = abs.slice(0, -(fname.length + 1));

        // ストアに選択されたファイルを保存
        this.store.apply({
          m4_thrust_file_select: { fn: fname, path: dir }
        });
        this.updateFileLabel();
      } catch (err) {
        console.error(err);
      }
    });

    this.updateFileLabel();
  }

  // ファイル名ラベルの表示を更新
  updateFileLabel() {
    const s = this.store?.get() || {};
    const fileObj = s.m4_thrust_file_select;
    const label = byId("m4_thrust_fn_label");
    if (label) {
      if (fileObj && fileObj.fn) {
        label.innerHTML = `<span style="color: #28a745;">✔</span> <strong>${fileObj.fn}</strong>`;
      } else {
        label.textContent = "(未選択)";
      }
    }
  }

  applyDefaults() {
    setVal("m4_engine_select", "j-2i");
    setVal("m4_oxidant_select", "N2O");
    setVal("m4_fuel_select", "PP");
    setVal("m4_spikecut", "Yes");
    this.store?.apply({ m4_thrust_file_select: { fn: "", path: "" } });
    this.updateFileLabel();
  }

  collectPayload() {
    const s = this.store?.get() || {};
    return {
      m4_engine_select: byId("m4_engine_select")?.value || "j-2i",
      m4_oxidant_select: byId("m4_oxidant_select")?.value || "N2O",
      m4_fuel_select: byId("m4_fuel_select")?.value || "PP",
      spikecut: byId("m4_spikecut")?.value || "Yes",
      // モード1などと同様に { fn, path } のオブジェクト構造で保存
      m4_thrust_file_select: s.m4_thrust_file_select || { fn: "", path: "" }
    };
  }

  apply(data) {
    if (!data) return;
    setVal("m4_engine_select", data.m4_engine_select ?? "j-2i");
    setVal("m4_oxidant_select", data.m4_oxidant_select ?? "N2O");
    setVal("m4_fuel_select", data.m4_fuel_select ?? "PP");
    setVal("m4_spikecut", data.spikecut ?? "Yes");

    if (data.m4_thrust_file_select) {
      this.store?.apply({ m4_thrust_file_select: data.m4_thrust_file_select });
    }
    this.updateFileLabel();
  }

  checkValidity(payload) {
    const errs = [];
    return errs;
  }
}