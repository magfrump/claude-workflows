Commit: c95c9cb

# UI Visual Review — Lean verifier "offline" state (advisory critic)

**Scope:** `git diff d86d2dc..c95c9cb` (worktree wt-lean, pinned at c95c9cb) — 4 tsx components: `LeanCodeDisplay.tsx`, `VerificationBadge.tsx`, plus their tests and `OutputPanel.test.tsx`
**Date:** 2026-08-06
**Review mode:** Mechanical (default) + item 6/8 affordance spot-checks, since the diff's whole purpose is a new visual state
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/lean/fact-check.md`
**Tier:** Advisory — all findings are green / "Consider" only. Nothing here blocks.

## Environment

- **Files reviewed:** `app/components/features/lean-display/LeanCodeDisplay.tsx`, `app/components/ui/VerificationBadge.tsx` (at c95c9cb)
- **Target viewports:** 320–480 / 768–1024 / 1920+
- **Target platforms:** modern evergreen browsers + mobile Safari
- **Contamination guard honored:** read only from wt-lean at c95c9cb; did not touch `/workspace/external/meta-formalism-copilot`.

---

## What looks good (the PR's core intent is met)

The amber "offline" state is genuinely distinct from the red "failed" state at every surface, and the distinction never relies on color alone:

- **Banner** (`LeanCodeDisplay.tsx:132-143`): amber palette (`border-amber-300 bg-amber-50`, heading `text-amber-800`, body `text-amber-900`) vs. the red invalid block (`border-red-300 bg-red-50 text-red-800`, `LeanCodeDisplay.tsx:146-172`). Both carry a distinct text heading ("Verifier offline — proof not checked" vs "lake build output"), so the state is legible without perceiving hue — satisfies WCAG 1.4.1.
- **Badge** (`VerificationBadge.tsx:11-19`): amber text + unique copy "Verifier offline — not checked", separate from "Verification Failed" (red) and "Verified" (green).
- **Overflow discipline:** the amber banner holds only fixed short copy (no unbounded child), so it correctly omits the `max-h-64 overflow-auto` cap that the red block needs for verifier output. Sits inside the existing `h-full overflow-auto` scroll region — no new overflow trap.
- **Re-verify affordance** (`LeanCodeDisplay.tsx:110-119`): extending the render gate to `"unavailable"` is correct and gives the user a recovery path. Button carries full state coverage — `disabled:opacity-50`, `hover:bg-blue-100`, `focus:ring-1`, and is pinned `absolute ... z-30` outside the scroll container so it stays visible.

---

## Consider-tier findings

#### C1 — Amber vs red badge distinguished mainly by hue for colorblind users
**Severity:** Consider (Informational) · **Issue type:** Affordance / color perception
**Location:** `app/components/ui/VerificationBadge.tsx:14` (amber) vs `:21` (red)
**Evidence (quoted):** `text-amber-700` vs `text-red-700` — inline text badges with no icon or shape differentiator.
**Confidence:** Medium
**Legibility-target:** protanopia / deuteranopia users scanning the badge quickly.
Amber (`#b45309`) and red (`#b91c1c`) are adjacent hues that red-green colorblind users can confuse. This is **not a WCAG 1.4.1 failure** because the label text differs ("Verifier offline — not checked" vs "Verification Failed") — the words carry the meaning. Consider only: a small leading glyph (e.g. a warning triangle for offline, ✕ for failed) would let the state be read pre-attentively without parsing the sentence. Same pattern would strengthen the banner heading.

#### C2 — Badge's config instruction lives only in a `title` tooltip
**Severity:** Consider (Informational) · **Issue type:** Affordance / discoverability
**Location:** `app/components/ui/VerificationBadge.tsx:15`
**Evidence (quoted):** `title="Lean verifier is offline or not configured. Set LEAN_VERIFIER_URL to enable checking."`
**Confidence:** High
**Legibility-target:** touch and keyboard users (no hover), who never see `title`.
`title` surfaces on pointer-hover only — invisible on touch and not reliably reachable by keyboard/AT. Acceptable as-is because the **same instruction is rendered visibly in the banner** (`LeanCodeDisplay.tsx:137-140`), so no information is truly gated behind hover; the badge tooltip is redundant reinforcement. No change needed unless the badge can appear in a context where the banner does not.

#### C3 — Amber badge text contrast is borderline (pre-existing pattern, not introduced here)
**Severity:** Consider (Informational) · **Issue type:** Contrast
**Location:** `app/components/ui/VerificationBadge.tsx:14`
**Evidence (quoted):** `className="ml-2 text-xs font-normal text-amber-700"`
**Confidence:** Medium
**Legibility-target:** low-vision users reading the 12px badge.
`text-amber-700` (`#b45309`) on a light ivory/white background lands ~4.5–4.7:1 — meets WCAG 1.4.3 AA for normal text, but only just, at `text-xs`. This exactly mirrors the existing `text-green-700` / `text-red-700` badges, so it is **consistent with the established design system**, not a regression. Consider `text-amber-800` for a bit more headroom if the badge ever renders on a darker surface. The banner body (`text-amber-900` on `bg-amber-50`) is comfortably above threshold — no concern there.

---

## Keyboard Navigation

The diff adds/modifies focusable elements (the Re-verify button's render gate now includes `"unavailable"`), so the section applies.

- **Focus order:** The Re-verify button (`LeanCodeDisplay.tsx:112`) and Edit/Done button (`:120`) share the absolute-positioned control cluster and appear in DOM order matching visible left-to-right order. No `order`/`row-reverse` reordering. OK.
- **Escape-key behavior:** N/A — no modal/overlay/dropdown added or modified in this diff.
- **Skip-link presence:** N/A — diff does not change page-level landmarks.
- **Focus-trap risks:** None identified. Re-verify button has a visible `focus:ring-1 focus:ring-blue-400`; disabled state uses real `disabled` (not `aria-disabled` with a live handler), so it drops out of the tab order cleanly.

## Overall assessment

Clean, low-risk visual change that achieves its stated intent: the amber "verifier offline" state is unambiguously separate from the red "verification failed" state at banner and badge, and never leans on color alone. No overflow, sizing, positioning, or state-coverage defects. The only notes are hardening opportunities (icon/shape redundancy for colorblind users; a hover-only tooltip that is already backstopped by visible banner copy) — all green/Consider tier.
