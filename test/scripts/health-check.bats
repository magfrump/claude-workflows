#!/usr/bin/env bats
# @category slow
# Integration test for scripts/health-check.sh
#
# Runs the health-check script ONCE per file (not per test) and asserts
# against the cached output. Negative tests at the bottom run separately
# since they inject broken fixture files.
#
# Compatibility: uses setup_file/teardown_file (bats-core >=1.2.0).
# On older BATS the functions are silently ignored and the lazy-init
# fallback in setup() runs the script on the first test instead.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/scripts/health-check.sh"

# Recursion guard (Q-023): health-check.sh gate 5 runs every bats suite,
# including this one, so a health-check launched from here must not run gate 5
# again. Exported so every `run bash "$SCRIPT"` below inherits it. Gate 5's own
# ordering is tested further down with a stub runner.
export HEALTH_CHECK_SKIP_BATS=1

# Cache shared across all tests in this file. It must be BATS_FILE_TMPDIR, not
# a path built from $$: bats runs each test in its own process, so `$$` differs
# between setup_file and every test. The old "/tmp/bats-hc-cache.$$" never hit,
# and every test re-ran the full health check (~18s each, ~400s per file).
_HC_CACHE_DIR="$BATS_FILE_TMPDIR/hc-cache"

_run_and_cache() {
  mkdir -p "$_HC_CACHE_DIR"
  run bash "$SCRIPT"
  printf '%s' "$output" > "$_HC_CACHE_DIR/output"
  printf '%s' "$status" > "$_HC_CACHE_DIR/status"
}

setup_file() {
  _run_and_cache
}

teardown_file() {
  rm -rf "$_HC_CACHE_DIR"
}

setup() {
  if [ -f "$_HC_CACHE_DIR/output" ]; then
    HC_OUTPUT=$(cat "$_HC_CACHE_DIR/output")
    HC_STATUS=$(cat "$_HC_CACHE_DIR/status")
  else
    _run_and_cache
    HC_OUTPUT=$(cat "$_HC_CACHE_DIR/output")
    HC_STATUS=$(cat "$_HC_CACHE_DIR/status")
  fi
}

# --- assertions (use cached output) ----------------------------------------

@test "health-check exits 0 on this repo" {
  echo "$HC_OUTPUT"
  [ "$HC_STATUS" -eq 0 ]
}

# Print one section of the cached output: from its "── <name>" header up to the
# next header. The assertions below read a gate's own lines, so one gate's pass
# line cannot satisfy another's test, and a ✗ is attributed to its gate.
_section() {
  printf '%s\n' "$HC_OUTPUT" | awk -v h="── $1" '
    index($0, h) == 1 { on = 1; next }
    /^── / { on = 0 }
    on'
}

# Each test pins a line the gate prints only on its passing branch — a section
# header is printed whatever the outcome, so grepping for one proved nothing —
# and, where the gate can fail, that it printed no ✗ of its own.

@test "gate 1: skill frontmatter checks every skill and flags none" {
  local sec; sec="$(_section "Skill YAML frontmatter")"
  echo "$sec"
  [[ "$sec" =~ ✓\ [0-9]+\ skill\(s\)\ checked ]]
  [[ "$sec" != *"✗"* ]]
}

@test "gate 2: every workflow reference in the three MD files resolves" {
  local sec; sec="$(_section "Workflow cross-references")"
  echo "$sec"
  [[ "$sec" == *"✓ global-instructions/CLAUDE.md: all workflow references resolve"* ]]
  [[ "$sec" == *"✓ AGENTS.md: all workflow references resolve"* ]]
  [[ "$sec" == *"✓ GEMINI.md: all workflow references resolve"* ]]
}

@test "gate 3: the three MD files reference the same workflows" {
  _section "MD file consistency" | grep -qF "✓ All MD files reference the same workflows"
}

@test "gate 4: fixture ↔ expected-verdicts coverage has no gaps" {
  local sec; sec="$(_section "Fixture ↔ expected-verdicts")"
  echo "$sec"
  [[ "$sec" == *"✓ fact-check: all fixtures have verdicts and vice versa"* ]]
  [[ "$sec" != *"✗"* ]]
}

@test "directory (tree-mode) fixture sets pass the fixture ↔ verdict check" {
  # self-eval and divergent-design keep one directory per fixture. The check
  # once tested keys with -f only, so every directory key read as missing.
  echo "$HC_OUTPUT" | grep -q "self-eval: all fixtures have verdicts and vice versa"
  echo "$HC_OUTPUT" | grep -q "divergent-design: all fixtures have verdicts and vice versa"
}

@test "gate 5: the nested run skips the BATS gate (recursion guard) with a warning" {
  _section "BATS tests" | grep -qF "⚠ HEALTH_CHECK_SKIP_BATS=1 — BATS gate skipped"
}

@test "gate 6: shellcheck linted the repo's scripts and flagged none" {
  local sec; sec="$(_section "shellcheck")"
  [[ "$sec" == *"✓ scripts/health-check.sh"* ]]
  [[ "$sec" == *"✓ test/scripts/health-check.bats"* ]]
  [[ "$sec" != *"✗"* ]] || { echo "$sec" | grep '✗'; return 1; }
}

@test "gate 7: workflow value-justification scanned the workflows" {
  _section "Workflow value-justification" | grep -qE '[0-9]+ workflow\(s\) checked'
}

@test "gate 8: every hook script is executable" {
  local sec; sec="$(_section "Hook script permissions")"
  echo "$sec"
  [[ "$sec" == *"✓ log-usage.sh is executable"* ]]
  [[ "$sec" =~ ✓\ [0-9]+\ hook\(s\)\ checked ]]
  [[ "$sec" != *"✗"* ]]
}

@test "output ends with All checks passed" {
  echo "$HC_OUTPUT" | grep -q "All checks passed"
}

# ── Negative tests: broken skill files ──────────────────────────────────────
#
# Hermetic: each test copies the real skills/ into $BATS_TEST_TMPDIR/skills,
# injects its broken fixture there, and points health-check.sh at the copy via
# HEALTH_CHECK_SKILLS_DIR. Nothing is written under the real repo, so an
# interrupted run cannot leave a fixture in skills/ (where every consuming
# project would load it as a skill) and concurrent runs cannot race on it.
# The copy is complete so the only difference from the real tree is the
# fixture, and each assertion greps for the message naming that fixture, so
# the failure is attributable to it alone.

REAL_SKILLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/skills"

# Copy skills/ to an isolated tree and print its path. The basename must stay
# "skills": skill names are derived from the /skills/ path component.
_isolated_skills_dir() {
  local dir="$BATS_TEST_TMPDIR/skills"
  cp -R "$REAL_SKILLS_DIR" "$dir"
  printf '%s' "$dir"
}

@test "detects skill file with no YAML frontmatter" {
  local skills_dir
  skills_dir="$(_isolated_skills_dir)"
  printf '# A skill file with no YAML frontmatter\n\nJust plain markdown.\n' \
    > "$skills_dir/_test_no_frontmatter.md"

  HEALTH_CHECK_SKILLS_DIR="$skills_dir" run bash "$SCRIPT"

  echo "$output"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "_test_no_frontmatter: no YAML frontmatter found"
}

@test "detects skill file with missing description field" {
  local skills_dir
  skills_dir="$(_isolated_skills_dir)"
  printf -- '---\nname: test-broken-skill\n---\n\nBody text.\n' \
    > "$skills_dir/_test_missing_desc.md"

  HEALTH_CHECK_SKILLS_DIR="$skills_dir" run bash "$SCRIPT"

  echo "$output"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "_test_missing_desc: missing 'description' field"
}

# ── Gate 5: fast-then-slow ordering (Q-023) ────────────────────────────────
#
# Sources health-check.sh (main only runs when executed) and calls check_bats
# against a stub runner via the HEALTH_CHECK_RUN_TESTS seam, so these tests
# never run the real suites. The stub logs each invocation's flag and the
# HEALTH_CHECK_SKIP_BATS it saw, and exits with STUB_FAST_RC / STUB_SLOW_RC.

_stub_runner() {
  local stub="$BATS_TEST_TMPDIR/run-tests-stub.sh"
  cat > "$stub" <<'STUB'
#!/usr/bin/env bash
printf '%s skip=%s\n' "$1" "${HEALTH_CHECK_SKIP_BATS:-unset}" >> "$STUB_LOG"
case "$1" in
  --fast) exit "${STUB_FAST_RC:-0}" ;;
  --slow) exit "${STUB_SLOW_RC:-0}" ;;
esac
exit 99
STUB
  chmod +x "$stub"
  printf '%s' "$stub"
}

# Run check_bats with the stub; prints FAIL=<n> last. Gate-5 guard unset here.
_run_check_bats() {
  local stub
  stub="$(_stub_runner)"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"
  : > "$STUB_LOG"
  run env -u HEALTH_CHECK_SKIP_BATS HEALTH_CHECK_RUN_TESTS="$stub" \
    bash -c 'source "$1"; check_bats; echo "FAIL=$FAIL"' _ "$SCRIPT"
}

@test "gate 5: runs fast then slow when both are green" {
  STUB_FAST_RC=0 STUB_SLOW_RC=0 _run_check_bats
  echo "$output"; cat "$STUB_LOG"
  [ "$status" -eq 0 ]
  [[ "$output" == *"FAIL=0"* ]]
  [ "$(cat "$STUB_LOG")" = "$(printf -- '--fast skip=1\n--slow skip=1')" ]
}

@test "gate 5: red fast blocks slow and fails the gate" {
  STUB_FAST_RC=1 STUB_SLOW_RC=0 _run_check_bats
  echo "$output"; cat "$STUB_LOG"
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"slow suites not run"* ]]
  [ "$(cat "$STUB_LOG")" = "--fast skip=1" ]
}

@test "gate 5: red slow after green fast fails the gate" {
  STUB_FAST_RC=0 STUB_SLOW_RC=1 _run_check_bats
  echo "$output"; cat "$STUB_LOG"
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"Slow BATS suites failed"* ]]
  [ "$(wc -l < "$STUB_LOG")" -eq 2 ]
}

@test "gate 5: HEALTH_CHECK_SKIP_BATS=1 skips the runner with a warning, not a pass" {
  local stub
  stub="$(_stub_runner)"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"
  : > "$STUB_LOG"
  run env HEALTH_CHECK_SKIP_BATS=1 HEALTH_CHECK_RUN_TESTS="$stub" \
    bash -c 'source "$1"; check_bats; echo "FAIL=$FAIL"' _ "$SCRIPT"
  echo "$output"
  [[ "$output" == *"FAIL=0"* ]]
  [[ "$output" == *"BATS gate skipped"* ]]
  [[ "$output" != *"passed"* ]]
  [ ! -s "$STUB_LOG" ]
}

# ── Negative tests: one gate at a time against a broken fixture repo ────────
#
# Same seam as gate 5: source health-check.sh (main only runs when executed),
# then repoint REPO_ROOT — a plain global every check_* reads at call time — at
# a throwaway tree under $BATS_TEST_TMPDIR and call a single check. Nothing is
# written under the real repo. Each test asserts the gate's own FAIL signal
# (FAIL=1 for a hard gate; FAIL=0 plus the ⚠ for the soft, warn-only ones, so a
# soft gate silently turning hard is caught too) and the message naming the
# injected defect, with a passing sibling in the same fixture as the positive
# control.
#
# Not covered here: gate 9 (fixture coverage — an informational count with no
# pass/fail branch). Gate 11 (doc freshness) has one fixture-git test below, for
# the field spellings docs/thoughts/ uses.

# Minimal repo: the three instruction files each reference workflows/rpi.md.
_fixture_repo() {
  local root="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$root/global-instructions" "$root/workflows"
  printf -- '---\nvalue-justification: x\n---\n# rpi\n' > "$root/workflows/rpi.md"
  printf 'Use `rpi.md`.\n' > "$root/global-instructions/CLAUDE.md"
  printf 'Use **@./workflows/rpi.md**.\n' > "$root/AGENTS.md"
  printf 'Use **rpi.md**.\n' > "$root/GEMINI.md"
  printf '%s' "$root"
}

# _run_gate <fixture-root> <check_fn>: prints the gate's output, then FAIL=<n>.
_run_gate() {
  run bash -c 'source "$1"; REPO_ROOT="$2"; "$3"; echo "FAIL=$FAIL"' _ "$SCRIPT" "$1" "$2"
  echo "$output"
}

@test "gate 2: a workflow reference with no file fails the gate" {
  local root; root="$(_fixture_repo)"
  printf 'Use `rpi.md` and `ghost.md`.\n' > "$root/global-instructions/CLAUDE.md"
  _run_gate "$root" check_workflow_crossrefs
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"✗ global-instructions/CLAUDE.md references ghost.md but workflows/ghost.md does not exist"* ]]
  [[ "$output" == *"✓ GEMINI.md: all workflow references resolve"* ]]
}

@test "gate 3: MD files referencing different workflows fail the gate" {
  local root; root="$(_fixture_repo)"
  printf 'Use **@./workflows/rpi.md** and **@./workflows/spike.md**.\n' > "$root/AGENTS.md"
  _run_gate "$root" check_md_consistency
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"✗ In AGENTS.md but not global-instructions/CLAUDE.md: spike.md"* ]]
  [[ "$output" != *"All MD files reference the same workflows"* ]]
}

@test "gate 3: a missing instruction file fails the gate instead of shrinking it" {
  local root; root="$(_fixture_repo)"
  rm "$root/GEMINI.md"
  _run_gate "$root" check_md_consistency
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"✗ GEMINI.md not found — MD consistency cannot be checked"* ]]
}

@test "gate 4: fixture/verdict mismatches and a missing verdicts file fail the gate" {
  local root; root="$(_fixture_repo)"
  mkdir -p "$root/test/skills/foo/fixtures" "$root/test/skills/bar/fixtures" \
           "$root/test/skills/ok/fixtures"
  touch "$root/test/skills/foo/fixtures/unlisted.md" "$root/test/skills/bar/fixtures/x.md" \
        "$root/test/skills/ok/fixtures/a.md"
  printf 'EXPECTED_VERDICT["gone.md"]="pass"\n' > "$root/test/skills/foo/expected-verdicts.bash"
  printf 'EXPECTED_VERDICT["a.md"]="pass"\n' > "$root/test/skills/ok/expected-verdicts.bash"
  _run_gate "$root" check_fixture_verdicts
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"✗ foo: fixture unlisted.md has no expected-verdicts entry"* ]]
  [[ "$output" == *"✗ foo: expected-verdicts references gone.md but fixture does not exist"* ]]
  [[ "$output" == *"✗ bar: has fixtures/ but no expected-verdicts.bash"* ]]
  [[ "$output" == *"✓ ok: all fixtures have verdicts and vice versa"* ]]
}

@test "gate 6: a shellcheck warning fails the gate and names the file" {
  command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not installed"
  local root; root="$(_fixture_repo)"
  mkdir -p "$root/scripts"
  printf '#!/bin/bash\nunused=1\n' > "$root/scripts/bad.sh"          # SC2034
  printf '#!/bin/bash\necho ok\n' > "$root/scripts/good.sh"
  _run_gate "$root" check_shellcheck
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"✗ scripts/bad.sh"* ]]
  [[ "$output" == *"✓ scripts/good.sh"* ]]
}

@test "gate 6: finding no shell files at all fails rather than passing vacuously" {
  command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not installed"
  local root; root="$(_fixture_repo)"
  _run_gate "$root" check_shellcheck
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"✗ No shell files found"* ]]
}

@test "gate 7: a workflow without value-justification warns (soft gate)" {
  local root; root="$(_fixture_repo)"
  printf '# no frontmatter\n' > "$root/workflows/bare.md"
  _run_gate "$root" check_workflow_value_justification
  [[ "$output" == *"FAIL=0"* ]]
  [[ "$output" == *"⚠ bare.md: missing or empty value-justification in frontmatter"* ]]
  [[ "$output" == *"✓ rpi.md: value-justification present"* ]]
  [[ "$output" == *"⚠ 2 workflow(s) checked — 1 missing value-justification"* ]]
}

@test "gate 8: a non-executable hook fails the gate" {
  local root; root="$(_fixture_repo)"
  mkdir -p "$root/hooks"
  printf '#!/bin/bash\n' > "$root/hooks/inert.sh"; chmod 644 "$root/hooks/inert.sh"
  printf '#!/bin/bash\n' > "$root/hooks/live.sh";  chmod 755 "$root/hooks/live.sh"
  _run_gate "$root" check_hook_permissions
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"✗ inert.sh is not executable"* ]]
  [[ "$output" == *"✓ live.sh is executable"* ]]
}

@test "gate 8b: unwired and target-missing hooks, and an empty deny list, warn (soft gate)" {
  command -v jq >/dev/null 2>&1 || skip "jq not installed"
  local root cfg; root="$(_fixture_repo)"; cfg="$BATS_TEST_TMPDIR/cfg"
  mkdir -p "$root/hooks" "$cfg/hooks"
  cat > "$root/hooks/wiring.json" <<'JSON'
{"hooks":{"PreToolUse":[{"hooks":[
  {"command":"bash {{CLAUDE_DIR}}/hooks/unwired.sh"},
  {"command":"bash {{CLAUDE_DIR}}/hooks/absent.sh"}]}]},
 "permissions":{"deny":["Edit(x)"]}}
JSON
  jq -n --arg c "bash $cfg/hooks/absent.sh" \
    '{hooks:{PreToolUse:[{hooks:[{command:$c}]}]}}' > "$cfg/settings.json"
  CLAUDE_CONFIG_DIR="$cfg" _run_gate "$root" check_hook_wiring
  [[ "$output" == *"FAIL=0"* ]]
  [[ "$output" == *"⚠ not wired: bash $cfg/hooks/unwired.sh"* ]]
  [[ "$output" == *"⚠ wired but target missing: $cfg/hooks/absent.sh"* ]]
  [[ "$output" == *"⚠ permissions.deny is empty"* ]]
  [[ "$output" != *"all targets present"* ]]
}

@test "gate 10: an si-functions.sh function nothing calls is flagged as an orphan" {
  local root; root="$(_fixture_repo)"
  mkdir -p "$root/scripts/lib"
  # The comment line matters: the gate greps the library minus its definition
  # lines, and a file of nothing but one-line definitions leaves that grep empty.
  printf '# lib\nused_fn() { :; }\norphan_fn() { :; }\n' > "$root/scripts/lib/si-functions.sh"
  printf '#!/bin/bash\nused_fn\n' > "$root/scripts/entry.sh"
  _run_gate "$root" check_feature_integration
  [[ "$output" == *"✓ used_fn: called from entry point"* ]]
  [[ "$output" == *"⚠ orphan_fn: not called from any entry-point script (orphan)"* ]]
  [[ "$output" == *"Feature integration: 1/2 functions"* ]]
}

@test "gate 12: a persona last sampled long ago is reported stale" {
  local root; root="$(_fixture_repo)"
  mkdir -p "$root/skills/old-persona" "$root/skills/new-persona"
  printf -- '---\nname: old-persona\npersona-last-sampled: 2020-01-01\n---\n' \
    > "$root/skills/old-persona/SKILL.md"
  printf -- '---\nname: new-persona\npersona-last-sampled: %s\n---\n' "$(date +%F)" \
    > "$root/skills/new-persona/SKILL.md"
  HEALTH_CHECK_SKILLS_DIR="$root/skills" _run_gate "$root" check_persona_freshness
  [[ "$output" == *"⚠ old-persona: STALE — persona last sampled"* ]]
  [[ "$output" == *"✓ new-persona: fresh (0 days since"* ]]
  [[ "$output" == *"Persona freshness: 2 checked, 1 fresh, 1 stale, 0 invalid"* ]]
}

@test "gate 13: AGENTS.md and GEMINI.md with different sections are flagged" {
  local root; root="$(_fixture_repo)"
  printf '## Skills\n## Only in agents\n' >> "$root/AGENTS.md"
  printf '## Skills\n' >> "$root/GEMINI.md"
  HEALTH_CHECK_SKILLS_DIR="$root/skills" _run_gate "$root" check_md_semantic_divergence
  [[ "$output" == *"⚠ AGENTS.md and GEMINI.md have diverging section structure"* ]]
  [[ "$output" != *"No semantic divergence detected"* ]]
}

@test "gate 14: a duplicated question id fails the gate" {
  # The gate runs the real scripts/questions.sh; QUESTIONS_LIVE/_ARCHIVE (its
  # own env overrides, honoured by check_questions_doc) point it at a fixture.
  local d="$BATS_TEST_TMPDIR/q" qs
  qs="$(dirname "$SCRIPT")/questions.sh"
  mkdir -p "$d"
  (cd "$d" && bash "$qs" init >/dev/null 2>&1)
  local s
  for s in one two; do
    printf '\n### Q-001 · %s\n**Needs:** agent · **Opened:** 2026-09-26 · **Status:** OPEN\n\nq?\n' \
      "$s" >> "$d/docs/working/questions.md"
  done
  run env QUESTIONS_LIVE="$d/docs/working/questions.md" \
          QUESTIONS_ARCHIVE="$d/docs/working/questions-archive.md" \
      bash -c 'source "$1"; check_questions_doc; echo "FAIL=$FAIL"' _ "$SCRIPT"
  echo "$output"
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"✗ duplicate id: Q-001"* ]]
  [[ "$output" == *"✗ questions doc: structure or index problems"* ]]
}

@test "gate 5: report suites the runner gated out are warned about with their count, never passed" {
  local stub="$BATS_TEST_TMPDIR/run-tests-nr.sh"
  cat > "$stub" <<'STUB'
#!/usr/bin/env bash
[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"
exit 0
STUB
  chmod +x "$stub"
  run env -u HEALTH_CHECK_SKIP_BATS HEALTH_CHECK_RUN_TESTS="$stub" \
    bash -c 'source "$1"; check_bats; echo "FAIL=$FAIL"' _ "$SCRIPT"
  echo "$output"
  [[ "$output" == *"FAIL=0"* ]]
  [[ "$output" == *"⚠ 47 report-dependent BATS suite(s) NOT RUN"* ]]
  [[ "$output" == *"Fast BATS suites passed (excluding 47 report-dependent suite(s) not run)"* ]]
}

@test "gate 11: thoughts docs are checked in all three field spellings; field-less notes are not" {
  local root; root="$(_fixture_repo)"
  mkdir -p "$root/docs/thoughts" "$root/src"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  git -C "$root" init -q
  git -C "$root" config user.email t@example.com
  git -C "$root" config user.name t
  echo a > "$root/src/a.sh"; echo b > "$root/src/b.sh"
  git -C "$root" add -A
  GIT_COMMITTER_DATE=2020-01-01T00:00:00 git -C "$root" commit -qm init --date=2020-01-01T00:00:00
  printf 'Last verified: 2021-01-01 (with a note)\nRelevant paths: src/a.sh · src/b.sh (the helper)\n' > "$root/docs/thoughts/plain.md"
  printf '`Last verified`: 2021-01-01\n`Relevant paths`: `src/b.sh`\n' > "$root/docs/thoughts/ticked.md"
  printf '**Last verified:** 2021-01-01\n**Relevant paths:** src/a.sh\n' > "$root/docs/thoughts/bold.md"
  printf '# a note with no freshness fields\n' > "$root/docs/thoughts/untracked.md"
  echo a2 >> "$root/src/a.sh"
  git -C "$root" add -A
  GIT_COMMITTER_DATE=2022-01-01T00:00:00 git -C "$root" commit -qm touch-a --date=2022-01-01T00:00:00
  _run_gate "$root" check_doc_freshness
  [[ "$output" == *"FAIL=0"* ]]
  [[ "$output" == *"docs/thoughts/plain.md: STALE — 1 commit(s)"* ]]
  [[ "$output" == *"docs/thoughts/bold.md: STALE — 1 commit(s)"* ]]
  # Positive control: b.sh has not changed since 2021.
  [[ "$output" == *"docs/thoughts/ticked.md: fresh"* ]]
  [[ "$output" != *"untracked.md"* ]]
  [[ "$output" == *"Freshness: 3 checked, 1 fresh, 2 stale, 0 missing fields"* ]]
}
