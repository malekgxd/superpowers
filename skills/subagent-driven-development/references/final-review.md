# Final Review and Finish

Part of superpowers:subagent-driven-development. Every task in the plan is
complete and committed.

The whole change gets one review, now. A ledger that already holds a `Review:` or `Fix: reviewed` line is a review in flight: [resuming.md](resuming.md) says where it resumes, and no second end review starts. Otherwise, in this order:

1. Use superpowers:requesting-code-review to start the one end review of
   the whole change. Append to its focus text every ledger line for a
   failure still open, with its reproducer.
2. Use superpowers:receiving-code-review on what comes back.
3. Use superpowers:verification-before-completion before you claim the
   work is done.

### Finish

Before you archive anything, collect every ledger line containing `Ruling:` —
preflight rulings, parked findings, breaker adjudications, all of them — into
your final message under "Rulings I made", in the order you made them, each
with what it costs if wrong. The list is exhaustive: if the ledger holds a
ruling, the list holds it. That list is the only place the decisions you
took on your human partner's behalf reach them — they read it and rework
whatever you got wrong. A ruling that only lives in the archive was a
decision made in secret.

When the final whole-branch review is clean and its fixes are merged,
archive this plan's workspace: run this skill's `bash scripts/sdd-archive PLAN_FILE`
by its absolute path, from the working tree you're executing in. It moves the workspace to
`.superpowers/sdd/_archive/<plan-basename>-<timestamp>/`, still git-ignored,
so the ledger, reports and reviews outlive the run for tooling that reads
them, while a rerun of the same plan starts from an empty workspace. Never
`rm -rf` it. Sibling directories belong to other plans; leave them alone.

Use superpowers:finishing-a-development-branch.
