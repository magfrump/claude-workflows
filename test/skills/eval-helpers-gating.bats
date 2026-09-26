#!/usr/bin/env bats
# @category fast
# scripts/run-tests.sh's per-skill report gating (audit 2026-09-26, Batch G
# T1/T2), run against a copy of the script in a throwaway repo layout with a
# stub bats that records the suites it was handed. No real suite runs.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  T=$(mktemp -d)
  mkdir -p "$T/scripts" "$T/test/skills/alpha/output" "$T/test/skills/beta/output" \
    "$T/skills/alpha" "$T/skills/beta" "$T/bin"
  cp "$REPO_ROOT/scripts/run-tests.sh" "$T/scripts/"
  cp "$REPO_ROOT/test/skills/runner-contract.bash" "$T/test/skills/"
  echo "# alpha" > "$T/skills/alpha/SKILL.md"
  echo "# beta" > "$T/skills/beta/SKILL.md"
  suite alpha-eval.bats alpha
  suite alpha-format.bats alpha
  suite beta-eval.bats beta
  mkdir -p "$T/test/skills/beta"
  suite beta/dimensions.bats beta
  # Report-free suites, whatever their name: they always run.
  suite alpha-skill-lint.bats ""
  suite zeta-format.bats ""
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$@" > "%s/bats-args"\n' "$T" > "$T/bin/bats"
  chmod +x "$T/bin/bats"
  PATH="$T/bin:$PATH"
}

teardown() {
  rm -rf "$T"
}

# suite <path under test/skills> <skill or "">: a fast suite, tagged
# "# @needs-reports <skill>" when a skill is given.
suite() {
  {
    echo '#!/usr/bin/env bats'
    echo '# @category fast'
    [ -z "$2" ] || echo "# @needs-reports $2"
    echo '@test "x" { true; }'
  } > "$T/test/skills/$1"
}

ran() { grep -c "/$1\$" "$T/bats-args"; }

@test "no reports: every tagged suite is listed NOT RUN on stdout; report-free suites run" {
  run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== NOT RUN: 4 report-dependent suite(s)"* ]]
  [[ "$output" == *"skills/alpha-eval.bats [alpha]"* ]]
  [[ "$output" == *"skills/beta/dimensions.bats [beta]"* ]]
  [ "$(cat "$T/nr")" = 4 ]
  [ "$(ran alpha-skill-lint.bats)" -eq 1 ]
  [ "$(ran zeta-format.bats)" -eq 1 ]
  [ "$(ran alpha-eval.bats)" -eq 0 ]
}

@test "one skill's reports run only that skill's suites" {
  echo "# R" > "$T/test/skills/alpha/output/tc-1.md.report.md"
  run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast
  [ "$status" -eq 0 ]
  [ "$(ran alpha-eval.bats)" -eq 1 ]
  [ "$(ran alpha-format.bats)" -eq 1 ]
  [ "$(ran beta-eval.bats)" -eq 0 ]
  [ "$(ran dimensions.bats)" -eq 0 ]
  [ "$(cat "$T/nr")" = 2 ]
  [[ "$output" == *"skills/beta-eval.bats [beta]"* ]]
  [[ "$output" != *"alpha-eval.bats [alpha]"* ]]
}

@test "a stamp or .failed marker alone is not a report" {
  touch "$T/test/skills/alpha/output/tc-1.md.stamp" "$T/test/skills/alpha/output/tc-1.md.failed"
  run bash "$T/scripts/run-tests.sh" --fast
  [ "$status" -eq 0 ]
  [ "$(ran alpha-eval.bats)" -eq 0 ]
}

@test "a tag naming no skill is an error, not a suite that never runs" {
  suite gamma-eval.bats gamma
  run bash "$T/scripts/run-tests.sh" --fast
  [ "$status" -eq 1 ]
  [[ "$output" == *"must name a skill"*"gamma-eval.bats"* ]]
}

@test "a tag outside the header does not gate the suite" {
  printf '#!/usr/bin/env bats\n# @category fast\n%s\n# @needs-reports alpha\n@test "x" { true; }\n' \
    "$(printf '#\n%.0s' {1..14})" > "$T/test/skills/late-tag.bats"
  run bash "$T/scripts/run-tests.sh" --fast
  [ "$status" -eq 0 ]
  [ "$(ran late-tag.bats)" -eq 1 ]
}

@test "the real tree: every report-reading suite is tagged, and arithmetic-eval's lint suite is not" {
  local f
  while IFS= read -r f; do
    head -15 "$f" | grep -qE '^# @needs-reports [a-z-]+$' \
      || { echo "untagged report suite: $f"; return 1; }
  done < <(grep -lE '^\s*(eval_fixture|resolve_skill_report|load_edge_report) ' \
             "$REPO_ROOT"/test/skills/*.bats "$REPO_ROOT"/test/skills/*/*.bats \
           | grep -v '/eval-helpers-')
  ! head -15 "$REPO_ROOT/test/skills/arithmetic-eval-format.bats" | grep -q '@needs-reports'
}
