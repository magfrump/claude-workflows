# Code Fact-Check Report

**Commit:** c95c9cb
**Repository:** /workspace/external/cc-review-eval/mfc-lean
**Scope:** Files changed in `git diff d86d2dc...HEAD` (Lean-verifier error-handling change: `app/api/verification/lean/route.ts`, `app/components/features/lean-display/LeanCodeDisplay.{tsx,test.tsx}`, `app/components/panels/OutputPanel.test.tsx`, `app/components/ui/VerificationBadge.tsx`, `app/hooks/useFormalizationPipeline.ts`, `app/lib/formalization/{api.ts,leanRetryLoop.ts}`, `app/lib/types/session.ts`, `app/lib/utils/workspacePersistence.test.ts`) plus docs referencing this code (`README.md`, `docs/ARCHITECTURE.md`, `docs/USER_GUIDE.md`).
**Checked:** 2026-08-18
**Total claims checked:** 17 (21 atomic verdicts after compound-claim splits)
**Summary:** 12 verified, 4 mostly accurate, 5 stale, 0 incorrect, 0 unverifiable

Execution environment note: all executed verdicts ran in the review sandbox with the repo's installed `node_modules` (vitest 4.1.5, Next.js dev server on port 4460, Node 20.20.2). No live Lean verifier was available; route behavior was exercised against unset/unreachable/stubbed endpoints, which suffices for every executable claim in scope. Evidence files live under `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/` (prefix `r2-`).

---

## Claim 1: "No verifier configured (typical on Vercel deploys without a separate verifier service)."

**Location:** `app/api/verification/lean/route.ts:28`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unset-`LEAN_VERIFIER_URL` branch returning a not-configured unavailable response before any fetch; does not establish anything about actual Vercel deployment environments (the "typical on Vercel" aside is deployment context, not checkable here).

The guarded branch fires when the env var is missing:

```ts
// app/api/verification/lean/route.ts:26-30
const verifierUrl = process.env.LEAN_VERIFIER_URL;
if (!verifierUrl) {
  // No verifier configured (typical on Vercel deploys without a separate verifier service).
  return unavailableResponse("verifier-not-configured");
}
```

Executed: with the dev server started via `env -u LEAN_VERIFIER_URL npx next dev -p 4460` (cwd `/workspace/external/cc-review-eval/mfc-lean`), `curl -s -X POST http://localhost:4460/api/verification/lean ... -d '{"leanCode":"theorem t : True := trivial"}'` returned `{"valid":false,"unavailable":true,"reason":"verifier-not-configured"}` with HTTP 200, curl exit 0, at 2026-08-18T06:25:36Z (`r2-route-no-env.txt`, Case E). A detector stub listening on `127.0.0.1:3100` during the request logged zero incoming requests, confirming no fetch is attempted when the var is unset.

**Evidence:** `app/api/verification/lean/route.ts:26-30`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-no-env.txt`

---

## Claim 2: "Verifier reachable but errored — treat as unavailable rather than a failed proof, since the proof itself was never checked."

**Location:** `app/api/verification/lean/route.ts:45-48`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the non-OK-HTTP-response branch of the route; does not establish how the client UI renders the `verifier-error` reason (the reason string is collapsed into the single `unavailable` status client-side — see Claims 6, 7, 9).

The branch returns the unavailable shape instead of a failed-proof result:

```ts
// app/api/verification/lean/route.ts:45-49
if (!res.ok) {
  // Verifier reachable but errored — treat as unavailable rather than a failed proof,
  // since the proof itself was never checked.
  return unavailableResponse("verifier-error", `HTTP ${res.status}`);
}
```

Who observes the failure: the route converts it to `{valid:false, unavailable:true, reason:"verifier-error", detail:"HTTP <status>"}`; `verifyLean` (`app/lib/formalization/api.ts:123-131`) carries `unavailable` to callers, and `verifyResultToStatus` maps it to the `"unavailable"` status rendered as an amber banner/badge, not "Verification Failed" (see Claims 5, 10). Executed: with the dev server running with `LEAN_VERIFIER_URL=http://127.0.0.1:4461` and a stub on 4461 returning HTTP 500, the route returned `{"valid":false,"unavailable":true,"reason":"verifier-error","detail":"HTTP 500"}`, HTTP 200, curl exit 0, at 2026-08-18T06:24:28Z (`r2-route-stub-cases.txt`, Case B).

**Evidence:** `app/api/verification/lean/route.ts:45-49`, `app/lib/formalization/api.ts:123-131`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-stub-cases.txt`

---

## Claim 3: "Network / timeout / DNS failure — verifier unreachable."

**Location:** `app/api/verification/lean/route.ts:53-55`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the catch block returns and that connection-refused failures land there; does not establish behavior for the timeout (35s abort) or DNS sub-cases specifically, which were not separately exercised.

The catch block returns the unreachable reason:

```ts
// app/api/verification/lean/route.ts:52-55
} catch {
  // Network / timeout / DNS failure — verifier unreachable.
  return unavailableResponse("verifier-unreachable");
}
```

Executed: with `LEAN_VERIFIER_URL=http://127.0.0.1:4461` and nothing listening on 4461, the route returned `{"valid":false,"unavailable":true,"reason":"verifier-unreachable"}`, HTTP 200, curl exit 0, at 2026-08-18T06:23:56Z (`r2-route-with-env.txt`, Case A). The comment is imprecise about the branch's full coverage: `const data = await res.json();` sits inside the same `try` after the OK check (`app/api/verification/lean/route.ts:51`), so a reachable verifier returning a 2xx response with malformed JSON would also land in this catch and be labeled `verifier-unreachable` — a case that is neither network, timeout, nor DNS. The mechanism and conclusion are right for the failure classes the comment names; the label is merely broader than stated.

**Evidence:** `app/api/verification/lean/route.ts:32-55`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-with-env.txt`

---

## Claim 4: "Edit / Done toggle + Re-verify — outside scroll container so they stay visible"

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:108`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the DOM placement of the button group relative to the scrolling content div; does not establish actual rendered stacking/visibility across browsers (no visual test run).

The button group is an absolutely positioned sibling of the scroll container, not a child of it:

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:110-111
{code && (
  <div className="absolute right-4 top-4 z-30 flex items-center gap-2">
```

The scrolling content is a separate sibling div (`app/components/features/lean-display/LeanCodeDisplay.tsx:128`: `<div className="h-full overflow-auto px-8 py-6">`), so scrolling it does not move the buttons. The Re-verify button's visibility condition now includes the new status (`LeanCodeDisplay.tsx:112`: `(leanEdited || verificationStatus === "invalid" || verificationStatus === "unavailable") && editMode === "rendered"`), and the existing test "shows Re-verify button when status is unavailable" passed in the executed suite (see Claim 5's run).

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.tsx:105-128`

---

## Claim 5: "Verifier offline banner — distinct from 'Verification Failed' so users don't read a missing verifier as a passing proof."

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:129-130`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rendering of the amber banner for `"unavailable"` status as distinct from the red invalid-status UI and the green "Verified" badge; does not establish that every upstream failure reason reaches the `"unavailable"` status (that is the route/mapping layer, Claims 1-3, 10).

The banner renders only for the `"unavailable"` status:

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:131-135
{verificationStatus === "unavailable" && (
  <div className="mb-4 rounded border border-amber-300 bg-amber-50 px-4 py-3">
    <h3 className="text-xs font-semibold uppercase tracking-wide text-amber-800">
      Verifier offline — proof not checked
    </h3>
```

The "Verification Failed" red panel is a separate branch gated on `"invalid"` (`LeanCodeDisplay.tsx:146`: `{verificationStatus === "invalid" && verificationErrors && (`), and the badge renders "Verified" only for `"valid"` (`app/components/ui/VerificationBadge.tsx:8-10`). Who observes the failure: the end user, via this banner and the amber badge — never the green "Verified" badge. Executed: `npx vitest run` over `LeanCodeDisplay.test.tsx`, `OutputPanel.test.tsx`, `workspacePersistence.test.ts` (cwd `/workspace/external/cc-review-eval/mfc-lean`) — 3 files, 55 tests, all passed, exit 0, at 2026-08-18T06:22:42Z, including "shows the verifier-offline banner when status is unavailable" and OutputPanel's 'shows "Verifier offline" for unavailable status (not a passing badge)' which additionally asserts `queryByText('Verified')` is absent (`app/components/panels/OutputPanel.test.tsx:112-116`).

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.tsx:131-145`, `app/components/features/lean-display/LeanCodeDisplay.tsx:146`, `app/components/ui/VerificationBadge.tsx:8-10`, `app/components/panels/OutputPanel.test.tsx:112-116`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-vitest-existing-tests.txt`

---

## Claim 6: "The Lean verifier service is not configured or unreachable, so this proof has not been checked. Set the LEAN_VERIFIER_URL environment variable to a running verifier to enable checking."

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:137-140`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the causes the banner attributes the `"unavailable"` status to, and the claimed remedy (`LEAN_VERIFIER_URL`); does not establish that setting the variable to a *broken* verifier enables checking.

The remedy is accurate: the route reads exactly this variable and only fetches when it is set (`app/api/verification/lean/route.ts:26`: `const verifierUrl = process.env.LEAN_VERIFIER_URL;`). Executed: with the variable unset the route short-circuits to `verifier-not-configured` (Case E, `r2-route-no-env.txt`, 2026-08-18T06:25:36Z); with it set to `http://127.0.0.1:4461` and a stub answering 200 `{valid:false, errors:"stub: unsolved goals"}`, the route passed the stub's verdict through verbatim (`{"valid":false,"errors":"stub: unsolved goals"}`, Case C, `r2-route-stub-cases.txt`, 2026-08-18T06:24:28Z), proving the env URL is actually used. The imprecision: the banner also renders when the verifier is reachable but errored — the route returns `unavailable: true` with `reason: "verifier-error"` for non-OK responses (`app/api/verification/lean/route.ts:45-49`, executed Case B), and the client collapses all three reasons into the one `"unavailable"` status (`app/lib/formalization/api.ts:115-118`), so "not configured or unreachable" omits the reachable-but-errored cause. "This proof has not been checked" remains true in all three cases.

**Evidence:** `app/api/verification/lean/route.ts:26-49`, `app/lib/formalization/api.ts:115-118`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-no-env.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-stub-cases.txt`

---

## Claim 7: "Lean verifier is offline or not configured. Set LEAN_VERIFIER_URL to enable checking." (badge tooltip)

**Location:** `app/components/ui/VerificationBadge.tsx:15`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what conditions produce the tooltip-bearing badge and whether the named env var is the remedy; does not establish tooltip rendering behavior (title attribute display is browser-native, not tested).

The badge branch is gated on the `"unavailable"` status:

```tsx
// app/components/ui/VerificationBadge.tsx:11-17
if (status === "unavailable") {
  return (
    <span
      className="ml-2 text-xs font-normal text-amber-700"
      title="Lean verifier is offline or not configured. Set LEAN_VERIFIER_URL to enable checking."
    >
```

Same finding as Claim 6, on the same executed evidence: the env-var remedy is verified (Cases C and E in `r2-route-stub-cases.txt` / `r2-route-no-env.txt`), but "offline or not configured" omits the third cause — a reachable verifier that returned an HTTP error also yields status `"unavailable"` (Case B: `{"reason":"verifier-error","detail":"HTTP 500"}`). The OutputPanel test asserting this badge appears (and "Verified" does not) for `"unavailable"` passed in the executed suite (`r2-vitest-existing-tests.txt`, exit 0, 2026-08-18T06:22:42Z).

**Evidence:** `app/components/ui/VerificationBadge.tsx:11-17`, `app/api/verification/lean/route.ts:45-49`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-stub-cases.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-vitest-existing-tests.txt`

---

## Claim 8: "Only 'invalid' carries verifier output; 'valid'/'unavailable' clear errors."

**Location:** `app/hooks/useFormalizationPipeline.ts:122`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two status-to-errors mappings inside this hook (`runLean` result handling and `verifyWithDeps`); does not establish that other writers of `verificationErrors` elsewhere in the app follow the same rule.

Both call sites gate errors on `"invalid"` and clear otherwise:

```ts
// app/hooks/useFormalizationPipeline.ts:121-126
const vStatus = verifyResultToStatus(result);
// Only "invalid" carries verifier output; "valid"/"unavailable" clear errors.
const vErrors = vStatus === "invalid" ? result.errors : "";
a.setVerificationStatus(vStatus);
if (vStatus !== "invalid") a.setVerificationErrors("");
a.onSessionUpdate?.({ verificationStatus: vStatus, verificationErrors: vErrors });
```

The second site behaves identically (`app/hooks/useFormalizationPipeline.ts:142-144`: `const vStatus = verifyResultToStatus(result); const vErrors = vStatus === "invalid" ? (result.errors || "Verification failed") : "";`). One subtlety, consistent with the claim: in the first site, when `vStatus === "invalid"` the local error state is not re-set (only `onSessionUpdate` receives `result.errors`) — but that path is downstream of `leanRetryLoop`, whose `onErrors` callback already streamed errors into state (paraphrased — no quote available because the invariant is inferred from the `leanRetryLoop` callback wiring at `app/hooks/useFormalizationPipeline.ts:110-118` plus `app/lib/formalization/leanRetryLoop.ts:84-96` acting together).

**Evidence:** `app/hooks/useFormalizationPipeline.ts:121-126`, `app/hooks/useFormalizationPipeline.ts:139-147`, `app/lib/formalization/leanRetryLoop.ts:68-96`

---

## Claim 9: "True when the verifier is not configured or could not be reached." (doc on `VerifyLeanResult.unavailable`)

**Location:** `app/lib/formalization/api.ts:108`
**Type:** Invariant / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conditions under which the route sets `unavailable: true` and `verifyLean` propagates it; does not establish behavior when `/api/verification/lean` itself returns a non-JSON error (in that case `verifyLean`'s own `res.json()` throws to its caller).

`verifyLean` propagates the flag from the route response:

```ts
// app/lib/formalization/api.ts:126-131
return {
  valid: Boolean(data.valid),
  errors: (data.errors as string | undefined) ?? "",
  unavailable: Boolean(data.unavailable),
};
```

The route sets `unavailable: true` in three cases, not two: not configured (Case E), unreachable (Case A), and reachable-but-errored — `app/api/verification/lean/route.ts:45-49` returns `unavailableResponse("verifier-error", ...)` for any non-OK verifier response, confirmed by execution (Case B: stub returning HTTP 500 produced `{"valid":false,"unavailable":true,"reason":"verifier-error","detail":"HTTP 500"}`, `r2-route-stub-cases.txt`, 2026-08-18T06:24:28Z). The doc's two named causes are real but the list is incomplete; a reader treating `unavailable` as strictly "not configured or unreachable" would misattribute verifier-error cases. Mechanism and conclusion ("proof was never checked") both hold in all three cases.

**Evidence:** `app/lib/formalization/api.ts:104-131`, `app/api/verification/lean/route.ts:8-16`, `app/api/verification/lean/route.ts:45-49`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-stub-cases.txt`

---

## Claim 10: "Map a verification result's `valid`/`unavailable` flags to a `VerificationStatus`. `unavailable` wins over `valid` so a missing verifier never reads as a passing proof."

**Location:** `app/lib/formalization/api.ts:111-114`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the precedence logic of `verifyResultToStatus` for all four flag combinations; does not establish that every code path constructing a status goes through this function (both hook call sites do — Claim 8 — but the route's JSON is also consumed raw by `leanRetryLoop`).

The implementation checks `unavailable` first:

```ts
// app/lib/formalization/api.ts:115-118
export function verifyResultToStatus(result: { valid: boolean; unavailable?: boolean }): VerificationStatus {
  if (result.unavailable) return "unavailable";
  return result.valid ? "valid" : "invalid";
}
```

Executed: a scratch vitest file (removed after the run) asserted all four combinations — `{valid:true, unavailable:true}` → `"unavailable"`, `{valid:false, unavailable:true}` → `"unavailable"`, `{valid:true, unavailable:false}` → `"valid"`, `{valid:false}` → `"invalid"`. Command `npx vitest run app/lib/formalization/factcheck-r2.scratch.test.ts`, cwd `/workspace/external/cc-review-eval/mfc-lean`, 5/5 tests passed, exit 0, at 2026-08-18T06:23:06Z (`r2-vitest-scratch-unit.txt`; test source preserved inside the log's context is summarized here — the four assertions above are quoted from the scratch file as written).

**Evidence:** `app/lib/formalization/api.ts:115-118`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-vitest-scratch-unit.txt`

---

## Claim 11: "True when the verifier was unavailable — the proof was generated but never checked." (doc on `LeanRetryResult.unavailable`)

**Location:** `app/lib/formalization/leanRetryLoop.ts:26`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when `leanRetryLoop` sets `unavailable: true` on its result and that generated code is still returned; inherits Claim 9's caveat that "unavailable" includes the verifier-error case, but this doc's wording ("was unavailable") does not enumerate causes, so it stays accurate.

The flag is set exactly on the unavailable short-circuit, with the generated code preserved:

```ts
// app/lib/formalization/leanRetryLoop.ts:73-77
if (unavailable) {
  // No point retrying — the proof was never actually checked.
  onErrors("");
  return { valid: false, code: currentCode, errors: "", unavailable: true };
}
```

`currentCode` at that point holds the freshly generated Lean code (`app/lib/formalization/leanRetryLoop.ts:59-62`: `currentCode = onToken ? await generateLeanStreaming(...args, onToken) : await generateLean(...args);`), so "generated but never checked" matches. Executed: the scratch test mocked `verifyLean` to return `{valid:false, errors:"", unavailable:true}` and asserted the loop returned `{ valid: false, code: "theorem t : True := trivial", errors: "", unavailable: true }` — passed, exit 0, 2026-08-18T06:23:06Z (`r2-vitest-scratch-unit.txt`).

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:22-28`, `app/lib/formalization/leanRetryLoop.ts:59-77`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-vitest-scratch-unit.txt`

---

## Claim 12: "No point retrying — the proof was never actually checked."

**Location:** `app/lib/formalization/leanRetryLoop.ts:74`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism that an unavailable verify result exits the retry loop after exactly one verification attempt; does not establish UI-level retry behavior (the user can still trigger Re-verify manually — `LeanCodeDisplay.tsx:112`).

The `return` inside the `for (let attempt = 1; attempt <= MAX_LEAN_ATTEMPTS; attempt++)` loop (`app/lib/formalization/leanRetryLoop.ts:43`) exits before any retry:

```ts
// app/lib/formalization/leanRetryLoop.ts:70-77
const { valid, errors, unavailable } = await verifyLean(fullCode);

if (unavailable) {
  // No point retrying — the proof was never actually checked.
  onErrors("");
  return { valid: false, code: currentCode, errors: "", unavailable: true };
}
```

Executed: in the scratch test run, with `verifyLean` mocked to always return `unavailable: true`, `expect(vi.mocked(verifyLean)).toHaveBeenCalledTimes(1)` passed — one verification call, no retries (out of a possible `MAX_LEAN_ATTEMPTS = 3`, `app/lib/formalization/leanRetryLoop.ts:3`) — and `onErrors` was called with `""`. 5/5 tests passed, exit 0, 2026-08-18T06:23:06Z (`r2-vitest-scratch-unit.txt`).

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:3`, `app/lib/formalization/leanRetryLoop.ts:43`, `app/lib/formalization/leanRetryLoop.ts:70-77`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-vitest-scratch-unit.txt`

---

## Claim 13: "maps 'unavailable' to 'none' (transient verifier-state, not artifact-state)"

**Location:** `app/lib/utils/workspacePersistence.test.ts:32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `sanitizeVerificationStatus`'s mapping of `"unavailable"` on persistence round-trips; does not establish that all persistence entry points route through the sanitizer (both `saveWorkspace` and the load path do call it — `workspacePersistence.ts:89` and `:182`).

The sanitizer whitelists only `"valid"`/`"invalid"` and coerces everything else — including `"unavailable"` — to `"none"`:

```ts
// app/lib/utils/workspacePersistence.ts:34-37
export function sanitizeVerificationStatus(status: string): "none" | "valid" | "invalid" {
  if (status === "valid" || status === "invalid") return status;
  return "none";
}
```

Executed: the test asserting `sanitizeVerificationStatus("unavailable")` returns `"none"` passed in the suite run (55/55 tests, exit 0, 2026-08-18T06:22:42Z, `r2-vitest-existing-tests.txt`). Note the sanitizer's return type still names only three statuses; `"unavailable"` reaching it is handled by the catch-all branch, which is exactly the "not artifact-state" behavior the test name claims.

**Evidence:** `app/lib/utils/workspacePersistence.ts:34-37`, `app/lib/utils/workspacePersistence.ts:89`, `app/lib/utils/workspacePersistence.ts:182`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-vitest-existing-tests.txt`

---

## Claim 14a: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment"

**Location:** `README.md:84`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the route reads and uses this env var as the verifier base URL; does not establish anything about the removed default (split off as Claim 14b).

The route reads the variable at request time:

```ts
// app/api/verification/lean/route.ts:26
const verifierUrl = process.env.LEAN_VERIFIER_URL;
```

and fetches `` `${verifierUrl}/verify` `` (`app/api/verification/lean/route.ts:36`). Executed: with `LEAN_VERIFIER_URL=http://127.0.0.1:4461` and a stub there returning `{valid:false, errors:"stub: unsolved goals"}`, the route returned that exact payload (Case C, `r2-route-stub-cases.txt`, exit 0, 2026-08-18T06:24:28Z), proving the configured URL is used.

**Evidence:** `app/api/verification/lean/route.ts:26`, `app/api/verification/lean/route.ts:36`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-stub-cases.txt`

---

## Claim 14b: "(defaults to `http://localhost:3100`)"

**Location:** `README.md:84`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claimed default value of `LEAN_VERIFIER_URL`; does not establish behavior when the var is set (Claim 14a).

This was true before this change — the base commit had a hardcoded fallback (paraphrased — no quote available because the evidence is the removed side of the diff: `git diff d86d2dc...HEAD` shows the deletion of `const LEAN_VERIFIER_URL = process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";` from `app/api/verification/lean/route.ts`). There is no default now: the unset case short-circuits before any fetch (`app/api/verification/lean/route.ts:26-30`, quoted in Claim 1). Executed: with the var unset and a detector stub listening on `127.0.0.1:3100`, the route returned `verifier-not-configured` and the stub log recorded zero requests ("stub up on 3100" with no "GOT REQUEST" lines, `r2-route-no-env.txt`, 2026-08-18T06:25:36Z). A reader relying on the documented default (e.g., running the Docker verifier on 3100 without setting the var) would get "Verifier offline" instead of real verification.

**Evidence:** `README.md:84`, `app/api/verification/lean/route.ts:26-30`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-no-env.txt`

---

## Claim 15a: "The app continues to work without the verifier"

**Location:** `README.md:92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the API route (and thus the pipeline) does not error or crash when no verifier is available; does not establish the mechanism the sentence goes on to claim (split off as Claim 15b).

Executed: with no verifier configured, the route responds HTTP 200 with a well-formed JSON body rather than failing (`{"valid":false,"unavailable":true,"reason":"verifier-not-configured"}`, Case E, `r2-route-no-env.txt`); with a configured-but-unreachable verifier likewise (Case A, `r2-route-with-env.txt`). Downstream, `leanRetryLoop` returns cleanly instead of throwing (`app/lib/formalization/leanRetryLoop.ts:73-77`, quoted in Claim 11; scratch test passed), and the UI renders the amber banner (Claim 5's passing tests). The app still functions — it now reports "not checked" instead of fabricating success.

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-no-env.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-with-env.txt`, `app/lib/formalization/leanRetryLoop.ts:73-77`

---

## Claim 15b: "the API route falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `README.md:92`
**Type:** Behavioral / Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route's no-verifier response shape; does not establish client-side handling of the new shape (Claims 8-12).

This described the pre-change code — the diff removes exactly this behavior (paraphrased — no quote available because the evidence is the removed side of `git diff d86d2dc...HEAD`, which deletes `// Service unavailable — fall back to mock` / `return NextResponse.json({ valid: true, mock: true });` from the route's catch block). The route now returns the unavailable shape in every no-verifier scenario, confirmed by execution: unset env → `{"valid":false,"unavailable":true,"reason":"verifier-not-configured"}` (Case E); unreachable → `{"valid":false,"unavailable":true,"reason":"verifier-unreachable"}` (Case A); verifier HTTP 500 → `{"valid":false,"unavailable":true,"reason":"verifier-error","detail":"HTTP 500"}` (Case B). No response contained `valid: true` or a `mock` field. A reader acting on this line (e.g., writing a test expecting `mock: true`, or assuming unverified code shows as "Verified") is misled — the entire point of commit 5fe0dad was to remove this behavior.

**Evidence:** `README.md:92`, `app/api/verification/lean/route.ts:52-55`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-no-env.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-with-env.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-stub-cases.txt`

---

## Claim 16a: Request-flow diagram: "Next.js route (POST /api/verification/lean) → POST http://localhost:3100/verify { leanCode }"

**Location:** `docs/ARCHITECTURE.md:197-200`
**Type:** Architectural / Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diagram's hardcoded target URL; does not dispute the request/response shape for a configured, working verifier (`{ valid, errors? }` passthrough was confirmed in Case C).

The diagram reflects the old default. The route now targets `` `${verifierUrl}/verify` `` where `verifierUrl` comes solely from the environment (`app/api/verification/lean/route.ts:26`, `:36`, quoted in Claims 1 and 14a) — there is no `localhost:3100` anywhere in the current route (paraphrased — no quote available because the claim covers absence of code: `rg -n "3100" app/api/verification/lean/route.ts` matches nothing). Executed: with the env unset, no request reached a listener on port 3100 (Case E detector stub, `r2-route-no-env.txt`); with the env set, the request went to the configured 4461 stub (Case C, `r2-route-stub-cases.txt`).

**Evidence:** `docs/ARCHITECTURE.md:197-200`, `app/api/verification/lean/route.ts:26-36`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-no-env.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-stub-cases.txt`

---

## Claim 16b: "If verifier is unavailable: ← fallback mock { valid: true, mock: true }"

**Location:** `docs/ARCHITECTURE.md:203-204`
**Type:** Behavioral / Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the documented unavailable-verifier response; does not establish anything about the verifier service internals documented below it.

Same finding as Claim 15b on the same executed evidence: the unavailable-verifier response is now `{ valid: false, unavailable: true, reason: ... }` in all three failure modes (Cases A, B, E — `r2-route-with-env.txt`, `r2-route-stub-cases.txt`, `r2-route-no-env.txt`), built by:

```ts
// app/api/verification/lean/route.ts:8-15
function unavailableResponse(reason: UnavailableReason, detail?: string) {
  return NextResponse.json({
    valid: false,
    unavailable: true,
    reason,
    ...(detail ? { detail } : {}),
  });
}
```

The `{ valid: true, mock: true }` shape no longer exists in the codebase (paraphrased — no quote available because the claim covers absence of code: `rg -n "mock: true" app/` matches only historical docs, not source).

**Evidence:** `docs/ARCHITECTURE.md:203-204`, `app/api/verification/lean/route.ts:8-15`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-no-env.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-stub-cases.txt`

---

## Claim 17a: "The app automatically detects whether it's available"

**Location:** `docs/USER_GUIDE.md:345`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that verifier unavailability is detected per verification request without user configuration of a "mode"; does not establish the response the guide claims follows detection (split off as Claim 17b).

Detection happens per request: the route distinguishes not-configured (env check, `app/api/verification/lean/route.ts:26-30`), unreachable (catch block, `:52-55`), and errored (`:45-49`) — all quoted in Claims 1-3 — and the client surfaces the result as the `"unavailable"` status. Executed: Cases A, B, and E each produced the corresponding `reason` with no manual switching (`r2-route-with-env.txt`, `r2-route-stub-cases.txt`, `r2-route-no-env.txt`, 2026-08-18T06:23:56Z–06:25:38Z).

**Evidence:** `app/api/verification/lean/route.ts:26-55`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-with-env.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-no-env.txt`

---

## Claim 17b: "and falls back to mock responses when it's not."

**Location:** `docs/USER_GUIDE.md:345`
**Type:** Behavioral / Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claimed mock fallback in the user guide; the same staleness applies to the guide's framing at `docs/USER_GUIDE.md:332` ("For real Lean 4 verification (instead of mock responses)").

Same finding as Claims 15b/16b on the same executed evidence: no mock response exists any longer — the unavailable cases return `{valid:false, unavailable:true, ...}` (Cases A, B, E) and the UI shows "Verifier offline — proof not checked" (`app/components/features/lean-display/LeanCodeDisplay.tsx:133-135`, quoted in Claim 5) rather than a mock pass. Additionally, the guide's implication that no configuration is needed is now wrong: because the `localhost:3100` default was removed (Claim 14b), a user who starts the Docker verifier per `docs/USER_GUIDE.md:337-338` but never sets `LEAN_VERIFIER_URL` gets `verifier-not-configured`, not real verification (paraphrased — no quote available because this consequence combines the executed Case E result with the guide's setup instructions rather than a single code site).

**Evidence:** `docs/USER_GUIDE.md:332-345`, `app/api/verification/lean/route.ts:8-15`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-no-env.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/r2-route-stub-cases.txt`

---

## Claims Requiring Attention

### Stale
- **Claim 14b** (`README.md:84`): The `http://localhost:3100` default was removed; unset `LEAN_VERIFIER_URL` now yields `verifier-not-configured` with no fetch. Update the README (and note the Docker workflow now requires setting the var).
- **Claim 15b** (`README.md:92`): The mock `{ valid: true, mock: true }` fallback no longer exists; the route returns `{ valid: false, unavailable: true, reason }`. Rewrite the sentence.
- **Claim 16a** (`docs/ARCHITECTURE.md:197-200`): Request-flow diagram hardcodes `http://localhost:3100`; the URL now comes only from `LEAN_VERIFIER_URL`.
- **Claim 16b** (`docs/ARCHITECTURE.md:203-204`): Diagram's unavailable branch still shows the removed mock response; actual response is the unavailable shape.
- **Claim 17b** (`docs/USER_GUIDE.md:345`): "falls back to mock responses" is gone; users now see "Verifier offline — proof not checked" (also fix the mock framing at `docs/USER_GUIDE.md:332` and mention the env var in the setup steps).

### Mostly Accurate
- **Claim 3** (`app/api/verification/lean/route.ts:53-55`): The catch also swallows JSON-parse failures of a 2xx verifier response (since `res.json()` moved inside the try), labeling them `verifier-unreachable`; the comment names only network/timeout/DNS.
- **Claim 6** (`app/components/features/lean-display/LeanCodeDisplay.tsx:137-140`): Banner says "not configured or unreachable" but also renders for reachable-but-errored verifiers (`verifier-error`).
- **Claim 7** (`app/components/ui/VerificationBadge.tsx:15`): Tooltip has the same two-of-three-causes gap as Claim 6.
- **Claim 9** (`app/lib/formalization/api.ts:108`): `unavailable` doc omits the third trigger — verifier reachable but returning a non-OK HTTP response.

## Execution provenance summary

All commands ran with cwd `/workspace/external/cc-review-eval/mfc-lean` unless noted. Raw output files are under `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/`.

| Log file | Command | Exit | Timestamp (UTC) |
|---|---|---|---|
| `r2-vitest-existing-tests.txt` | `npx vitest run` (LeanCodeDisplay.test.tsx, OutputPanel.test.tsx, workspacePersistence.test.ts) | 0 (55/55 passed) | 2026-08-18T06:22:42Z |
| `r2-vitest-scratch-unit.txt` | `npx vitest run app/lib/formalization/factcheck-r2.scratch.test.ts` (scratch file removed after run) | 0 (5/5 passed) | 2026-08-18T06:23:06Z |
| `r2-route-with-env.txt` | curl POSTs to Next dev server (`npx next dev -p 4460`, `LEAN_VERIFIER_URL=http://127.0.0.1:4461`): Case A unreachable, Case D missing-leanCode 400 | curl exit 0 each | 2026-08-18T06:23:56Z |
| `r2-route-stub-cases.txt` | Same server; inline `node -e` stub on 4461: Case B (HTTP 500 → `verifier-error`), Case C (200 invalid passthrough) | curl exit 0 each | 2026-08-18T06:24:28Z |
| `r2-route-no-env.txt` | Fresh dev server via `env -u LEAN_VERIFIER_URL npx next dev -p 4460`; detector stub on 3100; Case E (`verifier-not-configured`, zero requests to 3100) | curl exit 0 | 2026-08-18T06:25:36Z |
| `r2-stub-verifier.js`, `r2-stub-3100.log`, `r2-devserver-*.log` | Supporting stub source and server logs | — | — |

Note: an unrelated harness artifact ("Invalid package config /workspace/external/package.json" / "Cannot find dependency 'jsdom'" warnings) appears in the vitest logs; the runs nonetheless completed with all tests passing and exit 0. Cases B/C initially failed to launch their stub from a file path (broken `/workspace/package.json` up-tree — visible in `r2-route-with-env.txt`) and were re-run successfully via inline `node -e` in `r2-route-stub-cases.txt`; only the re-run is verdict-bearing for those cases.
