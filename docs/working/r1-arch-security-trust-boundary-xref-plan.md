# Plan: Architecture-Review ↔ Security-Reviewer Trust-Boundary Cross-Reference

## Goal

Add a read-only cross-reference in `skills/architecture-review.md` so that when both
`architecture-review` and `security-reviewer` produce output on the same diff,
architecture-review reads the security findings first and constrains its
module-boundary analysis to be consistent with the security-identified trust
boundaries.

## Activation condition

The cross-reference activates only when **both** of the following exist at scan time:

- A security-reviewer output file (matching `docs/reviews/security-review-*.md`,
  per the path convention in `skills/security-reviewer.md` line 397).
- An architecture-review run that is about to produce module-boundary findings
  (cognitive move #3 — "Audit the module boundary").

When either output is missing, behavior is unchanged from current
architecture-review behavior.

## Design

Architecture-review already has a precedent for read-only consumption of another
skill's output: the "Using the Code Fact-Check Report" section. The trust-boundary
cross-reference follows the same shape — a dedicated input-handling section that
fires only when the upstream artifact exists.

Why read-only:
- Architecture-review must not edit, supplement, or revise the security findings.
- The security-reviewer's Trust Boundary Map (with labels `B1`, `B2`, …) is
  authoritative for trust boundaries.
- Architecture-review may *reference* boundary labels in its own findings to
  show consistency, but it does not produce trust-boundary findings of its own.

Why "constrain" module-boundary analysis:
- Cognitive move #3 audits the public surface of each module.
- A module boundary that crosses a security-identified trust boundary inherits
  security significance. If architecture-review recommends widening a public
  surface that sits on `B1`, that recommendation carries security implications
  that must be acknowledged.
- Recommendations that would move, dissolve, or relocate a trust-boundary
  crossing must be flagged as having security implications — not silently made.

## Edit pattern

1. Add a new top-level subsection **`## Trust-Boundary Cross-Reference (Security-Reviewer Integration)`**
   between "Using the Code Fact-Check Report" and "The Cognitive Moves".
   Contents:
   - Activation condition (both outputs exist).
   - Scan step: look for `docs/reviews/security-review-*.md` before producing
     module-boundary findings.
   - How to use the Trust Boundary Map (read-only): module-boundary findings
     that touch a labeled trust boundary must reference its label (`B1`, `B2`)
     and must not contradict the security-identified boundary placement.
   - Recommendations that would move/dissolve a trust-boundary crossing must
     be explicitly tagged as having security implications.
   - No-op when either output is missing.

2. Add a single sentence in cognitive move #3 ("Audit the module boundary")
   pointing the reader to the cross-reference section. This keeps the
   constraint visible at the point where module-boundary findings are produced,
   without duplicating the activation condition.

## Out of scope

- Bidirectional cross-reference (security-reviewer reading architecture findings).
  This plan is one-directional: architecture-review reads security output.
- Modifying `skills/security-reviewer.md`.
- Changing how security-reviewer formats its Trust Boundary Map.
- Adding a new finding category to architecture-review.

## Verification

- `skills/architecture-review.md` parses as valid markdown.
- The activation condition is explicit and the no-op fallback is stated.
- Cognitive move #3 references the new section.
- No other files are modified.
