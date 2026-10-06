Commit: d48f4645
# Test Strategy: feat/build-loop-u2a1 (final confirming pass)

**Scope:** `git diff main...HEAD` at d48f4645 (6f624cdf, 706e0499, d48f4645): scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats, test/scripts/build-loop-read.bats, test/lib/build-loop-fixtures.bash
**Reviewed:** 2026-10-06
**Mode:** final confirming pass, full panel; iteration-1 rubric and override-log rows 306-325 taken as settled context.

## Test Conventions

- bats-core (>= 1.5.0), `# @category fast` tag required by scripts/run-tests (header line 3), contract tests that build a throwaway repo under `$BATS_TEST_TMPDIR` and assert whole output lines (`[ "$output" = ... ] || { echo "$output"; return 1; }`).
- Lib functions are tested in-process through `bash -c 'set -euo pipefail; source "$1"; ...' _ "$REPO_ROOT/scripts/lib/dev-cycle-read.sh"` (dev-cycle.bats:1338-1366).
- build-loop suites load `test/lib/build-loop-fixtures.bash` (`bl_setup`); dev-cycle.bats has its own `setup()`/`make_repo` (repo on `main` with three merged feature branches).
- Mutation checks by hand are the review convention (fact-check reports name surviving mutants).

## Untested Paths Touched by the Change

Each gap below was checked by running a mutant against `test/scripts/dev-cycle.bats` and `test/scripts/build-loop-read.bats` in a scratch copy (93 tests; test 78 of the pair fails in any copy without the repo's own `docs/`, and fails on the unmutated copy too, so it is not counted).

- **G1** — test/scripts/dev-cycle.bats:13, test/lib/build-loop-fixtures.bash:15 — the `unset $(git rev-parse --local-env-vars)` in both setups (iteration-1 fix A1, closes override row 314) — not covered; no committed test runs either suite under an inherited `GIT_DIR`, so removing both lines passes every test. The fix was verified once by hand (fact-check: "a mutant without the unset wrote 80 commits").
  - **Evidence:** `    # shellcheck disable=SC2046  # word splitting is wanted: one name per line` / `    unset $(git rev-parse --local-env-vars)`
  - **Legibility-target:** test suite (fixture hermeticity contract)
- **G2** — scripts/lib/dev-cycle-read.sh:158 — the `[[ "$1" == docs/working/briefs/closed/* ]]` guard in `isclosed` — not covered. Mutant M1 (drop the guard, keep `isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"`) passes all 92 countable tests, and with it `--check-write 2026-01-01-x.md` prints `ok 2026-01-01-x.md` and `--check-brief 2026-01-01-x.md` prints `ok 2026-01-01-x.md new` (executed; the unmutated script prints `skip ...: not one of the dev cycle's own files` and `skip ...: not a build brief (...)`). `writable` is the `--check-write` gate (lib:159-162), so this mutant fails open. The old anchored regex (`^docs/working/briefs/closed/...`) carried the prefix inside the pattern; the new spelling splits it into a separate clause that no test pins. Existing closed-brief tests (dev-cycle.bats:728-732, 893-903; build-loop-read.bats:404-407, 469-472) cover only real `closed/` paths and the `2026-10-0closed/` negative, never a brief-shaped name outside `docs/working/briefs/`.
  - **Evidence:** `isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }`
  - **Legibility-target:** scripts/lib/dev-cycle-read.sh (isclosed's contract)
- **G3** — scripts/lib/dev-cycle-read.sh:265-266 — the order of main_entry's two guards (no main by name answers `error` before a refused form answers `badform`) — not covered. Mutant M2 (swap the two lines) passes all 92 countable tests. Both words are refusals to every caller, so this is wording/contract only; the stage-1 annotation already notes the comment implies but does not state the order.
  - **Evidence:** `  if ! main_by_name; then echo error; return; fi` / `  if ! pathform "$1"; then echo badform; return; fi`
  - **Legibility-target:** scripts/lib/dev-cycle-read.sh (main_entry header comment, lines 249-262)
- **G4** — scripts/lib/dev-cycle-read.sh:354 — check_brief's `*)` arm for the words `notdir PART` and `error` — partially covered: `notfile` is pinned end to end (dev-cycle.bats:1042); `notdir` and `error` reach the CLI in no test (pre-existing gap; the diff rewrote the line). entry_why's own wording for both is pinned by the unit test (dev-cycle.bats:1338-1354).
  - **Evidence:** `    *) echo "skip $a: $(entry_why "$e" "")"; return ;;`
  - **Legibility-target:** test suite
- **G5** — scripts/build-loop.sh:133 — main_file's `error` reason through `--settings` (iteration-1 fix A3, "names the path") — not covered end to end; `notfile` and `notdir` are (build-loop-read.bats:61-66, 193), and the `error` wording with a path is pinned via check_answer (dev-cycle.bats:1327) and the unit test.
  - **Evidence:** `    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;`
  - **Legibility-target:** test suite
- **G6** — scripts/lib/dev-cycle-read.sh:284 — newline folding of entry_why's word `$1` — not covered (stage-1 r3 annotation: the mutant survives; no caller can produce a word with a newline, since `notdir PART` comes from a path pathform already accepted).
  - **Evidence:** `  local w="${1//$'\n'/ }" p="${2//$'\n'/ }"`
  - **Legibility-target:** scripts/lib/dev-cycle-read.sh

Iteration-1 fixes checked against tests: A1 has no regression test (G1). A2's path-newline folding is pinned (dev-cycle.bats:1338-1354, last case `a ok b is not an allowed path form`). A3/A4 wording is pinned by exact-line tests at dev-cycle.bats:1198, 1203, 1226-1228, 1327 and the unit test. A5/A6 are comment-only. No iteration-1 fix introduced an untested branch beyond G1. The `unset` list includes `GIT_CONFIG_COUNT`/`GIT_CONFIG_PARAMETERS`; build-loop-read.bats:438 sets `GIT_CONFIG_COUNT` inside `run ... env`, after setup, so it is unaffected (stage-1: 19/19 pass).

## Recommended Tests

#### Both fixture setups keep an inherited GIT_DIR's repo untouched

**Closes gaps:** G1
**Type:** integration (runs each suite's real setup under a hostile environment)
**Priority:** medium
**File:** new `test/scripts/fixture-git-env.bats` (a checked draft is at `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-final/test/g1-fixture-git-env.bats`)
**What it verifies:** running one test of dev-cycle.bats and one of build-loop-read.bats with `GIT_DIR`/`GIT_INDEX_FILE` pointed at a victim repo leaves the victim at 1 commit and 1 ref, and the inner run itself ran one test and passed (so the check is not vacuous).
**Key cases:**
- `env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f '^prints all eight sections' test/scripts/dev-cycle.bats` → status 0, output has `1..1` and `ok 1 `; `git -C "$V" rev-list --all --count` = 1.
- Same with `bats -f 'exact policy line is set' test/scripts/build-loop-read.bats`.
- Executed in a scratch copy: both pass at d48f4645; with both `unset` lines replaced by `:` both fail (the victim gained 7 and 5 commits). [unverified — submitted as claim; route: code-fact-check]

**Setup needed:** a victim repo made with `git init` plus one `--allow-empty` commit under `$BATS_TEST_TMPDIR`; `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`; `bats` on PATH (it is the runner). Adds ~2-4 s. Spawns only `bats` and `git`, so test/fixture-hermeticity.bats's network-binary gate is not affected.

#### isclosed accepts a closed/ path only

**Closes gaps:** G2
**Type:** integration (CLI contract)
**Priority:** medium
**File:** test/scripts/dev-cycle.bats, a new `@test` after the main_entry test (checked patch: `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-final/test/g2-g3-dev-cycle.patch`)
**What it verifies:** a brief-shaped name outside `docs/working/briefs/closed/` is neither writable nor a brief.
**Key cases:**
- `--check-write 2026-01-01-x.md docs/2026-01-01-x.md docs/working/briefs/closedx/2026-01-01-x.md` → three exact lines `skip <p>: not one of the dev cycle's own files`.
- `--check-brief 2026-01-01-x.md` → `skip 2026-01-01-x.md: not a build brief (docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md)`.
- Executed: passes at d48f4645, fails under M1. [unverified — submitted as claim; route: code-fact-check]

**Setup needed:** none beyond the suite's `setup()` (main found by name).

#### main_entry with no main found by name answers error, even for a refused form

**Closes gaps:** G3
**Type:** unit (in-process lib call)
**Priority:** low (one line in an existing test, so worth taking with G2's patch)
**File:** test/scripts/dev-cycle.bats:1356-1366, the existing `main_entry answers badform ...` test (same patch file)
**What it verifies:** the header's order: `error` for no default branch outranks `badform`.
**Key cases:**
- After the existing loop, `MAIN_SHA=""; main_entry .gitattributes` → `error` (eighth expected line).
- Executed: passes at d48f4645, fails under M2; the whole dev-cycle.bats with the patch runs 75/75 under a `/tmp/u2a1x-*` TMPDIR. [unverified — submitted as claim; route: code-fact-check]

**Setup needed:** none.

## What NOT to Test

- **G4** (check_brief's notdir/error arms at the CLI): Low. The arm is one `*)` line handing the word to entry_why, whose wording is pinned word by word; the only caller-side choice (passing `""`) is pinned by the notfile test at :1042, which a `"$a"` mutant would fail. Building a duplicate-name tree or a non-directory `docs/working/briefs` on main adds fixture weight for no new branch.
- **G5** (main_file's error arm through `--settings`): Low, same reasoning: the arm is shared with notfile (pinned at build-loop-read.bats:61-63, 193), so passing a wrong second argument already fails a test; the error wording is pinned elsewhere. A duplicate-tree `--settings` fixture belongs with row 307's broken-read work in U2's --check, if anywhere.
- **G6** (newline folding of the word): unreachable from any caller today; a test would pin defensive code no input can reach. Revisit if U2a2's floor passes words from a source other than main_entry.
- The SKILL.md and header wording changes (constraints.md in the list, "checked task box", "not ahead of main"): prose; the behaviour each describes is pinned (dev-cycle.bats:1016-1032 for constraints.md and docs/thoughts/).

## Coverage Gaps Beyond Current Scope

**1.** shared_branches (scripts/build-loop.sh:318) skips a brief that brief_fields refuses, so F31's duplicate-open-brief count fails open for an unreadable second brief (stage-1 r3 annotation; settled by override rows 293/308, trigger U2a2's floor). No new test proposed here.

**2.** build-loop-read.bats:84 keeps an unsplit `git replace ... && git config` chain, guarded by its own `git replace -d` at :85 (stage-1 r2/r3 annotation); outside row 317's three chains. Split it on the next edit of that file, alongside U2's build-loop-check.bats.

## Summary

The highest-value addition is G2's test: the new `isclosed` spelling moved the `closed/` prefix out of an anchored regex into a separate guard that no test pins, and dropping that guard turns `--check-write` and `--check-brief` into `ok` for a root-level brief-shaped name (executed). G1's regression test turns A1's one-off manual check into a standing one; without it, a later setup edit can silently send fixture commits into a hook's repo again. G3 is a one-line extension of an existing test. After both patches, the residual risk is the CLI-unreached refusal arms (G4, G5), whose wording is pinned at the unit level. No iteration-1 fix was found incorrect.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-final-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d48f4645` as its first line.
- **Answered:** yes: this file, `Commit: d48f4645` on line 1, structured per skills/test-strategy (conventions, gap list G1-G6 with Evidence and Legibility-target, recommended tests, what not to test, beyond scope, summary). Iteration-1 fixes A1-A6 checked; none incorrect; one untested (A1, G1).
- **Out of scope:** writing the tests into the branch (advisory pass; drafts are in the scratch dir only); re-filing override rows 306-325.
- **Escalate:** none. G1 and G2 are medium test gaps, not behavioural defects in d48f4645; whether to take them in this unit or defer them is the orchestrator's call.
- **Decisions:** scratch-dir drafts `g1-fixture-git-env.bats` and `g2-g3-dev-cycle.patch` (paths above); scratch copies and `/tmp/u2a1x-*` TMPDIRs removed; no tracked file modified.
