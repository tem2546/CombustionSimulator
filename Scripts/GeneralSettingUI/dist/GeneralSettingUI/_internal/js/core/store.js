// js/core/store.js
export class SettingsStore {
  constructor() {
    this.defaults = {
      // 実行モード状態
      modeSelect: "6",

      // モード1: データ整理パラメータ
      m1_thrust: { fn: "", path: "" },
      m1_noiseremoved: "No",
      m1_spikecut: "No",
      m1_csvout: "Yes",
      m1_calc_residual_time: "Yes",

      // モード2: CEA解析パラメータ
      m2_compareDataNumSelect: "2",
      m2_customDataNumInput: "4",
      m2_compare_sync_spike: "Yes",
      m2_compare_graphs: { thrust: true, removed_thrust: false },
      m2_compare_files_dict: {},

      // モード3: CEA解析パラメータ
      m3_fuel_select: "PP",
      m3_oxidant_select: "N2O",
      m3_hkj: -713.01204,
      m3_c_atom: 30,
      m3_o_atom: 0,
      m3_h_atom: 60,
      m3_n_atom: 0,
      m3_tk: 297,

      // モード4: 自作エンジン解析パラメータ
      m4_thrust: { fn: "", path: "" },
      m4_engine_select: "j-2i",
      m4_oxidant_select: "N2O",
      m4_fuel_select: "PP",

      // モード5: エンジニアパラメータ設計パラメータ
      m5_oxidant_select: "N2O",
      m5_fuel_select: "PP",
      m5_F_req: 250,
      m5_I_req: 1500,
      m5_vt: 2000,
      m5_pti: 5.0,
      m5_cstar_eff: 0.85,
      m5_Cd: 0.7,
      m5_do: 3.5,
      m5_df: 15,
      m5_Df_outer: 50,
      m5_Lf_max: 0.5,
      m5_Lstar: 2.0,

      // 互換性維持のためのダミー（空オブジェクト化されたセクション用）
      mode_export: "Default",
      result_path: "",
      output: "None"
    };
    this.state = structuredClone(this.defaults);
  }

  apply(data = {}) {
    if (!data || typeof data !== "object" || Array.isArray(data)) {
      return this.state;
    }
    
    for (const [key, value] of Object.entries(data)) {
      this.set(key, value);
    }
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
    if (typeof v === "object" && v !== null && !Array.isArray(v)) {
      this.state[k] = { ...this.state[k], ...v };
    } else {
      this.state[k] = v;
    }
  }
}