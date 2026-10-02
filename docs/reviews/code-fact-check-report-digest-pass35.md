Commit: f3c9ebb (A) / 2bf03da (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at f3c9ebb; HEAD dc00bbd adds only the pass-34 review docs, and `git diff --quiet f3c9ebb HEAD -- scripts test` returns 0). B: `/workspace/.claude/wt-devcycle` (content at 2bf03da; HEAD is merge 55bdb14, whose `scripts/` and `test/` equal f3c9ebb).
**Scope:** Partial: the pass-34 fix round only. A: `git diff e93312d..f3c9ebb -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of f3c9ebb. B: `git diff 823f494..2bf03da -- skills/dev-cycle/SKILL.md docs/decisions/log.md` plus the message of 2bf03da, and merge 55bdb14. Everything else is context only (rubric section "Pass 34").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 18
**Summary:** 15 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 patterns) first. No claim here matches a logged pattern. There is no Incorrect verdict, so nothing qualifies for the log, and the brief allows no other write.

## Headline

**Every pass-34 probe now refuses or reads as CommonMark.** That covers fc34 R-A/R-B (N1, N2, N2b, N3, N3b, N8, N8b), sec34 F1/F2 (E1–E6, E8, BE1, BE3, BE5), api34's nested markers and perf34's dense `<!--` lines. Every pass-33 and earlier shape reads the same as under e93312d (P2). The one changed verdict among the older shapes is a fix in the right direction: `[a] x \]: y` used to be refused and is now read (X5), which matches CM.

- **`refdef()` is correct and complete against the acceptance bar** for the shapes I could construct. It strips any number of markers (X8 `- - - `, X9 `* + 1) `, X10 tab separators, X12 `> > - > - ` with an escaped label all refuse). The escape drop handles `\]`, `\\]` and `\\\]` the way CM does: X1 refuses, X2 reads `drop` as CM does, X3 refuses, and X4 (a trailing `\`) refuses. A `[` that starts with `\[` is still read (N14, as CM reads it).
- **`opencomment()` via `split` is exactly equivalent to the e93312d loop.** I compared the two on 300,000 random lines over `<!->x ` and found 0 differences (P3). Its edge cases hold under mawk 1.3.4: an empty line gives 0, a lone `<!--` gives 1, `<!--<!--` gives 1, `<!---->` gives 0 and `<!-->` gives 1. The check is linear. A 1 MiB dense line takes 10 ms (it took 3,824 ms under e93312d). At 16 MiB it takes 1,231 ms, which is the same as mawk takes just to read a plain 16 MiB line (943–961 ms, P4).
- **The `odd` early return changes no output.** Both END blocks test `odd` first. `refuse()` keeps only the first line. `infence`, `fline`, `qline`, `count` and `done` are read only when `odd` is unset. So nothing else needs to run after a refusal. R1–R4 (a refusal followed by an unclosed fence, a quoted heading, or a duplicate heading) print the same skip under both commits.
- **Real files:** I ran the f3c9ebb reader over 18 questions files across 9 branches and 6 working copies. All 24 read `ok` and none was refused. No tracked `.md` on main changes its verdict between e93312d and f3c9ebb (P1).
- **Gates:** bats 49/49 (rc 0), hermeticity lint clean (rc 0), shellcheck clean (rc 0) (E1).

**The three Mostly-accurate verdicts are all wording, and none is behavioral.** In each, a refusal list overstates or understates the code at its edges:
- **Claim 1** (`--check-brief` help) says a line starting with `<` is refused, without the one-line-comment exception. The `--check-answer` help (`:60`) has the same omission. It is context only and unchanged.
- **Claim 17** (skill brief clause) says only "starting with `[`", but the code also refuses lines behind blanks, `>` or list markers. It also says `--check-brief` "prints a skip for a brief with any of these", but a complete one-line `<!-- … -->`, `[a [b] c` and `[a] x \]: y` are not skipped.
- **Claim 18** (commit 2bf03da) credits the brief clause with "behind any markers", which only log 69 says.

No reader acting on these texts gets a wrong answer from the code. Severity: Low, wording. Confidence: High.

**Concurrent commit (outside this pass's fixed HEADs).** While this pass ran, adb5260 ("docs(dev-cycle): pass-35 help lists the one-line comment exception", committed 19:16:09Z) landed on wt-digest. It was not written by this review. E1 ran from 19:13:51Z to 19:14:14Z, and the status logs show HEAD dc00bbd both before and after, so every gate result here is for f3c9ebb's code. Every probe extracted the script with `git show f3c9ebb:` / `e93312d:`. All line numbers are f3c9ebb's. adb5260 rewords both help lists to "a line starting (after blanks) with < other than a complete one-line <!-- comment -->, a line leaving a <!-- open", and moves the range to `2,75p`. That closes Claim 1. P6 checked it: `--help` at adb5260 prints 74 lines ending at the Exit paragraph, and line 76 is blank (`fc35/probe6.log`). P6 checked only that, not the rest of adb5260.

**Probe discipline.** Each probe was one script. Each began with `set -eu`, created its own `mktemp -d -p fc35/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Every per-case repo was checked again after its `cd`. Every process ran under `timeout` and exited. Inside the worktrees I ran only read-only commands (`git diff/show/log/rev-parse/status/ls-tree`, `bats`, `shellcheck`, the hermeticity lint). bats ran with `TMPDIR` set to the probe's temp dir. `git status --short` plus HEAD for both worktrees was byte-identical before and after (`fc35/e1-status-before.log`, `fc35/e1-status-after.log`, `cmp` → identical). The only file written in a worktree is this report.

**Execution provenance** (all paths under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/`):
- **P1** 19:11:44Z, cwd `fc35/`: `timeout 400 bash probe1.sh` → `fc35/probe1.log`, rc 0. It extracts `FENCE_AWK` from f3c9ebb and e93312d. It runs the f3c9ebb reader over every questions file and brief on all 9 local branches (18 files; no branch tracks a brief) and over the 6 working copies, then diffs the two readers' verdicts over every tracked `.md` on main.
- **P2** 19:12:34Z, cwd `fc35/`: `timeout 590 bash probe2.sh` → `fc35/probe2.log`, rc 0. It covers 89 `--check-answer`/`--check-brief` shapes against f3c9ebb ("new") and e93312d ("old"), each with a stated CM expectation: the pass-33 and pass-34 shapes, sec34's E/BE shapes, the new X (escape and marker), S (split) and R (early-return) shapes, plus `--help` and lines 73-76 under `cat -A`.
- **P3** 19:13:12Z, cwd `fc35/`: `timeout 590 bash probe3.sh` → `fc35/probe3.log`, rc 0. It runs the opencomment equivalence fuzz (seed 35), times dense and closed lines from 256 KiB to 16 MiB, and times a refused file with 200,000 trailing lines.
- **P4** 19:13:32Z, cwd `fc35/`: `timeout 590 bash probe4.sh` → `fc35/probe4.log`, rc 0. It times a bare line read against `split` alone against the full `FENCE_AWK`, for dense and plain lines of 2–16 MiB.
- **P5** 19:17:28Z, cwd `fc35/`: `timeout 60 bash probe5.sh` → `fc35/probe5.log`, rc 0. It runs the f3c9ebb `FENCE_AWK` on single lines (`[a [b] c`, `[a] x \]: y`, `<!-- x -->`, `- [ ] see [n]: note`) and greps `--help` for `FENCE_AWK` (0).
- **P6** 19:18:06Z, cwd `fc35/`: `timeout 60 bash probe6.sh` → `fc35/probe6.log`, rc 0. It checks the `--help` range at adb5260.
- **E1** 19:13:51Z, cwd `/workspace/.claude/wt-digest` (in a subshell): `TMPDIR=<probe dir> timeout 550 bats test/scripts/dev-cycle.bats` → `fc35/e1-bats.log` (rc 0, 49 `ok`, 0 `not ok`); `timeout 60 python3 scripts/hermeticity-lint --root .` → `fc35/e1-lint.log` (rc 0); `timeout 60 shellcheck scripts/dev-cycle.sh` → `fc35/e1-shellcheck.log` (rc 0). Driver `fc35/e1.sh`, log `fc35/e1.log`.

CM labels rest on my reading of the spec. No CommonMark implementation is installed in the sandbox, as pass 34 found.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the person reading `--help`, a skip line, the decision log or a commit message.

---

## Claim 1: "\"skip <path>: <reason>\" otherwise, including a brief the reader cannot trust, naming the line and the reason: a code fence never closed or not in plain column-0 form, a line starting (after blanks) with < or leaving a <!-- open, a line starting like a link reference definition, a stray carriage return, or a byte-order mark on line 1."

**Location:** `scripts/dev-cycle.sh:36-41`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each listed cause against the `refuse()` or `unbalanced` path that emits it in `check_brief`, and confirms the list is complete. It does not establish the `--check-answer` list at `:53-64` (unchanged, context only), which carries the same `<` wording.

Each item maps to a code path. "Never closed" maps to `else if (infence) print "unbalanced " fline` (`scripts/dev-cycle.sh:359`). "Not in plain column-0 form" maps to `if (fenceish(l)) { refuse("fence"); return 1 }` and its in-fence twin (`:316`, `:320`). "Leaving a <!-- open" maps to `opencomment` (`:288-291`). "Starting like a link reference definition" maps to `refdef` (`:292-300`). "Stray carriage return" maps to `if (index(l, "\r")) { refuse("cr"); return 1 }`, which runs after `{ sub(/\r$/, "") }` (`:312`, `:356`). "Byte-order mark on line 1" maps to `NR == 1 && substr(l, 1, 3) == "\357\273\277"` (`:313`). The list is complete: `refuse()` is called with exactly fence, html, comment, refdef, cr and bom (`:312-323`).

The imprecision: `rawhtml` is `l ~ /^[ \t]*</ && !(l ~ /^[ \t]*<!--/ && index(l, "-->"))` (`:287`). So a line that starts with `<!--` and holds `-->`, such as `<!-- x -->`, is not refused, although the help says a line starting with `<` is. P2 S3/S6 and the bats one-line-comment case read such lines. The skip text for `html` does state the exception ("only a complete one-line <!-- comment --> is read", `:329`). The precise version would read "a line starting (after blanks) with < (except a complete one-line <!-- comment -->)". This is **wording**: nothing is refused that the help does not cover.

**Evidence:** `scripts/dev-cycle.sh:36-41`, `scripts/dev-cycle.sh:284-325`, `scripts/dev-cycle.sh:327-336`, `scripts/dev-cycle.sh:355-363`, `fc35/probe2.log` (briefs section; S3, S6)

---

## Claim 2: "-h|--help) sed -n '2,74p' \"$0\""

**Location:** `scripts/dev-cycle.sh:138`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the range ending exactly at the last header comment line at f3c9ebb. It does not establish that later header edits keep it in step (no test pins it).

`--help` printed 73 lines (2–74), ending "default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data." `cat -A` of lines 73-76 shows line 74 is the last `#` line, line 75 is an empty `$` and line 76 is `set -euo pipefail$` (P2 `--help` section).

**Evidence:** `scripts/dev-cycle.sh:72-76`, `scripts/dev-cycle.sh:138`, `fc35/probe2.log` (`== --help`)

---

## Claim 3: "a line starting like a link reference definition (after any > and list markers)"

**Location:** `scripts/dev-cycle.sh:271-272`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers refusal of a `[`-led line behind leading blanks, any run of `>` and any number of list markers, in any order. It does not establish CM fidelity for indented-code shapes (N7 and similar), where refusing is the design's cost, not a misreading.

`sub(/^[ \t>]*/, "", l)` and then `while (l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l); sub(/^[ \t>]*/, "", l) }` (`scripts/dev-cycle.sh:293-294`). Every iteration removes at least two characters, so the loop terminates. P2 refuses `- - `, `- > - `, `1. - `, `> - > `, `- - - `, `* + 1) `, `-⇥- ` and `> > - > - ` (N1, N2, N2b, E3–E6, X8–X10, X12). Every one of these read `drop` under e93312d except E6. Plain nested items (`- - item`, `1. 2) item`) are still read (X11).

**Evidence:** `scripts/dev-cycle.sh:292-300`, `fc35/probe2.log`

---

## Claim 4: "the last <!-- on the line has no --> after it"

**Location:** `scripts/dev-cycle.sh:288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `opencomment`'s result for every line, through exact equivalence with the e93312d loop, edge cases under mawk, and the bats second-comment case. It does not establish CM 0.31 semantics for `<!-->` / `<!--->`, which are refused (an over-refusal, the design's cost).

```awk
# scripts/dev-cycle.sh:288-291
function opencomment(l,   n, p) {  # the last <!-- on the line has no --> after it
  n = split(l, p, /<!--/)  # one linear pass; <!-- cannot overlap itself
  return n > 1 && !index(p[n], "-->")
}
```

`p[n]` is the text after the last `<!--`. The fuzz found 0 differences from the e93312d loop over 300,000 random lines, and 1,982 of them were open (P3). The edges under mawk are `""`→0, `<!--`→1, `<!--<!--`→1, `<!---->`→0 and `<!-->`→1. In P2, S1/S4/S7 refuse, S3/S5/S6 read `keep`, and fc33-R1, sec-C1–C5 and third-comment-open still refuse.

**Evidence:** `scripts/dev-cycle.sh:288-291`, `fc35/probe3.log` (equivalence), `fc35/probe2.log` (S1–S7)

---

## Claim 5: "one linear pass; <!-- cannot overlap itself"

**Location:** `scripts/dev-cycle.sh:289`
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the cost of `split` against line length, and the non-overlap property that makes the last field equal the old `substr(l, i + 4)`. It does not establish mawk's own record-read cost, which is superlinear on very long lines whatever the script does.

No proper prefix of `<!--` equals a suffix of it (`<`/`-`, `<!`/`--`, `<!-`/`!--`), so leftmost non-overlapping matches find the same last occurrence as the overlapping scan. The 300,000-line fuzz agrees (Claim 4). The timings from P3, for f3c9ebb against e93312d, were:
- 256 KiB dense: 5 ms against 154 ms.
- 1 MiB dense: 10 ms against 3,824 ms.
- 4 MiB dense: 76 ms, while e93312d was skipped as quadratic.
- 16 MiB dense: 1,231 ms.

P4 separates out the reading. At 16 MiB, a bare `length($0)` read takes 934–943 ms, `split` alone takes 1,009 ms (dense) and 940 ms (plain), and the full `FENCE_AWK` takes 1,028 ms (dense) and 961 ms (plain). So `split` adds almost nothing over reading the line. One noisy 4 MiB dense row has a 714 ms bare read.

**Evidence:** `scripts/dev-cycle.sh:289`, `fc35/probe3.log`, `fc35/probe4.log`

---

## Claim 6: "also behind any number of blockquote and list markers"

**Location:** `scripts/dev-cycle.sh:292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers any interleaving of `>` runs and `-*+` / `N.` / `N)` markers followed by a space or tab. It does not establish anything for markers CM does not accept, such as a marker with no following blank, which CM reads as text too.

The loop at `scripts/dev-cycle.sh:294` repeats while a marker leads, and strips `[ \t>]*` after each one. See Claim 3 for the shapes (P2 X8, X9, X10, X12, E3–E6, N1, N2, N2b). The bats prefixes `'- - ' '1. - ' '> - - '` pass (`test/scripts/dev-cycle.bats:948`, E1).

**Evidence:** `scripts/dev-cycle.sh:292-294`, `test/scripts/dev-cycle.bats:948-953`, `fc35/probe2.log`, `fc35/e1-bats.log`

---

## Claim 7: "Any line starting [ that holds ]: or never closes its [ with an unescaped ] (a label that continues on the next line) counts; escapes are dropped first."

**Location:** `scripts/dev-cycle.sh:295-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High (reader) / Medium-High (CM labels)
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the `[` test after marker stripping, the left-to-right drop of backslash pairs, and both arms, on escaped, double-escaped, triple-escaped and trailing-backslash labels. It does not establish CM fidelity for labels over 999 characters or blank-only labels (`[ ]`), which are refused (over-refusal, the design's cost).

```awk
# scripts/dev-cycle.sh:297-299 (excerpt ends :299; enclosing refdef() continues to :300 — read)
  if (substr(l, 1, 1) != "[") return 0
  gsub(/\\./, "", l)
  return index(l, "]:") || !index(l, "]")
```

`gsub` consumes backslash pairs left to right without overlap, so a `]` disappears only when a backslash escapes it, and `\\` disappears before the `]` that follows it. The P2 results were:
- `[a\]`/`b]: …` refuses (N3, sec-E1, E2, E8, BE1, X12).
- `[a\\]: …` refuses (X1).
- `[a\\]` followed by `b]: …` reads `drop`, which matches CM: the label closes and no `:` follows, so the lines are paragraph text (X2).
- `[a\\\]` refuses (X3).
- `[a\` refuses (X4).
- `[a] x \]: y` now reads `keep` (X5). CM agrees, because `[a]` is followed by a space and not `:`. e93312d refused this line.
- `[a\]b] text` and `[x] text` read `keep` (X6, X7).

**Evidence:** `scripts/dev-cycle.sh:292-300`, `fc35/probe2.log` (X1–X7, N3, sec-E*)

---

## Claim 8: "if (odd) return 1   # the file is already refused: nothing after it is read"

**Location:** `scripts/dev-cycle.sh:311`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `fence()` and both callers' rules after a refusal: every later line is `next`ed, and both END blocks print `odd` first. It does not cover the two rules that still run before `fence()` on each later line, `{ sub(/\r$/, "") }` and `infence && /^### Q-[0-9]+ /`. Both are inert here, because `infence` is frozen and `qline` is read only when `odd` is unset.

`function refuse(why) { if (!odd) { odd = NR; oddwhy = why } }` (`:301`). The ANSWER_AWK END starts `if (odd) print "odd " odd " " oddwhy` (`:488`). The brief END is `END { if (odd) print "odd " odd " " oddwhy; else if (infence) …` (`:359`). Neither caller reads `infence`, `fline`, `qline`, `count`, `answered` or `result` while `odd` is set, so nothing needs to run after a refusal. In P2, R1 (refusal then an unclosed fence), R2 (refusal then a fenced `### Q-1`), R3 (an in-fence refusal then a heading) and R4 (refusal then a duplicate heading) each print the same skip under f3c9ebb and e93312d, naming the first line. A file refused on line 1 followed by 200,000 lines takes 14 ms, against 110 ms before (P3).

**Evidence:** `scripts/dev-cycle.sh:301`, `scripts/dev-cycle.sh:310-325`, `scripts/dev-cycle.sh:355-359`, `scripts/dev-cycle.sh:441-493`, `fc35/probe2.log` (R1–R4), `fc35/probe3.log`

---

## Claim 9: Test literals: "for shape in '[a\]b]: /u' '[a' '[a\]'" and "for pre in '- ' '> ' '1. ' '- - ' '1. - ' '> - - '"

**Location:** `test/scripts/dev-cycle.bats:942-953`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the literals writing a real `\]` (single quotes, then `echo "$shape"` without `-e`) and the six prefixes each producing the refdef skip. It does not establish brief-side coverage of the new shapes (BE1/BE3 are probed in P2, not in bats).

`'[a\]b]: /u'` in single quotes keeps one backslash, and bash's builtin `echo "$shape"` (`:943`) does not interpret it. So the file holds `[a\]b]: /u`, which is an escaped bracket. The old `'[a\\]b]: /u'` held `\\`, an escaped backslash. All 49 tests pass (E1).

**Evidence:** `test/scripts/dev-cycle.bats:942-953`, `fc35/e1-bats.log`

---

## Claim 10: "opencomment() splits once on <!-- instead of re-scanning the rest of the line per match (quadratic: 3.3 s on a 1 MiB line of <!--, now about 10 ms); fence() stops examining lines once the file is refused."

**Location:** commit f3c9ebb message
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the timing on this machine and the early return. It does not establish timings on other awks (only mawk 1.3.4 is installed).

P3 measured 1 MiB dense at 10 ms under f3c9ebb and 3,824 ms under e93312d. Perf34 had 3,342 ms. For the early return, see Claim 8 (`scripts/dev-cycle.sh:311`).

**Evidence:** `scripts/dev-cycle.sh:288-291`, `scripts/dev-cycle.sh:311`, `fc35/probe3.log`

---

## Claim 11: "refdef() strips any number of > and list markers ('- - [x]:', '1. - [x]:', '> - - [x]:' now refuse) and drops backslash escapes before testing, so '[a\]' counts as an unclosed label."

**Location:** commit f3c9ebb message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the three named prefixes and `[a\]`. It does not establish anything past Claims 3, 6 and 7.

These are bats prefixes (`test/scripts/dev-cycle.bats:948`) and the `'[a\]'` shape (`:942`), all passing (E1). P2 adds N1, N2b and N3.

**Evidence:** `scripts/dev-cycle.sh:292-300`, `fc35/e1-bats.log`, `fc35/probe2.log`

---

## Claim 12: "--check-brief's help lists its own refusals in plain words instead of naming an internal variable."

**Location:** commit f3c9ebb message
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the removal of "FENCE_AWK" from the help text. It does not establish the list's precision, which is Claim 1.

The old help, "including a brief FENCE_AWK refuses (as for --check-answer, …)", is replaced by the list at `scripts/dev-cycle.sh:37-41`, which names no variable. `FENCE_AWK` now appears only in code comments and code (`:284`, `:340`, `:353`, `:419-421`), and lines 2-74 contain no `FENCE_AWK` (paraphrased — no quote available because the claim covers absence: `bash dc.sh --help | grep -c FENCE_AWK` at f3c9ebb gives 0, P5).

**Evidence:** `scripts/dev-cycle.sh:36-41`

---

## Claim 13: "49/49; shellcheck and the hermeticity lint clean; no real ID refused."

**Location:** commit f3c9ebb message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers bats, lint and shellcheck at f3c9ebb, and every questions file on all 9 local branches plus 6 working copies. It does not establish files on branches not present locally.

E1 gives bats rc 0 (49 ok, 0 not ok), lint rc 0 ("126 test file(s) checked, no unstubbed network spawns") and shellcheck rc 0. P1 gives 24/24 `ok` and no verdict change on main's tracked `.md` files.

**Evidence:** `fc35/e1.log`, `fc35/e1-bats.log`, `fc35/e1-lint.log`, `fc35/e1-shellcheck.log`, `fc35/probe1.log`

---

## Claim 14: Decision log 69's refusal list: "any fence-like line that is not a plain column-0 fence, a line starting (after blanks) with `<` (except a complete one-line comment), a `<!--` left open on its line, a line that starts like a link reference definition (behind any `>` and list markers), a stray CR, a BOM on line 1, a fence open at the end, or (for questions files) a question heading inside a fence."

**Location:** `docs/decisions/log.md:92` (wt-devcycle, 2bf03da)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each item against its code path, and the list's completeness (the six `refuse()` reasons, unbalanced and quoted). It does not establish the skip consequences in the same row ("stays off `Applied:` …"), which are unchanged context.

The items map to `fenceish`/`refuse("fence")` (`scripts/dev-cycle.sh:316`, `:320`), `rawhtml` with its one-line-comment exception (`:287`), `opencomment` (`:288-291`), `refdef` after blanks, `>` and markers (`:292-300`), `cr` and `bom` on `NR == 1` (`:312-313`), and `unbalanced` in both ENDs (`:359`, `:489`). `quoted` exists only in ANSWER_AWK (`infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }`, `:462`), which matches "(for questions files)". P2 exercises every item.

**Evidence:** `docs/decisions/log.md:92`, `scripts/dev-cycle.sh:284-325`, `scripts/dev-cycle.sh:441-493`, `fc35/probe2.log`

---

## Claim 15: "rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` passes 30–34"

**Location:** `docs/decisions/log.md:92` (references column)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the reference at merge 55bdb14. It does not establish it at 2bf03da alone, where the rubric ends at Pass 33.

At 55bdb14 the rubric has "## Pass 30 …" through "## Pass 34 (review-fix loop, k=1, all critics; on e93312d digest / 823f494 skill)" (lines 722, 738, 751, 766, 781). At 2bf03da, Pass 34 is absent. It arrives with the merge, which is the state the brief reviews.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:722-781`

---

## Claim 16: "no line starting with `<` (write placeholders as `NAME`, not `<name>`, even indented)"

**Location:** `skills/dev-cycle/SKILL.md:336-337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers an indented `<` being refused, as the clause warns. It does not establish the consequence sentence's precision for complete one-line comments (Claim 17).

`rawhtml` matches `/^[ \t]*</` (`scripts/dev-cycle.sh:287`). P2 brief-indented-lt (`  <x>`) prints "line 2 starts with < after any blanks …". A mid-line `<name>` is read (brief-midline-placeholder → `ok … open`).

**Evidence:** `scripts/dev-cycle.sh:287`, `fc35/probe2.log` (briefs)

---

## Claim 17: "no line starting with `[` that holds `]:` or leaves its `[` open (a link reference definition, or text that starts like one), no stray carriage return and no byte-order mark: `--check-brief` prints a skip for a brief with any of these"

**Location:** `skills/dev-cycle/SKILL.md:338-340`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the `[` item against `refdef`, and the consequence sentence against the clause's whole list. It does not establish the CR, BOM and fence items, which match the code (P2 brief-bom, sec-B1).

The mechanism is right for the plain case: `[x]: /u` refuses (brief-refdef), and `[a`/`b]: …` refuses (sec-B2). The clause is imprecise at three edges. This is **wording only**, and no brief gets a wrong state from it:
- **The code refuses more than "starting with `[`".** It also refuses after blanks, `>` and any list markers (`sub(/^[ \t>]*/, "", l)` and the `while` loop, `scripts/dev-cycle.sh:293-294`). Briefs N8, BE3 and BE5 (`- - [x]: …`, `- > - [x]: …`) are skipped, and so is a task item `- [ ] see [n]: note` (N13). An author following the clause would not expect those.
- **"Prints a skip for a brief with any of these" overstates the `[` item.** `holds ]:` and `open` are judged after escapes are dropped, and `open` means "no `]` at all" (`return index(l, "]:") || !index(l, "]")`, `:299`). So `[a] x \]: y` (it holds a raw `]:`) and `[a [b] c` (its first `[` is never matched) are read, not skipped (P2 X5; P5 prints `ok` for both). `- [ ] see [n]: note` is refused (P5 `odd 1 refdef`). CM agrees with the reads.
- **The same sentence covers the `<` item**, but a complete one-line `<!-- … -->` line is read, not skipped (`:287`, P2 S3/S6).

A precise version: "no line starting, after any blanks, `>` and list markers, with `[` that holds an unescaped `]:` or no unescaped `]` …", and "(a complete one-line `<!-- … -->` is allowed)", or else drop "with any of these" in favour of "for these".

**Evidence:** `skills/dev-cycle/SKILL.md:335-341`, `scripts/dev-cycle.sh:287`, `scripts/dev-cycle.sh:292-300`, `fc35/probe2.log` (N8, sec-BE3, sec-BE5, N13, X5, S3, S6), `fc35/probe5.log`

---

## Claim 18: "log 69 and the brief clause now describe what the code refuses ('<' after blanks, a BOM on line 1, lines that start like a reference definition behind any markers, question headings only for questions files); log 69 cites passes 30-34."

**Location:** commit 2bf03da message
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the claim against both changed texts at 2bf03da, with the rubric at 55bdb14. It does not establish anything beyond Claims 14, 15 and 17.

For log 69 the claim is accurate (Claims 14, 15). For the brief clause, "lines that start like a reference definition behind any markers" does not hold. The clause says "no line starting with `[` …" and names no markers (`skills/dev-cycle/SKILL.md:338-339`, quoted in Claim 17). "A BOM on line 1" is likewise unqualified there ("no byte-order mark"), which is harmless because only line 1 can carry one. "'<' after blanks" is in the clause as "even indented" (Claim 16). The commit message is immutable, so a fix would go in the clause (Claim 17). **Wording.**

**Evidence:** `docs/decisions/log.md:92`, `skills/dev-cycle/SKILL.md:335-341`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 1** (`scripts/dev-cycle.sh:36-41`): the `--check-brief` help says a line starting with `<` is refused, without the one-line-comment exception. The identical `--check-answer` phrase at `:59-60` is context only. **Wording. Already addressed by adb5260**, which landed during this pass and is outside its fixed HEADs; P6 checked its help range.
- **Claim 17** (`skills/dev-cycle/SKILL.md:338-340`): the brief clause says "starting with `[`", but the code also refuses after blanks, `>` and list markers. "Prints a skip for a brief with any of these" overstates it: `[a] x \]: y`, `[a [b] c` and a one-line `<!-- … -->` are read. **Wording.**
- **Claim 18** (commit 2bf03da): it credits the brief clause with "behind any markers", which only log 69 says. The commit is immutable, so the fix belongs in the clause (Claim 17). **Wording.**

### Unverifiable
None.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass35.md`. Its first line is `Commit: f3c9ebb (A) / 2bf03da (B)`, and its header carries `**Replication:** k=1 (loop pass, decision 031)`. It follows `skills/code-fact-check/SKILL.md`: header fields, the seven mandatory per-claim fields plus Legibility-target, quote-or-paraphrase evidence, provenance for executed verdicts, and the attention summary.

For the user goal (a clean pass, then merge): every pass-34 probe now refuses or reads as CommonMark, nothing in this round is behavioral, and no real file is refused. Three wording imprecisions were found in refusal lists (Claims 1, 17, 18). adb5260, which landed mid-pass, already fixes Claim 1. Claim 17 (the skill's brief clause) is the one still open in the shipped text, and Claim 18 is an immutable commit message that points at it. None is Medium or above, and none is in log 69's accepted class, because they concern documentation, not the reader.
