# Skill: Systematic Debugging

Load this skill whenever any check, test, build, or environment step fails, **before making any change in response**.

## The rule

Read before you write. Every change made without first reading the failure output is a guess. Guesses compound into broken states that are hard to exit.

## Steps

### 1. Read the full failure output

Do not skim. Read the complete error message, including:
- The exact file path and line number.
- The full error or assertion text.
- Any preceding context the tool printed.
- The stack trace if one is present.

If the output is long, write the decisive lines verbatim under "Current focus" in `progress.md` before doing anything else.

### 2. Identify the cause, not just the location

The failing line is the symptom. Ask:
- Why does this line fail? What invariant or assumption does it violate?
- Was it always broken, or did a recent change introduce it? (`git diff HEAD~1` is faster than `git log`.)
- Is this the only place this pattern appears, or does the same root cause affect other files?

### 3. Verify your diagnosis before fixing

State your diagnosis explicitly under "Current focus" in `progress.md`. If the diagnosis is uncertain, find the smallest change that would confirm or refute it — a `console.log`, a single assertion, running only the failing test — before touching production code.

### 4. Fix the cause

- Change only what the diagnosis says to change.
- If the fix touches more than three files, ask whether the root cause is actually elsewhere.
- Do not add workarounds (try/catch, `// @ts-ignore`, conditional checks) unless the underlying cause is outside this codebase and the workaround is documented in `decisions.md`.

### 5. Verify the fix

Run the failing check again in isolation before running the full `scripts/verify.sh`. A fast feedback loop catches regressions immediately.

### 6. If the same check fails three iterations in a row

Stop. Do not try a fourth variation on the same approach.

1. Write the failure pattern verbatim under "Current focus" in `progress.md`.
2. Write your next idea there too.
3. Check `lessons.md` — has this pattern been seen before?
4. If you have exhausted 2 different approaches and the check still fails, this is STUCK (§6 of AGENTS.md).

### 7. Record confirmed lessons

Once a non-obvious failure is fixed and `scripts/verify.sh` is green, record the pattern and fix in `lessons.md`:

```text
### L-<nnn>: <short title>
- Symptom: <exact error text or check name>
- Cause: <one sentence>
- Fix: <what to do — file, command, or pattern>
- Confirmed: <date>
```

Do not record obvious fixes ("forgot to import X"). Record patterns that would surprise a reader who knows this codebase well.

## What not to do

- Do not make multiple changes at once to "try things".
- Do not delete tests or weaken assertions to make a check pass.
- Do not change the verify script or lint configuration to suppress the failure.
- Do not assume a package API without reading its documentation for the resolved version.
