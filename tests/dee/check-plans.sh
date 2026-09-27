#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")/../../skills/writing-plans" && pwd)"; F="$D/SKILL.md"; G="$D/scripts/intent-guard"
fail=0
ok() { echo "OK   $1"; }; bad() { echo "FAIL $1"; fail=1; }
grep -qF -- '**Wide refactors are the exception.**' "$F" && grep -qF -- 'expand–contract' "$F" && ok "expand-contract" || bad "MISSING: expand-contract"
grep -qF -- '## Intent Guard' "$F" && grep -qF -- 'bash scripts/intent-guard' "$F" && ok "SKILL runs the intent guard" || bad "SKILL lacks the intent guard"
grep -qF -- '**Intent:**' "$F" && ok "plan header carries Intent" || bad "plan header lacks Intent"
grep -qF -- 'challenge the committed plan' "$F" && ok "handoff challenges the plan" || bad "handoff lacks the plan challenge"
grep -qF -- 'I recommend Subagent-driven' "$F" && ok "handoff recommends Subagent-driven" || bad "handoff does not recommend Subagent-driven"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mk() { # mk NAME INTENT_STATUS  -> repo with committed spec+intent
  r="$T/$1"; mkdir -p "$r/docs/superpowers/intents" "$r/docs/superpowers/specs"; git -C "$r" init -q
  printf '# Intent: x\nAuthor: t. Status: %s\n' "$2" > "$r/docs/superpowers/intents/i.md"
  printf '# Spec\nIntent: docs/superpowers/intents/i.md\n' > "$r/docs/superpowers/specs/s.md"
  git -C "$r" add -A; git -C "$r" -c user.name=t -c user.email=t@t commit -qm init; }
run() { (cd "$T/$1" && bash "$G" docs/superpowers/specs/s.md 2>&1); }
expect() { # expect NAME RC TEXT
  local out rc=0; out=$(run "$1") || rc=$?
  [ "$rc" -eq "$2" ] && grep -qF -- "$3" <<<"$out" && ok "guard $1: $3" || bad "guard $1: rc=$rc out=$out"; }
mk good accepted; expect good 0 'intent-guard: OK'
mk noline accepted; printf '# Spec\n' > "$T/noline/docs/superpowers/specs/s.md"; git -C "$T/noline" -c user.name=t -c user.email=t@t commit -qam s
expect noline 1 'spec has no Intent: line'
mk draft draft; expect draft 1 'intent not Status: accepted'
mk quoted draft; printf 'Body quotes Status: accepted here.\n' >> "$T/quoted/docs/superpowers/intents/i.md"; git -C "$T/quoted" -c user.name=t -c user.email=t@t commit -qam q
expect quoted 1 'intent not Status: accepted'
out=$(cd "$T/good" && bash "$G" docs/superpowers/specs/missing.md 2>&1) && rc=0 || rc=$?
[ "$rc" -eq 2 ] && ! grep -qF 'intent-guard: OK' <<<"$out" && ok "guard missing spec: exit 2, no OK" || bad "guard missing spec: rc=$rc out=$out"
mk untracked accepted; git -C "$T/untracked" rm -q --cached docs/superpowers/intents/i.md
expect untracked 1 'intent is untracked'
mk dirty accepted; echo edit >> "$T/dirty/docs/superpowers/intents/i.md"; expect dirty 1 'intent has uncommitted changes'
[ "$fail" -eq 0 ] && echo "plans: OK"
exit $fail
