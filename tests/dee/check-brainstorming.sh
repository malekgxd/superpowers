#!/usr/bin/env bash
# Fork edit check: brainstorming carries the intent gate, frontier rounds, challenge handoff.
set -euo pipefail
F="$(dirname "$0")/../../skills/brainstorming/SKILL.md"
fail=0
need() { grep -qF -- "$1" "$F" || { echo "MISSING: $1"; fail=1; }; }
gone() { grep -qF -- "$1" "$F" && { echo "STILL PRESENT: $1"; fail=1; } || true; }
need '2. **Write the intent**'
need 'docs/superpowers/intents/YYYY-MM-DD-<topic>.md'
need '## Problem'
need '## Open questions'
need 'Status: accepted'
need '**Ask in frontier rounds**'
need 'Intent: <path to the accepted intent file>'
need 'invoke it on the committed spec'
need '"Commit accepted intent" -> "Ask in frontier rounds"'
need '"Challenge the spec" -> "Invoke writing-plans skill"'
need 'Bounded path only: ask questions one at a time'
gone 'Do NOT invoke any other skill. writing-plans is the next step.'
gone '3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria'
[ "$fail" -eq 0 ] && echo "brainstorming: OK"
exit $fail
