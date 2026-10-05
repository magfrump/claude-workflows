Commit: 2da477b7

# Performance Review — feat/build-loop-u1a (U1a, review-fix iteration 2)

**Scope:** `git diff main...feat/build-loop-u1a` (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats)
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check summary (`/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/shared/fc-summary.md`; full report `docs/reviews/code-fact-check-report-build-loop-u1a.md`)

## Data Flow and Hot Paths

The changed code is the shared reader lib's check modes, invoked from `scripts/dev-cycle.sh`'s check-mode loop (`for a in "${CHECK_ARGS[@]}"`, dev-cycle.sh:195-205), once per argument and once per dev-cycle step. That is a **cold path**: a CLI run a few times per dev cycle, which the user starts by hand. There is no request handler or high-frequency loop.

- `check_answer` (dev-cycle-read.sh:534-560) now, for each question ID and for each of the two files, runs `main_entry` (one `git ls-tree -t --full-tree` in a `$(...)` subshell), then `git cat-file blob | awk` over the whole blob. On this repo's main the blobs are questions.md 32,991 B and questions-archive.md 188,668 B.
- `check_brief` (:309-) replaces its old `ls-tree | cut` with `main_entry`, and replaces its inline awk with `brief_fields` (:281-300). That is one `cat-file | awk` pass over the brief plus a bash loop over at most 6 output lines.
- `FENCE_AWK` gains one `index(l, "\0")` per input line (:216).
- `main_entry`'s ls-tree lists each named directory's children (docs/ 11 entries, docs/working/ 37 entries on main). This is settled as Won't-Fix (override row 220), and the review does not re-raise it.

I measured both readers in my scratch dir: main's reader came from `git show main:scripts/{dev-cycle.sh,lib/dev-cycle-read.sh}`, and the branch's reader ran at 2da477b7, both against this repo's main (mawk, `LC_ALL=C.UTF-8`, wall-clock `time`):

| Run | main's reader | branch reader |
|---|---|---|
| `--check-answer` × 20 archived IDs | 0.242 s | 0.230 s |
| `--check-answer Q-001` (×3) | 0.024–0.025 s | 0.024–0.025 s |
| `--check-brief` × 3 briefs on main (×2) | 0.043–0.044 s | 0.049–0.050 s |

Outputs were byte-identical for the brief run. The answer run differs in content only by design, because it now reads main instead of the working tree.

## Findings

#### check_answer re-lists and re-reads both questions files for every ID

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:538-547`
**Move:** Count the hidden multiplications
**Classification:** Macro (O(IDs × archive bytes); the per-ID re-read predates this diff) / Cold path (a dev-cycle CLI check mode, run about once per cycle with a handful of IDs)
**Confidence:** High
**Baseline:** 0.230 s wall clock for `--check-answer` over 20 IDs against this repo's main (archive 188,668 B), measured in the reviewer's scratch dir on 2026-10-05; main's working-tree reader took 0.242 s for the same IDs.
**Evidence:**
```
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
...
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"
```
(excerpt ends at :547; the enclosing check_answer() continues to :560, which I read)

**Legibility-target:** for-orchestrator-synthesis

Each ID now costs 2 `ls-tree` and 2 `cat-file` forks, plus 2 full awk passes over about 222 KB. The two files and `MAIN_SHA` are the same for every ID in one invocation. Before this diff the reader already scanned the whole file once per ID, so the asymptotic shape is unchanged, and the measured total is flat (no regression). The archive grows without a bound (it is append-only), so the cost per ID grows with it, and per-call cost scales linearly with archive size × IDs. At today's scale this is about 11 ms per ID, which does not matter on a cold path. This is a forward note only. It would matter if a U1b/U1c consumer called `check_answer` per poll or per brief in a loop. That consumer is not part of this diff, and this report does not flag its absence.

**Recommendation:** No change is needed for U1a. If a later consumer calls this in a loop, resolve `main_entry` and the blob once per file per invocation (outside the per-ID loop), or pass all IDs to one awk pass. Re-measure against the 0.230 s / 20-ID baseline above.

#### check_brief pays about 2 ms more per brief for main_entry's subshell and brief_fields' bash loop

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:320`, `:286-299`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (one extra `$(...)` subshell plus a ≤6-iteration read loop per brief) / Cold path (a `--check-brief` CLI run once per cycle)
**Confidence:** Medium (wall-clock noise at the millisecond scale)
**Baseline:** 0.049–0.050 s for `--check-brief` over the 3 briefs on main, against 0.043–0.044 s for main's reader, measured in the reviewer's scratch dir on 2026-10-05.
**Evidence:**
```
  e="$(main_entry "$a")"
```
```
  while IFS= read -r l; do
```
(the second excerpt ends at :293; the enclosing brief_fields() continues to :300, which I read)

**Legibility-target:** for-orchestrator-synthesis

The process count per brief is unchanged: one `ls-tree` and one `cat-file | awk`. The increase comes from the bash subshell and the assoc-array loop. A difference of 6 ms on 3 briefs, in a command run once per cycle, is below any threshold that matters. I recorded it so the next pass has a number to compare against.

**Recommendation:** None. This is a coverage note.

## Escalations received

None of the Stage-1 escalations is addressed to the performance critic:

- Escalation 1 (portability of `"\0"`) is a correctness concern. If `"\0"` were empty, the check would refuse every line, which is fail-closed. The CPU cost of the check is the same either way.
- Escalation 3 belongs to security-reviewer.
- Escalations 2 and 4 belong to the orchestrator and test-strategy.

I found nothing that contradicts override rows 201, 208, 213, 215, 220 or 221.

## Endorsements

- brief_fields keeps check_brief's parse at one `git cat-file blob | awk` pass per brief with no early exit, the same pipeline shape as the inline awk it replaces. `[read: scripts/lib/dev-cycle-read.sh:286-292]`
- The NUL refusal adds one `index()` per input line inside `fence()`, which is a constant cost per line. `[read: scripts/lib/dev-cycle-read.sh:216]`
- Claim: on this repo's main, the branch's `--check-answer` (20 IDs) and `--check-brief` (3 briefs) run within ±15% of main's reader's wall clock, with identical check_brief output. `[unverified — submitted as claim]` (route: code-fact-check; probe: run both readers as described under Data Flow)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | check_answer re-lists and re-reads both questions files per ID (forward note for loop consumers) | Informational | `scripts/lib/dev-cycle-read.sh:538-547` | High |
| 2 | check_brief about 2 ms more per brief (subshell + read loop) | Informational | `scripts/lib/dev-cycle-read.sh:320`, `:286-299` | Medium |

## Overall Assessment

This diff carries no meaningful performance risk. Every changed path is a cold CLI check mode. Reading answers from main instead of the working tree took 0.230 s for 20 IDs, against 0.242 s for main's reader, and check_brief gained about 2 ms per brief. The one structural shape worth remembering is check_answer's O(IDs × archive size) re-read with per-ID git forks. It predates this diff and is harmless at today's 189 KB archive. It becomes relevant only if a U1b/U1c consumer calls it in a polling loop. The ls-tree directory listing cost is settled (row 220). No profiling is needed before merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path given in your tail, structured per your skill, with `Commit: 2da477b7` as its first line.
- Answered: performance review of the full `main...feat/build-loop-u1a` diff at 2da477b7, with measured baselines comparing main's reader and the branch reader; two Informational findings, no blocking issues.
- Out of scope: correctness or portability of `"\0"` (escalation 1), test-strength issues (escalation 2), the set -e behavior of brief_fields (escalation 3, security), the digest's questions readers (escalation 4), and U1b/U1c consumers.
- Escalate: none. Finding 1 is a forward note for whoever writes U1c's `--status`, in case it calls check_answer per poll.
