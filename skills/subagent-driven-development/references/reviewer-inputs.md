# Task Reviewer Inputs

Part of superpowers:subagent-driven-development.

- **Reviewer inputs:** the task reviewer gets four paths — the same brief
  file, the report file, the review package, and the review file it writes
  (`…/task-N-review.md`) — plus the global constraints that bind the task.
- The global-constraints block you hand the reviewer is its attention
  lens. Copy the binding requirements verbatim from the plan's Global
  Constraints section or the spec: exact values, exact formats, and the
  stated relationships between components ("same layout as X", "matches
  Y"). The reviewer's template already carries the process rules (YAGNI,
  test hygiene, review method) — the constraints block is for what THIS
  project's spec demands.
