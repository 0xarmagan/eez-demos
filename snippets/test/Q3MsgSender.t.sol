// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEEZ} from "../lib/IEEZ.sol";
import {OwnerGated} from "../q3-msg-sender.sol";

// Runnable proof of the q3 gotcha. Paste into any Foundry project and run:
//
//   forge test --match-contract Q3MsgSenderTest -vv
//
// Deliberately depends on nothing but solc — no forge-std, no submodules — so
// it drops into an existing test suite without dragging in a dependency tree.
//
// The point of the test is the FIRST case: test_sameChainCheck_passesOnSameChain
// is why this bug ships. The owner check is not obviously wrong. It passes
// locally, it passes in unit tests, and it only fails once a call actually
// arrives through a proxy — which is exactly the path a same-chain test never
// exercises.

/// @dev Minimal cheatcode surface. Same address forge injects.
interface Vm {
    function prank(address) external;
    function expectRevert() external;
    function label(address, string calldata) external;
}

/// @dev Stands in for the manager. Uses the real derivation shape
///      (eez-core-protocol EEZBase.sol:250 @ 9a1f815): CREATE2 over the manager's
///      own address, the (rollupId, address) salt, and the hash of the
///      argument-free proxy creation code. `Dummy` replaces the real proxy, so
///      the address differs from production; the shape does not.
contract MockEEZ {
    function computeCrossChainProxyAddress(address originalAddress, uint64 originalRollupId)
        external
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(originalRollupId, originalAddress));
        bytes32 initCodeHash = keccak256(type(Dummy).creationCode);
        return address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCodeHash))))
        );
    }
}

/// @dev Like upstream's proxy, takes no constructor argument: the deploying
///      manager is captured from msg.sender.
contract Dummy {
    address public immutable manager;

    constructor() {
        manager = msg.sender;
    }
}

contract Q3MsgSenderTest {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint64 internal constant ORIGIN_RID = 100;
    address internal alice = address(0xA11CE);

    MockEEZ internal eez;
    OwnerGated internal gated;
    address internal aliceProxy;

    function setUp() public {
        eez = new MockEEZ();
        gated = new OwnerGated(IEEZ(address(eez)), alice, ORIGIN_RID);
        aliceProxy = eez.computeCrossChainProxyAddress(alice, ORIGIN_RID);
        vm.label(alice, "alice(EOA)");
        vm.label(aliceProxy, "proxy(alice)");
    }

    /// @dev Why the bug ships: called directly by the owner, the check is fine.
    function test_sameChainCheck_passesOnSameChain() public {
        vm.prank(alice);
        gated.sameChainOnly();
    }

    /// @dev The bug: the same call arriving through the proxy reverts, because
    ///      msg.sender is proxy(alice) and never alice.
    function test_sameChainCheck_revertsWhenCalledViaProxy() public {
        vm.prank(aliceProxy);
        vm.expectRevert();
        gated.sameChainOnly();
    }

    /// @dev The fix: whitelist the derived proxy instead of the EOA.
    function test_proxyCheck_passesWhenCalledViaProxy() public {
        vm.prank(aliceProxy);
        gated.crossChainSafe();
    }

    /// @dev And the fix is not a blanket opening: an unrelated caller still fails.
    function test_proxyCheck_revertsForStranger() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        gated.crossChainSafe();
    }
}
