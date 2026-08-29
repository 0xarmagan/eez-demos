# Start here

Three things EEZ does, in the order that makes them make sense — then the one surprise worth
knowing before you build. About ten minutes.

Every step below runs code that this repo's CI already compiles and tests. Nothing here
is a sketch, and nothing here is new — the starter is a *path* through
[`../snippets/`](../snippets/), not a second copy of it. If a snippet changes, this path
changes with it.

```bash
cd starter && ./run.sh
```

Prerequisites: [Foundry](https://book.getfoundry.sh/getting-started/installation)
(`forge`). Nothing else — the snippets are deliberately dependency-free, with no
`forge-std` and no submodules, so they build on a bare checkout.

---

## 1 · Read another chain

Your contract reads state from a contract that lives somewhere else.

```bash
forge test --match-test "test_routedReadReturnsThePreCommittedEntry|test_unresolvedReadRevertsExecutionNotFound" -vv
```

Source: [`q8-remote-reads.sol`](../snippets/q8-remote-reads.sol) ·
test: [`Q8RemoteReads.t.sol`](../snippets/test/Q8RemoteReads.t.sol)

**What to notice.** The answer was written into a table *before* your transaction ran, and
is matched by a hash of the call. This is the opposite of fetch-on-demand messaging, where
the answer is retrieved while you wait. A miss doesn't return an empty value — it reverts
`ExecutionNotFound()`.

## 2 · Call another chain

Same idea, but you're moving state rather than observing it.

```bash
forge test --match-test "test_plainCallTakesTheExecutionPathAndMisses|test_staticcallTakesTheReadPath|test_missRevertsCrossChainCallFailed" -vv
```

Source: [`q2-cross-chain-call.sol`](../snippets/q2-cross-chain-call.sol) ·
test: [`Q2CrossChainCall.t.sol`](../snippets/test/Q2CrossChainCall.t.sol)

**What to notice.** The caller side is ordinary — encode a call, send it to an address.
What decides whether you get a read or a write is `STATICCALL` versus `CALL`, i.e. the
frame you're in, not whether the function is marked `view`.

## 3 · Use the answer

The value comes back and **decides what the rest of your transaction does**.

```bash
forge test --match-test "test_fundedBranchCreditsFromARemoteValue|test_shortBranchRecordsTheGapFromTheSameCall|test_theBranchTracksTheValueNotTheSuccessFlag" -vv
```

Source: `settleIfFunded` in [`q2-cross-chain-call.sol`](../snippets/q2-cross-chain-call.sol)

**This is the one worth your attention.** Read `test_theBranchTracksTheValueNotTheSuccessFlag`
— the branch turns on the *value that came back*, not on whether the call succeeded. That
is the whole point. You are not being told "the message was delivered." You are holding
the answer, inside the same transaction, in time to act on it.

If you have built cross-chain flows before, this is the moment to notice what you did
**not** have to write: no callback handler, no timeout, no retry path, no half-finished
state to reconcile later. That machinery exists to survive a gap. Here there is no gap.

---

## Why msg.sender isn't your contract on the other side

One detour before you build anything, because this is the first thing that bites and it does not announce itself.

```bash
forge test --match-test "test_sameChainCheck_revertsWhenCalledViaProxy|test_balanceReadsTheProxyNotTheCounterpart|test_blockContextIsLocal" -vv
```

Source: [`q3-msg-sender.sol`](../snippets/q3-msg-sender.sol)

**The destination sees a proxy as `msg.sender`, not your contract.** Every `onlyOwner`,
every allowlist, every `msg.sender`-keyed mapping and every ERC-20 `approve`/`transferFrom`
on the far side keys to that proxy address. Your access control will not fail loudly. It
will pass or fail for the wrong reason.

Two more in the same run: `balance` and `extcodesize` describe the *proxy*, not the contract
it stands for, and block context describes the chain you are executing on rather than the
one you are reading from. All three return real numbers about the wrong thing, and nothing
reverts.

---

## What is not here yet

**The full atomic write path** — call out, mutate state on the other side, and have the
whole thing unwind together if any part fails. Step 3 above shows the read-and-branch shape
of it, which is real and runnable today. The mutating version is not in this starter
because it is not yet reliable end to end. It will be added here when it is.

That is deliberate. A starter that ships a path which fails intermittently is worse than
one that stops short and says so.

---

## Then what

If you got this far and want to try it on something real: pick the smallest thing in your
own product that needs a value from another chain. Not a demo — your own contract, failing
in a way that surprises you, is the interesting outcome.

If you write that up, we will link the whole thing, unedited, on your channel and under
your byline. See the write-up guide for what is worth covering.

## Provenance

The snippets these steps run are pinned to a specific upstream commit and checked by
`scripts/verify-citations.py`. Interfaces upstream are still in flux — if a step here
disagrees with upstream source, upstream wins and this is a bug worth reporting.
