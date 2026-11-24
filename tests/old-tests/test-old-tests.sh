#!/usr/bin/env bash
# Fixture test for skills/verification-before-completion/scripts/old-tests.
set -euo pipefail
S="$(cd "$(dirname "$0")/../../skills/verification-before-completion/scripts" && pwd)/old-tests"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0
ok() { echo "  [PASS] $1"; }
bad() { echo "  [FAIL] $1"; echo "$out" | sed 's/^/      /'; fail=1; }
has() { grep -qF -- "$1" <<<"$out"; }

# The suite: every tests/*.sh is run and gets one PASS or FAIL line.
SUITE=(bash -c 'r=0; for t in tests/*.sh; do if bash "$t" >/dev/null 2>&1; then echo "PASS $t"; else echo "FAIL $t"; r=1; fi; done; exit $r')
cd "$T"; git init -q; git config user.name t; git config user.email t@example.com
mkdir tests
echo 'echo 1' > lib.sh
echo '[ "$(bash lib.sh)" = 1 ]' > tests/a.sh
echo '[ "$(bash lib.sh)" = 1 ]' > tests/b.sh
git add -A; git commit -qm reviewed; base=$(git rev-parse HEAD)
# each case branches off the reviewed commit; `try` runs the script against the case's commit
try() { rc=0; out=$("$S" "$base" "$(git rev-parse HEAD)" -- "${SUITE[@]}" 2>&1) || rc=$?; git checkout -q "$base"; }
commit() { git add -A; git commit -qm "$1"; }

echo 'echo 1 # refactor' > lib.sh; commit 'no test change'; try
[ $rc -eq 0 ] && has 'no test file changed' && ok "no test change: says so, exit 0" || bad "no test change (rc=$rc)"

echo 'true' > tests/c.sh; commit 'added only'; try
[ $rc -eq 0 ] && has 'keep    A tests/c.sh' && has 'nothing to restore' && ok "added test only: kept, no comparison, exit 0" || bad "added test only (rc=$rc)"

# The fix breaks the behaviour and weakens the test to hide it; a new test rides along.
echo 'echo 2' > lib.sh; echo 'true' > tests/a.sh; echo 'true' > tests/c.sh; commit 'modified'; try
[ $rc -eq 1 ] && has 'restore M tests/a.sh' && has 'REGRESSED     PASS tests/a.sh' && has 'keep    A tests/c.sh' && has '| PASS tests/c.sh' && ok "modified test: old version restored, regression caught, added test still runs" || bad "modified test (rc=$rc)"

echo 'echo 1 # ok' > lib.sh; echo '[ "$(bash lib.sh)" = 1 ] # reworded' > tests/a.sh; commit 'modified harmless'; try
[ $rc -eq 0 ] && has 'STILL PASSES  PASS tests/a.sh' && has 'old-tests: OK' && ok "modified test, behaviour kept: exit 0" || bad "modified harmless (rc=$rc)"

git mv tests/b.sh tests/b2.sh; commit 'renamed'; try
[ $rc -eq 0 ] && has 'restore R tests/b.sh (removes tests/b2.sh)' && has 'STILL PASSES  PASS tests/b.sh' && ! has '| PASS tests/b2.sh' && ok "renamed test: old path restored, new path not run twice" || bad "renamed test (rc=$rc)"

git rm -q tests/b.sh; echo 'echo 2' > lib.sh; echo 'true' > tests/a.sh; commit 'deleted'; try
[ $rc -eq 1 ] && has 'restore D tests/b.sh' && has 'REGRESSED     PASS tests/b.sh' && ok "deleted test: restored, regression caught" || bad "deleted test (rc=$rc)"

[ "$(git worktree list | wc -l)" -eq 1 ] && ok "no disposable worktree left behind" || { out=$(git worktree list); bad "worktrees left behind"; }
rc=0; out=$("$S" "$base" 2>&1) || rc=$?
[ $rc -eq 2 ] && ok "usage error exits 2" || bad "usage (rc=$rc)"

[ "$fail" -eq 0 ] && echo "old-tests: ALL OK"
exit $fail
