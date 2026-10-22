# EEZ Quickstarts

Short, step-by-step walkthroughs of how EEZ works, for dApp developers, rollup operators and protocol researchers. Each one pairs a diagram with real protocol code, cited at a pinned commit.

- **Site:** [eez-association.github.io/eez-demos](https://eez-association.github.io/eez-demos)
- **Live network:** [EEZ-X dashboard](https://mainnet.eez.dev/dashboard/)
- **For agents:** [`llms.txt`](llms.txt) · [`llms-full.txt`](llms-full.txt)

## Run locally

```bash
git clone https://github.com/eez-association/eez-demos.git
cd eez-demos && python3 -m http.server 8000
```

Static HTML, no build step. Pushing to `main` deploys the site.

## Contribute

```bash
bash scripts/audit.sh
python3 scripts/build-llms.py --check
```

Code is quoted verbatim and cited by `file:line`. See [CONTRIBUTING.md](CONTRIBUTING.md) for the checklist.
