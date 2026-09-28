Commit: 3dafc66

# Code Fact-Check Report

**Repository:** claude-workflows (`/workspace`), worktree `u3-review-docs`
**Scope:** `git diff main...feat/u3-review-docs` at 3dafc66: `docs/decisions/log.md` (row 60), `workflows/pr-prep.md`, `workflows/research-plan-implement.md`, `workflows/review-fix-loop.md`
**Checked:** 2026-09-28
**Commit:** 3dafc66
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 31
**Summary:** 24 verified, 6 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Evidence sources: files were read from the worktree (`$WT` = `/tmp/claude-1000/-workspace/fe8d5f41-d34b-4387-9352-6d6b13c2ada9/scratchpad/wt/u3-review-docs`). Paths are repo-relative. The proposal (`docs/working/proposal-2026-09-27-smaller-review-units.md`) is the source of record for the Q-076 transcript forensics, as the brief directed. Claims that only it supports are marked "per proposal doc" in their Scope. The hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read. No claim here matches a logged pattern. The closest class is "measured value quoted from an artifact", and the +476/+3,613 and 8/5 figures do appear in the cited source.

---

## Claim 1: "Every Incorrect in three iterations was in Q-076."

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the proposal's forensics; per proposal doc. It does not establish the count from the iteration-1 to iteration-3 fact-check reports themselves, which were not re-tallied.
**Legibility-target:** for-orchestrator-synthesis

The proposal says so: "Every Incorrect claim in every iteration was in Q-076." (`docs/working/proposal-2026-09-27-smaller-review-units.md:7`). The same claim already stands in `workflows/parallel-worktrees.md:58` ("every Incorrect finding in all three iterations was in Q-076").

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:7`, `workflows/parallel-worktrees.md:58`

---

## Claim 2: "the split was isolated by 21:50 but asked only at the cap and answered after 61 minutes"

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the timestamps and the 61-minute wait per proposal doc. It does not establish whether anyone raised the split before the cap; the source says someone did.
**Legibility-target:** for-author

The source reads: "By 21:50 the reviewers had already isolated it, and the split was offered then, but it happened only at the loop cap (asked 00:09, answered 01:10)." (`docs/working/proposal-2026-09-27-smaller-review-units.md:7`). 00:09 → 01:10 is 61 minutes, which matches "61m of it on the split question" (`:15`). Two points need tightening:
- "The split was isolated" should be "Q-076 was isolated".
- The source says the split was *offered* at 21:50. "Asked only at the cap" drops that. The lesson changes from "nobody raised it" to "it was raised and not acted on". Precise version: "Q-076 was isolated and a split offered by 21:50, but the split was put to the user only at the cap (00:09) and answered at 01:10."

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:7,15`

---

## Claim 3: "Iterations 2 and 3 re-fact-checked the whole diff at k=3, although `--range` and `--loop-pass` (k=1, decisions 031, 032 #4) already existed."

**Location:** `docs/decisions/log.md:83`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers k=3 on iterations 2 and 3 (from the rubric) and that both flags predate 2026-09-27 (from git history). "Whole diff" rests on the proposal. It does not establish that k=1 came from 032 #4: k=1 is decision 031, and 032 #4 is the short-circuit.
**Legibility-target:** for-orchestrator-synthesis

The rubric records "Fact-check k=3 at 02d14b0 (`iter2-*`)" and "Fact-check k=3 at a42e37f (iteration 3)" (`docs/reviews/code-review-rubric-2026-09-27-q076.md:14-15`). The proposal states the scope: "The iteration 2 and 3 fact-check briefs said 'every checkable claim … in the pass-1 diff'" (`proposal…:9`). Both flags existed before the batch:
- `--range` is listed as "**Commit range:** `--range abc123..def456`" (`skills/code-review/SKILL.md:106`).
- `git log -S'--loop-pass'` first hits 09eb87a (2026-08-06, decision 032 bundle).
- 3da78ec (2026-08-07, "loop-aware k per decision 031") introduces k=1.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-27-q076.md:13-18`, `skills/code-review/SKILL.md:106,218,410-417`, git `09eb87a`, `3da78ec`

---

## Claim 4: "Of 8 health-check runs, 5 were red."

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the proposal per proposal doc. It does not establish the count from session logs, which are not in the repo.
**Legibility-target:** for-orchestrator-synthesis

"There were 8 full health-check runs, 5 of them red" (`proposal…:11`).

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:11`

---

## Claim 5: "Install-host T33, T83 and T6 failed only in full runs, tripped by review agents' leftover probes (install.sh's no-agent guard reads the real process table)"

**Location:** `docs/decisions/log.md:83`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three test IDs: T83 and T6 from the rubric, T33 per proposal doc only. Also covers install.sh reading `/proc`. It does not establish by re-running that the probes were the cause.
**Legibility-target:** for-orchestrator-synthesis

- The rubric says: "Earlier full-suite runs failed a different single `install-host` test each time (T83, T6). Each passed when run alone; the cause was stray probe processes from review agents" (`docs/reviews/code-review-rubric-2026-09-27-q076.md:23`).
- The proposal adds T33: "install-host T33, T83 and T6. Each failed only in full runs and passed alone" (`proposal…:13`).
- install.sh reads the real table: "So any other process of this uid whose working directory is in the checkout is refused too. Read from /proc" (`devcontainer-config/install.sh:1122-1123`).

**Evidence:** `docs/reviews/code-review-rubric-2026-09-27-q076.md:23`, `docs/working/proposal-2026-09-27-smaller-review-units.md:13`, `devcontainer-config/install.sh:1120-1132`

---

## Claim 6: "one red came from a mid-run `questions.md` edit; the one real failure took 3 runs to see, one of them lost by piping output through `grep`"

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the proposal per proposal doc. It does not establish these facts from session logs.
**Legibility-target:** for-orchestrator-synthesis

Two proposal passages support this:
- "*Real* (1): shellcheck SC2155 … It took 3 full runs to see: one timed out, one had its output piped through `grep fail` and lost the failure, one wrote to a file." (`proposal…:12`)
- "*Self-inflicted* (1): `questions.md` was edited while a health-check was running" (`:14`).

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:12,14`

---

## Claim 7: "Q-076's design changed twice inside the loop as each round found a new bypass family, and the code grew +476 → +3,613 lines under review."

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the proposal per proposal doc. The line counts were not reproduced from git: the combined integrate branches' merge bases make a clean `--shortstat` ambiguous. This does not establish how "code" lines were counted.
**Legibility-target:** for-orchestrator-synthesis

"Each fact-check round found new bypass families: receivepack/pushurl, then includeIf/husky/rebase-exec, then gitdir/alternates. The design changed twice … The Q-076 code grew from +476 to +3,613 lines during review." (`proposal…:8`)

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:8`

---

## Claim 8: Row 60's citations: "(4) A plan that changes an enforcement file (`hooks/live-verify-gate.sh`'s set) …" and sources "`proposal…` (A2, A3, B1/B2, C3, C5, C6, D1); `workflows/review-fix-loop.md`, `pr-prep.md` 3c–3d/5a, `research-plan-implement.md` step 3"

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each cited section exists and holds the matching rule. It does not establish that the proposal items are adopted in full: B2's "final confirming pass stays k=3, full diff" is adopted only through pr-prep's existing "no `--loop-pass` on the final pass".
**Legibility-target:** for-orchestrator-synthesis

The enforcement set is defined in the hook: "`# The enforcement set: what cc-isolated.sh's enforcement_files() hashes`" (`hooks/live-verify-gate.sh:70`). The proposal sections exist at the cited IDs: A2 `:26`, A3 `:28`, B1 `:34`, B2 `:36`, C3 `:52`, C5 `:60`, C6 `:67`, D1 `:81`. The target locations hold the rules:
- review-fix-loop `### Early split trigger` at `:48`.
- pr-prep 3c `:232`, 3d `:244`, 5a `:321-335`.
- RPI step 3 `### 3. Plan` at `:152`, with the enforcement paragraph at `:233`.

**Evidence:** `hooks/live-verify-gate.sh:70-73`, `docs/working/proposal-2026-09-27-smaller-review-units.md:26-81`, `workflows/review-fix-loop.md:48`, `workflows/pr-prep.md:232-335`, `workflows/research-plan-implement.md:152,233`

---

## Claim 9: Row number "| 60 |" (and the commit subject "decision log 60")

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that 60 is the next free row on `main`, which ends at row 59 (`docs/decisions/log.md:82`). It does not establish uniqueness after sibling units merge: sibling branch `feat/u4-code-review-skill` (77a4ca5) also adds a row numbered 60 with different content.
**Legibility-target:** for-orchestrator-synthesis

Main's last row is "| 59 | 2026-09-27 | **Batch fan-out reviews and merges per item…" (`docs/decisions/log.md:82`). The sibling u4 diff adds "+| 60 | 2026-09-27 | **The code-review first-red short-circuit (decision 032 #4) may skip the critic panel at most once per review-fix loop…" (u4.diff:9). Whichever unit merges second must renumber its row and every "decision log 60" reference (see Escalations).

**Evidence:** `docs/decisions/log.md:82-83`, `scratchpad/wt/u4.diff:9`

---

## Claim 10: Row 60's rules (1)–(3) restate the workflow text they cite without contradiction

**Location:** `docs/decisions/log.md:83`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers (1) against `review-fix-loop.md:50-52,69`, (2) against `pr-prep.md:244,252-253`, and (3) against `pr-prep.md:232,321-335`. It does not cover the internal pr-prep tension in Claim 23.
**Legibility-target:** for-orchestrator-synthesis

The row and the workflow text line up:
- Row (1): "≥ ~75% of at least 3 Must Fix / Incorrect findings". review-fix-loop: "If there are at least 3 and one item or one file group holds about 75% or more of them" (`workflows/review-fix-loop.md:50`).
- Row (2): "the final confirming pass runs without either". pr-prep: "run that final confirmation pass **without** it and without `--range`" (`workflows/pr-prep.md:252-253`).
- Row (3) matches 3c's "`scripts/run-tests.sh <files>` and `scripts/run-tests.sh --failed`" (`:232`) and 5a's quiesce, file-output and re-run-alone paragraphs (`:323-335`).

**Evidence:** `workflows/review-fix-loop.md:50-52,69`, `workflows/pr-prep.md:232,244,252-253,321-335`

---

## Claim 11: "the plan-time pre-mortem wiring in `research-plan-implement.md` step 3 (the high-stakes escalation under "Failure modes considered")"

**Location:** `workflows/pr-prep.md:97`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step number and the subsection. It does not examine the rest of pr-prep 1c.
**Legibility-target:** for-orchestrator-synthesis

Step 3 is "### 3. Plan (essential) — specify the implementation steps" (`workflows/research-plan-implement.md:152`), and it runs until "### 4. Annotate" (`:359`). The escalation paragraph "**When to escalate to `/pre-mortem`:** If the plan is high-stakes" is at `:231`, inside "- **Failure modes considered**" (`:225`). The old "step 4" pointed at Annotate, so the fix is correct.

**Evidence:** `workflows/research-plan-implement.md:152,225,231,359`

---

## Claim 12: "In claude-workflows that is `scripts/run-tests.sh <files>` and `scripts/run-tests.sh --failed`."

**Location:** `workflows/pr-prep.md:232` (also `:335`, and row 60 at `docs/decisions/log.md:83`)
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Unverifiable-pending-sibling. Covers the uncommitted sibling worktree's usage text and argument parsing, which support both forms. It does not establish that `--failed` works: that is an executable guarantee, and the sibling is not committed.
**Legibility-target:** for-orchestrator-synthesis

On `main` the runner accepts only "`scripts/run-tests.sh [--fast|--slow|--all]`" (`scripts/run-tests.sh:16`). `feat/u1-run-tests` has no commit beyond 6fd72c8. Its worktree has `scripts/run-tests.sh` modified but uncommitted, with "`scripts/run-tests.sh [--fast|--slow|--all] [--failed] [FILE...]`" (u1 `scripts/run-tests.sh:16`) and "`--failed) failed_only=true; shift ;;`" (u1 `:66`). FILE arguments must be `.bats` files "under test/" (u1 `:29-31`). To verify: commit u1, then run `--failed` after a red run. Re-check after u1 merges.

**Evidence:** `scripts/run-tests.sh:16` (main), `scratchpad/wt/u1-run-tests/scripts/run-tests.sh:16-31,58-80` (uncommitted)

---

## Claim 13: "The full gate belongs to [step 5a](#5-verify-and-annotate-parallelizable), which owns how to run it and how to triage a red result."

**Location:** `workflows/pr-prep.md:232`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the anchor resolves and that 5a contains both how-to-run and triage. It does not cover the internal consistency of 5a's triage (Claim 23).
**Legibility-target:** for-orchestrator-synthesis

The heading "#### 5. Verify and annotate (parallelizable)" (`workflows/pr-prep.md:301`) slugs to `5-verify-and-annotate-parallelizable` under GitHub's rules (lowercase, punctuation dropped, spaces to hyphens). 5a holds the gate ("In claude-workflows the gate is `scripts/health-check.sh`", `:321`) and the triage table (`:329-335`).

**Evidence:** `workflows/pr-prep.md:301,321-335`

---

## Claim 14: "where `<sha>` is the `Commit:` stamp at the top of this unit's previous rubric (`docs/reviews/code-review-rubric-*.md`)"

**Location:** `workflows/pr-prep.md:244` (also row 60, `docs/decisions/log.md:83`)
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers current practice and the template on `main`. It does not establish the rule once sibling u4 lands: u4 makes the stamp mandatory and rewrites it each pass.
**Legibility-target:** for-author

Recent rubrics carry the stamp. The q076 rubric starts "Commit: 623ca02" (`docs/reviews/code-review-rubric-2026-09-27-q076.md:1`), and so do the 09-27, 09-25 and 09-24 skill-fixtures rubrics. The template on `main` does not require it. It opens "# Code Review Rubric\n\n**Scope:** [branch/range] | **Reviewed:** [date] | **Status…" with no `Commit:` line (`skills/code-review/references/rubric.md:31-34`). The only mandated `**Commit:**` is on the merged fact-check report (`skills/code-review/SKILL.md:570-571`). One older rubric puts the line after the heading, not at the top (`docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md:3`).

A second problem: within a loop "keep updating the same file" (`references/rubric.md:14`), so "the previous rubric" is the same file. Whether its stamp names the last reviewed pass depends on whoever updates it. u4.diff adds "The file's first line is `Commit: <reviewed HEAD short SHA>`" (u4.diff:127) and a pass that "rewrites the rubric's `Commit:` line to the HEAD it reviewed" (u4.diff:32). After u4 merges this claim is accurate. Until then, name the fallback (the canonical fact-check report's `**Commit:**`) or state the dependency on u4.

**Evidence:** `skills/code-review/references/rubric.md:14,31-34`, `skills/code-review/SKILL.md:570-571`, `docs/reviews/code-review-rubric-2026-09-27-q076.md:1`, `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md:1-3`, `scratchpad/wt/u4.diff:25-32,127`

---

## Claim 15: "Run `/code-review --loop-pass --range <sha>..HEAD`"

**Location:** `workflows/pr-prep.md:244`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both flags exist and can be combined in the documented syntax. It does not establish how partial-scope labelling interacts with the fact-check brief beyond SKILL.md's existing rule.
**Legibility-target:** for-orchestrator-synthesis

The two flags are documented as "**Commit range:** `--range abc123..def456`" (`skills/code-review/SKILL.md:106`) and "`--loop-pass` — mark this run as a **non-final pass of a review-fix loop**" (`:218`). Nothing in SKILL.md forbids combining them. Partial scope is handled at `:111` ("When the scope is narrower … (`--range` …) every critic prompt must state…").

**Evidence:** `skills/code-review/SKILL.md:106,111,218-222`

---

## Claim 16: "`--loop-pass` also sets the fact-check replicate count and the short-circuit; code-review's SKILL.md owns both (decisions 031, 032 #4)."

**Location:** `workflows/pr-prep.md:244`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two effects and their decision numbers. It does not list `--loop-pass`'s third effect, which is not needed for the claim: it implies `--no-gate`.
**Legibility-target:** for-orchestrator-synthesis

- Replicate count: "On a `--loop-pass` … run **k=1**" under "**Replication is loop-aware (decision 031…)**" (`skills/code-review/SKILL.md:410-413`).
- Short-circuit: "### First-red short-circuit (decision 032 #4) … Applies **only** when `--loop-pass` was passed" (`:638-640`).
- The flag's own entry: "Enables the first-red short-circuit and implies `--no-gate`" (`:220-221`).

**Evidence:** `skills/code-review/SKILL.md:218-222,410-417,638-640`

---

## Claim 17: "run that final confirmation pass **without** it and without `--range`, so the full panel runs over the whole diff and the amber inventory is complete"

**Location:** `workflows/pr-prep.md:252-253`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with SKILL.md's terminal-pass rule. It does not establish the scope default that u4 introduces (u4 makes `--loop-pass` default to the stamp range; a terminal pass without `--loop-pass` stays full-branch).
**Legibility-target:** for-orchestrator-synthesis

SKILL.md agrees: "`pr-prep` runs the final, otherwise-clean pass **without** `--loop-pass`, so the full panel runs to completion and the amber inventory is complete" (`skills/code-review/SKILL.md:674-676`). The default scope with no flags is "`git diff main...HEAD`" (`:100`), which is the whole diff.

**Evidence:** `skills/code-review/SKILL.md:100,218-222,674-676`

---

## Claim 18: "the [early split trigger](review-fix-loop.md#early-split-trigger-after-any-iteration) (checked after every iteration) … are owned by review-fix-loop.md"

**Location:** `workflows/pr-prep.md:262`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the anchor and the ownership statement. It does not cover other docs (CLAUDE.md, AGENTS.md) that may describe the cap without the trigger.
**Legibility-target:** for-orchestrator-synthesis

The heading is "### Early split trigger (after any iteration)" (`workflows/review-fix-loop.md:48`), which slugs to `early-split-trigger-after-any-iteration`. review-fix-loop's ownership line now lists "the early split trigger" (`:7`).

**Evidence:** `workflows/review-fix-loop.md:7,48`

---

## Claim 19: "In claude-workflows the gate is `scripts/health-check.sh`, which runs the fast suite and then the slow one."

**Location:** `workflows/pr-prep.md:321`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `check_bats`'s order. It does not cover the other checks health-check runs (shellcheck and others, `:1099-1109`). Note that the slow suite runs only if the fast one passes.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh:389-397
if ! HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast; then
    fail "Fast BATS suites failed — slow suites not run (fix fast first)"
    ...
if HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/slow" "$runner" --slow; then
```
(excerpt ends :397; enclosing `check_bats()` continues to :409 — read)

This is a structural claim about the script's control flow, not a claim that the gate passes, so static reading is enough.

**Evidence:** `scripts/health-check.sh:368-409,1099`

---

## Claim 20: "install.sh's no-agent guard (Q-058/Q-062) reads the real process table"

**Location:** `workflows/pr-prep.md:323`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `/proc` cwd scan (Q-062) and the pgrep check (Q-058). It does not establish which install-host tests stub which of the two, which the proposal describes ("The tests stub `pgrep`, but the `/proc` cwd scan reads the real process table", `proposal…:13`).
**Legibility-target:** for-orchestrator-synthesis

The Q-058 gate is headed "# --- No-agent gate (Q-058) ---" (`devcontainer-config/install.sh:1097`). The Q-062 addition says "Q-062 [2]: a process an agent left behind … counts as an agent … Read from /proc" (`:1120-1123`) and reads `< "/proc/$1/status"` (`:1132`).

**Evidence:** `devcontainer-config/install.sh:1097-1132`

---

## Claim 21: "In the Q-076 run, leftover probes made install-host T33, T83 and T6 fail in full runs while each passed alone."

**Location:** `workflows/pr-prep.md:323`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The same evidence as Claim 5: T83 and T6 from the rubric, T33 per proposal doc only.
**Legibility-target:** for-orchestrator-synthesis

The rubric says "(T83, T6). Each passed when run alone; the cause was stray probe processes from review agents" (`docs/reviews/code-review-rubric-2026-09-27-q076.md:23`). The proposal gives "install-host T33, T83 and T6" (`proposal…:13`).

**Evidence:** `docs/reviews/code-review-rubric-2026-09-27-q076.md:23`, `docs/working/proposal-2026-09-27-smaller-review-units.md:13`

---

## Claim 22: "Never pipe the output through `grep`: Q-076 lost a real failure that way."

**Location:** `workflows/pr-prep.md:325`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the proposal per proposal doc. The failure was lost for one run, not for good: it surfaced on a later run.
**Legibility-target:** for-orchestrator-synthesis

"one had its output piped through `grep fail` and lost the failure" (`proposal…:12`).

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:12`

---

## Claim 23: The "Flaky / infra / environmental" row (including "locally, stray processes or a missing locale") with action "Re-run the job once. If it fails again on re-run, treat as recurrent — file a flake issue and do not block this PR", alongside "A test that also fails alone is real."

**Location:** `workflows/pr-prep.md:333,335`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the internal consistency of 5a's triage now that local environmental causes are in the flaky row. It does not establish which rule a reader follows in practice.
**Legibility-target:** for-author

The row's action is "If it fails again on re-run, treat as recurrent — file a flake issue and do not block this PR on it" (`workflows/pr-prep.md:333`). The new paragraph says "A test that also fails alone is real" (`:335`). Take a stray probe that is still alive. The re-run fails again, so the row says "file a flake, do not block" while the paragraph says "real". Neither rule says "quiesce, then re-run", which is what the proposal's C5 intended ("Passes alone → *environmental*: print the offending processes and stop", `proposal…:61`). Suggested precise version: have the row's action for the local environmental causes point to the quiesce step (`:323`) and the re-run-alone rule (`:335`), rather than "file a flake issue and do not block".

**Evidence:** `workflows/pr-prep.md:323,333,335`, `docs/working/proposal-2026-09-27-smaller-review-units.md:60-63`

---

## Claim 24: "a path matching the `enforcement` pattern in `hooks/live-verify-gate.sh`"

**Location:** `workflows/research-plan-implement.md:233`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the variable exists under that name and is a path regex. It does not establish that the set is complete relative to `cc-isolated.sh`'s `enforcement_files()`, which the hook's comment says to "Keep in step with".
**Legibility-target:** for-orchestrator-synthesis

```bash
# hooks/live-verify-gate.sh:70-74
# The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo
# paths. Keep in step with that function. Plus install.sh, which is not hashed but
# runs on the host and chooses the diff the human reviews (decision 035).
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh|install\.sh$|egress/)'
touched="$(printf '%s\n' "$files" | grep -E "$enforcement" | sort -u)"
```

**Evidence:** `hooks/live-verify-gate.sh:70-74`

---

## Claim 25: "In Q-076, the review loop found a new bypass family in each round, the design changed twice, and the code grew from +476 to +3,613 lines under review."

**Location:** `workflows/research-plan-implement.md:233`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** The same evidence and residue as Claim 7, per proposal doc.
**Legibility-target:** for-orchestrator-synthesis

"Each fact-check round found new bypass families … The design changed twice … grew from +476 to +3,613 lines during review." (`proposal…:8`)

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:8`

---

## Claim 26: "If the plan changes an enforcement file …, the pre-mortem is required." (paragraph), and the checklist item: "If the plan is high-stakes (…), `/pre-mortem` has been invoked …; if the plan changes an enforcement file, that output lists the bypass families"

**Location:** `workflows/research-plan-implement.md:233,348`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the Done-when checklist enforces what the paragraph requires. It does not decide whether every enforcement-file change counts as a "security/auth boundary", which would make the two agree.
**Legibility-target:** for-author

The paragraph requires the pre-mortem for any enforcement-file plan (`:233`). The checklist puts the enforcement clause inside the item that is conditional on "If the plan is high-stakes (irreversible operation, >500 LOC, security/auth boundary, or public API contract)" (`:348`). An enforcement-file plan that the author does not class as high-stakes would pass the checklist with no pre-mortem at all. Precise version: make the checklist condition "If the plan is high-stakes **or changes an enforcement file**".

**Evidence:** `workflows/research-plan-implement.md:231-233,348`

---

## Claim 27: "This document owns the review-fix loop's control rules: the iteration cap and its exit conditions, the early split trigger, … The code-review skill owns … `--loop-pass`."

**Location:** `workflows/review-fix-loop.md:7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers pr-prep and review-fix-loop: pr-prep links the trigger rather than restating it. It does not cover row 60's restatement (a decision record, by design) or CLAUDE.md, AGENTS.md or GEMINI.md, which were not grepped for the cap wording.
**Legibility-target:** for-orchestrator-synthesis

pr-prep links rather than restating: "the [early split trigger](review-fix-loop.md#early-split-trigger-after-any-iteration) (checked after every iteration) … are owned by [review-fix-loop.md § Hard cap]" (`workflows/pr-prep.md:262`). `grep -i split` over pr-prep and parallel-worktrees finds no competing trigger rule (paraphrased — no quote available because the claim covers absence of matches).

**Evidence:** `workflows/review-fix-loop.md:7`, `workflows/pr-prep.md:262`, `workflows/parallel-worktrees.md:58`

---

## Claim 28: "Batches are already reviewed per item ([decision log 59](../docs/decisions/log.md))"

**Location:** `workflows/review-fix-loop.md:50`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the link resolves and that row 59 says this. The link targets the file, not the row: there is no per-row anchor.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/log.md` exists at `../docs/decisions/log.md` relative to `workflows/`. Row 59 reads "**Batch fan-out reviews and merges per item, not as one combined pass.**" (`docs/decisions/log.md:82`).

**Evidence:** `docs/decisions/log.md:82`

---

## Claim 29: "In the Q-076 batch, every Incorrect in three iterations was in Q-076. Reviewers had isolated it by 21:50, but the split was asked only at the cap (00:09) and answered at 01:10, and the other items waited on it."

**Location:** `workflows/review-fix-loop.md:52`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same as Claim 2: the timings and the Incorrect distribution match per proposal doc. The sentence omits that the split was offered at 21:50.
**Legibility-target:** for-author

The source reads "By 21:50 the reviewers had already isolated it, and the split was offered then, but it happened only at the loop cap (asked 00:09, answered 01:10)." (`proposal…:7`). "Asked only at the cap" is true of the question to the user. It hides that a split was already on the table at 21:50, which is the failure this trigger exists to fix (acting on the signal without waiting). Suggest "a split was offered by 21:50 but put to the user only at the cap (00:09)".

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:7`

---

## Claim 30: "In /away mode and autonomous loops, `split` is the default when the unit has separable parts …; when it has none, `escalate` stays the default."

**Location:** `workflows/review-fix-loop.md:69`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether a prior default existed in this doc. It does not assess whether CLAUDE.md's /away stop-and-wait rules imply one.
**Legibility-target:** for-author

"Stays" says escalate was already the default. On `main`, review-fix-loop names no default for the iteration-4 gate. `git show main:workflows/review-fix-loop.md | grep -i default` hits only unrelated lines (`:68` "dismissed by default", `:93`, `:183`). The gate says only "until a written decision is recorded selecting one of" (`workflows/review-fix-loop.md:56`). Precise version: "when it has none, `escalate` is the default."

**Evidence:** `workflows/review-fix-loop.md:56,69`; `git show main:workflows/review-fix-loop.md`

---

## Claim 31: "recorded the way the [early split trigger](#early-split-trigger-after-any-iteration) records it"

**Location:** `workflows/review-fix-loop.md:69`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the in-file anchor and that the trigger section defines a recording method. It does not re-check the cross-file anchor (Claim 18).
**Legibility-target:** for-orchestrator-synthesis

The heading "### Early split trigger (after any iteration)" is at `:48`. It defines the recording as "Record the split as an interim in `docs/working/questions.md` and in the commit body's `Notes:` line" (`:52`).

**Evidence:** `workflows/review-fix-loop.md:48,52`

---

## Escalations

- **Decision-log row collision.** U3 and U4 (`feat/u4-code-review-skill`, 77a4ca5) each add `| 60 |` to `docs/decisions/log.md`. The second to merge must renumber its row to 61 and update its commit/doc references ("decision log 60"). Route this to the merge orchestrator.
- **Dependency on U4 for Claim 14.** pr-prep 3d's "`Commit:` stamp at the top of this unit's previous rubric" becomes a contract only when U4's `references/rubric.md` change lands. If U3 merges first, the rule rests on convention.
- **Dependency on U1 for Claim 12.** `run-tests.sh <files>` / `--failed` exist only uncommitted in the u1 worktree. Re-verify, with execution, after U1 commits.

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 2** (`docs/decisions/log.md:83`): "the split was isolated by 21:50 but asked only at the cap". The source says Q-076 was isolated *and a split offered* at 21:50. Reword: "Q-076 was isolated and a split offered by 21:50".
- **Claim 14** (`workflows/pr-prep.md:244`): the `Commit:` stamp at the top of the rubric is convention, not template, on main (`references/rubric.md:31-34`). The rubric is also one file per loop. Accurate once U4 lands; until then name a fallback or state the dependency.
- **Claim 23** (`workflows/pr-prep.md:333,335`): the flaky row now includes stray processes and locale but keeps "fails again → file flake, do not block". That conflicts with "fails alone → real". Point the row's local-environmental action at quiesce plus re-run-alone.
- **Claim 26** (`workflows/research-plan-implement.md:348`): the checklist nests the enforcement-file clause under the high-stakes condition, so a non-high-stakes enforcement-file plan passes with no pre-mortem. Add "or changes an enforcement file" to the condition.
- **Claim 29** (`workflows/review-fix-loop.md:52`): same as Claim 2. "Split was asked only at the cap" omits that it was offered at 21:50.
- **Claim 30** (`workflows/review-fix-loop.md:69`): "`escalate` stays the default", but no prior default was stated. Use "is the default".

### Unverifiable
- **Claim 12** (`workflows/pr-prep.md:232,335`): Unverifiable-pending-sibling. `run-tests.sh <files>` / `--failed` exist only in the uncommitted u1 worktree. Needs U1 committed and one execution of `--failed` after a red run.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to <worktree>/docs/reviews/u3-code-fact-check-report.md, with `Commit: 3dafc66` at the top and `**Replication:** k=1 (loop pass, decision 031)` in the header, structured per the code-fact-check skill.
- Answered: yes. All 10 brief focus areas are covered in 31 claims.
- Out of scope: the pre-existing tension in code-review SKILL.md, whose "requires 2 consecutive clean passes" (`:411-412`) differs from pr-prep's exit condition (not in the U3 diff). CLAUDE.md, AGENTS.md and GEMINI.md were not grepped for cap/split wording.
- Escalate: decision-log row 60 collides with U4's row 60. Claim 14 depends on U4 and Claim 12 on U1 (see Escalations).
- Decisions I made: the Q-076 timings and counts that only the proposal supports are Verified with a "per proposal doc" scope, as the brief directed, not Unverifiable. Claim 9 (row number) is Verified against main, with the sibling collision moved to Escalations rather than a downgraded verdict.
