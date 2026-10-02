Commit: 10c2809 (A) / 875b41f (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at 10c2809; HEAD 18cb059 adds only review docs under `docs/reviews/`). B: `/workspace/.claude/wt-devcycle` (content at 875b41f; HEAD bf5dfac merges A in; `skills/dev-cycle/SKILL.md` is identical at 875b41f and bf5dfac, `git diff 875b41f bf5dfac -- skills/dev-cycle/SKILL.md` is empty).
**Scope:** Partial: the pass-25 fix round only. A: `git diff cbfdf35..10c2809 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of 10c2809. B: `git diff 77e21af..875b41f -- skills/dev-cycle/SKILL.md` plus the message of 875b41f. Everything else is context only (rubric section "Pass 25").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 30
**Summary:** 24 verified, 5 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) before starting. No claim below matches a logged pattern. The one Incorrect verdict is not a fabricated symbol, API or flag, so nothing is appended to the log. The brief allows no other write anyway.

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p fc26/` dir in that same script, and checked `case "$PWD"` before any `git init`, commit, write or `rm`. The probes took the code under review with `git archive` or `git show <commit>:<path>` into the temp dir and ran it there. Every process ran under `timeout`. None of mine was still running at the end. `pgrep` shows bats runs in `wt-devcycle`, but those belong to another session's suite and were left alone. My probes wrote nothing to either worktree. At the end, `git status --short` in `wt-digest` also showed `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats` modified (mtime 16:43Z, after my last probe at 16:39:44Z) and the other critics' pass-26 reports. Those are not mine. This report reviews the committed 10c2809 via `git archive`/`git show`, not the working tree. Nothing was written to `/workspace`'s own checkout. Its two questions files were only copied, read-only, into a temp repo.

The execution logs are scratch and are not committed. They are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc26/` (below, `fc26/`). The probes ran with cwd `fc26/`, and each script `cd`s into its own temp dir. The environment's `LC_ALL=en_US.UTF-8` is not installed, which is why the logs contain setlocale warnings.

Executed runs (UTC):
- **E1**, 16:36:55Z, `timeout 900 bash fc26/probe1.sh`, exit 0 → `fc26/probe1.out`. Temp dir `fc26/tmp.nO1IwQocwl/`. It holds three trees: `new/` (10c2809), `old/` (cbfdf35), and `inl/` (10c2809 with `$INSTRUCTION_FILE` replaced by the same pattern written inline). It ran:
  - `bats test/scripts/dev-cycle.bats` on `new/`: 41 ok, 0 not ok, exit 0 → `bats.out`.
  - `shellcheck scripts/dev-cycle.sh`: exit 0 → `sc.out`.
  - `python3 scripts/hermeticity-lint --root .` on each tree:
    - `new/`: exit 0, clean → `lint.new`;
    - `old/`: exit 1, "can spawn `claude` (via scripts/dev-cycle.sh)" → `lint.old`;
    - `inl/`: exit 1, the same message → `lint.inl`.
  - `--help` → `help.out`.
- **E2**, 16:37:41Z, `timeout 600 bash fc26/probe2.sh`, exit 0 → `fc26/probe2.out`. Temp dir `fc26/tmp.OBsN1kbL3y/`. It ran `--check-answer` with all 99 `### Q-NNN` IDs, under 10c2809 and under cbfdf35, on copies of `/workspace/docs/working/questions.md` and `questions-archive.md` → `ans.new`, `ans.old`. The diff was empty. A per-entry scan (`odd.out`, 0 lines) found:
  - no entry whose first `**Needs:**` line lacks `**Status:**`;
  - no Status value other than `OPEN` or `ANSWERED` followed by a space or the end of the line;
  - no `**Status:**` on any other line.

  The questions files are a time-varying input. The results hold for those files as of 16:37Z.
- **E3**, 16:38:33Z, `timeout 600 bash fc26/probe3.sh`, exit 0 → `fc26/probe3.out`. Each case ran under 10c2809 and under cbfdf35:
  - P1: `--check-answer` edge cases:
    - an unclosed fence;
    - a lower-case or comma-suffixed Status, or a Status on its own line;
    - a fenced heading in another entry;
    - a hidden duplicate.
  - P2: `--check-brief` on these briefs:
    - fenced, case-variant, unspaced and unclosed-fence `Status:` lines;
    - a CRLF brief;
    - a 300 KB brief.
  - P3: the printed commit when the default branch also edited the brief.
  - P4: the tip-date zone, and a repo with no main.
  - P5: `--check-fix` instruction-file names.
- **E4**, 16:39:44Z, `timeout 300 bash fc26/probe4.sh`, exit 0 → `fc26/probe4.out`. It covers:
  - P6: an earlier entry that quotes, inside a fence, an answered copy of a later OPEN entry;
  - P7: the same quote placed after the real entry;
  - a fence count over both real questions files.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the human reading the help, the record or the commit log.

---

## Claim 1: help: "--check-brief … "ok <path> new" when the default branch has no file there (not landed, or moved to closed/), else "ok <path> open|done|dropped <commit>" from its first unfenced "Status:" line on the default branch and the commit that last changed it there"

**Location:** `scripts/dev-cycle.sh:29-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output forms and the "first unfenced Status: line" rule for briefs of ordinary size. It does not establish the following:
- which commit "last changed it there" names after a two-sided edit (Claim 7);
- behavior for a brief over the pipe buffer: a 300 KB brief exits 141 with no output line, under cbfdf35 too;
- what an unclosed fence does: it hides every later line, and the brief is skipped.

```bash
# scripts/dev-cycle.sh:260-268
  if [[ "$(git cat-file -t "$MAIN_SHA:$a" 2>/dev/null || true)" != blob ]]; then echo "ok $a new"; return; fi
  # shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
  st="$(git cat-file blob "$MAIN_SHA:$a" | env LC_ALL=C awk '
    { sub(/\r$/, "") }
    /^(```|~~~)/ { fence = !fence; next }
    !fence && /^Status:/ { if ($0 ~ /^Status: (open|done|dropped)$/) print; exit }')"
  c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
  if [[ -n "$st" ]]; then echo "ok $a ${st#Status: } $c"
  else echo "skip $a: its first Status: line is not exactly Status: open, done or dropped"; fi
```
(excerpt ends :268; enclosing `check_brief()` ends at :269 — read.) Under 10c2809, E3/P2 printed the following:
- `open` for a brief with a fenced `Status: done` above `Status: open` (cbfdf35: `done`);
- a skip for `Status: Open` and for `Status:open` above an exact line (cbfdf35 read the later exact line);
- a skip for an unclosed fence;
- `done` for a CRLF brief (cbfdf35: skip).

For the 300 KB brief, both commits printed nothing and exited 141. awk's `exit` closes the pipe, `git cat-file` takes SIGPIPE, and `pipefail` plus `set -e` end the script. This is fail-safe, because the skill records a non-zero check.

**Evidence:** `scripts/dev-cycle.sh:255-269`, `fc26/probe3.out`
**Legibility-target:** user / agent

---

## Claim 2: help: "--check-branch "ok <name> <commit> <n> <YYYY-MM-DD>" for a brief's branch that exists (n: its commits not on the default branch; the date of its tip commit)"

**Location:** `scripts/dev-cycle.sh:35-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five-field form and the date as `%cs` of the tip. It does not establish what "today" a caller compares the date against. The skill's 14-day rule uses the cycle's local date (Claim 21).

`if [[ -n "$sha" ]]; then echo "ok $a $sha $(git rev-list --count "$MAIN_SHA..$sha") $(git log -1 --format=%cs "$sha")"` (`scripts/dev-cycle.sh:286`). E3/P4 printed `ok feat/tz 6aa1800… 1 2026-01-01`.

**Evidence:** `scripts/dev-cycle.sh:277-289`, `fc26/probe3.out`
**Legibility-target:** user / agent

---

## Claim 3: help: "The check modes need a default branch found by name (origin/HEAD, main or master): they read its commit." (and the code comment at :412-413, the Exit line at :59-61)

**Location:** `scripts/dev-cycle.sh:52-53`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-1 path for every check mode when only the current branch was found, and that the digest still runs on the current branch. It does not establish behavior when `origin/HEAD` names a branch with no local `refs/heads/<name>`. That case falls through to main or master, unchanged by this diff.

```bash
# scripts/dev-cycle.sh:414-416
if [[ -n "$CHECK" && -z "$MAIN_BY_NAME" ]]; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
```
`MAIN_BY_NAME=1` is set only in the candidate loop (`scripts/dev-cycle.sh:402`). E3/P4 ran on a repo whose only branch is `trunk`:
- 10c2809 printed `--check-branch needs a default branch …`; cbfdf35 printed an `ok` line computed against trunk;
- the digest mode exited 0.

bats test 41 passes.

**Evidence:** `scripts/dev-cycle.sh:391-416`, `fc26/probe3.out`, `fc26/tmp.nO1IwQocwl/bats.out`
**Legibility-target:** user / agent

---

## Claim 4: help range "sed -n '2,62p'"

**Location:** `scripts/dev-cycle.sh:125`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the range ends on the blank line :62, after the last header line :61 and before `set -euo pipefail` at :63. It does not establish that the range stays right after later header edits.

`-h|--help) sed -n '2,62p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`scripts/dev-cycle.sh:125`). The tail of E1's `help.out` is the Exit paragraph ("…or no perl; a failed step exits non-zero mid-digest. Printed repo text is data.") followed by a blank line.

**Evidence:** `scripts/dev-cycle.sh:59-63`, `fc26/tmp.nO1IwQocwl/help.out`
**Legibility-target:** maintainer

---

## Claim 5: "A done or dropped brief moves to briefs/closed/, so the open ones are all that the briefs/*.md glob lists once the move has landed."

**Location:** `scripts/dev-cycle.sh:232-233`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the glob is `git ls-files` (index) based, so a `git mv` is reflected once staged. It does not establish that every done or dropped brief does get moved: that is the skill's step.

`GIT_LITERAL_PATHSPECS=0 git ls-files -z -- "$1" | exact "$2"` (`scripts/dev-cycle.sh:205`). The qualifier "once the move has landed" closes pass 25's Claim 6.

**Evidence:** `scripts/dev-cycle.sh:203-212`, `scripts/dev-cycle.sh:229-233`
**Legibility-target:** maintainer

---

## Claim 6: "its first line outside a ``` or ~~~ fence that starts with "Status:", which must be exactly "Status: open|done|dropped". "new" when the default branch has no file at that path (not landed yet, or moved to closed/)."

**Location:** `scripts/dev-cycle.sh:249-253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fence handling (column-0 fences only, as in `ANSWER_AWK`), the first-line rule, CR stripping and both `new` causes. It does not establish the over-buffer exit 141 named in Claim 1.

`/^(```|~~~)/ { fence = !fence; next }` / `!fence && /^Status:/ { if ($0 ~ /^Status: (open|done|dropped)$/) print; exit }` (`scripts/dev-cycle.sh:264-265`). E3/P2 gives the results listed in Claim 1. Pass 25's E3/P2 showed `new` for an untracked brief and for the old path after `git mv` (`fc25/probe3.out`). That code path (:260) is unchanged.

**Evidence:** `scripts/dev-cycle.sh:255-269`, `fc26/probe3.out`
**Legibility-target:** maintainer

---

## Claim 7: "The commit that last changed the file there is printed: the commit that set the status, which a merge brought in (not the merge itself)."

**Location:** `scripts/dev-cycle.sh:253-254`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed commit in two cases: a `--no-ff` merge where only the branch touched the brief (the status-setting commit), and a squash (the squash commit). It does not establish a case where the default branch also changed the brief while the branch was open. There the merge itself is printed.

`c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"` (`scripts/dev-cycle.sh:266`). E3/P3 had two parts:
- A brief landed. A branch set `Status: done`. Meanwhile main appended `Kept: 2026-01-20`, as a cycle's keep answer does. Both commits printed the merge `a7003f8…`, not the set-done commit `45e2298…`.
- The control, with no main-side edit, printed the set-done commit `31ac9e4…`.

The two-sided case is not exotic. Cycles write `Asked:`, `Applied:` and `Kept:` lines into In flight briefs on the default branch while their build branches are open. The precise version would be: "…the commit that set the status, or the merge when the default branch also changed the file meanwhile, or a later commit that touched the file." The conclusion holds either way: the printed commit contains the status change. Wording.

**Evidence:** `scripts/dev-cycle.sh:253-254`, `scripts/dev-cycle.sh:266`, `fc26/probe3.out`
**Legibility-target:** maintainer / agent

---

## Claim 8: "The last fields are the branch's commits not on the default branch (0: none, as for a fresh branch or one merged with a merge commit; a squash-merged branch keeps its count) and the date of its tip commit, YYYY-MM-DD in the committer's zone. The default branch, when one was found by name, is refused."

**Location:** `scripts/dev-cycle.sh:272-276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This claim covers three things:
- the zone: committer date in the commit's own offset, not UTC or local;
- the count semantics: from pass 25's run, and the count code is unchanged;
- the refusal.

It does not establish that a rebased branch keeps its original date: the rebase rewrites the committer date.

E3/P4 committed with `GIT_COMMITTER_DATE='2026-01-01T23:30:00-1000'` (UTC 2026-01-02 09:30) and an author date of 2026-03-03. The output was `… 1 2026-01-01`. So the field is the committer date in the committer's zone. Pass 25's E3/P3 printed counts of 0 for a merged branch and 1 for a squash-merged one (`fc25/probe3.out`). Since Claim 3, the "when one was found by name" qualifier is always true in a check mode. The sentence is still accurate.

**Evidence:** `scripts/dev-cycle.sh:277-289`, `fc26/probe3.out`
**Legibility-target:** maintainer

---

## Claim 9: "Instruction-file basenames, lower-cased: CLAUDE.md, CLAUDE.local.md, AGENTS.override.md and the like, GEMINI.md, SKILL.md. (A variable, quoted: written inline, the hermeticity lint reads the alternation as a command.)"

**Location:** `scripts/dev-cycle.sh:295-298`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex as used unquoted on the right of `=~` (per-branch anchors), the named examples and the lint rationale. It does not establish other variants: `skill.local.md`, multi-segment names like `claude.a.b.md`, and hyphenated names like `claude-notes.md` all pass as ordinary docs. Those are not instruction names the comment lists.

`INSTRUCTION_FILE='^(claude|agents|gemini)(\.[a-z0-9_-]+)?\.md$|^skill\.md$'` (`scripts/dev-cycle.sh:298`), used as `"$low" =~ $INSTRUCTION_FILE` (`:306`). E3/P5 under 10c2809:
- skipped `AGENTS.md`, `gemini.md` and `Agents.Override.md` (cbfdf35 allowed the last);
- allowed `skill.local.md`, `claude.a.b.md`, `xclaude.md` and `claude-notes.md`.

E1 ran the lint on three trees: on `inl/`, with the same pattern written inline at :306, it exits 1 ("can spawn `claude` (via scripts/dev-cycle.sh)"); on cbfdf35 it fails the same way; on 10c2809 it is clean.

**Evidence:** `scripts/dev-cycle.sh:290-309`, `fc26/probe3.out`, `fc26/tmp.nO1IwQocwl/lint.new`, `fc26/tmp.nO1IwQocwl/lint.inl`, `fc26/tmp.nO1IwQocwl/lint.old`
**Legibility-target:** maintainer

---

## Claim 10: "Prints keep, drop, done, open, unrecognized, dup (the heading appears more than once), or nothing when the file has no such entry." (with the help's skip for "a duplicate heading", `:50`)

**Location:** `scripts/dev-cycle.sh:310-312`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers headings that sit outside every fence. The claim fails when a heading-shaped line sits inside a fence: either in another entry's fence, or after an unclosed fence in the target entry. It does not establish any real entry being affected. Both real files have 0 fenced `### ` lines and end outside a fence (E4).

```awk
# scripts/dev-cycle.sh:349-355
{ sub(/\r$/, "") }
inside && /^(```|~~~)/ { fence = !fence; next }
inside && fence { next }
heading($0) { count++; inside = (count == 1); fence = 0; header = 0; next }
/^(#|##|###) / { inside = 0 }
!inside { next }
!header && /^\*\*Needs:\*\*/ { header = 1; answered = ($0 ~ /\*\*Status:\*\* ANSWERED( |$)/); next }
```
(excerpt ends :355; `ANSWER_AWK` continues to :373 with the answer-line reader and END — read.)

Fence parity is tracked only while `inside`. Two failures follow:
- **A heading quoted in another entry's fence.** The heading-shaped line opens the entry with `fence = 0`. The quote's closing fence is then read as an opener, which hides the real entry's heading, so no `dup`. Any `**Needs:** … ANSWERED` and `- Q-NNN: [2]` lines inside the quote are read as the entry's.
- **An unclosed fence in the target entry.** It hides the next entries' headings until some later fence flips parity. Then another entry's answer lines are read.

E3/E4 results (10c2809 vs cbfdf35):
- **P6.** Q-10's body quotes, in a fence, an answered copy of Q-11 (`### Q-11 …`, `**Needs:** … **Status:** ANSWERED`, `- Q-11: [2]`). The real Q-11 below it is OPEN. Result: `drop Q-11` vs `skip Q-11: more than one entry with this heading`.
- **P1 Q-7.** A fenced `### Q-7 · quoted` in Q-6, then a real ANSWERED Q-7 with `- Q-7: [2]`. Result: `open Q-7` vs the dup skip. The fence flip hid the real entry.
- **P1 Q-8.** A real duplicate `### Q-8` after an unclosed fence. Result: `unrecognized Q-8` vs the dup skip.
- **P1 Q-1.** An ANSWERED Q-1 with an unclosed fence. Q-2's fence closes it, and Q-2's `**Answer:** [2] drop` is read. Result: `drop Q-1` vs `unrecognized Q-1`.
- **P7.** With the quote placed after the real entry, both commits print the dup skip.

At cbfdf35 every one of these cases was fail-safe (a dup skip or `unrecognized`). The reorder brings back the non-fail-safe class that pass 25 recorded for c1d0a80 (`drop Q-3` for a fenced heading in another entry).

Behavioral, non-fail-safe: an OPEN keep-or-drop entry can be read as `drop` or `done`, and the skill then closes the brief. Preconditions:
- **P6 path:** an entry above the target quotes the target's heading and an ANSWERED header plus an answer line inside a fence (for example a follow-up quoting an answered earlier ask with the same ID).
- **Q-1 path:** an answered target entry with an odd number of column-0 fence lines.

Likelihood: low. No real entry matches today (E2 diff empty, E4 counts). Fix: track fence parity over the whole file (toggle outside `inside` too) and test headings only outside a fence. Or state the limit in the comment.

**Evidence:** `scripts/dev-cycle.sh:310-373`, `scripts/dev-cycle.sh:46-51`, `fc26/probe3.out`, `fc26/probe4.out`
**Legibility-target:** maintainer / agent

---

## Claim 11: "An entry is answered only when its header line (the first line starting "**Needs:**", as questions.sh writes it) carries "**Status:** ANSWERED"; any other entry is open, whatever its body says"

**Location:** `scripts/dev-cycle.sh:313-316`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers entries whose own heading opens them. The gate is the entry's first unfenced `**Needs:**` line. The match is exact: `ANSWERED` in capitals, followed by a space or the end of the line. It also covers that every real entry reads as it did at cbfdf35. It does not establish the case where a quoted copy's header becomes the gate after a fenced heading-shaped line (Claim 10).

`!header && /^\*\*Needs:\*\*/ { header = 1; answered = ($0 ~ /\*\*Status:\*\* ANSWERED( |$)/); next }` (`scripts/dev-cycle.sh:355`). `scripts/questions.sh:16` documents the header as `**Needs:** <route> · **Opened:** YYYY-MM-DD · **Status:** OPEN|ANSWERED`.

E2 results:
- All 99 real IDs give identical output under 10c2809 and cbfdf35: 23 keep, 19 drop, 3 done, 12 open, 42 unrecognized.
- `odd.out` is empty: every real header has a Status, its value is exactly OPEN or ANSWERED, and no Status appears on any other line.

E3/P1 off-format headers all read `open` under 10c2809, where cbfdf35 read `keep`: `**Status:** Answered`, `ANSWERED, 2026-10-01`, and a Status on its own line. This is fail-safe. The skill now lists open IDs in the final message.

**Evidence:** `scripts/dev-cycle.sh:313-319`, `scripts/dev-cycle.sh:355`, `scripts/questions.sh:16`, `fc26/tmp.OBsN1kbL3y/ans.new`, `fc26/tmp.OBsN1kbL3y/ans.old`, `fc26/tmp.OBsN1kbL3y/odd.out`, `fc26/probe3.out`
**Legibility-target:** maintainer / agent

---

## Claim 12: "Lines inside a fence in the entry are skipped, headings included."

**Location:** `scripts/dev-cycle.sh:316-317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers balanced fences inside an entry that a real heading opened. A `# comment` line inside the fence no longer ends the entry. It does not establish where the entry ends when a fence is unclosed, or when the heading itself sat in a fence. Both are in Claim 10.

`inside && /^(```|~~~)/ { fence = !fence; next }` / `inside && fence { next }` (`scripts/dev-cycle.sh:350-351`). bats test 40 has Q-2, whose fenced `# a comment, not a heading` precedes `**Answer:** [2]`. It prints `drop Q-2` and passes. pass 25's Claim 12b regression is fixed for this case.

**Evidence:** `scripts/dev-cycle.sh:349-354`, `test/scripts/dev-cycle.bats:745-761`, `fc26/tmp.nO1IwQocwl/bats.out`
**Legibility-target:** maintainer

---

## Claim 13: "The recorder's own answer line is the one read (the questions protocol records the user's answer there); a note above it would be read first."

**Location:** `scripts/dev-cycle.sh:317-319`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reader's first-match rule (`!done`) after the header line. It does not establish that recorders put nothing answer-shaped above the answer. Pass 25's E3/P1 showed an agent's interim `**Answered by agent …**` line deciding.

`!done { line = $0; sub(/^- /, "", line) … result = option(rest); done = 1 }` (`scripts/dev-cycle.sh:356-369`, paraphrased joining — no quote available because the block spans 14 lines; the operative parts are quoted). The first answer-shaped line after the header wins.

**Evidence:** `scripts/dev-cycle.sh:356-369`
**Legibility-target:** maintainer

---

## Claim 14: "`ok <path> new` when the default branch has no file there (not landed yet, or already moved to `closed/`)"

**Location:** `skills/dev-cycle/SKILL.md:80-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the agreement with `check_brief`'s `new` branch. It does not establish behavior for the over-buffer case (Claim 1).

The skill text matches the script's `if [[ "$(git cat-file -t "$MAIN_SHA:$a" …)" != blob ]]; then echo "ok $a new"` (`scripts/dev-cycle.sh:260`). Pass 25's E3/P2 showed both causes. This closes pass 25's Claim 21.

**Evidence:** `skills/dev-cycle/SKILL.md:78-81`, `scripts/dev-cycle.sh:260`
**Legibility-target:** agent

---

## Claim 15: "**A brief holds a slot** when the glob lists it or this cycle wrote it, unless `--check-brief` prints `done` or `dropped` for it; a brief the check skips keeps its slot (recorded) until the cause is fixed." (used at :293-294 and :307-309)

**Location:** `skills/dev-cycle/SKILL.md:81-84`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every place the skill decides a slot:
- In flight step 3: "Until it is answered, the brief still holds its slot" (:293-294);
- Build briefs: "while fewer than 3 briefs hold a slot (as in the Rules; each counted once)" (:308-309);
- the removed step-1 sentence, now only in the Rules.

It does not establish the record template's count label (Claim 25), or that step 1's "open brief (found as in the Rules)" (:160) means slot-holding. There it only selects branches not to prune, which is harmless either way.

Each case maps to one outcome:
- listed by the glob: `new` or `open` → slot; `done` or `dropped` → no slot; skip → slot;
- written this cycle: untracked, so `new` → slot;
- moved this cycle: off the glob after `git mv` (Claim 5).

Pass 25's Claim 22 contradiction (":80-82 only when open or new" vs ":265 keeps its slot") is gone: `rg -n slot` finds only :81, :83, :294, :308 (paraphrased — no quote available because this is a grep over the file; the four lines are quoted in this claim's title and scope).

**Evidence:** `skills/dev-cycle/SKILL.md:76-88`, `skills/dev-cycle/SKILL.md:158-161`, `skills/dev-cycle/SKILL.md:287-296`, `skills/dev-cycle/SKILL.md:307-309`
**Legibility-target:** agent

---

## Claim 16: "A roadmap In flight path that `--check-path` skips (the brief moved, or never landed) is recorded and its line corrected."

**Location:** `skills/dev-cycle/SKILL.md:84-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that `--check-path` skips both cases. A moved brief's old path is no longer tracked. A never-landed brief is untracked, and briefs are not under the gitignored-docs/working exception unless ignored. It does not establish what "corrected" means for a brief that never landed: the text names no target.

`check_path` lists only `git ls-files` matches plus ignored files under `docs/working/` (`scripts/dev-cycle.sh:203-212`). Any other path gets "skip $a: no tracked file (or ignored file under docs/working/) matches" (`:227`).

**Evidence:** `scripts/dev-cycle.sh:203-228`, `skills/dev-cycle/SKILL.md:84-85`
**Legibility-target:** agent

---

## Claim 17: "`--check-branch '<name>'`, which prints `ok <name> <commit> <n> <date>` (n: its commits beyond the default branch; date: its tip commit's), `absent <name>`, or a skip"

**Location:** `skills/dev-cycle/SKILL.md:85-88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the agreement with the script's output form. It does not establish the zone of the date, which is the committer's (Claim 8).

The skill's form matches the script line quoted in Claim 2 (`scripts/dev-cycle.sh:286`). E3/P4 printed it.

**Evidence:** `scripts/dev-cycle.sh:286-287`, `fc26/probe3.out`
**Legibility-target:** agent

---

## Claim 18: "A check that exits non-zero (no default branch, say) is recorded, and the step that needed it stops."

**Location:** `skills/dev-cycle/SKILL.md:89-90`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the no-default-branch case now exits non-zero for every check mode, so the instruction has a trigger. It does not establish that the agent records it: that is prose. The over-buffer brief is another non-zero exit this covers (Claim 1).

E3/P4 printed `--check-branch needs a default branch …` from `scripts/dev-cycle.sh:415`, and the exit is 1 (bats test 41).

**Evidence:** `scripts/dev-cycle.sh:414-416`, `fc26/probe3.out`, `fc26/tmp.nO1IwQocwl/bats.out`
**Legibility-target:** agent

---

## Claim 19: "→ Done, naming the commit it prints (the commit that set the status; the merge that brought it in follows it)."

**Location:** `skills/dev-cycle/SKILL.md:261-263`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-sided `--no-ff` merge and the squash. It does not establish the two-sided case, where the printed commit is the merge (Claim 7).

E3/P3: when main appended a `Kept:` line while the build branch set `Status: done`, `--check-brief` printed the merge `a7003f8…`. The parenthesis would then describe the record's commit wrongly. The skill itself writes the `Kept:`, `Asked:` and `Applied:` lines that make this case. Wording: Done still names a commit containing the change.

**Evidence:** `scripts/dev-cycle.sh:266`, `fc26/probe3.out`
**Legibility-target:** agent

---

## Claim 20: "It prints `dropped` (set on the default branch, by the user or a merged change; the record names its commit)"

**Location:** `skills/dev-cycle/SKILL.md:263-264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `dropped` is read only from MAIN_SHA and that a commit is printed with it. The record's choice of commit has the same two-sided caveat as Claim 7.

`echo "ok $a ${st#Status: } $c"` (`scripts/dev-cycle.sh:267`), where `st` comes from `git cat-file blob "$MAIN_SHA:$a"` (`:262`).

**Evidence:** `scripts/dev-cycle.sh:262-267`
**Legibility-target:** agent

---

## Claim 21: "`open` is not answered yet (or the answer is not recorded: an entry is read only once its header says ANSWERED): leave the ID, and list it in the final message with the date it was asked, so a reply written in place gets recorded."

**Location:** `skills/dev-cycle/SKILL.md:276-279`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the agreement of "open" with the script (Claim 11). It does not establish that the end-of-cycle instruction carries this list, or where the date comes from.

The parenthesis matches `print (!answered ? "open" : …)` (`scripts/dev-cycle.sh:372`). Two gaps:
- **The final message.** The final-message paragraph is what the agent follows when it sends the message. It lists "the new `you: judgment` entries by ID and name, any keep-or-drop answer step 6 could not read, and each open build brief by path" (`skills/dev-cycle/SKILL.md:353-355`). It does not name still-open IDs or their dates; an open ID is "not answered", not "could not read".
- **The date.** The `Asked:` line holds IDs only (`:293`). The entry's `**Opened:**` date sits in the questions file, but the Rules say "A question ID from a brief is read only through `--check-answer`" (`:89`), and that check prints no date. The date is derivable from the cycle record that filed the entry, but the skill does not say so.

Wording, agent-facing, low.

**Evidence:** `skills/dev-cycle/SKILL.md:89`, `skills/dev-cycle/SKILL.md:276-279`, `skills/dev-cycle/SKILL.md:293`, `skills/dev-cycle/SKILL.md:353-355`, `scripts/dev-cycle.sh:372`
**Legibility-target:** agent

---

## Claim 22: "if the brief is still open and no ID on its `Asked:` line is still `open` or skipped, and its branch shows no work 14 days after the brief's last `Kept:` date … "Shows no work": `--check-branch` prints `absent`, skips the name (recorded), prints a count of 0, or prints a tip date more than 14 days before today (an idle branch, including a squash-merged one whose status line was not set)."

**Location:** `skills/dev-cycle/SKILL.md:287-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the asking cadence against `Kept:`. An ask requires all three of these at once:
- today ≥ last `Kept:` (or brief date) + 14;
- the tip is older than 14 days, or the branch is absent, skipped or at a count of 0;
- no outstanding ask.

So an active but slow branch is asked at most once per 14-day window after each keep. It is asked only when its tip is over 14 days old at that cycle, and never while it commits at least every 14 days. It does not establish behavior for a rebased branch (the committer date resets, so it reads as active), or the boundary day (strictly "more than 14 days").

The tip date is the committer date in the committer's zone (Claim 8). The skill compares it with "today", the cycle's local date, so the boundary can shift by a day across zones. That is immaterial at a 14-day threshold. A squash-merged branch keeps a count above 0 but stops gaining commits, so it crosses the 14-day line and is asked keep, drop or done. Option [3] covers it ("it shipped; its status line was not set", `:292`).

**Evidence:** `skills/dev-cycle/SKILL.md:287-296`, `scripts/dev-cycle.sh:286`, `fc26/probe3.out`
**Legibility-target:** agent

---

## Claim 23: "**Done**: items finished since the last cycle, each with the commit `--check-brief` printed (or the user's done answer)."

**Location:** `skills/dev-cycle/SKILL.md:301-302`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with In flight step 1. Done comes either from a `done` print (a commit) or from a keep-or-drop `done` (the user's answer as the source). It does not establish which commit is printed in the two-sided case (Claim 7).

Step 1 says "→ Done, naming the commit it prints" and "Keep-or-drop says done → Done, with … the user's answer as the source" (`skills/dev-cycle/SKILL.md:262`, `:266-267`). This closes pass 25's Claim 25 mismatch ("with the merge").

**Evidence:** `skills/dev-cycle/SKILL.md:261-267`, `skills/dev-cycle/SKILL.md:301-302`
**Legibility-target:** agent

---

## Claim 24: "(a file name no brief has used before, in `briefs/` or `briefs/closed/`, nor by a brief this cycle has written: `--check-brief` prints `new` for it, `--check-path` on the same name under `closed/` prints a skip, and no file exists at the path yet …)"

**Location:** `skills/dev-cycle/SKILL.md:310-314`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three tests together:
- landed open briefs fail `new`;
- tracked closed briefs fail the `closed/` skip;
- this cycle's own untracked briefs fail "no file exists" (this closes pass 25's Claim 30);
- a brief moved this cycle still shows on main at its old path, so it is not `new`.

It does not establish names used only on unmerged branches.

`--check-brief` prints `new` for any path absent from MAIN_SHA (`scripts/dev-cycle.sh:260`), so the third test is the one that sees same-cycle files.

**Evidence:** `skills/dev-cycle/SKILL.md:310-314`, `scripts/dev-cycle.sh:203-228`, `scripts/dev-cycle.sh:260`
**Legibility-target:** agent

---

## Claim 25: record template "6. roadmap: <done>; briefs: <written this cycle, or none>; <k>/3 open (3/3: no new briefs)"

**Location:** `skills/dev-cycle/SKILL.md:337`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the label against the slot rule. It does not establish how an agent fills k.

Build briefs stops at "fewer than 3 briefs hold a slot" (`:308`), and the slot rule counts briefs that are not open. Examples are a brief the check skips (`:83`) and one this cycle wrote, which prints `new`. The template still reports the cap as "<k>/3 open". The precise label would be "<k>/3 slots held". Wording, low. This is the one place the single slot rule is not used verbatim.

**Evidence:** `skills/dev-cycle/SKILL.md:81-84`, `skills/dev-cycle/SKILL.md:307-309`, `skills/dev-cycle/SKILL.md:337`
**Legibility-target:** agent / user

---

## Claim 26: test name "the ANSWERED gate reads only the header line; a fenced Status line in a brief is not its status"

**Location:** `test/scripts/dev-cycle.bats:745`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's own fixtures. Q-1's body quotes `**Status:** ANSWERED` and its header is OPEN, so it prints `open`. Q-2 has a fenced heading-shaped line and prints `drop`. The brief has a fenced `Status: done` above `Status: open`. It does not establish a fenced heading in another entry or an unclosed fence (Claim 10). No test covers either.

`[[ "$output" == *"open Q-1"* && "$output" == *"drop Q-2"* ]]` and `[[ "$output" == "ok docs/working/briefs/2026-01-01-a.md open "* ]]` (`test/scripts/dev-cycle.bats:758-761`). E1: ok 40.

**Evidence:** `test/scripts/dev-cycle.bats:745-761`, `fc26/tmp.nO1IwQocwl/bats.out`
**Legibility-target:** maintainer

---

## Claim 27: test name "the check modes need a default branch found by name"

**Location:** `test/scripts/dev-cycle.bats:763`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-branch` on a `trunk`-only repo: exit 1 and the stderr text. It does not establish the other five modes individually. They share the one guard at `scripts/dev-cycle.sh:414`, which runs before the dispatch loop.

`[ "$status" -eq 1 ]` and `[[ "$stderr" == *"needs a default branch"* ]]` (`test/scripts/dev-cycle.bats:766-768`). E1: ok 41.

**Evidence:** `test/scripts/dev-cycle.bats:763-769`, `scripts/dev-cycle.sh:414-417`, `fc26/tmp.nO1IwQocwl/bats.out`
**Legibility-target:** maintainer

---

## Claim 28: commit 10c2809 behavior bullets ("--check-answer reads "**Status:** ANSWERED" only from the entry's header line …; a body that quotes it no longer makes an OPEN entry answered. Fences inside the entry hide heading-shaped lines too." / "--check-brief takes the brief's first unfenced "Status:" line, which must be exact" / "--check-branch adds its tip commit's date" / "The check modes need a default branch found by name; in a repo with none they exit 1" / "--check-fix refuses CLAUDE.local.md / AGENTS.override.md style names … written inline, the hermeticity lint read its alternation as a call to a network binary")

**Location:** `10c2809` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet as worded: the entry's own body (Claims 11, 26), fences inside the entry (Claim 12), and Claims 1, 2, 3 and 9. It does not establish that quoted text elsewhere in the file cannot make an OPEN entry answered: Claim 10 shows it can (P6).

This claim combines the executed results cited in Claims 1-3, 9, 11, 12 and 26 (paraphrased — no quote available because the commit message's bullets each map to a claim above, where the code is quoted).

**Evidence:** `scripts/dev-cycle.sh:255-309`, `scripts/dev-cycle.sh:349-355`, `scripts/dev-cycle.sh:414-416`, `fc26/probe3.out`, `fc26/tmp.nO1IwQocwl/lint.inl`
**Legibility-target:** user

---

## Claim 29: commit 10c2809: "Tests: header-only gate, fenced headings, fenced status, tip date, no default branch, more instruction names. 41/41; shellcheck and the hermeticity lint clean."

**Location:** `10c2809` (commit message)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, the pass, shellcheck and the lint at 10c2809. It does not establish the full `scripts/health-check.sh` run.

E1 results:
- bats: 41 ok, 0 not ok, exit 0;
- `grep -c '^@test'` gives 41;
- shellcheck: exit 0, empty;
- `hermeticity-lint --root .`: exit 0, "126 test file(s) checked, no unstubbed network spawns".

**Evidence:** `fc26/tmp.nO1IwQocwl/bats.out`, `fc26/tmp.nO1IwQocwl/sc.out`, `fc26/tmp.nO1IwQocwl/lint.new`
**Legibility-target:** user

---

## Claim 30: commit 875b41f bullets ("One rule for a brief's slot, stated once in the Rules …" / ""Shows no work" also covers a branch whose tip is older than 14 days …" / "An ID still open is listed in the final message with its date …" / "Done names the commit --check-brief prints (the one that set the status); "new" also covers a brief already moved to closed/, and a stale In flight path is corrected; a new brief's name is checked against this cycle's own briefs too.")

**Location:** `875b41f` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the diff: Claims 14-16, 19, 21, 22 and 24. The verdict is carried by the most severe part, "(the one that set the status)", which Claim 19 shows can be the merge. It does not establish that the final-message paragraph itself was updated: it was not (Claim 21).

The other bullets match the diff, as quoted in the claims named in the Scope (paraphrased — no quote available because each bullet maps to a claim above where the skill text is quoted).

**Evidence:** `skills/dev-cycle/SKILL.md:76-90`, `skills/dev-cycle/SKILL.md:258-319`, `fc26/probe3.out`
**Legibility-target:** user

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`scripts/dev-cycle.sh:310-312`, help `:50`): "dup (the heading appears more than once)" no longer holds once a heading-shaped line sits in a fence.
  - Cause: the reorder tracks fence parity only inside the target entry, so a heading quoted in another entry's fence starts the entry and flips parity.
  - P6: an OPEN entry is read as `drop` via an earlier fenced quote of an answered copy (cbfdf35: dup skip).
  - P1: an unclosed fence in an answered entry reads the next entry's `**Answer:**` (`drop Q-1`, cbfdf35: `unrecognized`). Real duplicates and real entries are hidden (`open Q-7`, `unrecognized Q-8`).
  - Behavioral, non-fail-safe, low likelihood: no real entry has a fenced heading (E4).
  - Fix: track fences file-wide and test headings only outside them, plus a test with a fenced `### Q-N` in another entry.

### Stale
- None.

### Mostly Accurate
- **Claim 7** (`scripts/dev-cycle.sh:253-254`): "not the merge itself" fails when the default branch also edited the brief while the branch was open (a cycle's `Kept:`, `Asked:` or `Applied:` line). The merge is printed (P3). Wording.
- **Claim 19** (`skills/dev-cycle/SKILL.md:261-263`): the same caveat in the skill's Done instruction. Wording.
- **Claim 21** (`skills/dev-cycle/SKILL.md:276-279` vs `:353-355`, `:89`): the final-message paragraph does not list still-open IDs. "The date it was asked" has no named source: `Asked:` holds IDs only, and question IDs are read only through `--check-answer`. Wording, agent-facing.
- **Claim 25** (`skills/dev-cycle/SKILL.md:337`): the record template says "<k>/3 open" for what the slot rule counts as slots held. Wording.
- **Claim 30** (commit 875b41f): inherits Claim 19's "(the one that set the status)". Wording.

### Unverifiable
- None.

Observations outside the verdict counts:
- A brief larger than the pipe buffer makes `--check-brief` exit 141 with no line. This is pre-existing (cbfdf35's `grep -m1` did the same) and fail-safe, since the skill records a non-zero check (Claims 1, 6).
- In check modes, `check_branch`'s `-n "$MAIN_BY_NAME"` guard is now always true (Claim 8).

---

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass26.md`. Its first line is `Commit: 10c2809 (A) / 875b41f (B)`, and it carries `**Replication:** k=1 (loop pass, decision 031)`. Every claim has the seven mandatory fields plus a Legibility-target. Verdicts are counted in the Summary and listed under Claims Requiring Attention.

The brief's priority list was covered first:
- **A:**
  - the header-only gate against every real entry, with no change against cbfdf35 (Claim 11);
  - the fence-before-heading reorder. A fence can now hide the next entry's heading and misread answers (Claim 10);
  - the brief status awk (Claims 1, 6);
  - the tip date and its zone (Claims 2, 8);
  - the no-default-branch exit (Claims 3, 18, 27);
  - the instruction regex with `|` inside `=~ $VAR`, and the lint rationale (Claim 9);
  - the help range (Claim 4);
  - commit 10c2809 (Claims 28, 29).
- **B:**
  - the single slot rule at every counting site (Claims 15, 25);
  - the 14-day rule against `Kept:`: an active slow branch is asked at most once per 14 days after each keep (Claim 22);
  - the final-message listing (Claim 21);
  - commit 875b41f (Claim 30).

Nothing was committed.
