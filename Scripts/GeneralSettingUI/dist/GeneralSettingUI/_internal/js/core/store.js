// js/core/store.js
export class SettingsStore {
  constructor() {
    this.defaults = {
      // 実行モード状態
      modeSelect: "6",

      // モード1: データ整理パラメータ
      thrust: { fn: "", path: "" },
      noiseremoved: "No",
      spikecut: "No",
      csvout: "Yes",
      // 【追加】モード4: 自作エンジン解析パラメータ
      m4_engine_select: "EngineA",
      m4_thrust_file_select: "",
      m4_oxidant_select: "N2O",
      m4_fuel_select: "PP",

      // 【追加】モード5: エンジニアパラメータ設計パラメータ
      m5_oxidant_select: "N2O",
      m5_fuel_select: "PE",
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
    const deepKeys = ["thrust"];
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
