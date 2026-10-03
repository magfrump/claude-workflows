# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** partial, loop pass 3: `git diff 4a68e29a..237fce88` on chore/dev-cycle-2026-10-02 (the pass-2 fix commit: docs/working/cycles/cycle-2026-10-02.md, docs/working/questions.md, docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md, the review rubric, and the added pass-2 report). 4a68e29a and earlier are context only. The added pass-2 report is a review artifact; only the rubric's summary of it is checked here.
**Commit:** 237fce88
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-02
**Total claims checked:** 11
**Summary:** 10 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Tag: Legibility-target (docs-only delta; every finding is a count, a categorization or a source statement in a doc).

Execution provenance. Every command ran under `timeout` with cwd `/workspace` unless noted, between 2026-10-03T00:56Z and 00:58Z (UTC; the local date is 2026-10-02). Outputs are in the scratch directory `/home/node/.claude/jobs/db6d1182/tmp/fc3/` rather than `docs/reviews/execution-logs/`, because this pass may write only this report. The files are `bats-out.txt` and `nr` (Q-110 reproduction), `checkbrief.txt`, `qcheck.txt` and `git-counts.txt`. The scratch clone used for `--check-brief` was deleted afterwards. I read the hallucination-patterns log first. No claim in scope matches a logged pattern. The closest class is "a specific measured value quoted from a checked-in artifact set that does not contain it", and every count below reproduces from its named source.

---

## Claim 1: "Of the 16 decision records changed, two count as major design decisions: 031 (…) and 037 (bare-host copy install, created in the window at 29cdd160)."

**Location:** `docs/working/cycles/cycle-2026-10-02.md:54-56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 037 being the only decision record added in the window, its creating commit, and the 16-record count. It does not establish that no other changed record is "major", which is a judgment call.

`git log --diff-filter=A … 188e0a7d -- docs/decisions/` returns one addition, `29cdd160 2026-09-23 14:04:07 -0700` with `docs/decisions/037-bare-host-copy-install.md`. That commit's subject is "docs: revise copy-install plan to shape D; decision 037 (per plan step 1)". The window starts on 2026-09-18 (`cycle-2026-10-02.md:2`), so 29cdd160 falls inside it. The record's title is ``# 037 — Bare-host `~/.claude` is installed by blessed copy, offered on every `install.sh` run`` (`docs/decisions/037-bare-host-copy-install.md:1`). A distinct-path count over `docs/decisions/0*` in the window gives `16`. This fixes pass-2 Claim 9.

**Evidence:** `docs/working/cycles/cycle-2026-10-02.md:2`, `docs/decisions/037-bare-host-copy-install.md:1`, `/home/node/.claude/jobs/db6d1182/tmp/fc3/git-counts.txt`

---

## Claim 2a: "The rest carry trigger, status, amendment or wording edits (e.g. 035's status note, …)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:56-57`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the category list and the 035 example. It does not establish the category of each of the other 13 records, which I did not re-derive individually.

In the window, 035 got a Task-status change in addae610: `-- **Task status**: in-progress (decided 2026-09-12; …)` became `+- **Task status**: complete (decided 2026-09-12; A7 closed as installed 2026-09-17; the regex landed 2026-09-26 …)`. It also got a dated note in a4d9baf5: `+**Note, 2026-09-23 ([decision 037](037-bare-host-copy-install.md)).** install.sh now also …`. So "035's status note" is accurate.

**Evidence:** `git show addae610 -- docs/decisions/035-install-sh-gating.md`, `git show a4d9baf5 -- docs/decisions/035-install-sh-gating.md`

---

## Claim 2b: "(e.g. … 020/021's superseded notes)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:57`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what kind of note the window added to 020 and to 021. It does not establish anything about 030, which b09ebe06 also marked.

The 021 part holds. b09ebe06 ("mark superseded records") added `+**Superseded in part (noted 2026-09-26)**: the "cross-model / cheap-critic sweep" consumer …` to 021. The 020 part does not. The only window commit touching 020 is 4114b8bd, which added `+  **Amendment 2026-09-26:** the shipped Gate 1h does the opposite. It fails closed …`. `grep -ci supersed docs/decisions/020-*.md` returns `0`, and 020's header still reads `Status: Accepted` (`docs/decisions/020-self-improvement-loop-dogfoods-repo-process.md:3`). The sentence's category list already includes "amendment", so the classification is right and only the example's label is wrong. Precise version: "020's amendment note, 021's superseded note". This matches the wording of pass-2 Claim 9 ("020/021/035 carry amendments or a status change").

**Evidence:** `docs/decisions/020-self-improvement-loop-dogfoods-repo-process.md:3`, `git show 4114b8bd -- docs/decisions/020-*`, `git show b09ebe06 -- docs/decisions/021-*`, `/home/node/.claude/jobs/db6d1182/tmp/fc3/git-counts.txt`

---

## Claim 3: "Q-074: … (134 fix commits since its opening commit e7aa412d)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count under the subject-prefix rule `fix(`/`fix:` over every commit reachable from 188e0a7d and not from e7aa412d, and covers e7aa412d being the commit that filed Q-074. It does not establish the count under other rules: first-parent only gives 4, and a broader "fix-like" reading gives other numbers.

Command: `git log --format=%s e7aa412d..188e0a7d | grep -cE '^fix(\(|:)'` → `134`. Case-insensitive `^fix` also gives 134. `git log -S'Q-074' --reverse -- docs/working/questions.md` puts e7aa412d first ("docs(questions): file Q-068..Q-074 from the machinery-purpose review; …"), so it is the opening commit. main's tip is still 188e0a7d. This fixes pass-2 Claim 10.

**Evidence:** `docs/working/cycles/cycle-2026-10-02.md:31`, `/home/node/.claude/jobs/db6d1182/tmp/fc3/git-counts.txt`

---

## Claim 4: "193/244 … (digest-final3 counts single-replicate clusters as agreed; the others count multi-replicate clusters only; either rule gives <90%)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:155`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counting-rule note and the "either rule" conclusion, from the five Verdict-stability sections. It does not establish per-cluster correctness inside those reports.

The sections read as follows. A: "41 (including 3 single-replicate detections …). Among the 54 clusters with at least two reporting replicates: 38 agreed." B: "22 (no single-replicate detections …)" of 23. final3: "All reporting replicates agreed: 28" of 34, "Claim 3 counted as agreed (single replicate)", "Single-replicate detections: 7". final4: "46 (of which 9 are single-replicate detections …)" of 62, which is 37/53 multi-only. final5: "68 of 80 multi-replicate clusters". So the 193/244 sum mixes final3's all-cluster figure with multi-only figures for the rest, as the note says. B has no single-replicate clusters, so the rule makes no difference there. All-cluster pooled is 41+22+28+46+84 = 221 over 57+23+34+62+96 = 272, about 81%. Removing final3's 7 single-replicate clusters (at most 6 of them agreed, since Claim 11 is listed as disagreed) keeps the rate near 79%. Both are under 90%. This fixes pass-2 Claim 14.

**Evidence:** `docs/reviews/q094-final-A-code-fact-check-report.md`, `docs/reviews/q094-final-B-code-fact-check-report.md`, `docs/reviews/code-fact-check-report-digest-final3.md`, `docs/reviews/code-fact-check-report-digest-final4.md`, `docs/reviews/code-fact-check-report-digest-final5.md` (each "## Verdict stability")

---

## Claim 5: "Cause (reproduced …): `test/skills/eval-helpers-gating.bats` runs nested `run-tests.sh --fast` calls (lines 76–91; … the line-76 test) that do not override `RUN_TESTS_NOT_RUN_FILE`. The nested run inherits the parent's file and overwrites the parent's count (50, written before any suite runs, `scripts/run-tests.sh:356`) with its own 4."

**Location:** `docs/working/questions.md:129`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the override-free nested calls at lines 76, 83 and 91, the write at :356 happening before bats runs, and an executed overwrite (50 → 4) by the line-76 test. It does not establish that this is the only leaking suite, or which nested write lands last under `--jobs`. Both calls that write (76 and 91) write 4, so the order does not change the result.

The bats file's override-free calls are `76	  run bash "$T/scripts/run-tests.sh" --fast`, `83	  run bash "$T/scripts/run-tests.sh" --fast` and `91	  run bash "$T/scripts/run-tests.sh" --fast`. Lines 50 and 63 set `RUN_TESTS_NOT_RUN_FILE="$T/nr"`. The line-83 call exits at the bad-tag check (`scripts/run-tests.sh:351-354`, `exit 1`) before reaching the write, so only 76 and 91 overwrite. The write is

```bash
# scripts/run-tests.sh:356-358
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
```

and it comes before any suite runs. The suites run at `scripts/run-tests.sh:437` (`exec bats "${bats_args[@]}" "${files[@]}"`). health-check passes the variable in at `scripts/health-check.sh:389`: `HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast`.

Reproduction: `echo 50 > $S/nr; timeout 120 env RUN_TESTS_NOT_RUN_FILE=$S/nr bats -f 'a stamp or .failed marker alone' test/skills/eval-helpers-gating.bats`, run at 2026-10-03T00:56:41Z with cwd /workspace. Result: `ok 1 a stamp or .failed marker alone is not a report`, exit 0, `nr-after=4`. The test's temp dir is under mktemp, and the repo working tree was unchanged afterwards.

**Evidence:** `test/skills/eval-helpers-gating.bats:50,63,74-94`, `scripts/run-tests.sh:17-20,351-358,437`, `scripts/health-check.sh:380-397`, `/home/node/.claude/jobs/db6d1182/tmp/fc3/bats-out.txt`

---

## Claim 6: Q-096 brief: "(If an autonomous build loop runs this brief, it does not write questions.md: it names the probe and Q-096's closure in its stop or ready marker, and the dev cycle files both.)" and "(by the cycle, under a build loop)"

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:34-37`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the build-loop brief's invariant, the seed's marker design, and dev-cycle SKILL step 6b. It does not establish that the not-yet-built handoff script will parse marker bodies. That is the build-loop unit's work.

The build-loop brief requires "a loop never pushes and never writes `docs/working/questions.md`, `docs/roadmap.md` or `docs/dev-cycle.md`" (`docs/working/briefs/2026-10-02-build-loop-handoff.md:38-39`). The seed has a loop end with "one marker commit: `handoff: ready` or `handoff: stopped: <reason>`. The cycle files the merge or stop entries on the default branch" (`docs/working/seed-build-loop-handoff.md:26-27`). The seed's quoted step 6b says "never the questions files or the roadmap. It ends with one marker commit on that branch, which the next cycle reads" (`docs/working/seed-build-loop-handoff.md:114-115`). The new sentence moves the questions.md write and Q-096's closure from the loop to the cycle, so the pass-2 contradiction is gone. The direct (hand-started) path keeps its original criteria.

**Evidence:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:34-37`, `docs/working/briefs/2026-10-02-build-loop-handoff.md:36-40`, `docs/working/seed-build-loop-handoff.md:26-27,112-117`

---

## Claim 7: The edited Q-096 brief still meets the dev-cycle brief line rules (no line starting with `<`, no `[`…`]:` line, no open `<!--`, no CR or BOM)

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:1-45`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief's line shape at 237fce88, checked by `--check-brief` in a scratch clone whose `main` was set to 237fce88, and by hand with `rg`. It does not establish the post-landing check on the real default branch (rubric C8 stays open).

`rg` for `^\s*<`, bracket-led lines, `\r` and `<!--` returned nothing, and the first bytes are `# B` (no BOM). In a scratch clone (`git checkout -B main 237fce88`, run at 2026-10-03T00:57:05Z, cwd = the clone), `bash scripts/dev-cycle.sh --check-brief docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md` printed `ok … open 20a462d4…`, exit 0. The build-loop brief also printed `ok`, exit 0. The clone was deleted afterwards. The SKILL rule text is at `skills/dev-cycle/SKILL.md:338-344`.

**Evidence:** `skills/dev-cycle/SKILL.md:338-344`, `/home/node/.claude/jobs/db6d1182/tmp/fc3/checkbrief.txt`

---

## Claim 8: Rubric header and status: "Commit: 4a68e29a"; "🟡 Pass 2: findings fixed in the pass-2 fix commit (see Iterations). Final confirming pass pending."

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:1,6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header naming the reviewed commit of pass 2, and the pass-2 findings being addressed in 237fce88. It does not establish that every fix is exact: Claim 2b of this pass is a new imprecision introduced in the 4b fix.

The pass-2 report's header is `**Commit:** 4a68e29a`. Each pass-2 item has a matching hunk in 237fce88: Claims 1, 3, 4, 5 and 6 above, and C9 for the rubric item.

**Evidence:** `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-pass2.md:5`, `git diff 4a68e29a..237fce88`

---

## Claim 9: Rubric Iterations row 2: "1 Incorrect (4b: 037 …), 3 Mostly accurate (rubric "all fixed" omitted the open Unverifiable; Q-074 fix-commit count; 193/244 mixes counting rules). Escalations: Q-110 cause reproduced; build-loop brief's "loops never write questions.md" contradicted the Q-096 brief."

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's tallies and its escalation list against the pass-2 report. It does not re-verify the pass-2 report's per-claim content.

The pass-2 report's summary is `**Summary:** 16 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable` (`…-pass2.md:9`). Its attention list names Claim 9 (037) as Incorrect and Claims 1b, 10 and 14 as Mostly accurate (`…-pass2.md:336-342`). Its Goal-Alignment Note gives escalations "(1) Q-110's lead is confirmed by execution" and "(2) Cross-brief tension … conflicts with the Q-096 brief's criteria" (`…-pass2.md:351`). The row matches all of these.

**Evidence:** `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-pass2.md:9,336-351`

---

## Claim 10: Rubric row 1 "(Unverifiable "landed through pr-prep" is C9)" and row C9 "Record step 7 says the branch "landed through pr-prep" before it has (pass-1 Unverifiable) … Open until the merge"

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:12,41`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping of pass-1's two Unverifiables to C9 and C6. It does not establish that the merge has happened. It has not, so C9 is correctly open.

Pass-1's Unverifiables are "Claim 24 (`cycle-2026-10-02.md:61`): "landed through pr-prep" is a future event at 20a462d4" and "Claim 37 … 193/244 has no cited source". The second is C6. The record still says "branch `chore/dev-cycle-2026-10-02` landed through pr-prep" (`docs/working/cycles/cycle-2026-10-02.md:64`), and the branch is unmerged (`git log main..HEAD` lists 4 commits). Row C10 lists the five pass-2 items, which matches Claim 9. Cosmetic only, not a claim error: C9 and C10 sit above C8 in the table.

**Evidence:** `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md` ("### Unverifiable"), `docs/working/cycles/cycle-2026-10-02.md:64`, `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:38-43`

---

## Claim 11: `scripts/questions.sh check` passes on the edited questions.md

**Location:** `docs/working/questions.md:129`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the structure and index check at 237fce88. It does not establish the content of other entries.

`timeout 60 bash /home/node/.claude/scripts/questions.sh check`, run with cwd /workspace at 2026-10-03T00:57:08Z, exited 0 and printed `✓ questions: structure valid, indexes current`.

**Evidence:** `/home/node/.claude/jobs/db6d1182/tmp/fc3/qcheck.txt`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 2b** (`docs/working/cycles/cycle-2026-10-02.md:57`): 020's window note is an "Amendment 2026-09-26" (4114b8bd), not a superseded note. Only 021 was marked superseded. Say "020's amendment, 021's superseded note".

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-pass3.md in the code-fact-check format, header `**Commit:** 237fce88` and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All checklist items were checked: 037 at 29cdd160 and the 035/020/021 notes (Claims 1, 2a, 2b), the 134 count with its exact command (3), the 193/244 note (4), the Q-110 cause, reproduced under `timeout` (5), the Q-096 brief's consistency and line shape (6, 7), and the rubric rows plus `questions.sh check` (8–11). Result: **0 Incorrect, 0 Stale**, 1 Mostly accurate (doc-class, a mislabeled example in a parenthetical). Every pass-2 finding is confirmed fixed.
- Out of scope: the pass-2 report's per-claim content beyond its tallies, and the security review, which the rubric defers to the final pass. The hallucination-patterns log was not updated: there is no Incorrect, and this pass may write only this report.
- Decisions I made: "fix commits" counts subject prefix `fix(`/`fix:` over all commits in `e7aa412d..188e0a7d`, following pass 2. The post-landing `--check-brief` state was simulated in a deleted scratch clone instead of switching branches. Q-109's paste block was not run. Nothing I started is still running.
