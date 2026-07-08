// js/sections/mode3-settings.js
import { byId } from "../core/dom.js";

export class Mode3Settings {
  constructor() {
    // 画面上の主要な入力要素を取得
    this.fuel = byId("m3_fuel_select") || byId("fuel_select"); // 既存のIDに配慮
    this.oxidant = byId("m3_oxidant_select") || byId("oxidant_select");
    this.hkj = byId("m3_hkj") || byId("h_kj_mol");
    this.c_atom = byId("m3_c_atom");
    this.o_atom = byId("m3_o_atom");
    this.h_atom = byId("m3_h_atom");
    this.n_atom = byId("m3_n_atom");
    this.tk = byId("m3_tk");
  }

  // 初期デフォルト値の適用
  applyDefaults() {
    if (this.fuel) this.fuel.value = "PP";
    if (this.oxidant) this.oxidant.value = "N2O";
    if (this.hkj) this.hkj.value = "-713.0";
    if (this.c_atom) this.c_atom.value = "3";
    if (this.o_atom) this.o_atom.value = "0";
    if (this.h_atom) this.h_atom.value = "6";
    if (this.n_atom) this.n_atom.value = "0";
    if (this.tk) this.tk.value = "298.15";
  }

  // フォームからデータを一括収集
  collectPayload() {
    return {
      m3_fuel_select: this.fuel ? this.fuel.value : "PP",
      m3_oxidant_select: this.oxidant ? this.oxidant.value : "N2O",
      m3_hkj: this.hkj ? parseFloat(this.hkj.value || 0) : -713.0,
      m3_c_atom: this.c_atom ? parseFloat(this.c_atom.value || 0) : 3,
      m3_o_atom: this.o_atom ? parseFloat(this.o_atom.value || 0) : 0,
      m3_h_atom: this.h_atom ? parseFloat(this.h_atom.value || 0) : 6,
      m3_n_atom: this.n_atom ? parseFloat(this.n_atom.value || 0) : 0,
      m3_tk: this.tk ? parseFloat(this.tk.value || 0) : 298.15
    };
  }

  // 外部ロードデータの画面反映
  apply(data) {
    if (!data) return;
    if (this.fuel) this.fuel.value = data.m3_fuel_select ?? "PP";
    if (this.oxidant) this.oxidant.value = data.m3_oxidant_select ?? "N2O";
    if (this.hkj) this.hkj.value = data.m3_hkj ?? "-713.0";
    if (this.c_atom) this.c_atom.value = data.m3_c_atom ?? "3";
    if (this.o_atom) this.o_atom.value = data.m3_o_atom ?? "0";
    if (this.h_atom) this.h_atom.value = data.m3_h_atom ?? "6";
    if (this.n_atom) this.n_atom.value = data.m3_n_atom ?? "0";
    if (this.tk) this.tk.value = data.m3_tk ?? "298.15";
  }

  // バリデーションチェック
  checkValidity(payload) {
    const errs = [];
    if (isNaN(payload.m3_hkj)) errs.push("CEA: 比エンタルピーは数値で入力してください");
    if (payload.m3_tk <= 0) errs.push("CEA: 温度は0Kより大きい必要があります");
    return errs;
  }
}