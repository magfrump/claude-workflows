# Code Fact-Check Report — Submitted Claims (Stage 2.5)

**Commit:** d90d6bb
**Repository:** /workspace/external/cc-review-eval/mfc-csp
**Scope:** `git diff d86d2dc...HEAD` — `app/layout.tsx`, `proxy.ts` (CSP proxy with per-request nonces). Endorsement claims routed by the Stage-2 critics (security-reviewer, performance-reviewer).
**Checked:** 2026-08-18
**Total claims checked:** 3 (submitted)
**Summary:** 3 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Stage-2.5 verdicting of the endorsement claims the critics routed via `route: code-fact-check`
(security-reviewer) and `[unverified — submitted as claim]` (performance-reviewer). Numbering
continues from the merged harvested report (`code-fact-check-report.md`, last harvested claim
15). api-consistency-review.md's "What Looks Good" bullets and test-strategy-review.md carry no
routing tag and are not submitted claims — untagged critic praise is not collected (Stage 2.5
step 1).

Where the merged report already executed a probe that covers a submitted claim's full wording,
this stage cites that executed evidence rather than re-running it, and states the residual in the
per-claim `Scope` line. No new probes were run; the target clone was left pristine (no `sc-`
evidence written).

---

## Submitted Claims

## Claim 16: "The per-request nonce is derived from `crypto.randomUUID()` (base64-encoded), i.e. from a cryptographic UUID source rather than `Math.random`/time."

**Submitted by:** security-reviewer
**Location:** `proxy.ts:37`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the emitted nonce is the base64 encoding of `crypto.randomUUID()` output — a v4-UUID cryptographic source, not `Math.random`/time — as read from the source line and observed fresh per matched request on both dev (r1) and prod (r2) servers; does not cover browser-side rejection of a non-nonced injected `<script>` (no browser in the sandbox — the critic scoped that as "not verified").

The merged report's Claim 7a quotes the generation site verbatim:

```ts
// proxy.ts:37
const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```

so the source is `crypto.randomUUID()` base64-encoded, with no `Math.random`/timestamp path. The merged report's executed Claims 7b and 1c confirm the emitted values are well-formed base64-of-UUID and distinct on consecutive requests (e.g. `'nonce-MWY1MjlhZDYtYWQyMy00ZjJjLWFlMzktZTEyZjdkZWIyNTgx'`, which decodes to UUID `1f529ad6-ad23-4f2c-ae39-e12f7deb2581`; `evidence/r2-curl-probes.log`, `evidence/r1-nonce-freshness.txt`). The submitted claim's full wording — cryptographic-UUID source, base64-encoded, per request — is covered by these merged executed verdicts (7a Verified/High, 7b Verified/High, 1c Verified/High). Citation matches: the claim asserts nothing beyond what 7a/7b/1c establish.

**Evidence:** `proxy.ts:37`, `code-fact-check-report.md` Claims 7a/7b/1c, `evidence/r1-nonce-freshness.txt`, `evidence/r2-curl-probes.log`

---

## Claim 17: "Every Next-generated `<script>` tag in the served `/` document carries the nonce matching that response's CSP header, and no app code reads `x-nonce` itself."

**Submitted by:** security-reviewer
**Location:** `app/layout.tsx:28-31`, `proxy.ts:41-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rendered HTML of `/` on both the dev server (r1) and the production server (r2) — every `<script>` tag nonced with the value from the same response's CSP header, and a repo-wide grep finding no app code that reads `x-nonce`; does not establish browser-side execution of those scripts, nor script tags emitted during client-side navigation to a different route (only `/` was captured — the critic scoped both as "not verified").

This is the exact assertion the merged report's Claim 2 verdicted Verified (executed), reproduced on both replicates. r2 (production) shows every generated `<script>` carrying a nonce byte-identical to the response CSP header (`evidence/r2-html-nonce-check.log`, `evidence/r2-root-headers.txt`); r1 (dev) audited 36 `<script>` tags with 0 lacking a `nonce=` attribute and a single distinct nonce equal to the header's (`evidence/r1-script-nonce-audit.txt`). The "no app code reads `x-nonce`" half is covered by Claim 2's grep evidence: `rg -rn "x-nonce" app proxy.ts` returns only the `proxy.ts` set-site and the `app/layout.tsx` comment, no consumer. Citation matches the submitted claim's full wording (script-tag nonce coverage on `/` + absence of an `x-nonce` reader).

**Evidence:** `code-fact-check-report.md` Claim 2 (and Claim 12), `evidence/r2-html-nonce-check.log`, `evidence/r2-root-headers.txt`, `evidence/r1-script-nonce-audit.txt`, `node_modules/next/dist/server/app-render/app-render.js:166-167`

---

## Claim 18: "Removing the `x-nonce` forwarding block (`proxy.ts:41-45`, replacing `NextResponse.next({ request: ... })` with bare `NextResponse.next()`) would leave the served CSP header and the rendered HTML's script nonces unchanged, because no server component reads `x-nonce` and Next sources the nonce from the response CSP header."

**Submitted by:** performance-reviewer
**Location:** `proxy.ts:41-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the served CSP header and Next's script-nonce tagging are, per the merged report's executed evidence, both sourced independently of the `x-nonce` request-header override — so removing the override cannot change either; does not include an executed counterfactual build (the edit was not applied/rebuilt/served — the residual left to Scope per the Stage-2.5 counterfactual guidance), hence Confidence Medium rather than High.

The counterfactual is logically closed by two executed merged verdicts, so the expensive probe was not run:

1. **Served CSP header is independent of the request override.** The response CSP header is set by `response.headers.set("Content-Security-Policy", buildCsp(nonce))` on the response object (merged Claim 13 quotes the exact set-site). The `nonce` is generated at `proxy.ts:37` and the header is built from it regardless of whether the request headers are cloned/overridden. The `request: ...` argument to `NextResponse.next()` overrides only the *request* headers passed downstream — it is not an input to the response CSP header. Replacing it with bare `NextResponse.next()` leaves the nonce generation and the response-header set untouched.

2. **Rendered script nonces are sourced from the response CSP header, not `x-nonce`.** Merged Claim 2 (executed) establishes Next extracts the script nonce from the response's `content-security-policy` header (`node_modules/next/dist/server/app-render/app-render.js:166-167`), and that no app code reads `x-nonce`. Merged Claim 8 confirms `x-nonce` is set on the forwarded request but has no consumer (`app/layout.tsx:28-30` states it is not needed). Since nothing reads `x-nonce`, removing its forwarding cannot change what Next reads; the script nonces stay tied to the response CSP header, which by (1) is unchanged.

Both halves of the submitted claim (served CSP unchanged; rendered script nonces unchanged) therefore follow from the merged report's executed evidence that Next sources the nonce from the response CSP header, not `x-nonce`. The only residual — that no build with the edit applied was actually served and diffed — is scoped above and drives the Medium confidence.

**Evidence:** `code-fact-check-report.md` Claim 2, Claim 8, Claim 13; `node_modules/next/dist/server/app-render/app-render.js:166-167`; `proxy.ts:37`, `proxy.ts:41-47`; `app/layout.tsx:28-30`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.

All three routed endorsement claims verdicted **Verified**. Claims 16 and 17 carry executed
backing (via the merged report's Stage-1 probes); Claim 18 is a counterfactual verdicted static
with Medium confidence — logically established by executed Claims 2/8/13, residual (no probe
build) noted in Scope.
