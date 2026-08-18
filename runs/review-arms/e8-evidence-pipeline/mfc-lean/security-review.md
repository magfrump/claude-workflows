# Security Review — mfc-lean Lean-verifier error handling (`d86d2dc...c95c9cb`)

**Commit:** c95c9cb
**Scope:** `git diff d86d2dc...HEAD` in `/workspace/external/cc-review-eval/mfc-lean` (10 files: verification route, status taxonomy, retry-loop short-circuit, persistence-sanitizer test, UI surfaces)
**Date:** 2026-08-17
**Based on:** merged code-fact-check report (`code-fact-check-report.md`, commit c95c9cb, k=2, 31 claims — its verdicts bind; behavior it executed is not re-verified here)

## Trust Boundary Map

```
B1 (moved):  [unauthenticated client HTTP POST /api/verification/lean, leanCode]
             → [type check: leanCode is non-empty string, route.ts:19-24]
             → [forwarded verbatim to `${LEAN_VERIFIER_URL}/verify`, route.ts:36-41]
B2 (moved):  [verifier HTTP response] → [ok-check + res.json(), route.ts:45-52]
             → [passed through unvalidated to client → Boolean-coerced in verifyLean, api.ts:126-131]
B3:          [localStorage persisted state] → [sanitizeVerificationStatus + type coercers
             on the legacy workspace-v2 load path ONLY, workspacePersistence.ts:34-37,182]
             → [in-memory store → VerificationBadge / banner UI]
             ⚠ two live persistence paths skip the sanitizer entirely (Finding 1)
B4 (new):    [LEAN_VERIFIER_URL env var] → [presence check, route.ts:26-30] → [fetch target]
             (default http://localhost:3100 removed — unset now fails closed to
             "verifier-not-configured" with zero outbound requests, fact-check Claim 4)
```

What enters from outside: attacker-shapeable `leanCode` on B1; verifier-controlled JSON on B2; user/extension-writable localStorage on B3; operator-controlled config on B4. The diff's central trust move is correct in direction: every verifier-failure mode now fails closed to `valid:false, unavailable:true` instead of the old fabricated `{valid:true, mock:true}` (fact-check Claims 2/6/22, executed). The residual assumptions are that verifier 2xx bodies are well-shaped (B2) and that persisted status went through the sanitizer (B3) — the second assumption is false on the live paths.

## Findings

#### 1. `sanitizeVerificationStatus` guards only the legacy persistence path — both live localStorage paths persist and restore `unavailable`/`verifying` raw

**Severity:** Medium
**Location:** `app/lib/stores/workspaceStore.ts:313` (persist `partialize`), `app/hooks/useWorkspacePersistence.ts:22` (rehydrate), `app/hooks/useFormalizationSessions.ts:8,52,15-16` (sessions store), `app/hooks/useFormalizationPipeline.ts:126,144` (diff wires `vStatus` — including `"unavailable"` — into `onSessionUpdate`)
**Boundary:** B3
**Move:** #11 (bypass enumeration — BC6/BC7 below)
**Confidence:** High (static trace of both paths; not exercised in a browser)

The diff's persistence guarantee ("maps 'unavailable' to 'none' — transient verifier-state, not artifact-state", `workspacePersistence.test.ts:32-34`, fact-check Claim 21 Verified) holds only for `saveWorkspace`/`loadWorkspace` — the **legacy workspace-v2 migration path**. The app's live persistence is (a) the Zustand persist middleware (`workspace-zustand-v1`), whose `partialize` writes `verificationStatus: state.verificationStatus` with no sanitizer and whose rehydrate restores it verbatim, and (b) the formalization-sessions store, which persists raw session objects (`JSON.parse(raw) as ...`, no sanitizer on save or load) — and the diff itself feeds `vStatus` (which can be `"unavailable"`) into `onSessionUpdate`. So the new transient status is persisted as artifact-state on both live paths; a reload restores "Verifier offline — proof not checked" (or a stuck `verifying`) for a session in which no verification was attempted. The passing test verifies a path the app no longer routes normal saves through, which overstates the guarantee the guardrail provides.

**Recommendation:** Apply `sanitizeVerificationStatus` in the Zustand `partialize` (or on rehydrate) and on the formalization-sessions load path; add tests against those paths, not only the legacy one.

#### 2. Persisted `valid` status is not bound to the code it endorsed — edit-then-reload shows "Verified" for never-checked code

**Severity:** Medium
**Location:** `app/lib/utils/workspacePersistence.ts:34-37`, `app/lib/stores/workspaceStore.ts:313`, `app/page.tsx:408-414` (`handleLeanCodeChange` never resets status), `app/components/features/lean-display/LeanCodeDisplay.tsx:31` (`leanEdited` is transient React state)
**Boundary:** B3
**Move:** #4 (time-of-check to time-of-use)
**Confidence:** Medium (load-side executed — probe BC5, `sec-vitest-sanitizer.log`; full in-browser edit→reload flow not exercised; pre-existing, not introduced by this diff)

The verification verdict and the verified code persist as independent fields with no binding (hash, or status reset on code change). `handleLeanCodeChange` updates `leanCode` without touching `verificationStatus`; the only "stale" signal, `leanEdited`, is component state and is lost on reload. A user who verifies (status `valid`), edits the Lean code, and reloads gets a green "Verified" badge on code the verifier never saw — and no Re-verify button, since `leanEdited` is false and status is `valid` (`LeanCodeDisplay.tsx:111`). Executed probe BC5 confirmed the load half: a persisted payload with status `valid` and altered `leanCode` loads with status `valid` intact. This is the same property this diff exists to protect ("a missing verifier never reads as a passing proof") violated through the persistence sibling path. Pre-existing, but the diff's taxonomy work is the natural place to close it.

**Recommendation:** Reset `verificationStatus` to `"none"` in `handleLeanCodeChange` (and the node-edit equivalent), or persist a hash of the verified code and downgrade status on mismatch at load.

#### 3. Unauthenticated proxy of arbitrary code to the Lean verifier with a 35s held connection and no rate limit

**Severity:** Medium
**Location:** `app/api/verification/lean/route.ts:16-41`
**Boundary:** B1
**Move:** #8 (what if there are a million of these?)
**Confidence:** Low (pre-existing surface — the diff changes only the error mapping; verifier sandboxing unverifiable per fact-check Claim 1)

Any client can POST arbitrary `leanCode` and have the route hold a connection to the verifier for up to `REQUEST_TIMEOUT_MS = 35_000` per request, with no rate limiting, body-size limit, or auth. Lean elaboration is attacker-steerable heavy compute (and Lean metaprogramming can reach the filesystem inside the verifier container), so the route is both a DoS amplifier against the verifier and a free compute/probing proxy when deployed with a configured verifier. Noted for completeness: this diff did not add the surface, and the not-configured short-circuit (B4) actually removes the default outbound target on unconfigured deploys.

**Recommendation:** Rate-limit and cap request body size on the verification route before any internet-facing deploy with `LEAN_VERIFIER_URL` set; treat the verifier container's sandboxing as an open verification item (fact-check Claim 1 is Unverifiable).

#### 4. Verifier 2xx responses are passed through to the client unvalidated

**Severity:** Low
**Location:** `app/api/verification/lean/route.ts:51-52`
**Boundary:** B2
**Move:** #7 (serialization boundary)
**Confidence:** High

On `res.ok`, the route returns the verifier's JSON body verbatim with no shape validation — whatever entity `LEAN_VERIFIER_URL` names fully controls the client-visible payload, including `valid: true` for unchecked code. Exploitation requires controlling the env var or the verifier host (operator-trust territory, hence Low rather than the Medium floor — the attacker must already control config/host). Two mitigations already hold: `verifyLean` coerces to `Boolean(data.valid)`/`Boolean(data.unavailable)` and defaults `errors` to `""` (fact-check Claim 16), and a 2xx body that fails `res.json()` lands in the catch and fails closed as `verifier-unreachable` (fact-check Claim 9 — mislabeled, but safe-direction). Rendered `errors` text goes through React text nodes, so markup injection is escaped.

**Recommendation:** Validate the passthrough shape (`{valid: boolean, errors?: string}`) in the route and reject/relabel anything else; optionally split the JSON-parse failure out of the `verifier-unreachable` label per fact-check Claim 9.

## Move #11 — Guardrail bypass enumeration: `sanitizeVerificationStatus`

Guardrail: `app/lib/utils/workspacePersistence.ts:34-37` (allowlist `valid`/`invalid`, everything else → `none`); the diff adds the `unavailable → none` contract test. Seven candidates enumerated; probes captured to `evidence/sec-vitest-sanitizer.log` (scratch file `__sec_scratch.test.ts`, 5/5 passed, deleted after run; tree left clean).

| # | Candidate | Dispatch | Outcome |
|---|-----------|----------|---------|
| BC1 | Case/whitespace variants (`"VALID"`, `" valid"`, `"valid\n"`) | **Tested** (executed) | Fail closed → `"none"` |
| BC2 | Coercing non-primitives (`new String("valid")`, `{toString: () => "valid"}`, `undefined`, `null`, `0`) | **Tested** (executed) | Fail closed → `"none"` (strict `===`, no coercion) |
| BC3 | Sanitizer-skipping writer of the workspace-v2 key (raw `"unavailable"`/`"verifying"` payload) | **Tested** (executed) | Re-sanitized on load → `"none"`; companion `verificationErrors` retained un-sanitized (render-gated on `invalid && errors`, so not displayed) |
| BC4 | Non-string persisted status (object) on the v2 load path | **Tested** (executed) | Coerced to `""` before sanitizing → `"none"` |
| BC5 | Allowlisted `"valid"` with swapped `leanCode` (no status↔code binding) | **Tested** (executed) | Bypass of the *intent* confirmed → Finding 2 |
| BC6 | Zustand persist path (`workspace-zustand-v1` `partialize`/rehydrate) skipping the sanitizer | **Tested** (static trace: `workspaceStore.ts:313`, `useWorkspacePersistence.ts:22`; no sanitizer present) | Bypass confirmed → Finding 1 |
| BC7 | Formalization-sessions store persisting raw `verificationStatus` from `onSessionUpdate` | **Tested** (static trace: `useFormalizationSessions.ts:8,15-16,52`; diff wires `vStatus` in at `useFormalizationPipeline.ts:126,144`) | Bypass confirmed → Finding 1 |

### Untested bypass candidates

- **In-browser end-to-end rehydrate of BC6/BC7** — a live session that reaches `"unavailable"`, persists via the Zustand/sessions stores, and reloads. Not tested: requires a driven browser session; the static trace (both writers lack any sanitizer call) is recorded under Finding 1 instead of an executed fixture.
- **UI rendering of retained `verificationErrors` alongside sanitized `"none"` status (BC3 residue)** — gate `verificationStatus === "invalid" && verificationErrors` (`LeanCodeDisplay.tsx:146`) read statically; not render-tested for every consumer of `verificationErrors`.

Because BC6/BC7 are *confirmed* bypasses, the sanitizer carries no endorsement claim below beyond an explicitly path-scoped one.

## Endorsement Claims

- **Claim:** For each of the three verifier-failure modes (env unset, connection refused, verifier HTTP 500), the route's response body sets `valid: false` and `unavailable: true`.
  **Location:** `app/api/verification/lean/route.ts:7-14,26-30,45-49,53-56`
  **Evidence:** executed (fact-check Claims 6/7/8/22 — r1 E4 real-handler run; r2 live-HTTP Cases A/B/E)
  **Verified:** all three failure payloads observed under real execution; no response contained `valid: true` or a `mock` field.
  **Not verified:** verifier 2xx responses — the passthrough at `route.ts:51-52` can still deliver arbitrary `valid` values from a controlled verifier (Finding 4).
  **route: code-fact-check** (already verdicted: report Claims 6, 7, 8, 22)

- **Claim:** `verifyResultToStatus` returns `"unavailable"` for every input where `unavailable` is truthy, regardless of `valid`.
  **Location:** `app/lib/formalization/api.ts:115-118`
  **Evidence:** executed (fact-check Claim 17 — both replicates' scratch tests, all four flag combinations)
  **Not verified:** callers that consume `verifyLean` flags without this helper — `leanRetryLoop` reads `unavailable` directly (`leanRetryLoop.ts:71-77`), and any future caller is one hop away.
  **route: code-fact-check** (already verdicted: report Claim 17)

- **Claim:** When `verifyLean` reports `unavailable`, `leanRetryLoop` returns after exactly one generation and one verification call, with `errors: ""`.
  **Location:** `app/lib/formalization/leanRetryLoop.ts:71-77`
  **Evidence:** executed (fact-check Claims 19/20 — call-count accounting in both replicates)
  **Not verified:** concurrent invocations of the loop (no cancellation/abort interaction was exercised).
  **route: code-fact-check** (already verdicted: report Claims 19, 20)

- **Claim:** With status `"unavailable"`, the rendered output contains the amber "Verifier offline" surface and does not contain the text "Verified".
  **Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:131-138`, `app/components/ui/VerificationBadge.tsx:11-19`, `app/components/panels/OutputPanel.test.tsx:112-116`
  **Evidence:** executed (fact-check Claim 11 — component tests passing in both replicates, including the `queryByText('Verified')` absence assertion)
  **Not verified:** other components that read `verificationStatus` outside `OutputPanel`/`LeanCodeDisplay`/`VerificationBadge` (e.g., node-level or analytics surfaces) — one hop away.
  **route: code-fact-check** (already verdicted: report Claim 11)

- **Claim:** On the legacy workspace-v2 load path, `loadWorkspace` maps the persisted statuses `"unavailable"`, `"verifying"`, case-variant strings, and non-string values to `"none"`.
  **Location:** `app/lib/utils/workspacePersistence.ts:34-37,182-184`
  **Evidence:** executed (this review — probes BC1-BC4, `evidence/sec-vitest-sanitizer.log`, 5/5 passed)
  **Verified:** direct calls and full `localStorage → loadWorkspace` round-trips for those inputs on that path.
  **Not verified:** the Zustand persist and formalization-sessions paths — confirmed to skip the sanitizer (Finding 1), so this claim is deliberately scoped to the legacy path and licenses nothing about live persistence.

- **Claim:** With `LEAN_VERIFIER_URL` unset, the route returned `verifier-not-configured` while a listener on `127.0.0.1:3100` recorded zero incoming requests.
  **Location:** `app/api/verification/lean/route.ts:26-30`
  **Evidence:** executed (fact-check Claim 4/7 — r2 Case E detector stub; r1 E4)
  **Not verified:** other routes or code in the app that might still contact a hardcoded verifier URL — only this route was exercised.
  **route: code-fact-check** (already verdicted: report Claims 4, 7)

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Live persistence paths (Zustand persist, formalization sessions) bypass `sanitizeVerificationStatus` | Medium | B3 | `workspaceStore.ts:313`, `useFormalizationSessions.ts:52` | High |
| 2 | Persisted `valid` not bound to `leanCode` — edit-then-reload shows "Verified" for unchecked code | Medium | B3 | `workspacePersistence.ts:34-37`, `page.tsx:408-414` | Medium |
| 3 | Unauthenticated, unlimited proxy of arbitrary code to verifier (35s held connection) | Medium | B1 | `route.ts:16-41` | Low |
| 4 | Verifier 2xx body passed through unvalidated to client | Low | B2 | `route.ts:51-52` | High |

## Overall Assessment

The security direction of this change is right and execution-verified: the fabricated `{valid: true, mock: true}` fallback — a genuine unchecked-code-reads-as-verified flaw — is removed, all three failure modes fail closed, `unavailable` wins over `valid` in the status mapping, and the removed default URL means unconfigured deploys make no outbound requests. The most important thing to address is Finding 1: the persistence sanitizer the diff tests is only wired into the legacy path, so the new transient status is in fact persisted by both live localStorage paths, and the passing test creates false assurance about the guarantee. Finding 2 (status/code binding) is the pre-existing sibling gap in the same property and is cheap to close alongside. Findings 3 and 4 are surface hygiene for any internet-facing deploy, not blockers for this diff. No findings rise to the HALT escalation patterns. Per the endorsement rules: no findings within the code paths read beyond those listed; endorsement claims are either execution-backed (cited fact-check verdicts, this review's probes) or explicitly scoped with their unverified hop named — this is not a categorical all-clear on the persistence layer, where Finding 1 stands.
