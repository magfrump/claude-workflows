Commit: b64c1ca

# API Consistency Review — fscompat (dataDir writable-dir routing)

**Scope:** branch diff `d86d2dc..b64c1ca` (full-branch changeset) — `app/lib/utils/dataDir.ts` (new), `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`
**Date:** 2026-08-06
**Based on:** code fact-check report at `/workspace/runs/review-arms/baseline-2026-08-06/fscompat/fact-check.md`

The only new consumer-facing surface is the exported `dataDir(...subpaths)` helper in `app/lib/utils/`. The two call sites (`persist.ts`, `cache.ts`) do not change their own exported signatures — `appendAnalyticsEntry`, `readAnalyticsEntries`, `clearAnalyticsEntries`, `getCachedResult`, `setCachedResult`, `removeCachedResult`, `computeHash` are all untouched in shape. So the review reduces to: (a) does `dataDir` match `app/lib/utils/` conventions, and (b) do the call sites preserve their pre-diff contract.

## Baseline Conventions

Surveyed `app/lib/utils/*.ts` (18 files) and `process.env` usage across `app/lib` + `app/api`:

- **Util exports:** bare named functions, camelCase, mostly verb-led (`saveWorkspace`, `loadWorkspace`, `parseLatexPropositions`, `extractTextFromFile`, `downloadLeanCode`, `topologicalSort`, `throttle`). No `DTO`/`I`-prefix/suffix conventions; no default exports; no wrapper objects.
- **Env branching:** existing reads use `process.env.X ?? <default>` (`callLlm.ts:112-113`, `verification/lean/route.ts:4`, `streamLlm.ts:105`). `dataDir` uses a boolean-presence ternary on `process.env.VERCEL`, which is the correct idiom here (VERCEL is a presence flag, not a value), so this is a reasonable variant rather than a deviation.
- **Path construction:** call sites use `join(process.cwd(), "data", ...)` inline (this is exactly what the diff centralizes). There is no pre-existing path/dir-resolution helper — `dataDir` is the first of its kind.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `dataDir` | function (exported) | `saveWorkspace`, `loadWorkspace`, `topologicalSort`, `throttle` | `app/lib/utils/*.ts` | Acceptable — noun-shaped rather than verb-led, but no precedent exists for a path/dir *resolver* util; utils names are not uniformly verb-led (`throttle`, `topologicalSort`). See Finding 1. |
| `subpaths` | parameter (rest) | no existing variadic path param | none — searched `app/lib/utils/` and all `join(...)` call sites in `app/lib` | New — first variadic path helper; naming is clear. |

No new routes, types, classes, enum variants, error codes, or event names are introduced.

## Findings

#### `dataDir` is noun-shaped where most utils are verb-led, and reads ambiguously as a getter vs. a mkdir

**Severity:** Informational
**Location:** `app/lib/utils/dataDir.ts:12`
**Move:** #2 (naming against the grain)
**Confidence:** Medium

No existing precedent in `app/lib/utils/` (searched all 18 util modules; no prior path- or directory-resolution helper exists). Most util exports are verb-led (`saveWorkspace`, `extractTextFromFile`, `parseLatexPropositions`), so a bare noun `dataDir` reads slightly against the grain, and the name does not signal that it only *computes* a path (it does not create the directory — callers still call `mkdirSync`/`mkdir` themselves, see `persist.ts:13`, `cache.ts:30`). A reader could reasonably expect `dataDir()` to ensure the directory exists. Because no precedent exists for this category, the naming claim floors at Informational per the precedent rule — this is establishing a new convention, not violating one.

**Recommendation:** Optional. If the author wants to align with the verb-led majority and make the compute-only nature explicit, `dataDirPath(...)` or `resolveDataDir(...)` would read more clearly; `dataDir` is acceptable as-is since it is the first resolver of its kind. Worth a deliberate choice now because future writable-path helpers will copy it.

#### Dead cross-reference in the new analytics comment ("see Deploy to Vercel in README")

**Severity:** Minor
**Location:** `app/lib/analytics/persist.ts:6-7`
**Move:** #3 (documentation drift)
**Confidence:** High

Per the fact-check report (Claim 1, Incorrect/High), the comment directs readers to a "Deploy to Vercel" section in the README that does not exist. This is a documentation-contract issue, not a code-behavior one — the behavioral half of the comment is accurate. A consumer reading the code for the persistence rationale is sent to a non-existent anchor; the authoritative rationale actually lives in the `dataDir` docstring (`dataDir.ts:3-11`), which the same comment also (correctly) references.

**Recommendation:** Drop the "see Deploy to Vercel in README" clause (the `dataDir()` reference already carries the rationale), or add the missing README section. Prefer dropping it, since duplicating the rationale invites the same drift.

#### Inconsistent use of the new helper across the two call sites

**Severity:** Informational
**Location:** `app/lib/analytics/persist.ts:8-9` vs. `app/lib/llm/cache.ts:7`
**Move:** #7 (asymmetry)
**Confidence:** Medium

`cache.ts` uses the variadic form (`dataDir("cache")`) to reach its subdirectory, while `persist.ts` calls `dataDir()` and then composes the final file path with a separate `join(DATA_DIR, "analytics.jsonl")` (`persist.ts:9`). Both are correct and both preserve pre-diff behavior (confirmed by fact-check Claim 3). The asymmetry is only that the helper's variadic feature is used in one place and bypassed in the other. This is not a defect — a file leaf (`analytics.jsonl`) is arguably clearer composed at the call site — but it means the two adopters model "how you use `dataDir`" differently, which future callers will imitate unevenly.

**Recommendation:** No change required. If uniformity is desired, note in the docstring that `subpaths` is intended for subdirectories/leaves so callers converge on one style.

## What Looks Good

- **Backward-compatible off-Vercel:** both call sites resolve to byte-identical paths when `VERCEL` is unset (fact-check Claim 3, verified) — no consumer of the analytics or cache modules is affected in dev/self-hosted.
- **No signature changes** to any of the seven exported functions in `persist.ts`/`cache.ts`; the refactor is purely internal to the DATA_DIR/CACHE_DIR constants.
- **Variadic `...subpaths`** is a clean, extensible signature that will absorb future writable-path needs without an API change.
- **Docstring rationale** on `dataDir` (`dataDir.ts:3-11`) is the right place for the platform explanation and is correctly cross-referenced from `persist.ts`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `dataDir` noun-shaped / getter-vs-mkdir ambiguity | Informational | `dataDir.ts:12` | Medium |
| 2 | Dead "Deploy to Vercel in README" cross-reference | Minor | `persist.ts:6-7` | High |
| 3 | Uneven use of the helper across call sites | Informational | `persist.ts:8-9` / `cache.ts:7` | Medium |

## Overall Assessment

Consistent with the codebase's API patterns. The change introduces exactly one new public name (`dataDir`), preserves every existing exported signature, and keeps off-Vercel behavior byte-identical, so there is no consumer-breaking surface. All findings are Informational/Minor and fixable in place — the only actionable item is the dead README cross-reference (Finding 2). No High/Breaking/blocking issues.
