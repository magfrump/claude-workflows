#!/usr/bin/env bash
# CRB direction-(1) arm: OUR review pipeline on THEIR benchmark PRs.
# ── RUN FROM THE HOST (WSL terminal), never from inside a Claude session ──
# (docker cannot run inside a session; same constraint as E5/E7/cc-isolated.)
#
# Per benchmark instance (materialized by scripts/crb-materialize.py) this runs,
# in a fresh node:22 container:
#
#   claude -p "/code-review main" --model $MODEL
#
# with a COPY of the claude-workflows payload (skills/, workflows/, guides/,
# patterns/, CLAUDE.md — taken from $PAYLOAD_REF via `git archive`) mounted as
# the container's ~/.claude. That is the decision-022 arrangement minus the
# baked-image boundary: the orchestrator, the critics, and the routing table are
# the ones under test, so this is *the pipeline*, not Claude Code's built-in
# /code-review (that arm is E5/E7, which deliberately run --bare so the payload
# does NOT load).
#
# DEFAULT ARM = E8. The evidence-discipline work (execution-mode fact-check +
# endorsement claims; 87% recall / 0 FPs on the canon,
# docs/working/e8-results-2026-08-18.md) was MERGED into main at d9234c9, and
# `git diff main feat/critic-evidence-discipline -- skills workflows CLAUDE.md`
# is empty as of 2026-08-18 — so main IS the E8 payload and is the default here.
# Pin PAYLOAD_REF=<sha> if the two ever diverge again; run-meta.json records the
# commit that actually ran either way.
#
# DEVIATIONS FROM E8-AS-RUN, to state in any results doc:
#   * E8 was orchestrated stage-by-stage by a human-driven session (k=2
#     fact-check, explicit critic list per instance). Here the skill's own
#     orchestration runs unattended in one headless invocation, so stage count,
#     critic selection and k are whatever skills/code-review/SKILL.md decides.
#   * hooks/ and scripts/ are NOT in the payload (they write to host paths and
#     log usage); E5/E7 also ran hookless.
#   * The benchmark PRs are third-party upstream code with no CLAUDE.md of their
#     own in most cases — the canon instances had one. Repo-local instructions
#     load as they would for any real user.
#
# Prereqs:
#   * docker
#   * ANTHROPIC_API_KEY exported (API billing => result.json's total_cost_usd is
#     authoritative billed spend, which is the point of using a key here)
#   * clones from: scripts/crb-materialize.py --per-repo 1   (or --all)
#
# Usage:
#   ANTHROPIC_API_KEY=sk-ant-... bash runs/review-arms/crb-pipeline/run-host.sh
#   ... run-host.sh discourse-graphite-PR4 grafana-PR79265     # subset
#   MODEL=opus BUDGET=10 ... run-host.sh                       # cheaper sweep
#   DRY_RUN=1 ... run-host.sh                                  # plan only, $0
set -euo pipefail
cd "$(dirname "$0")/../../.."
ROOT="$PWD"
CLONES="$ROOT/external/crb-eval"
MANIFEST="$ROOT/runs/review-arms/crb/instances.json"
OUT="$ROOT/runs/review-arms/crb-pipeline"
CC_VERSION="${CC_VERSION:-2.1.232}"   # pin for reproducibility; bump deliberately
PAYLOAD_REF="${PAYLOAD_REF:-main}"   # == feat/critic-evidence-discipline (merged, see header)
# E8's canon sweep ran the orchestrator on Fable 5. Keep that as the default so
# the benchmark row is comparable to the ledger row; MODEL=opus is ~1/2 the
# per-token price if the sweep needs to be cheaper.
MODEL="${MODEL:-claude-fable-5}"
BUDGET="${BUDGET:-25.00}"
# Sweep-level ceiling. BUDGET caps ONE instance; without an aggregate the loop
# will happily spend BUDGET x 50 unattended before run-meta.json first reports a
# total. Checked after every cell, so the worst overshoot is one instance.
SWEEP_BUDGET="${SWEEP_BUDGET:-75.00}"
DRY_RUN="${DRY_RUN:-}"

[ -f "$MANIFEST" ] || { echo "no $MANIFEST — run scripts/crb-materialize.py first" >&2; exit 1; }

if [ $# -gt 0 ]; then
  INSTANCES=("$@")
else
  mapfile -t INSTANCES < <(python3 -c '
import json, sys
print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$MANIFEST")
fi
[ "${#INSTANCES[@]}" -gt 0 ] || { echo "no instances in $MANIFEST" >&2; exit 1; }

echo "Arm:      pipeline @ $PAYLOAD_REF"
echo "Model:    $MODEL (budget \$$BUDGET/instance)"
echo "Instances (${#INSTANCES[@]}): ${INSTANCES[*]}"

# ── Payload: a copy of the branch's skills, never the live worktree ──────────
# `git archive` (not a bind mount of $ROOT) so a running review cannot edit the
# skills that are reviewing it, and so an unrelated local edit mid-sweep cannot
# change the arm's condition halfway through.
PAYLOAD_SRC=$(mktemp -d)
trap 'rm -rf "$PAYLOAD_SRC"' EXIT
git -C "$ROOT" archive "$PAYLOAD_REF" skills workflows guides patterns CLAUDE.md \
  | tar -x -C "$PAYLOAD_SRC"
PAYLOAD_SHA=$(git -C "$ROOT" rev-parse "$PAYLOAD_REF")
echo "Payload:  $PAYLOAD_REF @ ${PAYLOAD_SHA:0:8} ($(find "$PAYLOAD_SRC/skills" -name SKILL.md | wc -l) skills)"
[ -f "$PAYLOAD_SRC/skills/code-review/SKILL.md" ] || {
  echo "payload has no skills/code-review/SKILL.md — wrong ref?" >&2; exit 1; }

if [ -n "$DRY_RUN" ]; then
  echo "DRY_RUN=1 — payload built and verified, no container started, \$0 spent."
  exit 0
fi
[ -n "${ANTHROPIC_API_KEY:-}" ] || { echo "ANTHROPIC_API_KEY not set" >&2; exit 1; }

# Docker creates a fresh named volume root-owned, but the review container runs
# as uid 1000 (-u node) — chown it once, as root, before any -u node mount.
docker run --rm -v cc-review-npm-cache:/home/node/.npm node:22 \
  chown -R node:node /home/node/.npm

# ── Preflight: auth AND skill registration ──────────────────────────────────
# Two failure modes cost a whole sweep if unchecked:
#  (a) bad credential — the CLI exits 0 with result "Not logged in" (E7 note);
#  (b) payload mounted but skills not registered — the run then silently
#      measures Claude Code's built-in review, i.e. the E5 arm under a wrong
#      label. Decision 022 exists because exactly this happened in cc-isolated.
echo "=== preflight"
PF_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$PF_HOME/"; chmod -R u+w "$PF_HOME"
preflight=$(docker run --rm -u node -e ANTHROPIC_API_KEY \
  -v "$PF_HOME":/home/node/.claude \
  -v cc-review-npm-cache:/home/node/.npm node:22 \
  npx -y @anthropic-ai/claude-code@"$CC_VERSION" \
    -p "List the names of your available skills, comma separated. Nothing else." \
    --model "$MODEL" --output-format json 2>&1) || true
rm -rf "$PF_HOME"
printf '%s\n' "$preflight" | tail -1 > "$OUT/preflight.json" 2>/dev/null || true
python3 - "$OUT/preflight.json" <<'EOF' || { echo "PREFLIGHT FAILED — see $OUT/preflight.json" >&2; exit 1; }
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    sys.exit(f"  preflight output is not JSON ({e})")
r = (d.get("result") or "")
# Both spellings, deliberately: E7 learned the exact failure string the hard way
# (e7-fable-3x/run-host.sh:87-89 — exit 0, result "Not logged in · Please run
# /login", num_turns=0). "log in" does NOT match "logged in", so testing only the
# former leaves num_turns as the single point of failure for auth detection.
low = r.lower()
if d.get("num_turns", 0) < 1 or "log in" in low or "logged in" in low:
    sys.exit(f"  auth failed: {r[:200]!r}")
if "code-review" not in r:
    sys.exit("  payload skills NOT registered — the run would measure the "
             f"built-in reviewer, not the pipeline. Model said: {r[:300]!r}")
print("  preflight OK — auth good, code-review skill registered")
EOF

for id in "${INSTANCES[@]}"; do
  clone="$CLONES/$id"
  [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/crb-materialize.py --slug $id" >&2; continue; }
  dest="$OUT/$id"
  # "Complete" must mean SUCCEEDED, not "took turns". A cell that exhausted
  # --max-budget-usd or errored still records num_turns > 0, so a turns-only
  # predicate banks the expensive failures as done and locks them out of retry.
  if [ -s "$dest/result.json" ] && python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
ok = (d.get("num_turns", 0) > 0
      and not d.get("is_error")
      and d.get("subtype", "success") == "success")
sys.exit(0 if ok else 1)' "$dest/result.json" 2>/dev/null; then
    echo "=== $id — completed result exists, skipping (delete to re-run)"
    continue
  fi
  if [ -s "$dest/result.json" ]; then
    echo "=== $id — prior result was incomplete/errored, re-running"
  fi
  mkdir -p "$dest"
  echo "=== $id"
  # Fresh writable payload copy per instance: Claude Code writes settings.json,
  # projects/, todos/ into ~/.claude, and one instance's state must not leak
  # into the next (nor back into the payload source).
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
  # The clone is mounted read-write on purpose: the code-review skill writes its
  # rubric to docs/reviews/ in the repo under review. Artifacts are harvested
  # and the tree reset below, so re-runs start from the same state.
  #
  # Containment is re-asserted around every cell, not just at materialize time:
  # a read-write mount plus an agent with network access is exactly the shape
  # that could re-add a remote and fetch the merged upstream fix (the answer
  # key). Failing here costs one cell; failing silently would invalidate the arm.
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2; continue; }
  t0=$(date +%s)
  docker run --rm -u node -w /repo \
    -e ANTHROPIC_API_KEY \
    -v "$clone":/repo \
    -v "$INST_HOME":/home/node/.claude \
    -v cc-review-npm-cache:/home/node/.npm \
    node:22 \
    npx -y @anthropic-ai/claude-code@"$CC_VERSION" \
      -p "/code-review main" \
      --model "$MODEL" \
      --output-format stream-json --verbose \
      --dangerously-skip-permissions \
      --max-budget-usd "$BUDGET" \
    > "$dest/transcript.jsonl" 2> "$dest/stderr.log" || {
      echo "$id: claude exited non-zero — see $dest/stderr.log" >&2; }
  t1=$(date +%s)
  rm -rf "$INST_HOME"

  # Harvest: the final result event (cost/turns) + the review text, and any
  # files the pipeline wrote into the repo (rubric, critic reports).
  python3 - "$dest/transcript.jsonl" "$dest/result.json" "$dest/review.md" <<'EOF'
import json, sys
res = None
for line in open(sys.argv[1], errors="replace"):
    line = line.strip()
    if not line:
        continue
    try:
        d = json.loads(line)
    except Exception:
        continue
    if d.get("type") == "result":
        res = d
if res is None:
    print("  !! no result event — treat this instance as failed", file=sys.stderr)
    sys.exit(0)
json.dump(res, open(sys.argv[2], "w"))
open(sys.argv[3], "w").write(res.get("result") or "")
EOF
  mkdir -p "$dest/artifacts"
  # -z + cut: `git status --porcelain` pads the XY status to 3 chars, and NUL
  # termination is the only form that survives paths with spaces. `awk $2` also
  # dropped the second half of rename entries.
  (cd "$clone" && git status --porcelain=v1 -z --untracked-files=all) \
    | tr '\0' '\n' | cut -c4- | grep -E '\.(md|json)$' \
    | while read -r f; do
        [ -f "$clone/$f" ] || continue
        mkdir -p "$dest/artifacts/$(dirname "$f")"
        # --no-dereference: the agent could leave a symlink in the repo, and this
        # cp runs on the HOST, so following it would copy host files into a
        # tracked artifacts dir.
        cp --no-dereference "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true
      done
  # -x as well as -d: without it, gitignored files the review created survive
  # into the next run of this instance, and the harvest above misses them too.
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfdx 2>/dev/null || true
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" \
    || echo "$id: POST-RUN containment check FAILED — treat this cell's result as void" >&2

  python3 - "$dest/result.json" "$((t1-t0))" "$dest" <<'EOF'
import json, os, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    print("  no result.json"); sys.exit(0)
n = sum(len(files) for _r, _d, files in os.walk(sys.argv[3] + "/artifacts"))
print(f"  cost=${d.get('total_cost_usd','?')} duration={sys.argv[2]}s "
      f"turns={d.get('num_turns','?')} review_len={len(d.get('result') or '')} "
      f"artifacts={n}")
EOF

  # Aggregate spend gate. BUDGET caps one instance; this caps the sweep, so an
  # unattended --all run cannot quietly spend BUDGET x N. Re-summed from the
  # cells on disk each time, so it survives a resumed sweep.
  python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
import json, os, sys
out, cap = sys.argv[1], float(sys.argv[2])
total = 0.0
for name in os.listdir(out):
    rp = os.path.join(out, name, "result.json")
    if os.path.isfile(rp):
        try:
            total += json.load(open(rp)).get("total_cost_usd") or 0
        except Exception:
            pass
print(f"  sweep spend so far: ${total:.2f} / ${cap:.2f}")
sys.exit(1 if total >= cap else 0)
EOF
done

# Sweep-level provenance: which payload actually ran (review-canon section 3).
python3 - "$OUT/run-meta.json" "$PAYLOAD_REF" "$PAYLOAD_SHA" "$MODEL" "$CC_VERSION" "$OUT" <<'EOF'
import json, os, sys
meta_path, ref, sha, model, ccv, out = sys.argv[1:7]
cells = {}
for name in sorted(os.listdir(out)):
    rp = os.path.join(out, name, "result.json")
    if os.path.isfile(rp):
        try:
            d = json.load(open(rp))
        except Exception:
            continue
        cells[name] = {"cost_usd": d.get("total_cost_usd"), "turns": d.get("num_turns"),
                       "usage": d.get("usage")}
json.dump({"arm": "crb-pipeline", "payload_ref": ref, "payload_commit": sha,
           "model": model, "cc_version": ccv, "cells": cells,
           "total_cost_usd": round(sum(c["cost_usd"] or 0 for c in cells.values()), 4)},
          open(meta_path, "w"), indent=2)
print(f"\nrun-meta: {meta_path} — {len(cells)} cell(s), "
      f"total ${sum(c['cost_usd'] or 0 for c in cells.values()):.2f}")
EOF
echo "Next: scripts/crb-pipeline-to-benchmark.py  (inject as a benchmark tool, then judge)"
