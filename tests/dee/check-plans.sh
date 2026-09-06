#!/usr/bin/env bash
set -euo pipefail
F="$(dirname "$0")/../../skills/writing-plans/SKILL.md"
grep -qF -- '**Wide refactors are the exception.**' "$F" && grep -qF -- 'expand–contract' "$F" && echo "plans: OK" || { echo "MISSING: expand-contract"; exit 1; }
