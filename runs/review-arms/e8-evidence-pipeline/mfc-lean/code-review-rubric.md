# Code Review Rubric

**Commit:** c95c9cb

**Scope:** `d86d2dc...c95c9cb` (Lean-verifier "unavailable" status taxonomy — route/client/store/UI) | **Reviewed:** 2026-08-17 | **Status: 🔴 DOES NOT PASS** — 2 red item(s) unresolved

Stage 1 fact-check: k=2 merged, 0 Incorrect / 9 Stale / 5 Mostly accurate / 1 Unverifiable / 16 Verified — no Fact-Check Gate trigger. Stage 2.5 submitted claims: 6 Verified (executed) / 1 Unverifiable (37b). Core critics run: security, performance, api-consistency (all ran). Contextual: ui-visual (advisory).

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | Node/decomposition mode ignores the new `unavailable` contract. `formalizeNode` collapses it to a failed proof (`result.valid ? "verified" : "failed"`, no `.unavailable` read), and `toNodeVerificationStatus` has no `"unavailable"` case so it falls to `default: "unverified"` → round-trips to `"none"`; every node-scoped surface (banner, badge, Re-verify, node dot/chip) goes blank and an offline verifier reads as a real failure — the exact misread this commit exists to eliminate, re-introduced in node scope. **Convergence:** api-consistency (Breaking, `formalizeNode.ts:61`) + api-consistency (Inconsistent, `decomposition.ts:29-38`) + performance (High — fan-out re-pays N× LLM generation, cascades false skips, regenerates on re-run) + ui-visual (Critical — zero visual feedback). Native red on api-consistency `Breaking`; convergence recorded, not tier-manufactured. | API Consistency | Breaking | `formalizeNode.ts:61`, `decomposition.ts:29-38`, `useAutoFormalizeQueue.ts:57-139`, `page.tsx:348-350` | for-author | — | 🔴 Unresolved |
| R2 | Removed `LEAN_VERIFIER_URL` default (`http://localhost:3100`) breaks the documented Docker config contract: an unset var now short-circuits to `verifier-not-configured` with zero outbound requests (FC Claims 4/27, Stale/executed — detector stub logged zero requests), so a previously working setup (Docker verifier up, var unset) silently degrades to "Verifier offline". No doc/migration/`.env.example` update ships in the diff. May be an intentional explicit-config change — but then it must be stated as a breaking setup change and the docs (A5) updated. | API Consistency | Breaking | `route.ts:26-30` (contract at `README.md:84`, `docs/USER_GUIDE.md:332-345`, `docs/ARCHITECTURE.md:197-200`) | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Live persistence paths bypass `sanitizeVerificationStatus`. The tested guard (`unavailable → none`, FC Claim 21 Verified) covers only the legacy workspace-v2 path; the app's live paths — Zustand `persist` `partialize` (`workspaceStore.ts:313`) and the formalization-sessions store — write/restore `verificationStatus` raw, and the diff itself feeds `vStatus` (incl. `"unavailable"`) into `onSessionUpdate`. So the transient status is persisted as artifact-state; a reload restores "Verifier offline" (or a stuck `verifying`) for a session that never verified. Passing test overstates the guarantee. **Mechanism visibility floor:** live-persist bypass confirmed by static trace of both writers (security move #11, BC6/BC7). **Convergence:** api-consistency F10 (`🟢`). | Security | Medium | Security (move #11 bypass) + API-consistency | for-author | — | 🟡 Open | — |
| A2 | Persisted `valid` status is not bound to the code it endorsed. `handleLeanCodeChange` updates `leanCode` without resetting `verificationStatus`; the only staleness signal `leanEdited` is transient React state lost on reload. Verify → edit → reload shows a green "Verified" badge (and no Re-verify) on code the verifier never saw — the same "missing verifier reads as passing proof" property this diff protects, violated via the persistence sibling path. Load half executed (probe BC5). Pre-existing; the taxonomy work is the natural place to close it. | Security | Medium | Security | for-author | — | 🟡 Open | — |
| A3 | Unauthenticated, unrate-limited proxy of arbitrary `leanCode` to the verifier, holding a connection up to `REQUEST_TIMEOUT_MS = 35_000` per request, no body-size cap. DoS amplifier + free compute/probing proxy on any deploy with `LEAN_VERIFIER_URL` set (Lean elaboration is attacker-steerable heavy compute). Pre-existing surface — the diff changes only error mapping; the not-configured short-circuit removes the default outbound target on unconfigured deploys. | Security | Medium | Security | for-author | — | 🟡 Open | — |
| A4 | 35 s route timeout is unpriced against duration-limited serverless. The route exports no `maxDuration` and no repo duration override exists (FC 37a, executed). Where the platform default duration limit is below 35 s, the `AbortController` (`route.ts:33-34`) never fires — the platform kills the function, the client gets a non-JSON error, `verifyLean`'s unconditional `res.json()` throws, the throw bypasses `leanRetryLoop`'s `unavailable` exit, and the pipeline catch records status **`invalid`** — bypassing the entire new taxonomy and reading a missing verifier as a failed proof. **Mechanism visibility floor:** repo-side chain (37c) is Verified/executed (non-JSON → throw → `"invalid"`); only the Vercel default-limit premise (37b) is Unverifiable — *pending execution verification*, not confirmed. | Performance | Medium | Performance | for-author | — | 🟡 Open | — |
| A5 | Documentation contract drift: nine stale passages still describe the removed mock `{valid:true, mock:true}` fallback and the removed `localhost:3100` default (incl. the ARCHITECTURE request-flow diagram's hardcoded URL + mock branch); the USER_GUIDE badge list omits the new "Verifier offline" state. A consumer coding a client/test from these docs targets a response shape that no longer exists. **Convergence:** Fact-check (Claims 2,4,6,24,27,28,29,30,31 Stale/executed) + api-consistency F4 (Inconsistent). | Documentation | Stale ×9 | Fact-check + API-consistency | for-author | — | 🟡 Open | — |
| A6 | In-code cause lists omit the reachable-but-errored (`verifier-error`) case. The banner text, badge tooltip, and `VerifyLeanResult.unavailable` docstring all say "not configured or unreachable" but the route also sets `unavailable:true` on HTTP-error (`route.ts:45-49`, executed); precise wording is "not configured, unreachable, or errored." | Documentation | Mostly Accurate | Fact-check (Claims 12/14/16) + API-consistency | for-author | — | 🟡 Open | — |
| A7 | Route catch comment ("Network / timeout / DNS failure — verifier unreachable") is broader than reality: `res.json()` sits inside the same `try` after the OK check, so a reachable 2xx verifier returning malformed JSON also lands in this catch and is mislabeled `verifier-unreachable` — a case that is neither network, timeout, nor DNS. Safe-direction (fails closed) but the label misleads. | Documentation | Mostly Accurate | Fact-check (Claim 9, divergence winner) | for-author | — | 🟡 Open | — |
| A8 | Retry-loop docstring ("retrying up to MAX_LEAN_ATTEMPTS times on failure") omits that since this change one failure class — verifier-unavailable — exits on the first attempt without retrying (executed, FC Claims 18/20). | Documentation | Mostly Accurate | Fact-check (Claim 18) | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Verifier 2xx responses passed through to client unvalidated (`route.ts:51-52`) — a controlled verifier host/env can deliver arbitrary `valid` values. Low because exploitation requires operator-trust control; mitigated by `Boolean()` coercion and React text-node escaping. | Security F4 | Low | for-author | — | 🟢 Open |
| C2 | Transient 503 (rolling restart) permanently downgrades the run to `unavailable`; missing a cheap *verify-only* retry (1–2 re-calls of `verifyLean` with backoff, no LLM tokens). The generation short-circuit itself is economically correct as written. | Performance F3 | Low | for-author | — | 🟢 Open |
| C3 | `clearTimeout(timeout)` runs only after a successful `fetch`; on the throw path (connection refused / `res.json()` throw — the now-common down-verifier path) the 35 s timer + `AbortController` closure outlive the response. Move `clearTimeout` into a `finally`. | Performance F4 | Low | for-author | — | 🟢 Open |
| C4 | Reload sanitizes `unavailable → none` while `leanCode` persists, so the Re-verify affordance (gated on `leanEdited || invalid || unavailable`) disappears; cheapest recovery (one verify call) is lost and visible paths re-run generation. Show Re-verify whenever code exists with status `none`. | Performance F5 | Low | for-author | — | 🟢 Open |
| C5 | Route emits typed `reason` (always) and `detail` (on `verifier-error`), but `verifyLean` — the sole caller — discards both; nothing in `app/` reads them. The client collapses all three reasons into one `"unavailable"` status, which is exactly why the cause lists (A6) can't be accurate. Thread `reason` through or document as debug-only. | API-consistency F5 | Minor | for-author | — | 🟢 Open |
| C6 | `detail` (singular) diverges from the one sibling structured-extra field `details` (plural, `formalization/lean/route.ts:145`). Settle the spelling before it gains a consumer. | API-consistency F6 | Minor | for-author | — | 🟢 Open |
| C7 | `unavailable` optionality is asymmetric: required on `VerifyLeanResult`, optional on `LeanRetryResult`, absent-on-success on the wire. Nothing breaks; consumers get different answers to "can I read `.unavailable` directly?". | API-consistency F7 | Minor | for-author | — | 🟢 Open |
| C8 | `verifyResultToStatus` uses `<source>To<Target>` infix while the existing status mappers use `to<Target>`/`from<Source>`; the three now form a family harder to grep. Optional rename `toVerificationStatus`. | API-consistency F8 | Informational | for-author | — | 🟢 Open |
| C9 | Unavailable responses use HTTP 200 in-band signaling while sibling failures use `{error}` + 4xx/5xx. Defensible (unavailability is a domain outcome), but undocumented — a one-line comment prevents a future "fix" back to 5xx that would break `verifyLean` (which never checks `res.ok`). | API-consistency F9 | Informational | for-author | — | 🟢 Open |
| C10 | Zustand `persist` `partialize` writes `verificationStatus` raw (`workspaceStore.ts:289,313`); only the compat shim applies the sanitizer. The new test asserts an invariant the running app does not enforce on its primary path. **Convergence with A1** (same live-persist bypass, from the API-consistency angle). | API-consistency F10 | Minor | for-author | — | 🟢 Open |
| C11 | SessionBanner status dot renders `unavailable` identically to `none` (gray fallback); a run that ended verifier-offline is indistinguishable from one never run, and for node-scoped sessions the session record is the only place the value survives (see R1). Add an explicit branch + `title`/`aria-label` (not color-alone, WCAG 1.4.1). | ui-visual F2 (Major, advisory) | Major | for-author | — | 🟢 Open |
| C12 | Icon Rail Lean `statusSummary` lets `unavailable` fall to "Code ready" — same label as a never-verified artifact; the rail silently drops the distinction this change introduces. Add "Not checked — verifier offline". | ui-visual F3 | Minor | for-author | — | 🟢 Open |
| C13 | Unavailable-badge remedy text ("Set LEAN_VERIFIER_URL…") lives only in a native `title` on a non-focusable `<span>` — never fires on touch, unreachable by keyboard (WCAG 1.4.13). Mitigated in global mode by the inline banner; fixing R1 raises its value in node mode. | ui-visual F4 | Minor | for-author | — | 🟢 Open |
| C14 | Floating Re-verify/Edit group (`absolute right-4 top-4 z-30`) can occlude the amber banner's heading/first line at narrow panel widths (< ~560px). Reserve right clearance (`mr-44`) or move the banner above the scroll area. | ui-visual F5 | Minor | for-author | — | 🟢 Open |
| C15 | Reload drops `unavailable` (banner+badge vanish) by design (sanitizer, FC Claim 21) — noted so the UX consequence is on record; re-probing on load would restore the signal. No change requested. | ui-visual F6 | Informational | for-author | — | 🟢 Open |
| C16 | Re-verify button (visibility condition modified by the diff) has no `:active` pressed style — click gives no feedback beyond hover. Optional `active:bg-blue-200`. | ui-visual F7 | Informational | for-author | — | 🟢 Open |
| C17 | "Type-checked by a real Lean 4 installation" (`README.md:60`) could not be established — requires the Dockerized verifier, unavailable in the review sandbox; verifier container sandboxing is an open item (relates A3). *Pending execution verification.* | Fact-check (Claim 1) | Unverifiable | for-author | — | 🟢 Open |
| C18 | Vercel's default function-duration limit vs the 35 s route timeout (the 37b half of A4) could not be verified — no network access; value is plan/fluid-compute dependent. Verify via current Vercel duration docs or the deployment's project settings. *Pending execution verification.* | Fact-check (Claim 37b) | Unverifiable | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

Every row is backed by an `executed`-mode fact-check verdict (Stage 1 or Stage 2.5) and narrowed to that verdict's `Scope:` line (provenance rule 5). Cross-checked against the merged and per-replicate fact-check reports — no contradicting observation within each row's stated scope.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The three verifier-failure modes (env unset / connection refused / verifier HTTP 500) fail closed to `{valid:false, unavailable:true, reason}` — never the old `{valid:true, mock:true}`. *(Scope: the three exercised failure modes only — does NOT cover 2xx passthrough, where a reachable verifier's body passes through unvalidated, C1.)* | ✅ Confirmed | `route.ts:8-15` `unavailableResponse(...)` — FC submitted claim 32 (executed) + FC Claims 6/7/8/22 (executed; r1 E4 real handler, r2 live HTTP Cases A/B/E) | Fact-check (Stage 2.5) | for-orchestrator-synthesis |
| `verifyResultToStatus` returns `"unavailable"` whenever `unavailable` is truthy, regardless of `valid` — a missing verifier never reads as a passing proof at the mapping. *(Scope: the four boolean flag combinations in this helper — does NOT cover callers that read `unavailable` directly, e.g. `leanRetryLoop`.)* | ✅ Confirmed | `api.ts:115-118` `if (result.unavailable) return "unavailable";` — FC Claim 17 (executed) + submitted claim 33 (executed; both replicates' scratch tests, all four combinations) | Fact-check | for-orchestrator-synthesis |
| `leanRetryLoop` short-circuits on unavailable: exactly one generation + one verification call, returns `errors:""`, no retry (out of `MAX_LEAN_ATTEMPTS = 3`). *(Scope: single sequential invocation — does NOT cover concurrent invocations or cancellation/abort.)* | ✅ Confirmed | `leanRetryLoop.ts:73-77` — FC Claims 19/20 (executed) + submitted claim 34 (executed; call-count accounting `toHaveBeenCalledTimes(1)`) | Fact-check | for-orchestrator-synthesis |
| In **global mode**, status `"unavailable"` renders the amber "Verifier offline — proof not checked" banner and the rendered output contains no "Verified" text. *(Scope: `OutputPanel`/`LeanCodeDisplay`/`VerificationBadge` render trees only — does NOT extend to node-scoped surfaces, which is the R1 defect.)* | ✅ Confirmed | `OutputPanel.test.tsx:112-116` (asserts `queryByText('Verified')` absent), `LeanCodeDisplay.tsx:131-136` — FC Claim 11 (executed) + submitted claim 35 (executed; component tests pass both replicates) | Fact-check | for-orchestrator-synthesis |
| On the **legacy workspace-v2 load/save path**, `sanitizeVerificationStatus` maps `"unavailable"`/`"verifying"`, case-variant strings, and non-string values to `"none"` (strict `===`, no coercion). *(Scope: the legacy path only — explicitly licenses nothing about the live Zustand/sessions persistence paths, which bypass the sanitizer, A1/C10.)* | ✅ Confirmed | `workspacePersistence.ts:34-37` — FC Claim 21 (executed) + security endorsement probes BC1–BC4 (executed, `sec-vitest-sanitizer.log`) | Fact-check + Security | for-orchestrator-synthesis |
| With `LEAN_VERIFIER_URL` unset, the route returns `verifier-not-configured` before any fetch — a detector stub on `127.0.0.1:3100` recorded zero incoming requests. *(Scope: this route only — does NOT establish that no other code path contacts a hardcoded verifier URL.)* | ✅ Confirmed | `route.ts:26-30` — FC Claims 4/7 (executed; r2 Case E detector stub) + submitted claim 36 (executed) | Fact-check (Stage 2.5) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

To pass review: both 🔴 items (R1, R2) must be resolved. All 🟡 items must be fixed or carry an author note. 🟢 items are optional.

**Recommended next action:** fix red items then re-review. *(Next-action derivation rule 4: ≥1 🔴 item; both reds are single-domain api-consistency, diff is not >500 lines, reds do not span 3+ domains — so not split-PR/pre-mortem/architectural-block.)*
