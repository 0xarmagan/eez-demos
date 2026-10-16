# One Call, Two Rollups, One Transaction

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

Your L1 contract gets an L2 contract's return value back in the same transaction, with no bridge message and no callback.

- Page: https://eez-demos.vercel.app/dapp-developers/qs0-one-call-two-rollups.html
- Source: `eez-core-protocol/src/base/CrossChainProxy.sol:113 · _fallback`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/src/base/CrossChainProxy.sol#L113

### Step 1 — YOUR CONTRACT CALLS A PROXY.

Your contract calls the proxy for Counter@L2 like any other contract. The proxy has no functions of its own, so its fallback hands your calldata and your contract's address to the EEZ manager.

```solidity
fallback() external payable {
    // ⋯ manager + self-probe branches
    _fallback();
}

function _fallback() internal {
    // ⋯ static-context probe
    (success, result) =
        // EEZ.call → executeCrossChainCall(
        //     msg.sender, msg.data)
    if (success) {
        result = abi.decode(result, (bytes));
    }
    // ⋯ return(result) to your contract
}
```

### Step 2 — THE ANSWER IS ALREADY THERE.

The composer lands its postAndVerifyBatch and your transaction as one bundle, batch first, so the batch is verified and its entries queued before your call runs. executeCrossChainCall works only in that block: it hashes your call and takes the first queued entry, from the cursor on, whose hash, destination rollup and expected starting roots all match.

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

The manager applies the entry, checks its roots and rolling hash against what the batch committed to, and returns its returnData. The proxy passes those bytes back, so your contract's next line already has Counter@L2's result. No callback, and no second transaction from you.

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

Whole site for agents: https://eez-demos.vercel.app/llms.txt
