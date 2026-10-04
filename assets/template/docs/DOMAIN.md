# Domain

The core concepts and how they relate. Human-language definitions live in the [GLOSSARY](GLOSSARY.md); this is the structural side.

## Entities

### {Entity}

| Field | Type | Notes |
|---|---|---|
| id | | |
| | | |

**Relationships:** {e.g. belongs to X, has many Y}
**Rules:** {invariants, e.g. "name must be unique per account"}

## Relationship overview

```
{Entity A} 1---* {Entity B}
{Entity B} *---* {Entity C}
```

## Lifecycles

{State machines for entities that change status, e.g. draft -> active -> archived.}

## Sensitive data

{Which fields hold personal or private information, and any handling rules.}
