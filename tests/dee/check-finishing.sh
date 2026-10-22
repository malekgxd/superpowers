#!/usr/bin/env bash
set -euo pipefail
F="${FINISH_SKILL:-$(cd "$(dirname "$0")/../../skills/finishing-a-development-branch" && pwd)/SKILL.md}"
fail=0
ok() { echo "OK   $1"; }; bad() { echo "FAIL $1"; fail=1; }
pin() { grep -qF -- "$1" "$F" && ok "pin: $1" || bad "MISSING: $1"; }
pin 'Finish branch:'
pin 'git show <base-branch>:CLAUDE.md'
pin 'merge locally; ask before push'
pin 'any other value gets the menu'
pin 'authorizes `git push` only'
# Each pin below also gets a deletion mutant. STEPS are the push rule's commands, in the order the skill must give them.
STEPS=('git fetch origin' 'ORIGIN=$(git rev-parse origin/<base-branch>)' 'git rev-list "$ORIGIN"..<base-branch>' 'git merge --ff-only "$ORIGIN"'
  'FEATURE_OID=$(git rev-parse <feature-branch>)' 'git merge --no-edit <feature-branch>' 'MERGED=$(git rev-parse <base-branch>)'
  'git rev-list --parents -n1 "$MERGED"' 'git rev-list "$ORIGIN".."$MERGED"' 'git rev-list "$ORIGIN".."$FEATURE_OID"' 'git push origin "$MERGED":refs/heads/<base-branch>')
PINS2=("${STEPS[@]}" 'Step 1 tests passed' 'detached HEAD always gets the menu'
  "this session ran the review chain on this branch's current HEAD and it passed"
  'the main checkout is already on `<base-branch>`' '(`git -C <main-checkout> branch --show-current`); otherwise the menu'
  'If either command fails, stop and ask; nothing is merged yet.' 'must succeed and print nothing.'
  "Otherwise stop and ask, listing those commits: push all, or don't push." 'If the fast-forward fails, stop and ask.'
  'A conflict or any other merge failure: `git merge --abort`, then the menu.' 'If the merged tests fail, stop; nothing has been pushed.'
  'If either command fails or any other commit is listed, stop and ask,' "listing them: push all, or don't push."
  '`$MERGED` must equal `$FEATURE_OID` (fast-forward) or be a merge commit' 'whose parents are exactly `$ORIGIN` and `$FEATURE_OID`, checked with'
  '; anything else: stop and ask.' 'never retried with force' 'Under `merge locally; ask before push`, ask push or not here'
  'Keep the feature branch until the push is settled' 'If tests fail on the merged result: stop')
for x in "${PINS2[@]}"; do pin "$x"; done
last=0; for x in "${STEPS[@]}"; do n=$(grep -boF -- "$x" "$F" | head -1 | cut -d: -f1); n=${n:-0}
  [ "$n" -gt "$last" ] && last=$n || bad "OUT OF ORDER: $x"; done
if [ -z "${FINISH_MUTANT:-}" ]; then
  mt=$(mktemp -d); trap 'rm -rf "$mt" "${T:-}"' EXIT
  mutant() { FINISH_MUTANT=1 FINISH_SKILL="$mt/SKILL.md" bash "$0" >/dev/null 2>&1 && bad "MUTANT PASSED: $1" || ok "mutant caught: $1"; }
  for x in "${PINS2[@]}"; do cp "$F" "$mt/SKILL.md"; PIN="$x" perl -0pi -e 's/\Q$ENV{PIN}\E/X/' "$mt/SKILL.md"
    cmp -s "$F" "$mt/SKILL.md" && { bad "MUTANT NO-OP: $x"; continue; }; mutant "pin dropped: $x"; done
  cp "$F" "$mt/SKILL.md"; perl -0pi -e 's/git merge --ff-only "\$ORIGIN"/\0SWAP/; s/git merge --no-edit <feature-branch>/git merge --ff-only "\$ORIGIN"/; s/\0SWAP/git merge --no-edit <feature-branch>/' "$mt/SKILL.md"
  cmp -s "$F" "$mt/SKILL.md" && bad "MUTANT NO-OP: steps c and d swapped" || mutant "steps c and d swapped"
fi
[ -n "${FINISH_MUTANT:-}" ] && { [ "$fail" -eq 0 ]; exit; }
T=$(mktemp -d); trap 'rm -rf "${mt:-}" "$T"' EXIT
G() { git -c user.name=t -c user.email=t@t "$@"; }
mk() { # mk NAME -> $T/NAME/{origin.git,repo}; main pushed with one commit, cwd = repo
  mkdir -p "$T/$1"; git init -q --bare -b main "$T/$1/origin.git"
  git init -q -b main "$T/$1/repo"; cd "$T/$1/repo"; git remote add origin "$T/$1/origin.git"
  echo base > f; echo 'exit 0' > t.sh; G add -A; G commit -qm base; git push -q -u origin main; }
branch() { git checkout -q -b feat; echo feat > feat.txt; G add -A; G commit -qm feat1; git checkout -q main; }
commit() { echo "$1" > "$1"; G add -A; G commit -qm "$1"; } # commit NAME on the current branch
moved() { # another clone pushes REMOTE1 to origin
  G clone -q "$T/$1/origin.git" "$T/$1/other"; (cd "$T/$1/other"; echo r > r; G add -A; G commit -qm remote1; git push -q origin main); }
otip() { git --git-dir="$(git config remote.origin.url)" rev-parse main 2>/dev/null || echo none; }
osubj() { git --git-dir="$(git config remote.origin.url)" log main --format=%s | LC_ALL=C sort | tr '\n' ' '; }
# finish [AFTER HOOK]: the skill's push rule, steps a-g, run literally on main/feat; HOOK runs after step AFTER.
# Prints push | rejected | ask:<step> | menu | stop:e.
finish() { local after="${1:-}" hook="${2:-}" ORIGIN FEATURE_OID MERGED out allowed c par
  at() { [ "$after" = "$1" ] && eval "$hook"; return 0; }
  { git fetch -q origin && ORIGIN=$(git rev-parse -q --verify origin/main); } 2>/dev/null || { echo ask:a; return; }; at a  # a
  out=$(git rev-list "$ORIGIN"..main 2>/dev/null) && [ -z "$out" ] || { echo ask:b; return; }                            # b
  git merge -q --ff-only "$ORIGIN" 2>/dev/null || { echo ask:c; return; }                                                 # c
  FEATURE_OID=$(git rev-parse feat)                                                                                     # d
  G merge -q --no-edit feat >/dev/null 2>&1 || { git merge --abort; echo menu; return; }; at d
  MERGED=$(git rev-parse main); bash t.sh || { echo stop:e; return; }; at e                                             # e
  par=$(git rev-list --parents -n1 "$MERGED" 2>/dev/null) || { echo ask:f; return; }                                    # f
  [ "$MERGED" = "$FEATURE_OID" ] || [ "$par" = "$MERGED $ORIGIN $FEATURE_OID" ] || { echo ask:f; return; }
  { out=$(git rev-list "$ORIGIN".."$MERGED") && allowed=$(git rev-list "$ORIGIN".."$FEATURE_OID"); } 2>/dev/null || { echo ask:f; return; }
  for c in $out; do [ "$c" = "$MERGED" ] || grep -qx "$c" <<<"$allowed" || { echo ask:f; return; }; done
  git push -q origin "$MERGED":refs/heads/main 2>/dev/null && echo push || echo rejected; }                            # g
# (1) clean finish: the push carries exactly the feature commits (fast-forward)
mk clean; branch; r=$(finish)
[ "$r" = push ] && [ "$(otip)" = "$(git rev-parse feat)" ] && [ "$(osubj)" = "base feat1 " ] && ok "(1) clean finish pushes exactly the feature" || bad "(1) r=$r s=$(osubj)"
# (2) origin moved ahead: c fast-forwards, the push carries exactly feature commits + merge
mk moved; branch; moved moved; r=$(finish)
[ "$r" = push ] && [ "$(osubj)" = "Merge branch 'feat' base feat1 remote1 " ] && ok "(2) origin moved: ff then merge pushed" || bad "(2) r=$r s=$(osubj)"
# (3) unpushed commit on local base made before the cut -> asks at b, nothing pushed
mk precut; commit held; branch; o=$(otip); r=$(finish)
[ "$r" = ask:b ] && [ "$(otip)" = "$o" ] && ok "(3) held pre-cut commit asks at b" || bad "(3) r=$r"
# (4) another session's commit on local base after the cut -> asks at b
mk postcut; branch; commit other; o=$(otip); r=$(finish)
[ "$r" = ask:b ] && [ "$(otip)" = "$o" ] && ok "(4) post-cut commit asks at b" || bad "(4) r=$r"
# (5) a commit lands on base between d and e (a real merge, origin moved) -> caught at f
mk race; branch; moved race; o=$(otip); r=$(finish d 'commit racer')
[ "$r" = ask:f ] && [ "$(otip)" = "$o" ] && ok "(5) commit between merge and record caught at f" || bad "(5) r=$r"
# (5b) the same race after a fast-forward merge: the racer becomes $MERGED itself -> caught at f by the parent check
mk ffrace; branch; o=$(otip); r=$(finish d 'commit racer')
[ "$r" = ask:f ] && [ "$(otip)" = "$o" ] && ok "(5b) commit after a fast-forward merge caught at f" || bad "(5b) r=$r"
# (6) no origin ref -> asks at a; a failed rev-list -> asks at b, never a vacuous pass
mk noref; branch; git --git-dir="$T/noref/origin.git" update-ref -d refs/heads/main; git update-ref -d refs/remotes/origin/main; r=$(finish)
[ "$r" = ask:a ] && ok "(6) missing origin ref asks at a" || bad "(6) r=$r"
mk badrev; branch; o=$(otip); r=$(finish a 'ORIGIN=0000000000000000000000000000000000000001')
[ "$r" = ask:b ] && [ "$(otip)" = "$o" ] && ok "(6b) failed rev-list asks at b" || bad "(6b) r=$r"
# (7) merge conflict -> merge aborted, the menu, nothing pushed
mk conflict; git checkout -q -b feat; echo F > f; G commit -qam feat1; git checkout -q main; moved conflict
(cd "$T/conflict/other"; echo O > f; G commit -qam clash; git push -q origin main); o=$(otip); r=$(finish)
[ "$r" = menu ] && ! git rev-parse -q --verify MERGE_HEAD >/dev/null && [ "$(otip)" = "$o" ] && ok "(7) conflict aborts to the menu" || bad "(7) r=$r"
# (8) merged tests fail -> stop at e, nothing pushed
mk redtest; git checkout -q -b feat; echo 'exit 1' > t.sh; G commit -qam feat1; git checkout -q main; o=$(otip); r=$(finish)
[ "$r" = stop:e ] && [ "$(otip)" = "$o" ] && ok "(8) failed merged tests stop at e" || bad "(8) r=$r"
[ "$fail" -eq 0 ] && echo "finishing: OK"
exit $fail
