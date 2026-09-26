#!/usr/bin/env bash
# Performance probes for b22a026's census transcript.jq (performance review, iteration 6).
# Usage: bash docs/reviews/execution-logs/perf-299727c-census-probes.sh <workdir>
# Writes synthetic stream-json transcripts under <workdir> and prints wall time
# (ms, best of 3) and peak RSS (KB) of each program, each measured in its own
# python3 parent so the RSS is that program's alone. No claude, no network.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
LIB="$REPO/test/skills"
WORK="${1:?workdir}"
mkdir -p "$WORK/old" "$WORK/once"

# The pre-census module (iteration 4, the parent of b22a026), for comparison.
git -C "$REPO" show 'b22a026^:test/skills/transcript.jq' > "$WORK/old/transcript.jq"

# The committed module plus deny_record_failures_once: the same verdict with
# problems, init, tool_uses and tool_results each computed once.
cp "$LIB/transcript.jq" "$WORK/once/transcript.jq"
cat >> "$WORK/once/transcript.jq" <<'JQ'

def _census_problems_of($u; $r):
    ($u[] | if ((.id | _is_str) and (.name | _is_str)) | not then "a tool_use has no string id and name"
            elif .name == "Bash" and ((.input | type) != "object" or (.input.command | _is_str | not)) then
              "a Bash tool_use has no string input.command"
            else empty end),
    ($r[] | if (.tool_use_id | _is_str) | not then "a tool_result has no string tool_use_id" else empty end),
    (if ($u | length) != _placed_tool_uses then "a tool_use outside an assistant event's message.content" else empty end),
    (if ($r | length) != _placed_tool_results then "a tool_result outside a user event's message.content" else empty end),
    (if ([$u[] | .id] | length) != ([$u[] | .id] | unique | length) then "two tool_uses share an id" else empty end);
def deny_record_failures_once:
  tool_uses as $u | tool_results as $r | init as $init
  | ([(.[] | _event_problems), _census_problems_of($u; $r)] | map(_one_line)) as $p
  | ($p + (if $init == null then ["no init event in the stream (the run did not start?)"] else [] end)) as $base
  | if ($p | length) > 0 then $base
    else $base +
      ($init | (.claude_code_version // "unknown") | tostring | _one_line) as $cli
      | ([$u[] | .id] | _set) as $all
      | denials as $d
      | ([$d[] | select(.tool_name == "Bash") | .tool_use_id]) as $denied
      | ($denied | _set) as $dset
      | [ ($init | .tools) as $tools
          | if $init != null and $tools != ["Bash"] then "Bash init canary: the init event's tools are \($tools | tojson | _one_line), not exactly [\"Bash\"] (CLI \($cli))" else empty end,
          ([$u[] | select(.name != "Bash")] | length) as $n
          | if $n > 0 then "Bash tripwire: \($n) call(s) of a tool other than Bash, the only tool granted" else empty end,
          ([$u[] | select($dset[.id] | not)] | length) as $n
          | if $n > 0 then "Bash tripwire: \($n) call(s) not in permission_denials (may have executed)" else empty end,
          ([$denied[] | select($all[.] | not)] | length) as $n
          | if $n > 0 then "Bash parser canary: \($n) Bash denial(s) name a tool_use not in the census (CLI \($cli))" else empty end,
          ([$r[] | select($all[.tool_use_id] | not)] | length) as $n
          | if $n > 0 then "Bash parser canary: \($n) tool_result(s) answer a tool_use not in the census (CLI \($cli); a call may have run unseen)" else empty end,
          ([$d[] | select(.tool_name != "Bash")] | length) as $n
          | if $n > 0 then "Bash tripwire: \($n) denial(s) of a tool other than Bash" else empty end
        ]
    end;
JQ

# measure <label> <cmd...>: best-of-3 wall ms, and the command's own peak RSS.
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

# make_transcript <file> <n> <pad>: init (tools ["Bash"]), n denied Bash calls
# (a <pad>-byte text block beside each, and a tool_result), then a result event
# denying all n.
make_transcript() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, sys
path, n, pad = sys.argv[1], int(sys.argv[2]), "x" * int(sys.argv[3])
with open(path, "w") as f:
    f.write(json.dumps({"type": "system", "subtype": "init", "claude_code_version": "9.9.9", "tools": ["Bash"]}) + "\n")
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

imp='import "transcript" as t; t::events | '
OLD_GEN='import "transcript" as t;
      t::events | [ (t::problems | length), (t::problems | first // ""),
        (t::init | if . == null then "none" elif ((.tools // []) | type == "array" and index(["Bash"]) != null) then "bash" else "nobash" end),
        (t::init | .claude_code_version // "unknown"),
        (if (t::problems | length) == 0 then (t::deny_record_counts | "\(.undenied) \(.unseen) \(.orphans) \(.foreign)") else "" end)
      ] | join("\u001f")'

echo "jq: $(jq --version); nproc: $(nproc); loadavg: $(cut -d' ' -f1-3 /proc/loadavg)"
for spec in 10:0 2000:0 20000:0 40000:1000; do
  n="${spec%%:*}"
  pad="${spec##*:}"
  f="$WORK/t$n.jsonl"
  make_transcript "$f" "$n" "$pad"
  echo "== n=$n bash calls, pad=$pad, $(wc -c < "$f") bytes, $(wc -l < "$f") lines"
  a="$(jq -rR -n -L "$LIB" "$imp t::deny_record_failures | t::print_verdict" "$f" | tr '\n' '|')"
  b="$(jq -rR -n -L "$WORK/once" "$imp t::deny_record_failures_once | t::print_verdict" "$f" | tr '\n' '|')"
  echo "verdict committed: $a"
  echo "verdict bound once: $b"
  measure "events only" jq -rR -n -L "$LIB" "$imp length" "$f"
  measure "tool_uses (one census walk)" jq -rR -n -L "$LIB" "$imp t::tool_uses | length" "$f"
  measure "_placed_tool_uses (positional)" jq -rR -n -L "$LIB" "$imp t::_placed_tool_uses" "$f"
  measure "problems once" jq -rR -n -L "$LIB" "$imp t::problems | length" "$f"
  measure "transcript_failures (committed)" jq -rR -n -L "$LIB" "$imp t::transcript_failures | t::print_verdict" "$f"
  measure "deny_record_failures (committed)" jq -rR -n -L "$LIB" "$imp t::deny_record_failures | t::print_verdict" "$f"
  measure "deny_record_failures bound once" jq -rR -n -L "$WORK/once" "$imp t::deny_record_failures_once | t::print_verdict" "$f"
  measure "iteration-4 generator verdict (b22a026^)" jq -rR -n -L "$WORK/old" "$OLD_GEN" "$f"
  # The generator's other two jq processes per fixture (generate-reports.bash:252-261).
  measure "gen report text (strict reader)" jq -rR -n -L "$LIB" "$imp [.[] | objects | select(.type == \"result\")] | last | .result // empty | if type == \"string\" then . else tojson end" "$f"
  measure "gen result_state (strict reader)" jq -rR -n -L "$LIB" "$imp [.[] | objects | select(.type == \"result\")] | last | if . == null then \"none\" elif .is_error == true then \"error\" else \"ok\" end" "$f"
  # assert_mode1_equiv's second jq process (eval-helpers.bash:539).
  measure "mode1 command extraction" jq -rR -n -L "$LIB" "$imp [t::tool_uses[] | .input.command]" "$f"
done

echo "== equivalence of the bound-once verdict on failing inputs (insertion variants, the 13 shapes)"
# shellcheck source=../../../test/skills/malformed-transcripts.bash
source "$LIB/malformed-transcripts.bash"
nv="$(write_insertion_variants "$WORK/t10.jsonl" "$WORK/ins")"
write_malformed_transcripts "$WORK/bad" "echo good"
same=0 differ=0
for g in "$WORK"/ins/v*.jsonl "$WORK"/bad/*.jsonl; do
  a="$(jq -rR -n -L "$LIB" "$imp t::deny_record_failures | t::print_verdict" "$g" 2>&1 || true)"
  b="$(jq -rR -n -L "$WORK/once" "$imp t::deny_record_failures_once | t::print_verdict" "$g" 2>&1 || true)"
  if [ "$a" = "$b" ]; then same=$((same + 1)); else differ=$((differ + 1)); echo "differs: $g"; fi
done
echo "insertion variants=$nv shapes=${#MALFORMED_SHAPES[@]} identical=$same differ=$differ"

echo "== fixed per-process cost"
measure "jq -n 1 (no module)" jq -n 1
measure "jq -n -L import transcript; 1" jq -n -L "$LIB" 'import "transcript" as t; 1'
measure "python3 -c pass" python3 -c pass

echo "== mode1-equiv.py self-test (reference() runs evaluate(6 * 7) once per invocation)"
SKILL="$REPO/skills/arithmetic-eval/SKILL.md"
measure "mode1-equiv.py --check-spec (committed, with self-test)" python3 "$LIB/arithmetic-eval/mode1-equiv.py" --check-spec "$SKILL" 42
# The self-test's own cost: reference() with and without its evaluate(6 * 7) subprocess.
python3 - "$LIB/arithmetic-eval/mode1-equiv.py" "$SKILL" <<'PY'
import importlib.util, sys, time
spec = importlib.util.spec_from_file_location("m", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
prog, _ = m.reference(sys.argv[2])
ev = []
for _ in range(5):
    t = time.perf_counter(); v = m.evaluate(prog, "6 * 7"); ev.append((time.perf_counter() - t) * 1000)
ref = []
for _ in range(5):
    t = time.perf_counter(); m.reference(sys.argv[2]); ref.append((time.perf_counter() - t) * 1000)
print(f"evaluate(prog, '6 * 7') = {v}: best {min(ev):.1f} ms; reference() with self-test: best {min(ref):.1f} ms")
PY
