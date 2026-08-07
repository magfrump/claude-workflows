# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree wt-corpus-arm, branch e3/corpus-arm)
**Scope:** `git diff dc6dfb0..HEAD -- app/` (full scope; corpus S0/S1 + pass-1 fix 409e9dc)
**Checked:** 2026-08-06
**Commit:** 409e9dc
**Total claims checked:** 14
**Summary:** 8 verified, 4 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

No `docs/reviews/hallucination-patterns.md` exists; none created (no fabrication-class Incorrect found).

---

## Claim 1: "DEFAULT OFF and DEV-ONLY ... Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`"

**Location:** `app/lib/corpus/flag.ts:2-11`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

The checkable parts hold. Default-off: the function returns `false` unless one of two opt-ins is present, and the SSR/no-window path also returns `false`:

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

Both enable mechanisms match: `process.env.NEXT_PUBLIC_CORPUS_FS === "1"` (build-time, Next inlines `NEXT_PUBLIC_*`) and the localStorage key. The key string matches the documented value: `export const CORPUS_FLAG_KEY = "corpus-fs-enabled";` (`app/lib/corpus/flag.ts:13`).

Caveat on "DEV-ONLY": nothing in the code restricts the flag to non-production environments — the env check has no `NODE_ENV` guard. "DEV-ONLY" and "must not be turned on for end users" are policy/intent statements (excluded from fact-check per the intent-comment rule), not code-enforced invariants; the code would honor the flag in production too.

**Evidence:** `app/lib/corpus/flag.ts:13-25`

---

## Claim 2: "WITHIN a well-formed array the codec is deliberately LENIENT, not fail-loud" (A3 narrowed docstring)

**Location:** `app/lib/corpus/manifest.ts:16-21`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The enumerated lenient behaviors are all real: non-object entries are dropped via `.filter(isObject)`, `label` defaults to `id`, non-string `customTypeIds` are filtered, and timestamps are fabricated:

```ts
// app/lib/corpus/manifest.ts:95-97
? raw.sources.filter(isObject).map((s) => {
    if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");
    return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
```
```ts
// app/lib/corpus/manifest.ts:110-112,117-118
? raw.customTypeIds.filter((x): x is string => typeof x === "string")
...
createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : new Date().toISOString(),
```

The imprecision: the blanket framing "WITHIN a well-formed array the codec is deliberately LENIENT, not fail-loud" overstates. An *object* entry that is present but missing required fields still fails the whole parse — `if (typeof s.id !== "string" || typeof s.ext !== "string") fail(...)` (`manifest.ts:96`) and `if (typeof a.type !== "string" || typeof a.currentVersion !== "number") { fail(...) }` (`manifest.ts:103-104`). So leniency applies specifically to *non-object* entries (dropped) and to optional fields (defaulted); malformed *object* entries are still fail-loud. The tightened version would say "non-object entries are dropped and optional fields defaulted, but an object entry missing a required field still fails loud."

**Evidence:** `app/lib/corpus/manifest.ts:94-118`

---

## Claim 3: "This matches the app's existing `coerceArtifactVersion` convention"

**Location:** `app/lib/corpus/manifest.ts:19-21`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

`coerceArtifactVersion` exists and follows the same drop-invalid / default-optional convention the manifest docstring points to:

```ts
// app/lib/stores/workspaceStore.ts:39-50
function coerceArtifactVersion(raw: unknown): ArtifactVersion | null {
  if (!isObject(raw)) return null;
  if (typeof raw.content !== "string") return null;
  ...
  createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
```

It returns `null` for structurally-bad entries (which callers `.filter` out) and defaults missing optional fields — matching the manifest's within-array leniency.

**Evidence:** `app/lib/stores/workspaceStore.ts:39-65`, `app/lib/stores/workspaceStore.ts:55-57`

---

## Claim 4: "SSR/unavailable guard ... rejects with a typed `CorpusError` ({kind:"unavailable"}), never a raw `TypeError`" and "a quota failure rejects with {kind:"quota-exceeded", substrate:"opfs"} — it is NOT swallowed with console.warn"

**Location:** `app/lib/corpus/opfsAdapter.ts:9-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Both guards are implemented. `getRoot()` throws a typed `unavailable` error before any raw `TypeError` can arise from touching `navigator.storage`:

```ts
// app/lib/corpus/opfsAdapter.ts:51-54
const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
if (!storage || typeof storage.getDirectory !== "function") {
  throw new CorpusError({ kind: "unavailable", reason: "navigator.storage.getDirectory is not available (SSR or unsupported browser)" });
}
```

Quota reification: every adapter method routes errors through `wrap`, which maps a quota `DOMException` to the typed kind and re-throws (no swallow):

```ts
// app/lib/corpus/opfsAdapter.ts:80-83
function wrap(path: string, e: unknown): never {
  if (e instanceof CorpusError) throw e;
  if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
  throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });
}
```

`isQuota` matches both `QuotaExceededError` and legacy `QUOTA_EXCEEDED_ERR` (`opfsAdapter.ts:46-48`). The contrast with the localStorage swallow is genuine — see Claim 5 for the accuracy of that cross-reference.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:46-56`, `app/lib/corpus/opfsAdapter.ts:80-84`

---

## Claim 5: "createDebouncedLocalStorage in storeAdapter.ts:35" (A17 cross-reference)

**Location:** `app/lib/corpus/opfsAdapter.ts:13-15`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High

The symbol is correct — `createDebouncedLocalStorage` exists in `storeAdapter.ts` and does swallow a quota failure with `console.warn`. But the line number is imprecise. The function is *declared* at line 26, and the `console.warn` swallow the sentence describes is at line 36; line 35 is the `} catch (e) {`:

```ts
// app/lib/corpus/storeAdapter.ts:26,33-37
export function createDebouncedLocalStorage(): StateStorage {
...
        try {
          localStorage.setItem(name, value);
        } catch (e) {
          console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
        }
```

`:35` lands on the catch clause (adjacent to the swallow) rather than the function declaration (`:26`) or the `console.warn` line (`:36`). Directionally correct, off by one from the behavior it names. (This is an improvement over the pre-fix `workspaceStore.ts:44-46` reference, which pointed at a different file entirely.)

**Evidence:** `app/lib/corpus/storeAdapter.ts:26`, `app/lib/corpus/storeAdapter.ts:33-37`

---

## Claim 6: "`write` copies `bytes` into the file before it resolves, so the caller's array is safe to mutate once `writeFile` returns — no defensive copy is made here (the array is passed through unchanged)" (R4 corrected comment)

**Location:** `app/lib/corpus/opfsAdapter.ts:116-121`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium

The code-level half is verified: no defensive copy is made in the adapter — `bytes` is passed to `write` unchanged:

```ts
// app/lib/corpus/opfsAdapter.ts:113-125
const fh = await dir!.getFileHandle(name, { create: true });
const w = await fh.createWritable();
try {
  await w.write(bytes);
} finally {
  await w.close();
}
```

The safety half — that `FileSystemWritableFileStream.write` copies the buffer before resolving, making post-return mutation safe — is a claim about OPFS/browser runtime semantics that cannot be confirmed by static analysis in this repo: jsdom has no OPFS, so the adapter's success path never executes in the Vitest suite. The corresponding contract case (`corpusFsContract.ts:94-100`, "write does not alias") runs only against the in-memory fake (which slices) in CI; the OPFS side is asserted only by the out-of-CI Playwright smoke. So this is a correct-per-web-spec but statically-unverifiable claim. The old "fresh ArrayBuffer view" wording is gone; the new wording no longer contradicts the code. The S3 SharedArrayBuffer note (`opfsAdapter.ts:119-121`) is forward-looking rationale (not checked).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:108-129`, `app/lib/corpus/__tests__/corpusFsContract.ts:94-100`

---

## Claim 7: "state/<name>.json ... see storeAdapter.ts" layout diagram entry + "The only source of corpus paths is this module — callers must never hand-concatenate" (R1)

**Location:** `app/lib/corpus/paths.ts:8-10`, `app/lib/corpus/paths.ts:18-22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The layout diagram now documents the `state/` directory (previously undocumented per pass-1 R1):

```
// app/lib/corpus/paths.ts:8-10
*   ├── state/<name>.json            (S1 blob-mode zustand persist blob, one per
*   │                                 persist key; see storeAdapter.ts. Retired
*   │                                 once S4 writes the folder layout directly.)
```

The single-source claim holds for the corpus module: `storeAdapter.ts` no longer hand-builds `state/${name}.json` — it imports and calls the builder. `import { stateBlobPath } from "./paths";` (`storeAdapter.ts:18`), used at `storeAdapter.ts:58,62,65`. No remaining hand-concatenation of corpus paths exists in the corpus consumers.

**Evidence:** `app/lib/corpus/paths.ts:4-22`, `app/lib/corpus/storeAdapter.ts:18`, `app/lib/corpus/storeAdapter.ts:57-66`

---

## Claim 8: "Routed through here rather than hand-concatenated in `storeAdapter.ts` so this module stays the single source of corpus paths (and the traversal guard applies)"

**Location:** `app/lib/corpus/paths.ts:78-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`stateBlobPath` routes through `safeSegment`, which is the traversal guard (strips `/`, `\`, dot-runs, control chars to hyphens):

```ts
// app/lib/corpus/paths.ts:76-83
export const STATE_DIR = "state";
export function stateBlobPath(name: string): string {
  return `${STATE_DIR}/${safeSegment(name)}.json`;
}
```
```ts
// app/lib/corpus/paths.ts:55-61
export function safeSegment(id: string): string {
  const seg = id.normalize("NFKD").replace(SAFE_SEGMENT, "-")...
  if (!seg) { throw new Error(...); }
  return seg;
}
```

`SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g` (`paths.ts:31`) collapses any separator/dot to a hyphen, so a `name` cannot escape `state/`. The "traversal guard applies" claim is accurate. (Note: the sole caller passes the fixed key `"workspace-zustand-v1"`, which is already safe, so the guard is defense-in-depth rather than currently load-bearing — but the claim is about the builder, and it is true.)

**Evidence:** `app/lib/corpus/paths.ts:28-31`, `app/lib/corpus/paths.ts:55-83`

---

## Claim 9: "The CorpusFS is injected via `makeCorpusFs` (default: the OPFS adapter) ... The factory is only invoked on the flag-ON branch, so the default OFF path pays nothing" (R2)

**Location:** `app/lib/corpus/storeAdapter.ts:70-78`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High

`resolveWorkspaceStorage` is parameterized with a defaulted factory, and the factory is only called inside the flag-ON branch:

```ts
// app/lib/corpus/storeAdapter.ts:79-86
export function resolveWorkspaceStorage(
  makeCorpusFs: () => CorpusFS = createOpfsCorpusFs,
): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(makeCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```

Default is `createOpfsCorpusFs`; `makeCorpusFs()` is invoked only after `isCorpusEnabled()` is true. The OFF branch returns `createDebouncedLocalStorage()` without touching the factory — "the default OFF path pays nothing" is accurate.

**Evidence:** `app/lib/corpus/storeAdapter.ts:79-86`, `app/lib/corpus/flag.ts:15-25`

---

## Claim 10: "Reads are synchronous (instant); writes are debounced by 300ms"

**Location:** `app/lib/corpus/storeAdapter.ts:22-24`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

`getItem` is a synchronous `localStorage.getItem`; `setItem` wraps the write in a `setTimeout(..., 300)`:

```ts
// app/lib/corpus/storeAdapter.ts:29-39
getItem: (name) => localStorage.getItem(name),
setItem: (name, value) => {
  if (pending) clearTimeout(pending);
  pending = setTimeout(() => {
    try {
      localStorage.setItem(name, value);
    } catch (e) { ... }
    pending = null;
  }, 300);
},
```

The 300ms debounce interval matches exactly.

**Evidence:** `app/lib/corpus/storeAdapter.ts:26-47`

---

## Claim 11: "The complete set of corpus failure kinds. Every exhaustive `switch` over a corpus error binds to this union; adding a kind here forces every consumer to handle it at compile time"

**Location:** `app/lib/corpus/types.ts:36-49`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The exhaustiveness mechanism is real: `describeCorpusError` switches over all eight kinds and ends in `assertNever(d)`, a compile-time guard (`types.ts:78-96`). Adding a kind without updating the switch is a TS error. That part is verified.

The imprecision is in "the complete set of corpus failure kinds" read as *producible* kinds. Only three of the eight are ever constructed in S1 code — `io`, `unavailable`, `quota-exceeded`:

```
app/lib/corpus/manifest.ts:74      kind: "io"
app/lib/corpus/opfsAdapter.ts:53   kind: "unavailable"
app/lib/corpus/opfsAdapter.ts:61   kind: "io"
app/lib/corpus/opfsAdapter.ts:82   kind: "quota-exceeded"
app/lib/corpus/opfsAdapter.ts:83   kind: "io"
```

The remaining five — `not-found`, `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, `git-conflict` — are declared but never produced anywhere in `app/` (grep for each returns only the type declaration and the `describeCorpusError` case; paraphrased — no quote available because the claim is about *absence* of construction sites, confirmed by `rg` returning zero non-`types.ts` matches). This is consistent with the file's own forward-looking notes (the `CorpusSubstrate` comment names `fsa`/`remote` for S2, and `git-conflict` is an S3 kind), so the union is correctly a superset for future sub-tasks — but a reader taking "complete set of corpus failure kinds" to mean kinds the current code can emit would be over-counting by five.

**Evidence:** `app/lib/corpus/types.ts:41-49`, `app/lib/corpus/types.ts:78-96`; grep of `app/lib/corpus` for each kind construction

---

## Claim 12: "Coverage is deliberately NOT one-sided (R3) ... The fake was aligned to the OPFS adapter's semantics (copy-on-read; reject a file used as a parent) ... The OPFS adapter itself still cannot execute under jsdom; it is exercised ... by the documented out-of-CI Playwright smoke (docs/spikes/corpus-opfs-smoke.md)"

**Location:** `app/lib/corpus/__tests__/corpusFsContract.ts:10-16`
**Type:** Architectural / Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The three named axes have dedicated contract cases: write-aliasing (`corpusFsContract.ts:94-100`), read-aliasing (`:102-108`), and file-as-parent (`:110-117`). The contract runs against the fake in CI: `defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());` (`corpusFs.contract.test.ts:8`). The referenced smoke doc exists at `docs/spikes/corpus-opfs-smoke.md` (confirmed present). The "cannot execute under jsdom" statement is consistent with the adapter needing `navigator.storage.getDirectory`, which jsdom lacks.

Accurate caveat inherent in the claim itself: it explicitly concedes the OPFS adapter is not run in CI, so a green CI run only *predicts* OPFS behavior via the aligned fake — the report does not overstate CI coverage.

**Evidence:** `app/lib/corpus/__tests__/corpusFsContract.ts:92-117`, `app/lib/corpus/__tests__/corpusFs.contract.test.ts:5-8`, `docs/spikes/corpus-opfs-smoke.md`

---

## Claim 13: "Reject writing under a path whose ancestor is an existing file. OPFS raises a TypeMismatchError that the adapter wraps to a `CorpusError` (kind "io"); the fake must diverge the same way" + copy-on-read/write comments

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:18-31`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:39-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The fake rejects a file-ancestor path with `CorpusError` kind `io`:

```ts
// app/lib/corpus/__tests__/inMemoryCorpusFs.ts:23-31
function assertNoFileAncestor(files, path): void {
  const parts = normalize(path).split("/").filter(Boolean);
  for (let i = 1; i < parts.length; i++) {
    const ancestor = parts.slice(0, i).join("/");
    if (files.has(ancestor)) {
      throw new CorpusError({ kind: "io", path, reason: `parent path is a file: ${ancestor}` });
    }
  }
}
```

The claim about OPFS behavior is corroborated by tracing the adapter: on `writeFile("parent.txt/child.txt", …)`, `walkDir(root, ["parent.txt"], create=true)` calls `getDirectoryHandle("parent.txt", {create:true})`; on an existing file this throws `TypeMismatchError`, and because `create` is true the `if (!create && isNotFound(e)) return null` guard does not apply, so it rethrows into `wrap`, which produces `kind:"io"` (`opfsAdapter.ts:67-84`). Copy-on-read (`bytes.slice()`, `inMemoryCorpusFs.ts:42`) mirrors the OPFS `new Uint8Array(await file.arrayBuffer())` fresh-array read (`opfsAdapter.ts:102`); copy-on-write (`bytes.slice()`, `inMemoryCorpusFs.ts:48`) makes the fake's write-aliasing behavior match. All three alignments are as described.

**Evidence:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:23-48`, `app/lib/corpus/opfsAdapter.ts:67-84`, `app/lib/corpus/opfsAdapter.ts:102`

---

## Claim 14: "Storage seam is selected here (DD-009 S1) ... The seam is typed as CorpusFS so the S3 worker-proxy is a drop-in"

**Location:** `app/lib/stores/workspaceStore.ts:496-499`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The persist middleware selects storage via `resolveWorkspaceStorage`, which returns localStorage by default or the CorpusFS-backed adapter when the flag is on:

```ts
// app/lib/stores/workspaceStore.ts:499
storage: createJSONStorage(resolveWorkspaceStorage),
```

The injection type is `CorpusFS`, not a concrete adapter: `resolveWorkspaceStorage(makeCorpusFs: () => CorpusFS = ...)` (`storeAdapter.ts:79-80`) and `createCorpusBackedStorage(fs: CorpusFS)` (`storeAdapter.ts:53`). The "typed as CorpusFS so the S3 worker-proxy is a drop-in" claim matches the interface-not-adapter binding.

**Evidence:** `app/lib/stores/workspaceStore.ts:494-499`, `app/lib/corpus/storeAdapter.ts:53`, `app/lib/corpus/storeAdapter.ts:79-86`

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 2** (`app/lib/corpus/manifest.ts:16-21`): "within a well-formed array ... not fail-loud" overstates — object entries missing required `id`/`ext` (or `type`/`currentVersion`) still fail the whole parse (`manifest.ts:96,103-104`); leniency is scoped to non-object entries + optional fields. Comment-only tightening.
- **Claim 5** (`app/lib/corpus/opfsAdapter.ts:13-15`): the `createDebouncedLocalStorage in storeAdapter.ts:35` reference is off — the function is declared at `storeAdapter.ts:26` and the `console.warn` swallow it describes is at `:36`; `:35` is the catch clause. Comment-only.
- **Claim 11** (`app/lib/corpus/types.ts:36-49`): "complete set of corpus failure kinds" is accurate for the exhaustive-switch mechanism but only 3 of 8 kinds (`io`, `unavailable`, `quota-exceeded`) are producible in S1; the other 5 are forward-declared for S2/S3. Comment-only (intentional superset).

### Unverifiable
- **Claim 6** (`app/lib/corpus/opfsAdapter.ts:116-121`): the "write copies bytes before resolving, post-return mutation safe" claim depends on OPFS/browser `FileSystemWritableFileStream.write` semantics that cannot execute under jsdom; the CI contract case runs only against the copying fake, and the OPFS side is asserted only by the out-of-CI Playwright smoke. The code-level half ("no defensive copy; passed through unchanged") is verified.

---

## Goal-Alignment Note

This is the FULL-scope pass-2 baseline for the corpus arm (against which carry-forward will be compared). All five pass-1 fix claims (R1-R4) and both comment ambers (A17, A3) were re-verified against the code at 409e9dc:

- **R1** (state blob through paths.ts) — Verified (Claims 7, 8).
- **R2** (`makeCorpusFs` seam, flag-ON only) — Verified (Claim 9).
- **R3** (fake aligned to OPFS + 3 contract cases + jsdom-smoke documented) — Verified (Claims 12, 13).
- **R4** (corrected "fresh ArrayBuffer view" comment) — the contradiction is gone; the new wording's runtime-safety half is Unverifiable by static analysis but no longer contradicts the code (Claim 6).
- **A17** (layout.ts→paths.ts docstring; workspaceStore ref→createDebouncedLocalStorage) — the file/symbol corrections are right; the embedded line number `:35` is imprecise (Claim 5).
- **A3** (narrowed FAIL-LOUD docstring) — improved but the blanket "not fail-loud within a well-formed array" still overstates (Claim 2).

No Incorrect verdicts and no fabricated symbols/APIs — the fix did not introduce documentation that contradicts code. The three Mostly-accurate findings are all **comment-only** (no code is wrong); the one Unverifiable finding is a static-analysis limitation (jsdom has no OPFS), not a defect. Standing S0/S1 claims (flag default-off + NEXT_PUBLIC, manifest codec kinds, paths single-source, error-kind producibility, workspaceStore seam, opfsAdapter error mapping) were all checked and hold, with the producibility nuance noted in Claim 11.
