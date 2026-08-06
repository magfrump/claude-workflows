# API Consistency Review — meta-formalism-copilot `HEAD~3..HEAD` (post-review fix batch on `integration/6.1`)

**Commit:** 7f30210
**Scope:** `git diff HEAD~3..HEAD` — commits 4d5f743, 2e23824, c0e0a35, merge 7f30210. Files: `proxy.ts`, `proxy.test.ts`, `app/components/panels/BalancedPerspectivesPanel.tsx`, `app/components/panels/BalancedPerspectivesPanel.test.tsx` (new), `app/lib/stores/evidenceStore.ts`, `app/api/evidence-search/route.ts`.
**Date:** 2026-08-06
**Based on:** code-fact-check report (k=3 merged; 0 Incorrect, 0 Stale) — used as foundation, not re-verified.
**Partial-scope note:** files outside the range are context only. Where a finding touches out-of-range code (`app/lib/types/artifacts.ts`, `app/lib/llm/schemas.ts`, `app/lib/corpus/flag.ts`), it is cited as the *baseline the in-range change is measured against*, not as a defect under review.

---

## Baseline Conventions

Read before judging: `app/lib/corpus/flag.ts`, `app/lib/utils/export.ts`, `app/lib/corpus/fsaPicker.ts`, `app/lib/corpus/manifest.ts`, `app/lib/utils/pdfPropositionParser.ts`, `app/lib/utils/mergeStreamingPreview.ts`, `app/hooks/useStreamingMerge.ts`, `app/lib/types/artifacts.ts`, `app/lib/llm/schemas.ts`, `app/components/panels/CounterexamplesPanel.tsx` + `.test.tsx`, `app/api/formalization/balanced-perspectives/route.ts`.

1. **Environment gating is an internal hard short-circuit, not a caller-supplied argument.** The one prior dev-only feature in the repo, `isCorpusEnabled()`, reads `process.env.NODE_ENV` *inside the function body* and returns early. It takes no parameters at all, so no caller can override it. Its comment explicitly frames the guard as un-overridable and names the exact condition under which it may be removed.

2. **Default parameter values are compile-time constants or dependency seams — never ambient environment reads.** Every pre-existing default in the codebase falls into two buckets: literal constants (`root = ""`, `mimeType = "text/plain"`, `filename = "semiformal-proof.md"`, `filename = "proof.lean"`, `fontName: string = ""`) or an injectable collaborator for testability (`store: HandleStore = idbStore()`, `now = new Date().toISOString()`). None reads `process.env` in the default expression. `buildCsp`'s new default is the first.

3. **Boolean names use the `is*` / `has*` prefix family.** Across params, props, and fields: `isDecompMode`, `isBold`, `isItalic`, `isEmpirical`, `isStale`, `isBusy`, `isLoading`, `isScoring`, `isAnalyzing`, `isRetry`, `isConfounder`, `isActive`, `hasData`, `hasDisplayData`, `hasContent`, `hasCausalGraph`, `hasStatisticalModel`, `hasPropertyTests`, `hasBalancedPerspectives`, `hasCounterexamples`, `hasReviews`.

4. **Streaming panels guard partials positionally, by kind.** Objects/scalars are gated with `&&` (`{displayMap.topic && …}` line 46, `{displayMap.summary && …}` line 56, `{displayMap.synthesis && …}` line 129); arrays use optional chaining plus a length gate (`(displayMap.perspectives?.length ?? 0) > 0` + `perspectives?.map`); leaf strings inside an already-guarded container render bare (`{p.coreClaim}`, `{t.description}`), which is safe because React renders `undefined` as nothing.

5. **The streaming type contract is a lie by design, repo-wide.** `mergeStreamingPreview<T>(finalData: T | null, streamingPreview: T | null | undefined, …)` types the mid-stream preview as a *complete* `T`. No `Partial<T>` / `DeepPartial<T>` exists anywhere. Panels therefore compensate at render sites (convention 4) rather than in the type system. `app/page.tsx:994` casts the raw streaming JSON straight to the full response type.

6. **Artifact schemas use `Array<…>` / `string[]` for every multi-value field.** `supportingArguments: string[]`, `vulnerabilities: string[]`, `howAddressed: Array<…>`, `perspectives: Array<…>`, `scenarios: Array<…>`. `between: [string, string]` (`artifacts.ts:100`) is the **only** fixed-length tuple in the entire artifact type surface — and the only one in the repo outside the mock that feeds it.

7. **Sub-types are derived by indexed access, never re-declared.** `BalancedPerspectivesResponse["balancedPerspectives"]` (hooks, panel props, `exportAll.ts`), `EvidenceOverlapRequest["papers"][number]`, `CounterexamplesResponse["counterexamples"]["scenarios"][0]`. Both `[number]` and `[0]` appear; `[number]` is the more common form.

8. **Panel tests share a fixed shape:** mock `EditableSection` and `ArtifactPanelShell` (the latter gating on `hasData`), a `makeData(...)` factory, a `baseProps` object with the artifact prop typed `null as T | null`, single-quoted strings.

9. **CSP has exactly one definition site.** `next.config.ts` is empty of headers; `buildCsp` in `proxy.ts` is the sole producer, consumed at `proxy.ts:53` and set on both the forwarded request and the response. It was exported solely to make it testable (`docs/reviews/csp-headers/code-review-rubric.md` A4, `test-strategy-review.md:96`).

---

## Name-Pattern Audit

New public names introduced in this range. `buildCsp`'s new parameter is public surface because `buildCsp` is exported. Locals (`scriptSrc`), test-file-local types (`BalancedPerspectives`, `Tension`) and test helpers (`makeData`, `baseProps`, `partialTension`) are not public API but are listed where a convention applies. **No new exported functions, types, endpoints, config fields, CLI flags, or event payloads were added in this range.**

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `allowUnsafeEval` | Public boolean parameter on an exported function | `isRetry`, `isDecompMode`, `hasData` | `app/api/formalization/lean/route.ts:62`, `app/hooks/useActiveArtifactState.ts:20`, `app/components/panels/ArtifactPanelShell.tsx:28` | Deviates — first `allow*` boolean in the repo (see F5) |
| `buildCsp(nonce, allowUnsafeEval = …)` | Exported-function signature change (2nd positional optional param) | `downloadTextFile(content, filename, mimeType = …)`, `saveHandle(handle, store = idbStore())` | `app/lib/utils/export.ts:21`, `app/lib/corpus/fsaPicker.ts:140` | Shape OK (trailing optional positional); **default value** deviates (see F2) |
| `scriptSrc` (local const) | Local variable | `directives`, `nonce`, `csp` | `proxy.ts:33,51,53` | OK |
| `BalancedPerspectives` (test-local alias) | Derived type alias | `OverlapPaper = EvidenceOverlapRequest["papers"][number]` | `app/api/evidence-overlap/overlapUtils.ts:14` | OK |
| `Tension` (test-local alias) | Derived type alias via `["tensions"][number]` | `["counterexamples"]["scenarios"][0]`, `["papers"][number]` | `app/components/panels/CounterexamplesPanel.test.tsx:18`, `app/api/evidence-overlap/overlapUtils.test.ts:10` | OK — `[number]` is the majority form |
| `makeData(tensions: Tension[])` (test helper) | Test factory | `makeData(cxOverrides: Partial<…> = {})` | `app/components/panels/CounterexamplesPanel.test.tsx:30` | Deviates mildly (see F9) |

---

## Findings

### F1 — Dev-only gating is exposed as a caller-overridable parameter, contradicting both the docstring and the repo's established hard-guard pattern

**Severity:** Inconsistent
**Location:** `proxy.ts:22-32` (signature + docstring), consumer at `proxy.ts:53`
**Move:** 3 (consumer contract), 6 (versioning/semantics), 1 (baseline)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
> ```
> proxy.ts:21-32
>  * Why `allowUnsafeEval` in development only: Next.js's dev server (HMR + eval
>  * source maps) injects `eval()`-based code that a strict CSP blocks, flooding
>  * the browser console with EvalErrors. Production output is genuinely
>  * eval-free, so `'unsafe-eval'` is added only when NODE_ENV !== "production".
>  */
> export function buildCsp(
>   nonce: string,
>   allowUnsafeEval: boolean = process.env.NODE_ENV !== "production",
> ): string {
> ```
> ```
> app/lib/corpus/flag.ts:15-21
> export function isCorpusEnabled(): boolean {
>   // Hard production guard: ... Refuse to activate in a production build so the dev flag can never
>   // become an end-user data-loss footgun (security review C2). Remove this guard
>   // only when S4 ships migration and the flag becomes a real, safe rollout knob.
>   if (typeof process !== "undefined" && process.env?.NODE_ENV === "production") return false;
> ```

The repo already made this exact decision once and made it the opposite way. `isCorpusEnabled()` gates a dev-only capability with a zero-argument function whose `NODE_ENV === "production"` short-circuit no caller can defeat — a shape adopted *specifically in response to a prior security review* (C2), and reaffirmed as load-bearing in `docs/working/research-corpus-s2.md:36` and `research-corpus-s3.md:39`. `buildCsp` gates an analogous dev-only capability by making the environment check merely the *default* of a public parameter, so the docstring's unconditional claim ("added only when NODE_ENV !== production") holds only for the single current call site at `proxy.ts:53`. The fact-check already escalated this; the API-consistency angle is that the deviation is not merely theoretical — the codebase has a settled convention and this contradicts it. Because `buildCsp` is exported (for tests) from the module that also exports the Next.js `proxy` entry point, a future caller — a second matcher branch, a route handler that wants to reuse the policy, an edge-runtime variant — can pass `true` and ship `'unsafe-eval'` to production with no test failing.

**Recommendation:** Keep the environment read inside the body (`const allowUnsafeEval = process.env.NODE_ENV !== "production"`) and, if tests need to pin it, expose the seam as a non-default-carrying internal — e.g. `buildCsp(nonce)` plus an explicitly-named `buildCspForEnv(nonce, env: string)` used only by the test — mirroring `flag.ts`. If the parameter stays, hard-clamp it (`const useEval = allowUnsafeEval && process.env.NODE_ENV !== "production"`) so the docstring's contract is enforced rather than merely asserted.

---

### F2 — Default parameter value reads `process.env`; every other default in the codebase is a constant or an injectable seam

**Severity:** Inconsistent
**Location:** `proxy.ts:28`
**Move:** 1 (baseline), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
> ```
> proxy.ts:26-29
> export function buildCsp(
>   nonce: string,
>   allowUnsafeEval: boolean = process.env.NODE_ENV !== "production",
> ): string {
> ```
> ```
> app/lib/utils/export.ts:21
> export function downloadTextFile(content: string, filename: string, mimeType = "text/plain") {
> ```
> ```
> app/lib/corpus/fsaPicker.ts:140
> export async function saveHandle(handle: FileSystemDirectoryHandle, store: HandleStore = idbStore()): Promise<void> {
> ```
> ```
> app/lib/corpus/manifest.ts:47
> export function createManifest(title: string, now = new Date().toISOString()): WorkspaceManifest {
> ```

The six pre-existing default parameters in this repo are either literal constants (`export.ts:21,26,30`, `gitFs.ts:124`, `pdfPropositionParser.ts:126,135`) or a dependency the caller may substitute in a test (`fsaPicker.ts:140,146`, `manifest.ts:47`). Both categories make the *declared* default fully visible at the call site. `buildCsp`'s default is neither: it is an ambient-state read whose evaluated value differs per process, so the function's behavior with an omitted argument is not determinable from the signature. Consumer impact is concrete and already realized inside this diff: Vitest sets `NODE_ENV="test"`, so the default silently flipped to `true` for every test, which is why `proxy.test.ts:12` had to be changed to pass `false` — a test-visible behavior change to an existing call form. Note this is "establishing a new pattern," not violating an explicitly documented rule; the cost is that the new pattern is strictly less legible than the one it departs from.

**Recommendation:** Move the environment read into the body (folds together with F1's recommendation). If the parameter is retained, type it `allowUnsafeEval?: boolean` and resolve `?? (process.env.NODE_ENV !== "production")` internally, so the signature does not advertise an environment-dependent default.

---

### F3 — Producer and consumer disagree on `between`'s arity: JSON Schema says unbounded array, TypeScript says fixed 2-tuple, and the new guard hardens absence but not arity

**Severity:** Inconsistent
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119` (in range); baseline at `app/lib/llm/schemas.ts:129` and `app/lib/types/artifacts.ts:100`
**Move:** 3 (consumer contract), 7 (asymmetry), 8 (nullability)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
> ```
> app/components/panels/BalancedPerspectivesPanel.tsx:113-119
>                       {t.between && (
>                         <div className="flex items-center gap-1 text-xs font-mono text-red-700">
>                           <span>{t.between[0]}</span>
>                           <span className="text-red-400">&harr;</span>
>                           <span>{t.between[1]}</span>
>                         </div>
>                       )}
> ```
> ```
> app/lib/llm/schemas.ts:126-130
>             required: ["between", "description"],
>             additionalProperties: false,
>             properties: {
>               between: { type: "array", items: { type: "string" } },
>               description: { type: "string" },
> ```
> ```
> app/lib/types/artifacts.ts:99-102
>     tensions: Array<{
>       between: [string, string];
>       description: string;
>     }>;
> ```

Three descriptions of the same field disagree. The provider-facing JSON Schema declares `between` as a string array with no `minItems`/`maxItems`, so a conforming model response may contain one, three, or zero elements. The TypeScript type declares a fixed 2-tuple. The panel — the only consumer that reads the field — renders exactly index 0 and index 1. The new guard closes the `undefined` case but leaves the arity mismatch untouched: a three-element `between` silently drops its third endpoint with no error and no visual indication, and a one-element `between` renders `"A ↔ "` with a dangling separator. This also explains *why* the guard had to be bespoke: `between` is the only tuple in the artifact surface (baseline 6), so the repo's array idiom (`x?.length > 0` + `x?.map`) was unavailable and an object-style `&&` guard was borrowed instead. The mismatch predates this range — but this commit is the point at which the codebase acknowledged in code that the declared contract does not hold at runtime, and it addressed only one of the two ways it fails.

**Recommendation:** Pick one arity and enforce it end to end: either add `"minItems": 2, "maxItems": 2` to `schemas.ts:129` so the schema matches the tuple type, or relax `artifacts.ts:100` to `string[]` and render with the repo's array idiom (`{(t.between?.length ?? 0) > 0 && t.between?.map(...)}` joined by the `↔` separator), which would make this panel structurally identical to its five sibling list renders.

---

### F4 — Runtime nullability contract now diverges from the declared type, pushing `as unknown as` casts onto every consumer that wants to exercise the guarded path

**Severity:** Inconsistent
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113`, `app/components/panels/BalancedPerspectivesPanel.test.tsx:47-49`
**Move:** 8 (nullability contract), 3 (test drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
> ```
> app/components/panels/BalancedPerspectivesPanel.test.tsx:46-49
>     // `between` absent mid-stream — the static type marks it required, so cast.
>     const partialTension = { description: "Half-streamed tension" } as unknown as Tension
>     const data = makeData([partialTension])
> ```
> ```
> app/lib/utils/mergeStreamingPreview.ts:8-12
> export function mergeStreamingPreview<T>(
>   finalData: T | null,
>   streamingPreview: T | null | undefined,
>   hasContent: (data: T) => boolean,
> ): { displayData: T | null; hasDisplayData: boolean } {
> ```

`t.between &&` is a truthiness check on a field TypeScript guarantees is present, so the guard is dead code as far as the compiler is concerned — and the test that proves it isn't must launder its fixture through `as unknown as Tension`, the double-cast escape hatch. Elsewhere in the repo that cast is reserved for genuinely foreign objects: browser handles (`fsaPicker.ts:37,78`), `Response`→`NextResponse` at framework boundaries (`artifactRoute.ts:82`), and deliberately-invalid protocol fixtures (`gitProtocol.test.ts:99`). Using it for *the repo's own artifact type* signals the type is wrong, not the fixture. The root cause is baseline 5: `mergeStreamingPreview`/`useStreamingMerge` type the mid-stream preview as a complete `T`, so no panel can express "partial" in the type system. The consumer impact is that every future test or helper touching mid-stream artifact data inherits the same cast, and the compiler will not flag the next panel that indexes a not-yet-streamed field. Fixing the general case is out of scope for this range; flagging that the fix hardened the runtime without moving the type is not.

**Recommendation:** Either mark `between` optional in `artifacts.ts:100` (matching `isEmpirical?` at line 124, the repo's existing "may be absent" marker) so the guard type-checks and the cast disappears, or — the broader fix, worth a follow-up rather than this batch — change the `streamingPreview` parameter of `mergeStreamingPreview`/`useStreamingMerge` to `DeepPartial<T>` so every panel's partial-handling becomes compiler-enforced.

---

### F5 — `allowUnsafeEval` is the only `allow*`-prefixed boolean in the repo; the established prefix family is `is*` / `has*`

**Severity:** Minor
**Location:** `proxy.ts:28`
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `is*` / `has*` boolean-prefix convention used in `app/api/formalization/lean/route.ts:62` (`isRetry`), `app/hooks/useActiveArtifactState.ts:20` (`isDecompMode`), `app/components/panels/ArtifactPanelShell.tsx:20,28` (`isStale`, `hasData`), `app/lib/types/artifacts.ts:124` (`isEmpirical`), `app/hooks/usePanelDefinitions.tsx:41-49` (`hasCausalGraph` …).

**Evidence:**
> ```
> proxy.ts:28
>   allowUnsafeEval: boolean = process.env.NODE_ENV !== "production",
> ```
> ```
> app/api/formalization/lean/route.ts:62
> function mockResponse(informalProof: string, isRetry: boolean): string {
> ```

A repo-wide grep for boolean-typed params, props, and fields returns 27 names before this change; all 27 use `is*` or `has*`. `allowUnsafeEval` is the 28th and the first `allow*`. In fairness the semantics differ — the existing names are state predicates ("this thing is stale") while this one is a permission toggle ("permit this thing") — so `allow*` reads naturally in isolation and CSP-domain readers will parse it instantly. This is a genuine new naming category rather than a misnamed predicate, which is why it is Minor rather than Inconsistent. The cost is only that a reader grepping for the repo's boolean-flag convention will not find it.

**Recommendation:** No change required if the parameter survives F1/F2 review. If a second permission-style flag is ever added, either standardize on `allow*` for that category deliberately or rename this to `isDevBuild` / `unsafeEvalEnabled` to stay inside the existing family.

---

### F6 — Test drift: the "no eval in production" invariant no longer covers the default call form, and nothing pins the default's behavior

**Severity:** Minor
**Location:** `proxy.test.ts:10-13`, `proxy.test.ts:30-34`
**Move:** 3 (test drift), 6 (versioning impact)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
> ```
> proxy.test.ts:10-13
>   // Pin the production CSP explicitly so these assertions don't depend on the
>   // ambient NODE_ENV the test runner happens to set.
>   const csp = buildCsp(NONCE, false);
>   const directives = csp.split("; ");
> ```
> ```
> proxy.test.ts:30-34
>   it("does not allow eval, wildcards, or http: schemes in production", () => {
>     expect(csp).not.toMatch(/'unsafe-eval'/);
> ```

Before this change, `buildCsp(NONCE)` exercised the exact expression that shipped to production, and the eval assertion was an end-to-end guarantee. Now the whole suite tests `buildCsp(NONCE, false)` and `buildCsp(NONCE, true)` — both explicit — while the default expression `process.env.NODE_ENV !== "production"`, which is the *only* thing standing between production and `'unsafe-eval'`, is never evaluated by any test. The test-name change from "anywhere" to "in production" (`proxy.test.ts:30`) is an honest acknowledgement that the invariant narrowed, and the file's own header comment declares that "CSP changes are intentional security decisions — updating this test is the explicit acknowledgement," so the weakening is at least visible. But the class of regression the suite was written to catch (per `docs/reviews/csp-headers/code-review-rubric.md` A4: "someone weakening `script-src` during refactor wouldn't fail anything") is now reachable by editing the default expression alone. Vitest runs with `NODE_ENV="test"`, so the default cannot be exercised as-is without stubbing.

**Recommendation:** Add one test that stubs the environment and asserts the default path — `vi.stubEnv("NODE_ENV", "production"); expect(buildCsp(NONCE)).not.toMatch(/'unsafe-eval'/); vi.unstubAllEnvs()` — plus its `"development"` counterpart. This restores the original guarantee and is the cheapest available enforcement of F1's docstring contract.

---

### F7 — Comment-accuracy fix applied to the docstring but not to the duplicate claim 14 lines below; the parity assertion the commit set out to drop survives

**Severity:** Minor
**Location:** `app/lib/stores/evidenceStore.ts:8-9` (fixed) vs `app/lib/stores/evidenceStore.ts:17` (unchanged)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
> ```
> app/lib/stores/evidenceStore.ts:8-9  (after the fix)
>  * Persists to localStorage with debounced writes (see the debounced storage
>  * adapter below) to avoid excessive serialization on rapid updates.
> ```
> ```
> app/lib/stores/evidenceStore.ts:17  (unchanged by this range)
> // Debounced localStorage adapter (same pattern as workspaceStore)
> ```

Commit 4d5f743's stated purpose was to drop an unverifiable cross-module parity claim from the module docstring. The identical claim — "same pattern as workspaceStore" — remains verbatim in the section banner immediately below, so a reader gains nothing: the module still asserts parity with `workspaceStore`, just from a different line. The claim is also the weaker one it was replaced for: `workspaceStore.ts:530-533` selects its storage adapter through `resolveWorkspaceStorage` (a CorpusFS-vs-localStorage seam added by DD-009 S1), whereas `evidenceStore` hardcodes `debouncedStorage` at line 356 — the two are no longer the same pattern in the sense the comment implies. Per the partial-scope rule I checked the rest of the file and the branch: line 17 is untouched by this range and by the two preceding commits, so this is an incomplete fix rather than a regression.

**Recommendation:** Apply the same edit to line 17 — e.g. `// Debounced localStorage adapter` — completing the change 4d5f743 intended.

---

### F8 — The guard admits partially-arrived tuples: `between[1]` is still indexed unconditionally inside the guarded branch

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`
**Move:** 8 (nullability contract), 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
> ```
> app/components/panels/BalancedPerspectivesPanel.tsx:113-117
>                       {t.between && (
>                         <div className="flex items-center gap-1 text-xs font-mono text-red-700">
>                           <span>{t.between[0]}</span>
>                           <span className="text-red-400">&harr;</span>
>                           <span>{t.between[1]}</span>
> ```

Partial-JSON streaming produces arrays incrementally, so `between: ["perspective-a"]` is as reachable a mid-stream state as `between: undefined` — the case the guard was written for. The guard is truthy for `["perspective-a"]` and for `[]`, after which `between[1]` (and `between[0]`) evaluate to `undefined`. This does **not** crash: React renders `undefined` as nothing, consistent with baseline 4's treatment of unguarded leaf fields. The visible result is a transient `"perspective-a ↔"` or a bare `"↔"` row for one frame. Calling this out because the commit message frames the change as making the panel safe against partial tensions, and it is safe against the object-level partial but not the array-level one; the accompanying test covers only the `undefined` case (`BalancedPerspectivesPanel.test.tsx:48`), so the arity case is neither handled nor documented as accepted.

**Recommendation:** No code change needed for crash-safety. If the flicker matters, tighten to `t.between?.[0] && t.between?.[1] && (…)` — one character of additional guard, and it becomes exactly correct under F3's tuple reading.

---

### F9 — New panel test's `makeData` takes a full array where the sibling takes a partial-override object

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:20-28`
**Move:** 7 (asymmetry), 1 (baseline)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
> ```
> app/components/panels/BalancedPerspectivesPanel.test.tsx:20-28
> function makeData(tensions: Tension[]): BalancedPerspectives {
>   return {
>     topic: "Test topic",
>     perspectives: [],
>     tensions,
> ```
> ```
> app/components/panels/CounterexamplesPanel.test.tsx:29-32
> function makeData(
>   cxOverrides: Partial<CounterexamplesResponse["counterexamples"]["scenarios"][0]> = {},
> ): CounterexamplesResponse["counterexamples"] {
> ```

The only sibling panel test with the same structure exposes `makeData(overrides: Partial<Item> = {})` — defaulted, override-shaped, and paired with a separate `makeCx()` item factory. The new file's `makeData(tensions: Tension[])` is required-argument and array-shaped, with no item factory. Both are defensible; the new shape is arguably better suited to a test whose whole point is supplying a *malformed* item, since a `Partial<>` override could not express "field absent" without the same cast anyway. Noting it only because these two files are otherwise near-identical (same mocks, same `baseProps` idiom, same quoting), so the divergence is likely incidental rather than chosen, and the next panel test will have two precedents to copy from instead of one.

**Recommendation:** Optional. If a third panel test lands, converge on the `Partial<>`-override shape or document the array shape as the preferred form for partial-streaming regression tests.

---

## What Looks Good

- **The panel guard picks the right idiom from the right family.** `{t.between && …}` matches the object-guard convention (`topic &&` line 46, `synthesis &&` line 129) rather than inventing a new one, and correctly does *not* use the array `?.length` idiom that the sibling list fields use — `between` is a tuple, not a collection. The fact-check's "mostly accurate" verdict on the commit message is borne out.
- **The regression test carries its own justification.** The comment at `BalancedPerspectivesPanel.test.tsx:43-45` names the mechanism (partial-JSON streaming), the failure (`TypeError` from indexing `undefined`), and the blast radius (whole panel crashed) — so a future reader who sees the guard as redundant against the type will find the reason not to delete it.
- **`proxy.test.ts` widened its contract in the right direction.** The new dev-CSP test asserts the *exact* `script-src` string rather than a substring, and adds `expect(devCsp.match(/'unsafe-eval'/g)).toHaveLength(1)` to prove the token cannot leak into another directive — a containment assertion the original suite did not have for any token.
- **The test comment explains the changed call form.** `proxy.test.ts:10-11` states why `false` is now passed explicitly, so the diff does not read as an unexplained weakening of the existing assertions.
- **The evidence-search comment fix is a genuine precision improvement.** The old note asserted a bound (`PER_QUERY_RESULTS × 5`) without naming the path it applied to; the new one separates the override path (5 queries → 25) from the LLM path (≤3 → 15). Both remain far under the spread-argument limit, and the claim is now checkable.
- **Consumer surface is unchanged for every existing caller.** `buildCsp(nonce)` still compiles and still returns the same directive list in the same order in a production build; `proxy.ts:53` was not touched. No HTTP endpoint, artifact schema, store shape, or exported type changed, so there is no client-facing breaking change in this range.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | Dev-only gating exposed as a caller-overridable parameter; contradicts `flag.ts` hard-guard precedent and its own docstring | Inconsistent | `proxy.ts:22-32` | High |
| F2 | Default parameter reads `process.env`; all existing defaults are constants or injectable seams | Inconsistent | `proxy.ts:28` | High |
| F3 | `between` arity disagrees across JSON Schema (unbounded), TS type (2-tuple), and renderer (indices 0,1) | Inconsistent | `BalancedPerspectivesPanel.tsx:113-119` | High |
| F4 | Runtime nullability contract diverges from declared type; forces `as unknown as` casts on consumers | Inconsistent | `BalancedPerspectivesPanel.tsx:113`, `.test.tsx:47-49` | High |
| F5 | `allowUnsafeEval` is the only `allow*` boolean; repo convention is `is*`/`has*` | Minor | `proxy.ts:28` | High |
| F6 | Eval invariant no longer covers the default call form; the default expression is untested | Minor | `proxy.test.ts:10-13,30-34` | High |
| F7 | Parity claim removed from docstring but survives verbatim at line 17 | Minor | `evidenceStore.ts:8-9` vs `:17` | High |
| F8 | Guard admits partially-arrived tuples; `between[1]` indexed unconditionally | Informational | `BalancedPerspectivesPanel.tsx:113-119` | High |
| F9 | `makeData` takes a full array where the sibling test takes a partial-override object | Informational | `BalancedPerspectivesPanel.test.tsx:20-28` | Medium |

---

## Overall Assessment

This is a small, well-motivated fix batch with **no breaking changes for any existing consumer** — `buildCsp(nonce)` still compiles and still emits an identical production policy, no artifact schema or store shape moved, and the panel change is strictly a widening of what it tolerates. The API-consistency concerns are all about *shape*, not compatibility.

The substantive one is F1/F2, which are two views of the same decision: the repo already established, under security-review pressure, that dev-only capabilities are gated by an un-overridable internal check (`flag.ts`), and this change gates a dev-only CSP relaxation with an overridable public parameter whose default is an ambient environment read. That is a deviation from an established pattern rather than the creation of a new one, and the pattern it deviates from exists precisely because the previous instance of "documented dev-only, not enforced dev-only" was itself a review finding. F6 compounds it: the one expression that enforces the docstring is now the one expression no test exercises. Together they are cheap to close — move the read into the body, or clamp the parameter, and add a `vi.stubEnv` test.

F3/F4/F8 are a cluster around the same root: the repo has no way to *say* "partially streamed" in its type system (`mergeStreamingPreview` types the preview as a complete `T`), so every panel compensates at the render site and every test compensates with a cast. This commit does that correctly and in the house style — but it is the fourth or fifth instance of the pattern, and `between` being the repo's only tuple is what forced a bespoke guard where an idiomatic array guard would have done. Worth a follow-up that either aligns the schema's arity with the tuple type or relaxes the tuple to an array; not worth blocking this batch.

F5, F7, and F9 are polish. F7 is the only one I would fold into this batch directly, since it is a one-line completion of a change the batch already intended to make.

---

## Goal-Alignment Note
- Answered: yes — full API-consistency pass over the range, all severities including Informational
- Out of scope: `mergeStreamingPreview.ts` / `useStreamingMerge.ts` are byte-identical duplicates (a real duplication issue, but out of range and an architecture concern, not API consistency); the broader `DeepPartial` streaming-type redesign implied by F4; the `schemas.ts` arity fix implied by F3 — all flagged as follow-ups, not reviewed as defects in this range
- Escalate: F1 — the "dev-only" property is enforced by exactly one call site and zero tests, in a repo that already took a security finding (corpus flag C2) for the identical shape; the security reviewer should see this even though the mechanism is an API-design choice
