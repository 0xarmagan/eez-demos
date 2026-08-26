// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// The read helper the Chiado playground needs (card I.1).
// Mirrors eez-core-protocol/src/base/CrossChainProxy.sol:95 and :107
// and eez-core-protocol/src/EEZ.sol:1266
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// WHY THIS CONTRACT EXISTS. The obvious playground command does not work:
//
//   cast call <proxy> "balanceOf(address)(uint256)" <user> --rpc-url <chiado>
//
// `cast call` is an eth_call, and the EVM runs an eth_call as a NON-static
// frame. CrossChainProxy detects static context by self-calling `staticCheck()`
// and seeing whether a `tstore` reverts (CrossChainProxy.sol:95-107). Under
// eth_call that tstore SUCCEEDS, so `_fallback` concludes it is in a normal
// context and routes to `executeCrossChainCall` — the MUTATING path, which is
// block-gated at EEZ.sol:794 and reverts `ExecutionNotInCurrentBlock(rid)`
// unless a batch verified this rollup in the very block you are calling.
//
// Reaching `staticCrossChainCall` needs a real STATICCALL. Solidity compiles a
// high-level call to an external `view` function into exactly that, so routing
// the read through a `view` function on any contract is enough. That is the
// whole trick, and it is the difference between a command that reverts and a
// command that returns.
//
// Verified against the real contracts, not reasoned about:
// test_StaticLookup_ReadHelperWorksWhereADirectCallDoesNot asserts both halves
// in one test — the helper read returns its value 50 blocks after the entry was
// posted with nothing running, and the direct call against that same state
// reverts ExecutionNotInCurrentBlock.
//
// WHEN THE READ RESOLVES, AND THE TWO WAYS IT STOPS. Top-level
// `staticCrossChainCall` (EEZ.sol:1266) has no block gate: it scans
// `verificationByRollup[destRid].staticEntryQueue` and matches on
// `proxyEntryHash`, `destinationRollupId` and `_stateRootsMatch`. Upstream's own
// comment at EEZ.sol:1308 — "Note that static calls do not obsolete after a
// block passes." A queued entry therefore serves reads indefinitely, subject to
// two conditions that both have tests:
//
//   1. Every pinned state root must still be live.
//      (test_StaticLookup_StaleStateRootStopsResolving)
//   2. No later batch may verify that rollup. `_markVerifiedBlockAndDelete-
//      PreviousEntries` (EEZ.sol:745) deletes entryQueue AND staticEntryQueue on
//      EVERY verify, roots untouched or not.
//      (test_StaticLookup_LaterBatchWipesTheQueue)
//
// Condition 2 is the one that decides how a playground is operated, and it runs
// opposite to intuition: a composer posting every block DESTROYS the seeded
// entry each time unless it deliberately re-posts it. A paused rollup preserves
// it. The playground wants nothing running, not something running.
//
// A read with no matching entry reverts `ExecutionNotFound()` — and that is
// indistinguishable from the destination itself reverting (docs/CAVEATS.md,
// "Indistinguishable revert reasons when calling a proxy"). Do not write a
// try/catch that claims to tell them apart. See q8.

/// @title CrossChainReader
/// @notice Routes a read through a CrossChainProxy as a real STATICCALL, so it
///         resolves against a pre-computed static entry instead of hitting the
///         block-gated mutating path.
/// @dev Deliberately generic: one deployment serves every read on the
///      playground. It holds no state and has no owner.
contract CrossChainReader {
    /// @notice Raw read. `proxy` is the CrossChainProxy standing for the remote
    ///         contract; `data` is the calldata you would send it directly.
    /// @return The pre-computed return data of the matching static entry.
    function read(address proxy, bytes calldata data)
        external
        view
        returns (bytes memory)
    {
// `view` => the compiler emits STATICCALL, which is what the
// proxy's tstore probe detects. A plain .call() here would
// route to the mutating path and defeat the whole contract.
(bool ok, bytes memory ret) = proxy.staticcall(data);
if (!ok) {
    // Forward the raw revert. It may be ExecutionNotFound()
    // or the destination's own revert - you cannot tell.
    assembly {
        revert(add(ret, 0x20), mload(ret))
    }
}
return ret;
    }

    /// @notice Convenience for the common case of a single uint256 return.
    function readUint(address proxy, bytes calldata data)
        external
        view
        returns (uint256)
    {
        return abi.decode(this.read(proxy, data), (uint256));
    }
}
