#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parent.parent
REGISTRY_PATH = SKILL_DIR / "references" / "feature-registry.json"
ALLOWED_PREFIXES = (
    "NEChatUIKit/",
    "app/",
)


def load_registry():
    with REGISTRY_PATH.open(encoding="utf-8") as handle:
        return json.load(handle)


def resolve_feature(registry, requested):
    normalized = requested.casefold().strip()
    for slug, entry in registry.items():
        candidates = [slug, *entry.get("aliases", [])]
        if normalized in {candidate.casefold().strip() for candidate in candidates}:
            return slug, entry
    available = ", ".join(sorted(registry))
    raise ValueError(f"unknown feature {requested!r}; available: {available}")


def validate_scope(entry):
    path_groups = [
        entry.get("owned_paths", []),
        entry.get("edit_paths", []),
        entry.get("residual", {}).get("roots", []),
        entry.get("residual", {}).get("allowed_paths", []),
    ]
    invalid = sorted(
        {
            path
            for paths in path_groups
            for path in paths
            if Path(path).is_absolute()
            or ".." in Path(path).parts
            or not any(
                path == prefix.rstrip("/") or path.startswith(prefix)
                for prefix in ALLOWED_PREFIXES
            )
        }
    )
    if invalid:
        raise ValueError(
            "inventory contains paths outside NEChatUIKit/app scope: "
            + ", ".join(invalid)
        )


def git_root(candidate):
    result = subprocess.run(
        ["git", "-C", str(candidate), "rev-parse", "--show-toplevel"],
        check=True,
        capture_output=True,
        text=True,
    )
    return Path(result.stdout.strip()).resolve()


def has_expected_layout(root):
    return (root / "NEChatUIKit").is_dir() and (root / "app").is_dir()


def repository_root(requested):
    candidates = [requested.expanduser().resolve()] if requested else [SKILL_DIR, Path.cwd()]
    checked = []
    for candidate in candidates:
        try:
            root = git_root(candidate)
        except (OSError, subprocess.CalledProcessError):
            continue
        if root in checked:
            continue
        checked.append(root)
        if has_expected_layout(root):
            return root

    if requested:
        raise ValueError(
            f"{requested} is not a source checkout with NEChatUIKit/ and app/"
        )
    raise ValueError(
        "cannot locate a source checkout with NEChatUIKit/ and app/; "
        "place this skill under skills/ in that repository or pass --repo"
    )


def existing_paths(repo_root, paths):
    return [path for path in paths if (repo_root / path).exists()]


def residual_files(repo_root, residual):
    roots = [root for root in residual.get("roots", []) if (repo_root / root).exists()]
    patterns = residual.get("patterns", [])
    if not roots or not patterns:
        return []

    command = [
        "rg",
        "-l",
        "--hidden",
        "--glob",
        "!**/.git/**",
        "--glob",
        "!**/Pods/**",
        "--glob",
        "!**/build/**",
    ]
    for pattern in patterns:
        command.extend(["-e", pattern])
    command.extend(roots)
    result = subprocess.run(command, cwd=repo_root, capture_output=True, text=True)
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr.strip() or "rg failed")
    return sorted({line.strip() for line in result.stdout.splitlines() if line.strip()})


def main():
    parser = argparse.ArgumentParser(description="Audit a registered Swift feature inventory")
    parser.add_argument("feature", nargs="?", help="feature slug or registered alias")
    parser.add_argument("--phase", choices=("before", "after"), default="before")
    parser.add_argument("--list", action="store_true", help="list registered features")
    parser.add_argument(
        "--repo",
        type=Path,
        help="source checkout; defaults to the skill's repository, then the current directory",
    )
    args = parser.parse_args()

    registry = load_registry()
    if args.list:
        for slug, entry in sorted(registry.items()):
            print(f"{slug}: {', '.join(entry.get('aliases', []))}")
        return 0
    if not args.feature:
        parser.error("feature is required unless --list is used")

    try:
        slug, entry = resolve_feature(registry, args.feature)
        validate_scope(entry)
        repo_root = repository_root(args.repo)
        owned_present = existing_paths(repo_root, entry.get("owned_paths", []))
        edit_missing = [
            path for path in entry.get("edit_paths", []) if not (repo_root / path).exists()
        ]
        matches = residual_files(repo_root, entry.get("residual", {}))
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    allowed = set(entry.get("residual", {}).get("allowed_paths", []))
    forbidden_matches = [path for path in matches if path not in allowed]
    allowed_matches = [path for path in matches if path in allowed]
    registered = set(entry.get("owned_paths", [])) | set(entry.get("edit_paths", [])) | allowed
    unregistered_matches = [path for path in matches if path not in registered]

    print(f"feature: {slug}")
    print(f"repository: {repo_root}")
    print(f"phase: {args.phase}")
    print(f"owned paths present: {len(owned_present)}/{len(entry.get('owned_paths', []))}")
    for path in owned_present:
        print(f"  owned: {path}")
    for path in edit_missing:
        print(f"  warning missing edit target: {path}")
    print(f"residual files: {len(matches)}")
    for path in forbidden_matches:
        print(f"  residual: {path}")
    for path in allowed_matches:
        print(f"  allowed shared residual: {path}")
    for path in unregistered_matches:
        print(f"  inventory gap: {path}")

    if args.phase == "after" and (owned_present or forbidden_matches):
        print("audit failed: feature-owned paths or non-allowed residuals remain", file=sys.stderr)
        return 1
    if args.phase == "before" and unregistered_matches:
        print("audit failed: residual files are missing from the inventory", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
