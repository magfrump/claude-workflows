#!/usr/bin/env bash
# Security iter4 probes (jq 1.6, python3). cwd = scratchpad.
W=/workspace
GEN=$W/docs/reviews/execution-logs/cfc-5bdee46-gen.jq
M=$W/test/skills/arithmetic-eval/mode1-equiv.py
SK=$W/skills/arithmetic-eval/SKILL.md
source $W/test/skills/eval-helpers.bash
REPORT_PATH=$PWD/x.report.md; T=$PWD/x.transcript.jsonl
# A correct Mode 1 command for "2+2" (=4), taken verbatim from SKILL.md's block
CMD=$(python3 - <<'EOF'
import re,json
t=open('/workspace/skills/arithmetic-eval/SKILL.md').read()
b=re.search(r"^## Mode 1\b.*?^```bash\n(.*?)^```", t, re.S|re.M).group(1)
head=b[:b.index("<<'EXPREOF'\n")+len("<<'EXPREOF'\n")]
print(json.dumps(head+"2+2\nEXPREOF"))
EOF
)
INIT='{"type":"system","subtype":"init","tools":["Bash"],"claude_code_version":"9.9"}'
tu(){ printf '{"type":"tool_use","name":"Bash","id":"%s","input":{"command":%s}}' "$1" "$2"; }
run(){ local name="$1"; shift; printf '%s\n' "$@" > "$T"
  g=$(jq -rRn "$(cat $GEN)" "$T" 2>/dev/null || echo unreadable)
  n=$(assert_no_tool_called Bash >/dev/null 2>&1; echo $?)
  m=$(python3 $M $SK "$T" 4 >/dev/null 2>&1; echo $?)
  printf '%-58s gen=[%s] no_tool_called_rc=%s mode1_rc=%s\n' "$name" "$(echo $g | tr '\t' ' ')" "$n" "$m"; }
DEN(){ printf '{"type":"result","is_error":false,"result":"r","permission_denials":[%s]}' "$1"; }
d(){ printf '{"tool_name":"%s","tool_use_id":"%s"}' "$1" "$2"; }
echo "== baseline"
run "B0 normal denied Mode 1 call" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[$(tu t1 "$CMD")]}}" "$(DEN "$(d Bash t1)")"
echo "== F1 parser divergence: non-object content block before the tool_use"
run "P1 [\"stray\", Bash t1], t1 denied" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[\"stray\",$(tu t1 '"rm -rf x"')]}}" "$(DEN "$(d Bash t1)")"
run "P1b [7, Bash t1], t1 denied" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[7,$(tu t1 '"rm -rf x"')]}}" "$(DEN "$(d Bash t1)")"
run "P1c [Bash t1, \"stray\"] (order reversed)" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[$(tu t1 '"rm -rf x"'),\"stray\"]}}" "$(DEN "$(d Bash t1)")"
echo "== F2 both shapes / deny failure plus one shape"
run "P2a tool_use moved + no permission_denials key" "$INIT" "{\"type\":\"assistant\",\"message\":{\"blocks\":[$(tu t1 '"rm -rf x"')]}}" '{"type":"result","is_error":false,"result":"r"}'
run "P2b tool_use moved + denial tool_name renamed" "$INIT" "{\"type\":\"assistant\",\"message\":{\"blocks\":[$(tu t1 '"rm -rf x"')]}}" "$(DEN "$(d bash t1)")"
run "P2c tool_use moved + call NOT denied (executed)" "$INIT" "{\"type\":\"assistant\",\"message\":{\"blocks\":[$(tu t1 '"rm -rf x"')]}}" "$(DEN "")"
run "P2d same as P2c + its tool_result in a user event" "$INIT" "{\"type\":\"assistant\",\"message\":{\"blocks\":[$(tu t1 '"rm -rf x"')]}}" '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t1","content":"ok"}]}}' "$(DEN "")"
run "P2e only permission_denials moved (tool_use visible)" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[$(tu t1 '"rm -rf x"')]}}" '{"type":"result","is_error":false,"result":"r","denials":[{"tool_name":"Bash","tool_use_id":"t1"}]}'
echo "== mode1-equiv exit-0 attempts"
run "M1 Mode 1 t1 denied under tool_name Read" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[$(tu t1 "$CMD")]}}" "$(DEN "$(d Read t1)")"
run "M2 Mode 1 t1 denied + hidden undenied t2 in .blocks" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[$(tu t1 "$CMD")]}}" "{\"type\":\"assistant\",\"message\":{\"blocks\":[$(tu t2 '"rm -rf x"')]}}" "$(DEN "$(d Bash t1)")"
run "M3 id true vs denial id 1 (hash-equal in Python)" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"id\":true,\"input\":{\"command\":$CMD}}]}}" '{"type":"result","is_error":false,"result":"r","permission_denials":[{"tool_name":"Bash","tool_use_id":1}]}'
run "M4 id 1 vs denial id \"1\" (tostring-equal in jq)" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"id\":1,\"input\":{\"command\":$CMD}}]}}" '{"type":"result","is_error":false,"result":"r","permission_denials":[{"tool_name":"Bash","tool_use_id":"1"}]}'
run "M5 permission_denials is an object, not a list" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[$(tu t1 "$CMD")]}}" '{"type":"result","is_error":false,"result":"r","permission_denials":{"tool_name":"Bash","tool_use_id":"t1"}}'
run "M6 NaN ids on both sides (Python json accepts NaN)" "$INIT" "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"id\":NaN,\"input\":{\"command\":$CMD}}]}}" '{"type":"result","is_error":false,"result":"r","permission_denials":[{"tool_name":"Bash","tool_use_id":NaN}]}'
echo "== init canary"
for tools in '["BashOutput"]' '"Bash,Read"' '"NotBashButContainsBash"' '["bash"]'; do
  printf 'tools=%-28s -> ' "$tools"; printf '{"type":"system","subtype":"init","tools":%s}\n' "$tools" > "$T"; jq -rRn "$(cat $GEN)" "$T" | cut -f3
done
