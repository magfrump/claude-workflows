# API Consistency Review — csp-clean (d86d2dc..4f018ab)

**Scope:** `git diff d86d2dc..4f018ab` — `proxy.ts` (new), `proxy.test.ts` (new), `app/layout.tsx`, `app/lib/utils/exportGraph.ts`. Consumer-facing surfaces reviewed: the Next.js 16 Proxy contract (`proxy`, `config`), the newly exported `buildCsp`, the `x-nonce` / `Content-Security-Policy` request-header contract, the response CSP contract imposed on all browser clients, and the unchanged-signature `exportGraph` exports.
**Date:** 2026-08-06
**Based on:** merged code fact-check (`/workspace/runs/review-arms/e1/csp-clean/code-fact-check-report.md`) — its findings are treated as established and are not re-verified here.

`Commit: 4f018ab`

---

### Baseline Conventions

Sampled siblings: `app/lib/utils/export.ts`, `app/lib/utils/exportAll.ts`, `app/lib/utils/fileExtraction.ts`, `app/lib/formalization/artifactRoute.ts`, `app/api/predict/route.ts`, `app/api/analytics/route.ts`.

1. **Named function exports, verb-first, no default exports in `lib/`.** Every public helper is `export function <verb><Noun>` — `triggerDownload`, `downloadTextFile`, `sanitizeFilename`, `buildUserMessage`, `extractTextFromPDF`. The dominant verb prefixes across `app/lib` are `extract` (6), `generate` (5), `sanitize` (4), `get` (4), `download` (4). `build` appears once as a public export (`buildUserMessage`).
2. **Private module helpers stay unexported and sit above their callers.** `getPdfjs` in `fileExtraction.ts:24` and the `EXPORT_BG` constant in `exportGraph.ts:15` are the pattern: extract the shared body, do not widen the module's public surface.
3. **Errors are thrown as plain `Error` with a human-readable, context-naming message.** `fileExtraction.ts:85` — `` throw new Error(`Unsupported file type: .${ext ?? "(unknown)"}`) ``. There is no error-class hierarchy in `app/lib/utils`; only the LLM layer defines one (`OpenRouterError`, used consistently across all six `app/api/**/route.ts` handlers).
4. **No custom HTTP headers exist anywhere in the pre-change codebase.** `rg "headers\.set\(|'x-|\"x-" app` over `*.ts*` returns zero hits before this diff. API routes communicate exclusively through `NextResponse.json` bodies (`{ error: string }` for failures, bare object for success).
5. **Tests are colocated `*.test.ts` next to the module they test, importing via a relative `./` path, `vitest` globals opted in via `vitest.config.ts` with `environment: 'jsdom'` applied repo-wide.** When a helper is not exported, the established practice is to *re-implement* it in the test rather than widen the export surface — see `app/hooks/useDecomposition.test.ts:3`: `// Extract toPropositionNodes for testing by re-implementing the same logic.`
6. **Design decisions of any architectural weight get a numbered record.** `docs/decisions/` holds seven records (`001-formal-artifact-types.md` … `007-cost-estimation-model.md`), including framework-level ones (`001-vitest-test-framework.md`, `005-zustand-state-management.md`). `docs/ARCHITECTURE.md` enumerates the module layout.

---

### Name-Pattern Audit

All names newly introduced to a consumer-visible surface by this diff, plus the one changed export signature.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `buildCsp` | Exported pure function returning a string | `buildUserMessage(req): string` | `app/lib/formalization/artifactRoute.ts:10` | **Consistent** — verb-first, `build*` for string assembly, matches the single existing `build*` public export |
| `proxy` | Framework-contract export (Next 16 Proxy entry point) | none — first root-level framework module in the repo | `rg --files -g 'middleware*'` → no results | **Framework-dictated** — name is fixed by Next.js 16; no local convention to violate |
| `config` (matcher) | Framework-contract exported const | none | — | **Framework-dictated** |
| `x-nonce` | Request header name | none | no custom header is set anywhere in `app/` | **No precedent** — see F3 |
| `Content-Security-Policy` (set on the *request*) | Request header name | none | — | **No precedent** — see F3 |
| `renderGraphPng` | Module-private async helper | `getPdfjs` (private async helper above its callers) | `app/lib/utils/fileExtraction.ts:24` | **Consistent** |
| `"Failed to render graph PNG"` | Thrown `Error` message | `` `Unsupported file type: .${ext}` `` | `app/lib/utils/fileExtraction.ts:85` | **Consistent** |
| `proxy.test.ts` | Test-file location/name | `textSelection.test.ts` colocated, relative `./` import | `app/lib/utils/textSelection.test.ts:2` | **Consistent** |
| `RootLayout` (sync → `async`) | Changed framework export | — | `app/layout.tsx:22` | **Framework-permitted**, but see F1 |

---

### Findings

#### F1. The app-wide script-execution contract now depends on nonce propagation that nothing in the diff exercises

**Severity:** Breaking
**Location:** `proxy.ts:21-35` (`'strict-dynamic'`), `proxy.ts:44-52` (request-header forwarding), `app/layout.tsx:26-31` (`await headers()`)
**Move:** Consumer contracts — breaking changes
**Confidence:** Medium — the mechanism is certain; whether it currently holds end-to-end could not be executed here (`node_modules` is absent in this worktree) and is not covered by any test in the diff.
**Evidence:**
```
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```
and
```
  // Opt this layout into dynamic rendering so Next.js injects the per-request
  // nonce (set by proxy.ts) into its own bootstrap <script> tags during render.
  // The proxy already runs per request via its matcher; the dynamic-rendering
  // switch is what lets the rendered HTML pick up the nonce.
  await headers();
```
**Legibility-target:** a maintainer who later edits `app/layout.tsx` and removes the `await headers()` line because its return value is discarded and it looks dead.

`'strict-dynamic'` makes the `'self'` source expression **inert** in every CSP3-capable browser: after this change, no `<script>` executes unless it carries the nonce or was injected by a script that did. The entire browser-facing contract of the app therefore rests on a three-link chain — proxy sets the CSP on the forwarded *request* headers, the root layout opts into dynamic rendering, and Next.js parses `nonce-…` back out of that request header and stamps its bootstrap tags. Two of those three links are load-bearing side effects with no local reader: `await headers()` discards its result, and the request-side `Content-Security-Policy` header is never read by repo code. Baseline convention 5 shows the repo does test its utility contracts (`textSelection`, `workspacePersistence`, `fileExtraction` all have colocated suites), yet the one test added here (`proxy.test.ts`) exercises only the pure string builder — the propagation chain, which is what can actually white-screen every client, is untested. Breaking a link produces total script failure, not degradation.
**Recommendation:** Add one integration-level assertion that the rendered document's bootstrap `<script>` tags carry the same nonce the proxy issued (Playwright, or a Next `next build && next start` smoke check). Failing that, at minimum annotate `await headers()` with a `// DO NOT REMOVE —` prefix naming the CSP dependency, so the discarded return value reads as intentional.

#### F2. `x-nonce` is a published header contract with zero consumers, and its docstring names a consumer that does not exist

**Severity:** Inconsistent
**Location:** `proxy.ts:44-49`; the only layout, `app/layout.tsx:31`
**Move:** Asymmetries; consumer contracts — doc drift
**Confidence:** High — established by the merged fact-check (x-nonce written, never read) and confirmed here: `rg "x-nonce"` matches only `proxy.ts:49`.
**Evidence:**
```
  // Forward the nonce to server components via a request header so layouts
  // can read it via `headers()` and pass it to <Script> tags they render.
```
**Legibility-target:** a future contributor adding a third-party `<Script>` tag, who will read this comment, assume `x-nonce` is the supported channel, and be surprised that no precedent call site exists to copy.

The comment describes a producer/consumer pair, but the repo contains exactly one layout and it calls `await headers()` purely for its dynamic-rendering side effect — it never reads `x-nonce`, and no component renders a nonced `<Script>`. Baseline convention 4 is that this codebase has never before published a custom header; introducing one as the very first, with no reader, sets the precedent that headers are write-only. This is an asymmetry in the classic sense: the request side of the contract is populated, the consuming side is absent, and the docstring asserts a symmetry that the code does not have.
**Recommendation:** Either delete the `x-nonce` line and rewrite the comment to state accurately that the *`Content-Security-Policy`* request header is the operative mechanism Next.js reads, or keep `x-nonce` and add the one consumer that justifies it. Do not leave the comment describing a call site that does not exist.

#### F3. Header-name casing is inconsistent across two adjacent lines, with no repo precedent to appeal to

**Severity:** Minor
**Location:** `proxy.ts:49-50`
**Move:** Naming vs neighbors
**Confidence:** High
**No existing precedent in `app/**/*.ts*` and the repository root** — `rg "headers\.set\(|'x-|\"x-"` over the pre-change tree returns zero custom-header call sites, so there is no house style to match and this finding is scored one tier below the Inconsistent it would otherwise carry.
**Evidence:**
```
  requestHeaders.set("x-nonce", nonce);
  requestHeaders.set("Content-Security-Policy", csp);
```
**Legibility-target:** the next person to add a custom header, who has two contradictory examples two lines apart and no third to break the tie.

HTTP header names are case-insensitive, so nothing malfunctions; the cost is purely that this diff is establishing the repo's first header convention and establishes two of them simultaneously — lowercase-hyphenated for the custom header, canonical Title-Case for the standard one. That is a defensible rule (custom lowercase, standard canonical) but it is nowhere stated, so the next contributor will read it as an oversight. Baseline convention 4 means whatever lands here becomes the precedent by default.
**Recommendation:** Pick one and state the rule in a one-line comment, or lowercase both (`content-security-policy`) to match what the Fetch/Headers spec normalizes to anyway.

#### F4. The docstring's stated justification for `connect-src 'self'` cites an integration that does not exist

**Severity:** Minor
**Location:** `proxy.ts:18-19`
**Move:** Consumer contracts — doc drift
**Confidence:** High — established by the merged fact-check; corroborated here (`rg -i openalex` matches only `proxy.ts`, while `OpenRouter` and `@anthropic-ai/sdk` are real and used in six route handlers).
**Evidence:**
```
 * `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter
 * calls are server-to-server (Next API routes), not browser-to-third-party.
```
**Legibility-target:** anyone auditing whether `connect-src 'self'` is still safe after adding a new integration — the list they will diff against is wrong.

The justification is a load-bearing security argument: it enumerates the outbound integrations and asserts each is server-side. Two of the three named integrations are real; the third names a service the codebase has never called. An enumeration used as a safety argument that contains a phantom entry is worse than an unenumerated one, because a reader checking "is this list still complete?" gets a false signal that the list is maintained. Baseline convention 6 is that this repo documents its architectural reasoning carefully; this docstring is doing that job with a stale fact in it.
**Recommendation:** Drop `OpenAlex`, or replace the enumeration with the invariant that actually holds — "all third-party API calls originate from Next route handlers, never from the browser" — which stays true as integrations change.

#### F5. `buildCsp`'s test pins the serialization format while the assertions meant to pin the security surface are inert

**Severity:** Minor
**Location:** `proxy.test.ts:11,29-46`
**Move:** Consumer contracts — test drift
**Confidence:** High — the vacuity of the wildcard/`http:` assertions is established by the merged fact-check.
**Evidence:**
```
  const directives = csp.split("; ");
```
and
```
    expect(csp).not.toMatch(/\*\s/); // wildcard source not followed by directive end
    expect(csp).not.toMatch(/\bhttp:\b/);
```
**Legibility-target:** a maintainer who reads the test names, concludes `img-src`/`font-src`/`style-src` are protected against weakening, and relaxes one of them.

The suite turns `buildCsp`'s *output formatting* into a tested contract twice over — the `"; "` separator via `split`, and the exact ten-element directive ordering via the `emits the directive list in stable order` case — so any cosmetic reordering fails the build. Meanwhile the two assertions that were meant to guard the actual security surface cannot match anything, and `img-src`, `font-src`, and `style-src` are not pinned by any other case. The net effect inverts the intent stated in the file's own header comment (`so a refactor that weakens script-src, connect-src, frame-ancestors, or object-src fails loudly`): brittle where it should be flexible, silent where it should be loud.
**Recommendation:** Assert the three unpinned directives explicitly by full string, the way `locks down the highest-risk directives` already does for the other six, and drop or fix the two regex assertions rather than leaving them as false assurance.

#### F6. `buildCsp` widens the public surface for testability, against the repo's established test-access precedent

**Severity:** Minor
**Location:** `proxy.ts:21`, `proxy.test.ts:2`
**Move:** Naming vs neighbors; asymmetries
**Confidence:** High
**Precedent:** `re-implement the unexported helper inside the test rather than export it` used in `app/hooks/useDecomposition.test.ts:3`; the counter-precedent `export function buildUserMessage` (exported *and* called at `artifactRoute.ts:66`) is used in `app/lib/formalization/artifactRoute.ts:10`.
**Evidence:**
```
export function buildCsp(nonce: string): string {
```
**Legibility-target:** a reader deciding whether `buildCsp` is a supported entry point they may call from elsewhere, or an internal that happens to be visible.

The one existing `build*` export, `buildUserMessage`, is exported because it has a real in-repo caller. `buildCsp`'s only importer outside its own module is the test — making it the first export in this codebase whose entire justification is test access, at odds with `useDecomposition.test.ts`, which explicitly chose duplication over widening. This is arguably the *better* of the two practices, but it is now the minority one and carries no marker distinguishing it from a supported API. There is no `@internal`/`@visibleForTesting` convention anywhere in the repo to lean on.
**Recommendation:** Add a one-line `/** @internal — exported for proxy.test.ts; not a supported entry point. */` above it, and consider retro-fitting the same marker convention if a second such export appears.

#### F7. `buildCsp` accepts an unvalidated string into a security-critical serialization, with no signalled failure mode

**Severity:** Minor
**Location:** `proxy.ts:21-24`
**Move:** Nullability and contracts; error consistency
**Confidence:** High on the contract gap; the current sole caller passes base64, so exploitability today is nil.
**Evidence:**
```
export function buildCsp(nonce: string): string {
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
```
**Legibility-target:** the second caller of `buildCsp`, whoever they are — the signature promises that any string is acceptable.

Now that `buildCsp` is exported (F6), its type signature *is* its contract, and `nonce: string` promises total acceptance. A value containing `'`, `;`, or whitespace silently yields a malformed or attacker-shaped policy, and the `string` return type gives the caller no channel to detect it — there is no thrown error and no nullable result. The repo has a directly analogous precedent for defending a string before it reaches a sensitive sink: `sanitizeFilename` in `app/lib/utils/export.ts:34` strips unsafe characters and falls back to `"untitled"` rather than trusting its input. `buildCsp` sits at a strictly more sensitive sink and does less.
**Recommendation:** Guard with a base64 shape check and throw a plain `Error` on violation — matching baseline convention 3 (`fileExtraction.ts:85`) — or narrow the parameter to a branded nonce type produced by a single generator.

#### F8. A security-architecture change lands with no decision record and no `ARCHITECTURE.md` entry

**Severity:** Minor
**Location:** repository-level — `docs/decisions/`, `docs/ARCHITECTURE.md`
**Move:** Consumer contracts — doc drift
**Confidence:** High — `rg -l "CSP|Content-Security|proxy\.ts|middleware" docs documentation README.md CLAUDE.md CONTRIBUTING.md` matches only two unrelated Zustand documents.
**Evidence:** `docs/decisions/` contains `001-formal-artifact-types.md`, `001-vitest-test-framework.md`, `002-multi-artifact-ui-layout.md`, `003-artifact-generation-api.md`, `004-generalized-decomposition.md`, `005-streaming-api-responses.md`, `005-zustand-state-management.md`, `007-cost-estimation-model.md` — and no CSP record.
**Legibility-target:** a contributor who hits a CSP violation in the browser console and searches the docs for why.

Baseline convention 6 establishes that decisions of this weight — including framework-level ones like the test-runner and state-library choices — get a numbered record, and `docs/ARCHITECTURE.md` enumerates the module layout. This change introduces the first root-level framework module in the repo, permanently constrains what every future client-side dependency may do (no `eval`, no third-party script hosts, no cross-origin `fetch`), and encodes a deliberate carve-out (`style-src 'unsafe-inline'`) whose rationale currently lives only in a source comment that nobody grepping the docs will find. `ARCHITECTURE.md`'s module list does not mention `proxy.ts` at all.
**Recommendation:** Add `docs/decisions/008-strict-csp-nonces.md` capturing the `'strict-dynamic'` choice, the `'unsafe-inline'` style carve-out, and the dynamic-rendering cost from F1; add `proxy.ts` to the `ARCHITECTURE.md` module map.

#### F9. `downloadGraphAsPng` and `graphToPngBlob` now disagree on `async` in the same file

**Severity:** Informational
**Location:** `app/lib/utils/exportGraph.ts:26,34`
**Move:** Asymmetries
**Confidence:** High
**Evidence:**
```
export async function downloadGraphAsPng(
  viewportElement: HTMLElement,
  filename = "proof-graph.png",
) {
  triggerDownload(await renderGraphPng(viewportElement), filename);
}
...
export function graphToPngBlob(viewportElement: HTMLElement): Promise<Blob> {
  return renderGraphPng(viewportElement);
}
```
**Legibility-target:** a reader scanning the module's two public functions and inferring a rule about when this codebase marks a function `async`.

Both were `async` before the change; now one is and one is not, two functions apart, both returning promises and both awaited by their callers. Behaviourally this is neutral — `graphToPngBlob` still returns a promise, and a rejection from `renderGraphPng` surfaces identically to both call sites. The inconsistency is purely in what the file teaches: `downloadGraphAsPng` keeps `async` for a single `await`, while `graphToPngBlob` drops it for a bare pass-through, and no comment marks the distinction as deliberate.
**Recommendation:** No action required. If touched again, prefer `async` on both for uniformity within the module.

#### F10. API routes receive no CSP at all, so the response-header contract differs by surface

**Severity:** Informational
**Location:** `proxy.ts:56-70`
**Move:** Asymmetries; versioning/scoping
**Confidence:** High
**Evidence:**
```
      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
```
**Legibility-target:** a security reviewer who checks the site's headers on `/` and assumes the whole origin is covered.

Excluding `/api` is correct for the nonce machinery — JSON responses render no scripts and would waste a nonce — but it also drops the directives that *do* apply to non-HTML responses regardless of content type: `frame-ancestors 'none'` and `default-src 'self'` protect against a JSON endpoint being framed or content-sniffed into a document context. The sixteen `app/api/**/route.ts` handlers therefore serve with no CSP at all while every page serves with a strict one. The inline comment justifies the exclusion only in terms of "they don't render HTML", which is the narrower of the two considerations.
**Recommendation:** Optional — if API responses should carry `frame-ancestors 'none'`, apply a nonce-free minimal policy to `/api` via `next.config.ts` `headers()` rather than widening the proxy matcher, keeping the nonce path untouched.

#### F11. `proxy.test.ts` loads `next/server` into the repo-wide `jsdom` environment with no precedent and no environment pragma

**Severity:** Informational
**Location:** `proxy.test.ts:2`, `vitest.config.ts:8`
**Move:** Consumer contracts — test drift
**Confidence:** Medium — could not be executed (`node_modules` absent in this worktree); flagged as a risk, not a confirmed failure.
**Evidence:** `vitest.config.ts` sets `environment: 'jsdom'` globally with no per-file overrides anywhere in the repo; `proxy.test.ts:2` is `import { buildCsp } from "./proxy";` and `proxy.ts:1-2` import `NextResponse` and `NextRequest` from `next/server`.
**Legibility-target:** whoever debugs the first CI failure in this file and starts by suspecting `buildCsp` rather than the module graph.

Testing the pure `buildCsp` requires evaluating the whole `proxy.ts` module, which pulls the Next server runtime into a browser-shaped environment. Every one of the twenty-plus existing test files targets either browser code or a plain utility, so there is no sibling establishing that `next/server` imports resolve under `jsdom` in this setup. If it does fail, the failure will look like a `buildCsp` problem rather than an environment one.
**Recommendation:** Either add `// @vitest-environment node` at the top of `proxy.test.ts`, or move `buildCsp` into a dependency-free module (e.g. `app/lib/security/csp.ts`) that `proxy.ts` imports — which would also resolve F6.

---

### What Looks Good

- **The `exportGraph` refactor preserves every consumer contract it touches.** Both exported signatures are byte-identical from a caller's perspective, `toBlob` produces `image/png` by default (it delegates to `canvas.toBlob()` with no type argument, matching the `image/png` bytes the previous `toPng` → `fetch` → `blob` path yielded), so the `proof-graph.png` download filename and the `zip.file("proof-graph.png", pngBlob)` entry in `exportAll.ts:65` remain accurate. The new `if (!blob) throw` path is a genuinely *new* failure mode, and both call sites already tolerate it: `exportAll.ts:67-69` catches and `console.warn`s, `GraphPanel.tsx:105-107` catches and `console.error`s. This is the right way to change internals under a fixed signature.
- **`renderGraphPng` was extracted as a private helper, not a new export.** It matches baseline convention 2 (`getPdfjs` in `fileExtraction.ts:24`) and removes the duplication between the two public functions without enlarging the module's surface — the discipline F6 notes is missing on `buildCsp`.
- **The `data:`-to-`blob:` motivation is documented at the import site.** `// Use toBlob (not toPng + fetch) so we don't need 'data:' in CSP connect-src.` ties an otherwise-mysterious library-call change to the CSP decision in a different file, which is exactly the coupling a future maintainer needs to see before "simplifying" it back.
- **`buildCsp` names itself correctly.** Verb-first, `build*` for string assembly, matching the one existing precedent (`buildUserMessage`).
- **The `form-action` comment earns its place.** `// form-action does NOT fall back to default-src (CSP3); set explicitly.` documents a genuinely non-obvious spec detail at the exact line that depends on it.
- **The `style-src 'unsafe-inline'` carve-out is declared rather than smuggled.** The docstring names the specific call sites that force it and labels it "a deliberate carve-out, not an oversight" — the correct way to ship a known weakening.
- **`request: NextRequest` matches the parameter naming used by all six `app/api/**/route.ts` handlers**, and `proxy.test.ts`'s location and relative-import style match the colocated `*.test.ts` convention.

---

### Summary Table

| ID | Severity | Surface | Finding | Confidence |
|---|---|---|---|---|
| F1 | Breaking | Response CSP / all browser clients | `'strict-dynamic'` makes app-wide script execution depend on an untested three-link nonce-propagation chain | Medium |
| F2 | Inconsistent | `x-nonce` request header | Header contract has zero consumers; docstring asserts a reader that does not exist | High |
| F3 | Minor | Request header names | `x-nonce` vs `Content-Security-Policy` casing differs two lines apart; no repo precedent (tier reduced) | High |
| F4 | Minor | `proxy.ts` docstring | `connect-src` safety argument enumerates a nonexistent OpenAlex integration | High |
| F5 | Minor | `buildCsp` test contract | Serialization format over-pinned; wildcard/`http:` guards inert; three directives unpinned | High |
| F6 | Minor | `buildCsp` export | Exported solely for tests, against `useDecomposition.test.ts` precedent, with no `@internal` marker | High |
| F7 | Minor | `buildCsp(nonce: string)` | Unvalidated input into a security-critical serialization; no failure channel | High |
| F8 | Minor | Project docs | No decision record and no `ARCHITECTURE.md` entry for a security-architecture change | High |
| F9 | Informational | `exportGraph` exports | `async` marking now disagrees between the module's two public functions | High |
| F10 | Informational | `config.matcher` | `/api` excluded, so sixteen route handlers serve with no CSP at all | High |
| F11 | Informational | `proxy.test.ts` | `next/server` loaded under the repo-wide `jsdom` environment with no pragma or precedent | Medium |

---

### Overall Assessment

The public surface this change adds is small and, where local precedent exists, it follows it: `buildCsp` is named the way the one existing `build*` export is named, `renderGraphPng` stays private the way sibling private helpers do, thrown errors read like the ones in `fileExtraction.ts`, and the test file sits where every other test file sits. The `exportGraph` half of the diff is a model of changing internals under a frozen signature — signatures identical, output bytes identical, the one new failure mode already absorbed by both existing call sites, and the reason for the change documented at the line that would otherwise get reverted.

The weakness is concentrated in the contracts that are *not* expressed in TypeScript. Three separate mechanisms in `proxy.ts` — the forwarded request-side CSP header, the discarded `await headers()`, and `x-nonce` — are load-bearing or purported-to-be-load-bearing side effects with no local reader, and the comments describing them are more optimistic than the code (F2, F4). Because `'strict-dynamic'` neutralizes `'self'`, the cost of any one of those links silently breaking is total, and the single test added covers only the pure string builder while over-constraining its formatting and under-constraining its security surface (F1, F5). Nothing here is wrong in a way a compiler or a client integration would catch today; the risk is that the invariants live in prose that has already drifted once (OpenAlex) inside a diff that is still fresh.

The highest-leverage fixes are cheap and mostly independent: correct the two inaccurate comments, pin the three unpinned directives, and add one end-to-end assertion that the served HTML's bootstrap scripts carry the issued nonce. Moving `buildCsp` into a dependency-free `app/lib/security/csp.ts` would resolve F6 and F11 together and give the CSP a home the docs can point at.

---

## Goal-Alignment Note

- **Answered:** Whether the new public names (`buildCsp`, `proxy`, `config`, `renderGraphPng`, the `x-nonce` and request-side `Content-Security-Policy` header names, the new thrown-error message, the root-level test file) match established repo precedent — audited in full above against five sampled sibling modules. Whether the `exportGraph` internals change is safe for its two existing consumers — yes, PNG bytes and both signatures are preserved and both call sites already handle the new throw. Whether the new request-header contract has consumers — it does not. Whether the tested contract matches the claimed contract — it does not. Whether doc/decision-record conventions were followed — they were not.
- **Out of scope:** Whether `'strict-dynamic'`, `style-src 'unsafe-inline'`, and `connect-src 'self'` are the *right* security posture (security-reviewer's lane — this review only checks that the policy is expressed and documented consistently). The performance cost of converting the app from static prerendering to per-request dynamic rendering via `await headers()` (performance-reviewer's lane; noted here only as the mechanism behind F1). Whether `crypto.getRandomValues` and `Buffer` are both available in the Next 16 Proxy runtime — a correctness question the fact-check foundation covers. Module-boundary questions about `proxy.ts` living at the repository root (architecture-review's lane).
- **Escalate:** F1 needs an executable verification that this review could not run — `node_modules` is absent from the pinned worktree, so the nonce-propagation chain and the `jsdom`/`next-server` import in F11 are both reasoned rather than observed. Whoever can run `npm ci && npm test && npm run build` against `4f018ab` should confirm both before F1 is downgraded. F5's vacuous assertions and F4's phantom integration are inherited from the merged fact-check and are treated as settled facts here.
