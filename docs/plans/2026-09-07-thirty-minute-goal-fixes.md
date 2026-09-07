# 30-Minute Goal Fixes — Testnet-Ready Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the 8 findings from the 2026-09-07 funnel audit ("deploy a contract on the EEZ testnet in under 30 minutes"). Fix 1 is built **assuming the hosted testnet exists**, with every network value read from one config file, so connecting the live testnet is a one-file edit + redeploy.

**Source audit:** conversation audit 2026-09-07 (5 dimensions, verdict FAIL-on-goal / A-on-content). Fixes 2–8 approved as written; Fix 1 approved in testnet-assumed form.

**Inherits all Global Constraints from `docs/plans/2026-08-25-audit-fixes.md`** — panel geometry, drift checker coupling, citation verification, `build-llms.py` regeneration, the four CI gates, amber-for-friction, design tense, branch-per-phase / PR-per-phase, never commit to `main`.

---

## The connect-day mechanism (applies to Phase 1)

All testnet values live in **one file**: `assets/testnet-config.js`.

```js
// assets/testnet-config.js — the ONLY place network values live.
// status: "pending" renders every consumer in COMING-SOON mode;
// flip to "live" and fill the values the day the testnet ships.
window.EEZ_TESTNET = {
  status: "pending",            // "pending" | "live"
  l2: {
    name: "EEZ L2 (testnet)",
    rpcUrl: "",                 // e.g. https://rpc.eez-testnet.gnosis.io
    chainId: "",                // decimal string
    managerAddress: "0x4200000000000000000000000000000000000007", // EEZL2 — predeploy, known now
    explorer: "",
  },
  l1: {
    name: "Chiado",
    rpcUrl: "https://rpc.chiadochain.net",  // known now
    chainId: "10200",                        // known now
    managerAddress: "",         // EEZ (L1) — from the canonical deploy
    explorer: "https://gnosis-chiado.blockscout.com",
  },
  faucet: "https://faucet.chiadochain.net", // known now; replace if a dedicated faucet ships
  deployedAt: "",               // commit or date of the canonical protocol deploy, for the page footer
};
```

Rules:
- Every page that shows a network value reads `window.EEZ_TESTNET` at render time. **No RPC URL, chain ID, or address is ever hard-coded in page HTML.**
- While `status === "pending"`, consumers render the value cell as `COMING SOON` (amber `#8B7B55`, not red) and the copy button is disabled. The page structure, commands, and prose are final either way.
- Commands that embed a value render it as a shell variable the reader sets once (`$EEZ_RPC`), with the concrete value shown beside it from config — so the command text never changes on connect day.
- **Connect-day checklist** (put verbatim at the top of the config file as a comment): fill values → `status: "live"` → `python3 scripts/build-llms.py` → run the four gates → PR titled "Connect the testnet".
- `build-llms.py`: the deploy page's llms.txt entry must render values from this config too, or state "see /deploy for live endpoints" — decide when wiring the generator; do not duplicate values into the generator.

---

## Phase 1 — Fix 1: the deploy page (`deploy.html`)

One new top-level page + the config file. This is the page the North Star grades.

### Task 1: `assets/testnet-config.js`
- [ ] Create the file exactly as above (values known today filled; unknowns empty).
- [ ] Add it to the audit script's scan set if `audit.sh` globs only HTML.

### Task 2: `deploy.html`
**Files:** Create `deploy.html` (clone `start-here.html`'s shell: same header, ← Quickstarts, PRE-MAINNET badge, fonts, footer). Modify `scripts/build-llms.py` inputs if page lists are explicit.

Page structure (final copy; placeholders render via config):

- [ ] **H1 + framing** — `Deploy on the EEZ testnet` / "One contract, live on the EEZ L2, in about fifteen minutes. Everything you need is on this page — the walkthroughs explain *why* it works, and none of them are prerequisites."
- [ ] **Block 0 · BEFORE THE CLOCK STARTS** — Foundry v1.7.1 (`curl -L https://foundry.paradigm.xyz | bash && foundryup`), a funded key (link `faucet` from config, "xDAI on Chiado funds both layers"), and `export EEZ_RPC=<l2.rpcUrl>` / `export KEY=<your private key>`. One warning, amber: never a key that holds real assets.
- [ ] **Block 1 · THE NETWORK** — table rendered from config: chain, RPC URL, chain ID, EEZ manager, explorer — one row for EEZ L2, one for Chiado L1. Each value cell has a copy button (disabled + `COMING SOON` while pending).
- [ ] **Block 2 · DEPLOY** —
  ```
  forge create src/MyContract.sol:MyContract --rpc-url $EEZ_RPC --private-key $KEY
  ```
  followed by an expected-output block: `Deployed to: 0x…` → "if you see this, you're done — verify with `cast code <address> --rpc-url $EEZ_RPC` (non-empty bytes = deployed)."
- [ ] **Block 3 · FAILURE CASES** (the audit's Dimension-4 standard: never happy-path only) — three rows: `insufficient funds` → faucet link; connection refused/timeout → check `$EEZ_RPC` against the table above; `nonce too low` → a stuck earlier tx, `cast nonce` to inspect. Amber, not red.
- [ ] **Block 4 · NEXT** — "Give it a cross-chain address → q7 (Dapp 01) · Call it from the other side → q2 · Before you build on it, the msg.sender surprise → q3."
- [ ] **Footer** — pinned-commit line per Fix 6 pattern, plus `deployedAt` from config once live.
- [ ] Geometry: this page has no `#codePanel`; keep code blocks inside the standard content column so the geometry checker's scope is unchanged. Run all four gates.

### Task 3: pending-mode banner
- [ ] While `status === "pending"`, render one banner under the H1: "Public endpoints are not live yet — every command on this page is final; the table fills in the day they are. Run the same three steps locally meanwhile → start-here." Banner is driven by config, so connect day deletes it automatically.

**PR 1:** `deploy.html` + config + llms regeneration. Do **not** link it from the homepage yet — that's Phase 2, so the page can merge and sit unlinked until reviewed.

---

## Phase 2 — Fix 2: homepage funnel

**Files:** `index.html`, `start-here.html`.

- [ ] Primary CTA above the track cards: `DEPLOY A CONTRACT →  ~15 MIN` linking `deploy.html`, visually peer to (not replacing) the learn-oriented hero. While config is pending, the deploy page's own banner handles expectation — the CTA text stays stable.
- [ ] Keep the `[ FIRST TIME HERE? THREE STEPS, IN THIS ORDER ]` trio; relabel the DApp Developers section header to `[ DAPP DEVELOPERS — ALL WALKTHROUGHS, TRACK ORDER ]` so the two orderings read as intentional.
- [ ] `q8`'s `NEXT:` currently points at rollup-ops 01; repoint to `deploy.html` ("NEXT: Deploy on the EEZ testnet →").
- [ ] Add the deploy CTA to `start-here.html`'s dapp section head as one line.

## Phase 3 — Fix 3: runnable commands on the walkthrough pages

**Files:** `dapp-developers/q2,q3,q5,q6,q8` (the four pages with tests, per `snippets/README.md`, plus q2).

- [ ] Each page footer (beside PINNED) gets: `RUN THIS STEP · forge test --match-test <its test> -vv  (from eez-demos/snippets)`. Tests: q2 `test_theBranchTracksTheValueNotTheSuccessFlag`, q3 `test_sameChainCheck_revertsWhenCalledViaProxy`, q8 `test_routedReadReturnsThePreCommittedEntry`; q5/q6 use their `test/*.t.sol` names (read them; don't guess).
- [ ] These lines are page chrome, not `codeByStep` content — confirm `check-panel-drift.py` doesn't scan footers before merging.

## Phase 4 — Fixes 4 + 5: prerequisites + expected output

**Files:** `start-here.html`, `rollup-operators/ro2,ro3,ro4`.

- [ ] start-here: "You need **Foundry v1.7.1** and nothing else."
- [ ] ro4 prerequisite: replace `scripts/chiado-up.sh` with the exact compose command ro3 teaches — or, if `chiado-up.sh` exists upstream and is preferred, teach it in ro3 instead. **Check the upstream repo before choosing**; the two pages must name the same command.
- [ ] ro3: add snapshot size + expected sync time (measure or pull from upstream README — do not invent), and one sentence on `EEZ_DEPLOY_SKIP_SIMULATION=1` (confirm the actual reason in `scripts/deploy.sh` upstream before writing it).
- [ ] Expected-output blocks: start-here (`./run.sh` → three `pass` lines), ro2 (`make deploy-protocol` → "19 keys written to deployments.env"). ro4 already shows the RESULTS format — replicate that visual pattern.

## Phase 5 — Fix 6: surface the commit pin

**Files:** all 15 walkthrough pages + `deploy.html`.

- [ ] One footer line beside PINNED: `Verified against eez-core-protocol @ 9735f53 — pre-mainnet; interfaces may move.` Template it identically across pages; a follow-up could generate it, but hand-paste is fine now.

## Phase 6 — Fix 7: q5 trim

**Files:** `dapp-developers/q5-encode-a-calls-content-hash.html`, possibly `snippets/q5-content-hash.sol`.

- [ ] Keep: "two of the eight are written by the manager, not you — put your own values in either and the hash will never match an entry," with the two field names.
- [ ] Move the `USE_GAS_LEFT` / `EntryNotFound(hash, callGas)` mechanics into a collapsed "FOR ENTRY BUILDERS" note (or the researcher track). Strip inline line-number citations from body prose — the PINNED link carries them.
- [ ] Mind the drift checker if any panel line moves.

## Phase 7 — Fix 8: copy sweep

**Files:** `index.html`, `start-here.html`, `dapp-developers/q3`, `q7-test-demo.html` (delete), card copy on index.

- [ ] start-here "Eighteen" → "Seventeen" (recount after deploy.html ships: 17 walkthroughs + deploy page; the counter counts walkthroughs, deploy is not one).
- [ ] Converge duplicate card descriptions between index and start-here (pick one per card; the start-here variants are generally the sharper sequencing ones — keep those and backport).
- [ ] q3 title bar: `How msg.sender Resolves Across Chains` (lowercase m).
- [ ] Index card 07 description: "Learn why balance and code size answer about the proxy — a real number about the wrong contract, with no revert."
- [ ] Delete `dapp-developers/q7-test-demo.html`; confirm nothing (including llms generator) references it.
- [ ] `python3 scripts/build-llms.py` + all gates.

---

## Order & PRs

Phases are independently shippable; 1 → 2 is the only hard ordering (don't link a page that doesn't exist). Suggested PRs: (1) deploy page + config, (2) homepage funnel, (3) run-commands + prereqs + expected output [Phases 3–4], (4) pin lines + q5 trim + copy sweep [Phases 5–7].

## Connect day (when the testnet ships)

1. Fill `assets/testnet-config.js`, set `status: "live"`.
2. `python3 scripts/build-llms.py`; run the four gates.
3. PR "Connect the testnet" — the only content change on the whole site is that one file.
