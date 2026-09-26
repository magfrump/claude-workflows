# Audit: do the tests constrain production behavior? (2026-09-26)

Driven by `/loop check that all tests in the repo constrain production behavior`.

**Question per test:** is there a plausible regression in *production* code
(scripts/, hooks/, skills/*/SKILL.md + helpers, install/, global-instructions/,
workflows/, guides/ — anything a user runs or an agent reads) that would turn
this test red? A test that cannot go red on any production change is vacuous.

**Vacuity patterns looked for**

- V1 tests a fixture, stub, or inline copy of the logic instead of the real artifact
- V2 assertion cannot fail (no status/output check after `run`, `|| true`, regex that matches anything, grep of the test file itself)
- V3 the unit under test is itself stubbed/mocked away
- V4 permanently skipped, or skipped in every environment the runner uses
- V5 asserts only on the harness/helper, with no path back to production
- V6 tautology: expected value derived from the same code path as the actual
- V7 weak: exercises production but a named plausible regression still passes

**Verdicts:** `OK` · `WEAK` (V7, fixable by tightening) · `VACUOUS` (V1–V6) · `META` (tests test-infra by design — legitimate only if that infra gates production tests).

Fixes are verified by mutation: break the production line, watch the test go red, restore.

## Batches

| Batch | Scope | Status |
|---|---|---|
| A | test/*.bats agents-gemini-sync … merge-safety (16) | pending |
| B | cc-isolated-functions, init-firewall-rules, test_cc_sni_proxy.py | pending |
| C | install-host, link-claude-home-wiring, hermeticity-lint | pending |
| D | test/*.bats lite-review-grammar … worktree-cleanup-functions (17) | pending |
| E | test/hooks/*, test/scripts/* (14) | pending |
| F | test/skills non-templated suites (~17) + arithmetic-eval/mode1-equiv.py | pending |
| G | test/skills *-eval.bats / *-format.bats pairs (~46) | pending |

## Findings

_(filled per iteration)_
