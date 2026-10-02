Commit: 38578a9 (A) / c345865 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at 38578a9; HEAD 47b63d4 adds only pass-28 review docs, and `git diff --stat 38578a9 HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at c345865). Merge 5a50016 has parents c345865 and 47b63d4, and its blobs of `scripts/dev-cycle.sh` (2b4c8e2), `test/scripts/dev-cycle.bats` (aa8fc81) and `skills/dev-cycle/SKILL.md` (6da1506) equal 38578a9's and c345865's.
**Scope:** Partial: the pass-28 fix round only. A: `git diff 366efd7..38578a9 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of 38578a9. B: `git diff b73069e..c345865 -- skills/dev-cycle/SKILL.md` plus the message of c345865 and merge 5a50016. Everything else is context only (rubric section "Pass 28").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 29
**Summary:** 20 verified, 8 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) before starting. One claim is a test and ID tally, the class of the logged "85 tests" and "mode1-equiv 33" patterns. It was recounted by execution and holds (Claim 17). No verdict is Incorrect, so nothing goes in the log. The brief allows no other write anyway.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc29/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Repos inside the temp dir got the same check after their `cd`. Probes took the code with `git archive <commit> | tar -x` into the temp dir and ran it there. Every process ran under `timeout` in the foreground, and all of them exited. The only commands run inside a worktree were read-only: `git show`, `git archive`, `git diff` and `git status`, plus bats, the hermeticity lint and shellcheck in wt-digest. All three ran before 17:16Z, and `git status --short` was empty both before and after them.

**Worktree change not made by me (reported first, per the probe rule).** At 17:19:48Z, `git status --short` in wt-digest showed ` M scripts/dev-cycle.sh`, with mtime 2026-10-02 17:19:44Z. The uncommitted diff rewrites FENCE_AWK into `spaces()`/`opens()` with `fcol` and an "at most 3 spaces" rule. It looks like someone has started fixing this pass's fence findings. My probes did not write it: each one wrote only under `fc29/tmp.*`, and the tree was clean after my last in-worktree command (shellcheck, about 17:15Z). It also holds an untracked `api-consistency-review-2026-10-02-digest-pass29.md` from another critic. I did not touch either file. By 17:23:35Z another actor had committed it as e2f2d54 ("fix(dev-cycle): pass-29 fence closers bounded by the opener (regression fix)"), on top of 47b63d4. e2f2d54 is outside this pass's fixed HEADs and was not reviewed here. Every verdict below is on the committed 38578a9, and every probe ran a `git archive 38578a9` copy. `/workspace` was still on `main`, and wt-devcycle's `git status --short` was empty.

Scratch logs (not committed) are in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc29/`, called `fc29/` below. `old` is 366efd7 and `new` is 38578a9. The system awk is mawk 1.3.4 (`/usr/bin/awk -> /etc/alternatives/awk -> /usr/bin/mawk`), so every awk result is mawk's. Setlocale warnings in the logs come from the environment's uninstalled `en_US.UTF-8`.

Executed runs (UTC, 2026-10-02, all exit 0):
- **E1**, 17:14:59Z, cwd `/workspace/.claude/wt-digest` (tree clean, equal to 38578a9): `timeout 600 bats test/scripts/dev-cycle.bats` → `fc29/logs/bats.log` (47 ok). `timeout 120 python3 scripts/hermeticity-lint --root .` → `fc29/logs/lint.log` ("126 test file(s) checked, no unstubbed network spawns"). `timeout 60 shellcheck scripts/dev-cycle.sh` → `fc29/logs/sc.log` (empty, exit 0).
- **E2**, 17:16:00Z, cwd `fc29/`: `timeout 300 bash fc29/probe1.sh` → `logs/probe1.log`. Lint, shellcheck and `--help` on the archive copy. `--check-answer` on every real ID, old against new, for d535260's questions files (102 IDs) and `/workspace` main's (99 IDs).
- **E3**, 17:16:11Z and 17:16:12Z: `probe2.sh` and `probe2b.sh` → `logs/probe2.log` and `logs/probe2b.log`. These rerun pass 28's security probe inputs (F1–F4 and the pass-27 shapes), old against new.
- **E4**, 17:17:12Z: `probe3.sh` → `logs/probe3.log`. FENCE_AWK fence state over the real questions files at d535260, c345865, 38578a9 and `main`, plus a mawk `split` on `" · "` under `LC_ALL=C`.
- **E5**, 17:17:31Z: `probe4.sh` → `logs/probe4.log`. Isolated `--check-answer` shapes Q-101 to Q-114, one temp repo each.
- **E6**, 17:18:13Z: `probe5.sh` → `logs/probe5.log`. The `--check-brief` commit through a `--no-ff` merge, a squash, a fast-forward of a branch that had merged main in, a simple fast-forward, a move into `closed/`, a later fenced `Status:` quote and an indented one.
- **E7**, 17:19:28Z: `probe6.sh` → `logs/probe6.log`. `questions.sh init` and `archive` on an ANSWERED entry that quotes a `### Q-` heading inside a fence, with `--check-answer` before and after.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the person reading `--help` or the final message.

---

## Claim 1: "the commit in its first-parent history that last added or removed a "Status: " line there (a merge commit, the branch's own commit after a fast-forward, or a later move or quoted Status line)"

**Location:** `scripts/dev-cycle.sh:33-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers which commit `--check-brief` prints for a `--no-ff` merge, a simple fast-forward, a squash, a move into `closed/`, and a later column-0 quoted line. It does not establish which commit is printed when a fast-forwarded branch had merged main in. That case prints the branch's merge-of-main commit, which is a merge commit, though not the commit that set the status.

The code is `c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"` (`scripts/dev-cycle.sh:307`), with a fallback to the last commit touching the file (`:308`). E6 printed `done 11e973d` for the `--no-ff` merge. For a simple fast-forward it printed `done 2927844`, the branch commit that set done, and not the later `Asked:` edit b5008e8. For the move into `closed/` it printed `done c5214f8`, the move commit. After a later fenced column-0 `Status: open` quote it printed `done 6837cea`, the quote commit. An indented `  Status: x` line added later did not change the commit (still 6837cea). When the fast-forwarded branch had merged main in, it printed `001ff9c`, the "merge main into ff" commit.

**Evidence:** `scripts/dev-cycle.sh:33-36`, `scripts/dev-cycle.sh:307-308`, `fc29/logs/probe5.log`

---

## Claim 2: "unrecognized (answered, but the first answer line's text does not start with one of the options)"

**Location:** `scripts/dev-cycle.sh:51-53`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the cases in which an answered entry prints `unrecognized`. It does not establish anything about the skill's handling of `unrecognized`.

The help names one cause. The code has a second one: an answered entry with no readable answer line also prints `unrecognized`: `else if (count) print (!answered ? "open" : done ? result : "unrecognized")` (`scripts/dev-cycle.sh:425`). That happens when no answer line was written, or when the only one is hidden by a fence or sits after a fenced `### ` line. In E5, Q-109 ("answered, no answer line") and Q-111 ("answer hidden by open fence") both printed `unrecognized`. The bats case Q-21 (`test/scripts/dev-cycle.bats:867`) expects the same. The previous help covered this case ("no answer line starts with one of the options, or a fence in the entry is left open"). The new wording dropped it. A precise version: "unrecognized (answered, but no answer line is found, or the first one's text does not start with one of the options)". Wording only.

**Evidence:** `scripts/dev-cycle.sh:51-53`, `scripts/dev-cycle.sh:422-426`, `fc29/logs/probe4.log`

---

## Claim 3: "skip Q-NNN: <reason> when it cannot be read (no such entry, a duplicate heading, a heading only inside a code fence, a questions file that is not plain)"

**Location:** `scripts/dev-cycle.sh:53-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the four named skip causes, including the new fenced-heading one. It does not establish that the parenthetical is exhaustive. It omits "an entry in both files" and "not a question ID" (`:437`, `:429`), both pre-existing and outside this diff.

`if [[ "$r" == fenced ]]; then echo "skip $a: its heading appears only inside a code fence in $f"; return; fi` (`scripts/dev-cycle.sh:436`). E3 printed that line for Q-018 and Q-023 (forged copies). The bats case at `test/scripts/dev-cycle.bats:646` expects it for Q-7.

**Evidence:** `scripts/dev-cycle.sh:430-441`, `fc29/logs/probe2.log`, `fc29/logs/probe2b.log`, `fc29/logs/bats.log`

---

## Claim 4: `-h|--help) sed -n '2,66p'` (the help prints the whole header)

**Location:** `scripts/dev-cycle.sh:130`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the help range against the header's length at 38578a9. It does not establish that the range stays correct after later header edits.

E2's `--help` printed 65 lines. The last is "default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data." That is header line 66, and line 67 is blank (`sed -n 60,70p | cat -A`).

**Evidence:** `scripts/dev-cycle.sh:2-66`, `scripts/dev-cycle.sh:130`, `fc29/logs/probe1.log`

---

## Claim 5: "a line of 3 or more ` or ~ opens one (after any indentation and an optional list marker such as "- " or "1. "; a ` fence's info string holds no `)"

**Location:** `scripts/dev-cycle.sh:254-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the opener rule as coded. It does not establish agreement with CommonMark (see Claim 6), or that markers other than `-*+` and `N.`/`N)` are handled.

```awk
# scripts/dev-cycle.sh:260-264
function lead(l) {
  sub(/^[ \t]+/, "", l)
  if (l ~ /^[-*+][ \t]/ || l ~ /^[0123456789]+[.)][ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l) }
  return l
}
```

In E5, Q-114 (`1. ```` opener) read `keep`, and Q-103 (a 4-space-indented ```` ``` ````) was treated as a fence. In E3, Q-024 (`- ```bash`) read `keep` and Q-011 (backtick in the info string) was not a fence.

**Evidence:** `scripts/dev-cycle.sh:254-271`, `fc29/logs/probe4.log`, `fc29/logs/probe2b.log`

---

## Claim 6: "Code fences, close to CommonMark: … and only a line of the same character, at least as long and followed by nothing but spaces or tabs, closes it."

**Location:** `scripts/dev-cycle.sh:254-257`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the closer rule and where it departs from CommonMark. It does not establish that any real questions file contains the departing shapes (E4: none do).

Closers also go through `lead()`, so any indentation and a list marker are stripped before a closer as well: `function closes(l,   s, n) { s = lead(l); n = run(s, fch) … }` (`scripts/dev-cycle.sh:273-276`). The parenthetical sits on the opener only, so read literally, a `- ```` line is not "a line of the same character", yet it closes a fence. Code-wise the mechanism is otherwise as stated.

**Behavioral consequence (answers brief item 1).** "Any indentation" also makes a line indented 4 or more spaces, and a list-marker line, act as an opener or closer where CommonMark treats it as content. In E5, three isolated shapes give a wrong keep or drop rather than a skip or `unrecognized`:

| Shape (one entry, ANSWERED) | 366efd7 | 38578a9 | CommonMark |
|---|---|---|---|
| Q-101: ```` ``` ```` / `    ```` / `**Answer:** [2] drop` / ```` ``` ```` / `**Answer:** [1] keep` | keep | **drop** | keep (the 4-space line is fence content; it cannot close) |
| Q-102: ```` ```markdown ```` / `- ```` / `[2] drop` / ```` ``` ```` / `[1] keep` | keep | **drop** | keep |
| Q-105: ```` ``` ```` / `[2] drop` / `    ```` / `[1] keep` (fence never closed in CommonMark) | unrecognized | **keep** | no answer: unrecognized |

The same rule only hides answers in Q-103 (4-space indented code around the answer → `unrecognized`, where CommonMark reads keep) and in pass 28's probe2 Q-013 and Q-014 (both `unrecognized`, CommonMark keep). Those fail toward asking again. A precise version of the comment: "… and a line of the same character, at least as long, after any indentation and an optional list marker, and followed by nothing but spaces or tabs, closes it. Unlike CommonMark, a line indented 4 or more spaces, or inside a fence behind a list marker, still opens or closes." Graded Mostly accurate rather than Incorrect because "close to CommonMark" is hedged and the parenthetical plausibly carries over to closers. The wrong keep/drop is a behavioral finding for the sibling critics, not a comment mismatch.

**Evidence:** `scripts/dev-cycle.sh:254-276`, `fc29/logs/probe4.log`, `fc29/logs/probe2.log`

---

## Claim 7: "a merge commit for merged work, the branch's own commit after a fast-forward; never a later Asked:/Kept: edit. Any such line counts (a quoted one, or a move into closed/, which adds the file whole)."

**Location:** `scripts/dev-cycle.sh:302-306`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the same cases as Claim 1, plus "never an Asked: edit" and "a move adds the file whole". It does not establish behavior for a status line with CR endings in the `-G` match, or for history rewritten after landing.

`-G'^Status: '` matches added or removed lines only (`:307`). E6: the simple fast-forward printed sfdone (2927844), not the later `Asked:` edit. The move into `closed/` printed the move commit c5214f8. A fenced column-0 quote printed its own commit (6837cea). An indented quote did not count.

**Evidence:** `scripts/dev-cycle.sh:302-308`, `fc29/logs/probe5.log`

---

## Claim 8: "Prints keep, drop, done, open, unrecognized, dup (the heading appears more than once, counting copies inside code fences), fenced (it appears only inside a fence), or nothing when the file has no such entry."

**Location:** `scripts/dev-cycle.sh:352-355`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the END block's outputs. It does not establish how `check_answer` combines the two files (Claim 3 covers its messages).

```awk
# scripts/dev-cycle.sh:422-426
END {
  if (count + quoted > 1) print "dup"
  else if (quoted) print "fenced"
  else if (count) print (!answered ? "open" : done ? result : "unrecognized")
}
```

`quoted` counts target headings seen while `infence` (`:397`). In E3, probe2's Q-001 (quoted in Q-008's fence and real) printed the dup skip, and Q-018 printed the fenced skip. The bats case at `:818-820` expects the dup skip for Q-11.

**Evidence:** `scripts/dev-cycle.sh:352-355`, `scripts/dev-cycle.sh:396-426`, `fc29/logs/probe2.log`, `fc29/logs/bats.log`

---

## Claim 9: "Fences are tracked across the whole file (FENCE_AWK): a heading inside one is a quote, never the entry (though a "### " line there still ends the entry being read), and no fenced line is read."

**Location:** `scripts/dev-cycle.sh:356-358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the rule order at `:396-401` under the reader's own fence notion. It does not establish CommonMark agreement on which lines are fenced (Claim 6).

`infence { if (heading($0)) quoted++; if ($0 ~ /^### /) inside = 0; if (closes($0)) infence = 0; next }` comes before `opens($0)`, `heading($0)` and every reading rule (`scripts/dev-cycle.sh:397-401`), and those rules run for every line of the file. E5: Q-112 (a fenced `### other`, then `[2]` after the fence) read `unrecognized`, so the entry ended. Q-113 (a fenced `## Sub`) read `drop`, so a fenced `## ` line does not end the entry, which matches CommonMark.

**Evidence:** `scripts/dev-cycle.sh:356-358`, `scripts/dev-cycle.sh:396-401`, `fc29/logs/probe4.log`

---

## Claim 10: "A fence left open hides the rest of the file, which can only make an answer unreadable (skip or unrecognized), never read one from elsewhere."

**Location:** `scripts/dev-cycle.sh:358-360`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers fences that the reader itself leaves open. It does not establish that the reader's notion of "open" matches CommonMark: Q-105 (Claim 6) is a fence CommonMark leaves open that the reader closes, after which a fenced answer is read.

While `infence`, the only effects are `quoted++` and `inside = 0` (`:397`), so no result can be set. In E3 (probe2), Q-014's stray opener swallowed the rest of the file. Q-015 and Q-017 printed the fenced skip and Q-016 printed `unrecognized`. None printed a keep or drop taken from elsewhere. In E5, Q-111 printed `unrecognized`.

**Evidence:** `scripts/dev-cycle.sh:358-360`, `scripts/dev-cycle.sh:397`, `fc29/logs/probe2.log`, `fc29/logs/probe4.log`

---

## Claim 11: "has a " · "-separated field that is exactly "**Status:** ANSWERED" (the last Status field counts, as in questions.sh)"

**Location:** `scripts/dev-cycle.sh:361-364`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the gate's field split, last-field-wins rule and comparison under mawk with `LC_ALL=C`. It does not establish agreement with questions.sh on headers inside fences, which questions.sh does not track.

```awk
# scripts/dev-cycle.sh:403-405 (excerpt ends :405; the enclosing rule closes with `next` at :406 — read)
  header = 1; v = ""; n = split($0, fld, " · ")
  for (i = 1; i <= n; i++) { f = fld[i]; sub(/^[ \t]+/, "", f); if (substr(f, 1, 12) == "**Status:** ") v = substr(f, 13) }
  sub(/[ \t]+$/, "", v); answered = (v == "ANSWERED")
```

Last-wins and "(by user)" behave as stated. In E5, Q-108 (`ANSWERED · OPEN`) read `open` and Q-110 (`OPEN · ANSWERED`) read `drop`. In E3, Q-007 (`ANSWERED (2026-10-02)`) and Q-006 (a quoted status inside another field) read `open`. E4 shows mawk's `split` on `" · "` under `LC_ALL=C` giving three clean fields. The departure from "exactly": the code trims blanks around the field. In E5, Q-106 (`**Status:** ANSWERED<TAB>`) read `drop`. questions.sh compares the untrimmed value exactly: `status = substr(f[i], 9)` (`scripts/questions.sh:179`), then `[[ "$status" == "ANSWERED" ]] || continue` (`scripts/questions.sh:379`). So questions.sh would not archive that entry, and its `check` flags it (`:269`). A precise version: "… a field that is "**Status:** ANSWERED", ignoring surrounding blanks (the last Status field counts, as in questions.sh)". Wording only. The trim fails toward reading an answer the header nearly states.

**Evidence:** `scripts/dev-cycle.sh:361-364`, `scripts/dev-cycle.sh:402-406`, `scripts/questions.sh:170-181`, `scripts/questions.sh:269`, `scripts/questions.sh:379`, `fc29/logs/probe4.log`, `fc29/logs/probe2.log`, `fc29/logs/probe3.log`

---

## Claim 12: "The answer is the first line in the entry, outside fences, that starts, after an optional "- ", with "Q-NNN:" or a bold "**Answer:", "**Answer (" or "**Answered" label (any case)"

**Location:** `scripts/dev-cycle.sh:365-367`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the first-line rule after the rewording. It does not re-verify the label-text parsing at `:410-420`, which is unchanged from pass 28.

The `!done` rule sets `done = 1` on the first matching line (`scripts/dev-cycle.sh:407-421`), and fenced lines never reach it (`:397`). The bats case Q-20 (`test/scripts/dev-cycle.bats:864`: "maybe later" then `[1]`) expects `unrecognized`. In E3, Q-019 and Q-020 read the first unfenced line (`keep`).

**Evidence:** `scripts/dev-cycle.sh:365-367`, `scripts/dev-cycle.sh:407-421`, `fc29/logs/bats.log`, `fc29/logs/probe2.log`

---

## Claim 13: "skip $a: more than one entry with this heading in $f (counting copies inside code fences)"

**Location:** `scripts/dev-cycle.sh:435`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the dup message's parenthetical. It does not establish whether a legitimate quoted heading should block the real entry; that is a design choice, not a claim.

`count + quoted > 1` (`:423`) counts fenced copies. E3's probe2 Q-001 printed this message.

**Evidence:** `scripts/dev-cycle.sh:423`, `scripts/dev-cycle.sh:435`, `fc29/logs/probe2.log`

---

## Claim 14: "an unclosed fence stays inside its entry; fences close only with their own kind; the gate is anchored"

**Location:** `test/scripts/dev-cycle.bats:779`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the test title's first clause against 38578a9's reader. It does not establish anything wrong with the test's assertions, which pass (`unrecognized Q-1`, `keep Q-3`, `open Q-4`).

The title was true under the per-entry tracking at 366efd7. 38578a9 now says the opposite: "A fence left open hides the rest of the file" (`scripts/dev-cycle.sh:358-359`). This round reordered the test body so that Q-1's unclosed fence comes last-but-one: `printf '### Q-1 · keep-or-drop-x-1\n**Needs:** you: judgment · **Status:** ANSWERED\n\n%s\nno close\n\n' "$f"` (`:785`), then Q-2 (`:786`). In the new reader, Q-1's fence runs on into Q-2 and is closed by Q-2's own ```` ``` ```` line. It does not stay inside Q-1. Q-2 is not queried, so no assertion catches it. A precise title: "an unclosed fence hides the rest of the file; …". Wording only.

**Evidence:** `test/scripts/dev-cycle.bats:779-792`, `scripts/dev-cycle.sh:356-360`, `scripts/dev-cycle.sh:397`

---

## Claim 15: "# its answer line is above the fence"

**Location:** `test/scripts/dev-cycle.bats:820`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers why Q-10 reads `keep`. It does not establish anything about the dup assertion on Q-11.

Q-10's body is `**Answer:** [1]\n\nOriginal:\n%s\n` (`:813`), so the answer comes before the unclosed fence. bats test 45 passed (E1).

**Evidence:** `test/scripts/dev-cycle.bats:809-821`, `fc29/logs/bats.log`

---

## Claim 16: "fences are tracked across the file: forged copies, list-item fences, sections after an open fence"

**Location:** `test/scripts/dev-cycle.bats:857`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers that the test exercises the three named shapes and passes. It does not establish coverage of list-marker or 4-space lines inside a fence (Claim 6), which no test exercises.

The test asserts `skip Q-18: its heading appears only inside a code fence`, `keep Q-15` (a `- ```` item fence) and `unrecognized Q-21` (a `## Archive` after an open fence) (`:872-874`). E1: `ok 47`.

**Evidence:** `test/scripts/dev-cycle.bats:857-878`, `fc29/logs/bats.log`

---

## Claim 17: "Tests: … 47/47; shellcheck and the hermeticity lint clean; all 102 real IDs read as before."

**Location:** commit 38578a9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the suite, the lints and the real files at d535260 (102 IDs) and `/workspace` main (99 IDs) under mawk. It does not establish behavior under gawk or busybox awk, which are not installed.

E1: 47 ok, the lint was clean, shellcheck exited 0. E2: `== d535260: 102 IDs` `identical` and `== main: 99 IDs` `identical` (old vs new `diff` empty). Tallies at d535260: 3 done, 19 drop, 26 keep, 13 open, 41 unrecognized.

**Evidence:** `fc29/logs/bats.log`, `fc29/logs/lint.log`, `fc29/logs/sc.log`, `fc29/logs/probe1.log`

---

## Claim 18: "A fence left open hides the rest of the file, so it can only make an answer unreadable, never read one from another entry or past a section."

**Location:** commit 38578a9 message
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Same as Claim 10, plus "past a section": the bats Q-21 shape (`## Archive` after an open fence) reads `unrecognized`. It does not establish the claim for fences CommonMark leaves open but the reader closes (Q-105).

See Claim 10. The bats case at `test/scripts/dev-cycle.bats:867` and E5 Q-111 both read `unrecognized`.

**Evidence:** `scripts/dev-cycle.sh:397`, `test/scripts/dev-cycle.bats:867-874`, `fc29/logs/probe4.log`

---

## Claim 19: "The fence reader allows any indentation and a list marker before an opener ("- ```"), so a list-item fence no longer inverts what follows."

**Location:** commit 38578a9 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers list-item fences as openers (pass-28 F2, now fixed) and the same allowance applied to closers. It does not establish anything about real files, which hold no such lines (E4).

The opener half holds. probe2b Q-024 changed from `unrecognized` to `keep`, and the bats Q-15 case reads `keep`. But the allowance is in `lead()`, which closers share (`:273-276`). So a `- ```` or a 4-space ```` ``` ```` line inside a fence now closes that fence and inverts what follows: E5 Q-102 reads `drop` and Q-101 reads `drop`, where CommonMark reads keep for both. A precise version: "… before an opener or a closer, so a list-item fence no longer inverts what follows. A list-marker or indented fence line inside another fence now does." Behavioral; the details are in Claim 6.

**Evidence:** `scripts/dev-cycle.sh:260-276`, `fc29/logs/probe2b.log`, `fc29/logs/probe4.log`

---

## Claim 20: "The ANSWERED gate reads the header's " · "-separated fields and takes the last one that starts "**Status:** ", which must be exactly ANSWERED, as questions.sh does: "ANSWERED (by user)" and a quoted status inside another field read open."

**Location:** commit 38578a9 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Same as Claim 11.

Everything holds except "exactly … as questions.sh does". dev-cycle trims surrounding blanks (`:404-405`) and questions.sh does not (`scripts/questions.sh:179`, `:379`). E5 Q-106 shows the difference. The two examples hold: E3 Q-007 and Q-006 read `open`. Wording only.

**Evidence:** `scripts/dev-cycle.sh:402-406`, `scripts/questions.sh:179`, `scripts/questions.sh:379`, `fc29/logs/probe4.log`, `fc29/logs/probe2.log`

---

## Claim 21: "the trade is that an unbalanced fence anywhere makes later entries unreadable (a skip), which fails toward asking again"

**Location:** commit 38578a9 message (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers dev-cycle's reading of a file with an unbalanced fence, and whether real files or questions.sh produce one (brief item 1). It does not establish what other consumers of questions.md do with such a file.

When a fence opens before a later entry's heading, that heading is `quoted` and the entry prints the fenced skip. An entry whose heading is unfenced but whose answer is hidden prints `unrecognized` (E3 Q-015/Q-016/Q-017). Both fail toward asking.

Brief item 1, real files (E4): at d535260, c345865, 38578a9 and `main`, both questions files end with no fence open. They have 0 headings inside a fence, 0 lines indented 4+ before a fence and 0 list-marker fence lines (`questions.md` 1 opener, the archive 9).

Brief item 1, questions.sh (E7): questions.sh writes no fence itself (no ```` ``` ```` or `~~~` in `scripts/questions.sh`). But its own layout can produce an unbalanced fence. `live_without_entry` and `extract_entry` split entries at every `^### Q-[0-9]+ ` line, fenced or not (`scripts/questions.sh:359-369`). E7 ran `archive` on an ANSWERED entry Q-001 that quotes `### Q-000 · old` inside a ```` ```markdown ```` fence. The archive received Q-001 cut off after ```` ```markdown ````, an unclosed fence that hides every entry archived after it. The live file kept the quote's tail, whose ```` ``` ```` now opens a fence. So Q-002 went from `open` to the fenced skip, and the quoted `### Q-000` became a real entry (`open Q-000`). Every result stayed a skip, `open` or `unrecognized`, so the claim holds. The forged-heading promotion is questions.sh behavior, routed to the sibling critics. Even before archiving, Q-001 read `unrecognized`, because the fenced `### ` line ends the entry (as Claim 9 documents).

**Evidence:** `scripts/dev-cycle.sh:397-399`, `scripts/questions.sh:355-391`, `fc29/logs/probe3.log`, `fc29/logs/probe6.log`, `fc29/logs/probe2.log`

---

## Claim 22: "the commit in the default branch's first-parent history that last added or removed a `Status:` line there: a merge commit for merged work, the branch's own commit after a fast-forward, or a later move or quoted Status line"

**Location:** `skills/dev-cycle/SKILL.md:81-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Same as Claim 1. It does not establish the fast-forward-after-merging-main case, where the printed merge commit is not the commit that set the status.

The skill text matches the help (Claim 1) and the code (`scripts/dev-cycle.sh:307`). E6 shows all four cases.

**Evidence:** `skills/dev-cycle/SKILL.md:79-84`, `scripts/dev-cycle.sh:307`, `fc29/logs/probe5.log`

---

## Claim 23: "a `closed/` brief that reads `open` or `new` is recorded and listed in the final message for the user to set, and gets no keep-or-drop question"

**Location:** `skills/dev-cycle/SKILL.md:91-92`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with In flight's checks and with the final-message step. It does not establish what check 2 should do with existing `Asked:` IDs on such a brief. Check 2 still applies them, which is consistent with "no question" filed.

The "no keep-or-drop question" half matches check 3: "if the brief is still open and under `briefs/`" (`skills/dev-cycle/SKILL.md:300`). The "listed in the final message" half has no counterpart in the step that writes that message. That step lists new `you: judgment` entries, keep-or-drop answers that were unreadable, `unrecognized` or still `open`, and "each brief holding a slot by path" (`skills/dev-cycle/SKILL.md:369-372`). A `closed/` brief holds no slot (`:86`), so an agent following step 7 alone would leave it out. Precise fix: add "and any `closed/` brief that reads `open` or `new`" to the final-message list. Wording, a cross-section gap.

**Evidence:** `skills/dev-cycle/SKILL.md:84-92`, `skills/dev-cycle/SKILL.md:300`, `skills/dev-cycle/SKILL.md:369-374`

---

## Claim 24: "In flight: items whose brief the Rules' glob lists or this cycle wrote (whatever state `--check-brief` prints, so check 1 can close it)"

**Location:** `skills/dev-cycle/SKILL.md:269-272`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers In flight membership against the slot rule (`:84-87`) and the line-adding rule (`:93-95`). It does not establish how often a done or dropped brief sits in `briefs/` without an In flight line. Normally the writing cycle adds the line (`:336`).

Against the slot rule, the membership holds. In flight is a superset of the slot holders: glob-`ok` or written this cycle, minus `closed/` and done/dropped (`:84-86`). It adds exactly the done and dropped briefs, which check 1 needs to see. But the only rule that creates an In flight line is narrower: "A brief that holds a slot but whose path no In flight line names … gets one, so In flight's checks reach it" (`:93-95`). A done or dropped brief still in `briefs/` with no line, written by hand or after its line was edited away, is a member by the In flight definition. Yet no rule gives it a line, and check 1 iterates lines. An agent reading `:93-95` would leave it in `briefs/` indefinitely. It holds no slot, so the cost is a brief never moved to `closed/`. A precise version of `:93`: "A brief the glob lists or this cycle wrote whose path no In flight line names gets one". Medium confidence, because an agent may read `:269` itself as the instruction to add the line. Behavioral (agent procedure), low impact.

**Evidence:** `skills/dev-cycle/SKILL.md:84-95`, `skills/dev-cycle/SKILL.md:269-283`, `skills/dev-cycle/SKILL.md:336`

---

## Claim 25: "→ Done, naming the commit it prints (as the Rules describe it)"

**Location:** `skills/dev-cycle/SKILL.md:274-275`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the Rules carry the one description of the commit, and that Done points to it. It does not establish anything beyond Claim 22.

The Rules describe the commit at `:81-83`. The Done list says "each with the commit `--check-brief`" / "printed (or the user's done answer)" (`skills/dev-cycle/SKILL.md:317-318`). No second description of the commit remains in the skill (paraphrased — no quote available because this is an absence claim: a grep for "for merged work" finds only `:82`).

**Evidence:** `skills/dev-cycle/SKILL.md:81-83`, `skills/dev-cycle/SKILL.md:274-275`, `skills/dev-cycle/SKILL.md:317-318`

---

## Claim 26: "Then, if the brief is still open and under `briefs/`, no ID on its `Asked:` line is still `open` or skipped, …"

**Location:** `skills/dev-cycle/SKILL.md:300-301`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers consistency with the Rules' `closed/` sentence (`:91-92`) and the slot rule. It does not establish what happens to a `closed/` brief whose user never sets it. It stays listed every cycle.

Check 3 now excludes `closed/` briefs, as `:91-92` says, and a `closed/` brief holds no slot (`:86`), so "Until it is answered, the brief still holds its slot" (`:307-308`) never applies to one.

**Evidence:** `skills/dev-cycle/SKILL.md:86`, `skills/dev-cycle/SKILL.md:91-92`, `skills/dev-cycle/SKILL.md:300-312`

---

## Claim 27: "A tip date more than two days after today is recorded and counts as idle (the committer sets the date; two days cover every time-zone pair)."

**Location:** `skills/dev-cycle/SKILL.md:310-312`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the arithmetic for civil offsets UTC−12:00 to UTC+14:00 (a 26-hour span: at one instant, the two local dates differ by at most 2), and that the date compared is the committer's own. It does not establish clock skew or a falsified committer date, which is the point of "recorded".

`--check-branch` prints `$(git log -1 --format=%cs "$sha")`, the committer's own zone (`scripts/dev-cycle.sh:328`). At 23:00 on day D in UTC−12, it is 01:00 on D+2 in UTC+14, so a legitimate tip can be dated today+2. "More than two days" therefore never flags one. 14 − (−12) = 26 hours, as the c345865 message says ("time zones span 26 hours"). The zone range is general knowledge, not checked against a tz database in this sandbox.

**Evidence:** `skills/dev-cycle/SKILL.md:306-312`, `scripts/dev-cycle.sh:328`

---

## Claim 28: "In flight holds every brief the glob lists or this cycle wrote, whatever its state, so check 1 can close a done or dropped one (the slot rule had excluded exactly those). A closed/ brief that reads open or new is recorded and listed for the user to set; it gets no keep-or-drop question (check 3 runs only for briefs under briefs/). The printed commit is described once, in the Rules …; Done refers to it. A tip date counts as future-idle only beyond two days (time zones span 26 hours)."

**Location:** commit c345865 message
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the message's four bullets against the c345865 text. It does not repeat the residue of Claims 23 and 24.

Bullets 2 to 4 hold (Claims 25 to 27; the final-message gap is Claim 23). Bullet 1 holds for In flight's definition. But the line-adding rule (`skills/dev-cycle/SKILL.md:93-95`) was not widened to match, so check 1 reaches a done or dropped brief only when it already has a line (Claim 24). Behavioral (agent procedure), low impact.

**Evidence:** `skills/dev-cycle/SKILL.md:84-95`, `skills/dev-cycle/SKILL.md:269-272`, `skills/dev-cycle/SKILL.md:300`, `skills/dev-cycle/SKILL.md:369-372`

---

## Claim 29: "Merge branch 'feat/dev-cycle-digest' into feat/dev-cycle" carries 38578a9's script and tests and c345865's skill unchanged

**Location:** merge 5a50016
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers blob identity of the three files in scope. It does not establish anything about other files the merge carries (the pass-28 review docs).

`git log -1 --format='%H %P' 5a50016` gives parents c3458654… and 47b63d45…. `git rev-parse` gave equal blobs: `scripts/dev-cycle.sh` 2b4c8e2 = 2b4c8e2, `test/scripts/dev-cycle.bats` aa8fc81 = aa8fc81, `skills/dev-cycle/SKILL.md` 6da1506 = 6da1506. Run in cwd `/workspace/.claude/wt-devcycle` at 17:19:48Z, exit 0, output inline in this session (read-only `git rev-parse`; no log file).

**Evidence:** merge 5a50016 (`git rev-parse 5a50016:<path>` vs `38578a9:<path>` / `c345865:<path>`)

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 14** (`test/scripts/dev-cycle.bats:779`): the test title "an unclosed fence stays inside its entry" predates whole-file tracking. Now an unclosed fence runs on to the next matching line or EOF. Retitle it. Wording.

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:51-53`): help `unrecognized` omits "answered, but no answer line is found" (no line written, or hidden by a fence). Wording.
- **Claim 6** (`scripts/dev-cycle.sh:254-257`): closers also pass through `lead()`. **Behavioral:** a 4-space or list-marker fence line inside a fence opens or closes it, giving a wrong `drop` (Q-101, Q-102) or `keep` (Q-105) versus CommonMark. No real file has such a line.
- **Claim 11** (`scripts/dev-cycle.sh:361-364`): "exactly" ANSWERED, "as in questions.sh", but the code trims blanks around the field and questions.sh does not (Q-106). Wording.
- **Claim 19** (38578a9 message): the list-marker allowance applies to closers too, so a list-item line inside a fence still inverts what follows. Behavioral, same root as Claim 6.
- **Claim 20** (38578a9 message): "exactly … as questions.sh does". The trim differs (same as Claim 11). Wording.
- **Claim 23** (`skills/dev-cycle/SKILL.md:91-92`): "listed in the final message", but step 7's final-message list omits `closed/` briefs reading open or new. Wording, a cross-section gap.
- **Claim 24** (`skills/dev-cycle/SKILL.md:269-272`): In flight now includes done and dropped briefs, but the line-adding rule (`:93-95`) still adds lines only for slot holders, so an unlined done or dropped brief is never closed. Behavioral (agent procedure), low impact.
- **Claim 28** (c345865 message): bullet 1, same as Claim 24.

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion, restated verbatim from the brief: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass29.md` with the required first line and Replication field. It follows the code-fact-check structure: header, per-claim seven fields plus Legibility-target, and Claims Requiring Attention. It serves the user goal (merge after a clean k=1 pass) as follows. There are no Incorrect verdicts. The pass-28 probes all now read as CommonMark does, or as a skip or `unrecognized`. Three new fence shapes (Claim 6: Q-101, Q-102, Q-105) still give a wrong keep or drop. They need a list-marker or 4+-space fence line inside a fence, and no real questions file has one. questions.sh's `archive` can itself produce an unbalanced fence (Claim 21), which dev-cycle reads as a skip. The remaining items are wording, plus one low-impact skill rule gap (Claim 24). An uncommitted edit to wt-digest's `scripts/dev-cycle.sh` appeared at 17:19:44Z from another actor. I did not touch it.
