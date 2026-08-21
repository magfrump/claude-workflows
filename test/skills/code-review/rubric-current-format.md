# Code Review Rubric

**Scope:** feat/example-branch (12 commits, 340 lines) | **Reviewed:** 2026-07-30 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | Token comparison uses `==`, allowing a timing side channel on the session secret. | Security | Critical | `src/auth/session.ts:42` | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `parseWindow` allocates a new buffer per call inside the request loop. | Performance | Medium | performance-reviewer | for-author | — | 🟡 Open | — |
| A2 | New endpoint returns `204` where every sibling returns `200` with a body. | API Consistency | Inconsistent | api-consistency-reviewer | for-author | `#118` / 2026-05-02 | 🟡 Open | Deliberate; body is empty by spec. |
| A3 | Confirmation revoked: the security review certified `connect-src 'self'` as sufficient, but the fact-check recorded "client fetches include `data:` URLs" at `src/export/graph.ts:24` — a `data:` fetch is not permitted by `connect-src 'self'`. | Security | Contested | Confirmed-Good cross-check | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | No test covers the expired-token branch added in this diff. | test-strategy | Low | for-author | — | 🟢 Open |
| C2 | `SessionStore` now has five responsibilities; consider extracting the cache. | tech-debt-triage | Informational | for-author | — | 🟢 Deferred |

---

## ↩️ Considered Overrides

Rows lifted from `docs/reviews/override-log.md` that matched the current diff per the
Step 3.5 scan. Each row records how the current run treated the prior call.

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `#118` / 2026-05-02 | Empty-body 204 on `/logout` (api-consistency) | 🟡 Must-Address → Won't-Fix | "matches the RFC; siblings are the outliers" | Re-flagged as A2 — the prior rationale covers `/logout` only. |

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Refresh-token rotation matches the documented flow in `docs/auth.md`. | ✅ Confirmed | `src/auth/session.ts:88` — "rotateRefreshToken(prev, now)"; matches `docs/auth.md:31` | code-fact-check | for-orchestrator-synthesis |
| No client-side code calls a third-party origin, so `connect-src 'self'` holds. | ✅ Confirmed | Enumeration: `rg -n "fetch\(" src` → 12 matches, all relative `/api/…` paths | security-reviewer | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

Findings whose **Evidence** block could not be located at the cited location (after
basename resolution). These are advisory only: they may not be 🔴 or 🟡 and do not count
toward convergence.

| # | Finding | Source | Cited location | Why unverified |
|---|---|---|---|---|
| U1 | Retry loop lacks a backoff ceiling. | performance-reviewer | `retry.ts:88` | No file matching `retry.ts` in repo |

---

## ⏭️ Skipped Core Critics

Core critics downgraded by the Stage 1.5 critic gate (diff-shape skip and/or absence of
corroborating fact-check evidence). This section makes coverage limits auditable across runs.

| Critic | Reason | Signal |
|---|---|---|
| ui-visual-review | No rendering code in diff | `git diff --stat` shows no `.tsx`/`.css` changes |

---

## 🧩 Composition check

Multi-source co-located clusters found by the Fragment-Composition cross-check, with
the forced question's disposition for each.

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `store/database.go:80-110` | FC-6, R3, arch-4 | composed → X1 |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
