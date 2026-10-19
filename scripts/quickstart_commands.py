#!/usr/bin/env python3
"""Preview page commands; execute only supported argv forms with --execute.

Execution still trusts the pinned upstream repository and installed tools.
Use a disposable environment without credentials for --execute.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import time

SCRIPTS = Path(__file__).resolve().parent
REPO = "https://github.com/eez-association/eez-core-protocol.git"
SCENARIOS = {"counter", "counterL2", "flash-loan", "bridge", "bridgeL2"}


def extract(root, page):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*\.html", page):
        raise ValueError("page must be an HTML filename, without directories")
    directory = (root / "dapp-developers").resolve()
    path = (directory / page).resolve()
    if path.parent != directory:
        raise ValueError("page resolves outside dapp-developers")
    spec = importlib.util.spec_from_file_location("build_llms", SCRIPTS / "build-llms.py")
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    return [line[2:] for step in builder.steps_of(path.read_text(encoding="utf-8"), page)
            for line in step if line.startswith("$ ")]


def validate(commands, pin):
    """Validate the whole batch before executing anything. Shell syntax is data."""
    parsed = [shlex.split(command) for command in commands]
    cloned = entered = pinned = False
    for args in parsed:
        if not args:
            raise ValueError("empty command")
        if args[0] in {"echo", "true"} or args == ["false"]:
            continue  # Implemented below, without a shell or external process.
        if args == ["git", "clone", REPO] and not cloned:
            cloned = True
        elif args == ["cd", "eez-core-protocol"] and cloned and not entered:
            entered = True
        elif args in (["git", "checkout", "-q", pin], ["git", "checkout", pin]) and entered:
            pinned = True
        elif pinned and args in (
            ["git", "submodule", "update", "--init", "--recursive"],
            ["forge", "build"],
            ["forge", "test", "--match-test", "test_BridgeTokens_Roundtrip"],
        ):
            pass
        elif (pinned and len(args) >= 3
              and args[:2] == ["bash", "script/e2e/run/local/parallel.sh"]
              and all(item in SCENARIOS for item in args[2:])):
            pass
        else:
            raise ValueError("unsupported command or unsafe ordering: " + shlex.join(args))
    return parsed


def execute(page, commands, parsed):
    started = time.monotonic()
    output = []
    with tempfile.TemporaryDirectory(prefix="eez-quickstart-") as directory:
        work = Path(directory)
        cwd = work
        for original, args in zip(commands, parsed):
            print("RAN: " + original, flush=True)
            if args[0] == "cd":
                cwd = (work / "eez-core-protocol").resolve()
                if cwd.parent != work.resolve() or not cwd.is_dir():
                    raise ValueError("checkout escaped its temporary directory")
                continue
            if args[0] == "echo":
                text, code = " ".join(args[1:]) + "\n", 0
            elif args[0] in {"true", "false"}:
                text, code = "", int(args[0] == "false")
            else:
                # Do not populate the mutable default branch before checkout
                # of the reviewed commit.
                command_args = (["git", "clone", "--no-checkout", REPO]
                                if args[:2] == ["git", "clone"] else args)
                argv = (["git", "-c", "core.hooksPath=/dev/null",
                         "-c", "protocol.file.allow=never"] + command_args[1:]
                        if args[0] == "git" else command_args)
                result = subprocess.run(argv, cwd=cwd, stdin=subprocess.DEVNULL,
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                        text=True)
                text, code = result.stdout, result.returncode
            print(text, end="", flush=True)
            output.append(text)
            if code:
                raise ValueError(f"{page}: command failed with exit {code}")
        log = "".join(output)
        results = re.findall(r"RESULT:\s*(\d+) passed,\s*(\d+) failed,\s*(\d+) skipped", log)
        if any(int(p) == 0 or int(f) != 0 or int(s) != 0 for p, f, s in results):
            bad = next(line for line in log.splitlines() if "RESULT:" in line)
            raise ValueError(f"{page}: scenario run passed nothing / failed / skipped: {bad}")
        if any("parallel.sh" in command for command in commands) and not results:
            raise ValueError(f"{page}: parallel.sh printed no RESULT line")
    print(f"ELAPSED {page} {int(time.monotonic() - started)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--extract-only", action="store_true", help="preview only (the default)")
    modes.add_argument("--execute", action="store_true", help="run reviewed commands; use isolation")
    parser.add_argument("pages", nargs="+")
    args = parser.parse_args()
    root = Path(os.environ.get("QS_ROOT", SCRIPTS.parent)).resolve()
    pins = root / "scripts" / "citation-pins.json"
    if not pins.is_file():
        pins = SCRIPTS / "citation-pins.json"
    pin = json.loads(pins.read_text())["repos"]["eez-core-protocol"]["sha"]
    if not re.fullmatch(r"[0-9a-f]{40}", pin):
        raise ValueError(f"invalid eez-core-protocol pin in {pins}")
    batches = []
    for page in args.pages:
        commands = extract(root, page)
        if not commands:
            raise ValueError(f"{page}: no commands found")
        if any(any(ord(char) < 32 or ord(char) == 127 for char in command)
               for command in commands):
            raise ValueError(f"{page}: command contains terminal control characters")
        parsed = [shlex.split(command) for command in commands]
        if any(a[:2] == ["git", "clone"] and any("eez-core-protocol" in s for s in a[2:])
               for a in parsed):
            if not any(a in (["git", "checkout", "-q", pin], ["git", "checkout", pin])
                       for a in parsed):
                raise ValueError(f"{page}: clones eez-core-protocol without checking out the pin {pin}")
        batches.append((page, commands, validate(commands, pin) if args.execute else parsed))
    if args.execute:
        print("Executing reviewed commands and pinned upstream code; this is not a sandbox.",
              file=sys.stderr)
    for page, commands, parsed in batches:
        if args.execute:
            execute(page, commands, parsed)
        else:
            print("\n".join(commands))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, KeyError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
