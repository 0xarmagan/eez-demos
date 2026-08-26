// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEEZ} from "../lib/IEEZ.sol";
import {RemoteReader, IRemote} from "../q8-remote-reads.sol";

// Runnable proof of the q8 caveat. Paste into any Foundry project and run:
//
//   forge test --match-contract Q8RemoteReads -vv
//
// Depends on nothing but solc — no forge-std, no submodules.
//
// The first three cases are the whole hazard: NOTHING REVERTS. Each is a
// successful read returning a real number about the wrong contract. Unlike the
// q3 owner check, there is no failure to notice.
//
// WHAT IS FAKED HERE, AND WHAT IS NOT. Q6ManagerDirect.t.sol refuses to fake
// protocol state and says so in its header; the same line is held here.
// `EntryTable` below is not an EEZ manager and does not pretend to be one. It
// is a local model of the one property the routed read rests on: the outcome
// was written into a table BEFORE the transaction ran, it is matched by a hash
// of the call, and a miss reverts `ExecutionNotFound()`. That is the shape of
// EEZ resolution — the opposite of fetch-on-demand messaging, where the answer
// is gone and fetched while you wait.
//
// What this establishes: the reader in ../q8-remote-reads.sol behaves correctly
// against a resolver of that shape, including both failure modes a builder will
// actually meet. What it does NOT establish: that upstream resolves this way.
// The citations on the page and scripts/verify-citations.py are the check for
// that, and nothing in a local table could stand in for it.
//
// Deliberately not modelled, because a local table cannot: the composer, the
// rolling hash, state roots, the entry queues, and the side-specific rule for
// when a static entry is still valid (L1 matches on state roots with no block
// gate, EEZ.sol:1308-1319; L2 gates on the block, EEZL2.sol:634). The key below
// is a REDUCED stand-in for `computeCrossChainCallHash` — q5 has the real
// eight-field preimage. What is under test is lookup-then-revert, not the
// field list.

/// @dev Minimal cheatcode surface. Same address forge injects.
interface Vm {
    function deal(address, uint256) external;
    function label(address, string calldata) external;
    function expectRevert(bytes4) external;
}

/// @dev Named exactly as upstream names it (EEZ.sol:1327, EEZL2.sol:644), so a
///      reader who hits it in production can search for the same string.
error ExecutionNotFound();

/// @dev The destination's own error, for the case where an entry exists and
///      records that the destination call reverted.
error RemoteBalanceUnavailable();

// @stand-in a local table, not a manager: it holds outcomes keyed by a reduced
//           call hash so the test can exercise hit, miss and destination-revert
//           without faking EEZ storage. See the header.
contract EntryTable {
    struct Entry {
        bool present;
        bool success;
        bytes data;
    }

    mapping(bytes32 => Entry) private entries;

    address private immutable destAddress;
    uint64 private immutable destRollupId;

    constructor(address destAddress_, uint64 destRollupId_) {
        destAddress = destAddress_;
        destRollupId = destRollupId_;
    }

    /// @dev Reduced stand-in for computeCrossChainCallHash. The real preimage is
    ///      eight fields in a fixed order (q5); the point here is only that the
    ///      entry is addressed by the content of the call.
    function keyFor(address sourceAddress, bytes memory callData) public view returns (bytes32) {
        return keccak256(abi.encode(true, sourceAddress, destAddress, destRollupId, callData));
    }

    /// @dev The composer's job, done by hand. In production nothing in your
    ///      transaction writes this table.
    function commit(address sourceAddress, bytes calldata callData, bool success, bytes calldata data) external {
        entries[keyFor(sourceAddress, callData)] = Entry(true, success, data);
    }

    /// @dev Same name and signature as the manager's read entry point, so the
    ///      shape of the call the proxy makes is the real one.
    function staticCrossChainCall(address sourceAddress, bytes calldata callData)
        external
        view
        returns (bytes memory)
    {
        Entry storage entry = entries[keyFor(sourceAddress, callData)];
        if (!entry.present) revert ExecutionNotFound();
        if (!entry.success) {
            bytes memory reason = entry.data;
            assembly {
                revert(add(reason, 0x20), mload(reason))
            }
        }
        return entry.data;
    }
}

// @stand-in a two-line model of CrossChainProxy's read path: a real local
//           contract with its own code and balance, whose fallback forwards to
//           the manager's view entry point and hands back exactly what comes
//           out — including raw revert data (CrossChainProxy.sol:104-113).
contract StubProxy {
    address internal immutable manager;

    constructor(address manager_) {
        manager = manager_;
    }

    fallback() external payable {
        (bool ok, bytes memory result) =
            manager.staticcall(abi.encodeCall(EntryTable.staticCrossChainCall, (msg.sender, msg.data)));
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

// @stand-in an address book, nothing more: the reader asks for its proxy and
//           gets the stub back. It does not derive anything — q7 is the page
//           for the real CREATE2 derivation.
contract MockEEZ {
    address private immutable proxyAddress;

    constructor(address proxyAddress_) {
        proxyAddress = proxyAddress_;
    }

    function computeCrossChainProxyAddress(address, uint64) external view returns (address) {
        return proxyAddress;
    }
}

// @stand-in the contract being read, as it exists on the OTHER rollup. It is
//           local here only so the test can hold two different numbers at once.
//           The routed read must never touch it, which is what `calls` proves.
contract Counterpart {
    uint256 public calls;

    mapping(address => uint256) private balances;

    function setBalance(address who, uint256 amount) external {
        balances[who] = amount;
    }

    function balanceOf(address who) external returns (uint256) {
        calls++;
        return balances[who];
    }
}

contract Q8RemoteReadsTest {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    address internal constant USER = address(0xA11CE);
    address internal constant STRANGER = address(0xB0B);
    uint64 internal constant REMOTE_ROLLUP_ID = 1;

    uint256 internal constant COMMITTED_BALANCE = 500 ether;
    uint256 internal constant PROXY_BALANCE = 1 wei;
    uint256 internal constant COUNTERPART_BALANCE = 7 ether;

    Counterpart internal counterpart;
    EntryTable internal table;
    StubProxy internal proxy;
    RemoteReader internal reader;

    function setUp() public {
        counterpart = new Counterpart();
        counterpart.setBalance(USER, COMMITTED_BALANCE);
        vm.deal(address(counterpart), COUNTERPART_BALANCE);

        table = new EntryTable(address(counterpart), REMOTE_ROLLUP_ID);
        proxy = new StubProxy(address(table));
        vm.deal(address(proxy), PROXY_BALANCE);

        reader = new RemoteReader(
            IEEZ(address(new MockEEZ(address(proxy)))), address(counterpart), REMOTE_ROLLUP_ID
        );

        // The entry for the one read this test expects to resolve. Written
        // before any of it runs, which is the whole point.
        table.commit(
            address(reader),
            abi.encodeCall(IRemote.balanceOf, (USER)),
            true,
            abi.encode(COMMITTED_BALANCE)
        );

        vm.label(address(proxy), "proxy(counterpart)");
        vm.label(address(counterpart), "counterpart");
        vm.label(address(table), "entryTable");
    }

    /// @dev The trap, part one. `.balance` answers about the proxy. No revert.
    function test_balanceReadsTheProxyNotTheCounterpart() public view {
        (uint256 bal,,) = reader.inspectionLies(block.chainid + 1);
        require(bal == PROXY_BALANCE, "expected the proxy's own balance");
        require(bal != COUNTERPART_BALANCE, "must not be the counterpart's balance");
    }

    /// @dev The trap, part two. The proxy has code, so an `extcodesize`-style
    ///      "is this a contract" check passes — and proves nothing about whether
    ///      anything exists on the other rollup.
    function test_codeSizeIsTheProxysOwn() public view {
        (, uint256 size,) = reader.inspectionLies(block.chainid + 1);
        require(size == address(proxy).code.length, "the proxy's own code size");
        require(
            keccak256(address(proxy).code) != keccak256(address(counterpart).code),
            "proxy code is not the counterpart's code"
        );
        require(reader.proxyExistsButProvesNothing(), "code at the proxy address proves only that");
    }

    /// @dev The trap, part three. Block context is local. A reader comparing
    ///      against the counterparty's chain id silently takes the wrong branch.
    function test_blockContextIsLocal() public view {
        (,, bool sameChain) = reader.inspectionLies(block.chainid + 1);
        require(!sameChain, "block.chainid is this chain's, never the remote one");
    }

    /// @dev The fix. Calling THROUGH the proxy returns the remote contract's
    ///      state, because a call is routed and an inspection is not — and the
    ///      value comes out of the entry, not out of a live fetch. `calls == 0`
    ///      is that second half: the counterpart is never touched.
    function test_routedReadReturnsThePreCommittedEntry() public view {
        uint256 seen = reader.readRemoteBalance(USER);
        require(seen == COMMITTED_BALANCE, "routed read returns the committed outcome");
        require(counterpart.calls() == 0, "resolution never calls the counterpart");
    }

    /// @dev The honest limit. With no matching entry the routed read reverts
    ///      `ExecutionNotFound()` rather than returning zero. In production that
    ///      is a read whose static entry is not in scope: on L2 because the block
    ///      moved on (EEZL2.sol:634), on L1 because no entry in the queue matches
    ///      the call and the live state roots (EEZ.sol:1308-1319).
    function test_unresolvedReadRevertsExecutionNotFound() public {
        vm.expectRevert(ExecutionNotFound.selector);
        reader.readRemoteBalance(STRANGER);
    }

    /// @dev CAVEATS.md, "Indistinguishable revert reasons when calling a proxy".
    ///      The proxy forwards raw revert data and adds nothing of its own, so
    ///      the caller has no field saying which layer failed — only the bytes it
    ///      was handed. Both cases below hand back the same bytes.
    function test_missAndDestinationRevertAreIndistinguishable() public {
        bytes memory callData = abi.encodeCall(IRemote.balanceOf, (STRANGER));

        // A: nothing committed for STRANGER, so the table itself reverts.
        (bool okMiss, bytes memory fromMiss) = address(proxy).staticcall(callData);

        // B: an entry EXISTS and records that the destination call reverted,
        // carrying the destination's own revert bytes.
        table.commit(address(this), callData, false, abi.encodeWithSelector(ExecutionNotFound.selector));
        (bool okReverted, bytes memory fromReverted) = address(proxy).staticcall(callData);

        require(!okMiss && !okReverted, "both fail");
        require(keccak256(fromMiss) == keccak256(fromReverted), "the caller cannot tell them apart");

        // And a destination that reverts with its own error is no more legible:
        // it is still just bytes arriving from the proxy.
        table.commit(address(this), callData, false, abi.encodeWithSelector(RemoteBalanceUnavailable.selector));
        (bool okOther, bytes memory fromOther) = address(proxy).staticcall(callData);
        require(!okOther, "still a revert from the proxy");
        require(fromOther.length == 4, "four bytes of someone else's error, and no attribution");
    }
}
