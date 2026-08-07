Commit: 2dc403e

# Test Strategy: Corpus filesystem/OPFS storage layer (DD-009 S0/S1)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` — 15 files in `app/lib/corpus` and `app/lib/stores` (manifest codec, OPFS adapter, path builders, store-adapter seam, feature flag, plus test suites)
**Reviewed:** 2026-08-06
**Tier:** Advisory (all findings green / Consider). Coverage on this change is already strong — the diff ships its own contract suite, characterization baseline, and error-mapping tests. The gaps below are residual branch/edge coverage, not missing test infrastructure.

## Test Conventions

Vitest + jsdom. Tests live in `app/lib/**/__tests__/*.test.ts`; shared fixtures/helpers are `.ts` (no `.test.` infix) so they aren't collected as suites (`inMemoryCorpusFs.ts`, `corpusFsContract.ts`). Style is describe/it with arrange-act-assert; error assertions deliberately check the discriminated `CorpusError.detail.kind` rather than message strings ("Diagnostic:" comments flag this intent). Substrate that jsdom lacks (real OPFS) is driven by stubbing `navigator.storage`; the adapter's success path is explicitly deferred to out-of-CI Playwright and the CI-side contract runs against the in-memory fake. New tests should follow these patterns.

## Untested Paths Touched by the Change

Manifest codec — only 2 of the field-validation `fail()` arms are exercised (`sources` malformed, top-level `{}`):

- **G1** — `app/lib/corpus/manifest.ts:99-101` — `fail("missing or invalid field: artifacts")` when `artifacts` is not an array — not covered (only the `sources` arm is tested at `manifest.test.ts:44-49`)
- **G2** — `app/lib/corpus/manifest.ts:95-97` — `fail("artifact pointer missing type/currentVersion")` for a malformed artifact entry — not covered
- **G3** — `app/lib/corpus/manifest.ts:104-106` — `fail("missing or invalid field: customTypeIds")` when `customTypeIds` is not an array — not covered
- **G4** — `app/lib/corpus/manifest.ts:82` — `fail("missing required field: manifestVersion")` — not covered; the only object-missing-fields test uses `{}`, which throws on the `title` check first (`:81`), so the `manifestVersion` branch is never reached
- **G5** — `app/lib/corpus/manifest.ts:110-111` — `createdAt`/`updatedAt` fallback to `new Date().toISOString()` when those fields are absent or non-string — not covered (the round-trip test always supplies them, so the ternary's else-branch never runs)

OPFS adapter — unavailable + quota-on-write are covered; the remaining error-mapping arms are not, and are jsdom-testable (they run after a stubbed `getDirectory` succeeds):

- **G6** — `app/lib/corpus/opfsAdapter.ts:60` — `splitPath` throws `{kind:"io", reason:"path has no file component"}` for a path with no file component (e.g. `""` / `"/"`) — not covered
- **G7** — `app/lib/corpus/opfsAdapter.ts:82-83` — `wrap()` generic-io branch: a non-quota, non-not-found `DOMException` (or plain Error) maps to `{kind:"io"}` — not covered (only the quota arm at `:81` is asserted)
- **G8** — `app/lib/corpus/opfsAdapter.ts:45` — `isNotFound` `TypeMismatchError` arm (a file-vs-dir type mismatch treated as not-found) — not covered; tests only drive `NotFoundError`

Store-adapter seam — routing is covered; the preserved-verbatim localStorage branches are not:

- **G9** — `app/lib/corpus/storeAdapter.ts:33-36` — debounced `setItem` `catch` that swallows a localStorage quota failure with `console.warn` — not covered. This is the same "swallow vs. reify" asymmetry the OPFS quota test (G7 fact-check) exists to contrast against; the OFF-path swallow is asserted nowhere.
- **G10** — `app/lib/corpus/storeAdapter.ts:42-44` — `removeItem` clearing a pending debounce timer before removing — not covered (the flag-OFF test only exercises `setItem`)

Feature flag — the ON localStorage branch is covered via the resolver test; the defensive branches are not:

- **G11** — `app/lib/corpus/flag.ts:20-21` — `catch { return false }` when `localStorage.getItem` throws (e.g. storage disabled / SecurityError) — not covered
- **G12** — `app/lib/corpus/flag.ts:23` — final `return false` for the SSR / no-`window`, no-env case — not covered

Path builders — the sanitizers are well covered; two residual arms:

- **G13** — `app/lib/corpus/paths.ts:62` — `safeExt` empty-input fallback to `"bin"` (e.g. `sourcePath(s, id, "")` or `sourcePath(s, id, "...")`) — not covered (extension tests only use `pdf` / `.PDF`)
- **G14** — `app/lib/corpus/paths.ts:46-47` — `safeSegment` empty-result `throw` for an all-unsafe id — not covered; the equivalent throw is tested for `workspaceSlug` (`paths.test.ts:30-33`) but not for `safeSegment`, which is the sanitizer for source/custom-type/artifact ids

Contract-suite blind spot (substitutability):

- **G15** — `app/lib/corpus/__tests__/corpusFsContract.ts:1-82` — the shared contract has no case asserting `writeFile` copies its input (no-aliasing invariant). The in-memory fake copies via `bytes.slice()` (`inMemoryCorpusFs.ts:26`) but the OPFS adapter passes `bytes` straight to `w.write(bytes)` (`opfsAdapter.ts:115-116`) despite a comment claiming a "fresh ArrayBuffer view" — see fact-check Claim 8 (Incorrect). Because the contract is silent on aliasing, the fake and the adapter can diverge on this behavior and both still pass. Not covered.

## Recommended Tests

#### Manifest: each remaining field-validation arm throws typed io error

**Closes gaps:** G1, G2, G3, G4
**Type:** unit
**Priority:** medium
**File:** `app/lib/corpus/__tests__/manifest.test.ts` (extend "fail-loud parse" describe)
**What it verifies:** every malformed-field arm routes through `fail()` → `CorpusError{kind:"io"}` rather than a silent default.
**Key cases:**
- `{manifestVersion:1, title:"t", sources:[], artifacts:"nope", customTypeIds:[]}` → throws, `detail.kind==="io"` (G1)
- `{...valid, artifacts:[{type:"x"}]}` (missing `currentVersion`) → throws `/artifact pointer missing/` (G2)
- `{...valid, customTypeIds:"nope"}` → throws (G3)
- `{title:"t", sources:[], artifacts:[], customTypeIds:[]}` (no `manifestVersion`) → throws `/missing required field: manifestVersion/` (G4)

**Setup needed:** none (reuses `TextEncoder`).

#### Manifest: absent createdAt/updatedAt get defaulted, not dropped

**Closes gaps:** G5
**Type:** unit
**Priority:** low
**File:** `app/lib/corpus/__tests__/manifest.test.ts`
**What it verifies:** parsing a manifest without `createdAt`/`updatedAt` yields ISO-string timestamps rather than `undefined`.
**Key cases:**
- valid object omitting both timestamps → `typeof parsed.createdAt === "string"` and parses as a Date.

**Setup needed:** optionally freeze time; a `typeof`/parseable assertion avoids needing it.

#### OPFS adapter: generic io + malformed-path error mapping

**Closes gaps:** G6, G7, G8
**Type:** unit
**Priority:** medium
**File:** `app/lib/corpus/__tests__/opfsAdapter.test.ts`
**What it verifies:** non-quota failures and bad paths surface as `{kind:"io"}`, and a `TypeMismatchError` is treated as not-found.
**Key cases:**
- stub `getDirectory` to succeed, call `readFile("")` → `CorpusError{kind:"io", reason:/no file component/}` (G6)
- `createWritable` throws a plain `Error` / non-quota `DOMException` on write → `{kind:"io"}` (G7)
- `getFileHandle` throws `DOMException("...", "TypeMismatchError")` → `readFile` resolves `null` (G8)

**Setup needed:** same `setStorage`/`fakeRoot` pattern already in the file.

#### Store adapter: debounced localStorage quota is swallowed (OFF-path contract)

**Closes gaps:** G9, G10
**Type:** unit
**Priority:** medium
**File:** `app/lib/stores/__tests__/workspaceStore-corpus-flag.test.ts` (or a new `storeAdapter.test.ts`)
**What it verifies:** the OFF path swallows a quota error via `console.warn` (does NOT throw — the deliberate contrast with the OPFS reify path) and `removeItem` cancels a pending write.
**Key cases:**
- fake timers; stub `localStorage.setItem` to throw `QuotaExceededError`; `setItem` then advance 300ms → no throw, `console.warn` spy called (G9)
- `setItem` then `removeItem` before 300ms elapses → advancing timers performs no `localStorage.setItem` (pending cleared) (G10)

**Setup needed:** `vi.useFakeTimers()`, `vi.spyOn(console, "warn")`, stubbed `localStorage.setItem`.

#### Flag: defensive false-returns (storage throws, SSR)

**Closes gaps:** G11, G12
**Type:** unit
**Priority:** low
**File:** `app/lib/corpus/__tests__/flag.test.ts` (new)
**What it verifies:** `isCorpusEnabled()` returns `false` rather than throwing when `localStorage` access throws, and in a no-`window` environment.
**Key cases:**
- `localStorage.getItem` stubbed to throw → returns `false` (G11)
- env unset and `window` undefined → returns `false` (G12)

**Setup needed:** stub/spy on `localStorage`; a describe that deletes `globalThis.window` for the SSR case.

#### Paths: safeExt default and safeSegment empty-throw

**Closes gaps:** G13, G14
**Type:** unit
**Priority:** low
**File:** `app/lib/corpus/__tests__/paths.test.ts`
**What it verifies:** empty/degenerate extension falls back to `bin`; an all-unsafe id throws instead of yielding an empty segment.
**Key cases:**
- `sourcePath(s, "src1", "")` and `sourcePath(s, "src1", "...")` → `.../src1.bin` (G13)
- `safeSegment("////")` / `safeSegment("。。。")` → throws `/empty path segment/` (G14)

**Setup needed:** none.

#### Contract: writeFile must not alias the caller's buffer

**Closes gaps:** G15
**Type:** contract (add to shared suite)
**Priority:** medium
**File:** `app/lib/corpus/__tests__/corpusFsContract.ts`
**What it verifies:** mutating the input `Uint8Array` after `writeFile` does not change stored bytes — enforced identically on the fake and the OPFS adapter.
**Key cases:**
- `const b = Uint8Array.of(1,2,3); await fs.writeFile("x", b); b[0] = 99; expect(await fs.readFile("x"))` still `[1,2,3]`.

**Setup needed:** none for the fake; when this case runs against the OPFS adapter under Playwright it will fail as-is (the adapter does not copy) — that failure is the point, and it should be reconciled with fact-check Claim 8 (either copy in the adapter or drop the misleading comment). Flag before adding so the expectation matches the decided contract.

## What NOT to Test

- **OPFS success path (read/write/readdir/stat/rm happy paths).** Deliberately deferred to out-of-CI Playwright per the file header (`opfsAdapter.test.ts:5-8`); jsdom has no OPFS. Re-testing it against a hand-rolled `fakeRoot` would assert the fake, not the adapter. Leave as-is.
- **`describeCorpusError` / `assertNever` / worker-error round-trip (`types.ts`).** Pure formatting and a compile-time exhaustiveness guard; low blast radius and partly enforced by the type system. Not worth dedicated cases unless a consumer starts branching on the messages.
- **`serializeManifest` alone.** Already exercised transitively by the round-trip test; a separate golden test adds maintenance cost without new information.
- **`workspaceStore` rehydration internals.** Covered by the characterization suite (`workspaceStore-characterization.test.ts`); no need to duplicate.

## Coverage Gaps Beyond Current Scope

**1.** No migration coverage exists because migration does not exist yet — `flag.ts:4-7` states S1 starts from an empty corpus and localStorage→corpus migration is S4. When S4 lands, the highest-risk untested path in this whole area will be the migration/rehydration bridge (localStorage blob → folder layout); the characterization suite (G16) is explicitly the equivalence target for it. Flag for the S4 test-strategy pass, not this one.

**2.** The manifest is parsed but never yet written or read by the store (S1 uses blob mode via `storeAdapter.ts`, per its header `:10-12`). The folder-layout ↔ manifest integration is therefore entirely untested end-to-end; that too is S4 scope.

## Summary

The highest-value addition is the OPFS error-mapping trio (G6-G8) plus the debounced-quota swallow test (G9): both close branches in the code's core promise — "failures become typed `CorpusError`s, and the OFF path preserves prior swallow-behavior" — that the current suite states as intent but does not assert. The manifest field-validation arms (G1-G4) are the next tier: the fail-loud contract is the module's reason to exist, yet three of its five field-guards run in no test. Residual risk after this plan is concentrated at the OPFS success path (structurally CI-invisible until Playwright runs) and the S4 migration bridge (code not yet written). The one gap the enumeration surfaced as more than coverage is G15: the contract suite cannot see the fake/adapter buffer-aliasing divergence that fact-check Claim 8 flags — worth resolving the comment-vs-behavior mismatch before codifying the invariant.
