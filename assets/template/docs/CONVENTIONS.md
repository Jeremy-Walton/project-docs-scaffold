# Conventions

Index only. The rules live in [`conventions/`](conventions/), one short file per topic. Copy [`conventions/_TEMPLATE.md`](conventions/_TEMPLATE.md) to start a new one.

## What belongs in a convention file

<!-- Fill in per project. Suggested starting rules: -->

- **Rules the tooling can't enforce.** If a linter, formatter, generator, or hook can check it, configure that instead of writing prose.
- **Facts the code can't tell you on sight.** Traps, non-obvious constraints, and the reason behind a rule that looks arbitrary.
- **Not what other docs already own.** Technology choices live in [STACK](STACK.md), structure in [ARCHITECTURE](ARCHITECTURE.md), terms in [GLOSSARY](GLOSSARY.md).
- **Not step-by-step instructions or restated signatures.** Point at a reference implementation instead.

## Index

One entry per convention file, in this shape (delete this example once you have a real entry):

```markdown
- [Title](conventions/slug.md) — what the file covers, not its rules. <!-- paths: src/**/*.ext -->
```

## Adding a convention

1. Confirm it belongs here (see above).
2. Copy `conventions/_TEMPLATE.md` to `conventions/kebab-case-slug.md` and fill it in.
3. Add an index entry above in the shape shown.
