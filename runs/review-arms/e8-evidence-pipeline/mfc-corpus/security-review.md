# Security Review — mfc-corpus DD-009 corpus-architecture (S0/S1)

**Commit:** 2dc403e
**Scope:** `git diff dc6dfb0...HEAD` — OPFS/`CorpusFS` storage seam, `NEXT_PUBLIC_CORPUS_FS` dev flag, manifest codec, path builders, rehydration/migration. Source under `app/lib/corpus/*.ts` and `app/lib/stores/workspaceStore.ts`.
**Date:** 2026-08-18
**Based on:** code-fact-check report at `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-corpus/code-fact-check-report.md` (Commit 2dc403e). Documented behavior is taken as established there and not re-verified; this review builds security implications on top of it.

Deployment context (from `CLAUDE.md`): the app is **self-hosted single-tenant** — one deployer == the end user, one trust boundary per deployment. There is no multi-tenant blast radius; the security surface here is **data integrity / durability** and **dev-only-feature reachability**, not cross-user compromise.

No escalation patterns (plaintext secrets, missing auth on privileged endpoints, injection, disabled TLS, hardcoded keys) matched. No HALT block.

## Trust Boundary Map

```
B1 (new): NEXT_PUBLIC_CORPUS_FS env (build-time, client-inlined) → isCorpusEnabled() → storage-seam selection (localStorage vs OPFS)
B2 (new): browser localStorage["corpus-fs-enabled"] (end-user-settable via console) → isCorpusEnabled() → storage-seam selection
B3 (new): workspace title / source & type ids (user input) → workspaceSlug()/safeSegment() sanitizer → corpus path segment  [built, not yet reached by the S1 store write path]
B4 (new): persisted blob in OPFS (external storage, was localStorage) → readFile()/decode → zustand rehydrate+merge → store state
B5 (new): path string → splitPath()/walkDir() → OPFS getDirectoryHandle()/getFileHandle()
```

What enters from outside: a build-time env var and a browser-localStorage key that together *select which storage substrate the store uses* (B1/B2); the previously-persisted state blob, now read back from OPFS instead of localStorage and JSON-parsed into store state (B4); path strings handed to the OPFS API (B5). The diff's central new assumption is that the corpus flag is "dev-only" — but nothing in code enforces that (Finding 1). B3's title→slug sanitizer exists and is the intended single choke point, but in S1 the store only ever writes the constant path `state/workspace-zustand-v1.json`, so no attacker-controlled title reaches OPFS yet.

## Findings

#### DEV-ONLY corpus flag has no production/NODE_ENV gate — enforceable in production

**Severity:** Medium
**Location:** `app/lib/corpus/flag.ts:4-7,15-25`; consumed at `app/lib/corpus/storeAdapter.ts:71-76`
**Boundary:** B1, B2
**Move:** #11 (guardrail bypass), #3 (error/failure state)
**Confidence:** High

The docstring states the flag is "DEFAULT OFF and DEV-ONLY … must not be turned on for end users until S4 ships migration," because enabling it "starts from an EMPTY corpus and does not carry existing localStorage work over." `isCorpusEnabled()` contains **no `NODE_ENV`/production gate** on either enablement path. I tested both: with `NODE_ENV=production` set, `NEXT_PUBLIC_CORPUS_FS=1` returns `true`, and the `localStorage["corpus-fs-enabled"]="1"` opt-in returns `true` (`evidence/sec-move11-probes.txt`: `SEC_ENV_PROD_RESULT: true`, `SEC_LS_PROD_RESULT: true`). The mechanism: once enabled in a production deployment, `resolveWorkspaceStorage()` selects the empty OPFS corpus; the user's real work still sits in localStorage but is no longer read, so it silently appears lost (no migration until S4). The B2 path is directly end-user-reachable — a single `localStorage.setItem` in the browser console flips a production instance to the empty corpus. Per the mechanism-floor rule, a dev-only flag that is enforceable in production may not rate below Medium; the single-tenant model and the required user action are why confidence-of-harm is bounded, not the severity.

**Recommendation:** Gate the env path on `process.env.NODE_ENV !== "production"` (and/or gate the localStorage path likewise), or move the flag to a non-`NEXT_PUBLIC_` server-only env so it cannot be inlined into the client bundle and toggled from the browser. If the flag is genuinely needed in prod builds before S4, replace the "dev-only" docstring with the real contract.

#### Clobber-on-read-error: a transient non-NotFound read failure silently overwrites intact persisted data (fail-open)

**Severity:** Medium
**Location:** `app/lib/corpus/storeAdapter.ts:57-63`; `app/lib/stores/workspaceStore.ts:528-543` (`onRehydrateStorage` `if (error) return`)
**Boundary:** B4
**Move:** #3 (check the error path)
**Confidence:** High

Carried forward from fact-check Claim 16's Scope note and confirmed by reading the path. `createCorpusBackedStorage.getItem` returns `null` only for a truly-absent file (adapter maps NotFound → `null`); **any other** `readFile` failure — a typed `CorpusError{kind:"io"}` from a transient OPFS glitch, or `{kind:"unavailable"}` — rejects out of `getItem` into zustand's rehydrate. `onRehydrateStorage`'s callback does `if (error) return`, discarding the error, so the store keeps rendering `DEFAULT_STATE`. The next state mutation triggers persist's `setItem`, which writes those defaults to `state/workspace-zustand-v1.json` — **overwriting the user's still-intact file** with empty defaults. A recoverable, transient read error is thereby converted into permanent, silent data loss: the failure is fail-open on the integrity axis. This is a genuine mechanism (transient IO on read → durable data destruction), hence Medium, not Informational.

**Recommendation:** Distinguish "not found" (safe to render defaults) from "read failed" (must not persist over the source). On a non-NotFound rehydrate error, surface a failure-driven UI state per the DD-009 mandate and **block writes** until the user resolves it, rather than letting the next `setItem` clobber the file.

#### Corpus-backed write awaits `writeFile` with no catch — failures become unhandled rejections, no failure-driven UI

**Severity:** Low
**Location:** `app/lib/corpus/storeAdapter.ts:61-63`
**Boundary:** B4
**Move:** #3 (check the error path)
**Confidence:** High

Carried forward from fact-check Claim 9's Scope note. The OPFS adapter *correctly* reifies a quota failure as `CorpusError{kind:"quota-exceeded", substrate:"opfs"}` (Claim 9, Verified) instead of swallowing it — but the store-level consumer `setItem` does `await fs.writeFile(...)` with no `try/catch`. The reified rejection propagates into zustand-persist's async setItem as an **unhandled promise rejection**, with no UI state signalling that the save failed. Unlike the localStorage adapter (which swallows quota with `console.warn`), a corpus write failure is neither surfaced nor recovered: the user believes work is saved when it silently was not. No attacker trigger — this is a durability/robustness gap that the DD-009 "failure-driven UI" mandate is specifically meant to close, so it is Low here, but it should be fixed alongside Finding 2 (same error-path family).

**Recommendation:** Wrap the `writeFile` await in a `catch` that routes `CorpusError` to a persistence-failure UI state (at minimum a typed callback), matching the failure-driven-UI intent rather than dropping the rejection.

#### splitPath performs no traversal guard of its own — relies entirely on the OPFS API to reject `..`

**Severity:** Informational
**Location:** `app/lib/corpus/opfsAdapter.ts:57-62,66-77`
**Boundary:** B5
**Move:** #11 (guardrail bypass)
**Confidence:** High

`splitPath` strips leading/trailing slashes and drops empty segments, but does **not** reject `.` or `..` segments. I tested it (via `writeFile("../escape.json", …)` against a stub root emulating real OPFS): splitPath forwarded `".."` verbatim to `getDirectoryHandle` (`evidence/sec-move11-probes.txt`: `SEC_SPLITPATH_REQUESTED: [".."]`), where the browser's `getDirectoryHandle` rejects it (real OPFS throws for `.`/`..`/names containing `/`), and the adapter wrapped it as `CorpusError{kind:"io"}`. So traversal is stopped **only** at the browser OPFS layer, not by the adapter. Within this diff no attacker-controlled path reaches `splitPath`: the store uses the constant `state/workspace-zustand-v1.json`, and every other corpus path is produced by the `paths.ts` builders whose `SAFE_SEGMENT` sanitizer strips separators and dots (fact-check Claim 12, Verified). The contract in `paths.ts:16-19` explicitly states callers "must never hand-concatenate." This is defense-in-depth: if a future consumer ignores that contract and passes an unsanitized path, splitPath's lack of an own guard means the only backstop is the OPFS runtime.

**Recommendation:** Add an explicit reject in `splitPath` for any segment equal to `.` or `..` (throw `CorpusError{kind:"io"}`), so the adapter fails closed on traversal independently of browser behavior and the choke-point invariant does not rest on an implicit OPFS guarantee.

## Untested bypass candidates

Move #11 requires ≥3 bypass candidates per guardrail; those not traced are listed here with the reason.

**Guardrail: `workspaceSlug`/`safeSegment` title→slug sanitizer (`paths.ts:28,36-58`, boundary B3).** Fact-check Claim 12 verified it strips `/`, `\`, and dot-runs and throws on an empty result, but its Scope explicitly disclaims Unicode-edge and caller-bypass coverage. Because untested bypass candidates remain, this guardrail is **not** carried into Endorsement Claims.
- **Unicode NFKD residue** — e.g. characters that decompose to a separator or dot but survive as a base char, or fullwidth/compatibility forms (`／` U+FF0F, `．` U+FF0E). NFKD runs *before* `SAFE_SEGMENT`, so most fold into stripped ASCII, but I did not enumerate the decomposition table. *Untested — no attacker-controlled title reaches OPFS in S1, so not on a reachable path yet; deferred until S4 wires titles to writes.*
- **Caller bypass of the choke point** — a future caller hand-building a path or calling `opfsAdapter` directly, sidestepping `paths.ts`. *Untested — depends on code outside this diff (S2/S4).*
- **`safeSegment` on source/type ids vs. an id that is already a crafted path** — same sanitizer, but ids may come from LLM/manifest content rather than a typed title. *Untested — id provenance is out of the S1 diff scope.*

**Guardrail: the corpus flag (B1/B2).** Bypass candidates were **tested** — see Finding 1 (env-in-prod and localStorage-in-prod both enable). **Guardrail: `splitPath` (B5).** Bypass candidate (`..` segment) was **tested** — see Finding 4.

## Endorsement Claims

- **Claim:** The OPFS unavailable-guard throws a typed `CorpusError{kind:"unavailable"}` from `getRoot()` before any raw property access on `navigator.storage`, so a read in an SSR/unsupported-browser context fails with a typed error rather than a raw `TypeError`.
  **Location:** `app/lib/corpus/opfsAdapter.ts:49-55,85-105`
  **Evidence:** executed (via code-fact-check Claim 8, `readFile` under jsdom)
  **Verified:** `readFile` in an env with no `navigator.storage` rejected with `{kind:"unavailable"}`, not a `TypeError`.
  **Not verified:** that `writeFile`/`readdir`/`rm`/`stat` (which share the same `getRoot()` front) were each individually exercised — only `readFile` was run; and whether the store consumer surfaces the typed error rather than dropping it (see Findings 2–3).
  **route: code-fact-check**

- **Claim:** The OPFS adapter maps a `QuotaExceededError`/`QUOTA_EXCEEDED_ERR` DOMException to `CorpusError{kind:"quota-exceeded", substrate:"opfs"}` in `wrap()`, rather than swallowing it with `console.warn` as the localStorage adapter does.
  **Location:** `app/lib/corpus/opfsAdapter.ts:45-47,79-83`
  **Evidence:** read-static (via code-fact-check Claim 9, Verified)
  **Verified:** the `isQuota` classifier and the `wrap()` mapping match the claim; the contrasted localStorage swallow lives at `storeAdapter.ts:34-35`.
  **Not verified:** whether a real OPFS quota event actually surfaces one of those DOMException names (browser-dependent, not reproducible in jsdom); and — one hop away — whether the reified rejection is ever caught, which it is **not**, at `storeAdapter.ts:61-63` (Finding 3).

- **Claim:** In S1 the store's corpus write target is the constant path `state/workspace-zustand-v1.json`, so no user-controlled title/id reaches the OPFS adapter through the store's runtime write path.
  **Location:** `app/lib/corpus/storeAdapter.ts:55,61-63`; `app/lib/stores/workspaceStore.ts:495,499`
  **Evidence:** read-static
  **Verified:** `pathFor(name)` builds `state/${name}.json` and the persist config uses the single constant store name `workspace-zustand-v1`, so the path handed to `writeFile` is a fixed literal in the store path.
  **Not verified:** any non-store caller of `createCorpusBackedStorage`/`createOpfsCorpusFs` (none in this diff), and the S2/S4 paths that will wire `paths.ts` builders to writes — one hop beyond this diff.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | DEV-ONLY flag has no production/NODE_ENV gate | Medium | B1,B2 | `flag.ts:15-25` | High |
| 2 | Clobber-on-read-error overwrites intact data (fail-open) | Medium | B4 | `storeAdapter.ts:57-63` | High |
| 3 | `writeFile` awaited with no catch → unhandled rejection | Low | B4 | `storeAdapter.ts:61-63` | High |
| 4 | `splitPath` has no own traversal guard (relies on OPFS) | Informational | B5 | `opfsAdapter.ts:57-62` | High |

## Overall Assessment

The change is structurally sound — typed error model, a real single-choke-point path sanitizer, and correct failure reification in the adapter — and in a single-tenant self-hosted deployment there is no cross-user attack surface. The security posture is dominated by **data-integrity, not classic exploitability**. The one issue that most warrants action before this ships anywhere near end users is the pairing of Finding 1 (the "dev-only" flag is enforceable in production, including from the browser) with Finding 2 (a transient read error fails open and clobbers intact persisted work): together they are a realistic path to silent, irreversible data loss with no migration safety net until S4. Both are fixable in place — a NODE_ENV gate on the flag and a not-found-vs-read-failed distinction in the rehydrate path — and Finding 3 should be fixed in the same error-path pass. No findings amount to an architectural problem. Consistent with the skill's gate: this is **not a categorical all-clear** — the Endorsement Claims are scoped, two carry `route: code-fact-check` pending execution-backed verdicting, and each names its nearest unverified hop.
