#!/usr/bin/env python3
"""Regenerate each page's embedded `fullSnippet` array from its snippets/*.sol file.

The FULL toggle shows a verbatim whole-file copy of the snippet, embedded in the
page as a JS array. `check-panel-drift.py` asserts that copy equals the file
line for line, so editing a .sol without re-embedding it fails CI.

That check tells you the two diverged. This is the half that fixes it: edit the
.sol, run this, done. Hand-syncing a 40-to-95-line array is exactly the kind of
manual companion step that gets skipped.

Usage:
  python3 scripts/sync-embedded-snippets.py           # rewrite where needed
  python3 scripts/sync-embedded-snippets.py --check   # report, change nothing
"""

import json
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO_ROOT, "scripts"))

# Reuse the single source of truth for page -> snippet rather than restating it.
_drift = {}
with open(os.path.join(REPO_ROOT, "scripts", "check-panel-drift.py")) as fh:
    _src = fh.read()
_map_src = re.search(r"SNIPPET_MAP = \{(.*?)\n\}", _src, re.S).group(1)
for m in re.finditer(r'"([^"]+)":\s*"([^"]+)"', _map_src):
    _drift[m.group(1)] = m.group(2)

ARRAY_RE = re.compile(r"(  var fullSnippet = )\[.*?\n  \](;)", re.S)


def render(lines):
    body = ",\n".join("      " + json.dumps(ln.rstrip()) for ln in lines)
    return "[\n" + body + "\n  ]"


def main():
    check_only = "--check" in sys.argv
    changed, stale = [], []

    for page, rel in sorted(_drift.items()):
        page_path = os.path.join(REPO_ROOT, "dapp-developers", page)
        sol_path = os.path.join(REPO_ROOT, "snippets", rel)
        if not (os.path.exists(page_path) and os.path.exists(sol_path)):
            print(f"  SKIP {page}: missing page or snippet")
            continue

        src = open(page_path, encoding="utf-8").read()
        m = ARRAY_RE.search(src)
        if not m:
            print(f"  SKIP {page}: no fullSnippet array")
            continue

        lines = open(sol_path, encoding="utf-8").read().splitlines()
        new_src = src[:m.start()] + m.group(1) + render(lines) + m.group(2) + src[m.end():]

        if new_src == src:
            continue
        stale.append(page)
        if not check_only:
            open(page_path, "w", encoding="utf-8").write(new_src)
            changed.append(page)

    if check_only:
        if stale:
            print(f"STALE ({len(stale)}) - run without --check:")
            for p in stale:
                print(f"  - {p}")
            return 1
        print("Every embedded fullSnippet matches its .sol file.")
        return 0

    if changed:
        print(f"Re-embedded {len(changed)} snippet(s):")
        for p in changed:
            print(f"  - {p}")
    else:
        print("Nothing to do; all embedded snippets already match.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
