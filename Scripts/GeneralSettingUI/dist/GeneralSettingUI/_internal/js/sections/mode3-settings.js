// js/sections/mode3-settings.js
import { byId, setVal } from "../core/dom.js";

export class Mode3Settings {
  init(store) {
    this.store = store;
    // 必要であればここでイベントリスナー等を初期化できます
  }

  // 初期デフォルト値の適用
  applyDefaults() {
    setVal("m3_fuel_select", "PP");
    setVal("m3_oxidant_select", "N2O");
    setVal("m3_hkj", -713.01204);
    setVal("m3_c_atom", 30);
    setVal("m3_o_atom", 0);
    setVal("m3_h_atom", 60);
    setVal("m3_n_atom", 0);
    setVal("m3_tk", 297);
  }

  // フォームからデータを一括収集（Mode2と同様にbyIdから直接確実に取得）
  collectPayload() {
    return {
      m3_fuel_select: byId("m3_fuel_select")?.value || "PP",
      m3_oxidant_select: byId("m3_oxidant_select")?.value || "N2O",
      m3_hkj: parseFloat(byId("m3_hkj")?.value ?? -713.01204),
      m3_c_atom: parseFloat(byId("m3_c_atom")?.value ?? 30),
      m3_o_atom: parseFloat(byId("m3_o_atom")?.value ?? 0),
      m3_h_atom: parseFloat(byId("m3_h_atom")?.value ?? 60),
      m3_n_atom: parseFloat(byId("m3_n_atom")?.value ?? 0),
      m3_tk: parseFloat(byId("m3_tk")?.value ?? 297)
    };
  }

  // 外部ロードデータの画面反映
  apply(data) {
    if (!data) return;
    setVal("m3_fuel_select", data.m3_fuel_select ?? "PP");
    setVal("m3_oxidant_select", data.m3_oxidant_select ?? "N2O");
    setVal("m3_hkj", data.m3_hkj ?? -713.01204);
    setVal("m3_c_atom", data.m3_c_atom ?? 30);
    setVal("m3_o_atom", data.m3_o_atom ?? 0);
    setVal("m3_h_atom", data.m3_h_atom ?? 60);
    setVal("m3_n_atom", data.m3_n_atom ?? 0);
    setVal("m3_tk", data.m3_tk ?? 297);
  }

  // バリデーションチェック（Mode2のように安全な形、または一旦空にしてテスト）
  checkValidity(payload) {
    const errs = [];
    if (byId("modeSelect")?.value === "mode3") {
      if (isNaN(payload.m3_hkj)) {
        errs.push("CEA: 比エンタルピーは数値で入力してください");
      }
      if (isNaN(payload.m3_tk) || payload.m3_tk <= 0) {
        errs.push("CEA: 温度は0Kより大きい数値を入力してください");
      }
    }
    return errs;
  }
}