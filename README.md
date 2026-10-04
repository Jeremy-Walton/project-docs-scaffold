# project-docs-scaffold

A Claude skill that scaffolds a set of short, single-purpose markdown docs into a new or existing software project, then helps fill them in. See [SKILL.md](SKILL.md) for what it creates and how it behaves.

## Install

For Claude Code, clone straight into your personal skills folder (available in every project):

```bash
git clone <repo-url> ~/.claude/skills/project-docs-scaffold
```

Or package it for the Claude app by zipping the folder contents as a `.skill` file and uploading it in Settings.

## Layout

```
SKILL.md              skill instructions and trigger description
scripts/scaffold.py   copies the template into a project (never overwrites)
assets/template/      the doc set that gets copied; edit these to change the template
```

## Use the script directly

```bash
python scripts/scaffold.py --dest <project-root> --name "My App"   # --dry-run to preview
```
