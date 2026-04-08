# Research → Plan → Implement (Slim)

> Quick-start checklist. Full workflow: [research-plan-implement.md](../research-plan-implement.md)
> Last synced: 2026-04-08

## When to use

Non-trivial feature or bug fix where you need to understand code before changing it.

## Checklist

- [ ] **1. Scope** — State what this loop covers in one sentence. One task per loop.

- [ ] **2. Research** — Read relevant code (implementations, not just signatures). Write `docs/working/research-{topic}.md` covering:
  - What exists (files, functions, how they connect)
  - Invariants (what must not break)
  - Prior art (existing similar solutions)
  - Gotchas (surprising or fragile behavior)

- [ ] **3. Plan** — Write `docs/working/plan-{topic}.md` with:
  - Approach (2-3 sentences)
  - Numbered steps (each = one commit, ordered by dependency)
  - Test specification (one case per behavioral requirement)
  - Risks

- [ ] **4. Get approval** — Human reviews the plan before implementation starts. Research review is soft; plan review is the hard gate.

- [ ] **5. Implement** — Write failing tests first, then implement one step at a time. Commit after each step referencing the plan.

- [ ] **6. Verify** — Run lint, build, tests. Update `docs/thoughts/` if you learned something. Proceed to pr-prep if opening a PR.

## Pivot signals

- Hit a feasibility question → [spike.md](../spike.md)
- Found 3+ viable approaches → [divergent-design.md](../divergent-design.md)
- Bug in code you already understand → [bug-diagnosis.md](../bug-diagnosis.md)
