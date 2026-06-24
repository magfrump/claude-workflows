# LIVE-branch triage — 2026-06-24

Triaged the 111 kept branches (106 LIVE + 5 UNSURE-kept) from the branch audit against the owner's value lens: external workflow/skill impact = high; SI-loop introspection/observability = deprioritized; token-tracking deprecated; shellcheck-dodge retired; DD additions must clear a real-improvement bar.

| Verdict | Count | Meaning |
|---|---|---|
| MERGE | 44 | Valuable AND applies cleanly/near-cleanly to current main |
| REWORK | 30 | Valuable idea, but built on a restructured base — re-apply rather than cherry-pick |
| RETIRE | 37 | Low value under the lens (SI introspection, deprecated, shellcheck-dodge, slimming-only, moot) — recommend deletion |

## Dedupe before landing
- **cowen-technical-draft** idea appears 3×: `r1-r1-cowen-yglesias-tech-draft-calibration`, `r5-r5b-cowen-technical-draft`, `r6-cowen-technical-draft-note` (all REWORK) — keep one.
- **rpi-checkpoint-freshness** appears 2×: `r2-rpi-checkpoint-freshness`, `r4-r8-rpi-checkpoint-freshness` (both MERGE) — keep one.
- **pr-prep MERGE cluster** (reviewer-orientation, test-evidence-bounded, scope-drift-check, task-status, failures-prevented, decision-citation) each edits the same pr-prep "six sections present" completion line; they apply cleanly individually but collide with each other — **sequence them**, don't land in parallel.

## MERGE — HIGH value (do first)

- **feat/r2-pr-prep-ci-triage** — CI-failure triage-by-class table (caused-by-branch / pre-existing / flaky) applies cleanly to current pr-prep and meaningfully improves PR-prep external behavior.
- **feat/r2-pr-prep-reviewer-orientation** — Adds a required Reviewer's-path start-here PR section (named files in read-order) that directly improves reviewer experience; both pr-prep anchors still exist verbatim in main so it applies cleanly.
- **feat/r5-r5b-task-decomp-quality-signals** — Pre-dispatch coupling signals (shared mutable state, >2 shared interfaces, cross-package imports) catch bad decompositions before they waste parallelism; high external value, only minor context conflicts.

## MERGE — MED/LOW (clean small wins)

- `feat/r1-r1-pr-prep-retro-doc-convention` — Establishes docs/thoughts/retro-{branch-or-feature}.md naming so retros are discoverable; the exact old "docs/thoughts/ or a commit message" text it edits is still present verbatim in main, applies cleanly.
- `feat/r1-r1-review-fix-loop-convergence-summary` — Symmetric convergence-summary PR line gives reviewers a calibration signal on clean exits; edits the still-verbatim main Tracking text, applies cleanly.
- `feat/r1-r1-rpi-back-from-dd-pivot` — Adds an implementation-time "← From Divergent Design" back-pivot entry to RPI's When-to-pivot list; the list exists in main with no such entry, applies cleanly.
- `feat/r1-r1-spike-testability-gate` — Two-line "operationalize the question before timeboxing" check for spike step 1 applies cleanly to current workflows/spike.md and improves the spike workflow's external output.
- `feat/r1-r1-user-testing-dd-handoff-convention` — One-line edit telling user-testing to emit docs/working/testing-findings-{topic}.md before the DD pivot; applies cleanly and improves the user-testing-to-DD handoff.
- `feat/r1-user-testing-contrastive-analysis` — Adds a Step 1.5 contrastive success/struggle pair analysis to user-testing; applies cleanly to current main and meaningfully improves the workflow's analysis output.
- `feat/r2-dd-scoring-rubric` — Tightens both DD compatibility-matrix glyph keys to one-meaning-each; applies cleanly to current divergent-design.md and makes DD scoring output more consistent.
- `feat/r2-onboarding-dd-double-diamond-handoff` — Adds a from-scratch redirect from onboarding to the DD Double Diamond variant; applies cleanly and improves onboarding's external routing for framing-stage projects.
- `feat/r2-pr-prep-decision-citation-checklist` — Adds a "Decisions referenced:" PR-template line and checklist item (conscious check, regex dropped); applies cleanly and supports the owner's DD-decision-traceability interest.
- `feat/r2-pr-prep-failures-prevented-line` — Adds an optional "Failures prevented" PR-description line plus checklist item; applies cleanly to current pr-prep and surfaces failure-driven value in PRs.
- `feat/r2-pr-prep-test-evidence-bounded` — Adds a per-Major-change file:test_name evidence requirement with no-test waiver to the PR template; the six-sections completion anchor still exists in main so it applies cleanly.
- `feat/r2-r2-pr-prep-scope-drift-check` — Single checklist line flagging diff-files-vs-plan-scope drift to the human; its completion-criteria anchor exists verbatim in main and adds genuine reviewer value.
- `feat/r2-r2-task-status-block` — Optional Done/In-progress/Blocked-on PR status block plus commit-footer convention; anchors present in main, useful for stacked and autonomous-mode work.
- `feat/r2-rpi-checkpoint-freshness` — One-line checkpoint Date freshness git-log check mirroring the doc-freshness pattern; the Continuation bullet it edits exists verbatim in main so it applies cleanly.
- `feat/r3-claude-api-failure-modes-line` — Adds a new in-repo skills/claude-api.md supplement with common API integration failure-modes guidance; new file, applies clean with no conflict.
- `feat/r3-dd-diamond1-healthcheck-examples` — One-line enrichment adding worked examples (downstream-consumer perspective, schedule-dimension anchoring) to the DD framing health check; target line matches main verbatim, applies cleanly.
- `feat/r3-dd-diamond1-stakeholder-scope-grid` — Adds a stakeholder/scope coverage matrix to DD framing diagnosis that forces multi-perspective candidate framings; clears the real-improvement bar and applies cleanly to main's framing list.
- `feat/r3-dd-step1-failure-mode-bullet` — One diverge bullet enabling failure-driven generation (8-15 failure modes become hard constraints) for bug-fix/security/reliability design; cleanly applies and improves DD output for hardening tasks.
- `feat/r3-dd-step2-success-criterion-required` — Requires an observable success line per hard constraint with worked good/bad examples, making the step-3 compatibility matrix actually scorable; anchor text still present in main so it applies near-cleanly.
- `feat/r3-onboarding-fromscratch-dd-pointer-v3` — Single optional sentence pointing from-scratch onboarding at DD's Double Diamond variant; cheap, external-facing crosslink that applies cleanly.
- `feat/r3-r3-dd-post-decision-fragility-note` — Adds a one-line decision-fragility marker naming the evidence whose change would flip the decision, pairing with the existing anti-portfolio to make DD records auditable; applies cleanly.
- `feat/r3-r3-onboarding-task-purpose-context` — Captures onboarding intent before subsystem mapping and threads it into sub-agent briefs so notes scope to the actual purpose; meaningfully improves onboarding output and applies cleanly.
- `feat/r3-r3-rpi-reference-not-duplicate` — Plan-doc guidance to link DD/spike records rather than copy their rationale; sensible external workflow improvement that applies cleanly to RPI.
- `feat/r3-r3-task-decomp-dispatch-example` — Adds a concrete end-to-end parallel-dispatch-and-recompose example to task-decomposition; improves workflow usability and applies cleanly.
- `feat/r3-workflow-transition-handoff-line-narrowed` — Adds a conditional "carried from RPI" provenance line to pr-prep's plan-drift check so reviewers see originating decisions without re-deriving; applies cleanly to current workflows/pr-prep.md and improves external PR output.
- `feat/r4-onboarding-sub-agent-canonical-form` — Restructures onboarding sub-agent briefing around the canonical goal-preamble + scope spec + verbatim success-criterion restatement; applies cleanly and meaningfully improves the dispatched sub-agent output and synthesis quality.
- `feat/r4-r8-dd-prior-decision-seed` — Seeds the prior CHOSEN decision as candidate 0 in DD divergence so the team explicitly weighs reuse-vs-re-derive; two-line clean addition that improves DD output, distinct from main's pruned-candidate grep.
- `feat/r4-r8-onboarding-section-index` — Adds a one-line section index to onboarding orientation docs so downstream RPI sessions load only relevant sections; applies cleanly to current codebase-onboarding.md and improves doc usability.
- `feat/r4-r8-pr-prep-escalation-template` — Adds a consistent escalation-summary markdown template to pr-prep's convergence-ceiling exit; applies cleanly and standardizes external escalation output.
- `feat/r4-r8-rpi-checkpoint-freshness` — Adds a git-log staleness check when loading a prior-session checkpoint, closing a gap main only covers for research docs; applies cleanly to research-plan-implement.md.
- `feat/r4-r8-task-decomp-evidence-priority` — Adds an [observed]>[inferred]>[assumed] conflict-resolution rule with escalate-on-tie to task-decomp reconciliation; clean two-line addition that sharpens cross-investigation conflict handling.
- `feat/r4-si-implementation-dispatch-preamble` — Replaces bare "Task: $DESC" in the SI implementer dispatch with a User-goal/Current-task/Success-criterion preamble; applies cleanly and improves the actual implementer-agent output (external-facing dispatch quality, not loop introspection).
- `feat/r4-task-decomp-canonical-goal-preamble` — Rewrites task-decomp briefing to mandate the orchestrated-review goal preamble + Goal-Alignment Note; applies cleanly to current task-decomposition.md and improves dispatched sub-agent output and reconciliation.
- `feat/r5-dry-run-mode` — Adds a --dry-run flag exiting after task selection with a summary — genuine testing/inspection value for the SI script (lets a run be validated without worktrees/implementation); applies cleanly to self-improvement.sh.
- `feat/r5-r5b-pr-prep-description-gate` — Adds a fast 3-question PR-description micro-check (why-not-what, specific tests, uncertainty flagged) to pr-prep; applies cleanly and improves reviewer-facing output.
- `feat/r5-r5b-rpi-assumed-closeout` — One-line RPI commit-checklist item closing out [assumed] research claims; small external workflow improvement, only a trivial context conflict to resolve.
- `feat/r5-r5b-spike-timebox-defaults` — Per-spike-type timebox anchor table (API check/library eval/cross-cutting) usefully concretizes the generic 30-min default; applies cleanly.
- `feat/r5-r5b-task-decomp-output-template` — Recommended 5-section sub-agent output scaffold reduces reconciliation overhead in task-decomposition; applies cleanly.
- `feat/r6-branch-strategy-conflict-prevention` — Adds a pre-branch overlap-scan procedure (git diff --name-only across feat/* branches) with parallelize/sequence heuristics; clean and externally useful for multi-branch work.
- `feat/r6-pr-prep-scope-drift` — Scope-drift re-review rule (file follow-up, decline non-blocker changes) tightens the review-fix loop; applies with one trivial context conflict.
- `feat/r6-rpi-bug-fix-sufficiency-bullet` — Bug-fix research-sufficiency bullet (root cause named / code location / why tests missed it) gives a concrete stop condition; applies cleanly.

## REWORK (valuable, needs re-applying to restructured base)

- `feat/r1-code-review-rewrite-profile` (HIGH) — Adds a rewrite-vs-diff review profile that genuinely changes what critics evaluate on near-total rewrites (real external impact), but targets the flat skills/code-review.md that became skills/code-review/SKILL.md.
- `feat/r1-dd-multi-lens-variant` (MED) — Skeptic/simplifier/contrarian parallel-lens DD generation variant widens the candidate set, but DD was restructured and this should be re-applied to current divergent-design.md.
- `feat/r1-failure-driven-design-workflow` (MED) — New failure-driven-design workflow with generative-vs-evaluative framing is a real workflow addition, but its CLAUDE.md routing-table rewrite (renumbering all rows) collides with main's restructured decision tree and needs re-application.
- `feat/r1-onboarding-coupling-matrix` (MED) — Optional subsystem coupling-matrix bullet improves the onboarding Architecture Map output for downstream change-scoping, but onboarding was restructured to 13 steps and needs re-anchoring.
- `feat/r1-onboarding-from-scratch-branch` (MED) — From-scratch gate plus project-charter path stops onboarding mis-firing on empty repos (real output improvement), but must be reslotted into main's restructured 13-step onboarding.
- `feat/r1-onboarding-serialization-addendum` (MED) — Data-serialization onboarding addendum (source/target/conversion/lossy-vs-lossless) directly fits the owner's board-game-digitization interest, but targets the restructured onboarding doc.
- `feat/r1-pr-decision-record-citation` (MED) — Decisions-cited scan surfaces invariant drift to reviewers at PR time, but adds a 7th template section to main's now-six-section pr-prep template and needs re-application.
- `feat/r1-pr-prep-reviewer-orientation` (MED) — Required reviewer's-path section orients reviewers fast (external review impact), but adds a 7th section to main's restructured six-section pr-prep template.
- `feat/r1-pr-prep-test-evidence` (MED) — Per-major-change test-evidence requirement makes test gaps visible at PR time, but adds a 7th section to the restructured pr-prep template and needs re-application.
- `feat/r1-r1-code-review-accurate-summary` (MED) — Prepending an accurate-claims summary when truncating fact-check output preserves verified-claim signal for downstream critics, but targets the flat skills/code-review.md that became a SKILL.md dir.
- `feat/r1-r1-cowen-yglesias-tech-draft-calibration` (MED) — Technical-draft move-prioritization note for cowen/yglesias critics improves critique fit, but targets the flat skill files now under SKILL.md dirs (and overlaps later LIVE technical-draft siblings).
- `feat/r1-r1-dd-lens-checklist` (MED) — Optional six-lens generation checklist widens DD candidate search, but should be re-applied to the restructured divergent-design.md diverge step.
- `feat/r1-r1-onboarding-entry-point-churn-trigger` (MED) — One-sentence escalate-to-full-rerun-on-entry-point-churn refinement to the onboarding lightweight refresh is valuable but the refresh step was restructured; re-apply to current main.
- `feat/r2-fact-check-temporal-anchor` (MED) — Valuable "Accurate as of <date>" verdict subtype for time-bound claims, but targets the old flat skills/fact-check.md (main is skills/fact-check/SKILL.md) so it needs re-application.
- `feat/r2-review-fix-loop-override-noise` (MED) — Valuable override-log Won't-Fix noise-suppression for the review loop (override-log is live in main code-review), but review-fix-loop.md was restructured and the target anchors are absent, so re-apply.
- `feat/r2-review-fix-non-convergence` (MED) — Useful a/b/c non-convergence cause taxonomy for escalation, but the review-fix-loop.md anchors are gone in main (restructured); pr-prep half applies, re-apply against current base.
- `feat/r2-spike-framing-patterns` (HIGH) — Strong external improvement (three spike framings: binary/comparison/exploration with format conventions), but main already restructured the feasibility-criteria block the branch rewrites, so re-apply.
- `feat/r2-task-schema-path-validator` (MED) — Real fix for the 50%-task-loss bug (rejects absolute/home/traversal paths in files_touched), genuine behavior; but validate_task_json moved to scripts/lib/si-functions.sh in main, so transplant the logic there.
- `feat/r2-ui-visual-review-semantic-a11y` (MED) — Adds a WCAG-grounded semantic-accessibility checklist (item 8) that improves external review output, but it edits the old flat skills/ui-visual-review.md which main restructured into a SKILL.md directory.
- `feat/r2-workflow-transition-handoff-line` (MED) — Defines the cross-workflow carried-from marker across DD/RPI/pr-prep for handoff continuity; the RPI anchor still exists but the change spans three restructured files, so re-apply as one coherent pass.
- `feat/r3-r3-dep-upgrade-security-crosslink` (MED) — Good idea (run security-reviewer on the upgrade diff before recommending merge) but targets the removed flat skills/dependency-upgrade.md; re-apply to skills/dependency-upgrade/SKILL.md.
- `feat/r3-r3-tech-debt-rpi-handoff` (MED) — Good workflow-composition idea (Fix-now routes to RPI for non-trivial remediations) but targets the removed flat skills/tech-debt-triage.md; re-apply to skills/tech-debt-triage/SKILL.md.
- `feat/r3-r3-yglesias-non-policy` (MED) — Useful prioritization guidance for non-policy/engineering drafts (the repo's own use case) but targets the removed flat skills/yglesias-critique.md; re-apply to skills/yglesias-critique/SKILL.md.
- `feat/r4-r8-draft-review-ensemble-threshold` (MED) — Numeric N/N agreement threshold table replacing qualitative convergence prose is a real output improvement, but targets flat skills/draft-review.md (now skills/draft-review/SKILL.md, which still has the old prose) — re-apply to the restructured file.
- `feat/r4-r8-fact-check-chunking` (MED) — Useful >30-claim chunking guidance to prevent shallow verdicts, but targets flat skills/fact-check.md (now skills/fact-check/SKILL.md, where it is absent) — re-apply to the restructured SKILL.
- `feat/r4-r8-ui-review-guideline-discovery` (MED) — Multi-path guideline discovery (ui-guidelines.md/design-system.md/STYLE.md + grep) reduces false positives, but targets flat skills/ui-visual-review.md (now skills/ui-visual-review/SKILL.md, still single-path) — re-apply to the restructured SKILL.
- `feat/r5-r5b-code-fact-check-stale-patterns` (MED) — Genuinely useful high-frequency stale-comment patterns for code-fact-check, but edits the flat skills/code-fact-check.md that main restructured into skills/code-fact-check/SKILL.md, so it must be re-applied.
- `feat/r5-r5b-cowen-technical-draft` (MED) — Valuable technical-draft move-prioritization for cowen-critique but targets the flat skills/cowen-critique.md (now a SKILL.md dir) and overlaps the r6 sibling; re-apply one of the two.
- `feat/r5-r5b-perf-micro-macro` (MED) — Strong Micro/Macro x Hot/Cold severity-calibration matrix for performance-reviewer, but edits the flat skills/performance-reviewer.md that main moved to a SKILL.md dir.
- `feat/r6-cowen-technical-draft-note` (MED) — Same technical-draft prioritization idea as the r5 sibling, slightly fuller; targets flat skills/cowen-critique.md (now a SKILL.md dir) — re-apply one version, not both.

## RETIRE (recommend deletion — low value under the lens)

- `feat/r1-calibration-report-script` — Standalone hypothesis-calibration script parsing the removed docs/working/hypothesis-log.md; pure SI-loop introspection/measurement, deprioritized per the value lens.
- `feat/r1-hypothesis-mandatory-odds` — Adds an odds_ratio field to the SI task prompt and the removed hypothesis-log.md for calibration data; internal SI measurement plumbing, deprioritized.
- `feat/r1-r1-claude-api-streaming-thinking` — Adds an in-repo skills/claude-api.md supplement, but the claude-api skill in main is a bundled binary skill with no in-repo file, so the supplement is orphaned with nowhere canonical to live.
- `feat/r1-si-cycle-framing-record` — Per-cycle self-referential framing record is pure SI-loop introspection with no external workflow output.
- `feat/r1-si-duplicate-detector` — Near-duplicate candidate surfacing is explicitly "informational" SI-loop observability, not external output.
- `feat/r1-si-input-failure-prompt` — Adds a failure-modes section to the SI input template plus a non-existent templates/si-input.md; SI-loop plumbing, no external impact.
- `feat/r1-si-null-result` — Lets an SI round legitimately produce no tasks; internal loop-control plumbing with no external workflow output, and competes with an unmerged sibling.
- `feat/r1-si-pre-round-health-check` — Repo-integrity pre-round gate is SI-loop observability/plumbing; duplicate of an unmerged sibling, neither adopted.
- `feat/r1-si-value-revisit` — Logs whether shipped features retained value as a lagging self-measurement signal; pure SI introspection.
- `feat/r2-convergence-transparency-report` — Self-describes as "output-only, does not change the gate decision" — textbook SI transparency-report introspection.
- `feat/r2-hypothesis-evaluation-automation` — LLM-free hypothesis evidence-gathering for human review is SI-loop introspection plumbing; built on a hypothesis mechanism largely removed by main's three-phase SI rewrite.
- `feat/r2-morning-summary-intentionality-aids` — Morning-summary YES/NO adjudication aids are SI observability; area was heavily restructured in main, and the value is internal legibility.
- `feat/r2-mvp-process-headers` — Adds "Quick Version" summary headers to workflow docs — a legibility/slimming aid that doesn't change external output, and one target file (bug-diagnosis) was removed from main.
- `feat/r2-r2-hypothesis-pipeline-integrity` — Health-check #12 hypothesis-pipeline-integrity plus bats is SI-loop observability plumbing with no external workflow-output change.
- `feat/r2-r2-hypothesis-surfacing-fix` — _count_surfaceable_hypotheses morning-summary surfacing-regression guard is internal SI introspection, not external output quality.
- `feat/r2-r2-si-round-purpose-header` — Per-task-agent round-purpose header in self-improvement.sh is SI-loop legibility/introspection plumbing, deprioritized.
- `feat/r2-si-cycle-framing-shellcheck-clean` — Per-cycle cycle-framing record emitter with a shellcheck-clean slug — introspection framing-record plumbing plus shellcheck-dodge framing, deprioritized.
- `feat/r2-si-emits-integration-refresh` — run_integration_refresh wires branch-strategy integration refresh into the SI loop; internal loop machinery, not external workflow/skill output.
- `feat/r2-si-seed-addressed-echo` — Seed adoption-gap echo (compute_seed_addressed_map / _summary_seed_adoption_gaps) is SI transparency-report plumbing, deprioritized.
- `feat/r3-morning-summary-stale-inconclusive-archive` — SI morning-summary internal plumbing (surfaces stale INCONCLUSIVE hypotheses); deprioritized observability with no external workflow-output impact.
- `feat/r3-post-merge-verification` — SI merge-loop guard detecting empty-diffstat merges; internal SI plumbing, deprioritized rule.
- `feat/r3-pr-prep-decision-citation-mechanized` — R3 re-attempt of a decision-citation idea its own embedded note records as rejected in R1 and R2; heavy grep machinery for marginal external value.
- `feat/r3-r3-dd-stress-test-deltas` — Adds a stress-test delta logging subsection to DD records; record-keeping/observability rather than better decision output, and self-guarded to often be empty.
- `feat/r3-r3-persona-selection-log` — Adds a considered-but-not-selected personas log for auditability; introspection plumbing and also targets the removed flat skills/ai-personas-critique.md.
- `feat/r3-r3-pr-prep-registered-hypothesis` — Adds a Falsifiable-expectation PR line to register hypotheses for self-measurement; SI-introspection-flavored, deprioritized.
- `feat/r3-r3-si-task-prompt-goal-preamble` — Reframes the SI implementer dispatch prompt with a goal preamble; SI-internal, deprioritized rule.
- `feat/r3-r3-tasks-schema-scope-required` — Adds a required scope enum field to the SI task schema; SI-internal plumbing, deprioritized rule.
- `feat/r3-si-cycle-framing-python-only` — Explicit shellcheck-gate-dodge (Python rewrite to route around the gate) producing an internal cycle-framing line, deliverable-shaped but unwired — exactly the introspection+gate-dodge pattern the rubric retires.
- `feat/r3-tests-gate-failure-isolation-task` — SI-internal tests-gate-skip recognizer primitives that ship unwired (consumer in self-improvement.sh never updated); pure loop plumbing with no external output change.
- `feat/r4-failure-analysis-automation` — Wires failure-analysis.sh auto-invoke on rejected SI tasks into the validation log — SI-internal observability plumbing feeding the hypothesis dashboard, deprioritized per the rubric.
- `feat/r4-hypothesis-survey-runner` — Interactive terminal survey runner for resolving internal SI hypotheses; violates the non-interactive SI constraint and is pure self-improvement-loop introspection.
- `feat/r4-r8-bug-diagnosis-hypothesis-prompts` — Targets workflows/bug-diagnosis.md, which was removed from main (decision 013) — moot; the hypothesis-generation prompts have no surviving file to land in.
- `feat/r4-slim-workflow-companions` — Adds parallel workflows/slim/ companion files — context-slimming for its own sake, which the rubric explicitly says not to over-value; doubles maintenance surface with no external output improvement.
- `feat/r5-si-implementer-validation-aware-success` — Pure SI-loop plumbing — surfaces the loop's own validation gates to the implementer dispatch; no change to any external workflow/skill output.
- `feat/r5-workflow-complexity-reduction` — Extracts user-testing appendices into a separate file — slimming for its own sake, which the value lens explicitly deprioritizes; also conflicts with main.
- `feat/r6-seed-context-enrichment` — Injects gate pass/fail rates into the DD idea-generation prompt, but this is internal-measurability bias fed back into the SI loop (the deprioritized pattern) rather than a DD-output-quality win the user sees; also conflicts with main.
- `feat/r9-usage-data-analysis-boring` — Tracking-doc bookkeeping moving H-01/H-05/H-07 to INCONCLUSIVE; pure SI introspection/self-measurement with no external output change.
