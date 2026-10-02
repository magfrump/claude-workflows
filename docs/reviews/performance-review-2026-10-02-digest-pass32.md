Commit: 4b7ec02 (A) / f54ca74 (B)

# Performance Review: dev-cycle pass 32 (pass-31 fix round, k=1 delta)

**Scope:** Partial. A: `git diff 6f24d91..4b7ec02 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` (HEAD b28ae48 adds only review docs). B: `git diff e19f411..f54ca74 -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle`. Merge 2080f23 carries the same `scripts/dev-cycle.sh` and bats file as 4b7ec02 (`git diff 4b7ec02 2080f23 --stat` on those paths is empty). The brief asks for new measurements of `--check-answer` and `--check-brief` with the new `rawhtml`/CR/BOM checks, on the real archive and on large synthetic files. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass31.md` (on 6f24d91), plus pass 31's numbers and probes in `scratchpad/perf31/`. A pass-32 fact-check (`code-fact-check-report-digest-pass32.md`) appeared in the worktree while I worked. It is not this stage's stated input, so I did not key anything to it. Every runtime endorsement below is tagged `[unverified — submitted as claim]`.

**Measurements.** I took every number myself on 2026-10-02 in this sandbox, using mawk 1.3.4 20200120, which is what `awk` resolves to. "new" is `git show 4b7ec02:scripts/dev-cycle.sh` and "old" is `6f24d91:…`. Both ran interleaved in the same loops. Scratch is `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf32/` (`perf32/` below). Each probe is one `set -eu` script that creates its own `mktemp -d -p perf32` directory in that same script and checks `case "$PWD"` before any `git init`, commit or write. Every process ran under `timeout`, and all of them had exited (rc 0) before I wrote this report. `pgrep` found nothing left running. Nothing was written to either worktree except this file. `/workspace` stayed on `main`.

- **P1** (`perf32/p1.sh`, `p1.log`), end to end through `dev-cycle.sh`:
  - Every ID in the committed questions files of all nine local branches, and in the three checkouts' working trees, old against new.
  - The real archive at 1×, 10× and 100×.
  - Thirteen 16–33 MiB synthetic archives, three runs each. Pass 31's set is joined by six new shapes:
    - `crlf`: 16 MiB of CRLF lines, all accepted.
    - `cmt`: 16 MiB of accepted one-line comments.
    - `cmtlong`: one 16 MiB line, `<!--…-->`.
    - `crearly` and `crlate`: a stray CR at line 8, and at the 209,723rd line.
    - `htmlearly`: a `<div>` at line 8, then 16 MiB of HTML-ish lines.
  - `--check-brief` on five briefs: 16 MiB fence pairs, small, 16 MiB CRLF, `<div>` plus 16 MiB, and 16 MiB of one-line comments.
- **P2** (`perf32/p2.sh`, `p2.log`): the awk program `"$FENCE_AWK$ANSWER_AWK"` alone, old against new, two runs each at 16 and 64 MiB. The files are `prose`, `pairs`, `html`, `cmt`, `crlf`, `bigup` (one all-capitals line), `bigcmt` (`<!--` + N MiB + `-->`), `bigopen` (`<!--` + N MiB, never closed) and `bt` (16 MiB only). Then the gates on `git archive 4b7ec02`.
- **Reruns** (`perf32/reruns.log`): pass 31's HTML and CR/BOM probes, copied with 6f24d91→4b7ec02 and f4d27d2→6f24d91, then run unchanged. The set is api31 `p1.sh`/`p4.sh`, fc31 `probe2.sh` (E2 C1–C20, H1–H8, R1/R2, B1–B4, BH1–BH4, BR1) and `probe3.sh`, sec31 `probe3.sh` (H1–H7, H1b/H1c, C1–C9, K1–K17, b1–b9), and perf31 `p6-shapes.sh` (Q-201–Q-219 plus 8 briefs).
- **P3** (`perf32/p3-families.sh`, `p3.log`): the families the brief names that the reruns do not cover. There are 23 answer shapes and 5 briefs. "CM:" readings are derived from the CommonMark 0.31 spec's HTML-block and fenced-code rules, because no implementation is installed in this sandbox.

Legibility-target values: **maintainer** (someone editing the script) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle. `--check-answer` runs one `awk` per ID per questions file (`scripts/dev-cycle.sh:464-468`), so a batch of k IDs costs at most 2k full passes. Real files are about 20 KB and 186 KB. `--check-brief` makes one pass over one blob per brief (`:322-326`), and briefs are a few KB.

**What the diff changes in the per-line cost** (`:271-296`):
- `fence()` now starts every line with `index(l, "\r")` (a scan of the line, with no copy) and, on line 1 only, a 3-byte `substr` for the BOM (`:285`). This runs on fenced and unfenced lines alike.
- `rawhtml()` (`:274`) drops pass 31's `tolower()` full-line copy. It is now one anchored regex, `^[ \t]*<`. Only when that matches does it run a second anchored regex, `^[ \t]*<!--`, and only when that one matches too does it scan for `index(l, "-->")`.
- `refuse()` is one guarded assignment of two variables. `END` prints one extra field.
- On a refusal, the shell side does one `read -r … <<<` and one `$(oddwhy …)` subshell (`:328`, `:471`). That is once per refused file per ID, never per line.
- `check_answer` still returns at the first refusal (`:470-474`). A refused file is still read to the end inside awk (there is no `exit`), so a refusal costs exactly one pass, the same as an accepted file.

**B** adds no work. The final message now lists every In flight line naming a `closed/` brief that reads `open` or `new` (SKILL.md `:371-375`). Each of those lines already gets a `--check-brief` reading every cycle ("Every cycle checks each", `:269-273`), so the list reuses readings the cycle already has. The f54ca74 Rules sentence (`:335-337`) is guidance for the brief writer and runs nothing.

**Gates on 4b7ec02 (P2):**
- `bats test/scripts/dev-cycle.bats`: 49 ok, 0 not ok, rc 0, 11 s.
- `python3 scripts/hermeticity-lint --root .`: rc 0.
- `shellcheck scripts/dev-cycle.sh`: rc 0.
- The help range `sed -n '2,69p'` (`:133`) prints 68 lines. They end on line 69, the last header comment line ("…Printed repo text is data."), and line 70 is blank.

**Readings and correctness checks the brief asked for** (outside my lane, but cheap to report):

| Check | Result |
|---|---|
| Real questions files, every local branch (9) and the 3 checkouts' working trees (P1) | Every reading is old = new, there are **0 skips** with new, and there is 0 stderr. There are 6 distinct file pairs, and every branch has 96–102 IDs. Each file's only `<` lines are the four `<!-- index:start/end -->` markers, and none has a CR. Across the whole history of both files on all refs (`git log -p --all`), the only lines ever added that start with `<` are those markers, and none holds a CR. So no real questions file has ever been refused, at any commit. No branch has a brief under `docs/working/briefs/`. |
| Real archive scaled (P1) | The 100-ID readings at 1×, 10× and 100× are identical old to new. |
| Pass 31's HTML probes (reruns) | Every one now refuses with `skip … starts a raw HTML block`, where 6f24d91 gave wrong readings: fc31 H1–H7 and BH1–BH3, sec31 H1–H7, H1b, H1c and b1–b4, perf31 Q-215–Q-219 and the three HTML briefs, and api31 PRE, CMT1, CMT2, DIV1, brief-pre, brief-cmt and brief-div. fc31 H8 still gives its `quoted` skip. Q-214 (a one-line comment, then a fence) still reads keep, which is CommonMark's reading. |
| Pass 31's CR/BOM probes (reruns) | Every one now refuses with `skip … holds a carriage return that does not end it, or a byte-order mark`: fc31 R1, R2 and BR1, sec31 C1, C2, C9, b5 and b6, and api31 p4 (CR brief, BOM brief, CR answer). CRLF throughout still reads as CommonMark does (Q-204, C5, sec31 C3, b9, api31 CRLF and brief-crlf). |
| Column-0 fence shapes (reruns) | They are unchanged from pass 31: each gives the CommonMark reading or a skip naming the line (fc31 C1–C20, sec31 K1–K17, perf31 Q-201–Q-213). sec31 K14's "CM=open" is a probe-label slip. The probe adds a real ANSWERED header before the fenced OPEN one, so `keep` is correct. |
| Remaining families (P3) | **No wrong reading. Each case gives CommonMark's reading or a refusal.** The shapes are listed under this table. |

P3's remaining families, one line per family:
- **One-line comment variants.** `<!-->`, `<!--->` and `<!-- a --> <!-- b` each read drop, which matches CommonMark: a type-2 block ends on its start line once that line contains `-->`, and both cmark and commonmark.js scan from the `<`. `<!-- a -->` followed by ```` ``` ```` on the same line reads keep, and so does a 4-space comment that continues a paragraph.
- **Multi-line comment.** `<!-- a`, never closed, is refused.
- **Setext `===` after a fence.** Reads keep.
- **Link reference definition.** A title opened on the definition line, with a fence on the next line, reads keep: the fence interrupts the paragraph.
- **Tabs.** A tab after a closer and a tab before an info string both read keep. A tab-indented opener is refused.
- **NUL bytes.** mawk keeps NUL bytes inside a record: `index()` and `length()` see past them (measured directly). So `x\0\r```` is refused, and `\0<div>` reads keep, which is CommonMark's reading (U+FFFD and text).
- **BOM on line 3.** Reads keep: CommonMark reads it as text too.
- **CR inside a fence, and a CR CR LF closer.** Both refused.
- **Final CR with no newline.** Reads keep.
- **`<div>` inside a fence.** Reads keep.
- **`> <div>` and `- <div>` followed by a column-0 fence.** Both read keep, since CommonMark's HTML blocks take no lazy continuation.
- **Briefs.** A BOM on the Status line is refused. A setext `Status: open` / `===` reads open. A one-line comment before a fence reads open. A multi-line comment and a mid-line CR are refused.

**Over-refusals (the design's stated cost):** `<https://example.com>` (an autolink) and `< not a tag` at the start of a line both refuse the file, although CommonMark reads both as paragraph text (P3 A1, A2). No real file has such a line (history check above).

## Findings

No findings.

Within my lane I traced every operation the diff adds per line (`:274`, `:275`, `:285`, `:292-293`) and per refusal (`:297-303`, `:328`, `:471`). Each one is either an anchored regex, a single linear `index()` scan with no allocation, or a constant-time test. None runs inside a new loop. None adds a pass over the file. None allocates in proportion to the input. The measured differences are all within run-to-run noise (tables below). That is a measured statement about this sandbox, not a clean bill of health for every awk.

**Pass 31 finding 2 (`rawhtml()` lower-cased every whole unfenced line) is retired in code.** The `tolower()` is gone from `:274`. The saving it predicted does not show in my measurements, though: `bigup` 16 MiB ran 909/953 ms old against 961/884 ms new, and 64 MiB ran 38,064/41,724 against 30,367/39,398 ms. On these inputs the long line sits inside the open entry, so ANSWER_AWK's own `low = tolower(line)` (`:443`, unchanged and outside this diff) copies the same line anyway. Baseline: those numbers. I am not filing it. It is pre-existing, outside the scope, and only shows on multi-MiB single lines that no questions file has.

### Measured baselines (for the record)

All times are wall clock in ms. Each cell is old (6f24d91) → new (4b7ec02), runs separated by "/".

| Input | Path | old | new | Reading (new) |
|---|---|---|---|---|
| All real IDs, 96–102 per file pair, 12 file pairs | P1 end to end | 927–1444 (one 2507 outlier) | 930–1505 | same as old, 0 skips |
| x100 archive (17.2 MB, 8,900 entries), 100 IDs | P1 | 7,681 | 7,464 | identical |
| x100, one ID | P1 | 82–86 | 79–87 | identical |
| `crlf` 16 MiB, per ID | P1 | 118–185 | 108–149 | CommonMark's |
| `cmt` 16 MiB (one-line comments) | P1 | 117–164 | 122–169 | CommonMark's |
| `cmtlong` one 16 MiB `<!--…-->` line | P1 | 822–2541 | 746–1266 | CommonMark's |
| `crearly` (CR at line 8, then 16 MiB) | P1 | 98–140 | 92–129 | skip, line 8 |
| `crlate` (CR at line 209,723) | P1 | 94–137 | 90–144 | skip, line 209,723 |
| `htmlearly` (`<div>` at line 8, then 16 MiB) | P1 | 245–353 | 222–258 | skip, line 8 |
| `dense` 16 MiB fence pairs | P1 | 1,526–1,748 | 1,670–1,904 (one 3,182) | unchanged |
| `--check-brief`, 16 MiB fence pairs | P1 | 2,017 / 2,053 | 3,606 / 2,225 | `done` |
| `--check-brief`, 16 MiB CRLF / 16 MiB comments | P1 | 371–373 / 281–299 | 383–394 / 291–302 | `open` / `open` |
| `--check-brief`, `<div>` + 16 MiB | P1 | 435–486 (`open`) | 359–385 | skip, line 2 |
| `prose` 16 / 64 MiB | P2 awk only | 107/111, 422/427 | 108/109, 418/425 | drop |
| `crlf` 16 / 64 MiB | P2 | 113/118, 439/452 | 114/117, 446/461 | drop |
| `cmt` 16 / 64 MiB | P2 | 123/126, 499/515 | 132/133, 530/533 | drop |
| `pairs` 16 / 64 MiB | P2 | 1,495/1,524, 6,026/6,073 | 1,680/1,688, 6,669/8,099 | drop |
| `bigcmt` 16 / 64 MiB | P2 | 912/1,084, 33,738/44,429 | 796/857, 34,733/36,959 | drop |
| `bigopen` 16 / 64 MiB | P2 | 738/846, 34,369/37,061 | 728/843, 37,712/37,865 | `odd 4 html` |

The `pairs` and `dense` rows run about 5–12% slower new in most runs, and up to about 34% in one 64 MiB run. That is the added `index(l, "\r")` on each of 3–5 million short lines plus run-to-run noise. It amounts to under 1 s on 16 MiB of fence pairs, a shape no questions file approaches: real files are 20–186 KB and finish in about 21 ms per ID. The 3,606 ms and 3,182 ms single runs are outliers. The repeat runs (2,225 and 1,798–1,904) sit with old. The 64 MiB single-line cases stay at mawk's existing long-record cost of about 30–44 s, with no change in the complexity class. **Classification: Micro / Cold. Below Informational. Not filed.**

## Endorsements

- Every real ID on all nine local branches and in all three working trees reads the same under 4b7ec02 as under 6f24d91. None is refused. The time for about 100 IDs is unchanged (930–1505 ms new against 927–1444 ms old). `[unverified — submitted as claim]`
- Every pass-31 HTML and CR/BOM probe that gave a wrong keep, drop, done or open reading on 6f24d91 now gives a skip naming the line and the reason. No column-0 fence shape changed its reading. `[unverified — submitted as claim]`
- The new per-line checks are linear and allocation-free: `index(l, "\r")` and the anchored `^[ \t]*<` test. The `-->` scan runs only on lines that start `<!--`. On a single 64 MiB record, `bigcmt` and `bigopen` stay at mawk's existing long-record cost (34–38 s, as for `bigup`), and there is no backtracking cliff. `[unverified — submitted as claim]`
- A refusal costs exactly one awk pass and stops the ID loop. `refuse()` only records the first line (`if (!odd)`), `check_answer` returns at the first `odd`/`unbalanced`/`quoted` result, and `check_brief` returns at once. `[read: scripts/dev-cycle.sh:275, 284-296, 326-331, 461-474]`
- B's final-message change adds no check call. The In flight lines it lists are the ones each cycle already reads with `--check-brief`. `[read: skills/dev-cycle/SKILL.md:269-273, 371-375]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| none | No performance finding. Pass 31 F2 (the full-line `tolower`) is retired in code. Pass 31 F1 (the HTML-block wrong readings, cross-lane) is retired by refusal and confirmed on every rerun probe. | none | none | High (measured) |

## Overall Assessment

The pass-31 fix round is performance-neutral, as measured:
- Real archives read identically on every branch and checkout, with no refusals and no time change.
- The checks the diff adds are an `index()` scan, a BOM test on line 1 and an anchored `<` test. All stay linear on 64 MiB records, and the only visible cost is a few percent on millions of short fence lines. A refused file costs one pass, the same as an accepted one.
- All gates hold: 49/49 bats, lint rc 0, shellcheck clean, help range `2,69p` intact.

On the brief's acceptance bar, every probe I ran gave the CommonMark reading or a skip naming its line. That covers pass 31's HTML and CR/BOM probes from all four lanes, plus the new families: one-line comment variants including `<!-->`, `<!--->` and a second `<!--` after `-->`, setext, link reference definitions, tabs, NUL bytes, a BOM off line 1, CR inside a fence, and HTML inside containers. The only cost is over-refusal of non-HTML lines that start with `<`, such as autolinks, which the design accepts. No real questions file at any commit has such a line. This lane has nothing to fix. No profiling is needed.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass32.md`, with first line `Commit: 4b7ec02 (A) / f54ca74 (B)`. It follows the performance-reviewer structure: title, header, Data Flow and Hot Paths, Findings (none, with the reason and measured baselines), evidence-tagged Endorsements, Summary Table and Overall Assessment. Toward the user goal of merging `feat/dev-cycle` after a clean pass, this lane reports no known issue in this delta. Every acceptance-bar probe gave CommonMark's reading or a refusal, and no real file is refused. The synthesis can count the performance lane clean for this pass.
