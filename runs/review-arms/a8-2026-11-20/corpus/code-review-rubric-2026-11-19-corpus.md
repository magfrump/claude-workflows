Commit: 2dc403e

# Code review rubric: corpus (dc6dfb0..2dc403e -- app/), A8 inline pass

Status: 1 red, 9 amber. Do not merge. Delivery mode: inline-diff-only (part 5 with enclosing files was about 30.9k tokens, over the 25k budget). Terminal pass: k=3 fact-check, 6 critics in parallel, Stage 2.5 on 7 routed claims. Synthesized inline by the orchestrator (not an agent; not in the token totals). Override log: the reviewed repo has none; no prior overrides matched this diff.

## 🔴 Must Fix

| ID | Finding | Location | Source | Severity |
|---|---|---|---|---|
| R1 | Rehydration reads localStorage to decide whether the store is empty, bypassing the new storage layer. With the flag on, the check always finds nothing and, if a `workspace-v2` key exists, `migrateFromV2()` overwrites the OPFS state on every reload (the key is never removed); that data also skips `coercePersistedState` | `app/lib/stores/workspaceStore.ts:528-543` | architecture Structural #1; security Low #2; api F9; tech-debt TD4; test-strategy G12; fact-check Claims 12, 14 (r2) and Stage 2.5 escalation | Structural |

## 🟡 Must Address

| ID | Finding | Location | Source |
|---|---|---|---|
| A1 | "DEV-ONLY" flag is not gated; the localStorage key (or a build with the env var) enables it in production | `app/lib/corpus/flag.ts:4,15-25` | security Medium #1; fact-check Claim 2 (Incorrect 3/3) |
| A2 | Manifest codec is not fail-loud: malformed entries are filtered out, timestamps default to now, `manifestVersion` unchecked, only kind "io" is ever thrown | `app/lib/corpus/manifest.ts:10-14,84-114` | fact-check Claims 3, 4 (executed 3/3); api F1, F11; architecture Minor #6; tech-debt TD2; test G7, G8 |
| A3 | The OPFS adapter is never run against the shared contract suite, though four docstrings and a commit say it is; fake and OPFS differ on name clashes, rm of a directory and `""`/`"/"` paths | `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-8` and siblings | fact-check Claim 1 (Incorrect 3/3); architecture Coupling #3; tech-debt TD1; test G1, G6; Stage 2.5 Claim 28 |
| A4 | `state/${name}.json` is hand-built outside `paths.ts`, which claims to be the only source of corpus paths; no production code imports `paths.ts` | `app/lib/corpus/storeAdapter.ts:55`; `paths.ts:16-19` | fact-check Claim 6 (Incorrect 3/3); api F10; architecture Minor #5; tech-debt TD7 |
| A5 | Stale comments: `workspaceStore.ts:44-46` reference and `layout.ts` name; "fresh ArrayBuffer view" is false | `opfsAdapter.ts:14,115`; `storeAdapter.ts:11` | fact-check Claims 5, 7, 8 (3/3); tech-debt TD5 |
| A6 | Corpus `setItem` has no debounce and no write ordering: a full-blob OPFS write per `set()`, an older snapshot can land last; rejections go unhandled | `app/lib/corpus/storeAdapter.ts:52-68` | performance Medium #1; security Low #3; api F8; tech-debt TD3; Stage 2.5 Claim 26 (executed) |
| A7 | Store seam is typed `StateStorage`, not `CorpusFS`; `createOpfsCorpusFs()` is hard-wired, so nothing can inject a CorpusFS | `storeAdapter.ts:5-8,70-76`; `workspaceStore.ts:496-498` | architecture Coupling #2; fact-check Claim 11 (MA 3/3) |
| A8 | `paths.ts` throws bare `Error` while the module's error model is `CorpusError` | `app/lib/corpus/paths.ts:43-45,89-91` | api F2 |
| A9 | Custom-type artifacts path diverges from the DD-009 layout (`artifacts/custom/<id>/`) | `app/lib/corpus/paths.ts:82-84` | api F3 |

## 🟢 Consider

- C1 security Low #4, performance Low #2, test G3: `close()` in the `finally` can mask a quota error as "io".
- C2 security Low #5: distinct titles collide on one slug ("My WS", "my-ws").
- C3 api F4, F5, F6, F7, F12: type and naming conventions (plain `string` ids, `currentVersion` 1-based, `CorpusFS` casing, `SourceRef` field names).
- C4 architecture Minor #4: `storeAdapter.ts` (zustand, legacy adapter, flag selection) belongs under `app/lib/stores/`.
- C5 test G2, G4, G9, G10, G11, G13, G14: untested arms (not-found returns, "io" wrap, CorpusError into persist, debounce timing, env route, flag-on bytes).
- C6 fact-check Claim 24: `process.env?.NEXT_PUBLIC_CORPUS_FS` may not be inlined by Next (unverifiable without a build).
- C7 performance Info #3: `getDirectory()` re-walked per operation.

## ✅ Confirmed Good

- Slug and id sanitizers produce no traversal segment (Stage 2.5 Claim 30, executed over 200,019 inputs). Not covered: collisions (C2), the hand-built `state/` path (A4).
- The unavailable guard rejects with `{kind:"unavailable"}` on every absent shape (Claim 32, executed). A present-but-throwing `getDirectory()` maps to "io".
- Corpus blobs pass the same `merge` → `coercePersistedState` validation as localStorage (Claim 31, executed). Not covered: the `migrateFromV2` path (R1).

## ⏭️ Skipped Core Critics

None. ui-visual-review and dependency-upgrade not selected at Step 5 (no UI code or manifest in `app/` scope).

## 🧩 Composition check

- `workspaceStore.ts:528-543` cluster (architecture #1, security #2, api F9, TD4, test G12): distinct sightings of one defect, R1, stated whole by architecture #1.
- `storeAdapter.ts:52-68` cluster (performance #1, security #3, api F8, TD3): one defect, A6, stated whole by performance #1.
- `manifest.ts:84-114` cluster: one defect, A2, stated whole by fact-check Claim 3.

Single-sample review; absence of findings is not an attestation.
