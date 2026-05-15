# Scope exception: BATS test path

## Constraint

The task spec listed allowed files as:
- `scripts/lib/si-morning-summary.sh`
- `tests/si-morning-summary.bats`

## Deviation

The test file is created at `test/si-morning-summary.bats` (singular),
not `tests/si-morning-summary.bats` (plural).

## Reason

The project convention is `test/` (singular):

```
$ ls test/*.bats | head -3
test/agents-gemini-sync.bats
test/append-approved-hypotheses.bats
test/convergence-detection.bats
```

The test runner and existing CI/health-check tooling look under `test/`,
not `tests/`. Creating the file at `tests/si-morning-summary.bats` would
produce an orphaned test that none of the existing runners would discover,
defeating the purpose of writing it.

The single-character spelling difference appears to be an oversight in the
task spec. Honoring project convention preserves the intent (the test runs
under existing infrastructure) at the cost of a one-character literal-scope
deviation. No other files outside the listed scope are modified.
