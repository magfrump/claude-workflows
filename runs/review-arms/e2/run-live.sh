#!/usr/bin/env bash
# E2 live sweep (docs/working/review-canon.md §3): lite arm (base = sonnet-5 k=1,
# Stage-1 context) on every canon dirty state. Projected total ≈ $0.50.
# Usage:  OPENROUTER_API_KEY=sk-or-... bash runs/review-arms/e2/run-live.sh
# mfc-postfix is not re-run: its base-arm results already exist at
# runs/review-arms/mfc-2026-08-06/base/.
set -euo pipefail
cd "$(dirname "$0")/../../.."

[ -n "${OPENROUTER_API_KEY:-}" ] || { echo "OPENROUTER_API_KEY not set" >&2; exit 1; }

run() { # id base head
  echo "=== E2: $1 ($2..$3)"
  python3 scripts/review-arms.py \
    --repo external/meta-formalism-copilot \
    --range "$2..$3" --context-base "$2" \
    --out "runs/review-arms/e2/$1" --arms base --max-usd 2.00
}

run mfc-csp      d86d2dc d90d6bb
run mfc-lean     d86d2dc c95c9cb
run mfc-hygiene  d86d2dc f2f149b
run mfc-secdeps  d86d2dc 8bde50c
run mfc-deploy   d86d2dc 4329d6e
run mfc-fscompat d86d2dc b64c1ca
run mfc-corpus   dc6dfb0 2dc403e

echo "E2 sweep complete. Findings in runs/review-arms/e2/*/base/findings.jsonl"
echo "Next: score against canon labels (docs/working/review-canon.md §1 rubrics)."
