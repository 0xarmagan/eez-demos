---
title: EEZ Developer Content — v4.1 execution manifest (in-repo)
date: 2026-08-26
source: "EEZ Developer Content — Full Plan (v4.1, operative)"
---

# v4.1 execution manifest

Part II of the v4.1 plan, in the repo, because a manifest that lives outside the
tree it describes is the CLAUDE.md failure the plan lists as a risk. **This file
is the source of truth for status.** Part I of the plan stays the source of truth
for judgment and is not restated here.

`scripts/check-manifest.py` asserts this file against reality on every build.

## Header block — RESOLVED (0.0 closed 2026-08-26)

```
contracts_pin:  9735f53abbb6b9f5e863f405ad4555b4701b7fda   # = upstream HEAD; 32/34 assertions pass
node_pin:       a4b9b2f1da1208c0f4f9c5b2ff4e45d6281ad1d2   # HOLD — see below
error_name:     path-specific, three sites, none stale     # see below
format:         Option A (Walkthroughs + Guides)
skill_version:  eez-protocol-dev v2 (bytecodeHash correction applied)
```

### node_pin — hold at `a4b9b2f`

Not a coin toss between `a4b9b2f` and `d8a7547`; already decided in writing at
`docs/reviews/2026-08-25/01-pin-decision.md`, reviewed against upstream HEAD
`d8a7547b3`. Two commits moved 3 of 12 cited files, none of them changed a
public surface, and every narration still holds. Re-pinning would cost a
re-verify of nine pages plus one line-number fix (`composer.rs:515` → `:636`)
and buy nothing.

### error_name — the card's premise was wrong

0.0 asked which of `ExecutionNotFound` and `EntryNotFound` wins, and told us to
append the loser to the stale-names list. **Both are live at `9735f53` and
neither is stale.** They are different paths, not different vintages:

| Path | Reverts | Declared | Raised |
|---|---|---|---|
| L2 state-changing consumption (`executeCrossChainCall` → `_consumeAndExecute` → `_findMatchingEntry`) | `EntryNotFound(bytes32 crossChainCallHash, uint64 callGas)` | `EEZL2.sol:98` | `EEZL2.sol:441` |
| L2 static read (`staticCrossChainCall`) | `ExecutionNotFound()` | `EEZBase.sol:104` | `EEZL2.sol:630`, `:644` |
| L1, both paths | `ExecutionNotFound()` | `EEZBase.sol:104` | `EEZ.sol:1015`, `:1302`, `:1327` |
| Block gate, either side — a *third* error, not a variant of these | `ExecutionNotInCurrentBlock` | `EEZL2.sol:82`, `EEZ.sol:209` | `EEZL2.sol:228`, `:634` |

**Nothing is appended to the stale-names list.** Appending either name would
make the §7 gate reject correct copy. Note that `docs/CAVEATS.md` uses
`ExecutionNotFound` as the umbrella term in prose even for the L2 execution
path, so upstream's own docs are looser than upstream's own code here — cite the
code.

`EntryNotFound` carries the observed `callGas` on purpose: under `USE_GAS_LEFT`
the hash preimage contains a value the caller cannot predict off-chain, so the
revert hands it back for the entry-builder to reproduce the key. That is the
same fact 0.5 is about, and both pages now say it.

Grep transcript: `grep -n "error \|revert " src/EEZ.sol src/L2/EEZL2.sol
src/base/EEZBase.sol` at `9735f53`, fetched over raw.githubusercontent through
`.citation-cache/`. `EntryNotFound` has zero occurrences in `EEZ.sol`;
`ExecutionNotFound` has zero declarations in `EEZL2.sol` (it inherits the
`EEZBase` one).

## Stale-names list (§7 gate)

`StateDelta` · `LookupCall` · `ExpectedLookup` · `revertSpan` ·
`staticCallLookup` · `executeL2TX` · `IZKVerifier` · `ProofSystemRegistry`

Unchanged by 0.0. Verified zero hits across tracked HTML on 2026-08-26.

## Asset manifest

Machine-readable at `scripts/asset-manifest.json`; `check-manifest.py` asserts
it. Summary:

| Asset | Path | State |
|---|---|---|
| `verify_citations.py` | `scripts/verify-citations.py` | live |
| `snippet_drift.py` | `scripts/check-snippet-fidelity.py` | live — 0.8 still owes declaration *bodies* |
| `q8-remote-reads.sol` + test | `snippets/q8-remote-reads.sol`, `snippets/test/Q8RemoteReads.t.sol` | live — **forge-test-run now, 6/6 green, gated in CI** |
| `q2-cross-chain-call.sol` + test | `snippets/q2-cross-chain-call.sol`, `snippets/test/Q2CrossChainCall.t.sol` | live — new in 1.1, 8/8 green |
| `flash-loan-guide.md` | — | **UNLOCATED.** Searched this repo, `eez-docs`, `agent-mesh` and `~/Downloads` on 2026-08-26. Ground rule 4: not done without a location. Blocks 1.2 from starting off a banked draft. |
| `eez-protocol-dev.skill` | `agent-mesh/eez-agent/skills/eez-protocol-dev/` | external — recorded, not gated (outside this repo) |

## Task cards

Statuses: `ready` · `blocked` · `in-flight` · `needs-human` · `done`.
Reconciled against the tree at `ede42e3`, which already carried part of Wave 0
from the protocol-content review (PR #14) — the v4.1 plan was written from a
pre-merge snapshot.

### Wave 0 — Mechanical integrity

**0.0 — Pin & error-name reconciliation** · `done` · XS
done-when: header block has zero blanks; grep transcript attached. ✔ Both above.
Deviation on the record: no name goes on the stale-names list, because the card's
premise that one of them is stale is false.

**0.1 — `llms-full.txt` export fix** · `done` · S
done-when: scripted step count asserted; CI fails on mismatch. ✔
`scripts/test_build_llms.py` now asserts a code block **per step, per page**,
against each page's own step count rather than a hardcoded 15 or 16. The old gate
was "at least one block", which a page losing two of three steps passes.
Verified by injecting a drop into the emitter and watching every page fail.

**0.2+0.3+0.4 — q2 mechanical bundle** · `done` · XS
done-when: `STATIC_CHECK_GAS == 1_000`; the comment names `transient
_staticDetector` and the slot-0 risk; the gas-cap rationale is present; zero
"read-only lookup" in q2; `scripts/check-snippet-fidelity.py` clean. ✔
Already shipped in PR #14 and re-verified here: `STATIC_CHECK_GAS == 1_000` in
snippet and panel; the comment names upstream's `transient _staticDetector`
(`CrossChainProxy.sol:18`, written at `:71`) and the raw-slot-0 collision risk;
the gas-cap rationale is present (static-context `tstore` = exceptional halt
consuming everything forwarded); zero "read-only lookup" in page copy (the only
hits are the review docs recording the finding); `check-snippet-fidelity.py`
clean.

**0.5 — q5 encoding conditions** · `done` · XS
done-when: q5 states `callGas = 0` except L2-origin under `USE_GAS_LEFT`, and L1
forces `sourceRollupId`. ✔ Both stated with citations, plus a live reachability
note that flags field combinations no manager would produce.

**0.6 — Move q5/q6 out of dapp track** · `blocked` by 2.4 · XS

**0.7 — CI wiring** · `done` · S
done-when: both scripts run on PR and block merge. ✔ — and the card understated
the job. Three checkers existed with **nothing running them**:
`check-snippet-fidelity.py`, `test_snippet_fidelity.py`, `test_build_llms.py`.
All three are in CI now, and `check-panel-height.cjs` has its own job with a
browser. That checker was also itself broken — the lead-in slide overlays
`#btnNext`, so it died before measuring anything; repairing it surfaced four
over-height panels (pr4 s1, pr5 s3, ro4 s2 and s3), all now fixed.

**0.8 — `snippet_drift.py` full declarations** · `ready` · M (end Wave 2)
Partially standing: `check-snippet-fidelity.py` compares named constants, error
declarations, struct field order and function **signatures**. Bodies are still
uncompared, which is exactly what the card owes.

**0.9 — Pin-age reporter** · `ready` · S — sequenced with Wave 3 per §6.

**0.10 — CAVEATS coverage assertion** · `ready` · S — sequenced with Wave 3.
Unblocked: `CAVEATS.md` is upstream at `docs/CAVEATS.md`, 13 lines, 4 bullets
(match-vs-execution-time failures, transient-phase self-containment,
indistinguishable revert reasons, differing opcodes). Cards 2.2/2.3/2.4/3.3 and
q8 cover them; the assertion is what makes that durable.

**0.11 — pr4 retitle** · `done` · XS
done-when: "attests" not "proves"; paragraph names Stateless re-execution,
ECDSA-for-succinctness, per-rollup prover swap. ✔ All three named with
citations. **Open decision:** the filename and canonical URL still say
`proves-a-batch`. Renaming breaks a live URL; q1 has the redirect-stub pattern
if we want it. Not taken silently.

**0.12 — ro4 atomicity caveat** · `done` · XS
done-when: same-L1-block + builder-inclusion qualifier present;
`EEZ_MAX_USER_TXS_PER_BUNDLE = 3` and the ~3-tx silent drop explained. ✔ The cap
and drop were already there; the qualifier was not, so "atomically" stood as an
unexamined premise. Both bounds now stated.

### Wave 1 — The differentiator

**1.1 — q2 returns a value** · `done` · S
done-when: snippet contains `balanceOf(user)` → decode → branch on result;
static-entry path named; failure case present; same-block constraint stated;
compiles; drift and stale-vocab greps clean. ✔ All of it, plus an 8-case runnable
test and a corrected `setValue` selector (the art said `55 24 1f 6b`; the real
selector is `0x55241077`).
**Still open — `needs-human`:** the acceptance interview. A reader unfamiliar
with EEZ has to answer "what does EEZ do that a bridge doesn't" off this page.
Nothing an agent runs substitutes for that.

**1.2 — Flash-loan guide** · `needs-human` (devnet, for the network-mode half) · L
The banked draft is unlocated (see asset manifest), and step 5's encoding
asymmetry still needs protocol-engineer review as a publish blocker.

**Run locally 2026-08-26; findings in
`docs/reviews/2026-08-26/1.2-flash-loan-local-run.md`.** The scenario
`script/e2e/nested/L1_to_L2/flash-loan/E2EFlashLoan.s.sol` executes and verifies
on anvil with no devnet — exit 0, seven PASS assertions across the L1 batch, the
L2 table and the L2 calls. That replaces the unlocated draft with something
better: an entry construction that can be read rather than guessed.

**Step 5's asymmetry is resolved, and the answer inverts the fear.** The scenario
hashes the return leg two ways — `crossChainCallHash` on the L1 side,
`crossChainCallHashL2Out` on the L2-outgoing side — but the second is a one-line
wrapper around the first, so they are byte-identical today. The run confirms it:
the L1 and L2 expected-hash lists are the same two values. The separate name is a
marker for when `useGasLeft` flips on, per its own doc comment. So *"the return
leg is hashed differently"* is wrong today, and *"one call, one hash"* is right
today and wrong the moment gas keying turns on. Same fact `q5` teaches under 0.5.

Protocol review is still a publish blocker, but the question is now a yes/no
rather than an open review: *is it correct to document the L2-outgoing key as
identical to the L1 key today, flagging `useGasLeft` as the single condition that
separates them?*

Still needs the live devnet: only the captured trace and the gas numbers feeding
4.2, because local mode has the test playing sequencer rather than a real
composer.

**1.3 — End-to-end quickstart** · `ready` (1.1 shipped) · L — cold-start test is
`needs-human`. Inherits the Guide format from 1.5 (below).

One cold-start defect is already known and should be in the quickstart or fixed
upstream first: **the e2e harness does not run on stock macOS.** `declare -A`
(bash 4+) at `E2EBase.sh:182` and three sites in `decode-trace.sh`, plus `set -u`
with empty-array expansion, which bash 3.2 calls unbound. macOS ships 3.2.57, so
a reader following `script/e2e/README.md` hits `declare: -A: invalid option` on
the first command with no indication why. CI cannot catch it — the runners are
ubuntu, where bash is 5.x. Both are reporting-path only, so the workaround is
local; details in `docs/reviews/2026-08-26/1.2-flash-loan-local-run.md`.

**1.4 — Lead Safe at N=2** · `blocked` — moved to Wave 2 · M
Timebox spent 2026-08-26; research recorded in
`docs/reviews/2026-08-26/1.4-encoding-research.md`. Outcome per the card's own
rule — *"overflow → Wave 2, never guess"*.

The protocol supports N=2; the e2e harness does not. There is no `L2_to_L2`
direction in any of the 22 scenarios, `DeployInfra.s.sol` asserts a single rollup
(`require(rid == 1)`), `chain.env` and the Kurtosis args each carry one L2, and
the only batch builder is `immediateSingleRollupBatch` — hardcoded to one
`RollupIdWithProofSystems` with zero `expectedStateRootPerRollup` pins.
`multi-call-two-diff`, which the card was reaching for, is two target *contracts*
on one L2, not two rollups.

Also on the record: the card's input path is wrong. `script/e2e/multi_call/` is in
`eez-core-protocol` at `contracts_pin`, not `eez-rollup0` at `node_pin`.

Building it means a second rollup in the infra, a second L2 in two configs, and a
multi-rollup batch builder. That is protocol-engineering work, not content work.
The card's required "same batch follows" caveat is already grounded for whenever
it happens — `docs/CAVEATS.md` states the same-batch rule outright.

**1.5 — Rolling hash** · `done` · L
done-when: covers 4-tuple collapse, seeding, tag chain, `CALL_NOT_FOUND`
anti-forgery, tagged/untagged asymmetry with justification; code illustrative not
copy-pasteable; zero stale names; the researcher takes home one reusable idea. ✔
Shipped as `protocol-researchers/pr6-the-rolling-hash.html`, seven steps, source
`docs/CORE_PROTOCOL_SPEC.md` §E and `EEZBase.sol`. Seven per-step citations, all
resolving at the pin. Checked by `scripts/audit.sh`,
`scripts/check-panel-drift.py` (ILLUSTRATIVE_ONLY) and
`scripts/check-panel-height.cjs`.

Deviation on the record: the card says **"4-tuple collapse"**. Upstream says
**triple** — `(hash, rollingHash, isStatic)` collapsed into one comparison
(`EEZBase.sol:244-245`), and that is the only tuple language anywhere in the
pinned tree. The page says triple. Related: spec §E calls `crossChainCallHash`
"seven-field" in one sentence, which is shorthand for the seven that *vary* once
`callGas` is constant — the formula is eight fields (§C), so q5's "8 FIELDS" is
right and was left alone.

The reusable idea is step 4: a hash chain plus domain tags already encodes
sequence, so folding a position counter is redundant — and the redundancy is not
free, because it forbids re-running a subsequence out of its original offset.
That is what lets a `revertNextNCalls` span be processed as a 0-based sub-slice.

### Wave 2 — The safety net

**2.1 — q8, reads that lie** · `ready` · M — **the forge-test blocker is
cleared**: `snippets/test/Q8RemoteReads.t.sol` runs 6/6 green locally and in CI,
including both negative cases. What the card still owes is coverage breadth —
`balance`/`extcodesize`/`extcodecopy`/`delegatecall` plus block context, and
closing the q4 gap (live proxy ≠ live target).

**2.2 — Same-block constraint, standalone** · `ready` · M
done-when: `lastVerifiedBlock == block.number`; no "later"; meta-hook same-batch
ceiling; a one-block-late failure shown then the working version; the reader can
name a design this kills.

**2.3 — Indistinguishable revert reasons** · `ready` · S
done-when: two byte-identical reverts from different causes; correct patterns
shown (`staticCrossChainCall` pre-flight, off-chain simulation); cross-links 2.4.
Note: `snippets/test/Q2CrossChainCall.t.sol` and `Q8RemoteReads.t.sol` already
demonstrate this executably — the standalone page can cite the tests rather than
re-derive it.

**2.4 — Failure catalogue** · `ready` · M
done-when: generated from `EEZ.sol`/`EEZL2.sol` errors at the pin, grouped by
root cause, "you saw X → check Y"; generation scripted so it stays current;
triggers 0.6. Input already gathered by 0.0: the two error sets differ by side,
and `EEZL2` carries eleven of its own.

**2.5 — Operator troubleshooting** · `ready` · M
done-when: nonce-gap livelock, dev-key incident, bundle limits, sibling-reorg /
Engine-API rules, the 48-block gate; cross-linked from ro1/ro3.

### Wave 3 — Depth and distribution

**3.1 — `revertNextNCalls`** · `ready` · M
done-when: forced rollback vs natural revert distinguished; `tload`/journal
semantics explained; failure case included.

**3.2 — Multi-prover + private-chains framing** · `ready` · M
done-when: per-rollup proof-system ownership demonstrated live; private-chains
framing labeled **roadmap** with both constraints stated (composer visibility;
ECDSA attestation today, ZK not live); no unqualified claim survives the gate.
0.11 lays the groundwork — `IProofSystem.sol:5-9` states there is no central
registry and each rollup owner vets its own set, so the per-rollup framing is
upstream's own words, not ours.

**3.3 — Unified reentrant table / meta-hook** · `ready` · M
done-when: transient-phase self-containment and the same-batch ceiling
explained; tamper demo embedded (one return value tampered → mismatch observed);
framing states that the script plays sequencer and production tables come from
the composer.

**3.4 — Distribution** · `blocked` by Tier-1 guides shipping
done-when: one article + one thread each for q2-reworked, flash loan,
quickstart, rolling hash, reads-that-lie; rolling hash first; every claim passes
claims-to-challenge; the caveat travels with the screenshot or the claim is cut.

### Wave 4 — Backfill (rolling)

**4.1 — Tests for q7/q4/pr5** · `ready` · S each
done-when: `forge test` green, negative cases included. Two of the seven landed
already (q8 in PR #14, q2 in 1.1), so this is q7, q4 and pr5.

**4.2 — Gas comparison** · `blocked` by 1.2 data capture · M
done-when: local vs cross-chain vs static-read table published from captured
numbers, not estimates.

**4.3 — Remaining use cases at N=2** · `ready` · M each
done-when: the unified-collateral *read* ships with the solvency-path correction
(composer liveness sits in your solvency path); bridging absorbed into the
quickstart family; no borrowed credibility.

**4.4 — IA pass** · `blocked` by index > ~20 items · M
done-when: the dapp-dev section is one ordered curriculum; constraints precede
designs; "First time here?" routes through same-block early. Index is at 17.

## The Guide format — pilot locked, awaiting sign-off

Ground rule 1 decides Guides are variable-length (3–12 steps), but every page in
the repo was a hardcoded three-step walkthrough and `scripts/new-demo.sh` only
scaffolds those. That looked like a blocker on all of Wave 1. It was smaller than
it looked: `stepLabel`, the dot row and every `*ByStep` array already derive from
`N`. The only hardcoding was the stage show/hide (`els.s1/s2/s3`), now a loop
over `N` with a startup assertion that every step has a stage div.

So a Guide, as shipped in pr6, is the same player with four differences:

1. `var N` is the real step count (7 here), pacing eased to 4200ms since the
   steps carry more reading.
2. No FULL toggle and no snippet, because the code is illustrative. The button is
   absent, `fullSnippet` is `[]`, and the player's existing `if (btnFull)` guards
   make that a no-op rather than a special case.
3. `citeByStep`, updated inside `render()`. A guide's panels span several files,
   so one fixed citation would be right on step 1 and wrong on the rest.
4. Registered in `check-panel-drift.py`'s `ILLUSTRATIVE_ONLY` with a written
   reason — an allowlist, not a skip, so "no snippet" can never mean "nobody
   looked".

**pr6 is the pilot. 1.2 and 1.3 should roll out to this template once it is
signed off, not before** — building three Guides against an unreviewed shape is
how a format gets locked in by accident.

## Measurement, re-read

| Metric | v4.1 said | Now | Checked by |
|---|---|---|---|
| Demos showing a returned value in use | 0/15 | **1/16** (q2) | rubric + decode-and-branch grep |
| Actionable use-case demos | 0 | 0 | rubric |
| Critical footguns covered | 0/4 | 0/4 | 0.10 assertion (not yet written) |
| Contract-side researcher demos | 0/5 | 0/5 | rubric |
| Solidity demos with tests | 3/7 | **5/8** | `forge test` in CI |
| Formats shipped | 2/4 | **3/4** (Guides now shipped) | manual |
| Max citation pin age | unmeasured | unmeasured | 0.9 reporter (not yet written) |

Target for the first metric is ≥3. q2 is one; 1.3 and 4.3 are the other two.
