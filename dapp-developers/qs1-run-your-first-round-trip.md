# Run Your First Round Trip

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

Two scenarios pass on local anvil chains: a call that starts on L1 gets back the value L2's execution produces (locally, precomputed in the entry), then the same call runs the other way round.

- Page: https://eez-demos.vercel.app/dapp-developers/qs1-run-your-first-round-trip.html
- Source: `eez-core-protocol/script/e2e/run/local/parallel.sh:17 · parallel.sh`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/script/e2e/run/local/parallel.sh#L17

### Step 1 — CLONE AT THE PIN.

Clone at a fixed commit so your output matches these cards. You need Foundry 1.7.1 with forge, cast and anvil on PATH, Git, jq (recent macOS ships it), and bash 4 or newer (macOS ships 3.2; brew install bash puts bash 5 first on PATH). No Docker.

```text
# needs Foundry 1.7.1 (forge, cast, anvil on PATH),
# Git, jq, and bash 4+. No Docker.
# Foundry: https://book.getfoundry.sh/getting-started/installation
# macOS ships bash 3.2; this puts bash 5 first on PATH:
#   brew install bash
# jq: recent macOS ships it, or brew/apt install jq

$ git clone https://github.com/eez-association/eez-core-protocol.git
$ cd eez-core-protocol
$ git checkout -q 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f
$ git submodule update --init --recursive
```

### Step 2 — BUILD AND RUN BOTH DIRECTIONS.

One build, then both scenarios at once. About 5 minutes on an Apple M4 with Foundry 1.7.1 and solc already cached; the first build is most of it.

```text
# the first build is most of the time
$ forge build

$ bash script/e2e/run/local/parallel.sh counter counterL2
  [counterL2] starting (L1=18547 chain=41339, L2=18548 chain=41340)
  [counter] starting (L1=18545 chain=41337, L2=18546 chain=41338)
  [counterL2] PASS
  [counter] PASS

===== RESULT: 2 passed, 0 failed, 0 skipped =====
```

### Step 3 — WHAT THAT PASS PROVED.

Locally, the scenario script played composer. You'll see what it did in two cards.

```text
# counter:   L1 called L2, got 1 back
# counterL2: L2 called L1, got 1 back

  [counterL2] PASS
  [counter] PASS

===== RESULT: 2 passed, 0 failed, 0 skipped =====
```

## Next

[Read Your Side of It](qs2-read-your-side-of-it.md)

---

Whole site for agents: https://eez-demos.vercel.app/llms.txt
