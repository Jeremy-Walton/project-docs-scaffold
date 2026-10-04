#!/usr/bin/env python3
"""Stop hook: every doc must be linked from the index that owns it.

Exit 2 keeps the agent working and shows stderr to it.
"""
import json
import os
import sys
from pathlib import Path

# (docs to check, index file that must link each one)
INDEXES = [
    ("docs/*.md", "AGENTS.md"),
    ("docs/*.md", "README.md"),
    ("docs/product/*.md", "docs/PRODUCT.md"),
    ("docs/conventions/*.md", "docs/CONVENTIONS.md"),
]


def main() -> int:
    data = json.load(sys.stdin)
    # Set when the agent is already continuing because of a Stop hook; nagging
    # again would loop forever.
    if data.get("stop_hook_active"):
        return 0

    root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd", "."))
    missing = []
    for pattern, index_name in INDEXES:
        index = root / index_name
        if not index.is_file():
            continue
        text = index.read_text(encoding="utf-8")
        for doc in sorted(root.glob(pattern)):
            if doc.name == "_TEMPLATE.md":
                continue
            link = os.path.relpath(doc, index.parent)
            if f"]({link}" not in text:
                missing.append(f"{doc.relative_to(root)} is not linked from {index_name}")

    if not missing:
        return 0

    print("Docs missing from their index:", file=sys.stderr)
    for m in missing:
        print(f"- {m}", file=sys.stderr)
    print("Add the entries, or ask the user if a doc should stay unlisted.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
