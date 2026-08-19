#!/usr/bin/env bash
# Scaffold a new walkthrough from the q1 template.
#
# Usage:
#   scripts/new-demo.sh <audience> <slug> <title>
#
#   audience  dapp-developers | rollup-operators | protocol-researchers
#   slug      filename without .html, e.g. q7-my-new-topic
#   title     display title, e.g. "My New Topic"
#
# This gets you a structurally-correct file (fixed stage, terminal code
# panel, PRE-MAINNET label, favicon, mobile scaleStage floor) with every
# piece of real content — diagram, code, citation, kickers, captions —
# replaced with an obvious TODO. It does NOT wire the file into
# index.html or the NEXT: chain — that's still a manual step, see
# CONTRIBUTING.md.
set -euo pipefail

AUDIENCE="${1:?Usage: $0 <dapp-developers|rollup-operators|protocol-researchers> <slug> <Title>}"
SLUG="${2:?slug required, e.g. q7-my-new-topic}"
TITLE="${3:?title required, e.g. \"My New Topic\"}"

case "$AUDIENCE" in
  dapp-developers|rollup-operators|protocol-researchers) ;;
  *) echo "error: audience must be dapp-developers, rollup-operators, or protocol-researchers" >&2; exit 1 ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_ROOT/dapp-developers/q1-compute-your-cross-chain-address.html"
DEST="$REPO_ROOT/$AUDIENCE/$SLUG.html"

if [ ! -f "$TEMPLATE" ]; then
  echo "error: template not found at $TEMPLATE" >&2
  exit 1
fi
if [ -e "$DEST" ]; then
  echo "error: $DEST already exists" >&2
  exit 1
fi

cp "$TEMPLATE" "$DEST"

python3 - "$DEST" "$TITLE" <<'PYEOF'
import re, sys
path, title = sys.argv[1], sys.argv[2]
s = open(path).read()

s = s.replace("Compute Your Cross-Chain Address — EEZ", f"{title} — EEZ")
s = s.replace('>Compute Your Cross-Chain Address</div>', f">{title}</div>")

# citation header -> obvious TODO
s = re.sub(
    r'(<div style="font-family:var\(--mono\);font-size:13px;color:#7a7a7a;letter-spacing:0\.02em;">)[^<]*(</div>)',
    r'\1TODO: real file:line citation, verified fresh\2', s, count=1)

# flag the whole diagram block as needing full replacement, not reuse
s = s.replace(
    "<!-- ===== DIAGRAM — dense byte-flow visualization ===== -->",
    "<!-- ===== DIAGRAM — TODO: replace steps s1/s2/s3 below entirely. This is still q1's byte-packing diagram. ===== -->"
)

# kickers / captions -> TODO placeholders (real content is topic-specific, never reuse)
s = re.sub(r'var kickers = \[.*?\];',
           'var kickers = ["TODO STEP 1", "TODO STEP 2", "TODO STEP 3"];', s, flags=re.S)
s = re.sub(r'var captions = \[.*?\];',
           'var captions = [\n    "TODO: step 1 caption — one sentence.",\n'
           '    "TODO: step 2 caption — one sentence.",\n'
           '    "TODO: step 3 caption — one sentence."\n  ];', s, flags=re.S)

open(path, "w").write(s)
PYEOF

echo "Created $DEST"
echo
echo "Still to do by hand (see CONTRIBUTING.md):"
echo "  1. Replace the diagram (steps s1/s2/s3) and codeByStep with real content for your topic."
echo "  2. Fix the citation header to a real file:line — verify against the pinned commit if it's under eez-core-protocol."
echo "  3. Add a card for it on index.html, under the right audience section."
echo "  4. Thread it into the NEXT: chain — update the demo before it, and this file's own NEXT: link."
echo "  5. Serve it locally (see CONTRIBUTING.md) and click through before opening a PR."
