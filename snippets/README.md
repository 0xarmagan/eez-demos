# Snippets

Compilable Solidity behind the code panels on the `dapp-developers/` walkthroughs (q2–q8) plus one `protocol-researchers/` walkthrough — `pr5`, which reuses the `q1` snippet.

## Why this exists

The panels are hand-wrapped to fit a 662px column, so they can't simply *be* these
files. But before this directory existed, nothing stopped a panel from drifting into
Solidity that would never compile — and Solidity developers copy what they see.

Two checks close that, without making the HTML generated:

| Check | What it proves |
|---|---|
| `forge build` / `forge test` (CI) | these files are valid Solidity, and the q3, q5, q6 and q8 tests actually pass |
| `scripts/check-panel-drift.py` | every non-comment line in a panel exists verbatim in its snippet |

So a panel edit that invents invalid Solidity fails the drift check, and a genuine
panel edit forces the same line into a file the compiler checks.

## Layout

```
lib/IEEZ.sol           signatures copied verbatim from upstream IEEZ
lib/IEEZManager.sol    the two EEZBase members the demos use that IEEZ lacks
q1..q8-*.sol           one per walkthrough panel (q1 backs pr5, the
                        protocol-researcher page; q2..q8 back their
                        matching dapp-developer pages)
test/*.t.sol           runnable proofs for q3, q5, q6 and q8 (each page's
                        TEST tab shows a slice of its own file)
foundry.toml           no forge-std, no submodules — builds on a bare checkout
```

## Running

```bash
cd snippets
forge build
forge test -vv
```

Expected: 14 files compile, 19 tests pass. The interesting one is
`test_sameChainCheck_passesOnSameChain` — it passes, which is *why* the bug ships.
An owner check looks correct until a call actually arrives through a proxy, and a
same-chain test never exercises that path. `Q8RemoteReads.t.sol`'s first three
cases are the same shape: nothing reverts, and that is the hazard.

Without Foundry installed, `solc` alone is enough to confirm the files compile;
only the tests need `forge`.

## Scope

Only the Solidity walkthroughs: the seven `dapp-developers/` pages and one
`protocol-researchers/` page (`pr5`). `rollup-operators/` panels are shell, and
the rest of `protocol-researchers/` is Rust and protobuf — different
toolchains, not covered here.

## Adding a walkthrough

`scripts/new-demo.sh` templates from `pr5`. If the new page is Solidity, add a
snippet here and register it in `SNIPPET_MAP` in `scripts/check-panel-drift.py`
— any Solidity walkthrough with no entry there fails the check rather than
being skipped silently.

## What these files are not

They mirror upstream, they are not upstream. Compilation only proves they are valid
Solidity — not that they still match the protocol. `scripts/verify-citations.py` is
the check for that: it fetches each cited file at its pinned SHA and asserts the
line and symbol still match.
