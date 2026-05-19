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
