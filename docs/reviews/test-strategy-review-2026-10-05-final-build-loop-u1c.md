Commit: 4dc84ce4

# Test Strategy: U1c build-loop --settings constraints line and --status (final confirming pass, iteration 3)

**Scope:** `test/scripts/build-loop-read.bats` and `test/lib/build-loop-fixtures.bash` against `scripts/build-loop.sh` at 4dc84ce4, focused on what 4dc84ce4 changed: the task-box fold (`:175`), the F31 `git grep` candidate set (`:306-308`), the `status_line` ordering (`:318`), and the new END-nosuccess T44 case (`bats:183`).
**Reviewed:** 2026-10-05
**Method:** I ran 15 mutants of `scripts/build-loop.sh` against copies of `scripts/` and `test/` in my scratch dir (`/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/test-strategy/`), then wrote probe tests and ran them against HEAD and against the surviving mutants. Test 4 (T3, G19) reads the real repo's `docs/dev-cycle.md` through REPO_ROOT, so it fails in every copy. I ignored it when scoring the mutants.

## Test Conventions

- **Framework and fixture:** bats 1.5+, with `run --separate-stderr bash "$BL" ...`. Each test builds a throwaway repo in `bl_setup` (`test/lib/build-loop-fixtures.bash`).
  - The repo gets a hermetic git environment: `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, `LC_ALL=C`.
  - Helpers: `settings`, `constraints`, `brief` (sets `B`), `work`, `tip`, and `line` / `settings_is` / `settings_like`.
- **Test style:** each test is a contract test named with the plan's T-number. Within a test, cases run in sequence, often as a table loop like `for c in ...`. A failing case prints `$output` and returns 1.
- **Caller config is invisible:** because of `GIT_CONFIG_GLOBAL=/dev/null`, the caller's global config never reaches a test. Repo-local `git config` in the fixture repo still reaches the script, and so do `GIT_CONFIG_COUNT`/`KEY`/`VALUE` env vars. I confirmed both by probe.
- **Literal pathspecs:** `build-loop.sh:112` exports `GIT_LITERAL_PATHSPECS=1`, so pathspec magic such as `:!closed/` in the script is inert. My first closed/ mutant was invalid for this reason, and I replaced it with a `--max-depth 0` mutant.

### Mutation results (4dc84ce4's fixes)

| Mutant | Change | Result | Killed by |
|---|---|---|---|
| M1 | task-box fold reverted to `sub(/^[^a-zA-Z]*/, "", s)` (`:175`) | killed | T44 (`bats:178`, `- [x] H2: x`) |
| M2 | END `nosuccess` check deleted (`:183`) | killed | T44 (`bats:183`) |
| M3c | `shared_branches` call deleted (`:318`) | killed | T28 |
| M3a | call moved to after `brief_fields "$a"` (the harmful order) | **survived** | none (G4) |
| M3b | call moved back to c143b929's position (after `pol=`) | survived, equivalent | nothing reads BRIEF after that point, so A14 was latent at c143b929 |
| M4 | grep pattern `'^Status: open$'` (`\r?` dropped) | **survived** | none (G5) |
| M5 | `\|\| true` dropped | **survived** | none (G3) |
| M6 | `f="${f#"$MAIN_SHA":}"` deleted | killed | T28 |
| M7b | `git grep --max-depth 0` (closed/ not searched) | killed | T28 (`bats:382`) |
| M8 | `git -c color.grep=always grep` inside the script | killed | T28 |
| M9 | `Status: open` filter in `shared_branches` removed | survived | row 291 (G4 of iteration 2), deferred to U1d, so not re-filed |
| M10 | `isbrief "$f"` (closed/ not stripped) | killed | T28 |
| M11 | shared threshold `-lt 3` | killed | T28 |

The four fixes named in the task are covered as follows:

- **Task-box fold (M1):** covered.
- **END-nosuccess case (M2):** covered. This agrees with Stage-1 Claim 25.
- **git-grep candidate set:** the set itself is covered (M6, M7b, M8, M10, M11). Its CR arm (M4) and its no-match arm (M5) are not.
- **status_line ordering:** the presence of the call is covered (M3c). Its position is not (M3a).

## Untested Paths Touched by the Change

- **G1** — scripts/build-loop.sh:306 — `git grep -l` under the caller's colour config (`color.ui=always` or `color.grep=always`, in repo config, global config or `GIT_CONFIG_COUNT` env) — not covered. The tests set `GIT_CONFIG_GLOBAL=/dev/null`, and no test sets repo config.
  - At HEAD the probe failed: with `git config color.ui always` in the fixture repo, two open briefs on `feat/x` print `ok docs/working/briefs/2026-10-01-a.md open review feat/x absent - - 0`.
  - The env form fails the same way: `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=color.ui GIT_CONFIG_VALUE_0=always`.
  - This is the Stage-1 Claim 20b regression. The fail-open is a code finding. The test gap is mine.
  - Severity: high (an F31 dispatch guard fails open, silently). Confidence: high (probed). Legibility-target: for-author.
  - **Evidence** (`:306`): `  list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"`
- **G2** — scripts/build-loop.sh:306 — `|| true` on a git grep that fails with exit 128 — not covered.
  - Probe: with `git config grep.patternType bogus`, stderr shows `fatal: bad grep.patterntype argument: bogus`, the exit is 0, and the result is the same fail-open `ok` for a shared branch.
  - Severity: medium. Confidence: high (probed). Legibility-target: for-author.
  - **Evidence:** same line as G1.
- **G3** — scripts/build-loop.sh:306 — the no-match arm (git grep exits 1 when main has no open brief at all) — not covered. Every `--status` test has at least one open brief on main before its first run.
  - With M5 (`|| true` dropped), `--status` prints nothing and exits 1 in a repo with no open brief on main. That would break the first `new` brief in a fresh repo, and the suite stays green.
  - The probe confirmed that HEAD is right (`ok ... done review feat/x absent - - 0`) and that M5 breaks it.
  - Severity: medium (only a refactor can break it, but it is the arm most likely to be "cleaned up" while fixing G2). Confidence: high. Legibility-target: for-author.
- **G4** — scripts/build-loop.sh:318 — `shared_branches` runs before `brief_fields "$a"` (A14's fix) — partially covered.
  - The call's presence is pinned (M3c killed). Its position is not. M3a (the call after `brief_fields "$a"`) survives because every first `--status` argument in the suite is the lexically last open candidate. The last brief `shared_branches` reads is then the queried one, so the clobbered BRIEF looks the same.
  - Probe: with a second open brief `z` (`Dispatched: 7`) after the queried `a`, M3a prints `feat/z`'s fields for `a`.
  - Severity: medium (silent wrong answer: the wrong branch, policy or Dispatched for a brief). Confidence: high. Legibility-target: for-author.
  - **Evidence** (`:318`): `  [[ -n "$SHARED_BRANCHES" ]] || shared_branches  # first: it reads other briefs into BRIEF`
- **G5** — scripts/build-loop.sh:306 — the `\r?` arm of the grep pattern (an open brief with CRLF line endings) — not covered.
  - M4 survives. The probe showed that `brief_fields` reads a CRLF brief as `Status: open`, so at HEAD it counts for F31. Under M4 grep never selects it, and F31 fails open for that pair.
  - Severity: low. Confidence: high. Legibility-target: for-author.

These gaps are covered by override rows and I have not re-filed them:

- **Row 291:** NUL refusal; F31 open-only filter (M9 survives, as recorded).
- **Rows 246/295:** U1b's G7–G11.

Iteration 2's C19 (G5–G7: the 1-character reason, `Dispatched: 99` / `0`, and the fenced `H2:` pin) is still open in the rubric with no override row. Its premise has not changed.

## Recommended Tests

All four tests below were applied together in `prop/` in my scratch dir, a copy of the suite with these edits and nothing else.

- **With `--no-color` added to `:306`:** all 15 tests that can run in a copy pass.
- **At HEAD's script:** T28 fails on the colour line, which shows the regression.
- **Under M3a (with `--no-color`):** T28 fails.
- **Under M5:** T8 fails.

Together the four edits are a net +4 lines (one line moved). G2 and G5 below would add about 5 more.

#### Forced colour in T28 (the smallest test for the colour regression)

**Closes gaps:** G1
**Type:** integration
**Priority:** high
**File:** test/scripts/build-loop-read.bats, T28 (`:366`), as its second line
**What it verifies:** F31's file list does not depend on the caller's colour config.
**Key cases:**
- Add `git config color.ui always  # the caller's config: F31's file list must not carry colour` right after `settings 'Build-loop policy: review'`. Every existing T28 assertion then runs under forced colour.
- At HEAD, `lines[1]` reads `ok docs/working/briefs/2026-10-01-d.md ...` instead of the expected skip, so the test fails. After the fix (`git grep --no-color` or `-c color.grep=false`) it passes.

**Setup needed:** none. Repo-local config bypasses `GIT_CONFIG_GLOBAL=/dev/null`, so no fixture change is needed. With `--no-color` applied I also ran the whole suite with `color.ui`, `color.grep` and `color.diff` set to `always` in `bl_setup`: nothing else in the script is colour-sensitive.

#### A queried brief that is not the last F31 candidate

**Closes gaps:** G4
**Type:** integration
**Priority:** medium
**File:** test/scripts/build-loop-read.bats, end of T28
**What it verifies:** BRIEF holds the queried brief when other open briefs sort after it.
**Key cases:**
- Append these lines to T28:
  ```
  # The queried brief is not the last one F31 reads (BRIEF is read after the set).
  rm docs/working/briefs/2026-10-01-wt.md && brief z 'Status: open' 'Branch: feat/z' 'Dispatched: 7' && run --separate-stderr bash "$BL" --status "$d"
  [ "$output" = "ok $d open review feat/d absent - - 0" ] || { echo "$output"; return 1; }
  ```
  The `rm` is needed because `commit_all` runs `git add -A`, which would otherwise commit the working-tree-only `wt.md` (another open `feat/d`).
- Under M3a the output carries `feat/z ... 7`, and the test fails.

**Setup needed:** none.

#### No open brief on main (git grep exits 1)

**Closes gaps:** G3
**Type:** integration
**Priority:** medium
**File:** test/scripts/build-loop-read.bats, T8 (`:305`)
**What it verifies:** `--status` works when main has no open brief at all, which is the first brief in a fresh repo.
**Key cases:**
- Move the existing "Not landed on main" block (`bats:333-336`) up to just after T8's `settings` line, and add ", and no open brief on main" to its comment. This adds no lines.
- Under M5, T8 fails at the moved block (no output, exit 1).

**Setup needed:** none.

#### git grep failure is not a silent empty set

**Closes gaps:** G2
**Type:** integration
**Priority:** medium. The assertion depends on the fix the orchestrator picks.
**File:** test/scripts/build-loop-read.bats, T28
**What it verifies:** a git grep error (exit other than 0/1) does not read as "no shared branches".
**Key cases:**
- Run `git config grep.patternType bogus`, then `--status "$a"`, where `a` and `b` share `feat/x`.
- Assert that the output is not `ok $a ...`. If the fix makes it an error, also assert a non-zero exit or a skip line.
- Remove the config afterwards (`git config --unset grep.patternType`).

**Setup needed:** none. At HEAD this run prints `ok` with exit 0 (probed).

#### CRLF open brief counts for F31

**Closes gaps:** G5
**Type:** integration
**Priority:** low
**File:** test/scripts/build-loop-read.bats, T28
**What it verifies:** the `\r?` in the grep pattern selects an open brief written with CRLF line endings.
**Key cases:**
- Write a CRLF brief with `printf '# Brief: b\r\n\r\nStatus: open\r\nBranch: feat/x\r\n' > docs/working/briefs/2026-10-01-crlf.md && commit_all crlf` next to an LF open brief on `feat/x`.
- The LF brief's line must be the skip. Under M4 it reads `ok`.

**Setup needed:** none.

## What NOT to Test

- **M3b (the call at c143b929's position):** this mutant is equivalent at HEAD, because nothing reads BRIEF after `pol=` is set. The G4 test pins the harmful order, which is enough. A test against the old position would be pinning an implementation detail.
- **The fold's new false positives** (`- [x] S3 bucket moved` now reads unreadable; Stage-1 Claim 4): this is fail-closed and inside Q-112's best-effort rule. A test would freeze an incidental shape.
- **Bracketed non-task-box shapes** (`- [x ] H2:`, `- [y] H2:`, `- (x) H2:`): these are the Stage-1 escalation and the orchestrator places them against row 290. A test should wait for that ruling.
- **The caller's global `~/.gitconfig`:** the repo-local config test reaches the same code path. Changing `bl_setup`'s hermetic `GIT_CONFIG_GLOBAL` would cost every suite its isolation for no extra coverage.

## Coverage Gaps Beyond Current Scope

**1.** Row 291's NUL refusal and F31 open-only filter (M9 still survives), deferred to U1d.

**2.** Rows 246/295: U1b's G7–G11, deferred to U1d.

**3.** Iteration 2's C19 (1-character stopped reason, `Dispatched: 99` / explicit `0`, fenced `H2:` pin). It has no override row. If U1c lands without them, they should go to U1d alongside rows 246/291/295, and the orchestrator should give them a row.

**4.** Which unit each new gap belongs to:
- **U1c:** G1, G3 and G4. They test code that 4dc84ce4 itself introduced or moved, G1 is a live fail-open regression from c143b929, and each costs 0–3 lines.
- **U1c or U1d:** G2, depending on the fix shape.
- **U1d:** G5, if the ~430-line cap (Q-114) must hold.

## Summary

The highest-value test is the single line `git config color.ui always` at the top of T28. It turns the Stage-1 colour regression (Claim 20b) from invisible to red, because repo-local config reaches the script despite `GIT_CONFIG_GLOBAL=/dev/null`.

Mutation runs confirm that 4dc84ce4's task-box fold and END-nosuccess case are pinned by T44, and that the git-grep candidate set is pinned by T28 except for its CR arm and its `|| true` arms.

The ordering fix (A14) is only half pinned: deleting the call is caught, but moving it after `brief_fields "$a"` is not. One appended T28 case closes that.

A residual risk remains after these tests: the `|| true` fail-open (G2) also needs a code fix, and its test assertion waits on which fix the orchestrator chooses. Proposed G1+G3+G4 cost a net +4 lines, inside the spirit of the Q-114 waiver.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path your task names, structured per your skill, with a `Commit: 4dc84ce4` first line.
- Answered: yes
- Out of scope: the code fix for the colour and exit-128 fail-open, which belongs to the fact-check and security channel; re-filing rows 246/291/295; the bracketed-prefix residue (Stage-1 escalation, row 290's call).
- Escalate: G1 is a test gap for a live, unanimously confirmed fail-open (Claim 20b). The orchestrator should pair the `--no-color` and exit-code fix with the T28 colour line in the same fix commit. C19 (G5–G7 of iteration 2) has no override row; give it one (likely Defer to U1d).
- Questions I would have asked: should a git grep exit of 128 be a per-brief skip, or an exit-1 run error? The G2 assertion depends on the answer.
- Decisions I made: I treated test 4's failure in scratch copies as an environment artefact (it reads REPO_ROOT's `docs/dev-cycle.md`) and did not score it. I replaced the invalid `:!closed/` mutant (inert under `GIT_LITERAL_PATHSPECS=1`) with `--max-depth 0`.
