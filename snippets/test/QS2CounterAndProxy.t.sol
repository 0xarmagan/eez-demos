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
