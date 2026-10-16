# Three Gotchas Before You Build

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

Three things behave differently from a same-chain call: a test that never leaves one chain hides all three. Cross-chain, two of them revert, and the third matters once an L2 turns on USE_GAS_LEFT.

- Page: https://eez-demos.vercel.app/dapp-developers/qs5-three-gotchas-before-you-build.html
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
  // decodes destination, callGas, data
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

### Step 3 — ON L2, GAS CAN BE PART OF THE CALL.

If an L2 deploys its manager with USE_GAS_LEFT on (the intended production mode, off in every current deployment), the gas left when the manager hashes the call goes into the hash. That is why call sites attach a fixed amount.

```solidity
// paraphrasing CounterContracts.sol:4-6:
/// L2 folds the gas left after its pre-hash
/// checks into the outgoing call hash, so these
/// sites attach a fixed amount
uint256 constant PROXY_CALL_GAS = 5_000_000;

function incrementProxy() external {
  // :63 attaches it: targetCounter =
  //   target.increment{gas: PROXY_CALL_GAS}();
  ⋯

// With EEZL2's USE_GAS_LEFT on (intended for
// production, off in every current deployment),
// callGas = the L2 manager's gasleft() after its
// proxy checks and value transfer (EEZL2.sol:282),
// not the gas you forward. L1 uses ZERO_CALL_GAS.
```

## Next

[Cross-Chain Flash Loan](qs7-cross-chain-flash-loan.md)

---

Whole site for agents: https://eez-demos.vercel.app/llms.txt
