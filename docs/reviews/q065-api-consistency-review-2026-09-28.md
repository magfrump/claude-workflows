Commit: 0304a2c

# API Consistency Review — review/q065 (Q-065 [1], final confirming pass)

**Scope:** `git -C /workspace/.claude/wt-q065 diff main...HEAD` at HEAD 0304a2c (full branch; `docs/reviews/q065-*.md` out of scope)
**Date:** 2026-09-28
**Based on:** `docs/reviews/q065-code-fact-check-report.md` (k=1, 19 verified / 1 mostly accurate / 0 stale / 0 incorrect)

## Baseline Conventions

`scripts/lib/*.sh` files are sourced shell libraries. Their public surface is the set of non-underscore functions, listed in a `# Functions:` header block (`scripts/lib/si-input.sh:8-11`); internals carry a leading `_` and an `Internal:` comment (`_save_si_section`, `_trim_blank_lines`). Each library refuses direct execution (`si-input.sh:14-17`). Sibling tests source the library directly (`test/parse-si-priority-hypotheses.bats:7`, `test/si-input-parse-comments.bats:9`). Test files are named `<subject>-<aspect>.bats` with `# @category fast` on line 2 and a one-paragraph header comment naming the subject function. `test/function-inventory.bats` is the existence registry for functions reachable from `scripts/self-improvement.sh`.

## Name-Pattern Audit

The diff adds **no new public names**. It removes one exported function, `prepend_si_input_rejected_history`. The only new name is a test file, audited below for convention fit.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `test/si-input-parse-comments.bats` | test file | `test/parse-si-priority-hypotheses.bats`, `test/si-input-rejected-history.bats` (deleted), `test/function-inventory.bats` | `test/*.bats` | Consistent: `si-input-` prefix matches the deleted sibling it replaces; `@category fast` header and setup/teardown shape match `parse-si-priority-hypotheses.bats` |
| `@test "parse_si_input drops text before the first heading and under unknown headings"` | test name | the two moved `parse_si_input …` tests at `:18`, `:26` | `test/si-input-parse-comments.bats:18,26` | Consistent: `<function> <verb phrase>` form |

## Consumer contract (move #3) — removal of `prepend_si_input_rejected_history`

Removing an exported function from a sourced library is breaking only if a consumer calls it. Consumers traced:

- **In-repo:** `git grep` (excluding `archive/`, `docs/reviews/`) finds no call site. The only remaining mentions are `docs/working/questions.md:28,52` (the Q-065 entry, which the answers branch closes) and `docs/working/audit-test-constraint-2026-09-26.md:68,142` (dated audit ledger). Both are historical records, not consumers. `test/si-input-parse-comments.bats:5-6` names it only as provenance.
- **Installed payload:** `~/.claude/scripts` → `/opt/claude-workflows/scripts` (image-baked, read-only). `grep -rln prepend_si_input_rejected_history /opt/claude-workflows` returns only `scripts/lib/si-input.sh` itself: the definition, with no caller. The installed copy keeps the function until the next image build/link; that is harmless since nothing calls it.
- **Other surfaces:** no hits in `skills/`, `hooks/`, `workflows/`, `guides/`, `README.md`. `test/function-inventory.bats` never registered it (only `parse_si_input`, `:52-53`), so no registry drift.
- **Documentation drift:** the `# Functions:` header drops the entry in the same hunk (`@@ -9,9 +9,6 @@`); fact-check Claim 5 confirms the list now matches the defined non-underscore functions exactly.
- **Surviving contract:** `parse_si_input` and `parse_si_priority_hypotheses` are untouched (both removed hunks lie outside them; fact-check Claim 3). Its export variables `SI_FEEDBACK`, `SI_PRIORITIES`, `SI_OFF_LIMITS`, `SI_CONTEXT` and return codes are unchanged.

Moves 4-9 (errors, pagination, versioning, asymmetry, nullability, idempotency) have no surface here: no new or altered signatures, return values or side effects on a live path.

## Findings

No findings.

## What Looks Good

- The removal is clean at the contract level: definition, header entry and dedicated tests go together, and nothing else referenced the name.
- The replacement test file follows sibling naming and header conventions, and its header states provenance of the moved tests.
- The self-improvement loop's used surface (`parse_si_input`, `parse_si_priority_hypotheses`) is byte-for-byte unchanged in behaviour.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The change is consistent with the library conventions and breaks no consumer: the deleted function had no caller in the repo, in the installed `/opt/claude-workflows` payload, or in any skill, hook or workflow, and the library's documented function list was updated in the same commit. The one new name (the test file) matches sibling conventions. Nothing to fix.

## Goal-Alignment Note

- **Answered:** whether removing `prepend_si_input_rejected_history` from the sourced/installed library breaks any consumer or leaves documentation/registry drift (no), and whether the new test file follows naming conventions (yes). Final confirming pass over the full branch at 0304a2c.
- **Out of scope:** test adequacy and mutant strength (test-strategy/fact-check own these); `docs/reviews/q065-*.md` artifacts; the override-log row's substance beyond fact-check's verdicts; the stale installed copy under `/opt` (updates on image rebuild; not a branch change).
- **Escalate:** nothing.
