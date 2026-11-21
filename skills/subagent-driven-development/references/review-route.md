# A Review Route That Is Not a Subagent

Part of superpowers:subagent-driven-development.

When the routing skill names a review route that is not a subagent, run that route instead of
dispatching a reviewer; everything else in this workflow stays as written. Its focus names the
review package, the task brief, the plan (for its global constraints) and the implementer's
report, and requires the reply's `summary` to open with two lines, `Spec: pass|fail` and
`Quality: pass|fail`, then one `Cannot verify:` line per item it could not check. Write the full
output to the same review file (`task-N-review.md`, `final-review.md`); re-reviews append a
round. A task advances only when both lines read `pass` and you have resolved every `Cannot
verify` line yourself, and the reply carries no finding above low severity; a reply missing
either line, or an inconsistent one (an `approve` with a finding above low or a `fail` line, a
`needs-attention` with no findings), is a failed review, run again. Findings are
handled by the fix loop as written: low-severity ones are deferred to the final review and
listed in its focus, the rest are fixed, and the re-review runs over the fix range with a focus
that lists each open finding and asks for a verdict on each. With no such route named, dispatch
the reviewer as before. Write the focus as plain text with no backticks, quotes or dollar signs,
because the launcher passes it through a shell; name the verdict lines in words (the summary
opens with a line Spec: pass or Spec: fail, then a line Quality: pass or Quality: fail).

- The orchestrator waits for the review before the next task: on Claude Code it polls
  `/codex:status` and copies `/codex:result` into the review file; on Pi it runs
  `cross-review.sh --wait` and copies the run dir's `report.md`. The review file holds the
  output itself, never a pointer to a job.
- Bases are the workflow's own: the BASE it records before dispatching a task's implementer for
  the first review, and its fix base for a re-review.
