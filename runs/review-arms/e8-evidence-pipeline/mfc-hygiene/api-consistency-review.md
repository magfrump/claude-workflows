# API Consistency Review — mfc-hygiene (LLM-server hygiene)

**Scope:** `git diff d86d2dc...f2f149b` — `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/callLlm.test.ts`, `app/lib/llm/streamLlm.ts`
**Commit:** f2f149b
**Date:** 2026-08-17
**Based on:** `runs/review-arms/e8-evidence-pipeline/mfc-hygiene/code-fact-check-report.md` (k=2 merged code-fact-check; Claim 10b Stale, Claim 1c Mostly accurate are the binding foundation for this review)

The consumer-facing surfaces this diff touches are: (a) the **SSE event-payload schema** documented in `streamLlm.ts`'s protocol JSDoc and consumed by any SSE reader, (b) the **HTTP error-envelope shape** returned by the LLM route handlers, and (c) the **exported factory** `makeAnthropicClient` (renamed from `getAnthropicClient`). No new HTTP routes, request/response DTOs, enums, or error codes are introduced.

## Baseline Conventions

Observed from the changed files and their siblings:

- **HTTP error envelope.** All LLM route catch sites return a flat `{ error: string, details?: string }` JSON body with status 502. `details` carries a bounded slice of provider/response content and is surfaced to the caller in every current handler (`edit/artifact/route.ts:83-85`, `formalization/artifactRoute.ts:108-111` and `:114-118`, and the six other `OpenRouterError` catch sites enumerated in fact-check Claim 7). The envelope is flat (no nested `error.code`/`error.message` object), keys are camelCase-free single words (`error`, `details`).
- **SSE event envelope.** `sseEvent(event, data)` emits `event: <name>\ndata: <json>`. Event names are lowercase single words: `token`, `done`, `error`. Payloads are flat objects: `{ text }`, `{ text, usage }`, `{ error }`. The in-repo SSE consumer (`app/lib/formalization/api.ts:92`) reads only `.error`.
- **Log redaction.** The stated policy across the diff is: log status/length/endpoint metadata only, never user-derived response or provider-error content; keep the full content on the returned/thrown object so the *caller* (who originated the request) can opt into it. Applied at `edit/artifact/route.ts:77-81`, `callLlm.ts:182-187`, and `streamLlm.ts:157-162`.
- **Client-factory naming.** Sibling helpers use `get*` for accessors (`getSelectionCoordinates`, `getGraphViewportElement`, `getCachedResult`) and `build*` for constructors of derived values (`buildUserMessage`). There is no other "construct a fresh SDK client" factory in the repo.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `makeAnthropicClient` | exported function (factory) | `getAnthropicClient` (removed, this rename), `buildUserMessage`, `getCachedResult` | `app/lib/llm/callLlm.ts`, `app/lib/formalization/artifactRoute.ts:10` | Consistent — `make` correctly signals fresh construction, distinguishing it from the memoizing `get*` accessors; rename is semantically justified and all in-repo callers updated (see Finding 3) |
| `event: error` payload `{ error }` | event schema | `event: token` `{ text }`, `event: done` `{ text, usage }` | `app/lib/llm/streamLlm.ts:65-71` | Inconsistent with its own documented schema — JSDoc says `{ error, details }` (Finding 1) |

No new routes, types/classes, enum variants, error codes, or request/response fields are introduced by this diff.

## Findings

#### SSE `error` event schema: documented `{ error, details }`, emitted `{ error }`

**Severity:** Inconsistent
**Location:** `app/lib/llm/streamLlm.ts:71` (JSDoc) vs `app/lib/llm/streamLlm.ts:162` (emit site)
**Move:** #3 (consumer contract) / #7 (asymmetry)
**Confidence:** High

The SSE protocol JSDoc still documents the error event as `event: error — { error: "message", details: "..." }`, but commit 7c799cc removed `details` from the only emit site; the wire payload is now exactly `{ error }` (fact-check Claim 10b, Stale, executed: `Object.keys(data) === ["error"]`). This is a producer/consumer contract mismatch on a published event schema: a client coded against the documented protocol will read `data.details` and always get `undefined`. The neighboring `errorWithDetails` JSDoc *was* updated in this same diff to explain that `details` is intentionally not forwarded over SSE — so the protocol block three lines above is now internally contradicted by the file's own documentation. The in-repo consumer (`app/lib/formalization/api.ts:92`) reads only `.error`, so there is no current in-repo breakage — the exposure is to any external/future SSE client that trusts the protocol comment.

**Recommendation:** Update the protocol JSDoc line to `event: error — { error: "message" }` to match the emit site and the `errorWithDetails` note. If `details` on the wire is ever wanted back, that is a schema decision to make deliberately, not to leave implied by a stale comment.

#### Log-redaction policy applied inconsistently across sibling invalid-JSON handlers

**Severity:** Inconsistent
**Location:** `app/api/edit/artifact/route.ts:77-81` (redacted) vs `app/lib/formalization/artifactRoute.ts:106-107` (not redacted)
**Move:** #4 (error consistency)
**Confidence:** High

This diff establishes the policy — in `edit/artifact/route.ts` the invalid-JSON log now emits `${responseText.length} chars` instead of a content slice, with a comment stating response text "is a function of the user's source material and shouldn't end up in server logs." But the shared generic handler `handleArtifactRoute`, which serves the same `callLlm` pipeline and the identical invalid-JSON failure for every other artifact route, still `console.error`s a 500-char content preview (`formalization/artifactRoute.ts:106-107`; fact-check Claim 1c, executed: the spy captured the marker content). Two sibling handlers of the same error condition now treat the same class of user-derived data differently — one redacts to a length, the other logs 500 chars. A reader who inferred from the new comment that the redaction is a pipeline-wide invariant would be wrong. The log *message text* also diverges (`LLM returned invalid JSON` vs `Failed to parse LLM response as JSON`), a lesser inconsistency of the same origin.

**Recommendation:** Apply the same length-only redaction to `artifactRoute.ts:106-107` (log `${responseText.length} chars`, keep the 500-char slice only in the `details` response body, which already matches `edit/artifact`). Either make the redaction pipeline-wide or scope the `edit/artifact` comment to say it is route-local.

#### Exported factory renamed `getAnthropicClient` → `makeAnthropicClient` (signature-compatible)

**Severity:** Informational
**Location:** `app/lib/llm/callLlm.ts:14`
**Move:** #2 (naming) / #3 (consumer contract)
**Confidence:** High

Precedent: `get*` accessors and `build*`/`make*` constructors used in `app/lib/utils/*.ts`, `app/lib/formalization/artifactRoute.ts:10`, `app/lib/llm/cache.ts`

The exported symbol `getAnthropicClient` was renamed to `makeAnthropicClient` and its behavior changed from memoized-singleton to fresh-per-call. The rename is the *right* call for consistency: `get*` in this repo denotes accessors that may reuse/lookup (`getCachedResult`, `getSelectionCoordinates`), and keeping `get` on a now-non-caching constructor would have been the misleading option. The signature `(apiKey: string): Anthropic` is unchanged, and both in-repo importers (`callLlm.ts:133`, `streamLlm.ts:8,207`) are updated in the same diff — `rg getAnthropicClient app` returns zero hits, so no stale reference remains. Renaming an exported symbol is technically breaking for any out-of-tree importer, but this is an app-internal lib with no published-package surface, so the practical consumer impact is nil.

**Recommendation:** No change required. Flagging only so the rename of a public symbol is a recorded, deliberate choice rather than an incidental one.

## What Looks Good

- **HTTP error envelope stayed consistent.** The `edit/artifact` invalid-JSON branch still returns `{ error, details }` with `details = responseText.slice(0, 500)` at status 502, matching `artifactRoute.ts:108-111` exactly. The redaction change touched only the *log*, not the *response contract* — consumers of the 502 body see no change. Correctly reasoned: the caller originated the content, so echoing it back to them (but not to disk) is the right asymmetry.
- **`makeAnthropicClient` adopted uniformly.** Both call and stream paths use the same factory; no divergence between the two provider entry points.
- **SSE `token`/`done` payloads unchanged and consistent** (`{ text }` / `{ text, usage }` on every emitting branch — fact-check Claim 10a Verified). Only the `error` event's *documentation* drifted.
- **`errorWithDetails` JSDoc was updated** in this diff to document the deliberate non-forwarding of `details` over SSE — the correct instinct; it just wasn't carried up to the protocol block (Finding 1).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | SSE `error` schema: doc says `{error,details}`, wire sends `{error}` | Inconsistent | `streamLlm.ts:71` vs `:162` | High |
| 2 | Log redaction half-applied — `artifactRoute.ts` still logs 500-char content preview | Inconsistent | `route.ts:77-81` vs `artifactRoute.ts:106-107` | High |
| 3 | Exported factory renamed `get*`→`make*` (signature-compatible, all callers updated) | Informational | `callLlm.ts:14` | High |

## Overall Assessment

The change is largely consistent with the codebase's conventions — the HTTP error envelope is preserved, the client factory is adopted uniformly, and the rename improves rather than breaks the naming grain. The two real consistency defects are both **doc/producer contract drift left half-finished**, not design mistakes: the SSE error-event schema comment was not updated when `details` was dropped from the wire (Finding 1), and the log-redaction policy this diff introduces was applied to one invalid-JSON handler but not to its sibling that runs the same pipeline (Finding 2). Both are fixable in place with one-to-two-line edits and neither breaks an existing in-repo consumer — the risk is entirely to external SSE clients trusting the stale protocol block and to the false impression that log redaction is a pipeline-wide invariant. Fixing Finding 2 (extend the redaction to `artifactRoute.ts`) is the only one with a live privacy consequence; Finding 1 is a documentation correction.
