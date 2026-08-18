# API Consistency Review — mfc-lean `d86d2dc...c95c9cb` (unavailable-verifier status taxonomy)

**Commit:** c95c9cb
**Scope:** `git diff d86d2dc...HEAD` in `/workspace/external/cc-review-eval/mfc-lean` — 10 files: `app/api/verification/lean/route.ts`, `app/lib/formalization/{api.ts,leanRetryLoop.ts}`, `app/hooks/useFormalizationPipeline.ts`, `app/lib/types/session.ts`, `app/components/{features/lean-display/LeanCodeDisplay.tsx,ui/VerificationBadge.tsx}`, plus tests
**Date:** 2026-08-17
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/code-fact-check-report.md` (merged k=2 report, commit c95c9cb; its verdicts bind — executed route/loop/UI behavior is taken as established and not re-verified)

## Baseline Conventions

Surveyed sibling surfaces before evaluating the diff:

- **Status enums** (`app/lib/types/session.ts:1-2`, `app/lib/types/decomposition.ts:22-26`): lowercase adjective/participle members — `VerificationStatus` = `none|verifying|valid|invalid`, `NodeVerificationStatus` = `unverified|in-progress|verified|failed`, `LoadingPhase` = `idle|semiformal|lean|...`. Kebab-case precedent exists for multi-word members (`in-progress`) and for `ArtifactType` values (`causal-graph`, `statistical-model`).
- **Status-contract bridging**: the global and node-scoped status vocabularies are bridged by a mapper pair `toNodeVerificationStatus` / `fromNodeVerificationStatus` (`app/lib/types/decomposition.ts:29-50`) with catch-all `default` branches. Every global-status producer that lands on a node routes through these (`app/page.tsx:186,350`; `app/hooks/useActiveArtifactState.ts:41-42`).
- **API-route error envelope**: sibling routes return `{ error: string }` with a 4xx/5xx status (`app/api/decomposition/extract/route.ts:105`, `app/api/formalization/lean/route.ts:144-154` — the latter adds `details` for structured extra info at status 502). Success payloads are bare domain objects at 200.
- **Result types**: `<Noun>Result` shapes returned from `lib/formalization` helpers — `LeanRetryResult` (`leanRetryLoop.ts:22-28`).
- **Persistence**: transient statuses are stripped before persistence via `sanitizeVerificationStatus` / `sanitizeNodeStatus` (`app/lib/utils/workspacePersistence.ts:33-45`), but the live storage path is the Zustand store's own `persist` middleware (`app/lib/stores/workspaceStore.ts:305-317`), which persists `verificationStatus` raw.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `"unavailable"` (VerificationStatus member) | enum variant | `none`, `verifying`, `valid`, `invalid` | `app/lib/types/session.ts:1` | Consistent — lowercase adjective matches siblings |
| `UnavailableReason` | type | `VerificationStatus`, `NodeVerificationStatus`, `LoadingPhase` | `app/lib/types/session.ts:1-2`, `app/lib/types/decomposition.ts:22` | Consistent — PascalCase union of string literals |
| `"verifier-not-configured"` / `"verifier-unreachable"` / `"verifier-error"` | enum values (wire) | `"in-progress"`, `"causal-graph"`, `"statistical-model"` | `app/lib/types/decomposition.ts:24`, `app/lib/types/session.ts` (ArtifactType) | Consistent — kebab-case multi-word literals have precedent; shared `verifier-` prefix is well-formed |
| `unavailable` (response/result field) | field | `valid`, `semiformalDirty` | `app/api/verification/lean/route.ts`, `app/lib/stores/workspaceStore.ts:56` | Consistent — bare-adjective boolean, no `is` prefix, matches `valid` |
| `reason` (route response field) | field | `error` (sibling error responses) | `app/api/formalization/lean/route.ts:152`, `app/api/decomposition/extract/route.ts:105` | New convention — no existing machine-readable error-code field; siblings put prose in `error`. Unconsumed (Finding 5) |
| `detail` (route response field) | field | `details` | `app/api/formalization/lean/route.ts:145` | Inconsistent — the one sibling structured-extra field is plural `details` (Finding 6) |
| `VerifyLeanResult` | type | `LeanRetryResult`, `LlmCallUsage` | `app/lib/formalization/leanRetryLoop.ts:22`, `app/lib/llm/callLlm.ts` | Consistent — matches `<Noun>Result` shape of its direct sibling |
| `verifyResultToStatus` | function | `toNodeVerificationStatus`, `fromNodeVerificationStatus` | `app/lib/types/decomposition.ts:29,41` | Minor divergence — existing status mappers use `to<Target>`/`from<Source>` prefix shape (Finding 8) |
| `unavailableResponse` | function (route-private) | `unavailableResponse` is not exported | `app/api/verification/lean/route.ts:8` | Not audited — private local helper, wire shape audited via its fields above |

## Findings

#### 1. `formalizeNode` ignores the new `unavailable` contract member — node-mode marks unchecked proofs "failed"

**Severity:** Breaking
**Location:** `app/lib/formalization/formalizeNode.ts:61` (also `app/hooks/useAutoFormalizeQueue.ts:106-118`)
**Move:** #3 (trace the consumer contract)
**Confidence:** High

`leanRetryLoop`'s result contract changed: it now returns early with `{ valid: false, errors: "", unavailable: true }` when the verifier is unavailable (fact-check Claim 19, executed). The node-scoped pipeline consumer was not updated: `formalizeNode.ts:61` still computes `deductiveResult = result.valid ? "verified" : "failed"`, so an offline verifier now marks the node **"failed"** with empty `verificationErrors` (line 96 clears them). `NodeDetailPanel` and `ProofGraphNode` render that as an ordinary failure (`STATUS_LABELS`/`STATUS_COLORS` keyed on `NodeVerificationStatus`, `NodeDetailPanel.tsx:23,34`; `ProofGraphNode.tsx:6,39`) with none of the "not checked" surfaces the change added for global mode. Before this change the same condition produced the mock `valid: true` → "verified"; either reading violates the commit's own stated invariant ("distinguish unavailable Lean verifier from a passing proof" / route comment "treat as unavailable rather than a failed proof"). Compounding it, `useAutoFormalizeQueue` retries only non-`"verified"` nodes and marks failures `"failed"` (`useAutoFormalizeQueue.ts:59,106-117`), so a batch auto-formalize with the verifier down burns an LLM generation call per node and paints the whole graph red, indistinguishable from real proof failures.

**Recommendation:** Handle `result.unavailable` in `formalizeNode` explicitly — either add an `unavailable`-shaped member to `NodeVerificationStatus` or map it to `"unverified"` with a distinguishing message — and have the auto-formalize queue stop (not fail-mark) remaining nodes when the verifier is unavailable.

#### 2. Removed `LEAN_VERIFIER_URL` default breaks the documented Docker configuration contract

**Severity:** Breaking
**Location:** `app/api/verification/lean/route.ts:26-30` (contract documented at `README.md:84`, `docs/USER_GUIDE.md:332-345`, `docs/ARCHITECTURE.md:197-200`)
**Move:** #3 / #6 (consumer contract, versioning impact)
**Confidence:** High

Per fact-check Claims 4 and 27 (both Stale, executed — binding): the base commit defaulted to `http://localhost:3100`; at HEAD an unset env var short-circuits to `verifier-not-configured` and no request is ever made to port 3100 (r2's detector stub logged zero requests). The consumers of this configuration contract are deployers following the in-repo docs: USER_GUIDE tells users to `docker compose up` the verifier on 3100 with no mention that the env var is now mandatory. A previously working setup (Docker verifier running, var unset) silently degrades from real verification to "Verifier offline". The change may be deliberate (explicit-over-implicit config), but nothing in the diff updates the contract's documentation or migrates existing setups.

**Recommendation:** Either restore the localhost default for dev, or update README/USER_GUIDE/ARCHITECTURE in the same change and add the variable to any `.env.example`. If intentional, state it in the docs as a breaking setup change.

#### 3. `toNodeVerificationStatus` silently collapses `"unavailable"` — and node mode reaches two different statuses for the same condition

**Severity:** Inconsistent
**Location:** `app/lib/types/decomposition.ts:29-38` (call sites `app/page.tsx:348-350`, `app/hooks/useActiveArtifactState.ts:41-42`)
**Move:** #3 / #7 (consumer contract, asymmetry)
**Confidence:** High

The global↔node status bridge was not extended for the new member. `toNodeVerificationStatus` has no `"unavailable"` case, so it falls into `default: return "unverified"`. When a node is selected and the shared formalization pipeline runs (page.tsx's node-scope accessor `setVerificationStatus` at `page.tsx:348-350`), an unavailable verifier writes `"unverified"` to the node; the round-trip via `fromNodeVerificationStatus` then yields `"none"`, so the amber banner, badge, and Re-verify affordance the diff added to `LeanCodeDisplay`/`VerificationBadge` never render in node scope — the signal is dropped with no user-visible trace. Combined with Finding 1, the same real-world condition (verifier offline) produces `"unverified"` on one node-mode path and `"failed"` on the other (`formalizeNode`), an asymmetry that guarantees confusing behavior. The catch-all `default` also means future `VerificationStatus` members will silently degrade the same way — the compiler cannot flag the gap.

**Recommendation:** Add an explicit mapping for `"unavailable"` (and ideally replace the `default` with an exhaustiveness check via `never`) so global-mode and node-mode consumers agree on what an unavailable verifier means.

#### 4. Documentation contract drift: nine stale doc claims describe the removed mock-fallback API behavior

**Severity:** Inconsistent
**Location:** `README.md:60,84,92`, `docs/USER_GUIDE.md:203,332-345`, `docs/ARCHITECTURE.md:197-204,234`, `docs/thoughts/feature-brainstorm.md:11`
**Move:** #3 (documentation drift)
**Confidence:** High

The fact-check report (Claims 2, 4, 6, 24, 27-31 — all Stale, binding) shows every prose description of this API still documents the old contract: mock `{ valid: true, mock: true }` fallback, the `localhost:3100` default, and the ARCHITECTURE request-flow diagram's hardcoded URL and mock branch. A consumer writing a client or test from these docs would code against a response shape that no longer exists. The USER_GUIDE's badge-status list (`USER_GUIDE.md:203` context, per Claim 24's scope note) also omits the new "Verifier offline" state, so the new taxonomy is documented nowhere outside code comments. Additionally, the in-code cause lists are imprecise per Claims 12/14/16 (banner, tooltip, and `VerifyLeanResult.unavailable` docstring all omit the reachable-but-errored `verifier-error` case).

**Recommendation:** Update all nine stale passages and the diagram in the same change (the repo's CLAUDE.md "Documentation Maintenance" section requires exactly this); extend the three in-code cause lists to "not configured, unreachable, or errored".

#### 5. Route's typed `reason`/`detail` response fields have no consumer anywhere

**Severity:** Minor
**Location:** `app/api/verification/lean/route.ts:5-15` (producer); `app/lib/formalization/api.ts:126-131` (the only client, which drops them)
**Move:** #3 (consumer contract)
**Confidence:** High

The route defines a typed `UnavailableReason` union and emits `reason` (always) and `detail` (on `verifier-error`), but `verifyLean` — the sole caller of `/api/verification/lean` — extracts only `valid`/`errors`/`unavailable` and discards both fields; nothing else in `app/` reads them (grep: `reason`/`detail` appear only inside the route). Commit c95c9cb itself removed `VerifyLeanResult.unavailableReason` as having "no consumer" (fact-check Claim 23, Verified), leaving the server half of the taxonomy orphaned: the client collapses all three reasons into one `"unavailable"` status, which is precisely why the banner/tooltip cause lists (Finding 4) cannot be accurate — the UI has no access to which reason occurred. A three-member reason enum on the wire with zero consumers is contract surface that will drift.

**Recommendation:** Either thread `reason` through `VerifyLeanResult` to the banner (fixing the Claim 12/14 imprecision and enabling reason-specific remedies — "set LEAN_VERIFIER_URL" is only the right advice for `verifier-not-configured`), or document `reason`/`detail` as debugging-only fields so the asymmetry is deliberate.

#### 6. `detail` field diverges from sibling routes' `details`

**Severity:** Minor
**Location:** `app/api/verification/lean/route.ts:8-14`
**Move:** #2 (naming against the grain)
**Confidence:** High

Precedent: `details` used in `app/api/formalization/lean/route.ts:145`

The only existing structured-extra-info field on an API error-ish response in this codebase is plural `details` (`{ error: err.message, details: err.details }`); the new route introduces singular `detail`. A consumer (or future maintainer) handling both routes must remember two spellings of the same concept. Low impact today because the field is unconsumed (Finding 5), but that is exactly when the spelling should be settled.

**Recommendation:** Rename to `details` to match the formalization route, or align both when `reason`/`detail` gain a consumer.

#### 7. `unavailable` optionality is asymmetric across the three layers that carry it

**Severity:** Minor
**Location:** `app/lib/formalization/api.ts:104-108` vs `app/lib/formalization/leanRetryLoop.ts:23-28` vs wire shape (`route.ts:8-15`)
**Move:** #8 (nullability contract)
**Confidence:** Medium

The same flag is required (`unavailable: boolean`, always materialized via `Boolean(...)`) on `VerifyLeanResult`, optional (`unavailable?: boolean`) on `LeanRetryResult`, and absent-on-success on the wire (the route's passthrough of a healthy verifier response carries no `unavailable` key; only `unavailableResponse` payloads do). `verifyResultToStatus` accepts `unavailable?: boolean`, hedging again. Nothing breaks — falsy handling is uniform — but consumers of the two Result types get different answers to "can I read `.unavailable` directly?", and the success-path wire shape differs from the failure-path shape for the same field.

**Recommendation:** Make `LeanRetryResult.unavailable` required (`unavailable: boolean`) and return `unavailable: false` on the valid/exhausted paths, matching `VerifyLeanResult`.

#### 8. `verifyResultToStatus` breaks the `to<Target>`/`from<Source>` shape of the existing status mappers

**Severity:** Informational
**Location:** `app/lib/formalization/api.ts:111-118`
**Move:** #2 (naming against the grain)
**Confidence:** Medium

Precedent: `toNodeVerificationStatus` / `fromNodeVerificationStatus` used in `app/lib/types/decomposition.ts:29-50`

The codebase's two existing status-mapping helpers use directional `to`/`from` prefixes; the new mapper uses the `<source>To<Target>` infix shape. Both are readable, and the new name is arguably clearer about its input, so this is a note rather than a defect — but the three mappers now form the family a reader will grep for, and two naming shapes make that family harder to discover.

**Recommendation:** Optional: `toVerificationStatus` would match the family; not worth churn on its own.

#### 9. Unavailable responses use HTTP 200 in-band signaling while sibling failures use `{ error }` + status codes

**Severity:** Informational
**Location:** `app/api/verification/lean/route.ts:8-15,45-49`
**Move:** #4 (error consistency)
**Confidence:** Medium

Sibling routes report failure as `{ error: ... }` with 4xx/5xx (baseline above), and this route itself keeps that pattern for the missing-`leanCode` 400 (`route.ts:18-22`). The three unavailable cases instead return HTTP 200 with in-band flags — including `verifier-error`, which previously forwarded the verifier's status code (`NextResponse.json(data, { status: res.status })` in the base). This is defensible as designed: "verifier unavailable" is a valid domain outcome, not a request error, and `verifyLean` never checks `res.ok` (a non-200 would have thrown nothing but also signaled nothing). Flagged so the divergence is deliberate rather than accidental; note that `fetchApi` (`api.ts:7`), the codebase's standard client helper, throws on non-OK — the 200-in-band choice is what lets `verifyLean` bypass that convention.

**Recommendation:** Keep as is, but a one-line comment in the route ("intentionally 200 — unavailability is a domain outcome, not a transport error") would prevent a future "fix" back to 5xx that would break `verifyLean`.

#### 10. Transient-status persistence invariant enforced on only one of two persistence paths

**Severity:** Minor
**Location:** `app/lib/stores/workspaceStore.ts:289,313` (unsanitized) vs `app/lib/utils/workspacePersistence.ts:34-37` and `app/hooks/useWorkspacePersistence.ts:119` (sanitized)
**Move:** #3 / #7 (consumer contract, asymmetry)
**Confidence:** Medium

The new test (`workspacePersistence.test.ts:32-34`, passing per fact-check Claim 21) pins the contract "`unavailable` is transient verifier-state, not artifact-state" into `sanitizeVerificationStatus`. But the live storage path is the Zustand `persist` middleware, whose `partialize` writes `verificationStatus` raw to `workspace-zustand-v1` (`workspaceStore.ts:313`), and the store's own `getSnapshot` (`workspaceStore.ts:289`) is likewise unsanitized — only the compatibility shim's `getSnapshot` applies the sanitizer (`useWorkspacePersistence.ts:119`). So `"unavailable"` (and pre-existing `"verifying"`) does persist across reloads on the primary path, and the diff's new test asserts an invariant the running app does not enforce. The gap predates this change, but the diff extends the transient set and adds the test without closing it.

**Recommendation:** Apply `sanitizeVerificationStatus` in `partialize` (or in `onRehydrateStorage`) so both persistence paths honor the invariant the new test documents.

## What Looks Good

- **`"unavailable"` enum member naming** fits the sibling adjectives exactly, and the kebab-case `verifier-*` reason codes match the `in-progress`/`causal-graph` literal style (Precedent: `app/lib/types/session.ts:1`, `app/lib/types/decomposition.ts:24`).
- **`VerifyLeanResult`** mirrors its direct sibling `LeanRetryResult` in name and shape.
- **`verifyResultToStatus`'s precedence rule** (`unavailable` wins over `valid`) is the right invariant, documented, extracted to one place, and executed against all four flag combinations (fact-check Claim 17).
- **Global-mode surfaces are complete and asymmetry-free**: banner, badge (with the amber not-checked state distinct from both green and red), Re-verify affordance, and both `useFormalizationPipeline` call sites route through the shared helper with consistent error-clearing (Claims 10, 11, 15).
- **Backward-compatible success path**: healthy-verifier responses pass through unchanged (`{ valid, errors? }`), so a working deployment's response contract is untouched (Claim 13/Case C).
- **Retry-loop short-circuit** on unavailability (Claim 20) is the correct contract evolution — no wasted attempts against a dead verifier in global mode.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `formalizeNode` ignores `unavailable`; node-mode shows "failed" for unchecked proofs; auto-queue churns | Breaking | `formalizeNode.ts:61` | High |
| 2 | Removed `LEAN_VERIFIER_URL` default breaks documented Docker setup contract | Breaking | `route.ts:26-30` | High |
| 3 | `toNodeVerificationStatus` collapses `unavailable`→`unverified`; two node statuses for one condition | Inconsistent | `decomposition.ts:29-38` | High |
| 4 | Nine stale doc passages still describe mock fallback / default URL; badge list omits new state | Inconsistent | `README.md`, `docs/*` | High |
| 5 | Typed `reason`/`detail` response fields produced but consumed nowhere | Minor | `route.ts:5-15`, `api.ts:126-131` | High |
| 6 | `detail` vs sibling `details` | Minor | `route.ts:8-14` | High |
| 7 | `unavailable` required/optional/absent asymmetry across layers | Minor | `api.ts:104-108`, `leanRetryLoop.ts:27` | Medium |
| 8 | Mapper name shape diverges from `to`/`from` family | Informational | `api.ts:115` | Medium |
| 9 | 200-in-band unavailable vs sibling `{error}`+status convention (deliberate, undocumented) | Informational | `route.ts:8-15` | Medium |
| 10 | Sanitizer invariant bypassed by live Zustand persistence path | Minor | `workspaceStore.ts:289,313` | Medium |

## Overall Assessment

Within global mode this is a well-executed, internally consistent contract change: the new status member, its precedence helper, and every global-mode surface (route → client → hook → banner/badge/persistence-sanitizer) agree, are named in the codebase's established style, and are test-covered. The change fails at the contract's edges. The status taxonomy has a second consumer family — the node-scoped decomposition pipeline — and neither of its two entry points was updated: `formalizeNode` re-reads an unavailable verifier as a failed proof (the exact misreading class this commit exists to eliminate, now in the opposite direction) and the `toNodeVerificationStatus` bridge silently drops the new member, so node mode never shows any of the new UI. The server half of the taxonomy (`reason`/`detail`) ships with zero consumers, and every piece of prose documentation still describes the removed contract, including a removed config default that breaks the documented Docker workflow. The fixes are localized (a mapper case, a branch in `formalizeNode`, doc updates), but the pattern — updating the producers and the nearest consumers while missing the sibling consumer subsystem — suggests the author should grep for every `VerificationStatus` consumer before landing status-contract changes.
