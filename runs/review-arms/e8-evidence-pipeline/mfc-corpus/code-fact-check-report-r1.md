# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-corpus
**Commit:** 2dc403e
**Scope:** Checkable claims in files changed in `git diff dc6dfb0...HEAD` (DD-009 corpus-architecture change: OPFS/storeAdapter storage, NEXT_PUBLIC_CORPUS_FS flag, manifest codec, rehydration/migration). Source + doc comment claims only; prior review artifacts inside the clone ignored per blinding.
**Checked:** 2026-08-17
**Total claims checked:** 15
**Summary:** 9 verified, 2 mostly accurate, 1 stale, 2 incorrect, 1 unverifiable

Execution environment note: the repo's `vitest` process exits `1` even when every test passes, because a probe reads `/workspace/external/package.json` (empty file → invalid JSON) that sits *outside* the clone. This is an environment artifact, not a test result; the authoritative signal is the `Test Files N passed / Tests N passed` line in each captured log. Both executed vitest runs below show all tests passing.

---

## Claim 1: "`paths.ts` — **not** `layout.ts`, which is a reserved Next.js filename"

**Location:** `CLAUDE.md:55`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of `paths.ts` (and absence of `layout.ts`) in `app/lib/corpus/`; does not independently adjudicate Next.js's reserved-filename list beyond the rename's stated rationale.

The corpus module ships `paths.ts`, and the path builders live there:

```ts
// app/lib/corpus/paths.ts:36
export function workspaceSlug(title: string): string {
```

No `app/lib/corpus/layout.ts` exists (the rename is recorded in commit `122d70f refactor(corpus)+docs: rename layout.ts->paths.ts (Next reserved name)`) (paraphrased — no quote available because the claim covers absence of a file, confirmed by grep returning no `layout.ts` in the corpus dir).

**Evidence:** `app/lib/corpus/paths.ts:1-47`, `CLAUDE.md:55`

---

## Claim 2: "DEFAULT OFF and DEV-ONLY"

**Location:** `app/lib/corpus/flag.ts:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `isCorpusEnabled()` returning `false` when neither the env nor the localStorage opt-in is set; does not establish any caller enforces "dev-only" (that is an intent/deployment claim outside code).

With no env var and no localStorage key, every branch falls through to `return false`:

```ts
// app/lib/corpus/flag.ts:15-25
export function isCorpusEnabled(): boolean {
  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
  if (typeof window !== "undefined") {
    try {
      return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
    } catch {
      return false;
    }
  }
  return false;
}
```

**Evidence:** `app/lib/corpus/flag.ts:15-25`

---

## Claim 3: "enabling this starts from an EMPTY corpus and does not carry existing localStorage work over" (no migration until S4)

**Location:** `app/lib/corpus/flag.ts:4-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the ON path (`createCorpusBackedStorage`) contains no localStorage read/migration; does not establish future S4 behavior.

When the flag is on, `resolveWorkspaceStorage()` returns a corpus-backed storage that reads only from the corpus FS under `state/`, with no localStorage fallback:

```ts
// app/lib/corpus/storeAdapter.ts:57-60
getItem: async (name) => {
  const bytes = await fs.readFile(pathFor(name));
  return bytes ? dec.decode(bytes) : null;
},
```

An empty OPFS corpus therefore returns `null` (no seeded data). No code path copies `WORKSPACE_KEY`/`workspace-zustand-v1` localStorage into the corpus on enable (paraphrased — no quote available because the claim covers the absence of a migration call in the ON path; grep of `storeAdapter.ts` finds no `localStorage`/`migrateFromV2` reference).

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-76`

---

## Claim 4: "Enable via ... the build-time env `NEXT_PUBLIC_CORPUS_FS=1`"

**Location:** `app/lib/corpus/flag.ts:9`
**Type:** Behavioral (build-time inlining — executable guarantee)
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether `next build` with `NEXT_PUBLIC_CORPUS_FS=1` inlines the value so the client bundle reads it through `process.env?.NEXT_PUBLIC_CORPUS_FS` (optional chaining on `process.env`); does not cover runtime/server evaluation, which reads `process.env` directly and is unaffected by inlining.

This is an executable guarantee (build-time env replacement), so the mandatory-execution rule applies. I ran `next build` with the env set; it aborted before producing any client bundle to grep, because the sandbox has **no network** and Next's `next/font/google` loader could not fetch the fonts declared in `app/layout.tsx`:

```
Error: Turbopack build failed with 2 errors:
next/font: error: Failed to fetch `EB Garamond` from Google Fonts.
next/font: error: Failed to fetch `Geist Mono` from Google Fonts.
  ...Server Component: ./app/layout.tsx
```

Blocker: network-blocked Google Fonts fetch during `next build` (the app cannot build offline). No built output was emitted, so the optional-chaining inlining question (`process.env?.NEXT_PUBLIC_CORPUS_FS` — whether Turbopack's `NEXT_PUBLIC_*` substitution survives the `?.` on `process.env`) could not be confirmed. Verdict capped at Unverifiable per the mandatory-execution rule; static reading cannot certify build-pipeline substitution.

**Evidence:** `app/lib/corpus/flag.ts:16`, `app/layout.tsx` (font imports), captured output `evidence/r1-next-build-flag-set.txt`
- command: `NEXT_PUBLIC_CORPUS_FS=1 NEXT_TELEMETRY_DISABLED=1 next build`
- cwd: `/workspace/external/cc-review-eval/mfc-corpus`
- exit code: 1 (build error — font fetch)
- timestamp: 2026-08-17 (audit session)

---

## Claim 5: "at runtime in a dev browser, `localStorage.setItem(\"corpus-fs-enabled\", \"1\")`" enables the flag

**Location:** `app/lib/corpus/flag.ts:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the localStorage key name and comparison; does not cover browser-specific localStorage availability.

The key constant and the read match the documented setter exactly:

```ts
// app/lib/corpus/flag.ts:13
export const CORPUS_FLAG_KEY = "corpus-fs-enabled";
// app/lib/corpus/flag.ts:19
return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
```

**Evidence:** `app/lib/corpus/flag.ts:13,19`

---

## Claim 6: "parsing is FAIL-LOUD. A malformed or absent manifest must surface as a typed `CorpusError` ... never a silent default-empty manifest"

**Location:** `app/lib/corpus/manifest.ts:11-14`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whole-manifest failure modes (absent bytes, non-JSON, non-object, missing `title`/`manifestVersion`/`sources`/`artifacts`/`customTypeIds`) throwing `CorpusError`; does not cover per-field malformations of `createdAt`/`updatedAt`/`label` (see Claim 7).

Executed via vitest: `parseManifest(null)`, non-JSON bytes, a JSON array, and an object missing `manifestVersion` all threw `CorpusError` (captured log: 6 tests passed). The `fail()` helper throws rather than returning a default:

```ts
// app/lib/corpus/manifest.ts:64-67
function fail(reason: string): never {
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
}
```

The specific "default-empty manifest masquerading as no work" failure mode is prevented: an absent file (`bytes === null`) throws at line 75.

**Evidence:** `app/lib/corpus/manifest.ts:64-84`, captured output `evidence/r1-scratch-vitest.txt` (`Tests 6 passed`)
- command: `vitest run app/lib/corpus/__tests__/factcheck_scratch_r1.test.ts --reporter=verbose --disable-console-intercept`
- cwd: `/workspace/external/cc-review-eval/mfc-corpus`
- exit code: 1 (environmental — see header note; test line reports `6 passed`)
- timestamp: 2026-08-18T06:54:10Z (UTC, from test-emitted ISO timestamp)

---

## Claim 7: "Parse + validate manifest bytes. Throws a `CorpusError` on any malformation"

**Location:** `app/lib/corpus/manifest.ts:69-73`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the docstring's universal "any malformation → throws" claim against the `createdAt`/`updatedAt`/`label` fields, which are silently defaulted rather than rejected; does not contradict the whole-manifest fail-loud behavior of Claim 6.

The docstring says *any* malformation throws, but three fields are silently coerced instead. A wrong-typed `createdAt` (a number) and `updatedAt` (`null`) do not throw — they are replaced with a fresh timestamp:

```ts
// app/lib/corpus/manifest.ts:109-110
createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : new Date().toISOString(),
```

A missing/malformed source `label` is silently defaulted to the source `id`:

```ts
// app/lib/corpus/manifest.ts:89
return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
```

Executed confirmation (captured log): `parseManifest` of a manifest with `createdAt: 12345, updatedAt: null` returned without throwing and produced `{"createdAt":"2026-08-18T06:54:10.606Z","updatedAt":"2026-08-18T06:54:10.606Z"}`; a source `{id:"s1", ext:"pdf"}` (no label) yielded `label:"s1"`. A reader relying on "any malformation throws" (e.g. to trust that a persisted `createdAt` round-trips or that a missing label is an error) is misled. Note the header-level docstring (lines 11-14, Claim 6) is narrower ("default-*empty* manifest") and remains accurate; this per-function docstring overstates it.

**Evidence:** `app/lib/corpus/manifest.ts:89,109-110`, captured output `evidence/r1-scratch-vitest.txt` (`R1_CREATEDAT_RESULT`, `R1_LABEL_RESULT`)
- command: `vitest run app/lib/corpus/__tests__/factcheck_scratch_r1.test.ts --reporter=verbose --disable-console-intercept`
- cwd: `/workspace/external/cc-review-eval/mfc-corpus`
- exit code: 1 (environmental — see header note; `6 passed`)
- timestamp: 2026-08-18T06:54:10Z (UTC)

---

## Claim 8: "any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:\"unavailable\"}), never a raw `TypeError`"

**Location:** `app/lib/corpus/opfsAdapter.ts:10-13`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `readFile` under jsdom (no `navigator.storage`) producing `CorpusError{kind:"unavailable"}`; the same `getRoot()` guard fronts `writeFile`/`readdir`/`rm`/`stat`, so the finding generalizes, though only `readFile` was executed.

`getRoot()` throws the typed error before any raw property access:

```ts
// app/lib/corpus/opfsAdapter.ts:50-53
const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
if (!storage || typeof storage.getDirectory !== "function") {
  throw new CorpusError({ kind: "unavailable", reason: "navigator.storage.getDirectory is not available (SSR or unsupported browser)" });
}
```

Executed (captured log): `await fs.readFile("state/x.json")` under the test env rejected with `{"kind":"unavailable","reason":"navigator.storage.getDirectory is not available (SSR or unsupported browser)"}` — a `CorpusError`, not a `TypeError`.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:49-55,85-105`, captured output `evidence/r1-scratch-vitest.txt` (`R1_OPFS_ERR`)
- command: `vitest run app/lib/corpus/__tests__/factcheck_scratch_r1.test.ts ...`
- cwd: `/workspace/external/cc-review-eval/mfc-corpus`
- exit code: 1 (environmental — see header note; `6 passed`)
- timestamp: 2026-08-18T06:54:10Z (UTC)

---

## Claim 9a: "a quota failure rejects with {kind:\"quota-exceeded\", substrate:\"opfs\"}"

**Location:** `app/lib/corpus/opfsAdapter.ts:13-14`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `wrap()` mapping of a `QuotaExceededError`/`QUOTA_EXCEEDED_ERR` DOMException to the typed kind; does not cover whether a real OPFS quota event surfaces one of those DOMException names (browser-dependent, not reproducible in jsdom).

The quota classifier and the mapping in `wrap()` match the claim:

```ts
// app/lib/corpus/opfsAdapter.ts:45-47
function isQuota(e: unknown): boolean {
  return e instanceof DOMException && (e.name === "QuotaExceededError" || e.name === "QUOTA_EXCEEDED_ERR");
}
// app/lib/corpus/opfsAdapter.ts:81
if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
```

**Evidence:** `app/lib/corpus/opfsAdapter.ts:45-47,79-83`

---

## Claim 9b: "it is NOT swallowed with console.warn the way the legacy localStorage adapter does (`workspaceStore.ts:44-46`)"

**Location:** `app/lib/corpus/opfsAdapter.ts:14`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the `workspaceStore.ts:44-46` line pointer; the substance (the OPFS adapter reifies quota instead of swallowing it) is correct per Claim 9a.

The referenced legacy `console.warn` swallow no longer lives at `workspaceStore.ts:44-46`. This same diff deleted `createDebouncedStorage` from `workspaceStore.ts` and moved it into `storeAdapter.ts`, where the swallow now sits:

```ts
// app/lib/corpus/storeAdapter.ts:34-35
} catch (e) {
  console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
```

At HEAD, `workspaceStore.ts:44-46` is unrelated rehydration code (`createdAt`/`source`/`editInstruction` coercion in an artifact-version parser), not a quota swallow (paraphrased — no quote available because the point is that the cited lines no longer contain the referenced code; `git show HEAD:app/lib/stores/workspaceStore.ts` lines 44-46 show the parser fields). The pointer should read `storeAdapter.ts:34-35`.

**Evidence:** `app/lib/corpus/storeAdapter.ts:33-36`, `app/lib/stores/workspaceStore.ts:44-46` (current content unrelated)

---

## Claim 10: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** `app/lib/corpus/opfsAdapter.ts:115`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether `writeFile` actually hands `write()` a fresh/copied view; does not cover whether real OPFS implementations require one.

The comment asserts a fresh view is passed, but the very next line writes the caller's `bytes` reference unchanged — no `.slice()`, no copy, no new view:

```ts
// app/lib/corpus/opfsAdapter.ts:115-116
// Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
await w.write(bytes);
```

Executed (captured log): with a stubbed OPFS root, the `Uint8Array` observed by `write()` was the *same object reference* the caller passed (`R1_WRITE_SAME_REF: true`, `sameBuffer: true`). The comment describes a defensive copy the code does not perform; a reader trusting it (e.g. assuming it is safe to mutate `bytes` after the call, or that shared-buffer-averse backends are handled) is misled.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:107-123`, captured output `evidence/r1-scratch-vitest.txt` (`R1_WRITE_SAME_REF`)
- command: `vitest run app/lib/corpus/__tests__/factcheck_scratch_r1.test.ts ...`
- cwd: `/workspace/external/cc-review-eval/mfc-corpus`
- exit code: 1 (environmental — see header note; `6 passed`)
- timestamp: 2026-08-18T06:54:10Z (UTC)

---

## Claim 11: "the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`"

**Location:** `app/lib/corpus/paths.ts:16-19,30-35`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `workspaceSlug` strips `/`, `\`, and dot-runs via `SAFE_SEGMENT` and throws on an empty result; does not exhaustively prove no Unicode normalization edge case survives, and does not verify callers never bypass it.

Every workspace path routes through `workspaceDir` → `workspaceSlug`, which collapses any character outside `[a-zA-Z0-9_-]` to a hyphen and rejects an all-unsafe title:

```ts
// app/lib/corpus/paths.ts:28
const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;
// app/lib/corpus/paths.ts:37-46
const slug = title.normalize("NFKD").replace(SAFE_SEGMENT, "-")...
if (!slug) { throw new Error(`workspace title produced an empty slug: ...`); }
```

`/`, `\`, and `.` are all in the stripped class, so a title cannot introduce a path separator or `..` segment.

**Evidence:** `app/lib/corpus/paths.ts:28,36-47,70-72`

---

## Claim 12: "In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode)"

**Location:** `app/lib/corpus/storeAdapter.ts:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the corpus-backed storage writes one file per persist key under `state/`; the persist middleware uses a single key (`workspace-zustand-v1`), so exactly one file results.

`createCorpusBackedStorage` maps each key to one `state/<name>.json` file — no folder-per-artifact layout:

```ts
// app/lib/corpus/storeAdapter.ts:55
const pathFor = (name: string) => `state/${name}.json`;
```

The persist config uses a single store name, so the blob is one file:

```ts
// app/lib/stores/workspaceStore.ts:495
name: "workspace-zustand-v1",
```

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-68`, `app/lib/stores/workspaceStore.ts:495`

---

## Claim 13: "the OFF path is byte-for-byte the prior behavior ... Reads are synchronous (instant); writes are debounced by 300ms"

**Location:** `app/lib/corpus/storeAdapter.ts:22-24`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers behavioral equivalence of `createDebouncedLocalStorage` to the deleted `workspaceStore.ts` `createDebouncedStorage` and the sync-read/300ms-debounced-write description; "byte-for-byte" is imprecise as to source text (the function was renamed and its return type changed).

The moved function's body is behaviorally identical to the deleted one (same `getItem` passthrough, same 300ms `setTimeout` debounce, same quota `catch`):

```ts
// app/lib/corpus/storeAdapter.ts:28-38
getItem: (name) => localStorage.getItem(name),
setItem: (name, value) => {
  if (pending) clearTimeout(pending);
  pending = setTimeout(() => {
    try { localStorage.setItem(name, value); }
    catch (e) { console.warn("Failed to persist workspace (localStorage quota exceeded):", e); }
    pending = null;
  }, 300);
```

The deleted original (from the diff) had identical logic under the name `createDebouncedStorage` with an inline object return type. So *behavior* is byte-for-byte equivalent, but the source is not literally byte-for-byte: the function was renamed to `createDebouncedLocalStorage` and typed `StateStorage`. The sync-read / 300ms-debounce description is exact.

**Evidence:** `app/lib/corpus/storeAdapter.ts:25-46`; deleted `createDebouncedStorage` per `git diff dc6dfb0...HEAD -- app/lib/stores/workspaceStore.ts`

---

## Claim 14: "\"Not found\" is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

**Location:** `app/lib/corpus/types.ts:17-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the OPFS adapter's not-found returns (`null`/`[]`) and typed-error mapping; the "never `undefined`" clause holds for the completed-promise return values on the not-found paths shown.

The OPFS adapter honors the contract: missing dir/file returns `null` from `readFile`/`stat`, `[]` from `readdir`, and all other errors funnel through `wrap()` into a `CorpusError`:

```ts
// app/lib/corpus/opfsAdapter.ts:91-97 (readFile not-found)
const dir = await walkDir(root, dirs, false);
if (!dir) return null;
...
if (isNotFound(e)) return null;
// app/lib/corpus/opfsAdapter.ts:130 (readdir missing dir)
if (!dir) return [];
// app/lib/corpus/opfsAdapter.ts:79-82 (everything else)
function wrap(path, e): never { ... throw new CorpusError(...) }
```

The unavailable-guard path was additionally executed (Claim 8), confirming a rejection rather than an `undefined` resolution.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:79-105,125-137,156-174`, `app/lib/corpus/types.ts:112-125`

---

## Claim 15: "Migrate data from workspace-v2 ... Called once on app load if the Zustand key is absent but workspace-v2 exists."

**Location:** `app/lib/stores/workspaceStore.ts:248-249`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the actual firing condition in `onRehydrateStorage`; does not exercise the full zustand rehydration lifecycle at runtime (traced statically from the guard).

The stated trigger ("Zustand key is absent") is narrower than the real guard, which fires migration whenever the legacy key exists AND there is no *usable* zustand `sourceText` — including when the zustand key is **present** but has no `state.sourceText`, or is corrupted:

```ts
// app/lib/stores/workspaceStore.ts:533-540
if (typeof window !== "undefined" && localStorage.getItem(WORKSPACE_KEY)) {
  const zustandRaw = localStorage.getItem("workspace-zustand-v1");
  let hasZustandData = false;
  try { hasZustandData = !!(zustandRaw && JSON.parse(zustandRaw)?.state?.sourceText); }
  catch { /* corrupted localStorage — proceed with migration */ }
  if (!hasZustandData) {
    migrateFromV2();
  }
}
```

The conclusion (migrate v2 → zustand when there's no prior zustand work) is right, but "if the Zustand key is absent" is imprecise: a reader assuming a present zustand key blocks migration would be wrong (a present-but-`sourceText`-less or corrupt key still migrates). Precise wording: "if there is no usable persisted zustand `sourceText`". Also note `migrateFromV2` itself returns `false` and no-ops when `loadWorkspace()` yields nothing (`workspaceStore.ts:252-253`), so the migration is inert absent v2 data.

**Evidence:** `app/lib/stores/workspaceStore.ts:248-253,528-543`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`app/lib/corpus/manifest.ts:69-73`): docstring "Throws a `CorpusError` on any malformation" overstates — `createdAt`/`updatedAt`/`label` malformations are silently defaulted (executed). Tighten to "Throws on absent bytes or a malformed structural field; `createdAt`/`updatedAt`/`label` are coerced to defaults."
- **Claim 10** (`app/lib/corpus/opfsAdapter.ts:115`): comment "Pass a fresh ArrayBuffer view" describes a copy the code never makes — `write(bytes)` passes the caller's reference unchanged (executed). Either add the copy or delete the comment.

### Stale
- **Claim 9b** (`app/lib/corpus/opfsAdapter.ts:14`): cross-reference `workspaceStore.ts:44-46` points at deleted code; the referenced console.warn swallow now lives at `storeAdapter.ts:34-35`.

### Mostly Accurate
- **Claim 13** (`app/lib/corpus/storeAdapter.ts:22-24`): "byte-for-byte" is behaviorally true but literally false — function renamed and re-typed; consider "behaviorally identical to the prior adapter."
- **Claim 15** (`app/lib/stores/workspaceStore.ts:248-249`): firing condition is broader than "Zustand key is absent" — also fires on a present-but-empty or corrupt zustand key. Reword to "no usable persisted zustand data."

### Unverifiable
- **Claim 4** (`app/lib/corpus/flag.ts:9`): build-time `NEXT_PUBLIC_CORPUS_FS` inlining could not be confirmed — `next build` is network-blocked (Google Fonts fetch fails offline), so no client bundle was produced to grep. Re-run in a networked environment (or stub `next/font/google`) and grep the built output for the inlined value.
