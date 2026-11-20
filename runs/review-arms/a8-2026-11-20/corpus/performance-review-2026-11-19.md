Commit: 2dc403e

# Performance Review — meta-formalism-copilot dc6dfb0..2dc403e (`app/`, partial scope)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` (15 files); other 13 branch files are context only
**Date:** 2026-11-19
**Based on:** Stage-1 merged code-fact-check report (`code-fact-check-report.md`, k=3), escalation E5

## Data Flow and Hot Paths

The Zustand workspace store persists on every `set()`. `partialize` (`workspaceStore.ts:511-525`) selects the full data surface: source text, extracted file text (`{ name, text }[]`, `app/lib/types/persistence.ts:19`), up to `MAX_VERSIONS = 20` versions per artifact type (`artifactStore.ts:37`), the decomposition and custom-type data. `createJSONStorage(resolveWorkspaceStorage)` (`workspaceStore.ts:499`) stringifies that blob and hands it to the selected `StateStorage`.

`set()` is hot. Keystrokes in the source editor call `setSourceText` directly (`page.tsx:814` → `workspaceStore.ts:321`), and LLM streaming calls `setLeanCode`/`setSemiformalText` through `throttle(..., 50)` (`useFormalizationPipeline.ts:66,95-97`, `useDecomposition.ts:130`). That is about 20 persists per second for the whole stream.

- **Flag off (default):** `createDebouncedLocalStorage` (`storeAdapter.ts:25-46`) has the same body as the removed `createDebouncedStorage` (fact-check claim 10). Only the localStorage write is debounced to 300 ms. The one new cost is a single `localStorage.getItem(CORPUS_FLAG_KEY)` when the store initializes (claim 18). That runs once, on a cold path.
- **Flag on (dev only, not enforced; claim 2):** `createCorpusBackedStorage(createOpfsCorpusFs())`. Every persist runs one undebounced `writeFile("state/workspace-zustand-v1.json", ...)`, which does `getDirectory` → `getDirectoryHandle("state")` → `getFileHandle` → `createWritable` → `write` → `close`.

The OPFS path is default-off and not shipped to end users. Every finding below is in that path, and severities are set for its dev-only reach today. They become ship blockers when S4 turns the flag on for users.

## Findings

#### Corpus-backed storage drops the write debounce: one full-blob OPFS write per `set()`, unserialized

**Severity:** Medium
**Location:** `app/lib/corpus/storeAdapter.ts:61-63`
**Move:** Work that moved to the wrong place (debounce removed) / Hidden multiplication
**Classification:** Macro (write volume grows with blob size × update rate, and in-flight writes are unbounded) / Hot path (per-keystroke, and 20 Hz during streaming)
**Confidence:** High for the missing debounce and serialization. Medium for the out-of-order effect, which depends on how each browser orders concurrent `createWritable` commits.
**Legibility-target:** for-author
**Baseline:** no baseline available — flagged as speculative

**Evidence:**
```ts
    setItem: async (name, value) => {
      await fs.writeFile(pathFor(name), enc.encode(value));
    },
```
(excerpt ends :63; enclosing `createCorpusBackedStorage` continues to :68 — read. The flow continues into `opfsAdapter.ts:107-123` `writeFile`, which was read in full.)

The default adapter coalesces writes to one localStorage write per 300 ms of quiet. The corpus adapter has no coalescing, so each `set()` runs a full OPFS write cycle: `TextEncoder.encode` of the whole blob, then `createWritable`, which in Chromium writes to a swap file and atomically replaces the target on `close()`, then `write` and `close`. While a 50 ms-throttled stream runs, that is about 20 full-blob writes per second. The blob carries extracted PDF text and up to 20 versions per artifact type, so its size is unbounded by design: N writes/s × blob bytes, against 0 to 3 writes/s on the default path.

Nothing serializes the writes. zustand's persist fires `setItem` without awaiting the previous call (zustand v5 `persist` middleware; `node_modules` is absent, so this is not verified here). Writes therefore overlap with no limit. When two writes to the same file overlap, the one whose `close()` commits last wins. That can be an older snapshot, which leaves stale state on disk after the stream ends. The overlapping writes also pile up swap files and pending promises.

**Recommendation:** Wrap `createCorpusBackedStorage` in the same trailing debounce as the default path, or a latest-value-wins single-flight writer: hold the newest value, run at most one in-flight write, and start the next only after the current one settles. Do this before S4. Before enabling the flag for users, measure write rate and blob size during a real streaming run.

#### Quota failure on the corpus path has no backoff and surfaces as unhandled rejections at update rate (E5)

**Severity:** Low
**Location:** `app/lib/corpus/opfsAdapter.ts:113-121`, `app/lib/corpus/storeAdapter.ts:61-63`
**Move:** Resource lifecycle / Contention point
**Classification:** Micro per call, multiplied by the hot update rate / Hot path (only when the substrate is out of quota)
**Confidence:** Medium. The masking question depends on how each browser behaves.
**Legibility-target:** for-author
**Baseline:** no baseline available — flagged as speculative

**Evidence:**
```ts
        const w = await fh.createWritable();
        try {
          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
          await w.write(bytes);
        } finally {
          await w.close();
        }
      } catch (e) {
        wrap(path, e);
      }
```
(excerpt ends :121; enclosing `writeFile` continues to :123 — read)

Regarding E5: the Stage-1 probe showed that a stubbed `close()` which throws a different error turns a quota failure into `{kind:"io"}`. In a WHATWG-streams-conformant writable, a failed `write()` errors the stream, and `close()` then rejects with the same stored error. So on real browsers the masking may not happen. That is unverified and needs the Playwright/OPFS run. The bigger performance cost is the same whichever error kind wins. When the quota is full, every `set()` still runs a complete encode, swap-file write and `close()` that is bound to fail, about 20 times per second while streaming. No caller backs off, because the rejection leaves `setItem` uncaught and zustand discards the promise (from memory; not verified here). The result is wasted I/O and a stream of unhandled-rejection reports, with no single typed signal the UI could act on. The corpus path also loses the old adapter's behavior of warning once per debounced write.

**Recommendation:** Call `w.abort()` in a `catch` on the `write()` failure, not `close()` in `finally`, so the original error propagates without depending on browser behavior. In the storage wrapper, catch `CorpusError` of kind `quota-exceeded`, stop or slow further writes until the state changes materially, and surface it once.

#### Per-call `getDirectory()` and directory re-walk on every operation

**Severity:** Informational
**Location:** `app/lib/corpus/opfsAdapter.ts:49-55`, `:109-112`
**Move:** Hidden multiplication
**Classification:** Micro (a few extra async handle lookups per op) / Hot path when the flag is on
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** no baseline available — flagged as speculative

**Evidence:**
```ts
        const root = await getRoot();
        const { dirs, name } = splitPath(path);
        const dir = await walkDir(root, dirs, true);
        const fh = await dir!.getFileHandle(name, { create: true });
```
(excerpt ends :112; enclosing `writeFile` continues to :123 — read)

Every method calls `navigator.storage.getDirectory()` again and walks the path segment by segment. For the single `state/` file used in S1, this is one extra `getDirectoryHandle` per write and does not matter on its own. It does multiply with the undebounced write rate in the first finding. In S4 it will also multiply with per-artifact files, where the contract suite already exercises 30 files per artifact directory (`corpusFsContract.ts:101-117`).

**Recommendation:** Fix the first finding first. If S4 profiling shows handle lookup in the trace, cache the root handle lazily (and directory handles if needed). Until then, no action is required.

## Endorsements (evidence-gated)

- The flag-off path keeps the prior debounced-write behavior: the body was moved, then renamed, exported and retyped `[fact-check: claim 10 — Mostly accurate]`.
- The flag-off path's only new runtime cost is one flag-key localStorage read when the store initializes, which is cold `[fact-check: claim 18 — Verified with a caveat]`.
- Claim: the removed comment "avoids JSON.stringify on every keystroke" was never true. `createJSONStorage` stringifies before calling `setItem`, so both adapters pay a full stringify per `set()`, and the debounce only saves the storage write `[unverified — submitted as claim]`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Corpus storage has no debounce or serialization: full-blob OPFS write per `set()` | Medium | `app/lib/corpus/storeAdapter.ts:61-63` | High |
| 2 | Quota failure retried at update rate with no backoff; `close()` in `finally` (E5) | Low | `app/lib/corpus/opfsAdapter.ts:113-121` | Medium |
| 3 | Per-op `getDirectory()` and path re-walk | Informational | `app/lib/corpus/opfsAdapter.ts:49-55,109-112` | High |

## Overall Assessment

The default path is performance-neutral. It keeps the same debounce body and adds one cold flag read. The corpus path has a structural regression that can be fixed in place: it removes the write coalescing the store relies on, so a dev who enables the flag gets about 20 full-blob OPFS writes per second while LLM output streams, with no ordering guarantee between them. The fix is small, a debounce or a single-flight latest-value writer in `createCorpusBackedStorage`, and it should land before S4 enables the flag for anyone. No finding has a measured baseline. A real-browser run measuring write count, blob size and the on-disk final state after a streaming session is needed to put numbers on the first finding and to settle whether E5's masking happens outside stubs.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: 2dc403e` as its first line, structured per the performance-reviewer skill.
- Answered: yes
- Out of scope: Correctness side of E5 and E4 (the error-kind contract and the migrateFromV2 interaction) are left to the security and architecture reviewers. Test-only `inMemoryCorpusFs.readdir` O(files) scan is not flagged, since that code is test-only.
- Escalate: (1) The out-of-order commit risk in finding 1 is a data-correctness issue (stale state persisted) for architecture-review and test-strategy. (2) E5 masking needs a real-browser OPFS run, alongside E6. (3) zustand v5 persist behavior (stringify before `setItem`, unawaited `setItem` promise) needs checking in a provisioned environment with `node_modules`.
- Decisions I made: Severities are capped for the dev-only, default-off reach of the corpus path, not graded as user-facing. Finding 1 would be High once S4 turns the flag on.
