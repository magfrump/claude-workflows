# Research: the flaky fanout case in board.bats

Date: 2026-11-18 · Brief: `docs/working/briefs/2026-11-18-board-fanout-flaky.md` · Branch: `fix/board-fanout-flaky`

Failure-pattern grep: `rg -n -i 'ln -s|fixture.*vary|nondetermin|hash.*timestamp|flak' docs/failure-patterns.md` -> FP-174 and FP-175 (flakes under parallel load: a `find` racing deletions, SIGPIPE under pipefail). Neither is this one, a fixture whose content varies with commit times.
Failure-pattern skip: a one-off test-setup slip (`ln -s` into a directory that may already exist) found and fixed in one test; it names no recurring cause worth an entry, and an entry would send this self-merge brief to the owner's review for no gain.

## Reproduction

`bats -f 'a symlink in the git directory' test/scripts/board.bats`, with the fixture forced to hold an `objects/ab` directory (a probe copy of the file whose fanout line ran `mkdir -p "$c/objects/ab"` first).

## Cause: confirmed (criterion 1)

The case's `fanout` step ran `ln -s "$out/ab" "$c/objects/ab"`. When the fixture repo already held a loose object whose hash starts `ab`, `objects/ab` was a real directory, so `ln` made the link at `objects/ab/ab` and left `objects/ab` a plain directory. `scripts/board.sh` checks `objects/??` for symlinks (line 187), found none, and the write went through, giving `want: objects/ab ... is a symlink or leaves it` followed by `WRITTEN`. Commit hashes in the fixture vary with timestamps, so whether an `ab` object exists changes from run to run.

Probe: with `objects/ab` pre-created, the unfixed case failed 3 of 3 runs with exactly the health-check output (`WRITTEN to .../alpha: Q-001`). With the fix, the same forced fixture (an `ab` directory holding a file) passed 3 of 3.

The script is not wrong: a symlink at `objects/ab/ab` is not a fan-out directory, git never writes an object to that name, and the case's own "nothing landed outside" check still passed. Only the test's setup was wrong, so `scripts/board.sh` is unchanged.

## Fix (criterion 2)

One-line choice (two viable options, no divergent design needed): the fanout step now always runs `mkdir -p "$c/objects/ab"` and then moves that directory out to `$out/ab` before linking, the same move-and-link that the reflog and heads cases already use. This beats picking a fan-out name the repo does not hold, which needs a search loop and still leaves a race. A new guard after the `case` block, `[ -L "$c/$want" ]`, fails the setup with a message naming the case, so a plant that misses can never pass silently again (this covers all four cases).

## Verification (criterion 3)

- The case alone under `timeout 300`: 20 of 20 passed.
- `timeout 900 bats test/scripts/board.bats`: 24 of 24 passed.
- `scripts/hermeticity-lint --root .`: passes.

## Review

The diff is 6 test lines. I reviewed it myself, with no subagent, against the four cases: each `want` path is a symlink after its step (`logs/refs/heads/main`, `refs/heads`, `objects/ab`, `packed-refs`). `mv` into the not-yet-existing `$out/ab` renames the directory. Any objects it holds are captured in the `out.before` snapshot, so the "nothing lands outside" comparison is unchanged. No findings.
