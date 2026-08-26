// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: dapp-developers/q9-when-the-proof-fails.html
// Mirrors eez-core-protocol/src/EEZ.sol:1055 (_executeEntry), :206 and :1069
// (StateRootMismatch) and src/base/EEZBase.sol:107 (RollingHashMismatch)
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// Every other page here is a success path. This one is the opposite: what you
// see when the table you are trusting is wrong. Nobody building on EEZ writes
// this code — the composer does — and that is the reason to show it. The
// question a builder actually has about a pre-mainnet protocol is not "will it
// work", it is "will it fail loudly", and that is answerable today.
//
// THE TWO CHECKS, IN THE ORDER _executeEntry RUNS THEM (EEZ.sol:1055-1083).
//
//   1. The state-root precondition, BEFORE any call runs. Each StateUpdate
//      names the `currentState` it expects; if the live root has moved,
//      EEZ.sol:1069 reverts StateRootMismatch(rollupId) and no call in the
//      entry executes at all.
//
//   2. The rolling hash, AFTER all of them have. _processNCalls runs the whole
//      array, folding each outcome; EEZ.sol:1083 compares the accumulator to
//      the entry's declared `rollingHash` and reverts RollingHashMismatch on
//      any divergence. The calls DID run — and then the whole entry unwound.
//
// So an entry that is wrong both ways reports the state root, and the target
// is never touched. Verified: test_StateRootMismatch_PreemptsRollingHash.
//
// POSTING IS NOT VALIDATION. The entry above posts successfully. Entries
// publish unconditionally and the precondition is checked at CONSUMPTION —
// that is what lets alternative entries be stacked speculatively, and it is
// why "the batch was accepted" is not a statement about your call.
//
// THE FAILURE THAT IS NOT A REVERT. The same stale root does not always reach
// you as a revert. An immediate L2Tx entry runs inside a try/catch self-call,
// so StateRootMismatch is swallowed and the entry is reported as an
// `L2TxSkipped` event instead (upstream's own
// test_PostBatch_StateRootMismatch_ImmediateSkipped). Same cause, two
// observables, decided by which path the entry took. Watch the event, not just
// the revert.
//
// WHAT IS VERIFIED AND WHERE. Upstream tests the forged hash directly:
// test_RollingHashMismatch_Reverts and test_UnconsumedCalls_Reverts in
// test/EEZ.t.sol, plus the EEZL2 mirror. The consumption-time
// StateRootMismatch reaching a proxy caller had NO test at this pin; it was
// added locally to check this page and passes against the real contract, but
// it is not upstream yet — treat that one as verified-by-us, not by them.
//
// The contract below is illustrative: it is the shape of the two checks, in
// order, not EEZ's internals. The real ones are internal to EEZ.sol and fold a
// tagged hash chain per call (see pr6). What is faithful here is the ORDERING
// and the two error names, which is what a caller actually observes.

error RollingHashMismatch();
error StateRootMismatch(uint64 rollupId);

contract WhatTheChainChecks {
    /// @dev The live root per rollup, as the registry holds it.
    mapping(uint64 => bytes32) public stateRoot;

    function seedLiveRoot(uint64 rollupId, bytes32 root) external {
        stateRoot[rollupId] = root;
    }

    /// @dev The two gates, in `_executeEntry`'s order. `claimedRoot` is the
    ///      entry's StateUpdate.currentState; `declaredHash` is its rollingHash;
    ///      `observedHash` is what folding the real outcomes produced.
    function consume(
        uint64 rollupId,
        bytes32 claimedRoot,
        bytes32 declaredHash,
        bytes32 observedHash
    ) external view returns (bool) {
// 1. precondition — before a single call runs
if (stateRoot[rollupId] != claimedRoot) {
    revert StateRootMismatch(rollupId);
}

// ... every call in the entry executes here ...

// 2. the referee — after all of them have
if (observedHash != declaredHash) {
    revert RollingHashMismatch();
}
        return true;
    }
}
