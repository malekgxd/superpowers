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
  '2. **Write the intent** — before any design question' \
  '**Terminal states are path-bound.**' 'read [references/architectural.md](references/architectural.md) before step 2'; do in_skill "$s"; done
# Fewer questions (2026-10-22): intent carries round 1, one design message, no spec review stop. Each pin also gets a mutant below.
NEW_PINS=('- Architectural: the human partner accepts and commits the intent, then approves the design message; the spec is then written, builder-checked and challenged with no review stop'
  '- Bounded: the human partner approves the short in-chat design, which carries the approaches.'
  '5. **Present the design** — one message: the 2-3 ways to build it, the design for the recommended one, and a "Calls I made" list'
  '8. **Builder check** — stops only when it has questions only your human partner can answer'
  '9. **Challenge the spec**' '10. **Transition to implementation**' 'before steps 4, 6, 8 and 9'
  "the intent's Open questions hold the first question round" 'round 1 always asks their time budget for the work'
  '- the calls you made without asking, under a "Calls I made" heading'
  # Kept stops (final review I2): each must stay, deletion-tested below.
  'present it and STOP; one reply accepts it and settles the round' 'list that names the execution method; STOP for approval'
  "stops for your human partner only when a ruling would change the intent's scope or needs a fact only they have, otherwise rule, record, and go on"
  'in one message that does not wait, then invoke the writing-plans skill'
  'and any fact only they know that the design depends on. One reply accepts the intent and settles the round.'
  # Upstream 7.0.2 port: three first-message cases on spike and bounded, case 3 on bounded, ask only what changes the build.
  'On the spike and bounded paths:' 'with nothing to pick from' 'ask about the one that would change it most'
  'If nothing like that is open, end with the short design' 'a choice among ways to build it is not asked'
  "When nothing was open from the start, that is the first message's short design, approved once."
  '3. **Present short design in chat** — one message (when nothing was open from the start, your first message)'
  'Process steps are always your calls' 'looking further within the project' 'Look things up; offer recon'
  'pick a sensible place and say where'
  'On the bounded path the short in-chat design is the playback' 'Every path except Quick ends with your human partner approving'
  # Fix round 1: the question filter, case 1's ask-why condition, recon consent, and approvals are not filtered questions.
  'Ask a question only when the answer would change what gets built and neither the request nor the project answers it.'
  "If they haven't told you why they want it, even if you can guess, ask about that:"
  "In the repo or the environment, look freely; for their own files and data outside the project, or the web, offer to look, say what you'd look for, and wait for their yes."
  'This covers clarifying questions and routine process choices only: approval stops, intent acceptance, and the offer before recon outside the project are never yours to skip or decide.')
for s in "${NEW_PINS[@]}"; do in_skill "$s"; done
A="$D/references/architectural.md"
ARCH_PINS=("commit. Stop for your human partner only when a ruling would change the intent's scope or needs a fact only they have"
  "- Stop for your human partner only when a ruling would change the intent's scope or needs a fact only they have"
  'in one message headed "Questions only you can answer:"' 'under the heading "Questions only you can answer:"'
  'in one message that does not wait (see Handing it over)' 'send one message that does not wait, then go on to writing-plans'
  '"Size: quick / spike / bounded / architectural" -> "Present short design in chat" [label="bounded, nothing open"];'
  'pick a sensible place and say where')
for s in "${ARCH_PINS[@]}"; do grep -qF -- "$s" "$A" || { echo "NOT IN architectural.md: $s"; fail=1; }; done
for s in 'a message of their own' 'approval after each section' 'User reviews written spec' 'Written-spec approval only permits' \
  'picks an approach (its own message)' 'the intent file is already committed by the time the first round is asked' \
  'again before steps 4, 7, 9 and 11' 'reviews the written implementation plan and selects its execution method' \
  '"User reviews spec?"' '"Lay out approaches; partner picks'; do gone "$s"; done
need 'Define any term the first time you use it'
need '"Builder check\n(bring '"'"'theirs'"'"' pile)" -> "Challenge the spec"'
# Rulings most likely to regress at the next upstream merge (Opus round 1, 7.0.1).
gone 'Short or full, the design doc'; gone '| Size | The design doc |'
in_skill 'no plan document |'; in_skill 'leave the offer out'
# Upstream 7.0.2 port: bounded writes no plan; the design goes in a sensible place; the every-message one-question rule is gone.
gone 'go on to the plan'; gone 'ask where it goes'; gone 'Each such message ends with one question'
# Every markdown link inside references/ resolves.
for rf in "$D"/references/*.md; do for l in $(grep -oE '\]\([^)#: ]+\.md\)' "$rf" | sed 's/^](//; s/)$//' | sort -u); do [ -f "$(dirname "$rf")/$l" ] || { echo "$(basename "$rf") points at missing $l"; fail=1; }; done; done
for l in $(grep -oE '\(references/[a-z-]+\.md\)' "$F" | tr -d '()' | sort -u); do [ -f "$D/$l" ] || { echo "SKILL.md points at missing $l"; fail=1; }; done
for r in architectural conversation; do grep -qF "(references/$r.md)" "$F" || { echo "SKILL.md never points at references/$r.md"; fail=1; }; done
need '2. **Write the intent**'
need 'docs/superpowers/intents/YYYY-MM-DD-<topic>.md'
need '## Problem'
need '## Open questions'
need 'Status: accepted'
need '4. **Later question rounds**'
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
need 'record the rulings in the spec under a `## Challenge rulings` heading, add `Challenge: YYYY-MM-DD <verdict>`'
need '"holds with conditions" → `holds-with-conditions`, "broken" with every finding and Flag ruled → `broken-ruled` (a "broken" verdict with unruled findings may not be recorded)'
gone 'written-spec approval only permits invoking writing-plans'
for h in 'First: What Do You Actually Know?' 'Look Before You Ask' 'Your First Message' 'The Conversation' 'Play It Back' 'Size the Work' 'The Written Design' 'Red Flags' 'Visual Companion'; do
  grep -qxF -- "## $h" "$F" || { echo "MISSING heading: $h"; fail=1; }
done
need '| Quick | the request itself | do it, say what you did |'
need 'architectural path the opt-out skips the questions, not the gates'
need '"Spec self-review\n(fix inline)" -> "Builder check\n(bring '"'theirs'"' pile)"'
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
need '"Ask clarifying questions (bounded)" -> "Present short design in chat"'
gone 'Write the design doc, short or full'
# Negative cases: each mutant of the real file must fail this check.
if [ -z "${BRAINSTORM_CHECK_MUTANT:-}" ]; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  # mut <file under the skill dir> <perl substitution> <description>; a no-op substitution counts as a failed mutant.
  mut() { rm -rf "$tmp/m"; cp -r "$D" "$tmp/m"; perl -0pi -e "$2" "$tmp/m/$1"; cmp -s "$D/$1" "$tmp/m/$1" && { echo "MUTANT NO-OP: $3"; fail=1; return; }
    BRAINSTORM_CHECK_MUTANT=1 BRAINSTORM_SKILL_DIR="$tmp/m" bash "$0" >/dev/null && { echo "MUTANT PASSED: $3"; fail=1; } || true; }
  mut references/architectural.md 's/^.*"Builder check\\n\(bring .theirs. pile\)" -> "Challenge the spec".*\n//m' 'builder -> challenge edge deleted'
  mut references/architectural.md 's/"Spec self-review\\n\(fix inline\)" -> "Builder check\\n\(bring .theirs. pile\)"/"Spec self-review\\n(fix inline)" -> "User reviews spec?"/' 'self-review -> review bypass restored'
  mut SKILL.md 's/^## Play It Back$/## Play it back/m' 'heading renamed'
  mut SKILL.md 's/ the architectural check comes first//' 'quick precedence dropped'
  mut SKILL.md 's/If they opted out of the questions on the spike or\nbounded path, the skill is done and the gate goes with it; on the\narchitectural path every gate above still holds\./If they opted out of the questions, the skill is done and the gate goes with it./' 'upstream opt-out restored in HARD-GATE'
  mut SKILL.md 's/^9\. \*\*Challenge the spec\*\*.*\n//m' 'challenge step dropped from SKILL.md checklist'
  for s in "${NEW_PINS[@]}"; do export PIN="$s"; mut SKILL.md 's/\Q$ENV{PIN}\E/X/' "pin dropped: $s"; done
  for s in "${ARCH_PINS[@]}"; do export PIN="$s"; mut references/architectural.md 's/\Q$ENV{PIN}\E/X/' "pin dropped: $s"; done
  mut SKILL.md 's/\(references\/conversation\.md\)/(references\/talk.md)/g' 'every conversation pointer broken'
  mut SKILL.md 's/before steps 4, 6, 8 and 9/before step 4/' 'architectural reload schedule cut'
  mut SKILL.md 's/ and leave the offer out//' 'asked-for brainstorming still offers to skip'
  mut references/architectural.md 's/\(\.\.\/builder-check-prompt\.md\)/(builder-check-prompt.md)/' 'builder prompt path broken'
  mut SKILL.md 's/\| Bounded \| a short design, in chat \| build it through the normal workflow, no plan document \|/| Bounded | a short design doc | superpowers:writing-plans |/' 'bounded row turned into doc + plan'
  mut SKILL.md 's/\(references\/architectural\.md\)/(references\/arch.md)/g' 'every architectural pointer broken'
fi
[ "$fail" -eq 0 ] && echo "brainstorming: OK"
exit $fail
