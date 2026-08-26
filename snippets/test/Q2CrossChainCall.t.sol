// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Caller, IRemote, CrossChainCallFailed} from "../q2-cross-chain-call.sol";

// Runnable proof of the one rule q2 turns on. Paste into any Foundry project:
//
//   forge test --match-contract Q2CrossChainCall -vv
//
// Depends on nothing but solc — no forge-std, no submodules.
//
// The claim under test is not "a cross-chain call works." It is narrower and it
// is the thing a builder gets wrong: THE CALLER'S FRAME PICKS THE PATH. The
// proxy probes itself with a `tstore`, a `tstore` is an exceptional halt inside
// a STATICCALL (EIP-1153), and that halt is the entire signal. `view` on the
// callee has nothing to do with it. So `staticcall` reaches the read path and a
// pre-committed static entry; a plain `call` reaches the execution path and
// demands an entry no composer wrote for a read.
//
// That halt is real here, not simulated: `ProbeProxy` does the actual `tstore`
// and solc/revm enforce the static-context rule. This is the one part of the
// mechanism a local test CAN establish honestly.
//
// WHAT IS FAKED, AND WHAT IS NOT. `EntryTable` is not an EEZ manager and does
// not pretend to be one, the same line Q6ManagerDirect and Q8RemoteReads hold.
// It models one property the whole design rests on: the outcome was written
// BEFORE this transaction ran, it is addressed by the content of the call, and
// a miss reverts. Deliberately not modelled, because a local table cannot: the
// composer, the rolling hash, state roots, the entry queues, the block gate,
// and the side-specific rule for when a static entry is still valid (L1 matches
// on state roots, EEZ.sol:1308-1319; L2 gates on the block, EEZL2.sol:634).
//
// The key below is a REDUCED stand-in for `computeCrossChainCallHash` — the
// real preimage is eight fields in a fixed order (q5). What is under test is
// routing and the branch, not the field list.

/// @dev Minimal cheatcode surface. Same address forge injects.
interface Vm {
    function expectRevert(bytes4) external;
    function label(address, string calldata) external;
}

/// @dev Named as upstream names them, so a reader who hits one in production can
///      search for the same string. The read path reverts `ExecutionNotFound` on
///      either side (EEZ.sol:1327, EEZL2.sol:644); the L2 execution path reverts
///      `EntryNotFound` and carries the observed `callGas` in the payload so the
///      entry-builder can reproduce the key (EEZL2.sol:98, :441).
error ExecutionNotFound();
error EntryNotFound(bytes32 crossChainCallHash, uint64 callGas);

/// @dev The destination's own error, for the case where an entry exists and
///      records that the destination call reverted.
error RemoteBalanceUnavailable();

// @stand-in a local table, not a manager. Two pools, because the point of this
//           test is that the two paths are separate: a static entry cannot
//           satisfy an execution, and vice versa.
contract EntryTable {
    struct Entry {
        bool present;
        bool success;
        bytes data;
    }

    mapping(bytes32 => Entry) private staticEntries;
    mapping(bytes32 => Entry) private execEntries;

    address private immutable destAddress;
    uint64 private immutable destRollupId;

    constructor(address destAddress_, uint64 destRollupId_) {
        destAddress = destAddress_;
        destRollupId = destRollupId_;
    }

    /// @dev Reduced stand-in for computeCrossChainCallHash. `isStatic` is folded
    ///      in because upstream folds it in (EEZBase.sol:197) — it is what makes
    ///      a read hash distinctly from an otherwise-identical write.
    function keyFor(bool isStatic, address sourceAddress, bytes memory callData) public view returns (bytes32) {
        return keccak256(abi.encode(isStatic, sourceAddress, destAddress, destRollupId, callData));
    }

    /// @dev The composer's job, done by hand. In production nothing in your
    ///      transaction writes either table.
    function commitStatic(address sourceAddress, bytes calldata callData, bool success, bytes calldata data) external {
        staticEntries[keyFor(true, sourceAddress, callData)] = Entry(true, success, data);
    }

    /// @dev Same name and signature as the manager's read entry point.
    function staticCrossChainCall(address sourceAddress, bytes calldata callData)
        external
        view
        returns (bytes memory)
    {
        Entry storage entry = staticEntries[keyFor(true, sourceAddress, callData)];
        if (!entry.present) revert ExecutionNotFound();
        if (!entry.success) {
            bytes memory reason = entry.data;
            assembly {
                revert(add(reason, 0x20), mload(reason))
            }
        }
        return entry.data;
    }

    /// @dev Same name and signature as the manager's execution entry point. The
    ///      execution pool is left empty on purpose: no composer writes an
    ///      ExecutionEntry for a read, which is exactly why a plain `call` for a
    ///      read fails, and fails with the OTHER error name.
    function executeCrossChainCall(address sourceAddress, bytes calldata callData)
        external
        payable
        returns (bytes memory)
    {
        bytes32 key = keyFor(false, sourceAddress, callData);
        Entry storage entry = execEntries[key];
        if (!entry.present) revert EntryNotFound(key, 0);
        return entry.data;
    }
}

// @stand-in a model of CrossChainProxy's routing decision, and the only part of
//           the protocol this test reproduces for real: the self-probe. The
//           `tstore` and the gas cap are upstream's (CrossChainProxy.sol:23,
//           :71, :89). Unlike the page snippet this declares a NAMED transient
//           variable rather than writing raw slot 0 — which is what upstream
//           does and what the snippet's STAND-IN note tells you to do.
contract ProbeProxy {
    address internal immutable manager;

    uint256 transient _staticDetector;

    constructor(address manager_) {
        manager = manager_;
    }

    function staticCheck() external {
        _staticDetector = 1;
    }

    fallback() external payable {
        (bool probeOk,) = address(this).call{gas: 1_000}(abi.encodeCall(this.staticCheck, ()));

        bool ok;
        bytes memory result;
        if (!probeOk) {
            // The probe halted, so this frame is static: route the read.
            (ok, result) = manager.staticcall(
                abi.encodeCall(EntryTable.staticCrossChainCall, (msg.sender, msg.data))
            );
        } else {
            (ok, result) = manager.call{value: msg.value}(
                abi.encodeCall(EntryTable.executeCrossChainCall, (msg.sender, msg.data))
            );
        }
        if (ok) {
            // The manager returns `bytes`, so the raw result is double-encoded.
            result = abi.decode(result, (bytes));
        }
        assembly {
            switch ok
            case 0 { revert(add(result, 0x20), mload(result)) }
            default { return(add(result, 0x20), mload(result)) }
        }
    }

    receive() external payable {}
}

contract Q2CrossChainCallTest {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    address internal constant REMOTE = address(0xBEEF);
    uint64 internal constant REMOTE_ROLLUP = 42;
    address internal constant USER = address(0xA11CE);

    EntryTable internal table;
    ProbeProxy internal proxy;
    Caller internal caller;

    bytes internal readData;

    function setUp() public {
        table = new EntryTable(REMOTE, REMOTE_ROLLUP);
        proxy = new ProbeProxy(address(table));
        caller = new Caller(address(proxy));
        readData = abi.encodeCall(IRemote.balanceOf, (USER));
        vm.label(address(proxy), "CrossChainProxy(stand-in)");
    }

    function _commitBalance(uint256 balance) internal {
        table.commitStatic(address(caller), readData, true, abi.encode(balance));
    }

    // ── The payoff: a value from another rollup decides the branch ──

    function test_fundedBranchCreditsFromARemoteValue() public {
        _commitBalance(100);
        bool funded = caller.settleIfFunded(USER, 40);
        require(funded, "expected the funded branch");
        require(caller.credited(USER) == 40, "credited should record the need");
        require(caller.shortfall(USER) == 0, "shortfall should be untouched");
    }

    function test_shortBranchRecordsTheGapFromTheSameCall() public {
        _commitBalance(10);
        bool funded = caller.settleIfFunded(USER, 40);
        require(!funded, "expected the short branch");
        require(caller.shortfall(USER) == 30, "shortfall should be need - have");
        require(caller.credited(USER) == 0, "credited should be untouched");
    }

    /// @dev The decode is not decorative: the same call with a different
    ///      committed value takes a different branch and nothing else changes.
    function test_theBranchTracksTheValueNotTheSuccessFlag() public {
        _commitBalance(40);
        require(caller.settleIfFunded(USER, 40), "have == need is funded");
    }

    // ── The rule: the frame picks the path ──

    /// @dev A plain CALL with the very same calldata does NOT reach the read
    ///      path. It reaches `executeCrossChainCall` and misses, because no
    ///      composer writes an ExecutionEntry for a read — and it misses under
    ///      the other error name. This is the failure a `.call(data)` read
    ///      produces in production.
    function test_plainCallTakesTheExecutionPathAndMisses() public {
        _commitBalance(100);
        (bool ok, bytes memory ret) = address(proxy).call(readData);
        require(!ok, "a plain call must not resolve the static entry");
        require(bytes4(ret) == EntryNotFound.selector, "expected EntryNotFound, not ExecutionNotFound");
    }

    /// @dev And the staticcall reaches the read path even though the committed
    ///      static entry is the ONLY entry that exists. Committed for THIS
    ///      contract, because the entry is keyed by the source address —
    ///      `sourceAddress` is the second field of the real preimage too
    ///      (EEZBase.sol:197), so the same call from a different caller is a
    ///      different entry.
    function test_staticcallTakesTheReadPath() public {
        table.commitStatic(address(this), readData, true, abi.encode(uint256(100)));
        (bool ok, bytes memory ret) = address(proxy).staticcall(readData);
        require(ok, "the static entry should resolve");
        require(abi.decode(ret, (uint256)) == 100, "the remote value should come back");
    }

    /// @dev The corollary, worth its own case because it is a real footgun: an
    ///      entry committed for one caller does not resolve for another.
    function test_anEntryIsKeyedByTheSourceAddress() public {
        _commitBalance(100);
        (bool ok, bytes memory ret) = address(proxy).staticcall(readData);
        require(!ok, "another caller's entry must not resolve");
        require(bytes4(ret) == ExecutionNotFound.selector, "expected ExecutionNotFound");
    }

    // ── Both failure modes, and why they are the same failure to a caller ──

    function test_missRevertsCrossChainCallFailed() public {
        vm.expectRevert(CrossChainCallFailed.selector);
        caller.settleIfFunded(USER, 40);
    }

    /// @dev An entry exists and records that the destination reverted. The
    ///      caller sees the identical outcome as the miss above — this is
    ///      docs/CAVEATS.md "Indistinguishable revert reasons", executable.
    function test_destinationRevertIsIndistinguishableFromAMiss() public {
        table.commitStatic(
            address(caller), readData, false, abi.encodeWithSelector(RemoteBalanceUnavailable.selector)
        );
        vm.expectRevert(CrossChainCallFailed.selector);
        caller.settleIfFunded(USER, 40);
    }
}
