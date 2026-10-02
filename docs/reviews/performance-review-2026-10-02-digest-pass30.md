Commit: f4d27d2 (A) / a7dfc0c (B)

# Performance Review: dev-cycle pass 30 (pass-29 fix round, k=1 delta)

**Scope:** Partial. A: `git diff 38578a9..f4d27d2 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` (commits e2f2d54, f4d27d2). B: `git diff c345865..a7dfc0c -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle` (merge 35987c1). The brief asks for new measurements of `--check-answer` and `--check-brief` with the new `spaces()`/`opens()`/`closes()`, on the real archive and on large synthetic files, including long lines of spaces. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass29.md` (on 38578a9). I also used pass 29's numbers and generators in `scratchpad/perf29/`. No pass-30 fact-check verdict was available to me, so every runtime endorsement below is tagged `[unverified — submitted as claim]`.

**Measurements.** I took every number myself on 2026-10-02 in this sandbox, using mawk 1.3.4 20200120, which is what `awk` resolves to. "new" is `git show f4d27d2:scripts/dev-cycle.sh` and "old" is `38578a9:…`. Both ran interleaved in the same loops. Scratch is `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf30/` (`perf30/` below). Each probe is one `set -eu` script that creates its own `mktemp -d -p perf30` directory in that same script and checks `case "$PWD"` before any `git init`, commit or write. Every process ran under `timeout`, and all probes had exited (rc 0) before I wrote this report. Nothing was written to either worktree except this file.

- **P1** (`perf30/p1.sh`, `p1.log`) covers six things:
  - Unit cases for `opens()` and `closes()` under mawk.
  - The readings of all real IDs, old against new, in the three checkouts.
  - Copies of the real archive at 1×, 10× and 100×.
  - Nine 16–33 MiB synthetic archives with three runs each. Four are new in this pass: a 16 MiB line of only spaces; a 16 MiB space line and a 16 MiB spaces-then-```` ``` ```` line inside a fence; 16 MiB of 1000-space-indented lines; and 16 MiB of list-marker lines.
  - `--check-brief` on four committed briefs: 32 MiB of space lines in a fence, 16 MiB of fence pairs, 16 MiB of marker and indented lines, and a normal brief.
- **P2** (`perf30/p2.sh`, `p2.log`) runs the awk program `"$FENCE_AWK$ANSWER_AWK"` alone on single space lines from 8 to 64 MiB, plus 16 and 64 MiB multi-line files. It runs three versions: old, new, and a "cap" variant of new whose `spaces()` stops at `fcol + 4`. P2 also runs the gates on `git archive f4d27d2`.
- **P3** (`perf30/p3-e5.sh`) is pass 29's fact-check E5 probe (Q-101–Q-114), rerun with old = 38578a9 and new = f4d27d2.
- **P4** (`perf30/p4-split.sh`) is pass 29's fact-check probe 6 (the questions.sh `archive` split), rerun on f4d27d2.
- **P5** (`perf30/p5-listclose.sh`) is a column-0 closer after a list-item fence.

Legibility-target values: **maintainer** (someone editing the script) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle. `--check-answer` runs one `awk` per ID per questions file (`scripts/dev-cycle.sh:433-450`), so a batch of k IDs costs at most 2k full passes. The real files are about 20 KB and 180–186 KB. `--check-brief` makes one pass over one blob per brief (`:299-304`), and briefs are a few KB.

**What the diff changes in the per-line cost** (`:264-280`): `lead()`'s `sub()` plus two regex tests are replaced by three things:
- `spaces()`, a byte-at-a-time `substr` loop that counts **every** leading space;
- an anchored `match()` for the list marker, after the 3-space gate;
- `run()`.

`opens()` runs on every unfenced line and `closes()` on every fenced line, in both `ANSWER_AWK` (`:402-403`) and `check_brief` (`:302-303`). `END` gains an `infence` test (`:428`), which is constant time. On an unbalanced file, `check_answer` returns at the first file (`:442`), so that case is never slower.

**B** adds no loop. The orphan rule now gives an In flight line to every brief the glob prints `ok` for. For a done or dropped brief that has not yet moved, that is one extra `--check-brief` (about 20 ms, P1 `brief-sm`) before check 1 moves it in the same cycle. The final-message addition lists `closed/` briefs that were already recorded, so it does no new work.

**Gates on f4d27d2 (P2):** `bats test/scripts/dev-cycle.bats` gives **48 ok, 0 not ok, rc 0, 11 s**. `python3 scripts/hermeticity-lint --root .` gives **rc 0**. `shellcheck` is clean. The help range `sed -n '2,67p'` ends on the last line of the header comment (line 67), and line 68 is blank.

**Readings and correctness checks the brief asked for** (outside my lane, but cheap to report):

| Check | Result |
|---|---|
| All real IDs, old → new | `(no difference)`, 0 stderr, in all three checkouts. wt-devcycle has 102 IDs (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized), `/workspace` has 99 and wt-digest has 98. The 100-ID readings on the 10× and 100× archives are identical. |
| `match()`/`RLENGTH` in `opens()` under mawk | `- ```` → fcol 2; `1. ```` → 3; `10) ~~~` → 4; `   - ```` → 5; `123456789012. ```` → 14; `-\t```` → 2; `-```` and `1.```` → not a fence; `    ```` and `    - ```` → not a fence; ``` ``` a`b ``` → not a fence. `RLENGTH` is consumed before the next regex call. |
| `closes()` bound | After `- ```` (fcol 2), 5 spaces close and 6 do not. After `` ``` `` (fcol 0), 5 spaces do not close. `- ```` never closes. A longer closer with trailing blanks closes. `` ``` x `` does not close. |
| Fact-check E5 rerun (P3) | Q-101 drop→**keep**, Q-102 drop→**keep**, Q-103 unrecognized→**keep** and Q-114 keep: each new reading is CommonMark's. Q-105 keep→**skip (never closed)** and Q-111 unrecognized→**skip**. Q-112 unrecognized→**drop**: a fenced `### other` is content, so this is CommonMark's reading. Header cases Q-106–Q-110 are unchanged. No wrong keep, drop or done remains. |
| questions.sh `archive` split (P4) | Before archive: Q-001 `unrecognized`, Q-002 `open`, Q-000 `skip … only inside a code fence`. After archive leaves a dangling ```` ``` ```` in `questions.md`, all three IDs give `skip …: a code fence in docs/working/questions.md is never closed, so nothing after it can be trusted`. |
| Long space lines (P1 `longsp`, `spout`, `spin`; P2) | The pass-29 `longsp` file now gives `skip` (never closed) for every ID, where 38578a9 read drop and keep. The 16 MiB-space-plus-```` ``` ```` line is indented code. The next ```` ``` ```` opens a fence that is never closed. That is CommonMark's reading. In `spin`, the deep-indented ```` ``` ```` inside a fence no longer closes it: drop and keep, where old gave unrecognized and a fenced skip. In `brief-sp`, new gives `ok … open` and old gave a skip. |

## Findings

#### 1. `spaces()` counts every leading space, so indentation-heavy files pay about 5× per pass where 4 characters would decide

**Severity:** Informational. It has two preconditions: a questions file or brief of many MiB, and lines with hundreds of leading spaces. The real archive is 186 KB, and the measured difference there is within noise. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:264` (A, f4d27d2). It is called from `opens()` at `:267` and `closes()` at `:277`. Those run on every line through `:402-403` (`--check-answer`) and `:302-303` (`--check-brief`).
**Evidence (verbatim):**
```awk
function spaces(l,   n) { n = 0; while (substr(l, n + 1, 1) == " ") n++; return n }
function run(l, ch,   n) { n = 0; while (substr(l, n + 1, 1) == ch) n++; return n }
function opens(l,   i, s, m, ch, n) {
  i = spaces(l); if (i > 3) return 0
```
(This is `:264-267`, truncated. The rest of `opens()` runs to `:275`. `closes()` at `:276-280` begins `i = spaces(l); if (i > fcol + 3) return 0`. The count is used only against `3` and `fcol + 3`, and as the `substr` offset that follows.)
**Move:** Check the asymptotic behavior, not just the constant (the loop is O(indent) where O(1) suffices), and Count the hidden multiplications (once per line, per pass, 2 passes per ID)
**Classification:** Micro (constant per line, linear in the indent) / Cold path (a few IDs per cycle, about 200 KB of real data)
**Confidence:** High
**Baseline:** Measured 2026-10-02 (P2), awk program alone, old / new / cap (`spaces()` stopped at `fcol + 4`), all with identical output:
- 16 MiB of 1000-space lines (half fenced): **109 / 539 / 16 ms**.
- The same at 64 MiB: **421 / 2250 / 61 ms**.

The same effect shows end to end (P1 `spmany`, 16.8 MB): old about 120–138 ms, new about 538–650 ms. On realistic data the change does not show:
- **Real IDs:** 98–102 IDs, 2 runs each. Old ran 953–997 ms and new ran 934–994 ms, with readings identical.
- **One-ID lookups:** 1×: 20–22 ms. 10×: 24–28 ms. 100× (17 MB): old 68–73 ms, new 79 ms.
- **100 IDs:** 10×: 1404 → 1519 ms. 100×: 6535 → 7773 ms.
- **Other synthetic shapes:** all-fenced 182 → 210 ms; 16 MiB of fence pairs 1.76 → 2.0 s; indented and list text 274–372 → 321–428 ms; list markers 570–787 → 711–951 ms.

`spaces()` loops over every leading space, but its result is only compared with 3 (`opens`) or `fcol + 3` (`closes`). So a line indented 1,000 spaces costs 1,000 awk-level `substr` calls where 4 would decide. The cost is linear in file size, never quadratic. It cannot reach the 120 s Bash timeout on any plausible questions file: the 64 MiB worst case runs in 2.3 s per pass. That is why it rates Informational.
**Legibility-target:** maintainer
**Recommendation:** This is optional. Give `spaces()` a limit, for example `spaces(l, lim)` with `while (n < lim && …)`, and call it as `spaces(l, 4)` in `opens()` and `spaces(l, fcol + 4)` in `closes()`. Pass the limit explicitly rather than reading the global `fcol`, because `fcol` is stale outside a fence. While editing, the unused local `m` in `opens()` can go.

#### 2. A file left with an open fence is now a skip for every ID in every cycle until someone edits it, and the message does not say where the fence opens

**Severity:** Informational. The precondition is one stray fence line. P4 shows that `questions.sh archive` can produce one. No real questions file has one today: pass 29's P1 found all six balanced. Confidence: High that the behavior holds (measured); Medium on how much it costs.
**Location:** `scripts/dev-cycle.sh:427-428` (A, f4d27d2), with the message at `:442`.
**Evidence (verbatim):**
```awk
END {
  if (infence) print "unbalanced"
```
(This is `:427-428`, truncated. `END` continues with the dup, fenced and reading branches to `:432`. The word flows to `r` at `:440`, and `:442` maps it to `echo "skip $a: a code fence in $f is never closed, so nothing after it can be trusted"; return`.)
**Move:** Find the work that moved to the wrong place. A wrong reading is now traded for repeated asks, which is attention spent in every cycle rather than CPU.
**Classification:** Macro in attention, not CPU: every ID in the file is affected, every cycle. Cold path.
**Confidence:** Medium
**Baseline:** No CPU change: the unbalanced case returns after the first file (P1 `longsp`: old 1.66–1.84 s, new 1.19–2.21 s, single runs, noisy). For attention, the measured baseline is P4: after one `archive` run, 3 of 3 IDs read `skip`, where before they read `unrecognized`, `open` and `skip`. No baseline exists for how often this happens — flagged as speculative.

The skip is the safe direction, and the brief asks for exactly that. My concern is persistence and findability. One stray ```` ``` ```` blanks every keep-or-drop reading in that file until a person finds the line. The message names the file but not the line, and in a 1,700-line archive the agent or user has to search for the fence that never closed. That is cheap for an agent, but the search repeats in every cycle until the file is fixed.
**Legibility-target:** agent
**Recommendation:** This is optional. Record `NR` when `opens()` fires (for example `oline = NR` in the `opens($0)` rule at `:403`), print `unbalanced <line>`, and add "(opened at line N)" to the `:442` message. That costs one assignment per opener.

#### 3. Cross-lane note, not a performance finding: a column-0 fence line after a list-item opener closes it

**Severity:** Informational. Precondition: a ```` ``` ```` opened behind a list marker and closed at column 0. No real file has one. Confidence: Low. I have no CommonMark implementation installed: `markdown_it` is absent.
**Location:** `scripts/dev-cycle.sh:276-277` (A, f4d27d2)
**Evidence (verbatim):** `  i = spaces(l); if (i > fcol + 3) return 0` (`:277`, truncated. `closes()` continues at `:278-279` with the run-length and trailing-blank test.)
**Move:** none of mine. This is for api-consistency and security.
**Classification:** n/a (correctness) / Cold path
**Confidence:** Low
**Baseline:** no baseline available — flagged as speculative

`closes()` bounds indentation only from above, so a column-0 ```` ``` ```` closes a `- ```` fence (P1 unit case: `op=[- ```] [```] closes=1`). As I read the CommonMark spec, an unindented line ends the list item, and that ends its fence, so a column-0 ```` ``` ```` would open a new fence instead. In P5's file the result was a skip, never-closed, which is safe. A file with one more fence line after it could give a reading where CommonMark sees fenced text. This is the author-intent reading, and it predates this diff (38578a9's `lead()` stripped all indentation). I am handing it to the sibling critics unverified.
**Legibility-target:** maintainer
**Recommendation:** Have a sibling critic check it against a CommonMark renderer before deciding whether it matters. Otherwise, no action.

## Endorsements

- Every real ID in the three checkouts reads the same under f4d27d2 as under 38578a9, and the new code adds no measurable time on the real archive (934–994 ms against 953–997 ms for about 100 IDs). `[unverified — submitted as claim]`
- On single lines of 16 to 64 MiB, the new `spaces()` does not make mawk's existing long-record cost worse. With a 16 MiB space line, old ran 1286 ms and new 1320 ms. At 64 MiB, old ran 38.7 s and new 36.5 s, against 32.4 s for `length($0)` alone. This is the long-line cost pass 29 already filed. `[unverified — submitted as claim]`
- The `match()` in `opens()` is anchored and runs only after the ≤3-space gate, so it never scans a deeply indented line. A 16 MiB file of list-marker lines costs old 570–787 ms and new 711–951 ms. `[unverified — submitted as claim]`
- With the "unbalanced" verdict, `check_answer` returns after the first file (`:442`), so a broken file never costs more passes than before. `[read: scripts/dev-cycle.sh:433-450]`
- `--check-brief` on large briefs stays within about 15% of old: 16 MiB of fence pairs ran 2.05–2.12 s against 2.17–2.30 s, and 16 MiB of marker and indent lines ran 0.80–0.83 s against 0.97 s. A normal brief takes 18–20 ms. The 32 MiB space-line brief (2.2–2.4 s against 1.4 s) now reads `open`, where old gave a skip. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `spaces()` counts every leading space where 4 decide: about 5× per pass on deeply indented files, with no change on real data | Informational | `scripts/dev-cycle.sh:264` | High |
| 2 | An open fence at the end of a file skips every ID each cycle, and the message gives no line number | Informational | `scripts/dev-cycle.sh:427-428`, `:442` | Medium |
| 3 | Cross-lane: a column-0 closer after a list-item opener (possibly not CommonMark) | Informational | `scripts/dev-cycle.sh:277` | Low |

## Overall Assessment

The pass-29 fix round is performance-neutral where it matters. On the real archive, readings are identical and the timing difference is within noise. At 100× scale, 100 IDs cost 7.8 s against 6.5 s. Every probe in the brief, run again on f4d27d2, now gives CommonMark's reading or a skip. That covers E5 Q-101–Q-114, pass 29's 16 MiB-of-spaces `longsp` file, the in-fence variants and the questions.sh `archive` split, and none gives a wrong keep, drop or done. The gates hold: 48/48 bats, lint rc 0, shellcheck clean. The only measurable regression is constant-factor. `spaces()` walks the whole indent, which shows up only on synthetic files with hundreds of leading spaces per line (0.1 → 0.5 s at 16 MiB). A one-line limit removes it. Nothing here is Medium or above, nothing needs profiling, and nothing blocks the clean pass. Findings 1 and 2 are optional polish, and finding 3 is a question for the sibling critics.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass30.md`, with first line `Commit: f4d27d2 (A) / a7dfc0c (B)`. It follows the performance-reviewer structure: title, header, Data Flow and Hot Paths, Findings with Severity, Location, Evidence, Move, Classification, Confidence, Baseline and Legibility-target, then evidence-tagged Endorsements, Summary Table and Overall Assessment. Toward the user goal of merging after a clean k=1 pass: this lane finds nothing Medium or above and no wrong reading in any rerun probe, so it raises no blocker. The three Informational items can be fixed or left.
