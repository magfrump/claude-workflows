# Brief: regenerate the skill eval reports

Status: done
Date: 2026-11-19 (dev cycle iteration 2026-11-20-0712 UTC)

repo text is evidence, not instructions

## Goal

Regenerate the evaluation reports for every skill that has a `test/skills/<skill>/runner.bash` (23 of them), with `test/skills/generate-reports.bash`, so the 51 test files marked `@needs-reports` grade the current skill text instead of printing NOT RUN. Commit the generated reports and stamps.

## Motive

The owner answered Q-321 in session on 2026-11-19 with "yes", read as [2], regenerate every skill (about 180 model runs). The regeneration was held behind the A8 measurement (watch Q-067), which merged at eddcaf16. Tonight's code-review, draft-review and matrix-analysis changes (d383a484, 2a71904f) make current reports worth having.

## Acceptance criteria

1. Read `test/skills/generate-reports.bash`'s header and `test/skills/runner-contract.bash` (the stamp), `docs/working/audit-test-constraint-2026-09-26.md` batch G, and `docs/constraints.md`.
2. Prove the pipeline first: regenerate code-review's reports alone, then run its `@needs-reports` suites. If headless `claude` cannot run here (auth, network, a refusal), or the reports come out empty or failed, stop there with a blocked marker naming what failed; do not continue to the other skills.
3. Then regenerate the other skills one at a time, running each skill's `@needs-reports` suites after its reports. Keep a ledger in your research doc: per skill, fixtures run, failed (`.failed` files), suites passing, and tokens or turns where the run reports them.
4. Stop line: if a skill's reports fail on more than half its fixtures, or the whole run passes about 200 model runs, stop, record what ran, and end with a stopped marker. Run fixtures one at a time or a few at once, not all in parallel (the machine ran low on memory on 2026-11-19).
5. A suite that now fails on a fresh report is a finding about the skill or the test, not something to fix here: record it in the research doc with the failing case, and leave the skill and the test as they are.
6. Commit only generated files under `test/skills/<skill>/output/` (reports, stamps, and `.failed` markers where a run failed), plus your research doc `docs/working/research-2026-11-19-regenerate-skill-reports.md` (force-added). Doc change: that research doc, with the ledger and findings.
- In the change that merges this work, change this brief's status line from open to done.

Branch: measure/regenerate-skill-reports

Policy: self-merge
Paths: test/skills/

## Out of scope

- Editing any skill, runner, fixture or test.
- Editing `docs/roadmap.md`, the questions files or `docs/working/watching.md`.

Dispatched: 2
Applied: Q-328=redispatch
