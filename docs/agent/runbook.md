# Runbook

Build, test, and run commands for this service. Update as soon as something changes or is discovered. Cap at about 150 lines.

## Environment setup

```bash
# Required: Node version (fill in after confirming)
node --version   # must match .nvmrc or engines.node in package.json

# Install dependencies
npm install

# Copy and fill in local env
cp .env.example .env
# Edit .env — see README.md for each variable's meaning
```

## Common commands

| Task | Command |
|---|---|
| Run verify gate | `bash scripts/verify-agent.sh` |
| Run tests only | `npm test` |
| Run type check | `npm run typecheck` |
| Run lint | `npm run lint` |
| Fix lint auto-fixable | `npm run lint:fix` |
| Start dev server | `npm run dev` |
| Build for production | `npm run build` |

_Fill in the actual commands after reading `package.json` scripts._

## Database (if applicable)

```bash
# Start local DB (fill in with docker-compose command or similar)
# Run migrations
# Seed test data
```

## Known gotchas

_None yet. Add entries here as they are discovered._

## Pinned versions

| Tool | Version | Source |
|---|---|---|
| Node | (fill in) | .nvmrc |
| npm | (fill in) | engines field |

_Fill in when confirmed. Never write versions from memory._
