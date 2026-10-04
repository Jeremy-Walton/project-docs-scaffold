#!/usr/bin/env python3
"""PreToolUse hook: before an edit, show the agent every convention whose
`<!-- paths: ... -->` globs in docs/CONVENTIONS.md match the file.

Each convention is sent once per session, tracked in a temp-dir state file,
so repeated edits don't flood the context.
"""
import json
import os
import re
import sys
import tempfile
from pathlib import Path

ENTRY = re.compile(r"\]\((conventions/[^)#\s]+\.md)[^)]*\).*<!--\s*paths:\s*(.+?)\s*-->")


def split_globs(spec):
    """Split on whitespace or commas, except commas inside {a,b}."""
    globs, cur, depth = [], "", 0
    for c in spec:
        depth += (c == "{") - (c == "}")
        if (c.isspace() or c == ",") and depth == 0:
            if cur:
                globs.append(cur)
            cur = ""
        else:
            cur += c
    if cur:
        globs.append(cur)
    return globs


def glob_to_regex(glob):
    out, i, depth = [], 0, 0
    while i < len(glob):
        if glob.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
            continue
        if glob.startswith("**", i):
            out.append(".*")
            i += 2
            continue
        c = glob[i]
        if c == "*":
            out.append("[^/]*")
        elif c == "?":
            out.append("[^/]")
        elif c == "{":
            depth += 1
            out.append("(?:")
        elif c == "}" and depth:
            depth -= 1
            out.append(")")
        elif c == "," and depth:
            out.append("|")
        else:
            out.append(re.escape(c))
        i += 1
    return re.compile("".join(out) + r"\Z")


def matching_conventions(index_text, rel):
    matches, in_fence = [], False
    for line in index_text.splitlines():
        # Skips the shape example in the index's code fence.
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        m = None if in_fence else ENTRY.search(line)
        if m and any(glob_to_regex(g).match(rel) for g in split_globs(m.group(2))):
            matches.append(m.group(1))
    return matches


def main() -> int:
    data = json.load(sys.stdin)
    root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd", ".")).resolve()
    index = root / "docs" / "CONVENTIONS.md"
    if not index.is_file():
        return 0
    try:
        rel = Path(data.get("tool_input", {}).get("file_path", "")).resolve().relative_to(root)
    except ValueError:
        return 0

    state = Path(tempfile.gettempdir()) / f"claude-conventions-{data.get('session_id', 'none')}.txt"
    seen = set(state.read_text().split()) if state.is_file() else set()

    new = [
        c for c in matching_conventions(index.read_text(encoding="utf-8"), rel.as_posix())
        if c not in seen and (root / "docs" / c).is_file()
    ]
    if not new:
        return 0

    parts = [f"Conventions that apply to {rel.as_posix()}. Follow them in this edit."]
    for c in new:
        parts.append(f"--- docs/{c} ---\n" + (root / "docs" / c).read_text(encoding="utf-8").strip())
    with state.open("a") as f:
        f.write("\n".join(new) + "\n")

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": "\n\n".join(parts),
        }
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
