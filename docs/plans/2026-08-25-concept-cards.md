# Concept Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the landing page explain each concept on its card, retitle every card as the question a developer actually asks, and move the CREATE2 derivation demo out of the dapp track into the research track behind a new opener built on the functions developers actually call.

**Architecture:** Four sequential changes to a static site with no build step. First move the derivation demo and leave a redirect stub; then add the new dapp opener as a normal 3-step walkthrough; then rewrite `index.html` cards; then align every demo's `<title>` with its card. Each task ends green against the repo's existing verification scripts, which are this project's test suite.

**Tech Stack:** Static HTML/CSS/vanilla JS (no framework, no bundler, one self-contained file per walkthrough). Python 3 verification scripts. Foundry (`forge`) for Solidity snippets. Node + a cached Puppeteer for headless panel checks.

**Spec:** `docs/specs/2026-08-25-concept-cards-design.md`

**Branch:** `concept-cards` (already created, spec committed at `e2d5014`)

## Global Constraints

- **Every walkthrough file is fully self-contained.** Per-file `<style>` and `<script>`. Do not introduce a shared stylesheet. Shared JS is limited to the existing `assets/eez-*.js`.
- **Code panel design target: 16 lines.** The panel is fixed-height with `overflow-y:auto`, so a 17th line scrolls below the fold rather than clipping — easy to miss inside a scale-transformed stage, and `audit.sh` does not catch it. Line width ~50 chars before the right edge cuts. (Corrected mid-execution: earlier text claimed `overflow-y:hidden`, which stopped being true at commit f6f3820.)
- **Citations are SHA-pinned, never branch-pinned.** `eez-core-protocol` = `9735f53abbb6b9f5e863f405ad4555b4701b7fda`. Never point a citation link at a mutable branch.
- **Solidity snippets compile under solc 0.8.28** and carry no forge-std, no submodules.
- **Colour tokens are the existing ones.** `--eez-canvas:#0A0A0A`, `--eez-screen:#161616`, `--eez-edge:#2E2E2E`, `--eez-green:#3BE57E`, `--muted:#9aa3b3`. Do not invent new greys.
- **Card explanation type: 14.5px on `--muted`** (7.3:1 on the card). Answer line: 15.5px `#eef2f7`, weight 500.
- **No marketing language.** `audit.sh` fails the build on it. EEZ is pre-mainnet — design tense, never shipped-behaviour tense.
- **Do not renumber files to match display order.** Display order and filename deliberately differ; `DESIGN.md` records this.
- **Commit style:** explicit paths only, never `git add -A` or `git add .` — the tree may carry another session's work.

---

### Task 1: Move the derivation demo to the research track

**Files:**
- Rename: `dapp-developers/q1-compute-your-cross-chain-address.html` → `protocol-researchers/pr5-how-the-address-is-derived.html`
- Create: `dapp-developers/q1-compute-your-cross-chain-address.html` (redirect stub)
- Modify: `protocol-researchers/pr3-the-deriver.html:81` area (add NEXT link)
- Modify: `scripts/check-panel-drift.py:40`
- Modify: `scripts/new-demo.sh:29`
- Modify: `CONTRIBUTING.md:26`
- Modify: `snippets/q1-compute-address.sol:4`

**Interfaces:**
- Consumes: nothing.
- Produces: the path `protocol-researchers/pr5-how-the-address-is-derived.html`, which Task 3 links from the research section and Task 4 retitles. The old dapp path continues to resolve via stub.

- [ ] **Step 1: Move the file with git so history follows**

```bash
cd /Users/armagan/Documents/eez-demos
git mv dapp-developers/q1-compute-your-cross-chain-address.html \
       protocol-researchers/pr5-how-the-address-is-derived.html
```

- [ ] **Step 2: Fix the moved file's own broken links**

The file was written for `dapp-developers/`. Two links are now wrong.

In `protocol-researchers/pr5-how-the-address-is-derived.html`, find the NEXT link (was line 80):

```html
      <a class="back" href="q2-send-a-cross-chain-call.html" style="border-left:1px solid #2a2a2a;padding-left:22px;">NEXT: Send a Cross-Chain Call →</a>
```

`pr5` is the last demo in the research track, so it ends the chain. Delete that entire `<a class="back">` element.

Then find the self-referencing comment in `codeByStep` (was line 327) and update the path:

```javascript
      "// Panel source for: protocol-researchers/pr5-how-the-address-is-derived.html",
```

- [ ] **Step 3: Point pr3 at the new pr5**

`pr3` currently ends the research chain and has no NEXT link. Open `protocol-researchers/pr3-the-deriver.html`, find the `<div id="stepLabel">` line in the bottom bar, and add a sibling immediately after it, matching the markup other demos use:

```html
      <a class="back" href="pr5-how-the-address-is-derived.html" style="border-left:1px solid #2a2a2a;padding-left:22px;">NEXT: How the Address Is Derived →</a>
```

- [ ] **Step 4: Write the redirect stub at the old path**

Create `dapp-developers/q1-compute-your-cross-chain-address.html`. The href is **relative** — the GitHub Pages mirror serves from `/eez-demos/`, not the domain root, so an absolute path breaks there.

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="0; url=../protocol-researchers/pr5-how-the-address-is-derived.html">
<link rel="canonical" href="../protocol-researchers/pr5-how-the-address-is-derived.html">
<title>Moved — How the Address Is Derived</title>
<link rel="icon" href="../favicon.svg" type="image/svg+xml">
<style>
  body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
       background:#0A0A0A;color:#9aa3b3;
       font-family:'Geist',system-ui,-apple-system,'Segoe UI',sans-serif;
       font-size:15px;line-height:1.6;text-align:center;padding:24px}
  a{color:#3BE57E}
</style>
</head>
<body>
  <p>
    This walkthrough moved to the protocol-researcher track.<br>
    <a href="../protocol-researchers/pr5-how-the-address-is-derived.html">How the Address Is Derived →</a>
  </p>
</body>
</html>
```

- [ ] **Step 5: Update the three scripts and docs that point at the old path**

`scripts/check-panel-drift.py:40` — the map is keyed by basename:

```python
    "pr5-how-the-address-is-derived.html": "q1-compute-address.sol",
```

`scripts/new-demo.sh:29` — this file is the scaffold template for every new walkthrough:

```bash
TEMPLATE="$REPO_ROOT/protocol-researchers/pr5-how-the-address-is-derived.html"
```

`CONTRIBUTING.md:26` — replace the phrase `copy \`dapp-developers/q1-compute-your-cross-chain-address.html\` as the template` with `copy \`protocol-researchers/pr5-how-the-address-is-derived.html\` as the template`. Leave the rest of that sentence alone.

`snippets/q1-compute-address.sol:4` — the header comment names the page it backs:

```solidity
// Panel source for: protocol-researchers/pr5-how-the-address-is-derived.html
```

- [ ] **Step 6: Run the verification suite and confirm it passes**

```bash
bash scripts/audit.sh
python3 scripts/check-panel-drift.py
```

Expected: `Structural audit passed.` and `Every panel line is backed by a line in a compilable snippet.` with `pages checked: 6`.

If `audit.sh` reports a broken internal link, the stub's relative href or the pr3 NEXT href is wrong — fix and re-run.

- [ ] **Step 7: Regenerate llms.txt and verify it is clean**

```bash
python3 scripts/build-llms.py
python3 scripts/build-llms.py --check
```

Expected from `--check`: `llms.txt and llms-full.txt are current (14 walkthroughs).`

Note: still 14 here. The stub is not a walkthrough and must not appear as one. If the count reads 15, `build-llms.py` picked up the stub — confirm the stub has no `#stage` element and re-run.

- [ ] **Step 8: Commit**

```bash
git add dapp-developers/q1-compute-your-cross-chain-address.html \
        protocol-researchers/pr5-how-the-address-is-derived.html \
        protocol-researchers/pr3-the-deriver.html \
        scripts/check-panel-drift.py scripts/new-demo.sh \
        CONTRIBUTING.md snippets/q1-compute-address.sol \
        llms.txt llms-full.txt
git commit -m "Move the address derivation to the research track

A dapp developer calls computeCrossChainProxyAddress; they do not
hand-roll a CREATE2 preimage. 'Why is this deterministic' is a
protocol-researcher question, so the demo goes where that question
belongs. The old URL is public and published in llms.txt, so a
relative meta-refresh stub stays behind — relative because the Pages
mirror serves from /eez-demos/, not the domain root."
```

---

### Task 2: Add the new dapp opener

**Files:**
- Create: `dapp-developers/q7-your-cross-chain-address.html`
- Create: `snippets/q7-create-proxy.sol`
- Create: `scripts/check-panel-height.cjs`
- Modify: `scripts/check-panel-drift.py` (SNIPPET_MAP)

**Interfaces:**
- Consumes: the template at `protocol-researchers/pr5-how-the-address-is-derived.html` (moved in Task 1) via `scripts/new-demo.sh`.
- Produces: the path `dapp-developers/q7-your-cross-chain-address.html`, linked as card 01 by Task 3 and titled by Task 4. Produces `scripts/check-panel-height.cjs`, used by Task 5's final gate.

- [ ] **Step 1: Write the compilable snippet first**

Create `snippets/q7-create-proxy.sol`. It mirrors the two upstream functions this demo cites. `CrossChainProxy` is a stand-in — only its `creationCode` matters — matching how `snippets/q1-compute-address.sol` already does it.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: dapp-developers/q7-your-cross-chain-address.html
// Mirrors eez-core-protocol/src/base/EEZBase.sol:156 and :176
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// The two calls a dapp developer makes. Neither requires knowing how the
// address is derived — that is protocol-researcher territory.

/// @dev Stand-in for the real proxy. Only `type(...).creationCode` matters here.
contract CrossChainProxy {
    address public immutable manager;

    constructor(address manager_) {
        manager = manager_;
    }
}

contract CreateProxySnippet {
    /// @notice Error when a proxy is requested for an address on THIS
    ///         manager's own network.
    error SameNetworkProxy(uint64 rollupId);

    mapping(address => bool) public authorizedProxies;

    event CrossChainProxyCreated(address indexed proxy, address indexed originalAddress, uint64 originalRollupId);

    function _getRollupId() internal pure returns (uint64) {
        return 0;
    }

    function createCrossChainProxy(address originalAddress, uint64 originalRollupId)
        external
        returns (address proxy)
    {
        if (originalRollupId == _getRollupId()) revert SameNetworkProxy(originalRollupId);
        bytes32 salt = keccak256(abi.encodePacked(originalRollupId, originalAddress));
        proxy = address(new CrossChainProxy{salt: salt}(address(this)));
        authorizedProxies[proxy] = true;
        emit CrossChainProxyCreated(proxy, originalAddress, originalRollupId);
    }

    function computeCrossChainProxyAddress(address originalAddress, uint64 originalRollupId)
        public
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(originalRollupId, originalAddress));
        bytes32 bytecodeHash =
            keccak256(abi.encodePacked(type(CrossChainProxy).creationCode, abi.encode(address(this))));
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }
}
```

- [ ] **Step 2: Verify the snippet compiles**

```bash
cd snippets && forge build && cd ..
```

Expected: compiles clean under 0.8.28. If `new CrossChainProxy{salt: salt}` errors, the stand-in contract is declared after its use — move it above `CreateProxySnippet`.

- [ ] **Step 3: Scaffold the walkthrough**

```bash
scripts/new-demo.sh dapp-developers q7-your-cross-chain-address "Your Address on Every Rollup"
```

This produces a structurally-correct file with every piece of real content replaced by `TODO`. It does **not** wire the file into `index.html` or the NEXT chain — Task 3 does that.

- [ ] **Step 4: Write the three steps**

In `dapp-developers/q7-your-cross-chain-address.html`, replace the scaffold's `kickers`, `captions` and `codeByStep`:

```javascript
  var kickers = ["CALL IT INTO EXISTENCE", "OR READ IT FIRST", "THE ONE RULE"];
  var captions = [
    "One call deploys the proxy and registers it — you get the address back.",
    "Or read the address before anything is deployed. It is a view call.",
    "Remote addresses only. A proxy for your own network reverts."
  ];

  var codeByStep = [
    [
      "function createCrossChainProxy(",
      "    address originalAddress,",
      "    uint64 originalRollupId",
      ") external returns (address proxy);"
    ],
    [
      "function createCrossChainProxy(",
      "    address originalAddress,",
      "    uint64 originalRollupId",
      ") external returns (address proxy);",
      "",
      "function computeCrossChainProxyAddress(",
      "    address originalAddress,",
      "    uint64 originalRollupId",
      ") external view returns (address);"
    ],
    [
      "function createCrossChainProxy(",
      "    address originalAddress,",
      "    uint64 originalRollupId",
      ") external returns (address proxy);",
      "",
      "function computeCrossChainProxyAddress(",
      "    address originalAddress,",
      "    uint64 originalRollupId",
      ") external view returns (address);",
      "",
      "// A proxy stands in for a REMOTE address.",
      "if (originalRollupId == _getRollupId())",
      "    revert SameNetworkProxy(originalRollupId);"
    ]
  ];
```

Step 3's panel is 13 lines — inside the 16-line cap, with room to spare.

Set the static step label near the bottom bar to `01 / 03` (the scaffold may carry a TODO there).

- [ ] **Step 5: Set the citation and the NEXT link**

The authoritative citation is the code panel's header. Point it at the create entry point, pinned:

```
eez-core-protocol/src/base/EEZBase.sol:156
```

with href `https://github.com/eez-association/eez-core-protocol/blob/9735f53abbb6b9f5e863f405ad4555b4701b7fda/src/base/EEZBase.sol#L156`.

Copy the exact `<div id="srcCite" data-demo-cite="...">` markup shape from `dapp-developers/q2-send-a-cross-chain-call.html` — the attribute holds an escaped copy of the same anchor, and `verify-citations.py` reads both.

`q7` is the first demo in the dapp track, so its NEXT points at `q2`:

```html
      <a class="back" href="q2-send-a-cross-chain-call.html" style="border-left:1px solid #2a2a2a;padding-left:22px;">NEXT: Send a Cross-Chain Call →</a>
```

- [ ] **Step 6: Draw the diagram**

Three states, matching the captions. The repo rule is real data, never placeholder boxes — reuse the address values already used in `pr5-how-the-address-is-derived.html` so the two demos agree.

1. Your contract on rollup 1, its stand-in on rollup 2, the same address under both.
2. The same picture with the address shown as *readable before deployment* — the stand-in drawn as an outline rather than a solid.
3. The same picture with a third rollup — your own — struck through, labelled `SameNetworkProxy`.

Use `--eez-green` for the live path and `#8B7B55` amber for the rejected same-network case. **Never red** — that is a brand rule.

- [ ] **Step 7: Register the page for drift checking**

In `scripts/check-panel-drift.py`, add to `SNIPPET_MAP`:

```python
    "q7-your-cross-chain-address.html": "q7-create-proxy.sol",
```

- [ ] **Step 8: Write the headless panel-height checker**

The 16-line cap is silently enforced and `audit.sh` does not catch it. This repo has hit that twice. Create `scripts/check-panel-height.cjs`:

```javascript
#!/usr/bin/env node
/* Assert no walkthrough's code panel clips at any step.
 *
 * The panel is fixed-height with overflow-y:hidden: 16 lines fit, 17 clip,
 * and the ~11px overflow is invisible in a screenshot. audit.sh cannot see
 * this — it has passed on a file that was actively clipping.
 *
 * Usage: node scripts/check-panel-height.cjs [file.html ...]
 *        (no args = every tracked walkthrough)
 */
const { execSync } = require("child_process");
const path = require("path");
const puppeteer = require("puppeteer");

async function main() {
  let files = process.argv.slice(2);
  if (files.length === 0) {
    files = execSync("git ls-files '*/q*.html' '*/ro*.html' '*/pr*.html'", { encoding: "utf8" })
      .split("\n").filter(Boolean);
  }

  const browser = await puppeteer.launch({ args: ["--no-sandbox"] });
  let failures = 0;

  for (const f of files) {
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });
    await page.goto("file://" + path.resolve(f), { waitUntil: "load" });

    const steps = await page.$$eval("#dots > div", (d) => d.length);
    for (let i = 0; i < steps; i++) {
      if (i > 0) await page.click("#btnNext");
      await new Promise((r) => setTimeout(r, 120));
      const m = await page.$eval("#codePanel", (el) => ({
        scroll: el.scrollHeight, client: el.clientHeight
      }));
      if (m.scroll > m.client) {
        console.error(`CLIP  ${f}  step ${i + 1}/${steps}  ${m.scroll} > ${m.client}`);
        failures++;
      }
    }
    await page.close();
  }

  await browser.close();
  console.log(failures === 0
    ? `No clipping across ${files.length} file(s).`
    : `${failures} clipping state(s).`);
  process.exit(failures === 0 ? 0 : 1);
}

main();
```

- [ ] **Step 9: Run every gate and confirm each passes**

```bash
bash scripts/audit.sh
python3 scripts/check-panel-drift.py
python3 scripts/verify-citations.py
cd snippets && forge test && cd ..
node scripts/check-panel-height.cjs dapp-developers/q7-your-cross-chain-address.html
```

Expected: audit passes · `pages checked: 7` · citations resolve at the pinned SHA · 13 tests pass · `No clipping across 1 file(s).`

If puppeteer is missing, it is already cached — resolve it from `~/.npm/_npx/` rather than installing Chromium fresh.

- [ ] **Step 10: Regenerate llms.txt**

```bash
python3 scripts/build-llms.py
python3 scripts/build-llms.py --check
```

Expected: `llms.txt and llms-full.txt are current (15 walkthroughs).`

- [ ] **Step 11: Commit**

```bash
git add dapp-developers/q7-your-cross-chain-address.html \
        snippets/q7-create-proxy.sol \
        scripts/check-panel-height.cjs scripts/check-panel-drift.py \
        llms.txt llms-full.txt
git commit -m "Add the dapp opener: the two calls you actually make

createCrossChainProxy had zero coverage across all 14 demos — the one
function that brings a proxy into existence was absent from a track
about using proxies. This demo is the calls, not the derivation:
create it, or read the address before it exists, and the one rule
that a proxy stands in for a REMOTE address.

Also adds check-panel-height.cjs, which catches the silent 16-line
panel clip that audit.sh cannot see."
```

---

### Task 3: Rewrite the landing page cards

**Files:**
- Modify: `index.html` — CSS (after line 77), filter counts (lines 131-133), starter row (~line 153), all three card sections

**Interfaces:**
- Consumes: the paths produced by Tasks 1 and 2.
- Produces: the fifteen question titles that Task 4 copies into each demo's `<title>`.

- [ ] **Step 1: Add the two new card CSS rules**

In `index.html`, immediately after the `.card-hook` rule (line 77), add:

```css
.card-answer{font-size:15.5px;line-height:1.5;color:#eef2f7;margin:0;font-weight:500;letter-spacing:-.005em;text-wrap:pretty}
.card-answer code{font-family:var(--mono);font-size:.9em;color:#fff}
.card-detail{font-size:14.5px;line-height:1.62;color:var(--muted);margin:0;text-wrap:pretty}
.card-detail code{font-family:var(--mono);font-size:.9em;color:#cfd6e4}
```

Keep `.card-hook` — the starter row still uses it.

- [ ] **Step 2: Update the filter counts**

Lines 131-133. Dapp stays 6 (loses the derivation demo, gains the opener); research goes 4 → 5:

```html
      <button class="filter-btn" data-filter="dapp-developers">DAPP DEVS (6)</button>
      <button class="filter-btn" data-filter="rollup-operators">ROLLUP OPS (4)</button>
      <button class="filter-btn" data-filter="protocol-researchers">PROTOCOL RESEARCHERS (5)</button>
```

- [ ] **Step 3: Repoint the starter row**

Line 153 links the old `q1`. The starter row shows the real 01 from each track, so it must now link the new opener, with its question title and answer:

```html
    <a class="card" href="./dapp-developers/q7-your-cross-chain-address.html">
      <div class="card-head"><h3 class="card-title">What address does my contract have on another rollup?</h3><span class="badge">DAPP DEVS</span></div>
      <p class="card-hook">You already have one on each — derived from your address, and computable before anything is deployed.</p>
      <div class="cta">WATCH THE 3-STEP WALKTHROUGH <span class="circ">→</span></div>
    </a>
```

Leave the other two starter cards' hrefs alone, but update their titles to the questions from the table in Step 5 (`How do I run the whole stack locally?` and `Which component does what?`).

- [ ] **Step 4: Convert every numbered card to the answer-first shape**

Each card in the three sections becomes this shape — `card-hook` is replaced by two paragraphs:

```html
      <a class="card" href="./<track>/<file>.html">
        <div class="card-head"><h3 class="card-title"><span class="card-num">NN</span>QUESTION</h3></div>
        <p class="card-answer">ANSWER</p>
        <p class="card-detail">DETAIL</p>
        <div class="cta">WATCH THE 3-STEP WALKTHROUGH <span class="circ">→</span></div>
      </a>
```

- [ ] **Step 5: Fill in all fifteen cards from this table**

Text is verbatim. Wrap the named symbols in `<code>` where they appear.

**Dapp developers** (`./dapp-developers/`)

| NN | file | QUESTION | ANSWER | DETAIL |
|---|---|---|---|---|
| 01 | `q7-your-cross-chain-address` | What address does my contract have on another rollup? | You already have one on each — derived from your address, and computable before anything is deployed. | The stand-in is a proxy, and its address is derived from yours plus the rollup it lives on, so nothing has to be registered. Read it with `computeCrossChainProxyAddress`, deploy it with `createCrossChainProxy` — or do neither, because the protocol creates one on the first inbound call. |
| 02 | `q2-send-a-cross-chain-call` | How do I call a contract on another rollup? | Encode it like any normal call and send it to the proxy address. | There is no cross-chain ABI to learn — the proxy's fallback catches everything and routes it. It even works out whether you meant a read: one self-call probes a transient write, and if that reverts, the call goes to a read-only lookup instead of a real execution. |
| 03 | `q3-fix-the-msg-sender-gotcha` | Who is `msg.sender` when the call comes from another chain? | The proxy — never your original address. | A call from another rollup arrives through the proxy, so that is who the destination sees. A `require(msg.sender == owner)` written for same-chain use passes locally and reverts every time cross-chain. Whitelist the proxy instead. |
| 04 | `q4-check-if-an-address-is-a-proxy` | How do I check an address is a real proxy? | Read the registry — every proxy is recorded when it is created. | One public mapping, no simulation and no guessing. When `isProxy` is true, the other two fields — the original address and its rollup id — are real. |
| 05 | `q6-why-you-cant-call-the-manager-directly` | What does the manager accept? | Calls that arrive through a registered proxy. Nothing else reaches execution. | Call the manager's entry point directly and it reverts with `UnauthorizedProxy()`. Both proxy entry points open with that same check, so no call reaches execution without passing it. |
| 06 | `q5-encode-a-calls-content-hash` | How do I encode a call's content hash? | Eight fields, hashed in one fixed order, identify a cross-chain call. | Hash them together and you get the `bytes32` that identifies the call. The order is load-bearing: reorder the fields and the hash changes silently — no error, just a hash that nothing matches. |

Note cards 05 and 06: the display order deliberately does not match the filenames. Do not "fix" it.

**Rollup operators** (`./rollup-operators/`)

| NN | file | QUESTION | ANSWER | DETAIL |
|---|---|---|---|---|
| 01 | `ro1-run-the-devnet-with-kurtosis` | How do I run the whole stack locally? | One Kurtosis command brings up all of it. | Sequencer, composer, proof-signer and an embedded L1 in one disposable network. A single script deploys the contracts, generates the L2 genesis and boots everything together — the same components you would run against a real testnet, without one. |
| 02 | `ro2-deploy-the-protocol` | How do I deploy the protocol? | One command deploys the core protocol, the proof system and your manager. | `make deploy-protocol` writes every address it produces into a gitignored `deployments.env`, and `make run-node` reads that file at startup — so there is no paste-the-address-into-.env step. |
| 03 | `ro3-run-a-real-chiado-l2` | How do I run this against a real testnet? | The same stack, pointed at Chiado instead of a sandbox. | One-time build tooling, then deploy-protocol writes `deployments.env` and `genesis.json` before docker compose starts the node, signer and lighthouse. `cast block-number` against both ports confirms the embedded L1 is climbing and the L2 is producing. |
| 04 | `ro4-send-and-test-cross-chain-calls` | How do I send and test a cross-chain call? | Two proxy fronts, one script, real pass/fail numbers. | Transparent fronts sit in front of L1 and L2: cross-chain transactions are held for the next sync block, everything else passes straight through. Watch `EEZ_MAX_USER_TXS_PER_BUNDLE` — it defaults to 3, and anything past it is dropped silently. |

**Protocol researchers** (`./protocol-researchers/`)

| NN | file | QUESTION | ANSWER | DETAIL |
|---|---|---|---|---|
| 01 | `pr1-the-four-components-of-rollup0` | Which component does what? | Four separate programs, not one node. | The sequencer builds a chain's blocks; the composer settles any cross-chain calls inside them — the live path is just those two. The proof-signer then signs a hash of the result so the block can be trusted downstream. The deriver trusts none of them and re-derives the same state from L1 alone. |
| 02 | `pr2-commit-first-repair-if-needed` | If L2 commits first, what makes L1 the source of truth? | L2 commits immediately, and L1 either settles it or repairs it. | `begin()` commits the L2 block before L1 has confirmed anything, and that optimistic state waits at a fixed sync height until L1's history reaches it. L1 confirmation then marks it settled — or marks it failed and triggers a repair. |
| 03 | `pr3-the-deriver` | Can the L2 chain be rebuilt from L1 alone? | Yes — that is the deriver's entire job. | It watches L1 for `BatchPosted` events rather than trusting any node's live output, rebuilding each slice of L2 state from raw L1 data. Replayed across all of L1 history, the resulting state answers to L1 and nothing else. |
| 04 | `pr4-how-the-composer-proves-a-batch` | How does the composer prove a batch? | One gRPC stream: header first, then blocks, then a signature. | The prover re-executes rather than taking the composer's word — it decodes the batch calldata, replays each block and recomputes the hash itself. The composer trusts the result only once the signature recovers to the registered attester. |
| 05 | `pr5-how-the-address-is-derived` | How is the address derived? | Two values, hashed into a salt, run through CREATE2. | The rollup id and your address, packed together, are the whole identity. `keccak256` turns them into a 32-byte salt, and CREATE2 turns (manager, salt, bytecodeHash) into one address — computable before anything is deployed. This is the inside of `computeCrossChainProxyAddress`. |

- [ ] **Step 6: Verify the page renders and the filters still work**

```bash
bash scripts/audit.sh
node -e "const h=require('fs').readFileSync('index.html','utf8');
const n=(h.match(/class=\"card\"/g)||[]).length;
console.log('cards:', n);
console.log('research cards:', (h.match(/\.\/protocol-researchers\//g)||[]).length);"
```

Expected: audit passes; 18 cards total (15 numbered + 3 starter); 6 research hrefs (5 numbered + 1 starter).

- [ ] **Step 7: Confirm no card clips its container at a narrow width**

```bash
node scripts/check-panel-height.cjs 2>/dev/null || true
```

Then open `index.html` in a browser at 390px width and confirm no horizontal scroll — the longer detail text is the risk. The page body must never scroll sideways.

- [ ] **Step 8: Commit**

```bash
git add index.html
git commit -m "Cards answer the question they now ask

The page listed fifteen demos and gave a developer no way to tell
which one was their problem. Every card is now the question a
developer actually asks, answered in one line, with the concept under
it at a size that reads as explanation rather than footnote —
14.5px on --muted, 7.3:1 on the card, against the 4.5:1 the old
subtext was scraping.

Questions come from the DAPPCon BuilderRoom workshop; answers come
from each demo's own captions, so a card cannot contradict the
walkthrough it links to."
```

---

### Task 4: Align every demo title with its card

**Files:**
- Modify: `<title>` in all 15 walkthrough HTML files

**Interfaces:**
- Consumes: the fifteen questions from Task 3's table.
- Produces: titles that `build-llms.py` publishes into `llms.txt`.

- [ ] **Step 1: Set each title to its card's question**

The `<title>` is near line 9 of each file, currently in the form `Compute Your Cross-Chain Address — EEZ`. The new form keeps the ` — EEZ` suffix and uses the question:

```html
<title>What address does my contract have on another rollup? — EEZ</title>
```

Apply to all fifteen, using the QUESTION column from Task 3's table verbatim. For `q3`, the title is plain text — drop the backticks around `msg.sender`:

```html
<title>Who is msg.sender when the call comes from another chain? — EEZ</title>
```

Do **not** change the stub's title — it stays `Moved — How the Address Is Derived`.

- [ ] **Step 2: Verify every title changed and none was missed**

```bash
grep -h "<title>" $(git ls-files '*/q*.html' '*/ro*.html' '*/pr*.html') | sed 's/^ *//'
```

Expected: fifteen lines, every one a question ending in `? — EEZ`, plus the stub if it matched the glob (it will — confirm it still reads `Moved — …` and leave it).

- [ ] **Step 3: Regenerate llms.txt and run the full suite**

```bash
python3 scripts/build-llms.py
bash scripts/audit.sh
python3 scripts/check-panel-drift.py
python3 scripts/verify-citations.py
python3 scripts/build-llms.py --check
cd snippets && forge test && cd ..
```

Expected: every one green, `15 walkthroughs`.

- [ ] **Step 4: Commit**

```bash
git add $(git ls-files '*/q*.html' '*/ro*.html' '*/pr*.html') llms.txt llms-full.txt
git commit -m "Page titles are the question the card asks

A deep-linker who never saw a card now lands on a page whose own
title states their question, instead of opening on 'TWO INPUTS'."
```

---

### Task 5: Verify end to end, then open the PR

**Files:**
- None modified. This task is gates and the PR.

**Interfaces:**
- Consumes: everything from Tasks 1-4.

- [ ] **Step 1: Run the full suite from a clean state**

```bash
git status --short
bash scripts/audit.sh
python3 scripts/check-panel-drift.py
python3 scripts/verify-citations.py
python3 scripts/build-llms.py --check
cd snippets && forge test && cd ..
node scripts/check-panel-height.cjs
```

Expected: working tree clean · audit passes · `pages checked: 7` · citations resolve · `15 walkthroughs` · 13 tests pass · no clipping across 15 files.

Any failure stops the task. Do not push a red tree.

- [ ] **Step 2: Confirm the redirect stub actually redirects**

```bash
node -e "
const p=require('path');const puppeteer=require('puppeteer');
(async()=>{const b=await puppeteer.launch({args:['--no-sandbox']});const pg=await b.newPage();
await pg.goto('file://'+p.resolve('dapp-developers/q1-compute-your-cross-chain-address.html'),{waitUntil:'networkidle0'});
console.log('landed on:', pg.url().split('/').pop());await b.close();})();"
```

Expected: `landed on: pr5-how-the-address-is-derived.html`

- [ ] **Step 3: Push and open the PR**

Run each command separately — chaining `commit && push && gh pr create` gets the whole chain denied.

```bash
git push -u origin concept-cards
```

```bash
gh pr create --title "Concept cards: the landing page explains itself" --body "$(cat <<'BODY'
The first card taught a CREATE2 preimage to an audience that only needs to
call a view function, and nothing on the site said what a cross-chain
address is.

- Cards are now the question a developer asks, answered in one line, with
  the concept under it at 14.5px / 7.3:1 instead of 13px / 4.5:1.
- The derivation demo moves to the research track behind a relative
  meta-refresh stub, so the public URL keeps resolving on both hosts.
- A new dapp opener covers `createCrossChainProxy`, which had zero
  coverage across all 14 demos.
- Adds `scripts/check-panel-height.cjs` for the silent 16-line panel clip
  that `audit.sh` cannot see.

Questions are sourced from the DAPPCon BuilderRoom workshop; answers are
derived from each demo's own captions.

Spec: `docs/specs/2026-08-25-concept-cards-design.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
BODY
)"
```

- [ ] **Step 4: Confirm CI is green before asking for a merge**

```bash
gh pr checks --watch
```

Expected: `Structure, citations, panel drift` and `Snippets compile and tests pass` both pass, plus the Vercel preview.

- [ ] **Step 5: Update the KB entry (separate repo, no commit here)**

`agent-mesh/eez-agent/knowledge/eez/kb/02-technical/EEZ-Demos-Walkthroughs.md` lists every slug and title and says "Fourteen". It is outside this repo, so no CI catches it. Update: the count to fifteen, the dapp table (`q7` in, `q1` out, question titles), and the researcher table (`pr5` added). Commit in `agent-mesh`, not here.

---

## Post-merge

Merging rebuilds GitHub Pages in about a minute and triggers the Vercel deploy. Confirm both:

```bash
for u in https://eez-demos.vercel.app https://0xarmagan.github.io/eez-demos; do
  for p in /llms.txt /dapp-developers/q7-your-cross-chain-address.html \
           /protocol-researchers/pr5-how-the-address-is-derived.html \
           /dapp-developers/q1-compute-your-cross-chain-address.html; do
    printf "%s%s -> " "$u" "$p"; curl -s -o /dev/null -w "%{http_code}\n" "$u$p?cb=$$"
  done
done
```

Expected: 200 on all eight.

## Known open item

`q7` needs a diagram (Task 2, Step 6) and the spec leaves its design open. If the implementer is a subagent, that step needs a decision from Armagan before it can be built to the repo's "real data, never placeholder boxes" rule.
