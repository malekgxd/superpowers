#!/usr/bin/env bash
# Fork edit check: brainstorming carries the intent gate, frontier rounds, challenge handoff.
set -euo pipefail
# Since 7.0.1 the skill is SKILL.md (gates, under the 20,000-byte compaction cut) plus references/*.md (step detail).
D="${BRAINSTORM_SKILL_DIR:-$(dirname "$0")/../../skills/brainstorming}"
F="$D/SKILL.md"
SK=$(cat "$F" "$D"/references/*.md)
fail=0
need() { grep -qF -- "$1" <<<"$SK" || { echo "MISSING: $1"; fail=1; }; }
gone() { grep -qF -- "$1" <<<"$SK" && { echo "STILL PRESENT: $1"; fail=1; } || true; }
# Gates must survive compaction: they live in SKILL.md itself.
in_skill() { grep -qF -- "$1" "$F" || { echo "NOT IN SKILL.md: $1"; fail=1; }; }
[ "$(wc -c <"$F")" -lt 20000 ] || { echo "SKILL.md is $(wc -c <"$F") bytes, compaction cut is 20000"; fail=1; }
for s in '<HARD-GATE>' 'architectural path every gate above still holds' '| Quick | the request itself | do it, say what you did |' \
  '2. **Write the intent** — before any design question' '9. **Builder check**' '11. **Challenge the spec**' '12. **Transition to implementation**' \
  '**Terminal states are path-bound.**' 'read [references/architectural.md](references/architectural.md) before step 2'; do in_skill "$s"; done
in_skill 'before steps 4, 7, 9 and 11'
for l in $(grep -oE '\(references/[a-z-]+\.md\)' "$F" | tr -d '()' | sort -u); do [ -f "$D/$l" ] || { echo "SKILL.md points at missing $l"; fail=1; }; done
for r in architectural conversation; do grep -qF "(references/$r.md)" "$F" || { echo "SKILL.md never points at references/$r.md"; fail=1; }; done
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
for h in 'First: What Do You Actually Know?' 'Look Before You Ask' 'Your First Message' 'The Conversation' 'Play It Back' 'Size the Work' 'The Written Design' 'Red Flags' 'Visual Companion'; do
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
need '3. **Lay out the approaches** — a message of their own'
need '5. **Lay out the approaches** — a message of their own'
need '"Ask clarifying questions (bounded)" -> "Lay out approaches; partner picks (bounded)"'
need '- Bounded: the human partner picks an approach (its own message), then'
gone 'Write the design doc, short or full'
# Negative cases: each mutant of the real file must fail this check.
if [ -z "${BRAINSTORM_CHECK_MUTANT:-}" ]; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  # mut <file under the skill dir> <perl substitution> <description>; a no-op substitution counts as a failed mutant.
  mut() { rm -rf "$tmp/m"; cp -r "$D" "$tmp/m"; perl -0pi -e "$2" "$tmp/m/$1"; cmp -s "$D/$1" "$tmp/m/$1" && { echo "MUTANT NO-OP: $3"; fail=1; return; }
    BRAINSTORM_CHECK_MUTANT=1 BRAINSTORM_SKILL_DIR="$tmp/m" bash "$0" >/dev/null && { echo "MUTANT PASSED: $3"; fail=1; } || true; }
  mut references/architectural.md 's/^.*"Builder check\\n\(bring .theirs. pile\)" -> "User reviews spec\?";\n//m' 'builder -> review edge deleted'
  mut references/architectural.md 's/"Spec self-review\\n\(fix inline\)" -> "Builder check\\n\(bring .theirs. pile\)"/"Spec self-review\\n(fix inline)" -> "User reviews spec?"/' 'self-review -> review bypass restored'
  mut SKILL.md 's/^## Play It Back$/## Play it back/m' 'heading renamed'
  mut SKILL.md 's/ the architectural check comes first//' 'quick precedence dropped'
  mut SKILL.md 's/If they opted out of the questions on the spike or\nbounded path, the skill is done and the gate goes with it; on the\narchitectural path every gate above still holds\./If they opted out of the questions, the skill is done and the gate goes with it./' 'upstream opt-out restored in HARD-GATE'
  mut SKILL.md 's/^11\. \*\*Challenge the spec\*\*.*\n//m' 'challenge step dropped from SKILL.md checklist'
  mut SKILL.md 's/\(references\/conversation\.md\)/(references\/talk.md)/g' 'every conversation pointer broken'
  mut SKILL.md 's/before steps 4, 7, 9 and 11/before step 4/' 'architectural reload schedule cut'
  mut SKILL.md 's/\(references\/architectural\.md\)/(references\/arch.md)/g' 'every architectural pointer broken'
fi
[ "$fail" -eq 0 ] && echo "brainstorming: OK"
exit $fail
