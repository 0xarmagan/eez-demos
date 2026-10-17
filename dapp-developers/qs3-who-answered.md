# Who Answered?

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

The L1 call never waited for L2: its answer was already in an entry, and locally you can read the entry the scenario script wrote as composer.

- Page: https://eez-demos.vercel.app/dapp-developers/qs3-who-answered.html
- Source: `eez-core-protocol/script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol:94 · ExecutionEntry`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol#L94

### Step 1 — THE ANSWER, WRITTEN DOWN FIRST.

Before your call runs, the L1 entry already holds its answer: success, and a return value of 1. On a real network the composer builds this entry. Locally, the scenario script plays composer.

```solidity
// _l1Entries: the entry posted on L1
entries[0] = ExecutionEntry({
  rollupUpdates: deltas,
  proxyEntryHash: proxyEntryHash,
  destinationRollupId: L2_ROLLUP_ID,
  ⋯
  success: true,
  returnData: abi.encode(uint256(1))
});
```

### Step 2 — THE REAL CALL, ON L2.

The L2 entry holds the call that really runs: CounterAndProxy on L1 calling increment() on Counter on L2. Locally, the script delivers it too, as the L2 system address.

```solidity
// _l2Entries: the entry loaded on L2
calls[0] = CrossChainCall({
  ⋯
  sourceAddress: counterAndProxy,
  sourceRollupId: MAINNET_ROLLUP_ID,
  targetAddress: counterL2,
  value: 0,
  data: _incrementCallData()
});
⋯
entries[0] = L2ExecutionEntry({
  ⋯
  incomingCalls: calls,
  ⋯
});
```

### Step 3 — ONE HASH, ONE CALL.

Both entries carry the same proxyEntryHash, built by one helper, _callHash. That shared hash says both entries are the same call, and L2 checks it against the call it actually runs. It does not tie the answers: rollup 1's proof systems attest that when they verify the batch. Locally the proof system accepts anything, and the script writes 1 on both sides.

```solidity
// Both entries set the same field
// from one helper:
// _callHash(counterL2, counterAndProxy)
// _l1Entries
entries[0] = ExecutionEntry({
  ⋯
  proxyEntryHash: proxyEntryHash,
  ⋯
});
// _l2Entries
entries[0] = L2ExecutionEntry({
  proxyEntryHash: proxyEntryHash,
  ⋯
});
```

## Next

[Three Gotchas Before You Build](qs5-three-gotchas-before-you-build.md)

---

Whole site for agents: https://eez-demos.vercel.app/llms.txt
