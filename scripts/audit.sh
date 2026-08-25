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
#
# See CONTRIBUTING.md's "Audit, before merge" section for what remains manual.
set -uo pipefail
cd "$(dirname "$0")/.."
FAIL=0
# Enumerate from git, not the filesystem, so the audit checks what actually
# ships. Globbing the disk made this fail locally on an untracked scaffold file
# that CI never sees, which is a difference that only ever wastes time.
if git rev-parse --git-dir >/dev/null 2>&1; then
  HTML_FILES=$(git ls-files 'index.html' 'dapp-developers/*.html' 'rollup-operators/*.html' 'protocol-researchers/*.html')
else
  HTML_FILES="index.html dapp-developers/*.html rollup-operators/*.html protocol-researchers/*.html"
fi

echo "== Internal links resolve =="
for f in $HTML_FILES; do
  dir=$(dirname "$f")
  for href in $(grep -oE 'href="[^"]*\.html"' "$f" | sed 's/href="//;s/"//'); do
    case "$href" in http*) continue ;; esac
    resolved=$(python3 -c "import os; print(os.path.normpath(os.path.join('$dir', '$href')))" 2>/dev/null)
    if [ ! -f "$resolved" ]; then
      echo "  BROKEN: $f -> $href"
      FAIL=1
    fi
  done
done

echo "== JS syntax valid =="
for f in $HTML_FILES; do
  node -e "
    const fs = require('fs');
    const src = fs.readFileSync('$f', 'utf8');
    const m = src.match(/<script>([\s\S]*?)<\/script>/);
    if (m) new Function(m[1]);
  " 2>/tmp/eez-audit-js-err.$$ || { echo "  JS ERROR in $f:"; sed 's/^/    /' /tmp/eez-audit-js-err.$$; FAIL=1; }
  rm -f /tmp/eez-audit-js-err.$$
done

echo "== No leftover scaffold TODOs =="
hits=$(grep -l "TODO" $HTML_FILES 2>/dev/null || true)
if [ -n "$hits" ]; then
  echo "$hits" | sed 's/^/  /'
  FAIL=1
fi

echo "== No marketing-flavored language =="
hits=$(grep -rniE "trustless|seamless|revolutionary|next-gen|blazing|effortless|magic(al)?" $HTML_FILES 2>/dev/null || true)
if [ -n "$hits" ]; then
  echo "$hits" | sed 's/^/  /'
  FAIL=1
fi

echo "== Contract-layer citations use the eez-core-protocol/ path =="
hits=$(grep -nE '>[A-Za-z]+\.sol:[0-9]' $HTML_FILES 2>/dev/null | grep -v "eez-core-protocol/" || true)
if [ -n "$hits" ]; then
  echo "$hits" | sed 's/^/  /'
  FAIL=1
fi

echo "== Infra-layer .rs citations (the authoritative one, not diagram shorthand) use the crates/ path =="
# The .sol check above only ever covered eez-core-protocol; this is its
# equivalent for eez-rollup0's Rust crates (missed a real bug this way once —
# a bare "eez-deriver/src/deriver.rs" header with no crates/ prefix). Scoped to
# the code-panel header div and pr1's citation-chip data, same as every other
# demo's single authoritative citation — small in-diagram "file.rs:N" badges
# are an intentional shorthand that points back at that one, not a citation
# of their own, so they're not checked here.
hits=$( { grep -nE 'letter-spacing:0.02em;">[^<]*\.rs' $HTML_FILES; \
          grep -nE 'loc: "[^"]*\.rs' $HTML_FILES; } 2>/dev/null | grep -v "crates/" || true)
if [ -n "$hits" ]; then
  echo "$hits" | sed 's/^/  /'
  FAIL=1
fi

echo "== Every page carries the PRE-MAINNET label =="
# Added by 47922e6 to close a DevRel review gap, then deleted from all 15 pages
# by 81a211f — a syntax-highlighting commit — and nothing noticed for four days,
# while README.md went on claiming "every page says so". The pages make
# capability claims about a protocol that has not shipped; the label is the
# frame those claims are read in.
for f in $HTML_FILES; do
  case "$f" in *q1-compute-your-cross-chain-address.html) continue ;; esac
  if ! grep -qi "PRE-MAINNET" "$f"; then
    echo "  MISSING: $f"
    FAIL=1
  fi
done

echo
echo "== Generated files are current =="
# A stale generated file is how STATIC_CHECK_GAS=5000 kept shipping after the
# snippet was fixed: llms-full.txt is what agents read, and nothing compared it
# to its sources. --check compares without writing, so staleness FAILS here
# rather than being silently repaired by the section below.
python3 scripts/build-llms.py --check 2>&1 | sed 's/^/  /'
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
  FAIL=1
fi

echo
echo "== Every walkthrough reaches llms-full.txt with its code =="
# ro2 and ro4 shipped a title, a source line and zero steps because they build
# codeByStep from .slice() and the extractor only read string literals — and
# the build still exited 0. This runs the gate that catches a page whose panels
# are built a way build-llms.py cannot read. It regenerates llms.txt and
# llms-full.txt as a side effect, which is what build-llms.py is for.
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
  echo "If you edited a snippet: python3 scripts/sync-embedded-snippets.py"
  echo "If you edited any content: python3 scripts/build-llms.py"
else
  echo "Structural audit FAILED — see above."
  exit 1
fi
