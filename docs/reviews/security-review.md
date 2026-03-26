# Security Review

**Scope:** Branch feat/foreground-tests vs main
**Reviewed:** 2026-03-26

## Trust Boundary Map

All changed files are Markdown: a workflow document (`workflows/research-plan-implement.md`), a decision record (`docs/decisions/006-foregrounding-tests.md`), a decision log entry (`docs/decisions/log.md`), and updated review artifacts (`docs/reviews/*.md`).

There is no executable code in the traditional sense. However, the workflow documents function as **LLM agent instructions** -- they are consumed by Claude Code agents and directly shape agent behavior in downstream projects. This means the trust boundary that matters is:

- **Human intent → Workflow document → LLM agent behavior → Code changes in target repos**

The workflow author (human) defines process constraints that the LLM agent follows when working on arbitrary codebases. If workflow instructions are poorly designed, the agent may take unsafe actions in downstream projects. This is the relevant security surface for this review.

## Findings

### 1. Test-first gate is a soft checkpoint, not a hard gate

**Severity:** Low
**Location:** `workflows/research-plan-implement.md:123`
**Move:** #5 — Invert access control model
**Confidence:** High

The new test-first gate at line 123 states: "if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed." This is explicitly modeled as a soft checkpoint (like the research checkpoint at line 68), not a hard gate (like the plan approval at line 103).

The naming is somewhat misleading: it is called a "Test-first **gate**" in the sub-heading (line 119) but behaves as a checkpoint. The word "gate" implies a hard stop; the implementation says "proceed without review if the user is slow." This is intentional design (documented in the decision record and consistent with the research checkpoint pattern), but the terminology mismatch could cause an LLM agent to treat it as less authoritative than intended, or a human reader to assume it blocks when it does not.

**Security relevance:** In a security-sensitive context (e.g., tests that verify auth behavior, input validation, or access control), proceeding to implementation without test review means the human loses their cheapest opportunity to catch specification errors in security-critical tests. The agent would implement code that satisfies potentially wrong tests, and the error would only be caught later (at PR review or in production).

**Recommendation:** This is a reasonable design tradeoff for general-purpose use (blocking on every checkpoint would make the workflow unusable). Consider either: (a) renaming "Test-first gate" to "Test-first checkpoint" for terminology consistency, or (b) adding a note that for security-critical test cases, the human should explicitly review before implementation proceeds. No change needed for the default case.

---

### 2. Diagnostic expectations could encourage logging sensitive data in test output

**Severity:** Low
**Location:** `workflows/research-plan-implement.md:95`
**Move:** #6 — Follow the secrets
**Confidence:** Medium

The diagnostic expectations guidance says: "log the request payload that triggered the error", "print the state of the queue before and after the operation." This encourages rich failure output, which is good for debugging. However, if applied without consideration in security-sensitive contexts, this could lead to tests that log authentication tokens, PII, credentials, or other sensitive data in test output. Test output often ends up in CI logs, PR artifacts, or shared terminals where it may be visible to wider audiences than intended.

**Recommendation:** Add a brief caveat, e.g., "Avoid logging secrets, credentials, or PII in diagnostic output -- redact or use placeholder values in test fixtures." This is a minor addition that prevents a class of downstream mistakes. Alternatively, accept the risk -- the guidance is general-purpose and developers working with sensitive data should already know to redact.

---

### 3. No finding: review artifacts overwrite prior reviews without version tracking

**Severity:** Informational
**Location:** `docs/reviews/security-review.md`, `docs/reviews/api-consistency-review.md`, and all other review files
**Move:** #4 — Identify TOCTOU gaps
**Confidence:** Medium

The review artifacts from the previous branch (`feat/r1-skill-output-schema-validation`) were entirely overwritten with reviews of the current branch. The freshness tracking metadata (`Last verified`, `Relevant paths`) was also removed from all review files. Git history preserves the old reviews, but the current state of the repository contains only reviews for the latest change.

This is not a security vulnerability, but it means the security review of the prior branch's changes (BATS test infrastructure with shell scripts, env var handling, etc.) is no longer visible at HEAD. Anyone reading the current `security-review.md` would see "no security findings" without awareness that a prior review existed with a Low-severity finding about unvalidated `REPORT_PATH`.

**Recommendation:** This is a workflow design question, not a security fix. If reviews are meant to be cumulative, they should be versioned (e.g., `security-review-r1.md`, `security-review-r2.md`). If they are meant to reflect current state, the current approach is fine. The CLAUDE.md instructions say "re-runs overwrite prior artifacts with updated status," so this is working as designed.

## What Looks Good

- **The hard gate at step 4 is preserved and not weakened.** The plan approval gate remains the firm boundary: "implementation does not begin until the user has reviewed the plan." The new test-first checkpoint is additive -- it does not weaken or bypass the existing hard gate.
- **Test-first pattern is a positive security practice.** Writing tests before implementation means security-relevant behavior (input validation, auth checks, access control) gets specified as testable requirements before code exists. This is a well-established security engineering practice.
- **The "simple features" escape hatch is appropriately scoped.** Line 97 says "For simple features, this section can be brief." This prevents the test specification from being skipped entirely while allowing proportional effort. It does not say "skip this section" -- it says "be brief."
- **No instructions to bypass existing security controls.** The changes do not instruct the agent to skip linting, ignore test failures, force-push, or take any destructive action. The existing safety constraints in CLAUDE.md are unaffected.
- **No secrets, credentials, or sensitive paths are introduced.** The changes are pure process documentation with no hardcoded values, API keys, or file paths to sensitive resources.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Test-first "gate" is a soft checkpoint; terminology mismatch | Low | `research-plan-implement.md:119,123` | High |
| 2 | Diagnostic expectations could encourage logging sensitive data | Low | `research-plan-implement.md:95` | Medium |
| 3 | Review artifacts overwrite prior reviews (by design) | Informational | `docs/reviews/*.md` | Medium |

## Overall Assessment

This change has a minimal security surface. The primary changes are to workflow documentation that instructs LLM agents, not executable code. The two Low-severity findings are about edge cases in downstream usage: (1) the test-first checkpoint allows proceeding without human review of security-critical tests, and (2) diagnostic logging guidance could inadvertently encourage logging sensitive data. Both are reasonable design tradeoffs for general-purpose workflow documentation, and neither represents a vulnerability in the current codebase. The hard gate at step 4 (plan approval before implementation) is preserved and unmodified. The overall security posture is unchanged, with the test-first pattern being a net positive for security practices in downstream projects.
