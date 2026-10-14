// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: protocol-researchers/pr5-how-the-address-is-derived.html
// Mirrors eez-core-protocol/src/base/EEZBase.sol:250 and :188
// @ 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
//
// The address is a pure function of two values. No nonce, no deployment
// order, no registry lookup — so you can compute it before anything is
// deployed, on any chain running the manager.

/// @dev Stand-in for the real proxy. Only `type(...).creationCode` matters here.
///      Like upstream, it takes no constructor argument and records its deployer,
///      so the creation code alone is hashed.
contract CrossChainProxy {
    address public immutable manager;

    constructor() {
        manager = msg.sender;
    }
}

contract ComputeAddressSnippet {
bytes32 public immutable PROXY_INIT_CODE_HASH;

constructor() {
    PROXY_INIT_CODE_HASH = keccak256(
        type(CrossChainProxy).creationCode
    );
}

function computeCrossChainProxyAddress(
    address originalAddress,
    uint64 originalRollupId
) public view returns (address) {

    bytes32 salt = keccak256(
        abi.encodePacked(
            originalRollupId, originalAddress
        )
    );
    return address(uint160(uint256(keccak256(
        abi.encodePacked(
            bytes1(0xff), address(this),
            salt, PROXY_INIT_CODE_HASH
        )
    ))));
}
}
