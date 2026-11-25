#!/usr/bin/env bash
# Fork edit check: the end review lives in requesting/receiving-code-review and verification; executing-plans only points at it.
set -euo pipefail
D="$(cd "$(dirname "$0")/../../skills" && pwd)"
fail=0
# check FILE then pins to need, after a "--" the pins that must be gone
run() {
  local f="$1"; shift
  local -a need=() gone=(); local mode=need
  for a in "$@"; do if [ "$a" = "--" ]; then mode=gone; elif [ $mode = need ]; then need+=("$a"); else gone+=("$a"); fi; done
  for s in "${need[@]}"; do grep -qF -- "$s" "$f" || { echo "MISSING in $f: $s"; fail=1; }; done
  for s in "${gone[@]}"; do ! grep -qF -- "$s" "$f" || { echo "STILL PRESENT in $f: $s"; fail=1; }; done
}
EP=('superpowers:requesting-code-review' 'superpowers:receiving-code-review' 'superpowers:verification-before-completion'
  'sdd-archive PLAN_FILE' 'End review, fixes and verification: see Final Review' 'when HEAD is past the last ledger line' 'never redo the work, restart a review or guess what a commit covers'
  'no ledger line records those commits, whatever their subjects say' 'A `Review done:` line: the end review is over, never start another' 'Only after that line exists, archive')
RC=('## Findings from the end review' 'model: fable' 'Reproduce each finding with a failing test or a command'
  'Groups that share a file are merged' 'does not delete, weaken or rewrite an existing test'
  'Neither the lead nor the fixers commit' '--base <reviewed commit>'
  'More than three rounds run only on your human partner'"'"'s say' 'with fewer than three fix rounds run: start the next round at item 1' 'IMPLEMENT: One item at a time, test each'
  'Where no subagent can be dispatched, you do items 1 to 4 yourself' 'Every finding left unfixed goes into the re-review'"'"'s focus text'
  'No finding reproduced: no fix commit and no re-review' 'Fix: reviewed <reviewed sha>`, commits the fixes as one commit' 'Review done: approve on <sha>' 'does not close it')
VC=('Run the normal full suite on the fix commit' 'scripts/old-tests <reviewed sha> <fix sha> -- <suite command>'
  'by its absolute path, from the working tree that holds the fix commit'
  'It prints `no test file changed`' 'exits 1 on any `REGRESSED`' 'Exit 3 is `UNVERIFIED`, not a pass'
  'Every `REGRESSED` line is fixed in a follow-up commit or listed with its reason'
  'one run against the real artifact' 'the manual steps are listed'
  'NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE')
check_all() {
  fail=0
  run "$EPF" "${EP[@]}" -- 'review-package' 'There is no second fix pass' 'minor (deferred)'
  run "$RCF" "${RC[@]}"
  run "$VCF" "${VC[@]}" -- 'git checkout <reviewed commit> --' 'git diff --name-status'
  [ -x "$D/verification-before-completion/scripts/old-tests" ] || { echo "MISSING: scripts/old-tests is not executable"; fail=1; }
  a=$(grep -nF -- '## Findings from the end review' "$RCF" | head -1 | cut -d: -f1)
  b=$(grep -nF -- '## The Response Pattern' "$RCF" | head -1 | cut -d: -f1)
  [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ] || { echo "ORDER: end-review section must precede The Response Pattern"; fail=1; }
  return $fail
}
EPF="${EP_SKILL:-$D/executing-plans/SKILL.md}"; RCF="${RC_SKILL:-$D/receiving-code-review/SKILL.md}"; VCF="${VC_SKILL:-$D/verification-before-completion/SKILL.md}"
if [ -z "${ENDREVIEW_MUTANT:-}" ]; then
  check_all || fail=1
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  mut() { # which-var file pin
    export PIN="$3"; cp "$2" "$tmp/m.md"; perl -0pi -e 's/\Q$ENV{PIN}\E/X/g' "$tmp/m.md"
    cmp -s "$2" "$tmp/m.md" && { echo "MUTANT NO-OP: $3"; fail=1; return; }
    ( export ENDREVIEW_MUTANT=1; export "$1=$tmp/m.md"; bash "$0" >/dev/null ) && { echo "MUTANT PASSED: $3"; fail=1; } || true
  }
  for s in "${EP[@]}"; do mut EP_SKILL "$EPF" "$s"; done
  for s in "${RC[@]}"; do mut RC_SKILL "$RCF" "$s"; done
  for s in "${VC[@]}"; do mut VC_SKILL "$VCF" "$s"; done
else
  check_all >/dev/null || exit 1
  exit 0
fi
[ "$fail" -eq 0 ] && echo "endreview: OK"
exit $fail
