// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: dapp-developers/q6-why-you-cant-call-the-manager-directly.html
// Mirrors eez-core-protocol/src/EEZ.sol:855 and :1561
// @ 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
//
// The registry check is the first thing the entry point does: its first line
// calls _validateProxyAndGetDestinationInfo, whose first check is the registry
// lookup. staticCrossChainCall opens with the same helper (EEZ.sol:1380).
// There is no path into execution that skips it, which is why calling the
// manager yourself cannot work no matter how the calldata is shaped.
//
// Omitted here: the helper's second check, _requireVerifiedThisBlock(destRid)
// (EEZ.sol:1571), which only runs once the caller is already a proxy.

struct ProxyInfo {
    bool isProxy;
    address originalAddress;
    uint64 originalRollupId;
}

error UnauthorizedProxy();

contract ManagerEntrySnippet {
    mapping(address proxy => ProxyInfo info) public authorizedProxies;

function executeCrossChainCall(
    address sourceAddress,
    bytes calldata callData
) external payable returns (bytes memory result) {
(address destAddress, uint64 destRid) =
    _validateProxyAndGetDestinationInfo();
    sourceAddress;
    callData;
    destAddress;
    destRid;
    return "";
}

function _validateProxyAndGetDestinationInfo()
    internal view returns (address, uint64) {
ProxyInfo storage proxyInfo =
    authorizedProxies[msg.sender];
if (!proxyInfo.isProxy)
    revert UnauthorizedProxy();
// msg.sender must be a real proxy —
// never the caller's own address
    address destAddress = proxyInfo.originalAddress;
    uint64 destRid = proxyInfo.originalRollupId;
    return (destAddress, destRid);
}
}
