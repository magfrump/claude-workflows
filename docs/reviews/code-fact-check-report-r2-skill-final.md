Commit: e438cd1

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-devcycle`, branch `feat/dev-cycle`)
**Scope:** `git diff feat/dev-cycle-digest...HEAD -- . ':(exclude)docs/reviews'` (README.md, docs/decisions/log.md, docs/roadmap.md, docs/working/questions.md, global-instructions/CLAUDE.md, guides/skill-creation.md, skills/dev-cycle/SKILL.md) plus commit messages `git log feat/dev-cycle-digest..HEAD --no-merges`. `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats` (the lower unit) read as context, not reviewed. Replicate r2 of 3, final confirming pass.
**Checked:** 2026-09-29
**Total claims checked:** 29
**Summary:** 23 verified, 2 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The closest logged pattern class is "counts in commit messages/docs that don't match" (entries for 59ca38f and 37c5ea9). Every count in scope was re-counted by execution (claims 1, 22, 26, 27); none matches the pattern.

Pass-1 fixes listed in the brief were each re-checked and hold: installed path first plus never-follow line (claim 17), repo text is evidence (SKILL.md:22-24, read), wait for health check before step 4 (claim 19), no `archive-working-docs.sh` (claim 20), roadmap template inline and Next points at Q-IDs (SKILL.md:93-114, read), description ≤250 with precedence clause (claim 16), step 7 copies "Main at:" (claim 24), guide rationale and step count (claim 15), row 67 and roadmap facts (claims 1-11). One new Incorrect appears in the sentence e438cd1 rewrote (claim 25), plus a roadmap measurement defect (claim 7a).

---

## Claim 1: "As of 2026-09-28, 11 decision records carried revisit triggers and 7 log rows mentioned a revisit condition, and no recurring step read them (codebase-onboarding step 10 reads the records once, at onboarding)"

**Location:** `docs/decisions/log.md:90`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two counts at the last commit dated 2026-09-28 before this branch (1f8ed13^) and that codebase-onboarding step 10 is a one-time read; does not establish that no other recurring process anywhere reads triggers, and the counts are now 11 and 10 at HEAD (rows 66 and 67 added since, expected).

Command (cwd worktree, 2026-09-29T03:04:52-07:00): `git grep -l '^## Revisit triggers' <c> -- 'docs/decisions/[0-9][0-9][0-9]-*.md' | wc -l` and `git show <c>:docs/decisions/log.md | grep -E '^\| [0-9]+ \|' | grep -ci revisit`. Output: `1f8ed13^ 2026-09-28 22:30:09 -0700 records=11 logrows=7`. Onboarding step 10 lives in `workflows/codebase-onboarding.md` ("### 10. Build the watch signals"), which runs inside the onboarding workflow, and its lightweight-refresh step 4 re-runs it only on a refresh (paraphrased — no quote available because the claim is about where the step sits in the workflow, not one line).

**Evidence:** `docs/decisions/log.md:90`, `workflows/codebase-onboarding.md` step 10, docs/reviews/execution-logs/r2-skill-final-counts.txt

---

## Claim 2: "Mechanical parts are a script because steps only prose asks for do not run (Q-074; the override log's nine unwritten runs)"

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both cited sources exist and say this; does not re-derive the "nine runs" count from the override log's history.

`scripts/questions.sh:7-8`: "the code-review override log went unwritten for nine runs, both because only prose asked for them." `docs/working/questions.md:107`: failure-patterns "has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only."

**Evidence:** `scripts/questions.sh:5-11`, `docs/working/questions.md:104-109`

---

## Claim 3: "Steps: digest → health and cleanup → revisit-trigger verdicts ... → roadmap (Now / Next ≤5 / Ideas / Done) → cycle record in `docs/working/cycles/cycle-YYYY-MM-DD.md` ... the self-improvement loop's `feature-ideas*.md` is read as a signal in step 5 (interim for Q-099)"

**Location:** `docs/decisions/log.md:90`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that row 67's step list, roadmap sections, record path and step-5 signal match the skill and the digest's record glob; does not establish that the dev cycle's outputs are used.

Skill headings run `### 0. Digest` through `### 7. Close` (`skills/dev-cycle/SKILL.md:31-118`); `SKILL.md:109`: "**Next**: at most five items, ranked"; `SKILL.md:86-87` names "`docs/working/feature-ideas*.md`"; the digest globs `docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:65`), matching `SKILL.md:120`.

**Evidence:** `skills/dev-cycle/SKILL.md:31-126`, `scripts/dev-cycle.sh:64-69`

---

## Claim 4: "Q-075 — ... Motive: Q-068 was answered 'resume' on condition of this evidence ... First step: list every path, config, hook, credential and git ref `scripts/self-improvement.sh` can write outside its working docs."

**Location:** `docs/roadmap.md:20-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-068's answer and Q-075's stated first step; does not establish how long the loop has been dormant.

Archive `docs/working/questions-archive.md:1370`: "**Answered 2026-09-27: [3] resume** ... So the loop stays dormant until that trust exists. The trust work is filed as Q-075". `docs/working/questions.md:114`: "list every path, config, hook, credential and git ref the loop can write outside its own working docs".

**Evidence:** `docs/working/questions-archive.md:1367-1370`, `docs/working/questions.md:111-117`

---

## Claim 5: "Q-088 — ... Motive: Q-098 (a global allow list) waits on a Bash sandbox."

**Location:** `docs/roadmap.md:24-26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Q-098 → Q-088 dependency; does not establish Q-088's feasibility.

`docs/working/questions.md:178`: "Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088)."

**Evidence:** `docs/working/questions.md:175-188`, `docs/working/questions.md:199-206`

---

## Claim 6: "Q-089 — ... Motive: `cc-push.sh` and the exit scan are gated by a `Live-verified:` trailer they can never satisfy, since they run only on the host (Q-083 [1])."

**Location:** `docs/roadmap.md:27-29`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reading "they can never carry a real live-verification hash"; does not establish that the gate blocks their commits — it does not, since `Live-verified: no — <reason>` passes it.

The gate needs only the trailer's presence: `hooks/live-verify-gate.sh:131` `grep -Eq "(^|[[:space:]\"'])Live-verified:" <<< "$1"`, and its own help offers `Live-verified: no — <reason>` (`hooks/live-verify-gate.sh:152`). So the gate is satisfiable; what host tools cannot give is a hash. Q-083 states the cost as dilution and launch blocking: "every commit to them carries `Live-verified: no`, which dilutes row 45's debt list. `check_manifest` runs only when cc-isolated launches, so a changed `cc-push.sh` blocks every launch until re-blessed" (`docs/working/questions-archive.md:1581`). Precise version: "commits to them can only ever say `Live-verified: no`, diluting row 45's debt list, and a changed host tool blocks cc-isolated launches until re-blessed."

**Evidence:** `hooks/live-verify-gate.sh:16-20`, `hooks/live-verify-gate.sh:131`, `hooks/live-verify-gate.sh:150-152`, `docs/working/questions-archive.md:1572-1586`

---

## Claim 7a: "Measure router uptake ... count multi-file merges that carry RPI research/plan docs ... (an artifact count, not the usage log, which under-counts, Q-017)" — RPI research/plan half

**Location:** `docs/roadmap.md:30-33`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether committed merges can carry RPI research/plan docs in this repo; does not establish whether RPI is in fact followed, and does not cover row 66's own revisit trigger text (outside this diff, same defect).

This repo gitignores exactly those files: `.gitignore:26` `docs/working/plan-*.md` and `.gitignore:27` `docs/working/research-*.md` (confirmed by `git check-ignore -v`). Only 4 such files are tracked in the whole history (force-added): `plan-copy-install-bare-host.md`, `plan-q093-cc-push-self-commondir.md`, `plan-q094-exit-scan-worktree-layout.md`, `research-copy-install-bare-host.md`. So a merge normally carries no RPI doc even when RPI ran, and the proposed artifact count under-counts too — the thing the parenthetical says it avoids. Acting on it, the first three cycles would read near-zero and fire row 66's trigger ("selection, not discovery, is the bottleneck") on a measurement artifact. Fix: count review artifacts only, or count force-added/linked plan docs knowing they are rare, or un-ignore plan/research docs first.

**Evidence:** `docs/roadmap.md:30-33`, `.gitignore:22-36`, docs/reviews/execution-logs/r2-skill-final-counts.txt (command `git ls-files 'docs/working/plan-*' 'docs/working/research-*'` and `git check-ignore -v`, cwd worktree, exit 0, 2026-09-29T03:04:52-07:00)

---

## Claim 7b: same roadmap item — pr-prep review artifacts half

**Location:** `docs/roadmap.md:30-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that pr-prep review artifacts under `docs/reviews/` are tracked and so travel with merges; does not establish that their presence implies the pr-prep router was selected.

`.gitignore` ignores `docs/working/reviews/round-*/` (the SI loop's rubric archive, `.gitignore:18-20`) but nothing under `docs/reviews/`; this branch's own commits add tracked `docs/reviews/*` files (d8b0cca stat lists 40+ of them).

**Evidence:** `.gitignore:15-36`, `git log -1 --stat d8b0cca`

---

## Claim 8: "A8 post-restructure token measurement. Motive: the user deferred big compute until code and prompts settle; it validates code-review lever #3."

**Location:** `docs/roadmap.md:34-36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the project memory record; does not establish whether settlement has occurred.

Memory `run-a8-measurement-after-settling.md`: "the post-restructure measurement of code-review lever #3 (re-run ≥1 canon cell ...) **should be run — but only after the code/prompt changes in /workspace are fully settled**".

**Evidence:** `/home/node/.claude/projects/-workspace/memory/run-a8-measurement-after-settling.md:10`

---

## Claim 9: "Q-074, 1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26 if fewer than 5 new entries have landed by then."

**Location:** `docs/roadmap.md:44-46`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Q-074's text; does not recount fix commits.

`docs/working/questions.md:107`: "has gained 1 entry across about 128 `fix` commits ... If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment".

**Evidence:** `docs/working/questions.md:104-109`

---

## Claim 10: "Narrow code-review's 'default whenever a PR is prepared' description ... (override log, deferred from log row 66's review)" and "Finish skill-format-audit F1: drop `when:` repo-wide and from `divergent-design-router.bats` ... (override log, deferred from log row 66's review)"

**Location:** `docs/roadmap.md:47-50`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both deferrals exist in the override log under the row-66 branch; does not establish that they remain unfixed on main.

`docs/reviews/override-log.md:161`: "`skills/code-review/SKILL.md` description still says \"default whenever a PR is prepared or evaluated\", overlapping pr-prep ... Deferred". `docs/reviews/override-log.md:164`: "`test/skills/divergent-design-router.bats` still requires `when:`/`trigger` ... finishing skill-format-audit F1 repo-wide is a separate change. Candidate for the first dev cycle."

**Evidence:** `docs/reviews/override-log.md:161`, `docs/reviews/override-log.md:164`

---

## Claim 11: "merging the row-66 branch hit conflicts on `code-fact-check-report-r*.md` ... and add/add conflicts on `*-review-<date>.md`"

**Location:** `docs/roadmap.md:51-54`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge 33fdfd3 (main into feat/workflow-router-skills) replayed with merge-tree; does not establish that every pair of branches collides.

Command `timeout 60 git merge-tree --write-tree --name-only 028105b c9a370a` (cwd worktree, exit 1 = conflicts, 2026-09-29): output includes "CONFLICT (content): Merge conflict in docs/reviews/code-fact-check-report-r1.md" (also r2, r3) and "CONFLICT (add/add): Merge conflict in docs/reviews/performance-review-2026-09-29.md" and security-review-2026-09-29.md.

**Evidence:** docs/reviews/execution-logs/r2-skill-final-merge-tree-33fdfd3.txt

---

## Claim 12: Done items — "log row 65, merge c9a370a ... Removes ~89K tokens" and "log row 66, merge 4225753"

**Location:** `docs/roadmap.md:59-61`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge hashes' subjects and row 65's stated token figure; does not re-measure the ~89K.

`git log main`: "c9a370a merge: AGENTS.md names workflows by filename, not @-import (decision log 65)" and "4225753 merge: a router skill for every workflow (decision log 66)". Row 65 (`docs/decisions/log.md:88`): "put ~358 KB (~89K tokens at chars/4) of workflow text into every session and subagent".

**Evidence:** `docs/decisions/log.md:88-89`, `git log --oneline main -5`

---

## Claim 13: "`feat/dev-cycle-digest` ... hit the review loop's 3-iteration cap: its last full pass found behavioural Incorrects, fixed in baa46e3 but not re-reviewed by a full pass."

**Location:** `docs/working/questions.md:53`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the digest rubric and topology; does not establish that the fixes are complete.

Rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:5`: "review cap reached (3 iterations); gate decision: escalate ... Final pass 2 found Incorrects, fixed in baa46e3 ... but not by a fourth full pass." Line 53: "F2 | `git status` rewrote .git/index ... fact-check r2 (Incorrect)" — behavioural. Topology: 65bd433 (artifacts) follows baa46e3 with no later review pass.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:5`, `:48-61`

---

## Claim 14: "Rely on the fix's tests (each fails on the previous script)"

**Location:** `docs/working/questions.md:61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two tests baa46e3 changed, run against de53069's script; does not establish test coverage of other window-start edges.

baa46e3 changed exactly two tests (`git diff de53069 baa46e3 -- test/scripts/dev-cycle.bats`). Command `timeout 300 bats test/scripts/dev-cycle.bats` with baa46e3's test file over `git archive de53069` (cwd scratchpad/r2sf/old, exit 1, 2026-09-29): "not ok 2 lists a decision record's revisit triggers and a log row's whole revisit clause", "not ok 3 after a cycle record, unchanged triggers carry forward and changed ones print"; the other 11 pass. At HEAD all 13 pass (exit 0).

**Evidence:** docs/reviews/execution-logs/r2-skill-final-baa46e3-tests-on-de53069.txt, docs/reviews/execution-logs/r2-skill-final-bats-head.txt

---

## Claim 15: "`dev-cycle` ... Workflow-shaped (eight ordered steps, 0–7) but, by the criteria above, a skill: Claude completes it in one pass given the digest, with no human checkpoint mid-run (decisions go to questions.md), and it produces a self-contained artifact (the cycle record)."

**Location:** `guides/skill-creation.md:137`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step count and that the named criteria exist in the guide's table and match the skill; does not judge whether skill is the better form factor.

The criteria table (`guides/skill-creation.md:98-102`) has "Does it require human judgment at intermediate checkpoints? | Workflow | Skill", "Can Claude complete it in a single pass given the right context? | Skill | Workflow", "Does it produce a self-contained artifact ...? | Skill | Either". The skill defers user choices to entries: `SKILL.md:48-49` "put the list in one `you: terminal` entry rather than deleting"; `SKILL.md:116` "propose it as one `you: judgment` entry instead". Steps 0-7 at `SKILL.md:31-118`.

**Evidence:** `guides/skill-creation.md:96-102`, `guides/skill-creation.md:137`, `skills/dev-cycle/SKILL.md:31-126`

---

## Claim 16: description "Run one maintenance cycle ... Not for landing one change (pr-prep). Triggers: ..." (≤250 chars with precedence clause; commit 89a3d3b "no when:")

**Location:** `skills/dev-cycle/SKILL.md:4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers length (245 chars joined), presence of a "Not for X (Y)" clause and absence of `when:`; does not establish that row 12's extra keywords ("check the revisit triggers", "repo health pass") reach the skill layer — they are not in the description.

Command in r2-skill-final-counts.txt: description length `245`. Frontmatter is lines 1-5 with only `name:` and `description:`. `test/skills/workflow-routers.bats` passes (dev-cycle is not a router; exit 0).

**Evidence:** `skills/dev-cycle/SKILL.md:1-5`, docs/reviews/execution-logs/r2-skill-final-counts.txt, docs/reviews/execution-logs/r2-skill-final-workflow-routers.txt

---

## Claim 17: "Run `~/.claude/scripts/dev-cycle.sh` from the repo root (inside claude-workflows, its own `scripts/dev-cycle.sh`) ... It is read-only and gives the window and where its start came from, merges in it, the revisit triggers that need a verdict, the watched questions, the spot-check sample and the roadmap's Next section."

**Location:** `skills/dev-cycle/SKILL.md:33-37`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that install stages the whole `scripts/` dir (so the path resolves after install) and that the digest prints those sections; does not establish the path exists in this container now (the installed copy predates the branch) or that the digest is correct in every edge.

`devcontainer-config/install.sh:135`: `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`; `link-claude-home.sh:54` `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)`. Sections are `## 1. Activity` … `## 5. Roadmap` plus the `Window:` line naming its source (`scripts/dev-cycle.sh:82-187`); probe A output: "Window: since 2026-09-15 (from no cycle record found, ...)". Read-only per header `scripts/dev-cycle.sh:16` "writes nothing to the repo (one temp file, removed on exit)".

**Evidence:** `devcontainer-config/install.sh:126-135`, `devcontainer-config/link-claude-home.sh:44-54`, `scripts/dev-cycle.sh:15-18`, docs/reviews/execution-logs/r2-skill-final-digest-probe.txt

---

## Claim 18: "If the digest says no cycle record was found but earlier cycles ran, the last one skipped step 7: note it and pass `--since` explicitly."

**Location:** `skills/dev-cycle/SKILL.md:38-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the digest's wording in the no-record case; does not establish detection of the more common skip — a cycle that skipped step 7 after earlier records exist — which the digest does not flag at all (see claim 25).

`scripts/dev-cycle.sh:76`: "no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)". Probe A printed exactly that. When an older record exists (probe B), the digest instead says "from the last cycle record, docs/working/cycles/cycle-2026-09-10.md" with no hint that a later cycle ran without a record.

**Evidence:** `scripts/dev-cycle.sh:70-77`, docs/reviews/execution-logs/r2-skill-final-digest-probe.txt

---

## Claim 19: "run the project's full check to a file (in claude-workflows: `scripts/health-check.sh`) and wait for it to finish before step 4 ... triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)"

**Location:** `skills/dev-cycle/SKILL.md:43-46`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script's existence and pr-prep 5a's three classes; does not run health-check.sh (forbidden by the brief).

`scripts/health-check.sh` is tracked. `workflows/pr-prep.md` 5a table: "Caused by this branch", "Pre-existing on main", "Flaky / infra / environmental" (paraphrased — no quote available because the classes are table cells across three rows).

**Evidence:** `scripts/health-check.sh`, `workflows/pr-prep.md` step 5a

---

## Claim 20: "`questions.sh archive` then `questions.sh index` ... Do not run `archive-working-docs.sh`: it serves the self-improvement loop and moves files into a gitignored archive."

**Location:** `skills/dev-cycle/SKILL.md:47-52`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the subcommands' existence and the archive script's purpose and destination; does not establish that `index` after `archive` does anything (archive already reindexes, so it is redundant but harmless).

`scripts/questions.sh:447-452` dispatches `init check index archive next-id open`; line 30: "archive    move ANSWERED entries to the archive, reindex". `scripts/archive-working-docs.sh:2`: "Archive docs/working/ artifacts from a completed self-improvement run"; line 6: "into docs/working/archive/"; `.gitignore:16` `docs/working/archive/`.

**Evidence:** `scripts/questions.sh:27-33`, `scripts/questions.sh:447-452`, `scripts/archive-working-docs.sh:1-8`, `.gitignore:16`

---

## Claim 21: "For every trigger the digest prints in full, decide ... Triggers the digest lists as carried forward keep the previous record's verdict, unless that verdict was 'cannot tell' or 'fired': re-decide those."

**Location:** `skills/dev-cycle/SKILL.md:57-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the match between the skill's vocabulary and the digest's section text and carried-forward line; does not establish that carried log rows reflect later edits to a row's text (a log row carries by date only, `scripts/dev-cycle.sh:130`).

Probe B output: "Printed in full: triggers in decision records changed since 2026-09-10, and log rows dated on or after it. Listed by name only: the rest, whose verdict carries forward from docs/working/cycles/cycle-2026-09-10.md unless that record says \"cannot tell\" or \"fired\"." and "Carried forward (2): 001-a.md log row 1".

**Evidence:** `scripts/dev-cycle.sh:96-141`, docs/reviews/execution-logs/r2-skill-final-digest-probe.txt

---

## Claim 22: "If the digest says `questions.sh open` failed, fix that first; the section was not checked."

**Location:** `skills/dev-cycle/SKILL.md:70-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's failure line; does not establish that step 0's "init if no questions.md" covers every cause — a questions.md without questions-archive.md also fails `open` (probe D), which step 3's "fix that first" then handles.

Probe D output: "**questions.sh open failed** — watched questions were NOT checked. Its error:" followed by "✗ missing: .../docs/working/questions-archive.md".

**Evidence:** `scripts/dev-cycle.sh:147-164`, docs/reviews/execution-logs/r2-skill-final-digest-probe.txt

---

## Claim 23: "dispatch one `code-fact-check` agent ... an item from the self-improvement loop's `docs/working/feature-ideas*.md` ... note it for `divergent-design`"

**Location:** `skills/dev-cycle/SKILL.md:77-89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named skills and file pattern exist; does not establish that feature-ideas files are present where the cycle runs — `feature-ideas-round-*.md` is gitignored (`.gitignore:28`), so a fresh clone or worktree has none.

`skills/code-fact-check/` and `skills/divergent-design/` exist. `scripts/self-improvement.sh:38`: "docs/working/feature-ideas-round-N.md   DD output per round"; `scripts/archive-working-docs.sh:9` keeps `feature-ideas.md` as permanent.

**Evidence:** `skills/code-fact-check/SKILL.md`, `skills/divergent-design/SKILL.md`, `scripts/self-improvement.sh:38`, `.gitignore:28`

---

## Claim 24: "the digest's `Main at: <sha>` line copied verbatim ... The next digest starts its window from this file's date and compares triggers against the recorded commit"

**Location:** `skills/dev-cycle/SKILL.md:121-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's use of the newest record's date and a line-start `Main at:` hash that is an ancestor of the default branch; does not establish that a record with the line indented or bulleted (e.g. `- Main at: …`) is read — it is not, and the digest silently falls back to a date-based start with no message.

`scripts/dev-cycle.sh:108`: `base="$(sed -n 's/^Main at: \([0-9a-f]\{7,40\}\).*/\1/p' "docs/working/cycles/cycle-$last_record.md" ...`; line 109 falls back to `git rev-list -1 --first-parent --before="$SINCE_TS"` if the base is missing or not an ancestor. Probe C (bulleted line) printed the same digest header as probe B with no warning. The skill does say "verbatim", which a copied line satisfies.

**Evidence:** `scripts/dev-cycle.sh:64-73`, `scripts/dev-cycle.sh:107-109`, docs/reviews/execution-logs/r2-skill-final-digest-probe.txt

---

## Claim 25: "so a cycle without the record silently falls back to 14 days"

**Location:** `skills/dev-cycle/SKILL.md:124`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's window source when the latest cycle wrote no record; does not establish harm beyond a wider window and verdicts carried from an older record.

Both parts are wrong. (1) Not 14 days: the digest takes the newest record on disk (`scripts/dev-cycle.sh:65-68`, `[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"`), so once any cycle has written a record, a skipped record makes the next window start at the *older* record (probe B: "Window: since 2026-09-10 (from the last cycle record, docs/working/cycles/cycle-2026-09-10.md)"). 14 days applies only when no record exists at all. (2) Not silent: in that no-record case the digest says "no cycle record found, so the default of 14 days" (`scripts/dev-cycle.sh:76`, probe A). Never true: the script at 1f8ed13 already used the newest record (`SINCE="${last:-$(date -d '14 days ago' +%F)}"`); the sentence dates from d8b0cca. Precise version: "a cycle without the record makes the next window start at the previous record (or 14 days if there is none), and the digest does not say a cycle was missed." This misstatement matches the architecture review's finding 1 wording ("silently narrows to 14 days", `docs/reviews/architecture-review-2026-09-29-devcycle.md:138`), which the skill appears to have inherited.

**Evidence:** `skills/dev-cycle/SKILL.md:120-124`, `scripts/dev-cycle.sh:64-77`, docs/reviews/execution-logs/r2-skill-final-digest-probe.txt

---

## Claim 26: README "`skills/` holds 34 Claude Code skills ... the `dev-cycle` skill (the outer maintenance loop; `docs/roadmap.md`)"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the directory count at HEAD; does not check the category grouping of every skill.

`ls -d skills/*/ | wc -l` → `34` (r2-skill-final-counts.txt). Pre-branch README said 33.

**Evidence:** `README.md:182`, docs/reviews/execution-logs/r2-skill-final-counts.txt

---

## Claim 27: Commit 1f8ed13 "test/dev-cycle.bats: six hermetic tests" and "11 decision records and 7 log rows carry revisit triggers"; commit d8b0cca "size gate: the unit is now 531 code lines against main (cap 400). Split ... into feat/dev-cycle-digest (script + tests) and feat/dev-cycle stacked on it"

**Location:** `git log -1 1f8ed13`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at those commits and the resulting topology; does not verify d8b0cca's list of script fixes, which belong to the lower unit (the bullets I spot-checked — hash-resolved branch, option-like names rejected, hashed seed, test moved to test/scripts/ — match `scripts/dev-cycle.sh:43-54`, `:171-174`).

`git show 1f8ed13:test/dev-cycle.bats | grep -c '^@test'` → 6; counts at 1f8ed13^ → records=11 logrows=7; pr-prep 1a count over `4225753...d8b0cca` → 531. `git log --graph` shows feat/dev-cycle-digest merged into feat/dev-cycle at c8ef1b0. This unit now counts 130 code lines against the digest branch.

**Evidence:** docs/reviews/execution-logs/r2-skill-final-counts.txt, `git log --graph HEAD feat/dev-cycle-digest`

---

## Claim 28: Commit 89a3d3b "dev-cycle description <=250 chars with a precedence clause; no when: ... README: 34 skills, dev-cycle named; skill-creation inventory row"; commit e438cd1 "record the Main at: line; Q-100 escalates the digest review cap"

**Location:** `git log -1 89a3d3b`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each named change is present at HEAD and e438cd1's diff does what its subject says; does not rank the commits' completeness.

See claims 16 and 26; `git diff 3268a5e e438cd1 -- skills/dev-cycle/SKILL.md` adds "the digest's `Main at: <sha>` line copied verbatim"; e438cd1's stat adds 19 lines to questions.md (Q-100 and its index row).

**Evidence:** `git show --stat e438cd1`, `skills/dev-cycle/SKILL.md:120-124`

---

## Claim 29: "~1.3M tokens" (cost of a fourth full pass)

**Location:** `docs/working/questions.md:60`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about the figure; does not establish its source.

No token accounting for earlier passes is in the scoped files or the digest rubric (paraphrased — no quote available because the claim covers absence of a source; `grep -rn '1.3M' docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle*.md` finds nothing). Verifying it needs the session's token logs for final pass 1/2.

**Evidence:** `docs/working/questions.md:60`

---

Also checked and holding (no per-claim entry, all static or covered above): decision-tree row 12 (`global-instructions/CLAUDE.md:32`) names the `dev-cycle` skill and "rows 6/9" are RPI and pr-prep; Q-099's cited "architecture-review ... finding 3" exists and is the ownership question (`docs/reviews/architecture-review-2026-09-29-devcycle.md:138-144`); "Running questions document" heading exists (`global-instructions/CLAUDE.md:234`); `questions.sh check` passes ("✓ questions: structure valid, indexes current", r2-skill-final-questions-check.txt); `test/cross-reference-integrity.bats` and `test/guide-index-sync.bats` pass.

## Claims Requiring Attention

### Incorrect
- **Claim 7a** (`docs/roadmap.md:30-33`): RPI research/plan docs are gitignored (`.gitignore:26-27`; 4 ever tracked), so "count merges that carry RPI research/plan docs" under-counts like the usage log it replaces and would fire row 66's trigger falsely. Count review artifacts only, or un-ignore those docs first.
- **Claim 25** (`skills/dev-cycle/SKILL.md:124`): a missing record makes the next window start at the previous record (14 days only if none exists), and the no-record fallback is announced, not silent. The real silent gap is a skipped cycle after an earlier record: nothing flags it.

### Mostly Accurate
- **Claim 6** (`docs/roadmap.md:27-29`): the gate accepts `Live-verified: no — <reason>`; the cost is debt-list dilution and launch blocking, not an unsatisfiable gate.

### Unverifiable
- **Claim 29** (`docs/working/questions.md:60`): "~1.3M tokens" has no cited source; needs token logs from the earlier final passes.

Scope residues worth a reader's attention (Verified claims, narrow): a bulleted `- Main at:` line is ignored without warning (claim 24); feature-ideas files are gitignored and absent in fresh worktrees (claim 23); row 12's keywords "check the revisit triggers" and "repo health pass" are not in the skill description (claim 16).

## Goal-Alignment Note
- **Answered:** Every item in "Particularly check": the skill's digest vocabulary against scripts/dev-cycle.sh at HEAD (section names, "carried forward", "printed in full", "questions.sh open failed", "no cycle record found", "Main at:") by executed probes; every named command, path and cross-reference; roadmap facts incl. Q-IDs, c9a370a, 4225753 and log rows; row 67, Q-099, Q-100, row 12, README and guide lines; commit messages. All nine pass-1 fixes hold.
- **Out of scope:** The lower unit (script, tests) was used as context only; I ran its tests and one test-on-old-script check solely to verify Q-100's claim. No health-check or full suite.
- **Escalate:** Claim 7a also affects log row 66's revisit trigger on main (same measurement, outside this diff). Claim 25 exposes an undetected case (a cycle that skips its record after an earlier record exists) that the digest cannot currently signal; fixing it may need a lower-unit script change, which Q-100's held state makes a judgment call. Probe cleanup: all probes ran under `timeout` in the scratchpad; no stray processes remain. New files: this report and ten `docs/reviews/execution-logs/r2-skill-final-*.txt` logs (untracked); no tracked file edited.
