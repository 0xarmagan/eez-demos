// assets/testnet-config.js — the ONLY place hosted-testnet network values live.
// Every page that shows an RPC URL, chain id or manager address reads
// window.EEZ_TESTNET at render time; nothing is hard-coded in page HTML.
//
// Source: the EEZ-X Testnet dashboard's own config, https://eez.dev/dashboard/config.json,
// checked 2026-10-14 with eth_chainId on each RPC and eth_getCode on each manager
// (non-empty code on its own chain). Re-check both before changing a value.
window.EEZ_TESTNET = {
  status: "live", // "pending" | "live"
  dashboard: "https://eez.dev/dashboard/",
  l2: {
    name: "EEZ-X Testnet (L2)",
    rpcUrl: "https://eez.dev/rpc/l2",
    chainId: "699069", // eth_chainId 0xaaabd
    // EEZL2 proxy predeploy (config.json l2ContractAddress; also the genesis
    // profile value, eez-rollupX scripts/update-eezl2-genesis.sh:15).
    managerAddress: "0x4B2760F84B83d6b3829E30A7573B0172B6d6402C",
    explorer: "https://eez.dev/explorer",
  },
  l1: {
    name: "Chiado (L1)",
    rpcUrl: "https://eez.dev/rpc/l1",
    chainId: "10200", // eth_chainId 0x27d8
    managerAddress: "0x96d6617629b90bdf275dd1d4888170ad5266fa33", // EEZ (L1), config.json l1ContractAddress; rollupId 1
    explorer: "https://gnosis-chiado.blockscout.com",
  },
  // No faucet: the previously listed faucet.chiadochain.net no longer resolves (2026-10-14).
  // The protocol commit the testnet runs (config.json protocolCommit). The
  // walkthroughs cite 9a1f815, 11 commits later.
  deployedAt: "eez-core-protocol @ 855fe06",
};
