Commit: 4b7ec02 (A) / f54ca74 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at 4b7ec02; HEAD b28ae48 adds only the pass-31 review docs, and `git diff --stat 4b7ec02 b28ae48 -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at f54ca74; HEAD is merge 2080f23).
**Scope:** Partial: the pass-31 fix round only. A: `git diff 6f24d91..4b7ec02 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of d0bf53f and 4b7ec02. B: `git diff e19f411..f54ca74 -- skills/dev-cycle/SKILL.md` plus the messages of 4e5cbbc and f54ca74, and merge 2080f23. One adjacent comment (`scripts/dev-cycle.sh:382-392`) is included because this round changed the output it describes. Everything else is context only (rubric section "Pass 31").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 19
**Summary:** 13 verified, 5 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 patterns) first. Two claims are tallies of the logged kind ("49/49" and "102 here, 99 on main"). I recounted both by execution (Claims 10a and 10b). No verdict is a fabricated symbol, API or flag, so nothing qualifies for the log, and the brief allows no other write.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc32/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Every repo made inside a temp dir got the same check after its `cd`. Every process ran under `timeout` and exited. None of mine is still running (the `ps` entries at the end were other sessions' `sec32/` and `perf32/` probes). Inside the worktrees I ran only read-only commands: `git diff`, `git show`, `git log`, `git rev-parse`, `git status`, `git ls-tree`, `bats`, `shellcheck` and the hermeticity lint. `git status --short` was empty in both worktrees before this report was written, and `/workspace` was on `main`.

Scratch logs (not committed) are in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc32/`, called `fc32/` below. The system awk is mawk 1.3.4 (20200120). No CommonMark implementation is installed (no markdown-it, commonmark, mistune, cmark or pandoc, and there is no network), so every "CM" expectation below is my reading of the CommonMark spec:
- §2.1, line endings (LF, CR, CRLF); §2.3, NUL replaced by U+FFFD
- §4.5, fenced code blocks (a closer is followed only by spaces or tabs; a fence may interrupt a paragraph)
- §4.6, HTML blocks: type 2 starts with `<!--` and ends on the first line containing `-->`, which can be the start line; only paragraph continuation text is lazy

Verdicts that depend on those expectations carry Medium confidence. The code's behavior on each input was executed and is certain.

Executed runs (UTC, 2026-10-02). Each exited 0:
- **E1** 18:12:29Z, cwd `/workspace/.claude/wt-digest` (HEAD b28ae48 = 4b7ec02 for scripts/tests): `timeout 500 bats test/scripts/dev-cycle.bats` → `fc32/e1-bats.log` (rc 0, 49 `ok`); `timeout 60 python3 scripts/hermeticity-lint --root .` → `fc32/e1-lint.log` (rc 0); `timeout 60 shellcheck scripts/dev-cycle.sh` → `fc32/e1-shellcheck.log` (rc 0).
- **E2** 18:13:10Z, cwd `fc32/`: `timeout 600 bash e2-real.sh > e2-real.log 2>&1`. For all 9 local branches it copies the branch's questions files into a fresh repo and runs `--check-answer` on every real ID with 4b7ec02 and with 6f24d91. It also lists every line of those files that starts with `<` (after spaces or tabs) or holds a CR.
- **E3** 18:15:19Z, cwd `fc32/`: `timeout 600 bash e3-probe.sh > e3-probe.log 2>&1`. It runs 47 synthetic cases, one repo each, with 4b7ec02 against 6f24d91: the pass-31 reruns, new families, and brief forms. stderr (only the sandbox's setlocale warning) goes to `fc32/tmp.nYjtMsUKVX/stderr.log`.
- **E4** 18:16:49Z, cwd `fc32/`: `timeout 120 bash e4-help-wording.sh > e4.log 2>&1`. It runs `--help` and four lines that start with `<` but start no CommonMark HTML block.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the person reading `--help`, a skip line or the final message.

---

## Claim 1: "\"skip <path>: <reason>\" otherwise, including a brief whose fences cannot be trusted (as for --check-answer, naming the line)."

**Location:** `scripts/dev-cycle.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers `--check-brief` printing a skip that names a line for each of the reader's refusals (odd line, never-closed fence). It does not establish which inputs count as untrusted (Claims 4a/4b).

`check_brief` maps the reader's result to a skip that names a line: `odd\ *) read -r _ n why <<<"$st"; echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read"` and `unbalanced\ *) echo "skip $a: the code fence opened at line ${st#unbalanced } is never closed, …"` (`scripts/dev-cycle.sh:328-329`, excerpt; enclosing `check_brief()` spans `:311-340` — read). In E3, BH1–BH3 printed `skip …: line 2 starts a raw HTML block …`, BR1 printed `line 4 holds a carriage return …`, and BB printed `line 1 …`. E1's test at `:903` asserts the never-closed form.

**Evidence:** `scripts/dev-cycle.sh:36-38`, `scripts/dev-cycle.sh:311-340`, `fc32/e3-probe.log`, `fc32/e1-bats.log`

---

## Claim 2: "a code fence never closed or not in plain column-0 form, a raw HTML block, a stray carriage return or byte-order mark"

**Location:** `scripts/dev-cycle.sh:55-58`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the help's list of `--check-answer` skip causes against the refusals in `fence()`. It does not establish the "in both files" skip (`:475`), which predates this round and is also unlisted.

Every listed cause is printed (E3). The HTML cause is narrower in the help than in the code. `rawhtml()` is `l ~ /^[ \t]*</ && !(l ~ /^[ \t]*<!--/ && index(l, "-->"))` (`scripts/dev-cycle.sh:274`), so any line outside a fence that starts with `<` after any spaces or tabs refuses, whether or not CommonMark starts an HTML block there. In E4, an autolink line `<https://example.com/x>`, a line `<3 thanks`, a `<span>…</span>` line continuing a paragraph (type 7 cannot interrupt one), and a 4-space `    <div>` all gave `skip Q-1: line N … starts a raw HTML block`. The BOM is refused only on line 1: `(NR == 1 && substr(l, 1, 3) == "\357\273\277")` (`:285`). A BOM on line 2 is read as text (E3 N20, `drop`, which is the CM reading). Tighten to "a line starting with < (other than a one-line <!-- comment -->), a carriage return inside a line or a byte-order mark on line 1". **Wording.** The over-refusal itself is the design's stated cost. No real file is refused (E2).

**Evidence:** `scripts/dev-cycle.sh:55-58`, `scripts/dev-cycle.sh:272-296`, `fc32/e4.log`, `fc32/e3-probe.log`, `fc32/e2-real.log`

---

## Claim 3: "-h|--help) sed -n '2,69p' \"$0\""

**Location:** `scripts/dev-cycle.sh:133`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the help range ending exactly at the last header comment line at 4b7ec02. It does not establish that later header edits keep it in step (there is no test for the range).

Line 69 is `# default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data.`, line 70 is blank and line 71 is `set -euo pipefail` (E4 prints `69:`–`71:`). `--help` printed 68 lines, from `Gather the mechanical signals …` to that last line, with rc 0.

**Evidence:** `scripts/dev-cycle.sh:66-71`, `scripts/dev-cycle.sh:133`, `fc32/e4.log`

---

## Claim 4a: "Code fences, read only in their plain form, so that every fence this reads is read the way CommonMark reads it … and so is anything this reader does not model … fence() records the first one's line number in `odd` (and why in `oddwhy`), and the caller refuses the whole file."

**Location:** `scripts/dev-cycle.sh:257-270`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the acceptance bar (CommonMark reading or a refusal) for every family I ran: the pass-31 HTML, CR and BOM shapes, one-line comments, link reference titles, setext headings, tabs, NUL, FF/VT, NBSP, BOM after line 1, blockquote and list-item HTML, and escaped `<`. It does not establish inputs outside those families, and the CM side rests on my reading of the spec (no implementation installed).

The refusals are in `fence()`: `if (index(l, "\r") || (NR == 1 && substr(l, 1, 3) == "\357\273\277")) { refuse("cr"); return 1 }`, then the in-fence branch, `if (opens(l)) …`, `if (fenceish(l)) { refuse("fence"); return 1 }` and `if (rawhtml(l)) { refuse("html"); return 1 }` (`scripts/dev-cycle.sh:284-295`; whole `FENCE_AWK` `:272-296` read). Both callers print `odd` before anything else (`:326`, `:455`).

E3 results at 4b7ec02:
- **Pass-31 reruns all refuse.** H1 (`<!--`/`-->`), H2 `<div>`, H3 `<details>`, H4 `<span>`, H5 `<?x`, H6 `<!X`, H7 CDATA, H1c (`<!-- a` closed by `-- -->`), C18 `<PRE>`, and a `</div>` start each give `skip … starts a raw HTML block`. 6f24d91 gave `keep` for H1–H7 and `</div>`, which is the pass-31 wrong reading. R1 (`` ``` ``<CR><CR>), R2 (`text<CR>` `` ``` ``), R3 (a CR inside fenced content) and a line-1 BOM give `skip … holds a carriage return …`. Briefs BH1–BH3, BR1 and a BOM brief skip, where 6f24d91 read `open` for BH1–BH3 and the BOM brief.
- **The comment exception gives the CM reading.** `<!-- note -->`, `<!-->`, `<!--->`, `<!---->`, `<!-- a --> trailing <!-- b`, a 3-space comment and a tab-indented comment, each followed by a fenced `Q-1: [2]` and a later `Q-1: [1]`, all read `keep`. That is CM's reading, because type 2 ends on the first line containing `-->` (the start line included, `<!-->` too), so the `` ``` `` that follows opens a fence. A brief with a one-line comment reads `open`. No line that starts `<!--` and contains `-->` can be continued by CommonMark, so the "one-line comment that CommonMark would continue" family is empty.
- **Other families read as CM.** These all read as CM: a link reference title spanning a fence (`keep`; a fence interrupts the paragraph), setext `===`/`---` under the answer or Status line (`keep`/`open`), a tab after an opener's info string and after a closer (`keep`), a tab-indented fence (refuses, `fence-like`), and NUL. mawk keeps NUL bytes, so `` ``` ``NUL is not a closer, matching CM's U+FFFD, and `keep` results; a column-0 NUL before `` ``` `` gives `drop`; the brief NUL closer gives `open`. FF/VT after a closer (`keep`, not closers in CM), `> <div>` and `- <div>` / `- <!--` before a column-0 fence (`keep`; HTML blocks take no lazy lines, so the container ends), NBSP before `<div>` (`keep`; not indentation), a BOM on line 2 (`drop`; text), `\<div>` (`drop`), `<div>` inside a fence (`keep`) and a CRLF file (`keep`, `open`) also match.

I found no input on which the reader gives a non-CommonMark keep/drop/done/open without refusing.

**Evidence:** `scripts/dev-cycle.sh:257-296`, `scripts/dev-cycle.sh:326`, `scripts/dev-cycle.sh:455`, `fc32/e3-probe.sh`, `fc32/e3-probe.log`

---

## Claim 4b: "a line outside a fence that starts with < (an HTML block can hold a fence line; only a complete one-line <!-- comment --> is read), a carriage return inside a line (CommonMark ends a line there), or a byte-order mark"

**Location:** `scripts/dev-cycle.sh:263-266`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the comment's description of the three new refusal triggers. It does not establish the acceptance bar (Claim 4a).

The mechanism is right, but two qualifiers are missing. First, "starts with <": the regex is `^[ \t]*<` (`scripts/dev-cycle.sh:274`), so leading spaces or tabs of any width still refuse (E4 `    <div>`). That is unlike the fence rule two lines up, which names indentation. Second, "a byte-order mark": only a BOM at the start of line 1 refuses (`NR == 1 && substr(l, 1, 3) == …`, `:285`). A BOM elsewhere is read as text (E3 N20), which is CM's reading. Tighten to "starts with < (after any spaces or tabs)" and "a byte-order mark at the start of the file". **Wording.**

**Evidence:** `scripts/dev-cycle.sh:263-266`, `scripts/dev-cycle.sh:274`, `scripts/dev-cycle.sh:285`, `fc32/e4.log`, `fc32/e3-probe.log`

---

## Claim 5a: "html) echo \"starts a raw HTML block (only a one-line <!-- comment --> is read)\""

**Location:** `scripts/dev-cycle.sh:299`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the skip text for `oddwhy html`. It does not establish whether the refusal is right (the design accepts over-refusal), only whether the text describes the line.

`refuse("html")` fires for every non-comment line starting with `<` (`:274`, `:293`). For lines that start a CommonMark HTML block (H1–H7, `<PRE>`, `</div>`), the text is exact. For an autolink `<https://…>`, `<3 thanks`, a type-7 `<span>` line continuing a paragraph, or a 4-space `    <div>` (an indented code line after a blank), CommonMark starts no HTML block. The skip line still says "starts a raw HTML block" (E4). A user who fixes the file by looking for HTML finds an autolink or an emoticon. "starts with < (read as a possible raw HTML block …)" would be exact. **Wording.** Confidence is Medium because the "no HTML block" side rests on spec §4.6 (type 7 needs a complete tag alone on the line and cannot interrupt a paragraph; an autolink is not an open tag).

**Evidence:** `scripts/dev-cycle.sh:274`, `scripts/dev-cycle.sh:293`, `scripts/dev-cycle.sh:297-303`, `fc32/e4.log`

---

## Claim 5b: "cr) echo \"holds a carriage return that does not end it, or a byte-order mark\"" and the default "is a fence-like line that is not a plain column-0 fence"; "`--check-brief` and `--check-answer` both use it"

**Location:** `scripts/dev-cycle.sh:297-303`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the two other `oddwhy` texts and that both callers print through `oddwhy`. It does not establish the html text (Claim 5a).

`refuse("cr")` fires only for a CR left after `{ sub(/\r$/, "") }` strips the trailing one (`:323`, `:428`), or for a line-1 BOM (`:285`), so "does not end it, or a byte-order mark" fits both. `refuse("fence")` is the only other cause (`:288`, `:292`), and it maps to the `*)` branch. Both callers use it: `echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read"` (`:328`) and `echo "skip $a: line $n of $f $(oddwhy "$why"), so no entry in $f is read"` (`:471`). E3 shows all three texts from both modes (R1/BR1, N9b, BH1).

**Evidence:** `scripts/dev-cycle.sh:285-295`, `scripts/dev-cycle.sh:297-303`, `scripts/dev-cycle.sh:323-329`, `scripts/dev-cycle.sh:428`, `scripts/dev-cycle.sh:471`, `fc32/e3-probe.log`

---

## Claim 6: "A brief whose fences cannot be trusted (FENCE_AWK refuses it) is not read at all."

**Location:** `scripts/dev-cycle.sh:306-307`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `odd` and `unbalanced` taking precedence over any Status line. It does not establish which inputs are refused (Claim 4a).

The program reads to EOF, and its END is `END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else if (st != "") print st }` (`scripts/dev-cycle.sh:326`), so a valid `Status: open` before a later odd line still gives a skip. E3 BH1 has `Status: open` at line 7 and HTML at line 2 and prints `skip …: line 2 …`. BR1 has the odd line after a fenced Status and prints `line 4`.

**Evidence:** `scripts/dev-cycle.sh:304-340`, `fc32/e3-probe.log`

---

## Claim 7: "Prints keep, drop, done, open, unrecognized, dup (the heading appears more than once), \"odd N\", \"unbalanced N\" or \"quoted N\" … Each of these makes the whole file a skip for every ID, naming the line, …: an ambiguous fence-like line, a fence still open at the end, or a \"### Q-NNN \" heading inside a fence"

**Location:** `scripts/dev-cycle.sh:382-392`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the ANSWER_AWK header comment's output list and list of refusal causes at 4b7ec02. It does not establish anything about the code, which is correct.

This round changed the output to `if (odd) print "odd " odd " " oddwhy` (`scripts/dev-cycle.sh:455`), so the program now prints `odd N <html|cr|fence>`, not `"odd N"`. `check_answer` depends on the third field (`read -r _ n why <<<"$r"`, `:471`). The list of what makes the file a skip still names only "an ambiguous fence-like line, a fence still open at the end, or a "### Q-NNN " heading inside a fence". It omits the new HTML-start, inner-CR and BOM refusals (`:285`, `:293`), which also go through `odd`. The comment was accurate at 6f24d91 (the same text at its `:369`), and d0bf53f did not update it. Tighten to `"odd N WHY"` and add "a line starting with <, a CR inside a line or a BOM" to the list. **Wording.**

**Evidence:** `scripts/dev-cycle.sh:382-392`, `scripts/dev-cycle.sh:455`, `scripts/dev-cycle.sh:471`, `6f24d91:scripts/dev-cycle.sh:369`

---

## Claim 8: "@test \"header status fields, a second answer line, a list-item fence refusing a brief, a section after an open fence\""

**Location:** `test/scripts/dev-cycle.bats:856`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the title against the test body. It does not establish coverage beyond the body's assertions.

The body has Q-22 `**Status:** ANSWERED (by user)` and Q-23 `(was **Status:** ANSWERED) · **Status:** OPEN` (header status fields), Q-20 `**Answer:** maybe later` then `**Answer:** [1]` (a second answer line), the brief `printf '# Brief\n- %s\n  Status: done\n  %s\nStatus: open\n'` asserted as `line 2 is a fence-like line` (a list-item fence refusing a brief), and Q-21's `## Archive` after an open fence (`test/scripts/dev-cycle.bats:856-882`, read whole). The pass-31 Stale title is gone.

**Evidence:** `test/scripts/dev-cycle.bats:856-882`

---

## Claim 9: "@test \"HTML blocks, stray carriage returns and a byte-order mark refuse the file; a one-line comment is read\""

**Location:** `test/scripts/dev-cycle.bats:903`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the title against the body, and that the test passes. It does not establish the untested families in Claim 4a (comment variants, NUL, tabs and the rest are probe-only).

The body reads the index markers `<!-- index:start -->`/`<!-- index:end -->` as `keep Q-1`, then asserts `starts a raw HTML block` for `<details>` and for a multi-line `<!--`, `holds a carriage return` for `x\r` `` ``` ``, the full CR/BOM text for a line-1 BOM, and a brief's `line 2 starts a raw HTML block` and never-closed skip (`test/scripts/dev-cycle.bats:903-933`, read whole). E1: `ok 49 HTML blocks, stray carriage returns and a byte-order mark refuse the file; a one-line comment is read`.

**Evidence:** `test/scripts/dev-cycle.bats:903-933`, `fc32/e1-bats.log`

---

## Claim 10a: d0bf53f message: "any line outside a fence that starts with < refuses the file, except a complete one-line <!-- comment --> (the real files' only such lines are their index markers); so does a CR left inside a line or a BOM on line 1. Skip lines say why … Tests: <details>, multi-line comment, lone CR, BOM, the index-marker comment still read, a brief's HTML and never-closed refusals. 49/49; shellcheck and the hermeticity lint clean" and "Loop pass 31 (api Inconsistent F1, F2, Minor F3, Info F4)"

**Location:** `d0bf53f` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the mechanism, the test list, the gate results and the cited findings. It does not establish the ID counts (Claim 10b).

The mechanism matches `:274`, `:285` and `:293` (quoted in Claims 2 and 4a). E2's listing of `<`/CR lines across all 9 branches' questions files shows only `<!-- index:start -->` and `<!-- index:end -->` lines, and no CR. The tests are those in Claim 9. E1: 49 `ok`, and shellcheck and the lint both rc 0. The api pass-31 review has `#### F1` and `#### F2` at `**Severity:** Inconsistent`, F3 Minor and F4 Informational (`docs/reviews/api-consistency-review-2026-10-02-digest-pass31.md:35-94`).

**Evidence:** `scripts/dev-cycle.sh:274-295`, `fc32/e1-bats.log`, `fc32/e1-lint.log`, `fc32/e1-shellcheck.log`, `fc32/e2-real.log`, `docs/reviews/api-consistency-review-2026-10-02-digest-pass31.md:35-106`

---

## Claim 10b: d0bf53f message: "all real IDs (102 here, 99 on main) read as before, none refused"

**Location:** `d0bf53f` (commit message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the real questions files on all 9 local branches, read by 4b7ec02 against 6f24d91. It does not establish entries written after those tips.

E2 found no skip on any branch, and 4b7ec02's output is byte-identical to 6f24d91's on every branch (`feat/dev-cycle: 102 ids, new skips=0, new vs old: identical`; `main: 99 ids …`; the other seven have 96–98). The conclusion holds. The "here" is imprecise: d0bf53f is a commit on `feat/dev-cycle-digest`, whose files hold 98 IDs (12 + 86 at 4b7ec02). The 102 is `feat/dev-cycle`'s count. Say "102 on feat/dev-cycle". **Wording.**

**Evidence:** `fc32/e2-real.sh`, `fc32/e2-real.log`, `4b7ec02:docs/working/questions.md`, `4b7ec02:docs/working/questions-archive.md`

---

## Claim 11: 4b7ec02 message: "docs(dev-cycle): pass-31 fact-check wording (brief refusal comment, a stale test title)" and "Loop pass 31 fact-check (Stale 18, MA 7; Incorrect 4 and 20a share the HTML/CR root fixed in d0bf53f)."

**Location:** `4b7ec02` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the diff's contents and the cited verdicts. It does not establish that every pass-31 fact-check item was addressed; Claims 1 and 9 there (MA) were handled in d0bf53f (Claims 2 and 5b here).

`git show 4b7ec02` changes only the check_brief comment (adding "A brief whose fences cannot be trusted (FENCE_AWK refuses it) is not read at all.") and the `:856` test title. In the pass-31 report, Claim 7 is `**Verdict:** Mostly accurate` (the check_brief comment), Claim 18 is `Stale` (that title), and Claims 4 and 20a are `Incorrect` with the HTML/CR root (`docs/reviews/code-fact-check-report-digest-pass31.md:127-131, 199-203, 387-391, 419-423`).

**Evidence:** `4b7ec02`, `docs/reviews/code-fact-check-report-digest-pass31.md:127-131`, `docs/reviews/code-fact-check-report-digest-pass31.md:199-203`, `docs/reviews/code-fact-check-report-digest-pass31.md:387-391`, `docs/reviews/code-fact-check-report-digest-pass31.md:419-423`

---

## Claim 12a: "Any code in a brief sits in plain column-0 ``` fences, with no indented or list-item fences, raw HTML or stray carriage returns (`--check-brief` refuses a brief with those"

**Location:** `skills/dev-cycle/SKILL.md:335-337`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the named shapes against what `--check-brief` refuses at 4b7ec02. It does not establish whether the cycle actually writes briefs that obey it (no real brief exists on any branch).

`--check-brief` refuses each named shape (E3 BH1–BH3, BR1; the bats test at `:883` for indented and list fences). The refused set is wider than "raw HTML", though. Any line starting with `<` after spaces or tabs refuses (`rawhtml()`, `scripts/dev-cycle.sh:274`), including a placeholder line such as `<path>` or `<3`, and so does a BOM on line 1 (`:285`). Both refusals are shown for `--check-answer` in E4, and the reader is the same `FENCE_AWK`. An agent following the sentence could write a brief line starting with `<` that is not HTML, and the brief would then hold its slot until fixed. Tighten "raw HTML" to "no line starting with < (raw HTML, or a <placeholder>)", and add the BOM. **Wording.**

**Evidence:** `skills/dev-cycle/SKILL.md:335-337`, `scripts/dev-cycle.sh:274`, `scripts/dev-cycle.sh:285`, `fc32/e3-probe.log`, `fc32/e4.log`

---

## Claim 12b: "and a refused brief keeps its slot)"

**Location:** `skills/dev-cycle/SKILL.md:337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with the Rules' slot definition. It does not establish behavior for a `closed/` brief, which never holds a slot.

The Rules say: "**A brief holds a slot** when the glob prints `ok` for it … unless it is under `closed/` or `--check-brief` prints `done` or `dropped` for it; a brief the check skips keeps its slot (recorded) until the cause is fixed." (`skills/dev-cycle/SKILL.md:84-87`). A refusal is a skip (Claim 1), so the brief keeps its slot.

**Evidence:** `skills/dev-cycle/SKILL.md:84-87`, `skills/dev-cycle/SKILL.md:335-337`

---

## Claim 13: "each In flight line naming a `closed/` brief that reads `open` or `new` (for the user to set its status)" and 4e5cbbc: "not only those repointed this cycle, so such a line is reported every cycle until the user sets the brief's status" (api Info F5)

**Location:** `skills/dev-cycle/SKILL.md:373-375`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the final message's list, its persistence across cycles, and the cited finding. It does not establish what happens to such a line's keep-or-drop questions (unchanged this round).

In flight check 1 moves a line only on `done`, `dropped`, or a drop/done answer (`skills/dev-cycle/SKILL.md:272-283`). Check 3 files keep-or-drop only "if the brief is still open and under `briefs/`" (`:300`). So a line naming a `closed/` brief that reads `open` or `new` stays in In flight each cycle, and the new wording lists it each time, until a status is set and check 1 moves it. This matches the Rules' "a `closed/` brief that reads `open` or `new` is recorded and listed in the final message for the user to set" (`:91-92`). A line closed this cycle has already left In flight (to Done or Ideas), so a just-moved brief reading `new` is not falsely listed. api pass-31 `#### F5` is `**Severity:** Informational` (`docs/reviews/api-consistency-review-2026-10-02-digest-pass31.md:104-106`).

**Evidence:** `skills/dev-cycle/SKILL.md:84-96`, `skills/dev-cycle/SKILL.md:269-311`, `skills/dev-cycle/SKILL.md:371-378`, `4e5cbbc`, `docs/reviews/api-consistency-review-2026-10-02-digest-pass31.md:104-106`

---

## Claim 14: f54ca74 message: "Loop pass 31 (security Info F3): a brief the cycle writes with an indented or list-item fence, raw HTML or a stray CR would be refused by --check-brief every cycle and hold its slot; the brief format now says so."

**Location:** `f54ca74` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the named shapes and the cited finding. It does not establish that the named list is exhaustive (it does not claim to be; the SKILL text's version is Claim 12a).

Each named shape refuses (E3 BH1–BH3, BR1; bats `:883`), and a skip keeps the slot (Claim 12b). The commit adds that sentence at `skills/dev-cycle/SKILL.md:335-337`. The security pass-31 review has `#### F3. Briefs: the cycle writes briefs itself …` with `**Severity:** Informational` (`docs/reviews/security-review-2026-10-02-digest-pass31.md:94-96`).

**Evidence:** `f54ca74`, `skills/dev-cycle/SKILL.md:335-337`, `docs/reviews/security-review-2026-10-02-digest-pass31.md:94-96`, `fc32/e3-probe.log`

---

## Claim 15: Merge 2080f23 carries A's code and B's skill unchanged

**Location:** `2080f23` (merge commit)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the three files under review. It does not establish other files in the merge.

`git diff --stat f54ca74 2080f23 -- skills/dev-cycle/SKILL.md` and `git diff --stat 4b7ec02 2080f23 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` both printed nothing (rc 0, run 18:17Z in `/workspace/.claude/wt-devcycle`). (Paraphrased — no quote available because the output is empty and was read inline. The command is read-only and repeatable.)

**Evidence:** `2080f23`, `skills/dev-cycle/SKILL.md:1`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 7** (`scripts/dev-cycle.sh:382-392`): the ANSWER_AWK comment still says it prints `"odd N"` (now `odd N WHY`, which check_answer parses), and its refusal list omits the HTML-start, inner-CR and BOM causes. **Wording.**

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:55-58`): the help says "a raw HTML block"; the code refuses any line starting with `<` after spaces or tabs, and a BOM only on line 1. **Wording.**
- **Claim 4b** (`scripts/dev-cycle.sh:263-266`): "starts with <" needs "after any spaces or tabs", and "a byte-order mark" needs "at the start of the file". **Wording.**
- **Claim 5a** (`scripts/dev-cycle.sh:299`): the skip says "starts a raw HTML block" for autolinks, `<3` and paragraph-continuation tags, which start none. **Wording.**
- **Claim 10b** (d0bf53f message): "102 here" is `feat/dev-cycle`'s count; the commit's own branch has 98. The conclusion (none refused, readings unchanged) holds. **Wording.**
- **Claim 12a** (`skills/dev-cycle/SKILL.md:335-337`): "raw HTML" understates the refusal. Any brief line starting with `<` (a `<placeholder>`) or a BOM also refuses, and the brief then holds its slot. **Wording** (agent-facing).

Claims 2, 4b, 5a and 12a share one root: the refusal rule is "a line starting with `<`", and the texts call it "raw HTML". One phrase change fixes all four.

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass32.md`. Its first line is `Commit: 4b7ec02 (A) / f54ca74 (B)` and it carries the Replication field. It follows the code-fact-check structure: header, the seven per-claim fields plus Legibility-target, Claims Requiring Attention, and this note.

How it serves the user goal (merge after a clean k=1 pass):
- **Fence reader against the acceptance bar: met on everything tried.** Every pass-31 HTML, CR and BOM probe shape now refuses. Across the new families, the reader gives the CommonMark reading or refuses on every input: one-line comments including `<!-->` and `<!--->`, link reference titles, setext, tabs, NUL (mawk keeps NUL bytes), FF/VT, NBSP, a later-line BOM, container HTML and CRLF. The "one-line comment that CommonMark would continue" family is empty, because type 2 ends on the first line containing `-->`. No behavioral finding.
- **Gates and real files.** bats 49/49, shellcheck and lint clean. All 9 branches' real questions files read byte-identically to 6f24d91, none refused, and no real brief exists. The help range is exact.
- **B.** Both B changes are correct against the Rules, and the merge carries both sides unchanged.
- **Not clean yet: six wording items, none behavioral.** Claim 7 (Stale ANSWER_AWK comment) and Claims 2/4b/5a/12a ("raw HTML" where the rule is "a line starting with <", and "BOM" where it is "BOM on line 1"), plus Claim 10b ("102 here"). Claim 12a is agent-facing: a cycle that follows it literally can write a `<placeholder>` line and get a brief that holds its slot.
