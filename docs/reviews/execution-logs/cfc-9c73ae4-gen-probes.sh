#!/usr/bin/env bash
# code-fact-check 9c73ae4: probe test/skills/generate-reports.bash (copied into
# a temp tree, as test/generate-reports.bats does) with a stubbed claude.
# Each probe prints the generator's exit status and the .failed marker (or
# "NO MARKER"). Run from /workspace.
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

runner() { # runner <tools> <extra lines>
  printf 'FIXTURE_TOOLS="%s"\nFIXTURE_MODE="inline"\nfixture_prompt() { printf "x %%s" "$1"; }\n%s\n' "$1" "$2" \
    > "$tmp/test/skills/demo/runner.bash"
}
stub_file() { # the stub prints <file> as its stream
  printf '#!/usr/bin/env bash\ncat >/dev/null\ncat %q\n' "$1" > "$tmp/bin/claude"
  chmod +x "$tmp/bin/claude"
}
run_gen() {
  local rc=0
  (cd "$tmp" && bash "$tmp/test/skills/generate-reports.bash" demo) > "$tmp/gen.out" 2>&1 || rc=$?
  echo "generator exit: $rc"
  grep -E 'FAILED|Done|WARNING' "$tmp/gen.out" | sed 's/^/  gen: /'
  if [ -e "$out/tc-1-thing.txt.failed" ]; then
    echo "  marker: $(cat "$out/tc-1-thing.txt.failed")"
  else
    echo "  NO MARKER"
  fi
}

DENY=$'FIXTURE_TRANSCRIPT=1\nFIXTURE_BASH=deny-record'
X1='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
RES='{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}'

echo "=== P1 deny-record, undenied Bash call, init claude_code_version contains a newline"
runner Bash "$DENY"
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9\n9","tools":["Bash"]}' "$X1" "$RES" > "$tmp/t1"
stub_file "$tmp/t1"; run_gen

echo "=== P2 deny-record, undenied Bash call, init claude_code_version contains \\u001f"
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9\u001f9","tools":["Bash"]}' "$X1" "$RES" > "$tmp/t2"
stub_file "$tmp/t2"; run_gen

echo "=== P3 deny-record, undenied Bash call, claude_code_version is an object"
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":{"v":1},"tools":["Bash"]}' "$X1" "$RES" > "$tmp/t3"
stub_file "$tmp/t3"; run_gen

echo "=== P4 control: undenied Bash call, normal version"
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}' "$X1" "$RES" > "$tmp/t4"
stub_file "$tmp/t4"; run_gen

echo "=== P5 deny-record: malformed line beside an undenied Bash call, claude exited 3 (is the tripwire reported?)"
printf '#!/usr/bin/env bash\ncat >/dev/null\nprintf "%%s\\n" %q %q %q %q\nexit 3\n' \
  '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}' "$X1" '[1]' "$RES" > "$tmp/bin/claude"
chmod +x "$tmp/bin/claude"; run_gen

echo "=== P6 non-transcript run, claude succeeds: marker removed?"
runner WebSearch ""
printf '#!/usr/bin/env bash\ncat >/dev/null\necho "# Report"\n' > "$tmp/bin/claude"; chmod +x "$tmp/bin/claude"; run_gen

echo "=== P7 non-transcript run, claude exits 1"
printf '#!/usr/bin/env bash\ncat >/dev/null\necho "# Report"\nexit 1\n' > "$tmp/bin/claude"; chmod +x "$tmp/bin/claude"; run_gen

echo "=== P8 transcript run, unreadable fixture (inline cat fails under set -e): marker left?"
runner Bash "$DENY"
chmod 000 "$tmp/test/skills/demo/fixtures/tc-1-thing.txt"
stub_file "$tmp/t4"; run_gen
chmod 644 "$tmp/test/skills/demo/fixtures/tc-1-thing.txt"

echo "=== P9 transcript run (not deny-record), a Bash tool_use inside a user event, no_tool_called-style view"
runner Agent $'FIXTURE_TRANSCRIPT=1'
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Agent"]}' \
  '{"type":"user","message":{"content":[{"type":"tool_use","id":"u1","name":"Bash","input":{"command":"rm -rf x"}}]}}' \
  '{"type":"result","subtype":"success","result":"# Report"}' > "$tmp/t9"
stub_file "$tmp/t9"; run_gen

echo "=== P10 deny-record, the undenied Bash call sits in a user event (tool_use_in_user_event)"
runner Bash "$DENY"
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}' \
  '{"type":"user","message":{"content":[{"type":"tool_use","id":"u1","name":"Bash","input":{"command":"pwd"}}]}}' \
  "$RES" > "$tmp/t10"
stub_file "$tmp/t10"; run_gen
