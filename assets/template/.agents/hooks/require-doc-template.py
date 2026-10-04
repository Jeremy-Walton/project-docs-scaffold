#!/usr/bin/env python3
"""PreToolUse hook: PRDs and convention files must start from their _TEMPLATE.md.

Exit 2 blocks the write and shows stderr to the agent.
"""
import json
import os
import sys
from pathlib import Path


def headings(text):
    return [line.strip() for line in text.splitlines() if line.startswith("## ")]


def main() -> int:
    data = json.load(sys.stdin)
    tool_input = data.get("tool_input", {})
    content = tool_input.get("content", "")
    root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd", ".")).resolve()
    try:
        rel = Path(tool_input.get("file_path", "")).resolve().relative_to(root)
    except ValueError:
        return 0

    if (
        len(rel.parts) != 3
        or rel.parts[0] != "docs"
        or rel.parts[1] not in ("product", "conventions")
        or rel.suffix != ".md"
        or rel.name == "_TEMPLATE.md"
    ):
        return 0

    template = root / "docs" / rel.parts[1] / "_TEMPLATE.md"
    if not template.is_file():
        return 0

    problems = []
    if not content.lstrip().startswith("# "):
        problems.append("start with a `# Title` line")
    if "<!--" in content:
        problems.append("delete the template's <!-- guidance --> comments")
    # Convention sections are optional by design; PRD sections are not.
    if rel.parts[1] == "product":
        present = set(headings(content))
        missing = [h for h in headings(template.read_text(encoding="utf-8")) if h not in present]
        if missing:
            problems.append(
                "keep every template section, leaving {placeholders} for unknowns; missing: "
                + ", ".join(missing)
            )

    if not problems:
        return 0

    print(f"{rel} must follow docs/{rel.parts[1]}/_TEMPLATE.md:", file=sys.stderr)
    for p in problems:
        print(f"- {p}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
