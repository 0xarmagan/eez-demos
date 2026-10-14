# Quickstart run log

Pin: eez-core-protocol `9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f`.

## qs1: counter / counterL2 (cold)

- Date: 2026-10-14
- Machine: macOS 26.5.2, arm64, Apple M4
- forge: 1.7.1 (4072e48705, built 2026-05-08)
- bash: Homebrew bash 5.3.20, first on PATH. Stock macOS `/bin/bash` 3.2 fails the e2e runner with `script/e2e/lib/E2EBase.sh: line 458: declare: -A: invalid option` (verified 2026-10-14).
- Conditions: cold (`/tmp/qs-measure` removed first, no forge cache). Docker was not running, so no containers; `kurtosis engine stop` found no engine. Load average before run about 3.3.
- solc cache: Solc 0.8.34 was already cached (`~/Library/Application Support/svm/0.8.34`; macOS has no `~/.svm`), so the 213 s `forge build` excludes the compiler download. A first-time Foundry user also downloads solc on top of this; download time not measured.
- Commands: exactly the qs1 sequence from the plan (clone, checkout pin, submodules, `forge build`, `bash script/e2e/run/local/parallel.sh counter counterL2`), with `date` stamps between steps.

| Step | Seconds |
|---|---|
| clone + checkout + submodules | 18 |
| `forge build` | 213 |
| scenario run (`counter counterL2`) | 20 |
| total (`/usr/bin/time -p` real) | 251.66 (about 4.2 min) |

Final 4 output lines (the blank line counts):

```
  [counter] PASS
  [counterL2] PASS

===== RESULT: 2 passed, 0 failed, 0 skipped =====
```

**N = 5** (251.66 s rounded up to the next 5 minutes).

## Scenario runs from the built tree

Same machine, run inside `/tmp/qs-measure/eez-core-protocol` after the build. The seconds below are from the first measurement and were not re-taken.

- `bash script/e2e/run/local/parallel.sh flash-loan`: 14.66 s
- `bash script/e2e/run/local/parallel.sh bridge bridgeL2`: 11.30 s

## Full output, re-recorded 2026-10-14

Same machine and built tree, PATH=/opt/homebrew/bin:$HOME/.foundry/bin:$PATH (Homebrew bash 5.3, Foundry 1.7.1, `/usr/bin/jq` 1.7.1). Run one at a time, because the scenarios share anvil ports. Not timed. Each card's output panel shows exactly these lines.

Parallel scenarios start and finish in any order, so the order of the `starting` and `PASS` lines changes between runs. The port numbers follow the argument order (`parallel.sh:73-81`): the first scenario gets L1=18545/L2=18546, the second L1=18547/L2=18548.

`bash script/e2e/run/local/parallel.sh counter counterL2` (qs1, card 01)

```
  [counterL2] starting (L1=18547 chain=41339, L2=18548 chain=41340)
  [counter] starting (L1=18545 chain=41337, L2=18546 chain=41338)
  [counterL2] PASS
  [counter] PASS

===== RESULT: 2 passed, 0 failed, 0 skipped =====
```

`bash script/e2e/run/local/parallel.sh flash-loan` (qs7, card 06)

```
  [flash-loan] starting (L1=18545 chain=41337, L2=18546 chain=41338)
  [flash-loan] PASS

===== RESULT: 1 passed, 0 failed, 0 skipped =====
```

`bash script/e2e/run/local/parallel.sh bridge bridgeL2` (qs8, card 07)

```
  [bridge] starting (L1=18545 chain=41337, L2=18546 chain=41338)
  [bridgeL2] starting (L1=18547 chain=41339, L2=18548 chain=41340)
  [bridge] PASS
  [bridgeL2] PASS

===== RESULT: 2 passed, 0 failed, 0 skipped =====
```

`forge test --match-test test_BridgeTokens_Roundtrip` (qs8, card 07). On a tree that `forge build` has just built, the first line is "No files changed"; the card elides it and the timing tail with `⋯` / `…`.

```
No files changed, compilation skipped

Ran 1 test for test/IntegrationTestBridge.t.sol:IntegrationTestBridge
[PASS] test_BridgeTokens_Roundtrip() (gas: 2236711)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 2.19ms (609.00µs CPU time)

Ran 1 test suite in 4.88ms (2.19ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

Note: `bridge` is `one_way/L1_to_L2/bridge`, `bridgeL2` is `one_way/L2_to_L1/bridgeL2`.

Prerequisite found by audit: the local runner needs `jq` (`script/e2e/lib/E2EBase.sh:215`, `:321`, `:601-607`). This machine has `/usr/bin/jq` (macOS 15+ ships it); Linux and older macOS need `brew install jq` / `apt install jq`.
