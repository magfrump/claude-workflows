# Research: flaky "emits nothing when two candidates tie" (rubric selection)

Brief: docs/working/briefs/2026-11-20-rubric-selection-flake.md
Date: 2026-11-20
Branch: fix/rubric-selection-flake (dispatched at 54f4be34)

Failure-pattern grep: `rg -n -i -e pipefail -e sigpipe -e 'grep -q' docs/failure-patterns.md` -> FP-009, FP-129, FP-175, FP-182. FP-175 (a load-only flake from `echo | grep -q` dying with SIGPIPE 141 under pipefail) has this bug's mechanism, cause and fix.
Failure-pattern skip: FP-175 already records this mechanism, cause category and fix shape (a pipe into grep -q under pipefail, SIGPIPE 141 under load, fixed by removing the pipe); only the writer (printf, not echo) and the symptom differ, so a new entry would duplicate it.

## Reproduction

Reproduction: `bats -f 'emits nothing when two candidates tie' test/rubric-selection.bats`, run in a loop of 200. The probe script was kept in the session scratchpad. It started and stopped its load processes by PID inside the same script, under `timeout 540`.

| Run | Code | Load | Failures |
|---|---|---|---|
| tie case x200 | 54f4be34 (unfixed) | none | 0 / 200 |
| tie case x200 | 54f4be34 (unfixed) | 32 busy loops on 16 CPUs | 2 / 200 |
| the two new forced-input cases | 54f4be34 (unfixed) | none | fail every run (also 5/5 per reviewer replicate) |
| tie case x200 | fix | 32 busy loops on 16 CPUs | 0 / 200 |
| whole suite x200 in a row | fix | none | 200 / 200 passed |

The review's fact-checkers independently reproduced the race on the bare pipeline at 3-8 losses in 2000 tries.

## Mechanism

The tie-break in `select_run_rubric` (scripts/self-improvement.sh) reads only a score per file: 2 for a commit match plus 1 for a date match. Each point comes from `printf '%s' "$haystack" | grep -q ...`, where the haystack is the basename followed by the file's content. Glob order decides only which file of a tie is held in `best`, never whether the result is a tie. Nothing reads mtimes, `ls` or `stat`. The two fixtures share a date and a commit, so both should score 3.

What varies is the exit status of that pipeline. Sourcing the script turns on `set -o pipefail`, and `grep -q` exits at its first match. The date is on haystack line 1 (the basename). The commit is on haystack line 4 (file line 3).

Bash line-buffers the `printf` builtin's stdout. A haystack without a trailing newline therefore goes out in two writes: everything up to the last newline, then the unterminated tail. When the scheduler lets grep match and exit between those two writes, the second write raises SIGPIPE. printf exits 141, pipefail reports the pipeline as failed, and the `if` drops the point. One fixture then scores less than the other, `ties` ends at 1, and the function prints a file. Load widens that window. That is why the failure appeared once in a loaded health check and 2 of 200 times under 32 busy loops.

When much text follows the match, the same bug hits without load. printf blocks on the full pipe, grep matches and exits, and the rest of the write fails. The reviewers measured the threshold on this host. With 64-128 KiB after the match, the point was lost in 0-20% of runs. From about 128 KiB on, it was lost every time. A 1 MiB probe lost it every time (`pipe:nomatch rc=141 0`, against `herestring:match`). A match that comes after the large body keeps its point.

So this was also a production bug in Gate 1h's advisory rubric cross-check. Under load, or with a large rubric, a real rubric could lose its points. The cross-check would then go "unavailable" or pick the wrong one of two candidates. The test was right; the code was wrong.

## Design note (one-line, no 3-option fork)

- Fix shape: feed grep from a here-string (`grep ... <<< "$haystack"`). The exit status is then grep's own, and no writer can die of SIGPIPE.
- Alternatives were bash `[[ =~ ]]`, which needs `nocasematch` toggling and a port of the regex, and grepping the file and the basename separately, which takes two greps per point.
- The here-string wins outright. It keeps the same regexes, and it is the smallest change `git revert` undoes. It is also the fix shape FP-175 used (remove the path). Decision: Path A, one option dominates.

## Change

- scripts/self-improvement.sh: both scoring greps read a here-string, with a comment saying why. A comment at the tie-break says what decides a tie.
- test/rubric-selection.bats: a `mk_big_rubric` helper puts a 1 MiB body after the matching lines, and two new cases use it. One is a tie where one candidate is large, which must emit nothing. The other is a lone large match, which must be selected. Both fail on 54f4be34 every run and pass on the fix. They pin the lost-point bug through the full pipe, not the small-file timing race. Only the original tie case covers that race. With the fix, a 1 MiB here-string takes bash's temp-file path; the pipe path that small rubrics take is the one the original tie case covers.
- Wording note: the first commit's body (45553ee7) says a large rubric lost points "(always)" past 64 KiB. The measured threshold is the one above. The commit was not amended, because this branch only adds commits.

Out of scope: the brief excludes any other change to the self-improvement loop. Sibling pipe-into-`grep -q` sites the reviewers found (line numbers as of 45553ee7): scripts/self-improvement.sh:823, :1512 and :1830, and scripts/lib/si-functions.sh:110, :241, :253, :290, :320 and :327. Also out of scope: hooks/claude-config-audit.sh:112.

`rg -n -e "printf '%s' .*\| *grep -q" -e "echo .*\| *grep -q" scripts/` (single-quoted in the shell) finds the echo-on-one-line ones. The rest need reading by hand.

## Verification

- `test/rubric-selection.bats` passed 200 times in a row on the fix: a scratch loop running `bats test/rubric-selection.bats` that stops at the first failure.
- Touched suites passed via `scripts/run-tests.sh`. The suites run were rubric-selection, round-log-functions, validate-task-json, claude-headless-flags, function-inventory, convergence-detection, code-review-gate, si-clean-state, worktree-cleanup-functions and q125-verify-check.
- `scripts/hermeticity-lint --root .`: exit 0 (150 test files, no unstubbed network spawns).
- `scripts/confine-tests.sh --probe`: exit 3, first line "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." Following the brief, I relied on run-tests.sh plus the lint.
- `scripts/health-check.sh` on the branch: exit 0, "All checks passed." Every load process had been stopped by PID before it ran.

## Review (pr-prep review-fix loop)

- Iteration 1 (code-review: three fact-check replicates plus security and performance critics). Result: 0 Must Fix, 7 Must Address, 4 Consider. All Must Address items were wording, and all were fixed in the follow-up commit:
  - an empty Verification section
  - the 64 KiB claim
  - a broken rg command
  - "several writes" (it is two writes)
  - the commit's line number
  - the test comment's claim
  - the FP-175 "exact" claim
- Consider C1, kept as residual risk: for a haystack of 64 KiB or more, bash writes the here-string to a temp file. If it cannot create that file (no writable TMPDIR, or out of file descriptors), the redirect fails with status 1, which reads as "no match". The point is dropped, as before the fix, and bash prints a message to stderr. The selection is advisory, so no gate verdict changes. If the Gate 1h cross-check is ever made fail-closed (constraint H2: gates fail closed and loudly), it should first treat a grep status above 1 as "selection unavailable".
- C2 and C3 (performance): no action. On the real archive the new code is faster, and the 1 MiB fixtures add no measurable suite time.
- C4: notes only.
