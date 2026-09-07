// assets/testnet-config.js — the ONLY place hosted-testnet network values live.
// Every page that shows an RPC URL, chain id or manager address reads
// window.EEZ_TESTNET at render time; nothing is hard-coded in page HTML.
//
// CONNECT-DAY CHECKLIST (when the hosted testnet ships):
//   1. Fill every empty value below.
//   2. Flip status to "live".
//   3. python3 scripts/build-llms.py
//   4. Run the four gates (audit.sh, check-panel-drift.py, verify-citations.py,
//      build-llms.py --check), then open a PR titled "Connect the testnet".
// That PR should touch this file and the regenerated llms files only.
window.EEZ_TESTNET = {
  status: "pending", // "pending" | "live"
  l2: {
    name: "EEZ L2 (testnet)",
    rpcUrl: "",      // e.g. https://rpc.eez-testnet.gnosis.io
    chainId: "",     // decimal string
    // EEZL2 is a predeploy at a fixed address — known before the network is.
    managerAddress: "0x4200000000000000000000000000000000000007",
    explorer: "",
  },
  l1: {
    name: "Chiado (L1)",
    rpcUrl: "https://rpc.chiadochain.net",
    chainId: "10200",
    managerAddress: "", // EEZ (L1) — from the canonical protocol deploy
    explorer: "https://gnosis-chiado.blockscout.com",
  },
  faucet: "https://faucet.chiadochain.net",
  deployedAt: "", // commit or date of the canonical protocol deploy, shown in the footer once live
};
