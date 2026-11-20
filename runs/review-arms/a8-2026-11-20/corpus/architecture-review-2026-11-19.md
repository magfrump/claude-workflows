Commit: 2dc403e

# Architecture Review — corpus S0+S1 (dc6dfb0..2dc403e, `app/` only)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` (15 files, partial scope; the docs/ files in the same range are context only)
**Date:** 2026-11-19
**Based on:** Stage-1 merged code-fact-check summary (k=3) in the shared block; `docs/reviews/architecture-review.md` (the plan-stage arch review this diff answers)

Trigger categories: module structure yes (new `app/lib/corpus/`), public APIs yes (`CorpusFS`, `CorpusError*`, path builders), data models yes (`workspace.json` manifest, `state/<name>.json` blob), cross-cutting yes (persist storage wiring in the store). Full review.

Trust-boundary cross-reference: `docs/reviews/security-review.md` exists (the reviewed repo has no `security-review-*.md`; this is the nearest file). Its map is numbered 1-4, not `B<n>`, and has no `Commit:` line. Boundary 4 ("Browser <-> localStorage") is the one the persistence seam sits on. Cited below as "boundary 4 from `docs/reviews/security-review.md` (Commit: unknown) — security review predates this diff; boundary may be stale" (it reviewed `feat/custom-artifact-types`, 2026-04-07).

## Dependency Map

- `app/lib/stores/workspaceStore.ts` -> `app/lib/corpus/storeAdapter.ts` (`resolveWorkspaceStorage`, zero-arg). That is the only production import of `app/lib/corpus/`.
- `storeAdapter.ts` -> `zustand/middleware` (type `StateStorage`), `./types` (`CorpusFS`), `./opfsAdapter` (concrete), `./flag`.
- `opfsAdapter.ts` -> `./types`. `manifest.ts` -> `./types`. `paths.ts` and `flag.ts` are leaves. `types.ts` has no imports.
- `paths.ts` and `manifest.ts` have no production importers (tests only), as S1 intends.
- Direction: inside `corpus/` it is correct. The concrete OPFS adapter and the codec depend on the `types.ts` abstraction, and nothing in `corpus/` imports from the store. The exception is `storeAdapter.ts`, which makes the corpus package depend on the store framework (zustand) and is also where the concrete adapter gets picked. The store still reads `localStorage` directly, outside the seam (finding 1).

## Findings

#### 1. The store reads localStorage directly on rehydrate, so the persistence seam is bypassed and flag-ON re-runs the v2 migration over corpus state (E4)

**Severity:** Structural
**Location:** `app/lib/stores/workspaceStore.ts:528-541`
**Move:** #1 (dependency direction), #3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```ts
      onRehydrateStorage: () => {
        return (_state, error) => {
          if (error) return;
          // If Zustand store was empty (no persisted data) but workspace-v2 exists,
          // migrate the old data. We check by looking for the old key.
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
(excerpt ends :541 on the closing of `onRehydrateStorage`. The enclosing `persist` options object continues to :543, `);`. Read in full.)

The diff swaps the store's storage substrate at :499, but the store's "is there persisted data?" check still goes straight to `localStorage`, and it ignores the `_state` the persist middleware actually rehydrated. With the flag on, the blob lives at `state/workspace-zustand-v1.json` in OPFS, so `zustandRaw` is always `null` and `hasZustandData` is always false. Whenever a `workspace-v2` key exists, `migrateFromV2()` (:251-285) calls `useWorkspaceStore.setState(...)` with the v2 data. That overwrites what was just rehydrated from the corpus, and the overwrite is then persisted back to the corpus. Nothing in `app/` ever removes `WORKSPACE_KEY` (`grep` shows writes only in `workspacePersistence.ts:25,109`), so this repeats on every reload. The structural cause is that the store depends on one concrete substrate (localStorage) for a decision that belongs to the abstraction it just introduced. "Pure substrate swap" (`storeAdapter.ts:12`) is false, and `flag.ts`'s "starts from an EMPTY corpus" is false whenever v2 data exists (fact-check claims 12 and 14). The localStorage read also means this decision sits on the localStorage trust boundary (boundary 4 from `docs/reviews/security-review.md`, Commit: unknown — security review predates this diff; boundary may be stale). S4 will own a real localStorage-to-corpus migration and will inherit two competing migration paths unless this is fixed first.

**Recommendation:** Decide "store was empty" from the rehydrated `_state` argument, or from a `hasPersistedData()` the storage seam exposes, not from `localStorage.getItem("workspace-zustand-v1")`. Alternatively, skip `migrateFromV2` when `isCorpusEnabled()` until S4 defines the migration. Add a flag-ON rehydrate test with a `workspace-v2` key present. G15 currently checks only that `getDirectory` was called.

#### 2. The injection seam is `StateStorage`, with the concrete OPFS adapter hard-wired, not the `CorpusFS` seam prior finding 3 asked for

**Severity:** Coupling
**Location:** `app/lib/corpus/storeAdapter.ts:5-8,70-76`; `app/lib/stores/workspaceStore.ts:496-499`
**Move:** #1 (dependency direction), #3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```ts
/** Selected once when the store's persist middleware initializes. */
export function resolveWorkspaceStorage(): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(createOpfsCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```
```ts
 * the dev flag is on. The injection seam is typed as `CorpusFS` (arch-review
 * finding 3) so the S3 worker-proxy implementation drops in here without the
```

The store binds to a zero-argument factory that returns zustand's `StateStorage`. `CorpusFS` is one layer below, and the choice of `createOpfsCorpusFs()` is fixed inside `corpus/`. The comments in both files say the seam is typed as `CorpusFS`. That is only true of `createCorpusBackedStorage(fs)`, which the store never calls (fact-check claim 11). In practice the S3 swap is still one line in `resolveWorkspaceStorage`, so the store would not need editing. The problems are that (a) there is no composition root through which a test or S3 can inject a `CorpusFS`: the G15 test has to monkey-patch `navigator.storage` to exercise the ON path, and (b) the recommended G14 assertion ("the store holds something typed as `CorpusFS`") was never added. The plan-stage finding is therefore closed in prose but not in code.

**Recommendation:** Give `resolveWorkspaceStorage` an optional `makeFs: () => CorpusFS` parameter defaulting to `createOpfsCorpusFs`, or move the selection into a small composition module the store imports. Correct the two comments so they describe the actual seam.

#### 3. Substitutability is asserted, not verified: OPFS never runs the contract suite, and the suite does not pin the cases where fake and OPFS diverge (E1)

**Severity:** Coupling
**Location:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-8`; `app/lib/corpus/__tests__/corpusFsContract.ts:4-7`; `app/lib/corpus/types.ts:112-125`
**Move:** #6 (substitutability)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```ts
defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());
```
```ts
 * Any `CorpusFS` implementation must pass this. Run against the in-memory fake
 * in CI (corpusFs.contract.test.ts) and against the real OPFS adapter via
 * out-of-CI Playwright (jsdom has no OPFS). Keeping the cases in one place means
 * the fake and the adapter are held to identical behavior (substitutability).
```
```ts
  /** Removes a file. Idempotent: resolves (no-op) if the path does not exist. */
  rm(path: string): Promise<void>;
```

The only `defineCorpusFsContract` caller passes the fake. The OPFS run is an unrun sketch (fact-check claim 1, 3/3). Every later sub-task (S2 FSA, S3 worker proxy, S4 layout) will be developed against the fake. The `CorpusFS` contract (`types.ts:112-125`) leaves the divergent cases unspecified, so the fake's behavior becomes the de facto spec:
- `rm` on a directory: Map no-op in the fake, `removeEntry` throws to `io` on a non-empty OPFS dir (`opfsAdapter.ts:146`).
- Writing `a/b` when `a` is a file: both coexist in the fake, `getDirectoryHandle` type-mismatch to `io` in OPFS (`opfsAdapter.ts:70`).
- Byte aliasing: the fake copies on write, OPFS does not.

Code that passes CI against the fake can fail on the real substrate. That is the LSP failure the shared suite was meant to prevent.

**Recommendation:** Specify these cases on the `CorpusFS` interface (for example, "rm of a directory rejects with io" and "a path segment that names a file rejects with io"), add matching contract cases, and make the fake match OPFS. Track the OPFS contract run as an explicit open item, and do not describe it as done in the docstrings and the f6361a3 body.

#### 4. `storeAdapter.ts` puts a zustand dependency and the legacy localStorage adapter inside `corpus/`

**Severity:** Minor
**Location:** `app/lib/corpus/storeAdapter.ts:15-18`
**Move:** #2 (responsibility boundaries), #1 (dependency direction)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```ts
import type { StateStorage } from "zustand/middleware";
import type { CorpusFS } from "./types";
import { createOpfsCorpusFs } from "./opfsAdapter";
import { isCorpusEnabled } from "./flag";
```

The plan-stage review praised `corpus/` as "a clean leaf with no inward app dependencies". This module adds three things to it: a dependency on the state-management framework, the legacy `createDebouncedLocalStorage` (which has nothing to do with the corpus), and flag-based selection. `corpus/` now changes for three reasons: corpus FS, the zustand API, and the legacy localStorage behavior. The `CorpusFS` package's public surface also now includes a localStorage adapter that S4 will delete.

**Recommendation:** Move the `StateStorage` adapters and the resolver to `app/lib/stores/` (for example `workspaceStorage.ts`). The store side then depends on `corpus/`, never the reverse.

#### 5. The `state/` blob path sits outside the documented layout and the "single choke point", leaving an undocumented on-disk contract for S4 to migrate

**Severity:** Minor
**Location:** `app/lib/corpus/storeAdapter.ts:55`; `app/lib/corpus/paths.ts:16-19`
**Move:** #3 (module boundary), data contracts
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```ts
  const pathFor = (name: string) => `state/${name}.json`;
```
```ts
 * slash), suitable for passing straight to a `CorpusFS`. The only source of
 * corpus paths is this module — callers must never hand-concatenate, so the
 * traversal guard in `workspaceSlug` is the single choke point that keeps
 * untrusted workspace titles inside `workspaces/`.
```

The only production corpus path is built by hand. It creates a `state/` sibling of `workspaces/` and `settings.json` that the DD-009 layout diagram in `paths.ts:3-14` does not include (fact-check claim 6). Today `name` is a constant, so this is not a traversal risk. Structurally, though, a persisted location now exists that the layout module does not own, and S4's migration and any S2 FSA mirror will have to discover it. Separately, `workspaceDir(slug)` (`paths.ts:70`) runs `workspaceSlug()` again on its argument, so it is unclear whether callers pass a title or a slug.

**Recommendation:** Add `STATE_DIR` and `stateBlobPath(name)` to `paths.ts` and use them from `storeAdapter.ts`, and add `state/` to the layout diagram. Name the `workspaceDir` parameter for what it accepts.

#### 6. The manifest data contract has no version gate, and its leniency contradicts the documented fail-loud contract (E2, structural angle)

**Severity:** Minor
**Location:** `app/lib/corpus/manifest.ts:84,87,94,103,107-110`
**Move:** #8 (extension points), data contracts
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```ts
  if (typeof raw.manifestVersion !== "number") fail("missing required field: manifestVersion");
```
```ts
    ? raw.sources.filter(isObject).map((s) => {
```
```ts
    ? raw.customTypeIds.filter((x): x is string => typeof x === "string")
```

`MANIFEST_VERSION` is exported, but `parseManifest` never compares the parsed version to it. A future v2 manifest would therefore be accepted as v1, so schema evolution, the extension point this persisted contract most needs, has no hook. The `.filter(isObject)` and string filters silently drop malformed entries, and the timestamps default to now. That contradicts the fail-loud contract in `manifest.ts:10-14` (fact-check claim 3, executed 3/3). The codec has no production callers yet, so the fix is cheap now and expensive once S4 writes manifests users depend on. The codec-behavior side of this belongs to api-consistency and test-strategy. The point here is the missing version dispatch.

**Recommendation:** Reject `manifestVersion > MANIFEST_VERSION` with a typed error, and dispatch on version, even when the only branch is v1. Replace the filters with per-entry `fail(...)` calls so the code matches its docstring.

#### 7. The error model has a `not-found` kind that the `CorpusFS` contract says never occurs, and typed errors have no consumer

**Severity:** Informational
**Location:** `app/lib/corpus/types.ts:17-18,42`
**Move:** #3 (module boundary), #7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```ts
 *  - "Not found" is `null` from `readFile`/`stat` and `[]` from `readdir`;
 *  everything else rejects with a `CorpusError`. Callers never see `undefined`.
```
```ts
  | { kind: "not-found"; path: string }
```

The union offers a second way to signal absence, one the interface forbids, and every exhaustive switch must handle it. Nothing outside `corpus/` imports `CorpusError`, `describeCorpusError` or `isCorpusWorkerError`. A `quota-exceeded` rejection from `createCorpusBackedStorage.setItem` therefore goes into zustand persist with no app-level handler, so the failure-reification contract (`opfsAdapter.ts:9-15`) currently ends without anything handling it. I did not verify zustand v5's handling of a rejected `setItem`, since `node_modules` is absent. That is acceptable for a dev-only S1, but the failure-driven-UI consumer (S5) is what gives the reified errors value.

**Recommendation:** Either remove `not-found` or document which operation produces it, for example a future strict `open()`. Record the missing error sink for S1's flag-ON path in `docs/thoughts/corpus-fs-seam.md`.

## What Looks Good

- **Plan-stage findings 1, 2 and 4 landed.** There is one `CorpusErrorKind` union shared by the thrown and worker-serialized forms, a substrate-neutral `quota-exceeded {substrate}`, an explicit "GIT IS NOT PART OF THIS INTERFACE" note keeping `CorpusFS` narrow (ISP), and the 30-small-files S4 access-pattern case in the contract suite.
- **`CorpusFS` is minimal, async and bytes-oriented.** The worker move remains a transport swap, and the five methods are all ones every implementor needs.
- **`types.ts` is a true leaf.** The adapters and the codec depend on it, never the reverse, and the exhaustive `assertNever` switch is a sound OCP extension point.
- **Local OPFS typings** isolate the adapter from lib.dom version drift.
- **The default-OFF path keeps the default seam behaviorally identical** (body moved verbatim), with a characterization test pinning the persisted shape.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Store bypasses seam via direct localStorage read; flag-ON re-runs v2 migration over corpus state | Structural | `app/lib/stores/workspaceStore.ts:528-541` | High |
| 2 | Seam is `StateStorage` with concrete OPFS hard-wired; "typed as CorpusFS" comments inaccurate | Coupling | `app/lib/corpus/storeAdapter.ts:5-8,70-76` | High |
| 3 | Contract suite never run on OPFS; divergent cases unspecified in `CorpusFS` | Coupling | `app/lib/corpus/__tests__/corpusFs.contract.test.ts:8`, `types.ts:112-125` | High |
| 4 | zustand dependency + legacy localStorage adapter live inside `corpus/` | Minor | `app/lib/corpus/storeAdapter.ts:15-18` | Medium |
| 5 | `state/` blob path outside layout module and diagram | Minor | `app/lib/corpus/storeAdapter.ts:55`, `paths.ts:16-19` | High |
| 6 | Manifest has no version gate; lenient filters contradict fail-loud contract | Minor | `app/lib/corpus/manifest.ts:84-110` | High |
| 7 | `not-found` kind contradicts null contract; typed errors have no consumer | Informational | `app/lib/corpus/types.ts:17-18,42` | Medium |

## Overall Assessment

Inside `app/lib/corpus/` the change improves structure. The abstraction is narrow, the dependency direction is correct, and the plan-stage contract findings were taken up. The weakness is where the store meets the seam. The store still makes a persistence decision by reading localStorage directly (finding 1), so the flag does not give a clean substrate swap: with v2 data present, flag-ON silently replays the legacy migration over corpus state on every reload. Separately, the seam the store binds to is not the `CorpusFS` seam the comments claim (finding 2), and fake-vs-OPFS substitutability is assumed rather than tested (finding 3). All of these can be fixed in place, and none calls for restructuring the corpus module. Finding 1 is the most important, because S4's migration design will inherit it.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: 2dc403e` as its first line, structured per the architecture-review skill.
- Answered: yes
- Out of scope: concurrency and ordering of un-debounced async OPFS writes (performance-reviewer), dev-only flag enforcement and env inlining (E3, security-reviewer), close()-masks-quota (E5), and manifest codec behavior beyond the version gate (E2, api-consistency and test-strategy). Build, lint and vitest were not run (no `node_modules`).
- Escalate: Finding 1 (E4 confirmed). Flag-ON rehydrate re-runs `migrateFromV2` over corpus state on every reload while `workspace-v2` exists, which is a correctness and data-integrity consequence for code-review synthesis and test-strategy (missing flag-ON rehydrate test). E1 confirmed as Coupling (finding 3). Unverified: whether zustand v5 persist surfaces a rejected async `setItem` as an unhandled rejection (finding 7). It needs a provisioned environment (E6).
- Decisions I made: I used `docs/reviews/security-review.md` (no `security-review-*.md` exists) for the trust-boundary cross-reference and labeled it stale. I rated finding 1 Structural rather than Coupling because the store, the core, depends on the concrete substrate for a decision that belongs behind the new abstraction, and that dependency causes the behavior bug.
