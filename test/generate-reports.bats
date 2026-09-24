#!/usr/bin/env bats
# @category fast
# Tests test/skills/generate-reports.bash's per-skill runner contract against a
# stubbed claude, in a copy of the repo layout under a temp dir so no report is
# ever written into the real test/skills/*/output/.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup() {
  TEST_TMPDIR=$(mktemp -d)
  mkdir -p "$TEST_TMPDIR/test/skills" "$TEST_TMPDIR/bin"
  cp "$REPO_ROOT/test/skills/generate-reports.bash" "$TEST_TMPDIR/test/skills/"
  GEN="$TEST_TMPDIR/test/skills/generate-reports.bash"

  # The stub records its argv, working directory and stdin, then prints a
  # one-finding report so the generator's "Done" path runs.
  CALLS="$TEST_TMPDIR/calls"
  mkdir -p "$CALLS"
  cat > "$TEST_TMPDIR/bin/claude" <<EOF
#!/usr/bin/env bash
n=\$(ls "$CALLS" | wc -l)
{ printf 'ARGS: %s\n' "\$*"; printf 'CWD: %s\n' "\$PWD"; printf 'LS: %s\n' "\$(ls)"; echo 'STDIN:'; cat; } > "$CALLS/\$n"
printf '# Report\n\n**Severity:** High\n'
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
  [[ "$output" == *"1 severity-tagged findings"* ]]
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

@test "a runner granting Write is refused" {
  make_skill demo repo "Read,Write"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"must not include Write"* ]]
  [ "$(ls "$CALLS" | wc -l)" -eq 0 ]
}

@test "a runner with an unknown mode is refused" {
  make_skill demo sideways "Read"
  run bash "$GEN" demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"FIXTURE_MODE"* ]]
}

@test "every committed fixture set has a runner the generator accepts" {
  # A fixture set nothing can generate reports for is dead weight: it counts
  # toward health-check coverage while no eval can ever run against it.
  local missing=()
  for dir in "$REPO_ROOT"/test/skills/*/fixtures/; do
    local skill_dir="${dir%/fixtures/}"
    [ -f "$skill_dir/runner.bash" ] || missing+=("$(basename "$skill_dir")")
  done
  [ "${#missing[@]}" -eq 0 ] || { echo "no runner.bash: ${missing[*]}"; return 1; }
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
