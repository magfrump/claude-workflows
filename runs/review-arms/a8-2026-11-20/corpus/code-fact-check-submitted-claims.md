Commit: 2dc403e

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (reviewed worktree `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-corpus`, detached HEAD 2dc403e)
**Scope:** Stage 2.5 submitted claims only (S1-S7) over `dc6dfb0..2dc403e -- app/` (partial scope: `app/` only; non-`app/` files are context). No claims harvested from the diff in this pass.
**Checked:** 2026-11-19 (probes timestamped 2026-11-20T02:03-02:04Z UTC)
**Total claims checked:** 7
**Summary:** 4 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Field note: **Legibility-target** names the reader each verdict is written for and the one thing they should be able to act on without re-reading the code.

Execution environment for all executed claims: Node v22.23.2, `node --experimental-strip-types`. The corpus modules were copied to `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25-corpus/`, with only their relative import specifiers rewritten to `.ts` (needed for Node ESM resolution; no logic changed). zustand was loaded from `/workspace/external/cc-review-eval/mfc-corpus/node_modules/zustand/esm/` (version 5.0.13). That matches the reviewed repo's lockfile (`package-lock.json:11138-11139`, `"node_modules/zustand": { "version": "5.0.13"`), and `package.json` is unchanged across the range. Logs and probe scripts are in `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/`. No hallucination-pattern log exists in the reviewed repo (`docs/reviews/hallucination-patterns.md` is absent), so there were no logged patterns to compare against.

---

## Submitted Claims

## Claim 26: "The removed comment 'avoids JSON.stringify on every keystroke' was never true: zustand's `createJSONStorage` stringifies before calling `setItem`, so both adapters pay a full stringify per `set()`, and the debounce only saves the storage write."

**Submitted by:** performance-reviewer
**Location:** `app/lib/corpus/storeAdapter.ts:21-46`; removed comment at `app/lib/stores/workspaceStore.ts:27` (dc6dfb0)
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** Performance rubric row. The debounce never avoided serialization. Every `set()` pays `partialize` plus a full `JSON.stringify` on both paths, and the corpus path also pays one un-debounced OPFS write per `set()`.
**Scope:** Covers zustand 5.0.13's `createJSONStorage.setItem` and persist's per-`set()` `setItem` call, as they apply to the debounced adapter and the corpus-backed adapter. Does not establish the real cost per keystroke in the app (state size, how often `set()` runs per keystroke), and does not measure OPFS write latency.

zustand stringifies inside the wrapper before the raw storage sees the value:

```js
// node_modules/zustand/esm/middleware.mjs:300 (zustand 5.0.13, createJSONStorage)
setItem: (name, newValue) => storage.setItem(name, JSON.stringify(newValue, options == null ? void 0 : options.replacer)),
```

and persist calls that `setItem` on every `set()`, after `partialize`:

```js
// node_modules/zustand/esm/middleware.mjs (persistImpl)
const setItem = () => {
  const state = options.partialize({ ...get() });
  return storage.setItem(options.name, { state, version: options.version });
};
...
(...args) => { set(...args); return setItem(); },
```

The debounce sits inside the raw adapter, below the stringify. Only `localStorage.setItem` is deferred:

```ts
// app/lib/corpus/storeAdapter.ts:29-38 (excerpt ends :38; enclosing createDebouncedLocalStorage() continues to :46 — read)
setItem: (name, value) => {
  if (pending) clearTimeout(pending);
  pending = setTimeout(() => {
    try {
      localStorage.setItem(name, value);
```

Executed: a zustand vanilla store with persist and `createJSONStorage`, where `JSON.stringify` is counted. 10 `set()` calls produced 10 stringify calls and 0 localStorage writes on the debounced adapter (one write after 350 ms). The corpus-backed adapter also produced 10 stringify calls. The debounced function moved verbatim (a `diff` of old `workspaceStore.ts:37-57` against new `storeAdapter.ts:26-46` shows only a line offset and one blank line), so the old comment's claim was false before the move as well. The corpus-backed `setItem` (`storeAdapter.ts:61-63`, `await fs.writeFile(pathFor(name), enc.encode(value))`) has no debounce at all.

Provenance: command `timeout 30 node --experimental-strip-types --no-warnings probe-s1-s6-zustand.mjs`, cwd `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs`, exit 0, 2026-11-20T02:03:02Z.

**Evidence:** `node_modules/zustand/esm/middleware.mjs:278-304`, `app/lib/corpus/storeAdapter.ts:21-46`, `app/lib/corpus/storeAdapter.ts:52-68`, `app/lib/stores/workspaceStore.ts:499`, `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/s1-s6.log`, `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/probe-s1-s6-zustand.mjs`

---

## Claim 27: "`toWorkerError` and `new CorpusError(detail, message)` round-trip a CorpusError losslessly."

**Submitted by:** api-consistency-reviewer
**Location:** `app/lib/corpus/types.ts:41-75`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** API-consistency rubric row. The typed payload (`detail`, `message`, `name`, `instanceof`) survives the round trip, but `stack` and `cause` do not. Do not rely on the worker-side stack.
**Scope:** Covers all 9 `CorpusErrorKind` variants, each with and without a custom message, through `toWorkerError` → `structuredClone` (the postMessage algorithm) → `new CorpusError(...)`. Does not establish preservation of `stack` or `cause` (both are lost), does not establish behaviour in a real Worker realm, and does not cover the not-yet-written S3 main-thread reconstruction code.

Precise version: the round trip is lossless for `detail`, `message`, `name` and the class; it drops `stack` and any `cause`. The serializer copies only two fields:

```ts
// app/lib/corpus/types.ts:69-71
export function toWorkerError(err: CorpusError): CorpusWorkerError {
  return { __corpusError: true, detail: err.detail, message: err.message };
}
```

Reconstruction keeps the message because it is passed explicitly, and it resets `name`:

```ts
// app/lib/corpus/types.ts:54-58
constructor(detail: CorpusErrorKind, message?: string) {
  super(message ?? describeCorpusError(detail));
  this.name = "CorpusError";
  this.detail = detail;
}
```

Executed: all 18 kind/message cases compared equal on name, message, `JSON.stringify(detail)` and `instanceof CorpusError` after `structuredClone`. `back.stack === orig.stack` is `false`, and `"cause" in toWorkerError(err)` is `false`. In-realm (with no clone), `toWorkerError` aliases `detail` by reference rather than copying it (`w.detail === o.detail` is `true`).

Provenance: command `timeout 120 node --experimental-strip-types --no-warnings probe-s2-s5-s7.mjs`, cwd `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs`, exit 0, 2026-11-20T02:03:38Z.

**Evidence:** `app/lib/corpus/types.ts:41-75`, `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/s2-s5-s7.log`, `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/probe-s2-s5-s7.mjs`

---

## Claim 28: "The in-memory fake and the OPFS adapter expose identical method signatures, with a uniform not-found contract (`null`/`[]`, idempotent `rm`). Signatures only; behavioural parity is not claimed."

**Submitted by:** api-consistency-reviewer
**Location:** `app/lib/corpus/types.ts:112-125`, `app/lib/corpus/opfsAdapter.ts:85-176`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:17-53`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** API-consistency rubric row. Signatures are identical by construction, and the not-found contract matches on well-formed paths. On the empty or root path, OPFS throws `io` where the fake returns `null`, a no-op or `[]`.
**Scope:** Covers the method signatures (both factories declare return type `CorpusFS`) and the absent-file, absent-directory and leading-slash cases of `readFile`/`stat`/`readdir`/`rm` on both implementations. Does not establish the empty or `/` path (which diverges), `rm` of a directory, a file-vs-directory type mismatch on real OPFS, or any success-path parity.

Precise version: the signatures are identical, and the not-found contract is uniform for every path that has a file component. For `""` and `"/"`, OPFS `readFile`/`stat`/`rm` reject with `CorpusError{kind:"io"}`, while the fake returns `null`/`null`/`undefined`.

Signatures: both factories are object literals checked against the same interface, `export function createOpfsCorpusFs(): CorpusFS {` (`opfsAdapter.ts:85`) and `export function createInMemoryCorpusFs(): CorpusFS {` (`inMemoryCorpusFs.ts:17`). Their method parameter and return types are therefore those of `CorpusFS` (`types.ts:112-125`).

The divergence comes from OPFS's `splitPath`, which runs before any lookup:

```ts
// app/lib/corpus/opfsAdapter.ts:57-62
function splitPath(path: string): { dirs: string[]; name: string } {
  const parts = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
  const name = parts.pop();
  if (!name) throw new CorpusError({ kind: "io", path, reason: "path has no file component" });
  return { dirs: parts, name };
}
```

The fake instead normalizes the path and does a `Map` lookup, `return files.get(normalize(path)) ?? null;` (`inMemoryCorpusFs.ts:22`).

Executed: a matrix over `absent.txt`, `no/such/dir/f.txt`, `/lead/slash.txt`, `""` and `"/"`, run against the fake and against OPFS over a stub root whose lookups reject `NotFoundError`. The first three rows match exactly (`null`, `null`, `[]`, `undefined`). In the `""` and `"/"` rows, OPFS gives `readFile=THROW(io) stat=THROW(io) rm=THROW(io)` and the fake gives `null`/`null`/`undefined`. `readdir` returns `[]` on both. The stub models only OPFS's `NotFoundError` path, so real-OPFS `TypeMismatchError` cases are covered by static reading of `isNotFound` (`opfsAdapter.ts:42-44`) and not by execution.

Provenance: command `timeout 30 node --experimental-strip-types --no-warnings probe-s3-notfound.mjs /tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/s25-corpus`, cwd `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs`, exit 0, 2026-11-20T02:04:01Z.

**Evidence:** `app/lib/corpus/types.ts:112-125`, `app/lib/corpus/opfsAdapter.ts:42-62`, `app/lib/corpus/opfsAdapter.ts:85-176`, `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:13-52`, `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/s3.log`, `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/probe-s3-notfound.mjs`

---

## Claim 29: "Store consumers see no API change: `useWorkspaceStore`'s exported surface is untouched, and only the `storage:` line changed."

**Submitted by:** api-consistency-reviewer
**Location:** `app/lib/stores/workspaceStore.ts:25`, `app/lib/stores/workspaceStore.ts:495-499`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** API-consistency rubric row. The exported names are byte-identical, and nothing exported changed. "Only the storage line changed" understates the diff, and with the flag on, hydration becomes truly async.
**Scope:** Covers the set of `export` declarations in `workspaceStore.ts` before and after the change, and the default-off adapter body. Does not establish runtime behaviour when the flag is on: `rehydrate()` and `set()` become Promise-returning, and hydration completes on a later tick, which only matters to a consumer that reads state synchronously after `rehydrate()` (the one production caller, `app/page.tsx:83`, ignores the return value).

Precise version: no exported declaration changed. The file's diff also removes the non-exported `createDebouncedStorage` helper, adds `import { resolveWorkspaceStorage } from "@/app/lib/corpus/storeAdapter";` (`workspaceStore.ts:25`), and adds a 3-line comment. `git diff --stat` reports `5 insertions(+), 33 deletions(-)`. The changed line is:

```ts
// app/lib/stores/workspaceStore.ts:499
storage: createJSONStorage(resolveWorkspaceStorage),
```

A `diff` of the `^export` lines at dc6dfb0 against 2dc403e printed nothing (EXPORTS-SAME). The removed `createDebouncedStorage` was declared without `export` (`function createDebouncedStorage(): {` at old `:31`), so no consumer could have imported it. The only other `createDebouncedStorage` in `app/` is a separate private copy in `app/lib/stores/evidenceStore.ts:20`, which this change leaves untouched. The flag-off adapter body moved verbatim (see Claim 26).

**Evidence:** `app/lib/stores/workspaceStore.ts:25`, `app/lib/stores/workspaceStore.ts:495-499`, `app/lib/corpus/storeAdapter.ts:26-46`, `app/lib/stores/evidenceStore.ts:20`, `app/page.tsx:79-85`

---

## Claim 30: "`workspaceSlug` and `safeSegment` output only `[a-z0-9_-]` (respectively `[A-Za-z0-9_-]`), throw on empty results, so a `..`, `/`, `\`, fullwidth-dot/slash or NUL-bearing title or id yields no traversal segment in a built path."

**Submitted by:** security-reviewer
**Location:** `app/lib/corpus/paths.ts:28-58`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** Security rubric row. The sanitizers themselves are sound, and every builder in `paths.ts` routes through them. The remaining traversal risk lies in callers that bypass the builders, not in the builders.
**Scope:** Covers the output alphabet and empty-throw of `workspaceSlug`/`safeSegment`, plus every builder in `paths.ts` (including `safeExt`, which defaults to `bin`). Does not establish that callers use the builders (the critic's stated scope: `storeAdapter.ts:55` hand-builds `state/${name}.json`, today with the constant name `workspace-zustand-v1`). It also does not establish anything about slug collisions (`a/b` and `a\b` both map to `a-b`) or about rejection of non-Latin titles (an all-CJK or `ß` title throws).

The only sanitizer is a negated allow-list followed by trimming and an empty check:

```ts
// app/lib/corpus/paths.ts:28, 36-47
const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;
...
export function workspaceSlug(title: string): string {
  const slug = title
    .normalize("NFKD")
    .replace(SAFE_SEGMENT, "-")
    .replace(/-{2,}/g, "-")
    .replace(/^-+|-+$/g, "")
    .toLowerCase();
  if (!slug) {
    throw new Error(`workspace title produced an empty slug: ${JSON.stringify(title)}`);
  }
  return slug;
}
```

`replace` runs after `normalize`, so the string is ASCII `[A-Za-z0-9_-]` before `toLowerCase`, and lowercasing ASCII stays within `[a-z0-9_-]`. `.` is outside the alphabet, so `..` cannot appear. `safeSegment` (`paths.ts:52-58`) is the same pipeline without `toLowerCase`.

Executed: 200,019 inputs (19 crafted, plus 200,000 random code points up to U+2FFFF) through both functions, with each output checked against `^[a-z0-9_-]+$` / `^[A-Za-z0-9_-]+$` and for `..`. The result was 0 violations, and every throw carried the "empty" message. Crafted inputs: `..`, `．．`, `／`, `＼`, `‥`, `\u0000`, `...` and `. .` all throw. `../etc/passwd` becomes `etc-passwd`, `a\u0000b` becomes `a-b`, and `Ⅻ` becomes `xii`. Built paths: `sourcePath("../x","../../y","../z")` gives `workspaces/x/sources/y.z`, and `customTypePath("s","..\\..\\q")` gives `workspaces/s/custom-types/q.json`.

Provenance: command `timeout 120 node --experimental-strip-types --no-warnings probe-s2-s5-s7.mjs`, cwd `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs`, exit 0, 2026-11-20T02:03:38Z.

**Evidence:** `app/lib/corpus/paths.ts:24-64`, `app/lib/corpus/paths.ts:72-110`, `app/lib/corpus/storeAdapter.ts:55`, `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/s2-s5-s7.log`

---

## Claim 31: "The corpus-backed path passes persisted state through the same `merge` → `coercePersistedState` validation as the localStorage path, because `createJSONStorage(resolveWorkspaceStorage)` is the only storage wired and `merge` is substrate-agnostic."

**Submitted by:** security-reviewer
**Location:** `app/lib/stores/workspaceStore.ts:493-545`, `app/lib/stores/workspaceStore.ts:66-120`
**Type:** Error-handling / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** Security rubric row. The validation of state read from the corpus blob is identical to the localStorage path, and non-JSON from the async `getItem` is rejected before `merge`. The adjacent `onRehydrateStorage` v2-migration check does not follow the substrate (see the Escalate line).
**Scope:** Covers the blob read through the corpus-backed `getItem` → `createJSONStorage` parse → `merge` → `coercePersistedState`, including how zustand 5.0.13 handles an async `getItem` that returns non-JSON (the residue the critic left open). Does not establish that every state entering the store on rehydrate goes through `coercePersistedState`. The `onRehydrateStorage` callback (`:528-543`) decides v2 migration by reading `localStorage.getItem("workspace-zustand-v1")` whatever the storage. With the flag on and a legacy `workspace-v2` key present, it therefore runs `migrateFromV2()` after every hydrate, which `setState`s `loadWorkspace()` data (validated by `loadWorkspace`, not `coercePersistedState`) over the corpus-hydrated state.

There is one storage, and `merge` does not depend on which substrate it reads from:

```ts
// app/lib/stores/workspaceStore.ts:499, 503-506
storage: createJSONStorage(resolveWorkspaceStorage),
...
merge: (persisted, current) => ({
  ...current,
  ...(isObject(persisted) ? coercePersistedState(persisted as Record<string, unknown>) : {}),
}),
```

zustand parses an async `getItem` result inside a `.then`, so a parse failure becomes a rejection. persist routes it to `.catch`, which calls `postRehydrationCallback(void 0, e)` and never reaches `merge` (`middleware.mjs:294-296`: `if (str instanceof Promise) { return str.then(parse); }`).

The callback that breaks the same-path assumption:

```ts
// app/lib/stores/workspaceStore.ts:528-543 (enclosing onRehydrateStorage; read in full)
onRehydrateStorage: () => {
  return (_state, error) => {
    if (error) return;
    if (typeof window !== "undefined" && localStorage.getItem(WORKSPACE_KEY)) {
      const zustandRaw = localStorage.getItem("workspace-zustand-v1");
      let hasZustandData = false;
      try { hasZustandData = !!(zustandRaw && JSON.parse(zustandRaw)?.state?.sourceText); }
      catch { /* corrupted localStorage — proceed with migration */ }
      if (!hasZustandData) {
        migrateFromV2();
      }
    }
  };
},
```

`migrateFromV2` (`:251-281`) calls `useWorkspaceStore.setState({ sourceText: old.sourceText, ... })` with the output of `loadWorkspace()`. (paraphrased — no quote available because the effect on flag-on users combines this callback with the corpus storage choice made in `storeAdapter.ts:71-76`, and was not executed against the full store.)

Executed (zustand 5.0.13 persist with the real `createCorpusBackedStorage` over the in-memory fake):
- A valid blob `{state:{text:"from-corpus",evil:1}}` reached `merge` exactly once with the parsed state.
- The non-JSON blob `{ not json` produced 0 `merge` calls. `rehydrate()` resolved rather than rejecting, `onRehydrateStorage` received `SyntaxError`, state stayed at its defaults, and `hasHydrated()` was `false`. That is the same handling as a synchronous parse throw on the localStorage path.
- A non-object `state:"str"` reached `merge`, where the real `isObject` guard discards it.

Provenance: command `timeout 30 node --experimental-strip-types --no-warnings probe-s1-s6-zustand.mjs`, cwd `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs`, exit 0, 2026-11-20T02:03:02Z. The probe used a stand-in `merge` spy rather than the store's `coercePersistedState`, whose identity across substrates is established statically above.

**Evidence:** `app/lib/stores/workspaceStore.ts:66-120`, `app/lib/stores/workspaceStore.ts:251-281`, `app/lib/stores/workspaceStore.ts:495-545`, `app/lib/corpus/storeAdapter.ts:52-76`, `node_modules/zustand/esm/middleware.mjs:278-304`, `node_modules/zustand/esm/middleware.mjs:383-431`, `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/s1-s6.log`

---

## Claim 32: "`getRoot()` throws a typed `{kind:\"unavailable\"}` CorpusError when `navigator.storage.getDirectory` is absent, and every method's outer `catch` passes it through `wrap()` unchanged."

**Submitted by:** security-reviewer
**Location:** `app/lib/corpus/opfsAdapter.ts:49-55`, `app/lib/corpus/opfsAdapter.ts:79-83`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** Security / error-model rubric row. All five methods reject with typed `unavailable` when OPFS is absent, and with typed `io` when `getDirectory()` is present but throws. No raw TypeError escapes.
**Scope:** Covers all five methods under four absent shapes (no `navigator`, no `storage`, no `getDirectory`, non-function `getDirectory`) and under a present-but-throwing `getDirectory` (TypeError, SecurityError), which maps to `io` as the critic noted. Does not establish behaviour against a real browser's OPFS, and does not establish that the S3 worker proxy will keep `instanceof` across the boundary.

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

```ts
// app/lib/corpus/opfsAdapter.ts:79-83
function wrap(path: string, e: unknown): never {
  if (e instanceof CorpusError) throw e;
  if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
  throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });
}
```

Each of `readFile`, `writeFile`, `readdir`, `rm` and `stat` calls `const root = await getRoot();` as the first statement inside a `try` whose `catch (e) { wrap(path, e); }` closes the method (`opfsAdapter.ts:86-175`, each method read in full).

Executed: all four absent shapes gave `unavailable` for all five methods. The throwing `getDirectory` (TypeError, and DOMException SecurityError) gave `io` for all five.

Provenance: command `timeout 120 node --experimental-strip-types --no-warnings probe-s2-s5-s7.mjs`, cwd `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs`, exit 0, 2026-11-20T02:03:38Z.

**Evidence:** `app/lib/corpus/opfsAdapter.ts:42-55`, `app/lib/corpus/opfsAdapter.ts:79-176`, `/workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/stage25-logs/s2-s5-s7.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 27** (`app/lib/corpus/types.ts:69-71`): the round trip is lossless for `detail`, `message`, `name` and the class, but drops `stack` and `cause`.
- **Claim 28** (`app/lib/corpus/opfsAdapter.ts:57-62`): the not-found contract is uniform only for paths that have a file component. For `""` and `"/"`, OPFS `readFile`/`stat`/`rm` throw `io`, while the fake returns `null` or a no-op.
- **Claim 29** (`app/lib/stores/workspaceStore.ts:25,499`): the exported surface is identical, but the diff also adds an import and removes a private helper. With the flag on, hydration and `set()` become Promise-returning.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to the output path below, with `Commit: 2dc403e` as its first line and a `## Submitted Claims` section verdicting each listed claim.
- Answered: yes. All 7 submitted claims (S1-S7, numbered 26-32) are verdicted, 6 of them executed.
- Out of scope: harvesting new claims from the diff (Stage 1 did that); performance cost per keystroke in the real app; real-browser OPFS behaviour.
- Escalate: (1) `workspaceStore.ts:528-543`: with the corpus flag on, the v2-migration check reads localStorage instead of the active storage. A lingering `workspace-v2` key therefore makes `migrateFromV2()` overwrite the corpus-hydrated state on every load. This is a candidate finding for the security or correctness critics, surfaced under Claim 31's scope. (2) The corpus-backed `setItem` (`storeAdapter.ts:61-63`) is un-debounced, so every `set()` issues an un-serialized OPFS write. This is for the performance critic, surfaced under Claim 26.
