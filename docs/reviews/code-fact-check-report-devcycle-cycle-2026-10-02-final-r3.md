Commit: daf5bd82

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** full branch, final confirming pass replicate r3 (k=3): `git diff main...HEAD` on chore/dev-cycle-2026-10-02 (main = merge base = 188e0a7d). 12 files, docs only: docs/roadmap.md, docs/working/cycles/cycle-2026-10-02.md, docs/working/idea-log.md, docs/working/questions.md, the 3 briefs under docs/working/briefs/, and the review artifacts (rubric, pass-1/2/3 fact-check reports, security review). The review artifacts are checked only where the rubric summarizes them.
**Commit:** daf5bd82
**Replication:** r3 of k=3 (final confirming pass, decision log row 63)
**Checked:** 2026-10-02
**Total claims checked:** 34
**Summary:** 32 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Tag: Legibility-target per claim below (default mapping: Verified / Unverifiable → for-orchestrator-synthesis; Mostly accurate → for-author).

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). The closest logged class is "a count claimed in a tally that the source does not hold" (e.g. the mode1-equiv 33-vs-25 entry). Every count on this branch was re-derived below; none matches that pattern.

Execution provenance. Every command ran under `timeout`, cwd `/workspace` unless stated, against HEAD daf5bd82. Raw output is in the replicate's scratch directory `/home/node/.claude/jobs/db6d1182/tmp/cfc-r3.F4RVNL/` (abbreviated `$S` below), not `docs/reviews/execution-logs/`, because this replicate may write only this report. No repo file other than this report was written. The working tree was checked after each run: only the pre-existing untracked `devcontainer-config/` placeholder files were present.

| # | Command | Time (-07:00) | Exit | Output |
|---|---|---|---|---|
| E1 | `timeout 300 scripts/dev-cycle.sh --since=2026-09-18` | 18:01:11 | 0 | `$S/digest.md`, `$S/digest.err` |
| E2 | `LC_ALL=C.UTF-8 RUN_TESTS_NOT_RUN_FILE=$S/nr timeout 120 bats -f 'a stamp or .failed marker alone' test/skills/eval-helpers-gating.bats` (with `$S/nr` pre-filled `SENTINEL`); same with `-f 'a tag outside the header'` and `$S/nr2` | 18:02:40 | 0, 0 | `$S/gating-76.log`, `$S/gating-91.log`, `$S/nr`, `$S/nr2` |
| E3 | `bash -c 'source test/skills/runner-contract.bash; …'` count of `@needs-reports` suites without reports (the runner's own tag rule, `scripts/run-tests.sh:320-344`) | 18:02:4x | 0 | `$S/notrun-count.log` |
| E4 | `LC_ALL=C.UTF-8 timeout 120 bash -c "source scripts/health-check.sh; <check>"` for `check_skill_fixture_coverage`, `check_doc_freshness`, `check_md_semantic_divergence`, `check_questions_doc` | 18:02:54 | 0 ×4 | `$S/hc-<check>.log` |
| E5 | `LC_ALL=C.UTF-8 timeout 60 scripts/questions.sh check`; `timeout 60 ~/.claude/scripts/questions.sh check` | 18:03:01 | 0, 0 | `$S/qcheck-repo.log`, `$S/qcheck.log` |
| E6 | `timeout 60 scripts/dev-cycle.sh --check-branch <4 merged branches> <3 brief branches>` | 18:04:41 | 0 | `$S/check-branch.log` |
| E7 | `git clone --no-hardlinks /workspace $S/clone`; in the clone `git checkout -B main origin/chore/dev-cycle-2026-10-02` (daf5bd82), then `timeout 60 scripts/dev-cycle.sh --check-brief <3 briefs>`; clone deleted afterwards | 18:04:54 | 0 | `$S/check-brief.log` |
| E8 | `LC_ALL=C.UTF-8 timeout 500 bats test/cc-push.bats test/cc-isolated-functions.bats` | 18:05:16 | 0 | `$S/bats-ccpush.log` |
| E9 | the same, container default locale (`LC_ALL=en_US.UTF-8`, unset in the image) | 18:06:25 | 1 | `$S/bats-ccpush-bare.log` |
| E10 | `LC_ALL=C.UTF-8 timeout 300 bats test/cross-reference-integrity.bats test/fixture-hermeticity.bats` | 18:07:22 | 0 | `$S/bats-xref.log` |

Q-109's paste block was not run.

---

## Claim 1: Rubric Iterations rows 1–3: "5 Incorrect (doc-class), 7 Mostly accurate, 2 Unverifiable; security 2 Medium + 1 Info" / "1 Incorrect …, 3 Mostly accurate" / "Clean: 0 Incorrect, 0 Stale; 1 Mostly accurate (4b example called 020's amendment a superseded note), fixed before the final pass"

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:12-14`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's counts against the summary line of the report it cites, and the pass-3 fix landing in daf5bd82; does not establish that the earlier reports' own verdicts were correct, and notes that the pass-2 and pass-3 report headers count a split claim (1a/1b, 2a/2b) once, so their `Total claims checked` (20, 11) is one less than their section count (21, 12).

The report headers read `**Summary:** 28 verified, 7 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable` (`docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:9`), `16 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable` (`…-pass2.md:9`) and `10 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable` (`…-pass3.md:9`). The security review's severity lines are `**Severity:** Medium` (`docs/reviews/security-review-2026-10-02-devcycle-cycle.md:38`), `**Severity:** Medium (floor rule: …)` (`:64`) and `**Severity:** Informational` (`:80`). The pass-3 fix is daf5bd82's one-line record change, `-… 020/021's superseded notes` → `+… 020's amendment, 021's superseded note` (`git show daf5bd82 -- docs/working/cycles/cycle-2026-10-02.md`). That wording now matches the window diffs: 020 gained `+  **Amendment 2026-09-26:** the shipped Gate 1h does the opposite` and 021 gained `+**Superseded in part (noted 2026-09-26)**` (`git diff <main before 2026-09-18> main -- docs/decisions/020-… 021-…`).

**Evidence:** `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:9`, `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-pass2.md:9`, `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-pass3.md:9`, `docs/reviews/security-review-2026-10-02-devcycle-cycle.md:38`, `docs/working/cycles/cycle-2026-10-02.md:57`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: Rubric scope line: "`main...chore/dev-cycle-2026-10-02` (full branch, loop pass 1, `--loop-pass`)"

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:5`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's description of what the rubric reviewed; does not establish any error in the Iterations table, which carries each pass's real scope.

The header still describes pass 1 only, while the rubric now records three passes, two of them partial: `| 2 | 4a68e29a | \`20a462d4..4a68e29a\` |` and `| 3 | 237fce88 | \`4a68e29a..237fce88\` |` (`:13-14`). The `Commit:` line was advanced to 237fce88 in daf5bd82 but this line was not. The precise version: "full branch at pass 1; partial loop passes 2–3 (see Iterations); final confirming pass pending". Tier T: doc wording, no behavior.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:1`, `:5`, `:12-14`
**Legibility-target:** for-author

---

## Claim 3: Rubric Confirmed Good: "All cited hashes and line numbers resolve … 396 → 1861 re-derives"; "`--check-brief` prints `open` for all three briefs … the brief branches print `absent`"; "The record gives one verdict for every trigger the digest prints"

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:47-49`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every hash and line number cited in the 7 non-review files (Claims 11–12, 16, 20–28, 31–33 below), `--check-brief` in a clone whose `main` is daf5bd82, `--check-branch` for the three brief branches, and the trigger-name comparison (Claim 19); does not establish `--check-brief`'s result on the real merge commit, which does not exist yet (rubric C8 stays open until then).

E7 printed `ok docs/working/briefs/2026-10-02-build-loop-handoff.md open 20a462d44dbde7aa7edf73ee9a72f75a4132e7e5` and the same `open 20a462d4…` for the other two briefs. E6 printed `absent feat/build-loop-handoff`, `absent fix/doc-drift-cycle1`, `absent fix/q096-exit-scan-insteadof-target`. On the real `main` (188e0a7d) the same command prints `ok … new`, as expected before landing. The 30 cited hashes all resolve (`git log -1` for each). The ones the docs say are on main are ancestors of main (`git merge-base --is-ancestor`: fc3bff82, 7387d8f1, 86865d49, 7bf3b581, 90364c73, 4225753a, d98cac98, addae610, aa21535d, 29cdd160, 6793b79a).

**Evidence:** `$S/check-brief.log`, `$S/check-branch.log`, `scripts/dev-cycle.sh:28-41`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: Rubric C8 / C9 stay open: "Re-run `--check-brief` after the merge"; "Record step 7 says the branch 'landed through pr-prep' before it has … Open until the merge"

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:42`, `:44`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both items are still correctly open at daf5bd82 (the branch is 5 commits ahead of main and not merged); does not establish how they close.

`git log --oneline main..HEAD` lists five commits, `daf5bd82` down to `20a462d4`, and `git branch --merged main` does not list `chore/dev-cycle-2026-10-02`. So the record's step-7 "landed" is still a future state (Claim 18), and the post-merge `--check-brief` cannot run yet.

**Evidence:** `git log main..HEAD`, `git branch --merged main`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: Roadmap Next #4: "3 multi-file landings since 4225753a; 0/3 carry the line, 2/3 committed a rubric, 1/3 (188e0a7d, 2 files) has neither" (also record log row 66)

**Location:** `docs/roadmap.md:44-45`, `docs/working/cycles/cycle-2026-10-02.md:157`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three merges on main's first-parent line after 4225753a (6ee986d8 run-tests, 90364c73 dev-cycle, 188e0a7d skill-invocation fix), the carried-line grep and the rubric files; does not establish whether d98cac98, a 3-file direct commit on main and not a merge, should count as a landing under log row 66 (whose text says "multi-file merges").

`git log --first-parent 4225753a..188e0a7d` shows three merge commits. The only `carried from RPI` hit in their logs is prose describing the signal: `` (`← carried from RPI` merge lines, committed rubrics); research/plan `` (90364c73's branch). Rubric files changed per range: run-tests 1, dev-cycle 3, 188e0a7d 0. `git diff --shortstat 188e0a7d^1 188e0a7d` gives `2 files changed, 31 insertions(+), 1 deletion(-)`.

**Evidence:** `git log --first-parent 4225753a..188e0a7d`, `git diff --name-only 088bc97c^..6ee986d8`, `git diff --name-only 90364c73^1..90364c73`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: Roadmap Ideas: "the runner printed 50 report-dependent suites NOT RUN; the health-check summary said 4"; "health check 11 shows 7/7 stale, 0 fresh"; "Fixtures for dev-cycle and the 9 other unfixtured skills"

**Location:** `docs/roadmap.md:58-65`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's output of health-check checks 9 and 11, the 50-suite count under the runner's tag rule, and the 4-overwrite mechanism; does not re-run the full `health-check.sh` (≈7.5 min serial), so it does not reproduce the one historical summary line itself.

E4: `Coverage: 24/34 skills have test fixtures (10 without)` listing `branch-strategy codebase-onboarding dev-cycle draft-review parallel-worktrees pr-prep research-plan-implement spike task-decomposition user-testing-workflow`, and `Freshness: 7 checked, 0 fresh, 7 stale, 0 missing fields`. E3: `tagged=50 not_run=50`, and all 50 tagged suites carry `@category fast`, so the `--fast` run writes 50 (`scripts/run-tests.sh:356-358`, `echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"`) before any suite runs. The overwrite to 4 is Claim 33.

**Evidence:** `$S/hc-check_skill_fixture_coverage.log`, `$S/hc-check_doc_freshness.log`, `$S/notrun-count.log`, `scripts/health-check.sh:381-410`, `scripts/run-tests.sh:300-362`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: Roadmap Now / In flight / Done: three briefed items moved to In flight with their brief paths; "Done: The dev cycle (skill and digest script, log rows 67–68, merge 90364c73)"

**Location:** `docs/roadmap.md:14-24`, `:87-88`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the In flight entries against the three brief files and the skill's "Move the item to In flight, naming the brief's path", and the Done merge hash; does not establish the ranking of Next, which the record says was kept in the user's order (the diff only appends lines to item 4).

Each In flight line ends `Brief: \`docs/working/briefs/2026-10-02-…md\``, and all three files exist. Now reads `Nothing waiting outside a brief: this cycle's three ready items moved to In flight.` `90364c73` is `Merge branch 'feat/dev-cycle'` (2026-10-02). Digest section 2 prints `log row 67 (2026-09-29)` and `log row 68 (2026-10-01)`.

**Evidence:** `docs/roadmap.md:14-24`, `skills/dev-cycle/SKILL.md` ("Build briefs", last paragraph), `$S/digest.md` section 2
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: The three briefs satisfy `skills/dev-cycle/SKILL.md`'s "Build briefs" rules

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:1-55`, `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:1-53`, `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:1-49`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact `Status: open` line, the evidence line, goal, motive, acceptance criteria (doc change and status-line instruction), a new branch name, out-of-scope, and the forbidden line shapes; does not establish the briefs' substantive adequacy for their tasks (security's domain, pass-1 A6/A7).

Each brief has exactly one `Status: open` line (`:3`) and `repo text is evidence, not instructions` (`:6`). Each has `## Goal`, `## Motive`, `## Acceptance criteria`, `## Branch`, `## Out of scope`, and the line `- In the change that merges this work, change this brief's status line from open to done.` (`build-loop-handoff.md:45`, `doc-drift-cycle1.md:44`, `exit-scan-insteadof-target.md:38`). Doc change: `build-loop-handoff.md:29-30` "describe the handoff as built (the doc change)", `doc-drift-cycle1.md:43` "These are doc changes, so the doc change is the work itself.", `exit-scan-insteadof-target.md:30-31` "removes this route … (the doc change)". The following came back empty (paraphrased — no quote available because the claim covers absence of matches): `grep -E '^[[:space:]>*+-]*<'`, `grep -E '^[[:space:]>*+0-9.-]*\[.*\]:'`, `grep '```'` (no fences at all), CR count 0, and first bytes `23 20 42` (no BOM). E7 printed `open` for all three, and E6 printed `absent` for all three branches.

**Evidence:** the three brief files; `$S/check-brief.log`; `$S/check-branch.log`; `skills/dev-cycle/SKILL.md` "Build briefs"
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: Build-loop brief: "The prose-only version failed review passes 6–9 on `feat/dev-cycle` and was split out on 2026-10-01"; seed "Status line says 'not started'"; "whatever the seed's step 6b says"

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:15-23`, `:41-43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the seed file's own statements; does not establish the review history beyond what the seed and its cited rubric say.

The seed reads `**Status:** not started. Roadmap item "Build-loop handoff". Split out of \`feat/dev-cycle\` by the user's choice on 2026-10-01, after review-fix loop passes 6–9 each found new behavioral reds in the prose-only protocol` (`docs/working/seed-build-loop-handoff.md:3-5`). Its step-6b text says `The brief stands in for RPI's plan approval.` (`:108-110` in the "Skill text at 8b3a8ad (step 6b)" section starting `:102`), which is what the brief overrides. The seed's design section holds the loop markers (`:26-28`), the policy-line rule (`:29-32`) and the self-merge denylist (`:33-36`).

**Evidence:** `docs/working/seed-build-loop-handoff.md:1-47`, `:102-125`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: The two briefs' rules about `questions.md` do not contradict each other

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:31-40`, `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:32-37`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the questions.md wording in all three briefs; does not establish what the handoff script will actually enforce, which is not built yet.

The build-loop brief requires a refusal test that `a loop never pushes and never writes \`docs/working/questions.md\`` (`:38-39`) and has Q-103 re-routed `once the handoff lands` (`:31-32`). That brief builds the handoff, so no build loop can run it. The Q-096 brief agrees: `(If an autonomous build loop runs this brief, it does not write questions.md: it names the probe and Q-096's closure in its stop or ready marker, and the dev cycle files both.)` (`:34-36`) and `Q-096 is set ANSWERED or closed with the merge commit (by the cycle, under a build loop).` (`:37`). The doc-drift brief does not mention questions.md (paraphrased — no quote available because the claim covers absence: `grep -n questions docs/working/briefs/2026-10-02-doc-drift-cycle1.md` finds nothing).

**Evidence:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:31-40`, `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:32-37`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: Doc-drift brief items 1–4: cc-isolated-usage ~897 bare advice; init-firewall ~343 points to `cc-isolated --probe-only` since fc3bff82; the row below explains the harm; line 58 is launcher behavior; devcontainer-setup ~366 predates fc3bff82 ("rebuild_hint already warned"); README index omits cc-push and the exit scan; AGENTS.md/GEMINI.md omit `dev-cycle` since 90364c73

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:18-31`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each cited line, the fc3bff82 diff, blame dates and the divergence check; does not establish that these are the only stale spots in the guides.

`guides/cc-isolated-usage.md:897`: `| \`PROBE FAIL (firewall): init-firewall.sh did not complete\` | … If it cannot bootstrap any more, recreate: \`devcontainer up --remove-existing-container …\`. |`. The row at `:904` says the bare rebuild leaves `/etc/cc-egress-profile` and `/etc/cc-config-hash` empty, so `the image bakes base-only egress`. `:57-59` is launcher step 5: `If the running container's baked hash is not the blessed one …, recreate it with \`--remove-existing-container\``. fc3bff82's diff replaced `-    echo "         devcontainer up --remove-existing-container --workspace-folder <repo>"` with `+    echo "         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes"`. The new comment starts at `devcontainer-config/init-firewall.sh:343`: `# Not a bare \`devcontainer up --remove-existing-container\``. `guides/devcontainer-setup.md:366`: `` change, `devcontainer up --remove-existing-container …` by hand. ``, blamed to 2d679ce5a on 2026-09-09. `rebuild_hint` first appears in c1e5abd7 on 2026-09-15 (`git log -S rebuild_hint`), before fc3bff82 (2026-09-18). `guides/README.md:49` describes cc-isolated-usage as `launching a session …, registering a project's egress profile, the baked toolchains, and the \`--probe\`/\`--bless\` boundary checks`, with no cc-push or exit scan. E4 printed `⚠ Skills referenced in global-instructions/CLAUDE.md but not AGENTS.md: dev-cycle` (and the same for GEMINI.md). 90364c73's stat includes `global-instructions/CLAUDE.md | 1 +`.

**Evidence:** `guides/cc-isolated-usage.md:57-59`, `:897`, `:904`; `devcontainer-config/init-firewall.sh:343-350`; `guides/devcontainer-setup.md:363-368`; `guides/README.md:49`; `$S/hc-check_md_semantic_divergence.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: Q-096 brief: listed under "Known routes it does not see"; precondition met at 7bf3b581; `_snap_remote` in cc-exit-scan.sh; decision log rows 61 and 62

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:16-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited headings, function names, commit and log rows; does not establish that the brief's test list is complete for every git rewrite form.

`guides/cc-isolated-usage.md:373` is `#### Known routes it does not see`, and its list includes `- **A URL rewritten by \`url.<base>.insteadOf\`.** The base is walked, never the` (`:402`). `7bf3b581` is `merge: Q-094 exit scan accepts git's standard worktree layout (units A+B)` (2026-09-28) and is on main. `devcontainer-config/cc-exit-scan.sh:351` has `_snap_remote() {`. Log row 61 reads `enforcement-file plans enumerate bypass families before implementation` (`docs/decisions/log.md:84`), and row 62 is the `~400 changed code lines` cap (`:85`).

**Evidence:** `guides/cc-isolated-usage.md:373-405`, `devcontainer-config/cc-exit-scan.sh:342-351`, `docs/decisions/log.md:84-85`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: Record Window line is "the digest's Window line, as printed"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:2`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line's fixed text and the default-window note text; does not reproduce the original no-record run itself, because this branch's tree now holds a cycle record and E1 had to use `--since`.

E1's Window line matches the record word for word after the `(from …)` note. The note text is the script's own string at `scripts/dev-cycle.sh:646`: `source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"`. 2026-10-02 minus 14 days is 2026-09-18.

**Evidence:** `$S/digest.md:3`, `scripts/dev-cycle.sh:636-653`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: Record step 1: 7/7 stale; 10 skills without fixtures; 50 suites not run vs summary 4; merged branches with 0 ahead → Q-109; feat/wiring-allowlist 6 ahead, -b 7 ahead; only `/workspace` as a worktree; the listed working docs; nothing to archive

**Location:** `docs/working/cycles/cycle-2026-10-02.md:9-27`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's re-derivation of each count and list; does not establish that the "all checks passed" health-check run happened as described (the full run was not repeated), nor that the two wiring branches are exactly Q-098's (Q-098 names only `-b`; the other is the earlier Q-095 branch for the same allow list).

E4: `10 without`, `7 checked, 0 fresh, 7 stale`. E3: 50 (Claim 6). E6: `ok feat/hook-refuse-redirects … 0 2026-09-28`, `ok feat/run-tests-jobs … 0`, `ok feat/workflow-router-skills … 0`, `ok fix/agents-md-no-imports … 0`. `git rev-list --count main..feat/wiring-allowlist` = 6, `…-b` = 7. `git worktree list` shows only `/workspace`. All 12 named working docs exist under `docs/working/`. questions.md has 0 `Status:** ANSWERED` entries. The questions archive's Q-095 entry reads `Branch \`feat/wiring-allowlist\` (5d929dd) adds the host's 857-rule allow list` (`docs/working/questions-archive.md:1760`).

**Evidence:** `$S/hc-*.log`, `$S/notrun-count.log`, `$S/check-branch.log`, `git worktree list`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: Record step 3: "Q-074: 0 of 5 new failure-pattern entries since it opened (134 fix commits since its opening commit e7aa412d); it reopens as a judgment on 2026-10-26"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:31-32`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fix-commit count from e7aa412d to main and the failure-patterns file's last commit; does not establish the count under other prefix rules (with or without merges, `fix(`/`fix:`, all 134).

`git log --format=%s e7aa412d..main | grep -c '^fix'` gives 134, and the `--no-merges` and `^fix(\(|:)` variants also give 134. `docs/thoughts/failure-patterns.md` was last committed 2026-09-24, before Q-074 opened (`**Opened:** 2026-09-26`, `docs/working/questions.md:196`). Q-074's text: `If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment` (`:198`).

**Evidence:** `docs/working/questions.md:195-200`, `git log e7aa412d..main`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: Record step 4: 86865d49 `test/cross-reference-integrity.bats` ok; 7387d8f1 exit contract (cc-push 0/1/2, scan 3/4) and "220/220 with `LC_ALL=C.UTF-8`", "Bare `bats` shows 5 false reds"; 17 merges with code but no docs; d98cac98 "a 3-file code fix … landed on main directly after the pass-38 review, with no rubric covering it"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:37-51`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test runs, the exit-code headers, digest section 6's count and d98cac98's placement; does not establish the record's judgment that 16 of the 17 merges owe no doc.

E8: `1..220` with 220 `ok`. E9 (container locale `LC_ALL=en_US.UTF-8`): exit 1, 215 ok, 5 `not ok` (tests 28, 46, 159, 160, 208). E10: 3/3 ok (cross-reference 1/1, fixture-hermeticity 2/2). `devcontainer-config/cc-push.sh:30-34`: `#   0 pushed, or nothing to push;` / `#   1 an error …` / `#   2 bad usage`. `devcontainer-config/cc-exit-scan.sh:42`: `the launcher exits 3 instead of 0`, and `:1057` `exit 4` on fail-closed. Digest section 6 lists 17 merges. d98cac98 sits on main's first-parent line directly after `c8c83211 … pass-38 final k=1 delta on the merged dev-cycle; 1 red`. It touches `docs/working/known-issues-dev-cycle.md`, `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`. Only this branch's own pass-1 report mentions it under `docs/reviews/` (`rg -l d98cac9 docs/reviews`).

**Evidence:** `$S/bats-ccpush.log`, `$S/bats-ccpush-bare.log`, `$S/bats-xref.log`, `$S/digest.md` section 6, `devcontainer-config/cc-push.sh:30-34`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: Record 4b: "8 router skills plus `skills/dev-cycle/SKILL.md` were added in the window (48 skill/workflow files changed)"; "Of the 16 decision records changed, two count as major …: 031 … and 037 (… created in the window at 29cdd160). The rest carry trigger, status, amendment or wording edits (e.g. 035's status note, 020's amendment, 021's superseded note)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:52-58`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts against digest section 7, the router merge, creation dates and the sizes of the window edits; the "major" label is the cycle's judgment and is checked only for consistency with the diffs.

`git diff --name-status 4225753a^1 4225753a -- skills | grep ^A` lists 8 SKILL.md files (branch-strategy, codebase-onboarding, parallel-worktrees, pr-prep, research-plan-implement, spike, task-decomposition, user-testing-workflow). E1 section 7: `Skill or workflow files changed on \`main\` in the window: 48` and `Decision records added or changed … : 16`. Of the 16, only 037 was added in the window (`git log --diff-filter=A`: 2026-09-23, 29cdd160). The others' window diffs are 1–9 lines; 035's is `-- **Task status**: in-progress` → `+- **Task status**: complete …`.

**Evidence:** `$S/digest.md` section 7, `git log --diff-filter=A -- docs/decisions/*.md`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: Record step 7: "branch `chore/dev-cycle-2026-10-02` landed through pr-prep (local merge; no PRs in this repo)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:64-65`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch's state at daf5bd82; does not establish the future merge, which is the event that would make the line true.

At daf5bd82 the branch is unmerged (`git branch --merged main` does not list it; 5 commits in `main..HEAD`). This is the same open item as rubric C9: it becomes checkable only once the local merge happens. Blocker: the event has not occurred.

**Evidence:** `git log main..HEAD`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: The record has exactly one verdict per trigger the digest prints, under the digest's names

**Location:** `docs/working/cycles/cycle-2026-10-02.md:72-159`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers trigger names and per-record trigger counts in E1's section 2 against the record; does not establish each "not fired"/"cannot tell" judgment beyond the fired ones in Claims 20–28.

E1 section 2 prints 11 records (014, 015, 016, 017, 021, 028, 030, 031, 035, 036, 037) and 11 log rows (35, 53, 57, 58, 60, 62, 63, 65, 66, 67, 68). The record has the same 22 names, each once. Per record, the number of `if …` clauses printed equals the record's T-count: 014 5, 015 6, 016 6, 017 6, 021 7, 028 6, 030 6, 031 6, 035 5, 036 6, 037 6. Each log row has one line (row 65 carries a two-part verdict on one line).

**Evidence:** `$S/digest.md:43-120`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: 015 T2 fired: "f906b50f (09-09), 6c35e39d (09-12), 7c970bfe (09-19), all from this repo's own boundary changes, none from Docker"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commits' dates and subjects against the trigger "breakage exceeds 1/week over any 2-week window"; does not establish that no other breakage occurred (which only strengthens "fired"), or the definition question Q-105 leaves to the user.

`f906b50f 2026-09-09 fix(cc-isolated): accept steered traffic on destination`, `6c35e39d 2026-09-12 fix(cc-isolated): let \`node\` read the firewall completion marker`, `7c970bfe 2026-09-19 fix(cc-isolated): admit the Artifact frame zone`. That is three in 10 days, inside one 2-week window. All three are cc-isolated firewall/launcher fixes.

**Evidence:** `git log -1` for each hash; `$S/digest.md` 015 section
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: Other dated evidence: 014 T2 (c167181e, 5f70e0f6; fixture-hermeticity 2/2), 014 T3 (2a455fd4, 2026-07-09), 015 T6 (`devcontainer-setup.md:373` still unverified), 016 T1 (e87e0b54, 2026-07-13), 017 T2 (`unshare -rn` EPERM, no bwrap)

**Location:** `docs/working/cycles/cycle-2026-10-02.md:75-76`, `:85`, `:87`, `:95`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cited commits, line and runtime facts; does not establish the "not fired" judgments beyond these facts.

c167181e's body: `the hermeticity gate (test/fixture-hermeticity.bats) went red on the merged tip`. 5f70e0f6: `test: stub curl in the auto-approve suite so the hermeticity lint passes`. E10: fixture-hermeticity 2/2. `2a455fd4 2026-07-09 spike: nested bwrap fixture confinement is feasible`. `e87e0b54 2026-07-13 fix: anchor cc-isolated build paths to the config dir`. `guides/devcontainer-setup.md:373`: `- **SI loop / cron (H5, unverified):** overnight runs need reworking to`. `timeout 10 unshare -rn true` → `unshare: unshare failed: Operation not permitted`, and `command -v bwrap socat` prints nothing.

**Evidence:** `guides/devcontainer-setup.md:373-375`, `$S/bats-xref.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: 035 T2/T3: "All 3 install.sh commits after addae610 carry `Live-verified: no`" / "All carry the Claude co-author trailer"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:131-132`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the non-merge commits touching `devcontainer-config/install.sh` in `addae610..main`; does not establish who ran them beyond the trailer.

`git log addae610..main -- devcontainer-config/install.sh` lists 9133e23f, f511cc19 and c3d9223b. Each body has a `Live-verified: no — …` line and `Co-Authored-By: Claude Opus 5.5 (1M context)`.

**Evidence:** `git log -1 --format=%B 9133e23f f511cc19 c3d9223b`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: 036 T2 "0 commits since 2026-09-17"; 036 T3 fired: "037's host target (built 6793b79a, recorded 29cdd160) uses `assemble()` alongside the devcontainer target (install.sh:498, :857)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:137-138`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers non-merge commits since 2026-09-17 and the two `assemble` call sites; does not establish whether the shared `assemble()` meets 036's [11] seam (that is Q-107's task), and notes one merge, f8245afa (2026-09-21, `ans/litereview`), whose combined diff spans both `devcontainer-config/` and `workflows/` through separate commits (aa9a5a04 install.sh, 6eb89cd8 workflow docs). No single commit does.

Scanning every non-merge commit on main since 2026-09-17 for paths in both `^devcontainer-config/` and `^(skills|workflows|patterns)/` gives `count=0`. `devcontainer-config/install.sh:498`: `assemble "$stage/claude-home" "${dc_paths[@]}"`. `:857`: `assemble "$stage"` (host target). 6793b79a (`feat: install.sh offers the host ~/.claude target`) adds `+  assemble "$stage"`. 29cdd160 is `docs: … decision 037`. `assemble()` (`:329-361`) stages `git archive` content: `the payload is \`git archive HEAD\`, never \`cp -r\` of the tree` (`:326-327`).

**Evidence:** `devcontainer-config/install.sh:319-361`, `:494-500`, `:853-859`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: 037 T1 "Q-049 was answered 2026-09-23 (aa21535d)"; 037 T3 "The regex landed (addae610) and install.sh is covered (`test/hooks/live-verify-gate.bats`); 037's lines 37 and 58 are stale"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:143-145`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the archive entry, the commits, the test name and the two lines; does not run the gate test.

`docs/working/questions-archive.md:1201`: `**Answered 2026-09-23, run 3: single-slash rules match nothing; \`//abs\` and \`~/rel\` work.**`. `aa21535d 2026-09-23 fix(wiring): write config-dir deny rules as //abs; prune the no-op forms (Q-049)`. `addae610 2026-09-26 fix(hooks): gate install.sh commits on Live-verified, as decision 035 chose` touches `test/hooks/live-verify-gate.bats`, which has `@test "install.sh is gated although it is not manifest-hashed (decision 035)"` (`:138`). `docs/decisions/037-bare-host-copy-install.md:37`: `It holds host-private hardening, Q-049 is open`. `:58`: `That raises the stakes of 035's still-pending regex.`

**Evidence:** `docs/working/questions-archive.md:1165-1215`, `test/hooks/live-verify-gate.bats:138`, `docs/decisions/037-bare-host-copy-install.md:37`, `:58`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: Log row 35: "`skills/code-review` last changed 2026-09-28 (14 commits since 09-25)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:149`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `git log` with default merge inclusion; does not establish the "settled" judgment (13 if merges are excluded).

`git log -1 main -- skills/code-review` → `90a70554 2026-09-28`. `git log --since=2026-09-25 main -- skills/code-review | wc -l` → 14 (13 with `--no-merges`).

**Evidence:** `git log main -- skills/code-review`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: Log row 62 fired: "396 to 1861 code lines outside `docs/` (de530691 → 5652d33f, re-derived with `git diff --shortstat`) over 37 passes, with no re-split or waiver"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:154`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two shortstats against 4225753a and the pass numbering in the digest rubric; does not establish that pass 37 was complete (the rubric marks it `⏸ paused, not clean`), which "37 passes" does not claim.

`git diff --shortstat 4225753a de530691 -- . ':!docs'` → `2 files changed, 396 insertions(+)`. The same to 5652d33f → `2 files changed, 1861 insertions(+)`. `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:837`: `## Pass 37 (k=1 delta on 6f3d55e digest / 2e65ad5 skill) — stopped at the user's request`, and `:847`: `## Pass 38 (final k=1 delta, post-merge; on 90364c73 main = 5652d33f digest …)`. `grep -i 'waiver\|re-split'` on that rubric finds nothing (paraphrased — no quote available because the claim covers absence).

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:837-851`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: Log row 63: "193/244 ≈ 79% (<90%) … (digest-final3 counts single-replicate clusters as agreed; the others count multi-replicate clusters only; either rule gives <90%)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:155`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic from the five merged reports' Verdict-stability sections; does not establish agreement on untouched code alone, which the record itself says is not tallied.

Sources: q094-final-A `Among the 54 clusters with at least two reporting replicates: 38 agreed`; q094-final-B `22/23`; digest-final3 `28/34`; digest-final4 `37/53 … over the 53 clusters with two or more`; digest-final5 `68/80`. Sum 193/244 = 0.791 (python3). All-single-as-agreed: 221/272 = 0.8125. Multi-only (final3 as 21/27): 186/237 = 0.785. Both are below 0.90.

**Evidence:** `docs/reviews/q094-final-A-code-fact-check-report.md`, `docs/reviews/q094-final-B-code-fact-check-report.md`, `docs/reviews/code-fact-check-report-digest-final{3,4,5}.md` ("Verdict stability")
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: Log row 65: "Claude Code is now 2.1.288; the grammar was read from 2.1.284"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:156`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the installed package version in this container and the version string in log row 65; does not establish whether the grammar changed between them.

`/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/package.json`: `"version": "2.1.288"`. `docs/decisions/log.md` contains `2.1.284` once (row 65, `:88`).

**Evidence:** `docs/decisions/log.md:88`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: Idea-log seeds: "7 of 7 tracked docs are stale, 0 fresh, one by 67 commits"; "check 9 lists 10 skills"; idea source "file last committed 2026-03-23"; "Bare `bats` … 5 false reds"

**Location:** `docs/working/idea-log.md:7-10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each seed's cited signal; does not establish the ideas' merit.

E4: `docs/thoughts/code-review-evaluation-state.md: STALE — 67 commit(s) to tracked paths since 2026-07-30`, and 10 skills without fixtures. `git log -1 main -- docs/working/feature-ideas.md` → `dc7a7462 2026-03-23`, and it is the only `feature-ideas*` file. E9: 5 false reds.

**Evidence:** `$S/hc-check_doc_freshness.log`, `$S/hc-check_skill_fixture_coverage.log`, `$S/bats-ccpush-bare.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: Questions entries follow the global grammar and `questions.sh check` passes

**Location:** `docs/working/questions.md:29-33`, `:41-43`, `:52-141`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Q-104–Q-110 and the Q-096 edit: header line, route, a 4-column options table where options exist, Interim, a single paste block for the terminal entry, and the scripted check; does not establish ID order in the Open section (Q-109 follows Q-110), which the grammar does not require.

Q-104, Q-105 and Q-106 each have `**Needs:** you: judgment · **Opened:** 2026-10-02 · **Status:** OPEN`, a table headed `| Option | What it means | Cost to you | If it's wrong |`, `- **Blocks:**` and `- **Interim:**`. Q-107, Q-108 and Q-110 are `agent` with no option space and carry `- **Interim:**`. Q-109 is `you: terminal` with one fenced block and `- **Interim:** the branches stay.` E5: both checkers print `✓ questions: structure valid, indexes current` (exit 0). The digest counts 20 open entries (`agent=10, deferred=3, trigger=1, you: judgment=4, you: terminal=2`), matching 20 `### Q-` headings.

**Evidence:** `$S/qcheck-repo.log`, `$S/qcheck.log`, `$S/digest.md` section 3
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: Q-104 evidence: "396 code lines outside `docs/` at its first rubric (de530691, against 4225753a) … after 37 review passes (pass 38 reviewed the merged result) … run-tests 254 lines, skill-invocation fix 32 lines"

**Location:** `docs/working/questions.md:59`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest unit's own rubric file (first committed in de530691) and the two other landings' sizes; does not establish the earlier history: before the split, the combined feat/dev-cycle unit had its own pass-1 rubric at 89a3d3b (`code-review-rubric-2026-09-29-feat-dev-cycle.md`, 342 insertions and 1 deletion outside docs vs 4225753a).

`git log --diff-filter=A -- docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` → `de530691 2026-09-29 02:33:40`. Shortstats as in Claim 26. `git diff --shortstat 088bc97c^ 6ee986d8 -- . ':!docs'` → `246 insertions(+), 8 deletions(-)` (254 lines). 188e0a7d: `31 insertions(+), 1 deletion(-)` (32 lines).

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:8-10`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: Q-106 / Q-107 / Q-108 citations: "037 line 37 …", "`devcontainer-config/install.sh` header (line 44)", "FP-161", "`assemble` at lines 498 and 857", "Line 58 says '035's still-pending regex'"

**Location:** `docs/working/questions.md:94`, `:110`, `:118`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each cited line; does not establish the option tables' cost estimates.

`devcontainer-config/install.sh:44`: `settings.json is never written; hook wiring stays a manual merge.` `docs/thoughts/failure-patterns.md:303`: `- **FP-161** 2026-09-12 symptom:wiring-merge-by-deep-equality-leaves-stale-group-beside-new`. The installer's reminder: `echo "REMINDER: hooks/wiring.json changed (or was not installed before). Copying the"` (`devcontainer-config/install.sh:1091`). Lines 37, 58, 498 and 857 are as quoted in Claims 23–24.

**Evidence:** `devcontainer-config/install.sh:44`, `:1091`; `docs/thoughts/failure-patterns.md:303`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 33: Q-110 cause: "`test/skills/eval-helpers-gating.bats` runs nested `run-tests.sh --fast` calls (lines 76–91 …) that do not override `RUN_TESTS_NOT_RUN_FILE`. The nested run inherits the parent's file and overwrites the parent's count (50, written before any suite runs, `scripts/run-tests.sh:356`) with its own 4."

**Location:** `docs/working/questions.md:129`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the nested calls at 76, 83 and 91, the inherited-file overwrite reproduced for the 76 and 91 tests, and the write's position before the suites run; does not re-run the whole health check, and notes that `:356` is the guarding `if` whose body writes at `:357`.

`test/skills/eval-helpers-gating.bats:76`, `:83`, `:91`: `run bash "$T/scripts/run-tests.sh" --fast`, with no `RUN_TESTS_NOT_RUN_FILE`, unlike `:63`'s `run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash …`. (The `:83` call exits 1 at the bad-tag check, `scripts/run-tests.sh:351-353`, before the write.) `scripts/run-tests.sh:356-358`: `if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then` / `echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"` / `fi`, before the suites run. E2: a file pre-filled `SENTINEL` read `4` after the line-76 test alone, and `4` after the line-91 test alone. The parent's `--slow` run writes its own file (`scripts/health-check.sh:397`), so the summary is 4 + 0 = 4 (`:406-407`).

**Evidence:** `test/skills/eval-helpers-gating.bats:61-94`, `scripts/run-tests.sh:351-358`, `scripts/health-check.sh:388-408`, `$S/gating-76.log`, `$S/nr`, `$S/nr2`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 34: Q-109: "Four local branches are fully merged into `main` (0 commits beyond it)"; the paste block holds only `--check-branch` `ok` names

**Location:** `docs/working/questions.md:132-141`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four names via `--check-branch` and `git branch --merged main`; the block was not run, and this does not establish that no other session needs these branches.

`git branch --merged main` lists exactly those four plus `main`. E6 printed `ok <name> <sha> 0 <date>` for each. The block is `git -C /workspace branch -d feat/hook-refuse-redirects feat/run-tests-jobs feat/workflow-router-skills fix/agents-md-no-imports` (`:138`). `-d` refuses unmerged branches.

**Evidence:** `$S/check-branch.log`, `docs/working/questions.md:138`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 2** (`docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:5`): the scope line still says "full branch, loop pass 1" although the rubric now records partial passes 2–3. Name the passes, or point to Iterations.

### Unverifiable
- **Claim 18** (`docs/working/cycles/cycle-2026-10-02.md:64-65`): "landed through pr-prep" becomes checkable only after the local merge (rubric C9). Re-check post-merge, together with C8's `--check-brief` on the merge commit.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to the OUTPUT PATH below in the code-fact-check format with `Commit: daf5bd82` at the top.
- Answered: yes. All six requested areas were checked, with executed re-derivations for counts, the Q-110 mechanism, the digest trigger names and the briefs' `--check-brief` state.
- Out of scope: a full `scripts/health-check.sh` rerun (≈7.5 min, and the mechanism was reproduced directly); Q-109's paste block (not run, by rule).
- Escalate: nothing blocking. Optional wording fix for Claim 2. Residue noted in Claims 5/23: d98cac98 (a direct 3-file commit) and the merge f8245afa sit outside "multi-file merges" and "a commit" respectively.
- Decisions I made: I counted log row 66's "landings" as merges on main's first-parent line (6ee986d8, 90364c73, 188e0a7d) and left d98cac98 as a scope residue. I read "first rubric" in Q-104 as the digest unit's own rubric file (de530691), not the combined unit's earlier one (89a3d3b).
