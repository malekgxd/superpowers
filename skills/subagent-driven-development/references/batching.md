# Batching Small Same-Shape Work

Part of superpowers:subagent-driven-development.

**Batch small same-shape work.** When the plan lists several tasks that are
each a small, independent edit of the same kind — the same one-line fix,
constant change, or field addition repeated across files — do not dispatch
one subagent per task. Compose ONE dispatch brief listing every file and
its change, and send the whole batch to a single subagent. Reserve
one-dispatch-per-task for work that needs its own judgment or its own tests.

Only tasks that could share a wave are batched: each one's `Depends on`
tasks are complete and no two list the same file. A plan with no
`Depends on` lines is never batched, because each of its tasks waits for
the one before it.

You still commit each task of a batch alone, `Task <N>:`, with its own ledger line.
