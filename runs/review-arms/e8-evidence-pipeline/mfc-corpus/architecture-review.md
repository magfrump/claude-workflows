# Architecture Review — DD-009 corpus storage substrate (mfc-corpus)

**Scope:** `git diff dc6dfb0...HEAD` — OPFS storage substrate behind a Zustand persist adapter (`storeAdapter`/`opfsAdapter`), manifest codec, corpus feature flag, and the rehydration/migration path in `workspaceStore.ts`.
**Commit:** 2dc403e
**Date:** 2026-08-18
**Based on:** code-fact-check report `runs/review-arms/e8-evidence-pipeline/mfc-corpus/code-fact-check-report.md` (18 claims; its verdicts bind — migration firing conditions and manifest field-default behavior were executed there).

Trust-boundary cross-reference is a no-op here: no security-reviewer output was consulted (blinded from `docs/reviews/`), so module-boundary findings below carry no security-boundary labels.

## Dependency Map

The new subsystem lives in `app/lib/corpus/` and is consumed by the existing `app/lib/stores/workspaceStore.ts`:

```
workspaceStore (persist middleware)
  └── storeAdapter.resolveWorkspaceStorage()
        ├── isCorpusEnabled()                         [flag.ts]
        ├── createDebouncedLocalStorage()   (OFF)     [localStorage, concrete]
        └── createCorpusBackedStorage(fs)   (ON)
              └── createOpfsCorpusFs(): CorpusFS       [opfsAdapter.ts, concrete]
                    └── CorpusError / CorpusErrorKind  [types.ts]

paths.ts     — folder-layout path builders (workspaces/<slug>/…)   NOT imported by storeAdapter
manifest.ts  — workspace.json codec, depends on CorpusError         NOT imported by the store (S4)
```

Dependency direction is mostly correct: the store binds to the `CorpusFS` *interface* (`types.ts`), and the concrete OPFS adapter is injected through `resolveWorkspaceStorage`. The stable core (interface + error model) sits below the volatile adapters. Two seams, however, reach around this structure — the rehydration callback and the store-adapter path builder — and those are where the findings concentrate.

## Findings

#### Rehydration/migration seam fires ungated by the corpus flag and bypasses the storage abstraction

**Severity:** Structural
**Location:** `app/lib/stores/workspaceStore.ts:528-543` (with `app/lib/corpus/flag.ts:4-7`, `app/lib/corpus/storeAdapter.ts:52-68`)
**Move:** #4 Layer violation / #3 module boundary
**Confidence:** High

The whole diff introduces a storage *seam* — the store persists through `StateStorage`, and `storeAdapter.ts:6-8` states the goal explicitly ("the store ever knowing which adapter it talks to"). But `onRehydrateStorage` reaches *around* that seam and reads `localStorage` directly (`localStorage.getItem(WORKSPACE_KEY)` and `localStorage.getItem("workspace-zustand-v1")`, lines 533-534) to decide whether to run `migrateFromV2()`. When the corpus flag is ON, the persisted zustand blob lives in OPFS at `state/workspace-zustand-v1.json` (`storeAdapter.ts:55`), **not** in localStorage — so `zustandRaw` is always `null`, `hasZustandData` is always `false`, and if any legacy `workspace-v2` key exists in localStorage, `migrateFromV2()` fires on **every** load. `migrateFromV2()` calls `useWorkspaceStore.setState(...)` (`workspaceStore.ts:269`), which the persist middleware then writes through the *corpus* adapter — so the stale v2 snapshot is injected into the store and clobbered over the OPFS corpus state on each reload. This directly contradicts the flag's documented contract (`flag.ts:4-7`: "enabling this starts from an EMPTY corpus and does not carry existing localStorage work over … no migration until S4"). The fact-check verified the *adapter* has no migration (Claim 3) and that the firing condition is broader than documented (Claim 17), but neither claim addresses this cross-cutting interaction: the migration gate is coupled to a concrete substrate (localStorage) that the corpus mode no longer uses, so a legacy migration re-fires over corpus state.

**Recommendation:** Gate the migration on `!isCorpusEnabled()` (S4 owns corpus migration per the flag docstring), and route the "is there prior persisted state?" probe through the selected `StateStorage`/`CorpusFS` seam rather than reading `localStorage` directly, so the check works regardless of substrate.

#### Typed `CorpusError` is reified by the adapter but dropped by the store seam — the failure-driven-UI pipeline has no consumer

**Severity:** Coupling
**Location:** `app/lib/corpus/storeAdapter.ts:57-63` (write path), `app/lib/stores/workspaceStore.ts:529-530` (read path); contract at `app/lib/corpus/types.ts:36-49`
**Move:** #1 dependency direction / cross-cutting error-handling pipeline
**Confidence:** High

`types.ts:36-49` frames the entire `CorpusErrorKind` union as the backbone of a "failure-driven-UI mandate" — every failure is reified into a typed, exhaustively-switchable error so consumers must handle it at compile time. The OPFS adapter honors this (Claims 8/9/16). But the store seam — the only S1 consumer — discards the typing at both ends. On write, `setItem` awaits `fs.writeFile` with **no catch** (`storeAdapter.ts:62`), so a reified `quota-exceeded`/`io` `CorpusError` propagates into zustand persist as an unhandled rejection (fact-check Claims 9/16 Scope notes). On read, a non-NotFound `readFile` rejection surfaces in `onRehydrateStorage`, whose `if (error) return` (`workspaceStore.ts:530`) silently discards it — and a later `setItem` then persists defaults over the still-present file (clobber-on-read-error). The architectural consequence: the typed-error abstraction the diff builds terminates at the seam that was supposed to consume it, so the "failure-driven UI" it exists to enable cannot observe any corpus failure. The abstraction is introduced without a landing point.

**Recommendation:** Give the store seam an explicit error boundary — catch the `CorpusError` in `setItem`/`getItem` and route it to whatever surface will own corpus-failure UI (even a typed callback stub for now), rather than letting typed failures become unhandled rejections or be dropped by `onRehydrateStorage`.

#### `storeAdapter` hand-concatenates `state/<name>.json`, a parallel path namespace outside the documented single choke point

**Severity:** Coupling
**Location:** `app/lib/corpus/storeAdapter.ts:55` vs. `app/lib/corpus/paths.ts:16-19`
**Move:** #3 module boundary
**Confidence:** High

`paths.ts:16-19` declares itself the sole authority for corpus paths: "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`." `storeAdapter.ts` does not import `paths.ts` at all; it defines its own `pathFor = (name) => \`state/${name}.json\`` (line 55), introducing a second, parallel corpus namespace (`state/`) that `paths.ts` neither knows about nor guards — and that isn't in the folder-layout docstring (`paths.ts:4-14`). So the "only source of corpus paths is this module" invariant is already false at introduction. Fact-check Claim 12 verified the choke-point guarantee holds for `workspaces/`, and its Scope explicitly notes it "does not verify callers never bypass it" — this is that bypass. There is no *security* exposure today: `name` is the compile-time constant persist key (`"workspace-zustand-v1"`), not untrusted input. But the module boundary is breached: the documented single-source-of-truth is a fiction, and if a later sub-task parameterizes the persist key or adds per-workspace `state/` files, the bypass means the traversal guard silently does not cover them.

**Recommendation:** Either add a `statePath(name)` builder to `paths.ts` and route `storeAdapter` through it (restoring the single choke point), or narrow the `paths.ts` docstring to say it governs only the `workspaces/` layout and acknowledge `state/` as a separately-owned namespace.

#### Manifest codec contract is incoherent: fail-loud on structural fields, silent-coerce on metadata fields

**Severity:** Minor
**Location:** `app/lib/corpus/manifest.ts:10-14`, `:69-73`, `:87-113`
**Move:** #3 data-model contract boundary
**Confidence:** High (behavior bound by fact-check Claims 6/7, executed)

The manifest is the persisted workspace-index contract boundary. Both its header docstring (`:10-14`, "FAIL-LOUD … never a silent default") and its per-function docstring (`:69-73`, "Throws … on any malformation") advertise a strict, throw-on-anything contract. The codec's actual behavior is split: structural fields (`title`, `manifestVersion`, non-array `sources`/`artifacts`/`customTypeIds`, and object-but-incomplete source entries) fail loud, while metadata fields silently coerce — `createdAt`/`updatedAt` are fabricated from `new Date()` (`:109-110`), a missing source `label` defaults to the id (`:89`), and non-object sources / non-string custom-type ids are dropped by pre-map filters (`:87,103`). Fact-check verdicts: Claim 6 Mostly accurate (header), Claim 7 Incorrect (per-function). The architectural point beyond the doc mismatch: this boundary has no single coherent contract — a consumer cannot know from the type or the docstring whether the codec is a strict validator or a lenient normalizer, and the answer differs field by field. That ambiguity is a liability at a persisted-data boundary that S4 migration will build on.

**Recommendation:** Pick one contract and make it uniform — either fail loud on all malformed fields (including metadata) or document the codec as an intentional lenient normalizer with an explicit list of coerced fields. Align both docstrings to whichever is chosen.

## What Looks Good

- **Interface-first injection.** The store binds to `CorpusFS` (an interface in `types.ts`), not to the OPFS adapter, and the concrete adapter is injected at `resolveWorkspaceStorage` (`storeAdapter.ts:71-76`). The S3 worker-proxy is a genuine drop-in — correct dependency direction (volatile adapter → stable interface).
- **Interface segregation done deliberately.** `types.ts:19-22` keeps git off `CorpusFS` and reserves it for a separate `CorpusGit` interface — a conscious ISP choice that spares the in-memory fake and non-git consumers from stubbing methods they don't use.
- **Single-source error model with an exhaustiveness guard.** `CorpusErrorKind` is one union consumed by an `assertNever` switch (`types.ts:78-96`), so adding a kind forces every consumer to handle it at compile time. This is the right shape for the failure-driven-UI goal — the gap (finding 2) is only that the store seam doesn't yet consume it.
- **`workspaceSlug` choke-point design** (`paths.ts:36-47`) is sound where it is actually routed through (the `workspaces/` builders); the issue in finding 3 is a bypass, not a flaw in the guard itself.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Rehydration/migration seam ungated by corpus flag; bypasses storage seam, re-fires v2 over corpus state | Structural | `workspaceStore.ts:528-543` | High |
| 2 | Typed `CorpusError` reified by adapter but dropped by store seam (write unhandled-rejection; read clobber) | Coupling | `storeAdapter.ts:57-63`, `workspaceStore.ts:529-530` | High |
| 3 | `state/<name>.json` hand-concatenated outside `paths.ts` single-choke-point invariant | Coupling | `storeAdapter.ts:55` vs `paths.ts:16-19` | High |
| 4 | Manifest codec contract incoherent (fail-loud vs silent-coerce, field-dependent) | Minor | `manifest.ts:10-14,69-73,87-113` | High |

## Overall Assessment

The core substrate design is structurally sound — interface-first injection, a well-segregated FS seam, and a single-source typed error model are exactly the right bones for the staged DD-009 build. The structural risk is concentrated at the two seams that reach around the abstraction the diff just introduced. The single most important concern is finding 1: the rehydration/migration path is gated on a concrete substrate (localStorage) the corpus mode no longer writes to, so with the flag ON and legacy `workspace-v2` present, `migrateFromV2()` re-fires on every load and clobbers corpus state — directly violating the flag's "starts from an EMPTY corpus" contract. That is fixable in place (gate on `!isCorpusEnabled()` and probe through the seam) and does not indicate a need to restructure the substrate. Findings 2 and 3 are also in-place fixes that would restore the abstraction boundaries (typed-error consumption; single path authority) the module already documents but does not yet enforce.
