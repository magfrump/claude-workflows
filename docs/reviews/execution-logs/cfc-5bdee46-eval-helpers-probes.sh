#!/usr/bin/env bash
# Probes of eval-helpers.bash tool_inputs_checked / assert_no_tool_called / assert_tool_called
source /workspace/test/skills/eval-helpers.bash
INIT='{"type":"system","subtype":"init","tools":["Bash","Read"]}'
REPORT_PATH=$PWD/x.report.md; T=$PWD/x.transcript.jsonl
p(){ local name="$1" fn="$2" arg="$3" pat="$4"; shift 4; printf '%s\n' "$@" > "$T"; out=$($fn "$arg" $pat 2>&1); rc=$?; printf '%-44s %-22s rc=%s %s\n' "$name" "$fn $arg${pat:+=$pat}" "$rc" "$(echo "$out" | head -1 | cut -c1-110)"; }
A='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":"t1","input":{"command":"rm -rf x"}}]}}'
p "junk file, no init" assert_no_tool_called Bash "" 'garbage' 'more'
p "empty file" assert_no_tool_called Bash "" ''
p "init at end only (truncated start)" assert_no_tool_called Bash "" "$A" "$INIT"
p "truncated: init only" assert_no_tool_called Bash "" "$INIT"
p "truncated: init only, positive check" assert_tool_called Bash "" "$INIT"
p "misspelled tool" assert_no_tool_called bash "" "$INIT" "$A"
p "init with no tools list, misspelled" assert_no_tool_called bash "" '{"type":"system","subtype":"init"}' "$A"
p "message is a string (jq error)" assert_no_tool_called Bash "" "$INIT" '{"type":"assistant","message":"oops"}'
p "shape change hides tool_use" assert_no_tool_called Bash "" "$INIT" '{"type":"assistant","message":{"blocks":[{"type":"tool_use","name":"Bash","input":{}}]}}'
p "negative with pattern, hit" assert_no_tool_called Bash "rm -rf" "$INIT" "$A"
p "positive with pattern" assert_tool_called Bash "rm" "$INIT" "$A"
p "invalid ERE" assert_tool_called Bash "(" "$INIT" "$A"
rm -f "$T"; out=$(assert_no_tool_called Bash 2>&1); echo "missing transcript rc=$? $out"
