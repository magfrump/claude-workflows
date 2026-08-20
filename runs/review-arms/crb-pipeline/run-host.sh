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
# TWO CONTROLS, added 2026-08-19, answering the review escalation:
#
#   EGRESS ALLOWLIST. The review container runs on an --internal docker network
#   whose only route out is a tinyproxy sidecar that CONNECTs to exactly one
#   host, api.anthropic.com (docker/Dockerfile.proxy + docker/egress-allowlist).
#   Before this, the container had unrestricted egress: the merged upstream PR —
#   the answer key — was one curl away, and a crafted file in a benchmark fork
#   could exfiltrate ANTHROPIC_API_KEY (2026-08-18 rubric R3, 2026-08-19 R4).
#   The allowlist makes retrieval PREVENTED rather than detected. The preflight
#   below proves it by execution before any paid cell; it does not assume it —
#   run `PREFLIGHT_ONLY=1` to do exactly that and stop.
#
#   WHAT IT DOES NOT CLOSE, stated here rather than only in decision 034 because
#   this is where spend is authorized: containers on $EGRESS_NET still reach
#   docker's embedded DNS resolver, which is a low-bandwidth exfiltration and
#   retrieval side channel. Leg 3 proves one internet host is unroutable; it
#   proves nothing about the docker host itself or sibling containers.
#
#   DISPOSABLE CLONES. Each cell wipes its clone and re-extracts a hash-pinned
#   baseline tar. No host process runs `git` against a `.git` the container had
#   write access to — the arrangement out of which the 2026-08-19 review
#   executed five host-side code-execution paths plus a `core.worktree` redirect
#   that deleted files in an unrelated host directory (R1/R2). Post-run
#   detection runs inside a throwaway container (scripts/crb-audit-clone.sh).
#
# Prereqs:
#   * docker
#   * ANTHROPIC_API_KEY exported (API billing => result.json's total_cost_usd is
#     authoritative billed spend, which is the point of using a key here)
#   * clones from: scripts/crb-materialize.py --per-repo 1   (or --all)
#
# EXIT CODES (the only thing an unattended overnight run communicates):
#   0  every requested cell either ran or was already complete
#   1  bad invocation / missing prerequisite (no manifest, no key, no payload)
#   2  SWEEP_BUDGET reached — resumable, raise it and re-run
#   3  no cell ran AND something was unusable — not a clean sweep
#   4  a check could not RUN (cell-status, harvest, or audit): refused to guess
#   5  the egress allowlist could not be proven — nothing was spent
#   6  the sweep finished but at least one cell is VOID
#   7  halted mid-sweep on a void (CONTINUE_ON_VOID=1 to override)
#
# Usage:
#   ANTHROPIC_API_KEY=sk-ant-... bash runs/review-arms/crb-pipeline/run-host.sh
#   ... run-host.sh discourse-graphite-PR4 grafana-PR79265     # subset
#   MODEL=opus BUDGET=10 ... run-host.sh                       # cheaper sweep
#   DRY_RUN=1 ... run-host.sh                                  # plan only, $0
#   PREFLIGHT_ONLY=1 ... run-host.sh    # build + prove the egress control, then stop
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
# Runs the images, the network, the proxy and all preflights — then stops,
# before any paid cell. The design's central claim is that the egress control
# "tests itself at $0 before the first paid cell"; until this existed there was
# no way to CASH that claim: DRY_RUN exits before the images are even built, and
# nothing else stopped after the preflights. A claim about a control needs a
# command that demonstrates it.
PREFLIGHT_ONLY="${PREFLIGHT_ONLY:-}"
DOCKER_DIR="$ROOT/runs/review-arms/crb-pipeline/docker"
REVIEW_IMAGE="crb-review:$CC_VERSION"
PROXY_IMAGE="crb-egress-proxy:$(git -C "$ROOT" rev-parse --short HEAD)"
EGRESS_NET="crb-inner"
# Pinned so tinyproxy.conf's Allow line can name the subnet exactly rather than
# proxying for whatever else is on this host's default bridge. Override only if
# it collides with something already on the machine.
EGRESS_SUBNET="${EGRESS_SUBNET:-172.31.250.0/24}"
PROXY_NAME="crb-egress-proxy"
PROXY_URL="http://$PROXY_NAME:3128"

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

# ── Images: built once, pinned, before the restricted network exists ────────
# The review image bakes the pinned CLI instead of `npx -y ...@VER` per cell.
# That is what lets the egress allowlist hold ONE host: installing at run time
# would force registry.npmjs.org (and its CDN) into the allowlist for every paid
# cell, and an allowlist with a package registry in it is not much of a control.
echo "=== images"
docker build --quiet --build-arg CC_VERSION="$CC_VERSION" \
  -f "$DOCKER_DIR/Dockerfile.review" -t "$REVIEW_IMAGE" "$DOCKER_DIR" >/dev/null
docker build --quiet -f "$DOCKER_DIR/Dockerfile.proxy" -t "$PROXY_IMAGE" \
  "$DOCKER_DIR" >/dev/null
echo "  review: $REVIEW_IMAGE (claude-code $CC_VERSION baked)"
echo "  proxy:  $PROXY_IMAGE ($(grep -c '^[^#]' "$DOCKER_DIR/egress-allowlist") allowed host(s))"

# ── Egress allowlist: an --internal network plus one proxy sidecar ──────────
# --internal means containers on it have NO route off this host. The proxy is
# attached to it AND to the default bridge, so it is the only path out, and it
# CONNECTs to api.anthropic.com alone.
NET_CREATE_CMD=""
setup_egress() {
  docker rm -f "$PROXY_NAME" >/dev/null 2>&1 || true
  docker network rm "$EGRESS_NET" >/dev/null 2>&1 || true
  # Captured so the preflight can assert the flag against the command that ran.
  NET_CREATE_CMD="docker network create --internal --subnet $EGRESS_SUBNET $EGRESS_NET"
  $NET_CREATE_CMD >/dev/null
  docker run -d --name "$PROXY_NAME" --network "$EGRESS_NET" \
    --restart no "$PROXY_IMAGE" >/dev/null
  # Second attachment AFTER creation: a container created on the internal
  # network and then joined to the bridge keeps both, and this ordering makes
  # the internal network its primary one.
  docker network connect bridge "$PROXY_NAME" >/dev/null
}
teardown_egress() {
  docker rm -f "$PROXY_NAME" >/dev/null 2>&1 || true
  docker network rm "$EGRESS_NET" >/dev/null 2>&1 || true
}
echo "=== egress allowlist"
setup_egress
# Replaces the payload-only trap: from here the sweep owns a network and a
# container, and a Ctrl-C that left them running would leave a proxy attached to
# this host's bridge indefinitely. Superseded once more below, when run-meta
# joins the handler — every version keeps every job.
trap 'teardown_egress; rm -rf "$PAYLOAD_SRC"' EXIT
echo "  network $EGRESS_NET ($EGRESS_SUBNET, --internal), proxy $PROXY_NAME up"

# Run a command in a throwaway container on the restricted network, exactly as a
# review cell sees it. Used by the preflight so the thing tested IS the thing
# that runs, not a re-description of it.
in_cell_net() {
  docker run --rm --network "$EGRESS_NET" \
    -e HTTP_PROXY="$PROXY_URL" -e HTTPS_PROXY="$PROXY_URL" \
    -e http_proxy="$PROXY_URL" -e https_proxy="$PROXY_URL" \
    --entrypoint bash "$REVIEW_IMAGE" -c "$1"
}

# ── Egress preflight: PROVE the allowlist, five ways ────────────────────────
# This is the control that makes the arm's numbers meaningful (an agent that can
# fetch the merged PR scores well for the wrong reason) and the one that keeps
# ANTHROPIC_API_KEY out of a hostile fork's reach. So it is tested by execution
# before any money is spent, and each leg is separate because they fail for
# different reasons — a single test passing for the wrong reason is how this
# harness has gone wrong before.
echo "=== egress preflight"
VERDICT="$ROOT/scripts/crb-egress-verdict.sh"
# Every leg's PASS/FAIL rule lives in that script, where test/crb-egress-verdict.bats
# pins it. This block only observes; it does not decide. Before the split, three
# separate mutations that neutered these legs left the whole suite green.
egress_leg() {  # <leg> <observed>
  # Capture THEN print. The obvious form — `bash "$VERDICT" ... | sed` followed by
  # a PIPESTATUS check — is broken under this file's `set -euo pipefail`: pipefail
  # makes the pipeline return the verdict's nonzero status, errexit kills the
  # shell at that line, and the PIPESTATUS check plus `exit 5` below it never run.
  # The sweep still failed closed, but with status 1 and no explanation, so every
  # doc promising "exits 5" was wrong. Found by execution on the 2026-08-19
  # iteration-2 fact-check — a fix-round mechanism error of exactly the class this
  # loop keeps producing, which is why the assignment is guarded with `|| rc=$?`
  # rather than relying on a pipeline's exit status at all.
  local out rc=0
  out=$(bash "$VERDICT" "$1" "$2") || rc=$?
  printf '%s\n' "$out" | sed 's/^/  /'
  [ "$rc" -eq 0 ] || { echo "  (refusing to spend — egress leg '$1' failed)" >&2; exit 5; }
}

# (0) the flag the whole story rests on — asserted against the command that was
# actually run, not against the author's intention.
egress_leg internal-net "$NET_CREATE_CMD"
# Each probe ends `|| true`, NOT `|| echo 000`. `-w "%{http_code}"` writes the
# code — "000" when there was no answer — whether or not curl exits 0, so the
# fallback echo appended a SECOND token to a stream that already had one: a
# connect-level refusal emitted "000000", which the verdict script correctly
# refused as "not an HTTP status code" and the sweep exited 5 in front of a
# working filter. Executed 2026-08-19 on the first real preflight, leg 2.
# `|| true` only keeps the nonzero curl from propagating; an observation that is
# empty (the container itself never ran) still fails closed in the verdict.
#
# (1) positive: the API is reachable THROUGH the proxy. Must be first — the
# refusal legs accept "000", which a dead proxy also produces.
egress_leg api-reachable "$(in_cell_net 'curl -s -o /dev/null -w "%{http_code}" --max-time 25 https://api.anthropic.com/v1/models || true')"
# (2) negative: a non-allowlisted host through the proxy must be refused.
# github.com specifically: it is where the answer key lives.
egress_leg filter-blocks "$(in_cell_net 'curl -s -o /dev/null -w "%{http_code}" --max-time 25 https://github.com/ || true')"
# (2b) the same over PLAIN HTTP. `ConnectPort 443` scopes the CONNECT method
# only, so a `GET http://…` is an ordinary forward-proxy request that ConnectPort
# never sees — and HTTP_PROXY/http_proxy are exported to every cell. The Filter
# is what refuses it, and until this leg existed nothing exercised that path.
egress_leg plain-http "$(in_cell_net 'curl -s -o /dev/null -w "%{http_code}" --max-time 25 http://github.com/ || true')"
# (3) negative: with the proxy env removed there must be no route at all.
egress_leg no-direct-route "$(docker run --rm --network "$EGRESS_NET" --entrypoint bash "$REVIEW_IMAGE" \
  -c 'curl -s -o /dev/null -w "%{http_code}" --max-time 20 https://github.com/ || true')"

# ── Preflight: auth AND skill registration, ON THE RESTRICTED NETWORK ───────
# Two failure modes cost a whole sweep if unchecked:
#  (a) bad credential — the CLI exits 0 with result "Not logged in" (E7 note);
#  (b) payload mounted but skills not registered — the run then silently
#      measures Claude Code's built-in review, i.e. the E5 arm under a wrong
#      label. Decision 022 exists because exactly this happened in cc-isolated.
# Running it inside $EGRESS_NET makes it do a third job: prove a real headless
# invocation still works through the proxy, before 50 of them are paid for.
echo "=== preflight"
PF_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$PF_HOME/"; chmod -R u+w "$PF_HOME"
preflight=$(docker run --rm -u node -e ANTHROPIC_API_KEY \
  --network "$EGRESS_NET" \
  -e HTTPS_PROXY="$PROXY_URL" -e HTTP_PROXY="$PROXY_URL" \
  -e https_proxy="$PROXY_URL" -e http_proxy="$PROXY_URL" \
  -v "$PF_HOME":/home/node/.claude \
  "$REVIEW_IMAGE" \
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
print("  preflight OK — auth good, code-review skill registered, egress constrained")
EOF

if [ -n "$PREFLIGHT_ONLY" ]; then
  echo
  echo "PREFLIGHT_ONLY=1 — images built, egress allowlist proven by execution,"
  echo "auth and skill registration confirmed. No cell ran; only the preflight's"
  echo "own auth turn was billed. Re-run without PREFLIGHT_ONLY to sweep."
  exit 0
fi

# ── Sweep-level provenance: which payload actually ran (review-canon §3) ─────
# A function, and trapped on EXIT, because it used to sit inline after the loop:
# the SWEEP_BUDGET gate below exits 2 from INSIDE the loop, so the halt that is
# the *designed* outcome of an --all run at the default ceiling (which sits
# under the setup doc's own $500-2000 estimate) wrote no run-meta.json at all —
# the provenance file was missing at exactly the moment a spend decision needed
# it. Ctrl-C and a docker failure had the same hole.
META_WRITTEN=""
write_run_meta() {
  if [ -n "$META_WRITTEN" ]; then return 0; fi
  META_WRITTEN=1
  python3 - "$OUT/run-meta.json" "$PAYLOAD_REF" "$PAYLOAD_SHA" "$MODEL" \
           "$CC_VERSION" "$OUT" "${INSTANCES[*]}" <<'EOF' || true
import json, os, sys
meta_path, ref, sha, model, ccv, out, requested = sys.argv[1:8]
# Carry forward what earlier invocations recorded, so requested_instances is the
# union over the whole sweep rather than the last batch. Read before the file is
# rewritten below.
prior_requested = []
if os.path.isfile(meta_path):
    try:
        prior_requested = json.load(open(meta_path)).get("requested_instances") or []
    except Exception:
        prior_requested = []
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
# requested_instances is what the sweep was ASKED to do, ACCUMULATED across
# invocations. A slug that never got far enough to write a result.json (missing
# clone, pre-run containment failure) appears only here, and it is what lets the
# leaderboard tell "reviewed 3 PRs" apart from "asked for 5, 2 disappeared".
#
# The union with the existing file is load-bearing, and three critics converged
# on its absence. This value used to be just the CURRENT invocation's argv while
# `cells` accumulated — so after a documented subset re-run (see the Usage block
# at the top of this file) or a resume following a SWEEP_BUDGET halt, the
# denominator shrank to the last batch and attrition reported nothing lost.
# Absence of the warning is indistinguishable from no attrition, which would
# silently void the bias caveat this whole mechanism exists to publish. Union
# fails safe: it can only ever over-report what the sweep was asked to do.
req = sorted(set(requested.split()) | set(prior_requested))
json.dump({"arm": "crb-pipeline", "payload_ref": ref, "payload_commit": sha,
           "model": model, "cc_version": ccv, "cells": cells,
           "requested_instances": req,
           # NOT "containment held" — only "no contamination was DETECTED".
           # The guard catches in-place git fetches; it does not catch non-git
           # retrieval (curl/WebFetch then commit), a nested clone, or a review
           # already written from the answer key before any check runs. Named
           # explicitly because a results doc reading `voided_cells: []` as an
           # all-clear is the most likely way this artifact gets over-read.
           "voided_cells_meaning": "cells where contamination was DETECTED; "
                                   "an empty list is not proof of cleanliness",
           "missing_cells": [s for s in req if s not in cells],
           "retried_cells": retried, "voided_cells": voided,
           "total_cost_usd": round(total, 4)},
          open(meta_path, "w"), indent=2)
print(f"\nrun-meta: {meta_path} — {len(cells)} cell(s), total ${total:.2f}"
      + (f", {len(retried)} retried" if retried else "")
      + (f", {len(voided)} VOIDED by containment" if voided else ""))
EOF
}
# All three jobs, one handler.
trap 'write_run_meta; teardown_egress; rm -rf "$PAYLOAD_SRC"' EXIT

# Aggregate spend gate. BUDGET caps one instance; this caps the sweep, so an
# unattended --all run cannot quietly spend BUDGET x N. Summed over ATTEMPTS
# across all cells, so it survives both a resumed sweep and re-run cells.
#
# A FUNCTION called at the TOP of the loop body, not a step at the bottom: at the
# bottom, every early `continue` (missing baseline, already-complete cell,
# MAX_ATTEMPTS, failed restore) jumped straight past it, so a resume that was
# already over the ceiling paid one more full $10-40 cell before noticing. The
# check is cheap and reading it before deciding to spend is the whole point.
sweep_spend_ok() {
  python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF'
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
}

for id in "${INSTANCES[@]}"; do
  sweep_spend_ok || { echo "SWEEP BUDGET EXCEEDED — stopping before this cell. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
  clone="$CLONES/$id"
  # The BASELINE, not the clone, is the precondition: --restore below builds the
  # clone from it, and a work clone left over from a previous cell is not
  # evidence that this cell can run. BOTH halves are required here, before the
  # cell is paid for — the index used to be first touched at harvest time, i.e.
  # after the $10-40 review.
  #
  # Paths come from crb-materialize.py rather than being spelled here: the
  # .baselines/ layout has one owner, and this file restating it was the
  # hand-copy failure crb_common.py's docstring exists to prevent.
  mapfile -t _bl < <(python3 "$ROOT/scripts/crb-materialize.py" --baseline-paths "$id")
  if [ ! -f "${_bl[0]:-/nonexistent}" ] || [ ! -f "${_bl[1]:-/nonexistent}" ]; then
    echo "$id: no baseline — rebuild the clone and its baseline with:" >&2
    echo "      python3 scripts/crb-materialize.py --slug $id --force" >&2
    echo "    (there is deliberately no mode that baselines an existing clone in" >&2
    echo "     place; that path ran host git against a container-writable .git)" >&2
    skipped_bad=$((skipped_bad+1)); continue
  fi
  dest="$OUT/$id"
  # A VOID IS TERMINAL FOR THE CELL. Without this, the void's own bookkeeping
  # (is_error=true) made crb-cell-status.py report "incomplete", the cell was
  # re-run under MAX_ATTEMPTS, and a clean second audit erased the record — so a
  # sweep that HAD observed contamination could finish with voided_cells: [] and
  # exit 0. Re-running is also the wrong instinct: the clone is contaminated
  # evidence, not a flaky test.
  if [ -f "$dest/CONTAINMENT_FAILED" ]; then
    echo "=== $id — previously VOIDED by the containment audit; not re-running." >&2
    echo "    Adjudicate it, then delete $dest to retry deliberately." >&2
    skipped_bad=$((skipped_bad+1)); continue
  fi
  # "Complete" must mean PRODUCED A REVIEW. The rules, and the artifacts they
  # were measured against, live in scripts/crb-cell-status.py — extracted from
  # here so they have fixtures (test/crb-cell-status.bats). It prints its reason
  # either way; capture it so the re-run message says WHY.
  cell_status=""
  if [ -s "$dest/result.json" ]; then
    cell_status=$(python3 "$ROOT/scripts/crb-cell-status.py" "$dest/result.json" 2>&1)
    case $? in
      0) echo "=== $id — completed result exists, skipping (delete to re-run)"
         skipped_ok=$((skipped_ok+1)); continue ;;
      1) : ;;   # incomplete — fall through to the retry logic below
      # Exit 2 is a usage error, NOT a verdict. Treating it as "incomplete"
      # would re-pay $10-40 per cell for what is actually a broken invocation,
      # silently, for the whole sweep. Stop instead.
      *) echo "$id: crb-cell-status.py invocation error — $cell_status" >&2
         exit 4 ;;
    esac
  fi
  # MAX_ATTEMPTS is checked OUTSIDE the result.json test, deliberately. Nested
  # inside it (three review rounds running), it could not see the failure that
  # matters most: a container that dies before emitting a `result` event writes
  # NO result.json, so the guard never ran, the cell re-ran on every resume
  # forever, and each attempt ledgered cost_usd 0 — invisible to SWEEP_BUDGET
  # too. Every new precondition in this file (the sidecar, the --internal
  # network, the baked image) fails in exactly that shape, so the hole got more
  # reachable, not less. attempts.jsonl is the ledger either way, so it is the
  # right thing to gate on.
  #
  # `grep -c` prints 0 AND exits 1 on no match, so `|| echo 0` would append a
  # SECOND zero — `attempts` becomes "0\n0", the -ge test errors, and bash
  # abandons the rest of this cell's loop body without running it.
  attempts=0
  if [ -f "$dest/attempts.jsonl" ]; then
    attempts=$(grep -c . "$dest/attempts.jsonl" || true)
    [ -n "$attempts" ] || attempts=0
  fi
  if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
    echo "=== $id — $attempts attempt(s) already made, at MAX_ATTEMPTS — skipping (delete $dest to reset)" >&2
    skipped_bad=$((skipped_bad+1)); continue
  fi
  if [ -s "$dest/result.json" ]; then
    echo "=== $id — prior result was incomplete/errored, re-running (attempt $((attempts+1))): $cell_status"
  elif [ "$attempts" -gt 0 ]; then
    echo "=== $id — $attempts prior attempt(s) produced no result event, re-running (attempt $((attempts+1)))"
  fi
  mkdir -p "$dest"
  # A void marker from an EARLIER sweep must not make this sweep exit 6: nothing
  # else ever deletes it, so the status would be sticky forever once any cell had
  # ever voided. This cell is about to be re-decided, so its old verdict goes.
  rm -f "$dest/CONTAINMENT_FAILED"
  echo "=== $id"
  # Every cell starts from a WIPE, not a repair: the work clone is deleted and
  # re-extracted from a hash-pinned baseline built before any container existed.
  # An agent commit, a staged edit, a created branch, a deleted `main`, a nested
  # clone of the answer key — none of them can reach this cell, and none of them
  # has to be told apart from contamination by a heuristic. Host `git` never
  # reads the outgoing `.git` (2026-08-19 rubric R1/R2).
  # Run BEFORE the payload copy below, so a skipped cell leaks no temp dir.
  python3 "$ROOT/scripts/crb-materialize.py" --restore "$id" || {
    echo "$id: RESTORE failed — skipping cell (nothing was paid for)" >&2
    echo "    A baseline hash mismatch or a clone materialized before the" >&2
    echo "    baseline pin both land here. Rebuild it:" >&2
    echo "      python3 scripts/crb-materialize.py --slug $id --force" >&2
    skipped_bad=$((skipped_bad+1)); continue; }
  # The proxy is `--restart no` and its liveness was proven once, at t=0. If it
  # died since, every remaining cell would burn its budget failing to reach the
  # API — and (until the retry fix above) re-run forever at cost_usd 0. One $0
  # probe per cell is the cheapest possible insurance against that.
  if ! in_cell_net 'curl -s -o /dev/null --max-time 15 https://api.anthropic.com/v1/models' >/dev/null 2>&1; then
    echo "$id: egress proxy is not answering — the sweep cannot reach the API." >&2
    echo "    Stopping rather than burning budget on cells that will all fail." >&2
    exit 5
  fi

  # Fresh writable payload copy per instance: Claude Code writes settings.json,
  # projects/, todos/ into ~/.claude, and one instance's state must not leak
  # into the next (nor back into the payload source).
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
  # The clone is mounted read-write on purpose: the code-review skill writes its
  # rubric to docs/reviews/ in the repo under review. Nothing resets it
  # afterwards — the NEXT cell's `--restore` above wipes and re-extracts it, so
  # re-runs start from the same state. (This comment used to say "the tree reset
  # below", which survived the deletion of the reset it referred to.)
  #
  t0=$(date +%s)
  # --network $EGRESS_NET: no route off this host except the proxy, which
  # CONNECTs to api.anthropic.com and nothing else. The key is still passed in —
  # the cell has to authenticate — but there is now nowhere else to send it, and
  # the merged upstream PR is not reachable. Proven by the egress preflight.
  docker run --rm -u node -w /repo \
    -e ANTHROPIC_API_KEY \
    --network "$EGRESS_NET" \
    -e HTTPS_PROXY="$PROXY_URL" -e HTTP_PROXY="$PROXY_URL" \
    -e https_proxy="$PROXY_URL" -e http_proxy="$PROXY_URL" \
    -v "$clone":/repo \
    -v "$INST_HOME":/home/node/.claude \
    "$REVIEW_IMAGE" \
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
  # `|| true` is load-bearing here and was missing: this is the only unguarded
  # statement between the PAID container and the attempt ledger, so under
  # `set -euo pipefail` a write failure on result.json/review.md killed the sweep
  # after the money was spent and before it was recorded. Found by execution on
  # the 2026-08-19 terminal fact-check.
  python3 - "$dest/transcript.jsonl" "$dest/result.json" "$dest/review.md" <<'EOF' || true
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
  # Ledger this attempt's spend IMMEDIATELY, before the audit and before any
  # path that can leave the loop. result.json is overwritten by a retry, so
  # summing result.json alone silently forgets every earlier paid attempt — and
  # the audit's `exit 4` abort would additionally have dropped THIS attempt's
  # spend on the floor, under-counting exactly the cell that just cost money.
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

  # Artifacts: diff the tree against the baseline index instead of asking git.
  # The old harvest ran `git -C "$clone" status` ON THE HOST as the FIRST
  # command after the container exited — which is exactly where core.fsmonitor
  # fires (2026-08-19 R1). It was also incomplete: --untracked-files=all still
  # honours .gitignore, so a rubric written under a path the upstream repo
  # ignores never appeared. Nothing below reads .git.
  python3 "$ROOT/scripts/crb-harvest-artifacts.py" \
    "$clone" "${_bl[1]}" "$dest/artifacts" || {
      echo "$id: HARVEST invocation failed — see above" >&2; exit 4; }

  # Post-run audit, INSIDE a throwaway container: read the outgoing clone for
  # evidence of contamination, where a hostile .git can reach nothing but a
  # container that is about to be deleted. --network none, no API key.
  #
  # This is EVIDENCE, not the control. The control is the egress allowlist; this
  # records whether anything got past it. A void still matters — a contaminated
  # cell scores plausibly HIGH, so banking it is the worst outcome — but a quiet
  # pass is not proof of cleanliness.
  head_sha=$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))[sys.argv[2]]["head"])' "$MANIFEST" "$id")
  # The audit publishes THREE states and they are not interchangeable: 0 clean,
  # 1 VOID (contamination detected), anything else "could not check". A bare
  # `if ! docker run` collapsed the last two into VOID, so an audit that never
  # ran — a missing binary in the image, a docker daemon hiccup (125/126/127),
  # or a `.git` the agent moved (exit 2) — was published in run-meta.json's
  # voided_cells as DETECTED CONTAMINATION about a $10-40 cell. This file already
  # gets that distinction right twice (crb-cell-status.py above, the harvest
  # just now), both times by aborting the sweep rather than guessing.
  audit_rc=0
  docker run --rm --network none -u node \
        -v "$clone":/repo \
        -v "$ROOT/scripts/crb-audit-clone.sh":/audit.sh:ro \
        --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha" || audit_rc=$?
  if [ "$audit_rc" -gt 1 ]; then
    echo "$id: containment audit could not run (exit $audit_rc) — NOT a void." >&2
    echo "    Refusing to guess: an unchecked cell must not be banked as clean," >&2
    echo "    and must not be published as contaminated either. Stopping." >&2
    exit 4
  fi
  if [ "$audit_rc" -eq 1 ]; then
    echo "$id: POST-RUN containment audit FAILED — voiding this cell" >&2
    : > "$dest/CONTAINMENT_FAILED"
    # And STOP, unless told otherwise. A void means the containment control was
    # observed FAILING on real work; continuing pays $10-40 a cell into a sweep
    # whose central claim is already in doubt. Note the asymmetry this fixes: the
    # WEAKER signal ("could not check", above) already halted, while the stronger
    # one did not. CONTINUE_ON_VOID=1 is the deliberate override for someone who
    # wants the remaining cells anyway and will read voided_cells before quoting
    # any number.

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
    if [ -z "${CONTINUE_ON_VOID:-}" ]; then
      echo "Halting the sweep: containment was observed failing on a paid cell." >&2
      echo "Set CONTINUE_ON_VOID=1 to keep going and adjudicate voided_cells later." >&2
      exit 7
    fi
    echo "  CONTINUE_ON_VOID=1 — continuing despite the void." >&2
  fi
  # The clone is left as the container wrote it; the NEXT cell's --restore wipes
  # it. Nothing on the host touches it in between, and a voided cell no longer
  # leaves a permanently dead clone (2026-08-19 A8).

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


done

write_run_meta
echo "Cells: $ran ran, $skipped_ok already complete, $skipped_bad skipped as unusable"
# Exit non-zero when nothing ran AND something was unusable. Otherwise a
# persistent containment break, or every clone missing, skips all 50 cells and
# still exits 0 — which reads to a caller (or a human skimming) as a clean sweep
# that simply had nothing to do.
if [ "$ran" -eq 0 ] && [ "$skipped_bad" -gt 0 ]; then
  echo "NO CELL RAN and $skipped_bad instance(s) were unusable — not a clean sweep." >&2
  exit 3
fi
# A void is a paid cell whose result cannot be used. Exiting 0 on a sweep that
# voided anything reads as success to a caller and to anyone skimming, and the
# cells that void are exactly the ones a results doc must account for.
voided=$(python3 - "$OUT" <<'EOF' || echo 0
import os, sys
out = sys.argv[1]
print(sum(1 for n in os.listdir(out)
          if os.path.isfile(os.path.join(out, n, "CONTAINMENT_FAILED"))))
EOF
)
if [ "${voided:-0}" -gt 0 ]; then
  echo "$voided cell(s) VOIDED by the containment audit — see run-meta.json's voided_cells." >&2
  echo "Those PRs leave the judged denominator; read the leaderboard's SUBSET ATTRITION line." >&2
  exit 6
fi
echo "Next: scripts/crb-pipeline-to-benchmark.py  (inject as a benchmark tool, then judge)"
