
## Round 1

- **epistemic-dd-trigger**: Added row 3 to the CLAUDE.md workflow decision tree: an epistemic DD trigger that fires on explain/theorize/hypothesize tasks, directing to divergent-design.md's Epistemic Reasoning variant section.
- **webapp-testing-guidance**: Added runtime verification guidance (Step 6) to ui-visual-review skill: screenshot capture procedures, cross-resolution verification checklist at 5 breakpoints, browser console log analysis steps, and visual regression detection workflow, with report template extensions for tracking static-vs-runtime analysis accuracy.
- **skill-workflow-boundary-ref**: Added a "When to create a workflow vs. a skill" section to guides/skill-creation.md covering the original distinction, how the boundary has shifted (bug-diagnosis deprecation, DD-as-sub-procedure, orchestrator skills), decision criteria for new additions, and a full inventory table of current workflows/skills with form-factor-fit notes.
- **round-changelog**: Created docs/working/round-changelog.md with structured per-round entries for R11–R15 including tasks selected/landed/deferred, key decisions, and feature lineage, replacing scattered archive files as the primary human-readable SI history.

## Round 2

- **dd-candidate-quality-heuristics**: Added a generation health check to DD step 1 (Diverge) that flags candidate clustering, missing perspectives, and excessive vagueness — framed as generation assistance to preserve the "no evaluation yet" principle, with a note in the epistemic variant to apply the same checks to hypotheses.
- **spike-output-template**: Added a concrete inline example to spike.md step 4 showing a filled-in spike conclusion with Question, Answer (partial go), Key Findings, RPI Seed, and Limitations sections.
- **pr-prep-review-loop-timeout**: Added a firm 3-iteration termination bound to the pr-prep review-fix loop (step 3e) with two exit paths — ship with documented known issues or escalate to human review — and updated review-fix-loop.md to match, mirroring the debugging 3-hypothesis escape hatch pattern.
- **rpi-scope-narrowing-defaults**: Added research sufficiency signals (minimum coverage criteria + stop-researching triggers) to RPI step 2 as additive guidance for calibrating research effort, with optional transition annotations to support hypothesis evaluation.
- **hypothesis-backlog-retirement**: (no summary generated)
- **hypothesis-evidence-analysis**: (no summary generated)

## Round 3

- **r3-onboarding-staleness-completion**: Added staleness signals (4 concrete refresh triggers with git commands) and onboarding sufficiency criteria (3 handoff-readiness checks) to codebase-onboarding.md, following the R2 pattern of adding stopping/refresh criteria to workflows.
- **r3-user-testing-when-to-pivot**: Added a 'When to pivot' section to workflows/user-testing-workflow.md with handoff guidance for three transitions: → RPI (findings identify a feature/fix), → DD (findings reveal 3+ redesign directions), and ← From RPI (implementation needs usability validation before shipping).
- **r3-draft-review-tool-name-fix**: Replaced all 8 occurrences of 'Task tool' with 'Agent tool' in skills/draft-review.md to match the current Claude Code tool name used in code-review.md and matrix-analysis.md.
- **r3-fact-check-confidence-calibration**: Added a "Confidence Calibration" section to skills/fact-check.md defining High (primary source), Medium (multiple secondary sources or strong inferential chain), and Low (single source, indirect inference, or conflicting signals) confidence levels, and updated the inline step 4 to reference it and require citing which criterion applies.

## Round 4

- **r4-task-decomposition-examples**: Re-attempted R3 task: created guides/task-decomposition-examples.md (reusing R3 content) and added the missing guides/README.md index entry that caused the R3 guide-index-sync.bats failure.
- **r4-skill-creator-audit-readonly**: Audited 5 skills against Anthropic guidelines, identified 7 format divergences, output to guides/skill-format-audit.md with README index entry — read-only, no skill files modified.
- **r4-dd-stress-test-triggers**: Standardized all 7 stress-test moves in divergent-design.md step 4 with explicit "When to use" trigger sentences, replacing the inconsistent "Best for" column to enable deliberate move selection based on decision context.
- **r4-code-review-critic-table**: Extracted code-review.md's contextual critic auto-selection logic from prose bullets into a structured `| Diff characteristic | Critic to invoke | Rationale |` trigger table, matching CLAUDE.md's skill routing format for auditability and consistency.
- **r4-pr-prep-workflow-provenance**: Added an optional "Workflow provenance" one-liner to the PR description template in pr-prep.md (inside "What this does") with a matching optional checklist item, so reviewers of multi-workflow PRs can see the path taken (e.g., "RPI → DD → RPI") without adding overhead to simple PRs.
- **r4-spike-feasibility-criteria**: Added optional feasibility criteria template (Success/Failure/Ambiguous) to spike.md step 1 for binary yes/no spike questions, framed as opt-in so exploratory spikes aren't forced into binary framing.

## Round 5

- **r5-rpi-from-testing-handoff**: Added `← From Testing` pivot entry to RPI's "When to pivot" section, creating a symmetric inbound handoff for user-testing-workflow's existing outbound `→ RPI` pivot — severity-rated findings and prioritization matrix replace broad exploration when testing surfaces a feature or bug.
- **r5-draft-review-disagreement-protocol**: Added factual vs. perspective-based disagreement classification framework to draft-review.md Stage 3 synthesis, so critics' conflicts get triaged (escalate to fact-check or present both sides) instead of just surfaced.
- **r5-fact-check-source-ranking**: Added a Source Ranking subsection to fact-check.md's Confidence Calibration section: primary sources outrank secondary by default, source conflicts must be noted explicitly with reasoning, and deviations from the hierarchy require explanation.
- **r5-onboarding-architecture-format**: Added a suggested three-section output structure (subsystem inventory, data flow, external dependencies) to codebase-onboarding.md step 2, framed as a recommended default rather than a mandatory format, to improve architecture map consistency for downstream RPI consumption.
- **r5-security-reviewer-escalation**: Added "Critical Finding Escalation" section to security-reviewer.md with 5 halt-and-escalate patterns (plaintext secrets, missing auth, injection, disabled TLS, hardcoded keys) and a prescribed escalation output block format.
- **r5-code-review-large-diff-triage**: Added large-diff triage guidance (~1000+ lines) to code-review.md's scoping section: split reviews into multiple passes by subsystem, prioritize highest-risk files (auth, data handling, public API) first, and note the triage in the plan summary for auditability.
- **r5-spike-abandon-signals**: Added three named abandon signals (no convergence, scope drift, wrong question) to spike.md between the timebox and throwaway-space steps, each with a specific action, so spikes stop early with a clear reason rather than running to timebox exhaustion.

## Round 6

- **r6-fact-check-ai-awareness**: Added an "AI-Generated Draft Awareness" section to skills/fact-check.md that directs the fact-checker to apply heightened scrutiny to specific numbers, named studies, and attributed quotes when the draft is AI-generated, with observable output markers (header annotation + per-claim notes) so activation can be confirmed in future invocations.
- **r6-performance-reviewer-hot-path**: Added hot-path gate to performance-reviewer.md scoping section: findings in cold paths (startup, config, migrations) default to Low/Informational severity, and reviewers must explicitly state path temperature in each finding for downstream verifiability.
- **r6-dd-from-bug-diagnosis**: Added '← From Bug Diagnosis' pivot entry to workflows/divergent-design.md: when debugging reveals a design-level root cause with 3+ viable fix approaches, invoke DD directly, carrying the diagnosis log's root-cause analysis and failed hypotheses as constraints.
- **r6-user-testing-unmoderated-note**: Added a blockquote note to the Phase 0 Logistics Checklist in user-testing-workflow.md explaining how unmoderated remote sessions adapt the moderator script, pilot testing, and analysis phases.
- **r6-draft-review-small-draft-guidance**: Added guidance after Step 2 in skills/draft-review.md: for short drafts (<500 words) or narrowly scoped technical pieces, use only the 1–2 most relevant critics and explicitly note the reduced panel in the user-facing plan.
- **r6-task-decomp-recompose-check**: Added step 4 (reconcile conflicting assumptions) to task-decomposition.md between dispatch and synthesize, requiring the orchestrating agent to check for contradictions about shared interfaces across sub-investigations and document findings in a Reconciliation heading before merging into a unified plan.

## Round 7

- **r7-fact-check-code-claims**: Added "Code-Based Claims" subsection to fact-check.md's "How to check each claim" section, directing the checker to use file reading and grep (not web search) for claims about the codebase itself, while preserving web search for non-code claims.
- **r7-security-reviewer-dep-trigger**: Added dependency manifest trigger to security-reviewer.md: new cognitive move #10 checks for newly added deps (maintenance/popularity), major version bumps (CVEs), unexplained lockfile churn, and removal of security-relevant packages; findings use `[Dependency change]` prefix for traceability.
- **r7-onboarding-monorepo-scoping**: Added monorepo scoping guidance to codebase-onboarding.md step 2: scope architecture mapping to the task-relevant package, note the top-level dependency graph, and list unexamined packages in Known Unknowns (step 5).
- **r7-pr-prep-post-merge-retrospective**: Added post-merge sub-question (#5) to pr-prep.md's existing Retrospective section, covering CI-on-main, monitoring alerts, and feature flag cleanup for PRs that change production behavior.
- **r7-code-review-incremental-recheck**: Added incremental re-review guidance to pr-prep.md step 3d: on iterations 2+, scope re-review to git diff of fix commits plus targeted verification of prior Must Fix findings, with fallback to full re-review when fixes are broad.
- **r7-draft-review-fact-critic-crossref**: Added fact-critic cross-referencing to draft-review.md Stage 3: before synthesizing, each critic's key claims are checked against fact-check verdicts, and critiques depending on Inaccurate/Unverified claims are caveated rather than presented as standalone analysis.
- **r7-spike-finding-promotion**: Added finding-promotion guidance after spike.md step 4: promote lasting discoveries (library limitations, undocumented API behavior, ruled-out approaches) to docs/thoughts/ with freshness fields before deleting the spike branch.
- **r7-onboarding-lightweight-refresh**: Added 'Lightweight refresh' subsection under codebase-onboarding.md's 'When to re-run' section with clear criteria for when a targeted refresh (review git log, update Architecture Map and Known Unknowns, bump Last verified) is proportionate vs. when a full 7-step re-run is needed.

## Round 1

- **ui-visual-review-3d-viewport**: feat(skills): add 3D viewport rendering subsection to ui-visual-review
- **fact-check-quote-attribution**: feat(fact-check): add Quote attribution section with Secondary-only verdict
- **bug-diagnosis-env-failure-step-zero**: docs(bug-diagnosis): add step 0 to verify failure isn't preexisting
- **design-space-situating-skill**: feat: add design-space-situating skill
