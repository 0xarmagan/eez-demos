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

Only the six dapp-developer pages are covered. The rollup-operator pages are
shell and the protocol-researcher pages are Rust/protobuf — different
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

# Every Solidity walkthrough must name its snippet. A new dapp-developers page
# with no entry here is a failure, not a silent skip.
SNIPPET_MAP = {
    "q1-compute-your-cross-chain-address.html": "q1-compute-address.sol",
    "q2-send-a-cross-chain-call.html": "q2-cross-chain-call.sol",
    "q3-fix-the-msg-sender-gotcha.html": "q3-msg-sender.sol",
    "q4-check-if-an-address-is-a-proxy.html": "q4-proxy-registry.sol",
    "q5-encode-a-calls-content-hash.html": "q5-content-hash.sol",
    "q6-why-you-cant-call-the-manager-directly.html": "q6-manager-direct.sol",
}

# Panel lines that are prose or deliberate elision, not Solidity to compile.
IGNORE_PREFIXES = ("//", "/*", "*", "⋯", "...")


# Pages that embed a verbatim slice of a test file behind the TEST tab.
TEST_SNIPPET_MAP = {
    "q3-fix-the-msg-sender-gotcha.html": "test/Q3MsgSender.t.sol",
}


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


def main():
    pages_dir = os.path.join(REPO_ROOT, "dapp-developers")
    present = sorted(
        f for f in os.listdir(pages_dir)
        if f.endswith(".html") and re.match(r"q[1-9]", f)
    )

    failures, checked = [], 0

    for page in present:
        # q7-test-demo.html is untracked scaffold, not a published walkthrough
        if page not in SNIPPET_MAP:
            if page.startswith("q7-test-demo"):
                continue
            failures.append(f"{page}: no snippet registered in SNIPPET_MAP")
            continue

        snippet_path = os.path.join(SNIPPETS, SNIPPET_MAP[page])
        if not os.path.exists(snippet_path):
            failures.append(f"{page}: snippet missing at snippets/{SNIPPET_MAP[page]}")
            continue

        snippet = {ln.rstrip() for ln in open(snippet_path, encoding="utf-8").read().splitlines()}

        try:
            lines = panel_lines(os.path.join(pages_dir, page))
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
                    f"{page}: panel line not in snippets/{SNIPPET_MAP[page]}:\n"
                    f"        {ln.rstrip()!r}")

    # The TEST tab claims to show a verbatim slice of a real test file. Prove it.
    for page, rel in TEST_SNIPPET_MAP.items():
        page_path = os.path.join(pages_dir, page)
        test_path = os.path.join(SNIPPETS, rel)
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
