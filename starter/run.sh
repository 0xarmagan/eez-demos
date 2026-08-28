#!/usr/bin/env bash
# Walk the three EEZ functions in order, then the surprise that bites first.
#
# Runs tests that live in ../snippets — this script owns no Solidity of its own,
# so it cannot drift from what CI checks.
set -uo pipefail

SNIPPETS="$(cd "$(dirname "${BASH_SOURCE[0]}")/../snippets" && pwd)"

if ! command -v forge >/dev/null 2>&1; then
  cat >&2 <<'MSG'
forge not found.

Install Foundry, then re-run:
  curl -L https://foundry.paradigm.xyz | bash && foundryup

Nothing else is needed — the snippets have no forge-std and no submodules.
MSG
  exit 127
fi

cd "$SNIPPETS"

pass=0
fail=0

step() {
  local n="$1" title="$2" note="$3" pattern="$4"
  printf '\n\033[1m%s · %s\033[0m\n%s\n' "$n" "$title" "$note"
  if forge test --match-test "$pattern" "${VERBOSITY:--vv}" >/tmp/eez-starter-$$.log 2>&1; then
    printf '   \033[32mpass\033[0m\n'
    pass=$((pass + 1))
  else
    printf '   \033[31mfail\033[0m — output below\n'
    sed 's/^/   /' /tmp/eez-starter-$$.log
    fail=$((fail + 1))
  fi
  rm -f /tmp/eez-starter-$$.log
}

printf '\033[1mEEZ starter\033[0m — three functions, then the one surprise.\n'
printf 'Running against %s\n' "$SNIPPETS"

step 1 "Read another chain" \
  "   The answer was written into a table before your transaction ran." \
  "test_routedReadReturnsThePreCommittedEntry|test_unresolvedReadRevertsExecutionNotFound"

step 2 "Call another chain" \
  "   STATICCALL vs CALL decides read or write — not the view modifier." \
  "test_plainCallTakesTheExecutionPathAndMisses|test_staticcallTakesTheReadPath|test_missRevertsCrossChainCallFailed"

step 3 "Use the answer" \
  "   The branch turns on the value that came back, not on success. This is the one." \
  "test_fundedBranchCreditsFromARemoteValue|test_shortBranchRecordsTheGapFromTheSameCall|test_theBranchTracksTheValueNotTheSuccessFlag"

step "!" "Why msg.sender isn't your contract" \
  "   Three real numbers about the wrong thing. Nothing reverts." \
  "test_sameChainCheck_revertsWhenCalledViaProxy|test_balanceReadsTheProxyNotTheCounterpart|test_blockContextIsLocal"

printf '\n\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"

if [ "$fail" -eq 0 ]; then
  cat <<'MSG'

Next: pick the smallest thing in your own product that needs a value from
another chain. Your own contract failing in a surprising way is the
interesting outcome — see ../starter/README.md, "Then what".
MSG
fi

exit $((fail > 0 ? 1 : 0))
