# Self-Evaluation: release-risk-notes

**Target:** `skills/release-risk-notes/SKILL.md` | **Type:** Skill | **Evaluated:** 2026-11-19
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | The output has three named sections and a fixed set of four tags, so a test repo with two tags, a planted unflagged payment change and a flagged auth change can be checked mechanically ("Is the payment change listed under **Unflagged risky changes**?"). But the skill names no dashboard source, so "Watch first" can only be judged by a human who knows the team's monitoring. |
| Trigger clarity | Adequate | The description gives three concrete trigger phrases and a clear moment ("before a production deploy") for a clear reader (the on-call engineer). The edges are fuzzy, though: "what changed since the last deploy" is close to `changelog-writer`'s "what shipped since v2.3" and "draft release notes", so a request like "write release notes before we ship" could go either way. |
| Overlap and redundancy | Adequate | It shares the same first step as `changelog-writer` (diff since the last tag), and its data-deletion tag partly overlaps `sql-migration-review` for destructive migrations. The lenses differ: risk tags, feature-flag status and monitoring for on-call, versus plain-language notes for end users and lock/rollback analysis per statement. No built-in capability covers this. |
| Test coverage | Weak | There is no `test/` directory, no `docs/reviews/` directory and no example `# Deploy risk — <release>` output. Git history is one commit named "fixture", so there is no evidence of real use. This puts the skill in the rubric's probationary state. |
| Pipeline readiness | Strong | The skill can be used on its own: it has no `requires` block, and no other skill references it. There are no orchestrators in the repo (`skills/draft-review` and `skills/code-review` don't exist), so nothing depends on a pipeline being built. |

---

## Flagged for Human Review

### Counterfactual Gap

- **What the tool does:** It diffs the release candidate against the deployed tag and tags each change as payment, auth, data-deletion or other. For each tagged change it records whether a feature flag guards it, then picks three dashboards to watch. The output is a short note in three sections, and the unflagged risky changes get their own section.
- **What generic prompting achieves:** "Summarise the risky changes in this release for on-call" would probably produce a reasonable change summary with some risk commentary. Three things would likely be missing:
  - the fixed set of three risk categories, applied every time
  - an explicit feature-flag check on each risky change, which is the skill's most distinctive move
  - a consistent section layout that on-call can scan quickly
- **What built-in tools cover:** No built-in Claude Code capability writes deploy risk briefs.
- **Note on depth:** The skill is only four steps long and leaves out the hard parts:
  - how to find the currently deployed tag
  - how to tell whether a feature flag guards a change
  - what counts as a "data-deletion path"
  - where the dashboard list comes from

  Much of the real work is left to the model's improvisation, which makes the gap over a generic prompt smaller.
- **Questions for the reviewer:**
  - How much of the value is the fixed categories and the flag check (consistency), and how much is analysis the user wouldn't do anyway?
  - Is the gap "on-call would otherwise never be told about unflagged payment changes" or "we'd write this note anyway, just less consistently"?
  - Is the gap biggest for large releases with many PRs, for releases built by people who aren't on call, or for teams without a release checklist?

### User-Specific Fit

- **Triggering situations:**
  - Just before a production deploy, briefing the on-call engineer.
  - The user says "write the deploy risk note", "what should on-call watch for this release", or "brief on-call before we ship".
  - A release that touches payment, auth or data-deletion code.
- **Questions for the reviewer:**
  - How often do you deploy to production, and do you currently write any on-call handoff note?
  - Is your deploy frequency, or the on-call responsibility, growing or shrinking?
  - Does this serve a goal you're actively pursuing, such as fewer incidents or better on-call handoffs?
  - At deploy time, would you remember to invoke this, or would it only run if built into a release checklist or CI step?
  - Do the three fixed categories (payment / auth / data-deletion) match the riskiest areas of *your* systems?

### Failure Mode Gracefulness

- **Output structure:** A note headed `# Deploy risk — <release>` with **Changes**, **Unflagged risky changes** and **Watch first** sections. Gaps in structure, such as a missing section, an empty Changes list or the wrong release name, are easy to spot.
- **Potential silent failures:**
  - **Wrong baseline:** The skill doesn't say how to find "the currently deployed tag". If the model diffs against the latest git tag and that isn't what's deployed, the Changes list is incomplete but looks authoritative.
  - **False "flagged" status:** If a risky change is wrongly recorded as flag-guarded, it disappears from **Unflagged risky changes**. That is the worst failure here, because the omission is invisible: on-call sees a short, reassuring list.
  - **Missed tags:** Payment, auth or data-deletion code reached through generic helpers, config changes or migrations may get tagged "other".
  - **Made-up dashboards:** With no dashboard catalog, the model may invent plausible names ("Payments Latency p99") that don't exist, or pick generic ones.
  - **Unenforced "one-page" claim:** The description promises one page, but nothing in the steps enforces it.
- **Pipeline mitigations:** None. No orchestrator or upstream checking stage exists. `sql-migration-review` could catch destructive migrations if run separately, but nothing links the two skills.
- **Questions for the reviewer:**
  - Which is most likely in your codebase: wrong baseline, false flag status, missed tags, or made-up dashboards?
  - Is it acceptable for a risk note to fail by *leaving things out*, given that an omission looks like "low risk"?
  - Should the skill require evidence for each claim (the flag name and file/line for "flagged", and dashboard links from a known catalog) so silent failures become visible ones?

### Condition for Value

- **Stated or inferred conditions:**
  - The user deploys to production and hands off to an on-call engineer.
  - Release tags exist, and there's a reliable way to know which tag is deployed.
  - The codebase uses feature flags in a form the model can detect.
  - There's a known set of dashboards the model can pick from.
  - Payment, auth and data deletion are the risk categories that matter.
- **Automated findings:**
  - Orchestrator dependency: none required (no `requires` block). No orchestrators exist in the repo.
  - Source for the deployed tag: **not specified in the skill**.
  - Dashboard catalog or source: **not specified in the skill**, and nothing in the repo provides one.
  - Way to detect feature flags: **not specified in the skill**.
  - Sibling skills that could feed into it: `changelog-writer` (same diff), `sql-migration-review` (migration risk). Neither is referenced.
- **Questions for the reviewer:**
  - Are these conditions met in the projects where you would use this?
  - If dashboards and flag detection depend on the environment, should the skill ask the user for them, or read them from a project config file?
  - Is this a real gap in your deploy process, or a nice-to-have that will sit unused?

---

## Key Questions

1. **The skill's main promise is the list of unflagged risky changes, and that's where it can fail silently.** A risky change wrongly marked as flagged drops off the list without a trace, and the skill doesn't say how flag status should be determined or proven. Should each "flagged" verdict require a cited flag name and location before this ships?
2. **Steps 1 and 4 rely on information the skill never says where to get.** "The currently deployed tag" and "the three most relevant dashboards" both need knowledge specific to the environment, so without it the model will guess. Should the skill take these as inputs, or read them from a config, rather than inferring them?
3. **The boundary with `changelog-writer` is thin at the trigger level.** Both start from "what changed since the last release", and "release notes before we ship" could match either. Is the on-call framing clear enough to tell them apart, or should both descriptions explicitly point to each other?

---

I scored `release-risk-notes` against the rubric and printed the report above instead of saving it. Two of the five auto-scored dimensions are fine:

- **Pipeline readiness: Strong.** It works standalone and depends on nothing.
- **Test coverage: Weak.** There are no tests, no example outputs, and the git history (one "fixture" commit) shows no use.
- **Testability, trigger clarity, overlap: Adequate.** The output is easy to check, but there's no source for dashboards. The trigger and the first step are close to `changelog-writer`'s.

The most important question for a human reviewer is whether flag status should need cited evidence. If a risky change is wrongly marked as flagged, it quietly drops off the list on-call relies on. Behind that are two gaps: the skill never says how to find the deployed tag or where the dashboards come from.
