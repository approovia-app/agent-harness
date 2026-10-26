#!/usr/bin/env bash
# scripts/verify-agent.sh — agent verify gate
#
# Usage:
#   bash scripts/verify-agent.sh                   # run all checks
#   bash scripts/verify-agent.sh --through M2      # gate on M0–M2; later milestones reported but non-gating
#   bash scripts/verify-agent.sh --full            # gate + mutation/coverage (if configured)
#
# Writes: verify-summary.json
#
# Exit 0 = all gating steps passed. Exit 1 = one or more gating steps failed.
#
# ── HOW TO ADAPT THIS SCRIPT ───────────────────────────────────────────────
# 1. Fill in each "ADAPT:" section with this repo's actual commands.
# 2. Add milestone acceptance-test commands under the milestone map below.
# 3. Run `bash scripts/verify-agent.sh` to confirm it works before starting a run.
# 4. Record the working commands in docs/agent/runbook.md.
# ───────────────────────────────────────────────────────────────────────────

set -euo pipefail

SUMMARY_FILE="verify-summary.json"
THROUGH_MILESTONE=""
FULL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --through)
            # Accept "M2", "m2" or "2"; reject anything else rather than gating wrongly.
            if [[ "${2:-}" =~ ^[Mm]?([0-9]+)$ ]]; then
                THROUGH_MILESTONE="M${BASH_REMATCH[1]}"; shift 2
            else
                echo "Invalid --through value: '${2:-}' (expected e.g. M2)"; exit 1
            fi ;;
        --full)    FULL=true; shift ;;
        *)         echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# ── Step tracking ───────────────────────────────────────────────────────────
PASS=true
STEP_JSON=""
MILESTONES_REGISTERED=0

# First 3 lines of $1 as a JSON string body: control chars become spaces,
# backslashes and quotes are escaped (in that order).
json_escape() {
    printf '%s' "$1" | head -3 | tr '\000-\037' ' ' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

step() {
    local name="$1"
    local status="$2"   # pass | fail | skip
    local detail="${3:-}"
    local entry="{\"name\":\"$(json_escape "$name")\",\"status\":\"$status\",\"detail\":\"$(json_escape "$detail")\"}"
    STEP_JSON="${STEP_JSON:+$STEP_JSON,}$entry"
    if [[ "$status" == "fail" ]]; then
        PASS=false
        echo "  FAIL  $name${detail:+ — $detail}"
    elif [[ "$status" == "skip" ]]; then
        echo "  skip  $name"
    else
        echo "  pass  $name"
    fi
}

run_step() {
    local name="$1"; shift
    local output
    if output=$("$@" 2>&1); then
        step "$name" "pass"
    else
        step "$name" "fail" "$output"
    fi
}

echo "=== verify $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="

# ── 1. Format ───────────────────────────────────────────────────────────────
# ADAPT: replace with this repo's format check command.
# Examples:
#   npm run format:check
#   npx prettier --check "src/**/*.ts"
echo "— format"
if npm run format:check --silent 2>/dev/null; then
    step "format" "pass"
else
    step "format" "fail" "run: npm run format"
fi

# ── 2. Lint ─────────────────────────────────────────────────────────────────
# ADAPT: replace with this repo's lint command.
echo "— lint"
run_step "lint" npm run lint --silent

# ── 3. Type check ───────────────────────────────────────────────────────────
# ADAPT: replace with this repo's type check command.
# Examples:
#   npm run typecheck
#   npx tsc --noEmit
echo "— typecheck"
run_step "typecheck" npm run typecheck --silent

# ── 4. Unit tests ───────────────────────────────────────────────────────────
# ADAPT: replace with this repo's unit test command.
echo "— unit-tests"
run_step "unit-tests" npm test --silent

# ── 5. Acceptance tests ─────────────────────────────────────────────────────
# ADAPT: add one block per milestone. The --through flag gates earlier milestones;
# later ones run but their failure does not set PASS=false.
#
# milestone_number <n> <command...>
milestone_number() {
    local n="$1"; shift
    local gate=true
    MILESTONES_REGISTERED=$((MILESTONES_REGISTERED + 1))
    if [[ -n "$THROUGH_MILESTONE" ]]; then
        local through_n="${THROUGH_MILESTONE#M}"
        [[ "$n" -gt "$through_n" ]] && gate=false
    fi
    local output
    if output=$("$@" 2>&1); then
        step "acceptance-M${n}" "pass"
    else
        if $gate; then
            step "acceptance-M${n}" "fail" "$output"
        else
            step "acceptance-M${n}" "skip" "not yet gating"
        fi
    fi
}

echo "— acceptance tests"
# ADAPT: add milestone acceptance test commands here.
# Example:
#   milestone_number 1 npm run test:acceptance -- --grep "m1_"
#   milestone_number 2 npm run test:acceptance -- --grep "m2_"

# ── 6. Full mode: coverage / mutation ───────────────────────────────────────
if $FULL; then
    # --full is the SUCCESS gate; it must never pass without acceptance tests.
    if [[ "$MILESTONES_REGISTERED" -eq 0 ]]; then
        step "acceptance-registered" "fail" "no milestone_number lines in scripts/verify-agent.sh"
    fi

    echo "— coverage"
    # ADAPT: replace with this repo's coverage command.
    # Example:
    #   run_step "coverage" npm run test:coverage
    step "coverage" "skip" "not configured — fill in scripts/verify-agent.sh"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
if $PASS; then
    OVERALL="pass"
    echo "=== PASS ==="
else
    OVERALL="fail"
    echo "=== FAIL ==="
fi

cat > "$SUMMARY_FILE" <<EOF
{
  "overall": "$OVERALL",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "through": "${THROUGH_MILESTONE:-all}",
  "steps": [$STEP_JSON]
}
EOF

echo "Summary written to $SUMMARY_FILE"
$PASS
