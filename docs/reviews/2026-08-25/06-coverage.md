# Task 6 — coverage: what a dapp developer needs that the site does not teach

**Verdict: five of the six known app-dev traps are absent from the dapp track, confirmed by grep. Two of the five earn a page. Three are better served by one sentence on a page that already exists, or by a link to a spec section that is already written and already correct.**

| Trap | On the dapp track? | Costs |
|---|---|---|
| 1 · `msg.sender` is a `CrossChainProxy` | **Covered** — `q3`, with a runnable test | — |
| 2 · `balance` / `extcodesize` / `extcodecopy` / `delegatecall` describe the proxy; block opcodes describe the local chain | **Absent** | A page (`q8` candidate exists) |
| 3 · The same-block constraint | **Absent** | One sentence on `q2` (already commissioned as B1 in `03-dapp-pages.md`) |
| 4 · Outcomes are pre-committed in an `ExecutionEntry` before the tx runs | **Absent** | A page |
| 5 · A caller cannot distinguish "no matching entry" from "the destination reverted" | **Absent** | One sentence on `q2` + a link to `CAVEATS.md:9` |
| 6 · `value` and `callGas` semantics on a cross-chain call | **Partial** — both are unlabelled inputs on `q5`'s calculator | A note and an input constraint on `q5` + a link to `EXECUTION_ENTRY_SPEC.md:61-69` |

**Method.** Nothing was compiled or executed. The site side is grep against the six live dapp pages in the worktree (`dapp-developers/q2`,`q3`,`q4`,`q5`,`q6`,`q7`); `q1` is a 967-byte canonical redirect and is excluded. `llms-full.txt` was deliberately not read — it is being regenerated under Task 7, and it is the lossy surface, not the authoritative one. The protocol side is `eez-core-protocol` at the pin `9735f53abbb6b9f5e863f405ad4555b4701b7fda`, fetched over `raw.githubusercontent.com`, which Task 1 confirmed is also upstream HEAD. Findings already published in `03-dapp-pages.md` (B1, W1, W2) are cross-referenced, not re-reported.

## The confirmed coverage table

Counts are `grep -o -i -E` over `dapp-developers/q[234567]*.html`, deduplicated by hand against the syntax highlighter's keyword and identifier maps — which are JS object literals shipped on every page (`q2:428-444` and its siblings) and are not content a reader ever sees.

| Term | Hits | Where | Reads as coverage? |
|---|---|---|---|
| `extcodesize` | **0** | — | No |
| `extcodecopy` | **0** | — | No |
| `balance` | **0** | — | No |
| `chainid` | **0** | — | No |
| `coinbase` | **0** | — | No |
| `delegatecall` | 6 | `q2:442`, `q3:389`, `q4:350`, `q5:433`, `q6:379`, `q7:476` | **No** — one per page, all the highlighter's `"delegatecall":1` keyword entry |
| `blockhash` | 6 | `q2:440` and siblings | **No** — same map, `"blockhash":1` |
| `block.number` | **0** | — | No |
| `lastVerified` | **0** | — | No |
| `ExecutionNotInCurrentBlock` | **0** | — | No |
| `same block` | **0** | — | No |
| `ExecutionEntry` | **0** | — | No |
| `StaticExecutionEntry` | **0** | — | No |
| `rolling hash` | **0** | — | No |
| `revertNextNCalls` | **0** | — | No |
| `ExecutionNotFound` | **0** | — | No |
| `pre-comput` | 1 | `q5:215` | **No** — "every off-chain tool that pre-computes this", about tooling, not about the protocol pre-committing an outcome |
| `staticCrossChainCall` | 8 | `q2:305`, `q2:392`; 6 highlighter entries | Partial — real on `q2` only, in a code panel, never named in prose |
| `callGas` | 15 | `q5` only (`:165-166`, `:228`, `:326`, `:334`, `:341`, `:371`, `:377`, `:667`, `:678`, `:691`, `:705`) | **Partial** — a labelled `uint64` input and a hash argument, with no statement of when it is nonzero |

So traps 2, 3, 4 and 5 are absent in the strict sense: the vocabulary does not occur on the track at all, in any form, including the words a reader would search for after something broke. Trap 6 occurs as a field name with no semantics attached.

The upstream facts these gaps are measured against, each verified at the pin:

- **Trap 2** — `CAVEATS.md:11-13`, "Opcodes that differ on cross-chain proxies": `delegatecall`, `balance`, `extcodesize`, `extcodecopy` return information about the proxy itself; block-state opcodes reflect the chain the call is executing on.
- **Trap 3** — `EEZ.sol:794-797` gates the L1 mutating path (`if (verificationByRollup[destRid].lastVerifiedBlock != uint64(block.number)) revert ExecutionNotInCurrentBlock(destRid);`), as does `EEZL2.sol:228` on L2. **The rule is side-specific for reads:** `EEZ.sol:1308-1310` falls through to the persistent `staticEntryQueue` with no block gate, under the source's own comment *"Note that static calls do not obsolete after a block passes. As long as the state roots matches it can be execute"*, matching on `_stateRootsMatch` at `:1319`; `EEZL2.sol:634` **does** gate the L2 static path, with the docstring at `:588-589` giving the reason — *"no pins on L2 — the block gate bounds staleness"*. `STATIC_ENTRY.md:280-283` states both sides in one paragraph. No copy may state either rule flatly.
- **Trap 4** — `IEEZ.sol:126-135`. `ExecutionEntry` carries `bytes32 rollingHash` (`:131`), `bool success` (`:133`) and `bytes returnData` (`:134`), and its docstring (`:122-125`) is explicit: *"When `success` is true the top-level call returns `returnData`; when false the entry is run, verified, then reverted with `returnData` so all of its state effects roll back."* The outcome is written down before the transaction runs.
- **Trap 5** — `CAVEATS.md:9`, *"Indistinguishable revert reasons when calling a proxy"* — sitting immediately **above** the opcode caveat, which is why one page can honestly carry both. Mechanism: `CrossChainProxy.sol:109-113` forwards raw revert data unmodified.
- **Trap 6** — `EEZBase.sol:196-197`: *"`callGas` is 0 except calls leaving an L2 with `USE_GAS_LEFT`, where it is the `gasleft()` observed at manager entry."* `EEZL2.sol:236` is the only site that can produce a nonzero value. `EXECUTION_ENTRY_SPEC.md:55` adds the part that matters today: *"Every fixture and current deployment runs `useGasLeft = false`, so build every key with `callGas = 0`"* — confirmed at `script/e2e/shared/DeployInfra.s.sol:58`, `new EEZL2(rollupId, systemAddress, false)`. Value: `EEZ.sol:813` sets `_entryEtherDelta = int256(msg.value)` and the entry must balance (`EtherDeltaMismatch`), while `EEZL2.sol:230-234` **burns** it — `SYSTEM_ADDRESS.call{value: msg.value}("")`, under the comment *"burn ether — return to system address"*. `EXECUTION_ENTRY_SPEC.md:238`: *"L2 has no ether accounting."*

## The gaps, ranked by what breaks a builder soonest

The skill's mental model says the two consequences that change how a builder writes contracts are **pre-committed outcomes** and **proxy identity**, and that the site has the second and not the first. Confirmed: `q3`, `q4`, `q6` and `q7` all teach proxy identity, from four angles; the word `ExecutionEntry` appears zero times. That is the correct diagnosis. But "changes how you write contracts" and "breaks you soonest" are not the same axis, and the ranking below is by damage arrival, with the mental-model weight applied where it decides between two adjacent items.

1. **Trap 3, the same-block constraint — damage arrives at design time, before a line is written.** It is the only gap that can invalidate an entire architecture: a builder who assumes a cross-chain call can be settled "later" has designed a system the protocol cannot run, and nothing on the track contradicts them. It ranks first on arrival and **still does not earn a page** — see the counter-case. `03-dapp-pages.md` B1 already commissions the sentence, scoped correctly to both sides.
2. **Trap 2, opcode lies — damage arrives at ship time and never announces itself.** Every other trap on this list reverts. This one returns a plausible number about the wrong contract: `proxy.balance` is a real balance, `proxy.code.length` is a real code size, `block.chainid` is a real chain id. There is no failure to notice, no error string to search, and no test that fails unless the author already knew. It ranks second on arrival and first on cost-once-arrived.
3. **Trap 4, pre-committed outcomes — damage is diffuse, and it is the parent of items 1, 5 and 6.** Without it, the same-block rule reads as an arbitrary restriction rather than a consequence ("the outcome was proven for *this* block's state"), the indistinguishable revert reads as sloppy error handling rather than a structural property of matching against a table, and `callGas` reads as a gas parameter rather than a key field. This is why it cannot be a sentence: it is not a caveat, it is the frame the other caveats hang from.
4. **Trap 5, indistinguishable reverts — damage arrives at first debug, minutes after item 1 or 2 fires.** A builder whose first cross-chain call fails will write `try/catch` to tell "the destination reverted" from "something else", and cannot. Small, sharp, three lines upstream.
5. **Trap 6, `value` and `callGas` — mostly latent today, with one live defect.** `USE_GAS_LEFT` is `false` in every current deployment, so the gas-keyed hash trap is real but dormant. What is live: `q5`'s calculator accepts any combination of the eight fields and returns a green hash for all of them (`q5:668-695` validates address/rollup/hex shape only). Set `isStatic = true` with a nonzero `value` or `callGas` and it renders a hash that no on-chain path can ever produce — `EXECUTION_ENTRY_SPEC.md:67` folds `value = 0` and `callGas = 0` for `staticCrossChainCall` on both chains, unconditionally. A page whose whole thesis is *"this exact sequence is what the protocol hashes on-chain"* (`q5:244`) currently hands the reader hashes the protocol never computes.
6. **Trap 1, `msg.sender` — covered, and covered well.** No action.

## Proposed walkthroughs — three, of which two should be built

### `q8` · How to read a remote contract's state — **build it**

- **Teaches:** inspection is local, invocation is cross-chain. The four opcodes and the block-context set answer about the proxy or about this chain, and the fix is to call *through* the proxy rather than inspect it.
- **Anchor:** `docs/CAVEATS.md · "Opcodes that differ on cross-chain proxies"` (`:11-13`), with `src/base/CrossChainProxy.sol:89 · _fallback` as the mechanism citation.
- **Why it earns a page:** it is the only trap on the list with no failure signal, so it is the only one a sentence cannot discharge — a reader who skims past a sentence about `balance` gets no second chance from the compiler, the tests, or production. It also needs a *contrast*, and contrast needs two panels: the read that lies beside the call that does not.
- **A candidate already exists** at `/Users/armagan/Downloads/eez contract demo analye/q8-walkthrough.md`, being fixed under Task 11. Do not draft a competing page. Two defects to carry into that fix, both verified here:
  - **Its step 3 states the L1 rule as universal.** *"A view call is routed cross-chain and returns the remote contract's real state — provided the composer put a matching static entry in this block. Outside that block there is nothing to resolve against, and the read reverts."* That is true on L2 (`EEZL2.sol:634`) and **false on L1**, where `EEZ.sol:1308-1310` resolves from the persistent `staticEntryQueue` with no block gate and matches on state-root pins. The snippet repeats it: *"Reverts if this block carries no matching static entry."* `q8` teaches the shared `CrossChainProxy`, which runs on both sides, so the flat statement is wrong on whichever side the reader is on half the time.
  - **Its test proves the stub, not the protocol.** `Q8RemoteReads.t.sol`'s `test_callingThroughTheProxyReturnsRemoteState` and `test_routedReadRevertsWhenUnresolved` both exercise a local `StubProxy` that `staticcall`s a local `RemoteToken`. They establish that a forwarding contract forwards. That is the standard `Q6ManagerDirect.t.sol:17-21` sets and meets by refusing to fake the positive case — `q8` should either carry the same refusal in writing or drop the two tests. The first three tests (`.balance`, `.code.length`, `block.chainid`) are sound and are the whole point: nothing reverts.

### `q9` · What the protocol already knows about your call — **build it**

- **Teaches:** one thing. Before your transaction runs, the outcome of every cross-chain call in it is already written down — success flag, return data, nesting — and the chain's job is to check that what happened matches, not to discover what happens.
- **Anchor:** `src/interfaces/IEEZ.sol:126-135 · ExecutionEntry`, with the struct docstring at `:122-125` as the caption source and `docs/CORE_PROTOCOL_SPEC.md §A.1 · ExecutionEntry` (`:104`) as the spec link.
- **Why it earns a page:** it is the frame, and the track currently has none. Six pages teach the reader that a proxy stands for a remote address, and not one tells them why that address returns a value at all. Concretely, this page is what makes three separate absences legible at once — the same-block rule stops being arbitrary, `success == false` stops being a contradiction ("the entry ran, verified, then reverted"), and "no matching entry" stops being a bug report. It is also the page most likely to be read by someone deciding whether to build here at all, because the inversion is the interesting idea and it is currently invisible on the reader's own track.
- **Scope discipline:** show the entry being *checked*, never being *constructed*. `03-dapp-pages.md` R7 records that the words *composer*, *entry* and *table* appear nowhere on the dapp track and scores it as a deliberate right. This page has to introduce `entry` — it cannot introduce table-building. One labelled sentence saying the composer produces the entry, and no further operational detail.

### `q10` · Why your cross-chain call only works in this block — **do not build it yet**

- **Teaches:** `lastVerifiedBlock == block.number`, `ExecutionNotInCurrentBlock`, and the L1/L2 asymmetry for reads.
- **Anchor:** `src/EEZ.sol:794-797`, against `src/EEZ.sol:1308-1310` and `src/L2/EEZL2.sol:634` / `:588`.
- **Why it does not earn a page today:** the content is one `if` statement and one asymmetry, and both have a natural home — the `if` on `q2` step 3, where the call is being sent, and the asymmetry in `q9`'s "the outcome was proven against *this* block's state." A standalone page would restate `q2` and `q9` at 300 words apiece. Build it only if the B1 sentence ships and the constraint still turns up in support questions; that is a measurable trigger, not a hedge.

## The counter-case

**Six pages that are each true beat nine where three are thin, and that is the binding constraint here, not the gap list.** The dapp track's current asset is that every page has a runnable artifact or a live calculator, a citation that resolves to a real line, and a claim narrow enough to defend. `03-dapp-pages.md` shipped all six. Three of the four checks the repo runs cover the Solidity pages only, and the one gap that produced a real defect this week — `STATIC_CHECK_GAS = 5000` — was invisible to all of them. Adding three pages adds three more surfaces to that under-covered set before Task 8's checker exists. Adding two is defensible; adding three is not, and `q10` is the cut.

There is also a shape argument against the maximal read of this task. Five absent traps does not mean five gaps of equal standing: two of them are *caveats* (traps 2 and 5), one is a *constraint* (trap 3), one is a *frame* (trap 4), and one is a *field reference* (trap 6). Only the frame and the silent caveat are page-shaped. A constraint is a sentence at the point of the action; a caveat with a failure signal is a sentence at the point of the failure; a field reference is a table someone else already wrote.

**Gaps better served by a link than by a page**, with the exact target:

| Gap | Link to | Why the link wins |
|---|---|---|
| The side-specific same-block rule for reads | `docs/STATIC_ENTRY.md §7 · L1 / L2 differences` (`:280-283`) | The correct statement of both sides is already one paragraph, upstream, and it names the reason each side is the way it is. Any paraphrase on the site is the thing that goes stale — and the `q8` candidate is live proof, having flattened it in exactly the way a paraphrase does. |
| `value` and `callGas` semantics per entry point | `docs/EXECUTION_ENTRY_SPEC.md §"Hash semantics by entry point"` (`:61-69`) | A seven-row table covering all six entry points. It *is* the content; a page would be a worse copy of it. Pair the link with two real changes on `q5`: force `value` and `callGas` to `0` when `isStatic` is `true`, and label `callGas` with the one fact that decides it — `0` at every keying site except a call leaving an L2 with `USE_GAS_LEFT`, which is `false` in every current deployment (`EXECUTION_ENTRY_SPEC.md:55`). |
| Indistinguishable revert reasons | `docs/CAVEATS.md:9` | Three lines upstream. `03-dapp-pages.md` W1 already places the sentence on `q2`; the link is where a reader goes to confirm it is a property and not a bug. |

One structural note that makes those links cost something. **Not one citation on the dapp track points at a document** — all six resolve to `src/base/*.sol` or `src/EEZ.sol` (`q2:218`, `q3:181`, `q4:182`, `q5:254`, `q6:187`, `q7:232`/`:335-337`). Linking a `docs/` section is therefore a new pattern, not an extension of an existing one, and `scripts/verify-citations.py` asserts a symbol at a line — it has nothing to assert about a Markdown heading. Either the link goes in as prose outside the citation frame, or the verifier grows a heading-anchor mode. Deciding that is cheaper than writing a page, but it is not free, and it should be decided once rather than three times.

## What I could not verify

- **Nothing was compiled, executed or rendered.** No `forge`, `solc` or `solcx` on this machine. Every claim about `q8`'s candidate test is read from its source, not from a run — including the claim that its first three tests pass without reverting, which is the property the page rests on.
- **`llms-full.txt` was not read**, by instruction — it is being regenerated under Task 7. So every count above is site-HTML-only. If a trap is discussed in a page's `<!-- -->` comments or in a surface that only reaches `llms-full.txt`, this review would not see it. The grep covered the full HTML including comments, which bounds the risk to zero for these six terms.
- **The protocol-researcher track was not grepped** — those pages are held by another agent this session. So "absent from the site" is claimed here only as **absent from the dapp track**, which is the track a dapp developer is routed to from `index.html:181-211`. If `pr1`-`pr5` teach the rolling hash or the execution table, that does not close a gap for this reader; it does change how `q9` should link out, and that should be checked against `04-researcher-pages.md` before `q9` is drafted.
- **Whether any deployment runs `USE_GAS_LEFT = true`.** `EXECUTION_ENTRY_SPEC.md:55` and `DeployInfra.s.sol:58` establish `false` for every fixture and every current deployment *as documented at the pin*. No live chain was queried, so trap 6's dormancy is read from upstream's own statement, not observed.
- **That `q5`'s calculator produces an unreachable hash for `isStatic = true, value != 0`** is inferred from `EXECUTION_ENTRY_SPEC.md:67` and `EEZ.sol:1277` / `EEZL2.sol:605` folding a literal `0`, plus reading `q5:668-695`. The calculator was not run in a browser.
- **Reader behaviour.** The ranking's top item — that the same-block gap costs an architecture — is an argument from the mechanism, not from observed support traffic. `q10`'s build trigger is written to be falsifiable for exactly that reason.
