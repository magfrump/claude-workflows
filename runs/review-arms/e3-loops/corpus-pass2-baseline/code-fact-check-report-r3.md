# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/e3-loops/wt-corpus-arm (branch e3/corpus-arm)
**Scope:** `git diff dc6dfb0..HEAD -- app/` (HEAD = 409e9dc); FULL scope; ancestors of 409e9dc only
**Commit:** 409e9dc
**Checked:** 2026-08-06
**Total claims checked:** 24
**Summary:** 18 verified, 5 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

This is the pass-2 (post-fix) fact-check, replicate 3. The pass-1 fix commit 409e9dc claims to
close review findings R1-R4 plus comment ambers. Each fix claim is verified below, and standing
S0/S1 claims are re-checked. Pass-1 artifacts at `/workspace/runs/review-arms/e1/corpus-dirty/`
were treated as advisory only. No `docs/reviews/hallucination-patterns.md` exists in this worktree
(checked); no prior-pattern comparisons were possible and none are logged.

---

## Claim 1: "DEFAULT OFF and DEV-ONLY" (corpus feature flag)

**Location:** `app/lib/corpus/flag.ts:5`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

Default-OFF is verified: `isCorpusEnabled()` returns `false` unless an env var or localStorage key
is explicitly set to `"1"`:

```ts
// app/lib/corpus/flag.ts:15-24
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

"DEV-ONLY" is **not enforced in code** — there is no `NODE_ENV`/production guard (paraphrased — no
quote available because the claim covers the absence of a guard; `grep -n "NODE_ENV|development"
app/lib/corpus/flag.ts` returns only the `NEXT_PUBLIC_CORPUS_FS` line, no dev-mode check). The flag
will activate in any environment if the env var or localStorage key is set. "DEV-ONLY" is therefore
a usage policy/intent, not a behavioral guarantee. Comment-only imprecision (the code behaves as a
plain flag; nothing enforces dev-only). This wording also matches the CLAUDE.md statement
"default-off and dev-only", which is likewise a policy statement.

**Evidence:** `app/lib/corpus/flag.ts:13-24`

---

## Claim 2: "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or ... runtime `localStorage.setItem("corpus-fs-enabled", "1")`"

**Location:** `app/lib/corpus/flag.ts:11-12`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

Both enable paths exist. The env path reads `process.env?.NEXT_PUBLIC_CORPUS_FS === "1"`
(`app/lib/corpus/flag.ts:16`) and the runtime path reads
`window.localStorage.getItem(CORPUS_FLAG_KEY) === "1"` where
`CORPUS_FLAG_KEY = "corpus-fs-enabled"`:

```ts
// app/lib/corpus/flag.ts:13
export const CORPUS_FLAG_KEY = "corpus-fs-enabled";
```

The "build-time env inlining" characterization is correct for Next.js: `NEXT_PUBLIC_`-prefixed
vars are statically inlined at build time (paraphrased — no quote available because this is a
Next.js framework behavior, not a fact expressible from a snippet in this repo). The key literal
matches the localStorage instructions exactly.

**Evidence:** `app/lib/corpus/flag.ts:13, 16, 21`

---

## Claim 3: "In S1 there is no localStorage->corpus migration ... enabling this starts from an EMPTY corpus"

**Location:** `app/lib/corpus/flag.ts:3-5`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

No migration code exists in the corpus layer: `resolveWorkspaceStorage` selects one of two
storages and copies nothing between them (`app/lib/corpus/storeAdapter.ts:74-85`), and
`createCorpusBackedStorage.getItem` returns whatever the CorpusFS holds — `null` for a fresh corpus
— with no fallback read from localStorage:

```ts
// app/lib/corpus/storeAdapter.ts:50-52
getItem: async (name) => {
  const bytes = await fs.readFile(stateBlobPath(name));
  return bytes ? dec.decode(bytes) : null;
},
```

Paraphrased — no quote available because the claim covers the absence of migration logic; a search
of `app/lib/corpus/` shows no read of localStorage on the corpus-ON branch. Medium confidence
because "empty" also depends on S4 code not yet present, which is consistent with the claim.

**Evidence:** `app/lib/corpus/storeAdapter.ts:47-58, 74-85`

---

## Claim 4: Manifest codec is "FAIL-LOUD at the STRUCTURAL level ... never a silent default-empty manifest"

**Location:** `app/lib/corpus/manifest.ts:12-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Every listed structural failure calls `fail()`, which throws a `CorpusError` (kind "io"):

```ts
// app/lib/corpus/manifest.ts:48-51
function fail(reason: string): never {
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
}
```

Absent bytes → `fail("manifest file is absent")` (`manifest.ts:59`); non-JSON → `fail` in the catch
(`manifest.ts:564` context, i.e. `manifest.ts:63-64`); non-object top level → `fail`
(`manifest.ts:66`); missing `title`/`manifestVersion` → `fail` (`manifest.ts:67-68`); a non-array
`sources`/`artifacts`/`customTypeIds` field → `fail` (`manifest.ts:75, 84, 88` context). No branch
returns an empty manifest on malformation. Tests confirm (`manifest.test.ts:24-45`).

**Evidence:** `app/lib/corpus/manifest.ts:58-88`, `app/lib/corpus/__tests__/manifest.test.ts:24-45`

---

## Claim 5: "WITHIN a well-formed array the codec is deliberately LENIENT ... entries are dropped (.filter), a missing `label` defaults to `id` ..."

**Location:** `app/lib/corpus/manifest.ts:18-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Non-object array entries are dropped via `.filter(isObject)`, missing `label` defaults to `id`, and
missing timestamps are fabricated as "now":

```ts
// app/lib/corpus/manifest.ts:70-73
? raw.sources.filter(isObject).map((s) => {
    if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");
    return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
  })
```

```ts
// app/lib/corpus/manifest.ts:93-94
createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : new Date().toISOString(),
```

Non-string `customTypeIds` dropped: `raw.customTypeIds.filter((x): x is string => typeof x === "string")`
(`manifest.ts:87`). Note the docstring's lenient list does not claim id/ext are lenient — those
still `fail` — so there is no contradiction. The narrowed docstring accurately scopes leniency to
what the code actually tolerates.

**Evidence:** `app/lib/corpus/manifest.ts:70-94`

---

## Claim 6: "This matches the app's existing `coerceArtifactVersion` convention"

**Location:** `app/lib/corpus/manifest.ts:19-20`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

`coerceArtifactVersion` exists and uses the same drop-invalid-entries `.filter` convention:

```ts
// app/lib/stores/workspaceStore.ts:39,56
function coerceArtifactVersion(raw: unknown): ArtifactVersion | null {
...
    ? (raw.versions as unknown[]).map(coerceArtifactVersion).filter((v): v is ArtifactVersion => v !== null)
```

The referenced symbol resolves in-repo and the described convention (map-then-filter, drop
null/invalid) matches.

**Evidence:** `app/lib/stores/workspaceStore.ts:39, 56`

---

## Claim 7: OPFS "SSR / unavailable guard ... rejects with a typed `CorpusError` ({kind:"unavailable"}), never a raw `TypeError`"

**Location:** `app/lib/corpus/opfsAdapter.ts:9-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`getRoot()` throws a typed `unavailable` error before any raw property access:

```ts
// app/lib/corpus/opfsAdapter.ts:51-54
const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
if (!storage || typeof storage.getDirectory !== "function") {
  throw new CorpusError({ kind: "unavailable", reason: "navigator.storage.getDirectory is not available (SSR or unsupported browser)" });
}
```

`getRoot()` is called first in every method's `try` block, so no method reaches a raw `TypeError`.
Tests assert `detail.kind === "unavailable"` for readFile and rejection for all five methods
(`opfsAdapter.test.ts:34-46`).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:50-56, 88-90`, `app/lib/corpus/__tests__/opfsAdapter.test.ts:23-46`

---

## Claim 8: "a quota failure rejects with {kind:"quota-exceeded", substrate:"opfs"} — it is NOT swallowed with console.warn the way the legacy localStorage adapter does (createDebouncedLocalStorage in storeAdapter.ts:35)"

**Location:** `app/lib/corpus/opfsAdapter.ts:12-15`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High

The quota-reification behavior is verified: `wrap()` maps a quota DOMException to the typed kind:

```ts
// app/lib/corpus/opfsAdapter.ts:82
if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
```

and `isQuota` matches `QuotaExceededError`/`QUOTA_EXCEEDED_ERR` (`opfsAdapter.ts:46-48`). The test
confirms `detail.kind === "quota-exceeded"` and `substrate === "opfs"` (`opfsAdapter.test.ts:60-64`).
The contrast claim is also correct — the legacy path swallows with `console.warn`:

```ts
// app/lib/corpus/storeAdapter.ts:36
console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
```

The imprecision is the line reference: the `console.warn` swallow is at `storeAdapter.ts:36`, not
`:35` (line 35 is the `} catch (e) {`). Off-by-one comment-only inaccuracy; the function name
`createDebouncedLocalStorage` resolves correctly (defined at `storeAdapter.ts:26`).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:46-48, 82`, `app/lib/corpus/storeAdapter.ts:26, 33-37`, `app/lib/corpus/__tests__/opfsAdapter.test.ts:33-65`

---

## Claim 9 (R4): writeFile — "`write` copies `bytes` into the file before it resolves, so the caller's array is safe to mutate once `writeFile` returns — no defensive copy is made here (the array is passed through unchanged)"

**Location:** `app/lib/corpus/opfsAdapter.ts:120-125` (diff lines 721-726)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The "no defensive copy / passed through unchanged" half is verified from source — `bytes` is handed
straight to `w.write` with no `.slice()`:

```ts
// app/lib/corpus/opfsAdapter.ts:127
await w.write(bytes);
```

The "write copies bytes before it resolves, so the caller's array is safe to mutate" half is an
OPFS runtime-semantics claim (paraphrased — no quote available because it depends on
`FileSystemWritableFileStream.write` behavior, an external Web API not statically verifiable from
this repo). This is the corrected replacement for the pass-1 "fresh ArrayBuffer view" wording; it no
longer overstates a defensive copy. The write-aliasing contract case exercises this axis against the
in-memory fake only (`corpusFsContract.ts:114-120`); OPFS itself is checked out-of-CI. Marked
mostly accurate because the runtime half rests on documented-but-not-here Web API behavior.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:113-134`, `app/lib/corpus/__tests__/corpusFsContract.ts:114-120`

---

## Claim 10: readFile returns a fresh `Uint8Array` each read (basis for the fake's copy-on-read alignment)

**Location:** `app/lib/corpus/opfsAdapter.ts:106` and cross-referenced at `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:23-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

OPFS readFile constructs a new `Uint8Array` from a fresh `arrayBuffer()`:

```ts
// app/lib/corpus/opfsAdapter.ts:106
return new Uint8Array(await file.arrayBuffer());
```

This substantiates the inMemory fake's comment that "OPFS returns a fresh `new Uint8Array(...)` each
read; the fake must too", which the fake honors with `bytes.slice()` (see Claim 15).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:106`

---

## Claim 11 (R1): "Top-level directory holding S1's blob-mode persist files" — `STATE_DIR = "state"` and `stateBlobPath` routed through paths.ts

**Location:** `app/lib/corpus/paths.ts:66-76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`STATE_DIR` is defined and `stateBlobPath` builds under it via the sanitizer:

```ts
// app/lib/corpus/paths.ts:69, 74-76
export const STATE_DIR = "state";
...
export function stateBlobPath(name: string): string {
  return `${STATE_DIR}/${safeSegment(name)}.json`;
}
```

`storeAdapter.ts` imports and uses it rather than hand-concatenating:

```ts
// app/lib/corpus/storeAdapter.ts:16 (import) and 51/54/57
import { stateBlobPath } from "./paths";
...
const bytes = await fs.readFile(stateBlobPath(name));
```

The flag-routing test confirms the blob lands at `state/workspace-zustand-v1.json`
(`workspaceStore-corpus-flag.test.ts:50`). R1 fix confirmed.

**Evidence:** `app/lib/corpus/paths.ts:66-76`, `app/lib/corpus/storeAdapter.ts:16, 50-58`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:49-51`

---

## Claim 12: "The only source of corpus paths is this module — callers must never hand-concatenate ... the traversal guard in `workspaceSlug` is the single choke point"

**Location:** `app/lib/corpus/paths.ts:19-23`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

`workspaceSlug` applies the traversal guard and every workspace-scoped builder routes through
`workspaceDir` → `workspaceSlug`:

```ts
// app/lib/corpus/paths.ts:32-43
export function workspaceSlug(title: string): string {
  const slug = title
    .normalize("NFKD")
    .replace(SAFE_SEGMENT, "-")
    ...
  if (!slug) { throw new Error(`workspace title produced an empty slug: ...`); }
  return slug;
}
```

Paraphrased — no quote available because the "no hand-concatenation" claim covers the absence of
path literals in callers: the only corpus-path consumer in the diff, `storeAdapter.ts`, calls
`stateBlobPath()` rather than building strings. Medium confidence because "single choke point" is a
whole-codebase invariant and future callers could bypass it; it holds for the code present at 409e9dc.

**Evidence:** `app/lib/corpus/paths.ts:32-53, 78-80`, `app/lib/corpus/storeAdapter.ts:50-58`

---

## Claim 13: "artifact version path is zero-padded to 4 digits" and "rejects a non-positive or non-integer version"

**Location:** `app/lib/corpus/paths.ts:94-95` (docstring + code)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
// app/lib/corpus/paths.ts:96-102
export function artifactVersionPath(slug: string, artifactType: string, version: number): string {
  if (!Number.isInteger(version) || version < 1) {
    throw new Error(`artifact version must be a positive integer, got ${version}`);
  }
  const v = String(version).padStart(VERSION_PAD, "0");
  return `${artifactDir(slug, artifactType)}/v${v}.md`;
}
```

`VERSION_PAD = 4` (`paths.ts:19`). Tests confirm `v0001.md`, `v0042.md`, and throws on `0` and `1.5`
(`paths.test.ts:60-64`).

**Evidence:** `app/lib/corpus/paths.ts:18-19, 96-102`, `app/lib/corpus/__tests__/paths.test.ts:54-64`

---

## Claim 14 (R2): "The CorpusFS is injected via `makeCorpusFs` (default: the OPFS adapter) ... callers override the factory instead of this module hard-wiring `createOpfsCorpusFs` (arch-review R2). The factory is only invoked on the flag-ON branch, so the default OFF path pays nothing."

**Location:** `app/lib/corpus/storeAdapter.ts:59-68`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High

The signature is parameterized with a default factory, and the factory is only called inside the
flag-ON branch:

```ts
// app/lib/corpus/storeAdapter.ts:74-85
export function resolveWorkspaceStorage(
  makeCorpusFs: () => CorpusFS = createOpfsCorpusFs,
): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(makeCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```

`makeCorpusFs()` is invoked only after `isCorpusEnabled()` is true; the OFF path returns
`createDebouncedLocalStorage()` and never constructs an OPFS adapter. R2 fix confirmed. The flag-OFF
test also asserts `getDirectory` is never called (`workspaceStore-corpus-flag.test.ts:28-30`).

**Evidence:** `app/lib/corpus/storeAdapter.ts:74-85`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:22-30`

---

## Claim 15: "Default: debounced localStorage (moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior)"

**Location:** `app/lib/corpus/storeAdapter.ts:14-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The removed `createDebouncedStorage` (diff lines 1357-1382) and the new
`createDebouncedLocalStorage` (`storeAdapter.ts:26-46`) have identical bodies: synchronous
`getItem`, a 300ms `setTimeout` debounce on `setItem` wrapping `localStorage.setItem` in try/catch
with the same `console.warn` string, and a `removeItem` that clears the pending timer. The only
difference is the return-type annotation (`StateStorage` vs an inline shape) — the logic is
byte-for-byte. Confirmed by comparing diff removal block against `storeAdapter.ts:26-46`.

**Evidence:** `app/lib/corpus/storeAdapter.ts:26-46`; diff removal at `app/lib/stores/workspaceStore.ts` (old `createDebouncedStorage`)

---

## Claim 16 (R3): in-memory fake read/write copy semantics + rm idempotence + file-as-parent rejection aligned to OPFS

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:23-31, 190-193, 210-212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Copy-on-read and copy-on-write both use `.slice()`:

```ts
// app/lib/corpus/__tests__/inMemoryCorpusFs.ts:37, 43
return bytes ? bytes.slice() : null;        // readFile
files.set(normalize(path), bytes.slice());  // writeFile
```

`rm` is idempotent via `Map.delete` (no-op on missing key) — `files.delete(normalize(path))`
(`inMemoryCorpusFs.ts:56`). File-as-parent is rejected with a `CorpusError`:

```ts
// app/lib/corpus/__tests__/inMemoryCorpusFs.ts:26-28
if (files.has(ancestor)) {
  throw new CorpusError({ kind: "io", path, reason: `parent path is a file: ${ancestor}` });
}
```

The three new contract cases exist and target exactly these axes — write-aliasing, read-aliasing,
file-as-parent (`corpusFsContract.ts:114-137`). R3 alignment confirmed.

**Evidence:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:20-56`, `app/lib/corpus/__tests__/corpusFsContract.ts:112-138`

---

## Claim 17: "OPFS raises a TypeMismatchError that the adapter wraps to a `CorpusError` (kind "io")" (file-as-parent on write)

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:16-19` (diff lines 163-167)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

On the write path, `walkDir` is called with `create = true`. When an ancestor segment is an existing
file, `getDirectoryHandle` throws `TypeMismatchError`; the `walkDir` catch re-throws because
`!create` is false, and the outer `writeFile` catch routes to `wrap`, which maps a non-quota
DOMException to kind "io":

```ts
// app/lib/corpus/opfsAdapter.ts:72-74 (walkDir catch)
if (!create && isNotFound(e)) return null;
throw e;
```
```ts
// app/lib/corpus/opfsAdapter.ts:83 (wrap)
throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });
```

So on write, `TypeMismatchError` → re-thrown → wrapped to kind "io", matching the fake's io
rejection. (Note: on *read*, `isNotFound` treats `TypeMismatchError` as not-found and returns
`null` — but the comment is scoped to writing under a file parent, which is the io path. Accurate as
scoped.)

**Evidence:** `app/lib/corpus/opfsAdapter.ts:44-45, 67-78, 80-84, 113-134`

---

## Claim 18: contract-suite docstring — "green CI run here predicts OPFS behavior ... exercised against this same suite by the documented out-of-CI Playwright smoke (docs/spikes/corpus-opfs-smoke.md)"

**Location:** `app/lib/corpus/__tests__/corpusFsContract.ts:29-37`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High

The referenced smoke doc exists at HEAD (`git cat-file -e HEAD:docs/spikes/corpus-opfs-smoke.md`
succeeds — paraphrased, no quote because this is a file-existence check, not a snippet). The suite
is defined once and run against the fake in CI (`corpusFs.contract.test.ts:14`
`defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs())`); the OPFS adapter is not
run under jsdom, consistent with the docstring. The R3 fix's "documented jsdom smoke" claim holds.

**Evidence:** `app/lib/corpus/__tests__/corpusFsContract.ts:21-37`, `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-14`, `docs/spikes/corpus-opfs-smoke.md` (exists at HEAD)

---

## Claim 19: types.ts references "docs/decisions/009-artifact-corpus-architecture.md and docs/reviews/architecture-review.md"

**Location:** `app/lib/corpus/types.ts:9-10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

Both referenced docs exist at HEAD (paraphrased — no quote available because these are
file-existence checks; `git cat-file -e HEAD:docs/decisions/009-artifact-corpus-architecture.md`
and `...docs/reviews/architecture-review.md` both succeed).

**Evidence:** `docs/decisions/009-artifact-corpus-architecture.md`, `docs/reviews/architecture-review.md` (both exist at HEAD)

---

## Claim 20: `describeCorpusError` handles every `CorpusErrorKind`, guarded by `assertNever`

**Location:** `app/lib/corpus/types.ts:93-106`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High

The switch has a `case` for all eight kinds declared in `CorpusErrorKind` (`types.ts:57-65`):
`not-found`, `quota-exceeded`, `unavailable`, `io`, `fsa-permission-revoked`,
`remote-auth-expired`, `browser-storage-cleared`, `git-conflict`, with a `default: return
assertNever(d)` exhaustiveness guard:

```ts
// app/lib/corpus/types.ts:104
default: return assertNever(d);
```

Each declared kind maps to a message case; the compile-time exhaustiveness claim is structurally
sound.

**Evidence:** `app/lib/corpus/types.ts:57-65, 94-106, 110-112`

---

## Claim 21: "The complete set of corpus failure kinds. Every exhaustive `switch` over a corpus error binds to this union; adding a kind here forces every consumer to handle it at compile time"

**Location:** `app/lib/corpus/types.ts:52-56`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High

The compile-time exhaustiveness mechanism is real (Claim 20). However, of the eight declared kinds
only three are ever *constructed* in the code at 409e9dc: `io`, `unavailable`, and `quota-exceeded`
(`grep "new CorpusError" app/lib/corpus/` → `manifest.ts:74` io, `opfsAdapter.ts:53` unavailable,
`opfsAdapter.ts:61` io, `opfsAdapter.ts:82` quota-exceeded, `opfsAdapter.ts:83` io,
`inMemoryCorpusFs.ts:28` io). The other five — `not-found`, `fsa-permission-revoked`,
`remote-auth-expired`, `browser-storage-cleared`, `git-conflict` — are declared but never produced
(forward-looking for S2/S3/S4). Notably `not-found` is *intentionally* never thrown: the interface
contract is "Not found is `null` from readFile/stat and `[]` from readdir" (`types.ts:34-35`). The
docstring claim is about the switch/exhaustiveness contract, which is accurate; it does not assert
all kinds are currently produced. Flagged mostly accurate so downstream readers know producibility
is partial by design, not oversight. Comment-only (the type is intentionally ahead of the producers).

**Evidence:** `app/lib/corpus/types.ts:57-65`, `app/lib/corpus/manifest.ts:74`, `app/lib/corpus/opfsAdapter.ts:53, 61, 82, 83`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:28`

---

## Claim 22: "'Not found' is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

**Location:** `app/lib/corpus/types.ts:33-35`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High

The OPFS adapter honors this: readFile returns `null` on missing dir/file
(`opfsAdapter.ts:98,103`), readdir returns `[]` on missing dir (`opfsAdapter.ts:135` context / diff
741 `if (!dir) return [];`), stat returns `null` on missing (`opfsAdapter.ts:171` context). The
in-memory fake matches: readFile `null` / readdir `[]` / stat `null` (`inMemoryCorpusFs.ts:37, 47,
54-55`). No path returns `undefined`; failures go through `wrap` → `CorpusError`. The contract's
first two cases assert null/`[]` for missing paths (`corpusFsContract.ts:51-57`).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:88-110, 136-148, 166-184`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:33-55`, `app/lib/corpus/__tests__/corpusFsContract.ts:51-57`

---

## Claim 23: "GIT IS NOT PART OF THIS INTERFACE ... Do not add git methods here"

**Location:** `app/lib/corpus/types.ts:36-38`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`CorpusFS` declares only `readFile`, `writeFile`, `readdir`, `rm`, `stat`
(`types.ts:128-141`); no commit/log/push/pull methods are present (paraphrased — no quote available
because the claim is about the absence of git methods on the interface). Consistent with the ISP
rationale cited.

**Evidence:** `app/lib/corpus/types.ts:128-141`

---

## Claim 24: workspaceStore seam — "Storage seam is selected here ... typed as CorpusFS so the S3 worker-proxy is a drop-in"

**Location:** `app/lib/stores/workspaceStore.ts:496-499` (diff lines 1392-1395)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The store's persist config delegates storage selection to `resolveWorkspaceStorage` and no longer
defines its own adapter:

```ts
// app/lib/stores/workspaceStore.ts (persist config)
storage: createJSONStorage(resolveWorkspaceStorage),
```

with the import replacing the deleted inline `createDebouncedStorage`:

```ts
// app/lib/stores/workspaceStore.ts:25 (added import)
import { resolveWorkspaceStorage } from "@/app/lib/corpus/storeAdapter";
```

The seam is typed `CorpusFS` in `storeAdapter`/`types` (Claims 14, 23); the "S3 worker-proxy
drop-in" is a forward-looking design rationale consistent with the async `CorpusFS` interface.
No stale reference to the removed `createDebouncedStorage` remains in `app/` (the only
`createDebouncedStorage` left is an unrelated one in `evidenceStore.ts:20`).

**Evidence:** `app/lib/stores/workspaceStore.ts:25, 493-499`, `app/lib/stores/evidenceStore.ts:20`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`app/lib/corpus/flag.ts:5`): "DEV-ONLY" is a usage policy, not enforced — no
  `NODE_ENV`/production guard exists; the flag activates in any environment. Comment-only.
- **Claim 8** (`app/lib/corpus/opfsAdapter.ts:14`): line reference `storeAdapter.ts:35` is off by
  one — the `console.warn` swallow is at line 36. Comment-only.
- **Claim 9** (`app/lib/corpus/opfsAdapter.ts:120-125`): the "no defensive copy" half is verified
  from source; the "write copies bytes so the caller's array is safe to mutate" half rests on OPFS
  runtime semantics not verifiable in-repo. Comment-only (accurate replacement for the pass-1
  "fresh ArrayBuffer view" wording).
- **Claim 21** (`app/lib/corpus/types.ts:52-56`): only 3 of 8 declared `CorpusErrorKind`s are
  constructed at this commit; the other 5 are forward-looking (and `not-found` is intentionally
  never thrown, per the null contract). Docstring is accurate about the switch contract; producibility
  is partial by design. Comment-only.

### Unverifiable
- **Claim 9** (`app/lib/corpus/opfsAdapter.ts:120-125`): the OPFS `write`-copies-before-resolve
  runtime guarantee would need a real-OPFS (Playwright) run to confirm; it is checked only against
  the in-memory fake in CI.

---

## Goal-Alignment Note

The stated goal of this pass was to verify the pass-1 fix claims (R1-R4 + comment ambers) and
re-check standing S0/S1 claims. All four fix claims are substantiated in code: R1 (state blob routed
through `paths.ts` `stateBlobPath()` + `STATE_DIR`, Claim 11), R2 (`resolveWorkspaceStorage`
parameterized with `makeCorpusFs`, factory only on flag-ON, Claim 14), R3 (in-memory fake aligned to
OPFS copy/reject semantics + three new contract cases + documented jsdom smoke, Claims 16-18), and
R4 (the "fresh ArrayBuffer view" wording is replaced by an accurate no-defensive-copy comment,
Claim 9). Stale-reference cleanup is confirmed (no dangling `createDebouncedStorage` in the corpus
path; Claim 24), and the manifest docstring's narrowed fail-loud/lenient split matches the codec
(Claims 4-5). No Incorrect verdicts. The five Mostly-accurate items are all comment-only
imprecisions (an unenforced "dev-only" policy, one off-by-one line reference, a runtime-semantics
half-claim, and partial-by-design error-kind producibility) — none indicate code-wrong behavior.
No hallucination-pattern log exists in this worktree, so no patterns were logged.
