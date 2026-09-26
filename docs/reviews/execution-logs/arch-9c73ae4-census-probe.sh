#!/usr/bin/env bash
# architecture-review 9c73ae4 (iteration 5): does a census reader close the
# "shape the reader accepts but does not count" class by construction?
#
# Compares, on the same transcripts, HEAD's transcript.jq (problems +
# deny_record_counts) with a prototype census defined inline below, which
# derives the validated set and the counted set from ONE selector:
#   every object with .type == "tool_use" anywhere in any event (jq's `..`).
# The prototype is not a proposed patch, only a feasibility check.
# Transcripts: the fact-check's escape shapes (cfc-9c73ae4-reader-probes.sh),
# the 13-shape table (test/skills/malformed-transcripts.bash) and a control.
# Run from /workspace. Writes nothing outside a mktemp dir.
set -u
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
dir="$repo/test/skills"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# shellcheck source=../../../test/skills/malformed-transcripts.bash
. "$dir/malformed-transcripts.bash"

INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
GOOD='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"echo good"}}]}}'
RES='{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1","tool_input":{"command":"echo good"}}]}'
X1='{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}'

# HEAD's verdict, as the generator computes it (problems first, counts only
# when there are none).
HEAD_PROG='import "transcript" as t; t::events |
  if (t::problems | length) > 0 then "HEAD: problem: \(t::problems | first)"
  else "HEAD: counts \(t::deny_record_counts | [.undenied,.unseen,.orphans,.foreign] | map(tostring) | join(" "))" end'

# The census prototype. One selector (`_calls`) feeds both validation and
# counting, so a tool_use cannot be validated-but-uncounted or
# counted-but-unvalidated, wherever it sits.
CENSUS_PROG='import "transcript" as t;
  def _calls: [.[] | objects | .. | objects | select(.type == "tool_use")];
  def _results: [.[] | objects | .. | objects | select(.type == "tool_result")];
  def census_problems:
    (_calls) as $c
    | [ $c[] | if ((.id | type) == "string" and (.name | type) == "string") | not
               then "a tool_use has no string id and name"
               elif .name == "Bash" and ((.input | type) != "object" or (.input.command | type) != "string")
               then "a Bash tool_use has no string input.command" else empty end ]
    + (if ([$c[] | .id] | length) != ([$c[] | .id] | unique | length) then ["two tool_uses share an id"] else [] end)
    + [ _results[] | select((.tool_use_id | type) != "string") | "a tool_result has no string tool_use_id" ];
  def census_counts:
    (_calls) as $c
    | ([t::denials[] | select(.tool_name == "Bash") | .tool_use_id] | map({(.): true}) | add // {}) as $den
    | ([$c[] | .id] | map({(.): true}) | add // {}) as $all
    | { undenied: ([$c[] | select(.name == "Bash") | select($den[.id] | not)] | length),
        orphans:  ([_results[] | select($all[.tool_use_id] | not)] | length) };
  t::events
  | ((t::problems + census_problems)) as $p
  | if ($p | length) > 0 then "CENSUS: problem: \($p | first)"
    else "CENSUS: counts undenied=\(census_counts.undenied) orphans=\(census_counts.orphans)" end'

run_both() {
  local name="$1" file="$2"
  echo "=== $name"
  jq -rR -n -L "$dir" "$HEAD_PROG" "$file" 2>&1 | head -2
  jq -rR -n -L "$dir" "$CENSUS_PROG" "$file" 2>&1 | head -2
}

probe() {
  local name="$1" bad="$2" f="$tmp/$1.jsonl"
  printf '%s\n' "$INIT" "$GOOD" "$bad" "$RES" > "$f"
  run_both "$name" "$f"
}

echo "# cmd: bash docs/reviews/execution-logs/arch-9c73ae4-census-probe.sh  cwd: $PWD  at: $(date -u +%FT%TZ)  jq: $(jq --version)"
echo "## control (init, denied g1, result): both must pass with 0 undenied"
printf '%s\n' "$INIT" "$GOOD" "$RES" > "$tmp/control.jsonl"
run_both control "$tmp/control.jsonl"

echo "## escape shapes from the fact-check (HEAD passes each; census must not)"
probe tool_use_in_user_event "{\"type\":\"user\",\"message\":{\"content\":[$X1]}}"
probe typeless_event_with_tool_use "{\"message\":{\"content\":[$X1]}}"
probe renamed_event_type "{\"type\":\"assistant_message\",\"message\":{\"content\":[$X1]}}"
probe array_type_field "{\"type\":[\"assistant\"],\"message\":{\"content\":[$X1]}}"
probe tool_use_inside_tool_result "{\"type\":\"user\",\"message\":{\"content\":[{\"type\":\"tool_result\",\"tool_use_id\":\"g1\",\"content\":[$X1]}]}}"
probe duplicate_id_undenied_second_call '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"rm -rf x"}}]}}'
probe tool_result_in_assistant_event '{"type":"assistant","message":{"content":[{"type":"tool_result","tool_use_id":"zz","content":"ran"}]}}'

echo "## benign shapes (both should pass: sub-agent call is counted, a rate-limit event is ignored)"
probe tool_use_in_subagent_event "{\"type\":\"assistant\",\"parent_tool_use_id\":\"a1\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"id\":\"x1\",\"name\":\"Bash\",\"input\":{\"command\":\"pwd\"}}]}}"
probe tool_result_for_denied_g1 '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"g1","is_error":true,"content":"denied"}]}}'
probe rate_limit_event '{"type":"rate_limit_event","rate_limit_info":{"status":"allowed"}}'

echo "## the 13-shape table (both must reject every shape)"
write_malformed_transcripts "$tmp/table" "echo good"
for s in "${MALFORMED_SHAPES[@]}"; do
  run_both "table:$s" "$tmp/table/$s.jsonl"
done

echo "## cost: a 5000-event transcript, each event nesting 50 levels"
{
  printf '%s\n' "$INIT"
  for i in $(seq 1 5000); do
    printf '{"type":"system","subtype":"x","v":%s1%s}\n' "$(printf '[%.0s' $(seq 50))" "$(printf ']%.0s' $(seq 50))"
    [ "$i" -eq 1 ] && printf '%s\n' "$GOOD"
  done
  printf '%s\n' "$RES"
} > "$tmp/big.jsonl"
echo "size: $(wc -c < "$tmp/big.jsonl") bytes"
s=$(date +%s%N); jq -rR -n -L "$dir" "$HEAD_PROG" "$tmp/big.jsonl"; e=$(date +%s%N)
echo "HEAD ms: $(( (e - s) / 1000000 ))"
s=$(date +%s%N); jq -rR -n -L "$dir" "$CENSUS_PROG" "$tmp/big.jsonl"; e=$(date +%s%N)
echo "CENSUS ms: $(( (e - s) / 1000000 ))"
