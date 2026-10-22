#!/usr/bin/env bash
# SDD fork edits: reviewer findings land in a file, and a finished workspace is archived, not deleted.
set -euo pipefail
D="$(cd "${SDD_SKILL_DIR:-$(dirname "$0")/../../skills/subagent-driven-development}" && pwd)"
# Upstream 7.0.1 moved the fix loop and final review into references/: check the skill text as a whole.
SK=$(cat "$D/SKILL.md" "$D"/references/*.md)
fail=0
ok() { echo "OK   $1"; }
bad() { echo "FAIL $1"; fail=1; }

grep -qF -- '[REVIEW_FILE]' "$D/task-reviewer-prompt.md" && grep -qF -- 'Write your full report to [REVIEW_FILE]' "$D/task-reviewer-prompt.md" \
  && ok "task reviewer writes its report to [REVIEW_FILE]" || bad "task reviewer lacks [REVIEW_FILE] contract"
grep -qF -- '[REVIEW_FILE]' "$D/re-review-prompt.md" && grep -qF -- '## Re-review round [ROUND]' "$D/re-review-prompt.md" \
  && ok "re-reviewer appends a round heading to [REVIEW_FILE]" || bad "re-reviewer lacks [REVIEW_FILE] append contract"
grep -qF -- 'final message is the report itself' "$D/task-reviewer-prompt.md" && bad "task reviewer still told to reply with the whole report" || ok "old reply-is-the-report line is gone"
lean=$(sed -n '/^```$/,/^```$/p' "$D/task-reviewer-prompt.md" | tr -s ' \n' ' ')
grep -qF -- "is a named risk. Search this repo's own files once for an existing one by what it does" <<<"$lean" \
  && grep -qF -- "A hit is a finding: name the existing path to call instead." <<<"$lean" \
  && ok "task reviewer searches the repo for reuse" || bad "task reviewer lacks the lean reuse search"
grep -qF -- "Code the brief never asked for is also a Part 1 **Extra** finding: report it in both parts, so the spec verdict is ❌." <<<"$lean" \
  && ok "unrequested code stays a Part 1 Extra" || bad "lean block lost the Part 1 Extra routing"
grep -qE -- 'ponytail:|shortcut:' "$D/task-reviewer-prompt.md" && bad "shortcut comments exempt findings" || ok "no shortcut-comment exemption"
grep -qF -- 'task-N-review.md' <<<"$SK" && ok "SKILL names the review file" || bad "SKILL never names task-N-review.md"
grep -qF -- 'final-review.md' <<<"$SK" && ok "SKILL names final-review.md" || bad "SKILL never names final-review.md"
grep -qF -- 'review-file path' <<<"$SK" && ok "fix dispatches carry the review file" || bad "fix dispatches omit the review file"
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
grep -qF -- 'Declined to judge' <<<"$SK" && ok "SDD final review returns Declined-to-judge lines" || bad "SDD final review drops Declined-to-judge lines"

# Reachability: rules that moved to references/ must be read from SKILL.md, and live in the file that is read.
for l in $(grep -oE '\(references/[a-z-]+\.md\)' "$D/SKILL.md" | tr -d '()' | sort -u); do [ -f "$D/$l" ] || bad "SKILL.md points at missing $l"; done
for r in fix-loop final-review review-file gate-check; do grep -qF "(references/$r.md)" "$D/SKILL.md" || bad "SKILL.md never points at references/$r.md"; done
grep -qF -- '<workspace>/final-review.md' "$D/references/final-review.md" && grep -qF -- 'Declined to judge' "$D/references/final-review.md" \
  && grep -qF -- 'bash scripts/sdd-archive' "$D/references/final-review.md" && ok "final-review.md carries report file, Declined-to-judge, sdd-archive" || bad "final-review.md lost a fork contract"
grep -qF -- 'review-file path' "$D/references/fix-loop.md" && ok "fix-loop.md carries the review file" || bad "fix-loop.md lost the review file"
grep -qF -- 'ledger each Minor finding' "$D/SKILL.md" && ok "SKILL.md ledgers Minor findings on every review" || bad "Minor findings only ledgered inside the fix loop"
# Negative cases: each mutant of a copy of the skill dir must fail this check; a no-op mutant fails too.
if [ -z "${SDD_CHECK_MUTANT:-}" ]; then
  mt=$(mktemp -d); trap 'rm -rf "$mt"' EXIT
  mut() { rm -rf "$mt/m"; cp -r "$D" "$mt/m"; perl -0pi -e "$2" "$mt/m/$1"; cmp -s "$D/$1" "$mt/m/$1" && { bad "mutant no-op: $3"; return; }
    SDD_CHECK_MUTANT=1 SDD_SKILL_DIR="$mt/m" bash "$0" >/dev/null 2>&1 && bad "mutant passed: $3" || true; }
  mut SKILL.md 's/\(references\/final-review\.md\)/(references\/final.md)/g' 'final-review pointer broken'
  mut references/final-review.md 's/`<workspace>\/final-review\.md`/the workspace/' 'final review report file dropped'
  mut SKILL.md 's/^After every review, read its review file and ledger each Minor finding\n.*\n\n//m' 'Minor-finding ledger line dropped'
  mut references/fix-loop.md 's/review-file path/review path/g' 'fix-loop review file dropped'
fi

[ "$fail" -eq 0 ] && echo "sdd: OK"
exit $fail
