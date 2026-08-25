# Contributing to eez-demos

Single maintainer right now, no enforced branch protection — the checklist and audit pass below are still worth self-applying solo.

## Run it locally

```bash
git clone git@github.com:0xarmagan/eez-demos.git
cd eez-demos
npx serve .          # or: python3 -m http.server 8000
```

No build step, no dependencies — but serve it rather than opening `index.html` from disk, since a few paths are absolute (the favicon breaks otherwise).

## Add a new example

```bash
scripts/new-demo.sh <dapp-developers|rollup-operators|protocol-researchers> <slug> "<Title>"
```

Scaffolds a structurally-correct file from the `q1` template (stage, code panel, `PRE-MAINNET` label, mobile floor — all pre-wired), with topic-specific content (diagram, `codeByStep`, citation, captions) marked `TODO`. Doesn't touch `index.html` or the `NEXT:` chain — that's manual.

## Format

- **Card** on `index.html`: action-oriented title, one-sentence hook stating the *consequence* (not the mechanic — "reorder the fields and you get a silently different hash," not "eight fields in order"). No code on the card. CTA is always `WATCH THE 3-STEP WALKTHROUGH →`.
- **Walkthrough**: copy `dapp-developers/q1-compute-your-cross-chain-address.html` as the template. Keep the fixed 1920×1080 stage (diagram left / code right / caption bottom / Prev-Play-Next), progressive `codeByStep` reveal, real data in the diagram (never placeholder boxes), the `PRE-MAINNET` label, the `NEXT:` link chain, and `scaleStage()`'s mobile floor — don't redesign these.
- Links: back/index links are `../index.html`. A `NEXT:` link into a different audience folder needs that folder in its path (`../rollup-operators/ro1-....html`); same-folder links just need the filename.

## Source of truth

Every snippet is verbatim, cited by exact `file:line`, against `eez-rollup0`:

- **Infra** — cite `eez-rollup0` @ `main`.
- **Contracts** — `eez-core-protocol` is a submodule, pinned to a commit, not tracking `main`. Cite `eez-core-protocol/<path>:<line>` and verify against that pinned commit (`git ls-tree HEAD eez-core-protocol`), not its own `main` — they drift.

Re-pull before writing anything, and again before merge if a PR sat open a while. If you can't verify something, say so rather than inventing a plausible signature.

No card or caption implies something works, or costs less time, than it does. An empty section gets "coming soon," never a fabricated example.

## Before opening a PR

Run the three checks first — they catch mechanically what the human pass below shouldn't spend attention on. CI runs the same three.

```bash
bash scripts/audit.sh                    # links, JS syntax, TODOs, citation paths
python3 scripts/verify-citations.py      # every citation vs real source at its pinned SHA
python3 scripts/check-panel-drift.py     # every panel line vs a compilable snippet
cd snippets && forge build && forge test # snippets compile, the tests pass
```

Edited a `snippets/*.sol`? The FULL toggle embeds a verbatim copy of it in the page,
and the drift check asserts the two match line for line. Re-embed rather than
hand-syncing a 40-to-95-line array:

```bash
python3 scripts/sync-embedded-snippets.py          # re-embed where needed
python3 scripts/sync-embedded-snippets.py --check  # report only
```

Changed any page content, snippet or citation? `llms.txt` and `llms-full.txt` are
generated from them, so rebuild or CI will fail:

```bash
python3 scripts/build-llms.py           # rebuild both
python3 scripts/build-llms.py --check   # report only
```

- [ ] `scripts/audit.sh` passes
- [ ] `scripts/verify-citations.py` passes — this replaces re-checking citations by hand
- [ ] `scripts/check-panel-drift.py` passes; new Solidity pages registered in its `SNIPPET_MAP`
- [ ] Hook states a consequence, not a restatement of the title
- [ ] Card matches the existing visual style; walkthrough matches `q1`'s structure
- [ ] Added a card on `index.html`, under the correct audience section
- [ ] `NEXT:` chain updated on both neighbors
- [ ] Served locally and clicked through all 3 steps — not just eyeballed the source

## Audit, before merge

A second, independent pass — every real bug in this repo so far (a drifted submodule citation, an invented variable name, an undefined synonym used for an existing term, a stray marketing word, infra citations missing their `crates/` path) survived the first read and was only caught here. Don't skip it because the diff looks clean.

1. Re-run `scripts/audit.sh` yourself — don't trust that it was run, or that nothing changed since.
2. Re-run `scripts/verify-citations.py` — it fetches each cited file at the SHA in `scripts/citation-pins.json` and asserts the line and symbol still match, so citations no longer need checking by hand. What still needs judgment: whether the cited line is the *right* line to point at. The verifier accepts any line whose symbol matches within a few lines; it caught `EEZ.sol:790` pointing 10 lines into a function body, but it can't tell you a citation is pedagogically misaimed.
3. Check the diagram against the code panel — same real function/struct/value, or just plausible-looking?
4. Grep the term across all 14 demos before accepting a new name for something already named.
5. Serve it locally and click through all 3 steps yourself — a diff review won't catch a broken `NEXT:` link or a step that renders wrong.

Fix anything this turns up before merge — don't file a follow-up issue for a page that's already live.
