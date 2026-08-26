# I.1 — how long a seeded static entry actually lives

Verified against `eez-core-protocol` @ `9735f53`, run locally with Foundry. Five
tests added to `test/EEZStaticLookup.t.sol`; all pass alongside the nine that
were already there.

## Why this matters to the card

I.1 wants deployed contracts and one copy-pasteable command that returns a
cross-chain value. The plan gates it on a composer:

> a cross-chain read only resolves if the current block's batch carries a
> matching static entry. So the playground needs a composer running against
> Chiado, or the read reverts. **Decide this before scoping.**

and lists that as the card's one real unknown. Both halves of that are wrong,
and the second one is wrong in the opposite direction from what you would guess.

## What the code does

Top-level `staticCrossChainCall` (`EEZ.sol:1266`) carries **no block gate**,
unlike `executeCrossChainCall` (`:794`) and `executeL2Txs` (`:824`). It scans
`verificationByRollup[destRid].staticEntryQueue` and matches on `proxyEntryHash`
+ `destinationRollupId` + `_stateRootsMatch`. Upstream's own comment at `:1308`:

> Note that static calls do not obsolete after a block passes. As long as the
> state roots matches it can be execute

Confirmed: `test_StaticLookup_ResolvesInLaterBlocks` reads the same entry back at
+1 and +100 blocks. **No composer is required.**

## The correction — a second expiry condition, and it is the binding one

An earlier pass here recorded state-root staleness as *the* expiry condition.
That was incomplete. `_markVerifiedBlockAndDeletePreviousEntries`
(`EEZ.sol:745`) deletes `entryQueue` **and** `staticEntryQueue` on *every* verify
of that rollup:

```solidity
rec.lastVerifiedBlock = uint64(block.number);
delete rec.entryQueue;
delete rec.staticEntryQueue;
```

So there are two, and they are independent:

| # | Condition | Test |
|---|---|---|
| 1 | A pinned state root moves | `test_StaticLookup_StaleStateRootStopsResolving` |
| 2 | **Any later batch verifies that rollup** — roots untouched or not | `test_StaticLookup_LaterBatchWipesTheQueue` |

Condition 2 asserts the roots are unchanged before re-reading, so the two cannot
be confused. It is also the one that decides how a playground is operated, and
it inverts the plan's model: **a composer posting every block destroys the seeded
entry each time** unless it deliberately re-posts that exact entry. A paused
rollup preserves it indefinitely.

The playground wants nothing running. Not something running.

## The command in the card does not work

```
cast call <proxyAddress> "balanceOf(address)(uint256)" <user> --rpc-url <chiado>
```

`cast call` is an eth_call, which the EVM executes as a **non-static** frame.
`CrossChainProxy._fallback` detects static context by self-calling `staticCheck()`
and seeing whether a `tstore` reverts (`CrossChainProxy.sol:95-107`). Under
eth_call the tstore succeeds, so it routes to `executeCrossChainCall` — the
block-gated mutating path — and reverts `ExecutionNotInCurrentBlock(rid)`.

A Solidity `view` call compiles to a real STATICCALL, so routing the read through
a `view` function fixes it. `snippets/i1-cross-chain-reader.sol` is that contract.

`test_StaticLookup_ReadHelperWorksWhereADirectCallDoesNot` asserts both halves
against the same state, 50 blocks after the entry was posted with nothing
running: the helper returns `123`, the direct call reverts
`ExecutionNotInCurrentBlock`.

## What I.1 therefore needs

1. Deploy the protocol to public Chiado L1 — `ro2`'s five steps. There is no
   shared public EEZ deployment; `ro3` documents self-hosting with an embedded
   L1, so these addresses have to be created.
2. Deploy the five demo contracts plus `CrossChainReader`.
3. Run the L2 far enough to produce the state, post **one** batch carrying the
   `StaticExecutionEntry`.
4. Stop, and post nothing further for that rollup.
5. Publish the addresses, the command, and the deploy commit.

After step 4 the stack can be switched off entirely. The L1 contracts and the
queued entry are persistent storage on public Chiado, so the read resolves for
anyone, indefinitely, with zero infrastructure running.

## The honest constraint the page must state

The value is real and proven, and the state behind it is frozen. The draft page
says so in step 3 rather than burying it, because a visitor who believes they are
reading a live chain has been misled. Stating it also teaches the actual design
— validate-at-consumption — which is a better outcome than the caveat the plan
wanted to print.

## Status

`snippets/i1-cross-chain-reader.sol` is final and compiles.
`docs/drafts/q10-read-a-live-cross-chain-value.html` is complete except the
address table, which carries `TBD · not yet deployed` placeholders rather than
plausible-looking fake addresses. It is deliberately **not** in
`dapp-developers/`, not in `index.html` and not in `llms.txt`: wiring it in is a
`git mv` plus a `SNIPPET_MAP` entry, an index card and an
`EXPECTED_WALKTHROUGHS` bump, and should happen in the commit that fills in real
addresses — not before.

The five tests live in a local clone and are not upstream. Worth offering: the
queue-wipe behaviour is a documented design decision with no test asserting it,
and it is the kind of thing an integrator will otherwise learn from an outage.
