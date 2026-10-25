# Skill: WKSM Conventions

Load this skill before writing or structuring any code in this service.

## Platform context

This service is part of the WKSM (Workstream Management) platform at approovia-app. It follows the patterns established across the platform. When a convention is not specified here, check `docs/agent/codemap.md` for what this service already does, and follow that pattern.

## Naming

| Context | Convention | Example |
|---|---|---|
| Files and directories | kebab-case | `user-profile.ts`, `billing-events/` |
| TypeScript types and classes | PascalCase | `WorkgroupMember`, `InvoiceLineItem` |
| Functions and variables | camelCase | `getUserProfile`, `lineItemTotal` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Database tables and columns | snake_case | `workgroup_members`, `created_at` |
| Environment variables | UPPER_SNAKE_CASE with service prefix | `WKSM_DATABASE_URL` |
| API routes | kebab-case nouns, plural | `/v1/workgroups`, `/v1/invoice-items` |
| Event types | kebab-case with dot separator | `workgroup.member.added` |

Never use a product name, customer name, or project code (e.g. PSD, ND, S&A) in any identifier, event type, or configuration key. Use generic domain terms.

## TypeScript

- Prefer `type` aliases over `interface` unless declaration merging is needed.
- Use `unknown` over `any`. If `any` is unavoidable, suppress with a narrow `// eslint-disable-next-line @typescript-eslint/no-explicit-any` with a `// reason:` comment on the preceding line, and record the decision in `decisions.md`.
- Prefer `const` over `let`; avoid `var`.
- No implicit `any` — `tsconfig.json` must have `"strict": true`.
- Use explicit return types on exported functions.
- Prefer named exports over default exports.
- Group imports: external packages first, then internal modules, then types.

## Money, rates and quantities

Never use `number` (floating point) for money, rates, or quantities. Use a decimal library (record the choice in `decisions.md`). Rounding mode must be explicit at every calculation boundary and recorded in `decisions.md`.

## Error handling

- At API boundaries: return a typed error response, never throw to the caller.
- At internal boundaries: use a `Result`-style type or typed exceptions; never swallow errors silently.
- Log the full error context (file, function, inputs that are safe to log) before returning an error response.
- Never log credentials, tokens, PII, or full request bodies without scrubbing.

## Database

- Migrations are append-only: never edit an applied migration file.
- Every migration is reversible unless explicitly noted in `decisions.md` with a reason.
- Use parameterised queries everywhere; never interpolate user input into SQL strings.
- RLS (Row Level Security) and constraints are enforced at the database level, not only in application code.

## Testing

- Acceptance tests (`tests/acceptance/`) are black-box: they call the HTTP API, read events, or query the database directly. They never import internal modules.
- Unit tests cover pure functions and non-trivial logic; they do not hit the network or database.
- Test names contain the criterion ID in lowercase with underscores: `m3_ac04_reopen_requires_approval`.
- No test depends on external network services other than those listed in `runbook.md`.
- Tests are deterministic: no `Math.random()`, no `Date.now()` without injection, no order-dependent assertions across test cases.

## Environment and configuration

- All configuration is read from environment variables at startup.
- A missing or invalid required variable stops the service immediately with a clear message naming the variable.
- Document every variable in `README.md` under a "Configuration" section.
- Use `.env.example` (no real values) as a template; never commit `.env`.

## Commits

- Message format: `<scope>: <what changed> (<criterion ID if applicable>)` — e.g. `workgroups: enforce member limit (M3-AC07)`.
- One logical change per commit.
- No AI attribution (enforced by `.claude/settings.json`).
