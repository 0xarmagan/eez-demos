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
