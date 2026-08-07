# Security Review — e3/csp-arm2 (verification pass, Arm 2 critic stage)

Commit: ab4dbdb
**User goal:** E3-loops experiment, 0R+0A merge standard. Arm 2 verification pass, critic stage. Confirm 0 red AND surface any NEW amber the disposition commit ab4dbdb introduced.
**Scope:** `git diff d86d2dc..HEAD` (worktree `wt-csp-arm2`, branch `e3/csp-arm2`, HEAD `ab4dbdb`)
**Date:** 2026-08-06
**Based on:** merged code-fact-check (k=3): 0 Incorrect / 0 Stale; sole cosmetic residual = "Each exclusion is anchored" overbroad for `_next/*`.
**Prior artifacts honored:** full-3 rubric + amber-dispositions.md (14 ambers: 8 fixed, 6 acked). This pass verifies the fixes hold, confirms the two prior Medium findings are CLOSED, and hunts for anything NEW.

Legibility-target: the merge gate (0 Red + 0 Amber). Findings are calibrated to that bar — anything below Amber is stated as Informational and marked so the gate is not tripped by cosmetics.

---

## Bottom line up front

**No Critical or High findings. No Red. No NEW Amber.** Both prior Medium findings are **CLOSED**. The disposition commit `ab4dbdb` introduces exactly one new item, and it is a **documentation-accuracy overclaim (Informational, cosmetic)** — the same residual the k=3 fact-check already isolated, with no behavior or security impact. The two ACKED items (A8 `buildCsp` placement + unvalidated nonce param; enforce-only rollout with no `report-uri`) are honored and not re-raised.

---

## Trust Boundary Map

```
B1: [inbound HTTP request + client-controlled headers]  → [proxy.ts config.matcher + proxy()]  → [Next render pipeline / CSP response header]   (modified)
B2: [per-request nonce: crypto.randomUUID → base64]      → [buildCsp() string interpolation]     → [CSP request+response header → browser policy]
B3: [in-DOM `data:` image URL from html-to-image]        → [dataUrlToBlob() in-process decode]    → [Blob → triggerDownload] (no network fetch)   (moved)
```

Prose: The only externally-controlled inputs crossing into trusted context here are (a) the request path and request headers, which decide whether the CSP applies (B1), and (b) the html-to-image-produced `data:` URL that `dataUrlToBlob` decodes locally (B3). The nonce (B2) is server-generated from a CSPRNG and never derived from client input. `ab4dbdb` modifies B1 (matcher hardening, removal of the header-conditioned skip, removal of the `x-nonce` write) and relocates B3 (byte-identical function move to `app/lib/utils/dataUrl.ts`). Every finding below is anchored to one of these labels.

---

## Verification of prior findings (CARRIED)

### Prior Medium — prefetch bypass — CLOSED
**Boundary:** B1 · **Confidence:** High
The old matcher carried a `missing:` clause keyed on `next-router-prefetch` and `purpose: prefetch` request headers — client-controlled, so a client could suppress the CSP on a rendered/painted prefetch document. `ab4dbdb` deletes the `missing:` clause entirely and anchors the API exclusion to `api(?:/|$)`.

Evidence (verbatim, `proxy.ts`):
```
    source: "/((?!api(?:/|$)|_next/static|_next/image|favicon\\.ico$).*)",
```
Regression-locked by `proxy.test.ts` — `applies the CSP to a prefetch request` sends `purpose: prefetch` + `next-router-prefetch: 1` and asserts `'strict-dynamic'` is present, and `has no request-header-conditioned skip` asserts the matcher entry has neither `missing` nor `has`. **Bypass eliminated.**

### Prior Medium — form-action absence (injected-`<form>` / dangling-markup) — CLOSED
**Boundary:** B2 · **Confidence:** High
`script-src 'strict-dynamic'` does not constrain a script-less injected `<form>`; without `form-action` such markup could POST to an attacker origin. `ab4dbdb` adds the directive with no `default-src` fallback.

Evidence (verbatim, `proxy.ts`):
```
    // Does not fall back to default-src. The app posts to no cross-origin
    // form target, so 'self' is free and closes the dangling-markup /
    // injected-<form> path, which needs no script and so is untouched by
    // script-src 'strict-dynamic'.
    "form-action 'self'",
```
Locked by `buildCsp` test asserting `form-action` is in the directive set and equals `'self'`. **Gap closed.**

---

## Findings

### F1 — Comment claims "Each exclusion is anchored" but `_next/static` / `_next/image` are prefix-matched
**Severity:** Informational (below Amber)
**Location:** `proxy.ts` (config.matcher docblock) — "Each exclusion is anchored so it cannot swallow a sibling route"
**Boundary:** B1
**Move:** #2 (implicit-assumption trace) / #5 (invert the access-control model — what does the matcher fail to cover?)
**Confidence:** High · **NEW to ab4dbdb** (the comment was rewritten in this commit)

The docblock added by `ab4dbdb` states *each* exclusion is anchored. Only two are: `api(?:/|$)` (bounded by `/` or end) and `favicon\.ico$` (bounded by end). `_next/static` and `_next/image` remain bare prefixes, so `/_next/staticfoo` or `/_next/imagexyz` also fall in the exclusion. This is not exploitable: `_next` is Next.js's reserved build-output namespace, application routes cannot be created under it, and no attacker-controlled HTML document with executable inline script is served from that prefix to a victim under the app origin. Behavior is also **unchanged** from before `ab4dbdb` — both matchers leave the `_next/*` prefixes unanchored; only the *comment* asserting full anchoring is new. Net: a documentation-accuracy nit, not a policy gap. This is the identical residual the k=3 fact-check flagged.

**Recommendation:** Soften the comment to "The `api` and `favicon.ico` exclusions are anchored; `_next/*` are prefix matches on Next's reserved output namespace, which carries no routable siblings." No code change needed. Does not gate merge.

---

## What Looks Good

- **Nonce integrity (B2).** `Buffer.from(crypto.randomUUID()).toString("base64")` yields a base64 string (charset `[A-Za-z0-9+/=]`) from a CSPRNG (UUIDv4, 122 bits). It contains no `;`, whitespace, or CR/LF, so string-interpolating it into the directive list cannot inject a directive or (with `Headers.set` also rejecting CRLF) split the header — this is precisely why the ACKED A8 unvalidated-`nonce`-param deferral is unreachable. Verified by sampling the generator.
- **`x-nonce` write removed cleanly (B2).** The former `requestHeaders.set("x-nonce", nonce)` is gone; the nonce now travels only via the request `Content-Security-Policy` header that Next actually consumes. Removing an unused write shrinks the contract surface and removes a header a future component might have trusted by accident. `proxy.test.ts` pins the absence (`does not publish an x-nonce header with no consumer`). No new surface.
- **`dataUrlToBlob` move is byte-identical (B3).** `git diff 2544a19..ab4dbdb` shows the function body relocated to `app/lib/utils/dataUrl.ts` with no logic change; it still decodes `data:` URLs in-process rather than `fetch()`-ing them, keeping `connect-src 'self'` tight. Input is DOM-internal (html-to-image output), the parser rejects non-`data:` input, and base64/percent branches handle non-UTF-8 bytes correctly (covered by `dataUrl.test.ts`). No trust-boundary regression from the move.
- **Matcher hardening is a strict improvement.** Anchoring `api(?:/|$)` now correctly *includes* `/apidocs`, `/api-status` (real pages that previously risked exemption), and escaping `favicon\.ico$` stops `/favicon.ico.map` and similar from being swallowed — both regression-locked by `does not let an exclusion swallow a sibling route`.
- **Both headers carry the same policy.** `proxy()` sets the CSP on the forwarded request *and* the response, which is required for `'strict-dynamic'` to nonce Next's bootstrap scripts; the `force-dynamic` layout export (unchanged by `ab4dbdb`; only its comment expanded) prevents a static prerender from baking one nonce for all visitors.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Status |
|---|---------|----------|----------|----------|------------|--------|
| — | Prefetch bypass (client-header-conditioned skip) | Medium | B1 | `proxy.ts` matcher | High | CARRIED — CLOSED |
| — | form-action absence (injected-`<form>`) | Medium | B2 | `proxy.ts` buildCsp | High | CARRIED — CLOSED |
| F1 | "Each exclusion is anchored" overclaim (`_next/*` prefix) | Informational | B1 | `proxy.ts` matcher docblock | High | NEW (open, non-gating) |

No Critical / High / Medium / Low findings open. ACKED (not re-raised): A8 (`buildCsp` exported from entry file + unvalidated `nonce` param — CRLF rejection makes injection unreachable); enforce-only rollout with no `report-uri`.

---

## Overall Assessment

The security posture of this change is **strong and merge-ready against the 0R+0A gate**. `ab4dbdb` is a disposition commit that closes both outstanding Medium findings at the design level (a real `form-action` directive, and removal of a client-controllable CSP-skip) rather than papering over them, and it does so with regression tests that lock each fix. No new attack surface is introduced: the `x-nonce` removal and the `dataUrl.ts` relocation both *reduce* surface, and the matcher change is strictly more inclusive on document routes while more precise on exclusions. The single NEW item is a comment that overstates anchoring coverage for the `_next/*` reserved namespace — cosmetic, non-exploitable, behavior-unchanged, and already isolated by the k=3 fact-check. The single most important thing to (optionally) address is that one-line comment softening; it does not gate merge.

## Goal-Alignment Note

The goal was to confirm 0 Red and surface any NEW Amber `ab4dbdb` introduced. Result: **0 Red confirmed** (no Critical/High/Medium/Low; the two prior Mediums are verified CLOSED), and **0 NEW Amber** — the only thing `ab4dbdb` introduces that wasn't already present is a documentation overclaim that sits below the Amber bar (Informational, no behavior/security impact). Against the 0R+0A merge standard, this arm's disposition commit **passes** the security critic stage.
