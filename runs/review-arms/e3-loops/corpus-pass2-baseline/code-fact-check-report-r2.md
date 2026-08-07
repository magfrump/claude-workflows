# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree wt-corpus-arm, branch e3/corpus-arm)
**Scope:** `git diff dc6dfb0..HEAD -- app/` (corpus S0/S1 layer + workspaceStore seam); FULL scope, pass-2 replicate 2
**Commit:** 409e9dc
**Checked:** 2026-08-06
**Total claims checked:** 20
**Summary:** 16 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Pass-1 fix claims (R1–R4 + amber narrowings) and standing S0/S1 claims re-checked. No `docs/reviews/hallucination-patterns.md` exists in this worktree; none of the findings below are fabrication-class, so no log entry is warranted.

---

## Claim 1: state blob is routed through `paths.ts` `stateBlobPath()` + `STATE_DIR` (fix R1)

**Location:** `app/lib/corpus/paths.ts:63-70`, `app/lib/corpus/storeAdapter.ts:60-66`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`paths.ts` defines the single-source builder and directory constant:

```ts
// app/lib/corpus/paths.ts (STATE_DIR + stateBlobPath)
export const STATE_DIR = "state";
export function stateBlobPath(name: string): string {
  return `${STATE_DIR}/${safeSegment(name)}.json`;
}
```

`storeAdapter.ts` imports and uses it rather than hand-concatenating — `import { stateBlobPath } from "./paths";` and all three storage methods call it:

```ts
// createCorpusBackedStorage — getItem/setItem/removeItem
getItem: async (name) => { const bytes = await fs.readFile(stateBlobPath(name)); ... },
setItem: async (name, value) => { await fs.writeFile(stateBlobPath(name), enc.encode(value)); },
removeItem: async (name) => { await fs.rm(stateBlobPath(name)); },
```

The flag-routing test confirms the resulting path is `state/workspace-zustand-v1.json` (`workspaceStore-corpus-flag.test.ts:50` reads `fs.readFile("state/workspace-zustand-v1.json")`). Fix claim holds; state routing goes through the single path module.

**Evidence:** `app/lib/corpus/paths.ts:63-70`, `app/lib/corpus/storeAdapter.ts:15,60-66`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:50`

---

## Claim 2: `resolveWorkspaceStorage(makeCorpusFs)` is parameterized with an injectable factory (fix R2)

**Location:** `app/lib/corpus/storeAdapter.ts:78-85`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The resolver takes a factory defaulting to the OPFS adapter, and invokes it only on the flag-ON branch:

```ts
// app/lib/corpus/storeAdapter.ts
export function resolveWorkspaceStorage(
  makeCorpusFs: () => CorpusFS = createOpfsCorpusFs,
): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(makeCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```

The docstring's claim that "the factory is only invoked on the flag-ON branch, so the default OFF path pays nothing" is verified: `makeCorpusFs()` is called inside the `if (isCorpusEnabled())` block only; the OFF branch returns `createDebouncedLocalStorage()` without touching the factory. Fix claim holds.

**Evidence:** `app/lib/corpus/storeAdapter.ts:78-85`

---

## Claim 3: in-memory fake copies on read (no read-aliasing), matching OPFS "fresh Uint8Array each read" (fix R3)

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:38-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The fake's `readFile` returns `bytes.slice()` (a copy), and the comment's cross-reference to OPFS semantics is accurate:

```ts
// inMemoryCorpusFs.ts readFile
// (OPFS returns a fresh `new Uint8Array(...)` each read; the fake must too — R3 read-aliasing).
return bytes ? bytes.slice() : null;
```

The OPFS adapter does return a fresh view each read:

```ts
// app/lib/corpus/opfsAdapter.ts readFile
return new Uint8Array(await file.arrayBuffer());
```

The contract case "read does not alias stored bytes" (`corpusFsContract.ts:105-110`) pins this axis. Alignment claim holds.

**Evidence:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:38-43`, `app/lib/corpus/opfsAdapter.ts:102`, `app/lib/corpus/__tests__/corpusFsContract.ts:105-110`

---

## Claim 4: in-memory fake copies on write (no write-aliasing) (fix R3)

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:45-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
// writeFile
// Copy so later mutation of the caller's array can't alter stored bytes.
files.set(normalize(path), bytes.slice());
```

The contract case "write does not alias the caller's array" (`corpusFsContract.ts:97-103`) fills `bytes` with zeros after the write and asserts the stored value is unchanged. Claim holds.

**Evidence:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:45-49`, `app/lib/corpus/__tests__/corpusFsContract.ts:97-103`

---

## Claim 5: fake rejects writing under a file-as-parent with a `CorpusError` (fix R3 — file-as-parent axis)

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:22-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`assertNoFileAncestor` walks each ancestor prefix and throws a typed `CorpusError` (kind `io`) if any ancestor path is an existing file:

```ts
for (let i = 1; i < parts.length; i++) {
  const ancestor = parts.slice(0, i).join("/");
  if (files.has(ancestor)) {
    throw new CorpusError({ kind: "io", path, reason: `parent path is a file: ${ancestor}` });
  }
}
```

`writeFile` calls it before storing. The third R3 contract case ("rejects writing under a file used as a parent with a CorpusError", `corpusFsContract.ts:112-119`) asserts `rejects.toBeInstanceOf(CorpusError)`. The comment claims OPFS raises `TypeMismatchError` wrapped to kind `io`; the adapter's `isNotFound` treats `TypeMismatchError` as not-found (returns `null`/`[]`) rather than an `io` error on read paths, but on the write path a file-as-parent surfaces via `walkDir(create:true)` → `getDirectoryHandle` throwing `TypeMismatchError`, which is re-thrown and caught by `wrap()` → kind `io`. So the fake's kind `io` matches the adapter's write-path mapping. Three new R3 cases present and correct.

**Evidence:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:22-31,45-46`, `app/lib/corpus/__tests__/corpusFsContract.ts:112-119`, `app/lib/corpus/opfsAdapter.ts:80-84`

---

## Claim 6: documented out-of-CI jsdom/Playwright OPFS smoke exists (fix R3)

**Location:** `app/lib/corpus/__tests__/corpusFsContract.ts:16`, `docs/spikes/corpus-opfs-smoke.md`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The contract file references `docs/spikes/corpus-opfs-smoke.md`; the file exists and documents the 6-behavior manual Playwright smoke against real OPFS (Chromium + Firefox), status "manual, pre-merge before the corpus flag is ever defaulted on." The referenced target resolves.

**Evidence:** `app/lib/corpus/__tests__/corpusFsContract.ts:16`, `app/lib/corpus/__tests__/corpusFs.contract.test.ts:2-3`, `docs/spikes/corpus-opfs-smoke.md:1-32`

---

## Claim 7: OPFS `writeFile` makes no defensive copy; caller array is safe to mutate after return (fix R4 — corrected "fresh ArrayBuffer view" comment)

**Location:** `app/lib/corpus/opfsAdapter.ts:114-122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium

The corrected comment now describes the write path accurately — the array is passed through unchanged, not copied:

```ts
// `write` copies `bytes` into the file before it resolves, so the
// caller's array is safe to mutate once `writeFile` returns — no
// defensive copy is made here (the array is passed through unchanged).
await w.write(bytes);
```

The code assertion "no defensive copy is made here / passed through unchanged" is directly verifiable: `w.write(bytes)` receives the caller's array with no intervening `.slice()`. The claim that OPFS `write` copies bytes before resolving is a Web-platform spec property (FileSystemWritableFileStream), not statically checkable from this repo — hence Medium confidence on that sub-clause. The prior erroneous "fresh ArrayBuffer view" framing is gone. Fix claim holds.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:114-122`

---

## Claim 8: no stale `layout.ts` references remain in the corpus module (fix — stale-ref narrowing)

**Location:** `app/lib/corpus/paths.ts` (module header), `CLAUDE.md` corpus section
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High

A grep for `layout.ts`/`layout(` across `app/lib/corpus/` returns zero hits (paraphrased — no quote available because the claim covers absence of code: no matching grep results). The file is `paths.ts`; `CLAUDE.md` explicitly notes "`paths.ts` — **not** `layout.ts`, which is a reserved Next.js filename." The rename (commit 122d70f) is fully reflected; no dangling `layout.ts` reference.

**Evidence:** `app/lib/corpus/paths.ts:1-20` (header refers only to DD-009 layout, not a `layout.ts` symbol); grep of `app/lib/corpus/` for `layout.ts` — 0 hits

---

## Claim 9: the debounced localStorage adapter was moved out of `workspaceStore.ts` and the store now delegates to `resolveWorkspaceStorage` (fix — stale workspaceStore ref)

**Location:** `app/lib/stores/workspaceStore.ts:25,496-499`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The in-file `createDebouncedStorage` function was deleted from `workspaceStore.ts` (diff removes lines 25-56 of the old file) and replaced with an import plus a persist-config wiring:

```ts
import { resolveWorkspaceStorage } from "@/app/lib/corpus/storeAdapter";
...
storage: createJSONStorage(resolveWorkspaceStorage),
```

`git grep createDebouncedStorage` finds it only in the unrelated `evidenceStore.ts` (a separate store) — not in `workspaceStore.ts`. The moved copy lives in `storeAdapter.ts:26` as `createDebouncedLocalStorage`. No stale in-store definition remains.

**Evidence:** `app/lib/stores/workspaceStore.ts:25,496-499`, `app/lib/corpus/storeAdapter.ts:26`

---

## Claim 10: manifest parse is FAIL-LOUD at the structural level (S0/S1 standing; docstring narrowed)

**Location:** `app/lib/corpus/manifest.ts:35-49,82-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The narrowed docstring distinguishes structural fail-loud from within-array leniency, and the implementation matches both halves. Structural failures throw:

```ts
if (bytes === null) fail("manifest file is absent");
... catch (e) { fail(`not valid JSON (${(e as Error).message})`); }
if (!isObject(raw)) fail("top-level value is not an object");
if (typeof raw.title !== "string") fail("missing required field: title");
if (typeof raw.manifestVersion !== "number") fail("missing required field: manifestVersion");
```

Within a well-formed array, leniency matches the docstring: `raw.sources.filter(isObject).map(...)` drops non-object entries, `label` defaults to `id` (`typeof s.label === "string" ? s.label : s.id`), and missing `createdAt`/`updatedAt` are fabricated as `new Date().toISOString()`. Tests `manifest.test.ts:23-51` confirm: non-JSON, `{}`, `null`, and a malformed source entry all throw `CorpusError`. Docstring accurately describes behavior.

**Evidence:** `app/lib/corpus/manifest.ts:35-49,82-124`, `app/lib/corpus/__tests__/manifest.test.ts:23-51`

---

## Claim 11: `fail()` throws `CorpusError` with kind `io` (manifest error kinds — S0)

**Location:** `app/lib/corpus/manifest.ts:33-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
function fail(reason: string): never {
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
}
```

Test `manifest.test.ts:34` asserts `(caught as CorpusError).detail.kind === "io"` on the `{}` (missing-fields) case. Matches.

**Evidence:** `app/lib/corpus/manifest.ts:33-36`, `app/lib/corpus/__tests__/manifest.test.ts:34`

---

## Claim 12: manifest codec has no silent default-empty path (S0 standing)

**Location:** `app/lib/corpus/manifest.ts:82-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The docstring claims parsing never returns "a silent default-empty manifest masquerading as 'this workspace has no work in it'." Every early exit is a `fail(...)` throw; `parseManifest` has no branch returning `createManifest(...)` or an empty object on bad input (paraphrased — no quote available because the claim covers absence of a code path: no `return createManifest`/empty-object fallback exists in `parseManifest`). The only construction of empty arrays is inside the success return when the input arrays were themselves valid-but-empty. Claim holds.

**Evidence:** `app/lib/corpus/manifest.ts:82-124`

---

## Claim 13: `flag.ts` is DEFAULT-OFF (S0/S1 standing)

**Location:** `app/lib/corpus/flag.ts:15-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`isCorpusEnabled()` returns `true` only if the env var equals `"1"` or the localStorage key equals `"1"`; the final statement is `return false`:

```ts
export function isCorpusEnabled(): boolean {
  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
  if (typeof window !== "undefined") {
    try { return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1"; } catch { return false; }
  }
  return false;
}
```

With no env var and no localStorage key set, the function returns `false`. Test `workspaceStore-corpus-flag.test.ts:16-27` confirms the default resolver routes to localStorage and never calls `getDirectory`. Default-off holds.

**Evidence:** `app/lib/corpus/flag.ts:15-25`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:16-27`

---

## Claim 14: `NEXT_PUBLIC_CORPUS_FS` is build-time-inlined (flag.ts — S1 standing)

**Location:** `app/lib/corpus/flag.ts:8-9,17`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium

The comment says enable "via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1`". The code reads `process.env.NEXT_PUBLIC_CORPUS_FS`. In Next.js, any `NEXT_PUBLIC_`-prefixed env var referenced as a static `process.env.X` access is statically replaced (inlined) at build time — the code uses exactly that static access pattern, so the "build-time" characterization is correct. Medium confidence because the inlining behavior is a Next.js/webpack framework property, not verifiable from this repo's source alone; the access pattern in code is consistent with it.

**Evidence:** `app/lib/corpus/flag.ts:8-9,17`

---

## Claim 15: flag is "DEV-ONLY" and starts from an EMPTY corpus with no migration (flag.ts — S1 standing)

**Location:** `app/lib/corpus/flag.ts:2-6`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The "no localStorage→corpus migration in S1" sub-claim is verifiable and correct: `createCorpusBackedStorage` reads/writes only via `stateBlobPath` and never reads the existing `localStorage` `workspace-zustand-v1` key, so enabling the flag starts from an empty corpus (paraphrased — no quote available because the claim is about absence of a migration path: `storeAdapter.ts` contains no read of the prior localStorage key when the corpus branch is taken). The "DEV-ONLY" label, however, is an intent/documentation assertion — nothing in `flag.ts` restricts activation to development builds; `NEXT_PUBLIC_CORPUS_FS=1` in a production build would enable it. The comment itself acknowledges this ("it must not be turned on for end users until S4 ships migration"), so it reads as a documented constraint, not a code-enforced one. Directionally accurate; "dev-only" is a convention, not an enforced invariant.

**Evidence:** `app/lib/corpus/flag.ts:2-6`, `app/lib/corpus/storeAdapter.ts:55-66`

---

## Claim 16: `paths.ts` is the single source of corpus paths, with `workspaceSlug` as the traversal choke point (S0 standing)

**Location:** `app/lib/corpus/paths.ts:19-24,38-44`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

Every builder in `paths.ts` routes user-controlled segments through `workspaceSlug`/`safeSegment`, both of which apply `SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g` and throw on an empty result:

```ts
export function workspaceSlug(title: string): string {
  const slug = title.normalize("NFKD").replace(SAFE_SEGMENT, "-")...toLowerCase();
  if (!slug) { throw new Error(`workspace title produced an empty slug: ...`); }
  return slug;
}
```

`workspaceDir` calls `workspaceSlug(slug)`, and every other path builder composes on `workspaceDir` or `safeSegment`. `storeAdapter.ts` uses `stateBlobPath` rather than concatenating (Claim 1). Tests `paths.test.ts:14-40` confirm `../etc/passwd` cannot retain `..` or `/`, and all-unsafe titles throw. The "single source / choke point" claim holds for the code in this diff.

**Evidence:** `app/lib/corpus/paths.ts:19-24,32-54`, `app/lib/corpus/__tests__/paths.test.ts:14-40`

---

## Claim 17: `CorpusErrorKind` is the single source for the failure-kind set; each kind is producible (types.ts — S0 standing)

**Location:** `app/lib/corpus/types.ts:41-49,78-90`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High

`CorpusErrorKind` is a discriminated union of 8 kinds and `describeCorpusError` has an exhaustive `switch` with an `assertNever(d)` default, so the "one source of truth / exhaustive switch" claim is verified structurally. However, "adding a kind here forces every consumer to handle it at compile time" is only partly realized in S1: only three kinds — `io`, `unavailable`, `quota-exceeded` — are actually constructed anywhere in the corpus code (grep of `app/lib/corpus/*.ts` non-test). `not-found`, `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, and `git-conflict` are declared but never thrown in this diff. Notably `not-found` is by-design never thrown because the `CorpusFS` interface returns `null` for absence (`types.ts:88` "'Not found' is `null` from `readFile`/`stat`"). So the union is correctly the single declaration point, but "producible" is aspirational for 5 of 8 kinds in S1 — they are reserved for S2/S3. Not incorrect (the docstring frames them as the complete future set), but the compile-time-forcing benefit only bites where an exhaustive switch exists (`describeCorpusError`), not at construction sites.

**Evidence:** `app/lib/corpus/types.ts:41-49,60-71,78-90`; grep of `app/lib/corpus/*.ts` for `kind: "` (non-test) yields only `io`, `unavailable`, `quota-exceeded`

---

## Claim 18: `workspaceStore` seam is typed as `CorpusFS` so the S3 worker proxy is a drop-in (S1 standing)

**Location:** `app/lib/corpus/storeAdapter.ts:52-53,78-80`, `app/lib/stores/workspaceStore.ts:496-499`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`createCorpusBackedStorage(fs: CorpusFS)` and `resolveWorkspaceStorage(makeCorpusFs: () => CorpusFS)` both bind to the `CorpusFS` interface, not the concrete `createOpfsCorpusFs`. The store's persist config passes `resolveWorkspaceStorage` (the factory) into `createJSONStorage`, so the store never names a concrete adapter. The seam-is-CorpusFS claim holds.

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-53,78-80`, `app/lib/stores/workspaceStore.ts:496-499`

---

## Claim 19: OPFS adapter maps failures to typed `CorpusError` (unavailable / quota / io) (opfsAdapter — S1 standing)

**Location:** `app/lib/corpus/opfsAdapter.ts:52-55,79-84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`getRoot` throws `{kind:"unavailable"}` when `navigator.storage.getDirectory` is absent; `wrap` re-throws existing `CorpusError`s, maps `QuotaExceededError`/`QUOTA_EXCEEDED_ERR` to `{kind:"quota-exceeded", substrate:"opfs"}`, and everything else to `{kind:"io"}`:

```ts
function wrap(path: string, e: unknown): never {
  if (e instanceof CorpusError) throw e;
  if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
  throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });
}
```

Every public method wraps its body in `try { ... } catch (e) { wrap(path, e); }`. Tests `opfsAdapter.test.ts:25-64` confirm unavailable-for-every-method and quota reification with `substrate: "opfs"`. Error-mapping claim holds.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:52-55,79-84,88-95`, `app/lib/corpus/__tests__/opfsAdapter.test.ts:25-64`

---

## Claim 20: quota failure is "NOT swallowed with console.warn the way the legacy localStorage adapter does (createDebouncedLocalStorage in storeAdapter.ts:35)" (opfsAdapter header)

**Location:** `app/lib/corpus/opfsAdapter.ts:12-15`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High

The substantive claim — the OPFS adapter reifies quota failures (Claim 19) whereas `createDebouncedLocalStorage` swallows them with `console.warn` — is correct: `storeAdapter.ts:36` is `console.warn("Failed to persist workspace (localStorage quota exceeded):", e);` inside a `catch`, with no re-throw. But the inline line locator is off by one: the `console.warn` sits at `storeAdapter.ts:36` and the function `createDebouncedLocalStorage` is defined at `storeAdapter.ts:26`; line 35 is the `} catch (e) {`. The reference "storeAdapter.ts:35" points one line above the actual `console.warn`. Behavior claim verified; the cited line number should be `:36` (or the range `:26`/`:36`).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:12-15`, `app/lib/corpus/storeAdapter.ts:26,33-37`

---

## Claims Requiring Attention

### Incorrect
- *(none)*

### Stale
- *(none)*

### Mostly Accurate
- **Claim 15** (`app/lib/corpus/flag.ts:2-6`): "DEV-ONLY" is a documented convention, not a code-enforced restriction — `NEXT_PUBLIC_CORPUS_FS=1` in a production build would enable the flag. The "empty corpus / no migration" half is accurate. Comment-only.
- **Claim 17** (`app/lib/corpus/types.ts:41-49`): union is correctly the single kind-declaration point, but 5 of 8 kinds (`not-found`, `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, `git-conflict`) are declared-but-never-produced in S1; `not-found` is by-design unthrown (interface returns `null`). Comment-only (reserved for S2/S3).
- **Claim 20** (`app/lib/corpus/opfsAdapter.ts:12-15`): line locator off by one — `console.warn` is at `storeAdapter.ts:36`, not `:35`; the swallow-vs-reify behavior claim is correct. Comment-only.

### Unverifiable
- *(none)*

---

## Goal-Alignment Note

This pass verified the five pass-1 fix claims (R1–R4 plus the stale-ref / manifest-docstring narrowings) and re-checked the standing S0/S1 claims requested in the brief. All four fixes (R1 state-blob routing through `paths.ts`, R2 `resolveWorkspaceStorage` factory parameterization, R3 in-memory-fake OPFS alignment + 3 new contract cases + documented smoke, R4 corrected write-copy comment) are correctly implemented and land as claimed. The stale `layout.ts`/in-store `createDebouncedStorage` references are gone, and the manifest fail-loud docstring accurately describes the structural-strict / within-array-lenient split. No Incorrect verdicts and no fabrication-class findings (no hallucination-pattern log entry warranted). The three Mostly-accurate items are all comment-only imprecisions — an aspirational "dev-only" label, kinds reserved for future sub-tasks, and a one-line-off reference — none of which reflect wrong code. Scope held to ancestors of 409e9dc, `app/` only; no worktree writes.
