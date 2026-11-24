---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write implementation plans for an engineer who has not seen this codebase or this spec. Assume they write idiomatic code in the project's language once they know the exact interface and the exact test, and that they will make a reasonable choice wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, which tests prove each task. Document those. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Intent Guard

Before any planning work, from the repo that holds the spec, run this
skill's `scripts/intent-guard` by its full path:
`bash <this skill's base directory>/scripts/intent-guard <spec path>`.
On `REFUSE`, stop and tell your human partner the reason it printed; the
intent must be accepted and committed first
(brainstorming writes it). Anything other than an `intent-guard: OK` line
(a REFUSE, a missing spec, any error) means stop. With no spec at all,
stop: planning starts from a spec that names its intent.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit with its own test cycle that one builder can
finish alone. When drawing task boundaries: fold setup, configuration,
scaffolding, and documentation steps into the task whose deliverable needs
them. Each task ends with an independently testable deliverable.

**Wide refactors are the exception.** A wide refactor is one mechanical
change (rename a column, retype a shared symbol) whose blast radius fans
across the whole codebase, so a single edit breaks many call sites at
once and no single task can land green. Do not force it into one task;
sequence it as **expand–contract**. First expand: add the new form beside
the old so nothing breaks. Then migrate the call sites in batches sized
by blast radius (per package, per directory), each batch its own task
that depends on the expand, keeping the suite green batch to batch
because the old form still exists. Finally contract: delete the old form
once no caller remains, in a task that depends on every migrate batch.

## Step Granularity

**Each step is one action with a checkable result:**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [path to the spec/design doc this plan implements — the plan
argues from the spec, so the spec travels with it; executors read both]

**Intent:** [the spec's `Intent:` path, which the guard checked]

**Challenge:** [YYYY-MM-DD holds|holds-with-conditions|broken-ruled — added
after the plan challenge is ruled on; gate-check reads it]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

## Review Focus

[This section is passed verbatim as the focus text of the one end review,
so write it as plain text with no backticks, quotes or dollar signs (the
launcher passes it through a shell). The five input classes or failure modes the spec implies but no task's
tests exercise that are most likely to bite a person using this software
— one line each, naming the input or condition and the behavior a
reasonable person would expect, most likely first. The spec is a vision
document: it says what the software must do, not everything it will
meet, and its silence on an input is not permission for that input to
break the program. Write the list here, once, with the spec in front of
you. Then, for each line, add the test that pins it to the task that
owns the code, in that task's own step style. The section always ends with
the line "Name anything outside the diff that carries the same rule, value or check and was left unchanged."]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Depends on:** none
[or `**Depends on:** Task N, Task M`]

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`**

One line on the approach when the signature and the test leave a choice
(which library call, which data structure); a code block only for an
algorithm they do not determine.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## What a Step Contains

A step is done when the implementer can write exactly one reasonable thing
from it. That is the whole requirement: unambiguous, not complete. Each kind
of step carries what makes it unambiguous and nothing more:

- **A test step:** the test's name and its assertions, as code, with the
  spec's exact values in them.
- **A code step:** the exact signature (name, parameters, return type), the
  file it lives in, and the specific values the spec pins. The implementer
  writes the body. A body appears only for an algorithm the signature and
  tests do not determine, or for exact copy the spec fixes.
- **A verification step:** the command to run and the output that means it
  passed.
- **A reference to another task:** that task's Interfaces block says what
  to use; the plan does not repeat that task's code.

A plan is the set of decisions the implementer cannot make alone. A plan
longer than the code it describes has written the code instead. Lines that
decide nothing ("TBD", "handle edge cases", "add appropriate validation",
"write tests for the above", a type or function no task defines) are the
opposite failure, and the self-review catches both.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Step scan:** Every step must let the implementer write exactly one reasonable thing, and no step may carry more than that: a line that decides nothing is a gap, a function body the signature and tests already determine is a transcript. Fix both.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Review Focus:** For each input class or failure mode the spec implies, is there a task whose tests exercise it? The five uncovered ones most likely to bite a person go in the Review Focus section, and each line there gets its test added to the owning task. An empty section means you checked and found none, not that you skipped the check.

**5. Proportion:** Compare the plan's length to the spec's. A plan several times longer than the spec it implements is a transcript of the program, not a plan. If code blocks are most of the document, replace bodies with signatures, test names and assertions, and check that each step is still unambiguous.

**6. Independence:** Two tasks with no dependency between them must not list the same file, and their tests must not share a mutable resource (an output file, a fixture written at run time, a port, a database). If they do, add the dependency or separate the resource.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

Before offering execution, commit the plan; then, if a `challenge` skill is installed, challenge the committed plan, record its rulings in the plan under a `## Plan challenge rulings` heading, add `Challenge: YYYY-MM-DD <verdict>` to the plan header — map the challenge verdict to the field — "holds" → `holds`, "holds with conditions" → `holds-with-conditions`, "broken" with every finding and Flag ruled → `broken-ruled` (a "broken" verdict with unruled findings may not be recorded) — and commit; the handoff waits for that. Who challenges: every committed plan goes to Astra (`gpt-6.2-astra`) through the `challenge` skill.

After saving and self-reviewing the plan, committing it and recording the challenge, write the handoff and stop. Do not ask for a review and do not ask which method to use. The method is the one the design message's "Calls I made" list named: subagent-driven by default, or native when your human partner's reply said "native".

The handoff stops only when the plan challenge has a finding only your human partner can rule on, or the plan would change behaviour the spec states. Task order, task splits and file layout are not behaviour changes. When it stops, name the finding or the changed behaviour and ask that one question. That stop comes before the handoff is written.

Otherwise write and commit `docs/superpowers/plans/<plan-basename>-HANDOFF.md`, print `Plan complete and saved to <plan path>. Challenge: <verdict>. Handoff: <handoff path>.` and one start line for a new `claude-opus-5-5` session: `Read <handoff path> and follow it.` Then stop. It does not start building.

The handoff file:

```markdown
# Handoff: <plan title>

Plan: <path> · Spec: <path> · Intent: <path>
Plan commit: <full sha of the commit that holds the challenged plan>
Repo: <path> · Worktree: <path> · Base: <branch> at <sha>
Method: subagent-driven (or: native)
Model rule: name a model on every dispatch; an unset model runs on your own.
Stages left: build (superpowers:subagent-driven-development, or superpowers:executing-plans when native), review (superpowers:requesting-code-review), fix (superpowers:receiving-code-review), verify (superpowers:verification-before-completion), finish (superpowers:finishing-a-development-branch).
Stops: the four stops in subagent-driven-development.
First act: `git diff --quiet <plan commit> -- <plan path>` exits 0, `git merge-base --is-ancestor <plan commit> HEAD` exits 0, then `gate-check` with the plan path. Anything else: stop and ask.

## Review Focus

<copied from the plan>
```
