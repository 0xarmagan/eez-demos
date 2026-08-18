# eez-demos

Real EEZ code examples, organized by **what you're trying to do**, not by protocol mechanic. One page, one card per example: a title, a one-line description, and a real verbatim code snippet — no prose walkthroughs, no animation.

Three audiences:

- **Dapp developers** — building a contract that makes or receives cross-chain calls. 6 examples live.
- **Rollup operators** — standing up or running a rollup on EEZ. Coming soon.
- **Protocol researchers** — execution model, settlement, invariants. Coming soon.

## Source of truth

- Contract layer: [eez-association/eez-core-protocol](https://github.com/eez-association/eez-core-protocol) @ `main`.
- Infra layer: [eez-association/eez-rollup0](https://github.com/eez-association/eez-rollup0) @ `main`.
- **Status:** EEZ is pre-audit and not deployed. Every page carries a `SPEC · NOT LIVE` badge.

Every code block cites its real `file:line`. See `CONTRIBUTING.md` before adding an example.

*Static site — one `index.html`, no build step. Deployed on Vercel, git-linked (push to `main` deploys).*
