#!/usr/bin/env python3
"""Copy the bundled project-docs template into a project directory.

Existing files are never overwritten unless --force is given, so it is safe to
run in a project that already has a README or some docs.

Usage:
    python scaffold.py --dest . --name "My App"
    python scaffold.py --dest ~/code/new-thing --dry-run
"""
import argparse
import datetime
import os
import shutil
import sys
from pathlib import Path

TEMPLATE = Path(__file__).resolve().parent.parent / "assets" / "template"

# Placeholders filled at scaffold time. Everywhere else, {braces} are meant to
# be filled in by hand (or by Claude) while writing the docs, so leave them.
DATE_FILES = {"README.md", "CHANGELOG.md"}

# Created as relative symlinks rather than stored in the template, because
# zipping the skill for upload can flatten symlinks into copies.
SYMLINKS = {
    ".claude/skills": "../.agents/skills",
    ".claude/hooks": "../.agents/hooks",
}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--dest", default=".", help="project root (default: current dir)")
    ap.add_argument("--name", help="project name, written into README.md")
    ap.add_argument("--force", action="store_true", help="overwrite existing files")
    ap.add_argument("--dry-run", action="store_true", help="report only, write nothing")
    args = ap.parse_args()

    if not TEMPLATE.is_dir():
        print(f"error: template not found at {TEMPLATE}", file=sys.stderr)
        return 1

    dest = Path(args.dest).expanduser().resolve()
    today = datetime.date.today().isoformat()
    created, skipped = [], []

    for src in sorted(TEMPLATE.rglob("*")):
        if not src.is_file():
            continue
        rel = src.relative_to(TEMPLATE)
        out = dest / rel

        if out.exists() and not args.force:
            skipped.append(rel)
            continue

        created.append(rel)
        if args.dry_run:
            continue

        out.parent.mkdir(parents=True, exist_ok=True)
        if str(rel) in DATE_FILES or (args.name and str(rel) == "README.md"):
            text = src.read_text(encoding="utf-8")
            if str(rel) in DATE_FILES:
                text = text.replace("{YYYY-MM-DD}", today)
            if args.name and str(rel) == "README.md":
                text = text.replace("{Project Name}", args.name)
            out.write_text(text, encoding="utf-8")
        else:
            shutil.copy2(src, out)

    for link, target in SYMLINKS.items():
        out = dest / link
        if os.path.lexists(out):
            skipped.append(Path(link))
            continue
        created.append(Path(f"{link} -> {target}"))
        if args.dry_run:
            continue
        out.parent.mkdir(parents=True, exist_ok=True)
        out.symlink_to(target, target_is_directory=True)

    verb = "Would create" if args.dry_run else "Created"
    print(f"{verb} {len(created)} file(s) in {dest}")
    for rel in created:
        print(f"  + {rel}")
    if skipped:
        print(f"Skipped {len(skipped)} existing file(s) (use --force to overwrite)")
        for rel in skipped:
            print(f"  = {rel}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
