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

import importlib.util
import json
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Reuse the single source of truth for page -> snippet, and its page-location
# helper (a page isn't always in dapp-developers/ - e.g. pr5), rather than
# restating either. check-panel-drift.py's filename has a hyphen so it can't
# be a plain `import`; load it by path instead.
_spec = importlib.util.spec_from_file_location(
    "check_panel_drift", os.path.join(REPO_ROOT, "scripts", "check-panel-drift.py"))
_drift_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_drift_mod)
_drift = _drift_mod.SNIPPET_MAP
find_page_path = _drift_mod.find_page_path

ARRAY_RE = re.compile(r"(  var fullSnippet = )\[.*?\n  \](;)", re.S)


def render(lines):
    body = ",\n".join("      " + json.dumps(ln.rstrip()) for ln in lines)
    return "[\n" + body + "\n  ]"


def main():
    check_only = "--check" in sys.argv
    changed, stale = [], []

    for page, rel in sorted(_drift.items()):
        page_path = find_page_path(page)
        sol_path = os.path.join(REPO_ROOT, "snippets", rel)
        if page_path is None or not os.path.exists(sol_path):
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
