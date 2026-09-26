#!/usr/bin/env bash
# Performance probes for 272bc83's transcript.jq (performance review, iteration 5).
# Usage: bash docs/reviews/execution-logs/perf-9c73ae4-transcript-jq-probes.sh <workdir>
# Writes synthetic stream-json transcripts under <workdir> and prints wall time
# (ms, best of 3) and peak child RSS (KB) for each program. No claude, no network.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
LIB="$REPO/test/skills"
WORK="${1:?workdir}"
mkdir -p "$WORK"

# measure <label> <cmd...>: best-of-3 wall ms and max RSS of the child, stdout discarded.
measure() {
  local label="$1"
  shift
  python3 - "$label" "$@" <<'PY'
import resource, subprocess, sys, time
label, cmd = sys.argv[1], sys.argv[2:]
best = None
for _ in range(3):
    t0 = time.perf_counter()
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    ms = (time.perf_counter() - t0) * 1000
    best = ms if best is None else min(best, ms)
rss = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
print(f"{label}\t{best:.0f} ms\tmaxrss={rss} KB")
PY
}

# make_transcript <file> <n>: init, n denied Bash calls (1000-byte text blocks and
# tool_results beside them), then a result event denying all n.
make_transcript() {
  python3 - "$1" "$2" <<'PY'
import json, sys
path, n = sys.argv[1], int(sys.argv[2])
pad = "x" * 1000
with open(path, "w") as f:
    f.write(json.dumps({"type": "system", "subtype": "init", "claude_code_version": "9.9.9", "tools": ["Bash", "Read"]}) + "\n")
    for i in range(n):
        f.write(json.dumps({"type": "assistant", "message": {"content": [
            {"type": "text", "text": pad},
            {"type": "tool_use", "id": f"toolu_{i}", "name": "Bash", "input": {"command": f"echo {i}"}}]}}) + "\n")
        f.write(json.dumps({"type": "user", "message": {"content": [
            {"type": "tool_result", "tool_use_id": f"toolu_{i}", "content": "denied", "is_error": True}]}}) + "\n")
    f.write(json.dumps({"type": "result", "subtype": "success", "is_error": False, "result": "# Report",
                        "permission_denials": [{"tool_name": "Bash", "tool_use_id": f"toolu_{i}"} for i in range(n)]}) + "\n")
PY
}

# The generator's verdict program, verbatim from generate-reports.bash:286-291.
GEN_FILTER='import "transcript" as t;
      t::events | [ (t::problems | length), (t::problems | first // ""),
        (t::init | if . == null then "none" elif ((.tools // []) | type == "array" and index(["Bash"]) != null) then "bash" else "nobash" end),
        (t::init | .claude_code_version // "unknown"),
        (if (t::problems | length) == 0 then (t::deny_record_counts | "\(.undenied) \(.unseen) \(.orphans) \(.foreign)") else "" end)
      ] | join("\u001f")'
# Same output, problems and init bound once.
GEN_ONCE='import "transcript" as t;
      t::events | (t::problems) as $p | (t::init) as $i | [ ($p | length), ($p | first // ""),
        ($i | if . == null then "none" elif ((.tools // []) | type == "array" and index(["Bash"]) != null) then "bash" else "nobash" end),
        ($i | .claude_code_version // "unknown"),
        (if ($p | length) == 0 then (t::deny_record_counts | "\(.undenied) \(.unseen) \(.orphans) \(.foreign)") else "" end)
      ] | join("\u001f")'

echo "jq: $(jq --version); nproc: $(nproc); loadavg: $(cut -d' ' -f1-3 /proc/loadavg)"
for n in 10 2000 10000 40000; do
  f="$WORK/t$n.jsonl"
  make_transcript "$f" "$n"
  echo "== n=$n bash calls, $(wc -c < "$f") bytes, $(wc -l < "$f") lines"
  echo "verdict(as committed): $(jq -rR -n -L "$LIB" "$GEN_FILTER" "$f" | tr '\037' '|')"
  echo "verdict(bound once):   $(jq -rR -n -L "$LIB" "$GEN_ONCE" "$f" | tr '\037' '|')"
  measure "gen verdict as committed" jq -rR -n -L "$LIB" "$GEN_FILTER" "$f"
  measure "gen verdict bound once" jq -rR -n -L "$LIB" "$GEN_ONCE" "$f"
  measure "events only (try fromjson catch)" jq -rR -n -L "$LIB" 'import "transcript" as t; t::events | length' "$f"
  measure "old slurp ([inputs|fromjson?])" jq -rR -n '[inputs | fromjson?] | length' "$f"
  measure "problems once" jq -rR -n -L "$LIB" 'import "transcript" as t; t::events | t::problems | length' "$f"
  measure "deny_record_counts once" jq -rR -n -L "$LIB" 'import "transcript" as t; t::events | t::deny_record_counts' "$f"
  measure "gen report extraction (:252)" jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$f"
  # eval-helpers: one no_tool_called check = transcript_checked + inputs + known (3 jq).
  measure "eval transcript_checked (:396)" jq -rR -n -L "$LIB" 'import "transcript" as t; t::events | ("\(t::problems | length)\u001f\(t::problems | first // "")\u001f\(if t::init == null then "none" else "init" end)")' "$f"
  measure "eval transcript_tool_inputs (:384)" jq -rR -n -L "$LIB" --arg n Bash 'import "transcript" as t; t::events | (t::tool_uses[] | select(.name == $n) | .input | tostring)' "$f"
  measure "eval known tools (:428)" jq -rR -n -L "$LIB" 'import "transcript" as t; t::events | (t::init | .tools // [] | if type == "array" then .[] | strings else empty end)' "$f"
done

echo "== fixed per-process cost"
measure "jq -n 1 (no module)" jq -n 1
measure "jq -n -L import transcript; 1" jq -n -L "$LIB" 'import "transcript" as t; 1'

echo "== deep line (malformed-transcripts.bash:35)"
python3 -c 'import time,subprocess; t=time.perf_counter(); subprocess.run(["bash","-c","printf \"[%.0s\" $(seq 20000) >/dev/null; printf \"]%.0s\" $(seq 20000) >/dev/null"]); print(f"build 20000-deep line: {(time.perf_counter()-t)*1000:.0f} ms")'
