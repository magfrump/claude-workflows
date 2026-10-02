Commit: 6f24d91 (A) / e19f411 (B)

# Performance Review: dev-cycle pass 31 (pass-30 fix round, k=1 delta)

**Scope:** Partial. A: `git diff f4d27d2..6f24d91 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff a7dfc0c..e19f411 -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle` (merge 0c45039 carries the same `scripts/dev-cycle.sh` and bats file as 6f24d91: `git diff 6f24d91 0c45039 --stat` on those paths is empty). The brief asks for new measurements of `--check-answer` and `--check-brief` with the plain-fence reader, which runs the `fenceish`/`rawhtml` regexes on every line, on the real archive and on large synthetic files. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass30.md` (on f4d27d2), and pass 30's numbers and generators in `scratchpad/perf30/`. No pass-31 fact-check verdict was available to me, so every runtime endorsement below is tagged `[unverified — submitted as claim]`.

**Measurements.** I took every number myself on 2026-10-02 in this sandbox, using mawk 1.3.4 20200120, which is what `awk` resolves to. "new" is `git show 6f24d91:scripts/dev-cycle.sh` and "old" is `f4d27d2:…`. Both ran interleaved in the same loops. Scratch is `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf31/` (`perf31/` below). Each probe is one `set -eu` script that creates its own `mktemp -d -p perf31` directory in that same script and checks `case "$PWD"` before any `git init`, commit or write. Every process ran under `timeout`, and all probes had exited (rc 0) before I wrote this report. Nothing was written to either worktree except this file.

- **P1** (`perf31/p1.sh`, `p1.log`): pass 30's P1 ported to new/old. It covers all real IDs in the three checkouts, old against new, the real archive at 1×, 10× and 100×, eleven 16–33 MiB synthetic archives with three runs each (two are new this pass: `html`, 16 MiB of short mixed-case HTML-ish lines; `bigline`, one 16 MiB upper-case line plus one 16 MiB tab line), and `--check-brief` on four committed briefs.
- **P2** (`perf31/p2.sh`, `p2.log`): the awk program `"$FENCE_AWK$ANSWER_AWK"` alone, old against new, on 16 and 64 MiB files (single space lines outside and inside a fence, 1000-space lines, list markers, fence pairs, HTML-ish lines, prose, and `bt`: a tab/space/marker line, a digit-run line and an upper-case line, each 16 or 64 MiB, to exercise the `fenceish` and `rawhtml` regexes on the longest records). Then the gates on `git archive 6f24d91`.
- **P3–P5** (`perf31/p3-e5.sh`, `p4-split.sh`, `p5-listclose.sh`): pass 30's reruns of pass 29's fact-check E5 (Q-101–Q-114), the questions.sh `archive` split, and the column-0 closer after a list-item fence, ported to new/old.
- **P6** (`perf31/p6-shapes.sh`, `p6-shapes.log`): 19 `--check-answer` shapes and 8 `--check-brief` shapes from the brief's claim 1 (info strings, longer closers, `~~~` in a backtick fence, CRLF, blank-only lines, backtick lines in a tilde fence, a fence at end of file, a heading in a fence, HTML comments and other HTML blocks). No CommonMark implementation is installed (`markdown_it`, `commonmark`, `mistune`, `cmark` all absent), so each "CM:" reading is derived from the spec's HTML-block and fenced-code rules. (The probe's case counter did not advance because `run` sits behind a pipe. Each case therefore reused one repo dir, overwrote its file and committed again. Every reading is still from that case's own commit.)

Legibility-target values: **maintainer** (someone editing the script) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle. `--check-answer` runs one `awk` per ID per questions file (`scripts/dev-cycle.sh:446-465`), so a batch of k IDs costs at most 2k full passes. Real files are about 20 KB and 180–186 KB. `--check-brief` makes one pass over one blob per brief (`:307-311`), and briefs are a few KB.

**What the diff changes in the per-line cost** (`:267-289`):
- `spaces()` and the `match()` for list markers are gone. `opens()` and `closes()` now look only at column 0, through `run()`.
- `fence()` is new. On every unfenced line that does not open a fence, it runs `fenceish()`, one anchored regex. When that fails it runs `rawhtml()`, which is `tolower()` of the whole line plus one anchored regex. On every fenced line it runs `closes()` and, when that fails, `fenceish()`.
- `ANSWER_AWK` adds one anchored regex test on fenced lines (`:414`). `END` (`:439-445`) adds three constant-time tests.
- `check_answer` (`:454-459`) still returns at the first refusal, so a refused file never costs more passes than an accepted one.

**B** adds no work. The final message now lists a subset of the `closed/` briefs it listed before, namely those an In flight line was repointed to. Those briefs already carry a `--check-brief` reading from the same cycle (SKILL.md `:87-92`).

**Gates on 6f24d91 (P2):** `bats test/scripts/dev-cycle.bats` gives **48 ok, 0 not ok, rc 0, 14 s**. `python3 scripts/hermeticity-lint --root .` gives **rc 0**. `shellcheck` is clean. The help range `sed -n '2,67p'` (`:131`) still ends on the last header comment line (67), because the header edit replaced two lines with two. Line 68 is blank.

**Readings and correctness checks the brief asked for** (outside my lane, but cheap to report):

| Check | Result |
|---|---|
| All real IDs, old → new (P1) | `(no difference)`, 0 stderr, in all three checkouts. None is refused. wt-devcycle has 102 IDs (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized), `/workspace` has 99 and wt-digest has 98. The 100-ID readings on the 1×, 10× and 100× archives are identical. Each real file's only HTML is the one-line `<!-- index:start -->` / `<!-- index:end -->` markers, and the reader accepts them. |
| E5 rerun (P3) | Q-101–Q-105 and Q-114 (indented and list-marker fence lines), where old read keep or gave a skip, now give `skip … line N … is a fence-like line that is not a plain column-0 fence`. Those are refusals of files CommonMark reads, which is the design's stated cost. Q-111 is `skip` (never closed, at line 6). Q-112 and Q-113 stay `drop`, which is CommonMark's reading. Header cases Q-106–Q-110 are unchanged. |
| questions.sh `archive` split (P4) | Before archive, all three IDs give `skip … line 15 … is a question heading inside a code fence`. After the split, all three give `skip … the code fence opened at line 16 … is never closed`. Both are refusals with a line number, and none is a wrong reading. |
| Column-0 closer after a list-item fence (P5, pass 30 F3) | `skip … line 6 … fence-like line`. The `- ```` opener is now refused, which retires pass 30's F3. |
| Pass-30 long-space files (P1 `longsp`, `spin`, `spout`) | `longsp` and `spin`: a skip naming the 16 MiB-spaces-then-```` ``` ```` line (8 and 10). `spout` (a space-only line): drop and keep, unchanged. `brief-sp`: a skip at line 3, where old gave `ok … open`. These are refusals. None is a wrong reading. |
| Column-0 shapes (P6 Q-201–Q-214) | Info string, longer closer with trailing blanks, `~~~` in a backtick fence, CRLF throughout, blank-only lines in a fence, a backtick line and a ``` ``` a`b ``` line in a tilde fence, `~~~ a`b`, a 4-tick fence holding a 3-tick line, and a one-line comment before a fence each give CommonMark's reading (keep, or unrecognized for Q-210). A fence at EOF, a closer with an info string (never closed), a column-0 ``` ``` a`b ``` outside a fence, and a heading in a fence each give a skip naming the line. **No column-0 fence shape gave a wrong reading.** |
| `--check-brief` shapes (P6) | A fenced Status line, a longer closer, CRLF and a backtick line in a tilde fence each give CommonMark's `open`. A fence left open after the Status line gives a skip, where old read `open`. |
| HTML blocks holding a ```` ``` ```` line (P6 Q-215–Q-218 and two briefs) | **Wrong readings, not refusals.** See finding 1. |

## Findings

#### 1. Cross-lane: a ```` ``` ```` line inside an HTML comment or a non-`<pre>` HTML block is read as a fence, giving wrong keep, done and open readings without a refusal

**Severity:** Medium on the brief's acceptance bar ("a wrong keep/drop/done/open on any input is a finding"). This is a correctness defect, not a performance one, so my skill's performance scale does not apply. Preconditions: a questions file or brief whose column-0 ```` ``` ```` lines sit inside an HTML comment (type 2) or a block-level or standalone-tag HTML block (types 6 and 7, such as `<div>`, `<details>` or `<span>` alone on a line), with an even total so the reader sees balanced fences. Text that CommonMark shows must fall between those lines. No real questions file or brief has one: all real readings are unchanged and none is refused. The behavior is identical at f4d27d2, so it predates this diff, but this diff's comment claims it is fixed and the brief's bar now covers it.
**Location:** `scripts/dev-cycle.sh:270` (`rawhtml`) and `:279-288` (`fence`), with the claim at `:255-262` (A, 6f24d91)
**Evidence (verbatim):**
```awk
function rawhtml(l) { l = tolower(l); return l ~ /^[ \t]*<(pre|script|style|textarea)([ \t>]|$)/ }
```
(`:270`. It is called only from `fence()` at `:286`, `if (fenceish(l) || rawhtml(l)) { if (!odd) odd = NR; return 1 }`, which `fence()` reaches after `opens()` at `:285` has already accepted any column-0 ```` ``` ````. The function ends at `:288`, `return 0`.) The comment at `:255-257` reads: "Code fences, read only in their plain form, so that every fence this reads is / read the way CommonMark reads it".
Measured readings (P6, `p6-shapes.log`):
```
Q-215  comment-held ``` lines around answer (CM: drop)            old=[keep Q-215]
                                                                  new=[keep Q-215]
Q-216  div-held ``` lines around answer (CM: drop)                old=[keep Q-216]
                                                                  new=[keep Q-216]
Q-217  details block, blank ends it (CM: fence? see note)         old=[keep Q-217]
                                                                  new=[keep Q-217]
Q-218  type-7 <span> line holds ``` (CM: drop)                    old=[keep Q-218]
                                                                  new=[keep Q-218]
brief  comment-held ``` around Status (CM: open)                  old=[ok docs/working/briefs/2026-10-01-b1.md done …]
                                                                  new=[ok docs/working/briefs/2026-10-01-b1.md done …]
brief  div-held ``` around Status (CM: dropped)                   old=[ok docs/working/briefs/2026-10-01-b1.md open …]
                                                                  new=[ok docs/working/briefs/2026-10-01-b1.md open …]
```
Q-215's entry body is `<!--`, ```` ``` ````, `-->`, blank, `- Q-215: [2]`, blank, `<!--`, ```` ``` ````, `-->`, blank, `- Q-215: [1]`. CommonMark ends each comment block at its `-->` line, so both ```` ``` ```` lines are raw HTML, the first answer line is `[2]` and the reading is drop. The reader opens a fence at the first ```` ``` ```` and closes it at the second, which hides `[2]`, so it reads `[1]`, keep. Q-216 uses `<div>…</div>` (type 6, ends at a blank line) and Q-218 uses a lone `<span>` (type 7), with the same result. In Q-217, `<details>` holds the first ```` ``` ````, and CommonMark opens a real fence at the second, which runs to EOF. CommonMark reads drop and the reader reads keep. The briefs are the same shape around `Status:` lines: CommonMark reads open and dropped, and the reader reads done and open.
**Move:** none of mine. This is for the fact-check, security and api-consistency lanes.
**Classification:** n/a (correctness) / Cold path
**Confidence:** High that the reader gives these readings (measured). Medium-High that CommonMark gives the stated ones: they are derived from the spec's HTML-block start and end conditions, and no implementation was available to run.
**Baseline:** no baseline available — flagged as speculative (on frequency. The readings themselves are measured.)
**Legibility-target:** maintainer
**Recommendation:** Do not refuse on every HTML start. Every real questions file has `<!-- index:start -->`, so that would refuse all of them. Instead, track HTML-block state in `fence()` at O(1) per line. A line opening with `<!--` (ends at the first line containing `-->`, which may be the same line), `<?`, `<!X` or `<![CDATA[` (types 3–5), or any other `^ {0,3}</?[A-Za-z]` (types 6 and 7: end at the next blank line) sets `inhtml`. A `fenceish` line while `inhtml` is set then sets `odd`. Add Q-215 and Q-216 as bats cases. Separately, and predating this round: an answer line or `Status:` line inside a multi-line comment is read as text (P6 Q-219 reads keep where CommonMark reads drop, and the brief "Status inside comment" reads done where CommonMark reads open). That is the answer rule's own gap, not the fence reader's. It is worth a line in the comment at `:367-391` or the same `inhtml` skip.

#### 2. `rawhtml()` lower-cases every whole unfenced line to test about a dozen leading characters

**Severity:** Informational. Precondition: questions files or briefs with multi-MiB single lines. On real data the difference is within noise. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:270` (A, 6f24d91). It is called from `fence()` at `:286` on every unfenced line that neither opens a fence nor is `fenceish`, through `:415` (`--check-answer`) and `:309` (`--check-brief`).
**Evidence (verbatim):** `function rawhtml(l) { l = tolower(l); return l ~ /^[ \t]*<(pre|script|style|textarea)([ \t>]|$)/ }` (`:270`, the whole function)
**Move:** Count the hidden multiplications (once per line, per pass, 2 passes per ID), and Check the asymptotic behavior (an O(line) copy where only the prefix decides)
**Classification:** Micro (constant per line, linear in line length) / Cold path (a few IDs per cycle, about 200 KB of real data)
**Confidence:** High
**Baseline:** Measured 2026-10-02 (P1 `bigline`, end to end): one 16 MiB upper-case line plus one 16 MiB tab line, old **705–891 ms**, new **1477–1705 ms** (one outlier at 3299 ms). With many short lines the copy does not show. P2, awk program alone: `prose` (74-byte lines) 115 → 141 ms at 16 MiB and 414 → 436 ms at 64 MiB; `html` 304 → 321 ms and 1135 → 1161 ms. Real archives: about 100 IDs in 944–1003 ms new against 966–1025 ms old.

`tolower()` allocates a copy of the full record before an anchored regex that can only match within the leading blanks and the next eleven characters. The long `bt` lines show that the regexes themselves stay linear in mawk: a 64 MiB tab/space/marker line, a digit-run line and a capital line took 43,072 ms old and 43,010 ms new, against 46,298 ms for a bare `length($0)` pass over the 64 MiB space file. So there is no backtracking cliff in `fenceish` or `rawhtml`. The only extra cost is the copy, which roughly doubles the time on a single huge line. At 2 passes per ID that is still seconds, nowhere near the Bash timeout, and no plausible questions file has such a line.
**Legibility-target:** maintainer
**Recommendation:** This is optional. Gate the copy with `l ~ /^[ \t]*</` first, or lower-case only a prefix (for example `tolower(substr(l, 1, k + 12))` after counting the leading blanks). If finding 1's `inhtml` tracking is added, it can share the same `^[ \t]*<` test.

## Endorsements

- Every real ID in the three checkouts reads the same under 6f24d91 as under f4d27d2, none is refused, and the time for about 100 IDs is unchanged (944–1003 ms new against 966–1025 ms old). `[unverified — submitted as claim]`
- Removing `spaces()` retires pass 30's F1 and makes fence-heavy and indent-heavy files faster. Awk alone (P2): 16 MiB of 1000-space lines ran 561 → 409 ms, and 64 MiB of fence pairs 10,514 → 6,413 ms. End to end (P1), `dense` ran about 2.0 → 1.5–1.6 s, and `--check-brief` on 16 MiB of fence pairs 2.47–2.50 → 1.96–1.99 s. `[unverified — submitted as claim]`
- `fenceish` and `rawhtml` are anchored and stay linear on 16 and 64 MiB single records (P2 `bt`: 43.0 s for both old and new, at mawk's existing long-record cost), so they add no backtracking hazard. `[unverified — submitted as claim]`
- Each refusal names its line: `odd N`, `unbalanced N` from `fline`, and `quoted N`. That retires pass 30's F2 at the cost of one assignment per opener (`:285`), and `check_answer` returns at the first refusal, so a refused file costs no extra passes. `[read: scripts/dev-cycle.sh:279-288, 439-465]`
- B narrows the final message's `closed/` list to briefs an In flight line was repointed to. Those briefs already carry a `--check-brief` reading from the In flight correction (SKILL.md `:87-92`), so the change adds no check call. `[read: skills/dev-cycle/SKILL.md:84-95, 368-372]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Cross-lane: a ```` ``` ```` held inside an HTML comment, `<div>`, `<details>` or lone-tag block is read as a fence, so wrong keep, done and open readings come back without a skip (pre-existing, contradicts the new comment) | Medium (brief's acceptance bar; not a performance severity) | `scripts/dev-cycle.sh:270`, `:279-288`, `:255-257` | High (reader) / Medium-High (CM reading) |
| 2 | `rawhtml()` runs `tolower()` on the whole line to test its prefix: about 2× on a 16 MiB single line, noise on real data | Informational | `scripts/dev-cycle.sh:270` | High |

## Overall Assessment

The pass-30 fix round is performance-neutral or better. Real archives read identically, with no refusals and no time change. Fence- and indent-heavy synthetic files get faster because the `spaces()` loop is gone. The new per-line regexes are anchored and linear even on 64 MiB records. The only measurable regression is `rawhtml()`'s full-line `tolower()` copy, which shows only on multi-MiB single lines. All gates hold: 48/48 bats, lint rc 0, shellcheck clean, help range intact. Pass 30's three findings are retired: `spaces()` is gone, refusals name their line, and list-item openers are refused. On the brief's acceptance bar, every column-0 fence shape I tried, and every earlier probe rerun, gives CommonMark's reading or a skip. The exception is finding 1. HTML blocks other than `<pre>`/`<script>`/`<style>`/`<textarea>` can hold ```` ``` ```` lines that CommonMark treats as raw HTML, and the reader pairs them into a fence and returns wrong keep, done and open readings. This predates the diff and no real file hits it. But the new comment claims the property, and the brief counts any wrong reading as a finding, so this lane cannot call the reader clean until it is fixed or the bar is narrowed. The fix is O(1) per line and needs no profiling.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass31.md`, with first line `Commit: 6f24d91 (A) / e19f411 (B)`. It follows the performance-reviewer structure: title, header, Data Flow and Hot Paths, Findings with Severity, Location, Evidence, Move, Classification, Confidence, Baseline and Legibility-target, then evidence-tagged Endorsements, Summary Table and Overall Assessment. Toward the user goal of merging after a clean k=1 pass: this lane finds nothing in performance above Informational. It does report one acceptance-bar correctness item (finding 1, pre-existing, constructed inputs only), which the synthesis should grade before declaring the pass clean.
