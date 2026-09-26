#!/usr/bin/env bats
# @category fast
# Unit tests for arithmetic-eval's mode1_equiv: check (arithmetic-eval/
# mode1-equiv.py) and no_tool_called:, against synthetic deny-record
# transcripts shaped like the 2026-09-25 probe: the Bash tool_use in an
# assistant event, and its id in the result event's permission_denials.
# Each command is built from SKILL.md's own Mode 1 block, so a SKILL.md edit
# that breaks the extraction fails here, not in a paid run.

load eval-helpers

bats_require_minimum_version 1.5.0

setup() {
  TEST_TMPDIR=$(mktemp -d)
  REPORT_PATH="$TEST_TMPDIR/tc-1.md.report.md"
  echo "# Report" > "$REPORT_PATH"
  T="$TEST_TMPDIR/tc-1.md.transcript.jsonl"
  SKILL_MD="$BATS_TEST_DIRNAME/../../skills/arithmetic-eval/SKILL.md"
  # SKILL.md's Mode 1 block, minus its trailing "# → ..." comment line.
  BLOCK="$TEST_TMPDIR/block.sh"
  awk '/^## Mode 1/ { m=1 } m && /^```bash$/ { f=1; next } f && /^```$/ { exit } f' "$SKILL_MD" \
    | grep -v '^# →' > "$BLOCK"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# with_expr <expression>: the Mode 1 block with its heredoc body replaced.
with_expr() {
  awk -v e="$1" "/<<'EXPREOF'\$/ { print; print e; skip=1; next } skip && /^EXPREOF\$/ { skip=0 } !skip" "$BLOCK"
}

# transcript <command> [denied]: a one-call transcript; denied defaults to yes.
transcript() {
  local denials='[{"tool_name":"Bash","tool_use_id":"b1","tool_input":{}}]'
  [ "${2:-yes}" = yes ] || denials='[]'
  jq -nc --arg c "$1" '{type:"assistant",parent_tool_use_id:null,message:{content:[{type:"tool_use",id:"b1",name:"Bash",input:{command:$c}}]}}' > "$T"
  jq -nc --argjson d "$denials" '{type:"result",subtype:"success",result:"# Report",permission_denials:$d}' >> "$T"
}

@test "the Mode 1 block extracts from SKILL.md" {
  grep -q "timeout 5 python3 -c '" "$BLOCK"
  grep -qx "EXPREOF" "$BLOCK"
}

@test "SKILL.md's own wrapper and program, with a new expression, compute its value" {
  transcript "$(with_expr '4750 / 0.0025 * 1000')"
  run assert_mode1_equiv arithmetic-eval '1900000000'
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "a copy with the comments stripped still passes (AST, not bytes)" {
  # The probe's Haiku dropped every Python comment. Remove full-line comments
  # and trailing "   # ..." comments from the program.
  transcript "$(with_expr '4750 / 0.0025 * 1000' | sed -E '/^[[:space:]]+#/d; s/[[:space:]]{2,}#[^"]*$//')"
  grep -q '# every intermediate' "$T" && { echo "comments not stripped"; return 1; }
  run assert_mode1_equiv arithmetic-eval '1900000000'
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "a one-token change to the program fails" {
  transcript "$(with_expr '4750 / 0.0025 * 1000' | sed 's/MAX_BITS = 100000/MAX_BITS = 100001/')"
  run assert_mode1_equiv arithmetic-eval '1900000000'
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"program differs"* ]]
}

@test "the right program with the wrong expression fails" {
  transcript "$(with_expr '4750 / 0.0025 * 10000')"
  run assert_mode1_equiv arithmetic-eval '1900000000'
  [ "$status" -ne 0 ]
  [[ "$output" == *"No Mode 1 call computed"* ]]
}

@test "any listed value passes, and a tolerance widens one" {
  transcript "$(with_expr '26.2 * 1.61')"
  run assert_mode1_equiv arithmetic-eval '42.1648128'
  [ "$status" -ne 0 ]
  run assert_mode1_equiv arithmetic-eval '99|42.16~0.002'
  [ "$status" -eq 0 ]
}

@test "shell after the closing EXPREOF fails; a trailing comment does not" {
  transcript "$(with_expr '1 + 1'; echo 'touch pwned')"
  run assert_mode1_equiv arithmetic-eval '2'
  [ "$status" -ne 0 ]
  [[ "$output" == *"not the Mode 1 wrapper"* ]]
  transcript "$(with_expr '1 + 1'; echo '# → 2')"
  run assert_mode1_equiv arithmetic-eval '2'
  [ "$status" -eq 0 ]
}

@test "a second EXPREOF line cannot smuggle shell: the heredoc closes at the first" {
  # bash ends the body at the first EXPREOF line and runs what follows as shell.
  transcript "$(with_expr $'1 + 1\nEXPREOF\ntouch pwned')"
  run assert_mode1_equiv arithmetic-eval '2'
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not the Mode 1 wrapper"* ]]
}

@test "a bad value spec or missing argument exits 2 with a message, not a traceback" {
  transcript "$(with_expr '1 + 1')"
  run python3 "$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" "$SKILL_MD" "$T" 'abc'
  [ "$status" -eq 2 ]
  [[ "$output" == *"bad expected value"* ]]
  [[ "$output" != *"Traceback"* ]]
  run python3 "$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" "$SKILL_MD"
  [ "$status" -eq 2 ]
}

@test "a skill with no mode1-equiv.py of its own fails the check with a message" {
  transcript "$(with_expr '1 + 1')"
  run assert_mode1_equiv no-such-skill '2'
  [ "$status" -ne 0 ]
  [[ "$output" == *"skill-owned checker"* ]]
}

@test "a wrapper change (no ulimit) fails" {
  transcript "$(with_expr '1 + 1' | sed 's/ulimit -t 5 -v 1000000 2>\/dev\/null; //')"
  run assert_mode1_equiv arithmetic-eval '2'
  [ "$status" -ne 0 ]
  [[ "$output" == *"not the Mode 1 wrapper"* ]]
}

@test "the expression is evaluated by SKILL.md's evaluator, so a non-numeric one gets no value" {
  transcript "$(with_expr '__import__("os").getcwd()')"
  run assert_mode1_equiv arithmetic-eval '0'
  [ "$status" -ne 0 ]
  [[ "$output" == *"-> None"* ]]
}

@test "tripwire: a Bash call missing from permission_denials fails whatever it computed" {
  transcript "$(with_expr '1 + 1')" no
  run assert_mode1_equiv arithmetic-eval '2'
  [ "$status" -ne 0 ]
  [[ "$output" == *"Bash tripwire"* ]]
}

@test "no_tool_called passes with no Bash call and fails with one" {
  jq -nc '{type:"result",subtype:"success",result:"# Report",permission_denials:[]}' > "$T"
  run assert_no_tool_called Bash
  [ "$status" -eq 0 ]
  transcript "echo hi"
  run assert_no_tool_called Bash
  [ "$status" -ne 0 ]
  [[ "$output" == *"Expected no Bash calls, found 1"* ]]
}

@test "no_tool_called:<Tool>=<ERE> takes tool_called's shape: fails only on a matching input" {
  transcript "rm -rf /tmp/x"
  run assert_no_tool_called Bash 'rm -rf'
  [ "$status" -ne 0 ]
  [[ "$output" == *"matching /rm -rf/"* ]]
  run assert_no_tool_called Bash 'curl'
  [ "$status" -eq 0 ]
}

@test "a missing transcript fails (not skips)" {
  rm -f "$T"
  run assert_mode1_equiv arithmetic-eval '2'
  [ "$status" -ne 0 ]
  [[ "$output" == *"FIXTURE_TRANSCRIPT=1"* ]]
}

# --- Iteration-2 review fixes (A11, A12, A13, C18) ---

@test "no_tool_called fails, never passes, on an invalid or dash-leading pattern" {
  transcript "rm -rf / --force ("
  run assert_no_tool_called Bash '('
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid pattern"* ]]
  run assert_no_tool_called Bash '-rf'
  [ "$status" -ne 0 ]
  [[ "$output" == *"Expected no Bash calls with input matching /-rf/"* ]]
}

@test "no_tool_called fails on an unreadable transcript" {
  transcript "echo hi"
  chmod 000 "$T"
  run assert_no_tool_called Bash
  chmod 644 "$T"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Could not read tool calls"* ]]
}

@test "a tool name the run's init event does not list fails the check (a misspelling cannot pass)" {
  transcript "echo hi"
  sed -i '1i {"type":"system","subtype":"init","tools":["Bash"]}' "$T"
  run assert_no_tool_called bash
  [ "$status" -ne 0 ]
  [[ "$output" == *"bash is not a tool of this run"* ]]
  run assert_no_tool_called Bash
  [ "$status" -ne 0 ]
  [[ "$output" == *"Expected no Bash calls"* ]]
}

@test "tool_called:<Tool> with no pattern means the tool was called at all" {
  transcript "echo hi"
  run assert_tool_called Bash
  [ "$status" -eq 0 ]
  jq -nc '{type:"result",subtype:"success",result:"# Report",permission_denials:[]}' > "$T"
  run assert_tool_called Bash
  [ "$status" -ne 0 ]
  [[ "$output" == *"Bash calls seen: 0"* ]]
  run assert_tool_called Bash ''
  [ "$status" -ne 0 ]
}

@test "mode1_equiv labels a checker exit 2 as a setup error, not a model result" {
  transcript "$(with_expr '1 + 1')"
  run assert_mode1_equiv arithmetic-eval '1~-1'
  [ "$status" -ne 0 ]
  [[ "$output" == *"SETUP ERROR (exit 2), not a model result"* ]]
  run assert_mode1_equiv arithmetic-eval 'nan'
  [[ "$output" == *"SETUP ERROR"* ]]
}

@test "pre-flight: every committed mode1_equiv: spec is valid (--check-spec), before any paid run" {
  local specs spec n=0
  specs="$(grep '^KEY_CHECK' "$BATS_TEST_DIRNAME/arithmetic-eval/expected-verdicts.bash" | grep -o 'mode1_equiv:[^;"]*')"
  [ -n "$specs" ]
  while IFS= read -r spec; do
    n=$((n + 1))
    python3 "$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" --check-spec "$SKILL_MD" "${spec#mode1_equiv:}" \
      || { echo "invalid spec: $spec"; return 1; }
  done <<< "$specs"
  [ "$n" -ge 4 ]
}

# eval_fixture itself, against a throwaway tree shaped like test/skills, so the
# dispatcher's parsing of tool_called:/no_tool_called:/mode1_equiv: is tested,
# not only the assert functions (review C18).
@test "eval_fixture dispatch: tool_called and no_tool_called parse <Tool>[=<ERE>]; mode1_equiv resolves by skill" {
  local root="$TEST_TMPDIR/tree"
  mkdir -p "$root/test/skills/arithmetic-eval/output" "$root/skills"
  ln -s "$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" "$root/test/skills/arithmetic-eval/mode1-equiv.py"
  ln -s "$(cd "$BATS_TEST_DIRNAME/../../skills/arithmetic-eval" && pwd)" "$root/skills/arithmetic-eval"
  transcript "$(with_expr '1 + 1')"
  cp "$T" "$root/test/skills/arithmetic-eval/output/tc-1.md.transcript.jsonl"
  echo "# Report" > "$root/test/skills/arithmetic-eval/output/tc-1.md.report.md"
  BATS_TEST_DIRNAME="$root/test/skills"
  declare -gA KEY_CHECK EXPECTED_VERDICT
  EXPECTED_VERDICT["tc-1.md"]="any"
  local check
  for check in "tool_called:Bash" "tool_called:Bash=python3" "no_tool_called:Bash=rm -rf" "mode1_equiv:2"; do
    KEY_CHECK["tc-1.md"]="$check"
    run eval_fixture arithmetic-eval tc-1.md
    [ "$status" -eq 0 ] || { echo "expected pass: $check"; echo "$output"; return 1; }
  done
  for check in "no_tool_called:Bash" "no_tool_called:Bash=python3" "tool_called:Bash=curl" "mode1_equiv:3"; do
    KEY_CHECK["tc-1.md"]="$check"
    run eval_fixture arithmetic-eval tc-1.md
    [ "$status" -ne 0 ] || { echo "expected fail: $check"; echo "$output"; return 1; }
  done
}
