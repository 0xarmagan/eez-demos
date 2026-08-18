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

## Source of truth, by layer

- Contract layer → `eez-association/eez-core-protocol` @ `main`
- Infra layer → `eez-association/eez-rollup0` @ `main`

Both move fast. Every code panel cites a real `file:line`; nothing is paraphrased or invented. See `CONTRIBUTING.md` for the full rule and the pre-PR checklist.

## Collaboration model

- Private repo, internal team + core contributors.
- GitHub Issues for topic proposals/tracking (not a markdown backlog — more discoverable for multiple contributors).
- Branch protection on `main`: PR + review required, no direct pushes.
- House style is written down (`CONTRIBUTING.md`), not tribal knowledge — the point of writing it down is that a new contributor's first demo should already look like it belongs.

## What's explicitly out of scope for this phase

- Making the repo public (may happen later, per its own decision)
- A written/runnable-guide format track (rejected in favor of format consistency — see above)
- Migrating `eez-remotion`, `eez-uc-html-pipeline`, or other EEZ creative-content pipelines into this repo — this is specifically the interactive-explainer surface, not a general EEZ content home
