// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEEZ} from "./lib/IEEZ.sol";

// Panel source for: dapp-developers/q3-fix-the-msg-sender-gotcha.html
// Mirrors eez-core-protocol/src/base/CrossChainProxy.sol:39
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// Cross-chain, the destination never sees your EOA. It sees the proxy the
// manager forwards through. So an owner check that passes on the same chain
// reverts every time it is reached cross-chain.
//
// WHY WHITELISTING THE PROXY IS SAFE, and not just a way to silence the revert:
// the proxy address is CREATE2-derived from exactly (owner, originRollupId)
// and the manager's own address, so one owner on one rollup maps to one
// address and nothing else can occupy it. Only the manager can forward
// through that proxy. Authorizing it therefore authorizes that one owner on
// that one rollup — not "anyone who can reach the manager".

contract OwnerGated {
    IEEZ internal immutable eez;
    address internal immutable owner;
    uint64 internal immutable originRollupId;

    constructor(IEEZ eez_, address owner_, uint64 originRollupId_) {
        eez = eez_;
        owner = owner_;
        originRollupId = originRollupId_;
    }

    /// @dev The trap. Correct on one chain, unreachable across chains.
    function sameChainOnly() external view {
// same-chain owner check — reverts cross-chain:
require(msg.sender == owner);
    }

    /// @dev The fix.
    function crossChainSafe() external view {
// whitelist the proxy, not the owner:
address proxy = eez.computeCrossChainProxyAddress(
    owner, originRollupId
);

require(msg.sender == proxy);
    }
}
