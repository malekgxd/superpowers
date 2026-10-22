# Architectural Path

Part of superpowers:brainstorming. Read it before checklist step 2, and
again before steps 4, 6, 8 and 9.

## Checklist Detail

1. **Explore project context** — check files, docs, recent commits
2. **Write the intent** — before any design question, approach, or design (one purpose question may come first): write `docs/superpowers/intents/YYYY-MM-DD-<topic>.md` using the Intent template below, present it, and STOP. Its Open questions heading holds question round 1 in the round format (step 4), each question with your recommended answer; round 1 always asks their time budget for the work and any fact only they know that the design depends on. One reply ("accept, all recommended", or edits) accepts the intent and settles the round: record the rulings under Open questions, set `Status: accepted`, and commit it. Nothing downstream starts before that commit. A heading with nothing to say gets one line saying so ("None known."); never drop a heading.
3. **Offer the visual companion just-in-time** — NOT upfront. The first time a question would genuinely be clearer shown than described, offer it then (its own message); on approval its browser tab opens for you. If no visual question ever arises, never offer it. See SKILL.md's Visual Companion section.
4. **Later question rounds** — ask only questions the round 1 answers opened; none means go straight to step 5. The frontier is every question whose prerequisites are already settled. Ask the whole frontier in one numbered message, each question with your recommended answer. A question that depends on another still open in this round waits for the next round. Facts are your job: anything answerable from the repo or the environment is looked up (dispatch `subagent_type: Explore`, `model: sonnet` when it is more than a grep), never asked. Done when the frontier is empty and nothing is silently assumed. Round format:

   ```
   ❓ **Q1** - **<title>**: <question, options if any>
   ➡️ <your recommended answer>
   ---
   ❓ **Q2** - ...
   ```
5. **Present the design** — one message, in this order: the 2-3 ways to build it with trade-offs, one line or a short bullet each, recommended first; the design for the recommended way; a "Calls I made" list (decisions you took without asking, including the execution method: subagent-driven unless they answer "native"). A reply naming another way gets the design redone for it; "ok" approves. STOP until then.
6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` with the header line `Intent: <path to the accepted intent file>`, and commit
7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below); also every Constraint in the intent is satisfied by the spec or explicitly waived with a reason
8. **Builder check** — dispatch a fresh subagent with `builder-check-prompt.md`; sort its questions; stop only when the "theirs" pile is not empty, and then bring only those questions, in one message headed "Questions only you can answer:" (see The Written Design: Details)
9. **Challenge the spec** — if a `challenge` skill is installed, invoke it on the committed spec with the intent path in its brief; rule on every finding and Flag, record the rulings in the spec under a `## Challenge rulings` heading, add `Challenge: YYYY-MM-DD <verdict>` to the spec header (before its first `## ` heading) — map the challenge verdict to the field — "holds" → `holds`, "holds with conditions" → `holds-with-conditions`, "broken" with every finding and Flag ruled → `broken-ruled` (a "broken" verdict with unruled findings may not be recorded) — commit. Stop for your human partner only when a ruling would change the intent's scope or needs a fact only they have; otherwise rule, record, and go on
10. **Transition to implementation** — send your human partner the spec path and the "Calls I made" list in one message that does not wait (see Handing it over), then invoke writing-plans skill to create implementation plan

## Intent Template

Exactly these five H2 headings, this order:

```markdown
# Intent: <topic>
Author: <who asked>. Status: draft

## Problem
<what hurts, from the asker's perspective>

## Proposed outcome
<what is true when this is done>

## Affected users and systems
<who and what this touches>

## Constraints
<what the design must respect; the challenger checks the spec against these>

## Open questions
<question round 1 in the round format (step 4), each with your recommended answer; always their time budget for the work; on accept, the rulings>
```

## Process Flow

```dot
digraph brainstorming {
    "Size: quick / spike / bounded / architectural" [shape=diamond];
    "Do it; say what you did" [shape=doublecircle];
    "Present question + probe (2-3 sentences)" [shape=box];
    "Ask clarifying questions (bounded)" [shape=box];
    "Present short design in chat" [shape=box];
    "Human approves?" [shape=diamond];
    "Investigate; report recommendation" [shape=doublecircle];
    "Implement via normal workflow (no plan doc)" [shape=doublecircle];
    "Explore project context" [shape=box];
    "Write intent with question round 1;\nhuman accepts?" [shape=diamond];
    "Commit accepted intent" [shape=box];
    "Ask in frontier rounds" [shape=box];
    "Challenge the spec" [shape=box];
    "Present the design message\n(approaches, design, Calls I made)" [shape=box];
    "User approves design?" [shape=diamond];
    "Write design doc" [shape=box];
    "Spec self-review\n(fix inline)" [shape=box];
    "Builder check\n(bring 'theirs' pile)" [shape=box];
    "Ask only the 'theirs' questions;\nupdate spec, commit" [shape=box];
    "Invoke writing-plans skill" [shape=doublecircle];
    "Hidden complexity? Upgrade path" [shape=box];

    "Size: quick / spike / bounded / architectural" -> "Do it; say what you did" [label="quick"];
    "Size: quick / spike / bounded / architectural" -> "Present question + probe (2-3 sentences)" [label="spike"];
    "Size: quick / spike / bounded / architectural" -> "Ask clarifying questions (bounded)" [label="bounded"];
    "Size: quick / spike / bounded / architectural" -> "Explore project context" [label="architectural"];
    "Present question + probe (2-3 sentences)" -> "Human approves?";
    "Ask clarifying questions (bounded)" -> "Present short design in chat";
    "Present short design in chat" -> "Human approves?";
    "Human approves?" -> "Investigate; report recommendation" [label="spike: yes"];
    "Human approves?" -> "Implement via normal workflow (no plan doc)" [label="bounded: yes"];
    "Hidden complexity? Upgrade path" -> "Size: quick / spike / bounded / architectural";
    "Explore project context" -> "Write intent with question round 1;\nhuman accepts?";
    "Write intent with question round 1;\nhuman accepts?" -> "Write intent with question round 1;\nhuman accepts?" [label="no, revise"];
    "Write intent with question round 1;\nhuman accepts?" -> "Commit accepted intent" [label="yes"];
    "Commit accepted intent" -> "Ask in frontier rounds" [label="answers opened questions"];
    "Commit accepted intent" -> "Present the design message\n(approaches, design, Calls I made)" [label="none opened"];
    "Ask in frontier rounds" -> "Present the design message\n(approaches, design, Calls I made)";
    "Present the design message\n(approaches, design, Calls I made)" -> "User approves design?";
    "User approves design?" -> "Present the design message\n(approaches, design, Calls I made)" [label="another way: redo"];
    "User approves design?" -> "Write design doc" [label="yes"];
    "Write design doc" -> "Spec self-review\n(fix inline)";
    "Spec self-review\n(fix inline)" -> "Builder check\n(bring 'theirs' pile)";
    "Builder check\n(bring 'theirs' pile)" -> "Challenge the spec" [label="no 'theirs' questions"];
    "Builder check\n(bring 'theirs' pile)" -> "Ask only the 'theirs' questions;\nupdate spec, commit" [label="'theirs' pile"];
    "Ask only the 'theirs' questions;\nupdate spec, commit" -> "Challenge the spec";
    "Challenge the spec" -> "Invoke writing-plans skill" [label="rulings recorded"];
}
```

## The Process

The subsections below serve the bounded and architectural paths (a
spike stops at "present the probe, get a nod"). Sections from
**Exploring approaches** onward are architectural-path depth — for
bounded work, context, a few questions, and one short in-chat design
message (approaches on top) are the whole process.

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own intent → spec → challenge → plan → implementation cycle.
- Bounded path only: ask questions one at a time to refine the idea; only one question per message - if a topic needs more exploration, break it into multiple questions
- Architectural path: the intent's Open questions carry the first question round (checklist step 2); later rounds (step 4) ask only what those answers opened
- Open questions first; offer a short menu only when they're stuck (see The Conversation)
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Lay out 2-3 approaches with trade-offs at the top of the design message (see Lay Out the Approaches in [conversation.md](conversation.md))
- Lead with your recommended option and explain why
- YAGNI ruthlessly - remove unnecessary features from every approach and design

**Presenting the design:**

- Once you believe you understand what you're building, present the design in one message: the approaches, then the design for the recommended one, then the "Calls I made" list (checklist step 5)
- Scale each part to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Cover: architecture, components, data flow, error handling, testing
- A reply naming another way gets the design redone for it; "ok" approves
- Be ready to go back and clarify if something doesn't make sense

**Playing it back:**

- The intent is the first playback and the design message the second; no design-section chunks
- The intent is exempt from the visual companion: present it as text, never hold it back for the offer, and put no mockup beside it. The visual offer and mockups start after the intent is accepted and committed.

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## The Written Design: Details

**Documentation:**

- The spec's header carries the line `Intent: <path to the accepted intent file>` so the challenger and the plan can find it
- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
  - Outside a software repo, ask where it goes. User preferences for spec location override both.
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document to git

**Spec Self-Review:**
After writing the spec document, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.
5. **Intent check:** Every line under the intent's Constraints heading is either satisfied by the spec or explicitly waived in the spec with a reason. An unmentioned constraint is a gap; fix it.

Fix any issues inline. No need to re-review — just fix and move on.

**Builder check:** dispatch a fresh general-purpose subagent (`model: sonnet`)
with [builder-check-prompt.md](../builder-check-prompt.md). When you tell
your human partner you're writing it up, say a reviewer will read it
first and you may come back once with a few questions. Don't hand over
the document until the check is back. Sort what the builder asks into
three piles:

- **Answered already** by the conversation or the project: put the answer
  in the document.
- **Minor:** a sensible builder could settle it without changing what gets
  built. Settle it yourself and mark it in the document as your call.
- **Theirs:** only your human partner can answer it, and the answer changes
  what gets built.

If the "theirs" pile is empty, do not stop. Otherwise bring it in one
message under the heading "Questions only you can answer:", most
important first. Update the document with their answers and commit.
That's the only round of questions the check produces. Without a subagent tool, read
the document as that builder yourself.

**Handing it over:**
The written spec is not a review stop. After the challenge rulings are committed, send one message that does not wait, then go on to writing-plans:

> "The design is written up at `<path>`. Calls I made: <list>. I'm going on to the build plan; say if any of those calls is wrong."

If they answer with changes, make them and re-run the spec self-review, not the builder check.

**Challenge, then implementation:**

- If a `challenge` skill is installed, invoke it on the committed spec. Its brief carries four things: the one-sentence claim, the spec path, the intent path, and the settled constraints. Rule on every finding and Flag, record the rulings in the spec under a `## Challenge rulings` heading, add `Challenge: YYYY-MM-DD <verdict>` (`holds`, `holds-with-conditions` or `broken-ruled`) to the spec header (before its first `## ` heading), commit.
- Stop for your human partner only when a ruling would change the intent's scope or needs a fact only they have; otherwise rule, record, and go on. An answer that changes the picked approach means sending the design message again; any smaller change goes in the spec and its "Calls I made" list.
- Then invoke the writing-plans skill to create a detailed implementation plan
- Do NOT invoke any other skill. challenge (when installed) and then writing-plans are the only next steps.

