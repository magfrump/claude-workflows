#!/usr/bin/env bats
# @category fast
# Guards the rubric->benchmark section contract in
# scripts/crb-pipeline-to-benchmark.py, added by the 2026-08-18 review (rubric
# A15 / C1).
#
# Why this exists: the section filter used to be a SUBSTRING test, and
# "consider" is a substring of "Considered Overrides". That section passed the
# filter and emitted nothing only by the accident that the rubric template names
# its column "Prior finding" rather than "Finding". A one-word rename in
# skills/code-review/SKILL.md would have started injecting already-waived
# findings into the benchmark as guaranteed false positives, silently
# understating the pipeline's precision, with nothing to catch it.
#
# test/skills/code-review/rubric-current-format.md is the checked-in golden
# rubric that code-review-format-contract.bats already keeps in sync with the
# template, so this suite guards the CONSUMER half of the same contract using an
# asset that is already drift-protected. Hermetic: no network, no repo mutation.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export SCRIPT="$REPO_ROOT/scripts/crb-pipeline-to-benchmark.py"
  export GOLDEN="$REPO_ROOT/test/skills/code-review/rubric-current-format.md"
}

# Load the injector as a module and print one fact about a rubric on stdout.
# $1 = rubric path, $2 = python expression over `m` (module) and `md` (text).
probe() {
  python3 - "$SCRIPT" "$1" "$2" <<'PY'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("inj", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
md = Path(sys.argv[2]).read_text()
print(eval(sys.argv[3]))
PY
}

@test "golden rubric fixture exists (contract asset for this suite)" {
  [ -f "$GOLDEN" ]
}

@test "only the two finding sections are emitted from the golden rubric" {
  run probe "$GOLDEN" \
    "sorted({m.normalize_section(s) for s,_h,_r in m.md_tables(md) if m.normalize_section(s) in {m.normalize_section(x) for x in m.FINDING_SECTIONS}})"
  [ "$status" -eq 0 ]
  [ "$output" = "['must address', 'must fix']" ]
}

# 🟢 Consider is excluded by DECISION (log #36, 2026-08-19), taken before any
# judge run: advisory rows rarely match a human PR comment, and the benchmark
# scores precision as TP / total_candidates, so each unmatched green is a false
# positive. This case exists so the exclusion cannot be undone by accident —
# re-adding the alias or the section makes it fail, which forces a new decision
# rather than a quiet edit.
@test "Consider is excluded, and cannot be re-enabled by a flag" {
  run probe "$GOLDEN" "m.FINDING_SECTIONS"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Consider"* ]]
  run probe "$GOLDEN" "sorted(m.SECTION_ALIASES)"
  [ "$output" = "['address', 'fix']" ]
  # The golden rubric really does carry Consider rows, so the exclusion is
  # doing work rather than passing vacuously.
  run probe "$GOLDEN" \
    "[s for s,_h,_r in m.md_tables(md) if m.normalize_section(s) == 'consider']"
  [ "$status" -eq 0 ]
  [ "$output" != "[]" ]
}

@test "Considered Overrides is NOT treated as a finding section" {
  run probe "$GOLDEN" \
    "m.normalize_section('↩️ Considered Overrides') in {m.normalize_section(x) for x in m.FINDING_SECTIONS}"
  [ "$status" -eq 0 ]
  [ "$output" = "False" ]
}

@test "Confirmed Good is NOT treated as a finding section" {
  run probe "$GOLDEN" \
    "m.normalize_section('✅ Confirmed Good') in {m.normalize_section(x) for x in m.FINDING_SECTIONS}"
  [ "$status" -eq 0 ]
  [ "$output" = "False" ]
}

@test "normalize_section strips emoji and punctuation decoration" {
  run probe "$GOLDEN" "m.normalize_section('## 🔴 Must Fix')"
  [ "$status" -eq 0 ]
  [ "$output" = "must fix" ]
}

@test "the golden rubric yields at least one review comment" {
  run probe "$GOLDEN" "len(m.comments_from_rubric(md)) > 0"
  [ "$status" -eq 0 ]
  [ "$output" = "True" ]
}

# The regression this suite exists for: renaming the Considered-Overrides column
# to `Finding` must NOT change what gets injected. Before the section match was
# anchored, this rename silently added every waived override as a finding.
@test "renaming the Considered Overrides column to Finding is inert" {
  local renamed="$BATS_TEST_TMPDIR/renamed.md"
  sed 's/| Prior finding |/| Finding |/' "$GOLDEN" > "$renamed"
  run probe "$GOLDEN" "len(m.comments_from_rubric(md))"
  [ "$status" -eq 0 ]
  local before="$output"
  run probe "$renamed" "len(m.comments_from_rubric(md))"
  [ "$status" -eq 0 ]
  [ "$output" = "$before" ]
}

# Discriminating on purpose, and the narrowest case: `--sections consider` is the
# invocation where "consider" vs "considered overrides" actually collides. With
# the pre-fix substring filter this goes 2 -> 3 comments on the rename (the
# override row is injected); with the section match anchored it stays 2.
# Named for the property, not for a flag: `--sections consider` no longer exists
# (log #36), but the collision this guards does — "consider" is a substring of
# "considered overrides", so section matching must stay on the normalized
# HEADING. Passing 'Consider' directly to comments_from_rubric is just the
# sharpest available probe of that, since it is the section whose name collides.
@test "section matching is heading-based, so Considered Overrides cannot leak in" {
  local renamed="$BATS_TEST_TMPDIR/renamed-consider.md"
  sed 's/| Prior finding |/| Finding |/' "$GOLDEN" > "$renamed"
  run probe "$GOLDEN" "len(m.comments_from_rubric(md, ['Consider']))"
  [ "$status" -eq 0 ]
  local before="$output"
  run probe "$renamed" "len(m.comments_from_rubric(md, ['Consider']))"
  [ "$status" -eq 0 ]
  [ "$output" = "$before" ]
}
