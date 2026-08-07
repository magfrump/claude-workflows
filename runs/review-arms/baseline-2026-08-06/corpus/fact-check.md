Commit: 2dc403e

# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/baseline-2026-08-06/wt-corpus (meta-formalism-copilot)
**Scope:** `git diff dc6dfb0..2dc403e -- app/` (15 TypeScript source/test files in app/lib/corpus and app/lib/stores)
**Checked:** 2026-08-06
**Total claims checked:** 16
**Summary:** 11 verified, 3 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Note: `docs/reviews/hallucination-patterns.md` does not exist in this worktree; proceeded normally. No fabricated-symbol patterns were found among the Incorrect verdicts (the one Incorrect is a comment/code behavioral mismatch, not a fabricated API), so no log entry is warranted.

---

## Claim 1: "Copy so later mutation of the caller's array can't alter stored bytes."

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The write path copies the input via `slice()` before storing:

```ts
// app/lib/corpus/__tests__/inMemoryCorpusFs.ts:26
files.set(normalize(path), bytes.slice());
```

`Uint8Array.prototype.slice()` returns a new array with a fresh backing buffer, so later mutation of the caller's array cannot alter the stored bytes.

**Evidence:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:24-27`

---

## Claim 2: "Directories are implicit: a file at 'a/b/c.txt' makes 'a' and 'a/b' listable."

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`readdir` derives children by prefix-matching stored file keys and taking the next path segment:

```ts
// app/lib/corpus/__tests__/inMemoryCorpusFs.ts:31-40
for (const key of files.keys()) {
  if (prefix !== "" && !key.startsWith(prefix)) continue;
  const rest = key.slice(prefix.length);
  if (rest === "") continue;
  const next = rest.split("/")[0];
  if (next) children.add(next);
}
```

A file stored at `a/b/c.txt` therefore makes `a` a child of the root and `b` a child of `a`, matching the docstring.

**Evidence:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:28-42`

---

## Claim 3: "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime in a dev browser, `localStorage.setItem(\"corpus-fs-enabled\", \"1\")`."

**Location:** `app/lib/corpus/flag.ts:11-12`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** Medium

Both paths are implemented, and the localStorage key matches the exported constant:

```ts
// app/lib/corpus/flag.ts:13-24
export const CORPUS_FLAG_KEY = "corpus-fs-enabled";
export function isCorpusEnabled(): boolean {
  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
  if (typeof window !== "undefined") {
    try {
      return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
    } ...
```

The env-var branch relies on Next.js build-time inlining of `NEXT_PUBLIC_*` (paraphrased — no quote available because the inlining is performed by the Next.js/webpack DefinePlugin at build, outside this repo's source, so it cannot be confirmed by static read alone; confidence lowered to Medium accordingly). The runtime-localStorage branch is confirmed directly by the quoted code.

**Evidence:** `app/lib/corpus/flag.ts:13-24`

---

## Claim 4: "parsing is FAIL-LOUD. A malformed or absent manifest must surface as a typed `CorpusError` of kind \"io\" or \"browser-storage-cleared\", never a silent default-empty manifest."

**Location:** `app/lib/corpus/manifest.ts:10-13`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

Parsing is fail-loud and never returns a default-empty manifest — every malformation and a `null` input route through `fail()`, which throws:

```ts
// app/lib/corpus/manifest.ts:64-66
function fail(reason: string): never {
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
}
```

The fail-loud claim and the "kind io" claim are correct. The `"browser-storage-cleared"` half is imprecise: this codec only ever throws `kind: "io"`; no path in `parseManifest` produces `browser-storage-cleared` (that kind exists in the `CorpusErrorKind` union in `types.ts:56` but is never raised here).

**Evidence:** `app/lib/corpus/manifest.ts:64-108`, `app/lib/corpus/types.ts:50-58`

---

## Claim 5: "a `null` input (file absent) is the caller's responsibility to detect ... passing `null` here is itself an error."

**Location:** `app/lib/corpus/manifest.ts:73-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`parseManifest` throws on `null` rather than returning a default:

```ts
// app/lib/corpus/manifest.ts:78
if (bytes === null) fail("manifest file is absent");
```

**Evidence:** `app/lib/corpus/manifest.ts:77-78`

---

## Claim 6: "SSR / unavailable guard: any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:\"unavailable\"}), never a raw `TypeError`."

**Location:** `app/lib/corpus/opfsAdapter.ts:8-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`getRoot()` throws a typed unavailable error, and every method calls `getRoot()` inside a `try` whose `catch` funnels through `wrap()` (which re-throws `CorpusError` as-is):

```ts
// app/lib/corpus/opfsAdapter.ts:65-70
const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
if (!storage || typeof storage.getDirectory !== "function") {
  throw new CorpusError({ kind: "unavailable", reason: "..." });
}
```

The `opfsAdapter.test.ts` "unavailable guard" cases assert exactly this for every method. No raw `TypeError` escapes.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:64-71`, `:80-83`, `:87-186`

---

## Claim 7: "a quota failure rejects with {kind:\"quota-exceeded\", substrate:\"opfs\"} — it is NOT swallowed with console.warn the way the legacy localStorage adapter does (workspaceStore.ts:44-46)."

**Location:** `app/lib/corpus/opfsAdapter.ts:12-14`
**Type:** Behavioral / Reference
**Verdict:** Stale
**Confidence:** High

The behavioral half is correct — `wrap()` reifies quota failures:

```ts
// app/lib/corpus/opfsAdapter.ts:80-82
if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
```

But the cross-file line reference `workspaceStore.ts:44-46` is stale. This same diff *removed* the debounced-localStorage adapter (with its `console.warn`) from `workspaceStore.ts` and moved it to `storeAdapter.ts`. The `console.warn` now lives at `app/lib/corpus/storeAdapter.ts:35`:

```ts
// app/lib/corpus/storeAdapter.ts:35
console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
```

`workspaceStore.ts:44-46` now contains the body of `coerceArtifactVersion` (`id: raw.id, content: raw.content, ...`), not the localStorage adapter. The reference should point to `storeAdapter.ts:33-36`.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:80-82`, `app/lib/corpus/storeAdapter.ts:29-37`, `app/lib/stores/workspaceStore.ts:43-49`

---

## Claim 8: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** `app/lib/corpus/opfsAdapter.ts:115`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The comment says a fresh ArrayBuffer view is passed, but the code writes the caller's `bytes` argument directly with no copy/slice/subarray:

```ts
// app/lib/corpus/opfsAdapter.ts:115-116
// Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
await w.write(bytes);
```

`bytes` is the untouched parameter from `writeFile(path, bytes)`; no fresh view is created. A reader relying on this comment would wrongly believe the shared-buffer concern is handled here. (The in-memory fake *does* copy via `slice()` — Claim 1 — but the OPFS adapter does not.)

**Evidence:** `app/lib/corpus/opfsAdapter.ts:105-122`

---

## Claim 9: "walkDir ... Returns null when `create` is false and a segment is missing."

**Location:** `app/lib/corpus/opfsAdapter.ts:86-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
// app/lib/corpus/opfsAdapter.ts:91-96
try {
  cur = await cur.getDirectoryHandle(d, { create });
} catch (e) {
  if (!create && isNotFound(e)) return null;
  throw e;
}
```

When `create` is false and a directory segment is not found, it returns `null`; otherwise it rethrows.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:88-99`

---

## Claim 10: "rm ... Idempotent: resolves (no-op) if the path does not exist."

**Location:** `app/lib/corpus/types.ts:122` (interface docstring) and `app/lib/corpus/opfsAdapter.ts` rm
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The OPFS `rm` swallows both a missing parent dir and a missing entry:

```ts
// app/lib/corpus/opfsAdapter.ts (rm)
if (!dir) return; // idempotent: parent dir missing -> nothing to remove
try { await dir.removeEntry(name); }
catch (e) { if (isNotFound(e)) return; throw e; }
```

The in-memory fake's `rm` is likewise a no-op on a missing key (`files.delete` on an absent key). The contract test "rm removes a file and is idempotent on a missing path" asserts this.

**Evidence:** `app/lib/corpus/opfsAdapter.ts` rm body, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:44-46`, `app/lib/corpus/__tests__/corpusFsContract.ts:47-56`

---

## Claim 11: "\"Not found\" is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

**Location:** `app/lib/corpus/types.ts:29-30`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High

Both adapters honor this. OPFS `readFile`/`stat` return `null` on `isNotFound`, `readdir` returns `[]` when the dir is missing; the in-memory fake returns `?? null` / `[]` correspondingly. All other failures pass through `wrap()` → `CorpusError`. No branch returns `undefined`.

```ts
// app/lib/corpus/__tests__/inMemoryCorpusFs.ts:20-22
async readFile(path) {
  return files.get(normalize(path)) ?? null;
},
```

**Evidence:** `app/lib/corpus/types.ts:106-124`, `app/lib/corpus/opfsAdapter.ts:87-186`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:20-51`

---

## Claim 12: "the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`."

**Location:** `app/lib/corpus/paths.ts:15-18`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium

`workspaceSlug` does strip separators/dot-runs and throw on an empty result, and every workspace-scoped builder routes through `workspaceDir` → `workspaceSlug`:

```ts
// app/lib/corpus/paths.ts:52-54
export function workspaceDir(slug: string): string {
  return `workspaces/${workspaceSlug(slug)}`;
}
```

The "single choke point" phrasing is slightly imprecise: `safeSegment` is a second, parallel sanitizer applied to source ids, custom-type ids, and artifact types within a workspace dir. `workspaceSlug` is the single guard for the *workspace* segment specifically, which is the accurate reading. The claim holds under that narrow reading; taken literally as the *only* traversal guard in the module it is incomplete.

**Evidence:** `app/lib/corpus/paths.ts:26-49`, `:52-110`

---

## Claim 13: "artifactVersionPath ... `version` is 1-based" / "rejects a non-positive or non-integer version."

**Location:** `app/lib/corpus/paths.ts:82-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
// app/lib/corpus/paths.ts:84-88
if (!Number.isInteger(version) || version < 1) {
  throw new Error(`artifact version must be a positive integer, got ${version}`);
}
const v = String(version).padStart(VERSION_PAD, "0");
```

`VERSION_PAD` is 4 (`paths.ts:22`), so version 1 → `v0001.md`, matching the docstring example and the `paths.test.ts` zero-pad assertions.

**Evidence:** `app/lib/corpus/paths.ts:22`, `:82-90`, `app/lib/corpus/__tests__/paths.test.ts:46-53`

---

## Claim 14: "moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior ... Reads are synchronous (instant); writes are debounced by 300ms."

**Location:** `app/lib/corpus/storeAdapter.ts:20-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The removed `createDebouncedStorage` in `workspaceStore.ts` and the new `createDebouncedLocalStorage` in `storeAdapter.ts` have identical bodies (synchronous `getItem`, 300ms `setTimeout` debounce on `setItem` with the same try/catch `console.warn`, `removeItem` clearing the pending timer). The diff shows the old block deleted and the new one added with matching logic:

```ts
// app/lib/corpus/storeAdapter.ts:31-37
pending = setTimeout(() => {
  try { localStorage.setItem(name, value); }
  catch (e) { console.warn("Failed to persist workspace (localStorage quota exceeded):", e); }
  pending = null;
}, 300);
```

The debounce constant is 300ms and reads go straight to `localStorage.getItem` (synchronous). Behavior is preserved verbatim.

**Evidence:** `app/lib/corpus/storeAdapter.ts:24-46`, `app/lib/stores/workspaceStore.ts` diff (removed `createDebouncedStorage`)

---

## Claim 15: "the persist blob is stored as a SINGLE file via CorpusFS (blob mode) ... In S1 the persist blob is stored as one file under `state/`."

**Location:** `app/lib/corpus/storeAdapter.ts:10-12` and `:48-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`createCorpusBackedStorage` writes/reads/removes one file per persist key under `state/`:

```ts
// app/lib/corpus/storeAdapter.ts:53
const pathFor = (name: string) => `state/${name}.json`;
```

`getItem`/`setItem`/`removeItem` all operate through `pathFor`, storing the whole serialized blob as a single file, not the per-artifact folder layout. The `workspaceStore-corpus-flag.test.ts` G14 case asserts the blob lands at `state/workspace-zustand-v1.json`.

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-64`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:38-52`

---

## Claim 16: "resolveWorkspaceStorage() returns ... the existing debounced localStorage adapter by default, or a CorpusFS-backed storage when the dev flag is on."

**Location:** `app/lib/corpus/storeAdapter.ts:3-6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
// app/lib/corpus/storeAdapter.ts:70-75
export function resolveWorkspaceStorage(): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(createOpfsCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```

`workspaceStore.ts` wires this into `createJSONStorage(resolveWorkspaceStorage)` at the persist config, and the flag routing tests confirm OFF → localStorage (getDirectory never called) and ON → OPFS.

**Evidence:** `app/lib/corpus/storeAdapter.ts:69-75`, `app/lib/stores/workspaceStore.ts:493-499`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:24-82`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`app/lib/corpus/opfsAdapter.ts:115`): Comment claims a "fresh ArrayBuffer view" is passed to `write`, but the code passes the caller's `bytes` argument unchanged — no copy is made. Either copy the bytes or fix the comment.

### Stale
- **Claim 7** (`app/lib/corpus/opfsAdapter.ts:14`): Cross-file reference `workspaceStore.ts:44-46` is stale — the `console.warn` localStorage adapter it points to was moved by this same diff to `app/lib/corpus/storeAdapter.ts:35`; update the citation.

### Mostly Accurate
- **Claim 4** (`app/lib/corpus/manifest.ts:12`): Fail-loud parsing is correct, but the docstring names kind `"browser-storage-cleared"` as a possible throw; `parseManifest` only ever throws `kind: "io"`. Drop the `browser-storage-cleared` mention.
- **Claim 12** (`app/lib/corpus/paths.ts:16`): "single choke point" is accurate only for the workspace segment; `safeSegment` is a parallel guard for ids/types. Tighten to "the single guard for the workspace segment."
