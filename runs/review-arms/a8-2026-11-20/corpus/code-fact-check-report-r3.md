Commit: 2dc403e

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-corpus`, detached HEAD 2dc403e)
**Scope:** `git diff dc6dfb0..2dc403e -- app/` (15 files) plus the bodies of commits ec7bbbc, 3da6747, f6361a3, 00ba8c3, 122d70f; replicate r3 of 3
**Checked:** 2026-11-19
**Total claims checked:** 22
**Summary:** 9 verified, 4 mostly accurate, 2 stale, 5 incorrect, 2 unverifiable

Notes on method: the worktree has no `node_modules`, so vitest, `next build` and `eslint` could not run. Pure-TS modules (`manifest.ts`, `paths.ts`, `types.ts`) were copied to a scratch dir (imports rewritten to `./types.ts`) and run under `node --experimental-strip-types` (Node v22.23.2). `docs/reviews/hallucination-patterns.md` does not exist in the reviewed repo, so there were no prior patterns to compare against.

---

## Claim 1: "The OPFS adapter is held to the same suite out-of-CI (Playwright)" (and siblings: "the fake and the adapter are held to identical behavior (substitutability)"; "both asserted against the same shared contract suite ... so substitutability (LSP) is verified, not assumed"; "The adapter's *success* path is covered by the shared CorpusFS contract suite run against real OPFS out-of-CI")

**Location:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-3`, `app/lib/corpus/__tests__/corpusFsContract.ts:4-7`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:4-6`, `app/lib/corpus/__tests__/opfsAdapter.test.ts:4-7`; commit f6361a3 body ("the success path is held to the shared contract suite via Playwright out-of-CI")
**Type:** Architectural / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether any harness runs `defineCorpusFsContract` (or its cases) against `createOpfsCorpusFs()` at 2dc403e; does not establish whether the OPFS adapter would pass such a run.
**Legibility-target:** for-author

The only invocation of the contract suite is against the fake:

```ts
// app/lib/corpus/__tests__/corpusFs.contract.test.ts:8
defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());
```

`rg defineCorpusFsContract` finds no other call site (paraphrased — no quote available because the claim covers absence of code: no matching grep results in `app/` or `docs/`). The Playwright harness the docstrings point to is an unrun sketch that does not import the suite and lists only six behaviors:

```md
// docs/spikes/corpus-opfs-smoke.md
**Status:** manual, pre-merge before the corpus flag is ever defaulted on. Not wired into CI ...
node /tmp/corpus-smoke/runner.mjs   # asserts the 6 behaviors, prints per-op result
## Results
_(not yet run — fill in when executed before enabling the flag in a shared environment)_
```

Its six behaviors omit the suite's "overwrites an existing file in place" case (`corpusFsContract.ts:119-123`). The suite is also vitest-bound (`import { describe, it, expect, beforeEach } from "vitest"`, `corpusFsContract.ts:53`), so it cannot be dropped into the sketched `page.evaluate` runner as-is. Nothing has asserted the OPFS adapter against the contract, so "verified, not assumed" is false at this commit. The two implementations also differ on cases the suite does not cover (paraphrased — no quote available because the divergence is inferred from reading both implementations): the fake lets "a" be both a file and a directory prefix and makes `rm` of a directory a silent no-op, while the adapter's `getDirectoryHandle(d, {create:true})` / `removeEntry(name)` would reject on those inputs and surface `{kind:"io"}` through `wrap`.

**Evidence:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:8`, `app/lib/corpus/__tests__/corpusFsContract.ts:53,119-123`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:156-177`, `app/lib/corpus/opfsAdapter.ts:628-645,701-716`, `docs/spikes/corpus-opfs-smoke.md`

---

## Claim 2a: "DEFAULT OFF"

**Location:** `app/lib/corpus/flag.ts:4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `isCorpusEnabled()` returning false when neither the env var nor the localStorage key is set; does not establish build-time env inlining (see Claim 3b).
**Legibility-target:** for-orchestrator-synthesis

```ts
// app/lib/corpus/flag.ts:25-35
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

**Evidence:** `app/lib/corpus/flag.ts:25-35`, `app/lib/corpus/storeAdapter.ts:72-76`

---

## Claim 2b: "DEV-ONLY"

**Location:** `app/lib/corpus/flag.ts:4`
**Type:** Configuration / Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the flag is gated on a development build or environment; does not establish whether any production deployment actually sets either route.
**Legibility-target:** for-author

The function quoted in Claim 2a (`flag.ts:25-35`) has no `NODE_ENV` or dev-build check. Both routes work in a production build: the build-time env var ships to every user, and any user can set `localStorage["corpus-fs-enabled"]="1"` in a production page. "Dev-only" is a usage policy (the docstring goes on: "it must not be turned on for end users"), not a property of the code. A reader who takes "DEV-ONLY" as enforced could set `NEXT_PUBLIC_CORPUS_FS=1` in a deploy, expecting it to be ignored outside dev, and every user would then start from an empty corpus (the docstring's own warning at `flag.ts:4-7`). Precise version: "default off; intended for dev use only, but not gated — either route enables it in any build."

**Evidence:** `app/lib/corpus/flag.ts:4-7,25-35`

---

## Claim 3a: "at runtime in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`" enables the flag

**Location:** `app/lib/corpus/flag.ts:9-10`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the key name and value comparison, and that the resolver picks the OPFS path when the key is set; does not establish timing: the flag is read once, when the store module creates its persist storage, so setting the key needs a reload.
**Legibility-target:** for-orchestrator-synthesis

`export const CORPUS_FLAG_KEY = "corpus-fs-enabled";` (`flag.ts:13`) and `window.localStorage.getItem(CORPUS_FLAG_KEY) === "1"` (`flag.ts:19`). The G15 test sets exactly this key and asserts that `getDirectory` gets called: `localStorage.setItem(CORPUS_FLAG_KEY, "1"); ... expect(getDirectory).toHaveBeenCalled();` (`workspaceStore-corpus-flag.test.ts:47,65`). The resolver is passed to `createJSONStorage(resolveWorkspaceStorage)` at store creation (`workspaceStore.ts:499`), so it runs once per page load (paraphrased — no quote available because the once-per-load timing is zustand v5 `createJSONStorage` behavior, which calls `getStorage()` eagerly, from library knowledge; node_modules is absent so the library source could not be read).

**Evidence:** `app/lib/corpus/flag.ts:13,19`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:45-67`, `app/lib/stores/workspaceStore.ts:499`

---

## Claim 3b: "the build-time env `NEXT_PUBLIC_CORPUS_FS=1`" enables the flag

**Location:** `app/lib/corpus/flag.ts:9`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers the server/Node path, where real `process.env` is read; does not establish the client-bundle path, which decides the store's storage in the browser.
**Legibility-target:** for-orchestrator-synthesis

The check is written with optional chaining: `process.env?.NEXT_PUBLIC_CORPUS_FS === "1"` (`flag.ts:16`). Next.js inlines `NEXT_PUBLIC_*` values into client bundles by matching the literal member expression `process.env.NEXT_PUBLIC_X`. Whether Next 16's compiler (`"next": "^16.2.6"`, `package.json`) also replaces the optional-chain form `process.env?.X` could not be confirmed. If it does not, the env route silently does nothing in the browser, where the store resolves its storage, and works only server-side, where `skipHydration: true` means the storage is never read. This is an executable guarantee. Blocker: execution required, but there is no `node_modules` in the worktree, so `NEXT_PUBLIC_CORPUS_FS=1 npm run build` plus a grep of the client chunk for the inlined value could not run.

**Evidence:** `app/lib/corpus/flag.ts:16`, `package.json` (`next ^16.2.6`), `app/lib/stores/workspaceStore.ts:499-501`

---

## Claim 4a: "A malformed or absent manifest must surface as a typed `CorpusError` of kind "io" or "browser-storage-cleared""

**Location:** `app/lib/corpus/manifest.ts:10-12`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the kinds `parseManifest` can throw; does not establish how any caller handles a `null` read, since no production caller exists.
**Legibility-target:** for-author

Every rejection goes through one helper, which emits only `"io"`:

```ts
// app/lib/corpus/manifest.ts:64-67
function fail(reason: string): never {
  // Manifest parse failure is an i/o-class corruption of the workspace index.
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
}
```

The codec never produces `"browser-storage-cleared"`, and an absent file also maps to `"io"` (`if (bytes === null) fail("manifest file is absent");`, `manifest.ts:75`). `parseManifest` has no caller outside tests (paraphrased — no quote available because the claim covers absence of code: `rg parseManifest app` hits only `manifest.ts:74` and `__tests__/manifest.test.ts`). So "absent manifest surfaces as..." describes the codec only, with no consume site yet. Precise version: "throws `CorpusError{kind:"io"}` for any malformation, including a `null` (absent) input."

**Evidence:** `app/lib/corpus/manifest.ts:64-67,74-75`, `app/lib/corpus/__tests__/manifest.test.ts:229,233`

---

## Claim 4b: "parsing is FAIL-LOUD ... never a silent default-empty manifest that would masquerade as "this workspace has no work in it""

**Location:** `app/lib/corpus/manifest.ts:10-13`
**Type:** Error-handling / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole body of `parseManifest` (`:74-115`) on malformed array entries, missing timestamps and a wrong `manifestVersion`; does not establish caller behavior (none exists).
**Legibility-target:** for-author

The parser fails loudly only on missing top-level fields. Malformed entries are dropped silently, and missing timestamps default to now:

```ts
// app/lib/corpus/manifest.ts:86-91
  const sources: SourceRef[] = Array.isArray(raw.sources)
    ? raw.sources.filter(isObject).map((s) => {
        if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");
        return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
      })
    : fail("missing or invalid field: sources");
```

`artifacts` uses the same `.filter(isObject)` (`:93-94`), and `customTypeIds` uses `.filter((x): x is string => typeof x === "string")` (`:102-103`). Timestamps: `createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString()` (`:109-110`). The value of `manifestVersion` is never checked against `MANIFEST_VERSION` (`:84`). Executed: `parseManifest` on `{manifestVersion:999,title:"t",sources:[1,"x",null],artifacts:[7],customTypeIds:[3,{}]}` returned, with no throw:

```
A {"manifestVersion":999,"title":"t","createdAt":"2026-11-20T01:48:24.274Z","updatedAt":"2026-11-20T01:48:24.274Z","sources":[],"artifacts":[],"customTypeIds":[]}
```

That is a corrupted index that silently becomes an empty-but-valid manifest, which is exactly the "masquerade as no work" case the docstring rules out. The test at `manifest.test.ts:236-241` passes only because `{id:"x"}` is an object and reaches the `fail` branch.

Command: `timeout 20 node --experimental-strip-types probe.ts`; cwd `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r3-probe` (copies of `manifest.ts`, `types.ts`, `paths.ts` from 2dc403e, imports rewritten to `.ts`); exit 0; 2026-11-20T01:48:24Z.

**Evidence:** `app/lib/corpus/manifest.ts:74-115`, `app/lib/corpus/__tests__/manifest.test.ts:236-241`, `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r3-probe/out.txt`

---

## Claim 5: "any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:"unavailable"}), never a raw `TypeError`"

**Location:** `app/lib/corpus/opfsAdapter.ts:9-11`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all five methods when `navigator`, `navigator.storage` or `getDirectory` is missing; does not establish what happens when `getDirectory` exists but rejects (for example a SecurityError in a private window), which maps to `{kind:"io"}`, not `"unavailable"`.
**Legibility-target:** for-orchestrator-synthesis

```ts
// app/lib/corpus/opfsAdapter.ts:611-617
async function getRoot(): Promise<OpfsDirHandle> {
  const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
  if (!storage || typeof storage.getDirectory !== "function") {
    throw new CorpusError({ kind: "unavailable", reason: "..." });
  }
```

(Line numbers here and below are diff-hunk positions in the shared block; in-file, `getRoot` is at `opfsAdapter.ts:53-59`.) Each method calls `getRoot()` as the first statement inside its `try` and routes the catch through `wrap`, which rethrows a `CorpusError` unchanged: `if (e instanceof CorpusError) throw e;`. Since the methods are `async`, the throw becomes a rejection. The test exercises all five methods (`opfsAdapter.test.ts:288-295`).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:53-59` (getRoot), `wrap()` and the five methods (whole file read), `app/lib/corpus/__tests__/opfsAdapter.test.ts:273-296`

---

## Claim 6: "a quota failure rejects with {kind:"quota-exceeded", substrate:"opfs"} — it is NOT swallowed with console.warn"

**Location:** `app/lib/corpus/opfsAdapter.ts:12-13`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers DOMException quota errors thrown by `createWritable`, `write` or `getFileHandle` during `writeFile`; does not establish real-browser behavior where `close()` in the `finally` might reject with a different error and replace the quota error (real OPFS not run; see Claim 1).
**Legibility-target:** for-orchestrator-synthesis

```ts
// opfsAdapter.ts (wrap)
function wrap(path: string, e: unknown): never {
  if (e instanceof CorpusError) throw e;
  if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
  throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });
}
```

`isQuota` matches `DOMException` named `QuotaExceededError` or `QUOTA_EXCEEDED_ERR`. The G7 test drives the `createWritable` throw (`opfsAdapter.test.ts:306-308,328-329`). There is no `console.warn` in the file (paraphrased — no quote available because the claim covers absence of code: grep finds no `console` in `opfsAdapter.ts`). Medium confidence because, in `writeFile`, a quota rejection from `w.write` goes through `finally { await w.close(); }`, so a throwing `close()` would replace it. Per the streams spec, `close()` on an errored stream rejects with the stored error, so the kind is probably preserved, but this was not run.

**Evidence:** `app/lib/corpus/opfsAdapter.ts` (`isQuota`, `wrap`, `writeFile` — whole unit read), `app/lib/corpus/__tests__/opfsAdapter.test.ts:298-331`

---

## Claim 7: "the way the legacy localStorage adapter does (workspaceStore.ts:44-46)"

**Location:** `app/lib/corpus/opfsAdapter.ts:14`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line reference at HEAD 2dc403e; does not establish anything about the adapter's behavior.
**Legibility-target:** for-author

The reference was correct when written (f6361a3), when `workspaceStore.ts:44-46` held the `catch { console.warn(...) }`. Commit 00ba8c3 moved the adapter out, and those lines now hold artifact-version coercion:

```ts
// app/lib/stores/workspaceStore.ts:44-46 (at 2dc403e)
    id: raw.id,
    content: raw.content,
    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
```

The swallow now lives at `app/lib/corpus/storeAdapter.ts:34-36` (`console.warn("Failed to persist workspace (localStorage quota exceeded):", e);` at `:35`). Fix: point at `storeAdapter.ts:34-36` / `createDebouncedLocalStorage`.

**Evidence:** `app/lib/stores/workspaceStore.ts:44-46`, `git show dc6dfb0:app/lib/stores/workspaceStore.ts` lines 44-46, `app/lib/corpus/storeAdapter.ts:34-36`

---

## Claim 8: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** `app/lib/corpus/opfsAdapter.ts:115`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what is passed to `w.write`; does not establish whether any OPFS implementation actually rejects a caller-shared buffer.
**Legibility-target:** for-author

```ts
// app/lib/corpus/opfsAdapter.ts:114-119 (writeFile inner try)
        try {
          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
          await w.write(bytes);
        } finally {
          await w.close();
        }
```

(excerpt ends inside writeFile; enclosing writeFile continues to its outer `catch (e) { wrap(path, e); }` — read.) The caller's `bytes` is passed unchanged, with no `.slice()`, `new Uint8Array(...)` or copy. It has been this way since f6361a3 (`git show f6361a3:app/lib/corpus/opfsAdapter.ts` shows the same `await w.write(bytes);` under the comment). By contrast, the in-memory fake does copy (`files.set(normalize(path), bytes.slice());`, `inMemoryCorpusFs.ts:158`). Either the comment or the code should change.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:107-125`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:158`

---

## Claim 9: "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`." (also commit ec7bbbc: "single choke point for untrusted titles")

**Location:** `app/lib/corpus/paths.ts:16-19`; commit ec7bbbc body
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which production code builds `CorpusFS` paths at 2dc403e; does not establish that the one hand-built path is exploitable (its `name` is the constant persist key).
**Legibility-target:** for-author

The only production code that builds a `CorpusFS` path does not use this module:

```ts
// app/lib/corpus/storeAdapter.ts:55
  const pathFor = (name: string) => `state/${name}.json`;
```

`paths.ts` has no production importer at all (paraphrased — no quote available because the claim covers absence of code: `rg "lib/corpus" app -g '!**/__tests__/**'` finds only `workspaceStore.ts:25` importing `storeAdapter`). The `state/` prefix is also missing from the module's own layout diagram (`paths.ts:3-13`). So at this commit "the only source of corpus paths" is false, and the guard is not a choke point on the one live path. The title-sanitizing half is accurate as a property of the builders: every builder goes through `workspaceDir` → `workspaceSlug` (`paths.ts:71`). The write-path concatenation should go through a builder, or the docstring should name the `state/` exception.

**Evidence:** `app/lib/corpus/storeAdapter.ts:55`, `app/lib/corpus/paths.ts:3-19,70-72`, `app/lib/stores/workspaceStore.ts:25`

---

## Claim 10: Sanitizer guarantees — "a value can never contain "/", "\\", "." runs, or control characters"; "Strips path separators, dot-segments, and unicode ... Throws if nothing safe remains"; `safeSegment` has the "Same guarantees as `workspaceSlug` but preserves case"

**Location:** `app/lib/corpus/paths.ts:25-35,49-51`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `workspaceSlug` and `safeSegment` output on traversal, backslash, NUL, bidi-override, NFKD-to-dot and full-width inputs; does not establish `safeExt` (which defaults to `"bin"` rather than throwing, as its own doc says) or a slug's length limits.
**Legibility-target:** for-orchestrator-synthesis

`const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;` (`paths.ts:28`) is applied after `.normalize("NFKD")`, so "." and every non-ASCII character are replaced; an empty result throws (`paths.ts:43-45`, `:53-55`). Executed output:

```
S "../etc/passwd" "etc-passwd" "etc-passwd"
S "a\\b" "a-b" "a-b"
S "..." THROWS workspace title produced an empty slug: "..."
S "a\u0000b" "a-b" "a-b"
S "café" "cafe" "cafe"
S "․․" THROWS ...          (U+2024, NFKD → ".")
S "。。。" THROWS ...
S "x‮y" "x-y" "x-y"         (U+202E bidi override)
S "ＡＢ" "ab" "AB"          (case preserved by safeSegment)
```

Command, cwd, exit code and timestamp as in Claim 4b (same probe run).

**Evidence:** `app/lib/corpus/paths.ts:25-58`, `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r3-probe/out.txt`

---

## Claim 11: "The injection seam is typed as `CorpusFS` ... so the S3 worker-proxy implementation drops in here without the store ever knowing which adapter it talks to" (and `workspaceStore.ts:496-498`: "The seam is typed as CorpusFS so the S3 worker-proxy is a drop-in"; commit 00ba8c3: "drops in without store changes")

**Location:** `app/lib/corpus/storeAdapter.ts:5-8`; `app/lib/stores/workspaceStore.ts:496-498`; commit 00ba8c3 body
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the type chain from store to adapter; does not establish that a worker proxy can implement `CorpusFS` as-is.
**Legibility-target:** for-author

The store depends only on `StateStorage` (`storage: createJSONStorage(resolveWorkspaceStorage)`, `workspaceStore.ts:499`). `CorpusFS` is the parameter type one layer down (`export function createCorpusBackedStorage(fs: CorpusFS): StateStorage`, `storeAdapter.ts:52`). The concrete adapter is hard-wired in the resolver:

```ts
// app/lib/corpus/storeAdapter.ts:71-76
export function resolveWorkspaceStorage(): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(createOpfsCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```

So a worker proxy needs an edit in `storeAdapter.ts` but none in the store, which matches "drops in here". The store-file comment's "The seam is typed as CorpusFS" is imprecise: the store's seam is `StateStorage`, and `CorpusFS` is the typed seam inside `storeAdapter.ts`.

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-76`, `app/lib/stores/workspaceStore.ts:496-499`

---

## Claim 12a: "In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode)"

**Location:** `app/lib/corpus/storeAdapter.ts:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the flag-on storage writing one file per persist `name` (the store uses one name); does not establish OPFS write atomicity.
**Legibility-target:** for-orchestrator-synthesis

`const pathFor = (name: string) => \`state/${name}.json\`;` and `await fs.writeFile(pathFor(name), enc.encode(value));` (`storeAdapter.ts:55,61-62`); the store's only persist name is `name: "workspace-zustand-v1"` (`workspaceStore.ts:495`). Test G14 asserts the file at `state/workspace-zustand-v1.json` (`workspaceStore-corpus-flag.test.ts:234`).

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-68`, `app/lib/stores/workspaceStore.ts:495`

---

## Claim 12b: "the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used by the store until S4"

**Location:** `app/lib/corpus/storeAdapter.ts:11`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file name reference; the "not used by the store" half is accurate (see Claim 9: no production importer of `paths.ts` or `manifest.ts`).
**Legibility-target:** for-author

Commit 122d70f renamed `app/lib/corpus/{layout.ts => paths.ts}` (from its `--stat`), so `layout.ts` no longer exists. `docs/thoughts/corpus-fs-seam.md:19` already says "(`paths.ts`/`manifest.ts`)". Fix: `paths.ts/manifest.ts`.

**Evidence:** `app/lib/corpus/storeAdapter.ts:11`, commit 122d70f stat, `docs/thoughts/corpus-fs-seam.md:19`

---

## Claim 13a: "debounced localStorage (moved verbatim from workspaceStore.ts" (also commit 00ba8c3: "Debounced localStorage moved here verbatim from workspaceStore")

**Location:** `app/lib/corpus/storeAdapter.ts:21`; commit 00ba8c3 body
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a text comparison of the old `createDebouncedStorage` (dc6dfb0 `workspaceStore.ts:26-57`) with the new `createDebouncedLocalStorage` (`storeAdapter.ts:20-46`).
**Legibility-target:** for-author

The body (`let pending ...` through `localStorage.removeItem(name);`) is character-identical. Three things changed: the name (`createDebouncedStorage` → `createDebouncedLocalStorage`), the return type (an inline `{getItem; setItem; removeItem}` object type → `StateStorage`), and the header comment ("avoids JSON.stringify on every keystroke" was dropped). Precise version: "body moved unchanged; renamed and retyped."

**Evidence:** `git show dc6dfb0:app/lib/stores/workspaceStore.ts` (lines 26-57), `app/lib/corpus/storeAdapter.ts:20-46`

---

## Claim 13b: "so the OFF path is byte-for-byte the prior behavior" (also commit 00ba8c3: "OFF path unchanged")

**Location:** `app/lib/corpus/storeAdapter.ts:21-22`; commit 00ba8c3 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the storage object the store gets when the flag is off (same functions, same 300 ms debounce, same quota swallow, chosen at the same point in store creation); does not establish the characterization test passing at HEAD (not executable, no node_modules), and the only new off-path side effect is one guarded `localStorage.getItem("corpus-fs-enabled")` read at store creation.
**Legibility-target:** for-orchestrator-synthesis

With the flag off, `resolveWorkspaceStorage()` returns `createDebouncedLocalStorage()` (`storeAdapter.ts:75`), whose body matches the pre-change adapter (Claim 13a). It is passed to `createJSONStorage` exactly where `createDebouncedStorage` used to be (`workspaceStore.ts:499` vs dc6dfb0 `storage: createJSONStorage(createDebouncedStorage)`). The added `isCorpusEnabled()` read is wrapped in `try { ... } catch { return false; }` (`flag.ts:18-22`), so it cannot add a failure mode.

**Evidence:** `app/lib/corpus/storeAdapter.ts:71-76`, `app/lib/corpus/flag.ts:15-25`, `app/lib/stores/workspaceStore.ts:499`

---

## Claim 14: Characterization test "locks in" the current localStorage persistence behavior as the equivalence target (PR intent: it guards the flag-off path)

**Location:** `app/lib/stores/__tests__/workspaceStore-characterization.test.ts:1-8`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which properties the four tests assert; does not establish that they pass at HEAD (not executed).
**Legibility-target:** for-author

The tests assert the content of the persisted round-trip after `vi.advanceTimersByTime(300)`: three versions plus `currentVersionIndex`, custom types and data, the `verifying` → `none` sanitization, and a full rehydrate (`:122-178`). They were committed in 3da6747, before the swap in 00ba8c3, so they really are a pre-change baseline. They do not pin the debounce itself (no assertion that nothing is written before 300 ms, or that rapid writes coalesce), the quota `console.warn` swallow, or `removeItem` cancelling a pending write. So "locks in the existing behavior" covers persisted content and rehydration, not the adapter's timing or failure semantics. Precise version: "pins the persisted shape and rehydrate round-trip."

**Evidence:** `app/lib/stores/__tests__/workspaceStore-characterization.test.ts:1-178`

---

## Claim 15: "one-line storage swap to resolveWorkspaceStorage; net shrinks the store file"

**Location:** commit 00ba8c3 body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line delta of `workspaceStore.ts` in 00ba8c3; "one-line" is loose (one import line and three comment lines were added too), but the conclusion holds.
**Legibility-target:** for-orchestrator-synthesis

The 00ba8c3 `--stat` shows `app/lib/stores/workspaceStore.ts | 38 ++--------` (+5/−33, net −28 lines), matching the hunk in the shared diff (`@@ -22,38 +22,7 @@` removes the adapter; `@@ -524,7 +493,10 @@` swaps the storage line and adds three comment lines).

**Evidence:** commit 00ba8c3 stat, `app/lib/stores/workspaceStore.ts:25,496-499`

---

## Claim 16a: Test counts — "26 tests pass" (3da6747), "3 tests pass" (f6361a3), "69 corpus+store tests pass" (00ba8c3)

**Location:** commit bodies 3da6747, f6361a3, 00ba8c3
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the number of test cases defined (counting `it` / `it.each` expansions) in the stated file sets; whether they pass is Claim 16b.
**Legibility-target:** for-orchestrator-synthesis

Counted with `rg` over `it(`/`it.each(` (paraphrased — no quote available because the counts are aggregated across nine test files):
- 3da6747: contract 7 + layout/paths 10 + manifest 5 + characterization 4 = 26.
- f6361a3: opfsAdapter 3.
- 00ba8c3: corpus 25 (7+10+5+3) + stores 44 (corpus-flag 3, characterization 4, `workspaceStore.test.ts` 17, hydration 8, `artifactEditHandlers.test.ts` 2 + 2×5 `it.each` over 5 `KEYS` = 12) = 69.

**Evidence:** `app/lib/corpus/__tests__/*`, `app/lib/stores/__tests__/*` (`artifactEditHandlers.test.ts:6-12,27,40`)

---

## Claim 16b: The tests "pass"; "Verified: npm run lint clean, npm run build passes, 324 vitest tests pass" (122d70f)

**Location:** commit bodies 3da6747, f6361a3, 00ba8c3, 122d70f
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the attempt; execution was required and blocked.
**Legibility-target:** for-orchestrator-synthesis

These are executable guarantees. Blocker: the reviewed worktree has no `node_modules` (`ls node_modules | wc -l` → 0), and the pass rules forbid installing packages or using the network, so `npm test`, `npm run lint` and `npm run build` could not run. The 324 total was not recounted statically. Running `npm ci && npm run lint && npm run build && npx vitest run` in a provisioned checkout of 2dc403e would settle it. Claim 3b's env-inlining question can be checked in the same build.

**Evidence:** `package.json` (scripts), worktree root listing

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-3`, `corpusFsContract.ts:4-7`, `inMemoryCorpusFs.ts:4-6`, `opfsAdapter.test.ts:4-7`): the OPFS adapter has never been run against the contract suite. The Playwright smoke is an unrun sketch that does not import the suite and omits the overwrite case. Reword as "planned", or run the suite.
- **Claim 2b** (`app/lib/corpus/flag.ts:4`): "DEV-ONLY" is not enforced; both routes work in production builds. Either gate on dev or reword as policy.
- **Claim 4b** (`app/lib/corpus/manifest.ts:10-13`): executed. Malformed array entries are silently dropped, timestamps default to now, and `manifestVersion` is unchecked, so a corrupt manifest parses to an empty valid one.
- **Claim 8** (`app/lib/corpus/opfsAdapter.ts:115`): no fresh view is made; `bytes` is passed unchanged.
- **Claim 9** (`app/lib/corpus/paths.ts:16-19`): `storeAdapter.ts:55` hand-builds `state/${name}.json`, and `paths.ts` has no production importer.

### Stale
- **Claim 7** (`app/lib/corpus/opfsAdapter.ts:14`): `workspaceStore.ts:44-46` is now artifact-version coercion; the swallow is at `storeAdapter.ts:34-36`.
- **Claim 12b** (`app/lib/corpus/storeAdapter.ts:11`): `layout.ts` was renamed to `paths.ts` in 122d70f.

### Mostly Accurate
- **Claim 4a** (`app/lib/corpus/manifest.ts:10-12`): only `"io"` is ever thrown, never `"browser-storage-cleared"`, and the codec has no production caller.
- **Claim 11** (`app/lib/corpus/storeAdapter.ts:5-8`, `workspaceStore.ts:496-498`): the store's seam is `StateStorage`; `CorpusFS` is typed one layer down, and the resolver hard-wires OPFS.
- **Claim 13a** (`app/lib/corpus/storeAdapter.ts:21`): the body is verbatim, but the function was renamed and retyped.
- **Claim 14** (`app/lib/stores/__tests__/workspaceStore-characterization.test.ts:1-8`): pins persisted content and rehydration, not the debounce or quota-swallow behavior.

### Unverifiable
- **Claim 3b** (`app/lib/corpus/flag.ts:9,16`): whether Next 16 inlines `process.env?.NEXT_PUBLIC_CORPUS_FS` (optional chain) into the client bundle; needs a build plus a grep of the client chunk.
- **Claim 16b** (commit bodies): tests pass / lint clean / build passes / 324 tests; needs `npm ci` and a run, blocked by missing `node_modules` and the no-install rule.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: 2dc403e` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: code-quality judgments about the fake/OPFS semantic divergence (noted only as evidence for Claim 1) and the silent-drop parsing (evidence for Claim 4b); these belong to the sibling critics.
- Escalate: (1) Claim 4b: the manifest codec's fail-loud contract is violated in executed tests, and the G11 tests miss it; treat as a correctness finding for synthesis. (2) Claim 3b: the env-var enable route may be a silent no-op on the client because of the `process.env?.` optional chain; needs a provisioned build to confirm. (3) Claims 16b/3b: no reviewer in this pass can run vitest or build (no `node_modules`), so every "tests pass / build passes" claim stays unverified unless the orchestrator runs them in a provisioned checkout. (4) Claim 1: the substitutability claim rests on a smoke test that has never run; the PR intent's "held to one shared contract suite" inherits the same gap.
- Decisions I made: I did not update `docs/reviews/hallucination-patterns.md` (the skill's post-step) because the brief forbids writing other files; none of the Incorrect verdicts are fabricated symbols anyway. The execution probe wrote copies of three source files and its output to `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r3-probe/` (the scratchpad, not the repo) to provide the provenance an executed verdict needs. Line numbers for `opfsAdapter.ts` internals in Claims 5, 6 and 8 mix in-file numbers with shared-block positions where noted; Claim 8's `:115` is the in-file line.
