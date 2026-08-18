# API Consistency Review — mfc-corpus DD-009 corpus-architecture

**Commit:** 2dc403e
**Scope:** `git diff dc6dfb0...HEAD` — new `app/lib/corpus/*` module (`types.ts`, `manifest.ts`, `paths.ts`, `flag.ts`, `opfsAdapter.ts`, `storeAdapter.ts`) plus the `workspaceStore.ts` storage-seam swap. Consumer-facing surface: exported types/functions of the corpus module and the persisted `workspace.json` schema.
**Date:** 2026-08-18
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-corpus/code-fact-check-report.md` (its verdicts bind; behavior it documents is not re-verified here).

## Baseline Conventions

Surveyed the app's existing public vocabulary and persisted-schema conventions:

- **Custom-artifact-type vocabulary is fully qualified in the persisted/type surface.** The id type is `CustomArtifactTypeId` (`app/lib/types/customArtifact.ts:11`), the definition is `CustomArtifactTypeDefinition` (`:13`), and the persisted collection field is `customArtifactTypes` (`app/lib/types/persistence.ts:34`; `app/lib/stores/workspaceStore.ts:169,230,524`). Local *predicates* abbreviate to "CustomType" (`isCustomType`, `customArtifact.ts:33`; `isValidCustomTypeDef`, `app/lib/utils/workspacePersistence.ts:121`), but every persisted-schema field and every exported type carries the full `CustomArtifactType*` form.
- **Boolean predicates** use an `is<Noun><Adj>` prefix (`isCustomType`, `isValidCustomTypeDef`, `isLatexStructured`). The corpus module's `isCorpusEnabled`/`isCorpusWorkerError` match.
- **Storage factories** use a `create*` verb prefix (`createJSONStorage` from zustand, the deleted `createDebouncedStorage`). The corpus module's `createDebouncedLocalStorage`/`createCorpusBackedStorage`/`createOpfsCorpusFs` match.
- **Source vocabulary**: the app models a source as `SourceDocument` with a `sourceId` field (`app/lib/types/decomposition.ts:52-53`, `persistence.ts:12`).
- **Rehydration/persistence is coercion-heavy**: `sanitizeVerificationStatus`, `sanitizeNodeStatus`, `coerceDecomposition`, and the `rehydrateArtifactVersion` coercions (`workspaceStore.ts:40-48`) repair malformed persisted data rather than reject it. The corpus manifest codec deliberately breaks from this with a fail-loud stance (documented) — noted so its internal split (below) is judged against its own stated contract, not the app's coercion norm.
- **Path construction contract**: `paths.ts` states it is *the only* source of corpus paths ("callers must never hand-concatenate", `paths.ts:15-19`); the documented on-disk layout is `settings.json` + `workspaces/<slug>/...` (`paths.ts:4-14`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `WorkspaceManifest.customTypeIds` | field (persisted schema) | `customArtifactTypes` (persisted field); `CustomArtifactTypeId` (id type) | `app/lib/types/persistence.ts:34`, `app/lib/stores/workspaceStore.ts:169`, `app/lib/types/customArtifact.ts:11` | **Inconsistent** — persisted-schema fields use the full `customArtifactType*` form; this drops "Artifact" and types the ids as bare `string[]` not `CustomArtifactTypeId[]`. See Finding 1. |
| `state/<name>.json` | path (route/segment) | `workspaceDir`, `sourcePath`, `customTypePath`, `SETTINGS_PATH` | `app/lib/corpus/paths.ts:66-110` | **Inconsistent** — a new top-level corpus dir, hand-concatenated in `storeAdapter.ts`, absent from the `paths.ts` layout that claims to be the sole path source. See Finding 2. |
| `SourceRef` / `.id` | type / field | `SourceDocument` / `sourceId` | `app/lib/types/decomposition.ts:52-53` | Consistent (acceptable) — distinct concept (manifest index entry vs. full doc); bare `id` inside a `Source*` object is contextually clear. |
| `CorpusFS`, `CorpusError`, `CorpusErrorKind`, `CorpusSubstrate`, `CorpusStat`, `CorpusWorkerError` | types | `EvidenceStore`, `WorkspaceState`, `CustomArtifactTypeDefinition` (bare-noun PascalCase, no `I`/`DTO` suffixes) | `app/lib/stores/*`, `app/lib/types/*` | Consistent — `Corpus`-prefixed bare nouns, no Hungarian/suffix noise. |
| `isCorpusEnabled`, `isCorpusWorkerError` | functions (predicate) | `isCustomType`, `isValidCustomTypeDef`, `isLatexStructured` | `app/lib/types/customArtifact.ts:33`, `app/lib/utils/workspacePersistence.ts:121` | Consistent — `is*` boolean prefix. |
| `createDebouncedLocalStorage`, `createCorpusBackedStorage`, `createOpfsCorpusFs`, `resolveWorkspaceStorage` | functions (factory) | `createDebouncedStorage` (deleted), `createJSONStorage` | `app/lib/stores/workspaceStore.ts` (pre-diff), zustand | Consistent — `create*`/`resolve*` verb prefixes. |
| `parseManifest`, `serializeManifest`, `createManifest` | functions | `loadWorkspace`, `coerceDecomposition` | `app/lib/utils/workspacePersistence.ts` | Consistent — verb-noun. |
| path builders: `workspaceDir`, `workspaceManifestPath`, `sourcePath`, `artifactDir`, `artifactVersionPath`, `artifactMetaPath`, `customTypePath`, `decompositionDir`, `decompositionGraphLayoutPath` | functions | _(first path-builder module of its kind)_ | none — searched `app/lib/**` for `*Path`/`*Dir` builders | New category — internally consistent (`*Path` for files, `*Dir` for directories); note the convention being set. |
| `CORPUS_FLAG_KEY`, `MANIFEST_VERSION`, `SETTINGS_PATH`, `VERSION_PAD` | constants | `WORKSPACE_KEY`, `MANIFEST_VERSION` (n/a) | `app/lib/types/persistence.ts` (`WORKSPACE_KEY`) | Consistent — SCREAMING_SNAKE module constants. |

## Findings

### 1. `WorkspaceManifest.customTypeIds` drops the app-wide `customArtifactType*` qualifier

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:41` (also the `customTypeIds` handling at `:102-104,113`)
**Move:** #2 (naming against the grain), #7 (asymmetry on the S4 reconciliation path)
**Confidence:** High

Precedent: `customArtifactTypes` used in `app/lib/types/persistence.ts:34` and `app/lib/stores/workspaceStore.ts:169,230,524`; the id type `CustomArtifactTypeId` in `app/lib/types/customArtifact.ts:11`.

The persisted `WorkspaceManifest` names its custom-type collection `customTypeIds: string[]`. Everywhere else the app persists or types this concept it uses the fully-qualified form — the localStorage schema field is `customArtifactTypes`, and the id is the branded `CustomArtifactTypeId` (`` `custom-${string}` ``), not a bare `string`. The manifest is the S4 reconciliation target: on that path `manifest.customTypeIds` will be populated from the store's `customArtifactTypes[].id` (each a `CustomArtifactTypeId`), so a reader/migrator sits astride two names and two types for one concept and must remember the mapping and the widening from `CustomArtifactTypeId` to `string`. Note the precedent is mixed — the app's *predicates* already abbreviate (`isCustomType`, `isValidCustomTypeDef`) — but no persisted-schema field or exported type does; the closest neighbors to a persisted field are `customArtifactTypes`/`CustomArtifactTypeId`, and those set the convention this field should follow.

**Recommendation:** Rename the field to `customArtifactTypeIds` and type it `CustomArtifactTypeId[]` (importing the brand from `app/lib/types/customArtifact.ts`). If a bare `string[]` is intentional for forward-compat with non-artifact custom types, say so in the manifest docstring so the S4 mapping seam is deliberate rather than accidental drift.

### 2. `storeAdapter` hand-concatenates `state/<name>.json`, bypassing the `paths.ts` choke point

**Severity:** Inconsistent
**Location:** `app/lib/corpus/storeAdapter.ts:55` (`const pathFor = (name: string) => \`state/${name}.json\`;`)
**Move:** #1 (baseline: single-source-of-paths contract), #3 (consumer contract)
**Confidence:** High

`paths.ts:15-19` states the contract explicitly: "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point." `storeAdapter.createCorpusBackedStorage` violates this on two counts: (a) it builds the path by string interpolation instead of calling a `paths.ts` builder, and (b) it introduces a top-level `state/` directory that does not appear in the documented on-disk layout (`paths.ts:4-14`, which lists only `settings.json` and `workspaces/<slug>/...`). Exploit risk is low today because `name` is the static persist key `"workspace-zustand-v1"` (`workspaceStore.ts:495`), not an untrusted value — so this is a contract/consistency finding, not a live traversal bug — but it is exactly the hand-concatenation the module contract forbids, and it silently forks the folder-layout catalog so a future reader auditing "where can the corpus write?" from `paths.ts` will miss `state/` entirely. This is the same seam the fact-check flags as blob-mode storage (Claims 13–14); those verdicts stand — this finding is the path-construction-contract angle, not the behavior.

**Recommendation:** Add a `statePath(name)` builder (and a `state/` entry) to `paths.ts` and call it from `storeAdapter`, or, if `state/` is intentionally outside the corpus tree and outside the traversal guard's remit, amend the `paths.ts:15-19` contract to carve out that exception so "the only source of corpus paths" stays true.

### 3. Manifest codec splits field-defaulting policy without a stated rule

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:83-113`
**Move:** #7 (asymmetry), #8 (nullability/defaulting contract)
**Confidence:** Medium

Building on fact-check Claims 6 (Mostly accurate) and 7 (Incorrect) — I do not re-verify the behavior; the consistency concern is that `parseManifest` applies two contradictory field-handling policies with no documented boundary between them. Structural fields fail loud (`title`, `manifestVersion`, non-array `sources`/`artifacts`/`customTypeIds`, and per-entry `id`/`ext`, `type`/`currentVersion` all call `fail()`), while `createdAt`, `updatedAt`, and per-source `label` silently coerce to a fresh timestamp or to the source `id` (`:89,109-110`). Non-object source entries and non-string custom-type ids are silently dropped by pre-map filters (`:87,103`) rather than rejected. A consumer of this codec cannot predict from the type or the docstring which malformations surface as a `CorpusError` and which are repaired — the per-function docstring's "any malformation → throws" (`:69-70`) is the Incorrect claim precisely because of this split. Symptomatically this is a request/response-asymmetry analog: the same corruption class (a wrong-typed field) produces a throw for `title` but a silent default for `createdAt`.

**Recommendation:** Pick one policy per field *class* and document it on `parseManifest`: e.g., "identity/structure fields fail loud; timestamps and labels are best-effort defaulted." Then align the two docstrings (header `:10-14` and per-function `:69-73`) with that rule so the fail-loud contract the manifest advertises is the contract it enforces.

### 4. `not-found` error kind is dead relative to the null-return absence contract

**Severity:** Minor
**Location:** `app/lib/corpus/types.ts:42` (`not-found` kind) vs. the readFile/stat/readdir contract at `types.ts:17-18,113-124`; manifest absence handling at `manifest.ts:66,75`
**Move:** #7 (asymmetry — two ways to signal one condition)
**Confidence:** High

The `CorpusErrorKind` union declares `{ kind: "not-found"; path: string }`, but the `CorpusFS` contract signals absence by *returning* (`null` from `readFile`/`stat`, `[]` from `readdir`) and the OPFS adapter never throws `not-found` (`opfsAdapter.ts` maps not-found to `null`/`[]`/no-op). Manifest absence is likewise surfaced as `kind: "io"` with `path: "workspace.json"` (`manifest.ts:66`), not `not-found`, even though `not-found` carries the same `path` field and reads as the more specific kind. So the diff ships two vocabularies for "thing is absent" — a null return (the one actually used) and a `not-found` error kind (defined, exhaustively handled in `describeCorpusError`, but never produced). This is harmless today but invites a future consumer to `catch` and switch on `not-found` that can never fire, or to mint it inconsistently with the null-return contract.

**Recommendation:** Either delete `not-found` from the union (absence is a null return by contract) or document at its definition that it is reserved for a specific future producer (e.g., an explicit `require`-style helper) so exhaustive switches aren't handling a phantom. If manifest absence should be distinguishable from manifest corruption, consider using `not-found` there instead of overloading `io`.

## What Looks Good

- **Error model is single-sourced and exhaustive.** `CorpusErrorKind` as one discriminated union with an `assertNever` guard (`types.ts:41-96`) is a clean, consistent contract; `CorpusWorkerError` as a transport twin sharing the same `detail` kind set avoids the common drift of a second, divergent error enum for the worker boundary.
- **Predicate and factory naming is on-grain.** `isCorpusEnabled`/`isCorpusWorkerError` match the app's `is*` predicate convention; `createDebouncedLocalStorage`/`createCorpusBackedStorage` match the `create*` storage-factory convention (and the moved `createDebouncedLocalStorage` preserves the prior adapter's behavior — fact-check Claim 15).
- **The seam type is `CorpusFS`, not a concrete adapter** (`storeAdapter.ts:52,71`), so the S3 worker-proxy is a drop-in without a signature change — a forward-compatible, non-breaking extension point.
- **Path builders are internally consistent**: `*Path` for files, `*Dir` for directories, all routed through the `workspaceSlug`/`safeSegment` guards — a coherent new convention (the `state/` bypass in Finding 2 is the one exception).
- **`CorpusFS` nullability contract is uniform** (`null`/`[]` for absence, typed throw otherwise) and the OPFS adapter honors it per fact-check Claims 8 and 16.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `customTypeIds` drops app-wide `customArtifactType*` qualifier; typed `string[]` not `CustomArtifactTypeId[]` | Inconsistent | `manifest.ts:41` | High |
| 2 | `state/<name>.json` hand-concatenated, bypasses `paths.ts` sole-path-source contract & layout | Inconsistent | `storeAdapter.ts:55` | High |
| 3 | Manifest codec splits fail-loud vs. silent-default policy with no stated rule | Inconsistent | `manifest.ts:83-113` | Medium |
| 4 | `not-found` error kind never produced; absence signaled by null return instead | Minor | `types.ts:42` | High |

## Overall Assessment

The corpus module is, on its own terms, a well-shaped and internally consistent API surface — the error model, predicate/factory naming, and `CorpusFS` seam all match the app's established conventions, and the additions are backward-compatible (new module, behind a default-off flag). The consistency friction is entirely at the boundaries where the new subsystem meets the existing app: the persisted-schema field `customTypeIds` drifts from the app's `customArtifactType*` vocabulary right on the S4 reconciliation path (Finding 1), and the `state/` blob path silently bypasses the very path-construction choke point `paths.ts` advertises (Finding 2). Both are fixable in place — a rename plus a builder — and both are worth fixing now, before S4 hard-wires the manifest↔store mapping and before a second caller learns to hand-concatenate corpus paths. Findings 3 and 4 are about making the module's own advertised contracts (fail-loud parsing; typed absence) match what the code does. Consumer impact today is low (flag is dev-only, off); the cost is deferred cognitive load and a mapping seam at S4 rather than a live break.
