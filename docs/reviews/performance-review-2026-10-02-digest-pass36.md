Commit: dd1988d (A) / d39c8f2 (B)

# Performance Review — feat/dev-cycle-digest, loop pass 36 (pass-35 fix round)

**Scope:** Partial. A: `git diff f3c9ebb..dd1988d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff 2bf03da..d39c8f2 -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle`. Everything else is context only (rubric section "Pass 35").
**Date:** 2026-10-02
**Based on:** the shared brief `digest-pass36-brief-dc1aa358.md`, plus its Stage-1 context `docs/reviews/code-fact-check-report-digest-pass35.md`. That is the pass-35 fact-check. The pass-36 fact-check (`code-fact-check-report-digest-pass36.md`) landed while I was writing. Its Claim 6 (Verified, executed) found the match exactly equivalent to the old loop and linear, and its result agrees with mine. Every other runtime claim below rests on my own probes (P1–P4), which are listed at the end.

## Data Flow and Hot Paths

Under review, `FENCE_AWK` is the awk reader that `--check-brief` and `--check-answer` run over each questions file or brief, one line at a time. The only code change in this round is in `refdef(l)` (`scripts/dev-cycle.sh:293-303` at dd1988d). It used to strip leading markers with a `sub()` loop. It now uses one anchored match:

```
  if (match(l, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) l = substr(l, RLENGTH + 1)
```

The rest of the A diff is help text plus a help range change from `2,74p` to `2,75p`. B is skill prose and has no performance surface.

**Path temperature: cold.** This is a CLI check mode that the dev-cycle skill runs a few times per cycle. Real inputs are questions files of roughly 100–200 KiB with ordinary line lengths. The worst realistic line is a few hundred bytes. The only inputs that reach the multi-MiB-line regime are adversarial or corrupt files.

Here is what each check found:

- **Old loop (f3c9ebb).** It rebuilt the line once per marker, which made it quadratic in the number of markers. I re-measured it in this pass: at 1 MiB it took 14.8 s (`- ` × N), 19.2 s (a line of only `- ` markers) and 12.4 s (mixed markers followed by 1000 digits).
- **New match (dd1988d).** The same rows took 58 ms, 49 ms and 56 ms. The scaling trend is linear: across 2 to 32 MiB the full reader tracks mawk's own cost of reading the line. Timings jitter heavily (see Finding 1).
- **Equivalence.** The new match gives the same stripped result as the old loop on all 400,020 random and adversarial prefixes (seed 36), with 0 differences. The alphabet covered blanks and tabs between markers, `>` between markers, digits without `.`/`)`, markers with no following blank, `--`, `**`, `- `, `1. ` and `> `. A hand list added the empty line, a lone `-`, `1.`, `1.x`, `1 . x`, `>-  [x`, `-\t\t>[x` and `1234567890. [x`.
- **Real files.** I ran dd1988d and f3c9ebb over 9,713 files: every tracked `.md` on every local branch of /workspace, plus the working `questions.md` and `questions-archive.md` in all three checkouts. Every verdict was identical. The tally was 4,649 ok, 4,548 ok with a fence, 274 fence, 99 refdef, 79 html and 64 comment, the same under both commits. The total was 20.6 s new against 23.3 s old, which is mostly process start. None of the six working questions files is refused.
- **The other FENCE_AWK functions on long lines.** All of them scale with mawk's own line read. I measured 1, 4 and 16 MiB as one row each, and the ratios between sizes match the bare read's:
  - `run()`, `opens()` and `closes()` on a 16 MiB backtick line, and on a `~` line inside a fence: 2.0 s and 2.3 s.
  - `fenceish()` on 16 MiB of blanks followed by ```` ``` ````: 2.0 s.
  - `rawhtml()` and `opencomment()` on a 16 MiB one-line comment: 1.9 s.
  - `refdef()`'s `gsub` on a 16 MiB unclosed `[`: 2.7 s.
  - 16 MiB of prose: 1.7 s.
  - For comparison, the bare read alone took 0.7 s at 16 MiB and 4.8–6.3 s at 32 MiB, so mawk's line buffer itself grows superlinearly here.

  None of the per-line work is superlinear beyond that. Pass 35 already showed that `split()` in `opencomment` is linear (fc35 P3/P4, 16 MiB dense in 1,231 ms).

## Findings

#### mawk's `match()` on the starred alternation is linear but jittery, and one 32 MiB run did not finish in 120 s

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:296` (dd1988d), inside `refdef(l)`, lines 293-303. I read the whole function, and its value flows to `fence()` at `:323`.
**Evidence (verbatim):** `if (match(l, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) l = substr(l, RLENGTH + 1)`
**Move:** 9 (asymptotic behaviour); 2 (size of N)
**Classification:** Micro (constant-factor variance, not a complexity class) / Cold path (a CLI check over files of about 100 KiB)
**Confidence:** Medium. The trend is clearly linear. The cause of the jitter, and the one timeout, are not established.
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** maintainer

I ran the match alone on one line of `" \t"` × N. At 16 MiB it took 6.5–12.6 s over three repetitions. The full reader, which runs the same match, took 2.4 s on the same input every time. At 32 MiB it took 7.4–10.6 s in three repetitions (P4), but an earlier single run timed out at 120 s (P3, rc 124). I could not reproduce that timeout. Neither result is quadratic: doubling the line from 16 to 32 MiB never more than doubled the time once the bare read's own growth is accounted for. Every input at or below 4 MiB finished in about 1.3 s or less. These inputs are adversarial single lines of 16 MiB or more. No real file comes within four orders of magnitude of that.

**Recommendation:** None needed for merge. If a size guard is ever wanted for hostile inputs, a byte cap on the file read is cheaper than tuning the regex. Do not reintroduce a per-marker loop.

## Endorsements

- The pass-35 Low (quadratic marker loop) is fixed. At 1 MiB, the new reader is 58 ms against the old 14,840 ms on `- ` × N, and 49 ms against 19,222 ms on a line of only markers (P1, mawk 1.3.4). `[fact-check: claim 6 — Verified]`
- The new strip agrees with the old loop on every one of 400,020 random and adversarial prefixes, with 0 differences (P1). `[unverified — submitted as claim]` (I executed this, but no fact-check verdict from this round backs it yet.)
- No verdict changes on 9,713 real `.md` files across all local branches and the three checkouts, and no working questions file is refused (P2). `[unverified — submitted as claim]`
- No other FENCE_AWK function is superlinear on long lines beyond mawk's own line read (P1 rows ticks, tildes, fenceish, lthtml, bracket and prose). `[unverified — submitted as claim]`
- B (`skills/dev-cycle/SKILL.md:335-343`) is prose only and adds no runtime work. `[read: skills/dev-cycle/SKILL.md diff 2bf03da..d39c8f2]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `match()` linear but jittery on 16 MiB+ adversarial lines; one 32 MiB run timed out and did not reproduce | Informational | `scripts/dev-cycle.sh:296` | Medium |

## Overall Assessment

The fix does what it says. The quadratic marker strip is gone, and its replacement scales linearly, give or take mawk's jitter. On the shapes that cost 12–19 s per MiB before, it is two to three orders of magnitude faster. It gives the same output on 400k fuzzed prefixes and the same verdict on every real file. No other function in FENCE_AWK is superlinear on long lines. **This pass finds no known performance issue:** 0 Critical, High, Medium or Low, and one Informational that needs no action. On the performance axis, nothing blocks moving to the k=1 full review. I did not run the gates (bats and the hermeticity lint); they are the fact-check stage's to verify.

## Probe provenance

All probes are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf36/`. Each one was written with the Write tool. Each began with `set -eu`, created its own `mktemp -d -p perf36` dir, `cd`'d into it and checked `case "$PWD"` before any write. Every generator and awk ran under `timeout`. Inside the worktrees they ran only `git show` / `ls-tree` / `for-each-ref`, and the only worktree write is this report. The engine was mawk 1.3.4 20200120, the only awk installed. The machine had other sessions' probes running at the same time, so the timings are noisy.

- **P1** `p1.sh` → `tmp.fC8jrKcu7d/p1.log`: 19 long-line shapes at 1, 4 and 16 MiB through FENCE_AWK+ANSWER_AWK at dd1988d (with f3c9ebb at 1 MiB); the match alone at 4–64 MiB; the 400,020-line equivalence fuzz.
- **P2** `p2.sh` → `tmp.Jd9g2IjSGR/p2.log`: FENCE_AWK verdicts on 9,713 real files, dd1988d against f3c9ebb.
- **P3** `p3.sh` → `tmp.FhOCE3BENO/p3.log`: the bare read, the match alone, a class-only match, the old `sub` and the full reader, for `>`, blank, dash and marker-only lines at 2–32 MiB.
- **P4** `p4.sh` → `tmp.R5WYAJY5SP/p4.log`: three repetitions of the bare read, the match and the full reader on blank lines at 16 and 32 MiB, as a re-run of P3's outlier.

## Goal-Alignment Note

The success criterion, verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass36.md` with the required first line. It follows the performance-reviewer structure: data flow, findings with a baseline and a classification, evidence-gated endorsements, a summary table and an overall assessment. It also answers the brief's two questions. First, the single-match strip is linear on lines of markers and on long ordinary lines. Second, no other FENCE_AWK function is superlinear on long lines beyond mawk's own line read. Nothing was committed.
