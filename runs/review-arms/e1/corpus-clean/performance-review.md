# Performance Review — corpus-clean (dc6dfb0..4de2b00, app/ only)

**Scope:** `git diff dc6dfb0..4de2b00 -- app/` — 15 files, +1226/-33. Corpus S0/S1 substrate (`app/lib/corpus/*`) plus the storage-seam swap in `app/lib/stores/workspaceStore.ts`. `docs/**` is context, not under review.
**Date:** 2026-08-06
**Based on:** merged code-fact-check (k=3), treated as foundation and not re-verified.
**Commit:** 4de2b00

---

### Data Flow and Hot Paths

One write path matters, and it forks at exactly one line.

Every mutation of the workspace store — including every keystroke into the source/semiformal/lean editors — goes through zustand's `persist` middleware:

```
keystroke
  → set(...) in workspaceStore
  → persist subscriber fires
  → partialize(state)                     [workspaceStore.ts:511-526]
  → JSON.stringify(...)                   [inside zustand createJSONStorage]
  → storage.setItem("workspace-zustand-v1", json)
       ├─ OFF (default, everyone):  debounce 300ms → localStorage.setItem   [storeAdapter.ts:28-49]
       └─ ON  (dev only):           safeSegment(name) → OPFS write, no debounce [storeAdapter.ts:55-71]
```

The fork is chosen once, by `resolveWorkspaceStorage()` (`storeAdapter.ts:74-79`), which zustand v5's `createJSONStorage` invokes eagerly when the module is evaluated. `zustand ^5.0.13` is pinned in `package.json:33`; `node_modules` is absent in this worktree, so the internal `createJSONStorage` semantics below are asserted from the pinned version's published implementation and the call shape, not from reading installed source — confidence is noted per finding.

**Temperature assignment used throughout:**

- **localStorage branch — HOT.** It is the default, it runs for every user, and it fires on every state change, i.e. per keystroke in a text editor.
- **Corpus/OPFS branch — COLD.** Flag-off by default (`flag.ts:15-31`), *and* hard-refused in production builds (`flag.ts:21`). It is reachable only in a dev build with an explicit env var or a hand-set `localStorage` key. Per the hot-path gate, nothing on this branch is eligible for Critical or High today. Several findings here would re-rank sharply if S4 ever flips the flag on for users, and each says so.

The corpus branch stores the entire persist blob as a **single file** (`state/workspace-zustand-v1.json`), not the files-per-artifact layout — `paths.ts:70-85` and `storeAdapter.ts:10-14` both say so explicitly. `paths.ts`/`manifest.ts` are built but unreferenced by the store in S1, so their cost is latent, not live.

Size of N: the persisted blob carries `sourceText`, `extractedFiles` (full extracted text of every uploaded document), `contextText`, `semiformalText`, `leanCode`, `artifacts` (up to `MAX_VERSIONS = 20` full-content versions per artifact type, `app/lib/types/artifactStore.ts:37`), the decomposition node graph, and custom artifact data. This is a document-sized payload that grows monotonically with a session, not a handful of scalars. Treat "one write" as "one O(workspace) serialization," never as O(1).

---

### Findings

#### F1 — `partialize` + `JSON.stringify` run per keystroke, outside the debounce

**Severity:** High (pre-existing; preserved deliberately by this diff, not introduced by it)
**Location:** `app/lib/stores/workspaceStore.ts:496`, `:511-526`; `app/lib/corpus/storeAdapter.ts:28-49`
**Move:** Hidden multiplications (per-keystroke partialize/stringify); size of N; serialization tax.
**Classification:** Macro / Hot — this is the default branch for 100% of users, and it fires on every `set()`, which in the editors means every keypress.
**Confidence:** Medium-high on the mechanism, medium on the zustand internals. `zustand ^5.0.13`'s `createJSONStorage` builds `setItem` as `storage.setItem(name, JSON.stringify(newValue, replacer))` — the stringify is on zustand's side of the seam, and the adapter's `setItem` is the *last* step. The debounce is inside the adapter, so it throttles only the `localStorage.setItem` syscall. Not verified against installed source (`node_modules` absent in this worktree).
**Baseline:** no baseline available — flagged as speculative.
**Evidence:**

```ts
      storage: createJSONStorage(resolveWorkspaceStorage),
```

and, inside the adapter that receives the already-serialized string:

```ts
    setItem: (name, value) => {
      if (pending) clearTimeout(pending);
      pending = setTimeout(() => {
        try {
          localStorage.setItem(name, value);
```

`value` arrives as a `string`. Whatever produced that string ran before the debounce could have any effect.

**Legibility-target:** A reader of `storeAdapter.ts` should be able to tell what the debounce does and does not cover without opening zustand's internals. Today the comment says "writes are debounced by 300ms," which is true of the write and false of the work that dominates it.

The debounce collapses N keystrokes into one `localStorage.setItem`, but `partialize` (which rebuilds a 13-field object and calls `sanitizeDecomposition`) and `JSON.stringify` over the full workspace blob still run N times. The scaling factor is the product of two things that both grow: typing rate × blob size. At 8 keystrokes/second against a workspace holding a few uploaded documents plus twenty retained artifact versions, this is eight full serializations per second of a payload measured in hundreds of kilobytes — on the main thread, in the same frame budget as the editor's own re-render. The 300ms debounce hides the syscall and none of the CPU. This diff does not make it worse; the characterization test at `app/lib/stores/__tests__/workspaceStore-characterization.test.ts` exists precisely to prove the OFF path is byte-for-byte unchanged, and that goal was met. It is reported at its real severity because a measurement run should record the state of the code, and because the storage-seam refactor was the natural moment to fix it.

**Recommendation:** Move the throttle up one level — debounce or `requestIdleCallback` the *state-change → persist* trigger rather than the storage write, e.g. by wrapping the persist subscription or by having `partialize` short-circuit on an unchanged reference the way `sanitizeDecomposition` already does at `workspaceStore.ts:296-298`. Before doing anything, measure: instrument `JSON.stringify` duration against a realistic loaded workspace and record the number here, because the fix is only worth its complexity if the serialization is actually multi-millisecond.

---

#### F2 — Corpus branch writes the full blob on every state change with no debounce

**Severity:** Medium
**Location:** `app/lib/corpus/storeAdapter.ts:55-71`
**Move:** Hidden multiplications (per-set corpus writes); work moved to the wrong place.
**Classification:** Macro / Cold — the write cost scales with the whole workspace blob and the trigger rate is per-keystroke, but the branch is flag-off by default *and* hard-refused in production (`flag.ts:21`), making it strictly a dev path at this commit.
**Confidence:** High. The code is unambiguous and the author acknowledged it; the fact-check confirms it is carried forward to S2/S3 as a known item.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:**

```ts
    setItem: async (name, value) => {
      await fs.writeFile(pathFor(name), enc.encode(value));
    },
```

**Legibility-target:** The asymmetry between the two branches — one rate-limited, one not — should be visible at the point of the fork in `resolveWorkspaceStorage`, not discoverable only by reading both closures side by side.

The default branch immediately above it in the same file carries a 300ms debounce; this one carries none. Where the OFF path performs one OPFS-equivalent write per 300ms burst, the ON path performs one complete file rewrite per keystroke — a factor of roughly 100× more writes during sustained typing at 8 keys/second, each write re-encoding and re-persisting the entire workspace rather than a delta. The dev-only status is what keeps this out of High: no user can reach it. But dev machines are also where the substrate's behavior gets characterized, and an un-debounced path will produce OPFS timings that nobody should generalize from.

**Recommendation:** Carry the same debounce across the fork before S2 lands, or lift the throttle above the fork entirely (which is also the F1 fix, and would resolve both with one change). If it is intentionally left un-debounced for S1 to stress the substrate, say so in the `storeAdapter.ts` header comment, which currently explains the blob-mode choice but not the missing rate limiter.

---

#### F3 — Async `setItem` has no write serialization; overlapping writes race on one file

**Severity:** Medium
**Location:** `app/lib/corpus/storeAdapter.ts:64-67`; `app/lib/corpus/opfsAdapter.ts:116-132`
**Move:** Contention (concurrent `setItem` races); memory lifecycle.
**Classification:** Macro / Cold — the number of simultaneously in-flight writes is unbounded and grows with typing rate; cold for the same flag/production-refuse reason as F2.
**Confidence:** Medium. Depends on whether zustand v5's persist awaits the previous `setItem` before issuing the next; the call is fire-and-forget from the subscriber's perspective in the published implementation, but `node_modules` is absent so this was not confirmed against installed source.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:**

```ts
      try {
        // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
        await w.write(bytes);
      } finally {
        await w.close();
      }
```

**Legibility-target:** An adapter that can have several writers open on the same path at once should say what the intended ordering guarantee is. `CorpusFS`'s doc block in `types.ts:106-111` specifies path shape and directory creation but is silent on concurrent-write semantics.

Each `writeFile` opens its own `createWritable()` handle, and OPFS `createWritable()` defaults to a truncating swap file that is committed atomically on `close()`. Two writes issued 20ms apart therefore both open, both write full-but-different snapshots, and the one that closes *last* wins — which is not necessarily the one issued last, since encode/write durations vary with payload size. Combined with F2's per-keystroke rate, a fast typist can have several full-blob writers in flight simultaneously, each holding its own complete copy of the blob in memory, and the persisted result can be an older snapshot than the one in the store. This is a correctness-under-load problem more than a throughput problem, which is why it sits at Medium despite the cold path; it would be High the moment the flag ships to users.

**Recommendation:** Serialize writes per path in `createCorpusBackedStorage` — a single-slot "latest wins" queue is enough and is the natural companion to a debounce (coalesce, then write one at a time). Add a contract test to `corpusFsContract.ts` asserting that two overlapping `writeFile` calls to the same path resolve with the later value persisted.

---

#### F4 — Every corpus operation re-acquires the OPFS root and re-walks the directory chain

**Severity:** Informational
**Location:** `app/lib/corpus/opfsAdapter.ts:50-56`, `:75-86`, and all five methods at `:96-183`
**Move:** Storage access patterns (OPFS handle churn); caches.
**Classification:** Micro / Cold — the extra work is a fixed constant per operation (O(path depth), and `state/` is depth 1), not a function of data size. Cold branch.
**Confidence:** High. Every method opens with `const root = await getRoot();` and there is no memoization anywhere in the file.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:**

```ts
async function getRoot(): Promise<OpfsDirHandle> {
  const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
  if (!storage || typeof storage.getDirectory !== "function") {
```

**Legibility-target:** The absence of a handle cache is a deliberate simplicity choice for S1; it should be recorded as such so S3's worker-proxy author does not assume handles are already pooled.

A single `setItem` on this path costs `getDirectory()` + `getDirectoryHandle("state", {create:true})` + `getFileHandle(name, {create:true})` + `createWritable()` + `write()` + `close()` — six async round-trips where a cached root and directory handle would need four. The multiplier is small and constant, which is exactly why it is Informational rather than higher: it does not scale with N. It earns a mention only because F2 removes the rate limiter that would otherwise keep the per-operation constant irrelevant, and because the S4 folder layout has deeper paths (`workspaces/<slug>/artifacts/<type>/v0001.md`, depth 4) where `walkDir` will do four handle acquisitions per file instead of one. Note also that `walkDir(..., true)` passes `create: true` on every write, so the directory-existence check is paid forever rather than once.

**Recommendation:** No action for S1. Revisit when the folder layout goes live in S4 — at that point cache the root handle in the closure returned by `createOpfsCorpusFs()` and consider an LRU of directory handles, guarded by an invalidation path for `browser-storage-cleared` (already a modeled error kind at `types.ts:48`).

---

#### F5 — Each corpus write allocates a second full copy of the blob

**Severity:** Informational
**Location:** `app/lib/corpus/storeAdapter.ts:56`, `:66`
**Move:** Memory lifecycle; serialization tax.
**Classification:** Micro / Cold — a constant-factor (roughly 2×) increase in transient peak memory per write, not a change in asymptotics. Cold branch.
**Confidence:** High.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:**

```ts
  const enc = new TextEncoder();
```

used as `enc.encode(value)` inside `setItem`.

**Legibility-target:** Nothing to fix in the code; this is a note for whoever measures the substrate, so a 2× memory reading is not mistaken for a leak.

`value` is already a fully-materialized JSON string of the entire workspace; `enc.encode` produces a second, independent UTF-8 buffer of comparable size. Peak transient memory during a write is therefore about twice the blob, and under F3's overlapping-writer scenario it is twice the blob per in-flight writer. The encoder instance itself is correctly hoisted into the closure rather than allocated per call, which is the part that would have mattered more. The `CorpusFS` interface is bytes-oriented by design (`types.ts:11-12`, sources are binary PDFs), so this copy is the price of a correct seam, not a mistake.

**Recommendation:** None for S1. If the blob ever gets large enough to matter, the fix is upstream — write artifacts as separate files (the S4 layout) so no single write carries the whole corpus.

---

#### F6 — `readdir` materializes and sorts the full directory listing

**Severity:** Informational
**Location:** `app/lib/corpus/opfsAdapter.ts:134-146`
**Move:** Asymptotics; size of N.
**Classification:** Micro / Cold — O(n log n) over a directory whose n is bounded by `MAX_VERSIONS = 20` per artifact type in the S4 layout, and which nothing calls in S1.
**Confidence:** High.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:**

```ts
        const names: string[] = [];
        for await (const key of dir.keys()) names.push(key);
        return names.sort();
```

**Legibility-target:** The `CorpusFS` contract (`types.ts:118-120`) promises "immediate child names"; the determinism guarantee that the `.sort()` provides is not stated there, and a future streaming implementation might drop it.

Buffering the whole listing forecloses streaming or early-exit iteration, and the sort is unconditional even for callers that do not care about order. Both are correct choices for a small-n interface and the sort buys deterministic, test-friendly output. The scaling concern is only theoretical at these sizes: with the version cap at 20 files per artifact directory, n log n is a rounding error next to the async handle acquisition that precedes it.

**Recommendation:** None. Consider documenting the sorted-order guarantee in the `CorpusFS.readdir` docstring so it is a contract rather than an accident, since `corpusFsContract.ts` will otherwise lock it in implicitly.

---

#### F7 — `TextEncoder`/`TextDecoder` allocated per manifest call

**Severity:** Informational
**Location:** `app/lib/corpus/manifest.ts:60`, `:81`
**Move:** Hidden multiplications; caches.
**Classification:** Micro / Cold — constant per-call allocation on a module nothing calls in S1.
**Confidence:** High.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:**

```ts
export function serializeManifest(m: WorkspaceManifest): Uint8Array {
  return new TextEncoder().encode(JSON.stringify(m, null, 2));
}
```

**Legibility-target:** Consistency with `storeAdapter.ts`, which hoists its encoder into the closure. Two files in the same module doing this differently is the kind of inconsistency that gets copied.

Manifest writes happen once per workspace mutation batch, not per keystroke, so the allocation cost is negligible in absolute terms. It is worth a line only because the sibling adapter already demonstrates the hoisted pattern and matching it costs nothing.

**Recommendation:** Hoist both to module-level constants when `manifest.ts` is next touched. Not worth a dedicated change.

---

#### F8 — Path builders re-sanitize already-sanitized segments through nested calls

**Severity:** Informational
**Location:** `app/lib/corpus/paths.ts:36-58`, `:83-85`, `:87-89`, `:105-111`
**Move:** Hidden multiplications; work moved to the wrong place.
**Classification:** Micro / Cold — a handful of regex passes and one `normalize("NFKD")` per short string.
**Confidence:** High.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:**

```ts
export function stateBlobPath(name: string): string {
  return `${STATE_DIR}/${safeSegment(name)}.json`;
}
```

**Legibility-target:** The redundancy is a deliberate security property — `paths.ts:16-19` names itself "the single choke point" — and should stay legible as such rather than being mistaken for an oversight and optimized away.

`artifactVersionPath` → `artifactDir` → `workspaceDir` → `workspaceSlug` re-normalizes and re-regexes the same slug at each level, and `stateBlobPath` runs `safeSegment` on the constant `"workspace-zustand-v1"` on every single corpus write (per keystroke, given F2). `normalize("NFKD")` plus three regex replaces on a 20-character string is sub-microsecond work; calling it a thousand times a minute is still sub-millisecond in aggregate. Idempotent sanitization applied redundantly is the correct trade here — cheap insurance against a caller that skipped a layer, which is precisely the traversal defense `splitPath` also duplicates at `opfsAdapter.ts:63-67`.

**Recommendation:** None. Do not "optimize" this by trusting pre-sanitized input; the redundancy is the security design.

---

#### F9 — `serializeManifest` pretty-prints, inflating persisted bytes

**Severity:** Informational
**Location:** `app/lib/corpus/manifest.ts:60`
**Move:** Serialization tax.
**Classification:** Micro / Cold — a whitespace multiplier on a small index file that S1 never writes.
**Confidence:** High.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:**

```ts
  return new TextEncoder().encode(JSON.stringify(m, null, 2));
}
```

**Legibility-target:** The reason for the indent (git-diffable manifests, per DD-009's S3 git layer) is not stated at the call site, so a later size-conscious change could strip it and silently degrade S3 diffs.

Two-space indentation adds roughly 20-40% to a small JSON document. For a manifest holding source refs, one pointer per artifact type, and a list of custom-type ids, that is a difference measured in hundreds of bytes. It is almost certainly the right call — this file is destined to be committed to git in S3, where line-oriented diffs are worth far more than the bytes.

**Recommendation:** Add a one-line comment naming git-diffability as the reason for `null, 2`, so the trade is recorded rather than rediscovered.

---

### What Looks Good

- **The misleading performance claim was removed.** The deleted comment read `Debounced localStorage adapter — avoids JSON.stringify on every keystroke`, which F1 shows was false. The replacement in `storeAdapter.ts:24-27` claims only what the code delivers: "Reads are synchronous (instant); writes are debounced by 300ms." Deleting a wrong perf claim is worth more than most optimizations, because the wrong claim is what stops anyone from measuring.
- **The OFF path is byte-for-byte preserved.** Moving `createDebouncedStorage` into `storeAdapter.ts` verbatim, with a characterization test (`workspaceStore-characterization.test.ts`) pinning it, means the default hot path carries zero regression risk from this refactor. This is the right way to introduce a seam under a hot path.
- **The flag is read once, not per write.** `createJSONStorage` invokes `resolveWorkspaceStorage()` a single time at module evaluation (`storeAdapter.ts:73-79`), so `isCorpusEnabled()`'s `localStorage.getItem` never lands in the write path. A naive implementation would have re-checked the flag on every `setItem` and put a synchronous localStorage read on the per-keystroke path.
- **The encoder/decoder are hoisted in the adapter.** `storeAdapter.ts:56-57` allocates `TextEncoder`/`TextDecoder` once per adapter rather than per call — the pattern F7 wants `manifest.ts` to adopt.
- **`readFile`/`stat` return `null` instead of throwing for absence.** `types.ts:17-18` makes not-found a value, not an exception. Exception construction with stack capture on a routine miss is a real cost on a path that will check for absent files constantly during S4 migration; this design avoids it by default.
- **`MAX_VERSIONS = 20` caps the per-artifact history.** The one thing in the persisted blob that could have grown without bound already has a bound.
- **Blob-mode for S1 is the cheaper choice.** Writing one file instead of the full folder layout keeps the substrate swap to a single write per state change instead of N-artifacts writes, and `paths.ts:70-81` documents the namespace fork so S4 can find and reconcile it.

---

### Summary Table

| # | Finding | Severity | Class | Path | Baseline |
|---|---------|----------|-------|------|----------|
| F1 | `partialize` + `JSON.stringify` per keystroke, outside the debounce | High (pre-existing) | Macro / Hot | localStorage (default, all users) | none — speculative |
| F2 | Corpus `setItem` writes full blob per state change, un-debounced | Medium | Macro / Cold | corpus (dev-only) | none — speculative |
| F3 | No write serialization; overlapping `createWritable` on one file | Medium | Macro / Cold | corpus (dev-only) | none — speculative |
| F4 | OPFS root + directory chain re-acquired per operation | Informational | Micro / Cold | corpus (dev-only) | none — speculative |
| F5 | `enc.encode` allocates a second full copy of the blob per write | Informational | Micro / Cold | corpus (dev-only) | none — speculative |
| F6 | `readdir` buffers and sorts the whole listing | Informational | Micro / Cold | corpus (unused in S1) | none — speculative |
| F7 | `TextEncoder`/`TextDecoder` allocated per manifest call | Informational | Micro / Cold | manifest (unused in S1) | none — speculative |
| F8 | Redundant re-sanitization through nested path builders | Informational | Micro / Cold | corpus (dev-only) | none — speculative |
| F9 | `serializeManifest` pretty-prints, inflating bytes | Informational | Micro / Cold | manifest (unused in S1) | none — speculative |

---

### Overall Assessment

This diff is performance-neutral for every user at this commit, and that is the correct outcome for a substrate swap. The default path was relocated verbatim and pinned by a characterization test; the new path is gated twice — flag-off by default and hard-refused in production builds (`flag.ts:21`) — so nothing added here executes for anyone outside a dev build. The hot-path gate consequently caps every corpus-branch finding at Medium.

The one High is not this diff's doing. `partialize` + `JSON.stringify` running per keystroke over the full workspace blob predates the range; what this diff changed is that it deleted the comment claiming otherwise. That deletion is the most useful performance change in the range, because it removes the reason nobody measured. The natural next step is not an optimization but a number: instrument serialization duration and blob size against a loaded workspace, then decide whether F1's fix earns its complexity. Every finding in this report carries `no baseline available — flagged as speculative` for exactly that reason.

The corpus branch's two Mediums (F2 un-debounced writes, F3 unserialized concurrent writes) are the same underlying gap seen twice: the fork copies the storage call but not the rate-limiting and ordering discipline around it. Both would be fixed by one change — lifting the throttle above the fork — which is also F1's fix. That is the single highest-leverage item in this review, and it is the thing to do before S2 layers an FSA mirror on top and doubles the per-write cost. F2 is already tracked: the fact-check confirms the author acknowledged it and carried it to S2/S3 as a known green item. F3 is not, and should be, because a lost-update race is a different class of problem than a throughput cost and will not announce itself in a timing measurement.

Everything below Medium is bookkeeping — handle caching, hoisted encoders, a documented sort order — none of it worth a dedicated change, most of it worth folding into S4 when the folder layout goes live and path depth grows from 1 to 4.

---

## Goal-Alignment Note

- **Answered:** Where the per-write cost actually lands on both branches of the storage fork, and why the debounce does not cover the expensive part (F1); how the corpus branch's write path multiplies work per keystroke and what it costs in round-trips, memory, and write ordering (F2-F5); which S0 modules carry latent cost that only activates in S4 (F6-F9); and what the hot/cold split means for severity at this commit.
- **Out of scope:** Security and correctness of `splitPath`/`workspaceSlug` traversal rejection (perf-neutral; noted only where redundancy is deliberate). Test-suite design and coverage. Rehydration/migration correctness in `onRehydrateStorage`. Anything in `docs/**`. Commits outside dc6dfb0..4de2b00.
- **Escalate:** (1) **No baselines exist for any finding in this report** — every severity here is a reasoned estimate from code shape and scaling arguments, not a measurement. F1's rank in particular should be re-derived once serialization duration and realistic blob size are recorded. (2) **F3 (concurrent-write race) does not appear to be on the S2/S3 carry list** the way F2 is; it is a correctness risk, not a throughput one, and warrants an explicit decision. (3) **Zustand v5 internals were verified statically only** — `node_modules` is absent in this worktree, so F1 and F3's dependence on `createJSONStorage`/`persist` call semantics should be confirmed against installed source before acting on either.
