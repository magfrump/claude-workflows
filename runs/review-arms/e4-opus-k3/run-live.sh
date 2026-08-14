#!/usr/bin/env bash
# E4 live sweep (2026-08-13): middle-ground arm (opus-k3 = opus-5, k=3,
# Stage-1 context, union-scored) on every canon dirty state — the same seven
# instances and config shape as E2 (runs/review-arms/e2/run-live.sh), so the
# recall numbers are directly comparable to E2's 6/24 and the full harness's
# 24/24 columns in docs/human-author/"LLM Code Review.md".
# Projected total ≈ $6 (E2 was $0.81 at sonnet intro pricing; opus is 2.5x
# per token and k=3 triples the calls).
# Usage:  OPENROUTER_API_KEY=sk-or-... bash runs/review-arms/e4-opus-k3/run-live.sh
set -euo pipefail
cd "$(dirname "$0")/../../.."

[ -n "${OPENROUTER_API_KEY:-}" ] || { echo "OPENROUTER_API_KEY not set" >&2; exit 1; }

run() { # id base head
  echo "=== E4: $1 ($2..$3)"
  python3 scripts/review-arms.py \
    --repo external/meta-formalism-copilot \
    --range "$2..$3" --context-base "$2" \
    --out "runs/review-arms/e4-opus-k3/$1" --arms opus-k3 --max-usd 5.00
}

run mfc-csp      d86d2dc d90d6bb
run mfc-lean     d86d2dc c95c9cb
run mfc-hygiene  d86d2dc f2f149b
run mfc-secdeps  d86d2dc 8bde50c
run mfc-deploy   d86d2dc 4329d6e
run mfc-fscompat d86d2dc b64c1ca
run mfc-corpus   dc6dfb0 2dc403e

echo "E4 sweep complete. Findings in runs/review-arms/e4-opus-k3/*/opus-k3/findings.jsonl"
echo "Next: score UNION of replicates against canon labels (docs/working/review-canon.md §1)."
