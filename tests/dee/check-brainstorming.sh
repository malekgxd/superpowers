#!/usr/bin/env bash
# Fork edit check: brainstorming carries the intent gate, frontier rounds, challenge handoff.
set -euo pipefail
F="${BRAINSTORM_SKILL_FILE:-$(dirname "$0")/../../skills/brainstorming/SKILL.md}"
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
need '2. **Write the intent** — before any design question'
gone '2. **Write the intent** — before any question, approach, or design'
need 'On the architectural path the intent file is this write-back'
need 'accepts and commits the intent'
need 'Written-spec approval only permits `challenge` and then writing-plans'
need 'record the rulings in the spec under a `## Challenge rulings` heading, add `Challenge: YYYY-MM-DD <verdict>`'
need '"holds with conditions" → `holds-with-conditions`, "broken" with every finding and Flag ruled → `broken-ruled` (a "broken" verdict with unruled findings may not be recorded)'
gone 'written-spec approval only permits invoking writing-plans'
for h in 'First: What Do You Actually Know?' 'Your First Message' 'The Conversation' 'Play It Back' 'Size the Work' 'The Written Design' 'Red Flags' 'Visual Companion'; do
  grep -qxF -- "## $h" "$F" || { echo "MISSING heading: $h"; fail=1; }
done
need '| Quick | the request itself | do it, say what you did |'
need 'architectural path the opt-out skips the questions, not the gates'
need '9. **Builder check**'
need '"Spec self-review\n(fix inline)" -> "Builder check\n(bring '"'theirs'"' pile)"'
need '"Builder check\n(bring '"'theirs'"' pile)" -> "User reviews spec?"'
need '"User reviews spec?" -> "Challenge the spec" [label="approved"]'
gone '"Spec self-review\n(fix inline)" -> "User reviews spec?"'
need 'the architectural check comes first'
need 'On the architectural path the intent is exempt'
need 'architectural path every gate above still holds'
gone 'If they opted out of the questions, the skill is done'
need '| "They said skip the questions, so the intent can go too" |'
need '- Quick: none; the request is the full description.'
need 'One question per message holds on spike and bounded, and on architectural until the intent is committed.'
need 'Anything answerable from the repo or the environment you look up yourself, never ask.'
need 'dispatch a fresh general-purpose subagent (`model: sonnet`)'
need 'On the architectural path this is the one purpose question allowed'
# Negative cases: each mutant of the real file must fail this check.
if [ -z "${BRAINSTORM_CHECK_MUTANT:-}" ]; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  mut() { perl -0pe "$1" "$F" > "$tmp/m.md"; BRAINSTORM_CHECK_MUTANT=1 BRAINSTORM_SKILL_FILE="$tmp/m.md" bash "$0" >/dev/null && { echo "MUTANT PASSED: $2"; fail=1; } || true; }
  mut 's/^.*"Builder check\\n\(bring .theirs. pile\)" -> "User reviews spec\?";\n//m' 'builder -> review edge deleted'
  mut 's/"Spec self-review\\n\(fix inline\)" -> "Builder check\\n\(bring .theirs. pile\)"/"Spec self-review\\n(fix inline)" -> "User reviews spec?"/' 'self-review -> review bypass restored'
  mut 's/^## Play It Back$/## Play it back/m' 'heading renamed'
  mut 's/ the architectural check comes first//' 'quick precedence dropped'
  mut 's/If they opted out of the questions on the spike or\nbounded path, the skill is done and the gate goes with it; on the\narchitectural path every gate above still holds\./If they opted out of the questions, the skill is done and the gate goes with it./' 'upstream opt-out restored in HARD-GATE'
fi
[ "$fail" -eq 0 ] && echo "brainstorming: OK"
exit $fail
