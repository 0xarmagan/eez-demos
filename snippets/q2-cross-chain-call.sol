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
//
// A read is the same code with one difference that matters: STATICCALL
// instead of CALL. That is what the proxy's probe detects, and it is what
// decides whether the manager resolves an ExecutionEntry or a
// StaticExecutionEntry. See `settleIfFunded` below.

interface IRemote {
    function setValue(uint256 v) external;
    function balanceOf(address account) external view returns (uint256);
}

/// @dev A cross-chain call fails for reasons an ordinary same-chain call
///      cannot, and the proxy forwards raw revert data either way
///      (CrossChainProxy.sol:109-113). So `ok == false` tells you the call
///      did not happen — never why. No matching entry in this block and a
///      genuine revert in the destination contract are indistinguishable
///      here; see docs/CAVEATS.md "Indistinguishable revert reasons".
error CrossChainCallFailed();

/// @dev Raised on a value that came back from another rollup. The point of the
///      mechanism is not that the call succeeded — it is that the answer
///      decides what the rest of this transaction does.
error InsufficientRemoteBalance(uint256 have, uint256 need);

/// @dev Caller side — this is all a dapp has to do.
contract Caller {
    address public proxyAddress;

    mapping(address account => uint256 amount) public credited;
    mapping(address account => uint256 amount) public shortfall;

    constructor(address proxyAddress_) {
        proxyAddress = proxyAddress_;
    }

    /// @dev The write path. Nothing comes back worth reading, so `ok` is the
    ///      whole result and the call is an ordinary CALL.
    function send() external {
bytes memory data = abi.encodeCall(
    IRemote.setValue, (42)
);

(bool ok, ) = proxyAddress.call(data);
if (!ok) revert CrossChainCallFailed();
    }

    /// @dev The read path — a value from another rollup deciding a branch here.
    ///
    ///      The one thing to get right: the proxy picks static-vs-mutable from
    ///      the CALLER'S frame, not from `view`. Its probe does a `tstore`, and
    ///      a `tstore` only halts under STATICCALL (CrossChainProxy.sol:71). A
    ///      plain `.call(data)` here would therefore take the mutable path and
    ///      demand an ExecutionEntry no composer wrote for a read — on L2 that
    ///      is `EntryNotFound(hash, callGas)` (EEZL2.sol:441). STATICCALL is
    ///      what routes it to `staticCrossChainCall` (EEZL2.sol:594) and a
    ///      `StaticExecutionEntry`.
    function settleIfFunded(address user, uint256 need) external returns (bool) {
bytes memory data = abi.encodeCall(
    IRemote.balanceOf, (user)
);

// STATICCALL, not CALL: the proxy keys off this
// frame, not off `view`.
(bool ok, bytes memory ret) =
    proxyAddress.staticcall(data);
if (!ok) revert CrossChainCallFailed();

// The proxy returns the destination call's raw
// return data, so decode it exactly as you would
// a same-chain read — then branch on the value.
uint256 have = abi.decode(ret, (uint256));
if (have < need) {
    shortfall[user] = need - have;
    return false;
}
credited[user] += need;
return true;
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
        (success, result) = EEZ.staticcall(
            abi.encodeCall(
            IEEZ.staticCrossChainCall,
            (msg.sender, msg.data)));
    } else {
        (success, result) = EEZ.call{value: msg.value}(
            abi.encodeCall(
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
