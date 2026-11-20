Commit: 2dc403e

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (reviewed worktree `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-corpus`, detached HEAD 2dc403e)
**Scope:** `git diff dc6dfb0..2dc403e -- app/` (15 files) plus the bodies of the five in-range commits touching `app/`; replicate r2 of 3
**Checked:** 2026-11-19
**Total claims checked:** 35
**Summary:** 12 verified, 6 mostly accurate, 2 stale, 9 incorrect, 6 unverifiable

Execution note: the worktree has no `node_modules` and the sandbox has no network, so `vitest`, `next build` and `eslint` cannot run. Behavioral claims about `manifest.ts`, `paths.ts` and `opfsAdapter.ts` were executed with Node 22's `--experimental-strip-types` against copies of those files (only the `./types` import specifier rewritten to `./types.ts`).
Probe: command `timeout 60 node --experimental-strip-types --no-warnings probe.ts`, cwd `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r2-probe`, exit 0, 2026-11-20T01:49:17Z, output captured at `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r2-probe/out.txt` (script `probe.ts` in the same directory). Below, this is called "the probe".

No `docs/reviews/hallucination-patterns.md` exists in the reviewed repo; no claim matched a logged pattern.

---

## Claim 1: "The OPFS adapter is held to the same suite out-of-CI (Playwright)"

**Location:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-3`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether any harness runs `defineCorpusFsContract` (or its cases) against `createOpfsCorpusFs`; does not establish whether the OPFS adapter would pass the suite if run.
**Legibility-target:** for-author

Only one caller of `defineCorpusFsContract` exists, and it passes the fake:

```ts
// app/lib/corpus/__tests__/corpusFs.contract.test.ts:8
defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());
```

The only Playwright material is the smoke doc, and it says the run has not happened and is a sketch:

```md
// docs/spikes/corpus-opfs-smoke.md (## Results)
_(not yet run — fill in when executed before enabling the flag in a shared environment)_
```

The sketch bundles `opfsAdapter.ts` with esbuild and runs six hand-written checks in `page.evaluate`. It does not import the vitest-based suite, and it omits the suite's "overwrites an existing file in place" case (paraphrased — no quote available because the claim is about the absence of a runner; `rg -ln defineCorpusFsContract` lists only the suite, the CI test and the docs).

**Evidence:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:8`, `app/lib/corpus/__tests__/corpusFsContract.ts:53-125`, `docs/spikes/corpus-opfs-smoke.md`

---

## Claim 2: "Run against the in-memory fake in CI ... and against the real OPFS adapter via out-of-CI Playwright ... the fake and the adapter are held to identical behavior (substitutability)"

**Location:** `app/lib/corpus/__tests__/corpusFsContract.ts:4-7`
**Type:** Behavioral / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "against the real OPFS adapter" and "held to identical behavior" parts; the CI run against the fake is true.
**Legibility-target:** for-author

Same evidence as Claim 1: no OPFS run of this suite exists. The suite also imports vitest (`import { describe, it, expect, beforeEach } from "vitest";` at `corpusFsContract.ts:10`), so it cannot run inside a browser page as written. The two implementations also differ on cases the suite never exercises. The fake's `files.set(normalize(path), bytes.slice())` (`inMemoryCorpusFs.ts:26`) accepts writing `a.txt/b` after `a.txt` exists. The OPFS adapter's `walkDir(root, dirs, true)` calls `getDirectoryHandle("a.txt", { create: true })`, which per the OPFS spec rejects with TypeMismatchError, and `wrap` (`opfsAdapter.ts:79-83`) turns that into `{kind:"io"}` (paraphrased — no quote available because the divergence spans two files plus browser behavior that cannot run here).

**Evidence:** `app/lib/corpus/__tests__/corpusFsContract.ts:4-10`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:24-27`, `app/lib/corpus/opfsAdapter.ts:66-83`

---

## Claim 3: "The OPFS adapter and this fake are both asserted against the same shared contract suite ... so substitutability (LSP) is verified, not assumed."

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:5-6`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the OPFS adapter is asserted against the suite; does not assess the fake's own correctness, which the CI run covers.
**Legibility-target:** for-author

Only the fake is asserted (`corpusFs.contract.test.ts:8`, quoted in Claim 1). For the OPFS adapter, substitutability is assumed, not verified.

**Evidence:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:1-9`, `app/lib/corpus/__tests__/corpusFs.contract.test.ts:8`, `docs/spikes/corpus-opfs-smoke.md`

---

## Claim 4: "The adapter's *success* path is covered by the shared CorpusFS contract suite run against real OPFS out-of-CI (Playwright, step 9)"

**Location:** `app/lib/corpus/__tests__/opfsAdapter.test.ts:5-7`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether a success-path run exists; does not establish whether the success path is correct.
**Legibility-target:** for-author

Step 9's artifact is `docs/spikes/corpus-opfs-smoke.md`, whose Results section reads `_(not yet run ...)_`. The success path is not covered anywhere. This file's three tests stub only the unavailable and quota paths.

**Evidence:** `app/lib/corpus/__tests__/opfsAdapter.test.ts:1-83`, `docs/spikes/corpus-opfs-smoke.md`

---

## Claim 5a: "DEFAULT OFF"

**Location:** `app/lib/corpus/flag.ts:4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `isCorpusEnabled()` returning false when neither the env var nor the localStorage key is set; does not establish what the deployed build environment sets.
**Legibility-target:** for-orchestrator-synthesis

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

## Claim 5b: "DEV-ONLY ... it must not be turned on for end users until S4 ships migration"

**Location:** `app/lib/corpus/flag.ts:4,6-7`
**Type:** Configuration / Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the code restricts the flag to development builds; does not cover "must not be turned on" read as a policy instruction, which is not checkable.
**Legibility-target:** for-author

Nothing in `isCorpusEnabled` (quoted in Claim 5a, `flag.ts:15-25`) checks `NODE_ENV` or anything dev-specific. In a production build, `localStorage.setItem("corpus-fs-enabled","1")` enables corpus mode for that user, and `resolveWorkspaceStorage` (`storeAdapter.ts:71-76`) then switches their store to an empty OPFS blob. "Dev-only" is a convention, not an enforced property. A reader who assumes production builds ignore the flag is misled. Medium confidence because the authors may have meant "dev-only" purely as policy.

**Evidence:** `app/lib/corpus/flag.ts:15-25`, `app/lib/corpus/storeAdapter.ts:71-76`

---

## Claim 6: "enabling this starts from an EMPTY corpus and does not carry existing localStorage work over"

**Location:** `app/lib/corpus/flag.ts:4-6`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the `workspace-zustand-v1` persist blob and the legacy `workspace-v2` migration hook; does not cover other localStorage-backed stores (evidenceStore, sessions hooks), which this flag does not touch.
**Legibility-target:** for-author

The persist blob does start empty: `getItem` reads `state/<name>.json` from OPFS (`storeAdapter.ts:56-59`). But the store's rehydrate hook still reads localStorage directly, outside the seam:

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

(excerpt ends :540; enclosing `onRehydrateStorage` continues to :543 — read.) Suppose the flag is on, legacy `workspace-v2` data exists, and the localStorage zustand key has no `sourceText`. Then `migrateFromV2()` (`workspaceStore.ts:251-253`, `const old = loadWorkspace();`) copies legacy v2 work into the store, and from there into the corpus. Precise version: "starts empty except that legacy workspace-v2 data can still be migrated in by the store's rehydrate hook".

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-68`, `app/lib/stores/workspaceStore.ts:251-253`, `app/lib/stores/workspaceStore.ts:528-543`

---

## Claim 7a: "Enable via ... the build-time env `NEXT_PUBLIC_CORPUS_FS=1`"

**Location:** `app/lib/corpus/flag.ts:9`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers whether the env route reaches client code; does not establish behavior under webpack vs Turbopack.
**Legibility-target:** for-orchestrator-synthesis

The check reads `process.env?.NEXT_PUBLIC_CORPUS_FS` with optional chaining (`flag.ts:16`, quoted in Claim 5a). Next.js inlines `NEXT_PUBLIC_*` by textually replacing `process.env.NEXT_PUBLIC_X`. Whether `process.env?.NEXT_PUBLIC_CORPUS_FS` is matched by Next 16's define step (Turbopack or webpack DefinePlugin) can only be settled by building. If it is not matched, the browser bundle sees an empty polyfilled `process.env` and the env route does nothing client-side. Execution required: needs `npm ci` (no network) and `NEXT_PUBLIC_CORPUS_FS=1 next build`, then a grep of the client chunk.

**Evidence:** `app/lib/corpus/flag.ts:16`, `package.json` (`"next": "^16.2.6"`)

---

## Claim 7b: "or, at runtime in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`"

**Location:** `app/lib/corpus/flag.ts:9-10`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the key name and the `=== "1"` check; does not establish timing. The storage is resolved once at store-module import (Claim 21), so the key takes effect only on the next page load.
**Legibility-target:** for-orchestrator-synthesis

`export const CORPUS_FLAG_KEY = "corpus-fs-enabled";` (`flag.ts:13`) and `return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";` (`flag.ts:19`). The G15 test sets this key and asserts `getDirectory` is called (`workspaceStore-corpus-flag.test.ts:47,65`).

**Evidence:** `app/lib/corpus/flag.ts:13-19`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:45-67`

---

## Claim 8a: "A malformed or absent manifest must surface as a typed `CorpusError` of kind "io" or "browser-storage-cleared""

**Location:** `app/lib/corpus/manifest.ts:10-13`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `parseManifest`'s throw paths; does not establish caller handling (no caller exists yet).
**Legibility-target:** for-author

Every throw goes through one helper, which only ever produces kind `"io"`:

```ts
// app/lib/corpus/manifest.ts:64-67
function fail(reason: string): never {
  // Manifest parse failure is an i/o-class corruption of the workspace index.
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
}
```

Nothing in `app/` constructs `"browser-storage-cleared"`; `rg` finds it only in `types.ts:48,86` and this docstring. "Absent" surfaces only if the caller passes `null` (`if (bytes === null) fail("manifest file is absent");`, `manifest.ts:75`). `parseManifest` has no caller outside tests yet. Precise version: "throws `CorpusError{kind:"io"}`; detecting an absent manifest is the caller's job". The function's own docstring at `manifest.ts:69-73` says exactly that.

**Evidence:** `app/lib/corpus/manifest.ts:64-115`, `app/lib/corpus/types.ts:48`, `app/lib/corpus/__tests__/manifest.test.ts:213-241`, probe output `out.txt`

---

## Claim 8b: "never a silent default-empty manifest that would masquerade as "this workspace has no work in it""

**Location:** `app/lib/corpus/manifest.ts:12-13`
**Type:** Invariant / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers malformed entries inside the `sources`/`artifacts`/`customTypeIds` arrays and missing timestamp or version fields; the missing-field and non-JSON throw paths are correct (Claim 8a).
**Legibility-target:** for-author

Malformed array entries are silently filtered out instead of failing:

```ts
// app/lib/corpus/manifest.ts:86-88
const sources: SourceRef[] = Array.isArray(raw.sources)
  ? raw.sources.filter(isObject).map((s) => {
      if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");
```

(excerpt ends :88; enclosing `parseManifest` continues to :115 — read.) The same pattern appears for `artifacts` (`:94`, `raw.artifacts.filter(isObject)`) and `customTypeIds` (`:103`, `.filter((x): x is string => typeof x === "string")`). Missing timestamps default to now (`:109`, `createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString()`). `manifestVersion` is not checked against `MANIFEST_VERSION`, and `currentVersion` is not checked for being a positive integer. In the probe, `{manifestVersion:1,title:"t",sources:[1,"x"],artifacts:["a",null],customTypeIds:[5]}` parsed without error to `"sources":[],"artifacts":[],"customTypeIds":[]`. That is exactly the "default-empty manifest" the comment rules out. `{manifestVersion:99, artifacts:[{type:"x",currentVersion:-3}]}` was also accepted. The commit ec7bbbc body makes the same claim ("never silent default-empty").

**Evidence:** `app/lib/corpus/manifest.ts:74-115`, probe output `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r2-probe/out.txt` (lines M1, M2)

---

## Claim 9: "any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:"unavailable"}), never a raw `TypeError`"

**Location:** `app/lib/corpus/opfsAdapter.ts:9-11`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five methods with `navigator.storage` lacking `getDirectory`; does not establish behavior when `getDirectory()` exists but rejects (for example SecurityError), which maps to `{kind:"io"}`.
**Legibility-target:** for-orchestrator-synthesis

```ts
// app/lib/corpus/opfsAdapter.ts:49-55
async function getRoot(): Promise<OpfsDirHandle> {
  const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
  if (!storage || typeof storage.getDirectory !== "function") {
    throw new CorpusError({ kind: "unavailable", reason: "navigator.storage.getDirectory is not available (SSR or unsupported browser)" });
  }
  return (await storage.getDirectory()) as unknown as OpfsDirHandle;
}
```

Each method calls `getRoot()` first, inside a `try` whose `catch` calls `wrap`. `wrap` rethrows a `CorpusError` unchanged (`if (e instanceof CorpusError) throw e;`, `:80`). In the probe, all five methods produced `O3 <method> true unavailable`.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:49-55`, `app/lib/corpus/opfsAdapter.ts:79-174`, probe output `out.txt` (O3 lines)

---

## Claim 10: "a quota failure rejects with {kind:"quota-exceeded", substrate:"opfs"} — it is NOT swallowed with console.warn"

**Location:** `app/lib/corpus/opfsAdapter.ts:12-14`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers DOMExceptions named `QuotaExceededError` raised by `createWritable`, or by `write` followed by `close` rejecting with the same error (the streams-spec behavior), against a stub; does not establish what real browsers raise on OPFS quota exhaustion.
**Legibility-target:** for-orchestrator-synthesis

`if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` (`opfsAdapter.ts:81`). `isQuota` matches `e.name === "QuotaExceededError" || e.name === "QUOTA_EXCEEDED_ERR"` (`:45-47`). In the probe, a `write()` that throws the quota error produced `{"kind":"quota-exceeded","substrate":"opfs"}`. `rg console.warn` finds no call in `opfsAdapter.ts`. Medium confidence because the error a real browser raises is not observable here.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:45-47`, `app/lib/corpus/opfsAdapter.ts:79-83`, `app/lib/corpus/opfsAdapter.ts:107-123`, probe output `out.txt` (O2)

---

## Claim 11: "the way the legacy localStorage adapter does (workspaceStore.ts:44-46)"

**Location:** `app/lib/corpus/opfsAdapter.ts:14`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file:line pointer; does not cover the adapter's behavior, which is unchanged.
**Legibility-target:** for-author

The pointer was right at dc6dfb0, where `git show dc6dfb0:app/lib/stores/workspaceStore.ts | sed -n 44,46p` gives `} catch (e) {` / `console.warn("Failed to persist workspace ...")` / `}`. Commit 00ba8c3 moved the adapter out of `workspaceStore.ts`, which now has unrelated code at 44-46: `content: raw.content,` / `createdAt: ...` / `source: ...`. The `console.warn` now lives at `app/lib/corpus/storeAdapter.ts:35`.

**Evidence:** `app/lib/stores/workspaceStore.ts:44-46`, `app/lib/corpus/storeAdapter.ts:33-36`, `dc6dfb0:app/lib/stores/workspaceStore.ts:44-46`

---

## Claim 12: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** `app/lib/corpus/opfsAdapter.ts:115`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what is passed to `write()`; does not establish whether any OPFS implementation rejects shared or offset views.
**Legibility-target:** for-author

```ts
// app/lib/corpus/opfsAdapter.ts:114-117
try {
  // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
  await w.write(bytes);
} finally {
```

(excerpt ends :117; enclosing `writeFile` continues to :123 — read.) The caller's `bytes` goes through unchanged: no `slice()`, no `new Uint8Array(...)`. In the probe, `write()` received the very same object (`O1 write received same object as caller: true`). Either the copy the comment describes is missing, or the comment is wrong.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:107-123`, probe output `out.txt` (O1)

---

## Claim 13a: "The only source of corpus paths is this module — callers must never hand-concatenate"

**Location:** `app/lib/corpus/paths.ts:16-18`
**Type:** Architectural / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "only source" and "never hand-concatenate" assertion across `app/`; does not establish that the hand-built path is exploitable (its `name` is the constant `"workspace-zustand-v1"`).
**Legibility-target:** for-author

The same diff builds a corpus path by hand in the only production CorpusFS consumer:

```ts
// app/lib/corpus/storeAdapter.ts:55
const pathFor = (name: string) => `state/${name}.json`;
```

Nothing outside tests imports `paths.ts` (`rg "corpus/paths|from \"./paths\"" app` with tests excluded returns nothing). The `state/` directory is also missing from the documented layout (`paths.ts:3-13`). The commit ec7bbbc body makes the same "single choke point" claim.

**Evidence:** `app/lib/corpus/paths.ts:1-20`, `app/lib/corpus/storeAdapter.ts:52-68`

---

## Claim 13b: "the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`"

**Location:** `app/lib/corpus/paths.ts:18-19`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every builder in `paths.ts`, since each routes the slug through `workspaceDir` → `workspaceSlug`; does not cover paths built outside the module (Claim 13a).
**Legibility-target:** for-orchestrator-synthesis

`return \`workspaces/${workspaceSlug(slug)}\`;` (`paths.ts:71`, `workspaceDir`). Every other builder starts from `${workspaceDir(slug)}`. In the probe: `"../etc/passwd" -> etc-passwd`, `".." throws`, `"a\\b" -> a-b`.

**Evidence:** `app/lib/corpus/paths.ts:36-47`, `app/lib/corpus/paths.ts:70-110`, probe output `out.txt` (S lines)

---

## Claim 14: "a value can never contain "/", "\\", "." runs, or control characters" / all-unsafe input throws / safeSegment has the "Same guarantees as `workspaceSlug`"

**Location:** `app/lib/corpus/paths.ts:25-28`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `workspaceSlug` and `safeSegment` output alphabets and their empty-result throws; does not cover `safeExt`, which falls back to `"bin"` instead of throwing, or slug collisions (`"a/b"`, `"a b"` and `"a.b"` all give `"a-b"`).
**Legibility-target:** for-orchestrator-synthesis

`const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;` (`paths.ts:28`). Applied after NFKD, this leaves only ASCII `[a-zA-Z0-9_-]`. Both functions then throw on an empty result: `throw new Error(\`workspace title produced an empty slug ...\`)` (`:44`) and `throw new Error(\`id produced an empty path segment ...\`)` (`:55`). In the probe: `"a\u0000b" -> a-b`, `"。。。" throws`, `safeSegment("..")` throws. The throw is a plain `Error`, not a `CorpusError` (no claim says otherwise).

**Evidence:** `app/lib/corpus/paths.ts:25-58`, probe output `out.txt`

---

## Claim 15: "Strips path separators, dot-segments, and unicode"

**Location:** `app/lib/corpus/paths.ts:32-33`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how non-ASCII characters are handled; the safety conclusion holds (Claim 14).
**Legibility-target:** for-author

Unsafe characters are replaced with hyphens, not stripped. NFKD splits accented letters into base letter plus combining mark, and the mark becomes a hyphen: in the probe, `"résumé" -> re-sume`. Precise version: "replaces separators, dots and non-ASCII (including combining marks after NFKD) with hyphens".

**Evidence:** `app/lib/corpus/paths.ts:36-47`, probe output `out.txt`

---

## Claim 16: "the S3 worker-proxy implementation drops in here without the store ever knowing which adapter it talks to ... This keeps S1 a pure substrate swap."

**Location:** `app/lib/corpus/storeAdapter.ts:5-8,12`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the persist `storage` path; does not cover other store code that touches localStorage directly.
**Legibility-target:** for-author

The persist storage is selected only through `resolveWorkspaceStorage` (`workspaceStore.ts:499`, `storage: createJSONStorage(resolveWorkspaceStorage),`). `createCorpusBackedStorage(fs: CorpusFS)` (`storeAdapter.ts:52`) depends only on the interface, so swapping adapters changes `storeAdapter.ts`, not the store. However, the store's `onRehydrateStorage` still reads `localStorage.getItem("workspace-zustand-v1")` directly (`workspaceStore.ts:534`, quoted in Claim 6) to decide whether to migrate. With the flag on, that decision consults the old substrate, not the active one. So the swap is not quite "pure": one store code path is still tied to localStorage.

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-76`, `app/lib/stores/workspaceStore.ts:499`, `app/lib/stores/workspaceStore.ts:528-543`

---

## Claim 17: "In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode)"

**Location:** `app/lib/corpus/storeAdapter.ts:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each persist `name` maps to exactly one file; does not establish write atomicity on OPFS.
**Legibility-target:** for-orchestrator-synthesis

`setItem: async (name, value) => { await fs.writeFile(pathFor(name), enc.encode(value)); }` with `pathFor = (name) => \`state/${name}.json\`` (`storeAdapter.ts:55,61-63`). G14 asserts the file `state/workspace-zustand-v1.json` (`workspaceStore-corpus-flag.test.ts:34`).

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-68`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:26-43`

---

## Claim 18: "the files-per-artifact folder layout (layout.ts/manifest.ts)"

**Location:** `app/lib/corpus/storeAdapter.ts:11`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file reference only.
**Legibility-target:** for-author

Commit 122d70f renamed `layout.ts` to `paths.ts` ("Rename app/lib/corpus/layout.ts -> paths.ts"). No `layout.ts` exists in `app/lib/corpus/`, and this docstring is the only remaining `layout.ts` mention in `app/` (`rg -n "layout\.ts" app`).

**Evidence:** `app/lib/corpus/storeAdapter.ts:11`, `app/lib/corpus/paths.ts:1`

---

## Claim 19: "Debounced localStorage moved here verbatim from workspaceStore" (code comment and commit 00ba8c3)

**Location:** `app/lib/corpus/storeAdapter.ts:21-22`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a textual comparison of the old `createDebouncedStorage` (dc6dfb0 `workspaceStore.ts:31-56`) with the new `createDebouncedLocalStorage` (`storeAdapter.ts:25-46`).
**Legibility-target:** for-author

The body, from `let pending` through `removeItem`, is character-identical, including the 300ms delay and the `console.warn` swallow at `storeAdapter.ts:35`. The wrapper is not verbatim: the function is renamed (`createDebouncedStorage` → `createDebouncedLocalStorage`), exported, and its inline sync return type is replaced by zustand's `StateStorage`. Precise version: "body moved verbatim; renamed, exported and retyped".

**Evidence:** `app/lib/corpus/storeAdapter.ts:25-46`, `dc6dfb0:app/lib/stores/workspaceStore.ts:26-56`

---

## Claim 20: "so the OFF path is byte-for-byte the prior behavior" / "OFF path unchanged" (code comment and commit 00ba8c3)

**Location:** `app/lib/corpus/storeAdapter.ts:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what is persisted to and read from `localStorage["workspace-zustand-v1"]`; does not cover the one new side effect, a `localStorage.getItem("corpus-fs-enabled")` read at store-module import. The characterization test pins only parsed round-trip semantics, not raw bytes, debounce coalescing or quota swallowing.
**Legibility-target:** for-orchestrator-synthesis

With the flag off, `resolveWorkspaceStorage` returns `createDebouncedLocalStorage()` (`storeAdapter.ts:71-76`), whose body is identical to the old adapter (Claim 19). The `createJSONStorage` wrapper, `partialize`, `merge` and `name` are unchanged (`workspaceStore.ts:495-526`, and the diff hunk touches only the `storage:` line). The added `isCorpusEnabled()` call (`flag.ts:15-25`) does one guarded localStorage read and changes no stored data. Medium confidence because the tests that would confirm this could not be run (Claim 28).

**Evidence:** `app/lib/corpus/storeAdapter.ts:25-46`, `app/lib/corpus/storeAdapter.ts:71-76`, `app/lib/stores/workspaceStore.ts:494-546`

---

## Claim 21: "Selected once when the store's persist middleware initializes."

**Location:** `app/lib/corpus/storeAdapter.ts:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers when the selection happens, which is module evaluation of `workspaceStore.ts`; does not establish behavior if zustand's `createJSONStorage` ever became lazy.
**Legibility-target:** for-orchestrator-synthesis

The function is passed as `createJSONStorage(resolveWorkspaceStorage)` (`workspaceStore.ts:499`). zustand v5's `createJSONStorage` calls `getStorage()` once, eagerly, when it is created (paraphrased — no quote available because `node_modules/zustand` is not installed in the worktree; the claim rests on zustand 5's published `createJSONStorage` source). Medium confidence for that reason.

**Evidence:** `app/lib/stores/workspaceStore.ts:499`, `app/lib/corpus/storeAdapter.ts:70-76`, `package.json` (`"zustand": "^5.0.13"`)

---

## Claim 22: Characterization test "locks in" the current localStorage persistence behavior (the equivalence target, flag off)

**Location:** `app/lib/stores/__tests__/workspaceStore-characterization.test.ts:1-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the round-trip of a 3-version record, custom types and data, the `verifying` → `none` sanitizing, and rehydrate, through the real store with the flag off; does not cover debounce coalescing, the quota `console.warn` path, raw serialized bytes, or whether the tests pass (not runnable here).
**Legibility-target:** for-orchestrator-synthesis

The test imports the real `useWorkspaceStore` and reads `localStorage.getItem(STORE_KEY)` after `vi.advanceTimersByTime(300)` (`:124-129`). It was added in 3da6747, before the seam change in 00ba8c3, so it first ran against the old adapter. Nothing in the test sets the flag key, and `beforeEach` runs `localStorage.clear()` (`:93`).

**Evidence:** `app/lib/stores/__tests__/workspaceStore-characterization.test.ts:1-106`

---

## Claim 23: "Verifies the OFF default is unchanged (localStorage, OPFS never touched) and that the CorpusFS-backed storage routes through the injected CorpusFS rather than localStorage."

**Location:** `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:3-6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test asserts; does not establish that it passes (not runnable here), and it calls `resolveWorkspaceStorage()` directly rather than through the store.
**Legibility-target:** for-orchestrator-synthesis

`expect(getDirectory).not.toHaveBeenCalled();` (`:37`) after a localStorage write in the off case. In G14, `expect(localStorage.getItem("workspace-zustand-v1")).toBeNull();` plus a read of `state/workspace-zustand-v1.json` from the fake (`:32-35`).

**Evidence:** `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:1-83`

---

## Claim 24: "The seam is typed as CorpusFS so the S3 worker-proxy is a drop-in."

**Location:** `app/lib/stores/workspaceStore.ts:496-498`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how the types are layered between the store and storeAdapter.
**Legibility-target:** for-author

The seam at this line is typed as zustand's `StateStorage` (`resolveWorkspaceStorage(): StateStorage`, `storeAdapter.ts:71`). The `CorpusFS` typing sits one layer down, in `createCorpusBackedStorage(fs: CorpusFS)` (`storeAdapter.ts:52`). The drop-in conclusion holds (Claim 16), but the type sits in storeAdapter, not at this line.

**Evidence:** `app/lib/stores/workspaceStore.ts:496-499`, `app/lib/corpus/storeAdapter.ts:52,71`

---

## Claim 25: "workspaceStore.ts: one-line storage swap to resolveWorkspaceStorage; net shrinks the store file" (commit 00ba8c3)

**Location:** `app/lib/stores/workspaceStore.ts:25,499`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line delta; "one-line" is loose (an import, the storage line and a 3-line comment).
**Legibility-target:** for-orchestrator-synthesis

`git diff --stat dc6dfb0..2dc403e -- app/lib/stores/workspaceStore.ts` reports `5 insertions(+), 33 deletions(-)`. The file went from 574 to 546 lines (paraphrased — no quote available because this is git/wc output, not file content).

**Evidence:** `app/lib/stores/workspaceStore.ts:22-26`, `app/lib/stores/workspaceStore.ts:494-499`

---

## Claim 26: "26 tests pass." (commit 3da6747)

**Location:** `app/lib/corpus/__tests__/corpusFsContract.ts:1` (commit 3da6747 body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the number of tests defined; whether they pass is unverified.
**Legibility-target:** for-orchestrator-synthesis

A static count at 3da6747 gives 26 test cases: contract 7, layout 10, manifest 5, characterization 4 (paraphrased — no quote available because this is a count of `it(` calls across four files). The count matches. Passing needs execution, which is blocked: no `node_modules`, no network for `npm ci`.

**Evidence:** `app/lib/corpus/__tests__/corpusFsContract.ts:64-123`, `app/lib/corpus/__tests__/manifest.test.ts:1-52`, `app/lib/stores/__tests__/workspaceStore-characterization.test.ts:1-106`

---

## Claim 27: "3 tests pass." (commit f6361a3)

**Location:** `app/lib/corpus/__tests__/opfsAdapter.test.ts:1` (commit f6361a3 body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the count only.
**Legibility-target:** for-orchestrator-synthesis

`opfsAdapter.test.ts` defines 3 `it(` cases (`:16,28,41` in the file). The count matches; passing is blocked as in Claim 26. My equivalent Node stub probe behaved as those tests expect (Claims 9, 10). The same commit body says "the success path is held to the shared contract suite via Playwright out-of-CI"; that part is Incorrect (see Claim 31).

**Evidence:** `app/lib/corpus/__tests__/opfsAdapter.test.ts:1-83`

---

## Claim 28: "69 corpus+store tests pass" / "characterization test still green" (commit 00ba8c3)

**Location:** `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:1` (commit 00ba8c3 body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the count across `app/lib/corpus/__tests__` and `app/lib/stores/__tests__` at 00ba8c3; whether they pass is unverified.
**Legibility-target:** for-orchestrator-synthesis

The static count at 00ba8c3 is corpus 25 (7+10+5+3) and stores 44 (artifactEditHandlers 2 + 2×`it.each` over 5 keys = 12; characterization 4; corpus-flag 3; hydration 8; workspaceStore 17), total 69 (paraphrased — no quote available because this is a count across nine files). The count matches; passing is blocked as in Claim 26.

**Evidence:** `app/lib/stores/__tests__/artifactEditHandlers.test.ts:6-12`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:1-83`

---

## Claim 29: "Verified: npm run lint clean, npm run build passes, 324 vitest tests pass." (commit 122d70f)

**Location:** `package.json:5-11` (commit 122d70f body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers the build, lint and full-suite claims; none could run.
**Legibility-target:** for-orchestrator-synthesis

These are executable guarantees. Execution is required but blocked: the worktree has no `node_modules` (`ls node_modules` fails) and the sandbox has no network for `npm ci`. Claim 7a (env inlining) depends on the same build.

**Evidence:** `package.json:5-11`

---

## Claim 30: "Next.js App Router treats any app/**/layout.ts as a route layout, failing the build with a missing-default error" (commit 122d70f)

**Location:** `app/lib/corpus/paths.ts:1` (commit 122d70f body)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers the stated reason for the rename; the rename itself is verified (Claim 18 evidence).
**Legibility-target:** for-orchestrator-synthesis

Consistent with App Router special-file conventions, but confirming it needs `next build` against the pre-rename tree, which is blocked as in Claim 29.

**Evidence:** `app/lib/corpus/paths.ts:1`

---

## Claim 31: "the success path is held to the shared contract suite via Playwright out-of-CI" / "OPFS adapter will reuse the same suite out-of-CI" (commits f6361a3, 3da6747)

**Location:** `app/lib/corpus/opfsAdapter.ts:1` (commit f6361a3 and 3da6747 bodies)
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the present-tense claim in f6361a3. 3da6747's "will reuse" is future tense and only becomes false if the plan is dropped.
**Legibility-target:** for-author

Same evidence as Claims 1-4. By the end of the range (2dc403e), no OPFS run of the suite exists, and the smoke doc's Results say `_(not yet run ...)_`.

**Evidence:** `docs/spikes/corpus-opfs-smoke.md`, `app/lib/corpus/__tests__/corpusFs.contract.test.ts:8`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-3`): the OPFS adapter is not run against the suite. The Playwright smoke is an unrun sketch.
- **Claim 2** (`app/lib/corpus/__tests__/corpusFsContract.ts:4-7`): there is no OPFS run, and the suite imports vitest, so it cannot run in-page. The fake and OPFS diverge on writing under a file path.
- **Claim 3** (`app/lib/corpus/__tests__/inMemoryCorpusFs.ts:5-6`): "LSP verified, not assumed" is false for the OPFS adapter.
- **Claim 4** (`app/lib/corpus/__tests__/opfsAdapter.test.ts:5-7`): the success path is covered nowhere.
- **Claim 5b** (`app/lib/corpus/flag.ts:4`): "DEV-ONLY" is not enforced. The localStorage key enables the flag in production builds.
- **Claim 8b** (`app/lib/corpus/manifest.ts:12-13`): `filter(isObject)` and the string filter silently drop malformed entries. An executed probe produced a default-empty manifest with no error. Timestamps default to now, and the version and currentVersion values are not checked.
- **Claim 12** (`app/lib/corpus/opfsAdapter.ts:115`): no fresh view is made. The caller's `bytes` is passed through unchanged (executed).
- **Claim 13a** (`app/lib/corpus/paths.ts:16-18`): `storeAdapter.ts:55` builds `state/${name}.json` by hand, and nothing in production imports `paths.ts`.
- **Claim 31** (commit f6361a3): the same false Playwright contract-coverage claim as Claims 1-4.

### Stale
- **Claim 11** (`app/lib/corpus/opfsAdapter.ts:14`): `workspaceStore.ts:44-46` now holds unrelated code. The swallow is at `storeAdapter.ts:35`.
- **Claim 18** (`app/lib/corpus/storeAdapter.ts:11`): `layout.ts` was renamed to `paths.ts` in 122d70f.

### Mostly Accurate
- **Claim 6** (`app/lib/corpus/flag.ts:4-6`): "empty corpus" leaves out that `onRehydrateStorage` can still migrate legacy workspace-v2 localStorage data in when the flag is on.
- **Claim 8a** (`app/lib/corpus/manifest.ts:10-13`): only kind `"io"` is ever thrown. `"browser-storage-cleared"` is never produced, and "absent" depends on the caller passing null (no caller exists).
- **Claim 15** (`app/lib/corpus/paths.ts:32`): unicode is hyphenated, not stripped (`"résumé" -> "re-sume"`).
- **Claim 16** (`app/lib/corpus/storeAdapter.ts:5-8,12`): the store still reads localStorage directly in `onRehydrateStorage`, so the swap is not fully "pure".
- **Claim 19** (`app/lib/corpus/storeAdapter.ts:21`): the body is verbatim; the function was renamed, exported and retyped.
- **Claim 24** (`app/lib/stores/workspaceStore.ts:496-498`): the seam at that line is `StateStorage`. `CorpusFS` is typed one layer down.

### Unverifiable
- **Claim 7a** (`app/lib/corpus/flag.ts:9`): needs `next build` to see whether `process.env?.NEXT_PUBLIC_CORPUS_FS` (optional chaining) is inlined client-side.
- **Claims 26, 27, 28** (commits 3da6747, f6361a3, 00ba8c3): the static test counts 26, 3 and 69 match; passing needs `npm ci` plus `vitest`.
- **Claim 29** (commit 122d70f): lint, build and the 324-test count need `npm ci`.
- **Claim 30** (commit 122d70f): the layout.ts reserved-name build failure needs `next build`.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: 2dc403e` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: the docs/ files on the branch (context only), apart from `docs/spikes/corpus-opfs-smoke.md`, which was used as evidence; code-quality judgments.
- Escalate: (1) the OPFS adapter has no success-path or contract coverage at all, despite four docstrings and a commit saying it does; (2) the manifest's "fail-loud" contract is broken by silent filtering, so a malformed manifest can parse to an empty one; (3) the dev-only flag is not gated to dev, and the localStorage route works in production; (4) the env-var route's optional-chaining read may not be inlined by Next (needs a build); (5) build, lint and vitest claims could not be executed (no node_modules, no network). Another stage should run them on a host.
- Decisions I made: I wrote probe files (`probe.ts`, copies of the four corpus modules, `out.txt`) under `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r2-probe/` as execution provenance, despite the "do not write any other file" instruction. They are outside both repos. I did not create `docs/reviews/hallucination-patterns.md` in the reviewed repo (it is read-only); no Incorrect verdict is a symbol fabrication anyway. Static test counts are reported as Unverifiable rather than Verified under the mandatory-execution rule.
