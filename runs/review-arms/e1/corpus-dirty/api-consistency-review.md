# API Consistency Review — corpus-dirty (dc6dfb0..2dc403e, app/ only)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` — 15 files, +1166/−33. New public surface: `app/lib/corpus/{types,paths,manifest,flag,storeAdapter,opfsAdapter}.ts` plus the `app/lib/stores/workspaceStore.ts` storage seam. `docs/working/**` treated as context, not under review.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3), used as foundation; documented behaviors from that report are not re-verified here.
**Commit:** 2dc403e

---

### Baseline Conventions

Sampled from five sibling modules that the new code sits next to: `app/lib/types/persistence.ts`, `app/lib/types/session.ts`, `app/lib/types/artifactStore.ts`, `app/lib/types/customArtifact.ts`, `app/lib/types/decomposition.ts`, plus the two existing zustand stores (`app/lib/stores/workspaceStore.ts`, `app/lib/stores/evidenceStore.ts`), the existing codec (`app/lib/utils/workspacePersistence.ts`), and the one existing error class (`app/lib/llm/callLlm.ts`).

| # | Convention | Evidence |
|---|---|---|
| B1 | Persisted data shapes are declared with `export type X = { … }`, not `interface`. `interface` is reserved for store state/action bags. | `PersistedWorkspace`, `ArtifactRecord`, `ArtifactVersion`, `SourceDocument`, `FormalizationSession`, `WorkspaceSession` are all `type`; `WorkspaceState`/`WorkspaceActions`/`EvidenceState` are `interface`. Sole exception: `CustomArtifactTypeDefinition`. |
| B2 | Every persisted schema pairs a `*_VERSION` numeric constant with a `version` field, and the loader **rejects** a mismatched version. | `WORKSPACE_VERSION = 2` + `PersistedWorkspace.version` + `if (parsed.version !== WORKSPACE_VERSION) return null;` (`workspacePersistence.ts:206`). |
| B3 | Every browser-storage key is version-suffixed. | `WORKSPACE_KEY = "workspace-v2"`, `WORKSPACE_SESSIONS_KEY = "workspace-sessions-v1"`, persist names `"workspace-zustand-v1"`, `"evidence-store-v1"`. |
| B4 | Artifact-type identity flows through the `ArtifactType`/`BuiltinArtifactType`/`ArtifactKey`/`CustomArtifactTypeId` union family — never bare `string`. | `ArtifactRecord.type: ArtifactKey`; `NodeArtifact.type: ArtifactType`; `ARTIFACT_META: Record<BuiltinArtifactType, …>`. |
| B5 | User-defined types are addressed with the `customArtifactType*` vocabulary and the branded id `CustomArtifactTypeId = \`custom-${string}\``. | `customArtifactTypes`, `customArtifactData`, `CustomArtifactTypeDefinition`, `isCustomType`. |
| B6 | Current-version pointers are named `currentVersionIndex` and are **0-based indices** into a `versions[]` array. | `ArtifactRecord.currentVersionIndex: number; // pointer into versions[]` (`artifactStore.ts`). |
| B7 | Deserialization is deliberately **lenient/coercive**, per-field, with typed fallbacks — never throwing. Bad records are dropped, not fatal. | `coerceArtifactVersion`, `coerceArtifactRecord`, `coercePersistedState`, `sanitizeVerificationStatus`, `sanitizeNodeStatus`; `loadWorkspace` returns `null` on malformation. |
| B8 | Errors are a class extending `Error` with `this.name` set and plain public payload fields; there is exactly one such class today. | `class OpenRouterError extends Error { status; details; … this.name = "OpenRouterError"; }`. Everything else throws bare `new Error(msg)` or returns `null`/`false`. |
| B9 | Zustand persist storage is SSR-guarded at the `storage:` option, and the adapter instance is hoisted with an explicit comment about why module scope is safe. | `evidenceStore.ts:117-119`: `storage: typeof window !== "undefined" ? createJSONStorage(() => debouncedStorage) : undefined`. |
| B10 | Factories are `create*` (`createDebouncedStorage`) or `make*` (`makeAnthropicClient`, `makeVersion`); loaders are `load*`/`save*`; pure resolvers over already-held data are `resolve*` (`resolveArtifactContent`). | as cited. |
| B11 | Source documents carry prefixed field names. | `SourceDocument = { sourceId; sourceLabel; text }` (`decomposition.ts:52`). |
| B12 | Discriminated unions in the app discriminate on `type` when the union *is* the concept (`SessionScope`), on `kind` when `kind` is a *field* of a larger record (`PropositionNode.kind: NodeKind`). | `SessionScope = { type: "global" } \| { type: "node"; … }`. |
| B13 | Server-only env vars are read bare (`process.env.X`) with no `NEXT_PUBLIC_` prefix anywhere in `app/`. | `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `LEAN_VERIFIER_URL`, `OPENALEX_MAILTO`, `VERCEL`. `NEXT_PUBLIC_CORPUS_FS` is the first of its kind. |

---

### Name-Pattern Audit

Ordered most-public-first: exported types → exported classes → exported functions → record fields. 28 new exported names plus manifest fields.

| New name | Kind | Closest existing neighbor | Verdict |
|---|---|---|---|
| `CorpusFS` | exported interface | `CustomArtifactTypeDefinition` (interface), `PersistedWorkspace` (type) | **Divergent (B1)** — declared `interface`; also the only abbreviated type name in `app/lib` (`FS`). No `*FS`/`*Fs` precedent exists. Defensible for a behavioral seam. |
| `CorpusStat` | exported interface | no app precedent; Node `fs.Stats` | Acceptable (borrows platform vocabulary), but `interface` vs B1. |
| `CorpusError` | exported class | `OpenRouterError` (B8) | **Consistent** — extends `Error`, sets `this.name`, public payload field. |
| `CorpusErrorKind` | exported type | `NodeKind`, `MathKind` (string unions); `SessionScope` (payload union) | **Divergent** — see F8. `*Kind` in this codebase names a bare string union; this is a payload union. |
| `CorpusSubstrate` | exported type | none | No existing precedent in `app/lib`. Fine. |
| `CorpusWorkerError` | exported type | `OpenRouterError` | Acceptable; the `__corpusError` brand has no precedent (nearest is `CustomArtifactTypeId`'s `custom-` prefix brand). |
| `WorkspaceManifest` | exported interface | `PersistedWorkspace`, `WorkspaceSession` | **Divergent (B1)** — `interface` where every sibling persisted shape is `type`. |
| `SourceRef` | exported interface | `SourceDocument` (B11) | **Divergent** — see F7. Field names unprefixed (`id`/`label`) where the neighbor uses `sourceId`/`sourceLabel`. |
| `ArtifactPointer` | exported interface | `ArtifactRecord` | Name is fine; field `currentVersion` collides semantically with `currentVersionIndex` — see F4. |
| `MANIFEST_VERSION` | exported const | `WORKSPACE_VERSION`, `MAX_VERSIONS` | **Consistent** naming; enforcement diverges — see F3. |
| `CORPUS_FLAG_KEY` | exported const | `WORKSPACE_KEY`, `WORKSPACE_SESSIONS_KEY` | Name consistent; **value** `"corpus-fs-enabled"` is unversioned — see F16 (B3). |
| `SETTINGS_PATH` | exported const | all other paths.ts exports are functions | Asymmetric export shape — see F15. |
| `workspaceSlug` | exported fn | no sanitizer precedent in `app/lib` | *No existing precedent in `app/lib` for slug/sanitize helpers* (nearest: `generateSessionTitle`, `stripCodeFences`). Fine. |
| `safeSegment` | exported fn | `workspaceSlug` (same module) | **Divergent from its own sibling** — preserves case where `workspaceSlug` lowercases. See F14. |
| `workspaceDir` / `workspaceManifestPath` / `sourcePath` / `artifactDir` / `artifactVersionPath` / `artifactMetaPath` / `customTypePath` / `decompositionDir` / `decompositionGraphLayoutPath` | exported fns | none | Internally consistent `<noun>Path` / `<noun>Dir` scheme. Good. Parameter naming diverges — F14. |
| `createManifest` | exported fn | `makeVersion`, `createDebouncedStorage` (B10) | Consistent. |
| `serializeManifest` / `parseManifest` | exported fns | `saveWorkspace`/`loadWorkspace`, `coerce*` (B7) | Names fine; the **pair is asymmetric** in field set and in throw-vs-null behavior — F2, F3, F19. |
| `isCorpusEnabled` | exported fn | `isCustomType` | Consistent `is*` predicate. |
| `createDebouncedLocalStorage` | exported fn | `createDebouncedStorage` (private, evidenceStore + old workspaceStore) | Consistent factory naming; renaming a moved function while an identically-purposed `createDebouncedStorage` still lives in `evidenceStore.ts` creates two names for one concept — F12. |
| `createCorpusBackedStorage` | exported fn | as above | Consistent. |
| `createOpfsCorpusFs` | exported fn | as above | Consistent; note casing `Fs` here vs type `CorpusFS`. |
| `resolveWorkspaceStorage` | exported fn | `resolveArtifactContent` (B10 — pure, over held data) | **Divergent** — this `resolve*` reads global env/localStorage and constructs an adapter. `create*`/`select*` would match B10. Minor. |
| `toWorkerError` / `isCorpusWorkerError` | exported fns | each other | **Asymmetric pair** — F13. |
| `describeCorpusError` | exported fn | none | Fine. |
| `assertNever` | exported fn | *No existing precedent in `app/`* — grep for `assertNever`/`x: never` across `app/` returns only this file | Generic, unprefixed utility exported from a corpus-specific module — F13. |
| `WorkspaceManifest.customTypeIds` | field | `customArtifactTypes`, `customArtifactData` (B5) | **Divergent** — F5. |
| `WorkspaceManifest.manifestVersion` | field | `PersistedWorkspace.version` (B2) | Minor divergence; self-describing prefix is defensible since manifests may be embedded. Informational. |
| `ArtifactPointer.type` / `artifactType` params | field / params | `ArtifactRecord.type: ArtifactKey` (B4) | **Divergent** — typed `string`. F6. |

---

### Findings

#### F1. `state/` path layout is built outside `paths.ts`, the module that declares itself the sole source of corpus paths

**Severity:** Inconsistent
**Location:** `app/lib/corpus/storeAdapter.ts:56`; contract declared at `app/lib/corpus/paths.ts:18-22`
**Move:** (3) consumer contracts / (2) naming vs neighbors
**Confidence:** High
*Precedent: the single-choke-point path convention is declared and used in `app/lib/corpus/paths.ts`, and every other corpus path in the diff routes through it.*
**Evidence:**
```
 * All builders return POSIX-style paths relative to the corpus root (no leading
 * slash), suitable for passing straight to a `CorpusFS`. The only source of
 * corpus paths is this module — callers must never hand-concatenate, so the
 * traversal guard in `workspaceSlug` is the single choke point that keeps
 * untrusted workspace titles inside `workspaces/`.
```
versus
```ts
  const pathFor = (name: string) => `state/${name}.json`;
```
**Legibility-target:** the S2 (FSA mirror) and S4 (migration) authors, who will enumerate the corpus root from `paths.ts` and find a `state/` directory that module has never heard of.

The corpus root now has two path vocabularies: the documented layout (`settings.json`, `workspaces/…`) exported from `paths.ts`, and an undocumented `state/<persist-name>.json` minted inline in `storeAdapter.ts`. Nothing in `paths.ts` names `state/`, so a mirror or migration written against the documented layout will silently omit the one file that actually holds user work in S1. The name interpolated into the path is the zustand persist key, which is developer-controlled today but is exactly the kind of value the module's own doc says must never be hand-concatenated — the convention is stated as absolute and then broken by the first consumer.
**Recommendation:** add `export function statePath(name: string): string` to `paths.ts` (using `safeSegment(name)`), document `state/` in the folder-layout comment, and have `createCorpusBackedStorage` call it.

---

#### F2. `serializeManifest` and `parseManifest` disagree on the required field set, and the codec contradicts its own fail-loud contract

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:10-14` (contract), `:74-113` (`parseManifest`)
**Move:** (7) asymmetries — serialize/deserialize field sets
**Confidence:** High (behavior established by the merged fact-check)
**Evidence:** the declared contract —
```
 * Codec contract (arch-review / test-strategy G11): parsing is FAIL-LOUD. A
 * malformed or absent manifest must surface as a typed `CorpusError` of kind
 * "io" or "browser-storage-cleared", never a silent default-empty manifest that
 * would masquerade as "this workspace has no work in it" and mask data loss.
```
versus the implementation —
```ts
        return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
…
    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
    updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : new Date().toISOString(),
```
**Legibility-target:** any consumer that reads `manifest.createdAt` and assumes it is the workspace's real creation time.

`WorkspaceManifest` declares `createdAt`, `updatedAt`, and `SourceRef.label` as required, and `serializeManifest` always emits all three; `parseManifest` accepts their absence and manufactures replacements — `createdAt` becomes *now*, silently converting "corrupted timestamp" into "created this instant". The same function is strict about `title`/`manifestVersion`/`sources`/`artifacts`/`customTypeIds` (`fail()`) and lenient about the rest, so a reader cannot predict from the type which fields are actually load-bearing. The leniency itself is not wrong — it matches B7, the app's established coercive-deserialization style (`coerceArtifactVersion` defaults `createdAt` identically) — but the module's own header advertises the opposite policy, and `.filter(isObject)` additionally drops malformed `sources`/`artifacts` entries without a word.
**Recommendation:** pick one policy and make the doc, the type, and the code agree. Either (a) mark `createdAt`/`updatedAt`/`label` optional on the interface and rewrite the header to say "coercive, consistent with `workspacePersistence.coerce*`", or (b) `fail()` on their absence and on any dropped array entry. Option (a) is the smaller change and matches B7.

---

#### F3. `parseManifest` never checks `manifestVersion`, unlike every other versioned loader in the app

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:88` and `:107`
**Move:** (3) consumer contracts / (4) error consistency
**Confidence:** High
**Evidence:**
```ts
  if (typeof raw.manifestVersion !== "number") fail("missing required field: manifestVersion");
…
    manifestVersion: raw.manifestVersion,
```
compared to `app/lib/utils/workspacePersistence.ts:206`:
```ts
    if (parsed.version !== WORKSPACE_VERSION) return null;
```
**Legibility-target:** whoever ships manifest v2 and needs the v1 reader to have refused unknown versions.

`MANIFEST_VERSION` is exported and stamped on write, but the reader only checks that the field is *a number* — a manifest claiming `manifestVersion: 7` parses successfully and is handed to callers as if it were v1. B2 is unambiguous here: the app's one existing versioned loader compares against the constant and bails. Because the corpus manifest is the workspace index, accepting a future version means a newer build's data will be read with older field semantics rather than rejected, and the failure will surface as missing artifacts rather than a version error.
**Recommendation:** `if (raw.manifestVersion !== MANIFEST_VERSION) fail(\`unsupported manifestVersion: ${raw.manifestVersion}\`);` — or add an explicit migration branch if forward-compat is intended.

---

#### F4. `ArtifactPointer.currentVersion` is 1-based while the established `currentVersionIndex` is 0-based

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:29-32`; `app/lib/corpus/paths.ts:88-95`
**Move:** (2) naming vs neighbors / (3) consumer contracts
**Confidence:** High
*Precedent: `currentVersionIndex: number; // pointer into versions[]` used in `app/lib/types/artifactStore.ts`, consumed by `resolveArtifactContent` and `coerceArtifactRecord` in `app/lib/stores/workspaceStore.ts`.*
**Evidence:**
```ts
/** Pointer to the current version of one artifact type. `currentVersion` is the
 *  1-based version number whose file is artifacts/<type>/v####.md. */
export interface ArtifactPointer {
  type: string;
  currentVersion: number;
}
```
against `artifactStore.ts`:
```ts
  currentVersionIndex: number; // pointer into versions[]
```
**Legibility-target:** the S4 migration author translating `ArtifactRecord` → `ArtifactPointer`, where an off-by-one silently points at the wrong revision.

Both names are "the current version pointer for one artifact", they will sit on both sides of the S4 migration, and they differ by exactly one with no signal in the names. `currentVersionIndex` is 0-based by its `Index` suffix; `currentVersion` drops the suffix and flips the base, and the only place that distinction is recorded is a doc comment in a different file. `artifactVersionPath` enforces `version >= 1`, so an index passed by mistake either throws (for 0) or silently resolves to `v{n+1}` — a wrong-file read, not a crash.
**Recommendation:** rename to `currentVersionNumber` (or keep `currentVersion` but add a branded `type VersionNumber = number`), and state the 1-based/0-based relationship in `artifactStore.ts` as well as here.

---

#### F5. `customTypeIds` abandons the app's `customArtifactType*` vocabulary and its branded id type

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:41`; `app/lib/corpus/paths.ts:100-102`
**Move:** (3) consumer contracts — manifest fields vs existing vocabulary
**Confidence:** High
*Precedent: `customArtifactTypes` / `customArtifactData` fields in `app/lib/types/persistence.ts` and `app/lib/stores/workspaceStore.ts`; `CustomArtifactTypeId = \`custom-${string}\`` and `isCustomType` in `app/lib/types/customArtifact.ts`.*
**Evidence:**
```ts
export interface WorkspaceManifest {
  …
  customTypeIds: string[];
}
```
versus `persistence.ts`:
```ts
  customArtifactTypes?: CustomArtifactTypeDefinition[];
  /** Generated output for custom types, keyed by custom type ID */
  customArtifactData?: Record<string, string | null>;
```
**Legibility-target:** the S4 migration author mapping `PersistedWorkspace.customArtifactTypes` onto the manifest.

The app has one established name for this concept — "custom artifact type" — carried consistently across the persisted schema, the store state, the type module, and the `isCustomType` guard. The manifest shortens it to "custom type", which in a corpus that will also hold *source* types and *artifact* types is genuinely ambiguous, and types the ids as bare `string` where `CustomArtifactTypeId` already exists and is already enforced elsewhere (`workspaceStore.ts` filters persisted entries on `id.startsWith("custom-")`). The manifest is the one place a non-`custom-`-prefixed id could enter the corpus unchallenged.
**Recommendation:** rename to `customArtifactTypeIds` and type it `CustomArtifactTypeId[]`, validating with `isCustomType` in `parseManifest` instead of the current bare `typeof x === "string"` filter.

---

#### F6. Artifact type is typed `string` throughout the corpus surface, discarding the `ArtifactKey`/`ArtifactType` unions

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:30`; `app/lib/corpus/paths.ts:83, 88, 97`
**Move:** (3) consumer contracts
**Confidence:** High
*Precedent: `ArtifactRecord.type: ArtifactKey` (`app/lib/types/artifactStore.ts`), `NodeArtifact.type: ArtifactType` (`app/lib/types/decomposition.ts`), `ARTIFACT_META: Record<BuiltinArtifactType, …>` (`app/lib/types/artifacts.ts`).*
**Evidence:**
```ts
export function artifactDir(slug: string, artifactType: string): string {
  return `${workspaceDir(slug)}/artifacts/${safeSegment(artifactType)}`;
}
```
**Legibility-target:** a caller who types `artifactDir(slug, "causalGraph")` and gets a valid-looking path to a directory that will never contain anything.

B4 is one of the codebase's most consistently applied rules: artifact identity is a union, never `string`, and `ArtifactKey` even exists specifically to `Exclude` the two non-structured types. The corpus path builders and `ArtifactPointer` accept any string, so the camelCase/kebab-case slip that the union exists to prevent (`"causal-graph"` vs `"causalGraph"`, both of which appear in the codebase — the latter as `ARTIFACT_RESPONSE_KEY.causalGraph`) is unguarded at exactly the layer that turns a type name into a directory name. `safeSegment` will happily sanitize a typo into a plausible path.
**Recommendation:** type these parameters and `ArtifactPointer.type` as `ArtifactType` (which already unions in `CustomArtifactTypeId`), importing from `@/app/lib/types/session`. If the corpus module must stay dependency-free from `types/`, at minimum validate against `SELECTABLE_ARTIFACT_TYPES ∪ isCustomType` in `parseManifest`.

---

#### F7. `SourceRef` field names drop the prefix convention used by the existing `SourceDocument`

**Severity:** Minor
**Location:** `app/lib/corpus/manifest.ts:34-39`
**Move:** (2) naming vs neighbors
**Confidence:** Medium
*Precedent: `SourceDocument = { sourceId: string; sourceLabel: string; text: string }` in `app/lib/types/decomposition.ts:52`, persisted inside `PersistedDecomposition.sources`.*
**Evidence:**
```ts
export interface SourceRef {
  id: string;
  label: string;
  /** File extension (no dot) of the stored source bytes under sources/. */
  ext: string;
}
```
**Legibility-target:** the S4 migration author writing `sources.map(d => ({ id: d.sourceId, label: d.sourceLabel, … }))` and reviewers checking that mapping.

Both types describe the same domain object — a source document attached to a workspace — and both are persisted under a field named `sources`. `SourceDocument` prefixes its scalars (`sourceId`, `sourceLabel`); `SourceRef` does not. Neither convention is wrong in isolation, but having both means the migration is a field-rename rather than a spread, and a reader seeing `sources[i].id` cannot tell which of the two shapes they hold. The `Ref` suffix itself is well chosen and worth keeping — this is only about the fields.
**Recommendation:** either adopt `sourceId`/`sourceLabel` on `SourceRef`, or note explicitly in `decomposition.ts` that `SourceDocument` is the legacy shape being superseded so the divergence reads as intentional.

---

#### F8. `CorpusErrorKind` names a payload union, not a kind

**Severity:** Minor
**Location:** `app/lib/corpus/types.ts:36-49`
**Move:** (2) naming vs neighbors / (4) error consistency
**Confidence:** Medium
*Precedent: `NodeKind` and `MathKind` in this codebase are bare string unions consumed as `kind: NodeKind` (`app/lib/types/decomposition.ts:68`, `app/lib/utils/pdfPropositionParser.ts:29`); the discriminated-union-of-payloads precedent is `SessionScope` in `app/lib/types/session.ts`, which is named for the concept, not for its discriminant.*
**Evidence:**
```ts
export type CorpusErrorKind =
  | { kind: "not-found"; path: string }
  …
export class CorpusError extends Error {
  readonly detail: CorpusErrorKind;
```
**Legibility-target:** a consumer writing `switch (err.detail.kind)` who first has to work out that `detail: CorpusErrorKind` is not a kind.

In this codebase `*Kind` means "the string union of discriminant values" — `NodeKind`, `MathKind` — and the type that carries payloads is named for what it *is* (`SessionScope`, not `SessionScopeType`). Here the payload union is called `...Kind` and is stored in a field called `detail`, so the type name and the field name describe different things, and there is no name at all for the actual kind union (`"not-found" | "quota-exceeded" | …`), which consumers will end up re-deriving as `CorpusErrorKind["kind"]`.
**Recommendation:** rename to `CorpusErrorDetail` (matching the field) and add `export type CorpusErrorKindName = CorpusErrorDetail["kind"]` for the discriminant-only union.

---

#### F9. The advertised error-kind set is far wider than what any code emits, and `not-found` is structurally unreachable

**Severity:** Inconsistent
**Location:** `app/lib/corpus/types.ts:42-49` vs `:106-124`; emitters at `app/lib/corpus/opfsAdapter.ts:52, 60, 81, 82` and `app/lib/corpus/manifest.ts:66`
**Move:** (4) error consistency
**Confidence:** High (emission set established by the merged fact-check)
**Evidence:** the contract —
```
 * The complete set of corpus failure kinds. Every exhaustive `switch` over a
 * corpus error binds to this union; adding a kind here forces every consumer to
 * handle it at compile time (the failure-driven-UI mandate, DD-009 §Failure-driven).
```
and, four lines below the `not-found` member, the interface doc —
```
 *  - "Not found" is `null` from `readFile`/`stat` and `[]` from `readdir`;
 *    everything else rejects with a `CorpusError`. Callers never see `undefined`.
```
**Legibility-target:** the first UI author who must write eight `case` arms to satisfy the exhaustiveness mandate.

`CorpusErrorKind` advertises eight kinds. Three are reachable in this diff (`io`, `unavailable`, `quota-exceeded`); `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, and `git-conflict` belong to S2/S3 and have no emitter. `not-found` is different in kind: the interface contract on the same file states that absence is signalled by `null`/`[]`, so no correct `CorpusFS` implementation can ever throw it — it is a member the surrounding documentation forbids. Meanwhile `manifest.ts`'s header promises `"browser-storage-cleared"` as a possible parse outcome and only ever emits `"io"`. Because the union drives compile-time exhaustiveness, every one of these speculative members imposes a real cost on every consumer switch, and `describeCorpusError` already carries five arms of unreachable prose.
**Recommendation:** narrow the union to the kinds S0/S1 can produce and grow it per sub-task (the exhaustiveness mandate makes additive growth safe and cheap). At minimum, delete `not-found` or drop the null-return convention — the two cannot both be right.

---

#### F10. The two storages behind one `StateStorage` return type differ in synchrony and in failure behavior

**Severity:** Inconsistent
**Location:** `app/lib/corpus/storeAdapter.ts:25-49` vs `:52-69`, selected at `:71-76`; consumed at `app/lib/stores/workspaceStore.ts:499`
**Move:** (3) consumer contracts / (4) error consistency
**Confidence:** High
**Evidence:** OFF path —
```ts
        try {
          localStorage.setItem(name, value);
        } catch (e) {
          console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
        }
```
ON path —
```ts
    setItem: async (name, value) => {
      await fs.writeFile(pathFor(name), enc.encode(value));
    },
```
**Legibility-target:** the developer who flips the flag and sees an unhandled promise rejection instead of a console warning on a full disk.

`resolveWorkspaceStorage(): StateStorage` presents the two adapters as interchangeable, but they differ on two axes the type cannot express. First, `getItem` is synchronous on the OFF path and a promise on the ON path, so rehydration through `skipHydration` + `rehydrate()` completes in a different tick depending on a flag — the store's own comment still says "SSR safe: render defaults first, hydrate in useEffect". Second, quota exhaustion is swallowed with `console.warn` on the OFF path and rejects with a `CorpusError` on the ON path, where zustand's persist has no rejection handler; `opfsAdapter.ts`'s header explicitly frames this as a deliberate improvement ("it is NOT swallowed with console.warn the way the legacy localStorage adapter does") but nothing on the ON path catches it, so the improvement lands as an unhandled rejection rather than as UI. The seam is also selected once per store creation, so toggling the flag at runtime has no effect until reload — reasonable, but undocumented at the flag's own doc site.
**Recommendation:** give `createCorpusBackedStorage` the same swallow-and-warn envelope (or, better, route both through a shared `onPersistError` callback so the two paths report identically), and state on `resolveWorkspaceStorage` that the ON path is async and is fixed at store-construction time.

---

#### F11. The new persist wiring drops the SSR guard that `evidenceStore` applies to the identical option

**Severity:** Inconsistent
**Location:** `app/lib/stores/workspaceStore.ts:496-499`
**Move:** (3) consumer contracts / (8) nullability
**Confidence:** Medium
*Precedent: `app/lib/stores/evidenceStore.ts:117-119`.*
**Evidence:** new code —
```ts
      storage: createJSONStorage(resolveWorkspaceStorage),
```
sibling store —
```ts
      storage: typeof window !== "undefined"
        ? createJSONStorage(() => debouncedStorage)
        : undefined,
```
with the sibling's rationale comment: *"Safe at module scope because the adapter's methods are only invoked via the persist middleware's `storage` config, which is guarded by `typeof window !== "undefined"` in the persist config below. During SSR, `storage` is `undefined` so the adapter is never called."*
**Legibility-target:** whoever debugs the first server-render that touches workspace persistence.

The two stores in `app/lib/stores/` now configure the same zustand option two different ways. `evidenceStore` treats `storage: undefined` as the SSR contract and documents why module-scope construction is safe *because* of that guard; `workspaceStore` relies instead on `skipHydration` plus each adapter's internal defenses (`isCorpusEnabled` returns `false` without `window`; `getRoot` throws `{kind:"unavailable"}`). That is probably sufficient today, but it means the OFF path's `getItem` closes over a bare `localStorage` reference with no guard of its own, and a future reader comparing the two stores has no way to tell which pattern is the house style.
**Recommendation:** mirror the `evidenceStore` guard, or add a comment at `workspaceStore.ts:499` explaining why this store deliberately omits it.

---

#### F12. `evidenceStore` keeps a private duplicate of the storage adapter and is not routed through the new seam

**Severity:** Minor
**Location:** `app/lib/stores/evidenceStore.ts` (unchanged in range) vs `app/lib/corpus/storeAdapter.ts:25`
**Move:** (3) consumer contracts
**Confidence:** High
**Evidence:** the moved function's own header —
```
// Default: debounced localStorage (moved verbatim from workspaceStore.ts so the
// OFF path is byte-for-byte the prior behavior — see the characterization test).
```
while `evidenceStore.ts` still declares its own `createDebouncedStorage()` and hoists `const debouncedStorage = createDebouncedStorage();`.
**Legibility-target:** a developer running with the flag on who wonders why evidence survives a corpus wipe.

The refactor exports `createDebouncedLocalStorage` as shared public surface but leaves the second, identical implementation in `evidenceStore` untouched — so the codebase now has one exported and one private version of the same 25 lines, under two names. More consequentially, `evidenceStore` does not consult `isCorpusEnabled`, so with the flag on, workspace state lives in OPFS while evidence slots stay in localStorage: two halves of one user session in two substrates, with no single place that clears or migrates both. Deferring evidence to a later sub-task is defensible; leaving it undocumented at the seam is what makes it a consistency problem.
**Recommendation:** have `evidenceStore` import `createDebouncedLocalStorage`, and add a one-line note at `resolveWorkspaceStorage` naming which stores are (and are not) behind the seam in S1.

---

#### F13. Prefixing is asymmetric across the `types.ts` exports, including within one to/is pair

**Severity:** Minor
**Location:** `app/lib/corpus/types.ts:65-79, 93-96`
**Move:** (2) naming vs neighbors
**Confidence:** Medium
*Precedent for the module's own dominant pattern: `CorpusSubstrate`, `CorpusErrorKind`, `CorpusError`, `CorpusWorkerError`, `CorpusStat`, `CorpusFS`, `describeCorpusError`, `isCorpusWorkerError` — all `Corpus`-qualified. No existing `assertNever` or exhaustiveness helper anywhere in `app/` (searched `app/**`).*
**Evidence:**
```ts
export function toWorkerError(err: CorpusError): CorpusWorkerError { … }
export function isCorpusWorkerError(v: unknown): v is CorpusWorkerError { … }
…
export function assertNever(x: never): never {
```
**Legibility-target:** a reader scanning imports from `@/app/lib/corpus/types` in an unrelated file.

`toWorkerError` and `isCorpusWorkerError` are a matched pair over the same type but qualify it differently; imported side by side into a file that also deals with, say, a verifier worker, `toWorkerError` reads as generic. `assertNever` is worse: it is a fully generic TypeScript idiom, has no `Corpus` qualifier, is unrelated to the corpus domain, and is the first of its kind in the repo — exporting it from a corpus module means the app's exhaustiveness helper now lives under `lib/corpus/`, and the second caller elsewhere will either import from a strange path or define a duplicate.
**Recommendation:** rename to `toCorpusWorkerError`, and move `assertNever` to a neutral home (`app/lib/utils/assertNever.ts`) since it has no corpus-specific behavior.

---

#### F14. `paths.ts` parameters disagree about whether their input is raw or sanitized, and its two sanitizers differ on case

**Severity:** Minor
**Location:** `app/lib/corpus/paths.ts:31-56, 69-71`
**Move:** (2) naming vs neighbors / (9) idempotency
**Confidence:** High
**Evidence:**
```ts
export function workspaceSlug(title: string): string {
…
    .toLowerCase();
…
export function safeSegment(id: string): string {
  const seg = id.normalize("NFKD").replace(SAFE_SEGMENT, "-")…
…
export function workspaceDir(slug: string): string {
  return `workspaces/${workspaceSlug(slug)}`;
}
```
**Legibility-target:** a caller deciding whether to pre-slugify before calling `workspaceManifestPath`.

`workspaceSlug` takes a `title`; every builder that consumes it names the same parameter `slug` and then re-slugifies it. Re-slugification is in fact idempotent (`workspaceSlug` output contains only `[a-z0-9_-]` with no leading/trailing or doubled hyphens, so a second pass is a no-op), so this is safe — but the parameter name tells callers the value is already sanitized while the body assumes it is not, and only one of those can be the documented contract. Separately, the two sanitizers in this module diverge on case: `workspaceSlug` lowercases and `safeSegment` explicitly does not, so on a case-insensitive filesystem mirror (S2, macOS/Windows) two source ids differing only in case collide, while two workspace titles differing only in case are *deliberately* unified. Neither behavior is wrong; having both undocumented on one path line is.
**Recommendation:** rename the builders' parameter to `title` (or add `workspaceDirFromSlug` for pre-sanitized input) and note the case asymmetry in the `safeSegment` doc comment, including the S2 collision consequence.

---

#### F15. `paths.ts` exports one path as a constant and the rest as functions

**Severity:** Informational
**Location:** `app/lib/corpus/paths.ts:60`
**Move:** (7) asymmetries
**Confidence:** High
*Precedent: no existing path-builder module in `app/lib` — `dataDir()` in `app/lib/utils/dataDir.ts` is a function despite being parameterless.*
**Evidence:**
```ts
export const SETTINGS_PATH = "settings.json";
```
**Legibility-target:** a caller writing `import { SETTINGS_PATH, workspaceManifestPath }` and pausing over the mixed call syntax.

Every other corpus path is a function; `SETTINGS_PATH` is a bare const, so the module's usage is `SETTINGS_PATH` in one line and `workspaceManifestPath(s)` in the next. The nearest precedent in the app, `dataDir()`, is a function even though it takes no arguments — precisely so its call site does not have to change when it later needs a parameter. Given that S2 will likely need per-root settings paths, the const is the shape most likely to churn.
**Recommendation:** either expose `settingsPath(): string` alongside (keeping the const private), or accept the asymmetry and say so in the module header.

---

#### F16. The corpus flag key is unversioned and `NEXT_PUBLIC_CORPUS_FS` is the app's first client-exposed env var, against a "DEV-ONLY" claim

**Severity:** Informational
**Location:** `app/lib/corpus/flag.ts:1-24`
**Move:** (2) naming vs neighbors / (3) consumer contracts
**Confidence:** High (unenforced "DEV-ONLY" established by the merged fact-check)
*Precedent: every browser-storage key in the app is version-suffixed — `workspace-v2`, `workspace-sessions-v1`, `workspace-zustand-v1`, `evidence-store-v1`. Every env var read in `app/` is server-side and unprefixed: `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `LEAN_VERIFIER_URL`, `OPENALEX_MAILTO`, `VERCEL`.*
**Evidence:**
```ts
export const CORPUS_FLAG_KEY = "corpus-fs-enabled";

export function isCorpusEnabled(): boolean {
  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
```
with the header claim: *"DEFAULT OFF and DEV-ONLY … it must not be turned on for end users until S4 ships migration."*
**Legibility-target:** the person who sets `NEXT_PUBLIC_CORPUS_FS=1` in a Vercel preview and ships it to a user with existing localStorage work.

Two small divergences. The localStorage key omits the version suffix that B3 applies universally — harmless for a boolean flag, but it means the corpus flag is the one key that cannot be version-bumped if its semantics change (e.g. from boolean to a substrate name). More notably, `NEXT_PUBLIC_*` is by definition inlined into the client bundle at build time and is a production-capable switch; the module asserts "DEV-ONLY" but nothing checks `NODE_ENV`, so the doc states a constraint the API does not enforce, and the constraint's violation is exactly the data-loss scenario the same comment describes ("enabling this starts from an EMPTY corpus").
**Recommendation:** gate on `process.env.NODE_ENV !== "production"` so the claim is enforced, and version the key (`corpus-fs-enabled-v1`) for consistency with B3.

---

#### F17. Corpus declares its data shapes with `interface` where every sibling persisted shape uses `type`

**Severity:** Informational
**Location:** `app/lib/corpus/types.ts:100-102, 111-124`; `app/lib/corpus/manifest.ts:29-42`
**Move:** (2) naming vs neighbors
**Confidence:** Medium
*Precedent: `PersistedWorkspace`, `PersistedDecomposition`, `ArtifactRecord`, `ArtifactVersion`, `SourceDocument`, `PropositionNode`, `FormalizationSession`, `WorkspaceSession`, `ArtifactGenerationRequest` are all `export type`; `interface` appears only for store bags (`WorkspaceState`, `EvidenceState`) and the single exception `CustomArtifactTypeDefinition`.*
**Evidence:**
```ts
export interface WorkspaceManifest {
export interface SourceRef {
export interface ArtifactPointer {
export interface CorpusStat {
```
**Legibility-target:** a reader inferring the house style from `app/lib/types/`.

`CorpusFS` as an `interface` is well justified — it is a behavioral seam meant to be implemented, and declaration merging is not a hazard there. `WorkspaceManifest`, `SourceRef`, `ArtifactPointer`, and `CorpusStat` are plain data records, the exact category where the codebase consistently reaches for `type`. The functional difference is negligible; the cost is that a reader can no longer use `type`-vs-`interface` as the signal for "data shape vs implementable contract", which is currently a reliable signal in this repo.
**Recommendation:** convert the four data records to `export type`, keeping `interface` for `CorpusFS`.

---

#### F18. Discriminant field is `kind` where the app's payload-union precedent uses `type`

**Severity:** Informational
**Location:** `app/lib/corpus/types.ts:42-49`
**Move:** (2) naming vs neighbors
**Confidence:** Low
*Precedent: `SessionScope = { type: "global" } | { type: "node"; nodeId; nodeLabel }` (`app/lib/types/session.ts`) is the app's only prior discriminated payload union and uses `type`. Counter-precedent: `kind` is used as a plain enum field on `PropositionNode` and `MathHeader`.*
**Evidence:**
```ts
  | { kind: "not-found"; path: string }
```
**Legibility-target:** a reader who has just written a `switch (scope.type)` and now writes `switch (err.detail.kind)`.

The codebase has one prior discriminated union of payload objects and it discriminates on `type`; `kind` is elsewhere used for closed string enums on records. Flagged for completeness rather than as a defect — `kind` avoids collision with `ArtifactPointer.type` and reads better next to `CorpusErrorKind`, and either choice is defensible. Worth a deliberate call now, before S2/S3 add more union types.
**Recommendation:** no change required; if `CorpusErrorKind` is renamed per F8, note the `kind`-vs-`type` choice in the module header so it reads as decided rather than accidental.

---

#### F19. Nullability is inconsistent across the corpus surface: `parseManifest` accepts a null its doc forbids, `readdir` cannot report absence, and `walkDir(create:true)` forces a non-null assertion

**Severity:** Minor
**Location:** `app/lib/corpus/manifest.ts:69-76`; `app/lib/corpus/types.ts:118-124`; `app/lib/corpus/opfsAdapter.ts:64-77, 108`
**Move:** (8) nullability
**Confidence:** High
**Evidence:**
```ts
 * `CorpusFS.readFile` returning `null`; passing `null` here is itself an error.
 */
export function parseManifest(bytes: Uint8Array | null): WorkspaceManifest {
  if (bytes === null) fail("manifest file is absent");
```
and
```ts
        const dir = await walkDir(root, dirs, true);
        const fh = await dir!.getFileHandle(name, { create: true });
```
**Legibility-target:** a caller composing `readFile` → `parseManifest` and deciding where the absent-file branch belongs.

Three small nullability inconsistencies on one surface. `parseManifest`'s signature invites the very `null` its doc comment calls a caller error — either the parameter should be `Uint8Array` (pushing the absence check to the caller, as documented) or the doc should stop calling it an error. `readdir` returns `[]` for both "missing directory" and "empty directory", so unlike `readFile`/`stat` it gives callers no way to distinguish absence — a deliberate choice per the interface doc, but it means the "not found is null" rule has an unstated exception and that `stat` is the only way to probe a directory's existence. And `walkDir` is typed `Promise<OpfsDirHandle | null>` even though it cannot return `null` when `create` is `true`, forcing the `dir!` assertion in `writeFile` — the one place in the adapter where a type error would surface as a runtime `TypeError` rather than a `CorpusError`.
**Recommendation:** narrow `parseManifest` to `Uint8Array`; state the `readdir` exception in the "Not found" bullet of the `CorpusFS` doc; and overload `walkDir` (`create: true → Promise<OpfsDirHandle>`) to remove the non-null assertion.

---

### What Looks Good

- **`CorpusError` follows the one existing error precedent closely.** It extends `Error`, sets `this.name = "CorpusError"`, and carries a public payload field — the same shape as `OpenRouterError` (B8), with the payload upgraded to a discriminated union. That is a genuine improvement on the baseline rather than a divergence from it.
- **The `CorpusFS` interface is correctly scoped.** Five methods, bytes-and-paths, no git — and the header explains *why* git is excluded (ISP: the in-memory fake would have to stub it). The seam is typed as the interface at the injection point (`createCorpusBackedStorage(fs: CorpusFS)`), so the S3 worker proxy really is a drop-in.
- **`rm` is documented and implemented as idempotent**, at both the missing-parent and missing-file levels, and the contract test asserts it (`workspaceStore-corpus-flag.test.ts` asserts a second `removeItem` resolves). Idempotency (move 9) holds on the delete path.
- **The path-builder naming scheme is internally consistent** — `<noun>Dir` for directories, `<noun>Path` for files, all relative, all POSIX, all routed through one sanitizer. Setting aside F1 and F14, this is a clean and predictable module surface.
- **`readdir` returns sorted names**, making directory enumeration deterministic across substrates — an unstated-but-valuable contract for the S2 mirror diffing.
- **The OFF path is preserved byte-for-byte** and pinned by a characterization test, so the refactor is a genuine no-op for existing consumers. The default-OFF flag means none of the findings above affect a live client today.
- **`ArtifactPointer`/`SourceRef` keep per-version bytes out of the manifest**, so the index stays small — the right split for a file-backed corpus, and consistent with how `ArtifactRecord` separates pointer from payload.

---

### Summary Table

| ID | Finding | Severity | Move | Confidence |
|---|---|---|---|---|
| F1 | `state/` path built outside `paths.ts`, the declared sole choke point | Inconsistent | consumer contracts | High |
| F2 | serialize/parse field-set asymmetry; codec contradicts its fail-loud contract | Inconsistent | asymmetries | High |
| F3 | `parseManifest` never checks `MANIFEST_VERSION` (B2 violated) | Inconsistent | consumer contracts | High |
| F4 | `currentVersion` (1-based) vs established `currentVersionIndex` (0-based) | Inconsistent | naming vs neighbors | High |
| F5 | `customTypeIds: string[]` abandons `customArtifactType*` vocabulary + `CustomArtifactTypeId` | Inconsistent | consumer contracts | High |
| F6 | Artifact type typed `string`, discarding `ArtifactKey`/`ArtifactType` | Inconsistent | consumer contracts | High |
| F9 | 8 advertised error kinds, 3 emitted; `not-found` unreachable by the file's own rule | Inconsistent | error consistency | High |
| F10 | Two storages behind one `StateStorage` differ in synchrony and failure behavior | Inconsistent | error consistency | High |
| F11 | SSR guard omitted, unlike sibling `evidenceStore` | Inconsistent | consumer contracts | Medium |
| F7 | `SourceRef` fields unprefixed vs `SourceDocument` | Minor | naming vs neighbors | Medium |
| F8 | `CorpusErrorKind` names a payload union, not a kind | Minor | naming vs neighbors | Medium |
| F12 | `evidenceStore` duplicate adapter, not behind the seam | Minor | consumer contracts | High |
| F13 | `toWorkerError`/`isCorpusWorkerError` asymmetry; unprefixed `assertNever` | Minor | naming vs neighbors | Medium |
| F14 | `title`-vs-`slug` parameter naming; `safeSegment` case asymmetry | Minor | naming / idempotency | High |
| F19 | `parseManifest` null, `readdir` absence, `walkDir` non-null assertion | Minor | nullability | High |
| F15 | `SETTINGS_PATH` const among all-function exports | Informational | asymmetries | High |
| F16 | Unversioned flag key; `NEXT_PUBLIC_` env vs unenforced "DEV-ONLY" | Informational | naming / consumer contracts | High |
| F17 | `interface` for data records where siblings use `type` | Informational | naming vs neighbors | Medium |
| F18 | `kind` discriminant vs `SessionScope`'s `type` | Informational | naming vs neighbors | Low |

**Counts:** Breaking 0 · Inconsistent 9 · Minor 6 · Informational 4 · **Total 19**

---

### Overall Assessment

The new corpus surface is internally coherent and unusually well documented — `CorpusFS` is correctly scoped, `CorpusError` is a clean upgrade of the app's one existing error precedent, and the path-builder module has a predictable naming scheme. There are **no Breaking findings**: the flag defaults OFF, the localStorage path was moved verbatim and is pinned by a characterization test, and no existing consumer contract changes in this range.

The consistency problems cluster into two groups. The first is **vocabulary drift at the boundary with the existing app** — F4, F5, F6, F7 all describe the same failure mode: the corpus layer re-invents names and types for concepts the app already has settled names and unions for (`currentVersionIndex`, `customArtifactTypes`, `ArtifactKey`, `SourceDocument`). None of these hurt today because nothing consumes the manifest yet; all of them become S4 migration work, and F4 in particular (same word, opposite base) is the kind of divergence that produces a silent wrong-revision read rather than a crash. Fixing these four now is cheap and shrinks S4.

The second group is **documentation that overstates the contract the code implements** — F1 (sole path choke point, violated by the first consumer), F2 (fail-loud, implemented as coercive), F9 (eight kinds, three emitted, one unreachable by the adjacent rule), F16 (DEV-ONLY, unenforced). Each doc block is otherwise excellent and clearly written to guide later sub-tasks, which is exactly why the overstatements matter: S2/S3/S4 authors will read these headers as the specification. The correct fix for most of them is to narrow the claim to what S0/S1 actually delivers, not to expand the implementation.

Recommended pre-S2 order: F1 (add `statePath`, document `state/`), F4/F5/F6 (align vocabulary before anything consumes the manifest), F3 (version check), F9 (narrow the kind set), F2 (reconcile the codec doc with B7). The remainder can ride along with S2.

---

## Goal-Alignment Note

- **Answered:** Whether the new public contracts (`CorpusFS`, `CorpusError`/`CorpusErrorKind`, `WorkspaceManifest` + fields, `paths.ts` exports, the flag exports, and the `storeAdapter` exports) match the conventions already established in `app/lib/types/*`, `app/lib/stores/*`, `app/lib/utils/workspacePersistence.ts`, and `app/lib/llm/callLlm.ts`; whether the `workspaceStore` storage seam preserves its consumer contract; whether error shapes, serialize/deserialize field sets, nullability, and idempotency are internally consistent. Baseline drawn from 5+ sibling modules (B1–B13); full name-pattern audit over all 28 new exported names plus manifest fields, ordered exported-types → exported-functions → fields.
- **Out of scope:** Security of the traversal guard in `workspaceSlug`/`safeSegment` (deferred to `security-reviewer` — noted only where it bears on the F1 path-vocabulary split). Performance of the OPFS adapter's per-call `getRoot()` handle walk (deferred to `performance-reviewer`). Module-boundary and dependency-direction questions raised by `app/lib/stores/workspaceStore.ts` importing `app/lib/corpus/storeAdapter.ts` (deferred to `architecture-review`). Test coverage adequacy of the six new test files (deferred to `test-strategy`). Re-verification of any behavior established by the merged code fact-check — those findings are foundation and were cited, not re-derived. Files outside `app/` and commits outside `dc6dfb0..2dc403e`.
- **Escalate:** F4 (`currentVersion` 1-based vs `currentVersionIndex` 0-based) is the single finding most likely to cause a silent data defect rather than a legibility cost, and it is cheapest to fix now while nothing consumes `ArtifactPointer`. F1 and F9 each represent a documented contract that a later sub-task will build against and that the current code does not honor — both warrant a decision (narrow the doc, or fix the code) before S2 begins rather than a deferred TODO. F16's unenforced "DEV-ONLY" is worth a product call: `NEXT_PUBLIC_CORPUS_FS` is a production-capable switch guarding a path that the flag's own comment says starts from an empty corpus.
