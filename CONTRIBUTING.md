# Contributing to eez-demos

This repo is internal team + core contributors. PRs go through review before merge — nothing merges to `main` without it.

## Before you start a new demo

Open (or claim) a GitHub Issue for the topic first, so two people don't build the same thing. Use the "New demo topic" issue template.

## The one hard rule: verify against real source, don't paraphrase

Every code panel in every demo must be **verbatim** from the actual source, with an exact `file:line` citation somewhere on the page (usually the code panel's header). Two sources of truth, by layer:

- **Contract layer** (proxies, calls, registration, reentrancy): [`eez-association/eez-core-protocol`](https://github.com/eez-association/eez-core-protocol) @ `main`
- **Infra layer** (sequencer, composer, proof-signer, deriver, devnet): [`eez-association/eez-rollup0`](https://github.com/eez-association/eez-rollup0) @ `main`

Both repos move fast. Before writing a code panel: `git pull` (or re-clone) fresh, read the actual file, and quote it exactly — including comments. Never write code that "looks like" what the contract/crate probably does. If you can't find something in source, say so in the PR description rather than inventing a plausible-looking signature.

**Re-verify before merge, not just at authoring time.** If a PR sits open for more than a few days, re-check its code panels against source before merging — both repos change often enough that a page can go stale between opening a PR and merging it.

## House visual style

Match the existing demos exactly — don't introduce a new look per contributor.

- **Stage:** fixed `1920×1080`, scaled to fit via `transform: scale()`. Dark canvas `#0b0f14`.
- **Type:** IBM Plex Sans (body) + IBM Plex Mono (code, labels, kickers). Load via the same Google Fonts `<link>` every existing demo uses.
- **Palette:** reuse the existing per-entity colors — `#7c83ff` (L1/origin), `#f0a83c` (L2/destination), `#b478f0` (proxy/alias/reentrant), `#3fb950` (EEZ/success/brand green), `#f85149` (revert/error). Don't invent new hues for the same kind of thing.
- **Structure:** top chrome (brand mark, track label, demo title, `SPEC · NOT LIVE` badge, step counter) → diagram/code-panel split → bottom bar (kicker, caption, Prev/Play/Next, step dots, color legend). Step-driven: an array of captions + an array of highlighted code-line indices per step, not free-form scrolling.
- **The "why this demo" modal:** every demo auto-opens a dismissible modal on load — purpose paragraph + 3 takeaways — reopenable via a small pill in the top chrome. Copy this structure from any existing demo (`d-msg-sender-through-proxy.html` is a clean reference).
- **Accessibility baseline:** `prefers-reduced-motion` respected, keyboard focus visible, Escape closes the modal.

The fastest way to get this right: copy an existing demo file closest in shape to your new topic and edit it, rather than starting from a blank page.

## Adding to the index

New demos get a card in `index.html` under the correct track, plus (if it's a foundational topic) consideration for the `start-here.html` guided path. Don't invent a fourth track without raising it as an Issue first — the three-track split (Builder / Rollup-integrator / Node-operator) is a deliberate scope boundary, not an accident.

## The "coming soon" honesty rule

If a capability doesn't exist yet (a partner integration, a feature still in development), it gets an honest "coming soon" note with no live link — never a CTA that implies something works when it doesn't. `SPEC · NOT LIVE` badges the same way: don't let any page imply EEZ is live/audited when it isn't.

## Before opening a PR

- [ ] Every code panel cites real `file:line` from the correct source repo, checked against a fresh pull
- [ ] The "why this demo" modal is present and accurate
- [ ] Visual style matches the existing demos (stage size, palette, type, structure)
- [ ] Added to `index.html` under the correct track
- [ ] Opens cleanly in a browser — no console errors, step navigation works end to end
