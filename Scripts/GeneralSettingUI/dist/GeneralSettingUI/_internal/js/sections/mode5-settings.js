// js/sections/mode5-settings.js
import { byId, setVal, getVal } from "../core/dom.js";

export class Mode5Settings {
  init(store) {
    this.store = store;
  }

  applyDefaults() {
    setVal("m5_oxidant_select", "N2O");
    setVal("m5_fuel_select", "PE");
    setVal("m5_port_select", "circle");
    setVal("m5_F_req", 250);
    setVal("m5_I_req", 1500);
    setVal("m5_vt", 2000);
    setVal("m5_pti", 5.0);
    setVal("m5_cstar_eff", 0.85);
    setVal("m5_Cd", 0.7);
    setVal("m5_do", 3.5);
    setVal("m5_df", 15);
    setVal("m5_Df_outer", 50);
    setVal("m5_Lf_max", 0.5);
    setVal("m5_Lstar", 2.0);
  }

  collectPayload() {
    return {
      m5_oxidant_select: getVal("m5_oxidant_select") || "N2O",
      m5_fuel_select: getVal("m5_fuel_select") || "PE",
      m5_port_select: getVal("m5_port_select") || "circle",
      m5_F_req: parseFloat(getVal("m5_F_req")) || 250,
      m5_I_req: parseFloat(getVal("m5_I_req")) || 1500,
      m5_vt: parseFloat(getVal("m5_vt")) || 2000,
      m5_pti: parseFloat(getVal("m5_pti")) || 5.0,
      m5_cstar_eff: parseFloat(getVal("m5_cstar_eff")) || 0.85,
      m5_Cd: parseFloat(getVal("m5_Cd")) || 0.7,
      m5_do: parseFloat(getVal("m5_do")) || 3.5,
      m5_df: parseFloat(getVal("m5_df")) || 15,
      m5_Df_outer: parseFloat(getVal("m5_Df_outer")) || 50,
      m5_Lf_max: parseFloat(getVal("m5_Lf_max")) || 0.5,
      m5_Lstar: parseFloat(getVal("m5_Lstar")) || 2.0
    };
  }

  apply(data) {
    if (!data) return;
    setVal("m5_oxidant_select", data.m5_oxidant_select ?? "N2O");
    setVal("m5_fuel_select", data.m5_fuel_select ?? "PE");
    setVal("m5_port_select", data.m5_port_select ?? "circle");
    setVal("m5_F_req", data.m5_F_req ?? 250);
    setVal("m5_I_req", data.m5_I_req ?? 1500);
    setVal("m5_vt", data.m5_vt ?? 2000);
    setVal("m5_pti", data.m5_pti ?? 5.0);
    setVal("m5_cstar_eff", data.m5_cstar_eff ?? 0.85);
    setVal("m5_Cd", data.m5_Cd ?? 0.7);
    setVal("m5_do", data.m5_do ?? 3.5);
    setVal("m5_df", data.m5_df ?? 15);
    setVal("m5_Df_outer", data.m5_Df_outer ?? 50);
    setVal("m5_Lf_max", data.m5_Lf_max ?? 0.5);
    setVal("m5_Lstar", data.m5_Lstar ?? 2.0);
  }

  checkValidity(payload) {
    const errs = [];
    if (payload.m5_port_select === "star_swirl" && payload.m5_fuel_select !== "ABS") {
      errs.push("設計: 星形旋回の後退速度モデルはABSでのみ使用できます");
    }
    if (payload.m5_F_req <= 0) errs.push("設計: 要求推力は0Nより大きい必要があります");
    if (payload.m5_I_req <= 0) errs.push("設計: 要求トータルインパルスは0Nsより大きい必要があります");
    return errs;
  }
}
