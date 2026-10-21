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
 *   any step change      the URL becomes #step-n; moving forward adds a
 *                        history entry so Back returns to the previous step
 *   no hash on arrival   nothing happens until the reader starts the page
 *   junk #step-… hash    dropped on arrival, corrected once a step shows
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
    if (n === cur.n) { sync(); return; }
    applying = true;
    document.documentElement.setAttribute("data-eez-applying", "1");
    try {
      var dot = document.querySelector('#dots button[data-step="' + (n - 1) + '"]');
      if (dot) {
        dot.click();
      } else {
        var next = document.getElementById("btnNext");
        for (var i = cur.n; i < n && next; i++) { next.click(); }
      }
    } finally {
      document.documentElement.removeAttribute("data-eez-applying");
    }
    applying = false;
  }

  function fromHash() {
    var m = RE.exec(location.hash);
    if (m) { go(+m[1]); return; }
    if (/^#step/i.test(location.hash)) {
      if (introShowing()) { history.replaceState(null, "", location.pathname + location.search); }
      else { sync(); }
    }
  }

  // A COPIED label belongs to the step it was clicked on.
  function resetCopy() {
    var b = document.getElementById("btnCopy");
    if (!b || b.textContent === "COPY") { return; }
    clearTimeout(b._reset);
    b.textContent = "COPY";
    b.style.color = "var(--muted)";
    b.style.borderColor = "#2e2e2e";
  }

  var firstSync = true;
  function sync() {
    if (applying || introShowing()) { return; }
    var cur = current();
    if (!cur) { return; }
    var want = "#step-" + cur.n;
    if (location.hash !== want) {
      var url = location.pathname + location.search + want;
      // The first step replaces the current entry; later steps add one so the
      // phone back gesture goes to the previous step, not out of the demo.
      if (firstSync && !location.hash && cur.n === 1) {
        history.replaceState({ step: cur.n }, "", url);
      } else {
        history.pushState({ step: cur.n }, "", url);
      }
    }
    firstSync = false;
  }

  if (window.MutationObserver) {
    new MutationObserver(function () { sync(); resetCopy(); })
      .observe(label, { childList: true, characterData: true, subtree: true });
  }
  window.addEventListener("hashchange", fromHash);
  window.addEventListener("popstate", fromHash);
  fromHash();
})();

/* ---------------------------------------------------------------------------
 * Launch-QA corrections shared by every walkthrough.
 *
 * These are deliberately additive: the step engine above and each page's
 * inline script keep owning step state. This layer only fixes the state the
 * reader sees around it:
 *   - the lead-in is an overview, not "step 1 of 3"
 *   - Up next is a next-walkthrough link, so it appears only after step 3
 *   - a phone starts the stage at the top, not halfway down the old scroll
 *   - Space/R autoplay leaves a visible way to pause
 *   - step pills and COPY meet the 44px touch target
 *   - step pills have accessible names
 * ------------------------------------------------------------------------- */
(function () {
  "use strict";

  var intro = document.getElementById("intro");
  var label = document.getElementById("stepLabel");
  var play = document.getElementById("btnPlay");
  var dots = document.getElementById("dots");
  var codePanel = document.getElementById("codePanel");
  var mq = window.matchMedia ? window.matchMedia("(max-width:1120px)") : { matches: false };

  var st = document.createElement("style");
  st.id = "eez-qa-fixes";
  st.textContent = [
    "/* Up next belongs after the last step, not beside step 1. */",
    "#nextDemo{display:none !important}",
    "#stepNav.at-end #nextDemo{display:inline-flex !important}",
    "/* Autoplay is keyboard-reachable; give it a visible pause. */",
    "body.is-playing #btnPlay{display:inline-flex !important;width:44px !important;min-width:44px !important;height:44px !important;min-height:44px !important;padding:0 !important;font-size:0 !important;align-items:center;justify-content:center;}",
    "body.is-playing #btnPlay::after{content:\"❚❚\";font-size:14px;letter-spacing:0;}",
    "/* Next step › (styled in each page) hides on the last step, where Up next takes over. */",
    "#stepNav.at-end #btnNext{display:none !important}",
    "/* Output-only panels stay non-copyable at every viewport width. */",
    "#btnCopy[hidden]{display:none !important}",
    ".ez-sr{position:absolute !important;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0;}",
    "@media (max-width:1120px){",
    "  #dots button{min-width:44px !important;min-height:44px !important;}",
    "  #btnCopy{height:44px !important;min-width:56px !important;padding:0 10px !important;top:2px !important;display:inline-flex !important;align-items:center;justify-content:center;}",
    "  #btnHelp{width:44px !important;height:44px !important;}",
    "  #stepNav > div:first-child{row-gap:12px;}",
    "  #btnStart{min-height:48px !important;}",
    "  .stage-wrap a.back{min-height:44px;display:inline-flex;align-items:center;}",
    "  body.is-playing #btnPlay{position:fixed !important;right:18px !important;bottom:18px !important;width:52px !important;height:52px !important;min-width:52px !important;min-height:52px !important;border-radius:50% !important;z-index:60 !important;box-shadow:0 8px 28px rgba(0,0,0,.5);}",
    "  /* Long command lines are more useful wrapped than clipped. The old */",
    "  /* two-axis scroll region also trapped page scroll on touch. */",
    "  #codePanel{max-height:none !important;height:auto !important;overflow-x:hidden !important;overflow-y:visible !important;}",
    "  #codePanel > div{white-space:pre-wrap !important;}",
    "  #codePanel > div > span:last-child{white-space:pre-wrap !important;overflow-wrap:anywhere;}",
    "  #codePanel::after{display:none !important;}",
    "  /* Keep file:line and the function name; the old nowrap clipped the */",
    "  /* function, which is the trust cue readers click to verify. */",
    "  #srcCite{white-space:normal !important;overflow:visible !important;text-overflow:clip !important;line-height:1.35 !important;}",
    "  #srcCite a{white-space:normal !important;overflow-wrap:anywhere !important;word-break:break-word !important;}",
    "}"
  ].join("\n");
  document.head.appendChild(st);

  if (label && !label.hasAttribute("aria-live")) {
    label.setAttribute("aria-live", "polite");
  }

  /* The lead-in covers the stage but the header still read STEP 1 OF 3.
     Swap the visible text while the overview is open; the step engine reads
     the original string, so restore it before the first real step. */
  var savedLabel = label ? label.textContent : "";
  function syncIntroLabel() {
    if (!intro || !label) { return; }
    if (!intro.hasAttribute("hidden")) {
      if (label.textContent !== "OVERVIEW") {
        savedLabel = label.textContent;
        label.textContent = "OVERVIEW";
      }
    } else if (label.textContent === "OVERVIEW") {
      label.textContent = savedLabel || "STEP 1 OF 3";
    }
  }
  if (intro) {
    new MutationObserver(syncIntroLabel).observe(intro, { attributes: true, attributeFilter: ["hidden"] });
    syncIntroLabel();
  }

  /* A fast double-click on the next-step arrow used to run twice: from step 1
     it skipped step 2, and from step 2 the second click landed on the UP NEXT
     link that appears where the arrow was, leaving the walkthrough. Guard
     repeated pointer clicks on that forward control, not numbered jumps or
     keyboard activation. A numbered jump starts a separate interaction. */
  var lastNextClick = 0;
  document.addEventListener("click", function (e) {
    var t = e.target;
    var control = t && t.closest && t.closest("#btnNext, #dots button, #nextDemo");
    if (!control) { return; }
    // Hash/back-forward navigation clicks a step control programmatically.
    // That is not a user gesture, so it must not arm the double-click guard.
    if (document.documentElement.hasAttribute("data-eez-applying") || e.detail === 0) { return; }
    if (control.closest("#dots")) { lastNextClick = 0; return; }
    var now = Date.now();
    if (now - lastNextClick < 450) {
      e.preventDefault();
      e.stopImmediatePropagation();
      return;
    }
    lastNextClick = control.id === "btnNext" ? now : 0;
  }, true);

  /* On a phone the stage is a normal stacked document. Dismissing the lead-in
     collapses it above the current scroll position, which used to leave the
     reader halfway down step 1. Step pills had the same problem. */
  var scrollQueued = false;
  function scrollStageTop() {
    if (!mq.matches || scrollQueued) { return; }
    scrollQueued = true;
    setTimeout(function () {
      scrollQueued = false;
      window.scrollTo(0, 0);
    }, 80);
  }
  document.addEventListener("click", function (e) {
    var t = e.target;
    if (t && t.closest && t.closest("#btnStart, #dots button, #btnNext, #btnPrev")) {
      scrollStageTop();
    }
  }, true);
  document.addEventListener("keydown", function (e) {
    if (e.key === "ArrowRight" || e.key === "ArrowLeft") { scrollStageTop(); }
  }, true);

  /* Autoplay can be started with Space or R even though the Play button is
     not shown. Reflect the real state so there is a visible pause. */
  if (play) {
    var syncPlay = function () {
      document.body.classList.toggle("is-playing", /pause/i.test(play.textContent || ""));
    };
    new MutationObserver(syncPlay).observe(play, { childList: true, subtree: true, characterData: true });
    syncPlay();
  }

  var nextStep = document.getElementById("btnNext");
  if (nextStep) {
    nextStep.setAttribute("aria-label", "Next step");
    nextStep.setAttribute("title", "Next step");
  }

  /* Bare "1 2 3" is not an accessible name. */
  function labelDots() {
    if (!dots) { return; }
    var buttons = dots.querySelectorAll("button");
    for (var i = 0; i < buttons.length; i++) {
      var title = (buttons[i].getAttribute("title") || "").trim();
      buttons[i].setAttribute("aria-label", "Step " + (i + 1) + " of " + buttons.length + (title ? ": " + title : ""));
    }
    if (!dots.hasAttribute("role")) { dots.setAttribute("role", "group"); }
    if (!dots.hasAttribute("aria-label")) { dots.setAttribute("aria-label", "Walkthrough steps"); }
  }
  if (dots) {
    new MutationObserver(labelDots).observe(dots, { childList: true, subtree: true });
    labelDots();
  }

  if (codePanel) {
    codePanel.setAttribute("aria-label", "Code panel.");
  }

  /* Copy feedback is visual on the button; announce it too. */
  var copyBtn = document.getElementById("btnCopy");
  if (copyBtn) {
    var live = document.createElement("span");
    live.className = "ez-sr";
    live.setAttribute("role", "status");
    live.setAttribute("aria-live", "polite");
    document.body.appendChild(live);
    new MutationObserver(function () {
      var text = (copyBtn.textContent || "").trim();
      if (text && text !== "COPY") { live.textContent = text; }
    }).observe(copyBtn, { childList: true, subtree: true, characterData: true });
  }
})();
