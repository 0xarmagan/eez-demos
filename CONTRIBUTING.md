# Contributing to eez-demos

Internal team + core contributors. PRs go through review before merge. Claim a topic via GitHub Issue before starting.

## Format

Every example is two layers:

1. **A card** on `index.html` — action-oriented title (what you're doing, not the mechanic's internal name) + a one-sentence hook stating the *consequence*, not the mechanic ("reorder the fields and you get a silently different hash," not "eight fields in order"). No code on the card. Badge is time to *watch the walkthrough*, not to complete the real process — don't blur those for an infra example with real setup cost. CTA is always `WATCH THE 3-STEP WALKTHROUGH →`.
2. **An animated walkthrough** (`qN-slug.html`) — copy `q1-compute-your-cross-chain-address.html` as the template and keep:
   - Fixed 1920×1080 stage, diagram left / code right / caption bottom / Prev-Play-Next — not up for redesign.
   - `codeByStep`: progressive reveal per step, never a full file dumped at once.
   - Real data in the diagram (actual bytes, values, state) — never placeholder boxes.
   - The `PRE-MAINNET` label, the header's `NEXT: <title> →` link (through the fixed sequence on `index.html`; the last example links back to the index instead), and `scaleStage()`'s mobile floor (`s < 0.58`, switches to a scrollable layout) — all already in `q1`. Copy them, don't reinvent.

## Source of truth — verify against real code, not memory

Every snippet is **verbatim**, cited by exact `file:line`. This repo is strictly `eez-rollup0`:

- **Infra** — cite `eez-rollup0` @ `main` directly.
- **Contracts** — `eez-core-protocol` is a **submodule** of `eez-rollup0`, pinned to a commit, not tracking `main`. Cite it as `eez-core-protocol/<path>:<line>` and verify against that *pinned* commit (`git ls-tree HEAD eez-core-protocol`) — not `eez-core-protocol`'s own `main`. They drift; a citation can be accurate against one and wrong against the other.

Re-pull fresh before writing anything, and again before merge if a PR sat open a few days. If you can't verify something, say so in the PR rather than inventing a plausible signature.

## Honesty

No card or caption implies something works, or costs less time, than it does. An empty audience section gets a plain "coming soon" note, never a fabricated example.

## Before opening a PR

- [ ] Every snippet verified against a fresh pull — against the pinned commit for anything under `eez-core-protocol`
- [ ] Hook states a consequence, not a restatement of the title
- [ ] Card matches the existing visual style; walkthrough matches `q1`'s structure exactly
- [ ] Filed under the correct audience section; `NEXT:` chain updated on both neighbors
- [ ] Renders cleanly at ~360px wide, no horizontal overflow
