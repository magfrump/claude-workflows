# Code Fact-Check Report — Corpus Pass 2 (CARRY-FORWARD, k=1)

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e3-loops/wt-corpus-arm, branch e3/corpus-arm)
**Arm:** Arm-Carry-K1 (carry-forward, k=1) — carrying pass-1 verdicts from the merged report at 2dc403e (/workspace/runs/review-arms/e1/corpus-dirty/code-fact-check-report.md)
**Scope:** Fixed state after pass-1 fixes; changed-set-scoped fresh check + carried-verified appendix. app/ only. HISTORICAL RULE honored: only ancestors of 409e9dc read.
**Checked:** 2026-08-06

**Commit:** 409e9dc
**Carry:** carried 0 / rechecked 30 / changed-set 14 files / carry-eligible-but-existential 0

---

## Carry-forward procedure log

### Step 1 — fix diff + changed-set

`git diff 2dc403e..409e9dc --name-only -- app/` (6 files changed by the pass-1 fix commit 409e9dc):

1. `app/lib/corpus/__tests__/corpusFsContract.ts`
2. `app/lib/corpus/__tests__/inMemoryCorpusFs.ts`
3. `app/lib/corpus/manifest.ts`
4. `app/lib/corpus/opfsAdapter.ts`
5. `app/lib/corpus/paths.ts`
6. `app/lib/corpus/storeAdapter.ts`

One-hop import closure (grep imports of/by these under app/lib/corpus + app/lib/stores):

- **Imported BY changed files:** `types.ts` (imported by manifest/opfsAdapter/storeAdapter/inMemoryCorpusFs/corpusFsContract), `flag.ts` (imported by storeAdapter). (`paths.ts`, `opfsAdapter.ts` are already in the changed set.)
- **Files that IMPORT changed files:** `workspaceStore.ts` (imports storeAdapter), `paths.test.ts`, `manifest.test.ts`, `opfsAdapter.test.ts`, `workspaceStore-corpus-flag.test.ts`, `corpusFs.contract.test.ts`.
- Excluded: `artifactEditHandlers.ts` — matched on keyword only; it imports no changed file (verified: no `from "…corpus/…"` import).

**CHANGED-SET (K = 14 files):** the 6 changed + `types.ts`, `flag.ts`, `workspaceStore.ts`, `paths.test.ts`, `manifest.test.ts`, `opfsAdapter.test.ts`, `workspaceStore-corpus-flag.test.ts`, `corpusFs.contract.test.ts`.

### Step 2 — claim partition

The fix diff, though small (a fix commit), edits the **hub files of the corpus module** (`paths.ts`, `manifest.ts`, `opfsAdapter.ts`, `storeAdapter.ts`, both test doubles). Its one-hop closure additionally sweeps in `types.ts`, `flag.ts`, and `workspaceStore.ts` — the three remaining source files that pass-1 claims cite. Result: **every pass-1 claim cites at least one changed-set file.**

| Partition | Count | Basis |
|---|---|---|
| CARRY-ELIGIBLE (Verified AND all cited files outside changed-set) | **0** | No pass-1 claim cites only files outside the changed-set. |
| MUST-RECHECK | **30** | All 30 — see below. |
| carry-eligible-but-existential (E) | **0** | The two absence/existential claims (Claim 1 "no NODE_ENV gate anywhere in app/lib/corpus/"; Claim 16 "every producer of CorpusError enumerated") are already MUST-RECHECK on the changed-file-citation rule, so they do not reduce a carry count that is already zero. Flagged per the known carry-limit rule. |

File-by-file basis for MUST-RECHECK (which changed-set file each claim cites):

- `flag.ts` (∈ closure): Claims 1, 2, 3
- `manifest.ts` (changed): Claims 4, 5, 6, 26(via ref)
- `paths.ts` (changed): Claims 6, 7, 8, 9, 10
- `storeAdapter.ts` (changed): Claims 3, 8, 11, 12, 13, 14, 19, 23, 29
- `workspaceStore.ts` (∈ closure): Claims 11, 14, 23, 24, 25, 29
- `types.ts` (∈ closure): Claims 4, 15, 16, 17
- `opfsAdapter.ts` (changed): Claims 15, 16, 18, 19, 20, 21, 28, 30
- `inMemoryCorpusFs.ts` (changed): Claims 15, 17, 20, 22
- `corpusFsContract.ts` (changed): Claims 15, 17, 21, 22, 27
- test files (∈ changed-set): Claims 7, 9, 10, 18, 22, 27, 28, 29, 30

Every claim (1–30) appears above → all 30 MUST-RECHECK. **The carry bought nothing on this diff.**

### Step 3 — fresh k=1 scoped check at 409e9dc

Ran a fresh k=1 fact-check over the changed-set at 409e9dc, including re-verifying the four pass-1 reds are closed and re-confirming the changed-set S0/S1 claims. No CARRY-ELIGIBLE appendix exists (partition was empty).

**What the fix changed (from `git diff 2dc403e..409e9dc`):**

- **R1** (Claim 8, was *Incorrect*): `storeAdapter.ts` no longer hand-builds `state/${name}.json`; it imports `stateBlobPath` from `paths.ts` (storeAdapter.ts:18, 58/62/65). `paths.ts` adds `STATE_DIR="state"` and `stateBlobPath(name)=`\``${STATE_DIR}/${safeSegment(name)}.json`\` (paths.ts:76, 81-83), and the layout diagram now documents `state/<name>.json` (paths.ts:8-10). The "only source of corpus paths … callers must never hand-concatenate" invariant (paths.ts:19-22) is now **true**, and the previously-undocumented `state/` dir is now in the diagram. **→ Verified (fixed).**
- **R2** (Claim 11 seam): `resolveWorkspaceStorage` now takes an injected `makeCorpusFs: () => CorpusFS = createOpfsCorpusFs` (storeAdapter.ts:79-84) — the composition seam arch-review R2 asked for; the OFF path still constructs nothing. **→ Verified (strengthened).**
- **R3** (Claim 22 contract suite): `corpusFsContract.ts` adds three cases (write-aliasing, read-aliasing, file-as-parent; it()-count 7→10). `inMemoryCorpusFs.ts` was aligned to OPFS semantics: `readFile` now returns `bytes.slice()` (copy-on-read) and `writeFile` calls `assertNoFileAncestor` (throws `CorpusError` kind "io" on a file used as a parent). Verified the OPFS adapter genuinely satisfies all three axes at 409e9dc: `readFile` returns `new Uint8Array(await file.arrayBuffer())` — fresh per read (opfsAdapter.ts:102); `writeFile` passes `bytes` through unchanged (opfsAdapter.ts:122); file-as-parent → `getDirectoryHandle(..,{create:true})` on a file raises `TypeMismatchError`, which is NOT swallowed on the create path (walkDir only maps not-found when `!create`, opfsAdapter.ts:73), so it funnels through `wrap` → `CorpusError` kind "io". Both implementations now diverge identically on the pinned axes.
- **R4** (Claim 20, was *Incorrect*): the orphaned "fresh ArrayBuffer view" comment is replaced by an accurate one — write copies before resolving, no defensive copy is made, plus an explicit S3 SharedArrayBuffer race note (opfsAdapter.ts:116-121). Comment now matches code. **→ Verified (fixed).**
- **Comment ambers:** Claim 12 (storeAdapter.ts:11 now says `paths.ts/manifest.ts`, not `layout.ts`) **→ Verified (fixed).** Claim 19 (opfsAdapter.ts:14 now references `createDebouncedLocalStorage in storeAdapter.ts:35`, the correct current location) **→ Verified (fixed).** Claim 4 (manifest.ts file-header comment rewritten to accurately state structural-fail-loud + within-array-lenient, manifest.ts:10-21) **→ Verified (fixed).**

**What did NOT change (re-confirmed unchanged at 409e9dc via diff + read):** `flag.ts`, `types.ts`, `workspaceStore.ts`, `manifest.test.ts`, `paths.test.ts` are untouched by the fix. `manifest.ts` **body** (parseManifest) is byte-identical — the silent entry-drops/field-defaults persist, and the `parseManifest` **docstring** "Throws a `CorpusError` on any malformation" (manifest.ts:77-80) is unchanged. Consequently the pass-1 verdicts on the code-behavior claims re-verify identically.

### Step 4 — merged report

Carried set is empty, so the report below is the fresh scoped verdicts for all 30 claims. Verdicts that re-confirm unchanged pass-1 findings are tagged `re-confirmed (code unchanged since 2dc403e)`; the seven fix-affected verdicts are tagged `fixed@409e9dc` / `improved@409e9dc`.

---

## Fresh scoped verdicts (all 30 claims re-checked at 409e9dc)

| # | Location | Pass-1 verdict | Pass-2 verdict | Note |
|---|---|---|---|---|
| 1 | flag.ts:4-10 | Mostly accurate | **Mostly accurate** | re-confirmed (flag.ts unchanged). "DEV-ONLY" still policy, no NODE_ENV gate (existential re-checked: zero matches in app/lib/corpus/). |
| 2 | flag.ts:9-10,16 | Mostly accurate | **Mostly accurate** | re-confirmed. Optional-chained `process.env?.NEXT_PUBLIC_CORPUS_FS` inlining risk unchanged. |
| 3 | flag.ts:4-7 / storeAdapter.ts:57-60 | Verified | **Verified** | re-confirmed. getItem now reads `stateBlobPath(name)` (R1) but still reads only injected CorpusFS from an empty root → defaults. |
| 4 | manifest.ts:10-21 (header) | Mostly accurate | **Verified** | `fixed@409e9dc`. Header rewritten: structural fail-loud + explicit within-array leniency now accurately match the code. |
| 5 | manifest.ts:77-80 (parseManifest docstring) | Mostly accurate | **Mostly accurate** | re-confirmed. Function docstring "any malformation" is UNCHANGED and still overstated at entry/field level; `manifestVersion` still not range-checked. |
| 6 | manifest.ts:5-8 / paths.ts:101-108 | Verified | **Verified** | re-confirmed. ArtifactPointer `{type,currentVersion}`; artifactVersionPath 1-based zero-pad intact. |
| 7 | paths.ts:4-23 (diagram) | Verified | **Verified** | re-confirmed + extended: diagram now includes `state/<name>.json` and a matching `stateBlobPath` builder exists — diagram still matches builders. |
| 8 | paths.ts:19-22 / storeAdapter.ts | **Incorrect** | **Verified** | `fixed@409e9dc` (R1). storeAdapter routes through `stateBlobPath`; no hand-concatenation remains; `state/` documented. Invariant now holds. |
| 9 | paths.ts:26-61 | Verified | **Verified** | re-confirmed. SAFE_SEGMENT/workspaceSlug/safeSegment/safeExt unchanged; note `stateBlobPath` also applies `safeSegment` to the persist key. |
| 10 | paths.ts:101-108 | Verified | **Verified** | re-confirmed. VERSION_PAD=4, 1-based, non-positive/non-integer rejected. |
| 11 | storeAdapter.ts:52,79-86 | Verified | **Verified** | `improved@409e9dc` (R2). Seam typed `CorpusFS`; now also factory-injected via `makeCorpusFs`; workspaceStore binds only `resolveWorkspaceStorage`. |
| 12 | storeAdapter.ts:10-12 | **Stale** | **Verified** | `fixed@409e9dc`. Comment now reads "paths.ts/manifest.ts". |
| 13 | storeAdapter.ts:21-24 | Verified | **Verified** | re-confirmed. `createDebouncedLocalStorage` body byte-identical to dc6dfb0 original; 300ms debounce intact. |
| 14 | storeAdapter.ts:70 | Mostly accurate | **Mostly accurate** | re-confirmed. Still selected once at module eval (possibly SSR); factory param does not change the timing. |
| 15 | types.ts:17-18 / opfsAdapter / fake | Verified | **Verified** | re-confirmed. null/[]/no-op convention intact; fake now also copies on read (`bytes.slice()`), callers still never see undefined. |
| 16 | types.ts:27-67 | Verified | **Verified** | re-confirmed. Single CorpusErrorKind union; existential producer audit re-run — io/unavailable/quota-exceeded produced; not-found et al. still reserved. |
| 17 | types.ts:109-110 / opfsAdapter / fake | Verified | **Verified** | re-confirmed + hardened: intermediate-dir creation intact; fake now also rejects file-as-parent (R3) matching OPFS. |
| 18 | opfsAdapter.ts:9-11 | Verified | **Verified** | re-confirmed. SSR/unavailable guard + wrap re-throw unchanged. |
| 19 | opfsAdapter.ts:12-15 | **Stale** | **Verified** | `fixed@409e9dc`. Reference now points at `createDebouncedLocalStorage in storeAdapter.ts:35`. |
| 20 | opfsAdapter.ts:116-121 | **Incorrect** | **Verified** | `fixed@409e9dc` (R4). Comment now accurately describes pass-through + S3 SharedArrayBuffer race caveat. |
| 21 | opfsAdapter.ts:42-47 | Verified | **Verified** | re-confirmed. isNotFound/isQuota mapping + null/[]/idempotent-rm unchanged. |
| 22 | inMemoryCorpusFs.ts:4-6 | Mostly accurate | **Mostly accurate** | `improved@409e9dc` (R3). Divergence axes now pinned by the shared suite and the fake aligned to OPFS; BUT the OPFS adapter's run of the suite is still out-of-CI Playwright (not executed in CI) — "verified, not assumed" remains overstated on the adapter side. |
| 23 | workspaceStore.ts:5 | Mostly accurate | **Mostly accurate** | re-confirmed (workspaceStore.ts unchanged). Header still states debounce unconditionally; corpus branch writes on every set. |
| 24 | workspaceStore.ts:500-501 | Verified | **Verified** | re-confirmed. skipHydration + page.tsx rehydrate path intact. |
| 25 | workspaceStore.ts:502-507 | Verified | **Verified** | re-confirmed. merge + coercePersistedState validation intact. |
| 26 | commit ec7bbbc | Mostly accurate | **Mostly accurate** | re-confirmed (historical ancestor unchanged). Its "single choke point"/"never silent default-empty" summaries were defensible at ec7bbbc; note the end-state weakness Claim 8 flagged is now *resolved* by 409e9dc, but that does not change ec7bbbc's own-snapshot accuracy. |
| 27 | commit 3da6747 ("26 tests pass") | Verified | **Verified** | re-confirmed. Static 26 reconstructs at 3da6747's snapshot; the +3 R3 tests added at 409e9dc do not alter this historical count. |
| 28 | commit f6361a3 ("3 tests pass") | Verified | **Verified** | re-confirmed. opfsAdapter.test.ts 3 it() intact; behavioral clauses map to verified code. |
| 29 | commit 00ba8c3 ("69 tests pass") | Verified | **Verified** | re-confirmed at 00ba8c3's snapshot; one-line storage swap + moved-verbatim intact. |
| 30 | commit 122d70f ("324 tests pass") | Mostly accurate | **Mostly accurate** | re-confirmed. Static 324 at 122d70f's snapshot; rename rationale + import-update + writable narrowing intact. Its "left Claims 12/19 unfixed" sub-note was true at 122d70f (both are only fixed later, at 409e9dc). |

---

## Claims Requiring Attention (pass 2)

### Closed since pass 1 (were red/stale)
- **Claim 8** (R1) — `state/` path now routed through `paths.ts:stateBlobPath` and documented in the layout diagram; the "single source of corpus paths" invariant holds. The S2 FSA-mirror concern (undocumented `state/` replayed into user folders) is resolved — it is now a documented location.
- **Claim 20** (R4) — opfsAdapter write comment now accurate (pass-through, no copy) with an explicit S3 SharedArrayBuffer note.
- **Claim 12 / Claim 19** — the two stale pointers (layout.ts→paths.ts; workspaceStore.ts:44-46→storeAdapter.ts:35) are corrected.
- **Claim 4** — manifest header comment now accurately distinguishes structural fail-loud from within-array leniency.

### Still open (unchanged by the fix)
- **Claim 5** — `parseManifest` *docstring* still says "any malformation"; the fix corrected the file-header comment (Claim 4) but not this function docstring, so the entry/field-level silent-drop/default overstatement persists here. `manifestVersion` still not range-checked against `MANIFEST_VERSION`.
- **Claim 1 / Claim 2** — flag.ts untouched: "DEV-ONLY" remains policy-not-mechanism; the optional-chained `NEXT_PUBLIC_CORPUS_FS` inlining path remains untested and possibly a silent no-op under Turbopack.
- **Claim 22** — R3 aligned the fake and pinned the divergence axes, but the OPFS adapter's contract run is still out-of-CI Playwright; "substitutability verified, not assumed" remains aspirational on the adapter side in CI.
- **Claim 23** — store header still states debounced rate-limiting unconditionally; corpus branch writes on every set.
- **Claim 14** — storage still selected once at module eval (possibly SSR); flag changes still require a reload.

---

## Carry-forward efficacy note (for the arm comparison)

This arm was chosen to measure carry on a **large diff where carry should pay**. On this fix it did **not**: the pass-1→pass-2 delta (409e9dc) is a small fix commit, but it edits the **hub files** of `app/lib/corpus/` (paths, manifest, opfsAdapter, storeAdapter, both test doubles), and the one-hop import closure pulls in the module's three remaining source files (types.ts, flag.ts, workspaceStore.ts). The changed-set (14 files) therefore covers **every file any pass-1 claim cites**, so all 30 Verified/non-Verified claims fell into MUST-RECHECK and 0 carried. Carry pays when a large diff is *localized* (leaves many cited files untouched); here the diff was small but *central*, and centrality — not diff size — is what determines carry yield. The two existential claims (1, 16) would have been forced to recheck regardless, but that rule was not load-bearing since neither was carry-eligible on the file-citation rule anyway.
