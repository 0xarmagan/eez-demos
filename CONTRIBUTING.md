# Contributing to eez-demos

Public repo, core-team maintained. Right now it's a single maintainer with no enforced branch protection — the review/audit sections below are the target process for once a second contributor is added, and worth self-applying with fresh eyes even solo in the meantime. Open (or claim) a GitHub Issue for the topic first if you want to avoid overlap — not a hard gate for a quick addition.

## Run it locally

The site uses a few absolute paths (`/favicon.svg`, the analytics script), so opening `index.html` straight from disk breaks the favicon. Serve it instead:

```bash
git clone git@github.com:0xarmagan/eez-demos.git
cd eez-demos
npx serve .          # or: python3 -m http.server 8000
```

No install, no build step, no dependencies — just a static file server rooted at the repo. Open the printed localhost URL and click through everything before opening a PR.

## Add a new example

```bash
scripts/new-demo.sh <dapp-developers|rollup-operators|protocol-researchers> <slug> "<Title>"
# e.g.
scripts/new-demo.sh rollup-operators ro5-my-new-topic "My New Topic"
```

This scaffolds a structurally-correct file from the `q1` template — fixed stage, terminal code panel, `PRE-MAINNET` label, mobile floor, all already wired — with every piece of *topic-specific* content (diagram, `codeByStep`, citation, kickers, captions) replaced with an obvious `TODO`. It does not touch `index.html` or the `NEXT:` chain; that's still on you, see the checklist below.

## Format

Every example is two layers:

1. **A card** on `index.html` — action-oriented title (what you're doing, not the mechanic's internal name) + a one-sentence hook stating the *consequence*, not the mechanic ("reorder the fields and you get a silently different hash," not "eight fields in order"). No code on the card. Badge is time to *watch the walkthrough*, not to complete the real process — don't blur those for an infra example with real setup cost. CTA is always `WATCH THE 3-STEP WALKTHROUGH →`.
2. **An animated walkthrough**, filed under the matching folder (`dapp-developers/`, `rollup-operators/`, or `protocol-researchers/`) — copy `dapp-developers/q1-compute-your-cross-chain-address.html` as the template and keep:
   - Fixed 1920×1080 stage, diagram left / code right / caption bottom / Prev-Play-Next — not up for redesign.
   - `codeByStep`: progressive reveal per step, never a full file dumped at once.
   - Real data in the diagram (actual bytes, values, state) — never placeholder boxes.
   - The `PRE-MAINNET` label, the header's `NEXT: <title> →` link (through the fixed sequence on `index.html`; the last example links back to the index instead), and `scaleStage()`'s mobile floor (`s < 0.58`, switches to a scrollable layout) — all already in `q1`. Copy them, don't reinvent.
   - The back link and index link are `../index.html` (walkthroughs live one folder down); a `NEXT:` link crossing into a different audience folder needs the folder in its path too (`../rollup-operators/ro1-....html`), same-folder ones just need the filename.

## Source of truth — verify against real code, not memory

Every snippet is **verbatim**, cited by exact `file:line`. This repo is strictly `eez-rollup0`:

- **Infra** — cite `eez-rollup0` @ `main` directly.
- **Contracts** — `eez-core-protocol` is a **submodule** of `eez-rollup0`, pinned to a commit, not tracking `main`. Cite it as `eez-core-protocol/<path>:<line>` and verify against that *pinned* commit (`git ls-tree HEAD eez-core-protocol`) — not `eez-core-protocol`'s own `main`. They drift; a citation can be accurate against one and wrong against the other.

Re-pull fresh before writing anything, and again before merge if a PR sat open a few days. If you can't verify something, say so in the PR rather than inventing a plausible signature.

## Honesty

No card or caption implies something works, or costs less time, than it does. An empty audience section gets a plain "coming soon" note, never a fabricated example.

## Before opening a PR

Run `scripts/audit.sh` first — it's a fast automated pass (broken links, invalid JS, leftover `TODO`s, marketing language, missing citation paths) that catches the mechanical stuff so the human audit below can focus on what can't be scripted.

- [ ] `scripts/audit.sh` passes
- [ ] Every snippet verified against a fresh pull — against the pinned commit for anything under `eez-core-protocol`
- [ ] Hook states a consequence, not a restatement of the title
- [ ] Card matches the existing visual style; walkthrough matches `q1`'s structure exactly
- [ ] Added a card on `index.html`, under the correct audience section
- [ ] `NEXT:` chain updated on both neighbors (the demo before it, and this one's own link)
- [ ] Served locally and clicked through all 3 steps — not just eyeballed the source

## Audit, before merge

This is meant as a second, independent pass — done by whoever reviews the PR, not just the author re-reading their own checklist. With a second contributor, that's literally who this is. Solo, it's still worth doing as a deliberate second look with fresh eyes, not folded into the checklist above — every real bug found in this repo so far (a submodule-pinned citation that had drifted, a `deployments.env` preview with invented variable names, "alias" used as an undefined synonym for "proxy" in two demos, a leftover marketing word, and a batch of infra-layer citations missing their `crates/` path or pointing at a line that had since moved) survived the first read-through and was only caught on a re-check against the actual source. Don't skip this because the diff looks clean.

1. **Re-run `scripts/audit.sh` yourself** — don't trust that the author ran it, or that nothing changed since they did.
2. **Re-verify every citation against a fresh clone** — not the PR's word for it. For anything under `eez-core-protocol`, check out the exact commit `eez-rollup0` pins (`git ls-tree HEAD eez-core-protocol`), not `main` — they drift.
3. **Check the diagram against the code panel** — does the diagram show the same real function, struct, or value the citation points at, or does it just *look* plausible?
4. **Grep the term across all 14 demos** before accepting a new name for something — a second name for a concept that already has one is exactly how "alias" vs "proxy" happened.
5. **Serve it locally and click through all 3 steps yourself** — a diff review alone won't catch a broken `NEXT:` link or a step that renders wrong.

If any of these turn up something, fix it before merge — don't file a follow-up issue for a page that's already live.
