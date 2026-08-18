# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-corpus
**Commit:** 2dc403e
**Scope:** `git diff dc6dfb0...HEAD` — corpus-architecture change (OPFS/storeAdapter storage, `NEXT_PUBLIC_CORPUS_FS` flag, manifest codec, rehydration/migration). Checkable claims in `app/lib/corpus/*.ts` and `app/lib/stores/workspaceStore.ts`.
**Checked:** 2026-08-17
**Total claims checked:** 11
**Summary:** 6 verified, 1 mostly accurate, 2 stale, 1 incorrect, 1 unverifiable

Execution note: vitest runs required `VITEST_SKIP_INSTALL_CHECKS=1` — a stray zero-byte `/workspace/external/package.json` (outside the clone; not created by this run) crashes vitest's `ensureInstalled` package-scope walk with `ERR_INVALID_PACKAGE_CONFIG`. Skipping the install check bypasses the walk; the tests themselves are unaffected.

---

## Claim 1: "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime in a dev browser, `localStorage.setItem(\"corpus-fs-enabled\", \"1\")`"

The sentence fuses two enablement mechanisms that earn different verdicts, so it is split.

## Claim 1a: "Enable via the build-time env `NEXT_PUBLIC_CORPUS_FS=1`"

**Location:** `app/lib/corpus/flag.ts:9`
**Type:** Configuration / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether Next.js's build-time static inlining of `process.env.NEXT_PUBLIC_CORPUS_FS` through the optional-chaining member expression can be confirmed; does not establish the runtime `process.env` read branch (verified separately below) or client-bundle behavior.

The flag reads the env with optional chaining:

```ts
// app/lib/corpus/flag.ts:16
if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
```

"Build-time env" implies Next.js textually inlines `NEXT_PUBLIC_*` into the bundle at build. This is an executable guarantee whose natural test is a production build. The build is network-blocked: `app/layout.tsx:2` imports fonts via `next/font/google` (`import { EB_Garamond, Geist_Mono } from "next/font/google"`), and the build fails fetching them (paraphrased — no quote available because the failure is in generated Turbopack font modules, not a source file):

```
Error: Turbopack build failed with 2 errors:
next/font: error: Failed to fetch `EB Garamond` from Google Fonts.
next/font: error: Failed to fetch `Geist Mono` from Google Fonts.
```

Per the mandatory-execution rule, a build-inlining guarantee that cannot be built stays Unverifiable. Blocker: no network access (Google Fonts fetch in `next/font/google` aborts the build before any bundle is emitted).

**Evidence:** `app/lib/corpus/flag.ts:16`, `app/layout.tsx:2`, `evidence/r2-next-build.txt` (exit 1; `cd /workspace/external/cc-review-eval/mfc-corpus`; `NEXT_PUBLIC_CORPUS_FS=1 NEXT_TELEMETRY_DISABLED=1 npm run build`; 2026-08-18T06:56Z)

## Claim 1b: "Enable at runtime in a dev browser via `localStorage.setItem(\"corpus-fs-enabled\", \"1\")`"

**Location:** `app/lib/corpus/flag.ts:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the localStorage-key branch of `isCorpusEnabled`; does not establish the OPFS adapter behavior that a `true` return then selects.

The documented key matches the constant, and the read compares against `"1"`:

```ts
// app/lib/corpus/flag.ts:13,19
export const CORPUS_FLAG_KEY = "corpus-fs-enabled";
...
      return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
```

The env-read half of the same function is separately executable and behaves as documented — with `process.env.NEXT_PUBLIC_CORPUS_FS = "1"` set at runtime, `isCorpusEnabled()` returned `true`, and `false` once deleted (this confirms the `process.env` read path, not the build-time inlining of Claim 1a):

```
R2 isCorpusEnabled with env=1: true
```

**Evidence:** `app/lib/corpus/flag.ts:13-24`, `evidence/r2-flag-env-read.txt` (exit 0; `cd /workspace/external/cc-review-eval/mfc-corpus`; `VITEST_SKIP_INSTALL_CHECKS=1 npx vitest run --reporter=verbose app/lib/corpus/__tests__/r2_scratch.test.ts`; 2026-08-18T06:56Z)

---

## Claim 2: "parsing is FAIL-LOUD. A malformed or absent manifest must surface as a typed `CorpusError` ... never a silent default-empty manifest"

**Location:** `app/lib/corpus/manifest.ts:10-13`
**Type:** Error-handling / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole-manifest empty-masking guarantee and field-level coercions in `parseManifest`; does not establish caller behavior on the returned manifest.

The specific danger the docstring names — a silent default-empty manifest masquerading as "no work in it" — is genuinely prevented: `parseManifest` throws `CorpusError` on `null` input, non-JSON, missing `title`/`manifestVersion`, and non-array `sources`/`artifacts`/`customTypeIds` (verified by the repo's own `manifest.test.ts`, 5 tests passing, `evidence/r2-vitest-manifest.txt`). But the absolute "FAIL-LOUD ... never a silent default" framing is overbroad: several malformations inside an otherwise-valid manifest are silently defaulted rather than surfaced.

Missing timestamps are fabricated, not surfaced:

```ts
// app/lib/corpus/manifest.ts:109
createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
```

Non-object source entries and non-string custom-type ids are silently dropped by the pre-map filters:

```ts
// app/lib/corpus/manifest.ts:87,103
    ? raw.sources.filter(isObject).map((s) => {
...
    ? raw.customTypeIds.filter((x): x is string => typeof x === "string")
```

Executed confirmation: a manifest missing `createdAt` parsed to a fabricated ISO date (`R2 createdAt fabricated: 2026-08-18T06:55:51.377Z`); `sources: [{id,ext}, "garbage-string", 42]` parsed to a single surviving source (`R2 sources after parse: [{"id":"good","label":"good","ext":"pdf"}]`); `customTypeIds: ["ok", 99, null]` parsed to `["ok"]`. (An object-but-incomplete source entry *does* fail loud — `manifest.test.ts` covers `sources: [{id:"x"}]` → throws — so the fail-loud behavior is real but inconsistent across malformation shapes.)

**Evidence:** `app/lib/corpus/manifest.ts:87-113`, `evidence/r2-scratch-manifest-migrate.txt` and `evidence/r2-flag-env-read.txt` (exit 0; `cd /workspace/external/cc-review-eval/mfc-corpus`; `VITEST_SKIP_INSTALL_CHECKS=1 npx vitest run --reporter=verbose app/lib/corpus/__tests__/r2_scratch.test.ts`; 2026-08-18T06:56Z), `evidence/r2-vitest-manifest.txt` (repo `manifest.test.ts`, 5 passed)

---

## Claim 3: "a quota failure rejects with {kind:\"quota-exceeded\", substrate:\"opfs\"} — it is NOT swallowed with console.warn the way the legacy localStorage adapter does (workspaceStore.ts:44-46)"

Splits into a mechanism sub-claim (Verified) and a location reference (Stale).

## Claim 3a: "a quota failure rejects with {kind:\"quota-exceeded\", substrate:\"opfs\"}, not swallowed"

**Location:** `app/lib/corpus/opfsAdapter.ts:12-13`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the OPFS adapter's own reject-on-quota mechanism; does NOT establish that the reified error is surfaced to any UI — the store-level consumer awaits `writeFile` with no catch (`app/lib/corpus/storeAdapter.ts:62`), so the reified rejection propagates into zustand persist as an unhandled rejection rather than a swallowed-or-surfaced failure (an error-handling concern for the critics, not a doc mismatch).

Every adapter method routes failures through `wrap`, which rethrows a typed quota error rather than swallowing it:

```ts
// app/lib/corpus/opfsAdapter.ts:81
  if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
```

Unlike the localStorage adapter, which swallows the quota failure with `console.warn`:

```ts
// app/lib/corpus/storeAdapter.ts:35
          console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
```

**Evidence:** `app/lib/corpus/opfsAdapter.ts:78-82`, `app/lib/corpus/storeAdapter.ts:30-38`, `app/lib/corpus/storeAdapter.ts:61-63`

## Claim 3b: "...the way the legacy localStorage adapter does (workspaceStore.ts:44-46)"

**Location:** `app/lib/corpus/opfsAdapter.ts:14`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the `workspaceStore.ts:44-46` line citation; the swallowing behavior it points at is real but now lives elsewhere.

The console.warn-swallowing debounced adapter was moved out of `workspaceStore.ts` in this same change (the diff deletes `createDebouncedStorage` from `workspaceStore.ts` and re-homes it as `createDebouncedLocalStorage` in `storeAdapter.ts`). `workspaceStore.ts:44-46` now holds rehydration-validation coercion, not a quota swallow:

```ts
// app/lib/stores/workspaceStore.ts:44-46
    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
    source: VALID_ARTIFACT_SOURCES.has(raw.source as string) ? raw.source as ArtifactVersion["source"] : "generated",
    editInstruction: typeof raw.editInstruction === "string" ? raw.editInstruction : undefined,
```

The actual swallow is now at `app/lib/corpus/storeAdapter.ts:35`. The reference should point there.

**Evidence:** `app/lib/stores/workspaceStore.ts:40-48`, `app/lib/corpus/storeAdapter.ts:35`

---

## Claim 4: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** `app/lib/corpus/opfsAdapter.ts:115`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the write actually constructs a fresh ArrayBuffer view; does not evaluate whether a fresh view is needed.

The comment claims a defensive copy the code does not make. The very next line writes the caller's `bytes` argument through unchanged — no `.slice()`, no `new Uint8Array(...)`, no fresh buffer allocation:

```ts
// app/lib/corpus/opfsAdapter.ts:115-116
          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
          await w.write(bytes);
```

`bytes` is the `writeFile(path, bytes)` parameter passed straight from the caller (`CorpusFS.writeFile`); it is written by reference, so any shared/pooled buffer the caller supplied is written as-is. A reader trusting the comment would wrongly believe shared-buffer inputs are already defended against here.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:105-118`, `app/lib/corpus/types.ts:117` (`writeFile(path: string, bytes: Uint8Array)` signature)

---

## Claim 5: "the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used by the store until S4"

**Location:** `app/lib/corpus/storeAdapter.ts:11`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `layout.ts` filename reference; the "built but not used until S4" behavioral half is not contradicted.

`layout.ts` no longer exists — it was renamed to `paths.ts` in this change (commit `122d70f`, "rename layout.ts->paths.ts (Next reserved name)"), because `layout.ts`/`layout.tsx` is a reserved Next.js filename under `app/`. A grep for `layout.ts` finds it only in stale references, while `CLAUDE.md` and `checkpoint-corpus-s1.md` document the rename explicitly (paraphrased — no quote available because the claim is about a file's absence: no `app/lib/corpus/layout.ts` exists). The path-builder module the comment means is `app/lib/corpus/paths.ts`; `manifest.ts` is correct.

**Evidence:** `app/lib/corpus/storeAdapter.ts:11`, `app/lib/corpus/paths.ts:1` (module docstring "Corpus folder-layout path builders"), `docs/working/checkpoint-corpus-s1.md:25`

---

## Claim 6: "Reads are synchronous (instant); writes are debounced by 300ms" (localStorage adapter moved verbatim, OFF path byte-for-byte prior behavior)

**Location:** `app/lib/corpus/storeAdapter.ts:22-23`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the synchronous-read / 300ms-debounced-write behavior and that the body matches the pre-change `workspaceStore.ts` adapter; does not run the debounce timing.

`getItem` calls `localStorage.getItem` synchronously and `setItem` schedules the write on a 300ms `setTimeout`:

```ts
// app/lib/corpus/storeAdapter.ts:29,38
    getItem: (name) => localStorage.getItem(name),
...
      }, 300);
```

The diff confirms the body is the same code deleted from `workspaceStore.ts` (`createDebouncedStorage` removed there, re-added as `createDebouncedLocalStorage` here with identical getItem/setItem/removeItem bodies and the same 300ms constant and console.warn quota guard) — supporting the "moved verbatim / byte-for-byte prior behavior" claim.

**Evidence:** `app/lib/corpus/storeAdapter.ts:24-42`, `git diff dc6dfb0...HEAD -- app/lib/stores/workspaceStore.ts` (deleted `createDebouncedStorage` block, 300ms)

---

## Claim 7: "'Not found' is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

**Location:** `app/lib/corpus/types.ts:17-18`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the OPFS adapter's not-found → null/[] and error → CorpusError mapping; the OPFS success path itself is not runnable under jsdom (no OPFS) so timing/handle behavior is read, not executed. Note the store-level consumer (`createCorpusBackedStorage.getItem`, `storeAdapter.ts:58-61`) re-throws a non-NotFound `readFile` rejection into zustand rehydration, where `onRehydrateStorage`'s `if (error) return` (`workspaceStore.ts:530`) discards it and defaults remain rendered — a later `setItem` then persists defaults over the file. That clobber-on-read-error path is a downstream error-handling concern for the critics, not a contradiction of this contract.

The adapter honors the contract: `readFile`/`stat` return `null` when a directory segment or file is missing (`if (!dir) return null;`, `if (isNotFound(e)) return null;`), `readdir` returns `[]` (`if (!dir) return [];`), and all other failures route through `wrap`, which always throws a `CorpusError`:

```ts
// app/lib/corpus/opfsAdapter.ts:82
  throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });
```

No path returns `undefined`.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:87-102` (readFile), `:125-131` (readdir), `:156-170` (stat), `:79-84` (wrap)

---

## Claim 8: "Migrate data from workspace-v2 localStorage format into the Zustand store. Called once on app load if the Zustand key is absent but workspace-v2 exists."

**Location:** `app/lib/stores/workspaceStore.ts:248-249`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `migrateFromV2`'s read-old-data-and-populate behavior and the `onRehydrateStorage` gate that invokes it; does not exercise the "called once" idempotence across multiple real rehydrations.

`migrateFromV2` returns `false` when no v2 data is present and `true` + populates the store when `workspace-v2` exists. Executed: with `workspace-v2` set, `migrateFromV2()` returned `true` and the store's `sourceText` became the migrated value (`R2 migrateFromV2 result: true` / `R2 store sourceText: hello-from-v2`); with localStorage cleared it returned `false`. The rehydrate gate matches the "Zustand key absent but workspace-v2 exists" condition:

```ts
// app/lib/stores/workspaceStore.ts:533-540
          if (typeof window !== "undefined" && localStorage.getItem(WORKSPACE_KEY)) {
            const zustandRaw = localStorage.getItem("workspace-zustand-v1");
            let hasZustandData = false;
            try { hasZustandData = !!(zustandRaw && JSON.parse(zustandRaw)?.state?.sourceText); }
            catch { /* corrupted localStorage — proceed with migration */ }
            if (!hasZustandData) {
              migrateFromV2();
```

**Evidence:** `app/lib/stores/workspaceStore.ts:251-285` (migrateFromV2), `:528-543` (onRehydrateStorage), `evidence/r2-flag-env-read.txt` (exit 0; `cd /workspace/external/cc-review-eval/mfc-corpus`; `VITEST_SKIP_INSTALL_CHECKS=1 npx vitest run --reporter=verbose app/lib/corpus/__tests__/r2_scratch.test.ts`; 6 passed; 2026-08-18T06:56Z)

---

## Claim 9: "SSR safe: render defaults first, hydrate in useEffect via rehydrate()"

**Location:** `app/lib/stores/workspaceStore.ts:500`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `skipHydration: true` defers hydration so defaults render first; does not assert hydration always succeeds — on a non-NotFound `readFile` rejection during rehydrate the defaults persist (see Claim 7 scope).

`skipHydration: true` is set immediately below the comment, which is exactly the zustand-persist option that suppresses automatic hydration so the component tree renders store defaults on first paint (SSR-safe) and hydration is triggered later by an explicit `rehydrate()` call:

```ts
// app/lib/stores/workspaceStore.ts:500-501
      // SSR safe: render defaults first, hydrate in useEffect via rehydrate()
      skipHydration: true,
```

The module docstring corroborates the pattern: `skipHydration: true for Next.js SSR safety (call rehydrate() in useEffect)` (`workspaceStore.ts:6`).

**Evidence:** `app/lib/stores/workspaceStore.ts:499-501`, `:6`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`app/lib/corpus/opfsAdapter.ts:115`): Comment claims "Pass a fresh ArrayBuffer view" but the code writes the caller's `bytes` unchanged — no fresh view is created. Fix the comment (or add the copy it describes).

### Stale
- **Claim 3b** (`app/lib/corpus/opfsAdapter.ts:14`): Reference `workspaceStore.ts:44-46` for the swallowing localStorage adapter is stale; that code moved to `storeAdapter.ts:35` in this change.
- **Claim 5** (`app/lib/corpus/storeAdapter.ts:11`): References `layout.ts`, which was renamed to `paths.ts` (Next reserved filename) in this change.

### Mostly Accurate
- **Claim 2** (`app/lib/corpus/manifest.ts:10-13`): The "never a silent default-empty manifest" guarantee holds, but the absolute "FAIL-LOUD" framing overstates: missing `createdAt`/`updatedAt` are fabricated and non-object source entries / non-string custom-type ids are silently dropped rather than surfaced.

### Unverifiable
- **Claim 1a** (`app/lib/corpus/flag.ts:9`): Build-time `NEXT_PUBLIC_CORPUS_FS` inlining could not be built — `next/font/google` fails fetching Google Fonts with no network. Needs a build with network access (or a self-hosted/mocked font) to confirm the optional-chaining member expression inlines.
