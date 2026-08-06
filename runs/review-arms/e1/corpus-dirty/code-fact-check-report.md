# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-corpus-dirty)
**Scope:** `git diff dc6dfb0..2dc403e -- app/` (corpus S0/S1 changeset) + commit messages ec7bbbc, 3da6747, f6361a3, 00ba8c3, 122d70f. docs/working/** used as evidence only, not verdicted. app/ only.
**Checked:** 2026-08-06
**Total claims checked:** 30
**Summary:** 17 Verified, 9 Mostly accurate, 2 Stale, 2 Incorrect, 0 Unverifiable. Merged from three independent replicate reports (most-severe-wins per cluster). All three replicates converge on the same core findings: two Incorrect comment/code mismatches — the paths.ts "only source of corpus paths" invariant violated by storeAdapter.ts's hand-built `state/${name}.json` path, and an opfsAdapter comment describing a "fresh ArrayBuffer view" the code never creates; two dangling references left by the range's own refactors (the layout.ts→paths.ts rename and the debounce-adapter move); a manifest codec that is fail-loud at whole-manifest granularity but silently defaults/drops at field/entry granularity; and a "DEV-ONLY" flag that is policy, not mechanism. All five commit-message test counts (26/3/69/324) reconstruct exactly by static counting in every replicate that checked them.

**Commit:** 2dc403e
**Replication:** k=3 (reports r1, r2, r3 merged mechanically, most-severe verdict wins per cluster; winning replicate's evidence carried)

---

## Claim 1: flag.ts — "DEFAULT OFF and DEV-ONLY"

**Location:** app/lib/corpus/flag.ts:4-10
**Type:** Configuration / invariant
**Verdict:** Mostly accurate
**Confidence:** High — the 10-line implementation and its only consumer read by all replicates.
**Legibility-target:** for-author

DEFAULT OFF is verified: `isCorpusEnabled()` returns `true` only when the env var or the localStorage key equals `"1"`; every other path returns `false` (flag.ts:16-24), and the sole consumer `resolveWorkspaceStorage()` falls back to `createDebouncedLocalStorage()` — pinned by the G13 test asserting `getDirectory` is never called by default (workspaceStore-corpus-flag.test.ts:36). "DEV-ONLY", however, is policy, not mechanism: nothing checks `NODE_ENV` or any dev-mode signal, so any end user of a production deployment who runs `localStorage.setItem("corpus-fs-enabled", "1")` (key at flag.ts:13) flips their persistence to an empty OPFS corpus — exactly the data-abandonment scenario the header warns about. "At runtime in a dev browser" describes the expected operator, not an enforced constraint.

**Evidence:**
```ts
if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
if (typeof window !== "undefined") {
  try {
    return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
  } catch {
    return false;
  }
}
return false;
```
(flag.ts:16-24). No `NODE_ENV` or dev gate appears anywhere in app/lib/corpus/ (zero-match grep).

**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate (r2 additionally verdicted the DEFAULT OFF half in isolation as Verified)

---

## Claim 2: flag.ts — enable via build-time env `NEXT_PUBLIC_CORPUS_FS=1`

**Location:** app/lib/corpus/flag.ts:9-10, 16
**Type:** Configuration / behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium — localStorage path fully verified; the env path depends on Next.js build-time inlining behavior that cannot be confirmed without a build.
**Legibility-target:** for-author

The localStorage half is verified end-to-end: key constant matches (`CORPUS_FLAG_KEY = "corpus-fs-enabled"`, flag.ts:13) and the G15 test proves setting it routes to OPFS (workspaceStore-corpus-flag.test.ts:62-80). The env half is risky: Next.js inlines `NEXT_PUBLIC_*` variables by textual replacement of the literal member expression `process.env.NEXT_PUBLIC_CORPUS_FS`, but this file uses **optional chaining** (`process.env?.NEXT_PUBLIC_CORPUS_FS`) behind a `typeof process` guard. Paraphrased — no quote available because this depends on Next.js/webpack DefinePlugin behavior outside the repo: webpack 5 added optional-chaining support to DefinePlugin, so replacement likely still occurs on webpack builds, but this is not guaranteed under Turbopack (`"next": "^16.2.6"`, package.json:23). If inlining fails, the client-bundle env gate silently never works. No test or config in the repo exercises the env path — `NEXT_PUBLIC_CORPUS_FS` appears only in flag.ts and docs; workspaceStore-corpus-flag.test.ts covers only the localStorage gate.

**Evidence:** flag.ts:16 (`if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;`); package.json:23.

**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Mostly accurate

---

## Claim 3: flag.ts — no localStorage→corpus migration in S1; enabling starts from an EMPTY corpus

**Location:** app/lib/corpus/flag.ts:4-7
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The corpus-backed storage reads only from the injected `CorpusFS` — `getItem` is `await fs.readFile(pathFor(name))` against `state/<name>.json`, a path nothing has written when the flag is first enabled, so a fresh OPFS root yields `getItem → null` → the store renders defaults. No file in app/lib/corpus/ reads the legacy localStorage keys for migration; the only localStorage read in the module is the flag key itself (flag.ts:19). The plan confirms migration is S4 (docs/working/plan-corpus-s1.md:75, evidence only).

**Evidence:**
```ts
getItem: async (name) => {
  const bytes = await fs.readFile(pathFor(name));
  return bytes ? dec.decode(bytes) : null;
},
```
(app/lib/corpus/storeAdapter.ts:57-60)

**Replicate verdicts:** r1=Verified · r2=Verified · r3=—

---

## Claim 4: manifest.ts — parsing is "FAIL-LOUD", surfacing kind "io" or "browser-storage-cleared", never a silent default-empty manifest

**Location:** app/lib/corpus/manifest.ts:10-13
**Type:** Behavioral / invariant
**Verdict:** Mostly accurate
**Confidence:** High — every field of `parseManifest` read.
**Legibility-target:** for-author

Three inaccuracies of degree, agreed by all replicates:

1. **The codec can only ever emit kind `"io"`.** The single failure helper hardcodes it; `"browser-storage-cleared"` appears nowhere outside the docstring and its declaration (types.ts:48, 86). If a caller is meant to map absence to `browser-storage-cleared`, no such caller exists in the range.
2. **Silent defaults**: `createdAt`/`updatedAt` fall back to `new Date().toISOString()` (manifest.ts:109-110); a source's `label` silently defaults to its `id` (manifest.ts:89).
3. **Malformed entries silently dropped**: `raw.sources.filter(isObject)` (manifest.ts:87) and `raw.artifacts.filter(isObject)` (manifest.ts:94) discard non-object entries before the id/ext check runs; non-string `customTypeIds` entries are dropped (manifest.ts:103). A manifest whose sources array is `["corrupt", "entries"]` parses "successfully" with `sources: []` — entry-level data loss masquerading as no work, the exact failure the header warns against.

The headline claim holds — a wholly malformed or absent manifest always throws (manifest.ts:75-104), never returns a default-empty manifest, and the G11 test asserts `detail.kind === "io"` (manifest.test.ts:39) — hence Mostly accurate rather than Incorrect.

**Evidence:**
```ts
function fail(reason: string): never {
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
}
```
(manifest.ts:64-67)

**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

---

## Claim 5: manifest.ts — `parseManifest` docstring: "Throws a `CorpusError` on any malformation"; null input is itself an error

**Location:** app/lib/corpus/manifest.ts:69-73
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High — every field of the return object traced to its validation (or lack of one).
**Legibility-target:** for-author

The null-input clause is verified: `if (bytes === null) fail("manifest file is absent");` (manifest.ts:75), tested at manifest.test.ts:43. But "any malformation" is overstated at the entry/field level: non-object entries in `sources`/`artifacts` are silently discarded (manifest.ts:87, 94), non-string `customTypeIds` entries silently dropped (manifest.ts:103), `label`/`createdAt`/`updatedAt` silently defaulted (manifest.ts:89, 109-110), and `manifestVersion` is type-checked but never range-checked against `MANIFEST_VERSION` (manifest.ts:84) — a future v2 manifest parses as v1 without complaint. Present-object-but-missing-field entries do throw (manifest.ts:88, 96).

**Evidence:** manifest.ts:87 (`raw.sources.filter(isObject).map(...)`); manifest.ts:84; manifest.ts:75.

**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Verified (r3 verdicted the null-input clause; r2 flagged the "any malformation" clause — most severe wins)

---

## Claim 6: manifest.ts — artifact bytes live in files; manifest only points at current version

**Location:** app/lib/corpus/manifest.ts:5-8
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`ArtifactPointer` carries only `{ type, currentVersion }` (manifest.ts:22-25) with the doc "1-based version number whose file is artifacts/<type>/v####.md" (manifest.ts:20-21), matching `artifactVersionPath` → `` `${artifactDir(slug, artifactType)}/v${v}.md` `` with 1-based validation (`version < 1` throws, paths.ts:88-94). No artifact content field exists on the manifest types.

**Evidence:** manifest.ts:22-25; paths.ts:88-94.

**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection

---

## Claim 7: paths.ts — layout diagram matches the builders

**Location:** app/lib/corpus/paths.ts:4-13
**Type:** Architectural / reference
**Verdict:** Verified
**Confidence:** High — every builder output compared to the diagram; test file pins exact strings.
**Legibility-target:** for-orchestrator-synthesis

Each diagram line has a corresponding builder producing exactly that shape: `SETTINGS_PATH = "settings.json"` (paths.ts:68), `workspaceManifestPath` → `workspaces/<slug>/workspace.json` (paths.ts:74-76), `sourcePath` (paths.ts:78-80), `artifactVersionPath` zero-padded via `VERSION_PAD = 4` (paths.ts:23, 88-94), `artifactMetaPath` (paths.ts:96-98), `customTypePath` (paths.ts:100-102), `decompositionGraphLayoutPath` (paths.ts:108-110). Pinned by paths.test.ts:47-66.

**Evidence:** `expect(artifactVersionPath(s, "semiformal", 1)).toBe("workspaces/my-slug/artifacts/semiformal/v0001.md")` (paths.test.ts:55).

**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection

---

## Claim 8: paths.ts — "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point"

**Location:** app/lib/corpus/paths.ts:16-19
**Type:** Architectural / invariant
**Verdict:** Incorrect
**Confidence:** High — every non-test corpus module grepped for path construction in all three replicates.
**Legibility-target:** for-author

> "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`." (paths.ts:17-19)

A production corpus module hand-concatenates a corpus path without going through paths.ts:

**Evidence:**
```ts
const pathFor = (name: string) => `state/${name}.json`;
```
(app/lib/corpus/storeAdapter.ts:55)

`storeAdapter.ts` does not import from paths.ts at all (imports at storeAdapter.ts:15-18 are zustand/middleware, ./types, ./opfsAdapter, ./flag), this is a real write path (`createCorpusBackedStorage` writes the entire persist blob there, storeAdapter.ts:61-63; G14 test confirms bytes land at `state/workspace-zustand-v1.json`), and `state/` is not a location in the layout diagram at paths.ts:4-13. True when written (ec7bbbc, no other corpus module existed); invalidated by 00ba8c3 later in the same range. Practical risk is low — the interpolated `name` is the compile-time constant `"workspace-zustand-v1"` (workspaceStore.ts:495), not untrusted input — so the security half (untrusted *workspace titles* pass through `workspaceSlug`) survives. But the categorical "only source of corpus paths" invariant is false at 2dc403e, and the drift matters because S2's FSA mirror will replay whatever paths exist — an undocumented top-level `state/` directory would silently appear in the user's mirrored folder. Either route the state-blob path through paths.ts or scope the paths.ts claim to workspace-layout paths.

**Replicate verdicts:** r1=Incorrect · r2=Stale · r3=Incorrect

---

## Claim 9: paths.ts — `workspaceSlug`/`safeSegment` sanitization guarantees

**Location:** app/lib/corpus/paths.ts:26-35, 49-51
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g` (paths.ts:28) excludes `/`, `\`, `.`, and control characters, so separators and dot-runs become hyphens; `.normalize("NFKD")` + replace + hyphen-run collapse + trim (paths.ts:37-42); empty result throws (paths.ts:43-45). An input of `"../.."` reduces to `""` and throws rather than escaping. `safeSegment` applies the same pipeline preserving case (paths.ts:52-58); `safeExt` strips leading dots, defaulting to `"bin"` (paths.ts:60-64). Pinned by tests including `expect(workspaceSlug("../etc/passwd")).not.toContain("..")` (paths.test.ts:17) and `expect(() => workspaceSlug("////")).toThrow(/empty slug/)` (paths.test.ts:30).

**Evidence:** paths.ts:28, 36-47; paths.test.ts:15-33.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 10: paths.ts — `artifactVersionPath` zero-padded 1-based version

**Location:** app/lib/corpus/paths.ts:86-94
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`String(version).padStart(VERSION_PAD, "0")` with `VERSION_PAD = 4` (paths.ts:23, 92) and rejection of non-positive/non-integer versions (paths.ts:89-91). Tests confirm the exact example string, the `v0042` case, and rejection of 0 and 1.5 (paths.test.ts:54-61).

**Evidence:** paths.ts:22-23, 88-94; paths.test.ts:54-61.

**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection

---

## Claim 11: storeAdapter.ts — seam typed as `CorpusFS`; localStorage default; S3 worker-proxy drops in without store changes

**Location:** app/lib/corpus/storeAdapter.ts:4-8 (echoed at workspaceStore.ts:496-498)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The injection point accepts the interface, not the concrete adapter: `export function createCorpusBackedStorage(fs: CorpusFS): StateStorage` (storeAdapter.ts:52). The only place a concrete adapter is named is the composition point inside `resolveWorkspaceStorage` (storeAdapter.ts:73), and workspaceStore binds only to `resolveWorkspaceStorage` (workspaceStore.ts:25, 499). The G14 test exercises the seam with a different implementation (the in-memory fake, workspaceStore-corpus-flag.test.ts:42-43), demonstrating the claimed substitutability.

**Evidence:**
```ts
export function resolveWorkspaceStorage(): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(createOpfsCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```
(storeAdapter.ts:71-76)

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 12: storeAdapter.ts — S1 blob mode; "the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used by the store until S4"

**Location:** app/lib/corpus/storeAdapter.ts:10-13
**Type:** Reference + architectural
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

The substantive claim is verified by all replicates — `createCorpusBackedStorage` reads/writes/removes only `state/<name>.json` (storeAdapter.ts:55-67); storeAdapter.ts imports nothing from paths.ts or manifest.ts, and no caller of the paths.ts builders exists outside tests. But the file name is stale: `layout.ts` was renamed to `paths.ts` by commit 122d70f *within this same range* ("Next.js App Router treats any app/**/layout.ts as a route layout"), which updated the test import (paths.test.ts:13 `from "../paths"`) but missed this comment. At 2dc403e no layout.ts exists under app/lib/corpus/. Low-stakes but exactly the kind of pointer that misleads the S2 implementer the seam docs target.

**Evidence:** storeAdapter.ts:11, 15-18; 122d70f commit message; directory listing of app/lib/corpus/ (paths.ts present, no layout.ts).

**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale (r2 additionally verdicted the substantive blob-mode half in isolation as Verified)

---

## Claim 13: storeAdapter.ts — debounced localStorage "moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior"; writes debounced 300ms

**Location:** app/lib/corpus/storeAdapter.ts:21-23
**Type:** Behavioral / equivalence
**Verdict:** Verified
**Confidence:** High — diffed line-by-line against the pre-range implementation at dc6dfb0 in all three replicates.
**Legibility-target:** for-orchestrator-synthesis

The body of `createDebouncedLocalStorage` (storeAdapter.ts:25-46) is token-for-token identical to `createDebouncedStorage` in `git show dc6dfb0:app/lib/stores/workspaceStore.ts`: same `getItem` passthrough, same `clearTimeout`/`setTimeout(..., 300)` debounce, same try/catch `console.warn("Failed to persist workspace (localStorage quota exceeded):", e)`, same `removeItem` cancel-then-delete. Only the function name and return-type annotation changed (type-level, no behavioral delta). The 300ms figure matches (`}, 300);`, storeAdapter.ts:38), and the OFF-path routing is locked by the G13 test asserting `getDirectory` is never called (workspaceStore-corpus-flag.test.ts:25-37); the characterization test flushes the same 300ms debounce (workspaceStore-characterization.test.ts:52).

**Evidence:** old body excerpt from dc6dfb0 (`pending = setTimeout(() => { try { localStorage.setItem(name, value); } catch (e) { console.warn("Failed to persist workspace (localStorage quota exceeded):", e); } pending = null; }, 300);`) — identical at storeAdapter.ts:31-38.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 14: storeAdapter.ts — "Selected once when the store's persist middleware initializes."

**Location:** app/lib/corpus/storeAdapter.ts:70
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium — zustand is not installed in this worktree, so the claim rests on knowledge of zustand v5 (`"zustand": "^5.0.13"`, package.json:33) rather than read source.
**Legibility-target:** for-author

`resolveWorkspaceStorage` is passed as the getter to `createJSONStorage` (workspaceStore.ts:499). Paraphrased — no quote available because zustand's source is not present in the worktree: in zustand v5, `createJSONStorage(getStorage)` invokes `getStorage()` exactly once, eagerly, when `createJSONStorage` itself runs — at module evaluation of workspaceStore.ts, i.e. slightly *before* "the persist middleware initializes" and possibly during SSR, where `window` is undefined and only the env half of the flag can select the corpus path. "Once" is right; "when the persist middleware initializes" is approximately right; the flag is consequently not re-evaluated when a user sets the localStorage key until the next page load — consistent with the flag docs, but worth the author confirming the SSR-time selection is intended.

**Evidence:** workspaceStore.ts:499 (`storage: createJSONStorage(resolveWorkspaceStorage),`).

**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified

---

## Claim 15: types.ts — "'Not found' is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

**Location:** app/lib/corpus/types.ts:17-18 (method docs at types.ts:113-124)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High — both implementations read end-to-end.
**Legibility-target:** for-orchestrator-synthesis

OPFS adapter: `readFile` returns `null` for missing dir or file (opfsAdapter.ts:92, 97), `stat` likewise (opfsAdapter.ts:161, 166), `readdir` returns `[]` (opfsAdapter.ts:130), `rm` is an idempotent no-op on missing (opfsAdapter.ts:144, 148); every other failure funnels through `wrap()`, which always throws a `CorpusError` (opfsAdapter.ts:79-83). In-memory fake: `files.get(normalize(path)) ?? null` (inMemoryCorpusFs.ts:22) — the `?? null` converts Map's `undefined` so callers never see it; `stat` returns `bytes ? { size } : null` (inMemoryCorpusFs.ts:50). Contract suite pins the convention (corpusFsContract.ts:21-28, 49-56).

**Evidence:** inMemoryCorpusFs.ts:22; opfsAdapter.ts:79-83; corpusFsContract.ts:21-28.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 16: types.ts — `CorpusErrorKind` is "the complete set of corpus failure kinds"; CorpusError/CorpusWorkerError "differ only in transport, never in the kind set"

**Location:** app/lib/corpus/types.ts:27-28, 37-49, 61-67
**Type:** Invariant / architectural
**Verdict:** Verified
**Confidence:** High — every producer of `CorpusError` in the repo enumerated.
**Legibility-target:** for-orchestrator-synthesis

Both types bind to the single `CorpusErrorKind` union: `CorpusError.detail: CorpusErrorKind` (types.ts:53) and `CorpusWorkerError = { __corpusError: true; detail: CorpusErrorKind; message: string }` (types.ts:63-67); `toWorkerError` copies `detail` and `message` verbatim (types.ts:69-71); no second kind enumeration exists. Per-kind production audit: **produced today** — `io` (opfsAdapter.ts:60, 82; manifest.ts:66), `unavailable` (opfsAdapter.ts:52), `quota-exceeded` (opfsAdapter.ts:81). **Declared but produced nowhere** — `not-found`, `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, `git-conflict` (reserved for S2/S3 per the header's forward references). `describeCorpusError` switches over all eight kinds with an `assertNever` default (types.ts:78-96). One synthesis-level tension flagged by all: the `not-found` kind is unreachable by design — the interface convention returns `null`/`[]` instead of throwing it — a dead union arm and latent ambiguity for S2+ implementers, not a false claim.

**Evidence:** types.ts:41-49, 53, 63-67, 78-96; `throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` (opfsAdapter.ts:81).

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 17: types.ts — "Implementations create intermediate directories on write."

**Location:** app/lib/corpus/types.ts:109-110 (writeFile doc at types.ts:117)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

OPFS: `writeFile` walks with `walkDir(root, dirs, true)` where `create=true` calls `getDirectoryHandle(d, { create })` per segment (opfsAdapter.ts:111, 70). Fake: directories are implicit — "a file at \"a/b/c.txt\" makes \"a\" and \"a/b\" listable" (inMemoryCorpusFs.ts:8). Contract test "creates intermediate directories and lists children at each level" asserts it (corpusFsContract.ts:41-47).

**Evidence:** opfsAdapter.ts:111, 70; corpusFsContract.ts:41-47.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=—

---

## Claim 18: opfsAdapter.ts — SSR/unavailable guard rejects with typed `CorpusError`, never a raw `TypeError`

**Location:** app/lib/corpus/opfsAdapter.ts:9-11
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High — all five methods traced; both stub scenarios tested.
**Legibility-target:** for-orchestrator-synthesis

`getRoot()` throws `new CorpusError({ kind: "unavailable", ... })` when `navigator.storage.getDirectory` is absent — the guard `if (!storage || typeof storage.getDirectory !== "function")` (opfsAdapter.ts:50-53) covers both `navigator` absent (SSR) and `storage` present without `getDirectory`. All five interface methods call `getRoot()` first inside a try whose catch is `wrap(path, e)`, and `wrap` re-throws CorpusError untouched: `if (e instanceof CorpusError) throw e;` (opfsAdapter.ts:80). Tests drive both shapes: `setStorage({})` asserts `detail.kind === "unavailable"` and `setStorage(undefined)` asserts all remaining methods reject with `CorpusError` (opfsAdapter.test.ts:26-47).

**Evidence:** opfsAdapter.ts:50-53, 79-83; opfsAdapter.test.ts:26-47.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 19: opfsAdapter.ts — quota reified as `{kind:"quota-exceeded", substrate:"opfs"}`, "NOT swallowed with console.warn the way the legacy localStorage adapter does (workspaceStore.ts:44-46)"

**Location:** app/lib/corpus/opfsAdapter.ts:12-14
**Type:** Behavioral + reference
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

The behavioral half is verified by all replicates: `if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` (opfsAdapter.ts:81), with `isQuota` matching `QuotaExceededError`/`QUOTA_EXCEED_ERR`-era names (opfsAdapter.ts:45-47), no `console.warn` anywhere in the file (zero-match grep), and the G7 test pinning the exact detail shape (opfsAdapter.test.ts:59, 80-81). The **line reference is stale**: commit 00ba8c3 (later in this same range, after f6361a3 introduced this comment) moved the debounced-localStorage adapter out of workspaceStore.ts, so the referenced `console.warn` now lives at storeAdapter.ts:33-36 (`console.warn("Failed to persist workspace (localStorage quota exceeded):", e)`, storeAdapter.ts:35), while workspaceStore.ts:44-46 is now the body of `coerceArtifactVersion` — a reader following the pointer lands on unrelated validation code. Commit 122d70f touched opfsAdapter but did not fix this pointer.

**Evidence:** opfsAdapter.ts:81, 45-47; storeAdapter.ts:35; workspaceStore.ts:44-46 at 2dc403e (fields of the returned `ArtifactVersion`).

**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale (r2 additionally verdicted the behavioral quota half in isolation as Verified)

---

## Claim 20: opfsAdapter.ts — "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** app/lib/corpus/opfsAdapter.ts:115
**Type:** Behavioral (comment vs. code)
**Verdict:** Incorrect
**Confidence:** High — one-line comparison of comment and the line below it, unanimous across replicates.
**Legibility-target:** for-author

**Evidence:**
```ts
try {
  // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
  await w.write(bytes);
} finally {
```
(opfsAdapter.ts:114-118)

The comment describes creating a fresh view; the code passes the caller's `bytes` parameter unmodified — no `new Uint8Array(bytes)`, no `.slice()`, no buffer copy exists anywhere in `writeFile` (opfsAdapter.ts:107-123). Either a defensive copy was written and later removed, or the comment was drafted for code that never landed. Contrast the in-memory fake, which does copy and says so accurately: `files.set(normalize(path), bytes.slice());` with comment "Copy so later mutation of the caller's array can't alter stored bytes." (inMemoryCorpusFs.ts:26-27). Commit 122d70f narrowed the *type* to `Uint8Array` ("narrow local OpfsWritable.write to Uint8Array") — a type-level change, not the runtime copy the comment claims. If some OPFS implementations genuinely "dislike shared buffers" (e.g. a Uint8Array over a SharedArrayBuffer, relevant once the S3 worker exists), the hazard the comment names is unhandled.

**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

---

## Claim 21: opfsAdapter.ts — DOMException → not-found/quota mapping (null from readFile/stat, [] from readdir, idempotent rm)

**Location:** app/lib/corpus/opfsAdapter.ts:42-47 (behavior claimed in header opfsAdapter.ts:1-14 and types.ts:113-124)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`isNotFound` matches `NotFoundError || TypeMismatchError` (opfsAdapter.ts:42-44) — the latter a reasonable widening (path exists but is a directory where a file was expected) — and all its call sites resolve to the null/[]/no-op convention (opfsAdapter.ts:72, 97, 148, 166) rather than throwing. `isQuota` feeds only the `quota-exceeded` throw in `wrap`; everything unmatched becomes `{kind:"io", path, reason}` with the original message preserved (opfsAdapter.ts:82). readFile: missing dir → `if (!dir) return null` (opfsAdapter.ts:92); readdir: `if (!dir) return [];` (opfsAdapter.ts:130); rm: missing parent → `return; // idempotent` (opfsAdapter.ts:144). Contract suite asserts the convention (corpusFsContract.ts:21-28, 49-56).

**Evidence:**
```ts
function isNotFound(e: unknown): boolean {
  return e instanceof DOMException && (e.name === "NotFoundError" || e.name === "TypeMismatchError");
}
function isQuota(e: unknown): boolean {
  return e instanceof DOMException && (e.name === "QuotaExceededError" || e.name === "QUOTA_EXCEEDED_ERR");
}
```
(opfsAdapter.ts:42-47)

**Replicate verdicts:** r1=Verified · r2=Verified · r3=—

---

## Claim 22: inMemoryCorpusFs.ts — "substitutability (LSP) is verified, not assumed"

**Location:** app/lib/corpus/__tests__/inMemoryCorpusFs.ts:4-6
**Type:** Architectural / testing claim
**Verdict:** Mostly accurate
**Confidence:** High — all three relevant files plus the plan status line read.
**Legibility-target:** for-author

The shared suite exists and is genuinely shared in structure: `corpusFsContract.ts:14` exports `defineCorpusFsContract`, and the CI runner binds only the fake (`defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());`, corpusFs.contract.test.ts:8). The OPFS adapter's run of that suite is out-of-CI Playwright, and at this commit it has **not been executed**: "out-of-CI OPFS Playwright smoke documented but not yet run" (docs/working/plan-corpus-s1.md:5, evidence only). At this repo state substitutability is verified for the fake and *planned* for the adapter — "verified, not assumed" overstates the adapter side.

**Evidence:** corpusFs.contract.test.ts:8; corpusFsContract.ts:4-7; plan-corpus-s1.md:5.

**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection

---

## Claim 23: workspaceStore.ts header — "custom debounced storage adapter rate-limits writes"

**Location:** app/lib/stores/workspaceStore.ts:5
**Type:** Behavioral / staleness signal
**Verdict:** Mostly accurate
**Confidence:** High — both storage branches read.
**Legibility-target:** for-author

Unconditionally phrased, but only the default branch debounces. When the corpus flag is on, storage is `createCorpusBackedStorage(...)`, whose `setItem` awaits `fs.writeFile` immediately with no debounce or rate-limiting (storeAdapter.ts:61-63) — every zustand `set()` triggers an OPFS write. Accurate for the default path (the only user-facing one in S1), and the seam comment lower in the same file (workspaceStore.ts:496-498) states the two-branch reality correctly, but the header predates the seam and was not updated to match.

**Evidence:** storeAdapter.ts:61-63 (`setItem: async (name, value) => { await fs.writeFile(pathFor(name), enc.encode(value)); }`).

**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Verified

---

## Claim 24: workspaceStore.ts — "SSR safe: render defaults first, hydrate in useEffect via rehydrate()" (skipHydration)

**Location:** app/lib/stores/workspaceStore.ts:500-501
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`skipHydration: true` is set (workspaceStore.ts:501) and the documented caller exists: app/page.tsx:83 calls `useWorkspaceStore.persist.rehydrate();` under the comment "--- SSR hydration: trigger Zustand rehydrate once on mount ---" (page.tsx:78). The characterization test exercises the same rehydrate path (workspaceStore-characterization.test.ts:97). The comment predates the range and remains accurate after the seam swap because storage selection at module scope safely returns false for the flag's localStorage half without `window` (flag.ts:17, 24).

**Evidence:** workspaceStore.ts:500-501; page.tsx:78, 83.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 25: workspaceStore.ts — "Validate deserialized localStorage data before merging into the store."

**Location:** app/lib/stores/workspaceStore.ts:502-503
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The `merge` option applies `coercePersistedState` behind an `isObject` guard before spreading over current state (workspaceStore.ts:504-507), and `coercePersistedState` type-checks every field, reusing `coerceDecomposition` for nodes (workspaceStore.ts:98-101) as the comment says. Unchanged by the range except that data may now arrive from CorpusFS rather than localStorage — minor wording narrowness when the flag is on; the same merge path validates both substrates identically.

**Evidence:** workspaceStore.ts:504-507 (`merge: (persisted, current) => ({ ...current, ...(isObject(persisted) ? coercePersistedState(persisted as Record<string, unknown>) : {}) })`).

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 26: commit ec7bbbc — "S0 contracts ... per plan-corpus-s1 steps 1-3" and content claims

**Location:** commit ec7bbbc message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Plan-step references check out: docs/working/plan-corpus-s1.md steps 1-3 (lines 21-23) describe exactly types.ts, layout.ts (now paths.ts), and manifest.ts — the three files the commit created — and the arch-review finding references (1, 2) match the plan's annotations (plan-corpus-s1.md:70). Two overstatements inherited by the message: "single choke point for untrusted titles" is accurate for untrusted titles specifically, but the stronger paths.ts wording it summarizes is violated later in the range (Claim 8), and "fail-loud parse (typed CorpusError, never silent default-empty)" carries the entry-level silent-drop caveats of Claim 4. Both were defensible at ec7bbbc's own snapshot (storeAdapter did not yet exist); flagged because the range's end state weakens them. One drift in the plan, not the commit: step 6 specified `opfs-quota-exceeded` while the shipped kind is substrate-neutral `quota-exceeded {substrate:"opfs"}`.

**Evidence:** plan-corpus-s1.md:21-23, 70; ec7bbbc message; Claims 4 and 8 above.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate

---

## Claim 27: commit 3da6747 — "26 tests pass" + characterization content claims

**Location:** commit 3da6747 message
**Type:** Reference / test-count (static, per brief)
**Verdict:** Verified
**Confidence:** High for the static count (reconstructs exactly with no expansion ambiguity); the "pass" assertion is historical CI state taken on count evidence only.
**Legibility-target:** for-orchestrator-synthesis

Static `it(` count across the four test files the commit adds: corpusFsContract.ts 7 (instantiated exactly once via corpusFs.contract.test.ts:8) + layout.test.ts 10 + manifest.test.ts 5 + workspaceStore-characterization.test.ts 4 = **26**, matching exactly. No `it.each` in these files, so static = runtime. Plan steps 4-5 (plan-corpus-s1.md:24-25) match the delivered files; the message's content claims match (30-small-files S4 access-pattern case at corpusFsContract.ts:58; fail-loud parse asserting the typed kind at manifest.test.ts:39; the four characterization test names).

**Evidence:** per-file `it(` counts (7/10/5/4); corpusFsContract.ts:58; manifest.test.ts:39.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 28: commit f6361a3 — plan steps 6,8a; adapter behavior summary; "3 tests pass"

**Location:** commit f6361a3 message
**Type:** Reference / behavioral / test-count (static)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

opfsAdapter.test.ts contains exactly 3 `it(` blocks (2 unavailable-guard + 1 quota) — matches. Plan steps 6 and 8 exist (plan-corpus-s1.md:26, 28); the plan has no literal "8a/8b" split — the commits subdivide step 8's two files, a faithful refinement. Every behavioral clause in the message maps to code verified above (Claims 18, 19, 21); the message's `{kind:"quota-exceeded", substrate:"opfs"}` matches the code and *corrects* the plan's own stale `opfs-quota-exceeded` wording (plan-corpus-s1.md:26, evidence only).

**Evidence:** opfsAdapter.test.ts (3 `it` blocks); opfsAdapter.ts:81; plan-corpus-s1.md:26, 28.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 29: commit 00ba8c3 — "moved here verbatim"; "one-line storage swap ... net shrinks the store file"; "69 corpus+store tests pass"

**Location:** commit 00ba8c3 message
**Type:** Reference / equivalence / test-count (static)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Static reconstruction: corpus tests (corpusFsContract 7 + layout.test 10 + manifest.test 5 + opfsAdapter.test 3 = 25) + store tests (workspaceStore.test 17 + hydration 8 + characterization 4 + corpus-flag 3 + artifactEditHandlers 2 plain `it` + 2 `it.each` over the 5-element `KEYS` array = 12) = 25 + 44 = **69**, exact (KEYS at artifactEditHandlers.test.ts:6-12). "Moved verbatim" — verified (Claim 13). "One-line storage swap" — the single changed wiring line is `storage: createJSONStorage(resolveWorkspaceStorage)` (workspaceStore.ts:499, replacing `createJSONStorage(createDebouncedStorage)`); the store file shrinks net (range diff: ~33 removed, ~5 added). The G13/G14/G15 test descriptions match the three describe blocks in workspaceStore-corpus-flag.test.ts (:24, :40, :60). Plan steps 7/8b exist, including the pre-authorized extraction to storeAdapter.ts (plan-corpus-s1.md:27-28, 40).

**Evidence:** per-file `it(` counts; artifactEditHandlers.test.ts:6-12, 27, 40; workspaceStore.ts:499; plan-corpus-s1.md:27-28, 40.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

---

## Claim 30: commit 122d70f — rename rationale ("Next reserved name"), "324 vitest tests pass", "paths.test.ts import updated", writable narrowing

**Location:** commit 122d70f message
**Type:** Reference / configuration / test-count (static)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

- **Rename + rationale**: `git log --follow -- app/lib/corpus/paths.ts` confirms the layout.ts→paths.ts rename at 122d70f. The rationale — Next.js App Router treats any `app/**/layout.ts` as a route layout, failing the build with a missing-default error — is consistent with Next.js App Router reserved-file conventions (paraphrased — no quote available because the behavior is in the Next.js framework, not this repo); the repo is on `"next": "^16.2.6"` with the corpus module under `app/lib/corpus/`, so the collision is real, and CLAUDE.md independently records the mechanism. The build itself was not re-run.
- **"paths.test.ts import updated"**: `from "../paths"` (paths.test.ts:13). Verified.
- **"narrow local OpfsWritable.write to Uint8Array"**: `write(data: Uint8Array): Promise<void>;` (opfsAdapter.ts:28). Verified.
- **"324 vitest tests pass"**: static reconstruction at 2dc403e: plain `it(`/`test(` occurrences across all test files + `it.each` expansion (2 × 5 KEYS, net +8) + 7 contract-suite tests instantiated once = **324**, exact — but this is arithmetic over static declarations, not a run; any conditionally-skipped test would break the equality, hence Mostly accurate rather than Verified for the "pass" half.
- **Unfixed staleness**: this commit updated seam docs and CLAUDE.md but left the two dangling references found above (Claims 12 and 19) unfixed.

**Evidence:** paths.test.ts:13; opfsAdapter.ts:28; static counts per file; package.json:23.

**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** — paths.ts:16-19: "the only source of corpus paths is this module" is violated by storeAdapter.ts:55's hand-built `state/${name}.json`, which also lies outside the documented layout diagram. Low practical risk (the interpolated name is a compile-time constant, so untrusted-title safety still holds), but the stated invariant is false as of the same changeset that introduced it, and S2's FSA mirror would replay the undocumented `state/` directory into user-visible folders. Either route the state-blob path through paths.ts or scope the claim to workspace-layout paths.
- **Claim 20** — opfsAdapter.ts:115: comment says a fresh ArrayBuffer view is passed to `write()`; the code passes the caller's `Uint8Array` unmodified — no copy or re-view exists anywhere in `writeFile`. Either add the copy (as inMemoryCorpusFs.ts:26-27 does, accurately documented) or delete the comment; if the shared-buffer hazard is real it becomes load-bearing at S3.

### Stale
- **Claim 19** — opfsAdapter.ts:13-14: line reference "(workspaceStore.ts:44-46)" points at code that commit 00ba8c3 (same range) moved to storeAdapter.ts:33-36; the cited lines are now unrelated validation code (`coerceArtifactVersion`).
- **Claim 12** — storeAdapter.ts:11-12: references "layout.ts", renamed to paths.ts by 122d70f in the same range; the rename sweep updated the test import but missed this comment.

### Mostly Accurate
- **Claim 1** — flag.ts:4: "DEV-ONLY" is policy, not an enforced mechanism (no NODE_ENV gate; the localStorage flag works identically in production browsers).
- **Claim 2** — flag.ts:9-10/16: the build-time env enable path uses optional-chained `process.env?.NEXT_PUBLIC_CORPUS_FS`, deviating from Next.js's documented literal-reference inlining form; nothing in the repo verifies the env path works, and if inlining fails it silently never activates in the browser. Cheap fix: the literal `process.env.NEXT_PUBLIC_CORPUS_FS` form or a built-bundle check.
- **Claim 4** — manifest.ts:10-13: codec can only emit kind `"io"` (never the advertised `"browser-storage-cleared"`); `createdAt`/`updatedAt`/`label` are silently defaulted; malformed sources/artifacts/customTypeIds *entries* are silently filtered out rather than failing loud.
- **Claim 5** — manifest.ts:69-73: "throws on any malformation" is overstated at the entry/field level (silent drops and defaults per Claim 4); `manifestVersion` is never range-checked against `MANIFEST_VERSION`.
- **Claim 14** — storeAdapter.ts:70: storage is selected at module evaluation (possibly during SSR), slightly earlier than "when the persist middleware initializes"; flag changes require a reload.
- **Claim 22** — inMemoryCorpusFs.ts:4-6: "substitutability (LSP) is verified, not assumed" — verified for the fake only; the OPFS run of the shared contract suite is documented but not yet executed at this commit.
- **Claim 23** — workspaceStore.ts:5: header states debounced rate-limiting unconditionally; the corpus-backed branch writes on every set with no debounce.
- **Claim 26** — ec7bbbc message: accurate at its own snapshot; the range's end state weakens "single choke point" (Claim 8) and "never silent default-empty" (Claim 4).
- **Claim 30** — 122d70f: test *count* 324 reconstructs exactly, but "pass" is unverifiable statically; the commit also left the two stale references above unfixed.

## Verdict stability

- **Total clusters:** 30 (from replicate reports of 24, 28, and 24 claims; k=3)
- **Agreed (all reporting replicates same verdict):** 23 — including all four single-replicate detections (Claims 6, 7, 10, 22) and three two-replicate clusters (Claims 3, 17, 21)
- **Disagreements:** 7
  - Claim 2 (NEXT_PUBLIC env inlining): r1=Unverifiable · r2=Unverifiable · r3=Mostly accurate → Mostly accurate
  - Claim 5 (parseManifest docstring): r1=— · r2=Mostly accurate · r3=Verified → Mostly accurate
  - Claim 8 (paths.ts "only source of corpus paths"): r1=Incorrect · r2=Stale · r3=Incorrect → Incorrect
  - Claim 14 ("Selected once"): r1=Mostly accurate · r2=Verified · r3=Verified → Mostly accurate
  - Claim 23 (store header rate-limits writes): r1=— · r2=Mostly accurate · r3=Verified → Mostly accurate
  - Claim 26 (commit ec7bbbc): r1=Verified · r2=Verified · r3=Mostly accurate → Mostly accurate
  - Claim 30 (commit 122d70f): r1=Mostly accurate · r2=Verified · r3=Verified → Mostly accurate
- **Agreement rate:** 23/30 = 77%. All disagreements are one-step severity gradations on the same underlying finding (no replicate contradicted another's evidence); the largest split is Claim 8, where all three found the same storeAdapter.ts:55 counterexample but rated the violated invariant Incorrect (r1, r3) vs Stale (r2).

## Goal-Alignment Note
- Answered: All eight briefed claim areas across all three replicates — flag header incl. the NEXT_PUBLIC inlining question (Claims 1-3), manifest parse/defaults/fail-loud (Claims 4-6), paths single-choke-point invariant checked against actual corpus write paths (Claims 7-10), storeAdapter moved-verbatim/debounce parity diffed against dc6dfb0 (Claims 11-14), per-kind production audit of CorpusErrorKind (Claims 15-17), opfsAdapter error-mapping/SSR/invariants (Claims 18-21), workspaceStore seam/skipHydration/validation comments (Claims 23-25), and all five commit messages incl. plan-step cross-references and static test-count reconstruction, which matched exactly at 26/3/69/324 in every replicate that checked them (Claims 26-30).
- Out of scope: docs/working/** and docs/thoughts/** claim verdicts (used as evidence only, per brief — noting in passing the plan's internal step-6 `opfs-quota-exceeded` vs step-1 substrate-neutral naming inconsistency); actually running the vitest suite or `next build` in the historical worktree (static verification only); non-app files (CLAUDE.md, docs/spikes) beyond their use as evidence; design questions such as whether the corpus-backed storage *should* debounce (deferred to the performance critic).
- Escalate (union of replicate escalations, deduplicated):
  1. **NEXT_PUBLIC inlining (Claims 2 + 1 jointly):** the flag's build-env gate uses an optional-chained access that Next 16's `NEXT_PUBLIC_*` replacement may not rewrite (webpack vs Turbopack), and it is the only enable path available to a production build — it may be a silent no-op, and it is untested. Downstream critics assessing flag safety should treat the localStorage gate as the only verified enable path; cheap fix is the literal `process.env.NEXT_PUBLIC_CORPUS_FS` form.
  2. **"DEV-ONLY" is purely conventional (Claim 1):** no enforcement mechanism exists; if any production hardening is expected before S4, the env/localStorage gate needs one.
  3. **Undocumented `state/` blob location (Claim 8):** invisible to the documented layout and to S4 migration planning, and the S2 FSA mirror will replay it into user-visible folders if not routed through paths.ts first — worth surfacing to the author before S4 assumes all corpus data lives under `workspaces/`.
  4. **Removed-copy bug risk (Claim 20):** the orphaned "fresh ArrayBuffer view" comment may mask a real shared-buffer bug on some OPFS implementations if the copy was removed rather than never written; becomes load-bearing at S3 when a worker-shared buffer can actually reach `writeFile`.
