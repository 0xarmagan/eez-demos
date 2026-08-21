# eez-demos

14 short animated walkthroughs (diagram, real code, one-sentence caption) showing how EEZ actually works. Live at [eez-demos.vercel.app](https://eez-demos.vercel.app).

- **Dapp developers** (6) — making or receiving cross-chain calls
- **Rollup operators** (4) — standing up or running a rollup
- **Protocol researchers** (4) — execution model, settlement, invariants

Every code panel cites a real, verified `file:line` — pre-mainnet, every page says so.

*Static site, one `index.html`, no build step. Deployed on Vercel, git-linked (push to `main` deploys).*

## Contributing

```bash
git clone https://github.com/0xarmagan/eez-demos.git && cd eez-demos
npx serve .   # or: python3 -m http.server 8000
```

Add a new example (scaffolds the file only — wiring it into `index.html` and the `NEXT:` chain is manual):

```bash
scripts/new-demo.sh rollup-operators ro5-my-topic "My Topic"
```

Run `scripts/audit.sh` before opening a PR. Full checklist and citation rules in [CONTRIBUTING.md](CONTRIBUTING.md).
