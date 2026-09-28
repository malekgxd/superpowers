#!/usr/bin/env bash
# SDD fork edits: reviewer findings land in a file, and a finished workspace is archived, not deleted.
set -euo pipefail
D="$(cd "$(dirname "$0")/../../skills/subagent-driven-development" && pwd)"
fail=0
ok() { echo "OK   $1"; }
bad() { echo "FAIL $1"; fail=1; }

grep -qF -- '[REVIEW_FILE]' "$D/task-reviewer-prompt.md" && grep -qF -- 'Write your full report to [REVIEW_FILE]' "$D/task-reviewer-prompt.md" \
  && ok "task reviewer writes its report to [REVIEW_FILE]" || bad "task reviewer lacks [REVIEW_FILE] contract"
grep -qF -- '[REVIEW_FILE]' "$D/re-review-prompt.md" && grep -qF -- '## Re-review round [ROUND]' "$D/re-review-prompt.md" \
  && ok "re-reviewer appends a round heading to [REVIEW_FILE]" || bad "re-reviewer lacks [REVIEW_FILE] append contract"
grep -qF -- 'final message is the report itself' "$D/task-reviewer-prompt.md" && bad "task reviewer still told to reply with the whole report" || ok "old reply-is-the-report line is gone"
grep -qF -- 'task-N-review.md' "$D/SKILL.md" && ok "SKILL names the review file" || bad "SKILL never names task-N-review.md"
grep -qF -- 'final-review.md' "$D/SKILL.md" && ok "SKILL names final-review.md" || bad "SKILL never names final-review.md"
grep -qF -- 'review-file path' "$D/SKILL.md" && ok "fix dispatches carry the review file" || bad "fix dispatches omit the review file"
grep -qF -- 'rm -rf <workspace>' "$D/SKILL.md" && bad "SKILL still deletes the workspace" || ok "SKILL no longer deletes the workspace"
grep -qF -- 'scripts/sdd-archive' "$D/SKILL.md" && ok "SKILL finishes with sdd-archive" || bad "SKILL never calls sdd-archive"
grep -qF -- 'delete this plan' "$D/SKILL.md" && bad "SKILL still says delete this plan" || ok "process flow says archive"
[ -x "$D/scripts/sdd-archive" ] && ok "sdd-archive is executable" || bad "scripts/sdd-archive missing or not executable"
grep -qF -- '"${BASH:-bash}" "$here/sdd-workspace"' "$D/scripts/sdd-archive" && ok "sdd-archive calls sdd-workspace via bash" || bad "sdd-archive execs sdd-workspace directly"
grep -qE -- '(^|[^/])scripts/sdd-archive' "$D/SKILL.md" && ! grep -qE -- '(^|[^h] )`?scripts/sdd-archive' "$D/SKILL.md" && ok "SKILL calls sdd-archive via bash" || bad "SKILL calls sdd-archive without bash"

# Fixture: a throwaway repo with one plan, one workspace holding a ledger.
if [ -x "$D/scripts/sdd-archive" ]; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  (cd "$T" && git init -q && mkdir -p docs && echo "# plan" > docs/feature-plan.md)
  ws=$(cd "$T" && "$D/scripts/sdd-workspace" docs/feature-plan.md)
  printf '# SDD ledger — plan: docs/feature-plan.md\nTask 1: complete (no commits, review clean)\n' > "$ws/progress.md"
  echo "findings" > "$ws/task-1-review.md"
  dest=$(cd "$T" && "$D/scripts/sdd-archive" docs/feature-plan.md)
  case "$dest" in "$T/.superpowers/sdd/_archive/feature-plan-"*) ok "archive path is _archive/<plan>-<stamp>";; *) bad "unexpected archive path: $dest";; esac
  [ -f "$dest/progress.md" ] && [ -f "$dest/task-1-review.md" ] && ok "ledger and review moved into the archive" || bad "archive is missing the ledger or review"
  [ ! -e "$ws" ] && ok "original workspace is gone" || bad "original workspace still exists"
  (cd "$T" && "$D/scripts/sdd-archive" docs/feature-plan.md >/dev/null 2>&1) && bad "archiving an empty workspace should fail" || ok "empty workspace refused"
  [ ! -e "$ws" ] && ok "refusal leaves no empty workspace behind" || bad "refusal left an empty workspace"
  (cd "$T" && git status --porcelain | grep -q superpowers) && bad "archive leaks into git status" || ok "archive stays git-ignored"
  ws=$(cd "$T" && "$D/scripts/sdd-workspace" docs/feature-plan.md); echo '# SDD ledger — plan: docs/feature-plan.md' > "$ws/progress.md"
  dest2=$(cd "$T" && "$D/scripts/sdd-archive" docs/feature-plan.md)
  [ "$dest2" != "$dest" ] && [ -f "$dest2/progress.md" ] && [ -f "$dest/progress.md" ] && ok "second archive in the same minute keeps both" || bad "same-minute archive collided"
  ws=$(cd "$T" && "$D/scripts/sdd-workspace" docs/feature-plan.md); echo brief > "$ws/task-1-brief.md"
  rc=0; (cd "$T" && "$D/scripts/sdd-archive" docs/feature-plan.md >/dev/null 2>&1) || rc=$?
  [ "$rc" -eq 2 ] && [ -f "$ws/plan-path" ] && [ -f "$ws/task-1-brief.md" ] && ok "ledgerless nonempty workspace kept with its marker" || bad "ledgerless nonempty workspace: rc=$rc, marker or brief removed"
fi

# Collision: once alpha's `plan` workspace is archived, beta must still resolve to its own `plan-beta`.
if [ -x "$D/scripts/sdd-archive" ]; then
  C=$(mktemp -d); trap 'rm -rf "${T:-}" "$C"' EXIT
  (cd "$C" && git init -q && mkdir -p docs/alpha docs/beta && echo "# a" > docs/alpha/plan.md && echo "# b" > docs/beta/plan.md)
  wa=$(cd "$C" && "$D/scripts/sdd-workspace" docs/alpha/plan.md)
  wb=$(cd "$C" && "$D/scripts/sdd-workspace" docs/beta/plan.md)
  [ "$wa" = "$C/.superpowers/sdd/plan" ] && [ "$wb" = "$C/.superpowers/sdd/plan-beta" ] && ok "same-name plans get plan and plan-beta" || bad "collision slugs: $wa $wb"
  echo '# SDD ledger — plan: docs/beta/plan.md' > "$wb/progress.md"
  echo '# SDD ledger — plan: docs/alpha/plan.md' > "$wa/progress.md"
  (cd "$C" && "$D/scripts/sdd-archive" docs/alpha/plan.md >/dev/null)
  wb2=$(cd "$C" && "$D/scripts/sdd-workspace" docs/beta/plan.md)
  [ "$wb2" = "$wb" ] && [ -f "$wb2/progress.md" ] && ok "beta keeps its owned workspace after alpha is archived" || bad "beta re-resolved to $wb2 (owned: $wb)"
  db=$(cd "$C" && "$D/scripts/sdd-archive" docs/beta/plan.md 2>/dev/null || true)
  [ -n "$db" ] && [ -f "$db/progress.md" ] && grep -q 'docs/beta/plan.md' "$db/progress.md" && [ ! -e "$wb" ] && ok "archiving beta moves beta's ledger" || bad "archiving beta did not move its ledger (dest=$db)"
fi

E="$(cd "$D/../executing-plans" && pwd)/SKILL.md"
grep -qiF -- "delete this plan's workspace" "$E" && bad "executing-plans still deletes the workspace" || ok "executing-plans archives the workspace"
grep -qF -- 'sdd-archive PLAN_FILE' "$E" && ok "executing-plans finishes with sdd-archive" || bad "executing-plans never calls sdd-archive"
grep -qF -- 'Declined to judge' "$D/SKILL.md" && ok "SDD final review returns Declined-to-judge lines" || bad "SDD final review drops Declined-to-judge lines"

[ "$fail" -eq 0 ] && echo "sdd: OK"
exit $fail
