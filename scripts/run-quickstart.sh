#!/usr/bin/env bash
# Run every command a quickstart card shows, exactly as the page shows it.
# The commands come out of the page's codeByStep ($-prefixed lines), never a
# second copy, so a card cannot drift from what was actually run.
set -euo pipefail
ROOT="${QS_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
PIN=9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
EXTRACT=0; [[ "${1:-}" == "--extract-only" ]] && { EXTRACT=1; shift; }
[[ $# -ge 1 ]] || { echo "usage: $0 [--extract-only] PAGE..." >&2; exit 2; }

extract() {
  python3 - "$SCRIPTS/build-llms.py" "$ROOT/dapp-developers/$1" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("b", sys.argv[1]); b = importlib.util.module_from_spec(spec); spec.loader.exec_module(b)
for step in b.steps_of(open(sys.argv[2], encoding="utf-8").read(), sys.argv[2]):
    for line in step:
        if line.startswith("$ "):
            print(line[2:])
PY
}

for page in "$@"; do
  cmds="$(extract "$page")"
  if grep -q "git clone .*eez-core-protocol" <<<"$cmds" && ! grep -q "git checkout -q $PIN\|git checkout $PIN" <<<"$cmds"; then
    echo "$page: clones eez-core-protocol without checking out the pin $PIN" >&2; exit 1
  fi
  if [[ $EXTRACT == 1 ]]; then printf '%s\n' "$cmds"; continue; fi
  work="$(mktemp -d)"; t0=$(date +%s)
  ( cd "$work"; set -e; while IFS= read -r c; do echo "RAN: $c"; eval "$c" </dev/null; done <<<"$cmds" )
  echo "ELAPSED $page $(( $(date +%s) - t0 ))"
done
