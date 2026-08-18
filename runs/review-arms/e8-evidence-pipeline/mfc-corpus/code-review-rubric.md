# Code Review Rubric

**Scope:** mfc-corpus DD-009 corpus-architecture (`dc6dfb0...2dc403e`) | **Reviewed:** 2026-08-18 | **Commit:** 2dc403e | **Status: 🔴 DOES NOT PASS** — 1 red item unresolved

Change under review: OPFS/`storeAdapter` storage seam, `NEXT_PUBLIC_CORPUS_FS` manifest codec, path builders, and rehydration/migration — the entire ON path behind a **DEV-ONLY, default-off** flag (`isCorpusEnabled`, fact-check Claim 2, Verified). Production blast radius today is near-zero; see [How flag-gating affected severities](#how-flag-gating-affected-severities). Dispatch: k=2 fact-check (one replicate failed), Stage 2.5 ran (3 routed claims). All core critics ran.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | **Rehydration/migration seam fires ungated by the corpus flag.** `onRehydrateStorage` reads `localStorage` directly to decide `migrateFromV2()`; with the flag ON the persisted blob lives in OPFS, so `zustandRaw` is always `null`, `hasZustandData` always `false`, and any legacy `workspace-v2` key makes `migrateFromV2()` re-fire on **every load** — injecting the stale v2 snapshot through the corpus adapter and clobbering corpus state, directly violating the flag's documented "starts from an EMPTY corpus … no migration until S4" contract. | Architecture | Structural | `workspaceStore.ts:528-543` (with `flag.ts:4-7`, `storeAdapter.ts:52-68`) | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | **Data-loss clobber cluster — typed `CorpusError` dropped at the store seam.** Write path `await fs.writeFile` has no catch (reified quota/io rejection → unhandled rejection); read path non-NotFound rejection is discarded by `onRehydrateStorage`'s `if (error) return`, then the next `setItem` persists defaults over the still-intact file → silent whole-workspace loss. `Convergence: security + architecture (+ tech-debt D2, highest-ranked).` | Security + Architecture | Medium / Coupling | Security (Finding 2 Medium + Finding 3 Low) + Architecture (Finding 2 Coupling) + tech-debt D2 | for-author | — | 🟡 Open | — |
| A2 | **Un-serialized concurrent OPFS writes to the same state file (lost-update race).** persist dispatches `setItem` fire-and-forget with no cross-call await/queue/lock, so two `writeFile` sequences overlap on `state/workspace-zustand-v1.json` and can complete out of issue order (torn/stale blob). `Convergence: performance + fact-check SC2; executed corroboration (probe maxConcurrent=2).` Held at 🟡 on flag-gating grounds — see severity note. | Performance | High | Performance (Finding 2) + FC submitted-claim SC2 (**executed**, D5 write-race) + tech-debt D1 | for-author | — | 🟡 Open | — |
| A3 | **Un-debounced full-blob OPFS write per state mutation (write amplification).** ON-path `setItem` drops the OFF-path 300ms debounce, so each keystroke fires a ~6-op full-blob OPFS rewrite; ~100 OPFS writes for a 100-char edit. | Performance | High | Performance (Finding 1) + FC submitted-claim SC3 (per-keystroke, static) + tech-debt D1 | for-author | — | 🟡 Open | — |
| A4 | **DEV-ONLY flag has no NODE_ENV/production gate (enforceable in production).** Tested: with `NODE_ENV=production`, both `NEXT_PUBLIC_CORPUS_FS=1` and the `localStorage["corpus-fs-enabled"]="1"` opt-in return `true`; a single browser-console `setItem` flips a prod instance to the empty corpus. This is the finding that undercuts the "dev-only" premise the rest of the flag-gating rests on. | Security | Medium | Security (Finding 1, move #11, **executed**, N11) | for-author | — | 🟡 Open | — |
| A5 | **`storeAdapter` hand-concatenates `state/<name>.json`, bypassing the `paths.ts` choke point.** Violates the documented "only source of corpus paths … callers must never hand-concatenate" contract and introduces a `state/` namespace absent from the layout catalog — no live traversal bug today (`name` is the constant persist key), but the "single choke point" invariant is already false at introduction. `Convergence: api-consistency + architecture.` | API + Architecture | Inconsistent / Coupling | API-consistency (Finding 2) + Architecture (Finding 3) | for-author | — | 🟡 Open | — |
| A6 | **Manifest codec contract incoherent (docstrings promise fail-loud, code coerces).** Both docstrings advertise "FAIL-LOUD … never a silent default" / "throws on any malformation," but `createdAt`/`updatedAt`/`label` are silently coerced and non-object sources / non-string custom-type ids dropped; the per-function docstring is factually Incorrect. `Convergence: fact-check + api-consistency + architecture (+ tech-debt D3).` | Fact-check + API + Architecture | Incorrect (doc) / Inconsistent / Minor | FC Claim 7 (Incorrect, doc-only) + Claim 6 (Mostly accurate) + API-consistency (Finding 3) + Architecture (Finding 4) + tech-debt D3 | for-author | — | 🟡 Open | — |
| A7 | **`WorkspaceManifest.customTypeIds` drops the app-wide `customArtifactType*` qualifier** and types ids as bare `string[]` not `CustomArtifactTypeId[]` — right on the S4 reconciliation path where the store's `customArtifactTypes[].id` maps in. | API consistency | Inconsistent | API-consistency (Finding 1) | for-author | — | 🟡 Open | — |
| A8 | **Stale / incorrect cross-reference comments (3).** `opfsAdapter.ts:14` points at deleted `workspaceStore.ts:44-46` (swallow now at `storeAdapter.ts:34-35`); `storeAdapter.ts:11` says `layout.ts` (renamed `paths.ts`, Next reserved name); `opfsAdapter.ts:115` "Pass a fresh ArrayBuffer view" describes a copy the next line never makes (`write(bytes)` passes the caller's reference unchanged — Incorrect, executed). | Fact-check | Stale (×2) / Incorrect-comment | FC Claims 10, 14 (Stale) + Claim 11 (Incorrect, comment-only) + tech-debt D4 | for-author | — | 🟡 Open | — |
| A9 | **Docstring wording imprecisions (Mostly accurate).** "byte-for-byte" for the OFF-path adapter is behaviorally true but literally false (renamed + retyped); the migration firing condition "if the Zustand key is absent" is narrower than the code, which also fires on a present-but-empty/corrupt key. | Fact-check | Mostly accurate (×2) | FC Claims 15, 17 | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `getRoot()` re-resolves the OPFS root handle on every op (no caching) — compounds the write amplification on the ON path. Memoize behind a lazy promise. | Performance (Finding 3) | Low | for-author | — | 🟢 Open |
| C2 | `splitPath` has no own `.`/`..` guard — traversal is stopped only at the browser OPFS layer. Defense-in-depth gap if a future caller bypasses `paths.ts` (mechanism preserved: unsanitized path → `splitPath` forwards `..` verbatim → only OPFS runtime rejects). | Security (Finding 4) | Informational | for-author | — | 🟢 Open |
| C3 | `not-found` `CorpusErrorKind` is declared and exhaustively handled but never produced (absence is a null return by contract) — a phantom branch a future consumer may `catch` on. | API-consistency (Finding 4) | Minor | for-author | — | 🟢 Open |
| C4 | `migrateFromV2`/rehydrate parse cost is a cold, once-per-load O(blob) path, inert absent v2 data (Claim 17 executed) — no hot-path concern. | Performance (Finding 4) | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C5 | Build-time `NEXT_PUBLIC_CORPUS_FS` inlining could **not** be confirmed — `next build` is network-blocked (Google Fonts fetch in `next/font/google` fails offline), so no client bundle was produced to grep. Named blocker; re-run networked and grep the built output. | Fact-check (Claim 4) | Unverifiable | for-author | — | 🟢 Open |
| C6 | Two parallel persistence models carried until S4 (blob `state/*.json` vs. folder-per-artifact `manifest.ts`+`paths.ts`, built-but-unused) — staged, documented, intentional deferral, not rot. | Tech-debt D5 (advisory) | — | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

Every row passed the Confirmed-Good cross-check (evidence grounded; provenance rule 5 — executed verdict or a static `Verified` whose `Scope:` covers the row's full breadth; no contradicting observation in the merged or per-replicate reports). SC2 and SC3 are **not** here — both are Verified but back defect findings (A2, A3), not strengths.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| OPFS unavailable-guard throws typed `CorpusError{kind:"unavailable"}` before any raw property access on `navigator.storage` (SSR/unsupported → typed error, not `TypeError`). | ✅ Confirmed | `opfsAdapter.ts:50-53` — guard throws before dereference; **executed** under jsdom (`readFile` rejected `{kind:"unavailable"}`). The same `getRoot()` fronts `writeFile`/`readdir`/`rm`/`stat` by static inspection; only `readFile` was run. `FC Claim 8 (executed)` = `Stage-2.5 SC1 (Verified, executed)`. | Fact-check + security endorsement | for-orchestrator-synthesis |
| OPFS adapter maps a `QuotaExceededError`/`QUOTA_EXCEEDED_ERR` DOMException to `CorpusError{kind:"quota-exceeded", substrate:"opfs"}` in `wrap()`, rather than swallowing with `console.warn` like the localStorage adapter. | ✅ Confirmed | `opfsAdapter.ts:45-47,81` — `if (isQuota(e)) throw new CorpusError({kind:"quota-exceeded",substrate:"opfs"})`. Scope = adapter mechanism only (not whether a browser emits those names; not UI surfacing — the seam drops it, A1). `FC Claim 9 (Verified, static; scope covers row)`. | Fact-check | for-orchestrator-synthesis |
| `CorpusFS` signals absence by returning `null` (`readFile`/`stat`) / `[]` (`readdir`) and funnels every other error through `wrap()` into a typed `CorpusError`; no path returns `undefined`. | ✅ Confirmed | `opfsAdapter.ts:79-105,125-137` — `if (!dir) return null` / `return []`; `wrap` → `CorpusError{kind:"io"}`. Scope = not-found paths shown (OPFS success path not runnable under jsdom). `FC Claim 16 (Verified, static; scope covers row)`. | Fact-check | for-orchestrator-synthesis |
| `workspaceSlug` collapses any char outside `[a-zA-Z0-9_-]` to a hyphen (via `SAFE_SEGMENT`, after NFKD) and throws on an all-unsafe title. | ✅ Confirmed | `paths.ts:28,37-46` — `SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g` + empty-slug throw. **Scope = the sanitizer's strip/throw behavior only** — NOT the "single choke point / callers never bypass" universal (contested by R1/A5). `FC Claim 12 (Verified, static; scope narrowed to sanitizer)`. | Fact-check | for-orchestrator-synthesis |
| `isCorpusEnabled()` is default-off: with no env var and no localStorage opt-in, every branch falls through to `return false`. | ✅ Confirmed | `flag.ts:15-25` — no `NEXT_PUBLIC_CORPUS_FS`, no `CORPUS_FLAG_KEY` → `return false`. `FC Claim 2 (Verified, static)`. (Load-bearing for the whole flag-gating severity argument.) | Fact-check | for-orchestrator-synthesis |
| S1 persists the whole zustand blob as a single file `state/<name>.json` (single persist key `workspace-zustand-v1`). | ✅ Confirmed | `storeAdapter.ts:55` — `pathFor = (name) => \`state/${name}.json\``; `workspaceStore.ts:495` — `name: "workspace-zustand-v1"`. `FC Claim 13 (Verified, static)`. | Fact-check | for-orchestrator-synthesis |
| `skipHydration: true` defers hydration so store defaults render on first paint (SSR-safe), with hydration triggered later by an explicit `rehydrate()`. | ✅ Confirmed | `workspaceStore.ts:500-501`. Scope = the deferral (does not assert hydration always succeeds — a read failure clobbers, A1). `FC Claim 18 (Verified, static; scope covers row)`. | Fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved. (Every 🔴/🟡/🟢 row cites a `path:line` with the source critic's verbatim evidence block; the target repo was not re-read at synthesis per the e8 blinding.)

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## How flag-gating affected severities

The entire ON path is behind the DEV-ONLY, default-off `isCorpusEnabled` flag (Claim 2, Verified), so today's production blast radius is near-zero. Flag-gating was weighed per the orchestrator's guidance, but the **mechanism floor** held every named-mechanism finding above 🟢 visibility. Effects, row by row:

- **R1 (rehydration-seam, Structural → 🔴) — not reduced.** Architecture-review's own mapping puts Structural → 🔴 and the skill forbids flattening it to advisory; the mechanism is a concrete causal chain (ungated `migrateFromV2` re-fires over corpus state). Flag-gating enters only as the S4-timing framing in the author note, not as a tier cut. This row alone sets the next action (`block on architectural review`).
- **A2 (write-race, D5) — executed corroboration recorded, but held at 🟡.** Stage-2.5 SC2 executed a probe (`maxConcurrent=2`) proving the interleave — the executed corroboration the Escalation Rule would accept for a 🟡→🔴 promotion. I **declined the escalation on flag-gating grounds**: the mechanism lives entirely on the dev-only ON path with near-zero production reach today, and both performance and tech-debt themselves frame it as an S4 entry-criterion, not a today-blocker. It stays at its native Performance-High tier (🟡) with the convergence + executed proof noted, never dropped below visibility.
- **A1 / A4 (data-loss clobber N12/N13; flag-no-gate N11) — stay 🟡 (Security Medium → 🟡).** Security itself cites the single-tenant model and required user action as why *confidence-of-harm* is bounded — that is the flag-gating weighting already applied at the critic level; the tier is unchanged. **N11 (A4) is the exception where flag-gating cannot be a mitigation**: the flag is *enforceable in production from the browser console*, so it undercuts the very "dev-only" premise the other severities lean on — flagged prominently rather than softened.
- **A6–A9, C5–C6 (manifest/doc/staging findings) — mapped tiers unchanged.** These are deferred-debt with a dated S4 activation trigger; flag-gating is reflected as "fix cheaply now while the seam is fresh, or gate on S4" author-note framing, not as a tier reduction. The two fact-check Incorrect **comment/doc-only** findings (A6 Claim 7 docstring; A8 Claim 11 ArrayBuffer) map to 🟡 per the Unified Severity Mapping (Incorrect-on-doc → 🟡, not 🔴) — code behaves correctly, only a reader is misinformed.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
