#!/usr/bin/env bash
# security-reviewer 9c73ae4 (iteration 5): probes of test/skills/transcript.jq,
# generate-reports.bash (stubbed claude, copied into a temp tree) and
# eval-helpers.bash for general properties the fact-check probes did not cover:
#   S1 grant-set exactness   S2 one-to-one id matching   S3/S4 line classification
#   S5 block-type allowlist  S6 marker completeness (counts field absent)
# Run from /workspace. Prints generator exit, marker, or helper exit per probe.
set -u
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/test/skills/demo/fixtures" "$tmp/skills/demo" "$tmp/bin"
cp "$repo/test/skills/generate-reports.bash" "$repo/test/skills/runner-contract.bash" \
  "$repo/test/skills/transcript.jq" "$tmp/test/skills/"
echo "# demo" > "$tmp/skills/demo/SKILL.md"
echo "BODY" > "$tmp/test/skills/demo/fixtures/tc-1-thing.txt"
out="$tmp/test/skills/demo/output"
unset CLAUDE_MODEL CLAUDE_FLAGS
PATH="$tmp/bin:$PATH"
printf 'FIXTURE_TOOLS="Bash"\nFIXTURE_MODE="inline"\nFIXTURE_TRANSCRIPT=1\nFIXTURE_BASH=deny-record\nfixture_prompt() { printf "x %%s" "$1"; }\n' \
  > "$tmp/test/skills/demo/runner.bash"

gen() { # gen <transcript-file>: run the generator with a stub that prints it
  local rc=0
  printf '#!/usr/bin/env bash\ncat >/dev/null\ncat %q\n' "$1" > "$tmp/bin/claude"
  chmod +x "$tmp/bin/claude"
  (cd "$tmp" && bash "$tmp/test/skills/generate-reports.bash" demo) > "$tmp/gen.out" 2>&1 || rc=$?
  echo "  generator exit: $rc"
  grep -E 'FAILED|Done|WARNING' "$tmp/gen.out" | sed 's/^/  gen: /'
  if [ -e "$out/tc-1-thing.txt.failed" ]; then echo "  marker: $(cat "$out/tc-1-thing.txt.failed")"; else echo "  NO MARKER"; fi
}

reader() { # reader <transcript-file>: the reader's view
  jq -c -rR -n -L "$repo/test/skills" 'import "transcript" as t; t::events |
    {problems: t::problems, uses: [t::tool_uses[] | {id, name}],
     counts: (if (t::problems | length) == 0 then t::deny_record_counts else null end)}' "$1"
}

# eval-helpers, outside bats
export BATS_TEST_DIRNAME="$repo/test/skills"
BATS_TEST_TMPDIR="$tmp/btmp"
mkdir -p "$BATS_TEST_TMPDIR"
skip() { echo "SKIP: $*"; return 0; }
# shellcheck source=../../../test/skills/eval-helpers.bash
source "$repo/test/skills/eval-helpers.bash"
REPORT_PATH="$tmp/tc.report.md"
echo "# Report" > "$REPORT_PATH"
T="$tmp/tc.transcript.jsonl"
show() { local rc=0 o; o="$("$@" 2>&1)" || rc=$?; echo "  helper exit: $rc"; printf '%s\n' "$o" | sed 's/^/    /' | head -4; }

INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
G1='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"echo good"}}]}}'
RES='{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1"}]}'

echo "=== S1 deny-record: init lists Bash AND BashOutput; an undenied BashOutput tool_use with a tool_result (it ran)"
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash","BashOutput"]}' "$G1" \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"o1","name":"BashOutput","input":{"bash_id":"1"}}]}}' \
  '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"o1","content":"output"}]}}' "$RES" > "$tmp/s1"
reader "$tmp/s1"; gen "$tmp/s1"

echo "=== S2 deny-record: a second Bash tool_use reusing denied id g1, with a tool_result (it ran)"
printf '%s\n' "$INIT" "$G1" \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"rm -rf x"}}]}}' \
  '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"g1","content":"ran"}]}}' "$RES" > "$tmp/s2"
reader "$tmp/s2"; gen "$tmp/s2"
cp "$tmp/s2" "$T"; echo "  assert_mode1_equiv (the same file):"; show assert_mode1_equiv arithmetic-eval 42

X1CALL='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"rm -rf x"}}]}}'
X1RES='{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"x1","content":"ran"}]}}'
esc=$'\e[0m'
bom=$'\xef\xbb\xbf'
echo "=== S3 deny-record: undenied x1 call and its tool_result, each line prefixed with an ANSI reset (valid JSON after the prefix)"
printf '%s\n' "$INIT" "$G1" "$esc$X1CALL" "$esc$X1RES" "$RES" > "$tmp/s3"
reader "$tmp/s3"; gen "$tmp/s3"

echo "=== S4 BOM-prefixed line whose JSON does not parse (lone surrogate in the command): classified as text?"
printf '%s\n' "$INIT" "$G1" \
  "$bom"'{"type":"assistant","message":{"content":[{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"rm -rf x \ud800"}}]}}' \
  "$RES" > "$tmp/s4"
reader "$tmp/s4"
cp "$tmp/s4" "$T"; echo "  assert_no_tool_called Bash rm:"; show assert_no_tool_called Bash rm
echo "  control, same line without the BOM:"
printf '%s\n' "$INIT" "$G1" \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"rm -rf x \ud800"}}]}}' \
  "$RES" > "$T"; show assert_no_tool_called Bash rm

echo "=== S3b the S3 file through assert_no_tool_called Bash rm and assert_mode1_equiv"
cp "$tmp/s3" "$T"; show assert_no_tool_called Bash rm; show assert_mode1_equiv arithmetic-eval 42

echo "=== S5 deny-record: an unknown content-block type in an assistant event (server_tool_use) carrying a command"
printf '%s\n' "$INIT" "$G1" \
  '{"type":"assistant","message":{"content":[{"type":"server_tool_use","id":"s1","name":"bash_code_execution","input":{"command":"rm -rf x"}}]}}' \
  "$RES" > "$tmp/s5"
reader "$tmp/s5"; gen "$tmp/s5"

echo "=== S6 marker completeness: n_problems 0, deny-record, counts field made empty by a trailing newline in claude_code_version"
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9\n","tools":["Bash"]}' "$X1CALL" \
  '{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}' > "$tmp/s6"
reader "$tmp/s6"; gen "$tmp/s6"
