Commit: 2dc403e

# Performance Review — Corpus filesystem/OPFS storage layer (DD-009 S1)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` (app/lib/corpus/*, app/lib/stores/workspaceStore.ts)
**Date:** 2026-08-06
**Based on:** code fact-check report at `/workspace/runs/review-arms/baseline-2026-08-06/corpus/fact-check.md`

## Data Flow and Hot Paths

The diff adds a `CorpusFS` abstraction and an OPFS adapter, plus a storage-seam
selector (`resolveWorkspaceStorage`) wired into the Zustand `persist` middleware
of the workspace store. Two paths exist:

- **OFF (default):** `createDebouncedLocalStorage` — moved verbatim from
  `workspaceStore.ts`; reads sync, writes debounced 300 ms. This path is
  unchanged behavior (fact-check Claim 14) and carries no new perf risk.
- **ON (dev flag, default-off):** `createCorpusBackedStorage(createOpfsCorpusFs())`
  — stores the whole persist blob as a single file `state/workspace-zustand-v1.json`
  in OPFS ("blob mode", S1). This is the path where the persistence hot path
  changes.

The Zustand persist middleware calls `storage.setItem` on **every persisted
state change** — the deleted debounce comment states this explicitly ("avoids
JSON.stringify on every keystroke"). So `setItem` is a hot path (per-mutation,
potentially per-keystroke). `getItem` runs once per page load (rehydrate). The
manifest/paths codecs are built but NOT used by the store in S1 (blob mode), so
they are cold in this diff.

No performance measurements were provided or found in the repo; every finding
below is flagged speculative.

## Findings

#### Corpus-backed storage drops the write debounce — full-blob serialize + OPFS write on every state change

**Severity:** High
**Location:** `app/lib/corpus/storeAdapter.ts:52-68` (esp. `setItem`, `:61-63`)
**Move:** Find the work that moved to the wrong place (#3) + hidden multiplication (#1)
**Classification:** Macro (work proportional to full state size, fired per mutation) / Hot path (persist `setItem` fires per state change / per keystroke)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

The localStorage adapter deliberately debounces writes by 300 ms — the original
comment says it exists "to avoid JSON.stringify on every keystroke." The new
corpus-backed adapter's `setItem` has **no debounce**: it `await fs.writeFile(...)`
on every call, re-serializing and rewriting the entire workspace blob to OPFS
each time. This reintroduces exactly the write-amplification the debounce was
added to prevent — now against OPFS (open writable → write whole blob → close),
which is more expensive per write than a `localStorage.setItem`. Because the blob
is the full serialized workspace, cost grows with workspace size AND with edit
frequency; under active editing this is a full re-serialize + file rewrite per
keystroke. A secondary hazard: with no debounce and async writes, rapid `setItem`
calls launch overlapping `createWritable`/`write`/`close` cycles on the same
file with no ordering guarantee (contention / possible last-writer-wins races),
whereas the localStorage path coalesces to one write per quiet period.

Current blast radius is limited because the flag is dev-only and default-off
(CLAUDE.md), so no end user hits this today. But the seam is explicitly designed
to become the real persistence path in S3/S4, and shipping it without the
debounce would regress the store's write behavior the moment the flag is turned
on.

**Recommendation:** Apply the same 300 ms debounce (and write-coalescing) to
`createCorpusBackedStorage.setItem` before this path is enabled — or move the
debounce up so both adapters share it. Capture a baseline (serialize+write time
for a realistic workspace blob) so the change is measurable.

#### OPFS root + `state/` directory handle re-resolved on every operation

**Severity:** Low
**Location:** `app/lib/corpus/opfsAdapter.ts:49-55, 107-123` (`getRoot`, `writeFile`); called via `storeAdapter.ts:56-67`
**Move:** Hidden multiplication (#1)
**Classification:** Micro (per-call constant overhead: `getDirectory()` + `walkDir` re-resolves the `state/` dir handle) / Hot path (per persist write)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

Every `readFile`/`writeFile`/`rm` calls `getRoot()` (`navigator.storage.getDirectory()`)
and then `walkDir` to re-resolve directory handles from the root. For the store's
single fixed `state/` path this repeats the same directory-handle resolution on
every write. It is constant-factor (one extra dir hop) and only bites in
combination with Finding 1's per-keystroke cadence; on its own it is minor. Not
worth micro-optimizing while writes are debounced to one per quiet period.

**Recommendation:** Optional — if profiling after the debounce fix still shows
write latency, memoize the root/`state` handle. Do not add caching prematurely;
fix the debounce (Finding 1) first.

#### `readdir` reads all directory keys into an array and sorts unconditionally

**Severity:** Low
**Location:** `app/lib/corpus/opfsAdapter.ts:125-137`
**Move:** Trace the memory lifecycle (#4) / asymptotic behavior (#9)
**Classification:** Macro (materializes all entries + O(k log k) sort) / Cold path (not used by the store in S1 blob mode)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`readdir` drains the async `keys()` iterator into a full array and then sorts it
every call. Directory sizes are bounded by workspace content (artifact
versions, sources), and this is not on the S1 store path, so impact is
negligible now. Worth noting for S4 when per-artifact folders are enumerated:
an artifacts dir with many versions would materialize + sort all of them per
listing. The sort is contract-driven (stable ordering) and fine at expected
sizes.

**Recommendation:** No action for S1. When S4 enumerates version files, confirm
the per-type version count stays bounded (or paginate) before relying on
`readdir` in a hot path.

#### `serializeManifest` pretty-prints with 2-space indent

**Severity:** Informational
**Location:** `app/lib/corpus/manifest.ts:56-58`
**Move:** Serialization tax (#6)
**Classification:** Micro (larger byte payload) / Cold path (manifest not written on the store hot path in S1)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

`JSON.stringify(m, null, 2)` inflates the manifest size for human-readability.
The manifest is small (index only, not artifact bodies) and written infrequently,
so this is fine — noting only so it is a conscious choice if manifests ever get
large or write-frequent.

**Recommendation:** Keep as-is (readable diffs are worth the bytes) unless
manifests become large/hot later.

## What Looks Good

- **Blob mode keeps S1 a single read / single write** (`storeAdapter.ts:55-67`):
  one `readFile` per load and one `writeFile` per save, no per-artifact fan-out.
  This is the right shape for the substrate swap and avoids an N-file N+1 on
  rehydrate.
- **`writeFile` passes `bytes` through without a copy** (`opfsAdapter.ts:116`):
  avoids an extra full-buffer allocation per write. (The comment claiming a
  "fresh ArrayBuffer view" is wrong per fact-check Claim 8 — a correctness/comment
  issue, not a perf one; from a perf angle the no-copy is preferable.)
- **`parseManifest` is a single O(n) pass** over sources/artifacts/customTypeIds
  with no nested scans (`manifest.ts:74-115`); appropriate for an index parse.
- **OFF path is byte-for-byte the prior debounced localStorage behavior**
  (fact-check Claim 14) — no regression for the default configuration.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Corpus-backed storage drops write debounce (full-blob write per state change) | High | `storeAdapter.ts:52-68` | Medium |
| 2 | OPFS root/`state` dir handle re-resolved every op | Low | `opfsAdapter.ts:49-55,107-123` | Medium |
| 3 | `readdir` materializes + sorts all keys | Low | `opfsAdapter.ts:125-137` | High |
| 4 | `serializeManifest` pretty-prints | Informational | `manifest.ts:56-58` | High |

## Overall Assessment

The performance posture of this change is good on the default (OFF) path — it is
the prior behavior, moved verbatim. The one substantive concern is on the
flagged corpus path: `createCorpusBackedStorage` reintroduces write-per-mutation
by omitting the 300 ms debounce that the localStorage adapter has, so under
active editing it re-serializes and rewrites the entire workspace blob to OPFS on
every state change (Finding 1). It is dev-only and default-off today, so it harms
no end user now, but it should be fixed before the flag is enabled in S3/S4 —
ideally by sharing one debounce across both adapters. All other findings are
Low/Informational and mostly forward-looking (S4). No issue here indicates a
structural problem; Finding 1 is fixable in place. Confirming Finding 1's impact
requires a benchmark of blob serialize+OPFS write latency at a realistic
workspace size, since no baseline measurements exist.
