// js/core/store.js
export class SettingsStore {
  constructor() {
    this.defaults = {
      // 実行モード状態
      modeSelect: "mode1",

      // モード1: データ整理パラメータ
      thrust: { fn: "", path: "" },
      noiseremoved: "No",
      spikecut: "No",
      csvout: "Yes",

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