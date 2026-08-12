// js/core/info.js
// 各項目の「i」ボタン（.info-btn[data-info=キー]）を押すと、
// その項目の仕様説明を小さなポップオーバーで表示する。
//  - 再クリック / 外側クリック / ESC / リサイズで閉じる
//  - 表示文言は i18n の現在言語に従う

import { t, getLang } from "./i18n.js";

let pop = null;
let openKey = null;

function ensurePop() {
  if (!pop) {
    pop = document.createElement("div");
    pop.className = "info-pop";
    pop.setAttribute("role", "tooltip");
    pop.style.display = "none";
    document.body.appendChild(pop);
  }
  return pop;
}

function closePop() {
  if (pop) pop.style.display = "none";
  openKey = null;
}

function openPop(btn) {
  const key = btn.getAttribute("data-info");
  if (!key) return;

  // 同じボタンの再クリックで閉じる（トグル）
  if (openKey === key && pop && pop.style.display !== "none") {
    closePop();
    return;
  }

  const p = ensurePop();
  p.textContent = t(key);
  p.dataset.lang = getLang();
  p.style.display = "block";
  openKey = key;

  // ボタン直下に配置（画面右端からはみ出さないよう左位置を調整）
  const r = btn.getBoundingClientRect();
  const popW = Math.min(p.offsetWidth || 300, 320);
  const maxLeft = document.documentElement.clientWidth - popW - 8;
  const left = Math.max(8, Math.min(r.left, maxLeft));
  p.style.top = `${window.scrollY + r.bottom + 6}px`;
  p.style.left = `${window.scrollX + left}px`;
}

export function initInfoButtons() {
  document.addEventListener("click", (e) => {
    const btn = e.target.closest(".info-btn");
    if (btn) {
      e.preventDefault();
      e.stopPropagation();
      openPop(btn);
      return;
    }
    // ポップオーバー外のクリックで閉じる
    if (pop && pop.style.display !== "none" && !e.target.closest(".info-pop")) {
      closePop();
    }
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closePop();
  });

  window.addEventListener("resize", closePop);
  window.addEventListener("scroll", closePop, { passive: true });
}

// 言語切替時に開いていれば閉じる（文言の取り違えを防ぐ）
export function refreshInfoOnLangChange() {
  closePop();
}
