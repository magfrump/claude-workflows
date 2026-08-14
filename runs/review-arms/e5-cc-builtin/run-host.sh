#!/usr/bin/env bash
# E5 arm: Claude Code's BUILT-IN /code-review skill, isolated in Docker.
# ── RUN FROM THE HOST (WSL terminal), never from inside a Claude session ──
# (docker cannot run inside a session; same constraint as cc-isolated.)
#
# Per canon instance this runs, in a fresh node:22 container with no ~/.claude
# state (so none of claude-workflows' skills/CLAUDE.md/hooks leak in — the
# decision-022 payload is a cc-isolated feature, deliberately NOT used here):
#   claude --bare -p "/code-review main" --model opus --output-format json
# against the truncated clone (branch `review` vs `main` = the canon range).
#
# Prereqs: docker; ANTHROPIC_API_KEY exported (API billing => the JSON
# envelope's total_cost_usd is authoritative); clones built by
# scripts/prep-cc-review-clones.sh.
#
# Usage:  ANTHROPIC_API_KEY=sk-ant-... bash runs/review-arms/e5-cc-builtin/run-host.sh [instance...]
#         (default: all eight)
set -euo pipefail
cd "$(dirname "$0")/../../.."
ROOT="$PWD"
CLONES="$ROOT/external/cc-review-eval"
OUT="$ROOT/runs/review-arms/e5-cc-builtin"
CC_VERSION="2.1.232"   # pin for reproducibility; bump deliberately
INSTANCES=("${@:-mfc-csp mfc-lean mfc-hygiene mfc-secdeps mfc-deploy mfc-fscompat mfc-corpus mfc-postfix}")
[ $# -gt 0 ] && INSTANCES=("$@") || INSTANCES=(mfc-csp mfc-lean mfc-hygiene mfc-secdeps mfc-deploy mfc-fscompat mfc-corpus mfc-postfix)

[ -n "${ANTHROPIC_API_KEY:-}" ] || { echo "ANTHROPIC_API_KEY not set" >&2; exit 1; }

for id in "${INSTANCES[@]}"; do
  clone="$CLONES/$id"
  [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/prep-cc-review-clones.sh" >&2; exit 1; }
  mkdir -p "$OUT/$id"
  echo "=== E5: $id"
  t0=$(date +%s)
  # -u node: non-root (required by --dangerously-skip-permissions);
  # named volume caches the npx download across instances;
  # --bare: no hooks/plugins/user-state — but the repo's own CLAUDE.md is part
  # of the tree under review and loads as it would for any real user.
  docker run --rm -u node -w /repo \
    -e ANTHROPIC_API_KEY \
    -v "$clone":/repo \
    -v cc-review-npm-cache:/home/node/.npm \
    node:22 \
    npx -y @anthropic-ai/claude-code@"$CC_VERSION" \
      --bare -p "/code-review main" \
      --model opus \
      --output-format json \
      --dangerously-skip-permissions \
      --max-budget-usd 5.00 \
    > "$OUT/$id/result.json" 2> "$OUT/$id/stderr.log" || {
      echo "$id: claude exited non-zero — see $OUT/$id/stderr.log" >&2; continue; }
  t1=$(date +%s)
  python3 - "$OUT/$id/result.json" "$((t1-t0))" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"  cost=${d.get('total_cost_usd','?')} duration={sys.argv[2]}s "
      f"turns={d.get('num_turns','?')} result_len={len(d.get('result') or '')}")
EOF
done
echo "E5 done. Results in $OUT/<instance>/result.json (cost in total_cost_usd)."
echo "Next: hand back to the workspace session for adjudication against the ledger."
