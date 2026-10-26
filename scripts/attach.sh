#!/usr/bin/env bash
# scripts/attach.sh — overlay the agent harness onto an existing repository
#
# Usage:
#   bash scripts/attach.sh <target-repo-path> [repo-name]
#
# Modes (auto-detected):
#   FRESH  — no AGENTS.md in target yet: copies the full harness including AGENTS.md
#   EXISTING — AGENTS.md already exists: adds only docs/agent/, the agent-run skill,
#              systematic-debugging, code-review, and scripts/verify-agent.sh.
#              Never overwrites AGENTS.md, .claude/settings.json, or existing skills.
#
# What it never does:
#   - Overwrite any existing file in the target repo. (It only appends
#     `verify-summary.json` to .gitignore if that line is missing.)
#   - Commit or push anything.

set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    echo "Usage: bash scripts/attach.sh <target-repo-path> [repo-name]"
    exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

if [[ ! -d "$TARGET/.git" ]]; then
    echo "Error: $TARGET is not a git repository."
    exit 1
fi

REPO_NAME="${2:-$(basename "$TARGET")}"
HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd)"

added=0
skipped=0

copy_file() {
    local src="$1"
    local dst="$2"
    if [[ -e "$dst" ]]; then
        echo "  skip  (exists) ${dst#$TARGET/}"
        ((skipped++)) || true
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "  add   ${dst#$TARGET/}"
        ((added++)) || true
    fi
}

# ── Detect mode ──────────────────────────────────────────────────────────────
EXISTING_REPO=false
if [[ -f "$TARGET/AGENTS.md" ]]; then
    EXISTING_REPO=true
fi

echo ""
echo "Target:    $TARGET"
echo "Repo name: $REPO_NAME"
if $EXISTING_REPO; then
    echo "Mode:      EXISTING (AGENTS.md found — adding harness layer only)"
else
    echo "Mode:      FRESH (no AGENTS.md — attaching full harness)"
fi
echo ""

# ── Always: docs/agent/ memory files ─────────────────────────────────────────
echo "— docs/agent/ (memory files)"
for f in "$HARNESS_DIR/docs/agent/"*.md; do
    fname="$(basename "$f")"
    copy_file "$f" "$TARGET/docs/agent/$fname"
done

# ── Always: agent-run skill ──────────────────────────────────────────────────
echo "— .claude/skills/agent-run/"
copy_file "$HARNESS_DIR/.claude/skills/agent-run/SKILL.md" \
          "$TARGET/.claude/skills/agent-run/SKILL.md"

# ── Always: systematic-debugging and code-review skills ──────────────────────
echo "— .claude/skills/systematic-debugging/"
copy_file "$HARNESS_DIR/.claude/skills/systematic-debugging/SKILL.md" \
          "$TARGET/.claude/skills/systematic-debugging/SKILL.md"

echo "— .claude/skills/code-review/"
copy_file "$HARNESS_DIR/.claude/skills/code-review/SKILL.md" \
          "$TARGET/.claude/skills/code-review/SKILL.md"

# ── Always: verify-agent.sh (named to avoid conflict with existing verify.sh) ─
VERIFY_DST="$TARGET/scripts/verify-agent.sh"
echo "— scripts/verify-agent.sh"
copy_file "$HARNESS_DIR/scripts/verify-agent.sh" "$VERIFY_DST"
chmod +x "$VERIFY_DST" 2>/dev/null || true

# ── Always: keep verify output out of commits ────────────────────────────────
# The only change ever made to an existing file: one line appended, once.
echo "— .gitignore"
if grep -qxF 'verify-summary.json' "$TARGET/.gitignore" 2>/dev/null; then
    echo "  skip  (present) verify-summary.json in .gitignore"
else
    # Don't glue onto a last line that lacks a trailing newline
    if [[ -s "$TARGET/.gitignore" && -n "$(tail -c1 "$TARGET/.gitignore")" ]]; then
        echo >> "$TARGET/.gitignore"
    fi
    echo 'verify-summary.json' >> "$TARGET/.gitignore"
    echo "  add   verify-summary.json to .gitignore"
fi

# ── Fresh repos only: AGENTS.md + settings.json + wksm-conventions ───────────
if ! $EXISTING_REPO; then
    echo "— AGENTS.md"
    dst="$TARGET/AGENTS.md"
    if [[ -e "$dst" ]]; then
        echo "  skip  (exists) AGENTS.md"
        ((skipped++)) || true
    else
        # Escape sed replacement metacharacters so names like "A/B & C" survive
        repo_name_esc="$(printf '%s' "$REPO_NAME" | sed 's/[\/&\\]/\\&/g')"
        sed "s/{{Repo Name}}/$repo_name_esc/g" "$HARNESS_DIR/AGENTS.md" > "$dst"
        echo "  add   AGENTS.md"
        ((added++)) || true
    fi

    echo "— .claude/settings.json"
    copy_file "$HARNESS_DIR/.claude/settings.json" \
              "$TARGET/.claude/settings.json"

    echo "— .claude/skills/wksm-conventions/"
    copy_file "$HARNESS_DIR/.claude/skills/wksm-conventions/SKILL.md" \
              "$TARGET/.claude/skills/wksm-conventions/SKILL.md"
fi

echo ""
echo "Done. Added $added file(s), skipped $skipped existing file(s)."
echo ""

# ── Next-steps checklist ──────────────────────────────────────────────────────
if $EXISTING_REPO; then
cat <<'CHECKLIST'
═══════════════════════════════════════════════════════════════
 EXISTING REPO — harness layer added
═══════════════════════════════════════════════════════════════

What was added (skipped if it already existed):
  docs/agent/            — 8 memory files for cross-session state
  .claude/skills/agent-run/     — run loop, phases, exit conditions
  .claude/skills/systematic-debugging/
  .claude/skills/code-review/
  scripts/verify-agent.sh       — verify gate (adapt ADAPT: sections)

What was NOT touched:
  AGENTS.md              — already exists; team rules preserved
  .claude/settings.json  — generated from handbook; not modified
  All existing skills    — preserved

NEXT STEPS:

 1. Adapt scripts/verify-agent.sh — fill in the ADAPT: sections
    with this repo's actual commands.
    Backend (.NET):   dotnet test -c Release
    Frontend (npm):   npm run typecheck && npm test
    Run it yourself: bash scripts/verify-agent.sh
    Record working commands in docs/agent/runbook.md.

 2. [Optional] Disable cross-session memory for agent runs.
    The generated .claude/settings.json cannot be modified, but
    you can create a gitignored local override:
      echo '{"autoMemoryEnabled": false}' > .claude/settings.local.json
      echo '.claude/settings.local.json' >> .gitignore
    Or raise it as a proposal for handbook/standards/claude-settings.yaml
    so it propagates to all repos.

 3. When starting an agent run, tell it to load the agent-run skill:
    "Load .claude/skills/agent-run/SKILL.md before doing anything else.
     Then follow §Session start exactly."

 4. Create the run branch:
    git checkout -b agent/run-01
    git add docs/agent/ .claude/skills/agent-run/ \
            .claude/skills/systematic-debugging/ \
            .claude/skills/code-review/ \
            scripts/verify-agent.sh .gitignore
    git commit -m "harness: add agent run layer"
    git push -u origin agent/run-01

 5. See README.md — "Starting a run" for the exact start and resume prompts.

CHECKLIST
else
cat <<'CHECKLIST'
═══════════════════════════════════════════════════════════════
 FRESH REPO — full harness attached
═══════════════════════════════════════════════════════════════

 1. Write docs/design.md — what the service must do.

 2. Write docs/milestones.md — milestones with acceptance criteria.
    Each criterion needs an ID like M1-AC01.

 3. Adapt scripts/verify-agent.sh — fill in the ADAPT: sections
    with this repo's actual commands.
    Run: bash scripts/verify-agent.sh
    Record working commands in docs/agent/runbook.md.

 4. Update docs/agent/decisions.md — fill in D-003 (decimal library)
    and other baseline decisions.

 5. Create the run branch:
    git checkout -b agent/run-01
    git add docs/ .claude/ AGENTS.md scripts/verify-agent.sh .gitignore
    git commit -m "harness: attach agent harness"
    git push -u origin agent/run-01

 6. See README.md — "Starting a run" for the start and resume prompts.

CHECKLIST
fi
