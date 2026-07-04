
// js/sections/model-settings.js
import { byId, setText, inEnum } from "../core/dom.js";
import { t } from "../core/i18n.js";

const selLabel = (id, name) => {
  setText(id, t("msg.selected", { name }));
  byId(id)?.classList.add("selected");
};
const unselLabel = (id) => {
  setText(id, t("status.unselected"));
  byId(id)?.classList.remove("selected");
};

const MULTI_STAGE_SLOTS = [
  { btnId: "pickParam1Btn", labelId: "param1_fn_label" },
  { btnId: "pickParam2Btn", labelId: "param2_fn_label" },
  { btnId: "pickParam3Btn", labelId: "param3_fn_label" },
];

export class ModelSettings {
  init(store) {
    this.store = store;

    // Parameter ファイル選択（単段：絶対パス）
    byId("pickParamBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_file(
        [{ description: "Excel", extensions: ["xlsx"] }], false
      );
      if (!abs) return;
      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));
      selLabel("param_fn_label", fname);
      const s = this.store.get();
      s.param = { fn: fname, path: dir };
      this.store.apply({ param: s.param });
    });

    // Parameter ファイル選択（多段：段ごとにスロット選択）
    MULTI_STAGE_SLOTS.forEach((slot, idx) => {
      byId(slot.btnId)?.addEventListener("click", async () => {
        const abs = await window.pywebview.api.open_file(
          [{ description: "Excel", extensions: ["xlsx"] }], false
        );
        if (!abs) return;
        const fname = abs.split(/[\\/]/).pop();
        const dir = abs.slice(0, -(fname.length + 1));
        selLabel(slot.labelId, fname);
        const s = this.store.get();
        const fnArr = Array.isArray(s.param?.fn) ? [...s.param.fn] : ["", "", ""];
        const pathArr = Array.isArray(s.param?.path) ? [...s.param.path] : ["", "", ""];
        while (fnArr.length < 3) fnArr.push("");
        while (pathArr.length < 3) pathArr.push("");
        fnArr[idx] = fname;
        pathArr[idx] = dir;
        this.store.apply({ param: { fn: fnArr, path: pathArr } });
      });
    });

    // multi_stage トグル切替
    byId("multi_stage")?.addEventListener("change", (e) => {
      const on = e.target.value === "On";
      this.store.apply({ multi_stage: on });
      this.syncMultiStageUI(on);
      // 単段⇔多段の切替で param をリセット（混同防止）
      if (on) {
        this.store.apply({ param: { fn: ["", "", ""], path: ["", "", ""] } });
        unselLabel("param_fn_label");
        MULTI_STAGE_SLOTS.forEach(s => unselLabel(s.labelId));
      } else {
        this.store.apply({ param: { fn: "", path: "" } });
        unselLabel("param_fn_label");
        MULTI_STAGE_SLOTS.forEach(s => unselLabel(s.labelId));
      }
    });

    // Thrust ファイル選択（絶対パス）
    byId("pickThrustBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_file(
        [{ description: "Data", extensions: ["xlsx","csv","txt"] }], false
      );
      if (!abs) return;
      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));
      selLabel("thrust_fn_label", fname);
      const s = this.store.get();
      s.thrust = { fn: fname, path: dir };
      this.store.apply({ thrust: s.thrust });
    });
  }

  syncMultiStageUI(on) {
    const single = byId("single_param_row");
    const multi  = byId("multi_param_rows");
    if (single) single.style.display = on ? "none" : "";
    if (multi)  multi.style.display  = on ? "" : "none";
  }

  // 読込時はファイルを反映しない方針：常に「未選択」表示
  applyDefaults() {
    unselLabel("param_fn_label");
    unselLabel("thrust_fn_label");
    MULTI_STAGE_SLOTS.forEach(s => unselLabel(s.labelId));
    const s = this.store.get();
    byId("descent_model").value = s.descent_model ?? "Vw_model";

    const on = !!s.multi_stage;
    if (byId("multi_stage")) byId("multi_stage").value = on ? "On" : "Off";
    this.syncMultiStageUI(on);
  }

  collectPayload() {
    const s = this.store.get();
    const on = !!s.multi_stage;
    let param;
    if (on) {
      const fn = Array.isArray(s.param?.fn) ? s.param.fn.slice(0,3) : ["", "", ""];
      const path = Array.isArray(s.param?.path) ? s.param.path.slice(0,3) : ["", "", ""];
      while (fn.length < 3) fn.push("");
      while (path.length < 3) path.push("");
      param = { fn, path };
    } else {
      const fn = Array.isArray(s.param?.fn) ? (s.param.fn[0] ?? "") : (s.param?.fn ?? "");
      const path = Array.isArray(s.param?.path) ? (s.param.path[0] ?? "") : (s.param?.path ?? "");
      param = { fn, path };
    }
    return {
      multi_stage: on,
      param,
      thrust: { fn: s.thrust?.fn ?? "", path: s.thrust?.path ?? "" },
      descent_model: byId("descent_model").value || "Vw_model"
    };
  }

  checkValidity(payload) {
    const errs = [];
    const { param, thrust, descent_model, multi_stage } = payload;
    const DM = ["Vw_model", "Dynamics"];
    if (multi_stage) {
      const stageKeys = ["err.param.stage1", "err.param.stage2", "err.param.stage3"];
      const fns = Array.isArray(param?.fn) ? param.fn : [];
      for (let i = 0; i < 3; i++) {
        if (!fns[i]) errs.push(t(stageKeys[i]));
      }
    } else {
      if (!param?.fn) errs.push(t("err.param"));
    }
    if (!thrust?.fn) errs.push(t("err.thrust"));
    if (!inEnum(descent_model, DM)) errs.push(t("err.descent"));
    return errs;
  }
}
