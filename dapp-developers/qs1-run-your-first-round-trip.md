# Run Your First Round Trip

> EEZ is pre-mainnet: read capability claims as design intent, not shipped behaviour. Every code block is cited at a pinned commit.

Two scenarios pass on local anvil chains: one call starts on L1 and gets back the value L2's execution produces, and one makes the same call from L2. Locally, that value is precomputed in the entry.

- Page: https://eez-association.github.io/eez-demos/dapp-developers/qs1-run-your-first-round-trip.html
- Source: `eez-core-protocol/script/e2e/run/local/parallel.sh:17 · parallel.sh`
- Pinned at commit: `9a1f815`
- Verify: https://github.com/eez-association/eez-core-protocol/blob/9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f/script/e2e/run/local/parallel.sh#L17

**What this proves:** Both directions pass on local anvil chains, two per scenario: a call from L1 to L2 and a call from L2 to L1 each get the other side's return value back inside the calling transaction.

**What it doesn't:** It does not use real proofs or a live node. The script does the composer's job: it precomputes the return value into an entry, posts that entry before your call, and the batch is accepted by an accept-all proof system.

### Step 1 — CLONE AT A FIXED COMMIT.

Clone at a fixed commit so your output matches these cards. You need Foundry 1.7.1, with forge, cast and anvil on PATH. You also need Git, jq and bash 4 or newer; no Docker. macOS includes bash 3.2, and brew install bash puts bash 5 first on PATH. Step 2 builds and runs it.

```text
# needs Foundry 1.7.1 (forge, cast, anvil on PATH),
# Git, jq, and bash 4+. No Docker.
# Foundry: https://book.getfoundry.sh/getting-started/installation
# macOS includes bash 3.2; this puts bash 5 first on PATH:
#   brew install bash
# jq: recent macOS includes it, or brew/apt install jq

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

Locally, the scenario script did the composer's job. Card 03 (Who Answered?) shows what it did.

```text
# counter:   L1 called L2, got 1 back
# counterL2: L2 called L1, got 1 back

  [counterL2] PASS
  [counter] PASS

===== RESULT: 2 passed, 0 failed, 0 skipped =====
```

## Next

[Follow One Call There and Back](qs2-read-your-side-of-it.md)

---

Whole site for agents: https://eez-association.github.io/eez-demos/llms.txt
