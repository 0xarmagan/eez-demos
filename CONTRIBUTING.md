# Contributing to eez-demos

This repo is internal team + core contributors. PRs go through review before merge.

## Format (settled 2026-08-18, revised same day)

Two layers, both required for a new example:

1. **A card on `index.html`** — title + a one-sentence hook that states the *consequence*, not just the mechanic (compare "one hash, eight fields" to "reorder the fields and you get a silently different hash" — the second is why anyone should care). No code snippet on the card itself — that lives in the walkthrough. Whole card is a clickable link.
2. **A short animated walkthrough** (`qN-slug.html`) the card links to — same stage/diagram/code/caption format as the original demos, 3 steps, one sentence per caption. See "Animated walkthrough rules" below before building one.

Before you start a new example, open (or claim) a GitHub Issue for the topic first.

## Animated walkthrough rules (learned from a real audit — apply to every one, Rollup0 included)

Copy `q1-compute-your-cross-chain-address.html` as your structural template. Two things that make a walkthrough weak, checked in that audit and fixed everywhere:

1. **Code panel shows only the current step's lines, revealed progressively.** Never dump the whole function/file grayed out from step 1 — that reads as a wall of dead text. Use a `codeByStep` array (one array of lines per step), not one static array highlighted in place.
2. **The diagram must show real data, not just labeled boxes.** Actual bytes, actual values, actual state transforming across steps — not two empty boxes and an arrow. If a topic's diagram would otherwise be sparse, find the real data to visualize (a block, a batch, an event) instead of settling for placeholders.

Keep the stage/panel/control structure (fixed 1920×1080, diagram left, code right, caption bottom, Prev/Play/Next) — that part isn't up for redesign per demo.

## The one hard rule: verify against real source, don't paraphrase

Every snippet must be **verbatim** from the actual source, cited by exact `file:line`. Two sources of truth:

- **Contract layer**: [`eez-association/eez-core-protocol`](https://github.com/eez-association/eez-core-protocol) @ `main`
- **Infra layer**: [`eez-association/eez-rollup0`](https://github.com/eez-association/eez-rollup0) @ `main`

Both move fast — `git pull` (or re-clone) fresh before writing anything, and re-check before merge if a PR sat open more than a few days. If you can't verify something, say so in the PR description rather than inventing a plausible-looking signature.

## Card format

Each example is a `.card` in `index.html`'s grid, under the right audience section:

- **Title** — action-oriented, states what you're doing ("Compute your cross-chain address"), not the mechanic's internal name.
- **A one-sentence hook** — the consequence or reason to care, not a restatement of the title. Ask "so what?" before shipping it — if the answer isn't in the sentence, it's still a mechanic description, not a hook.
- **A time badge** — this is time to *watch the 3-step walkthrough*, not time to complete the real process it depicts. For a contract-level snippet those are close enough not to matter; for an infra walkthrough (deploying a real testnet, running a load test) they are NOT the same number, and the badge must not blur them. If a walkthrough depicts something that takes real setup time (docker builds, funding a faucet, a multi-minute sync), say so honestly in the hook or caption rather than let the badge imply otherwise.
- **CTA** — "WATCH THE 3-STEP WALKTHROUGH →", exactly, on every card. Consistency here is deliberate — 14 cards with 14 different CTAs would cost more scanability than it buys in novelty.

Match the existing cards' visual style exactly — same palette, same card shape. Don't introduce a new look per contributor.

## The "coming soon" honesty rule

An audience section with no examples yet gets an honest "coming soon" note, not empty space or a fabricated example. Never write a card or caption that implies something works, or takes less time/effort, than it really does.

## Before opening a PR

- [ ] Every snippet cites real `file:line`, checked against a fresh pull
- [ ] Description is 1-2 sentences, not a paragraph
- [ ] Card matches the existing visual style
- [ ] Added under the correct audience section
- [ ] No horizontal overflow — check the card renders cleanly at ~360px wide (the grid's minimum column width)
