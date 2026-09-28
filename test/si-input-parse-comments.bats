#!/usr/bin/env bats
# @category fast
# Unit tests for parse_si_input()'s handling of HTML comments and of text
# outside the four known sections in si-input.md (lib/si-input.sh). The first
# two moved from si-input-rejected-history.bats when its subject,
# prepend_si_input_rejected_history, was deleted (Q-065 [1]).

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-input.sh"
  TEST_TMPDIR=$(mktemp -d)
  INPUT_FILE="$TEST_TMPDIR/si-input.md"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "parse_si_input drops the middle lines of a multi-line HTML comment" {
  printf '# SI Input\n\n## Feedback\n\nreal feedback\n<!--\nhidden middle line\n## Context\n-->\nmore feedback\n\n## Priorities\n\n  <!-- indented opener\n  hidden prio\n  -->\n- p1\n<!-- one-liner -->\n' > "$INPUT_FILE"
  parse_si_input "$INPUT_FILE" 2>/dev/null
  [ "$SI_FEEDBACK" = "$(printf 'real feedback\nmore feedback')" ]
  [ "$SI_PRIORITIES" = "- p1" ]
  [ -z "$SI_CONTEXT" ]
}

@test "parse_si_input keeps a heading that carries a trailing inline comment" {
  # Regression (2026-09-18 review F2): the `*-->` skip ran before heading
  # detection, so this heading was dropped and its body joined Feedback.
  printf '## Feedback\nfb line\n## Off-limits <!-- topics to avoid -->\nskills/code-review\n## Priorities\n- p1 <!-- why --> now\n' > "$INPUT_FILE"
  parse_si_input "$INPUT_FILE" 2>/dev/null
  [ "$SI_FEEDBACK" = "fb line" ]
  [ "$SI_OFF_LIMITS" = "skills/code-review" ]
  [ "$SI_PRIORITIES" = "- p1  now" ]
}

@test "parse_si_input drops text before the first heading and under unknown headings" {
  # Replaces the deleted "comment block does not pollute parsed sections"
  # test (Q-065 review A1): text before the first ## heading, comment or
  # prose, and the body of an unknown heading reach no SI_* variable.
  printf '<!-- Recent rejections (last 3 rounds):\n  Round 1: task-foo — something failed\n## Context\n-->\nstray preamble prose\n## Feedback\n\nthe real feedback\n\n## Notes\nunknown section body\n## Priorities\n\n- priority one\n' > "$INPUT_FILE"
  parse_si_input "$INPUT_FILE" 2>/dev/null
  [ "$SI_FEEDBACK" = "the real feedback" ]
  [ "$SI_PRIORITIES" = "- priority one" ]
  [ -z "$SI_CONTEXT" ]
  [ -z "$SI_OFF_LIMITS" ]

  # With no known section after them, a leak into any variable would not be
  # overwritten by a later real section, so all four SI_* section variables
  # must stay empty.
  printf 'stray preamble prose\n## Notes\nunknown section body\n' > "$INPUT_FILE"
  parse_si_input "$INPUT_FILE" 2>/dev/null
  [ -z "$SI_FEEDBACK" ]
  [ -z "$SI_PRIORITIES" ]
  [ -z "$SI_OFF_LIMITS" ]
  [ -z "$SI_CONTEXT" ]
}
