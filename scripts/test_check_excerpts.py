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

def test_step_with_zero_checked_lines_fails():
    # A registered step made only of comments, elisions and blanks checks nothing,
    # so "every line is verbatim" would pass vacuously. It must be reported.
    probs = ce.step_problems("qsT.html step 1", ["// only a note", "⋯", ""], SRC, "src/X.sol @ abc1234")
    assert len(probs) == 1 and "no checked lines" in probs[0], probs

def test_step_with_checked_lines_passes():
    assert ce.step_problems("qsT.html step 1", ["// note", "counter++;"], SRC, "src/X.sol @ abc1234") == []

def test_step_reports_drift():
    probs = ce.step_problems("qsT.html step 1", ["counter += 2;"], SRC, "src/X.sol @ abc1234")
    assert probs == ["qsT.html step 1: not verbatim in src/X.sol @ abc1234: 'counter += 2;'"], probs

def test_registry_mismatch_is_reported():
    probs = ce.registry_mismatch({"a.html": {}, "b.html": {}}, {"b.html": "", "c.html": ""})
    assert len(probs) == 2 and probs[0].startswith("a.html") and probs[1].startswith("c.html"), probs
    assert ce.registry_mismatch({"a.html": {}}, {"a.html": ""}) == []

if __name__ == "__main__":
    fails = 0
    for name, fn in sorted(globals().items()):
        if name.startswith("test_"):
            try: fn(); print("ok   ", name)
            except Exception as e: fails += 1; print("FAIL ", name, type(e).__name__, e)
    sys.exit(1 if fails else 0)
