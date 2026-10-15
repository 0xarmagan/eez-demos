# dApp Quickstart track — design

Date: 2026-10-14 · Status: approved in chat, pending spec review
Sources: eez-core-protocol @ `9a1f815`, eez-rollupX @ `2c19e36` (the pins in `scripts/citation-pins.json`)

## Goal

Add an ordered track of walkthroughs for dApp developers. A developer who opens it knowing nothing about EEZ should be able to answer four questions in order: what is this, does it actually work, can I build on it, and what can I build. The track sits behind this entry card:

> **dApp developers — Build cross-rollup apps**
> Write cross-chain logic — flash loans, bridging — as naturally as a same-chain call. Run a cross-rollup round trip locally in about N minutes.

Changes from the brief, agreed in chat:
- **DEX and lending are dropped from the card.** `script/DeployUniswapLab.s.sol` imports `MiniUniswapFactory`/`MiniUniswapRouter`, which do not exist at `9a1f815`, and there is no lending example. They can come back when real code exists.
- **N is measured, not assumed.** N is the clean cold time for card 1 (clone → `forge build` → first PASS) on a laptop, rounded up to the next 5 minutes. The run made during brainstorming took about 6 minutes, but `forge build` (292 s) shared the CPU with a Docker build, so it is not a clean measurement. If N comes out above 15, the card states the measured value.

## Flow

Four phases. Each answers the question the developer has at that point, and a developer can stop at the end of any phase having learned something complete.

| Phase | # | Card | What the developer does or sees | Ground truth | Status |
|---|---|---|---|---|---|
| 1. Understand (no install) | 0 | One call, two rollups, one transaction | One picture: your contract calls a proxy, the composer has already built the answer, and the other rollup's result returns in the same transaction | `CrossChainProxy.sol` `_fallback` → `EEZ.sol` `executeCrossChainCall` | ready |
| 2. See it work (Foundry only) | 1 | Run your first round trip | Clone core-protocol, `forge build`, `bash script/e2e/run/local/parallel.sh counter counterL2` | Verified 2026-10-14: 2/2 PASS, run 27 s | ready |
| | 2 | Read your side of it | `target.increment{gas: PROXY_CALL_GAS}()` against a proxy: an ordinary Solidity call | `test/mocks/CounterContracts.sol:62-65` | ready |
| | 3 | Who answered? | The composer pre-builds the answer, you don't. Locally, the script plays composer; that's why the scenario file is long. Links to pr6 and q5 for the internals | `script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol` | ready |
| 3. Make it real (devnet) | 4 | Run it with a real composer | Start the Kurtosis devnet; you only send the trigger transaction | `testing/kurtosis/README.md`, `script/e2e/run/network/staged.sh counter:1` | **blocked** (below) |
| | 5 | Before you write your own: three gotchas | `msg.sender` is the proxy (→ q3), entries count only in their block (→ q8), call gas is explicit (`PROXY_CALL_GAS`) | existing q3/q8 citations + `CounterContracts.sol` | ready |
| | 6 | Deploy your own contract, call it both ways | Your contract, `createCrossChainProxy`, one call in each direction against the devnet | `contracts/script/CreateValueProxy.s.sol` | **blocked** (needs 4) |
| 4. Build patterns | 7 | Cross-chain flash loan | Borrow on L1, use it on L2, repay on L1, in one transaction | `script/e2e/scenarios/nested/L1_to_L2/flash-loan`, `src/periphery/defiMock/FlashLoan.sol`, `FlashLoanBridgeExecutor.sol`; verified: local scenario PASS (13 s), `IntegrationTestFlashLoan` PASS | ready |
| | 8 | Bridge tokens both ways | Lock/mint on the way out, burn/release on the way back | `src/periphery/Bridge.sol`, scenarios `one_way/*/bridge`, `bridgeL2`; verified: local PASS both ways (12 s), `IntegrationTestBridge` 3/3, `IntegrationTestEEZBridge` 2/2 | ready |

Card 5 sits right before card 6 on purpose: the developer meets the gotchas when they are about to write their own contract, not while they are still watching something work.

### Blocked cards (4, 6)

The devnet does not run on a Mac today. The brainstorming spike found three blockers:
1. `testing/kurtosis/README.md` requires a Linux host.
2. `testing/kurtosis/start.sh:68` expands an empty array under `set -u`, which macOS's bash 3.2 rejects. Running it with Homebrew bash 5 works around this.
3. Building the `eez-node` image ran out of memory under Docker Desktop's 8 GB after 586 s (`cannot allocate memory`).

The UI repo `eez-rollup-ui` is also not public. The devnet runs without it (`EEZ_SKIP_UI_BUILD=1`, `enable_ui: false`), but nothing documents that.

Until a full devnet run passes, cards 4 and 6 ship as "coming soon" stubs, in line with CONTRIBUTING: "An empty section gets 'coming soon,' never a fabricated example." A stub names its requirements (Linux, ≥16 GB for Docker) and links ro1. The four blockers above go upstream to eez-rollupX as issues, but only with the user's approval, since filing an issue is an outward-facing action.

## Placement and format

- **Location:** pages go in `dapp-developers/` as `qs0-…html` through `qs8-…html`. Every script already globs that folder (`verify-citations.py:43`, `audit.sh:26`, `check-panel-drift.py:137`, `build-llms.py:38`), so no tooling is rewired.
- **Index:** the "First time here? Three steps" block (`index.html:155-179`) becomes the entry card above plus the phase strip. The existing 7-card dApp section stays unchanged as the reference track, and quickstart cards link into it rather than repeating it.
- **Format:** the standard walkthrough (`pr5` template via `scripts/new-demo.sh`): 1920×1080 stage, diagram left, cited code right, caption under the diagram, 3 steps, PRE-MAINNET label, `NEXT:` chain. Hands-on cards (1, 7, 8) use a shell panel like ro1–ro4 and show the real expected output (`[counter] PASS`).
- **Chain:** `qs0 → qs1 → qs2 → qs3 → qs5 → qs7 → qs8`. The stubs `qs4` and `qs6` are linked from the index phase strip but not from the `NEXT:` chain until they ship.
- **Solidity panels** (qs2, qs7, qs8) get snippets under `snippets/` registered in `SNIPPET_MAP`, so panel-drift and snippet-fidelity cover them.
- **Card count:** `check-manifest.py` asserts `EXPECTED_CARDS = 29`. Raise it by the number of cards added and record the rows in the v4.1 manifest.

## Skills

Reused as they are:
- `eez-protocol-dev`: grounding every claim in the pinned source.
- `technical-accuracy`: pre-publish check.
- `developer-experience` and `technical-writer`: card copy and task orientation.
- `motion-designer`: the qs0 diagram.

Created: **`eez-demos-quickstart`**, a project skill in this repo at `.claude/skills/eez-demos-quickstart/SKILL.md`. A search on 2026-10-14 found nothing that covers it; `web3-technical-writing` in agent-mesh covers prose, not this. It encodes:
1. **Run-it-for-real gate.** Every command on a hands-on card is executed at the pinned SHAs before publishing. The page records the platform, tool versions and measured time, and the expected output is pasted from the real run.
2. **Time-claim rule.** Any duration on a card or hook comes from a clean cold measurement, rounded up. No measurement means no number.
3. **Honest framing of local mode.** Locally the harness plays composer, so local cards say "see it work", never "build".
4. **Track wiring checklist.** File naming, index phase strip, `NEXT:` chain, `SNIPPET_MAP`, manifest count, `build-llms.py`.
5. **The check suite** from CONTRIBUTING, plus a rendered screenshot of every step.

It is validated after authoring by an adversarial subagent on a divergent scenario: writing a hypothetical qs9 "static read pattern" card. The subagent must report every point where it relied on outside knowledge.

## Out of scope

- DEX and lending cards (no source exists).
- Changing the existing 7 dApp, ro or pr pages.
- Fixing eez-rollupX's macOS support. That is upstream work; we only report the blockers.

## Done when

- qs0–qs3, qs5, qs7 and qs8 are published. qs4 and qs6 are stubs. The index entry card and phase strip are live.
- Every check in CONTRIBUTING passes: `audit.sh`, `verify-citations.py`, `check-panel-drift.py`, `check-snippet-fidelity.py` plus its self-test, `build-llms.py --check`, `test_build_llms.py`, `check-manifest.py`, `sync-embedded-snippets.py --check`, and `forge test`.
- Every hands-on command was re-run at the pins. N is measured clean and stated.
- The independent prose audit (CONTRIBUTING, "Audit, before merge") has no open findings.
- The `eez-demos-quickstart` skill exists and passed one adversarial validation.
