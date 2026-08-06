# UI Visual Review — BalancedPerspectivesPanel streaming guard (HEAD~3..HEAD)

**Commit:** 7f30210
**Scope:** `git diff HEAD~3..HEAD` in `/workspace/external/meta-formalism-copilot`, restricted to the UI-rendering portion (`BalancedPerspectivesPanel.tsx` + its new test). Non-UI files in the range (`app/api/evidence-search/route.ts`, `app/lib/stores/evidenceStore.ts`, `proxy.ts`, `proxy.test.ts`) are out of scope for this critic.
**Date:** 2026-08-06
**Based on:** code fact-check report (k=3 merged), supplied by the orchestrator. Documented behavior from that report is taken as foundation and not re-verified.

## Environment

**Files reviewed (diff-scoped):**
- `/workspace/external/meta-formalism-copilot/app/components/panels/BalancedPerspectivesPanel.tsx` (lines 113-120 changed)
- `/workspace/external/meta-formalism-copilot/app/components/panels/BalancedPerspectivesPanel.test.tsx` (new file, 56 lines)

**Files read for layout context only (not under review):**
- `app/components/panels/ArtifactPanelShell.tsx` — establishes the scroll container (`flex min-h-0 flex-1` + inner `flex-1 overflow-y-auto px-6 py-4`) with `WholeTextEditBar` docked *outside* the scroll area.
- `app/components/ui/CollapsibleSection.tsx` — children always mounted, hidden via `style={{display:"none"}}` when collapsed (`CollapsibleSection.tsx:50-51`).
- `app/components/layout/PanelShell.tsx`, `FocusPane.tsx`, `SplitPane.tsx` — panes carry `min-w-0`, so the panel genuinely shrinks with the viewport and shrinks again in split mode.

**Project UI guidelines doc:** none found. `docs/decisions/002-multi-artifact-ui-layout.md` exists but is an architecture decision record, not a layout style guide. Falling back to skill defaults + WCAG 2.2.

**Target viewports:** 360px (narrow) · 1366x768 (laptop, fold check) · 1920x1080 (wide, incl. split-pane halving)

**Review mode:** Mechanical (checklist items 1-5 and 8). No web search performed. Contrast ratios computed locally from Tailwind v4 default palette hexes via the WCAG 2.x relative-luminance formula.

---

### Findings

#### F1 — Tension arrow glyph fails WCAG contrast at 2.53:1

**Severity:** Major
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:116`
**Issue type:** Other (color contrast / legibility) — adjacent to the mechanical checklist rather than one of items 1-5, 8; reported because the line is an added line in this diff and the defect is mechanically verifiable.
**Viewport:** all
**Move:** Outside numbered mechanical items (contrast audit of added markup)
**Confidence:** High
**Evidence:**
> `<span className="text-red-400">&harr;</span>`
> (parent card: `<div className="rounded border border-red-200 bg-red-50 px-3 py-2">`, line 112)

The `↔` glyph is rendered in `text-red-400` (`#f87171`) on `bg-red-50` (`#fef2f2`), a measured contrast ratio of **2.53:1**. At `text-xs` (12px, non-bold) this is normal-size text under WCAG 2.2 SC 1.4.3, which requires 4.5:1; it also fails SC 1.4.11 (3:1) if you classify the glyph as a non-text graphical object instead. This is not decorative chrome — the arrow is the *only* thing in the row that communicates that A and B stand in tension rather than being an unordered pair, so its meaning is load-bearing. The two labels around it are fine: `text-red-700` on `bg-red-50` measures 5.91:1 and the description's `text-red-800` measures 7.60:1, so the arrow is the single outlier in an otherwise AA-compliant card. Note this is pre-existing styling that the diff re-emits verbatim inside the new guard — the change did not introduce the ratio, but it did put the line back under review.

**Recommendation:** Darken the glyph to `text-red-600` (`#dc2626`, ≈4.8:1) or reuse the endpoints' `text-red-700`, and give the glyph a text alternative so its meaning survives for screen readers.

```diff
-<span className="text-red-400">&harr;</span>
+<span className="text-red-600" aria-hidden="true">&harr;</span>
+<span className="sr-only">in tension with</span>
```

**Legibility-target:** for-author

---

#### F2 — Guard tests array presence, not element presence: partial `between` renders a dangling arrow

**Severity:** Minor
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`
**Issue type:** State coverage
**Viewport:** all
**Move:** Checklist item 8, generalized from interactive-element states to render states of the added conditional
**Confidence:** High
**Evidence:**
> `{t.between && (`
> `  <div className="flex items-center gap-1 text-xs font-mono text-red-700">`
> `    <span>{t.between[0]}</span>`
> `    <span className="text-red-400">&harr;</span>`
> `    <span>{t.between[1]}</span>`

The guard is a truthiness check on the array, so it admits every partially-materialized array. The fact-check confirms that a one-element `between` is a reachable parse state mid-stream; partial-JSON parsers also commonly surface an in-progress string as `""`. In both cases `t.between` is truthy, the row renders, and `t.between[1]` is `undefined` (or empty), which React renders as nothing — producing a visible **`A ↔`** with the arrow pointing at empty space, or **`↔ B`** with a leading orphan glyph. The `items-center` flex row keeps the arrow vertically centered against a zero-width sibling, so the result reads as a truncation artifact rather than as a loading state. This is the same class of defect the diff set out to fix, one step further down the stream; the fix closes the crash but not the visual incompleteness. The render states of this added conditional are three, not two: absent (handled), partial (unhandled), complete (handled).

**Recommendation:** Gate on both endpoints being non-empty so the row appears only once it is meaningful.

```diff
-{t.between && (
+{t.between?.[0] && t.between?.[1] && (
```

**Legibility-target:** for-author

---

#### F3 — Endpoints row lacks wrapping/`min-w-0` guards; long labels force horizontal panel scroll

**Severity:** Minor
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:114-118`
**Issue type:** Overflow
**Viewport:** 360px; also 1920px in split-pane mode (each half is narrow)
**Move:** Checklist items 1 and 3
**Confidence:** Medium
**Evidence:**
> `<div className="flex items-center gap-1 text-xs font-mono text-red-700">`
> `  <span>{t.between[0]}</span>`

`between[0]` and `between[1]` are LLM-generated strings of unbounded length rendered as flex children. Flex items default to `min-width: auto`, so each span refuses to shrink below its min-content width — the longest unbroken token. Multi-word labels will wrap acceptably, but a single long token (a hyphen-free perspective id, a compound term, a URL) sets a min-content floor wider than the card, and the row overflows horizontally. Because the panes carry `min-w-0` (`FocusPane.tsx:13`, `SplitPane.tsx:30`), the panel really does compress to the viewport, so the shell's `overflow-y-auto` content area (`ArtifactPanelShell.tsx:112`) computes `overflow-x` to `auto` and the *entire panel body* — topic, summary, all sections — gains a horizontal scrollbar because of one tension label. `font-mono` widens the failure envelope further, since Geist Mono advances are wider than the surrounding serif at the same 12px. Confidence is Medium because it depends on model output shape rather than on a guaranteed input.

**Recommendation:** Let the row wrap and let each endpoint shrink and break, so overflow resolves vertically inside the card instead of horizontally across the panel.

```diff
-<div className="flex items-center gap-1 text-xs font-mono text-red-700">
-  <span>{t.between[0]}</span>
+<div className="flex flex-wrap items-center gap-1 text-xs font-mono text-red-700">
+  <span className="min-w-0 break-words">{t.between[0]}</span>
```

(apply the same `min-w-0 break-words` to the `between[1]` span)

**Legibility-target:** for-author

---

#### F4 — Unconditional `mt-1` leaves the card top-heavy when the endpoints row is suppressed

**Severity:** Minor
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:112,120`
**Issue type:** Sizing
**Viewport:** all
**Move:** Checklist item 5
**Confidence:** High
**Evidence:**
> `<div className="rounded border border-red-200 bg-red-50 px-3 py-2">`
> `<p className="mt-1 text-xs text-red-800">{t.description}</p>`

`mt-1` exists to separate the description from the endpoints row above it. Now that the row is conditional, the margin is not. When the guard suppresses the row, the description becomes the card's first child and its 4px top margin stacks on the card's 8px `py-2` — the parent's padding blocks margin collapse — yielding 12px above the text and 8px below. The result is a visibly off-center single-line card in a `space-y-2` stack where neighbouring complete cards are symmetric. Cosmetic, and only observable in the transient mid-stream state the guard was added for, but it is a direct consequence of this diff: before the change the margin was always paired with a preceding sibling.

**Recommendation:** Move the spacing to the row that owns it, so the description carries no orphan margin.

```diff
-<div className="flex items-center gap-1 text-xs font-mono text-red-700">
+<div className="mb-1 flex items-center gap-1 text-xs font-mono text-red-700">
...
-<p className="mt-1 text-xs text-red-800">{t.description}</p>
+<p className="text-xs text-red-800">{t.description}</p>
```

**Legibility-target:** for-author

---

#### F5 — Endpoints row pops in mid-stream, shifting every tension below it

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:107-126`
**Issue type:** Responsive (reflow / layout stability)
**Viewport:** all
**Move:** Checklist item 5
**Confidence:** Medium
**Evidence:**
> `{(displayMap.tensions?.length ?? 0) > 0 && (`
> `  <CollapsibleSection title="Tensions" defaultOpen={false} count={...}>`

The panel re-renders on every streaming update, and the guard makes a ~16px line appear inside each tension card the moment `between` lands. In a multi-tension stream this inserts rows at several vertical positions, pushing the Proposed Resolution section and any content the user is currently reading downward — a cumulative-layout-shift pattern (NNGroup and Core Web Vitals both flag content that moves under a reading cursor). Two things bound the impact and are the reason this is Informational rather than Minor. First, the Tensions section is `defaultOpen={false}`, so the shifting content is inside a `display: none` subtree for any user who has not expanded it — the shift is invisible in the default path and only reaches users who expand Tensions *during* streaming. Second, `display: none` also means the cards contribute no height while collapsed, so nothing below the section moves either. No change is recommended; reserving space for the row would be worse, since a blank reserved line would read as a rendering bug. Flagging so the orchestrator can record that the layout-shift question was considered and consciously accepted.

**Recommendation:** No action. If tension cards ever become `defaultOpen` or get surfaced outside `CollapsibleSection`, revisit — the shift becomes user-visible at that point.

**Legibility-target:** for-orchestrator-synthesis

---

#### F6 — Regression test covers the absent case only, and mocks away the layout it renders into

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.test.tsx:9-13,44-55`
**Issue type:** State coverage
**Viewport:** n/a (test-side)
**Move:** Checklist item 8 (state matrix completeness)
**Confidence:** High
**Evidence:**
> `const partialTension = { description: "Half-streamed tension" } as unknown as Tension`
> `vi.mock('./ArtifactPanelShell', () => ({ default: ({ children, hasData }: ...) => hasData ? <div>{children}</div> : <div>empty</div> }))`

The new test pins two of the three render states from F2 — complete `between` and fully-absent `between` — and leaves the partial state (`["A"]`, or `["", "B"]`) uncovered, so a regression that reintroduces the dangling arrow would pass. Separately, mocking `ArtifactPanelShell` down to a bare `<div>` discards the real `flex min-h-0` / `overflow-y-auto` chain, which is the correct call for isolating panel logic but means these tests can never observe overflow, scroll, or spacing regressions of the kind in F3 and F4. Worth stating explicitly so the rubric does not read "regression test added" as coverage of the visual behavior. Adding a case asserting that a one-element `between` renders no arrow would close the F2 gap cheaply; the layout gap is not worth closing in jsdom, which has no layout engine.

**Recommendation:** Add a third case for the one-element `between` array asserting the endpoints row is absent (e.g. `expect(screen.queryByText('↔')).not.toBeInTheDocument()`). Leave the layout dimension to manual or Playwright checks.

**Legibility-target:** for-author

---

### What Looks Good

- **The guard is placed at the right granularity.** Wrapping only the endpoints row — rather than the whole card — keeps `t.description` rendering during the partial state, so the user sees the tension's substance as soon as it exists instead of an empty card that fills in later. That is the correct choice for a streaming surface and the test asserts it explicitly.
- **No content is hidden to solve a layout problem.** The suppressed row is genuinely not-yet-available data, not information being clipped away — consistent with the rule that overflow should be visible and scrollable, never hidden.
- **Item 2 (controls trapped in scroll containers) is clean.** `ArtifactPanelShell.tsx:111-116` keeps `WholeTextEditBar` as a sibling of the `overflow-y-auto` div, not inside it, so the edit affordance stays docked regardless of how many tensions stream in. The diff does not disturb this.
- **Item 3 is clean at the shell level.** `flex min-h-0 flex-1` on the content wrapper with `flex-1 overflow-y-auto` inside is the correct fill-and-scroll pairing; the diff adds no competing `shrink-0`/`flex-1` at the card level.
- **Item 4 is not applicable.** The diff introduces no absolutely-positioned elements. The only `absolute` in the render path (the edit banner, `ArtifactPanelShell.tsx:76`) is anchored to the shell's `relative` container at line 73 — correct, and untouched.
- **The `key={i}` on tensions is defensible here** despite the usual index-key caution, because streaming appends to the array rather than reordering it.

### Keyboard Navigation (REQUIRED)

No new focusable elements in this diff.

### Viewport Verification Checklist

Manual checks to run against a live stream with a multi-tension `balanced-perspectives` artifact, with the Tensions section expanded before generation starts.

**360px (narrow):**
- [ ] Expand Tensions during streaming; confirm no horizontal scrollbar appears on the panel body when a long endpoint label arrives (F3).
- [ ] Confirm long endpoint labels wrap inside the card rather than pushing the card border past the viewport.
- [ ] Confirm the `↔` glyph is legible against the red-50 card at 12px in normal room lighting (F1).

**1366x768 (laptop / fold check):**
- [ ] With Tensions expanded mid-stream, confirm cards missing `between` are not visibly top-heavy against complete neighbours (F4).
- [ ] Watch a full stream and note whether any tension card ever displays `A ↔` with nothing after the arrow (F2).
- [ ] Confirm the docked `WholeTextEditBar` stays visible as tensions accumulate and does not scroll away.

**1920x1080 (wide, including split-pane):**
- [ ] Open Balanced Perspectives as the secondary panel in a vertical split; each half is ~950px, and with the icon rail narrower still — recheck F3 at this width.
- [ ] Confirm the endpoints row does not stretch its spans across the full card width in a way that separates `A` from `↔` (flex `gap-1` should keep them adjacent, not justified).
- [ ] Confirm no cumulative jump of the Proposed Resolution section as tensions complete (F5).

### Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| F1 | Tension arrow glyph fails WCAG contrast at 2.53:1 | Major | Other (contrast) | `BalancedPerspectivesPanel.tsx:116` | High |
| F2 | Guard tests array presence, not element presence: partial `between` renders a dangling arrow | Minor | State coverage | `BalancedPerspectivesPanel.tsx:113-119` | High |
| F3 | Endpoints row lacks wrapping/`min-w-0` guards; long labels force horizontal panel scroll | Minor | Overflow | `BalancedPerspectivesPanel.tsx:114-118` | Medium |
| F4 | Unconditional `mt-1` leaves the card top-heavy when the endpoints row is suppressed | Minor | Sizing | `BalancedPerspectivesPanel.tsx:112,120` | High |
| F5 | Endpoints row pops in mid-stream, shifting every tension below it | Informational | Responsive | `BalancedPerspectivesPanel.tsx:107-126` | Medium |
| F6 | Regression test covers the absent case only, and mocks away the layout it renders into | Informational | State coverage | `BalancedPerspectivesPanel.test.tsx:9-13,44-55` | High |

### Overall Assessment

The change is small, correctly targeted, and improves the panel: it converts a hard crash during streaming into a graceful partial render, and it keeps the useful half of the data (`description`) on screen rather than blanking the card. Nothing in the diff regresses the panel's scroll or sizing structure, which is sound at the shell level — the docked edit bar and the `min-h-0`/`flex-1`/`overflow-y-auto` chain are all correct and untouched. Mechanical checklist items 2, 3, and 4 come back clean.

The substantive gap is F2: the guard checks that the array exists rather than that both endpoints do, so the exact streaming scenario it was written for can still produce a visibly broken row — `A ↔` with the arrow pointing at nothing — one parse-state later. It is a one-line change to close, and the accompanying test does not cover it. F1 is the highest-severity item but is inherited styling that the diff re-emits rather than a regression; it is worth fixing while the line is open, since 2.53:1 on a meaning-bearing glyph is a clear AA failure. F3 and F4 are small robustness and polish items in the same block. F5 and F6 are recorded for the rubric rather than for action; F5 in particular is materially bounded by `defaultOpen={false}` on the Tensions section, which keeps the mid-stream churn inside a `display: none` subtree for most users.

Recommended disposition: fix F2 and F1 before merge (both one-liners in the lines this diff already touches), take F3 and F4 opportunistically, and note F5/F6 in the review record without blocking.

## Goal-Alignment Note

- Answered: yes — mechanical checklist items 1-5 and 8 applied to the diff's TSX rendering change, with six findings and a viewport verification plan.
- Out of scope: non-UI files in the range (`app/api/evidence-search/route.ts`, `app/lib/stores/evidenceStore.ts`, `proxy.ts`, `proxy.test.ts`); branch content outside `HEAD~3..HEAD` (context only, per the partial-scope rule); runtime/browser verification, which was not performed — all findings are derived by reading code, and the viewport checklist above is the intended follow-up.
- Escalate: F2 to whichever critic owns correctness of the streaming guard — the guard is incomplete against the one-element `between` parse state that the supplied fact-check confirms is reachable, and that is a logic gap as much as a visual one, so it may deserve a severity above Minor when synthesized with a correctness critic's view. Also flag for the orchestrator that F1's contrast failure is pre-existing styling re-emitted by this diff, so the rubric should decide whether inherited defects surfaced by a diff count against it.
