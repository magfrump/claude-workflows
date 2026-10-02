Commit: e438cd1

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-devcycle, branch feat/dev-cycle)
**Scope:** `git diff feat/dev-cycle-digest...HEAD -- . ':(exclude)docs/reviews'` (README.md, docs/decisions/log.md row 67, docs/roadmap.md, docs/working/questions.md Q-099/Q-100, global-instructions/CLAUDE.md row 12, guides/skill-creation.md, skills/dev-cycle/SKILL.md) plus commit messages `git log feat/dev-cycle-digest..HEAD --no-merges`. scripts/dev-cycle.sh and test/scripts/dev-cycle.bats read as context only. Replicate r1 of 3, final confirming pass.
**Checked:** 2026-09-29
**Total claims checked:** 33
**Summary:** 29 verified, 1 mostly accurate, 1 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first; no claim below matches a logged pattern.

Executed probes ran in a throwaway clone at `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc-r1/repo` (cloned from the worktree, checked out at e438cd1), each under `timeout 60`. No process was left running (checked with `pgrep`).

---

## Claim 1: "`skills/` holds 34 Claude Code skills … the `dev-cycle` skill (the outer maintenance loop; `docs/roadmap.md`)"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill count at HEAD and that dev-cycle is a skill directory; does not establish that `install.sh` copies every one of them or that the other named skills in the sentence are complete.

`ls skills/*/SKILL.md | wc -l` returns `34` at HEAD and `33` on `feat/dev-cycle-digest` (paraphrased — no quote available because the claim is about directory layout, not a snippet); `skills/dev-cycle/SKILL.md:2` reads `name: dev-cycle`.

**Evidence:** `skills/dev-cycle/SKILL.md:2`, `README.md:182`

---

## Claim 2: Row 67 — "Steps: digest → health and cleanup → revisit-trigger verdicts (fired / not fired / cannot tell, with evidence) → watched questions → spot-check audit … → brainstorm … → roadmap (Now / Next ≤5 / Ideas / Done) → cycle record in `docs/working/cycles/cycle-YYYY-MM-DD.md`. The user starts it; there is no timer. … The global decision tree gains row 12."

**Location:** `docs/decisions/log.md:90`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step order, roadmap sections, record path, no-timer statement and row 12 against the skill and global instructions; does not establish that any cycle has run.

The skill's headings are `### 0. Digest` … `### 7. Close` in that order (`skills/dev-cycle/SKILL.md:31,41,55,65,73,82,91,118`); step 2 says "decide **fired / not fired / cannot tell**" (`:57`); step 6's template has `## Now`/`## Next`/`## Ideas`/`## Done` and "**Next**: at most five items" (`:102-109`); step 7 writes "`docs/working/cycles/cycle-YYYY-MM-DD.md`" (`:120`); the intro says "It runs when the user starts it; there is no timer." (`:14`). `global-instructions/CLAUDE.md:32` is `| 12 | **Maintenance or planning pass over the repo** …`.

**Evidence:** `skills/dev-cycle/SKILL.md:14-126`, `global-instructions/CLAUDE.md:32`

---

## Claim 3: Row 67 — "As of 2026-09-28, 11 decision records carried revisit triggers and 7 log rows mentioned a revisit condition"

**Location:** `docs/decisions/log.md:90`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts at the last main commit before 2026-09-28 23:59 (5ee8315); does not establish the counts on unmerged branches that day.

At `git rev-list -1 --before='2026-09-28 23:59' main` = `5ee8315`, the files under `docs/decisions/NNN-*.md` containing `^## Revisit triggers` number 11, and `log.md` rows matching `^\| [0-9]+ \|` and `-i revisit` number 7 (paraphrased — no quote available because the claim is a count over many files; commands as stated). At HEAD there are still 11 records and the matching rows are 35, 53, 57, 58, 60, 62, 63 plus the later 65, 66, 67.

**Evidence:** `docs/decisions/log.md:90`, `docs/decisions/` (at 5ee8315)

---

## Claim 4: Row 67 — "no recurring step read them (codebase-onboarding step 10 reads the records once, at onboarding)"

**Location:** `docs/decisions/log.md:90`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which workflow steps read `## Revisit triggers`; does not establish how often onboarding refreshes run in practice.

Onboarding step 10 greps them: "`grep '## Revisit triggers' docs/decisions/*.md` to find decision records that name re-examination conditions" (`workflows/codebase-onboarding.md`, step 10 recipe). But it is not only "once, at onboarding": the lightweight refresh repeats it — "4. **Rebuild Watch Signals.** Re-run step 10's grep + relevance filter against `docs/decisions/*.md`." (`workflows/codebase-onboarding.md`, Lightweight refresh process). Precise version: read at onboarding and at each onboarding re-run or refresh, which are staleness-triggered, not scheduled. The conclusion (no recurring step) holds.

**Evidence:** `workflows/codebase-onboarding.md` (step 10; "Lightweight refresh" step 4)

---

## Claim 5: Row 67 — "steps only prose asks for do not run (Q-074; the override log's nine unwritten runs)"

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both cited sources exist and say this; does not establish the general claim beyond those two cases.

Q-074: "`docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only." (`docs/working/questions.md:107`). The override-log diagnosis: "the eligible population is **≥9**, the observed capture rate is **≤1/9**" and "Every in-run automated path retains a 0/9 record." (`archive/docs/2026-08-06-handoff-diagnosis-override-log-not-written.md:62,69`). "Nine" is the stated minimum.

**Evidence:** `docs/working/questions.md:104-109`, `archive/docs/2026-08-06-handoff-diagnosis-override-log-not-written.md:59-69`

---

## Claim 6: Row 67 — "the self-improvement loop's `feature-ideas*.md` is read as a signal in step 5 (interim for Q-099)"

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill text and Q-099's interim; does not establish that those files exist in a given checkout (the per-round files are gitignored, `.gitignore:28`).

Skill step 5 lists "an item from the self-improvement loop's `docs/working/feature-ideas*.md`" (`skills/dev-cycle/SKILL.md:86-87`); Q-099: "**Interim:** [1]. Step 5 lists `feature-ideas*.md` as a signal source" (`docs/working/questions.md` Q-099). The SI loop writes `docs/working/feature-ideas-round-N.md` (`scripts/self-improvement.sh:38`).

**Evidence:** `skills/dev-cycle/SKILL.md:84-89`, `scripts/self-improvement.sh:38`, `.gitignore:28`

---

## Claim 7: Roadmap header — "Maintained by the `dev-cycle` skill …, step 6; each cycle's record is in `docs/working/cycles/`"

**Location:** `docs/roadmap.md:3-5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step number and record directory; does not establish anything about the seed's ranking.

`### 6. Roadmap` / "Update `docs/roadmap.md`" (`skills/dev-cycle/SKILL.md:91-93`); step 7 writes `docs/working/cycles/cycle-YYYY-MM-DD.md` (`:120`).

**Evidence:** `skills/dev-cycle/SKILL.md:91-93,120`

---

## Claim 8: Next 1 — "Q-075 … Q-068 was answered 'resume' on condition of this evidence … First step: list every path, config, hook, credential and git ref `scripts/self-improvement.sh` can write outside its working docs."

**Location:** `docs/roadmap.md:20-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-075/Q-068 facts; does not establish when the loop last ran.

Q-075: "Q-068 was answered "resume", but only once the user trusts `scripts/self-improvement.sh` not to break their setup. Build the evidence for that: list every path, config, hook, credential and git ref the loop can write outside its own working docs" (`docs/working/questions.md:114`). Q-068: "**Answered 2026-09-27: [3] resume** … the loop stays dormant until that trust exists. The trust work is filed as Q-075." (`docs/working/questions-archive.md:1370`).

**Evidence:** `docs/working/questions.md:111-118`, `docs/working/questions-archive.md:1367-1370`

---

## Claim 9: Next 2 — "Q-088 — spike `sandbox.enableWeakerNestedSandbox` in cc-isolated. Motive: Q-098 (a global allow list) waits on a Bash sandbox."

**Location:** `docs/roadmap.md:24-26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-088/Q-098 relationship; does not establish the spike's outcome.

Q-088: "Spike, per Q-081 [2]: can Claude Code's `sandbox.enableWeakerNestedSandbox` run Bash sandboxed inside cc-isolated" (`docs/working/questions.md:202`); Q-098: "Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088)." (`:178`).

**Evidence:** `docs/working/questions.md:175-206`

---

## Claim 10: Next 3 — "`cc-push.sh` and the exit scan are gated by a `Live-verified:` trailer they can never satisfy, since they run only on the host (Q-083 [1])"

**Location:** `docs/roadmap.md:27-29`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the live-verify gate requires of a commit touching these files; does not establish the launch-blocking half of Q-083's problem (check_manifest), which the roadmap line does not state.

The gate is satisfied by a negative trailer: "the commit message must carry a `Live-verified:` trailer. The value is free text on purpose — … or `Live-verified: no — <why, and what will run it>`. The gate does not judge the answer" (`hooks/live-verify-gate.sh:16-20`), and "trailer present → exit 0" (`:35`). So the gate does not block these commits. Q-083 states the actual cost: "host tools can't be live-probed, so every commit to them carries `Live-verified: no`, which dilutes row 45's debt list. `check_manifest` runs only when cc-isolated launches, so a changed `cc-push.sh` blocks every launch until re-blessed" (`docs/working/questions-archive.md:1581`). A reader would take "a trailer they can never satisfy" to mean commits to these files are blocked. Precise version: every commit to them has to carry `Live-verified: no`, which dilutes row 45's debt list, and a changed host tool blocks cc-isolated launches until it is re-blessed.

**Evidence:** `hooks/live-verify-gate.sh:13-40`, `docs/working/questions-archive.md:1572-1586`

---

## Claim 11: Next 4 — "Measure router uptake. Motive: log row 66's revisit trigger. … an artifact count, not the usage log, which under-counts, Q-017"

**Location:** `docs/roadmap.md:30-33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with row 66's trigger and Q-017's answer; does not establish how the count would be computed.

Row 66: "Revisit if, over the first three dev cycles after install, multi-file merges still land without the RPI research/plan docs or pr-prep review artifacts they should carry (an artifact count, not the usage log)" (`docs/decisions/log.md:89`). Q-017: "**Answered 2026-09-17: the measurement is not trustworthy, so the finding is withdrawn as evidence.**" (`docs/working/questions-archive.md:227`).

**Evidence:** `docs/decisions/log.md:89`, `docs/working/questions-archive.md:218-232`

---

## Claim 12: Next 5 — "A8 post-restructure token measurement. Motive: the user deferred big compute until code and prompts settle; it validates code-review lever #3."

**Location:** `docs/roadmap.md:34-36`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the user's auto-memory; does not establish it from any repo artifact.

The source is outside the repo: the user memory `run-a8-measurement-after-settling.md` reads "the post-restructure measurement of code-review lever #3 … should be run — but only after the code/prompt changes in /workspace are fully settled" (quoted from `~/.claude/projects/-workspace/memory/run-a8-measurement-after-settling.md`, not a repo path). It matches, but a repo reader cannot check it. The roadmap header does say it was seeded "from … project memory" (`docs/roadmap.md:9`). To verify in-repo: cite the rubric A8 row (`docs/reviews/code-review-rubric-2026-08-07-main.md`, named in that memory).

**Evidence:** `docs/roadmap.md:9,34-36`

---

## Claim 13: Ideas — Q-079 "Signal: the review canon grows only by hand (Q-072)"; failure-pattern harvest "Signal: Q-074, 1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26 if fewer than 5 new entries have landed by then."

**Location:** `docs/roadmap.md:42-46`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-072/Q-074/Q-079 facts; does not establish current failure-pattern counts.

Q-074: "has gained 1 entry across about 128 `fix` commits … If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment" (`docs/working/questions.md:107`). Q-079: "Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance" (`:123`); Q-072: the ledger "hasn't changed since 2026-08-18 … none feed back into it" (`docs/working/questions-archive.md:1449`).

**Evidence:** `docs/working/questions.md:104-126`, `docs/working/questions-archive.md:1446-1460`

---

## Claim 14: Ideas — code-review description overlap and skill-format-audit F1 `when:` are "override log, deferred from log row 66's review"

**Location:** `docs/roadmap.md:47-50`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of both deferral rows; does not establish that the underlying issues are still present.

`docs/reviews/override-log.md:161`: "`skills/code-review/SKILL.md` description still says "default whenever a PR is prepared or evaluated", overlapping pr-prep … | Deferred | … Candidate for the first dev cycle." `:164`: "`test/skills/divergent-design-router.bats` still requires `when:`/`trigger` … Deferred | … finishing skill-format-audit F1 repo-wide is a separate change." Both rows are on `feat/workflow-router-skills` (row 66's branch).

**Evidence:** `docs/reviews/override-log.md:161,164`

---

## Claim 15: Ideas — "merging the row-66 branch hit conflicts on `code-fact-check-report-r*.md` (undated, so any two branches collide) and add/add conflicts on `*-review-<date>.md`"

**Location:** `docs/roadmap.md:51-53`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which files both sides of merge 33fdfd3 changed; does not establish that git reported each one as a conflict (the merge commit does not record conflict markers), and "any two branches collide" holds only for the canonical undated names, not suffixed ones like `-r1-routers-3a63c56.md`.

Files changed on both sides of `33fdfd3` since their merge base: `docs/decisions/log.md`, `docs/reviews/code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`, `docs/reviews/override-log.md`, `docs/reviews/performance-review-2026-09-29.md`, `docs/reviews/security-review-2026-09-29.md` (paraphrased — no quote available because this is `comm -12` output over two `git diff --name-only` lists). The merge message: "Review artifacts that share canonical names with fix/agents-md-no-imports keep main's copy; this branch's copies are kept under -routers-<sha> names."

**Evidence:** `git show 33fdfd3` (commit message and stat)

---

## Claim 16: Done — "AGENTS.md names workflows by filename … (log row 65, merge c9a370a). Removes ~89K tokens …" and "A router skill for every workflow except review-fix-loop (log row 66, merge 4225753)."

**Location:** `docs/roadmap.md:59-61`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge hashes, subjects and the ~89K figure as recorded by row 65; does not re-measure the token count.

`c9a370a merge: AGENTS.md names workflows by filename, not @-import (decision log 65)`, `4225753 merge: a router skill for every workflow (decision log 66)` (`git log -1`), and 4225753 is an ancestor of HEAD. Row 65: "put ~358 KB (~89K tokens at chars/4) of workflow text into every session and subagent here" (`docs/decisions/log.md:88`).

**Evidence:** `docs/decisions/log.md:88-89`

---

## Claim 17: Q-100 — "`feat/dev-cycle-digest` … hit the review loop's 3-iteration cap: its last full pass found behavioural Incorrects, fixed in baa46e3 but not re-reviewed by a full pass." Read: "`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` (Final pass 2 table)"

**Location:** `docs/working/questions.md` (Q-100 entry)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit, rubric file and section cited; does not establish whether baa46e3 itself is correct (lower unit, out of scope).

The rubric exists and says "**Status: 🟡 HELD — review cap reached (3 iterations); gate decision: escalate to the user.** Final pass 2 found Incorrects, fixed in baa46e3 and verified by tests (each new test fails on the previous script) and the fix-drift check, but not by a fourth full pass." (`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:5`), with `## Final pass 2 (iteration 3, on de53069)` at `:48`. baa46e3's body: "this is the fix phase of iteration 3, the review loop's cap; the unit is held (gate decision: escalate)".

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:5,48`

---

## Claim 18: Q-099 — Read: "`docs/reviews/architecture-review-2026-09-29-devcycle.md` finding 3"; Interim "[1]. Step 5 lists `feature-ideas*.md` as a signal source; nothing in the SI loop changes."

**Location:** `docs/working/questions.md` (Q-099 entry)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited finding and the interim's agreement with the skill; does not judge the options.

`#### 3. The roadmap duplicates questions.md state, and a third idea store sits beside feature-ideas.md` (`docs/reviews/architecture-review-2026-09-29-devcycle.md:52`); skill step 5 names `docs/working/feature-ideas*.md` (`skills/dev-cycle/SKILL.md:86-87`); nothing on this branch changes `scripts/self-improvement.sh` (`git diff --stat` lists no such file).

**Evidence:** `docs/reviews/architecture-review-2026-09-29-devcycle.md:52-58`, `skills/dev-cycle/SKILL.md:84-89`

---

## Claim 19: questions.md index rows for Q-099 and Q-100 are current (generated index, "edit entries, not the table")

**Location:** `docs/working/questions.md:28-29`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `questions.sh check` validity and index stability on a copy of the two files; does not establish other repos' questions docs.

Command, run 2026-09-29T10:01Z in `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc-r1` (a copy of `docs/working/questions.md` and `questions-archive.md` in a fresh `git init`): `timeout 30 bash /workspace/.claude/wt-devcycle/scripts/questions.sh check` → `✓ questions: structure valid, indexes current`, exit 0; then `questions.sh index` followed by `diff` against the original gave no difference (`index-stable`). Output was captured only in the terminal transcript, since it is two lines: paraphrased — no quote available because no output file was written for this probe; it is reproducible with the command above.

**Evidence:** `docs/working/questions.md:25-31`, `scripts/questions.sh:447-452`

---

## Claim 20: Decision-tree row 12 — "`dev-cycle` skill … The outer loop over rows 6/9: health and cleanup, revisit triggers, spot-check audit, brainstorm, roadmap (`docs/roadmap.md`). User-started, no timer. Output is triage in `docs/working/questions.md`."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill; does not establish first-match ordering against rows 1–11 for these trigger phrases.

The skill: "The inner loop (`research-plan-implement` → `pr-prep`, with its review-fix loop) lands one change at a time" (`skills/dev-cycle/SKILL.md:11-12`), "It runs when the user starts it; there is no timer." (`:14`), and decisions become entries "in `docs/working/questions.md`" (`:19`). Rows 6 and 9 are RPI and pr-prep (`global-instructions/CLAUDE.md` decision-tree table).

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:11-20`

---

## Claim 21: Guide row — "Workflow-shaped (eight ordered steps, 0–7) but, by the criteria above, a skill: Claude completes it in one pass given the digest, with no human checkpoint mid-run (decisions go to questions.md), and it produces a self-contained artifact (the cycle record)."

**Location:** `guides/skill-creation.md:137`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step count and the mapping onto the guide's criteria table; does not establish that no future step needs a gate.

Steps `### 0.` through `### 7.` (`skills/dev-cycle/SKILL.md:31-118`). The criteria table: "Does it require human judgment at intermediate checkpoints? | Workflow | Skill", "Can Claude complete it in a single pass given the right context? | Skill | Workflow", "Does it produce a self-contained artifact (review, report, critique)? | Skill | Either" (`guides/skill-creation.md:97-103`). The skill routes user decisions to entries rather than waiting: "propose it as one `you: judgment` entry instead" (`skills/dev-cycle/SKILL.md:116`), and branch deletion goes "in one `you: terminal` entry rather than deleting" (`:49`).

**Evidence:** `guides/skill-creation.md:93-103,137`, `skills/dev-cycle/SKILL.md:49,116`

---

## Claim 22: Description ≤250 characters with a precedence clause

**Location:** `skills/dev-cycle/SKILL.md:3-4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers length (folded scalar, single line) and the clause's presence; does not establish how the harness truncates it.

`Run one maintenance cycle: health and cleanup, revisit triggers, spot-check audit, brainstorm, roadmap. Not for landing one change (pr-prep). Triggers: …` (`skills/dev-cycle/SKILL.md:4`) measures 245 characters (awk join + `wc -c`, trailing newline excluded).

**Evidence:** `skills/dev-cycle/SKILL.md:3-4`

---

## Claim 23: Step 0 — "Run `~/.claude/scripts/dev-cycle.sh` from the repo root (inside claude-workflows, its own `scripts/dev-cycle.sh`)" and "run `~/.claude/scripts/questions.sh init` first"

**Location:** `skills/dev-cycle/SKILL.md:33-38`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that install stages `scripts/` into `~/.claude` and that both scripts and the `init` subcommand exist; does not establish that the user has re-run install since the script was added.

`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`); `scripts/dev-cycle.sh` and `scripts/questions.sh` exist; `init)    cmd_init ;;` (`scripts/questions.sh:447`). The digest acts on the invoking repo: "Acts on $PWD's git repo (like questions.sh), so the installed copy serves any project." (`scripts/dev-cycle.sh:15-16`).

**Evidence:** `devcontainer-config/install.sh:125-135`, `scripts/questions.sh:447-452`, `scripts/dev-cycle.sh:15-16`

---

## Claim 24: Step 0 — "It is read-only and gives the window and where its start came from, merges in it, the revisit triggers that need a verdict, the watched questions, the spot-check sample and the roadmap's Next section."

**Location:** `skills/dev-cycle/SKILL.md:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the section list and read-only behaviour in one clone run; does not establish behaviour with a remote whose origin/HEAD is unusual.

Command: `DEV_CYCLE_TODAY=2026-09-29 timeout 60 bash scripts/dev-cycle.sh`, cwd the throwaway clone, exit 0, 2026-09-29T10:01:51Z. Output headings: `Window: since 2026-09-15 (from no cycle record found, …)`, `## 1. Activity`, `## 2. Revisit triggers`, `## 3. Watched questions (trigger and deferred routes)`, `## 4. Spot-check sample`, `## 5. Roadmap`. `git status --porcelain` in the clone afterwards was empty. Script header: "Read-only: writes nothing to the repo (one temp file, removed on exit)." (`scripts/dev-cycle.sh:16`).

**Evidence:** `docs/reviews/execution-logs/fc-skill-final-r1-digest-norecord.txt`, `scripts/dev-cycle.sh:82-187`

---

## Claim 25: Step 0 — "If the digest says no cycle record was found but earlier cycles ran, the last one skipped step 7: note it and pass `--since` explicitly."

**Location:** `skills/dev-cycle/SKILL.md:38-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's wording in the no-record case and that `--since` makes every trigger print in full; does not establish detection of a record that exists only on another branch.

Same run as Claim 24 printed `from no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)`, from `source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"` (`scripts/dev-cycle.sh:76`). With `--since`, `full=1` and the digest prints "An explicit --since was given … so every trigger is printed in full." (`scripts/dev-cycle.sh:101-102`).

**Evidence:** `docs/reviews/execution-logs/fc-skill-final-r1-digest-norecord.txt`, `scripts/dev-cycle.sh:70-77,97-103`

---

## Claim 26: Step 1 — "run the project's full check to a file (in claude-workflows: `scripts/health-check.sh`) … triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)"; "`questions.sh archive` then `questions.sh index`"

**Location:** `skills/dev-cycle/SKILL.md:43-47`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the script, subcommands and pr-prep triage classes exist as named; does not establish the health check's runtime.

`scripts/health-check.sh` exists. pr-prep 5a: "**Triage failures by class**" with rows "Caused by this branch", "Pre-existing on main", "Flaky / infra / environmental" (`workflows/pr-prep.md`, step 5a table). `archive) cmd_archive ;;` and `index)   cmd_index ;;` (`scripts/questions.sh:449-450`).

**Evidence:** `scripts/questions.sh:447-452`, `workflows/pr-prep.md` (step 5a)

---

## Claim 27: Step 1 — "Do not run `archive-working-docs.sh`: it serves the self-improvement loop and moves files into a gitignored archive."

**Location:** `skills/dev-cycle/SKILL.md:50-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script's stated purpose and destination and the ignore rule; does not establish its behaviour on every file class.

"# Archive docs/working/ artifacts from a completed self-improvement run." and "Moves all non-permanent files from docs/working/ into docs/working/archive/" (`scripts/archive-working-docs.sh:2,6`); `.gitignore:16` is `docs/working/archive/`.

**Evidence:** `scripts/archive-working-docs.sh:1-22`, `.gitignore:16`

---

## Claim 28: Step 2 — "For every trigger the digest prints in full, decide … Triggers the digest lists as carried forward keep the previous record's verdict, unless that verdict was "cannot tell" or "fired": re-decide those."

**Location:** `skills/dev-cycle/SKILL.md:57-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's "Printed in full" / "Carried forward" lines with a prior record present; does not establish that the carry-forward selection itself is complete (lower unit).

Command: after committing `docs/working/cycles/cycle-2026-09-29.md` containing the first run's `Main at:` line verbatim, `DEV_CYCLE_TODAY=2026-09-30 timeout 60 bash scripts/dev-cycle.sh`, cwd the clone, exit 0, 2026-09-29T10:02:00Z. It printed `Printed in full: triggers in decision records changed since 2026-09-29, and log rows dated on or after it. Listed by name only: the rest, whose verdict carries forward from docs/working/cycles/cycle-2026-09-29.md unless that record says "cannot tell" or "fired".` and `Carried forward (19): 014-secure-tool-guidance-layers.md …`, matching `scripts/dev-cycle.sh:99,141`.

**Evidence:** `docs/reviews/execution-logs/fc-skill-final-r1-digest-record.txt`, `scripts/dev-cycle.sh:96-142`

---

## Claim 29: Step 3 — "For each open `trigger` or `deferred` entry … If the digest says `questions.sh open` failed, fix that first; the section was not checked."

**Location:** `skills/dev-cycle/SKILL.md:67-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the digest's filter and failure message; does not establish questions.sh's own failure modes.

`watched="$(printf '%s\n' "$open_q" | awk -F'  +' '$2 == "trigger" || $2 == "deferred"')"` (`scripts/dev-cycle.sh:152`) and `echo "**questions.sh open failed** — watched questions were NOT checked. Its error:"` (`:161`). `open)    cmd_open ;;` exists (`scripts/questions.sh:452`).

**Evidence:** `scripts/dev-cycle.sh:144-167`, `scripts/questions.sh:408,452`

---

## Claim 30: Step 6 template sections and "Next" read by the digest

**Location:** `skills/dev-cycle/SKILL.md:95-106`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the template's `## Next` heading is what the digest extracts and that docs/roadmap.md uses the same four headings; does not establish ordering rules inside sections.

Template: `## Now`, `## Next`, `## Ideas`, `## Done` (`skills/dev-cycle/SKILL.md:102-105`); digest: `awk '/^## Next/ { on = 1; next } on && /^## / { exit } …' docs/roadmap.md` (`scripts/dev-cycle.sh:184`); roadmap headings at `docs/roadmap.md:13,18,38,55`.

**Evidence:** `skills/dev-cycle/SKILL.md:95-106`, `scripts/dev-cycle.sh:179-187`, `docs/roadmap.md:13-61`

---

## Claim 31a: Step 7 — "the digest's `Main at: <sha>` line copied verbatim … The next digest starts its window from this file's date and compares triggers against the recorded commit"

**Location:** `skills/dev-cycle/SKILL.md:120-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the window date and trigger base when the record carries the line at column 0 and the sha is an ancestor of the default branch; does not establish the fallback when the line is reformatted (e.g. as a list item) or when `--since` is passed, both of which fall back to the last first-parent commit before the window.

The digest emits `echo "Main at: $MAIN_SHA (copy this line …)"` (`scripts/dev-cycle.sh:85`) and reads it back with `sed -n 's/^Main at: \([0-9a-f]\{7,40\}\).*/\1/p'`, used only if `git merge-base --is-ancestor "$base" "$MAIN_SHA"`, else `git rev-list -1 --first-parent --before="$SINCE_TS"` (`:108-109`). The window uses the record's date: `SINCE="$last_record"` (`:73`). The executed run (Claim 28) reported `Window: since 2026-09-29 (from the last cycle record, docs/working/cycles/cycle-2026-09-29.md)` and carried unchanged triggers forward.

**Evidence:** `docs/reviews/execution-logs/fc-skill-final-r1-digest-record.txt`, `scripts/dev-cycle.sh:64-80,107-109`

---

## Claim 31b: Step 7 — "so a cycle without the record silently falls back to 14 days"

**Location:** `skills/dev-cycle/SKILL.md:123-124`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the fallback is announced; does not dispute that the fallback is 14 days.

The fallback is not silent: the digest states it in the Window line — `source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"` (`scripts/dev-cycle.sh:76`), printed as observed in the executed run (Claim 24). The skill relies on that message itself at step 0: "If the digest says no cycle record was found …" (`skills/dev-cycle/SKILL.md:38`). "Silently" matched the architecture review's finding 1 on 89a3d3b ("when that step is skipped the digest silently narrows to 14 days", `docs/reviews/architecture-review-2026-09-29-devcycle.md:138`); d8b0cca then added the source note ("the digest says where its window start came from"). Precise version: "…falls back to 14 days, and step 0 has to notice the digest's 'no cycle record found' note."

**Evidence:** `scripts/dev-cycle.sh:74-77`, `skills/dev-cycle/SKILL.md:38-39`, `docs/reviews/execution-logs/fc-skill-final-r1-digest-norecord.txt`

---

## Claim 32: Commit messages d8b0cca "size gate: the unit is now 531 code lines against main (cap 400). Split … into feat/dev-cycle-digest (script + tests) and feat/dev-cycle stacked on it"; e438cd1 "record the Main at: line; Q-100 escalates the digest review cap"; 1f8ed13 "11 decision records and 7 log rows carry revisit triggers"

**Location:** commits d8b0cca, e438cd1, 1f8ed13
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these three commit-message facts; does not re-check 1f8ed13's description of its own since-changed script (its date-seeded sample, test/dev-cycle.bats location), which later commits replaced.

`git diff --numstat main...d8b0cca -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` prints `531` (paraphrased — no quote available because this is a computed count). This unit against its base now counts `130`. e438cd1 touches `docs/working/questions.md` (+19, Q-100) and `skills/dev-cycle/SKILL.md` (step 7's "`Main at: <sha>` line copied verbatim", `skills/dev-cycle/SKILL.md:121`). The 11/7 counts match Claim 3.

**Evidence:** `skills/dev-cycle/SKILL.md:120-124`, `docs/decisions/log.md:90`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`docs/roadmap.md:27-29`): the live-verify gate accepts `Live-verified: no — …` (`hooks/live-verify-gate.sh:16-20,35`), so these commits are not blocked. Restate the motive from Q-083: every host-tool commit has to carry `Live-verified: no` (diluting row 45's debt list), and a changed host tool blocks cc-isolated launches until it is re-blessed.

### Stale
- **Claim 31b** (`skills/dev-cycle/SKILL.md:123-124`): "silently" predates d8b0cca. The digest now announces the 14-day fallback, and step 0 depends on that announcement. Drop "silently".

### Mostly Accurate
- **Claim 4** (`docs/decisions/log.md:90`): onboarding step 10 also re-runs at every onboarding re-run and lightweight refresh (refresh step 4), not just "once, at onboarding"; it is still not scheduled.

### Unverifiable
- **Claim 12** (`docs/roadmap.md:34-36`): the A8 / "lever #3" motive comes from user memory outside the repo; cite `docs/reviews/code-review-rubric-2026-08-07-main.md` A8 so it can be checked in-repo.

## Goal-Alignment Note

- **Answered:** Every instruction in the skill checked against what scripts/dev-cycle.sh at e438cd1 prints: section names, "carried forward", "printed in full", "questions.sh open failed", "no cycle record found" and "Main at:". Two runs were executed in a throwaway clone. Also checked every command, path and cross-reference (questions.sh subcommands, pr-prep 5a, "Running questions document" at `global-instructions/CLAUDE.md:234`, code-fact-check, divergent-design, install staging), the roadmap facts (Q-IDs, c9a370a, 4225753, log rows), row 67, Q-099, Q-100 (plus `questions.sh check`), decision-tree row 12, the README and guide lines, and the commit messages. The pass-1 fixes listed in the brief all hold. Two items are new: the Incorrect motive line in roadmap Next 3, and the Stale "silently" in step 7.
- **Out of scope:** Correctness of scripts/dev-cycle.sh and its tests (the lower unit, used only as ground truth). Whether the roadmap's ranking is right. I did not run health-check or the full suite.
- **Escalate:** None. Both findings are one-line text fixes.
