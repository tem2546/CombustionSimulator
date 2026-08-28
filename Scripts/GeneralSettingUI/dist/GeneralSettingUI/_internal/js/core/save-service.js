
// js/core/save-service.js
export class SaveService {
  static saveJSON(payload, suggestedName = "settings.json", msgEl) {
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url; a.download = suggestedName; a.style.display = "none";
    document.body.appendChild(a); a.click(); a.remove();
    URL.revokeObjectURL(url);
    if (msgEl) { msgEl.textContent = `${suggestedName} をダウンロードしました。`; msgEl.style.color = "#1a7f37"; }
  }
}
