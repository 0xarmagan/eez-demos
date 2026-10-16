# Cross-Chain Flash Loan

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

Borrowed tokens go to an L2 and back before the repayment check runs, all inside one L1 transaction.

- Page: https://eez-demos.vercel.app/dapp-developers/qs7-cross-chain-flash-loan.html
- Source: `eez-core-protocol/script/e2e/run/local/parallel.sh:17 · parallel.sh`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/script/e2e/run/local/parallel.sh#L17

### Step 1 — RUN IT.

One L1 transaction borrows 10,000 tokens, sends them to L2 and back, and repays the pool. Locally, the scenario script plays composer and posts the entries in a separate transaction first.

```text
# needs Git, jq, Foundry 1.7.1 (forge, cast, anvil on PATH)
# and bash 4+; macOS ships 3.2, so: brew install bash
# jq: recent macOS ships it, or brew/apt install jq
# fresh clone at the pinned commit
$ git clone https://github.com/eez-association/eez-core-protocol.git
$ cd eez-core-protocol
$ git checkout -q 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
$ git submodule update --init --recursive
$ forge build

# local anvil pair; the script plays composer
$ bash script/e2e/run/local/parallel.sh flash-loan
  [flash-loan] starting (L1=18545 chain=41337, L2=18546 chain=41338)
  [flash-loan] PASS

===== RESULT: 1 passed, 0 failed, 0 skipped =====
```

### Step 2 — BORROW ON L1, USE IT ON L2.

onFlashLoan sends the loan to executorL2 through Bridge.sol, then calls executorL2 through its proxy. On L2 it claims the NFT, and its return leg releases the escrow on L1 inside that same call.

```text
// L1 · FlashLoanBridgeExecutor.onFlashLoan
IERC20(_token).approve(address(bridge), amount);
bridge.bridgeTokens(_token, amount, l2RollupId, executorL2);
(bool success,) = executorL2Proxy.call(
  ⋯ abi.encodeCall(this.claimAndBridgeBack, (⋯))
);
require(success, "Cross-chain call failed");

// L2 · claimAndBridgeBack, reached through the proxy
FlashLoanersNFT(nftContract).claim();
uint256 balance = IERC20(wrappedToken).balanceOf(address(this));
// then bridgeTokens(wrappedToken, balance, ⋯): back to L1
```

### Step 3 — REPAID BEFORE THE TRANSACTION ENDS.

The pool checks its balance after onFlashLoan returns. It is whole only because the return leg already released the escrow on L1; otherwise the transaction reverts.

```text
// L1 · FlashLoan.flashLoan, the pool
uint256 balanceBefore = IERC20(token).balanceOf(address(this));
IERC20(token).safeTransfer(msg.sender, amount);
IFlashLoanReceiver(msg.sender).onFlashLoan(token, amount);
uint256 balanceAfter = IERC20(token).balanceOf(address(this));
require(balanceAfter >= balanceBefore, "Flash loan not repaid");

// last line of onFlashLoan, after the return leg
// 3. Repay (tokens are back from bridge release)
IERC20(_token).safeTransfer(msg.sender, amount);
```

## Next

[Bridge Tokens Both Ways](qs8-bridge-tokens-both-ways.md)

---

Whole site for agents: https://eez-demos.vercel.app/llms.txt
