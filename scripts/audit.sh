#!/usr/bin/env bash
# Structural audit — a fast automated first pass for a new/changed demo.
#
# This checks only what's verifiable from the repo alone. Three companion
# scripts cover the rest, and CI runs all four:
#
#   scripts/verify-citations.py    fetches each cited file at its pinned SHA
#                                  and asserts the line and symbol still match
#   scripts/check-panel-drift.py   asserts every Solidity line in a code panel
#                                  exists verbatim in a compilable snippet
#   scripts/check-snippet-fidelity.py  asserts every declaration a snippet shares
#                                  with upstream still matches upstream at the pin
#   scripts/sync-embedded-snippets.py  re-embeds a snippet after editing the .sol
#   scripts/build-llms.py          regenerates llms.txt / llms-full.txt
#   scripts/check-manifest.py      asserts docs/plans/2026-08-26-developer-content-v41.md
#                                  (the v4.1 execution manifest) against the tree
#
# See CONTRIBUTING.md's "Audit, before merge" section for what remains manual.
set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1
cd "$(dirname "$0")/.."
FAIL=0
# Enumerate from git, not the filesystem, so the audit checks what actually
# ships. Globbing the disk made this fail locally on an untracked scaffold file
# that CI never sees, which is a difference that only ever wastes time.
if git rev-parse --git-dir >/dev/null 2>&1; then
  HTML_FILES=()
  while IFS= read -r -d '' f; do
    HTML_FILES+=("$f")
  done < <(git ls-files -z 'index.html' 'dapp-developers/*.html' 'rollup-operators/*.html' 'protocol-researchers/*.html')
else
  shopt -s nullglob
  HTML_FILES=(index.html dapp-developers/*.html rollup-operators/*.html protocol-researchers/*.html)
fi

echo "== Internal links resolve =="
python3 -B - "${HTML_FILES[@]}" <<'PY_LINKS' || FAIL=1
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import sys

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.hrefs = []
    def handle_starttag(self, tag, attrs):
        self.hrefs.extend(value for key, value in attrs if key == "href" and value)

root = Path.cwd().resolve()
failed = False
for filename in sys.argv[1:]:
    page = Path(filename)
    parser = Links()
    parser.feed(page.read_text(encoding="utf-8"))
    for href in parser.hrefs:
        try:
            url = urlsplit(href)
            if url.scheme or url.netloc or not url.path.endswith(".html"):
                continue
            decoded = unquote(url.path)
            target = ((root / decoded.lstrip("/")) if decoded.startswith("/")
                      else (page.parent / decoded)).resolve()
            if root not in target.parents or not target.is_file():
                raise ValueError("missing target or path outside repository")
        except (ValueError, OSError) as exc:
            print(f"  BROKEN: {filename!r} -> {href!r}: {exc}")
            failed = True
sys.exit(int(failed))
PY_LINKS

echo "== JS syntax valid =="
for f in "${HTML_FILES[@]}"; do
  node - "$f" <<'JS_SYNTAX' || FAIL=1
const fs = require("fs");
const vm = require("vm");
const filename = process.argv[2];
const src = fs.readFileSync(filename, "utf8");
// Compile inline classic scripts without executing their contents.
for (const match of src.matchAll(/<script>([\s\S]*?)<\/script>/g)) {
  new vm.Script(match[1], { filename });
}
JS_SYNTAX
done

echo "== No leftover scaffold TODOs =="
hits=$(grep -l "TODO" "${HTML_FILES[@]}" 2>/dev/null || true)
if [ -n "$hits" ]; then
  echo "$hits" | sed 's/^/  /'
  FAIL=1
fi

echo "== No marketing-flavored language =="
hits=$(grep -rniE "trustless|seamless|revolutionary|next-gen|blazing|effortless|magic(al)?" "${HTML_FILES[@]}" 2>/dev/null || true)
if [ -n "$hits" ]; then
  echo "$hits" | sed 's/^/  /'
  FAIL=1
fi

echo "== Contract-layer citations use the eez-core-protocol/ path =="
hits=$(grep -nE '>[A-Za-z]+\.sol:[0-9]' "${HTML_FILES[@]}" 2>/dev/null | grep -v "eez-core-protocol/" || true)
if [ -n "$hits" ]; then
  echo "$hits" | sed 's/^/  /'
  FAIL=1
fi

echo "== Infra-layer .rs citations (the authoritative one, not diagram shorthand) use the crates/ path =="
# The .sol check above only ever covered eez-core-protocol; this is its
# equivalent for eez-rollupX's Rust crates (missed a real bug this way once —
# a bare "eez-deriver/src/deriver.rs" header with no crates/ prefix). Scoped to
# the code-panel header div and pr1's citation-chip data, same as every other
# demo's single authoritative citation — small in-diagram "file.rs:N" badges
# are an intentional shorthand that points back at that one, not a citation
# of their own, so they're not checked here.
hits=$( { grep -nE 'letter-spacing:0.02em;">[^<]*\.rs' "${HTML_FILES[@]}"; \
          grep -nE 'loc: "[^"]*\.rs' "${HTML_FILES[@]}"; } 2>/dev/null | grep -v "crates/" || true)
if [ -n "$hits" ]; then
  echo "$hits" | sed 's/^/  /'
  FAIL=1
fi

echo "== Every page carries its verified-against pin line =="
# Was a PRE-MAINNET label check (47922e6). EEZ-X is now live on Ethereum
# mainnet, so the frame every claim is read in is the pinned commit instead:
# each page must still say which commit it was verified against.
for f in "${HTML_FILES[@]}"; do
  case "$f" in *q1-compute-your-cross-chain-address.html) continue ;; esac
  # qs6 is a coming-soon stub with no code to pin yet.
  case "$f" in *qs6-deploy-your-own-contract.html) continue ;; esac
  # index.html is exempt by owner decision (2026-10-20): the landing page
  # links to walkthroughs, and every walkthrough carries the label itself.
  case "$f" in index.html|./index.html) continue ;; esac
  if ! grep -q "Verified against" "$f"; then
    echo "  MISSING: $f"
    FAIL=1
  fi
done

echo
echo "== Generated files are current =="
# A stale generated file is how STATIC_CHECK_GAS=5000 kept shipping after the
# snippet was fixed: llms-full.txt is what agents read, and nothing compared it
# to its sources. --check compares without writing, so staleness FAILS here
# without rewriting the generated files.
python3 scripts/build-llms.py --check 2>&1 | sed 's/^/  /'
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
  FAIL=1
fi

echo
echo "== Every walkthrough reaches llms-full.txt with its code =="
# ro2 and ro4 shipped a title, a source line and zero steps because they build
# codeByStep from .slice() and the extractor only read string literals — and
# the build still exited 0. This runs the gate that catches a page whose panels
# are built a way build-llms.py cannot read. The export is built in memory;
# neither this test nor the audit rewrites generated files.
python3 scripts/test_build_llms.py 2>&1 | sed 's/^/  /'
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
  FAIL=1
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "Structural audit passed."
  echo "Next: python3 scripts/verify-citations.py  (citations vs real source)"
  echo "      python3 scripts/check-panel-drift.py (panels vs compilable snippets)"
  echo "      python3 scripts/check-snippet-fidelity.py (snippets vs upstream at the pin)"
  echo "      python3 scripts/check-manifest.py     (the v4.1 manifest vs the tree)"
  echo "If you edited a snippet: python3 scripts/sync-embedded-snippets.py"
  echo "If you edited any content: python3 scripts/build-llms.py"
else
  echo "Structural audit FAILED — see above."
  exit 1
fi
