# Task 9 — runnable-artifact truth

**Verdict: every runnable claim the site makes is literally true, and the `q8` prediction made without a toolchain was right. `forge build` compiles 12 files clean; `forge test` is 13/13 green; all three of `q5`'s pinned digests reproduce on a live EVM, byte-for-byte, from solc's own `abi.encode`. The externally-drafted `Q8RemoteReads.t.sol` fails exactly one of its five cases — `test_routedReadRevertsWhenUnresolved` — for exactly the predicted reason. Task 11's Step-2 BLOCKING finding stands, empirically.**

| Claim under test | Result |
|---|---|
| "full compilable Solidity" (`btnFull`, 6 pages) | **True.** 12/12 files compile, 2 warnings, 0 errors |
| "runnable Foundry test" (`btnTest`, `q3`/`q5`/`q6`) | **True.** 13/13 pass, 3 suites |
| `snippets/README.md`: "12 files compile, 13 tests pass" | **True**, exactly |
| `q5`'s three pinned digests, EVM side | **True.** Reproduced 3 independent ways |
| `q8` draft: `test_routedReadRevertsWhenUnresolved` | **FAILS.** Prediction confirmed |
| 7 snippets / 3 tests | Gap is real; one snippet deserves a test — `q7` |

**This run is real.** Every prior task in this review was a source read: Task 3's own Method line says *"Nothing was compiled or executed,"* and the plan's Global Constraints record that no Solidity toolchain existed on this machine. That is no longer true. Everything below is pasted from an actual execution.

## 1. Toolchain

```
$ export PATH="$PATH:/Users/armagan/.foundry/bin"
$ forge --version
forge Version: 1.7.1
Commit SHA: 4072e48705af9d93e3c0f6e29e93b5e9a40caed8
Build Timestamp: 2026-05-08T07:54:31.470926000Z (1778226871)
Build Profile: dist
```

**Where it ran.** The repo *is* already a Foundry project — `snippets/foundry.toml` exists (`src = "."`, `test = "test"`, `libs = []`, `solc = "0.8.28"`), and `.gitignore` already carries `snippets/out/` and `snippets/cache/`. So building in place would have been safe. It was still done in a scratch copy at `scratchpad/scratch-snippets/`, byte-identical to `snippets/` on entry (`diff -r` → identical), because `snippets/**` is held read-only for this task. The repo tree is unchanged: `git status --porcelain snippets/` is empty, and neither `snippets/out` nor `snippets/cache` exists.

**What CI actually does** (`.github/workflows/ci.yml`, job `solidity`): `foundry-rs/foundry-toolchain@v1` with `version: nightly`, then `forge build` and `forge test -vv`, both `working-directory: snippets`. Two observations, both real:

- **CI installs `nightly`, unpinned**, on a repo whose entire thesis is pinning — every citation carries `@ 9735f53abb…`, `foundry.toml` pins `solc = "0.8.28"`, and the compiler is the one input left floating. A nightly regression turns a green repo red with no commit. → pin the toolchain to a released tag.
- **CI does not fail on warnings.** No `--deny-warnings` anywhere, so the two warnings in §2 ship silently and forever.

## 2. Compile

Compiler actually used: `solc 0.8.28+commit.7893614a` (svm-resolved from the `solc = "0.8.28"` pin — `Solc 0.8.28 finished in 756.99ms`). Every file declares `pragma solidity ^0.8.28`, so the pin is the floor and no file is compiled under a version its pragma would reject.

```
$ forge build --force
Compiling 12 files with Solc 0.8.28
Solc 0.8.28 finished in 756.99ms
Compiler run successful with warnings:
```

Per-file standalone compile, run against the raw `solc-0.8.28` binary one file at a time (`solc --bin <file>`), so "compiles standalone" means literally that and not "compiles as part of a project":

| File | Standalone | Notes |
|---|---|---|
| `lib/IEEZ.sol` | PASS | interface only |
| `lib/IEEZManager.sol` | PASS | resolves `./IEEZ.sol` relatively |
| `q1-compute-address.sol` | PASS | no imports |
| `q2-cross-chain-call.sol` | PASS | imports `./lib/IEEZ.sol`; 2 warnings (below) |
| `q3-msg-sender.sol` | PASS | imports `./lib/IEEZ.sol` |
| `q4-proxy-registry.sol` | PASS | imports `./lib/IEEZManager.sol` |
| `q5-content-hash.sol` | PASS | no imports |
| `q6-manager-direct.sol` | PASS | — |
| `q7-create-proxy.sol` | PASS | no imports |
| `test/Q3MsgSender.t.sol` | PASS | imports `../lib/IEEZ.sol`, `../q3-msg-sender.sol` |
| `test/Q5ContentHash.t.sol` | PASS | imports `../q5-content-hash.sol` |
| `test/Q6ManagerDirect.t.sol` | PASS | — |

**12/12, zero failures.** Nothing needs a project root to compile: `solc` resolves every `./lib/…` and `../…` import relative to the importing file, so the README's claim that *"`solc` alone is enough to confirm the files compile"* is exactly right. No snippet failed standalone, so there is no "why not" to report.

**Every warning, in full.** Three distinct warnings exist across the two runs, and the difference between the two runs is itself a finding.

1. `forge build` and `solc` both emit, on `q2`:

```
Warning (3628): This contract has a payable fallback function, but no receive ether function. Consider adding a receive ether function.
  --> q2-cross-chain-call.sol:33:1:
33 | contract CrossChainProxySnippet {
Note: The payable fallback function is defined here.
  --> q2-cross-chain-call.sol:60:1:
60 | fallback() external payable {
```

Benign and correct to leave: upstream `CrossChainProxy` routes bare ether through the same `_fallback()`, and adding a `receive()` to the snippet would make it diverge from the file it mirrors.

2. `forge` emits, on the interface header:

```
warning: invalid natspec tag '@9735f53abbb6b9f5e863f405ad4555b4701b7fda', custom tags must use format '@custom:name'
  ╭▸ lib/IEEZ.sol:9:1
9 │ ///   @ 9735f53abbb6b9f5e863f405ad4555b4701b7fda
```

Cosmetic, but it fires on **every** `forge` invocation in this repo and in CI, which is the definition of a warning nobody will ever read. The pin line is inside a `///` natspec block, so the parser reads `@9735f…` as a tag. → move the pin to `//` line comments, or write it `@custom:pin 9735f53…`.

3. **`solc` emits a third warning that `forge` silently swallows** — and it is the one warning a reader of `q2` most needs:

```
Warning: Transient storage as defined by EIP-1153 can break the composability of smart contracts: ...
  --> q2-cross-chain-call.sol:56:20:
56 |         assembly { tstore(0, 1) }
```

Proved, not inferred. Foundry's default `ignored_error_codes` (from `forge config`) is `["license", "code-size", "init-code-size", "transient-storage", "transfer-deprecated", "natspec-memory-safe-assembly-deprecated"]`, and `snippets/foundry.toml` does not override it. Re-running the identical build with `ignored_error_codes = []`:

```
with ignored_error_codes=[] -> Transient-storage warning lines: 1
with repo foundry.toml (defaults) -> Transient-storage warning lines: 0
```

The snippet's own comment at `:49-54` already warns that raw slot 0 is a collision risk and tells the reader to declare a named `transient` variable as upstream does. So the prose is right — but the reader who copies the line into their own Foundry project gets **no compiler warning either**, because they inherit the same default. → add `ignored_error_codes = ["license", "code-size", "init-code-size"]` to `snippets/foundry.toml`, dropping `transient-storage` from the suppressed set. One line, and the compiler starts backing up the comment.

## 3. Tests

```
$ forge test --match-contract "Q3MsgSender|Q5ContentHash|Q6ManagerDirect" -vv

Ran 4 tests for test/Q6ManagerDirect.t.sol:Q6ManagerDirectTest
[PASS] test_directCallFromContractReverts() (gas: 13803)
[PASS] test_directCallFromEoaReverts() (gas: 14403)
[PASS] test_emptyCallDataRevertsIdentically() (gas: 14365)
[PASS] test_spoofingSourceAddressDoesNotHelp() (gas: 14359)
Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 1.19ms (1.16ms CPU time)

Ran 5 tests for test/Q5ContentHash.t.sol:Q5ContentHashTest
[PASS] test_dataLengthIsEncoded() (gas: 16251)
[PASS] test_isDeterministic() (gas: 16285)
[PASS] test_isStaticIsPartOfTheHash() (gas: 16294)
[PASS] test_matchesIndependentlyDerivedDigest() (gas: 10542)
[PASS] test_swappingSourceAndTargetChangesTheHash() (gas: 16381)
Suite result: ok. 5 passed; 0 failed; 0 skipped; finished in 1.21ms (1.29ms CPU time)

Ran 4 tests for test/Q3MsgSender.t.sol:Q3MsgSenderTest
[PASS] test_proxyCheck_passesWhenCalledViaProxy() (gas: 17530)
[PASS] test_proxyCheck_revertsForStranger() (gas: 15802)
[PASS] test_sameChainCheck_passesOnSameChain() (gas: 10504)
[PASS] test_sameChainCheck_revertsWhenCalledViaProxy() (gas: 10832)
Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 1.21ms (234.54µs CPU time)

Ran 3 test suites in 4.14ms (3.61ms CPU time): 13 tests passed, 0 failed, 0 skipped (13 total tests)
```

Per contract: `Q6ManagerDirectTest` 4/4, `Q5ContentHashTest` 5/5, `Q3MsgSenderTest` 4/4. **13 passed, 0 failed, 0 skipped.** No failures, so there is nothing to diagnose against upstream. `snippets/README.md`'s "13 tests pass" is exact, and its highlighted case — `test_sameChainCheck_passesOnSameChain`, the one that passes *because* the bug is invisible on the same chain — is confirmed green at 10504 gas.

## 4. `q5` — the EVM side, settled

The three digests had been re-derived twice before this task, both times **outside** the EVM (Task 3 R5: pycryptodome, then a hand-written Keccak-f[1600]). What no one had checked is the half those derivations assume: that **solc's own `abi.encode` emits that preimage**. Three independent EVM-side derivations, none of which routes through the test's `require` statements:

**(a) `cast abi-encode` + `cast keccak`** — foundry's encoder, not solc's, and not the test:

```
$ cast abi-encode 'f(bool,address,uint64,address,uint64,uint256,uint64,bytes)' \
    false 0x1111111111111111111111111111111111111111 1 \
    0x2222222222222222222222222222222222222222 100 0 0 0xa9059cbb
0x0000000000000000000000000000000000000000000000000000000000000000
  0000000000000000000000001111111111111111111111111111111111111111
  0000000000000000000000000000000000000000000000000000000000000001
  0000000000000000000000002222222222222222222222222222222222222222
  0000000000000000000000000000000000000000000000000000000000000064
  0000000000000000000000000000000000000000000000000000000000000000
  0000000000000000000000000000000000000000000000000000000000000000
  0000000000000000000000000000000000000000000000000000000000000100
  0000000000000000000000000000000000000000000000000000000000000004
  a9059cbb00000000000000000000000000000000000000000000000000000000
  (one 0x-prefixed hex string, 320 bytes; wrapped here at 32-byte words)
len_bytes=320
$ cast keccak <that>
baseline digest: 0x6f907866fb077719ec239f745e2de52832f0d8507473768dbaa2d3b45cf8fbe1
swapped digest:  0x9876a218b9c58a69bb5b01481b628f13d5c2eb8d72b0f80d942e9eb0962dc19f
isStatic digest: 0xb3d426ceaa48ca006739dd0799a05e675999732e2a63a4021089512c489daa1d
```

**(b) the shipped snippet, executed on a live EVM.** `anvil` on `:8547`, `forge create` the unmodified `snippets/q5-content-hash.sol:ContentHashSnippet`, then `cast call` it. No `require`, no assertion — just the function's real return value read off a chain:

```
ContentHashSnippet @ 0x5FbDB2315678afecb367f032d93F642f64180aa3
baseline: 0x6f907866fb077719ec239f745e2de52832f0d8507473768dbaa2d3b45cf8fbe1
swapped:  0x9876a218b9c58a69bb5b01481b628f13d5c2eb8d72b0f80d942e9eb0962dc19f
isStatic: 0xb3d426ceaa48ca006739dd0799a05e675999732e2a63a4021089512c489daa1d
```

**(c) the preimage itself, returned raw from the EVM.** A scratch-only probe returning `abi.encode(...)` unhashed, deployed alongside, so the 320 bytes solc actually builds could be compared byte-for-byte against `cast`'s:

```
$ cast call <probe> 'preimage(bool,address,uint64,address,uint64,uint256,uint64,bytes)(bytes)' …
len_bytes=320
keccak of that preimage: 0x6f907866fb077719ec239f745e2de52832f0d8507473768dbaa2d3b45cf8fbe1

BYTE-IDENTICAL: solc abi.encode (on-chain, 320 bytes) == cast abi-encode (off-chain)
```

**Resolution: the EVM agrees with both spec-derived implementations, exactly.** All three digests match to the last nibble, from four independent encoders (pycryptodome + hand-built ABI encoder; hand-written Keccak-f[1600]; `cast`; solc-on-anvil) and 320 bytes / 10 words each time. `q5`'s test comment — *"they pin solc's output against an independent implementation"* — is now verified in the direction it was always claiming and never checking. Nothing in Task 3's R5 needs revising; it is upgraded from "two off-chain implementations agree" to "the EVM is one of them."

## 5. `q8` — the prediction was RIGHT

**This is the finding that decides Task 11.** The draft at `/Users/armagan/Downloads/eez contract demo analye/` was copied verbatim into the scratch project — `shasum -a 256` identical on both files, `q8-remote-reads.sol` `a620cac5…21ec8` and `Q8RemoteReads.t.sol` `f3a2e81c…e4bb3` — and compiled clean (`Compiling 2 files with Solc 0.8.28 / Compiler run successful!`), which is exactly what the draft's author reported and exactly why it is not enough.

```
$ forge test --match-contract Q8RemoteReads -vv

Ran 5 tests for test/Q8RemoteReads.t.sol:Q8RemoteReadsTest
[PASS] test_balanceReadsTheProxyNotTheRemote() (gas: 4920)
[PASS] test_blockContextIsLocal() (gas: 361)
[PASS] test_callingThroughTheProxyReturnsRemoteState() (gas: 13604)
[PASS] test_codeSizeIsTheProxysOwn() (gas: 10820)
[FAIL: unresolved read must revert, not return zero] test_routedReadRevertsWhenUnresolved() (gas: 135486)
Suite result: FAILED. 4 passed; 1 failed; 0 skipped; finished in 415.58µs

Encountered a total of 1 failing tests, 4 tests succeeded
```

**4 pass, 1 fails — and it is the one the review named, failing on the one line the review quoted.** The `-vvvv` trace confirms the causal chain link by link, in the predicted order:

```
  [135486] Q8RemoteReadsTest::test_routedReadRevertsWhenUnresolved()
    ├─ [96538] → new StubProxy@0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
    ├─ [3028] StubProxy::fallback(0x…A11cE) [staticcall]
    │   ├─ [0] 0x000000000000000000000000000000000000dEaD::balanceOf(0x…A11cE) [staticcall]
    │   │   └─ ← [Stop]                        ← no code: SUCCEEDS, returns nothing
    │   └─ ← [Return]                          ← require(ok,"unresolved") passes; zero bytes returned
    └─ ← [Revert] unresolved read must revert, not return zero   ← require(!ok) fails
```

Read against the prediction, clause for clause: *"a staticcall to an address with NO CODE succeeds and returns empty data"* → `0x…dEaD::balanceOf` `← [Stop]`, gas 0. *"the inner `require(ok, "unresolved")` passes"* → the frame did not revert there. *"the assembly returns zero bytes"* → `← [Return]` with no payload. *"the outer staticcall reports ok == true"* → the assertion at `:118` is the frame that reverts. Four for four. **The prediction, made with no toolchain, was correct in its conclusion and in its mechanism.**

**And the diagnosis is the whole cause, not a correlate.** One change — give the resolver code that reverts, leaving all five test bodies otherwise untouched — flips it green:

```
// scratch-only probe: StubProxy(address(new RevertingResolver())) instead of address(0xDEAD)
contract RevertingResolver { error ExecutionNotFound(); fallback() external { revert ExecutionNotFound(); } }

Ran 5 tests for test/Q8FixProbe.t.sol:Q8FixProbeTest
[PASS] test_balanceReadsTheProxyNotTheRemote()          [PASS] test_blockContextIsLocal()
[PASS] test_callingThroughTheProxyReturnsRemoteState()  [PASS] test_codeSizeIsTheProxysOwn()
[PASS] test_routedReadRevertsWhenUnresolved() (gas: 189209)
Suite result: ok. 5 passed; 0 failed; 0 skipped
```

**Task 11's Step 2 stands as BLOCKING, now on evidence rather than on reading.** Two riders for whoever executes Task 11:

- **The green probe above is not the fix to ship.** It proves the diagnosis; it does not satisfy Step 3. A resolver that reverts on *every* selector still models fetch-on-demand. Step 3's table keyed by `crossChainCallHash`, reverting `ExecutionNotFound` on a miss, satisfies Steps 1, 2 and 3 in one move, and the probe shows that shape passes.
- **The draft's test never touches the draft's snippet.** `Q8RemoteReads.t.sol` has no `import` at all and never names `RemoteReader`; it re-declares its own `IRemote` locally. So the four passing cases prove things about `StubProxy`, a fixture defined in the test file — not about `q8-remote-reads.sol`, which is the file the page would ship. Every other test in `snippets/test/` imports the snippet it defends (`Q3MsgSender.t.sol:5`, `Q5ContentHash.t.sol:4`). This one would be the first that does not, and `check-panel-drift.py` cannot see it, because it compares panels to snippets and never asks whether a test exercises one.

## 6. The 7-snippets / 3-tests gap

Tested: `q3`, `q5`, `q6`. Untested: `q1`, `q2`, `q4`, `q7`. The asymmetry is defensible in three of the four — `q4`'s `RegistryReader` is a getter call with nothing to assert that is not solc's own ABI decoding, and `q1` is `q7`'s derivation with the create half removed.

**The one that most deserves a test is `q7-create-proxy.sol`.**

The reason is not symmetry, and not that address derivation is important. It is that **`q7` is the only snippet every existing checker is structurally blind to, by design.** Task 8's fidelity check and `verify-citations.py` both work by comparing snippet text to upstream text. `q7` deliberately diverges from upstream in three places and must: `_getRollupId()` is hardcoded `return 0` (`:52-54`), `authorizedProxies` is a `mapping(address => bool)` rather than the `ProxyInfo` struct `q4` teaches (`:44`), and `CrossChainProxy` is a two-line stand-in whose `creationCode` is not the protocol's (`:18-24`). Those divergences are correct — but they mean a text-fidelity check cannot be pointed at this file, leaving **behaviour as the only checkable property, and behaviour is untested.**

It is also the only snippet carrying an invariant testable with **zero mocks and zero faked protocol state** — the standard `Q6ManagerDirect.t.sol:17-21` sets for itself. `createCrossChainProxy` and `computeCrossChainProxyAddress` live in the same contract, so the site's load-bearing claim (*"you can compute it before anything is deployed"*, `q1-compute-address.sol:8-10`) round-trips against a real CREATE2 deploy. Nothing on the site does this today: `Q3MsgSender.t.sol`'s `MockEEZ` (`:29-41`) **computes** an address and never deploys one, so `computed == deployed` is asserted nowhere, in a formula that is hand-copied into four separate files.

Written and run, to prove the recommendation is real rather than proposed:

```
Ran 3 tests for test/ScratchQ7RoundTrip.t.sol:ScratchQ7RoundTripTest
[PASS] test_computedAddressIsWhereCreateActuallyDeploys() (gas: 119998)
[PASS] test_saltIsUnambiguous() (gas: 14213)
[PASS] test_sameNetworkReverts() (gas: 6824)
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

The first asserts `predicted.code.length == 0`, then `createCrossChainProxy(...) == computeCrossChainProxyAddress(...)`, then that code now exists there. A transposed `salt`/`bytecodeHash`, a dropped `bytes1(0xff)` or the wrong deployer would compile, pass `check-panel-drift.py`, pass `verify-citations.py`, and fail this. That is the same defect class as the `STATIC_CHECK_GAS` `5000`/`1_000` drift Task 3 caught by hand — a wrong value sitting *between* two checkers that each pass.

**The runner-up, recorded and not recommended.** `q2` is the most intricate untested snippet, and its static/mutating branch is testable honestly with a counterparty-only mock (the same posture `Q3MsgSender.t.sol` already takes) — written and run, both cases green, with the trace showing the mechanism the site describes but never demonstrates:

```
    ├─ [5522] CrossChainProxySnippet::fallback(42) [staticcall]
    │   ├─ [217] CrossChainProxySnippet::staticCheck()
    │   │   └─ ← [StateChangeDuringStaticCall] EvmError: StateChangeDuringStaticCall
    │   ├─ [1708] RecordingEEZ::staticCrossChainCall(…) [staticcall]
    │   │   └─ ← [Return] 0x22
```

It loses to `q7` on exactly one criterion: `q2` is copied verbatim from upstream `CrossChainProxy.sol:95-102`, so Task 8's fidelity check *does* guard it. `q7` has no such guard and never can. One test, not four.

## What could not be verified

- **That any snippet matches the protocol.** Compiling and passing prove internal consistency only — `lib/IEEZ.sol:11-13` says this itself. `verify-citations.py` and Task 8's fidelity check are the checks for that, and they belong to other tasks.
- **`q1`/`q7`'s derivation against the real `CrossChainProxy`.** Both snippets CREATE2 over a local stand-in's `creationCode`, so the addresses they produce are correct *formulas* over the wrong *bytecode*. Proving the protocol's address would mean vendoring upstream, which the snippets exist to avoid. The proposed `q7` test inherits this limit and must not be described as producing a protocol address.
- **CI itself.** This ran on `forge 1.7.1` (released, pinned by hand); CI installs `nightly`. Local green does not prove CI green, and that is the finding in §1, not an aside.
- **`q4`'s `RegistryReader` against a real manager** — needs a deployed `EEZBase`, out of scope for a dependency-free snippet directory.
- **`scripts/*` and the generated `llms*.txt`** were not run or inspected; other agents hold them for Tasks 7 and 8.
