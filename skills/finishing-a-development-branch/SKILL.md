---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work
---

# Finishing a Development Branch

## Overview

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## Step 1: Verify Tests

Run the project's full test suite (`npm test` / `cargo test` / `pytest` / `go test ./...`).

**If tests fail**, report the failures and stop — the menu comes after a green suite:

```
Tests failing (<N> failures). Must fix before completing:

[Show failures]
```

**If tests pass:** continue to Step 2.

## Step 2: Detect Environment

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
# Capture now, while still inside the workspace — Step 5 changes directory
# before cleanup (Step 6) needs this value
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 3 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 3 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 2 options (no merge) | Externally managed — leave in place |

## Step 3: Determine Base Branch

The base branch is whatever this work forked from — usually named in the
plan, the conversation, the branch's upstream, or the worktree's creation
(a worktree made from a named base knows it). Ask only when the base is
unknown: "This branch split from <your best guess> - is that correct?"
Merging into the wrong base is expensive to undo.

## Step 4: Present Options

**Read the repo's `Finish branch:` line first.** Run
`git show <base-branch>:CLAUDE.md` and look for one line starting
`Finish branch:`. Values: `merge locally`, `merge and push`,
`merge locally; ask before push`. Act on it, without the menu, only when
all hold:

- Step 1 tests passed;
- the branch is named (detached HEAD always gets the menu);
- this session ran the review chain on `REVIEWED_OID` and it passed
  (a fresh or resumed session with no such record gets the menu);
- the `Finish branch:` value is one of the three recognised values above.

No line, a failed condition, or any other value gets the menu below.
Record the exact commit from the passed review's evidence, not a later
branch tip, at this gate:

```bash
REVIEWED_OID=<reviewed-commit>
```

```bash
test "$(git rev-parse <feature-branch>)" = "$REVIEWED_OID"
```

If the feature branch no longer points at `REVIEWED_OID`, stop and ask;
review the new tip before restarting. Keep this OID fixed through integration.

When acting on the line, use Option 1 and the integration rule below.
`merge locally` skips the push; `merge and push` pushes at g;
`merge locally; ask before push` asks at g.

**Integration rule** (steps a-g). Merge and test in temporary detached
worktrees. The main checkout is used only for the final ff-only update at g.
Run from the feature worktree; stop on any failed command as directed below.
`<test command>` means the same full suite used in Step 1.

- **a.** Fetch and record the remote base:

  ```bash
  git fetch origin &&
  ORIGIN=$(git rev-parse origin/<base-branch>)
  ```

  If either command fails, stop and ask; nothing is merged yet.

- **b.** Record the local base tip and enumerate `ORIGIN..<base-branch>`
  using that fixed tip, so an answer cannot authorise a later commit:

  ```bash
  INTEGRATION_BASE=$ORIGIN &&
  PUSH_ALL= &&
  LOCAL_BASE=$(git rev-parse <base-branch>) &&
  HELD=$(git rev-list "$ORIGIN".."$LOCAL_BASE")
  ```

  ```bash
  test -z "$HELD"
  ```

  The enumeration must succeed and be empty. Otherwise stop and ask,
  listing those commits: push all, or don't push. A failed enumeration
  stays stopped until it succeeds; an answer cannot authorise unknown commits.
  On "don't push", leave the branch in place. On "push all", record:

  ```bash
  INTEGRATION_BASE=$LOCAL_BASE &&
  PUSH_ALL=$HELD
  ```

  This base and these commits are approved for both d and f; do not ask
  again for the same commits. For `merge locally`, this approval includes
  them locally but does not authorise a push.

- **c.** Create the detached integration worktree:

  ```bash
  TMP_ROOT=$(mktemp -d) &&
  INTEGRATION="$TMP_ROOT/integration" &&
  git -c core.hooksPath=/dev/null worktree add --detach "$INTEGRATION" "$INTEGRATION_BASE"
  ```

  If creation fails, stop and ask. Recheck the feature before merging:

  ```bash
  test "$(git rev-parse <feature-branch>)" = "$REVIEWED_OID"
  ```

  If it changed, stop and ask for review of the new tip. Merge the recorded OID:

  ```bash
  git -C "$INTEGRATION" -c core.hooksPath=/dev/null merge --no-edit "$REVIEWED_OID"
  ```

  A conflict or any other merge failure: abort in that worktree, then the menu.

  ```bash
  git -C "$INTEGRATION" merge --abort
  ```

  If abort fails, report that too and leave the worktree for investigation.
  Never push a merge resolved by hand.

- **d.** Record and validate the result before testing:

  ```bash
  MERGED=$(git -C "$INTEGRATION" rev-parse HEAD) &&
  PARENTS=$(git rev-list --parents -n1 "$MERGED") &&
  { test "$MERGED" = "$REVIEWED_OID" || test "$PARENTS" = "$MERGED $INTEGRATION_BASE $REVIEWED_OID"; }
  ```

  `MERGED` must equal `REVIEWED_OID` (fast-forward) or have parents exactly
  `INTEGRATION_BASE` and `REVIEWED_OID`, in that order. Otherwise stop and ask.
  Independently merge those inputs again with hooks disabled and compare trees:

  ```bash
  git -c core.hooksPath=/dev/null worktree add --detach "$TMP_ROOT/check" "$INTEGRATION_BASE" &&
  git -C "$TMP_ROOT/check" -c core.hooksPath=/dev/null merge --no-edit "$REVIEWED_OID" &&
  EXPECTED_TREE=$(git -C "$TMP_ROOT/check" rev-parse 'HEAD^{tree}') &&
  test "$(git rev-parse "$MERGED^{tree}")" = "$EXPECTED_TREE" &&
  git worktree remove "$TMP_ROOT/check"
  ```

  If any validation command fails or the trees differ, stop and ask;
  matching parents alone do not authorise merge-only content.

- **e.** Check the integration checkout is still the recorded result,
  then run the tests in that temporary worktree:

  ```bash
  test "$(git -C "$INTEGRATION" rev-parse HEAD)" = "$MERGED" &&
  git -C "$INTEGRATION" diff --exit-code "$MERGED" -- &&
  git -C "$INTEGRATION" diff --cached --exit-code "$MERGED" --
  ```

  ```bash
  (cd "$INTEGRATION" && <test command>)
  ```

  ```bash
  test "$(git -C "$INTEGRATION" rev-parse HEAD)" = "$MERGED" &&
  git -C "$INTEGRATION" diff --exit-code "$MERGED" -- &&
  git -C "$INTEGRATION" diff --cached --exit-code "$MERGED" --
  ```

  If the merged tests fail or the recorded HEAD or tracked tree changed,
  stop; nothing has been pushed. A passing suite in the main checkout
  does not satisfy this step.

- **f.** Enumerate the outgoing commits and the reviewed history:

  ```bash
  OUTGOING=$(git rev-list "$ORIGIN".."$MERGED") &&
  REVIEWED_COMMITS=$(git rev-list "$ORIGIN".."$REVIEWED_OID")
  ```

  If either enumeration fails, stop and ask. Every outgoing commit must be
  `MERGED`, in `PUSH_ALL` from b, or in `REVIEWED_COMMITS`:

  ```bash
  EXTRAS=
  for OID in $OUTGOING; do
    if ! printf '%s\n' "$MERGED" "$PUSH_ALL" "$REVIEWED_COMMITS" | grep -Fx "$OID" >/dev/null; then
      EXTRAS="$EXTRAS $OID"
    fi
  done
  test -z "$EXTRAS"
  ```

  If any other commit is listed, stop and ask, listing them: push all, or
  don't push. An answer here does not waive the review, tree or test gates.

- **g.** Under `merge locally; ask before push`, ask push or not here;
  an answer already given at b or f is that answer. `merge locally` skips
  the push. Otherwise push the tested OID, once:

  ```bash
  git push origin "$MERGED":refs/heads/<base-branch>
  ```

  A rejected push is reported, never retried with force. Remove the temporary
  worktree from outside it, also after a declined or rejected push:

  ```bash
  git worktree remove "$INTEGRATION" &&
  rmdir "$TMP_ROOT"
  ```

  If removal is refused, stop and report the path; never force removal.
  Only if the main checkout is on the base branch and clean:

  ```bash
  MAIN_BRANCH=$(git -C <main-checkout> branch --show-current) &&
  MAIN_STATUS=$(git -C <main-checkout> status --porcelain) &&
  test "$MAIN_BRANCH" = <base-branch> &&
  test -z "$MAIN_STATUS"
  ```

  ```bash
  git -C <main-checkout> -c core.hooksPath=/dev/null merge --ff-only "$MERGED"
  ```

  If the checks or fast-forward fail, leave the main checkout in place and
  say so. For `merge locally`, or a declined push, stop and ask: the result
  has not landed. Report `MERGED` so the result can be recovered. Never
  switch the main checkout's branch or reset its work.

On any earlier stop, keep the feature branch and report temporary worktree
paths; remove only clean temporary worktrees, without force.
Keep the feature branch until the push is settled (or, for local-only work,
the ff-only update succeeded). Delete it only when no question remains and
it still points at `REVIEWED_OID`; preserve any newer feature work.

The line authorizes `git push` only. A deploy, OTA publish or release that
usually follows still asks. The report says which line was applied and what
ran.

**Normal repo and named-branch worktree — present exactly these 3 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)

Which option?
```

**Detached HEAD — present exactly these 2 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)

Which option?
```

Present the menu exactly as written — concise, with every option coming
from the list above. Discarding the work happens only in response to your
human partner explicitly asking for it (see "If your human partner asks to
discard the work" below). Wait for their answer; the integration decision
is theirs.

## Step 5: Execute Choice

### Option 1: Merge Locally

Record `REVIEWED_OID` at the Step 4 gate from this session's passed review
chain. If that review is missing, run it before integrating. A menu choice
of Option 1 uses `merge locally`; a recognised `Finish branch:` line uses
its stated value. All three use the integration rule, steps a-g above.

Resolve `<main-checkout>` before starting (without switching its branch):

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
```

Once the result has landed and no question remains, move outside the
feature worktree, clean it up (Step 6), then delete the branch only if it
still points at `REVIEWED_OID`:

```bash
cd "$MAIN_ROOT"
git branch -d <feature-branch>
```

### Option 2: Push and Create PR

```bash
git push -u origin <feature-branch>
# From a detached HEAD, name the new branch on the remote:
# git push origin HEAD:refs/heads/<new-branch>
```

Then create the pull/merge request against <base-branch> with the forge's
tooling — its CLI if one is available, or the creation URL most forges
print when you push — following the repo's PR template and conventions if
present, and report the URL to your human partner.

Keep the worktree — your human partner iterates on PR feedback there.

### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

### If your human partner asks to discard the work

This path exists only as a response to an explicit request to throw the
work away. Confirm first:

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for that exact confirmation. When it arrives:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then clean up the worktree (Step 6) and force-delete the branch:

```bash
git branch -D <feature-branch>
```

## Step 6: Cleanup Workspace

**Runs for Option 1 and confirmed discards.** Options 2 and 3 always
preserve the worktree. Both callers have already changed directory to the
main repo root — worktree removal must run from outside the worktree —
and use the `GIT_DIR`/`GIT_COMMON`/`WORKTREE_PATH` values captured in
Step 2, from before that directory change.

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If `WORKTREE_PATH` is under `.worktrees/` or `worktrees/`:** Superpowers
created this worktree — we own cleanup:

```bash
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**If removal is refused** (`contains modified or untracked files`): the
worktree holds files that exist nowhere else — uncommitted plans, notes,
or scratch work. Never `--force` on your own initiative. Show your human
partner what is at stake and ask:

```bash
git -C "$WORKTREE_PATH" status --porcelain -uall
```

```
Worktree removal refused — these files were never committed:

<file list>

1. Commit them to <branch> before cleanup
2. Move them into <main repo root>
3. Delete them (unrecoverable)

Which?
```

Carry out the choice, then remove the worktree.

**Otherwise:** The host environment owns this workspace — leave it in
place. If your platform provides a workspace-exit tool, use it.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| Discard (explicit request only) | - | - | - | yes (force) |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Tests passed earlier this session" | Run the suite on the tree you are about to integrate. A green run only proves the tree it ran on. |
| "They obviously want it merged" | Integration is your human partner's decision. Present the menu and wait. |
| "They seem done with this feature — I'll offer to discard it" | The menu is complete as written. Discard happens only when your human partner asks for it in so many words. |
| "'Yeah, get rid of it' counts as confirmation" | Only the typed word `discard` authorizes deletion. |
| "The PR is up, so the worktree is clutter now" | PR feedback gets fixed in that worktree. It stays until the work lands. |
| "This other worktree looks stale — I'll clean it too" | Clean up only worktrees under `.worktrees/` or `worktrees/`. Everything else belongs to the host. |
| "Removal refused — `--force` is just finishing the cleanup" | The refusal means files exist only in that worktree. `--force` destroys them permanently. Show your human partner and ask. |
| "The merged-result failure is probably flaky" | A failing merged result stops everything. Branch and worktree stay put while you investigate. |
| "The base branch is obviously main" | Confirm the fork point or ask. Merging into the wrong base is expensive to undo. |
| "The push was rejected — force-push will fix it" | A rejected push means the remote moved. Investigate; force-push only on your human partner's explicit request. |
