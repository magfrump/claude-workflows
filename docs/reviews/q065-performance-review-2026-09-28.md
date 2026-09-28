Commit: 12f96cd

# Performance Review — review/q065 (Q-065 [1])

**Scope:** `git -C /workspace/.claude/wt-q065 diff main...HEAD` (full branch, 3 files, +33 / −328)
**Date:** 2026-09-28
**Based on:** `docs/reviews/q065-code-fact-check-report.md` (Stage 1, 8 claims, 7 verified, 1 mostly accurate)

## Data Flow and Hot Paths

The diff removes code and adds none. It deletes `prepend_si_input_rejected_history` from `scripts/lib/si-input.sh`, deletes its 12-test suite, and moves 2 unchanged `parse_si_input` tests into a new file. The only thing that sources the library in production is `scripts/self-improvement.sh:231`, and it runs `parse_si_input` once per loop start (`scripts/self-improvement.sh:493`). That is a cold path: it runs once per self-improvement run, on a small, user-edited `si-input.md`. The fact-check (Claim 1) found that the deleted function was never called, so it never ran on any path, hot or cold. Surviving runtime code (`parse_si_input`, `_save_si_section`, `parse_si_priority_hypotheses`, `_trim_blank_lines`) is unchanged context in the diff (fact-check Claim 4).

What this means for performance:
- **Runtime:** no executed code path changes. The only effect is that bash parses about 110 fewer lines when it sources the library, once per run. That is a cold-path constant too small to matter.
- **Test suite:** the fast suite has 12 fewer `@test` blocks. Each deleted test forked `jq` one to five times (`write_round_report`, `rejected_entry`, `merge_validations`, plus the function's own per-round `jq`, `sort`, `awk`, `mktemp` and `mv`). The moved tests do the same work as before and use a smaller `setup()`.

I applied the relevant moves (hidden multiplications, size of N, work moved to the wrong place, memory lifecycle, cache) to the deleted and moved code. None applies, because no code is added or relocated on any executed path.

## Findings

No findings.

## Endorsements (evidence-gated)

- Deleting the function changes no runtime work in the self-improvement loop, because no in-repo path ever called it. [fact-check: claim 1 — Verified] [fact-check: claim 4 — Verified]
- The two moved tests do the same work as before: they are byte-identical to the originals and pass under the project runner. [fact-check: claim 3 — Verified]
- The fast suite should get slightly faster, by roughly the wall time of 12 jq-heavy tests. This has not been measured, and nothing in this report depends on it. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

This is a dead-code deletion with no performance risk. It removes code that never ran and changes no code that does run. No profiling or benchmarking is needed. The one open item from the fact-check is that no test now covers `parse_si_input` discarding an HTML-comment block placed before the first heading (Claim 2). That is a coverage question, not a performance one, so it belongs to test-strategy / synthesis.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the output path named in your role-specific tail, structured per your skill, ending with a Goal-Alignment Note."
- **Answered:** Performance review of the full branch diff at 12f96cd: runtime path impact (none), sourcing cost (lower, cold path), test-suite cost (lower). Endorsements are tied to fact-check verdicts, and one is left as an unverified claim.
- **Out of scope:** I did not time the fast suite before and after the change. I did not re-verify the fact-check's claims about callers or byte-identity; I relied on its verdicts.
- **Escalate:** None from the performance lens. For synthesis: the fact-check's Claim 2 coverage gap (pre-heading comment preamble) and its Claim 8 hash note (the answer record cites 11b79c6, but this branch lands the same change as 12f96cd) remain open and are outside this critic's scope.
