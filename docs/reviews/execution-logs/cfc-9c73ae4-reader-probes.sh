#!/usr/bin/env bash
# code-fact-check 9c73ae4: probe test/skills/transcript.jq beyond the 13-shape
# table. For each probe transcript, print the reader's problems, tool_uses,
# deny_record_counts and init, as generate-reports.bash and eval-helpers.bash
# would see them. Run from /workspace.
set -u
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../test/skills" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
GOOD='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"echo good"}}]}}'
RES='{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1"}]}'
X1='{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}'

probe() {
  local name="$1" bad="$2" t="$tmp/$1.jsonl"
  printf '%s\n' "$INIT" "$GOOD" "$bad" "$RES" > "$t"
  echo "=== $name"
  echo "bad line: $(printf '%s' "$bad" | cut -c1-160 | od -c | head -3 | tr -s ' ' | tr '\n' ' ')"
  jq -c -rR -n -L "$dir" 'import "transcript" as t; t::events |
    {problems: t::problems, bash_ids: [t::tool_uses[] | select(.name == "Bash") | .id],
     counts: (if (t::problems | length) == 0 then t::deny_record_counts else null end),
     init_tools: (t::init | .tools)}' "$t"
  echo "jq exit: $?"
}

probe tool_use_in_user_event "{\"type\":\"user\",\"message\":{\"content\":[$X1]}}"
probe tool_use_in_subagent_event "{\"type\":\"assistant\",\"parent_tool_use_id\":\"a1\",\"message\":{\"content\":[$X1]}}"
probe result_denials_null '{"type":"result","subtype":"success","result":"x","permission_denials":null}'
probe tool_result_for_denied_g1 '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"g1","is_error":true,"content":"denied"}]}}'
probe crlf_line "$(printf '%s\r' "{\"type\":\"assistant\",\"message\":{\"content\":[$X1]}}")"
probe leading_whitespace "   {\"type\":\"assistant\",\"message\":{\"content\":[$X1]}}"
probe top_string '"a string"'
probe top_true 'true'
probe top_null 'null'
probe duplicate_init '{"type":"system","subtype":"init","tools":[]}'
probe extra_top_fields "{\"type\":\"assistant\",\"uuid\":\"u\",\"session_id\":\"s\",\"extra\":[1,2],\"message\":{\"content\":[$X1]}}"
# Beyond the brief's list: shapes the header's "Other event types need only be
# objects" admits.
probe typeless_event_with_tool_use "{\"message\":{\"content\":[$X1]}}"
probe renamed_event_type "{\"type\":\"assistant_message\",\"message\":{\"content\":[$X1]}}"
probe array_type_field "{\"type\":[\"assistant\"],\"message\":{\"content\":[$X1]}}"
probe tool_use_inside_tool_result "{\"type\":\"user\",\"message\":{\"content\":[{\"type\":\"tool_result\",\"tool_use_id\":\"g1\",\"content\":[$X1]}]}}"
probe two_objects_one_line "{\"type\":\"system\",\"subtype\":\"x\"}{\"type\":\"assistant\",\"message\":{\"content\":[$X1]}}"
probe bom_prefixed_line "$(printf '\xef\xbb\xbf')$(printf '%s' "{\"type\":\"assistant\",\"message\":{\"content\":[$X1]}}")"
probe duplicate_id_undenied_second_call '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"rm -rf x"}}]}}'
probe bash_denial_naming_read_call '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"r1","name":"Read","input":{"file_path":"x"}}]}}'
probe lowercase_bash_name "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"id\":\"x1\",\"name\":\"bash\",\"input\":{\"command\":\"pwd\"}}]}}"
