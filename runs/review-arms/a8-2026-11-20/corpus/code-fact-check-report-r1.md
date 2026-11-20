Commit: 2dc403e

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-corpus`, detached at 2dc403e)
**Scope:** `git diff dc6dfb0..2dc403e -- app/` (15 files), plus commit bodies ec7bbbc, 3da6747, f6361a3, 00ba8c3, 122d70f; replicate r1 of 3
**Checked:** 2026-11-19
**Total claims checked:** 33 (28 numbered claims, with split sub-claims 6a-6e and 8a/8b counted separately)
**Summary:** 15 verified, 3 mostly accurate, 2 stale, 8 incorrect, 5 unverifiable

Execution note: the worktree has no `node_modules` and the sandbox has no network, so `vitest`, `next build` and `eslint` could not run. Pure-logic claims were executed instead by copying `paths.ts`, `manifest.ts`, `types.ts` and `opfsAdapter.ts` into a scratch dir and running a probe under `node --experimental-strip-types` (Node v22.23.2). Probe: `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r1-probe/probe.ts`; command `timeout 30 node --experimental-strip-types probe.ts > probe-out.txt 2>&1`; cwd `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r1-probe`; exit 0; 2026-11-20T01:48:05Z; output `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r1-probe/probe-out.txt`. The only probe edit to the copied sources was rewriting `from "./types"` to `from "./types.ts"` so Node could resolve it.

Hallucination-pattern log consulted (`docs/reviews/hallucination-patterns.md` in claude-workflows). The commit-message test counts were checked against the "specific measured test count not matching the suite" pattern (entries for commits 59ca38f and 37c5ea9): the 26, 3 and 69 counts match a static count, and 324 could not be confirmed (Claim 26).

---

## Claim 1: "Runs the shared CorpusFS contract against the in-memory fake ... The OPFS adapter is held to the same suite out-of-CI (Playwright)"

**Location:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-3`
**Type:** Architectural / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether `defineCorpusFsContract` is invoked against the OPFS adapter anywhere in the tree or in the documented smoke procedure. It does not cover whether the OPFS adapter would pass the suite if someone ran it.

The in-memory half holds: `defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());` (`corpusFs.contract.test.ts:8`). The OPFS half does not. A repo-wide grep for `defineCorpusFsContract` finds only its definition (`corpusFsContract.ts:14`) and this one call (paraphrased — no quote available because the claim is about the absence of a call site). The smoke doc that stands in for "Playwright" is an unexecuted sketch. `docs/spikes/corpus-opfs-smoke.md` lists "6 checks", runs them through a hand-written `page.evaluate(async () => { /* run the 6 checks above */ })`, not through the vitest suite, and records `## Results` as `_(not yet run — fill in when executed before enabling the flag in a shared environment)_`. Its six checks also leave out the contract's "overwrites an existing file in place" case (`corpusFsContract.ts:76-80`), so even once run it would not be "the same suite".

**Evidence:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-8`, `app/lib/corpus/__tests__/corpusFsContract.ts:14,76-80`, `docs/spikes/corpus-opfs-smoke.md:13-36`

---

## Claim 2: "Run against the in-memory fake in CI ... and against the real OPFS adapter via out-of-CI Playwright ... Keeping the cases in one place means the fake and the adapter are held to identical behavior"

**Location:** `app/lib/corpus/__tests__/corpusFsContract.ts:4-7`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether the OPFS adapter is run against this suite. It does not cover the fake, which is run against it.

The facts are the same as in Claim 1. The single invocation is the fake (`corpusFs.contract.test.ts:8`). No harness imports this module for the OPFS adapter (paraphrased — no quote available because the claim is about the absence of code; the grep for `defineCorpusFsContract` returns two hits). The smoke doc's results section reads `_(not yet run ...)_`. "Held to identical behavior" is therefore an aim, not something verified.

**Evidence:** `app/lib/corpus/__tests__/corpusFsContract.ts:1-14`, `app/lib/corpus/__tests__/corpusFs.contract.test.ts:8`, `docs/spikes/corpus-opfs-smoke.md:34-36`

---

## Claim 3: "The OPFS adapter and this fake are both asserted against the same shared contract suite (corpusFsContract.ts), so substitutability (LSP) is verified, not assumed."

**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:5-7`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether the OPFS adapter is asserted against the suite. It does not cover the fake's own conformance (the fake is run).

Only the fake is asserted: `defineCorpusFsContract("in-memory fake", ...)` (`corpusFs.contract.test.ts:8`). The OPFS side has never run (`docs/spikes/corpus-opfs-smoke.md`: `_(not yet run ...)_`). So in S1, substitutability is assumed, which is the opposite of what the comment says. The fake's "directories are implicit" statement is accurate: `readdir` derives children from key prefixes, `const next = rest.split("/")[0]; if (next) children.add(next);` (`inMemoryCorpusFs.ts:28-29`, excerpt ends :29; enclosing readdir continues to :31 — read).

**Evidence:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:1-53`, `app/lib/corpus/__tests__/corpusFs.contract.test.ts:8`

---

## Claim 4: "The adapter's *success* path is covered by the shared CorpusFS contract suite run against real OPFS out-of-CI (Playwright, step 9)"

**Location:** `app/lib/corpus/__tests__/opfsAdapter.test.ts:4-6`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether a real-OPFS run of the contract suite exists. It does not cover the error-path assertions in this file, which are present (`opfsAdapter.test.ts:19-80`).

The step-9 smoke (`docs/spikes/corpus-opfs-smoke.md`) is labelled `**Status:** manual` and its results are `_(not yet run ...)_`. It is a six-check sketch, not the contract suite (see Claim 1). No code path runs `defineCorpusFsContract` against `createOpfsCorpusFs` (paraphrased — no quote available because the claim is about the absence of a call site). Nothing currently covers the success path. Commit f6361a3's body says the same thing ("the success path is held to the shared contract suite via Playwright out-of-CI"), and this verdict applies to that sentence too.

**Evidence:** `app/lib/corpus/__tests__/opfsAdapter.test.ts:1-9`, `docs/spikes/corpus-opfs-smoke.md:8,34-36`, commit f6361a3 body

---

## Claim 5: Characterization test "is the equivalence target ... It asserts the existing behavior as-is" (and, per storeAdapter.ts:22, pins the flag-off path)

**Location:** `app/lib/stores/__tests__/workspaceStore-characterization.test.ts:1-9`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the four properties the test asserts through the real store under the default flag-off resolution. It does not cover debounce timing, the quota `console.warn` swallow, or `removeItem`, which it never exercises.

The test runs through the real store. It imports `useWorkspaceStore` (`:11`), so at module load `createJSONStorage(resolveWorkspaceStorage)` (`workspaceStore.ts:497`) resolves with the flag key absent and `NEXT_PUBLIC_CORPUS_FS` unset, which selects the localStorage path. It locks in the serialized content: three versions plus `currentVersionIndex` (`:52-64`), custom types and data (`:67-75`), `verifying`→`none` (`:78-82`), and a rehydrate round-trip (`:85-104`). Each test calls `vi.advanceTimersByTime(300)` and then reads, but none asserts that nothing was written before 300 ms or that later writes coalesce. No case makes `localStorage.setItem` throw. So the test pins what is persisted and rehydrated. It does not pin all of the "byte-for-byte prior behavior" that `storeAdapter.ts:21-22` cites it for. The precise wording would be "pins the persisted shape and round-trip; debounce and quota-swallow semantics are not covered".

**Evidence:** `app/lib/stores/__tests__/workspaceStore-characterization.test.ts:11-106`, `app/lib/stores/workspaceStore.ts:495-498`, `app/lib/corpus/storeAdapter.ts:21-22`

---

## Claim 6a: "DEFAULT OFF"

**Location:** `app/lib/corpus/flag.ts:4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `isCorpusEnabled()` with no env var and no localStorage key. It does not cover a build where `NEXT_PUBLIC_CORPUS_FS=1` is set in the environment.

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

With neither set, every branch returns `false`.

**Evidence:** `app/lib/corpus/flag.ts:13-25`

---

## Claim 6b: "DEV-ONLY ... it must not be turned on for end users until S4 ships migration"

**Location:** `app/lib/corpus/flag.ts:4-7`
**Type:** Invariant / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether the code restricts the flag to development builds. It does not cover the policy intent ("must not be turned on"), which is a rule for people, not code.

Read as a property of the flag, "dev-only" is not enforced. `isCorpusEnabled` (quoted in Claim 6a, `flag.ts:15-25`) has no `NODE_ENV` or `process.env.NODE_ENV !== "production"` check. In a production build, any user who runs `localStorage.setItem("corpus-fs-enabled","1")` gets the OPFS path, which starts from an empty corpus. A production build made with `NEXT_PUBLIC_CORPUS_FS=1` in its environment would turn it on for every user. A reader who takes "DEV-ONLY" as a guarantee would wrongly conclude that production is shielded.

**Evidence:** `app/lib/corpus/flag.ts:1-25`

---

## Claim 6c: "enabling this starts from an EMPTY corpus and does not carry existing localStorage work over"

**Location:** `app/lib/corpus/flag.ts:4-7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the read path of the flag-on storage on first enable. It does not cover what happens to the untouched localStorage blob afterwards.

The flag-on storage only reads `state/<name>.json` from the CorpusFS: `const bytes = await fs.readFile(pathFor(name)); return bytes ? dec.decode(bytes) : null;` (`storeAdapter.ts:58-59`). Nothing reads `localStorage` for workspace data on that path (paraphrased — no quote available because the claim is about the absence of migration code in `storeAdapter.ts:52-76`). On first enable the store therefore rehydrates from nothing.

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-76`

---

## Claim 6d: "Enable via ... the build-time env `NEXT_PUBLIC_CORPUS_FS=1`"

**Location:** `app/lib/corpus/flag.ts:9`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the server or Node-side read, which works as written. It does not establish that the client bundle receives the inlined value.

Next.js exposes `NEXT_PUBLIC_*` to the browser by inlining the literal expression `process.env.NEXT_PUBLIC_X` at build time. This code uses the optional-chain form `process.env?.NEXT_PUBLIC_CORPUS_FS` (`flag.ts:16`). Whether Next 16's bundler (Turbopack by default, or webpack's DefinePlugin) matches an optional-chain member expression could not be confirmed (paraphrased — no quote available because the relevant code is in the Next/Turbopack bundler, not in this repo). If the expression is not inlined, the client-side check reads the polyfilled, empty `process.env` and the env route silently does nothing in the browser. Execution is required: a `next build` with the variable set, then a grep of the client chunk. That was blocked because `node_modules` is absent and there is no network.

**Evidence:** `app/lib/corpus/flag.ts:9,16`, `package.json` (`"next": "^16.2.6"`)

---

## Claim 6e: "or, at runtime in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`"

**Location:** `app/lib/corpus/flag.ts:9-10`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the key name and value comparison, and that the key is read when the store module is evaluated. It does not cover toggling without a reload. The storage is resolved once (Claim 15), so a reload is needed.

`export const CORPUS_FLAG_KEY = "corpus-fs-enabled";` (`flag.ts:13`) and `return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";` (`flag.ts:19`). The flag-ON routing test sets exactly this key and asserts `getDirectory` was called (`workspaceStore-corpus-flag.test.ts:47,65`).

**Evidence:** `app/lib/corpus/flag.ts:13,19`, `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:46-67`

---

## Claim 7: "Codec contract ... parsing is FAIL-LOUD. A malformed or absent manifest must surface as a typed `CorpusError` of kind "io" or "browser-storage-cleared", never a silent default-empty manifest that would masquerade as 'this workspace has no work in it'"

**Location:** `app/lib/corpus/manifest.ts:10-14`
**Type:** Error-handling / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers `parseManifest` on non-JSON, `{}`, `null`, missing top-level arrays, and arrays whose elements are malformed. It does not cover callers, because there are none outside tests (grep finds `parseManifest` only at its definition and in `manifest.test.ts`).

Top-level malformation is loud: `null` → `fail("manifest file is absent")` (`:75`), non-JSON → `fail(...)` (`:79-81`), and missing `title`, `manifestVersion` or arrays → `fail` (`:82-104`). All of these raise `kind: "io"` (`:66`). The codec never raises `"browser-storage-cleared"` (paraphrased — no quote available because the claim is about the absence of that kind anywhere in `manifest.ts`).

Malformed elements are dropped silently:

```ts
// app/lib/corpus/manifest.ts:86-88
  const sources: SourceRef[] = Array.isArray(raw.sources)
    ? raw.sources.filter(isObject).map((s) => {
```
(excerpt ends :88; enclosing parseManifest continues to :115 — read. `artifacts` uses the same `.filter(isObject)` at `:94`, and `customTypeIds` uses `.filter((x): x is string => typeof x === "string")` at `:103`.)

The probe parsed `{manifestVersion:1,title:"t",sources:[1,null,"x"],artifacts:[null,5],customTypeIds:[7,{}]}` and returned `sources:[], artifacts:[], customTypeIds:[]`, with no error. That output is identical to a legitimately empty workspace, which is exactly the "masquerade as no work" outcome the docstring rules out. The probe also accepted `currentVersion: -2.5` (`manifest.ts:95-98` checks only `typeof === "number"`, despite the `1-based` docstring at `:20-21`). Missing `createdAt`/`updatedAt` silently default to `new Date().toISOString()` (`:109-110`).

**Evidence:** `app/lib/corpus/manifest.ts:64-115`, `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r1-probe/probe-out.txt` (lines 1-4)

---

## Claim 8a: "The only source of corpus paths is this module — callers must never hand-concatenate"

**Location:** `app/lib/corpus/paths.ts:16-18`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers non-test code under `app/` that builds CorpusFS paths. It does not cover test files, which also hand-build paths but are fixtures.

The one production CorpusFS consumer hand-concatenates its path without going through `paths.ts`: `const pathFor = (name: string) => \`state/${name}.json\`;` (`storeAdapter.ts:55`). This `state/` directory does not appear in the layout this docstring documents (`paths.ts:5-13`). No non-test file imports `paths.ts` at all (paraphrased — no quote available because the claim is about the absence of imports; grep for `corpus/paths` and `./paths` outside `__tests__` returns none). In this change, the module is not the only source of corpus paths.

**Evidence:** `app/lib/corpus/paths.ts:1-20`, `app/lib/corpus/storeAdapter.ts:52-56`

---

## Claim 8b: "the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`"

**Location:** `app/lib/corpus/paths.ts:18-19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the builders inside `paths.ts`. Every workspace-scoped builder routes through `workspaceDir`, which calls `workspaceSlug`. It does not establish that future callers will use these builders (see 8a), and it does not cover slug collisions between distinct titles.

`return \`workspaces/${workspaceSlug(slug)}\`;` (`paths.ts:71`). `workspaceManifestPath`, `sourcePath`, `artifactDir`, `customTypePath` and `decompositionDir` all build on `workspaceDir(slug)` (`paths.ts:75,79,83,101,105`).

**Evidence:** `app/lib/corpus/paths.ts:70-110`

---

## Claim 9: "a value can never contain "/", "\\", "." runs, or control characters"; all-unsafe input throws; `safeSegment` has the "same guarantees as `workspaceSlug` but preserves case"

**Location:** `app/lib/corpus/paths.ts:25-28,30-35,49-58`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the character set of outputs from `workspaceSlug` and `safeSegment`, and the empty-result throw. It does not cover OS-reserved names (`CON` passes through as `CON` from `safeSegment`), collisions (`"a/b"` and `"a.b"` both become `"a-b"`), or `safeExt`, which defaults to `"bin"` rather than throwing.

`const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;` (`paths.ts:28`) replaces everything outside `[A-Za-z0-9_-]`, which excludes `/`, `\`, `.` and all control characters. Both functions throw when the result is empty (`paths.ts:43-45`, `:54-56`). Probe results: `".."` → throws, `"-"` → throws, `"a\\b"` → `"a-b"`, `"\u0000x"` → `"x"`, `"x‮y"` → `"x-y"`, and `"CON"` → slug `"con"` / segment `"CON"`, which confirms that `safeSegment` preserves case.

**Evidence:** `app/lib/corpus/paths.ts:28-58`, `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r1-probe/probe-out.txt` (lines 5-12)

---

## Claim 10: "any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:"unavailable"}), never a raw `TypeError`"

**Location:** `app/lib/corpus/opfsAdapter.ts:8-10`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers all five methods when `navigator` or `navigator.storage` is undefined, or when `getDirectory` is not a function. It does not cover an environment where `getDirectory` exists but rejects (for example a SecurityError in a private window). The probe showed that case maps to `{kind:"io"}`, not `"unavailable"`.

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

Every method calls `getRoot()` inside a `try` whose catch is `wrap(path, e)`, and `wrap` rethrows a `CorpusError` unchanged (`:80`). With `navigator` undefined, the probe got `CorpusError unavailable` for `readFile`, `writeFile`, `readdir`, `rm` and `stat`. With `getDirectory` throwing a SecurityError, it got `io`.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:49-83,85-176`, `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r1-probe/probe-out.txt` (lines 13, 15-19)

---

## Claim 11: "a quota failure rejects with {kind:"quota-exceeded", substrate:"opfs"} — it is NOT swallowed with console.warn"

**Location:** `app/lib/corpus/opfsAdapter.ts:11-13`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a `QuotaExceededError` DOMException raised by `createWritable`, `write` or `close` on its own. It does not cover the case where `write()` rejects with a quota error and the `finally` clause's `close()` then rejects with a different error. In that case the close error replaces the quota error and the result is `{kind:"io"}` (probe). A spec-conforming close on an errored stream should rethrow the stored quota error, but that was not run in a real browser.

```ts
// app/lib/corpus/opfsAdapter.ts:107-123
    async writeFile(path, bytes) {
      try {
        const root = await getRoot();
        const { dirs, name } = splitPath(path);
        const dir = await walkDir(root, dirs, true);
        const fh = await dir!.getFileHandle(name, { create: true });
        const w = await fh.createWritable();
        try {
          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
          await w.write(bytes);
        } finally {
          await w.close();
        }
      } catch (e) {
        wrap(path, e);
      }
    },
```

`if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` (`:81`). No `console.warn` appears in the file (paraphrased — no quote available because the claim is about absence). The G7 test drives the `createWritable` throw path (`opfsAdapter.test.ts:47-79`). The probe with a write that throws quota followed by a close that throws TypeError produced `io`.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:42-47,79-83,107-123`, `app/lib/corpus/__tests__/opfsAdapter.test.ts:47-79`, `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/fc-r1-probe/probe-out.txt` (line 14)

---

## Claim 12: "the way the legacy localStorage adapter does (workspaceStore.ts:44-46)"

**Location:** `app/lib/corpus/opfsAdapter.ts:13-14`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the file:line pointer. It does not cover the behavioral half (the legacy adapter does swallow with `console.warn`), which is still true at its new location.

At dc6dfb0, `workspaceStore.ts:44-46` was the `} catch (e) { console.warn("Failed to persist workspace ..."); }` block. Commit 00ba8c3 moved the adapter out. At 2dc403e, `workspaceStore.ts:40-48` holds rehydration code, for example `if (typeof raw.content !== "string") return null;` (`workspaceStore.ts:41`). The swallow now lives at `storeAdapter.ts:34-36`: `console.warn("Failed to persist workspace (localStorage quota exceeded):", e);` (`:35`).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:13-14`, `app/lib/stores/workspaceStore.ts:40-48`, `app/lib/corpus/storeAdapter.ts:30-38`, `git show dc6dfb0:app/lib/stores/workspaceStore.ts` lines 44-46

---

## Claim 13: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** `app/lib/corpus/opfsAdapter.ts:115`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the argument passed to `w.write`. It does not cover whether any OPFS implementation actually rejects shared or offset views.

The next line passes the caller's array unchanged: `await w.write(bytes);` (`:116`). No copy or new view is made (`new Uint8Array(bytes)`, `bytes.slice()` and similar are absent; see the full unit quoted in Claim 11). This was never true. The same two lines appear at f6361a3 (`opfsAdapter.ts:113-114` in that commit).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:107-123`, `git show f6361a3:app/lib/corpus/opfsAdapter.ts` lines 113-114

---

## Claim 14: "We only ever write Uint8Array" (local `OpfsWritable.write(data: Uint8Array)`)

**Location:** `app/lib/corpus/opfsAdapter.ts:25-29`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the single `write` call in this file. It does not cover lib.dom typing compatibility, which is a build claim (Claim 27).

The only call is `await w.write(bytes);` (`:116`), where `bytes` is typed `Uint8Array` by `CorpusFS.writeFile(path: string, bytes: Uint8Array)` (`types.ts:117`).

**Evidence:** `app/lib/corpus/opfsAdapter.ts:25-29,116`, `app/lib/corpus/types.ts:117`

---

## Claim 15: "`resolveWorkspaceStorage()` returns ... the existing debounced localStorage adapter by default, or a CorpusFS-backed storage when the dev flag is on"; "Selected once when the store's persist middleware initializes"

**Location:** `app/lib/corpus/storeAdapter.ts:4-6,70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the selection branch and its single call site. It does not cover zustand's internal call timing beyond its documented eager `getStorage()` call, which could not be quoted because `node_modules` is absent.

```ts
// app/lib/corpus/storeAdapter.ts:71-76
export function resolveWorkspaceStorage(): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(createOpfsCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```

The only production call site is `storage: createJSONStorage(resolveWorkspaceStorage),` (`workspaceStore.ts:497`). zustand v5's `createJSONStorage` calls `getStorage()` once when the storage wrapper is created (paraphrased — no quote available because the zustand package is not installed in the worktree, so this is from knowledge of zustand v5 source and is the reason for Medium confidence).

**Evidence:** `app/lib/corpus/storeAdapter.ts:70-76`, `app/lib/stores/workspaceStore.ts:495-498`

---

## Claim 16: "The injection seam is typed as `CorpusFS` ... so the S3 worker-proxy implementation drops in here without the store ever knowing which adapter it talks to"

**Location:** `app/lib/corpus/storeAdapter.ts:6-8`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that `workspaceStore.ts` depends only on `resolveWorkspaceStorage`, and that the blob storage takes any `CorpusFS`. It does not establish that a worker proxy needs no change to `storeAdapter.ts`: the concrete adapter is hard-coded at `:73`, so "drops in here" means editing that line.

`export function createCorpusBackedStorage(fs: CorpusFS): StateStorage {` (`:52`). The store's only corpus import is `import { resolveWorkspaceStorage } from "@/app/lib/corpus/storeAdapter";` (`workspaceStore.ts:25`).

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-76`, `app/lib/stores/workspaceStore.ts:25`

---

## Claim 17: "In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode)"

**Location:** `app/lib/corpus/storeAdapter.ts:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the flag-on storage write path. It does not cover atomicity of that single-file write on OPFS.

`const pathFor = (name: string) => \`state/${name}.json\`;` (`:55`) and `await fs.writeFile(pathFor(name), enc.encode(value));` (`:62`). One file per persist key, and the store uses one key (`name: "workspace-zustand-v1"`, `workspaceStore.ts:494`).

**Evidence:** `app/lib/corpus/storeAdapter.ts:52-68`, `app/lib/stores/workspaceStore.ts:494`

---

## Claim 18: "the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used by the store until S4"

**Location:** `app/lib/corpus/storeAdapter.ts:11-12`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the filename reference. The "not used by the store" half is true: no non-test import of `paths.ts` or `manifest.ts` exists.

`layout.ts` was renamed to `paths.ts` in 122d70f (the commit body says "Rename app/lib/corpus/layout.ts -> paths.ts"). No `app/lib/corpus/layout.ts` exists at 2dc403e (paraphrased — no quote available because the claim is about file presence).

**Evidence:** `app/lib/corpus/storeAdapter.ts:11`, commit 122d70f (`app/lib/corpus/{layout.ts => paths.ts}`)

---

## Claim 19: "moved verbatim from workspaceStore.ts"

**Location:** `app/lib/corpus/storeAdapter.ts:21`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the function body. The function's name, export status and declared return type changed.

The body is line-for-line identical to the old `createDebouncedStorage` (compare `storeAdapter.ts:26-45` with `git show dc6dfb0:app/lib/stores/workspaceStore.ts` lines 36-56). The header changed from `function createDebouncedStorage(): { getItem: ...; setItem: ...; removeItem: ... } {` to `export function createDebouncedLocalStorage(): StateStorage {` (`:25`). A more precise wording: "body moved verbatim; renamed and retyped as `StateStorage`". Commit 00ba8c3's "Debounced localStorage moved here verbatim" gets the same verdict.

**Evidence:** `app/lib/corpus/storeAdapter.ts:25-46`, `git show dc6dfb0:app/lib/stores/workspaceStore.ts` lines 31-56

---

## Claim 20: "so the OFF path is byte-for-byte the prior behavior" ("OFF path unchanged", commit 00ba8c3)

**Location:** `app/lib/corpus/storeAdapter.ts:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the getItem/setItem/removeItem semantics and persisted bytes when the flag is off. It does not cover one new side effect at store init: a `localStorage.getItem("corpus-fs-enabled")` read and a `process.env` check (`flag.ts:16-19`). Nor does it establish that the characterization test guards the debounce semantics (Claim 5).

With the flag off, `resolveWorkspaceStorage` returns `createDebouncedLocalStorage()` (`storeAdapter.ts:75`). That body is identical to the prior adapter (Claim 19) and is passed to the same `createJSONStorage(...)` (`workspaceStore.ts:497`). The other persist options, `name`, `skipHydration`, `merge` and `partialize`, are unchanged because the diff hunk touches only the `storage:` line (`workspaceStore.ts:493-498` in the diff).

**Evidence:** `app/lib/corpus/storeAdapter.ts:25-46,71-76`, `app/lib/stores/workspaceStore.ts:493-500`, `app/lib/corpus/flag.ts:15-25`

---

## Claim 21: "The seam is typed as CorpusFS so the S3 worker-proxy is a drop-in."

**Location:** `app/lib/stores/workspaceStore.ts:496`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the type the store actually binds to. It does not challenge the drop-in conclusion (Claim 16).

At this call site the store binds to zustand's `StateStorage`, not to `CorpusFS`: `storage: createJSONStorage(resolveWorkspaceStorage),` (`:497`), where `resolveWorkspaceStorage(): StateStorage` (`storeAdapter.ts:71`). `CorpusFS` is the parameter type one layer down (`createCorpusBackedStorage(fs: CorpusFS)`, `storeAdapter.ts:52`). A more precise wording: "the store sees `StateStorage`; the corpus storage inside it is typed against `CorpusFS`."

**Evidence:** `app/lib/stores/workspaceStore.ts:493-498`, `app/lib/corpus/storeAdapter.ts:52,71`

---

## Claim 22: "`CorpusError` is the thrown form; `CorpusWorkerError` is its postMessage-serializable twin. They differ only in transport, never in the kind set."

**Location:** `app/lib/corpus/types.ts:27-30`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the type definitions. It does not cover a worker transport, which does not exist yet.

`readonly detail: CorpusErrorKind;` (`types.ts:53`) and `detail: CorpusErrorKind;` in `CorpusWorkerError` (`types.ts:65`). Both use the single union.

**Evidence:** `app/lib/corpus/types.ts:41-72`

---

## Claim 23: "'Not found' is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`"; "Implementations create intermediate directories on write"; `rm` "Idempotent"

**Location:** `app/lib/corpus/types.ts:18-19,110-125`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both implementations by reading their code (`opfsAdapter.ts`, `inMemoryCorpusFs.ts`). Success-path behavior on real OPFS was not executed (no browser), so the OPFS half rests on reading the code alone.

OPFS: a missing directory gives `if (!dir) return null;` / `return [];` / `return;` (`opfsAdapter.ts:91,129,143,160`), a missing file gives `if (isNotFound(e)) return null;` (`:96,165`), and all other errors go through `wrap`, which always throws a `CorpusError` (`:79-83`). Directories are created on write with `walkDir(root, dirs, true)` (`:111`). The fake creates directories implicitly from key prefixes and has `rm` as `files.delete(...)` (`inMemoryCorpusFs.ts:35`). The contract suite exercises all of this against the fake (`corpusFsContract.ts:21-56`).

**Evidence:** `app/lib/corpus/types.ts:104-125`, `app/lib/corpus/opfsAdapter.ts:85-176`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:17-52`

---

## Claim 24: "26 tests pass." (commit 3da6747) and "3 tests pass." (commit f6361a3)

**Location:** commit 3da6747 body; commit f6361a3 body
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a static count of test declarations. It does not establish that they pass, because execution is required and was blocked (no `node_modules`, no network).

The static counts match. At 3da6747 the files contain contract 7, layout 10, manifest 5 and characterization 4, for 26 (paraphrased — no quote available because these are `it(` counts across four files from `rg -c`). At f6361a3, `opfsAdapter.test.ts` contains 3 `it(` calls.

**Evidence:** `app/lib/corpus/__tests__/corpusFsContract.ts`, `app/lib/corpus/__tests__/paths.test.ts`, `app/lib/corpus/__tests__/manifest.test.ts`, `app/lib/stores/__tests__/workspaceStore-characterization.test.ts`, `app/lib/corpus/__tests__/opfsAdapter.test.ts`

---

## Claim 25: "69 corpus+store tests pass." (commit 00ba8c3)

**Location:** commit 00ba8c3 body
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the static declaration count for `app/lib/corpus/__tests__` plus `app/lib/stores/__tests__`. Pass status needs execution, which was blocked.

The static count is exactly 69: corpus 7+5+3+10 = 25, and stores are characterization 4, corpus-flag 3, hydration 8, workspaceStore 17 and artifactEditHandlers 12 (two `it.each(KEYS)` over 5 keys plus 2 plain `it`), giving 44 (paraphrased — no quote available because this is a count across nine files).

**Evidence:** `app/lib/stores/__tests__/artifactEditHandlers.test.ts:6-12,27,40`, `rg -c` over `app/lib/corpus/__tests__` and `app/lib/stores/__tests__`

---

## Claim 26: "324 vitest tests pass." (commit 122d70f)

**Location:** commit 122d70f body
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a literal-call-site count only. The suite needs to run to confirm 324, and running was blocked.

A count of literal `it(`/`test(` call sites in `*.test.ts(x)` files is 307, plus 10 from `.each` expansions, giving 317 (paraphrased — no quote available because this is a repo-wide count). The gap of 7 could come from tests declared inside loops. This replicate cannot confirm or refute it. This is the claim type the hallucination log flags (a specific test denominator).

**Evidence:** repo-wide `rg -c '^\s*(it|test)\('` over `*.test.ts`/`*.test.tsx`

---

## Claim 27: "Verified: npm run lint clean, npm run build passes" (commit 122d70f)

**Location:** commit 122d70f body
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing executed. Under the mandatory-execution rule, a build or lint claim stays Unverifiable until it is run.

Blocker: the worktree has no `node_modules` and the sandbox has no network, so neither `next build` nor `eslint` can run. The rename rationale ("Next.js App Router treats any app/**/layout.ts as a route layout") is consistent with App Router special-file conventions for non-underscore folders under `app/`, but it was not executed (paraphrased — no quote available because this is framework behavior outside the repo).

**Evidence:** commit 122d70f body, `package.json` scripts `build`/`lint`

---

## Claim 28: "one-line storage swap to resolveWorkspaceStorage; net shrinks the store file" (commit 00ba8c3)

**Location:** commit 00ba8c3 body
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line delta for `workspaceStore.ts`. "One-line" is loose: the change is one import line plus one changed `storage:` line plus three comment lines.

`git diff --stat dc6dfb0..00ba8c3 -- app/lib/stores/workspaceStore.ts` gives `38 +++++---------------------------------` with `5 insertions(+), 33 deletions(-)`, a net of −28. At 2dc403e the file is 546 lines, against 574 at dc6dfb0.

**Evidence:** `app/lib/stores/workspaceStore.ts:25,493-498`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`app/lib/corpus/__tests__/corpusFs.contract.test.ts:2`): the OPFS adapter is not run against the contract suite. The smoke doc is an unexecuted six-check sketch, so say "intended to be run" or wire it up.
- **Claim 2** (`app/lib/corpus/__tests__/corpusFsContract.ts:4-7`): same. Only the fake is run, so "held to identical behavior" is not true yet.
- **Claim 3** (`app/lib/corpus/__tests__/inMemoryCorpusFs.ts:5-7`): "substitutability is verified, not assumed" is backwards for S1. It is currently assumed.
- **Claim 4** (`app/lib/corpus/__tests__/opfsAdapter.test.ts:4-6`, also commit f6361a3): nothing covers the success path. The step-9 smoke has "not yet run" results.
- **Claim 6b** (`app/lib/corpus/flag.ts:4`): "DEV-ONLY" is not enforced. There is no NODE_ENV gate, so the localStorage key works in production builds.
- **Claim 7** (`app/lib/corpus/manifest.ts:10-14`): malformed array elements are filtered out silently, so a corrupt manifest can parse to an empty one (probe-confirmed). `currentVersion` is not validated, and `browser-storage-cleared` is never raised.
- **Claim 8a** (`app/lib/corpus/paths.ts:16-18`): `storeAdapter.ts:55` hand-builds `state/${name}.json`, and no production code imports `paths.ts`.
- **Claim 13** (`app/lib/corpus/opfsAdapter.ts:115`): the comment says a fresh view is passed, but `w.write(bytes)` passes the caller's array unchanged. This was never true.

### Stale
- **Claim 12** (`app/lib/corpus/opfsAdapter.ts:14`): `workspaceStore.ts:44-46` now holds rehydration code. The `console.warn` swallow moved to `storeAdapter.ts:34-36`.
- **Claim 18** (`app/lib/corpus/storeAdapter.ts:11`): `layout.ts` was renamed to `paths.ts` in 122d70f.

### Mostly Accurate
- **Claim 5** (`app/lib/stores/__tests__/workspaceStore-characterization.test.ts:1-9`): pins the persisted shape and round-trip, not debounce timing, the quota swallow or `removeItem`.
- **Claim 19** (`app/lib/corpus/storeAdapter.ts:21`, also commit 00ba8c3): the body is verbatim, but the function was renamed, exported and retyped as `StateStorage`.
- **Claim 21** (`app/lib/stores/workspaceStore.ts:496`): the store binds to `StateStorage`. `CorpusFS` is one layer down.

### Unverifiable
- **Claim 6d** (`app/lib/corpus/flag.ts:9,16`): whether Next inlines `process.env?.NEXT_PUBLIC_CORPUS_FS` (optional-chain form) into the client bundle. Needs `next build` with the variable set and a grep of the client chunk.
- **Claim 24** (commits 3da6747, f6361a3): 26 and 3 match static counts. Needs a vitest run.
- **Claim 25** (commit 00ba8c3): 69 matches the static count exactly. Needs a vitest run.
- **Claim 26** (commit 122d70f): 324 against a static count of 317. Needs a vitest run.
- **Claim 27** (commit 122d70f): lint clean and build passes. Needs `node_modules` (`npm ci`) and an execution environment.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: 2dc403e` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: Code-quality findings outside the comments' claims. The probe's quota-masked-by-`close()` mechanism (Claim 11 residue) and the SecurityError→`io` mapping (Claim 10 residue) are recorded only as scope residue, not as findings. Docs outside `app/` were read as evidence, not verdicted.
- Escalate: (1) The OPFS success path has no executed coverage (Claims 1-4), and the "same contract suite" story is the PR's main test-substitutability claim. (2) The manifest codec silently drops malformed entries (Claim 7), which defeats its stated G11 contract. (3) "Dev-only" is not enforced in code (Claim 6b). (4) All test-count, lint and build claims (24-27) and the client-side env route (6d) need an execution environment with `node_modules`, which this replicate lacked.
- Decisions I made: I did not append to `docs/reviews/hallucination-patterns.md`, because the brief said to write no other file and none of the Incorrect verdicts is a fabricated symbol or API. The behavioral claims were executed by copying four source files to a scratch dir and running them under `node --experimental-strip-types`, the only change being the `./types` import specifier rewritten to `./types.ts` so Node could resolve it. The worktree itself was not modified.
