#!/usr/bin/env bats
# @category fast
# Guards scripts/crb-harvest-artifacts.py, which replaced the runner's
# `git -C "$clone" status --porcelain -z --untracked-files=all` harvest loop.
#
# Two defects motivated the replacement, and both have a case here:
#   1. it was HOST git against a container-written `.git`, and it was the FIRST
#      host command after the container exited — where core.fsmonitor fires
#      (2026-08-19 rubric R1). Nothing in the new harvest reads `.git`, which is
#      pinned by the "gitignored path" case below: git could not see that file,
#      so a harvest that finds it demonstrably is not asking git.
#   2. `--untracked-files=all` still honours `.gitignore`. The code-review skill
#      writes its rubric under docs/reviews/, which some upstream repos ignore,
#      so a cell's only artifact could be silently dropped and the injector
#      would fall back to the freeform result text without anyone noticing.
#
# The rest are containment-of-the-harvest cases: the clone is third-party
# content, so symlinks, oversized files and runaway counts must not be able to
# reach or fill the host.
#
# Hermetic: throwaway trees in BATS_TEST_TMPDIR, no clones, no network.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HARVEST="$REPO_ROOT/scripts/crb-harvest-artifacts.py"
  export MAT="$REPO_ROOT/scripts/crb-materialize.py"
}

setup() {
  export CLONE="$BATS_TEST_TMPDIR/clone"
  export DEST="$BATS_TEST_TMPDIR/artifacts"
  export INDEX="$BATS_TEST_TMPDIR/index.json"
  rm -rf "$CLONE" "$DEST"; mkdir -p "$CLONE/docs" "$CLONE/.git"
  echo '# preexisting' > "$CLONE/README.md"
  echo '{"a":1}' > "$CLONE/docs/config.json"
  echo 'internals' > "$CLONE/.git/HEAD"
}

# The index must be produced by crb-materialize's own artifact_index(), not
# hand-rolled here: the two walks have to agree on exclusions or every file in a
# directory one skips reads as "new" on the first cell.
write_index() {
  python3 - "$MAT" "$CLONE" "$INDEX" <<'PY'
import importlib.util, json, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("mat", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
Path(sys.argv[3]).write_text(json.dumps(m.artifact_index(Path(sys.argv[2]))))
PY
}

harvest() { run python3 "$HARVEST" "$CLONE" "$INDEX" "$DEST"; }

@test "an unchanged tree harvests nothing" {
  write_index
  harvest
  [ "$status" -eq 0 ]
  [[ "$output" == *"harvested 0 artifact(s)"* ]]
}

@test "a new rubric is harvested with its directory structure" {
  write_index
  mkdir -p "$CLONE/docs/reviews"
  echo '# Code Review Rubric' > "$CLONE/docs/reviews/rubric.md"
  harvest
  [ "$status" -eq 0 ]
  [ -f "$DEST/docs/reviews/rubric.md" ]
  [[ "$output" == *"artifact (new): docs/reviews/rubric.md"* ]]
}

@test "a modified pre-existing file is harvested as modified" {
  write_index
  echo '# rewritten by the review' > "$CLONE/README.md"
  harvest
  [ "$status" -eq 0 ]
  [[ "$output" == *"artifact (modified): README.md"* ]]
  [ "$(cat "$DEST/README.md")" = "# rewritten by the review" ]
}

# The defect that made the git-based harvest incomplete. `git status
# --untracked-files=all` reports nothing for an ignored path; this must.
@test "an artifact written to a gitignored path is still harvested" {
  # A real repo, not setup()'s stub .git — this case needs git to actually
  # evaluate .gitignore for the negative control below to mean anything.
  rm -rf "$CLONE"; mkdir -p "$CLONE"
  git -C "$CLONE" init -q
  git -C "$CLONE" config user.email t@t; git -C "$CLONE" config user.name t
  echo 'docs/reviews/' > "$CLONE/.gitignore"
  git -C "$CLONE" add -A; git -C "$CLONE" commit -qm base
  write_index
  mkdir -p "$CLONE/docs/reviews"
  echo '# rubric' > "$CLONE/docs/reviews/rubric.md"
  # Establish that git genuinely cannot see it, so this case cannot silently
  # stop testing what it says it tests.
  run git -C "$CLONE" status --porcelain --untracked-files=all
  [[ "$output" != *"rubric.md"* ]]
  harvest
  [ "$status" -eq 0 ]
  [ -f "$DEST/docs/reviews/rubric.md" ]
}

@test "repository internals are never harvested" {
  write_index
  echo '{"leak":true}' > "$CLONE/.git/config.json"
  mkdir -p "$CLONE/vendor/nested/.git"
  echo '# nested' > "$CLONE/vendor/nested/.git/notes.md"
  harvest
  [ "$status" -eq 0 ]
  [[ "$output" == *"harvested 0 artifact(s)"* ]]
  [ ! -e "$DEST/.git" ]
}

# A symlink is a pointer into the host filesystem that any later reader of the
# artifacts dir would follow — including the injector.
@test "a symlinked artifact is not harvested and not followed" {
  write_index
  ln -s /etc/passwd "$CLONE/secrets.md"
  mkdir -p "$BATS_TEST_TMPDIR/outside"
  echo '# outside the clone' > "$BATS_TEST_TMPDIR/outside/host.md"
  ln -s "$BATS_TEST_TMPDIR/outside" "$CLONE/escape"
  harvest
  [ "$status" -eq 0 ]
  [[ "$output" == *"harvested 0 artifact(s)"* ]]
  [ ! -e "$DEST/secrets.md" ]
  [ ! -e "$DEST/escape" ]
}

@test "an oversized file is skipped, named, and does not stop the harvest" {
  write_index
  head -c 6000000 /dev/zero | tr '\0' 'x' > "$CLONE/huge.md"
  echo '# small' > "$CLONE/small.md"
  harvest
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipping huge.md"* ]]
  [ ! -e "$DEST/huge.md" ]
  [ -f "$DEST/small.md" ]
}

# Exit 2 is an invocation error, not "nothing to harvest" — the runner aborts on
# it rather than banking a cell whose artifacts were never collected.
@test "a missing baseline index is an invocation error, not an empty harvest" {
  harvest
  [ "$status" -eq 2 ]
  [[ "$output" == *"no baseline index"* ]]
}

@test "usage and a missing clone both exit 2" {
  run python3 "$HARVEST"
  [ "$status" -eq 2 ]
  run python3 "$HARVEST" "$BATS_TEST_TMPDIR/nope" "$INDEX" "$DEST"
  [ "$status" -eq 2 ]
}
