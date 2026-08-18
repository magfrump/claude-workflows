# Code Fact-Check Report

**Commit:** c95c9cb
**Repository:** /workspace/external/cc-review-eval/mfc-lean
**Scope:** `git diff d86d2dc...HEAD` (10 files — Lean-verifier availability/status-taxonomy change: `app/api/verification/lean/route.ts`, `app/components/features/lean-display/LeanCodeDisplay.{tsx,test.tsx}`, `app/components/panels/OutputPanel.test.tsx`, `app/components/ui/VerificationBadge.tsx`, `app/hooks/useFormalizationPipeline.ts`, `app/lib/formalization/{api.ts,leanRetryLoop.ts}`, `app/lib/types/session.ts`, `app/lib/utils/workspacePersistence.test.ts`) plus README.md, docs/USER_GUIDE.md, docs/ARCHITECTURE.md, and docs/thoughts/feature-brainstorm.md passages referencing the changed verification route
**Checked:** 2026-08-17
**Total claims checked:** 31 (merged atomic claims after cross-replicate clustering and compound splits)
**Summary:** 16 verified, 5 mostly accurate, 9 stale, 0 incorrect, 1 unverifiable
**Replication:** k=2 (two-replicate run, merged most-severe-wins)

Merged from `code-fact-check-report-r1.md` and `code-fact-check-report-r2.md` per the Stage-1
merge instructions (most-severe-wins; compound/atomic mismatches clustered per decision 033).
This merge is mechanical collation of the replicates' verdicts and evidence — no claims were
re-verified and no new evidence was added. Each claim carries a `**Replicate verdicts:**
r1=<verdict> · r2=<verdict>` field; `—` means the replicate did not surface the claim, and
such claims are marked `single-replicate detection`.

Execution provenance (both replicates; all cwd `/workspace/external/cc-review-eval/mfc-lean`, evidence dir `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/`):

- r1 — E1 `npm test` — exit 1 (pre-run `jsdom` dependency-resolution warning; 24 files / 225 tests passed) — 2026-08-18T06:22:35Z — `r1-vitest-full.log`
- r1 — E2 targeted `npx vitest run` (LeanCodeDisplay.test.tsx, OutputPanel.test.tsx, workspacePersistence.test.ts, verbose) — exit 1 (jsdom warning; 55/55 passed) — 2026-08-18T06:22:50Z — `r1-vitest-targeted.log`
- r1 — E3 scratch unit test (`__r1_scratch.test.ts`, deleted after run) — exit 1 (jsdom warning; 6/6 passed) — 2026-08-18T06:23:43Z — `r1-vitest-scratch.log`
- r1 — E4 scratch route-handler test executing the real `POST` from `app/api/verification/lean/route.ts` under vitest node env with env control + `node:http` stubs on 127.0.0.1:4399 (deleted after run) — exit 1 (jsdom warning; 5/5 passed) — 2026-08-18T06:25:11Z — `r1-route-handler-exec.log` (a concurrent dev server on port 4460 blocked r1 from launching its own — `r1-devserver-A.log`)
- r2 — `npx vitest run` (same three test files) — exit 0 (55/55 passed) — 2026-08-18T06:22:42Z — `r2-vitest-existing-tests.txt`
- r2 — scratch unit test (`factcheck-r2.scratch.test.ts`, removed after run) — exit 0 (5/5 passed) — 2026-08-18T06:23:06Z — `r2-vitest-scratch-unit.txt`
- r2 — live `next dev -p 4460` + curl: Case A unreachable, Case D missing-leanCode — 2026-08-18T06:23:56Z — `r2-route-with-env.txt`
- r2 — same server + inline `node -e` stub on 4461: Case B (HTTP 500 → `verifier-error`), Case C (200 invalid passthrough) — 2026-08-18T06:24:28Z — `r2-route-stub-cases.txt`
- r2 — fresh server via `env -u LEAN_VERIFIER_URL npx next dev -p 4460`, detector stub on 3100: Case E (`verifier-not-configured`, zero requests to 3100) — 2026-08-18T06:25:36Z — `r2-route-no-env.txt`

r1's vitest invocations exited 1 due to a pre-run `MISSING DEPENDENCY 'jsdom'` resolution
warning while all per-test results passed (r1 discloses this explicitly); r2's equivalent runs
exited 0 with the same warning present as noise. Verdicts rest on the per-test results.

---

## Claim 1: "The app includes a Dockerized Lean 4 verification service. When running, submitted Lean code is type-checked by a real Lean 4 installation."

**Location:** `README.md:60`
**Type:** Architectural / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the existence of the verifier service and its claimed real-Lean checking; does not establish the route's fallback behavior (Claim 2).
**Replicate verdicts:** r1=Unverifiable · r2=— · single-replicate detection

The verifier service exists in-repo (`verifier/` contains `Dockerfile`, `server.ts`, and `lean-project/` per `docs/ARCHITECTURE.md:208-218`; files present on disk). Whether submitted code is actually type-checked by a real Lean 4 installation requires the Dockerized verifier, which was not available in the review sandbox — execution required but blocked, so the verdict is capped at Unverifiable. (r1)

**Evidence:** `README.md:58-60`, `verifier/`, `docs/ARCHITECTURE.md:208-227`

---

## Claim 2: "When the service is not running, the app falls back to a mock response."

**Location:** `README.md:60`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route's response when the verifier is unreachable; does not establish UI rendering of that response.
**Replicate verdicts:** r1=Stale · r2=— · single-replicate detection

The mock fallback was removed in commit 5fe0dad. The route now returns an unavailability payload, not a mock pass:

```ts
// app/api/verification/lean/route.ts:53-56
} catch {
  // Network / timeout / DNS failure — verifier unreachable.
  return unavailableResponse("verifier-unreachable");
}
```

Executed (r1 E4): the real `POST` handler with `LEAN_VERIFIER_URL=http://127.0.0.1:4398` (nothing listening) returned `{ valid: false, unavailable: true, reason: "verifier-unreachable" }` (`r1-route-handler-exec.log`, 2026-08-18T06:25:11Z). r2 confirmed the identical route behavior over live HTTP at the sibling README:92 claim (Claim 6). This sentence sits at README:60, which only r1 harvested.

**Evidence:** `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log

---

## Claim 3: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment"

**Location:** `README.md:84`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the route reads and uses the env var as the verifier base URL per request; does not cover the default-value half of the sentence (Claim 4).
**Replicate verdicts:** r1=Verified · r2=Verified

```ts
// app/api/verification/lean/route.ts:26
const verifierUrl = process.env.LEAN_VERIFIER_URL;
```

Executed by both replicates independently: r1 — setting the var to a live stub changed route behavior and unsetting it produced `verifier-not-configured` (E4, `r1-route-handler-exec.log`); r2 — with `LEAN_VERIFIER_URL=http://127.0.0.1:4461` and a stub there returning `{valid:false, errors:"stub: unsolved goals"}`, the live route returned that exact payload, proving the configured URL is used (Case C, `r2-route-stub-cases.txt`, 2026-08-18T06:24:28Z).

**Evidence:** `app/api/verification/lean/route.ts:26`, `app/api/verification/lean/route.ts:36`, r1-route-handler-exec.log, r2-route-stub-cases.txt

---

## Claim 4: "(defaults to `http://localhost:3100`)"

**Location:** `README.md:84`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claimed default URL when the env var is unset; does not cover behavior when the var is set (Claim 3).
**Replicate verdicts:** r1=Stale · r2=Stale

The default was removed in this change; the base commit had `process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100"` (visible only in `git diff d86d2dc...HEAD`). At HEAD, unset means not-configured and no URL is contacted:

```ts
// app/api/verification/lean/route.ts:26-30
const verifierUrl = process.env.LEAN_VERIFIER_URL;
if (!verifierUrl) {
  // No verifier configured (typical on Vercel deploys without a separate verifier service).
  return unavailableResponse("verifier-not-configured");
}
```

Executed by both replicates: r1 — env var deleted → `{ valid: false, unavailable: true, reason: "verifier-not-configured" }` with no network attempt (E4, `r1-route-handler-exec.log`); r2 — strongest evidence: with the var unset and a detector stub listening on `127.0.0.1:3100`, the route returned `verifier-not-configured` and the stub log recorded zero incoming requests (Case E, `r2-route-no-env.txt`, 2026-08-18T06:25:36Z). A reader relying on the documented default (e.g., running the Docker verifier on 3100 without setting the var) would get "Verifier offline" instead of real verification. (r2)

**Evidence:** `README.md:84`, `app/api/verification/lean/route.ts:26-30`, r1-route-handler-exec.log, r2-route-no-env.txt

---

## Claim 5: "The app continues to work without the verifier"

**Location:** `README.md:92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the API route (and pipeline) does not error or crash when no verifier is available; does not establish the mock-fallback mechanism the sentence goes on to claim (Claim 6).
**Replicate verdicts:** r1=Stale (compound — severity carried by the mock-fallback half, Claim 6; r1's Scope explicitly excluded this half) · r2=Verified

r2 split the README:92 sentence; r1 verdicted it as one compound whose Stale is attributable entirely to the fallback half (r1's Scope: "does not establish whether the app 'continues to work' in the broader UI sense"), so the compound's severity does not transfer to this part — see Verdict stability. Executed (r2): with no verifier configured the route responds HTTP 200 with a well-formed JSON body (`{"valid":false,"unavailable":true,"reason":"verifier-not-configured"}`, Case E, `r2-route-no-env.txt`); likewise for configured-but-unreachable (Case A, `r2-route-with-env.txt`). Downstream, `leanRetryLoop` returns cleanly instead of throwing (`app/lib/formalization/leanRetryLoop.ts:73-77`) and the UI renders the amber banner (Claim 11's passing tests). The app still functions — it now reports "not checked" instead of fabricating success. (r2)

**Evidence:** r2-route-no-env.txt, r2-route-with-env.txt, `app/lib/formalization/leanRetryLoop.ts:73-77`

---

## Claim 6: "the API route falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `README.md:92`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route's no-verifier response shape; does not establish client-side handling of the new shape (Claims 12-20).
**Replicate verdicts:** r1=Stale · r2=Stale

The diff removes exactly this behavior (`git diff d86d2dc...HEAD` deletes `// Service unavailable — fall back to mock` / `return NextResponse.json({ valid: true, mock: true });` from the route's catch block). Executed by both replicates: r1 — unreachable and unset-env cases both returned `valid: false, unavailable: true` payloads, never `mock: true` (E4, `r1-route-handler-exec.log`); r2 — all three failure modes over live HTTP: unset env → `verifier-not-configured` (Case E), unreachable → `verifier-unreachable` (Case A), verifier HTTP 500 → `verifier-error` with `detail: "HTTP 500"` (Case B); no response contained `valid: true` or a `mock` field. A reader acting on this line (e.g., writing a test expecting `mock: true`, or assuming unverified code shows as "Verified") is misled — the entire point of commit 5fe0dad was to remove this behavior. (r2)

**Evidence:** `README.md:92`, `app/api/verification/lean/route.ts:52-56`, r1-route-handler-exec.log, r2-route-no-env.txt, r2-route-with-env.txt, r2-route-stub-cases.txt

---

## Claim 7: "No verifier configured (typical on Vercel deploys without a separate verifier service)."

**Location:** `app/api/verification/lean/route.ts:28`
**Type:** Error-handling / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch condition (env var unset → not-configured response before any fetch); the parenthetical about Vercel deploy topology is deployment context, not checked.
**Replicate verdicts:** r1=Verified · r2=Verified

```ts
// app/api/verification/lean/route.ts:26-30
const verifierUrl = process.env.LEAN_VERIFIER_URL;
if (!verifierUrl) {
  // No verifier configured (typical on Vercel deploys without a separate verifier service).
  return unavailableResponse("verifier-not-configured");
}
```

Executed by both replicates: r1 via the real handler with env var deleted (E4, `r1-route-handler-exec.log`); r2 via live dev server started with `env -u LEAN_VERIFIER_URL` — response `{"valid":false,"unavailable":true,"reason":"verifier-not-configured"}`, HTTP 200, and a detector stub on 3100 logged zero requests (Case E, `r2-route-no-env.txt`). Who observes this failure: `verifyLean` maps `unavailable` (`app/lib/formalization/api.ts:126-131`), `verifyResultToStatus` yields `"unavailable"`, and the UI renders the amber banner/badge (Claims 11, 14) — surfaced, not swallowed. (r1)

**Evidence:** `app/api/verification/lean/route.ts:26-30`, r1-route-handler-exec.log, r2-route-no-env.txt

---

## Claim 8: "Verifier reachable but errored — treat as unavailable rather than a failed proof, since the proof itself was never checked."

**Location:** `app/api/verification/lean/route.ts:45-48`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the non-OK-response branch mapping to the unavailable payload; does not establish behavior for OK responses with malformed JSON (see Claim 9) or how the UI renders the `verifier-error` reason (collapsed into the single `unavailable` status client-side).
**Replicate verdicts:** r1=Verified · r2=Verified

```ts
// app/api/verification/lean/route.ts:45-49
if (!res.ok) {
  // Verifier reachable but errored — treat as unavailable rather than a failed proof,
  // since the proof itself was never checked.
  return unavailableResponse("verifier-error", `HTTP ${res.status}`);
}
```

Executed by both replicates against real HTTP-500 stubs: r1 (`node:http` stub, E4, `r1-route-handler-exec.log`) and r2 (live server + stub on 4461, Case B, `r2-route-stub-cases.txt`) each observed `{ valid: false, unavailable: true, reason: "verifier-error", detail: "HTTP 500" }` — unavailable, not a failed proof (`unavailable:true` maps to status `"unavailable"`, not `"invalid"`, per Claim 17's executed mapping).

**Evidence:** `app/api/verification/lean/route.ts:45-49`, r1-route-handler-exec.log, r2-route-stub-cases.txt

---

## Claim 9: "Network / timeout / DNS failure — verifier unreachable."

**Location:** `app/api/verification/lean/route.ts:53-55`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the catch block returns and that connection-refused failures land there; does not establish behavior for the timeout (abort) or DNS sub-cases specifically, which were not separately exercised.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate

Most-severe-wins: r2's Mostly accurate carries; its analysis found a coverage imprecision r1 did not. The catch block returns the unreachable reason:

```ts
// app/api/verification/lean/route.ts:53-56
} catch {
  // Network / timeout / DNS failure — verifier unreachable.
  return unavailableResponse("verifier-unreachable");
}
```

Executed for the connection-refused case by both replicates: `{ valid: false, unavailable: true, reason: "verifier-unreachable" }` (r1 E4 `r1-route-handler-exec.log`; r2 Case A `r2-route-with-env.txt`, 2026-08-18T06:23:56Z). The timeout case reaches the same catch via abort (`route.ts:33-34`: `AbortController` + `setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)`), and DNS failure likewise throws from `fetch` into the same bare `catch` (r1). The imprecision (r2): `const data = await res.json();` sits inside the same `try` after the OK check (`route.ts:51`), so a reachable verifier returning a 2xx response with malformed JSON also lands in this catch and is labeled `verifier-unreachable` — a case that is neither network, timeout, nor DNS. Mechanism and conclusion are right for the failure classes the comment names; the label is merely broader than stated.

**Evidence:** `app/api/verification/lean/route.ts:32-56`, r1-route-handler-exec.log, r2-route-with-env.txt

---

## Claim 10: "Edit / Done toggle + Re-verify — outside scroll container so they stay visible"

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:108`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers DOM placement of the button group relative to the scrolling container; does not establish actual rendered stacking/visibility across viewports or browsers (no visual test run).
**Replicate verdicts:** r1=Verified · r2=Verified

The button group is an absolutely positioned sibling that precedes the scroll container rather than living inside it:

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:110
<div className="absolute right-4 top-4 z-30 flex items-center gap-2">
```

The scrolling content is a separate sibling div (`LeanCodeDisplay.tsx:128`: `<div className="h-full overflow-auto px-8 py-6">`), so scrolling it does not move the buttons (both replicates, same static evidence). r2 additionally noted the Re-verify visibility condition now includes the new status (`LeanCodeDisplay.tsx:112`: `(leanEdited || verificationStatus === "invalid" || verificationStatus === "unavailable") && editMode === "rendered"`), with the "shows Re-verify button when status is unavailable" test passing in both replicates' suite runs.

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.tsx:105-128`

---

## Claim 11: "Verifier offline banner — distinct from 'Verification Failed' so users don't read a missing verifier as a passing proof."

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:129-131`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `unavailable` status renders a dedicated amber banner distinct from the invalid-status error box and the green "Verified" badge; does not cover the badge tooltip (Claim 14) or that every upstream failure reason reaches the `"unavailable"` status (Claims 7-9, 16).
**Replicate verdicts:** r1=Verified · r2=Verified

```tsx
// app/components/features/lean-display/LeanCodeDisplay.tsx:131-136
{verificationStatus === "unavailable" && (
  <div className="mb-4 rounded border border-amber-300 bg-amber-50 px-4 py-3">
    <h3 className="text-xs font-semibold uppercase tracking-wide text-amber-800">
      Verifier offline — proof not checked
    </h3>
```

The "Verification Failed" error box is a separate branch gated on `verificationStatus === "invalid" && verificationErrors` (`LeanCodeDisplay.tsx:146`), and the badge renders "Verified" only for `"valid"` (`app/components/ui/VerificationBadge.tsx:8-10`). Executed by both replicates: "shows the verifier-offline banner when status is unavailable", "shows Re-verify button when status is unavailable", and OutputPanel's 'shows "Verifier offline" for unavailable status (not a passing badge)' — which additionally asserts `queryByText('Verified')` is absent (`app/components/panels/OutputPanel.test.tsx:112-116`) — all passed (r1 E2 `r1-vitest-targeted.log` 55/55; r2 `r2-vitest-existing-tests.txt` 55/55, exit 0).

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.tsx:131-146`, `app/components/ui/VerificationBadge.tsx:8-10`, `app/components/panels/OutputPanel.test.tsx:112-116`, r1-vitest-targeted.log, r2-vitest-existing-tests.txt

---

## Claim 12: "The Lean verifier service is not configured or unreachable, so this proof has not been checked."

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:134-137`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the banner text's characterization of when `unavailable` occurs; does not cover the env-var remedy sentence (Claim 13).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (as part of its compound Claim 6, whose imprecision is attributed to this cause list)

Both replicates found the same imprecision independently. The "proof has not been checked" half is correct for all three `unavailable` reasons. The cause list is incomplete: the route also emits `unavailable: true` when the verifier is configured, reachable, and returns an HTTP error (`route.ts:45-49`, quoted in Claim 8), and the client collapses all three reasons into the one `"unavailable"` status (`app/lib/formalization/api.ts:115-118`). Executed via the HTTP-500 stub cases in both replicates (r1 E4 `r1-route-handler-exec.log`; r2 Case B `r2-route-stub-cases.txt`). Precise version: "not configured, unreachable, or errored." Mechanism and conclusion are right; a cause case is missing.

**Evidence:** `app/components/features/lean-display/LeanCodeDisplay.tsx:132-138`, `app/api/verification/lean/route.ts:45-49`, `app/lib/formalization/api.ts:115-118`, r1-route-handler-exec.log, r2-route-stub-cases.txt

---

## Claim 13: "Set the `LEAN_VERIFIER_URL` environment variable to a running verifier to enable checking."

**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:135-140`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that setting the env var to a responsive verifier makes the route pass real verifier responses through; does not establish that a real Lean toolchain then checks the proof (Claim 1), nor that pointing it at a broken verifier enables checking.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound Claim 6 — its analysis states "The remedy is accurate"; the compound's severity is carried by the cause list, Claim 12)

r1 split the banner text; r2 verdicted it as one compound. Both replicates' analyses agree the remedy half is accurate, so the compound's Mostly-accurate does not transfer to this part — see Verdict stability. Executed by both: r1 — with the var pointed at a live stub returning `{ valid: false, errors: "type mismatch at line 3" }`, the route passed the verifier response through unchanged with no `unavailable` flag, and with the var unset checking is off (E4, `r1-route-handler-exec.log`); r2 — Case C passthrough of `{valid:false, errors:"stub: unsolved goals"}` and Case E short-circuit (`r2-route-stub-cases.txt`, `r2-route-no-env.txt`).

**Evidence:** `app/api/verification/lean/route.ts:26-30`, `app/api/verification/lean/route.ts:51-52`, r1-route-handler-exec.log, r2-route-stub-cases.txt, r2-route-no-env.txt

---

## Claim 14: "Lean verifier is offline or not configured. Set LEAN_VERIFIER_URL to enable checking." (badge tooltip)

**Location:** `app/components/ui/VerificationBadge.tsx:15`
**Type:** Error-handling / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tooltip's cause characterization and remedy for the `unavailable` badge; does not cover badge rendering for other statuses or browser-native title-attribute display.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate

Same imprecision as Claim 12, found by both replicates. The badge renders for status `"unavailable"`:

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

— which also occurs when the verifier is online but errors (HTTP 500 → `verifier-error`, executed in r1 E4 and r2 Case B). The remedy half is verified per Claim 13's executions; the compound verdict is carried by the incomplete cause list. Badge rendering for `unavailable` (and absence of a passing badge) executed via the OutputPanel test in both replicates' suite runs (`r1-vitest-targeted.log`, `r2-vitest-existing-tests.txt`).

**Evidence:** `app/components/ui/VerificationBadge.tsx:11-19`, `app/api/verification/lean/route.ts:45-49`, r1-route-handler-exec.log, r2-route-stub-cases.txt, r2-vitest-existing-tests.txt

---

## Claim 15: "Only 'invalid' carries verifier output; 'valid'/'unavailable' clear errors."

**Location:** `app/hooks/useFormalizationPipeline.ts:122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the error-string handling at the two call sites in this hook (post-retry-loop and `verifyWithDeps`); does not establish that other writers of `verificationErrors` elsewhere follow the same rule, nor the `catch` path behavior.
**Replicate verdicts:** r1=Verified · r2=Verified

```ts
// app/hooks/useFormalizationPipeline.ts:121-126
const vStatus = verifyResultToStatus(result);
// Only "invalid" carries verifier output; "valid"/"unavailable" clear errors.
const vErrors = vStatus === "invalid" ? result.errors : "";
a.setVerificationStatus(vStatus);
if (vStatus !== "invalid") a.setVerificationErrors("");
a.onSessionUpdate?.({ verificationStatus: vStatus, verificationErrors: vErrors });
```

The second site behaves identically (`useFormalizationPipeline.ts:142-144`: `const vErrors = vStatus === "invalid" ? (result.errors || "Verification failed") : "";`). Both sites propagate `result.errors` only for `"invalid"` and empty-string otherwise, matching the comment (both replicates, same static evidence). r2 noted one subtlety consistent with the claim: in the first site, when `vStatus === "invalid"` the local error state is not re-set (only `onSessionUpdate` receives `result.errors`) — but that path is downstream of `leanRetryLoop`, whose `onErrors` callback already streamed errors into state (`useFormalizationPipeline.ts:110-118` plus `leanRetryLoop.ts:84-96` acting together).

**Evidence:** `app/hooks/useFormalizationPipeline.ts:121-126`, `app/hooks/useFormalizationPipeline.ts:139-147`, `app/lib/formalization/leanRetryLoop.ts:68-96`

---

## Claim 16: "True when the verifier is not configured or could not be reached." (`VerifyLeanResult.unavailable`)

**Location:** `app/lib/formalization/api.ts:107-108`
**Type:** Invariant / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conditions under which the client-side `unavailable` flag is true; does not cover the status mapping (Claim 17) or behavior when `/api/verification/lean` itself returns non-JSON (in that case `verifyLean`'s own `res.json()` throws to its caller).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate

The flag mirrors the route's `unavailable` field:

```ts
// app/lib/formalization/api.ts:126-131
return {
  valid: Boolean(data.valid),
  errors: (data.errors as string | undefined) ?? "",
  unavailable: Boolean(data.unavailable),
};
```

The route sets `unavailable: true` in three cases, not two: not-configured, unreachable, and `verifier-error` (reachable but HTTP-error) — all executed in both replicates (r1 E4 `r1-route-handler-exec.log`; r2 Cases A/B/E). The docstring names only the first two; a reader treating `unavailable` as strictly "not configured or unreachable" would misattribute verifier-error cases. Precise version: "not configured, unreachable, or the verifier returned an error response." Client-side mapping of the flag executed in r1 E3 ("maps unavailable flag from the API response", `r1-vitest-scratch.log`).

**Evidence:** `app/lib/formalization/api.ts:104-131`, `app/api/verification/lean/route.ts:45-49`, r1-route-handler-exec.log, r1-vitest-scratch.log, r2-route-stub-cases.txt

---

## Claim 17: "`unavailable` wins over `valid` so a missing verifier never reads as a passing proof."

**Location:** `app/lib/formalization/api.ts:111-114`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the precedence inside `verifyResultToStatus` for all four flag combinations; does not establish that every caller routes through this helper (both `useFormalizationPipeline.ts` call sites do — Claim 15 — but `leanRetryLoop` consumes the flags directly).
**Replicate verdicts:** r1=Verified · r2=Verified

```ts
// app/lib/formalization/api.ts:115-118
export function verifyResultToStatus(result: { valid: boolean; unavailable?: boolean }): VerificationStatus {
  if (result.unavailable) return "unavailable";
  return result.valid ? "valid" : "invalid";
}
```

Executed by both replicates via independent scratch unit tests asserting all four combinations — `{valid:true, unavailable:true}` → `"unavailable"`, `{valid:false, unavailable:true}` → `"unavailable"`, `{valid:true}` → `"valid"`, `{valid:false}` → `"invalid"` — all passed (r1 E3 `r1-vitest-scratch.log` 6/6; r2 `r2-vitest-scratch-unit.txt` 5/5, exit 0).

**Evidence:** `app/lib/formalization/api.ts:111-118`, r1-vitest-scratch.log, r2-vitest-scratch-unit.txt

---

## Claim 18: "Generate Lean code from a semiformal proof and verify it, retrying up to MAX_LEAN_ATTEMPTS times on failure."

**Location:** `app/lib/formalization/leanRetryLoop.ts:30-33`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop's retry contract; does not cover cancellation behavior.
**Replicate verdicts:** r1=Mostly accurate · r2=— · single-replicate detection

Retrying up to 3 attempts holds for invalid-proof failures (`leanRetryLoop.ts:3`: `export const MAX_LEAN_ATTEMPTS = 3;`; `leanRetryLoop.ts:43`: `for (let attempt = 1; attempt <= MAX_LEAN_ATTEMPTS; attempt++)`). But since this change, one failure class does not retry at all: verifier-unavailable exits on the first attempt (`leanRetryLoop.ts:73-77`, quoted in Claim 20; executed in r1 E3 — exactly one generation call and one verification call, `r1-vitest-scratch.log`; r2's scratch run independently confirmed the same single-attempt exit under its Claim 12, though it did not verdict this docstring). Precise version: "retrying up to MAX_LEAN_ATTEMPTS times on verification failure; returns immediately without retrying if the verifier is unavailable." (r1)

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:3`, `app/lib/formalization/leanRetryLoop.ts:43`, `app/lib/formalization/leanRetryLoop.ts:73-77`, r1-vitest-scratch.log

---

## Claim 19: "True when the verifier was unavailable — the proof was generated but never checked." (`LeanRetryResult.unavailable`)

**Location:** `app/lib/formalization/leanRetryLoop.ts:26-27`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when the result field is set and what it signifies (generated code preserved, never checked); does not cover consumers' handling of the field (Claim 15). This doc's wording ("was unavailable") does not enumerate causes, so Claim 16's incomplete-cause-list finding does not apply here.
**Replicate verdicts:** r1=Verified · r2=Verified

The field is set on exactly one path — when `verifyLean` reports `unavailable` after code was generated:

```ts
// app/lib/formalization/leanRetryLoop.ts:73-77
if (unavailable) {
  // No point retrying — the proof was never actually checked.
  onErrors("");
  return { valid: false, code: currentCode, errors: "", unavailable: true };
}
```

`currentCode` at that point holds the freshly generated Lean code (`leanRetryLoop.ts:59-62`), so "generated but never checked" matches. Executed by both replicates via independent scratch tests with generation stubbed/mocked and verification returning unavailable: the loop returned `{ valid: false, code: <generated code>, errors: "", unavailable: true }` (r1 E3 `r1-vitest-scratch.log`; r2 `r2-vitest-scratch-unit.txt`). No other `return` in the function sets `unavailable` (grep of `leanRetryLoop.ts` finds `unavailable: true` only at line 76 — r1).

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:22-28`, `app/lib/formalization/leanRetryLoop.ts:59-77`, r1-vitest-scratch.log, r2-vitest-scratch-unit.txt

---

## Claim 20: "No point retrying — the proof was never actually checked."

**Location:** `app/lib/formalization/leanRetryLoop.ts:74`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the unavailable branch exits after exactly one verification attempt with no further generation or verification calls; does not establish UI-level retry behavior (the user can still trigger Re-verify manually — `LeanCodeDisplay.tsx:112`).
**Replicate verdicts:** r1=Verified · r2=Verified

The `return` at `leanRetryLoop.ts:76` (quoted in Claim 19) exits the attempt loop on the first unavailable result. Executed by both replicates: r1 — fetch-call accounting showed exactly one call to `/api/formalization/lean` and one to `/api/verification/lean`, no retries, `onErrors("")` observed once (E3, `r1-vitest-scratch.log`); r2 — `expect(vi.mocked(verifyLean)).toHaveBeenCalledTimes(1)` passed with `verifyLean` mocked always-unavailable, out of a possible `MAX_LEAN_ATTEMPTS = 3` (`r2-vitest-scratch-unit.txt`, 5/5, exit 0). Who observes this: the loop's caller receives `unavailable: true`, which `useFormalizationPipeline` maps to status `"unavailable"` via `verifyResultToStatus` (Claim 15), surfacing the banner/badge.

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:3`, `app/lib/formalization/leanRetryLoop.ts:43`, `app/lib/formalization/leanRetryLoop.ts:70-77`, r1-vitest-scratch.log, r2-vitest-scratch-unit.txt

---

## Claim 21: "maps 'unavailable' to 'none' (transient verifier-state, not artifact-state)" (test description asserting `sanitizeVerificationStatus` behavior)

**Location:** `app/lib/utils/workspacePersistence.test.ts:32-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers persistence sanitization of the `unavailable` status; does not cover in-session (non-persisted) status handling. Both `saveWorkspace` and the load path call the sanitizer (`workspacePersistence.ts:89`, `:182` — r2).
**Replicate verdicts:** r1=Verified · r2=Verified

```ts
// app/lib/utils/workspacePersistence.ts:34-37
export function sanitizeVerificationStatus(status: string): "none" | "valid" | "invalid" {
  if (status === "valid" || status === "invalid") return status;
  return "none";
}
```

`"unavailable"` falls through to `"none"` (not in the pass-through set), so it is never persisted as artifact state. Executed: the test passed in both replicates' suite runs (r1 E2 `r1-vitest-targeted.log`; r2 `r2-vitest-existing-tests.txt`, 55/55, exit 0). r2 noted the sanitizer's return type still names only three statuses; `"unavailable"` reaching it is handled by the catch-all branch, which is exactly the "not artifact-state" behavior the test name claims.

**Evidence:** `app/lib/utils/workspacePersistence.ts:34-37`, `app/lib/utils/workspacePersistence.ts:89`, `app/lib/utils/workspacePersistence.ts:182`, `app/lib/utils/workspacePersistence.test.ts:32-34`, r1-vitest-targeted.log, r2-vitest-existing-tests.txt

---

## Claim 22: "When the Lean verifier service is unset or unreachable, the route used to silently respond `{ valid: true, mock: true }` ... API route now distinguishes three failure modes (verifier-not-configured, verifier-unreachable, verifier-error) and responds with `{ valid: false, unavailable: true, reason: ... }`." (commit message)

**Location:** commit `5fe0dad` (message)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route-behavior halves of the commit message (old mock behavior, new three-reason taxonomy); does not re-verdict the UI halves, covered by Claims 11, 14, 20.
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

The old behavior is in the base version (`git diff d86d2dc...HEAD` shows the deleted lines `// Service unavailable — fall back to mock` / `return NextResponse.json({ valid: true, mock: true });`). The three reasons exist at HEAD:

```ts
// app/api/verification/lean/route.ts:5
type UnavailableReason = "verifier-not-configured" | "verifier-unreachable" | "verifier-error";
```

Executed (r1 E4): all three reasons were produced by the real handler under the corresponding conditions (unset env / connection refused / stub HTTP 500), each with `{ valid: false, unavailable: true, reason: ... }` (`r1-route-handler-exec.log`, 5/5 passed). r2's Cases A/B/E independently reproduced all three reasons over live HTTP, though r2 did not verdict the commit message itself.

**Evidence:** `app/api/verification/lean/route.ts:5-14`, r1-route-handler-exec.log

---

## Claim 23: "Remove unused unavailableReason field from VerifyLeanResult (no consumer)." (commit message)

**Location:** commit `c95c9cb` (message)
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the field existed at 5fe0dad, had no consumer, and is absent at HEAD; does not cover the helper-extraction half (whose existence Claim 17 establishes).
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

At the intermediate commit the field was declared and populated only within `api.ts` (`app/lib/formalization/api.ts:109 @ 5fe0dad`: `unavailableReason?: string;`). `git grep -n "unavailableReason" 5fe0dad` returns exactly two hits, both in `api.ts` (declaration line 109, population line 123) — no consumer anywhere. At HEAD, `git grep unavailableReason HEAD` returns zero hits. (r1)

**Evidence:** `app/lib/formalization/api.ts:104-109`, git history (`git grep` at 5fe0dad and HEAD)

---

## Claim 24: "If the service is not running, a mock 'valid' response is returned."

**Location:** `docs/USER_GUIDE.md:203`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the not-running fallback; does not cover the surrounding badge-status list (whose "Verifying.../None" entries are unchanged, though the list also omits the new unavailable state).
**Replicate verdicts:** r1=Stale · r2=— · single-replicate detection

Same mechanism as Claims 2/6: the route now returns `{ valid: false, unavailable: true, reason: "verifier-unreachable" }` when the service is down (`route.ts:53-56`; executed in r1 E4, `r1-route-handler-exec.log`; independently confirmed over live HTTP by r2 Case A at the README locations). No mock "valid" response exists at HEAD (`mock` does not appear in `route.ts`). This USER_GUIDE:203 sentence was harvested only by r1.

**Evidence:** `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log

---

## Claim 25: "The verifier runs on port 3100."

**Location:** `docs/USER_GUIDE.md:345`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Docker service's configured port; does not establish that the app contacts that port (it no longer does by default — Claim 4).
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

```yaml
# docker-compose.yml:6-9
    ports:
      - "3100:3100"
    environment:
      - PORT=3100
```

(The identical sentence at `README.md:71` is covered by this verdict — r1.)

**Evidence:** `docker-compose.yml:6-9`, `README.md:71`

---

## Claim 26: "The app automatically detects whether it's available"

**Location:** `docs/USER_GUIDE.md:345`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that verifier unavailability is detected per verification request without user configuration of a "mode"; does not establish the response the guide claims follows detection (Claim 27).
**Replicate verdicts:** r1=Stale (compound — severity carried by the mock-fallback half, Claim 27; r1's analysis states "Unavailability is still detected") · r2=Verified

r2 split the sentence; r1 verdicted it as one compound whose Stale is attributable to the fallback half — see Verdict stability. Detection happens per request: the route distinguishes not-configured (env check, `route.ts:26-30`), unreachable (catch block, `:53-56`), and errored (`:45-49`), and the client surfaces the result as the `"unavailable"` status. Executed (r2): Cases A, B, and E each produced the corresponding `reason` with no manual switching (`r2-route-with-env.txt`, `r2-route-stub-cases.txt`, `r2-route-no-env.txt`). One nuance from r1, consistent with r2's Scope: with `LEAN_VERIFIER_URL` unset the app makes no availability probe at all — it short-circuits to not-configured rather than probing.

**Evidence:** `app/api/verification/lean/route.ts:26-56`, r2-route-with-env.txt, r2-route-no-env.txt

---

## Claim 27: "and falls back to mock responses when it's not."

**Location:** `docs/USER_GUIDE.md:345`
**Type:** Behavioral / Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claimed mock fallback in the user guide; the same staleness applies to the guide's framing at `docs/USER_GUIDE.md:332` ("For real Lean 4 verification (instead of mock responses)") — r2.
**Replicate verdicts:** r1=Stale · r2=Stale

Same finding as Claims 6/29 on the same executed evidence: no mock response exists any longer — the unavailable cases return `{valid:false, unavailable:true, ...}` (r1 E4; r2 Cases A/B/E) and the UI shows "Verifier offline — proof not checked" (Claim 11) rather than a mock pass. Additionally (r2): because the `localhost:3100` default was removed (Claim 4), a user who starts the Docker verifier per `docs/USER_GUIDE.md:337-338` but never sets `LEAN_VERIFIER_URL` gets `verifier-not-configured`, not real verification — the guide's implication that no configuration is needed is now wrong.

**Evidence:** `docs/USER_GUIDE.md:332-345`, `app/api/verification/lean/route.ts:8-15`, `app/api/verification/lean/route.ts:26-30`, r1-route-handler-exec.log, r2-route-no-env.txt, r2-route-stub-cases.txt

---

## Claim 28: Request-flow diagram: "Next.js route (POST /api/verification/lean) → POST http://localhost:3100/verify { leanCode }"

**Location:** `docs/ARCHITECTURE.md:197-200`
**Type:** Architectural / Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diagram's hardcoded target URL; does not dispute the request/response shape for a configured, working verifier (`{ valid, errors? }` passthrough confirmed in r2 Case C), nor the verifier-internal structure sections (unchanged code, out of diff scope).
**Replicate verdicts:** r1=Stale (compound Claim 22 covering both diagram facts) · r2=Stale

The diagram reflects the old default. The route now targets `` `${verifierUrl}/verify` `` where `verifierUrl` comes solely from the environment (`route.ts:26`, `:36`) — there is no `localhost:3100` anywhere in the current route (`rg -n "3100" app/api/verification/lean/route.ts` matches nothing — r2). Executed: with the env unset, no request reached a listener on port 3100 (r2 Case E detector stub, `r2-route-no-env.txt`); with the env set, the request went to the configured stub (r2 Case C, `r2-route-stub-cases.txt`; r1 E4 equivalently).

**Evidence:** `docs/ARCHITECTURE.md:197-200`, `app/api/verification/lean/route.ts:26-36`, r1-route-handler-exec.log, r2-route-no-env.txt, r2-route-stub-cases.txt

---

## Claim 29: "If verifier is unavailable: ← fallback mock { valid: true, mock: true }" (request-flow diagram)

**Location:** `docs/ARCHITECTURE.md:203-204`
**Type:** Behavioral / Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diagrammed unavailable-verifier response; does not establish anything about the verifier service internals documented below it.
**Replicate verdicts:** r1=Stale (compound Claim 22) · r2=Stale

Same finding as Claims 6/27: the unavailable-verifier response is now `{ valid: false, unavailable: true, reason: ... }` in all three failure modes (r1 E4 `r1-route-handler-exec.log`; r2 Cases A/B/E), built by:

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

The `{ valid: true, mock: true }` shape no longer exists in the codebase (`rg -n "mock: true" app/` matches only historical docs, not source — r2).

**Evidence:** `docs/ARCHITECTURE.md:203-204`, `app/api/verification/lean/route.ts:8-15`, r1-route-handler-exec.log, r2-route-no-env.txt, r2-route-stub-cases.txt

---

## Claim 30: "docker compose down         # Stop; app falls back to mock"

**Location:** `docs/ARCHITECTURE.md:234`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fallback annotation; the `docker compose down` command itself is not checked (Docker not exercised).
**Replicate verdicts:** r1=Stale · r2=— · single-replicate detection

Same refuted mechanism as Claims 2/6/27/29: stopping the verifier now yields `{ valid: false, unavailable: true, reason: "verifier-unreachable" }` (r1 E4 executed unreachable case, `r1-route-handler-exec.log`), not a mock. This ARCHITECTURE:234 annotation was harvested only by r1.

**Evidence:** `app/api/verification/lean/route.ts:53-56`, r1-route-handler-exec.log

---

## Claim 31: "Lean verifier is external and silently mocks success when unavailable"

**Location:** `docs/thoughts/feature-brainstorm.md:11`
**Type:** Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "silently mocks success" gap entry; the "external" half remains true and does not diverge the verdict (most-severe part carries: the mock half).
**Replicate verdicts:** r1=Stale · r2=— · single-replicate detection

This "known gap" was the very behavior removed by 5fe0dad. Unavailability is now explicit and surfaced (r1 E4 `r1-route-handler-exec.log` for the route; r1 E2 `r1-vitest-targeted.log` for the UI banner/badge). The verifier remains an external service (separate composed container per `docker-compose.yml:2-5`). The gap entry should be removed or marked resolved. (r1 — `docs/thoughts/feature-brainstorm.md` was outside r2's scope.)

**Evidence:** `app/api/verification/lean/route.ts:26-56`, r1-route-handler-exec.log, r1-vitest-targeted.log

---

## Claims Requiring Attention

### Stale
- **Claim 2** (`README.md:60`): "falls back to a mock response" — route now returns `{valid:false, unavailable:true, reason}`; update wording. *(r1 only)*
- **Claim 4** (`README.md:84`): default `http://localhost:3100` removed — unset env var now means verification disabled (`verifier-not-configured`), no default URL; note the Docker workflow now requires setting the var. *(both)*
- **Claim 6** (`README.md:92`): mock `{ valid: true, mock: true }` fallback no longer exists; rewrite the sentence. *(both)*
- **Claim 24** (`docs/USER_GUIDE.md:203`): no mock "valid" response; an amber "Verifier offline" state is shown instead (badge list also lacks the new state). *(r1 only)*
- **Claim 27** (`docs/USER_GUIDE.md:345`): "falls back to mock responses" outdated; also fix the mock framing at `docs/USER_GUIDE.md:332` and mention the env var in the setup steps — starting the Docker verifier without setting `LEAN_VERIFIER_URL` no longer works. *(both)*
- **Claim 28** (`docs/ARCHITECTURE.md:197-200`): request-flow diagram hardcodes `localhost:3100`; URL now comes only from `LEAN_VERIFIER_URL`. *(both)*
- **Claim 29** (`docs/ARCHITECTURE.md:203-204`): diagram's unavailable branch still shows the removed mock response. *(both)*
- **Claim 30** (`docs/ARCHITECTURE.md:234`): "app falls back to mock" annotation outdated. *(r1 only)*
- **Claim 31** (`docs/thoughts/feature-brainstorm.md:11`): "silently mocks success" known-gap entry is resolved by this change; remove or mark resolved. *(r1 only)*

### Mostly Accurate
- **Claim 9** (`app/api/verification/lean/route.ts:53-55`): the catch also swallows JSON-parse failures of a 2xx verifier response (`res.json()` is inside the try), labeling them `verifier-unreachable`; the comment names only network/timeout/DNS. *(r2 only — divergence winner)*
- **Claim 12** (`app/components/features/lean-display/LeanCodeDisplay.tsx:134`): banner cause list omits the reachable-but-errored (`verifier-error`) case. *(both)*
- **Claim 14** (`app/components/ui/VerificationBadge.tsx:15`): tooltip cause list omits the `verifier-error` case. *(both)*
- **Claim 16** (`app/lib/formalization/api.ts:107`): `unavailable` docstring omits the `verifier-error` case. *(both)*
- **Claim 18** (`app/lib/formalization/leanRetryLoop.ts:30-33`): docstring should note the loop does not retry when the verifier is unavailable. *(r1 only)*

### Unverifiable
- **Claim 1** (`README.md:60`): "type-checked by a real Lean 4 installation" — needs the Dockerized Lean verifier running; not available in the review sandbox.

---

## Verdict stability

- **Total merged clusters:** 31
- **Clusters reported by both replicates:** 22 (Claims 3-17, 19-21, 26-29; the compound claims r1-C3, r1-C21b, r1-C22, r2-C6 cluster with their atomic parts per decision 033)
- **Single-replicate clusters:** 9 — all from r1's broader harvest scope (Claims 1, 2, 18, 22, 23, 24, 25, 30, 31: README:60 both sentences, the retry-loop docstring, both commit messages, USER_GUIDE:203, USER_GUIDE:345 port sentence, ARCHITECTURE:234, feature-brainstorm:11). r2's narrower doc scope (no commit messages, no `docs/thoughts/`) accounts for these; none are conflicts.
- **Substantive disagreements:** 1 — **Claim 9** (route catch comment): r1=Verified, r2=Mostly accurate. Resolved most-severe-wins to Mostly accurate; r2's evidence (malformed-JSON 2xx responses land in the same catch, mislabeled `verifier-unreachable`) is a real coverage gap r1's analysis did not consider, and r1's Verified does not contradict it — r1 simply checked only the named failure classes.
- **Compound/atomic slicing reconciliations (not counted as substantive disagreements):** 3 clusters where a compound's verdict differs from an atomic part's verdict only because the compound's severity was carried by its *other* half, per each replicate's own Scope/analysis text:
  - **Claim 5** (README:92 "continues to work"): r1's compound Stale explicitly scoped out this half; r2=Verified carries.
  - **Claim 13** (banner remedy sentence): r2's compound Mostly-accurate explicitly attributed its imprecision to the cause list (Claim 12) and called the remedy accurate; r1=Verified carries. (A literal reading of most-severe-wins across the cluster would demote this to Mostly accurate; both replicates' own analyses affirm the remedy half, so severity was attributed to the part that carries it rather than duplicated across parts. Flagged here for auditability.)
  - **Claim 26** (USER_GUIDE:345 "automatically detects"): r1's compound Stale was carried by the mock-fallback half and its analysis states detection still occurs; r2=Verified carries.
- **Doc-staleness reconciliation (r1 8 Stale vs r2 5 Stale):** not a verdict conflict. r2's five Stale (14b, 15b, 16a, 16b, 17b) map onto four r1 clusters (2b, 3, 22-split-in-two, 21b) — identical verdicts on identical substance, sliced differently (r1 kept the ARCHITECTURE diagram as one compound; r2 split it). r1's remaining four Stale (Claims 2, 24, 30, 31) are distinct documentation locations outside r2's harvest, all reporting the same underlying mechanism (mock-fallback removal / default-URL removal). Merged Stale count is 9 because the diagram compound is carried as two atomic claims.
- **Agreement rate:** 21/22 both-replicate clusters agree on substance (95%); 18/22 (82%) under strict per-verdict-token comparison counting the three slicing reconciliations as disagreements. The single substantive disagreement is Verified-vs-Mostly-accurate — no cluster anywhere approached the Incorrect blocking channel (0 Incorrect from either replicate).

## Goal-Alignment Note
- Answered: yes — mechanical merge of r1 and r2 per the Stage-1 merge instructions, adapted to k=2.
- Out of scope: no re-verification of any claim; no reading of the target repository (blinded merge over the two replicate reports only).
- Escalate: nothing — 0 Incorrect verdicts, so the Fact-Check Gate does not trigger; the 9 Stale doc claims are for-author fixes.
