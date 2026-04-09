# Research: RPI From-Testing Handoff

## Scope
Add a `← From Testing` pivot entry to RPI's "When to pivot" section, creating a symmetric handoff with user-testing-workflow's existing outbound `→ RPI` pivot.

## What exists

- **RPI "When to pivot"** (`workflows/research-plan-implement.md:15-22`): Six entries covering Spike, DD, Onboarding, and Bug Diagnosis handoffs. No inbound pivot from user testing. [observed]
- **User-testing-workflow outbound pivot** (`workflows/user-testing-workflow.md:11`): Already documents `→ RPI` — "carry the findings report (Phase 4) as input to RPI research — the severity-rated issues and prioritization matrix replace the 'explore from scratch' part of scoping." [observed]
- **User-testing-workflow inbound pivot** (`workflows/user-testing-workflow.md:13`): Documents `← From RPI` — when RPI implementation needs usability validation. [observed]
- **Existing inbound pivot patterns**: `← From Spike` loads the spike's RPI seed section; `← From Onboarding` loads the architecture map. Both follow the structure: what to load, what it replaces, don't re-derive. [observed]

## Invariants

- Pivot entries follow a consistent format: direction arrow, source workflow, what to carry forward, what it replaces in RPI's process. [observed from existing entries]
- User-testing-workflow's `→ RPI` text is the authoritative description of what gets carried — the RPI entry must be consistent with it. [observed]

## Prior art

The `← From Spike` and `← From Onboarding` entries are direct prior art. The new entry mirrors their structure.

## Gotchas

- CLAUDE.md's "How workflows compose" section doesn't list Testing ↔ RPI as a composition path. Updating it is outside file scope — documented in scope-exception file.
