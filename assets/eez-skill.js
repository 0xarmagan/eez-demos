/* "Use with your agent" for the dApp Quickstart cards.
 *
 * Adds a secondary button next to the intro's Start button. It opens a dialog
 * that hands the reader the agent skill built from these cards
 * (skills/eez-dapp-quickstart/SKILL.md): verified text to review and save in
 * the reader's project. No shell installer or automatic instruction update.
 *
 * Load it on a page with <script src="../assets/eez-skill.js" defer></script>.
 * Pages without #btnStart are left alone.
 */
(function () {
  "use strict";
  var start = document.getElementById("btnStart");
  if (!start || !window.HTMLDialogElement) { return; }

  var NAME = "eez-dapp-quickstart";
  // Update only after reviewing SKILL.md. CI checks the digest against the file.
  var SKILL_SHA256 = "cb0e301d1f2a7cff525037e9c62582ff8ae43eaf832487fe8ec5ba391e367364";
  var here = document.currentScript ? document.currentScript.src : location.href;
  var url = new URL("../skills/" + NAME + "/SKILL.md", here).href;
  var destination = ".claude/skills/" + NAME + "/SKILL.md";

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
    "#skillDialog button:disabled{opacity:.55;cursor:not-allowed}",
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
    '<h2 id="skillTitle">Use these cards with your agent</h2>' +
    "<p>One instruction file covers cards 00&ndash;04 and examples at eez-core-protocol @ 9a1f815. Review it before giving it to an agent: an agent may use these instructions to run tools. Copying this text does not execute its commands.</p>" +
    '<span class="k">REVIEW, THEN SAVE IN YOUR PROJECT</span>' +
    '<p>For Claude Code, save the reviewed text at this path. If a file already exists, compare it first. For another agent, attach the reviewed file using that agent&rsquo;s instructions feature.</p>' +
    '<div class="row"><code id="skillDestination"></code></div>' +
    '<div class="acts"><button type="button" data-copy="file" disabled>COPY SKILL.MD</button>' +
    '<a class="btn" id="skillView" target="_blank" rel="noopener">READ IT FIRST &#8599;</a></div>' +
    '<p id="skillStatus" role="status" aria-live="polite"></p>' +
    '<p class="note">The skill respects your project&rsquo;s execution policy and requires authorization for mainnet transactions, which cost real ETH. It does not adopt updates automatically.</p>';
  document.body.appendChild(d);
  d.querySelector("#skillDestination").textContent = destination;
  d.querySelector("#skillView").href = url;
  var copy = d.querySelector('[data-copy="file"]');
  var status = d.querySelector("#skillStatus");

  // Keys typed in the dialog belong to it, not to the step player behind it.
  d.addEventListener("keydown", function (e) { if (e.key !== "Escape") { e.stopPropagation(); } });
  d.addEventListener("click", function (e) { if (e.target === d) { d.close(); } });
  d.querySelector(".x").addEventListener("click", function () { d.close(); });
  d.addEventListener("close", function () { open.focus(); });
  // Load only on request. Verify before enabling COPY; never render fetched
  // content as HTML or fall back to unverified text on an error.
  var file = null;
  var loading = false;
  open.addEventListener("click", function () {
    d.showModal();
    if (file || loading) { return; }
    if (!window.crypto || !window.crypto.subtle || !window.AbortController) {
      status.textContent = "Verification is unavailable. Use HTTPS and a current browser; copying is disabled.";
      return;
    }
    loading = true;
    status.textContent = "Checking the skill file…";
    var controller = new AbortController();
    var timeout = setTimeout(function () { controller.abort(); }, 10000);
    fetch(url, { credentials: "omit", redirect: "error", cache: "no-cache", signal: controller.signal })
      .then(function (r) {
        if (!r.ok || r.redirected) { throw new Error("Skill unavailable"); }
        return r.arrayBuffer();
      })
      .then(function (bytes) {
        if (bytes.byteLength > 65536) { throw new Error("Unexpected skill size"); }
        return crypto.subtle.digest("SHA-256", bytes).then(function (digest) {
          var actual = Array.from(new Uint8Array(digest), function (b) {
            return b.toString(16).padStart(2, "0");
          }).join("");
          if (actual !== SKILL_SHA256) { throw new Error("Skill changed"); }
          file = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
          copy.disabled = false;
          status.textContent = "File matches this site's reviewed copy. Read it before installing.";
        });
      })
      .catch(function () {
        file = null;
        copy.disabled = true;
        status.textContent = "Could not verify the skill. Nothing was copied. Close and reopen to retry.";
      })
      .finally(function () { clearTimeout(timeout); loading = false; });
  });

  function flash(btn, text) {
    btn.textContent = text;
    btn.classList.toggle("done", text === "COPIED");
    clearTimeout(btn._reset);
    btn._reset = setTimeout(function () { btn.textContent = "COPY SKILL.MD"; btn.classList.remove("done"); }, 1400);
  }
  copy.addEventListener("click", function () {
    if (!file || copy.disabled) { return; }
    if (!navigator.clipboard || !navigator.clipboard.writeText) { flash(copy, "COPY FAILED"); return; }
    navigator.clipboard.writeText(file).then(
      function () { flash(copy, "COPIED"); },
      function () { flash(copy, "COPY FAILED"); }
    );
  });
})();
