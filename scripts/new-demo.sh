#!/usr/bin/env bash
# Scaffold a new walkthrough from the pr5 template.
#
# Usage:
#   scripts/new-demo.sh <audience> <slug> <title>
#
#   audience  dapp-developers | rollup-operators | protocol-researchers
#   slug      filename without .html, e.g. q7-my-new-topic
#   title     display title, e.g. "My New Topic"
#
# This gets you a structurally-correct file (fixed stage, terminal code
# panel, pre-mainnet intro note, favicon, mobile scaleStage floor) with every
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

[[ "$SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
  echo "error: slug must contain only lowercase letters, digits and hyphens" >&2
  exit 1
}

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_ROOT/protocol-researchers/pr5-how-the-address-is-derived.html"
DEST="$REPO_ROOT/$AUDIENCE/$SLUG.html"

if [ ! -f "$TEMPLATE" ]; then
  echo "error: template not found at $TEMPLATE" >&2
  exit 1
fi
if [ -e "$DEST" ]; then
  echo "error: $DEST already exists" >&2
  exit 1
fi

python3 -B - "$DEST" "$TITLE" "$AUDIENCE" "$SLUG" "$TEMPLATE" "$REPO_ROOT" <<'PYEOF'
import html, re, sys
from pathlib import Path
path, title, audience, slug, template, root = sys.argv[1:7]
if Path(path).parent.resolve() != Path(root).resolve() / audience:
    sys.exit("new-demo.sh: destination directory resolves outside its audience")
title = html.escape(title, quote=True)
s = Path(template).read_text(encoding="utf-8")

def sub(pattern, repl):
    """Regex replace that FAILS LOUDLY if the template no longer matches, so a
    drifting pr5 can never again silently leave its own content in a scaffold."""
    global s
    new, n = re.subn(pattern, lambda m: m.expand(repl), s, count=1, flags=re.S)
    if n == 0:
        sys.exit("new-demo.sh: template pattern no longer matches pr5: " + pattern[:70])
    s = new

def lit(old, new):
    global s
    if old not in s:
        sys.exit("new-demo.sh: template text no longer in pr5: " + old[:70])
    s = s.replace(old, new)

eyebrow = {"dapp-developers": "DAPP DEVELOPERS", "rollup-operators": "ROLLUP OPERATORS",
           "protocol-researchers": "PROTOCOL RESEARCHERS"}[audience]
esc_title = title.replace("\\", "\\\\")

# --- identity: title, canonical, header, lead-in ------------------------
sub(r'<title>.*?</title>', f"<title>{esc_title} — EEZ</title>")
sub(r'<link rel="canonical" href="[^"]*">',
    f'<link rel="canonical" href="https://eez-association.github.io/eez-demos/{audience}/{slug}.html">')
lit('<div style="font-size:22px;font-weight:600;color:#fff;">How the Address Is Derived</div>',
    f'<div style="font-size:22px;font-weight:600;color:#fff;">{title}</div>')
lit('<h1 class="intro-title" id="introTitle">How the address is derived</h1>',
    f'<h1 class="intro-title" id="introTitle">{title}</h1>')
lit('<div class="intro-eyebrow">PROTOCOL RESEARCHERS</div>', f'<div class="intro-eyebrow">{eyebrow}</div>')

# --- NEXT link: pr5's points at pr6; the new page is not wired in yet ----
#     Two links carry it: the small header one and the bottom-bar Up-next button.
sub(r'<a class="back hdr-rule" href="pr6-the-rolling-hash\.html"[^>]*>.*?</a>',
    '<a class="back hdr-rule" href="../index.html" style="border-left:1px solid #2a2a2a;padding-left:22px;">'
    'NEXT WALKTHROUGH: TODO next demo (set href + label, or delete this link if last in the chain) &rarr;</a>')
sub(r'(<a id="nextDemo" class="next-demo" href=")pr6-the-rolling-hash\.html(".*?<span class="next-demo-t">)The rolling hash(</span>)',
    r'\1../index.html\2TODO next demo (same href + title as the header NEXT link)\3')

# --- lead-in copy ----------------------------------------------------------
sub(r'<p class="intro-lede">.*?</p>\s*<p class="intro-lede">.*?</p>',
    '<p class="intro-lede">TODO: lead-in sentence 1.</p>\n      <p class="intro-lede">TODO: lead-in sentence 2.</p>')
sub(r'<ul class="intro-learn">.*?</ul>',
    '<ul class="intro-learn">\n'
    '        <li><b>01 · TODO STEP 1</b>TODO: what step 1 teaches.</li>\n'
    '        <li><b>02 · TODO STEP 2</b>TODO: what step 2 teaches.</li>\n'
    '        <li><b>03 · TODO STEP 3</b>TODO: what step 3 teaches.</li>\n'
    '      </ul>')
sub(r'(<p style="margin:12px 0 0;font-family:var\(--mono\);font-size:12\.5px;[^>]*>)Verified against[^<]*(</p>)',
    r'\1TODO: Verified against &lt;repo&gt; @ &lt;pinned sha&gt; &mdash; pre-mainnet; interfaces may move.\2')

# --- TRY IT calculator (pr5-specific salt calculator): remove button, panel, JS
sub(r'    <!-- TRY IT: live salt calculator.*?(?=\n\n    <!-- STEP 1:)', '')
sub(r'  var calcOn = false;.*?(?=  function copyFallback)', '')
sub(r'<script src="\.\./assets/eez-hash\.js"></script>\n', '')

# --- diagram: replace s1/s2/s3 wholesale ---------------------------------
def step(i, display):
    return (f'    <div id="s{i}" style="display:{display};flex-direction:column;gap:24px;">\n'
            f'      <div style="font-family:var(--mono);font-size:13px;letter-spacing:0.1em;color:var(--muted);">TODO STEP {i}</div>\n'
            f'      <div style="font-size:16px;color:var(--muted);max-width:820px;">TODO: step {i} diagram. Replace this block entirely.</div>\n'
            f'    </div>\n')
sub(r'    <!-- STEP 1:.*?(?=\n  \n    <!-- Narration)',
    '    <!-- TODO: replace steps s1/s2/s3 with this demo\'s diagram -->\n'
    + step(1, "flex") + "\n" + step(2, "none") + "\n" + step(3, "none"))
lit("<!-- ===== DIAGRAM — dense byte-flow visualization ===== -->",
    "<!-- ===== DIAGRAM — TODO: replace steps s1/s2/s3 below entirely. ===== -->")

# --- code panel citation (data-demo-cite + visible link) -----------------
sub(r'<div id="srcCite" data-demo-cite="[^"]*" (style="[^"]*")>.*?</div>\n',
    r'<div id="srcCite" data-demo-cite="TODO: real file:line citation, verified fresh" \1>TODO: real file:line citation, verified fresh</div>' + "\n")

# --- kickers / captions / code ------------------------------------------
sub(r'var kickers = \[.*?\];', 'var kickers = ["TODO STEP 1", "TODO STEP 2", "TODO STEP 3"];')
sub(r'var captions = \[.*?\];',
    'var captions = [\n    "TODO: step 1 caption — one sentence.",\n'
    '    "TODO: step 2 caption — one sentence.",\n'
    '    "TODO: step 3 caption — one sentence."\n  ];')
sub(r'var codeByStep = \[.*?\n  \];\n  var hlByStep = \[.*?\n  \];',
    'var codeByStep = [\n    ["// TODO: step 1 code lines"],\n    ["// TODO: step 2 code lines"],\n    ["// TODO: step 3 code lines"]\n  ];\n'
    '  var hlByStep = [\n    [0],\n    [0],\n    [0]\n  ];')
sub(r'  // Verbatim copy of snippets/q1-compute-address\.sol.*?var fullSnippet = \[.*?\n  \];',
    '  // TODO: verbatim copy of the whole snippets/<file>.sol (scripts/check-panel-drift.py\n'
    '  // asserts it equals that file line for line). Replace with real content, or delete\n'
    '  // this array, the FULL button and applyPanelMode()\'s FULL branch if no snippet.\n'
    '  var fullSnippet = [\n      "// TODO: full compilable snippet"\n  ];')
lit("'snippets/q1-compute-address.sol \\u00b7 solc 0.8.28'", "'snippets/TODO.sol \\u00b7 TODO solc version'")

# pr5's syntax-highlight builtin list names its own function; drop it so the
# scaffold carries no pr5 identifiers. (Other names are generic EEZ builtins.)
lit('"computeCrossChainProxyAddress":1,', '')

with open(path, "x", encoding="utf-8") as output:
    output.write(s)
PYEOF

echo "Created $DEST"
echo
echo "Still to do by hand (see CONTRIBUTING.md):"
echo "  1. Replace the diagram (steps s1/s2/s3) and codeByStep with real content for your topic."
echo "  2. Fix the citation header to a real file:line — verify against the pinned commit if it's under eez-core-protocol."
echo "  3. Add a card for it on index.html, under the right audience section."
echo "  4. Thread it into the NEXT: chain — update the demo before it, and this file's own NEXT: link."
echo "  5. Serve it locally (see CONTRIBUTING.md) and click through before opening a PR."
