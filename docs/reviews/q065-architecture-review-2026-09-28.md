Commit: 12f96cd

# Architecture Review — review/q065 (Q-065 [1])

**Scope:** `git -C /workspace/.claude/wt-q065 diff main...HEAD` (main 6405e43 → HEAD 12f96cd), full branch: `scripts/lib/si-input.sh`, `test/si-input-parse-comments.bats` (new), `test/si-input-rejected-history.bats` (deleted)
**Date:** 2026-09-28
**Based on:** `docs/reviews/q065-code-fact-check-report.md` (Commit: 12f96cd)

## Scope check

- Module structure: no (no module added, moved or split; one test file replaced by a smaller one)
- Public APIs: **yes**. `prepend_si_input_rejected_history` was a listed public function of `scripts/lib/si-input.sh` (main:scripts/lib/si-input.sh:12, :214); the diff removes it from the library's surface.
- Data models: marginally. The deleted function was the only producer of a pre-heading `<!-- Recent rejections ... -->` block in `si-input.md`, and its comment was the only place that stated the file-format rule it relied on (see finding 1).
- Cross-cutting concerns: no

Proceeding with the review.

## Dependency Map

`scripts/lib/si-input.sh` is a leaf library: it depends only on bash, `awk`, `sed` and `jq`, and imports no other repo module. Its one production consumer is `scripts/self-improvement.sh`, which sources it (`scripts/self-improvement.sh:231`) and calls only `parse_si_input` (`scripts/self-improvement.sh:493`); `parse_si_priority_hypotheses` is consumed through the same sourcing. Tests source the library directly (`test/si-input-parse-comments.bats:8`, `test/function-inventory.bats`, `test/parse-si-priority-hypotheses.bats`). Dependencies flow one way, orchestrator → library; the diff adds no edge and removes a function that had no inbound edge (fact-check Claim 1: no caller on any ref since 06903d6). The deleted function had an outbound read-dependency on the round-report JSON schema (`.validation.<tid>.verdict`, `.verdict_detail.reject_reason`), which it no longer imposes on the library.

Trust-boundary cross-reference: the most recent security review, `docs/reviews/security-review-2026-09-27.md` (Commit: 795ff71), covers `hooks/auto-approve-allowed-commands.sh` and other Q-077/078/080 files, not this library. This review produces no module-boundary finding on a labeled trust boundary, so the cross-reference is a no-op.

## Findings

#### 1. The "pre-heading text is discarded" format rule lost its only statement and its only test

**Severity:** Informational
**Location:** `scripts/lib/si-input.sh:19-25` (surviving contract comment); deleted statement at `main:scripts/lib/si-input.sh:205-207`; deleted assertion at `main:test/si-input-rejected-history.bats:178-188`
**Move:** 3 (module boundary: what the public surface promises)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**

```bash
# main:scripts/lib/si-input.sh:205-207
# The block lives BEFORE any "## " section heading, so parse_si_input's
# state machine treats it as preamble and discards it — user-editable
# sections (Feedback / Priorities / Off-limits / Context) are untouched.
```

```bash
# scripts/lib/si-input.sh:19-25
# --- Pre-run input parser ---
# Reads a markdown file with ## Feedback, ## Priorities, ## Off-limits,
# ## Context sections and exports their content as shell variables.
#
# Args: $1 = path to si-input.md
# Exports: SI_FEEDBACK, SI_PRIORITIES, SI_OFF_LIMITS, SI_CONTEXT
# Returns: 0 if file exists (even with empty sections), 1 if missing
```

`parse_si_input` still discards text before the first `##` heading: it accumulates such lines under an empty `current_section`, and `_save_si_section` (`scripts/lib/si-input.sh:103-113`) has no `case` arm for an empty heading, so they are dropped. That is part of the `si-input.md` format contract: it is what makes a pre-heading block a safe place for tool-written or explanatory text. Before this diff the rule was written down only in the deleted function's comment and asserted only by the deleted test "comment block does not pollute parsed sections" (fact-check Claim 2 confirms neither moved test places content before the first `##`). The behaviour is unchanged, so nothing breaks now. But a future edit to the state machine (for example, defaulting unheaded text to Feedback) would change the contract without a failing test or a contradicted comment. No producer of pre-heading content exists today, so the consequence is small.

**Recommendation:** Either add one line to the `parse_si_input` header (e.g. "Text before the first `##` heading is discarded.") or add a parse-only test to `test/si-input-parse-comments.bats` that puts a comment block or plain text before `## Feedback` and asserts that no `SI_*` variable contains it. Either is enough; the test is the stronger guard.

## What Looks Good

- The deletion narrows the library's public surface to what its one consumer uses: `parse_si_input` and `parse_si_priority_hypotheses`, plus two `_`-prefixed internals. The header's Functions list (`scripts/lib/si-input.sh:8-11`) now matches the file exactly (fact-check Claim 5).
- It removes a latent coupling. The library no longer reads the round-report JSON schema, a structure owned by the round-reporting code, so a future change to `validation`/`verdict_detail` no longer has a second, unexercised reader to keep in step.
- The library's responsibility becomes cleaner. It now only parses `si-input.md`. Before, it also rewrote that file from round reports, which is a second reason to change.
- The surviving tests went into a file named for what they test (`si-input-parse-comments.bats`) instead of staying in a file named for a deleted function. The runner discovers it by glob and `@category` tag, with no manifest to update (fact-check Claim 6).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Pre-heading discard rule of `si-input.md` lost its only comment and only test | Informational | `scripts/lib/si-input.sh:19-25` | High |

## Overall Assessment

The change improves the library's structural integrity. It removes a dead public function, narrows the library's surface to what is consumed, and drops an unexercised dependency on the round-report schema. No dependency direction, layering or boundary problem is introduced. The one structural note is that a small format-contract rule (text before the first `##` heading is discarded) was documented and tested only through the deleted code. It is worth restating in the surviving parser's header or a one-test addition, but it does not block merge.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the output path named in your role-specific tail, structured per your skill, ending with a Goal-Alignment Note."
- **Answered:** Scope check (the public-API category applies); the dependency map of `scripts/lib/si-input.sh` and its consumers; all eight cognitive moves considered. Moves 1, 2, 3 and 7 applied; 4, 5, 6 and 8 have nothing to act on in a pure deletion. Trust-boundary cross-reference checked and found to be a no-op. One Informational finding.
- **Out of scope:** Test adequacy beyond the contract point in finding 1 (test-strategy's domain); commit-message wording (fact-check Claim 2 already covers it); the questions.md/answer-record hash bookkeeping (fact-check Claim 8).
- **Escalate:** None from this critic. Finding 1 overlaps the fact-check's escalation (b), the lost pre-heading assertion. Synthesis should merge the two into one rubric item, not count them twice.
