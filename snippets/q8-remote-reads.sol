// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEEZ} from "./lib/IEEZ.sol";

// Panel source for: dapp-developers/q8-read-a-remote-contracts-state.html
// Mirrors eez-core-protocol/src/base/CrossChainProxy.sol:113
// and eez-core-protocol/docs/CAVEATS.md, "Opcodes that differ on cross-chain
// proxies" and "Missing entries and destination reverts"
// @ 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
//
// This is the caveat with no compiler help. q3's mistake reverts, so you find
// it the first time a call arrives through a proxy. The reads below SUCCEED and
// return a real number about the wrong contract, so they ship.
//
// WHY: once created, a CrossChainProxy is an ordinary contract on THIS chain,
// with its own code and its own balance. An opcode that asks the EVM about an
// address answers about that local contract. Only a CALL is routed: the proxy's
// fallback (CrossChainProxy.sol:113, `_fallback`) forwards to the manager, which
// resolves an outcome that was written down before your transaction ran. So
// inspection is local, invocation is resolved.
//
// CAVEATS.md lists four opcodes that answer about the proxy: `balance`,
// `extcodesize`, `extcodecopy`, `delegatecall`. The first three succeed and
// return a number about the proxy. Plus every block-state opcode (`number`,
// `blockhash`, `chainid`, `coinbase`, `gaslimit`), which describes the chain
// currently executing, not the source chain — so the same logical action reads
// differently on L1 and on L2.
//
// `delegatecall` is the exception: it does not succeed. Delegatecalling a proxy
// runs the PROXY's code in your context, so its fallback forwards to the manager
// with YOUR contract as msg.sender, and the manager reverts `UnauthorizedProxy()`
// (EEZ.sol:1564, EEZL2.sol:790). It never reaches the remote contract.
//
// WHEN A ROUTED READ RESOLVES — both sides gate on the block, but what else
// must match differs, so do not learn one half and carry it to the other chain:
//
//   L1: `staticCrossChainCall` (EEZ.sol:1379-1449) opens with
//   `_validateProxyAndGetDestinationInfo()` (:1380), which reverts
//   `ExecutionNotInCurrentBlock(destRid)` unless that rollup was verified in
//   this block (:1578-1580). A top-level read then scans `staticEntryQueue`
//   (:1420), or the batch's transient pool while one is mid-flight, and matches
//   on `proxyEntryHash`, `destinationRollupId` and `_rootsMatch(...)`
//   (:1437-1438). A nested read (inside an execution) is matched by the rolling
//   hash instead (:1390-1410).
//   Upstream's own comment: "Static entries require both current-block
//   verification (checked above) and matching root pins."
//
//   L2: `staticCrossChainCall` (EEZL2.sol:660) opens with the same-named helper,
//   whose gate at EEZL2.sol:791 is
//   `if (lastLoadBlock != block.number) revert ExecutionNotInCurrentBlock();`.
//   A top-level read matches on the call hash and the live entry cursor (:705);
//   a nested read is matched by the rolling hash (:681-699).
//
//   Mutating calls go through the same helper on both sides, so they are
//   block-gated too (EEZ.sol:863, EEZL2.sol:272).
//
// A read with nothing to resolve against reverts — `ExecutionNotFound()` on L1
// (EEZ.sol:1410, :1448), `EntryNotFound(bytes32 crossChainCallHash, uint64
// callGas)` on L2 (EEZL2.sol:699, :714). Those are the strings to search for.
//
// AND REVERT DATA WON'T TELL YOU WHY IT FAILED. CAVEATS.md, "Missing entries
// and destination reverts": a static lookup miss reverts at the proxy, as does a
// matched reverting destination, and revert data alone is not a reliable way to
// distinguish them — CrossChainProxy.sol:138-139 forwards the raw revert data
// unmodified. Do not write a `try/catch` that claims to know which one happened.

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
// once created, a contract on THIS chain with
// its own code and its own balance

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
    ///      Both sides resolve it only in the block the entries were loaded: on
    ///      L1 the rollup must be verified this block and, for a top-level read,
    ///      the entry's root pins must match (EEZ.sol:1578-1580, :1437-1438); on
    ///      L2 the table must be loaded this block (EEZL2.sol:791). With no matching entry this
    ///      reverts — `ExecutionNotFound()` on L1, `EntryNotFound(...)` on L2 —
    ///      and revert data alone cannot reliably tell that from the
    ///      destination reverting.
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
