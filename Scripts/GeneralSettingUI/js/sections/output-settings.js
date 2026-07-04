
// js/sections/output-settings.js
import { byId, setVal, setText, inEnum, isNonEmptyStr } from "../core/dom.js";
import { t } from "../core/i18n.js";

const unselLabel = (id) => {
  setText(id, t("status.unselected"));
  byId(id)?.classList.remove("selected");
};

const FIG_IDS = [
  { id: "fig_FlightPath",     value: "FlightPath" },
  { id: "fig_KML_FlightPath", value: "KML of FlightPath" },
  { id: "fig_FallPoint",      value: "FallPoint" },
  { id: "fig_KML_FallPoint",  value: "KML of FallPoint" },
  { id: "fig_AttitudeMP4",    value: "Attitude MP4" },
  { id: "fig_WindGraph",      value: "Wind Graph" },
  { id: "fig_WindCSV",        value: "Wind CSV" },
];

export class OutputSettings {
  init(store) {
    this.store = store;

    const toggleManual = () => {
      const manual = (byId("mode_export")?.value === "Manual");
      const dirRow = byId("resultDirRow");
      if (dirRow) dirRow.style.display = manual ? "" : "none";
      if (!manual) unselLabel("result_path_label");
    };

    byId("mode_export")?.addEventListener("change", toggleManual);

    // ディレクトリ選択（絶対パス）
    byId("pickResultDirBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_dir();
      if (!abs) return;
      const lbl = byId("result_path_label");
      if (lbl) { setText("result_path_label", t("msg.selected", { name: abs })); lbl.classList.add("selected"); }
      const s = this.store.get();
      s.result_path = abs;
      this.store.apply({ result_path: s.result_path });
    });

    // 図選択チェックボックス
    for (const { id } of FIG_IDS) {
      byId(id)?.addEventListener("change", () => {
        this.store.apply({ list_fig: this._collectListFig() });
      });
    }
  }

  _collectListFig() {
    return FIG_IDS
      .filter(({ id }) => byId(id)?.checked)
      .map(({ value }) => value);
  }

  applyDefaults() {
    const s = this.store.get();
    setVal("mode_export", s.mode_export ?? "Default");
    setVal("output", s.output ?? "None");
    unselLabel("result_path_label"); // 読込時は反映しない

    // 図チェックボックスの初期化
    const listFig = Array.isArray(s.list_fig) ? s.list_fig : [];
    for (const { id, value } of FIG_IDS) {
      const el = byId(id);
      if (el) el.checked = listFig.includes(value);
    }

    const evt = new Event("change");
    byId("mode_export").dispatchEvent(evt);
  }

  collectPayload() {
    const s = this.store.get();
    const mode_export = byId("mode_export").value || "Default";
    const output      = byId("output").value      || "None";
    const result_path = s.result_path ?? "";
    const list_fig    = this._collectListFig();

    const payload = { mode_export, output, result_path, list_fig };
    this.store.apply(payload);
    return payload;
  }

  checkValidity(payload) {
    const errs = [];
    const { mode_export, output } = payload;
    const ME = ["Default", "Manual"];
    if (!inEnum(mode_export, ME)) errs.push(t("err.modeexport"));
    if (!isNonEmptyStr(output)) errs.push(t("err.output"));
    return errs;
  }
}
