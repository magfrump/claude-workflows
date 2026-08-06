# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-corpus-dirty)
**Scope:** `git diff dc6dfb0..2dc403e -- app/` (corpus S0/S1: CorpusFS contracts, OPFS adapter, manifest codec, paths layout, default-off flag, workspaceStore seam) + commit messages ec7bbbc/3da6747/f6361a3/00ba8c3/122d70f. docs/working/** planning files used as evidence only, not verdicted.
**Checked:** 2026-08-06
**Total claims checked:** 24
**Summary:** 13 Verified, 5 Mostly accurate, 2 Stale, 2 Incorrect, 2 Verified-with-caveat folded into Mostly accurate/Verified counts as listed below. The two Incorrect findings: (1) `paths.ts` claims it is "the only source of corpus paths" while `storeAdapter.ts` hand-concatenates `state/${name}.json` outside it; (2) an `opfsAdapter.ts` comment says a "fresh ArrayBuffer view" is passed to `write()` while the code passes the caller's array unchanged. Two references went stale within the same range (`layout.ts` name, `workspaceStore.ts:44-46`). All static test-count claims in commit messages check out exactly (26, 3, 69, 324).

**Commit:** 2dc403e

## Claim 1: In-memory fake — "substitutability (LSP) is verified, not assumed"

**Location:** app/lib/corpus/__tests__/inMemoryCorpusFs.ts:4-6
**Type:** Architectural / testing claim
**Verdict:** Mostly accurate
**Confidence:** High — all three relevant files plus the plan status line read end-to-end.
**Legibility-target:** for-author

> "The OPFS adapter and this fake are both asserted against the same shared contract suite (corpusFsContract.ts), so substitutability (LSP) is verified, not assumed." (inMemoryCorpusFs.ts:4-6)

The shared suite exists and is genuinely shared in structure: `corpusFsContract.ts:14` exports `defineCorpusFsContract`, and the CI runner binds only the fake — "defineCorpusFsContract(\"in-memory fake\", () => createInMemoryCorpusFs());" (corpusFs.contract.test.ts:8). The OPFS adapter's run of that suite is out-of-CI Playwright, and at this commit it has **not been executed**: "out-of-CI OPFS Playwright smoke documented but not yet run" (docs/working/plan-corpus-s1.md:5). So at this repo state substitutability is verified for the fake and *planned* for the adapter — "verified, not assumed" overstates the adapter side.

**Evidence:** corpusFs.contract.test.ts:8 (fake-only binding); corpusFsContract.ts:4-7 ("Run against the in-memory fake in CI ... and against the real OPFS adapter via out-of-CI Playwright"); plan-corpus-s1.md:5 (smoke not yet run).

## Claim 2: Flag is "DEFAULT OFF and DEV-ONLY"

**Location:** app/lib/corpus/flag.ts:4-7
**Type:** Configuration / invariant claim
**Verdict:** Mostly accurate
**Confidence:** High — `isCorpusEnabled` is 11 lines and its only callers were grepped.
**Legibility-target:** for-author

> "DEFAULT OFF and DEV-ONLY. ... It exists only to let developers exercise the OPFS path; it must not be turned on for end users until S4 ships migration." (flag.ts:4-7)

DEFAULT OFF is verified: `isCorpusEnabled()` returns `false` unless the env var is `"1"` or the localStorage key is `"1"` — "return false;" is the terminal path (flag.ts:24), and the sole consumer gates on it: "if (isCorpusEnabled()) { return createCorpusBackedStorage(createOpfsCorpusFs()); } return createDebouncedLocalStorage();" (storeAdapter.ts:72-75). The G13 test confirms OPFS is never touched by default (workspaceStore-corpus-flag.test.ts:25-37).

"DEV-ONLY" is policy, not mechanism: nothing in the function checks `NODE_ENV` or any dev signal — "return window.localStorage.getItem(CORPUS_FLAG_KEY) === \"1\";" (flag.ts:19) works identically in a production browser. Any end user of a production deployment can enable the flag from the console and (per the S4 caveat the header itself states) land in an empty corpus. The header's own phrasing "at runtime in a dev browser" (flag.ts:9-10) describes intended use, not an enforced restriction.

**Evidence:** flag.ts:15-25 (full implementation); storeAdapter.ts:71-76 (only caller); workspaceStore-corpus-flag.test.ts:26-37.

## Claim 3: Flag — "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or ... localStorage"

**Location:** app/lib/corpus/flag.ts:9-10
**Type:** Configuration / behavioral claim
**Verdict:** Mostly accurate
**Confidence:** Medium — localStorage path fully verified; the env path depends on Next.js build-time inlining behavior that cannot be confirmed without a build.
**Legibility-target:** for-author

The localStorage half is verified end-to-end: key constant matches ("export const CORPUS_FLAG_KEY = \"corpus-fs-enabled\";", flag.ts:13) and the G15 test proves setting it routes to OPFS (workspaceStore-corpus-flag.test.ts:62-80).

The env half is risky. The access pattern is:

> "if (typeof process !== \"undefined\" && process.env?.NEXT_PUBLIC_CORPUS_FS === \"1\") return true;" (flag.ts:16)

Next.js inlines `NEXT_PUBLIC_*` variables into client bundles by textual replacement of the literal member expression `process.env.NEXT_PUBLIC_CORPUS_FS` (Next's docs explicitly warn that non-literal access — destructuring, dynamic lookup — is not replaced). Here the access uses **optional chaining** (`process.env?.NEXT_PUBLIC_CORPUS_FS`), which is not the documented literal form. Paraphrased — no quote available because this depends on Next.js/webpack DefinePlugin behavior outside the repo: webpack 5 added optional-chaining support to DefinePlugin, so on current webpack builds the replacement likely still occurs, but this is not guaranteed under Turbopack or future bundler changes, and no test or build artifact in the repo exercises the env path (grep for `NEXT_PUBLIC_CORPUS_FS` finds only flag.ts and docs; no `next.config` entry, no test). If inlining fails, the client-bundle `process.env` shim is empty and the env enable path silently never works. Since the flag is dev-only scaffolding this is low-stakes, but the header asserts the env path works without anything in the repo verifying it.

**Evidence:** flag.ts:16; grep result — `NEXT_PUBLIC_CORPUS_FS` appears only in app/lib/corpus/flag.ts (lines 9, 16) and no config/test file; workspaceStore-corpus-flag.test.ts:62 (localStorage path only).

## Claim 4: Manifest parsing is "FAIL-LOUD", surfacing kind "io" or "browser-storage-cleared", never a silent default-empty manifest

**Location:** app/lib/corpus/manifest.ts:10-14
**Type:** Behavioral / error-contract claim
**Verdict:** Mostly accurate
**Confidence:** High — every field of `parseManifest` read line-by-line.
**Legibility-target:** for-author

> "parsing is FAIL-LOUD. A malformed or absent manifest must surface as a typed `CorpusError` of kind \"io\" or \"browser-storage-cleared\", never a silent default-empty manifest" (manifest.ts:10-13)

Three inaccuracies of degree:

1. **The codec can only ever emit kind `"io"`.** Every failure funnels through one helper: "throw new CorpusError({ kind: \"io\", path: \"workspace.json\", reason }, ...)" (manifest.ts:66). No code path in manifest.ts constructs `"browser-storage-cleared"`; grep of the file confirms `fail()` is the only throw site. The "or browser-storage-cleared" half of the claim describes a kind this codec never produces (presumably a caller-level mapping planned for later).
2. **Silent defaults are applied for several fields**, contradicting the absolute "fail-loud" framing: `label` defaults to `id` ("label: typeof s.label === \"string\" ? s.label : s.id", manifest.ts:89); `createdAt`/`updatedAt` default to now ("createdAt: typeof raw.createdAt === \"string\" ? raw.createdAt : new Date().toISOString()", manifest.ts:109-110); `manifestVersion` accepts any number with no version check (manifest.ts:84, 107).
3. **Malformed entries can be silently dropped**: non-object entries in `sources`/`artifacts` are removed by "raw.sources.filter(isObject)" (manifest.ts:87) before the id/ext check runs, and non-string `customTypeIds` entries are dropped by "raw.customTypeIds.filter((x): x is string => typeof x === \"string\")" (manifest.ts:103). A manifest whose sources array is `["corrupted"]` parses "successfully" with zero sources — entry-level data loss the fail-loud contract says cannot happen.

The core whole-manifest claim is true: absent bytes, non-JSON, non-object, and missing required top-level fields all throw (manifest.ts:75-104), verified by tests (manifest.test.ts:24-51). The overall shape of the contract holds; the absolutes do not.

**Evidence:** manifest.ts:64-67, 83-110; manifest.test.ts:24-51.

## Claim 5: `parseManifest` docstring — null input is an error, absence is the caller's null-check

**Location:** app/lib/corpus/manifest.ts:69-73
**Type:** Behavioral claim
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

> "Throws a `CorpusError` on any malformation — a `null` input (file absent) is the caller's responsibility to detect via `CorpusFS.readFile` returning `null`; passing `null` here is itself an error." (manifest.ts:70-73)

Matches: "if (bytes === null) fail(\"manifest file is absent\");" (manifest.ts:75), and tested: "expect(() => parseManifest(null)).toThrow(CorpusError);" (manifest.test.ts:43).

**Evidence:** manifest.ts:75; manifest.test.ts:42-44.

## Claim 6: OPFS adapter — SSR/unavailable guard rejects with typed CorpusError, never a raw TypeError

**Location:** app/lib/corpus/opfsAdapter.ts:9-11
**Type:** Invariant claim
**Verdict:** Verified
**Confidence:** High — all five methods traced; each calls `getRoot()` first inside its try, and `wrap` re-throws CorpusError unchanged.
**Legibility-target:** for-orchestrator-synthesis

> "any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:\"unavailable\"}), never a raw `TypeError`." (opfsAdapter.ts:9-11)

`getRoot` checks both absence of `navigator` and of `getDirectory`: "if (!storage || typeof storage.getDirectory !== \"function\") { throw new CorpusError({ kind: \"unavailable\", ... })" (opfsAdapter.ts:50-53). All five interface methods (`readFile` 87, `writeFile` 107, `readdir` 125, `rm` 139, `stat` 156) begin with `await getRoot()` inside a try whose catch calls `wrap`, and "if (e instanceof CorpusError) throw e;" (opfsAdapter.ts:80) preserves the kind. Tested for all five methods (opfsAdapter.test.ts:26-47).

**Evidence:** opfsAdapter.ts:49-55, 79-83, 85-175; opfsAdapter.test.ts:25-48.

## Claim 7: OPFS adapter — quota failures reified, "NOT swallowed with console.warn the way the legacy localStorage adapter does (workspaceStore.ts:44-46)"

**Location:** app/lib/corpus/opfsAdapter.ts:12-14
**Type:** Behavioral + reference claim
**Verdict:** Stale
**Confidence:** High — both the current and pre-range versions of workspaceStore.ts read.
**Legibility-target:** for-author

The behavioral half is verified: "if (isQuota(e)) throw new CorpusError({ kind: \"quota-exceeded\", substrate: \"opfs\" });" (opfsAdapter.ts:81), with `isQuota` matching `QuotaExceededError`/`QUOTA_EXCEEDED_ERR` DOMExceptions (opfsAdapter.ts:45-47), tested at opfsAdapter.test.ts:51-82. The console.warn-swallow behavior it contrasts against is also real.

The **line reference is stale at this commit**: the console.warn swallow no longer lives in workspaceStore.ts. Commit 00ba8c3 (inside this same range, after f6361a3 introduced this comment) moved the debounced adapter out; at 2dc403e the swallow is "console.warn(\"Failed to persist workspace (localStorage quota exceeded):\", e);" at **storeAdapter.ts:35**, while workspaceStore.ts:44-46 is now the body of `coerceArtifactVersion`. (The reference was approximately correct against the pre-move file, where the warn sat at line 45.)

**Evidence:** opfsAdapter.ts:12-14, 45-47, 81; storeAdapter.ts:32-36; workspaceStore.ts:43-49 at 2dc403e (coerceArtifactVersion body); `git show dc6dfb0:app/lib/stores/workspaceStore.ts` lines 43-47 (old warn location).

## Claim 8: OPFS adapter write — "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** app/lib/corpus/opfsAdapter.ts:115
**Type:** Behavioral claim (comment vs. code)
**Verdict:** Incorrect
**Confidence:** High — the commented line is directly below the comment.
**Legibility-target:** for-author

> "// Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
> await w.write(bytes);" (opfsAdapter.ts:115-116)

The code does **not** pass a fresh view or copy — it passes the caller's `Uint8Array` unchanged. No `bytes.slice()`, `new Uint8Array(bytes)`, or buffer re-wrap occurs anywhere in `writeFile` (opfsAdapter.ts:107-123). Either the copy was written and later removed leaving the comment orphaned, or the comment describes an intention never implemented. (Contrast the in-memory fake, which does copy and says so accurately: "files.set(normalize(path), bytes.slice());", inMemoryCorpusFs.ts:27.) Interestingly, commit 122d70f narrowed the *type* to `Uint8Array` for TS-lib reasons ("narrow local OpfsWritable.write to Uint8Array (TS lib BufferSource/ArrayBufferLike strictness)", 122d70f message) — a type-level change, not the runtime copy the comment claims.

**Evidence:** opfsAdapter.ts:107-123 (full writeFile); inMemoryCorpusFs.ts:26-27; commit 122d70f message.

## Claim 9: paths.ts — "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point"

**Location:** app/lib/corpus/paths.ts:15-19
**Type:** Architectural / invariant claim
**Verdict:** Incorrect
**Confidence:** High — all corpus-module files grepped for literal path construction.
**Legibility-target:** for-author

> "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`." (paths.ts:16-19)

Within this same changeset, `storeAdapter.ts` hand-concatenates a corpus path without touching paths.ts:

> "const pathFor = (name: string) => \`state/${name}.json\`;" (storeAdapter.ts:55)

That string is passed straight to `fs.writeFile`/`readFile`/`rm` (storeAdapter.ts:58-65) on the same CorpusFS the layout claims to govern, and the `state/` directory does not appear in the documented on-disk shape (paths.ts:4-13 lists only `settings.json` and `workspaces/`). The practical risk is low — `name` is the persist key `"workspace-zustand-v1"`, a compile-time constant, not untrusted input — so the *security* half ("keeps untrusted workspace titles inside workspaces/") survives: nothing outside paths.ts builds a path from user data. But the stated invariant ("only source of corpus paths", "callers must never hand-concatenate") is factually violated by a sibling module in the same commit range, and the layout diagram omits a directory the code writes. The plan carried the same claim ("layout builders are the only path source", plan-corpus-s1.md:77).

**Evidence:** storeAdapter.ts:55-65; paths.ts:4-19; grep for path template literals across app/lib/corpus — only storeAdapter.ts:55 constructs a CorpusFS path outside paths.ts.

## Claim 10: `workspaceSlug` docstring — strips separators/dot-segments/unicode, collapses runs, throws on empty

**Location:** app/lib/corpus/paths.ts:30-35
**Type:** Behavioral claim
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The regex "const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;" (paths.ts:28) replaces every non-alphanumeric/underscore/hyphen run (which includes `/`, `\`, `.`) with `-`; hyphen runs collapse and trim (paths.ts:40-41); empty result throws: "throw new Error(\`workspace title produced an empty slug: ...\`)" (paths.ts:44). Tests assert traversal inputs (`../etc/passwd`, `a/b`), run-collapsing, and the all-unsafe throw including unicode "。。。" (paths.test.ts:16-32).

**Evidence:** paths.ts:28, 36-47; paths.test.ts:15-33.

## Claim 11: `artifactVersionPath` — zero-padded 1-based version, e.g. "workspaces/<s>/artifacts/semiformal/v0001.md"

**Location:** app/lib/corpus/paths.ts:86-88
**Type:** Behavioral claim
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

"const v = String(version).padStart(VERSION_PAD, \"0\");" with `VERSION_PAD = 4` (paths.ts:23, 92) and rejection of non-positive/non-integer versions (paths.ts:89-91). Test confirms the exact example string and the `v0042` case (paths.test.ts:54-57), and rejection of 0 and 1.5 (paths.test.ts:58-61).

**Evidence:** paths.ts:22-23, 88-94; paths.test.ts:54-61.

## Claim 12: storeAdapter — folder layout "(layout.ts/manifest.ts)" is built but not used until S4

**Location:** app/lib/corpus/storeAdapter.ts:10-12
**Type:** Reference + architectural claim
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

> "the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used by the store until S4." (storeAdapter.ts:11-12)

The substantive claim is verified — nothing in storeAdapter.ts imports paths.ts or manifest.ts (its imports are only zustand types, ./types, ./opfsAdapter, ./flag; storeAdapter.ts:15-18), and the blob is a single `state/` file. But the file name is stale: `layout.ts` was renamed to `paths.ts` by commit 122d70f *within this same range* ("rename layout.ts->paths.ts (Next reserved name)"), which updated the test import but missed this comment. At 2dc403e no file named layout.ts exists under app/lib/corpus/.

**Evidence:** storeAdapter.ts:11, 15-18; 122d70f commit message; `ls app/lib/corpus/` shows paths.ts, no layout.ts.

## Claim 13: storeAdapter — debounced localStorage "moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior"; reads synchronous, writes debounced 300ms

**Location:** app/lib/corpus/storeAdapter.ts:21-23
**Type:** Behavioral / equivalence claim
**Verdict:** Verified
**Confidence:** High — the moved function diffed line-by-line against `git show dc6dfb0:app/lib/stores/workspaceStore.ts`.
**Legibility-target:** for-orchestrator-synthesis

The function body of `createDebouncedLocalStorage` (storeAdapter.ts:25-46) is line-for-line identical to the pre-range `createDebouncedStorage` (old workspaceStore.ts, `createDebouncedStorage` body): same `getItem` passthrough, same 300ms `setTimeout` debounce, same try/catch with "console.warn(\"Failed to persist workspace (localStorage quota exceeded):\", e);", same `removeItem` cancel-then-remove. The only differences are the name and the return-type annotation (inline object type → `StateStorage`), which are type-level, not behavioral — "byte-for-byte the prior behavior" holds for the runtime path even though the source text is not literally byte-identical. "Reads are synchronous ... writes are debounced by 300ms" matches the code (storeAdapter.ts:28, 38). The characterization suite (4 tests, workspaceStore-characterization.test.ts) and G13 flag-off test exercise the moved code through the store.

**Evidence:** storeAdapter.ts:25-46 vs. dc6dfb0 workspaceStore.ts createDebouncedStorage (quoted in full in evidence gathering; bodies identical); workspaceStore-corpus-flag.test.ts:25-37.

## Claim 14: storeAdapter — `resolveWorkspaceStorage` "Selected once when the store's persist middleware initializes"

**Location:** app/lib/corpus/storeAdapter.ts:70
**Type:** Behavioral claim
**Verdict:** Verified
**Confidence:** Medium — depends on zustand `createJSONStorage` internals (calls its `getStorage` argument once, eagerly, when building the JSON-storage wrapper), which are outside the repo. Paraphrased — no quote available because zustand's source is in node_modules, not the reviewed diff.
**Legibility-target:** for-orchestrator-synthesis

The wiring is "storage: createJSONStorage(resolveWorkspaceStorage)" (workspaceStore.ts:499), evaluated once at module load when `create(...persist(...))` runs. Consequence worth noting for synthesis (not a doc error): because selection happens once at store init, flipping the localStorage flag requires a reload to take effect — consistent with the flag's dev-only framing.

**Evidence:** workspaceStore.ts:494-501; storeAdapter.ts:70-76.

## Claim 15: types.ts — "'Not found' is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`."

**Location:** app/lib/corpus/types.ts:17-18
**Type:** Invariant claim
**Verdict:** Verified
**Confidence:** High — both S1 implementations checked method-by-method.
**Legibility-target:** for-orchestrator-synthesis

OPFS adapter: missing paths return `null` ("if (isNotFound(e)) return null;", opfsAdapter.ts:97, 166; "if (!dir) return null;", opfsAdapter.ts:92, 161), `readdir` returns `[]` ("if (!dir) return [];", opfsAdapter.ts:130), all other failures funnel through `wrap` which always throws a CorpusError (opfsAdapter.ts:79-83). In-memory fake: "return files.get(normalize(path)) ?? null;" (inMemoryCorpusFs.ts:22) — the `?? null` specifically converts Map's `undefined` so callers never see it; `stat` returns `bytes ? {...} : null` (inMemoryCorpusFs.ts:50). Contract suite asserts the null/[] cases (corpusFsContract.ts:21-28).

**Evidence:** opfsAdapter.ts:79-83, 87-105, 125-137, 156-174; inMemoryCorpusFs.ts:20-52; corpusFsContract.ts:21-28.

## Claim 16: types.ts — CorpusError and CorpusWorkerError "differ only in transport, never in the kind set"; exhaustiveness enforced

**Location:** app/lib/corpus/types.ts:27-28, 37-40, 92-95
**Type:** Architectural / invariant claim
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both forms carry the same `detail: CorpusErrorKind` ("readonly detail: CorpusErrorKind;", types.ts:53; "detail: CorpusErrorKind;", types.ts:65) — a single union declared once (types.ts:41-49). `describeCorpusError` switches over all eight kinds with a default of "return assertNever(d);" (types.ts:88), and `assertNever` takes `never` so TS flags any added kind at compile time (types.ts:94-96).

One synthesis-level observation (not a falsehood — the union is explicitly forward-looking for S2/S3): of the eight kinds, only three have producers at this commit — `unavailable` (opfsAdapter.ts:52), `quota-exceeded` (opfsAdapter.ts:81), `io` (opfsAdapter.ts:60, 82; manifest.ts:66). `not-found`, `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, and `git-conflict` are constructed nowhere in app/. `not-found` in particular sits in mild tension with Claim 15's own contract (not-found is represented as `null`, never thrown), so it currently has no legitimate producer even in principle for the S1 interface.

**Evidence:** types.ts:41-49, 52-58, 63-67, 78-96; grep of `kind: "` constructors across app/lib/corpus — only unavailable/quota-exceeded/io appear outside types.ts.

## Claim 17: workspaceStore header — debounced storage adapter rate-limits writes; skipHydration for SSR safety

**Location:** app/lib/stores/workspaceStore.ts:5-6
**Type:** Behavioral claim
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Still true after the seam extraction: the default path is the debounced adapter ("return createDebouncedLocalStorage();", storeAdapter.ts:75) and "skipHydration: true," (workspaceStore.ts:501) with the comment "SSR safe: render defaults first, hydrate in useEffect via rehydrate()" (workspaceStore.ts:500) matching zustand's documented skipHydration semantics. Note the header sentence describes the *default* storage; when the corpus flag is on, the CorpusFS-backed storage has **no debounce** (storeAdapter.ts:52-68 writes on every setItem) — an intentional S1 difference, flagged here only so a reader doesn't extend the "rate-limits writes" claim to the flag-on path.

**Evidence:** workspaceStore.ts:5-6, 499-501; storeAdapter.ts:52-68, 75.

## Claim 18: workspaceStore seam comment — storage selected here, "seam is typed as CorpusFS so the S3 worker-proxy is a drop-in"

**Location:** app/lib/stores/workspaceStore.ts:496-498
**Type:** Architectural claim
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The injection point accepts the interface, not the concrete adapter: "export function createCorpusBackedStorage(fs: CorpusFS): StateStorage" (storeAdapter.ts:52), with the concrete OPFS adapter bound only inside `resolveWorkspaceStorage` (storeAdapter.ts:73). The G14 test proves any `CorpusFS` (the in-memory fake) drops in (workspaceStore-corpus-flag.test.ts:41-57). Matches arch-review finding 3 as folded into plan step 7 ("The injection seam's static type MUST be the `CorpusFS` interface", plan-corpus-s1.md:27).

**Evidence:** storeAdapter.ts:52, 71-76; workspaceStore-corpus-flag.test.ts:40-57; plan-corpus-s1.md:27.

## Claim 19: workspaceStore merge comment — "Validate deserialized localStorage data before merging into the store"

**Location:** app/lib/stores/workspaceStore.ts:502-503
**Type:** Behavioral claim
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

"merge: (persisted, current) => ({ ...current, ...(isObject(persisted) ? coercePersistedState(persisted as Record<string, unknown>) : {}) })" (workspaceStore.ts:504-507); `coercePersistedState` type-checks every field and delegates decomposition to `coerceDecomposition` (workspaceStore.ts:68-119). This code is unchanged from dc6dfb0 (the diff touches only imports, the removed adapter, and the storage line).

**Evidence:** workspaceStore.ts:68-119, 504-507; `git diff dc6dfb0..2dc403e -- app/lib/stores/workspaceStore.ts` (no hunk touches merge/coerce code).

## Claim 20: Commit ec7bbbc — S0 contracts match plan steps 1-3; "single choke point for untrusted titles"; "fail-loud parse ... never silent default-empty"

**Location:** commit ec7bbbc message
**Type:** Reference + behavioral claims
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Plan-step references check out: docs/working/plan-corpus-s1.md steps 1-3 (lines 21-23) describe exactly types.ts, layout.ts (now paths.ts), and manifest.ts, and the delivered files match the step descriptions (interface shape, error-kind single source, path builders, codec). The arch-review finding numbers cited (1, 2) match the plan's own summary (plan-corpus-s1.md:70). Two overstatements inherited by the message: "single choke point for untrusted titles" is accurate for *untrusted titles* specifically but the stronger paths.ts wording it summarizes is violated later in the range (Claim 9), and "never silent default-empty" carries the entry-level silent-drop caveats of Claim 4. As statements about the commit's own snapshot, both were defensible at ec7bbbc (storeAdapter did not yet exist); flagged for-author because the range's end state weakens them.

**Evidence:** plan-corpus-s1.md:21-23, 70; ec7bbbc message; Claims 4 and 9 above.

## Claim 21: Commit 3da6747 — plan steps 4-5; characterization + contract/layout/manifest tests; "26 tests pass"

**Location:** commit 3da6747 message
**Type:** Reference + test-count claims (static)
**Verdict:** Verified
**Confidence:** High for the static count; the "pass" assertion is historical CI state, taken on the count evidence only.
**Legibility-target:** for-orchestrator-synthesis

Plan steps 4-5 (plan-corpus-s1.md:24-25) list exactly these files. Static count of `it(` blocks in the files this commit added: corpusFsContract.ts 7 + paths.test.ts 10 + manifest.test.ts 5 + workspaceStore-characterization.test.ts 4 = **26** — matching "26 tests pass" exactly. The message's content description (30-small-files access pattern per arch-review finding 4; fail-loud parse asserting `err.detail.kind`) matches corpusFsContract.ts:58-74 and manifest.test.ts:37-39.

**Evidence:** `rg -c '^\s*it\('` per file (7/10/5/4); plan-corpus-s1.md:24-25; corpusFsContract.ts:58; manifest.test.ts:39.

## Claim 22: Commit f6361a3 — plan steps 6,8a; adapter behavior summary; "3 tests pass"

**Location:** commit f6361a3 message
**Type:** Reference + behavioral + test-count claims
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Steps 6 and 8a exist (plan-corpus-s1.md:26, 28). Static count: opfsAdapter.test.ts has exactly 3 `it(` blocks. Every behavioral clause in the message maps to code verified above (Claims 6, 7, 15). Notably the message says quota maps to "{kind:\"quota-exceeded\", substrate:\"opfs\"}" — which matches the code and arch-review finding 1, and *corrects* the plan's own stale wording ("mapped to `opfs-quota-exceeded`", plan-corpus-s1.md:26) — the commit is more accurate than the plan step it cites (plan doc is out of verdict scope; noted as context).

**Evidence:** opfsAdapter.test.ts (3 its); opfsAdapter.ts:81; plan-corpus-s1.md:26, 28.

## Claim 23: Commit 00ba8c3 — plan steps 7,8b; "moved here verbatim"; "one-line storage swap ... net shrinks the store file"; "69 corpus+store tests pass"

**Location:** commit 00ba8c3 message
**Type:** Reference + equivalence + test-count claims
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Steps 7 and 8b exist (plan-corpus-s1.md:27-28), including the pre-authorized extraction to storeAdapter.ts ("if it would push the file past ~600, extract the adapter selection into `app/lib/corpus/storeAdapter.ts` instead", plan-corpus-s1.md:40). "Moved verbatim" — verified (Claim 13). "One-line storage swap ... net shrinks the store file" — the functional change is exactly one line ("-      storage: createJSONStorage(createDebouncedStorage), / +      storage: createJSONStorage(resolveWorkspaceStorage),") plus one import and comments; the file shrinks by a net 31 lines (diff stat: 38 changed, -33/+5 region). "69 corpus+store tests pass" — static count across app/lib/corpus/__tests__ (25: 7+5+3+10) and app/lib/stores/__tests__ (44: workspaceStore.test 17, hydration 8, characterization 4, corpus-flag 3, artifactEditHandlers 2 plain + 2 `it.each` × 5 KEYS = 12) totals exactly **69**.

**Evidence:** git diff hunks for workspaceStore.ts; per-file `it(` counts; artifactEditHandlers.test.ts:6-12 (KEYS has 5 entries), 27, 40; plan-corpus-s1.md:27-28, 40.

## Claim 24: Commit 122d70f — rename rationale ("Next.js App Router treats any app/**/layout.ts as a route layout, failing the build"); plan steps 9-10; "324 vitest tests pass"

**Location:** commit 122d70f message
**Type:** Reference + configuration + test-count claims
**Verdict:** Verified
**Confidence:** High for the count and step references; Medium for the build-failure mechanism (not re-built here, but consistent with Next.js's documented reserved file conventions — paraphrased, no quote available because Next.js docs are outside the repo).
**Legibility-target:** for-orchestrator-synthesis

`layout.ts` is a reserved special-file name in the Next.js App Router for every directory under `app/`, so `app/lib/corpus/layout.ts` colliding with the convention is credible, and the repo shows the rename was carried through: paths.ts exists, no layout.ts remains under app/lib/corpus, and paths.test.ts imports "../paths" (paths.test.ts:13). Plan steps 9-10 exist (plan-corpus-s1.md:29-30) and match the delivered artifacts (docs/spikes/corpus-opfs-smoke.md exists; CLAUDE.md documents the module, the dev-only flag, and the jsdom-no-OPFS caveat, including "**not** `layout.ts`, which is a reserved Next.js filename"). "324 vitest tests pass": static enumeration — 303 plain `it(` in app/ test files + 2 `it.each` lines expanding to 10 (KEYS = 5) + 7 contract cases instantiated once via corpusFs.contract.test.ts + 4 in root proxy.test.ts = **324** exactly.

**Evidence:** paths.test.ts:13; `ls app/lib/corpus/`; plan-corpus-s1.md:29-30; static counts: `rg -c '^\s*it\('` app tests = 303 plain + 2 it.each lines, corpusFsContract.ts = 7, proxy.test.ts = 4, KEYS length 5 (artifactEditHandlers.test.ts:6-12); worktree CLAUDE.md lib/corpus entry.

## Claims Requiring Attention

### Incorrect

- **Claim 8** — opfsAdapter.ts:115: comment says a fresh ArrayBuffer view is passed to `write()`; the code passes the caller's `Uint8Array` unchanged. Either restore the copy or fix the comment.
- **Claim 9** — paths.ts:16-19: "the only source of corpus paths is this module" is violated by storeAdapter.ts:55 (`state/${name}.json` hand-concatenation), and `state/` is missing from the documented layout. Untrusted-input safety still holds (the bypassing path is a compile-time constant), but the stated invariant is false.

### Stale

- **Claim 7** — opfsAdapter.ts:14: reference "workspaceStore.ts:44-46" points at code that commit 00ba8c3 (same range) moved to storeAdapter.ts:32-36.
- **Claim 12** — storeAdapter.ts:11: "(layout.ts/manifest.ts)" — layout.ts was renamed to paths.ts by 122d70f (same range); this comment was missed in the rename sweep.

### Mostly Accurate

- **Claim 1** — inMemoryCorpusFs.ts:4-6: "substitutability (LSP) is verified, not assumed" — verified for the fake only; the OPFS run of the shared suite is documented but not yet executed at this commit.
- **Claim 2** — flag.ts:4: "DEV-ONLY" is unenforced policy — the localStorage enable path works identically in production browsers.
- **Claim 3** — flag.ts:9-10, 16: the build-time env enable path uses `process.env?.NEXT_PUBLIC_CORPUS_FS` (optional chaining), which deviates from Next.js's documented literal-reference inlining form; nothing in the repo verifies the env path works.
- **Claim 4** — manifest.ts:10-13: codec only ever emits kind `"io"` (never `"browser-storage-cleared"`); silent defaults for label/createdAt/updatedAt and silent drops of malformed array entries soften the absolute "FAIL-LOUD ... never a silent default" framing.
- **Claim 20** — ec7bbbc message: accurate at its own snapshot; the range's end state weakens "single choke point" (Claim 9) and "never silent default-empty" (Claim 4).

### Unverifiable

- None (Claim 3's env-inlining and Claim 24's build-failure mechanism are external-dependency-limited but each has enough corroborating evidence for a graded verdict above).

## Goal-Alignment Note
- Answered: All eight briefed claim clusters (flag header incl. NEXT_PUBLIC inlining pattern; manifest parse/validation incl. per-field default audit; paths choke-point incl. grep for literal path construction; storeAdapter verbatim-move diffed against dc6dfb0; CorpusErrorKind producer audit; opfsAdapter error-mapping/SSR invariants; workspaceStore seam comments; all five commit messages incl. exact static test-count verification — 26/3/69/324 all reproduced).
- Out of scope: docs/working/** planning files (used as evidence only; note in passing: plan step 6 and the G7 table row still say `opfs-quota-exceeded`, contradicted by the implemented substrate-neutral kind — an intra-plan staleness the orchestrator may want a docs pass to catch); non-app files (CLAUDE.md, docs/spikes) beyond their use as evidence; whether the flag-on path *should* lack a write debounce (design question, noted in Claim 17); actually running the build or test suite (historical-state review, static verification only).
- Escalate: (1) The flag's "DEV-ONLY" is purely conventional — if any production hardening is expected before S4, the env/localStorage gate needs an enforcement mechanism (Claim 2). (2) The env-flag inlining pattern (Claim 3) silently no-ops if the bundler doesn't rewrite optional-chained access — cheap to fix by using the literal `process.env.NEXT_PUBLIC_CORPUS_FS` form. (3) The orphaned copy comment (Claim 8) may mask a real shared-buffer bug on some OPFS implementations if the copy was removed rather than never written.
