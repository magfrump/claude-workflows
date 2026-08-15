#!/usr/bin/env bash
# Cubic CLI arm over the 8 canon instances (docs/working/crb-arm-plan.md).
#
# One-time setup (interactive, run in a normal terminal):
#   1. Install the CLI:            npm i -g @cubic-dev-ai/cli
#      (or set CUBIC_BIN to an unpacked binary path)
#   2. Connect Claude Code auth:   cubic auth connect claude-code
#      — reuses your Claude Code login; no cubic.dev account or API key needed.
#   3. Verify:                     cubic auth list     (expect 1 credential)
#
# Then run the sweep:
#   bash runs/review-arms/crb/run-cubic.sh            # all 8 instances
#   bash runs/review-arms/crb/run-cubic.sh mfc-csp    # subset / smoke test
#
# Per instance this creates a worktree of external/meta-formalism-copilot at the
# instance head, points a crb-base-<inst> branch at the context base, and runs
#   cubic review --base crb-base-<inst> --json
# capturing stdout JSON to runs/review-arms/crb/cubic-cli/<inst>/review.json.
# Idempotent: instances with an existing non-empty review.json are skipped
# (delete the file to re-run). Worktrees are left in place under
# external/crb-cubic/ for inspection; remove with:
#   git -C external/meta-formalism-copilot worktree remove ../crb-cubic/<inst>
#
# Notes:
# - This is cubic's LOCAL CLI review ("intentionally faster and less thorough"
#   than their cloud PR review, per cubic docs). Ledger tool name: cubic-cli.
# - Sends mfc file contents to cubic's model backend via your Claude Code
#   account — same exposure class as the E2/E4 arms.
set -euo pipefail
cd "$(dirname "$0")/../../.."   # workspace root

CUBIC_BIN="${CUBIC_BIN:-cubic}"
MFC=external/meta-formalism-copilot
WT_ROOT=external/crb-cubic
OUT_ROOT=runs/review-arms/crb/cubic-cli
export CUBIC_DISABLE_ANALYTICS=1 CUBIC_DISABLE_AUTOUPDATE=1

command -v "$CUBIC_BIN" >/dev/null || { echo "cubic not found (npm i -g @cubic-dev-ai/cli, or set CUBIC_BIN)" >&2; exit 1; }
# NOTE: `cubic auth list` reporting "0 credentials" is EXPECTED in claude-code
# mode — `auth connect claude-code` sets a claudeCodeEnabled preference flag
# and drives the local `claude` CLI via ACP; it stores nothing in auth.json.
# The real prerequisites are: `claude` on PATH and logged in.
if "$CUBIC_BIN" auth list 2>/dev/null | grep -q "0 credentials"; then
  command -v claude >/dev/null || {
    echo "0 cubic credentials and no claude CLI on PATH — run either" >&2
    echo "  cubic auth connect claude-code   (needs a logged-in claude CLI)" >&2
    echo "or cubic auth login" >&2; exit 1; }
  echo "note: 0 stored credentials — assuming claude-code ACP mode (this is normal)"
fi

# id  base     head   (ranges: docs/working/review-canon.md §1)
INSTANCES="
mfc-csp      d86d2dc d90d6bb
mfc-lean     d86d2dc c95c9cb
mfc-hygiene  d86d2dc f2f149b
mfc-secdeps  d86d2dc 8bde50c
mfc-deploy   d86d2dc 4329d6e
mfc-fscompat d86d2dc b64c1ca
mfc-corpus   dc6dfb0 2dc403e
mfc-postfix  9c9edf5 7f30210
"

mkdir -p "$WT_ROOT"
ran=0; skipped=0; failed=0
while read -r inst base head; do
  [ -n "$inst" ] || continue
  # optional positional filter: run only the named instances
  if [ "$#" -gt 0 ]; then
    case " $* " in *" $inst "*) ;; *) continue ;; esac
  fi

  out="$OUT_ROOT/$inst"
  if [ -s "$out/review.json" ]; then
    echo "=== $inst: review.json exists, skipping"; skipped=$((skipped+1)); continue
  fi
  mkdir -p "$out"

  wt="$WT_ROOT/$inst"
  if [ ! -d "$wt" ]; then
    git -C "$MFC" worktree add "../../$wt" "$head"
  fi
  git -C "$wt" branch -f "crb-base-$inst" "$base"

  echo "=== $inst ($base..$head)"
  start=$(date +%s)
  if (cd "$wt" && "$CUBIC_BIN" review --base "crb-base-$inst" --json \
        >"../../../$out/review.json" 2>"../../../$out/stderr.log"); then
    secs=$(( $(date +%s) - start ))
    echo "    ok in ${secs}s -> $out/review.json"
    ran=$((ran+1))
  else
    secs=$(( $(date +%s) - start ))
    echo "    FAILED after ${secs}s — see $out/stderr.log (review.json removed if empty)"
    [ -s "$out/review.json" ] || rm -f "$out/review.json"
    failed=$((failed+1))
  fi
done <<EOF
$INSTANCES
EOF

"$CUBIC_BIN" --version >"$OUT_ROOT/cubic-version.txt" 2>&1 || true
echo
echo "cubic sweep done: $ran ran, $skipped skipped, $failed failed"
echo "next: convert to benchmark reviews (scripts/canon-to-crb.py will pick up"
echo "runs/review-arms/crb/cubic-cli/*/review.json once the cubic converter lands)"
