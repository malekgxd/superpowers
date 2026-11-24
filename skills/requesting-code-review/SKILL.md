---
name: requesting-code-review
description: Use when the whole change is committed and needs its one review before merge
---

# Requesting Code Review

One review of the whole change, by Sol, before merge. The reviewer sees the committed branch, never your session's history.

## When

Review once, when the whole change is committed. Not per task.

## How

1. Before anything launches, Sol or fallback, ledger `Review: started on <sha>` (the sha from `git rev-parse HEAD`). A session that restarts with that line and no `Review done:` line stops and asks; it never starts a second review.
2. Check Codex next. No `codex:adversarial-review` skill, a refused Skill call or a failed launch: use the Fallback below now, without repairing the plugin first. Otherwise read `model-routing`'s CODEX-LANE.md.
3. Start this through the Skill tool, with the base branch the change merges into:
   `/codex:adversarial-review --base <base> --model gpt-6.2-sol -- <Review Focus text>`
   Add `--background` right after the command name (`--wait` only for a diff of one or two files): without one of them the command stops to ask which.
4. After the launch, ledger `Review: job <job-id> on <sha>`: the job id from the launch or `/codex:status`, the same sha. Read the result with `/codex:result <job-id>`, never bare: a bare `/codex:result` returns the latest finished job, which can be an earlier review. The verdict counts only when the result's `Target:` line names your base and HEAD is still the ledgered sha.
5. The focus text is the plan's Review Focus section verbatim, as plain text, plus any failing-combination reproducer the build ledgered.
6. No second review by another model.

## Fallback: Codex unavailable or refused

Codex is unavailable (step 2), or it refused the review and the `gpt-6.1-sol` rerun too: with the step 1 line already in the ledger, dispatch one `general-purpose` subagent with `model: opus` on the whole branch, filling the template at [code-reviewer.md](code-reviewer.md) with the range pinned as two shas. After the dispatch, ledger `Final review: fallback (general-purpose, opus)`. Use the same for the re-review, with `{BASE_SHA}` set to the reviewed commit.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit (`git merge-base <base> HEAD`, with the same `<base>` the change merges into)
- `{HEAD_SHA}` - Ending commit (`git rev-parse HEAD`)

The ready-to-merge summary then says the review was not a Sol review.

Its verdicts map onto the Sol ones: `Yes` counts as `approve`; `With fixes` and `No` are findings and go to the fix stage. Every Declined to judge line is a ruling you make and ledger, as `Final: Ruling: <behaviour the reviewer set aside> — <why it stands or why it is now a finding> — <cost if wrong>`.

No Codex plugin and no subagent tool: do the review in [code-reviewer.md](code-reviewer.md) yourself on the same range, as a separate pass after the last commit and after the step 1 line. Ledger `Final review: self-review (no subagent tool)`. The ready-to-merge summary says the only review was a self-review by the author.

After a fallback review or a self-review, nothing merges until your human partner gives an explicit go for the reviewed sha the ready-to-merge summary prints: superpowers:finishing-a-development-branch shows its menu and does not act on a `Finish branch:` line.

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
