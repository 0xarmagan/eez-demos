# Task 10 — vocabulary and cross-page consistency sweep

**Verdict: the stale-name sweep is clean. Zero hits on all eleven retired protocol names, across all 17 shipped HTML files, case-insensitive. The one contaminated word is `lookup` on `q2`, already reported as A1 in `03-dapp-pages.md`, and the contamination does not extend past it. Two real findings came out of the coinage and consistency passes instead: `q2` and `q7` use "view call" for two different things on adjacent pages, and 9 of the site's 14 `NEXT:` links name the destination page differently from that page's own `<h1>`. One infrastructure finding: `llms.txt` and `llms-full.txt` point every link at `0xarmagan.github.io`, which is a live, unretired second mirror the README does not treat as canonical.**

**Method.** Every page was grepped directly from the worktree at `e20951f` — `index.html`, `dapp-developers/*.html` (7, including the `q1` redirect stub), `rollup-operators/*.html` (4), `protocol-researchers/*.html` (5). `llms.txt` and `llms-full.txt` were deliberately **not** read: they were being regenerated concurrently, and they are derived from these files anyway. Upstream comparison is `eez-core-protocol` @ `9735f53abbb6b9f5e863f405ad4555b4701b7fda`, fetched over `raw.githubusercontent.com` (`src/EEZ.sol`, `src/base/EEZBase.sol`, `src/interfaces/IEEZ.sol`, `docs/CORE_PROTOCOL_SPEC.md`, `docs/CAVEATS.md`), plus `eez-rollup0` `README.md` @ `a4b9b2f` for the four-component names. Counts exclude the syntax highlighter's keyword dictionary (the `"symbol":1,` map present on every page), which is code, not copy — that map is why a naive grep reports `staticCrossChainCall` on all 17 pages.

---

## 1. Retired-name sweep

Eleven names from the skill's stale-name table, plus the bare word `lookup`, grepped case-insensitively across all 17 files.

| Retired term | Current name | Hits | Verdict |
|---|---|---|---|
| `StateDelta` | `StateUpdate` | 0 | clean |
| `LookupCall` | `StaticExecutionEntry` | 0 | clean |
| `ExpectedLookup` | merged into `ExpectedL1ToL2Call` | 0 | clean |
| `revertSpan` | `revertNextNCalls` | 0 | clean |
| `staticCallLookup` | `staticCrossChainCall` | 0 | clean |
| `executeL2TX` | `executeL2Txs` | 0 | clean |
| `IZKVerifier` | `IProofSystem` | 0 | clean |
| `ProofSystemRegistry` | deleted — policy lives in each rollup's manager | 0 | clean |
| `stateDeltas` | `stateUpdates` | 0 | clean |
| `l2ToL1CallNumber` | `expectedRollingHash` | 0 | clean |
| `executingLookupIndex` | `expectedRollingHash` | 0 | clean |

The bare word `lookup` returns three hits and no more:

| file:line | Text | Verdict |
|---|---|---|
| `dapp-developers/q2-send-a-cross-chain-call.html:240` | *"a revert marks it a view call, routed to a read-only lookup"* | **Retired protocol term.** Already reported as A1 in `03-dapp-pages.md`; not re-litigated here. |
| `dapp-developers/q2-send-a-cross-chain-call.html:276` | *"routed to a read-only lookup instead of a real execution"* | **Retired protocol term.** Same finding, same page — A1. |
| `protocol-researchers/pr5-how-the-address-is-derived.html:412` | *"// order, no registry lookup — so you can compute it before anything is deployed"* | **Ordinary English.** In-panel comment; means "you do not have to consult a registry," which is true — `computeCrossChainProxyAddress` (`EEZBase.sol:176-185`) is `public view` over CREATE2 and reads no mapping. Not a protocol object. Leave it. |

### The contaminated-source check on `q2` — it did not spread

A stale name means a stale source, so `q2`'s neighbouring claims were checked for the two design reversals the same `feature/simplify` refactor produced. They are absent, and so is every other artefact of the pre-refactor model. A site-wide grep for `flatCalls`, `callCount`, `lastConsumed`, `callNumber`, `partition invariant`, `global cursor`, `flat array`, `LOOKUP_SPEC` returns **zero hits on all 17 files**. `q2`'s only protocol-object names are three correct occurrences of `staticCrossChainCall` (`:305`, `:392`, `:444`), and `03-dapp-pages.md` R6 already verified the static/mutating branch is copied correctly in both directions from `CrossChainProxy.sol:95-102`.

So the source contamination on `q2` is one word deep. That is worth stating positively rather than leaving implied: the page's *mental model* is current, only its *label* for the static path is not. The A1 fix is sufficient; no wider re-derivation of `q2` is needed.

Refinement to A1 worth carrying into the copy: **"read-only" is upstream's own word and should stay.** `EEZBase.sol:48` — *"Readable `isStatic` argument for `computeCrossChainCallHash` on static (read-only) paths"*; `EEZBase.sol:195` — *"`isStatic` makes a read-only call hash distinctly from an otherwise-identical state-changing one"*; `IEEZ.sol:85` — *"whether to execute via STATICCALL (read-only, no value)"*; `IEEZ.sol:139` — *"Reverting top-level reads land here"*. Only `lookup` is retired. The minimal edit is to delete one word, not to rewrite the phrase.

---

## 2. The site's own coinages

Every noun the site introduces that upstream does not use, tested against the pinned source. Conservative bias: a rename is a real cost, so the default is keep-and-define unless upstream already has a word and the site's substitute is actively misleading.

| Site term | Upstream evidence | Ruling |
|---|---|---|
| **walkthrough** | 0 hits in any pinned file. | **Keep.** It names a page format, not a protocol object — nothing to collide with. Used 124× across the site and in `README.md`, `CONTRIBUTING.md` and `scripts/new-demo.sh`. Renaming buys nothing. |
| **manager** | Upstream's own word, and upstream overloads it too: `CORE_PROTOCOL_SPEC.md:39` *"inherited by both managers"* and `:510` *"deployer = the manager (EEZ on L1, EEZL2 on L2)"* mean the core contract; `:196` *"per-rollup `IRollupContract`-conforming manager (owner / vkeys / threshold live there)"* and `:522`, `:535`, `:537` mean `Rollup.sol`. | **Keep — but the overload lands across a track boundary.** The dapp track means the core contract (`q6:203` "EEZ MANAGER", `q3`, `q4`, `q7`, `pr5`); `ro2` means `Rollup.sol` (`:172` "Your Manager Contract", `:187` `EEZ_ROLLUP_MANAGER_ADDRESS`, `:237` *"the EEZ core protocol, the proof system, and your manager contract"*). `ro2` itself disambiguates cleanly by listing the three deployed things separately, and `q6` qualifies with "EEZ". Nothing to rename; upstream has the same ambiguity and no better word. Cheapest close: keep `q6`'s "EEZ manager" qualifier everywhere on the dapp track, and keep `ro2`'s "your manager contract" phrasing — never bare "the manager" on the operator track. |
| **the composer** / **deriver** / **sequencer** / **proof-signer** | All four are upstream's words. `eez-rollup0/README.md` @ `a4b9b2f`:4-8 — *"a **sequencer** produces L2 blocks … **composer** posts those blocks to the `EEZ` contract on L1, and a **proof signer** independently re-executes and attests them. A **deriver** can …"*. `composer` also appears 6× in `CORE_PROTOCOL_SPEC.md` (`:143`, `:299`, `:321`, `:330`, `:366`, `:1258`). | **Keep, all four.** `index.html:167` and `:265` list exactly upstream's four. The only divergence is hyphenation — upstream prose writes "proof signer", the binary is `eez-proof-signer`, the site writes "proof-signer" on every page. Matches the binary, internally consistent, not worth touching. |
| **prover** (pr4) | Not upstream's noun; upstream says "proof signer". | **Keep — this is the model to copy.** `pr4:305` binds it on first use: *"the prover — the proof-signer, from step 1 — decodes PostBatch's calldata"*. That is exactly the keep-and-define-once discipline `CONTRIBUTING.md`'s audit step names ("an undefined synonym used for an existing term"), executed correctly. |
| **stand-in** | Upstream's own image: `CORE_PROTOCOL_SPEC.md:516` — *"A proxy stands in for a REMOTE address, never one on the manager's own network"*. | **Keep the word, fix one collision.** It carries two referents, and `q7` carries both. `q7:248` — *"On every other rollup it has a stand-in — a proxy"* (upstream sense: the proxy stands in for your contract). `q7:366` and `pr5:415` — *"/// @dev Stand-in for the real proxy"* (demo sense: a mock contract standing in for `CrossChainProxy` so `type(...).creationCode` compiles). On `q7` a reader is told the proxy **is** the stand-in, then shown a panel calling something else a stand-in for the proxy. → in the two panel comments only, use "Minimal `CrossChainProxy`" or "Mock — only `type(...).creationCode` matters here." Reserve "stand-in" for the proxy's role. Two files, two comment lines, no URL or title churn. |
| **proxy registry** | Upstream's own word: `IEEZ.sol:156` — *"`EEZBase` proxy registry"*; `CORE_PROTOCOL_SPEC.md:262` — *"the shared rolling-hash transient fields, proxy registry, and base-event/error set are inherited from `EEZBase`"*. | **Keep.** Used at `q3:136` and `q4:131`. Upstream-aligned, no action. |
| **identity** | Upstream's word, and for a *different* object than the site uses it for. Upstream: `EEZBase.sol:59` (`authorizedProxies` maps a proxy "to their identity"), `:243`, `:301`, `:314` (`CALL_BEGIN` binds "the call's IDENTITY (`crossChainCallHash`)"), `CORE_PROTOCOL_SPEC.md:577` (`entry.proxyEntryHash == crossChainCallHash` — "identity"), `:773` ("identity hash"). Site: `pr5:306`, `:310`, `:347` — *"Two values, packed as bytes — that's the whole identity"*, meaning the CREATE2 salt. | **Keep — the site's use is the narrower, correct one.** `pr5` says the salt *is* the proxy's identity, which matches `EEZBase.sol:59`'s sense exactly (the mapping's payload is `(originalAddress, originalRollupId)`, the two values the salt packs — `EEZBase.sol:167`). No collision on the page. See the `content hash` row for where upstream's *other* identity sense should have been used and wasn't. |
| **content hash** | **0 hits in any pinned file.** Upstream's noun is the *cross-chain call hash*: `CORE_PROTOCOL_SPEC.md:37` §heading *"Cross-chain call hash (off-chain helper)"*, `:733` §heading `computeCrossChainCallHash`, and the function itself at `EEZBase.sol:198`. Upstream's plain-English gloss for what it *is* is "identity" (`EEZBase.sol:301`, `:314`; `SPEC:577`, `:673`, `:773`). | **Rename the visible label; keep the URL.** This is the only site coinage that renames a protocol object, and `q5` has already independently derived upstream's actual meaning — `q5:272`, `:276`, `:313` all say *"one bytes32 identifies the call"* — then labels it something else. The page's own panel shows `computeCrossChainCallHash` (`:319`, `:364`) and cites `EEZBase.sol:198`, so the title and the panel disagree in the same viewport, the same shape of defect as A1 on `q2`. **Which side this call falls on:** the blast radius is real — `<title>`, `<h1>`, `index.html:212`, `q6:135`'s `NEXT:` label, the filename, `snippets/q5-content-hash.sol`, `snippets/test/Q5ContentHash.t.sol`, `contract ContentHashSnippet`. So do **not** move the URL or the slug: an inbound link is worth more than a tidy path, and the site has no redirect infrastructure beyond `q1`'s one-off stub. Change the visible label to *"a call's cross-chain call hash"* (or *"call hash"*, which the page's own `bytes32 callHash` row at `:241` already uses), and add one binding sentence at step 2: *"Upstream calls it the cross-chain call hash — it is the call's identity, and it is what every on-chain check matches against."* Filenames and contract names can stay. |
| **entry** / **table** / **pin** / **fold** / **rolling hash** | Heavily used upstream — `entry` 294× in `EEZ.sol`, `table` 68× in the spec, `pin` 41×, `fold` 50×, and all of `SPEC` §E is *"Rolling Hash"*. | **Nothing to rule on: they appear zero times on the site.** A grep for `rolling` returns **0 hits across all 17 files**. Every occurrence of `entr*` in copy is either the CSS comment "existing entrance keyframe" or "entry point" in the function sense (`q6:204`, `:208`, `:210`, `:244`, `:246`, `q7:375`). So there is no fragmentation risk here and no synonym to retire — but also no coverage. On the dapp track that is deliberate and correct (`03-dapp-pages.md` R7). On the researcher track it is a **coverage** gap, not a vocabulary one, and belongs to the scorecard rather than to this task: `pr4` is titled "How the composer proves a batch" and is entirely about the `prove.v1.Prover` gRPC stream, so the execution table and the rolling hash — the mechanism the skill calls the referee — are named nowhere on the site. Recording it here only because this sweep is what establishes the zero. |

---

## 3. Cross-page consistency

### 3a. The three names the task asks about — all consistent

| Concept | Dapp track (6 pages) | Researcher track (5 pages) | Agree? |
|---|---|---|---|
| The manager contract | "the manager" / "EEZ MANAGER" (`q2:185`, `q3`, `q4`, `q6:203`, `q7`) | "this manager" / "the manager" (`pr5:177`, `:242`, `:413`; the CREATE2 deployer) | **Yes.** Same referent — the `EEZ`/`EEZL2` core contract — same word. The only other sense on the site is `ro2`'s per-rollup `Rollup.sol`, on the operator track, and `ro2` separates it explicitly (see §2). |
| The proxy | "the proxy" / `CrossChainProxy` / "stand-in" (`q2` 11+7, `q3` 15+4, `q7` 12+3, `q4`/`q6` via `authorizedProxies`) | `CrossChainProxy` ×3, "your proxy", "stand-in" (`pr5`) | **Yes**, with the one referent collision on "stand-in" noted in §2. No page invents a third noun. |
| The static path | `staticCrossChainCall` in panels (`q2:305`, `:392`); prose says "view call" and "read-only lookup" (`q2:240`, `:276`) | **Never named in prose on any of the five.** The only `staticCrossChainCall` occurrences on the researcher track are in the syntax highlighter's keyword map (e.g. `pr1:386`). | **No disagreement, because only one track speaks.** The A1 fix on `q2` is the whole job; there is no researcher-track copy to bring into line. |

### 3b. `q2` and `q7` use "view call" for two different things

Found by this sweep, not previously reported.

- `q2:240` / `:276` — *"a revert marks it a view call, routed to a read-only lookup"*. Here "view call" means **the cross-chain static path**: `CrossChainProxy` self-calls to probe a transient write, and on revert routes to `IEEZ.staticCrossChainCall` (`q2:305`) against a `StaticExecutionEntry`.
- `q7:253` / `:289` — *"A view call reads that address before anything is deployed. It is a view call."* Here "view call" means **an ordinary Solidity `view` function on your own chain**: `computeCrossChainProxyAddress` is `public view` (`EEZBase.sol:176-179`), pure CREATE2 arithmetic, no cross-chain machinery at all.

These are consecutive pages on the same track — `q7` is dapp 01, `q2` is dapp 02, and `q7:137`'s `NEXT:` link goes straight to `q2`. A reader meets the phrase on `q7` meaning "cheap local read", then meets it on the next page meaning "cross-chain read that resolves against a pre-computed entry". Nothing false is stated on either page; the term is just doing two jobs one click apart, which is the exact failure `CONTRIBUTING.md`'s audit step 4 exists to catch.

→ **Fix:** `q7` keeps "view call" (it is literally a Solidity `view` call). `q2` drops it along with `lookup` in the same A1 edit: *"a revert marks it a read, routed to `staticCrossChainCall`."* One phrase, one page, and it resolves both A1 and this.

### 3c. 9 of 14 `NEXT:` links name the destination differently from the destination's own `<h1>`

Every page ends with a `NEXT:` link. The label is hand-written and belongs to an older title set; the destination `<h1>` has since been rewritten to the current "How to …" grammar. Nothing is broken — all 14 hrefs resolve, verified by resolving every relative `.html` href on every page (0 broken) — but the reader is promised one page name and lands on another.

| From | `NEXT:` label | Destination `<h1>` | |
|---|---|---|---|
| `q7:137` | Send a Cross-Chain Call | How to call a contract on another rollup | ✗ |
| `q2:136` | How Msg.sender Resolves Across Chains | How to handle msg.sender across chains | ✗ |
| `q3:136` | How the Proxy Registry Works | How to check an address is a real proxy | ✗ |
| `q4:136` | Why the Manager Only Accepts Proxy Calls | How the guard makes sure only proxy calls reach execution | ✗ |
| `q6:135` | Encode a Call's Content Hash | How to encode a call's content hash | ✓ |
| `q5:138` | Run the EEZ Devnet with Kurtosis | How to run the whole stack locally | ✗ |
| `ro1` | Deploy the Protocol | How to deploy the protocol | ✓ |
| `ro2` | Run the Chiado L2 | How to run against a real testnet | ✗ |
| `ro3` | Send & Test Cross-Chain Calls | How to send and test a cross-chain call | ✓ |
| `ro4` | The Four Components of Rollup0 | How the four components divide the work | ✗ |
| `pr1` | Commit-First, Repair-If-Needed | How L1 stays the source of truth | ✗ |
| `pr2` | How the Composer Proves a Batch | How the composer proves a batch | ✓ |
| `pr4` | The Deriver: Rebuilding L2 State from L1 Alone | How the deriver rebuilds L2 from L1 | ✗ |
| `pr3` | How the Address Is Derived | How the address is derived | ✓ |

Worth being precise about what this is *not*: the labels are not the filename slugs either (`q4`'s file is `check-if-an-address-is-a-proxy`, its label is "How the Proxy Registry Works"). So the site carries **three** parallel naming systems per page — slug, `<h1>`, and `NEXT:` label — and only the first two are stable. By contrast, `<title>`, `<h1>` and the `index.html` card label agree on **all 15** walkthroughs, checked pair by pair. The defect is confined to the `NEXT:` strip.

→ **Fix:** rewrite the nine labels to the destination's current `<h1>`. Then make it structural rather than a checklist item — `CONTRIBUTING.md:88` already warns that a diff review will not catch a broken `NEXT:` link, and this is the same class one step milder. A dozen lines in `audit.sh` can parse each `NEXT:` href, read the destination's `<h1>`, and fail on mismatch. `scripts/new-demo.sh` says in `README.md` that wiring the `NEXT:` chain is manual, which is exactly why nine of them drifted.

---

## 4. Canonical host

**Finding: both hosts are live and serve the same content, the site declares no canonical anywhere, and the repo's two authoritative pointers disagree with each other.**

Evidence, all gathered fresh:

| Probe | Result |
|---|---|
| `curl` `https://eez-demos.vercel.app/`, `/dapp-developers/q5-…html`, `/llms.txt` | `200`, `200`, `200` |
| `curl` `https://0xarmagan.github.io/eez-demos/` + the same two paths | `200`, `200`, `200` — **github.io really does serve the site** |
| `<link rel="canonical">` across all 17 files | **Exactly one**, on `dapp-developers/q1-compute-your-cross-chain-address.html`, and it is *relative* (`../protocol-researchers/pr5-how-the-address-is-derived.html`) — a redirect stub's self-canonical, carrying no host. The 15 walkthroughs and `index.html` have **no canonical tag at all**. |
| `og:url` / any absolute self-reference in the HTML | **None.** `index.html` carries only `twitter:card` / `twitter:title` / `twitter:description` (`:9-11`). |
| `CNAME` | **Absent.** Confirmed by GitHub's own API: `"cname": null`. |
| `README.md:3` | *"Live at [eez-demos.vercel.app](https://eez-demos.vercel.app)"*, and `:11` *"Deployed on Vercel, git-linked (push to `main` deploys)"* |
| GitHub repo `homepage` field | `https://0xarmagan.github.io/eez-demos/` — **contradicts the README** |
| GitHub Pages config | `has_pages: true`, `status: "built"`, `build_type: "legacy"`, `source: {branch: "main", path: "/"}`, `https_enforced: true` — Pages is deliberately enabled and building from `main`, not a leftover |
| `.github/workflows/` | `ci.yml` only. No Pages deploy workflow — legacy Pages needs none. |

**Ruling: `https://eez-demos.vercel.app` is canonical; `0xarmagan.github.io/eez-demos` is an unretired mirror.** The two human-written, prose statements of intent both name Vercel — `README.md:3` and this review plan's own spec line (*"the live site (`https://eez-demos.vercel.app`)"*). The two pointers naming github.io are machine-facing metadata: the repo `homepage` field and `BASE` in the generator. Metadata loses to the stated intent, and Vercel is also the deploy path the README documents. This ruling is a reading of the repo's own statements, not a preference — if the owner intends github.io to be primary, the README is the thing that is wrong, and that inverts every fix below.

**Consequence, and it is not cosmetic.** `llms.txt` and `llms-full.txt` are the two files written specifically to be ingested by language models, and every URL in them points at the mirror. An assistant that ingests `llms.txt` will cite `0xarmagan.github.io/eez-demos/...` to a developer — a URL that works today, on a host nobody has committed to keeping, with no canonical tag anywhere on the site to correct it and no redirect from either host to the other. The same `BASE` also builds the deep links to snippets and tests (`:352`, `:361`), so a reader following a citation out of `llms-full.txt` leaves the canonical site entirely without noticing. Separately, two hosts serving byte-identical content with zero `rel="canonical"` is textbook duplicate content: search engines pick a winner on their own, and the two hosts' signals split.

**Exact fix location — not applied here, `scripts/**` is held by another agent:**

- **`scripts/build-llms.py:31`** — `BASE = "https://0xarmagan.github.io/eez-demos"` → `"https://eez-demos.vercel.app"`. Line 31 in both the working tree and `HEAD`, verified against `git show HEAD:scripts/build-llms.py`. Five consumers, all downstream of that one constant, no other change needed: `:342` (page links in `llms.txt`), `:352` (snippet links), `:361` (test links), `:366` (the `llms-full.txt` pointer), `:392` (the `Page:` line in `llms-full.txt`). Regenerate both files after the edit.
- **Two companion fixes, both outside `build-llms.py`.** (1) Add `<link rel="canonical" href="https://eez-demos.vercel.app/...">` to the 15 walkthroughs and `index.html` — with two live mirrors and no CNAME, this is the only thing that tells an ingester which host to cite, and the generator fix alone does not supply it. (2) Set the GitHub repo `homepage` field to the Vercel URL so the repo stops advertising the mirror. Either retire Pages, or leave it and let the canonical tags carry the load — but do not leave the site with two live hosts and no declaration.

---

## What could not be verified

- **`llms.txt` and `llms-full.txt` were not read.** Another agent was regenerating them during this task. Every claim above about their contents is derived from `scripts/build-llms.py`'s `BASE` constant and its five consumers, read at `HEAD` and in the working tree, not from the generated output. Re-confirm after regeneration.
- **`eez-rollup0` was checked at the plan's pin `a4b9b2f`, which upstream `HEAD` has moved past** (`d8a7547`, per Task 1). The four-component names were read from `README.md` at the pin; component *naming* is not among the files Task 1 flagged as drifted (`composer.rs`, `deriver.rs`, `optimistic.rs`), but this is a pin-relative claim, not a `HEAD` one.
- **No page was rendered.** Term counts come from the HTML source with tags stripped and the highlighter's keyword map excluded; a term hidden behind a JS branch that never fires would still be counted here.
- **The canonical-host ruling is a reading of intent, not a fact recovered from configuration.** No configuration on either host states which is primary — that is precisely the finding. The evidence is listed above in full so the ruling can be inverted cleanly if the owner's intent is the opposite.
- **One adjacent factual drift, out of this task's remit, recorded because the sweep surfaced it.** `README.md:3` says *"14 short animated walkthroughs"* and `:6` says *"Protocol researchers (4)"*. There are **15** (6 dapp + 4 operator + **5** researcher), which is what `index.html:11`'s own `twitter:description` says and what `CONTRIBUTING.md:84` assumes ("all 15 demos"). The README undercounts the researcher track by one — `pr5` is missing from its arithmetic. For the scorecard, not for this file.
