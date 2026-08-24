// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Panel source for: dapp-developers/q6-why-you-cant-call-the-manager-directly.html
// Mirrors eez-core-protocol/src/EEZ.sol:780
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// The registry check is the first thing the entry point does. There is no
// path into execution that skips it, which is why calling the manager
// yourself cannot work no matter how the calldata is shaped.

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
) external payable returns (bytes memory) {
ProxyInfo storage proxyInfo =
    authorizedProxies[msg.sender];

if (!proxyInfo.isProxy)
    revert UnauthorizedProxy();
// msg.sender must be a real proxy —
// never the caller's own address
    sourceAddress;
    callData;
    return "";
}
}
