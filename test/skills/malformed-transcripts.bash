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
# line itself carries a Bash call, that call (id x1) is never denied: a reader
# that skipped it would let an undenied, possibly executed call through
# (Stage 2.5 Claim 26b).
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
