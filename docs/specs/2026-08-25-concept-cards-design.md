# Concept cards: the landing page explains itself

**Status:** design approved, not implemented
**Date:** 2026-08-25

## The problem

The first card on the landing page reads *Compute your cross-chain address*, and its
walkthrough opens on `TWO INPUTS` — the salt packing, then keccak256, then the CREATE2
preimage. Two things are wrong with that.

**It teaches internals to an audience that only needs a call site.** `IEEZ` exposes
`computeCrossChainProxyAddress` as a `public view` function (`EEZBase.sol:176`) and
`createCrossChainProxy` as an external one (`:156`). A dapp developer calls those. They do
not hand-roll a CREATE2 preimage, so the derivation is a protocol-researcher question —
*why is this deterministic without a registry lookup* — sitting in the dapp track.

**Nothing on the site says what a cross-chain address is.** The entire conceptual grounding
is one card blurb: *"Every contract gets one deterministic address on every other rollup."*
No definition, no motivation, no statement of when a developer would touch it. The hero goes
straight from "Learn how EEZ actually works" into a fifteen-card grid, and a developer cannot
tell which of those cards is their problem.

There is also a coverage gap the current split hides: **`createCrossChainProxy` appears in
zero demos.** The one function that brings a proxy into existence is absent from a site whose
dapp track is about using proxies.

## Evidence

Two independent sources agree, which is why this is a restructure rather than a copy edit.

**Upstream source, verified at the pinned SHA** (`9735f53abbb6b9f5e863f405ad4555b4701b7fda`):

| Symbol | Location | Status on the site |
|---|---|---|
| `createCrossChainProxy` | `EEZBase.sol:156` | absent from all 14 demos |
| `_createCrossChainProxyInternal` | `EEZBase.sol:161` | absent |
| `computeCrossChainProxyAddress` | `EEZBase.sol:176` | q1 teaches its internals |
| `SameNetworkProxy` | `EEZBase.sol:142`, guard at `:166` | absent |

`EEZBase.sol:137-141` also documents an auto-creation path: the same-network guard lives in
the internal helper *"so it also blocks the auto-creation path during execution, not just the
external entry point."* A proxy can therefore come into existence without anyone calling
`createCrossChainProxy` — a fact with direct consequences for how a developer plans a
deployment, and one the site never mentions.

**The DAPPCon Berlin BuilderRoom workshop** (17 June 2026, ~3h, transcript at
`agent-mesh/eez-agent/knowledge/eez/sources/dappcon-2026-builderroom-workshop/transcript.txt`).
Audience questions map onto the demos closely enough to be used as the card copy's brief:

- *"Could it auto-deploy the proxies if they don't exist?"* — the auto-creation path above,
  asked unprompted by a builder in the room.
- *"Is there some kind of message caller aliasing on proxy calls? Who are the message senders?"* — q3.
- *"What happens if I call the proxy outside of this Composer context bundle?"* — q6.
- *"must the proxy address also be exactly the same as the address on the deployed contract?"* — the address concept.
- *"Are they the same client or are they different clients? And what's the communication between them?"* — pr1.

Questions asked at that workshop that **nothing on the site answers**, recorded here so they
are not rediscovered as new: *who pays the gas* (its own chapter), *which nonce persists
across chains*, *how to send Ether to an L2*, and *whether proxies can self-destruct*. Out of
scope for this change.

## Decisions

Each of these was chosen against at least one live alternative; the alternatives are recorded
so they are not silently re-opened.

1. **The concept lives on the landing card, not inside the demo.** Considered and rejected: a
   concept step 0 inside all 15 walkthroughs (would have taken every file from 3 steps to 4,
   collided with `check-panel-drift.py`, and put a panel with no citable source on the first
   screen); and a standalone concepts page (a second surface to keep accurate). The demos are
   **untouched** by this change except for their `<title>` and the two file moves below.

2. **Card titles become questions.** "Why" phrasings are avoided — as a CTA they read as a
   problem report, and two of the drafts front-loaded a failure. The gotchas move into the
   card's explanation, where "reorder the fields and the hash changes silently" is a useful
   warning rather than a discouraging headline.

3. **Card layout is answer-first**: question title → one-sentence answer in near-white →
   explanation. Rejected: growing the existing one-line hook into a paragraph (buries the
   answer), and a disclosure toggle (hides the answer behind a click most readers never make —
   the same failure that sank the VS Code layout prototype, see `DESIGN.md`).

4. **The explanation is typographically real, not a footnote.** 14.5px on the existing
   `--muted` token (`#9aa3b3`), which measures **7.3:1** against the `#161616` card. The first
   draft at 13px `#7e7e7e` measured 4.5:1 — technically AA, and still read as a footnote.

5. **The derivation demo moves to the research track**, and a new opener takes its place.

Approved visual reference: <https://claude.ai/code/artifact/020fd0df-b3fd-4da9-a4d8-19824968d111>

## Scope

### Track layout after the change

| Track | Count | Change |
|---|---|---|
| Dapp developers | 6 | new opener in; derivation demo out |
| Rollup operators | 4 | unchanged |
| Protocol researchers | 5 | derivation demo in |

Fifteen demos total, up from fourteen.

### File moves

**`q1` moves to the research track.**
`dapp-developers/q1-compute-your-cross-chain-address.html`
→ `protocol-researchers/pr5-how-the-address-is-derived.html`

A meta-refresh stub stays at the old path. The old URL is published in `llms.txt` and is
public on two hosts. The stub uses a **relative** href — an absolute path is exactly what
broke the favicon on the GitHub Pages mirror, which serves from `/eez-demos/` rather than the
domain root. A `vercel.json` redirect was rejected because it fixes only one of the two hosts.

**A new dapp opener is added:** `dapp-developers/q7-your-cross-chain-address.html`,
displayed as card 01.

The filename is `q7`, not `q0`, deliberately. This repo already separates display order from
filename — cards 05/06 were reordered by retitling rather than renaming, and `DESIGN.md`
records that as intentional. Renumbering `q2`–`q6` on disk to match display order would break
every existing URL to save nothing. **Do not "fix" this back.**

### New demo content

`q7` is a normal 3-step walkthrough, citing `IEEZ.sol` and `EEZBase.sol`:

1. **Call it into existence** — `createCrossChainProxy(originalAddress, originalRollupId)`,
   `EEZBase.sol:156`.
2. **Or read it before it exists** — `computeCrossChainProxyAddress`, `EEZBase.sol:176`, a
   view call that works before any deployment.
3. **The one rule** — remote addresses only; same-network reverts `SameNetworkProxy`,
   `EEZBase.sol:166`.

Requires a new compilable snippet (`snippets/q7-create-proxy.sol`) mirroring the cited
functions. `scripts/citation-pins.json` needs no change — it pins one SHA per repo, not per
citation, and `eez-core-protocol` is already pinned at the SHA these lines are read from.

### The fifteen cards

Titles are also the demo `<title>` tags, so the card and the page agree.

**Dapp developers**

| # | Question | Answer line |
|---|---|---|
| 01 | What address does my contract have on another rollup? | You already have one on each — derived from your address, and computable before anything is deployed. |
| 02 | How do I call a contract on another rollup? | Encode it like any normal call and send it to the proxy address. |
| 03 | Who is `msg.sender` when the call comes from another chain? | The proxy — never your original address. |
| 04 | How do I check an address is a real proxy? | Read the registry — every proxy is recorded when it is created. |
| 05 | What does the manager accept? | Calls that arrive through a registered proxy. Nothing else reaches execution. |
| 06 | How do I encode a call's content hash? | Eight fields, hashed in one fixed order, identify a cross-chain call. |

**Rollup operators**

| # | Question | Answer line |
|---|---|---|
| 01 | How do I run the whole stack locally? | One Kurtosis command brings up all of it. |
| 02 | How do I deploy the protocol? | One command deploys the core protocol, the proof system and your manager. |
| 03 | How do I run this against a real testnet? | The same stack, pointed at Chiado instead of a sandbox. |
| 04 | How do I send and test a cross-chain call? | Two proxy fronts, one script, real pass/fail numbers. |

**Protocol researchers**

| # | Question | Answer line |
|---|---|---|
| 01 | Which component does what? | Four separate programs, not one node. |
| 02 | If L2 commits first, what makes L1 the source of truth? | L2 commits immediately, and L1 either settles it or repairs it. |
| 03 | Can the L2 chain be rebuilt from L1 alone? | Yes — that is the deriver's entire job. |
| 04 | How does the composer prove a batch? | One gRPC stream: header first, then blocks, then a signature. |
| 05 | How is the address derived? | Two values, hashed into a salt, run through CREATE2. |

Full explanation text for every card is in the approved artifact linked above and is the
content contract for implementation.

**Every answer line is derived from its own demo's captions**, so a card cannot contradict the
walkthrough it links to. Two cards additionally close an open precision item from the
2026-08-24 accuracy audit: research 01 and 04 now connect *proof-signer* and *attester*, which
the demos use interchangeably with nothing linking them.

## Consumers to update

Adding the cards is half the work. Each of these reads something this change invalidates:

- **`index.html`** — card markup, the two new CSS rules, section counts (`DAPP DEVS (6)`,
  `PROTOCOL RESEARCHERS (5)`), the starter row, and the `q1` href.
- **Every demo `<title>`** — must match its card's question.
- **`scripts/check-panel-drift.py`** — `SNIPPET_MAP` is keyed by filename. The `q1` key breaks
  on the move and a `q7` key must be added, or its panels go unchecked.
- **`scripts/new-demo.sh:29` and `CONTRIBUTING.md:26`** — both name `q1` as the scaffold template for every new walkthrough.
- **`llms.txt` / `llms-full.txt`** — regenerate via `scripts/build-llms.py`; CI fails on drift.
- **The `NEXT:` chain** — `q1` currently sits in the dapp sequence.
- **`agent-mesh` KB, `kb/02-technical/EEZ-Demos-Walkthroughs.md`** — lists every slug and title
  and says "Fourteen". Outside this repo, so it will not fail CI; it goes stale silently.

## Verification

Nothing ships until all of these pass:

- `bash scripts/audit.sh` — structure, links, leftover TODOs, marketing language.
- `python3 scripts/check-panel-drift.py` — every panel line backed by a compilable snippet.
- `python3 scripts/verify-citations.py` — the new citations resolve at their pinned SHA.
- `cd snippets && forge test`.
- `python3 scripts/build-llms.py --check`.
- **Headless panel-height check on `q7` across all 3 steps.** The code panel is fixed-height
  with `overflow-y:auto`: 16 lines fit, and a 17th scrolls below the fold rather than
  clipping — easy to miss inside a scale-transformed stage. `audit.sh` does **not** catch this — it has passed on a file that was actively
  clipping. Assert `scrollHeight === clientHeight` on `#codePanel` at every step.
- **Both old and new URLs resolve** on Vercel *and* the GitHub Pages mirror after deploy.

## Out of scope

- The four unanswered workshop questions listed above.
- `<noscript>` fallbacks, the branch-protection gap, and the stale `docs/DESIGN.md:49-51`
  private-repo lines — all pre-existing, tracked separately.
- Any change to the walkthroughs' 3-step format or their diagrams.

## Open question

The new `q7` needs a diagram. Every other dapp walkthrough draws its mechanism; this one has
to draw *your contract on rollup A, its stand-in on rollup B, same address* without redrawing
the CREATE2 derivation that now belongs to research 05. Worth agreeing on before build.
