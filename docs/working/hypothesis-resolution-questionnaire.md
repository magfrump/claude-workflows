# Hypothesis Resolution Questionnaire

**Purpose:** Resolve hypotheses H-01 through H-07 via direct user testimony, after two automated approaches (usage.jsonl analysis, git-log scanning) failed due to insufficient instrumentation.

**Quick start:** Run `scripts/run-hypothesis-survey.sh` for an interactive terminal version that collects answers and saves results automatically.

**Time estimate:** 2 minutes (interactive script) or 10 minutes (manual editing)
**Instructions:** Answer each question briefly. One sentence or a short list is fine. "I don't know" and "N/A" are valid answers. If a question asks for project names, use whatever shorthand you prefer.

**Meta-hypothesis:** Running this questionnaire will move at least 3 of 7 TRACKING hypotheses to CONFIRMED or REFUTED within 1 round.

---

## Section A: Workflow Usage (H-01, H-03, H-04, H-07)

**Q1.** List the external projects (not claude-workflows itself) where you've used Claude Code in the last 30 days.

> _Answer:_

**Q2.** For each project listed in Q1, which workflows (if any) did you use? Check all that apply per project, or write "none."

| Project | RPI | Bug-diagnosis | Divergent Design | Codebase Onboarding | Other (name it) | None |
|---------|-----|---------------|------------------|---------------------|------------------|------|
| | | | | | | |
| | | | | | | |
| | | | | | | |
| | | | | | | |

**Q3.** In the last 30 days, roughly how many times have you kicked off the full RPI workflow (research doc + plan doc + implement) in external projects?

> _Answer:_

**Q4.** Have you started any new projects (or returned to a dormant one) since the codebase-onboarding workflow was added? If yes, did you use the onboarding workflow?

> _Answer:_

**Q5.** Have you ever used the bug-diagnosis workflow in an external project? If yes, name the project and what you were debugging.

> _Answer:_

---

## Section B: Structural Patterns (H-02)

**Q6.** Which of your external projects have adopted any of these directory conventions? List project names next to the ones they use.

- `docs/decisions/` —
- `docs/thoughts/` —
- `docs/working/` —
- None of the above in any project —

**Q7.** For projects that adopted these patterns: do you perceive a difference in how organized or structured the work feels compared to projects without them?

> _Answer:_

---

## Section C: Skills vs. Workflows (H-05)

**Q8.** Which skills (e.g., fact-check, draft-review, simplify, cowen-critique, ui-visual-review) have you used in external projects in the last 30 days? List them.

> _Answer:_

**Q9.** Roughly, how does the frequency compare? Pick the closest statement:

- [ ] I use skills much more often than workflows in external projects
- [ ] I use skills and workflows about equally
- [ ] I use workflows more often than skills
- [ ] I rarely use either in external projects

---

## Section D: Adoption Barriers (H-06)

**Q10.** Are there workflows you've consciously avoided or stopped using? If yes, which ones and why?

> _Answer:_

**Q11.** Does the length or complexity of a workflow doc affect whether you'll invoke it? (e.g., "I skip X because it's too many steps")

> _Answer:_

---

## Section E: Open-ended

**Q12.** Is there anything about your workflow/skill usage patterns that the questions above didn't capture?

> _Answer:_

---

## Scoring Guide

Use this section after the questionnaire is completed to resolve each hypothesis.

### H-01: RPI is actively used in external projects (>2 per month)

| Resolution | Criteria |
|------------|----------|
| **CONFIRMED** | Q3 answer is 3+ times in 30 days, corroborated by specific projects in Q2 |
| **REFUTED** | Q3 answer is 0-1, or user cannot name specific external RPI uses in Q2 |
| **INCONCLUSIVE** | Q3 answer is 2, or user is uncertain about frequency |

**Primary evidence:** Q2 (RPI column), Q3

### H-02: Workflow pattern adoption produces more structured commits

| Resolution | Criteria |
|------------|----------|
| **CONFIRMED** | Q6 lists 2+ projects with patterns AND Q7 reports a perceived positive difference |
| **REFUTED** | Q6 shows no external adoption, OR Q7 reports no perceived difference |
| **INCONCLUSIVE** | Only 1 project adopted patterns, or user is unsure about the effect |

**Primary evidence:** Q6, Q7

### H-03: Bug-diagnosis is never used outside the self-improvement loop

| Resolution | Criteria |
|------------|----------|
| **CONFIRMED** | Q5 answer is "no" and Q2 shows no bug-diagnosis checkmarks |
| **REFUTED** | Q5 names a specific external project and bug |
| **INCONCLUSIVE** | User is unsure or gives a vague answer without specifics |

**Primary evidence:** Q2 (bug-diagnosis column), Q5

### H-04: Divergent design is used for external architectural decisions

| Resolution | Criteria |
|------------|----------|
| **CONFIRMED** | Q2 shows divergent design used in 1+ external projects |
| **REFUTED** | Q2 shows no divergent design use, and Q10 doesn't cite it as avoided-but-wanted |
| **INCONCLUSIVE** | User hasn't faced architectural decisions in the period, so no opportunity to use it |

**Primary evidence:** Q2 (divergent design column), Q10

### H-05: Skills are invoked more frequently than workflows externally

| Resolution | Criteria |
|------------|----------|
| **CONFIRMED** | Q9 selects "skills much more often" AND Q8 lists 2+ skills used |
| **REFUTED** | Q9 selects "workflows more often" or "about equally" |
| **INCONCLUSIVE** | Q9 selects "rarely use either," or Q8 is empty |

**Primary evidence:** Q8, Q9

### H-06: Workflow complexity correlates negatively with adoption

| Resolution | Criteria |
|------------|----------|
| **CONFIRMED** | Q11 confirms complexity/length is a barrier, AND Q10 names specific workflows avoided for that reason |
| **REFUTED** | Q11 says complexity is not a factor in adoption decisions |
| **INCONCLUSIVE** | User avoids workflows but for reasons unrelated to complexity (e.g., relevance) |

**Primary evidence:** Q10, Q11

### H-07: Codebase-onboarding is used when starting new projects

| Resolution | Criteria |
|------------|----------|
| **CONFIRMED** | Q4 says yes to both parts (started new project + used onboarding) |
| **REFUTED** | Q4 says started new projects but did NOT use onboarding |
| **INCONCLUSIVE** | Q4 says no new projects started (no opportunity to test) |

**Primary evidence:** Q4

---

## Post-Completion Checklist

After scoring, update `docs/working/hypothesis-backlog.md`:

1. Change status from TRACKING to CONFIRMED/REFUTED/INCONCLUSIVE for each resolved hypothesis
2. Fill in the Evidence Summary column with a one-line summary citing the question numbers
3. Count how many hypotheses moved out of TRACKING to evaluate the meta-hypothesis (target: 3+)
4. Record the date of questionnaire completion as Last Checked
