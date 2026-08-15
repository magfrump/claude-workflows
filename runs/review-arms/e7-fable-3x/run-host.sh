#!/usr/bin/env bash
# E7 arm: Claude Code's built-in /code-review skill, headless in Docker,
# on **Fable 5** (claude-fable-5) with **3x replication** per instance.
# ── RUN FROM THE HOST (WSL terminal), never from inside a Claude session ──
# (docker cannot run inside a session; same constraint as E5/cc-isolated.)
#
# Identical harness to E5 (runs/review-arms/e5-cc-builtin/run-host.sh) except:
#   * --model claude-fable-5  (exact ID; $10/$50 per MTok — 2x Opus)
#   * 3 replications per instance → e7-fable-3x/<id>/rep{1,2,3}/
#   * --max-budget-usd 15.00 per run (Fable is 2x price and thinks longer)
#
# Replication rationale: E5 gave one sample per cell; with Fable we want
# within-arm variance — which hits are stable across reps vs. lottery draws —
# and the union-of-3-reps recall as a cheap ensemble datapoint.
#
# Cost estimate (pre-run): E5-opus averaged $0.88/instance. Fable at 2x price
# + longer thinking ≈ $1.8–2.6/instance → ~$14–21 per 8-instance rep,
# ~$45–65 for the full 3x sweep. Trim via args if that's too much.
#
# Prereqs: docker; clones built by scripts/prep-cc-review-clones.sh; and ONE of:
#   * CLAUDE_CODE_OAUTH_TOKEN — subscription billing. Mint once on the host with
#     `claude setup-token` (long-lived OAuth token; plain env var, so the
#     container still gets zero ~/.claude state). Caveats: total_cost_usd in
#     result.json is then a list-price ESTIMATE, not a bill — label it so in
#     the results doc; and 24 Fable runs draw on weekly subscription limits —
#     a mid-sweep limit failure confounds the arm (cf. E6 free-tier), though
#     the rep-skip logic lets you resume after the window resets.
#   * ANTHROPIC_API_KEY — API billing; total_cost_usd authoritative. Fable
#     needs 30-day data retention on the org (ZDR orgs 400 on every request).
# If both are set, the OAuth token wins (API key is not passed in).
#
# Usage:  bash runs/review-arms/e7-fable-3x/run-host.sh [instance...]
#         REPS=2 bash runs/review-arms/e7-fable-3x/run-host.sh mfc-csp   # fewer reps / subset
set -euo pipefail
cd "$(dirname "$0")/../../.."
ROOT="$PWD"
CLONES="$ROOT/external/cc-review-eval"
OUT="$ROOT/runs/review-arms/e7-fable-3x"
CC_VERSION="2.1.232"   # pin for reproducibility; bump deliberately
REPS="${REPS:-3}"
[ $# -gt 0 ] && INSTANCES=("$@") || INSTANCES=(mfc-csp mfc-lean mfc-hygiene mfc-secdeps mfc-deploy mfc-fscompat mfc-corpus mfc-postfix)

if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  AUTH_ENV=(-e CLAUDE_CODE_OAUTH_TOKEN)
  echo "Auth: subscription (CLAUDE_CODE_OAUTH_TOKEN) — total_cost_usd will be a list-price estimate, not billed spend."
elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  AUTH_ENV=(-e ANTHROPIC_API_KEY)
  echo "Auth: API key — total_cost_usd authoritative."
else
  echo "Set CLAUDE_CODE_OAUTH_TOKEN (subscription; mint via 'claude setup-token') or ANTHROPIC_API_KEY" >&2
  exit 1
fi

# Docker creates a fresh named volume root-owned, but the review container runs
# as uid 1000 (-u node) — chown it once, as root, before any -u node mount.
docker run --rm -v cc-review-npm-cache:/home/node/.npm node:22 \
  chown -R node:node /home/node/.npm

for id in "${INSTANCES[@]}"; do
  clone="$CLONES/$id"
  [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/prep-cc-review-clones.sh" >&2; exit 1; }
  for rep in $(seq 1 "$REPS"); do
    dest="$OUT/$id/rep$rep"
    if [ -s "$dest/result.json" ]; then
      echo "=== E7: $id rep$rep — result.json exists, skipping (delete to re-run)"
      continue
    fi
    mkdir -p "$dest"
    echo "=== E7: $id rep$rep"
    t0=$(date +%s)
    # -u node: non-root (required by --dangerously-skip-permissions);
    # named volume caches the npx download across runs;
    # --bare: no hooks/plugins/user-state — the repo's own CLAUDE.md is part
    # of the tree under review and loads as it would for any real user.
    docker run --rm -u node -w /repo \
      "${AUTH_ENV[@]}" \
      -v "$clone":/repo \
      -v cc-review-npm-cache:/home/node/.npm \
      node:22 \
      npx -y @anthropic-ai/claude-code@"$CC_VERSION" \
        --bare -p "/code-review main" \
        --model claude-fable-5 \
        --output-format json \
        --dangerously-skip-permissions \
        --max-budget-usd 15.00 \
      > "$dest/result.json" 2> "$dest/stderr.log" || {
        echo "$id rep$rep: claude exited non-zero — see $dest/stderr.log" >&2; continue; }
    t1=$(date +%s)
    python3 - "$dest/result.json" "$((t1-t0))" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"  cost=${d.get('total_cost_usd','?')} duration={sys.argv[2]}s "
      f"turns={d.get('num_turns','?')} result_len={len(d.get('result') or '')}")
EOF
  done
done
echo "E7 done. Results in $OUT/<instance>/rep<N>/result.json (cost in total_cost_usd)."
echo "Next: hand back to the workspace session for adjudication against the ledger"
echo "(score each rep as its own cell; also compute per-instance union-of-reps)."
