# eez-demos

Learn how EEZ actually works. 14 short animated walkthroughs (3 steps each: real diagram, real code, one-sentence caption) linked from cards on one `index.html`. Live at [eez-demos.vercel.app](https://eez-demos.vercel.app).

New here? The landing page opens with three picks — one per audience — before the full list.

Three audiences, all live:

- **Dapp developers** (6) — building a contract that makes or receives cross-chain calls.
- **Rollup operators** (4) — standing up or running a rollup on EEZ.
- **Protocol researchers** (4) — execution model, settlement, invariants.

Every code panel cites a real, verified `file:line` — pre-mainnet, every page says so. Sourcing rules (`eez-core-protocol` is pinned, not tracking `main`) are in `CONTRIBUTING.md`.

*Static site — one `index.html`, no build step. Deployed on Vercel, git-linked (push to `main` deploys).*

## Contributing

Run it locally:

```bash
git clone https://github.com/0xarmagan/eez-demos.git && cd eez-demos
npx serve .   # or: python3 -m http.server 8000 — no build step either way
```

Add a new example — scaffolds the file only, doesn't wire it into `index.html` or the `NEXT:` chain (that's still manual, see `CONTRIBUTING.md`):

```bash
scripts/new-demo.sh rollup-operators ro5-my-topic "My Topic"
```

Before opening a PR:

```bash
scripts/audit.sh   # broken links, invalid JS, leftover TODOs, marketing language
```

PRs are reviewed before merge — see `CONTRIBUTING.md` for the full checklist, the citation rules (`eez-core-protocol` is pinned, not tracking `main`), and the independent audit pass every new example gets before it ships.
