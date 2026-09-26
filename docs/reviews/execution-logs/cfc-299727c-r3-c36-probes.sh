#!/usr/bin/env bash
# code-fact-check 299727c: spot-check rubric rows R3 and C36 at HEAD.
# R3: each shape the row names, beside a good denied Bash call (g1), through
# the module's deny_record_failures. C36: an init-only transcript and a string
# init `tools`, through eval-helpers.bash's transcript_checked and
# assert_no_tool_called (the misspelling guard). Run from /workspace.
set -u
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
dir="$repo/test/skills"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
GOOD='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"echo good"}}]}}'
RES='{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1"}]}'
X1='{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}'

probe() {
  local name="$1" t="$tmp/$1.jsonl"
  printf '%s\n' "$INIT" "$GOOD" "$2" "$RES" > "$t"
  echo "=== R3 shape: $name"
  jq -rR -n -L "$dir" 'import "transcript" as t; t::events | t::deny_record_failures | t::print_verdict' "$t"
}

probe tool_use_in_user_event "{\"type\":\"user\",\"message\":{\"content\":[$X1]}}"
probe missing_event_type "{\"message\":{\"content\":[$X1]}}"
probe unknown_event_type "{\"type\":\"assistant_message\",\"message\":{\"content\":[$X1]}}"
probe nonstring_event_type "{\"type\":[\"assistant\"],\"message\":{\"content\":[$X1]}}"
probe nested_in_tool_result "{\"type\":\"user\",\"message\":{\"content\":[{\"type\":\"tool_result\",\"tool_use_id\":\"g1\",\"content\":[$X1]}]}}"
probe server_tool_use_block '{"type":"assistant","message":{"content":[{"type":"server_tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
probe reused_denied_id '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"rm -rf x"}}]}}'
probe ansi_prefixed "$(printf '\033[0m')"'{"type":"assistant","message":{"content":['"$X1"']}}'
probe bom_prefixed "$(printf '\357\273\277')"'{"type":"assistant","message":{"content":['"$X1"']}}'

echo "=== C36: eval-helpers on an init-only transcript and on a string init tools"
export BATS_TEST_DIRNAME="$dir"
export BATS_TEST_TMPDIR="$tmp"
# shellcheck source=../../../test/skills/eval-helpers.bash
source "$dir/eval-helpers.bash"
REPORT_PATH="$tmp/tc-1.md.report.md"
echo "# Report" > "$REPORT_PATH"
T="$tmp/tc-1.md.transcript.jsonl"

printf '%s\n' "$INIT" > "$T"
o="$(transcript_checked "$T" 2>&1)"; echo "init-only: transcript_checked -> exit $? ${o:+($o)}"
o="$(assert_no_tool_called Bash 2>&1)"; echo "init-only: assert_no_tool_called Bash -> exit $? ${o:+($o)}"

printf '%s\n' '{"type":"system","subtype":"init","tools":"Bash"}' \
  '{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}' > "$T"
o="$(assert_no_tool_called bash 2>&1)"; echo "string tools, misspelled 'bash': assert_no_tool_called -> exit $? ${o:+($o)}"
printf '%s\n' '{"type":"system","subtype":"init","tools":["Bash"]}' \
  '{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}' > "$T"
o="$(assert_no_tool_called bash 2>&1)"; echo "array tools, misspelled 'bash': assert_no_tool_called -> exit $? ${o:+($o)}"
