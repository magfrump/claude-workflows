# Architecture Review — e3/csp-arm1 (strict CSP + per-request nonces)

**Scope:** `git diff d86d2dc..HEAD` in `/workspace/runs/review-arms/e3-loops/wt-csp-arm1` (branch `e3/csp-arm1`) — `proxy.ts` (new, 71 lines), `app/layout.tsx` (+18)
**Commit:** e5d95a9
**Date:** 2026-08-06
**Based on:** `code-fact-check-report.md` (merged, k=3) in this directory — treated as foundation; behavioral claims not re-verified.
**Trust-boundary cross-reference:** no-op. No `security-review*.md` exists in this directory or in `docs/reviews/` at review time, so module-boundary findings below carry no boundary labels. If a security review lands later, findings A1, A2 and A4 are the ones whose locations would need label correlation.

## Dependency Map

The diff adds one new top-level module and one new dependency edge into an existing one.

- **`proxy.ts` (repo root, new).** A framework-entry module: Next.js 16 discovers it by filename and invokes the exported `proxy()` on every matched request. It depends only on `next/server` (`NextResponse`, `NextRequest` type) and on the ambient `process.env`. Nothing in the repo imports it; nothing can. It exports `proxy` and `config`; `buildCsp` is module-private.
- **`app/layout.tsx` (existing).** Gains an import of `next/headers` and becomes `async`. Its new dependency is not on `proxy.ts` as a module — there is no import — but on `proxy.ts`'s *runtime behavior*: the `await headers()` call exists solely to force dynamic rendering so that the proxy's per-request work is not bypassed by prerendering. This is a real dependency edge with no compile-time representation.
- **The nonce's intended consumer** is Next's app-renderer, reached through a header channel rather than an import. Per the merged fact-check (Claim 1), the renderer reads the nonce from the *request's* `content-security-policy` header (`app-render.js:166-167`); `proxy.ts` writes the CSP to the *response* and writes `x-nonce` to the request. So the producer and the consumer are wired to two different channels, and neither end of the intended contract is expressed in code that a type checker or test could hold.
- **Layering.** This repo's implicit layering is `app/api/**` (route handlers) → `app/lib/**` (logic, with colocated `*.test.ts`) → `app/components/**` / `app/hooks/**` (UI). `proxy.ts` sits outside all of it at the root, which is framework-mandated for the entry point — but it also carries the policy logic, which is not.

Dependency direction is not inverted anywhere: nothing stable was made to depend on anything volatile. The structural problems in this diff are all about **channels that exist only in comments** — a producer/consumer pair with no contract, a live seam with no consumer, and a render-mode switch expressed as a discarded side effect.

## Findings

#### The nonce delivery contract exists only in prose, split across three unlinked write sites

**Severity:** Structural
**Location:** `proxy.ts:41-56`, `app/layout.tsx:27-30`
**Move:** #1 (dependency direction), #7 (coupling surface)
**Confidence:** High

**Move:** Give the delivery channel a single named owner that writes every header the contract requires, so the producer and consumer cannot drift onto different channels.
**Legibility-target:** A maintainer changing how the nonce reaches the renderer — six months from now, on a different Next major.

The mechanism that makes this feature work spans three write sites that have no relationship to each other: `requestHeaders.set("x-nonce", nonce)`, `response.headers.set("Content-Security-Policy", ...)`, and a comment in a different file asserting which of the two Next consumes. The fact-check establishes that the assertion is wrong and the required write — the CSP on the *request* headers — is absent. The architectural point is not that one line is missing; it's that **nothing in the structure could have caught it**. There is no interface, no type, no test, and no single function that owns "deliver the nonce to the renderer," so the correctness of the whole feature rests on a comment. The consequence compounds: the next person who changes the delivery (Next 17 changes the channel, or the app adds a `<Script>` tag) has to re-derive the mechanism from framework internals, because the code records only the outcome someone believed, not the contract. Note that the belief shipped inside a commit message claiming end-to-end verification (Claim 13), which is what an unrepresented contract looks like from the outside — confident and unfalsifiable.

**Evidence:** `proxy.ts:49` — `requestHeaders.set("x-nonce", nonce);`; `proxy.ts:55` — `response.headers.set("Content-Security-Policy", buildCsp(nonce));`; `app/layout.tsx:28-30` — `// and can attach a fresh per-request CSP nonce. Next.js automatically tags` / `// its own bootstrap <script> elements with the nonce from the response's` / `// CSP header, so we don't need to read x-nonce here ourselves.`

**Recommendation:** Collapse the delivery into one function in `proxy()` that computes the policy string once and writes it to *both* the forwarded request headers and the response (`requestHeaders.set("Content-Security-Policy", csp)` — the documented Next pattern), so a single call site owns the contract. Then state the contract in one comment at that call site and delete the competing comment in `layout.tsx`.

---

#### The one testable unit of a cross-cutting security control is module-private in an untestable file

**Severity:** Structural
**Location:** `proxy.ts:24-39`
**Move:** #3 (module boundary audit)
**Confidence:** High

**Move:** Relocate the policy builder into the tested layer (`app/lib/**`) and leave `proxy.ts` as thin framework glue.
**Legibility-target:** Anyone tightening or loosening a directive later — the person who will want to know whether `'unsafe-eval'` really is dev-gated without booting a browser.

`buildCsp` is a pure function from a nonce to a policy string — exactly the shape that is cheap to test — and it is unexported inside a root-level file that no test can import, in a repo carrying **24 test files across `app/lib/**`, `app/hooks/**`, and `app/components/**` — and zero on the CSP**. The boundary is drawn in the wrong place: `proxy.ts` must live at the root because the framework demands the filename, but the *policy* has no reason to live there. The consequence is that every future policy question is answered by inspection or by a browser, not by a test — and the fact-check already found four wrong claims embedded in this function's docstring (`connect-src` sufficiency, the Tailwind rationale, the Edge-runtime claim, the strict-dynamic protection story). A test file would not have caught all of those, but a test asserting "prod build contains no `'unsafe-eval'`" and "the directive list contains `connect-src`" would have made the policy an object of study rather than a wall of prose. This is the highest-leverage structural change available in this diff and it costs about twenty lines.

**Evidence:** `proxy.ts:24` — `function buildCsp(nonce: string): string {` (no `export`); `proxy.ts:66-71` — the `matcher` block is the file's only other exported surface; repo test convention: `app/lib/utils/textSelection.test.ts`, `app/lib/llm/costs.test.ts`, `app/lib/stores/__tests__/workspaceStore.test.ts` et al.

**Recommendation:** Move `buildCsp` to `app/lib/security/csp.ts`, export it, and add `app/lib/security/csp.test.ts` covering the dev/prod branch, the presence of each directive, and nonce interpolation. `proxy.ts` then imports it and keeps only request/response plumbing.

---

#### `buildCsp` reads ambient environment instead of taking it as input, so the production policy cannot be exercised

**Severity:** Coupling
**Location:** `proxy.ts:25-26`
**Move:** #5 (interface segregation), #3 (module boundary)
**Confidence:** High

**Move:** Push the environment read out to the caller so the policy builder is a function of its arguments.
**Legibility-target:** The test author for the finding above — and anyone who wants to diff the dev policy against the prod policy.

The function's signature says it depends only on a nonce; its body says it also depends on `process.env.NODE_ENV`. That hidden second input is what makes the dev carve-out impossible to verify from a test process, which always runs with `NODE_ENV` set by the runner: you can never observe the production branch without mutating global state. This is a small change with an outsized effect on the previous finding — once the environment is a parameter, both branches are one assertion each. It also makes the security-relevant question ("does `'unsafe-eval'` ever ship?") answerable at the call site rather than buried in a string builder.

**Evidence:** `proxy.ts:25-26` — `const devOnly =` / `process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : "";`

**Recommendation:** Change to `buildCsp(nonce: string, opts: { dev: boolean })` and read `process.env.NODE_ENV === "development"` once inside `proxy()`. Keep the `=== "development"` comparison (it fails closed on unknown values); only its location changes.

---

#### `await headers()` is a discarded side effect standing in for a declarative render-mode switch

**Severity:** Coupling
**Location:** `app/layout.tsx:22-40`
**Move:** #7 (coupling surface), #8 (extension points)
**Confidence:** High

**Move:** Express the dynamic opt-out through the framework's first-class segment config rather than through a call whose value is thrown away.
**Legibility-target:** A future maintainer running a lint pass, a code-simplifier sweep, or a "why is this layout async?" cleanup.

The layout now depends on the proxy's behavior, but the dependency is encoded as a call whose return value is discarded — the coupling is real and the code looks like dead weight. Twelve lines of comment are doing the work that the framework has an API for: any tool or person that removes `await headers()` gets a statically prerendered layout, a stale-or-absent nonce baked into the HTML, and no failing test. The comment is now accurate (the fact-check confirms Claims 2 and 3), which makes it good documentation of *why* — but documentation is the wrong mechanism for an invariant this brittle. Next provides `export const dynamic = "force-dynamic"` for exactly this, which states the intent in the module's public surface instead of hiding it in a statement with no observable effect.

**Evidence:** `app/layout.tsx:40` — `  await headers();` (return value unused); `app/layout.tsx:27-28` — `// Opt this layout out of static rendering so proxy.ts runs on every request` / `// and can attach a fresh per-request CSP nonce.`

**Recommendation:** Replace `await headers()` with `export const dynamic = "force-dynamic";` and revert `RootLayout` to a synchronous function. Keep the second paragraph of the comment (the waive rationale) attached to the new export; drop the first paragraph's claim about response-header nonce tagging per finding A1.

---

#### `x-nonce` is a published seam with a producer, a documented consumer contract, and zero consumers

**Severity:** Coupling
**Location:** `proxy.ts:46-50`
**Move:** #3 (module boundary audit), #5 (interface segregation)
**Confidence:** High

**Move:** Either wire the seam to a real consumer as part of the A1 fix, or delete it so the module's surface matches what it actually provides.
**Legibility-target:** A developer adding a `<Script>` tag who greps for `x-nonce`, finds this, and assumes the plumbing works.

The proxy publishes a request header and a comment describing precisely how a layout would consume it — and no layout does; the repo-wide grep for `x-nonce` returns the write site and the comment in `layout.tsx` that explicitly declines to read it. An interface with no implementor is not free: it is the most convincing kind of misinformation, because it is code rather than prose. The cost lands on the next person who adds an inline script and trusts that the nonce is already reaching server components — which, per Claim 9 and Claim 1, it is neither reaching nor the channel Next would use. Worse, the seam's existence makes the actually-missing channel (CSP on the request headers) *less* likely to be noticed, because the file appears to already forward something to the request side.

**Evidence:** `proxy.ts:46-49` — `// Forward the nonce to server components via a request header so layouts` / `// can read it via \`headers()\` and pass it to <Script> tags they render.` / `const requestHeaders = new Headers(request.headers);` / `requestHeaders.set("x-nonce", nonce);`; fact-check Claim 9: repo-wide `x-nonce` grep = 2 matches (write site + declining comment); no `next/script` usage in `app/`.

**Recommendation:** If A1 is fixed by setting the CSP on `requestHeaders`, keep `requestHeaders` and drop `x-nonce` (Next extracts the nonce from the CSP itself). If a `<Script>` consumer is genuinely planned, add it in the same change; do not leave the seam standing on its own.

---

#### Response security headers now have two plausible homes and no stated owner

**Severity:** Minor
**Location:** `proxy.ts:53-56`, `next.config.ts:3-5`
**Move:** #2 (responsibility boundaries)
**Confidence:** Medium

**Move:** Name `proxy.ts` as the single owner of per-response security headers before a second one is added elsewhere.
**Legibility-target:** Whoever adds `Strict-Transport-Security`, `Referrer-Policy`, or `Permissions-Policy` next.

`next.config.ts` is currently an empty config with a `/* config options here */` placeholder, and its `headers()` hook is the conventional Next home for *static* security headers. `proxy.ts` is now the home for the one *dynamic* header. Nothing records that split, so the next security header will be placed by coin flip — and once headers live in two places, questions like "what is our actual response policy?" require reading two files with different execution models (build-time config vs. per-request function), and a `frame-ancestors`/`X-Frame-Options` style overlap becomes easy to introduce. The current state is fine; the ambiguity is what will cost.

**Evidence:** `proxy.ts:55` — `response.headers.set("Content-Security-Policy", buildCsp(nonce));`; `next.config.ts:3-5` — `const nextConfig: NextConfig = {` / `  /* config options here */` / `};`

**Recommendation:** Add one line to the `proxy.ts` docstring stating that all response security headers belong here (not `next.config.ts`) because the CSP is per-request and splitting them would fragment the policy. Or, if the team prefers the config hook for static headers, say that instead — the value is in the sentence existing.

---

#### The `matcher` config is the module's only extension point and it extends by editing a regex

**Severity:** Informational
**Location:** `proxy.ts:58-71`
**Move:** #8 (extension points)
**Confidence:** High

**Move:** None required at this size — recorded so the growth pattern is recognized if it starts.
**Legibility-target:** A reviewer of the *next* change to this file.

Exempting a new class of route means adding another alternative to a negative-lookahead group inside a string. That is modification rather than extension, and the readability cost grows non-linearly: `(?!api|_next/static|_next/image|favicon.ico)` is already at the edge of scannable. With four exclusions this is unambiguously the right call — a registry of matchers would be over-engineering. The signal to watch is a fifth and sixth exclusion arriving with unrelated features, at which point the pattern should become a named array of `source` entries instead.

**Evidence:** `proxy.ts:63` — `      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",`

**Recommendation:** No action. If a third contributor adds an exclusion, split `matcher` into multiple `source` objects with a comment each, rather than lengthening the lookahead.

---

#### New top-level module establishes a pattern; the pattern is currently "root file with logic inside"

**Severity:** Informational
**Location:** `proxy.ts` (whole file)
**Move:** #4 (layer violations)
**Confidence:** Medium

**Move:** Establish now that root-level framework-entry files are glue only.
**Legibility-target:** The author of the next root-level framework file (`instrumentation.ts`, `proxy` successors, route interceptors).

This is the repo's first root-level runtime module — everything else executes from `app/**`. It is not a layer *violation*: the proxy sits above the application layer and depends on nothing inside it, which is the correct direction. But it does establish a precedent, and the version being established bundles policy logic into the framework entry point. The next such file (instrumentation, a rate limiter, a request logger) will copy whatever this one does. The fix in finding A2 also resolves this, which is part of why A2 is worth doing beyond its testing payoff: it sets the precedent as "root file = adapter, `app/lib/** `= logic," matching how `app/api/**/route.ts` handlers already delegate to `app/lib/llm/*` rather than inlining.

**Evidence:** `proxy.ts:24-39` (policy construction) and `proxy.ts:41-56` (framework plumbing) in one file; compare `app/api/verification/lean/route.ts` and `app/lib/llm/callLlm.ts` — handler and logic separated.

**Recommendation:** Fold into the A2 refactor; no separate action.

## What Looks Good

- **Dependency direction is correct throughout.** The proxy depends on `next/server` and nothing in `app/**`; no application module was made to depend on the proxy by import. A cross-cutting concern was added without dragging the domain along with it, which is the failure mode most CSP retrofits hit.
- **The layout stayed out of the nonce business.** Declining to read `x-nonce` and render nonced `<Script>` tags by hand keeps the presentation layer free of security plumbing. The decision is right even though the comment justifying it is wrong — the fix belongs in the proxy, not in the layout.
- **The dev carve-out fails closed.** `NODE_ENV === "development"` (strict equality against the permissive value) means any unexpected environment string yields the *stricter* policy. The alternative shape — `!== "production"` — would have shipped `'unsafe-eval'` on any misconfigured deploy. This is the right default direction for a security control, and e5d95a9 chose it deliberately.
- **The matcher is scoped rather than global.** Excluding API routes and static assets keeps the header off responses that have no scripts to protect, which limits the blast radius of a policy mistake to HTML navigations — a real containment property, not just an optimization.
- **The waive rationale is recorded where the waive happens.** The expanded `layout.tsx` comment explains not just what the dynamic opt-out does but why the cost is acceptable *for this app specifically* and what would invalidate that (switching nonces to hashes). Even though finding A4 recommends moving the mechanism, this comment should survive the move — it is the kind of context that is otherwise unrecoverable.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| A1 | Nonce delivery contract exists only in prose, split across three unlinked write sites | Structural | `proxy.ts:41-56`, `app/layout.tsx:27-30` | High |
| A2 | The one testable unit of a cross-cutting security control is module-private and untestable | Structural | `proxy.ts:24-39` | High |
| A3 | `buildCsp` reads ambient `NODE_ENV` instead of taking it as input | Coupling | `proxy.ts:25-26` | High |
| A4 | `await headers()` is a discarded side effect standing in for a declarative render-mode switch | Coupling | `app/layout.tsx:22-40` | High |
| A5 | `x-nonce` is a published seam with zero consumers | Coupling | `proxy.ts:46-50` | High |
| A6 | Response security headers have two plausible homes and no stated owner | Minor | `proxy.ts:53-56`, `next.config.ts:3-5` | Medium |
| A7 | `matcher` extends by editing a regex | Informational | `proxy.ts:58-71` | High |
| A8 | First root-level runtime module sets a "logic in the entry file" precedent | Informational | `proxy.ts` | Medium |

## Overall Assessment

The change is structurally sound in the ways that are expensive to fix later — dependency direction is correct, the security concern is isolated from the domain, and the presentation layer was kept out of the nonce plumbing — and structurally weak in exactly one way that explains everything the fact-check found: **the feature's central contract has no representation in code.** A1, A2, A4 and A5 are four symptoms of that single cause. The nonce's path from producer to consumer lives in a comment; the policy that path protects lives in a private function no test can reach; the render-mode invariant the whole thing depends on lives in a discarded expression; and a header seam that looks like the delivery channel isn't one. Each of those is individually small, and together they are why a wrong belief about which header Next reads could ship under a commit message asserting verification — there was nothing for it to collide with. The good news is that all four are fixable in place, in one change, without restructuring anything: extract `buildCsp` to `app/lib/security/csp.ts` with a test and an explicit `dev` parameter, make `proxy()` write the CSP to both request and response from a single call site, swap `await headers()` for `export const dynamic`, and drop `x-nonce`. That refactor also happens to be where the A1 correctness fix naturally lands, so the structural and the functional work are the same work. The single most important concern: **do not fix the missing request header without also giving the CSP a test and a single owner** — a one-line fix to an untested, comment-documented mechanism reproduces the exact conditions that produced this bug, and the next wrong belief will ship just as confidently.

## Goal-Alignment Note

- **Answered:** All briefed lenses. Dependency direction (Dependency Map — correct, no inversions); responsibility boundaries (A6, A8); module boundary audit including `buildCsp` privacy and zero tests on a cross-cutting security control (A2); layer violations (A8 — precedent, not violation); interface segregation (A3, A5); substitutability (no subtypes or polymorphism in the diff — move #6 does not apply); coupling surface including `layout.tsx`'s `await headers()` coupling to proxy behavior (A4) and the `x-nonce` seam with no consumer (A5); extension points (A7, A4's `dynamic` export). Findings lead with consequences and use the Structural / Coupling / Minor / Informational scale.
- **Out of scope:** Whether the missing request-side CSP header is *exploitable* or merely breaks the app (security-reviewer's call); whether `connect-src 'self'` breaking `exportGraph.ts` is a correctness or security defect (fact-check Claim 6 — flagged there, not re-litigated here); the accuracy of individual directive rationales in the docstring (Claims 5, 7, 8 — documentation accuracy is the fact-check's domain, and A2 addresses only the structural reason they went unchecked); performance of per-request nonce generation. No trust-boundary labels referenced because no `security-review.md` existed in this directory at completion — if one is produced, A1, A2 and A5 sit on the proxy-to-renderer transition and should be correlated.
- **Escalate:** Two items need a human decision. (1) **Sequencing** — A2's extract-and-test refactor and the A1 correctness fix touch the same lines; doing A1 alone is fast but leaves the mechanism untested, and the assessment above argues against that. Someone should decide whether this arm ships the one-liner or the refactor. (2) **The `x-nonce` seam's future** — A5's recommendation branches on whether a `<Script>` consumer is actually planned; if the roadmap has one, deleting the seam is wrong and it should be wired instead. Neither question is answerable from the diff.
