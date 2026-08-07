Commit: f2f149b

# Architecture Review — LLM-server hygiene (branch diff `d86d2dc..f2f149b`)

**Scope:** `git diff d86d2dc..f2f149b` — worktree pinned at f2f149b (`/workspace/runs/review-arms/baseline-2026-08-06/wt-hygiene`)
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/hygiene/fact-check.md` (8 claims: 7 verified, 1 stale)
**PR intent:** Stop leaking response bodies/details in logs and SSE error payloads; align the SSE error contract and its JSDoc.

Severity mapping used: Structural→red, Coupling→amber, Minor/Informational→green.

## Scope check

In scope. The diff touches two trigger categories:
- **Public API** — `getAnthropicClient` (singleton) renamed and re-semantic'd to `makeAnthropicClient` (fresh per call), an exported symbol of `app/lib/llm/callLlm.ts` re-imported by `app/lib/llm/streamLlm.ts`.
- **Cross-cutting concern (error-handling pipeline + message-format contract)** — the SSE `error` event payload shape changed (`{ error, details }` → `{ error }`), and the logging surface of both the streaming and non-streaming error paths changed.

## Dependency Map

`streamLlm.ts` depends on `callLlm.ts` for `OPENROUTER_API_URL`, `DEFAULT_ANTHROPIC_MODEL`, `makeAnthropicClient`, and the `LlmCallUsage` type. Direction is unchanged and correct: the streaming module (a variant client) depends on the shared LLM-adapter module; nothing in `callLlm.ts` depends back on `streamLlm.ts`. The SSE message-format contract flows outward from `streamLlm.ts` (producer) to the sole in-repo client consumer `app/lib/formalization/api.ts:fetchStreamingApi` (lines 89–94), which reads only `.error` from the error event. Route handlers (`app/api/**/route.ts`) consume `OpenRouterError.details` from the non-streaming path and re-surface it in HTTP JSON responses. No new dependency edges, no cycles, no layer reversals introduced.

## Findings

#### Divergent hygiene contract between the streaming and non-streaming error paths

**Severity:** Coupling
**Location:** `app/lib/llm/streamLlm.ts:158-162` vs. `app/lib/llm/callLlm.ts:179-187` + route handlers (`app/api/edit/artifact/route.ts:89-93`, `app/api/refine/context/route.ts:54`, `app/api/edit/inline/route.ts:29`, `app/api/edit/whole/route.ts:37`, `app/api/formalization/lean/route.ts:145`, `app/api/explanation/lean-error/route.ts:38`)
**Move:** #2 (responsibility boundaries) / #7 (coupling surface across the error-handling pipeline)
**Confidence:** Medium

The PR establishes a hygiene rule for provider error bodies — "Provider error bodies can echo parts of the request, so don't write them to logs or send them to the client over SSE" (`streamLlm.ts:158-159`). The streaming path enforces it: `details` is neither logged nor forwarded (`streamLlm.ts:160-162`). The non-streaming path enforces only half of it: it stops *logging* the body (`callLlm.ts:182-186`, quoted: `console.error(\`[${endpoint}] OpenRouter error: status=${response.status}\`)`), but the same provider body still rides out to the client on `OpenRouterError.details` and route handlers still surface it verbatim in the HTTP JSON response (quoted: `{ error: err.message, details: err.details }`, `app/api/edit/artifact/route.ts:91`). So for identical data — an OpenRouter provider error body — the streaming contract withholds it from the caller while the non-streaming contract forwards it. A maintainer reasoning about "does our server leak provider bodies to callers?" now has to answer "depends which path," which is exactly the ambiguity a hygiene pass should eliminate. Whether the client-facing leak is acceptable is a security-reviewer call; the architectural cost is the split contract across the error-handling pipeline.

**Recommendation:** Decide one policy for provider error bodies reaching the caller and apply it to both paths. If callers legitimately need `details` to debug their own input (as the `route.ts` comments argue for the JSON path), document that the SSE path deliberately differs and why; otherwise align them.
**Legibility-target:** Maintainers extending the error-handling pipeline; security reviewer auditing egress of provider content.

#### SSE protocol JSDoc still documents the removed `details` field

**Severity:** Minor
**Location:** `app/lib/llm/streamLlm.ts:71`
**Move:** #3 (module boundary / message-format contract as public surface)
**Confidence:** High

The `streamLlm` doc block advertises the module's public wire contract (quoted: `*   event: error   — { error: "message", details: "..." }`), but the sole emit site now sends `{ error }` only (`streamLlm.ts:162`), and the sibling `errorWithDetails` JSDoc *was* updated to reflect the removal while this protocol block was not. This is the exact miss the PR intent set out to close ("align the SSE error contract and its JSDoc"). The message format is the module's contract with any current or future SSE client; a contract description that names a field never sent will mislead the next client author into parsing for `details`. Corroborated by fact-check Claim 5 (Stale, High).

**Recommendation:** Update line 71 to `event: error   — { error: "message" }`.
**Legibility-target:** Authors of new SSE clients reading the protocol block as the authoritative contract.

#### `errorWithDetails` attaches a `details` property no consumer reads

**Severity:** Informational
**Location:** `app/lib/llm/streamLlm.ts:30-34`, thrown at `streamLlm.ts:265`
**Move:** #8 (extension points) / #5 (interface segregation)
**Confidence:** High

This diff removed `getErrorDetails` (the only reader) but kept `errorWithDetails` writing a `details` property onto the thrown Error, justified by the comment "for any in-process consumer that opts in to reading it" (`streamLlm.ts:27-29`). No such consumer exists (fact-check Claim 4 confirms `getErrorDetails` grep is now zero). This is a speculative extension point carrying data nothing consumes — harmless today, but it invites the same drift the PR is fixing: the property can silently diverge from what the streaming catch block actually surfaces. Keeping it is defensible for the non-streaming symmetry with `OpenRouterError`, but note it is currently dead within the streaming module.

**Recommendation:** Keep if you intend a near-term in-process reader; otherwise consider dropping the `details` attachment in the streaming path so the throw carries only what's actually forwarded. No action required for correctness.
**Legibility-target:** Future maintainers of the streaming error path.

## What Looks Good

- **`getAnthropicClient` → `makeAnthropicClient` migration is clean.** The rename plus singleton-removal is applied at both call sites (`callLlm.ts:133`, `streamLlm.ts:207`) with zero lingering references (fact-check Claim 2, High). Dependency direction is preserved and the factory is a smaller, more honest public surface than the mutable module-scoped singleton it replaced — per-call construction removes hidden shared state between requests.
- **Logging/forwarding split is well-placed.** The "log length/status only, let the payload/error object carry the body" pattern keeps the hygiene decision at the boundary where the body is available and pushes the surface-or-not choice to the route handler that owns the caller relationship (`callLlm.ts:182-187`) — a reasonable separation of concerns.
- **SSE contract change is internally non-breaking.** The only in-repo SSE consumer reads just `.error` (`app/lib/formalization/api.ts:89-94`), so narrowing the payload breaks no current consumer; the residual risk is purely the stale doc (finding above).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Divergent hygiene contract across streaming vs. non-streaming error paths | Coupling | `streamLlm.ts:158-162` vs `callLlm.ts:179-187` + route handlers | Medium |
| 2 | SSE protocol JSDoc still documents removed `details` field | Minor | `streamLlm.ts:71` | High |
| 3 | `errorWithDetails` attaches `details` no consumer reads | Informational | `streamLlm.ts:30-34` | High |

## Overall Assessment

The change improves structural integrity: it removes hidden per-process shared state (the client singleton), tightens the logging surface, and narrows a message-format contract without breaking any in-repo consumer. No structural (red) issues. The one architectural loose end worth addressing is the split hygiene contract for provider error bodies (finding 1) — the streaming path withholds them from the caller while the non-streaming path still forwards them, so the codebase no longer has a single answer to "do we leak provider bodies to callers?" The stale SSE JSDoc (finding 2) is the small documentation miss the PR itself set out to fix. Both are fixable in place; neither indicates a need for restructuring.
