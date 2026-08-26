// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: protocol-researchers/pr7-what-the-refactor-renamed.html
// Mirrors eez-core-protocol/src/interfaces/IEEZ.sol:20, :75, :83, :114 and :126
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// Every declaration below is copied verbatim from upstream, which is the point
// of the file: this page's whole claim is "these are the current names", and a
// claim like that has to be enforced by something other than the day it was
// written. check-snippet-fidelity.py asserts each declaration against upstream
// at the pin, so the day a name moves again, this page fails the build instead
// of quietly becoming the thing it warns about.
//
// WHAT MOVED. The `feature/simplify` refactor (PR #34, merged as 9735f53)
// renamed most of the execution-table vocabulary. The old names still appear
// in the repo's own CLAUDE.md, which predates the refactor and was never
// updated — so a reader who started there builds a stale mental model, not
// just a stale glossary.
//
//   StateDelta                → StateUpdate
//   LookupCall                → StaticExecutionEntry
//   ExpectedLookup            → (merged into the unified ExpectedL1ToL2Call table)
//   revertSpan                → revertNextNCalls
//   staticCallLookup          → staticCrossChainCall
//   executeL2TX               → executeL2Txs
//   IZKVerifier               → IProofSystem
//   ProofSystemRegistry       → (deleted — policy lives in each rollup's manager)
//   stateDeltas               → stateUpdates
//   l2ToL1CallNumber /
//     executingLookupIndex    → expectedRollingHash (one key, not two)
//
// TWO REVERSALS, which is the part a rename table alone would hide. Content
// written before the refactor does not merely use old words; it asserts the
// opposite of the current design on two points.
//
//   1. The flat-array-with-one-global-cursor model is GONE. There is no
//      partition invariant (`callCount + Σ nested == flatCalls.length`) to
//      maintain. Each reentrant frame carries its own `l2ToL1Calls[]` sub-array
//      and is run to completion — see ExpectedL1ToL2Call below.
//
//   2. `ExecutionEntry` DOES carry a `bool success`. Older docs argue no failure
//      flag is needed, on the reasoning that a reverting top-level call is a
//      lookup rather than an execution. That was reversed: a `success == false`
//      entry executes, verifies, and then reverts with its `returnData`, so the
//      state effects roll back and a caller may try/catch it.
//
// ONE TRAP THE TABLE ABOVE DOES NOT CATCH. The field renamed; an error that
// names it did not. `RevertSpanOutOfBounds` is live at
// eez-core-protocol/src/EEZ.sol:256 and thrown at :1180. So grepping for the
// old word `revertSpan` finds a current, reachable error and reads as evidence
// the rename never happened. It did — the error kept the old vocabulary.
//
// AND ONE CONSEQUENCE WORTH MORE THAN THE RENAME. The same refactor made
// `stateUpdates` mandatory: at least one, enforced on-chain, reverting
// `EntryHasNoStateUpdates` (EEZ.sol:283). An entry builder ported field-by-field
// from the old names compiles and then fails at post time. If you pulled your
// mental model from CLAUDE.md, check the entry structure itself, not just the
// identifiers.

struct ExpectedStateRootPerRollup {
    uint64 rollupId;
    bytes32 stateRoot;
}

// WAS: StateDelta. The rename travelled with a rule change — see the note
// above: at least one of these per entry, enforced on-chain.
struct StateUpdate {
    uint64 rollupId;
    bytes32 currentState;
    bytes32 newState;
    int256 etherDelta;
}

// The field WAS revertSpan. Note that `RevertSpanOutOfBounds` (EEZ.sol:256)
// still carries the old word, so grepping the old name finds a live error.
struct L2ToL1Call {
    uint16 revertNextNCalls;
    bool isStatic;
    uint64 gas;
    address sourceAddress;
    uint64 sourceRollupId;
    address targetAddress;
    uint256 value;
    bytes data;
}

// Reversal 1 lives here. `l2ToL1Calls` is the frame's OWN sub-array, run to
// completion — not a slice of one flat array walked by a global cursor.
// ExpectedLookup was merged into this one unified table.
struct ExpectedL1ToL2Call {
    bytes32 expectedL1toL2Hash;
    L2ToL1Call[] l2ToL1Calls;
    bytes32 revertedOrStaticRollingHash;
    bool success;
    bytes returnData;
}

// Reversal 2 lives here: `bool success`. A false entry executes, verifies,
// then reverts with returnData. `stateDeltas` is now `stateUpdates`.
struct ExecutionEntry {
    StateUpdate[] stateUpdates;
    bytes32 proxyEntryHash;
    L2ToL1Call[] l2ToL1Calls;
    ExpectedL1ToL2Call[] expectedL1ToL2Calls;
    bytes32 rollingHash;
    uint64 destinationRollupId;
    bool success;
    bytes returnData;
}

// WAS: LookupCall. Resolved by staticCrossChainCall (was staticCallLookup).
// No reentrant table: a nested read re-enters the pool as another one of these.
struct StaticExecutionEntry {
    ExpectedStateRootPerRollup[] expectedStateRoots;
    bytes32 proxyEntryHash;
    L2ToL1Call[] l2ToL1Calls;
    bytes32 rollingHash;
    uint64 destinationRollupId;
    bool success;
    bytes returnData;
}
