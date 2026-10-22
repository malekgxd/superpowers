#!/usr/bin/env bash
# Fork edit check: finishing reads a repo's `Finish branch:` line to skip the merge menu; every push still asks.
set -euo pipefail
F="${FINISH_SKILL:-$(cd "$(dirname "$0")/../../skills/finishing-a-development-branch" && pwd)/SKILL.md}"
fail=0
need() { grep -qF -- "$1" "$F" || { echo "MISSING: $1"; fail=1; }; }
gone() { grep -qF -- "$1" "$F" && { echo "STILL PRESENT: $1"; fail=1; } || true; }
PINS=('Ask for the base only when it is unknown'
  'A worktree made from a named base knows it.'
  '`Finish branch:`'
  '`git show <base-branch>:CLAUDE.md`'
  'Recognised values, exact match:'
  '- `merge locally`: merge and stop; do not offer a push.'
  '- `merge locally; ask before push`: merge, then ask once whether to push the base branch.'
  '- Step 1 tests passed;'
  '- the branch is a named branch (a detached HEAD always gets the menu);'
  "- this session ran the review chain on the branch's current HEAD and it passed (a fresh or resumed session with no such record gets the menu);"
  '- the line is present exactly once with a recognised value.'
  'Otherwise show the menu below, unchanged.'
  'Run Option 1 (Merge Locally) on the reviewed commit, exactly as written there'
  'including its test run on the merged result and its stop when they fail'
  'A merge conflict means stop and show the menu.'
  'push only after a yes'
  'a plain `git push origin <base-branch>`'
  'never with force'
  'rejected push is reported, not retried'
  'A deploy, OTA publish or release that usually follows still asks separately.'
  'Report which line was applied and what ran.')
for s in "${PINS[@]}"; do need "$s"; done
# The removed automatic-push design must stay gone.
for s in 'merge and push' 'PUSH_ALL' 'core.hooksPath' 'push only this branch' 'REVIEWED_OID' 'INTEGRATION' 'ff-only' 'EXTRAS'; do gone "$s"; done
if [ -z "${FINISH_MUTANT:-}" ]; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  for s in "${PINS[@]}"; do
    export PIN="$s"; cp "$F" "$tmp/m.md"; perl -0pi -e 's/\Q$ENV{PIN}\E/X/g' "$tmp/m.md"
    cmp -s "$F" "$tmp/m.md" && { echo "MUTANT NO-OP: $s"; fail=1; continue; }
    FINISH_MUTANT=1 FINISH_SKILL="$tmp/m.md" bash "$0" >/dev/null && { echo "MUTANT PASSED: $s"; fail=1; } || true
  done
fi
[ "$fail" -eq 0 ] && echo "finishing: OK"
exit $fail
