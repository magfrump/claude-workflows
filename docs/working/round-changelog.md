# Round Changelog

Human-readable per-round history of the self-improvement loop. Replaces `round-history.json` as the primary SI history record and consolidates information previously scattered across archive files.

**Usage in DD sessions:** When tracing feature lineage during divergent design, search this file for task names or idea IDs to understand how prior work informs the current decision. If you reference this file during DD, note it in the DD output to support hypothesis evaluation.

---

## Round 15

**Date:** 2026-04-09T00:54:00-07:00

### Tasks selected
- guide-staleness-audit
- skill-creation-guide
- adoption-verification-checklist

### Tasks landed
- **guide-staleness-audit** (`6cd59c8`) — Audited `workflow-selection.md` and `skill-trigger-guide.md` against current CLAUDE.md; removed deprecated bug-diagnosis routing, reordered decision tree to match current state.
- **skill-creation-guide** (`96ce673`) — Created `guides/skill-creation.md` covering frontmatter fields, prompt structure conventions, CLAUDE.md routing registration, and test fixtures.

### Tasks deferred
- **adoption-verification-checklist** — Branch exists (`origin/feat/r15-adoption-verification-checklist`) but not merged. Deferred; verification smoke tests were added to the cross-project adoption guide in R14 instead.

### Key decisions
- Prioritized guide maintenance (staleness audit) alongside new guide creation (skill-creation), reflecting a shift toward keeping existing docs accurate rather than only producing new ones.

### Feature lineage
- **skill-creation-guide** ← fills gap identified during R13 skill-result-persistence and R14 skill-portability-headers work, where skill modification patterns were undocumented.
- **guide-staleness-audit** ← driven by doc-freshness tracking infrastructure from R1 (research-doc-freshness) now being applied to guides themselves.
- **adoption-verification-checklist** ← companion to R14 cross-project-adoption-guide; deferred because R14 already added verification smoke tests inline.

---

## Round 14

**Date:** 2026-04-09T00:47:50-07:00

### Tasks selected
- ideas-backlog-staleness-sweep
- skill-portability-headers
- cross-project-adoption-guide

### Tasks landed
- **ideas-backlog-staleness-sweep** (`8574a92`) — Staleness sweep of ideas-backlog.md: rejected 4 superseded items (IB-02, IB-08, IB-09, IB-17), marked 5 stale, kept 6 open. Confirmed hypothesis from R5 (ideas-backlog-lifecycle).
- **skill-portability-headers** (`c375528`) — Added `## Dependencies` sections to `skills/code-review.md` and `skills/draft-review.md` listing sub-skills required by orchestrators.
- **cross-project-adoption-guide** (`26009eb`, `72880be`) — Created `guides/cross-project-adoption.md` with verification smoke tests. Cherry-picked directly to main rather than merge.

### Tasks deferred
- None — all three tasks landed.

### Key decisions
- Cherry-picked cross-project-adoption-guide directly to main instead of formal merge, suggesting the validation gate was bypassed or simplified for this task.
- Staleness sweep applied the 30-day rule from ideas-backlog.md for the first time, establishing a precedent for lifecycle management.

### Feature lineage
- **skill-portability-headers** ← extends R13 skill-result-persistence; both address skill documentation gaps that emerged when skills were used across projects.
- **ideas-backlog-staleness-sweep** ← implements lifecycle management first proposed when ideas-backlog.md replaced ideas.txt (IB-05, done in R10 timeframe).
- **cross-project-adoption-guide** ← new initiative; addresses the gap between "workflows work in this repo" and "workflows work in other repos."

---

## Round 13

**Date:** 2026-04-09T00:28:54-07:00

### Tasks selected
- skill-result-persistence
- rpi-research-scaffolds
- hypothesis-backlog-retirement

### Tasks landed
- **skill-result-persistence** (`dc0ac78`) — Added explicit persistence instructions (write findings with date-stamped filenames and commit metadata) to `skills/code-review.md` and `skills/security-reviewer.md`.
- **rpi-research-scaffolds** (`94bf43e`) — Added optional research-phase templates for the RPI workflow. Cherry-picked directly to main.

### Tasks deferred
- **hypothesis-backlog-retirement** — Fourth consecutive attempt (R11, R12, R13). Branch exists but not merged. The hypothesis backlog retirement work (retiring H-02, H-08, H-09 as INCONCLUSIVE-EXPIRED) appears in commits on feature branches but never landed as a formal merge.

### Key decisions
- Focused on making skills self-documenting (persistence instructions) rather than adding new skills — a maintenance-over-growth choice.
- RPI research scaffolds cherry-picked directly, similar to R14's cross-project-adoption-guide pattern.

### Feature lineage
- **skill-result-persistence** ← addresses gap found during code-review and security-reviewer usage where findings were generated but not saved, making review artifacts (docs/reviews/) unreliable.
- **rpi-research-scaffolds** ← fills the "blank page problem" in RPI research phase; IB-09 (create hypotheses before implementing) is a related rejected idea that was superseded by this scaffolding approach.
- **hypothesis-backlog-retirement** ← multi-round saga (R11→R12→R13) attempting to clean up stale TRACKING hypotheses; repeatedly deferred due to merge conflicts or scope issues.

---

## Round 12

**Date:** 2026-04-09T00:02:20-07:00

### Tasks selected
- completed-tasks-backfill
- human-workflow-quickstart
- workflow-trigger-examples
- hypothesis-backlog-retirement

### Tasks landed
- **completed-tasks-backfill** (`5bc079d`) — Backfilled `completed-tasks.md` with R8–R11 entries (plan-drift-checklist, task-decomp-briefing-patterns, effectiveness-framing, debugging-worked-examples) derived from git history and round summary files.
- **human-workflow-quickstart** (`9f9cdb7`) — Added human-oriented preamble to CLAUDE.md workflow decision tree explaining that users describe their task and Claude automatically selects the matching workflow.
- **workflow-trigger-examples** (`f48d318`) — Cherry-picked trigger examples from R11 branch onto main, adding example user requests to the workflow decision tree. Avoided stale file deletions that caused prior rejection.

### Tasks deferred
- **hypothesis-backlog-retirement** — Third attempt (R11, R12). Branch exists but not merged.

### Key decisions
- Backfilling completed-tasks.md was a meta-task: improving the SI loop's own record-keeping, which directly motivates this round-changelog format.
- Decision 009 (human-feedback-integration) was recorded during this period, replacing internal hypothesis optimization with human feedback integration.
- Workflow-trigger-examples required cherry-pick strategy to avoid conflicts from stale branch — established the cherry-pick-to-main pattern used in R13–R14.

### Feature lineage
- **completed-tasks-backfill** ← motivated by the gap noticed when completed-tasks.md only covered R1–R7; this round-changelog supersedes that approach.
- **human-workflow-quickstart** ← directly addresses IB-17 (human guide for triggering skills/workflows), which was marked rejected-as-superseded during R14 staleness sweep.
- **workflow-trigger-examples** ← originally attempted in R10 and R11; finally landed via cherry-pick in R12 after two rounds of merge conflicts.

---

## Round 11

**Date:** 2026-04-08T23:50:40-07:00

### Tasks selected
- debugging-worked-examples
- hypothesis-backlog-retirement
- workflow-trigger-examples

### Tasks landed
- **debugging-worked-examples** (`cc6ed0a`) — Created `guides/debugging-examples.md` with 3 worked scenarios: (a) good vs. bad hypothesis formation, (b) the 3-hypothesis escape hatch pivot, (c) root-cause vs. symptom fixes. Referenced from CLAUDE.md debugging section and indexed in `guides/README.md`.

### Tasks deferred
- **hypothesis-backlog-retirement** — Branch exists (`origin/feat/r11-hypothesis-backlog-retirement`) but not merged. First of four consecutive attempts.
- **workflow-trigger-examples** — Branch exists (`origin/feat/r11-workflow-trigger-examples`) but not merged in R11. Landed via cherry-pick in R12.

### Key decisions
- Debugging defaults were absorbed into CLAUDE.md directly (replacing the standalone bug-diagnosis workflow), with worked examples in a separate guide — a "show don't tell" documentation pattern.

### Feature lineage
- **debugging-worked-examples** ← grounds the debugging defaults that were written into CLAUDE.md in earlier rounds; originated from R10 where the branch was first created (`origin/feat/r10-debugging-worked-examples`) and rebased.
- **workflow-trigger-examples** ← first attempted in R10 (`origin/feat/r10-workflow-trigger-examples`); deferred here, eventually landed R12.
- **hypothesis-backlog-retirement** ← began a 4-round journey (R11→R14) of attempting to clean up expired hypotheses; the repeated deferral itself became evidence that the hypothesis tracking infrastructure had accumulated debt.
