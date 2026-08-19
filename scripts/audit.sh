#!/usr/bin/env bash
# Structural audit — a fast automated first pass for a new/changed demo.
#
# This does NOT verify citations against real source (that needs a fresh
# clone of eez-rollup0/eez-core-protocol and can't be scripted) — it only
# catches what's checkable from the repo alone. See CONTRIBUTING.md's
# "Audit, before merge" section for the manual steps this doesn't cover.
set -uo pipefail
cd "$(dirname "$0")/.."
FAIL=0
HTML_FILES="index.html dapp-developers/*.html rollup-operators/*.html protocol-researchers/*.html"

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
hits=$(grep -l "TODO" dapp-developers/*.html rollup-operators/*.html protocol-researchers/*.html 2>/dev/null || true)
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
hits=$(grep -nE '>[A-Za-z]+\.sol:[0-9]' dapp-developers/*.html rollup-operators/*.html protocol-researchers/*.html 2>/dev/null | grep -v "eez-core-protocol/" || true)
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
hits=$( { grep -nE 'letter-spacing:0.02em;">[^<]*\.rs' dapp-developers/*.html rollup-operators/*.html protocol-researchers/*.html; \
          grep -nE 'loc: "[^"]*\.rs' dapp-developers/*.html rollup-operators/*.html protocol-researchers/*.html; } 2>/dev/null | grep -v "crates/" || true)
if [ -n "$hits" ]; then
  echo "$hits" | sed 's/^/  /'
  FAIL=1
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "Structural audit passed."
  echo "This does NOT verify citations against real source — do that part by hand."
else
  echo "Structural audit FAILED — see above."
  exit 1
fi
