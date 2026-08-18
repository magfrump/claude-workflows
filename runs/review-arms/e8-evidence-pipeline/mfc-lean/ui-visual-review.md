# UI Visual Review — Lean verifier "unavailable" status (mfc-lean)

**Commit:** c95c9cb
**Scope:** `git diff d86d2dc...HEAD` in `/workspace/external/cc-review-eval/mfc-lean` — new `"unavailable"` verification status: amber banner, badge state, Re-verify affordance, status-dependent panel rendering
**Date:** 2026-08-17
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-lean/code-fact-check-report.md` (k=2 merged; documented behavior not re-verified)

## Environment

- **Files reviewed:** `app/components/features/lean-display/LeanCodeDisplay.tsx`, `app/components/ui/VerificationBadge.tsx`, `app/components/panels/OutputPanel.tsx`, `app/components/panels/LeanPanel.tsx`, `app/components/panels/NodeDetailPanel.tsx`, `app/components/features/session-banner/SessionBanner.tsx`, `app/components/features/proof-graph/ProofGraphNode.tsx`, `app/hooks/usePanelDefinitions.tsx`, `app/hooks/useActiveArtifactState.ts`, `app/hooks/useFormalizationPipeline.ts`, `app/page.tsx`, `app/lib/types/decomposition.ts`, `app/lib/types/session.ts`, `app/globals.css` (status tokens)
- **Target viewports:** 320–480px (small mobile), 768–1024px (tablet / split panes), 1920px+ (desktop)
- **Target browsers / platforms:** modern evergreen + mobile Safari
- **Review mode:** Mechanical (orchestrator-invoked), plus item 8 (state matrix) and targeted affordance checks explicitly requested by the caller (mode/surface coverage for the new status). Static review only — no dev server (ports contended in this shared clone).

## Findings

#### Decomposition (node-scoped) mode renders no state at all for "unavailable" — verify appears to do nothing

**Severity:** Critical
**Location:** `app/lib/types/decomposition.ts:29-38`, `app/page.tsx:348-350`, `app/hooks/useActiveArtifactState.ts:41-42`
**Issue type:** State coverage / Affordance
**Viewport:** all
**Move:** Caller-directed mode-coverage check (Step 2 item 6/8 applied per-mode)
**Confidence:** High

In decomposition mode the pipeline writes status through `page.tsx:348-350` → `toNodeVerificationStatus()`, whose switch has cases only for `valid`/`invalid`/`verifying`; `"unavailable"` falls to `default: return "unverified"` (`decomposition.ts:32-37`). The panels then read status back through `fromNodeVerificationStatus()` (`useActiveArtifactState.ts:41-42`), where `"unverified"` → `"none"`. So the `"unavailable"` value is destroyed at write time and every surface in node scope goes blank: no amber banner (`LeanCodeDisplay.tsx:132` requires `"unavailable"`), no badge (`VerificationBadge.tsx:4` returns `null` for `"none"`), no Re-verify button (`LeanCodeDisplay.tsx:111` condition unmet), gray "Unverified" node dot/border (`ProofGraphNode.tsx:6-11`), gray "Unverified" chip in `NodeDetailPanel.tsx:23-34`. A user who verifies a node while the verifier is offline gets zero visual feedback — the click appears to have done nothing, and the remedy text (set `LEAN_VERIFIER_URL`) is unreachable in this mode. The change's own safety intent ("distinct from Verification Failed so users don't read a missing verifier as a passing proof") holds only in global scope; the diff touched neither `decomposition.ts` nor any node-scoped surface. Violates WCAG 4.1.3 (status messages) in spirit: the status is never communicated in this mode.

**Recommendation:** Either extend `NodeVerificationStatus` with an `"unavailable"` value (mapped both directions and given a `STATUS_COLORS`/`STATUS_LABELS` entry), or — smaller change — have `useActiveArtifactState` prefer the active session's `verificationStatus` (which does retain `"unavailable"` via `onSessionUpdate`, `page.tsx:355-356`) over the node-derived value for the panel display, so the banner/badge/Re-verify render in node scope even while the persisted node status stays "unverified".

```ts
// Before (decomposition.ts:32-37)
case "verifying": return "in-progress";
default: return "unverified";

// After
case "verifying": return "in-progress";
case "unavailable": return "unavailable"; // + add to NodeVerificationStatus, STATUS_COLORS, STATUS_LABELS
default: return "unverified";
```

**Tradeoff:** a new node status value touches persistence typing for nodes; the session-preference fix avoids that but leaves the graph dot gray (arguably correct — the node genuinely is unverified).

#### SessionBanner status dot renders "unavailable" identically to "none"

**Severity:** Major
**Location:** `app/components/features/session-banner/SessionBanner.tsx:18-23`
**Issue type:** State coverage / Affordance
**Viewport:** all
**Move:** Step 2 item 8 (state matrix) applied to the new status across surfaces
**Confidence:** High

`statusDot()` branches on `valid`/`invalid`/`verifying` and falls through to the gray `#9A9590` dot for everything else — the same rendering as `"none"`. `FormalizationSession.verificationStatus` does carry `"unavailable"` (set via `onSessionUpdate`, preserved on global-session restore at `page.tsx:193`), and for node-scoped sessions the session record is the *only* place the value survives (see Critical finding) — yet its only renderer shows it as "never verified". In the session dropdown (`SessionBanner.tsx:69-86`) a run that ended verifier-offline is indistinguishable from one never run. Note the dot is also color-only with no text/label (`title` absent) — a pre-existing pattern, but adding a fourth semantic to it should not reuse an existing color.

**Recommendation:** Add an explicit branch before the fallback, visually distinct from both `verifying` (`bg-amber-500` solid) and `none` (gray solid) — e.g., a hollow amber dot — and give the dot a `title`/`aria-label` so the distinction is not color-only (WCAG 1.4.1).

```tsx
if (status === "unavailable")
  return <span title="Verifier offline — not checked" className="inline-block h-1.5 w-1.5 rounded-full border border-amber-600 bg-transparent" />;
```

**Tradeoff:** hollow-vs-solid at 6px is subtle; the `title` text carries the real disambiguation.

#### Icon Rail Lean status summary reports "Code ready" for an unchecked proof

**Severity:** Minor
**Location:** `app/hooks/usePanelDefinitions.tsx:110-116`
**Issue type:** State coverage / Affordance
**Viewport:** all
**Move:** Caller-directed surface sweep (status summary text)
**Confidence:** High

The Lean panel's rail `statusSummary` ternary handles `valid` ("Verified") and `invalid` ("Failed") but lets `"unavailable"` fall to the `activeLeanCode ? "Code ready"` branch — the same label as a freshly generated, never-verified artifact. Not false, but the summary surface silently drops the very distinction this change introduces; a user scanning the rail sees a neutral-positive label for a proof the verifier never checked.

**Recommendation:** Add a branch: `activeVerificationStatus === "unavailable" ? "Not checked — verifier offline" : …` (or shorter "Not checked" if the rail truncates).

#### Unavailable-badge remedy text is mouse-hover-only (`title` attribute on a non-focusable span)

**Severity:** Minor
**Location:** `app/components/ui/VerificationBadge.tsx:11-19`
**Issue type:** Affordance / Accessibility serialization
**Viewport:** all (worst on touch devices — no hover at all)
**Move:** Step 2 item 6 (tooltip discoverability), caller-directed
**Confidence:** High

The badge's actionable remedy ("Set LEAN_VERIFIER_URL to enable checking") lives only in a native `title` tooltip on a `<span>`. Native `title` never fires on touch devices and is unreachable by keyboard (the span is not focusable), failing the spirit of WCAG 1.4.13 (content on hover) and NNGroup guidance against hover-only disclosure. Mitigation: in global mode the amber banner (`LeanCodeDisplay.tsx:133-142`) repeats the full remedy inline, so the information is not lost — hence Minor, not Major. In node-scoped mode the banner never renders (Critical finding), which would leave the tooltip as the only remedy carrier — except the badge doesn't render there either; fixing the Critical finding raises the value of fixing this one.

**Recommendation:** Keep the visible badge text as-is; the badge's OutputPanel/LeanPanel contexts always sit above a `LeanCodeDisplay` that shows the inline banner, so the simplest fix is ensuring the banner renders wherever the badge does (covered by the Critical finding). If the tooltip is kept, mirror it into visible or focus-revealed text rather than `title` alone.

#### Floating Re-verify/Edit button group can occlude the top-right of the new amber banner at narrow panel widths

**Severity:** Minor
**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:110-143`
**Issue type:** Occlusion / z-order
**Viewport:** narrow panes — roughly < ~560px content width (mobile, and desktop split-pane layouts)
**Move:** Step 2 item 11 (overlap/occlusion, unintended bucket) + item 4
**Confidence:** Medium

The button group is `absolute right-4 top-4 z-30` over the scroll container; its opaque buttons occupy roughly y 16–42px. The banner starts at y 24px (container `py-6`) and spans the full content width, so the buttons overlap the banner's first line region on the right. At comfortable widths the left-aligned uppercase heading ("VERIFIER OFFLINE — PROOF NOT CHECKED", ~300px at `text-xs` tracking-wide) clears the right-aligned group (~180px: Re-verify + Edit + gaps), but once available width drops below heading + buttons + paddings, the heading and first paragraph line run *under* the opaque `bg-blue-50`/`bg-[var(--ivory-cream)]` buttons and become unreadable. This overlap pair is introduced by the diff: the banner is new, and the Re-verify button now also appears in exactly this state (`LeanCodeDisplay.tsx:111`). The pre-existing red error box shares the geometry, but it renders only with `verificationErrors` whose `<pre>` wraps below; the banner's static heading sits precisely in the occlusion band. This is unintended occlusion (text hidden), not intended layering.

**Recommendation:** Reserve clearance for the floating controls on the banner, e.g.:

```tsx
// Before
<div className="mb-4 rounded border border-amber-300 bg-amber-50 px-4 py-3">

// After — keep first lines clear of the floating button group
<div className="mb-4 mr-44 rounded border border-amber-300 bg-amber-50 px-4 py-3">
```

or move the banner rendering above the `relative` code area (as a `shrink-0` sibling) so it never shares space with the floating controls. **Tradeoff:** `mr-44` wastes right-side width at large viewports; the structural move is cleaner but changes scroll behavior (banner would no longer scroll away — arguably desirable for a status of this importance).

#### Reload drops "unavailable" silently (by design) — banner and badge vanish

**Severity:** Informational
**Location:** `app/lib/utils/workspacePersistence.ts:34-37` (sanitizer), fact-check Claim 21
**Issue type:** State coverage
**Viewport:** all
**Move:** Step 2 item 6
**Confidence:** High

Per the fact-check report (Claim 21, Verified, executed), `sanitizeVerificationStatus` maps `"unavailable"` → `"none"` on both save and load — intentional ("transient verifier-state, not artifact-state") and test-covered. Consequence worth stating: after a refresh, a user who saw "Verifier offline — proof not checked" sees no badge and no banner at all (`"none"` renders nothing), and the remedy instruction is gone. Acceptable by design; if this proves confusing in practice, re-probing the verifier on load (or keeping the status until next verify) would restore the signal. No change requested.

#### Re-verify button lacks an `:active` (pressed) style

**Severity:** Informational
**Location:** `app/components/features/lean-display/LeanCodeDisplay.tsx:112-118`
**Issue type:** State coverage
**Viewport:** all
**Move:** Step 2 item 8 (state matrix)
**Confidence:** High

The diff modifies this button's visibility condition, putting it in item-8 scope. It has default, hover, focus, and disabled styles but no `active:` variant, so a click gives no pressed feedback beyond the hover shade — mildly "dead"-feeling, and the styling predates this diff. Optional: `active:bg-blue-200`.

## What Looks Good

- **The banner is distinguished by wording, structure, and color** — amber box with its own heading text vs. the red "lake build output" box vs. the green "Verified" badge. Not color-alone (WCAG 1.4.1 satisfied); the fact-check confirms tests assert `Verified` is absent for `unavailable` (`OutputPanel.test.tsx:112-116`).
- **Banner and error box are mutually exclusive by construction** — `useFormalizationPipeline.ts:121-126` clears `verificationErrors` for non-invalid statuses (fact-check Claim 15, Verified), so the amber and red boxes can never stack.
- **No long-string layout risk from the new status**: the route's `detail` field (e.g., "HTTP 500") is dropped client-side (`unavailableReason` removed with no consumer — fact-check Claim 23), and `errors` is cleared for `unavailable`, so the banner's content is fixed-length prose that wraps at `text-xs`; `LEAN_VERIFIER_URL` (~17ch, mono) fits even a 320px pane. The invalid path's long verifier output remains capped by the pre-existing `max-h-64 overflow-auto` `<pre>` with `whitespace-pre-wrap` (`LeanCodeDisplay.tsx:151`).
- **Controls stay outside the scroll region** — Re-verify/Edit are absolutely positioned siblings of the `overflow-auto` container (fact-check Claim 10, Verified), so they never scroll away (item 2 pattern done right), modulo the narrow-width occlusion noted above.
- **Re-verify shown, not hidden, after unavailability** — extending the visibility condition to `"unavailable"` follows the "update label / keep control available" principle (item 6): the user has an in-context retry path instead of a dead end.
- **Contrast is adequate**: `text-amber-800` (#92400E) on `bg-amber-50` (#FFFBEB) ≈ 6.8:1 and `text-amber-900` body text higher still; badge `text-amber-700` (#B45309) on white/ivory ≈ 4.7–5.0:1 — passes WCAG 1.4.3 AA for the 12px text used.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Status must be conveyed by more than color | WCAG 1.4.1 | Banner/badge carry explicit text; SessionBanner-dot fix recommends `title` + shape, not a new color alone |
| Status messages communicated | WCAG 4.1.3 | Critical finding: node-scoped mode communicates nothing for `unavailable` |
| Content on hover must be dismissable/reachable | WCAG 1.4.13, NNGroup tooltip guidance | Badge `title`-only remedy flagged; inline banner preferred |
| Keep controls available with updated labels | NNGroup / skill item 6 | Endorsed Re-verify visibility extension to `unavailable` |
| Overlap: wrong-thing-on-top, not overlap itself, is the bug | Skill item 11 | Floating controls vs. banner heading flagged as unintended occlusion at narrow widths |

## Keyboard Navigation

The diff modifies focusable elements (the Re-verify button's visibility condition) — in scope.

**Focus order.** In-scope focusables in DOM/tab order within `LeanCodeDisplay`: (1) Re-verify button (`LeanCodeDisplay.tsx:112`, now reachable in the `unavailable` state), (2) Edit/Done toggle (`:120`), then scroll-container content — invalid-only "Explain this error" button (`:154`), iterate input and send button (`:203`, `:213`). DOM order matches visual top-right → content reading order for interactive elements; the new banner contains no focusables, so its visual position (left of the buttons) creates no focus/visual mismatch. No WCAG 2.4.3 violation.

**Escape-key behavior.** N/A — no modals or overlays in this diff (the SessionBanner dropdown's outside-click dismissal is pre-existing and untouched).

**Skip-link presence.** N/A — diff does not change page-level structure.

**Focus-trap risks.** No focus-trap risks identified. The Re-verify button uses `disabled` (not `aria-disabled`), so it leaves the tab order when disabled; focus rings (`focus:ring-1 focus:ring-blue-400`) are present and not clipped — the button group sits at `z-30` above the scroll container, and its parent has `overflow-hidden` with the buttons inset 16px from the edges, so rings render fully.

## Viewport Verification Checklist

- [x] 360px mobile: banner text wraps (`text-xs`, no unbreakable tokens beyond ~17ch `LEAN_VERIFIER_URL`); no horizontal overflow — **but** floating buttons occlude the banner heading (Minor finding); Re-verify/Edit targets (~26px tall via `py-1` + text) meet WCAG 2.5.8 24px AA, below AAA 44px (pre-existing sizing)
- [x] 1366x768: Re-verify/Edit pinned top-right outside scroll — visible without scrolling; iterate bar docked `shrink-0` at bottom
- [x] 1920x1080: banner spans content width inside `px-8` container; no excessive whitespace introduced

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Node-scoped mode renders no state for `unavailable` (status destroyed by `toNodeVerificationStatus`) | Critical | State coverage / Affordance | `decomposition.ts:29-38`, `page.tsx:348-350`, `useActiveArtifactState.ts:41-42` | High |
| 2 | SessionBanner status dot shows `unavailable` identically to `none` | Major | State coverage | `SessionBanner.tsx:18-23` | High |
| 3 | Icon Rail Lean statusSummary says "Code ready" for unchecked proof | Minor | State coverage | `usePanelDefinitions.tsx:110-116` | High |
| 4 | Badge remedy text is `title`-tooltip-only (mouse hover; no touch/keyboard path) | Minor | Affordance | `VerificationBadge.tsx:11-19` | High |
| 5 | Floating Re-verify/Edit group occludes banner heading at narrow widths | Minor | Occlusion / z-order | `LeanCodeDisplay.tsx:110-143` | Medium |
| 6 | Reload drops `unavailable` → banner/badge vanish (intentional, test-covered) | Informational | State coverage | `workspacePersistence.ts:34-37` | High |
| 7 | Re-verify button has no `:active` pressed style | Informational | State coverage | `LeanCodeDisplay.tsx:112-118` | High |

## Overall Assessment

In global scope this change is visually well executed: the amber banner, badge, and Re-verify affordance form a coherent, text-plus-color-differentiated "not checked" state that cannot be confused with either "Verified" or "Verification Failed", with sensible contrast and no layout hazards from variable-length strings (the one long-string vector, the route's `detail`, never reaches the UI). The single most important thing to fix is the decomposition-mode gap: the `unavailable` status is silently converted to "unverified"/"none" before any node-scoped surface can render it, so an entire mode gets zero feedback when the verifier is offline — the mapping functions in `decomposition.ts` (untouched by the diff) are the choke point, and either extending the node status enum or letting the session's status drive the panel display fixes every node-scoped surface at once. The remaining findings are localized polish: an explicit dot branch in SessionBanner, a rail-summary label, and right-clearance on the banner under the floating buttons — all fixable in place; nothing indicates a structural problem.
