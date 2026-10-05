Commit: 497c8cb5

# Architecture Review — feat/build-loop-u0a, final confirming pass

**Scope:** `git diff feat/build-loop-handoff..feat/build-loop-u0a` (3 commits: 4ef450da, 32b9ae0e, 497c8cb5) and their messages; the U0b/U0c tips and the plan at the U0c tip as context only
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u0a.md` (merged k=3, Commit 497c8cb5); plan "Approach" with its 2026-10-05 amendment; `docs/reviews/architecture-review-build-loop-handoff.md` (plan-stage review); override-log rows dated 2026-10-05

Scope check: in scope (module structure). U0a creates `scripts/lib/dev-cycle-read.sh`, a new module with a public surface of functions and globals, and moves dev-cycle.sh's output scrub and file rules into it.

Trust-boundary cross-reference: no-op for this unit. `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`, which predates this diff, so its boundaries may be stale) labels B1 (`check_fix`) and B2 (the import walk). Neither is in U0a's range, and this report files no module-boundary finding.

Known items not re-filed:
- Fact-check claims 1–3: need_root's comment about `set -u` is inverted, the header's "read nothing as plain" sentence is too broad, and commit 497c8cb5's message repeats the inverted comment. All three are wording only.
- Override-log rows 196–200: the globals as interface (deferred to U1), "runs both suites" (U1), the Functions index (Won't-Fix), the ~1 ms start-up cost (Won't-Fix), and the D6 hash gap (U3b).

## Dependency Map

```
scripts/dev-cycle.sh ──source "$SCRIPT_DIR/lib/dev-cycle-read.sh" (no fallback; exit 1 if absent)──▶ lib
lib ──▶ perl, realpath, git (none called at source time; T29)
lib ◀── ROOT_REAL (set by caller after cd), cwd; ──▶ SKIPPED / SKIP_AT (globals out)
lib scrub_reexec ──re-exec──▶ "$self" (the caller's own path) under DEV_CYCLE_SCRUBBED
```

Dependencies point one way. The lib reads nothing that dev-cycle.sh defines except the documented `ROOT_REAL` input. I grepped the lib for upper-case expansions at the U0c tip: the only caller-provided names are `ROOT_REAL` and `DEV_CYCLE_SCRUBBED`. Everything else (`DIGIT`, `SLUG`, `NAMECHARS`, `SKIPPED`, `SKIP_AT`, …) is defined in the lib. The caller's own `GIT_LITERAL_PATHSPECS=1` export is not relied on. The lib is the stable layer, and dev-cycle.sh, the volatile consumer, depends on it.

## Findings

No findings.

## What Looks Good

- **The two guard channels fit the module.** `need_root` exits for a broken caller contract. `rawfile`/`plaindir` expand `${ROOT_REAL:-}` and fail closed when called outside it. Exiting from a sourced lib is right here: a caller that forgot to `cd` or to set `ROOT_REAL` cannot recover. The `ROOT_REAL == $(pwd -P)` half (497c8cb5) ties the lib's two implicit inputs, root and cwd, into one checked precondition. That later lets U0c key the walk's cache on `ROOT_REAL` safely.
- **One sourcing path.** `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` has no `~/.claude/scripts` fallback, so the lib and its caller always come from the same tree, as plan-stage finding 3 asked.
- **The header carries the contract.** The header names the consumer, the source idiom, the caller's duties, which functions exit, the `$(...)` caveat, and the shared `DEV_CYCLE_SCRUBBED` marker. Fact-check claims 1 and 2 are wording fixes on top of a sound structure.
- **Scrub as a shared cross-cutting concern.** Moving `scrub` and its re-exec wrapper into the lib takes plan-stage finding 5's option 2: a second script gets the same sanitisation by calling `scrub_reexec`, with no second policy.
- **Tests on the module boundary.** T29 sources the lib and asserts that nothing runs at source time. T30 checks that a copy without its lib exits 1.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

U0a creates a correctly directed, self-contained module. Its inputs are explicit (`ROOT_REAL` and the cwd, checked together), its outputs (`SKIPPED`/`SKIP_AT`, stdout) are documented, and it cannot be sourced from a different tree than its caller. The only open items are the three wording errors the fact-check already carries, and none of them changes the structure. Nothing here blocks landing.

## Goal-Alignment Note

The goal is to land U0a, U0b and U0c after a clean review-fix loop. For U0a, this pass finds no Structural, Coupling or new Minor item. The fact-check's three Incorrect wording clusters (need_root's comment, the header sentence, and commit 497c8cb5's message) are the only remaining work on this unit, and they are the author's to fix or record. I checked the guard conventions that start in this unit, along with U0b's and U0c's additions, under U0b and U0c.
