#!/usr/bin/env bats
# @category fast
# Unit tests for select_run_rubric() in scripts/self-improvement.sh — the picker that
# feeds the advisory rubric/sentinel cross-check in Gate 1h.
#
# WHY THIS SUITE EXISTS
# ---------------------
# The gate archives `$WT_DIR/docs/reviews/*.md` wholesale, and these repos carry rubrics
# from PREVIOUS branches in-tree. The old selector was
#   ls -1 "$CR_ARCHIVE"/code-review-rubric*.md | head -1
# which returns the lexicographically first name — for date-stamped rubrics, the OLDEST.
# It silently cross-checked this run's sentinel against someone else's rubric, and two
# measurement batches were discarded to it (docs/thoughts/code-review-evaluation-state.md
# §5.4, trap 1). Selection is now by CONTENT: reviewed commit plus run date.
#
# Usage: bats test/rubric-selection.bats

load lib/hermetic-env

# These tests capture command-substitution output; pin the locale so bash's setlocale
# warning cannot leak into a captured value.
pin_hermetic_locale

setup() {
  SI_SCRIPT="$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"

  TEST_TMPDIR=$(mktemp -d)
  ARCHIVE="$TEST_TMPDIR/archive"
  mkdir -p "$ARCHIVE"

  # Stub the claude CLI before sourcing — nothing under test should reach the real
  # binary (live LLM call + sandbox network prompt). Same pattern as
  # test/round-log-functions.bats and test/claude-headless-flags.bats.
  mkdir -p "$TEST_TMPDIR/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_TMPDIR/bin/claude"
  chmod +x "$TEST_TMPDIR/bin/claude"
  PATH="$TEST_TMPDIR/bin:$PATH"

  # The main-execution guard keeps the top-level loop from running on source.
  # shellcheck source=../scripts/self-improvement.sh
  source "$SI_SCRIPT"

  # NOTE on failure output: sourcing leaks the script's `set -euo pipefail` and its
  # `trap cleanup EXIT ERR` into the test shell, pre-empting bats' own ERR trap. A
  # failing assertion can therefore surface as "Executed N instead of expected M"
  # rather than a named failure. Do NOT "fix" this with `set +e` — that disables the
  # ERR trap bats uses to detect failure at all, and every test starts passing.
  # Same tradeoff as test/claude-headless-flags.bats.
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Write a rubric with the given basename, reviewed date and commit reference.
mk_rubric() {
  local name=$1 reviewed=$2 commit=$3
  printf '# Code Review Rubric\n\nCommit: %s\n\n**Scope:** feat/x | **Reviewed:** %s | **Status: 🔴 DOES NOT PASS**\n\n## 🔴 Must Fix\n\n| # | Finding |\n|---|---|\n| R1 | a |\n\n## 🟡 Must Address\n' \
    "$commit" "$reviewed" > "$ARCHIVE/$name"
}

# ---------------------------------------------------------------
# The regression the fix exists for
# ---------------------------------------------------------------

@test "picks this run's rubric over an older one carried in-tree" {
  # Lexically first == oldest date, which is exactly what `ls | head -1` returned.
  mk_rubric 'code-review-rubric-2026-01-05-feat-old-branch.md' '2026-01-05' 'aaaaaaaaaaaa'
  mk_rubric 'code-review-rubric-2026-07-30-feat-new-branch.md' '2026-07-30' 'd90d6bbcafe1'

  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ "$result" = "$ARCHIVE/code-review-rubric-2026-07-30-feat-new-branch.md" ]
}

@test "an alphabetically-earlier stale rubric with the same date is not selected" {
  # Date alone is not enough: a stale rubric can be re-archived on any run day. The
  # commit is the discriminator.
  mk_rubric 'code-review-rubric-2026-07-30-aaa-stale.md' '2026-07-30' 'deadbeef0000'
  mk_rubric 'code-review-rubric-2026-07-30-zzz-current.md' '2026-07-30' 'd90d6bbcafe1'

  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ "$result" = "$ARCHIVE/code-review-rubric-2026-07-30-zzz-current.md" ]
}

# ---------------------------------------------------------------
# Matching modes
# ---------------------------------------------------------------

@test "matches a commit recorded as a short SHA" {
  mk_rubric 'code-review-rubric-2026-07-30-feat-x.md' '2026-07-30' 'd90d6bb'
  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ "$result" = "$ARCHIVE/code-review-rubric-2026-07-30-feat-x.md" ]
}

@test "matches a commit range encoded only in the filename" {
  # The skill names rubrics after the reviewed range when there is no branch name.
  printf '# Code Review Rubric\n\n**Reviewed:** 2026-07-30\n' \
    > "$ARCHIVE/code-review-rubric-2026-07-30-commit-range-d86d2dc-d90d6bb.md"
  printf '# Code Review Rubric\n\nCommit: deadbeef\n\n**Reviewed:** 2026-01-05\n' \
    > "$ARCHIVE/code-review-rubric-2026-01-05-feat-old.md"

  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ "$result" = "$ARCHIVE/code-review-rubric-2026-07-30-commit-range-d86d2dc-d90d6bb.md" ]
}

@test "falls back to the date when the rubric never names the commit" {
  mk_rubric 'code-review-rubric-2026-01-05-feat-old.md' '2026-01-05' 'deadbeef'
  printf '# Code Review Rubric\n\n**Reviewed:** 2026-07-30\n' \
    > "$ARCHIVE/code-review-rubric-2026-07-30-feat-new.md"

  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ "$result" = "$ARCHIVE/code-review-rubric-2026-07-30-feat-new.md" ]
}

@test "a commit match outranks a date match" {
  printf '# Code Review Rubric\n\n**Reviewed:** 2026-07-30\n' \
    > "$ARCHIVE/code-review-rubric-2026-07-30-feat-datematch.md"
  mk_rubric 'code-review-rubric-2026-01-05-feat-commitmatch.md' '2026-01-05' 'd90d6bb'

  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ "$result" = "$ARCHIVE/code-review-rubric-2026-01-05-feat-commitmatch.md" ]
}

@test "a longer hex string that merely starts with the short SHA still matches" {
  # `Commit: d90d6bbcafe1234567890` must match a short SHA of d90d6bb.
  mk_rubric 'code-review-rubric-2026-07-30-feat-x.md' '2026-07-30' 'd90d6bbcafe1234567890'
  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ "$result" = "$ARCHIVE/code-review-rubric-2026-07-30-feat-x.md" ]
}

@test "a different commit sharing no prefix does not match" {
  mk_rubric 'code-review-rubric-2026-01-05-feat-old.md' '2026-01-05' 'deadbeef1234'
  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ -z "$result" ]
}

# ---------------------------------------------------------------
# Fail-to-unavailable, never guess
# ---------------------------------------------------------------

@test "emits nothing when no rubric matches this run" {
  mk_rubric 'code-review-rubric-2026-01-05-feat-old.md' '2026-01-05' 'deadbeef'
  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ -z "$result" ]
}

@test "emits nothing when two candidates tie" {
  # A guess here is what the old head -1 did. The cross-check is advisory, so
  # "unavailable" is a safe answer and a coin flip is not.
  mk_rubric 'code-review-rubric-2026-07-30-feat-a.md' '2026-07-30' 'd90d6bb'
  mk_rubric 'code-review-rubric-2026-07-30-feat-b.md' '2026-07-30' 'd90d6bb'

  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ -z "$result" ]
}

@test "emits nothing for an empty archive directory" {
  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ -z "$result" ]
}

@test "emits nothing for a directory that does not exist" {
  result=$(select_run_rubric "$TEST_TMPDIR/nope" 'd90d6bbcafe1234567890' '2026-07-30')
  [ -z "$result" ]
}

@test "emits nothing when neither a commit nor a date is known" {
  mk_rubric 'code-review-rubric-2026-07-30-feat-x.md' '2026-07-30' 'd90d6bb'
  result=$(select_run_rubric "$ARCHIVE" '' '')
  [ -z "$result" ]
}

@test "ignores non-rubric review artifacts in the same archive" {
  printf 'Commit: d90d6bb\n2026-07-30\n' > "$ARCHIVE/security-review-2026-07-30.md"
  mk_rubric 'code-review-rubric-2026-07-30-feat-x.md' '2026-07-30' 'd90d6bb'

  result=$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')
  [ "$result" = "$ARCHIVE/code-review-rubric-2026-07-30-feat-x.md" ]
}

# ---------------------------------------------------------------
# End-to-end with the parser it feeds
# ---------------------------------------------------------------

@test "the selected rubric is the one count_rubric_red reads" {
  # The stale rubric has three reds, the current one has one. Under the old selector
  # the cross-check reported 3 and flagged a spurious sentinel disagreement.
  printf '## 🔴 Must Fix\n| R1 | a |\n| R2 | b |\n| R3 | c |\n## 🟡 x\nCommit: deadbeef\n2026-01-05\n' \
    > "$ARCHIVE/code-review-rubric-2026-01-05-feat-old.md"
  mk_rubric 'code-review-rubric-2026-07-30-feat-new.md' '2026-07-30' 'd90d6bb'

  result=$(count_rubric_red "$(select_run_rubric "$ARCHIVE" 'd90d6bbcafe1234567890' '2026-07-30')")
  [ "$result" = "1" ]
}

# ---------------------------------------------------------------
# Call-site wiring
# ---------------------------------------------------------------

@test "the gate selects the rubric by content, not by ls order" {
  # shellcheck disable=SC2016  # literal grep pattern; expansion is not wanted
  run grep -n 'select_run_rubric "\$CR_ARCHIVE" "\$CR_COMMIT" "\$CR_RUN_DATE"' "$SI_SCRIPT"
  [ "$status" -eq 0 ]
}

@test "the ls | head -1 selector is gone" {
  # Also the outstanding SC2012 finding on that line; the glob-based selector clears
  # it rather than suppressing it.
  # Comment lines are exempt: the replacement documents the bug it replaced.
  local offenders
  offenders=$(grep -n 'ls -1 .*code-review-rubric' "$SI_SCRIPT" | grep -vE '^[0-9]+:[[:space:]]*#' || true)
  [ -z "$offenders" ] || { echo "live ls-based selector still present:"; echo "$offenders"; false; }
  run grep -n 'disable=SC2012' "$SI_SCRIPT"
  [ "$status" -ne 0 ]
}
