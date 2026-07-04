
// js/core/dom.js
export const byId   = (id) => document.getElementById(id);
export const getVal = (id) => String(byId(id)?.value ?? "").trim();
export const setVal = (id, v) => { const el = byId(id); if (el) el.value = String(v ?? ""); };
export const setText = (id, text) => { const el = byId(id); if (el) el.textContent = String(text ?? ""); };
export const show = (id) => { const el = byId(id); if (el) el.style.display = ""; };
export const hide = (id) => { const el = byId(id); if (el) el.style.display = "none"; };
export const on = (id, evt, handler) => byId(id)?.addEventListener(evt, handler);
export const isFiniteNum = (x) => typeof x === "number" && Number.isFinite(x);
export const isNonEmptyStr = (s) => typeof s === "string" && s.trim().length > 0;
export const inEnum = (v, list) => list.includes(v);
export const inRange = (x, min, max) => this.isFiniteNum(x) && x >= min && x <= max;