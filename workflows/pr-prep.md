---
value-justification: "Replaces manual pre-review cleanup with structured self-review, catching issues before async reviewers spend time on them."
---

# PR Preparation Workflow

*The self-review and cleanup steps follow the [orchestrated review pattern](../patterns/orchestrated-review.md), with commits/files as the units of review.*

## When to use
Before opening any pull request, especially when the reviewer is in a different timezone or unfamiliar with the libraries used.

## Process

The process has two phases: **content** (is the code right?) and **packaging** (is the PR presentable?). Complete Phase 1 before starting Phase 2 — packaging work gets thrown away if content issues force a split or architectural rethink.

See [decision 007](../docs/decisions/007-two-phase-pr-prep.md) for why this ordering was chosen.

### Step 0: Environment scan (automated)

Before starting either phase, run these commands to establish the state of the branch. These are mechanical — no judgment needed.

```bash
# Check for uncommitted work — stop and commit or stash before proceeding
git status

# Show what this branch changes vs main (file-level summary)
git diff --stat main...HEAD

# Show total lines changed (for the size check in step 1a)
git diff --stat main...HEAD | tail -1
```

**If `git status` shows uncommitted changes**, commit or stash them before proceeding. PR prep operates on committed code — uncommitted changes will be invisible to reviewers and CI.

**If the diff stat shows 0 files changed**, verify you're on the correct branch and that main is up to date (`git fetch origin main`).

**Advisory: failure-pattern coverage.** If this branch has `fix(...)` commits, check whether each one produced a corresponding entry in `docs/thoughts/failure-patterns.md`. The check is mechanical but its output is advisory — not every `fix:` commit should yield a library entry (typos, dep bumps, one-line obvious fixes don't). The point is to surface the question, not to coerce an answer.

```bash
# Count fix(...) commits on this branch
FIX_COMMITS=$(git log --oneline main..HEAD --grep='^fix' | wc -l)

# Count new FP-NNN entries added to the library
PATTERN_ADDITIONS=$(git diff main...HEAD -- docs/thoughts/failure-patterns.md \
  | grep -cE '^\+- \*\*FP-[0-9]+\*\*' || true)

if [[ "$FIX_COMMITS" -gt 0 && "$PATTERN_ADDITIONS" -eq 0 ]]; then
  echo "Advisory: $FIX_COMMITS fix(...) commit(s) on branch, 0 new failure-pattern entries."
  echo "  If any fix had a non-trivial {symptom, cause, fix} signature, append a new"
  echo "  FP-NNN entry to docs/thoughts/failure-patterns.md describing the root cause"
  echo "  and the symptom that led you to it. Use the existing entries as the format"
  echo "  reference. Do not skip this step — the library's value compounds only if"
  echo "  it's appended to."
  echo "  Legitimate skip cases: typo, dep bump, one-line obvious fix, environmental/upstream."
fi
```

**Interpret the result:** A warning here is a prompt, not a block. For each `fix(...)` commit, ask: did the diagnosis surface a reusable cause-and-fix shape a future grep would want to find? If yes for any of them, append a new FP-NNN entry to `docs/thoughts/failure-patterns.md` describing the root cause and the symptom that led you to it. Use the existing entries as the format reference. Do not skip this step — the library's value compounds only if it's appended to. If no for all of them, proceed — the legitimate-skip vocabulary in the warning covers the case. Do not invent FP entries to silence the warning; a misleading entry pollutes the library and degrades the prior signal for the next diagnosis.

**Completion criteria:**
- [ ] No uncommitted changes (clean working tree)
- [ ] Branch diff summary reviewed — total files and lines changed are known
- [ ] Failure-pattern advisory has been run; if it warned, each `fix(...)` commit was reviewed against the skip vocabulary and either an FP entry was appended or the skip rationale is recorded (commit message, PR description, or diagnosis log)
- [ ] If issues found, resolved before proceeding to Phase 1

### Phase 1: Content

#### 1. Gate checks

Run these concurrently — both are fast, and either failing changes the plan:

**a. Size check.** Use the line count from Step 0's diff stat. If the PR exceeds ~500 lines changed, consider whether it can be split before doing any other prep work. Look for:
- A preparatory refactor that can land independently
- Infrastructure/model changes separate from UI changes
- A minimal first PR that adds the feature behind a flag, with polish in a follow-up

If it genuinely can't be split, note this in the PR description (step 6). The **Reviewer's path — start here** section (step 6) is always required and already names the read-order entry point; for an oversized PR, expand that section from the default 1–3 files to walk the reviewer through the larger diff in dependency order, so a 1000-line change still has a named place to start rather than forcing the reviewer to reverse-engineer it.

**b. Dependent PR check.** If this branch builds on other unmerged PRs, verify they've been merged or that this PR's base is set correctly. If dependencies haven't landed, decide whether to wait, rebase onto a dev integration branch, or open as a stacked PR with a clear note. Skip this check for standalone branches.

When 2+ PRs are open or stacked together and you need to test them as a unit before review, don't improvise an ad-hoc dev merge — the standardized way to pull the whole in-flight set into one testable branch and resolve conflicts reviewably is the [Integration branch refresh](branch-strategy.md#integration-branch-refresh) in `branch-strategy.md`. It enumerates every open PR (not your local branch list), rebuilds a fresh `dev-refresh-<date>` off main, merges each PR head with conflict rationale recorded, and promotes only through the approval gate.

**c. Pre-mortem fallback check.** This step is a **fallback** for the plan-time pre-mortem wiring in `research-plan-implement.md` step 4 (the high-stakes escalation under "Failure modes considered") and `spike.md`. The primary path is plan-time — context is fullest then, and that's when `/pre-mortem` should run. This step exists only to catch the cases where the primary path did not run: RPI was skipped, the spike workflow was not used, or scope grew past the high-stakes threshold during implementation. The default action here is **skip**; the trigger fires only when both conditions below hold.

<!--
pr-prep-pre-mortem-fallback-r2 (separability note for future self-eval):
This step is intentionally distinct from the rejected R1 attempt
(commit 6ee0ae8, "feat(pr-prep): fire pre-mortem on high-risk PRs at gate-check
stage"). The polarity differs in a way self-eval can mechanically verify:

  R1 — ran-by-default on high-risk PRs; an existing artifact short-circuited
       the run. The default outcome was "run pre-mortem". Rejected because it
       duplicated RPI step 4's plan-time wiring whenever both fired, and ran
       a second time when the plan-time artifact lived under a different name.

  R2 (this step) — skipped-by-default; the trigger fires only when no
       `docs/working/pre-mortem-*.md` artifact exists for the branch AND the
       diff is high-risk. The default outcome is "skip pre-mortem". It cannot
       duplicate plan-time wiring because the existence of any plan-time
       artifact in the branch-scoped location suppresses it.

Separability test: if the existence of a branch-scoped pre-mortem artifact
no longer suppresses this step, R2 has regressed toward R1 and should be
re-evaluated.
-->

Run the check before opening the draft PR (step 2):

```bash
# (a) Does a branch-scoped pre-mortem artifact already exist?
PREMORTEM_EXISTS=$(find docs/working -maxdepth 1 -name 'pre-mortem-*.md' -type f 2>/dev/null | head -1)

# (b) Is the diff high-risk? Sum insertions + deletions; flag auth/crypto/migration paths.
LOC_TOTAL=$(git diff --numstat main...HEAD | awk '{ i+=$1; d+=$2 } END { print i+d+0 }')
HIGH_RISK_PATHS=$(git diff --name-only main...HEAD | grep -iE '(^|/)(auth|crypto|migration|migrate)' || true)

if [[ -z "$PREMORTEM_EXISTS" ]] && { [[ "${LOC_TOTAL:-0}" -gt 500 ]] || [[ -n "$HIGH_RISK_PATHS" ]]; }; then
  echo "Fallback pre-mortem trigger fires:"
  echo "  - No docs/working/pre-mortem-*.md artifact found for this branch"
  echo "  - Diff is high-risk (LOC=$LOC_TOTAL; high-risk paths: ${HIGH_RISK_PATHS:-none})"
  echo "Run /pre-mortem on the diff and save the output to"
  echo "  docs/working/pre-mortem-<branch-slug>.md"
fi
```

**If the trigger fires**, run `/pre-mortem` against the diff and save the artifact to `docs/working/pre-mortem-<branch-slug>.md`. Cite the artifact in the PR description's "Areas of uncertainty" section so reviewers see the failure narratives the author considered. **If it does not fire**, record the reason briefly (artifact already exists at `<path>`, or diff is low-risk) — either in a commit message or as a one-line note in the PR description — so the audit trail shows the check was evaluated, not skipped.

**This is a backstop, not the primary path.** If the trigger fires, treat that as a signal that the plan-time wiring failed for this branch and consider whether the workflow that produced this branch (RPI, spike, ad-hoc) needs to be adjusted — not just this single PR patched.

**Completion criteria:**
- [ ] PR is under 500 lines changed, OR PR description includes size justification and an expanded "Reviewer's path — start here" section (step 6) that walks the larger diff in read-order
- [ ] No unmerged dependency PRs block this branch, OR base is set correctly for stacking
- [ ] Fallback pre-mortem trigger was evaluated; if it fired, `docs/working/pre-mortem-<branch-slug>.md` exists and is cited in the PR description; if it did not fire, the reason is recorded

#### 2. Open draft PR

Push the branch and open a draft PR. This serves two purposes:
- CI starts running in parallel with your review-fix work (saves waiting at step 5a)
- Reviewers in other timezones get async visibility into in-progress work

Skip if the project doesn't use CI or if you're the sole contributor and prefer to push later.

**Done when...**
- [ ] Branch is pushed to remote
- [ ] Draft PR is open on the correct base branch
- [ ] CI is running (or this step was explicitly skipped with a documented reason)

#### 3. Review-fix loop

Run review skills and iterate until clean. This is required, not optional.

**Before running the review-fix loop, verify the change end-to-end: run the affected flow and observe the behavior (the `/verify` skill covers this), not just tests or typecheck.** Analytical critique from the loop's critic ensemble is not a substitute for executed evidence. Verification must run first; if it fails (tests don't pass, claims can't be backed by output), do not proceed to the critic ensemble — fix the underlying issue first.

**a. Generate reviews.** Run skills in parallel; perform manual checks while waiting for results:
- **Code review** (`/code-review`) — multi-critic structural review of the diff vs main
- **Self-eval** (`/self-eval <target>`) — rubric assessment of any new or modified skills/workflows
- **Documentation check** (manual) — if the PR changes public APIs, config options, or user-facing behavior, verify corresponding docs are updated (README, inline docs, decision records). Skip for internal refactors with no external surface.
- **Dependency audit** (manual) — if the PR introduces or upgrades dependencies, check license compatibility, package size, and maintenance status. Flag unmaintained or unfamiliar packages. Skip if no dependency changes.
- **Plan-drift check** (manual) — if a plan doc exists in `docs/working/` for this task, compare the diff against it and note: (1) planned items not yet implemented, (2) unplanned changes that appeared in the diff, and (3) plan assumptions that turned out wrong. Record any deviations found in the PR description's "Areas of uncertainty" section or as a comment on the PR. Skip if no plan doc exists for this work.

  **Carried-from line (RPI→pr-prep handoff).** A plan doc existing in `docs/working/` *is* the signal that this PR arrived through an RPI loop — so this same check is the RPI→pr-prep seam. While you have the plan doc open, also restate, in one line, the state the loop forwarded *into* the PR, recorded in the PR description's existing **Workflow provenance** field (step 6):

  ```
  ← carried from RPI: <state forwarded>
  ```

  `<state forwarded>` tersely names the load-bearing approach and the surviving constraints/invariants/decisions the diff must honor (and, if the RPI loop was itself entered from an upstream workflow, the originating decision record or spike/findings doc) — not a generic "see the plan." This is the *continuity* counterpart to the drift notes above: drift records what **diverged** from the plan; the carried-from line records what **crossed the seam intact**, so the reviewer sees the originating decisions without re-deriving them and can confirm the diff still honors them. The literal `← carried from` token is the grep audit handle (consistent with the `Failure-pattern grep:` and header `(cite: ...)` self-auditing conventions). The line is **conditional, never a placeholder**: standalone work has no plan doc and omits the line entirely — do not write `← carried from: none` (same rule as the Problem-framing line in `research-plan-implement.md`).

**b. Triage and fix.** Read each review artifact. Before sorting findings into the tier table below, scan each finding against `docs/reviews/override-log.md`. Findings that match a settled `Won't-Fix` row (this PR or an earlier one — same location, or same category and substantively the same claim) are surfaced under a separate **Re-flagged settled decisions** subsection in the review artifact and do **not** enter the tier triage. See `workflows/review-fix-loop.md` § Re-flagged settled decisions for the match criteria and the deliberate-promotion escape hatch (how to route a finding back into triage when the prior Won't-Fix no longer applies). This prefilter runs before the tier triage, but it does **not** override the Divergence detection check below — the two handle different re-fires: divergence detection *investigates* a re-fire the prior iteration tried to fix, whereas this filter *skips* a re-fire a human already settled as Won't-Fix. If a finding matches both (it was actively fix-attempted last iteration *and* carries a Won't-Fix row), divergence detection wins — see `workflows/review-fix-loop.md` § Re-flagged settled decisions. Only when neither applies does a finding enter the tier triage. Then work through the remaining findings in tier order:

| Tier | Meaning | Action |
|------|---------|--------|
| Must Fix | Correctness bugs, false passes, wrong behavior | Fix before proceeding |
| Must Address | Fragility, inconsistency, misleading tests | Fix or explicitly acknowledge |
| Consider | Style, duplication, future-proofing | Fix if cheap, otherwise note for later |

For each finding: confirm it's real by reading the code, then fix. Commit in coherent batches referencing finding IDs (e.g., `fix: Address code review findings A2-A5`).

**c. Run tests.** After fixing findings, re-run the test suite. Fixes often surface latent bugs — a tightened assertion may expose a helper bug, a scoping fix may reveal a silent false pass. Fix test breakage as separate commits.

**d. Re-review.** On the first iteration, run full review skills against the complete diff vs main. On iterations 2+, scope the re-review to reduce redundant work:

1. **Diff only the fixes.** Use `git diff <last-review-commit>..HEAD` to isolate code changed since the last review iteration. Run review skills against this narrower diff — unchanged code has already been reviewed.
2. **Verify prior Must Fix findings.** Walk the prior review's Must Fix and Must Address items and confirm each is resolved in the new diff. Mark each as resolved or still-open. This is a targeted check, not a full re-read of surrounding code.
3. **Spot-check for regressions.** Scan fix commits for unintended side effects (broken imports, changed signatures, shifted scoping). The narrower diff makes these easier to catch.

If a fix touched code broadly enough that the narrower diff covers most of the PR, fall back to a full re-review — the incremental approach only helps when fixes are localized.

**Scope drift.** If a re-review finding would expand the PR beyond the scope set in step 1 (size, files touched, stated intent), the default is to file a follow-up issue and decline the change in this PR. Comply only when the finding is a hard blocker for merge (correctness bug or unsafe state). When triggered, log a `follow-up issue filed: <id/title>` line in the review artifact so the deferral is visible to the reviewer.

**Optional contrastive prompt (iteration N≥2):** What new findings appeared in iteration N that weren't in N-1, and are any of them critic noise (regressions vs real)?

**Tracking iteration scope:** Note in the review artifact whether each iteration used full or incremental scope, and how many prior findings were verified as resolved vs. still-open. This supports evaluating whether incremental re-review reduces review output length and duplicate findings over time.

**e. Exit or repeat (3-iteration maximum).** Exit when no Must Fix items remain and Must Address items are resolved or explicitly acknowledged. Repeat if new findings appear. Each loop should be strictly smaller than the last.

**After 3 iterations**, if new findings are still appearing, **stop**. This mirrors the 3-hypothesis escape hatch in the debugging defaults — unbounded iteration has diminishing returns. Choose one of two exit paths:

1. **Ship with documented known issues.** If no Must Fix items remain but Must Address or Consider items persist, document them in the PR description's "Areas of uncertainty" section and proceed to Phase 2. The reviewer sees the known issues and can make a judgment call.
2. **Escalate to human review.** If Must Fix items remain, or if you're unsure whether remaining findings are safe to ship, stop and present the user with: iteration count, summary of fixes per iteration, remaining findings, and your assessment of why the loop isn't converging (e.g., fixes revealing deeper issues, change too large for incremental review, review criteria shifting). Use this template so escalation summaries stay consistent and complete:

   ```markdown
   ## Iterations (N completed)
   ## Remaining Must Fix
   ## Remaining Must Address
   ## Convergence diagnosis (one sentence)
   ## Recommended action (ship-with-issues / split-PR / pause for redesign)
   ```

The user can override the ceiling and say "continue" — but the default is to stop. See `workflows/review-fix-loop.md` § Convergence ceiling for extended discussion.

**Tracking:** Record the loop's outcome in the PR description so reviewers and future calibration have a consistent signal. This is symmetric across both exit paths:

- **Converged cleanly** (exited before the 3-iteration ceiling): add a one-line summary to the PR description in the form `Review converged in N iterations; M Must Fix resolved, K Must Address acknowledged.` This gives reviewers a calibration signal for the common case — they can see at a glance how much the loop actually caught.
- **Ceiling hit at 3 iterations:** follow the escalation paths above (ship-with-known-issues or escalate to human review), capturing iteration count, per-iteration fix summary, remaining findings, and assessment of why the loop didn't converge.

Both forms feed the same audit trail for calibrating the 3-iteration threshold over time.

**Completion criteria:**
- [ ] Review artifacts exist in `docs/reviews/` for each review skill run
- [ ] No Must Fix findings remain open
- [ ] All Must Address findings are resolved or explicitly acknowledged in the PR description
- [ ] Final review loop introduced no new Must Fix or Must Address findings
- [ ] Diff's files-touched match the plan's declared scope; if not, drift is flagged to the human for explicit acknowledgment
- [ ] Loop outcome noted in PR description: convergence summary (`Review converged in N iterations; M Must Fix resolved, K Must Address acknowledged.`) if converged cleanly, or escalation summary if ceiling hit at 3
- [ ] If ceiling hit: remaining findings documented in PR description, or escalated to human review
- [ ] If a plan doc exists (work arrived via RPI), the Plan-drift check restated the forwarded state as a `← carried from RPI: <state forwarded>` line in the PR's Workflow provenance field; if the work is standalone (no plan doc), the line is correctly omitted (no `← carried from: none` placeholder)
- [ ] Review artifacts committed to the branch (see [PR Review Doc Inclusion guide](../guides/pr-review-doc-inclusion.md))

### Phase 2: Packaging

#### 4. Clean up commit history

```bash
git rebase -i origin/main
```

Squash WIP commits into logical chunks. Each commit in the final history should represent one coherent change that could be reviewed independently. Good commit sequence for a feature:

1. `feat: add data model for X` (reviewable alone)
2. `feat: add API endpoint for X` (builds on 1, reviewable with context)
3. `feat: add UI for X` (builds on 1-2)
4. `test: add tests for X` (or interleaved with the above)

**Completion criteria:**
- [ ] No WIP, fixup, or squash commits remain in the branch
- [ ] Each commit message follows conventional format (`feat:`, `fix:`, `refactor:`, etc.)
- [ ] Each commit represents one coherent, independently reviewable change

#### 5. Verify and annotate (parallelizable)

These two steps have no dependency on each other and can run concurrently.

**a. Verify CI passes (automated).** Run the project's checks on the rebased, reviewed code — the final form the reviewer will see. Auto-detect and run available test suites:

```bash
# Auto-detect and run available checks (run whichever apply):
[[ -f package.json ]] && npm test
[[ -f Makefile ]] && make test
[[ -f pytest.ini || -f setup.py || -f pyproject.toml ]] && pytest
[[ -f Cargo.toml ]] && cargo test
[[ -d test/ && -f test/*.bats ]] && bats test/

# If the project has a CI config, check what it runs and mirror locally:
# .github/workflows/*.yml, Makefile, package.json scripts, etc.
```

If you opened a draft PR in step 2, push the rebased branch to trigger CI remotely.

**Triage failures by class** — not every red check is a regression caused by this branch. Resist the reflex to "fix anything broken" without first identifying which class the failure belongs to:

| Class | Cause | Action |
|-------|-------|--------|
| Caused by this branch | Failure traces to code changed on this branch (new test failure, lint error in changed files, build break, type error in modified module) | Fix before merging |
| Pre-existing on main | Same failure reproduces on `main` at the merge base, or on an untouched file | File a separate issue or follow-up PR; do **not** block this PR. Note in PR description's "Areas of uncertainty" so the reviewer isn't surprised by the red check. |
| Flaky / infra | Network timeout, runner OOM, intermittent third-party dependency, known race condition | Re-run the job once. If it fails again on re-run, treat as recurrent — file a flake issue and do not block this PR on it. If it passes on re-run, note in PR description. |

**To decide between caused-by-branch and pre-existing**, run the failing check on `main` (or a fresh checkout of the merge base) before assuming the failure is yours. If the same failure appears on untouched code, it's pre-existing.

**b. Annotate the diff.** If the PR includes code in languages or libraries the reviewer may not know well, add **PR comments on your own PR** explaining non-obvious sections. This is cheaper than back-and-forth across timezones.

**Completion criteria:**
- [ ] All CI failures triaged into one of the three classes (caused-by-branch / pre-existing / flaky)
- [ ] Class (a) caused-by-branch failures: all fixed; checks now green
- [ ] Class (b) pre-existing failures: filed separately and noted in PR description (do not block PR)
- [ ] Class (c) flaky/infra failures: re-run once; recurrent flakes filed as issues and noted in PR description
- [ ] No new warnings introduced (for projects that treat warnings as errors)
- [ ] If PR uses unfamiliar libraries or patterns, at least one explanatory PR comment exists
- [ ] If no unfamiliar code, annotation step is explicitly skipped (not forgotten)

#### 6. Write the PR description

**a. Generate skeleton (automated).** Run these commands to produce a draft PR description from commit history and review artifacts. The output is a starting point — human editing is required.

```bash
# List commits grouped by conventional prefix
echo "## What this does"
echo ""
git log --oneline main..HEAD | head -20
echo ""

# Show files changed for the "How it works" section
echo "## Files changed"
git diff --name-only main...HEAD
echo ""

# Scan docs/reviews/ for artifacts on this branch
echo "## Review evidence"
BRANCH=$(git branch --show-current)
# Extract keywords from branch name (split on / and -)
KEYWORDS=$(echo "$BRANCH" | tr '/-' '\n' | grep -v '^feat$\|^fix$\|^refactor$\|^r[0-9]*$' | grep -v '^$')
for kw in $KEYWORDS; do
  # Case-insensitive match on review artifact filenames
  find docs/reviews/ -iname "*${kw}*" -type f 2>/dev/null
done | sort -u

# Scan for decision records added on this branch
echo ""
echo "## Decisions made"
git diff --name-only main...HEAD -- docs/decisions/
```

**b. Edit the skeleton (manual).** Review the generated output and reshape it into the PR description template below. The skeleton gives you raw material; your job is to add context, explain *why*, and flag uncertainty. Do not submit the skeleton as-is.

The template requires a `Decisions referenced:` line — a manual, conscious check the author fills in. This re-attempts a Round 1 rejection (commit `3dbcd78`) that tried to auto-detect citations by scanning `Relevant paths` fields in `docs/decisions/*.md`. The value here is the 5-second conscious check before opening review, not the regex — auto-detection added machinery without changing the author's behavior, so the regex was dropped and the prompt kept.

Structure:

```markdown
## What this does
[1-3 sentences: what changed and why — use the commit list as a starting point. If this PR closes an issue, you can optionally annotate the close-line with a failure-mode bracket-tag, e.g., `Closes #123 [prevents: race-condition-on-double-submit]`.]

**Workflow provenance** (optional): [e.g., "RPI → DD → RPI" or "Spike → RPI → PR-prep"]

**Failures prevented** (optional): [one-line list of the specific failure modes this change addresses, if any]

## Reviewer's path — start here
[REQUIRED. Name the 1–3 files a reviewer should open *first*, in the order they should read
them, so they understand why this change exists in under 5 minutes without reverse-engineering
the diff. Rules that make a lazy fill visibly empty rather than plausible boilerplate:
 - **Name actual files.** Each entry is a real path in backticks (`src/auth/session.ts`), not a
   category ("the auth code") or a vague gesture ("the main changes"). If you can't name a path,
   you haven't filled this in.
 - **Read-order, not import-order.** The file that frames *why* the change exists comes first;
   the files it enables come after. Lead with intent, not with the dependency graph.
 - **One sentence of intent each.** Say what the reviewer should take from the file and why it
   matters to the change — not what the file is.
 - **1–3 entries.** If no single file is the center of gravity, the PR likely needs splitting
   (see Phase 1, step 1a) — that's a signal, not a reason to leave this blank.]

## Status (optional)
[Three-field block surfacing task status without forcing reviewers to read the diff.
 Useful for stacked PRs, multi-step work, or branches that close some items but not others.
 Omit the section entirely if all planned work is done and nothing is blocked.]
- **Done:** [items completed in this PR]
- **In progress:** [items partially done or still in flight in follow-up work]
- **Blocked-on:** [items blocked, with what's blocking them — issue link, dependency, decision needed]

## How it works
[Brief technical summary. Not a line-by-line walkthrough — describe the approach.]

## How to test
[Concrete steps the reviewer can follow to verify the change works]

## Areas of uncertainty
[Flag anything you're not confident about:
 - Libraries or patterns you haven't used before
 - Performance implications you haven't measured
 - Edge cases you thought of but didn't handle]

## Decisions made
[Link to any docs/decisions/ files created, or briefly note non-obvious choices]

Decisions referenced: [list of NNN decision IDs whose invariants this PR touches, or `none — change is independent of recorded decisions`]

## Review evidence
[List review artifacts from docs/reviews/ that were generated for this PR.
 These are committed to the branch — reviewers can expand them for details.
 Example:]
- `docs/reviews/code-review-feature-name.md` — code review, all findings resolved
- `docs/reviews/self-eval-feature-name.md` — self-eval, meets criteria
```

**Commit-message footer convention** (optional): The same three-field block (`Done:` / `In progress:` / `Blocked-on:`) can be used as a commit-message footer to surface per-commit status without forcing readers to open the diff. Useful for autonomous-mode commits and stacked work where each commit lands an incremental slice.

For UI changes, capture before/after screenshots or a short recording and include them in the description. The reviewer may not be able to run the UI locally — visual evidence eliminates a round-trip.

**c. Description gate (micro-check).** Before publishing the description (marking the draft PR ready for review, or opening the PR if no draft was made), answer these three questions about the description as written:

1. **Why, not just what.** Does the description explain *why* this change exists — the problem it solves or the motivation behind it — and not only enumerate what files/lines changed?
2. **Specific tests.** Does the description list the specific tests added or run (by name, file, or scenario), rather than vague phrases like "tested locally" or "all tests pass"?
3. **Uncertainty flagged.** Does the description flag decisions made under uncertainty (in the "Areas of uncertainty" section) — judgment calls, untested assumptions, or trade-offs the reviewer may want to revisit?

If any answer is **no**, revise the description before opening the PR. This gate is fast (under a minute) and catches the most common reviewer complaints: "I can't tell why this exists," "I don't know what was actually verified," and "what did you decide that I should double-check?"

**Completion criteria:**
- [ ] Skeleton was generated from commits and review artifacts (not written from scratch)
- [ ] All six sections are present (What this does, How it works, How to test, Areas of uncertainty, Decisions made, Review evidence)
- [ ] Reviewer's path — start here is filled with 1–3 actual file paths in read-order, each with a one-sentence intent (not a category or placeholder)
- [ ] Each section contains at least one substantive sentence (not a placeholder)
- [ ] Each "Major change" line under "What this does" cites `file:test_name` evidence or carries a one-sentence `(no test: <reason>)` parenthetical (e.g., `feat: add CSV export — exports/csv.test.ts:exports_complete_rows`)
- [ ] `Decisions referenced:` line is filled in — either a list of decision IDs or the explicit `none — change is independent of recorded decisions` (the conscious check is the point; do not leave the placeholder)
- [ ] Review evidence section lists all `docs/reviews/` artifacts for this PR, or states "No review artifacts" if none exist
- [ ] Description gate (6c) passed: why is stated, specific tests listed, uncertainty flagged — or description was revised until all three are yes
- [ ] (Optional) If this PR involved multiple workflow compositions (e.g., RPI → DD → RPI), a workflow provenance line is included in "What this does"
- [ ] (Optional) If this change addresses specific failure modes surfaced by RPI/code-review failure-driven thinking, a "Failures prevented" line is included in "What this does"
- [ ] (Optional) If the branch leaves work in flight or has dependencies, a Status block (Done / In progress / Blocked-on) is included

## Retrospective

After the PR is opened, take 2 minutes to close the loop on the workflow that produced it. Save as `docs/thoughts/retro-{branch-or-feature}.md` so retros are discoverable across PRs. Commit message is acceptable for one-off observations that do not warrant a standalone file. These compound over time.

1. **Plan vs. reality** — How closely did the implementation follow the plan? Where did it deviate, and was the deviation an improvement or a sign the plan missed something?
2. **Skipped steps** — Were any workflow steps skipped or abbreviated? Why, and was that the right call in hindsight?
3. **Surprises** — What was unexpected — in the codebase, the tooling, the requirements, or the review feedback? What would have helped you anticipate it?
4. **Next time** — Knowing what you know now, what would you do differently in the plan, the process, or the code?

**Completion criteria:**
- [ ] At least one of the four questions answered with more than one sentence
- [ ] Answer saved as `docs/thoughts/retro-{branch-or-feature}.md` so retros are discoverable across PRs (commit message is acceptable for one-off observations that do not warrant a standalone file)

## Step 7: Post-merge follow-up (optional)

*These items are not required for every PR. Review the list after merge and act on whichever apply. Skip items that don't fit the change.*

After the PR merges, there are follow-up tasks that are easy to forget in the moment of completion. Scanning this checklist takes under a minute and can prevent silent regressions or stale artifacts.

**Checklist — act on what applies, skip the rest:**

- [ ] **Verify CI passes on main.** Check that the merge commit's CI run is green. Rebased PRs can still break main if another PR landed between your last push and merge (semantic conflicts, flaky tests exposed by new code paths). A quick check catches these before they compound.
- [ ] **Monitor for regressions in the first hour.** If the project has observability (error tracking, latency dashboards, log alerts), glance at them within an hour of merge. Not all bugs show up in tests — some only appear under real traffic or data patterns. Scale monitoring effort to the risk: a config change needs less watching than a new auth flow.
- [ ] **Update affected documentation.** If the PR changed user-facing behavior, CLI flags, config options, or API contracts, verify that READMEs, onboarding docs, decision records, and `docs/thoughts/` entries still reflect reality. Documentation that contradicts the code is worse than no documentation.
- [ ] **Remove feature flags if the feature shipped fully.** If the feature was gated behind a flag during development and is now fully rolled out, remove the flag and its branching logic. Leftover flags accumulate as dead code and confuse future readers.
- [ ] **Consolidate remaining open PRs if 2+ are still in flight.** If this merge leaves 2+ PRs open or stacked, the standard way to pull them into one testable branch — and resolve the conflicts the just-landed merge may have introduced — is the [Integration branch refresh](branch-strategy.md#integration-branch-refresh) in `branch-strategy.md`. Rebuild the integration branch from the canonical open-PR set rather than re-merging local branches ad-hoc; this keeps the integration branch honest after main has moved.

**This step is intentionally lightweight.** If you find yourself spending more than 5 minutes here, the items have likely surfaced real follow-up work — track that work separately rather than blocking PR completion on it.

**Post-merge actions taken** (append to `docs/thoughts/retro-{branch-or-feature}.md` so retros are discoverable across PRs; commit message is acceptable for one-off observations that do not warrant a standalone file):
- _e.g., "CI green on main after merge", "Removed `ENABLE_NEW_EXPORT` flag in follow-up commit", "No docs affected"_
