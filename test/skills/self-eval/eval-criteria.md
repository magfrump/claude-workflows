# Self-Eval — Evaluation Criteria

Each fixture is a small repo (tree mode). The runner's `fixture_base` adds the
**live** `docs/evaluation-rubric.md`, three synthetic sibling skills from
`self-eval/base/skills/` (changelog-writer, sql-migration-review,
license-audit), and the fixture's own test files. The target skill lives in the
fixture under `skills/<name>/`. Three fixtures each plant one weakness the rubric
defines as Weak; two are negatives.

## Fixture → Expected Finding Map

| Fixture | Target | Planted | Expected | Must Mention |
|---|---|---|---|---|
| tc-se1-no-tests-no-outputs | release-risk-notes | nothing in `test/`, nothing in `docs/reviews/`, no git usage | Test coverage **Weak** | the Weak row |
| tc-se2-duplicates-migration-review | migration-safety-check | same five checks, severity scale, rollout section and triggers as sibling `sql-migration-review` (has a format suite, so test coverage isn't the only weakness) | Overlap and redundancy **Weak** | the Weak row and the sibling's name |
| tc-se3-vague-trigger | helper | description is "use it when it would be helpful" | Trigger clarity **Weak** | the Weak row |
| tc-se4-well-tested-distinct | api-changelog-diff | (negative) format + eval suites, a fixture, an example output in `docs/reviews/`; no sibling overlaps | Test coverage Strong or Adequate; neither Test coverage nor Overlap Weak | the Strong/Adequate row |
| tc-se5-rubric-missing | release-risk-notes | (negative) `.fixture-no-rubric` keeps the rubric out | stops before scoring | the repo-only message; no scored rows |

tc-se1 to tc-se4 also run `format_check` (self-eval-format.bats).

## Notes

- **Table rows, not field lines.** SKILL.md fixes the scores as a table
  (`| Test coverage | Weak | ... |`), so checks match rows. `[ *]*` tolerates
  bold cells.
- **Test files are stored as `.bats.in`** under each fixture's `.fixture-tests/`
  and renamed to `.bats` in the temp repo. `scripts/run-tests.sh` collects every
  `*.bats` under `test/` and fails untagged ones, so real `.bats` files here
  would break the suite.
- **No git evidence.** No Bash, so no `git log`; the prompt says the history is
  one "fixture" commit. That is why tc-se4 accepts Adequate: the rubric's Strong
  wants documented real-world usage too.
- **tc-se5's stop.** SKILL.md Step 2: without `docs/evaluation-rubric.md`,
  "stop before scoring" and "do not substitute a remembered or improvised
  rubric". The negative forbids scored rows, not the word "rubric".
- **Pipeline references.** Step 3c reads `skills/draft-review/` and
  `skills/code-review/`, which the fixture repos lack. The report may say so;
  no check depends on Pipeline readiness.
- **Likely to move on the first real run:** tc-se3 may score Overlap Weak
  alongside Trigger clarity (fine, not checked), and tc-se5's message pattern.
- Fixture files carry no comments naming the planted weakness.
