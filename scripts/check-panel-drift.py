#!/usr/bin/env python3
"""Assert every Solidity line shown in a code panel also exists in a snippet that compiles.

The panels are hand-wrapped to fit a 662px column, so they can't simply BE the
snippet files. But nothing stopped a panel from drifting into Solidity that
would never compile, and Solidity developers copy what they see.

This closes that gap without making the HTML generated: `snippets/*.sol` are
real compilable files, CI compiles them, and this script asserts that every
non-blank line in each page's `codeByStep` appears verbatim in its snippet. So
a panel edit that invents invalid Solidity fails here, and a panel edit that is
genuine forces the same line into a file the compiler checks.

Two embedded whole-file copies get a stricter treatment. Each page's FULL
toggle, and q3's TEST tab, claim to be showing a real file verbatim rather than
a hand-wrapped slice of one, so those are asserted equal to the file line for
line — a claim that would otherwise rot the moment the .sol file is edited.

Only the six dapp-developer pages and one protocol-researcher page (pr5, which
reuses the q1 snippet) are covered. The rollup-operator pages are shell and
the rest of the protocol-researcher pages are Rust/protobuf — different
toolchains, not in scope for this check.

Usage:
  python3 scripts/check-panel-drift.py

Exits non-zero if any panel line is missing from its snippet.
"""

import json
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SNIPPETS = os.path.join(REPO_ROOT, "snippets")

# Every Solidity walkthrough must name its snippet. A new dapp-developers or
# protocol-researchers page with no entry here is a failure, not a silent skip.
#
# That comment was aspirational until 2026-08-26: the coverage scan below only
# read dapp-developers/ and only files matching q[1-9], so a new
# protocol-researchers page WAS a silent skip. It now scans both directories.
SNIPPET_MAP = {
    "pr5-how-the-address-is-derived.html": "q1-compute-address.sol",
    "q2-send-a-cross-chain-call.html": "q2-cross-chain-call.sol",
    "q3-fix-the-msg-sender-gotcha.html": "q3-msg-sender.sol",
    "q4-check-if-an-address-is-a-proxy.html": "q4-proxy-registry.sol",
    "q5-encode-a-calls-content-hash.html": "q5-content-hash.sol",
    "q6-why-you-cant-call-the-manager-directly.html": "q6-manager-direct.sol",
    "q7-your-cross-chain-address.html": "q7-create-proxy.sol",
    "q8-read-a-remote-contracts-state.html": "q8-remote-reads.sol",
    "q9-when-the-proof-fails.html": "q9-when-the-proof-fails.sol",
    "pr7-what-the-refactor-renamed.html": "pr7-renames.sol",
}

# Pages whose panels are deliberately illustrative rather than compilable, and
# so have no snippet to compare against. This is an ALLOWLIST, not a skip: a
# page is exempt only by being named here with a reason, so "no snippet" can
# never mean "nobody looked". A Guide that teaches a scheme rather than an API
# surface is the case this exists for — pinning its panels to a compilable file
# would mean inventing a contract the protocol does not have.
ILLUSTRATIVE_ONLY = {
    "pr6-the-rolling-hash.html":
        "teaches the rolling-hash fold scheme; panels are hash formulas and "
        "elided loops, not a contract anyone should paste (card 1.5)",
}

# Exempt for a different reason: the panels are not Solidity at all, so there is
# no snippet a Solidity compiler could check. Kept separate from
# ILLUSTRATIVE_ONLY so the two reasons cannot be confused — "another toolchain"
# and "deliberately not compilable" are not the same claim, and a page moving
# from one to the other should be a visible edit.
NON_SOLIDITY = {
    "pr1-the-four-components-of-rollup0.html": "Rust (eez-rollup0 crates)",
    "pr2-commit-first-repair-if-needed.html": "Rust (eez-composer)",
    "pr3-the-deriver.html": "Rust (eez-deriver)",
    "pr4-how-the-composer-proves-a-batch.html": "protobuf + Rust constants",
}

# Panel lines that are prose or deliberate elision, not Solidity to compile.
IGNORE_PREFIXES = ("//", "/*", "*", "⋯", "...")


# Pages that embed a verbatim slice of a test file behind the TEST tab.
TEST_SNIPPET_MAP = {
    "q2-send-a-cross-chain-call.html": "test/Q2CrossChainCall.t.sol",
    "q3-fix-the-msg-sender-gotcha.html": "test/Q3MsgSender.t.sol",
    "q5-encode-a-calls-content-hash.html": "test/Q5ContentHash.t.sol",
    "q6-why-you-cant-call-the-manager-directly.html": "test/Q6ManagerDirect.t.sol",
    "q8-read-a-remote-contracts-state.html": "test/Q8RemoteReads.t.sol",
}

# Every Solidity walkthrough also embeds its whole snippet behind the FULL
# toggle, so a reader can go from the teaching slice to something that compiles.
# That is a stricter claim than the panel check above: not "every line I show
# exists in the file" but "this IS the file". So it gets the stricter check —
# same lines, same order, same count. Derived from SNIPPET_MAP rather than
# hand-listed, so a new page cannot ship the toggle without the check.
FULL_SNIPPET_MAP = dict(SNIPPET_MAP)


def panel_lines(html_path):
    src = open(html_path, encoding="utf-8").read()
    m = re.search(r"var codeByStep = (\[.*?\n  \]);", src, re.S)
    if not m:
        raise RuntimeError("codeByStep not found")
    steps = re.findall(r'\[\s*((?:"(?:[^"\\]|\\.)*",?\s*)*)\]', m.group(1))
    out = []
    for step in steps:
        for raw in re.findall(r'"((?:[^"\\]|\\.)*)"', step):
            out.append(json.loads('"' + raw + '"'))
    return out


def test_snippet_lines(html_path):
    """The TEST tab's embedded slice, if the page has one."""
    src = open(html_path, encoding="utf-8").read()
    m = re.search(r"var testSnippet = (\[.*?\n  \]);", src, re.S)
    if not m:
        return []
    return [json.loads('"' + raw + '"')
            for raw in re.findall(r'"((?:[^"\\]|\\.)*)"', m.group(1))]


def full_snippet_lines(html_path):
    """The FULL toggle's embedded whole-file copy, or None if the page has none."""
    src = open(html_path, encoding="utf-8").read()
    m = re.search(r"var fullSnippet = (\[.*?\n  \]);", src, re.S)
    if m is None:
        return None
    return [json.loads('"' + raw + '"')
            for raw in re.findall(r'"((?:[^"\\]|\\.)*)"', m.group(1))]


# Registered pages aren't all in dapp-developers/ any more (a Solidity page
# can move to another track, e.g. pr5) — locate a page by basename across
# every audience-track directory instead of assuming one fixed folder.
TRACK_DIRS = ("dapp-developers", "rollup-operators", "protocol-researchers")


def find_page_path(name):
    for track in TRACK_DIRS:
        candidate = os.path.join(REPO_ROOT, track, name)
        if os.path.exists(candidate):
            return candidate
    return None


def has_code_panels(html_path):
    """True if the page has a codeByStep array, i.e. is an actual walkthrough
    and not a redirect stub (which has no panels to drift-check)."""
    return bool(re.search(r"var codeByStep\s*=",
                           open(html_path, encoding="utf-8").read()))


def main():
    # Both Solidity-bearing tracks, not just the first one.
    present = []
    for track in ("dapp-developers", "protocol-researchers"):
        d = os.path.join(REPO_ROOT, track)
        for f in sorted(os.listdir(d)):
            if f.endswith(".html") and re.match(r"(q|pr)[1-9]", f):
                present.append((f, os.path.join(d, f)))

    failures, checked = [], 0

    for page, path in present:
        if page in SNIPPET_MAP:
            continue
        # q7-test-demo.html is untracked scaffold, not a published walkthrough
        if page.startswith("q7-test-demo"):
            continue
        # A page with no code panels at all (e.g. a moved-away redirect
        # stub) isn't a walkthrough and has nothing for this check to do.
        if not has_code_panels(path):
            continue
        if page in ILLUSTRATIVE_ONLY:
            print(f"  illustrative-only, no snippet compared: {page}")
            print(f"    reason: {ILLUSTRATIVE_ONLY[page]}")
            continue
        if page in NON_SOLIDITY:
            print(f"  not Solidity, nothing to compile: {page} "
                  f"({NON_SOLIDITY[page]})")
            continue
        failures.append(f"{page}: no snippet registered in SNIPPET_MAP (add one, "
                        f"or name it in ILLUSTRATIVE_ONLY / NON_SOLIDITY with a reason)")

    for page, snippet_name in sorted(SNIPPET_MAP.items()):
        page_path = find_page_path(page)
        if page_path is None:
            failures.append(f"{page}: registered in SNIPPET_MAP but the page is missing")
            continue

        snippet_path = os.path.join(SNIPPETS, snippet_name)
        if not os.path.exists(snippet_path):
            failures.append(f"{page}: snippet missing at snippets/{snippet_name}")
            continue

        snippet = {ln.rstrip() for ln in open(snippet_path, encoding="utf-8").read().splitlines()}

        try:
            lines = panel_lines(page_path)
        except RuntimeError as e:
            failures.append(f"{page}: {e}")
            continue

        for ln in lines:
            stripped = ln.strip()
            if not stripped or stripped.startswith(IGNORE_PREFIXES):
                continue
            checked += 1
            if ln.rstrip() not in snippet:
                failures.append(
                    f"{page}: panel line not in snippets/{snippet_name}:\n"
                    f"        {ln.rstrip()!r}")

    # The TEST tab claims to show a verbatim slice of a real test file. Prove it.
    for page, rel in TEST_SNIPPET_MAP.items():
        page_path = find_page_path(page)
        test_path = os.path.join(SNIPPETS, rel)
        if page_path is None:
            failures.append(f"{page}: registered in TEST_SNIPPET_MAP but the page is missing")
            continue
        if not os.path.exists(test_path):
            failures.append(f"{page}: test file missing at snippets/{rel}")
            continue
        embedded = test_snippet_lines(page_path)
        if not embedded:
            failures.append(f"{page}: TEST tab registered but no testSnippet found")
            continue
        actual = {ln.rstrip() for ln in open(test_path, encoding="utf-8").read().splitlines()}
        for ln in embedded:
            if not ln.strip():
                continue
            checked += 1
            if ln.rstrip() not in actual:
                failures.append(
                    f"{page}: TEST tab line not in snippets/{rel}:\n"
                    f"        {ln.rstrip()!r}")

    # The FULL toggle claims the panel is showing the snippet file itself. An
    # embedded copy that nothing checks is a copy that silently rots, so this
    # asserts equality line for line, including blanks and line count.
    for page, rel in sorted(FULL_SNIPPET_MAP.items()):
        page_path = find_page_path(page)
        snippet_path = os.path.join(SNIPPETS, rel)
        if page_path is None:
            failures.append(f"{page}: registered in FULL_SNIPPET_MAP but the page is missing")
            continue
        if not os.path.exists(snippet_path):
            failures.append(f"{page}: snippet missing at snippets/{rel}")
            continue
        embedded = full_snippet_lines(page_path)
        if embedded is None:
            failures.append(f"{page}: no fullSnippet array - the FULL toggle has nothing to show")
            continue
        actual = [ln.rstrip() for ln in
                  open(snippet_path, encoding="utf-8").read().splitlines()]
        if len(embedded) != len(actual):
            failures.append(
                f"{page}: fullSnippet has {len(embedded)} lines but "
                f"snippets/{rel} has {len(actual)} - re-embed the file")
        for i, actual_line in enumerate(actual):
            checked += 1
            if i >= len(embedded):
                failures.append(
                    f"{page}: fullSnippet is missing snippets/{rel}:{i + 1}:\n"
                    f"        {actual_line!r}")
                continue
            if embedded[i].rstrip() != actual_line:
                failures.append(
                    f"{page}: fullSnippet line {i + 1} differs from snippets/{rel}:{i + 1}\n"
                    f"        embedded: {embedded[i].rstrip()!r}\n"
                    f"        file:     {actual_line!r}")

    print(f"pages checked: {len(SNIPPET_MAP)}   panel lines asserted: {checked}")
    if failures:
        print(f"\nFAILED ({len(failures)}):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("Every panel line is backed by a line in a compilable snippet.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
