# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-corpus-clean, detached at 4de2b00)
**Scope:** `git diff dc6dfb0..4de2b00 -- app/` (corpus S0/S1 changeset + review-fix commit); app/ only, docs/** used as reference evidence only
**Checked:** 2026-08-06
**Total claims checked:** 28 (merged clusters from 3 replicate reports: r1=22, r2=27, r3=24 claims)
**Summary:** 17 Verified, 9 Mostly accurate, 1 Incorrect, 0 Stale, 1 Unverifiable. All three replicates independently found the same single Incorrect claim: the pre-existing "fresh ArrayBuffer view" comment at the OPFS write site (opfsAdapter.ts:124) — the code passes the caller's array as-is and never has done otherwise. All three agree the A4 manifest docstring is improved but still overstates fail-loudness (element-level malformations silently filtered; `label` defaults). The C2 production guard is correctly ordered ahead of both enable paths in source, but all three replicates flag the same residual: its client-bundle efficacy rests on Next.js/Turbopack inlining the optional-chained `process.env?.NODE_ENV` / `process.env?.NEXT_PUBLIC_CORPUS_FS` forms, unconfirmable statically (no node_modules, no build output), and untested. The `readdir`-bypasses-`splitPath` gap in the C1 defense-in-depth claim was found by all three replicates (verdict split: 2× Mostly accurate, 1× Verified-with-observation).

**Commit:** 4de2b00
**Replication:** k=3 (r1, r2, r3 independent code-fact-check passes; most-severe-wins merge)

## Claim 1: flag.ts — the two enable paths (env and localStorage)

**Location:** app/lib/corpus/flag.ts:9-10
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

> "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`."

The localStorage path works and is test-verified: `localStorage.setItem(CORPUS_FLAG_KEY, "1"); ... expect(getDirectory).toHaveBeenCalled();` (workspaceStore-corpus-flag.test.ts:62-80), with `CORPUS_FLAG_KEY = "corpus-fs-enabled"` (flag.ts:13). The env path reads `process.env?.NEXT_PUBLIC_CORPUS_FS === "1"` (flag.ts:23) and works in any Node context (SSR, tests). In a browser bundle, however, `NEXT_PUBLIC_*` vars exist only if the bundler inlines the access at build time; Next.js documents inlining for direct `process.env.VAR` member accesses, and this code uses the optional-chained form, which is off the documented pattern (paraphrased — the Next.js toolchain is not vendored in this worktree, so the bundler's handling of optional chaining cannot be inspected). If not inlined, the "build-time env" enable path would silently never fire in the browser — a footgun-safe failure direction, but the docstring's "enable via" claim would then be false for the client.

**Evidence:** app/lib/corpus/flag.ts:13, 23-30; app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:60-82.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate

## Claim 2: flag.ts — C2 production hard-refuse blocks both enable paths

**Location:** app/lib/corpus/flag.ts:16-21
**Type:** Behavioral / invariant (security fix C2)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

> "Refuse to activate in a production build so the dev flag can never become an end-user data-loss footgun (security review C2)."

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

1. **Build-time inlining of the optional-chained form.** The guard's load-bearing surface is the production *client* bundle, where `process.env` is only what the bundler inlines. The code uses `process.env?.NODE_ENV` (optional chaining). r2 notes this project is on Next 16 (`package.json: "next": "^16.2.6"`), where Turbopack is the default bundler, and whether Turbopack rewrites the optional-chained member access is not verifiable from this repo (no node_modules, no build output). If the `?.` form is NOT inlined, `process.env?.NODE_ENV` is undefined in the client, the guard is skipped, and the **localStorage path could still activate in a production build** — exactly the footgun the comment claims is closed. Paraphrased — no quote available because the inlining behavior lives in the Next.js build tooling, not this repo's source.
2. **No test.** `rg -n "NODE_ENV" app/` matches only flag.ts itself; no test manipulates NODE_ENV to assert the guard. The commit message claims a test only for C1, not C2.

Server-side (SSR/dev-server) the guard is straightforwardly correct: `process` exists and `NODE_ENV` is set by Next.

**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Unverifiable

## Claim 3: flag.ts — default-off, dev-only, "no migration in S1"

**Location:** app/lib/corpus/flag.ts:4-7
**Type:** Architectural / reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "DEFAULT OFF and DEV-ONLY. In S1 there is no localStorage->corpus migration (that is S4), so enabling this starts from an EMPTY corpus"

Default-off: with no env var and no localStorage key, every branch of `isCorpusEnabled()` falls through to `return false;` (flag.ts:31). No-migration: `createCorpusBackedStorage` reads only from the CorpusFS `state/` namespace and no code copies localStorage content into it.

**Evidence:** storeAdapter.ts:60-62 `getItem: async (name) => { const bytes = await fs.readFile(pathFor(name)); return bytes ? dec.decode(bytes) : null; }` — no localStorage fallback; `rg -n 'localStorage' app/lib/corpus/` matches only flag.ts and comments (paraphrased — absence claim from grep).
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified · single-replicate-pair (absent from r1)

## Claim 4: manifest.ts — A4 docstring: fail-loud for content, only io thrown, only timestamps default

**Location:** app/lib/corpus/manifest.ts:10-16
**Type:** Behavioral / invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

> "A malformed or absent manifest surfaces as a typed `CorpusError` of kind \"io\", never a silent default-empty manifest ... The only fields that default rather than fail are the `createdAt`/`updatedAt` timestamps (metadata, not content) — every content field (title, sources, artifacts, customArtifactTypeIds) fails loud if missing or malformed."

**Accurate halves:**
- "only throws io": every throw in the module goes through `fail()`, which mints exactly one kind:
  ```ts
  // app/lib/corpus/manifest.ts:67-70
  function fail(reason: string): never {
    throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
  }
  ```
  No other `CorpusError` constructor call exists in the module (grep, single hit at line 69). Test asserts the kind (manifest.test.ts:39).
- createdAt/updatedAt do default (manifest.ts:112-113).
- Missing/wrong-typed top-level fields fail loud: `title` (line 86), `manifestVersion` (line 87), non-array `sources` (line 94), non-array `artifacts` (line 103), non-array `customArtifactTypeIds` (line 107).

**Overstated half — "every content field fails loud if missing or malformed" is not true at element level:**
- Non-object entries inside `sources` and `artifacts` are silently dropped, not failed: `raw.sources.filter(isObject).map(...)` (manifest.ts:90), `raw.artifacts.filter(isObject).map(...)` (manifest.ts:97).
- Non-string entries inside `customArtifactTypeIds` are silently filtered (manifest.ts:105-106).
- `label` is a content field that defaults (to the id) rather than failing: `label: typeof s.label === "string" ? s.label : s.id` (manifest.ts:92).

So a manifest whose `sources` array contains, say, three strings and no objects parses "successfully" to `sources: []` — a partial silent-default of exactly the shape the docstring says never happens. Object-shaped entries missing `id`/`ext` or `type`/`currentVersion` do fail loud (lines 91, 98-100; tested at manifest.test.ts:46-51). The commit-message A4 claim inherits the same overstatement.

**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

## Claim 5: manifest.ts — parseManifest "throws on any malformation"; null input is an error

**Location:** app/lib/corpus/manifest.ts:72-78
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

> "Parse + validate manifest bytes. Throws a `CorpusError` on any malformation — ... passing `null` here is itself an error."

The null half is Verified: `if (bytes === null) fail("manifest file is absent");` (manifest.ts:78), tested at manifest.test.ts:42-44 (`expect(() => parseManifest(null)).toThrow(CorpusError)`). "Throws on any malformation" inherits the same element-level filtering exception documented under Claim 4 (non-object array entries and non-string type ids are dropped, not thrown). Same evidence, not repeated.

**Evidence:** app/lib/corpus/manifest.ts:78, 90, 97, 106; app/lib/corpus/__tests__/manifest.test.ts:42-44.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified

## Claim 6: manifest.ts — ArtifactPointer / currentVersion file convention

**Location:** app/lib/corpus/manifest.ts:23-24 (r2 also 5-8)
**Type:** Reference / behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "`currentVersion` is the 1-based version number whose file is artifacts/<type>/v####.md."

Matches the path builder's contract exactly:
```ts
// app/lib/corpus/paths.ts:105-110
export function artifactVersionPath(slug: string, artifactType: string, version: number): string {
  if (!Number.isInteger(version) || version < 1) {
    throw new Error(`artifact version must be a positive integer, got ${version}`);
  }
  const v = String(version).padStart(VERSION_PAD, "0");
  return `${artifactDir(slug, artifactType)}/v${v}.md`;
```
with `VERSION_PAD = 4` (paths.ts:23) and test `expect(artifactVersionPath(s, "semiformal", 1)).toBe("workspaces/my-slug/artifacts/semiformal/v0001.md")` (paths.test.ts:55). The schema stores only `{ type, currentVersion }` pointers (manifest.ts:25-28) — the manifest only points, bytes live in files.

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 7: opfsAdapter.ts — header contracts (unavailable guard; quota reification; A3-fixed storeAdapter reference)

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
   Tested for all five methods (opfsAdapter.test.ts:26-47, kind asserted at line 37).
2. "a quota failure rejects with {kind:"quota-exceeded", substrate:"opfs"} — it is NOT swallowed with console.warn" — `wrap()` at opfsAdapter.ts:88-92 (`if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` line 90), tested at opfsAdapter.test.ts:50-82.
3. The A3-fixed reference "(createDebouncedLocalStorage in storeAdapter.ts)" is now correct — that function does swallow with console.warn (storeAdapter.ts:36-39). The pre-fix stale form (`workspaceStore.ts:44-46`) appears nowhere in app/ anymore (grep empty; the 4de2b00 diff shows the replacement).

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 8: opfsAdapter.ts — C1 splitPath traversal rejection ("adapter must not trust callers")

**Location:** app/lib/corpus/opfsAdapter.ts:60-66
**Type:** Behavioral / security invariant (C1 fix)
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

> "Defense-in-depth: paths.ts is the sanitizing choke point, but the adapter must not trust callers to have used it. Reject traversal/backslash segments rather than resolving them."

The rejection logic is present and correct for every method that calls `splitPath`:
```ts
// app/lib/corpus/opfsAdapter.ts:63-67
for (const seg of parts) {
  if (seg === "." || seg === ".." || seg.includes("\\")) {
    throw new CorpusError({ kind: "io", path, reason: `unsafe path segment: ${seg}` });
  }
}
```
Test coverage exists: `fs.writeFile("workspaces/s/../../escape.txt", ...)` must reject with kind "io" (opfsAdapter.test.ts:85-103) — so the commit's "+ test" is accurate.

The "the adapter must not trust callers" framing is wider than the implementation: `readdir` does not go through `splitPath` — it splits inline without the rejection loop:
```ts
// app/lib/corpus/opfsAdapter.ts:134-137
async readdir(path) {
  try {
    const root = await getRoot();
    const dirs = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
```
so a `..` segment passed to `readdir` reaches `getDirectoryHandle("..")` un-rejected (real OPFS itself rejects invalid names at the platform layer, and readdir is read-only, so exposure is low — but the adapter-level guard covers 4 of 5 methods, not all calls). The commit-message form of the claim ("splitPath rejects ./../backslash segments") is literally accurate.

**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified

## Claim 9: opfsAdapter.ts — "fresh ArrayBuffer view" write-site comment

**Location:** app/lib/corpus/opfsAdapter.ts:124
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

> "// Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

The code passes the caller's `bytes` argument directly — no fresh view or copy is constructed:

**Evidence:**
```ts
// app/lib/corpus/opfsAdapter.ts:123-126
try {
  // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
  await w.write(bytes);
} finally {
```
`bytes` is the raw `writeFile(path, bytes)` parameter (line 116). The comment describes an action (`new Uint8Array(bytes)` or `bytes.slice()`) that the code does not perform; a caller passing a view over a SharedArrayBuffer or a mutated-after-call buffer gets exactly the "shared buffer" behavior the comment says is avoided. The comment was NOT touched by the fix commit — it appears verbatim in the original S1 commit (r1: `git show f6361a3:app/lib/corpus/opfsAdapter.ts`, identical text; r2 confirms via `git log -L120,130:app/lib/corpus/opfsAdapter.ts 4de2b00` that the comment+call were introduced together in f6361a3 and never modified). Contrast with the in-memory fake, which really does copy: `files.set(normalize(path), bytes.slice());` with comment "Copy so later mutation of the caller's array can't alter stored bytes" (inMemoryCorpusFs.ts:26-27) — so the fake and the adapter also diverge in aliasing behavior. Either make the copy or fix the comment.

**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

## Claim 10: opfsAdapter.ts — walkDir docstring

**Location:** app/lib/corpus/opfsAdapter.ts:73-74
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Walk (optionally creating) directory handles for the given segments. Returns null when `create` is false and a segment is missing."

**Evidence:** opfsAdapter.ts:79-82 `cur = await cur.getDirectoryHandle(d, { create }); } catch (e) { if (!create && isNotFound(e)) return null; throw e; }`.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection

## Claim 11: opfsAdapter.ts — rm idempotency comments

**Location:** app/lib/corpus/opfsAdapter.ts:153, 157
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "// idempotent: parent dir missing -> nothing to remove" and "// idempotent: file already gone"

**Evidence:** opfsAdapter.ts:153 `if (!dir) return;` and opfsAdapter.ts:156-157 `} catch (e) { if (isNotFound(e)) return;` — matching the CorpusFS interface doc (types.ts:121 "Idempotent: resolves (no-op) if the path does not exist."). Contract suite covers it: corpusFsContract.ts:49-56.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified

## Claim 12: paths.ts — "only source of corpus paths" / choke-point claim (A2 outcome)

**Location:** app/lib/corpus/paths.ts:15-19
**Type:** Architectural / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`."

Post-A2 this now holds for production code. The one prior violation (the hand-built blob path) was routed through the builder:
```ts
// app/lib/corpus/storeAdapter.ts:58
const pathFor = (name: string) => stateBlobPath(name);
```
(pre-fix, per `git show 4de2b00^:app/lib/corpus/storeAdapter.ts`: `` const pathFor = (name: string) => `state/${name}.json`; ``). `rg -n "stateBlobPath|STATE_DIR" app/` hits only paths.ts (definitions) and storeAdapter.ts (import + use); greps for string-built corpus paths (`"workspaces/`, `` `state/ ``) find none outside `__tests__` fixtures (paraphrased — absence claims from grep). manifest.ts's literal `"workspace.json"` (manifest.ts:69) is an error-detail label, not a path handed to a `CorpusFS`. Test files hand-concatenate paths as fixtures asserting the layout, not violating the caller rule. The choke-point sentence is scoped to "untrusted workspace titles", which is exactly `workspaceSlug`'s job (paths.ts:36-47).

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 13: paths.ts — SAFE_SEGMENT / workspaceSlug sanitization guarantees

**Location:** app/lib/corpus/paths.ts:26-35
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Everything else is collapsed to a hyphen so a value can never contain \"/\", \"\\\\\", \".\" runs, or control characters that would let it escape its directory." and "Strips path separators, dot-segments, and unicode; collapses runs of unsafe characters to a single hyphen; trims leading/trailing hyphens. Throws if nothing safe remains"

**Evidence:**
```ts
// app/lib/corpus/paths.ts:28
const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;
```
The allowlist excludes `/`, `\`, `.`, and all control characters, so no output of `workspaceSlug`/`safeSegment` can contain them (conservative — no `.` at all survives, not just runs). The pipeline `.replace(SAFE_SEGMENT, "-").replace(/-{2,}/g, "-").replace(/^-+|-+$/g, "")` then `if (!slug) { throw ... }` (paths.ts:37-46). Tested: `expect(workspaceSlug("../etc/passwd")).not.toContain("..")` / `.not.toContain("/")` (paths.test.ts:17-18), collapse/trim (paths.test.ts:23-26), and empty-slug throws on `"////"` and `"。。。"` (paths.test.ts:28-32).

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 14: paths.ts — S1 blob-mode breadcrumb (STATE_DIR / stateBlobPath, A2 fix)

**Location:** app/lib/corpus/paths.ts:70-84
**Type:** Architectural + reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Breadcrumb claims: (a) "In S1 the whole Zustand persist blob is written as a single file under `state/` (see storeAdapter.createCorpusBackedStorage)"; (b) "Routed through this builder ... so the namespace fork is greppable and the name goes through the same `safeSegment` sanitization as every other path."

**Evidence:**
- (a) The referenced function exists and writes one file per persist key: `setItem: async (name, value) => { await fs.writeFile(pathFor(name), enc.encode(value)); }` (storeAdapter.ts:64-66). Confirmed at the `state/` location by test: `const bytes = await fs.readFile("state/workspace-zustand-v1.json");` (workspaceStore-corpus-flag.test.ts:49).
- (b) `stateBlobPath` uses `safeSegment`: `export const STATE_DIR = "state"; ... return `${STATE_DIR}/${safeSegment(name)}.json`;` (paths.ts:82-85). Greppability confirmed — `rg stateBlobPath` finds the fork in 2 files.

Minor nuance, below verdict-changing threshold: "the same `safeSegment` sanitization as every other path" is loose — workspace segments go through `workspaceSlug` (which shares the same `SAFE_SEGMENT` regex but also lowercases) and extensions through `safeExt`; `safeSegment` itself is what sourcePath/artifactDir/customTypePath use (paths.ts:96, 100, 118).

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 15: paths.ts — artifactVersionPath example + 1-based

**Location:** app/lib/corpus/paths.ts:103-104
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "artifactVersionPath(s,\"semiformal\",1) -> \"workspaces/<s>/artifacts/semiformal/v0001.md\". `version` is 1-based."

**Evidence:** paths.test.ts:55 `expect(artifactVersionPath(s, "semiformal", 1)).toBe("workspaces/my-slug/artifacts/semiformal/v0001.md");`; rejection of 0 and 1.5 at paths.test.ts:59-60; guard at paths.ts:106.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection

## Claim 16: storeAdapter.ts — S1 blob-mode header

**Location:** app/lib/corpus/storeAdapter.ts:10-14
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode) — the files-per-artifact folder layout (paths.ts/manifest.ts) is built but not used by the store until S4. ... The blob path goes through `stateBlobPath` in paths.ts."

**Evidence:** `createCorpusBackedStorage` reads/writes/removes exactly one path per store name via `pathFor = (name) => stateBlobPath(name)` (storeAdapter.ts:58-70). The store side imports nothing from manifest.ts or the workspace-layout builders: workspaceStore.ts's only corpus import is `import { resolveWorkspaceStorage } from "@/app/lib/corpus/storeAdapter";` (workspaceStore.ts:25), and `rg -n "manifest|workspaceDir|artifactVersionPath" app/lib/stores/` returns no hits (paraphrased — empty grep result).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection

## Claim 17: storeAdapter.ts — "moved verbatim ... byte-for-byte the prior behavior"; 300ms debounce

**Location:** app/lib/corpus/storeAdapter.ts:24-27
**Type:** Behavioral / historical
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Default: debounced localStorage (moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior — see the characterization test). Reads are synchronous (instant); writes are debounced by 300ms."

**Evidence:** compared against the pre-change source `git show dc6dfb0:app/lib/stores/workspaceStore.ts` — the function body (getItem/setItem/removeItem, the `pending` timer, the 300ms constant, the console.warn catch) is line-for-line identical; only the function name (`createDebouncedStorage` → `createDebouncedLocalStorage`) and the return-type annotation (inline object type → `StateStorage`) differ, neither of which changes behavior (r3 independently confirmed the same via the 00ba8c3 diff). The 300ms figure: `}, 300);` (storeAdapter.ts:41). The referenced characterization test exists at app/lib/stores/__tests__/workspaceStore-characterization.test.ts, and the OFF-path routing test flushes exactly 300ms: `vi.advanceTimersByTime(300);` (workspaceStore-corpus-flag.test.ts:32).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 18: storeAdapter.ts — seam selection and CorpusFS typing (arch-review finding 3)

**Location:** app/lib/corpus/storeAdapter.ts:4-8, 55
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "The injection seam is typed as `CorpusFS` ... so the S3 worker-proxy implementation drops in here without the store ever knowing which adapter it talks to."

**Evidence:** storeAdapter.ts:55 `export function createCorpusBackedStorage(fs: CorpusFS): StateStorage` (interface import at storeAdapter.ts:18); selection at storeAdapter.ts:74-79 `if (isCorpusEnabled()) { return createCorpusBackedStorage(createOpfsCorpusFs()); } return createDebouncedLocalStorage();`; the store imports only `resolveWorkspaceStorage` (workspaceStore.ts:25) and never a concrete adapter. Routing-through-injected-fake tested at workspaceStore-corpus-flag.test.ts:41-57; OFF default at :36; flag-on OPFS at :61-82.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified

## Claim 19: workspaceStore.ts — storage-seam comment at the persist options

**Location:** app/lib/stores/workspaceStore.ts:496-499
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

> "Storage seam is selected here (DD-009 S1): debounced localStorage by default, or a CorpusFS-backed adapter when the dev flag is on. The seam is typed as CorpusFS so the S3 worker-proxy is a drop-in."

The selection claim is Verified: `storage: createJSONStorage(resolveWorkspaceStorage)` (workspaceStore.ts:499) with `resolveWorkspaceStorage` branching on `isCorpusEnabled()` (storeAdapter.ts:74-79), tested both ways (workspaceStore-corpus-flag.test.ts:24-37 and 60-82). The typing claim is loose at this location: the value bound *here* is a `StateStorage` factory — the CorpusFS-typed seam is one level down, `createCorpusBackedStorage(fs: CorpusFS)` (storeAdapter.ts:55), where the S3 worker-proxy would be injected. The claim's substance survives, but "the seam" as read at this comment (the `storage:` option) is not typed `CorpusFS`.

**Evidence:** app/lib/stores/workspaceStore.ts:499; app/lib/corpus/storeAdapter.ts:55, 74-79.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection

## Claim 20: storeAdapter.ts — "Selected once when the store's persist middleware initializes"

**Location:** app/lib/corpus/storeAdapter.ts:73
**Type:** Behavioral / timing
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The resolver is passed as `storage: createJSONStorage(resolveWorkspaceStorage)` (workspaceStore.ts:499), evaluated when `create(persist(...))` runs at module load. Paraphrased — no quote available because `node_modules` is not installed in this worktree: in zustand v5 (package.json: `"zustand": "^5.0.13"`), `createJSONStorage(getStorage)` invokes `getStorage()` once, eagerly, when `createJSONStorage` itself is called, and closes over the result for all subsequent getItem/setItem calls. That matches "selected once when the persist middleware initializes": the flag is read once per page load, not per write, so toggling localStorage mid-session takes effect only after reload. Confidence Medium in all three replicates because the zustand implementation could not be read from disk here.

**Evidence:** app/lib/stores/workspaceStore.ts:496-499; package.json (`"zustand": "^5.0.13"`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 21: types.ts — CorpusFS interface contracts (null/[] not-found; never undefined; mkdir-on-write)

**Location:** app/lib/corpus/types.ts:17-18, 106-125
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "\"Not found\" is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`." and "Implementations create intermediate directories on write."

**Evidence:** OPFS adapter: `if (isNotFound(e)) return null;` for readFile (opfsAdapter.ts:106) and stat (opfsAdapter.ts:175), `if (!dir) return [];` for readdir (opfsAdapter.ts:139), all other failures funnel through `wrap()` which always throws a `CorpusError` (opfsAdapter.ts:88-92); mkdir-on-write via `const dir = await walkDir(root, dirs, true);` (opfsAdapter.ts:120, `getDirectoryHandle(d, { create })` at line 79). In-memory fake: `return files.get(normalize(path)) ?? null;` (inMemoryCorpusFs.ts:22) — the `?? null` is precisely the undefined-suppression the claim requires; directories are implicit (inMemoryCorpusFs.ts:8). Contract-tested for both: null/[]/stat at corpusFsContract.ts:21-28, intermediate-directory creation at corpusFsContract.ts:41-47.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 22: types.ts — CorpusErrorKind is "the complete set"; compile-time exhaustiveness

**Location:** app/lib/corpus/types.ts:36-49
**Type:** Architectural / contract
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "The complete set of corpus failure kinds. Every exhaustive `switch` over a corpus error binds to this union; adding a kind here forces every consumer to handle it at compile time."

**Evidence:** The union declares 8 kinds (types.ts:41-49). The one exhaustive switch that exists, `describeCorpusError`, covers all 8 with an `assertNever` default (types.ts:78-90). For synthesis: post-fix, only three kinds are actually constructible from shipped code paths — `"unavailable"` (opfsAdapter.ts:53), `"quota-exceeded"` (opfsAdapter.ts:90), and `"io"` (opfsAdapter.ts:65, 69, 91; manifest.ts:69). The other five (`not-found`, `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, `git-conflict`) have no producers (grep over app/ hits only types.ts); `not-found` is unproduced by design (readFile/stat return null instead). The docstring claims completeness of the *kind set*, not that all kinds are currently produced — the S2/S3/S4 forward references in the header (types.ts:5-8) make the forward-looking intent explicit, so this is not stale.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified

## Claim 23: types.ts — CorpusWorkerError "differ only in transport, never in the kind set"

**Location:** app/lib/corpus/types.ts:27-28, 61-70
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** types.ts:63-66 `export type CorpusWorkerError = { __corpusError: true; detail: CorpusErrorKind; message: string; }` — `detail` is the same `CorpusErrorKind` union, and types.ts:70 `return { __corpusError: true, detail: err.detail, message: err.message };` copies it unchanged. No second kind enumeration exists (`rg -n 'CorpusErrorKind' app/` matches only types.ts).
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified

## Claim 24: opfsAdapter.test.ts + corpusFsContract.ts — "success path is covered ... against real OPFS out-of-CI (Playwright)"

**Location:** app/lib/corpus/__tests__/opfsAdapter.test.ts:5-7 (also corpusFsContract.ts:4-6, corpusFs.contract.test.ts:1-3)
**Type:** Reference / test-coverage
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

> "The adapter's *success* path is covered by the shared CorpusFS contract suite run against real OPFS out-of-CI (Playwright, step 9) — here we only assert that failures become typed CorpusErrors."

The in-CI half is accurate: the contract suite runs against the fake (`defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());`, corpusFs.contract.test.ts:8) and opfsAdapter.test.ts indeed asserts only error mapping. But "is covered ... run against real OPFS" overstates: the referenced smoke exists as a documented procedure, not an executed run. Evidence (docs used as reference evidence only, per scope):
```
// docs/spikes/corpus-opfs-smoke.md — ## Results
_(not yet run — fill in when executed before enabling the flag in a shared environment)_
```
Commit 4de2b00's own message agrees: "Remaining 🟢 items (walkDir handle caching, async un-debounced seam, **run the OPFS smoke**) carried to S2/S3/S5." So at this commit the OPFS success path is covered by a *planned* out-of-CI check, not by any run.

**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Verified

## Claim 25: workspaceStore.ts — header "custom debounced storage adapter rate-limits writes"

**Location:** app/lib/stores/workspaceStore.ts:5
**Type:** Behavioral / staleness
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
The commit message itself acknowledges the gap ("async un-debounced seam" carried to S2/S3), so this is a known, deliberate divergence — but the header sentence, unqualified, no longer describes all configurations of the store it heads. The affected path is dev-only, so this is drift, not a live-user inaccuracy.

**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

## Claim 26: commit 4de2b00 — mechanical fix claims A1, A2, A3, C1 (+ "review artifacts under docs/reviews/")

**Location:** commit 4de2b00 message, body bullets A1/A2/A3/C1
**Type:** Behavioral / reference (commit message)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

- **A1** "WorkspaceManifest.customTypeIds -> customArtifactTypeIds ... no consumers yet": `rg -n "customTypeIds|customArtifactTypeIds" app/` shows zero remaining bare `customTypeIds` occurrences — all hits are the new name in manifest.ts and its test. "No consumers yet" holds: no file outside manifest.ts + manifest.test.ts references the field (the store's similarly-named `customArtifactTypes` is a different, pre-existing field — workspaceStore.ts:169).
- **A2** "route the S1 blob path through paths.ts stateBlobPath() + STATE_DIR with an S4-reconciliation breadcrumb": Verified under Claims 12/14 (stateBlobPath at paths.ts:83-85; storeAdapter.ts:58 uses it; breadcrumb at paths.ts:70-81).
- **A3** "fix stale comments (layout.ts->paths.ts; workspaceStore.ts:44-46 ref -> storeAdapter)": `rg -n "layout\.ts" app/` returns no hits, and the opfsAdapter header now cites `createDebouncedLocalStorage in storeAdapter.ts` (opfsAdapter.ts:14-15; the fix diff shows the old `workspaceStore.ts:44-46` text removed).
- **C1** "opfsAdapter splitPath rejects ./../backslash segments (defense-in-depth) + test": Verified under Claim 8 (opfsAdapter.ts:63-67; test at opfsAdapter.test.ts:85-103). The readdir-bypass nuance does not contradict the literal claim, which names `splitPath`.
- "Review artifacts under docs/reviews/": the directory exists and contains the artifacts named by the message (directory listing; evidence-only per scope; r2 Claim 26).

**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 27: commit 4de2b00 — fix claims A4 and C2

**Location:** commit 4de2b00 message, body bullets A4/C2
**Type:** Behavioral (commit message)
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

- **A4** "manifest docstring matches behavior (only throws io; createdAt/updatedAt default while content fails loud)": "only throws io" and the timestamp defaults are Verified (Claim 4 evidence). "content fails loud" remains overstated at element level — non-object `sources`/`artifacts` entries and non-string `customArtifactTypeIds` entries are silently filtered, and `label` defaults (manifest.ts:90, 92, 97, 106). The docstring now *better* matches behavior than before the fix, but "matches" is not fully achieved.
- **C2** "flag.ts hard-refuses to activate in a production build": the guard exists and precedes both enable paths (flag.ts:21, Claim 2), but the client-bundle guarantee depends on Next.js inlining the `process.env?.NODE_ENV` optional-chaining form (unconfirmable statically here) and the guard has no test — see Claim 2.

**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (assessed within its Claims 2/6, which state the commit A4/C2 claims inherit the same caveats) · r3=—

## Claim 28: commit-message verification claims — "lint clean, build passes, 325 tests pass" (and sibling counts)

**Location:** commit 4de2b00 message, "Verified:" line (also 122d70f "324 vitest tests pass", f6361a3 "3 tests pass", 00ba8c3 "69 corpus+store tests")
**Type:** Verification claim
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The worktree has no node_modules, so `vitest`, `next build`, and ESLint cannot be run, and the run counts cannot be reproduced statically because the shared contract suite registers tests dynamically. Consistency checks that *are* possible all pass: 122d70f claims 324 tests, 4de2b00 adds exactly one test (the C1 traversal test is the only `it()` added in its diff) and claims 325 — arithmetically consistent; f6361a3's "3 tests pass" matches the three `it()` blocks in its version of opfsAdapter.test.ts (`git show f6361a3:... | rg -c "  it\("` → 3); static `it(` magnitude across the suite (~308 static occurrences plus contract-suite and `it.each` expansions) is consistent with ~325 at runtime but not provable. Nothing in the source contradicts any of the claims.

**Evidence:** git log for the commits; empty node_modules; static it-counts as described.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable

## Claims Requiring Attention

### Incorrect
- **Claim 9** — opfsAdapter.ts:124 "Pass a fresh ArrayBuffer view" comment: no fresh view or copy is made; `w.write(bytes)` passes the caller's array as-is. Pre-existing (introduced verbatim in f6361a3), untouched by the fix commit. Either make the copy (as the in-memory fake does at inMemoryCorpusFs.ts:27) or fix the comment. Found independently by all three replicates.

### Stale
- (none)

### Mostly Accurate
- **Claim 1** — flag.ts:9-10 enable paths: localStorage path verified; the "build-time env" path uses optional-chained `process.env?.NEXT_PUBLIC_CORPUS_FS`, off Next.js's documented direct-reference inlining pattern — client-bundle behavior unconfirmed.
- **Claim 2 / Claim 27 (C2)** — flag.ts production guard: logic is first-in-line for both enable paths, but the production-build guarantee rides on Next.js (Turbopack under Next 16) inlining the optional-chained `process.env?.NODE_ENV` form (statically unconfirmable here) and has no test. If not inlined, the localStorage enable path stays live in production — the exact footgun C2 claims to close.
- **Claim 4 / Claim 5 / Claim 27 (A4)** — manifest.ts docstring: "every content field fails loud" is untrue at element level (non-object array entries and non-string ids silently filtered — manifest.ts:90, 97, 106; `label` defaults to id — manifest.ts:92).
- **Claim 8** — opfsAdapter splitPath comment implies adapter-wide distrust of callers, but `readdir` bypasses the rejection loop (opfsAdapter.ts:137); covers 4 of 5 methods.
- **Claim 19** — workspaceStore.ts:498 "The seam is typed as CorpusFS": the seam at that line is `StateStorage`; the CorpusFS-typed injection point is `createCorpusBackedStorage` in storeAdapter.ts.
- **Claim 24** — "success path is covered ... against real OPFS out-of-CI": the Playwright smoke is documented but its Results section reads "not yet run"; the commit message itself lists running it as remaining.
- **Claim 25** — workspaceStore.ts:5 "debounced storage adapter rate-limits writes" is false on the flag-on corpus path (un-debounced write-through, acknowledged in the commit message; dev-only).

### Unverifiable
- **Claim 28** — "lint clean, build passes, 325 tests pass" (and sibling counts): process/environment claims; static inspection can neither confirm nor refute; all static deltas and magnitudes are consistent.

## Verdict stability

- **Total clusters:** 28
- **Agreed (all present replicate verdicts identical):** 23
- **Disagreements:** 5
  - Claim 1 (flag.ts enable paths): r1=Verified · r2=Verified · r3=Mostly accurate → merged Mostly accurate
  - Claim 2 (flag.ts C2 production guard): r1=Mostly accurate · r2=Mostly accurate · r3=Unverifiable → merged Mostly accurate
  - Claim 5 (parseManifest null / "any malformation"): r1=Mostly accurate · r2=Verified · r3=Verified → merged Mostly accurate
  - Claim 8 (splitPath C1 defense-in-depth): r1=Mostly accurate · r2=Mostly accurate · r3=Verified → merged Mostly accurate
  - Claim 24 (OPFS success path via Playwright smoke): r1=Mostly accurate · r3=Verified (r2 absent) → merged Mostly accurate
- **Agreement rate:** 23/28 = 82%
- Single-replicate detections: 4 clusters (Claim 10 walkDir, r2 only; Claim 15 artifactVersionPath, r2 only; Claim 16 storeAdapter blob-mode header, r1 only; Claim 19 workspaceStore seam comment, r1 only). All disagreements are one-step (Verified ↔ Mostly accurate, or Mostly accurate ↔ Unverifiable); no replicate contradicted another's Incorrect finding, and the sole Incorrect claim was found 3/3.

## Goal-Alignment Note
- Answered: All eight items in the shared brief, covered by all three replicates — C2 guard mechanics for both enable paths and the `process.env` inlining question (Claims 1, 2); A4 manifest docstring halves against the codec, including the element-level throw-vs-filter breakdown (Claims 4, 5); paths.ts single-source claim (pre-fix violation confirmed removed) and S4 breadcrumb (Claims 12, 14); C1 splitPath rejection + test coverage, the readdir bypass, and the untouched "fresh ArrayBuffer view" comment (Claims 8, 9); A3 stale-reference sweep (Claims 7, 26); workspaceStore/storeAdapter debounce, verbatim-move, and storage-selection-timing claims (Claims 17, 18, 19, 20, 25); commit-message fix claims A1–A4/C1–C2 and static test-count consistency (Claims 26, 27, 28); producible CorpusErrorKind set — io/unavailable/quota-exceeded only post-fix (Claim 22).
- Out of scope (all replicates concur): docs/** content accuracy (used only as reference/existence evidence); the "0 red, 4 amber" review-outcome framing in the commit message; the out-of-CI Playwright smoke's actual execution; root CLAUDE.md corpus paragraph (not app/); opinion/intent comments and whether the review-fix choices were *good* fixes (fact-check, not review).
- Escalate (union of replicate escalations, deduplicated):
  1. **C2 guard / NODE_ENV + NEXT_PUBLIC inlining (r1, r2, r3):** the production guard's client-bundle efficacy depends on the bundler (Next 16 / Turbopack) inlining the optional-chained `process.env?.NODE_ENV` / `process.env?.NEXT_PUBLIC_CORPUS_FS` accesses — untested and unprovable from the repo. This is the only finding with plausible end-user data-loss consequences: if not inlined, the localStorage enable path stays live in production. A production-build smoke assertion (`NODE_ENV=production` bundle grep) or a one-line rewrite to the non-optional-chained `process.env.NODE_ENV` form (which Next.js documents replacing), plus a guard test, would settle it before the flag ships anywhere.
  2. **readdir bypasses splitPath (r3; observed by r1, r2):** `readdir` (opfsAdapter.ts:137) splits inline and skips the C1 traversal rejection — low exposure (read-only, native OPFS rejects `..` names) but inconsistent with the "must not trust callers" stance; the adapter-level guard covers 4 of 5 methods.
  3. **ArrayBuffer copy decision / adapter–fake aliasing divergence (r1, r2, r3):** if some OPFS implementations really reject shared buffers, the *code* is the bug, not the comment — worth a decision, not just a comment edit. The adapter aliases caller bytes while the in-memory fake copies (inMemoryCorpusFs.ts:27), so the contract suite could pass while real OPFS behavior differs under buffer mutation.
