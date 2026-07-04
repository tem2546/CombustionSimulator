
// js/sections/roll-settings.js
import { byId, setVal, setText, isNonEmptyStr, inEnum, isFiniteNum } from "../core/dom.js";
import { t } from "../core/i18n.js";

const selLabel = (id, name) => {
  setText(id, t("msg.selected", { name }));
  byId(id)?.classList.add("selected");
};
const unselLabel = (id) => {
  setText(id, t("status.unselected"));
  byId(id)?.classList.remove("selected");
};

const AERO_SLOT_N = 5;
const aeroSlotIdx = Array.from({ length: AERO_SLOT_N }, (_, i) => i);
const emptyAeroFile = () => ({ use: false, v: 0, fn: "", path: "" });
const emptyAeroFiles = () => aeroSlotIdx.map(() => emptyAeroFile());

export class RollSettings {
  init(store) {
    this.store = store;

    const toggleMomentRow = () => {
      const isMoment = (byId("roll_factor")?.value === "Moment");
      byId("mx_file_row").style.display = isMoment ? "" : "none";
      if (!isMoment) setVal("mx_fn", t("status.unselected"));
    };

    const toggleRotRow = () => {
      const isRot = (byId("simu_mode")?.value === "Rotational");
      byId("rot_cond_row").style.display = isRot ? "" : "none";
    };

    const toggleAeroDbFiles = () => {
      const execOn = (byId("execute_cont")?.value === "true");
      const dbOn   = (byId("aero_db_use")?.value === "true");
      byId("aero_db_files").style.display = (execOn && dbOn) ? "" : "none";
    };

    // パーツ別空力寄与モードは execute_cont と独立（固定翼飛行＝execute_cont=false でも使用可）
    const toggleCompAeroFiles = () => {
      const compOn = (byId("comp_aero_use")?.value === "true");
      byId("comp_aero_files").style.display = compOn ? "" : "none";
    };
    // 固定舵角モード ON のときだけ δ_fixed 入力欄を表示
    const toggleCompDeltaRow = () => {
      const fixOn = (byId("comp_fix_delta_use")?.value === "true");
      byId("comp_delta_row").style.display = fixOn ? "" : "none";
    };

    const applyEnableState = () => {
      const execOn = (byId("execute_cont")?.value === "true");
      const compOn = (byId("comp_aero_use")?.value === "true");
      const ids = ["control_func","simu_mode","roll_factor","rot_Va","rot_z"];
      ids.forEach(id => {
        const el = byId(id);
        if (el) el.disabled = !execOn;
      });
      // Cl0(ロール空力係数)は Mx1 でロール制御 OFF でも使われるため、
      // ロール制御 または パーツ別空力 のいずれか/両方が ON なら入力可とする。
      const cl0 = byId("Cl0");
      if (cl0) cl0.disabled = !(execOn || compOn);
      // 動翼空力DB: Roll Control が false の時は強制的に OFF・操作不可
      const aeroUse = byId("aero_db_use");
      if (aeroUse) {
        if (!execOn) aeroUse.value = "false";
        aeroUse.disabled = !execOn;
      }
      byId("aero_db_row").style.display = "";   // 行自体は常時表示（セレクトのみ無効化）
      // 表示切り替え
      if (!execOn) {
        byId("mx_file_row").style.display = "none";
        byId("rot_cond_row").style.display = "none";
        setVal("mx_fn", t("status.unselected"));
      } else {
        toggleMomentRow(); toggleRotRow();
      }
      toggleAeroDbFiles();
    };

    byId("execute_cont")?.addEventListener("change", applyEnableState);
    byId("roll_factor")?.addEventListener("change", toggleMomentRow);
    byId("simu_mode")?.addEventListener("change", toggleRotRow);
    byId("aero_db_use")?.addEventListener("change", toggleAeroDbFiles);
    byId("comp_aero_use")?.addEventListener("change", toggleCompAeroFiles);
    byId("comp_aero_use")?.addEventListener("change", applyEnableState);  // Cl0 の有効/無効を更新
    byId("comp_fix_delta_use")?.addEventListener("change", toggleCompDeltaRow);

    // Moment CSV 絶対パス
    byId("pickMxBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_file(
        [{ description: "CSV/Excel", extensions: ["csv","xlsx"] }], false
      );
      if (!abs) return;
      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));
      setVal("mx_fn", t("msg.selected", { name: fname }));
      const s = this.store.get();
      s.Mx_csv = { fn: fname, path: dir };
      this.store.apply({ Mx_csv: s.Mx_csv });
    });

    // 動翼空力DB ファイル選択（5スロット、絶対パス）
    aeroSlotIdx.forEach((idx) => {
      byId(`pickAero${idx}Btn`)?.addEventListener("click", async () => {
        const abs = await window.pywebview.api.open_file(
          [{ description: "Excel (aero DB)", extensions: ["xlsx"] }], false
        );
        if (!abs) return;
        const fname = abs.split(/[\\/]/).pop();
        const dir = abs.slice(0, -(fname.length + 1));
        selLabel(`aero_fn_label_${idx}`, fname);
        const s = this.store.get();
        const files = Array.isArray(s.aero_db?.files) ? s.aero_db.files.slice() : emptyAeroFiles();
        while (files.length < AERO_SLOT_N) files.push(emptyAeroFile());
        files[idx] = { ...(files[idx] ?? emptyAeroFile()), fn: fname, path: dir };
        this.store.apply({ aero_db: { use: s.aero_db?.use ?? false, files } });
      });
    });

    // パーツ別空力データ（Components シート Excel、絶対パス）
    byId("pickCompAeroBtn")?.addEventListener("click", async () => {
      const abs = await window.pywebview.api.open_file(
        [{ description: "Excel (component aero)", extensions: ["xlsx"] }], false
      );
      if (!abs) return;
      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));
      setVal("comp_aero_fn", t("msg.selected", { name: fname }));
      const s = this.store.get();
      this.store.apply({ comp_aero: { ...(s.comp_aero ?? {}), fn: fname, path: dir } });
    });
  }

  applyDefaults() {
    const s = this.store.get();
    setVal("execute_cont", String(s.execute_cont ?? false));
    setVal("control_func", s.control_func ?? "example");
    setVal("simu_mode", s.simu_mode ?? "Launch");
    setVal("roll_factor", s.roll_factor ?? "Coefficience");
    setVal("Cl0", s.Cl0 ?? 0.001);
    const rc = s.rot_cond ?? { Va: 50, z: 200 };
    setVal("rot_Va", rc.Va); setVal("rot_z", rc.z);
    setVal("mx_fn", t("status.unselected")); // 読込時は反映しない方針

    // 動翼空力DB（流速・使用フラグは反映、ファイル名ラベルは反映しない方針）
    const adb = s.aero_db ?? { use: false, files: emptyAeroFiles() };
    setVal("aero_db_use", String(adb.use ?? false));
    const files = Array.isArray(adb.files) ? adb.files : [];
    aeroSlotIdx.forEach((idx) => {
      const f = files[idx] ?? emptyAeroFile();
      const cb = byId(`aero_use_${idx}`);
      if (cb) cb.checked = !!f.use;
      const v = (isFiniteNum(f.v) && f.v > 0) ? f.v : "";
      setVal(`aero_v_${idx}`, v);
      unselLabel(`aero_fn_label_${idx}`);
    });

    // パーツ別空力寄与モード（使用フラグ・固定舵角・δ_fixed は反映、ファイル名ラベルは反映しない方針）
    const ca = s.comp_aero ?? { use: false, fix_delta: false, fn: "", path: "", delta_fixed: 0 };
    setVal("comp_aero_use", String(ca.use ?? false));
    setVal("comp_fix_delta_use", String(ca.fix_delta ?? false));
    setVal("comp_delta_fixed", isFiniteNum(ca.delta_fixed) ? ca.delta_fixed : "");
    setVal("comp_aero_fn", t("status.unselected"));

    // 初期表示
    const evt = new Event("change");
    byId("execute_cont").dispatchEvent(evt);
    byId("roll_factor").dispatchEvent(evt);
    byId("simu_mode").dispatchEvent(evt);
    byId("aero_db_use").dispatchEvent(evt);
    byId("comp_aero_use").dispatchEvent(evt);
    byId("comp_fix_delta_use").dispatchEvent(evt);
  }

  collectPayload() {
    // パーツ別空力寄与モードは execute_cont と独立して収集する
    const readCompAero = () => {
      const s = this.store.get();
      const dRaw = byId("comp_delta_fixed")?.value;
      return {
        use: (byId("comp_aero_use").value === "true"),
        fix_delta: (byId("comp_fix_delta_use").value === "true"),
        fn: s.comp_aero?.fn ?? "",
        path: s.comp_aero?.path ?? "",
        delta_fixed: (dRaw === "" || dRaw === undefined || dRaw === null) ? 0 : Number(dRaw)
      };
    };
    const comp_aero = readCompAero();

    const execute_cont = (byId("execute_cont").value === "true");
    if (!execute_cont) {
      // ロール制御 OFF。ただしパーツ別空力 ON なら Cl0(ロール係数)は有効なので収集する。
      const Cl0 = comp_aero.use ? (Number(byId("Cl0").value) || 0) : 0;
      const payload = {
        execute_cont,
        control_func: "", simu_mode: "Launch",
        roll_factor: "Coefficience", Cl0,
        rot_cond: { Va: undefined, z: undefined },
        Mx_csv: { fn: "", path: "" },
        aero_db: { use: false, files: emptyAeroFiles() },
        comp_aero
      };
      this.store.apply(payload);
      return payload;
    }

    const control_func = byId("control_func").value || "example";
    const simu_mode    = byId("simu_mode").value || "Launch";
    const roll_factor  = byId("roll_factor").value || "Coefficience";
    const Cl0          = Number(byId("Cl0").value);

    let rot_cond = { Va: undefined, z: undefined };
    if (simu_mode === "Rotational") {
      rot_cond = { Va: Number(byId("rot_Va").value), z: Number(byId("rot_z").value) };
    }

    const s = this.store.get();

    const aero_use = (byId("aero_db_use").value === "true");
    const storedFiles = Array.isArray(s.aero_db?.files) ? s.aero_db.files : [];
    const aeroFiles = aeroSlotIdx.map((idx) => {
      const f = storedFiles[idx] ?? emptyAeroFile();
      const vRaw = byId(`aero_v_${idx}`)?.value;
      return {
        use: !!byId(`aero_use_${idx}`)?.checked,
        v: (vRaw === "" || vRaw === undefined || vRaw === null) ? NaN : Number(vRaw),
        fn: f.fn ?? "",
        path: f.path ?? ""
      };
    });
    const aero_db = { use: aero_use, files: aeroFiles };

    const payload = {
      execute_cont, control_func, simu_mode, roll_factor, Cl0, rot_cond,
      Mx_csv: { fn: s.Mx_csv?.fn ?? "", path: s.Mx_csv?.path ?? "" },
      aero_db,
      comp_aero
    };
    this.store.apply(payload);
    return payload;
  }

  checkValidity(payload) {
    const errs = [];
    const { execute_cont, control_func, simu_mode, roll_factor, Cl0, rot_cond, Mx_csv, aero_db, comp_aero } = payload;
    if (typeof execute_cont !== "boolean") {
      errs.push(t("err.exec"));
      return errs;
    }

    // ---- パーツ別空力寄与モード（execute_cont と独立に検証） ----
    if (comp_aero && comp_aero.use === true) {
      if (!isNonEmptyStr(comp_aero.fn)) errs.push(t("err.comp.fn"));
      // 固定舵角モード ON のときだけ δ_fixed を検証
      if (comp_aero.fix_delta === true && !isFiniteNum(comp_aero.delta_fixed)) {
        errs.push(t("err.comp.delta"));
      }
    }

    // false の場合は残りの項目をスキップ（無効運用。aero DB も強制 OFF）
    if (execute_cont === false) return errs;

    const SM = ["Launch", "Rotational"];
    const RF = ["Coefficience", "Moment"];
    if (!isNonEmptyStr(control_func)) errs.push(t("err.func"));
    if (!inEnum(simu_mode, SM)) errs.push(t("err.simu"));
    if (!inEnum(roll_factor, RF)) errs.push(t("err.factor"));

    if (simu_mode === "Rotational") {
      const Va = rot_cond?.Va;
      const z = rot_cond?.z;
      if (!isFiniteNum(Va) || Va <= 0) errs.push(t("err.rot.va"));
      if (!isFiniteNum(z) || z < 0) errs.push(t("err.rot.z"));
    }
    if (roll_factor === "Coefficience") {
      if (!isFiniteNum(Cl0) || Cl0 <= 0) errs.push(t("err.cl0"));
    }
    if (roll_factor === "Moment") {
      const fn = Mx_csv?.fn;
      if (!isNonEmptyStr(fn)) errs.push(t("err.mx"));
    }

    // ---- 動翼空力DB ----
    if (aero_db && aero_db.use === true) {
      const files = Array.isArray(aero_db.files) ? aero_db.files : [];
      const enabled = files.filter(f => f && f.use === true);
      if (enabled.length < 2) {
        errs.push(t("err.aero.count"));
      }
      files.forEach((f, i) => {
        if (f && f.use === true) {
          if (!isNonEmptyStr(f.fn)) errs.push(t("err.aero.fn", { n: i + 1 }));
          if (!isFiniteNum(f.v) || f.v <= 0) errs.push(t("err.aero.v", { n: i + 1 }));
        }
      });
      // 「使用」かつ v が正値のものについて、v が互いに異なること（補間の都合）
      const vs = enabled.map(f => f.v).filter(v => isFiniteNum(v) && v > 0);
      if (vs.length >= 2 && new Set(vs).size < vs.length) {
        errs.push(t("err.aero.dup"));
      }
    }
    return errs;
  }
}
