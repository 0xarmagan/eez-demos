/* First-run spotlight tour for the EEZ walkthroughs.
 *
 * Three things about this file are load-bearing:
 *
 * 1. Everything it injects lives INSIDE #stage. The stage is a fixed
 *    1920x1080 box that gets scale-transformed to fit the viewport, so an
 *    overlay mounted on <body> would drift off its targets at every window
 *    size. Mounting inside the stage means the tour inherits the same
 *    transform for free, and all geometry can be computed in stage units.
 *
 * 2. The steps are discovered from the DOM, not hardcoded. The pages do not
 *    share a control set: the rollup-operator and protocol-researcher pages
 *    have no FULL button, only q3 has TEST, only q1/q5 have TRY IT. A fixed
 *    script would describe buttons that are not there.
 *
 * 3. It shows once per SITE, not once per page. Someone working through all
 *    24 walkthroughs should meet this once.
 *
 * No dependencies, no build step, ES5-compatible.
 */
(function (root) {
  "use strict";

  var KEY = "eez-demos:tour-seen:v1";
  var PULSE_KEY = "eez-demos:help-pulse:v1";
  var STAGE_W = 1920;
  var CARD_W = 430;
  var GAP = 20;

  // localStorage throws outright in some contexts (private windows, embedded
  // frames, site-data blocked), so every access is guarded and a failure just
  // means "treat as unseen" rather than breaking the page.
  function hasSeen() {
    try { return root.localStorage.getItem(KEY) === "1"; } catch (e) { return false; }
  }
  function markSeen() {
    try { root.localStorage.setItem(KEY, "1"); } catch (e) { /* no-op */ }
  }

  function $(id) { return document.getElementById(id); }

  function scaleOf(stage) {
    var r = stage.getBoundingClientRect();
    return r.width / STAGE_W || 1;
  }

  /* Viewport rect -> stage-local rect, undoing the stage's scale. */
  function rectIn(stage, el) {
    var s = scaleOf(stage);
    var sr = stage.getBoundingClientRect();
    var er = el.getBoundingClientRect();
    return {
      left: (er.left - sr.left) / s,
      top: (er.top - sr.top) / s,
      width: er.width / s,
      height: er.height / s
    };
  }

  /* The walkthroughs render into a scale-transformed #stage; index.html is an
     ordinary scrolling document. Page mode pins the layer to the viewport, so
     rects can be used as-is and there is no transform to undo. */
  function isPageMode() { return !$("stage"); }

  /* Below 1120px the stage stops being a scaled 1920x1080 deck and becomes a
     normal stacked document. The tour must follow that layout: its old
     stage-space layer was 1920px wide inside a 375px page, which widened the
     viewport to ~1500px and pushed the card off-screen. */
  function isNarrowStage() {
    return !!$("stage") && root.matchMedia && root.matchMedia("(max-width:1120px)").matches;
  }

  var activePageMode = null;
  function tourPageMode() {
    return activePageMode === null ? isPageMode() : activePageMode;
  }

  function rectFor(el) {
    if (tourPageMode()) {
      var r = el.getBoundingClientRect();
      return { left: r.left, top: r.top, width: r.width, height: r.height };
    }
    return rectIn($("stage"), el);
  }

  function boundsW() { return tourPageMode() ? (root.innerWidth || STAGE_W) : STAGE_W; }
  function boundsH() { return tourPageMode() ? (root.innerHeight || 1080) : 1080; }

  /* Smallest rect covering every element given. Used for the button cluster,
     which is several separately-positioned buttons. */
  function unionIn(stage, els) {
    var out = null;
    for (var i = 0; i < els.length; i++) {
      if (!els[i]) { continue; }
      var r = rectFor(els[i]);
      if (!out) { out = { left: r.left, top: r.top, right: r.left + r.width, bottom: r.top + r.height }; }
      else {
        out.left = Math.min(out.left, r.left);
        out.top = Math.min(out.top, r.top);
        out.right = Math.max(out.right, r.left + r.width);
        out.bottom = Math.max(out.bottom, r.top + r.height);
      }
    }
    if (!out) { return null; }
    return { left: out.left, top: out.top, width: out.right - out.left, height: out.bottom - out.top };
  }

  function buildIndexSteps() {
    var steps = [];
    var q = function (sel) { return document.querySelector(sel); };
    function add(sel, pad, kicker, body, extra) {
      var el = q(sel);
      if (!el) { return; }
      var st = { els: [el], pad: pad, kicker: kicker, body: body };
      if (extra) { for (var k in extra) { st[k] = extra[k]; } }
      steps.push(st);
    }

    add(".hero-cta", 10, "WHERE TO START",
        "Dapp developers start at 00. Operators and researchers get a reading order on the line below.",
        { els: [q(".hero-cta"), q(".hero-aside")] });
    add(".search-box-row", 10, "SEARCH",
        "Find any walkthrough by keyword. Press / to jump here.");
    add(".filter-tabs", 10, "FILTER BY ROLE",
        "Dapp developers, rollup operators or protocol researchers.");
    add("#quickstart .phase", 12, "THE QUICKSTART",
        "Card 00 opens the Quickstart: seven cards, 00 to 06, in four phases. Read them in order.");
    add("#quickstart .card.soon", 8, "COMING SOON",
        "Dashed cards are not out yet.");
    add("#dapp-developers .sec-head", 12, "REFERENCE",
        "Short answers to questions you hit while building.");
    add("#rollup-operators .sec-head", 12, "ROLLUP OPERATORS",
        "Run the stack: devnet, deploy, Chiado, test calls.");
    add("#protocol-researchers .sec-head", 12, "PROTOCOL RESEARCHERS",
        "How it works inside, component by component.");
    add(".closer", 12, "MORE",
        "llms.txt gives agents every walkthrough as text.");
    add(".navlinks", 10, "THE SOURCE",
        "The contracts, the node, and the live testnet.");
    add('#quickstart a.card[href*="qs0-"]', 8, "START HERE",
        "Open card 00. \u201cHow this page works\u201d there explains the page.",
        { cta: { label: "Open it \u203a",
                 href: "./dapp-developers/qs0-one-call-two-rollups.html" } });
    return steps;
  }

  function buildSteps() {
    if (isPageMode()) { return buildIndexSteps(); }
    var steps = [];

    if ($("stepLabel")) {
      steps.push({
        els: [$("stepLabel")],
        pad: 10,
        kicker: "WHERE YOU ARE",
        body: "Your step. The URL updates, so you can share it."
      });
    }

    if ($("stageCol")) {
      // TRY IT sits on the stage column and swaps the diagram out for a live
      // calculator, so it belongs to this step. Grouping it with the code-panel
      // buttons instead produced one spotlight spanning both columns.
      var diagramEls = [$("stageCol")];
      var diagramBody = "What this step shows. It changes as you move.";
      if ($("btnTry")) {
        diagramEls.push($("btnTry"));
        diagramBody += " TRY IT lets you put in your own values.";
      }
      steps.push({
        els: diagramEls,
        pad: 10,
        kicker: "THE DIAGRAM",
        body: diagramBody
      });
    }

    if ($("codeCard")) {
      steps.push({
        els: [$("codeCard")],
        pad: 8,
        kicker: "THE REAL SOURCE",
        body: "Real code at a pinned commit. Click the citation to check it."
      });
    }

    // One step for the code-panel controls, worded from whichever exist here.
    // btnTry is deliberately excluded — it is on the stage, not this panel.
    var ctrl = [$("btnFull"), $("btnTest"), $("btnCopy")];
    var present = [];
    for (var i = 0; i < ctrl.length; i++) { if (ctrl[i]) { present.push(ctrl[i]); } }
    if (present.length) {
      var lines = [];
      if ($("btnFull")) { lines.push("FULL shows the whole file."); }
      if ($("btnTest")) { lines.push("TEST shows a test you can run."); }
      lines.push("COPY copies the commands or code in the panel, not sample output.");
      steps.push({
        els: present,
        pad: 9,
        kicker: "PANEL CONTROLS",
        body: lines.join(" ")
      });
    }

    if ($("narration")) {
      steps.push({
        els: [$("narration")],
        pad: 12,
        kicker: "NARRATION",
        body: "What just changed, and why."
      });
    }

    if ($("stepNav")) {
      var n = document.querySelectorAll("#dots > button").length;
      steps.push({
        els: [$("stepNav")],
        pad: 14,
        kicker: "MOVE THROUGH IT",
        body: (n ? n + " steps. " : "") + "Next step \u203a moves on; click a number to jump. Arrow keys work too. On the last step, Up next opens the next walkthrough."
      });
    }


    return steps;
  }

  function start(opts) {
    if (document.getElementById("tourLayer")) { return; }
    var pageMode = isPageMode() || isNarrowStage();
    activePageMode = pageMode;
    var stage = pageMode ? document.body : $("stage");
    if (!stage) { activePageMode = null; return; }
    // buildSteps() picks the walkthrough/index script from the real page type;
    // the narrow layout only changes where the spotlight is painted.
    var steps = buildSteps();
    if (!steps.length) { activePageMode = null; return; }

    var onDone = (opts && opts.onDone) || function () {};
    var idx = 0;

    var layer = document.createElement("div");
    layer.id = "tourLayer";
    layer.setAttribute("role", "dialog");
    layer.setAttribute("aria-label", "How this page works");
    layer.setAttribute("aria-modal", "true");
    var opener = document.activeElement;
    layer.style.cssText = pageMode
      ? "position:fixed;left:0;top:0;right:0;bottom:0;z-index:2000;"
      : "position:absolute;left:0;top:0;width:1920px;height:1080px;z-index:200;";

    var hole = document.createElement("div");
    // One element makes the whole spotlight: a transparent box with an
    // enormous spread shadow, so everything outside it dims and the target
    // itself is untouched. No masks, no cloning, transform-safe.
    hole.style.cssText = "position:absolute;border-radius:10px;pointer-events:none;" +
      "box-shadow:0 0 0 9999px rgba(0,0,0,0.74);border:1px solid transparent;" +
      "border-image:linear-gradient(135deg,#8AE5AC 0%,#6283BD 55%,#4439CB 100%) 1;transition:all .22s ease;";

    var card = document.createElement("div");
    card.style.cssText = "position:absolute;width:" + CARD_W + "px;background:#0d0d0d;" +
      "border:1px solid #2e2e2e;border-radius:10px;padding:22px 24px;box-sizing:border-box;" +
      "transition:all .22s ease;";

    layer.appendChild(hole);
    layer.appendChild(card);
    stage.appendChild(layer);

    // The layer covers the stage, so it swallows clicks while the tour is up.
    // Clicking the dimmed area is the obvious way out, so make it one.
    layer.addEventListener("click", function (e) {
      if (e.target === layer) { close(); }
    });

    // A tour opened at desktop width and then narrowed (or vice versa) cannot
    // keep its old coordinate system. Close instead of leaving a 1920px layer
    // inside a 375px page with the controls off-screen.
    function onBreakpoint() {
      var nowPage = isPageMode() || isNarrowStage();
      if (nowPage !== pageMode) { close(); }
    }
    root.addEventListener("resize", onBreakpoint);

    function close() {
      if (layer.parentNode) { layer.parentNode.removeChild(layer); }
      document.removeEventListener("keydown", onKey, true);
      root.removeEventListener("resize", onBreakpoint);
      if (onReflow) {
        root.removeEventListener("scroll", onReflow, true);
        root.removeEventListener("resize", onReflow);
      }
      activePageMode = null;
      markSeen();
      onDone();
      // Hand focus back to whatever opened the tour, or keyboard users land
      // on <body> at the top of the page.
      if (opener && opener.focus && document.contains(opener)) {
        try { opener.focus({ preventScroll: true }); } catch (e) { opener.focus(); }
      }
    }

    function onKey(e) {
      if (e.key === "Escape") { e.stopPropagation(); e.preventDefault(); close(); }
      else if (e.key === "Tab") {
        // Focus stays inside the card while the tour is up (aria-modal).
        var btns = card.querySelectorAll("button");
        if (!btns.length) { return; }
        var i = Array.prototype.indexOf.call(btns, document.activeElement);
        var n = e.shiftKey ? i - 1 : i + 1;
        if (i === -1) { n = 0; }
        btns[(n + btns.length) % btns.length].focus();
        e.stopPropagation(); e.preventDefault();
      }
      else if (e.key === "Enter" && e.target && e.target.closest && e.target.closest("#tourLayer button")) { return; }
      else if (e.key === "ArrowRight" || e.key === "Enter") { e.stopPropagation(); e.preventDefault(); go(1); }
      else if (e.key === "ArrowLeft") { e.stopPropagation(); e.preventDefault(); go(-1); }
      // Every other key stays with the tour: the page's own shortcuts (Space
      // plays, r restarts, / jumps to search) must not act behind the modal.
      // Not preventDefault, so Space still presses a focused tour button.
      else { e.stopPropagation(); }
    }

    function go(d) {
      if (d > 0 && steps[idx] && steps[idx].cta) {
        var href = steps[idx].cta.href;
        close();
        root.location.href = href;
        return;
      }
      idx += d;
      if (idx >= steps.length) { close(); return; }
      if (idx < 0) { idx = 0; }
      draw();
    }

    function draw() {
      var st = steps[idx];
      // On a scrolling page the target may be below the fold; centre it first,
      // then measure, or the spotlight lands on empty space.
      var sheet = pageMode && boundsW() < 640;
      if (sheet && st.els[0]) {
        // On a phone the card docks at the bottom, so put the target near the
        // top instead of the centre. Idempotent, because draw() also runs on scroll.
        var want = st.els[0].getBoundingClientRect().top + (root.scrollY || 0) - 32;
        if (Math.abs((root.scrollY || 0) - want) > 2) { root.scrollTo(0, Math.max(0, want)); }
      } else if (pageMode && st.els[0] && st.els[0].scrollIntoView) {
        try { st.els[0].scrollIntoView({ block: "center", inline: "nearest" }); } catch (e) {
          st.els[0].scrollIntoView();
        }
      }
      var r = unionIn(stage, st.els);
      if (!r) { go(1); return; }
      var pad = st.pad || 10;
      var hx = r.left - pad, hy = r.top - pad, hw = r.width + pad * 2, hh = r.height + pad * 2;
      hole.style.left = hx + "px";
      hole.style.top = hy + "px";
      hole.style.width = hw + "px";
      hole.style.height = hh + "px";

      var had = document.activeElement && card.contains(document.activeElement) ? document.activeElement.id : "";
      var cardW = sheet ? boundsW() - 32 : CARD_W;
      card.style.width = cardW + "px";
      card.innerHTML =
        '<div style="display:flex;align-items:center;justify-content:space-between;gap:14px;margin-bottom:11px;">' +
          '<div style="font-family:var(--mono);font-size:12px;letter-spacing:0.14em;color:#3BE57E;">' + st.kicker + '</div>' +
          '<div style="font-family:var(--mono);font-size:12px;color:var(--muted);">' + (idx + 1) + ' / ' + steps.length + '</div>' +
        '</div>' +
        '<div style="font-size:17px;line-height:1.5;color:#d8d8d8;">' + st.body + '</div>' +
        '<div style="display:flex;align-items:center;justify-content:space-between;margin-top:18px;">' +
          '<button type="button" id="tourSkip" aria-label="Skip tour" style="font-family:var(--mono);font-size:12px;letter-spacing:0.06em;color:var(--muted);background:none;border:none;padding:10px 8px;min-height:44px;min-width:44px;cursor:pointer;text-align:left;">SKIP</button>' +
          '<div style="display:flex;gap:9px;">' +
            (idx > 0 ? '<button type="button" id="tourPrev" style="font-family:var(--mono);font-size:12px;letter-spacing:0.06em;color:#d8d8d8;background:#141414;border:1px solid #2a2a2a;border-radius:100px;padding:10px 16px;min-height:44px;cursor:pointer;">‹ Back</button>' : '') +
            '<button type="button" id="tourNext" style="font-family:var(--mono);font-size:12px;font-weight:600;letter-spacing:0.06em;color:#0A0A0A;background:linear-gradient(90deg,#8AE5AC 0%,#6283BD 100%);border:1px solid #6283BD;border-radius:100px;padding:10px 20px;min-height:44px;cursor:pointer;">' +
              (st.cta ? st.cta.label : (idx === steps.length - 1 ? "Got it" : "Next ›")) + '</button>' +
          '</div>' +
        '</div>';

      // Place the card beside the spotlight, then clamp it inside the stage.
      var ch = card.offsetHeight || 190;
      var cx, cy;
      var BW = boundsW(), BH = boundsH();
      if (sheet) {
        cx = 16;
        cy = BH - 16 - ch;
      } else if (hx + hw + GAP + CARD_W <= BW - 24) {
        // beside, to the right
        cx = hx + hw + GAP;
        cy = hy + hh / 2 - ch / 2;
      } else if (hx - GAP - CARD_W >= 24) {
        // beside, to the left
        cx = hx - GAP - CARD_W;
        cy = hy + hh / 2 - ch / 2;
      } else if (hy + hh + GAP + ch <= BH - 24) {
        // A wide target leaves no room either side, so go under it. Without
        // this the card fell back to overlapping the very thing it describes.
        cx = Math.min(Math.max(24, hx), BW - CARD_W - 24);
        cy = hy + hh + GAP;
      } else if (hy - GAP - ch >= 24) {
        cx = Math.min(Math.max(24, hx), BW - CARD_W - 24);
        cy = hy - GAP - ch;
      } else {
        cx = Math.min(Math.max(24, hx), BW - CARD_W - 24);
        cy = hy + hh / 2 - ch / 2;
      }
      if (!sheet) {
        if (cy < 24) { cy = 24; }
        if (cy + ch > BH - 24) { cy = BH - 24 - ch; }
      }
      card.style.left = cx + "px";
      card.style.top = cy + "px";

      $("tourNext").addEventListener("click", function () { go(1); });
      $("tourSkip").addEventListener("click", close);
      if ($("tourPrev")) { $("tourPrev").addEventListener("click", function () { go(-1); }); }
      // draw() rebuilds the buttons (it also runs on scroll and resize), so put
      // focus back on the same one, or on Next for a new step.
      var f = (had && $(had)) || $("tourNext");
      try { f.focus({ preventScroll: true }); } catch (e) { f.focus(); }
    }

    var onReflow = null;
    if (pageMode) {
      onReflow = function () { if (layer.parentNode) { draw(); } };
      root.addEventListener("scroll", onReflow, true);
      root.addEventListener("resize", onReflow);
    }

    document.addEventListener("keydown", onKey, true);
    draw();
    // Second pass: offsetHeight is only real once the card has content.
    draw();
  }

  /* First-visit affordance: instead of auto-running the tour, pulse the ?
     button a few times so a new reader knows help exists. Once per browser
     (its own key — opening the tour is a separate act), guarded like every
     other storage access. */
  function pulseHelp() {
    var btn = document.getElementById("btnHelp");
    if (!btn) { return; }
    try {
      if (root.localStorage.getItem(PULSE_KEY) === "1") { return; }
      root.localStorage.setItem(PULSE_KEY, "1");
    } catch (e) { return; }
    var st = document.createElement("style");
    st.textContent =
      "@keyframes eezHelpPulse{0%{box-shadow:0 0 0 0 rgba(138,229,172,.75)}" +
      "70%{box-shadow:0 0 0 11px rgba(138,229,172,0)}100%{box-shadow:0 0 0 0 rgba(138,229,172,0)}}";
    document.head.appendChild(st);
    btn.style.animation = "eezHelpPulse 1.6s ease-out 3";
  }
  pulseHelp();

  /* Walkthroughs: the page tour runs only when asked, from the "How this
     page works" button in the bottom bar. It routes through the page's own ?
     handler, which dismisses the lead-in first. */
  if (!isPageMode()) {
    var pt = document.getElementById("btnTourPage");
    if (pt) {
      pt.addEventListener("click", function () {
        var h = document.getElementById("btnHelp");
        if (h) { h.click(); } else { start(); }
      });
    }
  }

  root.EEZTour = {
    start: start,
    hasSeen: hasSeen,
    /* The tour no longer auto-runs anywhere. A cold arrival already meets the
       lead-in slide on a walkthrough and the "first time here?" row on the
       index; stacking a spotlight tour on top of those was the popup pile-up
       this replaced. The ? button (pulsed once above) opens it on demand.
       Kept as a callable no-op so the pages' maybeStart() sites and any
       scaffolded page stay valid. */
    maybeStart: function () { return false; }
  };
})(typeof window !== "undefined" ? window : this);
