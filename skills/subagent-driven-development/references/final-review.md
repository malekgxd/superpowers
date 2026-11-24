# Final Review and Finish

Part of superpowers:subagent-driven-development. Every task in the plan is
complete and committed.

The whole change gets one review, now. A ledger that already holds a `Review:`, `Fix:`, `Guard:` or `Final review:` line means the review already started: with a `Review done:` line after it, go to Finish; without one, stop and ask as [resuming.md](resuming.md) says. No second end review starts either way. Otherwise, in this order:

1. Use superpowers:requesting-code-review to start the one end review of
   the whole change. Its `Review: started on <sha>` line goes into the ledger before any reviewer launches. Append to its focus text every ledger line for a
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

Then use superpowers:finishing-a-development-branch while the ledger is still active, and ledger `Finish: <what was done> on <sha>`. Only after that line exists, archive this plan's workspace (when finishing removed the worktree, the ledger went with it and nothing is left to archive): run this skill's `bash scripts/sdd-archive PLAN_FILE`
by its absolute path, from the working tree you're executing in. It moves the workspace to
`.superpowers/sdd/_archive/<plan-basename>-<timestamp>/`, still git-ignored,
so the ledger, reports and reviews outlive the run for tooling that reads
them, while a rerun of the same plan starts from an empty workspace. Never
`rm -rf` it. Sibling directories belong to other plans; leave them alone.
