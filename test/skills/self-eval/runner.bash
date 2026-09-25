# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# self-eval scores a skill in this repo against docs/evaluation-rubric.md, and
# reads every sibling skill, test/ and docs/reviews/ as evidence. So it runs in
# tree mode: each fixture is a small repo holding the target skill (plus any test
# files or example outputs it should be credited with), and fixture_base lays
# down what every fixture shares:
#   - the LIVE rubric from this repo (not a vendored copy), unless the fixture
#     carries .fixture-no-rubric (tc-se5 checks SKILL.md's repo-only stop);
#   - three synthetic sibling skills from self-eval/base/skills/, one of which
#     (sql-migration-review) the tc-se2 target duplicates;
#   - the fixture's .fixture-tests/ tree, copied to test/ with ".bats.in"
#     renamed to ".bats". They are stored renamed so scripts/run-tests.sh, which
#     collects every *.bats under test/, never runs them as real suites.
# Read/Grep/Glob only: no Write (the report goes to stdout) and no Bash, so the
# git-log usage check sees nothing; the prompt says so rather than letting the
# model guess.
FIXTURE_TOOLS="Read,Grep,Glob"
FIXTURE_MODE="tree"

fixture_base() {
  local dest="$1" fx="$2"
  mkdir -p "$dest/skills" "$dest/docs"
  cp -R "$REPO_ROOT/test/skills/self-eval/base/skills/." "$dest/skills/"
  [ -e "$fx/.fixture-no-rubric" ] || cp "$REPO_ROOT/docs/evaluation-rubric.md" "$dest/docs/"
  if [ -d "$fx/.fixture-tests" ]; then
    mkdir -p "$dest/test"
    cp -R "$fx/.fixture-tests/." "$dest/test/"
    local f
    while IFS= read -r f; do
      mv "$f" "${f%.in}"
    done < <(find "$dest/test" -name '*.bats.in')
  fi
}

fixture_prompt() {
  printf '%s' "Print the evaluation report to stdout instead of saving it to docs/reviews/. You have no shell, so you cannot run git log: this repository's history is a single commit named \"fixture\", so there is no usage evidence in git. The request:"
}
