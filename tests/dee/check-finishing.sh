#!/usr/bin/env bash
set -euo pipefail
F="$(cd "$(dirname "$0")/../../skills/finishing-a-development-branch" && pwd)/SKILL.md"
fail=0
ok() { echo "OK   $1"; }; bad() { echo "FAIL $1"; fail=1; }
pin() { grep -qF -- "$1" "$F" && ok "pin: $1" || bad "MISSING: $1"; }
pin 'Finish branch:'
pin 'git show <base-branch>:CLAUDE.md'
pin 'merge locally; ask before push'
pin 'any other value gets the menu'
pin 'git log origin/<base-branch>..<base-branch>'
pin 'before the merge'
pin 'authorizes `git push` only'
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
G() { git -c user.name=t -c user.email=t@t "$@"; }
mk() { # mk NAME -> $T/NAME/{origin.git,repo}; main pushed with one commit
  mkdir -p "$T/$1"; git init -q --bare -b main "$T/$1/origin.git"
  git init -q -b main "$T/$1/repo"; cd "$T/$1/repo"; git remote add origin "$T/$1/origin.git"
  echo base > f; echo 'exit 0' > t.sh; G add -A; G commit -qm base; git push -q -u origin main; }
scope() { git checkout -q main; git pull -q; git log origin/main..main --format=%s; } # as the skill runs it
branch() { git checkout -q -b feat; echo feat > feat.txt; G add -A; G commit -qm feat1; git checkout -q main; }
# (a) other-session commit on main after the branch was cut
mk a; branch; echo o > o; G add -A; G commit -qm other; out=$(scope)
[ "$out" = other ] && ok "(a) post-cut commit listed" || bad "(a) got: $out"
# (b) clean
mk b; branch; out=$(scope); [ -z "$out" ] && ok "(b) clean case empty" || bad "(b) got: $out"
# (c) no origin/main ref
mk c; git update-ref -d refs/remotes/origin/main; git remote remove origin; git remote add origin "$T/c/origin.git"
rc=0; (git log origin/main..main >/dev/null 2>&1) || rc=$?; [ "$rc" -ne 0 ] && ok "(c) missing ref exits $rc" || bad "(c) exit 0"
# (d) unpushed commit on main made before the branch was cut
mk d; echo p > p; G add -A; G commit -qm prebranch; branch; out=$(scope)
[ "$out" = prebranch ] && ok "(d) pre-cut commit listed" || bad "(d) got: $out"
# (e) full sequence: empty list, merge, tests, branch deletion, push of exactly the feature commits
mk e; branch; out=$(scope); G merge -q --no-ff -m merge feat; bash t.sh; git branch -d feat >/dev/null; git push -q origin main
n=$(git --git-dir="$T/e/origin.git" rev-list --count main); s=$(git --git-dir="$T/e/origin.git" log main --format=%s | sort | tr '\n' ' ')
[ -z "$out" ] && [ "$n" -eq 3 ] && [ "$s" = "base feat1 merge " ] && ! git rev-parse -q --verify feat >/dev/null && ok "(e) full sequence pushes feature commits" || bad "(e) out=$out n=$n s=$s"
[ "$fail" -eq 0 ] && echo "finishing: OK"
exit $fail
