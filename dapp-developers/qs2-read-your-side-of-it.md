# Read Your Side of It

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

Neither contract imports anything from EEZ: your side is an ordinary Solidity call that uses its return value.

- Page: https://eez-demos.vercel.app/dapp-developers/qs2-read-your-side-of-it.html
- Source: `eez-core-protocol/test/mocks/CounterContracts.sol:16 · Counter`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/test/mocks/CounterContracts.sol#L16

### Step 1 — THE CONTRACT ON L2.

Counter is plain Solidity. In the card 01 run it lives on L2, and increment() returns the new count.

```solidity
contract Counter is ICounterView {
    uint256 public counter;

    function increment() external returns (uint256) {
        counter++;
        return counter;
    }
}
```

### Step 2 — YOUR CONTRACT ON L1.

incrementProxy() calls target.increment() like any other contract and uses the return value on the next line. The fixed gas amount is the one extra; Three Gotchas explains when it matters.

```solidity
uint256 constant PROXY_CALL_GAS = 5_000_000;

contract CounterAndProxy {
    Counter public target;
    uint256 public targetCounter;
    uint256 public counter;

    // ⋯ constructor: step 3

    function incrementProxy() external {
        targetCounter = target.increment{gas: PROXY_CALL_GAS}();
        counter++;
    }
}
```

### Step 3 — POINT IT ANYWHERE.

The only cross-chain part is which address target holds. The scenario passes Counter's proxy on L1. The TEST tab passes a local Counter, and the same code passes.

```solidity
contract CounterAndProxy {
    Counter public target;
    // ⋯

    constructor(Counter _target) {
        target = _target;
    }

    // ⋯ incrementProxy() as in step 2
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

Whole site for agents: https://eez-demos.vercel.app/llms.txt
