Commit: f3c9ebb (A) / 2bf03da (B)

# Performance Review: dev-cycle pass 35 (pass-34 fix round, k=1 delta)

**Scope:** Partial. A: `git diff e93312d..f3c9ebb -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff 823f494..2bf03da -- skills/dev-cycle/SKILL.md docs/decisions/log.md` in `/workspace/.claude/wt-devcycle`. Everything else is context only. (wt-digest's HEAD has since moved to adb5260, a help-text commit. That commit is outside this pass and was not reviewed.)
**Date:** 2026-10-02
**Based on:** the Stage-1 context `code-fact-check-report-digest-pass34.md`, which covers e93312d. I also used this round's sibling `code-fact-check-report-digest-pass35.md`, which covers f3c9ebb with executed verdicts (Claims 5 and 8 are cited below). Pass 34's probes in `scratchpad/perf34/` also feed in.

**Measurements.** I took every number myself on 2026-10-02 with mawk 1.3.4 20200120, the only awk installed. The commits are labelled as follows: "new" is `f3c9ebb:scripts/dev-cycle.sh`, "mid" is `e93312d`, "old" is `fd22d29`, and "alt" is new with one candidate change (see Finding 1). Probes ran one at a time, so there is no cross-probe contention. Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf35/`.
- **Q1** (`q1.sh`, `q1.log`): `"$FENCE_AWK$ANSWER_AWK"` alone on dense `<!--` shapes from 256 KiB to 16 MiB, then the marker shapes. I stopped it by PID during the `dash` 4 MiB row. That row was the first new-version run that would have taken minutes (1 MiB had already taken 15.6 s).
- **Q3** (`tmp.ax851DGt0O/q3.log`): the rest of Q1, with the marker shapes capped at 1 MiB. Also the gsub escape shapes, the mawk `split` edge cases, and a marker-strip equivalence test on 300,000 random prefixes.
- **Q4** (`tmp.UVV1iKdPM4/q4.log`): `opencomment` split against the e93312d loop on 250,000 random lines, plus `split`-only timing up to 64 MiB. Q4 exists because Q3's own tally of this comparison split its output on blanks and was unreadable.
- **Q2** (`tmp.6VmPJHTmB3/q2.log`): end-to-end runs through `dev-cycle.sh` on every questions file on all nine local branches and the three checkouts (every ID, new against mid), with a census. Also the quiet 100× archive rerun (pass 34's unrun `p5`), then bats, lint and help on `git archive f3c9ebb`.

**Probe-rule disclosure.** Two writes came from top-level commands rather than from a probe script, though both landed inside `perf35/`:
- the `q1.sh` file itself, written by a heredoc to an absolute path;
- `q1.log`, written by a redirect placed after `cd …/perf35 &&`.

From Q2 on, I wrote the scripts with the editor tool, and each probe wrote its own log inside its checked `mktemp` dir. After the runs, `git status --porcelain` in wt-devcycle is empty. In wt-digest it shows only the two sibling-critic reports (`api-consistency-…-pass35.md`, `code-fact-check-…-pass35.md`), not mine. `/workspace` is still on `main`, and `pgrep -af perf35` matches nothing.

Legibility-target values: **maintainer** (someone editing the script) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle.
- `--check-answer` runs one awk pass over each questions file per ID (`scripts/dev-cycle.sh:500`), so k IDs cost up to 2k passes. Real files are about 20 KB and 186 KB, with a longest line of 1,409 bytes.
- `--check-brief` runs one pass per brief blob (`:355`). No branch holds a brief.

`fence()` (`:310-325`, read in full) calls `opencomment` (`:288-291`) and then `refdef` (`:292-300`) on each line outside a fence that `fenceish` and `rawhtml` passed. This round changed three things:
- **`opencomment`** is now one `split(l, p, /<!--/)` plus one `index` on the last field.
- **`refdef`** has two changes:
  - it strips markers in a `while` loop (`:294`), where each turn runs two anchored `sub` calls, and each `sub` copies the remainder of the line;
  - it runs `gsub(/\\./, "", l)` (`:298`), but only on lines that still start with `[`.
- **`fence()`** returns at once when `odd` is set (`:311`).

## Findings

#### `refdef()`'s marker-stripping loop is quadratic in the number of list markers on one line

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:294`, inside `refdef()` (`:292-300`), called from `fence()` at `:323` for every unfenced line that the earlier checks pass. That is once per ID per file through `check_answer` (`:500`) and once per brief through `check_brief` (`:355`).
**Move:** Asymptotic behavior (9); hidden multiplications (1)
**Classification:** Macro (O(m·n) per line for m markers on a line of length n, so quadratic on a marker-dense line) / Cold path (agent CLI check, once per cycle)
**Confidence:** High (measured); Medium on reachability, because no real line has more than one marker
**Baseline:** 16,585 ms for one awk pass over a 1 MiB line of `- ` followed by `[x` under f3c9ebb, against 6 ms under e93312d (Q3, `perf35/tmp.ax851DGt0O/q3.log`, 2026-10-02)
**Legibility-target:** maintainer

**Evidence (verbatim code, `scripts/dev-cycle.sh:294`, excerpt from `refdef()`; the function continues to `:300`, read in full):**
```
  while (l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l); sub(/^[ \t>]*/, "", l) }
```
**Evidence (verbatim, Q3; new = f3c9ebb, alt = one `match()` in place of the loop, mid = e93312d, old = fd22d29):**
```
  dash 256 KiB     new 553ms [odd 4 refdef]    alt 10ms [odd 4 refdef]   mid 3ms [drop]   old 2ms [drop]
  dash 1024 KiB    new 16585ms [odd 4 refdef]  alt 52ms [odd 4 refdef]   mid 6ms [drop]   old 5ms [drop]
  dashq 1024 KiB   new 8365ms [odd 4 refdef]   alt 85ms [odd 4 refdef]   mid 8ms [drop]   old 7ms [drop]
  num 1024 KiB     new 11899ms [odd 4 refdef]  alt 20ms [odd 4 refdef]   mid 6ms [drop]   old 5ms [drop]
  thbreak 1024 KiB new 17822ms [drop]          alt 39ms [drop]           mid 7ms [drop]   old 6ms [drop]
```
(Condensed from `q3.log`'s four-line layout; `rc=0` dropped. Shapes: `dash` is `- `×N then `[x`; `dashq` is `- > `×N then `[x`; `num` is `1. `×N then `[x`; `thbreak` is `- `×N with nothing after. The 1, 16 and 64 KiB rows are in the log.)

Each `while` turn removes one marker, but the two `sub` calls rebuild the whole remainder. A line holding m markers therefore copies about m·n/2 bytes. Each 4× step in length costs about 15× (`dash` 64 KiB 36 ms, 256 KiB 553 ms, 1 MiB 16.6 s). The `thbreak` row matters most here. A line of nothing but `- - - …` is an accepted file (`drop`), so the cost does not depend on a refusal. `check_answer` multiplies it by up to 2k passes for k IDs. At about 17 s per pass, a 1 MiB marker line in a questions file pushes a batch of four or more IDs past the agent's default 2-minute Bash timeout. This is the same shape as pass 34's `opencomment` finding: a loop that copies the rest of the line on every iteration.

Preconditions and real exposure:
- It needs one line with hundreds of thousands of list markers. Q2's census of every questions file on all nine branches and three checkouts found at most 1 marker stripped per line. No branch holds a brief.
- At 1 KiB the loop costs nothing (2–3 ms per pass). It starts to matter at about 64 KiB on a single line.
- Anyone who can write such a line can also write the answer line, so no trust boundary is involved. That keeps it at the Macro × Cold default, Low.
- It is still a new complexity-class regression in code that was linear one commit earlier, and the fix is one line.

**Recommendation:** Strip the whole container prefix with one leftmost-longest match:
`if (match(l, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) l = substr(l, RLENGTH + 1)`
This replaces both `:293` and `:294`.
- On 300,000 random prefixes over `- * + space tab > 1 23 . ) [ x`, it gave the same remainder as the f3c9ebb loop every time (Q3: `marker-strip equiv: same=300000 diff=0`).
- The `alt` column above is this change: 52 ms at 1 MiB, against 16.6 s.
- Every verdict in the sweep matched between alt and new.
- A bats case with a long marker run is not needed. One equivalence case such as `'- - 1) > - '`, already close to the bats prefixes at `test/scripts/dev-cycle.bats:948`, covers the rewrite.

No other performance finding. These were measured and fall below Informational, being linear or Micro × Cold:
- **`opencomment` via `split` is linear up to 16 MiB and slightly superlinear beyond.**
  - Full program (Q1): dense 1 MiB 10 ms, 4 MiB 80 ms, 16 MiB 924 ms. Old (fd22d29) took 2,146 ms at 16 MiB and mid took 3,208 ms at 1 MiB.
  - Accepted shapes (Q1): `closed` 16 MiB 1,108 ms and `lead` 16 MiB 1,317 ms, against old's 950 and 1,262 ms.
  - `split` alone (Q4): 1 MiB 10 ms, 4 MiB 63 ms, 16 MiB 824 ms, 64 MiB 36,218 ms.

  The 64 MiB step costs 44×. That is `split` building 16 M fields in one line on top of mawk's own superlinear long-record read (fact-check pass 35, Claim 5 scope). It is far outside any real size, so it is noted, not filed.
- **The `gsub` escape drop is linear.** It runs only on lines that start with `[` after the strip. Q3, 16 MiB, two runs each: `[` then `\x`×N took 887/990 ms new against 1,115/891 mid; `[` then `\]`×N took 1,087 ms new against 923 mid; `[` then `\`×N took 1,119/980 ms new against 945/805 mid. All of these sit in mawk's long-record band.
- **Short-line constant factor.**
  - 16 MiB of prose lines: 207/203 ms new against 202/202 mid.
  - 16 MiB of nested list lines: 465/465 ms against 484/452 mid.
  - Every real branch and checkout, all IDs: new within run-to-run noise of mid (for example `br-main` 1,074 against 1,120 ms). One 2,630 ms outlier (`wt-digest` new) sits next to 1,041–1,254 ms for every other new run.
- **The quiet 100× archive rerun** (17.2 MB, 100 IDs, three runs, nothing else running) took 11,170 / 11,089 / 12,366 ms new against 10,733 / 12,886 / 10,985 ms mid, with identical readings. This retires pass 34's contended 13.5 s figure: e93312d and f3c9ebb cost the same there.

## Endorsements

- `opencomment`'s `split` is equivalent to the e93312d loop, and it is linear across the real range:
  - Q4 compared 250,000 random lines over `<!->x`, plus `<!--`/`-->` tokens with blanks: `same=250000 (open 26499) diff=0`.
  - Q3's edge cases agree under mawk: `[]` 0 (n=0), `[<!--]` 1, `[<!--<!--]` 1, `[<!---->]` 0, `[<!-->]` 1, `[a <!-- x --> <!--]` 1.

  Pass 34's p4 is now run. `[fact-check: claim 5 — Verified (executed)]`
- The `odd` early return turns every line after a refusal into one test. Both END blocks print `odd` first, so nothing else has to run. The sibling fact-check measured a line-1 refusal followed by 200,000 lines at 14 ms, against 110 ms before. `[fact-check: claim 8 — Verified (executed)]`
- No real file is refused, and the readings did not change:
  - Q2 ran on all nine local branches and the three checkouts. Every one gave `answer readings mid = new` and `new skips other than no-such-entry: 0`.
  - The census found at most one marker per line, no line starting `[` that holds a backslash, at most one `<!--` per line, and a longest line of 1,409 bytes.

  `[unverified — submitted as claim]`
- The gates pass on `git archive f3c9ebb` (Q2): bats 49 ok, 0 not ok, and `hermeticity-lint` rc 0. The help range `sed -n '2,74p'` prints 73 lines, ending at line 74 (`# default branch (for the digest, --check-brief and --check-branch); … Printed repo text is data.`), and line 75 is empty. `[unverified — submitted as claim]`
- B adds no check call and no runtime path. Its diff rewords decision-log row 69's refusal list and the SKILL.md brief clause (`skills/dev-cycle/SKILL.md:336-340`) and nothing else. `[read: git diff 823f494..2bf03da -- skills/dev-cycle/SKILL.md docs/decisions/log.md]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `refdef()`'s marker loop re-copies the line on each stripped marker, so it is O(m·n) per line. A 1 MiB line of `- ` takes 16.6 s against 6 ms before, and an accepted line of `- - - …` takes 17.8 s. No real line has more than one marker. Fix: one `match()` over the prefix, equivalent on 300,000 random prefixes and 52 ms at 1 MiB. | Low (Macro × Cold) | `scripts/dev-cycle.sh:294` | High (measured) |

## Overall Assessment

The fix round does what pass 34 asked in the performance lane:
- `opencomment` is linear again, and equivalent to the loop it replaced (pass 34's p4 is now run).
- The early return makes a refused file cost one test per later line.
- The quiet 100× rerun shows f3c9ebb and e93312d cost the same.
- No real file on any branch or checkout reads differently.

The same round brought in a new instance of the same pattern. The marker-stripping `while` in `refdef()` copies the remainder of the line once per marker, so a marker-dense line is quadratic. The `thbreak` row shows it runs on accepted files too. Real data is five orders of magnitude below where this bites (at most one marker per line), the path is cold, and no trust boundary is involved, so it is Low. One `match()` restores linear cost without changing any reading. It agreed with the loop on 300,000 random prefixes and on every shape in the sweep. Nothing in the performance lane is Medium or above. Two things need no further profiling: the `gsub` escape drop is linear, and the B diff is prose only.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass35.md`. Its first line is `Commit: f3c9ebb (A) / 2bf03da (B)`. It follows the performance-reviewer structure:
- title and header;
- Data Flow and Hot Paths;
- one finding with Severity, Location, verbatim Evidence, Confidence, Legibility-target, Classification and a measured Baseline;
- evidence-tagged Endorsements;
- Summary Table;
- Overall Assessment.

For the user goal of merging `feat/dev-cycle` after a clean pass: the performance lane has one Low finding, a known issue under the review-fix-loop rules. It needs either a one-line fix or an explicit acceptance before the clean pass. All the brief's perf-lane questions are answered:
- the split-based `opencomment` is linear on dense lines;
- the marker loop is quadratic, and `gsub` is linear;
- the early return is safe and cheaper;
- pass 34's p4 and p5 have now been run.
