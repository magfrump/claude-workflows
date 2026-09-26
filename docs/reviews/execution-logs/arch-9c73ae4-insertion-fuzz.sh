#!/usr/bin/env bash
# architecture-review 9c73ae4 (iteration 5): an insertion test for the
# "every Bash call is counted or the run is voided" invariant.
#
# Takes a good deny-record transcript (init, a denied Bash call g1, a denied
# tool_result for g1, a result event) and, for EVERY array and object inside
# every event, inserts one undenied Bash tool_use x1 there (appended to an
# array; added under key "zz" to an object). One insertion per variant file.
# Also one variant per event-type rename. For each variant it asks HEAD's
# transcript.jq for the generator's verdict, and asks the census prototype
# from arch-9c73ae4-census-probe.sh (one `..` selector for validation and
# counting) the same question. A variant is an ESCAPE when
# problems is empty and undenied is 0: the call is present but neither
# counted nor refused. The invariant holds when there are no escapes.
# Run from /workspace. Writes nothing outside a mktemp dir.
set -u
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
dir="$repo/test/skills"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

X1='{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}'
cat > "$tmp/good.jsonl" <<'EOF'
{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"echo good"}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"g1","is_error":true,"content":[{"type":"text","text":"denied"}]}]}}
{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1","tool_input":{"command":"echo good"}}]}
EOF

VERDICT='import "transcript" as t; t::events |
  if (t::problems | length) > 0 then "problem"
  else (t::deny_record_counts | if .undenied > 0 or .unseen > 0 or .orphans > 0 or .foreign > 0 then "voided" else "ESCAPE" end) end'

CENSUS='import "transcript" as t;
  def _calls: [.[] | objects | .. | objects | select(.type == "tool_use")];
  def _results: [.[] | objects | .. | objects | select(.type == "tool_result")];
  t::events
  | (_calls) as $c
  | ([ $c[] | select(((.id | type) == "string" and (.name | type) == "string") | not) ]
     + [ $c[] | select(.name == "Bash" and ((.input | type) != "object" or (.input.command | type) != "string")) ]
     + [ _results[] | select((.tool_use_id | type) != "string") ]) as $bad
  | if (t::problems | length) > 0 or ($bad | length) > 0
       or ([$c[] | .id] | length) != ([$c[] | .id] | unique | length) then "problem"
    else
      ([t::denials[] | select(.tool_name == "Bash") | .tool_use_id] | map({(.): true}) | add // {}) as $den
      | ([$c[] | .id] | map({(.): true}) | add // {}) as $all
      | if ([$c[] | select(.name == "Bash") | select($den[.id] | not)] | length) > 0
           or ([_results[] | select($all[.tool_use_id] | not)] | length) > 0
           or ([t::denials[] | select(.tool_name != "Bash")] | length) > 0 then "voided"
        else "ESCAPE" end
    end'

echo "# cmd: bash docs/reviews/execution-logs/arch-9c73ae4-insertion-fuzz.sh  cwd: $PWD  at: $(date -u +%FT%TZ)  jq: $(jq --version)"
echo "control: $(jq -rR -n -L "$dir" "$VERDICT" "$tmp/good.jsonl") (expected ESCAPE: the control has no x1, so 'passes' is right)"

n=0 esc=0 cesc=0 line_no=0
while IFS= read -r line; do
  line_no=$((line_no + 1))
  # Every path whose value is an array or an object, including the event root.
  while IFS= read -r p; do
    n=$((n + 1))
    variant="$tmp/v$n.jsonl"
    jq -c --argjson p "$p" --argjson x "$X1" \
      'if (getpath($p) | type) == "array" then setpath($p; getpath($p) + [$x])
       else setpath($p + ["zz"]; $x) end' <<< "$line" > "$tmp/ins"
    awk -v k="$line_no" -v f="$tmp/ins" 'NR == k { while ((getline l < f) > 0) print l; next } { print }' \
      "$tmp/good.jsonl" > "$variant"
    v="$(jq -rR -n -L "$dir" "$VERDICT" "$variant" 2>&1)"
    c="$(jq -rR -n -L "$dir" "$CENSUS" "$variant" 2>&1)"
    [ "$v" = ESCAPE ] && esc=$((esc + 1))
    [ "$c" = ESCAPE ] && cesc=$((cesc + 1))
    echo "HEAD=$v  CENSUS=$c  event $line_no  at path $p"
  done < <(jq -c 'paths(type == "array" or type == "object"), []' <<< "$line")
done < "$tmp/good.jsonl"

# Event-type renames: move x1 into the assistant event's content, then rename
# that event's type.
for ty in '"assistant_message"' 'null' '["assistant"]' '"user"' '"system"'; do
  n=$((n + 1))
  variant="$tmp/v$n.jsonl"
  jq -c --argjson x "$X1" --argjson ty "$ty" \
    'if .type == "assistant" then .message.content += [$x] | .type = $ty else . end' \
    "$tmp/good.jsonl" > "$tmp/r.jsonl"
  # Keep the original, well-formed g1 event too, so g1 stays seen and denied.
  { awk 'NR <= 2' "$tmp/good.jsonl"; awk 'NR == 2' "$tmp/r.jsonl"; awk 'NR >= 3' "$tmp/good.jsonl"; } > "$variant"
  v="$(jq -rR -n -L "$dir" "$VERDICT" "$variant" 2>&1)"
  c="$(jq -rR -n -L "$dir" "$CENSUS" "$variant" 2>&1)"
  [ "$v" = ESCAPE ] && esc=$((esc + 1))
  [ "$c" = ESCAPE ] && cesc=$((cesc + 1))
  echo "HEAD=$v  CENSUS=$c  rename assistant event type to $ty"
done

echo "control under CENSUS: $(jq -rR -n -L "$dir" "$CENSUS" "$tmp/good.jsonl")"
echo "variants: $n  HEAD escapes: $esc  CENSUS escapes: $cesc"
