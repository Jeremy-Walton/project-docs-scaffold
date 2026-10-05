---
name: project-docs-scaffold
description: Scaffold a standard set of short, single-purpose markdown docs (README, CHANGELOG, AGENTS.md/CLAUDE.md with .agents/ and .claude/ skill and hook folders, and docs/ with PRODUCT, PERSONAS, GLOSSARY, ROADMAP, REJECTED_IDEAS, MONETIZATION, UX_FLOWS, DESIGN, BRAND, DOMAIN, ARCHITECTURE, INTEGRATIONS, CONVENTIONS, plus a per-feature PRD folder and a conventions folder) into a new or existing software project, then help fill them in. Use whenever the user wants to start a new app or project, set up project documentation, scaffold docs, "pull in the doc templates", bootstrap a product spec, or says they're starting something from scratch, even if they don't name this skill.
---

# Project docs scaffold

Drops a ready-made documentation skeleton into a project so the user can start filling it out. Each file answers exactly one question and links to its neighbors instead of repeating them, because duplicated facts drift apart. The files are plain markdown with `{placeholders}` where content goes.

## What gets created

```
README.md                     front door: summary, quick start, doc index
CHANGELOG.md
AGENTS.md                     AI agent entry point: labeled index of every doc, agent rules
CLAUDE.md                     just `@AGENTS.md`
.agents/skills/              real folder (empty, with .gitkeep)
.agents/hooks/               require-doc-template.py: blocks PRD/convention writes that skip the template
                             check-doc-index.py: at end of turn, flags docs missing from their index
                             surface-conventions.py: before an edit, injects conventions whose
                               `<!-- paths: -->` globs in CONVENTIONS.md match the file
.claude/settings.json        wires up the three hooks
.claude/skills -> ../.agents/skills   relative symlinks, made by the script
.claude/hooks  -> ../.agents/hooks
docs/
  PRODUCT.md                  the application concept; indexes a PRD per feature
  product/_TEMPLATE.md        copy per major feature -> product/feature-name.md
  PERSONAS.md  GLOSSARY.md  ROADMAP.md  REJECTED_IDEAS.md  MONETIZATION.md
  UX_FLOWS.md  DESIGN.md  BRAND.md          (BRAND also owns reusable copy)
  DOMAIN.md  ARCHITECTURE.md  INTEGRATIONS.md
  CONVENTIONS.md              index only; rules live in conventions/
  conventions/_TEMPLATE.md    copy per convention -> conventions/slug.md
```

## Steps

1. **Pick the destination.** Use the current working directory unless the user names another. Take the project name from what the user said; if they haven't given one, ask once (or use the directory name if it's obviously the project).
2. **Run the script** from this skill's folder:
   ```bash
   python scripts/scaffold.py --dest <project-root> --name "<Project Name>"
   ```
   It never overwrites existing files (add `--force` only if the user explicitly asks), so it is safe in a project that already has some docs. `--dry-run` previews. It fills the project name and today's date in README and CHANGELOG and leaves every other placeholder alone.
3. **Report briefly**: how many files were created and which, if any, were skipped. If `README.md` was skipped because one already exists, offer to add the documentation table from the template to it rather than replacing it. Same for `AGENTS.md` (offer to merge in the doc index) and `CLAUDE.md` (offer to add an `@AGENTS.md` line). If `.claude/settings.json` was skipped, offer to merge the `hooks` block from the template into it. If `.claude/skills` or `.claude/hooks` already exists as a real folder, the symlink is skipped; mention it and don't move anything without asking.
4. **Offer to start filling it in**, beginning with `docs/PRODUCT.md`. Don't start writing unprompted beyond that offer.

## Helping fill the docs in

The point of the scaffold is that the user fills these in, so make that easy without inventing content.

- Work one doc at a time, in roughly this order: PRODUCT, PERSONAS, GLOSSARY, then whatever the user cares about next. Ask the few questions that doc needs, then write the answers into it.
- Only record what the user actually said. If something is unknown, leave its placeholder; an honest gap beats a plausible guess, since these docs get read as ground truth later.
- When a feature comes up, copy `docs/product/_TEMPLATE.md` to `docs/product/<feature-name>.md` and add a row to the Features table in PRODUCT.md.
- When a doc is added or renamed, update the index in both README.md and AGENTS.md.
- When the user rejects an idea, record it in REJECTED_IDEAS with the reason, so it isn't re-proposed.
- New vocabulary goes into GLOSSARY first; other docs then use the term exactly.
- Leave `docs/conventions/` empty until there is a real convention to record. Use `conventions/_TEMPLATE.md` (its header comment explains when a rule belongs in prose versus a linter or hook), and add the index entry to CONVENTIONS.md.
- Keep each file to roughly a screen. If a doc is growing past that, it probably belongs split or linked out.
- Delete template guidance comments (`<!-- ... -->`) from any file you copy from a `_TEMPLATE.md`.
