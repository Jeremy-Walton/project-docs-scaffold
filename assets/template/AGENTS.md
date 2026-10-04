# AGENTS.md

Instructions for AI agents working in this repo. The human overview is [README](README.md).

## Docs

- [README](README.md): summary and quick start
- [CHANGELOG](CHANGELOG.md): release history
- [PRODUCT](docs/PRODUCT.md): app concept; indexes feature PRDs
- [product/](docs/product/): one PRD per feature
- [PERSONAS](docs/PERSONAS.md): who it's for
- [GLOSSARY](docs/GLOSSARY.md): canonical terms
- [ROADMAP](docs/ROADMAP.md): what ships when
- [REJECTED_IDEAS](docs/REJECTED_IDEAS.md): ideas ruled out, with reasons
- [MONETIZATION](docs/MONETIZATION.md): revenue model
- [UX_FLOWS](docs/UX_FLOWS.md): user journeys and behavior
- [DESIGN](docs/DESIGN.md): look and feel
- [BRAND](docs/BRAND.md): voice, tone, reusable copy
- [DOMAIN](docs/DOMAIN.md): core entities and relationships
- [STACK](docs/STACK.md): languages, frameworks, tools
- [ARCHITECTURE](docs/ARCHITECTURE.md): how the pieces fit together
- [INTEGRATIONS](docs/INTEGRATIONS.md): third-party services
- [CONVENTIONS](docs/CONVENTIONS.md): coding rules index; rules live in [conventions/](docs/conventions/)

## Agent config

- `.agents/skills/`: project skills (`.claude/skills` links here)
- `.agents/hooks/`: hook scripts (`.claude/hooks` links here)

## Rules

- Read PRODUCT, GLOSSARY, and REJECTED_IDEAS before proposing features.
- Use GLOSSARY terms exactly. Don't invent synonyms.
- Check STACK and CONVENTIONS before writing code.
- If docs conflict, the more specific doc wins; flag the conflict instead of guessing.
