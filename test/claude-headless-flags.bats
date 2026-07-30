#!/usr/bin/env bats
# @category fast
# Regression tests for the headless-confinement flags on `claude -p`
# invocations in scripts/self-improvement.sh.
#
# WHY THIS SUITE EXISTS
# ---------------------
# Headless (`claude -p`) sessions do not inherit interactive defaults:
#   * Write/Edit are DENIED, so "write the rubric to docs/reviews/" is a no-op
#     and the pipeline persists nothing while reporting success;
#   * Read is CONFINED to cwd, so an orchestrator skill told to read its
#     critics' skills/<name>/SKILL.md from outside cwd gets BLOCKED and
#     silently falls back to paraphrasing the role.
# Both failures are SILENT — the run exits 0 either way — so nothing else in
# the suite would notice a regression that dropped the flags.
#
# Usage: bats test/claude-headless-flags.bats

load lib/hermetic-env

# These tests capture command-substitution output; pin the locale so bash's
# setlocale warning cannot leak into a captured value.
pin_hermetic_locale

SI_SCRIPT=""

setup() {
  SI_SCRIPT="$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"

  TEST_TMPDIR=$(mktemp -d)

  # Stub the claude CLI before sourcing. Nothing under test should reach the
  # real binary (live LLM call + sandbox network prompt); the shim makes that
  # a property of the suite rather than an accident. Same pattern as
  # test/round-log-functions.bats.
  mkdir -p "$TEST_TMPDIR/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_TMPDIR/bin/claude"
  chmod +x "$TEST_TMPDIR/bin/claude"
  PATH="$TEST_TMPDIR/bin:$PATH"

  # The main-execution guard keeps the top-level loop from running on source.
  source "$SI_SCRIPT"

  # NOTE on failure output: sourcing leaks the script's `set -euo pipefail`
  # and its `trap cleanup EXIT ERR` into the test shell, which pre-empts bats'
  # own ERR trap. A failing assertion therefore aborts the shell before bats
  # prints its "not ok" line, and the regression surfaces as a non-zero exit
  # plus "Executed N instead of expected M" rather than a named test. Do NOT
  # "fix" this with `set +e` — that disables the ERR trap bats uses to detect
  # failure at all, and every test starts passing. Same tradeoff as
  # test/round-log-functions.bats, which also sources this script.
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ---------------------------------------------------------------
# claude_headless_flags — the flag builder
# ---------------------------------------------------------------

@test "claude_headless_flags always requests acceptEdits" {
  mapfile -t flags < <(claude_headless_flags)
  [ "${flags[0]}" = "--permission-mode" ]
  [ "${flags[1]}" = "acceptEdits" ]
}

@test "claude_headless_flags emits nothing else when given no directories" {
  mapfile -t flags < <(claude_headless_flags)
  [ "${#flags[@]}" -eq 2 ]
}

@test "claude_headless_flags adds --add-dir for an existing directory" {
  mapfile -t flags < <(claude_headless_flags "$TEST_TMPDIR")
  [ "${#flags[@]}" -eq 4 ]
  [ "${flags[2]}" = "--add-dir" ]
  [ "${flags[3]}" = "$TEST_TMPDIR" ]
}

@test "claude_headless_flags adds one --add-dir per existing directory" {
  mkdir -p "$TEST_TMPDIR/a" "$TEST_TMPDIR/b"
  mapfile -t flags < <(claude_headless_flags "$TEST_TMPDIR/a" "$TEST_TMPDIR/b")
  [ "${#flags[@]}" -eq 6 ]
  [ "${flags[3]}" = "$TEST_TMPDIR/a" ]
  [ "${flags[5]}" = "$TEST_TMPDIR/b" ]
}

@test "claude_headless_flags drops a non-existent directory" {
  # A --add-dir naming a missing path makes the CLI reject the whole
  # invocation, which would turn a soft degradation into a hard gate failure
  # on hosts without the baked payload.
  mapfile -t flags < <(claude_headless_flags "$TEST_TMPDIR/does-not-exist")
  [ "${#flags[@]}" -eq 2 ]
}

@test "claude_headless_flags drops an empty directory argument" {
  # The code-review gate passes "" for CR_ADD_DIR in the worktree-fallback
  # case, where everything the reviewer reads is already inside cwd.
  mapfile -t flags < <(claude_headless_flags "")
  [ "${#flags[@]}" -eq 2 ]
}

@test "claude_headless_flags tolerates a directory path containing spaces" {
  mkdir -p "$TEST_TMPDIR/with space"
  mapfile -t flags < <(claude_headless_flags "$TEST_TMPDIR/with space")
  [ "${#flags[@]}" -eq 4 ]
  [ "${flags[3]}" = "$TEST_TMPDIR/with space" ]
}

# ---------------------------------------------------------------
# Call-site wiring — the flags must actually reach `claude -p`
# ---------------------------------------------------------------

@test "the code-review gate passes CR_FLAGS to claude -p" {
  run grep -n 'claude -p "\${CR_FLAGS\[@\]}" --model "\$SI_CODE_REVIEW_MODEL"' "$SI_SCRIPT"
  [ "$status" -eq 0 ]
}

@test "the code-review gate builds CR_FLAGS from claude_headless_flags" {
  run grep -n 'mapfile -t CR_FLAGS < <(claude_headless_flags "\$CR_ADD_DIR")' "$SI_SCRIPT"
  [ "$status" -eq 0 ]
}

@test "the code-review gate adds the baked payload root, reaching skills/ and patterns/" {
  # code-review's SKILL.md links ../../patterns/orchestrated-review.md and
  # requires reading each critic's skills/<name>/SKILL.md verbatim. Both live
  # under /opt/claude-workflows, so that single root must be the add-dir.
  run grep -n 'CR_ADD_DIR="/opt/claude-workflows"' "$SI_SCRIPT"
  [ "$status" -eq 0 ]
}

@test "the worktree-fallback review path clears CR_ADD_DIR" {
  # In the fallback the skill and patterns are inside $WT_DIR (the cwd), so an
  # --add-dir would be pointless; more importantly the baked root is absent on
  # that host, and naming a missing dir would fail the invocation outright.
  run grep -n 'CR_ADD_DIR=""' "$SI_SCRIPT"
  [ "$status" -eq 0 ]
}

@test "every file-writing claude -p invocation carries headless flags" {
  # Allowlist: invocations that only read within cwd and return their answer
  # on stdout. These genuinely need neither flag. Everything else must expand
  # a *_FLAGS array built by claude_headless_flags.
  local allowlist='PROBLEMS_JSON=|OVERLAP_RESULT=|SOLVED_PROBLEMS_JSON='
  local offenders
  offenders=$(grep -n 'claude -p ' "$SI_SCRIPT" \
    | grep -v '^\s*[0-9]*:\s*#' \
    | grep -vE "$allowlist" \
    | grep -vF '_FLAGS[@]}' || true)
  [ -z "$offenders" ] || {
    echo "claude -p invocations missing headless flags:"
    echo "$offenders"
    false
  }
}

@test "the stdout-only invocations are still flag-free, keeping the allowlist honest" {
  # If one of these grows a file-writing instruction, this test should be
  # updated in the same change that adds the flags — it exists so the
  # allowlist above cannot silently drift into covering a writer.
  local var count
  for var in PROBLEMS_JSON OVERLAP_RESULT SOLVED_PROBLEMS_JSON; do
    count=$(grep -c "^ *${var}=.*claude -p " "$SI_SCRIPT" || true)
    [ "$count" -eq 1 ]
    ! grep -q "^ *${var}=.*claude -p .*_FLAGS\[@\]}" "$SI_SCRIPT"
  done
}
