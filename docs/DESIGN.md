# eez-demos — founding design

**Date:** 2026-08-18
**Status:** approved, in initial build

## Why this repo exists

`eez-contract-demos` proved the format: real verbatim code + narrated flow, in one frame, teaches EEZ mechanics well. Two things it didn't cover:

1. **The Rollup0 layer.** EEZ isn't just contracts — `eez-rollup0` is the actual off-chain infra (sequencer, composer, proof-signer, deriver) that runs a real chain against Gnosis Chiado, including a working Kurtosis local devnet. None of that had explainer content.
2. **Collaboration.** The old repo was single-author. This one is built for internal team + core contributors from day one — Issues for topic tracking, a written style guide, required review.

`eez-demos` consolidates the existing 8 contract demos and adds the Rollup0/infra layer under one roof, going forward. `eez-contract-demos` is archived, not deleted — history and any existing links stay intact, but it stops taking changes.

## Scope: three tracks, not four

- **Builder track** — dapp-developer contract mechanics (A, C, D, F, H — proxy derivation, call encoding, msg.sender, reentrancy, L1↔L2 split)
- **Rollup-integrator track** — contract mechanics for rollup operators (E, G — multi-prover threshold, registration)
- **Node-operator / Rollup0 track** (new) — the actual infra: how a chain runs, day to day

A fourth track isn't ruled out, but it's a deliberate boundary, not an oversight — raise it as an Issue before adding one.

## First Rollup0-track batch (basic → deeper)

1. How to Run the EEZ Devnet with Kurtosis
2. The Four Components of Rollup0 (sequencer / composer / proof-signer / deriver)
3. Sync Blocks
4. Cross-Chain Ingress Fronts
5. Commit-First, Repair-If-Needed
6. The Deriver

Deeper topics (proof-signer internals, the deploy-protocol flow, the `xchain-test.sh` test driver) are wave 2 — tracked as Issues once this batch ships, not pre-committed here.

## Format decision

Same interactive animated-demo format as the existing 8 — not written runnable guides — even for hands-on topics like the Kurtosis devnet. Consistency of format was weighted over format-fits-topic for this batch; if a future topic genuinely needs a runnable guide instead (not just an explainer), that's a new decision to raise, not an extension of this one.

## Source of truth: eez-rollup0, one repository

This repo is strictly scoped to `eez-rollup0`. Every example — dapp-dev included — has to trace back to something physically inside that one repository:

- Infra layer → `eez-association/eez-rollup0` @ `main` directly.
- Contract layer → `eez-core-protocol`, a **git submodule of `eez-rollup0`** (pinned by a gitlink commit, not tracking `main`). Cited as `eez-core-protocol/<path>:<line>` and verified against the exact pinned commit — not `eez-core-protocol`'s own independently-moving `main`, which drifts ahead of what's actually vendored.

Both move fast. Every code panel cites a real `file:line`; nothing is paraphrased or invented. See `CONTRIBUTING.md` for the full rule and the pre-PR checklist.

## Collaboration model

- Private repo, internal team + core contributors.
- GitHub Issues for topic proposals/tracking (not a markdown backlog — more discoverable for multiple contributors).
- Branch protection on `main` (PR + review required, no direct pushes) is the intent, but **not currently enforced** — GitHub requires a paid plan to set branch protection on a private repo, and this account is on the free tier. Until that's resolved (upgrade, or make the repo public), this is a convention everyone needs to actually follow, not a guardrail GitHub enforces. Revisit once the plan situation changes.
- House style is written down (`CONTRIBUTING.md`), not tribal knowledge — the point of writing it down is that a new contributor's first demo should already look like it belongs.

## What's explicitly out of scope for this phase

- Making the repo public (may happen later, per its own decision)
- A written/runnable-guide format track (rejected in favor of format consistency — see above)
- Migrating `eez-remotion`, `eez-uc-html-pipeline`, or other EEZ creative-content pipelines into this repo — this is specifically the interactive-explainer surface, not a general EEZ content home

---

## Revision (2026-08-18, same day) — format pivot

The animated-demo format above (all 14 A–N demos) was **deleted**, not iterated on. Feedback: too much prose per topic, not example-forward enough; inspiration pulled from build.nvidia.com/spark's dense card-grid pattern (title + one-line description + a real snippet, scannable, no click-through required for a basic example).

**New format:** one `index.html`, one card per example, grouped by audience — **dapp developers, rollup operators, protocol researchers** (a genuine 3rd audience, replacing the old "Rollup-integrator" framing) — instead of by protocol layer/track. Each card: title, 1-2 sentence description, a real verbatim snippet, a time badge (quick/medium), a `file:line` citation. No steps, no animation, no per-demo modal.

Dapp-developer audience shipped first with 6 basic examples (computing a proxy address, sending a cross-chain call, the msg.sender gotcha + fix, checking if an address is a proxy, encoding a call hash, why direct manager calls revert) — all re-verified against a fresh `eez-core-protocol` pull at pivot time. Rollup-operator and protocol-researcher sections are honest "coming soon" placeholders, not fabricated content.

Everything else in this doc (source-of-truth split, collaboration model, branch-protection gap, three-audience boundary) still holds — only the presentation format changed, not the underlying rules.

---

## Revision 2 (2026-08-18, same day) — animated walkthroughs came back, then got fixed

Feedback: cards alone weren't enough, bring the animated step-through format back per example — but adapted to the new card content, not restored as-is.

Then a direct audit (`q1-compute-your-cross-chain-address.html`, flagged as "weak") found the real problem: not the animation format itself, but two execution flaws inherited from the old A–N demos — a mostly-empty diagram panel (two small labeled boxes in a huge void) and a code panel dumping the entire function grayed out from step 1. Fixed both, kept the format: diagrams now show real transforming data (actual hex bytes packing/hashing/extracting an address, an actual mapping lookup), code panels reveal only the current step's lines. Applied to all 6. Rule captured in `CONTRIBUTING.md`'s "Animated walkthrough rules" so Rollup0 examples inherit the fix, not the original flaw.

**Current format, settled:** a card on `index.html` (title, description, snippet, citation) links to a short (3-step) animated walkthrough. Both layers required per example.

---

## Revision 3 (2026-08-18, same day) — brand redesign, then a Rollup0 capability re-audit

Feedback: the page "looked so AI" — generic dark cards with a colored rail per category, IBM Plex type. Checked eez.io for the real brand language and rebuilt the chrome on it: pure black canvas + faint grid texture, Geist/Geist Mono type, a mixed-weight headline split, bracket-wrapped eyebrows (`[ LABEL ]`), pill CTAs with a trailing circle-arrow, and cards that are flat/monochrome with the brand's green→blue→purple gradient reserved for the hover state only, not per-category branding. Cards dropped their code snippet entirely — hook line + "WATCH THE WALKTHROUGH" CTA, whole card clickable. The code panel in every walkthrough got a real terminal treatment: traffic-light window chrome, line numbers, a blinking cursor. The `SPEC · NOT LIVE` badge and a duplicate audience-nav block were cut as redundant.

Then re-audited `eez-rollup0` for capability the original 5 Rollup0 examples missed. Found real, previously-undiscovered infrastructure: a documented real-Chiado-testnet run path (`scripts/chiado-up.sh`, distinct from the local Kurtosis devnet), the two cross-chain ingress fronts with real ports and a real operational gotcha (`EEZ_MAX_USER_TXS_PER_BUNDLE=3`, silently enforced by rbuilder-chiado), the cross-chain test driver (`scripts/xchain-test.sh`) that exercises both fronts through the full op matrix and reports real pipeline metrics, and the composer↔proof-signer wire contract (`prove.proto`, a real gRPC service with concrete message shapes). Added four new examples from this — two Rollup Operator (`Run a real Chiado L2`, `Send & test cross-chain calls`), one Protocol Researcher (`How the composer proves a batch`) — bringing the set to 6 / 4 / 4 = 14. Rollup Operators and Protocol Researchers moved to a 2-column card grid (an even 4 items no longer divides cleanly into 3 columns without a phantom empty cell).

---

## Revision 4 (2026-08-19) — dapp-dev reframe, then a strict-single-repo audit

Feedback, repeated: dapp-dev examples were drifting toward niche edge cases (a proxy-check utility, manual content-hash encoding) instead of leading with generic mechanics. Reordered the 6 to teach the core mechanic set in order (address → send → msg.sender resolution → registry → access control → the one genuinely advanced topic, content-hash encoding, moved last) and renamed three cards out of "gotcha"/"can't" framing into plain mechanic descriptions. A DevEx pass (methodology, not vibes: measured hook word-counts, grepped for synonym drift) then found and fixed a real bug — "alias" used as an undefined synonym for "proxy" in 5 places across two demos, including one diagram showing both terms side by side in the same element.

Then a stricter rule: **every example must trace to something physically inside `eez-rollup0`**, dapp-dev included. This surfaced a real, previously-invisible accuracy bug: `eez-core-protocol` is a git submodule of `eez-rollup0`, pinned by a gitlink commit — but the 6 dapp-dev demos had been verified against `eez-core-protocol`'s own independently-moving `main`, which had drifted two weeks ahead of what `eez-rollup0` actually pins. One citation (`EEZ.sol:786`) was accurate against the wrong ground truth and wrong against the right one — `executeCrossChainCall` had shifted to line 790 in between. Re-verified all 6 against the actual pinned commit, fixed the line-shift, and re-cited every one as `eez-core-protocol/<path>:<line>` (the real path as it sits inside `eez-rollup0`) instead of a bare filename that read as an unrelated repo. The 8 Rollup0-native examples cite `eez-rollup0` directly, so the pin issue never applied to them — re-checked anyway, all still accurate.
