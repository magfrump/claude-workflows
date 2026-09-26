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
  echo '{"type":"system","subtype":"init","tools":["Bash"]}' > "$T"
  jq -nc --arg c "$1" '{type:"assistant",parent_tool_use_id:null,message:{content:[{type:"tool_use",id:"b1",name:"Bash",input:{command:$c}}]}}' >> "$T"
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
  [[ "$output" == *"No Mode 1 command computed"* ]]
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
  echo '[]' > "$TEST_TMPDIR/cmds.json"
  run python3 "$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" "$SKILL_MD" "$TEST_TMPDIR/cmds.json" 'abc'
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
  { echo '{"type":"system","subtype":"init","tools":["Bash"]}'
    jq -nc '{type:"result",subtype:"success",result:"# Report",permission_denials:[]}'; } > "$T"
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
  [[ "$output" == *"Could not read"* ]]
}

@test "a tool name the run's init event does not list fails the check (a misspelling cannot pass)" {
  transcript "echo hi"
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
  { echo '{"type":"system","subtype":"init","tools":["Bash"]}'
    jq -nc '{type:"result",subtype:"success",result:"# Report",permission_denials:[]}'; } > "$T"
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
# stamp_fixture <root> <skill>: give the dispatch tree's tc-1.md report the
# fixture, runner and provenance stamp eval_fixture requires (audit T3).
stamp_fixture() {
  local sk="$1/test/skills"
  mkdir -p "$sk/$2/fixtures"
  echo "fixture" > "$sk/$2/fixtures/tc-1.md"
  echo "FIXTURE_TOOLS=none" > "$sk/$2/runner.bash"
  cp "$BATS_TEST_DIRNAME/runner-contract.bash" "$sk/"
  report_stamp "$sk" "$2" tc-1.md > "$sk/$2/output/tc-1.md.stamp"
}

# allow_if_negative <skill> <check>: an absence-only check (no_tool_called:)
# needs its fixture on NEGATIVE_ONLY_ALLOWLIST, and a positive one must not be.
allow_if_negative() {
  # shellcheck disable=SC2034  # read by eval_fixture
  if key_check_has_positive "$2" any; then
    NEGATIVE_ONLY_ALLOWLIST=()
  else
    NEGATIVE_ONLY_ALLOWLIST=("$1/tc-1.md")
  fi
}

@test "eval_fixture dispatch: tool_called and no_tool_called parse <Tool>[=<ERE>]; mode1_equiv reaches the checker" {
  local root="$TEST_TMPDIR/tree"
  mkdir -p "$root/test/skills/arithmetic-eval/output" "$root/skills"
  ln -s "$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" "$root/test/skills/arithmetic-eval/mode1-equiv.py"
  ln -s "$(cd "$BATS_TEST_DIRNAME/../../skills/arithmetic-eval" && pwd)" "$root/skills/arithmetic-eval"
  transcript "$(with_expr '1 + 1')"
  cp "$T" "$root/test/skills/arithmetic-eval/output/tc-1.md.transcript.jsonl"
  echo "# Report" > "$root/test/skills/arithmetic-eval/output/tc-1.md.report.md"
  stamp_fixture "$root" arithmetic-eval
  BATS_TEST_DIRNAME="$root/test/skills"
  # KEY_CHECK and EXPECTED_VERDICT are read by eval_fixture, not here.
  # shellcheck disable=SC2034
  declare -gA KEY_CHECK EXPECTED_VERDICT
  # shellcheck disable=SC2034
  EXPECTED_VERDICT["tc-1.md"]="any"
  local check
  for check in "tool_called:Bash" "tool_called:Bash=python3" "no_tool_called:Bash=rm -rf" "mode1_equiv:2"; do
    # shellcheck disable=SC2034  # read by eval_fixture
    KEY_CHECK["tc-1.md"]="$check"
    allow_if_negative arithmetic-eval "$check"
    run eval_fixture arithmetic-eval tc-1.md
    [ "$status" -eq 0 ] || { echo "expected pass: $check"; echo "$output"; return 1; }
  done
  for check in "no_tool_called:Bash" "no_tool_called:Bash=python3" "tool_called:Bash=curl" "mode1_equiv:3"; do
    # shellcheck disable=SC2034  # read by eval_fixture
    KEY_CHECK["tc-1.md"]="$check"
    allow_if_negative arithmetic-eval "$check"
    run eval_fixture arithmetic-eval tc-1.md
    [ "$status" -ne 0 ] || { echo "expected fail: $check"; echo "$output"; return 1; }
  done
}

@test "no_tool_called fails on a transcript with no init event (junk or truncated), not reading it as no calls" {
  printf 'a stray warning line\n{"type":"result","subtype":"success","result":"x"}\n' > "$T"
  run assert_no_tool_called Bash
  [ "$status" -ne 0 ]
  [[ "$output" == *"no init event"* ]]
}


@test "eval_fixture dispatch: mode1_equiv runs the fixture's own skill's checker, not arithmetic-eval's" {
  # With the checker path hard-coded to arithmetic-eval, this fails: the stub
  # below is never run (review iteration 3, C25).
  local root="$TEST_TMPDIR/tree2" sk=other-skill
  mkdir -p "$root/test/skills/$sk/output" "$root/skills/$sk"
  printf '#!/usr/bin/env python3\nimport sys\nprint("OTHER-SKILL-CHECKER", sys.argv[1:])\n' > "$root/test/skills/$sk/mode1-equiv.py"
  echo "# other skill" > "$root/skills/$sk/SKILL.md"
  transcript "echo hi"
  cp "$T" "$root/test/skills/$sk/output/tc-1.md.transcript.jsonl"
  echo "# Report" > "$root/test/skills/$sk/output/tc-1.md.report.md"
  stamp_fixture "$root" "$sk"
  BATS_TEST_DIRNAME="$root/test/skills"
  # shellcheck disable=SC2034  # read by eval_fixture
  declare -gA KEY_CHECK EXPECTED_VERDICT
  # shellcheck disable=SC2034  # read by eval_fixture
  KEY_CHECK["tc-1.md"]="mode1_equiv:2"
  run eval_fixture "$sk" tc-1.md
  [ "$status" -eq 0 ]
  [[ "$output" == *"OTHER-SKILL-CHECKER"*"skills/$sk/SKILL.md"* ]]
}

# --- Iteration-4 structural fix: one strict reader (R2, A21) ---

@test "every malformed shape fails mode1_equiv and no_tool_called, even beside a good denied Mode 1 call" {
  source "$BATS_TEST_DIRNAME/malformed-transcripts.bash"
  local good shape
  good="$(with_expr '1 + 1')"
  write_malformed_transcripts "$TEST_TMPDIR/bad" "$good"
  # The same transcript without the bad line passes, so each failure below is
  # the bad shape's doing.
  grep -v '^123$' "$TEST_TMPDIR/bad/number_line.jsonl" > "$T"
  run assert_mode1_equiv arithmetic-eval '2'
  [ "$status" -eq 0 ] || { echo "control failed: $output"; return 1; }
  # no_tool_called's control: the good transcript has no Bash call running
  # `rm`, so it passes; only the bad shape may make it fail. (An earlier
  # version passed "Bash=rm" as one tool name, which failed on the control
  # too and so tested nothing; review iteration 5, api #2.)
  run assert_no_tool_called Bash '"command":"pwd"'
  [ "$status" -eq 0 ] || { echo "no_tool_called control failed: $output"; return 1; }
  for shape in "${MALFORMED_SHAPES[@]}"; do
    cp "$TEST_TMPDIR/bad/$shape.jsonl" "$T"
    run assert_mode1_equiv arithmetic-eval '2'
    [ "$status" -ne 0 ] || { echo "mode1_equiv passed on $shape"; return 1; }
    [[ "$output" == *" fails: "* ]] || { echo "$shape: $output"; return 1; }
    run assert_no_tool_called Bash '"command":"pwd"'
    [ "$status" -ne 0 ] || { echo "no_tool_called passed on $shape"; return 1; }
    [[ "$output" == *" fails: "* ]] || { echo "$shape (no_tool_called): $output"; return 1; }
  done
}

@test "a plain-text line (a stray warning) is ignored, not read as a malformed event" {
  transcript "$(with_expr '1 + 1')"
  sed -i '2i Warning: something printed to stdout' "$T"
  run assert_mode1_equiv arithmetic-eval '2'
  [ "$status" -eq 0 ]
}

@test "mode1-equiv.py takes a JSON array of commands; anything else, or any unexpected error, exits 2" {
  local py="$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" c="$TEST_TMPDIR/cmds.json"
  jq -cn --arg a "$(with_expr '6 * 7')" '[$a]' > "$c"
  run python3 "$py" "$SKILL_MD" "$c" '42'
  [ "$status" -eq 0 ]
  for bad in '{"a":1}' '[1,2]' 'not json'; do
    printf '%s' "$bad" > "$c"
    run python3 "$py" "$SKILL_MD" "$c" '42'
    [ "$status" -eq 2 ] || { echo "$bad -> $status"; return 1; }
    [[ "$output" != *Traceback* ]]
  done
  # Nesting too deep for json.loads raises RecursionError, which the script
  # does not anticipate: the catch-all turns it into exit 2, not a traceback.
  python3 -c 'print("[" * 200000 + "]" * 200000)' > "$c"
  run python3 "$py" "$SKILL_MD" "$c" '42'
  [ "$status" -eq 2 ]
  [[ "$output" == *"checker error"* ]] || [[ "$output" == *"is not JSON"* ]]
  [[ "$output" != *Traceback* ]]
}

@test "an empty tool name fails the check; a bare tool_called failure says 'No Bash call.', not /./" {
  transcript "echo hi"
  run assert_no_tool_called ''
  [ "$status" -ne 0 ]
  [[ "$output" == *"Empty tool name"* ]]
  { echo '{"type":"system","subtype":"init","tools":["Bash"]}'
    jq -nc '{type:"result",subtype:"success",result:"# Report",permission_denials:[]}'; } > "$T"
  run assert_tool_called Bash
  [ "$status" -ne 0 ]
  [[ "$output" == *"No Bash call."* ]]
  [[ "$output" != *"/./"* ]]
}


# --- Iteration-5 fix: the census (R3). A property, not a table of shapes. ---

@test "property: an undenied Bash call inserted at ANY object or array position fails the deny-record verdict and the eval checks" {
  source "$BATS_TEST_DIRNAME/malformed-transcripts.bash"
  transcript "$(with_expr '1 + 1')"
  # Control: the untouched transcript passes.
  run assert_mode1_equiv arithmetic-eval '2'
  [ "$status" -eq 0 ] || { echo "control failed: $output"; return 1; }
  local good="$TEST_TMPDIR/good.jsonl" n f escapes=0
  cp "$T" "$good"
  n="$(write_insertion_variants "$good" "$TEST_TMPDIR/ins")"
  [ "$n" -ge 10 ] || { echo "only $n variants"; return 1; }
  for f in "$TEST_TMPDIR"/ins/v*.jsonl; do
    if [ "$(transcript_jq "$f" 't::deny_record_failures | length')" = 0 ]; then
      escapes=$((escapes + 1)); echo "verdict passed: $(basename "$f")"
    fi
    cp "$f" "$T"
    run assert_mode1_equiv arithmetic-eval '2'
    [ "$status" -ne 0 ] || { escapes=$((escapes + 1)); echo "mode1_equiv passed: $(basename "$f")"; }
    run assert_no_tool_called Bash pwd
    [ "$status" -ne 0 ] || { escapes=$((escapes + 1)); echo "no_tool_called passed: $(basename "$f")"; }
  done
  echo "variants=$n escapes=$escapes"
  [ "$escapes" -eq 0 ]
}

@test "a SKILL.md whose evaluator changed its output format fails the self-test: exit 2, in --check-spec too" {
  # Before the self-test (review iteration 5, A27) this SKILL.md passed
  # --check-spec and every graded command scored None, exit 1: a model result.
  local bad="$TEST_TMPDIR/SKILL.md"
  sed 's/{src.strip()} -> {result}/{src.strip()} => {result}/' "$SKILL_MD" > "$bad"
  grep -q '=> {result}' "$bad"
  run python3 "$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" --check-spec "$bad" '42'
  [ "$status" -eq 2 ]
  [[ "$output" == *"failed its self-test"* ]]
  run python3 "$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" --check-spec "$SKILL_MD" '42'
  [ "$status" -eq 0 ]
}


# --- Iteration-6 fix: no key opts a call out of the census (R5) ---

@test "property: a call stays counted whatever marker-like keys sit on its path (the module's own has() keys and __text)" {
  source "$BATS_TEST_DIRNAME/malformed-transcripts.bash"
  transcript "$(with_expr '1 + 1')"
  local good="$TEST_TMPDIR/good.jsonl" n f escapes=0 keys=()
  cp "$T" "$good"
  mapfile -t keys < <(marker_keys "$BATS_TEST_DIRNAME/transcript.jq")
  [ "${#keys[@]}" -ge 2 ]
  n="$(write_marker_variants "$good" "$TEST_TMPDIR/mk" "${keys[@]}")"
  [ "$n" -ge 10 ]
  for f in "$TEST_TMPDIR"/mk/m*.jsonl; do
    if [ "$(transcript_jq "$f" 't::deny_record_failures | length')" = 0 ]; then
      escapes=$((escapes + 1)); echo "verdict passed: $(basename "$f") $(head -c 200 "$f")"
    fi
  done
  echo "keys=${keys[*]} variants=$n escapes=$escapes"
  [ "$escapes" -eq 0 ]
}

@test "the type allowlists match exactly: substrings and near-misses of allowed names are problems" {
  local t name bad=0
  for t in sys syste "" systemX user_ assistan result2 rate_limit; do
    printf '%s\n' '{"type":"system","subtype":"init","tools":["Bash"]}' "$(jq -cn --arg t "$t" '{type:$t}')" > "$T"
    if [ "$(transcript_jq "$T" 't::problems | length')" = 0 ]; then bad=$((bad + 1)); echo "event type accepted: '$t'"; fi
  done
  for name in tool tool_ "" result text_ think tool_use_x; do
    printf '%s\n' '{"type":"system","subtype":"init","tools":["Bash"]}' \
      "$(jq -cn --arg b "$name" '{type:"assistant",message:{content:[{type:$b}]}}')" > "$T"
    if [ "$(transcript_jq "$T" 't::problems | length')" = 0 ]; then bad=$((bad + 1)); echo "block type accepted: '$name'"; fi
  done
  [ "$bad" -eq 0 ]
}

@test "real transcripts committed in the repo pass the reader with no problems, census = placed count (golden cases)" {
  local root="$BATS_TEST_DIRNAME/../.." f n=0 out
  while IFS= read -r f; do
    n=$((n + 1))
    out="$(jq -rR -n -L "$BATS_TEST_DIRNAME" 'import "transcript" as t; t::events | t::transcript_failures | t::print_verdict' "$root/$f")"
    [ "$out" = "__VERDICT_COMPLETE__" ] || { echo "$f: $out" | head -3; return 1; }
  done < <(git -C "$root" ls-files 'runs/**/transcript.jsonl' 'runs/**/*.transcript.jsonl')
  [ "$n" -gt 0 ] || skip "no committed transcripts"
  echo "golden transcripts: $n"
}

@test "every init event is checked: a later init with other tools fails the deny-record verdict" {
  transcript "$(with_expr '1 + 1')"
  printf '%s\n' '{"type":"system","subtype":"init","tools":["Bash","Read"],"permissionMode":"bypassPermissions"}' >> "$T"
  run assert_mode1_equiv arithmetic-eval '2'
  [ "$status" -ne 0 ]
  [[ "$output" == *"Bash init canary: an init event's tools are"* ]]
}
