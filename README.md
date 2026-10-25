# approovia-app / agent-harness

A portable agent harness that overlays onto any approovia-app repository without modifying its existing files. It gives a coding agent a structured work loop, persistent memory, a verify gate, and an independent code-review mechanism.

Inspired by and adapted from [capitix/template](https://github.com/capitix/template).

---

## Two modes — auto-detected by `attach.sh`

| Mode | When | What gets added |
|---|---|---|
| **Fresh** | No `AGENTS.md` in target yet | Full harness: AGENTS.md, settings.json, all skills, memory files, verify-agent.sh |
| **Existing** | `AGENTS.md` already exists | Harness layer only: memory files, agent-run skill, systematic-debugging, code-review, verify-agent.sh. **Never touches** AGENTS.md, settings.json, or existing skills. |

The approovia-app `backend` and `frontend` repos are **existing** repos — they have a generated `AGENTS.md` and a centrally managed `.claude/settings.json`. The harness adds alongside that system, not on top of it.

---

## What this provides

| File / directory | Added to | Purpose |
|---|---|---|
| `AGENTS.md` | Fresh repos only | Agent rules: sources of truth, memory system, work loop, exit conditions |
| `.claude/settings.json` | Fresh repos only | Disables cross-session memory; removes AI attribution |
| `.claude/skills/agent-run/` | All repos | Run loop, phases A/B, exit conditions, session management, issue classification |
| `.claude/skills/systematic-debugging/` | All repos | Read before you change anything |
| `.claude/skills/code-review/` | All repos | Independent milestone review gate with severity levels |
| `.claude/skills/wksm-conventions/` | Fresh repos only | WKSM naming, TypeScript, money, testing, env-var rules |
| `docs/agent/*.md` | All repos | 8 memory files the agent reads and writes across sessions |
| `scripts/verify-agent.sh` | All repos | The verify gate — adapt ADAPT: sections for this repo's stack |
| `scripts/attach.sh` | (harness repo) | Copies harness into a target repo without overwriting existing files |

---

## Attaching to a repository

### Prerequisites

- `bash` available (Git Bash on Windows; built-in on macOS/Linux)
- The target repo must be a git repository (`git init` or cloned)
- `gh` CLI authenticated (`gh auth status`) — needed for issue classification

### Steps

```bash
# 1. Clone or update this harness
git clone https://github.com/approovia-app/agent-harness
cd agent-harness

# 2. Attach to the target repo (mode is auto-detected)
bash scripts/attach.sh /path/to/target-repo "My Service Name"

# 3. Follow the printed checklist
```

The script prints a checklist specific to the detected mode (fresh or existing). Nothing is committed or pushed — you do that manually.

### For existing approovia-app repos (backend, frontend, etc.)

```bash
# Clone the repo
gh repo clone approovia-app/backend

# Attach harness layer
bash agent-harness/scripts/attach.sh ./backend "WKSM Backend"

# What gets added (nothing existing is touched):
#   docs/agent/            8 memory files
#   .claude/skills/agent-run/
#   .claude/skills/systematic-debugging/
#   .claude/skills/code-review/
#   scripts/verify-agent.sh
```

**settings.json note:** The backend/frontend `.claude/settings.json` is generated from `handbook/standards/claude-settings.yaml` and cannot be modified. To disable cross-session memory for agent runs, add a gitignored local override:

```bash
echo '{"autoMemoryEnabled": false}' > .claude/settings.local.json
echo '.claude/settings.local.json' >> .gitignore
```

Or propose adding `"autoMemoryEnabled": false` to `handbook/standards/claude-settings.yaml` so it propagates everywhere.

---

## Before starting a run — maintainer checklist

Complete all of these before handing the repo to an agent.

### 1. Write `docs/design.md`

The design is the highest authority. The agent reads only the sections it needs.

Minimum sections:
- **§1 Purpose** — what problem this service solves
- **§2 Scope** — what is and is not in scope
- **§3 Public contracts** — API routes, event types, command types
- **§4 Invariants** — rules that must hold at all times (data integrity, security)
- **§5 Configuration** — every environment variable

If requirements live in GitHub issues, summarise them here rather than pointing the agent at the issue list as the primary source. The design wins over issues when they conflict.

### 2. Write `docs/milestones.md`

Defines what "done" means per milestone, as testable acceptance criteria.

Format:

```markdown
## M1 — <milestone name>

**Context:** One paragraph on what this milestone delivers and why.

### Acceptance criteria

| ID | Criterion | Test type |
|---|---|---|
| M1-AC01 | POST /v1/workgroups returns 201 with a valid workgroup object | HTTP |
| M1-AC02 | Creating a workgroup with a duplicate name returns 409 | HTTP |
| M1-AC03 | workgroup.created event is published within 1 second | Event |
```

Rules:
- Each criterion has a unique ID (`Mn-ACnn`).
- Every criterion must be testable without reading internal code.
- Every criterion must appear in at least one acceptance test name (e.g. `m1_ac01_create_workgroup`).

### 3. Adapt `scripts/verify.sh`

Fill in the `ADAPT:` sections with this repo's actual commands:

```bash
# Format
npm run format:check    # or: npx prettier --check "src/**/*.ts"

# Lint
npm run lint

# Type check
npm run typecheck       # or: npx tsc --noEmit

# Unit tests
npm test

# Acceptance tests per milestone
milestone_number 1 npm run test:acceptance -- --grep "m1_"
milestone_number 2 npm run test:acceptance -- --grep "m2_"
```

Run `bash scripts/verify.sh` yourself first. It must exit 0 before you hand the repo to an agent.

### 4. Update `docs/agent/decisions.md`

Fill in D-003 (decimal library) and add any other baseline decisions:
- Which HTTP framework (if applicable)
- Which database client
- Which test runner
- Which date/time library

Mark these as `Made by: maintainer` — they are binding.

### 5. Update `docs/agent/runbook.md`

Add the working commands for this specific repo:
- Exact `npm install` / setup steps
- Database start command (if any)
- How to run individual test files
- Known environment gotchas

### 6. Create the run branch and push

```bash
cd /path/to/target-repo
git checkout -b agent/run-01
git add docs/ .claude/ AGENTS.md scripts/verify.sh
git commit -m "harness: attach agent harness for run-01"
git push -u origin agent/run-01
```

---

## Starting a run

### Fresh repos (new service, no existing AGENTS.md)

```
You are starting run-01 on the agent/run-01 branch of this repository.

Read AGENTS.md in full before doing anything else.
Then follow the session start steps in §3.1 exactly:
  1. Confirm you are on branch agent/run-01, then git pull --rebase.
  2. Check the active session marker in docs/agent/progress.md.
  3. Check whether the previous session was interrupted (docs/agent/sessions.md).
  4. Continue from the step in docs/agent/progress.md.

The verify gate is scripts/verify-agent.sh.
The milestone criteria are in docs/milestones.md.
The design is in docs/design.md.
Current phase: A (foundation and acceptance tests).
```

### Existing repos (backend, frontend — already have AGENTS.md)

```
You are starting run-01 on the agent/run-01 branch of this repository.

1. Read AGENTS.md — this repo's operational rules. They all apply.
2. Load .claude/skills/agent-run/SKILL.md — this adds the run management
   layer (phases, memory system, work loop, exit conditions).
3. Follow "Session start" in the agent-run skill exactly before any other work.

The verify gate is scripts/verify-agent.sh.
The milestone criteria are in docs/milestones.md (or open GitHub issues if
docs/milestones.md does not exist yet).
Current phase: A.
```

---

## Resuming an interrupted run

### Fresh repos

```
Resume run-01 on branch agent/run-01.

Read AGENTS.md in full.
Then follow §3.1 (session start steps):
  1. git pull --rebase
  2. Check active session marker in docs/agent/progress.md
  3. Check sessions.md for the previous session outcome
  4. Handle uncommitted changes or wip: commits
  5. Continue from the step in progress.md
```

### Existing repos

```
Resume run-01 on branch agent/run-01.

1. Read AGENTS.md.
2. Load .claude/skills/agent-run/SKILL.md.
3. Follow "Session start" in the agent-run skill:
   1. git pull --rebase
   2. Check active session marker in docs/agent/progress.md
   3. Check sessions.md for interruption
   4. Handle uncommitted changes or wip: commits
   5. Continue from the step in progress.md
```

If the previous session left a `wip:` commit, the agent continues on top of it until verify is green.

---

## Answering the agent's questions

The agent writes questions to `docs/agent/questions.md` when it hits an ambiguity or blocker. To answer:

1. Pull the run branch: `git pull origin agent/run-01`
2. Edit `docs/agent/questions.md` — add your answer under the question (format: `- Answer: <your answer>, <YYYY-MM-DD>`)
3. Change the status to `resolved` if appropriate, or leave as `open` if it needs follow-up
4. Commit and push: `git commit -m "questions: answer Q-001" && git push`

The agent reads `questions.md` at the start of every iteration and picks up your answer.

---

## Reviewing a milestone

At the end of each milestone, the agent opens a draft PR and records a self-review in `docs/agent/reviews.md`. As maintainer:

1. Pull the branch and read `docs/agent/reviews.md`.
2. Read the milestone's acceptance criteria in `docs/milestones.md`.
3. Run `bash scripts/verify.sh --through M<n>` yourself to confirm green.
4. Add any findings you spot (using the format in `reviews.md`). Mark them with `Made by: maintainer`.
5. Commit your findings to the run branch and push.
6. Resume the agent to fix Critical/Major findings.

When all findings are resolved, mark the PR ready: `gh pr ready`.

---

## Memory files reference

| File | What it holds | When to read it |
|---|---|---|
| `progress.md` | Current phase, milestone, next step, active session | Every iteration start |
| `lessons.md` | Confirmed failure patterns and fixes | Every iteration start |
| `questions.md` | Agent's questions and your answers | Every iteration start |
| `decisions.md` | Library and approach choices | Before choosing a library/approach |
| `codemap.md` | Where things live in the code | When entering an unfamiliar area |
| `runbook.md` | Build/test/run commands and gotchas | When an environment step fails |
| `sessions.md` | One row per session | At session start only |
| `reviews.md` | Milestone review findings | Before starting a milestone |

As maintainer, you can edit any of these files at any time. The agent treats your edits as authoritative and will never revert them.

---

## Exit conditions

The agent stops when one of these is true:

| Outcome | Meaning |
|---|---|
| **SUCCESS** | All milestones pass verify; no Critical/Major review finding open |
| **BUDGET** | A run limit was reached (max iterations, max time) |
| **STUCK** | A check still fails after 2 different approaches, or a Critical finding after 2 review rounds |
| **BLOCKED** | Continuing requires changing the design, a frozen test, or needs credentials you haven't provided |

On any exit, the agent writes `docs/agent/report.md` and opens (or updates) a pull request. Read the report to understand what happened and what the agent needs from you.

---

## Skills reference

| Skill | What it covers | When the agent loads it |
|---|---|---|
| `systematic-debugging` | Read before changing; diagnose cause not symptom; record lessons | Any check/test/build fails |
| `code-review` | Severity levels; independent reviewer; finding format | End of every milestone |
| `wksm-conventions` | Naming, TypeScript, money types, testing, env vars | Writing or structuring any code |

You can add project-specific skills by creating `.claude/skills/<name>/SKILL.md`. Reference them in the skills table in `AGENTS.md` §1.

---

## Adding a new skill

1. Create `.claude/skills/<skill-name>/SKILL.md` in the target repo.
2. Add a row to the skills table in `AGENTS.md` §1:
   ```
   | `skill-name` | When to use it |
   ```
3. Commit and push on the run branch.

The agent loads it on the next iteration when the condition matches.

---

## Troubleshooting

**The agent is not picking up my answer in questions.md.**
Make sure you pushed the commit. The agent runs `git pull --rebase` at the start of each iteration but only reads the pulled state.

**The agent keeps failing the same check.**
Read `docs/agent/progress.md` — under "Current focus" you will see what it is trying. Read `docs/agent/lessons.md` for whether this pattern is known. If it is STUCK, the report will say so; add guidance in `questions.md`.

**The agent is on the wrong branch.**
It will stop and report BLOCKED. Create the correct branch (`agent/run-<nn>`) from the last green commit, update `progress.md` to name it, commit, and push. Then resume.

**verify.sh is not finding the right commands.**
Edit `scripts/verify.sh` — fill in the `ADAPT:` sections. Run it yourself first. Commit and push on the run branch.
