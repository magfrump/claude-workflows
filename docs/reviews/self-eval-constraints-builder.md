Commit: 2b34eced (the pre-split branch tip, no longer reachable; the same patch is the first u3 commit after the split)

# Self-Evaluation: constraints-builder

**Target:** `skills/constraints-builder/SKILL.md`, plus `references/reader-brief.md`, `references/working-doc-template.md`, and the pointer edits in `workflows/codebase-onboarding.md` and `skills/dev-cycle/SKILL.md` | **Type:** Skill | **Evaluated:** 2026-10-19
**Evaluator:** Automated (self-eval skill, opus subagent) — human review required for flagged dimensions. This file was condensed by the orchestrator from the returned report, because subagents may not write report files here.

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | Many properties are mechanical: the draft parses, `docs/constraints.md` is not written, the template sections are present, every H has a `success:` line, and a ratify entry is filed. The planted-trap fixtures in the iteration-1 eval show such tests are cheap. The core value is judgment, which needs a human or a long-horizon check (the sort, and loop design quality). |
| Trigger clarity | Adequate | The create path is clear: both emitters (onboarding:455 and dev-cycle step 10) name the skill. The amend path was fuzzy when evaluated: its triggers lived only in this skill. *(Fixed later in u3: the drift check and the deep audit now name amend mode.)* |
| Overlap and redundancy | Strong | No other skill drafts a repo-wide constraints doc. It reuses DD step 2's success-line rule rather than restating it. The nearest neighbour is code-fact-check, which the notes suggested for verification. |
| Test coverage | Weak | No bats tests for the skill; T46 covers the parser it depends on. The skill has not run on a real repo. The only evidence is one fixture iteration (3 evals, n=1 per configuration) against an earlier commit. |
| Pipeline readiness | Strong | Its output feeds a live pipeline: `--settings` gates dispatch, and every loop quotes the file into DD. Caveat: the installed `~/.claude/scripts/build-loop.sh` lacks `--check-constraints` until reinstalled. |

## Flagged for Human Review

### Counterfactual Gap
- The benchmark suggests the gap is in process and sorting, not discovery: both arms found refuse-whole, the debug.ts violation, the dead trigger and ADR 006's narrowing. The baseline (66%) lacked the discrimination test at extraction time, the authority ranking, exception carrying, a stand-alone block, ratify-not-write, and the lived-cost interview. The gap was largest in interview mode (40%).
- Distillation fidelity: dropped or thinned lessons were negative cases and comment stripping for success checks (behemoth 12-13), the three-way report against existing guidance (behemoth 5), "accepted risk" as a kind (belegarth §4), and follow-up briefs for unmechanical checks (philosophy-research). *(The first three are now in the skill.)*
- Questions: is structure and consistency the value you want, or did you expect discovery lift? How much of the +34 points is the skill teaching to its own test, given that the fixtures came from the same notes?

### User-Specific Fit
- Triggers: `constraints-doc-missing`, `none-hard`, `unreadable` (added to the description after this evaluation), onboarding, an explicit request, amend after a new ADR or drift.
- Questions: after the four repos, is amend the steady state? Will a run in a repo that already has a hand-made doc be a fresh draft or an amend? Does it serve the unattended-loop goal well enough to justify the cost?

### Failure Mode Gracefulness
- Format failures are loud (the parser fails closed), and a human gate (ratify, plus the N rule on `docs/constraints.md`) sits before any line binds.
- Silent failures: success checks that pass vacuously, or need judgment; a plausible but wrong hard line (sources record choices, not costs); over-length; and, downstream, a bad hard line silently pruning good designs in every loop.
- Questions: which failure is likeliest in your repos? Is the ratify gate enough when the failure shows only in loop outputs weeks later?

### Condition for Value
- Conditions: repos run the build-loop dev cycle; `--check-constraints` is installed; there is a corpus or an author for an interview; the author ratifies promptly; loop outcomes eventually show the effect.
- Not yet true when evaluated: the mode was not installed; amend routing was unwired *(since fixed)*; nothing collects the "Notes for the skill" sections across repos.

## Key Questions

1. **The fixture lift may measure the fixtures more than the skill.** What result in the four repos would make you revise or drop it? Is there a held-out fifth repo, or an interview-mode run?
2. **Close the feedback loop.** Amend routing is now wired. Where should the per-run notes for the skill be collected for revision 2?
3. **Success lines are the weakest observable.** Should a hard line's check be shown to fail on a planted violation before it is kept hard? *(Adopted in step 5.)*
