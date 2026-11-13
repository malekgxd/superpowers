# Conversation

Part of superpowers:brainstorming. Read it before your first message.

## Establish Shared Understanding

The outcome of brainstorming is an understanding your human partner can
recognize and correct, grounded in what they want to accomplish.

1. **Discover intent.** Use the request and available context to identify
   the intended outcome, who it is for, and what success looks like. When
   that information is missing, ask one focused question about purpose or
   intended use before proposing features or an approach. Knowing the app
   genre does not tell you why your partner wants it. Gathering missing
   requirements does not ask them to authorize the task again.
2. **Write back your understanding.** Summarize the intended outcome,
   relevant constraints, and success criteria in a short note your partner
   can assess. Separate what they said from assumptions. Invite correction
   and incorporate their answer before treating this as the design brief.
   On the architectural path the intent file is this write-back: write it
   with the Intent template in [architectural.md](architectural.md), not as a separate note.
3. **Carry intent into the design.** Preserve the agreed understanding in
   the selected path's design artifact: the written spec for architectural
   work, or the in-chat design/probe for bounded work and spikes. Check
   proposed features and technical choices against that understanding.

When the request already supplies the purpose and constraints, reflect
that understanding instead of asking the same questions again. Keep the
note concise; its accuracy and the opportunity to correct it matter.

## Asking

A first open question, for "a website for my bakery": "If it's mostly
for people deciding whether to stop by, I'd lead with hours and what's in
the case today; taking orders is a different site. What do you want
someone to do when they land on it?"

**Get them describing.** Until you know why they want it, ask open
questions, with no example answers attached. Their own words carry
intent that your options can't. Once you know why, when a decision has
choices you can name, sketch each concretely, with what it trades off
and which you'd pick. When they say "just guess" or "what do you think?",
propose something concrete.

**How it gets made.** Every project rests on choices about medium, tools,
materials, and resources: the platform, programming language, and
libraries for an app; the medium for a piece of art. Read from how they
talk which of those choices they want to make. Someone who raises the how
or asks about trade-offs wants the options with your pick. Someone who
talks about outcomes is handing you the how: make those calls and state
each in a line. When there's existing work, build on what it already
uses. Any choice you make goes in the design as your call, never as
something they agreed to.

**Ground to cover.** This is territory, not a script. Never read these
out as questions:

- what kind of thing this is, and what makes it special
- why now, and what success looks like to them
- goals, non-goals, and anti-goals (what would make this a failure even
  if it technically works)
- prior art: what they've seen elsewhere, loved or hated
- current state: what exists now, what they've tried
- the details they care about

**Make every question specific** to their project and what they've told
you. Ask Socratically, the way a sharp colleague would: build each
question on their last answer or on something you found, so it helps
them think through a consequence or a case they may have missed
("Voting closes before the meeting, and two members joined this month.
Does someone who joins mid-round get a vote?"). When the reason isn't
already plain, say what you're hoping to learn or what the answer would
change. A proposal they can correct, plus your reason for it, often
beats a question.

**Look things up; offer recon.**
Anything answerable from the repo or the environment you look up yourself, never ask.
Read-only exploration is always allowed. For their own files and data
outside the project, or the web, offer to go look: say what you'd look
for. They decide whether you go.

**Plain words.** Define any term the first time you use it, put your
recommended answer first, and name no tool or process where a plain
description works.

**Show, don't tell.** Whenever seeing would help more than reading,
sketch it in text: a few lines of what they'd see. Offer the visual
companion (below) when the look itself is theirs to decide:

- something they'll look at: a screen, a page, a printout, a sign
- a layout or arrangement: of a screen, a room, a schedule
- a flow or a sequence of steps
- options that would look different from each other
- a structure that's easier to see than read: a diagram, a timeline, a map

Once they've accepted, use it for mockups to react to, side-by-side
options, and throwaway prototypes they can click.

**Spike to feel things out.** Agentic work is waterfall, but very, very
fast. A quick throwaway build is often the cheapest way to learn what
they want or whether something works. Offer one when it would help.
When they just want to spike, get out of the way. Spikes get no tests
or minimal ones, aren't bulletproof, and skip the plan, implementation,
and review process. Bring what the spike taught you back into the
conversation. A spike during an architectural brainstorm is its own
task with its own yes; it may run before the intent commit because
nothing it builds is kept.

## Lay Out the Approaches

On the bounded and architectural paths, the design message opens with
the ways of building it. Come up with several real alternatives and drop
the weak ones, including any that work against why they want it and any
the existing work rules out. Present the two or three that remain, one
line or a short bullet each, recommended first; sketch each concretely
enough to picture, grounding it in what the project actually does and
saying what it trades off; say why you recommend the first. Then give
the design for the recommended one. When there's genuinely one sensible way, say so and explain why the others
don't fit. A reply naming another way gets the design redone for it.
This is for how it gets built; for what they want, get them describing
first.

## Play It Back

Play back as you go. As soon as you understand one part well enough to
describe it (what it's for and who it serves, say, or how one piece
behaves), describe that part back in about 200-300 words, then return to
questions about the next part. Playback and questions alternate through
the whole conversation; the last chunk covers whatever is left. On the
bounded path the short in-chat design is the playback; skip the
200-300-word chunks. On the architectural path the intent and the design
message are the playbacks, with no design-section chunks (detail in
[architectural.md](architectural.md)).

Only what they said goes in as theirs. Anything you filled in goes in
as your proposal, with your reason. End each chunk by asking what's wrong
or missing.

Before you send a chunk, check it: does it describe something they'll
look at, like a page, a screen, a schedule, or a printout? If so, put a
text sketch next to the description. If the look itself is theirs to
decide and they haven't seen the visual companion offer yet, send the
offer instead (its own message, below) and hold the chunk for the next
message. Once they've accepted, put a mockup next to the description.

## Anti-Pattern: "Too Simple To Need Approval"

Every path except Quick ends with your human partner approving the
required design before implementation. A bounded change may need only
two sentences in chat. A new todo-list project is architectural and
requires the written spec and planning handoffs. Scale the artifact to
the selected path; complete that path's reviews before implementation.

## Red Flags While Asking

| Thought | Reality |
|---------|---------|
| "I'll offer a menu of what they might want" | Options steer. Ask them to describe it first. |
| "I'll fill in sensible defaults" | Good. Say them out loud. A default they never heard is one they couldn't reject. |
| "I should explain the process first" | Ask your question. The process shows itself. |

## Offering the Visual Companion

A browser tab for showing mockups, diagrams, and prototypes. It's a
tool, not a mode: accepting it doesn't send every question to the
browser.

**Offer it just-in-time.** Offer it the first time one of the Show,
don't tell moments comes up, never upfront. The offer is its own message
with nothing else in it — no clarifying question, summary, or other
content:

> "This might be easier if I show you. Want me to open a browser tab with some mockups?"

Wait for the user's response. If they accept, start the server with
`--open` so their browser opens to the first screen automatically. If
they decline, stay in text and don't offer again unless they raise it.

**Per question, ask: would they understand this better by seeing it?**

- **Use the browser** for content that IS visual — mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
- **Use the terminal** for content that is text — requirements questions, conceptual choices, tradeoff lists, A/B/C/D text options, scope decisions

A question about a UI topic is not automatically a visual question. "What does personality mean in this context?" is a conceptual question — use the terminal. "Which wizard layout works better?" is a visual question — use the browser.

If they accept, read [visual-companion.md](../visual-companion.md) before
starting the server.
