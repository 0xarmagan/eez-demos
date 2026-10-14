#!/usr/bin/env bash
# Fixtures use the multi-line shape build-llms.py's js_array requires (`var codeByStep = [` ... `\n  ];`).
# Self-test: the run script must extract exactly the page's $-lines and refuse an unpinned clone.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/dapp-developers"
cat > "$TMP/dapp-developers/qsT-good.html" <<'EOT'
<script>
  var codeByStep = [
    ["$ echo one", "one"],
    ["$ echo two", "two"]
  ];
</script>
EOT
cat > "$TMP/dapp-developers/qsT-unpinned.html" <<'EOT'
<script>
  var codeByStep = [
    ["$ git clone https://github.com/eez-association/eez-core-protocol.git", "$ cd eez-core-protocol"]
  ];
</script>
EOT
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --extract-only qsT-good.html)"
[[ "$out" == $'echo one\necho two' ]] || { echo "FAIL extract: got [$out]"; exit 1; }
if QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --extract-only qsT-unpinned.html >/dev/null 2>&1; then
  echo "FAIL unpinned clone was accepted"; exit 1; fi
echo "ok   run-quickstart self-test"
