# Contributing to eez-demos

This repo is internal team + core contributors. PRs go through review before merge.

## Format (changed 2026-08-18 — read this before touching the old style)

This is **not** the animated step-through demo format anymore. It's one page, one example card per topic: a title, a one-line description, a real code snippet, and a `file:line` citation. Less text, more code. If you find yourself writing more than 2-3 sentences of description on a card, the example is probably trying to teach two things — split it.

Before you start a new example, open (or claim) a GitHub Issue for the topic first.

## The one hard rule: verify against real source, don't paraphrase

Every snippet must be **verbatim** from the actual source, cited by exact `file:line`. Two sources of truth:

- **Contract layer**: [`eez-association/eez-core-protocol`](https://github.com/eez-association/eez-core-protocol) @ `main`
- **Infra layer**: [`eez-association/eez-rollup0`](https://github.com/eez-association/eez-rollup0) @ `main`

Both move fast — `git pull` (or re-clone) fresh before writing anything, and re-check before merge if a PR sat open more than a few days. If you can't verify something, say so in the PR description rather than inventing a plausible-looking signature.

## Card format

Each example is a `.card` in `index.html`'s grid, under the right audience section:

- **Title** — action-oriented, states what you're doing ("Compute your cross-chain address"), not the mechanic's internal name.
- **One-line description** — what it does and why you'd reach for it. One sentence, two max.
- **A time badge** — `quick` (green, ≤3 min to read/adapt) or `medium` (amber, 4-6 min). Nothing on this page should take longer than that; if it does, it's not a basic example.
- **A real code snippet** — short enough to read at a glance, long enough to actually copy-paste and use.
- **A `file:line` citation** with a link to the real source line.

Match the existing cards' visual style exactly — same palette, same card shape, same badge colors. Don't introduce a new look per contributor.

## The "coming soon" honesty rule

An audience section with no examples yet gets an honest "coming soon" note, not empty space or a fabricated example. Never write a card that implies something works when it doesn't — `SPEC · NOT LIVE` badges every page for the same reason.

## Before opening a PR

- [ ] Every snippet cites real `file:line`, checked against a fresh pull
- [ ] Description is 1-2 sentences, not a paragraph
- [ ] Card matches the existing visual style
- [ ] Added under the correct audience section
- [ ] No horizontal overflow — check the card renders cleanly at ~360px wide (the grid's minimum column width)
