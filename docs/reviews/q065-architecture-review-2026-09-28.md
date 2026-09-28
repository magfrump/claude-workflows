Commit: 0304a2c

# Architecture Review — review/q065 (Q-065 [1]), final confirming pass

**Scope:** `git -C /workspace/.claude/wt-q065 diff main...HEAD` at HEAD 0304a2c (full branch): `scripts/lib/si-input.sh`, `test/si-input-parse-comments.bats` (new), `test/si-input-rejected-history.bats` (deleted), `docs/reviews/override-log.md`. The `docs/reviews/q065-*.md` artifacts are out of scope.
**Date:** 2026-09-28
**Based on:** `docs/reviews/q065-code-fact-check-report.md` (Commit: 0304a2c; 19 verified, 1 mostly accurate, 0 incorrect)

## Scope check

- Module structure: no (no files moved or renamed; a test file is replaced by a new one)
- Public APIs: **yes**. `prepend_si_input_rejected_history` is removed from the function surface of the sourced library `scripts/lib/si-input.sh`, and from the header's `Functions:` list.
- Data models: no. The `<!-- Recent rejections ... -->` block format that the function wrote into `si-input.md` goes away with it. No reader of that format exists: `parse_si_input` treats it as a comment and discards it.
- Cross-cutting concerns: no

Proceeding, limited to the removed export and how the surviving library and its tests fit around it.

## Dependency Map

- `scripts/self-improvement.sh:230-231` sources `scripts/lib/si-input.sh` and calls only `parse_si_input` (`:493`). `parse_si_priority_hypotheses` is exercised by `test/parse-si-priority-hypotheses.bats`.
- `test/function-inventory.bats:52-69` pins `parse_si_input` as part of the expected function set. It never listed the deleted function, so the inventory contract does not change.
- Across `scripts/`, `hooks/` and `test/`, nothing refers to `prepend_si_input_rejected_history` except the provenance comment at `test/si-input-parse-comments.bats:5-6`. Stage 1 also verified that no live caller exists (Claim group 5). What remains is in archive/, execution logs, dated ledgers (`docs/decisions/log.md:80`, `docs/working/audit-test-constraint-2026-09-26.md`) and the Q-065 questions entry, all excluded by the preamble.
- Direction is unchanged. The library depends only on bash, `sed`, `awk` and `jq`, and the orchestrator depends on the library. The deleted function was the library's only writer to `si-input.md` and its only reader of `round-<N>-report.json`. With it gone, `si-input.sh` is again a pure input parser with no dependency on the round-report schema.

## Findings

No findings.

(Trust-boundary cross-reference: `docs/reviews/security-review-*.md` files exist, but none covers this branch, and this review produces no module-boundary findings under move #3, so the cross-reference is a no-op.)

## What Looks Good

- **Cohesion restored (move #2).** The removed function wrote to `si-input.md` and read round reports. Those two responsibilities were foreign to a module whose header describes it as a "Pre-run input parser". Removing it narrows the reasons `si-input.sh` has to change to one: the si-input.md format. It also drops the library's coupling to the `round-*-report.json` `validation`/`verdict_detail` schema, which `scripts/lib/si-morning-summary.sh` still owns for its own "Recent rejections" summary.
- **Surface and documentation stay in step (move #3).** The header's `Functions:` list (`scripts/lib/si-input.sh:8-11`) is updated in the same change, so the documented public surface matches the exported one (Stage 1 verified).
- **Tests follow the unit under test.** The two `parse_si_input` tests that lived in the deleted helper's test file now sit in a file named for `parse_si_input`'s behaviour. The replacement third test pins the "preamble and unknown headings are discarded" contract that the deleted function's design relied on, and that any future re-introduction of a pre-heading block would rely on too. The contract now has a home that does not depend on the dead producer.
- **Clean removal.** No shim, stub or deprecated alias is left behind. The function had no caller, so a compatibility layer would only add surface.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | High |

## Overall Assessment

The change improves the structural integrity of `scripts/lib/si-input.sh`. It removes an uncalled export whose responsibilities (writing the input file and reading round reports) did not belong in a parser module, without changing the surface that the one consumer (`self-improvement.sh`) or the inventory test depends on. No dependency-direction, layering or coupling problems are introduced. The most important structural point is a forward-looking note rather than a defect: if the loop ever wants rejected-history feedback in `si-input.md` again (decision log row 57 says the loop is to be resumed), that writer belongs in the orchestrator or next to the round-report producer, not back in the parser library.

## Goal-Alignment Note
- **Answered:** Whether removing `prepend_si_input_rejected_history` from the `si-input.sh` public surface leaves any consumer, inventory contract, or dependency direction broken, and whether the relocated and new tests sit at the right module boundary. The full branch diff at 0304a2c was checked against `self-improvement.sh`, `function-inventory.bats`, `parse-si-priority-hypotheses.bats` and a repo-wide grep. Result: no findings.
- **Out of scope:** Test-assertion strength and mutant coverage (Stage 1 and test-strategy), override-log wording (Stage 1 Claim group 4), commit-message accuracy (Stage 1 Claim 11), and the `docs/reviews/q065-*.md` artifacts.
- **Escalate:** None.
