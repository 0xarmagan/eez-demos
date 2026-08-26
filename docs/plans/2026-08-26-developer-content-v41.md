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

**1.2 — Flash-loan guide** · `needs-human` (devnet) · L
Additionally blocked before the devnet session: the banked draft is unlocated
(see asset manifest). Step 5's encoding asymmetry still needs protocol-engineer
review as a publish blocker.

**1.3 — End-to-end quickstart** · `ready` (1.1 shipped) · L — cold-start test is
`needs-human`.

**1.4 — Lead Safe at N=2** · `ready` (timeboxed 1 day) · M — module code review
is a publish blocker.

**1.5 — Rolling hash** · `ready` · L — parallel desk work, not started.

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
designs; "First time here?" routes through same-block early. Index is at 16.

## Measurement, re-read

| Metric | v4.1 said | Now | Checked by |
|---|---|---|---|
| Demos showing a returned value in use | 0/15 | **1/16** (q2) | rubric + decode-and-branch grep |
| Actionable use-case demos | 0 | 0 | rubric |
| Critical footguns covered | 0/4 | 0/4 | 0.10 assertion (not yet written) |
| Contract-side researcher demos | 0/5 | 0/5 | rubric |
| Solidity demos with tests | 3/7 | **5/8** | `forge test` in CI |
| Formats shipped | 2/4 | 2/4 | manual |
| Max citation pin age | unmeasured | unmeasured | 0.9 reporter (not yet written) |

Target for the first metric is ≥3. q2 is one; 1.3 and 4.3 are the other two.
