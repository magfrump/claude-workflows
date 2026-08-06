# API Consistency Review — corpus-clean (dc6dfb0..4de2b00, app/ only)

**Scope:** `git diff dc6dfb0..4de2b00 -- app/` — 15 files, +1226/−33. New public surface: `app/lib/corpus/{types,flag,paths,manifest,opfsAdapter,storeAdapter}.ts` plus the test-side contract harness (`__tests__/{corpusFsContract,inMemoryCorpusFs}.ts`), and one modified live consumer (`app/lib/stores/workspaceStore.ts`). `docs/**` is context, not under review.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3). Findings there are treated as established and are not re-verified: the A1 `customTypeIds`→`customArtifactTypeIds` rename is total with zero stale refs; A2 gives `stateBlobPath` a single path source; the manifest codec still silently filters malformed array elements and defaults `label`; `CorpusErrorKind` still carries unproducible members; the `workspaceStore.ts:498` "typed as `CorpusFS`" comment describes a `StateStorage` seam; the "debounced" header claim does not hold on the corpus path.
`Commit: 4de2b00`

---

### Baseline Conventions

Sampled siblings: `app/lib/types/artifactStore.ts`, `app/lib/types/customArtifact.ts`, `app/lib/types/persistence.ts`, `app/lib/types/session.ts`, `app/lib/types/decomposition.ts`, `app/lib/utils/workspacePersistence.ts`, `app/lib/llm/callLlm.ts`.

| Convention | Established shape | Where |
|---|---|---|
| Type/interface names | PascalCase, domain-prefixed nouns (`ArtifactRecord`, `CustomArtifactTypeDefinition`, `PersistedWorkspace`) | `artifactStore.ts`, `customArtifact.ts`, `persistence.ts` |
| Acronyms inside identifiers | Capitalized-first, not all-caps: `PanelId`, `CustomArtifactTypeId`, `fetchApi`, `isPdfTexCompiled` | `panels.ts:3`, `customArtifact.ts:11`, `hooks/useEvidenceSearch.ts:6` |
| Module-level constants | `SCREAMING_SNAKE_CASE`; storage keys carry a version suffix | `WORKSPACE_KEY = "workspace-v2"` (`persistence.ts:5`), `WORKSPACE_SESSIONS_KEY = "workspace-sessions-v1"` (`workspaceSession.ts:4`), `MAX_VERSIONS` (`artifactStore.ts:37`) |
| Identity fields on a document-ish record | Entity-qualified: `sourceId`, `sourceLabel`, `nodeId`, `nodeLabel` | `decomposition.ts:52-56`, `session.ts:6` |
| Artifact type values | Branded union `ArtifactType = BuiltinArtifactType \| CustomArtifactTypeId`; records bind to it, never to bare `string` | `session.ts:21`, `artifactStore.ts:13,24`; `NodeArtifact.type` (`decomposition.ts:59`) |
| Version pointers | 0-based index into an array: `currentVersionIndex: number // pointer into versions[]` | `artifactStore.ts:25` |
| Persisted-payload version gating | Compare against the constant and reject on mismatch: `if (parsed.version !== WORKSPACE_VERSION) return null;` | `workspacePersistence.ts:206` |
| Persisted-payload failure mode | Return `null` on absent/wrong-version/malformed; coerce field-by-field | `workspacePersistence.ts:196-211` |
| Factory functions | `create<Thing>()` returning the interface, not a class | `createDebouncedStorage` (pre-diff `workspaceStore.ts`), `createObjectURL` usage in `export.ts` |
| Type guards | `is<Thing>(v): v is Thing` | `isCustomType` (`customArtifact.ts:33`), `isValidCustomTypeDef` (`workspacePersistence.ts:121`) |
| Module packaging | No barrel files anywhere under `app/` (`rg --files -g 'app/**/index.ts'` → empty); consumers import concrete module paths via the `@/app/...` alias | repo-wide |
| Feature flags | **None exist.** No `NEXT_PUBLIC_*` reference outside this diff; no prior `isXEnabled()` gate | repo-wide grep |

The corpus module follows the factory, type-guard, PascalCase, SCREAMING_SNAKE, and no-barrel conventions cleanly. The divergences are concentrated in three places: the manifest's field vocabulary versus the store's, the error model's advertised-versus-producible gap, and the storage seam's two incompatible behavioral contracts.

---

### Name-Pattern Audit

Ordered most-public first (types a future S2/S3/S4 consumer must bind to → path builders → adapters → test harness). 40 names audited.

| Name | Kind | Verdict | Note |
|---|---|---|---|
| `CorpusFS` | interface | ⚠️ casing | Sibling acronyms are `Id`/`Api`, not `ID`/`API` (`PanelId`, `fetchApi`). All-caps `FS` is the outlier — and the module's own factories spell it `Fs`. See F13. |
| `CorpusFS.readFile / writeFile / readdir / rm / stat` | methods | ✅ | Matches POSIX/`node:fs` naming that any TS reader already holds. `readdir` (lowercase d) is the `node:fs` spelling; consistent. |
| `CorpusStat` | interface | ✅ | Return-shape noun, matches `CorpusFS.stat`. |
| `CorpusError` | class | ✅ | `Error` subclass with `name = "CorpusError"`; first `Error` subclass in `app/lib/`. |
| `CorpusErrorKind` | union | ⚠️ | Name says "kind" but the type is the full discriminated *payload* union, not the kind literal set. `CorpusError.detail: CorpusErrorKind` reads oddly. No precedent for discriminated-error unions in the repo. Informational only; see F6 for the substantive issue. |
| `CorpusSubstrate` | union | ✅ | Substrate-neutral, extensible; justified in-line. |
| `CorpusWorkerError` / `toWorkerError` / `isCorpusWorkerError` | type + fns | ✅ | Guard follows `is<Thing>` precedent (`isCustomType`). |
| `describeCorpusError` | fn | ✅ | Verb-first, domain-prefixed. |
| `assertNever` | fn | ⚠️ | Generic TS utility with no corpus prefix exported from `corpus/types.ts`. No precedent in `app/lib/` (repo has no exhaustiveness helper). Belongs in `app/lib/utils/`. Informational. |
| `WorkspaceManifest` | interface | ✅ | Reads against `PersistedWorkspace` cleanly. |
| `WorkspaceManifest.manifestVersion` | field | ✅ name / ⚠️ behavior | Naming matches `PersistedWorkspace.version` + `WORKSPACE_VERSION`; not gated on parse. F10. |
| `WorkspaceManifest.customArtifactTypeIds` | field | ✅ | A1 rename landed. Aligns with `CustomArtifactTypeId` (`customArtifact.ts:11`) and `PersistedWorkspace.customArtifactTypes`. Vocabulary now consistent; only the element *type* is off (F5). |
| `WorkspaceManifest.title / createdAt / updatedAt` | fields | ✅ | `createdAt`/`updatedAt` ISO-string pair matches `CustomArtifactTypeDefinition` (`customArtifact.ts:28-29`) and `FormalizationSession` (`session.ts:34-35`). |
| `ArtifactPointer` | interface | ✅ name | Distinct from `ArtifactRecord`, correctly signalling "pointer not payload". |
| `ArtifactPointer.type` | field | ⚠️ | Typed `string`, not `ArtifactType`. F5. |
| `ArtifactPointer.currentVersion` | field | ❗ | Collides semantically with `ArtifactRecord.currentVersionIndex`. F3. |
| `SourceRef` | interface | ⚠️ | vs `SourceDocument` (`decomposition.ts:52`). F4. |
| `SourceRef.id / label` | fields | ❗ | vs `sourceId` / `sourceLabel`. F4. |
| `SourceRef.ext` | field | ✅ | No precedent; new concept (bytes-on-disk), abbreviation is idiomatic. |
| `MANIFEST_VERSION` | const | ✅ | Precedent: `WORKSPACE_VERSION = 2` (`persistence.ts:4`). |
| `createManifest` / `serializeManifest` / `parseManifest` | fns | ✅ | Codec verb pair `serialize`/`parse` is internally symmetric. Behavior is not (F9). |
| `SETTINGS_PATH` | const | ⚠️ | Only path constant with no codec, no type, and no caller. F20. |
| `STATE_DIR` | const | ✅ | `_DIR` vs `_PATH` suffixes correctly distinguish directory from file. |
| `stateBlobPath` | fn | ✅ | Sole exception to the `(slug, …)` signature shape, correctly — the state blob is not per-workspace, and the doc-comment says so. A2 fix is well-named and greppable. |
| `workspaceDir` / `workspaceManifestPath` / `artifactDir` / `artifactMetaPath` / `decompositionDir` / `decompositionGraphLayoutPath` / `sourcePath` / `customTypePath` / `artifactVersionPath` | fns | ⚠️ one | Uniform `<thing>Dir` / `<thing>Path` pattern, `(slug, …)` first arg. `customTypePath(slug, customTypeId)` is the lone survivor of the pre-A1 vocabulary. F12. |
| `workspaceSlug` / `safeSegment` | fns | ✅ | Both idempotent; `safeSegment` correctly preserves case where `workspaceSlug` lowercases, and each documents why. |
| `CORPUS_FLAG_KEY` | const | ⚠️ | Value `"corpus-fs-enabled"` unversioned against `"workspace-v2"` / `"workspace-sessions-v1"`. F14. |
| `isCorpusEnabled` | fn | ✅ | `is<Thing>` precedent holds even though it is a predicate on environment, not a type guard. |
| `NEXT_PUBLIC_CORPUS_FS` | env var | ✅ (no precedent) | **No existing precedent in `app/` and `app/lib/`** — first feature flag in the codebase. Token set differs from the localStorage key (`CORPUS_FS` vs `corpus-fs-enabled`), but with nothing to be consistent *with*, severity floors to Informational. |
| `createOpfsCorpusFs` | fn | ⚠️ | `Fs` here, `FS` in the interface it returns. F13. |
| `createDebouncedLocalStorage` | fn | ✅ | Rename from the private `createDebouncedStorage` adds the substrate, which is right now that a second substrate exists. |
| `createCorpusBackedStorage` | fn | ✅ | Parallel to `createDebouncedLocalStorage`; `<substrate>-backed` is a clear pairing. |
| `resolveWorkspaceStorage` | fn | ✅ | `resolve` (not `create`) correctly signals selection rather than construction. |
| `defineCorpusFsContract` | fn | ✅ | `Fs` casing again, but matches the file it lives in (`corpusFsContract.ts`); `define<X>Contract` is a standard shared-suite idiom. |
| `createInMemoryCorpusFs` | fn | ✅ | Parallel to `createOpfsCorpusFs`; substrate-in-name pattern held. |

---

### Findings

#### F1. `onRehydrateStorage` bypasses the storage seam it was just given, with a duplicated key literal

**Severity:** Breaking
**Location:** `app/lib/stores/workspaceStore.ts:533-537` (in-range context; the seam change at :493-499 is what makes it load-bearing)
**Move:** (3) consumer contracts
**Confidence:** High — behavior is directly readable from the two lines; the flag gate limits blast radius to the ON path.

**Evidence:**
```ts
      name: "workspace-zustand-v1",
      // Storage seam is selected here (DD-009 S1): debounced localStorage by
      // default, or a CorpusFS-backed adapter when the dev flag is on.
      storage: createJSONStorage(resolveWorkspaceStorage),
...
          if (typeof window !== "undefined" && localStorage.getItem(WORKSPACE_KEY)) {
            const zustandRaw = localStorage.getItem("workspace-zustand-v1");
```

**Legibility-target:** The abstraction's implicit invariant — "persisted store state lives wherever `storage` says it lives" — is violated one screen below the line that introduces the abstraction, and the violation is invisible because it reads a *string literal* rather than the `name` field.

The diff introduces a storage seam whose whole purpose is that the store no longer knows its substrate, but `onRehydrateStorage` reaches around it and asks `localStorage` directly whether persisted zustand state exists. Before this diff that read was sound, because the seam and the direct read were always the same substrate; the new abstraction silently breaks the invariant it depends on. On the corpus path `localStorage.getItem("workspace-zustand-v1")` is unconditionally `null`, so `hasZustandData` is `false` and `migrateFromV2()` fires on every rehydrate whenever a legacy `workspace-v2` blob exists — overwriting whatever the corpus just loaded with legacy data, on every reload. The duplicated `"workspace-zustand-v1"` literal is the mechanism that hid this: had the code read `name`, the coupling would at least have been greppable from the persist config.

**Recommendation:** Route the probe through the same seam (`await resolveWorkspaceStorage().getItem(WORKSPACE_STORE_KEY)`), or gate the whole legacy-migration branch on `!isCorpusEnabled()` since S1 explicitly has no migration story. Either way, hoist `"workspace-zustand-v1"` to an exported constant next to `WORKSPACE_KEY` in `app/lib/types/persistence.ts` — the existing precedent for named store keys — so the two references cannot drift.

---

#### F2. One `StateStorage` type, two incompatible failure and timing contracts

**Severity:** Inconsistent
**Location:** `app/lib/corpus/storeAdapter.ts:28-49` vs `:55-71`, selected by `:74-79`
**Move:** (4) error consistency — adapter synchrony/failure asymmetry
**Confidence:** High

**Evidence:**
```ts
      pending = setTimeout(() => {
        try {
          localStorage.setItem(name, value);
        } catch (e) {
          console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
        }
```
versus
```ts
    setItem: async (name, value) => {
      await fs.writeFile(pathFor(name), enc.encode(value));
    },
```

**Legibility-target:** `resolveWorkspaceStorage(): StateStorage` presents one type where the caller actually receives one of two objects that differ on failure semantics, write timing, and write volume — none of which the type expresses.

Both branches satisfy `StateStorage`, but they agree on nothing a caller would care about. The localStorage branch swallows quota failure into a `console.warn` and coalesces writes on a 300 ms debounce; the corpus branch rejects with a `CorpusError` (`opfsAdapter.ts:90`) and writes on every `setItem`. `createJSONStorage` does not attach a rejection handler, so on the corpus path an OPFS quota exhaustion surfaces as an unhandled promise rejection in a code path whose established contract — set by the very adapter sitting above it in the same file — is "persistence failures are warnings, not exceptions." The module docstring at `storeAdapter.ts:26` ("Reads are synchronous (instant); writes are debounced by 300ms") is scoped to the default branch but sits close enough to the shared return type to read as a property of the seam; per the fact-check the "debounced" framing does not hold on the corpus path. This is exactly the asymmetry the failure-driven-UI mandate in `types.ts:37-39` exists to prevent, applied everywhere except the one seam a live consumer binds to.

**Recommendation:** Make the contract uniform at the seam. Wrap `createCorpusBackedStorage`'s `setItem` in the same catch-and-report shape (or, better, route both through a shared `onPersistFailure(err)` callback so the eventual failure-driven UI has one hook), and give the corpus branch the same debounce. If the divergence is intentional for S1, say so in `resolveWorkspaceStorage`'s docstring — it is the only place a reader can learn which object they got.

---

#### F3. `ArtifactPointer.currentVersion` is 1-based; the store's `currentVersionIndex` is 0-based

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:23-28` vs `app/lib/types/artifactStore.ts:23-27`
**Move:** (3) consumer contracts
**Precedent:** `currentVersionIndex: number // pointer into versions[]` used in `app/lib/types/artifactStore.ts:25`
**Confidence:** High

**Evidence:**
```ts
/** Pointer to the current version of one artifact type. `currentVersion` is the
 *  1-based version number whose file is artifacts/<type>/v####.md. */
export interface ArtifactPointer {
  type: string;
  currentVersion: number;
}
```

**Legibility-target:** Two `number` fields in the same domain, six characters apart in name, differing by exactly one — the most reliably mis-transcribed shape in a migration.

The baseline is `ArtifactRecord.currentVersionIndex`, a 0-based pointer into `versions[]`. The manifest introduces `currentVersion`, a 1-based file ordinal matching `artifactVersionPath`'s `version < 1` guard (`paths.ts:106`). Both choices are individually right — array indices are 0-based, `v0001.md` is 1-based — but S4's migration must convert between them, and the only signal that a conversion is required is the six-character suffix difference. Nothing consumes `ArtifactPointer` today, so no client breaks now; the cost lands entirely on the S4 author, who will read `currentVersion` and `currentVersionIndex` in adjacent lines and has one chance to notice.

**Recommendation:** Rename to `currentVersionNumber`, or keep the name and add a converter pair in `manifest.ts` (`pointerFromRecord` / `recordIndexFromPointer`) so the ±1 lives in exactly one tested place rather than at every future call site. A one-line cross-reference in each type's doc-comment naming the other is the cheap floor.

---

#### F4. `SourceRef` uses `id`/`label` where the codebase's source vocabulary is `sourceId`/`sourceLabel`

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:30-35`
**Move:** (2) naming vs neighbors, (3) consumer contracts
**Precedent:** `sourceId` / `sourceLabel` used in `app/lib/types/decomposition.ts:52-56` (`SourceDocument`) and again on `PropositionNode.sourceId` (`decomposition.ts:72`); persisted as `PersistedDecomposition.sources: SourceDocument[]` (`persistence.ts:12`)
**Confidence:** High

**Evidence:**
```ts
export interface SourceRef {
  id: string;
  label: string;
  /** File extension (no dot) of the stored source bytes under sources/. */
  ext: string;
}
```

**Legibility-target:** The manifest and the persisted store describe the same user-visible objects — the sources in a workspace — using two disjoint field vocabularies, so the S4 migration is a rename table rather than a spread.

`SourceDocument { sourceId, sourceLabel, text }` is the established shape and it is what `PersistedDecomposition.sources` holds today; `PropositionNode.sourceId` already binds to that key. `SourceRef { id, label, ext }` is the same entity with the bytes moved to a file, but every field that survives the move is renamed. The unqualified `id`/`label` also lose the property that makes `sourceId` greppable across `decomposition.ts`, `graphOperations.ts`, and the hooks. The `ext` field is genuinely new and correctly named.

**Recommendation:** Rename to `sourceId` / `sourceLabel` so `SourceRef` is a structural subset of `SourceDocument` minus `text` plus `ext`, making S4's migration `({ sourceId, sourceLabel }) => ({ sourceId, sourceLabel, ext })`. If the shorter names are deliberate (they are namespaced by the containing type), say so in the doc-comment and add the mapping note.

---

#### F5. The manifest widens branded artifact-type values back to bare `string`

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:26` (`type: string`), `:44` (`customArtifactTypeIds: string[]`), `:101`, `:105-107`
**Move:** (3) consumer contracts — bare-string artifact types vs branded types
**Precedent:** `ArtifactKey = Exclude<ArtifactType, "semiformal" | "lean">` on `ArtifactRecord.type` (`app/lib/types/artifactStore.ts:13,24`); `NodeArtifact.type: ArtifactType` (`decomposition.ts:59`); `CustomArtifactTypeId = \`custom-${string}\`` (`customArtifact.ts:11`); `customArtifactTypes?: CustomArtifactTypeDefinition[]` (`persistence.ts:34`)
**Confidence:** High

**Evidence:**
```ts
export interface ArtifactPointer {
  type: string;
  currentVersion: number;
}
...
  customArtifactTypeIds: string[];
```

**Legibility-target:** The A1 rename aligned the manifest's field *names* with the store's vocabulary; the field *types* were not brought along, so the alignment is cosmetic at the type level.

Every artifact-type-carrying field elsewhere in `app/lib/` binds to the branded union — that is what makes `isCustomType` (`customArtifact.ts:33`) a type guard rather than a string test, and what makes exhaustive switches over artifact types compile-checked. `ArtifactPointer.type: string` and `customArtifactTypeIds: string[]` opt out, so a manifest can carry `type: "casual-graph"` and typecheck. This is doubly odd next to `CorpusErrorKind`, whose entire justification (`types.ts:37-39`) is that widening a union costs compile-time exhaustiveness — the module argues the case for branded unions in one file and abandons it in the next. The `parseManifest` casts at `:101` (`a.type as string`) and the `filter((x): x is string => …)` at `:106` are where the branding would have been enforced at the boundary.

**Recommendation:** Type `ArtifactPointer.type` as `ArtifactType` and `customArtifactTypeIds` as `CustomArtifactTypeId[]`, and have `parseManifest` validate on the way in — `isCustomType` already exists for the second, and the first needs a `BuiltinArtifactType` membership check. If `manifest.ts` must stay dependency-free of `app/lib/types/`, document that as the reason, because a reader's first assumption will be oversight.

---

#### F6. `CorpusErrorKind` advertises five kinds no code in the module can produce

**Severity:** Inconsistent
**Location:** `app/lib/corpus/types.ts:41-49`; producers at `opfsAdapter.ts:53, 65, 69, 90, 91` and `manifest.ts:69`
**Move:** (4) error consistency — producible vs advertised
**Confidence:** High (fact-check established; grep for `"not-found"` across `app/` returns only the declaration at `types.ts:42` and the `describeCorpusError` case at `:80` — no constructor site)

**Evidence:**
```ts
export type CorpusErrorKind =
  | { kind: "not-found"; path: string }
  | { kind: "quota-exceeded"; substrate: CorpusSubstrate; needed?: number; available?: number }
  | { kind: "unavailable"; reason: string } // e.g. SSR / no navigator.storage
  | { kind: "io"; path: string; reason: string }
  | { kind: "fsa-permission-revoked" }
  | { kind: "remote-auth-expired" }
  | { kind: "browser-storage-cleared" }
  | { kind: "git-conflict"; path: string };
```

**Legibility-target:** The type is documented as "the complete set of corpus failure kinds" and used as a compile-time forcing function, so a consumer writing an exhaustive switch has no way to tell that 5/8 arms are currently dead and 3/8 are live.

Only `quota-exceeded`, `unavailable`, and `io` are constructed anywhere in the diff. `fsa-permission-revoked` (S2), `remote-auth-expired`, `browser-storage-cleared`, and `git-conflict` (S3) are forward declarations for sub-tasks that have not landed — defensible, and arguably the point of centralizing the kind set. `not-found` is different: it is structurally unreachable by design, because `CorpusFS`'s own contract (`types.ts:18`) resolves missing paths to `null`/`[]` rather than erroring. It cannot become producible without changing the interface contract. The cost is real and immediate: `describeCorpusError` and every consumer switch must carry five arms that cannot fire, and the failure-driven-UI work in a later sub-task will build five branches of UI against kinds it cannot exercise in a test.

**Recommendation:** Delete `not-found` — it contradicts the interface's null-for-missing contract and nothing can produce it. For the four forward-declared kinds, add a `// S2` / `// S3` marker per line (the `unavailable` line already models this with its `// e.g. SSR` comment) so a consumer can see at a glance which arms are live today.

---

#### F7. The shared contract suite covers only the success half, and the two implementations disagree on the other half

**Severity:** Inconsistent
**Location:** `app/lib/corpus/__tests__/corpusFsContract.ts:21-80`; divergence between `inMemoryCorpusFs.ts:13-15,44-46` and `opfsAdapter.ts:58-71,148-163`
**Move:** (7) asymmetries
**Confidence:** High

**Evidence:**
```ts
 * the fake and the adapter are held to identical behavior (substitutability).
```
against the fake's entire path handling:
```ts
function normalize(path: string): string {
  return path.replace(/^\/+|\/+$/g, "");
}
```

**Legibility-target:** The suite's docstring makes a substitutability claim ("held to identical behavior") that the suite's seven cases do not test, and the two implementations in fact diverge on at least two observable behaviors.

`defineCorpusFsContract` asserts null-for-missing, byte round-trip, implicit directory creation, `rm` idempotency, the 30-file access pattern, and overwrite — all success paths. Nothing asserts the error contract. The implementations diverge accordingly: `opfsAdapter.splitPath` rejects `.`, `..`, and backslash segments with `CorpusError{kind:"io"}` (`:63-67`), while the fake normalizes only leading/trailing slashes and will happily store and return `"../../etc/passwd"` — so a test that passes against the fake proves nothing about the adapter's guard, which is the guard that matters. Second divergence: `rm` on a directory path is a silent no-op in the fake (`Map.delete` misses) but reaches `removeEntry(name)` without `recursive` in the adapter, which throws for a non-empty directory and is wrapped as `io`. `CorpusFS.rm`'s doc (`types.ts:121`) says "Removes a file" and specifies idempotency for missing paths but is silent on directories, so neither implementation is wrong — the contract just doesn't say.

**Recommendation:** Add error-contract cases to `defineCorpusFsContract`: unsafe-segment paths reject with `CorpusError{kind:"io"}`; `rm` on a directory path has a specified outcome. Then port `splitPath`'s validation into the fake so it can pass them. Also specify the directory case in `CorpusFS.rm`'s doc-comment — the contract suite can only enforce what the interface states.

---

#### F8. `readdir` is the one `CorpusFS` method that skips the traversal guard

**Severity:** Inconsistent
**Location:** `app/lib/corpus/opfsAdapter.ts:137` vs `:58-71` used by `:99, 119, 151, 168`
**Move:** (7) asymmetries
**Confidence:** High

**Evidence:**
```ts
    async readdir(path) {
      try {
        const root = await getRoot();
        const dirs = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
```
against the guard the other four methods get:
```ts
  for (const seg of parts) {
    if (seg === "." || seg === ".." || seg.includes("\\")) {
      throw new CorpusError({ kind: "io", path, reason: `unsafe path segment: ${seg}` });
```

**Legibility-target:** `splitPath` is documented as defense-in-depth for callers who bypass `paths.ts`, but four of five entry points enforce it and the fifth open-codes a split that omits the check — a shape that reads as complete at a glance.

`readdir` needs a directory-only split rather than dir+name, which is why it doesn't call `splitPath`; the consequence is that its inlined split drops the segment validation. `readdir("workspaces/../secrets")` therefore reaches `getDirectoryHandle("..")`, whose failure mode is browser-dependent and gets wrapped as a generic `io` error rather than the specific `unsafe path segment` message the other methods produce. The practical exposure is small — OPFS is origin-scoped and `paths.ts` is the only sanctioned path source — but the *inconsistency* is the finding: a reader auditing the guard will see it referenced in `splitPath` and reasonably conclude all five methods are covered.

**Recommendation:** Extract the segment check into `assertSafeSegments(path, parts)` and call it from both `splitPath` and `readdir`, so the guard has one definition and five call sites.

---

#### F9. `parseManifest` silently drops malformed array elements, contradicting its own fail-loud contract and breaking round-trip symmetry

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:89-107`; contract stated at `:10-16`
**Move:** (7) asymmetries — serialize/parse field sets
**Confidence:** High (fact-check established the residual docstring overstatement)

**Evidence:**
```ts
  const sources: SourceRef[] = Array.isArray(raw.sources)
    ? raw.sources.filter(isObject).map((s) => {
        if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");
        return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
      })
```

**Legibility-target:** The A4 docstring fix moved the claim from wrong to nearly-right — "every content field (title, sources, artifacts, customArtifactTypeIds) fails loud if missing or malformed" is true at the *field* level and false at the *element* level, and the gap is exactly where data loss hides.

`serializeManifest` emits every element of `sources`, `artifacts`, and `customArtifactTypeIds`; `parseManifest` filters non-objects out of the first two (`.filter(isObject)`) and non-strings out of the third (`.filter((x): x is string => …)`) before validating what survives. A manifest with three sources, one of which is `null` after a partial write, parses successfully with two — no error, no warning, no count check. Same for a `customArtifactTypeIds` entry that arrives as a number. That is precisely the "silent default that masquerades as *this workspace has no work in it*" the docstring at `:11-14` says the codec exists to prevent, applied one level down. The `label` default (`typeof s.label === "string" ? s.label : s.id`) is a third instance: a content field silently substituting, where the docstring reserves defaulting for timestamps only.

**Recommendation:** Replace the filters with per-element `fail()` calls — `raw.sources.map((s, i) => { if (!isObject(s)) fail(\`sources[${i}] is not an object\`); … })` — so element-level malformation surfaces as the same typed `CorpusError` as field-level malformation. Either make `label` required or move it into the documented "metadata, may default" set alongside the timestamps.

---

#### F10. `parseManifest` never checks `manifestVersion` against `MANIFEST_VERSION`

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:87, 110`
**Move:** (3) consumer contracts
**Precedent:** `if (parsed.version !== WORKSPACE_VERSION) return null;` in `app/lib/utils/workspacePersistence.ts:206`
**Confidence:** High

**Evidence:**
```ts
  if (typeof raw.manifestVersion !== "number") fail("missing required field: manifestVersion");
...
    manifestVersion: raw.manifestVersion,
```

**Legibility-target:** The field is named and constant-backed exactly like the codebase's existing versioned payload, which sets the expectation that it is *gated* like it too — but it is only type-checked and then echoed through.

`workspacePersistence.loadWorkspace` establishes the pattern: compare the payload's version to the module constant and refuse on mismatch. `parseManifest` declares `MANIFEST_VERSION = 1` (`:21`), uses it in `createManifest` (`:49`), and then accepts a manifest claiming `manifestVersion: 7` without comment — returning a `WorkspaceManifest` typed as current while carrying a future schema's field semantics. Since the codec is fail-loud by design elsewhere, silently accepting an unknown schema version is the least consistent option available: it neither fails loud (the module's own convention) nor returns null (the sibling's convention).

**Recommendation:** Add `if (raw.manifestVersion !== MANIFEST_VERSION) fail(\`unsupported manifestVersion: ${raw.manifestVersion}\`)`, or, if forward-compatibility is wanted, gate on `> MANIFEST_VERSION` and document the tolerated range. Either way the constant should be load-bearing on the read path.

---

#### F11. `paths.ts` throws bare `Error` inside a module whose stated contract is `CorpusError`

**Severity:** Minor
**Location:** `app/lib/corpus/paths.ts:44, 55, 107`
**Move:** (4) error consistency
**Precedent:** `CorpusError` used in `app/lib/corpus/{opfsAdapter,manifest,types}.ts`; contract stated at `app/lib/corpus/types.ts:18`
**Confidence:** High

**Evidence:**
```ts
  if (!slug) {
    throw new Error(`workspace title produced an empty slug: ${JSON.stringify(title)}`);
  }
```

**Legibility-target:** A consumer that wraps corpus work in `catch (e) { if (e instanceof CorpusError) … }` — the shape the module's error model invites — will silently miss three throw sites in the module's most-called file.

`types.ts:18` states "everything else rejects with a `CorpusError`", and `manifest.ts:67-70` follows it even for a validation failure that is not really I/O (`fail()` mints `{kind:"io"}` for a parse error). `paths.ts` does not. This is reachable from live code, not hypothetical: `createCorpusBackedStorage`'s `pathFor` calls `stateBlobPath` → `safeSegment` (`storeAdapter.ts:58`), so a store name that sanitizes to empty produces a bare `Error` from inside a `StateStorage.setItem` — a rejection type no corpus-aware handler will recognize.

**Recommendation:** Throw `new CorpusError({ kind: "io", path: <the input>, reason: … })` from all three sites. If a distinct kind is wanted for "caller passed an unusable name," add one to `CorpusErrorKind` — the module is explicitly designed for that (`types.ts:37-39`) and this is a better candidate for a new kind than several of the placeholders in F6.

---

#### F12. `customTypePath` / `customTypeId` retain the pre-A1 vocabulary

**Severity:** Minor
**Location:** `app/lib/corpus/paths.ts:117-119` (and the `custom-types/` literal at `:12, 118`)
**Move:** (2) naming vs neighbors
**Precedent:** `customArtifactTypeIds` used in `app/lib/corpus/manifest.ts:44,55,105,116`; `CustomArtifactTypeId` in `app/lib/types/customArtifact.ts:11`; `customArtifactTypes` in `app/lib/types/persistence.ts:34`
**Confidence:** High

**Evidence:**
```ts
export function customTypePath(slug: string, customTypeId: string): string {
  return `${workspaceDir(slug)}/custom-types/${safeSegment(customTypeId)}.json`;
}
```

**Legibility-target:** A1 established that the canonical noun phrase is "custom **artifact** type"; `paths.ts` is the one file in the new module still using the short form, so a grep for the canonical name misses the path builder for exactly these objects.

The A1 fix renamed the manifest field and aligned it with `CustomArtifactTypeId` and `PersistedWorkspace.customArtifactTypes`, so the vocabulary is now consistent across `manifest.ts` and `app/lib/types/`. `customTypePath(slug, customTypeId)` — the function that writes these very objects to disk — was outside that rename's blast radius and kept the ambiguous short form. `isCustomType` in `customArtifact.ts:33` uses the short form too, so there is a partial counter-precedent; but that predates A1, and A1's whole premise was that the short form is the one being retired.

**Recommendation:** Rename to `customArtifactTypePath(slug, customArtifactTypeId)`. The on-disk directory name `custom-types/` is a separate question — changing it is a data-format change, so either leave it and note the intentional divergence in the layout comment at `:12`, or fold it into S4's migration.

---

#### F13. `CorpusFS` vs `createOpfsCorpusFs` — the same acronym, two casings, in the same module

**Severity:** Minor
**Location:** `app/lib/corpus/types.ts:112` vs `opfsAdapter.ts:94`, `__tests__/inMemoryCorpusFs.ts:17`, `__tests__/corpusFsContract.ts:14`
**Move:** (2) naming vs neighbors
**Precedent:** Capitalized-first acronyms used in `app/lib/types/panels.ts:3` (`PanelId`), `app/lib/types/customArtifact.ts:11` (`CustomArtifactTypeId`), `app/hooks/useEvidenceSearch.ts:6` (`fetchApi`), `app/lib/utils/pdfPropositionParser.ts:429` (`isPdfTexCompiled`) — the codebase writes `Id`/`Api`/`Pdf`, never `ID`/`API`/`PDF`, inside identifiers
**Confidence:** High

**Evidence:** `export interface CorpusFS {` (`types.ts:112`) alongside `export function createOpfsCorpusFs(): CorpusFS {` (`opfsAdapter.ts:94`).

**Legibility-target:** Autocomplete and grep both split on casing, so `CorpusFs` finds the three factories and `CorpusFS` finds the interface — a reader searching for "everything corpus-FS" needs a case-insensitive search to get both halves.

The interface is `CorpusFS`; all three factories that return it spell it `CorpusFs`, as does the contract-suite file name and helper. The codebase's own convention across four sampled files is capitalized-first (`Id`, `Api`, `Pdf`), which points at `CorpusFs` as the consistent choice — but consistency *within the module* matters more than which side wins, and right now neither is applied uniformly.

**Recommendation:** Pick one and apply it to all five names. `CorpusFs` matches the repo's `Id`/`Api`/`Pdf` precedent and requires renaming only the interface (plus its ~10 references), all inside the new module.

---

#### F14. `CORPUS_FLAG_KEY` is the only unversioned localStorage key

**Severity:** Minor
**Location:** `app/lib/corpus/flag.ts:13`
**Move:** (2) naming vs neighbors
**Precedent:** `WORKSPACE_KEY = "workspace-v2"` in `app/lib/types/persistence.ts:5`; `WORKSPACE_SESSIONS_KEY = "workspace-sessions-v1"` in `app/lib/types/workspaceSession.ts:4`; store name `"workspace-zustand-v1"` in `app/lib/stores/workspaceStore.ts:495`
**Confidence:** Medium — the versioning convention is clear for *data* keys; whether it should extend to a boolean flag key is a judgment call.

**Evidence:**
```ts
export const CORPUS_FLAG_KEY = "corpus-fs-enabled";
```

**Legibility-target:** All three existing localStorage keys carry a `-vN` suffix so a schema change can coexist with the old value; the fourth does not, so the sharing convention is now "three out of four."

Every persisted key in the codebase is versioned, and `WORKSPACE_VERSION` / `loadWorkspace`'s version gate (`workspacePersistence.ts:206`) show why: the app expects to change a key's meaning and needs old values to be ignorable. A boolean flag is the weakest case for this — its value space is `"1"` or absent, and it is dev-only — so the omission is defensible. But `flag.ts:20` explicitly anticipates the flag's meaning changing at S4 ("Remove this guard only when S4 ships migration and the flag becomes a real, safe rollout knob"), which is exactly the situation versioning exists for. The key also shares the `workspace-*`-adjacent namespace without collision risk today.

**Recommendation:** Either add the suffix (`"corpus-fs-enabled-v1"`) or note in the doc-comment that the key is deliberately unversioned because it carries no schema. The second is fine; the current state just leaves a reader guessing.

---

#### F15. The flag doc-comment promises runtime toggling; the seam is resolved once

**Severity:** Minor
**Location:** `app/lib/corpus/flag.ts:9-10` vs `storeAdapter.ts:73-79` and `workspaceStore.ts:499`
**Move:** (9) idempotency
**Confidence:** High

**Evidence:**
```ts
 * Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1` or, at runtime
 * in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`.
```

**Legibility-target:** "at runtime" contrasted against "build-time env" in the same sentence reads as *live* — set the key, the corpus path engages — but zustand invokes the storage factory once at persist-middleware initialization.

`resolveWorkspaceStorage` is documented as "Selected once when the store's persist middleware initializes" (`storeAdapter.ts:73`), which is correct and is the right place for that note. The flag's own docstring — the file a developer opens when trying to turn this on — does not carry it, and the deliberate build-time/runtime contrast implies otherwise. The practical failure is a developer setting the key, seeing no change, and concluding the flag is broken. Related: `isCorpusEnabled` returns plain `false` under the production guard (`:21`), so "off" and "on but hard-refused" are indistinguishable to a caller — a developer testing a production build gets silence.

**Recommendation:** Append "requires a page reload — the storage seam is selected once at store initialization" to the flag docstring. Optionally have the production guard `console.warn` once when the flag was actually set, so the refusal is observable.

---

#### F16. `parseManifest` accepts a parameter value that is always an error

**Severity:** Minor
**Location:** `app/lib/corpus/manifest.ts:72-78`
**Move:** (8) nullability
**Precedent:** `CorpusFS.readFile(path): Promise<Uint8Array | null>` in `app/lib/corpus/types.ts:115`
**Confidence:** High

**Evidence:**
```ts
export function parseManifest(bytes: Uint8Array | null): WorkspaceManifest {
  if (bytes === null) fail("manifest file is absent");
```
with the doc-comment two lines above stating "passing `null` here is itself an error."

**Legibility-target:** The signature says `null` is an accepted input; the doc-comment says it is a caller bug — so the type invites the exact call (`parseManifest(await fs.readFile(p))`) that the prose forbids.

The widening exists to compose with `readFile`'s `Uint8Array | null`, which is a reasonable ergonomic motive — but the chosen resolution (accept, then always throw) gives the caller the worst of both: no compile-time push to handle absence, and a runtime throw that is indistinguishable from a corruption error since both arrive as `CorpusError{kind:"io"}`. A caller that wants to distinguish "no manifest yet, create one" from "manifest is corrupt" — the common case when opening a workspace — must string-match the `reason`.

**Recommendation:** Narrow to `parseManifest(bytes: Uint8Array)` and let TypeScript force the null check at the call site, or keep the widening and return `null` for the absent case so the two outcomes are separable by type rather than by message text.

---

#### F17. `workspaceDir(slug)` names its parameter `slug` but runs the title sanitizer on it

**Severity:** Minor
**Location:** `app/lib/corpus/paths.ts:87-89`, propagating to `:91-123`
**Move:** (2) naming vs neighbors, (9) idempotency
**Confidence:** Medium — behavior is safe (`workspaceSlug` is idempotent), the issue is that the signature misdescribes the accepted input.

**Evidence:**
```ts
export function workspaceDir(slug: string): string {
  return `workspaces/${workspaceSlug(slug)}`;
}
```

**Legibility-target:** `workspaceSlug(title)` and `workspaceDir(slug)` sit 40 lines apart and disagree about what the value is called at each stage, so it is unclear whether callers are expected to slugify first.

`workspaceSlug` is documented as taking a *title* and producing a slug; `workspaceDir` declares a *slug* parameter and then slugifies it again. Because `workspaceSlug` is idempotent (lowercase, collapse, trim — all fixpoints), both usages work, which is why this is Minor rather than a defect. The cost is ambiguity about the invariant: a caller cannot tell whether passing a raw title is supported (it is) or whether double-slugification is a bug being tolerated. Every downstream builder inherits the ambiguity through `workspaceDir`.

**Recommendation:** Either rename the parameter to `titleOrSlug` and state the idempotency guarantee in the doc-comment, or introduce a branded `type WorkspaceSlug = string & { __slug: true }` returned by `workspaceSlug` and required by `workspaceDir` — the module already reaches for branded-union discipline in `types.ts`, and this is the same move.

---

#### F18. `createManifest` accepts an injectable clock; `parseManifest` hardcodes one

**Severity:** Informational
**Location:** `app/lib/corpus/manifest.ts:47` vs `:112-113`
**Move:** (7) asymmetries
**Confidence:** High

**Evidence:**
```ts
export function createManifest(title: string, now = new Date().toISOString()): WorkspaceManifest {
```
against
```ts
    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
    updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : new Date().toISOString(),
```

**Legibility-target:** The two codec entry points make opposite choices about clock injection, so `parseManifest` is non-deterministic on the timestamp-defaulting path while its sibling is fully controllable.

`createManifest`'s `now` default parameter is a deliberate testability affordance. `parseManifest` has the same need — the timestamp defaults are the documented exception to fail-loud (`:14-15`) and a test asserting them must either freeze time or ignore the field — but takes no clock. The two calls also produce different values from each other for the same parse, since each invokes `new Date()` separately. Low impact; noted for symmetry.

**Recommendation:** Give `parseManifest` the same `now = new Date().toISOString()` parameter and use it for both defaults.

---

#### F19. `readdir` returns `[]` for both missing and empty directories, against the interface's null-for-missing convention

**Severity:** Informational
**Location:** `app/lib/corpus/types.ts:118-120`; behavior at `opfsAdapter.ts:139` and `inMemoryCorpusFs.ts:30-42`
**Move:** (8) nullability
**Confidence:** High — documented and deliberate; flagged as an internal inconsistency in the interface's own stated model.

**Evidence:**
```ts
 *  - "Not found" is `null` from `readFile`/`stat` and `[]` from `readdir`;
 *    everything else rejects with a `CorpusError`. Callers never see `undefined`.
```

**Legibility-target:** The interface states one absence convention with a carve-out in the same sentence, so "does this directory exist?" is answerable through `CorpusFS` for files but not for directories.

The choice is documented and defended (an empty array is the ergonomic result for the iteration that follows almost every `readdir`), and the contract suite pins it (`corpusFsContract.ts:26-28`). The consequence is that S4's migration — which must distinguish "this workspace folder has not been created" from "it exists but has no artifacts" — cannot get that answer from `readdir` alone and will need a `stat`-on-directory or a marker file, neither of which `CorpusFS` currently offers (`stat` is documented as file-only, `types.ts:123`).

**Recommendation:** No change to `readdir`. Consider whether `stat` should answer for directories (returning e.g. `{ size: 0 }` or a `type` discriminant), since S4 will need directory existence and the interface has no other way to express it. Worth deciding before S2/S4 bind to the current shape.

---

#### F20. `SETTINGS_PATH` is exported with no schema, codec, or caller

**Severity:** Informational
**Location:** `app/lib/corpus/paths.ts:68`
**Move:** (3) consumer contracts
**Precedent:** `workspaceManifestPath` (`paths.ts:91`) is paired with `WorkspaceManifest` + `parseManifest`/`serializeManifest` in `manifest.ts` — the established pairing for a JSON path constant in this module
**Confidence:** High

**Evidence:**
```ts
export const SETTINGS_PATH = "settings.json";
```

**Legibility-target:** Every other JSON path in the layout has a type and codec behind it; `settings.json` has a constant and a line in the layout diagram, so a reader cannot tell whether the schema is missing or the file is vestigial.

The layout comment at `:7` lists `settings.json` at the corpus root. Nothing in the diff defines what it contains, reads it, or writes it. As a placeholder for a later sub-task this is harmless — the constant costs nothing and reserving the name prevents drift — but it is the only exported name in the new public surface with no behavior attached.

**Recommendation:** Add a one-line marker (`/** S4: corpus-level settings; schema TBD. */`) matching the treatment `STATE_DIR` gets at `:70-81`, so its placeholder status is explicit rather than inferred from absence.

---

#### F21. Two seam-describing comments misstate the seam

**Severity:** Informational
**Location:** `app/lib/stores/workspaceStore.ts:496-498`; `app/lib/corpus/storeAdapter.ts:6-8, 26`
**Move:** (3) consumer contracts
**Confidence:** High (established by the merged fact-check; not re-verified)

**Evidence:**
```ts
      // Storage seam is selected here (DD-009 S1): debounced localStorage by
      // default, or a CorpusFS-backed adapter when the dev flag is on. The seam
      // is typed as CorpusFS so the S3 worker-proxy is a drop-in.
      storage: createJSONStorage(resolveWorkspaceStorage),
```

**Legibility-target:** The comment names the wrong interface at the exact line where a reader is trying to learn what the store binds to.

The seam at this line is `StateStorage` (zustand's), not `CorpusFS`; the `CorpusFS` injection point is `createCorpusBackedStorage(fs: CorpusFS)` one layer down (`storeAdapter.ts:55`). The architectural claim the comment is making — a worker proxy drops in without the store knowing — is true, but it is true *at `storeAdapter.ts:55`*, not here. The same conflation appears in `storeAdapter.ts:6-8`. Separately, the "debounced" framing in the module docstring (`:26`) describes only the localStorage branch, per F2.

**Recommendation:** Reword to "Storage seam (`StateStorage`) is selected here; the `CorpusFS` injection point that makes the S3 worker-proxy a drop-in is `createCorpusBackedStorage` in `corpus/storeAdapter.ts`." Two interfaces, named separately, each at its own layer.

---

#### F22. No barrel export for `app/lib/corpus/` — consistent with the repo

**Severity:** Informational
**Location:** `app/lib/corpus/` (absence)
**Move:** (2) naming vs neighbors
**Precedent:** **No existing precedent in `app/`** — `rg --files -g 'app/**/index.ts'` returns nothing; every consumer imports concrete module paths (e.g. `import { WORKSPACE_KEY } from "@/app/lib/types/persistence"` at `workspaceStore.ts:24`)
**Confidence:** High

**Evidence:** `import { resolveWorkspaceStorage } from "@/app/lib/corpus/storeAdapter";` (`workspaceStore.ts:25`) — a deep import, matching the six other deep imports in the same block.

**Legibility-target:** N/A — recorded so a future reviewer does not raise it as a gap.

The corpus module spreads ~40 exports across six files with no `index.ts`. Because the repo has no barrels anywhere, this is the consistent choice, and deep imports keep the S2/S3/S4 dependency edges visible in the import list. Severity floored to Informational per the no-precedent rule; noting it only to close the question.

**Recommendation:** None. Keep deep imports.

---

### What Looks Good

- **The A1 rename is vocabulary-complete at the field level.** `customArtifactTypeIds` (`manifest.ts:44`) now matches `CustomArtifactTypeId` (`customArtifact.ts:11`) and `PersistedWorkspace.customArtifactTypes` (`persistence.ts:34`). The manifest and the store finally use the same noun phrase for the same objects — the residue in F12 is one function name in a different file, not a split in the data vocabulary.
- **A2 gives the state-blob path a single source, and the doc-comment explains why.** Routing through `stateBlobPath` (`paths.ts:82-85`) rather than a literal in `storeAdapter` means the `state/` namespace fork is greppable, gets the same `safeSegment` sanitization as every other path, and carries an explicit S4-reconciliation marker. This is the right shape for a deliberately temporary namespace.
- **The path-builder family is uniformly shaped.** Nine builders, one signature convention (`(slug, …)`), one naming convention (`<thing>Dir` / `<thing>Path`), one sanitization choke point. `artifactVersionPath`'s 1-based guard (`:106-108`) is explicit and matches the on-disk `v0001.md` reality.
- **`safeSegment` vs `workspaceSlug` is a correct split, correctly documented.** Preserving case for ids and lowercasing for slugs is a real distinction, both are idempotent, and the doc-comment at `:49-51` says why.
- **Factory naming is consistent across three substrates.** `createOpfsCorpusFs` / `createInMemoryCorpusFs` / `createCorpusBackedStorage` / `createDebouncedLocalStorage` all encode the substrate in the name and return the interface, and `resolveWorkspaceStorage` correctly uses a different verb for selection.
- **The rename of `createDebouncedStorage` → `createDebouncedLocalStorage` is the right call at the right time.** Once a second substrate exists, the unqualified name would have been the ambiguous one.
- **`CorpusError` / `CorpusWorkerError` are a genuine symmetric pair.** Same kind set, one transport difference, with `toWorkerError` and `isCorpusWorkerError` following the codebase's `is<Thing>` guard precedent. The stated invariant ("They differ only in transport, never in the kind set", `types.ts:28`) holds in the code.
- **The interface's absence model is stated once, up front, and then actually followed** by both implementations for `readFile`/`stat`/`readdir` — including the `[]` carve-out, which is at least documented rather than incidental (F19 is about the consequence, not a violation).
- **`rm` idempotency is specified in the interface, implemented in both adapters, and pinned by the contract suite** (`types.ts:121`, `opfsAdapter.ts:153,157`, `inMemoryCorpusFs.ts:45`, `corpusFsContract.ts:49-56`). This is the one part of the contract that is fully closed end-to-end.
- **The C2 production guard is placed first and explained.** `isCorpusEnabled` refuses before consulting either input (`flag.ts:21`), with an inline note stating the exact condition for removing it. Ordering matters here and it is right.

---

### Summary Table

| # | Finding | Severity | Move | Confidence |
|---|---|---|---|---|
| F1 | `onRehydrateStorage` bypasses the storage seam via direct `localStorage` read + duplicated key literal | Breaking | 3 | High |
| F2 | One `StateStorage` type, two incompatible failure/timing contracts | Inconsistent | 4 | High |
| F3 | `ArtifactPointer.currentVersion` 1-based vs `ArtifactRecord.currentVersionIndex` 0-based | Inconsistent | 3 | High |
| F4 | `SourceRef.id/label` vs established `sourceId`/`sourceLabel` | Inconsistent | 2, 3 | High |
| F5 | Manifest widens branded artifact types back to bare `string` | Inconsistent | 3 | High |
| F6 | `CorpusErrorKind` advertises 5 of 8 kinds nothing can produce | Inconsistent | 4 | High |
| F7 | Contract suite omits the error half; fake and adapter diverge | Inconsistent | 7 | High |
| F8 | `readdir` skips the traversal guard the other four methods apply | Inconsistent | 7 | High |
| F9 | `parseManifest` silently drops malformed elements; breaks round-trip symmetry | Inconsistent | 7 | High |
| F10 | `manifestVersion` never gated against `MANIFEST_VERSION` | Inconsistent | 3 | High |
| F11 | `paths.ts` throws bare `Error` where the contract is `CorpusError` | Minor | 4 | High |
| F12 | `customTypePath` / `customTypeId` retain pre-A1 vocabulary | Minor | 2 | High |
| F13 | `CorpusFS` vs `createOpfsCorpusFs` — split acronym casing | Minor | 2 | High |
| F14 | `CORPUS_FLAG_KEY` unversioned against three versioned key precedents | Minor | 2 | Medium |
| F15 | Flag docstring implies live runtime toggling; seam resolves once | Minor | 9 | High |
| F16 | `parseManifest` accepts a `null` that is always an error | Minor | 8 | High |
| F17 | `workspaceDir(slug)` param named `slug` but runs the title sanitizer | Minor | 2, 9 | Medium |
| F18 | `createManifest` injects a clock; `parseManifest` hardcodes two | Informational | 7 | High |
| F19 | `readdir` `[]` conflates missing and empty, against the null-for-missing model | Informational | 8 | High |
| F20 | `SETTINGS_PATH` exported with no schema, codec, or caller | Informational | 3 | High |
| F21 | Two comments name `CorpusFS` where the seam is `StateStorage` | Informational | 3 | High |
| F22 | No barrel export — consistent with the repo (no-precedent floor) | Informational | 2 | High |

Totals: 1 Breaking · 9 Inconsistent · 7 Minor · 5 Informational.

---

### Overall Assessment

The new corpus surface is, on the whole, a well-conventioned module: the factory naming, type-guard shape, constant casing, path-builder family, and no-barrel packaging all match what the codebase already does, and the deliberate design choices (bytes-and-paths, async-everywhere, git-excluded, error-kinds-centralized) are stated once and then honored. The A1 rename genuinely closed the vocabulary split it targeted, and A2's `stateBlobPath` routing is the right shape for a namespace that is meant to be found and retired.

The consistency problems cluster in three places, and the clustering is informative. **First, the manifest is designed against the on-disk layout rather than against the in-memory store it will eventually have to merge with** — hence F3 (1-based vs 0-based), F4 (`id`/`label` vs `sourceId`/`sourceLabel`), and F5 (bare `string` vs branded `ArtifactType`). Each is individually defensible; together they mean S4's migration is a field-by-field translation table where it could have been close to a spread, and every one of those translations is a place to introduce a silent error. These are cheap to fix now — nothing consumes `WorkspaceManifest` yet — and expensive to fix after S2/S4 bind to it. **Second, the error model is more thoroughly designed than it is applied**: `CorpusErrorKind` is centralized and argued for, but five of its members are unreachable (F6), `paths.ts` throws outside it entirely (F11), the contract suite never exercises it (F7), and the one seam a live consumer touches has two different failure behaviors under one type (F2). **Third, the fail-loud manifest contract is enforced at the field level but not the element level** (F9) or the version level (F10), which leaves the module's most-emphasized invariant — no silent defaults that masquerade as an empty workspace — true of the shape and false of the contents.

F1 is the one finding that is live rather than prospective. It is contained by the dev-only flag and the production hard-refuse, so the practical risk today is a confused developer rather than user data loss, but it is a genuine consumer-contract break: the diff introduces an abstraction and then, thirty lines later, reads around it, in a way that will overwrite corpus-loaded state with legacy localStorage on every rehydrate. It should be fixed before anyone turns the flag on, and it argues for hoisting the store key to a named constant so the coupling is visible.

Ranked by cost-of-delay: F1 (fix before the flag is used), then F3/F4/F5 (fix before anything binds to `WorkspaceManifest`), then F9/F10 and F7/F8 (fix before the codec and the adapters are trusted), then the Minor naming items, which can ride along with any of the above.

## Goal-Alignment Note
- Answered: Whether the new corpus public surface — `CorpusFS` and its five methods, `CorpusError`/`CorpusErrorKind`, `WorkspaceManifest` and its fields (including `customArtifactTypeIds` post-A1-rename), `stateBlobPath`/`STATE_DIR`, and the `flag.ts` exports — is consistent with the conventions already established in `app/lib/types/` and `app/lib/utils/`, and whether it honors the contracts existing consumers (`workspaceStore`, `artifactStore`, `decomposition`, `workspacePersistence`) already depend on. Covered all nine requested moves: baseline conventions from seven siblings; a 40-name audit ordered most-public first with a precedent or no-precedent line on every naming finding; the three named consumer-contract checks (1-based vs 0-based version pointers, bare-string vs branded artifact types, `SourceRef` vs `SourceDocument` field names); error consistency in both requested aspects (producible vs advertised kinds, adapter synchrony/failure asymmetry); serialize/parse asymmetry; nullability; and idempotency.
- Out of scope: Security analysis of the traversal guards and the C1/C2 hardening beyond their consistency implications (F8 is raised as a "four of five methods" asymmetry, not as an exploitability claim) — that belongs to the security critic. Performance of the un-debounced corpus write path (noted in F2 only as a contract difference). Test adequacy and coverage as such — F7 is raised because the suite's own substitutability *claim* is a contract the implementations fail, not as a coverage judgment. Architectural questions of module placement and dependency direction. `docs/**`, which was read as context only. Re-verification of anything the merged code fact-check established.
- Escalate: **F1 to the orchestrator as the one live consumer-contract break in the diff** — it is a behavior change on the flagged path introduced by the seam refactor itself, and it sits at `workspaceStore.ts:533-537`, which is context rather than a changed line, so a line-scoped reviewer will not surface it. **F3/F4/F5 as a decision, not a fix**: whether the manifest's vocabulary should converge on the store's is a design call with an S4 migration cost attached either way, and it is cheapest to make while `WorkspaceManifest` has zero consumers. **F6's `not-found` member to whoever owns the failure-driven-UI mandate** — it is unreachable by construction under the current `CorpusFS` contract, so any UI built against it is untestable.
