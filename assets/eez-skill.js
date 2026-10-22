/* "Use with your agent" for the dApp track pages.
 *
 * Adds a secondary button next to the intro's Start button. It opens a dialog
 * that hands the reader the agent skill built from these cards
 * (skills/eez-dapp-quickstart/SKILL.md): a one-line install for Claude Code,
 * the file itself for any other agent, and a link to read it first.
 *
 * Load it on a page with <script src="../assets/eez-skill.js" defer></script>.
 * Pages without #btnStart are left alone.
 */
(function () {
  "use strict";
  var start = document.getElementById("btnStart");
  if (!start || !window.HTMLDialogElement) { return; }

  var NAME = "eez-dapp-quickstart";
  var here = document.currentScript ? document.currentScript.src : location.href;
  var url = new URL("../skills/" + NAME + "/SKILL.md", here).href;
  var install = "mkdir -p .claude/skills/" + NAME + " && curl -fsSL " + url +
    " -o .claude/skills/" + NAME + "/SKILL.md";

  var css = document.createElement("style");
  css.textContent = [
    ".intro-actions{display:flex;align-items:center;flex-wrap:wrap;gap:18px}",
    ".skill-open{font-family:var(--mono);font-size:17px;letter-spacing:.04em;color:#d8d8d8;background:#141414;border:1px solid #2a2a2a;border-radius:100px;padding:16px 28px;cursor:pointer;}",
    ".skill-open:hover{color:#fff;border-color:#444}",
    "@media (max-width:760px){.intro-actions{gap:12px}.skill-open{width:100%;font-size:14px;padding:12px 20px}}",
    "#skillDialog{box-sizing:border-box;width:min(640px,calc(100vw - 32px));max-height:calc(100vh - 32px);overflow:auto;margin:auto;padding:28px;background:#111;color:#e8e8e8;border:1px solid #2e2e2e;border-radius:14px;font-family:var(--sans);font-size:15px;line-height:1.55}",
    "#skillDialog::backdrop{background:rgba(0,0,0,.7)}",
    "#skillDialog h2{margin:0 0 6px;padding-right:88px;font-size:22px;font-weight:700;color:#fff}",
    "#skillDialog p{margin:0 0 18px;color:#b8bfcc}",
    "#skillDialog .k{display:block;margin:0 0 8px;font-family:var(--mono);font-size:12px;letter-spacing:.14em;color:var(--eez-green,#3BE57E)}",
    "#skillDialog .row{display:flex;gap:10px;align-items:stretch;margin:0 0 22px}",
    "#skillDialog code{flex:1;min-width:0;display:block;padding:12px 14px;background:#0a0a0a;border:1px solid #242424;border-radius:8px;font-family:var(--mono);font-size:12.5px;line-height:1.6;color:#d8d8d8;word-break:break-all}",
    "#skillDialog button,#skillDialog a.btn{flex:none;font-family:var(--mono);font-size:12px;letter-spacing:.08em;color:#d8d8d8;background:#161616;border:1px solid #2e2e2e;border-radius:8px;padding:0 14px;min-height:44px;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center}",
    "#skillDialog button:hover,#skillDialog a.btn:hover{color:#fff;border-color:#555}",
    "#skillDialog .acts{display:flex;flex-wrap:wrap;gap:10px;margin:0 0 22px}",
    "#skillDialog .note{font-size:13px;color:#8a93a3;margin:0}",
    "#skillDialog .x{position:absolute;top:14px;right:14px;min-height:36px;padding:0 12px}",
    "#skillDialog .done{color:#0a0a0a;background:var(--eez-green,#3BE57E);border-color:transparent}"
  ].join("\n");
  document.head.appendChild(css);

  var open = document.createElement("button");
  open.type = "button";
  open.className = "skill-open";
  open.textContent = "Use with your agent";
  start.insertAdjacentElement("afterend", open);

  var d = document.createElement("dialog");
  d.id = "skillDialog";
  d.setAttribute("aria-labelledby", "skillTitle");
  d.innerHTML =
    '<button class="x" type="button" aria-label="Close">CLOSE</button>' +
    '<h2 id="skillTitle">Use these walkthroughs with your agent</h2>' +
    "<p>One skill covers the whole dApp track, from the Quickstart cards to the reference pages: how a cross-chain call or read works, the rules for code that makes one, flash-loan and bridge patterns, a local run and a table of reverts. It is a single text file, pinned to eez-core-protocol @ 9a1f815. Nothing runs when you install it.</p>" +
    '<span class="k">CLAUDE CODE &middot; RUN IN YOUR PROJECT</span>' +
    '<div class="row"><code id="skillInstall"></code><button type="button" data-copy="install">COPY</button></div>' +
    '<span class="k">ANY OTHER AGENT</span>' +
    '<div class="acts"><button type="button" data-copy="file">COPY SKILL.MD</button>' +
    '<a class="btn" id="skillView" target="_blank" rel="noopener">READ IT FIRST &#8599;</a></div>' +
    '<p class="note">It defaults to local anvil chains and asks before anything touches EEZ-X mainnet, where transactions cost real ETH.</p>';
  document.body.appendChild(d);
  d.querySelector("#skillInstall").textContent = install;
  d.querySelector("#skillView").href = url;

  // Keys typed in the dialog belong to it, not to the step player behind it.
  d.addEventListener("keydown", function (e) { if (e.key !== "Escape") { e.stopPropagation(); } });
  d.addEventListener("click", function (e) { if (e.target === d) { d.close(); } });
  d.querySelector(".x").addEventListener("click", function () { d.close(); });
  d.addEventListener("close", function () { open.focus(); });
  // Fetch the file when the dialog opens, so COPY can write it while the click
  // still counts as a user gesture (Safari drops it after an await).
  var file = null;
  open.addEventListener("click", function () {
    d.showModal();
    if (!file) {
      file = fetch(url).then(function (r) { if (!r.ok) { throw new Error(r.status); } return r.text(); });
      file.then(function (t) { file.text = t; }, function () { file = null; });
    }
  });

  function flash(btn, text) {
    var was = btn.textContent;
    btn.textContent = text;
    btn.classList.toggle("done", text === "COPIED");
    clearTimeout(btn._reset);
    btn._reset = setTimeout(function () { btn.textContent = was; btn.classList.remove("done"); }, 1400);
  }
  d.querySelectorAll("[data-copy]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var isInstall = btn.getAttribute("data-copy") === "install";
      var ready = isInstall ? install : file && file.text;
      var done = function () { flash(btn, "COPIED"); };
      var fail = function () { flash(btn, "COPY FAILED"); };
      if (ready) { navigator.clipboard.writeText(ready).then(done, fail); return; }
      (file || Promise.reject()).then(function (t) { return navigator.clipboard.writeText(t); }).then(done, fail);
    });
  });
})();
