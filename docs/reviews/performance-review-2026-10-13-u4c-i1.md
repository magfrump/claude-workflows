Commit: 1bc823ea

# Performance Review — feat/build-loop-u4c (loop pass i1)

**Scope:** `git diff main...feat/build-loop-u4c` (6 files, +120/-209): `skills/dev-cycle/SKILL.md` "The D6 block", deleted `test/lib/d6-snippet.bash`, `test/scripts/build-loop-orchestrator.bats`, comment-only edits in `scripts/build-loop.sh` and `scripts/lib/dev-cycle-read.sh`, plan notes
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4c-i1.md` (Stage 1, k=1); override-log rows 734, 740, 741, 743, 744 (feat/build-loop-u3b3, 2026-10-12)

## Data Flow and Hot Paths

The D6 snippet is the wrapper every orchestrator call to `build-loop.sh`, `dev-cycle.sh` and (new in this diff) `questions.sh` goes through. Each call is one Bash tool turn in an LLM-driven cycle, so the path is cold relative to its caller: a tool turn costs seconds, the snippet tens of milliseconds.

Per call, the new snippet runs 7 hardened git processes (`for-each-ref refs/replace/`, `rev-parse --git-path info/grafts`, `show-ref` twice, `symbolic-ref`, `rev-parse --verify`, `cat-file -t`), each through `env`, plus one `stat` subshell per `own()` check: 4 image files and 5 directories (`/opt/claude-workflows/scripts/lib` up to `/`), so 9. None of these grows with repository size: they read refs and one object header, never history. Then one `bash` exec of the image script.

The old snippet ran the same ref checks, then `rev-parse --show-object-format`, `mktemp -d`, `mkdir`, and one perl process that walked main's whole first-parent history through `cat-file --batch` (row 740: ~34 µs per commit), then wrote four files into the temp dir. Outside claude-workflows it paid that walk and then the image-copy checks as well.

**Measured here** (this review, 2026-10-13, this worktree, main at 1138 first-parent commits, 16 cores, load average ~15 from other sessions). Snippet overhead was measured up to the exec, with the final `bash` line replaced by `exit 0`, over 3 runs of 20 calls each:

| Variant | per call |
|---|---|
| new (image copy) | 48.0 / 50.7 / 47.9 ms |
| old (claude-workflows path: perl reader walk) | 152.3 / 159.0 / 163.1 ms |
| bare `bash -c 'exit 0'` | 3.1 ms |

So the new snippet costs about **1/3 of the old one per call** (about −105 ms), and its cost is now flat: it no longer grows with main's history (row 740's 3.4 s at 100k commits no longer applies). The absolute numbers are higher than row 743's 80-100 ms because the host was loaded. The ratio is the comparable figure.

**Call frequency per cycle** (SKILL.md steps 0-10). There is a fixed set of calls: the digest (step 0), `--state` and `--main-log` (steps 0 and 9), `questions.sh init` and `archive` (step 1), `questions.sh open` (step 3), `--status` (step 7), `--settings` (steps 8 and 10), `--land-cycle`, `--cycle-diff` and `questions.sh index` and `check` (step 9). On top of that come per-item calls: in step 7 each collected branch takes `--main-log`, `--state`, `--merge`, `--approved` and `--check`, and each answer takes `--check-answer`; in steps 6 and 8 each brief takes `--check-brief`, `--check-path` and `--check-branch`. With 3 slots that is roughly 20-40 calls per cycle. That puts the saving at roughly 2-4 s per cycle, and the 4-5 `questions.sh` calls now routed through the snippet at roughly +0.25 s per cycle. Both are small next to the seconds each Bash tool turn already costs. The count is estimated from reading SKILL.md, not from a run.

**Test suite** (`bats test/scripts/build-loop-orchestrator.bats`, same host and load): branch 25/25 ok in 42 s; main (exported to a scratch dir) 28/28 ok in 40 s. The difference is within load noise. The diff removes 4 reader-path tests (each built fixtures and ran the perl walk) and adds one grep-only test. `d6_copy` now runs an awk extraction over SKILL.md plus 1-2 `sed -i` per setup, which costs milliseconds.

## Findings

#### `own()` forks one `stat` subshell per path, 9 per call

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:222` (`own()`), `:237-240` (the file loop and the directory walk)
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed process count per call) / Cold path (one call per Bash tool turn)
**Confidence:** Medium
**Baseline:** 48 ms per snippet call to the exec point, measured in this review (2026-10-13, load ~15, 16 cores); ~3 ms per bare bash fork on the same host

Evidence: `own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no ...; }` and `x="$D6_OPT/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done`. Four files plus five directories give nine `$(stat ...)` command substitutions, so nine forks and nine execs, alongside 7 git processes. One `stat -c '%u %n' -- PATH...` over all nine paths would cut 8 forks, a few ms per call on this host, or about 0.1 s per cycle. That is not worth changing: the per-path form keeps each refusal naming its own path, which tests 3 and 6 assert, and the cost does not scale with anything.

**Recommendation:** None required. If the snippet is reworked for another reason, a single `stat` over the path list is the cheaper form. Keep the per-path refusal text.

## Prior rows whose basis this diff changes

- **Row 740** (the reader's history walk, Defer; trigger "Q-140's answer, U4"): the trigger fired and the cause is gone. The diff deletes the perl reader, and per-call cost is now constant, at about 48 ms against about 155 ms measured here. It can close as resolved by U4c.
- **Row 741** (perl seam untested directly): the perl is deleted, so the row is moot.
- **Rows 734 and 743** (fork-overhead figures): superseded. The overhead no longer has a history-dependent part. Same-host figures are above.
- **Row 744** (no timeout): SKILL.md:47-49 now reads a Bash-tool timeout as a stop ("script that the Bash tool timed out, and a `refuse d6:` line, are stops too"), so its U4 trigger is met. Without the perl walk, the main remaining source of a long-running call is gone too.

## Endorsements

- The new snippet's git reads are ref- and header-level only (`for-each-ref` on `refs/replace/`, `show-ref --verify`, `symbolic-ref`, `rev-parse --verify`, `cat-file -t`), with no history walk, so per-call cost does not grow with main's commit count. [read: skills/dev-cycle/SKILL.md:226-233]
- `questions.sh` through the snippet costs about 48 ms of overhead per call. A cycle makes 4-5 such calls, about 0.25 s, small next to the Bash turns that carry them. [unverified — submitted as claim: a cycle makes at most 5 questions.sh calls (steps 1, 3, 9)]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `own()` forks one `stat` subshell per path, 9 per call | Informational | `skills/dev-cycle/SKILL.md:222, 237-240` | Medium |

## Overall Assessment

This is a performance improvement. The snippet loses its only part that grew with history, the perl first-parent walk, along with its temp-dir setup. Measured per-call overhead falls from about 155 ms to about 48 ms on the same loaded host, and the cost is now flat in main's size, which discharges row 740. Routing `questions.sh` through the snippet adds about 0.25 s per cycle, which does not matter at Bash-turn granularity. Test-suite runtime is unchanged within noise (42 s against 40 s, 25 tests against 28). Nothing needs fixing before merge. The single Informational item is optional.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/performance-review-2026-10-13-u4c-i1.md (first line `Commit: 1bc823ea`), structured per the skill.
- Answered: per-call cost of new vs old snippet (git/stat/process counts and measured ms), how often the cycle calls it including the questions.sh calls, test-suite runtime effect; prior rows 734/740/741/743/744 rechecked against the diff.
- Out of scope: security of the PATH-resolved `stat`/`git`/`env` (fact-check's overclaim item; security-reviewer's), the image-staleness consequence (a gate change runs only after a rebuild), and the plan's stale text.
- Escalate: none. The call-count estimate comes from reading SKILL.md, not from a measured cycle. A real cycle's tool log would confirm it if anyone needs the number.
