# Task 5 — the four rollup-operator pages

**Verdict: all four ship with fixes. Five Blocking findings across the track, and the two worst — `ro2` and `ro4` — are invented values captioned as real.**

| Page | Verdict | Blocking |
|---|---|---|
| `ro1` · Run the devnet with Kurtosis | Ship with fixes | 1 (B5) |
| `ro2` · Deploy the protocol | Ship with fixes | 2 (B3, B4) |
| `ro3` · Run a real Chiado L2 | Ship with fixes | 1 (B1) |
| `ro4` · Send and test cross-chain calls | Ship with fixes | 1 (B2) |

**Method.** Nothing was executed — no Docker, Kurtosis, forge, make or RPC calls. Every command was compared string-by-string against upstream `eez-rollup0` at the pin `a4b9b2f1da1208c0f4f9c5b2ff4e45d6281ad1d2`. Where this document says a command *will fail*, that is read from upstream's own guards and placeholder values, not from a run. Page content was read from `rollup-operators/*.html` in the worktree at `33cf510`, never from `llms-full.txt`.

## Blocking

### B1 — `ro3` strips upstream's guidance from the `.env.chiado` path

`ro3:189-191` puts `cp .env.chiado.example .env.chiado` immediately above `docker compose --env-file .env.chiado -f docker-compose.chiado-node.yml up`. Upstream `.env.chiado.example` ships `EEZ_L1_POSTER_KEY=0xCHANGE_ME` (L35), `EEZ_PROOF_SIGNER_KEY=0xCHANGE_ME` (L37) and `EEZ_L2_SYSTEM_KEY=0xCHANGE_ME` (L42). Those are not valid hex private keys, so the copied file cannot boot the stack as shown.

**Be fair about what is site-specific.** Upstream's README has the identical two-line, no-edit-shown structure, so the *shape* is inherited, not invented. The regression is an **asymmetry inside `ro3` itself**: `ro3:178` annotates the other copy —

```
$ cp .env.example .env
# EEZ_L1_RPC_URL · EEZ_L1_POSTER_KEY · EEZ_PROOF_SIGNER_KEY · EEZ_L2_SYSTEM_KEY
```

— while `ro3:189` carries nothing, and upstream README L104 *does* annotate it: `cp .env.chiado.example .env.chiado    # host paths + funded keys + bundler URL`. The comment existed upstream and was dropped here.

**Second half of the same defect: `ro3` never says `EEZ_PROOF_SIGNER_KEY` must be the same key used at deploy.** Upstream states it three times:

| Source | Statement |
|---|---|
| `scripts/deploy.sh:45` | `AUTHORIZED_SIGNER="$(cast wallet address --private-key "$EEZ_PROOF_SIGNER_KEY")"`, consumed at `:126` |
| `.env.chiado.example:36` | "Proof signer — MUST equal `ECDSAProofSystem.signer` set at deploy time" |
| README L83 | "(its address becomes the proof system's `authorizedSigner`)" |

A grep of `ro3` for `signer` / `authoriz` / `same key` / `deploy time` returns only container and image names. A reader who generates a fresh key at this step gets a stack that boots, produces blocks, and has **every attestation rejected on L1** — silent, and expensive to debug.

**Fix:** annotate `ro3:189` the way `ro3:178` is annotated, and carry upstream's sentence: the proof signer key must be the same one `deploy.sh` used, because its address is the proof system's `authorizedSigner`.

### B2 — `ro4` presents invented numbers as measured results

`ro4:227` (HTML comment): *"STEP 3: the real test driver, the full matrix, real reported metrics"*. The rendered box:

| `ro4` line | Rendered |
|---|---|
| `:248` | `N+1 next-slot hit-rate` **`100%`** |
| `:249` | `bundle drops/evictions` **`0`** |
| `:250` | `divergence` **`none`** |

The metric *names* are real (`scripts/xchain-test.sh:24-25`, `:263-264`). The *values* appear nowhere upstream at the pin. Upstream's actual output shape, `xchain-test.sh:263-264`:

```
N+1 next-slot hit-rate: $n1 | postBatch L1 blocks: consecutive=$consec gapped=$gap
bundle target-misses(drops)=$drops evictions(3-strike)=$evict | divergence=$div reconcile=$recon
```

`$div` is numeric — `:266` tests `"$div" -eq 0` — so upstream prints `divergence=0` and never `divergence: none`. The page doubles down in prose: `ro4:280` promises *"how you read real pass/fail numbers"*, `ro4:285` says it *"reports real pipeline metrics"*. A repo-wide grep for `illustrat|sample output|example output|not real|representative` returns zero hits — nothing anywhere labels this box as an example. And a perfect score contradicts `ro4`'s own step 2, which warns that the builder silently drops txs.

One mitigation, stated precisely: `assets/eez-tour.js:153` carries *"Not pseudocode… the exact file and line, pinned to a commit"* — but that promise is scoped to the right-hand code panel, and the metrics box is the left-hand diagram. It does not cover this box, the box carries no illustrative label, and the page says "real" twice. The finding stands.

**Fix:** label the box as the output *format*, or reproduce the real shape with placeholders (`divergence=<n>`) instead of a perfect score.

### B3 — `ro2`'s `make deploy-protocol` cannot run as shown

`scripts/deploy.sh:33-36` hard-fails on four variables, each via the `:?` form — `: "${EEZ_L1_RPC_URL:?EEZ_L1_RPC_URL not set in .env}"` and the same for `EEZ_L1_POSTER_KEY`, `EEZ_PROOF_SIGNER_KEY`, `EEZ_L2_SYSTEM_KEY`. `Makefile:3` says it outright: *"Reads configuration from `.env` (gitignored). Copy `.env.example` first."*

`ro2` never mentions creating `.env`. Its four references — `:198` (`.env` file header), `:209`, `:243`, `:286-288` — all treat the file as already existing. That makes the page's whole thesis false for a first run: `ro2:163` *"ONE COMMAND"*, `:174` *"One script, one run"*, `:209` *"no paste-the-address-into-.env step"* alongside `:243`'s framing of zero manual config.

Sharper still: **the site contradicts itself.** `ro3:177-178` does show `cp .env.example .env` with the four variables named. Two pages on the same track disagree about whether `.env` setup is a step.

**Fix:** put `cp .env.example .env` and the four required variables on `ro2` before the `make deploy-protocol` block, as `ro3` already does.

### B4 — `ro2` captions three invented addresses "Three real addresses"

`ro2:185-187` render, under an `OUTPUTS · deployments.env` header:

```
EEZ_REGISTRY_ADDRESS=0x9F2c8a41B7D3e6F1024AaC8e5D6B7F3A1C9E0D42
EEZ_ECDSA_PROOF_SYSTEM_ADDRESS=0x4C1A7Fe9B3D2568e1Aa0Fc3B6D9E7A2F58C0B144
EEZ_ROLLUP_MANAGER_ADDRESS=0x7B3E9A2C5D4F1608eE0Ab7D3C6F9A21B4E8D5C77
```

`ro2:189` captions them: *"Three real addresses, written once by deploy.sh — nothing to copy by hand."* All three grep clean against every upstream file at the pin.

Separately, the real template at `scripts/deploy.sh:262-289` writes **19 keys, not three** — including `EEZ_VKEY`, `EEZ_ATTESTER_ADDRESS`, `EEZ_ROLLUP_ID`, `EEZ_INITIAL_STATE_ROOT`, `EEZ_L2_GENESIS_PATH`, three bridge addresses, and `EEZL2_ADDRESS=0x4200000000000000000000000000000000000007`.

Same class as B2, and the more literal falsehood of the two, because it applies the word *real* to values that were made up.

**Fix:** drop "real", or show the actual `deployments.env` template.

### B5 — `ro1` drops upstream's Linux-host requirement

`testing/kurtosis/README.md` §1: *"The local network requires: - A Linux host with Docker running and enough free space to build three images."*

`ro1:241` says instead: *"The whole stack runs on your own machine, once Docker and the Kurtosis engine are running — all local tooling, plus the real contract source pulled in via submodule, with nothing else to install."* `grep -ci linux` on `ro1` returns 0. The prereq chip row at `ro1:148-158` — Docker, Kurtosis CLI, Foundry v1.7.1, Bash, Git, GNU timeout, jq, curl, openssl — carries no OS constraint.

This is a claim upstream directly contradicts, aimed at a developer audience that is substantially on macOS. `ro1` also drops three other upstream prerequisites: *"enough free space to build three images"*, *"Network access to pull container images"*, and README §2's *"It can take several minutes."*

**Fix:** add the Linux-host constraint to the prereq row, and carry the disk/network/duration notes into the step-1 intro.

## Protocol accuracy

- **A1 — `ro2` under-enumerates the deploy sequence.** `Makefile:52-59` describes *"the 5-step deploy sequence"*, including *"5. DeployBridgeL1 → L1 cross-chain bridge contracts"*. `ro2:174` asserts *"deploy.sh brings up all three, in order, every time"*, and repeats the same three at `:237` and `:241`. `RegisterRollup` and `DeployBridgeL1` are missing. **This is not a contradiction with `ro3`** — `ro3:182` lists `deployments.env` *variables*, `ro2` lists deployed *components*; different objects. The defect is under-enumeration measured against the Makefile alone. → say five steps, and name them.
- **A2 — `ro2`'s "zero manual config" framing overstates the Makefile's own narrower claim.** The panel quotes the true version — *"without any paste-the-address-into-.env step"* (`:286-288`) — and the headline generalises past it. `Makefile:69-71` refuses to run `run-node` without `EEZ_L2_DATADIR` and `EEZ_L2_GENESIS_PATH`, telling the operator to *"copy .env.example to .env"*. → say "no address-pasting step" and stop there.
- **A3 — `ro3`'s one-time setup block drops upstream commands, and one omission breaks the next line.** Upstream README L52 has `git submodule update --init --recursive`; L69 has `mkdir -p configs && cp -r …`. `ro3:155-164` shows the bare `cp -r /tmp/gnosis-configs/chiado configs/chiado`, which fails if `configs/` does not exist — that half is unambiguous. The submodule omission is load-bearing too: `testing/kurtosis/start.sh:16-20` hard-exits on an uninitialised `eez-core-protocol`. → restore both commands. *Not claimed:* that `mkdir -p data` is required — Docker creates the bind-mount path. The most that can be said, and it is **unverified**, is that a root-owned `data/` would break `openssl rand -hex 32 > data/jwt.hex` at `ro3:161`.

## Would make this better

- **W1 — `ro4` declares no prerequisite at all.** `xchain-test.sh:10` says *"Bring the node up first (scripts/chiado-up.sh)"*; `:62` checks the container and `:64` checks `deployments.env`. State the mechanism correctly: the reader does **not** get connection-refused — `xchain-test.sh:62` fails first and cleanly with `✗ container 'eez-node-chiado' not up — run scripts/chiado-up.sh`. One related line worth carrying: `ro4:176-192` and `:331-334` hardcode `:18688` / `:18645` / `:18999` / `:18998`, and `xchain-test.sh:42` defaults `NODE_CONTAINER` to `eez-node-chiado` — these are chiado-compose values, not devnet ones, because Kurtosis assigns dynamic host ports and exports `EEZ_DEVNET_*` (its README §4). **The `ro1`→`ro4` path is not broken:** site nav is ro1→ro2→ro3→ro4 (`ro1:138`, `ro2:154`), and `ro3` brings up exactly the stack `ro4` assumes. → name the prerequisite, and label the port table as the compose stack's.
- **W2 — `ro1` drops the Kurtosis key-safety warning.** `testing/kurtosis/README.md:7-8`: *"The included configuration contains deterministic private-network keys. Never use these keys on a public network or fund them with real assets."* One sentence, and it is the only safety line upstream puts in that README. → carry it.
- **W3 — `ro1` has no teardown.** The page starts a full private PoS L1 plus MEV stack, a node, a signer and two Blockscout instances, and then stops. `bash testing/kurtosis/stop.sh` is one line, and upstream flags it as destructive and `KURTOSIS_ENCLAVE`-sensitive. → add it as a closing step, with the destructive note.
- **W4 — `ro3` teaches only the manual flow.** Upstream README leads with *"One command: `bash scripts/chiado-up.sh`"* and calls the numbered steps *"that same flow done by hand."* The manual version is the better teaching choice and should stay — but one pointer to `chiado-up.sh` gives the reader the shortcut once they understand the steps. Two smaller items on the same page: `ro3` uses `cast` without listing Foundry as a prerequisite, where `ro1` does list it (pinned v1.7.1); and `ro3` names `EEZ_L1_RPC_URL` at `:178` and `:308` without carrying README L74-78's requirement that it be tip-synced at deploy time, while `.env.example:13` ships `EEZ_L1_RPC_URL=http://37.27.238.19:18545` — a team devnet, not a public Chiado endpoint — as the default a reader inherits. *Not claimed:* that `EEZ_L1_RPC_URL` must never point at `:18645` — `docker-compose.chiado-node.yml:88` sets exactly that at runtime by design. The constraint is deploy-time only.

## What this gets right

- **R1 — key hygiene is clean and deliberate.** No page prints a private key. All ten Anvil/Hardhat default keys grep repo-wide with zero hits; there is no 32-byte hex string on any of the four pages; `ro3` names its four keys and fills in none of them. Pointed version: the Kurtosis README that `ro1` quotes publishes a funded devnet key two sections past where `ro1` stops, and `ro1` does not carry it across. That key is the **public Hardhat account #2 default**, which upstream itself labels as such — so the credit is for not copying a confusing value onto a page, not for protecting a secret.
- **R2 — `ro4`'s friction box is the best content on the track.** It puts `EEZ_MAX_USER_TXS_PER_BUNDLE=3` (`:214`) and *"rbuilder-chiado silently drops the excess beyond ~3 — that's lost tx inclusion, not a queued retry"* (`:221`) on the page as a first-class warning. It keeps upstream's `~3` hedge instead of hardening it to `3`, and "lost tx inclusion, not a queued retry" is exactly the builder-cooperation caveat — carried without ever using the word *atomic*.
- **R3 — `ro1` is materially correct end to end.** Three steps, three upstream command blocks, right order, right dependencies. `start.sh:16-30` independently confirms the ordering by failing loudly when the submodule is missing or stale.
- **R4 — every file path the four pages name exists at the pin.** `.env.example`, `.env.chiado.example`, `docker-compose.chiado-node.yml`, `Dockerfile.signer`, `testing/kurtosis/{start,stop,ports}.sh`, `ci-args.yaml`, `scripts/xchain-test.sh` — all HTTP 200 at `a4b9b2f`.
- **R5 — the version-pinned externals need no change.** `ghcr.io/gnosischain/reth_gnosis:v2.0.0` (`ro3:160`) and the `gnosischain/configs` clone (`ro3:162`) are reproduced verbatim from upstream, which does not pin the clone either. `v2.0.0` is an immutable-by-convention tag on a first-party Gnosis registry, and the configs clone must track the network, so pinning it would be wrong. The plan asked whether a dated note is warranted here: it is not.

## What the automated layer cannot see here

**No operator page is drift-checked at all.** `check-panel-drift.py`'s `SNIPPET_MAP` covers only the seven Solidity pages. `verify-citations.py` proves that cited files and line numbers exist upstream — never that the *commands shown on the page* appear in them. For `ro1`, `ro3` and `ro4`, whose citations name a README with no line range, it checks essentially nothing about the commands. **This desk-check is the first comparison ever made between these four pages and upstream.**

Second gap, same layer: **`ro2` and `ro4` emit a metadata header and zero steps into `llms-full.txt`** (worktree lines 1002-1010 and 1085-1090). `build-llms.py:79-80` only matches arrays of string literals, and both pages build `codeByStep` from `.slice()` calls. So `ro4`'s entire bundle-cap warning — the best content on the track, R2 above — reaches no reader of that file. Cross-reference Task 7.

## What I could not verify

- That **any** command on these pages succeeds. Nothing was executed.
- That `ghcr.io/gnosischain/reth_gnosis:v2.0.0` exists, and that its `download --chain chiado --minimal` subcommand works as `ro3:159-160` shows.
- That `faucet.chiadochain.net` is live.
- Kurtosis behaviour on macOS. Upstream says Linux; untested either way.
- The exact runtime port assignment of a Kurtosis enclave. B5/W1 rest on upstream's own statement plus `ports.sh`, not on an observed enclave.
- The EIP-55 checksums of `ro2`'s three invented addresses — no keccak available. Irrelevant to B4, which is that they are invented.
- Anything about upstream HEAD `d8a7547`. Out of scope: Task 1 confirmed all four operator pages cite only files untouched between the pin and HEAD.

**Courtesy flag to upstream, not a finding against this site:** `scripts/xchain-test.sh:52` hardcodes a funded operator key in the public `eez-rollup0` repo (`OP=0x2248a31…`), plus Hardhat account #2 at `:53`. No `eez-demos` page quotes either — 0 hits repo-wide. It is used only against chain-id 10200 (asserted at `:63`), Gnosis Chiado, a faucet testnet, so the exposure is testnet xDAI. No RPC was queried, so no claim is made about its balance. In scope for `eez-demos`: nothing.

**The pre-mainnet disclosure regression applies to all four of these pages too** — already recorded as BLOCKING in `02-trust-claims.md`, not re-reported here.
