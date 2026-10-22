# Two Gotchas Before You Build

> Every code block is cited at a pinned commit; interfaces may move after it.

Two cross-chain gotchas to check before you build: msg.sender is the source's proxy, and a state-changing proxy call needs an entry verified in the same block.

- Page: https://build.eez.io/dapp-developers/qs5-three-gotchas-before-you-build.html
- Source: `eez-core-protocol/src/base/CrossChainProxy.sol:67 · fallback`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/src/base/CrossChainProxy.sol#L67

### Step 1 — MSG.SENDER IS THE PROXY.

Cross-chain, your contract is called by the source's proxy, not the source. Check msg.sender against the proxy address, or an owner check reverts every time.

```solidity
// CrossChainProxy.sol · fallback()
// The manager (EEZ on L1, EEZL2 on L2) has
// the source's proxy make your call:
fallback() external payable {
  // sender is EEZ, sig is executeOnBehalf
  // decodes the destination and call data
  ⋯
  ? destination.call{value: msg.value}(data)
  ⋯

// The proxy is the caller. In your contract,
// msg.sender == proxy(source), not source.
```

### Step 2 — AN ENTRY COUNTS ONLY IN ITS BLOCK.

Every proxy call checks that its rollup was verified in the current block. An entry posted in block N is dead in block N+1, and the call reverts with ExecutionNotInCurrentBlock.

```solidity
// EEZ.sol · every proxy call on L1 goes
// through _validateProxyAndGetDestinationInfo:
_requireVerifiedThisBlock(destRid);

// _requireVerifiedThisBlock (:1578): unless
// lastVerifiedBlock == block.number, :1580
revert ExecutionNotInCurrentBlock(rollupId);

// postAndVerifyBatch reaches
// _markVerifiedBlockAndResetQueues (:804),
// which sets lastVerifiedBlock to this block
// (:806). Next block, the same entry is out
// of reach.
// L2: lastLoadBlock != block.number reverts
// too (EEZL2.sol:791).
```

## Next

[Cross-Chain Flash Loan](qs7-cross-chain-flash-loan.md)

---

Whole site for agents: https://build.eez.io/llms.txt
