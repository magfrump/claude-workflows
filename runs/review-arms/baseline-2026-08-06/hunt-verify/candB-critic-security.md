Commit: 6cf4b0d

# Security Review — assisted evidence integration (candB, 6cf4b0d)

**Scope:** `app/api/evidence-integrate/` (route.ts, integrateValidation.ts) + `app/lib/utils/applyProposals.ts`
**Date:** 2026-08-07
**Based on:** `hunt-verify/candB-fact-check.md`

No escalation (HALT) patterns matched: no plaintext secrets, no injection into SQL/shell, no TLS disablement, no hardcoded keys. The whole app has **no auth on any `app/api/**/route.ts`** (confirmed by grep across the tree at 6cf4b0d), so "missing auth" is systemic, not a delta this PR introduces.

## Trust Boundary Map

```
B1: [HTTP body: artifactContent JSON, papers[]] → [route.ts POST validation]        → [artifact obj, validPaperIds]
B2: [LLM response, influenced by user artifact/abstracts = indirect prompt injection] → [validateProposal → resolveFieldPath (read-only)] → [RawIntegrationProposal]
B3(new): [user-approved proposals in browser]    → [applyProposals → resolveFieldPath WRITE sink] → [mutated artifact JSON]
```

B1: request body is untrusted; parsed as JSON (truncated to 10 000 chars) and bounded (papers ≤ MAX_INTEGRATION_PAPERS). B2: the proposals are LLM output, but the LLM is fed user-controlled `artifactContent` and paper `abstract` text, so `fieldPath`/`proposedValue` are attacker-*influenceable* via indirect prompt injection. On the server, `resolveFieldPath` is used **read-only** (a boolean filter) — nothing is written. B3 is the only write sink, and it runs **client-side** in `FindEvidenceButton.tsx` on proposals the user explicitly approved.

## Findings

#### Field-path write sink permits `__proto__` terminal key (prototype-pollution-shaped)
**Severity:** Medium
**Location:** `app/lib/utils/applyProposals.ts:20-38` (resolveFieldPath), `:72-85` (applyProposals write)
**Boundary:** B3 (write), B2 (read)
**Move:** #1 trust boundaries, #7 serialization/deserialization
**Confidence:** Medium
**Legibility-target:** a dangerous-key denylist (`__proto__`, `prototype`, `constructor`) in `resolveFieldPath`.

`resolveFieldPath` splits an attacker-influenceable path and, for the terminal segment, only guards with `if (!(lastKey in current)) return null;`. `"__proto__" in obj` is **true** for any object, so `fieldPath: "__proto__"` resolves to `{ parent: obj, key: "__proto__" }`. `applyProposals` then executes `obj["__proto__"] = JSON.parse(proposedValue)` (`:83`), reassigning the object's prototype. Classic key-injection via `constructor.prototype.x` is *incidentally* blocked because writing a **new** key fails the `lastKey in current` check (`"x" in Object.prototype` is false → null), and the `__proto__` reassignment is defused in practice because the result is immediately `JSON.stringify`ed (`:86`), which ignores the prototype. So exploitability today is low — but the sink is only accidentally safe. Any future server-side or persist-to-storage caller of `applyProposals` (or a change that stops round-tripping through `JSON.stringify`) turns this into real prototype pollution, and the path feeding it is influenceable by indirect prompt injection through the artifact/abstract text at B2.

**Recommendation:** In `resolveFieldPath`, reject any segment equal to `__proto__`, `prototype`, or `constructor` before walking (return null). Cheap, closes the class, and makes the safety explicit rather than incidental.

#### `proposedValue` JSON-parsed and written into a typed field (type confusion)
**Severity:** Low
**Location:** `app/lib/utils/applyProposals.ts:78-84`
**Boundary:** B3
**Move:** #7 serialization
**Confidence:** Medium

`applyProposals` does `try { value = JSON.parse(proposal.proposedValue) } catch { value = proposal.proposedValue }`, then writes `value` into the resolved field. A `proposedValue` of `"[1,2,3]"` or `"null"` replaces a string field (e.g. `summary`) with an array/null. Downstream renderers that assume `string` at that path can throw or mis-render. `validateProposal` only checks `proposedValue` is a *string* at B2; it never re-checks the parsed type matches the target field's type. Impact is confined to the user's own artifact (self-inflicted), hence Low.

**Recommendation:** Only JSON-parse when the existing value at the path is itself non-string (use `getFieldValue` to check), otherwise assign the raw string; or validate the parsed type against the current value's type before assigning.

#### Raw error message returned to client
**Severity:** Low
**Location:** `app/api/evidence-integrate/route.ts:238-242`
**Boundary:** B1
**Move:** #3 error path
**Confidence:** Medium

The catch-all returns `err.message` verbatim in the 500 body (`{ error: message }`). For unexpected server errors this can leak internal detail (paths, dependency internals) to an unauthenticated caller. Consistent with app norms but worth a generic message.

**Recommendation:** Log `err.message` server-side (already done) but return a static "Internal error" string to the client for the 500 branch.

#### Unauthenticated, unrated paid LLM endpoint
**Severity:** Low
**Location:** `app/api/evidence-integrate/route.ts:96-206` (whole POST)
**Boundary:** B1
**Move:** #8 "what if a million of these"
**Confidence:** High

Each request triggers a `callLlm` (Claude Sonnet, maxTokens 4096) with no auth and no rate limiting. An attacker can loop the endpoint to burn OpenRouter credit (cost-DoS). Bounds are reasonable per-request (papers capped, abstract sliced to 500, artifact to 10 000), so it's amplification-limited. Systemic to the app (no route has auth), so this PR is not uniquely at fault — flag for the deployment/auth story, not a blocker here.

**Recommendation:** Track under the app-wide auth/rate-limit decision; if this endpoint ships to an internet-reachable deployment, gate it behind the same auth as other paid endpoints.

## What Looks Good

- `validateProposal` is a proper allowlist: required-string type checks, `currentValue !== proposedValue`, `resolveFieldPath` existence check, `paperIds` filtered against the server-derived `validPaperIds` set (LLM cannot invent paper IDs), and `editType` constrained to a fixed enum with safe default. This is the right shape for constraining LLM output at B2.
- `validPaperIds` is derived server-side from the request papers, not trusted from the LLM — good.
- Request validation at B1 is thorough (type, presence, count cap, JSON-parse guard).
- Server-side `resolveFieldPath` use is read-only; the dangerous write sink is not reachable from the HTTP handler in this diff.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `__proto__` terminal key in field-path write sink | Medium | B3/B2 | `applyProposals.ts:20-38,72-85` | Medium |
| 2 | Type confusion via JSON-parsed proposedValue | Low | B3 | `applyProposals.ts:78-84` | Medium |
| 3 | Raw error message returned to client | Low | B1 | `route.ts:238-242` | Medium |
| 4 | Unauthenticated/unrated paid LLM endpoint | Low | B1 | `route.ts:96-206` | High |

## Overall Assessment

Solid posture for an LLM-proposal-application feature. The validation layer (`validateProposal`) correctly treats LLM output as untrusted and constrains it against server-derived data, and the one dangerous primitive — the field-path write in `applyProposals` — is reachable only client-side on user-approved edits and is incidentally defused by the `JSON.stringify` round-trip. The single most important thing to address is finding #1: add an explicit `__proto__`/`prototype`/`constructor` denylist to `resolveFieldPath` so the write sink is safe by construction rather than by accident, before any caller applies proposals server-side or persists them. No blocking issues.
