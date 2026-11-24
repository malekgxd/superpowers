#!/usr/bin/env bash
set -euo pipefail
F="$(dirname "$0")/../../skills/requesting-code-review/code-reviewer.md"
S="$(dirname "$0")/../../skills/requesting-code-review/SKILL.md"
fail=0
for s in 'Mysterious Name' 'Duplicated Code' 'Feature Envy' 'Data Clumps' 'Primitive Obsession' 'Repeated Switches' 'Shotgun Surgery' 'Divergent Change' 'Speculative Generality' 'Message Chains' 'Middle Man' 'Refused Bequest'; do
  grep -qF -- "**$s**" "$F" || { echo "MISSING: $s"; fail=1; }
done
grep -qF -- '**Smell baseline' "$F" || { echo "MISSING: heading"; fail=1; }
grep -qF -- 'A documented repo standard always wins' "$F" || { echo "MISSING: override rule"; fail=1; }
for s in '/codex:adversarial-review --base <base> --model gpt-6.2-sol -- <Review Focus text>' 'once, when the whole change is committed' 'CODEX-LANE.md' 'No second review by another model' 'the review was not a Sol review' '`Yes` counts as `approve`' 'Every Declined to judge line is a ruling you make and ledger'; do
  grep -qF -- "$s" "$S" || { echo "MISSING: $s"; fail=1; }
done
for s in 'Review early, review often' 'After each task in subagent-driven development' 'Continue to Task 3'; do
  ! grep -qF -- "$s" "$S" || { echo "STILL PRESENT: $s"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "review: OK"
exit $fail
