#!/usr/bin/env python3
"""Verify every source citation on the site against real upstream source.

scripts/audit.sh checks that citations are well-formed. It says so itself:
"This does NOT verify citations against real source." This script is that
missing half.

For each citation it fetches the referenced file at the pinned commit SHA and
asserts:

  1. the file exists at that SHA
  2. every claimed line number exists
  3. if the citation names a symbol (the "... :176 - computeCrossChainProxyAddress"
     form), that symbol really appears within a few lines of the claimed line

Citations are the credibility of this site, and they are the one thing that
rots without anyone touching the repo: upstream adds an import, every line
number below it shifts, and the citation is silently wrong. Pinning to a SHA
freezes that, and this script proves the pin is still honest.

Usage:
  python3 scripts/verify-citations.py             # verify
  python3 scripts/verify-citations.py --repin     # rewrite blob/<old> -> pinned SHA
  python3 scripts/verify-citations.py --offline   # use only the local cache

Exits non-zero if any citation fails.
"""

import argparse
import glob
import html
import json
import os
import re
import sys
import urllib.error
import urllib.request

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PINS_PATH = os.path.join(REPO_ROOT, "scripts", "citation-pins.json")
CACHE_DIR = os.path.join(REPO_ROOT, ".citation-cache")
ORG = "eez-association"
HTML_GLOBS = ["dapp-developers/*.html", "rollup-operators/*.html", "protocol-researchers/*.html"]
# How far from the claimed line the named symbol may appear. Upstream reformats
# signatures across lines, so an exact-line match is too brittle to be useful.
SYMBOL_WINDOW = 4

# Linked citations: <a href=".../blob/<sha>/<path>#L12-L13">display text</a>
LINK_RE = re.compile(
    r'href="https://github\.com/' + ORG + r'/(?P<repo>[^/]+)/blob/(?P<sha>[^/]+)/'
    r'(?P<path>[^"#]+)(?P<frag>#L[\dL\-]+)?"[^>]*>(?P<text>[^<]*)</a>'
)
# pr1-style plain citation objects: { label: "Composer", loc: "crates/x.rs:515", ... }
LOC_RE = re.compile(r'loc:\s*"(?P<loc>[^"]+)"')
# pr1 builds its <a href> at runtime from a url: field, so LINK_RE cannot see it.
# It still has to be pinned and repinned like every other citation link.
URL_RE = re.compile(
    r'url:\s*"https://github\.com/' + ORG + r'/(?P<repo>[^/]+)/blob/(?P<sha>[^/]+)/'
    r'(?P<path>[^"#]+)(?P<frag>#L[\dL\-]+)?"'
)


def load_pins():
    with open(PINS_PATH) as fh:
        return json.load(fh)["repos"]


def fetch(repo, sha, path, offline):
    """Return the file's lines at that SHA, using a local cache."""
    key = f"{repo}@{sha}@{path}".replace("/", "__")
    cached = os.path.join(CACHE_DIR, key)
    if os.path.exists(cached):
        with open(cached, encoding="utf-8", errors="replace") as fh:
            return fh.read().splitlines()
    if offline:
        raise RuntimeError(f"not cached and --offline given: {repo}/{path}")
    url = f"https://raw.githubusercontent.com/{ORG}/{repo}/{sha}/{path}"
    req = urllib.request.Request(url, headers={"User-Agent": "eez-demos-citation-verifier"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = resp.read().decode("utf-8", errors="replace")
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(cached, "w", encoding="utf-8") as fh:
        fh.write(body)
    return body.splitlines()


def parse_lines(spec):
    """'#L64-L65' or ':52 / :134' or ':176' -> [64, 65] / [52, 134] / [176]"""
    return [int(n) for n in re.findall(r"(\d+)", spec or "")]


def symbol_from_text(text):
    """'.../EEZBase.sol:176 - computeCrossChainProxyAddress ^' -> 'computeCrossChainProxyAddress'"""
    text = html.unescape(text)
    # the site separates path from symbol with a middot
    if "·" not in text:
        return None
    tail = text.split("·")[-1]
    tail = tail.replace("↗", "").strip()
    # only treat it as a symbol if it looks like an identifier or dotted path
    if re.fullmatch(r"[A-Za-z_][\w.:<>\-]*", tail or ""):
        return tail
    return None


def collect():
    """Every citation on the site, as dicts."""
    out = []
    for pattern in HTML_GLOBS:
        for path in sorted(glob.glob(os.path.join(REPO_ROOT, pattern))):
            rel = os.path.relpath(path, REPO_ROOT)
            src = open(path, encoding="utf-8").read()
            for m in LINK_RE.finditer(src):
                out.append({
                    "page": rel, "kind": "link", "repo": m.group("repo"),
                    "sha": m.group("sha"), "path": m.group("path"),
                    "lines": parse_lines(m.group("frag")),
                    "symbol": symbol_from_text(m.group("text")),
                    "text": html.unescape(m.group("text")).strip(),
                })
            for m in URL_RE.finditer(src):
                out.append({
                    "page": rel, "kind": "link", "repo": m.group("repo"),
                    "sha": m.group("sha"), "path": m.group("path"),
                    "lines": parse_lines(m.group("frag")),
                    "symbol": None,
                    "text": m.group("path"),
                })
            for m in LOC_RE.finditer(src):
                loc = m.group("loc")
                fpath = loc.split(":")[0]
                repo = "eez-rollup0" if fpath.startswith(("crates/", "testing/")) else "eez-core-protocol"
                out.append({
                    "page": rel, "kind": "loc", "repo": repo, "sha": None,
                    "path": fpath, "lines": parse_lines(loc[len(fpath):]),
                    "symbol": None, "text": loc,
                })
    return out


def repin(pins):
    """Rewrite every citation link to the pinned SHA."""
    changed = 0
    for pattern in HTML_GLOBS:
        for path in sorted(glob.glob(os.path.join(REPO_ROOT, pattern))):
            src = open(path, encoding="utf-8").read()
            orig = src

            def sub(m):
                repo = m.group("repo")
                want = pins.get(repo, {}).get("sha")
                if not want or m.group("sha") == want:
                    return m.group(0)
                return m.group(0).replace(f"/blob/{m.group('sha')}/", f"/blob/{want}/", 1)

            src = LINK_RE.sub(sub, src)
            src = URL_RE.sub(sub, src)
            if src != orig:
                open(path, "w", encoding="utf-8").write(src)
                changed += 1
    return changed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repin", action="store_true", help="rewrite links to the pinned SHAs")
    ap.add_argument("--offline", action="store_true", help="use only the local cache")
    args = ap.parse_args()

    pins = load_pins()

    if args.repin:
        n = repin(pins)
        print(f"repinned citation links in {n} file(s)")

    citations = collect()
    if not citations:
        print("FAIL: no citations found - did the markup change?")
        return 1

    failures, checked = [], 0
    for c in citations:
        want_sha = pins.get(c["repo"], {}).get("sha")
        if not want_sha:
            failures.append(f"{c['page']}: no pinned SHA for repo '{c['repo']}'")
            continue
        if c["kind"] == "link" and c["sha"] != want_sha:
            failures.append(
                f"{c['page']}: link points at '{c['sha'][:12]}' but pin is "
                f"'{want_sha[:12]}' ({c['path']}) - run --repin")
            continue
        try:
            lines = fetch(c["repo"], want_sha, c["path"], args.offline)
        except urllib.error.HTTPError as e:
            failures.append(f"{c['page']}: {c['repo']}/{c['path']} -> HTTP {e.code} at {want_sha[:12]}")
            continue
        except Exception as e:  # noqa: BLE001 - report and keep going
            failures.append(f"{c['page']}: {c['repo']}/{c['path']} -> {e}")
            continue

        for ln in c["lines"]:
            if ln < 1 or ln > len(lines):
                failures.append(
                    f"{c['page']}: {c['path']}:{ln} out of range "
                    f"(file has {len(lines)} lines at {want_sha[:12]})")
                continue
            if c["symbol"]:
                lo = max(0, ln - 1 - SYMBOL_WINDOW)
                hi = min(len(lines), ln + SYMBOL_WINDOW)
                window = "\n".join(lines[lo:hi])
                if c["symbol"] not in window:
                    failures.append(
                        f"{c['page']}: '{c['symbol']}' not found within "
                        f"{SYMBOL_WINDOW} lines of {c['path']}:{ln} "
                        f"- got: {lines[ln - 1].strip()[:64]!r}")
            checked += 1
        if not c["lines"]:
            checked += 1

    print(f"\ncitations found: {len(citations)}   assertions checked: {checked}")
    if failures:
        print(f"\nFAILED ({len(failures)}):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("All citations verified against real upstream source at the pinned SHAs.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
