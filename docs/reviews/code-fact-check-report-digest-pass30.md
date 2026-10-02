Commit: f4d27d2 (A) / a7dfc0c (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at f4d27d2; HEAD 0a56e33 adds only the pass-29 review docs, and `git diff --stat f4d27d2..HEAD` lists only `docs/reviews/` files). B: `/workspace/.claude/wt-devcycle` (content at a7dfc0c; HEAD is merge 35987c1).
**Scope:** Partial: the pass-29 fix round only. A: `git diff 38578a9..f4d27d2 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of e2f2d54 and f4d27d2. B: `git diff c345865..a7dfc0c -- skills/dev-cycle/SKILL.md` plus the message of a7dfc0c and merge 35987c1. Everything else is context only (rubric section "Pass 29").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 26
**Summary:** 23 verified, 2 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 5 patterns) before starting. Two claims are test or ID tallies, the class of the logged "85 tests" and "mode1-equiv 33" patterns. Both were recounted by execution and hold (Claims 18 and 21). No verdict is Incorrect, so nothing goes in the log. The brief allows no other write anyway.

**Worktree change not made by me (reported first, per the probe rule).** At 17:35:54Z, after all my probes had finished (the last ended 17:32:49Z), `git status --short` in wt-digest showed ` M scripts/dev-cycle.sh` (mtime 17:35:10Z) and an untracked `api-consistency-review-2026-10-02-digest-pass30.md` (mtime 17:33:56Z), from another critic. The uncommitted diff (47+/34−) rewrites FENCE_AWK to accept only column-0 fences and to refuse files with any other fence-like line (`odd`/`fline`). It looks like a pass-30 fix already in progress. I did not write it: my probes wrote only under `fc30/tmp.*` and ran on `git archive`/`git show` copies of the fixed commits, and the only file I wrote in the worktree is this report. I did not touch it. Every verdict below is on the committed f4d27d2 and a7dfc0c. wt-devcycle's `git status --short` was empty, and `/workspace` was on `main`.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc30/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Repos inside the temp dir got the same check after their `cd`. Probes took the code with `git archive <commit> | tar -x` or `git show <commit>:<path>` into the temp dir and ran it there. That includes bats, shellcheck and the hermeticity lint, which ran on an archive copy rather than in the worktree. Every process ran under `timeout` in the foreground, and all of them exited. Inside the worktrees I ran only read-only commands: `git diff`, `git show`, `git log`, `git rev-parse`, `git status` and `git archive`. Before my probes wt-digest held only committed state. After them, wt-devcycle was clean and `/workspace` was still on `main` (see the worktree note above for wt-digest). The only file I wrote outside `fc30/` is this report.

Scratch logs (not committed) are in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc30/`, called `fc30/` below. In the logs, `old` is 38578a9 (pass 28), `e2f`/`mid` is e2f2d54, and `new` is f4d27d2. The system awk is mawk (`readlink -f /usr/bin/awk` → `/usr/bin/mawk`), so every awk result is mawk's. Setlocale warnings in the logs come from the environment's uninstalled `en_US.UTF-8`. No CommonMark implementation is installed in the sandbox (no markdown-it, commonmark, cmark or pandoc), so every "CM" expectation below is my reading of the CommonMark spec §4.5 (fenced code blocks) and §5.2 (list items). That is why the CommonMark-dependent verdicts carry Medium confidence.

Executed runs (UTC, 2026-10-02). Each command was `timeout <n> bash fc30/probeN.sh > fc30/logs/probeN.log 2>&1`, run with cwd `fc30/`, and each exited 0:
- **E1** `probe2.sh`, 17:29:06Z → `logs/probe2.log`. Reruns the pass-29 fence shapes through `--check-answer` and `--check-brief`, old, e2f and new side by side. The shapes are api P1–P3, the security pass-28/29 shapes (Q-001…Q-024, N1–N9 and Q-035/036), fact-check Q-031…Q-045 and Q-101…Q-114, and new shapes X1–X7. Each case ran in its own temp repo.
- **E2** `probe1.sh`, 17:30:10Z → `logs/probe1.log`. On an f4d27d2 archive copy it ran `bats test/scripts/dev-cycle.bats` (`logs/bats.log`, rc 0, 48 ok), `python3 scripts/hermeticity-lint --root .` (`logs/lint.log`, rc 0, "126 test file(s) checked, no unstubbed network spawns") and `shellcheck scripts/dev-cycle.sh` (`logs/sc.log`, rc 0, 0 bytes). It also ran `--help` (`logs/help.log`). Then it ran `--check-answer` on every real ID, old against e2f against new, for the questions files at d535260 (102 IDs), `/workspace` main (99) and 35987c1 (102), with outputs in `logs/ans-{old,mid,new}-*.log`. Last, it ran the mawk `opens()` table.
- **E3** `probe3.sh`, 17:31:05Z → `logs/probe3.log`. Runs `questions.sh init` and then `archive` on an ANSWERED entry that quotes a `### Q-` heading inside a fence, with `--check-answer` before and after. It also covers performance's 16 MiB-of-spaces archive (perf29 `longsp`) and a balanced 16 MiB-spaces fence line inside a fence.
- **E4** `probe4.sh`, 17:32:14Z → `logs/probe4.log`. Runs `--check-brief` on indented-opener shapes at 366efd7, 38578a9 and f4d27d2.
- **E5** `probe5.sh`, 17:32:28Z → `logs/probe5.log`. On an e2f2d54 archive copy it ran bats (`logs/bats-e2f.log`, rc 0, 48 ok), shellcheck (`logs/sc-e2f.log`, rc 0) and the lint (`logs/lint-e2f.log`, rc 0).

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the person reading `--help` or the final message.

---

## Claim 1: "unrecognized (answered, but no answer line was found, or the first one's text does not start with one of the options)"

**Location:** `scripts/dev-cycle.sh:51-53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the two routes to `unrecognized` for an answered entry: no answer line, or a first answer line whose leading token is not an option. It does not establish the token-boundary detail. A word option must be followed by the end of the text, punctuation or a dash, so for example `keeping` is unrecognized although it "starts with" `keep`. The comment at `:378-380` states that detail, and the help does not.

The END rule is `else if (count) print (!answered ? "open" : done ? result : "unrecognized")` (`scripts/dev-cycle.sh:431`). An answered entry with no answer line (`done` unset) therefore prints `unrecognized`, and E1 shows exactly that: `Q-109 answered, no answer line | … new unrecognized`. When an answer line is present, `result = option(rest)` (`:425`), and `option()` returns `"unrecognized"` when the text matches no `[1]`/`[2]`/`[3]` or `1|2|3|keep|drop|done` prefix (`:387` — excerpt; enclosing `option()` spans `:382-395` — read).

**Evidence:** `scripts/dev-cycle.sh:51-53`, `scripts/dev-cycle.sh:382-395`, `scripts/dev-cycle.sh:425-431`, `fc30/logs/probe2.log`

---

## Claim 2: "\"skip Q-NNN: <reason>\" when it cannot be read (no such entry, a duplicate heading, a heading only inside a code fence, a code fence never closed, a questions file that is not plain)"

**Location:** `scripts/dev-cycle.sh:53-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the five skip causes that `check_answer` prints. It does not establish the sixth skip, which the help does not list: "an entry with this heading in both docs/working/questions.md and questions-archive.md" (`:444`). That skip predates this round. It also does not establish that "never closed" matches CommonMark's view of the file. It is FENCE_AWK's reading (see Claim 5).

`check_answer` prints `skip $a: a code fence in $f is never closed, so nothing after it can be trusted` on `unbalanced` (`scripts/dev-cycle.sh:442`). The other listed causes are at `:435` (not an ID), `:437` (not plain), `:441` (dup), `:443` (fenced) and `:448` (`else echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md"; fi`). In E3, a file left unbalanced by `questions.sh archive` gave the never-closed skip for all five IDs.

**Evidence:** `scripts/dev-cycle.sh:53-57`, `scripts/dev-cycle.sh:433-449`, `fc30/logs/probe3.log`

---

## Claim 3: "-h|--help) sed -n '2,67p' \"$0\""

**Location:** `scripts/dev-cycle.sh:131`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the help range ending exactly at the last header comment line at f4d27d2. It does not establish that the range stays right after later header edits, since nothing checks it mechanically.

E2 printed lines 66–69 of the file. Line 67 is `# default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data.`, line 68 is blank and line 69 is `set -euo pipefail`. `--help` printed 66 lines. Its first line is `Gather the mechanical signals…` (from line 2), and its last line is the line-67 text.

**Evidence:** `scripts/dev-cycle.sh:2`, `scripts/dev-cycle.sh:67-69`, `fc30/logs/help.log`, `fc30/logs/probe1.log`

---

## Claim 4: "An opener is a line of 3 or more ` or ~ after at most 3 spaces, or after a list marker (\"- \", \"* \", \"+ \", \"1. \", \"1) \") that itself has at most 3 spaces before it; a ` fence's info string holds no `. A line indented 4 or more spaces without a marker is indented code, not a fence. Only a line of the same character, at least as long, with no list marker, indented at most 3 columns past the opener's fence and followed by nothing but spaces or tabs, closes it."

**Location:** `scripts/dev-cycle.sh:255-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the opener and closer predicates as written, `match()`/`RLENGTH` under mawk, and `fcol` recording. It does not establish whether this rule matches CommonMark (Claim 5). It also leaves out two things the comment does not mention: tabs count as no indentation (`spaces()` counts only spaces), and a marker may be followed by any run of blanks.

The code (`scripts/dev-cycle.sh:264-280`):

```
function spaces(l,   n) { n = 0; while (substr(l, n + 1, 1) == " ") n++; return n }
...
function opens(l,   i, s, m, ch, n) {
  i = spaces(l); if (i > 3) return 0
  s = substr(l, i + 1)
  if (match(s, /^([-*+]|[0123456789]+[.)])[ \t]+/)) { i += RLENGTH; s = substr(s, RLENGTH + 1) }
  ...
  fch = ch; flen = n; fcol = i; return 1
}
function closes(l,   i, s, n) {
  i = spaces(l); if (i > fcol + 3) return 0
  s = substr(l, i + 1); n = run(s, fch)
  return n >= flen && substr(s, n + 1) ~ /^[ \t]*$/
}
```

`closes()` strips no marker, so a line beginning `- ` has a run of 0 of `fch` and never closes. E2's mawk table shows `match()`/`RLENGTH` working: `- ```` → `opens=1 fcol=2`; `1. ```` → `fcol=3`; `12) ```` → `fcol=4`; `   * ~~~~` → `fcol=5 flen=4`; `    ```` → `opens=0`; `   ```` → `opens=1 fcol=3`; `-```` → `opens=0`; `+<tab>```` → `opens=1 fcol=2`. E4 tests the closer bound. Under a 2-space opener (`fcol` 2), a 7-space inner line does not close it (`X1c … f4d27d2 open`), while a 4-space line does (`X1 … done`). E1 shows that list-marker and 8-space inner lines no longer close a column-0 fence (N1, N1b, N2, Q-101, Q-102: all `keep`).

**Evidence:** `scripts/dev-cycle.sh:255-280`, `fc30/logs/probe1.log`, `fc30/logs/probe2.log`, `fc30/logs/probe4.log`

---

## Claim 5: "Code fences, close to CommonMark."

**Location:** `scripts/dev-cycle.sh:255`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers every pass-29 probe shape plus the new shapes X1–X7, read by `--check-answer` and `--check-brief` at f4d27d2. It does not establish CommonMark behavior by running a reference implementation, since none is installed. The CM column is my reading of spec §4.5 and §5.2.

Every pass-29 probe now gives the CommonMark reading, a skip or `unrecognized`. That covers api P1–P3 (`keep`), N1/N1b/N2 (`keep`), Q-101/Q-102 (`keep`), Q-031/Q-032 (`drop`), Q-035 (`done`), Q-112 (`drop`), and the briefs N1/N2/N3 and the bats `2026-01-02-l` variant (`open`). N3, N5, Q-045, Q-105 and Q-111 now read as the new never-closed skip (E1). Performance's 16 MiB-of-spaces archive now reads as a skip for every ID instead of 38578a9's `drop Q-100`. A balanced 16 MiB-spaces line inside a fence is content (`keep Q-7`, against 38578a9's `drop`) (E3).

**Behavioral residue.** The closer bound is `fcol + 3` (`scripts/dev-cycle.sh:276`, quoted in Claim 4). For an opener with 1–3 leading spaces and no marker, `fcol` is that indentation, so the opener accepts a closer indented up to 4–6 spaces. CommonMark §4.5 allows a closing fence at most 3 spaces of indentation, whatever the opener's indentation. A 4–6-space fence line inside such a fence is content there, not a closer. `--check-brief` has no unbalanced guard, so it gives a wrong `done`. E4 shows `X1 2-space opener, 4-space inner | 366efd7 open | 38578a9 done | f4d27d2 done | CM: open`, and X1b (1-space opener) and X2 (3-space opener, 6-space inner) behave the same way. In `--check-answer` the same shape flips parity, so the file ends unbalanced and every ID is a skip (E1 X1/X2: `skip … never closed`). That reading is fail-safe. This residue regressed in 38578a9 (366efd7 read `open`), and e2f2d54 fixed it only for column-0 and list-marker openers. Two further divergences predate this round: a list-item fence closed by a column-0 line (N9), and a marker followed by 5+ spaces (X6). In both, f4d27d2 reads `keep` where my CommonMark reading ends the list item and leaves a fence open at EOF, which would be a skip. Both readings are low-confidence (CM reading Medium) and plausibly match the writer's intent. **Behavioral.** Preconditions for the `done` case: a brief with a 1–3-space-indented fence whose body holds a 4–6-space fence line followed by a quoted `Status: done`. No real file has one. Low impact.

**Evidence:** `scripts/dev-cycle.sh:255`, `scripts/dev-cycle.sh:268-279`, `scripts/dev-cycle.sh:299-304`, `fc30/logs/probe2.log`, `fc30/logs/probe3.log`, `fc30/logs/probe4.log`

---

## Claim 6: "Prints keep, drop, done, open, unrecognized, dup (the heading appears more than once, counting copies inside code fences), fenced (it appears only inside a fence), or nothing when the file has no such entry."

**Location:** `scripts/dev-cycle.sh:356-359`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the set of values ANSWER_AWK prints. It does not establish anything about `check_answer`'s mapping of those values, which is correct (`:440-443`).

f4d27d2 added a ninth output, and it takes precedence over the others: `END { if (infence) print "unbalanced" … }` (`scripts/dev-cycle.sh:427-428` — excerpt; END continues to `:432` — read). The comment's list omits `unbalanced`. "Nothing when the file has no such entry" is also no longer true for an unbalanced file. E3 printed `skip Q-999: a code fence in docs/working/questions.md is never closed…` for an ID that has no entry. The next paragraph (`:362-365`) does state the every-ID skip, so a reader of the whole comment is not misled about behavior. Wording.

**Evidence:** `scripts/dev-cycle.sh:356-365`, `scripts/dev-cycle.sh:427-432`, `fc30/logs/probe3.log`

---

## Claim 7: "a heading inside one is a quote, never the entry (though a \"### Q-NNN \" line there still ends the entry being read), and no fenced line is read"

**Location:** `scripts/dev-cycle.sh:360-362`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the fenced-line rule, including the literal trailing space in `"### Q-NNN "`. It does not establish the case of a fenced `### Q-9` with nothing after the number, or with a tab after it. Such a line does not end the entry, although `heading()` would accept that form as a heading (`:399`). The comment's literal text is still accurate.

The code is `infence { if (heading($0)) quoted++; if ($0 ~ /^### Q-[0123456789]+ /) inside = 0; if (closes($0)) infence = 0; next }` (`scripts/dev-cycle.sh:402`). E1 shows Q-035 (```` ```bash ```` / `# comment` / `## two` / `### three` / ```` ``` ```` / `[3]`) as `done`, where 38578a9 gave `unrecognized`. Q-112 (fenced `### other`) gives `drop`, X3 (fenced `### Q-9`, no trailing space) gives `drop`, and X4 (fenced `### Q-9 · quoted`) gives `unrecognized`. That last one is by design. s28 F1's forged Q-018 is still `skip … only inside a code fence`.

**Evidence:** `scripts/dev-cycle.sh:360-362`, `scripts/dev-cycle.sh:396-404`, `fc30/logs/probe2.log`

---

## Claim 8: "A file that ends with a fence still open is a skip for every ID: one stray fence line (questions.sh archive can split an entry at a fenced heading) flips what follows, so nothing in that file is trusted."

**Location:** `scripts/dev-cycle.sh:362-365`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the every-ID skip, including IDs with no entry and IDs whose entry sits in the other (balanced) file, and the archive-split cause. It does not establish anything about a parity error that happens to leave the file balanced. Such a file still reads normally (see Claim 5's X1 note).

`unbalanced` is printed before any per-entry result (`:428`), and `check_answer` returns on it for whichever file produced it (`:442`). E3, archive split: before `archive`, Q-001 read `unrecognized`, Q-002 `drop` and Q-003 `open`. `questions.sh archive` printed `archived Q-001` and `archived Q-002`, and afterwards `questions.md` and `questions-archive.md` each held one fence line. f4d27d2 then printed `skip … questions.md is never closed` for Q-001, Q-002, Q-003, Q-000 and the absent Q-999. 38578a9 had read `skip … only inside a code fence` for Q-002 and Q-003 and `open Q-000` (a wrong entry). In E3's `longsp` case the archive alone is unbalanced, and Q-1, which lives in the balanced `questions.md`, also reads `skip … questions-archive.md is never closed`. The bats case at `test/scripts/dev-cycle.bats:878-883` passes (E2).

**Evidence:** `scripts/dev-cycle.sh:362-365`, `scripts/dev-cycle.sh:427-443`, `test/scripts/dev-cycle.bats:878-883`, `fc30/logs/probe3.log`, `fc30/logs/bats.log`

---

## Claim 9: "has a \" · \"-separated field that is \"**Status:** ANSWERED\" once blanks around the field are trimmed (the last Status field counts, as in questions.sh)"

**Location:** `scripts/dev-cycle.sh:367-369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the leading trim per field, the trailing trim on the chosen value, and last-field-wins. It does not establish anything about blanks inside the field: `**Status:**  ANSWERED` with two spaces is not answered. It also does not establish whether questions.sh trims. Pass 29 found that it does not, so "as in questions.sh" attaches to last-field-wins only.

The code is `for (i = 1; i <= n; i++) { f = fld[i]; sub(/^[ \t]+/, "", f); if (substr(f, 1, 12) == "**Status:** ") v = substr(f, 13) }` followed by `sub(/[ \t]+$/, "", v); answered = (v == "ANSWERED")` (`scripts/dev-cycle.sh:409-410`). E1 shows Q-106 (trailing tab) as `drop`, Q-108 (`ANSWERED · OPEN`) as `open`, Q-110 (`OPEN · ANSWERED`) as `drop`, and Q-107 (`·**Status:**`, no space) as `open`.

**Evidence:** `scripts/dev-cycle.sh:367-369`, `scripts/dev-cycle.sh:407-412`, `fc30/logs/probe2.log`

---

## Claim 10: "skip $a: a code fence in $f is never closed, so nothing after it can be trusted"

**Location:** `scripts/dev-cycle.sh:442`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the skip naming the right file and stating a true reason. It does not establish that the reason covers the skip's full reach: entries before the stray fence are skipped too (Claim 8), and the message says only "after it".

E3 named `questions-archive.md` when only the archive was unbalanced, and `questions.md` when the live file was. The message does not say where the fence opened. Pass 29's api review asked for that information on the fenced-only skip (F2), but it is not a claim this line makes.

**Evidence:** `scripts/dev-cycle.sh:442`, `fc30/logs/probe3.log`

---

## Claim 11: "# Inside a fence only a \"### Q-NNN \" heading ends the entry, so a shell # comment in a pasted block does not cut it short."

**Location:** `test/scripts/dev-cycle.bats:759-760`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the behavior the comment states. It does not establish that this test exercises that behavior. Its fixture uses `# a comment, not a heading` (`:754`), a single `#` that never ended an entry, so the `### ` case is covered only by E1's Q-035, not by any bats case.

The code is the `infence` rule quoted in Claim 7 (`scripts/dev-cycle.sh:402`). Pass 29's security review reported this comment as stale at 38578a9. It is now accurate.

**Evidence:** `test/scripts/dev-cycle.bats:746-764`, `scripts/dev-cycle.sh:402`, `fc30/logs/probe2.log`

---

## Claim 12: "@test \"a fenced heading ends the entry being read; fences close only with their own kind; the gate is anchored\""

**Location:** `test/scripts/dev-cycle.bats:779`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the title's three parts against the fixture and assertions. It does not establish anything about Q-2, which the fixture writes but the test never asks about.

The fixture opens a fence in Q-1 (`%s\nno close\n\n`, `:786`), so Q-2's heading `### Q-2 · other` (`:787`) is a fenced `### Q-NNN ` line and ends Q-1. The test expects `unrecognized Q-1` (`:792`). Q-3 quotes a ```` ``` ```` inside `~~~` and expects `keep Q-3`, which is "their own kind". Q-4 has `(was **Status:** ANSWERED)` inside the field and expects `open Q-4`, which is "the gate is anchored". E2's bats run reports the test ok.

**Evidence:** `test/scripts/dev-cycle.bats:779-795`, `fc30/logs/bats.log`

---

## Claim 13: "printf '%s\n' \"$f\"   # balance the file: a fence still open at its end is a skip for every ID"

**Location:** `test/scripts/dev-cycle.bats:788`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the parity of the fixture without and with the added line. It does not establish anything beyond this fixture.

Without line 788, the toggles are Q-3 `~~~` open/close, Q-1's ```` ``` ```` open, Q-2's first ```` ``` ```` close and its second open, so the file ends inside a fence. Line 788 closes it (paraphrased — no quote available because the parity follows from counting fence lines across `:784-787`, not from any one line). The every-ID consequence is Claim 8.

**Evidence:** `test/scripts/dev-cycle.bats:782-789`, `fc30/logs/bats.log`

---

## Claim 14: "# A fence left open before a later section: the whole file is a skip."

**Location:** `test/scripts/dev-cycle.bats:878`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the assertion that Q-21 and the unrelated Q-15 both skip. It does not establish anything about other IDs, which Claim 8 covers by probe.

Lines 879–883 append Q-21 with an unclosed ```` ``` ```` before `## Archive`, then assert `skip Q-21: a code fence in docs/working/questions.md is never closed` and the same for Q-15. The test passes (E2).

**Evidence:** `test/scripts/dev-cycle.bats:878-883`, `fc30/logs/bats.log`

---

## Claim 15: "@test \"a fence line inside a fence is content, not a closer; indented code is not a fence\""

**Location:** `test/scripts/dev-cycle.bats:886`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers column-0 fences with a 4-space or `- ` inner line, an indented-code opener, and the two brief variants. It does not establish the 1–3-space-opener case (Claim 5), which no bats test exercises.

Q-1 has a 4-space inner line, Q-2 a `- ` inner line and Q-3 a 4-space `` ``` `` with no fence, and the test expects `keep` for all three (`:891-900`). Brief `i` has a 4-space inner line and brief `l` a `1. ` inner line, and the test expects `open` for both (`:895-903`). The test passes at f4d27d2 (E2) and at e2f2d54 (E5). In E1, 38578a9 gave `drop`/`done` on the same shapes (api P1/P2, briefs).

**Evidence:** `test/scripts/dev-cycle.bats:886-904`, `fc30/logs/bats.log`, `fc30/logs/bats-e2f.log`, `fc30/logs/probe2.log`

---

## Claim 16: e2f2d54 message, bullet 1: "Pass 28 let a fence opener follow any indentation or a list marker, and the closer test shared that leniency, so an indented or list-marker fence line inside a column-0 fence closed it and exposed what followed (a wrong drop from --check-answer, a wrong done from --check-brief). An opener now has at most 3 spaces, or a list marker with at most 3 spaces before it; a line indented 4+ spaces without a marker is indented code; a closer has no list marker and is indented at most 3 columns past the opener's fence." (subject: "fence closers bounded by the opener (regression fix)")

**Location:** `e2f2d54` (commit message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the diagnosis (column-0 fences) and the new rule. It does not establish that the pass-28 regression is fully fixed. It is not fixed for openers indented 1–3 spaces, and the subject's "regression fix" does not name that limit.

The diagnosis holds. In E1, 38578a9 gave `drop` on api P1/P2, N1, N1b, N2, Q-101 and Q-102, and `done` on the N1/N2/N3 briefs, and e2f2d54 gives `keep`/`open` on all of them. The new rule matches the code (Claim 4). The regression, though, is wider than "inside a column-0 fence". E4 shows a 1–3-space opener with a 4–6-space inner line reading `open` at 366efd7, `done` at 38578a9 and `done` at e2f2d54 and f4d27d2. The bound `fcol + 3` keeps it. **Behavioral** (the same residue as Claim 5). Low impact, no real file.

**Evidence:** `scripts/dev-cycle.sh:268-279`, `fc30/logs/probe2.log`, `fc30/logs/probe4.log`

---

## Claim 17: e2f2d54 message, bullet 2: "Help: unrecognized also covers an answered entry with no answer line; the fenced-only skip names the open-fence cause; the comment lists open among the fail-safe outcomes."

**Location:** `e2f2d54` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the three text changes as they stood at e2f2d54. It does not establish that they survive at f4d27d2. The second and third were superseded there: the help now lists "a code fence never closed" as its own cause, and the comment states the every-ID skip.

`git diff 38578a9 e2f2d54` shows `+#             answer line was found, or the first one's text does not start`, `+#             heading, a heading only inside a code fence (an earlier fence` / `+#             left open hides what follows)`, and `+# the rest of the file, which can only make an answer unreadable (a skip, open`.

**Evidence:** `scripts/dev-cycle.sh:51-57` (at e2f2d54), `scripts/dev-cycle.sh:356-365` (at e2f2d54)

---

## Claim 18: e2f2d54 message, bullet 3: "Tests: indented and list-marker fence lines inside fences, indented code showing an opener, both brief variants. 48/48; shellcheck and the hermeticity lint clean; all 102 real IDs read as before."

**Location:** `e2f2d54` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the e2f2d54 tree. It does not establish what the author's "real IDs" source was. I used d535260's questions files (102 IDs), and `/workspace` main (99) and 35987c1 (102) as cross-checks.

E5 on an e2f2d54 copy gave bats rc 0 with 48 `ok`, shellcheck rc 0, and lint rc 0 with "126 test file(s) checked, no unstubbed network spawns". `grep -c '^@test'` gives 48 at e2f2d54 and 47 at 38578a9. E2 gave `old=new identical` and `mid=new identical` for all three ID sets, with 0 bytes of stderr. At d535260 that is 3 done, 19 drop, 26 keep, 13 open and 41 unrecognized.

**Evidence:** `fc30/logs/probe5.log`, `fc30/logs/bats-e2f.log`, `fc30/logs/sc-e2f.log`, `fc30/logs/lint-e2f.log`, `fc30/logs/probe1.log`, `fc30/logs/ans-mid-d535260.log`

---

## Claim 19: f4d27d2 message, bullet 1: "--check-answer: a questions file that ends with a fence still open is a skip for every ID (\"a code fence ... is never closed\"). One stray fence line flips everything after it, and questions.sh archive can produce one by splitting an entry at a fenced heading"

**Location:** `f4d27d2` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Same as Claim 8. It does not establish anything about a balanced file with a parity error.

See Claim 8 (E3: archive split, then every ID is a skip).

**Evidence:** `scripts/dev-cycle.sh:427-443`, `fc30/logs/probe3.log`

---

## Claim 20: f4d27d2 message, bullet 2: "Inside a fence, only a \"### Q-NNN \" line ends the entry being read; a \"### \" shell comment in a pasted block no longer loses the answer."

**Location:** `f4d27d2` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Same as Claim 7.

E1 Q-035: `old unrecognized | e2f unrecognized | new done` (CM: done).

**Evidence:** `scripts/dev-cycle.sh:402`, `fc30/logs/probe2.log`

---

## Claim 21: f4d27d2 message, bullets 3–4: "Comment: the Status field is compared after trimming blanks. Tests: the open-fence case moved to its own assertion; a test title that no longer matched renamed. 48/48; shellcheck and the hermeticity lint clean; all 102 real IDs read as before."

**Location:** `f4d27d2` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the f4d27d2 tree. It does not establish anything about the real-ID source, as in Claim 18.

The comment change is Claim 9. The Q-21 case moved out of the first assertion into `:878-883`, and the `:779` title changed (diff). E2 gave bats 48 ok rc 0, shellcheck rc 0 with empty output, lint rc 0, and `old=new identical` on 102/99/102 IDs.

**Evidence:** `test/scripts/dev-cycle.bats:779`, `test/scripts/dev-cycle.bats:878-883`, `fc30/logs/bats.log`, `fc30/logs/sc.log`, `fc30/logs/lint.log`, `fc30/logs/probe1.log`

---

## Claim 22: "A brief the glob prints `ok` for, or this cycle wrote, whose path no In flight line names (compared as text) gets one, whatever its state, so In flight's checks reach it."

**Location:** `skills/dev-cycle/SKILL.md:93-95`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the rule's membership matching In flight's (`:269-271`), and a done or dropped brief that lost its line now reaching check 1. It does not establish anything about a line that names the brief in another spelling (for example `./docs/…`). "Compared as text" would add a duplicate, and nothing mechanical checks this.

The membership is "the glob prints `ok` for, or this cycle wrote" (`:93`), the same two sources as In flight (`:269`, Claim 23) and as the slot rule's "when the glob prints `ok` for it … or this cycle wrote it" (`:84-85`). "Whatever its state" closes pass 29's Claim 24 gap. Check 1 (`:273-282`) acts on `done` or `dropped` from `--check-brief`, so a glob-listed done brief without a line now gets one and is moved to Done and `closed/` in the same cycle. The glob lists only `briefs/*.md` (`:77-78`; `scripts/dev-cycle.sh:238-239`, "the open ones are all that the briefs/*.md glob lists once the move has landed"). A `closed/` brief therefore never gets a line from this rule, which is consistent with `:87-92`.

**Evidence:** `skills/dev-cycle/SKILL.md:77-95`, `skills/dev-cycle/SKILL.md:269-282`

---

## Claim 23: "**In flight**: items whose brief the Rules' glob prints `ok` for or this cycle wrote (whatever state `--check-brief` prints, so check 1 can close it)"

**Location:** `skills/dev-cycle/SKILL.md:269-271`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the wording now matching the Rules ("prints `ok`") and the line-adding rule. It does not establish how the glob itself behaves (out of scope).

The diff changes "the Rules' glob lists" to "the Rules' glob prints `ok` for". That is the phrasing at `:84-85` and `:93`, so the three membership statements now use the same words (pass 29 api F4).

**Evidence:** `skills/dev-cycle/SKILL.md:84-85`, `skills/dev-cycle/SKILL.md:93`, `skills/dev-cycle/SKILL.md:269-271`

---

## Claim 24: "each `closed/` brief that reads `open` or `new` (for the user to set its status)"

**Location:** `skills/dev-cycle/SKILL.md:371-372`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the final message now keeping the Rules' promise. It does not establish whether the record lists the same briefs, though the Rules say "is recorded" (`:91`).

The Rules say `a closed/ brief that reads open or new is recorded and listed in the final message for the user to set` (`:91-92`). Step 7's list now includes it (`:369-372`). That closes pass 29's Claim 23 and api F3.

**Evidence:** `skills/dev-cycle/SKILL.md:87-92`, `skills/dev-cycle/SKILL.md:369-375`

---

## Claim 25: a7dfc0c message: "Loop pass 29 (api Minor F3, F4): a brief the glob prints ok for, or this cycle wrote, gets an In flight line whatever its state, so a done or dropped brief that lost its line still reaches check 1; In flight says \"prints ok\" like the slot rule; the final message lists closed/ briefs that still read open or new."

**Location:** `a7dfc0c` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the three described edits and the finding references. It does not establish anything beyond Claims 22–24.

The api pass-29 review's table lists `| F3 | Final message omits closed/ open-or-new briefs … | Minor |` and `| F4 | In flight membership wider than the line-adding rule; "lists" vs "prints ok" | Minor |`. The three edits are the three diff hunks (Claims 22, 23, 24).

**Evidence:** `docs/reviews/api-consistency-review-2026-10-02-digest-pass29.md:141-142`, `skills/dev-cycle/SKILL.md:93-95`, `skills/dev-cycle/SKILL.md:269`, `skills/dev-cycle/SKILL.md:371-372`

---

## Claim 26: merge 35987c1 "Merge branch 'feat/dev-cycle-digest' into feat/dev-cycle"

**Location:** `35987c1` (merge commit)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the merge's parents and its blobs for the three reviewed files. It does not establish anything about the other merged files, which are review docs.

`git log -1 --format=%P 35987c1` gives `a7dfc0c… 0a56e33…`. `git rev-parse` gives these blobs at 35987c1: `scripts/dev-cycle.sh` a66b614 and `test/scripts/dev-cycle.bats` 7d54297, both equal to f4d27d2's, and `skills/dev-cycle/SKILL.md` 6b6010d, equal to a7dfc0c's. Run at 17:28Z, cwd `/workspace/.claude/wt-devcycle`, exit 0 for the parent and blob lookups (paraphrased — no quote available because the output was read inline rather than captured to a file; the command is repeatable and read-only).

**Evidence:** `35987c1`, `a7dfc0c`, `f4d27d2`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 6** (`scripts/dev-cycle.sh:356-359`): ANSWER_AWK's output list omits the new `unbalanced`, and "nothing when the file has no such entry" no longer holds for an unbalanced file. The next paragraph states the every-ID skip. Wording.

### Mostly Accurate
- **Claim 5** (`scripts/dev-cycle.sh:255`): "close to CommonMark". The closer bound `fcol + 3` lets a 4–6-space fence line close a fence opened with 1–3 spaces. CommonMark caps the closer at 3 spaces. `--check-brief` then gives a wrong `done` (E4 X1/X1b/X2: 366efd7 open, 38578a9/f4d27d2 done). `--check-answer` gives a fail-safe skip. **Behavioral**, Low: no real file, and it needs an indented opener plus an over-indented inner fence line before a quoted `Status: done`. Fix: bound the closer by the marker's content column plus 3 when the opener had a marker, else by 3. Pre-existing and lower-confidence: N9 and X6 read `keep` where my CommonMark reading gives a skip.
- **Claim 16** (e2f2d54 message): "regression fix" for "inside a column-0 fence". The pass-28 regression persists for 1–3-space openers (same root as Claim 5). **Behavioral**, Low.

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass30.md`. Its first line is `Commit: f4d27d2 (A) / a7dfc0c (B)` and it carries the Replication field. It follows the code-fact-check structure: header, per-claim seven fields plus Legibility-target, Claims Requiring Attention, and this note. It serves the user goal (merge after a clean k=1 pass) as follows:
- There are no Incorrect verdicts.
- Every pass-29 probe shape now gives the CommonMark reading, a skip or `unrecognized`, and never a wrong keep, drop or done. That covers api P1–P3, security N1–N4 and Q-013/014/017/031/032/035, fact-check Q-101–Q-114, and performance's 16 MiB-of-spaces line.
- The archive-split case is a skip for every ID.
- All real IDs read unchanged: 102, 99 and 102 IDs, old = e2f2d54 = f4d27d2.
- `match()`/`RLENGTH` works under mawk, and the help range is exact.
- The B fixes close pass 29's Claims 23/24 and api F3/F4.

One new behavioral residue remains: a 1–3-space-indented brief fence can still yield a wrong `done` (Claim 5/16, Low, no real file). There is also one stale comment list (Claim 6, wording).
