# Self-Evaluation: api-changelog-diff

**Target:** `skills/api-changelog-diff/SKILL.md` | **Type:** Skill | **Evaluated:** 2026-11-19
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Strong | The output is mechanically checkable: two fixed headings (`## Breaking` / `## Non-breaking`), one bullet per change, and a JSON pointer on each. A pair of spec versions with planted changes gives a known correct answer, and `test/skills/api-changelog-diff-format.bats` already shows the checks can be automated. |
| Trigger clarity | Adequate | The description gives concrete phrases ("what changed between these two specs", "is this spec change breaking"). The third trigger, "before publishing a new API version", overlaps with `changelog-writer`'s "draft release notes" / "what shipped since v2.3", and both deal with "changelog" and "breaking changes", so "write the API changelog" could go either way. |
| Overlap and redundancy | Strong | No other skill in the repo diffs specs. `changelog-writer` also flags breaking changes, but it works from merged-PR titles and produces end-user prose, not a structural spec diff. `license-audit` and `sql-migration-review` cover different ground. Dedicated external OpenAPI diff tools exist, though; see Counterfactual Gap. |
| Test coverage | Adequate | Two bats files exist, but the eval suite reads `api-changelog-diff/output/removed-field.report.md` and `optional-field.report.md`, and neither file exists. The only fixture is a 2-line stub (`removed-field-v1.yaml`) with no v2 counterpart and no optional-field fixtures, so the eval tests cannot pass as written. One example output exists (`docs/reviews/api-changelog-diff-orders-v3.md`), but there is no usage evidence in git (the repo has a single "fixture" commit). |
| Pipeline readiness | Strong | It works standalone: you give it two specs and get a report. It has no `requires` block, and no skill or orchestrator references it. The orchestrators named in self-eval Step 3c (`draft-review`, `code-review`) are not in this repo, so there is no pipeline to be orphaned from. |

---

## Flagged for Human Review

### Counterfactual Gap

- **What the tool does:** It loads two OpenAPI specs and resolves `$ref`s. It matches operations by method + path and schemas by name. Each difference is sorted into breaking (removed endpoint, removed or newly required field, narrowed enum, changed type) or non-breaking (new endpoint, new optional field, widened enum), and every change cites a JSON pointer.
- **What generic prompting achieves:** Asking Claude to "diff these two OpenAPI specs and tell me what's breaking" would probably produce much the same breaking/non-breaking split. What the skill adds is consistency: fixed section headings, JSON-pointer citations and a set matching rule. The skill body is only three steps. Step 3 classifies "using the table above", but **there is no table in the file**. The only classification rules are the parenthetical lists in the frontmatter `description`. The rules also say nothing about:
  - **Request vs. response direction.** A widened response enum or a field removed from a response can break consumers. A newly required request field is breaking, but a newly required response field is not. The skill treats "widened enum" as always non-breaking.
  - **Parameter, status-code, auth/security-scheme and default-value changes.**
  - **Renames.** Path or schema renames will show up as a remove plus an add.
- **What built-in tools cover:** Claude Code has no built-in for this. Outside it, deterministic OpenAPI diff tools (e.g., oasdiff, openapi-diff) do this job with exhaustive rule sets and no hallucination risk.
- **Questions for the reviewer:**
  - How much of the value comes from structure and consistency (headings, pointers) rather than analysis? From the current file, it looks like nearly all of it.
  - Is the gap "the skill adds moves you wouldn't think of" or "the skill makes sure you don't forget the pointer citations"?
  - Is the gap largest when no deterministic diff tool is available, or when an LLM is needed to explain *why* a change breaks consumers? Would wrapping a deterministic tool and adding explanation beat the current approach?

### User-Specific Fit

- **Triggering situations:**
  - Asked "what changed between these two specs?"
  - Asked "is this spec change breaking?"
  - About to publish a new API version
  - Possibly: a PR touches an `openapi.yaml` (this trigger is not stated in the description)
- **Questions for the reviewer:**
  - How often do you maintain or consume versioned OpenAPI specs?
  - Is that becoming more or less frequent?
  - Does this serve a current goal, such as API governance or a public API launch?
  - Would you remember to invoke this rather than `changelog-writer` (or an external diff tool) when cutting an API release?

### Failure Mode Gracefulness

- **Output structure:** Two sections with one bullet per change, each citing a JSON pointer. Pointers make each claimed change checkable: you can open the spec and confirm the element exists or changed. Wrong section placement is also visible on inspection.
- **Potential silent failures:**
  - **Omissions are invisible.** The report lists only what it found. A missed change (e.g., a changed parameter, a new required header, an auth scheme change) leaves no trace, and the report looks clean and complete.
  - **Direction-blind classification.** A widened response enum or a field removed from a response gets labelled "Non-breaking" or put in the wrong place with full confidence. This is a domain error a non-expert would not catch.
  - **Name-based matching.** A renamed schema or path becomes "removed + added". That is noisy rather than silent, but it can hide the real nature of the change.
  - **`$ref` resolution errors.** If remote or circular refs are misresolved, the pointers will look plausible but describe the wrong element.
  - **Dangling "table above" reference.** The model may invent its own classification table, so behaviour can vary between runs.
- **Pipeline mitigations:** None. There is no upstream verification stage. The format bats test checks structure only, not completeness or correctness.
- **Questions for the reviewer:**
  - Of these failure modes, which are most likely for the specs you work with? Omissions and request/response asymmetry seem the riskiest.
  - Have you seen a missed breaking change in practice?
  - For a tool whose main use is the "is it safe to publish?" gate, can you accept a failure mode where omissions are invisible?

### Condition for Value

- **Stated or inferred conditions:**
  1. The user regularly ships versioned OpenAPI specs.
  2. The classification rules are complete and correct enough to trust as a pre-publish gate.
  3. It does better than, or adds something on top of, a deterministic diff tool.
- **Automated findings:**
  - Classification table referenced in Step 3: **DOES NOT EXIST** in the file.
  - Eval-test output artifacts (`output/removed-field.report.md`, `output/optional-field.report.md`): **DO NOT EXIST**.
  - Paired fixtures (v1 + v2): **ONLY a v1 stub EXISTS**.
  - Orchestrator or pipeline dependency: **NONE REQUIRED** (standalone).
  - Example real-world output: **ONE EXISTS** (orders v2 → v3, two changes).
- **Questions for the reviewer:**
  - Is condition 1 true for you today?
  - Is there a realistic plan to fix the missing table, add request/response direction rules and complete the fixtures, so the skill can be trusted for condition 2?
  - Is this an investment worth finishing, or inventory that a deterministic diff tool already makes unnecessary?

---

## Key Questions

1. **The skill's core logic is missing.** Step 3 relies on "the table above", which does not exist, and the only rules (in the description) mislabel some response-side changes as non-breaking. Should the skill be finished first, with an explicit request/response-aware classification table, before it counts as passing the rubric?
2. **A deterministic tool may do this better.** OpenAPI diffing is a mechanical, rule-based task where an LLM's silent omissions are the main risk. Should this skill run or wrap a deterministic diff tool and add explanation, rather than doing the diff itself?
3. **The test suite exists on paper but can't pass.** The eval tests read report files that don't exist, and the only fixture is a 2-line v1 stub. Is anyone committed to building the fixture pairs and generated outputs, so the "Adequate" coverage score reflects tests that actually run?

---

The skill scores well on testability, overlap and pipeline readiness: its output is easy to check mechanically, nothing else in the repo does this, and it works standalone. Trigger clarity is only Adequate because "API changelog" and "before publishing" overlap with `changelog-writer`. Test coverage is a generous Adequate: the eval tests point at report files that don't exist and the only fixture is a stub. One example report exists, but git can't show whether it came from real use. Three findings matter most for the reviewer:
- Step 3 points to a classification table that isn't in the file.
- The rules ignore whether a change is on the request or the response side, which can mislabel breaking changes as non-breaking.
- Changes the skill misses leave no trace in the report, so a deterministic OpenAPI diff tool might be the better foundation.

As you asked, I printed the report here and didn't save it to `docs/reviews/self-eval-api-changelog-diff.md`.
