# Skill: Code Review

Load this skill at the end of every milestone and when acting as the reviewer in the review gate.

## When to run

- At the end of every milestone, before declaring it complete.
- When `AGENTS.md` §3 says "run the review gate".
- When the maintainer requests a review.

The reviewer must be a **fresh agent session** with no memory of writing the code being reviewed. This independence is the whole point. If you wrote the code, you may not also review it; open a new session, instruct it to load this skill, and have it review the diff.

## Severity levels

| Severity | Definition | Must fix before |
|---|---|---|
| **Critical** | Correctness bug, data loss risk, security vulnerability, broken contract | Milestone close |
| **Major** | Logic error that would surface under real load, missing required behaviour, significant test gap | Milestone close |
| **Minor** | Non-idiomatic code, naming inconsistency, missing edge case handling | Next run |
| **Nitpick** | Style, formatting, comment clarity | Optional |

No Critical or Major finding may remain open when exiting with SUCCESS.

## Review procedure

### 1. Scope the review

```bash
git diff <milestone-start-commit>..HEAD -- ':!docs/agent/'
```

List the files changed. Record that list under "Scope" in your review entry in `reviews.md`.

### 2. Read the milestone criteria

Read the acceptance criteria for the milestone being reviewed in `docs/milestones.md`. The review checks whether the implementation satisfies them — not whether the code is pretty.

### 3. Review each changed file

For each file in scope:

1. Read the full file in its current state, not just the diff.
2. Check the diff for what changed.
3. Ask for each change:
   - Does it correctly implement the criterion it is meant to serve?
   - Are there edge cases the tests don't cover?
   - Does it introduce a security or data-integrity risk?
   - Does it break an API contract, event schema, or database invariant?
   - Does it follow the conventions in `codemap.md` and the `wksm-conventions` skill?

### 4. Record findings in `reviews.md`

Use this format:

```text
### Review: M<n> — <date>
Reviewer: <session description>
Scope: <list of files or "see diff">

#### Finding R-<nnn>: <short title>
- Severity: Critical | Major | Minor | Nitpick
- File: <path>:<line>
- Description: <what is wrong and why it matters>
- Suggested fix: <concrete — what to change, not just "fix this">
- Status: open | fixed in <commit> | accepted (reason)
```

### 5. Fix Critical and Major findings

The implementing agent (not the reviewer) fixes each finding:

1. Read the finding carefully. Fix exactly what it says.
2. Run `scripts/verify.sh --through <current milestone>` after each fix.
3. Update the finding's status in `reviews.md` to `fixed in <short commit hash>`.
4. If you disagree with a finding, raise it in `questions.md` rather than silently ignoring it.

After fixing, the reviewer re-checks only the fixed findings (not the full review again), and updates statuses.

## What not to do

- Do not review your own code.
- Do not mark a Critical finding as Minor to avoid fixing it.
- Do not record "looks fine" entries — record only actual findings.
- Do not suggest refactors that go beyond the milestone scope; file them as issues instead.
