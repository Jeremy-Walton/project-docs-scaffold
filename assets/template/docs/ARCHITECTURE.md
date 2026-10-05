# Architecture

How the pieces fit together.

## Overview

{One paragraph: the shape of the system.}

## Diagram

```
{client} -> {api} -> {database}
              |
              +--> {external service}
```

## Components

| Component | Responsibility | Talks to |
|---|---|---|
| {name} | {what it owns} | {neighbors} |

## Data flow

{Follow one important request end to end.}

## Boundaries

{What's allowed to call what. What's deliberately kept separate.}

## Deployment

{Environments (dev/staging/prod), how code gets from commit to running.}
