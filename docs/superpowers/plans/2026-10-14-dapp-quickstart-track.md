# dApp Quickstart Track Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a 9-card dApp Quickstart track on eez-demos (7 walkthroughs, 2 "coming soon" stubs). The track is behind a new index entry card, and an `eez-demos-quickstart` skill encodes how such cards are built.

**Architecture:** Each card is one static HTML walkthrough in `dapp-developers/qs*.html`, scaffolded from the pr5 template by `scripts/new-demo.sh`. Every command on a card is executed by `scripts/run-quickstart.sh`, which reads the commands out of the pages themselves. Every code excerpt is checked verbatim against upstream at the pin by `scripts/check-excerpts.py`. Tooling, the run script and the skill land first, so the card agents work against fixed checks and never edit shared files.

**Tech Stack:** static HTML/JS, Python 3 checks, bash, Foundry 1.7.1 (`forge`, `anvil`), eez-core-protocol @ `9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f`.

**Spec:** `docs/superpowers/specs/2026-10-14-dapp-quickstart-track-design.md`. Read it before any task. Shared copy: https://claude.ai/code/artifact/f3d0f192-d550-4f13-82e6-07a0a4476583

## Global Constraints

- Source pins: eez-core-protocol `9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f`, eez-rollupX `2c19e36bed2720c00f89841ccfca47ec7c921e06`. Both are already in `scripts/citation-pins.json`. Never cite a branch.
- Every code line on a card is verbatim upstream at the pin, or verbatim from a compilable snippet in `snippets/`. Never invent a signature.
- Every command on a card was executed. Every duration comes from a clean cold measurement, rounded up to the next 5 minutes.
- Local mode is framed as "see it work", never "build". In local mode the scenario script plays composer.
- No DEX or lending claims anywhere: no source exists at the pin.
- Files are `dapp-developers/qs0…qs8-<slug>.html`. Slugs are fixed in the "Card slugs" table below.
- Keep the walkthrough format unchanged: 1920×1080 stage, diagram left, code right, caption under the diagram, Prev/Play/Next, PRE-MAINNET label, `scaleStage()` mobile floor, `NEXT:` link.
- Next-card chain: qs0 → qs1 → qs2 → qs3 → qs5 → qs7 → qs8 → back to `../index.html#dapp-developers`. The stubs qs4 and qs6 are linked only from the index phase strip.
- Do not change existing q/ro/pr pages. Do not change `EXPECTED_CARDS` in `check-manifest.py` (it counts manifest task cards, not site pages; this corrects the spec).
- Gotcha #3 wording (corrects the spec): "On L2 the gas you forward is folded into the call's hash, so a cross-chain call site attaches a fixed amount." Ground it in `test/mocks/CounterContracts.sol:3-7` (the `PROXY_CALL_GAS` doc comment) and link q5.
- Copy is short, plain and consequence-first (CONTRIBUTING "Format"). Each hook states a consequence.
- Card agents never commit. The lead commits per task after review.

### Card slugs

| # | File | Title |
|---|---|---|
| 0 | `qs0-one-call-two-rollups.html` | One Call, Two Rollups, One Transaction |
| 1 | `qs1-run-your-first-round-trip.html` | Run Your First Round Trip |
| 2 | `qs2-read-your-side-of-it.html` | Read Your Side of It |
| 3 | `qs3-who-answered.html` | Who Answered? |
| 4 | `qs4-run-it-with-a-real-composer.html` | Run It With a Real Composer (stub) |
| 5 | `qs5-three-gotchas-before-you-build.html` | Three Gotchas Before You Build |
| 6 | `qs6-deploy-your-own-contract.html` | Deploy Your Own Contract (stub) |
| 7 | `qs7-cross-chain-flash-loan.html` | Cross-Chain Flash Loan |
| 8 | `qs8-bridge-tokens-both-ways.html` | Bridge Tokens Both Ways |

## Review Focus

1. **A command on a card differs from what was run.** A developer pastes exactly what the page shows. `run-quickstart.sh` extracts `$ ` lines from the pages and runs those, never a separate copy (Task 2 test).
2. **Upstream `main` moves after publishing.** A pasted clone must land on the pinned commit, so card 1's commands include `git checkout 9a1f815…`. The run script fails if a page clones without checking out the pin (Task 2 test).
3. **An excerpt silently drifts from upstream** (an edited line, or a line from the wrong file). `check-excerpts.py` fails on any panel line not found verbatim in the registered files at the pin (Task 1 test).
4. **A developer lands on a stub from search.** A stub must not be a dead end. It names the requirements and links ro1 and the track, and carries the PRE-MAINNET label (Task 10 check).
5. **A phone-width reader.** Every new page must stay usable at 390 px through the existing `scaleStage()` floor (Task 12 screenshots at 390×844).

---

### Task 1: Excerpt checker and drift registration

**Files:**
- Create: `scripts/check-excerpts.py`
- Create: `scripts/test_check_excerpts.py`
- Modify: `scripts/check-panel-drift.py` (scan regex, `SNIPPET_MAP`, `NON_SOLIDITY`, new `EXCERPT_CHECKED`)
- Modify: `.github/workflows/ci.yml` (two new steps after "Snippets still match upstream at the pin")

**Interfaces:**
- Produces: `EXCERPTS` dict in `check-excerpts.py`, mapping page → `{step_index: [upstream path, ...]}`. Steps are 0-based indices into `codeByStep`. Card tasks never edit this dict; it is filled here, with every step that Tasks 4–9 must make verbatim.
- Produces: `missing_lines(panel_lines, source_lines) -> list[str]`.
- Consumes: `steps_of(src, rel)` from `scripts/build-llms.py`, and `fetch(repo, sha, path, offline)` plus `load_pins()` from `scripts/verify-citations.py` (imported with importlib, as the existing scripts do).

- [ ] **Step 1: Write the failing test**

```python
#!/usr/bin/env python3
"""Self-test for check-excerpts.py: it must catch a drifted line and pass a verbatim one."""
import importlib.util, os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location("ce", os.path.join(ROOT, "scripts", "check-excerpts.py"))
ce = importlib.util.module_from_spec(spec); spec.loader.exec_module(ce)

SRC = ["contract Counter {", "    uint256 public counter;", "    function increment() external returns (uint256) {", "        counter++;"]

def test_verbatim_lines_pass():
    assert ce.missing_lines(["uint256 public counter;", "counter++;"], SRC) == []

def test_drifted_line_is_reported():
    assert ce.missing_lines(["counter += 2;"], SRC) == ["counter += 2;"]

def test_comments_and_elisions_are_skipped():
    assert ce.missing_lines(["// what the composer did", "⋯", "...", "", "/* note */"], SRC) == []

if __name__ == "__main__":
    fails = 0
    for name, fn in sorted(globals().items()):
        if name.startswith("test_"):
            try: fn(); print("ok   ", name)
            except AssertionError as e: fails += 1; print("FAIL ", name, e)
    sys.exit(1 if fails else 0)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python3 scripts/test_check_excerpts.py`
Expected: FAIL. The file `scripts/check-excerpts.py` does not exist, so it raises FileNotFoundError.

- [ ] **Step 3: Write the checker**

```python
#!/usr/bin/env python3
"""Every code line on a quickstart excerpt step must exist verbatim upstream at the pin.

verify-citations.py checks that a cited line holds the named symbol. That does not
catch a panel line edited after it was copied, or copied from the wrong file. This
does: each non-comment panel line of a registered step must appear (whitespace-
trimmed) as a line of one of that step's registered upstream files.

Usage: python3 scripts/check-excerpts.py [--offline]
"""
import importlib.util, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def _load(name, file):
    spec = importlib.util.spec_from_file_location(name, os.path.join(ROOT, "scripts", file))
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod); return mod

CORE = "eez-core-protocol"
# page -> {0-based codeByStep index: [upstream paths in eez-core-protocol @ pin]}
EXCERPTS = {
    "qs0-one-call-two-rollups.html": {
        0: ["src/base/CrossChainProxy.sol"],
        1: ["src/EEZ.sol"],
        2: ["src/EEZ.sol"],
    },
    "qs3-who-answered.html": {
        0: ["script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol"],
        1: ["script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol"],
        2: ["script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol"],
    },
    "qs5-three-gotchas-before-you-build.html": {
        0: ["src/base/CrossChainProxy.sol", "src/EEZ.sol"],
        1: ["src/EEZ.sol"],
        2: ["test/mocks/CounterContracts.sol"],
    },
    "qs7-cross-chain-flash-loan.html": {
        1: ["src/periphery/defiMock/FlashLoan.sol", "src/periphery/defiMock/FlashLoanBridgeExecutor.sol"],
        2: ["src/periphery/defiMock/FlashLoan.sol", "src/periphery/defiMock/FlashLoanBridgeExecutor.sol"],
    },
    "qs8-bridge-tokens-both-ways.html": {
        1: ["src/periphery/Bridge.sol"],
        2: ["src/periphery/Bridge.sol"],
    },
}
SKIP_PREFIXES = ("//", "/*", "*", "⋯", "...")

def missing_lines(panel_lines, source_lines):
    have = {s.strip() for s in source_lines}
    out = []
    for line in panel_lines:
        t = line.strip()
        if not t or t.startswith(SKIP_PREFIXES):
            continue
        if t not in have:
            out.append(t)
    return out

def main():
    offline = "--offline" in sys.argv
    llms = _load("build_llms", "build-llms.py")
    vc = _load("verify_citations", "verify-citations.py")
    sha = vc.load_pins()[CORE]["sha"]
    problems, checked = [], 0
    for page, steps in sorted(EXCERPTS.items()):
        path = os.path.join(ROOT, "dapp-developers", page)
        if not os.path.exists(path):
            problems.append(f"{page}: registered but missing"); continue
        panels = llms.steps_of(open(path, encoding="utf-8").read(), page)
        for idx, files in sorted(steps.items()):
            if idx >= len(panels):
                problems.append(f"{page}: step {idx + 1} registered but page has {len(panels)} steps"); continue
            source = []
            for f in files:
                source += vc.fetch(CORE, sha, f, offline)
            for bad in missing_lines(panels[idx], source):
                problems.append(f"{page} step {idx + 1}: not verbatim in {', '.join(files)} @ {sha[:7]}: {bad!r}")
            checked += 1
    print(f"excerpt steps checked: {checked}")
    if problems:
        print("FAILED (%d):" % len(problems)); [print("  -", p) for p in problems]; sys.exit(1)
    print("Every excerpt line is verbatim upstream at the pin.")

if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run the self-test to verify it passes**

Run: `python3 scripts/test_check_excerpts.py`
Expected: three `ok` lines, exit 0.

- [ ] **Step 5: Register the qs pages in the panel-drift check**

In `scripts/check-panel-drift.py`:
- Change the scan regex `r"(q|pr)[1-9]"` to `r"(qs[0-9]|q[1-9]|pr[1-9])"`. Without this, qs pages would be skipped silently.
- Add to `SNIPPET_MAP`: `"qs2-read-your-side-of-it.html": "qs2-counter-and-proxy.sol",`
- Add to `NON_SOLIDITY`: `"qs1-run-your-first-round-trip.html": "shell commands and their recorded output (run by scripts/run-quickstart.sh)",`
- Add a new allowlist below `NON_SOLIDITY`, with its own comment, and make `main()` skip a page found in it exactly as it skips `ILLUSTRATIVE_ONLY`:

```python
# Verbatim upstream excerpts. Not compiled here, but checked line for line against
# the pinned source by scripts/check-excerpts.py, which is the stronger check for
# code nobody should edit after copying.
EXCERPT_CHECKED = {
    "qs0-one-call-two-rollups.html": "upstream excerpt, check-excerpts.py",
    "qs3-who-answered.html": "upstream excerpt, check-excerpts.py",
    "qs5-three-gotchas-before-you-build.html": "upstream excerpt, check-excerpts.py",
    "qs7-cross-chain-flash-loan.html": "shell step + upstream excerpts, run-quickstart.sh + check-excerpts.py",
    "qs8-bridge-tokens-both-ways.html": "shell step + upstream excerpts, run-quickstart.sh + check-excerpts.py",
}
```

Run: `python3 scripts/check-panel-drift.py`
Expected: exit 0. The qs pages don't exist yet; confirm a missing registered page is not a failure by reading the loop. If it is a failure, guard it with `if find_page_path(page) is None: continue` and say so in the commit message.

- [ ] **Step 6: Wire CI**

Add two steps to the `structure` job in `.github/workflows/ci.yml`, after "Snippets still match upstream at the pin":

```yaml
      - name: Quickstart excerpts are verbatim upstream
        run: python3 scripts/check-excerpts.py

      - name: Excerpt checker still catches drift
        run: python3 scripts/test_check_excerpts.py
```

- [ ] **Step 7: Commit**

```bash
git add scripts/check-excerpts.py scripts/test_check_excerpts.py scripts/check-panel-drift.py .github/workflows/ci.yml
git commit -m "Add excerpt checker and register quickstart pages in the drift check"
```

---

### Task 2: Run script and clean timing

**Files:**
- Create: `scripts/run-quickstart.sh`
- Create: `scripts/test_run_quickstart.sh`
- Create: `docs/quickstart-runs.md` (run log: platform, versions, timings, output)

**Interfaces:**
- Produces: `scripts/run-quickstart.sh [--extract-only] PAGE...`. For each page it reads the `codeByStep` lines that start with `$ ` (via `build-llms.py`'s `steps_of`) and runs them in order in one bash session, inside a fresh temp dir. It prints `RAN: <cmd>` before each command and `ELAPSED <page> <seconds>` at the end. It exits non-zero on any failing command, or if a `git clone` of eez-core-protocol is not followed by `git checkout 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f`. With `--extract-only` it prints the commands and runs nothing.
- Produces: `docs/quickstart-runs.md`, which records N (the clean cold time for qs1). Task 11 copies N into the entry card.
- Card convention (Tasks 5, 9): shell panels write commands as `$ <command>`, and the expected output as plain lines copied from a real run.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# Self-test: the run script must extract exactly the page's $-lines and refuse an unpinned clone.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/dapp-developers"
cat > "$TMP/dapp-developers/qsT-good.html" <<'EOF'
<script>var codeByStep = [["$ echo one", "one"], ["$ echo two", "two"]];</script>
EOF
cat > "$TMP/dapp-developers/qsT-unpinned.html" <<'EOF'
<script>var codeByStep = [["$ git clone https://github.com/eez-association/eez-core-protocol.git", "$ cd eez-core-protocol"]];</script>
EOF
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --extract-only qsT-good.html)"
[[ "$out" == $'echo one\necho two' ]] || { echo "FAIL extract: got [$out]"; exit 1; }
if QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --extract-only qsT-unpinned.html >/dev/null 2>&1; then
  echo "FAIL unpinned clone was accepted"; exit 1; fi
echo "ok   run-quickstart self-test"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/test_run_quickstart.sh`
Expected: FAIL. The script is missing, so the `--extract-only` call errors and the `FAIL extract` line prints.

- [ ] **Step 3: Write the run script**

```bash
#!/usr/bin/env bash
# Run every command a quickstart card shows, exactly as the page shows it.
# The commands come out of the page's codeByStep ($-prefixed lines), never a
# second copy, so a card cannot drift from what was actually run.
set -euo pipefail
ROOT="${QS_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
PIN=9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
EXTRACT=0; [[ "${1:-}" == "--extract-only" ]] && { EXTRACT=1; shift; }
[[ $# -ge 1 ]] || { echo "usage: $0 [--extract-only] PAGE..." >&2; exit 2; }

extract() {
  python3 - "$SCRIPTS/build-llms.py" "$ROOT/dapp-developers/$1" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("b", sys.argv[1]); b = importlib.util.module_from_spec(spec); spec.loader.exec_module(b)
for step in b.steps_of(open(sys.argv[2], encoding="utf-8").read(), sys.argv[2]):
    for line in step:
        if line.startswith("$ "):
            print(line[2:])
PY
}

for page in "$@"; do
  cmds="$(extract "$page")"
  if grep -q "git clone .*eez-core-protocol" <<<"$cmds" && ! grep -q "git checkout -q $PIN\|git checkout $PIN" <<<"$cmds"; then
    echo "$page: clones eez-core-protocol without checking out the pin $PIN" >&2; exit 1
  fi
  if [[ $EXTRACT == 1 ]]; then printf '%s\n' "$cmds"; continue; fi
  work="$(mktemp -d)"; t0=$(date +%s)
  ( cd "$work"; set -e; while IFS= read -r c; do echo "RAN: $c"; eval "$c"; done <<<"$cmds" )
  echo "ELAPSED $page $(( $(date +%s) - t0 ))"
done
```

Each page's commands run in their own temp dir, so qs7 and qs8 must contain their own clone, checkout and build lines. The qs1 sequence is the canonical one; Tasks 5 and 9 repeat it.

- [ ] **Step 4: Run the self-test to verify it passes**

Run: `bash scripts/test_run_quickstart.sh`
Expected: `ok   run-quickstart self-test`

- [ ] **Step 5: Measure N on a quiet machine**

Stop anything competing for CPU first: `kurtosis engine stop` and `docker ps -q | xargs -r docker stop`. Then time a cold run of exactly the qs1 command sequence below, which Task 5 will put on the page:

```bash
mkdir -p /tmp/qs-measure && cd /tmp/qs-measure && rm -rf eez-core-protocol
/usr/bin/time -p bash -c '
git clone https://github.com/eez-association/eez-core-protocol.git &&
cd eez-core-protocol &&
git checkout -q 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f &&
git submodule update --init --recursive &&
forge build &&
bash script/e2e/run/local/parallel.sh counter counterL2'
```

Write `docs/quickstart-runs.md` with:
- the date, `sw_vers -productVersion`, `uname -m`, `sysctl -n machdep.cpu.brand_string` and `forge --version`;
- the four timings: clone + submodules, `forge build`, scenario run, total;
- the verbatim final 4 output lines;
- N = the total rounded up to the next 5 minutes;
- the same record for `parallel.sh flash-loan` and `parallel.sh bridge bridgeL2` run from the built tree.

- [ ] **Step 6: Commit**

```bash
git add scripts/run-quickstart.sh scripts/test_run_quickstart.sh docs/quickstart-runs.md
git commit -m "Add run-quickstart.sh (runs the commands the cards show) and the timed run log"
```

---

### Task 3: The `eez-demos-quickstart` skill

**Files:**
- Create: `.claude/skills/eez-demos-quickstart/SKILL.md`

**Interfaces:**
- Consumes: `scripts/run-quickstart.sh` and `scripts/check-excerpts.py` (Tasks 1–2).
- Produces: the skill that card agents (Tasks 4–10) read first.

- [ ] **Step 1: Write the skill**

Frontmatter:

```yaml
---
name: eez-demos-quickstart
description: Use when adding or editing a card in the eez-demos dApp Quickstart track (dapp-developers/qs*.html), or any eez-demos walkthrough whose panel shows commands to run — covers the run-it-for-real gate, measured time claims, local-vs-devnet framing, excerpt registration and the track's wiring.
---
```

The body must contain these sections, each with concrete paths and commands:
1. **Before you write.** Read the spec and the plan's Global Constraints, then `eez-protocol-dev` for grounding.
2. **Run-it-for-real gate.** Shell panels use `$ ` lines. Run `bash scripts/run-quickstart.sh <page>` and paste output lines from that run. A command you didn't run never appears.
3. **Time claims.** Durations only from `docs/quickstart-runs.md`, rounded up to 5 minutes. No measurement means no number.
4. **Local vs devnet framing.** Locally the scenario script plays composer, so a local card says what you *see*. Only a devnet card may say you *build*. Cite `E2ECounter.s.sol` for the script's role.
5. **Excerpts.** A code step is either verbatim upstream, registered in `EXCERPTS` in `scripts/check-excerpts.py`, or verbatim from a `snippets/*.sol` registered in `SNIPPET_MAP`. Cite `file:line` at the pin, with `citeByStep` when steps cite different files (the q6/q7 pattern).
6. **Track wiring.** The `NEXT:` chain, the index phase strip, stubs (PRE-MAINNET label, requirements, links to ro1 and the track), `python3 scripts/build-llms.py`.
7. **Done check:** `bash scripts/audit.sh && python3 scripts/verify-citations.py && python3 scripts/check-panel-drift.py && python3 scripts/check-excerpts.py && python3 scripts/check-snippet-fidelity.py && python3 scripts/build-llms.py --check && (cd snippets && forge test)`, plus a headless-Chrome screenshot of every step at 1920×1080 and 390×844.

Keep it under 150 lines. Link CONTRIBUTING for everything it already covers instead of repeating it.

- [ ] **Step 2: Adversarial validation**

Dispatch a fresh general-purpose agent with no context, given only the repo path and this prompt:

> Using only `.claude/skills/eez-demos-quickstart/SKILL.md` and files it points to, plan (do not build) a hypothetical card `qs9-read-l2-state-from-l1.html` around the `staticReadWrite` scenario. List every point where the skill left you guessing or where you used outside knowledge.

Fix every gap it reports, in the skill.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/eez-demos-quickstart/SKILL.md
git commit -m "Add eez-demos-quickstart skill"
```

---

### Tasks 4–10: The cards (run in parallel after Tasks 1–3)

Every card task follows the same procedure:
1. Read the skill, the spec, the Global Constraints and q7/q6 (the `citeByStep` pattern) and ro1 (the shell-panel pattern).
2. Scaffold with `scripts/new-demo.sh dapp-developers <slug> "<Title>"`.
3. Replace every TODO.
4. Run the card's checks.
5. Report what changed. Do not commit.

The step outlines below are binding. The exact lines are the agent's to pick, verbatim at the pin.

#### Task 4: qs0 — One Call, Two Rollups, One Transaction

**Files:** Create `dapp-developers/qs0-one-call-two-rollups.html`

Hook (index phase strip): "See how a contract on L1 gets an L2 contract's answer back in the same transaction."

Steps:
1. **"YOUR CONTRACT CALLS A PROXY."** Diagram: `myContract` on L1 → `proxy(Counter@L2)`. Code: the proxy's forward to the manager, from `src/base/CrossChainProxy.sol` (`fallback`/`_fallback`).
2. **"THE ANSWER IS ALREADY THERE."** Diagram: the manager finds an entry the composer posted earlier in the block. Code: `executeCrossChainCall` and the lookup of the pre-built entry in `src/EEZ.sol`.
3. **"SAME TRANSACTION."** Diagram: the return value flows back to `myContract`, with no callback. Code: the line in `src/EEZ.sol` that returns the entry's `returnData` to the caller.

Captions say "composer", never "sequencer". Step 3 links q2 ("use the answer") as further reading.

Check: `python3 scripts/check-excerpts.py`, `python3 scripts/verify-citations.py`, `node --check` on the inline script.

#### Task 5: qs1 — Run Your First Round Trip

**Files:** Create `dapp-developers/qs1-run-your-first-round-trip.html`

Steps (shell panels):
1. **"CLONE AT THE PIN."** Commands: the exact qs1 sequence from Task 2 Step 5, up to and including `git submodule update --init --recursive`. Diagram: what you need (Foundry 1.7.1, Git; no Docker).
2. **"BUILD AND RUN BOTH DIRECTIONS."** Commands: `$ forge build` and `$ bash script/e2e/run/local/parallel.sh counter counterL2`. Output: the verbatim PASS lines from `docs/quickstart-runs.md`.
3. **"WHAT THAT PASS PROVED."** No new commands; repeat the 4 output lines. Diagram: two anvil chains; L1 `CounterAndProxy` got `1` back from `Counter` on L2 in one transaction, and the reverse for `counterL2`. Caption: "Locally, the scenario script played composer. You'll see what it did in two cards."

Check: `bash scripts/run-quickstart.sh qs1-run-your-first-round-trip.html` exits 0 and prints the same PASS lines the page shows.

#### Task 6: qs2 — Read Your Side of It

**Files:**
- Create `dapp-developers/qs2-read-your-side-of-it.html`
- Create `snippets/qs2-counter-and-proxy.sol`
- Create `snippets/test/QS2CounterAndProxy.t.sol`

Snippet: verbatim `Counter`, `CounterAndProxy` and `PROXY_CALL_GAS` from `test/mocks/CounterContracts.sol` @ pin, with a `// Mirrors eez-core-protocol/test/mocks/CounterContracts.sol:<lines> @ 9a1f815` header. Test, in the snippets' no-forge-std style:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Counter, CounterAndProxy} from "../qs2-counter-and-proxy.sol";

// The same CounterAndProxy, pointed at a same-chain Counter: the call site is
// identical whether `target` is a local contract or a cross-chain proxy.
contract QS2CounterAndProxyTest {
    function test_sameCallSiteWorksAgainstALocalCounter() public {
        Counter target = new Counter();
        CounterAndProxy cap = new CounterAndProxy(target);
        cap.incrementProxy();
        require(target.counter() == 1, "target not incremented");
        require(cap.targetCounter() == 1, "return value not used");
        require(cap.counter() == 1, "local state not updated");
    }
}
```

Steps:
1. **"THE CONTRACT ON L2."** `Counter`.
2. **"YOUR CONTRACT ON L1."** `CounterAndProxy.incrementProxy`: an ordinary call, with the return value used on the next line.
3. **"POINT IT ANYWHERE."** The test above. Caption: the only cross-chain part is which address `target` holds, which is a proxy (link q7).

Check: `cd snippets && forge test --match-contract QS2CounterAndProxyTest`, `python3 scripts/check-panel-drift.py`, `python3 scripts/check-snippet-fidelity.py`, `python3 scripts/sync-embedded-snippets.py --check`.

#### Task 7: qs3 — Who Answered?

**Files:** Create `dapp-developers/qs3-who-answered.html`

All three steps excerpt `script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol`:
1. **"THE ANSWER, WRITTEN DOWN FIRST."** The L1 entry with `returnData: abi.encode(uint256(1))`.
2. **"THE REAL CALL, ON L2."** The L2 entry's `incomingCalls` that runs `Counter.increment()`.
3. **"ONE HASH TIES THEM."** `_callHash`, used on both sides.

Captions: on a real network the composer builds both entries; locally the script does. Link pr6 (rolling hash) and q5 (call hash) as the deep dive. Do not explain rolling hashes here.

Check: `python3 scripts/check-excerpts.py`, `python3 scripts/verify-citations.py`.

#### Task 8: qs5 — Three Gotchas Before You Build

**Files:** Create `dapp-developers/qs5-three-gotchas-before-you-build.html`

One gotcha per step, each linking the page that covers it in depth:
1. **"MSG.SENDER IS THE PROXY."** Excerpt: the proxy forwarding the call, from `CrossChainProxy.sol` / `EEZ.sol`. Link q3.
2. **"AN ENTRY COUNTS ONLY IN ITS BLOCK."** Excerpt: `_requireVerifiedThisBlock` and the `ExecutionNotInCurrentBlock` revert in `src/EEZ.sol`. Link q8.
3. **"ON L2, GAS IS PART OF THE CALL."** Excerpt: the `PROXY_CALL_GAS` doc comment and constant, `test/mocks/CounterContracts.sol:3-7`. Use the Gotcha #3 wording from the Global Constraints. Link q5.

Check: `python3 scripts/check-excerpts.py`, `python3 scripts/verify-citations.py`.

#### Task 9: qs7 and qs8 — the pattern cards

One agent per card; they run in parallel.

**qs7 — Cross-Chain Flash Loan.** File: `dapp-developers/qs7-cross-chain-flash-loan.html`
1. **"RUN IT."** Shell: the qs1 clone, checkout, submodule and build lines, then `$ bash script/e2e/run/local/parallel.sh flash-loan`, and the verbatim PASS lines.
2. **"BORROW ON L1, USE IT ON L2."** Excerpt from `FlashLoan.sol` / `FlashLoanBridgeExecutor.sol`.
3. **"REPAID BEFORE THE TRANSACTION ENDS."** The repayment check.

Before writing anything, read `script/e2e/scenarios/nested/L1_to_L2/flash-loan` and `test/IntegrationTestFlashLoan.t.sol`, and describe the nesting exactly as the source does.

**qs8 — Bridge Tokens Both Ways.** File: `dapp-developers/qs8-bridge-tokens-both-ways.html`
1. **"RUN IT."** The qs1 lines, then `$ bash script/e2e/run/local/parallel.sh bridge bridgeL2`, and the PASS lines.
2. **"LOCK AND MINT."** The outbound path in `src/periphery/Bridge.sol`.
3. **"BURN AND RELEASE."** The return path.

Check for both: `bash scripts/run-quickstart.sh <page>` exits 0, plus `python3 scripts/check-excerpts.py` and `python3 scripts/verify-citations.py`. qs8's `NEXT:` goes to `../index.html#dapp-developers`.

#### Task 10: qs4 and qs6 stubs

**Files:** Create `dapp-developers/qs4-run-it-with-a-real-composer.html` and `dapp-developers/qs6-deploy-your-own-contract.html`

Model them on the redirect-stub structure of `dapp-developers/q1-compute-your-cross-chain-address.html`, without the meta refresh. Each contains:
- the title;
- "Coming soon";
- one sentence on what the card will show;
- "Needs: a Linux host and at least 16 GB for Docker (the devnet does not run on macOS yet)";
- links to `../rollup-operators/ro1-run-the-devnet-with-kurtosis.html` and to `../index.html#quickstart`;
- the PRE-MAINNET label.

No `codeByStep`, no captions (`build-llms.py` then treats them as stubs).

Check: `bash scripts/audit.sh` passes the PRE-MAINNET and link sections for both files.

---

### Task 11: Index entry card, phase strip and next-card chain

**Files:**
- Modify: `index.html:153-182` (the "FIRST TIME HERE" block and the "Start here" paragraph below it)

Replace the block with `<section class="sec" id="quickstart">`, containing:
- **Eyebrow:** `[ DAPP DEVELOPERS — QUICKSTART ]`.
- **Entry card:** use the existing `.card` markup. Title "Build cross-rollup apps"; hook "Write cross-chain logic — flash loans, bridging — as naturally as a same-chain call. Run a cross-rollup round trip locally in about N minutes." N comes from `docs/quickstart-runs.md`. The card links to qs0.
- **Phase strip:** four rows (Understand, See it work, Make it real, Build patterns), each listing its cards as numbered `.card` links in track order. qs4 and qs6 carry a `COMING SOON` badge using the existing `.badge` class.

The "Start here" paragraph keeps only the operator and researcher reading orders. Verify every `NEXT:` link in qs0–qs8 matches the chain in the Global Constraints.

Check: `python3 scripts/build-llms.py && python3 scripts/build-llms.py --check && python3 scripts/test_build_llms.py && bash scripts/audit.sh`.

Commit: `git add index.html llms.txt llms-full.txt dapp-developers/qs*.html snippets && git commit -m "Add the dApp Quickstart track"`

---

### Task 12: Whole-branch verification and audit

- [ ] **Step 1:** Run the full suite. Every line must exit 0:

```bash
bash scripts/audit.sh
python3 scripts/verify-citations.py
python3 scripts/check-panel-drift.py
python3 scripts/check-excerpts.py && python3 scripts/test_check_excerpts.py
python3 scripts/check-snippet-fidelity.py && python3 scripts/test_snippet_fidelity.py
python3 scripts/build-llms.py --check && python3 scripts/test_build_llms.py
python3 scripts/check-manifest.py
python3 scripts/sync-embedded-snippets.py --check
bash scripts/test_run_quickstart.sh
bash scripts/run-quickstart.sh qs1-run-your-first-round-trip.html qs7-cross-chain-flash-loan.html qs8-bridge-tokens-both-ways.html
(cd snippets && ~/.foundry/bin/forge test)
```

- [ ] **Step 2:** Serve with `python3 -m http.server`. Take a headless-Chrome screenshot of each of the 3 steps of every walkthrough at 1920×1080, plus step 1 at 390×844, and look at every one.
- [ ] **Step 3:** Run the independent prose audit from CONTRIBUTING ("Audit, before merge") with a fresh agent. It checks every qs claim against source at the pin, and checks the entry card's N against `docs/quickstart-runs.md`. Fix what it finds.
- [ ] **Step 4:** Push the branch and open a PR. Merging needs the user's go-ahead.
