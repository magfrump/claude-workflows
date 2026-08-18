# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-corpus
**Commit:** 2dc403e
**Scope:** `git diff dc6dfb0...HEAD` — DD-009 corpus-architecture change (OPFS/storeAdapter storage, `NEXT_PUBLIC_CORPUS_FS` flag, manifest codec, rehydration/migration). Checkable claims in `app/lib/corpus/*.ts`, `app/lib/stores/workspaceStore.ts`, and `CLAUDE.md`. Prior review artifacts inside the clone ignored per blinding.
**Checked:** 2026-08-18
**Total claims checked:** 18
**Summary:** 10 verified, 3 mostly accurate, 2 stale, 2 incorrect, 1 unverifiable
**Replication:** k=2 (both replicates executed)

Merge note: this report is a most-severe-wins collation of two independent fact-check replicates (r1, r2) over the same commit. Each claim records both replicates' verdicts on a `**Replicate verdicts:**` line; claims surfaced by only one replicate are tagged `single-replicate detection`. Evidence/reasoning is carried from the replicate that assigned the winning verdict.

Execution environment note (both replicates): the repo's `vitest` process exits non-zero even when every test passes, because a stray zero-byte `/workspace/external/package.json` *outside* the clone crashes vitest's install/package-scope check (`ERR_INVALID_PACKAGE_CONFIG`). r2 bypassed it with `VITEST_SKIP_INSTALL_CHECKS=1`; r1 read the authoritative `Test Files N passed / Tests N passed` line instead. The tests themselves are unaffected; both replicates' executed vitest runs show all tests passing.

---

## Claim 1: "`paths.ts` — **not** `layout.ts`, which is a reserved Next.js filename"

**Location:** `CLAUDE.md:55`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of `paths.ts` (and absence of `layout.ts`) in `app/lib/corpus/`; does not independently adjudicate Next.js's reserved-filename list beyond the rename's stated rationale.
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

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
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

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
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

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
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable

This is an executable guarantee (build-time env replacement), so the mandatory-execution rule applies. Both replicates ran `next build` with the env set; both aborted before producing any client bundle to grep, because the sandbox has **no network** and Next's `next/font/google` loader could not fetch the fonts declared in `app/layout.tsx`:

```
Error: Turbopack build failed with 2 errors:
next/font: error: Failed to fetch `EB Garamond` from Google Fonts.
next/font: error: Failed to fetch `Geist Mono` from Google Fonts.
  ...Server Component: ./app/layout.tsx
```

**Named blocker:** network-blocked Google Fonts fetch during `next build` (`next/font/google` in `app/layout.tsx:2` aborts the build before any bundle is emitted). No built output was produced, so the optional-chaining inlining question (`process.env?.NEXT_PUBLIC_CORPUS_FS` — whether Turbopack's `NEXT_PUBLIC_*` substitution survives the `?.` on `process.env`) could not be confirmed. Verdict capped at Unverifiable per the mandatory-execution rule; static reading cannot certify build-pipeline substitution. Re-run in a networked environment (or stub/self-host `next/font/google`) and grep the built output for the inlined value.

**Evidence:** `app/lib/corpus/flag.ts:16`, `app/layout.tsx:2` (font imports), captured output `./evidence/r1-next-build-flag-set.txt` and `./evidence/r2-next-build.txt`
- command: `NEXT_PUBLIC_CORPUS_FS=1 NEXT_TELEMETRY_DISABLED=1 next build` (r1) / `... npm run build` (r2)
- cwd: `/workspace/external/cc-review-eval/mfc-corpus`
- exit code: 1 (build error — font fetch), both replicates
- timestamp: 2026-08-18 (r2: 2026-08-18T06:56Z)

---

## Claim 5: "at runtime in a dev browser, `localStorage.setItem(\"corpus-fs-enabled\", \"1\")`" enables the flag

**Location:** `app/lib/corpus/flag.ts:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the localStorage key name and comparison; does not cover browser-specific localStorage availability or the OPFS adapter behavior a `true` return then selects.
**Replicate verdicts:** r1=Verified · r2=Verified

The key constant and the read match the documented setter exactly:

```ts
// app/lib/corpus/flag.ts:13,19
export const CORPUS_FLAG_KEY = "corpus-fs-enabled";
...
return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
```

r2 additionally exercised the env-read half of the same function: with `process.env.NEXT_PUBLIC_CORPUS_FS = "1"` set at runtime, `isCorpusEnabled()` returned `true`, and `false` once deleted (confirms the `process.env` read path, distinct from the build-time inlining of Claim 4).

**Evidence:** `app/lib/corpus/flag.ts:13,19`, `./evidence/r2-flag-env-read.txt` (env-read path, exit 0)

---

## Claim 6: "parsing is FAIL-LOUD. A malformed or absent manifest must surface as a typed `CorpusError` ... never a silent default-empty manifest" (header docstring)

**Location:** `app/lib/corpus/manifest.ts:10-14`
**Type:** Error-handling / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header docstring's whole-manifest empty-masking guarantee AND its absolute "never a silent default" framing against field-level coercions in `parseManifest`; does not establish caller behavior on the returned manifest. Distinct doc location from the per-function docstring in Claim 7 (`manifest.ts:69-73`).
**Replicate verdicts:** r1=Verified · r2=Mostly accurate

**Reconciliation of the divergence:** both replicates examined the same manifest-codec contract at the header scope but read the docstring at different breadths. r1 read it narrowly — the specific "default-*empty* manifest" danger — and found it genuinely prevented, so verdicted Verified. r2 read the absolute "FAIL-LOUD ... never a silent default" framing and found it overbroad because several *field-level* malformations inside an otherwise-valid manifest are silently defaulted rather than surfaced, so verdicted Mostly accurate. Most-severe-wins → Mostly accurate.

The specific danger the docstring names — a silent default-empty manifest masquerading as "no work in it" — is genuinely prevented: `parseManifest` throws `CorpusError` on `null` input, non-JSON, missing `title`/`manifestVersion`, and non-array `sources`/`artifacts`/`customTypeIds` (verified by the repo's own `manifest.test.ts`, 5 tests passing). But the absolute framing is overbroad — missing timestamps are fabricated, not surfaced:

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

Executed confirmation (r2): a manifest missing `createdAt` parsed to a fabricated ISO date; `sources: [{id,ext}, "garbage-string", 42]` parsed to a single surviving source; `customTypeIds: ["ok", 99, null]` parsed to `["ok"]`. (An object-but-incomplete source entry *does* fail loud — `manifest.test.ts` covers `sources: [{id:"x"}]` → throws — so the fail-loud behavior is real but inconsistent across malformation shapes.)

**Evidence:** `app/lib/corpus/manifest.ts:87-113`, `./evidence/r2-scratch-manifest-migrate.txt`, `./evidence/r2-flag-env-read.txt` (exit 0), `./evidence/r2-vitest-manifest.txt` (repo `manifest.test.ts`, 5 passed)

---

## Claim 7: "Parse + validate manifest bytes. Throws a `CorpusError` on any malformation" (per-function docstring)

**Location:** `app/lib/corpus/manifest.ts:69-73`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-function docstring's universal "any malformation → throws" claim against the `createdAt`/`updatedAt`/`label` fields, which are silently defaulted rather than rejected; does not contradict the whole-manifest fail-loud behavior of Claim 6. Distinct doc location from the header docstring (`manifest.ts:10-14`).
**Replicate verdicts:** r1=Incorrect · r2=— · single-replicate detection

The per-function docstring says *any* malformation throws, but three fields are silently coerced instead. A wrong-typed `createdAt` (a number) and `updatedAt` (`null`) do not throw — they are replaced with a fresh timestamp:

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

Executed confirmation (r1): `parseManifest` of a manifest with `createdAt: 12345, updatedAt: null` returned without throwing and produced fresh ISO timestamps; a source `{id:"s1", ext:"pdf"}` (no label) yielded `label:"s1"`. A reader relying on "any malformation throws" (e.g. to trust that a persisted `createdAt` round-trips or that a missing label is an error) is misled. This per-function docstring overstates the narrower, accurate header docstring (Claim 6).

**Evidence:** `app/lib/corpus/manifest.ts:89,109-110`, captured output `./evidence/r1-scratch-vitest.txt` (`R1_CREATEDAT_RESULT`, `R1_LABEL_RESULT`)
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
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

`getRoot()` throws the typed error before any raw property access:

```ts
// app/lib/corpus/opfsAdapter.ts:50-53
const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
if (!storage || typeof storage.getDirectory !== "function") {
  throw new CorpusError({ kind: "unavailable", reason: "navigator.storage.getDirectory is not available (SSR or unsupported browser)" });
}
```

Executed (r1): `await fs.readFile("state/x.json")` under the test env rejected with `{"kind":"unavailable",...}` — a `CorpusError`, not a `TypeError`.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:49-55,85-105`, captured output `./evidence/r1-scratch-vitest.txt` (`R1_OPFS_ERR`)
- command: `vitest run app/lib/corpus/__tests__/factcheck_scratch_r1.test.ts --reporter=verbose --disable-console-intercept`
- cwd: `/workspace/external/cc-review-eval/mfc-corpus`
- exit code: 1 (environmental — see header note; `6 passed`)
- timestamp: 2026-08-18T06:54:10Z (UTC)

---

## Claim 9: "a quota failure rejects with {kind:\"quota-exceeded\", substrate:\"opfs\"} — it is NOT swallowed with console.warn the way the legacy localStorage adapter does"

**Location:** `app/lib/corpus/opfsAdapter.ts:12-14`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the OPFS adapter's own reject-on-quota mechanism (the `wrap()` mapping of a `QuotaExceededError`/`QUOTA_EXCEEDED_ERR` DOMException to the typed kind); does not cover whether a real OPFS quota event surfaces one of those DOMException names (browser-dependent, not reproducible in jsdom), and does NOT establish that the reified error is surfaced to any UI.
**Replicate verdicts:** r1=Verified · r2=Verified

The quota classifier and the mapping in `wrap()` match the claim, and the contrasted localStorage adapter does swallow with `console.warn`:

```ts
// app/lib/corpus/opfsAdapter.ts:45-47,81
function isQuota(e: unknown): boolean {
  return e instanceof DOMException && (e.name === "QuotaExceededError" || e.name === "QUOTA_EXCEEDED_ERR");
}
...
if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
```

```ts
// app/lib/corpus/storeAdapter.ts:35
console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
```

**Note for critics (from r2's Scope, carried forward — an error-handling concern, not a doc mismatch):** the store-level consumer awaits `writeFile` with no catch (`app/lib/corpus/storeAdapter.ts:62`), so the reified OPFS quota rejection propagates into zustand persist as an *unhandled rejection* rather than a swallowed-or-surfaced failure. The doc claim about the adapter's own mechanism is accurate; whether the reified error is ever surfaced is a downstream error-handling question for the critics.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:45-47,78-83`, `app/lib/corpus/storeAdapter.ts:30-38,61-63`

---

## Claim 10: "...the way the legacy localStorage adapter does (`workspaceStore.ts:44-46`)"

**Location:** `app/lib/corpus/opfsAdapter.ts:14`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the `workspaceStore.ts:44-46` line pointer; the substance (the OPFS adapter reifies quota instead of swallowing it) is correct per Claim 9.
**Replicate verdicts:** r1=Stale · r2=Stale

The referenced legacy `console.warn` swallow no longer lives at `workspaceStore.ts:44-46`. This same diff deleted `createDebouncedStorage` from `workspaceStore.ts` and re-homed it as `createDebouncedLocalStorage` in `storeAdapter.ts`, where the swallow now sits:

```ts
// app/lib/corpus/storeAdapter.ts:34-35
} catch (e) {
  console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
```

At HEAD, `workspaceStore.ts:44-46` is unrelated rehydration-validation code (`createdAt`/`source`/`editInstruction` coercion in an artifact-version parser), not a quota swallow:

```ts
// app/lib/stores/workspaceStore.ts:44-46
    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
    source: VALID_ARTIFACT_SOURCES.has(raw.source as string) ? raw.source as ArtifactVersion["source"] : "generated",
    editInstruction: typeof raw.editInstruction === "string" ? raw.editInstruction : undefined,
```

The pointer should read `storeAdapter.ts:34-35` (r1 cites `:34-35`; r2 cites `:35`).

**Evidence:** `app/lib/corpus/storeAdapter.ts:33-36`, `app/lib/stores/workspaceStore.ts:40-48` (current content unrelated)

---

## Claim 11: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** `app/lib/corpus/opfsAdapter.ts:115`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether `writeFile` actually hands `write()` a fresh/copied view; does not cover whether real OPFS implementations require one.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect

High-confidence merge — both replicates independently found this Incorrect (r1 by execution, r2 by static reading). The comment asserts a fresh view is passed, but the very next line writes the caller's `bytes` reference unchanged — no `.slice()`, no copy, no new view:

```ts
// app/lib/corpus/opfsAdapter.ts:115-116
// Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
await w.write(bytes);
```

Executed confirmation (r1): with a stubbed OPFS root, the `Uint8Array` observed by `write()` was the *same object reference* the caller passed (`R1_WRITE_SAME_REF: true`, `sameBuffer: true`). `bytes` is the `writeFile(path, bytes)` parameter passed straight from `CorpusFS.writeFile`. A reader trusting the comment (e.g. assuming it is safe to mutate `bytes` after the call, or that shared-buffer-averse backends are handled) is misled. Either add the copy or delete the comment.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:105-123`, `app/lib/corpus/types.ts:117` (`writeFile(path, bytes: Uint8Array)` signature), captured output `./evidence/r1-scratch-vitest.txt` (`R1_WRITE_SAME_REF`)
- command: `vitest run app/lib/corpus/__tests__/factcheck_scratch_r1.test.ts ...`
- cwd: `/workspace/external/cc-review-eval/mfc-corpus`
- exit code: 1 (environmental — see header note; `6 passed`)
- timestamp: 2026-08-18T06:54:10Z (UTC)

---

## Claim 12: "the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`"

**Location:** `app/lib/corpus/paths.ts:16-19,30-35`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `workspaceSlug` strips `/`, `\`, and dot-runs via `SAFE_SEGMENT` and throws on an empty result; does not exhaustively prove no Unicode normalization edge case survives, and does not verify callers never bypass it.
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

Every workspace path routes through `workspaceDir` → `workspaceSlug`, which collapses any character outside `[a-zA-Z0-9_-]` to a hyphen and rejects an all-unsafe title:

```ts
// app/lib/corpus/paths.ts:28,37-46
const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;
...
const slug = title.normalize("NFKD").replace(SAFE_SEGMENT, "-")...
if (!slug) { throw new Error(`workspace title produced an empty slug: ...`); }
```

`/`, `\`, and `.` are all in the stripped class, so a title cannot introduce a path separator or `..` segment.

**Evidence:** `app/lib/corpus/paths.ts:28,36-47,70-72`

---

## Claim 13: "In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode)"

**Location:** `app/lib/corpus/storeAdapter.ts:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the corpus-backed storage writes one file per persist key under `state/`; the persist middleware uses a single key (`workspace-zustand-v1`), so exactly one file results.
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

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

## Claim 14: "the files-per-artifact folder layout (`layout.ts`/`manifest.ts`) is built but not used by the store until S4"

**Location:** `app/lib/corpus/storeAdapter.ts:11`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `layout.ts` filename reference; the "built but not used until S4" behavioral half is not contradicted. This is the second stale cross-reference (distinct from Claim 10's `workspaceStore.ts:44-46` pointer): the `layout.ts → paths.ts` rename reference.
**Replicate verdicts:** r1=— · r2=Stale · single-replicate detection

`layout.ts` no longer exists — it was renamed to `paths.ts` in this change (commit `122d70f`, "rename layout.ts->paths.ts (Next reserved name)"), because `layout.ts`/`layout.tsx` is a reserved Next.js filename under `app/`. A grep for `layout.ts` finds it only in stale references, while `CLAUDE.md` and `checkpoint-corpus-s1.md` document the rename explicitly (paraphrased — no quote available because the claim is about a file's absence: no `app/lib/corpus/layout.ts` exists). The path-builder module the comment means is `app/lib/corpus/paths.ts`; `manifest.ts` is correct.

**Evidence:** `app/lib/corpus/storeAdapter.ts:11`, `app/lib/corpus/paths.ts:1` (module docstring "Corpus folder-layout path builders"), `docs/working/checkpoint-corpus-s1.md:25`

---

## Claim 15: "the OFF path is byte-for-byte the prior behavior ... Reads are synchronous (instant); writes are debounced by 300ms"

**Location:** `app/lib/corpus/storeAdapter.ts:22-24`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers behavioral equivalence of `createDebouncedLocalStorage` to the deleted `workspaceStore.ts` `createDebouncedStorage` and the sync-read/300ms-debounced-write description; "byte-for-byte" is imprecise as to source text (the function was renamed and its return type changed).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified

**Divergence:** r1 flagged "byte-for-byte" as literally false — the function was renamed to `createDebouncedLocalStorage` and retyped `StateStorage`, so the source is not byte-for-byte identical even though behavior is — and verdicted Mostly accurate. r2 read the claim as a behavioral/"moved verbatim" assertion and verdicted Verified. Most-severe-wins → Mostly accurate.

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

So *behavior* is byte-for-byte equivalent, but the source is not literally byte-for-byte: the function was renamed and typed `StateStorage`. The sync-read / 300ms-debounce description is exact. Consider rewording to "behaviorally identical to the prior adapter."

**Evidence:** `app/lib/corpus/storeAdapter.ts:24-46`; deleted `createDebouncedStorage` per `git diff dc6dfb0...HEAD -- app/lib/stores/workspaceStore.ts`

---

## Claim 16: "\"Not found\" is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

**Location:** `app/lib/corpus/types.ts:17-18`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the OPFS adapter's not-found returns (`null`/`[]`) and typed-error mapping; the "never `undefined`" clause holds for the completed-promise return values on the not-found paths shown. The OPFS success path itself is not runnable under jsdom, so handle/timing behavior is read, not executed.
**Replicate verdicts:** r1=Verified · r2=Verified

The OPFS adapter honors the contract: missing dir/file returns `null` from `readFile`/`stat`, `[]` from `readdir`, and all other errors funnel through `wrap()` into a `CorpusError`; no path returns `undefined`:

```ts
// app/lib/corpus/opfsAdapter.ts (readFile not-found / readdir / wrap)
if (!dir) return null;          // readFile / stat
if (isNotFound(e)) return null;
if (!dir) return [];            // readdir
throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });  // wrap
```

r1 additionally executed the unavailable-guard path (Claim 8), confirming a rejection rather than an `undefined` resolution.

**Note for critics (from r2's Scope, carried forward — an error-handling concern, not a doc mismatch):** the store-level consumer (`createCorpusBackedStorage.getItem`, `storeAdapter.ts:58-61`) re-throws a *non-NotFound* `readFile` rejection into zustand rehydration, where `onRehydrateStorage`'s `if (error) return` (`workspaceStore.ts:530`) discards it and defaults remain rendered — a later `setItem` then persists defaults over the file. That clobber-on-read-error path does not contradict this contract; it is a downstream error-handling concern for the critics.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:79-105,125-137,156-174`, `app/lib/corpus/types.ts:112-125`

---

## Claim 17: "Migrate data from workspace-v2 ... Called once on app load if the Zustand key is absent but workspace-v2 exists."

**Location:** `app/lib/stores/workspaceStore.ts:248-249`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the actual firing condition in `onRehydrateStorage`; does not exercise the full zustand rehydration lifecycle at runtime (traced statically from the guard by r1; r2 executed `migrateFromV2` itself).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified

**Divergence:** r1 flagged the stated trigger ("if the Zustand key is absent") as imprecise — the real guard fires whenever the legacy key exists AND there is no *usable* zustand `sourceText`, including when the zustand key is present but has no `state.sourceText` or is corrupt — and verdicted Mostly accurate. r2 executed `migrateFromV2` (returns `true` and populates the store with `workspace-v2` present; `false` when cleared) and, reading the gate as matching the documented condition, verdicted Verified. Most-severe-wins → Mostly accurate (the docstring's firing condition is narrower than the code's).

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

The conclusion (migrate v2 → zustand when there's no prior zustand work) is right, but "if the Zustand key is absent" is imprecise: a present-but-`sourceText`-less or corrupt key still migrates. Precise wording: "if there is no usable persisted zustand `sourceText`". `migrateFromV2` itself returns `false` and no-ops when `loadWorkspace()` yields nothing (`workspaceStore.ts:252-253`), so the migration is inert absent v2 data.

**Evidence:** `app/lib/stores/workspaceStore.ts:248-253,528-543`, `./evidence/r2-flag-env-read.txt` (`migrateFromV2` executed: `R2 migrateFromV2 result: true` / `R2 store sourceText: hello-from-v2`; exit 0)

---

## Claim 18: "SSR safe: render defaults first, hydrate in useEffect via rehydrate()"

**Location:** `app/lib/stores/workspaceStore.ts:500`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `skipHydration: true` defers hydration so defaults render first; does not assert hydration always succeeds — on a non-NotFound `readFile` rejection during rehydrate the defaults persist (see Claim 16 note).
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection

`skipHydration: true` is set immediately below the comment — the zustand-persist option that suppresses automatic hydration so the component tree renders store defaults on first paint (SSR-safe) and hydration is triggered later by an explicit `rehydrate()` call:

```ts
// app/lib/stores/workspaceStore.ts:500-501
// SSR safe: render defaults first, hydrate in useEffect via rehydrate()
skipHydration: true,
```

The module docstring corroborates the pattern (`workspaceStore.ts:6`).

**Evidence:** `app/lib/stores/workspaceStore.ts:499-501`, `:6`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`app/lib/corpus/manifest.ts:69-73`): per-function docstring "Throws a `CorpusError` on any malformation" overstates — `createdAt`/`updatedAt`/`label` malformations are silently defaulted (executed, r1). Tighten to "Throws on absent bytes or a malformed structural field; `createdAt`/`updatedAt`/`label` are coerced to defaults."
- **Claim 11** (`app/lib/corpus/opfsAdapter.ts:115`): comment "Pass a fresh ArrayBuffer view" describes a copy the code never makes — `write(bytes)` passes the caller's reference unchanged (both replicates Incorrect; r1 executed). Either add the copy or delete the comment.

### Stale
- **Claim 10** (`app/lib/corpus/opfsAdapter.ts:14`): cross-reference `workspaceStore.ts:44-46` points at deleted code; the referenced console.warn swallow now lives at `storeAdapter.ts:34-35` (both replicates).
- **Claim 14** (`app/lib/corpus/storeAdapter.ts:11`): references `layout.ts`, renamed to `paths.ts` (Next reserved filename) in this change (r2 only).

### Mostly Accurate
- **Claim 6** (`app/lib/corpus/manifest.ts:10-14`): header docstring's "never a silent default-empty manifest" guarantee holds, but the absolute "FAIL-LOUD" framing overstates — field-level malformations (`createdAt`/`updatedAt`, non-object sources, non-string custom-type ids) are silently defaulted/dropped (r1 Verified / r2 Mostly accurate; merged Mostly accurate).
- **Claim 15** (`app/lib/corpus/storeAdapter.ts:22-24`): "byte-for-byte" is behaviorally true but literally false — function renamed and re-typed (r1 Mostly accurate / r2 Verified). Consider "behaviorally identical to the prior adapter."
- **Claim 17** (`app/lib/stores/workspaceStore.ts:248-249`): firing condition is broader than "Zustand key is absent" — also fires on a present-but-empty or corrupt zustand key (r1 Mostly accurate / r2 Verified). Reword to "no usable persisted zustand data."

### Unverifiable
- **Claim 4** (`app/lib/corpus/flag.ts:9`): build-time `NEXT_PUBLIC_CORPUS_FS` inlining could not be confirmed — `next build` is network-blocked (Google Fonts fetch in `next/font/google` fails offline), so no client bundle was produced to grep (both replicates). Re-run in a networked environment (or stub/self-host the fonts) and grep the built output for the inlined value.

---

## Verdict stability

- **Total merged clusters:** 18
- **Clusters surfaced by both replicates:** 9 (Claims 4, 5, 6, 9, 10, 11, 15, 16, 17)
- **Single-replicate detections:** 9 (r1-only: Claims 1, 2, 3, 7, 8, 12, 13; r2-only: Claims 14, 18)
- **Both-surfaced clusters where replicates agreed:** 6 of 9 (Claims 4, 5, 9, 10, 11, 16)
- **Both-surfaced clusters where verdicts disagreed:** 3 of 9
  - **Claim 6** (`manifest.ts:10-14`, FAIL-LOUD header docstring): r1=Verified · r2=Mostly accurate → merged **Mostly accurate**. Same contract read at different breadths (narrow "default-empty" danger vs. absolute "never a silent default" framing).
  - **Claim 15** (`storeAdapter.ts:22-24`, OFF-path "byte-for-byte"): r1=Mostly accurate · r2=Verified → merged **Mostly accurate**. r1 penalized the literal-source imprecision (renamed/retyped); r2 read it behaviorally.
  - **Claim 17** (`workspaceStore.ts:248-249`, migration firing condition): r1=Mostly accurate · r2=Verified → merged **Mostly accurate**. r1 found the documented "Zustand key absent" trigger narrower than the code's "no usable zustand `sourceText`" guard.
- **Agreement rate (both-surfaced clusters):** 6/9 = 67%. All three disagreements are Mostly-accurate-vs-Verified adjacency splits at the imprecision boundary — none straddle the Incorrect/blocking threshold. The two Incorrect verdicts (Claims 7, 11) and the two Stale verdicts (Claims 10, 14) carried no cross-replicate disagreement (Claim 11 and Claim 10 were confirmed by both; Claims 7 and 14 were single-replicate).

## Goal-Alignment Note
- Answered: yes — merged both replicates into one canonical report.
- Out of scope: no re-verification and no target-repo reads were performed (blinded merge per instructions); disagreements resolved by most-severe-wins.
- Escalate: two carried-forward error-handling notes (awaited-`writeFile` with no catch at `storeAdapter.ts:62`; non-NotFound `readFile` clobber-on-read-error path) are for the Stage-2 critics, not doc mismatches.
