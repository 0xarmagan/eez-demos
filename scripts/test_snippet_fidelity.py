#!/usr/bin/env python3
"""Tests for scripts/check-snippet-fidelity.py, written against the bug it exists to catch.

`snippets/q2-cross-chain-call.sol` once shipped `STATIC_CHECK_GAS = 5000` against an
upstream `1_000`. Neither existing check could see it: `check-panel-drift.py` compares
the panel to the snippet, and the panel only ever shows `gas: STATIC_CHECK_GAS` — the
value appears in neither compared surface. `verify-citations.py` compares the citation
to upstream, and the citation was correct. So the test here does the one thing that
matters: it puts the wrong value back and asserts the checker says so, by name.

The second test is the guard against the opposite failure — a checker that flags
everything and is therefore worthless. It asserts the untouched tree reports no drift
on STATIC_CHECK_GAS. It deliberately does NOT assert exit 0, because unrelated genuine
findings elsewhere in the snippet set must not make this test lie.

Runs under pytest if it is installed, and standalone if it is not:

  python3 scripts/test_snippet_fidelity.py
"""

import os
import re
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHECKER = os.path.join("scripts", "check-snippet-fidelity.py")
SNIPPET = os.path.join(REPO_ROOT, "snippets", "q2-cross-chain-call.sol")
# STATIC_CHECK_GAS (the original 5000-vs-1_000 regression) moved upstream from the
# proxy to the manager at eez-core-protocol 9a1f815, so the snippet now reads it
# through IEEZ instead of declaring it. The probe uses the proxy constant the
# snippet still declares verbatim (CrossChainProxy.sol:36).
NAME = "STATIC_CHECK_SELECTOR"
GOOD = 'STATIC_CHECK_SELECTOR = bytes4(keccak256("staticCheck()"))'
BAD = 'STATIC_CHECK_SELECTOR = bytes4(keccak256("staticProbe()"))'


def run_checker():
    return subprocess.run(
        [sys.executable, CHECKER],
        cwd=REPO_ROOT, capture_output=True, text=True)


def drift_lines(out):
    """Only the lines the checker reports as drift, not every mention of a name."""
    return [ln for ln in out.splitlines() if ln.startswith("DRIFT")]


def test_detects_a_drifted_constant(tmp_path=None):
    """The regression that motivated this script: snippet 5000 vs upstream 1_000."""
    with open(SNIPPET, encoding="utf-8") as fh:
        good = fh.read()
    assert GOOD in good, (
        f"fixture drifted: {SNIPPET} no longer contains {GOOD!r} - "
        "if upstream changed, update this test with it")
    try:
        with open(SNIPPET, "w", encoding="utf-8") as fh:
            fh.write(good.replace(GOOD, BAD))
        r = run_checker()
        assert r.returncode != 0, (
            "checker exited 0 with a known-drifted constant in the tree\n"
            f"stdout:\n{r.stdout}\nstderr:\n{r.stderr}")
        assert NAME in r.stdout, (
            f"checker failed but never named the constant\nstdout:\n{r.stdout}")
        named = [ln for ln in drift_lines(r.stdout) if NAME in ln]
        assert named, (
            f"{NAME} appears in the output but not on a DRIFT line - "
            f"the checker failed for some other reason\nstdout:\n{r.stdout}")
        assert "staticProbe" in named[0] and "staticCheck" in named[0], (
            f"drift line names neither the got nor the want value: {named[0]!r}")
    finally:
        with open(SNIPPET, "w", encoding="utf-8") as fh:
            fh.write(good)
    with open(SNIPPET, encoding="utf-8") as fh:
        assert fh.read() == good, f"failed to restore {SNIPPET}"


def test_clean_tree_reports_no_drift_on_that_constant(tmp_path=None):
    """A checker that flags everything would pass the test above and be useless.

    Asserts only that the probed constant is clean on the untouched tree - not that the
    whole run exits 0, so an unrelated genuine finding elsewhere cannot silently
    invert this test's meaning.
    """
    r = run_checker()
    named = [ln for ln in drift_lines(r.stdout) if NAME in ln]
    assert not named, (
        f"checker reports drift on {NAME} with the tree untouched:\n"
        + "\n".join(named))
    assert re.search(r"compared", r.stdout), (
        "checker printed no account of what it compared - the exact failure mode "
        f"this script exists to prevent\nstdout:\n{r.stdout}")


def test_stand_in_marker_silences_a_declaration(tmp_path=None):
    """The escape hatch has to work, or the only way to pass is to delete a snippet.

    Same known-bad value as the first test, this time marked. It must be reported
    as skipped, by name, with the reason - never silently absent.
    """
    with open(SNIPPET, encoding="utf-8") as fh:
        good = fh.read()
    marked = good.replace(
        f"    bytes4 private constant {GOOD};",
        "    /// @stand-in test probe, not a real divergence\n"
        f"    bytes4 private constant {BAD};")
    assert marked != good, "fixture drifted: could not place the @stand-in marker"
    try:
        with open(SNIPPET, "w", encoding="utf-8") as fh:
            fh.write(marked)
        r = run_checker()
        named = [ln for ln in drift_lines(r.stdout) if NAME in ln]
        assert not named, (
            "a marked stand-in was still reported as drift:\n" + "\n".join(named))
        skipped = [ln for ln in r.stdout.splitlines()
                   if NAME in ln and "@stand-in" in ln]
        assert skipped, (
            "the marked declaration vanished from the report instead of being "
            f"listed as skipped\nstdout:\n{r.stdout}")
    finally:
        with open(SNIPPET, "w", encoding="utf-8") as fh:
            fh.write(good)
    with open(SNIPPET, encoding="utf-8") as fh:
        assert fh.read() == good, f"failed to restore {SNIPPET}"


TESTS = [
    test_detects_a_drifted_constant,
    test_clean_tree_reports_no_drift_on_that_constant,
    test_stand_in_marker_silences_a_declaration,
]


def main():
    failed = 0
    for t in TESTS:
        try:
            t()
        except AssertionError as e:
            failed += 1
            print(f"FAIL  {t.__name__}\n      {e}")
        except Exception as e:  # noqa: BLE001 - a crash is a failure, report and continue
            failed += 1
            print(f"ERROR {t.__name__}: {type(e).__name__}: {e}")
        else:
            print(f"ok    {t.__name__}")
    print(f"\n{len(TESTS) - failed}/{len(TESTS)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
