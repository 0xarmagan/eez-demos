# Contributing to eez-demos

Single maintainer right now, no enforced branch protection — the checklist and audit pass below are still worth self-applying solo.

## Run it locally

```bash
git clone git@github.com:eez-association/eez-demos.git
cd eez-demos
npx serve .          # or: python3 -m http.server 8000
```

No build step or runtime dependencies — but serve it rather than opening `index.html` from disk, since a few paths are absolute (the favicon breaks otherwise). The npm manifest is for CI browser checks only.

## Add a new example

```bash
scripts/new-demo.sh <dapp-developers|rollup-operators|protocol-researchers> <slug> "<Title>"
```

Scaffolds a structurally-correct file from the `pr5` template (stage, code panel, the verified-against note in the intro, mobile floor — all pre-wired), with topic-specific content (diagram, `codeByStep`, citation, captions) marked `TODO`. Doesn't touch `index.html` or the `NEXT:` chain — that's manual.

## Format

- **Card** on `index.html`: action-oriented title, one-sentence hook stating the *consequence* (not the mechanic — "reorder the fields and you get a silently different hash," not "eight fields in order"). No code on the card. CTA is always `OPEN THE 3-STEP WALKTHROUGH →`.
- **Walkthrough**: copy `protocol-researchers/pr5-how-the-address-is-derived.html` as the template. Keep the fixed 1920×1080 stage (diagram left / code right / caption bottom / Prev-Play-Next), progressive `codeByStep` reveal, real data in the diagram (never placeholder boxes), the intro's verified-against note ("Verified against … ; interfaces may move."), the `NEXT:` link chain, and `scaleStage()`'s mobile floor — don't redesign these.
- Links: back/index links are `../index.html`. A `NEXT:` link into a different audience folder needs that folder in its path (`../rollup-operators/ro1-....html`); same-folder links just need the filename.

## Source of truth

Every snippet is verbatim, cited by exact `file:line`, against `eez-rollupX`:

- **Infra** — cite `eez-rollupX` at the commit pinned in `scripts/citation-pins.json`.
- **Contracts** — `eez-core-protocol` is a submodule, pinned to a commit, not tracking `main`. Cite `eez-core-protocol/<path>:<line>` and verify against that pinned commit (`git ls-tree HEAD eez-core-protocol`), not its own `main` — they drift.

Re-pull before writing anything, and again before merge if a PR sat open a while. If you can't verify something, say so rather than inventing a plausible signature.

No card or caption implies something works, or costs less time, than it does. An empty section gets "coming soon," never a fabricated example.

## Before opening a PR

Run the four checks first — they catch mechanically what the human pass below shouldn't spend attention on. CI runs the same four.

```bash
bash scripts/audit.sh                    # links, JS syntax, TODOs, citation paths
python3 scripts/verify-citations.py      # every citation vs real source at its pinned SHA
python3 scripts/check-panel-drift.py     # every panel line vs a compilable snippet
python3 scripts/check-snippet-fidelity.py # every snippet declaration vs upstream at its pinned SHA
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

Added a page or changed a title or hook on the index? Each page's link-preview
image (`assets/og/`) and its `og:` tags come from the index card:

```bash
NODE_PATH=<npx playwright install>/node_modules node scripts/build-og.cjs
```

- [ ] `scripts/audit.sh` passes
- [ ] `scripts/verify-citations.py` passes — this replaces re-checking citations by hand
- [ ] `scripts/check-panel-drift.py` passes; new Solidity pages registered in its `SNIPPET_MAP`
- [ ] Hook states a consequence, not a restatement of the title
- [ ] Card matches the existing visual style; walkthrough matches `q1`'s structure
- [ ] Added a card on `index.html`, under the correct audience section
- [ ] `NEXT:` chain updated on both neighbors: the header `NEXT:` link and the bottom-bar `#nextDemo` button both point to the same page with the same title
- [ ] Served locally and clicked through all 3 steps — not just eyeballed the source

## Audit, before merge

A second, independent pass — every real bug in this repo so far (a drifted submodule citation, an invented variable name, an undefined synonym used for an existing term, a stray marketing word, infra citations missing their `crates/` path) survived the first read and was only caught here. Don't skip it because the diff looks clean.

1. Re-run `scripts/audit.sh` yourself — don't trust that it was run, or that nothing changed since.
2. Re-run `scripts/check-snippet-fidelity.py` — until it existed, nothing compared the *snippet* to upstream: `check-panel-drift.py` compares the panel to the snippet and `verify-citations.py` compares the citation to upstream. That gap is how `STATIC_CHECK_GAS = 5000` shipped against an upstream `1_000` — the panel only shows `gas: STATIC_CHECK_GAS`, so the value appeared in neither compared surface. What still needs judgment: it compares only declarations the snippet and upstream share, so a function *body* that quietly diverges is still yours to read.
3. Re-run `scripts/verify-citations.py` — it fetches each cited file at the SHA in `scripts/citation-pins.json` and asserts the line and symbol still match, so citations no longer need checking by hand. What still needs judgment: whether the cited line is the *right* line to point at. The verifier accepts any line whose symbol matches within a few lines; it caught `EEZ.sol:790` pointing 10 lines into a function body, but it can't tell you a citation is pedagogically misaimed.
4. Check the diagram against the code panel — same real function/struct/value, or just plausible-looking?
5. Grep the term across all 17 demos before accepting a new name for something already named.
6. Serve it locally and click through all 3 steps yourself — a diff review won't catch a broken `NEXT:` link or a step that renders wrong.

Fix anything this turns up before merge — don't file a follow-up issue for a page that's already live.

## Script execution and side effects

The structural audit and export tests build exports in memory; they do not
regenerate files. Run the export generator explicitly to update them.
The snippet-fidelity tests modify only disposable copies of snippets. Their
checker can still download pinned upstream source text into the disposable cache.

The quickstart runner previews page commands by default. Its --extract-only flag
is an alias for this default. After reviewing a page, --execute opts into a
restricted set of commands executed as argument lists, without shell evaluation.
Execution still builds and runs upstream code: use a disposable environment
without mounted credentials or your home directory. Its temporary working
directory is not a security sandbox.

The browser geometry check keeps Chromium's sandbox enabled. If the host cannot
support it, use a suitable isolated host instead of disabling the sandbox.
CI pins Node to 24.22.1, Puppeteer to 25.16.0 and Foundry to v1.7.1. Its npm
dependency graph is committed in package-lock.json and installed with npm ci;
lifecycle scripts are disabled, followed by an explicit browser download step
in CI. Actions are pinned to full commit hashes. The dependency audit fails on
high or critical advisories. These are development checks, not site runtime
dependencies; publishing still serves static files.

The PR's dependency-lock preparation workflow runs only on
`fix/site-agent-deploy-safety` in this repository. It resolves package metadata
on GitHub without lifecycle scripts, commits only package-lock.json to that
branch, and starts CI on the updated branch. Only that job has repository write
and workflow-dispatch permissions; the validation workflow remains read-only.
No artifact download or local dependency installation is needed for that flow.

The site-safety browser check intercepts all HTTP requests and serves tracked
fixtures without contacting a live RPC. It checks unexpected requests (no page
fetches the agent skill), wallet access, hostile text inputs, clipboard writes
and the separate mainnet broadcast command. It never executes
displayed commands. Existing geometry and navigation assertions remain enabled.

The agent skill (skills/eez-dapp-quickstart/SKILL.md) is reviewed text, not a
shell installer, and no page links to it. Updates require review and approval
rather than automatic adoption of instructions from a mutable URL.

The mainnet playground guide previews before an explicit, chain-bound broadcast
and calls for small integration experiments using real ETH. It does not certify
the live protocol or bridge. Deployment examples import a fresh key interactively into an encrypted
keystore. Never put private keys or keystore passwords in command arguments or
exported variables. Install Foundry from verified official release artifacts.

Historical review and plan documents describe older commands and are not current
installation or deployment instructions.
