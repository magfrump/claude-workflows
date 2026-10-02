Commit: e93312d (A) / 823f494 (B)

# Performance Review: dev-cycle pass 34 (pass-33 fix round, k=1 delta)

**Scope:** Partial. A: `git diff fd22d29..e93312d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` (commits 5630135, 0db12bd, e93312d). B: `git diff 5085e64..823f494 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` in `/workspace/.claude/wt-devcycle`. Merge ba93f23 carries the same script and bats file as e93312d (`git diff e93312d ba93f23 --stat` on both paths is empty). Everything else is context only.
**Date:** 2026-10-02
**Based on:** the Stage-1 context `code-fact-check-report-digest-pass33.md`, which covers fd22d29 (the base of this delta), not e93312d. Pass 33's numbers and probes in `scratchpad/perf33/` also feed in. No fact-check covers e93312d, so every runtime endorsement below is tagged `[unverified — submitted as claim]`.

**Probe incident (reported first, as the brief requires).** One of my shell commands wrote a file outside my scratch dir. It ran `cd $S/perf34 && … ; timeout 900 bash p5.sh > p5.log` with a doubled path, so the `cd` failed. The `;`-joined second command then ran in the session cwd, `/workspace/.claude/wt-devcycle`, and its redirect created the untracked file `p5.log` there (108 bytes: the setlocale warning plus `bash: p5.sh: No such file or directory`). Nothing ran against git and nothing else was written. I confirmed the contents were exactly that and deleted the file. After that, `git status --porcelain` is empty in both worktrees, `/workspace` is still on `main`, and `pgrep -af perf34` matches nothing. The cause was a top-level command that was not a probe script. Every probe script (P1–P3) followed the rule. I stopped probing after the incident, so the planned P4 (a linear replacement and its equivalence test) and P5 (a quiet rerun of the 100× archive) were written but never ran. Both sit in `perf34/` without logs.

**Measurements.** I took all numbers myself on 2026-10-02, using mawk 1.3.4 20200120. "new" is `git show e93312d:scripts/dev-cycle.sh` and "old" is `fd22d29:…`, interleaved in the same loops. P1 and P2 ran at the same time, so absolute times carry contention noise. Only old/new pairs within one loop are comparable. Scratch is in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf34/`.
- **P1** (`p1.sh`, `p1.log`) runs end to end on every ID in the questions files of all nine local branches and the three checkouts. It also takes a census of the lines the new checks look at, and runs the real archive at 1×, 10× and 100×.
- **P2** (`p2.sh`, `p2.log`) runs `"$FENCE_AWK$ANSWER_AWK"` alone, sweeping long lines full of `<!--` from 16 KiB to 4 MiB, plus `[`/`>`-prefix shapes and controls at 1 and 16 MiB.
- **P3** (`p3.sh`, `p3.log`) reruns the perf33 p3/p4 shapes end to end, times an early refusal followed by 16 MiB, and runs the gates on `git archive e93312d`.

Legibility-target values: **maintainer** (someone editing the script) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle.
- `--check-answer` runs one awk pass over each questions file per ID (`scripts/dev-cycle.sh:493`), so k IDs cost up to 2k passes. Real files are about 20 KB and 186 KB.
- `--check-brief` makes one pass per brief blob (`:348`). No branch holds a brief.

`fence()` (`:304-318`, read in full) calls `opencomment` and `refdef` on every line outside a fence that `fenceish` and `rawhtml` did not already refuse. A line that starts `<!--` and also holds `-->` passes `rawhtml`, so it reaches `opencomment` too. `refuse()` records only the first offending line, but awk keeps calling `fence()` on every later line. A file that has already been refused therefore still pays both checks on every line after the refusal.

- **`opencomment` (`:284-287`), new.** `i = 0; while ((j = index(substr(l, i + 1), "<!--")) > 0) i += j`. Each iteration copies the whole remainder of the line with `substr` and scans that copy. With k occurrences of `<!--` on a line of length n, the cost is O(k·n), which is quadratic when the line is dense with them. The old version made one `index` call and at most one copy.
- **`refdef` (`:288-294`), new.**
  - one anchored `sub` that strips `[ \t>]*`;
  - one anchored list-marker test, plus two more `sub` calls when a marker matches;
  - `substr(l, 1, 1)`;
  - at most two `index` scans.

  Each of these is linear in the line. The old version was a single anchored regex.

## Findings

#### `opencomment()`'s last-`<!--` loop is quadratic in the number of `<!--` on one line

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:284-287`, called from `fence()` at `:315`, once per ID per file through `check_answer` (`:493`) and once per brief through `check_brief` (`:348`)
**Move:** Asymptotic behavior (9) and hidden multiplications (1)
**Classification:** Macro (O(k·n) per line, quadratic for a dense line) / Cold path (agent CLI check, once per cycle)
**Confidence:** High (measured); Medium on reachability, because no real file comes near the cliff
**Baseline:** 89,399 ms for one awk pass over a 4 MiB line of `<!--` under e93312d, against 54 ms under fd22d29 (P2, `perf34/p2.log`, 2026-10-02)
**Legibility-target:** maintainer

**Evidence (verbatim, P2, `"$FENCE_AWK$ANSWER_AWK"` alone, one run each):**
```
  dense 256 KiB    old 3ms [odd 4 comment]    new 138ms [odd 4 comment]
  dense 1024 KiB   old 7ms [odd 4 comment]    new 3342ms [odd 4 comment]
  dense 4096 KiB   old 54ms [odd 4 comment]   new 89399ms [odd 4 comment]
  spaced 4096 KiB  old 64ms [odd 4 comment]   new 67928ms [odd 4 comment]
  closed 4096 KiB  old 48ms [drop]            new 30889ms [drop]
  lead 4096 KiB    old 51ms [drop]            new 39465ms [drop]
```
(Lines condensed from `p2.log`'s two-line layout. Shapes: `dense` is `a` followed by `<!--` repeated; `spaced` is `a ` followed by `<!-- ` repeated; `closed` is `a ` followed by `<!-- x --> ` repeated; `lead` is `<!-- x -->` repeated from column 0. The two 16 and 64 KiB rows for each shape are also in the log.)

Each 4× step in line length costs about 24–27× in time, which is quadratic with a cache penalty on top. The `closed` and `lead` rows show the cost does not depend on a refusal. A file the reader accepts, with every comment closed (`drop`), still takes 31–39 s at 4 MiB. Because `fence()` keeps running after `refuse()`, the cost is also paid on a file that is already refused. `check_answer` makes one pass per ID per file, so a batch of k IDs multiplies the cost by up to 2k. A 4 MiB line would push one call past the agent's default 2-minute Bash timeout once k is 2 or more.

Preconditions and real exposure:
- The cliff needs a single line holding hundreds of thousands of `<!--`. Real data has none. P1's census of every questions file on all nine branches and three checkouts found at most 1 `<!--` per line, 4 such lines per file, and a longest line of 1,409 bytes. No branch holds a brief.
- Interpolating the measured curve, a whole 186 KB archive written as one dense line would cost about 0.1 s per pass. The quadratic only starts to matter around 1 MiB on one line.
- Whoever can write such a line can also write the answer or Status line, so there is no trust boundary to cross. That keeps this at Low, the Macro × Cold default, rather than the "large data" escalation.
- It is still a new complexity-class regression in code that was linear one commit earlier. The fix costs nothing.

**Recommendation:** Find the last `<!--` without re-copying the remainder each time. For example:
`function opencomment(l,   n, p) { n = split(l, p, /<!--/); return n > 1 && !index(p[n], "-->") }`
- `<!--` cannot overlap itself (no proper prefix of it equals a suffix), so `split`'s last field is exactly `substr(l, i + 4)` from the current code.
- `split` is a single linear pass.

My equivalence and timing probe for this candidate (`perf34/p4.sh`: 200,000 random lines over `<!->x`, plus dense lines up to 16 MiB) was written but not run, because of the incident above. The equivalence claim is therefore `[unverified — submitted as claim]` until someone runs it. The bats case `a <!-- x --> b <!--` (second-comment) would cover the fix.

No other performance finding. These were measured and are below Informational (Micro or linear, cold path):
- **`refdef` long lines are linear and often faster.** Over 16 MiB single lines, P2 measured these (old → new, two runs each):
  - `[`×N: 1,305/1,276 → 788/1,102 ms. This is now refused at once, where old read to the end.
  - `[` followed by `x]:`×N: 758/806 → 781/815 ms.
  - `> `×N followed by `[x]: /u`: 775/1,148 → 1,178/1,102 ms.
  - `- ` followed by `> `×N and `[x`: 674/742 → 1,167/1,354 ms.

  The 1 MiB rows run 5–31 ms. Every shape stays within mawk's existing long-record band from pass 33, so there is no backtracking cliff.
- **Short-line constant factor.**
  - 16 MiB of short prose lines: 174/177 → 207/211 ms (+19%).
  - 16 MiB of short lines that each hold one closed comment: 597/590 → 786/721 ms.
  - One ID against the 17 MiB archive: 101–120 → 129–136 ms.
  - At real size (186 KB archive, 100 IDs): 1,075 → 1,085 ms.
  - Every branch and checkout: old/new within run-to-run noise (for example `br-main` 1,330/1,328 against 1,423/1,317 ms).
  - The one large delta, 100× archive with 100 IDs at 9,049 → 13,513 ms, ran while P2 was spending 30–90 s on its 4 MiB dense rows. Pass 33 measured +12 ms per ID on the same set. The quiet rerun (`p5.sh`) did not run (see the incident), so treat that figure as contended and not as a baseline.

## Endorsements

- The widened `refdef` refuses no real file. On all nine local branches and all three checkouts, `answer readings old = new` and `new skips: 0` (P1). The census lists the real lines that hold `]:` without starting `[`, which `refdef` correctly passes. Examples: `**Answered 2026-09-23: [2], exempt …`, the index table rows `| [Q-088](#q-088--…) | agent | Spike, per Q-081 [2]: …` and the prose lines `Spike, per Q-081 [2]: …` and `Implement Q-083 [1]: …` (5 per file). The only lines that start with `[` after the strip are `[confidence: high], …` and `[1] was rejected …`, and neither holds `]:` or leaves its `[` open. `[unverified — submitted as claim]`
- The pass-33 shapes now behave as the brief says (P3, end to end):
  - perf33 p4's `escaped`, `mlabel` and `openlbl` changed from `drop Q-1` to a `starts like a link reference definition` skip;
  - `- [x]: /u`, `> [x]: /u`, `1. > [x]: /u`, `[a` and `a <!-- x --> b <!-- y` are now refused;
  - `- [ ] a task`, `- [x] done: yes`, `See [x]: here`, `[x] not a definition`, a fenced `[x]:` and a closed mid-line comment still read `keep`.

  `[unverified — submitted as claim]`
- An early refusal costs one ordinary pass, the same as before. With a refused line 2 followed by 16 MiB of prose, new took 149–167 ms and old 128–139 ms, against 130–170 ms for the unrefused control (P3). `[unverified — submitted as claim]`
- The gates pass on `git archive e93312d` (P3):
  - bats: 49 ok, 0 not ok;
  - `hermeticity-lint` rc 0;
  - shellcheck rc 0.

  The help range `sed -n '2,71p'` is exact: it prints 70 lines, the last being line 71 (`# default branch (for the digest, …) … Printed repo text is data.`), and line 72 is empty. `[unverified — submitted as claim]`
- B adds no check call. Its diff only rewords the brief clause and the final message ("printed a skip") and log 69. The final message reuses the `--check-brief` output each cycle already produces. `[read: skills/dev-cycle/SKILL.md diff 5085e64..823f494]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `opencomment()`'s last-`<!--` loop re-copies the line's remainder on each match. That is O(k·n) per line: 4 MiB of `<!--` takes 89 s against 54 ms before, and an accepted file of closed comments takes 31–39 s. No real line comes near this (at most 1 `<!--` per line, 1,409 bytes longest). Fix with a single `split` on `<!--`. | Low (Macro × Cold) | `scripts/dev-cycle.sh:284-287` | High (measured) |

## Overall Assessment

The fix round reads every real file exactly as before, with no refusals on any branch or checkout, and the gates hold. The widened `refdef` is linear, and on lines that start with `[` it is often faster, because it refuses at once. The one regression is structural but cheap to fix. The new last-`<!--` loop in `opencomment()` moved a linear check into a quadratic one: it copies the remainder of the line on every match. It runs on accepted files too, and keeps running after a refusal. Real data is at least three orders of magnitude below where this bites, the path is cold, and no trust boundary is involved, so it is Low. A one-line `split` replacement restores linear cost without changing the reading. Two things still need running: the equivalence and timing probe for that replacement (`perf34/p4.sh`), and the quiet 100× archive rerun (`perf34/p5.sh`) to retire the contended 13.5 s figure. Nothing in the performance lane is Medium or above.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass34.md`, and its first line is `Commit: e93312d (A) / 823f494 (B)`. It follows the performance-reviewer structure: title and header, Data Flow and Hot Paths, Findings with a measured baseline and classification, evidence-tagged Endorsements, Summary Table and Overall Assessment.

Toward the user goal of merging `feat/dev-cycle` after a clean pass: the performance lane has one Low finding, which is a known issue under review-fix-loop rules. It needs a one-line fix, or an explicit acceptance, before the clean pass. The probe incident is reported at the top. It was a stray, untracked `p5.log` in `wt-devcycle`, now removed, and both worktrees are clean.
