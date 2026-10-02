Commit: fd22d29 (A) / 5085e64 (B)

# Performance Review: dev-cycle pass 33 (pass-32 fix round, k=1 delta)

**Scope:** Partial. A: `git diff 4b7ec02..fd22d29 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. That worktree's HEAD, a257403, adds only review docs. B: `git diff f54ca74..5085e64 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` in `/workspace/.claude/wt-devcycle`. Merge 6ea4f68 carries the same `scripts/dev-cycle.sh` and bats file as fd22d29: `git diff fd22d29 6ea4f68 --stat` on those paths is empty. Everything else is context only.
**Date:** 2026-10-02
**Based on:** the Stage-1 context `code-fact-check-report-digest-pass32.md`, which covers 4b7ec02 (the base of this delta, not fd22d29), plus pass 32's numbers and probes in `scratchpad/perf32/`. No fact-check covers fd22d29 as Stage-1 input. Every runtime endorsement below is therefore tagged `[unverified — submitted as claim]`.

**Measurements.** I took every number myself on 2026-10-02 in this sandbox. `awk` here is mawk 1.3.4 20200120. "new" is `git show fd22d29:scripts/dev-cycle.sh` and "old" is `4b7ec02:…`. The two ran interleaved in the same loops. P1 and P2 ran at the same time, so absolute times carry contention noise, and only the old/new pairs within a loop are comparable. Scratch lives in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf33/` (`perf33/` below).

Probe discipline: each probe is one `set -eu` script. It creates its own `mktemp -d -p perf33` dir in that same script and checks `case "$PWD"` before any `git init`, commit or write. Every process ran under `timeout`, and all of them exited with rc 0 before this report was written. `pgrep -af perf33` matched only the pgrep itself. Nothing was written to either worktree except this file. The other untracked `*-pass33.md` files in `docs/reviews/` belong to sibling critics. `/workspace` stayed on `main`.

- **P1** (`perf33/p1.sh`, `p1.log`) runs end to end through `dev-cycle.sh`:
  - every ID in the committed questions files of all nine local branches, and in the three checkouts' working trees, old against new;
  - every real brief, of which none exists: `git ls-tree` shows 0 files under `docs/working/briefs/` on every branch;
  - a census of the lines that hold `<!--` and the lines that start with `[`;
  - the real archive at 1×, 10× and 100× (17 MiB, 8,900 entries).
- **P2** (`perf33/p2.sh`, `p2.log`) times the awk program `"$FENCE_AWK$ANSWER_AWK"` alone, old against new, two runs each, on 13 shapes aimed at the two new functions. Seven of them also ran at 64 MiB. After that it runs the gates on `git archive fd22d29`.
- **P3** (`perf33/p3.sh`, `p3.log`) covers the shapes that brief claim 1 names, the cost of an early refusal followed by 16 MiB, and three briefs.
- **P4** (`perf33/p4.sh`, `p4.log`) covers link reference definitions that `refdef()` does not see. This probe is cross-lane; see the end of Findings.

Legibility-target values: **maintainer** (someone editing the script) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle.
- `--check-answer` runs one awk pass per ID per questions file (`scripts/dev-cycle.sh:482`), so a batch of k IDs costs at most 2k passes. Real files are about 20 KB and 186 KB.
- `--check-brief` makes one pass over one blob per brief (`:337`). Briefs are a few KB, and none exists yet on any branch.

**What the diff adds per line.** It changes `fence()` (`:293-307`, read in full). The new work runs only on lines that are outside a fence and were not already refused by `fenceish` or `rawhtml`:
- `opencomment(l)` (`:282`) is one `index(l, "<!--")` scan per line. Only when that finds a hit does it copy the rest of the line with `substr(l, i + 4)` and scan the copy for `-->`. That is one copy, bounded by the line length.
- `refdef(l)` (`:283`) is one anchored regex, `^[ \t]*\[[^]]+\]:`. It can match at line start only, and its single variable-length part, `[^]]+`, has exactly one way to end (the first `]`).
- On line 1, the BOM test is the same 3-byte `substr` as before, now split from the CR test (`:294-295`). This adds no work.
- A refusal still only records the first offending line (`refuse()`, `if (!odd)`). awk keeps reading to the end, as before. The shell side runs one `$(oddwhy …)` per refused file, then returns.

## Findings

No findings.

The measured costs are recorded below so the next pass has a baseline. None of them reaches Informational: each is Micro or linear, and each sits on a cold path.

| Shape (P2, awk alone) | Size | old ms (r1/r2) | new ms (r1/r2) | Reading old → new |
|---|---|---|---|---|
| `prose` (74-byte lines) | 16 / 64 MiB | 107/107, 465/524 | 122/121, 548/588 | drop → drop |
| `pairs` (fence pairs) | 16 / 64 MiB | 3,112/1,752, 9,763/7,927 | 1,696/1,684, 8,237/7,638 | drop → drop |
| `midcmt` (closed `<!-- … -->` mid-line, every line) | 16 / 64 MiB | 129/129, 548/590 | 157/157, 713/2,142 | drop → drop |
| `refs` (`[label] text`, no colon) | 16 MiB | 139/138 | 169/178 | drop → drop |
| `tasks` (`- [ ]`, `- [x]:`) | 16 MiB | 327/351 | 373/396 | drop → drop |
| `bigup` (one all-capitals line) | 16 / 64 MiB | 1,480/1,204, 37,587/34,880 | 1,208/1,268, 41,273/37,534 | drop → drop |
| `bigmid` (`x <!--` + N, never closed) | 16 / 64 MiB | 1,166/1,323, 50,532/45,089 | 1,067/1,305, 42,612/33,733 | drop → `odd 4 comment` |
| `bigmidcl` (`x <!--` + N + `-->`) | 16 MiB | 1,055/1,372 | 1,007/1,010 | drop → drop |
| `bigbrk` (`[` + N `x`) | 16 / 64 MiB | 1,182/921, 33,000/53,653 | 1,780/1,541, 35,656/44,512 | drop → drop |
| `bigbrk2` (N `[`) | 16 / 64 MiB | 793/789, 44,016/41,483 | 2,820/1,721, 47,768/39,593 | drop → drop |
| `bigbrkc` (`[` + N + `]:`) | 16 MiB | 1,341/781 | 1,436/1,505 | drop → `odd 4 refdef` |
| `manyopen` (one line of N/5 × `<!-- `) | 16 MiB | 918/1,113 | 782/1,034 | drop → `odd 4 comment` |
| `sptail` (N spaces + `[x]`) | 16 MiB | 1,706/1,795 | 1,982/2,125 | drop → drop |

How to read the table:
- **Short-line files.** The new checks cost about 13–30% on 16–64 MiB of short lines: `prose`, `midcmt`, `refs` and `tasks`. That is the added `index(l, "<!--")` scan plus the anchored `refdef` test on each of 0.2–1.4 million lines, and it amounts to at most 0.17 s at 64 MiB. The 2,142 ms `midcmt` run is a single outlier, since r1 was 713 ms.
- **Single-line files.** These show the only visible relative cost, at 16 MiB: `bigbrk` went from about 1.0 to 1.6 s, and `bigbrk2` from about 0.8 to 1.7–2.8 s.
- **Scaling.** At 64 MiB, every single-line shape (`bigmid`, `bigbrk`, `bigbrk2`) lands inside the band of mawk's existing long-record cost (33–54 s, the same as `bigup`). Old and new overlap there. So `refdef`'s `[^]]+` and `opencomment`'s copy stay linear, with no backtracking cliff. Classification: Micro / Cold. This is below Informational, so it is not filed.
- **Real files.** Under 4b7ec02 against fd22d29:
  - 100 archive IDs: 2,586 against 1,240 ms at 1×, and 1,977 against 2,179 ms at 10×. At 100× (17 MiB, the size of `prose` 16 MiB) it was 8,301 against 9,505 ms, about 12 ms more per ID, the same ratio as `prose`.
  - One archive ID: 28–30 ms against 27–30 ms.
  - About 100 IDs on each branch or checkout: 999–1,826 ms old against 989–2,493 ms new. The 2,493 ms is a single first run; r2 was 1,052 ms.

**Cross-lane observation (correctness, not performance; for the fact-check and security lanes).** This is not a performance finding, so it is not in the Summary Table. It is recorded because the brief puts anything outside the decision-69 limit in scope.

- **Severity:** Low. Under this skill's scale it does not grade, because it is not a performance problem. On the brief's acceptance bar it is outside the accepted class, because a link reference definition is a block construct. Preconditions: someone writes a reference definition whose label holds an escaped `]` or a line break, with a title that spans lines, above the answer line.
- **Location:** `scripts/dev-cycle.sh:283` (`refdef`), as called by `fence()` at `:305`.
- **Evidence (verbatim, P4 on fd22d29):**
  - The probe places these lines between the header line and `- Q-1: [1]`. It adds a blank line after the header, so each definition starts after a blank line.
  - `[x]: /u 't` / `Q-1: [2]` / `'`, with the plain label, gives: `skip Q-1: line 6 of docs/working/questions.md is a link reference definition (its title can span lines), so no entry in docs/working/questions.md is read`
  - `[a\]b]: /u 't` / `Q-1: [2]` / `'` gives `drop Q-1`.
  - `[a` / `b]: /u 't` / `Q-1: [2]` / `'` gives `drop Q-1`.
  - `[` / `foo` / `]: /u 't` / `Q-1: [2]` / `'` gives `drop Q-1`.
- **CommonMark reading (spec-derived):** in each case the whole block is one definition, and its title `'t\nQ-1: [2]\n'` hides the `Q-1: [2]` line. The reader should therefore answer `keep` (from the real `- Q-1: [1]`) or refuse. This rests on CommonMark 0.31 §4.7: a label may contain backslash-escaped brackets and may span lines, as the spec's own examples `[Foo*bar\]]:my_(url) 'title (with parens)'` and `[\nfoo\n]: /url` show. No implementation is installed here.
- **Confidence:** High on the code's behavior, which was executed. Medium on the CommonMark reading.
- **Legibility-target:** maintainer.
- **Fix:** a cheap one that costs no measurable performance. Refuse any line outside a fence that starts (after up to three spaces) with `[` and holds no closing `]` on that line. Also allow `\\.` in the label: `^[ \t]*\[([^]\\]|\\.)+\]:`. Alternatively, let decision log 69 name this shape. This is the same "whoever can write it can write the answer" argument the user applied to the inline class.

## Endorsements

- Every real ID on all nine local branches and in all three working trees reads the same under fd22d29 as under 4b7ec02, and none is refused (P1: `answer readings old = new`, `new skips: 0` in all 12 sets). The census found no line that opens a comment it does not close: all four `<!--` lines are complete `<!-- index:start/end -->` lines. It also found no reference definition: the two lines that start with `[` are `[confidence: high], …` and `[1] was rejected …`. No branch holds a brief. `[unverified — submitted as claim]`
- `opencomment` and `refdef` stay linear on 64 MiB single records. A file refused by either costs the same single pass as an accepted one: P3's line-2 refusal followed by 16 MiB took 103–113 ms, against 97–119 ms for the unrefused control. `[unverified — submitted as claim]`
- The claim-1 shapes behave as the brief describes (P3, end to end):
  - a `[x]:` line inside a fence, a `[x]` line without a colon, `- [x]:` and `> [x]:` are all read;
  - a closed mid-line comment is read;
  - an unclosed mid-line comment is refused as `comment`, and an indented `[x]:` is refused as `refdef`.
  - A `<!--` inside a mid-line code span is refused as `comment`, which is over-refusal accepted by the design. No real file has one. The bats case's "code spans are read" covers `<your answer>`, not `<!--`. `[unverified — submitted as claim]`
- The help range `sed -n '2,70p'` prints exactly the header block. Line 70 is the block's last comment line and line 71 is empty (P2: 69 help lines). Gates on `git archive fd22d29`: bats 49 ok / 0 not ok, hermeticity-lint rc 0, shellcheck rc 0. `[unverified — submitted as claim]`
- B adds no check call. The final message's "marking any `--check-brief` refused, with its reason" reuses the `--check-brief` output each cycle already produces for In flight. `[read: skills/dev-cycle/SKILL.md:333-338, 374-379 at 5085e64]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| none | No performance finding. Both new per-line checks are linear and allocation-light. At most they cost about 13–30% on 16–64 MiB of short lines (0.17 s at most), and about 12 ms per ID on a 17 MiB archive. On 64 MiB single lines they stay within mawk's existing long-record band. | none | none | High (measured) |
| (cross-lane) | `refdef()` misses reference definitions with an escaped `]` or a multi-line label. Their multi-line title can hide an answer line (P4). This is not performance and is outside the decision-69 class. | Low (outside this skill's scale) | `scripts/dev-cycle.sh:283` | High (code) / Medium (CM) |

## Overall Assessment

The pass-32 fix round is performance-neutral as measured:
- Real questions files on every branch and checkout read identically to 4b7ec02, with no refusals. No real brief exists anywhere.
- The added `index()` scan, the copy made only when `<!--` appears, and the anchored `refdef` regex scale linearly to 64 MiB records with no backtracking cliff.
- The relative cost on huge short-line files is about a sixth, in absolute terms a tenth of a second. That is irrelevant at the real sizes of 20–186 KB, cold path, about 25 ms per ID.
- All gates hold: 49/49 bats, lint rc 0, shellcheck clean, and help range `2,70p` exact.

The performance lane has nothing to fix and needs no profiling. The one item worth routing is cross-lane: `refdef()`'s label pattern misses escaped-bracket and multi-line labels. A one-line regex change closes it at no measurable cost, or log 69 can name it as accepted.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass33.md`, with the first line `Commit: fd22d29 (A) / 5085e64 (B)`. It follows the performance-reviewer structure: title, header, Data Flow and Hot Paths, Findings (none in this lane, with measured baselines), evidence-tagged Endorsements, Summary Table and Overall Assessment.

Toward the user goal of merging `feat/dev-cycle` after a clean pass: the performance lane is clean for this delta. The cross-lane `refdef` gap is the one thing synthesis should weigh against the acceptance bar before calling the pass clean.
