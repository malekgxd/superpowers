#!/usr/bin/env bash
# All fork-edit checks. Exit non-zero on the first failure.
set -euo pipefail
cd "$(dirname "$0")"
for t in check-brainstorming.sh check-debugging.sh check-tdd.sh check-review.sh check-plans.sh; do bash "$t"; done
python3 check-version.py
echo "fork checks: ALL OK"
