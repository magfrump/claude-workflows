#!/usr/bin/env bats
# @category fast
# Tests that test/skills/generate-reports.bash grants, not only offers, the web
# tools a runner lists (finding F1 of the 2026-11-19 regeneration: --tools alone
# left every WebSearch/WebFetch call denied, so fact-check reports were all
# Unverified). Runs in a copy of the repo layout under a temp dir, against a
# claude stub that parses its argv the way the real CLI does and refuses what it
# would not accept, so no report is written into test/skills/*/output/.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup() {
  TEST_TMPDIR=$(mktemp -d)
  mkdir -p "$TEST_TMPDIR/test/skills" "$TEST_TMPDIR/bin"
  cp "$REPO_ROOT/test/skills/generate-reports.bash" "$REPO_ROOT/test/skills/runner-contract.bash" \
    "$REPO_ROOT/test/skills/transcript.jq" "$TEST_TMPDIR/test/skills/"
  GEN="$TEST_TMPDIR/test/skills/generate-reports.bash"
  unset CLAUDE_MODEL CLAUDE_FLAGS
  cd "$TEST_TMPDIR" || return 1
  CALLS="$TEST_TMPDIR/calls"
  mkdir -p "$CALLS"

  # A strict stub: every flag the generator may pass, with its arity; an
  # unknown flag, a missing value, --bare (which drops subscription auth) or a
  # stray positional argument exits 2, as a real CLI usage error would.
  # --allowedTools and --disallowedTools are variadic in the real CLI, so the
  # stub, like it, takes every following non-flag argument as more tool names,
  # and records each value it took on its own GRANT line.
  cat > "$TEST_TMPDIR/bin/claude" <<'EOF'
#!/usr/bin/env bash
calls="$STUB_CALLS"
n=$(ls "$calls" | wc -l)
rec="$calls/$n"
: > "$rec"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -p|--strict-mcp-config|--restricted|--safe-mode|--verbose) shift ;;
    --system-prompt-file|--output-format|--model|--permission-mode|--permission-prompts)
      [ "$#" -ge 2 ] || { echo "error: $1 needs a value" >&2; exit 2; }
      shift 2 ;;
    --tools)
      [ "$#" -ge 2 ] || { echo "error: --tools needs a value" >&2; exit 2; }
      printf 'TOOLS: %s\n' "$2" >> "$rec"; shift 2 ;;
    --allowedTools|--disallowedTools)
      flag="$1"; shift
      [ "$#" -ge 1 ] && [[ "$1" != -* ]] || { echo "error: $flag needs a value" >&2; exit 2; }
      while [ "$#" -gt 0 ] && [[ "$1" != -* ]]; do
        [ "$flag" = --allowedTools ] && printf 'GRANT: %s\n' "$1" >> "$rec"
        shift
      done ;;
    --bare) echo "error: --bare drops subscription auth" >&2; exit 2 ;;
    -*) echo "error: unknown option '$1'" >&2; exit 2 ;;
    *) echo "error: unexpected argument '$1'" >&2; exit 2 ;;
  esac
done
cat > /dev/null
printf '# Report\n\n**Severity:** High\n'
EOF
  chmod +x "$TEST_TMPDIR/bin/claude"
  export STUB_CALLS="$CALLS"
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
  cat > "$TEST_TMPDIR/test/skills/$name/runner.bash" <<EOF
FIXTURE_TOOLS="$tools"
FIXTURE_MODE="$mode"
fixture_prompt() { printf 'Review %s please' "\$1"; }
EOF
}

# grants — the GRANT lines of the one recorded call, one value per line.
grants() {
  sed -n 's/^GRANT: //p' "$CALLS/0"
}

@test "the real fact-check runner's web tools are granted, as one argv element" {
  mkdir -p "$TEST_TMPDIR/skills/fact-check" "$TEST_TMPDIR/test/skills/fact-check/fixtures"
  echo "# fact-check skill" > "$TEST_TMPDIR/skills/fact-check/SKILL.md"
  echo "A claim." > "$TEST_TMPDIR/test/skills/fact-check/fixtures/tc-1-claim.md"
  cp "$REPO_ROOT/test/skills/fact-check/runner.bash" "$TEST_TMPDIR/test/skills/fact-check/"
  run bash "$GEN" fact-check
  echo "$output"
  [ "$status" -eq 0 ]
  [ -s "$TEST_TMPDIR/test/skills/fact-check/output/tc-1-claim.md.report.md" ]
  [ "$(grants)" = "WebSearch,WebFetch" ]
  [ "$(sed -n 's/^TOOLS: //p' "$CALLS/0")" = "WebSearch,WebFetch" ]
}

@test "a runner with no web tool gets no grant" {
  local spec mode tools
  for spec in "repo Read,Grep,Glob" "inline Agent" "inline none"; do
    mode="${spec%% *}" tools="${spec#* }"
    rm -rf "${CALLS:?}"/* "$TEST_TMPDIR/test/skills/demo" "$TEST_TMPDIR/skills/demo"
    make_skill demo "$mode" "$tools"
    run bash "$GEN" demo
    [ "$status" -eq 0 ] || { echo "$tools: $output"; return 1; }
    [ -z "$(grants)" ] || { echo "$tools granted: $(grants)"; return 1; }
  done
}

@test "the grant names only the runner's web tools, never another tool it lists" {
  local spec mode tools want
  for spec in "inline WebFetch,Agent WebFetch" "repo Read,WebSearch,Glob WebSearch" \
      "inline WebSearch WebSearch"; do
    read -r mode tools want <<< "$spec"
    rm -rf "${CALLS:?}"/* "$TEST_TMPDIR/test/skills/demo" "$TEST_TMPDIR/skills/demo"
    make_skill demo "$mode" "$tools"
    run bash "$GEN" demo
    [ "$status" -eq 0 ] || { echo "$tools: $output"; return 1; }
    [ "$(grants)" = "$want" ] || { echo "$tools granted '$(grants)', want '$want'"; return 1; }
  done
}

@test "the grant does not swallow the model argument that follows it" {
  make_skill demo inline "WebSearch,WebFetch"
  CLAUDE_MODEL="m" run bash "$GEN" demo
  [ "$status" -eq 0 ]
  [ "$(grants)" = "WebSearch,WebFetch" ]
}

@test "deny-record runs get no grant and keep their Bash deny" {
  make_skill demo inline "Bash"
  printf 'FIXTURE_TRANSCRIPT=1\nFIXTURE_BASH=deny-record\n' >> "$TEST_TMPDIR/test/skills/demo/runner.bash"
  run bash "$GEN" demo
  # The stub prints no stream, so the run is voided; only the argv matters here.
  [ -z "$(grants)" ]
  [ "$(sed -n 's/^TOOLS: //p' "$CALLS/0")" = "Bash" ]
}
