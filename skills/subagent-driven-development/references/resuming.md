# Resuming From an Existing Ledger

Part of superpowers:subagent-driven-development. This plan's workspace
already has a ledger at `<workspace>/progress.md`.

If the ledger's first line names your plan file, tasks with a `Task <N>:
complete` line are DONE — do not re-dispatch them; resume at the first
task without one. A ledger whose first line names a
different plan file — or a stray ledger at the old flat path
`.superpowers/sdd/progress.md` — is another plan's progress: leave it in
place and start your own, fresh.

Before any redispatch, read `git log <start sha>..HEAD` for `Task <N>:`
commits and `git status` for pending edits. The start sha is on the
ledger's `Start:` line; a ledger without one stops and asks your human
partner. An earlier plan's `Task <N>:` commits sit before the start sha and
are never counted.

A task with a commit is complete even without its ledger line: write the line and move on.
Pending edits are attributed to their task's Files or ruled on.
