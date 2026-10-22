# One Call, Two Chains, One Transaction

> Every code block is cited at a pinned commit; interfaces may move after it.

Your L1 contract gets an L2 contract's return value back in the same transaction, with no bridge message and no callback.

- Page: https://build.eez.io/dapp-developers/qs0-one-call-two-rollups.html
- Source: `eez-core-protocol/src/base/CrossChainProxy.sol:113 · _fallback`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/src/base/CrossChainProxy.sol#L113

### Step 1 — YOUR CONTRACT CALLS A PROXY.

CounterAndProxy is your L1 caller contract. You call incrementProxy(); it calls increment() on Counter's L1 proxy and saves the returned value in targetCounter. The proxy's fallback passes the call to the EEZ manager.

```solidity
fallback() external payable {
    // ⋯ manager + self-probe branches
    _fallback();
}
function _fallback() internal {
    // ⋯ static probe; normal call path:
    // Call the EEZ manager
    (success, result) =
        EEZ.call{value: msg.value}(abi.encodeCall(IEEZ.executeCrossChainCall, (msg.sender, msg.data)));
    if (success) {
        result = abi.decode(result, (bytes));
    }
    // ⋯ return(result) to your contract
}
```

### Step 2 — THE ANSWER IS ALREADY THERE.

The composer — the service that orders cross-chain calls and posts their proofs — gets its batch and your transaction into one block as one bundle, batch first. The batch is verified and its entries (one record per call) are queued before your call runs. executeCrossChainCall works only in that block: it hashes your call and takes the first queued entry whose hash, destination rollup and expected starting roots (each chain's state before the call) all match.

```solidity
// tx 1, composer: postAndVerifyBatch
// ⋯ step 4, _markVerifiedBlockAndResetQueues:
rec.lastVerifiedBlock = uint64(block.number);
// ⋯ step 8, back in postAndVerifyBatch:
_saveRemainderEntries(batch);
// tx 2, you: the proxy calls
function executeCrossChainCall(
    address sourceAddress,
    bytes calldata callData
// ⋯ ), then _validateProxyAndGetDestinationInfo:
    _requireVerifiedThisBlock(destRid);
    // ⋯ then _consumeAndExecuteEntry() scans:
    idx = _findMatchingEntry(
        // ⋯ queue, cursor, call hash, rollup
    );
    entry = rec.entryQueue[idx];
```

### Step 3 — SAME TRANSACTION.

The manager applies the entry, checks its roots and rolling hash against what the batch committed to, and returns its returnData. The proxy passes those bytes back, so your contract's next line already has the result from Counter on L2. No callback, and no second transaction from you.

```solidity
// _consumeAndExecuteEntry, entry found
bytes memory returnData = entry.returnData;

_executeEntry(
    // ⋯ roots, calls, rollingHash
);
// reverts RollingHashMismatch on divergence

return returnData;

// ⋯ executeCrossChainCall returns it,
// the proxy decodes it and return()s it:
// your contract has the answer.
```

## Next

[Run Your First Round Trip](qs1-run-your-first-round-trip.md)

---

Whole site for agents: https://build.eez.io/llms.txt
