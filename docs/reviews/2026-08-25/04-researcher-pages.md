# Task 4 — protocol-researcher pages (pr1–pr5)

**Two pages must not ship as written.** `pr2` and `pr3` each teach a mechanism their own source contradicts, and in both cases the error is in the diagram — the surface no checker inspects.

| Page | Verdict | Blocking | In-panel annotations |
|---|---|---|---|
| pr1 · four components | Ship with fixes | 0 | 5/5 correct |
| pr2 · commit-first | **Don't ship — conceptual problem** | 4 | 3/4 correct (1 fabricated quote) |
| pr3 · the deriver | **Don't ship — conceptual problem** | 2 | 2/5 correct |
| pr4 · composer proves a batch | Ship with fixes | 0 | n/a (1 misattribution) |
| pr5 · address derivation | **Ship it** | 0 | 3/3 correct |

Method: nothing compiled or executed. All claims read from upstream at the pins — `eez-rollup0` @ `a4b9b2f`, `eez-core-protocol` @ `9735f53` — fetched via `raw.githubusercontent.com`. `git diff --stat 33cf510 -- protocol-researchers/` is empty, so these five files are byte-identical to what the site serves. The four decisive claims below were re-verified a second time, independently, before this document was written.

The site-wide pre-mainnet regression, `pr4`'s missing ECDSA disclosure and `pr1`'s "trusted downstream" phrasing are recorded in `02-trust-claims.md` and not repeated here.

## Blocking

### pr2-B1 — a fabricated return type, inside the page's own "verified verbatim" guarantee

The panel writes `pub fn begin(…) -> OptimisticallyIncluded {`. Source, `optimistic.rs:117-123`:

```rust
pub fn begin(
    &self,
    sync_height: u64,
    post_batch_hash: TxHash,
    parent: SealedHeader<alloy_consensus::Header>,
    txs: Vec<HeldTx>,
) {
```

`begin` returns **unit**. The page's own source comment claims *"Only optimistic.rs:101, 117, 177 and 191 are verified verbatim quotes … never an invented body."* The return type is invented API surface inside that guarantee — the one line the page did not elide is the one it fabricated.

### pr2-B2 — the fabricated type produces the wrong mental model, and the whole diagram rests on it

`optimistic.rs:101-103` is `pub struct OptimisticallyIncluded { by_sync_height: Mutex<BTreeMap<u64, InFlight>> }` — a **ledger**, one per cross-chain rollup, not a per-call state object. Per-batch state is `InFlight`; the state machine is the private `enum Resolution { Pending, Settled, Failed }` (`:67-74`). The three panels label the container as the state and animate it changing colour (`OptimisticallyIncluded [OPTIMISTIC] → [SETTLED] / [REPAIRED]`). That transition does not exist.

### pr2-B3 — "mark_settled / mark_failed are the only two exits" is false, and the missing exit is the page's own thesis

`resolve_below_cursor` (`optimistic.rs:160`) flips Pending **and Failed** entries at or below the deriver's cursor to Settled. Its doc comment says why: *"the cursor only advances past a batch after `check_claimed_state` accepted it, which is a stronger settlement proof than the observer's log scan. A Failed verdict is overridden here: a false-negative observation must not undo a batch the Deriver confirmed."* A page titled *"How L1 stays the source of truth"* has omitted the one path where the L1-derived cursor overrules the observer.

### pr2-B4 — "the optimistic state is now permanent" is false

`take_rolled_out(new_l2_cursor)` (`:247`) deletes every **Settled** batch above a retreated cursor on an L1 reorg and re-queues its txs — while Pending entries stay. Entries leave only at finality via `take_finalized` (`:270`), and even then the doc notes they are *"NOT dropped blind: the caller verifies each postBatch receipt still exists on L1 before discarding."* Settled means "L1 said yes for now."

**pr2 fix:** the honesty policy ("fields omitted — signature verified, body not") is not the problem and should survive. The problem is that with every body elided the diagram becomes the entire teaching surface, and three of the four things it asserts are outside what that policy covers. Redraw against `Resolution`, add the `resolve_below_cursor` path, and delete the invented return type.

### pr3-B1 — `rollupCount` is misread, and the misreading drives the page's climax

`EEZ.sol:152-153`:

```solidity
/// @notice Emitted when a batch is posted, carrying the number of rollups verified
event BatchPosted(uint256 indexed rollupCount);
```

emitted at `EEZ.sol:442` as `emit BatchPosted(batch.rollupIdsWithProofSystems.length);`. It is **the number of rollups settled in this batch** — for a single-rollup batch, `1`. pr3 renders it as a monotonic batch ordinal: step 1 shows `rollupCount (indexed) = 4,821` and step 3 draws `Batch 1 ··· Batch 4819 · Batch 4820 · Batch 4821` marching from L1 genesis to head. Step 2 then reuses `4,821` a third way, as the rebuilt L2 block number. Three distinct quantities collapsed into one number, on the page whose only subject is that event.

### pr3-B2 — `catch_up()` does not walk L1 history

Step 3's header is `CATCH_UP() · WALK L1 GENESIS → HEAD`. `catch_up_inner` (`deriver.rs:238-249`):

```rust
match anchor {
    Some(anchor_l1_block) => self.sync_batches_inner(anchor_l1_block, cursor).await,
    None => self.sync_batches_inner(self.inner.deploy_block, 0).await,
}
```

Cold start scans from **`deploy_block`**, not genesis. Warm start resumes from the highest still-canonical indexed batch returned by `revalidate_index_tail` (`:256`), which first walks the index tail *backward*, dropping batches whose recorded L1 hash is no longer canonical (`"L1 reorg rolled out confirmed batches; L2 safe cursor retreated"`, `:291-301`). A researcher sizing follower sync off "genesis" is wrong by the entire pre-deploy history — and misses that the reorg-revalidation pass is what makes derivation sound.

## Protocol accuracy

- **pr1 — "the live path runs on just the first two" is false in both directions.** Ordinary L2 blocks are the *sequencer alone*; the composer is not involved. A Sync slot *blocks on the proof-signer*: `composer.rs:2864` calls `prove_with_retry(...)` synchronously, and only on its return do `batch.proofs`, the calldata encode, the bundle dispatch and `rollup.optimistic.begin(…)` (`composer.rs:2026`) follow. There is no two-component path. Fix: *"Ordinary blocks are the sequencer alone. One Sync block per L1 block adds the composer — and that block cannot be emitted until the proof-signer returns an attestation."*
- **pr4 — "MAX_MESSAGE_BYTES = 1 GiB, encode + decode, both sides" is true of the client and false of the server.** The page faithfully reproduces `crates/eez-control-rpc/src/lib.rs:17-19`, whose doc comment says the limit applies to *"BOTH the client (encode) and server (decode)"*. The client honours it. The server does not: `eez-proof-signer/src/service.rs:184-186` sets decode to `max_decoding_message_bytes()` = `window_limits.payload_bytes.min(MAX_DECODING_MESSAGE_BYTES)` with the ceiling at **256 MiB** (`:26`), and encode to `MAX_ENCODING_MESSAGE_BYTES` = **1024 bytes** (`:29`, *"ProveResponse contains only a 32-byte digest and 65-byte signature"*). Server decode is 4× smaller than the page says; server encode is ~1,000,000× smaller. Tell the author their *source* drifted, not just the number — the stale claim is upstream's own doc comment.
- **pr4 — that constant is attributed to the wrong file.** It sits under a citation chip reading `crates/eez-control-rpc/proto/prove.proto · prove.v1.Prover`, beneath a comment claiming all lines are verbatim from the proto. `MAX_MESSAGE_BYTES` is Rust in `lib.rs` and is not in the `.proto` at all. Same defect class as pr3's `abi.rs` path, on a second page.
- **pr4 — "verbatim" is true of code and false of comments.** `// Header MUST be first; blocks follow in order.` abridges `// Header MUST be the first chunk; blocks follow in ascending block order.`; `// posted + 1` drops `(OD-5 anchor + 1)`. Every code line checked is byte-exact including column alignment. Either restore the comments or drop the word.
- **pr3 — `RollupL1` is an invented contract name.** Step 1 labels the emitter `0xA9c1…04Fe (RollupL1)`. No such name exists in either repo, and it appears exactly once on the whole site. The emitter is `contract EEZ` (`EEZ.sol:54`); rollup0's `abi.rs:1-4` says the L1 types *"mirror IEEZ.sol"*. Fix: `(EEZ)`.
- **pr3 — three in-panel annotations wrong** (found in Task 1, re-confirmed): `// deriver.rs:504` → `execute_block` is at `:516`; `// deriver.rs:774` → `handle_event` is at `:786`; `// abi.rs:105` → line right, path wrong (`crates/eez-protocol/src/abi.rs`).
- **pr2 — "begin() commits the L2 block"** — `begin` records; it does not commit. `composer.rs:2024` logs *"committing Sync block optimistically"* and `:2026` then calls `optimistic.begin(…)`. Two adjacent acts. On a researcher page that distinction is the point: the commit is the committer's, and `begin` is the bookkeeping that makes it repairable.

## Would make this better

- **pr1 — signatures stripped of their bounds teach nothing.** The panel renders `pub struct Sequencer<T, ChainSpec> { ... }` and `pub struct Deriver<L2> { ... }`, silently dropping `where T: PayloadTypes<PayloadAttributes = EthPayloadAttributes>` (`sequencer.rs:160-162`) and `where L2: BlockReader` (`deriver.rs:46-47`) — while `Composer<L2: BlockReader>` keeps its bound inline, so the panel is inconsistent with itself. `Deriver<L2>` is the clearest loss: it reads as unbounded generic bookkeeping, and `BlockReader` is the only thing in it that says what a deriver *is*.
- **pr1 — say that "four components" is a role decomposition, not a crate list.** Rollup0 has 12 crates. One sentence stops a reader hunting for `eez-l1` in the diagram.
- **pr3 — say where the batch data comes from.** Step 1 correctly shows `data (empty — nothing but the indexed topic)`, then step 2 says the block is derived "from the L1 data itself", leaving an empty log and no payload. The payload is the posting transaction's calldata: `on_batch_posted` (`deriver.rs:836`) opens with `let decoded = eez_payload_codec::decode(call_data.as_ref())?;` (`:849`). The log is the trigger; the calldata is the data. One line makes the empty-`data` detail land as a design choice rather than a curiosity.
- **pr3 — `handle_event` reacts to four things, not one.** `deriver.rs:787-832` matches `BatchPosted`, `NewHead`, `Reorg` → `on_l1_reorg`, `Finalized` → `on_l1_finalized`. For a page arguing L1 is the only trust anchor, the reorg and finality arms are more persuasive than the happy path.
- **pr4 — the panel skips `ProveChunk`**, the `oneof` that makes "header first" expressible at all. Step 1 shows the byte-strip diagram with no wire type behind it; four lines connect the picture to the protobuf.
- **pr5 — the calculator will compute a confident address for the local rollup id.** `computeCrossChainProxyAddress` has no `SameNetworkProxy` guard (`EEZBase.sol:176-185`) while `_createCrossChainProxyInternal` does (`:165-166`), and pr5's TRY IT panel defaults `originRollupId = 1` and accepts anything. q7 already teaches this and points step 3 at `:166`; pr5 cites only `:176`. One sentence beside the `not deployed yet` badge makes the two pages consistent. Same defect the dapp track carries as A3 in `03-dapp-pages.md`.
- **pr5 — vocabulary.** The diagram and calculator say `originRollupId` / `myContract`; source, snippet and q7 say `originalRollupId` / `originalAddress`. Keep the friendly labels, add the real names once, so grep works.

## What this gets right

- **pr4 is the best-verified page on the site, and "MUST BE FIRST" is enforced rather than merely documented** — the detail it could most easily have taken on faith. `window.rs:150-151` defines `BlockBeforeHeader { number: u64 }`, `:154-155` `DuplicateHeader`, and `WindowAssembler::start` (`:237`) rejects a block arriving first. Exactly one header, first, or the stream is refused.
- **pr4's step-3 trust claim is the strongest sentence on any of the five pages:** *"The signature only counts once it recovers to the registered attester — that check is the real gate, not the response arriving."* That is `prover-client/src/lib.rs:128-133` and `verify_attestation` (`:178-206`), comment and all: *"Fail-closed: the attestation must recover to the REGISTERED attester over the hash the prover signed."*
- **pr5 does not overclaim chain-independence**, which is the trap on that page. Both times it generalises, it generalises about the **salt**, and step 3 names `manager` and `bytecodeHash` as further CREATE2 inputs. The `not deployed yet` badge is the right honesty at the right pixel.
- **pr5 is the only page here with zero annotation defects**, and the reason is structural: it pins its derivation at a SHA in the snippet header and is drift-checked against `snippets/q1-compute-address.sol`. That is the pattern the other four should copy.
- **pr1 quotes a real function body** (`attest.rs:137`, `self.signer.sign_prehash(public_inputs_hash.into_inner())`) — the one place on this track where a panel earns being a panel rather than a diagram.
- **pr3 shows `async fn handle_event` without `pub`** — it did not quietly promote a private fn to make it look like API.

## An architectural observation pr4 did not ask for

`verify_attestation` recovers over `resp.public_inputs_hash` — the hash the *prover returned* — and the client never compares it against the hash the composer claimed in `ProveHeader`. A prover that signs a different-but-well-formed hash with the registered key passes the client-side gate and fails later, on L1, inside `postAndVerifyBatch`. That is defensible (the contract is the authority), but it means the composer-side check answers *"who signed this"*, not *"did they sign my batch"* — and the page's own framing ("that check is the real gate") invites the stronger reading.

## Every in-panel annotation, checked

`verify-citations.py` covers the citation block only. These are the `// file:NNN` strings written inside panels and diagram chips — 15 sites across five pages.

| Page | Annotation | Verdict |
|---|---|---|
| pr1 | `sequencer.rs:159`, `composer.rs:515`, `attest.rs:52`, `attest.rs:134`, `deriver.rs:45` | **all 5 correct** |
| pr2 | `optimistic.rs:101`, `:177`, `:191` | correct, verbatim |
| pr2 | `optimistic.rs:117` | **line correct, quote WRONG** — returns unit, `-> OptimisticallyIncluded` fabricated |
| pr3 | `deriver.rs:45`, `deriver.rs:169` | correct, verbatim |
| pr3 | `deriver.rs:504` | **WRONG** → `:516` (504 is `}`) |
| pr3 | `deriver.rs:774` | **WRONG** → `:786` (774 is `Err(err) => {`) |
| pr3 | `abi.rs:105` | **PATH WRONG** → `crates/eez-protocol/src/abi.rs`; line is exact |
| pr4 | *(no `file:NNN`)* | `MAX_MESSAGE_BYTES` **misattributed** to `prove.proto` |
| pr5 | `EEZBase.sol:176` (×3: chip, `data-demo-cite`, snippet header) | **all correct** |

**10 correct, 4 wrong, 1 misattributed.** pr1 and pr5 are clean; pr2 and pr3 are not; pr4 carries the same wrong-path defect in a form a `file:NNN` grep cannot even catch.

## What could not be verified

- Nothing compiled or executed: no cargo, rustc, forge or solc were used for this task.
- Illustrative values were not checked and largely cannot be: pr4's `1,412 bytes` / `118 nodes / 4 codes` / `62 keys / 1 header`; pr3's `0xA9c1…04Fe` and `state_root: 0x9a2c…f1d0`; pr5's `0x7d3F…9bA1` worked example.
- `assets/eez-hash.js`, which powers pr5's calculator, was not audited. pr5's derivation is verified *as displayed*; whether the calculator implements it is unverified.
- Server-side `window_limits.payload_bytes` is operator-configured. The pr4 finding rests on the 256 MiB ceiling and the clamp, not on a deployed value.
- `eez-l1`'s log-scanning internals were not read; pr3's calldata claim rests on `deriver.rs:836-849`, read directly.
- Upstream HEAD `d8a7547` was not re-examined — the pin is HOLD at `a4b9b2f` per `01-pin-decision.md`.
