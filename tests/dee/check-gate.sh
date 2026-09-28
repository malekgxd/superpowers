#!/usr/bin/env bash
# gate-check: execution refuses to start unless intent, spec challenge and plan challenge are all on record.
set -euo pipefail
S="$(cd "$(dirname "$0")/../../skills" && pwd)"
G="$S/subagent-driven-development/scripts/gate-check"
fail=0
ok() { echo "OK   $1"; }
bad() { echo "FAIL $1"; fail=1; }

[ -x "$G" ] && ok "gate-check is executable" || bad "gate-check missing or not executable"
grep -qF -- 'bash <this skill'"'"'s base directory>/scripts/gate-check PLAN_FILE' "$S/subagent-driven-development/SKILL.md" && ok "SDD SKILL runs gate-check by its absolute base directory" || bad "SDD SKILL does not run gate-check by its base directory"
grep -qF -- 'bash <this skill'"'"'s base directory>/../subagent-driven-development/scripts/gate-check PLAN_FILE' "$S/executing-plans/SKILL.md" && ok "executing-plans runs gate-check by its absolute base directory" || bad "executing-plans does not run gate-check by its base directory"
grep -qF -- 'Only the four stops stop you' "$S/executing-plans/SKILL.md" && bad "executing-plans still says only the four stops" || ok "executing-plans rationalization table names the gate stop"
for f in subagent-driven-development executing-plans; do
  grep -qF -- 'Ruling: gate-check waived' "$S/$f/SKILL.md" && ok "$f ledgers a waiver" || bad "$f has no waiver ledger line"
  grep -qF -- 'one more thing stops you: a gate-check refusal' "$S/$f/SKILL.md" && ok "$f stop list names the gate-check refusal" || bad "$f stop list omits the gate-check refusal"
  grep -qF -- 'neither a `gate-check: OK` nor a `gate-check waived` line' "$S/$f/SKILL.md" && ok "$f resume accepts a waiver" || bad "$f resume re-asks after a waiver"
done

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# Fixture: committed accepted intent; spec and plan whose header regions (before the first `## `)
# carry Intent/Spec and a Challenge: line.
fixture() {
  rm -rf "$T/r"; mkdir -p "$T/r/docs/intents" "$T/r/docs/specs" "$T/r/docs/plans"
  cd "$T/r" && git init -q && git config user.email t@t && git config user.name t
  printf '# Intent: demo\nAuthor: Dee. Status: accepted\n' > docs/intents/i.md
  printf '# Spec\nIntent: docs/intents/i.md\nChallenge: 2026-09-28 holds\n\n## 9. Challenge rulings\n- held\n' > docs/specs/s.md
  printf '# Plan\n\n**Spec:** `docs/specs/s.md` §4 (commit abc1234)\n**Intent:** `docs/intents/i.md`\n**Challenge:** 2026-09-28 holds-with-conditions\n\n## Plan challenge rulings\n- held\n' > docs/plans/p.md
  git add -A && git commit -qm fixture
}
C() { git add -A && git commit -qm x; }
run() { out=$(cd "$T/r" && "${BASH:-bash}" "$G" docs/plans/p.md 2>&1) && rc=0 || rc=$?; }
expect() { # $1 label, $2 rc, $3 output substring
  run
  [ "$rc" -eq "$2" ] && [[ "$out" == *"$3"* ]] && ok "$1" || bad "$1 (rc=$rc out=$out)"
}

if [ -x "$G" ]; then
  fixture; expect "complete fixture passes" 0 "gate-check: OK"
  fixture; sed -i '/^\*\*Spec:/d' docs/plans/p.md; C; expect "plan without Spec line refused" 1 "gate-check: REFUSE plan has no Spec:"
  fixture; sed -i 's/Status: accepted/Status: draft/' docs/intents/i.md; C; expect "draft intent refused via intent-guard" 1 "gate-check: REFUSE intent-guard on docs/specs/s.md: intent-guard: REFUSE intent not Status: accepted"
  fixture; sed -i '/^\*\*Intent:/d' docs/plans/p.md; C; expect "plan without Intent line refused" 1 "gate-check: REFUSE plan has no Intent:"
  # Challenge: exactly one `YYYY-MM-DD <verdict>` line in each header.
  fixture; sed -i '/^\*\*Challenge:/d' docs/plans/p.md; C; expect "plan without Challenge line refused" 1 "gate-check: REFUSE plan header has no Challenge: line"
  fixture; sed -i '/^Challenge:/d' docs/specs/s.md; C; expect "spec without Challenge line refused" 1 "gate-check: REFUSE spec header has no Challenge: line"
  fixture; sed -i 's/2026-09-28 holds-with/2026-13-28 holds-with/' docs/plans/p.md; C; expect "Challenge with a bad date refused" 1 "gate-check: REFUSE plan Challenge: line is not"
  fixture; sed -i 's/^Challenge: 2026-09-28 holds$/Challenge: 2026-09-28 broken/' docs/specs/s.md; C; expect "Challenge with a bad verdict refused" 1 "gate-check: REFUSE spec Challenge: line is not"
  fixture; sed -i 's/^Challenge: 2026-09-28 holds$/Challenge: 2026-09-28/' docs/specs/s.md; C; expect "Challenge without a verdict refused" 1 "gate-check: REFUSE spec Challenge: line is not"
  fixture; sed -i 's/^\*\*Challenge:.*$/&\nChallenge: 2026-09-29 holds/' docs/plans/p.md; C; expect "two plan Challenge lines refused" 1 "gate-check: REFUSE plan header has more than one Challenge: line"
  fixture; sed -i 's/^Challenge: .*$/Challenge: `2026-09-28 broken-ruled`   /' docs/specs/s.md; C; expect "backticked broken-ruled Challenge accepted" 0 "gate-check: OK"
  # Header region only: a fence or comment in it refuses; content after the first `## ` is ignored.
  fixture; sed -i 's/^# Plan$/&\n```md\nexample\n```/' docs/plans/p.md; C; expect "fence in plan header refused" 1 "gate-check: REFUSE plan header holds a code fence or comment"
  fixture; sed -i 's/^# Spec$/&\n<!-- note -->/' docs/specs/s.md; C; expect "comment in spec header refused" 1 "gate-check: REFUSE spec header holds a code fence or comment"
  fixture; sed -i 's/^# Spec$/&\nSee ~~~ here/' docs/specs/s.md; C; expect "tilde run in spec header refused" 1 "gate-check: REFUSE spec header holds a code fence or comment"
  fixture; printf '\n## Examples\n```md\nChallenge: 2026-09-28 holds\n<!-- x -->\n```\n' >> docs/plans/p.md; C; expect "fenced example below the header ignored" 0 "gate-check: OK"
  fixture; sed -i '/^\*\*Challenge:/d' docs/plans/p.md; printf '\n## Examples\n```md\n**Challenge:** 2026-09-28 holds\n```\nChallenge: 2026-09-28 holds\n' >> docs/plans/p.md; C; expect "Challenge only below the header refused" 1 "gate-check: REFUSE plan header has no Challenge: line"
  fixture; sed -i '/^\*\*Spec:/d' docs/plans/p.md; printf '\n## Notes\nSpec: docs/specs/s.md\n' >> docs/plans/p.md; C; expect "Spec only below the header refused" 1 "gate-check: REFUSE plan has no Spec:"
  fixture; sed -i '/^##/d' docs/plans/p.md; printf '```\nlate fence\n```\n' >> docs/plans/p.md; C; expect "plan with no ## heading is all header: late fence refused" 1 "gate-check: REFUSE plan header holds a code fence or comment"
  # Plan and spec are read from HEAD: uncommitted edits are not honoured.
  fixture; sed -i '/^\*\*Challenge:/d' docs/plans/p.md; C; sed -i 's/^\*\*Intent:.*$/&\n**Challenge:** 2026-09-28 holds/' docs/plans/p.md; expect "uncommitted plan Challenge not honoured" 1 "gate-check: REFUSE plan header differs from the committed version"
  fixture; sed -i '/^Challenge:/d' docs/specs/s.md; C; sed -i 's/^Intent:.*$/&\nChallenge: 2026-09-28 holds/' docs/specs/s.md; expect "uncommitted spec Challenge not honoured" 1 "gate-check: REFUSE spec header differs from the committed version"
  fixture; git rm -q --cached docs/plans/p.md; git commit -qm untrack; expect "untracked plan refused" 1 "gate-check: REFUSE plan not in HEAD"
  fixture; git rm -q --cached docs/specs/s.md; git commit -qm untrack; expect "untracked spec refused" 1 "gate-check: REFUSE spec not in HEAD"
  fixture; printf '# Intent: other\nAuthor: Dee. Status: accepted\n' > docs/intents/j.md; C; sed -i 's#^Intent:.*#Intent: docs/intents/j.md#' docs/specs/s.md; expect "worktree spec Intent differing from HEAD refused" 1 "gate-check: REFUSE spec header differs from the committed version"
  # The working-tree header must match the committed one; content below the header may differ.
  fixture; sed -i '/^Challenge:/d' docs/specs/s.md; expect "working-tree spec Challenge removed refused" 1 "gate-check: REFUSE spec header differs from the committed version"
  fixture; sed -i 's/^Challenge: .*$/Challenge: 2026-09-28 broken/' docs/specs/s.md; expect "working-tree spec verdict changed to broken refused" 1 "gate-check: REFUSE spec header differs from the committed version"
  fixture; sed -i 's/^# Plan$/# Plan, edited/' docs/plans/p.md; expect "working-tree plan header edited refused" 1 "gate-check: REFUSE plan header differs from the committed version"
  fixture; printf -- '- new step\n' >> docs/plans/p.md; expect "working-tree plan body edit accepted" 0 "gate-check: OK"
  fixture; sed -i 's/$/\r/' docs/plans/p.md; expect "working-tree CRLF-only change accepted" 0 "gate-check: OK"
  # Working-tree files must also refuse NUL bytes before capturing their headers.
  fixture; sed -i 's/^\*\*Challenge:/**Chal\x00lenge:/' docs/plans/p.md; expect "working-tree NUL inside the plan Challenge key refused" 1 "gate-check: REFUSE plan contains NUL bytes"
  fixture; sed -i 's/holds-with-conditions/hol\x00ds-with-conditions/' docs/plans/p.md; expect "working-tree NUL inside the plan verdict refused" 1 "gate-check: REFUSE plan contains NUL bytes"
  fixture; sed -i 's/^Challenge:/Chal\x00lenge:/' docs/specs/s.md; expect "working-tree NUL inside the spec Challenge key refused" 1 "gate-check: REFUSE spec contains NUL bytes"
  fixture; sed -i 's/^Challenge: 2026-09-28 holds$/Challenge: 2026-09-28 hol\x00ds/' docs/specs/s.md; expect "working-tree NUL inside the spec verdict refused" 1 "gate-check: REFUSE spec contains NUL bytes"
  # Committed blobs with NUL bytes refuse before any capture could strip them.
  fixture; sed -i 's/^\*\*Challenge:/**Chal\x00lenge:/' docs/plans/p.md; C; expect "NUL inside the plan Challenge key refused" 1 "gate-check: REFUSE plan contains NUL bytes"
  fixture; sed -i 's/^Challenge: 2026-09-28 holds$/Challenge: 2026-09-28 hol\x00ds/' docs/specs/s.md; C; expect "NUL inside the spec verdict refused" 1 "gate-check: REFUSE spec contains NUL bytes"
  # Absolute paths are made repo-relative before the HEAD read.
  fixture; out=$("${BASH:-bash}" "$G" "$T/r/docs/plans/p.md" 2>&1) && rc=0 || rc=$?
  [ "$rc" -eq 0 ] && [[ "$out" == "gate-check: OK" ]] && ok "absolute plan path accepted" || bad "absolute plan path (rc=$rc out=$out)"
  mkdir -p "$T/r/docs/sub"; out=$(cd "$T/r/docs/sub" && "${BASH:-bash}" "$G" "$T/r/docs/plans/p.md" 2>&1) && rc=0 || rc=$?
  [ "$rc" -eq 1 ] && [[ "$out" != *"not in HEAD"* ]] && ok "absolute plan path from a subdirectory reads the right blob" || bad "absolute plan path from a subdirectory (rc=$rc out=$out)"
  cp docs/plans/p.md "$T/outside.md"; out=$("${BASH:-bash}" "$G" "$T/outside.md" 2>&1) && rc=0 || rc=$?
  [ "$rc" -eq 1 ] && [[ "$out" == *"REFUSE plan lies outside the repo"* ]] && ok "absolute plan path outside the repo refused" || bad "absolute plan outside repo (rc=$rc out=$out)"
  # CRLF is normalized in header lines.
  fixture; sed -i 's/$/\r/' docs/specs/s.md docs/plans/p.md; C; expect "CRLF plan and spec accepted" 0 "gate-check: OK"
  # Full-path parse: never truncate or glob a Spec path.
  fixture; sed -i 's#`docs/specs/s.md`#docs/specs/s.md.disabled#' docs/plans/p.md; C; expect "Spec s.md.disabled refused although s.md exists" 1 "gate-check: REFUSE plan has no Spec:"
  fixture; sed -i 's#`docs/specs/s.md`#docs/specs/s*.md#' docs/plans/p.md; C; expect "globbed Spec path refused" 1 "gate-check: REFUSE plan has no Spec:"
  fixture; sed -i 's#^\*\*Spec:.*#Spec: docs/specs/s.md#' docs/plans/p.md; C; expect "bare Spec: line accepted" 0 "gate-check: OK"
  # Plan Intent: present, existing, and the spec's intent.
  fixture; sed -i 's#^\*\*Intent:.*#**Intent:** ``#' docs/plans/p.md; C; expect "empty plan Intent refused" 1 "gate-check: REFUSE plan has no Intent:"
  fixture; sed -i 's#docs/intents/i.md`$#docs/intents/nope.md`#' docs/plans/p.md; C; expect "nonexistent plan Intent refused" 1 "gate-check: REFUSE plan Intent file missing"
  fixture; printf '# Intent: other\nAuthor: Dee. Status: accepted\n' > docs/intents/j.md; sed -i 's#docs/intents/i.md`$#docs/intents/j.md`#' docs/plans/p.md; C; expect "mismatched plan Intent refused" 1 "gate-check: REFUSE plan Intent does not match the spec's Intent"
  fixture; sed -i 's#`docs/intents/i.md`$#./docs/intents/../intents/i.md#' docs/plans/p.md; C; expect "plan Intent spelled differently but same file accepted" 0 "gate-check: OK"
  # Each realpath call must succeed and return a nonempty path before comparison.
  mkdir -p "$T/bin"
  for mode in fail empty fail-with-output plan-fail spec-fail plan-empty spec-empty; do
    fixture
    cat > "$T/bin/realpath" <<'STUB'
#!/usr/bin/env bash
case "$REALPATH_MODE:$2" in
  fail:*|plan-fail:./*|spec-fail:docs/*) exit 127 ;;
  empty:*|plan-empty:./*|spec-empty:docs/*) exit 0 ;;
  fail-with-output:*) printf '/same/path\n'; exit 1 ;;
esac
printf '/same/path\n'
STUB
    chmod +x "$T/bin/realpath"
    sed -i 's#`docs/intents/i.md`$#./docs/intents/i.md#' docs/plans/p.md; C
    PATH="$T/bin:$PATH" REALPATH_MODE="$mode" expect "realpath $mode refused" 1 "gate-check: REFUSE cannot resolve intent path"
  done
  fixture; rc=0; (cd "$T/r" && "${BASH:-bash}" "$G" >/dev/null 2>&1) || rc=$?; [ "$rc" -eq 2 ] && ok "no argument is a usage error" || bad "no argument: rc=$rc"
fi

[ "$fail" -eq 0 ] && echo "gate: OK"
exit $fail
