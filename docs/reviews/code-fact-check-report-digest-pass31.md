Commit: 6f24d91 (A) / e19f411 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at 6f24d91; HEAD c028eca adds only the pass-30 review docs). B: `/workspace/.claude/wt-devcycle` (content at e19f411; HEAD is merge 0c45039).
**Scope:** Partial: the pass-30 fix round only. A: `git diff f4d27d2..6f24d91 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of 6f24d91. B: `git diff a7dfc0c..e19f411 -- skills/dev-cycle/SKILL.md` plus the message of e19f411 and merge 0c45039. Everything else is context only (rubric section "Pass 30").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 25
**Summary:** 19 verified, 3 mostly accurate, 1 stale, 2 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 patterns) first. Two claims are tallies of the logged kind ("48/48", "all 102 real IDs"). I recounted both by execution, and both hold (Claims 12 and 21). Neither Incorrect verdict is a fabricated symbol, API or flag, so nothing qualifies for the log. The brief allows no other write anyway.

**Worktree change not made by me (reported first, per the probe rule).** At 17:50:57Z, after all my probes had finished (the last ended 17:46:49Z), `git status --short` in wt-digest showed two changes from another session:
- ` M scripts/dev-cycle.sh`, mtime 17:50:01Z, 28+/14−. The change widens `rawhtml()` to any line starting with `<` (except a complete one-line comment), adds refusals for a carriage return inside a line and for a byte-order mark, and moves the help range to `2,69p`. This looks like a pass-31 fix already in progress for exactly the gap in Claims 4/20a.
- An untracked `api-consistency-review-2026-10-02-digest-pass31.md`, mtime 17:49:05Z.

I did not write either one. My probes ran only on `git show`/`git archive` copies of the fixed commits, inside `fc31/tmp.*`. The only file I wrote in a worktree is this report, and I did not touch the change. Every verdict below is on the committed 6f24d91 and e19f411. By 17:53:28Z the edit had been committed by that other session as d0bf53f ("fix(dev-cycle): pass-31 refuse HTML blocks, stray carriage returns and a BOM"), on top of c028eca. d0bf53f is outside this pass's fixed scope, and I did not review it. wt-devcycle's `git status --short` was empty, and `/workspace` was on `main`.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc31/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Repos made inside a temp dir got the same check after their `cd`. Every process ran under `timeout` and exited. None of mine was left running (the `ps` entries at 17:50Z were other sessions' shells, started after my last probe). Inside the worktrees I ran only read-only commands: `git diff`, `git show`, `git log`, `git rev-parse`, `git status` and `git archive`.

Scratch logs (not committed) are in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc31/`, called `fc31/` below. The system awk is mawk 1.3.4. No CommonMark implementation is installed (no markdown-it, commonmark, mistune, cmark or pandoc), so every "CM" expectation below is my reading of the CommonMark spec:
- §4.5, fenced code blocks
- §4.6, HTML blocks: start and end conditions for types 1–7
- §2.1, line endings: LF, CR or CRLF

Those expectations are why the CommonMark-dependent verdicts carry Medium confidence. The code's behavior on each input was executed and is certain.

Executed runs (UTC, 2026-10-02). Each command was `timeout <n> bash fc31/<script> > fc31/<log> 2>&1`, run with cwd `fc31/`, and each exited 0:
- **E1** `probe1.sh`, 17:44:25Z → `logs-probe1.log`. On a 6f24d91 archive copy it ran:
  - `bats test/scripts/dev-cycle.bats` → `logs/bats.log`: rc 0, `1..48`, 48 ok.
  - `python3 scripts/hermeticity-lint --root .` → `logs/lint.log`: rc 0.
  - `shellcheck scripts/dev-cycle.sh` → `logs/sc.log`: rc 0, 0 bytes.
  - `--help` → `logs/help.log`.
  - `--check-answer` on every real ID, f4d27d2 against 6f24d91, for the questions files at d535260, `/workspace` main, 35987c1, e19f411 and 0c45039 → `logs/ans-{old,new}-*.log`.
- **E2** `probe2.sh`, 17:45:38Z → `logs-probe2.log`. Runs `--check-answer` and `--check-brief` on f4d27d2 and 6f24d91 side by side, each case in its own temp repo:
  - column-0 shapes C1–C20;
  - HTML-block shapes H1–H8;
  - lone-CR shapes R1–R2;
  - brief shapes B1–B4, BH1–BH4 and BR1.
- **E3** `probe3.sh`, 17:46:10Z → `logs-probe3.log`. Greps the real questions files and briefs (main and 0c45039) for HTML-block starts and lone CRs, and runs `--check-brief` on the real briefs. There are none.
- **E4** `runall.sh`, 17:41Z–17:45:53Z → `logs-runall.log` and outputs in `fc31/tmp.UpVFIakbDf/out/*.out`. It reran every earlier fence probe from passes 26–30: 59 scripts from `fc26–30`, `sec26–30`, `api26–30`, `perf29–30`. Each script was copied by `gen.sh` with every pinned `dev-cycle.sh`/`questions.sh` commit replaced by 6f24d91, so every column now shows 6f24d91. The original "CM" annotations were kept. 58 exited rc 0. `api27/probe2` exited rc 1 at its `--check-brief` step: its repo has no default branch, so the error comes from that pass's setup and is not a fence result. I left out the 27 scripts that run bats, lint or shellcheck, since E1 covers those.
- **E5** `rerun2.sh`, 17:46:49Z. Reran three scripts whose commit came from a variable (`fc30/probe4`, `perf30/p2`, `perf29/p2-scaling`), which `gen.sh` had missed. `fc30/probe4` is the pass-30 indented-opener brief set (X1/X1b/X2/X1c/N9/X6), and all six are now `skip`. `perf30/p2` failed on its own line-number assertion about the awk program text, a perf-pass artifact and not a fence result.

Outcome of E4/E5:
- Every rerun shape in passes 26–30 now gives 6f24d91 either the annotated CM answer or a skip. That covers api P1–P3, security Q-001…Q-024, N1–N9 and C1–C18, fact-check Q-031…Q-045 and Q-101…Q-126, X1–X7, and the questions.sh archive splits P3, D1 and D2.
- The only rerun row whose output differs from its annotation is `s28 F4 Q-021` (`drop`, annotated "unrecognized/none"). The annotation is wrong. `` ```text `` opens a fence and the plain `` ``` `` at line 5 closes it (§4.5), so `**Answer:** [2]` is outside any fence and CM reads `drop`.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the person reading `--help`, a skip line or the final message.

---

## Claim 1: "\"skip Q-NNN: <reason>\" when it cannot be read (no such entry, a duplicate heading, a code fence never closed or not in plain column-0 form, a question heading inside a fence, a questions file that is not plain)"

**Location:** `scripts/dev-cycle.sh:53-57`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the skip causes `check_answer` prints at 6f24d91. It does not establish the "in both files" skip (`:460`), which predates this round and is also unlisted.

Every listed cause is printed. The new ones are `odd` (`:456`), `unbalanced` (`:457`) and `quoted` (`:458`), and E2 shows each (C10, C8, C9b). One cause is unlisted. A raw HTML start line (`<pre`, `<script`, `<style`, `<textarea`) also refuses the file through `odd`: `if (fenceish(l) || rawhtml(l)) { if (!odd) odd = NR; return 1 }` (`scripts/dev-cycle.sh:286`, excerpt; enclosing `fence()` spans `:279-288` — read). E2 C18 (`<PRE>`) gives `skip Q-1: line 8 … is a fence-like line`, and a `<pre>` line is not "a code fence … not in plain column-0 form". Tighten by adding "a raw HTML block". **Wording.**

**Evidence:** `scripts/dev-cycle.sh:53-57`, `scripts/dev-cycle.sh:279-288`, `scripts/dev-cycle.sh:446-465`, `fc31/logs-probe2.log`

---

## Claim 2: "-h|--help) sed -n '2,67p' \"$0\""

**Location:** `scripts/dev-cycle.sh:131`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the help range ending exactly at the last header comment line at 6f24d91. It does not establish the uncommitted worktree edit (`2,69p`), which I did not review.

E1 printed lines 66–69. Line 67 is `# default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data.`, line 68 is blank, and line 69 is `set -euo pipefail`. `--help` printed 66 lines, from `Gather the mechanical signals…` to the line-67 text.

**Evidence:** `scripts/dev-cycle.sh:2`, `scripts/dev-cycle.sh:66-69`, `fc31/logs/help.log`, `fc31/logs-probe1.log`

---

## Claim 3: "a line starting at column 0 with 3 or more ` or ~ opens one (a ` fence's info string holds no `), and only a column-0 line of the same character, at least as long and followed by nothing but spaces or tabs, closes it. Any other fence-like line (indented, after a list marker, or a column-0 line that neither opens nor, inside a fence, is plain content) is ambiguous … fence() records the first one's line number in `odd`, and the caller refuses the whole file."

**Location:** `scripts/dev-cycle.sh:256-264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `opens()`, `closes()`, `fenceish()` and the `odd` bookkeeping as written, for both callers. It does not establish that these rules give CommonMark's reading for every input (Claim 4). It also leaves out that `fenceish()` does not match a fence after `>` or after two list markers (`> ```` ``` ````, `- - ```` ``` ````). Such lines are read as text. That is harmless: CommonMark ends those containers at the next column-0 line, because fenced content takes no lazy continuation, so their fences cannot hide column-0 lines (E4 sec30 `fc Q-044`, `C12`, `N3`; E2 C16).

The code (`scripts/dev-cycle.sh:271-288`):

```
function opens(l,   ch, n) {
  ch = substr(l, 1, 1)
  if (ch != "`" && ch != "~") return 0
  n = run(l, ch); if (n < 3) return 0
  if (ch == "`" && index(substr(l, n + 1), "`")) return 0
  fch = ch; flen = n; return 1
}
function closes(l,   n) { n = run(l, fch); return n >= flen && substr(l, n + 1) ~ /^[ \t]*$/ }
function fence(l) {  # 1: a fence line or fenced content (not text); 0: ordinary text
  if (infence) {
    if (closes(l)) infence = 0
    else if (fenceish(l) && substr(l, 1, 1) != "`" && substr(l, 1, 1) != "~" && !odd) odd = NR
    return 1
  }
  if (opens(l)) { infence = 1; fline = NR; return 1 }
  if (fenceish(l) || rawhtml(l)) { if (!odd) odd = NR; return 1 }
  return 0
}
```

E2 C1–C7 and C11–C15 cover `~~~` inside a backtick fence, the reverse, `` ``` `` inside `` ```` ``, a longer closer, CRLF, trailing blanks, blank-only lines, a tilde info string holding a backtick, a closer carrying an info string, and `~~~` inside `~~~~`. All of them read `keep`, the CM answer. C19 and C20 (a 1-space fence, and a 3-space closer of a column-0 fence) refuse, naming the line. C10 (a backtick info string holding a backtick) also refuses, so a column-0 line that does not open is caught. bats tests at `:779`, `:823` and `:883` pass (E1).

**Evidence:** `scripts/dev-cycle.sh:256-288`, `fc31/logs-probe2.log`, `fc31/logs/bats.log`, `fc31/tmp.UpVFIakbDf/out/sec30-probe2.out`

---

## Claim 4: "Code fences, read only in their plain form, so that every fence this reads is read the way CommonMark reads it … and so is the start of a raw HTML block that can hold one (<pre>, <script>, <style>, <textarea>)"

**Location:** `scripts/dev-cycle.sh:255-256`, `scripts/dev-cycle.sh:261-262`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the claimed invariant (CommonMark's reading, or a refusal) on column-0 fence lines that sit inside a CommonMark HTML block of types 2–7, or that a lone CR splits off. Every other shape I tried meets the invariant (Claim 3). It does not establish whether any real file holds such a shape: E3 found none, the only HTML in the real questions files being one-line `<!-- index:start -->` / `<!-- index:end -->` comments, and no real brief exists. It does not cover a leading byte-order mark either (static only: cmark strips one, while the reader treats `\xEF\xBB\xBF```` ``` ```` as text).

Of the HTML block types, only type 1 can make the reader refuse: `function rawhtml(l) { l = tolower(l); return l ~ /^[ \t]*<(pre|script|style|textarea)([ \t>]|$)/ }` (`scripts/dev-cycle.sh:270`). Types 2–7 can also hold a column-0 `` ``` `` line, which CommonMark then reads as raw HTML and not as a fence:
- type 2, `<!--` … `-->`
- type 3, `<?` … `?>`
- type 4, `<!X` … `>`
- type 5, `<![CDATA[` … `]]>`
- type 6, `<div>`, `<details>` and others, up to a blank line
- type 7, a lone tag line after a blank line, up to a blank line

The reader opens a fence on such a line instead, and a second one rebalances the file. E2 results (6f24d91, and f4d27d2 the same):

| Case | Shape | 6f24d91 | CM |
|---|---|---|---|
| H1 | `<!--`, `` ``` ``, `-->`, `**Answer:** [2]`, the same three lines again, `**Answer:** [1]` | `keep` | `drop` |
| H2–H7 | the same pattern with `<div>`, `<details>`/`</details>`, `<span>`, `<?x`, `<!X`, CDATA | `keep` | `drop` |
| BH1–BH3 | a brief whose first `Status: open` sits between two HTML-held `` ``` `` lines | `done` | `open` |

The lone-CR rows go wrong the same way. The only CR handling is `{ sub(/\r$/, "") }` (`:413`, `:308`), which drops a trailing CR, but CommonMark ends a line at every CR:

| Case | Shape | 6f24d91 | CM |
|---|---|---|---|
| R1 | a `` ``` ``<CR><CR> line closes the fence in CM | `keep` | `drop` |
| R2 | `text<CR>```` ``` ```` opens a fence in CM | `drop` | `keep` |
| BR1 | brief form of R1 | `done` | `open` |

Every row is a wrong keep, drop or done with no refusal, which the brief's acceptance bar names as a finding. **Behavioral.** It is low-likelihood and needs no attacker: someone has to comment out or wrap a fenced block in HTML (or paste old-Mac line endings) so that two such lines balance. The brief direction is the worse one, because a wrong `done` lets check 1 move a brief that is still open. Fix: refuse any line outside a fence that starts an HTML block other than a complete one-line comment, and any line holding a CR. The uncommitted worktree edit noted above appears to do exactly this, and I did not review it.

**Evidence:** `scripts/dev-cycle.sh:255-265`, `scripts/dev-cycle.sh:270`, `scripts/dev-cycle.sh:308`, `scripts/dev-cycle.sh:413`, `fc31/logs-probe2.log`, `fc31/logs-probe3.log`

---

## Claim 5: "A fence still open at the end is recorded in `fline` (its opening line) and refuses the file too."

**Location:** `scripts/dev-cycle.sh:264-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `fline` holding the line of the opener left open, and both callers refusing. It does not establish behavior when an `odd` line also exists: `odd` takes precedence (`:311`, `:440`), which is still a refusal.

`if (opens(l)) { infence = 1; fline = NR; return 1 }` (`:285`) overwrites `fline` at each opener, so at END it names the last opener, which is the one still open. E2 C8 printed `skip Q-1: the code fence opened at line 9`, and line 9 is the bare `` ``` `` after `**Answer:** [1]`. E2 B4 printed `skip …: the code fence opened at line 3 …`.

**Evidence:** `scripts/dev-cycle.sh:285`, `scripts/dev-cycle.sh:311`, `scripts/dev-cycle.sh:439-445`, `fc31/logs-probe2.log`

---

## Claim 6: "function fence(l) {  # 1: a fence line or fenced content (not text); 0: ordinary text"

**Location:** `scripts/dev-cycle.sh:279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the return values. It does not establish that "fence line" covers the out-of-fence `fenceish`/`rawhtml` lines that also return 1 (`:286`). Those lines refuse the file anyway, so their return value never decides a reading.

The function returns 1 on every in-fence path (`:280-283`), on an opener (`:285`) and on an odd line (`:286`), and returns 0 otherwise (`:287`). The full function is quoted in Claim 3.

**Evidence:** `scripts/dev-cycle.sh:279-288`

---

## Claim 7: "A brief's state, read only from the default branch's commit (never the working tree): its first line outside a ``` or ~~~ fence that starts with \"Status:\", which must be exactly \"Status: open|done|dropped\"."

**Location:** `scripts/dev-cycle.sh:290-292`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the read rule. It does not establish the help text at `:29-37`, which says "skip <path>: <reason> otherwise" and so covers the new refusals generically.

The rule holds (E2 B1–B3 read `open`). The comment does not say that a brief is now not read at all when it holds an ambiguous fence line or a fence left open. The code is `END { if (odd) print "odd " odd; else if (infence) print "unbalanced " fline; else if (st != "") print st }` (`:311`), with the skips at `:313-314`. A brief whose first unfenced `Status:` line is fine still skips if a later line is odd (E2 B4, E4 sec30 brief rows). Add "unless the file holds an ambiguous fence line or a fence left open (a skip)". **Wording.**

**Evidence:** `scripts/dev-cycle.sh:290-316`, `fc31/logs-probe2.log`

---

## Claim 8: check_brief: an odd line or an open fence anywhere refuses the brief, naming the line

**Location:** `scripts/dev-cycle.sh:307-316`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the END precedence (odd, then unbalanced, then the status) and the three skip lines. It does not establish CommonMark parity for HTML-held fences (Claim 4).

The awk program runs to EOF with no early exit (`fence($0) { next }` then `!seen && /^Status:/ { … st = $0 }`, `:309-310`), so a later odd line still refuses. E2 BH4 (`<pre>`) printed `skip …: line 2 is a fence-like line …`. B4 printed the open-fence skip. bats `:856` and `:883` assert `line 2` and `line 3` (E1, 48/48). E5 reran the pass-30 X1/X1b/X2/X1c brief shapes, and all now skip, where f4d27d2 had given a wrong `done` (pass-30 Claim 5).

**Evidence:** `scripts/dev-cycle.sh:307-316`, `fc31/logs-probe2.log`, `fc31/tmp.UpVFIakbDf/out/fc30-probe4.out`, `fc31/logs/bats.log`

---

## Claim 9: "skip $a: line ${st#odd } is a fence-like line that is not a plain column-0 fence, so the brief is not read" (and the `--check-answer` twin)

**Location:** `scripts/dev-cycle.sh:313`, `scripts/dev-cycle.sh:456`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the message text for every cause of `odd`. It does not establish the line number's correctness, which is the first odd line (verified, E2).

`odd` is set by `fenceish()` and also by `rawhtml()` (`:286`). For a `<pre>` / `<PRE>` line, the message calls that line "a fence-like line", which it is not. E2 C18 printed `skip Q-1: line 8 of docs/working/questions.md is a fence-like line …` with line 8 = `<PRE>`, and BH4 gave the same for a brief. The reader acting on the message looks for a fence and finds HTML. Tighten to "a fence-like line or raw HTML block start". **Wording.**

**Evidence:** `scripts/dev-cycle.sh:286`, `scripts/dev-cycle.sh:313`, `scripts/dev-cycle.sh:456`, `fc31/logs-probe2.log`

---

## Claim 10: "Prints keep, drop, done, open, unrecognized, dup (the heading appears more than once), \"odd N\", \"unbalanced N\" or \"quoted N\" (the file's fences cannot be trusted; N is the line), or nothing when the file has no such entry. A trailing CR is dropped."

**Location:** `scripts/dev-cycle.sh:367-370`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the END outputs and their order. It does not establish that "A trailing CR is dropped" handles CRs elsewhere in a line (it does not; see Claim 4).

The END block (`scripts/dev-cycle.sh:439-445`):

```
END {
  if (odd) print "odd " odd
  else if (infence) print "unbalanced " fline
  else if (qline) print "quoted " qline
  else if (count > 1) print "dup"
  else if (count) print (!answered ? "open" : done ? result : "unrecognized")
}
```

The three file-level outputs come before "nothing", so the list's order matches the precedence. `count` now counts only unfenced headings (`heading($0)` runs after `fence($0) { next }`, `:415-416`), so "dup" means real duplicates (bats `:646`, `skip Q-9: more than one entry`).

**Evidence:** `scripts/dev-cycle.sh:413-445`, `fc31/logs/bats.log`

---

## Claim 11: "Each of these makes the whole file a skip for every ID, naming the line, because one stray fence line flips everything after it (and two flips can balance again): an ambiguous fence-like line, a fence still open at the end, or a \"### Q-NNN \" heading inside a fence (questions.sh archive splits entries at such a line, which is how stray fences arise)."

**Location:** `scripts/dev-cycle.sh:372-376`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the three refusals, and archive splits as a source of stray fences. It does not establish that these are the only sources of a stray or rebalanced fence: the HTML-held fences of Claim 4 also rebalance without tripping any of the three.

`infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }` (`:414`) runs before `fence($0)`, so a fenced question heading is caught. E4 reran sec30 P3, D1 and D2 and fc29 probe 6. There `questions.sh archive` splits entries at fenced headings, and 6f24d91 refuses both before the split (`line 14 … is a question heading inside a code fence`) and after it (`the code fence opened at line 17/16/18 … is never closed`, or a quoted line 19 in D2, where both files rebalance). bats `:808` asserts that both IDs skip at line 10.

**Evidence:** `scripts/dev-cycle.sh:414-415`, `fc31/tmp.UpVFIakbDf/out/sec30-probe3.out`, `fc31/tmp.UpVFIakbDf/out/sec30-probe4.out`, `fc31/logs/bats.log`

---

## Claim 12: "No real questions file has any of them."

**Location:** `scripts/dev-cycle.sh:376-377`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the questions files at d535260, `/workspace` main, 35987c1, e19f411 and 0c45039. It does not establish the same for future files.

E1 ran `--check-answer` on all IDs. That is 102 IDs at d535260, 35987c1, e19f411 and 0c45039, and 99 at main. The output was byte-identical between f4d27d2 and 6f24d91 (`diff` empty for all five), with no `skip` line and an empty stderr (setlocale noise aside). At d535260 the counts were 3 done, 19 drop, 26 keep, 13 open and 41 unrecognized. The grep for a fence-like line that does not start at column 0 printed nothing.

**Evidence:** `fc31/logs-probe1.log`, `fc31/logs/ans-new-d535260.log`, `fc31/logs/ans-new-main.log`, `fc31/logs/ans-new-0c45039.log`

---

## Claim 13: "skip $a: more than one entry with this heading in $f"

**Location:** `scripts/dev-cycle.sh:454`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the dup message after the removal of "(counting copies inside code fences)". It does not establish anything about fenced copies, which now refuse via `quoted` (Claim 11).

bats `:646` expects `skip Q-9: more than one entry` for two unfenced `### Q-9` entries, and it passes (E1).

**Evidence:** `scripts/dev-cycle.sh:443`, `scripts/dev-cycle.sh:454`, `test/scripts/dev-cycle.bats:638-647`, `fc31/logs/bats.log`

---

## Claim 14: "the code fence opened at line N of $f is never closed, so no entry in $f is read" / "line N of $f is a question heading inside a code fence (questions.sh archive splits entries there), so no entry in $f is read"

**Location:** `scripts/dev-cycle.sh:457-458`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the message text and line numbers. It does not establish that the archive is still read after questions.md refuses. It is not: `return` stops at the first refused file, so an ID that lives only in the archive also skips.

E2 C8 named line 9 (the opener) and C9b named line 9 (the fenced `### Q-2`). E4 D1 named line 18 after an archive split. All three are correct.

**Evidence:** `scripts/dev-cycle.sh:455-459`, `fc31/logs-probe2.log`, `fc31/tmp.UpVFIakbDf/out/sec30-probe3.out`

---

## Claim 15: "@test \"a closed fence hides its lines; fences close only with their own kind; the gate is anchored\""

**Location:** `test/scripts/dev-cycle.bats:779`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the title against the body at `:779-794`. It does not establish coverage of other fence kinds.

Q-1 has `fenced, then closed` between two `` ``` `` lines and no answer line, so it reads `unrecognized`. Q-3's `~~~` fence holds a `` ``` `` line, which does not close it, and the result is `keep`. Q-4's `OPEN (was **Status:** ANSWERED)` reads `open`, which is the gate. The test passes (E1).

**Evidence:** `test/scripts/dev-cycle.bats:779-794`, `fc31/logs/bats.log`

---

## Claim 16: "@test \"a question heading inside a fence refuses the whole file, never answers\""

**Location:** `test/scripts/dev-cycle.bats:808`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the title against the body. It does not establish the archive-split origin, which E4 covers.

Line 10 (`### Q-11 …`) sits inside the fence that Q-10 opens at line 9. Both Q-11 and Q-10 skip at line 10 (`:819-820`), and the test passes.

**Evidence:** `test/scripts/dev-cycle.bats:808-821`, `fc31/logs/bats.log`

---

## Claim 17: "@test \"plain column-0 fences: longer fences and info strings; the status field is read whole\""

**Location:** `test/scripts/dev-cycle.bats:823`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the title against the body. It does not establish meaning for the `Q-3` argument, which is still passed at `:834` but has no entry since its case was removed.

`` ```` `` holding `` ``` `` gives `drop Q-1`, an info-string line inside a fence gives `keep Q-2`, the status field gives `open Q-4`, and the brief reads `open`. The test passes.

**Evidence:** `test/scripts/dev-cycle.bats:823-840`, `fc31/logs/bats.log`

---

## Claim 18: "@test \"fences are tracked across the file: forged copies, a list-item fence refuses a brief, sections after an open fence\""

**Location:** `test/scripts/dev-cycle.bats:856`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the title against the body at 6f24d91. It does not establish any behavioral gap, because the test passes and the forged-copy case is covered by bats `:808` and E4.

This round removed the forged `### Q-18` copy from Q-1's fence. Q-1 now holds only `` ```bash ``/`ls`/`` ``` `` (`:861`). The assertion `"skip Q-18: no such entry"` (`:869`) therefore holds trivially, because Q-18 appears nowhere. `Q-15` is still passed at `:868` and `:878` though its entry was removed. At `:878-880` it skips only because the whole file refuses. "Forged copies" no longer describes the test. **Wording.**

**Evidence:** `test/scripts/dev-cycle.bats:856-881`, `git diff f4d27d2..6f24d91 -- test/scripts/dev-cycle.bats`

---

## Claim 19: "@test \"an indented or list-marker fence line anywhere refuses the whole file, naming the line\""

**Location:** `test/scripts/dev-cycle.bats:883`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the title against the body. In the questions file, the list-marker line (Q-2, line 16) is never the named line, because line 7 refuses first. The list-marker case is asserted only through the brief `2026-01-02-l.md`, at line 3.

`skip Q-1: line 7 … is a fence-like line` and `skip Q-3: line 7` are asserted (`:896`), and so are both briefs at line 3 (`:900`). The test passes.

**Evidence:** `test/scripts/dev-cycle.bats:883-901`, `fc31/logs/bats.log`

---

## Claim 20a: 6f24d91 message: "the fence reader now reads only the plain form, where the two agree by construction … or a raw HTML block that can hold one (<pre>, <script>, <style>, <textarea>), refuses the whole file" and Notes: "the cost is a skip (asked again), never a wrong reading"

**Location:** `6f24d91` (commit message, bullet 1 and Notes)
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers "agree by construction" and "never a wrong reading". It does not establish anything beyond Claim 4: same root, same evidence.

The commit message describes the same mechanism as the comment in Claim 4, and the same inputs refute it (paraphrased — no quote available because the evidence is the E2 result table already quoted under Claim 4). HTML blocks of types 2–7 and lone CRs give wrong `keep`/`drop`/`done` readings without a skip (H1–H7, R1–R2, BH1–BH3, BR1). **Behavioral.**

**Evidence:** `scripts/dev-cycle.sh:270`, `fc31/logs-probe2.log`

---

## Claim 20b: 6f24d91 message: "a column-0 run of 3+ ` or ~ opens, and only a column-0 run of the same character, at least as long, closes. Any other fence-like line … refuses the whole file, naming the line. Both --check-answer and --check-brief use it. --check-answer also refuses a file with a \"### Q-NNN \" heading inside a fence … every skip names the line … The fenced/dup counting it replaces is gone."

**Location:** `6f24d91` (commit message, bullets 1–2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the mechanics. It does not establish the parity claim (20a). "Every skip names the line" holds for the three fence skips, not for the dup or no-entry skips, and the message says it of the fence skips.

Both callers splice `FENCE_AWK`: `awk "$FENCE_AWK"'…'` at `:307` and `awk -v id="$a" "$FENCE_AWK$ANSWER_AWK"` at `:452`. `quoted` is at `:414`/`:442`. `fenced` and `quoted++` no longer appear in the script. A grep for `fenced` hits only comments at `:32`, `:305` and `:371`, and the remaining `quoted` hits are the new output label and unrelated comments (`:36`, `:321`, `:353`, `:369`). Claims 3, 8, 11 and 14 have the executed evidence.

**Evidence:** `scripts/dev-cycle.sh:307`, `scripts/dev-cycle.sh:414`, `scripts/dev-cycle.sh:439-459`, `fc31/logs-probe2.log`

---

## Claim 21: 6f24d91 message, bullets 3–4: "No real questions file has any of these lines (checked by three critics); all 102 real IDs read as before. Tests: the indented, list-marker and fenced-heading cases now assert the refusal with its line; the column-0 cases still read. 48/48; shellcheck and the hermeticity lint clean."

**Location:** `6f24d91` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the counts, the real-ID equality and the gates at 6f24d91. It does not establish "checked by three critics", which refers to pass-30 reports I did not reread. It does not establish raw-HTML refusal coverage either: no bats test exercises `rawhtml()` (grep for `<pre`, `<script` gives no hits), and the message does not claim one.

E1 results:
- bats: `1..48`, 48 ok.
- shellcheck: rc 0, 0 bytes.
- hermeticity lint: rc 0.
- All 102 IDs identical to f4d27d2 (Claim 12).

The refusal assertions with lines are in bats `:819-820`, `:874`, `:896` and `:900`.

**Evidence:** `fc31/logs/bats.log`, `fc31/logs/sc.log`, `fc31/logs/lint.log`, `fc31/logs-probe1.log`, `test/scripts/dev-cycle.bats:808-901`

---

## Claim 22: "each `closed/` brief an In flight line was repointed to that reads `open` or `new` (for the user to set its status)"

**Location:** `skills/dev-cycle/SKILL.md:370-373`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with the Rules paragraph that defines the repointing. It does not establish whether a `closed/` brief repointed in an earlier cycle and still `open` is listed again. "Was repointed" carries no time bound, but the Rules' "recorded and listed" is per cycle.

The Rules paragraph reads: "pointed at `docs/working/briefs/closed/<same name>` if `--check-path` prints `ok` there (… a `closed/` brief that reads `open` or `new` is recorded and listed in the final message for the user to set, and gets no keep-or-drop question)" (`skills/dev-cycle/SKILL.md:89-92`, excerpt; enclosing paragraph spans `:76-95` — read). The final message now names that same set. It no longer names every `closed/` file, which closes pass-30 api F4.

**Evidence:** `skills/dev-cycle/SKILL.md:76-95`, `skills/dev-cycle/SKILL.md:368-376`

---

## Claim 23: e19f411 message: "Loop pass 30 (api Info F4): only closed/ briefs an In flight line was repointed to, not every file in closed/."

**Location:** `e19f411` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the diff matching the message. It does not establish the api F4 text itself, which I did not reread.

`git show --stat e19f411` lists only `skills/dev-cycle/SKILL.md | 3 ++-`, and the diff is the sentence in Claim 22.

**Evidence:** `e19f411`, `skills/dev-cycle/SKILL.md:370-373`

---

## Claim 24: merge 0c45039 "Merge branch 'feat/dev-cycle-digest' into feat/dev-cycle"

**Location:** `0c45039`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers parents and the blobs under review. It does not establish other paths in the merge.

`git log -1 --format=%P 0c45039` printed `e19f411… c028eca…`. `git rev-parse` gave these blobs, read inline at 17:47Z in `/workspace/.claude/wt-devcycle`, exit 0:
- `scripts/dev-cycle.sh`: 84c7b90 at 0c45039, the same as 6f24d91.
- `test/scripts/dev-cycle.bats`: 48dd066 at 0c45039, the same as 6f24d91.
- `skills/dev-cycle/SKILL.md`: bb8ecf0 at 0c45039, the same as e19f411.

(Paraphrased — no quote available because the output was read inline rather than captured to a file. The commands are read-only and repeatable.) E1 also read 0c45039's questions files, with all 102 IDs unchanged.

**Evidence:** `0c45039`, `e19f411`, `6f24d91`, `fc31/logs-probe1.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`scripts/dev-cycle.sh:255-256, 261-262`): "every fence this reads is read the way CommonMark reads it" and the four-tag list of HTML blocks "that can hold one" are wrong. HTML blocks of types 2–7 (`<!--…-->`, `<div>`, `<details>`, a lone tag line, `<?…?>`, `<!X…>`, CDATA) and lone CRs hide or create column-0 fence lines in CommonMark, and the reader gives wrong `keep`/`drop`, and wrong brief `done`, with no skip (E2 H1–H7, R1–R2, BH1–BH3, BR1). **Behavioral**, Low likelihood, and no real file has the shape. Fix: refuse any line outside a fence that starts an HTML block other than a complete one-line comment, and any line holding a CR (an uncommitted worktree edit appears to do this).
- **Claim 20a** (6f24d91 message): "agree by construction" and "never a wrong reading" are wrong, with the same root and evidence as Claim 4. **Behavioral.**

### Stale
- **Claim 18** (`test/scripts/dev-cycle.bats:856`): the title says "forged copies", but the forged Q-18 copy was removed, so `skip Q-18: no such entry` holds trivially. `Q-15` is passed with no entry. **Wording.**

### Mostly Accurate
- **Claim 1** (`scripts/dev-cycle.sh:53-57`): the help's skip list omits the raw-HTML refusal. **Wording.**
- **Claim 7** (`scripts/dev-cycle.sh:290-292`): the check_brief comment omits that a brief with an ambiguous fence line or an open fence is not read at all. **Wording.**
- **Claim 9** (`scripts/dev-cycle.sh:313, 456`): a `<pre>`/`<script>`/`<style>`/`<textarea>` refusal is reported as "a fence-like line". **Wording.**

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass31.md`. Its first line is `Commit: 6f24d91 (A) / e19f411 (B)` and it carries the Replication field. It follows the code-fact-check structure: header, the seven per-claim fields plus Legibility-target, Claims Requiring Attention, and this note.

How it serves the user goal (merge after a clean k=1 pass):
- **Fence reader against the acceptance bar.** The reader meets the bar on every column-0 shape I tried, and on every rerun probe from passes 26–30 (59 scripts): each gives the CommonMark answer or a skip. Every pass-30 residue (X1/X1b/X2 wrong `done`) now refuses.
- **Gates and real files.** The gates are green: bats 48/48, shellcheck and lint clean. The real files read unchanged: 102/99 IDs identical to f4d27d2, nothing refused. The help range is exact.
- **B.** The B change and the merge are correct.
- **Not clean yet: one behavioral gap (Claims 4/20a).** Multi-line HTML blocks and lone CRs can still produce a wrong `keep`/`drop`, or a wrong brief `done`, without refusing. It is Low likelihood, no real file has the shape, and a fix appears to be in progress in the worktree (uncommitted, not reviewed here).
- **Not clean yet: four wording items.** Claims 1, 7, 9 and 18.
