# Quickstart run log

Pin: eez-core-protocol `9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f`.

## qs1: counter / counterL2 (cold)

- Date: 2026-10-14
- Machine: macOS 26.5.2, arm64, Apple M4
- forge: 1.7.1 (4072e48705, built 2026-05-08)
- Conditions: cold (`/tmp/qs-measure` removed first, no forge cache). Docker was not running, so no containers; `kurtosis engine stop` found no engine. Load average before run about 3.3.
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

Same machine, run inside `/tmp/qs-measure/eez-core-protocol` after the build.

`bash script/e2e/run/local/parallel.sh flash-loan` — 14.66 s

```
  [flash-loan] starting (L1=18545 chain=41337, L2=18546 chain=41338)
  [flash-loan] PASS

===== RESULT: 1 passed, 0 failed, 0 skipped =====
```

`bash script/e2e/run/local/parallel.sh bridge bridgeL2` — 11.30 s

```
  [bridgeL2] starting (L1=18547 chain=41339, L2=18548 chain=41340)
  [bridgeL2] PASS
  [bridge] PASS

===== RESULT: 2 passed, 0 failed, 0 skipped =====
```

Note: `bridge` is `one_way/L1_to_L2/bridge`, `bridgeL2` is `one_way/L2_to_L1/bridgeL2`. Output order of parallel scenarios varies between runs.
