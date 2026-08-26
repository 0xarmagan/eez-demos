// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEEZ} from "./lib/IEEZ.sol";

// Panel source for: dapp-developers/q8-read-a-remote-contracts-state.html
// Mirrors eez-core-protocol/src/base/CrossChainProxy.sol:89
// and eez-core-protocol/docs/CAVEATS.md, "Opcodes that differ on cross-chain
// proxies" and "Indistinguishable revert reasons when calling a proxy"
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// This is the caveat with no compiler help. q3's mistake reverts, so you find
// it the first time a call arrives through a proxy. The reads below SUCCEED and
// return a real number about the wrong contract, so they ship.
//
// WHY: a CrossChainProxy is an ordinary contract, deployed on THIS chain, with
// its own code and its own balance. An opcode that asks the EVM about an
// address answers about that local contract. Only a CALL is routed: the proxy's
// fallback (CrossChainProxy.sol:89, `_fallback`) forwards to the manager, which
// resolves an outcome that was written down before your transaction ran. So
// inspection is local, invocation is resolved.
//
// The four that answer about the proxy, per CAVEATS.md: `balance`,
// `extcodesize`, `extcodecopy`, `delegatecall`. Plus every block-state opcode
// (`number`, `blockhash`, `chainid`, `coinbase`, `gaslimit`), which describes
// the chain currently executing, not the source chain — so the same logical
// action reads differently on L1 and on L2.
//
// `delegatecall` deserves its own line: delegatecalling a proxy runs the
// PROXY's code in your storage context. It does not reach the remote contract.
//
// WHEN A ROUTED READ RESOLVES — the rule is side-specific, so do not learn one
// half of it and carry it to the other chain:
//
//   L1 has NO block gate on the read path. `staticCrossChainCall`
//   (EEZ.sol:1266-1328) falls through to
//   `verificationByRollup[destRid].staticEntryQueue` (:1309-1310) and matches on
//   `proxyEntryHash`, `destinationRollupId` and `_stateRootsMatch(...)`
//   (:1317-1319). Upstream's own comment at :1308: "Note that static calls do
//   not obsolete after a block passes. As long as the state roots matches it can
//   be execute".
//
//   L2 DOES gate it. `EEZL2.sol:634` is
//   `if (lastLoadBlock != block.number) revert ExecutionNotInCurrentBlock();`,
//   and the docstring at :588-589 gives the reason: "no pins on L2 — the block
//   gate bounds staleness".
//
//   Mutating calls are block-gated on both sides. On L1 that is EEZ.sol:794-797,
//   `revert ExecutionNotInCurrentBlock(destRid)`.
//
// A read with nothing to resolve against reverts `ExecutionNotFound()` —
// EEZ.sol:1327 and EEZL2.sol:644. That is the string to search for.
//
// AND YOU CANNOT TELL WHY IT FAILED. CAVEATS.md, "Indistinguishable revert
// reasons when calling a proxy": a caller cannot differentiate a call reverting
// because no matching entry existed from the destination call actually
// reverting. Both bubble up as a revert from the proxy, because
// CrossChainProxy.sol:109-113 forwards the raw revert data unmodified. Do not
// write a `try/catch` that claims to know which one happened.

interface IRemote {
    function balanceOf(address account) external view returns (uint256);
}

contract RemoteReader {
    IEEZ internal immutable eez;
    address internal immutable remote;
    uint64 internal immutable remoteRollupId;

    constructor(IEEZ eez_, address remote_, uint64 remoteRollupId_) {
        eez = eez_;
        remote = remote_;
        remoteRollupId = remoteRollupId_;
    }

    /// @dev The trap. Compiles, runs, returns real numbers about the proxy.
    ///      Returns are intentionally unnamed: the panel lines below declare
    ///      `bal`, `size` and `sameChain` verbatim, and named returns would
    ///      shadow them.
    function inspectionLies(uint256 remoteChainId)
        external
        view
        returns (uint256, uint256, bool)
    {
address proxy = eez.computeCrossChainProxyAddress(
    remote, remoteRollupId
);
// a contract deployed on THIS chain, with its
// own code and its own balance

uint256 bal  = proxy.balance;       // PROXY's ether
uint256 size = proxy.code.length;   // PROXY's code
bool sameChain =
    block.chainid == remoteChainId;  // THIS chain
        return (bal, size, sameChain);
    }

    /// @dev The fix. A view call through the proxy is routed, and resolves
    ///      against an entry the composer already wrote — so what comes back is
    ///      the remote contract's state, not the proxy's.
    ///
    ///      When it resolves is side-specific: on L1 a static entry stays valid
    ///      as long as the state roots still match (EEZ.sol:1308-1319), on L2 it
    ///      is gated on the current block (EEZL2.sol:634). With no matching
    ///      entry on either side, this reverts `ExecutionNotFound()` — and that
    ///      revert is indistinguishable from the destination reverting.
    function readRemoteBalance(address user) external view returns (uint256) {
address proxy = eez.computeCrossChainProxyAddress(
    remote, remoteRollupId
);

uint256 bal = IRemote(proxy).balanceOf(user);
// the proxy is an IDENTITY, not a mirror:
// ask it, don't inspect it
        return bal;
    }

    /// @dev A live proxy says nothing about the remote target. Code at the proxy
    ///      address means the manager will route through it — not that anything
    ///      answers on the other side. See q4 for reading the registry.
    function proxyExistsButProvesNothing() external view returns (bool) {
        address proxy = eez.computeCrossChainProxyAddress(remote, remoteRollupId);
        return proxy.code.length != 0;
    }
}
