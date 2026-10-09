// js/sections/mode3-settings.js
import { getVal, setVal } from "../core/dom.js";

export class Mode3Settings {
  // 初期化処理
  init(store) {
    this.store = store;
  }

  // フォームからデータを一括収集（Mode2と同様にbyIdから直接確実に取得）
  collectPayload() {
    return {
      m3_fuel_select: getVal("m3_fuel_select") || "PP",
      m3_oxidant_select: getVal("m3_oxidant_select") || "N2O",
      m3_hkj: parseFloat(getVal("m3_hkj") ?? -713.01204),
      m3_c_atom: parseFloat(getVal("m3_c_atom") ?? 30),
      m3_o_atom: parseFloat(getVal("m3_o_atom") ?? 0),
      m3_h_atom: parseFloat(getVal("m3_h_atom") ?? 60),
      m3_n_atom: parseFloat(getVal("m3_n_atom") ?? 0),
      m3_tk: parseFloat(getVal("m3_tk") ?? 297)
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
    if (getVal("modeSelect") === "3") {
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