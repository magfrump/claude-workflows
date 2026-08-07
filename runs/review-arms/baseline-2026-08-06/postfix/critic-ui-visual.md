Commit: 7f30210

# UI Visual Review — BalancedPerspectivesPanel streaming guard (postfix)

**Scope:** git diff 9c9edf5..7f30210 (worktree wt-postfix, pinned at 7f30210)
**Date:** 2026-08-06
**Review mode:** Mechanical (advisory / green-tier pass, no fix loop)
**Based on:** postfix/fact-check.md (Claims 6 & 7 cover this change)

## Environment

- **Files reviewed (UI):** `app/components/panels/BalancedPerspectivesPanel.tsx` (only UI file in diff; other changed files — `evidence-search/route.ts`, `evidenceStore.ts`, `proxy.ts`, and their tests — are non-rendering and out of scope for this critic)
- **Target viewports:** 320–480 / 768–1024 / 1920+
- **Target browsers / platforms:** modern evergreen + mobile Safari
- **Change under review:** the Tensions render path now wraps the `t.between[0] ↔ t.between[1]` row in a `{t.between && (...)}` guard so partial-JSON streaming (a tension arriving before its `between` tuple) renders the description alone instead of throwing a TypeError.

## Findings

Only one advisory observation. The change is a conditional-render guard around a non-interactive text row; it adds no focusable elements, no overflow surface, no positioning, and no interactive states.

#### Orphan top margin when `between` is absent mid-stream

**Severity:** Informational (Consider)
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-120`
**Issue type:** Sizing (spacing)
**Viewport:** all
**Move:** Step 2 item 5 (vertical spacing)
**Confidence:** Medium
**Legibility-target:** streaming/partial render — a tension card shown after `description` arrives but before `between` does.

**Evidence:**
```tsx
{t.between && (
  <div className="flex items-center gap-1 text-xs font-mono text-red-700">
    ...
  </div>
)}
<p className="mt-1 text-xs text-red-800">{t.description}</p>
```
When the guard is false (streaming state the fix exists to handle), the `<p>` still carries `mt-1`, so the description sits with a small top margin inside the `px-3 py-2` card with nothing above it. Purely cosmetic and self-corrects the instant `between` streams in; the card border/background render fine and text is fully legible. Consider `${t.between ? "mt-1" : ""}` on the `<p>` if the transient spacing ever looks off, but this is not worth a change on its own.

## What Looks Good

- The guard is the correct, minimal fix: it gates only the tuple row and preserves `{t.description}`, so a partial tension degrades to a description-only card rather than crashing the whole panel. Content is never hidden — the previously-crashing branch now renders less, not nothing.
- Outer conditionals are consistent with the file's established pattern (`(displayMap.tensions?.length ?? 0) > 0`, `t.between && ...`), so the change reads idiomatically.
- Card styling (`rounded border border-red-200 bg-red-50 px-3 py-2`) is unchanged; no overflow, positioning, or z-order surface touched.

## Keyboard Navigation

> No new focusable elements in this diff.

The guarded row and the description are static text; the surrounding `EditableSection`/`CollapsibleSection` wrappers are unchanged by this diff.

## Viewport Verification Checklist

- [x] 360px mobile: text row is `flex items-center gap-1`, wraps within the card; no horizontal overflow introduced.
- [x] 1366x768: no action buttons affected; unchanged.
- [x] 1920x1080: unchanged.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Orphan `mt-1` on description when `between` absent | Informational | Sizing | `BalancedPerspectivesPanel.tsx:120` | Medium |

## Overall Assessment

Clean, well-scoped streaming guard with no visual or layout regressions. The only observation is a transient, self-correcting cosmetic margin on the partial-render path — Consider-tier, not worth a change on its own. Nothing blocks; nothing to fix.
