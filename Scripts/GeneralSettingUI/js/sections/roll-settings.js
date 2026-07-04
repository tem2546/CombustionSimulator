// js/sections/roll-settings.js
export class RollSettings {
  init(store) {
    this.store = store;
  }

  applyDefaults() {
    // CSモードではロール制御・空力関連の設定は不要なため、処理をスキップ
  }

  collectPayload() {
    // 互換性のため空のオブジェクトを返すか、必要に応じて固定値をパッキング
    return {};
  }

  checkValidity(payload) {
    // 常にバリデーションを通過させる
    return [];
  }
}