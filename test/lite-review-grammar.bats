#!/usr/bin/env bats
# @category fast
# Contract tests for the FINDINGS grammar, which scripts/lite-review.py owns.
#
# The grammar used to live in scripts/cross-model-review.py, with lite-review
# documenting its copy as a copy. cross-model-review is the OpenRouter benchmark
# harness and is out of scope for this repo (decision log 48), so the live path
# now owns the definition and these tests are what keeps it honest — the two
# regexes were byte-identical when ownership moved, and nothing but this file
# holds the shape in place once the harness leaves.
#
# Keyless and offline throughout: parse_findings() is pure, so no `claude` call.

setup_file() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export REPO_ROOT
}

# Parse $1 with lite-review's parse_findings and print `<parse_ok>\n<json rows>`.
# The module filename has a hyphen, so it loads by path rather than by import.
parse() {
  python3 - "$REPO_ROOT/scripts/lite-review.py" "$1" <<'PY'
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location("lite_review", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
rows, ok = mod.parse_findings(sys.argv[2])
print(ok)
print(json.dumps(rows))
PY
}

@test "FINDINGS: NONE parses as a clean review, not as a parse failure" {
  run parse 'FINDINGS: NONE'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "True" ]
  [ "${lines[1]}" = "[]" ]
}

@test "a well-formed row keeps every field, and the line range is separate from the path" {
  run parse 'FINDINGS:
1. scripts/foo.py:12-14 | High | security | Unvalidated path | The path is joined without a prefix check.'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "True" ]
  [[ "${lines[1]}" == *'"path": "scripts/foo.py"'* ]]
  [[ "${lines[1]}" == *'"lines": "12-14"'* ]]
  [[ "${lines[1]}" == *'"severity": "High"'* ]]
  [[ "${lines[1]}" == *'"domain": "security"'* ]]
  [[ "${lines[1]}" == *'"title": "Unvalidated path"'* ]]
  [[ "${lines[1]}" == *'"description": "The path is joined without a prefix check."'* ]]
}

@test "severity is matched case-insensitively and normalized to capitalized" {
  run parse 'FINDINGS:
1. a.py:1 | critical | perf | T | D
2. b.py:2 | INFORMATIONAL | perf | T | D'
  [ "$status" -eq 0 ]
  [[ "${lines[1]}" == *'"severity": "Critical"'* ]]
  [[ "${lines[1]}" == *'"severity": "Informational"'* ]]
}

@test "a row without a line range parses with an empty lines field" {
  run parse 'FINDINGS:
1. README.md | Low | docs | Stale claim | The README describes the old flag.'
  [ "$status" -eq 0 ]
  [[ "${lines[1]}" == *'"path": "README.md"'* ]]
  [[ "${lines[1]}" == *'"lines": ""'* ]]
}

@test "prose before the FINDINGS header is ignored, not parsed as rows" {
  run parse 'Here is my review of the diff.
1. This numbered line is preamble, not a finding | High | x | y | z
FINDINGS:
1. a.py:3 | Medium | correctness | Off by one | The loop overruns by one.'
  [ "$status" -eq 0 ]
  [[ "${lines[1]}" == *'"title": "Off by one"'* ]]
  [[ "${lines[1]}" != *'preamble'* ]]
}

@test "output with no FINDINGS block at all reports a parse failure" {
  # The distinction that matters operationally: an empty finding list is only
  # trustworthy when the model actually emitted the block.
  run parse 'I was unable to review this diff.'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "False" ]
  [ "${lines[1]}" = "[]" ]
}

@test "a FINDINGS block with only malformed rows yields no rows but still parses" {
  run parse 'FINDINGS:
- a.py | High | something'
  [ "$status" -eq 0 ]
  # parse_ok stays true because the block was emitted, but no rows survive —
  # callers must not read "no rows" as "clean" without checking the raw text.
  [ "${lines[0]}" = "True" ]
  [ "${lines[1]}" = "[]" ]
}

# --- Negative pins (added 2026-09-12 after the review) ---------------------
# The seven tests above pin the accept spec against *narrowing*: mutate
# FINDING_RE to accept less and one of them goes red. They said nothing about
# *widening*, and mutation testing during the review found four widenings that
# kept all seven green — each with a real downstream consumer (a severity value
# outside the five has no row in the rubric's mapping and is dropped at
# synthesis; a row that loses its description carries no finding).
# These assert the shapes the grammar must keep REJECTING.

@test "a severity outside the five-value enum is not accepted" {
  run parse 'FINDINGS:
1. a.py:1 | Blocker | security | T | D'
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = "[]" ]
}

@test "a row with nothing after the final pipe is not accepted" {
  # Note the line ends AT the pipe: `.+` requires at least one character, so
  # widening it to `.*` is what this pin catches. A row with a trailing space
  # does match (the space satisfies `.+` and strips to an empty description) —
  # that is a separate gap, recorded as a 🟢 in the 2026-09-12 rubric.
  run parse 'FINDINGS:
1. a.py:1 | High | security | Some title |'
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = "[]" ]
}

@test "a bullet-prefixed row is not accepted in place of a numbered one" {
  run parse 'FINDINGS:
- a.py:1 | High | security | T | D'
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = "[]" ]
}

@test "a comma-separated line list survives in the lines field" {
  # Positive pin guarding the line-range character class: narrowing
  # [\d\-, ]+ to [\d\-]+ keeps every other test green while silently
  # dropping rows like this one.
  run parse 'FINDINGS:
1. a.py:12,15,20 | Medium | correctness | T | D'
  [ "$status" -eq 0 ]
  [[ "${lines[1]}" == *'"lines": "12,15,20"'* ]]
}
