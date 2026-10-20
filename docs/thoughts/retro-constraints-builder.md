# Retro: constraints-builder skill (2026-10-19)

Three stacked units (u1 `--check-constraints`, u2 references, u3 SKILL.md) went through
skill-creator, then pr-prep. They merged as c9f2fa21, 55e0bdac and 512a1512.

1. **Plan vs. reality.** The skill-creator draft took one fixture eval. pr-prep then ran three
   review iterations per unit. u1 converged on the merits. u2 and u3 hit the cap with a High
   open, and closed by a scope decision (log row 73) rather than a clean pass. The reviews kept
   finding new ways git runs repo-chosen code. The fix that worked was to shrink the trust
   boundary, not to add more hardening.
2. **Skipped steps.** No fourth iteration (the cap). Stage 2.5 (endorsement verification) was
   skipped on u1's final pass. Performance and api-consistency were skipped for the copy-only
   units. Review artifacts are condensed, because subagents here cannot write report files.
3. **Surprises.**
   - Security review of *prose* instructions is as productive as review of code. A skill that
     tells an agent to run git in a repo inherits git's whole exec surface.
   - Each fix pass created new claims for the next fact-check to break, such as the provenance
     command, the config denylist and rg's ignore flags.
   - k=3 fact-checks on prose units cost about 500K tokens per pass.
4. **Next time.**
   - Decide a skill's trust boundary before the first security review, and put it in the brief.
     That would have saved two iterations.
   - Probe every shell command a skill prints before review, since each one is a claim.
   - For prose-only units, consider k=1 plus a security pass until the final iteration.
