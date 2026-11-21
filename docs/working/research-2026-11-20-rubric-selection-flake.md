# Research: flaky "emits nothing when two candidates tie" (rubric selection)

Brief: docs/working/briefs/2026-11-20-rubric-selection-flake.md
Date: 2026-11-20
Branch: fix/rubric-selection-flake (dispatched at 54f4be34)

Failure-pattern grep: `rg -n -i -e pipefail -e sigpipe -e 'grep -q' docs/failure-patterns.md` -> FP-009, FP-129, FP-175, FP-182; FP-175 (echo | grep -q SIGPIPE 141 under pipefail, flaky under load) is this bug's exact class.
Failure-pattern skip: FP-175 already records this exact symptom, cause and fix shape (pipe into grep -q under pipefail, SIGPIPE 141 under load, remove the pipe), so a new entry would only duplicate it.

## Reproduction

Reproduction: `bats -f 'emits nothing when two candidates tie' test/rubric-selection.bats`, run in a loop of 200 (probe script kept in the session scratchpad, its load processes started and stopped by PID inside the same script, under `timeout 540`).

| Run | Code | Load | Failures |
|---|---|---|---|
| tie case x200 | 54f4be34 (unfixed) | none | 0 / 200 |
| tie case x200 | 54f4be34 (unfixed) | 32 busy loops on 16 CPUs | 2 / 200 |
| forced-input cases (new) | 54f4be34 (unfixed) | none | 2 / 2 fail, every run |
| whole suite x200 | fixed | none | see "Verification" |

## Mechanism

What the tie-break reads in `select_run_rubric` (scripts/self-improvement.sh): only a score per file, the sum of a commit match (2) and a date match (1). Each point comes from `printf '%s' "$haystack" | grep -q ...`, where the haystack is the basename plus the file's content. Glob order only decides which file of a tie is held in `best`, never whether the result is a tie, and nothing reads mtimes, `ls` or `stat`. The two fixtures have the same date and commit, so their scores should both be 3.

The varying input is the exit status of the pipeline. Sourcing the script turns on `set -o pipefail`. `grep -q` exits at its first match: the date is on line 1 (the basename) and the commit on line 3. Bash line-buffers the `printf` builtin's stdout, so a multi-line haystack goes out in several writes. When the scheduler lets grep match and exit between those writes, the next write raises SIGPIPE, printf exits 141, pipefail reports the pipeline as failed, and the `if` drops the point. One fixture then scores less than the other, `ties` ends at 1, and the function prints a file. Load widens that window, which is why it showed up only once, in a loaded health check, and 2 of 200 times under 32 busy loops.

The same bug is deterministic for any rubric whose text continues past the 64 KiB pipe buffer after the match: printf has to block, grep matches and exits, and the rest of the write fails. A 1 MiB probe confirmed it (`pipe:nomatch rc=141 0` against `herestring:match`). So this was a production bug in the Gate 1h advisory cross-check as well as a test flake: under load a real rubric could lose its points and the cross-check would go "unavailable", or pick the wrong one of two candidates. The test itself was right, and the code was wrong.

## Design note (one-line, no 3-option fork)

- Fix shape: feed grep from a here-string (`grep ... <<< "$haystack"`), so the status is grep's own and no writer can die of SIGPIPE. Other options: bash `[[ =~ ]]` (it would need `nocasematch` toggling and a port of the ERE), or grepping the file plus the basename separately (two greps per point). The here-string dominates because it keeps the same regexes and is the smallest change that `git revert` undoes. This is the same fix shape FP-175 used (remove the path). Path A.

## Change

- scripts/self-improvement.sh: both scoring greps now read a here-string, with a comment on why. A comment at the tie-break says what decides a tie.
- test/rubric-selection.bats: a `mk_big_rubric` helper (a 1 MiB body after the matching lines) and two cases. One is a tie where one candidate is large, which must emit nothing. The other is a lone large match, which must be selected. Both fail on 54f4be34 every run and pass on the fix.

Out of scope: other `printf | grep -q` pipelines in the self-improvement loop (the brief excludes any other change there). `rg -n "printf '%s' \"\\$[a-z_]*\" \| grep -q" scripts/` is the follow-up search for the cycle.

## Verification

Filled in below.
