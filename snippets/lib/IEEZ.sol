// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Minimal local copy of the real IEEZ interface, so the snippets in
///         this directory compile standalone without vendoring the whole
///         protocol. Every signature below is copied verbatim from upstream:
///
///   eez-core-protocol/src/interfaces/IEEZ.sol
///   @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
///
/// If upstream changes a signature, scripts/check-snippets.mjs keeps compiling
/// happily — it only proves the snippets are valid Solidity, not that they
/// match upstream. scripts/verify-citations.py is what catches upstream drift.
interface IEEZ {
    /// @notice Executes a cross-chain call initiated by an authorized proxy.
    function executeCrossChainCall(address sourceAddress, bytes calldata callData)
        external
        payable
        returns (bytes memory result);

    /// @notice Resolves a read-only cross-chain call initiated by an authorized proxy.
    function staticCrossChainCall(address sourceAddress, bytes calldata callData)
        external
        view
        returns (bytes memory result);

    /// @notice Creates the CrossChainProxy for an address on another rollup.
    function createCrossChainProxy(address originalAddress, uint64 originalRollupId)
        external
        returns (address proxy);

    /// @notice Recipient of ether swept from proxies.
    function RECOVERY_ADDRESS() external view returns (address);

    /// @notice Computes the deterministic CREATE2 address of the CrossChainProxy
    ///         for an (address, rollup) pair.
    function computeCrossChainProxyAddress(address originalAddress, uint64 originalRollupId)
        external
        view
        returns (address);
}
