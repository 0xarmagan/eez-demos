// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEEZ} from "./lib/IEEZ.sol";

// Panel source for: dapp-developers/q2-send-a-cross-chain-call.html
// Mirrors eez-core-protocol/src/base/CrossChainProxy.sol:67 and :113
// @ 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
//
// Caller side is ordinary: encode a call, send it to the proxy address like
// any other contract. The proxy has no matching function, so everything
// lands in fallback() and, unless the caller is the manager or the proxy
// itself, gets forwarded to the manager.
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
///      cannot. `ok == false` alone does not say why. The proxy forwards the
///      raw revert data (CrossChainProxy.sol:137-141), which usually does
///      (ExecutionNotFound / EntryNotFound vs the destination's own error), but
///      a destination can emit the same selector, so don't branch on it. This
///      Caller discards it; see docs/CAVEATS.md "Missing entries and
///      destination reverts".
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
    ///      a `tstore` only halts under STATICCALL (CrossChainProxy.sol:89). A
    ///      plain `.call(data)` here would take the mutable path; the composer
    ///      would then build an ExecutionEntry for it, hashed with
    ///      `isStatic = false`, instead of a static one. STATICCALL routes it to
    ///      `staticCrossChainCall` (EEZL2.sol:660) and a static entry, which is
    ///      read-only: it cannot change state on either side.
    function settleIfFunded(address user, uint256 need) external returns (bool) {
bytes memory data = abi.encodeCall(
    IRemote.balanceOf, (user)
);

// STATICCALL for a read: the proxy keys off this
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

/// @dev The manager-only forwarding ABI the proxy dispatches by selector.
///      Copied from eez-core-protocol/src/interfaces/ICrossChainProxy.sol:13.
interface ICrossChainProxy {
    function executeOnBehalf(address destination, uint64 callGas, bytes calldata data) external payable;
}

/// @dev Proxy side — how the forward actually happens. Upstream has no
///      `staticCheck()` function and no hardcoded gas cap any more: both the
///      manager's `executeOnBehalf` and the self-probe are served by selector
///      inside fallback(), and the probe's cap is read from the manager
///      (EEZBase.sol:65) so an upgraded manager can retune it without
///      redeploying a single proxy.
contract CrossChainProxySnippet {
    address internal immutable EEZ;

    /// @dev Upstream's detector variable (CrossChainProxy.sol:30). Writing it
    ///      is a TSTORE, which halts in a static context.
    uint256 transient _staticDetector;

    bytes4 private constant STATIC_CHECK_SELECTOR = bytes4(keccak256("staticCheck()"));

    /// @dev The deploying manager is the only caller that can forward through
    ///      this proxy. Upstream takes no constructor argument for it.
    constructor() {
        EEZ = msg.sender;
    }

// CrossChainProxy.sol
fallback() external payable {
    if (msg.sender == EEZ && msg.sig == ICrossChainProxy.executeOnBehalf.selector) {
        (address destination, uint64 callGas, bytes memory data) =
            abi.decode(msg.data[4:], (address, uint64, bytes));
        (bool ok, bytes memory ret) = callGas == 0
            ? destination.call{value: msg.value}(data)
            : destination.call{value: msg.value, gas: callGas}(data);
        assembly {
            switch ok
            case 0 { revert(add(ret, 0x20), mload(ret)) }
            default { return(add(ret, 0x20), mload(ret)) }
        }
    }
    if (msg.sender == address(this) && msg.sig == STATIC_CHECK_SELECTOR) {
        _staticDetector = 0;
        return;
    }
    _fallback();
}

function _fallback() internal {
    uint256 staticCheckGas = IEEZ(EEZ).STATIC_CHECK_GAS();
    (bool success,) = address(this).call{gas: staticCheckGas}(
        abi.encodeWithSelector(STATIC_CHECK_SELECTOR));
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
