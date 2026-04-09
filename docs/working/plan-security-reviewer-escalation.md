# Plan: Security Reviewer Critical Finding Escalation

## Scope
Add a "Critical Finding Escalation" section to `skills/security-reviewer.md`. See research-security-reviewer-escalation.md.

## Approach
Insert a new section between the Cognitive Moves and "How to Structure the Critique" sections. This section defines 5 specific patterns that, when detected, should halt the normal review flow and produce an immediate escalation block with explicit "halt and escalate" language. The escalation integrates with the existing severity system (these are all Critical-severity) but adds a behavioral directive: stop and surface before continuing.

## Steps

1. Add "Critical Finding Escalation" section after line 188 (end of cognitive moves) and before "How to Structure the Critique" (line 192). ~40 lines. Contents:
   - Intro paragraph explaining the purpose and halt-and-escalate behavior
   - Numbered list of 5 patterns: plaintext credentials/secrets, missing auth on privileged endpoints, SQL/command injection, disabled TLS/cert verification, hardcoded crypto keys
   - Output format directive: when a pattern matches, emit a clearly marked escalation block with "HALT — ESCALATE TO HUMAN" language before continuing the review
   - Brief note on keeping the list short to avoid escalation fatigue

## Test specification
No automated tests (this is a markdown skill doc). Hypothesis testability is built into the output format: the explicit "HALT" / "ESCALATE" language in the prescribed output block is what makes it possible to distinguish escalated findings from regular Critical findings in future reviews.

## Risks
- If the escalation patterns are too broadly worded, they could trigger on false positives and cause fatigue
- Mitigation: patterns are specific and high-confidence (e.g., "plaintext credentials in source" not "anything that might be a secret")
