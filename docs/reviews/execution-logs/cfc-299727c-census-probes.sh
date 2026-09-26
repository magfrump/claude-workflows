#!/usr/bin/env bash
# code-fact-check 299727c: try to break test/skills/transcript.jq's census
# ("wherever a call sits, it is found") and its allowlists. Each probe is a
# deny-record transcript: an init event listing Bash, one DENIED Bash call
# (g1), one probe line, and a result event denying g1 only. For each probe it
# prints the module's deny_record_failures verdict (as the generator prints
# it, sentinel included) and the Bash commands the census sees (what
# no_tool_called / mode1_equiv read). A probe whose verdict is only the
# sentinel PASSED deny-record. Run from /workspace.
set -u
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../test/skills" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
GOOD='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"echo good"}}]}}'
RES='{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1"}]}'
# The undenied call each probe hides (id x1, command "pwd").
X1='{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}'

verdict() {
  jq -rR -n -L "$dir" 'import "transcript" as t; t::events | t::deny_record_failures | t::print_verdict' "$1"
  echo "  (jq exit $?)"
  printf '  census Bash commands: '
  jq -rR -n -L "$dir" -c 'import "transcript" as t; t::events | [t::tool_uses[] | select(.name == "Bash") | .input.command]' "$1"
}

# probe <name> <line>: INIT, GOOD, <line>, RES
probe() {
  local name="$1" t="$tmp/$1.jsonl"
  printf '%s\n' "$INIT" "$GOOD" "$2" "$RES" > "$t"
  echo "=== $name"
  verdict "$t"
}

# probe_file <name>: the transcript is already at $tmp/<name>.jsonl
probe_file() {
  echo "=== $1"
  verdict "$tmp/$1.jsonl"
}

echo "## Control"
printf '%s\n' "$INIT" "$GOOD" "$RES" > "$tmp/control.jsonl"
probe_file control

echo "## Type-string variants of tool_use (brief item 1)"
probe trailing_space_in_assistant_content '{"type":"assistant","message":{"content":[{"type":"tool_use ","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
probe uppercase_in_assistant_content '{"type":"assistant","message":{"content":[{"type":"TOOL_USE","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
probe cyrillic_o_in_assistant_content '{"type":"assistant","message":{"content":[{"type":"tооl_use","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
probe escaped_underscore_is_still_tool_use '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
probe uppercase_nested_in_system_event '{"type":"system","subtype":"hook","x":{"type":"TOOL_USE","id":"x1","name":"Bash","input":{"command":"pwd"}}}'
probe trailing_space_nested_in_tool_input '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g2","name":"Bash","input":{"command":"echo n","x":{"type":"tool_use ","id":"x1","name":"Bash","input":{"command":"pwd"}}}}]}}'

echo "## allowlists use jq inside/1, which is substring containment for strings"
probe substring_block_type_tool '{"type":"assistant","message":{"content":[{"type":"tool","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
probe substring_block_type_empty '{"type":"assistant","message":{"content":[{"type":"","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
probe substring_user_block_type_result '{"type":"user","message":{"content":[{"type":"result","tool_use_id":"x1","content":"ran"}]}}'
probe substring_event_type_sys '{"type":"sys","anything":1}'
probe substring_event_type_empty '{"type":"","anything":1}'
probe substring_event_type_with_real_call "{\"type\":\"assist\",\"message\":{\"content\":[$X1]}}"

echo "## JSON-in-string and duplicate keys"
probe call_as_json_in_text_block "$(jq -cn --arg s "$X1" '{type:"assistant",message:{content:[{type:"text",text:$s}]}}')"
probe duplicate_type_key_last_wins_text '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"},"type":"text","text":"x"}]}}'
probe duplicate_type_key_last_wins_tool_use '{"type":"assistant","message":{"content":[{"type":"text","text":"x","type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
probe duplicate_content_key "{\"type\":\"assistant\",\"message\":{\"content\":[$X1],\"content\":[]}}"

echo "## Top-level key __text (the reader's own marker for ignored lines)"
probe event_with___text_key_call_unplaced "{\"__text\":\"x\",\"payload\":$X1}"
probe event_with___text_key_call_placed "{\"__text\":\"x\",\"type\":\"assistant\",\"message\":{\"content\":[$X1]}}"
probe event_with___text_key_call_and_result "{\"__text\":\"x\",\"a\":$X1,\"r\":{\"type\":\"tool_result\",\"tool_use_id\":\"x1\",\"content\":\"ran\"}}"

echo "## init events (brief item 1)"
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash","Bash"]}' "$GOOD" "$RES" > "$tmp/init_tools_bash_twice.jsonl"
probe_file init_tools_bash_twice
probe second_init_event_lists_more_tools '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash","Read"]}'
printf '%s\n' "$INIT" "$GOOD" '{"type":"system","subtype":"init","tools":["Bash","Read"]}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"r1","name":"Read","input":{"file_path":"x"}}]}}' "$RES" > "$tmp/second_init_plus_read_call.jsonl"
probe_file second_init_plus_read_call
printf '%s\n' "$GOOD" "{\"type\":\"assistant\",\"message\":{\"content\":[$X1]}}" "$RES" > "$tmp/no_init_undenied_call.jsonl"
probe_file no_init_undenied_call
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9"}' "$GOOD" "$RES" > "$tmp/init_without_tools.jsonl"
probe_file init_without_tools

echo "## Lines that are not events"
probe bare_number_line '42'
probe bare_word_line 'Warning: something'
probe quoted_string_line '"a string"'
probe true_line 'true'
probe two_objects_one_line "{\"type\":\"system\",\"subtype\":\"x\"} {\"type\":\"assistant\",\"message\":{\"content\":[$X1]}}"
probe ansi_prefixed_event "$(printf '\033[0m')"'{"type":"assistant","message":{"content":['"$X1"']}}'
probe type_is_array_on_event "{\"type\":[\"assistant\"],\"message\":{\"content\":[$X1]}}"
probe type_is_array_on_block '{"type":"assistant","message":{"content":[{"type":["tool_use"],"id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'

echo "## NUL bytes (written with printf, so the line holds a literal 0x00)"
{ printf '%s\n' "$INIT" "$GOOD"; printf '{"type":"assistant","message":{"content":[%s]}}\000\n' "$X1"; printf '%s\n' "$RES"; } > "$tmp/nul_after_event.jsonl"
probe_file nul_after_event
{ printf '%s\n' "$INIT" "$GOOD"; printf '\000{"type":"assistant","message":{"content":[%s]}}\n' "$X1"; printf '%s\n' "$RES"; } > "$tmp/nul_before_event.jsonl"
probe_file nul_before_event
{ printf '%s\n' "$INIT" "$GOOD"; printf '\000pwd tool_use\n'; printf '%s\n' "$RES"; } > "$tmp/nul_text_line.jsonl"
probe_file nul_text_line

echo "## Separators other than LF"
{ printf '%s\r' "$INIT" "$GOOD" "{\"type\":\"assistant\",\"message\":{\"content\":[$X1]}}" "$RES"; } > "$tmp/cr_only_separators.jsonl"
probe_file cr_only_separators

echo "## Nesting depth jq 1.6 will parse"
for d in 200 256 257 300; do
  inner="$X1"
  for _ in $(seq "$d"); do inner="[$inner]"; done
  probe "call_nested_${d}_arrays_deep_in_system_event" "{\"type\":\"system\",\"subtype\":\"x\",\"v\":$inner}"
done

echo "## Scale: 20000 denied Bash calls plus one undenied (timed)"
{
  printf '%s\n' "$INIT"
  jq -cn 'range(20000) | {type:"assistant",message:{content:[{type:"tool_use",id:"b\(.)",name:"Bash",input:{command:"echo \(.)"}}]}}'
  printf '%s\n' "{\"type\":\"assistant\",\"message\":{\"content\":[$X1]}}"
  jq -cn '{type:"result",subtype:"success",result:"# Report",permission_denials:[range(20000) | {tool_name:"Bash",tool_use_id:"b\(.)"}]}'
} > "$tmp/big.jsonl"
echo "=== big (bytes: $(wc -c < "$tmp/big.jsonl"))"
SECONDS=0
jq -rR -n -L "$dir" 'import "transcript" as t; t::events | t::deny_record_failures | t::print_verdict' "$tmp/big.jsonl"
echo "  (jq exit $?; whole seconds: $SECONDS)"
