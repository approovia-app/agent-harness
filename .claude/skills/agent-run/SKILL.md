# Skill: Agent Run

Load this skill at the start of any structured multi-milestone agent run. It adds the run management layer on top of this repo's existing `AGENTS.md` rules. Everything in `AGENTS.md` (never rules, PR workflow, branch rules, secrets handling) still applies — this skill only adds the phases, memory system, work loop, and exit conditions that `AGENTS.md` doesn't cover.

## Sources of truth

1. `docs/design.md` — what must be built. Highest authority. If it doesn't exist, open `docs/milestones.md` and the GitHub issues list instead.
2. `docs/milestones.md` — acceptance criteria per milestone.
3. Open GitHub issues: `gh issue list --state open`. Classify at run start (see §7).

If the design and milestones disagree, the design wins. Record the disagreement in `docs/agent/questions.md`.

## Memory system

The repository is the only cross-session memory. Keep these files in `docs/agent/` accurate and in their own lane.

| File | Holds | Update | Read |
|---|---|---|---|
| `progress.md` | Phase, milestone, next step, current focus, active session | Overwrite; cap ~80 lines | Every iteration |
| `lessons.md` | Confirmed failure patterns and fixes | Curated add/merge/remove; cap ~60 entries | Every iteration |
| `questions.md` | Blockers, ambiguities, your questions and maintainer answers | Add questions; mark resolved on answer | Every iteration start + before entering a questioned area |
| `decisions.md` | Library and approach choices with reasons | Append-only; supersede, never edit | Before choosing a library or approach |
| `codemap.md` | Where things live in the code | Overwrite on structure change; cap ~150 lines | When entering an unfamiliar area |
| `runbook.md` | Build/test/run commands and gotchas | Update when something changes; cap ~150 lines | When an environment step fails |
| `sessions.md` | One row per session, including interrupted ones | Append only | At session start, to check for interruption |
| `reviews.md` | Milestone review findings and resolution | Reviewers append; you update status + commit only | Before starting a milestone; when fixing findings |

**Memory rules:**
1. The repo is the only memory. Do not rely on the tool's own cross-session memory.
2. One fact, one place — point to it, don't copy it.
3. Current-state files (`progress.md`, `codemap.md`, `runbook.md`): overwrite.
4. History files (`decisions.md`, `sessions.md`, `reviews.md`): append only.
5. `lessons.md`: curated — add, merge, remove. No entry over ~5 lines.
6. Write for a stranger: file paths, commands, criterion IDs, exact error text. "Be careful with migrations" is not a lesson.
7. Record only confirmed facts. Unconfirmed ideas go under "Current focus" in `progress.md`.
8. Update memory with the work — same commit.
9. Memory never redefines requirements. If memory conflicts with design/milestones, design wins. Record the conflict in `questions.md`.
10. Maintainer edits to memory files are authoritative. Never revert them.

## Session start (do this every time, before any other work)

1. Confirm you are on the run branch in `progress.md`, then `git pull --rebase`.
2. Check "Active session" in `progress.md`:
   - Filled in and under 2 hours old → another session may be running: stop (BLOCKED).
   - Filled in and older → previous session was interrupted: take over, note the takeover in `sessions.md`.
   - Empty → fill it in now with tool, host, start time. Commit and push (`checkpoint: session start`).
3. Check `sessions.md` — if the last row doesn't match the previous session, append an *interrupted* row for it.
4. If there are uncommitted changes or a `wip:` commit:
   - Run `scripts/verify-agent.sh --through <current milestone>`.
   - If green and the changes match "Current focus" in `progress.md`, commit and push them.
   - If not, `git stash push -m "interrupted <date>: <step>"`, reset to the last green commit, note the stash in `progress.md`.
   - A `wip:` commit is already published — never reset it away. Continue on top of it until verify is green.
5. If `reviews.md` has an unfinished review round, resume it before any other work.
6. Continue from "Next step" in `progress.md`.

## Phases

`progress.md` states the current phase.

**Phase A — foundation and acceptance tests**
- Confirm `scripts/verify-agent.sh` is green for M0.
- Write acceptance tests in `tests/acceptance/` for every criterion of every later milestone. Black-box only: call the API, read events, query the database directly — never import internal modules. Tests are expected to fail until phase B.
- Open a draft PR and stop when done. A maintainer reviews the tests.

**Phase B — build**
- Implement milestones after M0 in order.
- Start a milestone only when `scripts/verify-agent.sh --through <previous milestone>` is green.

## Work loop

Repeat until an exit condition (below) is met:

1. **Orient.** Re-read `progress.md`, `lessons.md`, `questions.md`. Pick the smallest next step toward the current milestone's failing criteria.
2. **Write intent first.** Under "Current focus" in `progress.md`, write what you are about to do and which criterion it serves. Commit (`checkpoint: <step>`) and push before starting.
3. **Implement** that step only.
4. **Verify.** Run `scripts/verify-agent.sh --through <current milestone>` and read `verify-summary.json`.
5. **If it fails:** load the `systematic-debugging` skill. Fix the cause, not the symptom. If the same check fails 3 iterations in a row, record the pattern in `progress.md` before trying again.
6. **If it passes:** commit with a message like `M3: enforce lifecycle rules (M3-AC07)`. Update `progress.md` and `codemap.md` if structure changed. Push.
7. **End of milestone:** run `scripts/verify-agent.sh --full`. Load the `code-review` skill; a fresh independent session reviews the milestone's changes and records findings in `reviews.md`. Fix every Critical finding with verify green after each. Record the next milestone's start commit, tag `run-<nn>/M<n>`, move on.

Commit code only on green verify. Memory-only commits (`docs/agent/`) may be made any time.

## Rules specific to agent runs

**Push behaviour**
- Push every green commit immediately.
- `git pull --rebase` before every push.
- If rebase conflicts or the remote shows another session's checkpoint commits: stop (BLOCKED).

**Tagging**
After the review gate, tag: `git tag run-<nn>/M<n> && git push origin run-<nn>/M<n>`.

**Pull requests**
- Open as draft: `gh pr create --draft`. Mark ready only on SUCCESS.
- Use the existing `/pr` skill for the PR itself — this skill does not override the repo's PR workflow.

**Ambiguity**
If the design is ambiguous on something that doesn't change an invariant or public contract, use the most conservative interpretation, record it in `questions.md`, and continue. If it does change an invariant or public contract, stop (BLOCKED).

## Run limits (defaults; maintainer may override in `progress.md`)

| Limit | Default |
|---|---|
| Maximum iterations | 300 |
| Maximum wall-clock time | 48 hours |
| Consecutive failing iterations before trying a different approach | 6 |
| Different approaches before declaring STUCK | 2 |

## Exit conditions

| Outcome | Condition |
|---|---|
| **SUCCESS** | `scripts/verify-agent.sh --full` green; no Critical/Major review finding open; no protected file changed |
| **BUDGET** | A run limit reached |
| **STUCK** | Check still fails after 2 different approaches; or Critical finding open after 2 review rounds |
| **BLOCKED** | Continuing requires changing the design, a frozen test, an invariant, or needs credentials/access not provided |

## On exit (all outcomes)

1. Write `docs/agent/report.md`:
   - Outcome
   - Milestone status table
   - Latest verify summary
   - Open questions
   - Significant decisions
   - What you tried for failing checks
   - What you need from a maintainer
2. Update all memory files. Clear "Active session" in `progress.md`. Append the session row in `sessions.md`.
3. Commit and push. If outcome is not SUCCESS, put unverified changes in a `wip:` commit. Open or update the draft PR.

## Issue classification (at every run start)

Run `gh issue list --state open`. Sort each issue into one of:

1. **Resolvable** — design + criteria already say what to build. Do it; add `Closes #N` to the PR body.
2. **Needs maintainer** — behaviour or contract undecided. Raise in `questions.md` with an interim choice.
3. **Needs owner or outside facts** — business/legal/scope decision. Name who or what it waits on.

Nothing is left as "needs design" without an entry in `questions.md`.
