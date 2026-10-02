Commit: bc5dc76

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-devcycle`, branch `feat/dev-cycle` at bc5dc76 (contains the digest code 09f6fe7 and the skill 074164b)
**Scope:** Full branch: `git diff main...HEAD -- . ':!docs/reviews'` (13 files: `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`, `skills/dev-cycle/SKILL.md`, `docs/dev-cycle.md`, `docs/working/seed-build-loop-handoff.md`, `docs/roadmap.md`, `docs/decisions/log.md` rows 66–68, `docs/working/questions.md` (Q-103), `docs/working/questions-archive.md` (Q-099–Q-101), `global-instructions/CLAUDE.md` row 12, `guides/skill-creation.md` dev-cycle row, `workflows/codebase-onboarding.md` step 13, `README.md`)
**Checked:** 2026-10-02
**Replication:** k=1 (full review, user's choice)
**Total claims checked:** 80
**Summary:** 74 verified, 5 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fcF/` (cited below as `fcF/`). Every throwaway repo was built under its own `mktemp -d` directory inside `fcF/`; every process ran under `timeout`; nothing was written to the worktree except this report, and no branch was switched. All runs used `LC_ALL=C` (the host's en_US.UTF-8 locale is missing; the only effect is a `setlocale` warning line in some logs).

**Working-tree note.** When this report was saved, the worktree had uncommitted edits that this run did not make, to `skills/dev-cycle/SKILL.md`, `docs/dev-cycle.md` and `docs/working/seed-build-loop-handoff.md`. They move `questions.sh init` into step 1, add a path rule, and mention a `docs/working/briefs/` directory. Every verdict and line number here is against the committed bc5dc76 text, saved as `fcF/SKILL-bc5dc76.md`, `fcF/dev-cycle-settings-bc5dc76.md` and `fcF/seed-bc5dc76.md`. It was read before those edits appeared, and the cited lines were re-checked against `git show bc5dc76:…`. All other in-scope files, including `scripts/` and `test/`, have no diff from bc5dc76 (`git diff --quiet bc5dc76 -- …` succeeded), so the executed runs exercised the committed digest. Claims 58 and 60 concern text those edits rewrite. Re-check them on the next commit.

- `fcF/bats.txt`: `timeout 600 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-devcycle`, exit 0, 2026-10-02T07:06:06Z, 23/23 ok (`bats --count` = 23).
- `fcF/digest-self.md` (+ `digest-self.err`, empty): `timeout 120 bash scripts/dev-cycle.sh`, same cwd, exit 0, 2026-10-02T07:06:19Z. The digest of this repo (default branch `main` at bf54363).
- `fcF/probes0.log`: P0, `--help` and every bad-usage path, same cwd, 2026-10-02T07:12Z; exit codes recorded per line.
- `fcF/probes1.log`: P1 `questions.sh init` with a directory archive (init only); P2 `%cs` time zone; P3 `git log --since` vs a full walk; P4 the host awk. 2026-10-02T07:07:09Z; per-step exit codes inline.
- `fcF/probes1b.log`: P1b, P1 repeated with the digest run afterwards (sections 3 and 8 captured), 2026-10-02T07:19:40Z; init exit 0, digest exit 0.
- `fcF/probes-p5.log`: P5, the scrub's perl loop with the 3-byte resume vs a restart from 0, on the bats test's 1200-line input. 2026-10-02T07:08:01Z.
- `fcF/probes2.log`: P6 a recursive listing of a throwaway repo before and after a digest run with `TMPDIR` pointed at an empty dir; P7 a non-SKILL.md file under `skills/` added and removed in the window. 2026-10-02T07:11:01Z.
- `fcF/probes3.log`: P8 a skill path holding a newline, plus a merge-only workflow file. 2026-10-02T07:11:19Z.
- `fcF/probes4.log`: P9 a repo with no branch at all (detached HEAD); P10 no perl on PATH. 2026-10-02T07:11:45Z.
- `fcF/probes5.log`: P11 counts (skills, bats tests, revisit triggers at ec297d4 and ff43c49), the seed's code blocks compared with `git show 8b3a8ad:skills/dev-cycle/SKILL.md` (saved as `fcF/skill-8b3a8ad.md`), `git check-ignore` on the paths the skill writes. 2026-10-02T07:12:28Z.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) present and consulted. Its five entries are all "a specific measured value quoted from an artifact set that does not contain it" or a file-to-symbol association never grepped. Every measured value in scope was recomputed for that reason: the test count (23), the skill count (34), row 67's 11 records and 7 log rows, Q-101's 21 triggers, and the bats comment's ~35 s / ~1 s timing. All of them hold. No claim matches a logged pattern. There are no Incorrect verdicts, so nothing is appended.

Legibility-target values follow `patterns/orchestrated-review.md` "Legibility-target tagging" and the default mapping in `skills/code-review/SKILL.md` Stage 1: Verified → `for-orchestrator-synthesis`; Stale / Mostly accurate → `for-author`.

---

## Claim 1: "`skills/` holds 34 Claude Code skills … the `dev-cycle` skill (the outer maintenance loop; `docs/roadmap.md`)"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the skill count and that `dev-cycle` is one of them; does not establish the README's category list for the other 33.

`ls skills/*/SKILL.md | wc -l` printed `skills/*/SKILL.md: 34` (`fcF/probes5.log`), and `skills/dev-cycle/SKILL.md` exists, with frontmatter `name: dev-cycle` (`skills/dev-cycle/SKILL.md:2`).

**Evidence:** `README.md:182`, `skills/dev-cycle/SKILL.md:2`, `fcF/probes5.log`

---

## Claim 2: Row 66's corrected trigger: "multi-file merges to main still land without pr-prep's `← carried from RPI` line or a committed code-review rubric (tracked signals; research/plan docs are gitignored and the usage log under-counts)"

**Location:** `docs/decisions/log.md:89`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the carried-from line ends up in the merge message on this repo's local-merge path and that RPI research/plan docs match .gitignore patterns; does not establish that any past merge carries the line (none on `main` does yet).

pr-prep defines the line: `← carried from RPI: <state forwarded>` (`workflows/pr-prep.md:190`), placed in the PR description, and on the local-merge path `**Read "PR description" as "merge commit message"**` (`workflows/pr-prep.md:24`). So it is tracked in git on this repo's path. RPI writes `docs/working/research-{topic}.md` and `docs/working/plan-{topic}.md` (`workflows/research-plan-implement.md:30-31`). Both match the ignore rules `docs/working/plan-*.md` and `docs/working/research-*.md` (`.gitignore:26-27`).

**Evidence:** `docs/decisions/log.md:89`, `workflows/pr-prep.md:24`, `workflows/pr-prep.md:190`, `workflows/research-plan-implement.md:30-31`, `.gitignore:26-27`

---

## Claim 3: Row 67: "As of 2026-09-28, 11 decision records carried revisit triggers and 7 log rows mentioned a revisit condition, and no recurring step read them (codebase-onboarding step 10 reads them at onboarding and its lightweight refresh)" and "the override log's at least nine unwritten runs"

**Location:** `docs/decisions/log.md:90`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two counts at ec297d4 (the last `main` merge dated 2026-09-28) and the two onboarding readers; does not re-measure the nine-run override-log figure, which is checked only against the existing source that states it.

At ec297d4, `log rows with revisit=7 records with '## Revisit triggers'=11` (`fcF/probes5.log`). Step 10's recipe: `` `grep '## Revisit triggers' docs/decisions/*.md` `` (`workflows/codebase-onboarding.md:309`). The lightweight refresh's step 4: `**Rebuild Watch Signals.** Re-run step 10's grep + relevance filter` (`workflows/codebase-onboarding.md:516`). The nine-run figure matches the source the row cites: `the code-review override log went unwritten for nine runs` (`scripts/questions.sh:7-8`).

**Evidence:** `docs/decisions/log.md:90`, `workflows/codebase-onboarding.md:303-316`, `workflows/codebase-onboarding.md:516`, `scripts/questions.sh:5-11`, `fcF/probes5.log`

---

## Claim 4: Row 67: "The global decision tree gains row 12" and "(Q-099 [1], 2026-09-30)"

**Location:** `docs/decisions/log.md:90`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of row 12 and Q-099's recorded answer; does not establish the rest of row 67's historical step list, which the row itself marks "Revised by #68".

`| 12 | **Maintenance or planning pass over the repo**` (`global-instructions/CLAUDE.md:32`). `**Answer (2026-09-30, answers-9-30-26.txt): [1].** The roadmap is the one backlog.` (`docs/working/questions-archive.md:1800`).

**Evidence:** `global-instructions/CLAUDE.md:32`, `docs/working/questions-archive.md:1797-1800`

---

## Claim 5: Row 68's summary of the revised skill: carry-forward and `Main at:` cut; step 4b "when a skill, the model or a major design decision record changes"; step 5's conditions; build briefs (at most 3 open) that land with the cycle branch; the handoff split out; the policy "set during onboarding and read by that unit"; "undocumented is broken" checked through the code-without-docs section

**Location:** `docs/decisions/log.md:91`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed property against the skill and digest text; does not establish the row's process history ("The double-diamond pass's 8 gaps were applied"). It also does not cover the omission that step 4b's first trigger includes workflow files as well as skills, which is a summary simplification, not a contradiction.

Step 4b's triggers: `- a skill or workflow file added or substantially changed in the window;` / `- a decision record added or changed that is a major design decision;` / `- the model running this cycle differs from the last record's `Model:` line.` (`skills/dev-cycle/SKILL.md:180-182`). Step 5: `- roadmap Now holds 0–1 items ready for a build brief;` … `- 10+ ideas seeded since the last brainstorm;` … `- a week or more since the last brainstorm, by date, or none recorded yet` (`:194-198`). Briefs: `while fewer than 3 briefs are open, counting earlier cycles'` and `The briefs land with step 7` (`:253`, `:258-259`). The policy: `recorded for the build-loop handoff, which this skill does not run yet. This skill does not read it.` (`:57-58`). The digest's section 6 comment: `step 4 checks each one (rule: undocumented is broken)` (`scripts/dev-cycle.sh:304-305`). The digest has no carry-forward and does not read record bodies (paraphrased — no quote available because the claim covers absence of code: `rg 'Carried|Main at' scripts/dev-cycle.sh` matches only the comment "nothing carries forward" at `:17`, and the bats test at `test/scripts/dev-cycle.bats:65-78` asserts that `Main at:` never prints).

**Evidence:** `docs/decisions/log.md:91`, `skills/dev-cycle/SKILL.md:56-58`, `skills/dev-cycle/SKILL.md:173-206`, `skills/dev-cycle/SKILL.md:252-259`, `scripts/dev-cycle.sh:302-305`, `test/scripts/dev-cycle.bats:65-78`

---

## Claim 6: "Codebase onboarding asks the user for the build-loop policy (its step 13)" and "Read by the build-loop handoff (roadmap item "Build-loop handoff"; not built yet), not by the dev-cycle skill itself."

**Location:** `docs/dev-cycle.md:3-5`, `docs/dev-cycle.md:9-10`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the onboarding step number, the roadmap item, and the skill not reading the line; does not establish any reader in the not-yet-built handoff.

`### 13. Gate — validate with the team` (`workflows/codebase-onboarding.md:447`), under which `Also settle the project's **build-loop policy** with the user` (`:453`). The roadmap's Now has `- **Build-loop handoff** (follows this dev cycle)` (`docs/roadmap.md:17`). The skill says `This skill does not read it.` (`skills/dev-cycle/SKILL.md:57-58`), and "Build-loop policy" appears in the skill only in the settings template and that bullet (paraphrased — no quote available because the claim covers absence: `rg -n 'Build-loop policy' skills/dev-cycle/SKILL.md` matches only `:48` and `:56`).

**Evidence:** `docs/dev-cycle.md:3-10`, `workflows/codebase-onboarding.md:447-457`, `docs/roadmap.md:17-21`, `skills/dev-cycle/SKILL.md:48`, `skills/dev-cycle/SKILL.md:56-58`

---

## Claim 7: The self-merge path list is the one the seed gives, and "The handoff design counts the setting as made only when the file has exactly one line, outside code blocks, reading exactly … (a trailing CR is ignored). Anything else counts as unset, which means `review`."

**Location:** `docs/dev-cycle.md:10-19`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the seed's design items 2 and 3; does not establish an implementation, since none exists yet (the doc says so).

Seed item 2: `Policy: set only when `docs/dev-cycle.md` has exactly one line, outside code blocks, reading exactly `Build-loop policy: self-merge` or `Build-loop policy: review` (a trailing CR is ignored); anything else is `review`.` (`docs/working/seed-build-loop-handoff.md:29-31`). Item 3 lists `hooks, enforcement and harness settings, instruction files, `skills/`, `workflows/`, `scripts/`, `guides/`, `patterns/`, `templates/`, `test/`, `devcontainer-config/`` (`:33-35`). The doc points to that list (`the handoff seed, `docs/working/seed-build-loop-handoff.md`, lists them`, `docs/dev-cycle.md:12-13`).

**Evidence:** `docs/dev-cycle.md:10-19`, `docs/working/seed-build-loop-handoff.md:26-36`

---

## Claim 8: "Interim note: the "(interim; Q-103)" on the policy line keeps it unset until Q-103 is answered."

**Location:** `docs/dev-cycle.md:21-22`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exact-line rule applied to the current line; does not establish behavior of any future parser.

The line is `Build-loop policy: review (interim; Q-103)` (`docs/dev-cycle.md:7`), which is not exactly either allowed line under the rule at `:17-19`, so it counts as unset (= `review`).

**Evidence:** `docs/dev-cycle.md:7`, `docs/dev-cycle.md:17-22`

---

## Claim 9: Idea source row "Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files"

**Location:** `docs/dev-cycle.md:31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the glob matches what the self-improvement loop writes; does not establish that such files exist in any given working tree (they are gitignored, `.gitignore:28`, so only a local checkout where the loop ran has them).

`#   docs/working/feature-ideas-round-N.md   DD output per round` (`scripts/self-improvement.sh:38`); `IDEAS_FILE="$WORKING_DIR/feature-ideas-round-$ROUND.md"` (`:728`).

**Evidence:** `docs/dev-cycle.md:29-31`, `scripts/self-improvement.sh:38`, `scripts/self-improvement.sh:728`, `.gitignore:28`

---

## Claim 10: Roadmap Next 1–3: Q-075, Q-088, Q-089 with their motives ("Q-098 (a global allow list) waits on a Bash sandbox"; "a changed host tool blocks cc-isolated launches until it is re-blessed (Q-083 [1])")

**Location:** `docs/roadmap.md:27-37`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each cited entry exists, is open where the roadmap treats it as open, and says what the roadmap attributes to it; does not judge the ranking.

Q-075, Q-088 and Q-089 are open `agent` entries in `docs/working/questions.md`, and Q-098 is open `deferred` (paraphrased — no quote available because the status of four entries was read by `rg -A1 '^### Q-0NN '` across both files). Q-088: `Spike, per Q-081 [2]: can Claude Code's `sandbox.enableWeakerNestedSandbox` run Bash sandboxed inside cc-isolated` … `Success: a sandboxed Bash call` (`docs/working/questions.md:179`). Q-083 in the archive: `**Answered 2026-09-28: [1] separate host-tools category.** Filed as Q-089 (agent).` and `a changed `cc-push.sh` blocks every launch until re-blessed` (`docs/working/questions-archive.md:1578`, `:1584`).

**Evidence:** `docs/roadmap.md:27-37`, `docs/working/questions.md:179`, `docs/working/questions.md:188-192`, `docs/working/questions-archive.md:1576-1589`

---

## Claim 11: Roadmap Next 4: "count multi-file merges to main whose message carries pr-prep's `← carried from RPI` line and whose branch committed a code-review rubric. Both are tracked; research/plan docs are gitignored and the usage log under-counts (Q-017)"

**Location:** `docs/roadmap.md:38-42`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the same mechanism as Claim 2 (the line reaches the merge message on the local-merge path; research/plan docs are ignored); does not establish the Q-017 under-count, which is cited, not re-measured.

`**Read "PR description" as "merge commit message"** everywhere in this doc.` (`workflows/pr-prep.md:24`); `docs/working/plan-*.md` / `docs/working/research-*.md` (`.gitignore:26-27`). Q-017 is an answered entry in the archive (paraphrased — no quote available because only its existence and status were checked).

**Evidence:** `docs/roadmap.md:38-42`, `workflows/pr-prep.md:24`, `.gitignore:26-27`

---

## Claim 12: Roadmap Next 5: "rubric row A8 in `docs/reviews/code-review-rubric-2026-08-07-main.md`"

**Location:** `docs/roadmap.md:43-47`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence and subject of row A8; does not establish whether code-review is "settled".

`| A8 | "Leave it on because it is free" / "0% of token count" …` … `User decision 2026-08-07: run the post-restructure measurement once code/prompt changes are fully settled` (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`).

**Evidence:** `docs/roadmap.md:43-47`, `docs/reviews/code-review-rubric-2026-08-07-main.md:35`

---

## Claim 13: Roadmap Ideas: "Signal: Q-074, 1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26 if fewer than 5 new entries have landed by then."

**Location:** `docs/roadmap.md:54-56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers faithful citation of Q-074; does not re-measure the 1-in-~128 figure Q-074 states.

`` `docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. … If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment `` (`docs/working/questions.md:84`).

**Evidence:** `docs/roadmap.md:54-56`, `docs/working/questions.md:84`

---

## Claim 14: Roadmap Done: row 65 "merge c9a370a"; row 66 "merge 4225753"

**Location:** `docs/roadmap.md:69-71`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both hashes are those merges; does not establish the "~89K tokens" figure, which is quoted from row 65 and not re-measured.

`git log -1` gives `c9a370aa ec297d4f ae61ad18 merge: AGENTS.md names workflows by filename, not @-import (decision log 65)` and `4225753a c9a370aa 8506e93c merge: a router skill for every workflow (decision log 66)`. Both have two parents, so both are merges.

**Evidence:** `docs/roadmap.md:69-71`, `git log -1 c9a370a`, `git log -1 4225753`

---

## Claim 15: Q-099 answer: "This matches the interim, so the skill needs no change. Decision log row 67 now records it as decided."

**Location:** `docs/working/questions-archive.md:1800`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers row 67's record of the decision and step 5 reading feature-ideas as a source; does not establish the self-improvement loop's own behavior.

Row 67: `the self-improvement loop's `feature-ideas*.md` is read as a signal in step 5, so the roadmap is the one backlog (Q-099 [1], 2026-09-30)` (`docs/decisions/log.md:90`). Step 5 reads `the idea sources `docs/dev-cycle.md` lists` (`skills/dev-cycle/SKILL.md:202-203`), which list `docs/working/feature-ideas*.md` (`docs/dev-cycle.md:31`).

**Evidence:** `docs/working/questions-archive.md:1797-1812`, `docs/decisions/log.md:90`, `skills/dev-cycle/SKILL.md:201-206`, `docs/dev-cycle.md:31`

---

## Claim 16: Q-101 option [1]: "Each cycle judges all 21 triggers instead of ~2 plus a carried list"

**Location:** `docs/working/questions-archive.md:1828`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count on this branch's history as of 2026-09-30, when the entry was written (11 records + 10 log rows); does not cover today's count, which is 22 because row 68 added one (`fcF/digest-self.md` section 2 lists 11 records and 11 log rows).

At ff43c49 (the last commit dated 2026-09-30 on this branch): `log rows with revisit=10 records with '## Revisit triggers'=11` (`fcF/probes5.log`).

**Evidence:** `docs/working/questions-archive.md:1828`, `fcF/probes5.log`, `fcF/digest-self.md`

---

## Claim 17: Q-103: option [2]'s list "(the seed's list: hooks, enforcement and harness settings, instruction files, skills/, workflows/, scripts/, guides/, patterns/, templates/, test/, devcontainer-config/)", "spot-check (2 sampled merges by default)", and "Interim: [1] `review`, recorded as `Build-loop policy: review (interim; Q-103)`. … its design counts that line as unset, which means `review`."

**Location:** `docs/working/questions.md:45-61`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the list, the default sample size, the interim line and its unset reading; does not establish the user-facing claims in "Why it's yours" (what the user said), which are not checkable against code.

The seed's item 3 gives the same eleven entries (`docs/working/seed-build-loop-handoff.md:33-35`). `SAMPLE=2` (`scripts/dev-cycle.sh:72`). The policy line is `Build-loop policy: review (interim; Q-103)` (`docs/dev-cycle.md:7`), unset under the exact-line rule (`docs/dev-cycle.md:17-19`). The paragraph the entry says to delete starts `Interim note:` (`docs/dev-cycle.md:21`).

**Evidence:** `docs/working/questions.md:45-61`, `docs/working/seed-build-loop-handoff.md:29-36`, `scripts/dev-cycle.sh:72`, `docs/dev-cycle.md:7`, `docs/dev-cycle.md:17-22`

---

## Claim 18: "(rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md`, sections "Pass 6" to "Pass 9"; reports `docs/reviews/*digest-pass{6,7,8,9}*.md`)"

**Location:** `docs/working/seed-build-loop-handoff.md:3-6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the rubric sections and report files exist; does not re-judge what each pass found.

`## Pass 6 (review-fix loop, …` … `## Pass 9 (review-fix loop, k=1, all critics; on d503a43 digest / 1ae9b21 skill)` (`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:314`, `:332`, `:351`, `:370`). `ls docs/reviews/` lists `code-fact-check-report-digest-pass6.md` through `-pass9.md`, and api-consistency, performance and security reports for passes 7–9 (paraphrased — no quote available because the claim is about file names in a directory listing).

**Evidence:** `docs/working/seed-build-loop-handoff.md:3-6`, `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:314-370`

---

## Claim 19: "5. Never read or write through a symlink (the digest's `inrepo` already enforces this)."

**Location:** `docs/working/seed-build-loop-handoff.md:40`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the digest enforces; does not establish anything about the future handoff script.

The digest enforces only the **read** half. `inrepo` guards fixed-name reads: `inrepo() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`scripts/dev-cycle.sh:117`). Directories go through `dirok` (`:120`) and glob items through `rawfile` (`:92`). The digest writes nothing to the repo (Claim 28), so it has no write-side guard for the handoff to reuse. The precise version: "the digest's `blocker` rule (`inrepo`, `dirok`, `rawfile`) already enforces this for reads; writes need their own check, like `questions.sh`'s `assert_write_target`." Wording only. The seed asks for re-verification, and nothing executes it today.

**Evidence:** `docs/working/seed-build-loop-handoff.md:40`, `scripts/dev-cycle.sh:92`, `scripts/dev-cycle.sh:103-120`, `scripts/questions.sh:94-108`

---

## Claim 20: "The text below is the skill's step 6/6b wording at 8b3a8ad"

**Location:** `docs/working/seed-build-loop-handoff.md:44-95`, `docs/working/seed-build-loop-handoff.md:97-131`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers byte-for-byte containment of both fenced blocks in that commit's skill; does not establish the "unreviewed after its last fix" history.

Both blocks were extracted and searched for in `git show 8b3a8ad:skills/dev-cycle/SKILL.md`: `seed block seed-a.txt verbatim in 8b3a8ad skills/dev-cycle/SKILL.md: True` and the same for `seed-b.txt` (`fcF/probes5.log`).

**Evidence:** `docs/working/seed-build-loop-handoff.md:46-131`, `fcF/skill-8b3a8ad.md`, `fcF/seed-a.txt`, `fcF/seed-b.txt`, `fcF/probes5.log`

---

## Claim 21: Global row 12: "`dev-cycle` skill … The outer loop over rows 6/9: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer. Output is triage in `docs/working/questions.md`."

**Location:** `global-instructions/CLAUDE.md:32`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the row's summary against the skill and the row numbers it names; does not establish trigger-phrase routing behavior at runtime.

Rows 6 and 9 are RPI and pr-prep (`global-instructions/CLAUDE.md` rows `| 6 |` and `| 9 |`, the latter shown at `:29`). The skill: `It runs when the user starts it; there is no timer.` (`skills/dev-cycle/SKILL.md:16-17`). Its flow is `0 digest → 1 health and cleanup → { 2 triggers | 3 questions | 4 spot-check | 4b audit check } → 5 brainstorm (conditional) → 6 roadmap and build briefs` (`:81-82`). The trigger phrases match the skill's description (`:4`).

**Evidence:** `global-instructions/CLAUDE.md:29-32`, `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:14-18`, `skills/dev-cycle/SKILL.md:80-83`

---

## Claim 22: Guide row: "Workflow-shaped (steps 0–7, with step 4b added and steps 4b and 5 conditional) but, by the criteria above, a skill: Claude completes it in one pass given the digest, with no human checkpoint mid-run beyond the Operating Modes approvals for commits and merges … It produces a self-contained artifact (the cycle record). Its mechanical parts live in `scripts/dev-cycle.sh`."

**Location:** `guides/skill-creation.md:137`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the criteria the row cites and the absence of a mid-run user gate in the skill text; does not establish whether pr-prep, which step 7 calls, adds gates beyond Operating Modes on other delivery paths.

The criteria table: `| Can Claude complete it in a single pass given the right context? | Skill | Workflow |` and `| Does it produce a self-contained artifact (review, report, critique)? | Skill | Either |` (`guides/skill-creation.md:100`, `:103`). The skill sends choices to entries rather than gating: `Re-ranking is proposed to the user as one `you: judgment` entry, not done` (`skills/dev-cycle/SKILL.md:249-250`), and deleting branches goes into `one `you: terminal` entry rather than deleting` (`:129-130`). Commits and merges `follow the Operating Modes rules in the global instructions (in /active mode, ask first)` (`:29-31`). Medium confidence: "no human checkpoint" depends on step 7's pr-prep, which on the local-merge path gates only through Operating Modes.

**Evidence:** `guides/skill-creation.md:100-104`, `guides/skill-creation.md:137`, `skills/dev-cycle/SKILL.md:27-31`, `skills/dev-cycle/SKILL.md:128-131`, `skills/dev-cycle/SKILL.md:249-250`

---

## Claim 23: Header: "The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on top of this digest. … because steps that only prose asks for do not run (scripts/questions.sh header; Q-074)." Help prints this header (`sed -n '2,21p'`).

**Location:** `scripts/dev-cycle.sh:2-6`, `scripts/dev-cycle.sh:79`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cited source and that `--help` prints lines 2–21 in full; does not re-measure the questions.sh header's own counts.

`# Why a script and not a convention: this repo's own evidence is that an` / `# unenforced instruction does not execute — docs/thoughts/failure-patterns.md` (`scripts/questions.sh:5-6`). `-h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`scripts/dev-cycle.sh:79`). Line 21 is the last header line (`# perl; a failed step exits non-zero mid-digest. Printed repo text is data.`). Executed: `--help` printed the whole header, from "Gather the mechanical signals" to "Printed repo text is data.", and exited 0 (`fcF/probes0.log`).

**Evidence:** `scripts/dev-cycle.sh:2-21`, `scripts/dev-cycle.sh:79`, `scripts/questions.sh:5-11`, `fcF/probes0.log`

---

## Claim 24: "--since start of the cycle window: commits whose committer date, in the committer's own time zone (git's %cs), is on or after this date."

**Location:** `scripts/dev-cycle.sh:10-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `%cs` using the committer's recorded offset, not the reader's TZ, and the inclusive `>=` comparison; does not establish the section 1 commit count's behavior under clock skew between committers.

The filter is `awk -v s="$SINCE" '$1 >= s'` over `%cs` (`scripts/dev-cycle.sh:190`, `:193`, and the `@%cs` lines at `:326-327`). Executed (P2): a commit dated `2026-01-01T23:30:00-0800` prints `%cs` = `2026-01-01` under `TZ=UTC` and `TZ=Asia/Tokyo` alike (`fcF/probes1.log`). Bats test 12, "--since includes commits from the start date itself", passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:190-193`, `scripts/dev-cycle.sh:326-327`, `fcF/probes1.log`, `fcF/bats.txt`

---

## Claim 25: "Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md (only its file name is read), else 14 days ago. The digest says which."

**Location:** `scripts/dev-cycle.sh:12-13`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the default's selection rule and the 14-day fallback; does not establish whether the omitted qualifiers ever bite in practice. They do not when record dates come from real cycles.

The default is the newest record that is **plain and not future-dated**, not the newest record. Future-dated names are ignored: `[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated` (`scripts/dev-cycle.sh:158`). Non-plain records are skipped: `if ! rawfile "$f"; then … continue` (`:152-157`). Bats test 11 pins it: with `cycle-9999-12-31.md` present, the window starts at `2026-02-10` (`test/scripts/dev-cycle.bats:244-251`, passing in `fcF/bats.txt`). "Only its file name is read" and "the digest says which" both hold (`source_note`, `:164-178`). The 14-day fallback holds too: `Window: since 2026-09-18 (from no cycle record found, so the default of 14 days …` on 2026-10-02 (`fcF/digest-self.md`). The precise version: "the newest plain, not future-dated record". Wording only. The Window line names any skipped newer record.

**Evidence:** `scripts/dev-cycle.sh:12-13`, `scripts/dev-cycle.sh:148-178`, `test/scripts/dev-cycle.bats:236-251`, `fcF/bats.txt`, `fcF/digest-self.md`

---

## Claim 26: "--sample how many merges to sample for the spot-check (default 2)."

**Location:** `scripts/dev-cycle.sh:14`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the default and the sample size; does not establish behavior for N larger than the merge count (`shuf -n` then prints all).

`SAMPLE=2` (`scripts/dev-cycle.sh:72`). The self-digest's section 4 lists two merges (`fcF/digest-self.md`), and bats test 13 asserts `--sample=2` gives 2 lines (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:72`, `scripts/dev-cycle.sh:280-288`, `fcF/digest-self.md`, `fcF/bats.txt`

---

## Claim 27: "Every revisit trigger is printed every run (an output line over 4096 bytes is cut); nothing carries forward."

**Location:** `scripts/dev-cycle.sh:16-17`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers decision records named `NNN-*.md` with a `## Revisit triggers` heading and log rows `| N |` mentioning "revisit", which in this repo is every trigger (a case-insensitive scan found no other heading spelling and no revisit row outside that shape). It does not establish that a log row with two separate capitalised "Revisit" clauses would print both (only the first is taken, `:222`; no such row exists today).

In this repo the self-digest prints all 11 records and all 11 log rows that mention revisit (`fcF/digest-self.md` section 2). `rg -i '^#+ *revisit' docs/decisions/*.md` finds only `## Revisit triggers`, and every log row with several "revisit" mentions has exactly one capitalised clause (rows 53 and 67). Bats test 3 asserts old, uncommitted and future-dated triggers all print after a cycle record, and that no `Carried forward` or `Main at:` line appears (`test/scripts/dev-cycle.bats:65-78`; `fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:198-240`, `test/scripts/dev-cycle.bats:65-78`, `fcF/digest-self.md`, `fcF/bats.txt`

---

## Claim 28: "Acts on $PWD's git repo (like questions.sh), so the installed copy serves any project. Read-only: writes nothing to the repo (one temp file, removed on exit)."

**Location:** `scripts/dev-cycle.sh:18-19`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a normal run, which takes the temp-file branch (questions.md and the archive both present): repo tree unchanged and temp dir empty afterwards. It does not establish cleanup when the run is killed by a signal.

`ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"` (`scripts/dev-cycle.sh:86`); `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`:261`). Executed (P6): a recursive `ls -laR --time-style=full-iso` of the throwaway repo before and after differs only in the parent directory's `..` entry, where the probe wrote its output file outside the repo. `TMPDIR` pointed at an empty directory, and afterwards it held `0 entries` (`fcF/probes2.log`).

**Evidence:** `scripts/dev-cycle.sh:85-87`, `scripts/dev-cycle.sh:261`, `fcF/probes2.log`

---

## Claim 29: "Exit: 0 digest printed; 1 bad usage, not a git repo, no default branch or no perl; a failed step exits non-zero mid-digest."

**Location:** `scripts/dev-cycle.sh:20-21`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every named exit-1 path by execution and exit 0 on success; does not execute a mid-digest step failure (static: `set -euo pipefail`, `:23`, with the child's status passed through at `:67-68`).

`--since` with no value, `--sample` with no value, `--sample=x`, `--since=2026-02-30`, `--since=2026/01/01` and `--bogus` each exit 1. Outside a repo it prints `Not inside a git repository` and exits 1 (`fcF/probes0.log`). With no branch at all it prints `Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)` and exits 1 (P9). With no perl on PATH it prints `dev-cycle.sh needs perl (to scrub its output)` and exits 1 (P10, both `fcF/probes4.log`). The self-digest exits 0 (`fcF/digest-self.md` run).

**Evidence:** `scripts/dev-cycle.sh:23-25`, `scripts/dev-cycle.sh:66-83`, `scripts/dev-cycle.sh:146`, `scripts/dev-cycle.sh:179`, `fcF/probes0.log`, `fcF/probes4.log`

---

## Claim 30: The scrub "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069), the line and paragraph separators U+2028/2029 … and tag characters (U+E0000-E007F), and cuts lines longer than 4096 bytes as the scrub receives them (before controls are removed)."

**Location:** `scripts/dev-cycle.sh:26-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed range against the byte patterns and the cut order; does not cover the ranges the comment lists as not covered (Claim 32).

```perl
# scripts/dev-cycle.sh:44-51
    my $nl = s/\n\z//;
    $_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;
    $_ .= "\n" if $nl;
    tr/\000-\010\013-\037\177//d;
    my $i = 0;
    while (1) {
      pos($_) = $i;
      last unless /\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xA8-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]/g;
```
(excerpt ends :51; enclosing perl program continues to :56 — read: deletion, resume, `print`.) `\011` (TAB) and `\012` (LF) are outside both `tr` ranges. `E2 80 A8-AE` covers U+2028-202E, and `F3 A0 80-81 80-BF` is U+E0000-E007F. The cut (`:45`) runs before the `tr` (`:47`). Bats test 5 passes: C1 CSI, RLO, a tag character, ESC, CR, U+2028/2029 and an ESC in stderr are all removed (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:40-57`, `test/scripts/dev-cycle.bats:94-124`, `fcF/bats.txt`

---

## Claim 31: "Perl is pinned to bytes: PERL_UNICODE, PERL5OPT and PERLIO are removed …, -C0 is set, and both handles are binmoded. C0 goes first; after each deletion the search resumes 3 bytes before it (no sequence is longer than 4 bytes), so a control byte inside a sequence or a nested sequence cannot reassemble one; each search restarts near the last deletion, and the line cut bounds the scrub's work per line"

**Location:** `scripts/dev-cycle.sh:30-36`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the env pinning (five env settings), split and nested sequences, and the resume's speed on the test input; does not establish a formal complexity bound (`substr` deletion is itself O(line length), bounded by the 4096-byte cut).

`env -u PERL_UNICODE -u PERL5OPT -u PERLIO LC_ALL=C perl -C0 -ne '` / `BEGIN { $| = 1; binmode STDIN; binmode STDOUT }` (`scripts/dev-cycle.sh:42-43`); `$i = $s > 3 ? $s - 3 : 0;` (`:54`). Bats test 5 runs the split and nested inputs under `""`, `PERL_UNICODE=SDA`, `PERL5OPT=-CSD`, `PERLIO=:utf8` and `PERLIO=:raw:utf8`, and passes (`fcF/bats.txt`). Executed (P5), on the 1200-line, 1300-layer input: `resume=[$s > 3 ? $s - 3 : 0] exit=0 ms=1061`, against `resume=[0] exit=0 ms=34889`, with identical output (`fcF/probes-p5.log`).

**Evidence:** `scripts/dev-cycle.sh:40-57`, `test/scripts/dev-cycle.bats:97-114`, `fcF/bats.txt`, `fcF/probes-p5.log`

---

## Claim 32: "Not covered: lone bytes 0x80-0x9F and overlong encodings …, U+061C, and invisible format characters such as zero-width ones, U+00AD, U+206A-206F and U+FFF9-FFFB"

**Location:** `scripts/dev-cycle.sh:37-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that none of these byte forms matches the scrub's patterns; does not judge whether a terminal renders them harmfully.

The only multi-byte pattern for the C1 range needs a `\xC2` lead (`/\xC2[\x80-\x9F]|…/`, `scripts/dev-cycle.sh:51`), so lone 0x80-0x9F survives. U+061C (D8 9C), U+00AD (C2 AD), U+200B-200D (E2 80 8B-8D), U+206A-206F (E2 81 AA-AF) and U+FFF9-FFFB (EF BF B9-BB) fall outside every alternative of that pattern (paraphrased — no quote available because this is a byte-range comparison against the single regex quoted above).

**Evidence:** `scripts/dev-cycle.sh:37-39`, `scripts/dev-cycle.sh:51`

---

## Claim 33: Re-exec: "the shell waits for both filters before exiting: a redirected digest is complete when the script returns … fd 3 takes the outer pipe …, then inside the group the child's stderr takes the inner pipe and its stdout goes to fd 3. Exit status: the body's (pipefail; scrub itself does not fail). DEV_CYCLE_SCRUBBED marks the child"

**Location:** `scripts/dev-cycle.sh:58-69`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fd wiring, completeness on redirect, and exit-status passthrough; does not establish the relative interleaving of stdout and stderr when merged (the comment disclaims it).

`{ DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub` / `exit "${PIPESTATUS[0]}"` (`scripts/dev-cycle.sh:67-68`). Redirections apply left to right: `2>&1` sends stderr to the inner pipe, `1>&3` sends stdout to the outer pipe. Both scrubs are pipeline members, so the shell waits for them. Bats test 8 redirects to files and finds section 7 and the last line in the file. A `--since=nope` run exits 1, and an ESC in the unknown-option error reaches `$stderr` scrubbed (tests 5 and 8, `fcF/bats.txt`). P0 shows status 1 for every usage error (`fcF/probes0.log`).

**Evidence:** `scripts/dev-cycle.sh:58-69`, `test/scripts/dev-cycle.bats:119-123`, `test/scripts/dev-cycle.bats:191-197`, `fcF/bats.txt`, `fcF/probes0.log`

---

## Claim 34: "A regular file reached without any symlink: its real path must be exactly the repo root plus the path as given, so a committed symlink (to the file or to a parent directory, pointing outside the checkout or into .git) is never read." (and `plaindir`, the same for directories)

**Location:** `scripts/dev-cycle.sh:89-95`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers file and directory symlinks inside and outside the repo, including into `.git`; does not establish behavior under a race where a path changes between the check and the read.

`rawfile() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }` (`scripts/dev-cycle.sh:92`), with `ROOT_REAL="$(pwd -P)"` (`:88`). Bats tests 6 and 7 symlink records, the log, the roadmap, questions, the idea log, a cycle record, `docs/decisions/`, `docs/working/cycles/` and `docs/working/`, one of them pointing into `.git`. They assert `SECRET` never prints, and they pass (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:88-95`, `test/scripts/dev-cycle.bats:126-189`, `fcF/bats.txt`

---

## Claim 35: "One rule decides whether an input is skipped …: walking the path top down, the first part that exists but is not plain … blocks it. Nothing below a blocking part is probed …; the blocking part is what section 8 lists and what the inline note names. A newline in a name becomes a space before it is ever printed. An absent path is not skipped, just absent."

**Location:** `scripts/dev-cycle.sh:96-101`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the walk, the stop at the first blocking part, the absent case, and newline replacement for the file component. Directory components are printed without replacement (`:108`, `:111`), but every directory the digest passes is a fixed literal name. The scope does not establish newline safety for a caller that passes a directory name containing a newline, because none exists.

```bash
# scripts/dev-cycle.sh:103-113
blocker() {  # $1 path, $2 "file" or "dir"; prints the blocking part, or nothing
  local p="" c rest="$1"
  while [[ "$rest" == */* ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"; p="${p:+$p/}$c"
    [[ -e "$p" || -L "$p" ]] || return 0
    plaindir "$p" || { printf '%s/' "$p"; return 0; }
  done
  [[ -e "$1" || -L "$1" ]] || return 0
  if [[ "$2" == dir ]]; then plaindir "$1" || printf '%s/' "$1"
  else rawfile "$1" || printf '%s' "${1//$'\n'/ }"; fi
}
```
`skipped` records `SKIP_AT` (`:121`) and `skipnote` prints it (`:123`). Bats test 7: with `docs/working` symlinked, section 8 lists only `- docs/working/`, and the note reads `docs/working/questions.md is not read: docs/working/ is not a plain file or directory`. With `docs/decisions` symlinked, an outside `log.md` does not show. A newline name prints as `- docs/decisions/002-a - FORGED.md` (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:96-123`, `test/scripts/dev-cycle.bats:157-189`, `fcF/bats.txt`

---

## Claim 36: "A fixed-name input is read only when no part of its path blocks it; the walk runs first … (Glob items use rawfile directly: their directory has already passed dirok.)" and the same for `dirok`

**Location:** `scripts/dev-cycle.sh:114-120`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both glob sites and the order of the checks inside `inrepo` and `dirok`; does not establish symlink checks for git-history reads, which read no working-tree path.

`inrepo() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:117`) and `dirok() { [[ -z "$(blocker "$1" dir)" && -d "$1" ]]; }` (`:120`) run the walk before `-f`/`-d`. The two glob sites are each guarded: `if dirok docs/working/cycles; then for f in docs/working/cycles/cycle-…; … if ! rawfile "$f"` (`:149-152`) and `if dirok docs/decisions; then decisions_glob=(…)` … `rawfile "$f" || { skipped "$f" || true; continue; }` (`:204-206`).

**Evidence:** `scripts/dev-cycle.sh:114-120`, `scripts/dev-cycle.sh:149-162`, `scripts/dev-cycle.sh:203-206`

---

## Claim 37: "DEV_CYCLE_TODAY exists only so tests can pin the date. File names are literal, not pathspecs." and "Pass git only a hash for the default branch: … a branch named `--output=<path>` would reach `git log` as an option."

**Location:** `scripts/dev-cycle.sh:124-128`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the env var's only role (it sets `TODAY`), `GIT_LITERAL_PATHSPECS`, and the hash-only invocation; does not establish whether other callers set DEV_CYCLE_TODAY (none in the repo but the bats file).

`TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1` (`:126`). Every `git log` over the branch uses `"$MAIN_SHA"` (`:190`, `:193`, `:326`), and option-like names are skipped (`[[ "$c" == -* ]] && continue`, `:135`). Bats test 19 points origin/HEAD at `--output=<victim>`; the victim file keeps `keep`, and the test passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:124-146`, `test/scripts/dev-cycle.bats:348-358`, `fcF/bats.txt`

---

## Claim 38: "A repo on some other branch name: use the current branch." / "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)"

**Location:** `scripts/dev-cycle.sh:140`, `scripts/dev-cycle.sh:146`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fallback order and the failure message; does not exercise a repo whose only branch has an unusual name (static only, `:141-144`).

The candidate order is origin/HEAD, then `main master` (`:131-133`), then the current branch (`:141-144`). P9 (no branch, detached HEAD) prints the message and exits 1 (`fcF/probes4.log`). Bats test 18 (master only) passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:129-146`, `fcF/probes4.log`, `fcF/bats.txt`

---

## Claim 39: "Keep the newest skipped date (not future-dated) to warn when it is newer than the record the window starts from." / "ignore future-dated"

**Location:** `scripts/dev-cycle.sh:153-158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the warning for a skipped record that is itself the blocker; does not cover a skip caused by a parent directory, which goes to the "records, or a directory above them" note instead (`:173-174`).

`skipped "$f" && [[ "$SKIP_AT" == "$f" && "$d" > "$skipped_record" && ! "$d" > "$TODAY" ]] && skipped_record="$d"` (`:155`); `if [[ "$skipped_record" > "$last_record" ]]; then source_note+="; a newer record, …` (`:168-169`). Bats test 10 ("a skipped newer cycle record is named in the window line") passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:148-178`, `test/scripts/dev-cycle.bats:236-242`, `fcF/bats.txt`

---

## Claim 40: Window line: "Merges, commits and section 7's changed files: those on `$MAIN` at <sha> whose committer date (in the committer's time zone) is on or after $SINCE, filtered after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

**Location:** `scripts/dev-cycle.sh:183`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every source named; does not cover the "last committed on this branch" dates, which read HEAD's history rather than `$MAIN`'s, as their own label says.

Merges and commits walk `"$MAIN_SHA"` and filter `%cs` afterwards (`:190`, `:193`). Section 7 does the same (`:326-327`). Triggers, questions, roadmap and the idea log are read from working-tree paths (`trig < "$f"`, `:213`; `bash "$QS" open`, `:262`; `awk … docs/roadmap.md`, `:295`; `"$LOG"`, `:357-358`). Executed: `on `main` at bf54363` while the worktree is on `feat/dev-cycle` (`fcF/digest-self.md`).

**Evidence:** `scripts/dev-cycle.sh:183-196`, `scripts/dev-cycle.sh:213`, `scripts/dev-cycle.sh:262`, `scripts/dev-cycle.sh:295`, `scripts/dev-cycle.sh:326-327`, `fcF/digest-self.md`

---

## Claim 41: "Walk all of history and filter by committer date afterwards: `--since` stops at the first old-dated commit, so one such commit hid every merge behind it. %cs is the committer date as YYYY-MM-DD, which compares as a string."

**Location:** `scripts/dev-cycle.sh:187-189`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's `--since` on a first-parent walk with one old-dated commit; does not establish behavior of other git versions.

Executed (P3): three merges today with a 2020-dated commit between the second and third. `--since today merges: merge f3;` against `full walk filtered: … merge f3;… merge f2;… merge f1;` (`fcF/probes1.log`). Bats test 4 passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:187-193`, `test/scripts/dev-cycle.bats:80-92`, `fcF/probes1.log`, `fcF/bats.txt`

---

## Claim 42: "A newline in a file name would otherwise print a line of its own."

**Location:** `scripts/dev-cycle.sh:211-212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `###` heading line; does not cover the trigger body, which comes from file content rather than the name.

`echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"` (`:212`). Bats test 9 asserts no `\n## 3. Fake` line and passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:211-212`, `test/scripts/dev-cycle.bats:199-205`, `fcF/bats.txt`

---

## Claim 43: "The whole clause to the cell's end; prefer a capitalised "Revisit" (the trigger sentence) over an earlier "revisit-trigger verdicts" mention."

**Location:** `scripts/dev-cycle.sh:220-223`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the first capitalised clause to the next `|`, with a case-insensitive fallback; does not cover a second capitalised clause in another cell (none in this repo, Claim 27).

`text="$(grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"` / `[[ -n "$text" ]] || text="$(grep -oiE 'revisit[^|]*' …` (`:222-223`). Bats test 2 puts "revisit-trigger verdicts" before "Revisit if gizmos …" with a 500-char tail, and passes. The self-digest prints row 35's lowercase `revisit at the A8 post-restructure measurement.` through the fallback (`fcF/digest-self.md`).

**Evidence:** `scripts/dev-cycle.sh:215-225`, `test/scripts/dev-cycle.bats:51-63`, `fcF/bats.txt`, `fcF/digest-self.md`

---

## Claim 44: "Name every decision input skipped here, even when other triggers printed: a reader of this section alone must see that some were not read."

**Location:** `scripts/dev-cycle.sh:229-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers skips added during section 2 (directory, glob items, log); does not cover cycle-record skips, which belong to the Window line.

`if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then` … `echo "Not read: $p is not a plain file or directory (section 8); its triggers are missing above."` (`:231-235`). Bats test 10 asserts `if plain.` and `Not read: docs/decisions/log.md …` together, and the "No revisit triggers in the decision inputs that were read" summary. It passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:202-240`, `test/scripts/dev-cycle.bats:207-234`, `fcF/bats.txt`

---

## Claim 45: "questions.sh checks that the archive exists with a test that follows a symlink …, so the archive passes the same check first. It is checked once, up front, so a non-plain archive is listed in section 8 whatever branch below runs."

**Location:** `scripts/dev-cycle.sh:246-250`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers questions.sh's `-f` test and the single up-front check; does not cover questions.sh commands other than `open`.

`[[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; missing=1; }` (`scripts/questions.sh:135`, inside `require_files`, which `cmd_open` calls, `:408-409`). `qa_at=""; skipped "$QA" && qa_at="$SKIP_AT"` runs before the `if` chain (`scripts/dev-cycle.sh:250`). Bats test 10 removes questions.md and still finds the symlinked archive in section 8. P1b's directory archive is listed too (`fcF/bats.txt`, `fcF/probes1b.log`).

**Evidence:** `scripts/dev-cycle.sh:246-279`, `scripts/questions.sh:132-138`, `scripts/questions.sh:408-414`, `fcF/bats.txt`, `fcF/probes1b.log`

---

## Claim 46: "`open` prints "ID  route  slug" in columns of 2+ spaces; a route can contain one space ("you: judgment"), a slug can contain "trigger"."

**Location:** `scripts/dev-cycle.sh:263-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the format string and parsing by `-F'  +'`; does not establish slug content beyond the `### Q-NNN · <slug>` grammar.

`printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:412`). The longest route, `you: terminal` / `you: judgment` (13 chars), still gets two spaces. The self-digest prints `Open by route: agent=7, deferred=3, trigger=2, you: terminal=1` (`fcF/digest-self.md`). Bats test 16 (slug `a-trigger-in-the-slug`) passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:262-272`, `scripts/questions.sh:408-414`, `fcF/digest-self.md`, `fcF/bats.txt`

---

## Claim 47: "Seeded by a hash of the date: same day, same merges; different days usually differ."

**Location:** `scripts/dev-cycle.sh:282-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers determinism for a fixed date and merge list, and variation across four dates over 20 merges; does not establish the statistical quality of the sampling.

`seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"` / `shuf -n "$SAMPLE" --random-source=<(yes "$seed")` (`:284-285`). Bats tests 13 and 14 pass (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:280-288`, `test/scripts/dev-cycle.bats:261-284`, `fcF/bats.txt`

---

## Claim 48: "No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill."

**Location:** `scripts/dev-cycle.sh:299`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the template's existence; does not establish that the template's headings match section 5's heading rule beyond `## Next` (they do: `## Next` is a bare heading).

`Update `docs/roadmap.md`, creating it from this template if missing:` (`skills/dev-cycle/SKILL.md:210`), with `## Now` / `## In flight` / `## Next` / `## Ideas` / `## Done` (`:219-223`).

**Evidence:** `scripts/dev-cycle.sh:299`, `skills/dev-cycle/SKILL.md:208-224`

---

## Claim 49: "A merge whose diff against its first parent touches files but no doc (a path under docs/, a *.md file, or a file named README or README.*, all any case): step 4 checks each one (rule: undocumented is broken). Listed up to 30."

**Location:** `scripts/dev-cycle.sh:303-305`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the doc classification, the first-parent diff, the 30 cap, and the skill's step 4 reading; does not establish whether a rename counts both names (git's default rename detection reports the new name only).

`git diff --name-only -z "$full^1" "$full" | awk … p = tolower($0); if (p ~ /^docs\// || p ~ /\.md$/ || b == "readme" || index(b, "readme.") == 1) d++; else c++ …` (`:309`); `printf '%s\n' "${flagged[@]:0:30}"` (`:316`). The skill: `Also check every merge the digest lists under "Merges with code but no docs" (the fourth rule)` (`skills/dev-cycle/SKILL.md:168-169`). Bats test 22 (README_gen.sh flagged; README.txt, docs/, notes.md and NOTES.MD not flagged) passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:302-318`, `skills/dev-cycle/SKILL.md:163-171`, `test/scripts/dev-cycle.bats:369-392`, `fcF/bats.txt`

---

## Claim 50: "Every file any first-parent commit in the window touched (a merge counts its diff against its first parent), not a net diff … core.quotePath=false prints non-ASCII names as they are; git still quotes a name holding a control character (so each name is one line), and the patterns below accept the quote."

**Location:** `scripts/dev-cycle.sh:321-329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers files under the pathspec on the next line (`-- skills workflows docs/decisions`); "every file" means every file there. Covers merge counting, non-ASCII names and control-character quoting; does not establish behavior on git older than 2.31 (`--diff-merges=first-parent`).

Command: `git -c core.quotePath=false log "$MAIN_SHA" --first-parent --diff-merges=first-parent --name-only --format='@%cs' -- skills workflows docs/decisions` (`:326`). Executed (P8, git 2.39.5): a skill path holding a newline prints as `"skills/a\nb/SKILL.md"` on one line and is counted, and a workflow file added only through a merge is listed (`fcF/probes3.log`). Bats test 23 (`skills/café/SKILL.md`, a reverted `workflows/flow.md`) passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:320-338`, `fcF/probes3.log`, `fcF/bats.txt`

---

## Claim 51: "The skill's step 5 appends "## Brainstorm YYYY-MM-DD" after reading the log (its ideas go to the roadmap); seeding appends "- <idea> (signal: …)" lines, and only lines of that shape count."

**Location:** `scripts/dev-cycle.sh:353-355`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count's reset at each brainstorm heading and the line shape; does not establish that agents write lines of that shape.

The skill: `Then append `## Brainstorm YYYY-MM-DD` to the idea log … the surviving ideas go to the roadmap's Ideas` (`skills/dev-cycle/SKILL.md:205-206`) and `shaped `- <idea> (signal: <what prompted it>)`` (`:72`). The counter: `/^## Brainstorm [0-9]…/ { c = 0; next } /^- [^ ]/ && index(substr($0, 4), "(signal: ") && /\)[[:space:]]*$/ { c++ }` (`scripts/dev-cycle.sh:358`). Bats test 23 expects `Ideas seeded since: 2` from a log holding a pre-brainstorm seed, a format example and an unclosed line. It passes (`fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:351-369`, `skills/dev-cycle/SKILL.md:70-73`, `skills/dev-cycle/SKILL.md:201-206`, `test/scripts/dev-cycle.bats:406-423`, `fcF/bats.txt`

---

## Claim 52: "No {n} intervals in the awk regex: mawk, Debian's default awk, lacks them."

**Location:** `scripts/dev-cycle.sh:356`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers this host's awk (Debian 12.15, `/usr/bin/awk` → mawk 1.3.4 20200120); does not establish behavior of later mawk builds, which may support intervals.

P4: `readlink -f $(command -v awk)` → `/usr/bin/mawk`, `mawk 1.3.4 20200120`. `echo aaaa | awk '/^a{4}$/ …'` prints no match, only `done` (`fcF/probes1.log`).

**Evidence:** `scripts/dev-cycle.sh:356-358`, `fcF/probes1.log`

---

## Claim 53: Section 8: "Each is a symlink, or a file or directory of the wrong kind, so it was not read; nothing below a listed directory was read or probed:"

**Location:** `scripts/dev-cycle.sh:375`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every input path the digest reads from the working tree (cycles dir and records, decisions dir, records and log, questions and archive, roadmap, idea log), plus wrong-kind entries such as a directory where a file belongs. It does not cover `questions.sh` itself, which is a tool, not a repo input.

Each fixed input goes through `inrepo`, `dirok` or `skipped`, and `blocker` returns at the first blocking part (Claim 35). P1b lists a directory archive (`- docs/working/questions-archive.md`). Bats test 7 asserts that a `log.md` placed below a symlinked `docs/decisions` never appears (`fcF/probes1b.log`, `fcF/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:371-377`, `scripts/dev-cycle.sh:103-123`, `test/scripts/dev-cycle.bats:157-173`, `fcF/probes1b.log`, `fcF/bats.txt`

---

## Claim 54: "(Launching autonomous build loops from here is a separate unit: roadmap item "Build-loop handoff", `docs/working/seed-build-loop-handoff.md`.)"

**Location:** `skills/dev-cycle/SKILL.md:14-16`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the roadmap item and the seed file; does not establish that no other skill text still assumes the handoff. A separate read of the whole skill found none: In flight tracks briefs the user starts (`:226-242`), and the final message hands briefs to the user (`:291-294`).

`- **Build-loop handoff** (follows this dev cycle)` (`docs/roadmap.md:17`); `**Status:** not started. Roadmap item "Build-loop handoff".` (`docs/working/seed-build-loop-handoff.md:3`).

**Evidence:** `skills/dev-cycle/SKILL.md:14-16`, `skills/dev-cycle/SKILL.md:226-242`, `skills/dev-cycle/SKILL.md:291-294`, `docs/roadmap.md:17-21`, `docs/working/seed-build-loop-handoff.md:3`

---

## Claim 55: "**Build-loop policy** (`self-merge` or `review`; codebase onboarding's step 13 asks the user for it): recorded for the build-loop handoff, which this skill does not run yet. This skill does not read it." / "**Idea sources** (read by step 5, kept by hand)."

**Location:** `skills/dev-cycle/SKILL.md:56-59`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers step 13 and step 5's reading; does not establish that onboarding has been re-run for this repo (Q-103 says it predates the setting).

`### 13. Gate — validate with the team` … `Also settle the project's **build-loop policy** with the user` (`workflows/codebase-onboarding.md:447`, `:453`). Step 5 reads `the idea sources `docs/dev-cycle.md` lists` (`skills/dev-cycle/SKILL.md:202-203`).

**Evidence:** `skills/dev-cycle/SKILL.md:56-59`, `skills/dev-cycle/SKILL.md:201-203`, `workflows/codebase-onboarding.md:447-457`

---

## Claim 56: "The digest applies the same rule to everything it reads (and also skips anything that is not a regular file or directory) and lists what it skipped in its section 8."

**Location:** `skills/dev-cycle/SKILL.md:66-68`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the digest's working-tree inputs; does not cover its git-history reads, which involve no working-tree path.

Same evidence as Claims 34, 35 and 53: `blocker` checks each component with `plaindir`/`rawfile` (`scripts/dev-cycle.sh:103-113`), the glob is expanded only after `dirok` (`:149`, `:204`), and section 8 prints `SKIPPED` (`:372-377`). Bats tests 6, 7 and 10 pass, and P1b shows a wrong-kind archive skipped (`fcF/bats.txt`, `fcF/probes1b.log`).

**Evidence:** `skills/dev-cycle/SKILL.md:61-68`, `scripts/dev-cycle.sh:103-123`, `scripts/dev-cycle.sh:371-377`, `fcF/bats.txt`, `fcF/probes1b.log`

---

## Claim 57: "Run `~/.claude/scripts/dev-cycle.sh` … (inside claude-workflows, its own `scripts/dev-cycle.sh`)"

**Location:** `skills/dev-cycle/SKILL.md:92-94`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both installers stage the whole `scripts/` directory, so the digest lands at that path with `questions.sh` next to it; does not establish that a given host has re-run the installer since this branch.

`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`); `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)` (`devcontainer-config/link-claude-home.sh:50`). The digest finds questions.sh next to itself: `QS="$SCRIPT_DIR/questions.sh"` (`scripts/dev-cycle.sh:243`).

**Evidence:** `skills/dev-cycle/SKILL.md:92-94`, `devcontainer-config/install.sh:125-135`, `devcontainer-config/link-claude-home.sh:43-50`, `scripts/dev-cycle.sh:243-244`

---

## Claim 58: "Run `~/.claude/scripts/dev-cycle.sh` from the root of an up-to-date checkout of the default branch, before step 1 creates the cycle branch"

**Location:** `skills/dev-cycle/SKILL.md:92-93`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which part of the skill creates the branch; does not establish any harm from the order. The digest is read-only, and uncommitted `init` files carry over to a new branch.

Step 1's text does not create a branch. Its bullets are quiesce and health check, `questions.sh archive` then `index`, worktrees and merged branches, merged working docs, and mechanical fixes (`skills/dev-cycle/SKILL.md:121-135`). The branch comes from the Rules: `**Its own branch.** Before the first change, check `git branch --show-current` and create `chore/dev-cycle-<date>` from the default branch` (`:27-28`). Step 0 itself may make the first change (`run `~/.claude/scripts/questions.sh init` first`, `:100`), so by the Rules the branch would be created in step 0, before that init. The precise version: "before the cycle branch is created (Rules: 'Its own branch', before the first change, which may be step 0's `init`)", or have step 1 name the branch creation. Wording only, no behavioral consequence.

**Evidence:** `skills/dev-cycle/SKILL.md:27-31`, `skills/dev-cycle/SKILL.md:92-103`, `skills/dev-cycle/SKILL.md:119-135`

---

## Claim 59: "Its sections feed the steps: 1 activity (context), 2 triggers (step 2), 3 watched questions (step 3), 4 spot-check sample and 6 merges with code but no docs (step 4), 5 roadmap (step 6), 7 inputs (steps 4b and 5), 8 skipped inputs (the record's `## Skipped inputs`)." / "It is read-only."

**Location:** `skills/dev-cycle/SKILL.md:95-99`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the section numbers and titles and the read-only property; does not judge whether each step uses its section well.

The self-digest's headings are `## 1. Activity`, `## 2. Revisit triggers`, `## 3. Watched questions (trigger and deferred routes)`, `## 4. Spot-check sample`, `## 5. Roadmap`, `## 6. Merges with code but no docs`, `## 7. Inputs for steps 4b and 5` and `## 8. Skipped inputs` (`fcF/digest-self.md`). Read-only: Claim 28.

**Evidence:** `skills/dev-cycle/SKILL.md:95-99`, `scripts/dev-cycle.sh:186`, `scripts/dev-cycle.sh:371`, `fcF/digest-self.md`, `fcF/probes2.log`

---

## Claim 60: "If the repo has no `docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` first; if init refuses (no questions.sh, or a skipped archive), note it in the record and carry on: step 3 reports it."

**Location:** `skills/dev-cycle/SKILL.md:99-102`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers init's behavior for each kind of skipped archive and step 3's report; does not cover init's other refusal (a symlinked or outside-root `docs/working/questions.md` target), which the digest also reports as skipped.

`init` refuses only symlink-based skips: `[[ -L "$file" ]] && die …` / `[[ -L "$dir" ]] && die …` and the containment check (`scripts/questions.sh:98-105`). For an archive of the wrong kind (here a directory), init does **not** refuse. `[[ -e "$file" ]] && { echo "  = exists: $file"; continue; }` (`:425`) skips it, and init exits 0. Executed (P1, repeated as P1b): `+ created: …/questions.md`, `= exists: …/questions-archive.md`, `init exit 0`. That run's digest then prints `**Watched questions were NOT checked** — docs/working/questions-archive.md is not read: …` and lists the archive in section 8 (`fcF/probes1b.log`). The conclusion "step 3 reports it" holds in every case. Only the parenthetical's implication that every skipped archive makes init refuse is too broad. The precise version: "if init refuses (no questions.sh, or a symlinked archive or directory) or the digest still reports the archive skipped". Wording only, no behavioral consequence, since the instruction "carry on: step 3 reports it" is correct either way.

**Evidence:** `skills/dev-cycle/SKILL.md:99-102`, `scripts/questions.sh:94-110`, `scripts/questions.sh:418-445`, `scripts/dev-cycle.sh:250-260`, `fcF/probes1.log`, `fcF/probes1b.log`

---

## Claim 61: Window-line checks: "It says "records, or a directory above them, were skipped", or names a newer record that was skipped: a record, or one of `docs/`, `docs/working/` or the cycles directory, is not a plain file or directory"

**Location:** `skills/dev-cycle/SKILL.md:105-109`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two quoted digest phrasings and their causes; does not cover older skipped records, which correctly produce no note.

`source_note="no readable cycle record (records, or a directory above them, were skipped as not a plain file or directory: section 8), so the default of 14 days"` (`scripts/dev-cycle.sh:174`) and `; a newer record, docs/working/cycles/cycle-$skipped_record.md, was skipped …` (`:169`). Bats tests 6, 7 and 11 assert both phrasings, with `docs/working/` and `docs/working/cycles/` symlinked and with a symlinked newer record, and they pass (`fcF/bats.txt`).

**Evidence:** `skills/dev-cycle/SKILL.md:103-113`, `scripts/dev-cycle.sh:148-178`, `test/scripts/dev-cycle.bats:148`, `test/scripts/dev-cycle.bats:187`, `test/scripts/dev-cycle.bats:241`, `fcF/bats.txt`

---

## Claim 62: "Read failures from the file and triage them as pr-prep step 5a does (caused by recent work, pre-existing, flaky)."

**Location:** `skills/dev-cycle/SKILL.md:124-125`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the step number and the three classes; does not establish that pr-prep's re-run guidance applies unchanged to a health-check file.

`#### 5. Verify and annotate (parallelizable)` (`workflows/pr-prep.md:311`); `- [ ] All CI failures triaged into one of the three classes (caused-by-branch / pre-existing / flaky)` (`:350`); step 3c calls the full gate `[step 5a]` (`:242`).

**Evidence:** `skills/dev-cycle/SKILL.md:121-125`, `workflows/pr-prep.md:242`, `workflows/pr-prep.md:311-353`

---

## Claim 63: "`~/.claude/scripts/questions.sh archive` then `index`" and "Do not run `archive-working-docs.sh`: it serves the self-improvement loop and moves files into a gitignored archive."

**Location:** `skills/dev-cycle/SKILL.md:126-127`, `skills/dev-cycle/SKILL.md:132-134`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two subcommands' existence and the archive script's purpose and destination; does not run either script.

`index)   cmd_index ;;` / `archive) cmd_archive ;;` (`scripts/questions.sh:449-450`). `# Archive docs/working/ artifacts from a completed self-improvement run.` and `# Moves all non-permanent files from docs/working/ into docs/working/archive/` (`scripts/archive-working-docs.sh:2`, `:6`); `docs/working/archive/` is ignored (`.gitignore:16`).

**Evidence:** `scripts/questions.sh:446-458`, `scripts/archive-working-docs.sh:2-16`, `.gitignore:16`

---

## Claim 64: "If the digest prints "Watched questions were NOT checked" (with the cause: a skipped questions file or archive, questions.sh missing, or `questions.sh open` failing)"

**Location:** `skills/dev-cycle/SKILL.md:158-161`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the four causes are exactly the digest's four `$nc` branches; does not cover the "No docs/working/questions.md in this repo." branch, which is absence, not a failed check.

`nc="**Watched questions were NOT checked** —"` used at `:253` (questions.md skipped), `:257` (`questions.sh was not found`), `:259` (archive skipped) and `:274` (`questions.sh open failed`) (`scripts/dev-cycle.sh:251-278`).

**Evidence:** `skills/dev-cycle/SKILL.md:158-161`, `scripts/dev-cycle.sh:251-278`

---

## Claim 65: "Also check every merge the digest lists under "Merges with code but no docs" (the fourth rule)."

**Location:** `skills/dev-cycle/SKILL.md:168-169`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the section title and the rule's position; does not judge step 4's method.

The fourth Rules bullet is `- **Undocumented is broken.**` (`skills/dev-cycle/SKILL.md:37`), after "Repo text is evidence" (`:22`), "Its own branch" (`:27`) and "Attention is the budget" (`:32`). The section title is `## 6. Merges with code but no docs` (`scripts/dev-cycle.sh:302`).

**Evidence:** `skills/dev-cycle/SKILL.md:20-41`, `skills/dev-cycle/SKILL.md:168-169`, `scripts/dev-cycle.sh:302`

---

## Claim 66: Step 4b: "Its triggers, from the digest's section 7 and the last record" and step 5: "(the digest's section 7 prints the counts and dates; readiness and direction are judged here)"

**Location:** `skills/dev-cycle/SKILL.md:178`, `skills/dev-cycle/SKILL.md:191-192`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that section 7 prints the skill/workflow and decision-record lists, roadmap counts, last brainstorm date and seed count, and leaves the model to the record; does not cover the judged conditions.

The self-digest section 7 prints `Skill or workflow files changed on `main` in the window: 43`, `Decision records added or changed … : 16`, `Roadmap Now: 2 item(s)`, In flight and Next counts, and `No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded` (`fcF/digest-self.md`). Bats test 23 shows `Last brainstorm: 2026-01-01 (7 day(s) ago)` (`fcF/bats.txt`). The model line: `The model version is not in git: compare it with the last cycle record's.` (`scripts/dev-cycle.sh:330`).

**Evidence:** `skills/dev-cycle/SKILL.md:173-199`, `scripts/dev-cycle.sh:320-369`, `fcF/digest-self.md`, `fcF/bats.txt`

---

## Claim 67: "Then append `## Brainstorm YYYY-MM-DD` to the idea log, so the next digest counts seeds from here"

**Location:** `skills/dev-cycle/SKILL.md:205-206`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reset and the date read; does not cover a heading written with a different format (it would not reset the count).

Same counter as Claim 51 (`scripts/dev-cycle.sh:358`, `{ c = 0; next }` on the heading), and the last heading's date is read at `:357`. Bats test 23 passes (`fcF/bats.txt`).

**Evidence:** `skills/dev-cycle/SKILL.md:205-206`, `scripts/dev-cycle.sh:357-364`, `fcF/bats.txt`

---

## Claim 68: "write `docs/working/handoffs/YYYY-MM-DD-<slug>.md` … The briefs land with step 7, so they are on the default branch when the user starts one." (and the record at `docs/working/cycles/`, the idea log)

**Location:** `skills/dev-cycle/SKILL.md:254-259`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that none of these paths is gitignored, so committing them can land them; does not establish that step 7's pr-prep merge succeeds.

`git check-ignore` reports `not ignored` for `docs/working/handoffs/2026-10-02-x.md`, `docs/working/cycles/cycle-2026-10-02.md` and `docs/working/idea-log.md` (`fcF/probes5.log`), although many `docs/working/` patterns are ignored (`.gitignore:16-36`).

**Evidence:** `skills/dev-cycle/SKILL.md:252-259`, `skills/dev-cycle/SKILL.md:263`, `.gitignore:16-36`, `fcF/probes5.log`

---

## Claim 69: Record template examples "docs/decisions/014-secure-tool-guidance-layers.md: not fired" and "log row 62: cannot tell" / "Record one verdict for every trigger, under the name the digest prints."

**Location:** `skills/dev-cycle/SKILL.md:278-284`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both examples are real trigger names in the digest's own format; does not judge the example verdicts.

The self-digest prints `### docs/decisions/014-secure-tool-guidance-layers.md (last committed on this branch: 2026-09-26)` and `- log row 62 (2026-09-28): > Revisit if stacking overhead dominates small features, …` (`fcF/digest-self.md`).

**Evidence:** `skills/dev-cycle/SKILL.md:276-284`, `scripts/dev-cycle.sh:212`, `scripts/dev-cycle.sh:224`, `fcF/digest-self.md`

---

## Claim 70: "The next digest starts its window from this file's date (only the file name is read); if a cycle skips its record, the next window widens back to the older record (or to the 14-day default when there is none)"

**Location:** `skills/dev-cycle/SKILL.md:284-287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the selection and fallback; carries Claim 25's qualifier (a future-dated or skipped record is not used), which does not bite for a record written by a real cycle on its own date.

`d="${f##*/cycle-}"; d="${d%.md}"` (`scripts/dev-cycle.sh:151`, file name only); `SINCE="$(date -d "$TODAY - 14 days" +%F)"` (`:172`). Bats test 11 and the self-digest's 14-day default (`fcF/bats.txt`, `fcF/digest-self.md`).

**Evidence:** `skills/dev-cycle/SKILL.md:284-289`, `scripts/dev-cycle.sh:148-178`, `fcF/bats.txt`, `fcF/digest-self.md`

---

## Claim 71: "Contract tests for scripts/dev-cycle.sh … Each test builds a throwaway repo under $BATS_TEST_TMPDIR; this repo is untouched." and "HOME in the temp dir: the ~/.claude/scripts fallback can't reach the real one."

**Location:** `test/scripts/dev-cycle.bats:3-4`, `test/scripts/dev-cycle.bats:14-16`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers setup and every test body's write targets; does not establish behavior under a `BATS_TEST_TMPDIR` that points into the repo.

`R="$BATS_TEST_TMPDIR/repo"; make_repo "$R" main; cd "$R"` (`:17-19`), `export HOME="$BATS_TEST_TMPDIR/home"` (`:15`). The only use of `$REPO_ROOT` besides `$DC` is a read: `cp -r "$REPO_ROOT/scripts" "$BATS_TEST_TMPDIR/tools"` (`:288`).

**Evidence:** `test/scripts/dev-cycle.bats:1-35`, `test/scripts/dev-cycle.bats:286-295`

---

## Claim 72: Test name "prints all seven sections in a repo with no docs"

**Location:** `test/scripts/dev-cycle.bats:37`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the name against the test body and the script's section count; does not affect what the test asserts.

The body loops over **eight** headings, `"## 1. Activity"` … `"## 7. Inputs for steps 4b and 5" "## 8. Skipped inputs"` (`test/scripts/dev-cycle.bats:40-42`), and the script prints eight sections (`scripts/dev-cycle.sh:186`, `:371`). The name dates from db0e5ca ("digest prints code-without-docs merges and 4b/5 inputs", when there were seven). b88a9c4 ("pass-9 digest fixes (skipped inputs reported, test reach)") added `## 8. Skipped inputs` to both files without renaming the test (paraphrased — no quote available because this is commit history: `git log -S'prints all seven sections'` and `git log -S'## 8. Skipped inputs'`). It should read "prints all eight sections". Wording only: the assertions are complete.

**Evidence:** `test/scripts/dev-cycle.bats:37-49`, `scripts/dev-cycle.sh:371`, `git log -S'## 8. Skipped inputs' -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats`

---

## Claim 73: "Fast-forward a 2020-dated commit onto main, then merge today: --since used to stop its walk at the old commit, so it counted only the newest merge and hid the three older ones behind the old commit."

**Location:** `test/scripts/dev-cycle.bats:81-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git's `--since` behavior in that shape (P3 reproduces it with 2+1 merges); does not establish the pre-fix script's exact output, which was not re-run.

P3: `--since today merges: merge f3;` only (`fcF/probes1.log`). The test expects `4 merge(s)` and passes (`fcF/bats.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:80-92`, `fcF/probes1.log`, `fcF/bats.txt`

---

## Claim 74: "C1 CSI (U+009B), RLO (U+202E), a tag character (U+E0041), ESC, CR." and "Split by a C0 byte, and nested: neither may reassemble a sequence."

**Location:** `test/scripts/dev-cycle.bats:96-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the bytes written encode the named characters and shapes; the pass/fail is Claim 30's.

`\xc2\x9b` = U+009B, `\xe2\x80\xae` = U+202E, `\xf3\xa0\x81\x81` = U+E0041, `\033`, `\r` (`:97`). Line 99 has `\xc2\x01\x9b` (split by C0) and `\xc2\xc2\x9b\x9b` (nested), with the same shapes for the 3- and 4-byte sequences.

**Evidence:** `test/scripts/dev-cycle.bats:96-103`

---

## Claim 75: "1000 nested layers inside the cut are removed entirely; a 80 KB line is cut (which is what bounds the scrub's work) and the run stays fast." / "restarting each line per layer took ~35 s on the authoring host for these 1200 lines, against about 1 s with the resume."

**Location:** `test/scripts/dev-cycle.bats:104-105`, `test/scripts/dev-cycle.bats:110-111`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both timings on this host (the authoring host's figures are reproduced, not re-observed there) and the cut; does not establish timings on slower hosts, where the test's `timeout 10` could be tight.

P5 on the same 1200-line input: resume `ms=1061`, restart-from-0 `ms=34889` (`fcF/probes-p5.log`). The 1000-layer input is 2000 bytes, under the 4096 cut, and the test asserts `if mn.` and `[line cut at 4096 bytes]`. It passes (`fcF/bats.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:104-114`, `fcF/probes-p5.log`, `fcF/bats.txt`

---

## Claim 76: "A fixed name below a skipped directory is not probed: whether log.md exists out there must not show." / "docs/working itself a symlink: only it is listed (nothing below it is probed), the window says records were skipped, and notes name it."

**Location:** `test/scripts/dev-cycle.bats:166-167`, `test/scripts/dev-cycle.bats:180-181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what the assertions check, which matches the comments; does not establish non-probing by syscall trace (the test infers it from output).

The assertions are `[[ "$output" != *"docs/decisions/log.md"* ]]` (`:170`), `"$skipped" != *"docs/working/cycles"* && "$skipped" != *"questions.md"*` (`:186`), the Window phrase (`:187`) and the note naming `docs/working/` (`:188`). All pass (`fcF/bats.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:157-189`, `fcF/bats.txt`

---

## Claim 77: "No questions-archive.md: questions.sh open exits non-zero."

**Location:** `test/scripts/dev-cycle.bats:330`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `open`'s `require_files` failure; does not cover other `open` failures.

`[[ $missing -eq 0 ]] || die "no questions doc here — run \`$QS_CMD init\` first"` (`scripts/questions.sh:137`), with `die` exiting 1 (`:76`). The test expects `questions.sh open failed` and passes (`fcF/bats.txt`).

**Evidence:** `scripts/questions.sh:76`, `scripts/questions.sh:132-138`, `test/scripts/dev-cycle.bats:327-336`, `fcF/bats.txt`

---

## Claim 78: "Changed and reverted inside the window: still a change."

**Location:** `test/scripts/dev-cycle.bats:398-399`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what the commented lines can make the test observe; does not affect the script, whose behavior the comment states correctly.

The comment sits above `echo t > skills/demo/tmp.md && … git rm -q skills/demo/tmp.md`. `tmp.md` is not a `SKILL.md`, so section 7's filter `'^"?(skills/.*/SKILL\.md|workflows/[^/]*\.md)"?$'` (`scripts/dev-cycle.sh:328`) drops it, and no assertion can see it. Executed (P7): only that add-and-remove in the window gives `Skill or workflow files changed on `main` in the window: 0` (`fcF/probes2.log`). The reverted-change property is actually pinned by the next lines: `workflows/flow.md` is merged and then `git rm`-ed (`:400-401`) and is expected in the output (`:419`). A net-diff implementation would drop it and fail the test (paraphrased — no quote available because this is reasoning over `:400-401` and `:419` together). The precise version moves the comment to `:400` or makes the line-399 file a `SKILL.md`. Wording only: the property is pinned.

**Evidence:** `test/scripts/dev-cycle.bats:394-423`, `scripts/dev-cycle.sh:326-329`, `fcF/probes2.log`

---

## Claim 79: "README_gen.sh is code; a README.txt or docs/ alone is a doc." / "A non-ASCII skill name still counts." / "Heading case and suffixes do not hide items." / "Section 5 uses the same heading rule: CRLF on a bare heading here, then a suffix below; "## Nextgen" is not Next."

**Location:** `test/scripts/dev-cycle.bats:378`, `test/scripts/dev-cycle.bats:402-409`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each comment's case is set up and asserted; does not cover heading forms other than bare, a space suffix and `(`.

The cases are set up at `:379-384` and `:403-406` and asserted at `:387-391`, `:412`, `:417` and `:419-423`. Section 5's rule: `t == "## next" || index(t, "## next ") == 1 || index(t, "## next(") == 1` after `sub(/\r$/, "")` (`scripts/dev-cycle.sh:295`). Bats tests 22 and 23 pass (`fcF/bats.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:369-423`, `scripts/dev-cycle.sh:295`, `scripts/dev-cycle.sh:343`, `fcF/bats.txt`

---

## Claim 80: Onboarding step 13: "may the autonomous build loops the dev-cycle's build-loop handoff will start (a planned unit; the skill writes build briefs today) merge on their own (`self-merge`; it covers only work outside what later runs follow unreviewed …) … Record it as `Build-loop policy: <value>` in `docs/dev-cycle.md`, creating the file from the template in the dev-cycle skill's "Project settings" if missing. Until it is set, it counts as `review`."

**Location:** `workflows/codebase-onboarding.md:453-457`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the template, the planned-unit wording, and the default; does not establish onboarding behavior in other repos.

The skill's `**Project settings.** `docs/dev-cycle.md` holds this repo's dev-cycle settings:` with a template holding `Build-loop policy: review` (`skills/dev-cycle/SKILL.md:43-54`). The default matches `Anything else counts as unset, which means `review`.` (`docs/dev-cycle.md:19`) and the seed's item 2 (`docs/working/seed-build-loop-handoff.md:29-31`). The handoff is planned: `**Status:** not started.` (`seed-build-loop-handoff.md:3`).

**Evidence:** `workflows/codebase-onboarding.md:447-460`, `skills/dev-cycle/SKILL.md:43-59`, `docs/dev-cycle.md:17-19`, `docs/working/seed-build-loop-handoff.md:3`, `docs/working/seed-build-loop-handoff.md:29-31`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 72** (`test/scripts/dev-cycle.bats:37`): test name says "seven sections" but asserts eight, since b88a9c4 added section 8. Rename to "prints all eight sections …". Wording.

### Mostly Accurate
- **Claim 19** (`docs/working/seed-build-loop-handoff.md:40`): "the digest's `inrepo` already enforces this" covers reads only (via `inrepo`/`dirok`/`rawfile`). The digest has no write guard. Wording.
- **Claim 25** (`scripts/dev-cycle.sh:12-13`, also the `--help` text): "the newest … record" is the newest plain, not-future-dated record. Wording.
- **Claim 58** (`skills/dev-cycle/SKILL.md:93`): "before step 1 creates the cycle branch". Step 1 does not create it; the Rules' "Its own branch" does, before the first change, which may be step 0's `init`. Wording.
- **Claim 60** (`skills/dev-cycle/SKILL.md:99-102`): init refuses a symlink-skipped archive but not a wrong-kind one (exit 0, "= exists"). "Carry on: step 3 reports it" holds either way. Wording.
- **Claim 78** (`test/scripts/dev-cycle.bats:398`): the "changed and reverted" comment sits on a `tmp.md` case the test cannot observe. The property is pinned by `workflows/flow.md` at `:400-401`. Wording.

### Unverifiable
None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.
- Answered: yes. All 13 in-scope files were harvested; 80 claims (47 executed, 33 static); no Incorrect, no Unverifiable; 1 Stale and 5 Mostly accurate, all wording with no behavioral consequence.
- Out of scope: `docs/reviews/` (excluded by the brief); history-only statements with no code subject (row 68's "8 gaps were applied", Q-100's token estimates, Q-103's "you said …").
- Escalate: nothing behavioral. The six wording items above are one-line fixes if the loop wants a fully clean fact-check.
- Decisions I made: Legibility-target uses the canonical three values (code-review's default mapping), not the agent/maintainer/user values of the pass-16 report. Claim 50 is Verified with the pathspec named in Scope, not Mostly accurate, because the pathspec sits on the very next line. Claim 25 is Mostly accurate rather than Verified-with-residue, because the code contradicts "newest" for a future-dated name.
