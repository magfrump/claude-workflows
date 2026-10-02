Commit: 2fd9401

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-devcycle`, branch `feat/dev-cycle` at 2fd9401 (HEAD was 2fd9401 at the start and end of this pass; the only untracked file in the worktree is a sibling critic's report).
**Scope:** Full branch, not a delta: `git diff main...2fd9401 -- . ':!docs/reviews'` (13 files, 2,507 added lines): `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`, `skills/dev-cycle/SKILL.md`, `docs/dev-cycle.md`, `docs/roadmap.md`, `docs/working/seed-build-loop-handoff.md`, `docs/decisions/log.md` rows 66–69, `docs/working/questions.md` / `questions-archive.md`, `README.md`, `global-instructions/CLAUDE.md`, `guides/skill-creation.md`, `workflows/codebase-onboarding.md`. Also covered: the messages of the branch's commits (test-count claims across all of them, and merge 2fd9401's message). `docs/reviews/` is context only, except for the structural check of `override-log.md` after the merge.
**Checked:** 2026-10-02
**Replication:** k=1 (full review; user's instruction)
**Total claims checked:** 52
**Summary:** 49 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 5 patterns) first. No claim here matches a logged pattern. The one Incorrect verdict is a mechanism mismatch, not a fabricated symbol, so nothing qualifies for the log.

## Headline

- **One Incorrect (behavioral, low).** Claim 33a: the `ANSWER_AWK` comment (`scripts/dev-cycle.sh:437-438`) says an answer's text "ends at the bold's close if it opened inside the bold". The code cuts the text at the first `**` after `": "` in every case, including when the label's bold already closed before the colon. So `**Answer (2026-10-02)**: **[2]**` reads `unrecognized`, and so does `**Answer (2026-10-02)**: **drop** because`. The comment's rule (text starts at `**[2]**`, and the leading token decides once `*` is stripped) gives `drop`. The failure direction is safe: the user is asked again, and nothing is closed by mistake. No real questions file has this shape (0 matches over both files). It is a single-line label parse, outside decision log 69's accepted class.
- **Two Mostly accurate (wording only).**
  - Claim 20: the `--check-fix` help (`:50-53`) leaves out two refusals the code makes. `docs/roadmap.md` (a tracked .md under docs/) gets "one of the cycle's own files (use --check-write)". A dotfile such as `docs/notes/.hidden.md` is refused under the reason "dot-directories".
  - Claim 35: `last committed on this branch: <date>` (`:649`, `:731`) prints the **author** date (`%ad`). A commit authored 2026-01-05 and committed 2026-10-02 is counted in the window but printed as "last committed … 2026-01-05".
- **Everything the brief prioritized holds.**
  - **Digest end to end.** It ran on a throwaway clone with `main` moved to 2fd9401: rc 0, all 8 sections, every log row mentioning "revisit" printed (11/11), and the date map agrees with per-file `git log -1` for all 11 records.
  - **Check modes.** Their interfaces, the Exit text and `--help` (byte-equal to lines 2–75) all match behaviour.
  - **Read-only.** The digest and every check mode leave a clone unchanged: `status --ignored`, refs, and no file newer than the start stamp.
  - **The skill against the script.** It names each digest section, check output and exit behaviour correctly. Decision log 67–69, `docs/dev-cycle.md`, README, global row 12, the skill-creation guide row and onboarding step 13 agree with it and with each other.
- **The merge 2fd9401 is clean.**
  - `questions.sh check` rc 0, and `questions.sh index` regenerates both indexes with no diff.
  - All 103 Q-IDs read through `--check-answer` with 0 skips. Q-099/100/101 read `keep` and Q-102/103 read `open`; Q-090 reads `unrecognized`, an `agent` entry with no `Q-NNN:`/`**Answer…` line, so this is expected.
  - The archive order is Q-100, Q-099, Q-101, then Q-090, as the message says.
  - The override-log table is contiguous with no blank line. Its 15 merged-in rows are 6-cell like their neighbours, and the two irregular rows (cell counts 7 and 8, escaped pipes) were already on main.
  - "main's 13 commits since 4225753" holds: `rev-list --count 4225753..bf54363` = 13.
- **Gates.** bats 49/49 (rc 0), hermeticity lint rc 0, shellcheck rc 0. Every `N/N` test count in the 40 branch commit messages that state one equals the `@test` count at that commit.

**Probe discipline.** Each probe (`fcfull/p1.sh`–`p6.sh`) is one script. It starts with `set -eu`, creates its own `mktemp -d -p fcfull/` dir in that same script and checks `case "$PWD"` before any `git init`, clone, commit or write; nested repos are re-checked after their `cd`. Every git, bats, lint and digest process runs under `timeout`, and all exited. Inside the worktree I ran only read-only commands (`git diff/show/log/status/rev-parse/ls-tree/cat-file`, bats, shellcheck, the lint, `dev-cycle.sh --help`). P1 confirms that the worktree's `git status --porcelain` is the same before and after bats. Synthetic repos use a temp `HOME` and `GIT_CONFIG_GLOBAL`. **Slips (all inside my scratch dir; nothing else was touched):**
- I captured P2–P5's output with a top-level `> fcfull/pN.out` redirect, not inside the script.
- An exploratory one-liner wrote `fcfull/seedA.txt` through a top-level redirect. It was then redone in P6 without writing.
- My first P6 run printed to the terminal only. The rerun captures its log inside its own temp dir.
- No file outside `fcfull/` was written, except this report.

**Concurrent commits (outside this pass's fixed commit).** Two commits landed on `feat/dev-cycle` after my last probe (P6, 20:31:25Z), and this review did not write them. Both touch only `skills/dev-cycle/SKILL.md`:
- b684ff2 (13:32:12 −0700) changes "step 3" to "check 3" twice in step 6.
- 91b88d7 (13:33:58 −0700) adds "Every mode takes many arguments: batch a step's values into one call per mode."

Every verdict and SKILL.md line number here is at 2fd9401; at 91b88d7, lines after `:100` sit one line lower. I did not verdict these commits, beyond noting that the added sentence matches `CHECK_ARGS=("$@")` and the per-argument loop (`scripts/dev-cycle.sh:136,546-555`). Nothing in them touches Claims 20, 33a or 35.

**Execution provenance.** Each probe ran from the cwd `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fcfull` (below, `fcfull/`) as `timeout N bash pK.sh`.
- **P1** (20:25:56Z–20:26:19Z, rc 0) ran bats, the lint, shellcheck and `--help` on the worktree. Logs are in `fcfull/tmp.8pIMBef4P6/` (`bats.log`, `lint.log`, `shellcheck.log`, `help.log`, `help.expected`, `status-before.log`, `status-after.log`). `help.log`'s only difference from lines 2–75 is two host `bash: warning: setlocale` lines (LC_ALL=en_US.UTF-8 is not installed), which come from bash start-up, not from the script.
- **P2** (20:26:52Z–20:26:59Z, rc 0) ran the digest (default window and `--since=2026-09-01 --sample=3`), the date-map comparison, all IDs through `--check-answer`, `questions.sh check/index`, the override-log shape and the check modes on a clone. Output is in `fcfull/p2.out`; artifacts (`digest.md`, `digest-sep.md`, `answers.txt`, `qcheck.log`, …) are in `fcfull/tmp.2ZTplJGLcm/`.
- **P3** (20:28:57Z–20:28:58Z, rc 0) ran synthetic answer labels, `--check-fix`, briefs, exit codes and a deleted record in section 7. Output is in `fcfull/p3.out` (repo in `fcfull/tmp.w8DK6kbtxb/`).
- **P4** (20:30:06Z, rc 0) tested the author date against the committer date. Output is in `fcfull/p4.out`.
- **P5** (20:30:51Z–20:30:54Z, rc 0) is the read-only check. Output is in `fcfull/p5.out`; snapshots are in `fcfull/tmp.YDaTXdsf51/before.txt`, `after.txt`.
- **P6** (20:31:25Z, rc 0) checked history: commit-message test counts, the seed quote against 8b3a8ad, row 67's counts at main 5ee8315, the README count, the roadmap Done merges and the `.gitignore`. Output is in `fcfull/tmp.LVlUy91ri2/p6.log`.

Legibility-target values:
- **agent**: the model running the skill acts on the text.
- **maintainer**: someone editing the script, tests or docs.
- **user**: the person reading `--help`, a skip line, the decision log, a roadmap or questions entry, or a commit message.

---

## Claim 1: "`skills/` holds 34 Claude Code skills … the `dev-cycle` skill (the outer maintenance loop; `docs/roadmap.md`)"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the skill count at 2fd9401 and that `skills/dev-cycle/` exists. It does not establish the rest of the sentence's category list.

P6 prints `README skill count: 34 SKILL.md dirs; main has 33`. The README now reads `` `skills/` holds 34 Claude Code skills`` (`README.md:182`), and the one added directory is `skills/dev-cycle/`.

**Evidence:** `README.md:182`; `fcfull/tmp.LVlUy91ri2/p6.log`

---

## Claim 2: "research/plan docs are gitignored" (row 66's corrected trigger)

**Location:** `docs/decisions/log.md:89`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the `.gitignore` patterns for `docs/working/research-*.md` and `plan-*.md`. It does not establish that pr-prep's `← carried from RPI` line or committed rubrics are reliable signals.

`.gitignore:26-27` reads `docs/working/plan-*.md` / `docs/working/research-*.md` (P6).

**Evidence:** `.gitignore:26-27`; `fcfull/tmp.LVlUy91ri2/p6.log`

---

## Claim 3: "As of 2026-09-28, 11 decision records carried revisit triggers and 7 log rows mentioned a revisit condition"

**Location:** `docs/decisions/log.md:90`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the counts on main's last commit before 2026-09-29 (5ee8315, 2026-09-28 23:58 −0700), using the digest's own tests (`^## Revisit triggers`, a case-insensitive "revisit" in a numbered row). It does not establish the row's other history ("at least nine unwritten runs").

P6 prints `records with Revisit triggers: 11; log rows mentioning revisit: 7` at `main at 5ee8315…`.

**Evidence:** `docs/decisions/log.md:90`; `fcfull/tmp.LVlUy91ri2/p6.log`

---

## Claim 4: Row 68's summary of the cycle (carry-forward cut; step 4 spot-check and conditional 4b; brainstorm conditions; at most 3 open briefs; the policy is read by the handoff unit; "undocumented is broken" through the code-without-docs section)

**Location:** `docs/decisions/log.md:91`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers each listed property against the skill text and the digest's section 6. It does not establish the rationale cell ("8 gaps were applied"), which needs the approval doc.

The skill matches each part:
- brainstorm conditions: "roadmap Now holds 0–1 items ready … 10+ ideas seeded … a week or more since the last brainstorm, by date, or none recorded yet … the user asks" (`skills/dev-cycle/SKILL.md:236-241`);
- briefs: "while fewer than 3 briefs hold a slot" (`:324`);
- the policy: "This skill does not read it" (`:57-58`);
- 4b: "add a scoped deep-audit task to the roadmap" (`:226-227`).

The digest has `## 6. Merges with code but no docs` (`scripts/dev-cycle.sh:740`), and no `Main at:` or carry-forward text remains in either file (paraphrased — no quote available because the claim covers absence: `grep -n 'Main at\|carry'` finds only "nothing carries forward" at `scripts/dev-cycle.sh:70`).

**Evidence:** `skills/dev-cycle/SKILL.md:57-58,226-227,236-241,324`; `scripts/dev-cycle.sh:70,740`

---

## Claim 5: Row 69's refusal list (a fence-like line that is not a plain column-0 fence, a line starting with `<` except a complete one-line comment, a `<!--` left open, a line starting like a link reference definition behind any `>` and list markers, a stray CR, a BOM on line 1, a fence open at the end, a question heading inside a fence) and its effect (a skip; the ID stays off `Applied:`; a refused brief keeps its slot)

**Location:** `docs/decisions/log.md:92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each listed cause against `fence()`'s `refuse()` reasons, the `unbalanced` and `quoted` END results, and the skill's handling of a skip. It does not establish CommonMark agreement inside the accepted inline class, which this row itself excludes.

`fence()` refuses `cr`, `bom`, `fence`, `html`, `comment` and `refdef` (`scripts/dev-cycle.sh:314-325`). END prints `"unbalanced " fline` and `"quoted " qline` (`:491-492`). The skill keeps a skipped ID off `Applied:` ("the ID stays off `Applied:`", `SKILL.md:299`) and keeps the slot ("a brief the check skips keeps its slot", `:87`). bats tests 883, 903 and 808 pass (P1), and P3's `<name>` brief is skipped with reason `html`.

**Evidence:** `scripts/dev-cycle.sh:314-325,489-495`; `skills/dev-cycle/SKILL.md:87,299`; `fcfull/tmp.8pIMBef4P6/bats.log`; `fcfull/p3.out`

---

## Claim 6: "Codebase onboarding asks the user for the build-loop policy (its step 13)"

**Location:** `docs/dev-cycle.md:3-5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers that step 13 holds the policy paragraph and its Done-when box. It does not establish when onboarding is actually run.

`workflows/codebase-onboarding.md:447` is `### 13. Gate — validate with the team` (P6). `:453` reads "Also settle the project's **build-loop policy** with the user", and the Done-when list has "`docs/dev-cycle.md` records the build-loop policy the user chose".

**Evidence:** `workflows/codebase-onboarding.md:447-457`; `fcfull/tmp.LVlUy91ri2/p6.log`

---

## Claim 7: "The handoff design counts the setting as made only when the file has exactly one line, outside code blocks, reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` … Anything else counts as unset, which means `review`" / "the '(interim; Q-103)' … keeps it unset"

**Location:** `docs/dev-cycle.md:17-22`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers agreement with the seed's design item 2 and with Q-103's interim. No code reads this file yet ("not built yet"), so it does not establish any runtime behaviour.

The seed's design item 2 reads "set only when `docs/dev-cycle.md` has exactly one line, outside code blocks, reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` (a trailing CR is ignored); anything else is `review`" (`docs/working/seed-build-loop-handoff.md:29-31`). The live line is `Build-loop policy: review (interim; Q-103)` (`docs/dev-cycle.md:7`), which is not exact, so it reads as unset. Q-103's interim says the same: "its design counts that line as unset, which means `review`".

**Evidence:** `docs/dev-cycle.md:7,17-22`; `docs/working/seed-build-loop-handoff.md:29-31`; `docs/working/questions.md` (Q-103 Interim line)

---

## Claim 8: Idea-source rows go through `--check-path`, "which allows tracked files and gitignored files under `docs/working/` … at most 50 per row, never a symlink, a directory, a `.` or `..` component, `.git*` or any other untracked file"

**Location:** `docs/dev-cycle.md:26-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers `check_path`'s scope, cap and refusals and the real row `docs/working/feature-ideas*.md`. It does not establish what step 5 does with the files.

`check_path` sets `max=50` and prints `skip $a: matches more than $max files` (`scripts/dev-cycle.sh:228-234`). `matches()` lists `git ls-files` plus ignored files under `^docs/working/` (`:217-226`), and `pathform` rejects `.`, `..` and `[.][gG][iI][tT]*` (`:208`). On the clone, P2 prints `ok docs/working/feature-ideas.md` for the real row and `skip docs: a directory, not a file`. bats test 473 (symlinks, other untracked files, the 50 cap) passes (P1).

**Evidence:** `scripts/dev-cycle.sh:201-242`; `fcfull/p2.out`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 9: Q-074's signal: "1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26 if fewer than 5 new entries have landed by then"

**Location:** `docs/roadmap.md:54-56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers agreement with Q-074's text. It does not re-count `fix` commits.

Q-074 reads "`docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits … If it reaches 2026-10-26 with fewer than 5 n[ew entries]" (`docs/working/questions.md:100`; excerpt ends mid-sentence; the entry continues to `:102` — read).

**Evidence:** `docs/working/questions.md:97-102`

---

## Claim 10: Done: "log row 65, merge c9a370a" and "log row 66, merge 4225753"

**Location:** `docs/roadmap.md:69-71`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers that both are merge commits naming those log rows. It does not establish the "~89K tokens" figure (row 65's own claim).

P6 prints `c9a370aa parents ec297d4f ae61ad18 merge: AGENTS.md names workflows by filename, not @-import (decision log 65)` and `4225753a parents c9a370aa 8506e93c merge: a router skill for every workflow (decision log 66)`.

**Evidence:** `docs/roadmap.md:69-71`; `fcfull/tmp.LVlUy91ri2/p6.log`

---

## Claim 11: Q-103 [2]: "the next cycle's health check, spot-check (2 sampled merges by default) and code-without-docs check"

**Location:** `docs/working/questions.md:57`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the sample default and that the digest has a code-without-docs section. It does not establish how often those checks would catch a bad merge.

The default is `SAMPLE=2` (`scripts/dev-cycle.sh:126`), and the help says "how many merges to sample for the spot-check (default 2)" (`:21`). Section 6 is "Merges with code but no docs" (`:740`).

**Evidence:** `scripts/dev-cycle.sh:21,126,740`

---

## Claim 12: "reports `docs/reviews/*digest-pass{6,7,8,9}*.md`"; rubric sections "Pass 6" to "Pass 9"

**Location:** `docs/working/seed-build-loop-handoff.md:3-6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that the files and rubric headings exist. It does not establish their content.

`ls docs/reviews` lists `code-fact-check-report-digest-pass6.md` through `pass9.md` and the pass 7–9 security, performance and api reports (paraphrased — no quote available because the claim is about directory layout). The rubric has `## Pass 6 (review-fix loop, …` through `## Pass 9 (…` (`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:314,332,351,370`).

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:314-386`

---

## Claim 13: "The text below is the skill's step 6/6b wording at 8b3a8ad"

**Location:** `docs/working/seed-build-loop-handoff.md:49-51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers byte equality of both quoted blocks with `git show 8b3a8ad:skills/dev-cycle/SKILL.md` lines 213–259 and step 6b. It does not establish that the quoted design is right.

P6: the step 6b block is `identical`. The step 6 block differs only by `47d46 <` followed by an empty line, which is the skill's blank line before `### 7` that the fence omits.

**Evidence:** `docs/working/seed-build-loop-handoff.md:53-136`; `fcfull/tmp.LVlUy91ri2/p6.log`

---

## Claim 14: Global decision tree row 12: "The outer loop over rows 6/9: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer. Output is triage in `docs/working/questions.md`."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers agreement with the skill's description and Flow. It does not establish routing behaviour in a live session.

The skill's description reads "digest, health and cleanup, revisit triggers, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap, close, then hand build briefs for the top roadmap items to the user", and its trigger list matches row 12's keywords (`skills/dev-cycle/SKILL.md:4`). "It runs when the user starts it; there is no timer" (`:16-17`).

**Evidence:** `global-instructions/CLAUDE.md:32`; `skills/dev-cycle/SKILL.md:4,16-17`

---

## Claim 15: Inventory row: "Workflow-shaped (steps 0–7, with step 4b added and steps 4b and 5 conditional) … no human checkpoint mid-run beyond the Operating Modes approvals … produces a self-contained artifact (the cycle record). Its mechanical parts live in `scripts/dev-cycle.sh`."

**Location:** `guides/skill-creation.md:137`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers agreement with the skill's step list and rules. It does not establish the "Adequate" grade.

The Flow is `0 digest → 1 … → { 2 | 3 | 4 | 4b audit check } → 5 brainstorm (conditional) → 6 … → 7 close` (`skills/dev-cycle/SKILL.md:118-119`), with "### 4b. Deep-audit check (conditional)" (`:215`). The rule reads "Commits and merges follow the Operating Modes rules" (`:29-30`).

**Evidence:** `guides/skill-creation.md:137`; `skills/dev-cycle/SKILL.md:29-30,118-119,215,349`

---

## Claim 16: `--since`: "commits whose committer date, in the committer's own time zone (git's %cs), is on or after this date. Default: the date in the newest cycle-YYYY-MM-DD.md … that is a plain file, a real date and not future-dated (only its name is read), else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:16-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the window filter, the default and the Window line's source note. It does not establish the date map in section 2 (Claims 34–35).

The filter is `awk -v s="$SINCE" '$1 >= s'` on `%cs` (`:603,606`). The default loop skips non-real dates (`date -d "$d" … || continue`, `:570`) and future ones (`! "$d" > "$TODAY"`, `:571`), else `date -d "$TODAY - 14 days"` (`:585`). P2's Window line reads `since 2026-09-18 (from no cycle record found, so the default of 14 days …)`. bats tests 279, 289 and 271 pass (P1). P3: `--since=2026-02-30 rc=1`.

**Evidence:** `scripts/dev-cycle.sh:559-592,603-606`; `fcfull/p2.out`; `fcfull/p3.out`

---

## Claim 17: `--check-path` ("ok <path>" for a tracked file or a gitignored one under docs/working/, at most 50 per argument; "skip <arg or match>: <reason>" otherwise) and `--check-write` ("the same for one of the cycle's own bookkeeping files …; the file need not exist yet")

**Location:** `scripts/dev-cycle.sh:22-28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers both modes' output forms and allow lists. It does not establish that a stray git warning to stderr is absent: P2's `--check-path docs/working/briefs/x.md` on a repo with no `briefs/` dir also printed git's `warning: could not open directory 'docs/working/briefs/'` to stderr (the stdout answer was correct).

`writable()` allows exactly `docs/roadmap.md`, the questions files, the idea log, `cycles/cycle-DATE.md`, `briefs/closed/DATE-slug.md` and `isbrief` paths (`:251-255`). In P2 `--check-write` prints `ok` for six non-existent own-files and `skip docs/dev-cycle.md: not one of the dev cycle's own files`. bats tests 473 and 512 pass.

**Evidence:** `scripts/dev-cycle.sh:227-262`; `fcfull/p2.out`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 18: `--check-brief`: "ok <path> new" when the default branch has no file there; else "ok <path> open|done|dropped <commit>" from its first unfenced "Status:" line …; "skip <path>: <reason>" otherwise, including a brief the reader cannot trust (the listed causes)

**Location:** `scripts/dev-cycle.sh:29-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the output forms, the first-unfenced-Status rule, CRLF tolerance and the html refusal. The refusal list's completeness was verified at pass 36 (Claim 1 there) on the same code, and it is unchanged since dd1988d/3d580cd. It does not establish the accepted inline class.

P3 results:
- `ok docs/working/briefs/2026-10-01-fenced.md open …`: a fenced `Status: done` sits above the real `Status: open`.
- `ok …-crlf.md open …`: CRLF throughout is read, because a trailing CR is dropped (`{ sub(/\r$/, "") }`, `:358`).
- `skip …-html.md: line 2 starts with < after any blanks …, so the brief is not read`.

P2 prints `ok docs/working/briefs/2026-10-02-x.md new` and `skip docs/working/briefs/x.md: not a build brief`.

**Evidence:** `scripts/dev-cycle.sh:346-375`; `fcfull/p3.out`; `fcfull/p2.out`

---

## Claim 19: `--check-branch`: "ok <name> <commit> <n> <YYYY-MM-DD>" …, "absent <name>", "skip …" for a bad name, HEAD, refs/… or the default branch; "The commit is refs/heads/<name>'s own, never a same-named tag's."

**Location:** `scripts/dev-cycle.sh:43-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers each output form. It does not establish anything about a branch's work beyond the count and the tip date.

P2 prints `skip main: the default branch`, `ok feat/x 6872fc7… 0 2026-10-02`, `absent feat/nope`, `skip HEAD: not a valid branch name` and `skip -x: not an allowed branch name`. The lookup is `git show-ref --verify --hash "refs/heads/$a"` (`:391`). bats test 574 (a tag of the same name) passes.

**Evidence:** `scripts/dev-cycle.sh:384-396`; `fcfull/p2.out`

---

## Claim 20: `--check-fix`: "ok <path>" for … "a tracked .md file under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, a dot-directory or an instruction file) or README.md; "skip <path>: <reason>" otherwise."

**Location:** `scripts/dev-cycle.sh:50-53`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the help's allow list against `check_fix` for `docs/roadmap.md`, a dotfile and a file in a dot-directory. It does not establish the code comment (`:397-401`), which does list "the cycle's own files" and is accurate, or the skill's version (`SKILL.md:72-75`), which also lists "the cycle's own files".

Wording, not behaviour: the code is stricter than the help in two places.
- **The cycle's own files.** `docs/roadmap.md` is a tracked .md under docs/ and is not in the help's exclusions, yet `if writable "$a"; then echo "skip $a: one of the cycle's own files (use --check-write)"` (`:411`) refuses it. P3: `skip docs/roadmap.md: one of the cycle's own files (use --check-write)`.
- **Dotfiles.** The test `"$a" == */.*` (`:413`) matches any component that starts with `.`, including the file name. So `docs/notes/.hidden.md`, which is not in a dot-directory, is refused with the reason text "dot-directories" (P3).

A precise version would read "(not the cycle's own files, working/, …, dev-cycle.md, any path component starting with ., or an instruction file)".

**Evidence:** `scripts/dev-cycle.sh:50-53,406-416`; `fcfull/p3.out`

---

## Claim 21: `--check-answer`: "<option> Q-NNN" … keep, drop, done, open (not marked ANSWERED yet) or unrecognized …; "skip Q-NNN: <reason>" when it cannot be read (the listed causes)

**Location:** `scripts/dev-cycle.sh:54-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the output forms on all 103 real IDs and eight synthetic entries. It does not establish the label parse's bold handling (Claim 33a).

P2's `answers:` line reads `3 done 19 drop 26 keep 13 open 42 unrecognized`, with `no skips` over 103 IDs. In P3, `drop Q-008` shows that a header with `**Status:** OPEN · **Status:** ANSWERED  ` counts as answered, and `keep Q-006` reads `Q-006: keep — fine`.

**Evidence:** `scripts/dev-cycle.sh:496-515`; `fcfull/p2.out`; `fcfull/tmp.2ZTplJGLcm/answers.txt`; `fcfull/p3.out`

---

## Claim 22: "--check-brief and --check-branch need a default branch found by name (origin/HEAD, main or master): they read its commit." (with the code comment at `:539-541`: "the other modes do not use it")

**Location:** `scripts/dev-cycle.sh:66-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers a repo whose only branch is `trunk`. It does not establish the origin/HEAD path (bats test 388).

P3, with only `trunk`: `--check-brief needs a default branch (origin/HEAD, main or master); found none`, rc 1. `--check-path` gives rc 0. The digest gives rc 0 with 8 sections `` on `trunk` at 99bfd78 ``, through the current-branch fallback (`:531-537`).

**Evidence:** `scripts/dev-cycle.sh:518-544`; `fcfull/p3.out`

---

## Claim 23: "Every revisit trigger is printed every run (an output line over 4096 bytes is cut); nothing carries forward. … Read-only: writes nothing to the repo (one temp file, removed on exit)."

**Location:** `scripts/dev-cycle.sh:69-72`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers this repo's 11 trigger records and 11 revisit log rows, and the clone's state after the digest and all six modes. It does not establish triggers written outside a `## Revisit triggers` section, which section 2's own text says are not found.

P2 reports `date map: 11 records` and `log rows printed 11; rows with revisit 11`. P5 reports `clone unchanged (status --ignored, refs, files newer than stamp)`. The only temp file is `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`:698`).

**Evidence:** `scripts/dev-cycle.sh:611-677,698`; `fcfull/p2.out`; `fcfull/p5.out`; `fcfull/tmp.YDaTXdsf51/before.txt`, `after.txt`

---

## Claim 24: "Exit: 0 digest printed (or, for the check modes, every argument answered: a skip is an answer, not an error); 1 bad usage, not a git repo, no perl, or no default branch (for the digest, --check-brief and --check-branch)"

**Location:** `scripts/dev-cycle.sh:73-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers bad usage, a skip, a non-repo and a missing default branch. It does not establish "no perl" (that branch, `:79`, was not run) or "a failed step exits non-zero mid-digest".

P3 results: `--sample=x rc=1`, `--since=2026-02-30 rc=1`, `--check-path (no arg) rc=1`, `--check-path nope.md (a skip) rc=0`, `not a git repo rc=1`, and `--check-brief` on trunk-only `rc=1`. The digest needs a default branch only when even the current branch fails (`:538`), which matches "(for the digest …)".

**Evidence:** `scripts/dev-cycle.sh:73-79,128-146,538-544`; `fcfull/p3.out`

---

## Claim 25: The scrub drops C0 controls but TAB and LF, DEL, C1, the bidi controls, U+2028/2029 and tag characters, and cuts lines over 4096 bytes; perl is pinned to bytes; deletion resumes 3 bytes back

**Location:** `scripts/dev-cycle.sh:80-93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the byte classes in the regex and `tr`, the cut, and the env pinning. It does not establish the listed "Not covered" classes, which are out of scope by the comment's own statement.

The code is `tr/\000-\010\013-\037\177//d;` followed by `/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xA8-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]/g` with `$i = $s > 3 ? $s - 3 : 0` (`:101-108`; excerpt ends inside `scrub()`, which continues to `:111` — read). `env -u PERL_UNICODE -u PERL5OPT -u PERLIO LC_ALL=C perl -C0` (`:96`). bats test 94 ("the scrub strips C0, C1, bidi and tag characters from stdout and stderr") passes (P1).

**Evidence:** `scripts/dev-cycle.sh:94-111`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 26: "Exit status: the body's (pipefail; scrub itself does not fail)"; "a redirected digest is complete when the script returns"

**Location:** `scripts/dev-cycle.sh:112-119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the outer pipeline and exit. It does not establish that the two streams interleave in any particular way (the comment disclaims this).

The code is `{ DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub` followed by `exit "${PIPESTATUS[0]}"` (`:121-122`). bats test 191 ("the exit status and the whole digest survive a redirect to a file") passes. P3's rc 1 cases also show the body's status propagating.

**Evidence:** `scripts/dev-cycle.sh:120-123`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 27: The plain-input rule: rawfile/plaindir refuse any symlink; "walking the path top down, the first part that exists but is not plain … blocks it. Nothing below a blocking part is probed"; "A newline in a name becomes a space"

**Location:** `scripts/dev-cycle.sh:149-183`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the digest's fixed inputs and globbed directories. It does not establish TOCTOU behaviour between the check and the read.

The test is `[[ "$r" == "$ROOT_REAL/$1" ]]` after `realpath -e` (`:152,155`). `blocker()` returns at the first non-plain part (`:165-169`). bats tests 126 and 157 pass ("no input is read through a symlink …"; "a symlinked directory is listed and nothing below it is read or probed; a newline in a skipped name stays on one line").

**Evidence:** `scripts/dev-cycle.sh:149-183`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 28: The path rule: form (letters, digits, `. _ - /`, `* ?` in a glob; not starting `/` or `-`; no empty, `.`, `..` or `.git*` component), scope, plain; "Globs are matched by git … never by a shell"; locale-independent character lists

**Location:** `scripts/dev-cycle.sh:188-199`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `pathform`, `matches` and the locale behaviour. It does not establish git's `:(glob)` semantics beyond the cases tested.

The code reads `[[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]]` (`:208`) and `spec=":(glob)$a"` (`:230`). bats tests 473, 553 ("does not warn per match under an uninstalled locale") and 565 pass.

**Evidence:** `scripts/dev-cycle.sh:200-242`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 29: The code-fence comment: only plain column-0 fences are read; anything else listed (indented or list-marker fence lines, `<` lines except a complete one-line comment, an open `<!--`, a reference definition behind `>` and list markers, an inner CR, a BOM on line 1) refuses the file, as does a fence open at the end

**Location:** `scripts/dev-cycle.sh:263-283`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `FENCE_AWK`'s rules as listed. It does not establish CommonMark agreement for the accepted inline class (decision log 69, out of scope by the brief). Linearity and the marker-strip equivalence were measured at pass 36 on this code (unchanged since).

The fence rules are `opens()` (column 0, ≥3, no backtick in a backtick info string), `closes()` (same character, ≥ length, trailing blanks only), and `fenceish()`/`rawhtml()`/`opencomment()`/`refdef()` (`:286-311`). The order of checks is in `fence()` (`:312-327`). bats tests 779, 823, 883 and 903 pass (P1).

**Evidence:** `scripts/dev-cycle.sh:263-327`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 30: A brief's state "read only from the default branch's commit (never the working tree): its first line outside a ``` or ~~~ fence that starts with 'Status:', which must be exactly 'Status: open|done|dropped'"

**Location:** `scripts/dev-cycle.sh:339-345`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the reader and its source (`git cat-file blob "$MAIN_SHA:$a"`). It does not establish behaviour for a brief committed as a symlink on the default branch (a mode-120000 blob would be read as its target text and would skip for lack of a Status line; not run).

The rule is `!seen && /^Status:/ { seen = 1; if ($0 ~ /^Status: (open|done|dropped)$/) st = $0 }` (`:360`). P3's fenced brief reads `open` (the fenced `done` is ignored). bats test 713 ("reads the status line from the default branch only") passes.

**Evidence:** `scripts/dev-cycle.sh:346-366`; `fcfull/p3.out`

---

## Claim 31: The commit printed is "the default branch's own commit (first-parent history, a merge diffed against its first parent) that last added or removed a line starting 'Status: '": a merge commit, the branch's own commit after a fast-forward, a quoted line or a move

**Location:** `scripts/dev-cycle.sh:367-371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the `git log -G` query and the cases bats pins. It does not establish when the `:373` fallback (the last commit touching the file) fires; I found no reachable case, and it is not documented in the help.

The query is `git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a"` (`:372`). bats tests 796 ("names the commit that set its status") and 842 ("names the merge that brought a status change in, and reads closed/ briefs") pass.

**Evidence:** `scripts/dev-cycle.sh:367-374`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 32: check_branch comment: the commit comes from show-ref at exactly refs/heads/<name>; "0: none, as for a fresh branch or one merged with a merge commit; a squash-merged branch keeps its count"; the date is the tip's committer date, "a future date is possible"

**Location:** `scripts/dev-cycle.sh:376-383`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the count and date fields. The squash case is from reading `rev-list --count MAIN..sha` and was not run.

The output is `` echo "ok $a $sha $(git rev-list --count "$MAIN_SHA..$sha") $(git log -1 --format=%cs "$sha")" `` (`:393`). P2's `feat/x` is at 6872fc7, an ancestor of main 2fd9401, and prints count `0`. bats test 731 ("counts the branch's own commits") passes.

**Evidence:** `scripts/dev-cycle.sh:384-396`; `fcfull/p2.out`

---

## Claim 33a: "Its text starts after the label: at ':**' when the label alone is bold, else at the first ': ', and then ends at the bold's close if it opened inside the bold."

**Location:** `scripts/dev-cycle.sh:436-438`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the second branch (the label is not `**Answer:**`-style, so there is no `:**` before the first `": "`). It does not establish the first branch, which is correct (`**Answer:** **[2]**` reads `drop`), or any real file, none of which has the failing shape.

**Behavioral.** In the code, the text ends at the first `**` after `": "` whether or not a bold opened inside the label and is still open:

```awk
# scripts/dev-cycle.sh:483-485
  } else if ((c = index(rest, ": ")) > 0) {
    rest = substr(rest, c + 2)
    if ((e = index(rest, "**")) > 0) rest = substr(rest, 1, e - 1)
```
(excerpt ends :485; the enclosing `!done` rule continues to `:488` with `result = option(rest); done = 1` — read)

With `**Answer (2026-10-02)**: **[2]**`, the label's bold closes at `)**`, before the colon, so by the comment the text is `**[2]**`. `option()` strips the leading `*` (`sub(/^[ \t*]+/, "", s)`, `:445`) and returns `drop`. The code instead cuts `rest` at index 1 and passes `""`. P3 confirms `unrecognized Q-001` (`**Answer (2026-10-02)**: **[2]**`) and `unrecognized Q-002` (`**Answer (2026-10-02)**: **drop** because`). Whole-line bold works as the comment intends: `drop Q-003` for `**Answer (2026-10-02, chat): [2] drop.**`.

Effect, from the skill: an `unrecognized` answer goes to the record and the final message, the ID is added to `Applied:`, and the user is asked again on the next keep-or-drop entry (`SKILL.md:294-297`). It costs one extra question; nothing is closed wrongly. Severity: Low.
- Preconditions: a recorder writes a parenthesised label whose bold closes before the colon, then bolds the answer.
- Real files: none has it (`grep -E '^(- )?\*\*Answer[^:]*\*\*: \*\*'` finds 0 matches in both questions files).

The fix is either to cut only when the `**` count before `": "` is odd, or to say in the comment that the text ends at the first `**` after `": "`.

**Evidence:** `scripts/dev-cycle.sh:436-438,444-457,475-488`; `skills/dev-cycle/SKILL.md:294-297`; `fcfull/p3.out`

---

## Claim 33b: ANSWER_AWK's other rules: answered only when the header's " · "-separated field trims to `**Status:** ANSWERED` ("the last Status field counts, as in questions.sh"); the answer is the first line, outside fences, starting (after an optional "- ") with `Q-NNN:` or a bold `**Answer:` / `**Answer (` / `**Answered` label (any case); "Only the text's leading token decides" ([1]/1/keep, [2]/2/drop, [3]/3/done; a word followed by the end, punctuation or a dash)

**Location:** `scripts/dev-cycle.sh:417-441`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the gate, the label set and the leading-token rule on synthetic and real entries. It does not establish the bold-close cut (Claim 33a).

The header rule takes the last field: `for (i = 1; i <= n; i++) { … if (substr(f, 1, 12) == "**Status:** ") v = substr(f, 13) }` (`:471`). questions.sh likewise overwrites `status` per field (`if (f[i] ~ /^Status:/) { status = substr(f[i], 9) }`, `scripts/questions.sh:179`). P3 results: `drop Q-008` (`**Status:** OPEN · **Status:** ANSWERED  `), `done Q-005` (`- **Answered 2026-10-02:** [3]`), `keep Q-006` (`Q-006: keep — fine`) and `drop Q-007` (`[2] see **note**`). P2: 103 real IDs read with no skips. bats tests 600, 625, 685, 746 and 856 pass.

**Evidence:** `scripts/dev-cycle.sh:443-495`; `scripts/questions.sh:170-182`; `fcfull/p3.out`; `fcfull/p2.out`

---

## Claim 34: The date map: "Each record's last commit date, from one path-limited walk … Around merges the date can differ from per-file `git log -1`, in either direction … It is always a real commit on this branch that touched the record"

**Location:** `scripts/dev-cycle.sh:618-627`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers agreement with per-file `git log -1` on this repo's 11 trigger records. It does not establish the stated merge-edge differences, which were shown in the pass-18/19 probes (cited in the rubric) and are disclosed here.

P2 reports `date map: 11 records, 0 differ`. bats test 243 ("record dates match per-file git log for quoted names and a merge-resolution change") passes.

**Evidence:** `scripts/dev-cycle.sh:628-651`; `fcfull/p2.out`

---

## Claim 35: "### <record> (last committed on this branch: <date>)" and "docs/roadmap.md last committed on this branch: <date>"

**Location:** `scripts/dev-cycle.sh:649` (also `:731`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers which git date is printed. It does not establish any effect on a skill step: the skill uses these dates only as evidence and never compares them with the window.

Wording, not behaviour. The date is the last commit's **author** date: `--format='@%ad' --date=short` for the map (`:631`), `--format=%ad --date=short` for the fallback (`:646`) and for the roadmap (`:730`). The window, by contrast, filters on the committer date (`%cs`, `:603,606`).

In P4, a commit authored 2026-01-05 and committed 2026-10-02 (as after a rebase or cherry-pick) is counted in the window (`1 commit(s) reachable from it`). Both lines still print `last committed on this branch: 2026-01-05`. "Last committed" should say "last changed (author date)", or the code should use `%cd`/`%cs`.

**Evidence:** `scripts/dev-cycle.sh:603-606,628-651,730-731`; `fcfull/p4.out`

---

## Claim 36: Section 6: "A merge whose diff against its first parent touches files but no doc (a path under docs/, a *.md file, or a file named README or README.*, all any case) … Listed up to 30."

**Location:** `scripts/dev-cycle.sh:741-743`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the doc classification and the cap. It does not establish that a flagged merge truly lacks documentation, which is a judgment the skill's step 4 makes.

The code is `p ~ /^docs\// || p ~ /\.md$/ || b == "readme" || index(b, "readme.") == 1` on lowercased paths (`:747`) and `printf '%s\n' "${flagged[@]:0:30}"` (`:754`). P2's `--since=2026-09-01` run lists 30 merges and then `… 1 more`. Each listed `Merge branch 'feat/dev-cycle-digest' into feat/dev-cycle (2 file(s), no doc change)` brought only the script and the bats file. bats test 416 passes.

**Evidence:** `scripts/dev-cycle.sh:740-756`; `fcfull/tmp.2ZTplJGLcm/digest-sep.md`

---

## Claim 37: Section 7: "Every file any first-parent commit in the window touched (a merge counts its diff against its first parent), not a net diff"; the label "Decision records added or changed on `main` in the window"

**Location:** `scripts/dev-cycle.sh:759-771`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the listing rule and the counts. It notes that a record deleted in the window is also listed (P3: `docs/decisions/002-b.md` after `git rm`), which I read as a change. It does not establish whether any listed record is a "major design decision" (the skill's judgment).

The query is `git … log "$MAIN_SHA" --first-parent --diff-merges=first-parent --name-only --format='@%cs' -- skills workflows docs/decisions` (`:764`). P2 prints 48 skill/workflow files and 16 records (default window). bats test 441 ("changed and reverted inside the window: still a change") passes.

**Evidence:** `scripts/dev-cycle.sh:764-776`; `fcfull/p2.out`; `fcfull/p3.out`

---

## Claim 38: "The skill's step 5 appends '## Brainstorm YYYY-MM-DD' …; seeding appends '- <idea> (signal: …)' lines, and only lines of that shape count."

**Location:** `scripts/dev-cycle.sh:791-796`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the count after the last brainstorm heading and the shape test. It does not establish that agents write that shape (the skill instructs it, `SKILL.md:107-110`).

The test is `/^- [^ ]/ && index(substr($0, 4), "(signal: ") && /\)[[:space:]]*$/ { c++ }`, with `c = 0` reset at each `## Brainstorm DATE` (`:796`). bats test 441 ("prints the step 4b and step 5 inputs") passes.

**Evidence:** `scripts/dev-cycle.sh:789-807`; `skills/dev-cycle/SKILL.md:107-110`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 39: "**Build-loop policy** (`self-merge` or `review`; codebase onboarding's step 13 asks the user for it): recorded for the build-loop handoff, which this skill does not run yet. This skill does not read it."

**Location:** `skills/dev-cycle/SKILL.md:56-58`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers the step reference and that no other skill step reads the policy. It does not establish the handoff unit, which is not built.

Step 13 is `### 13. Gate — validate with the team` (`workflows/codebase-onboarding.md:447`), and its policy paragraph is at `:453`. "Build-loop policy" occurs in the skill only in the template line (`:48`) and this bullet (paraphrased — no quote available because the claim covers absence: `grep -n 'Build-loop policy\|self-merge' skills/dev-cycle/SKILL.md` gives only `:48` and `:56`).

**Evidence:** `skills/dev-cycle/SKILL.md:48,56-58`; `workflows/codebase-onboarding.md:447-457`

---

## Claim 40: The Rules' check interface: `--check-path` (tracked + ignored under docs/working/, at most 50, never a symlink, directory, `.`/`..`, `.git*` or other untracked file); `--check-write` "allows only those files"; `--check-fix`'s list; `--check-brief`'s outputs; the briefs glob lists only unmoved briefs; `--check-branch`'s output; "A check that exits non-zero (no default branch, say)"

**Location:** `skills/dev-cycle/SKILL.md:61-102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers each check output and refusal the paragraph names. Unlike the help (Claim 20), the skill's `--check-fix` list includes "the cycle's own files". It does not establish the slot rule's correctness as a policy, or that agents follow it.

The skill's `--check-fix` exclusions are "not the cycle's own files, `docs/working/`, `docs/human-author/`, `docs/reviews/`, `docs/decisions/`, `docs/dev-cycle.md`, a dot-directory or an instruction file" (`:72-75`). The code adds dotfiles (Claim 20's second point), which is still wording only. The rest of the check outputs match P2 and P3, as cited in Claims 17–22. bats test 671 ("closed briefs move out of the glob") passes.

**Evidence:** `skills/dev-cycle/SKILL.md:61-102`; `fcfull/p2.out`; `fcfull/p3.out`

---

## Claim 41: Step 0: the digest "reads the window start, triggers, questions, roadmap and idea log from that working tree … It is read-only. Its sections feed the steps: 1 activity …, 2 triggers …, 3 watched questions …, 4 spot-check sample and 6 merges with code but no docs …, 5 roadmap …, 7 inputs …, 8 skipped inputs"; "If the digest says the repo has no `docs/working/questions.md`"

**Location:** `skills/dev-cycle/SKILL.md:130-139`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the section numbering and names, the read-only behaviour and the absent-questions message. It does not establish the cycle's handling of each section.

P2 prints exactly `## 1. Activity` … `## 8. Skipped inputs`. The Window line reads "Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree." (`scripts/dev-cycle.sh:596`). Read-only is Claim 23 (P5). The absent case prints `No docs/working/questions.md in this repo.` (`scripts/dev-cycle.sh:692`).

**Evidence:** `skills/dev-cycle/SKILL.md:130-139`; `scripts/dev-cycle.sh:596,692`; `fcfull/p2.out`

---

## Claim 42: Window-line checks: "It says 'records, or a directory above them, were skipped', or names a newer record that was skipped"

**Location:** `skills/dev-cycle/SKILL.md:141-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the quoted phrases against the digest's source notes. It does not establish the user-side "last cycle you know ran" judgment.

The digest's notes are "`no readable cycle record (records, or a directory above them, were skipped as not a plain file or directory: section 8)`" (`scripts/dev-cycle.sh:587`) and "`a newer record, docs/working/cycles/cycle-$skipped_record.md, was skipped`" (`:582`). bats test 271 ("a skipped newer cycle record is named in the window line") passes.

**Evidence:** `scripts/dev-cycle.sh:577-591`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 43: "`questions.sh init` (it creates only what is missing) and then `questions.sh archive` (it also reindexes)"

**Location:** `skills/dev-cycle/SKILL.md:164-165`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers both properties in questions.sh. It does not establish failure handling inside questions.sh.

`cmd_init`'s comment reads "Never touches a file that exists." (`scripts/questions.sh:418`). `cmd_archive` ends with `cmd_index` (`scripts/questions.sh:393`).

**Evidence:** `scripts/questions.sh:385-394,415-418`

---

## Claim 44: Step 2: "The digest prints every trigger in full: each decision record's `## Revisit triggers` section and each decision-log row that mentions revisiting (a trigger written elsewhere in a record is not found; an output line over 4096 bytes is cut …)"

**Location:** `skills/dev-cycle/SKILL.md:179-182`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers agreement with section 2's code and its printed header. It does not establish triggers outside that section.

`trig()` prints from `## Revisit triggers` to the next `## ` (`scripts/dev-cycle.sh:614`). Rows come from `grep -E '^\| [0-9]+ \|' … | grep -i 'revisit'` (`:662`). P2 prints all 11 rows.

**Evidence:** `scripts/dev-cycle.sh:612-677`; `fcfull/p2.out`

---

## Claim 45: Step 3: "Watched questions were NOT checked" with the cause "a skipped questions file or archive, questions.sh missing, or `questions.sh open` failing"

**Location:** `skills/dev-cycle/SKILL.md:200-203`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the four NOT-checked branches. It does not establish questions.sh's own failure modes.

The text is `nc="**Watched questions were NOT checked** —"`, used for a skipped questions file (`:690`), a missing `questions.sh` (`:694`), a skipped archive (`:696`) and an `open` failure (`:712`). bats tests 207 and 367 pass.

**Evidence:** `scripts/dev-cycle.sh:679-716`; `fcfull/tmp.8pIMBef4P6/bats.log`

---

## Claim 46: Step 5: "the digest's section 7 prints the counts and dates"

**Location:** `skills/dev-cycle/SKILL.md:233-234`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the Now count, the last brainstorm date and the seed count. Readiness and direction are judged by the skill, as it says.

P2 prints `- Roadmap Now: 2 item(s)`, `- Roadmap In flight: 0 item(s)`, `- Roadmap Next: 5 item(s)` and `- No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded`. The day count is `$(( ($(date -d "$TODAY" +%s) - $(date -d "$last_bs" +%s)) / 86400 ))` (`scripts/dev-cycle.sh:798`).

**Evidence:** `scripts/dev-cycle.sh:778-807`; `fcfull/p2.out`

---

## Claim 47: The brief-writing rules (plain column-0 fences; no line starting `<`; no open `<!--`; no line starting `[` behind any `>`/list markers that holds `]:` or leaves `[` open, counting `\]` as no close; no stray CR, no BOM) and "`--check-brief` prints a skip, naming the line, for a brief with any line it cannot trust (a few shapes these rules allow are also skipped …)"

**Location:** `skills/dev-cycle/SKILL.md:335-343`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the rules against `FENCE_AWK`'s refusals and the skip line's form. Pass 36's P4 already established that the shapes listed as "also skipped" are skipped. It does not establish the accepted inline class.

`refdef()` drops escapes before testing (`gsub(/\\./, "", l)`, `scripts/dev-cycle.sh:300`), so an escaped `\]` is not a close. P3's `<name>` brief is refused, naming `line 2`. The CRLF brief is read, because only a CR that does not end the line is refused (`if (index(l, "\r")) { refuse("cr")`, `:314`, after `{ sub(/\r$/, "") }`, `:358`).

**Evidence:** `scripts/dev-cycle.sh:285-327,357-364`; `fcfull/p3.out`

---

## Claim 48: "The next digest starts its window from this file's date (only the file name is read); if a cycle skips its record, the next window widens back to the older record (or to the 14-day default when there is none)"

**Location:** `skills/dev-cycle/SKILL.md:370-373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers window selection. It does not establish that the record is written.

The code is `d="${f##*/cycle-}"; d="${d%.md}"`; the file is never opened (`scripts/dev-cycle.sh:562`). bats test 279 ("the window defaults to the newest cycle record's date and says so") passes, and P2 shows the 14-day default when there is no record.

**Evidence:** `scripts/dev-cycle.sh:559-591`; `fcfull/p2.out`

---

## Claim 49: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched."

**Location:** `test/scripts/dev-cycle.bats:3-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the worktree's `git status --porcelain` before and after a full bats run. It does not establish untouched gitignored files.

P1 prints `worktree status unchanged` after `bats rc=0; 49 ok, 0 not ok`.

**Evidence:** `test/scripts/dev-cycle.bats:1-36`; `fcfull/tmp.8pIMBef4P6/status-before.log`, `status-after.log`

---

## Claim 50: Branch commit messages' test tallies (`16/16` … `49/49`, 40 commits from d9e4cb9 to dd1988d)

**Location:** commit messages `main..2fd9401` (e.g. dd1988d "49/49", 6f24d91 "48/48", b00c057 "44/44", d9e4cb9 "16/16")
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers that each stated N equals the `@test` count in `test/scripts/dev-cycle.bats` at that commit. It does not establish that every test passed at each historical commit, and the one non-tally match (89a3d3b "rows 65/66") is not a test count.

P6 prints 40 lines of the form `<sha> claims N/N; file has N`, every one equal.

**Evidence:** `fcfull/tmp.LVlUy91ri2/p6.log`

---

## Claim 51: Merge 2fd9401: "Brings in main's 13 commits since 4225753"; conflicts resolved "keeping both sides in order" (override log: dev-cycle rows, then run-tests-jobs rows; archive: Q-100, Q-099, Q-101, then Q-090; questions.md: Q-103 and Q-102); "indexes regenerated …; questions.sh check passes. Every merged question ID (103) reads with --check-answer, none skipped."

**Location:** commit 2fd9401 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each stated fact. It does not establish main's run-tests `--jobs` change itself, which is reviewed on main and only context here.

P2 results:
- the commit count: `main commits 4225753..bf54363: 13`;
- `questions.sh check rc=0`, and `index regeneration: no diff`;
- `IDs: 103` with `no skips`;
- archive headings at `1775:### Q-100`, `1798:### Q-099`, `1818:### Q-101` and `1839:### Q-090`; live headings at `45:### Q-103` and `62:### Q-102`.

The override log has the dev-cycle rows at its old end, then the 12 run-tests-jobs rows (`git diff 6872fc7 2fd9401`). There is no blank line inside the table, and the merged rows have the table's 6 cells.

**Evidence:** `docs/working/questions-archive.md:1775-1839`; `docs/working/questions.md:45,62`; `docs/reviews/override-log.md:178-195`; `fcfull/p2.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 33a** (`scripts/dev-cycle.sh:436-438`): **behavioral.** The answer text is cut at the first `**` after `": "` even when the label's bold closed before the colon. So `**Answer (DATE)**: **[2]**` reads `unrecognized`, not `drop`. Safe direction: the user is asked again. No real file has the shape. Fix the cut, or the comment.

### Stale
(none)

### Mostly Accurate
- **Claim 20** (`scripts/dev-cycle.sh:50-53`): **wording.** The `--check-fix` help omits the cycle's own files (`docs/roadmap.md` is refused) and says "a dot-directory" where the code refuses any path component starting with `.`, a dotfile included.
- **Claim 35** (`scripts/dev-cycle.sh:649`, `:731`): **wording.** "Last committed on this branch: <date>" prints the author date (`%ad`), not the commit date, so a rebased commit in the window can show a date months earlier.

### Unverifiable
(none)

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-devcycle/docs/reviews/code-fact-check-report-devcycle-fullreview-2026-10-02.md`. Its first line is `Commit: 2fd9401`, and its header carries `**Replication:** k=1 (full review; user's instruction)`. Every claim has the seven mandatory fields plus **Legibility-target**. For the user's goal (merge once a full pass finds no known issue), this pass does **not** come back clean: Claim 33a is a behavioral Incorrect, low severity and outside decision log 69's accepted class. Claims 20 and 35 are wording only.
