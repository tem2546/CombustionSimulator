// js/sections/mode2-settings.js (完全版)
import { byId, setVal } from "../core/dom.js";

export class Mode2Settings {
  init(store) {
    this.store = store;

    const numSelect = byId("compareDataNumSelect");
    const customRow = byId("custom_datanum_row");
    const customInput = byId("customDataNumInput");
    const pickBtn = byId("pickCompareFilesBtn");
    const clearBtn = byId("clearCompareFilesBtn");

    // 設定された個数を安全に取得するヘルパー
    this.getTargetDataNum = () => {
      if (numSelect?.value === "custom") {
        return parseInt(customInput?.value || "2", 10);
      }
      return parseInt(numSelect?.value || "2", 10);
    };

    // 表示トグル処理
    this.toggleRows = () => {
      if (customRow) {
        customRow.style.display = (numSelect?.value === "custom") ? "block" : "none";
      }
      this.renderFileList();
    };

    // ファイルリストの描画
    this.renderFileList = () => {
      const listContainer = byId("compare_files_list");
      if (!listContainer) return;

      const targetNum = this.getTargetDataNum();
      const s = this.store.get();
      const filesArr = s.compare_files || [];

      let html = "";
      for (let i = 0; i < targetNum; i++) {
        const fileObj = filesArr[i];
        if (fileObj && fileObj.fn) {
          html += `<div style="color: #28a745; margin-bottom: 4px;">▶ ${i + 1}機目: <strong>${fileObj.fn}</strong></div>`;
        } else {
          html += `<div style="color: #6c757d; margin-bottom: 4px;">▷ ${i + 1}機目: <span class="file-label">(未選択)</span></div>`;
        }
      }
      listContainer.innerHTML = html;

      if (pickBtn) {
        pickBtn.disabled = (filesArr.length >= targetNum);
        if (filesArr.length >= targetNum) {
          pickBtn.textContent = "全データの選択が完了しました";
        } else {
          pickBtn.textContent = `${filesArr.length + 1}機目のファイルを選択`;
        }
      }
    };

    numSelect?.addEventListener("change", this.toggleRows);
    customInput?.addEventListener("input", this.toggleRows);

    // 順次ファイル選択イベント
    pickBtn?.addEventListener("click", async (e) => {
      if (e.target.disabled) return;
      
      const targetNum = this.getTargetDataNum();
      const s = this.store.get();
      const filesArr = [...(s.compare_files || [])];

      if (filesArr.length >= targetNum) return;

      e.target.disabled = true;
      try {
        if (!window.pywebview?.api) return;

        const abs = await window.pywebview.api.open_file(
          [{ description: "Excel Data", extensions: ["xlsx"] }], false
        );
        if (!abs) return;

        const fname = abs.split(/[\\/]/).pop();
        const dir = abs.slice(0, -(fname.length + 1));

        filesArr.push({ fn: fname, path: dir });
        this.store.apply({ compare_files: filesArr });
        
        this.renderFileList();
      } catch (err) {
        console.error(err);
      } finally {
        e.target.disabled = (filesArr.length >= targetNum);
      }
    });

    // リセットボタン
    clearBtn?.addEventListener("click", () => {
      this.store.apply({ compare_files: [] });
      this.renderFileList();
    });

    this.toggleRows();
  }

  applyDefaults() {
    const s = this.store.get();
    setVal("compareDataNumSelect", s.compareDataNumSelect || "2");
    setVal("customDataNumInput", s.customDataNumInput || 4);

    // グラフチェックボックスの復元
    const graphs = s.compare_graphs || { thrust: true, removed_thrust: false };
    const chkThrust = byId("compare_graph_thrust");
    const chkRemoved = byId("compare_graph_removed");
    if (chkThrust) chkThrust.checked = !!graphs.thrust;
    if (chkRemoved) chkRemoved.checked = !!graphs.removed_thrust;

    if (typeof this.toggleRows === "function") {
      this.toggleRows();
    }
  }

  collectPayload() {
    const s = this.store.get();
    return {
      compareDataNumSelect: byId("compareDataNumSelect")?.value || "2",
      customDataNumInput: parseInt(byId("customDataNumInput")?.value || "4", 10),
      compare_graphs: {
        thrust: !!byId("compare_graph_thrust")?.checked,
        removed_thrust: !!byId("compare_graph_removed")?.checked
      },
      compare_files: s.compare_files || []
    };
  }

  checkValidity(payload) {
    const errs = [];
    if (byId("modeSelect")?.value === "mode2") {
      const numSelect = payload.compareDataNumSelect;
      const targetNum = (numSelect === "custom") ? payload.customDataNumInput : parseInt(numSelect, 10);
      const chosenNum = (payload.compare_files || []).length;

      if (chosenNum < targetNum) {
        errs.push(`比較するデータが不足しています（${targetNum}機中、${chosenNum}機選択済み）。`);
      }
      
      // 少なくとも1つはグラフにチェックが入っているか検証
      if (!payload.compare_graphs.thrust && !payload.compare_graphs.removed_thrust) {
        errs.push("比較出力するグラフを少なくとも1つ選択してください。");
      }
    }
    return errs;
  }
}