# Security Review — mfc-deploy Vercel deploy documentation (`d86d2dc...HEAD`)

**Commit:** 4329d6e
**Scope:** `git diff d86d2dc...HEAD` — `CLAUDE.md` (new Deployment section), `README.md` (Deploy-to-Vercel button, section, Lean Verification Service edits). Documentation diff.
**Date:** 2026-08-17
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/code-fact-check-report.md` (k=2 merged; its Incorrect/Unverifiable verdicts bind and were not re-verified)

This is a documentation diff. The security question is not "does this code contain a vulnerability" but "what does this documentation invite a user to stand up, and are the security-relevant claims it makes true." The diff adds a one-click "Deploy with Vercel" button and prose describing the deployment as "self-hosted single-tenant … one trust boundary per deployment." I read the API routes and the verifier the docs point at to check whether that framing holds.

## Trust Boundary Map

```
B1 (new): [public internet request] → [NO authentication check] → [Next.js /api/* routes → deployer's ANTHROPIC_API_KEY / OPENROUTER_API_KEY → outbound paid LLM calls]
B2 (new): [attacker-supplied leanCode over the network] → [Next.js /api/verification/lean → LEAN_VERIFIER_URL] → [verifier POST /verify → execFile("lake build") on the submitted content]
B3:       [LLM/source-derived text] → [verifier mock fallback on fetch failure] → [client treats {valid:true,mock:true} as a real pass]
```

The diff does not add or move any boundary *in code* — it adds documentation that **invites the user to expose B1 and B2 to the public internet** where before they lived only on `localhost`. The "Deploy with Vercel" button stands up a publicly-reachable instance; the `LEAN_VERIFIER_URL` guidance ("host it elsewhere — Railway, Render, Fly.io — and set this to its URL") invites the user to stand up a public verifier. The prose claim "one trust boundary per deployment" implies the deployment is isolated; in fact every `/api/*` route is reachable by anyone who learns the URL, with no auth check anywhere (`rg` for `auth|Authorization|token|secret` across `app/api` and `verifier/server.ts` returns zero non-test hits). No guardrail, matcher, sanitizer, or filter is added by this diff, so cognitive move #11 (≥3 bypass candidates) has no target here — there is no new guard to bypass; the relevant finding is the *absence* of one on the newly-public surface.

## Findings

#### Deploy button invites a public, unauthenticated instance holding the deployer's API key

**Severity:** High
**Location:** `README.md:5` (deploy button), `README.md:98-120` (Deploy to Vercel section), `CLAUDE.md:71-77`
**Boundary:** B1
**Move:** #1 (trace trust boundaries), #5 (invert the access-control model), #8 (what if there are a million of these)
**Confidence:** High

The diff adds a one-click deploy button and documents the app as "self-hosted single-tenant … one trust boundary per deployment," which reads as an isolation guarantee. But none of the `/api/*` routes — `formalization`, `edit`, `decomposition`, `refine`, `explanation`, `predict`, `analytics`, `verification` — perform any authentication or authorization check (verified by grep: no `auth`/`Authorization`/session/token handling in `app/api` outside tests). A user who follows the button gets a public URL that anyone can POST to, driving paid Anthropic (or, if configured, OpenRouter) calls on the deployer's key. Inverting the access-control model (move #5): the routes prevent *nothing* for an unauthenticated caller. At scale (move #8) this is unbounded — a scripted attacker can exhaust the deployer's API credit or run a free LLM proxy on their dime, and the `POST /verify` path (B2) can be driven the same way. The documentation's "single-tenant / one trust boundary" language is a disclosure asymmetry: it implies protection the deployment does not have and never warns the deployer that the instance is world-reachable and unauthenticated. This meets the mechanism-severity floor (a concrete abuse mechanism reachable in the exact environment the docs invite); the financial/resource-exhaustion blast radius puts it at High.

**Recommendation:** Add an explicit warning to the Deploy to Vercel section that the deployed instance is public and unauthenticated, that anyone with the URL can spend the configured API key, and recommend a mitigation (Vercel password protection / access control, a proxy auth layer, or spend caps on the API key). At minimum, drop the "single-tenant / one trust boundary per deployment" framing, which implies an isolation the code does not provide.

#### Docs recommend hosting the Lean verifier publicly; `/verify` runs `lake build` on submitted content with no auth

**Severity:** Medium
**Location:** `README.md:115` (`LEAN_VERIFIER_URL` guidance), `verifier/server.ts:86-118,129-158`
**Boundary:** B2
**Move:** #1 (trust boundaries), #8 (what if there are a million of these)
**Confidence:** Medium

The diff newly instructs the deployer to host the verifier on a public provider and point `LEAN_VERIFIER_URL` at it. The verifier (`verifier/server.ts`) has no authentication: `POST /verify` writes the caller-supplied `leanCode` to `Verify.lean` and shells out to `lake build` (`execFile("lake", ["build"], … timeout 30_000)`). Once this is publicly hosted per the docs' recommendation, any internet caller can submit arbitrary Lean source and cause a 30-second build to run on the verifier host. Lean elaboration is effectively arbitrary compute (and `#eval` runs code at elaboration time), so this is a compute/DoS surface, bounded only by a `MAX_QUEUE_LENGTH = 3` mutex that itself makes denial-of-service *easier* (three concurrent submissions fill the queue and 503 legitimate requests). The docs invite this exposure without noting the verifier is unauthenticated or that it should sit behind network controls. Docker isolation limits blast radius to the container, which is why this is Medium rather than High, and Confidence is Medium because the concrete impact (arbitrary elaboration vs. pure build DoS) depends on the pinned Lean/Mathlib config not exercised here (fact-check Claim 9a/11 could not run the verifier — Docker absent).

**Recommendation:** Warn in the `LEAN_VERIFIER_URL` row that the verifier is unauthenticated and must not be exposed to the public internet without an access-control layer (network allowlist, shared secret, or private networking between the Vercel app and the verifier host).

#### `CLAUDE.md:76` overstates when the verifier silently mocks (fact-check: Incorrect)

**Severity:** Low
**Location:** `CLAUDE.md:76`
**Boundary:** B3
**Move:** #3 (check the error path)
**Confidence:** High

The bound fact-check verdict (Claim 4a, **Incorrect**, executed in both replicates) refutes the CLAUDE.md claim that "when `LEAN_VERIFIER_URL` is unset **or** unreachable … falls back to a mock." Unset does not select the mock — the route substitutes `http://localhost:3100` and makes a real request (`app/api/verification/lean/route.ts:3-4`); the mock only returns when the fetch throws (`:37-40`). The security-relevant consequence is minor and in the safe direction: a developer reading CLAUDE.md may believe verification is always mocked-off until configured, when in local dev an unset var actually reaches a real verifier on the default port. It does not weaken the silent-pass disclosure (which is accurate in README:64). Below the mechanism-floor because no security property is *violated* by the imprecision — it is a documentation-accuracy defect with a bounded developer-confusion impact. Listed here because its falsity touches the same fail-open boundary (B3) as the endorsed disclosures.

**Recommendation:** Adopt the precise README:88 phrasing — "unset defaults the URL to `localhost:3100`; the mock is returned only when the verifier is unreachable" — in CLAUDE.md:76.

## Untested bypass candidates

None. The diff adds no guardrail, matcher, sanitizer, or filter, so move #11's bypass-enumeration requirement has no target. The security findings above concern the *absence* of authentication on surfaces the docs newly expose, not a bypassable guard.

## Endorsement Claims

- **Claim:** The diff discloses that when the verifier is unreachable, generated Lean code is reported as valid without being type-checked (the silent-pass fail-open is documented, not hidden).
  **Location:** `README.md:64`, `CLAUDE.md:76`
  **Evidence:** read-static
  **Verified:** The added README text states "generated Lean code is reported as valid without actually being type-checked"; the underlying fail-open mechanism is execution-confirmed by the bound fact-check (Claim 9b/4b, `{valid:true,mock:true}` on fetch failure) and the client dropping the `mock` flag (Claim 5).
  **Not verified:** whether every UI panel that shows verification status surfaces or obscures the mocked pass — fact-check Claim 5 scopes its check to `verifyLean` and the pipeline hook, not every display component.
  **route: code-fact-check**

- **Claim:** The diff discloses that the OpenRouter fallback path transmits prompts including the user's source material to OpenRouter.
  **Location:** `README.md:114`
  **Evidence:** read-static
  **Verified:** The added "Privacy note" states prompts (including source material) are sent to OpenRouter on this path; the provider-selection order and outbound request body carrying the prompts are execution-confirmed by the bound fact-check (Claim 15, executed in both replicates).
  **Not verified:** OpenRouter's server-side handling of the transmitted data — outside this repo and not established by the fact-check.
  **route: code-fact-check**

- **Claim:** In this codebase, API keys are read from server-side environment variables and there is no in-browser key-entry path.
  **Location:** `CLAUDE.md:75`, `app/lib/llm/callLlm.ts:112-113`
  **Evidence:** read-static
  **Verified:** `callLlm.ts:112-113` reads `process.env.ANTHROPIC_API_KEY` / `process.env.OPENROUTER_API_KEY`; the bound fact-check (Claim 2, Verified) found no `apiKey`/`API_KEY` reference under `app/components/` or `app/hooks/` outside tests.
  **Not verified:** how a particular Vercel project is actually configured, and whether the key value leaks via error responses on a specific route (the OpenRouter error path forwards `response.status` but the fact-check did not trace every route's error body for key echo).
  **route: code-fact-check**

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Deploy button invites public unauthenticated instance holding API key | High | B1 | `README.md:5,98-120` | High |
| 2 | Docs recommend publicly hosting the auth-less `/verify` build endpoint | Medium | B2 | `README.md:115`, `verifier/server.ts:86-118` | Medium |
| 3 | `CLAUDE.md:76` overstates unset→mock (fact-check Incorrect) | Low | B3 | `CLAUDE.md:76` | High |

## Overall Assessment

The diff improves two disclosures (silent-pass verifier, OpenRouter data egress) and those are worth keeping — they are the endorsement claims above. But by adding a one-click deploy button and "self-hosted single-tenant" framing, the documentation invites users to stand up a **public, unauthenticated** instance that holds their paid API key and exposes an auth-less `lake build` endpoint, while never warning that the deployed surface is world-reachable. The single most important thing to address is Finding 1: the "one trust boundary per deployment" language implies an isolation the code does not provide, and the deploy section should carry an explicit warning that the instance is unauthenticated and that anyone with the URL can spend the deployer's key. These are documentation fixes, not architectural ones — the code's lack of auth is pre-existing and out of this diff's scope, but the diff is what turns it from a localhost dev tool into a public deployment. No findings were escalated (no plaintext secrets, no TLS disablement, no injection in the diff itself); the endorsement claims are pending execution verification via code-fact-check, so this is "no findings within the code paths read beyond those listed; endorsement claims pending execution verification," not a categorical all-clear.
