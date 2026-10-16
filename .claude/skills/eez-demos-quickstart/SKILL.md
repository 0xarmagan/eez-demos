---
name: eez-demos-quickstart
description: Use when adding or editing a card in the eez-demos dApp Quickstart track (dapp-developers/qs*.html), or any eez-demos walkthrough whose panel shows commands to run — covers the run-it-for-real gate, measured time claims, local-vs-devnet framing, excerpt registration and the track's wiring.
---

# eez-demos Quickstart cards

A quickstart card makes two promises a reader acts on: the commands work as pasted, and the code is real.
This skill covers what [CONTRIBUTING.md](../../../CONTRIBUTING.md) doesn't. Read CONTRIBUTING for the format, the source-of-truth rules and the PR checklist. Read [docs/founding-design.md](../../../docs/founding-design.md) for why the walkthrough format is fixed.

## 1. Before you write

1. Read the spec, `docs/specs/2026-10-14-dapp-quickstart-track-design.md`, and the **Global Constraints** at the top of `docs/plans/2026-10-14-dapp-quickstart-track.md`. They give the pins, slugs, `NEXT:` chain and the forbidden claims (no DEX, no lending).
2. Load `eez-protocol-dev` (it may be listed as `anthropic-skills:eez-protocol-dev`) to ground every claim. If it isn't available, read the pinned source directly; never write from memory.
3. Get the source at the pin (`scripts/citation-pins.json`, eez-core-protocol `9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f`):
   `git clone https://github.com/eez-association/eez-core-protocol.git && cd eez-core-protocol && git checkout -q 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f`. Clone outside this repo (e.g. under `/tmp`), never into it. This clone is for reading source and checking excerpts. `run-quickstart.sh` makes its own temp dir and clone.
4. Check `index.html` for a reference-track card (q1–q8) on your topic. Link to it instead of re-teaching it (for example, static reads already have q8).
   Pick a live scenario. Run `grep -n E2E_EXCLUDE_FROM_ALL <scenario>.s.sol` and read the "NOT LIVE YET" list in eez-core-protocol `script/e2e/README.md`. If the scenario is on that list, don't build a card on it. If it only carries the marker, call it "local run only" and claim no devnet path.
5. Scaffold: `scripts/new-demo.sh dapp-developers <slug> "<Title>"`. It sets the `<title>`, canonical, header, eyebrow and intro title from its arguments, turns the ledes, learn list, "Verified against" line, `NEXT:` link, diagram `s1`/`s2`/`s3`, `srcCite`/`data-demo-cite`, kickers, captions, `codeByStep`/`hlByStep` and `fullSnippet` into `TODO`s, and removes pr5's `TRY IT` calculator. Fill every `TODO` (`grep -n TODO <page>`). `hlByStep` holds 0-based line indices per step.
   The one thing left for you: the `FULL` button. Keep `#btnFull` and a real `fullSnippet` only for a `SNIPPET_MAP` page (then run `python3 scripts/sync-embedded-snippets.py`). Otherwise delete the `#btnFull` element and set `var fullSnippet = [];`. The JS guards a missing button.
6. Make the page visible to `audit.sh` without committing it: `git add -N dapp-developers/<page>`. `audit.sh` lists pages from `git ls-files`, so it silently skips an untracked page.

## 2. Run-it-for-real gate

Every command a card shows has been executed, and the output it shows came from that run.

- Shell panels write each command as one `"$ <command>"` string in `codeByStep`. Output lines are plain strings, pasted from the run. Comments start with `# `.
- `scripts/run-quickstart.sh` extracts only the lines that start with `$ ` (via `build-llms.py`'s `steps_of`), so:
  - **one command per `$ ` line, no `\` continuations.** The continuation line has no `$ `, so it is never run;
  - **each command appears in exactly one step.** Don't repeat earlier commands in later steps the way ro1 does: the script would run them twice (`git clone` fails the second time). To recap, use output or `# ` lines;
  - strings must be **double-quoted** JSON-style. `flat_strings` ignores single-quoted strings, so those lines are neither run nor excerpt-checked. Escape inner quotes as `\"` (e.g. `"require(ok, \"failed\");"`). `steps_of` unescapes each line with `json.loads`, and `check-excerpts.py` compares the unescaped line, so it must match upstream after unescaping;
  - keep the multi-line shape `  var codeByStep = [` … `\n  ];` (two-space indent), the only one `js_array` parses;
  - commands run non-interactively (stdin is `/dev/null`) in one bash session, so `cd` carries over to the next line.
- The local e2e runner needs bash 4+. Stock macOS bash 3.2 fails (`E2EBase.sh: line 458: declare: -A: invalid option`), so a card shows `brew install bash` only as a `# ` comment, never as a `$ ` line.
- Each page runs in its **own fresh temp dir**. A hands-on card therefore repeats the qs1 setup lines: `git clone https://github.com/eez-association/eez-core-protocol.git`, `cd eez-core-protocol`, `git checkout -q 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f`, `git submodule update --init --recursive`, `forge build`. Run every later command from inside the clone. `parallel.sh` needs `forge build` first.
- Scenarios: `bash script/e2e/run/local/parallel.sh <name> [<name>...]`. A name is a scenario **directory** name under `script/e2e/scenarios/<category>/<direction>/` (e.g. `staticReadWrite`), and each name is a separate argument. The direction directory names where the transaction starts: `L1_to_L2` starts on L1 and calls into L2 (`E2ECounter.s.sol:30` says "L1-starting"). Pass scenario names as separate arguments. Verified: `parallel.sh 'bridge bridgeL2'` prints `SKIP`, then `RESULT: 0 passed, 0 failed, 1 skipped`, and **exits 0**. `run-quickstart.sh` therefore reads the RESULT line and fails on 0 passed, any failed or any skipped, or when a `parallel.sh` command printed no RESULT line at all. Still check the passed count is what you expect.
- Run the gate with the bare filename (the script prepends `dapp-developers/`):
  ```bash
  bash scripts/run-quickstart.sh --extract-only <page>.html   # what will run
  bash scripts/run-quickstart.sh <page>.html                  # run it; prints RAN: lines and ELAPSED
  ```
  A clone without `git checkout <full pin>` makes the script refuse. It reads the pin from `scripts/citation-pins.json` (eez-core-protocol `sha`), so a pin bump there is the only edit; then update the pages' checkout lines to match. Paste the PASS and RESULT lines from this run. Parallel scenarios finish in any order, so the page shows the order you got.
- A command you didn't run never appears, not even as "optional" or "for reference". Self-test: `bash scripts/test_run_quickstart.sh` (CI runs it and `--extract-only` on qs1, qs7, qs8).

## 3. Time claims

- A duration appears on a card, caption or hook only if it comes from a clean cold run recorded in `docs/quickstart-runs.md`, rounded **up** to the next 5 minutes. Current figures: qs1 cold total 251.66 s, so **N = 5**. Scenario-only reruns from a built tree: flash-loan 14.66 s, `bridge bridgeL2` 11.30 s. Each is "under a minute" only once the tree is built.
- No measurement means no number. A new card may add a section to `docs/quickstart-runs.md` in the existing format: date, `sw_vers -productVersion`, `uname -m`, CPU, `forge --version`, cold conditions (nothing else loading the CPU, no forge cache), per-step seconds and the verbatim final output lines. Cards in the plan's Tasks 4–10 use the existing figures and don't edit the log.
- A card's own page total is the qs1 setup plus the scenario. Don't quote the scenario seconds as the time to run the card.

## 4. Local vs devnet framing

- Every scenario file has a local and a network executor. Cite them at the pin, e.g. `script/e2e/scenarios/one_way/L1_to_L2/counter/E2ECounter.s.sol`:
  - `:209` `Execute — local mode: postAndVerifyBatch tx + incrementProxy tx from the EOA`, so the script posts the entry the composer would;
  - `:188` `ExecuteL2 — local mode: system-driven L2 simulation of the inbound call`, so the script also acts as the L2 system address;
  - `:237` `ExecuteNetwork — network mode: outputs user tx fields`, so on a network you send only the trigger.
  Other scenarios use the same `Execute`/`ExecuteL2`/`ExecuteNetwork` split (`grep -n '^contract' <scenario>.s.sol`).
- So a **local** card says what you *see* ("see it work", "watch the round trip"). It never says you *build* or *deploy*. Name the composer's role once: "Locally, the scenario script plays composer."
- Only a card that runs on a real network (qs6, still a stub) may say *build* or *deploy*. Say "composer", never "sequencer", for who builds entries.

## 5. Excerpts

Every code step is one of the following:

| Kind | Must be | Registered in |
|---|---|---|
| Verbatim upstream (eez-core-protocol only) | each non-comment line found, whitespace-trimmed, in the listed files at the pin; a step with no such line fails | `EXCERPTS` in `scripts/check-excerpts.py` (page → `{0-based step: [paths]}`), **and** `EXCERPT_CHECKED` in `scripts/check-panel-drift.py` (check-excerpts fails if the two key sets differ) |
| From a compilable snippet | verbatim from `snippets/<file>.sol`, which mirrors upstream | `SNIPPET_MAP` in `check-panel-drift.py`; the test slice goes in `TEST_SNIPPET_MAP` |
| Shell | §2 | `NON_SOLIDITY` (shell-only page) or `EXCERPT_CHECKED` (shell step plus excerpt steps) |

- Choose an excerpt when the upstream lines teach the point as they are. Choose a snippet only when the reader needs code that compiles on its own, such as a contract they'd adapt (qs2), and then add a `snippets/test/*.t.sol` in the snippets' no-forge-std style.
- `check-panel-drift.py` scans `qs[0-9]|q[1-9]|pr[1-9]` pages. A page with `codeByStep` that's in none of these maps **fails**.
- The plan's Tasks 4–10 pages are already registered, so don't edit those dicts. A new card adds its own entries. If several card agents work in parallel, each one sends its entries to the lead instead of editing these shared files.
- Skipped by the excerpt check: lines starting with `//`, `/*`, `*`, `⋯`, `...`. Use them for your notes and elisions. Everything else must match an upstream line exactly. You can't shorten or reflow a long line. If it overflows the 662 px panel, choose different lines or elide with `⋯`. Skipped lines are unchecked, so a comment that reflows or trims upstream text (NatSpec, say) is labelled a paraphrase (`// paraphrasing CounterContracts.sol:4-6:`), never presented as a quote.
- Cite `eez-core-protocol/<path>:<line> · <symbol>` as a link to `https://github.com/eez-association/eez-core-protocol/blob/<full pin>/<path>#L<line>`. `verify-citations.py` checks that the symbol appears within 4 lines.
- When steps cite different files or functions, use `var citeByStep = [...]` with one literal `<a href=…>` per step, single-quoted JS strings. q7 (`dapp-developers/q7-your-cross-chain-address.html`) and q6 show the pattern. Keep `data-demo-cite` equal to step 1's link.
- A shell step cites the script it runs, e.g. `script/e2e/run/local/parallel.sh:17 · parallel.sh` (its "subset" usage line).

## 6. Track wiring

- **`NEXT:` chain**, from the Global Constraints: qs0 → qs1 → qs2 → qs3 → qs5 → qs7 → qs8 → `../index.html#dapp-developers`. Links have the form `<a class="back" href="qs3-who-answered.html#skip-intro" …>NEXT: Who Answered? &rarr;</a>`. `#skip-intro` skips the lead-in. Every page also has the bottom-bar button `<a id="nextDemo" class="next-demo" href="…#skip-intro">…<span class="next-demo-t">Who Answered?</span>…</a>`. Change its `href` and `next-demo-t` title together with the header link. A new card goes into the chain where its phase puts it. A new Build-patterns card goes after qs8: qs8's `NEXT:` moves to it, and it takes over `../index.html#dapp-developers`. Change both neighbours, and only the `NEXT:` link on existing pages.
- The qs pages (`dapp-developers/qs0`–`qs8`) and `index.html`'s `#quickstart` section exist. Check that a link target exists before adding it. `audit.sh` fails on a broken link.
- **Phase:** a card whose main point is a runnable pattern a developer would copy goes under Build patterns. A card that explains what happened goes under See it work.
- **Index phase strip**: `index.html` `<section class="sec" id="quickstart">` has four rows: Understand, See it work, Make it real, Build patterns. Each card is an `<a class="card" href="dapp-developers/<page>">` with a `card-title` and a `card-hook`. `build-llms.py` takes titles, hooks and page order from these anchors. The hook states a consequence (CONTRIBUTING "Format").
- **Stub** (qs6): modelled on `dapp-developers/q1-compute-your-cross-chain-address.html` without its meta refresh. It has the title, "Coming soon", one sentence on what the card will show (deploying and calling your own contract with the Remix cross-chain plugin), a link to `../index.html#quickstart`, and `PRE-MAINNET`. Its index card keeps the `COMING SOON` badge. qs4 (real composer on a local devnet) was removed, and the phase strip is numbered 00–07 without a gap; slugs keep their `qsN` names. Leave out `codeByStep` and captions, so `build-llms.py` and panel-drift skip the stub.
- Adding or removing a walkthrough means bumping the `EXPECTED_WALKTHROUGHS` constant in `scripts/build-llms.py` (24 now) in the same change, or `build-llms.py --check` fails. Stubs without captions don't count. `start-here.html` names the count in words; keep it in step.
- Leave `EXPECTED_CARDS` in `scripts/check-manifest.py` alone. It counts manifest task cards, not pages.
- Kickers are short ALL-CAPS phrases, one per step (`"RUN IT."`, `"BORROW ON L1, USE IT ON L2."`). A hands-on card's step 1 is `RUN IT.` Steps 2–3 are a short imperative or claim that says what the reader learns there (`"REPAID BEFORE THE TRANSACTION ENDS."`, `"ASK IT, DON'T INSPECT IT"`).
- Regenerate: `python3 scripts/build-llms.py`.

## 7. Done check

```bash
bash scripts/audit.sh && python3 scripts/verify-citations.py && python3 scripts/check-panel-drift.py \
  && python3 scripts/check-excerpts.py && python3 scripts/test_check_excerpts.py \
  && python3 scripts/check-snippet-fidelity.py && python3 scripts/test_snippet_fidelity.py \
  && python3 scripts/build-llms.py --check && python3 scripts/test_build_llms.py \
  && python3 scripts/check-manifest.py && bash scripts/test_run_quickstart.sh \
  && (cd snippets && forge test)
```

Also run: `bash scripts/run-quickstart.sh <page>.html` for a hands-on card, `python3 scripts/sync-embedded-snippets.py --check` for a snippet card, and `node --check` on the extracted inline script.

Then take a screenshot of every step at 1920×1080 and 390×844 and look at each one. Puppeteer is cached under `~/.npm/_npx/*/node_modules`:

```bash
NODE_PATH=$(dirname $(ls -d ~/.npm/_npx/*/node_modules/puppeteer | head -1)) node -e '
const p=require("puppeteer"),path=require("path"),[out,...fs]=process.argv.slice(1),z=t=>new Promise(r=>setTimeout(r,t));
(async()=>{const b=await p.launch();for(const f of fs)for(const [w,h] of [[1920,1080],[390,844]]){
 const g=await b.newPage();await g.setViewport({width:w,height:h});await g.goto("file://"+path.resolve(f),{waitUntil:"load"});await z(300);
 for(const id of ["#tourSkip","#btnStart"]){const e=await g.$(id);if(e){await e.click();await z(250);}}
 const n=await g.$$eval("#dots > *",d=>d.length);if(!n)throw new Error(f+": no steps, did its JS throw?");
 for(let i=0;i<n;i++){if(i)await g.click("#btnNext");await z(400);
  const s=`${out}/${path.basename(f,".html")}-${w}x${h}-s${i+1}.png`;await g.screenshot({path:s,fullPage:w<600});console.log(s);}
 await g.close();}await b.close();})().catch(e=>{console.error(e.message);process.exit(1)});' <outdir> dapp-developers/<page>.html
```

Step dots are `<button>`s, so select `#dots > *` and not `#dots > div`. Then do CONTRIBUTING's "Audit, before merge" pass. Don't commit unless your task says to.
