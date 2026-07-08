// js/sections/mode5-settings.js
import { byId } from "../core/dom.js";

export class Mode5Settings {
  constructor() {
    this.ox = byId("m5_oxidant_select");
    this.fuel = byId("m5_fuel_select");
    this.freq = byId("m5_F_req");
    this.ireq = byId("m5_I_req");
    this.vt = byId("m5_vt");
    this.pti = byId("m5_pti");
    this.cstar = byId("m5_cstar_eff");
    this.cd = byId("m5_Cd");
    this.do = byId("m5_do");
    this.df = byId("m5_df");
    this.df_outer = byId("m5_Df_outer");
    this.lf_max = byId("m5_Lf_max");
    this.lstar = byId("m5_Lstar");
  }

  applyDefaults() {
    if (this.ox) this.ox.value = "N2O";
    if (this.fuel) this.fuel.value = "PP";
    if (this.freq) this.freq.value = "250";
    if (this.ireq) this.ireq.value = "1500";
    if (this.vt) this.vt.value = "2000";
    if (this.pti) this.pti.value = "5.0";
    if (this.cstar) this.cstar.value = "0.85";
    if (this.cd) this.cd.value = "0.7";
    if (this.do) this.do.value = "3.5";
    if (this.df) this.df.value = "15";
    if (this.df_outer) this.df_outer.value = "50";
    if (this.lf_max) this.lf_max.value = "0.5";
    if (this.lstar) this.lstar.value = "2.0";
  }

  collectPayload() {
    return {
      m5_oxidant_select: this.ox ? this.ox.value : "N2O",
      m5_fuel_select: this.fuel ? this.fuel.value : "PP",
      m5_F_req: this.freq ? parseFloat(this.freq.value || 0) : 250,
      m5_I_req: this.ireq ? parseFloat(this.ireq.value || 0) : 1500,
      m5_vt: this.vt ? parseFloat(this.vt.value || 0) : 2000,
      m5_pti: this.pti ? parseFloat(this.pti.value || 0) : 5.0,
      m5_cstar_eff: this.cstar ? parseFloat(this.cstar.value || 0) : 0.85,
      m5_Cd: this.cd ? parseFloat(this.cd.value || 0) : 0.7,
      m5_do: this.do ? parseFloat(this.do.value || 0) : 3.5,
      m5_df: this.df ? parseFloat(this.df.value || 0) : 15,
      m5_Df_outer: this.df_outer ? parseFloat(this.df_outer.value || 0) : 50,
      m5_Lf_max: this.lf_max ? parseFloat(this.lf_max.value || 0) : 0.5,
      m5_Lstar: this.lstar ? parseFloat(this.lstar.value || 0) : 2.0
    };
  }

  apply(data) {
    if (!data) return;
    if (this.ox) this.ox.value = data.m5_oxidant_select ?? "N2O";
    if (this.fuel) this.fuel.value = data.m5_fuel_select ?? "PP";
    if (this.freq) this.freq.value = data.m5_F_req ?? 250;
    if (this.ireq) this.ireq.value = data.m5_I_req ?? 1500;
    if (this.vt) this.vt.value = data.m5_vt ?? 2000;
    if (this.pti) this.pti.value = data.m5_pti ?? 5.0;
    if (this.cstar) this.cstar.value = data.m5_cstar_eff ?? 0.85;
    if (this.cd) this.cd.value = data.m5_Cd ?? 0.7;
    if (this.do) this.do.value = data.m5_do ?? 3.5;
    if (this.df) this.df.value = data.m5_df ?? 15;
    if (this.df_outer) this.df_outer.value = data.m5_Df_outer ?? 50;
    if (this.lf_max) this.lf_max.value = data.m5_Lf_max ?? 0.5;
    if (this.lstar) this.lstar.value = data.m5_Lstar ?? 2.0;
  }

  checkValidity(payload) {
    const errs = [];
    if (payload.m5_F_req <= 0) errs.push("設計: 要求推力は0Nより大きい必要があります");
    if (payload.m5_I_req <= 0) errs.push("設計: 要求トータルインパルスは0Nsより大きい必要があります");
    return errs;
  }
}