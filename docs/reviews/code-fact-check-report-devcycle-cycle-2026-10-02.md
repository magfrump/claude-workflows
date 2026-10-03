# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** branch diff `git diff main...HEAD`, chore/dev-cycle-2026-10-02 vs main (7 files: docs/roadmap.md, docs/working/briefs/2026-10-02-{build-loop-handoff,doc-drift-cycle1,exit-scan-insteadof-target}.md, docs/working/cycles/cycle-2026-10-02.md, docs/working/idea-log.md, docs/working/questions.md)
**Commit:** 20a462d4
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-02
**Total claims checked:** 42
**Summary:** 28 verified, 7 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable

Execution provenance. Every executed command ran under `timeout`, with output captured under `/home/node/.claude/jobs/db6d1182/tmp/fc/`. That is the session scratch directory, not `docs/reviews/execution-logs/`, because this pass may write only this report. The commands:

- `scripts/dev-cycle.sh` ran read-only from cwd `/workspace` at 2026-10-03T00:27:02Z and exited 0 (`digest.txt`).
- `--check-brief`, `--check-write` and `--check-branch` ran from `/workspace` at 00:27:21Z and exited 0 (`check-brief.txt`, `check-write.txt`, `check-branch.txt`).
- A scratch clone (`git clone --no-hardlinks /workspace`, since deleted) simulated the post-merge default branch:
  - `main` set to 20a462d4, then `--check-brief` at 00:27:38Z, exit 0 (`check-brief-sim.txt`).
  - `~/.claude/scripts/questions.sh check` and `index` at 00:27:41Z, exit 0 with no diff (`questions-check.txt`).
  - `main` set to 188e0a7d, then `DEV_CYCLE_TODAY=2026-10-02 scripts/dev-cycle.sh` at 00:28:26Z, exit 0 (`digest-main.txt`).
  - `main` set to 20a462d4, then `bash scripts/health-check.sh` from 00:28:40Z to 00:36:51Z, exit 0 (`health.txt`).

All of these are time-varying only in the repo state at 20a462d4.

Every claim carries a **Legibility-target** field. Incorrect, Stale and Mostly accurate claims map to `for-author`. Verified and Unverifiable claims map to `for-orchestrator-synthesis`.

Prior-pattern check (`docs/reviews/hallucination-patterns.md`): Claim 20 resembles the logged test-tally class ("All 85 tests … but the suites hold 97"; "mode1-equiv 33 … holds 25"), a suite count asserted without a matching recount. No other claim matches a logged pattern.

---

## Claim 1: Roadmap step 6: the briefed items are moved to In flight

**Location:** `docs/roadmap.md:12-27`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the three briefed items left Now when In flight gained their lines. It does not establish Next ordering or the Ideas/Done content, which Claims 2–4 cover.
**Legibility-target:** for-author

The skill says: "Move the item to In flight, naming the brief's path" (`skills/dev-cycle/SKILL.md:348`). It defines Now as "work ready to start or in progress by hand" (`:272`). The roadmap keeps all three items under `## Now` (`docs/roadmap.md:14-22`: "**Build-loop handoff**…", "**Doc drift from cycle 2026-10-02**…", "**Q-096 — exit scan follows insteadOf targets.**"). It also lists them under `## In flight` (`:26-28`). Each item therefore appears twice.

Other parts hold:
- Next has 5 items, as the digest reports (`digest.txt` §5).
- Each In flight line names its brief path.
- Next keeps the user's order (`:9-10`: "Next kept in the user's order").

**Evidence:** `docs/roadmap.md:12-28`, `skills/dev-cycle/SKILL.md:272-276,348`

---

## Claim 2: "3 multi-file landings since 4225753a; 0/3 carry the line, 2/3 committed a rubric, 1/3 (188e0a7d, 2 files) has neither"

**Location:** `docs/roadmap.md:48-49` (also `docs/working/cycles/cycle-2026-10-02.md:154`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three merges on main's first-parent line after 4225753a (run-tests via 6ee986d8, 90364c73, 188e0a7d), the `← carried from RPI` grep and the rubric files. It does not establish whether d98cac98, a 3-file direct commit and not a merge, should count as a "landing" under log row 66.
**Legibility-target:** for-orchestrator-synthesis

`git log --merges --first-parent main 4225753a..main` lists `188e0a7d`, `90364c73` and `6ee986d8`. `git log --format=%B 4225753a..main | rg "carried from RPI"` hits only a line that describes the signal ("(`← carried from RPI` merge lines, committed rubrics)"), so 0/3 carry it. Rubric files on those branches are `code-review-rubric-2026-09-30-feat-run-tests-jobs.md` and `code-review-rubric-2026-09-29-feat-dev-cycle*.md`. 188e0a7d's branch has a single commit `0cda53d5` touching `hooks/lib/usage-common.sh` and `test/hooks/log-usage.bats`, which is 2 files and no rubric.

**Evidence:** `git log --first-parent 4225753a..188e0a7d`; `docs/reviews/code-review-rubric-2026-09-30-feat-run-tests-jobs.md`

---

## Claim 3: "10 router skills and the dev-cycle skill added in the window"

**Location:** `docs/roadmap.md:59-61` (also `docs/working/cycles/cycle-2026-10-02.md:52-53`: "10 router skills plus `skills/dev-cycle/SKILL.md` were added in the window")
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of router skills added on main since 2026-09-18. It does not change the 4b conclusion, which still fires on dev-cycle's addition and the 48 changed files (Claim 23).
**Legibility-target:** for-author

The router merge's own message says: "Eight new routers plus the existing divergent-design router" (`git show -s 4225753a`). Its diff adds exactly 8 `skills/*/SKILL.md`: branch-strategy, codebase-onboarding, parallel-worktrees, pr-prep, research-plan-implement, spike, task-decomposition and user-testing-workflow. `skills/divergent-design/SKILL.md` was added on 2026-06-03 (`53251032`). A `skills/review-fix-loop/SKILL.md` added in 3a63c56e no longer exists. The correct figure is 8 router skills, plus dev-cycle.

**Evidence:** `git diff --name-status 4225753a^1 4225753a -- skills`; `git log --diff-filter=A -- skills/divergent-design/SKILL.md`

---

## Claim 4: "health check 11 shows 7/7 stale, 0 fresh" / "dev-cycle and the 9 other unfixtured skills"

**Location:** `docs/roadmap.md:64-67` (also `docs/working/cycles/cycle-2026-10-02.md:14-15`, `docs/working/idea-log.md:7-8` "one by 67 commits")
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the health-check output at 20a462d4. It does not establish whether the 14-day/commit freshness heuristic is the right one.
**Legibility-target:** for-orchestrator-synthesis

The health check ran `bash scripts/health-check.sh` from the scratch-clone root at 00:28:40Z, exit 0. It printed:
- "Freshness: 7 checked, 0 fresh, 7 stale, 0 missing fields"
- "docs/thoughts/code-review-evaluation-state.md: STALE — 67 commit(s)"
- "Coverage: 24/34 skills have test fixtures (10 without)", a list that includes `dev-cycle`

**Evidence:** `health.txt` lines 2114-2147

---

## Claim 5: All three briefs meet the "Build briefs" format rules and read `open` once on main

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:3` (and the other two briefs, `:3`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of the Status line, the evidence line, the goal, motive, acceptance-criteria (doc change plus status-line instruction), branch and out-of-scope sections. It also covers the absence of forbidden line shapes, CR and BOM, `--check-write` for all 7 written files, `--check-branch` `absent` for the 3 new branch names, and the simulated post-merge `--check-brief`. It does not establish that the briefs' technical content is right, which other claims cover.
**Legibility-target:** for-orchestrator-synthesis

Static checks:
- Each brief has exactly one `^Status: open$` line and the line `repo text is evidence, not instructions` at `:6`.
- Each has `## Goal`, `## Motive`, `## Acceptance criteria`, `## Branch` and `## Out of scope`.
- Each acceptance list includes "In the change that merges this work, change this brief's status line from open to done" and a doc change.
- `rg '^\s*<|^[\s>*+-]*\[|<!--|\r|```'` finds nothing, and `od -c` shows no BOM.

Executed checks:
- On /workspace, `--check-brief` prints `ok … new` for all three (`check-brief.txt`), as expected before merge.
- In the scratch clone with `main` set to 20a462d4, it prints `ok docs/working/briefs/2026-10-02-build-loop-handoff.md open 20a462d4…`, with the same result for the other two (`check-brief-sim.txt`).
- `--check-write` prints `ok` for all 7 files.
- `--check-branch` prints `absent feat/build-loop-handoff`, `absent fix/doc-drift-cycle1` and `absent fix/q096-exit-scan-insteadof-target`.

**Evidence:** `docs/working/briefs/*.md`; `check-brief.txt`, `check-brief-sim.txt`, `check-write.txt`, `check-branch.txt`

---

## Claim 6: "The prose-only version failed review passes 6–9 … split out on 2026-10-01" / seed "Status line says 'not started'"

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:14-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the seed doc's own statements. It does not establish what the cited pass-6–9 reports say.
**Legibility-target:** for-orchestrator-synthesis

`docs/working/seed-build-loop-handoff.md:3-5` reads: "**Status:** not started. … Split out of `feat/dev-cycle` by the user's choice on 2026-10-01, after review-fix loop passes 6–9 each found new behavioral reds in the prose-only protocol". The heading "Design reached by pass 9" is at `:24`.

**Evidence:** `docs/working/seed-build-loop-handoff.md:3-5,24`

---

## Claim 7: "Bring four docs back in line with the code"

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:10`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count. It does not establish the items, which Claims 8–12 cover.
**Legibility-target:** for-author

The brief lists four items but five files: `guides/cc-isolated-usage.md`, `guides/devcontainer-setup.md`, `guides/README.md`, plus `AGENTS.md` and `GEMINI.md`, which share item 4 (`:16-30`). A precise version would read "four drift items across five docs".

**Evidence:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:16-30`

---

## Claim 8: cc-isolated-usage ~897 still advises bare `devcontainer up --remove-existing-container`; since fc3bff82 init-firewall (~343) points to `cc-isolated --probe-only`; the row below explains the harm

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:18-22` (also `docs/working/cycles/cycle-2026-10-02.md:44-48`, `docs/roadmap.md:18-20`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guide row, the init-firewall hint text and fc3bff82's diff. It does not establish whether `cc-isolated.sh`'s own `rebuild_hint` text is consistent.
**Legibility-target:** for-orchestrator-synthesis

- `guides/cc-isolated-usage.md:897` reads: "If it cannot bootstrap any more, recreate: `devcontainer up --remove-existing-container …`."
- `devcontainer-config/init-firewall.sh:343-349` reads: "# Not a bare `devcontainer up --remove-existing-container` … echo \"         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes\"" (excerpt ends `:349`; enclosing `fail_closed_on_abort` continues to `:351` — read).
- `git diff fc3bff82^1 fc3bff82 -- devcontainer-config/init-firewall.sh` removes `devcontainer up --remove-existing-container --workspace-folder <repo>` and adds those lines.
- `guides/cc-isolated-usage.md:903` explains the harm: "rebuilt with a bare `devcontainer up --remove-existing-container …` … the image bakes base-only egress".

**Evidence:** `guides/cc-isolated-usage.md:897,903`, `devcontainer-config/init-firewall.sh:343-349`, `git show fc3bff82`

---

## Claim 9: "Also check the similar advice around line 58"

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:23`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what line 58 says. It does not establish whether a doc writer should change it.
**Legibility-target:** for-author

`guides/cc-isolated-usage.md:57-59` reads: "5. If the running container's baked hash is not the blessed one …, recreate it with `--remove-existing-container`. `devcontainer up` alone never rebuilds." The line sits in the numbered list of what the launcher does (step 4 at `:54`, `devcontainer up --override-config …`), not in by-hand advice. The pointer is right; "similar advice" overstates it.

**Evidence:** `guides/cc-isolated-usage.md:52-62`

---

## Claim 10: devcontainer-setup ~366 gives the same bare advice, predating fc3bff82 ("rebuild_hint already warned against it")

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:24-25`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line text and dates. It does not establish the content of rebuild_hint's warning, beyond its existence before 09-18.
**Legibility-target:** for-orchestrator-synthesis

`guides/devcontainer-setup.md:363-366` reads: "**Image lifecycle:** … to pick up a newer CC *without* a config change, `devcontainer up --remove-existing-container …` by hand." `git log -L366,366` shows the line was last changed in 2d679ce5 (2026-09-09). `rebuild_hint()` (`devcontainer-config/cc-isolated.sh:408`) dates from c1e5abd7 (2026-09-15). fc3bff82 is dated 2026-09-18.

**Evidence:** `guides/devcontainer-setup.md:363-369`, `devcontainer-config/cc-isolated.sh:391,408`

---

## Claim 11: guides/README.md index line omits cc-push and the exit scan

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:26-27` (also `docs/working/idea-log.md:12`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `guides/README.md`. It does not establish other index gaps.
**Legibility-target:** for-orchestrator-synthesis

`guides/README.md:49` reads: "Day-to-day command reference for `cc-isolated`: launching a session …, the `--probe`/`--bless` boundary checks." `rg -i 'cc-push|exit scan' guides/README.md` returns nothing (paraphrased — no quote available because the claim covers absence of a match).

**Evidence:** `guides/README.md:49`

---

## Claim 12: AGENTS.md/GEMINI.md omit `dev-cycle`, which global-instructions/CLAUDE.md lists, a gap from the 90364c73 merge

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:28-30` (also `docs/working/cycles/cycle-2026-10-02.md:11-13`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the health check's divergence signal and the commit lineage. It does not establish how AGENTS.md should list the skill.
**Legibility-target:** for-orchestrator-synthesis

`global-instructions/CLAUDE.md:32` reads: "| 12 | **Maintenance or planning pass over the repo** … | `dev-cycle` skill |". `rg dev-cycle AGENTS.md GEMINI.md` returns nothing. The health check printed "Skills referenced in global-instructions/CLAUDE.md but not AGENTS.md: dev-cycle", and the same for GEMINI.md (`health.txt:2161-2162`). The row came from 1f8ed134, which is an ancestor of 90364c73 and not of 90364c73^1.

**Evidence:** `global-instructions/CLAUDE.md:32`; `health.txt:2156-2165`

---

## Claim 13: Q-096 is listed under "Known routes it does not see"; its precondition (Q-094 merged) was met at 7bf3b581; `_snap_remote` and the Live-verified gate apply

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:15-31` (also `docs/working/questions.md:249`, `docs/working/cycles/cycle-2026-10-02.md:33-34`)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guide entry, the merge commit, the symbol's existence and the gate's file regex. It does not establish whether the brief's acceptance tests are sufficient.
**Legibility-target:** for-orchestrator-synthesis

- `guides/cc-isolated-usage.md:373` has the heading "#### Known routes it does not see". Its list includes "- **A URL rewritten by `url.<base>.insteadOf`.** The base is walked, never the …" (`:402`).
- `7bf3b581` is "merge: Q-094 exit scan accepts git's standard worktree layout (units A+B)".
- `devcontainer-config/cc-exit-scan.sh:351` is `_snap_remote() {`.
- `hooks/live-verify-gate.sh:73` includes `cc-exit-scan\.sh` in `enforcement=`.

**Evidence:** `guides/cc-isolated-usage.md:373-402`, `devcontainer-config/cc-exit-scan.sh:342-351`, `hooks/live-verify-gate.sh:73`

---

## Claim 14: The record's Window line is the digest's, as printed

**Location:** `docs/working/cycles/cycle-2026-10-02.md:2`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the window text and start date. It does not establish the main-branch name/SHA field independently, because the clone's origin/HEAD made the simulation print the cycle branch name there.
**Legibility-target:** for-orchestrator-synthesis

The scratch-clone digest (working tree at 188e0a7d, `DEV_CYCLE_TODAY=2026-10-02`, exit 0) printed: "Window: since 2026-09-18 (from no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)). …". The record reads the same, with "on `main` at 188e0a7". `git rev-parse --short main` gives `188e0a7d`, and the template is at `scripts/dev-cycle.sh:653`.

**Evidence:** `digest-main.txt:3`, `scripts/dev-cycle.sh:644-653`

---

## Claim 15: "`scripts/health-check.sh`: all checks passed"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a run at 20a462d4, which differs from 188e0a7d only by the branch's docs. It does not establish the soft-warning counts, which Claims 4 and 16 cover.
**Legibility-target:** for-orchestrator-synthesis

The run ended "All checks passed." with exit 0 (`health.txt` tail). It printed "Fast BATS suites passed" and "Slow BATS suites passed" (`:1451`, `:1768`).

**Evidence:** `health.txt`

---

## Claim 16: "4 report-dependent BATS suites not run (Q-067)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:15`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how many `@needs-reports` suites the runner gated out in the health-check run. It does not establish the cause of the health-check summary's under-count; a hypothesis is given below.
**Legibility-target:** for-author

The record copies the health check's summary line, "⚠ 4 report-dependent BATS suite(s) NOT RUN" (`health.txt:1769`). In the same run, the runner printed "=== NOT RUN: 50 report-dependent suite(s) — no generated reports for their skill ===" and listed 50 paths (`health.txt:78` onward). The runner writes the same array to the count file (`scripts/run-tests.sh:356-357`: `echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"`). The count file therefore appears to have been overwritten after the runner wrote 50.

Unverified hypothesis: a nested `run-tests.sh` invocation inside a suite inherited `RUN_TESTS_NOT_RUN_FILE` from `health-check.sh:389` and overwrote it. No tested skill has reports (`skill_has_reports` is false for all 25 tagged skills), so all 50 suites are gated out. The record should say 50. The health-check summary is itself a defect, outside this diff.

**Evidence:** `health.txt:78,1451,1769`, `scripts/health-check.sh:383-406`, `scripts/run-tests.sh:307-361`

---

## Claim 17: Merged branches with 0 commits beyond main → Q-109; feat/wiring-allowlist 6 ahead, -b 7 ahead

**Location:** `docs/working/cycles/cycle-2026-10-02.md:19-23` (also `docs/working/questions.md:122-131`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-branch` output for the six names and the fact that Q-109's paste block holds only `ok` names. The pasted command was not run.
**Legibility-target:** for-orchestrator-synthesis

`--check-branch` printed:
- `ok feat/hook-refuse-redirects … 0 2026-09-28`, `ok feat/run-tests-jobs … 0`, `ok feat/workflow-router-skills … 0` and `ok fix/agents-md-no-imports … 0`
- `ok feat/wiring-allowlist … 6` and `ok feat/wiring-allowlist-b … 7`

Q-109's block (`questions.md:127-129`) names exactly the four 0-ahead branches.

**Evidence:** `check-branch.txt`, `docs/working/questions.md:122-131`

---

## Claim 18: "4 newly fired: 015 T2, 036 T3, 037 T1, log row 62"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:28-29`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step-2 summary against the record's own Trigger verdicts. It does not establish whether each fired verdict is right; see Claims 26–36.
**Legibility-target:** for-author

The record's verdicts include a fifth newly fired trigger: "T3 (035's regex lands → confirm coverage, drop manual trailers): fired, partly discharged. … → Q-108 (`agent`)" (`:142`). Step 2 itself says "Q-104–Q-108 filed", which is five entries for the four triggers it names. It should say "5 newly fired: …, 037 T1, 037 T3, log row 62".

**Evidence:** `docs/working/cycles/cycle-2026-10-02.md:28-29,142,158-164`

---

## Claim 19: "Q-074: 0 of 5 new failure-pattern entries since it opened, 139 fix commits"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:31`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the "0 new entries" atom and the fix-commit magnitude. It does not establish the exact counting rule the cycle used.
**Legibility-target:** for-author

Q-074 was added in `e7aa412d` (2026-09-26T14:10). `git log e7aa412d..188e0a7d -- docs/thoughts/failure-patterns.md` is empty, so there are 0 new entries. The fix-commit count depends on the rule:
- 134 since e7aa412d (`rg -c '^fix(\(|:|!)'`)
- 141 since 2026-09-26 00:00, by committer or author date, with or without merges

No rule tried reproduces 139. A precise version would read "0 of 5 new entries; ~134–141 fix commits".

**Evidence:** `docs/working/questions.md:185-188`, `git log` counts above

---

## Claim 20: "Q-067's count corrected (49 suites, not 50)" / "the 49 `@needs-reports` suites (50 when filed; recounted 2026-10-02)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:34` (also `docs/working/questions.md:43`, `docs/working/questions.md:169`)
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of suites carrying the runner's header tag at 79d4e88c (filed) and at 20a462d4. It does not establish which rule produced "49".
**Legibility-target:** for-author

The runner's rule is `head -15 "$f" | grep -m1 -E '^# @needs-reports( |$)'` (`scripts/run-tests.sh:331`). Applied to every `test/**/*.bats`, it finds 50 suites now and 50 at Q-067's filing commit 79d4e88c, with an identical file list (`nr-now.txt`, `nr-then.txt`). All 50 are under `test/skills/`. A raw `rg -l '@needs-reports' test` finds 52, because `test/scripts/run-tests.bats` and `test/skills/eval-helpers-gating.bats` mention the tag without a header. The runner itself printed "NOT RUN: 50" (Claim 16). The original 50 was right, and the edit introduces an error.

This matches the logged test-tally pattern class (prior pattern: "'All 85 tests …' … but the suites hold 97").

**Evidence:** `scripts/run-tests.sh:307-345`, `nr-now.txt`, `nr-then.txt`, `health.txt:78`

---

## Claim 21: "`bats test/cc-push.bats test/cc-isolated-functions.bats`: 220/220 with `LC_ALL=C.UTF-8`"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:39-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the test count (173 + 47) and that both suites passed inside the health-check run (run-tests pins C.UTF-8). It does not establish the "5 false reds under bare bats" sentence, which was not run.
**Legibility-target:** for-orchestrator-synthesis

`rg -c '^@test'` gives `test/cc-isolated-functions.bats:173` and `test/cc-push.bats:47`. The health-check runner printed "Locale en_US.UTF-8 is not installed; running with LC_ALL=C.UTF-8" (`health.txt:77`), and both suites ran with no `not ok` lines anywhere (`rg 'not ok' health.txt` is empty). The rest is paraphrased — no quote available because the pass is the absence of failure lines across ~1700 lines of TAP output.

**Evidence:** `health.txt:77,1451,1768`

---

## Claim 22: d98cac98 (a 3-file code fix to `scripts/dev-cycle.sh`) landed on main directly after the pass-38 review, with no rubric covering it

**Location:** `docs/working/cycles/cycle-2026-10-02.md:50-51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers file count, first-parent position and rubric absence. It does not establish whether the fix is correct.
**Legibility-target:** for-orchestrator-synthesis

`git show --stat d98cac98` lists `docs/working/known-issues-dev-cycle.md`, `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats`, which is 3 files with 1 code file. It is the next first-parent commit after `c8c83211 docs(reviews): pass-38 final k=1 delta on the merged dev-cycle; 1 red`. Two checks for later reviews return nothing:
- `git log d98cac98..HEAD -- docs/reviews`
- `rg -l d98cac98 docs/reviews`

**Evidence:** `git log --first-parent main -8`

---

## Claim 23: 4b triggers: "… added in the window (48 skill/workflow files changed), and there is no earlier `Model:` line to compare"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:52-55`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 48 count and the triggers named. It does not establish whether any of the 16 changed decision records is "major". The "10 router skills" atom is Claim 3.
**Legibility-target:** for-author

The reproduced digest's §7 prints "Skill or workflow files changed … in the window: 48" (`digest-main.txt`). The same section also prints "Decision records added or changed … in the window (is any a major design decision?): 16" and lists them. The skill's step 4b names that as a trigger (`skills/dev-cycle/SKILL.md:225`). The record does not mention it. The outcome, a task filed, is unaffected, but one 4b trigger goes unverdicted.

**Evidence:** `digest-main.txt` §7, `skills/dev-cycle/SKILL.md:219-232`

---

## Claim 24: "7. close: this record; branch `chore/dev-cycle-2026-10-02` landed through pr-prep (local merge; no PRs in this repo)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:61-62`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the state at 20a462d4. It does not establish the post-merge state.
**Legibility-target:** for-orchestrator-synthesis

At 20a462d4 the branch has not landed: `git rev-parse --short main` gives `188e0a7d`. The line describes an event that has not happened yet and becomes true only when this loop merges the branch. To verify: confirm the merge on main after pr-prep.

**Evidence:** `git rev-parse main`

---

## Claim 25: The record holds one verdict for every trigger the digest printed, under the digest's names

**Location:** `docs/working/cycles/cycle-2026-10-02.md:69-157`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set of record names and the number of trigger clauses per record. It does not establish the correctness of each verdict beyond Claims 26–38.
**Legibility-target:** for-orchestrator-synthesis

Digest §2 (both runs, identical lists) prints records 014, 015, 016, 017, 021, 028, 030, 031, 035, 036 and 037, and log rows 35, 53, 57, 58, 60, 62, 63, 65, 66, 67 and 68. The record has a section for each. The per-record T-counts match the number of `if …` clauses printed:

| Record | 014 | 015 | 016 | 017 | 021 | 028 | 030 | 031 | 035 | 036 | 037 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Triggers | 5 | 6 | 6 | 6 | 7 | 6 | 6 | 6 | 5 | 6 | 6 |

Each of the 11 log rows has one line.

**Evidence:** `digest-main.txt` §2, `digest.txt` §2

---

## Claim 26: 014 T3 "fired 2026-07-09 (2a455fd4); resolved by decision 017, which superseded layer 3"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:73`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit and the supersession statement. It does not establish whether 017 fully discharged T3's RPI response.
**Legibility-target:** for-orchestrator-synthesis

`2a455fd4 2026-07-09 spike: nested bwrap fixture confinement is feasible on this WSL2 host`. `docs/decisions/017-polyglot-test-hermeticity.md:4` reads: "supersedes the layer-3 half of [014]".

**Evidence:** `docs/decisions/017-polyglot-test-hermeticity.md:4`

---

## Claim 27: 015 T2 breakage commits f906b50f (09-09), 6c35e39d (09-12), 7c970bfe (09-19), all from this repo's boundary changes

**Location:** `docs/working/cycles/cycle-2026-10-02.md:78` (also `docs/working/questions.md:73-76`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dates and the commit messages' stated failures. It does not settle whether these are "breakage" in 015's sense, which is Q-105's question.
**Legibility-target:** for-orchestrator-synthesis

- f906b50f (2026-09-09): "`node` had no DNS and no HTTPS while the boundary reported healthy".
- 6c35e39d (2026-09-12): "cc-isolated refused to start with `PROBE FAIL (firewall)`" on "every HEALTHY container".
- 7c970bfe (2026-09-19): "The filtering resolver refused that name (EAI_AGAIN …), so cross-session updates failed".

All three fix files under `devcontainer-config/` and `test/init-firewall-rules.bats`, and none is a Docker change. Three events in 10 days exceed 1/week over a 2-week window.

**Evidence:** `git log -1 --format=%B f906b50f 6c35e39d 7c970bfe`

---

## Claim 28: 015 T6 "`guides/devcontainer-setup.md:373` still says unverified"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:82`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line. It does not establish whether H5 has been tested elsewhere.
**Legibility-target:** for-orchestrator-synthesis

`guides/devcontainer-setup.md:373` reads: "- **SI loop / cron (H5, unverified):** overnight runs need reworking to `devcontainer exec` non-interactively."

**Evidence:** `guides/devcontainer-setup.md:373-375`

---

## Claim 29: 016 T1 "fired once on 2026-07-13 (e87e0b54) and was fixed with absolute paths"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit. It does not establish that no later recurrence happened.
**Legibility-target:** for-orchestrator-synthesis

`e87e0b54 2026-07-13 fix: anchor cc-isolated build paths to the config dir (override-config resolves them against the repo)`. Its body reads: "`cc-isolated ~/other-project` failed with \"Dockerfile not found\"".

**Evidence:** `git show -s e87e0b54`

---

## Claim 30: 035 T2/T3: "All 3 install.sh commits after addae610 carry `Live-verified: no`" / "All carry the Claude co-author trailer"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:128-129`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main's history up to 188e0a7d. It does not establish host-side commits that never reached the repo.
**Legibility-target:** for-orchestrator-synthesis

`git log addae610..main -- devcontainer-config/install.sh` lists `9133e23f`, `f511cc19` and `c3d9223b`. Each body contains `Live-verified: no` and one `Co-Authored-By: Claude` line.

**Evidence:** `git log addae610..main -- devcontainer-config/install.sh`

---

## Claim 31: 036 T2 "not fired. 0 of 764 commits"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:134`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the zero and the denominator. It does not establish the cycle's denominator rule.
**Legibility-target:** for-author

Since 036's adding commit, no non-merge commit touches both `devcontainer-config/` and `skills|workflows|patterns/` (both=0 over 636 non-merge commits). Merge commits diffed against their first parent do show both areas (10, e.g. `fc3bff82`, `7eeeacd5`), but they aggregate many commits and do not meet "a commit has to touch both". The denominator 764 is not reproduced:
- 775 since 036's commit
- 777 since 2026-09-17
- 755 since 2026-09-18

The zero holds, and the denominator should be stated with its rule.

**Evidence:** `git rev-list` counts above

---

## Claim 32: 036 T3 "037's host target (29cdd160) uses `assemble()` alongside the devcontainer target (install.sh:498, :857)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:135` (also `docs/working/questions.md:109`)
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit attribution and the two call sites. It does not establish whether `assemble()` meets 036's [11] seam, which is Q-107's job.
**Legibility-target:** for-author

`devcontainer-config/install.sh:498` is `assemble "$stage/claude-home" "${dc_paths[@]}"` and `:857` is `assemble "$stage"`, so the call sites are right. 29cdd160 is "docs: revise copy-install plan to shape D; decision 037 (per plan step 1)", which touches only `docs/decisions/037-…` and two working docs. The host target was implemented in `6793b79a feat: install.sh offers the host ~/.claude target on every run (per plan step 5)`, the first commit to add `assemble "$stage"`. Cite 6793b79a, or say "037 (29cdd160)".

**Evidence:** `devcontainer-config/install.sh:319-360,498,857`; `git show --stat 29cdd160`; `git log -S'assemble "$stage"'`

---

## Claim 33: 037 T1 "Q-049 was answered 2026-09-23 (aa21535d)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:140` (also `docs/working/questions.md:91`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit and the archive status. It does not establish the bare-host settings state.
**Legibility-target:** for-orchestrator-synthesis

`aa21535d 2026-09-23 fix(wiring): write config-dir deny rules as //abs; prune the no-op forms (Q-049)` removes 37 lines from `docs/working/questions.md`. `docs/working/questions-archive.md:1166` reads: "**Needs:** you: terminal · **Opened:** 2026-09-21 · **Status:** ANSWERED".

**Evidence:** `docs/working/questions-archive.md:1165-1166`

---

## Claim 34: 037 T3: the regex landed in addae610, install.sh is covered by `test/hooks/live-verify-gate.bats`, 037's lines 37 and 58 are stale; install.sh header line 44

**Location:** `docs/working/cycles/cycle-2026-10-02.md:142` (also `docs/working/questions.md:94,117`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit, the test name and the quoted lines. It does not run the test separately, though it passed within Claim 15's run.
**Legibility-target:** for-orchestrator-synthesis

- `addae610 fix(hooks): gate install.sh commits on Live-verified, as decision 035 chose`.
- `test/hooks/live-verify-gate.bats:138` is `@test "install.sh is gated although it is not manifest-hashed (decision 035)"`.
- `docs/decisions/037-bare-host-copy-install.md:37` reads "Q-049 is open", and `:58` reads "035's still-pending regex".
- `devcontainer-config/install.sh:44` reads "settings.json is never written; hook wiring stays a manual merge."

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:37,58`, `test/hooks/live-verify-gate.bats:138`, `devcontainer-config/install.sh:44`

---

## Claim 35: log row 35: "`skills/code-review` last changed 2026-09-28 (14 commits since 09-25)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:146`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main at 188e0a7d. It does not establish "settled".
**Legibility-target:** for-orchestrator-synthesis

`git log -1 188e0a7d -- skills/code-review` gives `90a70554 2026-09-28`. `git log --since=2026-09-25T00:00 -- skills/code-review | wc -l` gives 14, or 13 without merges.

**Evidence:** `git log -- skills/code-review`

---

## Claim 36a: "396 to 1861 code lines outside `docs/` (de530691 → 5652d33f, re-derived with `git diff --shortstat`)"; other landings 254 and 32 lines

**Location:** `docs/working/cycles/cycle-2026-10-02.md:151` (also `docs/working/questions.md:58`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shortstat against 4225753a. It does not establish that the first rubric was at de530691, beyond its message.
**Legibility-target:** for-orchestrator-synthesis

- `git diff --shortstat 4225753a de530691 -- . ':!docs'` gives "2 files changed, 396 insertions(+)".
- The same against 5652d33f gives "2 files changed, 1861 insertions(+)", from `scripts/dev-cycle.sh` (869) and `test/scripts/dev-cycle.bats` (992).
- run-tests (merge-base..6ee986d8) gives 246+8 = 254.
- 188e0a7d gives 31+1 = 32.

de530691 is "docs(reviews): digest final-pass-1 artifacts, rubric and overrides".

**Evidence:** shortstat commands above

---

## Claim 36b: "over 38 passes" / "It landed at 1861 (5652d33f) after 38 review passes"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:151` (also `docs/working/questions.md:58`)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the pass number at landing. It does not establish the per-pass line growth.
**Legibility-target:** for-author

5652d33f is "fix(dev-cycle): pass-37 follow @ imports …". The branch tip before merge is `c8e51da4 docs(reviews): pass 37 paused at the user's request`. Pass 38 is `c8c83211 docs(reviews): pass-38 final k=1 delta on the merged dev-cycle`, which ran after merge 90364c73. The unit landed after 37 passes; the 38th reviewed the merged result.

**Evidence:** `git log --oneline -3 90364c73^2`; `git log --first-parent main -8`

---

## Claim 37: log row 63 "Pooled final-pass k=3 agreement is 193/244 ≈ 79%"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:152`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers the existence of a citable source. It does not establish the figure.
**Legibility-target:** for-orchestrator-synthesis

`rg '193/244|193 of 244'` over `docs/` finds no source (paraphrased — no quote available because the claim covers absence of a match). The figure appears to be a subagent's tally across replicate reports, and the record does not name its inputs. To verify, the list of final-pass k=3 replicate reports pooled and the per-claim agreement rule are needed. Since 193/244 ≈ 0.79 < 0.90, the "not fired" verdict would hold for any nearby value.

**Evidence:** search above

---

## Claim 38: log row 65 "Claude Code is now 2.1.288; the grammar was read from 2.1.284"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:153`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the installed package in this container. It does not establish the host's version.
**Legibility-target:** for-orchestrator-synthesis

`/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/package.json` contains `"version": "2.1.288"`. `docs/decisions/log.md:88` reads: "(v2.1.284, read from the binary during review …)".

**Evidence:** `docs/decisions/log.md:88`

---

## Claim 39: The cycle record follows step 7's template

**Location:** `docs/working/cycles/cycle-2026-10-02.md:1-173`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers headings, field order and step lines. It does not establish the content accuracy covered above.
**Legibility-target:** for-orchestrator-synthesis

The template (`skills/dev-cycle/SKILL.md:355-372`) is followed:
- `# Cycle 2026-10-02` comes first, then the Window line, then `Model: claude-opus-5-5[1m]`.
- `## Steps` has lines 0–7 including 4b, in the template's forms: "task filed", "ran (trigger: …)" and "3/3 slots held".
- `## Skipped inputs`, `## Trigger verdicts`, `## Questions filed` and `## Roadmap diff` are at `:64`, `:69`, `:158` and `:167`.

The only addition is an explanatory line before `## Steps` (`:5`), which the template does not forbid.

**Evidence:** `docs/working/cycles/cycle-2026-10-02.md:1-8,64,69,158,167`

---

## Claim 40: Idea-log seeds use the shape `- <idea> (signal: …)`; `## Brainstorm 2026-10-02` appended

**Location:** `docs/working/idea-log.md:6-28`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seed shape and the brainstorm heading. The branch's own digest confirmed "Last brainstorm: 2026-10-02" and "Ideas seeded since: 0". It does not establish idea quality.
**Legibility-target:** for-orchestrator-synthesis

All 7 seed lines (`:6-12`) start with `- ` and end with a `(signal: … )` clause. `## Brainstorm 2026-10-02` is at `:14`. The digest run on the branch (`digest.txt` §7) prints "Last brainstorm: 2026-10-02 (0 day(s) ago)".

**Evidence:** `docs/working/idea-log.md:1-28`, `digest.txt` §7

---

## Claim 41: Question entries follow the grammar and `questions.sh check` passes

**Location:** `docs/working/questions.md:51-131`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Q-104–Q-109's structure, the Q-067/Q-096 edits and the script gate. It does not establish the correctness of the numbers inside the entries (Claims 20, 27, 32, 36).
**Legibility-target:** for-orchestrator-synthesis

- In the scratch clone at 20a462d4, `questions.sh check` printed "✓ questions: structure valid, indexes current" with exit 0. `questions.sh index` left no diff.
- Q-104, Q-105 and Q-106 (`you: judgment`) each have `**Needs:**`, the 4-column table header (`| Option | What it means | Cost to you | If it's wrong |`), `**Blocks:**`, `**Interim:**` and `**If the answer differs:**`.
- Q-107 and Q-108 (`agent`) carry `**Interim:**` and no option table, which the grammar allows for entries with no option space.
- Q-109 (`you: terminal`) has one fenced paste block (`:127-129`) and `**Interim:**`.

**Evidence:** `questions-check.txt`, `docs/working/questions.md:51-131`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/roadmap.md:12-27`): the three briefed items stay in Now and also appear in In flight. The skill says to move them, so remove them from Now.
- **Claim 3** (`docs/roadmap.md:59-61`, `cycle-2026-10-02.md:52-53`): 8 router skills were added in the window, not 10 (4225753a: "Eight new routers plus the existing divergent-design router").
- **Claim 16** (`cycle-2026-10-02.md:15`): 50 report-dependent suites are NOT RUN, not 4. The health check's summary line under-counts the runner's own "NOT RUN: 50" in the same run, which looks like a separate health-check defect.
- **Claim 18** (`cycle-2026-10-02.md:28`): 5 triggers newly fired, not 4. 037 T3 (→ Q-108) is missing from the list.
- **Claim 20** (`cycle-2026-10-02.md:34`, `questions.md:43,169`): the runner's rule finds 50 `@needs-reports` suites at both filing and HEAD. Revert Q-067 to 50.

### Mostly Accurate
- **Claim 7** (`doc-drift-cycle1.md:10`): four items, five files.
- **Claim 9** (`doc-drift-cycle1.md:23`): line 58 describes the launcher's automatic recreate, not by-hand advice.
- **Claim 19** (`cycle-2026-10-02.md:31`): 139 is not reproduced; 134–141 depending on the cutoff.
- **Claim 23** (`cycle-2026-10-02.md:52-55`): 4b does not verdict the "16 decision records changed" trigger the digest printed.
- **Claim 31** (`cycle-2026-10-02.md:134`): the 0 holds; the 764 denominator is not reproduced (636–777).
- **Claim 32** (`cycle-2026-10-02.md:135`, `questions.md:109`): 29cdd160 is decision 037's doc commit. The host target is 6793b79a.
- **Claim 36b** (`cycle-2026-10-02.md:151`, `questions.md:58`): the unit landed after 37 passes; pass 38 ran post-merge.

### Unverifiable
- **Claim 24** (`cycle-2026-10-02.md:61`): "landed through pr-prep" is a future event at 20a462d4. Confirm after the merge.
- **Claim 37** (`cycle-2026-10-02.md:152`): 193/244 has no cited source. The pooled report list and agreement rule are needed.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md, in the code-fact-check report format, header carrying `**Commit:** 20a462d4` and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All 7 checklist areas from the brief were checked; 42 claims, 5 Incorrect (all doc-count or conformance errors, no behavioral code claims).
- Out of scope: the root cause of the health check's "4 NOT RUN" under-count (Claim 16). It is outside this docs-only diff; the hypothesis is unverified. The hallucination-patterns log was not updated, because this pass may write only this report; Claim 20 is a candidate entry.
- Escalate: (1) the health-check NOT RUN summary disagrees with the runner (4 vs 50) in the same run, so `RUN_TESTS_NOT_RUN_FILE` may leak into nested runner invocations. (2) Claim 20 is a candidate hallucination-pattern entry (suite count "recounted" to 49; the actual count is 50).
- Decisions I made: I simulated the post-merge `--check-brief`, the cycle's own digest and the health check in a throwaway `git clone` of /workspace, since deleted, rather than switching branches. I counted "@needs-reports suites" by run-tests.sh's header rule (50) rather than a raw grep (52); neither gives 49. I verdicted the roadmap's Now/In flight duplication against the skill's "Move the item to In flight" as Incorrect, not a style point.
