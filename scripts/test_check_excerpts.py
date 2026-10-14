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
