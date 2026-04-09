# Research: Security Reviewer Critical Finding Escalation

## Scope
Add a "Critical Finding Escalation" section to `skills/security-reviewer.md` listing 3-5 patterns that should halt review and surface immediately to a human.

## What exists
The security-reviewer skill (`skills/security-reviewer.md`, 268 lines) has:
- 9 cognitive moves for security analysis (lines 72-188)
- A structured critique output format with severity levels (lines 192-241)
- Severity guidelines already define "Critical" as: RCE, auth bypass, unrestricted data access (line 219)

Currently, Critical findings are listed alongside lower-severity ones in the summary table. There's no mechanism to halt the review process or surface findings with special urgency. [observed]

## Invariants
- The existing severity scale (Critical/High/Medium/Low/Informational) must be preserved [observed — used in finding structure at line 206]
- The cognitive moves section structure must remain intact [observed]
- Output format (Trust Boundary Map → Findings → What Looks Good → Summary Table → Overall Assessment) must not change [observed]

## Prior art
No existing escalation or halt-and-surface mechanism in any skill file. [inferred from reading the full skill]

## Gotchas
- The section must produce explicit "halt and escalate" language in output to make the hypothesis testable
- Must keep the list to 3-5 items to avoid escalation fatigue (per task spec)
- Should integrate naturally with the existing finding severity system rather than creating a parallel classification
