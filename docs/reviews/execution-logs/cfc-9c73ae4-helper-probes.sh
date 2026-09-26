#!/usr/bin/env bash
# code-fact-check 9c73ae4: probe test/skills/eval-helpers.bash's transcript
# checks and test/skills/arithmetic-eval/mode1-equiv.py outside bats. Run from
# /workspace. Prints each probe's exit status and output.
set -u
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export BATS_TEST_DIRNAME="$repo/test/skills"
BATS_TEST_TMPDIR="$tmp/btmp"
mkdir -p "$BATS_TEST_TMPDIR"
skip() { echo "SKIP: $*"; return 0; }
# shellcheck source=../../../test/skills/eval-helpers.bash
source "$repo/test/skills/eval-helpers.bash"
REPORT_PATH="$tmp/tc.report.md"
echo "# Report" > "$REPORT_PATH"
T="$tmp/tc.transcript.jsonl"
INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash","Agent"]}'

show() { local rc=0 out; out="$("$@" 2>&1)" || rc=$?; echo "exit: $rc"; printf '%s\n' "$out" | sed 's/^/  /' | head -8; }

echo "=== E1 tail-truncated transcript (init line only): assert_no_tool_called Bash"
printf '%s\n' "$INIT" > "$T"; show assert_no_tool_called Bash

echo "=== E2 a Bash tool_use inside a user event: assert_no_tool_called Bash rm (check syntax no_tool_called:Bash=rm)"
printf '%s\n' "$INIT" '{"type":"user","message":{"content":[{"type":"tool_use","id":"u1","name":"Bash","input":{"command":"rm -rf x"}}]}}' \
  '{"type":"result","subtype":"success","result":"x"}' > "$T"; show assert_no_tool_called Bash rm

echo "=== E3 subagents_min on a transcript with no init and a malformed line"
printf '%s\n' '[1]' '{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"a1","name":"Agent","input":{}}]}}' > "$T"
show assert_subagents_min 1
echo "  (transcript_checked on the same file:)"; show transcript_checked "$T"

echo "=== E4 assert_mode1_equiv, checker exit 1: temp file cleaned up?"
printf '%s\n' "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"echo hi"}}]}}' \
  '{"type":"result","subtype":"success","result":"x","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1"}]}' > "$T"
show assert_mode1_equiv arithmetic-eval 42
echo "  files left in BATS_TEST_TMPDIR: $(find "$BATS_TEST_TMPDIR" -type f | wc -l)"

echo "=== E5 mode1-equiv.py: SKILL.md evaluator whose output format changed (a SKILL.md problem)"
sk="$tmp/SKILL.md"
sed 's/ -> {result}/ => {result}/' "$repo/skills/arithmetic-eval/SKILL.md" > "$sk"
grep -c '=> {result}' "$sk" | sed 's/^/  modified lines: /'
prog="$(awk '/^## Mode 1/{m=1} m && /^```bash$/{f=1; next} f && /^```$/{exit} f' "$sk" | sed '/^EXPREOF$/,$d' | sed '$d')"
cmd="$prog"$'\n6 * 7\nEXPREOF'
cmd="$(printf '%s\n' "$cmd" | sed '0,/^[0-9]/{/^3600/d}')"
jq -cn --arg c "$cmd" '[$c]' > "$tmp/cmds.json"
show python3 "$repo/test/skills/arithmetic-eval/mode1-equiv.py" --check-spec "$sk" 42
show python3 "$repo/test/skills/arithmetic-eval/mode1-equiv.py" "$sk" "$tmp/cmds.json" 42
echo "  (same command against the real SKILL.md:)"
sed 's/ => {result}/ -> {result}/' "$tmp/cmds.json" > "$tmp/cmds2.json"
show python3 "$repo/test/skills/arithmetic-eval/mode1-equiv.py" "$repo/skills/arithmetic-eval/SKILL.md" "$tmp/cmds2.json" 42
