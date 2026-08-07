# Code Review Rubric — e3/csp-arm2 (verification pass)

**Scope:** `d86d2dc..ab4dbdb` (e3/csp-arm2 verification pass) | **Reviewed:** 2026-08-06 | **Commit:** ab4dbdb | **Status:** ✅ MEETS 0R+0A

**Pipeline:** code-fact-check (merged k=3, 0 Incorrect / 0 Stale) → critic stage (security · performance · api-consistency · architecture · ui-visual) → synthesis. This is the Arm-2 verification pass over amber-disposition commit `ab4dbdb`, confirming the 8 fixed full-3 ambers hold, honoring the 6 acked, and hunting for anything NEW the disposition commit introduced.

**Merge standard:** 0R+0A — merge requires 0 🔴 AND every open 🟡 carries a fix-or-ack disposition.

**Loop-owner override (honored):** `9b4e453`'s superseded historical-verification claim and the A15/A17 immutable-history items are accepted-immutable — treated as considered overrides, not findings (see ↩️ section). Excluded from all counts.

---

## 🔁 Iteration Delta

### Full-3 ambers FIXED — confirmed closed this pass (8, now gone)

Each verified by direct inspection this pass; none re-raised as a finding.

| # | Finding (full-3) | Fix | Verified by |
|---|---|---|---|
| A1 | Prefetch skip (client-header-conditioned) + unanchored matcher | `missing:` clause deleted; `api(?:/\|$)` + `favicon\.ico$` anchored; prefetch test added | security (prior Medium CLOSED), api (C3 closed for api/favicon), fc Clusters 10/11/19 |
| A2 | `form-action` absent (injected-`<form>` / dangling-markup) | `form-action 'self'` added, no default-src fallback; exact-key test widened 9→10 + value assertion | security (prior Medium CLOSED), fc Cluster 18 |
| A4 | `x-nonce` zero production readers | write deleted; absence pinned by test; contract surface shrinks | security, api (C1 closed), perf (net-positive), fc Cluster 9 |
| A5 | `dataUrlToBlob` published from code-split module | moved to zero-dep `app/lib/utils/dataUrl.ts`, byte-identical; `git mv` test rename | arch (C4 true move, single definition), api (C2 closed), fc Clusters 5/7 |
| A6 | Layout half of nonce control untested | `app/layout.test.ts` asserts `dynamic==="force-dynamic"`; mutation-confirmed falsifier | arch (mutation re-run: red on delete), fc Cluster 2 |
| A10 | `force-dynamic` broader than `await headers()`; forecloses PPR | comment records scope/PPR rationale; kept `force-dynamic` | fc Cluster 4 (PPR not enabled, equivalent today) |
| A12 | Phantom `OpenAlex` in connect-src rationale | dropped; replaced with server-origin invariant | fc Cluster 14 (`rg -in openalex` zero hits) |
| A16 | `style-src` rationale hand-synced into unlinked copies | single authoritative owner in `proxy.ts`; others reduced to pointers | arch (C5 collapsed to one owner + pointers), fc Cluster 13 |

### Full-3 ambers ACKED — dispositioned, still open 🟡 (4; carried below)

A7, A8, A9, A11 remain acked-with-justification and are carried as 🟡 rows in the Must-Address section — they remain dispositioned amber, not fresh findings, and honored (not re-raised) by every critic. A15/A17 are the two remaining acked items; per the loop-owner override they are accepted-immutable and live in ↩️ Considered Overrides, not here.

### NEW this pass

One underlying residual, surfaced through three lenses (fact-check Cluster 19 "each exclusion is anchored" overclaim; security F1; api F1) — all below the amber bar → 🟢. Plus perf's three micro-observations (1 Low, 2 Informational) and arch's fix-introduced N1 (Minor coupling) → all 🟢. Zero NEW red or amber across all six critics.

---

## 🔴 Must Fix

None. 0 🔴.

Confirmed across all critics: FC 0 Incorrect / 0 Stale (k=3, stable across all three replicates); security 0 Critical/High/Medium (both prior Mediums CLOSED); perf 0 Critical / 0 new High; api 0 Breaking; arch 0 Structural; ui 0 Critical.

---

## 🟡 Must Address

All rows are the acked full-3 ambers, carried with their disposition-by-ack recorded. No NEW amber this pass.

| # | Finding | Source severity | Disposition | Honored this pass by |
|---|---|---|---|---|
| A7 | Falsifier pinned to Next-private transport (`x-middleware-override-headers`) | api/arch (Inconsistent) | **ACKED + half-fix** — no public API to read forwarded headers; failure direction safe; docblock pins `next@16.2.4`, names both private headers, adds canary + triage rule | api ("degrades legibly rather than silently"), arch, fc Cluster 8 |
| A8 | `buildCsp` exported from framework entry file; unvalidated `nonce` param | security (Med) / arch (Coupling) | **ACKED** — cost curve, not defect; no 2nd consumer in 3 iterations; response-splitting unreachable (`Headers.set` rejects CRLF); base64-UUID caller. Revisit trigger: first 2nd consumer | security ("injection unreachable"), arch (deferral honored, trigger intact) |
| A9 | `force-dynamic` per-request render cost | perf (High) | **ACKED** — accepted, correctly-declared cost of per-request nonces; rendering-mode-neutral vs preceding `await headers()`. Owed: p50 TTFB, unobtainable in-sandbox (`next build` needs fonts.googleapis.com) | perf (sole High, explicitly not re-raised as red), fc Clusters 21/22 |
| A11 | Synchronous main-thread base64 decode | perf (Med) | **ACKED** — widening `connect-src` to `data:` for tens of ms is a bad trade; ~5 ms/MiB cold path, no jank reported; named drop-in (`Uint8Array.fromBase64`) if jank ever appears | perf (cold path, settled baseline), ui (throw-on-malformed not reachable from caller) |

Every 🟡 carries a fix-or-ack disposition. No undispositioned 🟡.

---

## 🟢 Consider

NEW items this pass — all below the amber bar; none gate merge.

| # | Item | Source | Severity | Note |
|---|---|---|---|---|
| G-N1 | "Each exclusion is anchored" overclaims — `_next/static` / `_next/image` are unanchored prefixes (`/_next/staticfoo` also excluded) while `api` / `favicon.ico` are anchored | fc Cluster 19 (Mostly accurate) · security F1 (Informational) · api F1 (Nit/Low) | 🟢 | **Same single residual through 3 lenses**, not 3 defects. Harmless: `_next/*` is Next's reserved namespace with no routable siblings; behavior unchanged from pre-ab4dbdb (only the comment is new). Optional one-clause tightening: name the anchored exclusions, or anchor the `_next` alternatives for one uniform rule. |
| G-N2 | Prefetch documents now run the proxy (nonce gen) per prefetch | perf finding 1 | 🟢 (Low) | Correctness-required (prefetched paintable doc otherwise ships un-nonced scripts); ~2.67 µs/req on documents rendered anyway — rounding error. |
| G-N3 | Anchored matcher regex — constant-factor change | perf finding 2 | 🟢 (Info) | No complexity-class change; correctness-motivated, perf-neutral. |
| G-N4 | `form-action` adds one constant string per CSP build | perf finding 3 | 🟢 (Info) | 11 vs 10 directives; immaterial. |
| G-N5 | Fix-introduced doc coupling: owner-enumerates-referrers + pointer-by-filename | arch N1 | 🟢 (Minor/Coupling) | The C5 analog. Net **improvement** over duplicated rationale (dangling pointer is visible on next read vs silent contradiction); comment-only, zero runtime effect. History (`b25e939`) shows filename pointers can go stale — cheapest hardening is to drop the hand-maintained referrer enumeration. No action to merge. |
| G-N6 | Silent PNG-export failure / 0-byte accepted (console-only error) | ui carried Major | 🟢 (advisory) | **CARRIED, out of diff range** — lives in `GraphPanel.tsx:98–108`, not touched by ab4dbdb; dispositioned in prior full-3. Recorded for continuity, not a new blocker; per severity mapping ui advisory → 🟢. |

---

## ↩️ Considered Overrides

Accepted-immutable per loop-owner override; treatment inherited (waived, not findings; excluded from counts).

| # | Item | Basis |
|---|---|---|
| — | `9b4e453` superseded historical-verification claim | Loop-owner accepted-immutable override (fc Cluster 23). Body was true when written; amending rewrites published history. |
| A15 | Commit messages (`9b4e453`/`d90d6bb`) state "Layout reads `headers()`" | Immutable history; true when written, superseded by `99e1229`'s `force-dynamic`. Live mechanism now documented (A10) + tested (A6). |
| A17 | `2544a19` commit-message aside on ripgrep output order | Immutable history; claim genuinely unreliable (nondeterministic parallel traversal) but decorates a disposition that stands; every substantive claim in the paragraph verified k=3. |

---

## ✅ Confirmed Good

Grounded evidence, cross-checked against merged FC + per-replicate verdicts (Commit: ab4dbdb).

- **Both prior Medium security findings CLOSED at the design level** (not papered over): real `form-action 'self'` directive; removal of client-controllable CSP-skip. Each fix regression-locked by a test. (security; fc Clusters 11/18)
- **Nonce integrity:** `Buffer.from(crypto.randomUUID()).toString("base64")` — CSPRNG, charset contains no `;`/whitespace/CRLF, cannot inject a directive or split the header. (security; fc Cluster 16)
- **`x-nonce` write removed cleanly** — nonce travels only via the request CSP header Next actually consumes; contract surface reduced, absence pinned. (security, api C1, perf, fc Cluster 9)
- **`dataUrlToBlob` move is a true byte-identical relocation** — rename in the diff, single surviving definition, clean leaf-util dependency direction, preserves the code-split boundary keeping `html-to-image` out of the codec's chunk. (arch C4, api C2, perf, fc Clusters 5/7)
- **Layout test is a confirmed deletion-detector, not a tautology** — mutation re-run goes red on delete, green on restore. (arch, fc Cluster 2)
- **CSP rationale now has a single owner** with pointer-only copies elsewhere — removes the drift risk behind two prior findings. (arch C5, api, fc Cluster 13)
- **Matcher hardening is a strict improvement** — `api(?:/\|$)` now correctly includes `/apidocs`, `/api-status`; `favicon\.ico$` stops `/favicon.ico.map` being swallowed; both regression-locked. (security, api C3, fc Clusters 10/19)
- **connect-src invariant holds** — every browser call same-origin `/api/...`; all vendor calls server-side; OpenAlex phantom gone. (fc Cluster 14)
- **Both request+response headers carry the same policy** — required for `'strict-dynamic'` to nonce Next's bootstrap scripts. (security, ui, fc Clusters 3/17)
- **UI: zero rendered-markup / styling change** — CSP keeps every directive the UI renders through (`style-src 'unsafe-inline'`, `img-src data: blob:`); `force-dynamic` alters render timing, not output. (ui)
- **Private-Next-transport coupling fenced by a labeled canary + written triage rule** — degrades legibly on a future Next bump. (api, arch, fc Cluster 8)
- **Build verification reproduced:** 27 files / 240 tests pass; `tsc --noEmit` exit 0; lint = 2 pre-existing warnings in untouched `app/page.tsx`. (fc Cluster 20; amber-dispositions Verification)

---

## ⚠️ Unverified Findings

Runtime/framework-internal claims the unit suite cannot settle statically (all in-repo halves verified; consequences owed outside the sandbox):

- Unmocked `next/font/google` throw behavior — needs a mutation run removing `vi.mock` (fc Cluster 1).
- Next renderer stamping the nonce onto emitted bootstrap scripts — framework-internal, needs integration render (fc Cluster 3).
- "Always Node.js runtime" universal — build forces Node for proxy files; no edge opt-out not settleable from repo (fc Cluster 16).
- "App never hydrates" un-nonced consequence — runtime browser outcome (fc Cluster 17).
- A9 owed TTFB — `next build` fails in-sandbox on `fonts.googleapis.com` (fc Cluster 22).
- "(from 26/234)" baseline test count — arithmetically consistent, not re-executed (no worktree writes) (fc Cluster 20).

None of these are defects; each is an out-of-sandbox measurement or integration-render gap, and the in-repo half of each is verified.

---

## ⏭️ Skipped Core Critics

None. All core critics ran: code-fact-check (merged k=3), security, performance, api-consistency, plus contextual architecture and ui-visual.

---

## 0R+0A Merge Verdict

**MEETS.**

- 🔴 **0** — 0 Incorrect (FC), 0 Critical/High/Medium (security, both prior Mediums CLOSED), 0 new High (perf; the sole High is acked A9), 0 Breaking (api), 0 Structural (arch), 0 Critical (ui).
- 🟡 **4**, all open rows dispositioned-by-ack: A7, A8, A9, A11. No undispositioned 🟡.
- 🟢 **6** new/carried items (one residual × 3 lenses + 2 perf-info + arch N1 + ui carried advisory), all below the amber bar.
- ↩️ 3 accepted-immutable overrides (9b4e453, A15, A17), excluded from counts.

Every open 🟡 carries a fix-or-ack disposition and the only 🟡 rows are the already-acked ones → **verdict is MEETS**. The NEW items ab4dbdb introduced all map to 🟢. Merge-clear against the 0R+0A standard.
