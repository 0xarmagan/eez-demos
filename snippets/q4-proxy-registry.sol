// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEEZManager} from "./lib/IEEZManager.sol";

// Panel source for: dapp-developers/q4-check-if-an-address-is-a-proxy.html
// Mirrors eez-core-protocol/src/base/EEZBase.sol:60
// @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
//
// The registry is a public mapping, so anyone can read it directly — no
// events to replay, no indexer required. Because it maps to a struct, the
// auto-generated getter returns the struct's members flattened.

struct ProxyInfo {
    bool isProxy;
    address originalAddress;
    uint64 originalRollupId;
}

/// @dev Manager side — the storage the walkthrough points at.
contract RegistryStorage {
mapping(address proxy => ProxyInfo info)
    public authorizedProxies;
}

/// @dev Reader side — anyone can do this.
contract RegistryReader {
    IEEZManager internal immutable eez;

    constructor(IEEZManager eez_) {
        eez = eez_;
    }

    function check(address someAddress) external view returns (bool) {
(bool isProxy, address origAddr, uint64 origRid)
    = eez.authorizedProxies(someAddress);

if (isProxy) {
    /* real proxy for origAddr@origRid */
}
        origAddr;
        origRid;
        return isProxy;
    }
}
