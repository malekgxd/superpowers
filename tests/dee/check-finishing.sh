#!/usr/bin/env bash
set -euo pipefail
F="${FINISH_SKILL:-$(cd "$(dirname "$0")/../../skills/finishing-a-development-branch" && pwd)/SKILL.md}"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
# Pin prose gates and complete command blocks. Execute the extracted blocks below,
# so fixtures cannot keep passing by silently implementing an older recipe.
python3 - "$F" "$T/steps.sh" <<'PY'
import os, re, shlex, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
blocks = {
'gate': ['REVIEWED_OID=<reviewed-commit>', 'test "$(git rev-parse <feature-branch>)" = "$REVIEWED_OID"'],
'a': ['''git fetch origin &&
ORIGIN=$(git rev-parse origin/<base-branch>)'''],
'b': ['''INTEGRATION_BASE=$ORIGIN &&
PUSH_ALL= &&
LOCAL_BASE=$(git rev-parse <base-branch>) &&
HELD=$(git rev-list "$ORIGIN".."$LOCAL_BASE")''', 'test -z "$HELD"', '''INTEGRATION_BASE=$LOCAL_BASE &&
PUSH_ALL=$HELD'''],
'c': ['''TMP_ROOT=$(mktemp -d) &&
INTEGRATION="$TMP_ROOT/integration" &&
git -c core.hooksPath=/dev/null worktree add --detach "$INTEGRATION" "$INTEGRATION_BASE"''',
'''test "$(git rev-parse <feature-branch>)" = "$REVIEWED_OID"''',
'''git -C "$INTEGRATION" -c core.hooksPath=/dev/null merge --no-edit "$REVIEWED_OID"''',
'''git -C "$INTEGRATION" merge --abort'''],
'd': ['''MERGED=$(git -C "$INTEGRATION" rev-parse HEAD) &&
PARENTS=$(git rev-list --parents -n1 "$MERGED") &&
{ test "$MERGED" = "$REVIEWED_OID" || test "$PARENTS" = "$MERGED $INTEGRATION_BASE $REVIEWED_OID"; }''',
'''git -c core.hooksPath=/dev/null worktree add --detach "$TMP_ROOT/check" "$INTEGRATION_BASE" &&
git -C "$TMP_ROOT/check" -c core.hooksPath=/dev/null merge --no-edit "$REVIEWED_OID" &&
EXPECTED_TREE=$(git -C "$TMP_ROOT/check" rev-parse 'HEAD^{tree}') &&
test "$(git rev-parse "$MERGED^{tree}")" = "$EXPECTED_TREE" &&
git worktree remove "$TMP_ROOT/check"'''],
'e': ['''test "$(git -C "$INTEGRATION" rev-parse HEAD)" = "$MERGED" &&
git -C "$INTEGRATION" diff --exit-code "$MERGED" -- &&
git -C "$INTEGRATION" diff --cached --exit-code "$MERGED" --''',
'''(cd "$INTEGRATION" && <test command>)''',
'''test "$(git -C "$INTEGRATION" rev-parse HEAD)" = "$MERGED" &&
git -C "$INTEGRATION" diff --exit-code "$MERGED" -- &&
git -C "$INTEGRATION" diff --cached --exit-code "$MERGED" --'''],
'f': ['''OUTGOING=$(git rev-list "$ORIGIN".."$MERGED") &&
REVIEWED_COMMITS=$(git rev-list "$ORIGIN".."$REVIEWED_OID")''',
'''EXTRAS=
for OID in $OUTGOING; do
  if ! printf '%s\\n' "$MERGED" "$PUSH_ALL" "$REVIEWED_COMMITS" | grep -Fx "$OID" >/dev/null; then
    EXTRAS="$EXTRAS $OID"
  fi
done
test -z "$EXTRAS"'''],
'g': ['''git push origin "$MERGED":refs/heads/<base-branch>''',
'''git worktree remove "$INTEGRATION" &&
rmdir "$TMP_ROOT"''',
'''MAIN_BRANCH=$(git -C <main-checkout> branch --show-current) &&
MAIN_STATUS=$(git -C <main-checkout> status --porcelain) &&
test "$MAIN_BRANCH" = <base-branch> &&
test -z "$MAIN_STATUS"''',
'''git -C <main-checkout> -c core.hooksPath=/dev/null merge --ff-only "$MERGED"'''],
}
pins = {
'initial': ["Run the project's full test suite (`npm test` / `cargo test` / `pytest` / `go test ./...`).",
'**If tests fail**, report the failures and stop — the menu comes after a green suite:'],
'gate': ['git show <base-branch>:CLAUDE.md', 'all hold:', 'Step 1 tests passed;',
'the branch is named (detached HEAD always gets the menu);',
"this session ran the review chain on `REVIEWED_OID` and it passed (a fresh or resumed session with no such record gets the menu);",
'the `Finish branch:` value is one of the three recognised values above.',
'No line, a failed condition, or any other value gets the menu below.',
"Record the exact commit from the passed review's evidence, not a later branch tip, at this gate:",
'If the feature branch no longer points at `REVIEWED_OID`, stop and ask;',
'Keep this OID fixed through integration.',
'`merge locally` skips the push; `merge and push` pushes at g; `merge locally; ask before push` asks at g.',
'The main checkout is used only for the final ff-only update at g.',
'`<test command>` means the same full suite used in Step 1.'],
'a': ['If either command fails, stop and ask; nothing is merged yet.'],
'b': ["The enumeration must succeed and be empty. Otherwise stop and ask, listing those commits: push all, or don't push.",
'A failed enumeration stays stopped until it succeeds; an answer cannot authorise unknown commits.',
'This base and these commits are approved for both d and f; do not ask again for the same commits.',
'For `merge locally`, this approval includes them locally but does not authorise a push.'],
'c': ['If creation fails, stop and ask.', 'If it changed, stop and ask for review of the new tip.',
'A conflict or any other merge failure: abort in that worktree, then the menu.',
'If abort fails, report that too and leave the worktree for investigation.', 'Never push a merge resolved by hand.'],
'd': ['`MERGED` must equal `REVIEWED_OID` (fast-forward) or have parents exactly `INTEGRATION_BASE` and `REVIEWED_OID`, in that order. Otherwise stop and ask.',
'If any validation command fails or the trees differ, stop and ask;'],
'e': ['then run the tests in that temporary worktree:',
'If the merged tests fail or the recorded HEAD or tracked tree changed, stop; nothing has been pushed.',
'A passing suite in the main checkout does not satisfy this step.'],
'f': ['If either enumeration fails, stop and ask.',
'Every outgoing commit must be `MERGED`, in `PUSH_ALL` from b, or in `REVIEWED_COMMITS`:',
"If any other commit is listed, stop and ask, listing them: push all, or don't push.",
'An answer here does not waive the review, tree or test gates.'],
'g': ['Under `merge locally; ask before push`, ask push or not here; an answer already given at b or f is that answer.',
'`merge locally` skips the push. Otherwise push the tested OID, once:',
'A rejected push is reported, never retried with force.',
'If removal is refused, stop and report the path; never force removal.',
'If the checks or fast-forward fail, leave the main checkout in place and say so.',
'For `merge locally`, or a declined push, stop and ask: the result has not landed.',
"Never switch the main checkout's branch or reset its work."],
'tail': ['On any earlier stop, keep the feature branch and report temporary worktree paths;',
'Keep the feature branch until the push is settled (or, for local-only work, the ff-only update succeeded).',
'Delete it only when no question remains and it still points at `REVIEWED_OID`; preserve any newer feature work.',
'The line authorizes `git push` only.'],
}
def sections(s):
    gate = s.index('## Step 4:')
    start = s.index('- **a.**', gate)
    end = s.index('On any earlier stop,', start)
    chunks = re.split(r'- \*\*([a-g])\.\*\*', s[start:end])
    assert chunks[1::2] == list('abcdefg'), 'lettered steps must be a-g, in order'
    return {'initial': s[:gate], 'gate': s[gate:start], 'tail': s[end:], **dict(zip(chunks[1::2], chunks[2::2]))}
def code(section):
    return [ '\n'.join(line[2:] if line.startswith('  ') else line for line in b.splitlines()).strip()
             for b in re.findall(r'```bash\n(.*?)```', section, re.S) ]
def validate(s):
    errors = []
    try:
        parts = sections(s)
    except (ValueError, AssertionError) as e:
        return [str(e)], {}
    actual = {k: code(parts[k]) for k in blocks}
    for k, expected in blocks.items():
        if actual[k] != expected:
            errors.append(f'command/order pin: {k}')
    for k, expected in pins.items():
        flat = ' '.join(parts[k].split())
        errors.extend(f'stop/gate pin: {k}: {p}' for p in expected if p not in flat)
    return errors, actual
errors, actual = validate(text)
if errors:
    print('\n'.join('FAIL '+e for e in errors))
    sys.exit(1)
print(f'OK   pins: {sum(map(len, blocks.values()))} command blocks; {sum(map(len, pins.values()))} stop/gate clauses')
if os.environ.get('FINISH_MUTANT'):
    sys.exit(0)
mutants = []
# Delete each command line, not just entire blocks. Match within its own step.
for k, bs in blocks.items():
    for i, b in enumerate(bs):
        for j, line in enumerate(b.splitlines()):
            if not line.strip() or line.strip() in ('fi', 'done'):
                continue
            part = sections(text)[k]
            match = list(re.finditer(r'```bash\n(.*?)```', part, re.S))[i]
            raw = match[1]
            lines = raw.splitlines(keepends=True)
            changed = ''.join(lines[:j]+lines[j+1:])
            mutant = text.replace(part, part[:match.start(1)]+changed+part[match.end(1):], 1)
            mutants.append((f'delete {k}.{i} command {j+1}', mutant))
            # A valid shell command that reports success without doing the work.
            weak = lines[j].replace('git ', 'echo ', 1) if 'git ' in line else lines[j].replace('test ', 'true ', 1)
            if weak != lines[j]:
                changed = ''.join(lines[:j]+[weak]+lines[j+1:])
                mutant = text.replace(part, part[:match.start(1)]+changed+part[match.end(1):], 1)
                mutants.append((f'weaken {k}.{i} command {j+1}', mutant))
# Delete each stop sentence; weaken its requirement independently.
for k, ps in pins.items():
    for p in ps:
        part = sections(text)[k]
        match = re.search(r'\s+'.join(re.escape(x) for x in p.split()), part)
        assert match, p
        for replacement in ('', 'Optional: continue.'):
            mutant = text.replace(part, part[:match.start()]+replacement+part[match.end():], 1)
            mutants.append((f'{"delete" if not replacement else "weaken"} {k}: {p}', mutant))
for old, new in [('all hold:', 'at least one holds:'), ('then run the tests', ''), ('then run the tests', 'then inspect the tests'),
                 ('run the tests', ''), ('&&', ';'), ('--ff-only', '--no-edit'),
                 ('core.hooksPath=/dev/null', 'core.hooksPath=.git/hooks'),
                 ('parents exactly', 'parents including')]:
    assert old in text
    mutants.append((f'weaken {old}', text.replace(old, new)))
# Tests must stay after validation and before publication; swapping e/f is also forbidden.
parts = sections(text)
mutants.append(('swap e and f', text.replace(parts['e'], '\0').replace(parts['f'], parts['e']).replace('\0', parts['f'])))
for name, mutant in mutants:
    assert mutant != text, f'no-op mutant: {name}'
    assert validate(mutant)[0], f'MUTANT PASSED: {name}'
print(f'OK   mutants: {len(mutants)} caught; 0 survived (includes all hold, run the tests, initial test stop)')
with open(sys.argv[2], 'w') as out:
    out.write('declare -A CODE\n')
    for k, bs in actual.items():
        for i, b in enumerate(bs):
            b = b.replace('<base-branch>', 'main').replace('<feature-branch>', 'feat')
            b = b.replace('<main-checkout>', '"$MAIN_ROOT"').replace('<test command>', 'bash t.sh')
            b = b.replace('<reviewed-commit>', '$REVIEW_RECORD')
            out.write(f'CODE[{k}.{i}]={shlex.quote(b)}\n')
PY
[ -n "${FINISH_MUTANT:-}" ] && exit 0
source "$T/steps.sh"
fail=0; cases=0
ok() { echo "OK   $1"; }
bad() { echo "FAIL $1"; tail -30 "$CASE_DIR/commands.log"; [ ! -f "$CASE_DIR/control.log" ] || tail -30 "$CASE_DIR/control.log"; fail=$((fail+1)); }
check() { cases=$((cases+1)); if eval "$2"; then ok "$1"; else bad "$1 (result: $r)"; fi; }
# All Git state, hooks and remotes belong to this mktemp fixture, never the fork.
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_ATTR_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t GIT_TERMINAL_PROMPT=0
unset GIT_DIR GIT_COMMON_DIR GIT_WORK_TREE GIT_INDEX_FILE
mk() {
  CASE_DIR="$T/$1"; export CASE_DIR TMPDIR="$T/$1"
  mkdir -p "$CASE_DIR"
  git init -q --bare -b main "$CASE_DIR/origin.git"
  git init -q -b main "$CASE_DIR/repo"
  MAIN_ROOT="$CASE_DIR/repo"; export MAIN_ROOT
  cd "$MAIN_ROOT"
  git remote add origin "$CASE_DIR/origin.git"
  echo base > f
  echo 'git rev-parse HEAD > "$CASE_DIR/tested"' > t.sh
  git add -A; git commit -qm base; git push -q -u origin main
  ANSWER_B=; ANSWER_G=; MODE='merge and push'; AFTER=; INJECT=:
  FAIL_ENUM=; : > "$CASE_DIR/commands.log"
}
commit() { echo "$1" > "$1"; git add -A; git commit -qm "$1"; }
branch() {
  git worktree add -q -b feat "$CASE_DIR/feature"
  cd "$CASE_DIR/feature"; commit feat1
  REVIEW_RECORD=$(git rev-parse HEAD)
}
moved() {
  git clone -q "$CASE_DIR/origin.git" "$CASE_DIR/other"
  (cd "$CASE_DIR/other"; commit remote1; git push -q origin main)
}
otip() { git --git-dir="$CASE_DIR/origin.git" rev-parse main; }
main_tip() { git -C "$MAIN_ROOT" rev-parse HEAD; }
no_push() { ! grep -q '^command g.0$' "$CASE_DIR/commands.log"; }
no_temps() { [ "$(git worktree list --porcelain | grep -c '^worktree ')" = 2 ]; }
# Each step executes SKILL.md's blocks verbatim; only prose decisions and
# fixture answers live here. The trace records exact commands and exit codes.
run() {
  local rc=0
  printf 'command %s\n%s\n' "$1" "${CODE[$1]}" >> "$CASE_DIR/commands.log"
  eval "${CODE[$1]}" >> "$CASE_DIR/commands.log" 2>&1 || rc=$?
  echo "exit=$rc" >> "$CASE_DIR/commands.log"
  return "$rc"
}
ask() { echo "ask:$1"; return 1; }
step_a() { run a.0 || ask a; }
step_b() {
  run b.0 || { ask b; return 1; }
  if ! run b.1; then
    echo ask:b
    [ "$ANSWER_B" = 'push all' ] || return 1
    run b.2 || return 1
    PUSH_ANSWER=yes
  fi
}
step_c() {
  run c.0 || { ask c; return 1; }
  printf '%s\n' "$INTEGRATION" > "$CASE_DIR/integration"
  run c.1 || { ask c; return 1; }
  if ! run c.2; then
    run c.3 || echo abort:failed
    echo menu:c; return 1
  fi
}
step_d() {
  run d.0 && run d.1 || { ask d; return 1; }
  printf '%s\n' "$MERGED" > "$CASE_DIR/merged"
}
step_e() { run e.0 && run e.1 && run e.2 || { echo stop:e; return 1; }; }
step_f() { run f.0 && run f.1 || { ask f; return 1; }; }
step_g() {
  local push=no
  if [ "$MODE" != 'merge locally' ]; then
    push=yes
    if [ "$MODE" = 'merge locally; ask before push' ] && [ "$PUSH_ANSWER" != yes ]; then
      echo ask:g
      case "$ANSWER_G" in yes) ;; no) push=no;; *) return 1;; esac
    fi
  fi
  if [ "$push" = yes ]; then run g.0 && echo push || echo rejected; fi
  run g.1 || { echo stop:g; return 1; }
  if run g.2 && run g.3; then
    echo main:updated
  else
    echo main:kept
    if [ "$push" = no ]; then ask g; return 1; fi
  fi
}
finish() (
  PUSH_ANSWER=
  # The fixture supplies this session's passed review record; never resolve it again.
  run gate.0 && run gate.1 || { echo ask:gate; exit 0; }
  # Failed enumeration is a fault at the Git boundary, not an alternate rule.
  git() {
    if [ "${1:-}" = rev-list ] && [ "${2:-}" = "$FAIL_ENUM" ]; then return 128; fi
    command git "$@"
  }
  for letter in a b c d e f g; do
    "step_$letter" || exit 0
    if [ "$AFTER" = "$letter" ]; then "$INJECT"; fi
  done
)
# a-g: clean finish, same tested/pushed OID, only the final main update.
mk clean; branch; r=$(finish)
check 'a-g clean finish tests and pushes reviewed OID' '[ "$r" = $'"'"'push\nmain:updated'"'"' ] && [ "$(otip)" = "$REVIEW_RECORD" ] && [ "$(cat "$CASE_DIR/tested")" = "$(otip)" ] && [ "$(main_tip)" = "$(otip)" ] && no_temps'
# b: held commits on either side of the feature cut require an answer.
mk precut; commit held; branch; o=$(otip); r=$(finish)
check 'b held pre-cut base commit asks' '[ "$r" = ask:b ] && [ "$(otip)" = "$o" ] && no_push'
mk postcut; branch; (cd "$MAIN_ROOT"; commit held); o=$(otip); r=$(finish)
check 'b held post-cut base commit asks' '[ "$r" = ask:b ] && [ "$(otip)" = "$o" ] && no_push'
# gate/c: both pre-gate and mid-integration feature changes invalidate the review.
mk advanced; branch; commit unreviewed; o=$(otip); r=$(finish)
check 'gate feature advanced after review asks' '[ "$r" = ask:gate ] && [ "$(otip)" = "$o" ] && no_push'
mk midreview; branch; o=$(otip); AFTER=a; INJECT=advance_feature
advance_feature() { commit unreviewed; }
r=$(finish)
check 'c feature advanced after the gate asks' '[ "$r" = ask:c ] && [ "$(otip)" = "$o" ] && no_push'
# c/d: prove the real hook amends with both parents, then prove hooks are disabled.
mk hook; branch; moved; git config merge.ff false
cat > "$MAIN_ROOT/.git/hooks/post-merge" <<'HOOK'
#!/usr/bin/env bash
set -eu
echo fired >> "$CASE_DIR/hook-fired"
echo unreviewed > hook.txt
git add hook.txt
# Git 2.43 still exposes MERGE_HEAD while post-merge runs.
git merge --quit
git -c core.hooksPath=/dev/null commit --amend --no-edit -q
HOOK
chmod +x "$MAIN_ROOT/.git/hooks/post-merge"
git fetch -q origin
git worktree add -q --detach "$CASE_DIR/control" origin/main
git -C "$CASE_DIR/control" merge --no-edit "$REVIEW_RECORD" > "$CASE_DIR/control.log" 2>&1
control=$(git -C "$CASE_DIR/control" rev-parse HEAD)
check 'c control hook really amends while preserving both parents' '[ -f "$CASE_DIR/hook-fired" ] && [ "$(git rev-list --parents -n1 "$control")" = "$control $(git rev-parse origin/main) $REVIEW_RECORD" ] && git cat-file -e "$control:hook.txt"'
git worktree remove "$CASE_DIR/control"; rm "$CASE_DIR/hook-fired"
r=$(finish)
check 'c-d-g post-merge amendment hook is neutralised with merge.ff=false' '[ "$r" = $'"'"'push\nmain:updated'"'"' ] && [ ! -e "$CASE_DIR/hook-fired" ] && ! git cat-file -e "$(otip):hook.txt" 2>/dev/null && [ "$(cat "$CASE_DIR/tested")" = "$(otip)" ] && no_temps'
# d: a deliberately amended result passes the parents but must fail the tree check.
mk tree; branch; moved; AFTER=c; INJECT=amend_tree; o=$(otip)
amend_tree() {
  (cd "$INTEGRATION"; echo injected > injection; git add injection; git -c core.hooksPath=/dev/null commit --amend --no-edit -q)
}
r=$(finish)
check 'd matching parents with a different tree asks' '[ "$r" = ask:d ] && [ "$(otip)" = "$o" ] && no_push && grep -q "command d.1" "$CASE_DIR/commands.log"'
# e/g: a main-checkout fix during tests cannot mask a failing integration tree.
mk race; branch
cat >> t.sh <<'TEST'
printf 'new main work\n' > "$MAIN_ROOT/racer"
git -C "$MAIN_ROOT" add racer
git -C "$MAIN_ROOT" commit -qm racer
[ ! -e racer ]
TEST
git add t.sh; git commit -qm race-test; REVIEW_RECORD=$(git rev-parse HEAD); r=$(finish)
check 'e-g concurrent main commit cannot change the tested/pushed result' '[ "$r" = $'"'"'push\nmain:kept'"'"' ] && [ "$(otip)" = "$REVIEW_RECORD" ] && [ "$(cat "$CASE_DIR/tested")" = "$(otip)" ] && [ "$(git -C "$MAIN_ROOT" log -1 --format=%s)" = racer ] && no_temps'
# a/c/g: remote advance becomes the integration base; local main ff update happens last.
mk ahead; moved; git fetch -q origin
# Feature descends from the newer remote, so integration and main updates both fast-forward.
git worktree add -q -b feat "$CASE_DIR/feature" origin/main
cd "$CASE_DIR/feature"; commit feat1; REVIEW_RECORD=$(git rev-parse HEAD); r=$(finish)
check 'a-c-g origin ahead fast-forwards without changing inputs' '[ "$r" = $'"'"'push\nmain:updated'"'"' ] && [ "$(otip)" = "$REVIEW_RECORD" ] && [ "$(main_tip)" = "$REVIEW_RECORD" ] && no_temps'
# a/b/f: missing refs and failed enumerations are never empty allow-lists.
mk missing; branch; git --git-dir="$CASE_DIR/origin.git" update-ref -d refs/heads/main; git update-ref -d refs/remotes/origin/main; r=$(finish)
check 'a missing origin ref asks' '[ "$r" = ask:a ] && no_push'
mk enumeration; branch; o=$(otip); FAIL_ENUM="$o..$(main_tip)"; ANSWER_B='push all'; r=$(finish)
check 'b failed enumeration asks even with a push-all answer' '[ "$r" = ask:b ] && [ "$(otip)" = "$o" ] && no_push'
mk outgoing; branch; o=$(otip); AFTER=e; INJECT=fail_outgoing
fail_outgoing() { FAIL_ENUM="$ORIGIN..$MERGED"; }
r=$(finish)
check 'f failed outgoing enumeration asks' '[ "$r" = ask:f ] && [ "$(otip)" = "$o" ] && no_push'
# c: divergent edits abort in the temporary worktree, leaving main untouched.
mk conflict; branch; echo feature > f; git commit -qam feature-edit; REVIEW_RECORD=$(git rev-parse HEAD); m=$(main_tip)
moved; (cd "$CASE_DIR/other"; echo remote > f; git commit -qam clash; git push -q origin main); o=$(otip); r=$(finish)
check 'c conflict aborts to the menu' '[ "$r" = menu:c ] && [ "$(otip)" = "$o" ] && [ "$(main_tip)" = "$m" ] && ! git -C "$(cat "$CASE_DIR/integration")" rev-parse -q --verify MERGE_HEAD >/dev/null && no_push'
# e: a failure introduced by the combination of base and feature stops publication.
mk redtest; branch; echo '[ ! -e remote1 ]' >> t.sh; git commit -qam merged-test; REVIEW_RECORD=$(git rev-parse HEAD); bash t.sh
moved; o=$(otip); r=$(finish)
check 'e failed merged suite stops before push' '[ "$r" = stop:e ] && [ "$(otip)" = "$o" ] && no_push'
# b/d/f/g: the approved local tip is parent 1; its held commits need no second question.
mk pushall; branch; (cd "$MAIN_ROOT"; commit held); held=$(main_tip); ANSWER_B='push all'; MODE='merge locally; ask before push'; r=$(finish)
check 'b-d-f-g push all on a non-ff merge is not re-asked' '[ "$r" = $'"'"'ask:b\npush\nmain:updated'"'"' ] && [ "$(git rev-list --parents -n1 "$(otip)")" = "$(otip) $held $REVIEW_RECORD" ] && no_temps'
# g: local-only mode lands via ff-only; push confirmation is asked at publication.
mk local; branch; o=$(otip); MODE='merge locally'; r=$(finish)
check 'g merge locally lands without a push' '[ "$r" = main:updated ] && [ "$(otip)" = "$o" ] && [ "$(main_tip)" = "$REVIEW_RECORD" ] && no_push && no_temps'
mk decline; branch; o=$(otip); MODE='merge locally; ask before push'; ANSWER_G=no; r=$(finish)
check 'g declined push still lands locally' '[ "$r" = $'"'"'ask:g\nmain:updated'"'"' ] && [ "$(otip)" = "$o" ] && [ "$(main_tip)" = "$REVIEW_RECORD" ] && no_push && no_temps'
mk confirm; branch; MODE='merge locally; ask before push'; ANSWER_G=yes; r=$(finish)
check 'g asks before pushing when no prior answer exists' '[ "$r" = $'"'"'ask:g\npush\nmain:updated'"'"' ] && [ "$(otip)" = "$REVIEW_RECORD" ] && no_temps'
mk dirty; branch; m=$(main_tip); echo dirty > "$MAIN_ROOT/f"; MODE='merge locally'; r=$(finish)
check 'g local-only dirty main is preserved and asks' '[ "$r" = $'"'"'main:kept\nask:g'"'"' ] && [ "$(main_tip)" = "$m" ] && [ "$(cat "$MAIN_ROOT/f")" = dirty ] && no_push && no_temps'
mk otherbranch; branch; git -C "$MAIN_ROOT" checkout -qb other; m=$(main_tip); r=$(finish)
check 'g main on another branch is left in place' '[ "$r" = $'"'"'push\nmain:kept'"'"' ] && [ "$(git -C "$MAIN_ROOT" branch --show-current)" = other ] && [ "$(main_tip)" = "$m" ] && no_temps'
mk rejected; branch; AFTER=f; INJECT=moved; r=$(finish)
check 'g rejected push is attempted once without force' '[ "$r" = $'"'"'rejected\nmain:updated'"'"' ] && [ "$(grep -c "^command g.0$" "$CASE_DIR/commands.log")" = 1 ] && [ "$(git --git-dir="$CASE_DIR/origin.git" log -1 --format=%s)" = remote1 ] && no_temps'
echo "finishing: $cases cases; $((cases-fail)) passed; $fail failed"
[ "$fail" -eq 0 ] && echo 'finishing: OK'
exit "$fail"
