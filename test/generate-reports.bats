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
    "$TEST_TMPDIR/test/skills/"
  GEN="$TEST_TMPDIR/test/skills/generate-reports.bash"
  # The caller's environment must not reach the argv under test, and the stub
  # lists its working directory, which must not be the repo root (395k files
  # there made this suite ~14 s).
  unset CLAUDE_MODEL CLAUDE_FLAGS
  cd "$TEST_TMPDIR"

  # The stub records its argv, working directory and stdin, then prints a
  # one-finding report so the generator's "Done" path runs.
  CALLS="$TEST_TMPDIR/calls"
  mkdir -p "$CALLS"
  cat > "$TEST_TMPDIR/bin/claude" <<EOF
#!/usr/bin/env bash
n=\$(ls "$CALLS" | wc -l)
{ printf 'ARGS: %s\n' "\$*"; printf 'CWD: %s\n' "\$PWD"; printf 'LS: %s\n' "\$(ls)"
  printf 'FILES: %s\n' "\$(find . -path ./.git -prune -o -type f -print | sort | tr '\n' ' ')"
  echo 'STDIN:'; cat; } > "$CALLS/\$n"
if [[ " \$* " == *" --output-format stream-json "* ]]; then
  # The shape of a real stream-json run: init, one tool call, the result.
  echo '{"type":"system","subtype":"init"}'
  echo '{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"x"}}]}}'
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
  # Every spelling the old Write/Edit denylist let through (FC 21, 2026-09-24).
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

@test "a successful run clears a previous run's .failed marker" {
  make_skill demo repo "Read"
  local out="$TEST_TMPDIR/test/skills/demo/output"
  mkdir -p "$out"
  echo "claude exited 1" > "$out/tc-1-thing.txt.failed"
  run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [ ! -e "$out/tc-1-thing.txt.failed" ]
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
