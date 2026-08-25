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
    uint256 internal constant STATIC_CHECK_GAS = 5000;

    constructor(address eez_) {
        EEZ = eez_;
    }

    /// @dev tstore reverts in a STATICCALL context, tload does not. A self-call
    ///      isolates the tstore so the revert can be caught instead of bubbling.
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
        (success, result) = EEZ.staticcall(
            abi.encodeCall(IEEZ.staticCrossChainCall,
                (msg.sender, msg.data)));
    } else {
        (success, result) = EEZ.call{value: msg.value}(
            abi.encodeCall(IEEZ.executeCrossChainCall,
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
