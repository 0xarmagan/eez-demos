// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEEZ} from "./IEEZ.sol";

/// @notice Two members the walkthroughs use that are NOT on IEEZ. They live on
///         the concrete manager (EEZBase), not the shared interface, so calling
///         them means holding a manager reference rather than an IEEZ one.
///         Worth knowing before you copy a snippet into your own contract.
///
///   authorizedProxies       -> eez-core-protocol/src/base/EEZBase.sol:60
///   computeCrossChainCallHash -> eez-core-protocol/src/base/EEZBase.sol:198
///   both @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
interface IEEZManager is IEEZ {
    /// @notice Auto-generated getter for `mapping(address => ProxyInfo) public authorizedProxies`.
    ///         A public mapping to a struct returns the struct's members, flattened.
    function authorizedProxies(address proxy)
        external
        view
        returns (bool isProxy, address originalAddress, uint64 originalRollupId);

    /// @notice Field order is load-bearing: reorder and every on-chain hash check
    ///         and every off-chain tool that pre-computes the hash breaks.
    function computeCrossChainCallHash(
        bool isStatic,
        address sourceAddress,
        uint64 sourceRollupId,
        address targetAddress,
        uint64 targetRollupId,
        uint256 value,
        uint64 callGas,
        bytes memory data
    ) external pure returns (bytes32);
}
