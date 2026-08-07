Commit: 2dc403e

# API Consistency Review — Corpus filesystem/OPFS storage layer (`dc6dfb0..2dc403e`, `app/`)

**Scope:** `git -C wt-corpus diff dc6dfb0..2dc403e -- app/` — new `app/lib/corpus/` module (`types.ts`, `manifest.ts`, `paths.ts`, `opfsAdapter.ts`, `storeAdapter.ts`, `flag.ts`) + tests, and the `workspaceStore.ts` storage-seam extraction.
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/corpus/fact-check.md` (16 claims; hints on Claims 4, 8 used, not re-verified).

The interfaces consumers bind to here are: the `CorpusFS` interface (two implementations — OPFS adapter + in-memory fake — asserted against a shared contract suite), the `CorpusError` / `CorpusErrorKind` discriminated-union error contract, the exported path-builder functions in `paths.ts`, the `manifest.ts` codec, and the `storeAdapter.ts` storage-seam factories. This is an internal library surface (no HTTP/SDK), so "consumers" are S2/S3/S4 sub-tasks and the Zustand store.

## Baseline Conventions

Observed across `app/lib/` (surveyed `app/lib/utils/`, `app/lib/stores/`, `app/lib/types/`):

- **Factories** use `create<Thing>` (`useEvidenceStore = create(...)`, and within the diff `createManifest`, `createOpfsCorpusFs`, `createDebouncedLocalStorage`). **Boolean predicates** use `is<Thing>` (`isLatexStructured`, `isValidCustomTypeDef`, `isBoldFont`, `isCustomType`). **Codec verbs** are `parse*`/`serialize*` (`parseLatexPropositions`, `serializeTargetKey`). **Resolvers** use `resolve*` (`resolveArtifactContent`). Confirmed via `rg 'export function (create|is|resolve|parse|serialize)[A-Z]' app/lib`.
- **Types/interfaces** are bare PascalCase nouns (`SourceDocument`, `PropositionNode`, `ArtifactRecord`) — no `I`/`DTO` affixes.
- **Constants** are UPPER_SNAKE.
- **Error signaling in the broader codebase** is plain `throw new Error(...)`. The `CorpusError` typed-union model is a *new, module-local* contract this diff introduces and documents heavily (`types.ts:26-49`, 92-96): "one source of truth for the kind set… every exhaustive `switch` over a corpus error binds to this union… the failure-driven-UI mandate." That establishes the in-module baseline the rest of the corpus code is expected to honor.

## Name-Pattern Audit

All new public names, grouped by category. Closest neighbors drawn from within `app/lib/corpus/**` and analogous `app/lib/**`.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `createOpfsCorpusFs`, `createInMemoryCorpusFs` | factory fn | `createManifest`, `createDebouncedLocalStorage`, `create` (zustand) | `app/lib/corpus/*.ts`, `app/lib/stores/evidenceStore.ts:81` | Consistent — `create<Thing>` |
| `createCorpusBackedStorage`, `resolveWorkspaceStorage` | factory/resolver | `resolveArtifactContent` | `app/lib/stores/workspaceStore.ts:126` | Consistent — `create*`/`resolve*` |
| `parseManifest`, `serializeManifest` | codec fn | `parseLatexPropositions`, `serializeTargetKey` | `app/lib/utils/latexParser.ts:151`, `app/lib/types/evidence.ts:23` | Consistent |
| `isCorpusEnabled`, `isCorpusWorkerError` | boolean pred | `isLatexStructured`, `isValidCustomTypeDef`, `isCustomType` | `app/lib/utils/*.ts`, `app/lib/types/customArtifact.ts:33` | Consistent |
| `toWorkerError`, `describeCorpusError`, `assertNever` | fn | (no `to*`/`describe*` analog) | none — searched `app/lib/**/*.ts` | New; conventional, note only |
| `workspaceSlug`, `safeSegment` | sanitizer fn | (first of kind) | none — searched `app/lib/**` | New category — establishes slug/segment convention |
| `workspaceDir`, `artifactDir`, `decompositionDir` | path builder | each other | `app/lib/corpus/paths.ts` | Consistent — `<thing>Dir` |
| `workspaceManifestPath`, `sourcePath`, `artifactVersionPath`, `artifactMetaPath`, `customTypePath`, `decompositionGraphLayoutPath`, `SETTINGS_PATH` | path builder/const | each other | `app/lib/corpus/paths.ts` | Consistent — `<thing>Path` / `*_PATH` |
| `CorpusFS`, `CorpusStat`, `CorpusError`, `CorpusWorkerError`, `CorpusSubstrate`, `CorpusErrorKind`, `WorkspaceManifest`, `ArtifactPointer`, `SourceRef` | type/class | `SourceDocument`, `ArtifactRecord`, `PropositionNode` | `app/lib/types/*.ts` | Consistent — bare PascalCase nouns |
| `CORPUS_FLAG_KEY`, `MANIFEST_VERSION`, `VERSION_PAD`, `SAFE_SEGMENT` | const | UPPER_SNAKE convention | `app/lib/**` | Consistent |
| `CorpusErrorKind` variants (`not-found`, `quota-exceeded`, `unavailable`, `io`, `fsa-permission-revoked`, `remote-auth-expired`, `browser-storage-cleared`, `git-conflict`) | enum/discriminant | each other | `app/lib/corpus/types.ts:41-49` | Consistent shape (kebab-case discriminant); but see F2/F3 for raise-vs-declare gaps |

Naming is uniformly consistent with both the existing codebase and within the new module. No naming-level findings. The findings below are error-contract and cross-implementation-symmetry issues.

## Findings

#### F1 — Path builders throw bare `Error`, bypassing the module's `CorpusError` typed-error contract

**Severity:** Inconsistent
**Location:** `app/lib/corpus/paths.ts:44`, `:55`, `:89-90`
**Move:** #4 (error consistency)
**Confidence:** High

`types.ts` goes to unusual lengths to establish that every corpus failure is a typed `CorpusError` carrying a `CorpusErrorKind` discriminant, so consumers can drive UI off an exhaustive switch: *"one source of truth for the kind set… every exhaustive `switch` over a corpus error binds to this union… the failure-driven-UI mandate"* (`types.ts:26-40`). `opfsAdapter.ts` and `manifest.ts` honor this — even `splitPath` throws `new CorpusError({ kind: "io", ... })` (`opfsAdapter.ts:60`), and `manifest.ts` routes every malformation through `fail()` → `CorpusError` (`manifest.ts:64-66`). But the `paths.ts` builders throw plain `Error`:

```ts
// paths.ts:43-45
if (!slug) {
  throw new Error(`workspace title produced an empty slug: ${JSON.stringify(title)}`);
}
```

Same at `safeSegment` (`:54-55`) and `artifactVersionPath` (`:89-90`). A consumer doing the mandated failure-driven UI — `catch (e) { if (e instanceof CorpusError) switch (e.detail.kind) ... }` — will silently miss these: they are not `instanceof CorpusError` and have no `.detail.kind`. Given a workspace slug is derived from an *untrusted title* (`paths.ts:31-34`), an all-unsafe title is a reachable, user-triggerable failure that escapes the typed contract every other corpus surface promises.

**Recommendation:** Throw `CorpusError` from the path builders — e.g. `{ kind: "io", path: <partial>, reason: "..." }`, or introduce a dedicated validation kind in the union if `io` is semantically wrong. Keep the whole module inside the one error contract `types.ts` advertises.

#### F2 — Manifest docstring advertises a `CorpusError` kind (`browser-storage-cleared`) the codec never throws

**Severity:** Inconsistent
**Location:** `app/lib/corpus/manifest.ts:10-13` (contract docstring) vs `:64-66` (only thrower)
**Move:** #4 (error consistency) / #3 (consumer contract)
**Confidence:** High

The codec contract states parse failures *"must surface as a typed `CorpusError` of kind `"io"` or `"browser-storage-cleared"`"* (`manifest.ts:11-13`). `parseManifest` only ever throws `kind: "io"` (`fail()`, `manifest.ts:64-66`); no path yields `browser-storage-cleared`. This matches fact-check Claim 4 (Mostly accurate). The documented error contract is a promise consumers write catch-branches against; a consumer that adds a `case "browser-storage-cleared":` handler for manifest parsing based on this docstring writes dead code, while one relying on the docstring's disjunction may under-handle `io`. (Non-naming finding — the discriminant shape itself is consistent; the issue is declared-vs-thrown drift, so the precedent line does not apply.)

**Recommendation:** Drop `browser-storage-cleared` from the manifest docstring so the stated throw-set matches the code (`io` only). If a cleared-storage signal is genuinely intended for the manifest path, raise it; don't only document it.

#### F3 — `not-found` error kind is declared in the union but the `CorpusFS` contract forbids throwing it

**Severity:** Informational
**Location:** `app/lib/corpus/types.ts:42` (union) vs `:17-18`, `:112-124` (interface contract)
**Move:** #7 (asymmetry)
**Confidence:** High

The `CorpusErrorKind` union's first variant is `{ kind: "not-found"; path: string }` (`types.ts:42`), but the `CorpusFS` contract explicitly signals not-found *without* throwing: *"Not found is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`"* (`types.ts:17-18`), and both adapters implement exactly that (OPFS `readFile` returns `null` on `isNotFound`, `opfsAdapter.ts:97`; in-memory `?? null`, `inMemoryCorpusFs.ts:22`). So no FS operation ever produces a `CorpusError` of kind `not-found`. A consumer writing an exhaustive switch over FS-operation failures gets a `not-found` arm the FS layer can never trigger — mild but real friction against the exhaustive-switch mandate. (Plausibly reserved for a higher layer, but nothing in this diff raises it.)

**Recommendation:** Add a one-line note on the `not-found` variant naming which layer raises it (e.g., a resource resolver above the FS), or defer adding it to the union until a thrower exists. No behavioral change needed.

#### F4 — Two `CorpusFS` implementations diverge on write-copy semantics; the interface is silent on which is the contract

**Severity:** Minor
**Location:** `app/lib/corpus/opfsAdapter.ts:114-116` vs `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:26-27`; interface at `types.ts:117`
**Move:** #7 (asymmetry) / #3 (consumer contract)
**Confidence:** Medium

The in-memory fake defensively copies the caller's array (`bytes.slice()`, `inMemoryCorpusFs.ts:27`) so later mutation can't alter stored bytes. The OPFS adapter's comment claims the same — *"Pass a fresh ArrayBuffer view; some implementations dislike shared buffers"* — but writes `bytes` directly with no copy (`opfsAdapter.ts:115-116`); fact-check Claim 8 (Incorrect). The `CorpusFS.writeFile` interface docstring (`types.ts:117`) says nothing about copy semantics. Because both adapters `await` the write, the *post-await* observable behavior is equivalent in practice, so this is not breaking — but the shared-contract suite runs only against the in-memory fake in CI (jsdom has no OPFS), so the "substitutability (LSP) is verified, not assumed" claim (`inMemoryCorpusFs.ts:5-6`) does not actually cover this axis. Two implementations of one interface documenting different buffer handling is exactly the cognitive-load trap this review targets.

**Recommendation:** Either state in the `CorpusFS.writeFile` docstring that implementations must not retain the caller's buffer beyond the returned promise (making the fake's copy the contract and the OPFS comment accurate), or delete the misleading OPFS comment. Prefer the former so the contract is explicit for S2/S3 adapters.

#### F5 — Fail-loud manifest contract is applied asymmetrically across fields

**Severity:** Informational
**Location:** `app/lib/corpus/manifest.ts:83-84` / `:88` / `:91` / `:100` / `:104` (fail-loud) vs `:89` / `:109-110` (silent default)
**Move:** #4 (error consistency) / #7 (asymmetry)
**Confidence:** High

The contract says a malformed manifest *"must surface as a typed `CorpusError`… never a silent default"* (`manifest.ts:10-13`). Required scalars and arrays do fail loud (`title`, `manifestVersion`, `sources`, `artifacts`, `customTypeIds`). But three fields are silently defaulted on malformation rather than failing: a non-string `label` falls back to `id` (`:89`), and non-string `createdAt`/`updatedAt` fall back to `new Date().toISOString()` (`:109-110`). This is a defensible design (timestamps/labels are non-critical), but it's an unstated exception to the blanket "never a silent default" promise — a consumer trusting the docstring would expect a corrupt `updatedAt` to throw.

**Recommendation:** Tighten the docstring to scope fail-loud to the structural/required fields and name the soft-defaulted ones, so the contract matches the codec.

## What Looks Good

- **Naming is uniformly on-convention** — `create*` factories, `is*` predicates, `parse*`/`serialize*` codecs, `<thing>Dir`/`<thing>Path` builders, bare-PascalCase types, UPPER_SNAKE consts — matching both the new module and pre-existing `app/lib/` code. No naming findings.
- **Return-shape invariant is honored symmetrically:** both adapters return `null` (readFile/stat) / `[]` (readdir) for not-found and never `undefined` (`opfsAdapter.ts:97,130,161`; `inMemoryCorpusFs.ts:22,41,50`), matching `types.ts:17-18`.
- **Idempotent `rm`** is consistent across both adapters (`opfsAdapter.ts:144-150`, `inMemoryCorpusFs.ts:45`) and asserted by the shared contract suite.
- **`CorpusWorkerError` twin** (`types.ts:63-75`) keeps the worker-boundary serialization contract on the same `detail`/kind set as the thrown form — a clean symmetric design for the S3 transport swap.
- **`quota-exceeded` is substrate-tagged** (`CorpusSubstrate`) rather than minting adapter-specific kinds, so S2/FSA reuses one kind — good forward-consistency (`types.ts:31-34`).
- **`storeAdapter` seam typed as `CorpusFS`, not a concrete adapter** (`storeAdapter.ts:52`), preserving the arch-review injection contract.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Path builders throw bare `Error`, not `CorpusError` | Inconsistent | `paths.ts:44,55,89-90` | High |
| F2 | Manifest docstring advertises `browser-storage-cleared` kind it never throws | Inconsistent | `manifest.ts:10-13` | High |
| F3 | `not-found` kind declared but FS contract forbids throwing it | Informational | `types.ts:42` vs `:17-18` | High |
| F4 | Adapters diverge on write-copy semantics; interface silent | Minor | `opfsAdapter.ts:114-116` vs `inMemoryCorpusFs.ts:26-27` | Medium |
| F5 | Fail-loud manifest contract applied asymmetrically | Informational | `manifest.ts:89,109-110` | High |

## Overall Assessment

This is a well-designed, internally consistent library surface — naming, return-shape invariants, and the error-union model are coherent and match the existing codebase. The one finding with real consumer impact is F1: the module advertises a strict typed-error contract (whole point of `CorpusErrorKind` + the failure-driven-UI mandate) yet `paths.ts` leaks bare `Error`s from user-triggerable input, so the exhaustive-switch consumers the design targets will silently miss those failures. F2 and F5 are docstring-vs-code error-contract drift (both flagged in fact-check) that will mislead consumers writing catch-branches. F3 and F4 are symmetry nits worth a doc line. All five are fixable in place — none require an API redesign; F1 is the one to fix before downstream sub-tasks bind to the error contract.
