# I.3 — what the protocol actually does when the table lies

Verified against `eez-core-protocol` @ `9735f53` (the pin, and still `origin/main`
HEAD at the time of writing), run locally with Foundry. No devnet involved — the
card was marked "needs devnet: Yes" and does not.

## What the plan asked for

> Deliberately forge a rolling hash and show `RollingHashMismatch` fire. Post an
> entry with a stale root and show `StateRootMismatch`.

Both behaviours are real. One of them had no test.

## Coverage at the pin, before this

| Scenario | Error | Upstream test |
|---|---|---|
| Forged `rollingHash` | `RollingHashMismatch` | `EEZ.t.sol:836 test_RollingHashMismatch_Reverts`, plus `test_UnconsumedCalls_Reverts` and an `EEZL2.t.sol` mirror |
| Stale root, immediate L2Tx entry | swallowed → `L2TxSkipped` | `EEZ.t.sol:277 test_PostBatch_StateRootMismatch_ImmediateSkipped` |
| **Stale root, consumed through a proxy** | **`StateRootMismatch(rollupId)`** | **none** |

`grep -rn StateRootMismatch test/` returns three hits at the pin: one is
`ExpectedStateRootMismatch` (a different error, thrown at post time,
`EEZ.sol:367`), one is the immediate-path test above, and one is a comment. The
revert at `EEZ.sol:1069` reaching a caller had nothing asserting it.

## Tests added (local, not upstream)

Both in `test/EEZ.t.sol`, both passing:

```
[PASS] test_StateRootMismatch_RevertsThroughProxy()  (gas: 1313768)
[PASS] test_StateRootMismatch_PreemptsRollingHash()  (gas: 1338797)
```

Run alongside the existing ones:

```
[PASS] test_PostBatch_StateRootMismatch_ImmediateSkipped()  (gas:  794982)
[PASS] test_RollingHashMismatch_Reverts()                   (gas: 1681767)
[PASS] test_UnconsumedCalls_Reverts()                       (gas: 1814008)
[PASS] test_RollingHashMismatch_Reverts()  [EEZL2]          (gas:  900043)
```

## What they establish

**1. Posting is not validation.** The entry with the stale root posts
successfully. `_postBatchOne` accepts it; the `currentState` precondition is
checked at consumption (`EEZ.sol:1069`), not at publication. This is
validate-at-consumption working as designed — it is what allows alternative
entries to be stacked speculatively — and it means "the batch was accepted" is
not a statement about any particular call in it.

**2. The two gates run at opposite ends of execution.** `_executeEntry`
(`EEZ.sol:1055`) checks every `StateUpdate.currentState` against the live root
*before* `_processNCalls`, and compares the rolling hash *after* it. So an entry
that is wrong both ways reports `StateRootMismatch`, and
`test_StateRootMismatch_PreemptsRollingHash` asserts the stronger form of that:
the target's value is still 0 afterwards. Nothing ran.

The corollary for the forged-hash case is the interesting one for content: there
the calls *did* all run, and then the whole entry unwound.

**3. The same cause has two observables.** A stale root reaching a caller through
a proxy is a revert. The same stale root on an immediate L2Tx entry is swallowed
— each runs inside `try this._attemptExecuteImmediateL2Txs(...)` (`EEZ.sol:403`)
so one bad entry rolls back alone and the loop continues, emitting
`L2TxSkipped(i, revertData)` (`EEZ.sol:406`) while the batch as a whole succeeds.

A monitor that watches only for reverts will report a clean batch on a batch that
dropped an entry. That is the operationally useful half of this card, and the
plan did not anticipate it.

## Status of the added tests

They pass against the real contract and are the basis for the page's claims, but
they live in a local clone and are **not upstream**. Treat the consumption-time
`StateRootMismatch` assertion as verified-by-us. Worth offering upstream: it is a
genuine coverage gap on a reachable revert, and the `PreemptsRollingHash` case
pins an ordering guarantee that nothing else asserts.
