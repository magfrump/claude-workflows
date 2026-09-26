#!/usr/bin/env bash
# security-reviewer 299727c (iteration 6): probes for the census review.
# Part 1: which reads besides the census consume "__text"-keyed events (init,
#   denials, the last result event), through the module's verdicts.
# Part 2: whether a later init event, or its permissionMode, is checked.
# Part 3: whether transcript data can forge the verdict sentinel.
# Part 4: the same shapes end to end in the real generate-reports.bash
#   (stubbed claude, the layout test/generate-reports.bats builds) and in
#   eval-helpers.bash's transcript_verdict.
# Run from /workspace. Does not run claude or touch the network.
set -u
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
dir="$repo/test/skills"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
CALL='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}}]}}'
TRES='{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"x1","content":"/home"}]}}'
RES_NODENY='{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}'
TXT_DENY='{"__text":0,"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"x1"}]}'
TXT_INIT='{"__text":0,"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
INIT_READ='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash","Read"]}'
INIT_BYPASS='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"],"permissionMode":"bypassPermissions"}'
RES_ERR='{"type":"result","subtype":"error_during_execution","is_error":true,"result":"API Error","permission_denials":[]}'
TXT_RES_OK='{"__text":0,"type":"result","subtype":"success","is_error":false,"result":"# Report","permission_denials":[]}'

verdict() { # verdict <def> <file>
  jq -rR -n -L "$dir" "import \"transcript\" as t; t::events | t::$1 | t::print_verdict" "$2"
}
case_() { # case_ <name> <def> <lines...>
  local name="$1" def="$2"
  shift 2
  printf '%s\n' "$@" > "$tmp/$name.jsonl"
  echo "=== $name ($def)"
  verdict "$def" "$tmp/$name.jsonl" | sed 's/^/  /'
}

echo "##### Part 1: __text-keyed events read outside the census"
case_ control_undenied_call deny_record_failures "$INIT" "$CALL" "$TRES" "$RES_NODENY"
case_ text_key_result_supplies_denial deny_record_failures "$INIT" "$CALL" "$TRES" "$RES_NODENY" "$TXT_DENY"
case_ control_no_init transcript_failures "$RES_NODENY"
case_ text_key_init_only transcript_failures "$TXT_INIT" "$RES_NODENY"
case_ control_init_lists_read deny_record_failures "$INIT_READ" "$RES_NODENY"
case_ text_key_init_shadows_real_init deny_record_failures "$TXT_INIT" "$INIT_READ" "$RES_NODENY"
printf '%s\n' "$INIT" "$RES_ERR" "$TXT_RES_OK" > "$tmp/text_key_result_state.jsonl"
echo "=== text_key_result_state: the generator's result_state and report reads"
jq -rR -n -L "$dir" 'import "transcript" as t; t::events | [.[] | objects | select(.type == "result")] | last
  | if . == null then "none" elif .is_error == true then "error" else "ok" end' \
  "$tmp/text_key_result_state.jsonl" | sed 's/^/  result_state: /'
echo "  deny_record verdict:"
verdict deny_record_failures "$tmp/text_key_result_state.jsonl" | sed 's/^/    /'
case_ control_unparsed_key_collision transcript_failures "$INIT" '{"__unparsed":"x","type":"system","subtype":"status"}' "$RES_NODENY"

echo "##### Part 2: later init events"
case_ later_init_lists_read deny_record_failures "$INIT" "$INIT_READ" "$RES_NODENY"
case_ later_init_bypass_mode deny_record_failures "$INIT" "$INIT_BYPASS" "$RES_NODENY"
echo "=== init events per committed real transcript (runs/**/transcript.jsonl)"
while IFS= read -r f; do
  printf '  %s: ' "${f#"$repo"/}"
  jq -s -c '[.[] | select(.type == "system" and .subtype == "init")] | {inits: length, distinct_tools: (map(.tools) | unique | length)}' "$f"
done < <(git -C "$repo" ls-files -- 'runs/*transcript.jsonl' | sed "s|^|$repo/|")

echo "##### Part 3: sentinel forgery from transcript data"
S='__VERDICT_COMPLETE__'
case_ sentinel_as_event_type transcript_failures "$INIT" "{\"type\":\"$S\"}" "$RES_NODENY"
case_ sentinel_after_newline_in_block_type transcript_failures "$INIT" \
  "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"x\\n$S\"}]}}" "$RES_NODENY"
case_ sentinel_after_newline_in_cli_version deny_record_failures \
  "{\"type\":\"system\",\"subtype\":\"init\",\"claude_code_version\":\"1\\n$S\",\"tools\":[\"Read\"]}" "$RES_NODENY"
case_ sentinel_after_u2028_and_nel_in_tools deny_record_failures \
  "{\"type\":\"system\",\"subtype\":\"init\",\"tools\":[\"a\\u2028$S\",\"b\\u0085$S\"]}" "$RES_NODENY"
case_ sentinel_as_raw_text_line transcript_failures "$S" "$RES_NODENY"
echo "=== line counts equal to the sentinel, per Part 3 verdict (must be exactly 1, the last line)"
for n in sentinel_as_event_type sentinel_after_newline_in_block_type sentinel_after_newline_in_cli_version sentinel_after_u2028_and_nel_in_tools sentinel_as_raw_text_line; do
  d=transcript_failures
  case "$n" in *cli_version|*tools) d=deny_record_failures ;; esac
  out="$(verdict "$d" "$tmp/$n.jsonl")"
  printf '  %s: lines=%s sentinel_lines=%s last_is_sentinel=%s\n' "$n" \
    "$(printf '%s\n' "$out" | wc -l)" "$(printf '%s\n' "$out" | grep -cxF -e "$S")" \
    "$([ "$(printf '%s\n' "$out" | tail -1)" = "$S" ] && echo yes || echo no)"
done

echo "##### Part 4: end to end"
gen_root="$tmp/gen"
mkdir -p "$gen_root/test/skills/demo/fixtures" "$gen_root/skills/demo" "$gen_root/bin"
cp "$dir/generate-reports.bash" "$dir/runner-contract.bash" "$dir/transcript.jq" "$gen_root/test/skills/"
echo "# demo skill" > "$gen_root/skills/demo/SKILL.md"
echo "FIXTURE BODY" > "$gen_root/test/skills/demo/fixtures/tc-1-thing.txt"
echo "SECRET VERDICTS" > "$gen_root/test/skills/demo/expected-verdicts.bash"
cat > "$gen_root/test/skills/demo/runner.bash" <<'EOF'
FIXTURE_TOOLS="Bash"
FIXTURE_MODE="inline"
fixture_prompt() { printf 'Review %s please' "$1"; }
FIXTURE_TRANSCRIPT=1
FIXTURE_BASH=deny-record
EOF
out="$gen_root/test/skills/demo/output"
for name in control_undenied_call text_key_result_supplies_denial text_key_init_shadows_real_init \
    text_key_result_state later_init_bypass_mode sentinel_after_newline_in_cli_version; do
  printf '#!/usr/bin/env bash\ncat >/dev/null\ncat %q\n' "$tmp/$name.jsonl" > "$gen_root/bin/claude"
  chmod +x "$gen_root/bin/claude"
  echo "=== generator (deny-record): $name"
  (cd "$gen_root" && unset CLAUDE_MODEL CLAUDE_FLAGS && PATH="$gen_root/bin:$PATH" bash "$gen_root/test/skills/generate-reports.bash" demo 2>&1 | tail -1 | sed 's/^/  /')
  if [ -e "$out/tc-1-thing.txt.failed" ]; then
    echo "  .failed: $(cat "$out/tc-1-thing.txt.failed")"
  else
    echo "  no .failed marker: the run PASSED the generator's checks"
  fi
done

export BATS_TEST_DIRNAME="$dir"
export BATS_TEST_TMPDIR="$tmp"
# shellcheck source=../../../test/skills/eval-helpers.bash
source "$dir/eval-helpers.bash"
for name in text_key_result_supplies_denial sentinel_after_newline_in_cli_version sentinel_as_event_type; do
  o="$(transcript_verdict "$tmp/$name.jsonl" deny_record_failures 2>&1)"; rc=$?
  echo "=== eval transcript_verdict deny_record_failures: $name -> exit $rc ${o:+($o)}"
done
