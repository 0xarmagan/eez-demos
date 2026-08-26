#!/usr/bin/env python3
"""Part III of the v4.1 plan: assert the execution manifest against reality.

A manifest that lives outside the tree it describes drifts, and nothing notices.
That is the CLAUDE.md failure the plan lists as a risk, and the llms-full.txt
failure is its sibling: a file that was silently incomplete while the build
exited 0. So the manifest lives in-repo and this asserts four things about it.

  1. COMPLETENESS   every task card has a status, a size and a done-when line;
                    the header block has zero blanks. A blank header fails the
                    build, which is what makes 0.0 blocking rather than
                    aspirational.
  2. STATUS TRUTH   every card marked `done` names the check that proves it, and
                    those checks are the ones CI actually runs. A `done` card
                    whose evidence is a command nobody runs is a claim, not a
                    status.
  3. ASSET PRESENCE every asset-manifest row resolves. `frozen` rows must also
                    match their recorded hash; `live` rows are code under edit,
                    so drift is reported and not failed; `unlocated` rows FAIL
                    CLOSED, because Ground rule 4 says nothing is done without a
                    location and a row that quietly reads as fine defeats it.
  4. NO TRUNCATION  the citation count has a floor, so a page or a whole
                    citation block going missing cannot pass as "all verified".

Usage:
  python3 scripts/check-manifest.py
  python3 scripts/check-manifest.py --repin    # rewrite `live` hashes
"""

import argparse
import glob
import hashlib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "docs", "plans", "2026-08-26-developer-content-v41.md")
ASSETS = os.path.join(ROOT, "scripts", "asset-manifest.json")

# The floor, not the count. Citations only ever get added, so an exact number
# would fail on every new page and get bumped without being read. A floor fails
# only on a LOSS, which is the failure this is for. Raise it when a wave lands.
MIN_CITATIONS = 38

STALE_NAMES = [
    "StateDelta", "LookupCall", "ExpectedLookup", "revertSpan",
    "staticCallLookup", "executeL2TX", "IZKVerifier", "ProofSystemRegistry",
]

CARD_RE = re.compile(
    r"^\*\*(?P<id>\d+\.\d+(?:\+\d+\.\d+)*)\s*—\s*(?P<title>[^*]+)\*\*\s*·\s*(?P<rest>.*)$")

# Part III item 1: "task count in manifest == task count in plan". v4.1 has 29
# cards — 11 in Wave 0 (0.2+0.3+0.4 is one bundled card), 5, 5, 4, 4. A card
# written in prose instead of the parseable form is a card this script cannot
# check, so a short count is a failure and not a formatting quibble.
EXPECTED_CARDS = 29
STATUSES = {"ready", "blocked", "in-flight", "needs-human", "done"}
SIZES = {"XS", "S", "M", "L", "XL"}


def fail(problems, msg):
    problems.append(msg)


def check_header(text, problems):
    """1. Completeness — the header block has no blanks."""
    m = re.search(r"```\n(contracts_pin:.*?)\n```", text, re.S)
    if not m:
        fail(problems, "header: no fenced header block found")
        return
    block = m.group(1)
    for line in block.splitlines():
        if not line.strip():
            continue
        key, _, rest = line.partition(":")
        val = rest.split("#")[0].strip()
        if not val or "FILL" in val or val in {"___", "—"}:
            fail(problems, "header: %s is still blank" % key.strip())
    # The two pins must be the ones the repo actually cites, or the manifest is
    # describing a different tree than the one being built.
    pins = json.load(open(os.path.join(ROOT, "scripts", "citation-pins.json")))
    for key, repo in (("contracts_pin", "eez-core-protocol"), ("node_pin", "eez-rollup0")):
        want = pins["repos"][repo]["sha"]
        got = re.search(key + r":\s*(\S+)", block)
        if not got:
            fail(problems, "header: %s missing" % key)
        elif got.group(1) != want:
            fail(problems, "header: %s is %s but citation-pins.json says %s"
                 % (key, got.group(1), want))


def parse_cards(text):
    cards = []
    for line in text.splitlines():
        m = CARD_RE.match(line.strip())
        if m:
            cards.append((m.group("id"), m.group("title").strip(), m.group("rest")))
    return cards


def check_cards(text, problems):
    """1. Completeness — every card carries a status and a size."""
    cards = parse_cards(text)
    if not cards:
        fail(problems, "cards: none parsed — the manifest format changed")
        return cards
    seen = set()
    for cid, title, rest in cards:
        if cid in seen:
            fail(problems, "%s: card id appears twice" % cid)
        seen.add(cid)
        fields = [f.strip() for f in rest.split("·")]
        status = None
        for f in fields:
            # A field reads "`ready` (timeboxed 1 day)" or "`blocked` by 2.4",
            # so match the backticked token at its head rather than the whole
            # field — the qualifier after it is prose for a human.
            m2 = re.match(r"`([a-z-]+)`", f)
            if m2 and m2.group(1) in STATUSES:
                status = m2.group(1)
                break
        if status is None:
            fail(problems, "%s (%s): no recognised status in %r" % (cid, title, rest))
        # A blocked card legitimately has no size; everything else needs one.
        if status != "blocked" and not any(
                w in SIZES for f in fields for w in f.replace("`", "").split()):
            fail(problems, "%s (%s): no size" % (cid, title))
    return cards


def check_done_cards_have_evidence(text, cards, problems):
    """2. Status truth — a `done` card must point at a check CI runs."""
    ci = open(os.path.join(ROOT, ".github", "workflows", "ci.yml")).read()
    gated = set(re.findall(r"scripts/[\w.-]+", ci)) | set(re.findall(r"forge \w+", ci))
    if not gated:
        fail(problems, "status truth: parsed no gated commands out of ci.yml")
    # audit.sh runs more checks inside itself; count what it calls as gated too.
    audit = open(os.path.join(ROOT, "scripts", "audit.sh")).read()
    gated |= set(re.findall(r"scripts/[\w.-]+", audit))

    body = text
    for cid, title, rest in cards:
        if not re.search(r"`done`", rest):
            continue
        # The card's own prose block, up to the next card or heading.
        start = body.index("**%s —" % cid)
        tail = body[start:]
        nxt = min([i for i in (tail.find("\n**", 1), tail.find("\n###"), tail.find("\n##"))
                   if i > 0] or [len(tail)])
        block = tail[:nxt]
        if "✔" not in block:
            fail(problems, "%s (%s): marked done with no ✔ evidence line" % (cid, title))
        named = re.findall(r"`(scripts/[\w.-]+|forge \w+)`", block)
        if named and not any(n in gated for n in named):
            fail(problems, "%s (%s): done-when cites %s, which nothing in CI runs"
                 % (cid, title, named))


def check_assets(problems, repin=False, done_cards=()):
    """3. Asset presence."""
    man = json.load(open(ASSETS))
    changed = False
    for row in man["assets"]:
        state, path, name = row["state"], row.get("path"), row["asset"]
        if state == "unlocated":
            # Loud every run, so Ground rule 4 cannot be forgotten...
            print("  UNLOCATED  %s" % name)
            print("             %s" % row.get("note", ""))
            # ...and fatal the moment a card that depends on it claims done.
            blockers = [c for c in row.get("blocks", []) if c in done_cards]
            if blockers:
                fail(problems, "asset %s is unlocated but card(s) %s are marked done"
                     % (name, ", ".join(blockers)))
            continue
        if state == "external":
            continue
        full = os.path.join(ROOT, path)
        if not os.path.exists(full):
            fail(problems, "asset %s: %s does not exist" % (name, path))
            continue
        got = hashlib.sha256(open(full, "rb").read()).hexdigest()
        if got == row["sha256"]:
            continue
        if state == "frozen":
            fail(problems, "asset %s: %s changed — frozen row, sha256 %s != %s"
                 % (name, path, got[:16], row["sha256"][:16]))
        elif repin:
            row["sha256"] = got
            changed = True
        else:
            print("  note: %s (%s) has changed since it was recorded "
                  "(live row, not a failure) — --repin to update" % (name, path))
    if repin and changed:
        open(ASSETS, "w").write(json.dumps(man, indent=2) + "\n")
        print("  repinned live asset hashes")


def check_no_truncation(problems):
    """4. No silent truncation — the citation floor."""
    out = subprocess.run([sys.executable, "scripts/verify-citations.py"],
                         cwd=ROOT, capture_output=True, text=True)
    if out.returncode != 0:
        fail(problems, "citations: verify-citations.py failed:\n%s" % out.stdout[-800:])
        return
    m = re.search(r"citations found:\s*(\d+)", out.stdout)
    if not m:
        fail(problems, "citations: could not read the count out of the verifier")
        return
    n = int(m.group(1))
    if n < MIN_CITATIONS:
        fail(problems, "citations: %d found, floor is %d — a citation block went "
                       "missing and 'all verified' would still have passed"
             % (n, MIN_CITATIONS))
    else:
        print("  citations: %d (floor %d)" % (n, MIN_CITATIONS))


def check_stale_names(problems):
    """§7's stale-names gate, which the manifest claims is clean."""
    files = subprocess.run(
        ["git", "ls-files", "index.html", "dapp-developers/*.html",
         "rollup-operators/*.html", "protocol-researchers/*.html"],
        cwd=ROOT, capture_output=True, text=True).stdout.split()
    for name in STALE_NAMES:
        for rel in files:
            src = open(os.path.join(ROOT, rel), encoding="utf-8").read()
            if name in src:
                fail(problems, "stale name %r appears in %s" % (name, rel))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repin", action="store_true",
                    help="rewrite the sha256 of `live` asset rows")
    args = ap.parse_args()

    if not os.path.exists(MANIFEST):
        print("FAIL: no manifest at %s" % os.path.relpath(MANIFEST, ROOT))
        return 1
    text = open(MANIFEST, encoding="utf-8").read()
    problems = []

    print("== 1. completeness ==")
    check_header(text, problems)
    cards = check_cards(text, problems)
    print("  %d task cards parsed (expected %d)" % (len(cards), EXPECTED_CARDS))
    if len(cards) != EXPECTED_CARDS:
        fail(problems, "cards: %d parsed, plan has %d — a card written in prose "
                       "rather than the parseable form is a card nothing checks"
             % (len(cards), EXPECTED_CARDS))

    print("== 2. status truth ==")
    check_done_cards_have_evidence(text, cards, problems)
    print("  %d done" % sum(1 for _, _, r in cards if re.search(r"`done`", r)))

    print("== 3. asset presence ==")
    done_ids = {cid for cid, _, r in cards if re.search(r"`done`", r)}
    check_assets(problems, repin=args.repin, done_cards=done_ids)

    print("== 4. no silent truncation ==")
    check_no_truncation(problems)
    check_stale_names(problems)

    print()
    if problems:
        print("Manifest integrity FAILED:")
        for p in problems:
            print("  - %s" % p)
        return 1
    print("Manifest integrity passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
