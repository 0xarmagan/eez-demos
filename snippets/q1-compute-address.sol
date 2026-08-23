// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: dapp-developers/q1-compute-your-cross-chain-address.html
// Mirrors eez-core-protocol/src/base/EEZBase.sol:176
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// The address is a pure function of two values. No nonce, no deployment
// order, no registry lookup — so you can compute it before anything is
// deployed, on any chain running the manager.

/// @dev Stand-in for the real proxy. Only `type(...).creationCode` matters here.
contract CrossChainProxy {
    address public immutable manager;

    constructor(address manager_) {
        manager = manager_;
    }
}

contract ComputeAddressSnippet {
function computeCrossChainProxyAddress(
    address originalAddress,
    uint64 originalRollupId
) public view returns (address) {

    bytes32 salt = keccak256(
        abi.encodePacked(
            originalRollupId, originalAddress
        )
    );
    bytes32 bytecodeHash = keccak256(abi.encodePacked(
        type(CrossChainProxy).creationCode,
        abi.encode(address(this))
    ));
    return address(uint160(uint256(keccak256(
        abi.encodePacked(
            bytes1(0xff), address(this),
            salt, bytecodeHash
        )
    ))));
}
}
