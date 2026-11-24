#!/usr/bin/env bash
# Test: subagent-driven-development skill
# Verifies that the skill is loaded and follows correct workflow
#
# No drill coverage: this test asks the agent to *describe* SDD (string-
# matches its verbal explanation against expected keywords like
# "self-review", "no per-task review", "worktree", "Step 1", "commits"). Drill
# scenarios test behavior (real subagent dispatch, plan-following, end review),
# not description-recall. Kept by design.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

CLAUDE_PROMPT_TIMEOUT="${CLAUDE_PROMPT_TIMEOUT:-90}"

echo "=== Test: subagent-driven-development skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the subagent-driven-development skill? Describe its key steps briefly." "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "subagent-driven-development\|Subagent-Driven Development\|Subagent Driven" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Load Plan\|read.*plan\|extract.*tasks" "Mentions loading plan"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify skill describes correct workflow order
echo "Test 2: Workflow ordering..."

output=$(run_claude "In the subagent-driven-development skill, is there a review after each task, and when does the review of the change happen? Answer using exactly this structure:
Per-task review: <yes or no>
Review happens: <after each task or once at the end>" "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "Per-task review:.*no" "No per-task review"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Review happens:.*\(once\|end\|whole\)" "One review at the end"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify self-review is mentioned
echo "Test 3: Self-review requirement..."

output=$(run_claude "Does the subagent-driven-development skill require implementers to self-review before handoff, and can self-review replace the end review of the whole change? Answer using exactly this structure:
Self-review required: <yes or no>
Self-review replaces external review: <yes or no>" "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "Self-review required:.*yes" "Mentions self-review"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Self-review replaces external review:.*no" "Self-review does not replace external review"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify plan is read once
echo "Test 4: Plan reading efficiency..."

output=$(run_claude "In subagent-driven-development, how many times should the controller read the plan file? When does this happen?" "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "once\|one time\|single" "Read plan once"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Step 1\|beginning\|start\|Load Plan" "Read at beginning"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify the orchestrator commits, builders do not
echo "Test 5: Who commits a task..."

output=$(run_claude "In subagent-driven-development, who commits a task: the builder subagent or the controller? Answer using exactly this structure:
Commits the task: <builder or controller>
Builder runs git commands that write: <yes or no>" "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "Commits the task:.*\(controller\|orchestrator\)" "Controller commits"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Builder runs git commands that write:.*no" "Builder runs no writing git command"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify failure handling without a per-task review loop
echo "Test 6: Failure handling..."

output=$(run_claude "In subagent-driven-development, what happens when a test that one task owns fails after a wave is committed? Is there a per-task review loop?" "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "back to.*builder\|redispatch\|builder.*fix\|fix.*builder" "Failure goes back to the task's builder"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "no.*per-task review\|end review\|once.*end\|review.*whole change" "No per-task review loop; one end review"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify the task brief is handed over as a file
echo "Test 7: Task context provision..."

output=$(run_claude "In subagent-driven-development, how does the controller provide task information to the implementer subagent? Answer using exactly this structure:
Controller provides: <directly or by file>
Implementer must read plan file: <yes or no>" "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "Controller provides:.*\(file\|brief\)" "Provides the brief by file"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Implementer must read plan file:.*no" "Doesn't make subagent read file"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify worktree requirement
echo "Test 8: Worktree requirement..."

output=$(run_claude "What workflow skills are required before using subagent-driven-development? List any prerequisites or required skills." "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "using-git-worktrees\|worktree" "Mentions worktree requirement"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 9: Verify main branch warning
echo "Test 9: Main branch red flag..."

output=$(run_claude "In subagent-driven-development, is it okay to start implementation directly on the main branch?" "$CLAUDE_PROMPT_TIMEOUT")

if assert_contains "$output" "worktree\|feature.*branch\|not.*main\|never.*main\|avoid.*main\|don't.*main\|consent\|permission" "Warns against main branch"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All subagent-driven-development skill tests passed ==="
