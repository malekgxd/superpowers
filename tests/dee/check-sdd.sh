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
fi

[ "$fail" -eq 0 ] && echo "sdd: OK"
exit $fail
