# Plan: accessible-output target addendum to onboarding step 2

## Goal
Add a small, conditional addendum to step 2 of `workflows/codebase-onboarding.md` requiring that accessibility-domain projects name a concrete accessible-output target (specific screen reader, specific braille protocol, specific structured format) in the architecture map, rather than treating accessibility as a vague concern.

## Pattern to mirror
The R7 monorepo-scoping addendum at `workflows/codebase-onboarding.md:60`:
- Single paragraph, bolded label sentence-leader
- Conditional opener ("For monorepos with multiple packages or services, ...")
- Concrete examples in parentheses
- Cross-reference to Known Unknowns where appropriate

## Placement
Immediately after the monorepo-scoping paragraph (between current lines 60 and 62), before the "If the codebase is large enough..." sub-agent guidance. This groups the two domain-specific scoping addenda together and keeps both ahead of the sub-agent dispatch instructions, so a sub-agent brief can incorporate the target if relevant.

## Wording (draft)
**Accessible-output target.** For projects in the accessibility domain (web-accessibility serialization, screen-reader tooling, refreshable-braille drivers, structured-data export for assistive tech, etc.), the architecture map must name the concrete accessible-output target rather than treating accessibility as a generic concern. State which screen reader (NVDA, JAWS, VoiceOver, Orca, TalkBack), which braille protocol or stack (BRLTTY, Liblouis translation tables, USB HID Braille Display, refreshable-braille over Bluetooth), and/or which structured-data format (DAISY, EPUB Accessibility, MathML, WAI-ARIA roles, accessible PDF tags) each subsystem is built to drive. Different targets impose different invariants — an NVDA-targeted serializer can't substitute for a JAWS-targeted one without re-validation, and Liblouis braille tables aren't interchangeable across grade-1/grade-2 contractions. List the target(s) alongside the relevant subsystem(s) in the inventory; if multiple targets coexist, note which subsystem owns which, and flag any subsystem that claims to be target-agnostic in Known Unknowns (step 5) for verification.

## Files touched
- `workflows/codebase-onboarding.md` — single paragraph insertion in step 2
- `docs/working/r3-onboarding-a11y-target-plan.md` — this plan

## Verification
- Re-read the inserted paragraph in context — the conditional opener should make it skippable for non-accessibility projects.
- Confirm placement does not break the "**Sub-agent briefing template.**" anchor or the surrounding flow.
- No other files modified (file-scope constraint).
