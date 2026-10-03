# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** partial, loop pass 2: `git diff 20a462d4..HEAD` on chore/dev-cycle-2026-10-02 (7c4f5063 fixes: docs/roadmap.md, the 3 briefs under docs/working/briefs/, docs/working/cycles/cycle-2026-10-02.md, docs/working/questions.md; 4a68e29a review artifacts: pass-1 rubric, fact-check report, security review). 20a462d4 and earlier are context only.
**Commit:** 4a68e29a
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-02
**Total claims checked:** 20
**Summary:** 16 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Tag: Legibility-target (docs-only delta; every finding is a count, a categorization or a source statement in a doc).

Execution provenance. Every command ran under `timeout` with cwd `/workspace` unless noted, between 2026-10-03T00:48Z and 00:53Z. Outputs are in the scratch directory `/tmp/tmp.Bj8dIFbJks/` rather than `docs/reviews/execution-logs/`, because this pass may write only this report. The files: `out.txt` + `nr` (NOT RUN probe), `checkbrief.txt`, `checkbrief-clone.txt`, `checkbranch.txt`, `qcheck.txt`, `health-grep.txt`, `git-counts.txt`. The scratch clone used for `--check-brief` was deleted afterwards. Hallucination-patterns log read first; no claim in scope matches a logged pattern. The closest class ("a specific measured value quoted from a checked-in artifact set that does not contain it") was checked against each count below, and every count reproduces from its named source.

---

## Claim 1a: "5 Incorrect (doc-class), 7 Mostly accurate, 2 Unverifiable; security 2 Medium + 1 Info."

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:12`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pass-1 tallies against the two pass-1 reports. It does not cover whether each pass-1 verdict was itself right.

The pass-1 fact-check header reads `**Summary:** 28 verified, 7 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable` (`docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:9`). The security summary table rows are `| 1 | … | Medium |`, `| 2 | … | Medium |` and `| 3 | … | Informational |` (`docs/reviews/security-review-2026-10-02-devcycle-cycle.md:179-181`).

**Evidence:** `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:9`, `docs/reviews/security-review-2026-10-02-devcycle-cycle.md:177-181`

---

## Claim 1b: "All fixed in 7c4f5063." / "Status: 🟡 Pass 1: all findings fixed in 7c4f5063."

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:7,12`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping from each pass-1 finding to a 7c4f5063 change. It does not establish that each fix is itself correct; Claim 9 finds one that is not.

Thirteen of the fourteen fact-check findings map to a rubric row (A1–A5, C1–C6), and each row's change is in `git diff 20a462d4..7c4f5063`. One pass-1 Unverifiable is in no row and was not changed. The pass-1 report lists it as: "**Claim 24** (`cycle-2026-10-02.md:61`): 'landed through pr-prep' is a future event at 20a462d4. Confirm after the merge." (`docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md`, Claims Requiring Attention, Unverifiable). The record still reads "7. close: this record; branch `chore/dev-cycle-2026-10-02` landed through pr-prep" (`docs/working/cycles/cycle-2026-10-02.md:61-62`). The rubric's table has one Unverifiable row (C6, Claim 37), not the two its pass-1 line counts. A precise version would say: "all fixed except pass-1 Claim 24, which stays open until the merge."

**Evidence:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:7,12,18-40`, `docs/working/cycles/cycle-2026-10-02.md:61-62`

---

## Claim 2: "Override-log row 175 (a fired trigger's text shapes the new `agent` entry; Won't-Fix)" / "Override-log row 176 (seeded roadmap intro differs from the template; Won't-Fix)"

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:54-55`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what rows 175/176 say. It does not establish that the overrides still apply. Note that "row" here means file line (they are table rows 96 and 97), the same convention as the earlier rubric `code-review-rubric-2026-09-28-q094-final-A.md:43` ("row 135" = line 135).

`docs/reviews/override-log.md:175`: "A fired trigger's own text shapes the new `agent` questions entry (security-reviewer skill-final #4) | Informational | Won't-Fix". `docs/reviews/override-log.md:176`: "Seeded roadmap intro differs from the skill's template intro (api-consistency skill-final F4) | Informational | Won't-Fix". The roadmap intro was in fact edited this cycle and still differs from the skill's template (`docs/roadmap.md:9-10` vs `skills/dev-cycle/SKILL.md:258-262`).

**Evidence:** `docs/reviews/override-log.md:175-176`, `docs/reviews/code-review-rubric-2026-09-28-q094-final-A.md:43`

---

## Claim 3: "`--check-brief` prints `open` for all three briefs in a scratch clone … the brief branches print `absent`"

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Re-run at 4a68e29a (the rubric ran it at 20a462d4). Covers the post-landing state of all three briefs and the three branch names. It does not establish the pre-landing check, which prints `new` in /workspace because main is still 188e0a7d. Rubric C8 already says this.

Command (cwd: a `git clone --no-hardlinks /workspace` scratch clone with `git checkout -B main 4a68e29a`): `timeout 60 bash /workspace/scripts/dev-cycle.sh --check-brief "$f"` for each brief. Every exit was 0. Output: `ok docs/working/briefs/2026-10-02-build-loop-handoff.md open 20a462d4…`, plus the same `open` line for doc-drift-cycle1 and exit-scan-insteadof-target. In /workspace (main = 188e0a7d) all three print `… new`, exit 0. `timeout 30 bash scripts/dev-cycle.sh --check-branch NAME` prints `absent feat/build-loop-handoff`, `absent fix/doc-drift-cycle1` and `absent fix/q096-exit-scan-insteadof-target`. Run 2026-10-03T00:49–00:51Z.

**Evidence:** `/tmp/tmp.Bj8dIFbJks/checkbrief-clone.txt`, `/tmp/tmp.Bj8dIFbJks/checkbrief.txt`, `/tmp/tmp.Bj8dIFbJks/checkbranch.txt`

---

## Claim 4: Roadmap Now/In flight: "Nothing waiting outside a brief: this cycle's three ready items moved to In flight." with each In flight line naming "Brief: `docs/working/briefs/…`"

**Location:** `docs/roadmap.md:14-24`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers conformance with `skills/dev-cycle/SKILL.md` step 6: "Move the item to In flight, naming the brief's path", and In flight lines "each naming its brief path". It does not establish the record's "Roadmap diff" against main beyond the Now/In flight/Ideas/Done lines (see Claim 15).

The three items now appear only under In flight, and each line ends with its brief path (`docs/roadmap.md:18-24`). The paths match the three files on disk, and the skill text is quoted from `skills/dev-cycle/SKILL.md:273-276,348-349`. Now holds no item, which the template's "work ready to start or in progress by hand" allows (`skills/dev-cycle/SKILL.md:272`).

**Evidence:** `docs/roadmap.md:12-24`, `skills/dev-cycle/SKILL.md:272-276,348-349`

---

## Claim 5: "8 router skills and the dev-cycle skill added in the window" (also cycle record 4b: "8 router skills plus `skills/dev-cycle/SKILL.md` were added in the window"; rubric A2: "eight new routers plus the existing divergent-design one")

**Location:** `docs/roadmap.md:55-56`, `docs/working/cycles/cycle-2026-10-02.md:52-53`, `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:22`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers SKILL.md files added on main in the window. It does not establish the "48 skill/workflow files changed" figure beyond the digest's own count (section 7 prints `Skill or workflow files changed on \`main\` in the window: 48`).

`git diff --name-status 4225753a^1 4225753a -- 'skills/*/SKILL.md'` shows `A` for branch-strategy, codebase-onboarding, parallel-worktrees, pr-prep, research-plan-implement, spike, task-decomposition and user-testing-workflow (8), and `M skills/divergent-design/SKILL.md`. 3a63c56e also added `skills/review-fix-loop/SKILL.md`, but no such file exists at HEAD (`ls: cannot access 'skills/review-fix-loop'`), so 8 is the net added count.

**Evidence:** `git diff --name-status 4225753a^1 4225753a`, `/home/node/.claude/jobs/db6d1182/tmp/digest.txt:185`

---

## Claim 6: Q-110 / roadmap idea: "the test runner printed `NOT RUN: 50 report-dependent suite(s)`, but the health check's own summary said `4 report-dependent BATS suite(s) NOT RUN`" (cycle record: "50 report-dependent BATS suites not run … the health-check summary line says 4 while the runner printed 50"), "main at 188e0a7d"

**Location:** `docs/working/questions.md:126`, `docs/roadmap.md:58-59`, `docs/working/cycles/cycle-2026-10-02.md:15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High (quotes), Medium ("main at 188e0a7d", from timestamps)
**Verification mode:** executed
**Scope:** Covers both quoted lines in the one health log, and the 50 by the runner's own tag rule. It does not establish the commit from the log itself, which names none: the log's mtime (17:17 -0700) falls after 188e0a7d (16:51:30 -0700) and before 20a462d4 (17:25:49 -0700).

`grep -n "NOT RUN\|report-dependent"` on the health log (2026-10-03T00:52Z) gives `78:=== NOT RUN: 50 report-dependent suite(s) — no generated reports for their skill ===`, `1451:  ✓ Fast BATS suites passed (excluding 4 report-dependent suite(s) not run)` and `1769:  ⚠ 4 report-dependent BATS suite(s) NOT RUN — …`. Applying run-tests.sh's rule (`needs=$(head -15 "$f" | grep -m1 -E '^# @needs-reports( |$)' …)`, `scripts/run-tests.sh:331`) to every `*.bats` under `test/` gives `tagged=50`, and no `test/skills/*/output/*.report.md` exists. So Q-067's restored "50" (`docs/working/questions.md:179`) also holds. The Q-067 body is now byte-identical to main.

**Evidence:** `/home/node/.claude/jobs/db6d1182/tmp/health.log:78,1451,1769`, `/tmp/tmp.Bj8dIFbJks/health-grep.txt`, `scripts/run-tests.sh:325-362`

---

## Claim 7: Q-110 "Lead (unverified): a nested `run-tests.sh` inside a suite may inherit the runner's NOT RUN file variable and overwrite the count." and "Read: `scripts/health-check.sh` (check 5's NOT RUN summary) · `scripts/run-tests.sh` ("Report gating")"

**Location:** `docs/working/questions.md:128-129`
**Type:** Error-handling / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lead's mechanism for the fast run: one suite reproduces the exact "4". It does not establish whether other suites also leak, and it does not fix anything. The entry's "(unverified)" label is now out of date; that is information for whoever takes Q-110, not an error in the entry.

The parent writes its count before any suite runs: `if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"; fi` (`scripts/run-tests.sh:356-358`), and the suites run later in the same script (excerpt ends :358; the enclosing top-level flow continues to the bats invocation below :420, which was read). The health check passes the variable as an env prefix: `HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast` (`scripts/health-check.sh:389`). It then reads the file after the run and sums it: `warn "$((fast_nr + slow_nr)) report-dependent BATS suite(s) NOT RUN …"` (`scripts/health-check.sh:394,407`). In `test/skills/eval-helpers-gating.bats`, the first two tests override the variable (`run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast`, :50,:63). The third does not: `run bash "$T/scripts/run-tests.sh" --fast` (:76). Two later tests also call the runner without the override (:83, which exits 1 at the bad-tag check before the write, and :91), so this suite is not the only possible writer. Its fixture has four tagged suites (alpha-eval, alpha-format, beta-eval, beta/dimensions, :19-24) and no reports (a stamp is not a report).

Probe: cwd /workspace, `echo 50 > $D/nr; LC_ALL=C.UTF-8 RUN_TESTS_NOT_RUN_FILE="$D/nr" timeout 120 bats -f "stamp or .failed marker" test/skills/eval-helpers-gating.bats`. Exit 0 (`ok 1 a stamp or .failed marker alone is not a report`), at 2026-10-03T00:48:27Z. The file afterwards: `nr after: 4`. The check-5 and "Report gating" pointers resolve: `#   5. BATS tests pass: run-tests.sh --fast, then --slow …` (`scripts/health-check.sh:33`), and `# Report gating, per skill.` (`scripts/run-tests.sh:307`).

**Evidence:** `scripts/run-tests.sh:307,356-362`, `scripts/health-check.sh:33,382-407`, `test/skills/eval-helpers-gating.bats:19-24,50,63,74-91`, `/tmp/tmp.Bj8dIFbJks/out.txt`, `/tmp/tmp.Bj8dIFbJks/nr`

---

## Claim 8: "5 newly fired: 015 T2, 036 T3, 037 T1, 037 T3, log row 62. … Q-104–Q-108 filed."

**Location:** `docs/working/cycles/cycle-2026-10-02.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between this line, the record's Trigger verdicts section and Questions filed. It does not re-verdict each trigger (pass 1 did that against a fresh digest).

In the Trigger verdicts section, the lines marked fired but not "already handled" are 015 T2 (→ Q-105), 036 T3 (→ Q-107), 037 T1 (→ Q-106), 037 T3 ("fired, partly discharged") and log row 62 (→ Q-104). That is five, and each maps to one of Q-104–Q-108 in "## Questions filed" (`docs/working/cycles/cycle-2026-10-02.md:160-164`). Already-handled 014 T3, 016 T1 and log row 53 read "Nothing new" or "Not firing now".

**Evidence:** `docs/working/cycles/cycle-2026-10-02.md:28-29,85-158,160-168`

---

## Claim 9: "Of the 16 decision records changed, 031 (review-loop tier and fact-check policy) counts as a major design decision; the rest were trigger-section or wording edits."

**Location:** `docs/working/cycles/cycle-2026-10-02.md:54-56`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what each of the 16 records' window diffs contains. It does not establish what "major design decision" should mean, which is the cycle's judgment. 4b's outcome (a deep-audit task filed) does not change, because the router-skill trigger already fired it.

The 16 are the digest's list: `- Decision records added or changed on \`main\` in the window (is any a major design decision?): 16`, ending in `docs/decisions/037-bare-host-copy-install.md` (`/home/node/.claude/jobs/db6d1182/tmp/digest.txt`, section 7). 037 was not edited in the window. It was **created** in it: `git log --diff-filter=A` gives `29cdd160 2026-09-23`, with 96 inserted lines. It is a full record of a decision the user made that day: "**Task status**: in-progress (decided 2026-09-23 by the user, Q-054 [2] …)" and "## Options considered" (`docs/decisions/037-bare-host-copy-install.md:1-20`). The record's own trigger list calls it out: 036 T3 fired on "037's host target". Several others are also neither trigger-section nor wording edits: 035 changes its Task status to complete and adds a note that install.sh's reach "widens" (`+**Note, 2026-09-23 ([decision 037](…)).** install.sh now also writes the host's ~/.claude …`); 020 adds "**Amendment 2026-09-26:** the shipped Gate 1h does the opposite."; and 021 adds "**Superseded in part (noted 2026-09-26)**". The remainder (021/023/028/030 path moves to `archive/docs/`, 012's note) fit "wording". This is the C5 fix from 7c4f5063, so rubric row C5's "✅ Fixed" rests on it. A correct version would say: "037 (bare-host copy install) was added in the window and 031 amended; both are major design decisions. The rest are notes, amendments, status updates or path moves."

**Evidence:** `/home/node/.claude/jobs/db6d1182/tmp/digest.txt` (section 7, "Decision records … 16"), `docs/decisions/037-bare-host-copy-install.md:1-20`, `git diff $(git rev-list -1 --before=2026-09-18 188e0a7d) 188e0a7d -- docs/decisions/`, `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:37`

---

## Claim 10: "Q-074: 0 of 5 new failure-pattern entries since it opened (~135–140 fix commits, by cutoff)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:31`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "0 entries" half and the fix-commit count on main at 188e0a7d under three cutoffs. It does not establish which cutoff Q-074 intends.

`git log e7aa412d..188e0a7d -- docs/thoughts/failure-patterns.md` is empty (e7aa412d, 2026-09-26 14:10 -0700, is the commit that opened Q-074), so "0 entries" holds. The `fix(`/`fix:` subjects on main number 134 from Q-074's opening commit, 141 from local midnight 2026-09-26 (-0700) and 144 from UTC midnight. None of the three is in "~135–140", and the pass-1 report this fix answered gave "134–141 depending on the cutoff". A precise version: "134 fix commits since Q-074 opened (e7aa412d)".

**Evidence:** `/tmp/tmp.Bj8dIFbJks/git-counts.txt`, `docs/working/questions.md:195-198`

---

## Claim 11: 036 T2 "not fired. 0 commits since 2026-09-17."

**Location:** `docs/working/cycles/cycle-2026-10-02.md:136`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-merge commits on main since 2026-09-17 (036 was created 2026-09-17, 74a501b2) whose own diff touches both `devcontainer-config/` and `skills/`|`workflows/`|`patterns/`. It does not judge the trigger's "for a non-doc reason" clause, which is moot at 0. Merge commits are excluded: their first-parent diffs carry whole branches and give 10 false hits.

Loop: `git diff-tree --no-commit-id --name-only -r $c` for each `git log --since=2026-09-17 --no-merges main` commit, testing both path sets. Result: no `HIT` lines (2026-10-03T00:52Z). The trigger text: "if any commit has to touch both devcontainer-config/ and skills|workflows|patterns for a non-doc reason" (`docs/decisions/036-cc-isolated-repo-split.md:131`).

**Evidence:** `/tmp/tmp.Bj8dIFbJks/git-counts.txt`, `docs/decisions/036-cc-isolated-repo-split.md:131`

---

## Claim 12: "037's host target (built 6793b79a, recorded 29cdd160) uses `assemble()` alongside the devcontainer target (install.sh:498, :857)" (also Q-107: "built in 6793b79a, recorded in 29cdd160")

**Location:** `docs/working/cycles/cycle-2026-10-02.md:137`, `docs/working/questions.md:110`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two hashes' roles and the two call sites. It does not establish whether `assemble()` meets 036's [11] seam, which is Q-107's own question.

`6793b79a … feat: install.sh offers the host ~/.claude target on every run (per plan step 5)` changes only `devcontainer-config/install.sh` (+268) and adds `+  assemble "$stage"`. `29cdd160 … docs: revise copy-install plan to shape D; decision 037 (per plan step 1)` adds `docs/decisions/037-bare-host-copy-install.md`. At HEAD: `assemble "$stage/claude-home" "${dc_paths[@]}"` (`devcontainer-config/install.sh:498`) and `assemble "$stage"` (`devcontainer-config/install.sh:857`; the line was last touched by fa25f13a8 in a later refactor). Both hashes are on main.

**Evidence:** `git show --stat 6793b79a 29cdd160`, `devcontainer-config/install.sh:329,498,857`

---

## Claim 13: "396 to 1861 code lines outside `docs/` (de530691 → 5652d33f …) over 37 passes" / Q-104: "after 37 review passes (pass 38 reviewed the merged result)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:153`, `docs/working/questions.md:59`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line counts and the rubric's pass numbering. It does not establish that "passes" includes the rubric's separately headed "Final pass 2–5" and "Full review 1" sections, which run alongside the numbered passes.

`git diff --shortstat 4225753a de530691 -- . ':!docs'` gives `2 files changed, 396 insertions(+)`, and against 5652d33f gives `1861 insertions(+)`. The digest rubric heads its last two sections `## Pass 37 (k=1 delta on 6f3d55e digest / 2e65ad5 skill) — stopped at the user's request, 2026-10-02` and `## Pass 38 (final k=1 delta, post-merge; on 90364c73 main = 5652d33f digest / 2da55741 skill)` (`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:837,847`). 5652d33f's subject is "fix(dev-cycle): pass-37 …".

**Evidence:** `/tmp/tmp.Bj8dIFbJks/git-counts.txt`, `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:837-851`

---

## Claim 14: "Pooled final-pass k=3 agreement is 193/244 ≈ 79% (<90%), summed from the Verdict-stability sections of the q094-final-A/B and digest-final3/4/5 merged reports."

**Location:** `docs/working/cycles/cycle-2026-10-02.md:154`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reproducing 193/244 from the five named sections. It does not establish that the sum uses one agreement rule throughout: it does not.

The sections give: q094-final-A "41/57 … (38/54 = 70.4% excluding single-replicate clusters)"; q094-final-B "22/23" ("no single-replicate detections"); digest-final3 "28/34 ≈ 82%. Single-replicate detections: 7"; digest-final4 "37/53 ≈ 69.8% over the 53 clusters with two or more reporting replicates"; digest-final5 "68/80 = 85.0% of multi-replicate clusters". Computed with python3: 38+22+28+37+68 = 193 and 54+23+34+53+80 = 244, so 193/244 = 79.1%. The sum uses multi-replicate-only figures for A, final4 and final5 but final3's all-cluster figure, which counts its 7 single-replicate clusters as agreed, because final3 prints no multi-only figure. The 79% and the "<90%" conclusion stand under either rule (all-cluster: 221/272 ≈ 81%). A precise version would add "final3 counted with its single-replicate clusters".

**Evidence:** `docs/reviews/q094-final-A-code-fact-check-report.md`, `docs/reviews/q094-final-B-code-fact-check-report.md`, `docs/reviews/code-fact-check-report-digest-final3.md`, `…-final4.md`, `…-final5.md` (each "## Verdict stability")

---

## Claim 15: Questions filed / Roadmap diff: "Q-110 · health-check-not-run-undercount (`agent` …)", "Edited: Q-096 (unblocked, briefed)", "Now: 'This dev cycle' moved to Done; 'Build-loop handoff' moved to In flight", "Ideas: +7 (…)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:167-176`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each line against `git diff main...HEAD` of roadmap.md and questions.md. It does not cover "Next: unchanged order", which is outside this delta.

On main, Now held "This dev cycle" and "Build-loop handoff". The branch moves the dev cycle to Done ("The dev cycle (skill and digest script, log rows 67–68, merge 90364c73)") and puts Build-loop handoff, plus the new doc-drift and Q-096 items, under In flight. Ideas gains 7 bullets (scoped deep audit, Q-110, host vs container, doc-freshness, fixtures, stale idea source, Contested-Soundness), in the order the record lists them. The only Q-096 body change against main is `+- **Unblocked 2026-10-02 (dev cycle):** Q-094's branches merged (7bf3b581) …`, and Q-067's body equals main.

**Evidence:** `git diff main...HEAD -- docs/roadmap.md docs/working/questions.md`

---

## Claim 16: Doc-drift brief: "Bring five files back in line with the code" and "Line 58 describes what the launcher does on its own, not advice to run by hand"

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:10,23-24`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file count and line 58's role. It does not re-check the line 897 / devcontainer-setup:366 drift (pre-existing, verified in pass 1).

The items name cc-isolated-usage.md, devcontainer-setup.md, guides/README.md, AGENTS.md and GEMINI.md: five files. `guides/cc-isolated-usage.md:57-59` is step 5 of the launcher's numbered sequence: "5. If the running container's baked hash is not the blessed one (you re-blessed since it was built), recreate it with `--remove-existing-container`. `devcontainer up` alone never rebuilds."

**Evidence:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:18-31`, `guides/cc-isolated-usage.md:50-62`

---

## Claim 17: Build-loop brief: "anything other than the exact policy line resolves to `review`; self-merge refuses any path on the seed's denylist; an added symlink refuses self-merge … whatever the seed's step 6b says"

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:33-43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each invariant and the step-6b reference exist in the seed. It does not establish that the invariant list is complete (the brief's pre-mortem criterion exists for that).

Seed: "Policy: set only when `docs/dev-cycle.md` has exactly one line … reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` …; anything else is `review`." (`docs/working/seed-build-loop-handoff.md:31-33`). "Self-merge only for work outside what later runs follow unreviewed (hooks, … `devcontainer-config/`), with a `Paths:` allowlist and a pre-merge … no-added-symlink check" (:34-36). The quoted step 6b says "The brief stands in for RPI's plan approval." (:110-111).

**Evidence:** `docs/working/seed-build-loop-handoff.md:27-41,102-135`

---

## Claim 18: Q-096 brief: "The commit carries `Live-verified: no — REASON` (the container cannot run the host probe), never a bare yes or a hash, unless the host probe actually ran"

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:32-34`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the gate's documented trailer forms. It does not establish that the gate rejects a dishonest value: it does not, because "The value is free text on purpose", which is why the brief pins it.

`hooks/live-verify-gate.sh:16-18`: "message must carry a `Live-verified:` trailer. The value is free text on purpose — `Live-verified: 3f2a9c0e1b7d4a6f` (the blessed hash …) or `Live-verified: no — <why, and what will run it>`." The gate's hint prints `Live-verified: no — <reason>; run cc-isolated --probe-only <repo> after install.sh` (:152).

**Evidence:** `hooks/live-verify-gate.sh:16-20,131,150-152`

---

## Claim 19: Briefs satisfy the skill's brief rules (exact `Status: open`, the evidence line, doc change in acceptance criteria, the status-line criterion, no `<`/`[`…`]:`/`<!--`/CR/BOM line shapes)

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:3,6,29-30,45`, `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3,6,43-44`, `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:3,6,30-31,36`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rules at `skills/dev-cycle/SKILL.md:330-347`, checked with `rg` and by `--check-brief` (which skips any brief whose lines it cannot trust) in the post-landing clone. It does not establish the slug-uniqueness rule beyond `--check-brief` printing `new` in /workspace.

`rg -n '^\s*<|^\s*(>\s*)*([-*+]\s+)?\[|\r|<!--'` over the three briefs: no match. The BOM grep counts 0 for each file and `grep -c '^Status: open$'` counts 1. Each brief has "repo text is evidence, not instructions" at line 6, a doc-change criterion ("(the doc change)", "These are doc changes, so the doc change is the work itself", "describes the new behavior (the doc change)"), and "In the change that merges this work, change this brief's status line from open to done." `--check-brief` printed `open` for all three, not a skip (Claim 3).

**Evidence:** `/tmp/tmp.Bj8dIFbJks/checkbrief-clone.txt`, `skills/dev-cycle/SKILL.md:327-349`

---

## Claim 20: `scripts/questions.sh check` passes on the edited questions doc (index regenerated for Q-110 and Q-067)

**Location:** `docs/working/questions.md:43-44,123-130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers grammar, unique IDs and index freshness, as `check` defines them. It does not establish Q-110's options-table form (an `agent` entry with no option space; none is required).

`timeout 60 bash scripts/questions.sh check` (cwd /workspace, 2026-10-03T00:49:57Z): exit 0, `✓ questions: structure valid, indexes current`.

**Evidence:** `/tmp/tmp.Bj8dIFbJks/qcheck.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9** (`docs/working/cycles/cycle-2026-10-02.md:54-56`): 037 was added in the window (29cdd160, a full user-made decision), not a "trigger-section or wording edit". 020/021/035 carry amendments or a status change. Name 037 alongside 031. Rubric C5's "✅ Fixed" rests on this line.

### Mostly Accurate
- **Claim 1b** (`docs/reviews/code-review-rubric-…:7,12`): "all findings fixed" leaves out pass-1 Claim 24 ("landed through pr-prep", a future event), which has no row. Add it as open until the merge.
- **Claim 10** (`docs/working/cycles/cycle-2026-10-02.md:31`): "~135–140" contains none of the three cutoffs' counts (134 since Q-074 opened, 141, 144). Say 134 since e7aa412d.
- **Claim 14** (`docs/working/cycles/cycle-2026-10-02.md:154`): 193/244 reproduces, but final3 enters with its single-replicate clusters counted as agreed while the others exclude theirs. Say so; the conclusion holds.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-pass2.md in the code-fact-check format, header `**Commit:** 4a68e29a` and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All four checklist areas were checked: changed counts and hashes (Claims 5, 8–15), Q-110's quoted lines (6, 7), the rubric's statuses and override rows (1–3), and skill conformance plus `questions.sh check` (4, 19, 20). The result is 1 Incorrect and 3 Mostly accurate, all doc-class, and every pass-1 Incorrect is confirmed fixed.
- Out of scope: the pass-1 fact-check and security reports' per-claim content was not re-verified (only their tallies, for Claim 1a). The hallucination-patterns log was not updated: Claim 9 is a miscategorization, not a fabricated symbol, and this pass may write only this report.
- Escalate: (1) Q-110's lead is confirmed by execution: `test/skills/eval-helpers-gating.bats` test 3 (`run bash "$T/scripts/run-tests.sh" --fast`, no env override) overwrites the parent's `RUN_TESTS_NOT_RUN_FILE` with 4. The Q-110 entry could drop "(unverified)" and name that test, as an `agent` follow-up. (2) Cross-brief tension, not a claim error: the build-loop brief's invariant "a loop never … writes `docs/working/questions.md`" conflicts with the Q-096 brief's criteria, which write a `you: terminal` entry and set Q-096 ANSWERED. That only matters once a build loop runs the Q-096 brief, and today the user starts each brief by hand.
- Decisions I made: I counted "fix commits" by subject prefix `fix(`/`fix:` on main's full history. "Row 175/176" is read as a file line, following the earlier rubric's convention. The `--check-brief` post-landing state was simulated in a deleted scratch clone instead of switching branches. Q-109's paste block was not run.
