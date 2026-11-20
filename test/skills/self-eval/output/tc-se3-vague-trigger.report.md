# Self-Evaluation: helper

**Target:** `skills/helper/SKILL.md` | **Type:** Skill | **Evaluated:** 2026-11-19
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | The skill sets no output format, verdicts or sections. Its only instruction is "suggest improvements where they make sense", so there's nothing structural to check and no planted-flaw input that has a known correct output. Any test would need fully subjective human judgment of whether the "help" was helpful. |
| Trigger clarity | Weak | The description ("Use it when it would be helpful, or whenever you are working on code and want some extra help") names no trigger phrases or situations. It applies to every coding task, which invites false positives everywhere. It also takes in the triggers of `sql-migration-review`, `changelog-writer` and `license-audit` with no rule for choosing between them. |
| Overlap and redundancy | Weak | The body ("Consider the code, the context, and what they are trying to do. Suggest improvements... explain your reasoning") is a restatement of Claude's default behavior with no prompt at all. It is a vaguer version of what `sql-migration-review` does with five specific checks. On the same input it would give much the same output as plain Claude. |
| Test coverage | Weak | There is no `test/` directory and no `docs/reviews/` directory, so there are no tests or example outputs. Git history is a single "fixture" commit, so there's no evidence of real use. Per the rubric this is probationary. |
| Pipeline readiness | Adequate | It isn't orphaned. It has no `requires` block, depends on no pipeline, and no sibling skill references it (no orchestrators such as `draft-review` or `code-review` exist in this repo). Being able to run on its own is nominal, though: invoking it standalone adds nothing over not invoking it. |

All five rows are required. Use only `Strong`, `Adequate`, or `Weak` in the Score column.

---

## Flagged for Human Review

### Counterfactual Gap

- **What the tool does:** It tells the agent to look at what the user is working on, take into account the code, the context and the user's goal, suggest improvements where sensible, and explain its reasoning. It has no specific steps, checklist, domain focus or output structure.
- **What generic prompting achieves:** Most likely all of it. "Help me with this code" without the skill file would produce the same behavior, because the skill's instructions *are* the default behavior. The skill adds no specific steps, pipeline stages or structured output that generic prompting would leave out.
- **What built-in tools cover:** Claude Code's default assistant behavior covers this entirely. Built-ins such as code-simplifier also cover narrower slices of "suggest improvements" with more structure.
- **Questions for the reviewer:**
  - How much of this skill's value comes from structure or consistency, and how much from unique analysis? Here there appears to be neither. Do you agree?
  - Is there any case where loading this skill changes agent behavior in a way you want?
  - Under what conditions, if any, is the gap anything other than zero?

### User-Specific Fit

- **Triggering situations:** "Whenever you are working on code and want some extra help", meaning effectively every coding session.
- **Questions for the reviewer:**
  - How often does this triggering situation arise in your actual work? (Constantly, but does it arise as something *different* from ordinary coding?)
  - Is the frequency increasing or decreasing?
  - Does this serve a goal you're actively pursuing? If so, which one? A narrower skill could target it directly.
  - Would you actually remember to reach for this tool, and would it matter if you didn't?

### Failure Mode Gracefulness

- **Output structure:** None is set. Output is free-form prose suggestions with reasoning, so there are no verdicts, severities, confidence levels or claim-against-evidence pairs to inspect.
- **Potential silent failures:** Without a structure, thin or wrong analysis isn't visible as such. Plausible but mistaken suggestions (for example, refactors based on a misreading of the code) look the same as good ones. The skill gives no checklist, so missed risks such as table locks, unsafe rollbacks or license violations are invisible: nothing shows what was or wasn't checked. Its broad trigger may also pull it in *instead of* a specialized skill like `sql-migration-review`, which quietly lowers review depth.
- **Pipeline mitigations:** None. No orchestrator or upstream fact-check stage exists in this repo.
- **Questions for the reviewer:**
  - Based on your domain expertise, which failure modes are most likely?
  - Have you seen this skill displace a more specific skill in practice?
  - Is the detectable-to-silent failure ratio acceptable when there's no structure to make failures detectable?

### Condition for Value

- **Stated or inferred conditions:** No condition is stated. Inferred: for the skill to be valuable, invoking it would have to change behavior in some useful way compared with default Claude. That would need specific steps, a domain focus or an output contract, none of which the file has.
- **Automated findings:**
  - Pipeline dependency: none (no `requires` block).
  - Orchestrators in the repo (`draft-review`, `code-review`): DO NOT EXIST.
  - Behavioral difference from the default: none found in the file's content.
- **Questions for the reviewer:**
  - Is the condition met today? (Based on the file, it doesn't appear to be.)
  - If not, is there a realistic path? Would narrowing it to a concrete domain with defined checks and output create value, and would that just duplicate an existing skill?
  - Is this tool an investment pulling toward building missing infrastructure, or speculative inventory?

---

## Key Questions

1. **The skill restates default behavior.** Every instruction in `helper` describes what Claude already does when asked for help with code, and it has no specific steps or output contract. Is there any behavior this skill produces that you couldn't get by not loading it at all?
2. **The catch-all trigger may displace specialized skills.** "Whenever you are working on code" overlaps the triggers of `sql-migration-review`, `license-audit` and `changelog-writer`, which would go deeper on their own inputs. Should `helper` be removed so it can't take selection away from those skills?
3. **Narrowing it might just mean writing a different skill.** If there's a real need behind "helper", making it rubric-worthy would mean naming specific triggers, checks and an output format. Is there a concrete recurring task you meant it for, and if so, should that task be a new, narrowly scoped skill instead?

---

I scored `helper` Weak on four of the five dimensions (testability investment, trigger clarity, overlap and test coverage) and Adequate on pipeline readiness. That last score only reflects that it depends on no pipeline; running it standalone gives you nothing beyond default Claude. The skill restates Claude's normal behavior, has no structure, and its catch-all trigger could draw selection away from the specific skills. There are no tests or example outputs, and git history is a single "fixture" commit. The main questions for you are whether loading it changes behavior at all, whether it should be removed, and whether some real need behind it would be better as a narrowly scoped skill. As you asked, I printed the report here and didn't save it to `docs/reviews/self-eval-helper.md`.
