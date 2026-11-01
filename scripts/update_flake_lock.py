#!/usr/bin/env python3
"""Update the lock file and report tool and NixOS kernel versions without builds."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import uuid


PACKAGE_MANIFEST = """
packages: builtins.mapAttrs (_system: hosts:
  builtins.mapAttrs (_host: env:
    builtins.map (p: {
      name = p.pname or p.name;
      version = p.version or null;
    }) env.paths
  ) hosts
) packages
"""


def evaluate_nix(attribute, expression):
    result = subprocess.run(
        [
            "nix",
            "eval",
            "--json",
            "--no-update-lock-file",
            attribute,
            "--apply",
            expression,
        ],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return json.loads(result.stdout)


def evaluate_packages():
    return evaluate_nix(".#packages", PACKAGE_MANIFEST)


def evaluate_kernels():
    return evaluate_nix(
        ".#nixosConfigurations",
        "configurations: builtins.mapAttrs (_host: nixos: "
        "nixos.config.boot.kernelPackages.kernel.version) configurations",
    )


def package_versions(packages):
    versions = {}
    for package in packages:
        version = package["version"]
        versions.setdefault(package["name"], set()).add(
            str(version) if version is not None else "(unknown)"
        )
    return versions


def render_message(before, after, old_lock, new_lock, kernels_before, kernels_after):
    lines = ["chore(deps): update flake inputs", "", "Flake inputs:"]
    old_nodes = old_lock["nodes"]
    new_nodes = new_lock["nodes"]
    input_changes = []
    for name in sorted(old_nodes.keys() | new_nodes.keys()):
        old = old_nodes.get(name, {}).get("locked")
        new = new_nodes.get(name, {}).get("locked")
        if old == new:
            continue

        def revision(locked):
            if locked is None:
                return "(absent)"
            return locked.get("rev") or locked.get("narHash") or "(unversioned)"

        detail = f"  {name}: {revision(old)} -> {revision(new)}"
        if revision(old) == revision(new):
            detail += " (lock metadata changed)"
        input_changes.append(detail)
    lines.extend(input_changes or ["  No input changes."])
    lines.extend(["", "NixOS kernels:"])
    kernel_changes = []
    for host in sorted(kernels_before.keys() | kernels_after.keys()):
        old = kernels_before.get(host, "(absent)")
        new = kernels_after.get(host, "(absent)")
        if old != new:
            kernel_changes.append(f"  {host}: {old} -> {new}")
    lines.extend(kernel_changes or ["  No kernel version changes."])
    lines.extend(["", "Direct packages:"])

    changed_hosts = []
    for system in sorted(before.keys() | after.keys()):
        old_hosts = before.get(system, {})
        new_hosts = after.get(system, {})
        for host in sorted(old_hosts.keys() | new_hosts.keys()):
            old_versions = package_versions(old_hosts.get(host, []))
            new_versions = package_versions(new_hosts.get(host, []))
            changes = []
            for name in sorted(old_versions.keys() | new_versions.keys()):
                old = old_versions.get(name, set())
                new = new_versions.get(name, set())
                if old != new:
                    old_text = ", ".join(sorted(old)) or "(absent)"
                    new_text = ", ".join(sorted(new)) or "(absent)"
                    changes.append(f"  {name}: {old_text} -> {new_text}")
            if changes:
                changed_hosts.extend([f"{host} ({system}):", *changes, ""])
    lines.extend(changed_hosts or ["  No direct package version changes."])
    return "\n".join(lines).rstrip() + "\n"


def update(output_dir):
    lock_path = Path("flake.lock")
    old_contents = lock_path.read_bytes()
    before = evaluate_packages()
    kernels_before = evaluate_kernels()
    subprocess.run(["nix", "flake", "update"], check=True)
    new_contents = lock_path.read_bytes()
    changed = old_contents != new_contents
    after = evaluate_packages() if changed else before
    kernels_after = evaluate_kernels() if changed else kernels_before
    message = render_message(
        before,
        after,
        json.loads(old_contents),
        json.loads(new_contents),
        kernels_before,
        kernels_after,
    )
    body = (
        "Automated flake input update. This PR is refreshed twice daily.\n\n"
        "```text\n" + message + "```\n\n"
        "The report covers directly selected tools and configured NixOS kernel "
        "versions, not the full NixOS closure or the currently running kernels. "
        "Same-version rebuilds and transitive dependency changes "
        "are not listed.\n\n"
        "Package metadata evaluation and `nix flake check --no-build --all-systems` "
        "run before this PR is published. No builds or deployments are performed.\n\n"
        "After required checks pass, this PR is automatically squash-merged, "
        "including kernel updates. The version report is retained in the "
        "commit message.\n"
    )
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "commit-message.txt").write_text(message, encoding="utf-8")
    (output_dir / "pr-body.md").write_text(body, encoding="utf-8")
    for name, manifest in [
        ("before", {"packages": before, "kernels": kernels_before}),
        ("after", {"packages": after, "kernels": kernels_after}),
    ]:
        (output_dir / f"{name}.json").write_text(
            json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
    if output := os.environ.get("GITHUB_OUTPUT"):
        delimiter = uuid.uuid4().hex
        with open(output, "a", encoding="utf-8") as stream:
            stream.write(f"changed={str(changed).lower()}\n")
            stream.write(f"commit-message<<{delimiter}\n{message}{delimiter}\n")
    print(message, end="")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    update(args.output_dir)


if __name__ == "__main__":
    main()
