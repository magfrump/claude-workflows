Commit: f2f149b

# API Consistency Review — LLM-server hygiene (branch diff d86d2dc..f2f149b)

**Scope:** branch diff `d86d2dc..f2f149b` — `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.ts`, `app/lib/llm/callLlm.test.ts` (new), `app/lib/llm/streamLlm.ts`
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/hygiene/fact-check.md` (7 verified, 1 stale)

## Baseline Conventions

Two distinct error-delivery surfaces exist and consumers bind to each differently:

- **Non-streaming HTTP routes** return a JSON body `{ error: string, details?: string }`. Both the invalid-JSON path (`route.ts:82-85`) and the `OpenRouterError` path (`route.ts:89-93`) include `details`. This contract is unchanged by the diff.
- **SSE streaming** emits typed events. The self-documented protocol (`streamLlm.ts:68-71`) is `event: token — { text }`, `event: done — { text, usage }`, `event: error — { error, details }`. The sole SSE consumer, `app/lib/formalization/api.ts:89-94`, reads **only** `.error` from the error event and never `.details`.
- Exported factory naming is mixed across `app/lib`: `getSelectionCoordinates`, `getGraphViewportElement`, `buildUserMessage`, and now `makeAnthropicClient` — no single dominant verb.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `makeAnthropicClient` | exported function (rename of `getAnthropicClient`) | `buildUserMessage`, `getGraphViewportElement`, `getSelectionCoordinates` | `app/lib/formalization/artifactRoute.ts:10`, `app/lib/utils/*.ts` | Consistent — `make*` (construct) correctly signals the behavior change from `get*` (memoized retrieval); no dominant verb convention to violate |
| `constructorCalls`, `messagesCreate` | test locals | n/a (private to `callLlm.test.ts`) | n/a | Out of scope — private test locals, not a public surface |

No new routes, types, enum variants, config fields, or event names introduced. The only public-surface change is the `getAnthropicClient` → `makeAnthropicClient` rename.

## Findings

#### SSE protocol JSDoc documents a `details` field the emit site no longer sends

**Severity:** Inconsistent
**Location:** `app/lib/llm/streamLlm.ts:71`
**Move:** #3 (consumer contract) / #7 (asymmetry — naming-shaped, doc vs. payload)
**Confidence:** High

Precedent: SSE `error` event payload shape defined at emit site `app/lib/llm/streamLlm.ts:162` (`sseEvent("error", { error: message })`) and consumed at `app/lib/formalization/api.ts:89-94`.

The module's own SSE-protocol JSDoc still advertises the error event as `event: error — { error: "message", details: "..." }`, but this same diff removed `details` from the only emit site: line 162 now sends `{ error: message }`. The sibling `errorWithDetails` JSDoc (streamLlm.ts:25-29) *was* updated to explain that `details` is intentionally not forwarded over SSE, so the two docs now contradict each other — one says SSE carries `details`, the other says it deliberately does not. A client author reading the protocol block would code against a field that is never transmitted. This is not runtime-breaking (the sole consumer at `api.ts:92` reads only `.error`), but it is exactly the doc-vs-contract drift that misleads the next SSE consumer.

**Recommendation:** Update line 71 to `event: error — { error: "message" }` to match the emit site and the `errorWithDetails` note.

#### Intentional error-contract divergence between HTTP and SSE surfaces

**Severity:** Informational
**Location:** `app/api/edit/artifact/route.ts:82-93` (HTTP `{ error, details }`) vs. `app/lib/llm/streamLlm.ts:162` (SSE `{ error }`)
**Move:** #4 (error consistency) / #7 (asymmetry)
**Confidence:** High

Post-diff, the two error surfaces disagree on whether `details` reaches the caller: the non-streaming routes still return `{ error, details }` (details slice / OpenRouter body), while SSE now sends `{ error }` only. This is a deliberate, well-reasoned split — the streaming catch block cannot let a per-route handler decide what to surface, so it withholds provider bodies uniformly (comment at streamLlm.ts:157-159). Worth recording so the divergence is a documented decision rather than accidental drift; no action required beyond the JSDoc fix above.

## What Looks Good

- **The SSE payload change is safe for existing consumers.** The only SSE reader, `app/lib/formalization/api.ts:89-94`, extracts `JSON.parse(dataStr).error` and never touches `details`; dropping `details` from the event is transparent to it. `transformSseStream.ts:55-56` passes error events through unchanged. So the `{error, details}` → `{error}` change is non-breaking in practice.
- **The `getAnthropicClient` → `makeAnthropicClient` rename is clean.** No lingering references remain (grep for `getAnthropicClient` returns zero hits in `app/`); the sole caller in `streamLlm.ts:207` was updated in the same diff. The verb change from `get` (which implied the removed memoized singleton) to `make` (fresh construction) accurately reflects the new semantics rather than silently repurposing the old name.
- **`OpenRouterError.details` and the HTTP `{ error, details }` contract are untouched** — the non-streaming consumer contract is preserved.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | SSE protocol JSDoc still documents removed `details` field | Inconsistent | `streamLlm.ts:71` | High |
| 2 | Intentional HTTP-vs-SSE error-contract divergence | Informational | `route.ts:82-93` / `streamLlm.ts:162` | High |

## Overall Assessment

The change is consistent with the codebase's API patterns and, importantly, non-breaking for real consumers: the sole SSE reader never bound to `details`, and the exported-function rename left no dangling references. The one substantive consistency defect is documentation-only — the SSE protocol JSDoc at `streamLlm.ts:71` still advertises `details` on the error event after the emit site dropped it, directly contradicting the updated `errorWithDetails` doc three dozen lines above. It is a one-line in-place fix. No consumer-facing runtime breakage; consumer impact is limited to a future client author being misled by the stale protocol comment.
