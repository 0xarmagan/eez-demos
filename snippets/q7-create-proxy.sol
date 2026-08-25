// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: dapp-developers/q7-your-address-on-every-rollup.html
// Mirrors eez-core-protocol/src/base/EEZBase.sol:156 and :176
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// The two calls a dapp developer makes. Neither requires knowing how the
// address is derived — that is protocol-researcher territory.
//
// Signatures and bodies are hand-wrapped to the code panel's column, the
// same way snippets/q1-compute-address.sol is, so that every line the panel
// shows exists verbatim here. scripts/check-panel-drift.py asserts that.

/// @dev Stand-in for the real proxy. Only `type(...).creationCode` matters here.
contract CrossChainProxy {
    address public immutable manager;

    constructor(address manager_) {
        manager = manager_;
    }
}

/// @dev The two entry points, as a dapp codes against them.
interface IEEZProxyFactory {
function createCrossChainProxy(
    address originalAddress,
    uint64 originalRollupId
) external returns (address proxy);

function computeCrossChainProxyAddress(
    address originalAddress,
    uint64 originalRollupId
) external view returns (address);
}

contract CreateProxySnippet {
    /// @notice Error when a proxy is requested for an address on THIS
    ///         manager's own network.
    error SameNetworkProxy(uint64 rollupId);

    mapping(address => bool) public authorizedProxies;

    event CrossChainProxyCreated(
        address indexed proxy,
        address indexed originalAddress,
        uint64 originalRollupId
    );

    function _getRollupId() internal pure returns (uint64) {
        return 0;
    }

function createCrossChainProxy(
    address originalAddress,
    uint64 originalRollupId
) external returns (address proxy) {
// A proxy stands in for a REMOTE address.
if (originalRollupId == _getRollupId())
    revert SameNetworkProxy(originalRollupId);

    bytes32 salt = keccak256(
        abi.encodePacked(originalRollupId, originalAddress)
    );
    proxy = address(new CrossChainProxy{salt: salt}(address(this)));
    authorizedProxies[proxy] = true;
    emit CrossChainProxyCreated(
        proxy, originalAddress, originalRollupId
    );
}

function computeCrossChainProxyAddress(
    address originalAddress,
    uint64 originalRollupId
) public view returns (address) {
    bytes32 salt = keccak256(
        abi.encodePacked(originalRollupId, originalAddress)
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
