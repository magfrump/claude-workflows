Commit: c95c9cb

# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/baseline-2026-08-06/wt-lean (meta-formalism-copilot)
**Scope:** branch diff d86d2dc..c95c9cb (full-branch changeset)
**Checked:** 2026-08-06
**Total claims checked:** 15
**Summary:** 12 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Note: `docs/reviews/hallucination-patterns.md` was not found in the worktree; proceeded normally. No fabricated-symbol patterns were confirmed in this run.

---

## Claim 1: "No verifier configured (typical on Vercel deploys without a separate verifier service)."

**Location:** `app/api/verification/lean/route.ts:28`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

The code returns the not-configured unavailable response exactly when `LEAN_VERIFIER_URL` is unset:

```ts
// app/api/verification/lean/route.ts:26-30
const verifierUrl = process.env.LEAN_VERIFIER_URL;
if (!verifierUrl) {
  // No verifier configured (typical on Vercel deploys without a separate verifier service).
  return unavailableResponse("verifier-not-configured");
}
```

`unavailableResponse("verifier-not-configured")` yields `{ valid:false, unavailable:true, reason:"verifier-not-configured" }` (`route.ts:7-14`). The "typical on Vercel" portion is deployment-environment rationale (not codebase-checkable) and is not verdicted. The checkable behavioral part matches.

**Evidence:** `app/api/verification/lean/route.ts:7-14`, `app/api/verification/lean/route.ts:26-30`

---

## Claim 2: "Verifier reachable but errored — treat as unavailable rather than a failed proof, since the proof itself was never checked."

**Location:** `app/api/verification/lean/route.ts:46-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

On a non-2xx response the route returns an unavailable response (not a `valid:false` proof failure), carrying the HTTP status as detail:

```ts
// app/api/verification/lean/route.ts:45-49
if (!res.ok) {
  // Verifier reachable but errored — treat as unavailable rather than a failed proof,
  // since the proof itself was never checked.
  return unavailableResponse("verifier-error", `HTTP ${res.status}`);
}
```

This is a genuine behavior change from the base revision, which returned the parsed body with the upstream status (`return NextResponse.json(data, { status: res.status })`). The comment accurately describes the new behavior. The upstream error body is now dropped (only `HTTP <status>` is preserved as `detail`), but no comment claims the body is preserved, so there is no doc/code mismatch here.

**Evidence:** `app/api/verification/lean/route.ts:45-49`, `app/api/verification/lean/route.ts:7-14`

---

## Claim 3: "Network / timeout / DNS failure — verifier unreachable."

**Location:** `app/api/verification/lean/route.ts:54`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The `catch` returns the unreachable response:

```ts
// app/api/verification/lean/route.ts:53-56
} catch {
  // Network / timeout / DNS failure — verifier unreachable.
  return unavailableResponse("verifier-unreachable");
}
```

The listed causes (network error, abort/timeout via `controller.abort()`, DNS failure) all do reach this block. However the `try` also contains `const data = await res.json()` for a *successful* (2xx) response (`route.ts:51`); a 2xx response with a malformed JSON body would throw and be caught here, labeling a reachable-but-malformed verifier as "verifier-unreachable". The comment's enumeration is directionally correct but omits that one non-transport case also lands here.

**Evidence:** `app/api/verification/lean/route.ts:51`, `app/api/verification/lean/route.ts:53-56`

---

## Claim 4: "True when the verifier is not configured or could not be reached." (`unavailable` field)

**Location:** `app/lib/formalization/api.ts:107`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

```ts
// app/lib/formalization/api.ts:104-109
export type VerifyLeanResult = {
  valid: boolean;
  errors: string;
  /** True when the verifier is not configured or could not be reached. */
  unavailable: boolean;
};
```

`unavailable` is derived from the route's `unavailable` flag (`api.ts:130`: `unavailable: Boolean(data.unavailable)`). The route sets `unavailable:true` in three cases: not-configured, unreachable, **and** verifier-error (a reachable verifier that returned a non-2xx status — `route.ts:48`). The docstring covers "not configured" and "could not be reached" but omits the reachable-but-errored (HTTP error) case, so the doc is narrower than the actual flag.

**Evidence:** `app/lib/formalization/api.ts:104-109`, `app/lib/formalization/api.ts:120-132`, `app/api/verification/lean/route.ts:45-49`

---

## Claim 5: "`unavailable` wins over `valid` so a missing verifier never reads as a passing proof."

**Location:** `app/lib/formalization/api.ts:112-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
// app/lib/formalization/api.ts:115-118
export function verifyResultToStatus(result: { valid: boolean; unavailable?: boolean }): VerificationStatus {
  if (result.unavailable) return "unavailable";
  return result.valid ? "valid" : "invalid";
}
```

`unavailable` is checked first and short-circuits before `valid` is consulted, so a result with `unavailable:true` (regardless of `valid`) returns `"unavailable"`, never `"valid"`.

**Evidence:** `app/lib/formalization/api.ts:115-118`

---

## Claim 6: "Only \"invalid\" carries verifier output; \"valid\"/\"unavailable\" clear errors."

**Location:** `app/hooks/useFormalizationPipeline.ts:122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
// app/hooks/useFormalizationPipeline.ts:121-126
const vStatus = verifyResultToStatus(result);
// Only "invalid" carries verifier output; "valid"/"unavailable" clear errors.
const vErrors = vStatus === "invalid" ? result.errors : "";
a.setVerificationStatus(vStatus);
if (vStatus !== "invalid") a.setVerificationErrors("");
a.onSessionUpdate?.({ verificationStatus: vStatus, verificationErrors: vErrors });
```

`vErrors` is `result.errors` only when status is `"invalid"`, else `""`; and `setVerificationErrors("")` runs whenever status is not `"invalid"`. The sibling `verifyWithDeps` follows the same pattern (`useFormalizationPipeline.ts:143-144`).

**Evidence:** `app/hooks/useFormalizationPipeline.ts:121-126`, `app/hooks/useFormalizationPipeline.ts:142-147`

---

## Claim 7: "True when the verifier was unavailable — the proof was generated but never checked." (`unavailable` on `LeanRetryResult`)

**Location:** `app/lib/formalization/leanRetryLoop.ts:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The optional `unavailable` field is set to `true` only on the unavailable early-return, where `currentCode` (the generated proof) is returned with `valid:false`:

```ts
// app/lib/formalization/leanRetryLoop.ts:71-77
const { valid, errors, unavailable } = await verifyLean(fullCode);

if (unavailable) {
  // No point retrying — the proof was never actually checked.
  onErrors("");
  return { valid: false, code: currentCode, errors: "", unavailable: true };
}
```

Code was generated by `generateLean`/`generateLeanStreaming` earlier in the loop (`leanRetryLoop.ts:59-62`), matching "generated but never checked."

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:22-28`, `app/lib/formalization/leanRetryLoop.ts:59-77`

---

## Claim 8: "No point retrying — the proof was never actually checked."

**Location:** `app/lib/formalization/leanRetryLoop.ts:74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

On `unavailable` the function returns immediately rather than continuing the `for` loop, so no further attempts are made:

```ts
// app/lib/formalization/leanRetryLoop.ts:73-77
if (unavailable) {
  // No point retrying — the proof was never actually checked.
  onErrors("");
  return { valid: false, code: currentCode, errors: "", unavailable: true };
}
```

The `return` exits the retry loop (`for attempt ... MAX_LEAN_ATTEMPTS`), confirming "no retry."

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:43-77`

---

## Claim 9: "Strip transient \"verifying\" status back to \"none\""

**Location:** `app/lib/utils/workspacePersistence.ts:33`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

```ts
// app/lib/utils/workspacePersistence.ts:33-37
/** Strip transient "verifying" status back to "none" */
export function sanitizeVerificationStatus(status: string): "none" | "valid" | "invalid" {
  if (status === "valid" || status === "invalid") return status;
  return "none";
}
```

The function is a whitelist: it preserves only `"valid"`/`"invalid"` and collapses everything else to `"none"`. With `"unavailable"` newly added to `VerificationStatus` (`app/lib/types/session.ts:1`), this function now also strips `"unavailable"` to `"none"` — a behavior the diff's own test asserts (`workspacePersistence.test.ts`, "maps 'unavailable' to 'none'"). The docstring names only `"verifying"`, so it understates what the function now collapses. The return-type annotation `"none" | "valid" | "invalid"` remains accurate.

**Evidence:** `app/lib/utils/workspacePersistence.ts:33-37`, `app/lib/types/session.ts:1`, `app/lib/utils/workspacePersistence.test.ts:32-34`

---

## Claim 10: "Verifier offline banner — distinct from \"Verification Failed\" so users don't read a missing verifier as a passing proof."

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:130-131`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The unavailable banner is a separate amber block gated on `verificationStatus === "unavailable"`, distinct from the red invalid block gated on `verificationStatus === "invalid"`:

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:132-143
{verificationStatus === "unavailable" && (
  <div className="mb-4 rounded border border-amber-300 bg-amber-50 px-4 py-3">
    <h3 ...>Verifier offline — proof not checked</h3>
    ...
  </div>
)}
```

The "Verification Failed" wording lives only in the invalid path (`VerificationBadge.tsx:21`), and the unavailable branch renders neither a passing "Verified" badge nor a failure label — it renders its own amber "Verifier offline" copy.

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.tsx:132-143`, `app/components/ui/VerificationBadge.tsx:8-21`

---

## Claim 11 (test): "shows the verifier-offline banner when status is unavailable" → expects text 'Verifier offline — proof not checked'

**Location:** `app/components/features/lean-display/LeanCodeDisplay.test.tsx:64-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The asserted string matches the component's `<h3>` copy verbatim:

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:134-136
<h3 ...>
  Verifier offline — proof not checked
</h3>
```

Rendering with `verificationStatus="unavailable"` and a non-empty `code` (from `defaultProps`) satisfies the `code && ... verificationStatus === "unavailable"` gates, so the banner renders.

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.test.tsx:64-72`, `app/components/features/lean-display/LeanCodeDisplay.tsx:132-143`

---

## Claim 12 (test): "shows Re-verify button when status is unavailable" → expects 'Re-verify ↺'

**Location:** `app/components/features/lean-display/LeanCodeDisplay.test.tsx:74-82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The Re-verify button's render condition now includes `"unavailable"`:

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:111
{(leanEdited || verificationStatus === "invalid" || verificationStatus === "unavailable") && editMode === "rendered" && (
  <button ...>Re-verify ↺</button>
)}
```

`editMode` defaults to `"rendered"` (`LeanCodeDisplay.tsx:27`) and `code` is non-empty via `defaultProps`, so the button label `Re-verify ↺` renders for `"unavailable"`.

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.test.tsx:74-82`, `app/components/features/lean-display/LeanCodeDisplay.tsx:109-118`

---

## Claim 13 (test): "shows \"Verifier offline\" for unavailable status (not a passing badge)" — asserts /Verifier offline/ present and 'Verified' absent

**Location:** `app/components/panels/OutputPanel.test.tsx:112-116`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`OutputPanel` renders `<VerificationBadge status={verificationStatus} />` (`OutputPanel.tsx:124`) inside the Lean4 section, which renders because `leanCode="code"` is truthy (`OutputPanel.tsx:117`). For `"unavailable"`, the badge renders "Verifier offline — not checked" and the "Verified" text is produced only for `status === "valid"`:

```tsx
// app/components/ui/VerificationBadge.tsx:8-20
if (status === "valid") { return <span ...>Verified</span>; }
if (status === "unavailable") { return (<span ...>Verifier offline — not checked</span>); }
```

So `/Verifier offline/` matches and `"Verified"` is absent, as asserted.

**Evidence:** `app/components/panels/OutputPanel.test.tsx:112-116`, `app/components/panels/OutputPanel.tsx:117-124`, `app/components/ui/VerificationBadge.tsx:8-21`

---

## Claim 14 (test): "maps 'unavailable' to 'none' (transient verifier-state, not artifact-state)"

**Location:** `app/lib/utils/workspacePersistence.test.ts:32-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`sanitizeVerificationStatus` returns `status` only for `"valid"`/`"invalid"`, else `"none"`; `"unavailable"` is not in the whitelist, so it collapses to `"none"`:

```ts
// app/lib/utils/workspacePersistence.ts:34-37
export function sanitizeVerificationStatus(status: string): "none" | "valid" | "invalid" {
  if (status === "valid" || status === "invalid") return status;
  return "none";
}
```

The test's expectation matches the implementation.

**Evidence:** `app/lib/utils/workspacePersistence.test.ts:32-34`, `app/lib/utils/workspacePersistence.ts:34-37`

---

## Claim 15: badge tooltip "Lean verifier is offline or not configured. Set LEAN_VERIFIER_URL to enable checking."

**Location:** `app/components/ui/VerificationBadge.tsx:15`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

The tooltip instructs setting `LEAN_VERIFIER_URL`; the route indeed reads that env var and returns not-configured when it is unset:

```ts
// app/api/verification/lean/route.ts:26-30
const verifierUrl = process.env.LEAN_VERIFIER_URL;
if (!verifierUrl) {
  return unavailableResponse("verifier-not-configured");
}
```

The env-var name in the UI copy matches the code that consumes it (also matches the banner copy in `LeanCodeDisplay.tsx:139`).

**Evidence:** `app/components/ui/VerificationBadge.tsx:11-19`, `app/api/verification/lean/route.ts:26-30`

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 3** (`app/api/verification/lean/route.ts:54`): catch-block comment lists only network/timeout/DNS causes, but a malformed JSON body on a 2xx response also lands here and is labeled "verifier-unreachable".
- **Claim 4** (`app/lib/formalization/api.ts:107`): `unavailable` docstring says "not configured or could not be reached" but omits the reachable-but-errored (HTTP non-2xx) case that also sets `unavailable:true`.
- **Claim 9** (`app/lib/utils/workspacePersistence.ts:33`): docstring names only "verifying" but the function now also strips the newly-added "unavailable" status to "none".

### Unverifiable
- (none)
