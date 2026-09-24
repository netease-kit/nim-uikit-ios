#!/usr/bin/env python3
"""Read-only audit of registered Swift UIKit skin deletion targets."""

import argparse
import json
import subprocess
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parent.parent
INVENTORY = SKILL_DIR / "references" / "skin-inventory.json"
ALLOWED_ROOTS = {
    "NEBaseUIKit", "NEChatUIKit", "NEContactUIKit", "NEConversationUIKit",
    "NELocalConversationUIKit", "NETeamUIKit", "app", "app.xcodeproj",
}


def source_root(candidate):
    result = subprocess.run(
        ["git", "-C", str(candidate), "rev-parse", "--show-toplevel"],
        check=True, capture_output=True, text=True,
    )
    root = Path(result.stdout.strip()).resolve()
    if not (root / "NEChatUIKit").is_dir() or not (root / "app").is_dir():
        raise ValueError("checkout must contain NEChatUIKit/ and app/")
    return root


def scoped_path(root, relative):
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] not in ALLOWED_ROOTS:
        raise ValueError(f"out-of-scope inventory path: {relative}")
    target = (root / path).resolve()
    if not target.is_relative_to(root):
        raise ValueError(f"inventory path escapes checkout: {relative}")
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("skin", help="normal / fun (or registered alias)")
    parser.add_argument("--phase", choices=("before", "after"), default="before")
    parser.add_argument("--repo", type=Path, help="source checkout when skill is not installed there")
    args = parser.parse_args()

    inventory = json.loads(INVENTORY.read_text(encoding="utf-8"))
    requested = args.skin.casefold().strip()
    matches = [(key, skin) for key, skin in inventory["skins"].items()
               if requested in [alias.casefold() for alias in skin["aliases"]]]
    if len(matches) != 1:
        parser.error(f"unknown skin {args.skin!r}; use normal or fun")
    skin_name, skin = matches[0]
    root = source_root(args.repo or SKILL_DIR)
    owned = skin["owned_paths"] + inventory["common_removals"]
    shared = inventory["shared_paths"] + skin.get("extra_edit_paths", [])
    if len(set(owned + shared)) != len(owned + shared):
        raise ValueError("duplicate paths in inventory")

    print(f"{skin_name} / {args.phase} / {root}")
    structural_errors = 0

    # A deletion can expose a shared type that lived in the removed skin
    # directory. These migrations are part of the inventory so callers do not
    # need a second repository-wide search to discover them.
    migrations = inventory.get("shared_migrations", {}).get(skin_name, [])
    for migration in migrations:
        source = scoped_path(root, migration["from"])
        destination = scoped_path(root, migration["to"])
        if args.phase == "before":
            source_state = "present" if source.exists() else "missing"
            destination_state = "present" if destination.exists() else "absent"
            print(f"  MOVE {migration['from']} -> {migration['to']} (before: {source_state}, destination: {destination_state})")
            if not source.exists():
                structural_errors += 1
        elif source.exists() or not destination.exists():
            print(f"  MOVE unresolved: {migration['from']} -> {migration['to']}")
            structural_errors += 1
        else:
            print(f"  MOVED {migration['from']} -> {migration['to']}")

    for relative, forbidden in skin.get("project_cleanup", {}).items():
        path = scoped_path(root, relative)
        if not path.is_file():
            print(f"  MISSING project cleanup path: {relative}")
            structural_errors += 1
            continue
        contents = path.read_text(encoding="utf-8", errors="replace")
        remaining = [marker for marker in forbidden if marker in contents]
        if args.phase == "before":
            state = "present" if remaining else "already absent"
            print(f"  PROJECT REFS {relative}: {state}")
        elif remaining:
            print(f"  PROJECT REFS unresolved in {relative}: {', '.join(remaining)}")
            structural_errors += len(remaining)
        else:
            print(f"  PROJECT REFS clean: {relative}")

    present = []
    for relative in owned:
        if scoped_path(root, relative).exists():
            present.append(relative)
    print(f"owned paths present: {len(present)} / {len(owned)}")
    for relative in present:
        print(f"  DELETE {relative}")
    if args.phase == "before":
        for relative in owned:
            if relative not in present:
                print(f"  ABSENT {relative} (already removed or inventory drift)")

    missing = []
    candidates = 0
    unresolved_candidates = 0
    accepted_candidates = {
        (entry["path"], entry["contains"])
        for entry in skin.get("accepted_candidates", [])
    }
    for relative in shared:
        path = scoped_path(root, relative)
        if not path.is_file():
            missing.append(relative)
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if any(marker in line for marker in skin["markers"]):
                candidates += 1
                stripped = line.strip()
                if any(path == relative and marker in stripped for path, marker in accepted_candidates):
                    print(f"  KEEP {relative}:{number}: {stripped[:180]}")
                else:
                    unresolved_candidates += 1
                    print(f"  REVIEW {relative}:{number}: {stripped[:180]}")
    print(f"shared candidate lines: {candidates}; unresolved: {unresolved_candidates}; missing shared paths: {len(missing)}")
    for relative in missing:
        print(f"  MISSING {relative}")
    if args.phase == "after" and (present or unresolved_candidates or missing or structural_errors):
        print("after audit needs resolution: inspect only the registered paths and structural checks above")
        return 1
    if args.phase == "before" and (missing or structural_errors):
        print("before audit has drift: update the inventory before deleting")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
