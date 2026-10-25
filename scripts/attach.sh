#!/usr/bin/env bash
# scripts/attach.sh — overlay the agent harness onto an existing repository
#
# Usage:
#   bash scripts/attach.sh <target-repo-path> [repo-name]
#
# What it does:
#   - Copies AGENTS.md, .claude/, docs/agent/, and scripts/verify.sh
#     into the target repo without overwriting any existing files.
#   - Substitutes {{Repo Name}} with the provided repo name in AGENTS.md.
#   - Prints a checklist of next steps.
#
# What it does NOT do:
#   - Overwrite any existing file in the target repo.
#   - Modify any existing file in the target repo.
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

echo ""
echo "Attaching agent harness to: $TARGET"
echo "Repo name: $REPO_NAME"
echo ""

added=0
skipped=0

copy_file() {
    local src="$1"
    local dst="$2"
    if [[ -e "$dst" ]]; then
        echo "  skip  (exists) $dst"
        ((skipped++)) || true
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "  add   $dst"
        ((added++)) || true
    fi
}

copy_dir() {
    local src="$1"
    local dst="$2"
    while IFS= read -r -d '' file; do
        rel="${file#$src/}"
        copy_file "$file" "$dst/$rel"
    done < <(find "$src" -type f -print0)
}

# AGENTS.md — substitute repo name placeholder
echo "— AGENTS.md"
dst="$TARGET/AGENTS.md"
if [[ -e "$dst" ]]; then
    echo "  skip  (exists) $dst"
    ((skipped++)) || true
else
    sed "s/{{Repo Name}}/$REPO_NAME/g" "$HARNESS_DIR/AGENTS.md" > "$dst"
    echo "  add   $dst"
    ((added++)) || true
fi

# .claude/
echo "— .claude/"
copy_file "$HARNESS_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
for skill_dir in "$HARNESS_DIR/.claude/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    copy_file "$skill_dir/SKILL.md" "$TARGET/.claude/skills/$skill_name/SKILL.md"
done

# docs/agent/
echo "— docs/agent/"
for f in "$HARNESS_DIR/docs/agent/"*.md; do
    fname="$(basename "$f")"
    copy_file "$f" "$TARGET/docs/agent/$fname"
done

# scripts/verify.sh
echo "— scripts/verify.sh"
copy_file "$HARNESS_DIR/scripts/verify.sh" "$TARGET/scripts/verify.sh"
chmod +x "$TARGET/scripts/verify.sh" 2>/dev/null || true

echo ""
echo "Done. Added $added file(s), skipped $skipped existing file(s)."
echo ""
echo "═══════════════════════════════════════════════════════════"
echo " NEXT STEPS — complete these before starting an agent run  "
echo "═══════════════════════════════════════════════════════════"
echo ""
echo " 1. Write docs/design.md — what the service must do."
echo "    (If requirements are in GitHub issues, summarise them here.)"
echo ""
echo " 2. Write docs/milestones.md — milestones with acceptance criteria."
echo "    Each criterion needs an ID like M1-AC01."
echo "    See the format in the harness README."
echo ""
echo " 3. Adapt scripts/verify.sh — fill in the ADAPT: sections"
echo "    with this repo's actual lint / typecheck / test commands."
echo "    Run: bash scripts/verify.sh"
echo "    When it passes, record the commands in docs/agent/runbook.md."
echo ""
echo " 4. Update docs/agent/decisions.md — fill in D-003 (decimal library)"
echo "    and any other baseline decisions for this service."
echo ""
echo " 5. Create the run branch:"
echo "    git checkout -b agent/run-01"
echo "    git add docs/ .claude/ AGENTS.md scripts/verify.sh"
echo "    git commit -m 'harness: attach agent harness'"
echo "    git push -u origin agent/run-01"
echo ""
echo " 6. Start the agent (see README.md — 'Starting a run')."
echo ""
