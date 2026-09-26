#!/usr/bin/env bash
# API-consistency review probes, iteration 5 (commit 9c73ae4). Run from /workspace:
#   bash docs/reviews/execution-logs/acr-9c73ae4-probes.sh
# Sources test/skills/eval-helpers.bash and test/skills/malformed-transcripts.bash
# directly; runs no claude and no network command.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/../../.." || exit 1
ROOT="$PWD"
work="$(mktemp -d "${TMPDIR:-/tmp}/acr-probes.XXXXXX")"
trap 'rm -rf "$work"' EXIT
# shellcheck source=../../../test/skills/eval-helpers.bash
source "$ROOT/test/skills/eval-helpers.bash"
# shellcheck source=../../../test/skills/malformed-transcripts.bash
source "$ROOT/test/skills/malformed-transcripts.bash"
REPORT_PATH="$work/tc-1.md.report.md"
T="$work/tc-1.md.transcript.jsonl"
echo "# Report" > "$REPORT_PATH"
echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)  jq: $(jq --version)"

write_malformed_transcripts "$work/bad" "echo good"
grep -v '^123$' "$work/bad/number_line.jsonl" > "$T"

echo "== A1: control transcript (no bad line); the table test's call form vs the function's (tool, ERE) form"
out="$(assert_no_tool_called Bash=rm)"; echo "assert_no_tool_called Bash=rm   -> exit $? : $out"
out="$(assert_no_tool_called Bash rm)"; echo "assert_no_tool_called Bash rm   -> exit $? : $out"
out="$(assert_no_tool_called Bash good)"; echo "assert_no_tool_called Bash good -> exit $? : $out"

echo "== A2: init.tools not an array: generator-style vs helper-style reading"
printf '%s\n' '{"type":"system","subtype":"init","tools":"Bash"}' \
  '{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}' > "$T"
out="$(assert_tool_called Bahs)"; echo "assert_tool_called Bahs (misspelled, tools is a string) -> exit $? : $out"
jq -rR -n -L "$ROOT/test/skills" 'import "transcript" as t; t::events | t::init
  | if . == null then "none" elif ((.tools // []) | type == "array" and index(["Bash"]) != null) then "bash" else "nobash" end' "$T" \
  | sed 's/^/generator init_state expression -> /'

echo "== A3: marker/message strings for the same conditions, generator vs eval-helpers"
cp "$work/bad/number_line.jsonl" "$T"
out="$(transcript_checked "$T")"; echo "transcript_checked (number_line) -> exit $? : $out"
printf '%s\n' '{"type":"result","subtype":"success","result":"x"}' > "$T"
out="$(transcript_checked "$T")"; echo "transcript_checked (no init)     -> exit $? : $out"
printf '%s\n' '{"type":"system","subtype":"init","tools":["Bash"]}' \
  '{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Read","tool_use_id":"r9"}]}' > "$T"
out="$(assert_mode1_equiv arithmetic-eval 2 2>&1)"; echo "assert_mode1_equiv (foreign denial) -> exit $? : $out"
