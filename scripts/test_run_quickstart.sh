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
err="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --extract-only qsT-unpinned.html 2>&1 >/dev/null)"; rc=$?
[[ $rc -ne 0 ]] || { echo "FAIL unpinned clone was accepted"; exit 1; }
[[ "$err" == *"without checking out the pin"* ]] || { echo "FAIL unpinned: wrong error [$err]"; exit 1; }

fixture() {  # name, then the page's $-lines (one JSON-quoted step line per arg)
  local name="$1"; shift; local body="" a
  for a in "$@"; do body="$body    [\"\$ $a\"],"$'\n'; done
  printf '<script>\n  var codeByStep = [\n%s    ["end"]\n  ];\n</script>\n' "$body" > "$TMP/dapp-developers/$name"
}
PIN=9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
fixture qsT-pinned.html "git clone https://github.com/eez-association/eez-core-protocol.git" "git checkout -q $PIN"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --extract-only qsT-pinned.html)"; rc=$?
[[ $rc -eq 0 && "$out" == $'git clone https://github.com/eez-association/eez-core-protocol.git\ngit checkout -q '"$PIN" ]] \
  || { echo "FAIL pinned clone: rc=$rc got [$out]"; exit 1; }

fixture qsT-fail.html "echo hi" "false"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" qsT-fail.html 2>&1)"; rc=$?
[[ $rc -ne 0 ]] || { echo "FAIL failing command exited 0"; exit 1; }
[[ "$out" == *"RAN: echo hi"* ]] || { echo "FAIL fail run: no RAN line [$out]"; exit 1; }
[[ "$out" != *ELAPSED* ]] || { echo "FAIL fail run printed ELAPSED"; exit 1; }

fixture qsT-pass.html "echo hi"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" qsT-pass.html 2>&1)"; rc=$?
[[ $rc -eq 0 && "$out" == *"ELAPSED qsT-pass.html "* ]] || { echo "FAIL pass run: rc=$rc [$out]"; exit 1; }

printf '<script>\n  var codeByStep = [\n    ["no dollar line"]\n  ];\n</script>\n' > "$TMP/dapp-developers/qsT-empty.html"
err="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" qsT-empty.html 2>&1)"; rc=$?
[[ $rc -ne 0 && "$err" == *"qsT-empty.html: no commands found"* && "$err" != *ELAPSED* ]] || { echo "FAIL empty page: rc=$rc [$err]"; exit 1; }
echo "ok   run-quickstart self-test"
