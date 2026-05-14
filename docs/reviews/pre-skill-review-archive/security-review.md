# Security Review

**Scope:** Branch feat/foreground-tests vs main (15 files, ~800 lines added)
**Date:** 2026-03-26
**Reviewer:** Security code review (design-level analysis)
**Fact-check report:** Referenced `docs/reviews/code-fact-check-report.md` (28 claims checked; 19 verified, 4 mostly accurate, 1 stale)

## Trust Boundary Map

All changed files are Markdown. There is no executable code in this diff. However, these documents function as **LLM agent instructions** -- they are consumed by Claude Code agents that then take real actions (writing code, running commands, committing, pushing) in downstream project repositories. The relevant trust chain:

```
Human (workflow author) → Workflow markdown → LLM agent (interpreter) → Code changes in target repos
```

Trust boundaries in the changed code:

1. **Human → Plan document (specification boundary)**: The human specifies test cases in prose during step 3; the LLM translates them into executable test code during step 5. The new test specification section (`research-plan-implement.md:83-101`) is the interface where human intent crosses into machine interpretation. Ambiguity here produces wrong tests, which then produce wrong implementations.

2. **LLM → Test diagnostic output → CI/terminal (data flow boundary)**: The diagnostic expectations guidance (`research-plan-implement.md:97`) instructs the LLM to produce tests with rich failure output including "the request payload that triggered the error" and "the state of the queue." That output flows into CI logs, terminal sessions, and PR artifacts -- environments with varying access controls.

3. **Soft checkpoint → Autonomous action (control flow boundary)**: The test-first checkpoint (`research-plan-implement.md:127`) allows the LLM to proceed to implementation without human review of test code if the human is unresponsive. This is a trust boundary where the human's review opportunity is bypassed by design.

4. **Hard gate (primary access control)**: The plan approval gate at `research-plan-implement.md:107` ("implementation does not begin until the user has reviewed the plan") remains the primary enforcement point. It is unchanged by this diff and applies to all downstream work including test writing.

## Findings

### 1. Soft checkpoint for test review uses "gate" terminology

**Severity:** Low
**Location:** `workflows/research-plan-implement.md:121,127`
**Move:** #5 -- Invert the access control model
**Confidence:** High

The heading at line 121 says "Test-first gate" but the body at line 127 says "this should not block progress indefinitely; if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed." This follows the established soft checkpoint pattern (matching the research checkpoint at line 68), not the hard gate pattern at line 107.

The access control model for RPI implementation is now:
- **Hard gate**: Plan approval (line 107) -- blocks unconditionally
- **Soft checkpoint**: Research review (line 68) -- proceeds after producing artifact
- **Soft checkpoint**: Test review (line 127) -- proceeds if human is unresponsive

The terminology "gate" implies enforcement that the mechanism does not provide. A user reading only the heading might believe test review is mandatory when it is not. More importantly, there is no escalation path: a security-critical test specification (e.g., tests for authentication, input validation, access control) receives the same soft treatment as a test for a cosmetic change. The LLM has no signal to distinguish these cases.

However, this risk is mitigated by the hard gate at step 4: the human has already approved the plan (including the test specification) before the LLM writes any test code. The soft checkpoint at step 5 is about reviewing the LLM's *translation* of already-approved specs into code, not about approving the specs themselves.

**Recommendation:** Rename to "Test-first checkpoint" for terminological consistency, or add a note that for security-critical tests the human should explicitly acknowledge before the LLM proceeds. This is a documentation clarity issue, not a structural flaw.

---

### 2. Diagnostic expectations guidance could lead to sensitive data in test output

**Severity:** Low
**Location:** `workflows/research-plan-implement.md:97-99`
**Move:** #6 -- Follow the secrets
**Confidence:** High

The diagnostic expectations section at line 97 encourages rich failure output with examples like "log the request payload that triggered the error" and "print the state of the queue before and after the operation." These are reasonable examples, but in downstream projects handling real user data, a request payload could contain authentication tokens, session cookies, or PII.

Line 99 mitigates this: "Avoid logging secrets, credentials, or PII in diagnostic output -- use placeholder values in test fixtures for sensitive data." This caveat was added in response to a prior security review finding (confirmed by the fact-check report, Claim 19 in the current report). The mitigation is appropriate for a workflow instruction document.

The residual risk: the caveat is a best-effort instruction to an LLM agent, not an enforcement mechanism. An LLM following RPI could still produce test code that logs sensitive data if the test fixture data itself contains real credentials (e.g., copied from a `.env` file or a database dump). Enforcement belongs in tooling (CI secret scanning, test fixture linting), not in workflow documentation.

**Recommendation:** No further action needed. The guidance is proportional and correctly scoped to what a workflow document can control.

---

### 3. No scope constraint on test specification volume

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:83-101`
**Move:** #8 -- "What if there are a million of these?"
**Confidence:** Low

The test specification section has no upper-bound guidance. A plan could specify 50+ test cases, causing the LLM to autonomously produce a large volume of test infrastructure before any implementation begins. In `/away` mode, this could result in autonomous commits of substantial test code for a feature the human might redirect after reviewing.

This is a resource waste concern, not a security vulnerability. The hard gate at step 4 means the human approved the test specification before the LLM begins writing tests. The "for simple features, this section can be brief" guidance at line 101 provides appropriate scaling pressure.

**Recommendation:** No change needed. The plan approval gate is sufficient.

---

### 4. Review artifacts overwrite without versioning

**Severity:** Informational
**Location:** `docs/reviews/*.md` (all review files)
**Move:** #4 -- Identify TOCTOU gaps
**Confidence:** Medium

All review artifacts from the prior branch (`feat/r1-skill-output-schema-validation`) were overwritten with this branch's reviews. The prior security review covered different code (BATS test infrastructure, shell scripts, env var handling) with its own findings. At HEAD, only the current branch's reviews exist in the working tree.

This is working as designed per CLAUDE.md ("re-runs overwrite prior artifacts with updated status"). The fact-check report (Claim 27) notes the prior security review's line references are now stale. Git history preserves the old content, but a reader of the working tree has no indication that a prior review existed with different findings.

For a workflow documentation repo, this is acceptable. For a repo with executable code where security reviews track known vulnerabilities, overwriting without a migration step would be more concerning.

**Recommendation:** No change needed for this repo. The design is appropriate for per-branch review snapshots.

## What Looks Good

- **The hard gate at step 4 is preserved and unweakened.** Line 107 remains the firm boundary: "implementation does not begin until the user has reviewed the plan." The new test-first checkpoint is additive -- it does not create an alternative path that bypasses plan approval.

- **Test-first is a positive security pattern.** Writing tests before implementation means security-relevant behavior gets specified as machine-checkable requirements before code exists. This is a well-established security engineering practice.

- **The secrets/PII caveat at line 99 addresses the diagnostic logging risk.** The prior review's finding was acted on. The mitigation is proportional -- a one-line instruction rather than a heavy-handed mechanism.

- **No instructions to bypass existing safety controls.** The changes do not instruct the agent to skip linting, ignore test failures, force-push, or take destructive actions. The CLAUDE.md safety constraints (no force-push, no `git reset --hard`, no destructive operations without approval) remain intact and unmodified.

- **No secrets, credentials, or sensitive paths introduced.** All changes are pure process documentation with no hardcoded values, API keys, or sensitive file paths.

- **The commit convention (`test: add tests for X`) creates auditable separation.** Test commits are distinct from implementation commits, supporting independent security review of what was tested vs. what was built.

- **The test specification table structure resists prompt injection.** The table format (`Test case | Expected behavior | Level | Diagnostic expectation`) is filled in by the human during planning and consumed by the LLM during implementation. Because the human authors this content and the hard gate requires human approval, there is no path for an external attacker to inject content into the test specification that the LLM would then execute. The trust chain is human → human-approved document → LLM, with no untrusted input.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Test-first "gate" is a soft checkpoint; terminology mismatch; no escalation for security-critical tests | Low | `research-plan-implement.md:121,127` | High |
| 2 | Diagnostic expectations could lead to sensitive data in output (mitigated by line 99 caveat) | Low | `research-plan-implement.md:97-99` | High |
| 3 | No upper bound on test specification volume (mitigated by plan approval gate) | Informational | `research-plan-implement.md:83-101` | Low |
| 4 | Review artifacts overwrite without versioning (by design) | Informational | `docs/reviews/*.md` | Medium |

## Overall Assessment

This change has a minimal security surface. All changes are Markdown workflow documentation with no executable code, no secrets, and no destructive instructions. The two Low-severity findings are design tradeoffs, not vulnerabilities: the soft checkpoint terminology mismatch (Finding 1) is a documentation clarity issue with the risk mitigated by the upstream hard gate at step 4, and the diagnostic output risk (Finding 2) is already addressed by the PII/secrets caveat at line 99. The hard gate at step 4 -- the primary access control in RPI -- is preserved and unmodified. The test-first pattern is a net positive for security in downstream projects, as it causes security-relevant behavior to be specified as executable tests before implementation begins. No critical or high-severity findings.
