# EEZ Quickstarts

Short, step-by-step walkthroughs of how EEZ works. Each step pairs a diagram with real protocol code cited at a pinned commit. Live at **[eez-demos.vercel.app](https://eez-demos.vercel.app)**.

EEZ is pre-mainnet, and every page says so. Read capability claims as design intent, not shipped behavior.

## What's on the site

| Track | Pages | For |
|---|---|---|
| **dApp Quickstart** | Cards 00–07 (`dapp-developers/qs*`), card 05 coming soon | A contract calls another rollup and uses the answer in the same transaction: run it locally, learn the gotchas, then a flash loan and a token bridge |
| **dApp reference** | `dapp-developers/q2`–`q8` | Proxy addresses, `msg.sender`, content hashes, remote reads |
| **Rollup operators** | `rollup-operators/ro1`–`ro4` | Devnet, deployment, Chiado, cross-chain traffic |
| **Protocol researchers** | `protocol-researchers/pr1`–`pr6` | How Rollup0 settles and proves |

There are 24 walkthroughs in all, plus `start-here.html` (a reading order per track) and `deploy.html` (deploying on the EEZ-X testnet). Agents can read the whole site as plain text from [`llms.txt`](llms.txt) and [`llms-full.txt`](llms-full.txt), because the code panels render from JavaScript. Each Quickstart card also has a markdown mirror beside it (`dapp-developers/qs*.md`) with a Next link, so an agent can walk the track card by card.

## Run it locally

Static HTML with no build step:

```bash
git clone https://github.com/0xarmagan/eez-demos.git && cd eez-demos
npx serve .        # or: python3 -m http.server 8000
```

Serve the folder rather than opening `index.html` from disk, because some paths are absolute. Pushing to `main` deploys to Vercel.

## Repo layout

```
index.html, start-here.html, deploy.html, 404.html   site pages (live URLs, don't move)
dapp-developers/  rollup-operators/  protocol-researchers/   walkthroughs (live URLs)
assets/      shared JS (help tour, hash helper, testnet config)
snippets/    compilable Solidity + Foundry tests behind the code panels
starter/     a guided run through snippets/ (cd starter && ./run.sh)
scripts/     CI checks, generators, and the new-page scaffold
docs/        plans, specs, reviews, measured runs (see docs/README.md)
llms.txt, llms-full.txt    generated, with the qs*.md card mirrors; rebuild with scripts/build-llms.py
PRODUCT.md   who the site is for and the rules it keeps
DESIGN.md    the visual system ("The Lit Bench")
```

## Before you open a PR

CI runs these checks, and you should too:

```bash
bash scripts/audit.sh                      # links, JS syntax, pre-mainnet note, generated files
python3 scripts/verify-citations.py        # every file:line citation vs upstream at its pinned SHA
python3 scripts/check-panel-drift.py       # every panel line vs a compilable snippet
python3 scripts/check-snippet-fidelity.py  # snippets vs upstream at the pin
python3 scripts/build-llms.py --check      # llms.txt / llms-full.txt are current
cd snippets && forge build && forge test   # snippets compile and tests pass
```

To add a walkthrough, scaffold it with `scripts/new-demo.sh <track> <slug> "<Title>"`. You wire it into `index.html` and the `NEXT:` chain by hand. [CONTRIBUTING.md](CONTRIBUTING.md) has the format, the citation rules and the full checklist.

## Ground rules

- **Verbatim code only:** every snippet is real source, cited by exact `file:line` at a pinned commit. Pins live in `scripts/citation-pins.json`.
- **No overclaiming:** no card or caption says something works, or takes less time, than it does. Timings name the hardware they were measured on (see `docs/quickstart-runs.md`).
- **No placeholder content:** an unfinished page says "coming soon" and never shows a made-up example.
