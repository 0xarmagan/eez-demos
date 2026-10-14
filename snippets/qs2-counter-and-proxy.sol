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
