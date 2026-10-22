# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

**Primary: dApp developers** who want to write contracts that call across rollups. They arrive knowing Solidity and Foundry but not EEZ, and the job is to get from "what is this?" to "my contract used another rollup's answer in the same transaction" without misreading how it works. The Quickstart track (cards 00–06, in four phases: Understand / See it work / Make it real / Build patterns) is their front door. The dApp reference track (`dapp-developers/q*`) is where they go deeper afterward.

**Secondary:** rollup operators (standing up and running the stack: devnet, deploy, Chiado, cross-chain traffic) and protocol researchers (how Rollup0 settles and proves). Each gets a reading order on `start-here.html` but not a dedicated quickstart.

## Product Purpose

EEZ Quickstarts (eez-association.github.io/eez-demos) teaches how EEZ actually works through short, step-by-step walkthroughs. Each one pairs a diagram, real verbatim code and a one-sentence caption on a fixed stage. The core idea it teaches: a contract can call another rollup and use the answer in the same transaction, with no callback and no second transaction.

Success means a developer runs a cross-rollup round trip on their own machine, understands why it worked (the answer was already in an execution entry), and avoids the gotchas before writing production code.

## Positioning

It is the EEZ team's official hands-on learning layer and sits between two other surfaces:

- **mainnet.eez.dev** is the live EEZ-X network on Ethereum mainnet (dashboard: https://mainnet.eez.dev/dashboard/). This site links out to it and doesn't duplicate its flows. eez.dev is the older Chiado testnet.
- **eez-core-protocol `docs/`** is the specification. This site teaches mechanics and cites the spec; it isn't a second spec.

What a neighbor can't truthfully copy: every code panel is verbatim source cited at a pinned `file:line` and commit, checked mechanically in CI. Snippets compile and their Foundry tests pass. Nothing is pseudocode.

## Operating Context

- Readers move between a walkthrough, their terminal (Foundry v1.7.1, `forge test`, the local e2e runner), the GitHub source the citations link to, and mainnet.eez.dev.
- The offline path (snippets with no forge-std, no submodules, no Docker) has to work on a bare checkout.
- Agents and LLMs consume the site through `llms.txt` / `llms-full.txt`, because the code panels render from JavaScript at runtime.

## Capabilities and Constraints

- **Stack:** static HTML/CSS/JS, no build step, no dependencies. It's served from the repo root and deployed on GitHub Pages from `main`. CI (`.github/workflows/ci.yml`) runs `scripts/audit.sh`, citation verification, panel-drift, snippet-fidelity and a geometry job.
- **Walkthrough format is fixed** (CONTRIBUTING.md): a 1920×1080 stage (diagram, code, caption, Prev/Play/Next), progressive `codeByStep` reveal, real data in diagrams, the `NEXT:` link chain, and the `scaleStage()` mobile floor. `pr5` is the template, and `scripts/new-demo.sh` scaffolds new pages from it.
- **Card format:** an action-oriented title and a one-sentence hook that states the consequence, not the mechanism. No code on cards.
- **Sources:** contracts come from `eez-core-protocol` and infra from `eez-rollupX`, both pinned by SHA. Pinned commits drift from upstream `main`, so check against the pin.
- **Network facts:** EEZ-X runs on Ethereum mainnet (L1 chain 1, L2 chain 696990, protocol 855fe06). The older Chiado testnet (L2 chain 699069) is at eez.dev. The proof system in public source is dev-grade ECDSA (threshold 1), not production ZK, and `USE_GAS_LEFT` is off in every current deployment.
- **Open decisions:**
  - whether to keep the hero phrase "as naturally as a same-chain call";
  - the unmeasured "DEPLOY A CONTRACT · ~15 MIN" pill;
  - rewrapping pr1–4 and pr6, which overflow their panels and keep the CI geometry job red;
  - the Deploy Your Own Contract card (Remix cross-chain plugin), which is "coming soon" and unnumbered.

## Brand Commitments

- Branded as EEZ (Ethereum Economic Zone), with the EEZ logo, under the title "EEZ Quickstarts".
- **Every walkthrough says EEZ is pre-mainnet**: walkthroughs in the intro slide's "Verified against … — pre-mainnet; interfaces may move." line, the Deploy Your Own Contract card in its text. The index is the exception (owner decision, 2026-10-20): it carries no label of its own. There is no header badge. Capability claims are design intent, not shipped behavior.
- **Honesty rules (binding):**
  - no card or caption implies something works, or takes less time, than it does;
  - stated timings name the hardware they were measured on;
  - an empty section says "coming soon" and never gets a made-up example;
  - anything unverifiable is labeled as such.
- **Public copy voice:** the team's warm, connected "we" voice. No robotic openers and no repeated framing words.
- `docs/founding-design.md` is the 2026-08-18 founding design note (scope and tracks), not a visual system record.

## Evidence on Hand

- 24 live walkthroughs plus 1 "coming soon": 14+1 for dApp developers (Quickstart 00–06 and reference q1–q8), 4 for rollup operators, 6 for protocol researchers.
- `snippets/`: compilable Solidity with runnable Foundry tests.
- `docs/quickstart-runs.md`: measured runs. A cold card-01 run took 251.66 s (about 4.2 min) on an Apple M4, with solc already cached; solc download time was not measured.
- `docs/reviews/`: accuracy audits.
- No testimonials, adoption figures, partner logos or production benchmarks exist. Don't invent them.

## Product Principles

1. **Source over story.** Every claim traces to a pinned line of real code. If it can't be cited, it gets labeled, not smoothed over.
2. **Run it, then explain it.** Get the developer to a working round trip early, then show why it worked.
3. **Consequences first.** Lead with what breaks or changes for the developer (msg.sender is a proxy, a field order silently changes the hash), not with protocol internals.
4. **Pre-mainnet honesty.** Undersell rather than overclaim on timing, proving and readiness.
5. **One format, many topics.** The fixed walkthrough stage and card grammar are what make 24 pages read as one site. Extend them; don't fork them.

## Accessibility & Inclusion

- Pages have to work at phone width: the stage scales down to the `scaleStage()` mobile floor.
- Keyboard focus is visible on links and cards.
- Code content is also published as plain text in `llms-full.txt` for readers who can't use the JS-rendered panels.
