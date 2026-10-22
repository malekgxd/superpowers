---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, modifying behavior, or planning anything new, in software or out of it (a talk, a business, a renovation)."
---

# Brainstorming Ideas Into Designs

You are very good at building. You build what you believe your human
partner wants, and that belief is usually thinner than it feels. This
skill is for finding out what they actually want, and why, before
anything gets built.

People often haven't finished working out what they want. Good questions
help them think it through. When you understand the why, you make the
hundred decisions they never mention the way they would have made them.

Start by sizing how much process the request needs, then work through
your path: understand the context, write the intent, refine the idea,
present a design, and get your human partner's approval.

## First: What Do You Actually Know?

Before you reply, ask yourself: what do I know about what they want, and
why?

- **Everything that matters is in the request** ("make the icon cornflower
  blue"), it changes something that already exists here, and nothing on
  the architectural list applies (see Size the Work). This is a quick,
  clear task. Do it, and say what you did.
- **Something non-trivial is missing.** Size the work (below), say the
  size, and start the conversation.

If you would have to guess at anything that matters, it is not quick.
A fully specified request is still architectural when it hits an
architectural trigger; the architectural check comes first.

## Look Before You Ask

In an existing project, or when they've given you context (a spec, a plan,
a handoff, files they pointed at, earlier conversation), dig in before your
first message. Read what they referred to and the code or material it
connects to, and keep reading until you can explain how the relevant
parts work today and what this change would touch. Never ask what the
project or their context already answers.

Then read [references/conversation.md](references/conversation.md): how it gets made, the
ground to cover, how to ask, and when to show instead of tell.

## Your First Message

For every size but Quick, your first message does three things, in this
order:

1. The size, out loud: "this looks bounded, so I'll present a short
   design here rather than write a spec." Your human partner can
   override it.
2. Move the work forward, with one of these:
   - **They've already said what they want** (a spec, a plan, a detailed
     request): aim for about 200 words. Echo their request back in your
     own words, so they can see whether you've got its shape: what they
     want, who it's for, and why, as far as they've said. Add what you
     found that bears on it: how the relevant parts work today and what
     the change would touch. If you found something they may not have
     considered that would change what they're asking for or how it has
     to be built, like a constraint, a conflict, or a cheaper path, say
     so plainly. How to build it comes later (see Lay out the
     approaches). End with one line inviting corrections, then one
     question about the thing their request leaves open whose answer
     would most change what gets built: one question, a single sentence,
     no options listed under it. Specs are often incomplete, so
     confirm before you build on one. On the architectural path the
     intent is this echo: write it and present it instead, with the
     question under its Open questions heading.
   - **They haven't:** one open question, in their own terms, about the
     biggest thing their request leaves unsettled. Say why you're asking:
     what the answer would change about what you build. One question, a
     single sentence, no options listed under it (example in
     references/conversation.md).
     On the architectural path this is the one purpose question allowed
     before the intent.
3. If they asked for brainstorming (by name, "let's brainstorm" counts,
   by invoking it, or by asking for a design discussion), end on your
   question and leave the offer out. Otherwise, a light one-line offer to
   skip the questions:
   - Spike or bounded: "Or if you'd rather I just dive in, say so." If
     they take you up on it, this skill is done: state any significant
     how-it-gets-made choice (platform, language, medium) in one plain
     line, then do what they asked through the normal workflow.
   - Architectural: "Or if you'd rather skip the questions, I'll draft
     the intent from what you've said." On the
     architectural path the opt-out skips the questions, not the gates:
     write the intent from the request, mark every guess as yours, and
     stop for acceptance as usual. After the intent commit, skip the
     frontier rounds and the approaches pick: put each open decision,
     and the approach, in the spec as your call. The builder check, spec
     review, challenge, and plan still run.

That's the whole message.

## Establish Shared Understanding

The outcome of brainstorming is an understanding your human partner can
recognize and correct: discover the intent, write it back so they can
correct it, and carry it into the design. On the architectural path the
intent file is this write-back. The detail is in
[references/conversation.md](references/conversation.md).

<HARD-GATE>
Before taking any implementation action, including invoking an
implementation skill, writing product code, scaffolding, installing
product dependencies, or creating an external project, complete the
selected path's prerequisites:

- Quick: none; the request is the full description.
- Spike: the human partner approves the question and probe.
- Bounded: the human partner picks an approach (its own message), then
  approves the short in-chat design.
- Architectural: the human partner accepts and commits the intent,
  then reviews and approves the written spec (after the builder check); the spec is challenged
  (if a `challenge` skill is installed) and its rulings recorded; then
  the partner reviews the written implementation plan and selects its
  execution method. Conversational design approval only permits writing
  the spec. Written-spec approval only permits `challenge` and then writing-plans.

A reply approves the stage actually presented. Approval of an idea or
feature scope does not approve artifacts that do not exist yet. Resume
at the earliest incomplete stage; do not turn one approval into permission
to skip the rest of the selected path. Read-only project exploration is
allowed while those prerequisites remain incomplete.

Two exceptions. If they opted out of the questions on the spike or
bounded path, the skill is done and the gate goes with it; on the
architectural path every gate above still holds. A spike they said yes
to may be built; it stays labeled throwaway, and keeping what it produced
is a new request that comes back through this gate.
</HARD-GATE>

## Size the Work

Before your first question, pick a size and say it out loud so your
human partner can override it:

| Size | The full description | Then |
|------|----------------------|------|
| Quick | the request itself | do it, say what you did |
| Spike | the question and probe, in chat | investigate, report a recommendation |
| Bounded | a short design, in chat | build it through the normal workflow, no plan document |
| Architectural | intent, then a written spec | challenge, then a full plan (superpowers:writing-plans) |

- **Quick** — everything that matters is in the request, it changes
  something already here, and no architectural trigger below applies
  (see First: What Do You Actually Know?). Check the architectural
  triggers first: a fully specified change to an interface others
  depend on is architectural, not quick. One guess that matters makes
  it bounded.
- **Spike** — a feasibility question ("can we...", "is it possible...",
  "quick and dirty is fine") whose output is an answer, not code you
  keep. No design doc, no spec file; anything you build stays labeled
  throwaway (checklist below).
- **Bounded** — a well-scoped change to code that already exists in
  this repo: a new flag, a small endpoint, a one-file fix.
  Understanding the kind of app is not enough — bounded means the flow
  you are changing is already here to read. If there is no existing
  flow to change, the task is not bounded. Ask the clarifying
  questions that matter, lay out the approaches in a message of their
  own and let them pick, then present a short design IN CHAT (a few
  sentences to a few short paragraphs), and STOP. Implementation
  starts only after your human partner says yes to that design — a
  bounded task's approval is as hard a gate as an architectural
  one. No spec file, no implementation plan document.
- **Architectural** — new projects, new subsystems, changes that
  restructure how components fit together or alter interfaces others
  depend on. Follow the full process in the checklist below, intent
  first.

When in doubt between two sizes, take the heavier one. The ratchet is
one-way: hidden complexity discovered mid-task upgrades the size —
stop, say so, and step up. Nothing downgrades mid-task.

The design, in chat for bounded and in the spec for architectural, has an
**Approaches** part: the two or three ways you considered building it,
what each trades off, which one they picked, and why. They pick in the
conversation, in the approaches message, before you write the design.

If this is really several independent projects, say so, agree on an
order, and brainstorm them one at a time.

Outside a software repo (a talk, a business, a renovation), "already
here" means existing work your human partner has shown you. The intent
and the written design go where they say; "commit" means saving them
there. writing-plans is for software only; otherwise the last step is
handing over the approved design.

## The Conversation

One question per message holds on spike and bounded, and on architectural until the intent is committed.
Each such message ends with one question: a single sentence with no list
of example answers hanging off it. After the intent commit, the
architectural path asks in frontier rounds instead (Checklist step 4). Use plain language, pitched just a little above where your human
partner is. Match their vocabulary; never use process jargon. You never
need to quote this skill to your human partner.

Be clear and concise. Lead with what matters. Avoid jargon. When you
report what you found, give them the most important findings and offer
the rest.

**Look things up; offer recon.**
Anything answerable from the repo or the environment you look up yourself, never ask.
Read-only exploration is always allowed. For their own files and data
outside the project, or the web, offer to go look: say what you'd look
for. They decide whether you go.

Spikes, and how to get them describing: [references/conversation.md](references/conversation.md).

**Lay out the approaches.** On the bounded and architectural paths,
once you understand what they want and before you write anything up
(the short in-chat design, or the spec's design sections), put the ways
of building it in a message of its own. Come up with several real
alternatives and drop the weak ones, including any that work against why
they want it and any the existing work rules out. Present the two or
three that remain, grounding each in what the project actually does and
saying what it trades off. Recommend one and say why, then ask which way
they want to go. When there's genuinely one sensible way, say so and
explain why the others don't fit. This is for how it gets built; for
what they want, get them describing first.

## Play It Back

Play back as you go. As soon as you understand one part well enough to
describe it (what it's for and who it serves, say, or how one piece
behaves), describe that part back in about 200-300 words, then return to
questions about the next part. Playback and questions alternate through
the whole conversation; the last chunk covers whatever is left. On the
architectural path the intent is the first playback, and the design
sections (Checklist step 6) are the later chunks. On the bounded path
the short in-chat design is the playback; skip the 200-300-word chunks.

Only what they said goes in as theirs. Anything you filled in goes in
as your proposal, with your reason. End each chunk by asking what's wrong
or missing.

Before you send a chunk, check it: does it describe something they'll
look at, like a page, a screen, a schedule, or a printout? If so, and
they haven't seen the visual companion offer yet, send the offer instead
(its own message, below) and hold the chunk for the next message. Once
they've accepted, put a mockup next to the description.

On the architectural path the intent is exempt: present it as text,
never hold it back for the offer, and put no mockup beside it. The
visual offer and mockups start after the intent is accepted and
committed.

## Anti-Pattern: "Too Simple To Need Approval"

Every path except Quick ends with your human partner approving the
required design before implementation. A bounded change may need only
two sentences in chat. A new todo-list project is architectural and
requires the written spec and planning handoffs. Scale the artifact to
the selected path; complete that path's reviews before implementation.

## Red Flags

| Thought | Reality |
|---------|---------|
| "This is too simple to need a design" | Follow the selected path: a bounded change gets a short chat design; an architectural change gets the written spec and planning handoffs. |
| "It's quick, I'll just do it" | Quick means nothing that matters is missing and no architectural trigger applies. A guess that matters makes it bounded; a new subsystem, a restructure, or an interface others depend on makes it architectural, however fully specified. |
| "I'll call it bounded and skip the spec" | Reaching for a label to skip work IS the doubt — take the heavier path. |
| "It's bounded and the design is obvious — I'll start while they read it" | The gate is the approval, not the design's length. Present, then stop until you hear yes. |
| "I understand this kind of app, so it's bounded" | Bounded measures the repo, not your familiarity. A new project has no existing flow — it is architectural. |
| "The spike works, so I'll keep the code" | A spike's output is an answer. Keeping the code is a new request — size it. |
| "It grew, but I'm almost done — no need to re-size" | Hidden complexity upgrades the path mid-task. Stop and say so. |
| "They approved the spike, so the follow-up change is approved too" | Each task gets its own size and its own approval. |
| "They said skip the questions, so the intent can go too" | On the architectural path the opt-out skips questions, not gates. Write the intent from the request and stop for acceptance. |
| "I'll write the intent after the design, once I know what it is" | The intent is what the design is checked against. Write it first, get the yes, commit, then design. |
| "Twelve questions, one per message, is thorough" | On the architectural path that is twelve round trips with no view of dependencies. Ask the frontier in one round with recommended answers. |
| "I've answered their questions, so I'll write the design" | Lay out the approaches first, in a message of their own. |
| "They said 'sounds good' to the idea" | Approval covers what you showed them. A design you haven't shown them isn't approved. |

## Checklist

Size first, announce the path, then create a task for each item on
your path and complete them in order.

**Quick:**
1. **Do it** — through the normal development workflow
2. **Say what you did**

**Spike:**
1. **Explore project context** — enough to frame the probe
2. **Present question + probe plan** — 2-3 sentences
3. **Get approval** — a nod is enough
4. **Investigate** — as cheaply as correctness allows
5. **Report findings** — a recommendation; label anything built as throwaway

**Bounded:**
1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time, the ones that matter
3. **Lay out the approaches** — a message of their own: 2-3 ways with trade-offs and your recommendation; they pick one
4. **Present short design in chat** — the picked approach, files touched, testing
5. **Get approval** — STOP and wait for an explicit yes; presenting the design and starting in the same breath is skipping the gate
6. **Implement** — proceed with the normal development workflow (TDD applies); no plan document

**Architectural:** read [references/architectural.md](references/architectural.md) before step 2, and again
before steps 4, 7, 9 and 11. It holds each step's full rules, the intent
template, the frontier-round format, the design process, and the flow
graph; your memory of it does not survive compaction.

1. **Explore project context** — check files, docs, recent commits
2. **Write the intent** — before any design question, approach, or design (one purpose question may come first); present it and STOP; on an explicit yes set `Status: accepted` and commit it
3. **Offer the visual companion just-in-time** — only when a question is clearer shown than described
4. **Ask in frontier rounds** — the whole frontier in one numbered message, each question with your recommended answer
5. **Lay out the approaches** — a message of their own: 2-3 ways with trade-offs and your recommendation; they pick one
6. **Present design** — in sections scaled to their complexity, approval after each section
7. **Write design doc** — the spec, with the header line `Intent: <path to the accepted intent file>`, committed
8. **Spec self-review** — including every Constraint in the intent
9. **Builder check** — fresh subagent; bring only the "theirs" pile to your human partner
10. **User reviews written spec**
11. **Challenge the spec** — if a `challenge` skill is installed; rulings and the `Challenge:` header line recorded in the spec, committed
12. **Transition to implementation** — invoke the writing-plans skill

**Terminal states are path-bound.** Architectural: after the spec is
approved, the ONLY skills you invoke are `challenge` (on the committed
spec, if installed) and then writing-plans — never frontend-design,
mcp-builder, or any other implementation skill. Bounded: after
approval, implementation proceeds directly through the normal
development workflow; no plan document. Spike: the terminal state is a
reported recommendation. Quick: the terminal state is the done task and
one line saying what you did.

## The Written Design

Architectural path. Write a plain document a talented builder in the
domain could plan from without going back to your human partner. Cover:

- intent and the why
- goals, non-goals, anti-goals
- constraints
- approaches (above)
- the parts of the how they decided, as they decided them
- what's left to the builder

Where it goes, the spec self-review, the builder check, your human
partner's review, and the challenge: read [references/architectural.md](references/architectural.md)
before you write it.

## Visual Companion

A browser tab for showing mockups, diagrams, and prototypes. It's a
tool, not a mode: accepting it doesn't send every question to the
browser. Offer it just-in-time, never upfront, as its own message with
nothing else in it. On the architectural path the intent is exempt.
How to offer it and when to use it: [references/conversation.md](references/conversation.md). If they
accept, read `visual-companion.md` in this directory before starting the
server.
