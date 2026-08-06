# Architecture Review — corpus-dirty (dc6dfb0..2dc403e, app/ only)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` in the pinned worktree /workspace/runs/review-arms/e1/wt-corpus-dirty — the corpus S0/S1 foundation (new `app/lib/corpus/` subtree: types.ts, paths.ts, manifest.ts, opfsAdapter.ts, flag.ts, storeAdapter.ts, contract suite + fake) plus the one-line storage-seam swap in `app/lib/stores/workspaceStore.ts`. Structural integrity only: dependency direction, responsibility boundaries, module boundaries, layering, interface segregation, substitutability, coupling surface, extension points for S2–S5. Implementation quality (security, performance, API naming) is out of scope. `docs/working/**` read as evidence of intended structure, not reviewed.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3, `code-fact-check-report.md`) — its findings are treated as established and not re-verified.

**Commit:** 2dc403e

A security review for this arm does not exist at `/workspace/runs/review-arms/e1/corpus-dirty/security-review.md`, so no boundary labels are cross-referenced.

---

### Dependency Map

Edges introduced or changed by the range (`→` = imports):

```
app/lib/stores/workspaceStore.ts
        │  (1 edge, added: line 25)
        ▼
app/lib/corpus/storeAdapter.ts ──type──► zustand/middleware (StateStorage)
        │            │            │
        │            │            └──────► ./flag.ts            (leaf, no imports)
        │            └───────────────────► ./opfsAdapter.ts     (CONCRETE)
        └────type────────────────────────► ./types.ts

app/lib/corpus/opfsAdapter.ts ──► ./types.ts
app/lib/corpus/manifest.ts    ──► ./types.ts
app/lib/corpus/paths.ts        (leaf, no imports)  ── unimported by any non-test module
app/lib/corpus/types.ts        (leaf, no imports)

app/lib/corpus/__tests__/inMemoryCorpusFs.ts ──► ../types.ts
        ▲
        └── imported across the module boundary by
            app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:15
```

Properties worth stating explicitly:

- **Acyclic, and one-way at the module level.** Nothing in `app/lib/corpus/` imports from `app/lib/stores/`, `app/lib/utils/`, `app/lib/types/`, or any component. The only production edge crossing the new boundary is `workspaceStore.ts:25 → corpus/storeAdapter.ts`. Verified by grep for `lib/corpus` outside the subtree: three test-file hits and one production hit.
- **`types.ts` is the sink.** Every other corpus module depends on it and it depends on nothing. That is the right shape for a contracts module.
- **Two nodes are unreachable from production code**: `paths.ts` and `manifest.ts` have no non-test importer at 2dc403e.
- **One edge points the wrong way in the layering sense**: `corpus/storeAdapter.ts → zustand/middleware`. The substrate layer names the app's state-management library (see Finding 2).
- **One concrete-class edge inside the seam**: `storeAdapter.ts:17` imports `createOpfsCorpusFs` directly; the interface-typed seam is one function deeper (see Finding 3).

---

### Findings

#### 1. Two incompatible corpus layouts now coexist in one root, and only the undocumented one is written

**Severity:** Structural
**Location:** `app/lib/corpus/storeAdapter.ts:49-68` (esp. :55) vs `app/lib/corpus/paths.ts:4-19`
**Move:** Module boundary audit — does the storage seam leak past the layout module?
**Confidence:** High — every production corpus module was read; the fact-check independently found the same violation at k=3.

**Evidence:**
```ts
const pathFor = (name: string) => `state/${name}.json`;
```
(`storeAdapter.ts:55`)

```
 * All builders return POSIX-style paths relative to the corpus root (no leading
 * slash), suitable for passing straight to a `CorpusFS`. The only source of
 * corpus paths is this module — callers must never hand-concatenate
```
(`paths.ts:15-18`)

**Legibility-target:** for-author

The consequence is not the broken comment (the fact-check already verdicted that Incorrect); it is that the corpus root now has two disjoint, unrelated on-disk shapes: the S0 folder layout under `workspaces/<slug>/…`, which nothing writes, and a single opaque JSON blob at `state/workspace-zustand-v1.json`, which is the only thing anything writes. `storeAdapter.ts` does not import `paths.ts` at all (imports at :15-18 are zustand, `./types`, `./opfsAdapter`, `./flag`), so the layout module is not merely bypassed — it is not on the corpus write path in any form. Three downstream costs follow: S2's FSA mirror replays the whole root, so an undocumented top-level `state/` directory appears inside the user's picked folder alongside the "user-visible source of truth" layout; S3's git pipeline commits a monolithic blob whose diffs are meaningless, defeating the "external tooling (`git log`/`grep`/`vim`) works on the corpus" goal the decomposition assigns to S0+S3; and S4's migration is now two migrations, localStorage→corpus *and* corpus-blob→corpus-folder, of which only the first is planned (`docs/working/decomposition-corpus-architecture.md:25`).

**Recommendation:** Add a `statePath(name)` builder (or `STATE_DIR`) to `paths.ts`, have `storeAdapter.ts` import it, and add the `state/` line to the layout diagram at `paths.ts:4-13` with a note that it is S1-transitional and removed by S4. That restores the single-choke-point invariant at near-zero cost and makes the blob visible to S2/S3/S4 planning instead of a surprise.

#### 2. `storeAdapter.ts` is a zustand-shaped consumer living inside the substrate module, inverting the intended layering

**Severity:** Coupling
**Location:** `app/lib/corpus/storeAdapter.ts:15`, `:25-46`, `:52`
**Move:** Dependency direction / responsibility boundaries
**Confidence:** High — the import list and both exported factories were read in full.

**Evidence:**
```ts
import type { StateStorage } from "zustand/middleware";
```
(`storeAdapter.ts:15`)

**Legibility-target:** for-author

`app/lib/corpus/` is positioned as the substrate every later sub-task binds to (`types.ts:4-8`), which makes it a lower layer than application state. But `storeAdapter.ts` sits inside that subtree while its entire reason to exist is to satisfy a zustand interface, and `createDebouncedLocalStorage` (`:25-46`) has nothing to do with the corpus at all — it is the pre-existing localStorage adapter, now living in the corpus module purely because that is where the selector ended up. The direction cost is real even though the zustand import is type-only and erased at runtime: an S3 worker bundle or any future non-store consumer that imports from `app/lib/corpus/` pulls in a subtree whose type-check depends on the app's state manager, and a reader looking for "how does the corpus store bytes" finds a localStorage debouncer. The two responsibilities in this one file — *be a CorpusFS-backed key/value store* and *decide which storage the workspace store uses* — belong to different layers.

**Recommendation:** Keep `createCorpusBackedStorage(fs: CorpusFS)` in the corpus module (it is a legitimate corpus-side facade), and move `createDebouncedLocalStorage` + `resolveWorkspaceStorage` to `app/lib/stores/storageSelection.ts`. Then the corpus subtree has no zustand edge, and the composition decision lives with the consumer that makes it — which is also where S2/S3 will need to change it.

#### 3. The DI seam is only half-open: `resolveWorkspaceStorage` hard-wires the concrete adapter at module-evaluation time

**Severity:** Structural
**Location:** `app/lib/corpus/storeAdapter.ts:70-76`; consumed at `app/lib/stores/workspaceStore.ts:499`
**Move:** Extension points — do S2–S5 land on this structure without reopening it?
**Confidence:** High for the structure; Medium for the zustand evaluation timing, which rests on the fact-check's Claim 14 (zustand not installed in the worktree).

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
(`storeAdapter.ts:70-76`)

**Legibility-target:** for-orchestrator-synthesis

The plan calls the interface-typed seam "the single most load-bearing structural decision in S1" (`docs/working/plan-corpus-s1.md:27`), and at the `createCorpusBackedStorage(fs: CorpusFS)` boundary it holds — that half is correct and well done. The gap is one level up: `resolveWorkspaceStorage` takes no parameters and constructs `createOpfsCorpusFs()` itself, so the only way to vary the FS in production is to edit this function. The claim that S3's worker proxy "drops in here without the store ever knowing" (`storeAdapter.ts:6-8`) is true of the *store* and false of the *resolver* — the choke point simply moved. This matters concretely for S2, whose read path is specified as "OPFS-first, fall through to FSA" (`docs/working/decomposition-corpus-architecture.md:72`): that is a *composed* `CorpusFS` (a decorator over two substrates), and the resolver has no composition parameter and no place to put one. Compounding it, the fact-check establishes that selection happens once at module evaluation of `workspaceStore.ts` — possibly under SSR — so no async capability probe (is OPFS available? is the FSA handle still granted? is the corpus empty?) can inform the choice, and every one of those questions is async by nature.

**Recommendation:** Give the resolver a seam of its own: `resolveWorkspaceStorage(makeFs: () => CorpusFS = createOpfsCorpusFs)`, and plan for the composed case now — S2 should be able to pass `createFallthroughFs(createOpfsCorpusFs(), createFsaCorpusFs(handle))` without editing this file. If async selection turns out to be required, that is a larger change (a lazily-initializing `StateStorage` wrapper) and is worth deciding before S2 rather than during it.

#### 4. The contract suite is the LSP argument, but it binds one implementation and under-specifies the semantics the two already differ on

**Severity:** Structural
**Location:** `app/lib/corpus/__tests__/corpusFsContract.ts:1-82`, `corpusFs.contract.test.ts:8`, `inMemoryCorpusFs.ts:26-27`, `opfsAdapter.ts:114-119`
**Move:** Substitutability (LSP) audit
**Confidence:** High — both implementations and all seven contract cases read line by line.

**Evidence:**
```ts
defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());
```
(`corpusFs.contract.test.ts:8` — the suite's only instantiation in the repo)

```ts
      // Copy so later mutation of the caller's array can't alter stored bytes.
      files.set(normalize(path), bytes.slice());
```
(`inMemoryCorpusFs.ts:26-27`) versus
```ts
          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
          await w.write(bytes);
```
(`opfsAdapter.ts:115-116`)

**Legibility-target:** for-author

The fact-check established that "substitutability (LSP) is verified, not assumed" (`inMemoryCorpusFs.ts:4-6`) holds only for the fake — the OPFS run is documented but unexecuted at this commit. The structural point is sharper than that: the contract as written would not catch the divergences that already exist. Three behaviors are unspecified by all seven cases and implemented differently. **Write aliasing:** the fake copies (`bytes.slice()`), OPFS hands the caller's array straight to `write()` despite a comment claiming otherwise — so a caller that reuses a scratch buffer gets different results per substrate, and this becomes load-bearing at S3 when a worker-shared buffer can reach `writeFile`. **Read aliasing:** the fake returns the *stored* `Uint8Array` (`inMemoryCorpusFs.ts:22`), so mutating a read result corrupts the store; OPFS returns a fresh `new Uint8Array(await file.arrayBuffer())` (`opfsAdapter.ts:101`). **Non-directory parent:** `writeFile("a.txt/b.txt")` when `a.txt` is a file throws `{kind:"io"}` on OPFS (`TypeMismatchError` rethrown through `wrap`, `opfsAdapter.ts:70-74, 121`) and silently succeeds on the fake, which has no directory concept at all (`inMemoryCorpusFs.ts:8`). A green CI run against the fake therefore does not predict OPFS behavior on exactly the axes S3 and S4 depend on, and the module's own docstring invites readers to believe otherwise.

**Recommendation:** Add three contract cases — mutate the caller's buffer after `writeFile` and assert stored bytes are unchanged; mutate a `readFile` result and assert a re-read is unchanged; write under a file-as-parent and assert the agreed outcome — then fix whichever implementation loses. Until the OPFS Playwright run actually executes, soften `inMemoryCorpusFs.ts:4-6` to say the suite is *defined* for both and *run* against the fake, so S2/S3 implementers do not inherit a false safety claim.

#### 5. Write-coalescing is an accident of which branch the flag takes, not a stated responsibility of any layer

**Severity:** Coupling
**Location:** `app/lib/corpus/storeAdapter.ts:25-46` vs `:56-67`; `app/lib/stores/workspaceStore.ts:5`
**Move:** Responsibility boundaries
**Confidence:** High

**Evidence:**
```ts
    setItem: async (name, value) => {
      await fs.writeFile(pathFor(name), enc.encode(value));
    },
```
(`storeAdapter.ts:61-63` — no debounce, versus the 300ms debounce at `:29-39`)

**Legibility-target:** for-author

The two branches behind one seam differ in write cadence by roughly the keystroke rate: the localStorage branch coalesces at 300ms, the corpus branch issues one OPFS write per zustand `set()`. Structurally the question is *where does coalescing live* — the store, the `StateStorage` seam, or each adapter — and the answer at this commit is "in one adapter, by inheritance from the code it replaced." That has consequences beyond throughput. The characterization test is explicitly framed as "the equivalence target" for the corpus path (`workspaceStore-characterization.test.ts:5`), but the seam permits substrates that are not equivalent in cadence, and nothing in `CorpusFS` or `StateStorage` expresses coalescing as a contract either party can rely on. S3 inherits the problem in a worse form: every uncoalesced write becomes a postMessage round-trip and (with commit-on-write) a git commit.

**Recommendation:** Hoist coalescing above the seam — wrap whichever `StateStorage` the resolver returns in a single `withDebounce(storage, 300)` decorator — so cadence is a property of the store's persistence policy rather than of the substrate that happens to be selected. That also makes the OFF/ON paths genuinely comparable under the characterization test.

#### 6. `CorpusErrorKind` is a shared union owned by no one, with five arms unreachable and one unreachable by design

**Severity:** Coupling
**Location:** `app/lib/corpus/types.ts:37-49`, `:78-96`
**Move:** Interface segregation / extension points
**Confidence:** High — every `CorpusError` producer in the range enumerated (fact-check Claim 16 foundation).

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
(`types.ts:41-49`)

**Legibility-target:** for-orchestrator-synthesis

Centralizing the kind set was a deliberate decision (`types.ts:26`, plan step 1) and it buys a real property: `CorpusError` and `CorpusWorkerError` provably cannot drift, and adding a kind forces every switch to handle it. The structural cost is that the union is a shared mutable surface across five sub-tasks that are otherwise decoupled — `fsa-permission-revoked` belongs to S2, `remote-auth-expired` and `git-conflict` to S3, `browser-storage-cleared` to S2/S5 — so `CorpusGit` cannot be added "over" `CorpusFS` (`types.ts:19-22`) without editing the FS module's error type, which is precisely the coupling the ISP note in that same header is trying to avoid. Today five of eight arms have no producer, and `not-found` is unreachable *by design*: the interface convention returns `null`/`[]` for absence (`types.ts:17-18`), so no implementation should ever throw it. A dead arm that looks live is an ambiguity S2/S3 implementers will resolve inconsistently — one will throw `not-found` where the contract says return `null`. Note this is a tension, not a defect: the alternative (per-adapter kind sets) was considered and rejected, and the substrate-neutral `quota-exceeded` shape is the right generalization.

**Recommendation:** Either delete the `not-found` arm and let the null convention be the only absence signal, or document at its declaration that it is reserved for future non-FS operations and must never be thrown by a `CorpusFS` method. Separately, consider whether S3 should extend rather than edit — e.g. `CorpusErrorKind = CorpusFsErrorKind | CorpusGitErrorKind` — so each interface owns its arms while the union stays single-source.

#### 7. `isCorpusEnabled(): boolean` is a one-bit switch for a choice space that becomes four-valued by S3

**Severity:** Minor
**Location:** `app/lib/corpus/flag.ts:15-25`
**Move:** Extension points
**Confidence:** Medium — depends on S2/S3 landing as scoped in the decomposition.

**Evidence:**
```ts
export function isCorpusEnabled(): boolean {
  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
  if (typeof window !== "undefined") {
    try {
      return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
```
(`flag.ts:15-20`)

**Legibility-target:** for-author

The decomposition names three degraded modes that "share one code path" — OPFS-only, FSA-no-remote, and full (`decomposition-corpus-architecture.md:74`) — plus the localStorage status quo. A boolean cannot express four states, so S2 and S3 each face the same fork: add a second boolean (combinatorial, and the invalid combinations become reachable) or replace the flag (and re-touch every call site). Worth noting the smaller irony that the corpus module reads its own configuration from `localStorage` — the substrate it exists to replace — so the corpus path cannot be enabled in an environment where localStorage is unavailable, and the flag is the one localStorage dependency S4's migration cannot delete.

**Recommendation:** Widen now, while there is exactly one call site: `corpusMode(): "localStorage" | "opfs"` returning a union that S2/S3 extend, rather than a boolean they must replace. Cost is a few lines; the alternative is a flag-shape migration in the middle of each of the next two sub-tasks.

#### 8. The layout contract (`paths.ts`, `manifest.ts`) has no consumer, so its fitness is unvalidated by anything but its own tests

**Severity:** Minor
**Location:** `app/lib/corpus/paths.ts`, `app/lib/corpus/manifest.ts`
**Move:** Module boundary audit
**Confidence:** High — grep for importers found only `__tests__/paths.test.ts` and `__tests__/manifest.test.ts`.

**Evidence:** `storeAdapter.ts:15-18` imports `zustand/middleware`, `./types`, `./opfsAdapter`, `./flag` — neither `./paths` nor `./manifest` appears in any non-test import in the repo at 2dc403e.

**Legibility-target:** for-orchestrator-synthesis

Contracts-first is the stated strategy and shipping S0 ahead of its consumers is defensible — the interfaces are the deliverable. The structural observation is that 225 lines of layout and manifest contract will not meet a real caller until S4, so the feedback loop on whether the shape fits (Is `ArtifactPointer` enough for undo/redo? Does `safeSegment` round-trip a title well enough for S2's user-visible folder?) is deferred by three sub-tasks — while the one write path that *does* execute deliberately routes around it (Finding 1). Combined, these mean the layout is not merely unvalidated but actively contradicted by the shipped behavior.

**Recommendation:** No structural change required; treat as a tracked risk. The cheapest partial mitigation is Finding 1's fix — routing the state blob through `paths.ts` gives the layout module one real production caller today.

#### 9. The in-memory fake is a cross-module public artifact living in a `__tests__` directory

**Severity:** Informational
**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts`; imported at `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts:15`
**Move:** Module boundary audit
**Confidence:** High

**Evidence:**
```ts
import { createInMemoryCorpusFs } from "@/app/lib/corpus/__tests__/inMemoryCorpusFs";
```
(`workspaceStore-corpus-flag.test.ts:15`)

**Legibility-target:** for-author

`createInMemoryCorpusFs` and `defineCorpusFsContract` are effectively part of the corpus module's published surface — S2, S3, and S4 tests will all want both — but they live under `__tests__/`, a path convention that signals module-private and that build tooling commonly excludes. The store's test already reaches across the boundary into it. Same note applies to `assertNever` (`types.ts:94`), a general-purpose helper exported from the corpus error module that any exhaustive switch elsewhere in the app will now import from `corpus/types`.

**Recommendation:** Consider `app/lib/corpus/testing/` (or `corpus/fixtures/`) for the fake and the contract-suite definition, leaving `__tests__/` for actual spec files. Low urgency; cheapest to do now, before three more sub-tasks import the current path.

---

### What Looks Good

- **Interface segregation on `CorpusFS` is disciplined and explicitly defended.** Five methods, all of which every implementation genuinely needs, with git deliberately kept out and routed to a future `CorpusGit` layered *over* `CorpusFS` (`types.ts:19-22`). The reasoning is written down at the point of temptation, which is where it will actually be read.
- **Dependency direction is clean and one-way.** One production edge crosses into the new subtree; nothing in `corpus/` imports stores, utils, types, or components. This is the property that makes the whole S2–S5 plan viable, and it was achieved on the first pass.
- **The interface-typed injection point is real where it matters most.** `createCorpusBackedStorage(fs: CorpusFS)` (`storeAdapter.ts:52`) accepts the abstraction, and the flag test exercises it with a second implementation (`workspaceStore-corpus-flag.test.ts:42-43`) — the substitutability is demonstrated at the seam, not just asserted.
- **Bytes-and-paths rather than strings-and-keys, async throughout.** Both choices are argued from downstream requirements (binary PDFs; worker transport at S3) rather than taste, and they are the two decisions that would have been most expensive to reverse later.
- **The store's blast radius is one line, and the file shrank.** `storage: createJSONStorage(resolveWorkspaceStorage)` (`workspaceStore.ts:499`) replacing the inline adapter, with the debouncer moved verbatim and a characterization test pinning the OFF path. This is what a reversible substrate swap should look like.
- **Substrate-neutral `quota-exceeded {substrate}`** instead of the plan's original `opfs-quota-exceeded` — the code corrected its own plan in the right direction, so S2's FSA and any future remote reuse one arm and one UI state.
- **Path-traversal sanitization is concentrated in one module with an explicit invariant.** The invariant is currently violated (Finding 1), but the design — one choke point, throws rather than silently emptying — is correct and worth preserving.

---

### Summary Table

| # | Finding | Severity | Location |
|---|---------|----------|----------|
| 1 | Two incompatible corpus layouts coexist; only the undocumented `state/` blob is written | Structural | storeAdapter.ts:55 · paths.ts:4-19 |
| 3 | DI seam half-open: resolver hard-wires the concrete OPFS adapter at module eval; no composition point for S2/S3 | Structural | storeAdapter.ts:70-76 |
| 4 | Contract suite binds one implementation and under-specifies the aliasing/parent semantics the two already differ on | Structural | corpusFsContract.ts · inMemoryCorpusFs.ts:26-27 · opfsAdapter.ts:114-119 |
| 2 | `storeAdapter.ts` is a zustand-shaped consumer inside the substrate module | Coupling | storeAdapter.ts:15, 25-46 |
| 5 | Write-coalescing lives in one adapter branch rather than at a stated layer | Coupling | storeAdapter.ts:25-46 vs :56-67 |
| 6 | `CorpusErrorKind` is a shared union owned by no one; five unreachable arms, `not-found` unreachable by design | Coupling | types.ts:37-49 |
| 7 | Boolean flag for a choice space that becomes four-valued by S3 | Minor | flag.ts:15-25 |
| 8 | Layout contract has no production consumer; fitness unvalidated until S4 | Minor | paths.ts · manifest.ts |
| 9 | In-memory fake and contract-suite definition are cross-module public artifacts under `__tests__/` | Informational | corpus/__tests__/inMemoryCorpusFs.ts |

---

### Overall Assessment

The load-bearing structural decisions in this changeset are right, and they are the ones that would have been expensive to get wrong. The dependency direction is clean and acyclic, `CorpusFS` is properly segregated with git explicitly excluded, the interface is bytes-and-paths and async for reasons argued from S3's requirements, and the store's exposure is a single line behind a default-off flag with a characterization test pinning the old path. Judged as "does this foundation support S2–S5," the answer is largely yes.

The findings cluster into one theme: **the seam is correctly typed one level too deep.** `createCorpusBackedStorage(fs: CorpusFS)` honors the abstraction, but everything above it — which FS gets constructed (Finding 3), which layout the bytes land in (Finding 1), whether writes coalesce (Finding 5) — is fixed at module evaluation inside a single unparameterized function that also happens to live on the wrong side of the layer boundary (Finding 2). Each of S2 (composed FS with FSA fallthrough), S3 (worker-proxy FS), and S4 (blob→folder migration) will need to reopen exactly that function, which is the file the seam docs claim they will not have to touch. Finding 4 compounds it: the LSP guarantee that makes swapping implementations safe is currently underwritten by a suite that runs against one implementation and does not test the semantics the two already differ on.

None of this is expensive to correct now. Findings 1, 3, 6, and 7 are each a handful of lines while there is exactly one call site of each; Finding 4 is three additional contract cases. The same corrections after S2 lands cost a refactor across two substrates. The recommended sequence is 1 (route `state/` through `paths.ts`) → 4 (close the contract gaps and soften the LSP claim) → 3 and 7 (parameterize the resolver, widen the flag to a union) → 2 and 5 as a single relocation-plus-decorator pass. Findings 8 and 9 are worth noting and not worth blocking on.

---

## Goal-Alignment Note
- Answered: All eight briefed structural questions. Dependency direction mapped edge by edge (corpus subtree vs stores vs UI — one production edge, acyclic, no UI edge). Responsibility boundaries (Findings 2, 5). Module boundary audit including the specific question asked — the `CorpusFS` seam is minimal and intentional, but `storeAdapter.ts:55`'s hand-built `state/` path does leak past `paths.ts` and the consequence is two coexisting layouts (Finding 1). Layer violations (Finding 2, the zustand edge into the substrate module). Interface segregation — `CorpusFS`'s five methods are role-specific and git is correctly excluded (What Looks Good), with the error union as the counterweight (Finding 6). Substitutability — the contract suite exists, is instantiated against the fake only at this commit, and under-specifies three behaviors the implementations already differ on, so the LSP claim is weaker than a "documented but not run" framing suggests (Finding 4). Coupling surface — no cycles; the `workspaceStore→storeAdapter→flag/opfsAdapter` shape is a one-way chain whose weak point is the unparameterized resolver (Finding 3). Extension points for S2–S5 (Findings 3, 6, 7, 8), checked against `docs/working/decomposition-corpus-architecture.md`.
- Out of scope: Implementation quality — the missing defensive copy in `opfsAdapter.writeFile`, the `manifest.ts` silent field defaults and entry drops, the `NEXT_PUBLIC_` inlining risk, and the two stale comment references are all established by the fact-check and referenced only where they carry a structural consequence; their remediation belongs to the author or to the security/performance critics. Also out of scope: OPFS write throughput and the S3 postMessage cost of Finding 5 (performance critic); "DEV-ONLY" being unenforced and the production-reachable localStorage flag (security critic); naming conventions across the new public surface (API-consistency critic); running the vitest suite or the Playwright OPFS pass in the historical worktree (nothing newer than 2dc403e was executed). `docs/working/**` read as evidence of intended structure only.
- Escalate:
  1. **Finding 1 is the highest-leverage item and is cheap only right now.** It is simultaneously a broken invariant, an undocumented artifact that S2's mirror will surface into a user-visible folder, and an unplanned second migration for S4. The fact-check rated the *comment* Incorrect; the architectural consequence is larger than the comment.
  2. **Finding 3 should be decided before S2 starts, not during.** S2's specified "OPFS-first, fall through to FSA" read path is a composed `CorpusFS`, and the current resolver has nowhere to put a composition. If async capability probing turns out to be required at selection time, that is a design change (lazily-initializing `StateStorage`) worth its own decision record.
  3. **Finding 4 changes how much confidence to place in the S1 test suite.** CI green against the in-memory fake does not currently predict OPFS behavior on write aliasing, read aliasing, or file-as-parent — the exact axes S3's worker and S4's migration depend on. Downstream reviewers should not treat "contract suite passes" as evidence of substrate equivalence at this commit.
