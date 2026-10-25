# Decisions

Implementation choices made during agent runs: libraries, approaches, and conventions not fixed by the design. Recording them stops a later session from silently reversing an earlier choice.

**Rules**

- Append-only. To change a decision, add a new entry that supersedes the old one; never edit or delete an old entry.
- Check this file before choosing a library or an approach.
- Design-level decisions belong in `docs/design.md`, which agents never edit.
- Size cap: none, but keep each entry to a few lines.

## Format

```text
### D-<nnn>: <short title>
- Date: <YYYY-MM-DD>
- Milestone: <Mn>
- Decision: what was chosen
- Reason: why, in one or two lines
- Alternatives: what else was considered
- Supersedes: D-<nnn>, if any
```

**Maintainer decisions** are marked `Made by: maintainer`. They are binding: an agent never supersedes them. If one seems wrong, raise it in `questions.md`.

## Baseline decisions

### D-001: No AI attribution in commits or PRs
- Date: (set at repo creation)
- Made by: maintainer
- Decision: No `Co-Authored-By` trailers naming an AI tool, no "Generated with" lines anywhere.
- Reason: Keeps authorship clean; enforced by `.claude/settings.json`.

### D-002: autoMemoryEnabled = false
- Date: (set at repo creation)
- Made by: maintainer
- Decision: Claude Code's cross-session memory is disabled. All persistent state lives in `docs/agent/`.
- Reason: The repository is the only memory. Tool-specific memory is invisible to other tools and to the maintainer.

### D-003: Decimal type for money and quantities
- Date: (fill in when first chosen)
- Made by: maintainer
- Decision: (fill in the chosen library — e.g. `decimal.js`, `big.js`)
- Reason: Floating-point is unsuitable for financial calculations.
- Alternatives: native `number` (rejected).

<!-- Add service-specific baseline decisions here before attaching to a repo -->
