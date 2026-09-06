#!/usr/bin/env bash
set -euo pipefail
D="$(dirname "$0")/../../skills/systematic-debugging"
fail=0
need() { grep -qF -- "$1" "$D/SKILL.md" || { echo "MISSING: $1"; fail=1; }; }
need 'name: systematic-debugging'
need 'description: Diagnosis loop for hard bugs and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow.'
need '## Phase 1: Build a feedback loop'
need '### Completion criterion: a tight loop that goes red'
need '## Phase 3: Hypothesise'
need '## Phase 6: Cleanup'
need '## If 3+ fixes failed: question the architecture'
need 'root-cause-tracing.md'
need 'superpowers:test-driven-development'
[ -f "$D/scripts/hitl-loop.template.sh" ] || { echo "MISSING: scripts/hitl-loop.template.sh"; fail=1; }
for f in root-cause-tracing.md defense-in-depth.md condition-based-waiting.md find-polluter.sh; do [ -f "$D/$f" ] || { echo "LOST: $f"; fail=1; }; done
[ "$fail" -eq 0 ] && echo "systematic-debugging: OK"
exit $fail
