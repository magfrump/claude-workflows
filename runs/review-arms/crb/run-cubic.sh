#!/usr/bin/env bash
# Cubic CLI arm over the 8 canon instances (docs/working/crb-arm-plan.md).
#
# One-time setup (interactive, run in a normal terminal):
#   1. Install the CLI:            npm i -g @cubic-dev-ai/cli
#      (or set CUBIC_BIN to an unpacked binary path)
#   2. Sign in to cubic.dev:       cubic auth login
#      REQUIRED for `cubic review` — the binary hard-errors with "Cubic auth is
#      required to start a review" otherwise. Free account; browser flow.
#   3. Connect Claude Code auth:   cubic auth connect claude-code
#      — makes the local logged-in `claude` CLI the model provider (ACP).
#      This sets a preference flag only; `auth list` will still show just the
#      cubic.dev credential from step 2, which is expected.
#   4. Verify:                     cubic auth list     (expect 1 credential)
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
# `cubic review` requires a cubic.dev session in auth.json ("Cubic auth is
# required to start a review", verified against the 1.10.4 binary) — the
# claude-code ACP connect alone is only the model provider, not review auth.
if "$CUBIC_BIN" auth list 2>/dev/null | grep -q "0 credentials"; then
  echo 'no cubic.dev session — "cubic review" refuses to start without one.' >&2
  echo 'run: cubic auth login   (free account; then optionally keep the' >&2
  echo 'claude-code provider via: cubic auth connect claude-code)' >&2
  exit 1
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
  # Use a local clone, not a git worktree: worktrees have a `.git` *file*
  # pointing back into the main repo, which some tools' git integration can't
  # follow. A same-disk clone shares objects via hardlinks, so it's cheap.
  if [ -d "$wt" ] && [ -f "$wt/.git" ]; then
    echo "    replacing stale worktree checkout at $wt with a clone"
    git -C "$MFC" worktree remove --force "../../$wt" || rm -rf "$wt"
  fi
  if [ ! -d "$wt" ]; then
    git clone -q --no-checkout "$MFC" "$wt"
  fi
  git -C "$wt" checkout -q --detach "$head"
  git -C "$wt" branch -f "crb-base-$inst" "$base"

  echo "=== $inst ($base..$head)"
  start=$(date +%s)
  if (cd "$wt" && "$CUBIC_BIN" review --base "crb-base-$inst" --json \
        --print-logs --log-level "${CUBIC_LOG_LEVEL:-DEBUG}" \
        >"../../../$out/review.json" 2>"../../../$out/stderr.log"); then
    secs=$(( $(date +%s) - start ))
    echo "    ok in ${secs}s -> $out/review.json"
    ran=$((ran+1))
  else
    secs=$(( $(date +%s) - start ))
    echo "    FAILED after ${secs}s — see $out/stderr.log (review.json removed if empty)"
    echo "    --- last stderr lines ---"
    tail -n 8 "$out/stderr.log" | sed 's/^/    | /'
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
