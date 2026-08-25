#!/usr/bin/env python3
"""Generate /llms.txt and /llms-full.txt from the real page and snippet content.

Per llmstxt.org: an H1 (the only required part), a blockquote summary, optional
prose, then H2 sections of markdown link lists. llms.txt is the index;
llms-full.txt inlines everything, which is the pattern docs.cow.fi uses.

This exists because the walkthroughs render their code from JS arrays at
runtime. The pages are useful to a person and nearly opaque to anything that
fetches them: curl gets the shell, and so does an agent. Everything of value —
the snippets, the citations, the tests — is behind a render. These two files
hand it over directly.

Generated, never hand-edited, for the same reason the embedded snippets are
generated: a hand-maintained copy of every page's content would be wrong within a
week. `--check` fails if the committed files are stale, so CI catches that.

Usage:
  python3 scripts/build-llms.py            # write llms.txt and llms-full.txt
  python3 scripts/build-llms.py --check    # exit 1 if either is out of date
"""

import glob
import html as html_mod
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = "https://0xarmagan.github.io/eez-demos"

TRACKS = [
    ("dapp-developers", "Dapp developers",
     "Writing contracts that call across rollups."),
    ("rollup-operators", "Rollup operators",
     "Standing the stack up and driving it."),
    ("protocol-researchers", "Protocol researchers",
     "How Rollup0 actually settles and proves."),
]

# Panel language per citation target, so fenced blocks are tagged usefully.
def lang_for(path, track):
    if path.endswith(".sol"):
        return "solidity"
    if path.endswith(".rs"):
        return "rust"
    if path.endswith(".proto"):
        return "protobuf"
    if track == "rollup-operators":
        return "bash"
    return "text"


def strip_tags(s):
    return html_mod.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", s))).strip()


def js_array(src, name):
    m = re.search(r"var " + name + r" = (\[.*?\n  \]);", src, re.S)
    if not m:
        return None
    return m.group(1)


def flat_strings(block):
    if not block:
        return []
    return [json.loads('"' + x + '"')
            for x in re.findall(r'"((?:[^"\\]|\\.)*)"', block)]


def top_level_items(raw):
    """The outer array's elements, as source text, split on depth-0 commas.

    Splitting on a regex instead lost whichever elements the regex didn't
    happen to describe, silently and without changing the step count. This
    hands back every element, so an unreadable one is a shape this file has
    to answer for rather than a step that quietly disappears.
    """
    body = raw.strip()[1:-1]                     # drop the outer [ ]
    items, buf, depth, quote, esc = [], [], 0, None, False
    for ch in body:
        if quote:
            buf.append(ch)
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == quote:
                quote = None
            continue
        if ch in "\"'":
            quote = ch
        elif ch in "[({":
            depth += 1
        elif ch in "])}":
            depth -= 1
        elif ch == "," and depth == 0:
            items.append("".join(buf))
            buf = []
            continue
        buf.append(ch)
    items.append("".join(buf))
    return [it.strip() for it in items if it.strip()]


def steps_of(src, rel="a page"):
    """codeByStep as a list of per-step line lists.

    Two shapes are in use. Most pages write each step as an inline array of
    string literals. The progressive-reveal pages (ro2, ro4) declare one named
    array of lines and take a growing prefix of it per step —
    `makefileLines.slice(0, 6)` — which carries no string literal at all, so
    reading literals out of codeByStep returned nothing for them and the build
    still exited 0. Both pages shipped a title, a source line and no code.

    Hence: resolve `<name>.slice(a, b)` against the named array declared in the
    same file, and refuse — loudly — any element this function cannot read, or
    a codeByStep that yields no lines. A third way of building panels must
    fail the build, not vanish from the corpus.
    """
    raw = js_array(src, "codeByStep")
    if not raw:
        return []
    steps = []
    for item in top_level_items(raw):
        if item.startswith("["):
            steps.append(flat_strings(item))
            continue
        m = re.match(r"([A-Za-z_$][\w$]*)\.slice\(\s*(-?\d+)\s*"
                     r"(?:,\s*(-?\d+)\s*)?\)$", item)
        if not m:
            raise ValueError(
                "%s: codeByStep element is neither a literal array nor a "
                "<name>.slice(a[, b]) reference, so its code would be dropped "
                "from llms-full.txt: %s" % (rel, item.replace("\n", " ")[:120]))
        base = js_array(src, m.group(1))
        if base is None:
            raise ValueError("%s: codeByStep references %s.slice(...) but no "
                             "`var %s = [...]` is declared in the page"
                             % (rel, m.group(1), m.group(1)))
        lines = flat_strings(base)
        start = int(m.group(2))
        end = None if m.group(3) is None else int(m.group(3))
        steps.append(lines[start:] if end is None else lines[start:end])
    if not any(steps):
        raise ValueError("%s: declares codeByStep but yielded zero lines — "
                         "the page would emit a header with no code" % rel)
    return steps


def diffs_of(src):
    """diffByStep as a list of {line_index: "del"|"add"} per step, or None."""
    m = re.search(r"var diffByStep = (\[.*?\]);", src, re.S)
    if not m:
        return []
    out = []
    # split the outer array on top-level commas between `null` and `{...}` items
    for tok in re.findall(r"null|\{[^}]*\}", m.group(1)):
        if tok == "null":
            out.append({})
        else:
            out.append({int(k): v for k, v in
                        re.findall(r'(\d+)\s*:\s*"(del|add)"', tok)})
    return out


def citation_of(src):
    """(display text, url, short sha, repo-relative path) for the page's citation."""
    m = re.search(
        r'href="(https://github\.com/eez-association/([^/]+)/blob/([0-9a-f]{7,40})/([^"#]+)'
        r'(#L[\dL\-]+)?)"[^>]*>([^<]*)</a>', src)
    if m:
        return (html_mod.unescape(m.group(6)).replace("↗", "").strip(),
                m.group(1), m.group(3)[:7], m.group(4))
    # pr1 keeps its citations in a JS array instead of an anchor in the markup
    locs = re.findall(r'loc:\s*"([^"]+)"', src)
    urls = re.findall(r'url:\s*"([^"]+)"', src)
    if locs:
        sha = ""
        if urls:
            sm = re.search(r"/blob/([0-9a-f]{7,40})/", urls[0])
            sha = sm.group(1)[:7] if sm else ""
        return (" · ".join(locs), urls[0] if urls else "", sha, locs[0].split(":")[0])
    return ("", "", "", "")


def index_cards():
    src = open(os.path.join(ROOT, "index.html"), encoding="utf-8").read()
    out = {}
    fuller = {}
    for href, body in re.findall(r'<a class="card"[^>]*href="([^"]+)"[^>]*>(.*?)</a>', src, re.S):
        rel = href.lstrip("./")
        # The title is an <h3> that opens with a card-number span, so stopping
        # at the first "</" captures the number instead of the title.
        t = re.search(r'class="card-title"[^>]*>(.*?)</h3>', body, re.S)
        h = re.search(r'class="card-hook"[^>]*>(.*?)</p>', body, re.S)
        title = rel
        if t:
            inner = re.sub(r'<span class="card-num">.*?</span>', "", t.group(1), flags=re.S)
            title = strip_tags(inner)
        if h:
            hook = strip_tags(h.group(1))
            is_full = False
        else:
            # Numbered cards carry the hook as two paragraphs instead of one
            # (card-answer, then card-detail) - join them so an entry still
            # gets a real hook instead of silently going blank.
            a = re.search(r'class="card-answer"[^>]*>(.*?)</p>', body, re.S)
            d = re.search(r'class="card-detail"[^>]*>(.*?)</p>', body, re.S)
            hook = " ".join(strip_tags(m.group(1)) for m in (a, d) if m)
            is_full = bool(a or d)
        if rel not in out:
            # First occurrence sets this page's position (dict insertion
            # order), which the starter row's entry and the numbered grid's
            # entry always agree on: the starter row only links a track's
            # own card 01.
            out[rel] = (title, hook)
            fuller[rel] = is_full
        elif is_full and not fuller[rel]:
            # The starter row's short card-hook loses to the numbered grid's
            # fuller card-answer + card-detail once both have been seen -
            # updating the value in place does not move rel's position.
            out[rel] = (title, hook)
            fuller[rel] = is_full
    return out


def snippet_map():
    src = open(os.path.join(ROOT, "scripts", "check-panel-drift.py"), encoding="utf-8").read()
    def grab(name):
        m = re.search(name + r" = \{(.*?)\n\}", src, re.S)
        return dict(re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))) if m else {}
    return grab("SNIPPET_MAP"), grab("TEST_SNIPPET_MAP")


def collect():
    cards = index_cards()
    grid_order = list(cards.keys())
    snips, tests = snippet_map()
    pages = []
    missing_from_grid = []
    for track, label, blurb in TRACKS:
        ordered_rels = [rel for rel in grid_order if rel.startswith(track + "/")]
        # Filename order is only a fallback, for a page glob finds but the
        # grid doesn't list - it must never silently reassert itself as the
        # primary order (that was the whole bug: alphabetical, not reading
        # order). Anything already placed by the grid is dropped from here.
        on_disk = [track + "/" + os.path.basename(p)
                   for p in sorted(glob.glob(os.path.join(ROOT, track, "*.html")))]
        extra = [rel for rel in on_disk if rel not in ordered_rels]
        for rel in ordered_rels + extra:
            name = os.path.basename(rel)
            # The untracked scaffold, ignored by .gitignore at this exact path.
            # Matched by exact filename, not a "q7" prefix: that prefix also
            # matches real q7 pages, which would then be dropped silently.
            if name == "q7-test-demo.html":
                continue
            path = os.path.join(ROOT, rel)
            if not os.path.exists(path):
                continue
            src = open(path, encoding="utf-8").read()
            captions = flat_strings(js_array(src, "captions"))
            if not captions:
                # No captions means no walkthrough steps to narrate - a
                # redirect stub left behind at a moved page's old path,
                # not a real page for this index. Skip generally rather
                # than by filename, so any future stub is caught too.
                continue
            if rel in extra:
                missing_from_grid.append(rel)
            title, hook = cards.get(rel, (name, ""))
            cite_txt, cite_url, sha, cite_path = citation_of(src)
            pages.append({
                "track": track, "track_label": label, "track_blurb": blurb,
                "rel": rel, "title": title, "hook": hook,
                "kickers": flat_strings(js_array(src, "kickers")),
                "captions": captions,
                "steps": steps_of(src, rel), "diffs": diffs_of(src),
                "cite_txt": cite_txt, "cite_url": cite_url, "sha": sha,
                "lang": lang_for(cite_path, track),
                "snippet": snips.get(name), "test": tests.get(name),
            })
    if missing_from_grid:
        print("NOTE: pages absent from index.html's card grid, appended after "
              "the ordered ones instead of dropped: %s" % ", ".join(missing_from_grid),
              file=sys.stderr)
    return pages


# Spelled out because the preamble reads as prose. Derived from len(pages) so
# that adding a walkthrough cannot leave the count silently wrong, which is
# exactly what happened to "Fourteen".
_ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
         "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
         "sixteen", "seventeen", "eighteen", "nineteen"]
_TENS = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
         "eighty", "ninety"]


def count_word(n):
    if n < 20:
        w = _ONES[n]
    elif n < 100:
        w = _TENS[n // 10] + ("-" + _ONES[n % 10] if n % 10 else "")
    else:
        return str(n)
    return w[0].upper() + w[1:]


HEAD_TMPL = """# EEZ Quickstarts

> %s interactive walkthroughs of the Ethereum Economic Zone, each built on real
> protocol source cited at a pinned commit rather than on pseudocode. Covers writing
> contracts that call across rollups, running the stack, and how Rollup0 settles and proves.

Every code panel on this site is rendered from JavaScript at runtime, so fetching a page
gives you the shell and not the content. These files hand over the content directly: each
walkthrough's narration and code, the full compilable Solidity behind the Solidity ones,
and the runnable Foundry tests.

Two things worth knowing before you use any of it. EEZ is pre-mainnet, so treat
capability claims as design intent rather than shipped behaviour; the proof system in the
public source is dev-grade ECDSA, not production ZK. And every citation here is pinned to
a commit SHA, so a link tells you exactly which revision a claim was true of.
"""


def head_for(pages):
    return HEAD_TMPL % count_word(len(pages))


def build_index(pages):
    out = [head_for(pages)]
    for track, label, blurb in TRACKS:
        rows = [p for p in pages if p["track"] == track]
        if not rows:
            continue
        out.append("## %s\n\n%s\n" % (label, blurb))
        for p in rows:
            out.append("- [%s](%s/%s): %s" % (p["title"], BASE, p["rel"], p["hook"]))
        out.append("")

    out.append("## Compilable source\n")
    out.append("Real files, not fragments: pragma, imports and a contract wrapper, all "
               "building under solc 0.8.28. Each mirrors the upstream function its "
               "walkthrough cites.\n")
    for p in pages:
        if p["snippet"]:
            out.append("- [snippets/%s](%s/snippets/%s): full source behind %s"
                       % (p["snippet"], BASE, p["snippet"], p["title"]))
    out.append("")

    out.append("## Runnable tests\n")
    out.append("Foundry tests with no forge-std and no submodules, so they drop into an "
               "existing suite. `cd snippets && forge test`.\n")
    for p in pages:
        if p["test"]:
            out.append("- [snippets/%s](%s/snippets/%s): proves the behaviour in %s"
                       % (p["test"], BASE, p["test"], p["title"]))
    out.append("")

    out.append("## Everything inlined\n")
    out.append("- [llms-full.txt](%s/llms-full.txt): every walkthrough's narration, code, "
               "citations, snippets and tests in one document\n" % BASE)

    out.append("## Optional\n")
    out.append("- [Repository](https://github.com/0xarmagan/eez-demos): source of this site")
    out.append("- [eez-core-protocol](https://github.com/eez-association/eez-core-protocol): "
               "the contracts every Solidity walkthrough cites")
    out.append("- [eez-rollup0](https://github.com/eez-association/eez-rollup0): "
               "the node, composer, deriver and proof-signer")
    out.append("- [CONTRIBUTING](https://github.com/0xarmagan/eez-demos/blob/main/CONTRIBUTING.md): "
               "how a walkthrough gets added and audited")
    return "\n".join(out).rstrip() + "\n"


def build_full(pages):
    out = [head_for(pages).replace(
        "These files hand over the content directly: each",
        "This file is the whole thing in one document: each")]
    for track, label, blurb in TRACKS:
        rows = [p for p in pages if p["track"] == track]
        if not rows:
            continue
        out.append("---\n\n# %s\n\n%s\n" % (label, blurb))
        for p in rows:
            out.append("## %s\n" % p["title"])
            if p["hook"]:
                out.append("%s\n" % p["hook"])
            out.append("- Page: %s/%s" % (BASE, p["rel"]))
            if p["cite_txt"]:
                out.append("- Source: `%s`" % p["cite_txt"])
            if p["sha"]:
                out.append("- Pinned at commit: `%s`" % p["sha"])
            if p["cite_url"]:
                out.append("- Verify: %s" % p["cite_url"])
            out.append("")
            for i, lines in enumerate(p["steps"]):
                kick = p["kickers"][i] if i < len(p["kickers"]) else "Step %d" % (i + 1)
                cap = p["captions"][i] if i < len(p["captions"]) else ""
                out.append("### Step %d — %s\n" % (i + 1, kick))
                if cap:
                    out.append("%s\n" % cap)
                dm = p["diffs"][i] if i < len(p["diffs"]) else {}
                if dm:
                    # The page marks these lines - and + in the gutter. Flatten
                    # them into a plain block and the removed line reads as if it
                    # belonged, which is worse than losing formatting: an agent
                    # would copy both halves of a before/after pair.
                    marked = []
                    for n, ln in enumerate(lines):
                        pre = {"del": "-", "add": "+"}.get(dm.get(n), " ")
                        marked.append((pre + ln).rstrip() if ln.strip() else pre.rstrip())
                    body = "\n".join(marked).rstrip()
                    if body.strip():
                        out.append("```diff\n%s\n```\n" % body)
                else:
                    body = "\n".join(lines).rstrip()
                    if body.strip():
                        out.append("```%s\n%s\n```\n" % (p["lang"], body))
            if p["snippet"]:
                sp = os.path.join(ROOT, "snippets", p["snippet"])
                if os.path.exists(sp):
                    out.append("### Full compilable source — snippets/%s\n" % p["snippet"])
                    out.append("```solidity\n%s\n```\n"
                               % open(sp, encoding="utf-8").read().rstrip())
            if p["test"]:
                tp = os.path.join(ROOT, "snippets", p["test"])
                if os.path.exists(tp):
                    out.append("### Runnable test — snippets/%s\n" % p["test"])
                    out.append("```solidity\n%s\n```\n"
                               % open(tp, encoding="utf-8").read().rstrip())
    return "\n".join(out).rstrip() + "\n"


def main():
    check = "--check" in sys.argv
    pages = collect()
    if len(pages) != 15:
        print("FAIL: expected 15 walkthroughs, collected %d" % len(pages))
        return 1

    targets = {"llms.txt": build_index(pages), "llms-full.txt": build_full(pages)}
    stale = []
    for name, content in targets.items():
        path = os.path.join(ROOT, name)
        old = open(path, encoding="utf-8").read() if os.path.exists(path) else None
        if old == content:
            continue
        stale.append(name)
        if not check:
            open(path, "w", encoding="utf-8").write(content)

    if check:
        if stale:
            print("STALE: %s — run python3 scripts/build-llms.py" % ", ".join(stale))
            return 1
        print("llms.txt and llms-full.txt are current (%d walkthroughs)." % len(pages))
        return 0

    for name in targets:
        size = len(targets[name].encode("utf-8"))
        mark = "updated" if name in stale else "unchanged"
        print("  %-14s %7d bytes  %s" % (name, size, mark))
    print("\n%d walkthroughs, %d snippets, %d tests"
          % (len(pages), sum(1 for p in pages if p["snippet"]),
             sum(1 for p in pages if p["test"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
