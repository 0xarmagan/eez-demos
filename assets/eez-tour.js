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
 *    14 walkthroughs should meet this once.
 *
 * No dependencies, no build step, ES5-compatible.
 */
(function (root) {
  "use strict";

  var KEY = "eez-demos:tour-seen:v1";
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

  function rectFor(el) {
    if (isPageMode()) {
      var r = el.getBoundingClientRect();
      return { left: r.left, top: r.top, width: r.width, height: r.height };
    }
    return rectIn($("stage"), el);
  }

  function boundsW() { return isPageMode() ? (root.innerWidth || STAGE_W) : STAGE_W; }
  function boundsH() { return isPageMode() ? (root.innerHeight || 1080) : 1080; }

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

    if (q(".search-box-row")) {
      steps.push({ els: [q(".search-box-row")], pad: 10,
        kicker: "FIND ONE",
        body: "Search all 14 walkthroughs by keyword \u2014 try msg.sender, CREATE2 or Kurtosis. " +
              "Pressing / jumps here from anywhere on the page." });
    }
    if (q(".filter-tabs")) {
      steps.push({ els: [q(".filter-tabs")], pad: 10,
        kicker: "OR BROWSE BY AUDIENCE",
        body: "Three tracks: 6 for dapp developers, 4 for rollup operators, 4 for protocol " +
              "researchers. The counts are live, so a filter never lands you on an empty list." });
    }
    var firstTime = q(".sec-head");
    if (firstTime) {
      steps.push({ els: [firstTime], pad: 12,
        kicker: "NOT SURE WHERE TO START",
        body: "These three are the ones to open first, one per audience. Each takes about a minute." });
    }
    if (q(".card")) {
      steps.push({ els: [q(".card")], pad: 8,
        kicker: "WHAT A CARD IS",
        body: "Every card is a 3-step walkthrough built on real, cited protocol source \u2014 not " +
              "pseudocode. The line under the title tells you what you will come away knowing." });
    }
    return steps;
  }

  function buildSteps() {
    if (isPageMode()) { return buildIndexSteps(); }
    var steps = [];

    if ($("stageCol")) {
      // TRY IT sits on the stage column and swaps the diagram out for a live
      // calculator, so it belongs to this step. Grouping it with the code-panel
      // buttons instead produced one spotlight spanning both columns.
      var diagramEls = [$("stageCol")];
      var diagramBody = "The mechanism, drawn out. This redraws as you move through the steps, so each " +
                        "picture matches the code on the right at that moment.";
      if ($("btnTry")) {
        diagramEls.push($("btnTry"));
        diagramBody += " TRY IT swaps it for a live calculator you can put your own values into.";
      }
      steps.push({
        els: diagramEls,
        pad: 10,
        kicker: "LEFT · WHAT IT DOES",
        body: diagramBody
      });
    }

    if ($("codeCard")) {
      steps.push({
        els: [$("codeCard")],
        pad: 8,
        kicker: "RIGHT · THE REAL SOURCE",
        body: "Not pseudocode. The header names the exact file and line, pinned to a commit — " +
              "click it to open that line on GitHub."
      });
    }

    // One step for the code-panel controls, worded from whichever exist here.
    // btnTry is deliberately excluded — it is on the stage, not this panel.
    var ctrl = [$("btnFull"), $("btnTest"), $("btnCopy")];
    var present = [];
    for (var i = 0; i < ctrl.length; i++) { if (ctrl[i]) { present.push(ctrl[i]); } }
    if (present.length) {
      var lines = [];
      if ($("btnFull")) { lines.push("FULL swaps in the whole compilable file — pragma, imports and all."); }
      if ($("btnTest")) { lines.push("TEST shows a Foundry test you can run that proves this gotcha."); }
      lines.push("COPY always copies exactly what you are looking at.");
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
        kicker: "BOTTOM LEFT · NARRATION",
        body: "One line per step, saying what just changed and why it matters."
      });
    }

    if ($("stepNav")) {
      var n = document.querySelectorAll("#dots > div").length;
      steps.push({
        els: [$("stepNav")],
        pad: 14,
        kicker: "BOTTOM RIGHT · MOVING THROUGH IT",
        body: (n ? n + " steps. " : "") + "Next and Prev step manually, Play advances on its own. " +
              "The arrow keys work too, and the dots show where you are."
      });
    }

    return steps;
  }

  function start(opts) {
    var pageMode = isPageMode();
    var stage = pageMode ? document.body : $("stage");
    if (!stage) { return; }
    var steps = buildSteps();
    if (!steps.length) { return; }

    var onDone = (opts && opts.onDone) || function () {};
    var idx = 0;

    var layer = document.createElement("div");
    layer.id = "tourLayer";
    layer.setAttribute("role", "dialog");
    layer.setAttribute("aria-label", "How to read this page");
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

    function close() {
      if (layer.parentNode) { layer.parentNode.removeChild(layer); }
      document.removeEventListener("keydown", onKey, true);
      if (onReflow) {
        root.removeEventListener("scroll", onReflow, true);
        root.removeEventListener("resize", onReflow);
      }
      markSeen();
      onDone();
    }

    function onKey(e) {
      if (e.key === "Escape") { e.stopPropagation(); e.preventDefault(); close(); }
      else if (e.key === "ArrowRight" || e.key === "Enter") { e.stopPropagation(); e.preventDefault(); go(1); }
      else if (e.key === "ArrowLeft") { e.stopPropagation(); e.preventDefault(); go(-1); }
    }

    function go(d) {
      idx += d;
      if (idx >= steps.length) { close(); return; }
      if (idx < 0) { idx = 0; }
      draw();
    }

    function draw() {
      var st = steps[idx];
      // On a scrolling page the target may be below the fold; centre it first,
      // then measure, or the spotlight lands on empty space.
      if (pageMode && st.els[0] && st.els[0].scrollIntoView) {
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

      card.innerHTML =
        '<div style="display:flex;align-items:center;justify-content:space-between;gap:14px;margin-bottom:11px;">' +
          '<div style="font-family:var(--mono);font-size:12px;letter-spacing:0.14em;color:#3BE57E;">' + st.kicker + '</div>' +
          '<div style="font-family:var(--mono);font-size:12px;color:#5b6572;">' + (idx + 1) + ' / ' + steps.length + '</div>' +
        '</div>' +
        '<div style="font-size:17px;line-height:1.5;color:#d8d8d8;">' + st.body + '</div>' +
        '<div style="display:flex;align-items:center;justify-content:space-between;margin-top:18px;">' +
          '<button type="button" id="tourSkip" style="font-family:var(--mono);font-size:12px;letter-spacing:0.06em;color:#5b6572;background:none;border:none;padding:0;cursor:pointer;">SKIP</button>' +
          '<div style="display:flex;gap:9px;">' +
            (idx > 0 ? '<button type="button" id="tourPrev" style="font-family:var(--mono);font-size:12px;letter-spacing:0.06em;color:#d8d8d8;background:#141414;border:1px solid #2a2a2a;border-radius:100px;padding:8px 16px;cursor:pointer;">‹ Back</button>' : '') +
            '<button type="button" id="tourNext" style="font-family:var(--mono);font-size:12px;font-weight:600;letter-spacing:0.06em;color:#0A0A0A;background:linear-gradient(90deg,#8AE5AC 0%,#6283BD 100%);border:1px solid #6283BD;border-radius:100px;padding:8px 18px;cursor:pointer;">' +
              (idx === steps.length - 1 ? "Got it" : "Next ›") + '</button>' +
          '</div>' +
        '</div>';

      // Place the card beside the spotlight, then clamp it inside the stage.
      var ch = card.offsetHeight || 190;
      var cx, cy;
      var BW = boundsW(), BH = boundsH();
      if (hx + hw + GAP + CARD_W <= BW - 24) {
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
      if (cy < 24) { cy = 24; }
      if (cy + ch > BH - 24) { cy = BH - 24 - ch; }
      card.style.left = cx + "px";
      card.style.top = cy + "px";

      $("tourNext").addEventListener("click", function () { go(1); });
      $("tourSkip").addEventListener("click", close);
      if ($("tourPrev")) { $("tourPrev").addEventListener("click", function () { go(-1); }); }
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

  root.EEZTour = {
    start: start,
    hasSeen: hasSeen,
    /* Auto-run on a first visit only. Skipped narrow, where the layout stacks
       and "left / right" would be a lie. */
    maybeStart: function (opts) {
      if (hasSeen()) { return false; }
      if (!isPageMode() && root.innerWidth && root.innerWidth <= 820) { return false; }
      start(opts);
      return true;
    }
  };
})(typeof window !== "undefined" ? window : this);
