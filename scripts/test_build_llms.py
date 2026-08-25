#!/usr/bin/env python3
"""Assert llms-full.txt is not silently lossy.

The generator renders each walkthrough's code panels out of the page's own
JavaScript. When a page builds `codeByStep` a way the extractor doesn't read,
the build still prints "15 walkthroughs" and exits 0 — the section is emitted
with a title, a source line and no code at all. `ro2` and `ro4` shipped that
way. This test is the gate: a walkthrough section with no fenced block fails.

Usage:
  python3 scripts/test_build_llms.py     # exits 1 on failure
  pytest scripts/test_build_llms.py -q   # if pytest is installed
"""

import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def test_every_walkthrough_emits_at_least_one_code_block():
    subprocess.run([sys.executable, "scripts/build-llms.py"], cwd=ROOT, check=True)
    text = (ROOT / "llms-full.txt").read_text(encoding="utf-8")
    sections = text.split("\n## ")[1:]
    empty = [s.splitlines()[0] for s in sections if "```" not in s]
    assert empty == [], "walkthroughs emitted with no code: %s" % empty


def main():
    # pytest is not installed on every machine that runs the audit, so the
    # file has to be its own runner too — otherwise the gate is skipped
    # exactly where it is needed.
    failed = 0
    for name, fn in sorted(globals().items()):
        if not name.startswith("test_") or not callable(fn):
            continue
        try:
            fn()
        except AssertionError as e:
            print("FAIL: %s\n  %s" % (name, e))
            failed += 1
        except Exception as e:                       # a build that dies is a fail
            print("ERROR: %s\n  %s: %s" % (name, type(e).__name__, e))
            failed += 1
        else:
            print("PASS: %s" % name)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
