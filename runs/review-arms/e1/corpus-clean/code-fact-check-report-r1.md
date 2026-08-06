# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-corpus-clean)
**Scope:** `git diff dc6dfb0..4de2b00 -- app/` — corpus S0/S1 changeset + review-fix commit; app/ code only, docs/** used as evidence for reference claims only
**Checked:** comments, docstrings, and commit-message claims in `app/lib/corpus/*` (flag, manifest, opfsAdapter, paths, storeAdapter, types), `app/lib/stores/workspaceStore.ts`, corpus/store test files, and commit 4de2b00's message
**Total claims checked:** 22
**Summary:** 13 Verified, 6 Mostly accurate, 1 Incorrect, 0 Stale, 2 Unverifiable. The review-fix commit's mechanical claims (A1 rename, A2 path routing, A3 stale-ref fixes, C1 splitPath rejection + test) all check out. The one Incorrect finding is the pre-existing "fresh ArrayBuffer view" comment in `opfsAdapter.ts` — the code does not do what the comment says. The A4-fixed manifest docstring is improved but still overstates fail-loud behavior (entry-level malformations are silently filtered; `label` defaults). The C2 production guard is logically first-in-line for both enable paths, but its client-bundle guarantee rests on Next.js inlining the optional-chained `process.env?.NODE_ENV` form, which cannot be confirmed statically here, and it has no test.

**Commit:** 4de2b00

## Claim 1: flag.ts — production hard-refuse (C2)

**Location:** app/lib/corpus/flag.ts:16-21
**Type:** Behavioral / invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

The comment claims: "Refuse to activate in a production build so the dev flag can never become an end-user data-loss footgun (security review C2)."

The guard is the first statement of `isCorpusEnabled()` and returns before either enable path is evaluated, so in any environment where the condition evaluates true it blocks BOTH the env path and the localStorage path:

**Evidence:**
```ts
// app/lib/corpus/flag.ts:21-26
if (typeof process !== "undefined" && process.env?.NODE_ENV === "production") return false;

if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
if (typeof window !== "undefined") {
  try {
    return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
```

Two caveats keep this from a clean Verified:

1. **Build-time inlining of the optional-chained form.** Next.js (package.json: `"next": "^16.2.6"` — paraphrased context, version line quoted below) inlines `process.env.NODE_ENV` / `process.env.NEXT_PUBLIC_*` in client bundles by exact-expression replacement. The code uses `process.env?.NODE_ENV` (optional chaining). Whether Next 16's define/inline step matches the `?.` form cannot be confirmed statically in this worktree (`node_modules` is not installed, and no build output exists to inspect). If the `?.` form is NOT inlined, the client-bundle behavior falls back to whatever runtime `process` shim exists in the bundle; if `process` is absent or its `env` lacks `NODE_ENV`, the guard is skipped in the browser and the **localStorage path could still activate in a production build** — exactly the footgun the comment claims is closed. Paraphrased — no quote available because the inlining behavior lives in Next.js build tooling, not in this repo's source.
   ```json
   // package.json (dependencies)
   "next": "^16.2.6",
   ```
2. **No test.** `rg -n "NODE_ENV" app/` matches only flag.ts itself (flag.ts:21 plus its comment); no test manipulates NODE_ENV to assert the guard. The commit message claims a test only for C1, not C2, so this is an observation, not a commit-claim mismatch.

Server-side (SSR/dev-server) the guard is straightforwardly correct: `process` exists and `NODE_ENV` is set by Next.

## Claim 2: flag.ts — the two enable paths

**Location:** app/lib/corpus/flag.ts:9-10
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Docstring: "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`."

**Evidence:**
```ts
// app/lib/corpus/flag.ts:13
export const CORPUS_FLAG_KEY = "corpus-fs-enabled";
// app/lib/corpus/flag.ts:23-26
if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
if (typeof window !== "undefined") {
  try {
    return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
```
The localStorage path is exercised by test: `localStorage.setItem(CORPUS_FLAG_KEY, "1")` then `resolveWorkspaceStorage()` routes to `navigator.storage.getDirectory` (app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:62-80).

## Claim 3: manifest.ts — codec contract docstring (A4 fix)

**Location:** app/lib/corpus/manifest.ts:10-16
**Type:** Behavioral / invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Docstring: "A malformed or absent manifest surfaces as a typed `CorpusError` of kind \"io\", never a silent default-empty manifest ... The only fields that default rather than fail are the `createdAt`/`updatedAt` timestamps (metadata, not content) — every content field (title, sources, artifacts, customArtifactTypeIds) fails loud if missing or malformed."

**Accurate halves:**
- "only throws io": every throw in the module goes through `fail()`, which mints exactly one kind:
  ```ts
  // app/lib/corpus/manifest.ts:67-70
  function fail(reason: string): never {
    // Manifest parse failure is an i/o-class corruption of the workspace index.
    throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
  }
  ```
  `rg "CorpusError\(" app/lib/corpus/manifest.ts` shows no other constructor call (paraphrased — grep result, single hit at line 69).
- createdAt/updatedAt do default:
  ```ts
  // app/lib/corpus/manifest.ts:112-113
  createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
  updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : new Date().toISOString(),
  ```
- Missing/wrong-typed top-level fields do fail loud: `title` (line 86), `manifestVersion` (line 87), non-array `sources` (line 94), non-array `artifacts` (line 103), non-array `customArtifactTypeIds` (line 107).

**Overstated half — "every content field fails loud if missing or malformed" is not true at entry level:**
- Non-object entries inside `sources` and `artifacts` are silently dropped, not failed:
  ```ts
  // app/lib/corpus/manifest.ts:89-90
  const sources: SourceRef[] = Array.isArray(raw.sources)
    ? raw.sources.filter(isObject).map((s) => {
  ```
  ```ts
  // app/lib/corpus/manifest.ts:96-97
  const artifacts: ArtifactPointer[] = Array.isArray(raw.artifacts)
    ? raw.artifacts.filter(isObject).map((a) => {
  ```
- Non-string entries inside `customArtifactTypeIds` are silently filtered:
  ```ts
  // app/lib/corpus/manifest.ts:105-106
  const customArtifactTypeIds: string[] = Array.isArray(raw.customArtifactTypeIds)
    ? raw.customArtifactTypeIds.filter((x): x is string => typeof x === "string")
  ```
- `label` is a content field that defaults (to the id) rather than failing:
  ```ts
  // app/lib/corpus/manifest.ts:92
  return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
  ```
So a manifest whose `sources` array contains, say, three strings and no objects parses "successfully" to `sources: []` — a partial silent-default of exactly the shape the docstring says never happens. Object-shaped entries missing `id`/`ext` or `type`/`currentVersion` do fail loud (lines 91, 98-100), and that case is tested (app/lib/corpus/__tests__/manifest.test.ts:46-51).

## Claim 4: manifest.ts — ArtifactPointer docstring

**Location:** app/lib/corpus/manifest.ts:23-24
**Type:** Reference / behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

"`currentVersion` is the 1-based version number whose file is artifacts/<type>/v####.md."

**Evidence:** matches the path builder's contract exactly:
```ts
// app/lib/corpus/paths.ts:105-110
export function artifactVersionPath(slug: string, artifactType: string, version: number): string {
  if (!Number.isInteger(version) || version < 1) {
    throw new Error(`artifact version must be a positive integer, got ${version}`);
  }
  const v = String(version).padStart(VERSION_PAD, "0");
  return `${artifactDir(slug, artifactType)}/v${v}.md`;
```
with `VERSION_PAD = 4` (paths.ts:23) and test `expect(artifactVersionPath(s, "semiformal", 1)).toBe("workspaces/my-slug/artifacts/semiformal/v0001.md")` (app/lib/corpus/__tests__/paths.test.ts:55).

## Claim 5: manifest.ts — parseManifest "throws on any malformation"; null input is an error

**Location:** app/lib/corpus/manifest.ts:72-78
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

"Parse + validate manifest bytes. Throws a `CorpusError` on any malformation — ... passing `null` here is itself an error."

The null half is Verified:
```ts
// app/lib/corpus/manifest.ts:78
if (bytes === null) fail("manifest file is absent");
```
and tested (manifest.test.ts:42-44). "Throws on any malformation" inherits the same entry-level filtering exception documented under Claim 3 (non-object array entries and non-string type ids are dropped, not thrown). Same evidence, not repeated.

## Claim 6: opfsAdapter.ts — header contracts (unavailable guard; quota reification; storeAdapter reference)

**Location:** app/lib/corpus/opfsAdapter.ts:8-15
**Type:** Behavioral + reference (A3 fix)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Three sub-claims:

1. "any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:"unavailable"}), never a raw `TypeError`" — every method starts with `await getRoot()`:
   ```ts
   // app/lib/corpus/opfsAdapter.ts:51-53
   const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;
   if (!storage || typeof storage.getDirectory !== "function") {
     throw new CorpusError({ kind: "unavailable", reason: "navigator.storage.getDirectory is not available (SSR or unsupported browser)" });
   ```
   Tested for all five methods (opfsAdapter.test.ts:26-47, including `expect((caught as CorpusError).detail.kind).toBe("unavailable")` at line 37).
2. "a quota failure rejects with {kind:"quota-exceeded", substrate:"opfs"} — it is NOT swallowed with console.warn" — `wrap()` at opfsAdapter.ts:88-92 (`if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` line 90), tested at opfsAdapter.test.ts:50-82.
3. The reference "the way the legacy localStorage adapter does (createDebouncedLocalStorage in storeAdapter.ts)" — the A3-fixed reference is now correct; that function does swallow with console.warn:
   ```ts
   // app/lib/corpus/storeAdapter.ts:36-39
   } catch (e) {
     console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
   }
   ```
   The pre-fix stale form (`workspaceStore.ts:44-46`) appears nowhere in app/ anymore: `rg -n "workspaceStore.ts:" app/` returns no hits (paraphrased — empty grep result).

## Claim 7: opfsAdapter.ts — splitPath traversal rejection (C1 fix)

**Location:** app/lib/corpus/opfsAdapter.ts:60-66
**Type:** Behavioral / security invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Comment: "Defense-in-depth: paths.ts is the sanitizing choke point, but the adapter must not trust callers to have used it. Reject traversal/backslash segments rather than resolving them."

The rejection logic is present and correct for every method that calls `splitPath`:
```ts
// app/lib/corpus/opfsAdapter.ts:63-67
for (const seg of parts) {
  if (seg === "." || seg === ".." || seg.includes("\\")) {
    throw new CorpusError({ kind: "io", path, reason: `unsafe path segment: ${seg}` });
  }
}
```
Test coverage exists: `fs.writeFile("workspaces/s/../../escape.txt", ...)` must reject with kind "io" (opfsAdapter.test.ts:85-103).

The "the adapter must not trust callers" framing is slightly wider than the implementation: `readdir` does not go through `splitPath` — it splits inline without the rejection loop:
```ts
// app/lib/corpus/opfsAdapter.ts:134-137
async readdir(path) {
  try {
    const root = await getRoot();
    const dirs = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
```
so a `..` segment passed to `readdir` reaches `getDirectoryHandle("..")` un-rejected (real OPFS would itself throw on the invalid name, and readdir is read-only, so exposure is low — but the adapter-level guard covers 4 of 5 methods, not all calls). The commit-message form of the claim ("splitPath rejects ./../backslash segments") is literally accurate.

## Claim 8: opfsAdapter.ts — "fresh ArrayBuffer view" write-site comment

**Location:** app/lib/corpus/opfsAdapter.ts:124
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Comment: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers." The code passes the caller's `bytes` argument directly — no fresh view or copy is constructed:

**Evidence:**
```ts
// app/lib/corpus/opfsAdapter.ts:123-126
try {
  // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
  await w.write(bytes);
} finally {
```
`bytes` is the raw `writeFile(path, bytes)` parameter (line 116). The comment describes an action (`new Uint8Array(bytes)` or `bytes.slice()`) that the code does not perform; a caller passing a view over a SharedArrayBuffer or a mutated-after-call buffer gets exactly the "shared buffer" behavior the comment says is avoided. The comment was NOT touched by the fix commit — it appears verbatim in the original S1 commit (`git show f6361a3:app/lib/corpus/opfsAdapter.ts` lines 113-114, identical text). Contrast with the in-memory fake, which really does copy: `files.set(normalize(path), bytes.slice());` with comment "Copy so later mutation of the caller's array can't alter stored bytes" (app/lib/corpus/__tests__/inMemoryCorpusFs.ts:26-27) — so the fake and the adapter also diverge in aliasing behavior.

## Claim 9: paths.ts — "only source of corpus paths" / choke-point claim (A2 outcome)

**Location:** app/lib/corpus/paths.ts:15-19
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

"The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`."

Post-A2 this now holds for production code. The only corpus-path construction outside paths.ts in non-test app/ code is storeAdapter, which routes through the builder:
```ts
// app/lib/corpus/storeAdapter.ts:58
const pathFor = (name: string) => stateBlobPath(name);
```
`rg -n "stateBlobPath|STATE_DIR" app/` hits only paths.ts (definitions) and storeAdapter.ts (import + use) (paraphrased — grep output shown in session; no other producer). manifest.ts's literal `"workspace.json"` (manifest.ts:69) is an error-detail label inside `CorpusError.detail`, not a path handed to a `CorpusFS` — no FS call is made with it. Test files hand-concatenate paths (e.g. corpusFsContract.ts:42 `"workspaces/s/artifacts/semiformal/v0001.md"`), which is exercising the FS directly, not violating the caller rule. The choke-point sentence is scoped to "untrusted workspace titles", which is exactly `workspaceSlug`'s job (paths.ts:36-47); ids and extensions have their own guards (`safeSegment`, `safeExt`), and post-C1 the adapter adds a second, redundant layer — neither contradicts the claim.

## Claim 10: paths.ts — SAFE_SEGMENT comment

**Location:** app/lib/corpus/paths.ts:26-28
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

"Everything else is collapsed to a hyphen so a value can never contain \"/\", \"\\\\\", \".\" runs, or control characters that would let it escape its directory."

**Evidence:**
```ts
// app/lib/corpus/paths.ts:28
const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;
```
The allowlist excludes `/`, `\`, `.`, and all control characters, so no output of `workspaceSlug`/`safeSegment` can contain them (the claim is actually conservative — no `.` at all survives, not just runs). Tested: `expect(workspaceSlug("../etc/passwd")).not.toContain("..")` and `.not.toContain("/")` (paths.test.ts:17-18), plus the empty-slug throw cases (paths.test.ts:28-32 asserting `toThrow(/empty slug/)`).

## Claim 11: paths.ts — S4-reconciliation breadcrumb (A2 fix)

**Location:** app/lib/corpus/paths.ts:70-84
**Type:** Architectural + reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Breadcrumb claims: (a) "In S1 the whole Zustand persist blob is written as a single file under `state/` (see storeAdapter.createCorpusBackedStorage)"; (b) "Routed through this builder ... so the namespace fork is greppable and the name goes through the same `safeSegment` sanitization as every other path."

**Evidence:**
- (a) The referenced function exists and writes one file per persist key:
  ```ts
  // app/lib/corpus/storeAdapter.ts:64-66
  setItem: async (name, value) => {
    await fs.writeFile(pathFor(name), enc.encode(value));
  },
  ```
  Confirmed at the `state/` location by test: `const bytes = await fs.readFile("state/workspace-zustand-v1.json");` (workspaceStore-corpus-flag.test.ts:49).
- (b) `stateBlobPath` does use `safeSegment`:
  ```ts
  // app/lib/corpus/paths.ts:82-85
  export const STATE_DIR = "state";
  export function stateBlobPath(name: string): string {
    return `${STATE_DIR}/${safeSegment(name)}.json`;
  }
  ```
  Minor nuance, below verdict-changing threshold: "the same `safeSegment` sanitization as every other path" is loose — workspace segments go through `workspaceSlug` (which shares the same `SAFE_SEGMENT` regex but also lowercases, paths.ts:37-42) and extensions through `safeExt`; `safeSegment` itself is what sourcePath/artifactDir/customTypePath use (paths.ts:96, 100, 118).

## Claim 12: storeAdapter.ts — S1 blob-mode header

**Location:** app/lib/corpus/storeAdapter.ts:10-14
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

"In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode) — the files-per-artifact folder layout (paths.ts/manifest.ts) is built but not used by the store until S4. ... The blob path goes through `stateBlobPath` in paths.ts."

**Evidence:** `createCorpusBackedStorage` reads/writes/removes exactly one path per store name via `pathFor = (name) => stateBlobPath(name)` (storeAdapter.ts:58-70, quoted under Claims 9/11). The store side imports nothing from manifest.ts or the workspace-layout builders: workspaceStore.ts's only corpus import is `import { resolveWorkspaceStorage } from "@/app/lib/corpus/storeAdapter";` (app/lib/stores/workspaceStore.ts:25), and `rg -n "manifest|workspaceDir|artifactVersionPath" app/lib/stores/` returns no hits (paraphrased — empty grep result).

## Claim 13: storeAdapter.ts — "moved verbatim ... byte-for-byte the prior behavior"; 300ms debounce

**Location:** app/lib/corpus/storeAdapter.ts:24-27
**Type:** Behavioral / historical
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

"Default: debounced localStorage (moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior — see the characterization test). Reads are synchronous (instant); writes are debounced by 300ms."

**Evidence:** compared against the pre-change source `git show dc6dfb0:app/lib/stores/workspaceStore.ts` — the function body (getItem/setItem/removeItem, the `pending` timer, the 300ms constant, the console.warn catch) is line-for-line identical; only the function name (`createDebouncedStorage` → `createDebouncedLocalStorage`) and the return-type annotation (inline object type → `StateStorage`) differ, neither of which changes behavior. The 300ms figure:
```ts
// app/lib/corpus/storeAdapter.ts:41
}, 300);
```
The referenced characterization test exists at app/lib/stores/__tests__/workspaceStore-characterization.test.ts (header: "Characterization baseline for the CURRENT localStorage persistence behavior", lines 1-9), and the OFF-path routing test flushes exactly 300ms: `vi.advanceTimersByTime(300); // flush debounced localStorage write` (workspaceStore-corpus-flag.test.ts:32).

## Claim 14: storeAdapter.ts — "Selected once when the store's persist middleware initializes"

**Location:** app/lib/corpus/storeAdapter.ts:73
**Type:** Behavioral / timing
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The resolver is passed as `storage: createJSONStorage(resolveWorkspaceStorage)` (app/lib/stores/workspaceStore.ts:499). Paraphrased — no quote available because `node_modules` is not installed in this worktree: in zustand v5 (package.json: `"zustand": "^5.0.13"`), `createJSONStorage(getStorage)` invokes `getStorage()` once, eagerly, when `createJSONStorage` itself is called — i.e., during `create()(persist(...))` evaluation at module load — and closes over the result for all subsequent getItem/setItem calls. That matches "selected once when the persist middleware initializes": the flag is read once per page load, not per write, so toggling localStorage mid-session takes effect only after reload. Confidence Medium because the zustand implementation could not be read from disk here.

## Claim 15: types.ts — null/[] not-found convention; "Callers never see undefined"

**Location:** app/lib/corpus/types.ts:17-18
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

"\"Not found\" is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

**Evidence:** OPFS adapter: `if (isNotFound(e)) return null;` for readFile (opfsAdapter.ts:106) and stat (opfsAdapter.ts:175), `if (!dir) return [];` for readdir (opfsAdapter.ts:139), and all other failures funnel through `wrap()` which always throws a `CorpusError` (opfsAdapter.ts:88-92). In-memory fake: `return files.get(normalize(path)) ?? null;` (inMemoryCorpusFs.ts:22) — the `?? null` is precisely the undefined-suppression the claim requires. Contract-tested for both: `expect(await fs.readFile("absent.txt")).toBeNull(); expect(await fs.stat("absent.txt")).toBeNull();` and `expect(await fs.readdir("nope")).toEqual([]);` (corpusFsContract.ts:22-27).

## Claim 16: types.ts — CorpusErrorKind is "the complete set"; compile-time exhaustiveness

**Location:** app/lib/corpus/types.ts:36-49
**Type:** Architectural / contract
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

"The complete set of corpus failure kinds. Every exhaustive `switch` over a corpus error binds to this union; adding a kind here forces every consumer to handle it at compile time."

**Evidence:** The union declares 8 kinds (types.ts:41-49). The one exhaustive switch that exists, `describeCorpusError`, covers all 8 with an `assertNever` default (types.ts:78-90, `default: return assertNever(d);` at line 88), so the compile-time-forcing mechanism is real. For the brief's producibility question: post-fix, only three kinds are actually constructible from shipped code paths — `"unavailable"` (opfsAdapter.ts:53), `"quota-exceeded"` (opfsAdapter.ts:90), and `"io"` (opfsAdapter.ts:65, 69, 91; manifest.ts:69). The other five (`not-found`, `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, `git-conflict`) have no producers: `rg -n '"not-found"|"fsa-permission-revoked"|"remote-auth-expired"|"browser-storage-cleared"|"git-conflict"' app/` hits only types.ts (paraphrased — grep over app/ returns definitions and the describe switch only). The docstring claims completeness of the *kind set*, not that all kinds are currently produced — the S2/S3/S4 forward references in the header (types.ts:5-8) make the forward-looking intent explicit, so this is not stale.

## Claim 17: opfsAdapter.test.ts + corpusFsContract.ts — "success path is covered ... against real OPFS out-of-CI (Playwright)"

**Location:** app/lib/corpus/__tests__/opfsAdapter.test.ts:5-7 (also app/lib/corpus/__tests__/corpusFsContract.ts:4-6, app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-3)
**Type:** Reference / test-coverage
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

"The adapter's *success* path is covered by the shared CorpusFS contract suite run against real OPFS out-of-CI (Playwright, step 9) — here we only assert that failures become typed CorpusErrors."

The in-CI half is accurate: the contract suite runs against the fake (`defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());`, corpusFs.contract.test.ts:8) and opfsAdapter.test.ts indeed asserts only error mapping. But "is covered ... run against real OPFS" overstates: the referenced smoke exists as a documented procedure, not an executed run. Evidence (docs used as reference evidence only, per scope):
```
// docs/spikes/corpus-opfs-smoke.md — ## Results
_(not yet run — fill in when executed before enabling the flag in a shared environment)_
```
Commit 4de2b00's own message agrees: "Remaining 🟢 items (walkDir handle caching, async un-debounced seam, **run the OPFS smoke**) carried to S2/S3/S5." So at this commit the OPFS success path is covered by a *planned* out-of-CI check, not by any run — "is held to the same suite out-of-CI" (contract.test.ts) phrases the intent better than opfsAdapter.test.ts's "is covered".

## Claim 18: workspaceStore.ts — header "custom debounced storage adapter rate-limits writes"

**Location:** app/lib/stores/workspaceStore.ts:5
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Accurate for the default (flag-off) path — `resolveWorkspaceStorage()` returns the 300ms-debounced localStorage adapter (storeAdapter.ts:74-78). Inaccurate for the flag-on path introduced by this changeset: the corpus-backed storage writes through on every `setItem` with no debounce:
```ts
// app/lib/corpus/storeAdapter.ts:64-66
setItem: async (name, value) => {
  await fs.writeFile(pathFor(name), enc.encode(value));
},
```
The commit message itself acknowledges the gap ("async un-debounced seam" carried to S2/S3), so this is a known, deliberate divergence — but the header sentence, unqualified, no longer describes all configurations of the store it heads.

## Claim 19: workspaceStore.ts — storage-seam comment at the persist options

**Location:** app/lib/stores/workspaceStore.ts:496-499
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

"Storage seam is selected here (DD-009 S1): debounced localStorage by default, or a CorpusFS-backed adapter when the dev flag is on. The seam is typed as CorpusFS so the S3 worker-proxy is a drop-in."

The selection claim is Verified: `storage: createJSONStorage(resolveWorkspaceStorage)` (workspaceStore.ts:499) with `resolveWorkspaceStorage` branching on `isCorpusEnabled()` (storeAdapter.ts:74-79), tested both ways (workspaceStore-corpus-flag.test.ts:24-37 and 60-82). The typing claim is loose at this location: the value bound *here* is a `StateStorage` factory — the CorpusFS-typed seam is one level down, `createCorpusBackedStorage(fs: CorpusFS)` (storeAdapter.ts:55), where the S3 worker-proxy would be injected. The claim's substance survives (a `CorpusFS` implementation is a drop-in at storeAdapter's injection point, cf. storeAdapter.ts:6-8 "The injection seam is typed as `CorpusFS` (arch-review finding 3)"), but "the seam" as read at this comment (the `storage:` option) is not typed `CorpusFS`.

## Claim 20: commit 4de2b00 — mechanical fix claims A1, A2, A3, C1

**Location:** commit 4de2b00 message, body bullets A1/A2/A3/C1
**Type:** Behavioral / reference (commit message)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

- **A1** "WorkspaceManifest.customTypeIds -> customArtifactTypeIds ... no consumers yet": `rg -n "customTypeIds|customArtifactTypeIds" app/` shows zero remaining `customTypeIds` (bare) occurrences — all 9 hits are the new name in manifest.ts and its test (evidence: grep output in session; e.g. `app/lib/corpus/manifest.ts:44: customArtifactTypeIds: string[];`). "No consumers yet" holds: no file outside manifest.ts + manifest.test.ts references the field.
- **A2** "route the S1 blob path through paths.ts stateBlobPath() + STATE_DIR with an S4-reconciliation breadcrumb, instead of a hand-built string in storeAdapter": Verified under Claims 9/11 (`stateBlobPath` at paths.ts:83-85; storeAdapter.ts:58 uses it; breadcrumb at paths.ts:70-81).
- **A3** "fix stale comments (layout.ts->paths.ts; workspaceStore.ts:44-46 ref -> storeAdapter)": `rg -n "layout\.ts" app/` returns no hits, and the opfsAdapter header now cites `createDebouncedLocalStorage in storeAdapter.ts` (opfsAdapter.ts:14-15; the fix diff shows the old `workspaceStore.ts:44-46` text removed — `git diff 4de2b00^ 4de2b00 -- app/lib/corpus/opfsAdapter.ts`).
- **C1** "opfsAdapter splitPath rejects ./../backslash segments (defense-in-depth) + test": Verified under Claim 7 (opfsAdapter.ts:63-67; test at opfsAdapter.test.ts:85-103). The readdir-bypass nuance in Claim 7 does not contradict the literal claim, which names `splitPath`.

## Claim 21: commit 4de2b00 — fix claims A4 and C2

**Location:** commit 4de2b00 message, body bullets A4/C2
**Type:** Behavioral (commit message)
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

- **A4** "manifest docstring matches behavior (only throws io; createdAt/updatedAt default while content fails loud)": "only throws io" and the timestamp defaults are Verified (Claim 3 evidence). "content fails loud" remains overstated at entry level — non-object `sources`/`artifacts` entries and non-string `customArtifactTypeIds` entries are silently filtered, and `label` defaults (manifest.ts:90, 92, 97, 106, quoted under Claim 3). The docstring now *better* matches behavior than before the fix, but "matches" is not fully achieved.
- **C2** "flag.ts hard-refuses to activate in a production build": the guard exists and precedes both enable paths (flag.ts:21, quoted under Claim 1), but the client-bundle guarantee depends on Next.js inlining the `process.env?.NODE_ENV` optional-chaining form (unconfirmable statically here) and the guard has no test — see Claim 1.

## Claim 22: commit 4de2b00 — "Verified: lint clean, build passes, 325 tests pass"

**Location:** commit 4de2b00 message, "Verified:" line
**Type:** Verification claim
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

Static-only check per brief. The exact figure "325 tests pass" cannot be confirmed without running the suite (`node_modules` is not installed in this worktree, and the brief scopes test-count claims to static checking). Static plausibility only: the corpus + store test files touched by this range alone declare 33 `it(` blocks (`rg -c "it\(|test\(" app/lib/corpus/__tests__/*.ts app/lib/stores/__tests__/*.ts` — per-file counts summed, paraphrased from grep output; the suite has many more files outside this range), which is consistent with a repo-wide total in the low hundreds but does not confirm 325. "lint clean" and "build passes" are likewise process claims about the author's environment, not checkable from source. Nothing in the source contradicts any of the three claims.

## Claims Requiring Attention

### Incorrect
- **Claim 8** — opfsAdapter.ts:124 "Pass a fresh ArrayBuffer view" comment: no fresh view or copy is made; `w.write(bytes)` passes the caller's array as-is. Pre-existing (f6361a3), untouched by the fix commit. Either make the copy (as the in-memory fake does at inMemoryCorpusFs.ts:27) or fix the comment.

### Stale
- (none)

### Mostly Accurate
- **Claim 1 / Claim 21 (C2)** — flag.ts production guard: logic is first-in-line for both enable paths, but the production-build guarantee rides on Next.js inlining the optional-chained `process.env?.NODE_ENV` form (statically unconfirmable here) and has no test.
- **Claim 3 / Claim 5 / Claim 21 (A4)** — manifest.ts docstring: "every content field fails loud" is untrue at entry level (non-object array entries and non-string ids silently filtered; `label` defaults to id).
- **Claim 7** — opfsAdapter splitPath comment implies adapter-wide distrust of callers, but `readdir` bypasses the rejection loop (opfsAdapter.ts:137).
- **Claim 17** — "success path is covered ... against real OPFS out-of-CI": the Playwright smoke is documented but its Results section reads "not yet run"; the commit message itself lists running it as remaining.
- **Claim 18** — workspaceStore.ts:5 "debounced storage adapter rate-limits writes" is false on the flag-on corpus path (un-debounced write-through, acknowledged in the commit message).
- **Claim 19** — workspaceStore.ts:498 "The seam is typed as CorpusFS": the seam at that line is `StateStorage`; the CorpusFS-typed injection point is `createCorpusBackedStorage` in storeAdapter.ts.

### Unverifiable
- **Claim 22** — "lint clean, build passes, 325 tests pass": process/environment claims; static inspection can neither confirm nor refute.

## Goal-Alignment Note
- Answered: All eight items in the shared brief — C2 guard mechanics for both enable paths and the `process.env` inlining question (Claim 1); A4 manifest docstring halves against the codec (Claims 3/5); paths.ts single-source claim and S4 breadcrumb (Claims 9/11); C1 splitPath rejection + test coverage and the untouched "fresh ArrayBuffer view" comment (Claims 7/8); A3 stale-reference sweep (Claims 6/20); workspaceStore/storeAdapter debounce and storage-selection timing claims (Claims 13/14/18/19); commit-message fix claims A1-A4/C1-C2 and test-count claim (Claims 20/21/22); producible CorpusErrorKind set (Claim 16).
- Out of scope: docs/** files in the range (review artifacts under docs/reviews/, spike docs) — used only as evidence for reference claims; the "0 red, 4 amber" review-outcome framing in the commit message (excluded by the brief); root CLAUDE.md corpus paragraph (not app/); whether the review-fix choices were *good* fixes (this is a fact-check, not a review).
- Escalate: (1) Claim 1/21-C2 — if the E1 pipeline's downstream critics treat the production guard as settled, the Next.js optional-chaining inlining question deserves a build-output check (`NODE_ENV=production` bundle grep) before the flag ships anywhere; it is the only finding with plausible end-user data-loss consequences. (2) Claim 8 — adapter/fake aliasing divergence (adapter aliases caller bytes, fake copies) could let the contract suite pass while real OPFS behavior differs under buffer mutation.
