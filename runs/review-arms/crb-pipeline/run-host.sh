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
# total. Checked after every cell, so the worst overshoot is SWEEP_BUDGET+BUDGET.
# Default sits ABOVE the setup doc's own $50-200 pilot estimate, deliberately: a
# ceiling that halts a legitimate pilot partway is a worse failure than one that
# needs raising for a full sweep. Raise it explicitly for --all.
SWEEP_BUDGET="${SWEEP_BUDGET:-250.00}"
# Retries overwrite result.json, so spend must be ledgered per ATTEMPT or the
# gate under-counts every re-run. MAX_ATTEMPTS stops a deterministically-failing
# cell from being re-paid indefinitely.
MAX_ATTEMPTS="${MAX_ATTEMPTS:-2}"
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
# Counters so the sweep can distinguish "nothing to do" from "nothing worked".
ran=0; skipped_ok=0; skipped_bad=0

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
  [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/crb-materialize.py --slug $id" >&2
    skipped_bad=$((skipped_bad+1)); continue; }
  dest="$OUT/$id"
  # "Complete" must mean PRODUCED A REVIEW. Measured against the 32 result.json
  # files already in this repo, no single field decides it:
  #   * is_error/subtype catch the real budget exhaustion
  #     (e7-fable-3x/mfc-hygiene/rep1: subtype=error_max_budget_usd, $15.24) —
  #     a turns-only predicate banked exactly that and locked it out of retry;
  #   * but 8 e5-cc-builtin cells are genuine successes with num_turns == 0 and
  #     3-7 KB of real review text, so requiring turns > 0 re-pays for work
  #     already done;
  #   * and 2 e7 cells report subtype=success, is_error=false, num_turns=0 with
  #     a 51-56 char body that is actually "You've hit your weekly limit".
  # So: trust subtype/is_error, then look at what came out.
  if [ -s "$dest/result.json" ] && python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
r = (d.get("result") or "").strip()
low = r.lower()
# Signatures of a run that returned cleanly without reviewing anything.
NON_REVIEW = ("log in", "logged in", "hit your weekly limit",
              "hit your session limit", "limit · resets", "limit - resets")
ok = (not d.get("is_error")
      and d.get("subtype", "success") == "success"
      and len(r) >= 200                      # real reviews run to KBs; these run to ~50 chars
      and not any(s in low for s in NON_REVIEW))
sys.exit(0 if ok else 1)' "$dest/result.json" 2>/dev/null; then
    echo "=== $id — completed result exists, skipping (delete to re-run)"
    skipped_ok=$((skipped_ok+1)); continue
  fi
  if [ -s "$dest/result.json" ]; then
    # `grep -c` prints 0 AND exits 1 on no match, so `|| echo 0` would append a
    # SECOND zero — `attempts` becomes "0\n0", the -ge test errors, and bash
    # abandons the rest of this cell's loop body without running it.
    attempts=0
    if [ -f "$dest/attempts.jsonl" ]; then
      attempts=$(grep -c . "$dest/attempts.jsonl" || true)
      [ -n "$attempts" ] || attempts=0
    fi
    if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
      echo "=== $id — $attempts failed attempt(s), at MAX_ATTEMPTS — skipping (delete $dest to reset)" >&2
      skipped_bad=$((skipped_bad+1)); continue
    fi
    echo "=== $id — prior result was incomplete/errored, re-running (attempt $((attempts+1)))"
  fi
  mkdir -p "$dest"
  echo "=== $id"
  # Containment is re-asserted around every cell, not just at materialize time:
  # a read-write mount plus an agent with network access is exactly the shape
  # that could re-add a remote and fetch the merged upstream fix (the answer
  # key). Failing here costs one cell; failing silently would invalidate the arm.
  # Checked BEFORE the payload copy below, so a skipped cell leaks no temp dir.
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2
    skipped_bad=$((skipped_bad+1)); continue; }
  # Fresh writable payload copy per instance: Claude Code writes settings.json,
  # projects/, todos/ into ~/.claude, and one instance's state must not leak
  # into the next (nor back into the payload source).
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
  # The clone is mounted read-write on purpose: the code-review skill writes its
  # rubric to docs/reviews/ in the repo under review. Artifacts are harvested
  # and the tree reset below, so re-runs start from the same state.
  #
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
  ran=$((ran+1))
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
  # Stay NUL-delimited end to end. `read -r -d ''` is the only form that
  # survives a newline in a filename — piping through `tr '\0' '\n'` would throw
  # away exactly the property `-z` buys, and a fixed `cut -c4-` then eats three
  # characters of any record that arrives without a status prefix.
  # Porcelain v1 -z emits "XY path" per record, plus a SECOND record holding the
  # original path for a rename/copy; consume and drop that one.
  # The path comes from a repository we do not own and this loop runs on the
  # HOST, so it is treated as untrusted: absolute or `..`-bearing paths are
  # refused rather than normalised, since `$dest/artifacts/$f` would otherwise
  # write outside the artifacts dir.
  while IFS= read -r -d '' entry; do
    [ ${#entry} -gt 3 ] || continue
    st=${entry:0:2}
    f=${entry:3}
    case "$st" in
      R*|C*) read -r -d '' _orig || true ;;
    esac
    case "$f" in
      *.md|*.json) ;;
      *) continue ;;
    esac
    case "$f" in
      /*|*..*) echo "  !! $id: refusing suspicious artifact path: $f" >&2; continue ;;
    esac
    [ -f "$clone/$f" ] || continue
    mkdir -p "$dest/artifacts/$(dirname "$f")"
    # --no-dereference so a symlink the agent left behind is copied as a link
    # rather than followed into host files. It only covers the final component,
    # which is why the traversal guard above is the load-bearing check.
    cp --no-dereference "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true
  done < <(git -C "$clone" status --porcelain=v1 -z --untracked-files=all)
  # -x as well as -d: without it, gitignored files the review created survive
  # into the next run of this instance, and the harvest above misses them too.
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfdx 2>/dev/null || true
  # A post-run failure must VOID the cell, not just print. A contaminated clone
  # produces a plausibly HIGH score, so a warning that leaves result.json marked
  # successful is the worst outcome: the resume predicate would bank it and the
  # injector would ship it. Rewrite the result so both refuse it.
  if ! python3 "$ROOT/scripts/crb-materialize.py" --verify "$id"; then
    echo "$id: POST-RUN containment check FAILED — voiding this cell" >&2
    : > "$dest/CONTAINMENT_FAILED"
    python3 - "$dest/result.json" <<'EOF' || true
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    d = {}
d["is_error"] = True
d["subtype"] = "containment_failed"
json.dump(d, open(sys.argv[1], "w"))
EOF
  fi

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

  # Ledger this attempt's spend BEFORE the gate. result.json is overwritten by a
  # retry, so summing result.json alone silently forgets every earlier paid
  # attempt — the gate would then under-count exactly the cells costing most.
  python3 - "$dest/result.json" "$dest/attempts.jsonl" <<'EOF' || true
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    d = {}
rec = {"cost_usd": d.get("total_cost_usd") or 0, "turns": d.get("num_turns"),
       "is_error": bool(d.get("is_error")), "subtype": d.get("subtype")}
with open(sys.argv[2], "a") as fh:
    fh.write(json.dumps(rec) + "\n")
EOF

  # Aggregate spend gate. BUDGET caps one instance; this caps the sweep, so an
  # unattended --all run cannot quietly spend BUDGET x N. Summed over ATTEMPTS
  # across all cells, so it survives both a resumed sweep and re-run cells.
  python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
import json, os, sys
out, cap = sys.argv[1], float(sys.argv[2])
total = 0.0
for name in sorted(os.listdir(out)):
    ledger = os.path.join(out, name, "attempts.jsonl")
    if os.path.isfile(ledger):
        for line in open(ledger):
            line = line.strip()
            if not line:
                continue
            try:
                total += json.loads(line).get("cost_usd") or 0
            except Exception:
                pass
        continue
    # Cell from a pre-ledger run: fall back to its final result.
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
    if not os.path.isfile(rp):
        continue
    try:
        d = json.load(open(rp))
    except Exception:
        continue
    # Billed spend is the sum over ATTEMPTS, not the final result: a retried
    # cell overwrites result.json, so reporting that alone under-states what was
    # actually paid — and this file is the provenance a results doc quotes.
    attempts, attempt_cost = [], 0.0
    lp = os.path.join(out, name, "attempts.jsonl")
    if os.path.isfile(lp):
        for line in open(lp):
            line = line.strip()
            if not line:
                continue
            try:
                a = json.loads(line)
            except Exception:
                continue
            attempts.append(a)
            attempt_cost += a.get("cost_usd") or 0
    final = d.get("total_cost_usd") or 0
    cells[name] = {"cost_usd": attempt_cost if attempts else final,
                   "final_cost_usd": final,
                   "attempts": len(attempts) or 1,
                   "voided_containment": os.path.isfile(
                       os.path.join(out, name, "CONTAINMENT_FAILED")),
                   "turns": d.get("num_turns"), "usage": d.get("usage")}
total = sum(c["cost_usd"] or 0 for c in cells.values())
retried = [n for n, c in cells.items() if c["attempts"] > 1]
voided = [n for n, c in cells.items() if c["voided_containment"]]
json.dump({"arm": "crb-pipeline", "payload_ref": ref, "payload_commit": sha,
           "model": model, "cc_version": ccv, "cells": cells,
           "retried_cells": retried, "voided_cells": voided,
           "total_cost_usd": round(total, 4)},
          open(meta_path, "w"), indent=2)
print(f"\nrun-meta: {meta_path} — {len(cells)} cell(s), total ${total:.2f}"
      + (f", {len(retried)} retried" if retried else "")
      + (f", {len(voided)} VOIDED by containment" if voided else ""))
EOF
echo "Cells: $ran ran, $skipped_ok already complete, $skipped_bad skipped as unusable"
# Exit non-zero when nothing ran AND something was unusable. Otherwise a
# persistent containment break, or every clone missing, skips all 50 cells and
# still exits 0 — which reads to a caller (or a human skimming) as a clean sweep
# that simply had nothing to do.
if [ "$ran" -eq 0 ] && [ "$skipped_bad" -gt 0 ]; then
  echo "NO CELL RAN and $skipped_bad instance(s) were unusable — not a clean sweep." >&2
  exit 3
fi
echo "Next: scripts/crb-pipeline-to-benchmark.py  (inject as a benchmark tool, then judge)"
