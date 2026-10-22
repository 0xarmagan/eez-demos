# Follow One Call There and Back

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

Your contract makes an ordinary call to a proxy, the proxy hands it to the L1 manager, and the 1 that Counter returns on L2 comes back as data that was posted before your call.

- Page: https://build.eez.io/dapp-developers/qs2-read-your-side-of-it.html
- Source: `eez-core-protocol/script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol:157 · DeployL2`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol#L157

### Step 1 — SET UP ONCE.

Counter is deployed on L2 only. On L1, the scenario asks the L1 manager for Counter's proxy, then builds CounterAndProxy with that proxy as its target. Neither contract imports anything from EEZ.

```solidity
// DeployL2, broadcast on L2:
Counter counterL2 = new Counter();

// Deploy, broadcast on L1: the L1 manager
// creates Counter@L2's proxy if it is missing
address counterProxy = getOrCreateProxy(IEEZ(address(rollups)), counterL2Addr, L2_ROLLUP_ID);

// your contract gets the proxy as its target
CounterAndProxy cap = new CounterAndProxy(Counter(counterProxy));
```

### Step 2 — AN ORDINARY CALL.

incrementProxy() calls target.increment() like any other contract call. target is counterProxy, a contract on L1, so that is where the call goes. The TEST tab runs this same contract against a local Counter.

```solidity
contract CounterAndProxy {
  Counter public target;
  uint256 public targetCounter;
  uint256 public counter;

  constructor(Counter _target) {
    target = _target;
  }

  function incrementProxy() external {
    targetCounter = target.increment{gas: PROXY_CALL_GAS}();
    counter++;
  }
}
```

### Step 3 — THE PROXY HANDS IT ON.

CrossChainProxy has no increment(). Its fallback checks that this isn't a static call, then calls executeCrossChainCall on the L1 manager with who called it, CounterAndProxy, and the exact calldata, increment().

```solidity
fallback() external payable {
  // ⋯ manager and self-probe branches
  _fallback();
}
function _fallback() internal {
  // ⋯ probe: is this call a STATICCALL?
  if (!success) {
    // ⋯ read path: staticCrossChainCall
  } else {
    (success, result) =
      EEZ.call{value: msg.value}(abi.encodeCall(IEEZ.executeCrossChainCall, (msg.sender, msg.data)));
  }
  // ⋯ step 5: decode it, return it
}
```

### Step 4 — THE ANSWER WAS POSTED FIRST.

L1 never calls out to L2 mid-transaction. Counter runs on L2, from the L2 entry: it stores counter = 1 and returns 1. The L1 entry, posted before your call, already holds that 1. Locally, the scenario script plays composer and writes both.

```solidity
// on L2: Counter, run by the L2 entry's call
function increment() external returns (uint256) {
  counter++;
  return counter;
}

// on L1: the entry posted before your call,
// by the batch (E2ECounter.s.sol, _l1Entries)
entries[0] = ExecutionEntry({
  ⋯
  success: true,
  returnData: abi.encode(uint256(1))
});
```

### Step 5 — BACK IN YOUR CONTRACT.

The manager returns the entry's returnData, the proxy unwraps it and returns the bytes, and Solidity decodes the uint256 that increment() declares. targetCounter is now 1. CounterAndProxy's own counter++ is a separate write on L1.

```solidity
// EEZ, the L1 manager (_consumeAndExecuteEntry)
bytes memory returnData = entry.returnData;
// ⋯ _executeEntry checks roots + rolling hash
return returnData;
// CrossChainProxy (_fallback)
result = abi.decode(result, (bytes));
// ⋯ return(result) hands the bytes back
// CounterAndProxy: Solidity decodes the uint256
function incrementProxy() external {
  targetCounter = target.increment{gas: PROXY_CALL_GAS}();
  counter++;
}
```

### Full compilable source — snippets/qs2-counter-and-proxy.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: dapp-developers/qs2-read-your-side-of-it.html
// Mirrors eez-core-protocol/test/mocks/CounterContracts.sol:4-23 and :53-66
// @ 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
//
// These are the contracts the card 01 round trip runs. Copied verbatim: Counter
// lives on L2, CounterAndProxy on L1. Nothing in CounterAndProxy knows it is
// calling across chains. `target` just holds an address, and on the scenario
// that address is Counter's cross-chain proxy on L1.

/// @dev Explicit gas attached to the cross-chain proxy call sites below. L2 folds the gas left
///      after its pre-hash checks into the outgoing call hash, so these sites attach a fixed amount
///      that a test-side probe with the same attach reproduces (equals `BaseL2.CALL_GAS`).
uint256 constant PROXY_CALL_GAS = 5_000_000;

/// @notice View surface of `Counter`. Gives call sites a compile-checked handle on the
///         auto-generated `counter()` getter (`Counter.counter.selector` is not reachable
///         through the contract type).
interface ICounterView {
    function counter() external view returns (uint256);
}

contract Counter is ICounterView {
    uint256 public counter;

    function increment() external returns (uint256) {
        counter++;
        return counter;
    }
}

contract CounterAndProxy {
    Counter public target;
    uint256 public targetCounter;
    uint256 public counter;

    constructor(Counter _target) {
        target = _target;
    }

    function incrementProxy() external {
        targetCounter = target.increment{gas: PROXY_CALL_GAS}();
        counter++;
    }
}
```

### Runnable test — snippets/test/QS2CounterAndProxy.t.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Counter, CounterAndProxy} from "../qs2-counter-and-proxy.sol";

// The same CounterAndProxy, pointed at a same-chain Counter: the call site is
// identical whether `target` is a local contract or a cross-chain proxy.
contract QS2CounterAndProxyTest {
    function test_sameCallSiteWorksAgainstALocalCounter() public {
        Counter target = new Counter();
        CounterAndProxy cap = new CounterAndProxy(target);
        cap.incrementProxy();
        require(target.counter() == 1, "target not incremented");
        require(cap.targetCounter() == 1, "return value not used");
        require(cap.counter() == 1, "local state not updated");
    }
}
```

## Next

[Who Answered?](qs3-who-answered.md)

---

Whole site for agents: https://build.eez.io/llms.txt
