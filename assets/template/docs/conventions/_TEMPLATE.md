<!--
Copy to `docs/conventions/<kebab-case-slug>.md`, fill it in, and delete every comment.

Before writing one, confirm a convention file is the right home — see
"What belongs in a convention file" in ../CONVENTIONS.md. A linter, generator, or hook beats prose.

Then add an index entry to ../CONVENTIONS.md in the same shape as its neighbors: the title, the
link, an em dash, what the file covers (not its rules), and a trailing `paths:` comment listing the
globs that should surface it.

Keep the whole file to a screen. Drop any section below that has nothing to say.
-->

# Title

<!--
Optional. One or two sentences of scope: what this applies to, and the fact the rules below follow from.
Name the reference implementation instead of transcribing it.
-->

Scope sentence. See `path/to/reference-file`.

<!--
One bullet per rule. State the rule, then the why only where the rule looks arbitrary without it.
Bold the lead sentence of a rule that guards a trap. Never restate signatures, arguments, or steps.
-->

- **The rule, stated as an instruction.** The why — a fact about the world the code can't tell you on sight.
- A rule that needs no justification.
- Do X, not Y — the consequence of Y.

## Subtopic

<!-- Optional. Split into `##` sections only when the rules fall into distinct groups. -->

- Rule.

<!-- Optional. Point at related conventions or docs rather than repeating them. -->

See [Related Convention](related-convention.md) for the matching rule in another context.
