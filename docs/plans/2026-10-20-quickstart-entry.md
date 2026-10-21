# Quickstart entry, honesty block, deep links

Base: `main` @ `d9974f1` (merge of #39). Branch: `feat/quickstart-entry`.
Source: external UX review of eez-association.github.io/eez-demos, 2026-10-20, re-checked against the live site.

| # | Commit | Review findings | Status |
|---|---|---|---|
| 0 | One navigation system, one label per audience | 3 | done; re-applies #13's UX-3 intent (its commits no longer apply), tour hunk dropped |
| 1 | Hero definition, one Start button, `start-here` links, `aria-pressed` | 1, 2, 6 | done |
| 2 | Coming-soon card out of the numbered sequence; filters lose "+ 1 SOON" | 8 (quickstart only), 9 | done |
| 3 | `assets/eez-steps.js` (`#step-N`, replaceState) + `<noscript>` on 24 pages | 4, 14 | done |
| 4 | "What this proves / what it doesn't" on qs1, qs7, qs8 + export parity + test | 5 | done |

## Constraints checked against source

- CI does not run the quickstarts: `run-quickstart.sh --extract-only` only lists commands and checks the pin (`ci.yml:71`).
- Locally a batch IS posted (`postAndVerifyBatch`) and accepted by `AcceptAllProofSystem` (`script/e2e/lib/E2EBase.sh:63` at `9a1f815`). Never write "no batch".
- `index_cards()` only reads `<a class="card" href>`, so the unlinked coming-soon card cannot reach `llms.txt`.

## Left open

- #13 and #16: close as superseded once this lands (needs owner OK).
- Finding 10: qs5 slug says "three-gotchas", page says two. Slug kept so no URL breaks.
- Finding 8 beyond the quickstart: reference/ops/researcher series still restart at 01.
- Geometry check (`check-panel-geometry.cjs`) not run locally — puppeteer not installed; CI runs it.
- Out of scope (P2): og:image, sitemap, robots.txt, JSON-LD, full-text search, progress memory, panel density.
