// js/core/store.js
export class SettingsStore {
  constructor() {
    this.defaults = {
      // ------- Condition / wind / time -------
      // elev / Vw0 / Wpsi は [min,max,step] で統一
      elev: [80, 80, 1],
      Vw0:  [ 1,  1, 1],
      Wpsi: [ 0,  0, 1],

      wind_model:   "PowerLaw",   // "PowerLaw" | "MSM" | "csv"
      mode_landing: "Hard",       // "Hard" | "Descent"
      t_max: 60,
      dt:    1 / 1000,
      base_azm:   "MN",           // ME/MN/MS/MW/TE/TN/TS/TW
      mode_angle: "CCW",          // CW/CCW

      // 風モデル付随ファイル（ファイル名のみ保持。バックエンドが path を補完）
      MSM:      { fn: "", path: "" },
      wind_csv: { fn: "", path: "" },
      fp:       { fn: "", path: "" }, // Fall Point bundle / setting file

      // ------- Model -------
      multi_stage: false,             // true のとき 2段式（param は 3要素配列）
      param:  { fn: "", path: "" },   // Parameter file (.xlsx)。multi_stage=true の時は fn/path とも長さ3の配列
      thrust: { fn: "", path: "" },   // Thrust data (.xlsx/.csv/.txt)
      descent_model: "Vw_model",      // "Vw_model" | "Dynamics"

      // ------- Roll -------
      execute_cont: false,            // false の時は他項目を無効扱い
      control_func: "example",
      simu_mode:    "Launch",         // "Launch" | "Rotational"
      rot_cond:     { Va: 50, z: 200 },
      roll_factor:  "Coefficience",   // "Coefficience" | "Moment"
      Cl0:          0.001,
      Mx_csv:       { fn: "", path: "" },
      // 動翼空力データベース：use=true のとき files[*] のうち use=true のものを v 軸として読み込む
      aero_db: {
        use: false,
        files: [
          { use: false, v: 0, fn: "", path: "" },
          { use: false, v: 0, fn: "", path: "" },
          { use: false, v: 0, fn: "", path: "" },
          { use: false, v: 0, fn: "", path: "" },
          { use: false, v: 0, fn: "", path: "" },
        ],
      },

      // ------- Option -------
      parallel: "No",                 // Yes/No

      // ------- Output -------
      mode_export: "Default",         // "Default" | "Manual"
      result_path: "",
      output: "None",                 // "None" | "vs-time_Logs" | "FeatureValues" etc.
      list_fig: [],                   // 出力する図のリスト
    };
    this.state = structuredClone(this.defaults);
  }

  /** 浅い＋簡易ディープマージ */
  apply(data = {}) {
    // 構造体の部分上書きを許可するキー
    const deepKeys = ["rot_cond", "MSM", "wind_csv", "param", "thrust", "Mx_csv", "fp"];
    const next = { ...this.state, ...data };
    for (const k of deepKeys) {
      if (data[k] && typeof data[k] === "object") {
        next[k] = { ...(this.state[k] ?? {}), ...data[k] };
      }
    }
    this.state = next;
    return this.state;
  }

  resetToDefaults() {
    this.state = structuredClone(this.defaults);
    return this.state;
  }

  get() {
    return structuredClone(this.state);
  }

  set(k, v) {
    this.state[k] = v;
  }
}