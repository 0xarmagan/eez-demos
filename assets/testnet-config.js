// assets/testnet-config.js — the source of truth for hosted-testnet network values.
// deploy.html reads window.EEZ_TESTNET at render time and overwrites its
// [data-val] spans, but those spans also carry the same values as fallback
// text in the HTML. Change a value here AND in deploy.html's fallback text.
//
// Source: the EEZ-X Testnet dashboard's own config, https://eez.dev/dashboard/config.json,
// checked 2026-10-14 with eth_chainId on each RPC and front and eth_getCode on each manager
// (non-empty code on its own chain). Re-check both before changing a value.
window.EEZ_TESTNET = {
  status: "live", // "pending" | "live"
  dashboard: "https://eez.dev/dashboard/",
  l2: {
    name: "EEZ-X Testnet (L2)",
    rpcUrl: "https://eez.dev/rpc/l2", // direct node RPC: reads and tooling
    // Composer front (config.json l2FrontUrl): send wallet transactions here.
    // Ordinary txs are forwarded unchanged, cross-chain ones are composed
    // (eez-rollupX README.md:136-142, testing/public-gateway/README.md:28-30).
    frontUrl: "https://eez.dev/composer/l2",
    chainId: "699069", // eth_chainId 0xaaabd
    // EEZL2 proxy predeploy (config.json l2ContractAddress; also the genesis
    // profile value, eez-rollupX scripts/update-eezl2-genesis.sh:15).
    managerAddress: "0x4B2760F84B83d6b3829E30A7573B0172B6d6402C",
    explorer: "https://eez.dev/explorer",
  },
  l1: {
    name: "Chiado (L1)",
    rpcUrl: "https://eez.dev/rpc/l1",
    frontUrl: "https://eez.dev/composer/l1", // config.json l1FrontUrl
    chainId: "10200", // eth_chainId 0x27d8
    managerAddress: "0x96d6617629b90bdf275dd1d4888170ad5266fa33", // EEZ (L1), config.json l1ContractAddress; rollupId 1
    explorer: "https://gnosis-chiado.blockscout.com",
  },
  // Faucet: faucet.chiadochain.net no longer resolves (2026-10-14). deploy.html links
  // https://faucet.gnosischain.com/?chain=chiado, the "Chiado Testnet Faucet" on
  // docs.gnosischain.com/tools/Faucets (200 on 2026-10-14).
  // The protocol commit the testnet runs (config.json protocolCommit). The
  // walkthroughs cite 9a1f815, 11 commits later.
  deployedAt: "eez-core-protocol @ 855fe06",
};
