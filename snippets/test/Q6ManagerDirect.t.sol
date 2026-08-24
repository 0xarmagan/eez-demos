// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ManagerEntrySnippet, UnauthorizedProxy} from "../q6-manager-direct.sol";

// Runnable proof that the manager's proxy entry point cannot be called
// directly. Paste into any Foundry project and run:
//
//   forge test --match-contract Q6ManagerDirectTest -vv
//
// Depends on nothing but solc — no forge-std, no submodules.
//
// These are all negative cases on purpose. The claim the walkthrough makes is
// that there is no way to shape a direct call that gets through, so the useful
// test is the one that tries several shapes and gets the same revert each time.
//
// The positive case — a registered proxy succeeding — is deliberately absent.
// authorizedProxies is written only by the manager's own CREATE2 deploy path,
// so faking an entry here would mean either adding a setter that the real
// contract does not have, or poking storage with vm.store. Both would be
// testing the fake rather than the protocol.

interface Vm {
    function prank(address) external;
    function expectRevert(bytes4) external;
}

contract Q6ManagerDirectTest {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    ManagerEntrySnippet internal manager;

    function setUp() public {
        manager = new ManagerEntrySnippet();
    }

    /// @dev An ordinary EOA calling the entry point directly.
    function test_directCallFromEoaReverts() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(UnauthorizedProxy.selector);
        manager.executeCrossChainCall(address(0xBEEF), hex"a9059cbb");
    }

    /// @dev A contract calling it is no different: the check is on msg.sender
    ///      being a registered proxy, not on being an EOA.
    function test_directCallFromContractReverts() public {
        vm.expectRevert(UnauthorizedProxy.selector);
        manager.executeCrossChainCall(address(this), hex"a9059cbb");
    }

    /// @dev Passing someone else's address as sourceAddress does not help.
    ///      sourceAddress is data; msg.sender is what is checked.
    function test_spoofingSourceAddressDoesNotHelp() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(UnauthorizedProxy.selector);
        manager.executeCrossChainCall(address(0xCAFE), hex"a9059cbb");
    }

    /// @dev Empty calldata reverts the same way. The registry check runs before
    ///      anything looks at the payload, so payload shape is irrelevant.
    function test_emptyCallDataRevertsIdentically() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(UnauthorizedProxy.selector);
        manager.executeCrossChainCall(address(0xBEEF), "");
    }
}
