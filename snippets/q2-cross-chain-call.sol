// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEEZ} from "./lib/IEEZ.sol";

// Panel source for: dapp-developers/q2-send-a-cross-chain-call.html
// Mirrors eez-core-protocol/src/base/CrossChainProxy.sol:39 and :89
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// Caller side is ordinary: encode a call, send it to the proxy address like
// any other contract. The proxy has no matching function, so everything
// lands in fallback() and gets forwarded to the manager.

interface IRemote {
    function setValue(uint256 v) external;
}

/// @dev Caller side — this is all a dapp has to do.
contract Caller {
    address public proxyAddress;

    function send() external {
bytes memory data = abi.encodeCall(
    IRemote.setValue, (42)
);

(bool ok, ) = proxyAddress.call(data);
        ok;
    }
}

/// @dev Proxy side — how the forward actually happens.
contract CrossChainProxySnippet {
    address internal immutable EEZ;

    /// @dev Upstream value, from CrossChainProxy.sol:23. The cap IS the cost: in a
    ///      static context the tstore is an exceptional halt, which consumes every
    ///      unit forwarded to it, so the probe must be given only what you are
    ///      willing to burn on every call. The mutable path spends ~300 of it.
    uint256 internal constant STATIC_CHECK_GAS = 1_000;

    constructor(address eez_) {
        EEZ = eez_;
    }

    /// @dev tstore reverts in a STATICCALL context, tload does not. A self-call
    ///      isolates the tstore so the revert can be caught instead of bubbling.
    ///
    ///      STAND-IN: upstream declares a named `uint256 transient _staticDetector`
    ///      (CrossChainProxy.sol:18) and writes it in staticCheck() (:71). Raw slot 0
    ///      is used here only to keep the probe to one readable line. Do not copy it:
    ///      raw slot 0 is not reserved for you, so in a real contract that also uses
    ///      transient storage this probe is a collision risk. Declare a named
    ///      `transient` variable, as upstream does, and let the compiler place it.
    function staticCheck() external {
        assembly { tstore(0, 1) }
    }

// CrossChainProxy.sol
fallback() external payable {
    _fallback();
}

function _fallback() internal {
    (bool success,) = address(this).call{
        gas: STATIC_CHECK_GAS
    }(abi.encodeCall(this.staticCheck, ()));
    bytes memory result;
    if (!success) {
        (success, result) = EEZ.staticcall(abi.encodeCall(
            IEEZ.staticCrossChainCall,
            (msg.sender, msg.data)));
    } else {
        (success, result) = EEZ.call{value: msg.value}(abi.encodeCall(
            IEEZ.executeCrossChainCall,
            (msg.sender, msg.data)));
    }
    if (success) result = abi.decode(result, (bytes));

    assembly {
        switch success
        case 0 { revert(add(result, 0x20), mload(result)) }
        default { return(add(result, 0x20), mload(result)) }
    }
}
}
