// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: dapp-developers/q5-encode-a-calls-content-hash.html
// Mirrors eez-core-protocol/src/base/EEZBase.sol:285
// @ 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
//
// Field order is load-bearing. abi.encode (not encodePacked) 32-byte pads
// every static field and length-prefixes `data`, so reordering two fields
// produces a different hash that still looks perfectly valid.

contract ContentHashSnippet {
function computeCrossChainCallHash(
    bool isStatic,
    address sourceAddress,
    uint64 sourceRollupId,
    address targetAddress,
    uint64 targetRollupId,
    uint256 value,
    uint64 callGas,
    bytes memory data
) public pure returns (bytes32) {
return keccak256(abi.encode(
    isStatic, sourceAddress, sourceRollupId,
    targetAddress, targetRollupId,
    value, callGas, data
));
// ^ same order the protocol hashes on-chain
}
}
