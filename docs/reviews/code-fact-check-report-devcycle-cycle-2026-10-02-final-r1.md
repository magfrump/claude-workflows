Commit: daf5bd82

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** full branch, `git diff main...HEAD` on chore/dev-cycle-2026-10-02 at daf5bd82 (docs only, 12 files: docs/roadmap.md, docs/working/{cycles/cycle-2026-10-02.md, questions.md, idea-log.md}, the 3 briefs under docs/working/briefs/, and the 5 review artifacts under docs/reviews/). Final confirming pass, replicate r1 of k=3.
**Checked:** 2026-10-02
**Total claims checked:** 36
**Summary:** 35 verified, 0 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable
**Replication:** k=3 final confirming pass; this is r1.

Execution logs live in the job scratch directory `/home/node/.claude/jobs/db6d1182/tmp/cfc-r1-LKRk/` (abbreviated `$S` below), not in `docs/reviews/execution-logs/`. This pass was allowed to write only this report. All commands ran with cwd `/workspace` unless noted. `docs/reviews/hallucination-patterns.md` was read. No claim matches a logged pattern.

---

## Claim 1: Rubric Iterations rows 1–3 tallies ("5 Incorrect (doc-class), 7 Mostly accurate, 2 Unverifiable; security 2 Medium + 1 Info" / "1 Incorrect … 3 Mostly accurate" / "Clean: 0 Incorrect, 0 Stale; 1 Mostly accurate")

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:12-14`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each pass row's counts, commits and escalation list against the cited reports' headers, attention lists and goal-alignment notes. It does not re-verify those reports' per-claim content.
**Legibility-target:** for-orchestrator-synthesis

The pass-1 report header reads `**Commit:** 20a462d4` and `**Summary:** 28 verified, 7 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable` (`docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md` header). Pass 2 reads `**Commit:** 4a68e29a` / `16 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable`. Pass 3 reads `**Commit:** 237fce88` / `10 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable`. The security review has `#### 1.` and `#### 2.` with `**Severity:** Medium` and `#### 3.` with `**Severity:** Informational` (`security-review-2026-10-02-devcycle-cycle.md:36-80`). The pass-2 note's Escalate line names both "Q-110's lead is confirmed by execution" and "Cross-brief tension … a loop never … writes `docs/working/questions.md`" (`…-pass2.md:351`), as row 2 says. The pass-3 MA (Claim 2b, "020's window note is an 'Amendment 2026-09-26'") was fixed: record line 57 now reads "020's amendment, 021's superseded note".

**Evidence:** `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:1-12`, `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-pass2.md:1-12`, `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-pass3.md:1-12`, `docs/reviews/security-review-2026-10-02-devcycle-cycle.md:36-80`, `docs/working/cycles/cycle-2026-10-02.md:57`

---

## Claim 2: Rubric A1–A7, C1–C10 map the cited findings and their statuses

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:21-44`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one-to-one mapping between rubric rows and the pass-1/pass-2 attention lists, and that each "✅ Fixed" row's fix is visible in the HEAD text. It does not establish the fix commit of each row beyond the text being fixed at HEAD.
**Legibility-target:** for-orchestrator-synthesis

The pass-1 attention list has Incorrect Claims 1, 3, 16, 18, 20 (A1–A5), Mostly accurate Claims 7, 9 (C1), 19, 31 (C2), 32 (C3), 36b (C4), 23 (C5), and Unverifiable 24 (C9) and 37 (C6). That accounts for all 5 + 7 + 2. Each fix is present at HEAD: the roadmap's Now reads "Nothing waiting outside a brief" (`docs/roadmap.md:14`); the record says "8 router skills" (`cycle-2026-10-02.md:52`), "50 report-dependent BATS suites not run" (`:15`), "5 newly fired" (`:28`); and Q-110's "Cause" line names the line-76 test (`questions.md:129`). C9 and C8 are marked open, which matches the state (see Claims 3 and 22).

**Evidence:** `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md` ("Claims Requiring Attention"), `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-pass2.md` ("Claims Requiring Attention"), `docs/roadmap.md:12-25`, `docs/working/cycles/cycle-2026-10-02.md:15,28,52`

---

## Claim 3: "`--check-brief` prints `open` for all three briefs in a scratch clone" (C8: check-brief only runs after landing)

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:44,48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-brief` and `--check-write` on the 7 cycle files in a local clone with `main` reset to daf5bd82 (the post-merge state). It does not establish the result on the real `main` after the actual merge.
**Legibility-target:** for-orchestrator-synthesis

Command (cwd `$S/clone`, a `git clone --no-hardlinks /workspace`, then `git checkout -B main daf5bd82`): `scripts/dev-cycle.sh --check-brief <brief>` for each brief, then `--check-write` on the record, roadmap, questions, idea log and briefs. Exit 0 each; 2026-10-03T01:04Z. Output:

```
ok docs/working/briefs/2026-10-02-build-loop-handoff.md open 20a462d4…
ok docs/working/briefs/2026-10-02-doc-drift-cycle1.md open 20a462d4…
ok docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md open 20a462d4…
ok docs/working/cycles/cycle-2026-10-02.md
… (ok for all 7 --check-write paths)
```

In /workspace itself (main not yet carrying the briefs), the same check prints `ok … new` for each (`$S/checks.out`), which is the C8 situation. The clone was deleted afterwards.

**Evidence:** `$S/clone-checks.out`, `$S/checks.out`, `$S/checks.ts`

---

## Claim 4: "The Q-109 paste block holds only names `--check-branch` printed `ok` for"

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-branch` on the four names in Q-109's block and their ahead-count against main. It does not run the block (forbidden), so `branch -d`'s refusal of unmerged branches is not re-checked.
**Legibility-target:** for-orchestrator-synthesis

`scripts/dev-cycle.sh --check-branch <b>` for each (exit 0, 2026-10-03T01:05Z) printed e.g. `ok feat/run-tests-jobs 6ee986d8… 0 2026-09-30`. All four print `ok` with count 0. `git rev-list --count main..<b>` gives 0 for all four, and 6 and 7 for `feat/wiring-allowlist` and `feat/wiring-allowlist-b`. These match the record's step 1 (`cycle-2026-10-02.md:18-21`).

**Evidence:** `docs/working/questions.md:132-140`, `docs/working/cycles/cycle-2026-10-02.md:18-21`; command output inline (paraphrased — no quote file kept because the four one-line outputs are quoted in full above in shape and count)

---

## Claim 5: Roadmap moves: briefed items out of Now into In flight; Ideas +7; Done + the dev cycle (90364c73)

**Location:** `docs/roadmap.md:12-25`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the roadmap diff against the record's "Roadmap diff" section and the skill's "Move the item to In flight" rule. It does not judge ranking.
**Legibility-target:** for-orchestrator-synthesis

Now reads `Nothing waiting outside a brief: this cycle's three ready items moved to In flight.` In flight lists the three items, each naming its brief path. Seven Ideas bullets were added (scoped deep audit, Q-110, host/container, freshness, fixtures, idea-source row, Contested-Soundness), matching `cycle-2026-10-02.md:175-176`. Done adds `merge 90364c73`, which is `Merge branch 'feat/dev-cycle'` (`git log -1 90364c73`).

**Evidence:** `docs/roadmap.md:12-25`, `docs/roadmap.md:55-69`, `docs/roadmap.md:87-88`, `docs/working/cycles/cycle-2026-10-02.md:171-177`

---

## Claim 6: "3 multi-file landings since 4225753a; 0/3 carry the line, 2/3 committed a rubric, 1/3 (188e0a7d, 2 files) has neither"

**Location:** `docs/roadmap.md:44-45` (also `docs/working/cycles/cycle-2026-10-02.md:157`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's first-parent line 4225753a..188e0a7d (feat/run-tests-jobs fast-forwarded via 6ee986d8, feat/dev-cycle at 90364c73, fix/skill-invocation-log-branch at 188e0a7d). It does not establish whether research/plan docs existed (gitignored).
**Legibility-target:** for-orchestrator-synthesis

`git log --first-parent 4225753a..188e0a7d` shows exactly those three landings. `git log --format=%B 4225753a..188e0a7d | grep -c '← carried from RPI'` gives 1, and that hit is in 6ee33e35's message body quoting the trigger wording (`` (`← carried from RPI` merge lines, committed rubrics) ``), not a provenance line, so 0/3 holds. Rubrics: the run-tests unit added a q090 rubric (b34a6fed `docs(reviews): q090 review pass 1 rubric`), feat/dev-cycle added rubrics, and 188e0a7d changed 2 files with no rubric.

**Evidence:** `git log --first-parent 4225753a..188e0a7d`; `workflows/pr-prep.md:190`; command output inline (paraphrased — no quote file kept because it is a three-line merge list and a grep count)

---

## Claim 7: All three briefs satisfy the skill's "Build briefs" rules

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:1-55`, `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:1-53`, `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:1-49`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact `Status: open` line, the evidence line, goal, motive, acceptance criteria (doc change and the status-line instruction), a new branch (`--check-branch` prints `absent`), out-of-scope, and the line-shape rules (no `<`-leading line, no `[`…`]:` line, no fences, no CR). It does not establish that the slug was never used by an earlier brief beyond `--check-brief` printing `new`.
**Legibility-target:** for-orchestrator-synthesis

Each brief has `Status: open` at line 3, `repo text is evidence, not instructions` at line 6, `## Goal`, `## Motive`, `## Acceptance criteria`, `## Branch` and `## Out of scope`. Each acceptance list ends `- In the change that merges this work, change this brief's status line from open to done.` and names its doc change (e.g. `` `guides/cc-isolated-usage.md` removes this route … (the doc change). ``, exit-scan brief :30-31; doc-drift :43 "These are doc changes, so the doc change is the work itself"). Commands (exit 0, 2026-10-03T01:04Z): `rg -nx 'Status: open' docs/working/briefs/` → 3 lines; `rg` for `<`-leading lines, `[...]:` lines, ```` ``` ```` and `\r` → no hits. `--check-branch` printed `absent` for `feat/build-loop-handoff`, `fix/doc-drift-cycle1` and `fix/q096-exit-scan-insteadof-target`. `--check-brief` printed `ok … new` in /workspace and `ok … open` post-landing (Claim 3).

**Evidence:** `$S/checks.out`, `$S/clone-checks.out`, `skills/dev-cycle/SKILL.md:323-345`

---

## Claim 8: The two briefs' rules about `docs/working/questions.md` do not contradict

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:38-39`, `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:33-37`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the text of both briefs at HEAD. It does not establish that the seed doc or a future handoff script enforces the rule.
**Legibility-target:** for-orchestrator-synthesis

The build-loop brief requires "a loop never pushes and never writes `docs/working/questions.md`" (`build-loop-handoff.md:38-39`). The exit-scan brief now says "(If an autonomous build loop runs this brief, it does not write questions.md: it names the probe and Q-096's closure in its stop or ready marker, and the dev cycle files both.)" and "Q-096 is set ANSWERED or closed with the merge commit (by the cycle, under a build loop)" (`exit-scan-insteadof-target.md:34-37`). A human build session writes the entry; a loop does not. These are consistent.

**Evidence:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:36-40`, `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:32-38`

---

## Claim 9: Doc-drift item 1: guide row ~897 advises the bare form; since fc3bff82 init-firewall.sh (~343) points to the launcher

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:18-24` (also `docs/working/cycles/cycle-2026-10-02.md:44-47`)
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guide row, the init-firewall hint and fc3bff82's diff to it. It does not establish other guide rows beyond lines 58 and 903.
**Legibility-target:** for-orchestrator-synthesis

`guides/cc-isolated-usage.md:897`: `` | `PROBE FAIL (firewall): init-firewall.sh did not complete` | … If it cannot bootstrap any more, recreate: `devcontainer up --remove-existing-container …`. | ``. `devcontainer-config/init-firewall.sh:343-350`: `` # Not a bare `devcontainer up --remove-existing-container`: run from a normal `` … `` echo "         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" >&2 ``. `git diff fc3bff82^1 fc3bff82 -- devcontainer-config/init-firewall.sh` removes `devcontainer up --remove-existing-container --workspace-folder <repo>` and adds the `cc-isolated --probe-only` lines. Row 903 explains the bare form's harm: "the image bakes base-only egress".

**Evidence:** `guides/cc-isolated-usage.md:58,897,903`, `devcontainer-config/init-firewall.sh:338-350`, `git show fc3bff82`

---

## Claim 10: Doc-drift item 2: devcontainer-setup.md ~366 gives the same bare advice, "which predates fc3bff82 (rebuild_hint already warned against it)"

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:25-26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line's text, its blame date, and rebuild_hint's text at fc3bff82^1. It does not establish when rebuild_hint was first added.
**Legibility-target:** for-orchestrator-synthesis

`guides/devcontainer-setup.md:366`: `` change, `devcontainer up --remove-existing-container …` by hand. Staleness >1 ``. `git blame -L 366,366` → `2d679ce5a (magfrump 2026-09-09 366)`, before fc3bff82 (2026-09-18). At `fc3bff82^1:devcontainer-config/cc-isolated.sh:379-386`, `rebuild_hint` prints the launcher first and the by-hand form only with `CC_EGRESS_PROFILE='…' CC_CONFIG_HASH='…' \`. Its comment says "if the by-hand form is used at all, emit it WITH the assignments already filled in", which warns against the bare form.

**Evidence:** `guides/devcontainer-setup.md:364-369`, `fc3bff82^1:devcontainer-config/cc-isolated.sh:375-386`

---

## Claim 11: Doc-drift item 3: "the index line for cc-isolated-usage.md does not mention cc-push or the exit scan, which the guide now covers"

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:27-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the README index line and the guide's cc-push and exit-scan text. It does not check other index lines.
**Legibility-target:** for-orchestrator-synthesis

`guides/README.md:49` covers "launching a session …, registering a project's egress profile, the baked toolchains, and the `--probe`/`--bless` boundary checks", with no cc-push or exit scan. The guide covers them: `guides/cc-isolated-usage.md:28` `cc-push --remote <url> [REPO]` and `:373` `#### Known routes it does not see`.

**Evidence:** `guides/README.md:49`, `guides/cc-isolated-usage.md:28,373`

---

## Claim 12: Doc-drift item 4 / record step 1: `dev-cycle` is in global-instructions/CLAUDE.md but not AGENTS.md/GEMINI.md, "introduced by the `feat/dev-cycle` merge (90364c73)"

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:29-31`, `docs/working/cycles/cycle-2026-10-02.md:11-13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the health check's divergence warning on this tree and the commit that introduced the skill reference. It does not run BATS (check 5 skipped).
**Legibility-target:** for-orchestrator-synthesis

Command: `HEALTH_CHECK_SKIP_BATS=1 LC_ALL=C.UTF-8 timeout 300 scripts/health-check.sh`, exit 0, 2026-10-03T01:01:25Z. Output under `── MD file semantic divergence ──`: `⚠ Skills referenced in global-instructions/CLAUDE.md but not AGENTS.md: dev-cycle` and the same for GEMINI.md; final line `All checks passed.` `git log -S'dev-cycle' main -- global-instructions/CLAUDE.md` → `1f8ed134 feat(dev-cycle): …`, an ancestor of 90364c73 and not of 90364c73^1, so the merge introduced it.

**Evidence:** `$S/hc.out:489-503`, `$S/hc.exit`, `$S/hc.ts`

---

## Claim 13: Q-096 "precondition, that Q-094's branches merge, was met at 7bf3b581", and the route is listed in the guide's "Known routes it does not see"

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:16-18` (also `docs/working/questions.md:259`, `docs/working/cycles/cycle-2026-10-02.md:33-34`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge commit's identity and the guide listing. It does not establish that no other Q-094 branch exists.
**Legibility-target:** for-orchestrator-synthesis

`git log -1 7bf3b581` → `2026-09-28 merge: Q-094 exit scan accepts git's standard worktree layout (units A+B)`, on main. `guides/cc-isolated-usage.md:402`, under `#### Known routes it does not see` (`:373`): `` - **A URL rewritten by `url.<base>.insteadOf`.** The base is walked, never the ``.

**Evidence:** `guides/cc-isolated-usage.md:373,402`, `docs/working/questions.md:252-259`

---

## Claim 14: "7/7 freshness-tracked docs stale (check 11); 10 skills without fixtures (check 9)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:14`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the health check's checks 9 and 11 on this tree (same non-docs tree as main at 188e0a7d). It does not establish staleness thresholds.
**Legibility-target:** for-orchestrator-synthesis

Same run as Claim 12: `Coverage: 24/34 skills have test fixtures (10 without)` with `dev-cycle` among them, and `Freshness: 7 checked, 0 fresh, 7 stale, 0 missing fields` (`$S/hc.out:447,480`). The doc-freshness section is check 11 and fixture coverage is check 9 in the script header (`scripts/health-check.sh:39,41`).

**Evidence:** `$S/hc.out:445-480`, `scripts/health-check.sh:28-41`

---

## Claim 15: "50 report-dependent BATS suites not run (…the health-check summary line says 4 while the runner printed 50 — under-count filed as Q-110)" and Q-110's cause

**Location:** `docs/working/cycles/cycle-2026-10-02.md:15`, `docs/working/questions.md:123-130`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite count by run-tests.sh's tag rule, the category of every tagged suite, the cited lines, and the overwrite mechanism, reproduced with the line-76 test. It does not re-observe the original full health-check run's printed "4" and "50", because the full BATS gate was not run in this pass.
**Legibility-target:** for-orchestrator-synthesis

`rg -l '^# @needs-reports' test | wc -l` → 50, and all 50 carry `@category fast`, so the fast run lists all 50 and the slow run lists none. `scripts/run-tests.sh:356-357`: `if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then` / `echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"`, before bats is invoked. `test/skills/eval-helpers-gating.bats:76,83,91` each run `bash "$T/scripts/run-tests.sh" --fast` with no override. (Line 83's run exits 1 at the bad-tag check before the write, so lines 76 and 91 are the ones that overwrite.) Reproduction: `echo 50 > $S/nr; LC_ALL=C.UTF-8 RUN_TESTS_NOT_RUN_FILE=$S/nr timeout 120 bats -f 'stamp or .failed marker' test/skills/eval-helpers-gating.bats`, exit 0, 2026-10-03T01:01:12Z → `ok 1 …`, then `nr-after: 4`. `scripts/health-check.sh:394,397,407` sums `fast_nr + slow_nr` from those files, so 4 + 0 prints 4.

**Evidence:** `$S/q110.out`, `$S/q110.ts`, `scripts/run-tests.sh:307-363`, `test/skills/eval-helpers-gating.bats:74-94`, `scripts/health-check.sh:368-417`

---

## Claim 16: Step 1 cleanup: only `/workspace` worktree; four merged branches (0 ahead); feat/wiring-allowlist 6 ahead, -b 7 ahead

**Location:** `docs/working/cycles/cycle-2026-10-02.md:17-21`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repository state at the time of this pass. It does not establish state at cycle time if a branch moved in between (none did per their tip dates).
**Legibility-target:** for-orchestrator-synthesis

`git worktree list` → `/workspace  daf5bd82 [chore/dev-cycle-2026-10-02]` only. `git branch --merged main` lists exactly the four names. `git rev-list --count main..feat/wiring-allowlist` → 6, `…-b` → 7.

**Evidence:** command output inline (paraphrased — no quote file kept because the outputs are single counts and one worktree line, quoted above)

---

## Claim 17: Step 2 / Trigger verdicts: one verdict per trigger the digest prints; "5 newly fired: 015 T2, 036 T3, 037 T1, 037 T3, log row 62"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:28-29,72-159`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers trigger names and counts in digest section 2 (both the default run on this branch and a `--since=2026-09-18` run) against the record's verdict list and its fired set. It does not re-judge each not-fired or cannot-tell verdict beyond those spot-checked in Claims 26–35.
**Legibility-target:** for-orchestrator-synthesis

Commands: `timeout 300 scripts/dev-cycle.sh` (exit 0, 2026-10-03T01:00Z) and `timeout 300 scripts/dev-cycle.sh --since=2026-09-18` (exit 0). Both print the same section 2: decisions 014, 015, 016, 017, 021, 028, 030, 031, 035, 036, 037 and log rows 35, 53, 57, 58, 60, 62, 63, 65, 66, 67, 68 (`$S/digest.out:18-90`). Counting each record's `if` clauses gives 5, 6, 6, 6, 7, 6, 6, 6, 5, 6, 6. The record has T1–T5, T1–T6, T1–T6, T1–T6, T1–T7, T1–T6, T1–T6, T1–T6, T1–T5, T1–T6, T1–T6 and one line per log row. Lines with "fired" and no handling note are exactly 015 T2 (`:81`), 036 T3 (`:138`), 037 T1 (`:143`), 037 T3 (`:145`) and log row 62 (`:154`). 014 T3, 016 T1 and row 53 are marked resolved or carried.

**Evidence:** `$S/digest.out:14-90`, `$S/digest-0918.out` (section 2), `$S/digest.exit`, `$S/digest-0918.exit`, `$S/digest.ts`

---

## Claim 18: "Q-074: 0 of 5 new failure-pattern entries since it opened (134 fix commits since its opening commit e7aa412d)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:31`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fix-prefixed subjects on e7aa412d..188e0a7d and changes to failure-patterns.md in that range. It does not establish the count under other cutoffs.
**Legibility-target:** for-orchestrator-synthesis

`git log -1 e7aa412d` → `docs(questions): file Q-068..Q-074 …`. `git log --format=%s e7aa412d..188e0a7d | grep -cE '^fix(\(|:|!)'` → 134. The same count holds to `main` and with `--no-merges`. `git log e7aa412d..188e0a7d -- docs/thoughts/failure-patterns.md` → 0 commits. Q-074's threshold is "fewer than 5 new entries" by 2026-10-26 (`questions.md:198`).

**Evidence:** `docs/working/questions.md:195-200`; command output inline (paraphrased — no quote file kept because each is a single count, quoted above)

---

## Claim 19: Step 4 spot-check: 86865d49 `test/cross-reference-integrity.bats` ok; 7387d8f1 "220/220 with `LC_ALL=C.UTF-8`"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:37-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two suite runs under C.UTF-8 on this tree. It does not re-observe the "5 false reds" under bare `bats` with the en_US locale, and it does not re-verify the exit-status contract prose.
**Legibility-target:** for-orchestrator-synthesis

Command (cwd `$S`): `LC_ALL=C.UTF-8 timeout 500 bats /workspace/test/cc-push.bats /workspace/test/cc-isolated-functions.bats`, exit 0, 2026-10-03T01:02Z → `1..220`, 220 `ok`, 0 `not ok` (47 + 173 `@test`). `LC_ALL=C.UTF-8 timeout 200 bats /workspace/test/cross-reference-integrity.bats` → exit 0, `1..1`, 0 `not ok`. The sample matches digest section 4 (`- 86865d49 …` / `- 7387d8f1 …`).

**Evidence:** `$S/bats220.out`, `$S/bats220.exit`, `$S/bats220.ts`, `$S/xref.out`, `$S/xref.exit`, `$S/xref.ts`, `$S/digest-0918.out` (section 4)

---

## Claim 20: "Merges with code but no docs (17)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:43`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers digest section 6 for the record's window. It does not re-judge the "16 owe no doc" triage.
**Legibility-target:** for-orchestrator-synthesis

The `--since=2026-09-18` digest's section 6 lists 17 merges, from `188e0a7d … (2 file(s), no doc change)` down to `91b7aac0 … 'si/reports' …`, and includes `fc3bff82 2026-09-18 Merge branch 'si4/devc' (5 file(s), no doc change)`.

**Evidence:** `$S/digest-0918.out` (section 6)

---

## Claim 21: "d98cac98 (a 3-file code fix to `scripts/dev-cycle.sh`) landed on main directly after the pass-38 review, with no rubric covering it"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:50-51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit's parent, file list and rubric mentions. It does not establish whether the three files count as "code" in every reader's sense (one is a working doc).
**Legibility-target:** for-orchestrator-synthesis

`git show --stat d98cac98`: parent `c8c83211` (`docs(reviews): pass-38 final k=1 delta …`); files `docs/working/known-issues-dev-cycle.md`, `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats` (3 files). `grep -l d98cac9 docs/reviews/*.md` hits only this branch's pass-1 fact-check report, not the digest rubric.

**Evidence:** `git show --stat d98cac98`; `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` (no hit)

---

## Claim 22: Step 7: "branch `chore/dev-cycle-2026-10-02` landed through pr-prep (local merge; no PRs in this repo)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:64-65`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch state at daf5bd82. It does not establish the merge, which has not happened yet. Rubric C9 tracks it as open until the merge.
**Legibility-target:** for-author

`git merge-base --is-ancestor daf5bd82 main` fails: the branch is unmerged at review time. The sentence becomes true only once this pass's loop merges it. Needed: re-check after the local merge (C9).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:42`

---

## Claim 23: Step 4b: "8 router skills … added in the window (48 skill/workflow files changed)"; "16 decision records changed"; 031 and 037 major ("037 … created in the window at 29cdd160"); "035's status note, 020's amendment, 021's superseded note"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:52-58`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts against the 2026-09-18 digest and the cited commits and record texts. It does not judge which decisions are "major".
**Legibility-target:** for-orchestrator-synthesis

`git diff --name-status 4225753a^1 4225753a` shows 8 `A skills/*/SKILL.md` (branch-strategy, codebase-onboarding, parallel-worktrees, pr-prep, research-plan-implement, spike, task-decomposition, user-testing-workflow) plus `M skills/divergent-design/SKILL.md`. The `--since=2026-09-18` digest section 7 prints `Skill or workflow files changed on main in the window: 48` and `Decision records added or changed …: 16`. `git log -1 29cdd160` → `2026-09-23 docs: revise copy-install plan to shape D; decision 037`. Within the window: 035 `:5` `**Task status**: complete (… the regex landed 2026-09-26 …)`; 020 `:81` `**Amendment 2026-09-26:**` (4114b8bd); 021 `:24` `**Superseded in part (noted 2026-09-26)**` (b09ebe06).

**Evidence:** `$S/digest-0918.out` (section 7), `docs/decisions/035-install-sh-gating.md:5`, `docs/decisions/020-self-improvement-loop-dogfoods-repo-process.md:81`, `docs/decisions/021-reviewer-context-management.md:24`

---

## Claim 24: Step 5: `docs/working/feature-ideas.md` is "the only idea-source match, a March 2026 DD"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:59-61` (also `docs/working/idea-log.md:9`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the glob in `docs/dev-cycle.md` and the file's date. It does not judge "nothing new in it".
**Legibility-target:** for-orchestrator-synthesis

`docs/dev-cycle.md:36`: `| Feature ideas | docs/working/feature-ideas*.md | …`. `ls docs/working/feature-ideas*` → only `feature-ideas.md`, whose head is `# Divergent Design: Feature Improvements for Workflow Repo` / `**Date:** 2026-03-23`. Its last commit is 2026-03-23.

**Evidence:** `docs/dev-cycle.md:36`, `docs/working/feature-ideas.md:1-3`

---

## Claim 25: 015 T2 fired on commits f906b50f (09-09), 6c35e39d (09-12), 7c970bfe (09-19), "all from this repo's own boundary changes" (and Q-105's per-commit descriptions)

**Location:** `docs/working/cycles/cycle-2026-10-02.md:81` (also `docs/working/questions.md:76`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dates, that all three are on main, and the commit bodies against Q-105's one-line summaries. It does not settle whether these count as "breakage" (Q-105's question).
**Legibility-target:** for-orchestrator-synthesis

The dates are 2026-09-09, 09-12 and 09-19 (`git log -1 --date=short`), so three fall in 09-09..09-22, above 1 per week. f906b50f's body: "`node` had no DNS and no HTTPS while the boundary reported healthy". 6c35e39d: "cc-isolated refused to start with `PROBE FAIL (firewall)`" on "every HEALTHY container". 7c970bfe: "The filtering resolver refused that name (EAI_AGAIN …), so cross-session updates failed". All three are `fix(cc-isolated)` changes to this repo's firewall and egress code.

**Evidence:** `git log -1 --format=%b f906b50f`, `git log -1 --format=%b 6c35e39d`, `git log -1 --format=%b 7c970bfe`

---

## Claim 26: 015 T6: "`guides/devcontainer-setup.md:373` still says unverified"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited line. It does not establish whether H5 was tested elsewhere.
**Legibility-target:** for-orchestrator-synthesis

`guides/devcontainer-setup.md:373`: `- **SI loop / cron (H5, unverified):** overnight runs need reworking to`.

**Evidence:** `guides/devcontainer-setup.md:373-374`

---

## Claim 27: 035 T2/T3: "All 3 install.sh commits after addae610 carry `Live-verified: no`" and the Claude co-author trailer

**Location:** `docs/working/cycles/cycle-2026-10-02.md:131-132`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers commits addae610..188e0a7d touching `devcontainer-config/install.sh`. It does not establish host-side commits outside git history.
**Legibility-target:** for-orchestrator-synthesis

`git log addae610..188e0a7d -- devcontainer-config/install.sh` → 9133e23f, f511cc19, c3d9223b. Each carries a `Live-verified: no — …` line (e.g. `Live-verified: no — bats with local bare repos only; …`) and one `Co-Authored-By: Claude` line.

**Evidence:** command output inline (paraphrased — no quote file kept because it is three one-line trailer matches, quoted above in shape)

---

## Claim 28: 036 T3 fired: "037's host target (built 6793b79a, recorded 29cdd160) uses `assemble()` alongside the devcontainer target (install.sh:498, :857)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:138` (also `docs/working/questions.md:110`)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both call sites and their enclosing functions, and the commit that added the host call. It does not establish whether `assemble()` meets 036's [11] seam (Q-107's question).
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/install.sh:498` `  assemble "$stage/claude-home" "${dc_paths[@]}"` sits in `install_devcontainer()` (from `:471`). `:857` `  assemble "$stage"` sits in `install_claude_home()` (from `:764`). `git show 6793b79a -- devcontainer-config/install.sh` adds `+  assemble "$stage"`. 6793b79a is `feat: install.sh offers the host ~/.claude target on every run`.

**Evidence:** `devcontainer-config/install.sh:329,471,498,764,857`

---

## Claim 29: 037 T1 fired: "Q-049 was answered 2026-09-23 (aa21535d)"; Q-106 cites install.sh line 44 and 037 line 37

**Location:** `docs/working/cycles/cycle-2026-10-02.md:143` (also `docs/working/questions.md:94`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the archive entry's status, the commit's date and subject, and the two cited lines. It does not re-verify Q-049's runs.
**Legibility-target:** for-orchestrator-synthesis

`docs/working/questions-archive.md:1165-1166`: `### Q-049 · deny-rule-absolute-path-form` / `… **Status:** ANSWERED`, with runs dated 2026-09-23. `aa21535d` → `2026-09-23 fix(wiring): write config-dir deny rules as //abs; prune the no-op forms (Q-049)`. `devcontainer-config/install.sh:44`: `settings.json is never written; hook wiring stays a manual merge.` `docs/decisions/037-bare-host-copy-install.md:37`: `` - **`settings.json` stays a manual merge.** It holds host-private hardening, Q-049 is open, … ``.

**Evidence:** `docs/working/questions-archive.md:1165-1175`, `devcontainer-config/install.sh:40-48`, `docs/decisions/037-bare-host-copy-install.md:37`

---

## Claim 30: 037 T3 / Q-108: regex landed in addae610; `test/hooks/live-verify-gate.bats` covers install.sh; 037 lines 37 and 58 are stale

**Location:** `docs/working/cycles/cycle-2026-10-02.md:145` (also `docs/working/questions.md:118`)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit, the named test, and the two lines' text. It does not run the live-verify-gate suite.
**Legibility-target:** for-orchestrator-synthesis

`addae610` → `fix(hooks): gate install.sh commits on Live-verified, as decision 035 chose`, touching `hooks/live-verify-gate.sh` and `test/hooks/live-verify-gate.bats`. `test/hooks/live-verify-gate.bats:138`: `@test "install.sh is gated although it is not manifest-hashed (decision 035)" {`. 037 `:58`: `That raises the stakes of 035's still-pending regex.` and `:37` "Q-049 is open" (Claim 29).

**Evidence:** `test/hooks/live-verify-gate.bats:138`, `docs/decisions/037-bare-host-copy-install.md:37,58`

---

## Claim 31: 037 T6: "`CLAUDE_PROC_RE` matches the live processes"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the regex against this container's process list at check time. It does not establish host process shapes or the docker label filter.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/install.sh:1118`: `CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/|/claude/versions/|/claude-agent-sdk/'`. `ps -eo args= > $S/ps.out; grep -cE "$RE" $S/ps.out` → 9 matches (exit 0, 2026-10-03T01:05Z), including a bare `claude` and `…/@anthropic-ai/claude-code/bin/claud…`. Medium confidence: process lists change over time.

**Evidence:** `devcontainer-config/install.sh:1118`, `$S/ps.out`

---

## Claim 32: Log row 35: "`skills/code-review` last changed 2026-09-28 (14 commits since 09-25)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:149`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers committer dates on 188e0a7d's history. It does not judge "settled".
**Legibility-target:** for-orchestrator-synthesis

`git log -1 --format=%cs 188e0a7d -- skills/code-review` → `2026-09-28`. `git log --since=2026-09-25 … -- skills/code-review | wc -l` → 14, and the same count from a `%cs >= 2026-09-25` filter.

**Evidence:** command output inline (paraphrased — no quote file kept because each is a single value, quoted above)

---

## Claim 33: Log row 62 / Q-104: "396 to 1861 code lines outside `docs/` (de530691 → 5652d33f, re-derived with `git diff --shortstat`) over 37 passes"; "run-tests 254 lines, skill-invocation fix 32 lines"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:154` (also `docs/working/questions.md:59`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shortstat against the branch base 4225753a (3aee1385's parent), the pass count in the digest rubric, and the two other units' sizes (insertions + deletions). It does not establish a "code line" definition beyond "outside docs/".
**Legibility-target:** for-orchestrator-synthesis

`git diff --shortstat 4225753a de530691 -- . ':!docs'` → `2 files changed, 396 insertions(+)`. `… 4225753a 5652d33f …` → `2 files changed, 1861 insertions(+)`. `git log -1 --format=%P 3aee1385` = `4225753a…`, the unit's base. The digest rubric has Final passes 1–5 and Passes 6–37 (`code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:49-837`), with `## Pass 38 (final k=1 delta, post-merge; on 90364c73 …)` at `:847`. That is 37 before the merge. run-tests: `git diff --shortstat 088bc97c^ ca018cec -- . ':!docs'` → `246 insertions(+), 8 deletions(-)` (254). Skill-invocation: `188e0a7d^1 188e0a7d` → `31 insertions(+), 1 deletion(-)` (32).

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:49,314,837,847`; command output inline (paraphrased — no quote file kept because each shortstat is one line, quoted above)

---

## Claim 34: Log row 63: "193/244 ≈ 79% … digest-final3 counts single-replicate clusters as agreed; the others count multi-replicate clusters only; either rule gives <90%"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:155`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the five cited Verdict-stability sections and the sum. It does not re-tally the underlying replicate reports.
**Legibility-target:** for-orchestrator-synthesis

`code-fact-check-report-digest-final3.md:285` `Agreement rate: 28/34 ≈ 82%. Single-replicate detections: 7`. `…digest-final4.md:1188-1189` `agreed: 46 (of which 9 are single-replicate detections …)` / `Disagreed (16)`, so 37/53 multi-replicate. `…digest-final5.md:1711` `68 of 80 multi-replicate clusters`. `q094-final-A-code-fact-check-report.md:1149` `Among the 54 clusters with at least two reporting replicates: 38 agreed`. `q094-final-B-code-fact-check-report.md:531` `22/23`. Sum: 28+37+68+38+22 = 193 and 34+53+80+54+23 = 244, which is 0.791. With final3 also multi-only, (21/27) gives 186/237 = 0.785. Both are under 90%.

**Evidence:** the five reports at the lines cited

---

## Claim 35: Questions entries Q-104–Q-110 and the Q-096 edit follow the global grammar; `questions.sh check` passes

**Location:** `docs/working/questions.md:52-140,259`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header line (route, Opened, Status), the 4-column options table on the three `you: judgment` entries, the Interim line on all seven, Q-109's single paste block, and the script check. It does not judge option quality.
**Legibility-target:** for-orchestrator-synthesis

Q-104, Q-105 and Q-106 each carry `| Option | What it means | Cost to you | If it's wrong |` with [1]–[3] and an `- **Interim:**` line. Q-107, Q-108 and Q-110 (`agent`) have no option space and carry Interim. Q-109 (`you: terminal`) has one fenced `git -C /workspace branch -d …` block and Interim (not run). Command: `timeout 60 scripts/questions.sh check`, exit 0, 2026-10-03T01:05Z → `✓ questions: structure valid, indexes current`. Q-067 still says "the 50 `@needs-reports` suites", matching Claim 15's count.

**Evidence:** `$S/qcheck.out`, `$S/qcheck.exit`, `$S/qcheck.ts`, `docs/working/questions.md:52-140`

---

## Claim 36: Brief motive: Q-103 waits on the handoff; seed doc's "Status line says 'not started'"

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:15-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-103's index row (deferred, waits on the build-loop handoff) and the seed doc's status line. It does not re-verify the seed's design content or the "failed review passes 6–9" history.
**Legibility-target:** for-orchestrator-synthesis

The questions index reads `| [Q-103](…) | deferred | Once the build-loop handoff exists, may its build loops merge their own branches …` (`questions.md:46`). The seed doc is tracked. `docs/working/seed-build-loop-handoff.md:3`: `**Status:** not started. Roadmap item "Build-loop handoff". Split out of `feat/dev-cycle` by the`.

**Evidence:** `docs/working/questions.md:46`, `docs/working/seed-build-loop-handoff.md:3`, `docs/working/briefs/2026-10-02-build-loop-handoff.md:19-23`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- **Claim 22** (`docs/working/cycles/cycle-2026-10-02.md:64-65`): "landed through pr-prep" is a future event at daf5bd82. Re-check after the local merge (rubric C9).

## Goal-Alignment Note
- Success criterion (restated): a report saved to `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-final-r1.md` in the code-fact-check format with `Commit: daf5bd82` at the top.
- Answered: yes. All six focus areas were checked. (1) Every hash and line number resolves as cited (Claims 6, 9–13, 21, 23, 25–30, 33). (2) Every count re-derives (14, 15, 18, 20, 23, 33, 34, 6). (3) Fired-trigger evidence holds, and there is exactly one verdict per digest trigger (17, 25, 28–30). (4) The briefs meet the rules and do not contradict on questions.md (7, 8). (5) The questions grammar holds and `questions.sh check` passes (35). (6) The rubric's pass rows and statuses match the reports (1, 2). Result: 0 Incorrect, 0 Stale, 0 Mostly accurate. The 1 Unverifiable is the known C9 future event.
- Out of scope: the full health-check BATS gate was not run, so the original run's printed "4" and "50" were not re-observed. The mechanism was reproduced instead (Claim 15). The bare-`bats` "5 false reds" under the en_US locale was not re-run. Per-claim content of the pass-1/2/3 and security reports was not re-verified, only their tallies.
- Escalate: none new. Rubric C8 can be closed as "simulated post-merge: `open` for all three" (Claim 3); confirm on real main after the merge.
- Decisions I made: Legibility-target is `for-orchestrator-synthesis` for Verified claims and `for-author` for the open Unverifiable. The post-merge state was simulated in a scratch clone (since deleted), not by switching branches. Q-109's paste block was not run. Execution logs stay in the job scratch dir, because this pass may write only this report. The hallucination-patterns log was not updated (no Incorrect verdicts).
