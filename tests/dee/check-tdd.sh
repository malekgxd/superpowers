#!/usr/bin/env bash
set -euo pipefail
F="$(dirname "$0")/../../skills/test-driven-development/SKILL.md"
fail=0
need() { grep -qF -- "$1" "$F" || { echo "MISSING: $1"; fail=1; }; }
need '## Seams: where tests go'
need 'Test only at pre-agreed seams.'
need '| **Tautological** |'
# the seams section must precede the loop
[ "$(grep -n '## Seams: where tests go' "$F" | cut -d: -f1)" -lt "$(grep -n '## Red-Green-Refactor' "$F" | cut -d: -f1)" ] || { echo "ORDER: seams after loop"; fail=1; }
[ "$fail" -eq 0 ] && echo "tdd: OK"
exit $fail
