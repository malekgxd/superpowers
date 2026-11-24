#!/usr/bin/env bash
# SDD fork edits: one builder per task, no per-task review, and a finished workspace is archived, not deleted.
set -euo pipefail
D="$(cd "${SDD_SKILL_DIR:-$(dirname "$0")/../../skills/subagent-driven-development}" && pwd)"
# Upstream 7.0.1 moved the final review into references/: check the skill text as a whole.
SK=$(cat "$D/SKILL.md" "$D"/references/*.md)
fail=0
ok() { echo "OK   $1"; }
bad() { echo "FAIL $1"; fail=1; }

for s in 'form a wave and are dispatched together in one message, as foreground calls' \
  'A task with no `Depends on` line depends on the task before it' \
  'Builders run no git command that writes' \
  'git commit --only --' \
  'A changed path that belongs to no task in the wave stops the wave' \
  'Task <N>: complete (commit <sha7>, tests <summary>)' \
  'one such task at a time' \
  'Start: <sha>' 'Task <N> (<plan-basename>):'; do
  grep -qF -- "$s" "$D/SKILL.md" && ok "SKILL.md has: $s" || bad "SKILL.md lacks: $s"
done
for s in 'Never dispatch multiple implementation subagents in parallel' 'review-package' 'task-reviewer' 'fix-loop' 'Fix-loop escalation' 're-review-prompt'; do
  grep -qF -- "$s" <<<"$SK" && bad "skill text still says: $s" || ok "skill text is free of: $s"
done
for s in 'superpowers:requesting-code-review' 'superpowers:receiving-code-review' 'superpowers:verification-before-completion' 'bash scripts/sdd-archive' 'Rulings I made'; do
  grep -qF -- "$s" "$D/references/final-review.md" && ok "final-review.md has: $s" || bad "final-review.md lacks: $s"
done
for s in 'Run no git command that writes' 'the orchestrator commits' 'run only the tests your brief names'; do
  grep -qF -- "$s" "$D/implementer-prompt.md" && ok "implementer-prompt.md has: $s" || bad "implementer-prompt.md lacks: $s"
done
for s in 'Commit your work' 'After Review Findings' 'Commits created'; do
  grep -qF -- "$s" "$D/implementer-prompt.md" && bad "implementer-prompt.md still says: $s" || ok "implementer-prompt.md is free of: $s"
done
for s in 'A task with a commit is complete even without its ledger line' 'git log <start sha>..HEAD'; do
  grep -qF -- "$s" "$D/references/resuming.md" && ok "resuming.md has: $s" || bad "resuming.md lacks: $s"
done
for s in '--first-parent' 'carries this plan'"'"'s basename and it changes that task' 'rerun the full suite before any task that depends on it starts' 'Do not start a new end review'; do
  grep -qF -- "$s" "$D/references/resuming.md" && ok "resuming.md has: $s" || bad "resuming.md lacks: $s"
done
for s in 'Only tasks that could share a wave are batched' 'You still commit each task of a batch alone'; do
  grep -qF -- "$s" "$D/references/batching.md" && ok "batching.md has: $s" || bad "batching.md lacks: $s"
done
grep -qF -- 'review' "$D/references/batching.md" && bad "batching.md still mentions review" || ok "batching.md is free of: review"
for f in task-reviewer-prompt.md re-review-prompt.md references/fix-loop.md references/review-file.md references/cannot-verify.md scripts/review-package; do
  [ ! -e "$D/$f" ] && ok "$f is gone" || bad "$f still exists"
done
grep -qF -- 'final-review.md' <<<"$SK" && ok "SKILL names final-review.md" || bad "SKILL never names final-review.md"
grep -qF -- 'rm -rf <workspace>' <<<"$SK" && bad "SKILL still deletes the workspace" || ok "SKILL no longer deletes the workspace"
grep -qF -- 'scripts/sdd-archive' <<<"$SK" && ok "SKILL finishes with sdd-archive" || bad "SKILL never calls sdd-archive"
grep -qF -- 'delete this plan' <<<"$SK" && bad "SKILL still says delete this plan" || ok "process flow says archive"
[ -x "$D/scripts/sdd-archive" ] && ok "sdd-archive is executable" || bad "scripts/sdd-archive missing or not executable"
grep -qF -- '"${BASH:-bash}" "$here/sdd-workspace"' "$D/scripts/sdd-archive" && ok "sdd-archive calls sdd-workspace via bash" || bad "sdd-archive execs sdd-workspace directly"
grep -qE -- '(^|[^/])scripts/sdd-archive' <<<"$SK" && ! grep -qE -- '(^|[^h] )`?scripts/sdd-archive' <<<"$SK" && ok "SKILL calls sdd-archive via bash" || bad "SKILL calls sdd-archive without bash"

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

E="$(cd "$(dirname "$0")/../../skills/executing-plans" && pwd)/SKILL.md"
grep -qiF -- "delete this plan's workspace" "$E" && bad "executing-plans still deletes the workspace" || ok "executing-plans archives the workspace"
grep -qF -- 'sdd-archive PLAN_FILE' "$E" && ok "executing-plans finishes with sdd-archive" || bad "executing-plans never calls sdd-archive"
grep -qF -- 'Start: <sha>' "$E" && ok "executing-plans ledger has Start" || bad "executing-plans ledger lacks: Start: <sha>"
grep -qF -- 'Start: %s' "$(dirname "$E")/scripts/task-done" && ok "task-done writes Start" || bad "task-done ledger lacks Start"

# Reachability: rules that moved to references/ must be read from SKILL.md, and live in the file that is read.
for l in $(grep -oE '\(references/[a-z-]+\.md\)' "$D/SKILL.md" | tr -d '()' | sort -u); do [ -f "$D/$l" ] || bad "SKILL.md points at missing $l"; done
for r in final-review gate-check resuming; do grep -qF "(references/$r.md)" "$D/SKILL.md" || bad "SKILL.md never points at references/$r.md"; done
for s in 'do not dispatch' '(references/waiting.md)'; do grep -qF -- "$s" "$D/SKILL.md" || bad "SKILL.md lost: $s"; done
# Negative cases: each mutant of a copy of the skill dir must fail this check; a no-op mutant fails too.
if [ -z "${SDD_CHECK_MUTANT:-}" ]; then
  mt=$(mktemp -d); trap 'rm -rf "$mt"' EXIT
  mut() { rm -rf "$mt/m"; cp -r "$D" "$mt/m"; perl -0pi -e "$2" "$mt/m/$1"; cmp -s "$D/$1" "$mt/m/$1" && { bad "mutant no-op: $3"; return; }
    SDD_CHECK_MUTANT=1 SDD_SKILL_DIR="$mt/m" bash "$0" >/dev/null 2>&1 && bad "mutant passed: $3" || true; }
  mut SKILL.md 's/\(references\/final-review\.md\)/(references\/final.md)/g' 'final-review pointer broken'
  mut SKILL.md 's/Builders run no git command that writes/Builders commit/' 'builder git-write ban dropped'
  mut references/final-review.md 's/bash scripts\/sdd-archive/sdd-archive/' 'final-review sdd-archive lost its bash'
  mut references/resuming.md 's/A task with a commit is complete even without its ledger line/x/' 'resume-from-commits rule dropped'
fi

[ "$fail" -eq 0 ] && echo "sdd: OK"
exit $fail
