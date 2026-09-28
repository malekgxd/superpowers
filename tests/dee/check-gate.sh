#!/usr/bin/env bash
# gate-check: execution refuses to start unless intent, spec challenge and plan challenge are all on record.
set -euo pipefail
S="$(cd "$(dirname "$0")/../../skills" && pwd)"
G="$S/subagent-driven-development/scripts/gate-check"
fail=0
ok() { echo "OK   $1"; }
bad() { echo "FAIL $1"; fail=1; }

[ -x "$G" ] && ok "gate-check is executable" || bad "gate-check missing or not executable"
grep -qF -- 'scripts/gate-check PLAN_FILE' "$S/subagent-driven-development/SKILL.md" && ok "SDD SKILL runs gate-check" || bad "SDD SKILL never runs gate-check"
grep -qF -- '../subagent-driven-development/scripts/gate-check PLAN_FILE' "$S/executing-plans/SKILL.md" && ok "executing-plans runs gate-check" || bad "executing-plans never runs gate-check"
for f in subagent-driven-development executing-plans; do
  grep -qF -- 'Ruling: gate-check waived' "$S/$f/SKILL.md" && ok "$f ledgers a waiver" || bad "$f has no waiver ledger line"
done

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# Fixture: committed accepted intent, spec with a challenge heading, plan with Spec/Intent and plan rulings.
fixture() {
  rm -rf "$T/r"; mkdir -p "$T/r/docs/intents" "$T/r/docs/specs" "$T/r/docs/plans"
  cd "$T/r" && git init -q && git config user.email t@t && git config user.name t
  printf '# Intent: demo\nAuthor: Dee. Status: accepted\n' > docs/intents/i.md
  printf '# Spec\nIntent: docs/intents/i.md\n\n## 9. Challenge rulings\n- held\n' > docs/specs/s.md
  printf '# Plan\n\n**Spec:** `docs/specs/s.md` §4 (commit abc1234)\n**Intent:** `docs/intents/i.md`\n\n## Plan challenge rulings\n- held\n' > docs/plans/p.md
  git add -A && git commit -qm fixture
}
run() { out=$(cd "$T/r" && "${BASH:-bash}" "$G" docs/plans/p.md 2>&1) && rc=0 || rc=$?; }
expect() { # $1 label, $2 rc, $3 output substring
  run
  [ "$rc" -eq "$2" ] && [[ "$out" == *"$3"* ]] && ok "$1" || bad "$1 (rc=$rc out=$out)"
}

if [ -x "$G" ]; then
  fixture; expect "complete fixture passes" 0 "gate-check: OK"
  fixture; sed -i '/^\*\*Spec:/d' docs/plans/p.md; expect "plan without Spec line refused" 1 "gate-check: REFUSE plan has no Spec:"
  fixture; sed -i 's/Challenge rulings/Notes/' docs/specs/s.md; git commit -qam x; expect "spec without challenge heading refused" 1 "gate-check: REFUSE spec has no Challenge rulings"
  fixture; sed -i 's/Plan challenge rulings/Notes/' docs/plans/p.md; expect "plan without challenge heading refused" 1 "gate-check: REFUSE plan has no challenge rulings"
  fixture; sed -i 's/Status: accepted/Status: draft/' docs/intents/i.md; git commit -qam x; expect "draft intent refused via intent-guard" 1 "gate-check: REFUSE intent-guard on docs/specs/s.md: intent-guard: REFUSE intent not Status: accepted"
  fixture; sed -i '/^\*\*Intent:/d' docs/plans/p.md; expect "plan without Intent line refused" 1 "gate-check: REFUSE plan has no Intent:"
  fixture; rc=0; (cd "$T/r" && "${BASH:-bash}" "$G" >/dev/null 2>&1) || rc=$?; [ "$rc" -eq 2 ] && ok "no argument is a usage error" || bad "no argument: rc=$rc"
fi

[ "$fail" -eq 0 ] && echo "gate: OK"
exit $fail
