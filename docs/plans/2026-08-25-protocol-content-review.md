# Protocol-Accuracy Review & Evaluation Plan — 15 published walkthroughs

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`, one task at a time. Steps use `- [ ]` for tracking.
> **Domain skill:** every reviewing task MUST be executed with `agent-mesh/eez-agent/skills/eez-protocol-dev/SKILL.md` loaded, plus the reference file its task names. That skill's review format, priority order and stale-name table are the rubric this plan scores against.

**Goal:** Establish whether every technical claim, code panel and command on eez-demos.vercel.app is true of the protocol as it exists today, and produce a per-page verdict a publisher can act on.

**Architecture:** The repo's automated layer (citations, panel drift, panel geometry, links, JS syntax) already passes and is *not* re-litigated here except where it is provably lossy. This plan targets only what tooling cannot check: whether the cited line is the *right* line, whether narration is true, whether trust claims are honest, and what a dapp developer needs that is missing. Findings are collected per page, then synthesised into one scorecard.

**Tech stack:** static HTML + JS panels; Python audit scripts (`scripts/`); Foundry for the runnable tests; GitHub API for upstream verification.

**Spec / source of truth:** the live site (`https://eez-demos.vercel.app`) and its generated `llms-full.txt`. **Not** the local working tree — see Global Constraints.

---

## Global Constraints

- **The working tree at `/Users/armagan/Documents/eez-demos` has a concurrent writer.** On 2026-08-25 22:05–22:06, `dapp-developers/q2-*.html`, `dapp-developers/q4-*.html`, `snippets/q2-cross-chain-call.sol` and `snippets/q4-proxy-registry.sol` were modified by another session on branch `fix/panel-geometry-gate`. Before any task writes to this checkout: confirm `git diff --stat` is stable across two reads 60s apart, or branch off `origin/main` and work there.
- **Review the live site, not the branch.** Live is `main` @ `33cf510`. `fix/panel-geometry-gate` (`c9af3d0`) is unmerged, and a local untracked `dapp-developers/q7-test-demo.html` 404s in production — it is a scaffold, not a page. Do not review it.
- **Pins, verbatim** (`scripts/citation-pins.json`): `eez-core-protocol` @ `9735f53abbb6b9f5e863f405ad4555b4701b7fda`; `eez-rollup0` @ `a4b9b2f1da1208c0f4f9c5b2ff4e45d6281ad1d2`.
- **Never re-point a citation at a mutable branch.** Bump the SHA in `citation-pins.json`, run `scripts/verify-citations.py --repin`, re-run the verifier.
- **No invented API surface.** If a function, field or error cannot be confirmed at the pinned SHA, the finding is "unverified — check `<file>`", never an assertion.
- **No Solidity toolchain on this machine.** `forge` and `solc` are both absent, and `solcx` is not installed. Any task claiming a test passes must either install a toolchain first or run it in CI — an unexecuted compile-check is not a passing test, and must be labelled as such.
- **Citation counts, verbatim.** The repo's own `scripts/verify-citations.py` finds **26 citations / 28 assertions** and passes. An external audit of this site reported "20/20 citations resolve" from a hand-rolled script with a hardcoded list; that is a subset, not a contradiction. Do not "fix" the repo's verifier to match it.
- **Severity vocabulary** (from the skill's review format, used by every task): `BLOCKING` (breaks in production, leaks value, or teaches a security-relevant falsehood) → `ACCURACY` (wrong name, field, or claim) → `BETTER` (opinionated improvement) → `RIGHT` (specific, earned credit).
- **Page verdicts:** `Ship it` / `Ship with fixes` / `Don't ship — conceptual problem`. One per page, no abstentions.

---

## Baseline already established (do not redo)

Evidence gathered 2026-08-25, before this plan. Rows below marked *(ext, re-verified)* originate in an external audit bundle at `/Users/armagan/Downloads/eez contract demo analye/` and were re-checked against upstream source here — that bundle also carries a candidate `q8` walkthrough (Task 11) and two throwaway scripts written against sandbox paths (`/home/claude/...`).

| Check | Result |
|---|---|
| `scripts/verify-citations.py` | 26 citations, 28 assertions, **all pass** at the pinned SHAs |
| `eez-core-protocol` upstream HEAD | `9735f53` — **identical to the pin**; the Solidity pages are pinned to current `main` |
| `eez-rollup0` upstream HEAD | `d8a7547` (2026-08-25) — **2 commits / 34 files ahead of the pin** |
| Cited rollup0 files changed since the pin | `composer.rs` **+870/−252**, `deriver.rs` +4/−10, `optimistic.rs` +1/−1 |
| Site inventory | 15 walkthroughs (6 dapp, 4 operator, 5 researcher) + index; `q1-compute-your-cross-chain-address.html` is a 967-byte canonical redirect to `pr5`, not a page |
| `llms-full.txt` extraction | **Lossy** — `ro2` and `ro4` emit a header with zero steps (see Task 7) |
| `q2` snippet constant | **DRIFTED** — `STATIC_CHECK_GAS = 5000`; upstream `CrossChainProxy.sol:23` is `1_000` |
| `q2` snippet probe | Substitutes `assembly { tstore(0, 1) }` for upstream's named `uint256 transient _staticDetector` (`:18`, `:71`) — unlabelled, and slot 0 is a collision risk |
| Top-level static reads | **Not block-gated.** `EEZ.sol:1306-1327` falls through to `verificationByRollup[destRid].staticEntryQueue` and matches on `_stateRootsMatch`, with the source comment *"static calls do not obsolete after a block passes"*. The same-block rule holds for execution entries, **not** for statics |
| `ro4`'s bundle cap | `EEZ_MAX_USER_TXS_PER_BUNDLE = 3` (rbuilder-chiado silently drops past it) is live on the page and **absent from `llms-full.txt`** — the stakes of Task 7 |

---

### Task 1: Decide the rollup0 pin — stay at `a4b9b2f` or move to `d8a7547`

Nine of fifteen pages (all 4 operator + all 5 researcher) rest on a pin that upstream has moved past. Citations still verify because pins are immutable; the question is whether the *content* still describes the system. This task gates Tasks 4 and 5, so it runs first.

**Files:**
- Read: `scripts/citation-pins.json`
- Produce: `docs/reviews/2026-08-25/01-pin-decision.md`

**Interfaces:**
- Produces: `PIN_DECISION` = `hold` | `repin`, and for each of the 9 pages a flag `AFFECTED_BY_DRIFT: yes|no`. Tasks 4 and 5 consume both.

- [ ] **Step 1: Pull the two commits' worth of change on the cited symbols only**

```bash
cd /Users/armagan/Documents/eez-demos
curl -s "https://api.github.com/repos/eez-association/eez-rollup0/compare/a4b9b2f1da1208c0f4f9c5b2ff4e45d6281ad1d2...d8a7547b3" \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
for f in d['files']:
    if f['filename'] in {
      'crates/eez-driver/src/sequencer.rs','crates/eez-composer/src/composer.rs',
      'crates/eez-proof-signer/src/attest.rs','crates/eez-deriver/src/deriver.rs',
      'crates/eez-composer/src/optimistic.rs','crates/eez-control-rpc/proto/prove.proto',
      'Makefile','README.md','testing/kurtosis/README.md'}:
        print('='*70); print(f['filename'], f['additions'], f['deletions'])
        print(f.get('patch','(patch too large — fetch the file at both SHAs)')[:4000])
"
```

Expected: `composer.rs` dominates. Its patch will exceed the inline limit; fetch it at both SHAs with `curl -s https://raw.githubusercontent.com/eez-association/eez-rollup0/<SHA>/crates/eez-composer/src/composer.rs`.

- [ ] **Step 2: Answer three questions in writing, per cited symbol**

For each: (a) does the symbol still exist at HEAD under the same name? (b) is the *line number* the page cites still that symbol? (c) does the page's narration still describe what the symbol does? Record a one-line answer each — (c) is the only one that can force `repin`.

- [ ] **Step 3: Decide and record**

`hold` is correct if all narration survives — a pin is a feature, and re-pinning costs a full re-verify of 9 pages. `repin` is required if any narration is now false. Write the decision and its reason; if `repin`, run:

```bash
python3 scripts/verify-citations.py --repin && python3 scripts/verify-citations.py
```

Expected on success: `All citations verified against real upstream source at the pinned SHAs.`

- [ ] **Step 4: Commit the decision doc** (not the pin bump — that ships with Task 4's fixes)

```bash
git add docs/reviews/2026-08-25/01-pin-decision.md
git commit -m "review: record rollup0 pin decision against upstream HEAD d8a7547"
```

---

### Task 2: Trust-and-claims honesty sweep (highest-severity pass)

The skill's first priority is anything that teaches a security-relevant falsehood. The site's own preamble says *"the proof system in the public source is dev-grade ECDSA, not production ZK"* — this task checks whether every page carries that honesty at the point of the claim, not only in a file no human reads.

**Files:**
- Read: all 15 pages (live), `llms-full.txt`
- Reference: `skills/eez-protocol-dev/references/stack-and-trust.md`
- Produce: `docs/reviews/2026-08-25/02-trust-claims.md`

- [ ] **Step 1: Extract every trust-bearing string**

```bash
cd /tmp && curl -s https://eez-demos.vercel.app/llms-full.txt > llms-full.txt
grep -n -i -E "prove|prover|proof|attest|trust|verif|secure|final|atomic|guarantee" llms-full.txt | grep -v "^.*Verify: https" > trust-hits.txt
wc -l trust-hits.txt
```

- [ ] **Step 2: Judge each hit against three named traps**

1. **ZK inference.** `pr4` is titled *"How the composer proves a batch"* and its step 2 says *"the prover re-executes"*; the artefact returned is a 65-byte ECDSA signature (`ProveResponse.signature`). A reader who lands on `pr4` from search sees "prover", "proves", "public_inputs_hash" and no statement that this is a signer standing in for a ZK proof. Decide: is the page-level `PRE-MAINNET` badge sufficient, or does the claim need a sentence at the claim?
2. **Trusted-downstream.** `pr1` step 2: *"the Attester signs a hash of the result so the block can be trusted downstream."* Check against `stack-and-trust.md` — what is actually trusted, by whom, and under what assumption.
3. **Atomicity.** Grep found no "atomic" claim on-site; confirm that holds, and record it as `RIGHT` if so. If any page adds one, it needs the builder caveat (bundle inclusion is builder-dependent) in the same sentence.

- [ ] **Step 3: Verify the badge is actually on all 15 live pages**

```bash
for p in $(curl -s https://eez-demos.vercel.app/llms.txt | grep -oE 'https://[^)]*\.html' | sed 's|.*/eez-demos/||;s|.*vercel.app/||'); do
  printf '%-62s ' "$p"; curl -s "https://eez-demos.vercel.app/$p" | grep -c "PRE-MAINNET"
done
```

Expected: `1` or more for every page. A `0` is `BLOCKING` — that page makes capability claims with no pre-mainnet frame.

- [ ] **Step 4: Write findings with severity, then commit**

Each finding: quoted string, page, why it misleads, and the exact replacement sentence. No "consider clarifying".

---

### Task 3: Dapp-developer pages — the demo checklist (q7, q2, q3, q4, q6, q5)

These are the pages a builder copies. Review each against the skill's *"Reviewing a code demo specifically"* list, in its order.

**Files:**
- Read: the 6 live pages + `snippets/*.sol` + `snippets/test/*.t.sol` as embedded in `llms-full.txt`
- Reference: `references/footguns.md` (read before signing off) and `references/execution-model.md`
- Produce: `docs/reviews/2026-08-25/03-dapp-pages.md`

- [ ] **Step 1: Run the eight checks per page and record a hit/miss line for each**

Entry encoding · who builds the table · `revertNextNCalls` misuse · static vs mutating schema · proxy opcode assumptions · same-block reality · error-handling honesty · dev keys. Most will be "not applicable" on a 3-step page — say so explicitly rather than skipping, so the reviewer can see the check ran.

- [ ] **Step 2: Fix the two confirmed `q2` snippet defects** (already verified against upstream — do not re-litigate, just fix)

`snippets/q2-cross-chain-call.sol` declares `uint256 internal constant STATIC_CHECK_GAS = 5000;`. Upstream at the pin:

```bash
curl -s "https://raw.githubusercontent.com/eez-association/eez-core-protocol/9735f53abbb6b9f5e863f405ad4555b4701b7fda/src/base/CrossChainProxy.sol" | sed -n '14,25p;64,74p'
```

Expected: `uint256 private constant STATIC_CHECK_GAS = 1_000;`, and `staticCheck()` writing the named `uint256 transient _staticDetector` rather than raw slot 0.

1. Change `5000` → `1_000` and add one line on why the probe is capped: in a static context the `tstore` is an exceptional halt that consumes everything forwarded, so the cap is the cost.
2. Label the `assembly { tstore(0, 1) }` simplification as a stand-in for upstream's named transient variable, and say that slot 0 in a real contract is a collision risk.

This defect is the reason Task 8 exists: `check-panel-drift.py` only compares panel↔snippet, and the constant's *value* never appears in a panel.

- [ ] **Step 3: Adjudicate the four already-flagged candidates**

1. **`q2` step 3 copy** — *"routed to a read-only lookup instead of a real execution."* "Lookup" is the pre-`feature/simplify` vocabulary (`LookupCall` → `StaticExecutionEntry`, `staticCallLookup` → `staticCrossChainCall`). The code panel uses the current name while the prose uses the retired one. Confirm against `docs/CORE_PROTOCOL_SPEC.md` at `9735f53`, then rewrite the sentence in the repo's own vocabulary.
2. **`q7` step 2 caption** — *"Or read the address before anything is deployed. It is a view call."* The panel above it shows both `createCrossChainProxy` (state-changing) and `computeCrossChainProxyAddress` (view). Decide whether "it" is unambiguous.
3. **`q3`'s safety argument** — the snippet comment claims whitelisting the proxy is safe because the address is CREATE2-derived from `(owner, originRollupId)` and the manager's address. Verify that derivation against `EEZBase.sol:176` at the pin, and verify the claim *"Only the manager can forward through that proxy"* against `CrossChainProxy.sol`. This is the one page whose central claim is a security claim.
4. **`q4`'s `ProxyInfo`** — confirm field order `(bool isProxy, address originalAddress, uint64 originalRollupId)` and that the auto-generated getter really returns them flattened in that order at `EEZBase.sol:60`. A wrong order here silently mis-destructures in copied code.

```bash
curl -s "https://raw.githubusercontent.com/eez-association/eez-core-protocol/9735f53abbb6b9f5e863f405ad4555b4701b7fda/src/base/EEZBase.sol" | sed -n '50,80p;150,215p'
curl -s "https://raw.githubusercontent.com/eez-association/eez-core-protocol/9735f53abbb6b9f5e863f405ad4555b4701b7fda/src/base/CrossChainProxy.sol" | sed -n '25,110p'
```

- [ ] **Step 4: Ask the "right line?" question the verifier cannot**

For each of the 6 citations, state whether the cited line is the *pedagogically* right anchor (`CONTRIBUTING.md` step 2 calls this out as the verifier's known blind spot).

- [ ] **Step 5: Verdict per page, then commit.**

---

### Task 4: Protocol-researcher pages (pr1, pr2, pr3, pr4, pr5)

Consumes `PIN_DECISION` from Task 1. These pages carry the highest drift exposure — `composer.rs` changed by 870 lines since the pin.

**Files:**
- Read: the 5 live pages; upstream rollup0 at the decided SHA
- Reference: `references/stack-and-trust.md`, `references/architecture.md`
- Produce: `docs/reviews/2026-08-25/04-researcher-pages.md`

- [ ] **Step 1: For each page, fetch the cited file at the decided SHA and read the cited symbol in full.**

```bash
S=a4b9b2f1da1208c0f4f9c5b2ff4e45d6281ad1d2   # or d8a7547b3, per Task 1
for f in crates/eez-driver/src/sequencer.rs crates/eez-composer/src/composer.rs \
         crates/eez-proof-signer/src/attest.rs crates/eez-deriver/src/deriver.rs \
         crates/eez-composer/src/optimistic.rs crates/eez-control-rpc/proto/prove.proto; do
  echo "=== $f"; curl -s "https://raw.githubusercontent.com/eez-association/eez-rollup0/$S/$f" | wc -l
done
```

- [ ] **Step 2: Check the four claims the panels make but the code must support**

- `pr2`: that `begin()` commits before L1 confirmation, and that `mark_settled` / `mark_failed` are the only two exits. Panels show *"fields omitted — signature verified, body not"* — a deliberate, honest limit. Decide whether a page whose panels omit every body still teaches the mechanism, or is a diagram wearing a code panel's clothes.
- `pr3`: that `catch_up()` replays *all* of L1 history, and that `BatchPosted(uint256 indexed rollupCount)` is the real event signature.
- `pr4`: that the header MUST be first, that `MAX_MESSAGE_BYTES` is 1 GiB, and that the composer trusts the result only once the signature recovers to the registered attester — the last clause is the trust claim, cross-reference Task 2.
- `pr5`: identical derivation to `q7`/`q1`; confirm the two pages agree byte-for-byte on salt construction and do not teach two subtly different orders.

- [ ] **Step 3: Coverage judgement.** `pr1` claims four components divide the work; verify no fifth component was introduced upstream, and that the live path really is sequencer + composer only.

- [ ] **Step 4: Verdict per page, then commit.**

---

### Task 5: Rollup-operator pages (ro1, ro2, ro3, ro4) — command truth

These are the only pages whose central content is *executable instructions*, which no citation check can validate. Their failure mode is a command that no longer works, and the cost is a builder's afternoon.

**Files:**
- Read: the 4 live pages; `README.md` and `testing/kurtosis/README.md` at the pinned SHA
- Produce: `docs/reviews/2026-08-25/05-operator-pages.md`

- [ ] **Step 1: Diff each command against upstream docs at the pin**

```bash
S=a4b9b2f1da1208c0f4f9c5b2ff4e45d6281ad1d2
curl -s "https://raw.githubusercontent.com/eez-association/eez-rollup0/$S/README.md" > /tmp/ro-readme.md
curl -s "https://raw.githubusercontent.com/eez-association/eez-rollup0/$S/testing/kurtosis/README.md" > /tmp/ro-kurtosis.md
grep -n -E "kurtosis|docker|make |cast |openssl|git submodule" /tmp/ro-readme.md /tmp/ro-kurtosis.md
```

Every command shown on `ro1`/`ro3` must appear upstream or be justified as a documented composition. Flag any invented flag or env var — `EEZ_DEPLOY_SKIP_SIMULATION=1`, `KURTOSIS_ARGS_FILE`, `EEZ_L2_SYSTEM_KEY` and the four `.env` keys on `ro3` are the specific ones to confirm.

- [ ] **Step 2: Check the version-pinned externals.** `ghcr.io/gnosischain/reth_gnosis:v2.0.0` and the `gnosischain/configs` clone are third-party and unpinned to a SHA — decide whether that is acceptable or needs a dated note.

- [ ] **Step 3: Key hygiene.** Confirm no page prints a well-known dev key as a poster, composer or proof-signer key (`BLOCKING` if one does). `ro3` step 2 tells the reader to *set* them, which is correct — verify no example value is filled in.

- [ ] **Step 4: Label what was not executed.** Nobody is standing up Kurtosis for this review. State plainly in the findings which commands were verified against upstream docs only and never run — an unlabelled desk-check reads as a test.

- [ ] **Step 5: Verdict per page, then commit.**

---

### Task 6: Coverage evaluation — what a dapp developer needs that is not here

Review checks what is on the page; this task checks what should be. Scored against the skill's list of what actually bites app developers.

**Files:**
- Produce: `docs/reviews/2026-08-25/06-coverage.md`

- [ ] **Step 1: Score the six known app-dev traps against the site**

| Trap | On the site today? |
|---|---|
| `msg.sender` is a `CrossChainProxy` | Yes — `q3`, with a runnable test |
| `balance` / `extcodesize` / `delegatecall` describe the proxy | **Check — appears absent** |
| Same-block constraint on **execution** entries (`lastVerifiedBlock == block.number`, "there is no later") | **Check — appears absent** |
| That the same-block rule does **not** apply to top-level **static** reads (`EEZ.sol:1306-1327`, persistent `staticEntryQueue`, gated on `_stateRootsMatch`) | **Absent — and a candidate page currently states the opposite. See Task 11** |
| Outcomes are pre-committed in an `ExecutionEntry` before the tx runs | **Check — appears absent** |
| A caller cannot distinguish "no matching entry" from "destination reverted" | **Check — appears absent** |
| Value and `callGas` semantics on a cross-chain call | Partial — `callGas` appears only as a hash field in `q5` |

Confirm each "check" by grep before asserting it:

```bash
grep -n -i -E "extcodesize|delegatecall|block\.number|lastVerified|ExecutionEntry|rolling hash|same block|revertNextNCalls" /tmp/llms-full.txt
```

- [ ] **Step 2: Rank the gaps by what breaks a builder soonest**, and propose at most three new walkthroughs. A candidate for the opcode gap already exists — see Task 11 before drafting a competing one. The skill's mental model says the two that change how a builder writes contracts are pre-committed outcomes and proxy identity; the site has the second and not the first.

- [ ] **Step 3: State the counter-case.** Six dapp pages that are each true beat nine where three are thin. If a gap is better served by a link to the spec than a new page, say so.

- [ ] **Step 4: Commit.**

---

### Task 7: Fix the lossy `llms-full.txt` extraction and gate it

`ro2` and `ro4` emit a title, a source line and **zero steps** into `llms-full.txt`, while their live pages have three steps each. The stakes are concrete: `ro4` Step 2 documents `EEZ_MAX_USER_TXS_PER_BUNDLE = 3` and that rbuilder-chiado silently drops anything past it — one of the sharpest operational footguns on the site, invisible to every agent that reads `llms-full.txt`. Root cause is confirmed: `steps_of()` in `scripts/build-llms.py` reads string literals out of the `codeByStep` array, but `ro2` builds its steps by reference (`makefileLines.slice(0, 6)`), so `flat_strings()` returns nothing. The script then prints `15 walkthroughs` and exits 0 — silent loss.

**Files:**
- Modify: `scripts/build-llms.py:59-81` (`js_array`, `flat_strings`, `steps_of`)
- Modify: `scripts/audit.sh` (add the assertion)
- Test: new `scripts/test_build_llms.py`

- [ ] **Step 1: Write the failing test**

```python
# scripts/test_build_llms.py
import subprocess, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent

def test_every_walkthrough_emits_at_least_one_code_block():
    subprocess.run([sys.executable, "scripts/build-llms.py"], cwd=ROOT, check=True)
    text = (ROOT / "llms-full.txt").read_text()
    sections = text.split("\n## ")[1:]
    empty = [s.splitlines()[0] for s in sections if "```" not in s]
    assert empty == [], "walkthroughs emitted with no code: %s" % empty
```

- [ ] **Step 2: Run it and watch it fail**

Run: `python3 scripts/test_build_llms.py -q` (or `pytest scripts/test_build_llms.py -q`)
Expected: FAIL listing `How to deploy the protocol` and `How to send and test a cross-chain call`.

- [ ] **Step 3: Make `steps_of` resolve slice-built steps**

Resolve `<name>.slice(a, b)` references against the named literal array in the same file before extracting strings, and raise (not warn) when a page declares `codeByStep` but yields zero lines.

- [ ] **Step 4: Re-run the test and the build**

```bash
python3 scripts/test_build_llms.py -q && python3 scripts/build-llms.py && git diff --stat llms-full.txt
```

Expected: PASS, and `llms-full.txt` grows by `ro2`'s and `ro4`'s steps.

- [ ] **Step 5: Wire it into `scripts/audit.sh`** so a future page that builds panels a third way fails CI rather than vanishing from the corpus.

- [ ] **Step 6: Commit**

```bash
git add scripts/build-llms.py scripts/test_build_llms.py scripts/audit.sh llms-full.txt
git commit -m "fix: llms-full.txt silently dropped ro2 and ro4 code panels"
```

---

### Task 8: Close the snippet↔upstream fidelity hole

`check-panel-drift.py` asserts every panel line exists in the snippet. `verify-citations.py` asserts the cited line and symbol still exist upstream. **Nothing asserts the snippet still matches upstream** — which is exactly how `STATIC_CHECK_GAS = 5000` shipped against an upstream `1_000` (Task 3, Step 2). This task builds the missing third check.

**Files:**
- Create: `scripts/check-snippet-fidelity.py`
- Modify: `scripts/audit.sh` (run it), `CONTRIBUTING.md` (name it in the audit list)
- Reference (do **not** vendor): `/Users/armagan/Downloads/eez contract demo analye/snippet_drift.py` — the right idea, but it hardcodes `/home/claude/...` clone paths, its `MIRRORS` matcher never matches a `.t.sol` file, and it compares only named constants (about one real constant across seven snippets) while printing "No constant drift detected." Treat it as a sketch, not a starting file.

**Interfaces:**
- Produces: `check-snippet-fidelity.py` exits non-zero on any drift, and prints `snippet:line  NAME = <got>   upstream: <want>`.

- [ ] **Step 1: Write the failing test against the known-bad value**

Restore `STATIC_CHECK_GAS = 5000` in a scratch copy (or run before Task 3's fix lands) and assert the checker catches it:

```python
# scripts/test_snippet_fidelity.py
import subprocess, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent

def test_detects_a_drifted_constant(tmp_path):
    src = ROOT / "snippets/q2-cross-chain-call.sol"
    good = src.read_text()
    src.write_text(good.replace("STATIC_CHECK_GAS = 1_000", "STATIC_CHECK_GAS = 5000"))
    try:
        r = subprocess.run([sys.executable, "scripts/check-snippet-fidelity.py"],
                           cwd=ROOT, capture_output=True, text=True)
        assert r.returncode != 0
        assert "STATIC_CHECK_GAS" in r.stdout
    finally:
        src.write_text(good)
```

- [ ] **Step 2: Run it and watch it fail** — `python3 scripts/test_snippet_fidelity.py -q`. Expected: FAIL, `check-snippet-fidelity.py` does not exist.

- [ ] **Step 3: Implement the checker**

Read each snippet's `// Mirrors <path>:<line>...` header (every snippet already declares one) rather than a hardcoded map, so a new snippet is covered the day it lands. Fetch upstream at the SHA in `scripts/citation-pins.json` over raw.githubusercontent — no local clone, matching how `verify-citations.py` already works. Compare, whitespace-normalised: **named constants**, **error declarations**, **struct field order**, and **function signatures**. Anything the snippet declares that upstream also declares must match; anything the snippet invents (stand-ins like `CrossChainProxy`, `MockEEZ`, `IRemote`) is out of scope and must be skippable by an explicit `// @stand-in` marker so silence is never the default.

- [ ] **Step 4: Run it against the whole snippet set**

```bash
python3 scripts/check-snippet-fidelity.py; echo "exit=$?"
```

Expected after Task 3's fix: clean, exit 0. Report every constant, error, struct and signature it actually compared — a checker that prints a pass without saying what it checked is the failure mode this task exists to end.

- [ ] **Step 5: Wire into `scripts/audit.sh` and `CONTRIBUTING.md`, then commit**

```bash
git add scripts/check-snippet-fidelity.py scripts/test_snippet_fidelity.py scripts/audit.sh CONTRIBUTING.md
git commit -m "feat: assert snippets still match upstream, not just the panels"
```

---

### Task 9: Runnable-artifact truth — snippets compile, tests pass, digests hold

The site's credibility rests on *"full compilable Solidity"* and *"runnable Foundry tests"*. Verify both claims literally. Note the asymmetry to report: 7 snippets, only 3 tests.

**Files:**
- Read: `snippets/*.sol`, `snippets/test/*.t.sol`
- Produce: `docs/reviews/2026-08-25/09-runnables.md`

- [ ] **Step 1: Get a toolchain, and say which one**

Neither `forge` nor `solc` nor `solcx` is present on this machine. Install Foundry (`curl -L https://foundry.paradigm.xyz | bash && foundryup`) **after asking**, or run this task in CI where `forge test` already passes. Record which. Every claim below is void without it.

- [ ] **Step 2: Compile every snippet**

```bash
forge build --root . 2>&1 | tail -20
```

If the repo has no Foundry root, compile into a scratch project rather than adding one here — and say which you did.

- [ ] **Step 3: Run the three tests**

```bash
forge test --match-contract "Q3MsgSender|Q5ContentHash|Q6ManagerDirect" -vv 2>&1 | tail -30
```

Expected: all green. Report actual output; a claim of "tests pass" without the pasted run is not acceptable here.

- [ ] **Step 4: Independently re-derive `Q5`'s three pinned digests**

The test asserts digests *"derived OUTSIDE the EVM with pycryptodome"*. Re-derive them a third way and confirm:

```bash
python3 - <<'PY'
from eth_abi import encode
from eth_utils import keccak
SRC="0x"+"11"*20; TGT="0x"+"22"*20
def h(is_static, src, srid, tgt, trid, data=bytes.fromhex("a9059cbb")):
    return keccak(encode(["bool","address","uint64","address","uint64","uint256","uint64","bytes"],
                         [is_static, src, srid, tgt, trid, 0, 0, data])).hex()
print("base   ", h(False, SRC,1,TGT,100))
print("swapped", h(False, TGT,100,SRC,1))
print("static ", h(True,  SRC,1,TGT,100))
PY
```

Expected, in order: `6f907866fb077719ec239f745e2de52832f0d8507473768dbaa2d3b45cf8fbe1`, `9876a218b9c58a69bb5b01481b628f13d5c2eb8d72b0f80d942e9eb0962dc19f`, `b3d426ceaa48ca006739dd0799a05e675999732e2a63a4021089512c489daa1d`. Any mismatch is `BLOCKING` — the site would be teaching a wrong preimage order.

- [ ] **Step 5: Judge the 7-snippets-3-tests gap.** Name which untested snippet most deserves a test and why; do not propose four tests for symmetry's sake.

- [ ] **Step 6: Commit.**

---

### Task 10: Vocabulary and cross-page consistency sweep

`CONTRIBUTING.md` step 4 already requires grepping a term across all 15 demos before accepting a new name. This task runs that sweep once, globally, against the skill's stale-name table.

**Files:**
- Produce: `docs/reviews/2026-08-25/10-vocabulary.md`

- [ ] **Step 1: Grep every retired name**

```bash
grep -n -i -E "StateDelta|LookupCall|ExpectedLookup|revertSpan|staticCallLookup|executeL2TX|IZKVerifier|ProofSystemRegistry|stateDeltas|l2ToL1CallNumber|executingLookupIndex|\blookup\b" /tmp/llms-full.txt
```

Expected: the `q2` "read-only lookup" hit from Task 3, and ideally nothing else. Every hit means the author worked from a stale source, so check that page's neighbouring claims too — the contaminated-source lesson, not just the word.

- [ ] **Step 2: Check the site's own coinages.** For each noun the site introduces that upstream does not use, decide: adopt upstream's word, or keep and define it once. Fragmented vocabulary across 15 pages is a real cost.

- [ ] **Step 3: Canonical host.** `llms-full.txt` points every `Page:` line at `https://0xarmagan.github.io/eez-demos/...` while the site serves from `eez-demos.vercel.app`. Confirm which host is canonical, check the pages' `<link rel="canonical">` agree with it, and fix `build-llms.py`'s base URL if not. An LLM ingesting `llms.txt` will cite whichever host is written there.

- [ ] **Step 4: Commit.**

---

### Task 11: Adjudicate and land the `q8` candidate walkthrough

An externally-drafted walkthrough — *"How to read a remote contract's state"* — sits at `/Users/armagan/Downloads/eez contract demo analye/` (`q8-walkthrough.md`, `q8-remote-reads.sol`, `Q8RemoteReads.t.sol`; the two `.sol` files are byte-identical to their embedded copies). It targets the opcode gap Task 6 scores, and its citation is sound: `docs/CAVEATS.md · Opcodes that differ on cross-chain proxies` exists at `9735f53` and lists exactly `delegatecall`, `balance`, `extcodesize`, `extcodecopy` plus block-state opcodes. **It must not ship as drafted** — three defects, verified against source.

**Files:**
- Create: `dapp-developers/q8-<slug>.html`, `snippets/q8-remote-reads.sol`, `snippets/test/Q8RemoteReads.t.sol`
- Modify: `index.html` (card), the `NEXT:` chain on the neighbouring dapp page, `docs/DESIGN.md`
- Produce: `docs/reviews/2026-08-25/11-q8-adjudication.md`

- [ ] **Step 1: Fix the false claim in Step 3 (BLOCKING)**

The draft says the routed read works *"provided the composer put a matching static entry in this block. Outside that block there is nothing to resolve against, and the read reverts."* Verify and rewrite:

```bash
curl -s "https://raw.githubusercontent.com/eez-association/eez-core-protocol/9735f53abbb6b9f5e863f405ad4555b4701b7fda/src/EEZ.sol" | sed -n '1266,1330p'
```

Expected: outside a mid-flight batch, `staticCrossChainCall` scans `verificationByRollup[destRid].staticEntryQueue` and matches on `proxyEntryHash`, `destinationRollupId` and `_stateRootsMatch(...)` — no `block.number` gate, with the source comment *"static calls do not obsolete after a block passes."* Replacement wording: the read resolves as long as a matching static entry exists **and the state roots it was proven against still match**, and it reverts `ExecutionNotFound()` when none does. Name the error exactly so search works.

- [ ] **Step 2: Fix the test that cannot pass (BLOCKING)**

`test_routedReadRevertsWhenUnresolved` builds `StubProxy(address(0xDEAD))` and asserts `!ok`. A `staticcall` to an address with **no code succeeds and returns empty data**, so `require(ok, "unresolved")` passes, the assembly returns zero bytes, the outer call reports `ok == true`, and the assertion reverts. The draft's author states they could not run Foundry; neither can this machine (see Global Constraints). Rewrite so the resolver reverts, then prove the assertion under a real toolchain in Step 4.

- [ ] **Step 3: Replace the stub's mental model (BLOCKING)**

`StubProxy` forwards live to a local `RemoteToken` — fetch-on-demand, the async-messaging model EEZ is not. Outcomes are pre-committed in an entry before the transaction runs. `snippets/test/Q6ManagerDirect.t.sol` refuses to fake protocol state and says so in its header; this test should hold the same line. Make the resolver a table keyed by `crossChainCallHash` that reverts `ExecutionNotFound` on a miss — one change that satisfies Steps 1, 2 and 3 at once and makes the honest limit testable.

- [ ] **Step 4: Compile and run under a real toolchain**

```bash
forge build && forge test --match-contract Q8RemoteReads -vv
```

Expected: all five cases green, including the unresolved-read revert. If no toolchain is available, this task is **not complete** — do not merge on a compile-only check, and do not restate the draft's "compiles clean" as evidence the tests pass.

- [ ] **Step 5: Add the missing sibling caveat**

`CAVEATS.md` places *"Indistinguishable revert reasons when calling a proxy"* immediately above the cited section. A page teaching "ask it, don't inspect it" must say the caller cannot distinguish "no matching entry" from "the destination reverted" — both bubble up identically. One sentence in Step 3, or the page teaches a fiction by omission.

- [ ] **Step 6: Wire it into every consumer before merging**

Adding a page is not adding a file. Confirm each: the index card on `index.html`; the `NEXT:` link chain; `scripts/verify-citations.py` parses its citation (the draft carries a second `Also:` source — confirm the page's `loc:`/link shape is one the parser reads, or add the second citation in the shape it does); `check-panel-drift.py` passes; `check-panel-geometry.cjs` passes; `build-llms.py` emits its steps (it must not become a third silent-drop case — see Task 7); `docs/DESIGN.md` records the page. Settle the slug too: the draft's header says `q8-reads-that-lie.html` while its title is *"How to read a remote contract's state"* — the site's convention is a descriptive slug, and `CONTRIBUTING.md` records "a stray marketing word" as a past defect.

- [ ] **Step 7: Run the full audit, then commit**

```bash
bash scripts/audit.sh && python3 scripts/verify-citations.py && python3 scripts/check-snippet-fidelity.py && python3 scripts/build-llms.py
git add dapp-developers snippets index.html llms.txt llms-full.txt docs/DESIGN.md docs/reviews/2026-08-25/11-q8-adjudication.md
git commit -m "feat: q8 — reading remote state, and the four opcodes that lie"
```

---

### Task 12: Synthesis — the evaluation scorecard

**Files:**
- Read: every `docs/reviews/2026-08-25/*.md`
- Produce: `docs/reviews/2026-08-25/00-scorecard.md`

- [ ] **Step 1: One table, 15 rows** (plus a 16th for `q8` if Task 11 landed it, marked as new)

Columns: page · verdict (`Ship it` / `Ship with fixes` / `Don't ship`) · blocking count · accuracy count · the single highest-value fix · pin exposure (`core@9735f53` = current, `rollup0@a4b9b2f` = behind HEAD).

If you score on axes, **define each axis once and apply it identically across all three tracks**. An external audit of this site scored "Runnable" as 2/2 for the Rust and proto pages, which ship no runnable artifact at all, while docking `q7`, `q4` and `pr5` for having no test — which inflated its median. Either the axis means "a reader can execute what is shown" (the researcher pages score low) or "the shown artifact is real" (the untested Solidity pages score high). Not both.

- [ ] **Step 2: Rank every finding once, globally**, by the skill's priority order: footguns and security → protocol correctness → opinionated improvements → audience fit. Merge duplicates that surfaced in more than one task.

- [ ] **Step 3: Name the two or three you would fix first, and why.** A ranked list with no recommendation is an unfinished review.

- [ ] **Step 4: State what this review did not cover**, explicitly including anything gated on the missing Solidity toolchain — commands never executed, pages judged against a pin rather than HEAD, and the UX findings already tracked in `docs/plans/2026-08-25-audit-fixes.md` (a separate axis; do not re-report them here).

- [ ] **Step 5: Commit the scorecard.**

---

## Execution notes

- Tasks 2, 3, 6 and 10 are independent and can run in parallel. Task 1 gates 4 and 5. Task 3's fix gates Task 8's clean run. Tasks 6 and 8 gate Task 11. Task 12 gates on everything.
- Tasks 3, 7, 8, 9 and 11 write to the repo; all are safe to run only after the concurrent-writer check in Global Constraints passes.
- Tasks 9 and 11 both need a Solidity toolchain this machine does not have. Do not report either complete on a compile-only check.
- If a task finds nothing, it says so and spends its output on the architectural observation instead. Padding a review with nitpicks to look thorough is a failure, not diligence.
