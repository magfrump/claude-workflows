#!/usr/bin/env bash
# Probes of test/skills/arithmetic-eval/mode1-equiv.py exit codes on mis-shaped transcripts and specs
M=/workspace/test/skills/arithmetic-eval/mode1-equiv.py
SK=/workspace/skills/arithmetic-eval/SKILL.md
INIT='{"type":"system","subtype":"init","tools":["Bash"]}'
t(){ local name="$1" spec="$2"; shift 2; printf '%s\n' "$@" > m.jsonl; out=$(python3 "$M" "$SK" m.jsonl "$spec" 2>&1 | tail -2 | tr '\n' ' '); rc=${PIPESTATUS[0]}; python3 "$M" "$SK" m.jsonl "$spec" >/dev/null 2>&1; rc=$?; printf '%-48s rc=%s %s\n' "$name" "$rc" "${out:0:170}"; }
c(){ local name="$1"; shift; out=$(python3 "$M" "$@" 2>&1 | head -1); python3 "$M" "$@" >/dev/null 2>&1; rc=$?; printf '%-48s rc=%s %s\n' "$name" "$rc" "${out:0:150}"; }
R='{"type":"result","permission_denials":[{"tool_name":"Bash","tool_use_id":"t1"}]}'
t "bash input not a dict" 1 "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":"t1","input":"x"}]}}' "$R"
t "bash command not a string" 1 "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":"t1","input":{"command":5}}]}}' "$R"
t "message is a string (skipped?)" 1 "$INIT" '{"type":"assistant","message":"oops"}' "$R"
t "content is a string (skipped?)" 1 "$INIT" '{"type":"assistant","message":{"content":"oops"}}' "$R"
t "event is a JSON array (skipped?)" 1 "$INIT" '[1,2]' "$R"
t "permission_denials is a number" 1 "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":"t1","input":{"command":"x"}}]}}' '{"type":"result","permission_denials":5}'
t "denial tool_use_id is a list (unhashable)" 1 "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":"t1","input":{"command":"x"}}]}}' '{"type":"result","permission_denials":[{"tool_use_id":[1]}]}'
t "tool_use id is a dict (unhashable)" 1 "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":{"a":1},"input":{"command":"x"}}]}}' "$R"
t "call with no id, denials present" 1 "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"x"}}]}}' "$R"
t "denial names Read, not Bash, same id" 1 "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":"t1","input":{"command":"x"}}]}}' '{"type":"result","permission_denials":[{"tool_name":"Read","tool_use_id":"t1"}]}'
t "no init event, no calls" 1 "$R"
t "result event is a list-typed permission_denials of strings" 1 "$INIT" '{"type":"result","permission_denials":["t1"]}'
printf 'x\n' > m.jsonl
for spec in "1e400" "nan" "inf" "1_000" "+1" " 1" "1 " "1~" "1~-1" "1~-0" ".5" "5." "1e5" "-2.5E-3~0.1" "1|" "1||2" "١" "0x10" "1~1e400" "1e-400"; do c "spec [$spec]" --check-spec "$SK" "$spec"; done
c "--check-spec arity 1" --check-spec "$SK"
c "--check-spec arity 3" --check-spec "$SK" 1 2
c "no args" 
c "unreadable transcript" "$SK" /nonexistent 1
printf '\xff\xfe\n' > bad.jsonl; c "non-utf8 transcript" "$SK" bad.jsonl 1
