# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-corpus-clean, detached at 4de2b00)
**Scope:** `git diff dc6dfb0..4de2b00 -- app/` (corpus S0/S1 + review-fix commit 4de2b00); commit messages in the range for app/ claims; docs/** used as evidence only
**Checked:** comments/docstrings in app/lib/corpus/{flag,manifest,opfsAdapter,paths,storeAdapter,types}.ts, corpus/store test files, app/lib/stores/workspaceStore.ts, and the range's commit messages
**Total claims checked:** 24
**Summary:** 17 Verified, 3 Mostly accurate, 1 Incorrect, 3 Unverifiable. The review-fix commit's A1–A3 and C1 fixes all check out against the code (rename complete, blob path routed through paths.ts, no stale layout.ts/workspaceStore-line refs remain, traversal rejection present and tested). The one Incorrect finding is the opfsAdapter write-site comment "Pass a fresh ArrayBuffer view" — the code passes the caller's array as-is and never has done otherwise. The A4 manifest docstring is Mostly accurate: field-level malformations do fail loud with kind "io", but malformed *elements inside* the sources/artifacts/customArtifactTypeIds arrays are silently filtered, and `label` silently defaults — more defaulting than "only createdAt/updatedAt". The C2 production hard-refuse is logically correct for both enable paths as written, but its efficacy in a *client* production bundle rests on Next.js inlining the optional-chained `process.env?.NODE_ENV` / `process.env?.NEXT_PUBLIC_CORPUS_FS` accesses, which cannot be confirmed statically in this worktree (no node_modules, no build) — escalated.

**Commit:** 4de2b00

## Claim 1: flag.ts — default-off, dev-only, no migration in S1

**Location:** app/lib/corpus/flag.ts:4-7
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High — both halves checked against code and greps.
**Legibility-target:** for-orchestrator-synthesis

> "DEFAULT OFF and DEV-ONLY. In S1 there is no localStorage->corpus migration (that is S4), so enabling this starts from an EMPTY corpus" (app/lib/corpus/flag.ts:4-6)

Default-off: with no env var and no localStorage key, every branch of `isCorpusEnabled()` falls through to `return false;` (app/lib/corpus/flag.ts:31). No-migration: the corpus-backed storage only ever reads/writes `state/<name>.json` via `CorpusFS` and never touches localStorage — `getItem: async (name) => { const bytes = await fs.readFile(pathFor(name)); return bytes ? dec.decode(bytes) : null; }` (app/lib/corpus/storeAdapter.ts:60-62); a grep of `app/lib/corpus/` finds no code copying localStorage content into the corpus (paraphrased — no quote available because the claim is about the *absence* of migration code, confirmed by `rg` over the module).
**Evidence:** app/lib/corpus/flag.ts:21-31; app/lib/corpus/storeAdapter.ts:55-71.

## Claim 2: flag.ts — the two enable paths (env and localStorage)

**Location:** app/lib/corpus/flag.ts:9-10
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium — localStorage path is test-verified; the build-time-env path is verified for Node/SSR but its client-bundle behavior depends on bundler inlining I cannot confirm statically (see Claim 3).
**Legibility-target:** for-author

> "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`." (app/lib/corpus/flag.ts:9-10)

The localStorage path works and is exercised by test G15: `localStorage.setItem(CORPUS_FLAG_KEY, "1"); ... expect(getDirectory).toHaveBeenCalled();` (app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:62-80). The env path reads `process.env?.NEXT_PUBLIC_CORPUS_FS === "1"` (app/lib/corpus/flag.ts:23). In any Node context (SSR, tests) this works directly. In a browser bundle, `NEXT_PUBLIC_*` vars only exist if the bundler inlines the access at build time; Next.js documents inlining for direct `process.env.VAR` member accesses, and this code uses the optional-chained form `process.env?.NEXT_PUBLIC_CORPUS_FS`, which is off the documented pattern (paraphrased — no quote available because the Next.js toolchain is not vendored in this worktree; node_modules is absent, so the bundler's handling of optional chaining cannot be inspected or exercised). If not inlined, the "build-time env" enable path would silently never fire in the browser — a footgun-safe failure direction, but the docstring's "enable via" claim would then be false for the client. Flag for the author to either verify with a build or rewrite as `process.env.NEXT_PUBLIC_CORPUS_FS`.
**Evidence:** app/lib/corpus/flag.ts:23-30; app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:60-82.

## Claim 3: flag.ts — C2 production hard-refuse blocks both enable paths

**Location:** app/lib/corpus/flag.ts:16-21
**Type:** Behavioral / invariant (security fix C2)
**Verdict:** Unverifiable
**Confidence:** Medium — the control flow is verified; the claim's operative guarantee ("in a production build") cannot be confirmed without building, and it hinges on the same inlining question as Claim 2.
**Legibility-target:** for-orchestrator-synthesis

> "Refuse to activate in a production build so the dev flag can never become an end-user data-loss footgun (security review C2)." (app/lib/corpus/flag.ts:18-19)

As source logic, the guard is correctly placed: `if (typeof process !== "undefined" && process.env?.NODE_ENV === "production") return false;` (app/lib/corpus/flag.ts:21) executes *before* both the env check (line 23) and the localStorage check (lines 24-30), so when it fires, both enable paths are blocked. What I cannot verify is that it fires in a production *client* bundle: the guard reads `process.env?.NODE_ENV` with optional chaining. If Next.js's define-replacement handles the optional-chained form, the guard compiles to `false`-on-dev/`true`-on-prod correctly. If it does not, then in the browser `process.env` is a shim object without `NODE_ENV`, the guard never fires, and the *localStorage* enable path (which needs no inlining) remains live in production — the exact C2 footgun the comment claims is closed (paraphrased — no quote available because verifying requires running `next build` and inspecting the bundle; node_modules is absent from this worktree and no build output is committed). No test in the range exercises the guard (grep for `NODE_ENV` under `app/lib/corpus/__tests__/` and `app/lib/stores/__tests__/` returns nothing — paraphrased, absence claim from `rg`). Escalated in the Goal-Alignment Note.
**Evidence:** app/lib/corpus/flag.ts:21-31.

## Claim 4: manifest.ts — A4 docstring: fail-loud for content, only io thrown, only timestamps default

**Location:** app/lib/corpus/manifest.ts:10-16
**Type:** Behavioral / invariant
**Verdict:** Mostly accurate
**Confidence:** High — codec read end-to-end.
**Legibility-target:** for-author

> "parsing is FAIL-LOUD for content. A malformed or absent manifest surfaces as a typed `CorpusError` of kind \"io\" ... The only fields that default rather than fail are the `createdAt`/`updatedAt` timestamps (metadata, not content) — every content field (title, sources, artifacts, customArtifactTypeIds) fails loud if missing or malformed." (app/lib/corpus/manifest.ts:10-16)

Accurate parts: every failure goes through `fail()`, which throws only kind "io" — `throw new CorpusError({ kind: "io", path: "workspace.json", reason }, ...)` (app/lib/corpus/manifest.ts:69) — so "only throws io" holds. Missing/malformed *fields* fail loud: `if (typeof raw.title !== "string") fail("missing required field: title")` (manifest.ts:86), and each of sources/artifacts/customArtifactTypeIds fails when not an array (manifest.ts:94, 103, 107). `createdAt`/`updatedAt` default: `createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString()` (manifest.ts:112).

Inaccurate parts (element level): a non-object entry inside `sources` or `artifacts` is silently *dropped*, not failed — `raw.sources.filter(isObject).map(...)` (manifest.ts:90) and `raw.artifacts.filter(isObject).map(...)` (manifest.ts:97); a non-string entry inside `customArtifactTypeIds` is likewise silently filtered — `raw.customArtifactTypeIds.filter((x): x is string => typeof x === "string")` (manifest.ts:106). And a third field defaults besides the timestamps: a source's `label` falls back to its id — `label: typeof s.label === "string" ? s.label : s.id` (manifest.ts:92). So "every content field fails loud if missing or malformed" is true of the fields themselves but not of malformed elements *within* the array fields — a corrupted source entry of the wrong shape silently vanishes from the parsed manifest, which is a small instance of the very "masks data loss" behavior the docstring says is excluded. (Entries that are objects but missing `id`/`ext` or `type`/`currentVersion` do fail loud — manifest.ts:91, 98-100.)
**Evidence:** app/lib/corpus/manifest.ts:67-70, 86-107, 112-113; test coverage of the fail-loud paths at app/lib/corpus/__tests__/manifest.test.ts:23-51.

## Claim 5: manifest.ts — ArtifactPointer file convention

**Location:** app/lib/corpus/manifest.ts:23-24
**Type:** Reference / architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "`currentVersion` is the 1-based version number whose file is artifacts/<type>/v####.md." (app/lib/corpus/manifest.ts:23-24)

Matches the path builder exactly: `artifactVersionPath` enforces 1-based (`if (!Number.isInteger(version) || version < 1) throw` — app/lib/corpus/paths.ts:106-108) and produces `` `${artifactDir(slug, artifactType)}/v${v}.md` `` with `VERSION_PAD = 4` (paths.ts:23, 109-110), confirmed by test: `expect(artifactVersionPath(s, "semiformal", 1)).toBe("workspaces/my-slug/artifacts/semiformal/v0001.md")` (app/lib/corpus/__tests__/paths.test.ts:55).
**Evidence:** app/lib/corpus/paths.ts:23, 105-111; app/lib/corpus/__tests__/paths.test.ts:54-57.

## Claim 6: manifest.ts — parseManifest throws on null input

**Location:** app/lib/corpus/manifest.ts:73-76
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "a `null` input (file absent) is the caller's responsibility to detect via `CorpusFS.readFile` returning `null`; passing `null` here is itself an error." (app/lib/corpus/manifest.ts:74-75)

Implemented: `if (bytes === null) fail("manifest file is absent");` (app/lib/corpus/manifest.ts:78), and `CorpusFS.readFile` is documented and implemented to return `null` for absent files (app/lib/corpus/types.ts:113-115; app/lib/corpus/opfsAdapter.ts:101, 106). Tested: `expect(() => parseManifest(null)).toThrow(CorpusError)` (app/lib/corpus/__tests__/manifest.test.ts:43).
**Evidence:** as quoted.

## Claim 7: opfsAdapter.ts — SSR/unavailable guard covers every method

**Location:** app/lib/corpus/opfsAdapter.ts:9-11
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:\"unavailable\"}), never a raw `TypeError`." (app/lib/corpus/opfsAdapter.ts:9-11)

All five methods (`readFile`, `writeFile`, `readdir`, `rm`, `stat`) call `getRoot()` first, which throws `new CorpusError({ kind: "unavailable", reason: ... })` when `getDirectory` is absent (app/lib/corpus/opfsAdapter.ts:51-54, then lines 98, 118, 136, 150, 167). Tested for the kind (`expect((caught as CorpusError).detail.kind).toBe("unavailable")` — app/lib/corpus/__tests__/opfsAdapter.test.ts:37) and for all methods (opfsAdapter.test.ts:40-47).
**Evidence:** as quoted.

## Claim 8: opfsAdapter.ts — quota reification, and the (fixed) cross-reference to the localStorage swallow

**Location:** app/lib/corpus/opfsAdapter.ts:12-15
**Type:** Behavioral + reference (A3 fix)
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "a quota failure rejects with {kind:\"quota-exceeded\", substrate:\"opfs\"} — it is NOT swallowed with console.warn the way the legacy localStorage adapter does (createDebouncedLocalStorage in storeAdapter.ts)." (app/lib/corpus/opfsAdapter.ts:12-15)

Reification: `if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` (app/lib/corpus/opfsAdapter.ts:90), tested at app/lib/corpus/__tests__/opfsAdapter.test.ts:78-81. The reference (previously the stale "workspaceStore.ts:44-46", replaced in 4de2b00) is now correct: the console.warn swallow lives at `console.warn("Failed to persist workspace (localStorage quota exceeded):", e);` inside `createDebouncedLocalStorage` (app/lib/corpus/storeAdapter.ts:38, function at line 28). No other stale line-number references to workspaceStore remain in `app/lib/corpus/` (grep for `workspaceStore` there hits only the accurate "moved verbatim from workspaceStore.ts" note at storeAdapter.ts:24).
**Evidence:** as quoted; diff hunk in 4de2b00 replacing "workspaceStore.ts:44-46" with "createDebouncedLocalStorage in storeAdapter.ts".

## Claim 9: opfsAdapter.ts — C1 splitPath traversal rejection

**Location:** app/lib/corpus/opfsAdapter.ts:60-66
**Type:** Behavioral / invariant (security fix C1)
**Verdict:** Verified
**Confidence:** High — code and test read; one scoping observation below.
**Legibility-target:** for-orchestrator-synthesis

> "Defense-in-depth: paths.ts is the sanitizing choke point, but the adapter must not trust callers to have used it. Reject traversal/backslash segments rather than resolving them" (app/lib/corpus/opfsAdapter.ts:60-62)

Implemented exactly: `if (seg === "." || seg === ".." || seg.includes("\\")) { throw new CorpusError({ kind: "io", path, reason: \`unsafe path segment: ${seg}\` }); }` (app/lib/corpus/opfsAdapter.ts:64-65). Test coverage exists for the `..` case: `await fs.writeFile("workspaces/s/../../escape.txt", ...)` asserting a CorpusError of kind "io" (app/lib/corpus/__tests__/opfsAdapter.test.ts:97-102); `.` and backslash segments are covered by the same code branch but have no dedicated test. Observation for synthesis (the comment's claim is scoped to `splitPath`, so this is not a verdict downgrade): `readdir` does not go through `splitPath` — it splits the path itself with no traversal check: `const dirs = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);` (opfsAdapter.ts:137) — so the defense-in-depth rejection covers readFile/writeFile/rm/stat but not readdir (readdir is read-only and native OPFS `getDirectoryHandle` rejects `..` names itself, so exposure is low).
**Evidence:** as quoted.

## Claim 10: opfsAdapter.ts — "fresh ArrayBuffer view" at the write site

**Location:** app/lib/corpus/opfsAdapter.ts:124
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High — one-line comparison of comment and code; history checked.
**Legibility-target:** for-author

> "// Pass a fresh ArrayBuffer view; some implementations dislike shared buffers." (app/lib/corpus/opfsAdapter.ts:124)

The code does not do this: the very next line is `await w.write(bytes);` (app/lib/corpus/opfsAdapter.ts:125) — the caller's `Uint8Array` is passed through unchanged, with no fresh view or copy (a fresh view would be e.g. `new Uint8Array(bytes)` or `bytes.slice()`). This is not drift from the 4de2b00 fix: the comment and the bare `w.write(bytes)` were introduced together in f6361a3 (`+ // Pass a fresh ArrayBuffer view; ... + await w.write(bytes);` in that commit's diff) and the review-fix commit did not touch the write site — the comment has never matched the code. Contrast with the in-memory fake, which really does copy and says so accurately: `// Copy so later mutation of the caller's array can't alter stored bytes. files.set(normalize(path), bytes.slice());` (app/lib/corpus/__tests__/inMemoryCorpusFs.ts:26-27). Either make the code copy (matching the stated intent about shared/SharedArrayBuffer-backed views) or fix the comment.
**Evidence:** app/lib/corpus/opfsAdapter.ts:122-127; git show f6361a3 diff lines 121-122; app/lib/corpus/__tests__/inMemoryCorpusFs.ts:26-27.

## Claim 11: opfsAdapter.ts — rm idempotency comments

**Location:** app/lib/corpus/opfsAdapter.ts:153,157
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "if (!dir) return; // idempotent: parent dir missing -> nothing to remove" (app/lib/corpus/opfsAdapter.ts:153) and "if (isNotFound(e)) return; // idempotent: file already gone" (opfsAdapter.ts:157)

Both branches return normally instead of throwing, matching the interface contract "Removes a file. Idempotent: resolves (no-op) if the path does not exist." (app/lib/corpus/types.ts:121) and the contract-suite test "rm removes a file and is idempotent on a missing path" (app/lib/corpus/__tests__/corpusFsContract.ts:49-56).
**Evidence:** as quoted.

## Claim 12: paths.ts — "the only source of corpus paths is this module" (A2 fix)

**Location:** app/lib/corpus/paths.ts:16-19
**Type:** Architectural / invariant
**Verdict:** Verified
**Confidence:** High — grep across all corpus modules and the store.
**Legibility-target:** for-orchestrator-synthesis

> "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point" (app/lib/corpus/paths.ts:17-19)

Post-A2 this now holds for non-test app/ code: the one prior hand-built path (`` `state/${name}.json` `` in storeAdapter) was replaced in 4de2b00 with `const pathFor = (name: string) => stateBlobPath(name);` (app/lib/corpus/storeAdapter.ts:58), importing from `"./paths"` (storeAdapter.ts:21). A grep of `app/lib/corpus/*.ts` and `app/lib/stores/*.ts` for string-built corpus paths finds none outside `__tests__` fixtures (paraphrased — no quote available because this is an absence claim established by `rg` for `state/`, `workspaces/`, and template-literal path patterns). Note the choke point for the *blob* path is `safeSegment`, not `workspaceSlug` (paths.ts:84) — consistent with the breadcrumb's own wording (Claim 14).
**Evidence:** app/lib/corpus/storeAdapter.ts:21,58; app/lib/corpus/paths.ts:83-84; 4de2b00 diff hunk `- const pathFor = (name: string) => \`state/${name}.json\`; + const pathFor = (name: string) => stateBlobPath(name);`.

## Claim 13: paths.ts — SAFE_SEGMENT / workspaceSlug sanitization guarantees

**Location:** app/lib/corpus/paths.ts:26-35
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Everything else is collapsed to a hyphen so a value can never contain \"/\", \"\\\\\", \".\" runs, or control characters" (app/lib/corpus/paths.ts:27-28) and "Throws if nothing safe remains (an all-unsafe title must not silently become \"\")." (paths.ts:34)

The character class `const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;` (paths.ts:28) admits only alphanumerics, underscore, hyphen — slash, backslash, dot, and control characters are all replaced. The empty-slug throw: `if (!slug) { throw new Error(\`workspace title produced an empty slug: ...\`); }` (paths.ts:43-45). Tested: traversal titles (`workspaceSlug("../etc/passwd")` contains no `..`/`/`) and `expect(() => workspaceSlug("////")).toThrow(/empty slug/)` (app/lib/corpus/__tests__/paths.test.ts:17-31).
**Evidence:** as quoted.

## Claim 14: paths.ts — S1 blob-mode breadcrumb (stateBlobPath / STATE_DIR)

**Location:** app/lib/corpus/paths.ts:70-84
**Type:** Architectural / reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "In S1 the whole Zustand persist blob is written as a single file under `state/` (see storeAdapter.createCorpusBackedStorage). ... Routed through this builder (rather than a hand-built string in storeAdapter) so the namespace fork is greppable and the name goes through the same `safeSegment` sanitization as every other path." (app/lib/corpus/paths.ts:73-80)

All three sub-claims check out: (1) the referenced function exists and stores one file per persist key — `setItem: async (name, value) => { await fs.writeFile(pathFor(name), enc.encode(value)); }` (app/lib/corpus/storeAdapter.ts:64-66); (2) the path is built here — `return \`${STATE_DIR}/${safeSegment(name)}.json\`;` (paths.ts:84) — and consumed via `stateBlobPath` in storeAdapter (storeAdapter.ts:58); (3) it runs through `safeSegment` (same function used by sourcePath/artifactDir/customTypePath, paths.ts:96,100,118). The flag-routing test confirms the resulting location: `const bytes = await fs.readFile("state/workspace-zustand-v1.json");` (app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:49).
**Evidence:** as quoted.

## Claim 15: storeAdapter.ts — seam selection and CorpusFS typing

**Location:** app/lib/corpus/storeAdapter.ts:4-8
**Type:** Architectural / behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "`resolveWorkspaceStorage()` returns the zustand persist storage: the existing debounced localStorage adapter by default, or a CorpusFS-backed storage when the dev flag is on. The injection seam is typed as `CorpusFS`" (app/lib/corpus/storeAdapter.ts:4-7)

Implemented: `if (isCorpusEnabled()) { return createCorpusBackedStorage(createOpfsCorpusFs()); } return createDebouncedLocalStorage();` (app/lib/corpus/storeAdapter.ts:74-79) and `export function createCorpusBackedStorage(fs: CorpusFS): StateStorage` (storeAdapter.ts:55) — the parameter type is the interface, not the concrete adapter. Exercised by tests G13 (OFF default hits localStorage, `expect(getDirectory).not.toHaveBeenCalled()` — workspaceStore-corpus-flag.test.ts:36), G14 (injected in-memory fake, not localStorage — lines 41-57), G15 (flag on selects OPFS path — lines 61-82).
**Evidence:** as quoted.

## Claim 16: storeAdapter.ts — "moved verbatim ... OFF path is byte-for-byte the prior behavior"

**Location:** app/lib/corpus/storeAdapter.ts:24-27
**Type:** Behavioral / staleness
**Verdict:** Verified
**Confidence:** High — compared against the removed code in the 00ba8c3 diff.
**Legibility-target:** for-orchestrator-synthesis

> "Default: debounced localStorage (moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior — see the characterization test). Reads are synchronous (instant); writes are debounced by 300ms." (app/lib/corpus/storeAdapter.ts:24-26)

The function body in storeAdapter.ts:28-49 is token-identical to the body removed from workspaceStore.ts in 00ba8c3 (same 300ms `setTimeout`, same `console.warn` quota swallow, same removeItem cancel-pending logic); only the function name changed (`createDebouncedStorage` → `createDebouncedLocalStorage`) and the return type annotation became `StateStorage` — behavior byte-for-byte as claimed. The 300ms figure matches `}, 300);` (storeAdapter.ts:41). The referenced characterization test exists and flushes exactly that debounce: `vi.advanceTimersByTime(300); // flush debounced write` (app/lib/stores/__tests__/workspaceStore-characterization.test.ts:52).
**Evidence:** 00ba8c3 diff of app/lib/stores/workspaceStore.ts (removed `createDebouncedStorage` body identical to storeAdapter.ts:28-49).

## Claim 17: storeAdapter.ts — "Selected once when the store's persist middleware initializes."

**Location:** app/lib/corpus/storeAdapter.ts:73
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium — the call site is confirmed in-repo; the "once, at initialization" timing rests on zustand's `createJSONStorage` invoking its getter eagerly, which I could not read locally (node_modules absent).
**Legibility-target:** for-orchestrator-synthesis

> "/** Selected once when the store's persist middleware initializes. */" (app/lib/corpus/storeAdapter.ts:73)

The resolver is passed as the storage getter: `storage: createJSONStorage(resolveWorkspaceStorage),` (app/lib/stores/workspaceStore.ts:499), evaluated when `create(persist(...))` runs at module load. zustand v5's `createJSONStorage` calls the supplied `getStorage()` once, immediately, when constructing the storage object (paraphrased — no quote available because zustand's source is not vendored in this worktree; node_modules is absent). Consequence consistent with the comment: flipping the localStorage flag requires a reload to take effect, which fits the dev-flag design.
**Evidence:** app/lib/stores/workspaceStore.ts:496-499; package.json:33 (`"zustand": "^5.0.13"`).

## Claim 18: types.ts — CorpusError / CorpusWorkerError "differ only in transport, never in the kind set"

**Location:** app/lib/corpus/types.ts:27-28
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "`CorpusError` is the thrown form; `CorpusWorkerError` is its postMessage-serializable twin. They differ only in transport, never in the kind set." (app/lib/corpus/types.ts:27-28)

Both carry the same discriminated union: `readonly detail: CorpusErrorKind;` (types.ts:53) and `export type CorpusWorkerError = { __corpusError: true; detail: CorpusErrorKind; message: string; };` (types.ts:63-67), with lossless conversion `return { __corpusError: true, detail: err.detail, message: err.message };` (types.ts:70). One shared `CorpusErrorKind` type (types.ts:41-49); no second kind enumeration exists anywhere in app/ (paraphrased — absence confirmed by `rg "kind:"` over app/lib/corpus/).
**Evidence:** as quoted.

## Claim 19: types.ts — "The complete set of corpus failure kinds" vs. what is producible in this range

**Location:** app/lib/corpus/types.ts:37-49
**Type:** Architectural / contract
**Verdict:** Verified
**Confidence:** High — every producer in the range grepped.
**Legibility-target:** for-orchestrator-synthesis

> "The complete set of corpus failure kinds. Every exhaustive `switch` over a corpus error binds to this union; adding a kind here forces every consumer to handle it at compile time" (app/lib/corpus/types.ts:37-39)

The union (types.ts:41-49) declares eight kinds; the exhaustive-switch mechanism is real (`describeCorpusError` switches over all eight with `default: return assertNever(d);` — types.ts:78-90). As a contract claim this is accurate. For the orchestrator's map of actual behavior at 4de2b00: only three kinds have producers — "unavailable" (opfsAdapter.ts:53), "quota-exceeded" (opfsAdapter.ts:90), and "io" (opfsAdapter.ts:65, 69, 91; manifest.ts:69). The other five ("not-found", "fsa-permission-revoked", "remote-auth-expired", "browser-storage-cleared", "git-conflict") are forward declarations for S2/S3 with no throw sites in app/ (paraphrased — absence established by `rg 'kind: "'` over app/). Notably "not-found" is never thrown by design: absent paths surface as `null`/`[]` per the interface docs (types.ts:17-18, 113-124), which the adapter honors (opfsAdapter.ts:101, 106, 139, 153, 157).
**Evidence:** as quoted.

## Claim 20: types.ts — CorpusFS interface contracts (null/[]/mkdir-on-write)

**Location:** app/lib/corpus/types.ts:106-125
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Implementations create intermediate directories on write." (app/lib/corpus/types.ts:110) and "\"Not found\" is `null` from `readFile`/`stat` and `[]` from `readdir`" (types.ts:17-18)

OPFS adapter: `const dir = await walkDir(root, dirs, true);` on write (opfsAdapter.ts:120, with `getDirectoryHandle(d, { create })` at line 79); `return null` / `return []` for missing paths (opfsAdapter.ts:101, 106, 139, 172-176). In-memory fake: implicit directories (inMemoryCorpusFs.ts:8, 30-42), `?? null` (line 22). Both are held to the shared contract suite, which asserts exactly these behaviors ("returns null for a missing file", "returns [] for a missing/empty directory", "creates intermediate directories and lists children at each level" — app/lib/corpus/__tests__/corpusFsContract.ts:21-47); the suite runs in CI against the fake (`defineCorpusFsContract("in-memory fake", ...)` — corpusFs.contract.test.ts:8).
**Evidence:** as quoted.

## Claim 21: test-file cross-references — OPFS success path deferred to out-of-CI Playwright smoke

**Location:** app/lib/corpus/__tests__/opfsAdapter.test.ts:4-7; app/lib/corpus/__tests__/corpusFsContract.ts:4-6
**Type:** Reference / staleness
**Verdict:** Verified
**Confidence:** High — referenced artifacts exist; the Playwright run itself is out-of-CI by its own admission and not re-executed here.
**Legibility-target:** for-orchestrator-synthesis

> "The adapter's *success* path is covered by the shared CorpusFS contract suite run against real OPFS out-of-CI (Playwright, step 9)" (app/lib/corpus/__tests__/opfsAdapter.test.ts:5-7)

The shared suite exists (`export function defineCorpusFsContract` — corpusFsContract.ts:14) and the referenced smoke doc exists at docs/spikes/corpus-opfs-smoke.md (present in the worktree's docs/spikes/ listing; used as evidence for the reference only, per scope). The claim honestly scopes itself as out-of-CI, matching CLAUDE.md's jsdom-no-OPFS caveat.
**Evidence:** as quoted; docs/spikes/corpus-opfs-smoke.md exists (directory listing).

## Claim 22: workspaceStore.ts — header: "custom debounced storage adapter rate-limits writes"

**Location:** app/lib/stores/workspaceStore.ts:5
**Type:** Behavioral / staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

> "persist middleware handles serialization lifecycle; custom debounced storage adapter rate-limits writes" (app/lib/stores/workspaceStore.ts:5)

Accurate for the default (flag-off) path: the debounced adapter is selected and rate-limits at 300ms (app/lib/corpus/storeAdapter.ts:34-41, 78). No longer unconditionally accurate: with the dev flag on, `resolveWorkspaceStorage()` returns the corpus-backed storage, whose `setItem` writes through immediately with no debounce — `setItem: async (name, value) => { await fs.writeFile(pathFor(name), enc.encode(value)); }` (storeAdapter.ts:64-66). The seam comment lower in the same file is accurate and conditional ("debounced localStorage by default, or a CorpusFS-backed adapter when the dev flag is on" — workspaceStore.ts:496-497), but the design-decision header at line 5 still states the debounce as an invariant. The gap is acknowledged elsewhere as a deferred item ("async un-debounced seam" carried to S2/S3 in the 4de2b00 commit message), and the affected path is dev-only, so this is drift, not a live-user inaccuracy.
**Evidence:** as quoted.

## Claim 23: commit 4de2b00 — fix claims A1/A2/A3/C1 and "review artifacts under docs/reviews/"

**Location:** git commit 4de2b00 (message body)
**Type:** Behavioral / reference (commit-message claims about app/ code)
**Verdict:** Verified
**Confidence:** High — each fix claim checked against the diff and current tree.
**Legibility-target:** for-orchestrator-synthesis

> "A1: WorkspaceManifest.customTypeIds -> customArtifactTypeIds ... no consumers yet" / "A2: route the S1 blob path through paths.ts stateBlobPath() + STATE_DIR" / "A3: fix stale comments (layout.ts->paths.ts; workspaceStore.ts:44-46 ref -> storeAdapter)" / "C1: opfsAdapter splitPath rejects ./../backslash segments (defense-in-depth) + test." (git log 4de2b00)

A1: `rg customTypeIds app/` returns zero hits; `customArtifactTypeIds` appears only in manifest.ts and its test (manifest.ts:44,55,105-107,116; manifest.test.ts:15,48) — rename complete and "no consumers yet" holds (nothing outside the corpus module reads the manifest field; the store's similarly-named `customArtifactTypes` is a different, pre-existing field). A2: verified in Claim 12/14. A3: `rg "layout\.ts" app/` returns zero hits, and the workspaceStore line reference is gone (Claim 8). C1: verified in Claim 9, including the promised test (opfsAdapter.test.ts:85-104). "Review artifacts under docs/reviews/": the directory exists and contains code-review-rubric.md, code-fact-check-report.md, security-review.md et al. (directory listing; evidence-only per scope).
**Evidence:** as cited per sub-claim.

## Claim 24: commit-message verification claims — "325 tests pass", "lint clean, build passes" (4de2b00); "324 vitest tests pass" (122d70f); "69 corpus+store tests" (00ba8c3)

**Location:** git commits 4de2b00, 122d70f, 00ba8c3 (message bodies)
**Type:** Verification / test-count
**Verdict:** Unverifiable
**Confidence:** Medium — cannot execute; internal consistency checks pass.
**Legibility-target:** for-orchestrator-synthesis

> "Verified: lint clean, build passes, 325 tests pass." (git log 4de2b00)

The worktree has no node_modules (`ls node_modules` is empty), so `vitest`, `next build`, and ESLint cannot be run here, and the run counts cannot be reproduced statically because the shared contract suite registers tests dynamically. Consistency checks that *are* possible all pass: 122d70f claims 324 tests, 4de2b00 adds exactly one test (the C1 traversal test is the only `it()` added in its diff), and claims 325 — arithmetically consistent; f6361a3's "3 tests pass" matches the three `it()` blocks in its version of opfsAdapter.test.ts (verified by `git show f6361a3:... | rg -c "  it\("` → 3).
**Evidence:** git log for the three commits; empty node_modules; f6361a3 it-count as described.

## Claims Requiring Attention

### Incorrect
- **Claim 10** — opfsAdapter.ts:124 "Pass a fresh ArrayBuffer view" — the code passes the caller's `Uint8Array` as-is (`await w.write(bytes)`, line 125); no fresh view is ever constructed, and never was. Fix the code (copy, matching the in-memory fake's behavior at inMemoryCorpusFs.ts:26-27) or the comment.

### Stale
- (none)

### Mostly Accurate
- **Claim 2** — flag.ts:9-10: localStorage enable path verified; the "build-time env" path uses optional-chained `process.env?.NEXT_PUBLIC_CORPUS_FS`, off Next.js's documented direct-reference inlining pattern — client-bundle behavior unconfirmed.
- **Claim 4** — manifest.ts:10-16 (A4 fix): field-level fail-loud and "only throws io" are true, but malformed *elements* inside sources/artifacts/customArtifactTypeIds are silently filtered (manifest.ts:90, 97, 106) and `label` silently defaults to `id` (manifest.ts:92) — the docstring's "only createdAt/updatedAt default" and "every content field fails loud if... malformed" overstate.
- **Claim 22** — workspaceStore.ts:5: "debounced storage adapter rate-limits writes" is unconditional but only true on the flag-off path; the corpus-backed path writes un-debounced (storeAdapter.ts:64-66; dev-only, deferral acknowledged in 4de2b00).

### Unverifiable
- **Claim 3** — flag.ts:16-21 (C2): the production hard-refuse is correctly ordered ahead of both enable paths in source, but whether it fires in a production *client* bundle depends on Next.js inlining `process.env?.NODE_ENV` under optional chaining; no node_modules/build available to confirm, and no test covers the guard. If not inlined, the localStorage enable path stays live in production — the exact footgun C2 claims to close.
- **Claim 24** — commit test-count/lint/build claims (325/324/69; internally consistent, not reproducible in this worktree).

## Goal-Alignment Note
- Answered: All 8 briefed focus areas — C2 production gate (Claims 3, 2), A4 manifest docstring halves incl. throw-vs-filter breakdown (Claim 4), paths.ts single-source + S4 breadcrumb (Claims 12, 14), C1 splitPath rejection + test coverage and the untouched "fresh ArrayBuffer view" comment (Claims 9, 10), A3 stale-reference sweep (Claims 8, 23), workspaceStore/storeAdapter debounce and selection-timing claims (Claims 16, 17, 22), 4de2b00 fix-claim audit incl. A1 grep of both names (Claim 23) and static test-count consistency (Claim 24), and the producible CorpusErrorKind set (Claim 19).
- Out of scope: docs/** content accuracy (used as existence evidence only, per scope note); the out-of-CI Playwright smoke's actual results; opinion/intent comments (ISP/LSP rationale in types.ts and test headers).
- Escalate: (1) Claim 3 — the C2 production guard's client-bundle efficacy is the highest-stakes open question in this changeset; a one-line change to the non-optional-chained `process.env.NODE_ENV` form (which Next.js documents replacing) plus a guard test would settle it. (2) Claim 9 observation — `readdir` bypasses the C1 traversal rejection (opfsAdapter.ts:137); low exposure (read-only, native OPFS rejects `..` names) but inconsistent with the "must not trust callers" stance. (3) Claim 10 — the shared-buffer write concern the comment names is real for SharedArrayBuffer-backed views; decide whether the copy should exist.
