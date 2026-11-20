Commit: 2dc403e

# Test Strategy: DD-009 S0+S1 corpus slice (dc6dfb0..2dc403e, `app/` only)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` (15 files). This is a partial scope: the docs/spike files on the branch are context only.
**Reviewed:** 2026-11-19
**Method:** I read every changed source file in full, plus the six corpus test files, the two store test files, `vitest.config.ts`, `package.json`, `workspaceStore.ts:490-546` and `docs/spikes/corpus-opfs-smoke.md`. I did not execute anything: the worktree has no `node_modules`, and this pass allows no network.

## Test Conventions

- Vitest 4 (`"test": "vitest run"`), `environment: 'jsdom'`, `globals: true`, `@` alias to the repo root (`vitest.config.ts`). The repo has no Playwright dependency and no browser test runner.
- Tests sit in `__tests__/` next to the code and end in `.test.ts`. Shared helpers in `__tests__/` carry no `.test` suffix (`corpusFsContract.ts`, `inMemoryCorpusFs.ts`).
- Patterns in use:
  - a parametrized contract suite (`defineCorpusFsContract(label, makeFs)`);
  - hand-built OPFS handle fakes injected through `Object.defineProperty(navigator, "storage", …)`;
  - `vi.useFakeTimers()` with `advanceTimersByTime(300)` to flush the debounce;
  - assertions on `CorpusError.detail.kind` rather than on message strings.
- Available infrastructure: the in-memory `CorpusFS` fake, and the OPFS handle-fake shape from `opfsAdapter.test.ts:58-74` and `workspaceStore-corpus-flag.test.ts`. That handle fake is enough to drive the adapter's success-path logic in jsdom. It is not real OPFS.

## Untested Paths Touched by the Change

- **G1**: `app/lib/corpus/opfsAdapter.ts:87-174`. This is the OPFS adapter's success path for all five methods. Covered cases: the `unavailable` guard, and quota thrown from `createWritable`. Not covered: a read, write, readdir, stat or rm that succeeds. The only `defineCorpusFsContract` caller passes the in-memory fake, and the Playwright smoke is unrun ("_(not yet run …)_").
- **G2**: `app/lib/corpus/opfsAdapter.ts:66-77, 92, 97, 130, 144, 148, 161, 166`. These are the not-found early returns: a missing parent dir returns `null`/`[]`, and a `NotFoundError`/`TypeMismatchError` on the file handle returns `null`. No test reaches them, because both handle fakes always resolve.
- **G3**: `app/lib/corpus/opfsAdapter.ts:113-119`. The `finally { await w.close() }` path: if `write()` rejects with quota and `close()` then rejects with something else, the close error replaces the quota error and comes out as `io` (E5). Also untested: quota raised from `write()` rather than `createWritable()`.
- **G4**: `app/lib/corpus/opfsAdapter.ts:79-83, 47-55`. The `io` arm of `wrap`: a non-quota DOMException, or `getDirectory()` throwing (`SecurityError`). Also `splitPath` throwing `io` for an empty or `/` path. Only the `unavailable` and `quota-exceeded` arms are tested.
- **G5**: `app/lib/corpus/opfsAdapter.ts:116` against `__tests__/inMemoryCorpusFs.ts:29` (`bytes.slice()`). Aliasing differs between adapters: the fake copies the caller's array and OPFS passes it through. No contract case pins what happens when the caller mutates the array after the write.
- **G6**: `__tests__/corpusFsContract.ts:57-124` (gap in the suite itself). The suite has no case for:
  - a path used as a file and then as a directory, or the reverse (`a` file, then write `a/b`);
  - `rm` on a directory;
  - leading or trailing slashes (`/a.txt`, `dir/`).

  The fake allows a file/dir clash, while OPFS raises `TypeMismatchError`. `isNotFound` folds that error into "missing" on reads and turns it into `io` on writes. The two adapters therefore diverge in ways the shared suite cannot detect.
- **G7**: `app/lib/corpus/manifest.ts:86-91, 93-100, 102-104`. The `.filter(isObject)` / `.filter(typeof x === "string")` arms drop non-object source and artifact entries and non-string ids silently, without failing (E2). Only the "object missing id" arm is tested (`manifest.test.ts:236-241`). Also untested: the `fail()` arms for a non-array `sources`, `artifacts` or `customTypeIds`, the artifact-pointer `fail`, and the `label` fallback to `id`.
- **G8**: `app/lib/corpus/manifest.ts:107-110`. `manifestVersion` is never compared to `MANIFEST_VERSION`, so `manifestVersion: 999` and a negative or fractional `currentVersion` are both accepted. A missing `createdAt` or `updatedAt` defaults to `new Date()`. No test covers either.
- **G9**: `app/lib/corpus/storeAdapter.ts:52-68`. Error propagation in `createCorpusBackedStorage`: a rejecting `fs.readFile` or `fs.writeFile` (a `CorpusError`) flows into zustand persist. Nothing tests whether the error reaches `onRehydrateStorage`'s `error` argument on read, or ends up as an unhandled rejection on write. Also untested: `getItem` on a zero-byte file. `bytes ? … : null` treats a zero-length `Uint8Array` as truthy, so it decodes to `""`, and `createJSONStorage` then calls `JSON.parse("")`.
- **G10**: `app/lib/corpus/storeAdapter.ts:25-46`. The parts of the debounced localStorage adapter the move did not pin (fact-check claim 9):
  - the `catch` that swallows a quota error;
  - coalescing of several `setItem` calls within 300 ms;
  - `removeItem` cancelling a pending write;
  - a write landing at exactly 300 ms and not at 299 ms.

  The characterization test checks only the persisted shape after 300 ms.
- **G11**: `app/lib/corpus/flag.ts:16-23`. Three branches have no test:
  - `NEXT_PUBLIC_CORPUS_FS === "1"` returns true;
  - a `localStorage.getItem` that throws, caught and returning false;
  - SSR (`window` undefined) returning false.

  Only the localStorage `"1"` route is covered, indirectly, through `resolveWorkspaceStorage`.
- **G12**: `app/lib/stores/workspaceStore.ts:528-541` together with `storeAdapter.ts:72-73`. With the flag on, `onRehydrateStorage` still reads `localStorage` directly and can call `migrateFromV2()` over a store that persists to the corpus (E4). Nothing tests that the flag-on rehydrate (async storage) works end to end through the real store.
- **G13**: `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:1245-1267` (shared-block line numbers). This flag-on test is weak. It asserts only that `getDirectory` was called and that localStorage is empty. It never checks that the bytes reached a `state/workspace-zustand-v1.json` handle, and it never resets `CORPUS_FLAG_KEY` explicitly; `afterEach`'s `localStorage.clear()` covers that today.
- **G14**: `app/lib/corpus/paths.ts:52-58, 60-64, 70-84`. Untested in paths.ts:
  - `safeSegment` throwing on an all-unsafe id;
  - `safeExt` falling back to `"bin"` (`sourcePath(s,"x","")`, `sourcePath(s,"x","..")`);
  - accented-unicode titles (`"Café"` becomes `"cafe-"`, then is trimmed);
  - a `workspaceSlug` that differs from the slug passed in, since `workspaceDir` re-slugs its argument, so `workspaceDir("My-Slug")` gives `workspaces/my-slug`.
- **G15**: `app/lib/corpus/types.ts:1011-1017, 1020-1031` (shared-block line numbers). `toWorkerError`, `isCorpusWorkerError` and `describeCorpusError` arms have no direct test. This is low risk, since the exhaustive switch is compile-checked.

## Findings

### F1: OPFS adapter success path has no executed coverage (E1)
- **Severity:** high
- **Location:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-8`; `app/lib/corpus/opfsAdapter.ts:87-174`
- **Evidence:** `defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());` and from `docs/spikes/corpus-opfs-smoke.md`: `_(not yet run — fill in when executed before enabling the flag in a shared environment)_`
- **Confidence:** high
- **Legibility-target:** for-author

### F2: Manifest silent-drop arms are untested and contradict the fail-loud contract (E2)
- **Severity:** medium
- **Location:** `app/lib/corpus/manifest.ts:87, 94, 103` (all inside `parseManifest`, :74-115, read in full)
- **Evidence:** `    ? raw.sources.filter(isObject).map((s) => {` / `    ? raw.artifacts.filter(isObject).map((a) => {` / `    ? raw.customTypeIds.filter((x): x is string => typeof x === "string")`
- **Confidence:** high, matching fact-check claim 3, which ran these arms 3/3.
- **Legibility-target:** for-author

### F3: Quota masked by `close()` in `finally` (E5)
- **Severity:** medium
- **Location:** `app/lib/corpus/opfsAdapter.ts:114-119` (enclosing `writeFile` :107-123, read in full)
- **Evidence:** `        try {` / `          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.` / `          await w.write(bytes);` / `        } finally {` / `          await w.close();` / `        }`
- **Confidence:** medium. The mechanism is certain. How real browsers behave, that is, whether `close()` after a failed `write()` throws, is unverified.
- **Legibility-target:** for-author

### F4: Corpus-backed storage error flow into zustand is unpinned
- **Severity:** medium
- **Location:** `app/lib/corpus/storeAdapter.ts:57-63` (enclosing `createCorpusBackedStorage` :52-68, read in full)
- **Evidence:** `    getItem: async (name) => {` / `      const bytes = await fs.readFile(pathFor(name));` / `      return bytes ? dec.decode(bytes) : null;` / `    },` / `    setItem: async (name, value) => {` / `      await fs.writeFile(pathFor(name), enc.encode(value));`
- **Confidence:** medium. Whether zustand persist catches a rejected `setItem` depends on the installed zustand version, which I could not run.
- **Legibility-target:** for-author

### F5: Flag-on rehydrate still consults localStorage and may run migrateFromV2 (E4)
- **Severity:** medium
- **Location:** `app/lib/stores/workspaceStore.ts:533-540` (enclosing `onRehydrateStorage` :528-543, read in full)
- **Evidence:** `          if (typeof window !== "undefined" && localStorage.getItem(WORKSPACE_KEY)) {` / `            const zustandRaw = localStorage.getItem("workspace-zustand-v1");`
- **Confidence:** medium
- **Legibility-target:** for-orchestrator-synthesis, because the behavior decision belongs to architecture-review. The test only pins whichever behavior is chosen.

## Recommended Tests

#### OPFS adapter against the shared contract in jsdom via an in-memory OPFS handle fake
**Closes gaps:** G1, G2
**Type:** contract
**Priority:** high
**File:** `app/lib/corpus/__tests__/opfsFake.ts` (new helper) and `app/lib/corpus/__tests__/corpusFs.contract.test.ts` (add a second `defineCorpusFsContract` call)
**What it verifies:** The adapter's path walking, not-found folding, `keys()` listing and byte read and write meet the same contract as the fake when they run over a faithful in-memory FileSystemDirectoryHandle. This is not real OPFS, but it puts every success line and early return into CI.
**Key cases:**
- `defineCorpusFsContract("opfs adapter over handle fake", () => { setStorage({getDirectory: async () => makeFakeDir()}); return createOpfsCorpusFs(); })`. All seven existing cases should pass.
- The handle fake throws `DOMException("…","NotFoundError")` for `getDirectoryHandle` or `getFileHandle` with `{create:false}` on a missing name, and `TypeMismatchError` on a kind clash, matching the spec.
- `readdir("nope")` returns `[]`, through the walkDir null return at :130.

**Setup needed:** About 60 lines: a Map-of-Maps dir and file fake with an async `keys()` generator. Keep it as strict as the spec (CLAUDE.md "stub at least as strict"): throw on a kind clash, never resolve silently.

#### Run the Playwright OPFS smoke and record results (pre-flag-default gate)
**Closes gaps:** G1 (real substrate)
**Type:** e2e
**Priority:** medium. It is high before the flag ships to anyone beyond a dev, but is out of CI by design.
**File:** results go in `docs/spikes/corpus-opfs-smoke.md` §Results. Ideally the runner exports the existing `defineCorpusFsContract` cases rather than re-hand-writing the six checks.
**What it verifies:** That real Chromium and Firefox OPFS meet the contract.
**Key cases:** the six listed in the spike; add the G6 clash cases once they are defined.
**Setup needed:** Playwright browsers and an esbuild bundle (not in `package.json`).

#### Contract cases for file/dir clash, rm-of-directory, slash normalization, aliasing
**Closes gaps:** G5, G6
**Type:** contract
**Priority:** medium
**File:** `app/lib/corpus/__tests__/corpusFsContract.ts`
**What it verifies:** Both adapters agree on the edge semantics that S2 and S4 will depend on.
**Key cases:**
- `writeFile("a", x)` then `writeFile("a/b", y)` rejects with `CorpusError` of kind `io`. This requires the fake to start rejecting, which is a deliberate contract decision.
- `readFile("/a.txt")` after `writeFile("a.txt")` returns the bytes. `readFile("")` rejects `io` (splitPath).
- `const b = new Uint8Array([1]); await fs.writeFile("x", b); b[0] = 9;` then `readFile("x")` returns `[1]`, the copy semantics. Decide the semantics, then either make OPFS copy or drop the fake's copy.
- `rm("dir")` on a non-empty dir: assert the agreed behavior, whether that is reject `io` or no-op.

**Setup needed:** none beyond the G1 handle fake.

#### OPFS adapter error arms: close-masks-quota, write-quota, io, SecurityError
**Closes gaps:** G3, G4
**Type:** unit
**Priority:** high for G3, medium for G4
**File:** `app/lib/corpus/__tests__/opfsAdapter.test.ts`
**What it verifies:** Every failure becomes the correct `CorpusError` kind.
**Key cases:**
- `write()` throws `QuotaExceededError` and `close()` throws `DOMException("x","InvalidStateError")`: expect `kind:"quota-exceeded"`. This fails today, which is intended: it pins the E5 fix.
- `write()` throws quota and `close()` resolves: `quota-exceeded`.
- `getDirectory` rejects `DOMException("denied","SecurityError")`: `kind:"io"`, or `unavailable` if the author reclassifies it. Assert the chosen kind.
- `getFileHandle` throws `DOMException("x","NoModificationAllowedError")` on readFile: `io`, with `path` equal to the input.
- `writeFile("/", bytes)`: `io` with reason "path has no file component".

**Setup needed:** extend the existing `fakeRoot` pattern.

#### Manifest strictness: silent-drop arms, version check, timestamps
**Closes gaps:** G7, G8
**Type:** unit (plus one property test if `fast-check` is ever added; it is not in deps now)
**Priority:** high
**File:** `app/lib/corpus/__tests__/manifest.test.ts`
**What it verifies:** Every malformation the docstring promises to reject is rejected.
**Key cases:**
- `sources: ["x"]`, `artifacts: [42]` and `customTypeIds: [1]` each throw `CorpusError`. These fail today, by intent.
- `sources: "x"`, `artifacts: null` and missing `customTypeIds` each throw (the existing arms, so pin them).
- `artifacts: [{type:"t"}]` throws `/artifact pointer missing/`.
- `manifestVersion: 999` throws, or else is documented as forward-compatible. Assert whichever is decided.
- `currentVersion: 0`, `-1` and `1.5` throw, consistent with `artifactVersionPath`.
- A missing `createdAt` throws, or is pinned as an intentional default. As written, `vi.setSystemTime` would be needed to assert the default.
- A source without `label` gives `label === id`.

**Setup needed:** none.

#### Corpus-backed storage error propagation and empty-file read
**Closes gaps:** G9
**Type:** unit
**Priority:** medium
**File:** `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts`
**What it verifies:** A `CorpusError` from the FS reaches the caller and is not swallowed or left unhandled.
**Key cases:**
- An FS whose `readFile` rejects `new CorpusError({kind:"io",…})`: `storage.getItem` rejects with that error. Through `createJSONStorage` plus the store, `onRehydrateStorage` receives `error`.
- An FS whose `writeFile` rejects quota: `storage.setItem` rejects with `kind:"quota-exceeded"`. Add a store-level check that `useWorkspaceStore.setState(...)` produces no unhandled rejection: register `process.on("unhandledRejection")` in the test, or assert the chosen surfacing.
- An FS containing a zero-byte `state/x.json`: `getItem` returns `""`. Assert the decided behavior, either `null` or a surfaced parse error.

**Setup needed:** a tiny wrapper around `createInMemoryCorpusFs()` that overrides one method to reject.

#### Debounce characterization: coalescing, cancel-on-remove, quota swallow
**Closes gaps:** G10
**Type:** unit (characterization)
**Priority:** medium. This is the "byte-for-byte OFF path" guarantee the PR rests on.
**File:** `app/lib/stores/__tests__/workspaceStore-characterization.test.ts`, or a new `app/lib/corpus/__tests__/storeAdapter.test.ts`
**What it verifies:** The moved `createDebouncedLocalStorage` keeps the prior timing and error behavior.
**Key cases:**
- `setItem("k","a")`, then `setItem("k","b")` 100 ms later: at 299 ms after the second call, `getItem` returns null; at 300 ms it returns `"b"`, with exactly one write (spy on `Storage.prototype.setItem`).
- `setItem("k","a")` then immediately `removeItem("k")`, advance 300 ms: still null.
- `Storage.prototype.setItem` throws `DOMException("q","QuotaExceededError")`: no throw, and `console.warn` is called once with the message prefix.

**Setup needed:** `vi.spyOn(Storage.prototype, "setItem")` and `vi.spyOn(console, "warn")`.

#### Flag routing: env route, throwing localStorage, SSR
**Closes gaps:** G11
**Type:** unit
**Priority:** medium. The env route is the only build-time switch, and fact-check claim 24 doubts it inlines.
**File:** `app/lib/corpus/__tests__/flag.test.ts` (new)
**What it verifies:** `isCorpusEnabled` handles every branch.
**Key cases:**
- `vi.stubEnv("NEXT_PUBLIC_CORPUS_FS","1")` returns true; `"0"` with localStorage unset returns false.
- `vi.spyOn(Storage.prototype,"getItem").mockImplementation(() => { throw new Error("SecurityError") })` returns false.
- `localStorage.setItem(CORPUS_FLAG_KEY,"true")` returns false (only `"1"` counts).

**Setup needed:** `vi.unstubAllEnvs()` in `afterEach`. Whether Next inlines `process.env?.X` in the client bundle is not something vitest can show; that needs a `next build` probe (E6).

#### Store-level flag-on round-trip and legacy-migration interaction
**Closes gaps:** G12, G13
**Type:** integration
**Priority:** medium
**File:** `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts`
**What it verifies:** With the flag on, the real `useWorkspaceStore` persists to the corpus path and rehydrates from it, and the `WORKSPACE_KEY` migration does or does not run, per the decided behavior.
**Key cases:**
- Strengthen G13: after `setItem`, read back through the handle fake (from the G1 helper). Assert that `state/workspace-zustand-v1.json` holds the exact string.
- Set the flag and the G1 OPFS fake, then `vi.resetModules()` and dynamic-import `workspaceStore` (storage is resolved at module init). `setState({sourceText:"x"})`, reset to initial, `await persist.rehydrate()`: `sourceText === "x"`.
- The same setup with `localStorage.setItem(WORKSPACE_KEY, <v2 blob>)` and corpus data present: assert whether `migrateFromV2` overwrites. Today it reads `workspace-zustand-v1` from localStorage, finds it empty, and migrates over the corpus state, which is E4. The test pins the decision.

**Setup needed:** `vi.resetModules()` and the G1 OPFS handle fake.

#### paths.ts residual arms
**Closes gaps:** G14
**Type:** unit
**Priority:** low
**File:** `app/lib/corpus/__tests__/paths.test.ts`
**Key cases:**
- `safeSegment("///")` throws `/empty path segment/`.
- `sourcePath(s,"x","")` and `sourcePath(s,"x","..")` both end `x.bin`.
- `workspaceSlug("Café")` equals `"cafe"`. NFKD splits the accent off, and it then becomes a trailing hyphen that is trimmed. Pin it, and fix the "strips unicode" docstring.
- `workspaceManifestPath("../x")` stays under `workspaces/` and has no `..`.

**What it verifies:** The traversal choke point holds for ids and extensions as well as titles.
**Setup needed:** none.

## What NOT to Test

- **G15** (`types.ts` worker-error helpers, `describeCorpusError`): the `assertNever` switch is compile-time exhaustive, and the worker transport does not exist until S3. One `toWorkerError`/`isCorpusWorkerError` round-trip would be cheap, but it is optional. Defer it to S3, where the transport makes it meaningful.
- Snapshot tests of `serializeManifest` output formatting (2-space JSON) would be brittle and add nothing beyond the existing round-trip.
- Quota by actually filling OPFS in CI: slow and impossible under jsdom. The handle-fake quota cases (G3) cover the mapping logic.

## Coverage Gaps Beyond Current Scope

**1.** `docs/spikes/corpus-opfs-smoke.md` names no owner and no trigger for running the gate. Nothing stops the flag from being defaulted on with §Results still empty. A CI or lint check that the flag's default stays off, or that the smoke results exist, would make the gate mechanical.
**2.** `migrateFromV2` and the `workspace-v2` legacy path in `workspaceStore.ts` predate this diff. They were not surveyed here beyond the G12 interaction.

## Summary

The highest-value addition is a spec-strict in-memory OPFS handle fake. With it, the existing `defineCorpusFsContract` suite runs against `createOpfsCorpusFs()` in CI (G1, G2), and the four docstrings that currently claim that coverage become true. Next in value are the manifest strictness cases (G7, G8) and the close-masks-quota case (G3). Both will fail against the current code, and they should be written that way to pin the fixes. After the plan runs, the main residual risk is real-browser OPFS semantics, which no jsdom fake proves; that stays with the unrun Playwright smoke. Three behaviors need the author's decision before their tests can assert anything: the file/dir clash and aliasing semantics shared by both adapters (G5, G6), what `manifestVersion` mismatches should do (G8), and whether flag-on rehydrate should ever run `migrateFromV2` (G12).

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: 2dc403e` as its first line, structured per the test-strategy skill.
- Answered: yes
- Out of scope: running vitest, `next build` or Playwright (no `node_modules`, no network); code outside `app/` except as context.
- Escalate: (1) The E1, E2 and E5 tests (G1, G7/G8, G3) are written to fail against current code, so the orchestrator should treat them as fix-and-test units, not test-only additions. (2) Three design decisions must come first: clash and aliasing semantics in the contract (G5/G6), the manifest version policy (G8), and the flag-on `migrateFromV2` behavior (G12, the same as E4, for architecture-review). (3) E6 stands: the env-flag inlining (G11) and the zustand rejection handling (G9) need a provisioned run.
- Decisions I made: I put the G13 strengthening under G12's integration test. I also proposed a jsdom OPFS handle fake as the CI route for G1 rather than adding Playwright to CI, because the repo has no browser runner.
