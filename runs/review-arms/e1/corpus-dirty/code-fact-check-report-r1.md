# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-corpus-dirty)
**Scope:** `git diff dc6dfb0..2dc403e -- app/` (corpus S0/S1 changeset, ~1166 lines) + commit messages ec7bbbc, 3da6747, f6361a3, 00ba8c3, 122d70f. docs/working/** used as evidence only, per brief.
**Checked:** header/docstring claims in app/lib/corpus/{flag,manifest,opfsAdapter,paths,storeAdapter,types}.ts, seam comments in app/lib/stores/workspaceStore.ts, test-file headers, and the five commit messages.
**Total claims checked:** 24
**Summary:** 15 Verified, 4 Mostly accurate, 2 Stale, 2 Incorrect, 1 Unverifiable. The two Incorrect findings are comment/code mismatches, not behavior bugs: paths.ts claims to be "the only source of corpus paths" while storeAdapter.ts hand-builds `state/<name>.json`, and opfsAdapter's write comment describes a "fresh ArrayBuffer view" the code does not create. The two Stale findings are dangling references left by the range's own refactors (a line-number pointer into pre-move workspaceStore.ts; a mention of the renamed layout.ts). All five commit-message test counts reconstruct exactly from static counting.

**Commit:** 2dc403e

## Claim 1: flag.ts — "DEFAULT OFF and DEV-ONLY"

**Location:** app/lib/corpus/flag.ts:4
**Type:** Configuration / invariant
**Verdict:** Mostly accurate
**Confidence:** High — both gates read end-to-end, and the only consumer checked.
**Legibility-target:** for-author

> "DEFAULT OFF and DEV-ONLY. In S1 there is no localStorage->corpus migration" (app/lib/corpus/flag.ts:4)

DEFAULT OFF is verified: with no env var and no localStorage key, `isCorpusEnabled()` falls through to `return false` (app/lib/corpus/flag.ts:24), and the only production consumer defaults to localStorage:

**Evidence:**
```ts
export function resolveWorkspaceStorage(): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(createOpfsCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```
(app/lib/corpus/storeAdapter.ts:71-76)

"DEV-ONLY", however, is policy, not mechanism: nothing in flag.ts checks `NODE_ENV` or otherwise restricts the gate to dev builds. Any end user of a production deployment who runs `localStorage.setItem("corpus-fs-enabled", "1")` (key at flag.ts:13) gets the corpus path, empty-corpus consequence included. The header itself softens this to intent ("it must not be turned on for end users until S4 ships migration", flag.ts:7), so the claim is aspirationally right but the phrase "DEV-ONLY" overstates what the code enforces. Commit 00ba8c3's "dev-only, default-off corpus flag (env or localStorage gate)" carries the same overstatement.

## Claim 2: flag.ts — enable via build-time env `NEXT_PUBLIC_CORPUS_FS=1`

**Location:** app/lib/corpus/flag.ts:9-10 (mechanism at flag.ts:16)
**Type:** Configuration / behavioral
**Verdict:** Unverifiable
**Confidence:** Medium — the mechanism is readable but its interaction with Next.js build-time inlining cannot be confirmed without building.
**Legibility-target:** for-author

> "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime in a dev browser, `localStorage.setItem(\"corpus-fs-enabled\", \"1\")`." (app/lib/corpus/flag.ts:9-10)

The implementation is:

**Evidence:**
```ts
if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
```
(app/lib/corpus/flag.ts:16)

The localStorage half is Verified (flag.ts:17-23 reads `CORPUS_FLAG_KEY` inside try/catch). The env half is the concern. Next.js inlines `NEXT_PUBLIC_*` variables by textual replacement of the literal member expression `process.env.NEXT_PUBLIC_CORPUS_FS`; this file instead uses the optional-chained form `process.env?.NEXT_PUBLIC_CORPUS_FS` plus a `typeof process` guard. Paraphrased — no quote available because the behavior lives in the Next 16 compiler (this worktree has no node_modules for next, and the historical-review rule precludes building): webpack 5's DefinePlugin does handle optional chaining in defined paths, but Turbopack's env inlining and the surviving `typeof process !== "undefined"` guard (which still references a bare `process` in the client bundle after any inlining) make it plausible that in some build configurations the env gate evaluates false in the browser even when `NEXT_PUBLIC_CORPUS_FS=1` was set at build time. `package.json` pins `"next": "^16.2.6"` (package.json:23). No test in the range exercises the env path — workspaceStore-corpus-flag.test.ts covers only the localStorage gate (app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:62). Recommend the author verify the env path in an actual `next build` bundle or switch to the literal `process.env.NEXT_PUBLIC_CORPUS_FS` form.

## Claim 3: flag.ts — "enabling this starts from an EMPTY corpus and does not carry existing localStorage work over"

**Location:** app/lib/corpus/flag.ts:5-7
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The corpus-backed storage reads only from the injected `CorpusFS` — `getItem` is `await fs.readFile(pathFor(name))` (app/lib/corpus/storeAdapter.ts:58) against `state/<name>.json`, a path nothing has ever written when the flag is first enabled. Grep of app/lib/corpus/ shows no code reading `localStorage` for migration purposes; the only localStorage read in the module is the flag key itself (app/lib/corpus/flag.ts:19). The v2→zustand migration in workspaceStore (`onRehydrateStorage` → `migrateFromV2()`, app/lib/stores/workspaceStore.ts:528-543) still reads localStorage directly, but it writes via `setState`, whose persistence then goes to the corpus file, not carrying the zustand localStorage blob over — consistent with "no migration until S4".

**Evidence:**
```ts
getItem: async (name) => {
  const bytes = await fs.readFile(pathFor(name));
  return bytes ? dec.decode(bytes) : null;
},
```
(app/lib/corpus/storeAdapter.ts:57-60)

## Claim 4: manifest.ts — "parsing is FAIL-LOUD ... typed `CorpusError` of kind 'io' or 'browser-storage-cleared', never a silent default-empty manifest"

**Location:** app/lib/corpus/manifest.ts:10-13
**Type:** Behavioral / invariant
**Verdict:** Mostly accurate
**Confidence:** High — every field of `parseManifest` read.
**Legibility-target:** for-author

> "parsing is FAIL-LOUD. A malformed or absent manifest must surface as a typed `CorpusError` of kind \"io\" or \"browser-storage-cleared\", never a silent default-empty manifest" (app/lib/corpus/manifest.ts:10-13)

Three inaccuracies of degree:

1. **The codec can only ever emit kind `"io"`.** The single failure helper hardcodes it:

**Evidence:**
```ts
function fail(reason: string): never {
  // Manifest parse failure is an i/o-class corruption of the workspace index.
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
}
```
(app/lib/corpus/manifest.ts:64-67)

`"browser-storage-cleared"` appears nowhere in manifest.ts outside the docstring (grep: only types.ts:48, types.ts:86 define/describe it). If the intent is that some *caller* maps absence to `browser-storage-cleared`, no such caller exists in the range.

2. **Some fields are silently defaulted**, contra the spirit of "fail-loud": `createdAt`/`updatedAt` fall back to `new Date().toISOString()` when missing or non-string (app/lib/corpus/manifest.ts:109-110), and a source's `label` silently defaults to its `id` (app/lib/corpus/manifest.ts:89).

3. **Malformed entries are silently dropped, not rejected**: `raw.sources.filter(isObject)` (app/lib/corpus/manifest.ts:87) discards non-object array entries before the id/ext check ever runs, and `customTypeIds.filter((x): x is string => ...)` (app/lib/corpus/manifest.ts:103) discards non-string ids. A manifest whose sources array is `["corrupt", "entries"]` parses "successfully" with `sources: []` — a silent partial-empty, which is exactly the data-loss masquerade the docstring warns against, at entry granularity rather than manifest granularity.

The headline claim holds — a wholly malformed or absent manifest (non-JSON, non-object, missing title/manifestVersion/sources/artifacts/customTypeIds, or `null` bytes) always throws (manifest.ts:75-104), never returns a default-empty manifest — hence Mostly accurate rather than Incorrect. Commit ec7bbbc's "fail-loud parse (typed CorpusError, never silent default-empty)" inherits the same caveats.

## Claim 5: manifest.ts — artifact bytes live in files, manifest only points at current version

**Location:** app/lib/corpus/manifest.ts:5-8
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`ArtifactPointer` carries only `{ type, currentVersion }` (app/lib/corpus/manifest.ts:22-25) with the doc "1-based version number whose file is artifacts/<type>/v####.md" (manifest.ts:20-21), matching the builder `artifactVersionPath` → `` `${artifactDir(slug, artifactType)}/v${v}.md` `` with 1-based validation `version < 1` throws (app/lib/corpus/paths.ts:88-94). No artifact content field exists on the manifest types.

## Claim 6: opfsAdapter.ts — SSR/unavailable guard rejects with typed CorpusError, never a raw TypeError

**Location:** app/lib/corpus/opfsAdapter.ts:9-11
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High — every method traced.
**Legibility-target:** for-orchestrator-synthesis

`getRoot()` throws `new CorpusError({ kind: "unavailable", reason: "navigator.storage.getDirectory is not available (SSR or unsupported browser)" })` when `navigator.storage.getDirectory` is absent (app/lib/corpus/opfsAdapter.ts:50-53). All five interface methods call `getRoot()` first inside a try whose catch is `wrap(path, e)`, and `wrap` re-throws CorpusError untouched: `if (e instanceof CorpusError) throw e;` (app/lib/corpus/opfsAdapter.ts:80). Tests assert the kind for `readFile` and rejection-with-CorpusError for the other four methods (app/lib/corpus/__tests__/opfsAdapter.test.ts:26-47).

## Claim 7: opfsAdapter.ts — quota reification, "NOT swallowed with console.warn the way the legacy localStorage adapter does (workspaceStore.ts:44-46)"

**Location:** app/lib/corpus/opfsAdapter.ts:12-14
**Type:** Behavioral + reference
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

> "it is NOT swallowed with console.warn the way the legacy localStorage adapter does (workspaceStore.ts:44-46)." (app/lib/corpus/opfsAdapter.ts:13-14)

The behavioral half is verified: `wrap` maps quota DOMExceptions to a typed error — `if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` (app/lib/corpus/opfsAdapter.ts:81), with `isQuota` matching `"QuotaExceededError" || "QUOTA_EXCEEDED_ERR"` (opfsAdapter.ts:45-47), and no `console.warn` anywhere in the file (grep: zero hits).

The line reference is stale: commit 00ba8c3 (later in this same range) moved the debounced-localStorage adapter out of workspaceStore.ts, so the referenced `console.warn` now lives at app/lib/corpus/storeAdapter.ts:35 (`console.warn("Failed to persist workspace (localStorage quota exceeded):", e)`), while workspaceStore.ts:44-46 is now the body of `coerceArtifactVersion` (returns of `id`/`content`/`createdAt`, app/lib/stores/workspaceStore.ts:44-46). Commit 122d70f touched opfsAdapter but did not fix this pointer.

## Claim 8: opfsAdapter.ts — "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** app/lib/corpus/opfsAdapter.ts:115
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High — one-line comparison of comment and the line below it.
**Legibility-target:** for-author

**Evidence:**
```ts
try {
  // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
  await w.write(bytes);
} finally {
```
(app/lib/corpus/opfsAdapter.ts:114-118)

The comment describes creating a fresh view; the code passes the caller's `bytes` parameter unmodified — no `new Uint8Array(bytes)`, no `.slice()`, no buffer copy exists in `writeFile` (opfsAdapter.ts:107-123). Either a defensive copy was written and later removed, or the comment was drafted for code that never landed. Contrast with the in-memory fake, which does copy and says so accurately: `files.set(normalize(path), bytes.slice());` with comment "Copy so later mutation of the caller's array can't alter stored bytes." (app/lib/corpus/__tests__/inMemoryCorpusFs.ts:26-27). If some OPFS implementations genuinely "dislike shared buffers" (e.g. a Uint8Array over a SharedArrayBuffer), the hazard the comment names is unhandled.

## Claim 9: opfsAdapter.ts — NotFound mapping: null from readFile/stat, [] from readdir, idempotent rm

**Location:** app/lib/corpus/opfsAdapter.ts (behavior claimed in header opfsAdapter.ts:1-14 and interface docs types.ts:113-124)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`isNotFound` matches `NotFoundError || TypeMismatchError` (app/lib/corpus/opfsAdapter.ts:42-44). readFile: missing dir → `if (!dir) return null` (opfsAdapter.ts:92), missing file → `if (isNotFound(e)) return null` (opfsAdapter.ts:97). readdir: `if (!dir) return [];` (opfsAdapter.ts:130). rm: missing parent → `return; // idempotent` (opfsAdapter.ts:144), already-gone entry → `if (isNotFound(e)) return;` (opfsAdapter.ts:148). stat mirrors readFile (opfsAdapter.ts:161-167). The `TypeMismatchError` inclusion is a reasonable widening (path exists but is a directory where a file was expected — treated as not-found); the contract suite asserts the null/[]/idempotent behavior against the fake (app/lib/corpus/__tests__/corpusFsContract.ts:21-28, 49-56).

## Claim 10: paths.ts — "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point"

**Location:** app/lib/corpus/paths.ts:16-19
**Type:** Architectural / invariant
**Verdict:** Incorrect
**Confidence:** High — grepped every non-test corpus module for path construction.
**Legibility-target:** for-author

> "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`." (app/lib/corpus/paths.ts:17-19)

A production corpus module hand-concatenates a corpus path without going through paths.ts:

**Evidence:**
```ts
const pathFor = (name: string) => `state/${name}.json`;
```
(app/lib/corpus/storeAdapter.ts:55)

`storeAdapter.ts` does not import from paths.ts at all (its imports are zustand/middleware, ./types, ./opfsAdapter, ./flag — app/lib/corpus/storeAdapter.ts:15-18), and `state/` is not a location in the layout diagram at paths.ts:4-13 (which lists only settings.json and workspaces/). storeAdapter even documents its own path choice: "stores the persist blob as one file under `state/`" (storeAdapter.ts:49). Practical risk is low — the interpolated `name` is the constant `"workspace-zustand-v1"` (app/lib/stores/workspaceStore.ts:495), not untrusted input — but the factual "only source" invariant is false as of the same changeset that introduced it. Mitigating nuance: the second half (untrusted *workspace titles* pass through `workspaceSlug`) remains true, since no other module touches `workspaces/` paths. Either route the state-blob path through paths.ts or scope the paths.ts claim to workspace-layout paths.

## Claim 11: paths.ts — `workspaceSlug` sanitization guarantees

**Location:** app/lib/corpus/paths.ts:30-35 (and segment doc at paths.ts:26-28)
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Strips path separators, dot-segments, and unicode; collapses runs of unsafe characters to a single hyphen; trims leading/trailing hyphens. Throws if nothing safe remains" (app/lib/corpus/paths.ts:32-34)

The allowlist regex `SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g` (paths.ts:28) excludes `/`, `\`, and `.`, so separators and dot-runs become hyphens; `.normalize("NFKD").replace(SAFE_SEGMENT, "-").replace(/-{2,}/g, "-").replace(/^-+|-+$/g, "")` then collapses and trims (paths.ts:37-42); empty result throws (paths.ts:43-45). An input of `"../.."` reduces to `""` and throws rather than escaping. `safeSegment` applies the same pipeline preserving case (paths.ts:52-58), and `safeExt` strips leading dots and non-alphanumerics, defaulting to `"bin"` as documented (paths.ts:60-64). Ten unit tests cover this (app/lib/corpus/__tests__/paths.test.ts, 10 `it` blocks).

## Claim 12: storeAdapter.ts — debounced localStorage "moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior ... writes are debounced by 300ms"

**Location:** app/lib/corpus/storeAdapter.ts:21-23
**Type:** Behavioral / staleness
**Verdict:** Verified
**Confidence:** High — diffed against the pre-range implementation directly.
**Legibility-target:** for-orchestrator-synthesis

Compared `git show dc6dfb0` side of the range diff for workspaceStore.ts against the current `createDebouncedLocalStorage`: the function body — `getItem: (name) => localStorage.getItem(name)`, the `clearTimeout`/`setTimeout(..., 300)` debounce with the try/catch `console.warn("Failed to persist workspace (localStorage quota exceeded):", e)`, and the `removeItem` that cancels the pending write — is token-for-token identical (removed lines in `git diff dc6dfb0..2dc403e -- app/lib/stores/workspaceStore.ts`, old lines 31-56, vs app/lib/corpus/storeAdapter.ts:25-46). Only the function name (`createDebouncedStorage` → `createDebouncedLocalStorage`) and the return-type annotation (inline object type → `StateStorage`) changed; neither affects behavior. The 300ms figure matches `}, 300);` (storeAdapter.ts:38). Commit 00ba8c3's "Debounced localStorage moved here verbatim from workspaceStore (OFF path unchanged)" is accurate, and the OFF-path routing is additionally locked by the G13 test asserting `getDirectory` is never called (app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:25-37).

## Claim 13: storeAdapter.ts — "the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used by the store until S4"

**Location:** app/lib/corpus/storeAdapter.ts:10-13
**Type:** Reference + architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

> "the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used by the store until S4" (app/lib/corpus/storeAdapter.ts:11-12)

The substantive claim is verified — the store's storage path never imports paths.ts or manifest.ts (storeAdapter imports, storeAdapter.ts:15-18; workspaceStore imports only `resolveWorkspaceStorage`, app/lib/stores/workspaceStore.ts:25), so the layout/manifest modules are indeed built-but-unused by the store. But `layout.ts` no longer exists: commit 122d70f in this same range renamed it (`git log --follow -- app/lib/corpus/paths.ts` shows the rename at 122d70f; `ls app/lib/corpus/` contains paths.ts, no layout.ts). The rename commit updated the test import (app/lib/corpus/__tests__/paths.test.ts:13 `from "../paths"`) but missed this comment. Given the rename rationale — layout.ts is a reserved Next.js filename — a dangling reference to it is worth cleaning up.

## Claim 14: storeAdapter.ts — seam typed as `CorpusFS` so the S3 worker-proxy drops in without store changes

**Location:** app/lib/corpus/storeAdapter.ts:5-8 (echoed at workspaceStore.ts:496-498)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```ts
export function createCorpusBackedStorage(fs: CorpusFS): StateStorage {
```
(app/lib/corpus/storeAdapter.ts:52)

The parameter is the interface type (`import type { CorpusFS } from "./types"`, storeAdapter.ts:16); the only place a concrete adapter is named is the composition point `createCorpusBackedStorage(createOpfsCorpusFs())` inside `resolveWorkspaceStorage` (storeAdapter.ts:73), and workspaceStore binds only to `resolveWorkspaceStorage` (workspaceStore.ts:25, 499). The G14 test exercises the seam with a different implementation (the in-memory fake, workspaceStore-corpus-flag.test.ts:42-43), demonstrating the substitutability the comment claims.

## Claim 15: storeAdapter.ts — "Selected once when the store's persist middleware initializes."

**Location:** app/lib/corpus/storeAdapter.ts:70
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium — zustand is not installed in this worktree (`ls node_modules/zustand` fails), so the claim rests on knowledge of zustand v5 (`"zustand": "^5.0.13"`, package.json:33) rather than read source.
**Legibility-target:** for-author

`resolveWorkspaceStorage` is passed as the getter to `createJSONStorage` (app/lib/stores/workspaceStore.ts:499). Paraphrased — no quote available because zustand's source is not present in the worktree: in zustand v5, `createJSONStorage(getStorage)` invokes `getStorage()` exactly once, eagerly, inside a try/catch when `createJSONStorage` itself runs — which is at module evaluation of workspaceStore.ts (the persist options object is built when `create()` executes at import time), i.e. slightly *before* "the persist middleware initializes" and notably possibly during SSR, where `window` is undefined and only the env half of the flag can select the corpus path. "Once" is right; "when the persist middleware initializes" is approximately right; the flag is consequently *not* re-evaluated when a user sets the localStorage key until the next page load — consistent with the flag docs ("at runtime in a dev browser" implies a reload), but worth the author confirming the SSR-time selection is intended.

## Claim 16: types.ts — "'Not found' is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

**Location:** app/lib/corpus/types.ts:17-18 (method docs at types.ts:113-124)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High — both implementations read end-to-end.
**Legibility-target:** for-orchestrator-synthesis

OPFS adapter: evidence in Claim 9. In-memory fake: `files.get(normalize(path)) ?? null` (app/lib/corpus/__tests__/inMemoryCorpusFs.ts:22) converts Map's `undefined` to `null`; stat returns `bytes ? { size } : null` (inMemoryCorpusFs.ts:50); readdir builds from a Set so a missing dir yields `[]` (inMemoryCorpusFs.ts:33-41). Every non-not-found failure path in the OPFS adapter funnels through `wrap()`, which always throws a `CorpusError` (opfsAdapter.ts:79-83). Contract suite asserts null/[]/idempotency (corpusFsContract.ts:21-28, 49-56).

## Claim 17: types.ts — `CorpusErrorKind` is "the complete set of corpus failure kinds"; CorpusError/CorpusWorkerError "differ only in transport, never in the kind set"

**Location:** app/lib/corpus/types.ts:27-28, 37-49
**Type:** Invariant / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both types bind to the single `CorpusErrorKind` union: `CorpusError.detail: CorpusErrorKind` (types.ts:53) and `CorpusWorkerError = { __corpusError: true; detail: CorpusErrorKind; message: string }` (types.ts:63-67); no second kind enumeration exists (grep for `kind:` string literals outside types.ts finds only constructions of existing kinds). Production status of each kind, per the brief: **produced today** — `io` (opfsAdapter.ts:60,82; manifest.ts:66), `unavailable` (opfsAdapter.ts:52), `quota-exceeded` (opfsAdapter.ts:81). **Not produced by any implementation** — `not-found` (by design: not-found is the null/[] convention, so this kind is currently dead code), `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, `git-conflict` (all reserved for S2/S3 per the header's forward references, types.ts:4-7). The docstring does not claim all kinds are currently emitted, so this is consistent — though the coexistence of a `not-found` *kind* with a "not-found never throws" convention (types.ts:17-18) is a latent ambiguity for S2+ implementers. `describeCorpusError` handles all eight kinds with an `assertNever` default (types.ts:78-90).

## Claim 18: types.ts — "Implementations create intermediate directories on write."

**Location:** app/lib/corpus/types.ts:109-110 (also writeFile doc at types.ts:117)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

OPFS: `writeFile` walks with `walkDir(root, dirs, true)` where `create=true` calls `getDirectoryHandle(d, { create })` per segment (opfsAdapter.ts:111, 70). Fake: directories are implicit — "a file at \"a/b/c.txt\" makes \"a\" and \"a/b\" listable" (inMemoryCorpusFs.ts:8), realized by the prefix-scan readdir. Contract test "creates intermediate directories and lists children at each level" asserts it (corpusFsContract.ts:41-47).

## Claim 19: workspaceStore.ts — "SSR safe: render defaults first, hydrate in useEffect via rehydrate()"

**Location:** app/lib/stores/workspaceStore.ts:500-501
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`skipHydration: true` is set (workspaceStore.ts:501) and the documented caller exists: app/page.tsx:83 calls `useWorkspaceStore.persist.rehydrate();` under the comment "--- SSR hydration: trigger Zustand rehydrate once on mount ---" (app/page.tsx:78). The characterization test exercises the same rehydrate path (workspaceStore-characterization.test.ts:97). Note this comment predates the range; it remains accurate after the seam swap because storage selection happens at module scope where the flag's localStorage half safely returns false without `window` (flag.ts:17,24).

## Claim 20: workspaceStore.ts — "Validate deserialized localStorage data before merging into the store."

**Location:** app/lib/stores/workspaceStore.ts:502-503
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The `merge` option applies `coercePersistedState` behind an `isObject` guard before spreading over current state (workspaceStore.ts:504-507), and `coercePersistedState` type-checks every field, including `coerceDecomposition` reuse for nodes (workspaceStore.ts:98-101) as the comment says. Unchanged by the range except that the data may now arrive from CorpusFS rather than localStorage — the word "localStorage" in the comment is now slightly narrow when the flag is on, but the default path it describes is intact.

## Claim 21: commit ec7bbbc — "per plan-corpus-s1 steps 1-3" and content claims

**Location:** commit ec7bbbc message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

docs/working/plan-corpus-s1.md exists in the worktree with numbered steps; steps 1-3 are exactly the three files this commit created: step 1 "New `app/lib/corpus/types.ts` ... single `CorpusErrorKind` source of truth ... the two differ only in transport, never in the kind set" (plan-corpus-s1.md:21), step 2 "New `app/lib/corpus/layout.ts` ... workspace-slug sanitization that refuses `..`/`/`/traversal" (plan-corpus-s1.md:22), step 3 "New `app/lib/corpus/manifest.ts` ... never a silent empty manifest" (plan-corpus-s1.md:23). The commit's arch-review finding references (1,2) match the plan's annotations (plan-corpus-s1.md:70). One drift, in the plan not the commit: step 6 specified `opfs-quota-exceeded` while the shipped kind is substrate-neutral `quota-exceeded {substrate:"opfs"}` — the plan's own step 1 (finding 1) mandates the substrate-neutral form the code follows.

## Claim 22: commit 3da6747 — "26 tests pass" + characterization content claims

**Location:** commit 3da6747 message
**Type:** Reference / behavioral (static count only, per brief)
**Verdict:** Verified
**Confidence:** Medium — static reconstruction, not a test run (historical worktree; counts reconstructed from `git show 3da6747:<file>`).
**Legibility-target:** for-orchestrator-synthesis

Static count at that commit: corpusFsContract.ts defines 7 `it` blocks, instantiated exactly once (`defineCorpusFsContract("in-memory fake", ...)`, corpusFs.contract.test.ts:8); layout.test.ts 10; manifest.test.ts 5; workspaceStore-characterization.test.ts 4. 7+10+5+4 = 26, matching the claim exactly. The characterization content claims also match: the four tests are precisely "3-version artifact" (test names at workspaceStore-characterization.test.ts:50), "custom types+data" (:67), "transient-state sanitization" (:78), "full rehydrate" (:85). Note the commit says these tests "are red until step 6" was the plan's framing; the commit itself landed them green against the fake.

## Claim 23: commits f6361a3 ("3 tests pass") and 00ba8c3 ("69 corpus+store tests pass", "one-line storage swap; net shrinks the store file")

**Location:** commit f6361a3 and 00ba8c3 messages
**Type:** Reference / behavioral (static count only)
**Verdict:** Verified
**Confidence:** Medium — static counts, not test runs.
**Legibility-target:** for-orchestrator-synthesis

f6361a3: opfsAdapter.test.ts contains exactly 3 `it` blocks (2 unavailable-guard + 1 quota) — matches. 00ba8c3: static `it` lines across app/lib/corpus + app/lib/stores test files at that commit sum to 61, of which 2 are `it.each(KEYS)` in artifactEditHandlers.test.ts (:27, :40) over a 5-element `KEYS` array (artifactEditHandlers.test.ts:6-12) — runtime expansion 61 − 2 + 10 = 69, matching exactly. The "one-line storage swap" is the single changed wiring line `storage: createJSONStorage(resolveWorkspaceStorage)` (workspaceStore.ts:499, replacing `createJSONStorage(createDebouncedStorage)` per the range diff), and the store file shrinks net −29 lines (range diff: 37 removed, 8 added including the new import and seam comment). The commit's G13/G14/G15 test descriptions match the three describe blocks in workspaceStore-corpus-flag.test.ts (:24, :40, :60) — including the G13 spy assertion `expect(getDirectory).not.toHaveBeenCalled()` (:36).

## Claim 24: commit 122d70f — rename rationale ("Next reserved name"), "324 vitest tests pass", "paths.test.ts import updated", writable narrowing

**Location:** commit 122d70f message
**Type:** Reference / configuration / behavioral (static count only)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

- **Rename + rationale**: `git log --follow -- app/lib/corpus/paths.ts` confirms the layout.ts→paths.ts rename at 122d70f. The rationale — "Next.js App Router treats any app/**/layout.ts as a route layout, failing the build with a missing-default error" — is consistent with Next.js App Router file conventions (paraphrased — no quote available because the behavior is in the Next.js framework, not this repo: special filenames like `layout` apply to any directory under `app/`, and a layout without a default React-component export fails the build). The repo is on `"next": "^16.2.6"` (package.json:23) with the corpus module under `app/lib/corpus/`, so the collision is real. Verified at Medium confidence.
- **"paths.test.ts import updated"**: `import { ... } from "../paths"` (app/lib/corpus/__tests__/paths.test.ts:13). Verified.
- **"narrow local OpfsWritable.write to Uint8Array"**: `write(data: Uint8Array): Promise<void>;` (opfsAdapter.ts:28). Verified.
- **"324 vitest tests pass"**: static reconstruction at 122d70f: 309 `it`/`test` lines across all `*.test.ts(x)` files + 8 extra from the two `it.each` over 5 keys + 7 contract-suite tests defined in corpusFsContract.ts (a non-.test file, instantiated once) = 324. Exact match, but this is arithmetic over static declarations, not a run — any conditionally-skipped test would break the equality, hence Mostly accurate rather than Verified for the "pass" half (the *count* reconstructs exactly).
- **Unfixed staleness**: this commit updated seam docs and CLAUDE.md but left the two dangling references found above (Claims 7 and 13) — the opfsAdapter pointer to workspaceStore.ts:44-46 and storeAdapter's mention of layout.ts.

## Claims Requiring Attention

### Incorrect
- **Claim 8** — opfsAdapter.ts:115: comment says a fresh ArrayBuffer view is passed to `write()`; the code passes the caller's `bytes` unmodified. Either add the copy or delete the comment (the fake at inMemoryCorpusFs.ts:26-27 shows the accurate pattern).
- **Claim 10** — paths.ts:17-19: "the only source of corpus paths is this module" is violated by storeAdapter.ts:55's hand-built `state/${name}.json`, which also lies outside the documented layout. Low practical risk (constant input), but the stated invariant is false and `state/` is undocumented in the layout diagram.

### Stale
- **Claim 7** — opfsAdapter.ts:13-14: line reference "(workspaceStore.ts:44-46)" points at code that commit 00ba8c3 (same range) moved to storeAdapter.ts:33-36; the cited lines are now unrelated validation code.
- **Claim 13** — storeAdapter.ts:11-12: references "layout.ts", renamed to paths.ts by 122d70f in the same range.

### Mostly Accurate
- **Claim 1** — flag.ts:4: "DEV-ONLY" is policy, not an enforced mechanism (no NODE_ENV gate; localStorage flag works in production builds).
- **Claim 4** — manifest.ts:10-13: codec can only emit kind `"io"` (never the advertised `"browser-storage-cleared"`); `createdAt`/`updatedAt`/`label` are silently defaulted; malformed sources/artifacts/customTypeIds *entries* are silently filtered out rather than failing loud.
- **Claim 15** — storeAdapter.ts:70: storage is selected at module evaluation (possibly during SSR), slightly earlier than "when the persist middleware initializes"; flag changes require a reload.
- **Claim 24** — 122d70f: test *count* 324 reconstructs exactly, but "pass" is unverifiable statically; commit also left the two stale references above unfixed.

### Unverifiable
- **Claim 2** — flag.ts:9-10/16: whether `process.env?.NEXT_PUBLIC_CORPUS_FS` (optional-chained, behind a `typeof process` guard) is actually inlined by Next 16's build (webpack DefinePlugin vs Turbopack) cannot be confirmed without building; no test covers the env path. Recommend the literal `process.env.NEXT_PUBLIC_CORPUS_FS` form or a build-output check.

## Goal-Alignment Note
- Answered: All 8 brief items — flag header incl. the NEXT_PUBLIC_* inlining question (Claims 1-3), manifest parse/defaults/fail-loud (Claim 4), paths single-choke-point incl. the storeAdapter literal-path grep (Claim 10), moved-verbatim/debounce parity diffed against the pre-range implementation (Claim 12), per-kind production status of CorpusErrorKind (Claim 17), OPFS error-mapping/SSR/invariants (Claims 6-9), workspaceStore seam/skipHydration/validation comments (Claims 14, 19, 20), and all five commit messages incl. plan-step cross-references and static test-count reconstruction, which matched exactly at 26/3/69/324 (Claims 21-24).
- Out of scope: docs/working/** and docs/thoughts/** claim verdicts (used as evidence only, per brief); actually running the vitest suite or `next build` in the historical worktree; test-file-internal prose beyond what the brief's items required; the Playwright smoke doc's claims (docs/spikes/, non-app).
- Escalate: (1) The env half of the flag (Claim 2) is the only enable path available to a production build and is untested and possibly non-functional under Next 16 inlining — if E1's downstream critics assess flag safety, they should treat the localStorage gate as the only verified enable path. (2) The `state/` blob location (Claim 10) is invisible to the documented layout and to S4 migration planning — worth surfacing to the author before S4 assumes all corpus data lives under `workspaces/`.
