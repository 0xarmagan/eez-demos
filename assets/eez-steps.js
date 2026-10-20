/* Shareable step URLs for the EEZ walkthroughs.
 *
 * Every walkthrough keeps its step state inside its own inline script, so this
 * file never touches that state directly. It reads the step from what the page
 * already renders (#stepLabel, "STEP n OF N") and drives the page through the
 * controls a reader would use (#btnStart, the #dots buttons, or the hidden
 * #btnNext as a fallback). That
 * keeps the 24 inline step scripts unedited.
 *
 *   #step-2 on arrival   dismiss the lead-in and open step 2
 *   any step change      the URL becomes #step-n (replaceState, so stepping
 *                        does not fill the back button with history entries)
 *   no hash on arrival   nothing happens until the reader starts the page
 */
(function () {
  "use strict";
  var label = document.getElementById("stepLabel");
  if (!label || !window.history || !history.replaceState) { return; }

  var RE = /^#step-(\d+)$/;
  var applying = false;

  function introShowing() {
    var intro = document.getElementById("intro");
    return !!intro && !intro.hasAttribute("hidden");
  }
  function current() {
    var m = /STEP\s+(\d+)\s+OF\s+(\d+)/i.exec(label.textContent || "");
    return m ? { n: +m[1], total: +m[2] } : null;
  }

  function go(n) {
    var start = document.getElementById("btnStart");
    if (introShowing() && start) { start.click(); }
    var cur = current();
    if (!cur) { return; }
    n = Math.max(1, Math.min(cur.total, n));
    if (n === cur.n) { return; }
    applying = true;
    var dot = document.querySelector('#dots button[data-step="' + (n - 1) + '"]');
    if (dot) {
      dot.click();
    } else {
      var next = document.getElementById("btnNext");
      for (var i = cur.n; i < n && next; i++) { next.click(); }
    }
    applying = false;
  }

  function fromHash() {
    var m = RE.exec(location.hash);
    if (m) { go(+m[1]); }
  }

  function sync() {
    if (applying || introShowing()) { return; }
    var cur = current();
    if (!cur) { return; }
    var want = "#step-" + cur.n;
    if (location.hash !== want) {
      history.replaceState(null, "", location.pathname + location.search + want);
    }
  }

  if (window.MutationObserver) {
    new MutationObserver(sync).observe(label, { childList: true, characterData: true, subtree: true });
  }
  window.addEventListener("hashchange", fromHash);
  fromHash();
})();
