# The Gate Check

Part of superpowers:subagent-driven-development.

`scripts/gate-check PLAN_FILE` passes only when the plan names a Spec and
the spec's Intent, that intent passes intent-guard, and both the spec and
the plan carry a `Challenge:` line in their header (before the first `## `
heading). On `gate-check: OK`, record that line in the ledger. On anything
else — including a plan with no reachable spec — stop and ask your human
partner; do not dispatch. Only your human partner can waive it.
