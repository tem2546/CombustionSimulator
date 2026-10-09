// js/sections/mode2-settings.js
import { byId, setVal } from "../core/dom.js";

export class Mode2Settings {
  init(store) {
    this.store = store;

    this.numSelect = byId("compareDataNumSelect");
    this.customRow = byId("custom_datanum_row");
    this.customInput = byId("customDataNumInput");
    this.clearBtn = byId("clearCompareFilesBtn");

    // イベントの監視登録
    this.numSelect?.addEventListener("change", this.renderDynamicUi);
    this.customInput?.addEventListener("input", this.renderDynamicUi);

    // 全クリアボタン
    this.clearBtn?.addEventListener("click", () => {
      this.store.apply({ m2_compare_files_dict: {} });
      this.renderDynamicUi();
    });

    this.renderDynamicUi();
  }
  
  apply(data) {
    setVal("compareDataNumSelect", data.m2_compareDataNumSelect ?? "2");
    setVal("customDataNumInput", data.m2_customDataNumInput ?? "4");
    setVal("compare_sync_spike", data.m2_compare_sync_spike ?? "Yes");
    this.renderDynamicUi();
  }

  collectPayload() {
    const s = this.store.get();
    const targetNum = this.getTargetDataNum();
    const currentDict = s.m2_compare_files_dict || {};

    // MATLAB側がループ処理(Class.datanum)で受け取りやすいように、指定台数分の配列に整列させてエクスポートする
    const packedFiles = [];
    for (let i = 1; i <= targetNum; i++) {
      const fileObj = currentDict[`engine${i}`];
      if (fileObj && fileObj.fn) {
        packedFiles.push(fileObj);
      }
    }

    return {
      compareDataNumSelect: byId("compareDataNumSelect")?.value || "2",
      customDataNumInput: parseInt(byId("customDataNumInput")?.value || "4"),
      compare_sync_spike: byId("compare_sync_spike")?.value || "Yes",
      compare_graphs: {
        thrust: byId("compare_graph_thrust")?.checked || true,
        removed_thrust: byId("compare_graph_removed")?.checked || false
      },
      compare_files: packedFiles // 有効なファイル配列をMATLABへ送出
    };
  }

  checkValidity(payload) {
    const errs = [];
    if (byId("modeSelect")?.value === "2") {
      const numSelect = payload.compareDataNumSelect;
      const targetNum = (numSelect === "custom") ? payload.customDataNumInput : parseInt(numSelect, 10);
      const chosenNum = (payload.compare_files || []).length;

      if (chosenNum < targetNum) {
        errs.push(`比較するデータファイルが不足しています（${targetNum}機中、${chosenNum}機が設定済み）。`);
      }
    }
    return errs;
  }

  // 台数に合わせて画面の入力欄やボタン一覧を再構成する
  renderDynamicUi() {
    // カスタム行のトグル表示
    if (this.customRow) {
      this.customRow.style.display = (this.numSelect?.value === "custom") ? "block" : "none";
    }

    const gridContainer = byId("compare_dynamic_grid");
    if (!gridContainer) return;

    const targetNum = this.getTargetDataNum();
    const s = this.store.get();
    const filesArr = s.m2_compare_files_dict || {}; // 各機のファイルを連想配列で管理

    let html = "";
    for (let i = 1; i <= targetNum; i++) {
      const fileObj = filesArr[`engine${i}`];
      const labelText = fileObj && fileObj.fn 
        ? `<span style="color: #28a745;">✔</span> <strong>${fileObj.fn}</strong>` 
        : `<span style="color: #6c757d;">(未選択)</span>`;

      // 1機ごとの独立したカード型UIを生成
      html += `
        <div style="border: 1px solid #e0e0e0; padding: 10px; border-radius: 6px; background-color: #fcfcfc; display: flex; flex-direction: column; justify-content: space-between; min-height: 90px;">
          <div style="font-weight: bold; margin-bottom: 6px; font-size: 0.85em; color: #333;">▼ ${i}機目 (Engine ${i})</div>
          <button type="button" class="btn js-pick-compare-file-btn" data-engine-idx="${i}" style="width: 100%; padding: 4px 8px; font-size: 0.9em;">選択</button>
          <div style="margin-top: 6px; font-size: 0.8em; word-break: break-all; line-height: 1.3;">${labelText}</div>
        </div>
      `;
    }
    gridContainer.innerHTML = html;

    // 生成したすべてのボタンへイベントリスナーを紐付け（イベントデリゲーションの代替）
    gridContainer.querySelectorAll(".js-pick-compare-file-btn").forEach(btn => {
      btn.addEventListener("click", async (e) => {
        const idx = e.currentTarget.getAttribute("data-engine-idx");
        await this.selectFileForEngine(`engine${idx}`);
      });
    });
  };

  // 現在の設定から、対象となる総台数を安全に取得するヘルパー
  getTargetDataNum() {
    if (this.numSelect?.value === "custom") {
      return Math.max(2, parseInt(this.customInput?.value || "4"));
    }
    return parseInt(this.numSelect?.value || "2", 10);
  };

  // 各機個別のファイル選択処理
  async selectFileForEngine(engineKey) {
    try {
      if (!window.pywebview?.api) return;

      const abs = await window.pywebview.api.open_file(
        { file_types: [`Excel Data (*.xlsx)`, `All files (*.*)`] }
      );
      if (!abs) return;

      const fname = abs.split(/[\\/]/).pop();
      const dir = abs.slice(0, -(fname.length + 1));

      const s = this.store.get();
      const currentDict = { ...(s.m2_compare_files_dict || {}) };
      currentDict[engineKey] = { fn: fname, path: dir };

      console.log(`Current Dict after selection for ${engineKey}:`, currentDict);
      this.store.apply({ m2_compare_files_dict: currentDict });
      this.renderDynamicUi();
    } catch (err) {
      console.error(err);
    }
  };
}