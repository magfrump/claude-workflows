# Code Fact-Check Report

**Commit:** c95c9cb
**Repository:** /workspace/external/cc-review-eval/mfc-lean
**Scope:** Stage 2.5 submitted-claims pass — 6 endorsement claims routed by critics (5 from security-review.md, 1 from performance-review.md); verdicted against the target repo at HEAD and the executed evidence in the merged Stage-1 report (`code-fact-check-report.md`, same commit). api-consistency-review.md and ui-visual-review.md contain no `route: code-fact-check` or `[unverified — submitted as claim]` tags — nothing to collect from them.
**Checked:** 2026-08-17
**Total claims checked:** 8 (6 submitted; the performance claim is compound and split into Claims 37a/37b/37c)
**Summary:** 7 verified, 0 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Numbering continues from the merged Stage-1 report (Claims 1-31). Where a security claim cites
already-executed Stage-1 evidence, the citation was checked against the merged report's claim text,
evidence files, and execution-provenance block; nothing was re-run for those. New execution for this
pass (both leaving the clone pristine; evidence dir `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/evidence/`):

- SC-E1 — captured grep/config sweep for `maxDuration` / `vercel.json` / route config exports — cwd `/workspace/external/cc-review-eval/mfc-lean` — rg exits 1 (no matches), `ls vercel.json` exit 2 (absent) — 2026-08-18T06:42:58Z — `sc-grep-maxduration.txt`
- SC-E2 — scratch vitest `__sc_scratch.test.ts` (deleted after run; `git status` clean): non-JSON route responses vs `verifyLean` and `leanRetryLoop` — `npx vitest run __sc_scratch.test.ts --reporter=verbose`, cwd `/workspace/external/cc-review-eval/mfc-lean`, exit 0, 3/3 passed — 2026-08-18T06:43:42Z — `sc-vitest-nonjson.log`
- WebFetch to Vercel documentation (three URLs under vercel.com/docs) failed — no network access from this sandbox — so platform-limit documentation claims could not be verified externally.

---

## Submitted Claims

## Claim 32: "For each of the three verifier-failure modes (env unset, connection refused, verifier HTTP 500), the route's response body sets `valid: false` and `unavailable: true`."

**Submitted by:** security-reviewer
**Location:** `app/api/verification/lean/route.ts:7-14,26-30,45-49,53-56`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the response bodies of the three exercised failure modes (env unset, connection refused, verifier HTTP 500) under real handler execution and live HTTP; does not establish 2xx-passthrough responses (a reachable verifier's body — including `valid: true` — passes through unvalidated, `route.ts:51-52`, the critic's own Not-verified line) nor separately exercise the timeout/DNS sub-cases of the catch block.

The citation (merged report Claims 6, 7, 8, 22) fully covers the claim's wording. Merged Claim 6
(executed, both replicates): "all three failure modes over live HTTP: unset env →
`verifier-not-configured` (Case E), unreachable → `verifier-unreachable` (Case A), verifier HTTP 500
→ `verifier-error` with `detail: \"HTTP 500\"` (Case B); no response contained `valid: true` or a
`mock` field" (`code-fact-check-report.md`, Claim 6). Claim 7 covers env-unset, Claim 8 the HTTP-500
mapping ("`{ valid: false, unavailable: true, reason: \"verifier-error\", detail: \"HTTP 500\" }`"),
and Claim 22 the three-reason taxonomy with the shared payload shape built by `unavailableResponse`
(`app/api/verification/lean/route.ts:8-15`, quoted in merged Claim 29). Execution provenance: r1 E4
scratch route-handler vitest executing the real `POST` (cwd `/workspace/external/cc-review-eval/mfc-lean`, exit 1 — pre-run jsdom warning, 5/5 passed, 2026-08-18T06:25:11Z, `r1-route-handler-exec.log`); r2 live `next dev` + curl Cases A/B/E (2026-08-18T06:23:56Z–06:25:36Z, `r2-route-with-env.txt`, `r2-route-stub-cases.txt`, `r2-route-no-env.txt`).

**Evidence:** `code-fact-check-report.md` (Claims 6, 7, 8, 22), `app/api/verification/lean/route.ts:8-15`, r1-route-handler-exec.log, r2-route-with-env.txt, r2-route-stub-cases.txt, r2-route-no-env.txt

---

## Claim 33: "`verifyResultToStatus` returns `\"unavailable\"` for every input where `unavailable` is truthy, regardless of `valid`."

**Submitted by:** security-reviewer
**Location:** `app/lib/formalization/api.ts:115-118`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Executed coverage is the four boolean flag combinations; the "every truthy input" generalization beyond booleans rests on static reading of the guard clause; does not establish callers that bypass this helper (`leanRetryLoop` reads `unavailable` directly, `leanRetryLoop.ts:73-77` — the critic's own Not-verified line).

The citation (merged report Claim 17) covers the claim. Both replicates ran independent scratch unit
tests asserting all four combinations — `{valid:true, unavailable:true}` → `"unavailable"`,
`{valid:false, unavailable:true}` → `"unavailable"`, `{valid:true}` → `"valid"`, `{valid:false}` →
`"invalid"` — all passed (r1 E3, exit 1 — jsdom warning, 6/6 passed, 2026-08-18T06:23:43Z,
`r1-vitest-scratch.log`; r2 scratch unit test, exit 0, 5/5 passed, 2026-08-18T06:23:06Z,
`r2-vitest-scratch-unit.txt`). The "every truthy input" breadth beyond `true` follows from the
implementation's unconditional guard:

```ts
// app/lib/formalization/api.ts:115-118
export function verifyResultToStatus(result: { valid: boolean; unavailable?: boolean }): VerificationStatus {
  if (result.unavailable) return "unavailable";
  return result.valid ? "valid" : "invalid";
}
```

**Evidence:** `code-fact-check-report.md` (Claim 17), `app/lib/formalization/api.ts:115-118`, r1-vitest-scratch.log, r2-vitest-scratch-unit.txt

---

## Claim 34: "When `verifyLean` reports `unavailable`, `leanRetryLoop` returns after exactly one generation and one verification call, with `errors: \"\"`."

**Submitted by:** security-reviewer
**Location:** `app/lib/formalization/leanRetryLoop.ts:71-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a single sequential invocation with generation stubbed and verification returning `unavailable` on the first attempt; does not cover concurrent invocations or cancellation/abort interaction (the critic's own Not-verified line), nor an `unavailable` first appearing on a later attempt.

The citation (merged report Claims 19, 20) fully covers the wording. Call counts executed by both
replicates: r1 "fetch-call accounting showed exactly one call to `/api/formalization/lean` and one to
`/api/verification/lean`, no retries, `onErrors(\"\")` observed once" (E3, exit 1 — jsdom warning,
6/6 passed, 2026-08-18T06:23:43Z, `r1-vitest-scratch.log`); r2 "`expect(vi.mocked(verifyLean)).toHaveBeenCalledTimes(1)` passed with `verifyLean` mocked always-unavailable, out of a possible `MAX_LEAN_ATTEMPTS = 3`" (exit 0, 5/5 passed, `r2-vitest-scratch-unit.txt`). The `errors: ""` half is in the executed return object of merged Claim 19: "the loop returned `{ valid: false, code: <generated code>, errors: \"\", unavailable: true }`", matching the single exit path:

```ts
// app/lib/formalization/leanRetryLoop.ts:73-77
if (unavailable) {
  // No point retrying — the proof was never actually checked.
  onErrors("");
  return { valid: false, code: currentCode, errors: "", unavailable: true };
}
```

**Evidence:** `code-fact-check-report.md` (Claims 19, 20), `app/lib/formalization/leanRetryLoop.ts:73-77`, r1-vitest-scratch.log, r2-vitest-scratch-unit.txt

---

## Claim 35: "With status `\"unavailable\"`, the rendered output contains the amber \"Verifier offline\" surface and does not contain the text \"Verified\"."

**Submitted by:** security-reviewer
**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:131-138`, `app/components/ui/VerificationBadge.tsx:11-19`, `app/components/panels/OutputPanel.test.tsx:112-116`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `OutputPanel`/`LeanCodeDisplay`/`VerificationBadge` render trees under vitest/jsdom component tests; does not establish other components that read `verificationStatus` outside these trees (the critic's own Not-verified line) nor full-browser rendering.

The citation (merged report Claim 11) covers both halves of the wording: the amber-banner test
("shows the verifier-offline banner when status is unavailable") and OutputPanel's "'shows
\"Verifier offline\" for unavailable status (not a passing badge)' — which additionally asserts
`queryByText('Verified')` is absent (`app/components/panels/OutputPanel.test.tsx:112-116`)" — all
passing in both replicates' suite runs (r1 E2 targeted vitest, exit 1 — jsdom warning, 55/55 passed,
2026-08-18T06:22:50Z, `r1-vitest-targeted.log`; r2, exit 0, 55/55 passed, 2026-08-18T06:22:42Z,
`r2-vitest-existing-tests.txt`). The banner and badge branches are gated on the `unavailable` status
(`LeanCodeDisplay.tsx:131-136` and `VerificationBadge.tsx:11-17`, both quoted in merged Claims 11/14).

**Evidence:** `code-fact-check-report.md` (Claim 11), `app/components/panels/OutputPanel.test.tsx:112-116`, r1-vitest-targeted.log, r2-vitest-existing-tests.txt

---

## Claim 36: "With `LEAN_VERIFIER_URL` unset, the route returned `verifier-not-configured` while a listener on `127.0.0.1:3100` recorded zero incoming requests."

**Submitted by:** security-reviewer
**Location:** `app/api/verification/lean/route.ts:26-30`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this route's behavior under the r2 live-server run (and r1's real-handler equivalent without the detector); does not establish that no other route or code path contacts a hardcoded verifier URL (the critic's own Not-verified line).

The citation (merged report Claims 4, 7) matches the claim's wording exactly — it is a direct restatement
of r2's Case E observation: "with the var unset and a detector stub listening on `127.0.0.1:3100`, the
route returned `verifier-not-configured` and the stub log recorded zero incoming requests" (merged
Claim 4; run: fresh server via `env -u LEAN_VERIFIER_URL npx next dev -p 4460` + detector stub on
3100, 2026-08-18T06:25:36Z, `r2-route-no-env.txt`, stub log `r2-stub-3100.log`). r1 E4 independently
observed the same response with the env var deleted and no network attempt
(`r1-route-handler-exec.log`, 2026-08-18T06:25:11Z). The short-circuit precedes any fetch
(`app/api/verification/lean/route.ts:26-30`, quoted in merged Claim 7).

**Evidence:** `code-fact-check-report.md` (Claims 4, 7), `app/api/verification/lean/route.ts:26-30`, r2-route-no-env.txt, r2-stub-3100.log, r1-route-handler-exec.log

---

## Claim 37: "On a default Vercel Node.js deployment of this repo (no `maxDuration` export in `app/api/verification/lean/route.ts` and no duration override in the repo), the platform's default function duration limit is below `REQUEST_TIMEOUT_MS = 35_000` ms, so the route's abort timer never fires there and hung-verifier requests surface to `verifyLean` as platform errors (non-JSON), which throw and are recorded as status `invalid` rather than `unavailable`."

**Submitted by:** performance-reviewer
Compound claim — split per the compound-claims rule into 37a (repo-configuration premise), 37b
(platform duration-limit premise), and 37c (repo-side error-path mechanism). The chain's overall
conclusion inherits 37b's Unverifiable: the repo-side halves are established, but whether the chain
fires on a real default Vercel deploy depends on the unverified platform limit.

## Claim 37a: "no `maxDuration` export in `app/api/verification/lean/route.ts` and no duration override in the repo"

**Submitted by:** performance-reviewer
**Location:** `app/api/verification/lean/route.ts`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of `maxDuration`, `vercel.json`, route segment-config exports, and any Next-config duration setting in the repo at HEAD; does not establish limits configured outside the repo (Vercel project dashboard settings).

Executed sweep (SC-E1, `sc-grep-maxduration.txt`, cwd `/workspace/external/cc-review-eval/mfc-lean`,
2026-08-18T06:42:58Z): `rg -n "maxDuration"` over the repo (excluding `node_modules`/`.git`) → no
matches, exit 1; `ls vercel.json` → "No such file or directory", exit 2; `rg -n "export const
(config|runtime|maxDuration|dynamic)" app/` → no matches, exit 1; `next.config.ts` contains only an
empty options object (`next.config.ts:3-5`: `const nextConfig: NextConfig = { /* config options here */ };`).

**Evidence:** sc-grep-maxduration.txt, `next.config.ts:1-7`, `app/api/verification/lean/route.ts:3`

## Claim 37b: "the platform's default function duration limit is below `REQUEST_TIMEOUT_MS = 35_000` ms, so the route's abort timer never fires there"

**Submitted by:** performance-reviewer
**Location:** `app/api/verification/lean/route.ts:3` (constant); Vercel platform documentation (external)
**Type:** Configuration / Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** What is establishable in-repo: `REQUEST_TIMEOUT_MS = 35_000` (`route.ts:3`) and that no repo file raises or sets a duration limit (Claim 37a). Not establishable here: Vercel's current default function duration limit — an external platform-documentation fact.

Blocker: the premise is a claim about Vercel's platform defaults, which live in Vercel's
documentation/dashboard, not in this repo. WebFetch to vercel.com documentation failed three times
(no network access from this sandbox), so no current, citable value could be obtained. The value is
also plan- and configuration-dependent (paraphrased — no quote available because the source is
external documentation unreachable from this sandbox): Vercel has historically used low defaults
(~10-15 s) that would make the claim true, but deployments with fluid compute — which Vercel has
made the default for newer projects — carry default limits well above 35 s, which would make the
claim false for those deploys (the abort timer at `route.ts:33-34` would fire first). Because the
claim's truth flips on plan/era/fluid-compute status and no authoritative source was reachable, the
verdict is Unverifiable, not Incorrect. To verify: fetch Vercel's "Configuring maximum duration"
docs (default and max `maxDuration` per plan, fluid vs non-fluid) or inspect the actual Vercel
project settings for this repo's deployment.

**Evidence:** `app/api/verification/lean/route.ts:3`, `app/api/verification/lean/route.ts:33-34`, sc-grep-maxduration.txt

## Claim 37c: "hung-verifier requests surface to `verifyLean` as platform errors (non-JSON), which throw and are recorded as status `invalid` rather than `unavailable`"

**Submitted by:** performance-reviewer
**Location:** `app/lib/formalization/api.ts:120-132`, `app/hooks/useFormalizationPipeline.ts:127-132`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo-side chain *given* a non-JSON response from `/api/verification/lean`: `verifyLean` throws (executed, 504 and 200 non-JSON bodies), the throw propagates uncaught through `leanRetryLoop` bypassing the `unavailable` exit (executed), and the pipeline hook's catch blocks record status `"invalid"` (static); does not establish that a platform-terminated Vercel function actually returns a non-JSON body to the client (external, tied to 37b), nor the `!currentLean` sub-branch that overwrites the editor instead.

Executed (SC-E2, scratch vitest `__sc_scratch.test.ts`, deleted after run; `npx vitest run
__sc_scratch.test.ts --reporter=verbose`, cwd `/workspace/external/cc-review-eval/mfc-lean`, exit 0,
3/3 passed, 2026-08-18T06:43:42Z, `sc-vitest-nonjson.log`): with `fetch` stubbed to return a 504
`text/plain` body (`FUNCTION_INVOCATION_TIMEOUT` shape) and a 200 non-JSON body, `verifyLean`
rejected in both cases — it has no `res.ok` check and no try/catch:

```ts
// app/lib/formalization/api.ts:126
const data = await res.json();
```

— and the rejection propagated out of `leanRetryLoop` with `onErrors` never called, i.e. the
`unavailable: true` exit path (`leanRetryLoop.ts:73-77`) was never taken. The recording step is
static: the pipeline's catch blocks map any thrown error to `"invalid"`:

```ts
// app/hooks/useFormalizationPipeline.ts:127-132
} catch (err) {
  const msg = err instanceof Error ? err.message : "Request failed";
  const currentLean = a.getLeanCode();
  if (!currentLean) a.setLeanCode(`-- Error: ${msg}`);
  else { a.setVerificationStatus("invalid"); a.setVerificationErrors(msg); }
  a.onSessionUpdate?.({ verificationStatus: "invalid", verificationErrors: msg });
}
```

The manual Re-verify path behaves the same (`useFormalizationPipeline.ts:162-166`:
`a.setVerificationStatus("invalid")` in its catch). So wherever a hung request does produce a
non-JSON response, the new `unavailable` taxonomy is bypassed and the failure reads as a failed
proof — exactly the critic's asserted mechanism.

**Evidence:** sc-vitest-nonjson.log, `app/lib/formalization/api.ts:120-132`, `app/lib/formalization/leanRetryLoop.ts:70-77`, `app/hooks/useFormalizationPipeline.ts:127-132`, `app/hooks/useFormalizationPipeline.ts:162-166`

---

## Claims Requiring Attention

### Unverifiable
- **Claim 37b** (`app/api/verification/lean/route.ts:3` / external Vercel docs): Vercel's default function-duration limit vs the 35 s route timeout could not be verified — no network access to Vercel documentation from this sandbox, and the value is plan/fluid-compute dependent. Needed: current Vercel duration docs or the deployment's project settings. Until then the performance claim's conclusion is *pending execution verification*, not a confirmation — though its repo-side halves (37a, 37c) are established and the 37c mechanism (non-JSON → status `"invalid"`) is a real taxonomy bypass wherever the premise holds.
