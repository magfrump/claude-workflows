# 013: Failure-pattern library after bug-diagnosis removal

**Date:** 2026-05-18
**Status:** Accepted

## Context
Bug-diagnosis workflow and skill removed in favor of superpowers:systematic-debugging. The failure-pattern library at docs/thoughts/failure-patterns.md had its write-side in bug-diagnosis step 8.

## Options considered
A. Wrap superpowers:systematic-debugging with a local pre/post step.
B. Move grep-and-append discipline into RPI (read) and pr-prep (write).
C. Deprecate the library entirely.

## Decision
**Option B.** Lowest cost preservation of the cumulative-pattern-learning loop. Decouples discipline from any single skill.

## Consequences
- pr-prep workflow now owns the write-side prompt.
- Header of failure-patterns.md updated to reflect new paths.
- Read-side (RPI research grep audit) unchanged.
- **Known trigger gaps in Option B (vs. the old step-8 always-runs design):** (a) the advisory only fires when a branch contains `fix(...)`-prefixed commits — fixes shipped on `refactor:`, `chore:`, or other prefixes are invisible to the trigger; (b) pr-prep is itself optional (sole-contributor workflows or hotfix branches that skip pr-prep get no prompt). The library will accumulate more slowly than under step-8. Revisit if the pattern-learning loop visibly decays.

## Addendum (2026-07-09)

The superpowers plugin was uninstalled (it raised flags in the trusted-policy security audit, and this repo had already replicated most of its value). The references above to `superpowers:systematic-debugging` are historical: the diagnostic loop now lives entirely in CLAUDE.md's Debugging defaults section, which was always the local extension and now stands alone as the full loop.
