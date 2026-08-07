Commit: 2dc403e

# Security Review — Corpus filesystem/OPFS storage layer (DD-009 S1)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` — `app/lib/corpus/*` (types, paths, manifest, opfsAdapter, storeAdapter, flag) + `app/lib/stores/workspaceStore.ts` storage-seam swap. Tests are context, not under review.
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/corpus/fact-check.md` (16 claims; 1 Incorrect, 1 Stale, 2 Mostly-accurate)

## Context that bounds severity

This is a single-tenant, self-hosted app (one trust boundary per deploy; CLAUDE.md "Deployment"). OPFS and localStorage are **origin-private** — the only writer of corpus bytes is the app itself. The corpus path is **default-off and dev-only** (`flag.ts`), starts from an empty corpus (no migration until S4), and — critically — the wired store persist path uses the **constant** key `"workspace-zustand-v1"` (→ `state/workspace-zustand-v1.json`), so no untrusted string flows through storage paths in S1. `paths.ts` (the untrusted-title sanitizer) is **built but not called by any consumer in this diff** (confirmed: `storeAdapter.ts` blob mode bypasses it; docstring says folder layout is unused until S4). This drops all path-safety findings to dormant/forward-looking.

Note on PR intent: the brief mentions a "v2→v3 migration/rehydration seam" — no migration code exists in this diff; the flag docstring explicitly defers migration to S4. There is nothing migration-shaped to review here.

## Trust Boundary Map

```
B1 (dormant): [untrusted workspace title / source-id / type] → [workspaceSlug / safeSegment allowlist] → [corpus path under workspaces/]   (new, not yet wired)
B2:           [in-app persist blob, constant key]            → [createCorpusBackedStorage / createDebouncedLocalStorage] → [OPFS file / localStorage]
B3:           [bytes read back from OPFS / manifest JSON]     → [parseManifest JSON.parse + validation]                   → [WorkspaceManifest domain model]
```

B1 is the only boundary carrying untrusted content (user-authored titles/ids), and in S1 nothing crosses it — the sanitizers are dead code awaiting S4. B2 crosses app state to origin-private storage using a compile-time-constant path. B3 reads origin-private bytes (same-origin, single writer) back through a fail-loud parser. No network, auth, crypto, secrets, or command/SQL surface in the diff — so no HALT escalation.

## Findings

#### Slug generation is many-to-one — distinct titles collide to one workspace directory

**Severity:** Medium
**Location:** `app/lib/corpus/paths.ts:36-47` (`workspaceSlug`), `:52-58` (`safeSegment`)
**Boundary:** B1
**Move:** #1 (trust boundaries), #2 (implicit assumption)
**Confidence:** Low (dormant in S1 — not reachable until S4 wires title→path)

`workspaceSlug` collapses every non-`[a-zA-Z0-9_-]` run to a single hyphen, lowercases, and trims. It correctly prevents traversal (`../etc/passwd` → `etc-passwd`, no `/` or `..` survives — good, allowlist is the right pattern), but it is lossy and non-injective: `"My Workspace!"`, `"my workspace"`, `"my/workspace"`, and `"my--workspace"` all map to `my-workspace`. If S4 derives a workspace's directory identity from `workspaceSlug(title)`, two distinct user workspaces silently share `workspaces/my-workspace/` — one overwrites or reads the other's `workspace.json`, sources, and artifacts. That is a cross-workspace integrity/confidentiality failure driven by attacker- or user-chosen titles. It is not exploitable today because no caller passes a title through these builders (the wired path uses the constant key), so confidence is Low — but the guarantee the module's own docstring claims ("keeps untrusted workspace titles inside `workspaces/`") is only half the story: it keeps them *inside*, not *distinct*.

**Recommendation:** Before S4 wires title→path, make workspace identity a collision-free id (e.g. a generated `workspace-<uuid>` directory) with the human title stored *inside* `workspace.json`, or append a content hash/disambiguator to the slug. Do not let two titles resolve to one directory. Add a collision test to `paths.test.ts`.

#### Silent data loss on localStorage quota exceed (default path)

**Severity:** Low
**Location:** `app/lib/corpus/storeAdapter.ts:32-37` (`createDebouncedLocalStorage`)
**Boundary:** B2
**Move:** #3 (error path), #8 (scale)
**Confidence:** High (behavior), Low (severity — pre-existing, integrity not confidentiality)

The default (flag-off, i.e. every end user) write path swallows a quota failure with `console.warn` and drops the write. Because writes are debounced 300 ms and the catch neither retries nor surfaces UI state, a user filling localStorage loses workspace edits silently — the availability/integrity failure the OPFS adapter was explicitly designed to *avoid* (`opfsAdapter.ts` reifies quota to a typed error). This is moved-verbatim pre-existing behavior (fact-check Claim 14), not introduced here, and it is an integrity/durability issue rather than a classic exploit, hence Low.

**Recommendation:** Out of scope to fix in S1, but track it: the corpus path already models `quota-exceeded` as a typed error feeding failure-driven UI; the legacy path should eventually surface the same signal rather than `console.warn`-and-drop.

#### OPFS `writeFile` passes the caller's buffer without the copy its comment claims

**Severity:** Informational
**Location:** `app/lib/corpus/opfsAdapter.ts:115-116`
**Boundary:** B2
**Move:** #4 (TOCTOU)
**Confidence:** High

Per fact-check Claim 8, the comment says "Pass a fresh ArrayBuffer view" but `await w.write(bytes)` passes the untouched parameter — no `slice()`/copy (unlike the in-memory fake). Exploitability is negligible: `writeFile` awaits the write inline, so a caller cannot realistically mutate `bytes` mid-write in single-threaded JS. Flagged only because the false comment could later license a caller to reuse/mutate a shared buffer believing it is defended.

**Recommendation:** Either add `bytes.slice()` (matching the fake, cheap for these payloads) or delete the misleading comment.

#### `readdir` materializes all directory entries unbounded

**Severity:** Informational
**Location:** `app/lib/corpus/opfsAdapter.ts:125-137`, `inMemoryCorpusFs.ts:29-42`
**Boundary:** B2
**Move:** #8 (a million of these)
**Confidence:** High

`readdir` collects every key into an array and sorts. Entry count is bounded only by what the same-origin app writes to origin-private storage; there is no external amplification vector in a single-tenant local store, so this is a scaling note, not a DoS.

**Recommendation:** None required for S1. If artifact-version directories grow unbounded in later sub-tasks, revisit pagination.

## What Looks Good

- **Path sanitization uses an allowlist** (`/[^a-zA-Z0-9_-]+/`), not a denylist/blocklist — the correct pattern; `..`, `/`, `\`, control chars, and (via NFKD + strip) unicode homoglyphs cannot survive. Empty-result throws instead of yielding `""` (no escape to `workspaces/`).
- **Fail-loud manifest parsing.** `parseManifest` never returns a default-empty manifest; malformed/absent input throws a typed `CorpusError`. No prototype-pollution surface: fields are read individually into a fresh literal, no `Object.assign`/spread of parsed input, and `JSON.parse` is used (not `eval`/`Function`).
- **Typed error reification.** OPFS quota and unavailable failures become discriminated `CorpusError`s rather than raw `TypeError`/swallowed warnings — the exhaustive `CorpusErrorKind` union forces future consumers to handle them.
- **Constant persist key.** The wired store path uses a compile-time constant, so the untrusted-title boundary (B1) is genuinely not crossed in S1.
- **Default-off, dev-only flag** with an SSR-safe guard and try/catch around `localStorage` access.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Slug collisions map distinct titles to one workspace dir | Medium | B1 | `paths.ts:36-58` | Low (dormant) |
| 2 | Silent data loss on localStorage quota (default path) | Low | B2 | `storeAdapter.ts:32-37` | High / Low |
| 3 | `writeFile` skips the copy its comment claims | Informational | B2 | `opfsAdapter.ts:115-116` | High |
| 4 | Unbounded `readdir` materialization | Informational | B2 | `opfsAdapter.ts:125-137` | High |

## Overall Assessment

Security posture is solid for what S1 actually ships. The genuinely untrusted boundary (B1, user titles → paths) is not reachable in this diff, and where sanitization is applied it uses the correct allowlist pattern; parsing is fail-loud with no injection or prototype-pollution surface; storage is origin-private in a single-tenant deploy. No High/Critical findings and no escalation. The one thing worth carrying forward before S4: `workspaceSlug` prevents traversal but not *collision* — make workspace directory identity collision-free (uuid dir + title stored inside the manifest) before any user title is used to select a storage path, or distinct workspaces will silently share one directory. Everything else is informational cleanup (fix the false copy comment; eventually surface the legacy quota failure the way the corpus path already does).
