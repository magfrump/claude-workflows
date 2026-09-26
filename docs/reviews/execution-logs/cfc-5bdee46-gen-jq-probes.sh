#!/usr/bin/env bash
# Probes of generate-reports.bash's deny-record jq program (extracted verbatim to gen.jq)
INIT='{"type":"system","subtype":"init","tools":["Bash"],"claude_code_version":"2.1.283"}'
INITNB='{"type":"system","subtype":"init","tools":["Read"],"claude_code_version":"2.1.283"}'
A(){ printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":"%s","input":{"command":"x"}}]}}' "$1"; }
R(){ printf '{"type":"result","is_error":false,"result":"r","permission_denials":[%s]}' "$1"; }
D(){ printf '{"tool_name":"%s","tool_use_id":"%s","tool_input":{}}' "$1" "$2"; }
run(){ local name="$1"; shift; printf '%s\n' "$@" > t.jsonl; out=$(jq -rRn -f gen.jq t.jsonl 2>&1); rc=$?; printf '%-45s rc=%s out=[%s]\n' "$name" "$rc" "$out"; }
run "clean: 1 call denied" "$INIT" "$(A t1)" "$(R "$(D Bash t1)")"
run "undenied call" "$INIT" "$(A t1)" "$(R '')"
run "call with no id" "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"x"}}]}}' "$(R "$(D Bash t1)")"
run "subagent call (parent_tool_use_id) denied" "$INIT" '{"type":"assistant","parent_tool_use_id":"p1","message":{"content":[{"type":"tool_use","name":"Bash","id":"s1","input":{}}]}}' "$(R "$(D Bash s1)")"
run "subagent call not denied" "$INIT" '{"type":"assistant","parent_tool_use_id":"p1","message":{"content":[{"type":"tool_use","name":"Bash","id":"s1","input":{}}]}}' "$(R '')"
run "two result events, denials split" "$INIT" "$(A t1)" "$(A t2)" "$(R "$(D Bash t1)")" "$(R "$(D Bash t2)")"
run "non-object lines (array, string, junk)" "$INIT" '[1,2]' '"str"' 'not json' "$(A t1)" "$(R "$(D Bash t1)")"
run "denial for Read (other tool) unseen" "$INIT" "$(A t1)" "$(R "$(D Bash t1),$(D Read r9)")"
run "Bash denial names unseen tool_use (shape change)" "$INIT" '{"type":"assistant","message":{"blocks":[{"type":"tool_use","name":"Bash","id":"t1"}]}}' "$(R "$(D Bash t1)")"
run "denial with null tool_use_id" "$INIT" "$(A t1)" "$(R "$(D Bash t1),{\"tool_name\":\"Bash\"}")"
run "denial missing tool_name" "$INIT" "$(A t1)" "$(R '{"tool_use_id":"t1"}')"
run "no init event" "$(A t1)" "$(R "$(D Bash t1)")"
run "init without Bash" "$INITNB" "$(R '')"
run "init only at END of stream" "$(A t1)" "$(R "$(D Bash t1)")" "$INIT"
run "empty file" 
run "message is a string" "$INIT" '{"type":"assistant","message":"oops"}' "$(R '')"
run "content is a string" "$INIT" '{"type":"assistant","message":{"content":"oops"}}' "$(R '')"
run "content block non-object" "$INIT" '{"type":"assistant","message":{"content":["s",3,null]}}' "$(R '')"
run "permission_denials is a string" "$INIT" "$(A t1)" '{"type":"result","permission_denials":"x"}'
run "permission_denials is an object" "$INIT" "$(A t1)" "{\"type\":\"result\",\"permission_denials\":{\"a\":$(D Bash t1)}}"
run "version is object" '{"type":"system","subtype":"init","tools":["Bash"],"claude_code_version":{"a":1}}' "$(R '')"
run "tools is a string Bash" '{"type":"system","subtype":"init","tools":"Bash"}' "$(R '')"
run "numeric id vs string denial id" "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":5}]}}' "$(R "$(D Bash 5)")"
run "duplicate call ids, one denial" "$INIT" "$(A t1)" "$(A t1)" "$(R "$(D Bash t1)")"
