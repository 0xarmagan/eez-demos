#!/usr/bin/env python3
"""Every code line on a quickstart excerpt step must exist verbatim upstream at the pin.

verify-citations.py checks that a cited line holds the named symbol. That does not
catch a panel line edited after it was copied, or copied from the wrong file. This
does: each non-comment panel line of a registered step must appear (whitespace-
trimmed) as a line of one of that step's registered upstream files. A registered
step with zero checked lines fails, and EXCERPTS must name the same pages as
EXCERPT_CHECKED in check-panel-drift.py (which skips those pages on our word).

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

def checked_lines(panel_lines):
    """The panel lines this check compares: trimmed, minus blanks, comments and elisions."""
    return [t for t in (line.strip() for line in panel_lines) if t and not t.startswith(SKIP_PREFIXES)]

def missing_lines(panel_lines, source_lines):
    have = {s.strip() for s in source_lines}
    return [t for t in checked_lines(panel_lines) if t not in have]

def step_problems(label, panel_lines, source_lines, where):
    """Problems for one registered step. A step whose every line is skipped checks
    nothing, so "every line is verbatim" would hold vacuously: that is a failure."""
    if not checked_lines(panel_lines):
        return [f"{label}: registered as an excerpt step but has no checked lines "
                f"(only comments, elisions or blanks)"]
    return [f"{label}: not verbatim in {where}: {bad!r}" for bad in missing_lines(panel_lines, source_lines)]

def registry_mismatch(excerpts, excerpt_checked):
    """EXCERPTS here and EXCERPT_CHECKED in check-panel-drift.py must name the same pages:
    panel-drift skips an EXCERPT_CHECKED page on the promise that this script checks it."""
    a, b = set(excerpts), set(excerpt_checked)
    return ([f"{p}: in check-excerpts.py EXCERPTS but not in check-panel-drift.py EXCERPT_CHECKED" for p in sorted(a - b)]
            + [f"{p}: in check-panel-drift.py EXCERPT_CHECKED but not in check-excerpts.py EXCERPTS" for p in sorted(b - a)])

def main():
    offline = "--offline" in sys.argv
    llms = _load("build_llms", "build-llms.py")
    vc = _load("verify_citations", "verify-citations.py")
    drift = _load("check_panel_drift", "check-panel-drift.py")
    sha = vc.load_pins()[CORE]["sha"]
    problems, checked = registry_mismatch(EXCERPTS, drift.EXCERPT_CHECKED), 0
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
            problems += step_problems(f"{page} step {idx + 1}", panels[idx], source, f"{', '.join(files)} @ {sha[:7]}")
            checked += 1
    print(f"excerpt steps checked: {checked}")
    if problems:
        print("FAILED (%d):" % len(problems)); [print("  -", p) for p in problems]; sys.exit(1)
    print("Every excerpt line is verbatim upstream at the pin.")

if __name__ == "__main__":
    main()
