// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: dapp-developers/q7-your-cross-chain-address.html
// Mirrors eez-core-protocol/src/base/EEZBase.sol:204, :238 and :250
// @ 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
//
// The two calls this page teaches. Neither is usually required: the protocol
// creates the proxy itself on the first inbound call, through the public
// getOrCreateCrossChainProxy (eez-core-protocol/src/base/EEZBase.sol:214),
// called at eez-core-protocol/src/EEZ.sol:1169 and src/L2/EEZL2.sol:596.
// Neither call requires knowing how the address is derived — that is
// protocol-researcher territory.
//
// Signatures and bodies are hand-wrapped to the code panel's column, the
// same way snippets/q1-compute-address.sol is, so that every line the panel
// shows exists verbatim here. scripts/check-panel-drift.py asserts that.

/// @dev Stand-in for the real proxy. Only `type(...).creationCode` matters
///      here; like upstream, the constructor takes no arguments and records
///      its deployer (the manager) as msg.sender.
contract CrossChainProxy {
    address internal immutable EEZ;

    constructor() {
        EEZ = msg.sender;
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

struct ProxyInfo {
    bool isProxy;
    address originalAddress;
    uint64 originalRollupId;
}

contract CreateProxySnippet {
    /// @notice Error when a proxy is requested for an address on THIS
    ///         manager's own network.
    error SameNetworkProxy(uint64 rollupId);

    bytes32 internal immutable PROXY_INIT_CODE_HASH;

    mapping(address proxy => ProxyInfo info) public authorizedProxies;

    event CrossChainProxyCreated(
        address indexed proxy,
        address indexed originalAddress,
        uint64 originalRollupId
    );

    constructor() {
        PROXY_INIT_CODE_HASH = keccak256(type(CrossChainProxy).creationCode);
    }

    function _getRollupId() internal pure returns (uint64) {
        return 0;
    }

function createCrossChainProxy(
    address originalAddress,
    uint64 originalRollupId
) external returns (address proxy) {
    return _createCrossChainProxyInternal(originalAddress, originalRollupId);
}

function _createCrossChainProxyInternal(
    address originalAddress,
    uint64 originalRollupId
) internal returns (address proxy) {
// A proxy stands in for a REMOTE address.
if (originalRollupId == _getRollupId())
    revert SameNetworkProxy(originalRollupId);

    bytes32 salt = keccak256(
        abi.encodePacked(originalRollupId, originalAddress)
    );
    proxy = address(new CrossChainProxy{salt: salt}());
    authorizedProxies[proxy] =
        ProxyInfo(true, originalAddress, originalRollupId);
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
    return address(uint160(uint256(keccak256(
        abi.encodePacked(
            bytes1(0xff), address(this),
            salt, PROXY_INIT_CODE_HASH
        )
    ))));
}
}
