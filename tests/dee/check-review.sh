#!/usr/bin/env bash
set -euo pipefail
F="$(dirname "$0")/../../skills/requesting-code-review/code-reviewer.md"
fail=0
for s in 'Mysterious Name' 'Duplicated Code' 'Feature Envy' 'Data Clumps' 'Primitive Obsession' 'Repeated Switches' 'Shotgun Surgery' 'Divergent Change' 'Speculative Generality' 'Message Chains' 'Middle Man' 'Refused Bequest'; do
  grep -qF -- "**$s**" "$F" || { echo "MISSING: $s"; fail=1; }
done
grep -qF -- '**Smell baseline' "$F" || { echo "MISSING: heading"; fail=1; }
grep -qF -- 'A documented repo standard always wins' "$F" || { echo "MISSING: override rule"; fail=1; }
[ "$fail" -eq 0 ] && echo "review: OK"
exit $fail
