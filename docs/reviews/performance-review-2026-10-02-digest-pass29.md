Commit: 38578a9 (A) / c345865 (B)

# Performance Review: dev-cycle pass 29 (pass-28 fix round, k=1 delta)

**Scope:** Partial. A: `git diff 366efd7..38578a9 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff b73069e..c345865 -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle`, merged as 5a50016. The brief asks me to measure `--check-answer` now that the fence functions run on every line of the whole file, on the real archive and on large synthetic ones, and to measure `lead()`'s per-line regex. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass28.md` (on 366efd7 / b73069e), plus pass 28's numbers and generators in `scratchpad/perf28/`. No pass-29 fact-check report was in the worktree when I finished. No endorsement below rests on a fact-check verdict, so every runtime endorsement is tagged `[unverified — submitted as claim]`.

**Measurements.** I took every measurement myself on 2026-10-02 in this sandbox (mawk 1.3.4 20200120 is the only awk; git 2.39.5). "new" is `git show 38578a9:scripts/dev-cycle.sh` and "old" is `366efd7:…`. Both ran interleaved in the same loop. Scratch is in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf29/` (`perf29/` below). Each probe is one `set -eu` script that creates its own `mktemp -d -p perf29` directory in that same script and checks `case "$PWD"` before any `git init`, commit, write or `rm`. Every process ran under `timeout`, and both probes exited (rc 0) before I wrote this report. Nothing was written to either worktree except this file. The real questions files were only read or copied.

- **P1** (`perf29/p1-answer.sh`, `p1.log`) covers five things:
  - The end-of-file fence state of the six real questions files, using the new `FENCE_AWK` cut verbatim from the script.
  - The readings of all real IDs in the three checkouts, old against new (102, 99 and 98 IDs).
  - The cost on 1×, 10× and 100× copies of the real archive.
  - Five 16–33 MiB synthetic archives, each with a target ID, the ID after it, a missing ID and an ID in `questions.md`, three runs each. The archives are a 17.5 MB all-fenced archive, a 16 MiB entry of fence pairs, 16 MiB of 4-space-indented code and list items, 16 MiB of plain text, and two 16 MiB single lines (leading spaces before ```` ``` ````, and a digit run before `. `).
- **P2** (`perf29/p2-scaling.sh`, `p2.log`) runs the awk program `"$FENCE_AWK$ANSWER_AWK"` alone, cut from each script, at 4/16/64 MiB for a missing ID. It also covers:
  - Single 8/16/32 MiB lines against a bare `length($0)` baseline.
  - The header `split` on `" · "` under mawk with `LC_ALL=C`.
  - The gates, on `git archive 38578a9`: `bats test/scripts/dev-cycle.bats` gives **47 ok, 0 not ok, rc 0, 11 s**. `python3 scripts/hermeticity-lint --root .` gives **rc 0**. `shellcheck scripts/dev-cycle.sh` is clean.

Legibility-target values: **maintainer** (someone editing the script) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle. For `--check-answer`, N is the set of IDs not yet on a brief's `Applied:` line, which is a handful per cycle (at most 3 briefs hold a slot). The files are `questions.md` (about 20 KB) and `questions-archive.md` (180–186 KB in the three real checkouts). Severity can still rise for three reasons: the agent's 120 s Bash timeout, a non-zero exit, or a cost that grows without bound.

- **What changed in the cost model** (`scripts/dev-cycle.sh:397-401`, A). The pattern `infence { … }` comes first, then `opens($0)`, then `heading($0)`, the `/^(#|##|###) /` test and `!inside { next }`. So every line of both files now pays one `opens()` call, which runs `lead()` (one `sub()` and up to two regex matches) and `substr`. Fenced lines pay `heading()`, a `/^### /` match and `closes()`. At 366efd7 these calls ran only inside the target entry. Outside it, each line paid `heading()` and one regex.
- **The multiplication** (`:427-445`, `:473-480`). `check_answer` runs one `awk` per ID per file, and it always reads both files, because a hit in one file is checked for a duplicate in the other. A batch of k IDs therefore costs 2k full passes. This predates the diff, but the diff raises the per-line cost of every one of those passes.
- **The header split** (`:402-406`) runs once per entry visited, on the header line of the target entry only. Its cost is negligible.
- **B** adds no loop to the scripts. It widens In flight to every glob-listed brief, whatever its state. A done or dropped brief that is not yet moved costs one `--check-brief` and then leaves `briefs/` through check 1's `git mv` in the same cycle. A `closed/` brief that reads `open` or `new` costs one `--check-path` and one `--check-brief` per cycle, plus one line in the final message, until the user sets it.

**Reading and safety checks the brief asked for** (performance lane, but cheap to report):

| Check | Result |
|---|---|
| Readings of all real IDs, old → new | identical in all three checkouts (`(no difference)`, 0 stderr): wt-devcycle 102 IDs (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized); `/workspace` 99; wt-digest 98 |
| 100-ID readings on the 10× and 100× archives | identical |
| End-of-file fence state of the six real questions files | every one balanced: `open-at-eof=0`, `fenced-###=0` (1 fence in each `questions.md`, 9 in each archive, the last opening at about line 1,660 of about 1,700) |
| Does `questions.sh` emit fences? | No. `rg` finds no ```` ``` ```` or `~~~` in `~/.claude/scripts/questions.sh` or `/workspace/scripts/questions.sh`, and the two files are identical. An open fence can only come from text pasted into an entry. |
| `split($0, fld, " · ")` under mawk, `LC_ALL=C` | 3 fields for `Needs · Opened · Status`. The last `**Status:**` field wins (`OPEN · ANSWERED` gives answered, `ANSWERED · OPEN` gives open). Trailing spaces are trimmed. `ANSWERED (date)` and a header with no separator are both not answered. The two-byte `·` is matched as a literal byte string. |

## Findings

#### 1. Whole-file fence tracking roughly doubles to triples `--check-answer`'s per-pass cost on every line, multiplied by 2 × (number of IDs)

**Severity:** Informational. Precondition: questions files of many MiB, or fence-dense ones. The real archive is 186 KB, with 9 fences. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:397-401` (A, 38578a9). The functions it calls are at `:259-277`, and the loop that multiplies it is at `:427-445`.
**Evidence (verbatim):**
```awk
infence { if (heading($0)) quoted++; if ($0 ~ /^### /) inside = 0; if (closes($0)) infence = 0; next }
opens($0) { infence = 1; next }
heading($0) { count++; inside = (count == 1); header = 0; next }
/^(#|##|###) / { inside = 0; next }
!inside { next }
```
(This is `:397-401`. The rest of the `ANSWER_AWK` unit continues with the header rule at `:402-406`, the answer-line rule at `:407-421` and `END` at `:422-426`. The printed word flows to `r` at `:433` and is mapped to the output line at `:434-440`.)
**Move:** Find the work that moved to the wrong place (the fence calls moved from the target entry to every line), and Count the hidden multiplications (one awk per ID per file)
**Classification:** Micro (constant factor per line) / Cold path (a few IDs per cycle, about 200 KB)
**Confidence:** High
**Baseline:** Measured 2026-10-02 (P1, P2), old (366efd7) → new (38578a9). End-to-end `--check-answer` unless marked:
- Real files, all IDs: 939–971 → 966–1,034 ms (102, 99 and 98 IDs).
- 100× real archive (17 MB, 8,900 entries): one ID 47–49 → 71–79 ms; 100 IDs 4,923 → 6,104 ms.
- 17.5 MB all-fenced synthetic archive, any ID: 95–108 → 190–198 ms.
- 16 MiB of fence pairs in a **non-target** entry, any other ID: 581–652 → 1,789–3,217 ms. This is the new cost. With the dense entry as the target, the cost is unchanged: 2,066–2,169 → 1,813–1,967 ms.
- 16 MiB of indented code and list items, non-target: 116–134 → 248–305 ms.
- 16 MiB plain text, non-target: 50–59 → 78–92 ms.
- The awk program alone, missing ID, at 4 / 16 / 64 MiB:
  - fence pairs: 145 / 555 / 3,559 → 435 / 1,749 / 6,935 ms
  - indented: 23 / 90 / 357 → 58 / 234 / 901 ms
  - plain: 8 / 27 / 106 → 15 / 53 / 207 ms
**Legibility-target:** maintainer

The cost is linear in the line count (P2: each 4× in size costs about 4× in time). It is now paid for every ID, not just inside the target entry. At real sizes it does not register: the full run over every real ID takes about 1 s either way, and process startup dominates that. The worst realistic batch is a few IDs against a file of about 200 KB. To reach the 120 s timeout with 3 IDs, the archive would need to be roughly 300 MiB of pure fence pairs, or several GiB of ordinary text. I'm recording this so the cost model stays written down. It is not a fix request: the whole-file reading is what makes a fenced heading a quote rather than an entry, and that is the purpose of the round.

**Recommendation:** None at current scale. If it ever matters, there are two cheap options, and neither changes a reading. One is a byte pre-test in front of `opens($0)`, such as `index($0, "``") || index($0, "~~")`, so that ordinary lines skip `lead()`'s `sub()` and regexes. The other is to read all IDs in one awk pass per file instead of one pass per ID, which removes the 2k multiplier.

#### 2. `lead()` adds about one more full scan of a very long line. mawk's superlinear long-record cost is pre-existing and unchanged

**Severity:** Informational. Precondition: a questions file holding a single line of tens of MiB. No real file comes close. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:260-264` (A, 38578a9)
**Evidence (verbatim):**
```awk
function lead(l) {
  sub(/^[ \t]+/, "", l)
  if (l ~ /^[-*+][ \t]/ || l ~ /^[0123456789]+[.)][ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l) }
  return l
}
```
(This is `:260-264`, the whole function. Its value flows into `opens()` at `:266-272` and `closes()` at `:273-276`, the only callers, and `:277` closes the `FENCE_AWK` string.)
**Move:** Ask "what's the size of N?" (N is the length of one line)
**Classification:** Macro (superlinear in line length, from mawk) / Cold path, pathological input
**Confidence:** High
**Baseline:** Measured 2026-10-02 (P2). Program alone, one line, with bare `length($0)` as the floor:

| Line | Size | `length($0)` floor | old | new |
|---|---|---|---|---|
| leading spaces, then ```` ``` ```` | 8 MiB | 168 ms | 173 ms | 429 ms |
| leading spaces, then ```` ``` ```` | 16 MiB | 780 ms | 792 ms | 1,333 ms |
| leading spaces, then ```` ``` ```` | 32 MiB | 5,393 ms | 6,824 ms | 5,885 ms |
| digit run, then `. x` | 32 MiB | 4,266 ms | 7,070 ms | 9,398 ms |
| backtick run | 32 MiB | 8,027 ms | 5,366 ms | 7,559 ms |

End to end, the 33 MiB two-long-line archive takes 681–956 ms old and 1,299–2,765 ms new (P1).
**Legibility-target:** maintainer

Every regex in `lead()` is anchored, and `[0123456789]+` and `[ \t]+` are simple runs, so the function itself is linear. The 32 MiB rows are noisy and are dominated by mawk's own record handling, which the `length($0)` floor already shows (pass 28 finding 2). New adds between nothing and about 2.5× on top of that floor. Nothing here is a backtracking or quadratic regex.

**Recommendation:** None. The size guard pass 28 suggested (skip a file above some MiB) would bound this case too, if questions files ever came from untrusted bulk text.

## Cross-lane observations (not graded here)

- **Whole-file trade, real exposure.** The brief's concern is an unbalanced fence early in a real questions file hiding later entries. The data rules it out today: all six real files end with no fence open, and no `### ` line sits inside a fence. `questions.sh` writes no fence characters at all, so its own layout cannot produce one. The risk stays limited to text pasted by hand into an entry. `[unverified — submitted as claim]` (my execution, P1)
- **Any-indentation fences can change a reading.** In P1's `longsp` archive, a line of 16 MiB of spaces followed by ```` ``` ```` counts as a fence opener at 38578a9 but not at 366efd7. Q-100 reads `drop` new and `unrecognized` old. CommonMark would treat that line as indented code. The brief accepts this deviation by design. I'm passing the case to the security and api lanes as a concrete example of 4+-space indentation exposing an answer. It is not a performance issue. `[unverified — submitted as claim]` (my execution, P1)

## Endorsements

- The round changes no reading on real data. All 102 / 99 / 98 real IDs read identically old → new with 0 stderr, and the 100-ID readings on the 10× and 100× archives are identical too. `[unverified — submitted as claim]` (my execution, P1)
- The header gate's `split($0, fld, " · ")` behaves under mawk with `LC_ALL=C` as `:402-406` describe. The two-byte separator matches as literal bytes. The last `**Status:**` field decides. Only an exact `ANSWERED` after trailing-space trimming counts as answered. `[unverified — submitted as claim]` (my execution, P2)
- `lead()`'s regexes are all anchored at `^`, and `opens()` and `closes()` add no loop beyond `run()`'s single scan, so the per-line cost is linear in line length. `[read: scripts/dev-cycle.sh:260-276]`
- The gates hold at 38578a9: bats 47/47 ok (11 s), hermeticity-lint rc 0, shellcheck clean. `[unverified — submitted as claim]` (my execution, P2)
- B adds attention cost only within existing bounds. A glob-listed done or dropped brief leaves In flight in the same cycle through check 1's `git mv` (`SKILL.md:273-282`). A `closed/` brief that reads open or new costs one `--check-path` and one `--check-brief` per cycle and gets no question (`:89-93`, `:300`). This recurs each cycle until the user sets the brief's status, so it is bounded by the number of such briefs. `[read: skills/dev-cycle/SKILL.md:76-95,268-312]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Whole-file fence tracking costs 2–3× per line on every pass, × 2 per ID. Examples: 16 MiB fence-dense non-target entry 0.6 → 1.8–2.1 s per ID; 100 IDs on a 17 MB archive 4.9 → 6.1 s. Real files about 1 s either way | Informational | `scripts/dev-cycle.sh:397-401` (A) | High |
| 2 | `lead()` adds up to about one more scan of a huge line. Its regexes are anchored and linear, and the superlinearity is mawk's own (pre-existing) | Informational | `scripts/dev-cycle.sh:260-264` (A) | High |

## Overall Assessment

The round's fix has a price, and it is small. Moving fence tracking from the target entry to the whole file means every line of both questions files now pays `opens()` and `lead()`'s `sub()` on every one of the 2 × (number of IDs) awk passes. That is about 2× on plain text and about 3× on fence-dense text. The cost is linear in size, and at real sizes (about 200 KB, 9 fences) it stays within the noise of process startup: about 1 s for every real ID, with identical readings. No regex in `lead()` backtracks. The only superlinear behavior is mawk's long-record handling, which predates this diff. The whole-file trade is safe on today's data: every real file ends balanced, and `questions.sh` writes no fences. B adds no loop and bounded per-cycle checks. Both findings are Informational and cold-path, and neither needs a fix or more benchmarking. Nothing in the performance lane blocks the clean pass.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file."
- **Path:** saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass29.md`, first line `Commit: 38578a9 (A) / c345865 (B)`. Not committed.
- **Structure:** follows the performance-reviewer layout: header, data flow and hot paths (with the safety-check table the brief asked for), findings, cross-lane observations, evidence-tagged endorsements (≤5), summary table and overall assessment. Each finding carries Severity (with preconditions and confidence), Location, verbatim Evidence with a note naming the rest of its unit and the flow of its value, Move, Classification, Confidence, a measured Baseline and Legibility-target. Endorsements I verified only by my own runs are tagged `[unverified — submitted as claim]`.
