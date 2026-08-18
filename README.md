# eez-demos

Real EEZ code, by what you're trying to do. 14 short animated walkthroughs (3 steps each: real diagram, real code, one-sentence caption) linked from cards on one `index.html`.

Three audiences, all live:

- **Dapp developers** (6) — building a contract that makes or receives cross-chain calls.
- **Rollup operators** (4) — standing up or running a rollup on EEZ.
- **Protocol researchers** (4) — execution model, settlement, invariants.

## Source of truth

This repo is strictly scoped to `eez-rollup0`:

- Infra layer: [eez-association/eez-rollup0](https://github.com/eez-association/eez-rollup0) @ `main`.
- Contract layer: `eez-core-protocol`, a **git submodule of `eez-rollup0`** — cited by its real path (`eez-core-protocol/<path>:<line>`) and verified against the commit `eez-rollup0` actually pins, not `eez-core-protocol`'s own independently-moving `main`.
- **Status:** pre-mainnet. Every page carries a quiet `PRE-MAINNET` label.

Every code panel cites a real `file:line`. See `CONTRIBUTING.md` before adding an example.

*Static site — one `index.html`, no build step. Deployed on Vercel, git-linked (push to `main` deploys).*
