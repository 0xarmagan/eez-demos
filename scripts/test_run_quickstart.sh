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
PIN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["repos"]["eez-core-protocol"]["sha"])' "$ROOT/scripts/citation-pins.json")"
[[ "$PIN" =~ ^[0-9a-f]{40}$ ]] || { echo "FAIL no eez-core-protocol sha in citation-pins.json"; exit 1; }
fixture qsT-pinned.html "git clone https://github.com/eez-association/eez-core-protocol.git" "git checkout -q $PIN"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --extract-only qsT-pinned.html)"; rc=$?
[[ $rc -eq 0 && "$out" == $'git clone https://github.com/eez-association/eez-core-protocol.git\ngit checkout -q '"$PIN" ]] \
  || { echo "FAIL pinned clone: rc=$rc got [$out]"; exit 1; }

OTHER=0000000000000000000000000000000000000000
fixture qsT-otherpin.html "git clone https://github.com/eez-association/eez-core-protocol.git" "git checkout -q $OTHER"
err="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --extract-only qsT-otherpin.html 2>&1 >/dev/null)"; rc=$?
[[ $rc -ne 0 && "$err" == *"without checking out the pin $PIN"* ]] || { echo "FAIL different-SHA checkout accepted: rc=$rc [$err]"; exit 1; }

fixture qsT-fail.html "echo hi" "false"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --execute qsT-fail.html 2>&1)"; rc=$?
[[ $rc -ne 0 ]] || { echo "FAIL failing command exited 0"; exit 1; }
[[ "$out" == *"RAN: echo hi"* ]] || { echo "FAIL fail run: no RAN line [$out]"; exit 1; }
[[ "$out" != *ELAPSED* ]] || { echo "FAIL fail run printed ELAPSED"; exit 1; }

fixture qsT-pass.html "echo hi"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --execute qsT-pass.html 2>&1)"; rc=$?
[[ $rc -eq 0 && "$out" == *"ELAPSED qsT-pass.html "* ]] || { echo "FAIL pass run: rc=$rc [$out]"; exit 1; }

printf '<script>\n  var codeByStep = [\n    ["no dollar line"]\n  ];\n</script>\n' > "$TMP/dapp-developers/qsT-empty.html"
err="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --execute qsT-empty.html 2>&1)"; rc=$?
[[ $rc -ne 0 && "$err" == *"qsT-empty.html: no commands found"* && "$err" != *ELAPSED* ]] || { echo "FAIL empty page: rc=$rc [$err]"; exit 1; }

fixture qsT-skip.html "echo '===== RESULT: 0 passed, 0 failed, 1 skipped ====='"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --execute qsT-skip.html 2>&1)"; rc=$?
[[ $rc -ne 0 && "$out" == *"qsT-skip.html: scenario run passed nothing / failed / skipped: ===== RESULT: 0 passed, 0 failed, 1 skipped ====="* && "$out" != *ELAPSED* ]] \
  || { echo "FAIL skipped scenario accepted: rc=$rc [$out]"; exit 1; }

fixture qsT-ok.html "echo '===== RESULT: 2 passed, 0 failed, 0 skipped ====='"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --execute qsT-ok.html 2>&1)"; rc=$?
[[ $rc -eq 0 && "$out" == *"ELAPSED qsT-ok.html "* ]] || { echo "FAIL passing scenario: rc=$rc [$out]"; exit 1; }

fixture qsT-noresult.html "true script/e2e/run/local/parallel.sh counter"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --execute qsT-noresult.html 2>&1)"; rc=$?
[[ $rc -ne 0 && "$out" == *"qsT-noresult.html: parallel.sh printed no RESULT line"* && "$out" != *ELAPSED* ]] \
  || { echo "FAIL parallel.sh without RESULT accepted: rc=$rc [$out]"; exit 1; }

fixture qsT-result.html "true script/e2e/run/local/parallel.sh counter" "echo '===== RESULT: 1 passed, 0 failed, 0 skipped ====='"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --execute qsT-result.html 2>&1)"; rc=$?
[[ $rc -eq 0 && "$out" == *"ELAPSED qsT-result.html "* ]] || { echo "FAIL parallel.sh with RESULT: rc=$rc [$out]"; exit 1; }

# Default mode must never execute commands, even ones outside the allowlist.
fixture qsT-preview.html "touch $TMP/should-not-exist"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" qsT-preview.html 2>&1)"; rc=$?
[[ $rc -eq 0 && ! -e "$TMP/should-not-exist" && "$out" == "touch $TMP/should-not-exist" ]] \
  || { echo "FAIL default mode executed commands"; exit 1; }
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --execute qsT-preview.html 2>&1)"; rc=$?
[[ $rc -ne 0 && ! -e "$TMP/should-not-exist" && "$out" == *"unsupported command"* ]] \
  || { echo "FAIL unsupported executable accepted"; exit 1; }
fixture qsT-shell.html "echo \$(touch $TMP/should-not-exist)"
out="$(QS_ROOT="$TMP" bash "$ROOT/scripts/run-quickstart.sh" --execute qsT-shell.html 2>&1)"; rc=$?
[[ $rc -eq 0 && ! -e "$TMP/should-not-exist" ]] \
  || { echo "FAIL shell substitution was executed"; exit 1; }
echo "ok   run-quickstart self-test"
