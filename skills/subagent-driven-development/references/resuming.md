# Resuming From an Existing Ledger

Part of superpowers:subagent-driven-development. This plan's workspace
already has a ledger at `<workspace>/progress.md`.

If the ledger's first line names your plan file, tasks with a `Task <N>:
complete` line are DONE — do not re-dispatch them; resume at the first
task without one. A ledger whose first line names a
different plan file — or a stray ledger at the old flat path
`.superpowers/sdd/progress.md` — is another plan's progress: leave it in
place and start your own, fresh.

Before any redispatch, read `git log <start sha>..HEAD --first-parent` for
`Task <N> (<plan-basename>):` commits and `git status` for pending edits. The start sha is on the
ledger's `Start:` line; a ledger without one stops and asks your human
partner. An earlier plan's commits sit before the start sha and
are never counted, and `--first-parent` leaves out the ones a merge brought in after it.
A task commit counts only when its subject carries this plan's basename and it changes that task's Files (`git show --stat <sha>`).

A task with a commit is complete even without its ledger line: write the line and do not re-dispatch it.
Its wave's suite result is missing with the line: rerun the full suite before any task that depends on it starts, and handle a failure as SKILL.md "Check the report" says.
Pending edits are attributed to their task's Files or ruled on.

A `Fix: reviewed <sha>` line with no `Guard:` line after it means the fix stage was interrupted. Do not start a new end review. Commit pending fix edits as the fix commit, then resume superpowers:receiving-code-review item 5 at the guard, with that sha as the reviewed commit. A `Review: job <id> on <sha>` line with no verdict ledgered: read that job's result if HEAD is still that sha.
