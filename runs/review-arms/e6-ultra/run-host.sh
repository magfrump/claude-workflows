#!/usr/bin/env bash
# E6 arm: /code-review ultra (ultrareview) — cloud multi-agent review.
# ── RUN FROM THE HOST, and mind the cost ──
#
# Ultrareview is billed via usage credits (reported ~$5–25/run; Pro/Max
# accounts get 3 free runs). A full 8-instance sweep could cost $40–200,
# so THE DEFAULT HERE IS A 3-INSTANCE SUBSET chosen to discriminate:
#   mfc-csp     — has the gold cross-file defect (csp-R1) headless arms miss
#   mfc-deploy  — cross-file reasoning stratum (E4 got 1/2)
#   mfc-secdeps — fully headless-solvable (E4 3/3): measures the floor
# Pass instance names to override, or "all" for all eight.
#
# Prereqs: claude CLI logged in to claude.ai (subscription OAuth — ultra does
# NOT run on an API key); clones built by scripts/prep-cc-review-clones.sh.
# Cost tracking: per-run billed cost has no API surface — after the sweep,
# record each run's cost in costs.md from https://claude.ai/analytics or your
# bill; the tracking URL printed per run is saved to stderr.log.
#
# Usage:  bash runs/review-arms/e6-ultra/run-host.sh [instance...|all]
set -euo pipefail
cd "$(dirname "$0")/../../.."
ROOT="$PWD"
CLONES="$ROOT/external/cc-review-eval"
OUT="$ROOT/runs/review-arms/e6-ultra"
DEFAULT=(mfc-csp mfc-deploy mfc-secdeps)
ALL=(mfc-csp mfc-lean mfc-hygiene mfc-secdeps mfc-deploy mfc-fscompat mfc-corpus mfc-postfix)
if [ $# -eq 0 ]; then INSTANCES=("${DEFAULT[@]}");
elif [ "$1" = "all" ]; then INSTANCES=("${ALL[@]}");
else INSTANCES=("$@"); fi

command -v claude >/dev/null || { echo "claude CLI not on PATH" >&2; exit 1; }

for id in "${INSTANCES[@]}"; do
  clone="$CLONES/$id"
  [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/prep-cc-review-clones.sh" >&2; exit 1; }
  mkdir -p "$OUT/$id"
  echo "=== E6: $id (blocks until the cloud review finishes; typically 5-10 min)"
  ( cd "$clone" && claude ultrareview main --json --timeout 30 ) \
    > "$OUT/$id/bugs.json" 2> "$OUT/$id/stderr.log" || {
      echo "$id: ultrareview exited non-zero — see $OUT/$id/stderr.log" >&2; continue; }
  echo "  findings: $(python3 -c "import json,sys;d=json.load(open('$OUT/$id/bugs.json'));print(len(d) if isinstance(d,list) else len(d.get('bugs',d.get('findings',[]))))" 2>/dev/null || echo '? (inspect bugs.json)')"
  grep -m1 -oE 'https://[^ ]*' "$OUT/$id/stderr.log" 2>/dev/null | head -1 || true
done

ledger="$OUT/costs.md"
[ -f "$ledger" ] || printf '# E6 ultrareview cost ledger (fill billed cost from claude.ai analytics / bill)\n\n| instance | date | billed cost | free-run? |\n|---|---|---|---|\n' > "$ledger"
for id in "${INSTANCES[@]}"; do printf '| %s | %s | $ | |\n' "$id" "$(date +%F)" >> "$ledger"; done
echo "E6 done. Findings in $OUT/<instance>/bugs.json; FILL IN $ledger with billed costs."
echo "Next: hand back to the workspace session for adjudication against the ledger."
