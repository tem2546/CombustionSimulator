// js/sections/cond-settings.js
import { byId, setVal, setText } from "../core/dom.js";
import { t } from "../core/i18n.js";

// ファイル選択ラベルを「選択中: …」表示（緑）に更新するヘルパ
const selLabel = (id, name) => {
  setText(id, t("msg.selected", { name }));
  byId(id)?.classList.add("selected");
};

export class CondSettings {
  init(store) {
    this.store = store;

    // ---- FallPoint (処理対象データ) 設定ファイルの選択 ----
    byId("pickFPBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_file(
        [{ description: "Data File", extensions: ["mat", "xlsx", "json", "csv"] }],
        false
      );
      if (!abs) return;
      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));
      selLabel("fp_fn_label", fname);
      
      this.store.apply({ fp: { fn: fname, path: dir } });
    });

    // ---- 風モデル切替（CSV 行の表示制御のみ残す、MSMは廃止）----
    this.wind_model = byId("wind_model");
    const toggleWindModelRows = () => {
      const wm = this.wind_model?.value || "PowerLaw";
      const isCSV = wm === "csv";
      
      // UI行の表示切り替え
      const csvRow = byId("csv_file_row");
      if (csvRow) csvRow.style.display = isCSV ? "grid" : "none";
      
      if (!isCSV) {
        const x = byId("windcsv_fn_label");
        if (x) x.value = "";
      }
    };
    this.wind_model?.addEventListener("change", toggleWindModelRows);

    // ---- CSV 風データファイルピッカー ----
    byId("pickCsvBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_file(
        [{ description: "CSV/Excel", extensions: ["csv", "xlsx"] }], false
      );
      if (!abs) return;
      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));
      selLabel("windcsv_fn_label", fname);
      
      this.store.apply({ wind_csv: { fn: fname, path: dir } });
    });

    // ---- 単一値入力フィールドのバインド ----
    this.elev = byId("elev");
    this.vw0  = byId("vw0");
    this.wpsi = byId("wpsi");

    // 初期の表示制御を実行
    toggleWindModelRows();
  }

  applyDefaults() {
    const s = this.store.get();

    // 単一の数値をUIへマッピング
    setVal("elev", s.elev ?? 80);
    setVal("vw0",  s.Vw0  ?? 1);
    setVal("wpsi", s.Wpsi ?? 0);
    setVal("wind_model", s.wind_model ?? "PowerLaw");

    // ファイルラベルの初期化
    ["fp_fn_label", "windcsv_fn_label"].forEach((id) => {
      setText(id, t("status.unselected"));
      byId(id)?.classList.remove("selected");
    });

    if (s.wind_csv?.fn && byId("windcsv_fn_label")) {
      selLabel("windcsv_fn_label", s.wind_csv.fn);
    }
    if (s.fp?.fn) {
      selLabel("fp_fn_label", s.fp.fn);
    }

    this.wind_model?.dispatchEvent(new Event("change"));
  }

  collectPayload() {
    const wm = this.wind_model?.value || "PowerLaw";
    const s = this.store.get();

    return {
      elev:       Number(this.elev?.value ?? 80),
      Vw0:        Number(this.vw0?.value ?? 1),
      Wpsi:       Number(this.wpsi?.value ?? 0),
      wind_model: wm,
      fp:         { fn: s.fp?.fn ?? "",       path: s.fp?.path ?? "" },
      wind_csv:   { fn: s.wind_csv?.fn ?? "", path: s.wind_csv?.path ?? "" },
    };
  }

  checkValidity(payload) {
    const errs = [];
    const { elev, Vw0, Wpsi, wind_model, wind_csv, fp } = payload;

    // 数値バリデーション (単一値)
    if (!Number.isFinite(elev) || elev < 0 || elev > 90)  errs.push(t("err.elev_range") || "Elevは0〜90の範囲で入力してください。");
    if (!Number.isFinite(Vw0)  || Vw0 < 0)                errs.push(t("err.vw0_range")  || "Vw0は0以上で入力してください。");
    if (!Number.isFinite(Wpsi) || Wpsi < 0 || Wpsi > 360) errs.push(t("err.wpsi_range") || "Wpsiは0〜360の範囲で入力してください。");

    // 必須ファイルバリデーション
    if (!fp?.fn) errs.push(t("err.fp"));

    const WM = ["PowerLaw", "csv"];
    if (!WM.includes(wind_model)) errs.push(t("err.wind"));

    if (wind_model === "csv" && !wind_csv?.fn) {
      errs.push(t("err.windcsv"));
    }

    return errs;
  }
}