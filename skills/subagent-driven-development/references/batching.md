# Batching Small Same-Shape Work

Part of superpowers:subagent-driven-development.

**Batch small same-shape work.** When the plan lists several tasks that are
each a small, independent edit of the same kind — the same one-line fix,
constant change, or field addition repeated across files — do not dispatch
one subagent per task. Compose ONE dispatch brief listing every file and
its change, and send the whole batch to a single subagent. The batch is
committed as one task. Reserve one-dispatch-per-task for work that needs
its own judgment or its own tests.
