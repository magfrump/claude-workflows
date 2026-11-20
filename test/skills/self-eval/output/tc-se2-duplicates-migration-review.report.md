# Self-Evaluation: migration-safety-check

**Target:** `skills/migration-safety-check/SKILL.md` | **Type:** Skill | **Evaluated:** 2026-11-19
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Strong | The output is structured (`## Finding N` sections, a constrained four-level severity scale, a Recommended rollout section), and test inputs with known answers are easy to build: for example, a migration with a planted `CREATE INDEX` that lacks `CONCURRENTLY`, an unbatched `UPDATE`, or a missing down migration. Whether the severity calibration and lock-duration reasoning are right still needs a human with Postgres knowledge, but checking that planted flaws get caught is mechanical. |
| Trigger clarity | Weak | The description's trigger phrases ("is this migration safe", "will this lock the table", "when a diff touches migrations/") repeat `sql-migration-review` almost word for word ("is this migration safe", "will this lock the table", "when a diff adds a file under migrations/"). Neither the user nor the agent has anything to go on when choosing between them, so which one fires is effectively random. |
| Overlap and redundancy | Weak | The overlap is in substance, not just format. `sql-migration-review` runs the same five checks (locks, rewrites, rollback, backfills, concurrent indexes) in the same order, uses the same `## Finding N` / Critical–Low severity format, and ends with an equivalent rollout section ("Safe rollout" vs. "Recommended rollout"). On the same input the two skills would produce nearly identical output. `migration-safety-check` actually has less detail: it lacks the rewrite examples (type change, default on old Postgres) that its sibling gives. |
| Test coverage | Adequate | `test/skills/migration-safety-check-format.bats` exists, so this is not zero coverage. But it has only two format checks (a severity line exists, a "Recommended rollout" string exists). It depends on a `$REPORT_PATH` with no fixture behind it, and nothing tests whether planted flaws are detected. There are no example outputs (`docs/reviews/` does not exist) and no usage evidence in git (the history is one commit, "fixture"). This is the bottom of Adequate. |
| Pipeline readiness | Strong | The skill works standalone: you point it at a migration and get a report. It has no `requires` block, no other skill references it, and no orchestrator exists in this repo (`skills/draft-review/` and `skills/code-review/` are absent, and there is no `workflows/` directory). It doesn't need a pipeline, so it isn't orphaned. If a code-review orchestrator is ever built, it would have to choose between this skill and `sql-migration-review`. |

---

## Flagged for Human Review

### Counterfactual Gap

- **What the tool does:** It goes through a migration one statement at a time and applies five production-safety checks: what lock is taken and for how long relative to table size, whether the table is rewritten, whether a down migration exists and whether it loses data, whether backfill `UPDATE`s are batched, and whether indexes are built concurrently. Each finding gets a severity, and the report ends with a recommended rollout strategy (expand/contract, batching, concurrent index).
- **What generic prompting achieves:** If you ask Claude "is this migration safe to run in production?", it will usually raise locking and non-concurrent indexes unprompted, and often unbatched backfills. The parts it is more likely to skip are a systematic pass over *every* statement, an explicit check of the down migration and whether it loses data, and a consistent severity format. The skill body is only five one-line checks, so most of its value is in making sure the checks happen and the format is consistent, not in expert content. It gives no lock-level tables, no version-specific Postgres/MySQL behaviour, and no table-size thresholds.
- **What built-in tools cover:** No built-in Claude Code capability is specific to migrations. General code review would catch some of these issues incidentally.
- **vs. other skills in this repo:** `sql-migration-review` covers the same ground, so the real question is how much worse things get without *this* skill when the sibling exists. The answer looks close to zero.
- **Questions for the reviewer:**
  - How much of the skill's value comes from structure and consistency, and how much from unique analytical content? With a five-line body, is there any unique content at all?
  - Is the gap "the skill adds moves the user wouldn't think of" or "the skill ensures consistency the user would otherwise forget"?
  - Under what conditions is the gap largest: high-traffic tables, inexperienced migration authors, a specific database engine?
  - Is there anything this skill does that `sql-migration-review` doesn't?

### User-Specific Fit

- **Triggering situations:**
  - The user asks "is this migration safe", "check this migration", or "will this lock the table".
  - A diff touches `migrations/`.
- **Questions for the reviewer:**
  - How often does this triggering situation arise in your actual work? Do you ship schema migrations against production databases where lock time matters?
  - Is the frequency increasing or decreasing?
  - Does this serve a goal you're actively pursuing?
  - Would you actually remember to reach for this tool when the situation arises? And if so, would you reach for *this* one or `sql-migration-review`?

### Failure Mode Gracefulness

- **Output structure:** The output is numbered findings, each with a four-level severity, followed by a rollout recommendation. A missing finding section or an unrecognised severity value is easy to spot, and the bats test catches the absence of either section.
- **Potential silent failures:**
  - **Version-dependent lock and rewrite claims.** Whether `ADD COLUMN ... DEFAULT` rewrites the table depends on the Postgres version (11+ does not, for non-volatile defaults). MySQL's online DDL behaviour also differs by version and algorithm. The skill never asks for the database engine or version, so it can confidently report a rewrite that won't happen, or miss one that will.
  - **Table-size assumptions.** "How big a table?" can't be answered from the migration file alone. The model may guess and assign severity from the guess.
  - **Missed findings.** A clean report ("no issues") looks exactly like a correct all-clear. Missed issues are the most dangerous failure here, because the user then deploys.
  - **Plausible but wrong rollout advice.** For example, recommending `CREATE INDEX CONCURRENTLY` inside a transaction-wrapped migration framework, where it will fail.
- **Pipeline mitigations:** None. No orchestrator exists and nothing upstream verifies factual claims.
- **Questions for the reviewer:**
  - Based on your domain expertise, which failure modes are most likely? Version-specific misclaims, or missed findings?
  - Have you observed any silent failures in practice?
  - Is the ratio of detectable to silent failures acceptable when a false all-clear can cause a production outage?

### Condition for Value

- **Stated or inferred conditions:**
  1. The user regularly writes or reviews migrations against production databases where locking and rewrites matter.
  2. The skill offers something `sql-migration-review` doesn't, or it replaces that skill.
  3. Its trigger can be told apart from its sibling's well enough that it gets invoked on purpose.
- **Automated findings:**
  - Orchestrator that composes it: DOES NOT EXIST. The skill is standalone, so it doesn't need one.
  - A sibling skill with equivalent scope: EXISTS (`skills/sql-migration-review/SKILL.md`).
  - Usage evidence: NONE (single-commit history, no `docs/reviews/`).
  - Format test: EXISTS, with no fixture report.
- **Questions for the reviewer:**
  - Are the conditions met today? Condition 2 looks unmet from the codebase.
  - If not, is there a realistic path, such as merging the two skills, or giving one of them a distinct scope (e.g., engine-specific or version-aware)?
  - Is this tool an investment pulling toward building missing infrastructure, or speculative inventory? Or is it simply a duplicate?

---

## Key Questions

1. **This skill duplicates `sql-migration-review`.** Both skills have the same five checks, the same severity format, the same trigger phrases and the same `migrations/` path trigger, and they differ only in what the final section is called. Which one should survive? Should the other be deleted, or merged in, carrying over the format test and the sibling's more detailed rewrite examples?
2. **Neither skill encodes real migration expertise.** Each body is five one-line checks with no engine or version awareness, so most of what they catch is what a generic prompt would catch too. Is the surviving skill worth keeping as a consistency checklist, or should it be deepened (ask for engine and version, lock-level reference, framework transaction caveats) so it justifies a dedicated file?
3. **The test coverage is format-only.** The bats file checks that sections exist but has no fixture report and no planted-flaw migrations, so nothing shows the skill catches an unsafe migration. Since false all-clears are the costliest failure here, should a planted-flaw fixture be required before this ships?

---

**Summary:** The skill is easy to test and works standalone (both Strong). Test coverage is a thin Adequate: there's a format-only bats file with no fixture behind it, no example outputs, and no usage history. Trigger clarity and overlap are both Weak because `skills/sql-migration-review` is the same skill in all but name: same checks, same output format, same trigger phrases. The main question for you is which of the two to keep. After that, the next questions are whether the survivor needs version- and engine-aware content to beat a generic prompt, and whether planted-flaw tests should be required given that a false all-clear can cause an outage. As you asked, I printed the report here instead of saving it to `docs/reviews/self-eval-migration-safety-check.md`. Two other notes: this repo has no `draft-review` or `code-review` orchestrators, and per your note I didn't run `git log`.
