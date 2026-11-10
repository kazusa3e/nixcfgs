#!/usr/bin/env python3
"""Inspect package update history and manage fixed nixpkgs inputs."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys


PACKAGE_NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_-]*")
REVISION = re.compile(r"[0-9a-fA-F]{40}")


def edit_pin(contents, package, revision):
    if not PACKAGE_NAME.fullmatch(package):
        raise ValueError("Package must be a top-level Nix attribute name")
    if revision is not None and not REVISION.fullmatch(revision):
        raise ValueError("Revision must be a full 40-character nixpkgs commit hash")

    opening = re.search(r"(?m)^  inputs = \{\n", contents)
    closing = (
        re.search(r"(?m)^  \};[ \t]*(?:\n|$)", contents[opening.end() :])
        if opening
        else None
    )
    if closing is None:
        raise ValueError("Expected the standard two-space-indented inputs block")
    end = opening.end() + closing.start()
    block = contents[opening.end() : end]
    name = re.escape("nixpkgs-pin-" + package)
    declarations = list(
        re.finditer(rf'(?m)^[ \t]*(?:{name}|"{name}")\s*(?:\.|=)', block)
    )
    line = re.compile(
        rf'(?m)^([ \t]*){name}\.url[ \t]*=[ \t]*"[^"\n]*";'
        r"([ \t]*(?:#[^\n]*)?)(\n|$)"
    )
    matches = list(line.finditer(block))
    if declarations and (len(declarations) != 1 or len(matches) != 1):
        raise ValueError("Refusing to edit a nonstandard or duplicate pin declaration")
    if revision is None:
        if not matches:
            raise ValueError(f"Package is not pinned: {package}")
        block = line.sub("", block, count=1)
    else:
        declaration = f'nixpkgs-pin-{package}.url = "github:NixOS/nixpkgs/{revision}";'
        if matches:
            block = line.sub(lambda m: m[1] + declaration + m[2] + m[3], block, count=1)
        else:
            block += "    " + declaration + "\n"
    return contents[: opening.end()] + block + contents[end:]


def read_lock(commit):
    result = subprocess.run(
        ["git", "show", "--end-of-options", f"{commit}:flake.lock"],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return json.loads(result.stdout)


def input_revisions(lock):
    nodes = lock["nodes"]
    return {
        name: nodes[node].get("locked", {}).get("rev")
        for name, node in nodes[lock["root"]]["inputs"].items()
        if isinstance(node, str)
    }


def revision_from_commit(commit, input_name):
    revision = input_revisions(read_lock(commit)).get(input_name)
    if revision is None:
        raise ValueError(
            f"No directly locked Git revision for input {input_name!r} at {commit}"
        )
    return revision


def history(package):
    if not PACKAGE_NAME.fullmatch(package):
        raise ValueError("Package must be a top-level Nix attribute name")
    result = subprocess.run(
        ["git", "log", "--format=%H%x00%B%x00", "--", "flake.lock"],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    entries = result.stdout.split("\0")
    found = False
    for index in range(0, len(entries) - 1, 2):
        commit, message = entries[index].strip(), entries[index + 1]
        report = message.partition("Direct packages:")[2]
        changes = list(
            dict.fromkeys(
                re.findall(rf"(?m)^  {re.escape(package)}: (.+ -> .+)$", report)
            )
        )
        if not changes:
            continue
        found = True
        print(f"{commit[:12]}  {package}: {'; '.join(changes)}")
        after = input_revisions(read_lock(commit))
        try:
            before = input_revisions(read_lock(commit + "^"))
        except subprocess.CalledProcessError:
            before = {}
        for name in sorted(before.keys() | after.keys()):
            old, new = before.get(name), after.get(name)
            if old != new:
                print(f"  {name}: {old or '(absent)'} -> {new or '(absent)'}")
        print(f"  Before: --from '{commit[:12]}^'; after: --from {commit[:12]}")
    if not found:
        print(f"No recorded version changes for {package}")


def change_pin(package, revision):
    flake, lock = Path("flake.nix"), Path("flake.lock")
    original_flake = flake.read_bytes()
    original_lock = lock.read_bytes()
    updated = edit_pin(original_flake.decode(), package, revision)
    try:
        flake.write_bytes(updated.encode())
        subprocess.run(["nix", "flake", "lock"], check=True)
    except (Exception, KeyboardInterrupt):
        flake.write_bytes(original_flake)
        lock.write_bytes(original_lock)
        raise
    if revision is None:
        print(f"Unpinned {package}; restored its configured package source")
    else:
        print(f"Pinned {package} to nixpkgs {revision}")
    print("Review the diff, then run make sync. No packages were installed.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ["history", "pin", "unpin"]:
        command = commands.add_parser(name)
        command.add_argument("package")
        if name == "pin":
            source = command.add_mutually_exclusive_group(required=True)
            source.add_argument("--rev", help="Full nixpkgs commit hash")
            source.add_argument(
                "--from",
                dest="commit",
                help="Repository Git revision containing the desired lock",
            )
            command.add_argument(
                "--input", dest="input_name", help="Root input to read with --from"
            )
    args = parser.parse_args()
    if args.command == "pin":
        if args.commit and not args.input_name:
            parser.error("--from requires --input (for example, nixpkgs-unstable)")
        if args.rev and args.input_name:
            parser.error("--input is only used with --from")
    os.chdir(Path(__file__).resolve().parent.parent)
    try:
        if args.command == "history":
            history(args.package)
        elif args.command == "unpin":
            change_pin(args.package, None)
        else:
            revision = (
                revision_from_commit(args.commit, args.input_name)
                if args.commit
                else args.rev
            )
            change_pin(args.package, revision)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
