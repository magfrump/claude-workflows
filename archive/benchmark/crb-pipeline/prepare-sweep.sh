#!/usr/bin/env bash
# Pre-sweep bootstrap for the CRB direction-(1) arm.
# ── RUN FROM THE HOST (WSL terminal), never from inside a Claude session ──
#
# Everything that must be true before the first paid cell, in the order it must
# be true, with the two things that can only be settled on a real docker host
# done FIRST and cheapest. Run this, read what it prints, then run one cell.
#
# It exists because three of the four preconditions are easy to miss and one of
# them fails as a clean `exit 3` that looks like "nothing to do":
#
#   1. Baselines.  Clones materialized before 2026-08-19 have none, and the
#      sweep skips every instance without them. There is deliberately NO mode
#      that baselines an existing clone in place — that path ran host `git`
#      against a `.git` an agent container had written, which is the whole
#      reason the disposable-clone design exists (decision 034). So a clone
#      without a baseline is REBUILT: re-cloned from the fork, re-verified,
#      re-snapshotted. That costs a re-download (~670 MB for the 5-PR pilot).
#   2. Images + egress.  The allowlist is the control that makes the arm's
#      numbers mean anything, and its only honest verification is execution.
#      PREFLIGHT_ONLY=1 builds the images, creates the network, starts the
#      proxy, proves the five egress legs, and confirms auth + skill
#      registration — then stops. Cost: ONE billed auth turn, not $0.
#   3. The first cell is read by a human before any sweep.
#
# Usage:
#   ANTHROPIC_API_KEY=sk-ant-... bash runs/review-arms/crb-pipeline/prepare-sweep.sh
#   ... prepare-sweep.sh --dry-run          # print the plan, touch nothing, $0
#   ... prepare-sweep.sh --skip-rebuild     # baselines already exist and you know it
#   ... prepare-sweep.sh keycloak-PR36880   # only this slug
#
# BILLING: use an Anthropic API key, not a subscription login. Under API billing
# each cell's `result.json` carries an authoritative `total_cost_usd`, which is
# what `run-meta.json` totals and what `SWEEP_BUDGET` gates on; a subscription
# run reports no usable cost and hits quota limits mid-sweep instead of a
# budget ceiling you chose. (See docs/working/crb-direction1-setup.md.)
set -euo pipefail
cd "$(dirname "$0")/../../.."
ROOT="$PWD"
MANIFEST="$ROOT/runs/review-arms/crb/instances.json"
CLONES="$ROOT/external/crb-eval"
RUNNER="$ROOT/runs/review-arms/crb-pipeline/run-host.sh"

DRY_RUN=""; SKIP_REBUILD=""; SLUGS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run)      DRY_RUN=1 ;;
    --skip-rebuild) SKIP_REBUILD=1 ;;
    -h|--help)      sed -n '2,40p' "$0"; exit 0 ;;
    -*)             echo "unknown flag: $arg" >&2; exit 1 ;;
    *)              SLUGS+=("$arg") ;;
  esac
done

step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
note() { printf '   %s\n' "$*"; }

[ -f "$MANIFEST" ] || {
  echo "no $MANIFEST — run scripts/crb-materialize.py --per-repo 1 first" >&2; exit 1; }

if [ "${#SLUGS[@]}" -eq 0 ]; then
  mapfile -t SLUGS < <(python3 -c '
import json, sys
print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$MANIFEST")
fi
[ "${#SLUGS[@]}" -gt 0 ] || { echo "no instances in $MANIFEST" >&2; exit 1; }

# ── 0. What needs doing ──────────────────────────────────────────────────────
step "0. Checking preconditions for ${#SLUGS[@]} instance(s)"
NEED_REBUILD=()
for slug in "${SLUGS[@]}"; do
  mapfile -t bl < <(python3 "$ROOT/scripts/crb-materialize.py" --baseline-paths "$slug")
  have_hash=$(python3 - "$MANIFEST" "$slug" <<'EOF'
import json, sys
rec = json.load(open(sys.argv[1])).get(sys.argv[2]) or {}
print("yes" if rec.get("baseline_sha256") and rec.get("baseline_index_sha256") else "no")
EOF
)
  if [ -f "${bl[0]}" ] && [ -f "${bl[1]}" ] && [ "$have_hash" = "yes" ]; then
    note "$slug: baseline present"
  else
    note "$slug: NO baseline — needs rebuild"
    NEED_REBUILD+=("$slug")
  fi
done

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  note "ANTHROPIC_API_KEY is set (API billing — per-cell cost will be authoritative)"
else
  note "ANTHROPIC_API_KEY is NOT set — step 2 will fail. Export it before running."
fi

# Smallest diff first when it is in scope: a 3-line change with 5 goldens
# exercises the whole chain for the least money. Chosen here so --dry-run and
# step 3 name the same cell.
FIRST="${SLUGS[0]}"
printf '%s\n' "${SLUGS[@]}" | grep -qx "keycloak-PR36880" && FIRST="keycloak-PR36880"

if [ -n "$DRY_RUN" ]; then
  step "--dry-run: plan only, nothing touched, \$0 spent"
  if [ "${#NEED_REBUILD[@]}" -gt 0 ]; then
    note "would rebuild ${#NEED_REBUILD[@]} clone(s): ${NEED_REBUILD[*]}"
    note "  (re-clones from the fork — expect a few hundred MB per clone)"
  else
    note "no rebuilds needed"
  fi
  note "would then run: PREFLIGHT_ONLY=1 bash $RUNNER"
  note "then, by hand: bash $RUNNER $FIRST   # one cell, then READ it"
  exit 0
fi

# ── 1. Baselines ─────────────────────────────────────────────────────────────
if [ -n "$SKIP_REBUILD" ]; then
  step "1. Baselines — skipped (--skip-rebuild)"
  [ "${#NEED_REBUILD[@]}" -eq 0 ] || {
    echo "   !! but ${#NEED_REBUILD[@]} clone(s) still have no baseline: ${NEED_REBUILD[*]}" >&2
    echo "   !! the sweep will skip them and exit 3. Drop --skip-rebuild." >&2; exit 1; }
elif [ "${#NEED_REBUILD[@]}" -eq 0 ]; then
  step "1. Baselines — all present, nothing to rebuild"
else
  step "1. Rebuilding ${#NEED_REBUILD[@]} clone(s) that have no baseline"
  note "Re-cloning, not repairing: in-place baselining was deleted for running"
  note "host git against a container-writable .git (decision 034 / rubric R1)."
  note "This re-downloads each repo. Ctrl-C is safe — it is idempotent."
  for slug in "${NEED_REBUILD[@]}"; do
    printf '\n   --- %s\n' "$slug"
    python3 "$ROOT/scripts/crb-materialize.py" --slug "$slug" --force
  done
fi

# ── 2. Images, egress allowlist, auth — proven by execution ──────────────────
step "2. Building images and PROVING the egress allowlist (one billed auth turn)"
note "If Claude Code does not honour HTTPS_PROXY, this is where you find out —"
note "for one turn, before any \$10-40 cell."
PREFLIGHT_ONLY=1 bash "$RUNNER" "${SLUGS[@]}"

# ── 3. What the human does next ──────────────────────────────────────────────
step "3. Ready. Nothing else is automated on purpose."
cat <<EOF
   Run ONE cell and read it before committing to a sweep:

       bash $RUNNER $FIRST

   Then read, in this order:
       runs/review-arms/crb-pipeline/$FIRST/review.md        <- did it review?
       runs/review-arms/crb-pipeline/$FIRST/artifacts/       <- did it write a rubric?
       runs/review-arms/crb-pipeline/run-meta.json           <- what did it cost?

   The rubric under artifacts/ is the thing the injector scores. No rubric means
   the arm falls back to freeform text, which is a different measurement — that
   is the single highest-risk assumption in the chain and one cell settles it.

   Only then sweep:
       bash $RUNNER                          # all materialized instances
       SWEEP_BUDGET=400 bash $RUNNER         # raise the ceiling deliberately

   One decision to make before an unattended run: a containment void currently
   HALTS the sweep (exit 7). Export CONTINUE_ON_VOID=1 if you would rather
   collect the remaining cells and adjudicate voided_cells at write-up time.
EOF
