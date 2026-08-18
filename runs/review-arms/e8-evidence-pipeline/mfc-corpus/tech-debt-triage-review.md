# Tech Debt Triage — mfc-corpus DD-009 corpus architecture

**Commit:** 2dc403e
**Scope:** `git diff dc6dfb0...HEAD` — OPFS storage substrate, manifest codec, `NEXT_PUBLIC_CORPUS_FS` flag, storage-seam swap, rehydration/migration.
**Advisory:** tech-debt-triage critic in the code-review pipeline. Costs/tradeoffs made explicit; not advocacy.

## Framing — the flag gate dominates every number here

The one fact that governs this whole triage: the corpus path is behind `isCorpusEnabled()`, **default-off and dev-only** (fact-check Claim 2, verified). Every defect that lives on the ON path (the OPFS write seam and its error handling) has **near-zero carrying cost today** — no end user exercises it — but a **real, dated activation trigger**: S4 / flag enablement. So this is textbook *deferred* debt with a built-in deadline, not accruing rot. The correct disposition for most items is therefore "fix cheaply now while the seam is fresh, or defer with a hard S4 gate" — not "fix now because it hurts today."

The two items that *do* have a today-cost even with the flag off are the stale comments (D4) and the performance regression half of the write seam (D1) — anyone dev-testing the flag gets un-debounced writes.

Five items triaged below (D1–D5), then a summary table and recommended order.

---

## D1 — OPFS write seam: un-debounced, un-serialized concurrent writes

**Location:** `app/lib/corpus/storeAdapter.ts:61-63` (`setItem` → `await fs.writeFile`), `app/lib/corpus/opfsAdapter.ts:107-123` (`writeFile`)
**Nature:** Concurrency / data-integrity + performance regression
**Cost of Deferral:** `+0 — inert while flag off; discrete step to Med at S4 enablement`
**Failure Cost:** `Med × High — a torn/interleaved write corrupts the single workspace blob (all work in one file); probability gated behind the flag but the whole workspace is the blast radius`

### Carrying Cost: Low (today) / would be High on activation
The OFF path debounces writes at 300 ms and the deleted comment states the debounce exists explicitly "to avoid JSON.stringify on every keystroke." The corpus-backed `setItem` drops both properties: it fires a full `writeFile` (stringify + OPFS `getFileHandle`→`createWritable`→`write`→`close`) on **every** persisted `set()`, with no debounce and no write serialization. Because `createWritable()` truncates the target, two overlapping `setItem` calls to the same `state/workspace-zustand-v1.json` can interleave — write B truncating while write A is mid-flight — leaving a partial or torn blob. Since the entire workspace persists as one file (fact-check Claim 13, verified), a single torn write loses everything, and it re-reads as unparseable JSON. Even absent a race, the lost debounce means the ON path re-does the exact per-keystroke work the OFF path was optimized to avoid.

### Fix Cost
- **Scope:** localized — `storeAdapter.ts` only (`createCorpusBackedStorage`).
- **Effort:** hours. Wrap corpus `setItem` in the same 300 ms debounce the localStorage adapter already uses, and chain writes through a single last-write-wins promise so they can't overlap.
- **Risk:** low — the in-memory `CorpusFS` fake + contract tests already exist to cover it.
- **Incremental?** yes — self-contained.

### Urgency Triggers
- S4 / any real enablement of `NEXT_PUBLIC_CORPUS_FS` — the write seam becomes live.
- Any dev running with the flag on hits the perf regression immediately (not corruption, but wasted work).

### Recommendation
**Recommendation:** Fix opportunistically

Lowest fix cost of the data-integrity items, and the fix restores a performance optimization that is silently regressed on the ON path *today*. The seam is fresh; fold the debounce+serialize in now rather than re-deriving it under an S4 deadline. If S4 is scheduled, this graduates to Fix now.

---

## D2 — Store-seam swallows the errors the OPFS adapter carefully reifies (unhandled rejection + read-clobber data loss)

**Location:** `app/lib/corpus/storeAdapter.ts:57-63` (`getItem`/`setItem`, no catch), interacting with `app/lib/stores/workspaceStore.ts:529-530` (`onRehydrateStorage` → `if (error) return`)
**Nature:** Error-handling / data-integrity — reification-vs-surfacing gap
**Cost of Deferral:** `+0 — inert while flag off; discrete step to High at S4 enablement`
**Failure Cost:** `High × High — a non-NotFound read error during rehydrate is discarded, defaults render, and the next setItem overwrites the real file with defaults: silent whole-workspace data loss, exactly the failure mode the manifest codec docstring says the design must prevent`

### Carrying Cost: Low (today) / would be High on activation
`opfsAdapter` goes to real trouble to reify failures into typed `CorpusError` — `{kind:"quota-exceeded"}`, `{kind:"unavailable"}`, `{kind:"io"}` (Claims 8, 9, 16, all verified). The consumer then throws that work away at the seam:
- **Write path:** `setItem` awaits `writeFile` with no catch (fact-check note carried to critics, `storeAdapter.ts:62`). A quota/io rejection surfaces as an *unhandled promise rejection* inside zustand persist — no UI state, no surfaced failure. The OFF path at least `console.warn`s.
- **Read path (worse):** a non-NotFound `readFile` rejection re-throws into rehydration, where `onRehydrateStorage`'s `if (error) return` (`workspaceStore.ts:530`) silently discards it. Defaults stay rendered, and the next debounced `setItem` then persists **defaults over the still-present real file** — the "silent default-empty manifest masquerading as no-work-in-it" that `manifest.ts:10-14` explicitly names as the thing the design must never do. Here the store seam reintroduces it one layer up.

### Fix Cost
- **Scope:** cross-cutting — `storeAdapter.ts` + `workspaceStore.ts` rehydration.
- **Effort:** ~1 day, because it requires a real design decision, not just a `try/catch`: on a read error the rehydrate must *not* fall through to a defaults-persist (abort persistence / show a "storage read failed" state), and write rejections need a surfacing policy (error UI vs. warn). Distinguishing "genuinely empty corpus" from "read failed" is the crux.
- **Risk:** medium — touches the rehydration lifecycle; wrong handling could block legitimate first-run empty state.
- **Incremental?** partially — the write-side catch is trivial; the read-clobber fix is the substantive part and should not ship half-done.

### Urgency Triggers
- S4 / flag enablement — this is the single most important thing to close **before** the ON path touches real user data. It is a hard gate, not a nice-to-have.

### Recommendation
**Recommendation:** Defer and monitor

Carrying cost is zero while the flag is off, but the failure cost is the worst in this diff (silent whole-workspace loss) and it directly violates the codebase's own stated fail-loud invariant. Set an explicit gate: **must be fixed before `NEXT_PUBLIC_CORPUS_FS` is enabled for anyone but a throwaway dev profile.** Track it in DD-009's S4 checklist so enablement can't ship without it.

---

## D3 — Manifest codec: docstrings promise fail-loud, code silently coerces

**Location:** `app/lib/corpus/manifest.ts:10-14` (header), `:69-73` (per-function), `:87-113` (coercions)
**Nature:** Documentation drift + mild silent-coercion; on unused code
**Cost of Deferral:** `+0 — inert (codec is built but not wired to the store until S4)`
**Failure Cost:** *(blank — codec is not on any live path; guessing a number would be noise)*

### Carrying Cost: Low
The header says "FAIL-LOUD … never a silent default" and the per-function docstring says "Throws … on **any** malformation," but three field classes are silently coerced, not surfaced (fact-check Claims 6 Mostly-accurate, 7 Incorrect): `createdAt`/`updatedAt` malformations are replaced with a fresh `new Date().toISOString()` (`:109-110`), a missing/wrong `label` defaults to the source `id` (`:89`), and non-object source entries / non-string custom-type ids are silently dropped by the pre-map filters (`:87,103`). The real cost today is a *misleading contract for the future S4 integrator*, not live behavior — `manifest.ts` is dead code until S4 wires it (Claims 13/14).

The substantive question underneath — should a corrupt persisted `createdAt` fabricate "now," and should malformed sources vanish from the index? — is a genuine design fork that belongs in the S4 reconciliation, not a bug to patch blind.

### Fix Cost
- **Scope:** localized — `manifest.ts` only.
- **Effort:** hours. Cheapest: tighten the two docstrings to match the code ("throws on absent bytes / malformed structural field; `createdAt`/`updatedAt`/`label` are coerced"). Alternative (defer to S4): tighten the code to actually fail loud on those fields.
- **Risk:** low — no live consumers.
- **Incremental?** yes.

### Urgency Triggers
- S4 wires the codec to the store — resolve coerce-vs-throw then, with the persistence model in hand.

### Recommendation
**Recommendation:** Fix opportunistically

Do the trivial half now — correct the two docstrings so the next reader isn't misled (this is a documentation fix, near-zero risk). Defer the coerce-vs-throw *behavior* decision to S4, where the manifest actually gets a consumer.

---

## D4 — Stale cross-reference comments (rename + move rot)

**Location:** `app/lib/corpus/opfsAdapter.ts:14` (`workspaceStore.ts:44-46`), `app/lib/corpus/storeAdapter.ts:11` (`layout.ts`), `app/lib/corpus/opfsAdapter.ts:115` ("fresh ArrayBuffer view")
**Nature:** Naming / reference rot
**Cost of Deferral:** `+0 — inert (cosmetic)`
**Failure Cost:** *(blank — cosmetic)*

### Carrying Cost: Low
Three cheap corrections surfaced by fact-check:
- `opfsAdapter.ts:14` points at `workspaceStore.ts:44-46` for the legacy `console.warn` swallow, which this same diff moved to `storeAdapter.ts:34-35` (Claim 10, Stale). That line in `workspaceStore.ts` is now unrelated rehydration code, so a reader following the pointer lands on the wrong thing.
- `storeAdapter.ts:11` says `layout.ts`, renamed to `paths.ts` in this change because `layout.ts` is a reserved Next filename (Claim 14, Stale).
- `opfsAdapter.ts:115` "Pass a fresh ArrayBuffer view" describes a copy the next line never makes — `write(bytes)` passes the caller's reference unchanged (Claim 11, Incorrect). Currently harmless (callers pass fresh `encode()` output), so this is cosmetic, but the comment claims a safety property the code doesn't provide.

### Fix Cost
- **Scope:** localized — three one-line comment edits, well under 50 LOC.
- **Effort:** minutes. Trivial fix-in-place.
- **Risk:** none — comments only.
- **Incremental?** yes.

### Urgency Triggers
- None. Purely misleads a reader.

### Recommendation
**Recommendation:** Fix opportunistically

Trivial. Batch these three comment edits with whichever of D1/D3 touches the same files, or fix in a single hygiene commit. Not worth its own ceremony.

---

## D5 — Two parallel persistence models carried until S4 (blob mode vs. folder layout)

**Location:** `app/lib/corpus/storeAdapter.ts` (blob mode, single `state/*.json`) vs. `app/lib/corpus/manifest.ts` + `paths.ts` (files-per-artifact folder layout, built but unused)
**Nature:** Structural / integration debt — deliberately staged
**Cost of Deferral:** `+0 — staged work, not accruing rot`
**Failure Cost:** *(blank — no live path)*

### Carrying Cost: Low
The store persists one blob under `state/` (Claim 13), while `manifest.ts`/`paths.ts` build a folder-per-artifact layout the store does not use "until S4" (Claim 14 behavioral half, uncontested). Two persistence models coexist in the tree; the only real cost is cognitive load — a reader must know which is live — plus dead code carried pending its consumer. S4 must reconcile: migrate localStorage→corpus and blob→folder layout, and wire the codec. This is documented and intentional (DD-009, checkpoint-corpus-s1), so it is roadmap, not rot.

### Fix Cost
- **Scope:** systemic — this *is* S4, the actual feature, not a cleanup.
- **Effort:** weeks. Requires a coordinated migration.
- **Risk:** medium-high — data migration of real user work.
- **Incremental?** no — needs a coordinated design (and it is the natural home for D1/D2/D3's ON-path resolutions).

### Urgency Triggers
- S4 is scheduled — but S4 is planned work, so this is "the plan," not debt to pre-empt.

### Recommendation
**Recommendation:** Carry intentionally

This is staged, documented, non-rotting deferral — the correct disposition is to carry it and let S4 do it as designed. Its value here is as the **umbrella**: D1, D2, and D3 all attach to it, and their shared urgency trigger is S4 enablement. Treat "close D1/D2/D3 before enabling the flag" as an S4 entry criterion.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| D1 | OPFS write seam un-debounced/un-serialized | Low (High on activation) | +0 (step at S4) | Med × High — torn write corrupts whole blob | Hours | S4 gate | Fix opportunistically |
| D2 | Store seam swallows reified errors; read-clobber data loss | Low (High on activation) | +0 (step at S4) | High × High — silent whole-workspace loss | ~1 day | S4 hard gate | Defer and monitor |
| D3 | Manifest docstrings promise fail-loud; code coerces | Low | +0 (inert, unused) | — | Hours | S4 | Fix opportunistically |
| D4 | Stale comments (workspaceStore/layout.ts/fresh-view) | Low | +0 (cosmetic) | — | Minutes | None | Fix opportunistically |
| D5 | Two parallel persistence models until S4 | Low | +0 (staged) | — | Weeks | S4 (planned) | Carry intentionally |

### Recommended Order
1. **D4 (minutes)** — three comment edits; land in a hygiene commit, batch with whatever else touches those files.
2. **D1 + D3-docstring (hours, same seam)** — while the write seam is fresh: add the debounce+serialize to corpus `setItem`, and correct the two manifest docstrings. Both localized, both have tests. Best ROI in the diff.
3. **D2 (~1 day, gated)** — the substantive one. Do **before** any real flag enablement; it needs a design decision (surface-vs-abort on read/write error, don't-persist-defaults-over-real-file). Put it on the S4 checklist as an entry criterion, not an afterthought.
4. **D5** — carry; it *is* S4. Let it absorb the ON-path resolutions from D1/D2/D3.

### Highest-ranked
**D2 is the most important defect** — it carries the worst failure cost (silent whole-workspace data loss) and it re-introduces, at the store seam, the exact silent-default failure the manifest codec's own docstring says the architecture must prevent. But it is **activation-gated and needs a design decision**, so it ranks as the *hard S4 gate* rather than a fix-today.

**D1 is the highest-ROI thing to fix now** — it is the cheapest data-integrity item, restores a performance optimization that regresses on the ON path today, and closes a corruption trapdoor with a localized, test-covered change while the seam is fresh. If you fix one thing this week, fix D1; if you enable the flag, you must first fix D2.
