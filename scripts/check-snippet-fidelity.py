#!/usr/bin/env python3
"""Assert every snippet declaration that upstream also declares still matches upstream.

Three checks guard the Solidity on this site, and until now only two existed:

  check-panel-drift.py   panel line  ->  snippet     (the panel is real Solidity)
  verify-citations.py    citation    ->  upstream    (the cited line still exists)
  this script            snippet     ->  upstream    (the code we teach is the code upstream runs)

The missing third is how `STATIC_CHECK_GAS = 5000` shipped against an upstream
`1_000`. The panel only ever shows `gas: STATIC_CHECK_GAS`, so the value appears
in neither surface the other two checks compare. The citation was correct the
whole time. A reader who copied the snippet got a five-times-too-large gas cap
and no check in the repo could see it.

What it compares, whitespace-normalised: named constants, error declarations,
struct field order, and function signatures. The rule is narrow on purpose -
anything the snippet declares that upstream ALSO declares must match. A snippet
is a teaching artifact, so it invents helpers (a Caller, an IRemote, a Dummy);
those have no upstream counterpart and are reported as skipped, by name, with a
reason. Nothing is skipped silently.

A declaration that DOES exist upstream but deliberately differs - a stubbed
`_getRollupId`, a simplified mapping - is drift until it is marked. Put

    /// @stand-in why it differs from upstream

in the comment block directly above the declaration (or above the whole
contract, which covers every member). The marker is explicit so that a
divergence is always either justified in the file or reported here.

Mirrors are discovered per file, never hardcoded: each snippet's header names
what it mirrors, e.g.

    // Mirrors eez-core-protocol/src/base/CrossChainProxy.sol:39 and :89

so a snippet added tomorrow is covered the day it lands. Solidity `import`s of
the mirrored files are followed one level, because upstream declares
`ProxyInfo` and `UnauthorizedProxy` in the interface `EEZBase.sol` imports
rather than in `EEZBase.sol` itself.

Upstream is fetched over raw.githubusercontent at the SHA in
scripts/citation-pins.json, through the same .citation-cache/ that
verify-citations.py uses. No clone required.

Usage:
  python3 scripts/check-snippet-fidelity.py
  python3 scripts/check-snippet-fidelity.py --offline   # use only the local cache
  python3 scripts/check-snippet-fidelity.py --quiet     # totals and drift only

Exits non-zero on any drift, on a top-level snippet with no Mirrors header, or
on an upstream file it could not fetch.
"""

import argparse
import glob
import json
import os
import re
import sys
import urllib.error
import urllib.request

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PINS_PATH = os.path.join(REPO_ROOT, "scripts", "citation-pins.json")
CACHE_DIR = os.path.join(REPO_ROOT, ".citation-cache")
SNIPPET_DIR = os.path.join(REPO_ROOT, "snippets")
ORG = "eez-association"

# Files that must declare what they mirror. snippets/lib and snippets/test are
# support code: covered when they name an upstream file, reported when they don't.
REQUIRE_MIRRORS_GLOB = "snippets/*.sol"
SNIPPET_GLOBS = ["snippets/*.sol", "snippets/lib/*.sol", "snippets/test/*.sol"]

# "// Mirrors eez-core-protocol/src/base/EEZBase.sol:156, :166 and :176" is the
# canonical form. The looser pattern catches any upstream path named in a
# snippet's leading comment block, which is how snippets/lib/*.sol declare
# theirs ("Every signature below is copied verbatim from upstream: <path>").
UPSTREAM_REF_RE = re.compile(r"\b(?P<repo>eez-[a-z0-9\-]+)/(?P<path>[\w./\-]+\.(?:sol|rs|proto))")

# Solidity type aliases, so `uint` and `uint256` are not reported as drift.
TYPE_ALIASES = {"uint": "uint256", "int": "int256", "byte": "bytes1"}
DATA_LOCATIONS = {"memory", "calldata", "storage", "payable", "indexed"}
VISIBILITIES = {"public", "external", "internal", "private"}
MUTABILITIES = {"pure", "view", "payable"}
# Inheritance plumbing, not part of the signature a reader copies.
DROPPED_TAIL_TOKENS = {"virtual"}

STAND_IN_RE = re.compile(r"@stand-in\b[:\s]*(?P<why>.*)")


# ──────────────────────────────────────────────
#  Upstream fetching (same cache and conventions as verify-citations.py)
# ──────────────────────────────────────────────

def load_pins():
    with open(PINS_PATH) as fh:
        return json.load(fh)["repos"]


def fetch(repo, sha, path, offline):
    """Return the file's text at that SHA, using the shared local cache."""
    key = f"{repo}@{sha}@{path}".replace("/", "__")
    cached = os.path.join(CACHE_DIR, key)
    if os.path.exists(cached):
        with open(cached, encoding="utf-8", errors="replace") as fh:
            return fh.read()
    if offline:
        raise RuntimeError(f"not cached and --offline given: {repo}/{path}")
    url = f"https://raw.githubusercontent.com/{ORG}/{repo}/{sha}/{path}"
    req = urllib.request.Request(url, headers={"User-Agent": "eez-demos-snippet-fidelity"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = resp.read().decode("utf-8", errors="replace")
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(cached, "w", encoding="utf-8") as fh:
        fh.write(body)
    return body


# ──────────────────────────────────────────────
#  Solidity parsing
# ──────────────────────────────────────────────

def blank_comments(src, blank_strings=False):
    """Same-length copy of src with comment bodies (optionally string bodies) blanked.

    Same length and same newlines, so every offset still maps to its real line.
    """
    out = list(src)
    i, n, state = 0, len(src), None
    while i < n:
        c = src[i]
        if state is None:
            if c == "/" and i + 1 < n and src[i + 1] == "/":
                out[i] = out[i + 1] = " "
                state, i = "line", i + 2
                continue
            if c == "/" and i + 1 < n and src[i + 1] == "*":
                out[i] = out[i + 1] = " "
                state, i = "block", i + 2
                continue
            if c in "\"'":
                state = "str" if c == '"' else "char"
            i += 1
            continue
        if state == "line":
            if c == "\n":
                state = None
            else:
                out[i] = " "
            i += 1
            continue
        if state == "block":
            if c == "*" and i + 1 < n and src[i + 1] == "/":
                out[i] = out[i + 1] = " "
                state, i = None, i + 2
                continue
            if c != "\n":
                out[i] = " "
            i += 1
            continue
        # inside a string literal
        quote = '"' if state == "str" else "'"
        if c == "\\":
            i += 2
            continue
        if c == quote:
            state = None
        elif blank_strings and c != "\n":
            out[i] = "x"
        i += 1
    return "".join(out)


def line_of(text, pos):
    return text.count("\n", 0, pos) + 1


def balanced(text, open_pos, opener="(", closer=")"):
    """text[open_pos] is the opener; return (inner, index_after_closer)."""
    depth, i, n = 0, open_pos, len(text)
    while i < n:
        if text[i] == opener:
            depth += 1
        elif text[i] == closer:
            depth -= 1
            if depth == 0:
                return text[open_pos + 1:i], i + 1
        i += 1
    return text[open_pos + 1:], n


def split_top_level(s, sep=","):
    parts, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == sep and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur)
    return [p.strip() for p in parts if p.strip()]


def norm_type(t):
    t = re.sub(r"\s+", " ", t).strip()
    return " ".join(TYPE_ALIASES.get(tok, tok) for tok in t.split())


def parse_params(s):
    """'address a, bytes calldata data' -> [('address', 'a'), ('bytes calldata', 'data')]"""
    out = []
    for part in split_top_level(s):
        toks = re.sub(r"\s+", " ", part).replace("[]", " []").split()
        if not toks:
            continue
        name = None
        if len(toks) > 1 and toks[-1] not in DATA_LOCATIONS and re.fullmatch(r"[A-Za-z_]\w*", toks[-1]):
            name = toks.pop()
        out.append((norm_type(" ".join(toks).replace(" []", "[]")), name))
    return out


def render_params(params):
    return ", ".join(t + (" " + n if n else "") for t, n in params)


def containers(code):
    """[(kind, name, start, end)] for every contract/interface/library body."""
    found = []
    for m in re.finditer(r"\b(?:abstract\s+)?(contract|interface|library)\s+(\w+)", code):
        brace = code.find("{", m.end())
        if brace == -1:
            continue
        _, after = balanced(code, brace, "{", "}")
        found.append((m.group(1), m.group(2), m.start(), after))
    return found


def container_at(conts, pos):
    inner = None
    for kind, name, start, end in conts:
        if start < pos < end and (inner is None or start > inner[2]):
            inner = (kind, name, start, end)
    return inner


def stand_in_reason(lines, decl_line):
    """@stand-in on the declaration's line, or in the comment block directly above it."""
    idx = decl_line - 1
    if 0 <= idx < len(lines):
        m = STAND_IN_RE.search(lines[idx])
        if m:
            return m.group("why").strip() or "marked on the declaration"
    i = idx - 1
    while i >= 0:
        stripped = lines[i].strip()
        if not stripped.startswith(("//", "*", "/*")):
            break
        m = STAND_IN_RE.search(stripped)
        if m:
            return m.group("why").strip() or "marked above the declaration"
        i -= 1
    return None


class Decl:
    """One comparable declaration: what it looks like, and what it means.

    `sig` is for humans. `parts` is what is actually compared, so that a
    difference which carries no meaning - an unnamed return where upstream
    names it, `1_000` vs `1000` - is not reported as drift, while every
    difference that a reader could copy and be wrong about is.
    """

    def __init__(self, kind, name, sig, parts, line, container=None, extra=""):
        self.kind, self.name, self.sig, self.line = kind, name, sig, line
        self.parts = parts                  # what is compared
        self.container = container          # (kind, name) or None
        self.extra = extra                  # reported, never compared
        self.stand_in = None

    def key(self):
        return (self.kind, self.name)

    def display(self):
        if self.kind == "constant":
            return f"constant {self.parts['type']} {self.name} = {self.sig}"
        if self.kind == "struct":
            return f"struct {self.name} {self.sig}"
        return f"{self.kind} {self.name}{self.sig}"

    def __repr__(self):
        return f"{self.kind} {self.name}"


def params_match(a, b):
    """Types always. Names only where both sides give one - upstream names a
    return value that an interface leaves unnamed, and that is not drift."""
    if (a is None) != (b is None):
        return False
    if a is None:
        return True
    if len(a) != len(b):
        return False
    for (ta, na), (tb, nb) in zip(a, b):
        if ta != tb:
            return False
        if na and nb and na != nb:
            return False
    return True


def parse_decls(src):
    """Every constant / error / struct / function declaration in one Solidity file."""
    code = blank_comments(src, blank_strings=True)
    lines = src.splitlines()
    conts = containers(code)
    decls, skipped = [], []

    def container_of(pos):
        c = container_at(conts, pos)
        return (c[0], c[1]) if c else None

    # named constants
    for m in re.finditer(
        r"\b(?P<type>[A-Za-z_]\w*(?:\s*\[\s*\])?)\s+"
        r"(?:(?P<vis>public|internal|private)\s+)?constant\s+"
        r"(?P<name>\w+)\s*=\s*(?P<value>[^;]+);", code):
        line = line_of(code, m.start())
        raw_value = re.sub(r"\s+", " ", src[m.start("value"):m.end("value")]).strip()
        ctype = norm_type(m.group("type"))
        decls.append(Decl(
            "constant", m.group("name"), raw_value,
            {"type": ctype, "value": canonical_value(raw_value)},
            line, container_of(m.start()),
            extra=f"visibility {m.group('vis') or 'default'}"))

    # error declarations
    for m in re.finditer(r"\berror\s+(?P<name>\w+)\s*\(", code):
        inner, _ = balanced(code, m.end() - 1)
        params = parse_params(inner)
        decls.append(Decl("error", m.group("name"), f"({render_params(params)})",
                          {"params": params},
                          line_of(code, m.start()), container_of(m.start())))

    # structs - field order is the point
    for m in re.finditer(r"\bstruct\s+(?P<name>\w+)\s*\{", code):
        inner, _ = balanced(code, m.end() - 1, "{", "}")
        fields = [f for part in split_top_level(inner, ";") for f in parse_params(part)]
        decls.append(Decl("struct", m.group("name"),
                          "{ " + "; ".join(render_params([f]) for f in fields) + " }",
                          {"fields": fields},
                          line_of(code, m.start()), container_of(m.start())))

    # function signatures (plus fallback/receive; constructors are per-contract, not upstream-comparable)
    for m in re.finditer(r"\bfunction\s+(?P<name>\w+)\s*\(|\b(?P<kw>fallback|receive|constructor)\s*\(", code):
        name = m.group("name") or m.group("kw")
        line = line_of(code, m.start())
        params_str, after = balanced(code, m.end() - 1)
        tail = ""
        depth, i = 0, after
        while i < len(code):
            ch = code[i]
            if ch in "([":
                depth += 1
            elif ch in ")]":
                depth -= 1
            elif depth == 0 and ch in "{;":
                break
            tail += ch
            i += 1
        if name == "constructor":
            skipped.append((f"constructor in {container_of(m.start())[1] if container_of(m.start()) else '?'}",
                            line, "constructors are per-contract, never a shared upstream declaration"))
            continue
        sig, parts = normalize_signature(params_str, tail)
        decls.append(Decl("function", name, sig, parts, line, container_of(m.start())))

    for d in decls:
        d.stand_in = stand_in_reason(lines, d.line)
        if d.stand_in is None and d.container:
            for kind, cname, start, _end in conts:
                if (kind, cname) == d.container:
                    why = stand_in_reason(lines, line_of(code, start))
                    if why:
                        d.stand_in = f"{why} (whole {kind} {cname})"
                    break
    return decls, skipped


def normalize_signature(params_str, tail):
    """'(a, b) public view returns (c)' -> (display string, comparable parts)."""
    tail = re.sub(r"\boverride\s*(\([^)]*\))?", " ", tail)
    returns, ret_display = None, ""
    m = re.search(r"\breturns\s*\(", tail)
    if m:
        inner, _ = balanced(tail, m.end() - 1)
        returns = parse_params(inner)
        ret_display = f" returns ({render_params(returns)})"
        tail = tail[:m.start()]
    toks = [t for t in re.sub(r"\s+", " ", tail).split() if t and t not in DROPPED_TAIL_TOKENS]
    vis = [t for t in toks if t in VISIBILITIES]
    mut = [t for t in toks if t in MUTABILITIES]
    mods = sorted(t for t in toks if t not in VISIBILITIES and t not in MUTABILITIES)
    params = parse_params(params_str)
    display = " ".join([f"({render_params(params)})"] + vis + mut + mods) + ret_display
    parts = {
        "params": params,
        "vis": vis[0] if vis else None,
        "mut": mut[0] if mut else None,
        "mods": mods,
        "returns": returns,
    }
    return display, parts


def canonical_value(sig):
    """Digit separators are formatting: 1_000 and 1000 are the same constant."""
    return re.sub(r"(?<=\d)_(?=\d)", "", sig)


def declarations_match(snippet_decl, upstream_decl):
    """(matched, note). The note records a difference accepted on purpose."""
    a, b = snippet_decl.parts, upstream_decl.parts
    kind = snippet_decl.kind
    if kind == "constant":
        return (a["value"] == b["value"] and a["type"] == b["type"]), ""
    if kind == "error":
        return params_match(a["params"], b["params"]), ""
    if kind == "struct":
        # Field ORDER, not just membership: reordering two fields changes every
        # hash and every destructuring assignment that copies this.
        return params_match(a["fields"], b["fields"]), ""
    if not params_match(a["params"], b["params"]):
        return False, ""
    if not params_match(a["returns"], b["returns"]):
        return False, ""
    if a["mut"] != b["mut"] or a["mods"] != b["mods"]:
        return False, ""
    if a["vis"] == b["vis"]:
        return True, ""
    # Inside an interface `external` is what the language requires, while
    # upstream's own implementation of the same function is `public`.
    in_interface = snippet_decl.container and snippet_decl.container[0] == "interface"
    if in_interface and a["vis"] == "external" and b["vis"] == "public":
        return True, "visibility relaxed: `external` in an interface vs upstream `public`"
    return False, ""


# ──────────────────────────────────────────────
#  Mirror discovery
# ──────────────────────────────────────────────

def header_block(src):
    """The leading comment/pragma/import preamble - where a snippet declares its mirrors."""
    keep = []
    for line in src.splitlines():
        s = line.strip()
        if not s or s.startswith(("//", "/*", "*", "pragma", "import")) or s.startswith("*/"):
            keep.append(line)
            continue
        break
    return "\n".join(keep)


def mirrors_of(src):
    """[(repo, path, how)] named by this file's own header. Never a hardcoded map."""
    head = header_block(src)
    canonical = set()
    for line in head.splitlines():
        if re.search(r"//\s*Mirrors\b", line):
            for m in UPSTREAM_REF_RE.finditer(line):
                canonical.add((m.group("repo"), m.group("path")))
    out, seen = [], set()
    for repo, path in sorted(canonical):
        out.append((repo, path, "Mirrors header"))
        seen.add((repo, path))
    for m in UPSTREAM_REF_RE.finditer(head):
        pair = (m.group("repo"), m.group("path"))
        if pair not in seen:
            seen.add(pair)
            out.append((pair[0], pair[1], "named in header comment"))
    return out


def imports_of(src, path):
    """Same-repo imports of an upstream file, resolved one level deep."""
    code = blank_comments(src)
    base = os.path.dirname(path)
    resolved, skipped = [], []
    for m in re.finditer(r"\bimport\b[^;]*?[\"'](?P<p>[^\"']+)[\"']\s*;", code, re.S):
        target = m.group("p")
        if target.startswith((".", "/")):
            resolved.append(os.path.normpath(os.path.join(base, target)))
        elif target.startswith("src/"):
            resolved.append(os.path.normpath(target))
        else:
            skipped.append(target)
    return resolved, skipped


# ──────────────────────────────────────────────
#  Main
# ──────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--offline", action="store_true", help="use only the local cache")
    ap.add_argument("--quiet", action="store_true", help="totals and drift only")
    args = ap.parse_args()

    pins = load_pins()
    required = {os.path.relpath(p, REPO_ROOT)
                for p in glob.glob(os.path.join(REPO_ROOT, REQUIRE_MIRRORS_GLOB))}

    paths = []
    for pattern in SNIPPET_GLOBS:
        paths += sorted(glob.glob(os.path.join(REPO_ROOT, pattern)))

    print("snippet -> upstream fidelity, at the SHAs in scripts/citation-pins.json")
    for repo, meta in sorted(pins.items()):
        print(f"  {repo} @ {meta['sha'][:12]}  (pinned {meta['pinned_on']})")

    drift, errors, uncovered = [], [], []
    totals = {"constant": 0, "error": 0, "struct": 0, "function": 0}
    skipped_total = 0
    upstream_cache = {}

    for path in paths:
        rel = os.path.relpath(path, REPO_ROOT)
        with open(path, encoding="utf-8") as fh:
            src = fh.read()
        mirrors = mirrors_of(src)
        if not mirrors:
            uncovered.append(rel)
            if rel in required:
                errors.append(f"{rel}: no `// Mirrors <repo>/<path>` header - "
                              "every snippet must declare what it mirrors")
            continue

        if not args.quiet:
            print(f"\n{rel}")

        # Fetch the mirrored files, then their same-repo imports one level down.
        upstream_files, import_notes = [], []
        for repo, upath, how in mirrors:
            sha = pins.get(repo, {}).get("sha")
            if not sha:
                errors.append(f"{rel}: no pinned SHA for repo '{repo}' ({upath})")
                continue
            try:
                text = upstream_cache.setdefault(
                    (repo, sha, upath), fetch(repo, sha, upath, args.offline))
            except urllib.error.HTTPError as e:
                errors.append(f"{rel}: {repo}/{upath} -> HTTP {e.code} at {sha[:12]}")
                continue
            except Exception as e:  # noqa: BLE001 - report and keep going
                errors.append(f"{rel}: {repo}/{upath} -> {e}")
                continue
            upstream_files.append((repo, upath, text, how))
            imports, unresolved = imports_of(text, upath)
            for note in unresolved:
                import_notes.append(f"not followed (out of repo): {note}")
            for ipath in imports:
                if any(u[1] == ipath for u in upstream_files):
                    continue
                try:
                    itext = upstream_cache.setdefault(
                        (repo, sha, ipath), fetch(repo, sha, ipath, args.offline))
                except Exception as e:  # noqa: BLE001 - an import we cannot read is a note, not a failure
                    import_notes.append(f"could not fetch import {ipath}: {e}")
                    continue
                upstream_files.append((repo, ipath, itext, f"imported by {os.path.basename(upath)}"))

        if not upstream_files:
            continue

        # Index every upstream declaration by (kind, name).
        upstream_index = {}
        for repo, upath, text, _how in upstream_files:
            udecls, _ = parse_decls(text)
            for d in udecls:
                upstream_index.setdefault(d.key(), []).append((repo, upath, d))

        if not args.quiet:
            for repo, upath, _t, how in upstream_files:
                print(f"  upstream: {repo}/{upath}   [{how}]")
            for note in import_notes:
                print(f"  note: {note}")

        decls, structural_skips = parse_decls(src)
        counts = {"constant": 0, "error": 0, "struct": 0, "function": 0}
        lines_ok, lines_skip = [], []
        for note, line, why in structural_skips:
            lines_skip.append(f"    skip  {rel}:{line}  {note}  ({why})")
            skipped_total += 1

        for d in decls:
            where = f"{rel}:{d.line}"
            label = f"{d.kind} {d.name}"
            if d.stand_in:
                lines_skip.append(f"    skip  {where}  {label}  (@stand-in: {d.stand_in})")
                skipped_total += 1
                continue
            candidates = upstream_index.get(d.key(), [])
            if not candidates:
                lines_skip.append(
                    f"    skip  {where}  {label}  (declared by the snippet only - "
                    "no such declaration in the mirrored upstream file(s))")
                skipped_total += 1
                continue
            hit = None
            for _repo, upath, ud in candidates:
                ok, note = declarations_match(d, ud)
                if ok:
                    hit = (upath, ud, note)
                    break
            counts[d.kind] += 1
            totals[d.kind] += 1
            if hit:
                upath, ud, note = hit
                notes = [note] if note else []
                if d.kind == "constant" and d.extra != ud.extra:
                    notes.append(f"snippet {d.extra}, upstream {ud.extra}")
                detail = ("  [" + "; ".join(notes) + "]") if notes else ""
                lines_ok.append(
                    f"    ok    {where}  {d.display()}"
                    f"\n            == {upath}:{ud.line}{detail}")
            else:
                _repo, upath, ud = candidates[0]
                got, want = d.sig, ud.sig
                if d.kind == "constant" and d.parts["type"] != ud.parts["type"]:
                    got = f"{d.parts['type']} {got}"
                    want = f"{ud.parts['type']} {want}"
                drift.append(
                    f"DRIFT  {where}  {d.name} = {got}   upstream: {want}"
                    f"   ({upath}:{ud.line})")

        if not args.quiet:
            print(f"  compared {counts['constant']} constants, {counts['error']} errors, "
                  f"{counts['struct']} structs, {counts['function']} signatures")
            for ln in lines_ok:
                print(ln)
            for ln in lines_skip:
                print(ln)

    print("\n" + "=" * 78)
    if uncovered:
        print(f"\nno upstream reference in the header, so not compared ({len(uncovered)}):")
        for rel in uncovered:
            print(f"  - {rel}")
    print(f"\ncompared in total: {totals['constant']} constants, {totals['error']} errors, "
          f"{totals['struct']} structs, {totals['function']} function signatures"
          f"   ({skipped_total} declarations skipped, each named above)")

    if errors:
        print(f"\nERRORS ({len(errors)}):")
        for e in errors:
            print(f"  - {e}")
    if drift:
        print(f"\n{len(drift)} declaration(s) drifted from upstream:\n")
        for d in drift:
            print(d)
        print("\nEach is either a real drift to fix, or a deliberate stand-in that needs a")
        print("`/// @stand-in why` comment directly above it.")
    if errors or drift:
        return 1
    print("\nEvery snippet declaration that upstream also declares matches upstream.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
