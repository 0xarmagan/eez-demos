// assets/network-config.js — the source of truth for the hosted EEZ-X network values.
// deploy.html reads window.EEZ_NETWORK at render time and overwrites its
// [data-val] spans, but those spans also carry the same values as fallback
// text in the HTML. Change a value here AND in deploy.html's fallback text.
//
// Source: the EEZ-X Mainnet dashboard's own config, https://mainnet.eez.dev/dashboard/config.json,
// checked 2026-10-21 with eth_chainId on each RPC and front and eth_getCode on each manager
// (non-empty code on its own chain). Re-check both before changing a value.
window.EEZ_NETWORK = {
  status: "live", // "pending" | "live"
  dashboard: "https://mainnet.eez.dev/dashboard/",
  l2: {
    name: "EEZ-X Mainnet (L2)",
    rpcUrl: "https://mainnet.eez.dev/rpc/l2", // direct node RPC: reads and tooling
    // Composer front (config.json l2FrontUrl): send wallet transactions here.
    // Ordinary txs are forwarded unchanged, cross-chain ones are composed
    // (eez-rollupX README.md:136-142, testing/public-gateway/README.md:28-30).
    frontUrl: "https://mainnet.eez.dev/composer/l2",
    chainId: "696990", // eth_chainId 0xaa29e
    // EEZL2 proxy predeploy (config.json l2ContractAddress; also the genesis
    // profile value, eez-rollupX scripts/update-eezl2-genesis.sh:15).
    managerAddress: "0x4B2760F84B83d6b3829E30A7573B0172B6d6402C",
    explorer: "https://mainnet.eez.dev/explorer",
  },
  l1: {
    name: "Ethereum (L1)",
    rpcUrl: "https://mainnet.eez.dev/rpc/l1",
    frontUrl: "https://mainnet.eez.dev/composer/l1", // config.json l1FrontUrl
    chainId: "1", // eth_chainId 0x1
    managerAddress: "0x4b2760f84b83d6b3829e30a7573b0172b6d6402c", // EEZ (L1), config.json l1ContractAddress; rollupId 1; code present on Ethereum mainnet
    explorer: "https://etherscan.io",
  },
  // The protocol commit the network runs (config.json protocolCommit). The
  // walkthroughs cite 9a1f815, 11 commits later.
  deployedAt: "eez-core-protocol @ 855fe06",
};
