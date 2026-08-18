# Performance Review — mfc-corpus (DD-009 corpus-architecture, `dc6dfb0...HEAD`)

**Commit:** 2dc403e
**Scope:** `git diff dc6dfb0...HEAD` — OPFS/`CorpusFS` storage seam, debounced localStorage adapter, `workspace.json` manifest codec, rehydration/`migrateFromV2` migration. Files: `app/lib/corpus/{storeAdapter,opfsAdapter,manifest,paths,flag,types}.ts`, `app/lib/stores/workspaceStore.ts`.
**Date:** 2026-08-18
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-corpus/code-fact-check-report.md` (18 claims; executed `migrateFromV2` firing and the debounced-adapter behavior)

## Data Flow and Hot Paths

The zustand `persist` middleware selects its storage backend once at init via `resolveWorkspaceStorage()` (`workspaceStore.ts:499`): the **OFF path** returns `createDebouncedLocalStorage()` (300 ms write debounce, synchronous reads); the **ON path** (dev flag `corpus-fs-enabled` / `NEXT_PUBLIC_CORPUS_FS=1`) returns `createCorpusBackedStorage(createOpfsCorpusFs())`, which stores the whole persisted blob as one file `state/workspace-zustand-v1.json` (fact-check claim 13 — Verified; blob mode, single key, single file).

The persist middleware calls `storage.setItem(name, value)` on **every mutation of a persisted field**. In this app those fields include `sourceText`, `semiformalText`, `leanCode`, etc. (`partialize`, `workspaceStore.ts:511-526`), which mutate **per keystroke** in the editor panels. So `setItem` is a high-frequency, hot event callback, and `value` is the full serialized workspace blob (all artifacts, all versions, decomposition) on each call. This is the temperature that governs the findings below.

No measured baselines exist anywhere in the repo or the fact-check report (client-side Next app, no perf dashboard, no load test), so every finding below is flagged speculative.

## Findings

#### OPFS `setItem` is un-debounced — a full-blob multi-op OPFS write fires per state mutation

**Severity:** High
**Location:** `app/lib/corpus/storeAdapter.ts:56-63` (ON-path `setItem`), contrast `:29-39` (OFF-path debounce)
**Move:** 3 (work moved to the expensive location) + 1 (hidden multiplication)
**Classification:** Micro (per-op overhead) escalated by extreme call frequency + large constant factor / Hot path (persist write, fired per keystroke)
**Confidence:** High (that no debounce exists — directly readable); Medium (per-keystroke frequency, inferred from editor→persisted-field mapping)
**Baseline:** no baseline available — flagged as speculative

The OFF path coalesces writes with a 300 ms `setTimeout`/`clearTimeout` debounce (fact-check claim 15 — Mostly accurate; behavior confirmed), so a burst of N keystrokes collapses to one `localStorage.setItem`. The ON-path `setItem` has **no debounce and no coalescing**: it `await fs.writeFile(...)` unconditionally on every call. Each `writeFile` is ~6 sequential async OPFS operations (`getRoot`→`getDirectoryHandle("state",{create})`→`getFileHandle({create})`→`createWritable`→`write`→`close`), each rewriting the *entire* workspace blob. A 100-character edit that costs one debounced localStorage write on the OFF path costs ~100 full-blob OPFS rewrites (~600 OPFS ops) on the ON path. This is pure write amplification introduced by dropping the coalescing the sibling adapter has.

**Recommendation:** Give `createCorpusBackedStorage` the same debounce the localStorage adapter uses (or a trailing-edge coalescing queue), so the OPFS write fires once per idle window rather than per mutation. Capture an OPFS write-latency baseline (one `writeFile` trace of a realistic blob) before/after.

#### Concurrent overlapping OPFS writes to the same state file are not serialized — lost-update ordering hazard

**Severity:** High
**Location:** `app/lib/corpus/storeAdapter.ts:61-63`, `app/lib/corpus/opfsAdapter.ts:107-123`
**Move:** 7 (contention / ordering point)
**Classification:** Macro (write-after-write ordering hazard, independent of scale) / Hot path (per-mutation persist write)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

`setItem` returns the `writeFile` promise, but zustand's persist middleware does **not** await the previous `setItem` before firing the next — async storage writes are dispatched fire-and-forget. Because each `writeFile` is a multi-await sequence with no cross-call queue or lock, two `setItem` calls issued closer together than one `writeFile` round-trip run **concurrently against the same `state/workspace-zustand-v1.json`**, each opening its own writable via `createWritable()`. Completion order is not guaranteed to match issue order, so a slower earlier write can `close()` last and persist a stale full blob over a newer one (classic lost update). The root cause is the same missing serialization as the finding above; the impact here is silent data loss rather than latency. The fact-check "Note for critics" on claim 9 already flags that this awaited `writeFile` has no catch, so a rejection also surfaces as an unhandled rejection into persist.

**Recommendation:** Serialize writes to a given path through a single-flight queue (chain each `writeFile` onto the prior promise for that key, keeping only the latest pending value). A debounce (previous finding) largely subsumes this by ensuring at most one in-flight write per idle window; the queue closes the residual race.

#### `getRoot()` re-resolves the OPFS root directory handle on every operation

**Severity:** Low
**Location:** `app/lib/corpus/opfsAdapter.ts:49-55`, called from every method (`:89,109,127,141,158`)
**Move:** 1 (hidden multiplication)
**Classification:** Micro (one extra async resolution per op) / Hot path (every read/write)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

Every `readFile`/`writeFile`/`readdir`/`rm`/`stat` calls `await storage.getDirectory()` afresh; the root handle is never cached across calls. `getDirectory()` is normally cheap, but on the un-debounced write path above it adds one more await to each of the amplified writes. Minor on its own; it compounds the amplification.

**Recommendation:** Memoize the resolved root handle (lazy singleton promise) after the first successful `getRoot()`, keeping the SSR/unavailable guard on the first resolution. Fold this in when adding the write debounce.

#### `migrateFromV2` and the rehydrate guard parse cost is a cold, once-per-load path

**Severity:** Informational
**Location:** `app/lib/stores/workspaceStore.ts:251-285` (`migrateFromV2`), `:528-543` (`onRehydrateStorage` guard)
**Move:** 2 (size of N) / 3 (work placement)
**Classification:** Macro-shaped work (O(stored-blob size) parse) / Cold path (runs once, on rehydrate at app load)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

The rehydrate guard does one `localStorage.getItem` + `JSON.parse` of the persisted zustand blob to test for `state.sourceText`, then `migrateFromV2` (when it fires) does one `loadWorkspace()` (localStorage read + parse) and a bounded loop over the fixed `PERSISTED_ARTIFACT_FIELDS` set (~6 entries), then a single batched `setState`. Cost scales with the stored workspace size but runs exactly once per app load and is inert when no v2 data exists (fact-check claim 17 — executed: returns `false`/no-op absent v2 data). Not a hot-path concern; noted only to confirm it was assessed. The double parse (guard-parse then `loadWorkspace` re-parse of the *legacy* key — different keys, so not redundant) is acceptable at load-time frequency.

**Recommendation:** None required. If load-time TTI becomes a concern with very large stored workspaces, defer migration behind the first idle callback.

## Endorsements (evidence-gated)

- The OFF (default) path preserves the prior 300 ms write-coalescing debounce, so end-user persistence behavior is unchanged by this diff — the amplification is confined to the dev-only ON path. `[fact-check: claim 15 — Mostly accurate]`
- In S1 the store persists as a single blob file (`state/<name>.json`), so **no per-write `workspace.json` manifest encode/decode and no folder-per-artifact traversal is incurred by the store yet** — the manifest codec and `walkDir` deep-traversal cost do not touch the write path until S4. `[fact-check: claim 13 — Verified]`
- `migrateFromV2` is a once-per-rehydrate load-time path that no-ops when no legacy `workspace-v2` data is present, so it adds no steady-state or hot-path cost. `[fact-check: claim 17 — Mostly accurate]`
- For the S1 blob layout, `walkDir` is only ever asked to resolve a depth-1 `state/` prefix (one `getDirectoryHandle`), so traversal cost is O(1) per op at current usage — the O(depth) loop only bites once the folder layout is wired in. `[read: app/lib/corpus/storeAdapter.ts:55, app/lib/corpus/opfsAdapter.ts:66-77]`

## Submitted claims (unverified)

- The zustand persist middleware dispatches `setItem` on each persisted-state mutation without awaiting the prior async `setItem`, so two OPFS writes to the same key can be in flight simultaneously. `[unverified — submitted as claim]` — decidable by reading zustand's persist source or by an executed test firing two rapid `setItem` calls against a stubbed slow `writeFile` and observing overlap; underlies the ordering-hazard finding.
- In the editor panels, a single keystroke mutates a persisted field (`sourceText`/`semiformalText`), producing one persist `setItem` per keystroke. `[unverified — submitted as claim]` — decidable by tracing the editor onChange→store `set` path (outside the reviewed diff); governs the frequency multiplier in the amplification finding.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Un-debounced full-blob OPFS write per mutation (write amplification) | High | `storeAdapter.ts:56-63` | High / Medium |
| 2 | Un-serialized concurrent writes to same state file (lost-update race) | High | `storeAdapter.ts:61-63`, `opfsAdapter.ts:107-123` | Medium |
| 3 | `getRoot()` re-resolves OPFS root every op (no caching) | Low | `opfsAdapter.ts:49-55` | High |
| 4 | `migrateFromV2`/rehydrate parse cost (cold, once per load) | Informational | `workspaceStore.ts:251-285,528-543` | High |

## Overall Assessment

The performance risk is concentrated in one place: the ON-path `createCorpusBackedStorage.setItem` is a bare `await fs.writeFile` with neither the write-coalescing debounce its sibling adapter has nor any cross-call serialization. On a persist path that fires per keystroke, that yields both write amplification (a full multi-op OPFS blob rewrite per mutation instead of one debounced write per idle window) and an ordering hazard (overlapping writes to the same file can persist a stale blob). Both are fixable in place and with the same change — add a trailing-edge debounce plus a single-flight per-key write queue — so this is not a structural problem, just an incomplete port of the adapter's coalescing behavior. Because the ON path is dev-only and default-off (fact-check claims 2, 15), nothing here reaches end users today, but it must be resolved before the flag is promoted (S4) since the same seam is slated to carry migrated user data. The manifest codec, `walkDir` traversal, and migration paths are not current hot-path concerns and were confirmed cold or unwired at S1. The two findings that gate promotion (1 and 2) warrant a written OPFS write-latency baseline and a concurrency test before merge — neither can be confirmed from code structure alone.
