#!/usr/bin/env bash
# Security iter4 probes, part 2: model-steerable unparseable lines (jq 1.6), mode1-equiv RecursionError, fork exhaustion.
GEN=/workspace/docs/reviews/execution-logs/cfc-5bdee46-gen.jq
M=/workspace/test/skills/arithmetic-eval/mode1-equiv.py; SK=/workspace/skills/arithmetic-eval/SKILL.md
I='{"type":"system","subtype":"init","tools":["Bash"]}'
A='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","id":"t1","input":{"command":"echo \ud800"}}]}}'
printf '%s\n' "$I" "$A" '{"type":"result","is_error":false,"result":"r","permission_denials":[{"tool_name":"Bash","tool_use_id":"t1"}]}' > s.jsonl
echo "S1 lone surrogate in command, call denied:   gen=[$(jq -rRn "$(cat $GEN)" s.jsonl | tr '\t' ' ')]"
printf '%s\n' "$I" "$A" '{"type":"result","is_error":false,"result":"r","permission_denials":[]}' > s2.jsonl
echo "S2 lone surrogate in command, call undenied: gen=[$(jq -rRn "$(cat $GEN)" s2.jsonl | tr '\t' ' ')]"
echo "S2 transcript_tool_inputs: [$(jq -rR --arg n Bash 'fromjson? | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == $n) | .input | tostring' s2.jsonl)]"
python3 $M $SK s2.jsonl 4 >/dev/null 2>&1; echo "S2 mode1-equiv rc=$? (python json parses lone surrogates)"
for n in 124 125; do python3 -c "
n=$n
s='{\"a\":'*n+'1'+'}'*n
print('{\"type\":\"system\",\"subtype\":\"init\",\"tools\":[\"Bash\"]}')
print('{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"id\":\"t1\",\"input\":{\"command\":\"echo\",\"x\":'+s+'}}]}}')
print('{\"type\":\"result\",\"is_error\":false,\"result\":\"r\",\"permission_denials\":[]}')" > d.jsonl
echo "D$n tool input nested $n objects deep, undenied: gen=[$(jq -rRn "$(cat $GEN)" d.jsonl | tr '\t' ' ')]"; done
jq -R 'fromjson' d.jsonl 2>&1 | head -1 | cut -c1-90
python3 -c "
print('{\"type\":\"system\",\"subtype\":\"init\",\"tools\":[\"Bash\"]}')
print('{\"type\":\"x\",\"y\":'+'['*1200+']'*1200+'}')" > deep.jsonl
python3 $M $SK deep.jsonl 4 2>&1 | tail -1; echo "R1 mode1-equiv on a 1200-deep line rc=${PIPESTATUS[0]}"
cat > fork.sh <<'EOF'
ulimit -u 1 || exit 0
x="$(readlink /proc/self/cwd 2>/dev/null)"; echo "reached: readlink-subst rc=$?"
EOF
timeout 60 bash fork.sh >fork.out 2>&1; echo "F1 command substitution under RLIMIT_NPROC exhaustion: bash exit=$? ; $(grep -v retry fork.out | grep -v setlocale)"
