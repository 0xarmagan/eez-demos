# Task 1 — rollup0 pin decision

**Decision: HOLD the pin at `a4b9b2f`.** Every claim the nine affected pages make survives at upstream HEAD. Re-pinning would buy nothing and would cost a re-verify of all nine plus one line-number fix.

Reviewed 2026-08-25 against `eez-rollup0` HEAD `d8a7547b3` (2026-08-25). Pin: `a4b9b2f1da1208c0f4f9c5b2ff4e45d6281ad1d2` (2026-08-21), per `scripts/citation-pins.json`.

`eez-core-protocol` is not in scope here: its pin `9735f53` **is** upstream HEAD, so the six Solidity pages carry no drift exposure at all.

## What moved

Two commits: `fix: chained inter-state (#97)` and `tests(ci): add protocol E2E tests (#47)`. 34 files changed; **3 of the 12 cited files** are among them.

| Cited file | Change since pin | Cited by |
|---|---|---|
| `crates/eez-composer/src/composer.rs` | +870 / −252 | pr1 |
| `crates/eez-deriver/src/deriver.rs` | +4 / −10 | pr1, pr3 |
| `crates/eez-composer/src/optimistic.rs` | +1 / −1 | pr2 |
| `sequencer.rs`, `attest.rs`, `prove.proto`, `eez-protocol/src/abi.rs`, `Makefile`, `README.md`, `testing/kurtosis/README.md`, `scripts/deploy.sh`, `scripts/xchain-test.sh` | untouched | pr1, pr3, pr4, ro1–ro4 |

All four operator pages and `pr4` cite only untouched files. They cannot have drifted.

## The three questions, per cited symbol

| Symbol | (a) exists at HEAD | (b) line still correct at HEAD | (c) narration still true |
|---|---|---|---|
| `composer.rs:515 · Composer<L2>` | yes | **no — moved to `:636`** | yes |
| `deriver.rs:45 · Deriver<L2>` | yes | yes | yes |
| `deriver.rs:169 · catch_up` | yes | yes | yes |
| `optimistic.rs:101 · OptimisticallyIncluded` | yes | yes | yes |
| `optimistic.rs:117 · begin` | yes | yes | yes |
| `optimistic.rs:177 · mark_settled` | yes | yes | yes |
| `optimistic.rs:191 · mark_failed` | yes | yes | yes |
| `sequencer.rs:159 · Sequencer` | yes | yes (file untouched) | yes |
| `attest.rs:52 · Attester`, `:134 · sign` | yes | yes (file untouched) | yes |

Only (c) can force a re-pin, and (c) is clean everywhere:

- **`composer.rs` (+870/−252) is a large change with no public-surface change.** `CrossChainExecCtx`, `CrossChainWiring`, `Composer<L2>`, the `Debug` impl, the two `impl Composer` blocks and `impl SyncSlotComposer` all still exist in the same order, shifted ~121 lines down. `pr1`'s claim — sequencer builds the block, composer settles the cross-chain calls inside it — is untouched by it.
- **`optimistic.rs` changed one doc comment**: *"a tx whose `simulate_and_resolve` deterministically fails"* → *"a tx whose chained simulation deterministically fails"*. `pr2`'s three steps (`begin` → held at `sync_height` → `mark_settled` / `mark_failed`) are unaffected.
- **`deriver.rs` moved log decoding into `eez_protocol::outbound_gate::observations_from_logs`.** It touches neither `Deriver`, `catch_up`, `execute_block` nor `handle_event`. `pr3` is unaffected.

## If someone re-pins later

Bumping to `d8a7547` requires one content fix, not just a SHA bump: **`pr1`'s `composer.rs:515` must become `:636`.** The verifier will catch it (a 121-line miss is far outside its window), but only if it is run after `--repin`, so run both:

```bash
python3 scripts/verify-citations.py --repin && python3 scripts/verify-citations.py
```

## Three defects found while checking — all pre-existing at the pin, all on `pr3`

These are not drift. They are wrong at `a4b9b2f` itself, and the repo's verifier cannot see them because they live in **panel comment text**, not in a page's citation metadata. Hand them to Task 4.

1. **`// deriver.rs:504`** (annotating `pub fn execute_block`) — at the pin, line 504 is a closing brace; `execute_block` is at **`:516`**. Off by 12.
2. **`// deriver.rs:774`** (annotating `async fn handle_event`) — at the pin, line 774 is `Err(err) => {`; `handle_event` is at **`:786`**. Off by 12, the same offset, so both were almost certainly taken from one stale local copy.
3. **`// abi.rs:105`** (annotating `event BatchPosted`) — there is no `crates/eez-deriver/src/abi.rs` at the pin, which is what the surrounding `deriver.rs:NNN` annotations imply. The file is **`crates/eez-protocol/src/abi.rs`**, where line 105 is exactly `event BatchPosted(uint256 indexed rollupCount);`. Line right, path missing. `CONTRIBUTING.md` already records "infra citations missing their `crates/` path" as a past defect — this is the same class, recurring.

The general lesson for Task 12: `verify-citations.py` covers the citation block only. Every `// file.rs:NNN` written inside a code panel is unverified surface, and three of them are wrong on one page.

## Verifier baseline, corrected

On `origin/main` (`33cf510`, what the site serves): **25 citations / 27 assertions, all pass.** The plan's Global Constraints record 26/28 — that number came from the unmerged `fix/panel-geometry-gate` branch, which adds one. The external audit's "20/20" is a hand-rolled subset of the same set.
