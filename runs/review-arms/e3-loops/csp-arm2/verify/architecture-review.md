# Architecture Review — e3 arm2 (CSP), verification pass

Commit: ab4dbdb
Range: d86d2dc..HEAD (branch e3/csp-arm2)
Scope rule: ancestors of worktree HEAD only. No other worktrees or arm artifacts consulted.
Reviewer stage: Arm 2 verification (critic stage), 0R+0A merge standard.
Cross-reference: security-review.md not present in the verify dir at completion — cross-reference is a no-op.

## Verdict up front

- **Structural findings: 0.** Confirmed. No dependency-direction inversion, no boundary breach, no ISP/SOLID violation introduced or carried.
- The four carried dispositions (C1, C3/A8, C4, C5) are all correctly resolved or honored — verified below, not taken on faith.
- **One NEW finding introduced by the disposition edits themselves** (N1, Minor/Coupling) — the C5 analog. It is a net improvement over what it replaced, but it is a fix-introduced coupling and is surfaced per the explicit ask.

---

## What Looks Good

- **C4 (dataUrlToBlob placement) — genuinely MOVED, not copied.** `git diff 2544a19..ab4dbdb` shows a `rename from app/lib/utils/exportGraph.test.ts → dataUrl.test.ts` (similarity 96%) plus deletion of the function body from `exportGraph.ts` and its recreation in the new leaf module `app/lib/utils/dataUrl.ts`. `exportGraph.ts` now `import`s it. Dependency direction is clean: `dataUrl.ts` is zero-dependency; `exportGraph.ts → dataUrl.ts`; both are leaf utils. The split is a real ISP/extension-point win — it lets a future consumer take the codec without dragging `html-to-image` into its chunk (the docblock's stated rationale). Verified there is no residual second definition (`rg` finds exactly one `dataUrlToBlob`).

- **C1 (layout half untested) — test added AND mutation-confirmed to falsify.** `app/layout.test.ts` asserts `layout.dynamic === "force-dynamic"`. I ran the mutation directly: commenting out `export const dynamic = "force-dynamic"` in `app/layout.tsx` turns the test red (`AssertionError: expected undefined to be 'force-dynamic'`); restoring it turns it green. The test is the deletion-detector it claims to be, not a tautology. Working tree restored, HEAD clean at ab4dbdb.

- **C5 (rationale drift from the style-src fix) — collapsed to a single owner, not relocated.** Before ab4dbdb the style-src justification lived in *two* places: the `proxy.ts` docblock and the `proxy.test.ts` "keeps the style-src carve-out" test comment, which carried its own independent wording ("Required by React style={}… removing it silently breaks graph layout"). The disposition commit reduces the test comment to `// Rationale: see the style-src note in proxy.ts (authoritative copy).` and adds an explicit ownership declaration to `proxy.ts` ("single authoritative rationale… so the fact has one owner and cannot drift into two disagreeing copies again"). The two divergent copies are now one owner + pointers. Drift is resolved, not moved.

- **C3 / A8 (buildCsp lives in the entry file) — deferral honored.** `buildCsp` remains an export of `proxy.ts`; it was not extracted, and the ACKED revisit trigger stands. The disposition commit does not touch this decision. Honored.

- **Test verification.** All 19 tests across the three changed/added files pass (`app/layout.test.ts`, `app/lib/utils/dataUrl.test.ts`, `proxy.test.ts`). The `config.matcher` suite and the `x-middleware-override-headers` canary give the private-Next-transport coupling an explicit tripwire with a documented triage rule — a good way to make an unavoidable coupling legible rather than hidden.

- **Public-surface changes are additive and low-blast-radius.** `buildCsp` signature unchanged; only a `form-action 'self'` directive string is added. `config.matcher` shape unchanged (the `missing:` clause is *removed*, which simplifies the contract). `layout.tsx` adds one exported const. No consumer contract is broken.

---

## Findings

### N1 — Fix-introduced documentation coupling: owner-enumerates-referrers + pointer-by-filename
**Severity: Minor (Coupling category).** NEW — introduced by the disposition edits (the C5 analog the prior pass warned to watch for).

The mechanism chosen to resolve C5 replaces *duplicated rationale* with *cross-file textual pointers*, and this creates a smaller residual coupling of its own along two edges:

1. **Owner enumerates its referrers.** The `proxy.ts` docblock now hand-lists its dependents by path: "Other files that touch a directive (`proxy.test.ts`, `app/lib/utils/dataUrl.ts`) point here rather than restating it." This referrer list is maintained by hand; a third file that adds a pointer, or a rename/removal of `dataUrl.ts`, leaves the list stale.
2. **Pointer-by-filename across a layer edge.** `app/lib/utils/dataUrl.ts` (app layer) now contains "see the connect-src note in `proxy.ts`" and `proxy.test.ts` contains "see the style-src note in proxy.ts (authoritative copy)." These reference the owner by filename, so a rename of `proxy.ts` breaks the pointers.

This is not hypothetical drift: this arm's own history already broke exactly this kind of pointer once — commit b25e939 ("correct layout comment to reference proxy.ts (renamed from middleware.ts)") existed only to fix a comment that had gone stale after the `middleware.ts → proxy.ts` rename. The pointer-by-filename pattern has a demonstrated failure mode in this very codebase.

**Why it is only Minor, and why I would still merge under 0R+0A:** the tradeoff is a net improvement over C5. The failure mode of duplicated rationale (C5) is *two facts silently disagreeing* — invisible until someone reads both. The failure mode of a pointer (N1) is *one dangling reference* — visible on the next read of either file, and non-load-bearing (comment-only, zero runtime effect). A dangling pointer is strictly more legible and less dangerous than a silent contradiction. The disposition traded a worse coupling for a lesser one; that is the correct direction. No action required to merge.

**Evidence (verbatim, `proxy.ts`):**
> This block is the single authoritative rationale for the CSP directives.
> Other files that touch a directive (`proxy.test.ts`, `app/lib/utils/
> dataUrl.ts`) point here rather than restating it, so the fact has one owner
> and cannot drift into two disagreeing copies again.

**Evidence (verbatim, `app/lib/utils/dataUrl.ts`):**
> `fetch(dataUrl)` is the shorter spelling but is a `connect-src` fetch, which
> the app's CSP refuses. Decoding here keeps that directive tight instead of
> widening it for an export helper; see the connect-src note in `proxy.ts` for
> the policy rationale itself.

**Legibility-target:** a future maintainer who renames `proxy.ts` or removes/renames `dataUrl.ts`. The residual risk is that the referrer list in the `proxy.ts` docblock and the two filename pointers silently fall out of date. If ever worth hardening (not required at this severity), the cheapest durable fix is to drop the hand-maintained referrer *enumeration* from the owner docblock (keep the "I am the single owner" assertion; let referrers point inward without the owner tracking them back), which removes edge (1) entirely and leaves only the ordinary, unavoidable filename references.

---

## Summary Table

| ID | Finding | Severity | Status |
|----|---------|----------|--------|
| — | Structural integrity (dep direction, boundaries, ISP) | Structural | **0 findings — confirmed** |
| C4 | dataUrlToBlob placement | Coupling (prior) | **RESOLVED** — moved to `app/lib/utils/dataUrl.ts`, single definition, clean direction |
| C1 | layout half untested | Coupling (prior) | **RESOLVED** — test added, mutation-confirmed to falsify |
| C5 | style-src rationale drift from fix | Coupling (prior) | **RESOLVED** — collapsed to single owner + pointers (not relocated) |
| C3/A8 | buildCsp in entry file | Coupling (prior, ACKED) | **HONORED** — deferral untouched, revisit trigger intact |
| N1 | owner-enumerates-referrers + pointer-by-filename | Minor (Coupling) | **NEW** — fix-introduced (C5 analog); net improvement, no action needed to merge |

## Overall Assessment

The disposition commit is architecturally sound. Zero Structural findings, confirmed by direct inspection of dependency direction, module boundaries, and public surface — every change is additive or simplifying, and the one new module (`dataUrl.ts`) improves the dependency graph rather than complicating it. All four carried dispositions are verified done for real: C4 is a true move (rename in the diff, single surviving definition), C1's test is a confirmed deletion-detector (mutation goes red), C5's two rationale copies are collapsed to one owner, and the C3/A8 deferral is honored.

The one thing the fixes *did* introduce is N1: the "single authoritative owner" pattern trades duplicated rationale for cross-file pointers, which is itself a (smaller) documentation coupling — and this arm's history proves such filename pointers can go stale (b25e939). This is the fix-introduced finding the pass was asked to look for, directly analogous to the prior C5. It is Minor and represents a net reduction in coupling risk, so it does not block a 0R+0A merge. Under the 0R+0A standard: **0 Structural, 0 Coupling of merge-blocking magnitude, 1 Minor (N1). Merge-clean.**

## Goal-Alignment Note

The change set serves its stated goal — a strict, nonce-based CSP whose control surface is legible and test-guarded. The disposition edits specifically raised legibility: the CSP rationale now has one owner, the two halves of the nonce control (proxy header + layout `force-dynamic`) are both tested, and the private-Next-transport dependency is fenced by a canary with a written triage rule. The single residual (N1) is a legibility tradeoff that lands on the right side of the ledger. Nothing in the diff drifts from the security intent; the `form-action 'self'` addition and the removal of the client-controllable `missing:` matcher skip both tighten the policy in line with the goal.
