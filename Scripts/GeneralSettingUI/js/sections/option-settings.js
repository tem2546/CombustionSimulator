
// js/sections/option-settings.js
import { byId, setVal, setText, inEnum } from "../core/dom.js";
import { t } from "../core/i18n.js";

export class OptionSettings {
  init(store) {
    this.store = store;
  }

  applyDefaults() {
    const s = this.store.get();
    setVal("parallel",   s.parallel   ?? "No");
  }

  collectPayload() {
    const s = this.store.get();
    const payload = {
      parallel:   byId("parallel")?.value   ?? "No",
    };
    this.store.apply(payload);
    return payload;
  }

  checkValidity(payload) {
    const errs = [];
    const { parallel, mgd } = payload;
    const YN = ["Yes", "No"];
    if (!inEnum(parallel, YN)) errs.push(t("err.parallel"));
    return errs;
  }
}
