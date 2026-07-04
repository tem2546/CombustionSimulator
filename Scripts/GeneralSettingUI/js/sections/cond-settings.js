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

    const applyWindEnableState = () => {
      const wm = this.wind_model?.value ?? "PowerLaw";
      const enable = (wm === "PowerLaw");

      const ids = [
        "vw0_min", "vw0_max", "vw0_step",
        "wpsi_min", "wpsi_max", "wpsi_step",
      ];

      ids.forEach(id => {
        const el = byId(id);
        if (el) el.disabled = !enable;
      });
    };

    // ---- FallPoint 設定ファイルの選択 ----
    byId("pickFPBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_file(
        [{ description: "FallPoint bundle", extensions: ["mat", "xlsx", "json"] }],
        false
      );
      if (!abs) return;
      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));
      selLabel("fp_fn_label", fname);
      const s = this.store.get();
      s.fp = { fn: fname, path: dir };
      this.store.apply({ fp: s.fp });
    });

    // ---- 風モデル切替（MSM/CSV 行の表示制御）----
    this.wind_model = byId("wind_model");
    const toggleWindModelRows = () => {
      const wm = this.wind_model?.value ?? "PowerLaw";
      const isMSM = wm === "MSM";
      const isCSV = wm === "csv";
      byId("msm_file_row").style.display = isMSM ? "grid" : "none";
      byId("csv_file_row").style.display = isCSV ? "grid" : "none";
      if (!isMSM) { const x = byId("msm_fn_label"); if (x) x.value = ""; }
      if (!isCSV) { const x = byId("windcsv_fn_label"); if (x) x.value = ""; }
      applyWindEnableState();
    };
    this.wind_model?.addEventListener("change", toggleWindModelRows);

    // ---- MSM / CSV ファイルピッカー ----
    byId("pickMsmBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_file(
        [{ description: "NetCDF", extensions: ["nc"] }], false
      );
      if (!abs) return;
      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));
      selLabel("msm_fn_label", fname);
      const s = this.store.get();
      s.MSM = { fn: fname, path: dir };
      this.store.apply({ MSM: s.MSM });
    });

    byId("pickCsvBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_file(
        [{ description: "CSV/Excel", extensions: ["csv", "xlsx"] }], false
      );
      if (!abs) return;
      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));
      selLabel("windcsv_fn_label", fname);
      const s = this.store.get();
      s.wind_csv = { fn: fname, path: dir };
      this.store.apply({ wind_csv: s.wind_csv });
    });

    // ---- 範囲入力（min/max/step） ----
    this.elev_min  = byId("elev_min");
    this.elev_max  = byId("elev_max");
    this.elev_step = byId("elev_step");
    this.vw0_min   = byId("vw0_min");
    this.vw0_max   = byId("vw0_max");
    this.vw0_step  = byId("vw0_step");
    this.wpsi_min  = byId("wpsi_min");
    this.wpsi_max  = byId("wpsi_max");
    this.wpsi_step = byId("wpsi_step");

    // ---- その他の項目 ----
    this.t_max        = byId("t_max");
    this.rate_hz      = byId("rate_hz");
    this.mode_landing = byId("mode_landing");
    this.base_azm     = byId("base_azm");
    this.mode_angle   = byId("mode_angle");

    // 初期の行表示
    toggleWindModelRows();
  }

  applyDefaults() {
    const s = this.store.get();

    // elev / Vw0 / Wpsi は [min,max,step] を期待（未定義なら既定値へ）
    const elev = this._normSet(s.elev, [80, 80, 1]);
    const Vw0  = this._normSet(s.Vw0,  [ 1,  1, 1]);
    const Wpsi = this._normSet(s.Wpsi, [ 0,  0, 1]);

    this._fillSetInputs(this.elev_min, this.elev_max, this.elev_step, elev, 0, 90, 1);
    this._fillSetInputs(this.vw0_min,  this.vw0_max,  this.vw0_step,  Vw0,  0, undefined, 1);
    this._fillSetInputs(this.wpsi_min, this.wpsi_max, this.wpsi_step, Wpsi, 0, 360, 1);

    // その他（store の値をそのまま反映）
    setVal("t_max", s.t_max ?? 60);
    setVal("rate_hz", 1 / (s.dt ?? 1 / 1000));
    setVal("wind_model", s.wind_model ?? "PowerLaw");
    setVal("mode_landing", s.mode_landing ?? "Hard");
    setVal("base_azm", s.base_azm ?? "MN");
    setVal("mode_angle", s.mode_angle ?? "CCW");

    // 付随ファイルのラベル/入力
    ["fp_fn_label", "msm_fn_label", "windcsv_fn_label"].forEach((id) => {
      setText(id, t("status.unselected"));
      byId(id)?.classList.remove("selected");
    });
    if (s.MSM?.fn && byId("msm_fn_label")) {
      selLabel("msm_fn_label", s.MSM.fn);
    }
    if (s.wind_csv?.fn && byId("windcsv_fn_label")) {
      selLabel("windcsv_fn_label", s.wind_csv.fn);
    }
    if (s.fp?.fn) {
      selLabel("fp_fn_label", s.fp.fn);
    }

    byId("wind_model")?.dispatchEvent(new Event("change"));

  }

  collectPayload() {
    const elev = this._readSet(this.elev_min, this.elev_max, this.elev_step);
    const Vw0  = this._readSet(this.vw0_min,  this.vw0_max,  this.vw0_step);
    const Wpsi = this._readSet(this.wpsi_min, this.wpsi_max, this.wpsi_step);

    const wm   = this.wind_model?.value || "PowerLaw";
    const ml   = this.mode_landing?.value || "Hard";
    const tmax = Number(this.t_max?.value);
    const rate = Number(this.rate_hz?.value);
    const dt   = (!Number.isFinite(rate) || rate <= 0) ? NaN : 1 / rate;
    const base = this.base_azm?.value || "MN";
    const ang  = this.mode_angle?.value || "CW";

    const s = this.store.get();

    return {
      elev, Vw0, Wpsi,
      wind_model:  wm,
      mode_landing: ml,
      t_max:       tmax,
      dt:          dt,
      base_azm:    base,
      mode_angle:  ang,
      fp:       { fn: s.fp?.fn ?? "",       path: s.fp?.path ?? "" },
      MSM:      { fn: s.MSM?.fn ?? "",      path: s.MSM?.path ?? "" },
      wind_csv: { fn: s.wind_csv?.fn ?? "", path: s.wind_csv?.path ?? "" },
    };
  }

  checkValidity(payload) {
    const errs = [];
    const { elev, Vw0, Wpsi, t_max, dt, wind_model, mode_landing, base_azm, mode_angle, MSM, wind_csv, fp} = payload;

    this._checkSet("err.label.elev", elev, errs, { min: 0, max: 90 });
    this._checkSet("err.label.vw0",  Vw0,  errs, { min: 0 });
    this._checkSet("err.label.wpsi", Wpsi, errs, { min: 0, max: 360, wrap360: true });

    if (!Number.isFinite(t_max) || t_max <= 0) errs.push(t("err.tmax"));
    if (!Number.isFinite(dt)    || dt    <= 0) errs.push(t("err.rate"));

    if (!fp?.fn) errs.push(t("err.fp"));

    const WM = ["PowerLaw", "MSM", "csv"];
    const ML = ["Hard", "Descent", "Both"];
    const BA = ["ME", "MN", "MS", "MW", "TE", "TN", "TS", "TW"];
    const MA = ["CW", "CCW"];
    if (!WM.includes(wind_model))   errs.push(t("err.wind"));
    if (!ML.includes(mode_landing)) errs.push(t("err.landing"));
    if (!BA.includes(base_azm))     errs.push(t("err.base"));
    if (!MA.includes(mode_angle))   errs.push(t("err.angle"));

    if (wind_model === "MSM" && !(MSM?.fn))      errs.push(t("err.msm"));
    if (wind_model === "csv" && !(wind_csv?.fn)) errs.push(t("err.windcsv"));

    return errs;
  }

  // ---------- helpers ----------
  _normSet(arr, fallback) {
    // 数値3要素の配列なら採用、そうでなければフォールバック
    if (Array.isArray(arr) && arr.length >= 3) {
      const v = [Number(arr[0]), Number(arr[1]), Number(arr[2])];
      if (v.every(Number.isFinite)) return v;
    }
    return [...fallback];
  }

  _fillSetInputs(iMin, iMax, iStep, set, hardMin, hardMax, stepDef) {
    const [mn, mx, st] = set;
    iMin.value  = Number.isFinite(mn) ? mn : (hardMin ?? 0);
    iMax.value  = Number.isFinite(mx) ? mx : (hardMax ?? iMin.value);
    iStep.value = Number.isFinite(st) ? st : (stepDef ?? 1);
  }

  _readSet(iMin, iMax, iStep) {
    return [Number(iMin?.value), Number(iMax?.value), Number(iStep?.value)];
  }

  _checkSet(labelKey, arr, errs, opts = {}) {
    const label = t(labelKey);
    const [mn, mx, st] = Array.isArray(arr) ? arr : [NaN, NaN, NaN];
    if (![mn, mx, st].every(Number.isFinite)) { errs.push(t("err.set.nan", { label })); return; }
    if (st <= 0) errs.push(t("err.set.step", { label }));
    if (mx < mn) errs.push(t("err.set.maxmin", { label }));
    if (opts.min !== undefined && mn < opts.min) errs.push(t("err.set.min", { label, v: opts.min }));
    if (opts.max !== undefined && mx > opts.max) errs.push(t("err.set.max", { label, v: opts.max }));
  }
}
