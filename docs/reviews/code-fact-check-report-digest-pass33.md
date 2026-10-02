Commit: fd22d29 (A) / 5085e64 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at fd22d29; HEAD a257403 adds only the pass-32 review docs, and `git diff --stat fd22d29 HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at 5085e64; HEAD is merge 6ea4f68).
**Scope:** Partial: the pass-32 fix round only. A: `git diff 4b7ec02..fd22d29 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of fd22d29. B: `git diff f54ca74..5085e64 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` plus the message of 5085e64, and merge 6ea4f68. One adjacent comment (`scripts/dev-cycle.sh:397-407`) is included because this round edited it. Everything else is context only (rubric section "Pass 32").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 23
**Summary:** 12 verified, 5 mostly accurate, 0 stale, 6 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 patterns) first. No claim here matches a logged pattern. No Incorrect verdict is a fabricated symbol, API or flag, so nothing qualifies for the log, and the brief allows no other write.

**The six Incorrect verdicts share three roots.** Two are behavioral (R1, R2) and one is wording (R3):
- **R1: unclosed inline comment.** `opencomment()` looks only at the line's *first* `<!--`.
- **R2: link reference definition.** `refdef()` matches only `[label]:` at line start with no `]` in the label.
- **R3: row 69's "(a skip, so the question is asked again)".**

Claims 1, 3b, 8a and 9b restate R1/R2 in different places. One code fix, or one narrowing of the wording, closes all four.

**Accepted-limit boundary.** Decision log 69 (and the rubric's Pass 32 user decision) makes inline constructs that span lines out of scope. The brief's acceptance bar names the class as "an open tag attribute, link title, code span or emphasis". It also says "an inline comment that does close later is also refused now". R1 is exactly such a comment that is *not* refused, so I treat it as in scope. A link reference definition is a block construct, not an inline one, and the code comment, help and row 69 all list it as refused, so R2's misses are in scope too. Note, though, that the rubric's Pass 32 A1 row listed "reference definition" inside the accepted class. If the orchestrator reads the acceptance that way, R2 becomes wording only: the texts over-promise. Under either reading, the texts as written are Incorrect.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc33/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Every per-case repo was checked again after its `cd`. Every process ran under `timeout` and exited. Inside the worktrees I ran only read-only commands (`git diff/show/log/rev-parse/status/ls-tree`, `bats`, `shellcheck`, the hermeticity lint). bats ran with `TMPDIR` set to the probe's temp dir. `git status --short` in wt-digest was byte-identical before and after (`fc33/e1-status-before.log`, `fc33/e1-status-after.log`). Nothing outside my temp dirs changed. The only file written in a worktree is this report.

Scratch logs (not committed) are in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc33/`, called `fc33/` below. The system awk is mawk. No CommonMark implementation is installed (no markdown-it, commonmark, mistune, cmark or pandoc, and there is no network). Every "CM" expectation is therefore my reading of the CommonMark 0.31 spec:
- §4.7: a link reference definition cannot interrupt a paragraph. Its label ends at the first unescaped `]`, may contain backslash-escaped brackets, and may span lines. Its title may span lines but not a blank line.
- §6.6: an inline HTML comment is `<!--` … `-->` and may contain line endings within its paragraph.
- §5: inside list items and block quotes, paragraph continuation lines may be lazy.

Verdicts that depend on those readings carry Medium confidence. The code's behavior on each input was executed and is certain.

Executed runs (UTC, 2026-10-02). Each exited 0:
- **E1** 18:38:04Z. cwd `/workspace/.claude/wt-digest` (HEAD a257403; scripts and tests identical to fd22d29). Commands: `TMPDIR=<probe dir> timeout 550 bats test/scripts/dev-cycle.bats` → `fc33/e1-bats.log` (rc 0, 49 `ok`, no `not ok`); `timeout 60 python3 scripts/hermeticity-lint --root .` → `fc33/e1-lint.log` (rc 0); `timeout 60 shellcheck scripts/dev-cycle.sh` → `fc33/e1-shellcheck.log` (rc 0). Driver: `fc33/e1.sh`, log `fc33/e1.log`.
- **P1** 18:35:11Z, cwd `fc33/`: `timeout 300 bash probe1.sh` → `fc33/probe1.log`. It extracts `FENCE_AWK` from fd22d29 and runs it over every real questions file and brief on all 9 local branches, plus the gitignored working copies in `/workspace` and both worktrees. It also runs it over every tracked `.md` on main, as context for what the new refusals catch. The first attempt (18:35:05Z) failed on my own extraction range (it cut `FENCE_AWK` at a lone `}`). I fixed the range and reran; the rerun is the log.
- **P2** 18:36:10Z, cwd `fc33/`: `timeout 300 bash probe2.sh` → `fc33/probe2.log`. It runs 18 `--check-answer` shapes against fd22d29 and 4b7ec02, 4 `--check-brief` shapes against fd22d29, and `--help`. The first attempt (18:36:05Z) stopped at case 2 on a dir-name collision in my harness. I fixed it and reran.
- **P3** 18:37:05Z, cwd `fc33/`: `timeout 200 bash probe3.sh` → `fc33/probe3.log`, with 6 more shapes (container and multi-line-label refdefs, a third inline comment, a list-item comment).
- **P4** 18:38:58Z, cwd `fc33/`: `timeout 200 bash probe4.sh` → `fc33/probe4.log`, covering a `[x]:` line under a paragraph and the merge diffs. Its last section used `awk -e`, which mawk does not support, and was redone in P5.
- **P5** 18:39:09Z, cwd `fc33/`: `timeout 200 bash probe5.sh` → `fc33/probe5.log`. It counts lines with an odd number of backticks in every real questions file, outside fences, and any answer-like line in the same paragraph after one. A grep at 18:40Z over the same files counted 0 lines with two comments, an escaped-bracket label or a container-prefixed `[x]:` in all 18 files (output read inline).

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the person reading `--help`, a skip line, the decision log or the final message.

---

## Claim 1: "a code fence never closed or not in plain column-0 form, a line starting with < or opening an unclosed comment, a link reference definition, a stray carriage return or byte-order mark, a question heading inside a fence"

**Location:** `scripts/dev-cycle.sh:55-60`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers which inputs `--check-answer` actually skips, compared with this help list. It does not establish CM's reading beyond the spec sections cited in the header.

The most severe part is the refusal list's "opening an unclosed comment" and "a link reference definition" (roots R1 and R2, Claims 3b and 3c). A line such as `Note <!-- a --> x <!-- b` opens a comment it never closes, yet it reads `drop Q-1` with no skip (P2 `second-inline-comment-open`). The refdef `[a\]b]: /u 'title` also reads `drop`, where CM hides the answer line in its title (P2 `refdef-escaped-bracket`). Lesser residue, wording only: the code refuses a `<` after leading spaces or tabs (`/^[ \t]*</`, `scripts/dev-cycle.sh:281`), and a BOM only on line 1 (`NR == 1 && …`, `:295`). The help says neither. Pass 32 flagged both, and the fix added them to the code comment but not here.

**Evidence:** `scripts/dev-cycle.sh:55-60`, `scripts/dev-cycle.sh:281-283`, `scripts/dev-cycle.sh:294-305`, `fc33/probe2.log`

---

## Claim 2: "-h|--help) sed -n '2,70p' \"$0\""

**Location:** `scripts/dev-cycle.sh:134`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the help range covering exactly the header comment (lines 2-70). It does not establish the help's content (Claim 1).

Line 70 is the header's last comment line (`# default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data.`), and line 71 is empty, then `set -euo pipefail` (`fc33/probe2.log`, `cat -A` of lines 70-72). `--help` ends on that Exit sentence.

**Evidence:** `scripts/dev-cycle.sh:68-72`, `scripts/dev-cycle.sh:134`, `fc33/probe2.log`

---

## Claim 3a: "outside a fence, a line that starts (after spaces or tabs) with < (an HTML block can hold a fence line; only a complete one-line <!-- comment --> is read)"

**Location:** `scripts/dev-cycle.sh:264-266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the `rawhtml()` rule and its order in `fence()`. It does not establish the HTML-block families, which pass 32 already ran (context).

`function rawhtml(l) { return l ~ /^[ \t]*</ && !(l ~ /^[ \t]*<!--/ && index(l, "-->")) }` (`scripts/dev-cycle.sh:281`). It runs only after the in-fence branch returns (`:296-300`), so it applies outside fences only. A brief line `<name>` skips with "starts with <" (P2 `brief-linestart-placeholder`). A mid-line `<name>` reads `open` (P2 `brief-midline-placeholder`). bats asserts the `<details>` and multi-line `<!--` cases (E1).

**Evidence:** `scripts/dev-cycle.sh:281`, `scripts/dev-cycle.sh:293-307`, `test/scripts/dev-cycle.bats:903-948`, `fc33/probe2.log`, `fc33/e1-bats.log`

---

## Claim 3b: "one that opens an HTML comment it does not close"

**Location:** `scripts/dev-cycle.sh:266-267`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High (code behavior) / Medium (CM reading)
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers which lines `opencomment()` refuses and whether a line that opens an unclosed comment after a closed one is refused. It does not establish CM's reading beyond spec §6.6. It also does not settle whether the orchestrator treats this miss as part of the accepted inline class (see header).

The code checks only the first `<!--`:

```awk
# scripts/dev-cycle.sh:282
function opencomment(l,   i) { i = index(l, "<!--"); return i && !index(substr(l, i + 4), "-->") }
```

When an earlier comment on the line closes, the `-->` after the first `<!--` satisfies the test, and a later unclosed `<!--` is never seen. The input `Note <!-- a --> x <!-- b` / `Q-1: [2]` / `-->` / blank / `Q-1: [1]` reads **`drop Q-1`** at fd22d29 (P2 `second-inline-comment-open`), and so does a third-comment variant (P3 `third-comment-open`). In CM the paragraph's second comment runs `<!-- b⏎Q-1: [2]⏎-->`, so the only visible answer is `Q-1: [1]` (`keep`). The same text with only one comment is refused correctly (P2 `first-inline-comment-open`).

Shapes that are not this construct behave as the brief asks:
- A `[x]:` line inside a fence is read as fenced content (P2 `refdef-inside-fence`: `keep`).
- `<!--` inside a code span mid-line refuses (P2 `codespan-open-comment`, and a brief in P2). That over-refuses, which is the design's cost. P1 shows no real file is refused.

Severity: Low. The preconditions are a questions entry or brief with a line holding a closed comment and then an unclosed one, plus an answer or `Status:` line in the same paragraph before the closing `-->`. No real file has two comments on a line (18 files, 0 hits). The writer could also write the answer line directly. Fix, either way: test the *last* `<!--` on the line (or every one), or say "whose first `<!--` is not closed on the line".

**Evidence:** `scripts/dev-cycle.sh:282`, `scripts/dev-cycle.sh:304`, `fc33/probe2.log`, `fc33/probe3.log`, `fc33/probe1.log`

---

## Claim 3c: "a link reference definition"

**Location:** `scripts/dev-cycle.sh:267`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High (code behavior) / Medium (CM reading)
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers which refdef forms `refdef()` matches. It does not establish CM's lazy-continuation behavior for refdefs inside containers beyond my reading of §4.7/§5, and it does not settle the scope question in the header.

`function refdef(l) { return l ~ /^[ \t]*\[[^]]+\]:/ }` (`scripts/dev-cycle.sh:283`). Three CM refdef forms are not matched, and each read `drop` where CM's visible answer is `keep`:
- **Escaped bracket in the label:** `[a\]b]: /u 'title` / `Q-1: [2]` / `end'` (P2 `refdef-escaped-bracket`). `[^]]+` stops at the escaped `]`, so `:` does not follow.
- **Label spanning lines:** `[a` / `b]: /u 'title` / … (P3 `refdef-label-spans`). Neither line starts `[label]:`.
- **Inside a list item or block quote, with a lazy continuation:** `- [x]: /u 'title` / `Q-1: [2]` / `end'` and the `> ` form (P3 `list-refdef-lazy`, `bq-refdef-lazy`).

The plain form refuses (P2 `refdef-plain`, `refdef-3sp`). A `[x]` line without a colon reads normally (P2 `bracket-no-colon`, `bracket-space-colon`, `list-refdef-shape`).

Severity: Low. The preconditions match Claim 3b's, and no real questions file has any of these shapes (0 hits). Fix: either widen the match (labels with `\]`; a line ending in an open `[`; container prefixes) or narrow the texts to "a line starting `[label]:`".

**Evidence:** `scripts/dev-cycle.sh:283`, `scripts/dev-cycle.sh:305`, `fc33/probe2.log`, `fc33/probe3.log`

---

## Claim 3d: "a carriage return inside a line (CommonMark ends a line there), or a byte-order mark on line 1: fence() records the first one's line number in `odd` (and why in `oddwhy`), and the caller refuses the whole file. A fence still open at the end is recorded in `fline`"

**Location:** `scripts/dev-cycle.sh:268-272`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the CR/BOM split, the first-refusal-wins rule and both callers printing `odd` first. It does not establish the CR line-number counting (LF-based, an Info item in pass 32).

`if (index(l, "\r")) { refuse("cr"); return 1 }` and `if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }` (`:294-295`). `function refuse(why) { if (!odd) { odd = NR; oddwhy = why } }` (`:284`). Both callers strip a trailing CR first (`{ sub(/\r$/, "") }`, `:338`, `:443`) and print `odd` before `unbalanced` (`:341`, `:470`). A line-1 BOM skips with "starts with a byte-order mark". An inner CR skips with "holds a carriage return that does not end it". A trailing-CR-only file reads `keep` (P2 `bom-line1`, `inner-cr`, `trailing-cr-only`).

**Evidence:** `scripts/dev-cycle.sh:284`, `scripts/dev-cycle.sh:294-301`, `scripts/dev-cycle.sh:337-345`, `scripts/dev-cycle.sh:469-475`, `fc33/probe2.log`

---

## Claim 4: "Accepted limit (decision log 69): inline constructs that span lines (an open tag attribute, link title, code span or emphasis) are not modelled, so text CommonMark would hide inside them is read as text. Whoever can write such a shape can write the answer or Status line itself; no real file has one."

**Location:** `scripts/dev-cycle.sh:273-276`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers three things: nothing in `FENCE_AWK` models those four constructs, row 69 exists where this comment ships, and real questions files have no odd-backtick line followed by an answer-like line in the same paragraph. It does not establish the absence of spanning tag attributes, link titles or emphasis in real files beyond those refusals and that heuristic, and "whoever can write…" is rationale, not checked.

`FENCE_AWK` (`:279-307`, read whole) has no code-span, emphasis, attribute or inline-link logic. P5: every real questions file on all 9 branches has 1–12 odd-backtick lines and 0 answer-like lines after one in the same paragraph. Row 69 is not on A's branch alone (`git show fd22d29:docs/decisions/log.md | grep -c '^| 69 '` → 0). It is on B at 5085e64 and in merge 6ea4f68, so the reference resolves once merged. (Paraphrased — no quote available because the evidence is counts from a grep and a probe, shown in `fc33/probe5.log` and read inline.)

**Evidence:** `scripts/dev-cycle.sh:273-307`, `fc33/probe5.log`, `docs/decisions/log.md:92` (B)

---

## Claim 5a: "html) echo \"starts with < (a possible raw HTML block; only a complete one-line <!-- comment --> is read)\""

**Location:** `scripts/dev-cycle.sh:311`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the reason text against `rawhtml()`. It does not establish the other reasons.

The rule is the right one, and "possible" fixes pass 32's 5a. But the trigger is `/^[ \t]*</` (`:281`), so a line with leading spaces or tabs is reported as one that "starts with <". The precise form would be "starts (after spaces or tabs) with <", as the code comment at `:265` now says. **Wording.**

**Evidence:** `scripts/dev-cycle.sh:265`, `scripts/dev-cycle.sh:281`, `scripts/dev-cycle.sh:311`, `fc33/probe2.log`

---

## Claim 5b: "comment) echo \"opens an HTML comment that does not close on the same line\""

**Location:** `scripts/dev-cycle.sh:312`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the sentence being literally true of every line that triggers it: the first `<!--` has no later `-->` on that line. It does not establish that every such line is refused (Claim 3b), or that CM reads a code-span `<!--` as a comment (it does not; that over-refusal is the design's cost).

Triggered only by `opencomment()` (`:282`, `:304`). P2's three triggering inputs (`codespan-open-comment`, `first-inline-comment-open`, `answer-line-open-comment`) and P3's `comment-closes-next-line` each print this reason on the right line.

**Evidence:** `scripts/dev-cycle.sh:282`, `scripts/dev-cycle.sh:304`, `scripts/dev-cycle.sh:312`, `fc33/probe2.log`, `fc33/probe3.log`

---

## Claim 5c: "refdef) echo \"is a link reference definition (its title can span lines)\""

**Location:** `scripts/dev-cycle.sh:313`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers what the reason asserts about the line that triggers it. It does not establish which refdefs escape it (Claim 3c).

The trigger is any line matching `^[ \t]*\[[^]]+\]:` (`:283`), with no paragraph context. A `[x]:` line under a paragraph line is a continuation in CM (a refdef cannot interrupt a paragraph), yet it skips as "is a link reference definition" (P4). GFM footnote syntax `[^1]: …` gets the same reason (P2 `footnote-def`). Refusing them is the design's cost. The sentence, though, states as fact what is only possible. Precise form: "starts like a link reference definition (`[label]:`)", parallel to 5a's "possible". **Wording.**

**Evidence:** `scripts/dev-cycle.sh:283`, `scripts/dev-cycle.sh:313`, `fc33/probe4.log`, `fc33/probe2.log`

---

## Claim 5d: "cr) echo \"holds a carriage return that does not end it\"" and "bom) echo \"starts with a byte-order mark\""

**Location:** `scripts/dev-cycle.sh:314-315`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the two reasons against their triggers. It does not establish line numbering for CR-split lines.

`cr` fires only on a CR left after the trailing-CR strip, and `bom` only on line 1's first three bytes (`:294-295`). P2 shows both texts on the matching inputs, where 4b7ec02 printed the merged sentence. bats asserts the BOM text (`test/scripts/dev-cycle.bats:926`).

**Evidence:** `scripts/dev-cycle.sh:294-295`, `scripts/dev-cycle.sh:314-315`, `test/scripts/dev-cycle.bats:922-926`, `fc33/probe2.log`

---

## Claim 6: "Prints keep, drop, done, open, unrecognized, dup …, \"odd N WHY\", \"unbalanced N\" or \"quoted N\" (the file cannot be trusted; N is the line, WHY the oddwhy reason) … Each of these makes the whole file a skip for every ID, naming the line, …: an ambiguous fence-like line, a fence still open at the end, or a \"### Q-NNN \" heading inside a fence … No real questions file has any of them."

**Location:** `scripts/dev-cycle.sh:397-407`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the output list against ANSWER_AWK's `END` and `check_answer`'s parse, plus the real-file claim. It does not establish the rest of the comment (`:408-421`), which this round did not change.

The output list is now right. `END` prints `"odd " odd " " oddwhy` (`:470`), and `check_answer` reads it with `read -r _ n why` and renders `$(oddwhy "$why")` (`:486`). "No real questions file has any of them" holds: all 18 real files across 9 branches give `ok` (P1). But the "Each of these…" list still names only the three fence causes. It leaves out the `<`-start, unclosed-comment, refdef, CR and BOM refusals that now produce `odd` too. That is the remainder of pass 32's Stale Claim 7. Precise form: "an ambiguous fence-like line or any other `FENCE_AWK` refusal, …". **Wording.**

**Evidence:** `scripts/dev-cycle.sh:397-407`, `scripts/dev-cycle.sh:469-475`, `scripts/dev-cycle.sh:482-488`, `fc33/probe1.log`

---

## Claim 7: test title "lines starting with <, open comments, reference definitions, stray CRs and a BOM refuse the file; one-line comments and code spans are read" and comment "An inline comment left open, and a link reference definition, refuse too; a < inside a code span mid-line (as the real files have) does not."

**Location:** `test/scripts/dev-cycle.bats:903`, `test/scripts/dev-cycle.bats:927-928`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the test asserts each named case and that it passes. It does not establish that "code spans are read" holds for a code span holding `<!--` (it refuses: P2 `codespan-open-comment`). The title's "code spans" means the `<` case the test exercises.

The test builds `Answer as \`Q-0NN: <your answer>\`.` and asserts `keep Q-1`. It also asserts `line 2 … opens an HTML comment` for `Note <!--` and `line 2 … is a link reference definition` for `[x]: /u 'title` (`:930-941`). E1: 49/49 ok. The real `questions.md` on main has `` `Q-0NN: <your answer>` `` at line 5 (grep at 18:41Z, read inline).

**Evidence:** `test/scripts/dev-cycle.bats:903-948`, `fc33/e1-bats.log`

---

## Claim 8a: fd22d29 message: "Two cheap refusals for inline constructs that hide following lines: a line that opens an HTML comment it does not close, and a link reference definition (its title can span lines)."

**Location:** `fd22d29` (commit message)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the two refusals as described against the code. It does not cover the rest of the message (8b).

This is the same refutation as Claims 3b and 3c (roots R1, R2). A line that opens an unclosed comment after a closed one, and refdefs with an escaped `]`, a multi-line label or a container prefix, are not refused (P2, P3). The commit message is immutable. The fix belongs in the code or in the texts that ship (Claims 1, 3b, 3c, 9b).

**Evidence:** `scripts/dev-cycle.sh:282-283`, `fc33/probe2.log`, `fc33/probe3.log`

---

## Claim 8b: fd22d29 message: "Loop pass 32 (api Inconsistent F1, Minor F2, Info F3; fact-check Stale 7, MA 2, 4b, 5a)"; "a BOM has its own reason; the ANSWER_AWK output list includes WHY; help lists every refusal"; "Tests: open inline comment, reference definition, a < inside a code span mid-line still read. 49/49; shellcheck and the hermeticity lint clean; no real ID refused here or on main."; "as the user chose on 2026-10-02 (decision log 69)"

**Location:** `fd22d29` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers these sentences. "help lists every refusal" is verified as listing every `FENCE_AWK` refusal cause, not that each is complete (Claim 1). The user's choice is verified as recorded (rubric Pass 32 "User decision"), not observed.

The pass-32 API review's table has F1 Inconsistent, F2 Minor, F3 Informational and F4 Informational (`docs/reviews/api-consistency-review-2026-10-02-digest-pass32.md:132-135`). Pass 32's fact-check lists Stale 7 and MA 2, 4b, 5a. E1 gives bats 49 ok and shellcheck and lint rc 0. P1 gives every real questions file on all 9 branches `ok`. The rubric records "**User decision (2026-10-02, decision log 69):** inline constructs that span lines … are an accepted, documented limit".

**Evidence:** `docs/reviews/api-consistency-review-2026-10-02-digest-pass32.md:132-135`, `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:751-764`, `fc33/e1-bats.log`, `fc33/e1-lint.log`, `fc33/e1-shellcheck.log`, `fc33/probe1.log`

---

## Claim 9a: decision log row 69's form: five columns, date 2026-10-02, references "`scripts/dev-cycle.sh` FENCE_AWK comment; rubric … passes 30–32"

**Location:** `docs/decisions/log.md:92` (B, 5085e64)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the row's shape and that its references exist. It does not cover its content (9b–9d).

Splitting on `|` gives 7 fields for row 69, as for row 68 (5 columns between the outer pipes, read inline). The FENCE_AWK comment names "decision log 69" (`scripts/dev-cycle.sh:273`), and the rubric has sections "Pass 30", "Pass 31" and "Pass 32" (`code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:722`, `:738`, `:751`).

**Evidence:** `docs/decisions/log.md:91-92`, `scripts/dev-cycle.sh:273`, `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:722-764`

---

## Claim 9b: row 69: "The reader refuses … on any fence-like line not at column 0, a line starting with `<` (except a complete one-line comment), an unclosed inline comment, a link reference definition, a stray CR or a BOM, a fence open at the end, or a question heading inside a fence."

**Location:** `docs/decisions/log.md:92` (B)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the refusal list against `FENCE_AWK` and both callers. It does not establish CM readings beyond the header's spec sections.

The most severe parts are "an unclosed inline comment" and "a link reference definition". Both are refuted for the shapes in Claims 3b and 3c (R1, R2), which read `drop` with no refusal. Lesser residue, wording only:
- "any fence-like line not at column 0" leaves out column-0 fence-like lines that also refuse, such as a backtick fence whose info string holds a backtick (`opens()` returns 0 at `:289`, then `fenceish` refuses at `:302`).
- "a question heading inside a fence" applies only to the answer reader (`qline`, `:444`, `:472`). The brief reader has no such check (`:337-341`).

**Evidence:** `docs/decisions/log.md:92`, `scripts/dev-cycle.sh:282-305`, `scripts/dev-cycle.sh:337-341`, `scripts/dev-cycle.sh:444`, `fc33/probe2.log`, `fc33/probe3.log`

---

## Claim 9c: row 69: "(a skip, so the question is asked again)"

**Location:** `docs/decisions/log.md:92` (B)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers what the skill does with a `--check-answer` skip. It does not cover brief skips, where a refused brief keeps its slot (context).

The skill says a skip is recorded and retried, not re-asked: "A `skip` (the entry could not be read) goes in the record and the final message, and the ID stays off `Applied:`, so the answer is read once the cause is fixed" (`skills/dev-cycle/SKILL.md:297-298`). Step 3 files a new keep-or-drop question only when "no ID on its `Asked:` line is still `open` or skipped" (`:300-302`), so a skip *holds back* the next asking. "Asked again" is what the script says of `unrecognized` (`scripts/dev-cycle.sh:421`). Precise form: "(a skip: the cycle reports it and reads the answer once the file is fixed)". **Wording**, but it misdescribes the refusal's consequence to a reader of the decision.

**Evidence:** `skills/dev-cycle/SKILL.md:285-302`, `scripts/dev-cycle.sh:419-421`, `docs/decisions/log.md:92`

---

## Claim 9d: row 69: "Text CommonMark would hide inside an inline construct spanning lines (an open tag attribute, link title, code span or emphasis) is still read as text." and rationale "Passes 26–32 … each found a new Markdown shape where a hand-rolled reader and CommonMark disagreed. The user chose (2026-10-02) to accept the inline class … no real file has one."

**Location:** `docs/decisions/log.md:92` (B)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers that the limit sentence matches the code (Claim 4) and that each of rubric passes 26–32 records a reader/CM shape disagreement. The user's choice is covered only as recorded in the rubric. "Disagreed" is my characterization of each pass's A rows.

Each rubric pass from 26 to 32 has an A row on a reader shape. 26: an unclosed fence hid headings. 27: longer, info-string and indented fences. 28 (C1): a list-item fence inverted. 29: indented and list-marker closers. 30: closer bound for indented openers. 31: HTML blocks, CR, BOM. 32: inline constructs (`code-review-rubric-…:667-764`). The pass 30 status also says "five passes in a row each found a new fence shape". The limit sentence matches Claim 4, and P5 found no such shape near an answer line in real files.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:667-764`, `fc33/probe5.log`

---

## Claim 10: "Any code in a brief sits in plain column-0 ``` fences, with no indented or list-item fences, no line starting with `<` (write placeholders as `NAME`, not `<name>`), and no link reference definitions or stray carriage returns (`--check-brief` refuses a brief with those, and a refused brief keeps its slot)."

**Location:** `skills/dev-cycle/SKILL.md:335-338` (B)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the format rule against what `--check-brief` refuses. It does not cover the slot rule (context, verified in pass 32).

Every named form refuses (P2: `brief-linestart-placeholder`, `brief-refdef`; pass-31/32 fence and CR cases), and a mid-line `<name>` reads `open` (P2). Two refusals are missing from the list:
- A line holding `<!--` with no later `-->`, even inside a code span mid-line. A brief that writes `` `<!--` `` refuses: "line 3 opens an HTML comment …" (P2 `brief-codespan-comment`).
- A BOM.

A cycle that follows the text can therefore still write a brief that refuses and then holds its slot. The likeliest way is a brief about comment handling that quotes `<!--`. Precise addition: "or `<!--` without a closing `-->` on the same line". 5085e64's "matching what --check-brief refuses" carries the same gap. **Wording** (agent-facing).

**Evidence:** `skills/dev-cycle/SKILL.md:335-338`, `scripts/dev-cycle.sh:282`, `scripts/dev-cycle.sh:304`, `fc33/probe2.log`

---

## Claim 11: "each brief holding a slot by path (marking any `--check-brief` refused, with its reason)"

**Location:** `skills/dev-cycle/SKILL.md:377` (B)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that `--check-brief` gives a reason the final message can carry. It does not establish that a cycle follows the instruction.

Every brief refusal prints `skip <path>: <reason>`, for example "line 2 is a link reference definition (its title can span lines), so the brief is not read" (P2). `check_brief` has no silent refusal path (`:328-345`, read whole through `:346`).

**Evidence:** `scripts/dev-cycle.sh:326-346`, `fc33/probe2.log`

---

## Claim 12: 5085e64 message: "Loop pass 32 (api Minor F2, Info F4; fact-check MA 12a): Brief format: no line starting with < (placeholders as NAME, not <name>), no link reference definitions, matching what --check-brief refuses; the final message marks refused briefs with their reason. Decision log 69: …"

**Location:** `5085e64` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the message against the diff and the pass-32 IDs. It does not re-verdict row 69's content (9b–9d).

The IDs match: API F2 Minor and F4 Informational (`api-consistency-review-…-pass32.md:133-135`), and fact-check MA 12a. The diff makes exactly the two SKILL edits and adds row 69. "Matching what --check-brief refuses" is incomplete in the same way as Claim 10 (unclosed `<!--`, BOM). **Wording.**

**Evidence:** `skills/dev-cycle/SKILL.md:335-338`, `skills/dev-cycle/SKILL.md:377`, `docs/decisions/log.md:92`, `docs/reviews/api-consistency-review-2026-10-02-digest-pass32.md:133-135`

---

## Claim 13: Merge 6ea4f68 carries A's code and B's skill and log unchanged

**Location:** `6ea4f68` (merge commit)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the four files under review. It does not establish other files in the merge.

Neither `git diff --stat fd22d29 6ea4f68 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` nor `git diff --stat 5085e64 6ea4f68 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` printed anything, and both returned 0 (P4, 18:38:58Z, run against `/workspace/.claude/wt-devcycle`). (Paraphrased — no quote available because the output is empty; see `fc33/probe4.log`.)

**Evidence:** `6ea4f68`, `fc33/probe4.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`scripts/dev-cycle.sh:55-60`): the help says a line "opening an unclosed comment" and "a link reference definition" are refused. Some of each are not (R1, R2). Residue: `<` after blanks, BOM on line 1 only. **Behavioral** root, user-facing text.
- **Claim 3b** (`scripts/dev-cycle.sh:266-267`, code `:282`): `opencomment()` tests only the first `<!--`. `Note <!-- a --> x <!-- b` / `Q-1: [2]` / `-->` reads `drop` where CM shows only the later `[1]`. **Behavioral** (R1), Low severity, no real file.
- **Claim 3c** (`scripts/dev-cycle.sh:267`, code `:283`): refdefs with an escaped `]`, a multi-line label, or a list/blockquote prefix with a lazy title line are not refused and read `drop`. **Behavioral** (R2), Low, no real file. In scope unless the orchestrator counts refdefs in the accepted inline class (the rubric's Pass 32 A1 row lists them, row 69 does not).
- **Claim 8a** (fd22d29 message): the same two refusals described as complete. **Behavioral** (R1, R2). Immutable; fixed by the code or by Claims 1/3b/3c/9b.
- **Claim 9b** (`docs/decisions/log.md:92`): the refusal list has the same R1/R2 gaps. Residue: column-0 fence-like refusals are omitted, and "question heading inside a fence" applies to the answer reader only. **Behavioral** root.
- **Claim 9c** (`docs/decisions/log.md:92`): "(a skip, so the question is asked again)". A skip is reported and retried, and it blocks re-asking (`SKILL.md:297-302`). **Wording** (R3).

### Stale
- None.

### Mostly Accurate
- **Claim 5a** (`scripts/dev-cycle.sh:311`): "starts with <" also fires after leading spaces or tabs. **Wording.**
- **Claim 5c** (`scripts/dev-cycle.sh:313`): "is a link reference definition" fires on `[x]:` paragraph continuations and footnotes. "Starts like a link reference definition" would be exact. **Wording.**
- **Claim 6** (`scripts/dev-cycle.sh:397-407`): the output list is fixed, but "Each of these…" still names only the three fence causes. **Wording.**
- **Claim 10** (`skills/dev-cycle/SKILL.md:335-338`): the brief format omits an unclosed `<!--` (even in a code span) and a BOM, both of which `--check-brief` refuses. **Wording**, agent-facing.
- **Claim 12** (5085e64 message): "matching what --check-brief refuses" has the same gap as Claim 10. **Wording.**

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass33.md`. Its first line is `Commit: fd22d29 (A) / 5085e64 (B)`, and it carries the Replication field. It follows the code-fact-check structure: header, the seven per-claim fields plus Legibility-target, Claims Requiring Attention, and this note.

How it serves the user goal (merge after a clean k=1 pass):
- **Gates and real files are clean.** bats 49/49, shellcheck and lint rc 0. Every real questions file on all 9 branches and every working copy reads `ok`, none is refused, and no real brief exists. The help range is exact, and the merge carries both sides unchanged.
- **Not clean: two narrow behavioral gaps in the new refusals, plus wording.**
  - R1: only the first `<!--` on a line is tested.
  - R2: refdefs with an escaped `]`, a multi-line label or a container prefix are missed.
  - Each still gives a wrong `drop` on a crafted input that no real file has.
  - Both are outside the accepted class as decision log 69 and the brief word it. The brief explicitly expects a later-closing inline comment to be refused. If the orchestrator reads the rubric's Pass 32 A1 (which listed reference definitions) as part of the acceptance, R2 becomes wording only.
  - Either way, the help, the FENCE_AWK comment and row 69 overstate the refusals today.
  - Row 69 also misstates a skip's consequence (R3). Five Mostly-accurate items are wording only.
- **Cheapest closure.** Make `opencomment()` test the last `<!--` on the line. Then either widen `refdef()` or narrow the three texts to "a line starting `[label]:`". Fix row 69's parenthetical. Add "unclosed `<!--`" and BOM to the brief clause.
