# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-corpus-clean, detached)
**Scope:** `git diff dc6dfb0..4de2b00 -- app/` (corpus S0/S1 + review-fix commit 4de2b00); docs/** out of scope except as reference evidence
**Checked:** comments/docstrings in app/lib/corpus/{flag,manifest,opfsAdapter,paths,storeAdapter,types}.ts, app/lib/stores/workspaceStore.ts, corpus test headers, and commit messages ec7bbbc..4de2b00
**Total claims checked:** 27
**Summary:** 19 Verified, 6 Mostly accurate, 1 Incorrect, 1 Unverifiable. The one Incorrect claim is the pre-existing "fresh ArrayBuffer view" comment at the OPFS write site (opfsAdapter.ts:124), which does not match the code and was NOT touched by the review-fix commit. The A4 manifest docstring fix is an improvement but still overstates fail-loudness (malformed array *elements* are silently filtered, and `label` defaults). The C1 defense-in-depth comment is accurate for `splitPath` but `readdir` bypasses `splitPath` entirely. The C2 production guard is correctly ordered ahead of both enable paths, with a residual bundler-inlining question on the optional-chained `process.env?.` accesses.

**Commit:** 4de2b00

## Claim 1: flag.ts enable paths (env or localStorage)
**Location:** app/lib/corpus/flag.ts:9-10
**Type:** configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`."

Both paths exist and the key matches the constant.

**Evidence:** flag.ts:13 `export const CORPUS_FLAG_KEY = "corpus-fs-enabled";`; flag.ts:23 `if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;`; flag.ts:26 `return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";`. Exercised by workspaceStore-corpus-flag.test.ts:62 `localStorage.setItem(CORPUS_FLAG_KEY, "1");` → OPFS path selected (line 80).

## Claim 2: flag.ts production hard-refuse (C2)
**Location:** app/lib/corpus/flag.ts:16-21 (and commit 4de2b00 "C2: flag.ts hard-refuses to activate in a production build")
**Type:** behavioral / invariant
**Verdict:** Mostly accurate
**Confidence:** Medium — logic verified by reading; client-bundle inlining behavior not verifiable from the repo
**Legibility-target:** for-author

> "Refuse to activate in a production build so the dev flag can never become an end-user data-loss footgun (security review C2)."

The guard is correctly placed BEFORE both enable paths, so in any environment where `process.env.NODE_ENV === "production"` is observable, both the env path and the localStorage path are blocked:

**Evidence:** flag.ts:21 `if (typeof process !== "undefined" && process.env?.NODE_ENV === "production") return false;` precedes flag.ts:23 (env path) and flag.ts:24-30 (localStorage path).

Caveat (the reason for Mostly accurate rather than Verified): the guard's load-bearing surface is the production *client* bundle (the flag is consumed at module load in the browser — see Claim 21), where `process.env` is only what the bundler inlines. Both accesses use optional chaining (`process.env?.NODE_ENV`, `process.env?.NEXT_PUBLIC_CORPUS_FS`). webpack 5's DefinePlugin handles optional-chained forms of defined expressions, but this project is on Next 16 (`package.json:23 "next": "^16.2.6"`), where Turbopack is the default bundler, and whether Turbopack rewrites the optional-chained member access is not verifiable from this repo (no node_modules in the worktree). If the access were NOT inlined, `process.env?.NODE_ENV` would be undefined in the client and the guard would silently not fire — while the commit message says "build passes," nothing in the repo demonstrates the guard was observed firing in a production bundle, and there is no test setting NODE_ENV=production (workspaceStore-corpus-flag.test.ts covers G13/G14/G15 only). Paraphrased — no quote available for Turbopack/webpack inlining semantics because that behavior lives in the toolchain, not this repository.

## Claim 3: flag.ts "no migration in S1"
**Location:** app/lib/corpus/flag.ts:4-7
**Type:** architectural / reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "In S1 there is no localStorage->corpus migration (that is S4), so enabling this starts from an EMPTY corpus"

Consistent with the code: `createCorpusBackedStorage` reads only from the CorpusFS `state/` namespace and no code copies localStorage content into it. The only migration in the tree is the old v2→zustand localStorage migration, which writes via the *selected* storage.

**Evidence:** storeAdapter.ts:60-62 `getItem: async (name) => { const bytes = await fs.readFile(pathFor(name)); return bytes ? dec.decode(bytes) : null; }` — no localStorage fallback; `rg -n 'localStorage' app/lib/corpus/` matches only flag.ts and comments.

## Claim 4: manifest header — bytes live in files, manifest only points
**Location:** app/lib/corpus/manifest.ts:5-8, 23-24
**Type:** architectural / reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "The per-version artifact bytes live in files (artifacts/<type>/v####.md), not here — the manifest only points at the current version"
> "`currentVersion` is the 1-based version number whose file is artifacts/<type>/v####.md."

The schema stores only `{ type, currentVersion }` pointers (manifest.ts:25-28), and the referenced filename shape matches the path builder exactly.

**Evidence:** paths.ts:105-110 `artifactVersionPath` → `` `${artifactDir(slug, artifactType)}/v${v}.md` `` with `padStart(VERSION_PAD, "0")` (VERSION_PAD = 4, paths.ts:23), 1-based enforced at paths.ts:106 `if (!Number.isInteger(version) || version < 1)`.

## Claim 5: manifest codec — "only throws io"
**Location:** app/lib/corpus/manifest.ts:11-12 ("A malformed or absent manifest surfaces as a typed `CorpusError` of kind \"io\"") and commit 4de2b00 "A4: manifest docstring matches behavior (only throws io ...)"
**Type:** behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every throw in `parseManifest` funnels through `fail()`, which emits exactly one kind.

**Evidence:** manifest.ts:67-70 `function fail(reason: string): never { ... throw new CorpusError({ kind: "io", path: "workspace.json", reason }, ...) }`; `rg -n 'throw' app/lib/corpus/manifest.ts` matches only line 69. Test asserts the kind: manifest.test.ts:39 `expect((caught as CorpusError).detail.kind).toBe("io");`.

## Claim 6: manifest codec — "every content field ... fails loud if missing or malformed"
**Location:** app/lib/corpus/manifest.ts:13-16
**Type:** behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

> "The only fields that default rather than fail are the `createdAt`/`updatedAt` timestamps (metadata, not content) — every content field (title, sources, artifacts, customArtifactTypeIds) fails loud if missing or malformed."

Accurate at the *field* level: a missing/non-array `sources`, `artifacts`, or `customArtifactTypeIds`, and a missing `title`/`manifestVersion`, all fail loud (manifest.ts:86-87, 94, 103, 107), and createdAt/updatedAt do default (manifest.ts:112-113). But at the *element* level the codec silently filters rather than failing, so "malformed" content can be dropped without an error:

**Evidence:**
- manifest.ts:90 `? raw.sources.filter(isObject).map((s) => {` — a non-object element of `sources` (e.g. a string) is silently discarded, not failed.
- manifest.ts:97 `? raw.artifacts.filter(isObject).map((a) => {` — same for artifact pointers.
- manifest.ts:106 `? raw.customArtifactTypeIds.filter((x): x is string => typeof x === "string")` — a non-string custom-type id is silently dropped.
- manifest.ts:92 `label: typeof s.label === "string" ? s.label : s.id` — `label` is a content subfield that defaults (to the id) rather than failing, contradicting "only createdAt/updatedAt default".

Object-shaped elements with wrong-typed required members DO fail loud (manifest.ts:91, 98-100; tested at manifest.test.ts:46-51), so the fail-loud spirit largely holds — but a corrupted manifest whose array elements degrade to non-objects would parse "successfully" with data missing, which is exactly the masking the docstring says cannot happen. The commit-message A4 claim inherits the same overstatement.

## Claim 7: parseManifest null-input contract
**Location:** app/lib/corpus/manifest.ts:72-76
**Type:** behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "a `null` input (file absent) is the caller's responsibility to detect via `CorpusFS.readFile` returning `null`; passing `null` here is itself an error."

**Evidence:** manifest.ts:78 `if (bytes === null) fail("manifest file is absent");`; tested at manifest.test.ts:43 `expect(() => parseManifest(null)).toThrow(CorpusError);`.

## Claim 8: opfsAdapter header — unavailable guard and quota reification, with storeAdapter reference (A3)
**Location:** app/lib/corpus/opfsAdapter.ts:8-15
**Type:** behavioral + reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:\"unavailable\"}), never a raw `TypeError`" and "a quota failure rejects with {kind:\"quota-exceeded\", substrate:\"opfs\"} — it is NOT swallowed with console.warn the way the legacy localStorage adapter does (createDebouncedLocalStorage in storeAdapter.ts)."

All five methods call `getRoot()` first inside their try, and `wrap()` maps quota errors before the generic io fallback. The comparison reference is now correct post-A3: the console.warn swallow is in storeAdapter.

**Evidence:** opfsAdapter.ts:52-53 `if (!storage || typeof storage.getDirectory !== "function") { throw new CorpusError({ kind: "unavailable", ... }) }`; opfsAdapter.ts:90 `if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });`; storeAdapter.ts:38 `console.warn("Failed to persist workspace (localStorage quota exceeded):", e);`. Tests: opfsAdapter.test.ts:37 (`kind ... "unavailable"`), :40-47 (all methods), :80-81 (`quota-exceeded` + `substrate "opfs"`). The A3 rewrite is visible in `git show 4de2b00 -- app/lib/corpus/opfsAdapter.ts`: `- ... (workspaceStore.ts:44-46).` / `+ ... (createDebouncedLocalStorage in storeAdapter.ts).`

## Claim 9: splitPath defense-in-depth rejection (C1)
**Location:** app/lib/corpus/opfsAdapter.ts:60-66 (and commit 4de2b00 "C1: opfsAdapter splitPath rejects ./../backslash segments (defense-in-depth) + test")
**Type:** behavioral / invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

> "Defense-in-depth: paths.ts is the sanitizing choke point, but the adapter must not trust callers to have used it. Reject traversal/backslash segments rather than resolving them"

The rejection logic itself is correct and tested: opfsAdapter.ts:63-67 rejects `.`, `..`, and any segment containing `\` with a typed io error, and opfsAdapter.test.ts:85-103 asserts `writeFile("workspaces/s/../../escape.txt", ...)` rejects with `detail.kind === "io"` — so the commit's "+ test" is accurate.

However, "the adapter must not trust callers" is not fully delivered: `readdir` does not go through `splitPath` and performs no segment check, so a traversal segment in a `readdir` path is passed straight to `getDirectoryHandle`:

**Evidence:** opfsAdapter.ts:137 `const dirs = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);` (inside `readdir`, no rejection loop) vs. the checked path in opfsAdapter.ts:119 `const { dirs, name } = splitPath(path);` used by writeFile/readFile/rm/stat. Practical risk is low (OPFS `getDirectoryHandle` rejects invalid names like `..` at the platform layer, and readdir is read-only), but the comment's blanket adapter-level claim covers only 4 of 5 methods.

## Claim 10: walkDir docstring
**Location:** app/lib/corpus/opfsAdapter.ts:73-74
**Type:** behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Walk (optionally creating) directory handles for the given segments. Returns null when `create` is false and a segment is missing."

**Evidence:** opfsAdapter.ts:79-82 `cur = await cur.getDirectoryHandle(d, { create }); } catch (e) { if (!create && isNotFound(e)) return null; throw e; }`.

## Claim 11: "fresh ArrayBuffer view" write comment
**Location:** app/lib/corpus/opfsAdapter.ts:124
**Type:** behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

> "// Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

The next line passes the caller's `Uint8Array` unchanged — no fresh view or copy is constructed:

**Evidence:** opfsAdapter.ts:125 `await w.write(bytes);` where `bytes` is the raw `writeFile(path, bytes)` parameter (opfsAdapter.ts:116). Nothing between the comment and the write clones or re-views the buffer (no `new Uint8Array(...)`, no `.slice()`). The comment describes an action the code does not take; if a "fresh view" is actually required by some OPFS implementations, the code is missing it — if not, the comment is wrong. This line was NOT touched by the review-fix commit: `git log -L120,130:app/lib/corpus/opfsAdapter.ts 4de2b00` shows the comment+call introduced verbatim in f6361a3 and never modified. (Contrast: the in-memory fake really does copy — inMemoryCorpusFs.ts:26-27 `// Copy so later mutation of the caller's array can't alter stored bytes.` / `files.set(normalize(path), bytes.slice());` — that comment is accurate; the OPFS one is not.)

## Claim 12: rm idempotency comments
**Location:** app/lib/corpus/opfsAdapter.ts:153, 157
**Type:** behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "// idempotent: parent dir missing -> nothing to remove" and "// idempotent: file already gone"

**Evidence:** opfsAdapter.ts:153 `if (!dir) return;` and opfsAdapter.ts:156-157 `} catch (e) { if (isNotFound(e)) return;` — matching the CorpusFS interface doc (types.ts:121 "Idempotent: resolves (no-op) if the path does not exist."). Contract suite covers it: corpusFsContract.ts:49-56.

## Claim 13: paths.ts — "The only source of corpus paths is this module" (A2)
**Location:** app/lib/corpus/paths.ts:16-19
**Type:** architectural / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point"

Post-fix, this now holds for production code. The one prior violation (the hand-built blob path) was routed through `stateBlobPath`:

**Evidence:** pre-fix `git show 4de2b00^:app/lib/corpus/storeAdapter.ts` line 55: `` const pathFor = (name: string) => `state/${name}.json`; `` → post-fix storeAdapter.ts:58 `const pathFor = (name: string) => stateBlobPath(name);` with import at storeAdapter.ts:21. `rg -n '"workspaces/|\`workspaces/' app/lib/corpus --glob '!__tests__'` matches only paths.ts builders and the types.ts docstring example. Test files do hand-build paths (e.g. corpusFsContract.ts:42, workspaceStore-corpus-flag.test.ts:49), but those are fixtures asserting the layout, not callers constructing operational paths.

## Claim 14: paths.ts SAFE_SEGMENT comment
**Location:** app/lib/corpus/paths.ts:26-28
**Type:** invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Everything else is collapsed to a hyphen so a value can never contain \"/\", \"\\\\\", \".\" runs, or control characters that would let it escape its directory."

**Evidence:** paths.ts:28 `const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;` — `/`, `\`, `.`, and control characters are all outside the allowed class, so every occurrence is replaced. Tested: paths.test.ts:17-18 (`workspaceSlug("../etc/passwd")` contains neither `..` nor `/`), paths.test.ts:40-42 (safeSegment traversal).

## Claim 15: workspaceSlug docstring (strip/collapse/trim/throw)
**Location:** app/lib/corpus/paths.ts:31-35
**Type:** behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Strips path separators, dot-segments, and unicode; collapses runs of unsafe characters to a single hyphen; trims leading/trailing hyphens. Throws if nothing safe remains"

**Evidence:** paths.ts:37-46 — `.replace(SAFE_SEGMENT, "-").replace(/-{2,}/g, "-").replace(/^-+|-+$/g, "")` then `if (!slug) { throw new Error(...) }`. Tests: paths.test.ts:23-26 (collapse/trim), :28-32 (throws on `"////"` and `"。。。"`).

## Claim 16: S1 blob-mode breadcrumb (STATE_DIR / stateBlobPath)
**Location:** app/lib/corpus/paths.ts:70-84
**Type:** architectural / reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "In S1 the whole Zustand persist blob is written as a single file under `state/` (see storeAdapter.createCorpusBackedStorage). This is a SEPARATE namespace from the per-workspace folder layout below ... Routed through this builder ... so the namespace fork is greppable and the name goes through the same `safeSegment` sanitization as every other path."

**Evidence:** referenced function exists (storeAdapter.ts:55 `export function createCorpusBackedStorage(fs: CorpusFS): StateStorage {`) and stores one file per persist key (storeAdapter.ts:58, :65). `state/` is disjoint from `workspaces/` (paths.ts:88). Sanitization applied: paths.ts:84 `` return `${STATE_DIR}/${safeSegment(name)}.json`; ``. Greppability confirmed — `rg stateBlobPath` finds the fork in 2 files. ("same as every other path" is slightly loose — `workspaceDir` uses `workspaceSlug`, not `safeSegment`, but both funnel through SAFE_SEGMENT; not worth a downgrade.)

## Claim 17: artifactVersionPath example + 1-based
**Location:** app/lib/corpus/paths.ts:103-104
**Type:** behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "artifactVersionPath(s,\"semiformal\",1) -> \"workspaces/<s>/artifacts/semiformal/v0001.md\". `version` is 1-based."

**Evidence:** paths.test.ts:55 `expect(artifactVersionPath(s, "semiformal", 1)).toBe("workspaces/my-slug/artifacts/semiformal/v0001.md");`; rejection of 0 and 1.5 at paths.test.ts:59-60; guard at paths.ts:106.

## Claim 18: storeAdapter — debounced localStorage "moved verbatim", 300ms, byte-for-byte OFF path
**Location:** app/lib/corpus/storeAdapter.ts:24-27
**Type:** behavioral / staleness
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior — see the characterization test ... Reads are synchronous (instant); writes are debounced by 300ms."

Compared the bodies against the pre-range store: `git show dc6dfb0:app/lib/stores/workspaceStore.ts` lines 36-53 are line-for-line identical to storeAdapter.ts:29-48 (`getItem: (name) => localStorage.getItem(name)`, `setTimeout(... , 300)`, same `console.warn` string, same removeItem cancel). The referenced characterization test exists (app/lib/stores/__tests__/workspaceStore-characterization.test.ts) and the OFF-path routing test flushes exactly 300ms (workspaceStore-corpus-flag.test.ts:32 `vi.advanceTimersByTime(300);`).

**Evidence:** quoted above; diff of the two extracts produced no differences (paraphrased — the byte-for-byte comparison output is empty by construction; both sides quoted at storeAdapter.ts:31-47 and dc6dfb0 workspaceStore lines 38-53).

## Claim 19: storeAdapter seam typed as CorpusFS (arch-review finding 3)
**Location:** app/lib/corpus/storeAdapter.ts:5-8, 53
**Type:** architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "The injection seam is typed as `CorpusFS` ... so the S3 worker-proxy implementation drops in here without the store ever knowing which adapter it talks to."

**Evidence:** storeAdapter.ts:55 `export function createCorpusBackedStorage(fs: CorpusFS): StateStorage` (interface import at storeAdapter.ts:18 `import type { CorpusFS } from "./types";`); the store imports only `resolveWorkspaceStorage` (workspaceStore.ts:25) and never a concrete adapter. Routing-through-injected-fake tested at workspaceStore-corpus-flag.test.ts:41-57.

## Claim 20: storeAdapter — "Selected once when the store's persist middleware initializes"
**Location:** app/lib/corpus/storeAdapter.ts:73
**Type:** behavioral (timing)
**Verdict:** Verified
**Confidence:** Medium — zustand's implementation is not vendored in the worktree
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** workspaceStore.ts:499 `storage: createJSONStorage(resolveWorkspaceStorage),` inside the `persist(...)` options evaluated at module load (workspaceStore.ts:315 `export const useWorkspaceStore = create<...>()(persist(...))`). Paraphrased — no quote available for zustand internals because node_modules is absent from this worktree: zustand v5's `createJSONStorage(getStorage)` (package.json:33 `"zustand": "^5.0.13"`) invokes `getStorage()` once, eagerly, when `createJSONStorage` is called, so the selection happens exactly once at store-module evaluation and the flag is not re-read per operation. Consistent with the tests, which call `resolveWorkspaceStorage()` once and reuse the returned storage.

## Claim 21: types.ts — null/[] not-found contract
**Location:** app/lib/corpus/types.ts:17-18, 113-124
**Type:** invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "\"Not found\" is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

Both implementations conform: OPFS adapter returns null (opfsAdapter.ts:101, :106, :170-176), `[]` (opfsAdapter.ts:139), and wraps every other failure into CorpusError via `wrap` (opfsAdapter.ts:88-92, called in each method's catch); in-memory fake returns `?? null` (inMemoryCorpusFs.ts:22) and `{size}|null` (inMemoryCorpusFs.ts:50). Contract-tested at corpusFsContract.ts:21-28.

**Evidence:** quoted lines above.

## Claim 22: types.ts — CorpusWorkerError "differ only in transport, never in the kind set"
**Location:** app/lib/corpus/types.ts:27-28, 61-62
**Type:** invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** types.ts:63-66 `export type CorpusWorkerError = { __corpusError: true; detail: CorpusErrorKind; message: string; }` — `detail` is the same `CorpusErrorKind` union, and types.ts:70 `return { __corpusError: true, detail: err.detail, message: err.message };` copies it unchanged. No second kind enumeration exists (`rg -n 'CorpusErrorKind' app/` matches only types.ts).

Note for synthesis (not a doc error): of the 8 declared kinds (types.ts:41-49), post-fix producers emit only `io`, `unavailable`, and `quota-exceeded` (opfsAdapter.ts, manifest.ts). `not-found` is unproduced by design (readFile/stat return null instead), and `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, `git-conflict` are reserved for S2/S3 — consistent with the docstring's forward-looking "complete set" framing (types.ts:37-40). paths.ts throws plain `Error`, not `CorpusError` (paths.ts:44, :55) — nothing in the range claims otherwise.

## Claim 23: types.ts — "Implementations create intermediate directories" on write
**Location:** app/lib/corpus/types.ts:110-111, 117
**Type:** behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** opfsAdapter.ts:120 `const dir = await walkDir(root, dirs, true);` (create=true on the write path); the fake's dirs are implicit (inMemoryCorpusFs.ts:8 "Directories are implicit: a file at \"a/b/c.txt\" makes \"a\" and \"a/b\" listable."). Contract-tested at corpusFsContract.ts:41-47.

## Claim 24: workspaceStore header — "custom debounced storage adapter rate-limits writes"
**Location:** app/lib/stores/workspaceStore.ts:5
**Type:** behavioral / staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

> "persist middleware handles serialization lifecycle; custom debounced storage adapter rate-limits writes"

True for the default (flag-off) path only. When the corpus flag is on, the selected storage is `createCorpusBackedStorage`, whose `setItem` writes immediately with no debounce:

**Evidence:** storeAdapter.ts:64-66 `setItem: async (name, value) => { await fs.writeFile(pathFor(name), enc.encode(value)); }` — no timer; vs. the debounced default at storeAdapter.ts:34-41. The header predates the seam and was not updated by the range; the author knows (commit 4de2b00: "Remaining 🟢 items (... async un-debounced seam ...) carried to S2/S3/S5"), but the header as written claims unconditional rate-limiting. The adjacent seam comment added in-range is accurate (workspaceStore.ts:496-498 "debounced localStorage by default, or a CorpusFS-backed adapter when the dev flag is on"); line 5 just wasn't reconciled with it.

## Claim 25: commit 4de2b00 — A1 rename customTypeIds → customArtifactTypeIds, "no consumers yet"
**Location:** commit 4de2b00 message
**Type:** reference / behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `rg -n 'customTypeIds' app/` (excluding the customArtifact prefix-matches) returns zero bare `customTypeIds` occurrences — all 8 hits are `customArtifactTypeIds` (manifest.ts:15,44,55,105-107,116; manifest.test.ts:15,48). "no consumers yet" holds: the manifest field is read/written only by manifest.ts and its tests; no store or UI code references it. The rename also matches the pre-existing app vocabulary (workspaceStore.ts:169 `customArtifactTypes: CustomArtifactTypeDefinition[]`). Note (minor, not flagged): `parseManifest` does not accept the old `customTypeIds` key, which is safe precisely because there are no consumers/persisted manifests yet.

## Claim 26: commit 4de2b00 — "Review artifacts under docs/reviews/"
**Location:** commit 4de2b00 message
**Type:** reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `ls docs/reviews/` in the worktree lists api-consistency-review.md, architecture-review-code.md, code-fact-check-report.md, code-review-rubric.md, performance-review.md, security-review.md, tech-debt-triage-review.md, override-log.md — matching the critic set named in the message ("security/perf/api-consistency/architecture/tech-debt + fact-check"), and the commit's own stat shows it updating them (`git show 4de2b00 --stat`).

## Claim 27: commit 4de2b00 — "Verified: lint clean, build passes, 325 tests pass"
**Location:** commit 4de2b00 message (and 122d70f "324 vitest tests pass", f6361a3 "3 tests pass")
**Type:** verification claim
**Verdict:** Unverifiable
**Confidence:** Medium — static evidence is consistent but the suite cannot be executed
**Legibility-target:** for-orchestrator-synthesis

The worktree has no node_modules, so the suite cannot be run (paraphrased — no quote available for a test run because dependencies are not installed in the pinned worktree). Static consistency checks all pass:
- f6361a3's "3 tests pass": `git show f6361a3:app/lib/corpus/__tests__/opfsAdapter.test.ts` contains exactly 3 `it(` blocks — matches.
- 324 → 325 across 4de2b00: the fix commit adds exactly one `it(` (the C1 traversal test, opfsAdapter.test.ts:86) and renames fields in manifest.test.ts without changing test count — the +1 delta matches.
- Absolute magnitude plausible: `rg -o '\bit\(' --glob '**/*.test.*' -c` sums to 308 static `it(` occurrences, plus 7 in the shared contract suite (corpusFsContract.ts, executed via corpusFs.contract.test.ts:8) plus `it.each` expansions in app/lib/stores/__tests__/artifactEditHandlers.test.ts — consistent with ~325 at runtime, but not provable statically.

## Claims Requiring Attention

### Incorrect
- **Claim 11** — opfsAdapter.ts:124 "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers." The code passes the caller's `Uint8Array` directly (`await w.write(bytes)`, opfsAdapter.ts:125); no fresh view or copy exists. Untouched by the review-fix commit. Either the comment is wrong or a needed copy is missing (the in-memory fake does copy, inMemoryCorpusFs.ts:27).

### Stale
- (none)

### Mostly Accurate
- **Claim 2** — flag.ts production guard: logic correct and ordered before both enable paths, but the optional-chained `process.env?.NODE_ENV` / `process.env?.NEXT_PUBLIC_CORPUS_FS` accesses depend on the bundler (Next 16 / Turbopack) inlining through optional chaining for the guard to fire in a production *client* bundle; no test sets NODE_ENV=production.
- **Claim 6** — manifest.ts:13-16 fail-loud docstring: non-object elements of `sources`/`artifacts` and non-string entries of `customArtifactTypeIds` are silently filtered (manifest.ts:90, 97, 106), and `label` defaults to the id (manifest.ts:92) — more defaults than "only createdAt/updatedAt". Commit A4 claim inherits this.
- **Claim 9** — opfsAdapter.ts:60-66 "the adapter must not trust callers": true for writeFile/readFile/rm/stat via splitPath, but `readdir` (opfsAdapter.ts:137) bypasses splitPath and performs no segment rejection.
- **Claim 24** — workspaceStore.ts:5 "custom debounced storage adapter rate-limits writes": unconditional claim, but the flag-on corpus path is un-debounced (storeAdapter.ts:64-66).

### Unverifiable
- **Claim 27** — "325 tests pass" (and sibling counts): cannot execute the suite in the pinned worktree; all static deltas and magnitudes are consistent.

## Goal-Alignment Note
- Answered: All 8 briefed claim areas verified — C2 flag gate (both paths blocked, inlining caveat), A4 manifest docstring (element-level filtering found), A2 paths single-source (now holds; pre-fix violation confirmed removed), C1 splitPath rejection + test (readdir bypass found), A3 stale refs (all fixed, greps clean), debounce/storage-timing claims (verbatim move confirmed; header overstates; selection-once confirmed), commit 4de2b00 fix claims (A1-A4, C1-C2 each checked), CorpusErrorKind producible set (io/unavailable/quota-exceeded post-fix).
- Out of scope: docs/** content accuracy (used only as reference evidence); review-outcome framing ("0 red, 4 amber") — that is a claim about the review artifacts, not app/ code; UI/security/perf judgments on the un-debounced corpus write path (fact vs. opinion boundary).
- Escalate: (1) opfsAdapter.ts:124 comment/code mismatch — if some OPFS implementations really reject shared buffers, the *code* is the bug, not the comment; worth a decision, not just a comment edit. (2) The C2 guard's reliance on bundler inlining of optional-chained `process.env` under Turbopack is untested and unprovable from the repo — a production-build smoke assertion (or rewriting to plain `process.env.NODE_ENV` member access) would make the data-loss guard verifiable.
