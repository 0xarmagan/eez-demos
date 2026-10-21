# EEZ Quickstarts

Step-by-step walkthroughs of how EEZ works, each pairing a diagram with real protocol code cited at a pinned commit. Live at **[eez-association.github.io/eez-demos](https://eez-association.github.io/eez-demos)**.

EEZ is pre-mainnet, and every walkthrough says so.

## Tracks

| Track | Pages |
|---|---|
| dApp Quickstart (start here) | `dapp-developers/qs*`, cards 00–06 |
| dApp reference | `dapp-developers/q2`–`q8` |
| Rollup operators | `rollup-operators/ro1`–`ro4` |
| Protocol researchers | `protocol-researchers/pr1`–`pr6` |

Agents can read everything as plain text in [`llms.txt`](llms.txt) and [`llms-full.txt`](llms-full.txt).

## Run locally

```bash
git clone https://github.com/eez-association/eez-demos.git && cd eez-demos
npx serve .        # or: python3 -m http.server 8000
```

No build step. Serve the folder rather than opening files from disk. Pushing to `main` deploys to GitHub Pages.

## Contribute

```bash
bash scripts/audit.sh                    # links, JS, pre-mainnet note, generated files
python3 scripts/build-llms.py --check    # llms.txt files are current
cd snippets && forge build && forge test
```

CI runs these plus the citation and snippet checks. [CONTRIBUTING.md](CONTRIBUTING.md) has the full checklist and the page scaffold (`scripts/new-demo.sh`).

Three rules: code is verbatim and cited by `file:line` at a pin; nothing claims more than it does; unfinished pages say "coming soon".

See also: [PRODUCT.md](PRODUCT.md) (audience) · [DESIGN.md](DESIGN.md) (visual system).
