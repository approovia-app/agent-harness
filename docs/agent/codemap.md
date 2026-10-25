# Codemap

Where things live in this codebase. Overwrite when the structure changes. Cap at about 150 lines.

## Format

```text
<path>  — <what it contains / why it exists>
```

## Structure

_Fill in after first reading the repo. Example:_

```
src/
  api/          — HTTP route handlers
  domain/       — business logic, pure functions
  db/           — database queries and migrations
  events/       — event schema types and publishers
  config.ts     — reads and validates all env vars at startup
tests/
  acceptance/   — black-box HTTP + DB tests (frozen in phase B)
  unit/         — pure function tests
scripts/
  verify.sh     — the agent verify gate
docs/
  design.md     — requirements (read-only)
  milestones.md — acceptance criteria (read-only)
  agent/        — agent memory files
```
