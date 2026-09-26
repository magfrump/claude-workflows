# shellcheck shell=bash
# Malformed stream-json transcripts, one per known bad shape (review iteration
# 4: R2, A21, C32 and the earlier A11/A19/Claim 13 shapes). Shared by
# test/generate-reports.bats and test/skills/mode1-equiv.bats, so the generator
# and the eval checks are held to the same table.
#
# write_malformed_transcripts <dir> <good-bash-command>: writes <dir>/<shape>.jsonl
# for every shape. Each holds an init event listing Bash, one well-formed
# DENIED Bash call (id g1) running <good-bash-command>, one bad line, and a
# result event denying g1 only. So a reader that skips the bad line sees a
# fully passing run, and only rejecting the bad shape fails it. Where the bad
# line itself carries a Bash call, that call is never denied (id x1, or a
# missing or non-string id in object_id and no_id): a reader that skipped it
# would let an undenied, possibly executed call through (Stage 2.5 Claim 26b).
# The table is past findings; write_insertion_variants below is the property
# (every position), which the census must pass by construction.
MALFORMED_SHAPES=(array_wrapped string_content string_message nonobject_block
  denials_number list_tool_use_id object_id number_line surrogate deep
  numeric_command no_id tool_result_no_id)

write_malformed_transcripts() {
  local dir="$1" good="$2" init call bad shape
  mkdir -p "$dir"
  init='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
  call='{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}'
  for shape in "${MALFORMED_SHAPES[@]}"; do
    case "$shape" in
      array_wrapped)   bad="[{\"type\":\"assistant\",\"message\":{\"content\":[$call]}}]" ;;
      string_content)  bad="{\"type\":\"assistant\",\"message\":{\"content\":$(jq -cn --arg c "$call" '$c')}}" ;;
      string_message)  bad="{\"type\":\"assistant\",\"message\":$(jq -cn --arg c "{\"content\":[$call]}" '$c')}" ;;
      nonobject_block) bad="{\"type\":\"assistant\",\"message\":{\"content\":[\"x\",$call]}}" ;;
      denials_number)  bad='{"type":"result","permission_denials":5}' ;;
      list_tool_use_id) bad='{"type":"result","permission_denials":[{"tool_name":"Bash","tool_use_id":["x1"]}]}' ;;
      object_id)       bad='{"type":"assistant","message":{"content":[{"type":"tool_use","id":{"x":1},"name":"Bash","input":{"command":"pwd"}}]}}' ;;
      number_line)     bad='123' ;;
      surrogate)       bad='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"echo \ud800"}}]}}' ;;
      deep)            bad="{\"type\":\"x\",\"v\":$(printf '[%.0s' $(seq 20000))$(printf ']%.0s' $(seq 20000))}" ;;
      numeric_command) bad='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"x1","name":"Bash","input":{"command":5}}]}}' ;;
      no_id)           bad='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"pwd"}}]}}' ;;
      tool_result_no_id) bad='{"type":"user","message":{"content":[{"type":"tool_result","content":"ran"}]}}' ;;
    esac
    {
      printf '%s\n' "$init"
      jq -cn --arg c "$good" '{type:"assistant",message:{content:[{type:"tool_use",id:"g1",name:"Bash",input:{command:$c}}]}}'
      printf '%s\n' "$bad"
      printf '%s\n' '{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1","tool_input":{}}]}'
    } > "$dir/$shape.jsonl"
  done
}

# write_insertion_variants <good-transcript> <dir>: the property test's inputs
# (review iteration 5, R3). For every event line and every object or array in
# it (the event itself included), one variant with an undenied Bash tool_use
# inserted there: appended to an array, or added under a new key of an
# object. A reader that counts calls only from positions it knows would miss
# most of them; the census must find every one. Prints the variant count.
write_insertion_variants() {
  local good="$1" dir="$2"
  mkdir -p "$dir"
  jq -rR -n '
    [inputs] as $lines
    | {"type":"tool_use","id":"inserted1","name":"Bash","input":{"command":"pwd"}} as $call
    | range(0; $lines | length) as $i
    | ($lines[$i] | fromjson) as $ev
    | ([$ev | paths(type == "object" or type == "array")] + [[]])[] as $p
    | ($ev | getpath($p)) as $v
    | ($ev | setpath($p; if ($v | type) == "array" then $v + [$call] else $v + {"x_inserted": $call} end)) as $new
    | [$lines[0:$i][], ($new | tojson), $lines[$i + 1:][]] | join("\u001e")' "$good" \
  | awk -v dir="$dir" '{ n++; f = dir "/v" n ".jsonl"; gsub("\036", "\n"); print > f; close(f) } END { print n + 0 }'
}

# marker_keys <transcript.jq>: every key the module tests with has("..."),
# plus "__text" (the marker whose collision was R5). A marker added to the
# module later is picked up automatically.
marker_keys() {
  { grep -o 'has("[^"]*")' "$1" | sed 's/^has("//; s/")$//'; echo "__text"; } | sort -u
}

# write_marker_variants <good-transcript> <dir> <key...>: like
# write_insertion_variants, but the object that receives the undenied Bash
# call also gets each <key> (set to true), and each event gets it at top
# level too. Property (review iteration 6): no key on the path to a call can
# hide it from the census. Prints the variant count.
write_marker_variants() {
  local good="$1" dir="$2"
  shift 2
  mkdir -p "$dir"
  jq -rR -n --args '
    [inputs] as $lines
    | $ARGS.positional as $keys
    | {"type":"tool_use","id":"inserted1","name":"Bash","input":{"command":"pwd"}} as $call
    | range(0; $lines | length) as $i
    | ($lines[$i] | fromjson) as $ev
    | $keys[] as $k
    | (([$ev | paths(type == "object")] + [[]])[]) as $p
    | ($ev | getpath($p)) as $v
    | ($ev | setpath($p; $v + {"x_inserted": $call, ($k): true}) | .[$k] = true) as $new
    | [$lines[0:$i][], ($new | tojson), $lines[$i + 1:][]] | join("\u001e")' "$@" < "$good" \
  | awk -v dir="$dir" '{ n++; f = dir "/m" n ".jsonl"; gsub("\036", "\n"); print > f; close(f) } END { print n + 0 }'
}
