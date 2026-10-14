# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4c`)
**Scope:** full branch `git diff main...feat/build-loop-u4c` (HEAD 43b8d7ed): `skills/dev-cycle/SKILL.md`, `test/scripts/build-loop-orchestrator.bats`, `test/lib/d6-snippet.bash` (deleted), `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `docs/working/plan-build-loop-handoff.md`, `docs/reviews/override-log.md` (rows 812-819), `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md`, and the four commit messages (`git log main..HEAD`). The i1/i2 critic reports and logs are evidence; I did not check them line by line.
**Commit:** 43b8d7ed
**Replication:** final confirming pass, replicate r2 of k=3 (merged most-severe-wins)
**Checked:** 2026-10-13
**Total claims checked:** 49
**Summary:** 35 verified, 10 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) first. No claim below matches a logged pattern. None of the three Incorrect verdicts is a fabricated symbol, API or flag: all three are prose that misstates what the code does. So the log is unchanged.

I followed the shared preamble's prior-pass rule. Items the rubric already decided (B1-B5, C1-C11, D1-D9) and rows 735-744, 775 and 807-819 are not re-filed unless the code has changed their basis. Where I say so below, it has: Claims 5 and 8b.

**Execution logs** (all under `docs/reviews/execution-logs/`, cwd `/workspace/.claude/wt-build-loop-u4c`, run as uid 1000, times UTC on 2026-10-14):
- `u4c-final-r2-orchestrator-bats.log`: `timeout 600 bats test/scripts/build-loop-orchestrator.bats`, exit 0, ended 06:37:14Z. 26 of 26 ok, no skips, no `not ok`.
- `u4c-final-r2-image-checks.log`: step 0.1's commands, run read-only against MAIN_WT=/workspace with the Rules' `hg` line and the real `/opt/claude-workflows/.manifest` at 06:37:36Z. The paste's check half was appended at 06:44:02Z. The script exited 0.
- `u4c-final-r2-d6-real.log`: the D6 block extracted from SKILL.md with the test's own awk and run against the real image at 06:38:26Z (appended 06:38:34Z and 06:38:51Z). It covers four things: /opt files against C's blobs, `--help` through the block against a direct run, QUESTIONS_LIVE/ARCHIVE, and an exported `env` function.

---

## Claim 1: "Commit: f2cc21e6" (the rubric's first line)

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:1`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stamp against the code-review rubric contract and the i2 critics' own stamps. It does not establish that the D-table statuses, written in 43b8d7ed, were reviewed at f2cc21e6 (they describe 43b8d7ed's fixes).

The contract reads: "The file's first line is `Commit: <reviewed HEAD short SHA>`" (`skills/code-review/references/rubric.md:20`). The three i2 critic reports each begin `Commit: f2cc21e6` (`docs/reviews/security-review-2026-10-13-u4c-i2.md:1`, `api-consistency-review-…-i2.md:1`, `architecture-review-…-i2.md:1`). The rubric itself says "Critics over 1bc823ea..f2cc21e6" (`:66`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:1`, `:66`; `skills/code-review/references/rubric.md:20`

---

## Claim 2: "Row 817's 'only the D6 block, its Rules and step 0.1' also omits steps 0.4 and 1 and the deleted fallback (Mostly accurate; its conclusion holds; rows are append-only)"

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:63-64`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the list of SKILL.md regions U4c changed, as of HEAD. It does not re-verdict row 817's conclusion (still true: none of rows 808-811's paths, steps 0.2 and 7, changed).

The note was right at f2cc21e6. Commit 43b8d7ed then changed one more region that the note leaves out: step 9.1, which now adds "(`check` exiting 1 names entries to fix before staging)" (`skills/dev-cycle/SKILL.md:713`). Precise version: "also omits steps 0.4, 1 and 9.1 and the deleted fallback." The diff's hunks touch the Rules, the D6 block, step 0.1, step 0.4, step 1 and step 9.1, but not step 0.2 or step 7 (paraphrased — no quote available because this is a list of `git diff main...HEAD -- skills/dev-cycle/SKILL.md` hunk positions).

**Evidence:** `skills/dev-cycle/SKILL.md:713`; `docs/reviews/override-log.md:817`

---

## Claim 3: "security (… 1 Medium, 1 Low, 2 Informational …), api-consistency (… 3 Inconsistent, 2 Minor, 1 Informational, none Breaking), architecture (… 2 Coupling, 2 Minor)"

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:67-70`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the three severity tallies against each i2 report's `**Severity:**` lines. It does not cover the findings' content.

The security tally matches: Medium, Low, Informational, Informational (`security-review-2026-10-13-u4c-i2.md:51`, `:65`, `:79`, `:91`). So does api-consistency: three Inconsistent, two Minor, one Informational (`:40-112`). The architecture report has five findings, not four. Its fifth is `#### 5. i1 Coupling finding 1 is resolved in substance` / `**Severity:** Informational` (`architecture-review-2026-10-13-u4c-i2.md:105-107`). The other two tallies count their Informationals, so this one should read "2 Coupling, 2 Minor, 1 Informational".

**Evidence:** `docs/reviews/architecture-review-2026-10-13-u4c-i2.md:31`, `:49`, `:71`, `:85`, `:107`; `docs/reviews/security-review-2026-10-13-u4c-i2.md:51-91`

---

## Claim 4: Rubric D1-D7 "Fixed" statuses

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:74-80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each Fixed status against SKILL.md and the plan at 43b8d7ed, with D1's and D2's mechanisms executed. It does not establish that the fixes are sufficient. D8 and D9 are covered by Claims 5 and 8.

- D1: SKILL.md says "if `hg -C MAIN_WT merge-base --is-ancestor C M` exits 1, the gate that runs was built off main: file one `you: judgment` entry `image-off-main`" (`SKILL.md:288-290`). The paste is `cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh` (`:295-296`). Executed: `is-ancestor C M exit=0` today, and `is-ancestor M C exit=1`, which shows the exit-1 branch is reachable.
- D2: the paths sit on one line, `` `scripts/build-loop.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/` `` (`:292`), and a test pins it (Claim 43, which passed).
- D3: the entry holds "C, M, the changed names … and the paste … interim: the image's gate runs. Exit 0: an open `image-lag` entry is answered `done …`" (`:294-298`). Plan `:356` says "U5 makes the release entry the `image-lag` entry's body".
- D4: SKILL.md now says "differs from main's" (`:293`), and the cat-file-fails case has its own branch (`:287-288`).
- D5: "(a `refuse d6:` naming a missing image file means an image older than this skill: its entry also gives the release paste below)" (`:283-284`).
- D6: "no repository file or state a build loop writes chooses which script runs as the gate" (`:42-43`).
- D7: `:713` (Claim 37).

**Evidence:** `skills/dev-cycle/SKILL.md:42-43`, `:283-299`, `:713`; `docs/working/plan-build-loop-handoff.md:356`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`, `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 5: "D9 | A fork holding C compares unrelated gate code (noise); deleting C's objects drops the check to a record note"

**Location:** `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:82`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the deletion half, checked against step 0.1 at 43b8d7ed. It does not re-open D9's Won't-Fix decision (the deletion is the Q-103 hostile class); only the description of the consequence is wrong. The fork half is Claim 8a.

The code has changed the basis of this row. Security i2 described f2cc21e6, where a failed `cat-file` fell to "any other exit: note it in the record" ("the check degrades to a record note", `security-review-2026-10-13-u4c-i2.md:111`). Commit 43b8d7ed, the same commit that wrote this D9 row, changed that branch to:

```
# skills/dev-cycle/SKILL.md:287-288
M main's commit. If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, the image was not
built here: skip silently.
```

So deleting C's objects now drops the check with no record note at all. Executed: `cat-file -e` of a commit the repository lacks exits 128 with `fatal: Not a valid object name …` (`u4c-final-r2-image-checks.log`), which takes the silent branch. Precise version: "deleting C's objects skips the check silently (no record line)".

**Evidence:** `skills/dev-cycle/SKILL.md:287-288`; `docs/reviews/security-review-2026-10-13-u4c-i2.md:111`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`

---

## Claim 6: Override rows 812-818 and every row number the branch cites

**Location:** `docs/reviews/override-log.md:812-818`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each cited row number against that line of `override-log.md` (819 lines). It covers the row numbers in SKILL.md's changed text, the plan's U4c note, the rubric, the GATE_CODE comment and the commits. Row 739 in 1bc823ea is the decided exception (row 812). It does not re-verdict rows 812-816's decisions. Rows 817 and 819 are Claims 7 and 8.

Every citation lands on its subject:
- 548 is "dev-cycle.sh runs neither state_gate nor default_gate".
- 704 is "`--state`'s ok does not make the orchestrator's own plain git calls safe".
- 735 is the `refuse d6: WHY` row.
- 736 and 737 are the HARDEN wrapper and precedence rows.
- 738 is "The canonical D6 source sits in test/lib/".
- 739 is "The snippet chooses main's copy from the repository's own data".
- 740 and 741 are the verified reader's cost and its perl seam.
- 742 is the environmental refusals row.
- 744 is "The snippet has no timeout".
- 775 is "`questions.sh` … run through `~/.claude/scripts`".
- 807-811 are the U4b2 confirm3 rows.
- 812-819 are this branch's eight rows, dated 2026-10-13 under `feat/build-loop-u4c` (sed of each line).

The facts in rows 812-818 also hold:
- 813: the block's git checks are the only state gate questions.sh has (Claim 26).
- 815: nine `own` calls per run, four files plus five directories (`SKILL.md:241-246`).
- 816: questions.sh's hints print `QS_CMD='~/.claude/scripts/questions.sh'` (`scripts/questions.sh:74`).

**Evidence:** `docs/reviews/override-log.md:548`, `:704`, `:735-744`, `:775`, `:807-819`; `scripts/questions.sh:74`

---

## Claim 7: "Re-keys rows 808-811 …: U4c changed only the D6 block, its Rules and step 0.1, none of those paths"

**Location:** `docs/reviews/override-log.md:817`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the "only" list. It does not re-file the row: i2 already rated it Mostly accurate and rows are append-only. The conclusion "none of those paths" holds.

U4c also changed step 0.4, step 1 and (in 43b8d7ed) step 9.1, and it deleted the by-hand fallback (Claim 2). None of these is step 0.2 or step 7, where rows 808-811's paths live (paraphrased — no quote available because this is a list of diff hunk positions).

**Evidence:** `docs/reviews/override-log.md:817`; `skills/dev-cycle/SKILL.md:354-358`, `:379-386`, `:713`

---

## Claim 8a: "In a fork that holds the image's commit, step 0.1 compares unrelated gate code and files an image-lag entry a rebuild cannot clear"

**Location:** `docs/reviews/override-log.md:819`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the fork case against step 0.1's branch order at 43b8d7ed. It does not cover how often forks occur.

This row was written in 43b8d7ed (git blame), alongside the new `image-off-main` branch. The diff and the `image-lag` entry now run only "Else", that is, when `merge-base --is-ancestor C M` does not exit 1 (`SKILL.md:288-290`). A fork whose main does not descend from C files `image-off-main` (`you: judgment`), not `image-lag`. In the descending case the paste's `test "$(git rev-parse HEAD)" = M` cannot pass in claude-workflows' host checkout A, so "a rebuild cannot clear" holds. Precise version: "files an image-lag entry (when C is on the fork's main; otherwise image-off-main)".

**Evidence:** `skills/dev-cycle/SKILL.md:288-296`; `docs/reviews/override-log.md:819`

---

## Claim 8b: "deleting C's objects turns the check into a record note"

**Location:** `docs/reviews/override-log.md:819`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the deletion consequence at 43b8d7ed. It does not challenge the Won't-Fix decision. The row is append-only, so the fix is an amending row (or the rubric's D9 status), not an edit.

This is the same mismatch as Claim 5. The row carries forward the f2cc21e6 wording, but the commit that wrote the row changed the branch to "If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, the image was not built here: skip silently" (`SKILL.md:287-288`). Executed: a missing commit makes `cat-file -e` exit 128, which is the silent-skip branch, not "any other exit: note it in the record" (`:298-299`). A reader would expect a record trace that never appears.

**Evidence:** `skills/dev-cycle/SKILL.md:287-288`, `:298-299`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`

---

## Claim 9: "D6 runs the image copy built from main (Q-140 [1]), so it is live at the next release, not the next merge; it stays on this list by choice, since a release review is a skim (F58)"

**Location:** `docs/working/plan-build-loop-handoff.md:71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the image is built from, plus the F58 reference. It does not establish what the release review is worth.

install.sh stages `commit="$(head_commit)"`, where `head_commit` runs `repo_git rev-parse --verify -q 'HEAD^{commit}'` (`devcontainer-config/install.sh:335`, `:185-186`). That is the host checkout's HEAD, not main, and it is why step 0.1 now files `image-off-main` (`SKILL.md:285`: "the image is the gate, built from the host checkout's HEAD"). "Live at the next release" and F58 ("Self-mergeable code reaches running sessions through a release you skim", plan `:176`) are right. Precise version: "the image copy, built from the host checkout's HEAD (step 0.1 checks it is on main)".

**Evidence:** `devcontainer-config/install.sh:185-191`, `:329-361`; `skills/dev-cycle/SKILL.md:285`; `docs/working/plan-build-loop-handoff.md:71`, `:176`

---

## Claim 10: "The snippet is inline in the installed SKILL.md, which is the root-owned image copy. It never trusts a file the uid can write:"

**Location:** `docs/working/plan-build-loop-handoff.md:77`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the "never trusts" invariant on the D6 heading line, which this branch rewrote. It does not dispute the narrow property that no uid-writable file chooses which script runs (Claim 23).

The block's own header states the opposite:

```
# skills/dev-cycle/SKILL.md:203-205
# scripts). It still trusts that entry and the default branch's ref for which repository
# and branch the script reads (a moved main is --main-log's to report), and it
# cannot guard against this uid's own shell (PATH, exported functions): the
```

The checkout's `.git` entry and `refs/heads/main` are files the uid can write. Every `g …` call in the block resolves the repository through them (`SKILL.md:233-239`). The plan's own as-built note says "the header again names the trusted `.git` entry" (plan `:344`). The heading line was rewritten in this branch ("The gate runs from the root-owned image copy …"), but the sentence after it was kept. A reader acting on it would take the `.git` entry and the default branch's ref as checked, which i1 C1 restored to the header precisely to correct. Precise version: "No file the uid can write chooses which script runs; it trusts the checkout's `.git` entry and the default branch's ref for which repository and branch the scripts read." Confidence is Medium on whether a reader of the plan, not the header, is misled.

**Evidence:** `docs/working/plan-build-loop-handoff.md:77`, `:344`; `skills/dev-cycle/SKILL.md:203-205`, `:233-239`

---

## Claim 11: D6 bullets: the F38 refusal; "Superseded by Q-140 [1] … it extracts nothing from MAIN_SHA, so the two bullets above and this bullet's root-commit test no longer apply"; "The digest runs the same way"

**Location:** `docs/working/plan-build-loop-handoff.md:78-82`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each bullet against the block at 43b8d7ed. It does not cover the "As first written" history beyond its being superseded.

- The block lists `refs/replace/` and refuses on non-empty output, and refuses an existing `info/grafts` (`SKILL.md:233-236`). Test 13 exercises both (ok).
- The block has no `cat-file blob`, `ls-tree`, `mktemp` or `D6_ROOT`; test 11 greps for exactly these (ok).
- The digest goes through the same block: `dev-cycle.sh` is one of the three SCRIPT values (`:231`). Test 12 shows main's and the working tree's copies never run.

**Evidence:** `skills/dev-cycle/SKILL.md:231-247`; `test/scripts/build-loop-orchestrator.bats:255-261`, `:282`; `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 12: F39 "`/opt/...` by absolute path with an ownership check, in every repository (Q-140 [1]; the root-commit choice is gone) (T37)"; F40 "Nothing is extracted: the image copy's own layout, its four files checked (T33, T36)"

**Location:** `docs/working/plan-build-loop-handoff.md:157-158`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both rows against the block and the named tests. It does not establish the directory walk's failure cases (row 814, deferred).

The launch line is `bash "$D6_OPT/scripts/$s" "$@"` with `D6_OPT=/opt/claude-workflows` (`SKILL.md:247`, `:223`), and it has no repository condition. Test 15 (T37) runs the real `/opt` copy and matches its `--help` (ok). Test 16 refuses a uid-owned copy (ok). The four files are checked in `for f in build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh; do own …` (`:243-245`). T36 covers a missing file and a non-regular file (test 13, ok).

**Evidence:** `skills/dev-cycle/SKILL.md:223`, `:243-247`; `test/scripts/build-loop-orchestrator.bats:282-297`, `:312-326`; `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 13: The U4c as-built note

**Location:** `docs/working/plan-build-loop-handoff.md:344`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the note's statements against the code, tests and override rows at 43b8d7ed, plus the 774a0eef claim, which I executed. It does not cover i2's changes, which the note does not mention (image-off-main, the paste's HEAD test, the pin test). That is an omission, not a false statement.

- "Once the four files are regular, root-owned, not symlinks and not writable, and so is every directory up to `/`": `own()` plus `[[ -f … ]]` and the walk (`SKILL.md:229`, `:243-246`).
- "The verified reader, D6_ROOT, the temp dir and the SHA-1 branch are gone": test 11's grep (ok), and `test/lib/d6-snippet.bash` is deleted.
- "row 744's timeout is the Rules' stop": the Rules say "a call of any script that the Bash tool timed out … are stops too" (`:50-51`).
- "SCRIPT may now also be `questions.sh` (row 775)": `:231`.
- "T33 asserts it appears once and holds no reader commands; the run test shows main's and the working tree's copies have no effect": tests 11 and 12.
- "a missing image file is refused as missing": `own() { [[ -e "$1" || -L "$1" ]] || no "$1 is missing"; …` (`:229`), with test 16 unstubbed.
- "the launch drops QUESTIONS_LIVE/QUESTIONS_ARCHIVE": `:247`, executed in Claim 28.
- "the image at the time of writing (774a0eef) predates U4a's `--land-cycle`": `grep -c -- land-cycle /opt/claude-workflows/scripts/build-loop.sh` printed 0, against 15 in the branch's copy, and the manifest's `commit=774a0eef…` (`u4c-final-r2-image-checks.log`). The `grep -c` counts are paraphrased (no quote available because they were run at the prompt and not captured to a log file; the manifest line is in the image-checks log).
- Row numbers: Claim 6.

**Evidence:** `skills/dev-cycle/SKILL.md:50-51`, `:229-247`; `test/scripts/build-loop-orchestrator.bats:255-280`, `:320-326`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`, `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 14: "The gate needs it too (D6 runs the image copy: Q-140 [1]) … Since U4c, step 0.1's `image-lag` entry is that release entry's trigger: U5 makes the release entry the `image-lag` entry's body (one slug, one paste), not a second entry."

**Location:** `docs/working/plan-build-loop-handoff.md:356`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the present-tense parts: D6 runs the image copy, and step 0.1 files a `you: terminal` `image-lag` entry with one paste. The U5 part is a plan for later work, so it is not checkable now.

SKILL.md: "File one `you: terminal` entry `image-lag` (an open one has its body rewritten) holding C, M, the changed names … and the paste" (`:293-296`). The launch runs `$D6_OPT/scripts/$s` (`:247`).

**Evidence:** `skills/dev-cycle/SKILL.md:247`, `:293-296`

---

## Claim 15: T33 row "runs the image copy's four files (build-loop.sh and dev-cycle.sh with their own lib, dev-cycle.sh with its own `questions.sh`); main's and the working tree's copies have no effect; SKILL.md holds the block once (its one copy)"

**Location:** `docs/working/plan-build-loop-handoff.md:396`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the row against tests 11 and 12, which passed. It does not establish that dev-cycle.sh's lib was the image's from that test's stderr (only build-loop.sh's stderr lines are checked). Main's and the working tree's libs are `exit 9` stubs, which would fail the run, and dev-cycle.sh sources only `$SCRIPT_DIR/lib/dev-cycle-read.sh` (`scripts/dev-cycle.sh:95-103`).

Test 12 makes every main and working-tree copy `echo main copy; exit 9` or `echo working copy; exit 9`. It then asserts these four things (`bats:263-280`):
- each stderr line of `build-loop.sh --settings` is `lib at $U/scripts/lib/dev-cycle-read.sh`;
- `dev-cycle.sh` lists `- Q-001  trigger  from-opt`, the stand-in image's questions.sh;
- `questions.sh open` prints `Q-001  trigger  from-opt`;
- status 0 throughout.

Test 11 asserts exactly one `cd WT && bash -s …` line and one `^D6$` line (`:256-257`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:255-280`; `scripts/dev-cycle.sh:95-104`, `:389-390`; `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 16: "Since Q-140 [1] the gate waits too (D6 runs the image copy); step 0.1 files an `image-lag` entry when main's GATE_CODE paths differ from the image's `.manifest` commit."

**Location:** `docs/working/plan-build-loop-handoff.md:432`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the condition under which `image-lag` is filed. It does not cover the rest of the risk bullet (unchanged text).

Step 0.1 files `image-lag` only after two earlier branches pass: "If `… cat-file -e 'C^{commit}'` fails … skip silently. Else, if `… merge-base --is-ancestor C M` exits 1 … `image-off-main` … Else run `… diff --quiet C M -- PATHS`" (`SKILL.md:287-291`). Precise version: "when the repository holds the image's commit, that commit is on main, and main's GATE_CODE paths differ from it (off main: an `image-off-main` entry)".

**Evidence:** `skills/dev-cycle/SKILL.md:287-296`

---

## Claim 17: Rollback 1 "the gate that runs is the image's, so a revert of gate code takes effect only after the image is rebuilt from the reverted main (the host's `./devcontainer-config/install.sh`, then the next sandbox launch)"

**Location:** `docs/working/plan-build-loop-handoff.md:441`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the release path: install.sh stages claude-home and the Dockerfile copies it to /opt. It does not establish that install.sh runs cleanly on the host (host-only, interactive).

Each piece of the path:
- install.sh stages committed content into `claude-home` (`assemble "$stage/claude-home" …`, `install.sh:498`).
- The image is built with `COPY claude-home/ /opt/claude-workflows/` and then `chown -R root:root /opt/claude-workflows` (`devcontainer-config/Dockerfile:500`, `:517`).
- cc-isolated hashes `claude-home` at launch (`cc-isolated.sh:121`, `:151`).
- The launch runs `/opt/claude-workflows/scripts/$s` (`SKILL.md:247`).

**Evidence:** `devcontainer-config/install.sh:329-361`, `:498`; `devcontainer-config/Dockerfile:500-520`; `skills/dev-cycle/SKILL.md:247`

---

## Claim 18: store_check's comment no longer names the deleted snippet

**Location:** `scripts/build-loop.sh:1042-1043`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the removal of the stale reference, plus a repo-wide grep for `d6-snippet` outside `docs/reviews/` and `archive/`. It does not re-verify store_check's unchanged claims (rows 492, 503).

The comment now reads `# and have one copy each (rows 492, 503). git checks no hash when it reads an` (`:1043`). It no longer mentions the reader, which is gone. `rg d6-snippet` finds three kinds of hit. In tests there is only the absence assertion, `[ ! -e "$REPO_ROOT/test/lib/d6-snippet.bash" ]` (`bats:260`). The rest are dated history docs: `docs/working/merge-msg-build-loop-u3b3.md`, the checkpoint, and Q-140 in the archive.

**Evidence:** `scripts/build-loop.sh:1042-1050`; `test/scripts/build-loop-orchestrator.bats:260`

---

## Claim 19: "The scripts because the image copy built from main runs every merge after the next release (plan D6, D5 item 3; Q-140 [1]); skills/dev-cycle/ because its SKILL.md holds the D6 snippet that runs the gate (U4c; plan D4, F52). Both reach a session only from a release, so here the floor is stricter than D5."

**Location:** `scripts/lib/dev-cycle-read.sh:1962-1967`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the comment's reasons against the block and install.sh. It does not cover GATE_CODE's consumers (unchanged; test 19 pins the slug rule).

The mechanism is right. The scripts run from `/opt` (`SKILL.md:247`), and SKILL.md holds the block (`:195-251`). F52 is "A review merge changes the gate itself" (plan `:170`). "Built from main" has the same imprecision as Claim 9: install.sh builds from the host checkout's `HEAD^{commit}` (`install.sh:186`). Precise version: "the image copy, built from the host checkout's HEAD (step 0.1 flags one off main)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1962-1970`; `devcontainer-config/install.sh:185-191`; `docs/working/plan-build-loop-handoff.md:170`

---

## Claim 20: Rules "Every `build-loop.sh`, `dev-cycle.sh` and `questions.sh` call runs from WT (step 0's first two from MAIN_WT; step 7's self-merge from its GT, after a `--state` from MAIN_WT) as `cd WT && bash -s -- SCRIPT ARG... <<'D6'` …", and the call sites' consistency

**Location:** `skills/dev-cycle/SKILL.md:36-56`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the call sites in the changed text: step 0.1-0.2, step 0.4, step 1's `questions.sh init`/`archive`, step 7's `--merge` from GT, and step 9's `questions.sh index`/`check`. It does not cover other script calls in unchanged steps, beyond confirming that none names `~/.claude/scripts/`.

The call sites agree with the Rule:
- Step 0.1: "`--state`, run through the D6 block from the main worktree (… MAIN_WT …)" (`:279-280`).
- Step 0.2: "also from MAIN_WT" (`:300`).
- Step 0.4: "`dev-cycle.sh` through the D6 block from WT" (`:340`).
- Step 1: "run `questions.sh init` … and then `questions.sh archive` … through the D6 block from WT" (`:382-383`). Step 1 also keeps the stop: "(a `refuse d6:` line or a timed-out call is still a stop, as the Rules say)" (`:385-386`).
- Step 7: "`--state` (from MAIN_WT, whose config the add copies), then `hg -C MAIN_WT worktree add --detach GT`" (`:563-565`), with "`--merge BRIEF --expect TIP`, run from a gate checkout, not WT" (`:561-562`).
- Step 9: "after `questions.sh index` and `check` in WT" (`:712`). It names no runner, so the Rule's "Every … `questions.sh` call" governs it.

`rg '~/.claude/scripts'` in SKILL.md finds only the Rule's prohibitions (`:39`, `:60-61`) (paraphrased — no quote available because this is a grep over the whole file with no matches outside those lines).

**Evidence:** `skills/dev-cycle/SKILL.md:36-61`, `:279-300`, `:340`, `:382-386`, `:561-566`, `:711-713`

---

## Claim 21: "`questions.sh` never runs as `~/.claude/scripts/questions.sh` (a uid-owned link; its own hints still print that path)"

**Location:** `skills/dev-cycle/SKILL.md:60-61`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the link's ownership in this sandbox and the hint text. It does not establish the link's ownership in other sandboxes or on a bare host.

`ls -la ~/.claude/scripts` printed `lrwxrwxrwx 1 node node 29 Oct 13 13:18 /home/node/.claude/scripts -> /opt/claude-workflows/scripts`, a link owned by uid 1000 (node). The `ls` output is paraphrased (no quote available because the command was run at the prompt and not captured to a log file). The hints come from `QS_CMD='~/.claude/scripts/questions.sh'` (`scripts/questions.sh:74`), which is used in the check messages (`:279`, `:296`).

**Evidence:** `scripts/questions.sh:74`, `:279`, `:296`

---

## Claim 22: "The canonical copy: every run pastes the lines between the `bash -s` line and the `D6` line below, byte for byte (a test reads them from this file)."

**Location:** `skills/dev-cycle/SKILL.md:191-193`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the claim that the tests read the block from SKILL.md and that SKILL.md holds one copy. It does not establish that a run pastes it byte for byte (an instruction to the orchestrator).

`d6_copy` extracts it with `awk '/^## The D6 block$/ { s = 1 } s && b && /^D6$/ { exit } b { print } …'` from `$REPO_ROOT/skills/dev-cycle/SKILL.md` (`bats:236`). Every D6 test then runs that extract. I used the same awk for the real-image run, and `--help` through the block matched a direct run except for one setlocale warning line from the extra bash (`u4c-final-r2-d6-real.log`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:234-240`, `:255-261`; `docs/reviews/execution-logs/u4c-final-r2-d6-real.log`

---

## Claim 23: "It always runs the root-owned image copy under D6_OPT by absolute path, never main's copy, a working-tree copy or ~/.claude/scripts, so no repository data chooses which script runs"

**Location:** `skills/dev-cycle/SKILL.md:197-202`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the path that is run: a constant prefix plus one of three literal names. It does not cover the shell that resolves `env`, `bash` and `stat` (Claim 24), or what the scripts then read from the repository.

```
# skills/dev-cycle/SKILL.md:223, :231, :247
  D6_OPT=/opt/claude-workflows
  [[ "$s" == build-loop.sh || "$s" == dev-cycle.sh || "$s" == questions.sh ]] || { …; exit 1; }
  env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE bash "$D6_OPT/scripts/$s" "$@"
```

No git output feeds the path. Test 12 (stand-in image) and test 15 (real `/opt`) passed. The real run's `--help` matched a direct run of `/opt/claude-workflows/scripts/build-loop.sh`.

**Evidence:** `skills/dev-cycle/SKILL.md:222-247`; `docs/reviews/execution-logs/u4c-final-r2-d6-real.log`, `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 24: "It still trusts that entry and the default branch's ref for which repository and branch the script reads …, and it cannot guard against this uid's own shell (PATH, exported functions): the plan's same-uid residual (Q-103)"

**Location:** `skills/dev-cycle/SKILL.md:203-206`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both trust statements: the block resolves the repository from cwd, and an exported function reaches it. It does not enumerate every same-uid route (settings, for example).

Every check is `g …`, which is `"${G[@]}"`, starting with `env … git` run in the caller's cwd (`:226-227`). So the checkout's `.git` entry and `refs/heads/$m` choose what is read. Executed under bash: with an exported function `env() { echo "HIJACKED env $*" …; }`, the block's first `g for-each-ref` printed the function's output, and the block refused `refuse d6: a replace ref exists (F38)` with exit 2. So a same-uid exported function changes what the block does (`u4c-final-r2-d6-real.log`, 06:38:51Z). PATH lookups are the same kind of route: `env`, `stat` and `bash` are all bare names (`:226-229`, `:247`).

**Evidence:** `skills/dev-cycle/SKILL.md:226-247`; `docs/reviews/execution-logs/u4c-final-r2-d6-real.log`

---

## Claim 25a: The header's refusal list: replace ref, info/grafts, the default branch, a missing or non-regular image file, ownership, a failed git read, "1 for another first argument"

**Location:** `skills/dev-cycle/SKILL.md:211-217`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every `no …` call in `d6()` against the list, and each case's test. It does not cover the directory walk's refusal cases (row 814, deferred) or a root run (Claim 25b).

The `no` calls are:
- "is missing" and "is not root-owned, a plain path and unwritable here" (`:229`);
- "refs/replace could not be listed" and "the grafts path could not be read", the git-read failures (`:233`, `:235`);
- "a replace ref exists (F38)" and "info/grafts exists (F38)" (`:234`, `:236`);
- "the default branch is not exactly one of main and master" and "is a symbolic ref", both the "not exactly one plain main or master" case (`:238-239`);
- "names no commit" (`:240`);
- "is not a regular file" (`:244`).

The first-argument failure goes to stderr with `exit 1` (`:231`). The header lists every one of these, and no refusal is missing from it. Tests 13 and 16 passed, covering every refusal except the two git-read failures. Executed against the real block: `bash -s -- x` printed `d6: the first argument is build-loop.sh, dev-cycle.sh or questions.sh` with exit 1.

**Evidence:** `skills/dev-cycle/SKILL.md:211-246`; `test/scripts/build-loop-orchestrator.bats:282-297`, `:320-326`; `docs/reviews/execution-logs/u4c-final-r2-d6-real.log`

---

## Claim 25b: "(the -w test makes a run as root refuse unless the mount is read-only)"

**Location:** `skills/dev-cycle/SKILL.md:215`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the non-root half only (executed: all four image files test unwritable for uid 1000). It does not establish the root behaviour, which needs execution. Blocker: no root in this sandbox (rubric C11, still open).

`own()` refuses when `-w "$1"` is true (`:229`). As uid 1000, `-w` was false for all four `/opt` files (`unwritable build-loop.sh` … in `u4c-final-r2-d6-real.log`). `findmnt` shows `/` as an `rw` overlay, so a root run here would see the files as writable (paraphrased — no quote available because `findmnt` was run at the prompt and not captured to a log file). This is an executable claim that I could not run as root, so the verdict is capped at Unverifiable.

**Evidence:** `skills/dev-cycle/SKILL.md:215`, `:229`; `docs/reviews/execution-logs/u4c-final-r2-d6-real.log`

---

## Claim 26: "Its git carries the lib's HARDEN pairs and git_harden's environment (G; a test pins the lists equal). These checks come before, not instead of, build-loop.sh's own state and default-branch gates in its gated modes (dev-cycle.sh, questions.sh and the read modes have none; row 548 for dev-cycle.sh)."

**Location:** `skills/dev-cycle/SKILL.md:217-222`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pin test, plus questions.sh having no gate. It does not re-verify build-loop.sh's gated-mode list (unchanged).

Test 17 now reads `G=(env …` from SKILL.md, asserts it appears exactly once, and compares its `-c` pairs and `GIT_*` set with HARDEN and git_harden (`bats:340-344`). It passed. questions.sh's only git calls are plain `git -C "$PWD" rev-parse …` (`scripts/questions.sh:80`, `:84`), with no state or default-branch gate. Row 548 is the dev-cycle.sh row (Claim 6).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:327-345`; `scripts/questions.sh:78-86`; `docs/reviews/override-log.md:548`

---

## Claim 27: "The four files the scripts run (build-loop.sh and dev-cycle.sh source the lib from their own directory; dev-cycle.sh runs questions.sh beside it)"

**Location:** `skills/dev-cycle/SKILL.md:240-242`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the source and exec paths under the block, where the image's questions.sh exists. It does not cover dev-cycle.sh outside the block, which falls back to `$HOME/.claude/scripts/questions.sh` when none sits beside it.

```
# scripts/build-loop.sh:524, :528, :531
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"
source "$READ_LIB"
# scripts/dev-cycle.sh:389-390 (the same SCRIPT_DIR/READ_LIB lines at :95-103)
QS="$SCRIPT_DIR/questions.sh"
[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"
```

The block's `own` and `-f` checks guarantee `$D6_OPT/scripts/questions.sh` exists, so the fallback never fires through the block. Test 12's `from-opt` line confirms it.

**Evidence:** `scripts/build-loop.sh:524-532`; `scripts/dev-cycle.sh:95-104`, `:389-390`; `test/scripts/build-loop-orchestrator.bats:263-280`

---

## Claim 28: The launch's `env -u … -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE` keeps questions.sh off the caller's files

**Location:** `skills/dev-cycle/SKILL.md:247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers questions.sh's `open` through the block on the real image, plus the variables' role in questions.sh. It does not cover other environment variables questions.sh might read (none found by grep besides these two).

questions.sh takes `LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"` (`scripts/questions.sh:85-86`). Executed: with both variables pointing at a planted file holding `Q-999`, a direct run printed 1 matching line and the run through the block printed 0 (`u4c-final-r2-d6-real.log`). The unset also reaches the questions.sh that dev-cycle.sh starts, because it inherits the block's environment (`scripts/dev-cycle.sh:408`, `bash "$QS" open`).

**Evidence:** `scripts/questions.sh:85-86`, `:110-111`; `scripts/dev-cycle.sh:408`; `docs/reviews/execution-logs/u4c-final-r2-d6-real.log`

---

## Claim 29: "(a `refuse d6:` naming a missing image file means an image older than this skill: its entry also gives the release paste below)"

**Location:** `skills/dev-cycle/SKILL.md:283-284`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the narrow reading: the refusal names the missing file, and an image built from a main holding this skill has all four files. It does not exclude a damaged image as another cause.

Test 16 (unstubbed) checks `refuse d6: $U/scripts/build-loop.sh is missing` (`bats:325`). The image's payload is `git archive` of a commit's `scripts` (`install.sh:135`, `:337`), so any commit carrying this block carries the four files it checks.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:320-326`; `devcontainer-config/install.sh:135`, `:329-337`

---

## Claim 30: "If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, the image was not built here: skip silently."

**Location:** `skills/dev-cycle/SKILL.md:287-288`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what the command establishes. It does not re-open the silent skip as a design choice; Claims 5 and 8b cover the review records that describe it wrongly.

`cat-file -e` establishes only that this repository does not hold commit C (exit 128 for a missing object, `u4c-final-r2-image-checks.log`). That is what f2cc21e6 wrote ("this repository holds the image's commit") and what rubric D4 lists as fixed ("'built' → 'holds'"). 43b8d7ed returns to "built". Another repository, or claude-workflows with C's objects gone, both land here. Precise version: "this repository does not hold the image's commit (the image was built elsewhere): skip silently."

**Evidence:** `skills/dev-cycle/SKILL.md:287-288`; `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:59-60`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`

---

## Claim 31: "Else, if `hg -C MAIN_WT merge-base --is-ancestor C M` exits 1, the gate that runs was built off main: file one `you: judgment` entry `image-off-main` naming C, unless one is open (options: rebuild from main, the paste below; or keep)."

**Location:** `skills/dev-cycle/SKILL.md:288-290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit-code meaning on the real repository. It does not cover an is-ancestor error exit (128), which falls to the diff and then to "any other exit: note it".

Executed with MAIN_WT=/workspace: `is-ancestor C M exit=0` (C=774a0eef is on main), and `is-ancestor M C exit=1` (`u4c-final-r2-image-checks.log`). Exit 1 means C is not an ancestor of M, so the image's commit is not in main's history. Combined with Claim 34 (the /opt files equal C's blobs), the running gate came from a non-main commit.

**Evidence:** `skills/dev-cycle/SKILL.md:288-290`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`

---

## Claim 32: "Else run `hg -C MAIN_WT diff --quiet C M -- PATHS` … Exit 1: the gate that runs differs from main's. File one `you: terminal` entry `image-lag` … holding C, M, the changed names (the same diff with `--name-only`)"

**Location:** `skills/dev-cycle/SKILL.md:290-295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the diff's exit codes and name list on the real repository, with the Rules' `hg` (GIT_LITERAL_PATHSPECS=1). It does not cover case variants (row 818).

Executed: `diff --quiet exit=1`, and `--name-only` listed `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` and `skills/dev-cycle/SKILL.md`. That equals an unrestricted `diff --name-only C M` filtered by the GATE_CODE regex. So the literal pathspecs, including the `scripts/lib/` directory prefix, select exactly GATE_CODE's paths. A path outside them returned `exit=0` (`u4c-final-r2-image-checks.log`).

**Evidence:** `skills/dev-cycle/SKILL.md:290-295`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`

---

## Claim 33: the paste "`cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh` (host; then a new sandbox launch)", with A the manifest's `assembled_from=`

**Location:** `skills/dev-cycle/SKILL.md:286`, `:295-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check half (executed with /workspace standing in for A, which is a host path absent here), A's meaning, and what install.sh stages. It does not establish an install run on the host, which is interactive and host-only.

- `assembled_from=$REPO_ROOT` and `commit=$commit` come from `head_commit`, which is `HEAD^{commit}` (`install.sh:357-360`, `:185-186`). `REPO_ROOT="$(cd "$SRC/.." && pwd)"` (`:112`). So A is the checkout whose HEAD the image is built from.
- Executed: the check half printed "would run …install.sh" with exit 0 where HEAD = M, and exited 1 in this worktree (HEAD 43b8d7ed ≠ M) (`u4c-final-r2-image-checks.log`, 06:44:02Z).
- `ls -d /home/magfrump/claude-workflows` fails in the sandbox, which confirms A is the host's path.
- "Then a new sandbox launch": Claim 17.

**Evidence:** `devcontainer-config/install.sh:112`, `:185-191`, `:329-361`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`

---

## Claim 34: "Exit 0: an open `image-lag` entry is answered `done: the image holds main's gate code` (this diff is the observation)."

**Location:** `skills/dev-cycle/SKILL.md:297-298`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the claim that the manifest's C describes the running image's gate files (executed today) and that a clean C..M diff means they equal main's. It does not establish that this holds for every future image: the diff relies on the root-owned `.manifest` stamp, not on reading `/opt`'s bytes.

Executed: `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/questions.sh`, `scripts/lib/dev-cycle-read.sh` and `skills/dev-cycle/SKILL.md` under `/opt/claude-workflows` are each byte-equal to `git show C:<path>` (`same as C:` ×5, `u4c-final-r2-d6-real.log`). install.sh writes both the payload and the stamp from one commit ("dirty=no always: the payload is exactly the commit's content", `install.sh:355`). Confidence is Medium because "the observation" is of the stamp, which a stronger reading would want of the files themselves.

**Evidence:** `devcontainer-config/install.sh:353-361`; `docs/reviews/execution-logs/u4c-final-r2-d6-real.log`

---

## Claim 35: "A missing `.manifest` or line, or any other exit: note it in the record. None of these stops the iteration."

**Location:** `skills/dev-cycle/SKILL.md:298-299`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers consistency with the Rules. Step 0.1's image check is skill text, not a script call, so no `refuse d6:` or exit rule applies to it. It does not cover an is-ancestor error exit's route (Claim 31's scope).

None of the image-check commands is a D6 call. They are `hg` commands (`:287-291`). The Rules' stop list covers script calls and `refuse d6:` lines only (`:46-52`). The notes are therefore consistent with "None of these stops the iteration" (paraphrased — no quote available because this is the absence of any stop rule for `hg` read results across `:36-61`).

**Evidence:** `skills/dev-cycle/SKILL.md:36-61`, `:285-299`

---

## Claim 36: Step 1 "run `questions.sh init` (it creates only what is missing) and then `questions.sh archive` (it also reindexes) through the D6 block from WT … (a `refuse d6:` line or a timed-out call is still a stop, as the Rules say)"

**Location:** `skills/dev-cycle/SKILL.md:382-386`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the routing and the stop wording against the Rules. It does not re-verify init's and archive's own behaviour (unchanged script).

The Rules: "a call of any script that the Bash tool timed out, and a `refuse d6:` line, are stops too" (`:50-52`). questions.sh dispatches `init` and `archive` to their commands (`scripts/questions.sh:447-450`).

**Evidence:** `skills/dev-cycle/SKILL.md:50-52`, `:382-386`; `scripts/questions.sh:447-450`

---

## Claim 37: "(`check` exiting 1 names entries to fix before staging)"

**Location:** `skills/dev-cycle/SKILL.md:713`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what `cmd_check` prints on exit 1. It does not cover warnings that leave the exit at 0.

`cmd_check` sets `rc=1` for entry problems (duplicate id, invalid route, Opened date, status, slug, and an OPEN entry in the archive). It also sets `rc=1` for problems that are not entries: `✗ missing: $file`, a file that is "not valid UTF-8", and "index is stale — run: $QS_CMD index" (`scripts/questions.sh:237`, `:243`, `:296`) (paraphrased — no quote available because the `rc=1` paths span `:233-300`). Precise version: "names the entries or files to fix before staging".

**Evidence:** `scripts/questions.sh:233-300`

---

## Claim 38: The helpers' comment: "Its one copy is SKILL.md's 'The D6 block' … with trust its ownership check passes any path that exists (and refuses a missing one with the snippet's own words), so a uid-owned OPT stands in for the root-owned image. d6_setup: main holds this branch's four scripts, and so does a trusted stand-in at $U."

**Location:** `test/scripts/build-loop-orchestrator.bats:227-233`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stub's text and d6_setup against the helper code. It does not claim the stub matches the real own() on a dangling symlink (stub: "missing"; real: "not root-owned …"), a case no test uses.

The stub is `sed -i 's|^  own() { .*|  own() { [[ -e "$1" ]] \|\| no "$1 is missing"; }|'` (`:239`). The real own() says `no "$1 is missing"` (`SKILL.md:229`), the same words. `d6_setup` copies the four scripts into the fixture and commits them, then runs `opt_copy "$U" && d6_copy "$U" trust` (`:242-245`). `trust` must be the literal second argument (`[[ "${2:-}" != trust ]]`, `:239`). The suite passed.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:227-247`; `skills/dev-cycle/SKILL.md:229`

---

## Claim 39: Test "SKILL.md holds the D6 snippet once, and it names no other copy to run: no root test, no read of main's scripts (T33, U4c)"

**Location:** `test/scripts/build-loop-orchestrator.bats:255-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers exactly what the test asserts: one call line, one `D6` line, a last line of `d6 "$@" </dev/null`, no `D6_ROOT|cat-file (blob|--batch)|ls-tree|mktemp|\$HOME|~/` on non-comment lines, and the old file gone. "No read of main's scripts" is a grep for named reader commands, not a proof (e.g. `git show main:…` is not in the pattern). Rubric C10 decided this; the run test (Claim 40) is the behavioural check.

The test's body is `! grep -v '^ *#' "$D6" | grep -nE 'D6_ROOT|cat-file (blob|--batch)|ls-tree|mktemp|\$HOME|~/' || return 1` (`:259`). It passed (ok 11).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:255-261`; `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 40: Test "the D6 snippet runs the image copy's scripts by absolute path, with the image's own lib and questions.sh, never main's or the working tree's (T33, U3b3, U4c)"

**Location:** `test/scripts/build-loop-orchestrator.bats:263-280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the assertions listed in Claim 15. Its residue is the same (dev-cycle.sh's lib is shown only by exit 0 against `exit 9` stubs).

Main's and the working tree's four files are each `echo … copy; exit 9` (`:266`, `:269`). The asserted lib lines are `lib at $U/scripts/lib/dev-cycle-read.sh` (`:274`), and the questions lines are the `from-opt` ones (`:278-279`). It passed (ok 12).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:263-280`; `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 41: Test "the D6 snippet refuses before running anything: a blob or commit replace ref, info/grafts, not exactly one plain main or master (T36, U3b3)", including its new missing-file and non-regular-file cases

**Location:** `test/scripts/build-loop-orchestrator.bats:282-297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each `d6_is` case, including empty stderr, meaning nothing ran. The missing-questions.sh case runs under the trust stub, so it shows the stub's (identical) words; the real own()'s missing refusal is Claim 42's. The name does not list the two new file cases, but it claims nothing false about them.

```
# test/scripts/build-loop-orchestrator.bats:294-295
    rm "$U/scripts/questions.sh"; d6_is "refuse d6: $U/scripts/questions.sh is missing"; …
    mv "$U/scripts/lib/dev-cycle-read.sh" "$U/x"; mkdir "$U/scripts/lib/dev-cycle-read.sh"; d6_is "refuse d6: $U/scripts/lib/dev-cycle-read.sh is not a regular file"
```

`d6_is` requires exit 2, the exact line and `[ -z "$stderr" ]` (`:250`). It passed (ok 13).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:249-250`, `:282-297`; `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 42: T37 tests "the D6 snippet runs the root-owned image copy at /opt by absolute path, not main's copy" and "refuses an image copy the uid owns or one missing a file (an older image), and never runs main's"

**Location:** `test/scripts/build-loop-orchestrator.bats:312-326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both tests unstubbed, with the first against the real `/opt` (not skipped here). It does not cover a directory above the files failing the walk (row 814).

The first test uses `d6_copy "$O"; d6 build-loop.sh --help` and compares the output with `bash "$O/scripts/build-loop.sh" --help` (`:316-317`). It was not skipped (ok 15). The second runs `d6_copy "$U"` (no `trust`), then `d6_is "… is not root-owned, a plain path and unwritable here"`, then after `rm` `d6_is "… is missing"` (`:323-325`) (ok 16). Main's `build-loop.sh` is `echo main copy`, and `d6_is` requires empty stderr and the refusal as the only stdout, so main's copy never ran.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:312-326`; `docs/reviews/execution-logs/u4c-final-r2-orchestrator-bats.log`

---

## Claim 43: Test "SKILL.md step 0.1's image-lag paths are GATE_CODE's, on one line of their own: a GATE_CODE change fails here until both move (U4c i2 architecture 1)"

**Location:** `test/scripts/build-loop-orchestrator.bats:347-354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers three things: GATE_CODE's literal is pinned, the SKILL.md line appears exactly once, and every listed path matches GATE_CODE. The reverse direction (every GATE_CODE alternative has a listed path) rests on the two pinned literals, not on a computed check. It holds today by inspection: three scripts, `scripts/lib/`, `skills/dev-cycle/`.

```
# test/scripts/build-loop-orchestrator.bats:350-353
    [ "$g" = '^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/' ] || { echo "GATE_CODE changed: …"; return 1; }
    q=$'\x60'
    [ "$(grep -cxF "   $q$P$q" "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ] || …
    for p in $P; do [[ "$p" =~ $g || "${p}x" =~ $g ]] || { echo "not GATE_CODE: $p"; return 1; }; done
```

The pinned line is `SKILL.md:292`. Any GATE_CODE change fails the first assertion, and any edit to the SKILL.md line fails the second. It passed (ok 18).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:347-354`; `skills/dev-cycle/SKILL.md:292`; `scripts/lib/dev-cycle-read.sh:1970`

---

## Claim 44: Commit 1bc823ea's message

**Location:** `1bc823ea` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the body's statements against the code at HEAD: the image copy always, the reader, D6_ROOT and temp dir gone, the kept checks, questions.sh, the deleted file, extraction, the fallback gone, step 0.4, and the stub description. It excludes the Notes' "row 739" atom, which is decided (row 812, Accepted-immutable) and not re-filed.

The Rules' fallback paragraph is gone (the diff's first hunk removes "**Until the D6 block is written** …"). Step 0.4 reads "Here and above, a cycle you know ran is one that reached step 9's land; an iteration that stopped does not count (U4b2 confirm3 F1)" (`SKILL.md:357-358`). "Ownership checks on the four files and every directory above them" is `SKILL.md:243-246`. "The unstubbed refusal and the real /opt run are tested as before" is tests 15 and 16 (Claim 42).

**Evidence:** `skills/dev-cycle/SKILL.md:229-247`, `:357-358`; `test/scripts/build-loop-orchestrator.bats:312-326`; `docs/reviews/override-log.md:812`

---

## Claim 45: Commit 33ad1767's message: "Step 0.1 files an image-lag entry when main's gate code is ahead of the image's .manifest commit"

**Location:** `33ad1767` (commit message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers this one atom. The message's other statements hold at HEAD: the trust narrowing (`SKILL.md:42-46`, `:197-206`), the `.git` entry (`:203`), missing-as-missing (`:229`), the `env -u` list (`:247`), and questions.sh in the Rules (`:36`, `:60`). It does not cover the fixes that later commits made to this atom.

The test is "differs", not "ahead of": `diff --quiet C M` exits 1 for any difference (`SKILL.md:291-293`). Rubric D4 made the same correction in the skill text. A commit message cannot be edited, so this is informational, and the note "a lagging image does not stop the cycle" still holds (`:299`).

**Evidence:** `skills/dev-cycle/SKILL.md:291-299`; `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:77`

---

## Claim 46: Commit f2cc21e6's message: "Step 0.1 compares only GATE_CODE's paths (all of scripts/ named health-check.sh too), says the repository holds the image's commit, names the release as install.sh then the next sandbox launch, and notes a missing manifest or failed command. Step 1 names the timeout stop; the block header says the default branch's ref; Rollback 1 is scoped to gate-code reverts."

**Location:** `f2cc21e6` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each statement as of f2cc21e6 (read with `git show f2cc21e6:skills/dev-cycle/SKILL.md`) plus the health-check.sh premise, which I executed. It does not cover 43b8d7ed's later rewording of "holds" (Claim 30).

At f2cc21e6, step 0.1 read "(this repository holds the image's commit)" and "the host's `./devcontainer-config/install.sh`, then the next sandbox launch rebuilds the image" and "No `.manifest`, no `commit=` line or any other exit: note it in the record". Executed: `git diff --name-only 774a0eef 2aaf97b4 -- scripts/` lists `scripts/health-check.sh` among its three paths (paraphrased — no quote available because this ran at the prompt; the GATE_CODE-filtered list in `u4c-final-r2-image-checks.log` omits it, as the message says). Step 1's timeout stop is `SKILL.md:385-386`, the header's ref is `:203`, and Rollback 1 is plan `:441`.

**Evidence:** `skills/dev-cycle/SKILL.md:203`, `:385-386`; `docs/working/plan-build-loop-handoff.md:441`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`

---

## Claim 47: Commit 43b8d7ed's message, including "executed by hand against the real image (C on main, diff 1)"

**Location:** `43b8d7ed` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each statement against HEAD and my own run of step 0.1. It does not cover the i2 critic reports' content, and it does not establish that the commit's own by-hand run was logged (no 43b8d7ed-specific execution log is committed).

The statements and where each holds:
- "image-off-main (you: judgment) when the image's commit is not on main": `SKILL.md:288-290`.
- "the image-lag paste checks the host checkout is at main's commit before install.sh": `:295-296` (Claim 33).
- "carries C, M, the changed names and an interim, and a clean diff answers it done": `:294-298`.
- "The path list sits on one line pinned with GATE_CODE by a new test": Claim 43.
- "A missing image file's --state stop gives the same paste": `:283-284`.
- "Plan: U5's release entry becomes the image-lag entry's body": plan `:356`.
- "(C on main, diff 1)": my run gave `is-ancestor C M exit=0` and `diff --quiet exit=1`.

**Evidence:** `skills/dev-cycle/SKILL.md:283-299`; `docs/working/plan-build-loop-handoff.md:356`; `docs/reviews/execution-logs/u4c-final-r2-image-checks.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md:82`): D9 says deleting C's objects "drops the check to a record note". Since 43b8d7ed a failed `cat-file -e` is "skip silently" (`SKILL.md:287-288`). Correct D9's text (the Won't-Fix decision can stand).
- **Claim 8b** (`docs/reviews/override-log.md:819`): the same wrong consequence ("turns the check into a record note"), written in the same commit that made the branch silent. The row is append-only, so record the correction in a new row or in the rubric.
- **Claim 10** (`docs/working/plan-build-loop-handoff.md:77`): "It never trusts a file the uid can write". The block trusts the checkout's `.git` entry and the default branch's ref, as its own header says. Narrow it to "no file the uid can write chooses which script runs; it trusts the `.git` entry and the default branch's ref for which repository and branch the scripts read".

### Stale
- None.

### Mostly Accurate
- **Claim 2** (rubric `:63-64`): the row-817 note also omits step 9.1, which 43b8d7ed changed.
- **Claim 3** (rubric `:70`): the architecture i2 tally omits its one Informational finding.
- **Claim 7** (`override-log.md:817`): the "only" list omits steps 0.4, 1 and 9.1 and the fallback. Already decided, and rows are append-only.
- **Claim 8a** (`override-log.md:819`): a fork files `image-lag` only when C is on its main; otherwise it files `image-off-main`.
- **Claim 9** (plan `:71`): "built from main" should be "built from the host checkout's HEAD (step 0.1 checks it is on main)".
- **Claim 16** (plan `:432`): `image-lag` is filed only once the repository holds C and C is on main.
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:1962-1963`): "the image copy built from main" has the same imprecision as Claim 9.
- **Claim 30** (`SKILL.md:287-288`): "the image was not built here" should be "this repository does not hold the image's commit", the f2cc21e6 wording that rubric D4 lists as the fix.
- **Claim 37** (`SKILL.md:713`): `check` exit 1 can also name a missing file, bad UTF-8 or a stale index, not only entries.
- **Claim 45** (`33ad1767` message): "ahead of" where the test is "differs". The message is immutable.

### Unverifiable
- **Claim 25b** (`SKILL.md:215`): the -w-as-root behaviour needs a root run (rubric C11, still open).

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/code-fact-check-report-2026-10-13-u4c-final-r2.md, structured per the code-fact-check skill.
- Answered: all eight claim groups the brief named. That covers the D6 header's refusals, trust statements, sourcing and `env -u`, and the Rules and every call site (steps 0, 1, 7, 9). Step 0.1's image checks were executed read-only against /workspace with the Rules' `hg` and the real manifest; the paste's check half was executed with /workspace standing in for A; the pin test was checked. Also covered: the D6 test names and comments (suite run: 26/26), the plan passages named, rows 812-819 and every cited row number, the rubric, the two script comments, and all four commit messages. For the merge decision, the review trail has three Incorrects: rubric D9 and row 819 misdescribe the deletion consequence after 43b8d7ed changed it, and plan :77's "never trusts a file the uid can write". None is a code defect, and none is blocking-grade: each is a doc line contradicted by code or by the block's own header.
- Out of scope: whether the silent skip itself is the right design (D9, Won't-Fix); a root run of the -w test; running install.sh on the host; scripts/health-check.sh (running elsewhere, per the preamble).
- Escalate: none. All three Incorrects can be fixed mechanically in docs (one needs an amending override row, since rows are append-only).
