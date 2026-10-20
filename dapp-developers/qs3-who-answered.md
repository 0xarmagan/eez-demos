# Who Answered?

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

Follow the call hash from its calculation to the matching entry, then read the success flag and the return data that gives your contract 1.

- Page: https://eez-demos.vercel.app/dapp-developers/qs3-who-answered.html
- Source: `eez-core-protocol/script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol:90 · _callHash`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol#L90

### Step 1 — COMPUTE THE CALL HASH.

proxyEntryHash is the hash of the cross-chain request stored in an entry. The scenario computes it with _callHash(counterL2, counterAndProxy), using the caller on L1, the target Counter on L2 and the other call inputs. It identifies the request, not the returned value.

```solidity
// Scenario: compute the entry's call hash
bytes32 proxyEntryHash = _callHash(counterL2, counterAndProxy);

// _callHash(counterL2, counterAndProxy)
return
  crossChainCallHash(
    false, counterAndProxy, MAINNET_ROLLUP_ID, counterL2, L2_ROLLUP_ID, 0, _incrementCallData()
  );

// _incrementCallData(): increment()
return abi.encodeWithSelector(Counter.increment.selector);
```

### Step 2 — MATCH THE CALL TO ITS ENTRY.

EEZ computes crossChainCallHash from the call forwarded by the proxy. _entryMatches compares it with entry.proxyEntryHash and rejects a different hash. The destination rollup and every starting root must match too. The queue scan takes the first full match or reverts with ExecutionNotFound.

```solidity
// EEZ hashes the call received from the proxy
bytes32 crossChainCallHash = computeCrossChainCallHash(
  NOT_STATIC_CALL, sourceAddress, MAINNET_ROLLUP_ID, destAddress, destRid, msg.value, ZERO_CALL_GAS, callData
);

// _entryMatches: reject a different call
if (entry.proxyEntryHash != crossChainCallHash) return false;
if (entry.destinationRollupId != destRid) return false;
// ⋯ live starting-root checks must also pass
return true;
```

### Step 3 — READ SUCCESS AND RETURN DATA.

The entry was posted before the call. Here success is true and returnData encodes 1. After validating the entry, EEZ returns those bytes through the proxy; CounterAndProxy decodes and saves 1. The call hash identifies the request; batch verification covers the result. Local tests use permissive proofs.

```solidity
// Scenario: the L1 entry already posted
entries[0] = ExecutionEntry({
  rollupUpdates: deltas,
  proxyEntryHash: proxyEntryHash,
  destinationRollupId: L2_ROLLUP_ID,
  // ⋯ calls and rollingHash
  success: true,
  returnData: abi.encode(uint256(1))
});

// EEZ: load the matched entry's result
bytes memory returnData = entry.returnData;
// ⋯ _executeEntry validates before returning
return returnData;
```

## Next

[Two Gotchas Before You Build](qs5-three-gotchas-before-you-build.md)

---

Whole site for agents: https://eez-demos.vercel.app/llms.txt
