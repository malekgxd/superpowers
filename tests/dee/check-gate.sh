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
  # Fences: headings and fields inside ``` or ~~~ blocks do not count.
  fixture; sed -i 's/^## Plan challenge rulings$/```md\n## Plan challenge rulings\n```/' docs/plans/p.md; expect "plan heading only in a backtick fence refused" 1 "gate-check: REFUSE plan has no challenge rulings"
  fixture; sed -i 's/^## 9. Challenge rulings$/~~~~\n## 9. Challenge rulings\n~~~\n~~~~/' docs/specs/s.md; git commit -qam x; expect "spec heading only in a tilde fence refused" 1 "gate-check: REFUSE spec has no Challenge rulings"
  fixture; sed -i 's/^## Plan challenge rulings$/````text\n```\n## Plan challenge rulings\n```\n````/' docs/plans/p.md; expect "heading inside a nested 4-backtick fence refused" 1 "gate-check: REFUSE plan has no challenge rulings"
  fixture; sed -i 's/^\*\*Spec:/```\n**Spec:/; s/^\*\*Intent:\(.*\)$/**Intent:\1\n```/' docs/plans/p.md; expect "Spec/Intent only inside a fence refused" 1 "gate-check: REFUSE plan has no Spec:"
  # Container fences and HTML comments cannot supply fields or challenge headings.
  for marker in '- ' '* ' '+ ' '1. ' '> ' '  > - '; do
    for fence in '```' '~~~'; do
      fixture; sed -i '/^## Plan challenge rulings/,$d' docs/plans/p.md
      printf '%s%smd\n  ## Plan challenge rulings\n  %s\n' "$marker" "$fence" "$fence" >> docs/plans/p.md
      expect "plan heading only in $marker$fence fence refused" 1 "gate-check: REFUSE plan has no challenge rulings"
    done
  done
  fixture; sed -i 's/^## 9. Challenge rulings$/<!--\n## 9. Challenge rulings\n-->/' docs/specs/s.md; expect "spec heading only in an HTML comment refused" 1 "gate-check: REFUSE spec has no Challenge rulings"
  fixture; sed -i 's/^## Plan challenge rulings$/<!--\n## Plan challenge rulings\n-->/' docs/plans/p.md; expect "plan heading only in an HTML comment refused" 1 "gate-check: REFUSE plan has no challenge rulings"
  fixture; sed -i 's/^\*\*Spec:.*$/<!--\n&\n-->/' docs/plans/p.md; expect "Spec only in an HTML comment refused" 1 "gate-check: REFUSE plan has no Spec:"
  fixture; sed -i 's/^\*\*Intent:.*$/<!--\n&\n-->/' docs/plans/p.md; expect "plan Intent only in an HTML comment refused" 1 "gate-check: REFUSE plan has no Intent:"
  fixture; sed -i 's/^## Plan challenge rulings$/<!-- ## Plan challenge rulings -->/' docs/plans/p.md; expect "single-line commented heading refused" 1 "gate-check: REFUSE plan has no challenge rulings"
  fixture; sed -i 's/^## Plan challenge rulings$/<!-- old -->## Plan challenge rulings<!-- note -->/' docs/plans/p.md; expect "visible heading beside comments accepted" 0 "gate-check: OK"
  fixture
  for doc in docs/specs/s.md docs/plans/p.md; do sed -i '1a ```md <!-- literal info text\nIntent: missing.md\n```' "$doc"; done
  expect "comment opener in fence info cannot hide later fields or headings" 0 "gate-check: OK"
  for wrapper in fence comment; do
    if [ "$wrapper" = fence ]; then open='```md'; close='```'; else open='<!--'; close='-->'; fi
    fixture; printf '# Spec\n%s\nIntent: docs/intents/i.md\n%s\n## Challenge rulings\n' "$open" "$close" > docs/specs/s.md
    expect "spec Intent only in $wrapper refused" 1 "intent-guard: REFUSE spec has no Intent: line"
    printf '# Intent: draft\nAuthor: Dee. Status: draft\n' > docs/intents/draft.md
    printf 'Intent: docs/intents/draft.md\n' >> docs/specs/s.md; git add -A; git commit -qm draft
    expect "hidden spec Intent in $wrapper cannot shadow draft Intent" 1 "intent-guard: REFUSE intent not Status: accepted"
  done
  # CRLF closes fences before real fields and headings in both documents.
  fixture
  for doc in docs/specs/s.md docs/plans/p.md; do sed -i '1a ```md\nexample\n```' "$doc"; sed -i 's/$/\r/' "$doc"; done
  expect "CRLF plan and spec with headings after a code block accepted" 0 "gate-check: OK"
  fixture; sed -i 's/^## Plan challenge rulings$/```md\n## Plan challenge rulings\n```/; s/$/\r/' docs/plans/p.md; expect "CRLF plan heading only inside a fence refused" 1 "gate-check: REFUSE plan has no challenge rulings"
  fixture; sed -i 's/^## 9. Challenge rulings$/~~~\n## 9. Challenge rulings\n~~~/; s/$/\r/' docs/specs/s.md; expect "CRLF spec heading only inside a fence refused" 1 "gate-check: REFUSE spec has no Challenge rulings"
  # Full-path parse: never truncate or glob a Spec path.
  fixture; sed -i 's#`docs/specs/s.md`#docs/specs/s.md.disabled#' docs/plans/p.md; expect "Spec s.md.disabled refused although s.md exists" 1 "gate-check: REFUSE plan has no Spec:"
  fixture; sed -i 's#`docs/specs/s.md`#docs/specs/s*.md#' docs/plans/p.md; expect "globbed Spec path refused" 1 "gate-check: REFUSE plan has no Spec:"
  fixture; sed -i 's#^\*\*Spec:.*#Spec: docs/specs/s.md#' docs/plans/p.md; expect "bare Spec: line accepted" 0 "gate-check: OK"
  # Plan Intent: present, existing, and the spec's intent.
  fixture; sed -i 's#^\*\*Intent:.*#**Intent:** ``#' docs/plans/p.md; expect "empty plan Intent refused" 1 "gate-check: REFUSE plan has no Intent:"
  fixture; sed -i 's#docs/intents/i.md`$#docs/intents/nope.md`#' docs/plans/p.md; expect "nonexistent plan Intent refused" 1 "gate-check: REFUSE plan Intent file missing"
  fixture; printf '# Intent: other\nAuthor: Dee. Status: accepted\n' > docs/intents/j.md; git add -A; git commit -qm j; sed -i 's#docs/intents/i.md`$#docs/intents/j.md`#' docs/plans/p.md; expect "mismatched plan Intent refused" 1 "gate-check: REFUSE plan Intent does not match the spec's Intent"
  fixture; sed -i 's#`docs/intents/i.md`$#./docs/intents/../intents/i.md#' docs/plans/p.md; expect "plan Intent spelled differently but same file accepted" 0 "gate-check: OK"
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
    sed -i 's#`docs/intents/i.md`$#./docs/intents/i.md#' docs/plans/p.md
    PATH="$T/bin:$PATH" REALPATH_MODE="$mode" expect "realpath $mode refused" 1 "gate-check: REFUSE cannot resolve intent path"
  done
  fixture; rc=0; (cd "$T/r" && "${BASH:-bash}" "$G" >/dev/null 2>&1) || rc=$?; [ "$rc" -eq 2 ] && ok "no argument is a usage error" || bad "no argument: rc=$rc"
fi

[ "$fail" -eq 0 ] && echo "gate: OK"
exit $fail
