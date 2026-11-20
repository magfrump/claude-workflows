Commit: 2dc403e

# API Consistency Review: meta-formalism-copilot dc6dfb0..2dc403e (`-- app/`, partial scope)

**Scope:** `git diff dc6dfb0..2dc403e -- app/`, 15 files (partial scope; the branch's docs/spikes/working files are context only)
**Date:** 2026-11-19
**Based on:** Stage-1 merged code-fact-check report (`code-fact-check-report.md`, k=3), which this review uses as its source for documented behavior. Escalation E2 is addressed below (F1).

## Baseline Conventions

I surveyed `app/lib/types/{persistence,artifactStore,session,customArtifact,decomposition}.ts`, `app/lib/utils/workspacePersistence.ts`, `app/lib/stores/{workspaceStore,evidenceStore}.ts`, `app/lib/llm/callLlm.ts` and `docs/decisions/009-artifact-corpus-architecture.md`.

- **Type declarations.** Mostly `export type X = { ... }`: 125 type-literal aliases under `app/` outside `corpus/`, against 5 `interface`s (`CustomArtifactTypeDefinition`, plus the store `WorkspaceState`/`WorkspaceActions`/`EvidenceState`/`EvidenceActions`).
- **Acronyms in identifiers** use camel case: `LlmUsage`, `LlmCallUsage`, `streamLlm`, `transformSseStream`, `isPdfTexCompiled`, `PanelId`.
- **Domain typing.** Artifact types are the `ArtifactType` union (`session.ts:21`). Custom ids are the template literal `CustomArtifactTypeId` (`customArtifact.ts:11`). The current-version pointer is `currentVersionIndex`, 0-based (`artifactStore.ts:23-27`). Sources are `{ sourceId, sourceLabel, text }` (`decomposition.ts:52-56`).
- **Persisted-blob codecs** (`workspacePersistence.ts`) are lenient by design: `filter(isObject)` plus per-field defaults, returning `null` on bad input. There is one strict gate: a version mismatch returns `null` (`:206`).
- **Errors.** Domain error classes subclass `Error` and set `name` (`OpenRouterError`, `callLlm.ts:18-27`). Persistence failures are swallowed with `console.warn` (both debounced adapters).
- **Storage keys** are kebab-case, mostly versioned (`workspace-v2`, `workspace-zustand-v1`, `evidence-store-v1`, `workspace-sessions-v1`). Both persisted zustand stores use a 300 ms debounced localStorage adapter.
- **Corpus layout contract:** DD-009 §Folder layout (`009-artifact-corpus-architecture.md:40-63`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `CorpusFS` | type | `LlmUsage`, `PanelId`, `LlmCallUsage` | `app/lib/types/analytics.ts:18`, `app/lib/types/panels.ts:3`, `app/lib/llm/callLlm.ts:29` | Inconsistent: all-caps acronym; the repo (and this diff's own `createOpfsCorpusFs`) camel-cases acronyms (F6) |
| `createOpfsCorpusFs`, `createInMemoryCorpusFs` | function | `makeAnthropicClient`, `streamLlm` | `app/lib/llm/callLlm.ts:14` | Consistent on acronyms; `create*` factory prefix is fine (zustand `create`/`createJSONStorage`) |
| `CorpusError` | class | `OpenRouterError` | `app/lib/llm/callLlm.ts:18-27` | Consistent: `Error` subclass that sets `name` |
| `CorpusErrorKind` | type | `SessionScope` (discriminated on `type`) | `app/lib/types/session.ts:4-6` | Minor: names the detail union, not the `kind` discriminant (F11) |
| `CorpusWorkerError`, `toWorkerError`, `isCorpusWorkerError` | type/functions | `isCustomType`, `isValidCustomTypeDef` | `app/lib/types/customArtifact.ts:33`, `app/lib/utils/workspacePersistence.ts:121` | Consistent: `is*` guard naming |
| `CorpusStat`, `CorpusSubstrate` | type | n/a, first of kind | none (searched `app/lib/**` for stat/substrate types) | New category |
| `readFile`/`writeFile`/`readdir`/`rm`/`stat` | methods | Node `fs` names; no in-repo FS seam | none (searched `app/lib/**`) | New category; following Node is a reasonable deliberate choice |
| `ArtifactPointer.currentVersion` | field | `ArtifactRecord.currentVersionIndex` | `app/lib/types/artifactStore.ts:23-27` | Inconsistent: different base and name for the same concept, untyped `type` (F4) |
| `SourceRef { id, label, ext }` | type/fields | `SourceDocument { sourceId, sourceLabel, text }` | `app/lib/types/decomposition.ts:52-56` | Minor: field names diverge from the existing source shape (F5) |
| `WorkspaceManifest.manifestVersion`, `MANIFEST_VERSION` | field/const | `PersistedWorkspace.version`, `WORKSPACE_VERSION` | `app/lib/types/persistence.ts:4,18` | Constant consistent; field is prefixed where the precedent is bare `version` (Informational, folded into F1's version-gate point) |
| `customTypeIds: string[]` | field | `CustomArtifactTypeId` | `app/lib/types/customArtifact.ts:11` | Inconsistent: drops the template-literal id type (F4) |
| `workspaceSlug`, `safeSegment`, `*Path`/`*Dir` builders | functions | n/a, first path builders | none (searched `app/lib/**` for path builders) | New category; internally consistent `<thing>Path`/`<thing>Dir` |
| `SETTINGS_PATH` | const | `WORKSPACE_KEY`, `WORKSPACE_SESSIONS_KEY` | `app/lib/types/persistence.ts:5`, `app/lib/types/workspaceSession.ts:4` | Consistent: SCREAMING_SNAKE consts |
| `CORPUS_FLAG_KEY = "corpus-fs-enabled"` | const/storage key | `WORKSPACE_KEY = "workspace-v2"`, `STORAGE_KEY = "metaformalism-sessions"` | `app/lib/types/persistence.ts:5`, `app/hooks/useFormalizationSessions.ts:10` | Consistent: kebab-case key; unversioned is fine for a boolean flag |
| `NEXT_PUBLIC_CORPUS_FS` | env flag | n/a | none (searched `app/**` for `NEXT_PUBLIC_`) | New category: first public env flag, so the convention is being set here |
| `isCorpusEnabled` | function | `isCustomType`, `isLatexStructured` | `app/lib/types/customArtifact.ts:33`, `app/lib/utils/latexParser.ts:60` | Consistent |
| `createDebouncedLocalStorage`, `createCorpusBackedStorage`, `resolveWorkspaceStorage` | functions | `createDebouncedStorage` (evidence) | `app/lib/stores/evidenceStore.ts:20` | Consistent on naming; the sibling copy was not moved (F9) |
| `defineCorpusFsContract` | test helper | n/a | none (searched `app/**/__tests__/`) | New category |

## Findings

#### F1. `parseManifest` is strict for some malformations and lenient for others, and skips the version gate the existing codec has (E2)

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:84-114`
**Move:** 4 (error consistency), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`manifest.ts:84,87-88,102-103,109`):
```ts
  if (typeof raw.manifestVersion !== "number") fail("missing required field: manifestVersion");
    ? raw.sources.filter(isObject).map((s) => {
        if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");
    ? raw.customTypeIds.filter((x): x is string => typeof x === "string")
    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
```
(excerpt; enclosing `parseManifest` runs from `:74` to `:115`, all read.)

The codec treats similar malformations differently:
- A source object missing `id` throws, but a source entry that is not an object (`"x"`, `null`) is silently dropped.
- A non-string `customTypeIds` element is silently dropped.
- A missing timestamp becomes "now".
- `manifestVersion` is checked for type but never compared to `MANIFEST_VERSION`.

Those lenient branches come from the repo's lenient-coercion idiom (`workspacePersistence.ts` `coerceDecomposition`/`loadWorkspace`, which `filter(isObject)` and default). The file's contract (`:10-14`) promises the opposite. The existing codec also does have a strict gate, `if (parsed.version !== WORKSPACE_VERSION) return null;` (`workspacePersistence.ts:206`), which this one lacks. So a v2 manifest read by v1 code parses "successfully".

The tests (`manifest.test.ts:236-241`) cover only the object-missing-id path. That last case also asserts by message regex (`/source entry missing/`) even though the sibling test says to "assert on the typed detail, not a string match" (`:227`).

**Recommendation:** Choose one policy per field and apply it to every malformation of that field. Under the documented fail-loud contract, replace each `filter(...)` with a per-element check that calls `fail`. Gate `manifestVersion > MANIFEST_VERSION` with a typed error, and either require the timestamps or document the defaulting. Add one test per branch.

#### F2. Path builders throw plain `Error` inside a module whose stated error model is `CorpusError`

**Severity:** Inconsistent
**Location:** `app/lib/corpus/paths.ts:43-45`, `:53-56` (safeSegment), `:89-91`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`paths.ts:44`, `:90`; `opfsAdapter.ts:60`):
```ts
    throw new Error(`workspace title produced an empty slug: ${JSON.stringify(title)}`);
    throw new Error(`artifact version must be a positive integer, got ${version}`);
  if (!name) throw new CorpusError({ kind: "io", path, reason: "path has no file component" });
```

`types.ts:25-28` declares `CorpusErrorKind` "one source of truth" for corpus failures, and the adapter turns an invalid path into `CorpusError{kind:"io"}`. The path builders, the other source of invalid paths, throw untyped `Error`. A consumer that handles corpus failures with `if (e instanceof CorpusError) switch (e.detail.kind)` (the exhaustive-switch pattern `types.ts:36-40` mandates) misses empty slugs and bad versions entirely. The same thing, an unusable path, ends up with two error shapes depending on which layer catches it.

**Recommendation:** Throw `CorpusError({kind:"io", path:<input>, reason})`, or add an explicit `invalid-path` kind to the union, from `workspaceSlug`, `safeSegment` and `artifactVersionPath`. Update `paths.test.ts` to assert on `detail.kind`.

#### F3. `artifactDir` puts custom-type artifacts somewhere other than the DD-009 layout, while the tests claim layout conformance

**Severity:** Inconsistent
**Location:** `app/lib/corpus/paths.ts:82-84`; test `app/lib/corpus/__tests__/paths.test.ts:382-403`
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Precedent: custom-type artifacts nest under `artifacts/custom/<custom-type-id>/` in `docs/decisions/009-artifact-corpus-architecture.md:56-57`

Evidence (`paths.ts:82-84`; DD-009 `:56-57`):
```ts
export function artifactDir(slug: string, artifactType: string): string {
  return `${workspaceDir(slug)}/artifacts/${safeSegment(artifactType)}`;
}
```
```
│       │   └── custom/
│       │       └── <custom-type-id>/...
```

For `artifactType = "custom-abc"` the builder returns `artifacts/custom-abc/`, a sibling of the built-in types. DD-009 nests it under `artifacts/custom/`. The `describe("path builders match DD-009 folder layout")` block exercises only built-in types, so the mismatch goes untested. S4 and external git tooling bind to the folder layout, so the shape is a contract. Fixing it after S4 writes files means a data migration.

**Recommendation:** Branch on `isCustomType(artifactType)` (`customArtifact.ts:33`) and emit `artifacts/custom/<id>/`, or amend DD-009 if the flat shape is intended. Either way, add a custom-type case to the layout test.

#### F4. Manifest pointer types drop the repo's domain types and redefine the current-version pointer under a different name and base

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:20-25`, `:41`
**Move:** 2 (naming), 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `currentVersionIndex: number; // pointer into versions[]` (0-based) used in `app/lib/types/artifactStore.ts:23-27`; `type: ArtifactType` used in `app/lib/types/session.ts:21-24`; `CustomArtifactTypeId` used in `app/lib/types/customArtifact.ts:11`

Evidence (`manifest.ts:22-25`, `:41`):
```ts
export interface ArtifactPointer {
  type: string;
  currentVersion: number;
}
  customTypeIds: string[];
```

The store records the current version as a 0-based `currentVersionIndex`. The manifest records the same fact as a 1-based `currentVersion`. The S4 migration has to convert between them, and the different names don't make the base difference obvious (the base is only in a doc comment). `type: string` and `customTypeIds: string[]` also drop the `ArtifactType`/`CustomArtifactTypeId` types every other artifact surface uses, so a typo'd type or a non-`custom-` id type-checks.

**Recommendation:** Type the fields as `ArtifactType` and `CustomArtifactTypeId[]`, validated with `isCustomType` in `parseManifest`. Keep `currentVersion` if 1-based is deliberate (it matches the `v0001` filenames), but say in the `ArtifactPointer` doc comment that it equals `currentVersionIndex + 1`.

#### F5. `SourceRef` field names diverge from the existing source shape

**Severity:** Minor
**Location:** `app/lib/corpus/manifest.ts:27-32`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `sourceId` / `sourceLabel` used in `app/lib/types/decomposition.ts:52-56` and `app/lib/utils/workspacePersistence.ts` (`coerceDecomposition`)

Evidence (`manifest.ts:27-29`; `decomposition.ts:52-54`):
```ts
export interface SourceRef {
  id: string;
  label: string;
export type SourceDocument = {
  sourceId: string;
  sourceLabel: string;
```

The manifest's source entry uses `id`/`label`, while the in-app source record, which S4 will map onto it, uses `sourceId`/`sourceLabel`. Nothing consumes it yet, but once the on-disk format ships the names are frozen.

**Recommendation:** Rename to `sourceId`/`sourceLabel` before any manifest is written to disk, or record the deliberate divergence in DD-009.

#### F6. `CorpusFS` all-caps acronym against camel-case acronyms elsewhere, and within this diff

**Severity:** Minor
**Location:** `app/lib/corpus/types.ts:112`
**Move:** 2 (naming)
**Confidence:** High
**Legibility-target:** for-author

Precedent: camel-case acronyms used in `app/lib/types/analytics.ts:18` (`LlmUsage`), `app/lib/llm/callLlm.ts:29` (`LlmCallUsage`), `app/lib/llm/transformSseStream.ts:15`, and in this diff's `app/lib/corpus/opfsAdapter.ts` (`createOpfsCorpusFs`)

Evidence (`types.ts:112`; `opfsAdapter.ts`):
```ts
export interface CorpusFS {
export function createOpfsCorpusFs(): CorpusFS {
```

The type is `CorpusFS`, but its factories, test file (`corpusFs.contract.test.ts`) and helper (`defineCorpusFsContract`) all spell it `CorpusFs`. Consumers have to remember which casing goes with which kind of name. Later seams that are meant to sit beside it (`CorpusGit`) follow the camel form.

**Recommendation:** Rename to `CorpusFs` now, while the only importers are in this diff.

#### F7. `interface` declarations against the repo's predominant `type` aliases

**Severity:** Informational
**Location:** `app/lib/corpus/types.ts:102,112`; `app/lib/corpus/manifest.ts:22,27,34`
**Move:** 2 (naming/declaration style)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `export type X = { ... }` used in `app/lib/types/*.ts` (125 aliases under `app/`), with `interface` used in `app/lib/types/customArtifact.ts:13` and `app/lib/stores/*.ts`

Evidence (`manifest.ts:34`):
```ts
export interface WorkspaceManifest {
```

The repo mixes both styles, so this is not a violation. But the data shapes nearest to the manifest (`PersistedWorkspace`, `ArtifactRecord`, `SourceDocument`) are all `type`. Interfaces are a defensible choice for `CorpusFS`, which is meant to be implemented. They are less obviously right for the manifest's plain data records.

**Recommendation:** Optional: use `type` for the manifest records to match `persistence.ts`.

#### F8. The two storages returned by `resolveWorkspaceStorage` have opposite failure semantics, and nothing consumes the typed rejection

**Severity:** Inconsistent
**Location:** `app/lib/corpus/storeAdapter.ts:29-36` vs `:61-63`, `:71-76`
**Move:** 4 (error consistency), 7 (asymmetry)
**Confidence:** Medium (the claim about how zustand persist handles a rejected `setItem` could not be checked, since there is no `node_modules`; route: code-fact-check)
**Legibility-target:** for-author

Evidence (`storeAdapter.ts:32-36`, `:61-63`):
```ts
        try {
          localStorage.setItem(name, value);
        } catch (e) {
          console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
        }
    setItem: async (name, value) => {
      await fs.writeFile(pathFor(name), enc.encode(value));
    },
```
(excerpt; enclosing `createDebouncedLocalStorage` continues to `:46` and `createCorpusBackedStorage` to `:68`, both read.)

One resolver returns one `StateStorage` contract with two behaviors. The OFF path swallows quota with a warn. The ON path rejects with `CorpusError{quota-exceeded}`. The ON path also drops the 300 ms debounce, so it does one OPFS write per `set()`. That last point is a contract asymmetry; the cost belongs to performance-reviewer. As far as I know, zustand v5's persist fires `setItem` without awaiting or catching it. If so, the "reified, not swallowed" quota error (`opfsAdapter.ts:12-14`) turns into an unhandled promise rejection that no UI can switch on, which is effectively swallowed by a different route.

**Recommendation:** Pick one failure contract for the seam and document it on `resolveWorkspaceStorage`, for example: the storage catches and routes `CorpusError` to a single reporter or store field. Either debounce the corpus path too, or document that it isn't debounced.

#### F9. The sibling persisted store and the store's own rehydrate hook bypass the new seam

**Severity:** Inconsistent
**Location:** `app/lib/stores/evidenceStore.ts:8-9,20-48,116-119`; `app/lib/stores/workspaceStore.ts:533-534`
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`evidenceStore.ts:8-9`; `workspaceStore.ts:534`):
```ts
 * Persists to localStorage with the same debounced write pattern as
 * workspaceStore to avoid excessive serialization.
            const zustandRaw = localStorage.getItem("workspace-zustand-v1");
```
(excerpt; enclosing `onRehydrateStorage` callback runs `:529-543`, read.)

`evidenceStore` still holds its own copy of the debounced adapter, which the diff moved out of `workspaceStore`. Its docstring now points at a pattern that has moved. With the flag on, evidence stays in localStorage while the workspace moves to OPFS, which breaks DD-009's motive of keeping categories of data from drifting apart (`009:16`). Separately, `onRehydrateStorage` reads the persist key straight from localStorage. Under the flag that key is always empty, so the "has zustand data" check always fails (cross-ref Stage-1 E4/Claim 14, routed to architecture-review). The persist key `"workspace-zustand-v1"` also stays a string literal in three places (`workspaceStore.ts:495`, `:534`, and through `pathFor` in `storeAdapter.ts:55`) rather than a constant like `WORKSPACE_KEY`.

**Recommendation:** Hoist the persist key to a constant next to `WORKSPACE_KEY`. Make the rehydrate check use the persist API's own result (the `_state` argument) instead of reading localStorage. Either route `evidenceStore` through `resolveWorkspaceStorage`, or state in `flag.ts` that evidence is out of scope for S1.

#### F10. The corpus-backed storage hand-builds a path outside the "only source of corpus paths"

**Severity:** Minor
**Location:** `app/lib/corpus/storeAdapter.ts:55`
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`storeAdapter.ts:55`):
```ts
  const pathFor = (name: string) => `state/${name}.json`;
```

`paths.ts:16-19` says callers "must never hand-concatenate" corpus paths. The diff's one production path writer does exactly that, with no `safeSegment` on `name`, under a `state/` directory that DD-009 §Folder layout doesn't list (Stage-1 Claim 6 confirms). Today `name` is a constant, so the risk is to the convention more than to safety.

**Recommendation:** Add `persistBlobPath(name)` (and `state/`) to `paths.ts` and to DD-009, or remove the "only source" claim.

#### F11. Error-kind union: a `not-found` kind contradicts the null contract, and the union's name is off by one level

**Severity:** Minor
**Location:** `app/lib/corpus/types.ts:41-49`; `app/lib/corpus/manifest.ts:12`
**Move:** 2 (naming), 8 (nullability)
**Confidence:** High
**Legibility-target:** for-author

Precedent: discriminated unions are named for the whole value, e.g. `SessionScope` (discriminant `type`), in `app/lib/types/session.ts:4-6`

Evidence (`types.ts:41-42`, `:48`):
```ts
export type CorpusErrorKind =
  | { kind: "not-found"; path: string }
  | { kind: "browser-storage-cleared" }
```

The `CorpusFS` doc (`types.ts:17-18`) says not-found is `null`/`[]` and never a rejection. Yet `not-found` is a kind every exhaustive switch must handle, and nothing produces it. Nothing produces `browser-storage-cleared` either, though the manifest doc names it as a parse outcome (Stage-1 Claim 4). Consumers will write dead branches and may expect a rejection that never comes. The union is also called `...Kind` while it is stored as `.detail` and discriminated by `.kind`, so `detail.kind: CorpusErrorKind["kind"]` reads awkwardly.

**Recommendation:** Rename to `CorpusErrorDetail`. Either drop `not-found` or document which future API rejects with it, and fix the manifest doc's kind list.

#### F12. `io.path` has two meanings, and `parseManifest` accepts `null` only to reject it

**Severity:** Informational
**Location:** `app/lib/corpus/manifest.ts:64-66,74-75`
**Move:** 7 (asymmetry), 8 (nullability)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`manifest.ts:66`; `opfsAdapter.ts:82`):
```ts
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
  throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });
```

From the adapter, `io.path` is the full corpus-relative path. From the codec, it is the bare literal `workspace.json`, which can't tell one workspace from another. Separately, the `Uint8Array | null` signature invites passing `readFile`'s result straight in, yet `null` always throws `io`, so an absent file and a corrupt file are indistinguishable by kind.

**Recommendation:** Take the manifest path as a parameter (or have callers rethrow with it). Consider narrowing the signature to `Uint8Array` so callers must handle absence explicitly, the way `CorpusFS`'s own null contract expects.

## What Looks Good

- `CorpusError` follows the existing `OpenRouterError` pattern (an `Error` subclass that sets `name`). The `CorpusWorkerError`/`isCorpusWorkerError` pair follows the repo's `is*` type-guard naming. Route: code-fact-check, to confirm `toWorkerError`/`new CorpusError(detail, message)` round-trips losslessly.
- The `CorpusFS` method set has an explicit, uniform not-found contract (`null`/`[]`, idempotent `rm`), and the in-memory fake and OPFS adapter expose identical signatures. Route: code-fact-check, since behavioral parity is disputed by Stage-1 Claim 1 (name-clash and rm-of-directory differences) and is not endorsed here.
- The path builders use one consistent `<thing>Path`/`<thing>Dir` vocabulary and take `slug` first in every builder.
- The flag key and constants follow the repo's kebab-key and SCREAMING_SNAKE conventions.
- Store consumers see no API change: `useWorkspaceStore`'s exported surface is untouched, and only the `storage:` line changed. Route: code-fact-check (Stage-1 Claim 18 already verifies this with the flag-read caveat).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Manifest codec mixes strict/lenient, no version gate (E2) | Inconsistent | `app/lib/corpus/manifest.ts:84-114` | High |
| F2 | Path builders throw plain `Error`, not `CorpusError` | Inconsistent | `app/lib/corpus/paths.ts:43-45,89-91` | High |
| F3 | Custom-type artifact dir deviates from DD-009 layout | Inconsistent | `app/lib/corpus/paths.ts:82-84` | High |
| F9 | evidenceStore and rehydrate hook bypass the seam | Inconsistent | `app/lib/stores/evidenceStore.ts:20-48`, `workspaceStore.ts:533-534` | High |
| F4 | `ArtifactPointer`/`customTypeIds` drop domain types; 1-based vs 0-based pointer | Inconsistent | `app/lib/corpus/manifest.ts:20-25,41` | Medium |
| F8 | Two storages from one resolver: swallow vs unhandled reject; no debounce on ON path | Inconsistent | `app/lib/corpus/storeAdapter.ts:29-36,61-63` | Medium |
| F6 | `CorpusFS` acronym casing | Minor | `app/lib/corpus/types.ts:112` | High |
| F10 | Hand-built `state/` path outside paths.ts | Minor | `app/lib/corpus/storeAdapter.ts:55` | High |
| F11 | Dead `not-found` kind contradicts null contract; union misnamed | Minor | `app/lib/corpus/types.ts:41-49` | High |
| F5 | `SourceRef` id/label vs `sourceId`/`sourceLabel` | Minor | `app/lib/corpus/manifest.ts:27-32` | Medium |
| F12 | `io.path` double meaning; nullable input only to throw | Informational | `app/lib/corpus/manifest.ts:64-66,74-75` | High |
| F7 | `interface` vs predominant `type` aliases | Informational | `app/lib/corpus/manifest.ts:22,27,34` | Medium |

## Overall Assessment

No existing consumer breaks. The store's exported surface is unchanged, and every new name is additive and imported only within this diff. That makes now the cheap moment to fix the surface. The inconsistencies fall into two groups:

- **The new module doesn't follow its own stated contracts.** The codec claims fail-loud but is partly lenient (F1). The module claims one error model, but its path builders throw plain `Error` (F2). The tests claim DD-009 layout conformance, but custom artifacts land elsewhere (F3). `paths.ts` claims to be the only path source, but the store adapter hand-builds one (F10).
- **The new on-disk types drift from the repo's existing domain types** (F4, F5, F6). That drift hardens into a file format once S4 writes manifests.

Everything here can be fixed in place in a small follow-up. None of it suggests the author skipped surveying the codebase; the drift comes from the module being designed against DD-009 rather than against `app/lib/types/`. The highest consumer impact is F3 and F4, because they are frozen into on-disk data, and F9, because flag-on splits the stores the DD set out to unify.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: 2dc403e` as its first line, structured per the api-consistency-reviewer skill.
- Answered: yes
- Out of scope: Exploitability of the slug/segment sanitizers (security-reviewer). Per-write OPFS cost on the undebounced ON path (performance-reviewer). Module-boundary placement of the test helpers under `__tests__/` imported cross-module (architecture-review). These were set aside per the role split.
- Escalate: (1) F8 depends on zustand v5 persist not awaiting or catching `setItem` rejections, which I couldn't check without `node_modules`; needs a provisioned environment (joins E6). (2) F9's rehydrate-hook bypass overlaps E4; architecture-review owns the migrateFromV2 consequence. (3) F3 needs an owner call: fix `paths.ts` or amend DD-009.
- Decisions I made: E2 is treated as an API-consistency finding (F1), with the version-gate gap added from the `workspacePersistence.ts:206` precedent. F7 is rated Informational rather than Minor because the repo mixes `interface` and `type`.
