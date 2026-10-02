Commit: e438cd1

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-devcycle, branch feat/dev-cycle)
**Scope:** `git diff feat/dev-cycle-digest...HEAD -- . ':(exclude)docs/reviews'` (README.md, docs/decisions/log.md row 67, docs/roadmap.md, docs/working/questions.md Q-099/Q-100, global-instructions/CLAUDE.md row 12, guides/skill-creation.md, skills/dev-cycle/SKILL.md) plus commit messages `git log feat/dev-cycle-digest..HEAD --no-merges` (1f8ed13, 89a3d3b, d8b0cca, 3268a5e, e438cd1). scripts/dev-cycle.sh and test/scripts/dev-cycle.bats read as context only (byte-identical between feat/dev-cycle-digest and HEAD: `git diff feat/dev-cycle-digest HEAD --stat -- scripts test` is empty).
**Checked:** 2026-09-29
**Total claims checked:** 31
**Summary:** 27 verified, 1 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Its recurring class is "a specific measured value quoted from an artifact set that does not contain it"; every count in scope (34 skills, 11 records / 7 log rows, 531 lines, six tests, 245 characters, ~128 fix commits, nine runs) was recomputed for that reason. None matches the logged pattern; the closest is Claim 4 ("nine"), which is a lower bound the source states as "≥9", not a fabricated value.

Execution logs for this run: `docs/reviews/execution-logs/r3-skill-final-*.txt`. All probes ran under `timeout` in a clone under the session scratchpad (or read-only git commands in the worktree); no process remained afterwards.

---

## Claim 1: "`skills/` holds 34 Claude Code skills ... the `dev-cycle` skill (the outer maintenance loop; `docs/roadmap.md`)"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of skill directories at HEAD and that `dev-cycle` is one of them; does not establish that every directory is a well-formed, installable skill.

`ls -d skills/*/ | wc -l` gives 34 at HEAD, and `dev-cycle` is in the listing (paraphrased — no quote available because the claim is about directory layout, not a snippet). The same count holds at 89a3d3b, the commit that changed the number (`git ls-tree -d --name-only 89a3d3b skills/ | wc -l` → 34).

**Evidence:** `README.md:182`, `skills/`

---

## Claim 2: "Steps: digest → health and cleanup → revisit-trigger verdicts ... → roadmap (Now / Next ≤5 / Ideas / Done) → cycle record in `docs/working/cycles/cycle-YYYY-MM-DD.md`. The user starts it; there is no timer."

**Location:** `docs/decisions/log.md:90`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order and content of the eight steps against the skill's headings and the Next cap; does not establish that the skill's steps are followed in practice.

The skill's headings run `### 0. Digest` (`skills/dev-cycle/SKILL.md:31`) through `### 7. Close` (`:118`) in the stated order; Next is capped at "`at most five items, ranked`" (`:109`); the record path is "`Write docs/working/cycles/cycle-YYYY-MM-DD.md`" (`:120`); and "`It runs when the user starts it; there is no timer.`" (`:14`).

**Evidence:** `skills/dev-cycle/SKILL.md:14`, `skills/dev-cycle/SKILL.md:31-126`

---

## Claim 3: "Mechanical parts are a script because steps only prose asks for do not run (Q-074; the override log's nine unwritten runs)."

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the "nine" figure against the override-log diagnosis it points at; does not establish the Q-074 part beyond its entry text (checked in Claim 13).

The diagnosis gives nine as a floor, not a count: "`It is at minimum **nine** runs`" (`archive/docs/2026-08-06-handoff-diagnosis-override-log-not-written.md:21`) and "`the eligible population is **≥9**, the observed capture rate is **≤1/9**`" (`:62`); the automated capture paths' "`record is 0/9`" (`:91`). "Nine unwritten runs" is right in mechanism and conclusion; the precise version is "at least nine runs, none captured by the in-run paths".

**Evidence:** `archive/docs/2026-08-06-handoff-diagnosis-override-log-not-written.md:21`, `:62`, `:91`

---

## Claim 4: "As of 2026-09-28, 11 decision records carried revisit triggers and 7 log rows mentioned a revisit condition, and no recurring step read them (codebase-onboarding step 10 reads the records once, at onboarding)."

**Location:** `docs/decisions/log.md:90`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two counts at the last main commit dated 2026-09-28 (ec297d4) and that onboarding step 10 is a one-time read; does not establish that no other recurring process reads triggers outside this repo.

Command: per-commit count of `docs/decisions/NNN-*.md` containing `^## Revisit triggers` and of log rows matching `revisit` (case-insensitive); cwd `/workspace/.claude/wt-devcycle`; exit 0; 2026-09-29T03:05:26-07:00. Output line: "`ec297d4 2026-09-28 22:30:09 -0700 records=11 logrows=7`". The count rises to 8/9/10 only with rows 65, 66 and 67 (dated 2026-09-28/29 but committed 2026-09-29). Onboarding step 10 is in the one-time onboarding workflow: "`grep '## Revisit triggers' docs/decisions/*.md to find decision records that name re-examination conditions`" (`workflows/codebase-onboarding.md`, step 10 recipe item 1).

**Evidence:** `docs/reviews/execution-logs/r3-skill-final-trigger-counts.txt`, `workflows/codebase-onboarding.md` (step 10)

---

## Claim 5: "the self-improvement loop's `feature-ideas*.md` is read as a signal in step 5 (interim for Q-099). ... The global decision tree gains row 12."

**Location:** `docs/decisions/log.md:90`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that step 5 names the file glob and that row 12 exists; does not establish that the glob matches anything in a given checkout (round files are gitignored).

Step 5 lists "`an item from the self-improvement loop's docs/working/feature-ideas*.md`" (`skills/dev-cycle/SKILL.md:86-87`); `global-instructions/CLAUDE.md:32` begins "`| 12 | **Maintenance or planning pass over the repo**`"; Q-099's interim is "`[1]. Step 5 lists feature-ideas*.md as a signal source`" (`docs/working/questions.md:82`).

**Evidence:** `skills/dev-cycle/SKILL.md:82-89`, `global-instructions/CLAUDE.md:32`, `docs/working/questions.md:67-83`

---

## Claim 6: "Q-075 — evidence that the self-improvement loop is safe to resume. Motive: Q-068 was answered "resume" on condition of this evidence; ... First step: list every path, config, hook, credential and git ref `scripts/self-improvement.sh` can write outside its working docs."

**Location:** `docs/roadmap.md:20-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-068 answer and Q-075's first step and interim; does not establish that the loop is the repo's only idea generator.

Q-068: "`**Answered 2026-09-27: [3] resume ...** So the loop stays dormant until that trust exists. The trust work is filed as Q-075.`" (`docs/working/questions-archive.md:1370`). Q-075: "`list every path, config, hook, credential and git ref the loop can write outside its own working docs`" and "`**Interim:** the loop stays dormant.`" (`docs/working/questions.md`, Q-075 entry).

**Evidence:** `docs/working/questions-archive.md:1367-1370`, `docs/working/questions.md` (### Q-075)

---

## Claim 7: "Q-088 — spike `sandbox.enableWeakerNestedSandbox` in cc-isolated. Motive: Q-098 (a global allow list) waits on a Bash sandbox."

**Location:** `docs/roadmap.md:24-26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-088 subject and the Q-098 dependency; does not establish the spike's outcome.

Q-098: "`Ship a global permissions.allow in hooks/wiring.json once cc-isolated has a Bash sandbox (Q-088).`" (`docs/working/questions.md:178`). Q-088: "`can Claude Code's sandbox.enableWeakerNestedSandbox run Bash sandboxed inside cc-isolated`" with a stated Success criterion (`docs/working/questions.md:202`).

**Evidence:** `docs/working/questions.md:175-183`, `docs/working/questions.md:199-206`

---

## Claim 8: "Q-089 — host-tool trust category. Motive: `cc-push.sh` and the exit scan are gated by a `Live-verified:` trailer they can never satisfy, since they run only on the host (Q-083 [1])."

**Location:** `docs/roadmap.md:27-29`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the live-verify gate requires of a commit touching an enforcement file and what Q-083 names as the problem; does not establish whether cc-exit-scan.sh is already in the enforcement set (Q-083 says "soon").

The gate is satisfiable with a "no" answer, so host-tool commits are not blocked by it: "`The value is free text on purpose — ... or Live-verified: no — <why, and what will run it>. The gate does not judge the answer; it refuses a commit that leaves the question unasked`" (`hooks/live-verify-gate.sh:16-20`). Q-083 states the actual problem as dilution plus launch blocking: "`host tools can't be live-probed, so every commit to them carries Live-verified: no, which dilutes row 45's debt list. check_manifest runs only when cc-isolated launches, so a changed cc-push.sh blocks every launch until re-blessed, while cc-push itself runs unchecked.`" (`docs/working/questions-archive.md:1581`). The precise motive: host tools can never be live-verified, so each commit adds a `Live-verified: no` debt entry, and a changed host tool blocks cc-isolated launches until re-blessed. Medium confidence because "a trailer they can never satisfy" can also be read as "never truthfully carry a verified hash", which is true; the natural reading of "gated by ... can never satisfy" is a permanent block, which the gate's own header refutes. Low stakes: a roadmap motive line.

**Evidence:** `hooks/live-verify-gate.sh:13-21`, `hooks/live-verify-gate.sh:34-38`, `docs/working/questions-archive.md:1572-1581`, `docs/working/questions.md:208-215`

---

## Claim 9: "Measure router uptake. Motive: log row 66's revisit trigger. First step: in each of the first three cycles after install, count multi-file merges that carry RPI research/plan docs and pr-prep review artifacts (an artifact count, not the usage log, which under-counts, Q-017)."

**Location:** `docs/roadmap.md:30-33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with row 66's trigger text; does not establish the Q-017 under-count beyond row 66's citation of it.

Row 66: "`Revisit if, over the first three dev cycles after install, multi-file merges still land without the RPI research/plan docs or pr-prep review artifacts they should carry (an artifact count, not the usage log)`" and "`Hook-based usage counts are not cited: they under-count silently (Q-017, triage 2026-09-17 §2.2 correction)`" (`docs/decisions/log.md:89`).

**Evidence:** `docs/decisions/log.md:89`

---

## Claim 10: "A8 post-restructure token measurement. Motive: the user deferred big compute until code and prompts settle; it validates code-review lever #3."

**Location:** `docs/roadmap.md:34-36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the project memory entry; does not establish the current settlement state (the item's own first step).

The memory entry reads "`the post-restructure measurement of code-review lever #3 ... should be run — but only after the code/prompt changes in /workspace are fully settled. Same holds for any further large-compute experiments.`" (`~/.claude/projects/-workspace/memory/run-a8-measurement-after-settling.md:11`). Medium confidence only because the source is user memory outside the repo, not a tracked file.

**Evidence:** `/home/node/.claude/projects/-workspace/memory/run-a8-measurement-after-settling.md:11`

---

## Claim 11: "Q-079 — canon-instance script and proposal filter. Signal: the review canon grows only by hand (Q-072)."

**Location:** `docs/roadmap.md:42-43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-079/Q-072 link and subject; does not establish how often the canon has been grown.

Q-072's answer: "`a *script* converts a commit or commit sequence into a canon instance, but *proposing* instances needs higher-level heuristic filtering ... Filed as Q-079`" (`docs/working/questions-archive.md:1449`).

**Evidence:** `docs/working/questions-archive.md:1446-1449`, `docs/working/questions.md` (### Q-079)

---

## Claim 12: "Automate the failure-pattern harvest, or drop the "do not skip" line. Signal: Q-074, 1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26 if fewer than 5 new entries have landed by then."

**Location:** `docs/roadmap.md:44-46`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Q-074's text; does not re-count the fix commits.

Q-074: "`docs/thoughts/failure-patterns.md has gained 1 entry across about 128 fix commits ... If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment: automate the harvest, or drop the "do not skip" line.`" (`docs/working/questions.md:107`).

**Evidence:** `docs/working/questions.md:104-109`

---

## Claim 13: "Narrow code-review's "default whenever a PR is prepared" description. ... Finish skill-format-audit F1: drop `when:` repo-wide and from `divergent-design-router.bats`. Signal: override log, deferred from log row 66's review."

**Location:** `docs/roadmap.md:47-50`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two override-log rows; does not establish that either change is still needed at HEAD.

`docs/reviews/override-log.md:161`: "``skills/code-review/SKILL.md` description still says "default whenever a PR is prepared or evaluated", overlapping pr-prep ... | Deferred``"; `:164`: "``test/skills/divergent-design-router.bats` still requires `when:`/`trigger` ... finishing skill-format-audit F1 repo-wide is a separate change``". Both rows are on `feat/workflow-router-skills` (row 66's branch).

**Evidence:** `docs/reviews/override-log.md:161`, `docs/reviews/override-log.md:164`

---

## Claim 14: "Review artifacts collide across branches. Signal: merging the row-66 branch hit conflicts on `code-fact-check-report-r*.md` (undated, so any two branches collide) and add/add conflicts on `*-review-<date>.md`."

**Location:** `docs/roadmap.md:51-53`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conflicts of merge 33fdfd3 (main into feat/workflow-router-skills) re-computed with merge-tree; does not establish that every pair of branches collides.

Command: `git merge-tree --write-tree --name-only 33fdfd3^1 33fdfd3^2`; cwd `/workspace/.claude/wt-devcycle`; exit 1 (conflicts, expected); 2026-09-29T03:05. Output includes "`CONFLICT (content): Merge conflict in docs/reviews/code-fact-check-report-r1.md`" (and r2, r3), "`CONFLICT (add/add): Merge conflict in docs/reviews/performance-review-2026-09-29.md`" and the same for `security-review-2026-09-29.md`.

**Evidence:** `docs/reviews/execution-logs/r3-skill-final-merge-tree-33fdfd3.txt`

---

## Claim 15: "AGENTS.md names workflows by filename, not `@` import; guard test (log row 65, merge c9a370a). Removes ~89K tokens ... A router skill for every workflow except review-fix-loop (log row 66, merge 4225753)."

**Location:** `docs/roadmap.md:59-61`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge hashes, subjects and the token figure against row 65; does not re-measure the 89K figure.

`git log` shows "`c9a370a merge: AGENTS.md names workflows by filename, not @-import (decision log 65)`" and "`4225753 merge: a router skill for every workflow (decision log 66)`"; row 65 says "`~358 KB (~89K tokens at chars/4)`" (`docs/decisions/log.md:88`).

**Evidence:** `docs/decisions/log.md:88-89`

---

## Claim 16: "`feat/dev-cycle-digest` ... hit the review loop's 3-iteration cap: its last full pass found behavioural Incorrects, fixed in baa46e3 but not re-reviewed by a full pass." (with Read: rubric "Final pass 2 table")

**Location:** `docs/working/questions.md:53`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric's status line, the Final pass 2 table's existence and baa46e3's position; does not establish that no fourth pass has run since HEAD.

The rubric (on feat/dev-cycle-digest, present in this worktree): "`**Status: 🟡 HELD — review cap reached (3 iterations); gate decision: escalate to the user.** Final pass 2 found Incorrects, fixed in baa46e3 ... but not by a fourth full pass.`" (`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:5`), with "`## Final pass 2 (iteration 3, on de53069)`" (`:48`). `git log feat/dev-cycle-digest` shows baa46e3 followed only by the artifacts commit 65bd433.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:5`, `:48-55`

---

## Claim 17: "Rely on the fix's tests (each fails on the previous script)"

**Location:** `docs/working/questions.md:61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two tests baa46e3 changed, run with baa46e3's test file against de53069's script; does not establish that those tests cover every edge of the new window-start logic.

Commands: `timeout 120 bats test/scripts/dev-cycle.bats` at baa46e3, then the same with `scripts/dev-cycle.sh` replaced by `git show de53069:scripts/dev-cycle.sh`; cwd a scratch clone; exits 0 then 1; 2026-09-29T03:04. With the new script all 13 pass; with the old one "`not ok 2 lists a decision record's revisit triggers and a log row's whole revisit clause`" and "`not ok 3 after a cycle record, unchanged triggers carry forward and changed ones print`", the two tests baa46e3's diff changed. The other 11 pass on both.

**Evidence:** `docs/reviews/execution-logs/r3-skill-final-baa46e3-tests-vs-de53069.txt`

---

## Claim 18: "the script is read-only, so the cost is a wrong digest, not damage"

**Location:** `docs/working/questions.md:61`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script at HEAD (no write commands to the repo; one mktemp file removed on EXIT); does not establish behaviour of `questions.sh open`, which it invokes.

Header: "`Read-only: writes nothing to the repo (one temp file, removed on exit).`" (`scripts/dev-cycle.sh:16`); the only file creation is "`qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT`" (`:148`). The remaining git calls are `rev-parse`, `symbolic-ref`, `log`, `rev-list`, `show`, `merge-base` (paraphrased — no quote available because the claim covers absence of writes across the whole 187-line script, read in full). The `git status` call that rewrote `.git/index` was removed in baa46e3 (rubric F2, `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:53`).

**Evidence:** `scripts/dev-cycle.sh:1-187`

---

## Claim 19: Q-099 "Read: ... `docs/reviews/architecture-review-2026-09-29-devcycle.md` finding 3" and option [2] "Next #1 (resume SI) ranks work in a list it doesn't read"

**Location:** `docs/working/questions.md:73-79`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited finding's subject and the roadmap's Next #1; does not establish the options' costs.

The architecture review: "`Finding 3 is a design choice worth settling before the roadmap accumulates: decide whether the roadmap references questions and SI outputs or restates them.`" (`docs/reviews/architecture-review-2026-09-29-devcycle.md:138`). Roadmap Next #1 is "`**Q-075 — evidence that the self-improvement loop is safe to resume.**`" (`docs/roadmap.md:20`).

**Evidence:** `docs/reviews/architecture-review-2026-09-29-devcycle.md:138`, `docs/roadmap.md:20`

---

## Claim 20: Questions index rows for Q-099 and Q-100 (the generated index is current)

**Location:** `docs/working/questions.md:28-29`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `questions.sh check` on HEAD's questions doc; does not establish that the entries' options are complete.

Command: `timeout 60 bash scripts/questions.sh check`; cwd a scratch clone at e438cd1; exit 0; 2026-09-29T03:04:10-07:00. Output: "`✓ questions: structure valid, indexes current`".

**Evidence:** `docs/reviews/execution-logs/r3-skill-final-questions-check.txt`

---

## Claim 21: "The outer loop over rows 6/9: health and cleanup, revisit triggers, spot-check audit, brainstorm, roadmap (`docs/roadmap.md`). User-started, no timer. Output is triage in `docs/working/questions.md`."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that rows 6 and 9 are RPI and pr-prep and the skill's description; does not establish first-match routing outcomes against rows 1–11.

Rows 6 and 9 are "`research-plan-implement.md`" and "`| 9 | **Work is ready to open a PR**`" → "`pr-prep.md`" (`global-instructions/CLAUDE.md:26`, `:29`); the skill's opening: "`The inner loop (research-plan-implement → pr-prep, with its review-fix loop) lands one change at a time`" (`skills/dev-cycle/SKILL.md:11-12`) and "`Its output`"/"`only decisions that need the user become you: judgment entries ... in docs/working/questions.md`" (`:17-19`).

**Evidence:** `global-instructions/CLAUDE.md:26-32`, `skills/dev-cycle/SKILL.md:11-20`

---

## Claim 22: "Workflow-shaped (eight ordered steps, 0–7) but, by the criteria above, a skill: ... no human checkpoint mid-run (decisions go to questions.md), and it produces a self-contained artifact (the cycle record). Its mechanical parts live in `scripts/dev-cycle.sh`."

**Location:** `guides/skill-creation.md:137`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step count, that the skill routes decisions to questions.md rather than stopping, and the criteria table's terms; does not establish the judgment that Claude completes it in one pass.

The skill has steps 0–7 (`skills/dev-cycle/SKILL.md:31-118`); user-approval items go to entries, e.g. "`deleting them needs the user's approval, so put the list in one you: terminal entry rather than deleting`" (`:48-49`) and "`propose it as one you: judgment entry instead`" (`:116`). The guide's criteria rows include "`Does it require human judgment at intermediate checkpoints? | Workflow | Skill`" and "`Does it produce a self-contained artifact (review, report, critique)? | Skill | Either`" (`guides/skill-creation.md:99`, `:103`).

**Evidence:** `guides/skill-creation.md:93-103`, `guides/skill-creation.md:137`, `skills/dev-cycle/SKILL.md:31-126`

---

## Claim 23: Description is at most 250 characters with a precedence clause ("Not for landing one change (pr-prep)")

**Location:** `skills/dev-cycle/SKILL.md:3-4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the description's length and clause; does not establish triggering behaviour in a live session.

The description "`Run one maintenance cycle: health and cleanup, revisit triggers, spot-check audit, brainstorm, roadmap. Not for landing one change (pr-prep). Triggers: ...`" (`skills/dev-cycle/SKILL.md:4`) is 245 characters (`printf '%s' ... | wc -c`), and the frontmatter has no `when:` key (`:1-5`).

**Evidence:** `skills/dev-cycle/SKILL.md:1-5`

---

## Claim 24: "Run `~/.claude/scripts/dev-cycle.sh` from the repo root (inside claude-workflows, its own `scripts/dev-cycle.sh`)"

**Location:** `skills/dev-cycle/SKILL.md:33-34`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the installer stages the whole `scripts/` directory into `~/.claude`; does not establish that a given host has re-run the installer since the script was added.

`devcontainer-config/install.sh:135`: "`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`". The script acts on `$PWD`'s repo — "`ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" ... cd "$ROOT"`" (`scripts/dev-cycle.sh:37-38`) — and finds questions.sh next to itself first (`:145-146`).

**Evidence:** `devcontainer-config/install.sh:125-135`, `scripts/dev-cycle.sh:36-38`, `scripts/dev-cycle.sh:145-146`

---

## Claim 25: "It is read-only and gives the window and where its start came from, merges in it, the revisit triggers that need a verdict, the watched questions, the spot-check sample and the roadmap's Next section. ... If the digest says no cycle record was found ..."

**Location:** `skills/dev-cycle/SKILL.md:35-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's sections and window-source line in a clone with and without a cycle record; does not establish output in a repo with no default branch (exit 1).

Command: `DEV_CYCLE_TODAY=2026-09-29 timeout 60 bash scripts/dev-cycle.sh --sample=1`; cwd a scratch clone at e438cd1; exit 0; 2026-09-29T03:03:59-07:00. Without a record the window line reads "`Window: since 2026-09-15 (from no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record))`", followed by `Main at:` and sections `## 1. Activity` … `## 5. Roadmap` ending in the Next section quote. Source: sections are printed at `scripts/dev-cycle.sh:88`, `:96`, `:144`, `:169`, `:179`, and the note at `:76`.

**Evidence:** `docs/reviews/execution-logs/r3-skill-final-digest-norecord.txt`, `scripts/dev-cycle.sh:70-85`

---

## Claim 26: "run the project's full check to a file (in claude-workflows: `scripts/health-check.sh`) ... triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky). `questions.sh archive` then `questions.sh index` ... If the repo has no `docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` first."

**Location:** `skills/dev-cycle/SKILL.md:37-47`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the script, the subcommands and pr-prep 5a's three classes; does not establish that the health check passes today.

`scripts/health-check.sh` exists; pr-prep 5a's table rows are "`| Caused by this branch |`", "`| Pre-existing on main |`", "`| Flaky / infra / environmental |`" (`workflows/pr-prep.md:341-343`); questions.sh dispatches "`init)    cmd_init ;;`", "`index)   cmd_index ;;`", "`archive) cmd_archive ;;`", "`open)    cmd_open ;;`" (`scripts/questions.sh:447-452`).

**Evidence:** `workflows/pr-prep.md:337-343`, `scripts/questions.sh:446-452`

---

## Claim 27: "Do not run `archive-working-docs.sh`: it serves the self-improvement loop and moves files into a gitignored archive."

**Location:** `skills/dev-cycle/SKILL.md:50-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script's stated purpose and its destination's ignore status; does not establish which files it would move in a given checkout.

"`# Archive docs/working/ artifacts from a completed self-improvement run.`" and "`# Moves all non-permanent files from docs/working/ into docs/working/archive/`" (`scripts/archive-working-docs.sh:2`, `:6`); `git check-ignore -v docs/working/archive/x.md` → "`.gitignore:16:docs/working/archive/`".

**Evidence:** `scripts/archive-working-docs.sh:1-12`, `.gitignore:16`

---

## Claim 28: "For every trigger the digest prints in full ... Triggers the digest lists as carried forward keep the previous record's verdict, unless that verdict was "cannot tell" or "fired": re-decide those." and "If the digest says `questions.sh open` failed, fix that first"

**Location:** `skills/dev-cycle/SKILL.md:57-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's "Printed in full" and "Carried forward" wording with a cycle record present, and the failure line's text; does not establish that carried triggers' previous verdicts are readable (the skill must open the old record itself).

Same command as Claim 25 after writing `docs/working/cycles/cycle-2026-09-28.md` containing a `Main at:` line; exit 0; 2026-09-29T03:03:59-07:00. Output: "`Printed in full: triggers in decision records changed since 2026-09-28, and log rows dated on or after it. Listed by name only: the rest, whose verdict carries forward from docs/working/cycles/cycle-2026-09-28.md unless that record says "cannot tell" or "fired".`" and "`Carried forward (16): 014-secure-tool-guidance-layers.md ...`". The failure text is "`echo "**questions.sh open failed** — watched questions were NOT checked. Its error:"`" (`scripts/dev-cycle.sh:161`).

**Evidence:** `docs/reviews/execution-logs/r3-skill-final-digest-record.txt`, `scripts/dev-cycle.sh:96-142`, `scripts/dev-cycle.sh:160-164`

---

## Claim 29a: "the digest's `Main at: <sha>` line copied verbatim ... The next digest starts its window from this file's date and compares triggers against the recorded commit"

**Location:** `skills/dev-cycle/SKILL.md:121-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parse of a verbatim-copied line and the window source; does not establish that a line copied with a list-marker prefix ("- Main at:") parses — it does not, since the regex is anchored at line start — nor use of the record when `--since` is given.

The printed line is "`echo "Main at: $MAIN_SHA (copy this line into the cycle record; ...)"`" (`scripts/dev-cycle.sh:85`); the parser takes "`sed -n 's/^Main at: \([0-9a-f]\{7,40\}\).*/\1/p'`" (`:108`), which accepts the trailing parenthetical. The window comes from the newest record's date (`:64-73`), and the recorded commit is used as the base only when it is an ancestor of the default branch, else the last first-parent commit before the window: "`git merge-base --is-ancestor "$base" "$MAIN_SHA" 2>/dev/null || base="$(git rev-list -1 --first-parent --before="$SINCE_TS" "$MAIN_SHA")"`" (`:109`).

**Evidence:** `scripts/dev-cycle.sh:64-73`, `scripts/dev-cycle.sh:85`, `scripts/dev-cycle.sh:107-109`

---

## Claim 29b: "so a cycle without the record silently falls back to 14 days"

**Location:** `skills/dev-cycle/SKILL.md:123-124`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's output when no record exists; does not establish anything about a record that exists but lacks a `Main at:` line (that case falls back to a date-based base, not to 14 days).

The fall-back is no longer silent. Since d8b0cca the digest names it: "`source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"`" (`scripts/dev-cycle.sh:76`), printed in the Window line (run in Claim 25's log). The skill's own step 0 relies on that message: "`If the digest says no cycle record was found but earlier cycles ran, the last one skipped step 7`" (`skills/dev-cycle/SKILL.md:38-39`). "Silently" matched the pre-fix script (architecture review finding 1: "`when that step is skipped the digest silently narrows to 14 days`", `docs/reviews/architecture-review-2026-09-29-devcycle.md:138`). The missing record also makes the next digest print every trigger in full rather than carrying any forward (`scripts/dev-cycle.sh:100-102`), which the sentence omits. Precise version: "so a cycle without the record makes the next digest fall back to 14 days (it says so) and re-print every trigger."

**Evidence:** `scripts/dev-cycle.sh:76`, `scripts/dev-cycle.sh:97-103`, `docs/reviews/execution-logs/r3-skill-final-digest-norecord.txt`

---

## Claim 30: Commit 1f8ed13: "11 decision records and 7 log rows carry revisit triggers that nothing read" and "test/dev-cycle.bats: six hermetic tests in throwaway repos"; commit 89a3d3b: "dev-cycle description <=250 chars with a precedence clause; no when:" and "README: 34 skills"

**Location:** `1f8ed13` (commit message), `89a3d3b` (commit message)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts at each commit and its parent; does not establish the tests' hermeticity beyond their count.

1f8ed13's parent is ec297d4, where the counts are 11 records and 7 log rows (Claim 4's log); `git show 1f8ed13:test/dev-cycle.bats | grep -c '^@test'` → 6. At 89a3d3b the description (then "`... Triggers: "run the dev cycle", "maintenance pass", "what next", "update the roadmap".`") has no `when:` key and the skills directory count is 34 (paraphrased — no quote available because the counts come from `git ls-tree`/`grep -c` output, not a file line).

**Evidence:** `docs/reviews/execution-logs/r3-skill-final-trigger-counts.txt`, `test/dev-cycle.bats` (at 1f8ed13), `skills/dev-cycle/SKILL.md:1-5` (at 89a3d3b)

---

## Claim 31: Commit d8b0cca: "size gate: the unit is now 531 code lines against main (cap 400). Split ... into feat/dev-cycle-digest (script + tests) and feat/dev-cycle stacked on it"; "Test moved to test/scripts/"; "Rubric, reports, override rows"; Must Fix "The branch now resolves to a hash; option-like names are rejected"

**Location:** `d8b0cca` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count with pr-prep step 1a's command, the file move, the override rows and the option-branch guard at HEAD; does not re-verify the message's other Must Address items beyond the digest tests passing (Claim 17's log, 13/13 on the fixed script).

`git diff --numstat main...d8b0cca -- ':(top)' ':(top,exclude)docs/' | awk ...` → 531 (merge base 4225753). `test/dev-cycle.bats` is gone at HEAD and `test/scripts/dev-cycle.bats` exists; d8b0cca adds 5 lines to `docs/reviews/override-log.md` (`--stat`: "`docs/reviews/override-log.md | 5 +`"). The guard: "`[[ "$c" == -* ]] && continue`" and "`sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" ...)"`" (`scripts/dev-cycle.sh:51-52`), with git log fed "`$MAIN_SHA`" (`:89`). The current unit (feat/dev-cycle-digest...HEAD, outside docs/) is 130 lines, under the cap.

**Evidence:** `scripts/dev-cycle.sh:43-62`, `scripts/dev-cycle.sh:89`, `test/scripts/dev-cycle.bats`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`docs/roadmap.md:27-29`): the live-verify gate accepts `Live-verified: no — <why>`, so host tools are not blocked by a trailer "they can never satisfy". The real motive (Q-083): every host-tool commit adds a `Live-verified: no` debt entry, and a changed host tool blocks cc-isolated launches until re-blessed. Reword the motive line.

### Stale
- **Claim 29b** (`skills/dev-cycle/SKILL.md:123-124`): "silently falls back to 14 days" predates d8b0cca; the digest now prints "no cycle record found, so the default of 14 days", and step 0 of the same skill relies on that line. Drop "silently" (and optionally note that every trigger is then re-printed in full).

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:90`): "nine unwritten runs" is a lower bound in its source ("≥9 runs", in-run capture 0/9). Say "at least nine".

### Unverifiable
- (none)

---

## Goal-Alignment Note

- **Answered:** Every claim in the scoped diff and the five commit messages that a reader could act on, including all items in the brief's "Particularly check" list: skill instructions against the digest's actual output (section names, "Printed in full", "Carried forward", "questions.sh open failed", "no cycle record found", "Main at:", run in a clone), every command/path/cross-reference (installed path via install.sh, questions.sh init/archive/index/open, health-check.sh, pr-prep 5a, "Running questions document" heading at `global-instructions/CLAUDE.md:234`, code-fact-check and divergent-design skills exist), roadmap facts (Q-IDs, merges c9a370a/4225753, override-log rows, the 33fdfd3 conflicts), row 67, Q-099, Q-100 (including executing its "each fails on the previous script" claim), row 12, README and guide lines. All pass-1 fixes listed in the brief hold at HEAD, except that step 7's "silently" (Claim 29b) no longer matches the digest the pass-1 fixes produced.
- **Out of scope:** scripts/dev-cycle.sh and its tests as review targets (read as context only; their claims were not verdicted except where the scoped files depend on them). Q-100 option [1]'s "~1.3M tokens" estimate was not verdicted (a forecast, not a checkable claim).
- **Escalate:** none. Claim 8 is low-stakes (a roadmap motive line) but a reader acting on it would misunderstand what Q-089 fixes.
