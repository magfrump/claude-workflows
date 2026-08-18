# UI Visual Review — BalancedPerspectivesPanel (evidence pipeline)

**Commit:** 7f30210
**Scope:** `git diff 9c9edf5...HEAD` — `app/components/panels/BalancedPerspectivesPanel.tsx` (streaming-preview / "between" tension rendering). Companion changes in `proxy.ts`, `evidence-search/route.ts`, `evidenceStore.ts` carry no rendered UI and are out of scope for this critic.
**Date:** 2026-08-18
**Based on:** `code-fact-check-report.md` (k=2, commit 7f30210) — foundation; the `between[0]` TypeError reproduction and guard behavior are taken as established, not re-verified.
**Review mode:** Mechanical (diff-scoped), with targeted state-rendering checks for the streaming/partial-data cases named in the brief.

## Environment

- **Files reviewed:** `app/components/panels/BalancedPerspectivesPanel.tsx` (full read), supporting types via fact-check report (`app/lib/types/artifacts.ts:100`, `app/lib/utils/mergeStreamingPreview.ts`)
- **Target viewports:** all (findings are data-shape dependent, not width dependent)
- **Target browsers / platforms:** modern evergreen + mobile Safari
- **Constraint:** static TSX review only; no dev server started (ports contended, per brief)

---

## Findings

#### Endpoint-row guard checks array-presence, not element-presence — dangling "↔" renders mid-stream

**Severity:** Minor
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`
**Issue type:** State coverage
**Viewport:** all
**Move:** Step 2 item 8 (state matrix) / brief's element-presence vs array-presence check
**Confidence:** High

The shipped guard `{t.between && (…)}` prevents the `between[0]`-on-`undefined` crash (fact-check Claim 11) by testing that `between` *exists*. But the row body renders three cells — `{t.between[0]}`, a literal `↔`, and `{t.between[1]}` — which require the array to hold **two** elements. The same partial-JSON stream that can deliver a `between`-less tension can also deliver a partially-filled `between`: `[]` (bracket parsed, no poles yet) or `["Consequentialism"]` (first pole parsed, second still streaming). Both are truthy arrays, so both pass `t.between &&`:

- `between: []` → renders a lone `↔` arrow between two empty spans (a tension glyph pointing at nothing).
- `between: ["A"]` → renders `A ↔` with an empty trailing span — a dangling relationship with one pole missing.

Neither crashes, so this is not a correctness/stability defect; it is a transient, self-healing visual glitch that resolves when the second pole arrives. It is worth flagging because the row briefly presents a *semantically wrong* artifact — a "balanced perspective tension" implies two opposing poles, and `A ↔ ⟨blank⟩` misrepresents that during the stream. It is the exact element-presence-vs-array-presence gap the guard's array-only test leaves open.

**Recommendation:** Guard on element count, not array truthiness, so the row appears only once both poles exist. This matches the panel's other list guards, which already gate on `?.length`.

```tsx
// before
{t.between && (

// after — both poles present before rendering the endpoint row
{t.between?.length === 2 && (
```

(`=== 2` rather than `>= 2` mirrors the `[string, string]` tuple type at `artifacts.ts:100`; `>= 2` is equally safe if over-long partial arrays are a concern.)

---

#### Tension row can render an empty red box when only `description` is still streaming

**Severity:** Minor
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:112-121`
**Issue type:** State coverage
**Viewport:** all
**Move:** Step 2 item 8 / brief's "state that renders no distinguishable UI"
**Confidence:** Medium

A tension whose `between` has not yet arrived **and** whose `description` is empty/undefined renders the outer `rounded border border-red-200 bg-red-50 px-3 py-2` container with the `between` block suppressed and an always-emitted `<p className="mt-1 text-xs text-red-800">{t.description}</p>` holding no text — i.e. an empty red-bordered box with a sliver of padding. This is a reachable mid-stream state: the `tensions` array can contain an object (counted in the `Tensions` collapsible's `count`) before either of its fields has parsed. The box carries no information but occupies vertical space and reads as a rendering artifact. Lower confidence than the finding above because it depends on the producer emitting an empty tension object rather than deferring the array push; the fact-check confirms the producer emits under-populated tension objects, which makes it plausible.

**Recommendation:** Skip rows with no displayable content, e.g. gate the row on `t.between?.length === 2 || t.description`, or render the description `<p>` only when `t.description` is truthy (consistent with how `topic`/`summary` are guarded at lines 46 and 56).

```tsx
// render the description paragraph only when present
{t.description && <p className="mt-1 text-xs text-red-800">{t.description}</p>}
```

---

## What Looks Good

- **Progressive disclosure without content reflow.** Every section (Topic, Summary, Perspectives, Tensions, Synthesis) is independently presence-guarded (lines 46, 56, 66, 107, 129), and sections append in document flow as streamed fields arrive. New content grows the panel downward; it does not displace or reflow already-rendered sections. There are no fixed heights, absolute positioning, or reserved-space placeholders that would cause layout *jump* — so the mid-stream layout-shift concern from the brief is benign here: the shift is additive-downward, which is the expected and low-jank form of streaming fill-in.
- **Crash guard is correct as far as stability goes.** `{t.between && …}` fully prevents the reported `between[0]`-on-`undefined` TypeError (fact-check Claim 11); the two findings above are cosmetic residue of the *transient* partial-array window, not a reintroduction of the crash.
- **List guards use `?.length`.** Perspectives, supporting arguments, vulnerabilities, tensions, and `howAddressed` all gate on `(x?.length ?? 0) > 0` — the correct element-presence pattern that the `between` endpoint row should adopt.
- **`hasDisplayData` gating.** The empty/loading/data tri-state is handled by `ArtifactPanelShell` via `hasDisplayData` + `loading && !hasDisplayData`, so there is no window where the panel is blank with no empty-message affordance.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Loading/status states communicated | WCAG 4.1.3 | `ArtifactPanelShell` shows explicit loading vs empty messaging via `hasDisplayData` |
| Element-presence guards over reference-presence | Defensive-rendering convention (matches sibling `?.length` guards in this file) | Recommended for the `between` endpoint row (findings 1–2) |

## Keyboard Navigation

> No new focusable elements in this diff.

The diff's change is the addition of the `{t.between && …}` presence guard wrapping display-only `<span>` elements. The surrounding `EditableSection` wrappers are pre-existing and unmodified by this diff. No new buttons, links, inputs, modals, overlays, or focus-managing regions are introduced.

- **Escape-key behavior:** N/A — no modals or overlays in this diff.
- **Skip-link presence:** N/A — diff does not change page-level structure.
- **Focus-trap risks:** No focus-trap risks identified.

## Viewport Verification Checklist

- [x] 360px mobile: content reachable, no horizontal overflow (text-xs mono cells wrap within their flex row; no fixed widths)
- [x] 1366x768: no action buttons in scope; sections stack in flow
- [x] 1920x1080: sections fill flow width without excessive whitespace

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | `between` guard tests array-presence not element count → dangling `↔` mid-stream | Minor | State coverage | `BalancedPerspectivesPanel.tsx:113-119` | High |
| 2 | Empty red tension box when only `description` still streaming | Minor | State coverage | `BalancedPerspectivesPanel.tsx:112-121` | Medium |

## Overall Assessment

The panel's visual/layout posture is sound: the crash guard does its job, sections are individually presence-gated, and streaming fill-in appends downward without reflowing existing content — the layout-shift concern is a non-issue here. What remains are two transient, self-healing rendering artifacts in the narrow partial-JSON window: the endpoint-row guard checks that `between` *exists* but not that both poles have arrived, so a `[]` or one-element array briefly renders a dangling `↔` glyph; and a bare tension object can flash an empty red box. Both are Minor, both are fixable in place with the same one-line pattern the rest of the file already uses (`?.length`-based guards). The single most important change is finding 1: replace `t.between &&` with `t.between?.length === 2` so the tension endpoint row only appears once it is semantically complete.
