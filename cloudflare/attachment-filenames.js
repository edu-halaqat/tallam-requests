(() => {
  "use strict";
  function normalizeNames() {
    const root = document.getElementById("attachmentsGrid");
    if (!root) return;
    root.querySelectorAll(".attachment > span").forEach((name) => {
      if (name.dataset.filenameReady === "1") return;
      const original = (name.textContent || "").trim();
      let displayed = original;
      if (/%[a-f0-9]{2}/i.test(original)) {
        try { displayed = decodeURIComponent(original); } catch { /* invalid encoding: keep original */ }
      }
      name.textContent = displayed;
      name.title = displayed;
      name.dataset.filenameReady = "1";
    });
  }
  function start() {
    const root = document.getElementById("attachmentsGrid");
    if (!root) return;
    new MutationObserver(normalizeNames).observe(root, { childList: true, subtree: true });
    normalizeNames();
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start, { once: true });
  else start();
})();
