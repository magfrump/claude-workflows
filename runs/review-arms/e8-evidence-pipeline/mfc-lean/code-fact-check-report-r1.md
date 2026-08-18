# Code Fact-Check Report

**Commit:** c95c9cb
**Repository:** /workspace/external/cc-review-eval/mfc-lean
**Scope:** `git diff d86d2dc...HEAD` (10 files — Lean-verifier availability/status-taxonomy change) plus README.md, docs/USER_GUIDE.md, docs/ARCHITECTURE.md, and docs/thoughts/feature-brainstorm.md passages referencing the changed verification route
**Checked:** 2026-08-17
**Total claims checked:** 24 (19 numbered, incl. 5 compound splits)
**Summary:** 16 verified, 4 mostly accurate, 8 stale, 0 incorrect, 1 unverifiable

Execution provenance note: every vitest invocation in this clone exits 1 due to a pre-run
`MISSING DEPENDENCY  Cannot find dependency 'jsdom'` resolution warning emitted before `RUN`
(visible at the top of each captured log); in all runs cited below the test summary itself
reports 100% of tests passed, and per-test `✓` lines are in the logs. Verdicts rest on the
per-test results, with the nonzero exit explained here rather than hidden. A concurrent
`next dev` for this same clone (port 4460, not started by this session) blocked launching a
dedicated dev server (Next 16 refuses a second server per project dir —
`evidence/r1-devserver-A.log`), so route-level claims were executed by invoking the real
route handler (`POST` from `app/api/verification/lean/route.ts`) under vitest node
environment against real local HTTP stubs and controlled `LEAN_VERIFIER_URL` values
(`evidence/r1-route-handler-exec.log`).

Executions (all cwd `/workspace/external/cc-review-eval/mfc-lean`, evidence dir `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/`):

- E1 — `npm test` — exit 1 (jsdom warning; 24 files / 225 tests passed) — 2026-08-18T06:22:35Z — `r1-vitest-full.log`
- E2 — `npx vitest run app/components/features/lean-display/LeanCodeDisplay.test.tsx app/components/panels/OutputPanel.test.tsx app/lib/utils/workspacePersistence.test.ts --reporter=verbose` — exit 1 (jsdom warning; 3 files / 55 tests passed) — 2026-08-18T06:22:50Z — `r1-vitest-targeted.log`
- E3 — `npx vitest run app/lib/formalization/__r1_scratch.test.ts --reporter=verbose` (scratch test, deleted after run) — exit 1 (jsdom warning; 6/6 passed) — 2026-08-18T06:23:43Z — `r1-vitest-scratch.log`
- E4 — `npx vitest run app/api/verification/lean/__r1_route_scratch.test.ts --reporter=verbose` (scratch test executing the real route handler with env control + node:http stubs on 127.0.0.1:4399, deleted after run) — exit 1 (jsdom warning; 5/5 passed) — 2026-08-18T06:25:11Z — `r1-route-handler-exec.log`
- (Blocked) `PORT=4321 npm run dev` + curl — server refused to start (concurrent dev server for same dir) — `r1-devserver-A.log`, `r1-route-A-not-configured.log`

---

## Claim 1: "The app includes a Dockerized Lean 4 verification service. When running, submitted Lean code is type-checked by a real Lean 4 installation."

**Location:** `README.md:60`
**Type:** Architectural / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the existence of the verifier service and its claimed real-Lean checking; does not establish the route's fallback behavior (that is Claim 1b).

The verifier service exists in-repo (paraphrased — no quote available because the claim is about directory/service structure: `verifier/` contains `Dockerfile`, `server.ts`, and `lean-project/` per `docs/ARCHITECTURE.md:208-218` and the files are present on disk). Whether submitted code is actually type-checked by a real Lean 4 installation is an executable guarantee requiring the Dockerized verifier, which is not available in this sandbox — execution required but blocked (no running Lean verifier; docker service not started per task constraints), so the verdict is capped at Unverifiable.

**Evidence:** `README.md:58-60`, `verifier/`, `docs/ARCHITECTURE.md:208-227`

---

## Claim 1b: "When the service is not running, the app falls back to a mock response."

**Location:** `README.md:60`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route's response when the verifier is unreachable; does not establish UI rendering of that response.

Split from Claim 1 (verdicts diverge). The mock fallback was removed in commit 5fe0dad. The route now returns an unavailability payload, not a mock pass:

```ts
// app/api/verification/lean/route.ts:53-56
} catch {
  // Network / timeout / DNS failure — verifier unreachable.
  return unavailableResponse("verifier-unreachable");
}
```

Executed: the real `POST` handler with `LEAN_VERIFIER_URL=http://127.0.0.1:4398` (nothing listening) returned `{ valid: false, unavailable: true, reason: "verifier-unreachable" }` — test "LEAN_VERIFIER_URL unreachable -> unavailable / verifier-unreachable" passed (E4, exit 1 per jsdom note, 5/5 tests passed, 2026-08-18T06:25:11Z, `r1-route-handler-exec.log`).

**Evidence:** `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log

---

## Claim 2: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment"

**Location:** `README.md:84`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the route reads the env var per-request; does not cover the default-value half of the sentence (Claim 2b).

```ts
// app/api/verification/lean/route.ts:26
const verifierUrl = process.env.LEAN_VERIFIER_URL;
```

Executed: setting `LEAN_VERIFIER_URL` to a live stub changed route behavior (verifier-error / passthrough cases), and unsetting it produced `verifier-not-configured` (E4, `r1-route-handler-exec.log`, 5/5 passed, 2026-08-18T06:25:11Z).

**Evidence:** `app/api/verification/lean/route.ts:26`, r1-route-handler-exec.log

---

## Claim 2b: "(defaults to `http://localhost:3100`)"

**Location:** `README.md:84`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claimed default URL when the env var is unset; does not cover other route behavior.

Split from Claim 2 (verdicts diverge). The default was removed in this change; the base commit had `process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100"` (paraphrased — no quote available because the code exists only at base commit d86d2dc, visible in `git diff d86d2dc...HEAD` for `route.ts`). At HEAD, unset means not-configured, no URL is contacted:

```ts
// app/api/verification/lean/route.ts:26-30
const verifierUrl = process.env.LEAN_VERIFIER_URL;
if (!verifierUrl) {
  // No verifier configured (typical on Vercel deploys without a separate verifier service).
  return unavailableResponse("verifier-not-configured");
}
```

Executed: with the env var deleted, the handler returned `{ valid: false, unavailable: true, reason: "verifier-not-configured" }` without any network attempt (E4, `r1-route-handler-exec.log`, test "LEAN_VERIFIER_URL unset -> ... (HTTP 200, no default URL contacted)" passed, 2026-08-18T06:25:11Z).

**Evidence:** `app/api/verification/lean/route.ts:26-30`, r1-route-handler-exec.log

---

## Claim 3: "The app continues to work without the verifier — the API route falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `README.md:92`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route's no-verifier response shape; does not establish whether the app "continues to work" in the broader UI sense.

The `{ valid: true, mock: true }` fallback is gone (see Claim 1b's quote of `route.ts:53-56`). Executed: unreachable-verifier and unset-env cases both returned `valid: false, unavailable: true` payloads, never `mock: true` (E4, `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z). The commit message documents this removal explicitly (paraphrased — no quote available because the source is the 5fe0dad commit message, quoted in Claim 18).

**Evidence:** `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log

---

## Claim 4: "No verifier configured (typical on Vercel deploys without a separate verifier service)."

**Location:** `app/api/verification/lean/route.ts:28`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch condition (env var unset → not-configured response); the parenthetical about Vercel deploy topology is deployment context, not checked.

```ts
// app/api/verification/lean/route.ts:26-30
const verifierUrl = process.env.LEAN_VERIFIER_URL;
if (!verifierUrl) {
  // No verifier configured (typical on Vercel deploys without a separate verifier service).
  return unavailableResponse("verifier-not-configured");
}
```

Executed with env var deleted: response `{ valid: false, unavailable: true, reason: "verifier-not-configured" }`, HTTP 200 (E4, `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z). Who observes this failure: `verifyLean` maps `unavailable` (`app/lib/formalization/api.ts:130`, quoted in Claim 12), `verifyResultToStatus` yields `"unavailable"`, and the UI renders the amber banner/badge (Claims 6, 8) — the failure is surfaced, not swallowed.

**Evidence:** `app/api/verification/lean/route.ts:26-30`, r1-route-handler-exec.log

---

## Claim 5: "Verifier reachable but errored — treat as unavailable rather than a failed proof, since the proof itself was never checked."

**Location:** `app/api/verification/lean/route.ts:46-47`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the non-OK-response branch mapping to the unavailable payload; does not establish behavior for OK responses with malformed JSON (unclaimed).

```ts
// app/api/verification/lean/route.ts:45-49
if (!res.ok) {
  // Verifier reachable but errored — treat as unavailable rather than a failed proof,
  // since the proof itself was never checked.
  return unavailableResponse("verifier-error", `HTTP ${res.status}`);
}
```

Executed against a real local `node:http` stub returning HTTP 500: response was `{ valid: false, unavailable: true, reason: "verifier-error", detail: "HTTP 500" }` — i.e. unavailable, not a failed proof (`valid:false` + `unavailable:true` maps to status `"unavailable"`, not `"invalid"`, per Claim 13's executed mapping) (E4, `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z). Observer chain is the same as Claim 4's.

**Evidence:** `app/api/verification/lean/route.ts:45-49`, r1-route-handler-exec.log

---

## Claim 6: "Network / timeout / DNS failure — verifier unreachable."

**Location:** `app/api/verification/lean/route.ts:54`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the catch-all branch returning verifier-unreachable; the network (connection-refused) case was executed, while the timeout and DNS variants are established statically as reaching the same catch.

```ts
// app/api/verification/lean/route.ts:53-56
} catch {
  // Network / timeout / DNS failure — verifier unreachable.
  return unavailableResponse("verifier-unreachable");
}
```

Executed for the network-failure case (connection refused on `127.0.0.1:4398`): `{ valid: false, unavailable: true, reason: "verifier-unreachable" }` (E4, `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z). The timeout case reaches the same catch via abort:

```ts
// app/api/verification/lean/route.ts:33-34
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
```

DNS failure likewise throws from `fetch` into the same bare `catch` (paraphrased — no quote available because the claim covers absence of any narrower catch clause; the `catch {` at `route.ts:53` binds no error and has no conditional rethrow).

**Evidence:** `app/api/verification/lean/route.ts:33-34`, `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log

---

## Claim 7: "Edit / Done toggle + Re-verify — outside scroll container so they stay visible"

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:108`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers DOM placement of the button group relative to the scrolling container; does not establish visual behavior across viewports (rendering not exercised).

The button group is an absolutely positioned sibling that precedes the scroll container rather than living inside it:

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:110
<div className="absolute right-4 top-4 z-30 flex items-center gap-2">
```

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:128
<div className="h-full overflow-auto px-8 py-6">
```

The `overflow-auto` container opens at line 128, after the button group's closing tag (paraphrased — no quote available because the claim is about element nesting order across a 20-line JSX block; the two quoted lines mark the sibling boundaries).

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.tsx:108-128`

---

## Claim 8: "Verifier offline banner — distinct from 'Verification Failed' so users don't read a missing verifier as a passing proof."

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:130-131`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `unavailable` status renders a dedicated banner distinct from the invalid-status error box and from any passing indicator; does not cover the badge component (Claim 10).

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:132-136
{verificationStatus === "unavailable" && (
  <div className="mb-4 rounded border border-amber-300 bg-amber-50 px-4 py-3">
    <h3 className="text-xs font-semibold uppercase tracking-wide text-amber-800">
      Verifier offline — proof not checked
    </h3>
```

The "Verification Failed"-style error box is a separate block gated on `verificationStatus === "invalid" && verificationErrors` (`app/components/features/lean-display/LeanCodeDisplay.tsx:146`). Executed: component tests "shows the verifier-offline banner when status is unavailable" and "shows Re-verify button when status is unavailable" passed, and the OutputPanel test asserted `Verified` is absent for unavailable status (E2, `r1-vitest-targeted.log`, 55/55 passed, 2026-08-18T06:22:50Z).

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.tsx:132-143`, `app/components/features/lean-display/LeanCodeDisplay.tsx:146`, r1-vitest-targeted.log

---

## Claim 9: "The Lean verifier service is not configured or unreachable, so this proof has not been checked."

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:134-135`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the banner text's characterization of when `unavailable` occurs; does not cover the env-var remedy sentence (Claim 9b).

The "proof has not been checked" half is correct for all three `unavailable` reasons. The cause list is incomplete: the route also emits `unavailable: true` when the verifier is configured, reachable, and returns an HTTP error —

```ts
// app/api/verification/lean/route.ts:45-48
if (!res.ok) {
  // Verifier reachable but errored — treat as unavailable rather than a failed proof,
  // since the proof itself was never checked.
  return unavailableResponse("verifier-error", `HTTP ${res.status}`);
}
```

— executed via the HTTP-500 stub case (E4, `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z). Precise version: "not configured, unreachable, or errored." Mechanism and conclusion are right; a cause case is missing.

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.tsx:132-138`, `app/api/verification/lean/route.ts:45-48`, r1-route-handler-exec.log

---

## Claim 9b: "Set the `LEAN_VERIFIER_URL` environment variable to a running verifier to enable checking."

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:135-136`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that setting the env var to a responsive verifier makes the route pass real verifier responses through; does not establish that a real Lean toolchain then checks the proof (that needs the Docker service — Claim 1).

Split from Claim 9 (verdicts diverge). Executed: with `LEAN_VERIFIER_URL` pointed at a live stub returning `{ valid: false, errors: "type mismatch at line 3" }`, the route passed the verifier response through unchanged with no `unavailable` flag (E4 test "verifier reachable, OK response -> passthrough", `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z), and with the var unset checking is off (`verifier-not-configured`, same log).

**Evidence:** `app/api/verification/lean/route.ts:26-30`, `app/api/verification/lean/route.ts:51-52`, r1-route-handler-exec.log

---

## Claim 10: "Lean verifier is offline or not configured. Set LEAN_VERIFIER_URL to enable checking." (badge tooltip)

**Location:** `app/components/ui/VerificationBadge.tsx:15`
**Type:** Error-handling / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tooltip's cause characterization and remedy for the `unavailable` badge; does not cover badge rendering for other statuses.

Same imprecision as Claim 9, not split because both halves' analysis is shared with Claims 9/9b: the badge renders for status `"unavailable"` —

```tsx
// app/components/ui/VerificationBadge.tsx:11-17
if (status === "unavailable") {
  return (
    <span
      className="ml-2 text-xs font-normal text-amber-700"
      title="Lean verifier is offline or not configured. Set LEAN_VERIFIER_URL to enable checking."
    >
      Verifier offline — not checked
```

— which also occurs when the verifier is online but errors (HTTP 500 → `verifier-error`, executed in E4, `r1-route-handler-exec.log`). The remedy half is Verified per Claim 9b's execution; the most informative verdict for the compound is Mostly accurate, carried by the incomplete cause list. Badge rendering for `unavailable` (and absence of a passing badge) executed via E2 OutputPanel test "shows 'Verifier offline' for unavailable status (not a passing badge)" (`r1-vitest-targeted.log`, 2026-08-18T06:22:50Z).

**Evidence:** `app/components/ui/VerificationBadge.tsx:11-19`, `app/api/verification/lean/route.ts:45-48`, r1-route-handler-exec.log, r1-vitest-targeted.log

---

## Claim 11: "Only 'invalid' carries verifier output; 'valid'/'unavailable' clear errors."

**Location:** `app/hooks/useFormalizationPipeline.ts:122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the error-string handling at the two call sites in this hook (post-retry-loop and `verifyWithDeps`); does not establish behavior of the `catch` path, which sets status "invalid" with the request-error message.

At the pipeline call site:

```ts
// app/hooks/useFormalizationPipeline.ts:121-126
const vStatus = verifyResultToStatus(result);
// Only "invalid" carries verifier output; "valid"/"unavailable" clear errors.
const vErrors = vStatus === "invalid" ? result.errors : "";
a.setVerificationStatus(vStatus);
if (vStatus !== "invalid") a.setVerificationErrors("");
a.onSessionUpdate?.({ verificationStatus: vStatus, verificationErrors: vErrors });
```

And in `verifyWithDeps`:

```ts
// app/hooks/useFormalizationPipeline.ts:142-144
const result = await verifyLean(fullCode);
const vStatus = verifyResultToStatus(result);
const vErrors = vStatus === "invalid" ? (result.errors || "Verification failed") : "";
```

Both sites propagate `result.errors` only for `"invalid"` and empty-string otherwise, matching the comment exactly.

**Evidence:** `app/hooks/useFormalizationPipeline.ts:121-126`, `app/hooks/useFormalizationPipeline.ts:139-147`

---

## Claim 12: "True when the verifier is not configured or could not be reached." (`VerifyLeanResult.unavailable`)

**Location:** `app/lib/formalization/api.ts:107`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when the client-side `unavailable` flag is true; does not cover the status mapping (Claim 13).

The flag mirrors the route's `unavailable` field:

```ts
// app/lib/formalization/api.ts:126-131
const data = await res.json();
return {
  valid: Boolean(data.valid),
  errors: (data.errors as string | undefined) ?? "",
  unavailable: Boolean(data.unavailable),
};
```

The route sets `unavailable: true` for three reasons — not-configured, unreachable, and `verifier-error` (reachable but HTTP-error), all executed in E4 (`r1-route-handler-exec.log`, 2026-08-18T06:25:11Z). The docstring names only the first two; precise version: "not configured, unreachable, or the verifier returned an error response." Client-side mapping of the flag executed in E3 test "maps unavailable flag from the API response" (`r1-vitest-scratch.log`, 6/6 passed, 2026-08-18T06:23:43Z).

**Evidence:** `app/lib/formalization/api.ts:104-109`, `app/lib/formalization/api.ts:126-131`, `app/api/verification/lean/route.ts:45-48`, r1-route-handler-exec.log, r1-vitest-scratch.log

---

## Claim 13: "`unavailable` wins over `valid` so a missing verifier never reads as a passing proof."

**Location:** `app/lib/formalization/api.ts:112-113`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the precedence inside `verifyResultToStatus`; does not establish that every caller routes through this helper (both call sites in `useFormalizationPipeline.ts` do — Claim 11 quotes them — but `leanRetryLoop` consumes the flags directly).

```ts
// app/lib/formalization/api.ts:115-118
export function verifyResultToStatus(result: { valid: boolean; unavailable?: boolean }): VerificationStatus {
  if (result.unavailable) return "unavailable";
  return result.valid ? "valid" : "invalid";
}
```

Executed: `{valid:true, unavailable:true}` → `"unavailable"`, `{valid:true}` → `"valid"`, `{valid:false}` → `"invalid"`, `{valid:false, unavailable:true}` → `"unavailable"` — all four assertions passed (E3, `r1-vitest-scratch.log`, 2026-08-18T06:23:43Z).

**Evidence:** `app/lib/formalization/api.ts:111-118`, r1-vitest-scratch.log

---

## Claim 14: "Generate Lean code from a semiformal proof and verify it, retrying up to MAX_LEAN_ATTEMPTS times on failure."

**Location:** `app/lib/formalization/leanRetryLoop.ts:30-33`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop's retry contract; does not cover cancellation behavior.

Retrying up to 3 attempts holds for invalid-proof failures:

```ts
// app/lib/formalization/leanRetryLoop.ts:3
export const MAX_LEAN_ATTEMPTS = 3;
```

```ts
// app/lib/formalization/leanRetryLoop.ts:43
for (let attempt = 1; attempt <= MAX_LEAN_ATTEMPTS; attempt++) {
```

But since this change, one failure class does not retry at all: verifier-unavailable exits on the first attempt (`leanRetryLoop.ts:73-77`, quoted in Claim 16; executed in E3 — exactly one generation call and one verification call, `r1-vitest-scratch.log`, 2026-08-18T06:23:43Z). Precise version: "retrying up to MAX_LEAN_ATTEMPTS times on verification failure; returns immediately without retrying if the verifier is unavailable." Mechanism and conclusion are right for the failure class the docstring plausibly means (failed proofs); a qualifier is missing.

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:3`, `app/lib/formalization/leanRetryLoop.ts:43`, `app/lib/formalization/leanRetryLoop.ts:73-77`, r1-vitest-scratch.log

---

## Claim 15: "True when the verifier was unavailable — the proof was generated but never checked." (`LeanRetryResult.unavailable`)

**Location:** `app/lib/formalization/leanRetryLoop.ts:26-27`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when the result field is set and what it signifies; does not cover consumers' handling of the field (Claim 11 covers the pipeline consumer).

The field is set on exactly one path — when `verifyLean` reports `unavailable` after code was generated:

```ts
// app/lib/formalization/leanRetryLoop.ts:71-77
const { valid, errors, unavailable } = await verifyLean(fullCode);

if (unavailable) {
  // No point retrying — the proof was never actually checked.
  onErrors("");
  return { valid: false, code: currentCode, errors: "", unavailable: true };
}
```

Executed: with generation stubbed to return code and verification stubbed unavailable, the loop returned `{ valid: false, code: <generated code>, errors: "", unavailable: true }` (E3, `r1-vitest-scratch.log`, 2026-08-18T06:23:43Z). No other `return` in the function sets `unavailable` (paraphrased — no quote available because the claim covers absence: grep of `leanRetryLoop.ts` finds `unavailable: true` only at line 76).

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:22-28`, `app/lib/formalization/leanRetryLoop.ts:71-77`, r1-vitest-scratch.log

---

## Claim 16: "No point retrying — the proof was never actually checked."

**Location:** `app/lib/formalization/leanRetryLoop.ts:74`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the unavailable branch returns without further generation or verification attempts; does not establish upstream re-verify UX.

The `return` at `leanRetryLoop.ts:76` (quoted in Claim 15) exits the attempt loop on the first unavailable result. Executed: fetch-call accounting showed exactly one call to `/api/formalization/lean` and one to `/api/verification/lean` — no retry attempts, and `onErrors("")` observed once (E3, test "returns immediately without retrying when verifier is unavailable", `r1-vitest-scratch.log`, 2026-08-18T06:23:43Z). Who observes this failure: the loop's caller receives `unavailable: true`, which `useFormalizationPipeline` maps to status `"unavailable"` via `verifyResultToStatus` (Claim 11), surfacing the banner/badge.

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:71-77`, r1-vitest-scratch.log

---

## Claim 17: "maps 'unavailable' to 'none' (transient verifier-state, not artifact-state)" (test description asserting `sanitizeVerificationStatus` behavior)

**Location:** `app/lib/utils/workspacePersistence.test.ts:32-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers persistence sanitization of the `unavailable` status; does not cover in-session (non-persisted) status handling.

```ts
// app/lib/utils/workspacePersistence.ts:34-37
export function sanitizeVerificationStatus(status: string): "none" | "valid" | "invalid" {
  if (status === "valid" || status === "invalid") return status;
  return "none";
}
```

`"unavailable"` falls through to `"none"` (it is not in the pass-through set), so it is never persisted as artifact state. Executed: the test passed in E2 (`✓ ... maps 'unavailable' to 'none' (transient verifier-state, not artifact-state)`, `r1-vitest-targeted.log`, 2026-08-18T06:22:50Z).

**Evidence:** `app/lib/utils/workspacePersistence.ts:34-37`, `app/lib/utils/workspacePersistence.test.ts:32-34`, r1-vitest-targeted.log

---

## Claim 18: "When the Lean verifier service is unset or unreachable, the route used to silently respond `{ valid: true, mock: true }` ... API route now distinguishes three failure modes (verifier-not-configured, verifier-unreachable, verifier-error) and responds with `{ valid: false, unavailable: true, reason: ... }`." (commit message)

**Location:** commit `5fe0dad` (message)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route-behavior halves of the commit message (old mock behavior, new three-reason taxonomy); does not re-verdict the UI halves, covered by Claims 8, 10, 16.

The old behavior is in the base version (paraphrased — no quote available because the removed code exists only in git history: `git diff d86d2dc...HEAD` shows the deleted lines `// Service unavailable — fall back to mock` / `return NextResponse.json({ valid: true, mock: true });`). The three reasons exist at HEAD:

```ts
// app/api/verification/lean/route.ts:5
type UnavailableReason = "verifier-not-configured" | "verifier-unreachable" | "verifier-error";
```

Executed: all three reasons were produced by the real handler under the corresponding conditions (unset env / connection refused / stub HTTP 500), each with `{ valid: false, unavailable: true, reason: ... }` (E4, `r1-route-handler-exec.log`, 5/5 passed, 2026-08-18T06:25:11Z).

**Evidence:** `app/api/verification/lean/route.ts:5-14`, r1-route-handler-exec.log

---

## Claim 19: "Remove unused unavailableReason field from VerifyLeanResult (no consumer)." (commit message)

**Location:** commit `c95c9cb` (message)
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the field existed at 5fe0dad, had no consumer, and is absent at HEAD; does not cover the helper-extraction half (whose existence Claim 13 establishes).

At the intermediate commit the field was declared and populated only within `api.ts`:

```ts
// app/lib/formalization/api.ts:109 @ 5fe0dad
unavailableReason?: string;
```

`git grep -n "unavailableReason" 5fe0dad` returns exactly two hits, both in `api.ts` (declaration line 109, population line 123) — no consumer anywhere (paraphrased — no quote available because the claim covers absence of other references; the grep produced no other matches). At HEAD, `git grep unavailableReason HEAD` returns zero hits (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `app/lib/formalization/api.ts:104-109`, git history (`git grep` at 5fe0dad and HEAD)

---

## Claim 20: "If the service is not running, a mock 'valid' response is returned."

**Location:** `docs/USER_GUIDE.md:203`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the not-running fallback; does not cover the surrounding badge-status list (whose "Verifying.../None" entries are unchanged, though the list also omits the new unavailable state).

Same mechanism as Claim 1b: the route now returns `{ valid: false, unavailable: true, reason: "verifier-unreachable" }` when the service is down (`route.ts:53-56`, quoted in Claim 1b; executed in E4, `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z). No mock "valid" response exists at HEAD (paraphrased — no quote available because the claim covers absence: `mock` does not appear in `route.ts`).

**Evidence:** `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log

---

## Claim 21: "The verifier runs on port 3100."

**Location:** `docs/USER_GUIDE.md:345`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Docker service's configured port; does not establish that the app contacts that port (it no longer does by default — Claim 2b).

```yaml
# docker-compose.yml:6-9
    ports:
      - "3100:3100"
    environment:
      - PORT=3100
```

(The identical sentence at `README.md:71` is covered by this verdict.)

**Evidence:** `docker-compose.yml:6-9`, `README.md:71`

---

## Claim 21b: "The app automatically detects whether it's available and falls back to mock responses when it's not."

**Location:** `docs/USER_GUIDE.md:345`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the detection-and-fallback sentence; does not re-verdict the port claim (21).

Split from Claim 21 (verdicts diverge). Unavailability is still detected, but the response is an explicit unavailable payload surfaced in the UI, not a mock: executed unreachable case returned `reason: "verifier-unreachable"` (E4, `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z), and the UI renders "Verifier offline — proof not checked" (Claim 8, E2). Additionally, with `LEAN_VERIFIER_URL` unset the app makes no availability probe at all — it short-circuits to not-configured (`route.ts:26-30`, quoted in Claim 2b).

**Evidence:** `app/api/verification/lean/route.ts:26-30`, `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log, r1-vitest-targeted.log

---

## Claim 22: "If verifier is unavailable: ← fallback mock { valid: true, mock: true }" (request-flow diagram, incl. "→ POST http://localhost:3100/verify")

**Location:** `docs/ARCHITECTURE.md:197-204`
**Type:** Error-handling / Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route's diagrammed fallback and hardcoded target URL; does not cover the verifier-internal structure sections (unchanged code, out of diff scope).

Both diagram facts are outdated: the mock fallback is replaced by the unavailable payload (executed, E4, `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z), and the route no longer targets `http://localhost:3100` by default — it uses `process.env.LEAN_VERIFIER_URL` with no default (`route.ts:26-30` and `route.ts:36`):

```ts
// app/api/verification/lean/route.ts:36
const res = await fetch(`${verifierUrl}/verify`, {
```

Both parts are Stale, so the compound is not split.

**Evidence:** `app/api/verification/lean/route.ts:26-36`, `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log

---

## Claim 23: "docker compose down         # Stop; app falls back to mock"

**Location:** `docs/ARCHITECTURE.md:234`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback annotation; the `docker compose down` command itself is not checked (Docker not exercised).

Same refuted mechanism as Claims 1b/20/22: stopping the verifier now yields `{ valid: false, unavailable: true, reason: "verifier-unreachable" }` (executed unreachable case, E4, `r1-route-handler-exec.log`, 2026-08-18T06:25:11Z), not a mock.

**Evidence:** `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log

---

## Claim 24: "Lean verifier is external and silently mocks success when unavailable"

**Location:** `docs/thoughts/feature-brainstorm.md:11`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "silently mocks success" gap entry; the "external" half remains true and does not diverge the verdict (most-severe part carries: the mock half).

This "known gap" was the very behavior removed by 5fe0dad. Unavailability is now explicit and surfaced (executed, E4 `r1-route-handler-exec.log` for the route; E2 `r1-vitest-targeted.log` for the UI banner/badge). The verifier remains an external service (`docker-compose.yml:2-5`, paraphrased — no quote available because the claim is about deployment structure: the verifier is a separate composed container). The gap entry should be removed or marked resolved.

**Evidence:** `app/api/verification/lean/route.ts:26-56`, r1-route-handler-exec.log, r1-vitest-targeted.log

---

## Claims Requiring Attention

### Stale
- **Claim 1b** (`README.md:60`): "falls back to a mock response" — route now returns `{valid:false, unavailable:true, reason}`; update wording.
- **Claim 2b** (`README.md:84`): default `http://localhost:3100` removed — unset env var now means verification disabled (verifier-not-configured), no default URL.
- **Claim 3** (`README.md:92`): mock `{ valid: true, mock: true }` fallback no longer exists.
- **Claim 20** (`docs/USER_GUIDE.md:203`): no mock "valid" response; an amber "Verifier offline" state is shown instead (badge list also lacks the new state).
- **Claim 21b** (`docs/USER_GUIDE.md:345`): "falls back to mock responses" outdated; also no probe happens when env var is unset.
- **Claim 22** (`docs/ARCHITECTURE.md:197-204`): request-flow diagram shows hardcoded localhost:3100 and mock fallback; both outdated.
- **Claim 23** (`docs/ARCHITECTURE.md:234`): "app falls back to mock" annotation outdated.
- **Claim 24** (`docs/thoughts/feature-brainstorm.md:11`): "silently mocks success" known-gap entry is resolved by this change.

### Mostly Accurate
- **Claim 9** (`app/components/features/lean-display/LeanCodeDisplay.tsx:134`): banner cause list omits the reachable-but-errored (`verifier-error`) case.
- **Claim 10** (`app/components/ui/VerificationBadge.tsx:15`): tooltip cause list omits the `verifier-error` case.
- **Claim 12** (`app/lib/formalization/api.ts:107`): `unavailable` docstring omits the `verifier-error` case.
- **Claim 14** (`app/lib/formalization/leanRetryLoop.ts:30-33`): docstring should note the loop does not retry when the verifier is unavailable.

### Unverifiable
- **Claim 1** (`README.md:60`): "type-checked by a real Lean 4 installation" — needs the Dockerized Lean verifier running; not available in this sandbox.
