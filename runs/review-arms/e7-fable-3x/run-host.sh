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
#   * CLAUDE_CREDENTIALS=~/.claude/.credentials.json — subscription billing.
#     A copy of the file is mounted as the container's ~/.claude (credential
#     only; no skills/hooks/CLAUDE.md leak). Caveats: total_cost_usd in
#     result.json is then a list-price ESTIMATE, not a bill — label it so in
#     the results doc; and 24 Fable runs draw on weekly subscription limits —
#     a mid-sweep limit failure confounds the arm (cf. E6 free-tier), though
#     the rep-skip logic lets you resume after the window resets.
#     IMPORTANT ARM-CONDITION DEVIATION vs E5: --bare blocks ALL subscription
#     auth (env token and stored credentials alike — probe-verified
#     2026-08-15), so subscription runs drop --bare. Consequence: repo-level
#     .claude/agents + .claude/commands load in the 3 instances that have
#     them (mfc-csp, mfc-deploy, mfc-secdeps; none appear in the diffs under
#     review). Note this in the E7 results doc.
#   * ANTHROPIC_API_KEY — API billing; total_cost_usd authoritative. Fable
#     needs 30-day data retention on the org (ZDR orgs 400 on every request).
# If both are set, the credentials file wins (API key is not passed in).
#
# Usage:  CLAUDE_CREDENTIALS=~/.claude/.credentials.json bash runs/review-arms/e7-fable-3x/run-host.sh [instance...]
#         REPS=2 ... run-host.sh mfc-csp   # fewer reps / subset
set -euo pipefail
cd "$(dirname "$0")/../../.."
ROOT="$PWD"
CLONES="$ROOT/external/cc-review-eval"
OUT="$ROOT/runs/review-arms/e7-fable-3x"
CC_VERSION="2.1.232"   # pin for reproducibility; bump deliberately
REPS="${REPS:-3}"
[ $# -gt 0 ] && INSTANCES=("$@") || INSTANCES=(mfc-csp mfc-lean mfc-hygiene mfc-secdeps mfc-deploy mfc-fscompat mfc-corpus mfc-postfix)

# Auth resolution, in preference order:
#   1. CLAUDE_CREDENTIALS — path to a .credentials.json (usually
#      ~/.claude/.credentials.json, written by 'claude /login'). A COPY is
#      mounted as the container's ~/.claude, so only the credential — no
#      skills/hooks/CLAUDE.md — crosses into the arm. This is the working
#      subscription path: verified 2026-08-14 that CLI 2.1.232 in --bare
#      headless mode does NOT honor CLAUDE_CODE_OAUTH_TOKEN (token present in
#      container, still 'Not logged in').
#   2. ANTHROPIC_API_KEY — API billing; total_cost_usd authoritative.
# Caveat for mode 1: if the container refreshes the OAuth token mid-sweep and
# the provider rotates refresh tokens, the host's copy can go stale — if
# 'claude' on the host later demands /login, that's why.
AUTH_ENV=() AUTH_MOUNT=()
if [ -n "${CLAUDE_CREDENTIALS:-}" ]; then
  [ -f "$CLAUDE_CREDENTIALS" ] || { echo "CLAUDE_CREDENTIALS=$CLAUDE_CREDENTIALS: no such file" >&2; exit 1; }
  AUTH_DIR=$(mktemp -d)
  trap 'rm -rf "$AUTH_DIR"' EXIT
  cp "$CLAUDE_CREDENTIALS" "$AUTH_DIR/.credentials.json"
  chmod 700 "$AUTH_DIR"; chmod 600 "$AUTH_DIR/.credentials.json"
  AUTH_MOUNT=(-v "$AUTH_DIR":/home/node/.claude)
  BARE_FLAG=()   # --bare blocks stored subscription credentials (verified 2026-08-15)
  echo "Auth: subscription (credentials file copy, non-bare) — total_cost_usd will be a list-price estimate, not billed spend."
elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  AUTH_ENV=(-e ANTHROPIC_API_KEY)
  BARE_FLAG=(--bare)   # E5 parity
  echo "Auth: API key (--bare) — total_cost_usd authoritative."
else
  echo "Set CLAUDE_CREDENTIALS=~/.claude/.credentials.json (subscription) or ANTHROPIC_API_KEY (API billing)" >&2
  exit 1
fi

# Docker creates a fresh named volume root-owned, but the review container runs
# as uid 1000 (-u node) — chown it once, as root, before any -u node mount.
docker run --rm -v cc-review-npm-cache:/home/node/.npm node:22 \
  chown -R node:node /home/node/.npm

# ── Auth preflight ──────────────────────────────────────────────────────────
# A bad credential does NOT make claude exit non-zero: it returns exit 0 with
# result "Not logged in · Please run /login" and num_turns=0 (learned the hard
# way, 2026-08-14). Verify auth with one cheap prompt before burning the sweep.
echo "=== E7 preflight: verifying auth inside the container"
docker run --rm -u node "${AUTH_ENV[@]}" "${AUTH_MOUNT[@]}" -v cc-review-npm-cache:/home/node/.npm node:22 \
  sh -c '[ -f /home/node/.claude/.credentials.json ] && echo "  credentials file mounted" || echo "  api key length in container: ${#ANTHROPIC_API_KEY}"'
preflight=$(docker run --rm -u node "${AUTH_ENV[@]}" "${AUTH_MOUNT[@]}" -v cc-review-npm-cache:/home/node/.npm node:22 \
  npx -y @anthropic-ai/claude-code@"$CC_VERSION" \
    "${BARE_FLAG[@]}" -p "Reply with exactly: OK" --model claude-fable-5 --output-format json 2>&1) || true
if ! printf '%s' "$preflight" | python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read().strip().splitlines()[-1])
except Exception:
    sys.exit(1)
r = d.get("result") or ""
sys.exit(0 if d.get("num_turns", 0) > 0 and "log in" not in r.lower() and "logged in" not in r.lower() else 1)
'; then
  echo "PREFLIGHT FAILED — the CLI could not authenticate. Raw response:" >&2
  printf '%s\n' "$preflight" >&2
  echo "Subscription mode: check the host file is fresh — run 'claude' interactively once to refresh, then retry." >&2
  echo "API mode: check the key and the org's data-retention setting (Fable needs 30-day retention)." >&2
  exit 1
fi
echo "  preflight OK"

for id in "${INSTANCES[@]}"; do
  clone="$CLONES/$id"
  [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/prep-cc-review-clones.sh" >&2; exit 1; }
  for rep in $(seq 1 "$REPS"); do
    dest="$OUT/$id/rep$rep"
    # Skip only genuinely completed reps: a failed-auth run leaves a result.json
    # with num_turns=0, which must be re-run, not skipped.
    if [ -s "$dest/result.json" ] && python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
sys.exit(0 if d.get("num_turns", 0) > 0 else 1)
' "$dest/result.json" 2>/dev/null; then
      echo "=== E7: $id rep$rep — completed result exists, skipping (delete to re-run)"
      continue
    fi
    mkdir -p "$dest"
    echo "=== E7: $id rep$rep"
    t0=$(date +%s)
    # -u node: non-root (required by --dangerously-skip-permissions);
    # named volume caches the npx download across runs;
    # BARE_FLAG: --bare (API mode, E5 parity) or empty (subscription — --bare
    # blocks stored credentials). Either way the container's ~/.claude holds at
    # most the credential, so no host skills/hooks/CLAUDE.md can leak; the
    # repo's own CLAUDE.md (and, non-bare, its .claude/agents+commands) loads
    # as it would for any real user.
    docker run --rm -u node -w /repo \
      "${AUTH_ENV[@]}" "${AUTH_MOUNT[@]}" \
      -v "$clone":/repo \
      -v cc-review-npm-cache:/home/node/.npm \
      node:22 \
      npx -y @anthropic-ai/claude-code@"$CC_VERSION" \
        "${BARE_FLAG[@]}" -p "/code-review main" \
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
