# eez-demos

Interactive, stepped walkthroughs of the Ethereum Economic Zone (EEZ) — both layers: the **contract mechanics** (Solidity, `eez-core-protocol`) and the **rollup infra** that actually runs a chain (`eez-rollup0`). Each demo pairs a plain-English explanation with **verbatim code** from the real source, shown side by side.

Successor to `eez-contract-demos` (archived) — same format, now covering both layers under one roof.

## Tracks

- **Builder track** — dapp-developer-facing contract mechanics (cross-chain proxies, calls, reentrancy).
- **Rollup-integrator track** — contract mechanics for anyone standing up a rollup (registration, multi-prover threshold).
- **Node-operator / Rollup0 track** — the actual off-chain infra: sequencer, composer, proof-signer, deriver, running the Kurtosis devnet.

## Source of truth

- Contract-layer code panels: verbatim from [eez-association/eez-core-protocol](https://github.com/eez-association/eez-core-protocol) @ `main`.
- Infra-layer code panels: verbatim from [eez-association/eez-rollup0](https://github.com/eez-association/eez-rollup0) @ `main`.
- **Status:** EEZ is pre-audit and not deployed. Every demo is badged `SPEC · NOT LIVE`.

See `CONTRIBUTING.md` before adding or editing a demo — it covers the house visual style and the verification rule every code panel must follow.

## Controls

← / → to step, space to play/pause. `start-here.html` is the guided two-demo path for a first-time visitor.

*Static site — no build step. Deploy any static host (currently Vercel).*
