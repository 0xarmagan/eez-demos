# Bridge Tokens Both Ways

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

Run one ETH scenario per direction, L1 to L2 and L2 to L1, each on its own pair of chains, then run the test that sends an ERC-20 through the Bridge.sol test fixture and back.

- Page: https://eez-demos.vercel.app/dapp-developers/qs8-bridge-tokens-both-ways.html
- Source: `eez-core-protocol/script/e2e/run/local/parallel.sh:17 · parallel.sh`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/script/e2e/run/local/parallel.sh#L17

### Step 1 — RUN IT.

The scenarios move ETH across: bridge from L1 to L2, bridgeL2 from L2 to L1, with the script playing composer. The test then runs Bridge.sol's token round trip: lock and mint, burn and release.

```text
# needs Git, jq, Foundry 1.7.1 (forge, cast, anvil on PATH)
# and bash 4+; macOS ships 3.2, so: brew install bash
# jq: recent macOS ships it, or brew/apt install jq
# fresh clone at the pinned commit, then build
$ git clone https://github.com/eez-association/eez-core-protocol.git
$ cd eez-core-protocol
$ git checkout -q 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
$ git submodule update --init --recursive
$ forge build

# one scenario per direction, run side by side
$ bash script/e2e/run/local/parallel.sh bridge bridgeL2
  [bridge] starting (L1=18545 chain=41337, L2=18546 chain=41338)
  [bridgeL2] starting (L1=18547 chain=41339, L2=18548 chain=41340)
  [bridge] PASS
  [bridgeL2] PASS

===== RESULT: 2 passed, 0 failed, 0 skipped =====

# token path in Bridge.sol: lock/mint, burn/release
$ forge test --match-test test_BridgeTokens_Roundtrip
⋯
[PASS] test_BridgeTokens_Roundtrip() (gas: 2236711)
Suite result: ok. 1 passed; 0 failed; 0 skipped; …
```

### Step 2 — LOCK AND MINT.

Bridge.sol makes the same kind of proxy call for ERC-20s. The origin bridge locks the token and calls the proxy that stands for the other bridge. When the other chain runs that entry, receiveTokens mints a wrapped copy, but only for the counterpart's proxy.

```text
// ORIGIN CHAIN · bridgeTokens(token, amount, …)
// Native token: lock in this contract
IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
// payload = receiveTokens(token, rollupId, to, amount, …)
(bool success, bytes memory reason) = bridgeProxy.call(payload);
if (!success) revert ProxyCallFailed(reason);

// OTHER CHAIN · receiveTokens, via onlyBridgeProxy
if (msg.sender != expectedProxy) revert UnauthorizedCaller();
// Token is foreign → mint wrapped tokens
// wrapped = _getOrDeployWrapped(originalToken, …)
IBridgeToken(wrapped).mint(to, amount);
emit WrappedTokensMinted(wrapped, to, amount);
```

### Step 3 — BURN AND RELEASE.

Going back, the bridge burns the wrapped copy and calls the proxy that stands for the origin bridge. When the origin chain runs that entry, receiveTokens releases the locked token. The ETH scenarios skip Bridge.sol; the step 1 test runs this path.

```text
// OTHER CHAIN · bridgeTokens(wrapped, amount, …)
TokenInfo memory info = wrappedTokenInfo[token];
if (info.originalToken != address(0)) {
// Wrapped token: burn and trace back to original
IBridgeToken(token).burn(msg.sender, amount);
// payload names info.originalToken, info.originalRollupId
⋯
(bool success, bytes memory reason) = bridgeProxy.call(payload);

// ORIGIN CHAIN · receiveTokens, via onlyBridgeProxy
if (originalRollupId == rollupId) {
// Token is native to this chain → release locked tokens
IERC20(originalToken).safeTransfer(to, amount);
emit TokensReleased(originalToken, to, amount);
```

## Next

[How to get your contract's address on another rollup](https://eez-demos.vercel.app/dapp-developers/q7-your-cross-chain-address.html), in the Reference track.

---

Whole site for agents: https://eez-demos.vercel.app/llms.txt
