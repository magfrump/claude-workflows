# Scope exception — r3-tasks-schema-scope-required

The task makes `scope` a strict-required field on tasks-round-N.json. The
fixtures in `test/scripts/self-improvement-smoke.bats` were written before
this requirement and lack the `scope` field on every fixture task.

After this change, three smoke-test fixtures will be rejected by the
schema validator:

- `smoke: full round sequence produces a valid round report` — both fixture
  tasks (`add-logging`, `retry-logic`) lack scope.
- `smoke: task validation rejects invalid tasks alongside valid ones` — the
  `good-task` fixture lacks scope.
- `smoke: hypothesis eligibility filters fixture tasks correctly` — uses the
  same fixture as the first test.
- `smoke: two sequential rounds accumulate in round-history.json` — does not
  call `validate_task_json` directly, so likely unaffected.

The test file is outside this task's file-scope constraint
(`scripts/lib/si-functions.sh`, `scripts/self-improvement.sh`,
`docs/working/`), so the test fixtures cannot be updated here. The fixtures
must be updated in a follow-up task to add `"scope": "internal-si"` (or the
appropriate value) to each task object.

This is the correct precedence: making the planner emit scope is the
externally visible behavior change; updating the test fixtures is a
mechanical follow-up that should not block landing the schema fix.
