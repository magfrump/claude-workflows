# Spike Graveyard

This file records spikes that were abandoned, refuted, or otherwise did not lead to proceeding with the tested approach. It exists so future spikes can grep it before scoping — to avoid re-investigating the same dead ends.

Each entry is a single line in the format:

    <date> | <question> | <abandonment reason> | <branch>

- **date**: YYYY-MM-DD
- **question**: the spike's original one-sentence question (from `workflows/spike.md` step 2)
- **abandonment reason**: a one-clause summary of why the approach was abandoned (e.g., "library silently drops merged cells", "no convergence at timebox", "wrong question — real blocker is elsewhere")
- **branch**: the spike branch name — useful even after the branch is deleted, as a pointer for git archaeology

The graveyard is appended to in step 5 of `workflows/spike.md`. It is grepped in step 1, before scoping a new spike question. A match doesn't always mean the new spike is wasted — conditions may have changed (new library version, different constraints, the prior spike was scoped differently) — but it does mean the prior abandonment reason should inform the current question.

Last verified: 2026-05-15
Relevant paths: workflows/spike.md

---

<!-- entries below, newest at the bottom -->
