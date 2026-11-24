---
name: requesting-code-review
description: Use when the whole change is committed and needs its one review before merge
---

# Requesting Code Review

One review of the whole change, by Sol, before merge. The reviewer sees the committed branch, never your session's history.

## When

Review once, when the whole change is committed. Not per task.

## How

1. Read `model-routing`'s CODEX-LANE.md.
2. Start this through the Skill tool, with the base branch the change merges into:
   `/codex:adversarial-review --base <base> --model gpt-6.2-sol -- <Review Focus text>`
   Add `--background` right after the command name (`--wait` only for a diff of one or two files): without one of them the command stops to ask which. Read a background result with `/codex:result`.
3. The focus text is the plan's Review Focus section verbatim, as plain text, plus any failing-combination reproducer the build ledgered.
4. No second review by another model.

## Fallback: no Codex plugin installed

Dispatch one `general-purpose` subagent on the whole branch, filling the template at [code-reviewer.md](code-reviewer.md). Use the same for the re-review, with `{BASE_SHA}` set to the reviewed commit.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit (`git merge-base <base> HEAD`, with the same `<base>` the change merges into)
- `{HEAD_SHA}` - Ending commit (`git rev-parse HEAD`)

The ready-to-merge summary then says the review was not a Sol review.

Its verdicts map onto the Sol ones: `Yes` counts as `approve`; `With fixes` and `No` are findings and go to the fix stage. Every Declined to judge line is a ruling you make and ledger, as `Final: Ruling: <behaviour the reviewer set aside> — <why it stands or why it is now a finding> — <cost if wrong>`.

No Codex plugin and no subagent tool: do the review in [code-reviewer.md](code-reviewer.md) yourself on the same range, as a separate pass after the last commit. Ledger `Final review: self-review (no subagent tool)`. The ready-to-merge summary says the only review was a self-review by the author, and your human partner decides whether that is enough before any merge.

## Act on feedback

- Fix Critical issues immediately
- Fix Important issues before merge
- Note Minor issues for later
- Push back if the reviewer is wrong (with reasoning)

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll just review the diff myself instead of dispatching a reviewer" | You're the coordinator — reviewing the diff inline burns the context window you need to keep driving the work. Dispatch a reviewer subagent: the diff and the evaluation live in its context, and only the findings come back to you. |
| "The reviewer needs my whole session history to understand the change" | Hand it precisely crafted context, never your session's history. That keeps the reviewer on the work product, not your thought process. |

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
