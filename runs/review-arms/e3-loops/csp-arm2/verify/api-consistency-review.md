# API Consistency Review — e3 arm2 (CSP), verification pass

Commit: ab4dbdb
Range: `git diff d86d2dc..HEAD` (branch e3/csp-arm2)
Skill: api-consistency-reviewer
Merge standard: 0R + 0A (0 Rejecting / 0 Amber)
Scope rule: ancestors of worktree HEAD only; no other worktree/arm artifacts consulted.

## Context

This is the Arm-2 verification (critic-stage) pass over the amber-disposition commit `ab4dbdb`. The
prior full-3 API review raised three Inconsistent findings; this pass confirms all three are closed
and hunts for anything NEW introduced by the amber pass.

Baseline-state check (`git show d86d2dc:<path>`): at the diff base, none of `proxy.ts`,
`middleware.ts`, or `app/lib/utils/dataUrl.ts` existed. Every consumer-facing surface in this diff
is therefore **net-new relative to the base** — there is no pre-existing public contract for this
range to break. Intra-branch renames/moves are also assessed below for completeness, but none of
them touch a surface a consumer outside this branch was bound to.

Public surfaces in the diff:
- `proxy.ts` — exports `buildCsp(nonce)`, `proxy(request)`, `config` (Next 16 proxy contract).
- `app/lib/utils/dataUrl.ts` — new module, exports `dataUrlToBlob(dataUrl)`.
- `app/lib/utils/exportGraph.ts` — internals rewired to `dataUrlToBlob`; exported surface unchanged.
- `app/layout.tsx` — adds `export const dynamic = "force-dynamic"` (Next route-segment contract).
- CSP directive set (a policy contract browsers bind to): `form-action 'self'` added; matcher anchored.

Legibility-target: reviewer familiar with Next.js middleware/proxy conventions and CSP directives,
not necessarily with this repo's history.

---

## Breaking-change determination

**0 Breaking.** Stated clearly:

- **`proxy.ts` (middleware→proxy rename + CSP):** net-new relative to base. Next.js discovers it by
  filename convention; no application code imports it as a contract. The intra-branch
  `middleware.ts`→`proxy.ts` rename predates this diff range and has no external consumer.
- **`x-nonce` deletion:** the header never existed at base, was never read by anything under `app/`
  (zero-reader), and is not present at HEAD. Removing a write that had no reader breaks no contract.
- **`dataUrlToBlob` move to `app/lib/utils/dataUrl.ts`:** the symbol did not exist as a public export
  at base. `exportGraph.ts`'s own exported functions (`getGraphViewportElement`,
  `downloadGraphAsPng`, `graphToPngBlob`) keep identical signatures and return types; only their
  bodies changed (`fetch(dataUrl)` → `dataUrlToBlob(dataUrl)`). Consumers of `exportGraph` see no
  change.
- **`form-action 'self'` added / matcher anchored:** tightening a net-new policy; no prior policy to
  break.

---

## Carried-finding verification (prior full-3: 3 Inconsistent)

### C1 — x-nonce zero-reader → CLOSED (NEW state: DELETED)
Evidence (`proxy.ts`, verbatim):
```
  // Deliberately no `x-nonce` header: Next reads the nonce out of the
  // Content-Security-Policy request header above, and nothing in `app/` has
  // ever read `x-nonce`. Publishing it made an unused write look like a
  // contract. If a component ever needs `<Script nonce>`, add it back here
  // together with the consumer, not ahead of it.
```
The write is gone and a regression test pins its absence (`proxy.test.ts`):
```
  it("does not publish an x-nonce header with no consumer", () => {
    ...
    expect(forwardedRequestHeader(run(), "x-nonce")).toBeNull();
  });
```
Verdict: closed. The unused-contract asymmetry is removed and guarded.

### C2 — dataUrlToBlob placement → CLOSED (NEW state: MOVED)
Evidence (`app/lib/utils/dataUrl.ts` docblock, verbatim):
```
 * Lives in its own module so a second consumer can use it without importing
 * `exportGraph.ts`, which pulls `html-to-image` into whatever chunk imports it
 * — the code split `GraphPanel.tsx` dynamic-imports precisely to avoid.
```
The helper now lives in a standalone module; `exportGraph.ts` imports it (`import { dataUrlToBlob }
from "./dataUrl";`). Both call sites (`downloadGraphAsPng`, `graphToPngBlob`) updated. Placement is
now consistent with sibling single-purpose util modules (`stripCodeFences.ts`, `topologicalSort.ts`,
`throttle.ts`). Verdict: closed.

### C3 — matcher scope not anchored → CLOSED for api/favicon, residual for _next/*
Evidence (`proxy.ts` matcher, verbatim):
```
    {
      source: "/((?!api(?:/|$)|_next/static|_next/image|favicon\\.ico$).*)",
    },
```
`api` is anchored (`(?:/|$)` — cannot swallow `/apidocs`) and `favicon\.ico$` is anchored to path
end (cannot swallow `/favicon.ico.map`). Both are pinned by tests
(`config.matcher` › "does not let an exclusion swallow a sibling route"). Verdict: the two paths
called out by the prior finding are **closed**. See F1 for the residual on `_next/*`.

---

## Findings

### F1 — [Nit / Low] `_next/static` and `_next/image` exclusions remain prefix-unanchored; the "each exclusion is anchored" comment overclaims — NEW (overlaps merged fact-check cosmetic residual)

Precedent: N/A (internal consistency of one pattern, not a naming choice) — no tier adjustment.

The matcher's own convention is inconsistent within a single list: `api` and `favicon.ico` are
anchored, but `_next/static` and `_next/image` are bare prefixes. A path such as
`/_next/staticfoo/x` starts with `_next/static` and is therefore excluded from the CSP, exactly the
"swallow a sibling" failure mode the other two exclusions were anchored to prevent.

Evidence (`proxy.ts`, verbatim):
```
  // Each exclusion is anchored so it cannot swallow a sibling route: `api` only
  // matches /api and /api/..., never a future /apidocs; `favicon.ico` only
  // matches the whole path.
```
The comment says "Each exclusion is anchored"; two of the four are not. The regression test in
`proxy.test.ts` ("does not let an exclusion swallow a sibling route") exercises `/apidocs`,
`/api-status`, `/favicon.ico.map` — but no `_next/*` sibling — so the gap is invisible to the suite.

Impact: **very low.** `/_next/` is Next.js's reserved namespace; application routes cannot be served
under it, so no real sibling route exists to be swallowed today. This is a doc-accuracy /
internal-consistency nit, not a live exposure. It coincides with the only residual from the merged
k=3 fact-check ("cosmetic 'anchored' overclaim for `_next/*`"), so it is not a second independent
defect — the API-consistency lens simply confirms the same overclaim as an asymmetry within the
exclusion list.

Suggested (optional, not merge-blocking): either anchor the two `_next` alternatives
(`_next/static(?:/|$)`, `_next/image(?:/|$)`) to match the api/favicon convention, or soften the
comment to name which exclusions are anchored. Prefer the former for one uniform rule.

Legibility-target: matcher-authoring reviewer.

---

## Required Name-Pattern Audit (new public names)

| New public name | Kind | Closest neighbors | Precedent? | Assessment |
|---|---|---|---|---|
| `app/lib/utils/dataUrl.ts` (module) | util module filename | `fileExtraction.ts`, `latexParser.ts`, `leanContext.ts`, `stripCodeFences.ts`, `textSelection.ts`, `topologicalSort.ts` | **Yes** — camelCase single-purpose util filename | Consistent. No adjustment. |
| `dataUrlToBlob` (export) | conversion fn | `triggerDownload`, `downloadTextFile`, `sanitizeFilename`, `topologicalSort`, `stripCodeFences` | Partial — neighbors are verb-noun; no existing `XtoY` converter | Idiomatic JS conversion naming, descriptive and unambiguous; the input type (`dataUrl`) and output (`Blob`) are both in the name. Acceptable; no sibling it contradicts. |
| `buildCsp` (export) | builder fn | `mergeStreamingPreview`, `migrateV1Workspace`, `saveWorkspace` | Yes — verb-noun builder style | Consistent. Exported for test access, mirrored by `proxy.test.ts`. |
| `proxy` (export) | Next proxy entry | framework contract | Framework-dictated (Next 16 proxy) | Not a free naming choice; correct per Next 16. |
| `config` (export) | Next matcher config | framework contract | Framework-dictated | Correct per Next convention. |
| `dynamic = "force-dynamic"` | route-segment config | framework contract | Framework-dictated | Correct Next route-segment option value. |
| `form-action 'self'` | CSP directive | CSP spec | Spec-dictated | Standard directive name/value; consistent with the other `'self'` directives in `buildCsp`. |

No new public name violates an established repo convention. No tier penalties triggered (the one
partial-precedent case, `dataUrlToBlob`, contradicts no sibling and is self-documenting).

---

## Consumer contracts — exportGraph after the dataUrl move

- `downloadGraphAsPng(viewportElement, filename)` — signature and `Promise<void>` contract
  unchanged; body swaps `await fetch(dataUrl); await res.blob()` for `dataUrlToBlob(dataUrl)`.
- `graphToPngBlob(viewportElement)` — signature and `Promise<Blob>` contract unchanged; returns
  `dataUrlToBlob(dataUrl)` (a sync `Blob` auto-wrapped in the async return — still `Promise<Blob>`).
- `getGraphViewportElement()` — untouched, still `HTMLElement | null`.

Consumer-visible surface of `exportGraph.ts` is byte-for-byte compatible. No asymmetry introduced.

## Error consistency

`dataUrlToBlob` throws `new Error("Not a data: URL")` synchronously on a non-`data:` input, pinned by
a test (`"rejects anything that is not a data: URL"`). Prior behavior (`fetch`) surfaced failure as a
rejected promise; because both call sites are `async`, a synchronous throw is still delivered to the
caller as a rejected promise — the observable error contract at the `exportGraph` boundary is
preserved. Generic `Error` with a plain message is consistent with the repo's other util-level
validation throws. No inconsistency.

## Nullability

`dataUrlToBlob` returns a non-null `Blob` or throws — no nullable return introduced. `buildCsp`
returns a non-null string. `proxy` returns a non-null `NextResponse`. No nullability drift.

## Asymmetries

Only F1 (anchoring asymmetry within the matcher exclusion list). The request/response CSP header pair
is deliberately symmetric (`proxy.ts` sets the same policy on both request and response headers, and
a test asserts equality), which is correct for the nonce-forwarding mechanism.

---

## What Looks Good

- The CSP rationale now has a **single owner**: the `proxy.ts` docblock is authoritative and
  `dataUrl.ts` / `proxy.test.ts` point to it rather than restating it — this directly removes the
  drift risk that produced two of the prior findings.
- `dataUrlToBlob` extraction into its own module is the right consistency call: it matches the
  single-purpose util-module convention and keeps `html-to-image` out of any chunk that only needs
  the codec.
- `form-action 'self'` is added with an explicit note that it does not fall back to `default-src`,
  and a test asserts the directive is present — a clean, self-documenting addition consistent with
  the other `'self'` directives.
- Test suite pins the private Next transport (`x-middleware-override-headers`) behind a labeled
  canary with a triage rule, so a future Next bump degrades legibly rather than silently.

---

## Summary Table

| ID | Severity | Status | Finding |
|----|----------|--------|---------|
| — | Breaking | 0 confirmed | No breaking change; all surfaces net-new vs base, exportGraph public surface unchanged. |
| C1 | (was Inconsistent) | CARRIED — closed | x-nonce zero-reader header DELETED + guarded by test. |
| C2 | (was Inconsistent) | CARRIED — closed | dataUrlToBlob MOVED to app/lib/utils/dataUrl.ts; exportGraph rewired. |
| C3 | (was Inconsistent) | CARRIED — closed (api/favicon) | matcher anchored for api + favicon; siblings pinned by tests. |
| F1 | Nit / Low | NEW | `_next/static` / `_next/image` exclusions unanchored; "each exclusion is anchored" comment overclaims. Overlaps merged fact-check cosmetic residual. Very low real risk (reserved namespace). |

## Overall Assessment

**Meets the 0R + 0A standard.** Zero Breaking changes; all three prior Inconsistent findings are
closed and now regression-guarded. The single NEW item (F1) is a Nit — a doc-overclaim /
internal-anchoring asymmetry on the `_next/*` exclusions, sitting in Next's reserved namespace where
no real sibling route can exist. It is not merge-blocking and coincides exactly with the one cosmetic
residual the merged k=3 fact-check already surfaced, so it introduces no independent defect. No Amber.

## Goal-Alignment Note

The task asked to (1) confirm 0 Breaking and (2) surface any NEW inconsistency from ab4dbdb, while
verifying the three prior findings are closed. All satisfied: 0 Breaking is confirmed with
base-state evidence; C1/C2/C3 verified closed with verbatim evidence and their guarding tests; and
the one NEW item (F1) is reported at Nit severity with an explicit cross-reference to the merged
fact-check's cosmetic residual so the caller can see it is the same overclaim viewed through the
consistency lens, not a new blocker. This review consulted only ancestors of the worktree HEAD; no
other arm/worktree artifacts were read.
