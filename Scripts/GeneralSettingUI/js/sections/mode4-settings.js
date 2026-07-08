// js/sections/mode4-settings.js
import { byId } from "../core/dom.js";

export class Mode4Settings {
  constructor() {
    this.engine = byId("m4_engine_select");
    this.thrustFile = byId("m4_thrust_file_select");
    this.oxidant = byId("m4_oxidant_select");
    this.fuel = byId("m4_fuel_select");
  }

  applyDefaults() {
    if (this.engine) this.engine.value = "EngineA";
    if (this.thrustFile) this.thrustFile.value = "";
    if (this.oxidant) this.oxidant.value = "N2O";
    if (this.fuel) this.fuel.value = "PP";
  }

  collectPayload() {
    return {
      m4_engine_select: this.engine ? this.engine.value : "EngineA",
      m4_thrust_file_select: this.thrustFile ? this.thrustFile.value : "",
      m4_oxidant_select: this.oxidant ? this.oxidant.value : "N2O",
      m4_fuel_select: this.fuel ? this.fuel.value : "PP"
    };
  }

  apply(data) {
    if (!data) return;
    if (this.engine) this.engine.value = data.m4_engine_select ?? "EngineA";
    if (this.thrustFile) this.thrustFile.value = data.m4_thrust_file_select ?? "";
    if (this.oxidant) this.oxidant.value = data.m4_oxidant_select ?? "N2O";
    if (this.fuel) this.fuel.value = data.m4_fuel_select ?? "PP";
  }

  checkValidity(payload) {
    const errs = [];
    // 必要に応じて、ファイル未選択時の警告などを追加可能
    return errs;
  }
}