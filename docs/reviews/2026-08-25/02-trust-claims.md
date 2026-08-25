# Task 2 — trust-and-claims honesty sweep

**Verdict: one BLOCKING regression, live on `main` right now, plus two documents that assert the disclosure still exists.**

Reviewed against the live site and `origin/main` @ `33cf510`.

## BLOCKING — the pre-mainnet disclosure was deleted from every page

**Not one of the 17 shipped HTML files contains a pre-mainnet label** — not the 15 walkthroughs, not `index.html`, in any casing:

```bash
for f in $(git ls-files '*.html'); do printf '%s %s\n' "$(grep -ci 'pre-mainnet' $f)" "$f"; done   # 0 everywhere
```

Git says this was deliberate once and accidental the second time:

| Commit | Date | Effect on `*.html` |
|---|---|---|
| `47922e6` *Fix all 4 gaps from the DevRel/DevEx review* | 2026-08-19 | **+15** `PRE-MAINNET` labels |
| `81a211f` *WIP: syntax highlighting, diff markers, linked citations* | 2026-08-23 | **−15** — all of them |

Both are ancestors of `origin/main`, so the removal is what visitors get. A disclosure added specifically to close a review gap was dropped four days later by a commit about syntax highlighting. Nothing failed, because nothing checks for it.

Severity is BLOCKING rather than cosmetic because of what the pages claim without it: `pr4` is titled *"How the composer proves a batch"*, its step 2 header reads *"THE PROVER RE-EXECUTES"*, and `pr1` step 2 says the attestation makes a block *"trusted downstream"*. A reader arriving from search sees proving language and no statement that the shipped proof system is a dev-grade ECDSA signer.

**Fix:** restore the label on all 15 pages **and** in `scripts/new-demo.sh`'s template (below), then add a one-line assertion to `scripts/audit.sh` so a future refactor fails CI instead of silently dropping it.

## BLOCKING — two files assert the disclosure that is no longer there

1. **`README.md:9`** — *"Every code panel cites a real, verified `file:line` — pre-mainnet, every page says so."* The first half is true (Task 1 verified 25/27 citations). The second half is false as of `81a211f`.
2. **`scripts/new-demo.sh:12`** — documents that the scaffold produces *"(fixed stage, terminal code panel, PRE-MAINNET label, favicon, mobile scaleStage floor)"*. Probed directly:

```bash
bash scripts/new-demo.sh dapp-developers zz-scaffold-probe "Scaffold Probe"
grep -ci pre-mainnet dapp-developers/zz-scaffold-probe.html   # 0
```

The generator lost the label too, so **every future page inherits the regression** and its own header will keep claiming otherwise. This is the template-level fix that matters more than the 15 restorations: put it back in the producing template, not in a review checklist.

## ACCURACY — `pr4` never says the prover is a signer

`pr4`'s only mention of what actually signs is a diagram field note at line 223: `65B — ECDSA over public_inputs_hash`. That is a technical label, not a disclosure. Against three pieces of proving language on one page — the title, *"THE PROVER RE-EXECUTES"*, and *"The prover signs the recomputed hash"* — it does not carry the weight.

**Fix:** one sentence in step 1, where "proof-signer" is first used. Suggested: *"The proof-signer re-executes the block and signs the result with ECDSA — it stands in for the ZK prover that will occupy this position, and the interface is the part that is real today."* That keeps the page honest without weakening what it teaches, since the gRPC contract genuinely is the shipped interface.

## ACCURACY — `pr1`'s "trusted downstream" overstates what an attestation buys

`pr1` step 2: *"Once Composer finishes, the Attester signs a hash of the result so the block can be trusted downstream."* Trust here is conditional on a registered key, not established by the signature. The page's own step 3 gets it right — *"Deriver never trusts any of the three"* — which makes step 2's phrasing the odd one out.

**Fix:** *"…signs a hash of the result, so a downstream consumer that recognises the attester's key can accept the block without re-executing it — until the deriver re-derives it from L1 anyway."*

## What this gets right

- **No atomicity overclaim anywhere.** The only `atomic` string on the whole site is `aria-atomic="true"` on the narration region — an accessibility attribute. For a synchronous-composability project this is the single easiest claim to overreach on, and the site never does.
- **`llms-full.txt`'s preamble is exemplary** and states plainly that EEZ is pre-mainnet, that capability claims are design intent, and that the proof system in public source is dev-grade ECDSA, not production ZK. The defect is that this honesty lives *only* in the generated file — the human-facing pages carry none of it.
- **`pr1` step 3 and `pr3`** both frame the deriver as the thing that trusts nothing, which is the right backstop framing.
- **`ro3`** tells the reader to *set* `EEZ_PROOF_SIGNER_KEY` and friends and never fills in an example value — no dev key ships as copyable text.
