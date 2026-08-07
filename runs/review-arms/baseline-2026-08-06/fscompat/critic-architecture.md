Commit: b64c1ca

# Architecture Review — wt-fscompat (dataDir persistence routing)

**Scope:** branch diff `d86d2dc..b64c1ca` (full-branch changeset)
**Date:** 2026-08-06
**Based on:** code fact-check report at `/workspace/runs/review-arms/baseline-2026-08-06/fscompat/fact-check.md`
**PR intent:** Route server-side persistence (analytics, LLM cache) to a Vercel-compatible writable dir via a new `dataDir()` util (`/tmp` on Vercel, repo `data/` elsewhere).

Trust-boundary cross-reference: no `docs/reviews/security-review-*.md` present — the security integration section is a no-op for this review.

## Dependency Map

The diff introduces one new leaf utility, `app/lib/utils/dataDir.ts`, exporting a single pure-ish function `dataDir(...subpaths)`. Two existing persistence modules now depend on it:

- `app/lib/analytics/persist.ts` → `dataDir()` (was `join(process.cwd(), "data")`)
- `app/lib/llm/cache.ts` → `dataDir("cache")` (was `join(process.cwd(), "data", "cache")`)

Dependency direction is correct: volatile infrastructure/persistence modules depend on a stable, low-level utility. No inversion, no new dependency from a stable module toward a volatile one, no cycle. `dataDir` itself depends only on Node's `path` and `process` — no upward or lateral imports. This is a textbook centralization of a previously duplicated cross-cutting concern (writable-directory policy): the `/tmp`-vs-`data/` decision that would otherwise be copy-pasted at each call site now has exactly one home and one reason to change.

Verified via `rg` that these are the only three filesystem/`process.cwd` sites in `app/`; the migration is complete — no call site was left resolving its own path.

## Findings

#### Server-only utility placed in a mixed client/server `lib/utils/` folder

**Severity:** Informational
**Location:** `app/lib/utils/dataDir.ts:1-15`
**Move:** #3 Audit the module boundary
**Confidence:** Medium

`lib/utils/` is dominated by client-safe/pure helpers (`textSelection`, `latexParser`, `stripCodeFences`, `topologicalSort`, `throttle`, `export*`, and `workspacePersistence` which is localStorage/client-only). `dataDir` is the opposite kind of module: it reads `process.env.VERCEL` and `process.cwd()`, so it is server-only and meaningless (indeed broken) in a browser bundle. Co-locating a server-only function in a folder consumers reach into for client utilities blurs the implied client/server boundary. Concrete consequence: if a future client component imports a sibling and the bundler pulls `dataDir` transitively, `process.cwd()` has no browser equivalent. Today the only importers are the two server-side persistence modules, so there is no live breakage.

**Recommendation:** Consider a `lib/server/` (or `lib/persistence/`) home for server-only utilities so the client/server split is legible from the path. Low priority — pragmatically fine at current scale with only two server-side callers.

#### Platform detection hardcoded to a single provider (Vercel)

**Severity:** Informational
**Location:** `app/lib/utils/dataDir.ts:13`
**Move:** #8 Evaluate extension points
**Confidence:** High

The writable-dir policy is a two-branch ternary keyed on `process.env.VERCEL`. Any additional read-only-FS host (AWS Lambda, Cloud Run, etc.) would fall into the `else` branch and silently attempt to write to `<cwd>/data`, which fails at runtime rather than routing to `/tmp`. Adding such a platform means editing this expression (a modify, not an extend). With only two cases today this is the pragmatically correct shape — a strategy/registry abstraction would be over-engineering — so this is noted only as the extension point to revisit if a third target appears.

**Recommendation:** No action now. If a second read-only-FS platform is ever added, generalize to a "is-read-only-FS / writable-base" resolver rather than growing the ternary.

## What Looks Good

- **Single source of truth for the writable-dir policy.** Centralizing the `/tmp`-vs-`data/` decision into `dataDir()` removes the duplication that previously lived independently in `persist.ts` and `cache.ts`. Future changes to the persistence-location policy touch one file (correct SRP for a cross-cutting concern).
- **Correct dependency direction and minimal surface.** One small exported function, variadic `subpaths` for composition, depends only on `path`/`process`. No leaked internals, no widened interface on the consuming modules.
- **Complete, behavior-preserving migration.** All three fs sites are accounted for; off-Vercel behavior is byte-identical to the pre-diff paths (confirmed by fact-check Claims 2-4), so no consumer contract changed.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Server-only util in mixed client/server utils folder | Informational | `app/lib/utils/dataDir.ts:1-15` | Medium |
| 2 | Platform detection hardcoded to Vercel (OCP) | Informational | `app/lib/utils/dataDir.ts:13` | High |

## Overall Assessment

This change improves the system's structural integrity. It replaces duplicated, inline path-resolution logic with a single stable utility that the persistence modules depend on in the correct direction — a net reduction in coupling and a proper home for a cross-cutting concern. There are no Structural or Coupling findings: no dependency inversion, no layer violation, no cycle, no widened public surface, and the migration is complete. The only observations are Informational and about future-proofing (module placement legibility and single-provider platform detection), neither warranting action at the current scale. The dead README cross-reference flagged by the fact-check (Claim 1) is a documentation-accuracy issue, not architectural, and is out of this review's domain.
