#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")/../../skills/writing-plans" && pwd)"; F="$D/SKILL.md"; G="$D/scripts/intent-guard"
fail=0
ok() { echo "OK   $1"; }; bad() { echo "FAIL $1"; fail=1; }
grep -qF -- '**Wide refactors are the exception.**' "$F" && grep -qF -- 'expand–contract' "$F" && ok "expand-contract" || bad "MISSING: expand-contract"
grep -qF -- '## Intent Guard' "$F" && grep -qF -- 'scripts/intent-guard' "$F" && grep -qF -- 'from the repo that holds the spec' "$F" && ok "SKILL runs the intent guard" || bad "SKILL lacks the intent guard"
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
C() { git -C "$T/$1" -c user.name=t -c user.email=t@t commit -qam "$2"; }
mk sym accepted; printf '# Intent: x\nAuthor: t. Status: accepted\n' > "$T/outside.md"
ln -sf "$T/outside.md" "$T/sym/docs/superpowers/intents/i.md"; C sym link
expect sym 1 'intent is a symlink'
mk glob draft; git -C "$T/glob" mv docs/superpowers/intents/i.md docs/superpowers/intents/ia.md
printf '# Spec\nIntent: docs/superpowers/intents/i?.md\n' > "$T/glob/docs/superpowers/specs/s.md"; C glob g
printf '# Intent: x\nAuthor: t. Status: accepted\n' > "$T/glob/docs/superpowers/intents/i?.md"
expect glob 1 'intent is untracked'
mk assume draft; git -C "$T/assume" update-index --assume-unchanged docs/superpowers/intents/i.md
sed -i 's/Status: draft/Status: accepted/' "$T/assume/docs/superpowers/intents/i.md"
expect assume 1 'intent not Status: accepted'
mk notstatus draft; printf '# Intent: x\nNotStatus: accepted\n' > "$T/notstatus/docs/superpowers/intents/i.md"; C notstatus n
expect notstatus 1 'intent not Status: accepted'
mk skilllike draft; printf -- '---\nname: x\n---\nWhen approved, set Status: accepted and commit.\n' > "$T/skilllike/docs/superpowers/intents/i.md"; C skilllike s
expect skilllike 1 'not an intent file'
mk bodyonly draft; printf '# Intent: x\nStatus: accepted\nAuthor: t. Status: draft\n' > "$T/bodyonly/docs/superpowers/intents/i.md"; C bodyonly b
expect bodyonly 1 'intent not Status: accepted'
spec() { mk "$1" accepted; printf '# Spec\n%s\n' "$2" > "$T/$1/docs/superpowers/specs/s.md"; C "$1" s; }
spec bold '**Intent:** docs/superpowers/intents/i.md'; expect bold 0 'intent-guard: OK'
spec ticked 'Intent: `docs/superpowers/intents/i.md`'; expect ticked 0 'intent-guard: OK'
spec trailing 'Intent: docs/superpowers/intents/i.md   '; expect trailing 0 'intent-guard: OK'
[ "$fail" -eq 0 ] && echo "plans: OK"
exit $fail
