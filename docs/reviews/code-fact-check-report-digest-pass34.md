Commit: e93312d (A) / 823f494 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at e93312d; HEAD 9dfbf82 adds only the pass-33 review docs, and `git diff --quiet e93312d HEAD -- scripts test` returns 0). B: `/workspace/.claude/wt-devcycle` (content at 823f494; HEAD is merge ba93f23).
**Scope:** Partial: the pass-33 fix round only. A: `git diff fd22d29..e93312d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of 5630135, 0db12bd and e93312d. B: `git diff 5085e64..823f494 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` plus the messages of 12f4cd6 and 823f494, and merge ba93f23. Everything else is context only (rubric section "Pass 33").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 30
**Summary:** 21 verified, 3 mostly accurate, 0 stale, 6 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 patterns) first. No claim here matches a logged pattern. No Incorrect verdict is a fabricated symbol, API or flag, so nothing qualifies for the log, and the brief allows no other write.

## Headline

**Every pass-33 probe now refuses or reads as CommonMark** (fc33 R1/R2 and probe3 shapes, sec33 C1–C5, B1, R1–R5, B2; api33's container refdefs; perf33 P4's escaped/multi-line refdefs). `opencomment()` is correct and complete for the inline-comment refusal (Claim 6). The gates are green, and no real file is refused.

**The six Incorrect verdicts share two new roots in `refdef()`. Both are behavioral, and both are outside log 69's accepted class (a reference definition is a block construct, and row 69 lists it as refused):**
- **R-A: only one list marker is stripped.** For example, `- - [x]: /u 'title` (or `- > - [x]:`, `1. - [x]:`) followed by a lazy `Q-1: [2]` / `end'` reads `drop`. CM hides the line in the title and reads the later `[1]` (`keep`). The brief variant reads `done` where CM reads `open`.
- **R-B: a label whose first line holds only an escaped `]`.** `[a\]` / `b]: /u 'title` / `Q-1: [2]` / `end'` reads `drop` where CM reads `keep`. The brief variant reads `done` where CM reads `open`. The line holds a `]`, so the "never closes" test passes, but it holds no `]:`. The label continues on the next line, as spec example 166 allows.

Claims 4b, 7, 8, 15a, 19a and 22a restate R-A/R-B in six places. One code change closes all six. Preconditions: an ANSWERED entry or a brief holds such a line outside fences, with a column-0 answer or `Status:` line as lazy continuation. **No real file has either shape** (P1). Severity: Low. Confidence: High for the reader's output (executed), Medium-High for the CM reading (spec reasoning; no CommonMark implementation is installed in the sandbox: `markdown_it`, `commonmark`, `mistune`, `cmark` and `pandoc` are all absent).

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc34/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Every per-case repo was checked again after its `cd`. Every process ran under `timeout` and exited. Inside the worktrees I ran only read-only commands (`git diff/show/log/rev-parse/status/ls-tree`, `bats`, `shellcheck`, the hermeticity lint). bats ran with `TMPDIR` set to the probe's temp dir. `git status --short` plus HEAD in wt-digest was byte-identical before and after (`fc34/e1-status-before.log`, `fc34/e1-status-after.log`, `cmp` → identical), and `git status --short` in wt-devcycle was empty. The only file written in a worktree is this report.

**Execution provenance** (all paths under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/`):
- **P1** 18:53:28Z, cwd `fc34/`: `timeout 300 bash probe1.sh` → `fc34/probe1.log`, rc 0. It extracts `FENCE_AWK` from e93312d and fd22d29. It runs the e93312d reader over every real questions file and brief on all 9 local branches (18 files, all questions files; no brief is tracked on any branch) and over the 6 gitignored working copies. It greps every `]:` line in those files, and it diffs the two readers' verdicts over every tracked `.md` on main.
- **P2** 18:54:47Z, cwd `fc34/`: `timeout 500 bash probe2.sh` → `fc34/probe2.log`, rc 0. It covers 52 `--check-answer`/`--check-brief` shapes against e93312d and fd22d29, each with a stated CM expectation, plus `--help` and lines 71-73 under `cat -A`.
- **E1** 18:55:07Z, cwd `/workspace/.claude/wt-digest`: `TMPDIR=<probe dir> timeout 550 bats test/scripts/dev-cycle.bats` → `fc34/e1-bats.log` (rc 0, 49 `ok`, 0 `not ok`); `timeout 60 python3 scripts/hermeticity-lint --root .` → `fc34/e1-lint.log` (rc 0); `timeout 60 shellcheck scripts/dev-cycle.sh` → `fc34/e1-shellcheck.log` (rc 0). Driver `fc34/e1.sh`, log `fc34/e1.log`.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the person reading `--help`, a skip line, the decision log or the final message.

---

## Claim 1: "\"skip <path>: <reason>\" otherwise, including a brief FENCE_AWK refuses (as for --check-answer, naming the line and the reason)."

**Location:** `scripts/dev-cycle.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the skip line's form for every FENCE_AWK refusal reason on a brief. It does not establish that every brief CM would mis-read is refused (see Claims 4b, 22a).

The brief path prints `echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read"` (`scripts/dev-cycle.sh:354`). P2 shows the line and the reason for the html, comment, refdef and bom reasons, e.g. `skip docs/working/briefs/2026-01-01-x.md: line 2 opens an HTML comment that does not close on the same line, so the brief is not read` (sec-B1).

**Evidence:** `scripts/dev-cycle.sh:36-38`, `scripts/dev-cycle.sh:348-356`, `fc34/probe2.log`

---

## Claim 2: "a code fence never closed or not in plain column-0 form, a line starting (after blanks) with < or leaving a <!-- open, a line starting like a link reference definition, a stray carriage return, a byte-order mark on line 1, a question heading inside a fence, a questions file that is not plain"

**Location:** `scripts/dev-cycle.sh:54-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the list as a description of what causes a skip. Each item matches one refusal in the code, and every refusal the code makes is listed. It does not establish that every definition CM would read starts the way `refdef()` tests (R-A/R-B, Claim 8).

The pass-33 residue is fixed. The help now says "(after blanks)", matching `/^[ \t]*</` (`scripts/dev-cycle.sh:283`), and "on line 1", matching `NR == 1 && substr(l, 1, 3) == "\357\273\277"` (`:306`). "Leaving a <!-- open" matches the last-`<!--` test (`:284-287`). "Starting like" is accurate wording for a test on the line's start (`:293`). R-A/R-B lines do not start the way `refdef()` tests, so the help does not misdescribe them, but it also does not promise to catch them.

**Evidence:** `scripts/dev-cycle.sh:54-61`, `scripts/dev-cycle.sh:283-316`, `fc34/probe2.log`

---

## Claim 3: help range `sed -n '2,71p'` covers the header

**Location:** `scripts/dev-cycle.sh:135`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the help range against the header at e93312d. It does not establish behavior after a future header edit.

`-h|--help) sed -n '2,71p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`:135`). Line 71 is the last header line (`# default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data.`), and line 72 is empty (`$` under `cat -A`). `--help` printed 70 lines, ending on that sentence (P2).

**Evidence:** `scripts/dev-cycle.sh:2-72`, `scripts/dev-cycle.sh:135`, `fc34/probe2.log`

---

## Claim 4a: "one that opens an HTML comment it does not close"

**Location:** `scripts/dev-cycle.sh:268`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the comment refusal for every pass-33 shape and for multiple comments on a line. Over-refusals (a code-span `<!--`, `<!-->`, `<!--->`) are the design's cost and are not examined further.

See Claim 6 for the code. In P2, fc33-R1, linestart-closed-then-open, third-comment-open and sec-C1–C5 all print `opens an HTML comment that does not close on the same line`. At fd22d29 they printed `drop Q-1`.

**Evidence:** `scripts/dev-cycle.sh:265-273`, `scripts/dev-cycle.sh:284-287`, `fc34/probe2.log`

---

## Claim 4b: "a link reference definition ... fence() records the first one's line number in `odd` ... and the caller refuses the whole file"

**Location:** `scripts/dev-cycle.sh:268-271`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High (reader) / Medium-High (CM)
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the refdef refusal for the shapes in P2. It does not establish CM's reading beyond spec reasoning (examples 166 and the nested-list/lazy-continuation examples).

Two kinds of definition are read, not refused (roots R-A, R-B):
- **R-A (nested list markers).** `N1-nested-list` (`- - [x]: /u 'title` / `Q-1: [2]` / `end'` / blank / `Q-1: [1]`) prints `drop Q-1`. CM reads `keep`: the inner list item's paragraph takes `Q-1: [2]` and `end'` as lazy continuation, so they become the definition's title. `N2-list-bq-list` (`- > - [x]:`) and `N2b-ol-ul` (`1. - [x]:`) also print `drop`.
- **R-B (escaped-`]` first line).** `N3-escaped-close-then-spans` (`[a\]` / `b]: /u 'title` / `Q-1: [2]` / `end'`) prints `drop Q-1`, where CM reads `keep`. `N3b` behind a list marker does the same.
- **Briefs.** `N8-nested-list` and `N8b-escaped-spans` print `ok ... done` where CM reads `Status: open`.

The pass-33 shapes are all refused now (Claim 14).

**Evidence:** `scripts/dev-cycle.sh:288-294`, `fc34/probe2.log` (N1, N2, N2b, N3, N3b, N8, N8b)

---

## Claim 5: "Accepted limit (decision log 69): inline constructs that span lines (an open tag attribute, link title, code span, emphasis, or a processing instruction, CDATA section or declaration opened mid-line) are not modelled ... no real file has one."

**Location:** `scripts/dev-cycle.sh:274-278`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the claim that FENCE_AWK has no logic for these constructs, and that a line *starting* with `<?`, `<![CDATA[` or `<!X` is refused by `rawhtml`. "No real file has one" rests on P1's 18 files reading `ok` and is not a construct-by-construct grep.

FENCE_AWK (`:280-319`, read whole) holds no code-span, emphasis, attribute or PI/CDATA/declaration logic. `function rawhtml(l) { return l ~ /^[ \t]*</ && !(l ~ /^[ \t]*<!--/ && index(l, "-->")) }` (`:283`) refuses any line starting with `<` after blanks, which covers line-start PI/CDATA/declarations. The wording matches row 69 (Claim 21).

**Evidence:** `scripts/dev-cycle.sh:274-319`, `fc34/probe1.log`

---

## Claim 6: "the last <!-- on the line has no --> after it"

**Location:** `scripts/dev-cycle.sh:284-287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High (reader) / Medium-High (CM completeness)
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the loop finding the last `<!--`, and the claim that this test catches every line that leaves a comment open under CM 0.31's comment rule. It does not establish anything about `<!--` inside multi-line inline constructs (accepted class).

```awk
# scripts/dev-cycle.sh:284-287
function opencomment(l,   i, j) {  # the last <!-- on the line has no --> after it
  i = 0; while ((j = index(substr(l, i + 1), "<!--")) > 0) i += j
  return i && !index(substr(l, i + 4), "-->")
}
```

`i += j` turns the substring offset into an absolute one, so `i` ends at the last `<!--`. Completeness (paraphrased — no quote available because this is reasoning over the spec, not code): a CM comment that opens at any `<!--` ends at the first `-->` after it. If a `-->` follows the last `<!--`, every comment opened on the line closes on it, and that holds even when some `<!--` sits in a code span. So the test misses nothing. Its only errors are over-refusals (`<!-->`, `<!--->`, a code-span `<!--`; N11 and codespan-open-comment in P2), which are the design's cost. The rule is correct and complete.

**Evidence:** `scripts/dev-cycle.sh:284-287`, `scripts/dev-cycle.sh:315`, `fc34/probe2.log`

---

## Claim 7: "also behind blockquote markers and list markers"

**Location:** `scripts/dev-cycle.sh:288`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High (reader) / Medium-High (CM)
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the container prefixes `refdef()` strips. It does not establish CM's reading beyond spec reasoning.

```awk
# scripts/dev-cycle.sh:289-290 (excerpt ends :290; enclosing refdef() continues to :294 — read)
  sub(/^[ \t>]*/, "", l)
  if (l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l); sub(/^[ \t>]*/, "", l) }
```

The code strips any number of `>`, then **one** list marker, then `>` again. A second list marker is left in place, so `- - [x]:`, `- > - [x]:` and `1. - [x]:` start with `-` and are not refused. All three read `drop` (root R-A, P2 N1/N2/N2b). The plural "list markers" claims more than one, so it does not hold.

**Evidence:** `scripts/dev-cycle.sh:288-294`, `fc34/probe2.log`

---

## Claim 8: "Any line starting [ that holds ]: (an escaped ] in the label too) or never closes its [ (a label that continues on the next line) counts."

**Location:** `scripts/dev-cycle.sh:291-292`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High (reader) / Medium-High (CM)
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the test `refdef()` returns. It does not establish CM's reading beyond spec reasoning.

`return substr(l, 1, 1) == "[" && (index(l, "]:") || !index(l, "]"))` (`:293`). "Never closes its [" is tested as "holds no `]` character". That test treats an escaped `\]` as a close. So `[a\]` is not refused, although in CM its `[` does not close and the label continues on the next line (`b]: /u 'title`). This is root R-B (P2 N3, N3b, N8b, all reading `drop` or `done`). The parenthetical "(a label that continues on the next line)" says such labels are caught, and for this shape the mechanism refutes it. The "holds ]:" half is accurate: fc33-R2 and sec-R2 (`[a\]b]: …`) are refused.

**Evidence:** `scripts/dev-cycle.sh:291-293`, `fc34/probe2.log`

---

## Claim 9: oddwhy reasons — "starts with < after any blanks …", "starts like a link reference definition (its label or title can span lines)", "starts with a byte-order mark"

**Location:** `scripts/dev-cycle.sh:320-328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each reason against the test that emits it. It does not establish that the refdef reason fires on R-A/R-B lines (it does not, Claims 7-8).

`html) echo "starts with < after any blanks …"` (`:322`) matches `/^[ \t]*</` (P2 brief-indented-lt is refused). `refdef) echo "starts like a link reference definition (its label or title can span lines)"` (`:324`) fits non-definitions too (N13 task item, N13b `[1, 2, 3`). `bom` fires only on line 1 (`:306`), and the skip names line 1, so "starts with" is accurate.

**Evidence:** `scripts/dev-cycle.sh:305-328`, `fc34/probe2.log`

---

## Claim 10: "A brief FENCE_AWK refuses (see its comment for every reason) is not read at all."

**Location:** `scripts/dev-cycle.sh:330-336`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the brief path returning on any `odd`, and the FENCE_AWK comment listing every `refuse()` reason (fence, html, comment, refdef, cr, bom) plus the open-fence case. It does not establish refusal of R-A/R-B.

`odd\ *) … echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read"; return ;;` (`:354`) returns before the status is used. The comment at `:265-273` names all six reasons and `fline`.

**Evidence:** `scripts/dev-cycle.sh:265-273`, `scripts/dev-cycle.sh:330-356`, `fc34/probe2.log`

---

## Claim 11: "Each of these makes the whole file a skip for every ID, naming the line and the reason: anything FENCE_AWK refuses (see its comment), a fence still open at the end, or a \"### Q-NNN \" heading inside a fence … No real questions file has any of them."

**Location:** `scripts/dev-cycle.sh:412-418`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the three skip forms and the real-file claim across 9 branches plus working copies. It does not establish CM fidelity for R-A/R-B.

`odd\ *) … echo "skip $a: line $n of $f $(oddwhy "$why"), so no entry in $f is read"`, `unbalanced\ *) … "the code fence opened at line … is never closed"`, `quoted\ *) … "is a question heading inside a code fence …"` (`:497-499`). In P1, all 18 tracked questions files on 9 branches and the 6 working copies read `ok`.

**Evidence:** `scripts/dev-cycle.sh:408-418`, `scripts/dev-cycle.sh:480-499`, `fc34/probe1.log`

---

## Claim 12: "An inline comment left open, and a link reference definition, refuse too; a < inside a code span mid-line (as the real files have) does not."

**Location:** `test/scripts/dev-cycle.bats:927-928`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the assertions in the block that follows (`:929-957`), and that they pass. It does not establish what the test inputs mean in CM (Claim 13).

The block asserts `keep Q-1` for the code-span `<`, and `opens an HTML comment` / `starts like a link reference definition` for the refusal cases. E1: 49/49 `ok`.

**Evidence:** `test/scripts/dev-cycle.bats:927-957`, `fc34/e1-bats.log`

---

## Claim 13: "Tests: escaped bracket and unclosed label."

**Location:** commit 0db12bd message; `test/scripts/dev-cycle.bats:941`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers what the test literal holds. It does not affect the code's behavior: P2 confirms a real escaped-bracket definition is refused.

`for shape in '[a\\]b]: /u' '[a' ; do … echo "$shape"` (`:941-942`). The single quotes keep both backslashes, so the line written is `[a\\]b]: /u`. In CM, `\\` is an escaped backslash, and the `]` after it is a real close, so this is not an escaped-bracket label: it is a non-definition that holds `]:`. The test still passes, and the escaped-bracket refusal works (P2 fc33-R2 / sec-R2, written with `printf`, which yields `[a\]b]:`). To test what the message says, the literal should be `'[a\]b]: /u'`.

**Evidence:** `test/scripts/dev-cycle.bats:941-946`, `fc34/probe2.log`

---

## Claim 14: 5630135 — "opencomment() tests the last <!-- on the line, so 'a <!-- x --> b <!--' refuses; refdef() looks past blockquote and list markers, so '- [x]: ...', '> [x]: ...' and '1. [x]: ...' refuse … Comments and help no longer say 'fences cannot be trusted' … the ANSWER_AWK comment points at FENCE_AWK's full list … 49/49; shellcheck and the hermeticity lint clean; no real ID refused."

**Location:** commit 5630135
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers each named example and the gates at e93312d. "Looks past … list markers" is verified for the three single-marker examples named; nested markers are Claim 7.

In P2, list-refdef-lazy, bq-refdef-lazy, sec-R3, sec-R4, N18 (`- > [x]:`) and N19 (`>> [x]:`) are all refused. `grep -n 'cannot be trusted'` finds only `:410` ("the file cannot be trusted", the general odd/unbalanced/quoted gloss), not "fences cannot be trusted". `:414` reads "anything FENCE_AWK refuses (see its comment)". E1 is green, and P1 shows no real file refused.

**Evidence:** `scripts/dev-cycle.sh:284-294`, `scripts/dev-cycle.sh:410-418`, `fc34/probe2.log`, `fc34/e1.log`, `fc34/probe1.log`

---

## Claim 15a: 0db12bd — "refdef(): after any blockquote or list marker, a line starting [ that holds ]: (so an escaped ] in the label counts) or never closes its [ (a label continued on the next line) refuses"

**Location:** commit 0db12bd
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High (reader) / Medium-High (CM)
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the mechanism as stated. It does not establish CM's reading beyond spec reasoning.

The commit says "after any … list marker", but only one is stripped (R-A, Claim 7). It says a label continued on the next line refuses, but a first line holding `\]` does not (R-B, Claim 8). The commit message is immutable, so the fix belongs in the code or in the texts that ship (Claims 4b, 7, 8, 19a, 22a).

**Evidence:** `scripts/dev-cycle.sh:288-294`, `fc34/probe2.log`

---

## Claim 15b: 0db12bd — "No real questions file has such a line. The html reason and the help say < counts after blanks and a BOM only on line 1. Tests … 49/49; shellcheck and the hermeticity lint clean; no real ID refused."

**Location:** commit 0db12bd
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the wording, gate and real-file parts. The test-intent part is Claim 13.

The help has "(after blanks)" and "on line 1" (`:57`, `:59`), and the reason has "after any blanks" (`:322`). E1 is green. P1: 18/18 real files on 9 branches and 6/6 working copies read `ok`. Every real line holding `]:` starts with something other than `[`: `**Answered 2026-09-23: [2], …`, `Spike, per Q-081 [2]: …`, `Implement Q-083 [1]: …`, and table rows `| [Q-088](#…) | …`.

**Evidence:** `scripts/dev-cycle.sh:54-61`, `scripts/dev-cycle.sh:322`, `fc34/probe1.log`, `fc34/e1.log`

---

## Claim 16: e93312d — "processing instructions, CDATA and declarations opened mid-line fall under decision log 69's inline class; a line starting with any of them is already refused."

**Location:** commit e93312d
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers line-start refusal by `rawhtml`, and that the class is now named in both texts. It does not test mid-line PI/CDATA (accepted class, out of scope).

`rawhtml(l)` matches `/^[ \t]*</` (`:283`), so `<?`, `<![CDATA[` and `<!DOCTYPE` at line start (after blanks) are refused. The same names appear at `scripts/dev-cycle.sh:275-276` and in row 69 (B).

**Evidence:** `scripts/dev-cycle.sh:274-283`, `docs/decisions/log.md:92` (B)

---

## Claim 17: gates — `bats test/scripts/dev-cycle.bats` (49) passes and `python3 scripts/hermeticity-lint --root .` stays clean

**Location:** brief scope; `test/scripts/dev-cycle.bats`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers these three commands at e93312d (HEAD 9dfbf82, identical in scripts/ and test/). It does not establish coverage of R-A/R-B, which no test exercises.

E1 at 18:55:07Z, cwd `/workspace/.claude/wt-digest`: bats rc 0 (49 `ok`, 0 `not ok`); the lint rc 0 (`hermeticity-lint: 126 test file(s) checked, no unstubbed network spawns.`); shellcheck rc 0.

**Evidence:** `fc34/e1.log`, `fc34/e1-bats.log`, `fc34/e1-lint.log`, `fc34/e1-shellcheck.log`

---

## Claim 18: the widened `refdef` refuses no real file

**Location:** brief claim 1; `scripts/dev-cycle.sh:288-294`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the 18 tracked questions files on 9 branches and the 6 working copies. No brief is tracked on any branch, so the brief side is checked only with synthetic briefs. Refusals on non-questions `.md` files are context.

P1: none of these files is refused. On main, the change from fd22d29 to e93312d newly refuses 5 tracked non-questions files. The lines it hits are a code-span `<!--` after a closed comment (`docs/reviews/q065-code-fact-check-report.md:176`) and list items such as `- [2]: add a **tripwire** …` and `- [ ] Otherwise, … one \`[NNN]: <Goal line text>\` row …` (`workflows/codebase-onboarding.md:356`, `workflows/spike.md:235`). These are the design's cost, not findings. One thing to watch: a brief whose acceptance criteria are task-list items holding `]:` would be refused.

**Evidence:** `fc34/probe1.log`

---

## Claim 19a: row 69 — "The reader refuses … on … a link reference definition (also behind `>` or a list marker)"

**Location:** `docs/decisions/log.md:92` (B)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High (reader) / Medium-High (CM)
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers this item of the refusal list against A's code at e93312d (merged into B by ba93f23). It does not establish CM's reading beyond spec reasoning.

Definitions behind two list markers (R-A) and labels whose first line holds only `\]` (R-B) are read, not refused (P2 N1, N2, N2b, N3, N3b, N8, N8b). This is a block construct, not the accepted inline class that the same row names.

**Evidence:** `docs/decisions/log.md:92` (B), `scripts/dev-cycle.sh:288-294`, `fc34/probe2.log`

---

## Claim 19b: row 69 — the rest of the refusal list ("any fence-like line that is not a plain column-0 fence, a line starting with `<` (except a complete one-line comment), an unclosed inline comment, … a stray CR or a BOM, a fence open at the end, or a question heading inside a fence")

**Location:** `docs/decisions/log.md:92` (B)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each remaining item against the code. It does not establish the refdef item (19a).

The fence item and the unclosed inline comment now match the code (Claims 4a, 6). The wording residue carried from pass 33 is not addressed by 12f4cd6:
- `<` counts after blanks (`/^[ \t]*</`, `scripts/dev-cycle.sh:283`).
- A BOM counts only on line 1 (`NR == 1 && …`, `:306`).
- "A question heading inside a fence" applies to the answer reader only (`infence && /^### Q-…/`, `:455`; the brief awk at `:348-352` has no such test).

**Evidence:** `docs/decisions/log.md:92` (B), `scripts/dev-cycle.sh:283`, `scripts/dev-cycle.sh:306`, `scripts/dev-cycle.sh:348-352`, `scripts/dev-cycle.sh:455`

---

## Claim 20: row 69 — "(a skip: a keep-or-drop ID stays off `Applied:` and blocks a new question, and a refused brief keeps its slot, until the line is fixed)"

**Location:** `docs/decisions/log.md:92` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers agreement with the skill's In flight and slot rules. It does not establish that an agent running the skill follows them.

The skill says "`skip` (the entry could not be read) goes in the record and the final message, and the ID stays off `Applied:`" (`skills/dev-cycle/SKILL.md:298-299`), and asks a new question only if "no ID on its `Asked:` line is still `open` or skipped" (`:300-302`). For briefs it says "a brief the check skips keeps its slot (recorded) until the cause is fixed" (`:86-87`).

**Evidence:** `docs/decisions/log.md:92` (B), `skills/dev-cycle/SKILL.md:84-87`, `skills/dev-cycle/SKILL.md:287-302`

---

## Claim 21: row 69 — "Text CommonMark would hide inside an inline construct spanning lines (an open tag attribute, link title, code span, emphasis, or a processing instruction, CDATA section or declaration opened mid-line) is still read as text."

**Location:** `docs/decisions/log.md:92` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers agreement with the code comment and the absence of inline logic in FENCE_AWK. It does not test each construct.

The row's wording is identical to the FENCE_AWK comment (`scripts/dev-cycle.sh:274-277`), and no inline logic exists (Claim 5).

**Evidence:** `docs/decisions/log.md:92` (B), `scripts/dev-cycle.sh:274-319`

---

## Claim 22a: brief clause — "outside fences a brief has no … link reference definition …: `--check-brief` prints a skip for a brief with any of these"

**Location:** `skills/dev-cycle/SKILL.md:335-339`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High (reader) / Medium-High (CM)
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the "prints a skip" promise for reference definitions. It does not establish CM's reading beyond spec reasoning.

`--check-brief` prints `ok docs/working/briefs/2026-01-01-x.md done` for a brief holding `- - [x]: /u 'title` (R-A, P2 N8) and for one holding `[a\]` / `b]: /u 'title` (R-B, N8b). CM reads `Status: open` for both, so no skip is printed.

**Evidence:** `skills/dev-cycle/SKILL.md:335-339`, `scripts/dev-cycle.sh:288-294`, `fc34/probe2.log`

---

## Claim 22b: brief clause — the rest ("no line starting with `<` …, no `<!--` left open on its line, … no stray carriage return and no byte-order mark: `--check-brief` prints a skip …, and the brief keeps its slot until it is fixed")

**Location:** `skills/dev-cycle/SKILL.md:335-339`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers each listed item and the slot clause. It does not establish the refdef item (22a).

P2 confirms every listed item prints a skip: brief-linestart-placeholder, sec-B1, brief-codespan-comment, brief-bom. The slot clause matches `SKILL.md:86-87`. The clause is narrower than the code in two ways, wording only:
- The code also refuses a `<` after leading blanks (P2 brief-indented-lt), so a writer who indents `<name>` gets a skip the clause does not warn of.
- The code refuses lines that merely start like a definition (`[1, 2, 3`, or `- [ ] … [n]: …`, P2 N13/N13b).

**Evidence:** `skills/dev-cycle/SKILL.md:84-87`, `skills/dev-cycle/SKILL.md:335-339`, `scripts/dev-cycle.sh:283`, `scripts/dev-cycle.sh:288-294`, `fc34/probe2.log`

---

## Claim 23: "brief holding a slot by path (marking any for which `--check-brief` printed a skip, with its reason)"

**Location:** `skills/dev-cycle/SKILL.md:378`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers whether a skip line carries a reason to copy. It does not establish what the agent writes.

Every brief skip in P2 has the form `skip <path>: <reason>` (e.g. `… line 1 starts with a byte-order mark, so the brief is not read`). "Printed a skip" matches the script's own wording (`:36`).

**Evidence:** `skills/dev-cycle/SKILL.md:373-380`, `scripts/dev-cycle.sh:339-356`, `fc34/probe2.log`

---

## Claim 24: 12f4cd6 — "Decision log 69: a skip keeps a keep-or-drop ID off Applied: (no new question) and keeps a refused brief's slot until the line is fixed; 'not a plain column-0 fence'; reference definitions behind > or a list marker. Brief format: the rules apply outside fences and include an open <!-- and a BOM; the final message says 'printed a skip'"

**Location:** commit 12f4cd6
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that each named edit is in the diff 5085e64..823f494. Whether the edited texts are true is Claims 19a–23.

Each edit is present in `git diff 5085e64..823f494 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` (paraphrased — no quote available because the evidence is a diff walk, and the diff's lines are quoted under Claims 19a–23).

**Evidence:** `docs/decisions/log.md:92` (B), `skills/dev-cycle/SKILL.md:335-339`, `skills/dev-cycle/SKILL.md:378`

---

## Claim 25: 823f494 — "log 69 names the inline HTML constructs in the accepted class"

**Location:** commit 823f494
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the row's text. Whether the class is right is out of scope (decision 69).

Row 69 now reads "…code span, emphasis, or a processing instruction, CDATA section or declaration opened mid-line…" (`docs/decisions/log.md:92`).

**Evidence:** `docs/decisions/log.md:92` (B)

---

## Claim 26: merge ba93f23 carries both sides unchanged

**Location:** merge ba93f23 (B)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the four in-scope files. It does not cover other files the merge brings in.

The parents are `823f494 9dfbf82`. `git diff --stat e93312d ba93f23 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` and `git diff --stat 823f494 ba93f23 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` both printed nothing and returned 0 (paraphrased — no quote available because the output is empty; run inline at about 18:57Z in `/workspace/.claude/wt-devcycle`, which `git status --short` showed clean).

**Evidence:** `ba93f23`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4b** (`scripts/dev-cycle.sh:268-271`): "a link reference definition" is refused, but R-A (nested list markers) and R-B (escaped-`]` first line of a multi-line label) read `drop`/`done`. **Behavioral.**
- **Claim 7** (`scripts/dev-cycle.sh:288`): "list markers" plural, but one is stripped. **Behavioral** (R-A).
- **Claim 8** (`scripts/dev-cycle.sh:291-292`): "never closes its [ (a label that continues on the next line)" is tested as "no `]` character", which misses `[a\]`. **Behavioral** (R-B).
- **Claim 15a** (commit 0db12bd): the same mechanism, described as complete ("any … list marker"). Immutable; fixed through Claims 4b/7/8/19a/22a. **Behavioral.**
- **Claim 19a** (`docs/decisions/log.md:92`, B): row 69's refdef item ("also behind `>` or a list marker") has the R-A/R-B gaps. **Behavioral.**
- **Claim 22a** (`skills/dev-cycle/SKILL.md:335-339`): "`--check-brief` prints a skip" for a reference definition, but R-A/R-B briefs read `done`. **Behavioral.**

### Stale
- None.

### Mostly Accurate
- **Claim 13** (commit 0db12bd; `test/scripts/dev-cycle.bats:941`): the "escaped bracket" test literal `'[a\\]b]: /u'` is an escaped backslash plus a real `]`. Use `'[a\]b]: /u'`. **Wording/test intent.**
- **Claim 19b** (`docs/decisions/log.md:92`, B): `<` counts after blanks, a BOM only on line 1, and a question heading inside a fence only for the answer reader. **Wording** (residue carried from pass 33).
- **Claim 22b** (`skills/dev-cycle/SKILL.md:335-339`): the code also refuses an indented `<` and lines that merely start like a definition. **Wording.**

### Unverifiable
- None. CM readings rest on spec reasoning (Medium-High), because no CommonMark implementation is installed in the sandbox.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass34.md`. Its first line is `Commit: e93312d (A) / 823f494 (B)`, and it carries the Replication field. It follows the code-fact-check structure: header, the seven per-claim fields plus Legibility-target, Claims Requiring Attention, and this note.

How it serves the user goal (merge after a clean k=1 pass):
- **Pass 33's three roots are fixed.** Every pass-33 probe now refuses. `opencomment()` is correct and complete. The gates are green (bats 49/49, lint and shellcheck rc 0), no real file is refused, and the merge carries both sides unchanged.
- **Not clean: one Low behavioral root pair in the widened `refdef()`, outside log 69's accepted class.**
  - R-A: only one list marker is stripped.
  - R-B: a first label line holding only `\]` passes the "never closes" test.
  - Both read `drop` on a questions file and `done` on a brief where CM reads otherwise. No real file has either shape.
  - A likely one-place fix: strip list and blockquote markers in a loop, and treat `[` as unclosed unless an unescaped `]` follows. Add N1 and N3 to the bats block at `:941-952`.
  - Six texts restate the gap. They become true once the code matches.
- **Wording only:** the test literal (Claim 13), and row 69's and the brief clause's narrower descriptions (Claims 19b, 22b).
