#!/usr/bin/env bats
# @category fast
# Tests test/skills/generate-reports.bash's per-skill runner contract against a
# stubbed claude, in a copy of the repo layout under a temp dir so no report is
# ever written into the real test/skills/*/output/.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup() {
  TEST_TMPDIR=$(mktemp -d)
  mkdir -p "$TEST_TMPDIR/test/skills" "$TEST_TMPDIR/bin"
  cp "$REPO_ROOT/test/skills/generate-reports.bash" "$REPO_ROOT/test/skills/runner-contract.bash" \
    "$REPO_ROOT/test/skills/transcript.jq" "$TEST_TMPDIR/test/skills/"
  GEN="$TEST_TMPDIR/test/skills/generate-reports.bash"
  # The caller's environment must not reach the argv under test, and the stub
  # lists its working directory, which must not be the repo root (395k files
  # there made this suite take 10-14 s).
  unset CLAUDE_MODEL CLAUDE_FLAGS
  cd "$TEST_TMPDIR" || return 1

  # The stub records its argv, working directory and stdin, then prints a
  # one-finding report so the generator's "Done" path runs.
  CALLS="$TEST_TMPDIR/calls"
  mkdir -p "$CALLS"
  cat > "$TEST_TMPDIR/bin/claude" <<EOF
#!/usr/bin/env bash
n=\$(ls "$CALLS" | wc -l)
{ printf 'ARGS: %s\n' "\$*"; printf 'ARGC: %s\n' "\$#"; printf 'CWD: %s\n' "\$PWD"; printf 'LS: %s\n' "\$(ls)"
  printf 'FILES: %s\n' "\$(find . -path ./.git -prune -o -type f -print | sort | tr '\n' ' ')"
  echo 'STDIN:'; cat; } > "$CALLS/\$n"
if [[ " \$* " == *" --output-format stream-json "* ]]; then
  # The shape of a real stream-json run: init, one tool call, the result.
  echo '{"type":"system","subtype":"init"}'
  echo '{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"r1","name":"Read","input":{"file_path":"x"}}]}}'
  echo '{"type":"result","subtype":"success","result":"# Report\\n\\n**Severity:** High"}'
else
  printf '# Report\n\n**Severity:** High\n'
fi
EOF
  chmod +x "$TEST_TMPDIR/bin/claude"
  PATH="$TEST_TMPDIR/bin:$PATH"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# make_skill <name> <mode> <tools> — a skill with one fixture and a runner.
make_skill() {
  local name="$1" mode="$2" tools="$3"
  mkdir -p "$TEST_TMPDIR/skills/$name" "$TEST_TMPDIR/test/skills/$name/fixtures"
  echo "# $name skill" > "$TEST_TMPDIR/skills/$name/SKILL.md"
  echo "FIXTURE BODY" > "$TEST_TMPDIR/test/skills/$name/fixtures/tc-1-thing.txt"
  echo "SECRET VERDICTS" > "$TEST_TMPDIR/test/skills/$name/expected-verdicts.bash"
  cat > "$TEST_TMPDIR/test/skills/$name/runner.bash" <<EOF
FIXTURE_TOOLS="$tools"
FIXTURE_MODE="$mode"
fixture_prompt() { printf 'Review %s please' "\$1"; }
EOF
}

@test "inline mode: prompt then fixture content on stdin, runner's tools passed" {
  make_skill demo inline "WebSearch"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  call="$(cat "$CALLS/0")"
  [[ "$call" == *"--tools WebSearch"* ]]
  [[ "$call" == *"--system-prompt-file $TEST_TMPDIR/test/skills/../../skills/demo/SKILL.md"* ]]
  [[ "$call" == *"Review subject.txt please"* ]]
  [[ "$call" == *"FIXTURE BODY"* ]]
  [ -s "$TEST_TMPDIR/test/skills/demo/output/tc-1-thing.txt.report.md" ]
  [[ "$output" == *"lines in report"* ]]
}

@test "inline mode: claude runs in an empty temp directory, not the caller's" {
  make_skill demo inline "WebSearch"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  call="$(cat "$CALLS/0")"
  [[ "$call" != *"CWD: $TEST_TMPDIR"$'\n'* ]]
  [[ "$call" == *$'LS: \n'* ]]
  [[ "$call" == *$'FILES: \n'* ]]
}

@test "FIXTURE_TOOLS=none passes an empty --tools list" {
  make_skill demo inline "none"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  call="$(cat "$CALLS/0")"
  # --tools is the last argument, so an empty value leaves "--tools " at the
  # end of the recorded argv line.
  [[ "$call" == *"--tools "$'\n'* ]]
  [[ "$call" != *"--tools none"* ]]
}

@test "repo mode: claude runs in a temp repo holding only the fixture" {
  make_skill demo repo "Read,Grep,Glob"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  call="$(cat "$CALLS/0")"
  [[ "$call" == *"LS: subject.txt"* ]]
  [[ "$call" != *"SECRET VERDICTS"* ]]
  [[ "$call" != *"CWD: $TEST_TMPDIR/test"* ]]
  # The prompt is on stdin; the fixture body is not (the model reads the file).
  [[ "$call" == *"Review subject.txt please"* ]]
  [[ "$call" != *"FIXTURE BODY"* ]]
}

@test "the fixture's descriptive filename never reaches the model" {
  make_skill demo repo "Read"
  mv "$TEST_TMPDIR/test/skills/demo/fixtures/tc-1-thing.txt" \
     "$TEST_TMPDIR/test/skills/demo/fixtures/tc-9-sql-injection.py"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  call="$(cat "$CALLS/0")"
  [[ "$call" != *"sql-injection"* ]]
  [[ "$call" == *"LS: subject.py"* ]]
  # The report is still keyed by the real fixture name, for the eval suite.
  [ -f "$TEST_TMPDIR/test/skills/demo/output/tc-9-sql-injection.py.report.md" ]
}

@test "every mode passes --strict-mcp-config --restricted --safe-mode" {
  # Without --strict-mcp-config, claude.ai connectors (write-capable Claude Docs
  # tools) are exposed even under --tools "" and in sub-agents. --restricted
  # confines the file tools to the temp dir and drops the user's settings and
  # hooks; --safe-mode drops memory files, skills and plugins.
  local mode
  for mode in inline repo tree; do
    rm -rf "${CALLS:?}"/* "$TEST_TMPDIR/test/skills/demo" "$TEST_TMPDIR/skills/demo"
    if [ "$mode" = tree ]; then make_tree_skill demo
    elif [ "$mode" = inline ]; then make_skill demo inline "WebSearch"
    else make_skill demo repo "Read"; fi
    run bash "$GEN" demo
    [ "$status" -eq 0 ]
    grep -q -- '--strict-mcp-config --restricted --safe-mode' "$CALLS/0" \
      || { echo "mode $mode: hardening flags missing"; cat "$CALLS/0"; return 1; }
  done
}

@test "FIXTURE_TRANSCRIPT=1: stream-json kept as a sidecar, report is the result text" {
  make_skill demo inline "Agent"
  echo 'FIXTURE_TRANSCRIPT=1' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  call="$(cat "$CALLS/0")"
  [[ "$call" == *"--output-format stream-json --verbose --tools Agent"* ]]
  local out="$TEST_TMPDIR/test/skills/demo/output"
  grep -q '"type":"result"' "$out/tc-1-thing.txt.transcript.jsonl"
  diff <(printf '# Report\n\n**Severity:** High\n') "$out/tc-1-thing.txt.report.md"
  [[ "$output" == *"lines in report"* ]]
}

@test "FIXTURE_TRANSCRIPT=1: a non-JSON line in the stream does not lose the report" {
  make_skill demo inline "Agent"
  echo 'FIXTURE_TRANSCRIPT=1' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  # Wrap the stub so it prints a stray warning line first.
  mv "$TEST_TMPDIR/bin/claude" "$TEST_TMPDIR/bin/claude-real"
  printf '#!/usr/bin/env bash\necho "Warning: stray stdout line"\nexec "%s" "$@"\n' \
    "$TEST_TMPDIR/bin/claude-real" > "$TEST_TMPDIR/bin/claude"
  chmod +x "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  diff <(printf '# Report\n\n**Severity:** High\n') \
    "$TEST_TMPDIR/test/skills/demo/output/tc-1-thing.txt.report.md"
}

@test "transcript off: no stream-json flags, and a stale sidecar is removed" {
  make_skill demo inline "WebSearch"
  local out="$TEST_TMPDIR/test/skills/demo/output"
  mkdir -p "$out"
  echo stale > "$out/tc-1-thing.txt.transcript.jsonl"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [[ "$(cat "$CALLS/0")" != *"stream-json"* ]]
  [ ! -e "$out/tc-1-thing.txt.transcript.jsonl" ]
  [ -s "$out/tc-1-thing.txt.report.md" ]
}

@test "a runner with a bad FIXTURE_TRANSCRIPT value is refused" {
  make_skill demo inline "WebSearch"
  echo 'FIXTURE_TRANSCRIPT=yes' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"FIXTURE_TRANSCRIPT"* ]]
  [ "$(ls "$CALLS" | wc -l)" -eq 0 ]
}

# make_tree_skill <name> — a tree-mode skill with one directory fixture whose
# name is descriptive, and a runner whose fixture_base copies a live repo file
# unless the fixture carries a .fixture-no-base marker.
make_tree_skill() {
  local name="$1"
  mkdir -p "$TEST_TMPDIR/skills/$name" "$TEST_TMPDIR/docs"
  echo "# $name skill" > "$TEST_TMPDIR/skills/$name/SKILL.md"
  echo "LIVE RUBRIC" > "$TEST_TMPDIR/docs/rubric.md"
  local fx="$TEST_TMPDIR/test/skills/$name/fixtures/tc-3-planted-weakness"
  mkdir -p "$fx/skills/target"
  echo "TARGET SKILL" > "$fx/skills/target/SKILL.md"
  echo "Please evaluate the target skill." > "$fx/REQUEST.md"
  echo "SECRET VERDICTS" > "$TEST_TMPDIR/test/skills/$name/expected-verdicts.bash"
  cat > "$TEST_TMPDIR/test/skills/$name/runner.bash" <<'EOF'
FIXTURE_TOOLS="Read"
FIXTURE_MODE="tree"
fixture_prompt() { printf 'Evaluate in %s' "$1"; }
fixture_base() {
  [ -e "$2/.fixture-no-base" ] && return 0
  mkdir -p "$1/docs" && cp "$REPO_ROOT/docs/rubric.md" "$1/docs/"
}
EOF
}

@test "tree mode: base + fixture tree in a temp repo, REQUEST.md goes to the prompt" {
  make_tree_skill demo
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  call="$(cat "$CALLS/0")"
  [[ "$call" == *"FILES: ./docs/rubric.md ./skills/target/SKILL.md "* ]]
  [[ "$call" == *"Evaluate in ."* ]]
  [[ "$call" == *"Please evaluate the target skill."* ]]
  [[ "$call" != *"SECRET VERDICTS"* ]]
  [[ "$call" != *"CWD: $TEST_TMPDIR/test"* ]]
  [ -s "$TEST_TMPDIR/test/skills/demo/output/tc-3-planted-weakness.report.md" ]
}

@test "tree mode: the fixture directory's name never reaches the model" {
  make_tree_skill demo
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [[ "$(cat "$CALLS/0")" != *"planted-weakness"* ]]
}

@test "tree mode: .fixture-* markers steer fixture_base and are removed" {
  make_tree_skill demo
  touch "$TEST_TMPDIR/test/skills/demo/fixtures/tc-3-planted-weakness/.fixture-no-base"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  call="$(cat "$CALLS/0")"
  [[ "$call" == *"FILES: ./skills/target/SKILL.md "* ]]
  [[ "$call" != *"fixture-no-base"* ]]
}

@test "tree mode takes directories only; repo mode takes files only" {
  make_tree_skill demo
  echo stray > "$TEST_TMPDIR/test/skills/demo/fixtures/tc-9-stray.md"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [ "$(ls "$CALLS" | wc -l)" -eq 1 ]

  rm -rf "${CALLS:?}"/*
  make_skill other repo "Read"
  mkdir "$TEST_TMPDIR/test/skills/other/fixtures/tc-5-a-dir"
  run bash "$GEN" other
  [ "$status" -eq 0 ]
  [ "$(ls "$CALLS" | wc -l)" -eq 1 ]
}

@test "fixture prefix selects a subset" {
  make_skill demo inline "WebSearch"
  echo other > "$TEST_TMPDIR/test/skills/demo/fixtures/tc-2-other.txt"
  run bash "$GEN" demo tc-2
  [ "$status" -eq 0 ]
  [ "$(ls "$CALLS" | wc -l)" -eq 1 ]
  [ -f "$TEST_TMPDIR/test/skills/demo/output/tc-2-other.txt.report.md" ]
  [ ! -f "$TEST_TMPDIR/test/skills/demo/output/tc-1-thing.txt.report.md" ]
}

@test "a skill without runner.bash is refused before claude runs" {
  make_skill demo inline "WebSearch"
  rm "$TEST_TMPDIR/test/skills/demo/runner.bash"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"no runner"* ]]
  [ "$(ls "$CALLS" | wc -l)" -eq 0 ]
}

@test "a runner naming any tool outside the allowlist is refused" {
  # Every spelling the old Write/Edit denylist let through (FC 21, 2026-09-24),
  # plus Edit, which it refused, and malformed lists.
  local tools
  for tools in "Read,Write" "Read, Write" "Write(*)" "write" "Edit" "MultiEdit" \
      "NotebookEdit" "Bash" "Read,Bash(git:*)" "Read," ",Read" "Read,,Grep" $'Read\nBash'; do
    rm -rf "${CALLS:?}"/* "$TEST_TMPDIR/test/skills/demo" "$TEST_TMPDIR/skills/demo"
    make_skill demo repo "$tools"
    run bash "$GEN" demo
    [ "$status" -ne 0 ] || { echo "accepted: $tools"; return 1; }
    [[ "$output" == *"FIXTURE_TOOLS may only name"* ]] || { echo "$tools: $output"; return 1; }
    [ "$(ls "$CALLS" | wc -l)" -eq 0 ]
  done
}

@test "an inline runner granting a file tool is refused" {
  local tool
  for tool in Read Grep Glob; do
    rm -rf "${CALLS:?}"/* "$TEST_TMPDIR/test/skills/demo" "$TEST_TMPDIR/skills/demo"
    make_skill demo inline "$tool"
    run bash "$GEN" demo
    [ "$status" -ne 0 ] || { echo "accepted inline $tool"; return 1; }
    [[ "$output" == *"inline mode must not grant file tools"* ]]
  done
}

@test "a descriptive suffix is not kept as the subject's extension" {
  make_skill demo repo "Read"
  mv "$TEST_TMPDIR/test/skills/demo/fixtures/tc-1-thing.txt" \
    "$TEST_TMPDIR/test/skills/demo/fixtures/tc-3-login.vuln"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [[ "$(cat "$CALLS/0")" == *"Review subject please"* ]]
  [[ "$(cat "$CALLS/0")" != *"vuln"* ]]
}

@test "a dotted fixture name with no plain extension reaches the model as 'subject'" {
  make_skill demo repo "Read"
  mv "$TEST_TMPDIR/test/skills/demo/fixtures/tc-1-thing.txt" \
    "$TEST_TMPDIR/test/skills/demo/fixtures/tc-2.4-inaccurate"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  call="$(cat "$CALLS/0")"
  [[ "$call" == *"Review subject please"* ]]
  [[ "$call" != *"inaccurate"* ]]
}

@test "a failed claude run leaves no stale report behind, and a .failed marker" {
  make_skill demo repo "Read"
  local out="$TEST_TMPDIR/test/skills/demo/output"
  mkdir -p "$out"
  echo "# Old report from a previous run" > "$out/tc-1-thing.txt.report.md"
  # A failed run that still prints text, like an auth error.
  printf '#!/usr/bin/env bash\necho "Not logged in"\nexit 1\n' > "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"FAILED: claude exited 1"* ]]
  run grep -q "Old report" "$out/tc-1-thing.txt.report.md"
  [ "$status" -ne 0 ]
  grep -q "claude exited 1" "$out/tc-1-thing.txt.failed"
}

@test "a run that aborts before claude starts still removes the previous report" {
  # The case the up-front rm -f exists for: when claude runs, its output
  # redirect would truncate the report anyway.
  make_tree_skill demo
  echo 'fixture_base() { return 1; }' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  local out="$TEST_TMPDIR/test/skills/demo/output"
  mkdir -p "$out"
  echo "# Old report" > "$out/tc-3-planted-weakness.report.md"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [ "$(ls "$CALLS" | wc -l)" -eq 0 ]
  [ ! -e "$out/tc-3-planted-weakness.report.md" ]
}

@test "a successful run clears a previous run's .failed marker" {
  make_skill demo repo "Read"
  local out="$TEST_TMPDIR/test/skills/demo/output"
  mkdir -p "$out"
  echo "claude exited 1" > "$out/tc-1-thing.txt.failed"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [ ! -e "$out/tc-1-thing.txt.failed" ]
}

# --- Provenance stamps (audit 2026-09-26 Batch G, T3) ---

@test "a successful run writes a stamp that check_report_stamp accepts" {
  make_skill demo repo "Read"
  local out="$TEST_TMPDIR/test/skills/demo/output"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [ -s "$out/tc-1-thing.txt.stamp" ]
  source "$TEST_TMPDIR/test/skills/runner-contract.bash"
  [ "$(cat "$out/tc-1-thing.txt.stamp")" = "$(report_stamp "$TEST_TMPDIR/test/skills" demo tc-1-thing.txt)" ]
  # fd 3 closed so a harness warning, if any, lands in $output.
  run check_report_stamp "$TEST_TMPDIR/test/skills" demo tc-1-thing.txt 3>&-
  [ "$status" -eq 0 ]
  [[ "$output" != *WARNING* ]]
  # The format line, then one "<input> <sha256>" line for each of the skill's
  # three own inputs and the informational harness hash (Q-071 [1]).
  [ "$(head -1 "$out/tc-1-thing.txt.stamp")" = "format 2" ]
  [ "$(tail -n +2 "$out/tc-1-thing.txt.stamp" | cut -d' ' -f1 | tr '\n' ' ')" = "skill runner fixture harness " ]
  ! tail -n +2 "$out/tc-1-thing.txt.stamp" | grep -vqE '^[a-z]+ [0-9a-f]{64}$'
}

@test "a failed run writes no stamp and removes the previous one" {
  make_skill demo repo "Read"
  local out="$TEST_TMPDIR/test/skills/demo/output"
  mkdir -p "$out"
  echo "skill old" > "$out/tc-1-thing.txt.stamp"
  printf '#!/usr/bin/env bash\necho "Not logged in"\nexit 1\n' > "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [ -f "$out/tc-1-thing.txt.failed" ]
  [ ! -e "$out/tc-1-thing.txt.stamp" ]
}

@test "the stamp is taken before the run: a SKILL.md edited during it leaves the report stale" {
  make_skill demo repo "Read"
  cat > "$TEST_TMPDIR/bin/claude" <<EOF2
#!/usr/bin/env bash
cat >/dev/null
echo "# edited mid-run" >> "$TEST_TMPDIR/skills/demo/SKILL.md"
printf '# Report\n'
EOF2
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  source "$TEST_TMPDIR/test/skills/runner-contract.bash"
  run check_report_stamp "$TEST_TMPDIR/test/skills" demo tc-1-thing.txt
  [ "$status" -ne 0 ]
  [[ "$output" == *"changed since generation: skill. "* ]]
}

@test "FIXTURE_TRANSCRIPT=1: an error or missing result event is recorded as a failure" {
  make_skill demo inline "Agent"
  echo 'FIXTURE_TRANSCRIPT=1' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  local out="$TEST_TMPDIR/test/skills/demo/output"
  printf '#!/usr/bin/env bash\ncat >/dev/null\n%s\n' \
    "echo '{\"type\":\"result\",\"is_error\":true,\"result\":\"Not logged in\"}'" \
    > "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  grep -q "the result event is an error" "$out/tc-1-thing.txt.failed"
  printf '#!/usr/bin/env bash\ncat >/dev/null\necho %s\n' "'{\"type\":\"system\"}'" \
    > "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  grep -q "no result event" "$out/tc-1-thing.txt.failed"
}

@test "a runner with an unknown mode is refused" {
  make_skill demo sideways "Read"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"FIXTURE_MODE"* ]]
}

@test "every committed fixture set has a runner the generator accepts" {
  # A fixture set nothing can generate reports for is dead weight: it counts
  # toward health-check coverage while no eval can ever run against it. Each
  # runner is sourced and checked against the same contract the generator
  # applies, so a bad runner fails here rather than on a paid run.
  local bad=()
  for dir in "$REPO_ROOT"/test/skills/*/fixtures/; do
    local skill_dir="${dir%/fixtures/}" skill
    skill="$(basename "$skill_dir")"
    if [ ! -f "$skill_dir/runner.bash" ]; then
      bad+=("$skill: no runner.bash")
      continue
    fi
    # shellcheck disable=SC2034  # REPO_ROOT is read by the sourced runner
    if ! msg=$( (
      REPO_ROOT="$REPO_ROOT"
      source "$REPO_ROOT/test/skills/runner-contract.bash"
      reset_runner_settings
      source "$skill_dir/runner.bash"
      check_runner_settings "$skill" 2>&1
    ) 2>&1 ); then
      bad+=("$skill: $msg")
    fi
  done
  [ "${#bad[@]}" -eq 0 ] || { printf '%s\n' "${bad[@]}"; return 1; }
}

@test "every committed fixture set has an eval suite" {
  local missing=()
  for dir in "$REPO_ROOT"/test/skills/*/fixtures/; do
    local skill
    skill="$(basename "${dir%/fixtures/}")"
    [ -f "$REPO_ROOT/test/skills/${skill}-eval.bats" ] || missing+=("$skill")
  done
  [ "${#missing[@]}" -eq 0 ] || { echo "no <skill>-eval.bats: ${missing[*]}"; return 1; }
}

# --- FIXTURE_BASH=deny-record (Q-063 [1]) ---

# make_deny_skill: an inline skill granting Bash under deny-record.
make_deny_skill() {
  make_skill demo inline "Bash"
  printf 'FIXTURE_TRANSCRIPT=1\nFIXTURE_BASH=deny-record\n' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
}

# stub_stream <denials JSON> [<init tools JSON>]: a claude stub whose stream
# holds an init event (tools default ["Bash"]), one Bash call (id b1) and a
# result event with the given permission_denials.
stub_stream() {
  cat > "$TEST_TMPDIR/bin/claude" <<EOF2
#!/usr/bin/env bash
cat >/dev/null
echo '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":${2:-[\"Bash\"]}}'
echo '{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"b1","name":"Bash","input":{"command":"echo hi"}}]}}'
echo '{"type":"result","subtype":"success","result":"# Report","permission_denials":$1}'
EOF2
  chmod +x "$TEST_TMPDIR/bin/claude"
}

@test "deny-record: Bash is accepted and every call is pinned to be denied" {
  # dontAsk alone still ran read-only commands (pwd, ls, echo; probed
  # 2026-09-25), so the Bash(**) deny rule is the part that denies everything.
  make_deny_skill
  run bash "$GEN" demo
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$(cat "$CALLS/0")" == *"--tools Bash --disallowedTools Bash(**) --permission-mode dontAsk --permission-prompts none"* ]]
}

@test "deny-record needs FIXTURE_TRANSCRIPT=1 and FIXTURE_TOOLS=Bash exactly; other values are refused" {
  make_skill demo inline "Bash"
  echo 'FIXTURE_BASH=deny-record' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"needs FIXTURE_TRANSCRIPT=1"* ]]
  rm -rf "$TEST_TMPDIR/test/skills/demo"
  make_skill demo inline "WebSearch"
  printf 'FIXTURE_TRANSCRIPT=1\nFIXTURE_BASH=deny-record\n' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"needs FIXTURE_TOOLS=Bash exactly"* ]]
  # Bash alongside another tool is refused too: dontAsk applies to every tool,
  # and only Bash's denial is probed and tripwired.
  rm -rf "$TEST_TMPDIR/test/skills/demo"
  make_skill demo inline "Bash,WebSearch"
  printf 'FIXTURE_TRANSCRIPT=1\nFIXTURE_BASH=deny-record\n' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"needs FIXTURE_TOOLS=Bash exactly"* ]]
  rm -rf "$TEST_TMPDIR/test/skills/demo"
  make_skill demo inline "Bash"
  printf 'FIXTURE_TRANSCRIPT=1\nFIXTURE_BASH=deny_record\n' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  # A misspelled value is reported as itself, not as a FIXTURE_TOOLS error.
  [[ "$output" == *"FIXTURE_BASH must be empty or deny-record, got 'deny_record'"* ]]
  rm -rf "$TEST_TMPDIR/test/skills/demo"
  make_skill demo inline "WebSearch"
  printf 'FIXTURE_TRANSCRIPT=1\nFIXTURE_BASH=allow\n' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"FIXTURE_BASH must be"* ]]
  [ "$(ls "$CALLS" | wc -l)" -eq 0 ]
}

@test "deny-record does not open Bash(<pattern>) spellings, and says what it needs" {
  local tools
  for tools in "Bash(python3:*)" "Bash(**)"; do
    rm -rf "$TEST_TMPDIR/test/skills/demo"
    make_skill demo inline "$tools"
    printf 'FIXTURE_TRANSCRIPT=1\nFIXTURE_BASH=deny-record\n' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
    run bash "$GEN" demo
    [ "$status" -ne 0 ] || { echo "accepted: $tools"; return 1; }
    [[ "$output" == *"needs FIXTURE_TOOLS=Bash exactly"* ]] || { echo "$tools: $output"; return 1; }
  done
  [ "$(ls "$CALLS" | wc -l)" -eq 0 ]
}

@test "deny-record refuses any CLAUDE_FLAGS before claude runs; blank is fine" {
  # A denylist of flag names could not hold (--setting-sources, a repeated
  # --tools, --mcp-config ... were accepted; review iteration 2, C16).
  make_deny_skill
  local f
  for f in "--permission-mode bypassPermissions" "--allowedTools Bash" "--setting-sources user" \
      "--tools Bash,Read" "--mcp-config x.json" "--add-dir /" "--model m" $'\t--verbose'; do
    CLAUDE_FLAGS="$f" run bash "$GEN" demo
    [ "$status" -ne 0 ] || { echo "accepted: $f"; return 1; }
    [[ "$output" == *"refuses CLAUDE_FLAGS"* ]]
  done
  [ "$(ls "$CALLS" | wc -l)" -eq 0 ]
  CLAUDE_FLAGS=$' \t' run bash "$GEN" demo
  [ "$status" -eq 0 ]
}

@test "CLAUDE_MODEL reaches claude as one argument, so it cannot smuggle flags" {
  make_deny_skill
  CLAUDE_MODEL="m" run bash "$GEN" demo
  [ "$status" -eq 0 ]
  local base
  base=$(sed -n 's/^ARGC: //p' "$CALLS/0")
  rm -rf "${CALLS:?}"/*
  CLAUDE_MODEL="m --permission-mode bypassPermissions" run bash "$GEN" demo
  [ "$status" -eq 0 ]
  # Same argument count: the whole value is the --model argument.
  [ "$(sed -n 's/^ARGC: //p' "$CALLS/0")" -eq "$base" ]
}

@test "deny-record canary: a run whose init event does not list Bash is voided, naming the CLI version" {
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output"
  stub_stream '[{"tool_name":"Bash","tool_use_id":"b1","tool_input":{}}]' '[]'
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  grep -q "Bash init canary: an init event.s tools are \[\], not exactly \[\"Bash\"\] (CLI 9.9.9)" "$out/tc-1-thing.txt.failed"
}

@test "deny-record tripwire: a Bash call missing from permission_denials voids the run" {
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output"
  stub_stream '[]'
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  grep -q "Bash tripwire: 1 call(s) not in permission_denials (may have executed)" "$out/tc-1-thing.txt.failed"
  stub_stream '[{"tool_name":"Bash","tool_use_id":"b1","tool_input":{}}]'
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [ ! -e "$out/tc-1-thing.txt.failed" ]
}

@test "deny-record tripwire still runs when the run already failed, and says so" {
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output"
  # A Bash call, then an error result with no denials: both causes are recorded.
  cat > "$TEST_TMPDIR/bin/claude" <<'EOF2'
#!/usr/bin/env bash
cat >/dev/null
echo '{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"b1","name":"Bash","input":{"command":"pwd"}}]}}'
echo '{"type":"result","is_error":true,"result":"boom","permission_denials":[]}'
EOF2
  chmod +x "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  grep -q "^the result event is an error; " "$out/tc-1-thing.txt.failed"
  grep -q "Bash tripwire: 1 call(s) not in permission_denials (may have executed)" "$out/tc-1-thing.txt.failed"
}


@test "deny-record: a tool_use moved to a field the reader does not know voids the run as malformed" {
  # A CLI event-shape change could hide tool_use blocks from every check. The
  # strict reader (transcript.jq) rejects the unknown shape outright (review
  # iteration 4, R2/A21; formerly caught only by the parser canary, A16).
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output"
  cat > "$TEST_TMPDIR/bin/claude" <<'EOF2'
#!/usr/bin/env bash
cat >/dev/null
echo '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
echo '{"type":"assistant","message":{"blocks":[{"type":"tool_use","id":"tu1","name":"Bash","input":{"command":"pwd"}}]}}'
echo '{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"tu1","tool_input":{}}]}'
EOF2
  chmod +x "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  grep -q "assistant event: message.content is not an array" "$out/tc-1-thing.txt.failed"
}

@test "deny-record: a run with no init event is reported as not started, not blamed on the deny rule" {
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output"
  printf '#!/usr/bin/env bash\ncat >/dev/null\necho %s\nexit 1\n' \
    "'{\"type\":\"result\",\"is_error\":true,\"result\":\"Not logged in\"}'" > "$TEST_TMPDIR/bin/claude"
  chmod +x "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  grep -q "no init event in the stream (the run did not start?)" "$out/tc-1-thing.txt.failed"
  # No init event means no tools to check: the init canary must not also fire.
  ! grep -q "Bash init canary" "$out/tc-1-thing.txt.failed"
}

@test "deny-record: a Bash tool_use with no id is malformed, and voids the run" {
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output"
  cat > "$TEST_TMPDIR/bin/claude" <<'EOF2'
#!/usr/bin/env bash
cat >/dev/null
echo '{"type":"system","subtype":"init","tools":["Bash"]}'
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"pwd"}}]}}'
echo '{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_input":{}}]}'
EOF2
  chmod +x "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  grep -q "a tool_use has no string id and name" "$out/tc-1-thing.txt.failed"
}

# --- Iteration-4 structural fix: one strict reader, fail-closed marker ---

# stub_transcript <file>: a claude stub that prints <file> as its stream.
stub_transcript() {
  printf '#!/usr/bin/env bash\ncat >/dev/null\ncat %q\n' "$1" > "$TEST_TMPDIR/bin/claude"
  chmod +x "$TEST_TMPDIR/bin/claude"
}

@test "deny-record: every malformed transcript shape voids the run, even beside a good denied call" {
  source "$REPO_ROOT/test/skills/malformed-transcripts.bash"
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output" shape
  write_malformed_transcripts "$TEST_TMPDIR/bad" "echo good"
  # Control: without the bad line the run passes.
  grep -v '^123$' "$TEST_TMPDIR/bad/number_line.jsonl" > "$TEST_TMPDIR/good.jsonl"
  stub_transcript "$TEST_TMPDIR/good.jsonl"
  run bash "$GEN" demo
  [ ! -e "$out/tc-1-thing.txt.failed" ] || { echo "control voided: $(cat "$out/tc-1-thing.txt.failed")"; return 1; }
  for shape in "${MALFORMED_SHAPES[@]}"; do
    stub_transcript "$TEST_TMPDIR/bad/$shape.jsonl"
    run bash "$GEN" demo
    [ -e "$out/tc-1-thing.txt.failed" ] || { echo "not voided: $shape"; return 1; }
    # Voided by the checks, not merely left at the in-progress marker.
    ! grep -q "generation did not finish" "$out/tc-1-thing.txt.failed" || { echo "$shape: marker only"; return 1; }
  done
}

@test "deny-record parser canaries: an orphan tool_result, or a denial of another tool, voids the run" {
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output" t="$TEST_TMPDIR/t.jsonl"
  local init='{"type":"system","subtype":"init","tools":["Bash"]}'
  # A tool_result answering a call the reader never saw: a call that ran unseen (A22).
  printf '%s\n' "$init" \
    '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"ghost","content":"/tmp"}]}}' \
    '{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}' > "$t"
  stub_transcript "$t"
  run bash "$GEN" demo
  grep -q "Bash parser canary: 1 tool_result(s) answer a tool_use not in the census" "$out/tc-1-thing.txt.failed"
  printf '%s\n' "$init" \
    '{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Read","tool_use_id":"r9"}]}' > "$t"
  stub_transcript "$t"
  run bash "$GEN" demo
  grep -q "Bash-only: 1 denial(s) of a tool other than Bash" "$out/tc-1-thing.txt.failed"
}

@test "the .failed marker exists while a run is in progress and is removed only after every check passes" {
  # Fail-closed (review iteration 4, A23): a generator interrupted between
  # writing the report and checking the transcript must leave a marker.
  make_skill demo inline "Agent"
  echo 'FIXTURE_TRANSCRIPT=1' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  local out="$TEST_TMPDIR/test/skills/demo/output"
  cat > "$TEST_TMPDIR/bin/claude" <<EOF2
#!/usr/bin/env bash
cat >/dev/null
cat "$out/tc-1-thing.txt.failed" > "$TEST_TMPDIR/marker-during-run" 2>/dev/null || echo ABSENT > "$TEST_TMPDIR/marker-during-run"
echo '{"type":"system","subtype":"init","tools":["Agent"]}'
echo '{"type":"result","subtype":"success","result":"# Report"}'
EOF2
  chmod +x "$TEST_TMPDIR/bin/claude"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  grep -q "generation did not finish" "$TEST_TMPDIR/marker-during-run"
  [ ! -e "$out/tc-1-thing.txt.failed" ]
  [ -s "$out/tc-1-thing.txt.report.md" ]
}

@test "any transcript run (not only deny-record) is voided by a malformed event or a missing init" {
  make_skill demo inline "Agent"
  echo 'FIXTURE_TRANSCRIPT=1' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  local out="$TEST_TMPDIR/test/skills/demo/output" t="$TEST_TMPDIR/t.jsonl"
  printf '%s\n' '{"type":"result","subtype":"success","result":"# Report"}' > "$t"
  stub_transcript "$t"
  run bash "$GEN" demo
  grep -q "no init event in the stream" "$out/tc-1-thing.txt.failed"
  printf '%s\n' '{"type":"system","subtype":"init","tools":["Agent"]}' '[1]' \
    '{"type":"result","subtype":"success","result":"# Report"}' > "$t"
  stub_transcript "$t"
  run bash "$GEN" demo
  grep -q "a line is not a JSON object" "$out/tc-1-thing.txt.failed"
}

# --- Iteration-5 fix: census, verdict in one place, sentinel (R3, R4, A28) ---

@test "property, end to end: an undenied Bash call inserted at any position voids the deny-record run" {
  source "$REPO_ROOT/test/skills/malformed-transcripts.bash"
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output" good="$TEST_TMPDIR/good.jsonl" n f escapes=0
  printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}' \
    '{"type":"assistant","message":{"content":[{"type":"text","text":"x"},{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"echo good"}}]}}' \
    '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"g1","content":"denied","is_error":true}]}}' \
    '{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1","tool_input":{}}]}' > "$good"
  stub_transcript "$good"
  run bash "$GEN" demo
  [ ! -e "$out/tc-1-thing.txt.failed" ] || { echo "control voided: $(cat "$out/tc-1-thing.txt.failed")"; return 1; }
  n="$(write_insertion_variants "$good" "$TEST_TMPDIR/ins")"
  [ "$n" -ge 10 ]
  for f in "$TEST_TMPDIR"/ins/v*.jsonl; do
    stub_transcript "$f"
    run bash "$GEN" demo
    if [ ! -e "$out/tc-1-thing.txt.failed" ] || grep -q "generation did not finish" "$out/tc-1-thing.txt.failed"; then
      escapes=$((escapes + 1)); echo "not voided by a check: $(basename "$f")"
    fi
  done
  echo "variants=$n escapes=$escapes"
  [ "$escapes" -eq 0 ]
}

@test "a newline in a verdict field cannot cut the verdict short: the run is still voided (R4)" {
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output" t="$TEST_TMPDIR/t.jsonl"
  printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"2.1\nX\n","tools":["Bash"]}' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"u1","name":"Bash","input":{"command":"pwd"}}]}}' \
    '{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}' > "$t"
  stub_transcript "$t"
  run bash "$GEN" demo
  grep -q "Bash tripwire: 1 call(s) not in permission_denials" "$out/tc-1-thing.txt.failed"
}

@test "deny-record: the granted tools must be exactly [Bash], and every call a Bash call (A28)" {
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output" t="$TEST_TMPDIR/t.jsonl"
  printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash","BashOutput"]}' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"o1","name":"BashOutput","input":{"bash_id":"1"}}]}}' \
    '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"o1","content":"ran"}]}}' \
    '{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}' > "$t"
  stub_transcript "$t"
  run bash "$GEN" demo
  grep -q 'Bash init canary: an init event.s tools are \["Bash","BashOutput"\]' "$out/tc-1-thing.txt.failed"
  grep -q "Bash-only: 1 call(s) of a tool other than Bash" "$out/tc-1-thing.txt.failed"
}

@test "a verdict that did not finish (no sentinel line) voids the run" {
  # Simulate jq dying mid-verdict: a jq wrapper that drops the sentinel line.
  make_deny_skill
  local out="$TEST_TMPDIR/test/skills/demo/output" t="$TEST_TMPDIR/t.jsonl" realjq
  realjq="$(command -v jq)"
  printf '%s\n' '{"type":"system","subtype":"init","tools":["Bash"]}' \
    '{"type":"result","subtype":"success","result":"# Report","permission_denials":[]}' > "$t"
  stub_transcript "$t"
  printf '#!/usr/bin/env bash\n"%s" "$@" | grep -v __VERDICT_COMPLETE__\nexit 0\n' "$realjq" > "$TEST_TMPDIR/bin/jq"
  chmod +x "$TEST_TMPDIR/bin/jq"
  run bash "$GEN" demo
  rm -f "$TEST_TMPDIR/bin/jq"
  grep -q "transcript: could not be read in full, so no check could complete" "$out/tc-1-thing.txt.failed"
}
