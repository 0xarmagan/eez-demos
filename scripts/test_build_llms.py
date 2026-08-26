#!/usr/bin/env python3
"""Assert llms-full.txt is not silently lossy.

The generator renders each walkthrough's code panels out of the page's own
JavaScript. When a page builds `codeByStep` a way the extractor doesn't read,
the build still prints "15 walkthroughs" and exits 0 — the section is emitted
with a title, a source line and no code at all. `ro2` and `ro4` shipped that
way. This test is the gate: a walkthrough section with no fenced block fails.

"At least one block" is the floor, not the claim. A page whose extractor reads
step 1 and silently misses steps 2 and 3 passes that floor while shipping a
third of the page — the same class of loss, one notch quieter. So the count is
asserted too, per page, against the page's OWN step count rather than a
hardcoded 15 or 16: the number of fenced blocks a walkthrough emits must equal
the number of captions it narrates. That way a four-step page landing tomorrow
is covered on the day it lands instead of failing a stale constant.

Usage:
  python3 scripts/test_build_llms.py     # exits 1 on failure
  pytest scripts/test_build_llms.py -q   # if pytest is installed
"""

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))


def _pages():
    """The generator's own page list, so the two cannot disagree about what a
    walkthrough is (a redirect stub has no captions and is not one)."""
    import importlib.util

    spec = importlib.util.spec_from_file_location(
        "build_llms", ROOT / "scripts" / "build-llms.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.collect()


def test_every_walkthrough_emits_at_least_one_code_block():
    subprocess.run([sys.executable, "scripts/build-llms.py"], cwd=ROOT, check=True)
    text = (ROOT / "llms-full.txt").read_text(encoding="utf-8")
    sections = text.split("\n## ")[1:]
    empty = [s.splitlines()[0] for s in sections if "```" not in s]
    assert empty == [], "walkthroughs emitted with no code: %s" % empty


def test_every_walkthrough_emits_a_code_block_per_step():
    """The count gate. A page that narrates three steps and emits one has lost
    two, and nothing else in the repo can see that."""
    subprocess.run([sys.executable, "scripts/build-llms.py"], cwd=ROOT, check=True)
    text = (ROOT / "llms-full.txt").read_text(encoding="utf-8")

    # Walkthrough sections are "## <title>"; steps inside them are
    # "### Step N — <kicker>", and the snippet/test appendices are "### " too,
    # so steps are matched by that prefix rather than by being a subsection.
    sections = {}
    for chunk in text.split("\n## ")[1:]:
        sections[chunk.splitlines()[0].strip()] = chunk

    problems = []
    for page in _pages():
        title = page["title"].strip()
        chunk = sections.get(title)
        if chunk is None:
            problems.append("%s: no section titled %r in llms-full.txt"
                            % (page["rel"], title))
            continue

        subs = re.split(r"\n### ", chunk)[1:]
        steps = [b for b in subs if b.startswith("Step ")]
        want = len(page["steps"])
        if want and len(steps) != want:
            problems.append("%s: %d step section(s) exported for %d step(s) on the page"
                            % (page["rel"], len(steps), want))
            continue
        # A step heading with no fence under it is the ro2/ro4 failure one
        # level down: the step is listed, its code is gone.
        for i, block in enumerate(steps, 1):
            if "```" not in block:
                problems.append("%s: step %d exported with no code block"
                                % (page["rel"], i))

    assert problems == [], ("steps lost in the export:\n  "
                            + "\n  ".join(problems))


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
