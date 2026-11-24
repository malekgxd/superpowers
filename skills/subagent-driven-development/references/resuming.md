# Resuming From an Existing Ledger

Part of superpowers:subagent-driven-development. This plan's workspace
already has a ledger at `<workspace>/progress.md`.

If the ledger's first line names your plan file, tasks with a `Task <N>:
complete` line are DONE — do not re-dispatch them; resume at the first
task without one. A ledger whose first line names a
different plan file — or a stray ledger at the old flat path
`.superpowers/sdd/progress.md` — is another plan's progress: leave it in
place and start your own, fresh.

A ledger line means done, and nothing else does. Before you dispatch anything, read `git log --oneline <start sha>..HEAD` (the start sha is on the ledger's `Start:` line) and `git status`.

Stop and ask your human partner when any of these holds:

- a `Task <N>:` commit in that log has no `Task <N>: complete` ledger line;
- `git status` shows pending edits;
- the ledger holds a `Review:`, `Fix:`, `Guard:` or `Final review:` line with no `Review done:` line after it;
- the ledger has no `Start:` line.

Show them the ledger tail and the output of `git log --oneline <start sha>..HEAD` (`git log --oneline -20` when there is no start sha), then wait for their ruling. Never redispatch a task, restart a review or guess which commit is whose.

With none of them, resume at the first task without a ledger line. When every task has one, [final-review.md](final-review.md) is next.
