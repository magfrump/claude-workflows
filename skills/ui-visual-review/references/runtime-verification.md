# Runtime Verification (Web Applications)

Reference for the `ui-visual-review` skill. Load this file when the user asks to "test
in browser", "check it visually", "run the app and verify", or when the project has
browser automation tooling available (Puppeteer, Playwright, Cypress).

Static review predicts what will happen at different viewport sizes by analyzing CSS and
layout logic. This step validates those predictions by running the application in a
browser. **This step is optional** and only applies when: (a) the project is a web
application with a runnable dev server, and (b) you have access to browser automation or
screenshot tools.

Skip this step if the project has no runnable frontend or if you are operating as a
sub-critic within the code-review orchestrator (where runtime access is typically
unavailable).

## Screenshot Capture Procedures

Capture screenshots at each verification breakpoint to create a visual record of the
current state. This serves two purposes: documenting what the UI looks like *now* (for
comparison after future changes) and providing evidence for issues found in the static
review.

### Procedure

1. Start the dev server (`npm run dev`, `yarn dev`, or project-equivalent)
2. Capture screenshots at each breakpoint defined in the cross-resolution checklist below
3. For each page or component under review, capture:
   - Default state (page load, no interaction)
   - Key interaction states (modal open, dropdown expanded, form with validation errors,
     long content that triggers scroll)
   - Edge cases flagged during the static review
4. Save screenshots to `docs/reviews/screenshots/` with naming convention:
   `{component}-{viewport}-{state}.png` (e.g., `sidebar-360px-collapsed.png`)

### Automation Example (Playwright)

```js
const viewports = [
  { width: 360, height: 800, name: 'mobile' },
  { width: 768, height: 1024, name: 'tablet' },
  { width: 1366, height: 768, name: 'laptop' },
  { width: 1920, height: 1080, name: 'desktop' },
];

for (const vp of viewports) {
  await page.setViewportSize({ width: vp.width, height: vp.height });
  await page.screenshot({ path: `docs/reviews/screenshots/${component}-${vp.name}-default.png`, fullPage: true });
}
```

When doing this manually, use browser DevTools device toolbar to set exact viewport
dimensions. The key is consistency — same viewports, same states, every time.

### 3D Viewport Content

Wait for the scene to stabilize before capturing. See `references/3d-viewport.md` for
the screenshot timing details.

## Cross-Resolution Verification Checklist

Run through this checklist at each breakpoint. This is the runtime counterpart to the
static analysis — you are confirming (or refuting) what the code review predicted.

### Breakpoints

| Category | Width | Represents | Key concerns |
|----------|-------|-----------|--------------|
| Small mobile | 360px | Typical Android phone | Touch targets, horizontal overflow, text truncation |
| Large mobile | 428px | iPhone Pro Max / large Android | Same as above, catches tight-but-not-broken layouts |
| Tablet portrait | 768px | iPad portrait | Sidebar collapse behavior, grid reflow |
| Small laptop | 1366px | Most common laptop | Action buttons above fold, no dead space |
| Desktop | 1920px | Standard monitor | Layout fills space, no extreme stretching |

### At Each Breakpoint, Verify

- [ ] No horizontal scrollbar appears (unless intentional, e.g., data tables)
- [ ] All text is readable without zooming (minimum 16px body text on mobile)
- [ ] Interactive elements are reachable without scrolling past the fold (especially
      submit buttons, primary actions)
- [ ] Touch targets meet minimum size (24x24px AA, 44x44px AAA) on mobile/tablet
- [ ] Images and media scale without overflow or distortion
- [ ] Navigation is accessible (hamburger menu works on mobile, sidebar visible on desktop)
- [ ] Modals and overlays don't overflow the viewport
- [ ] Scroll containers scroll smoothly and have visible scroll affordances
- [ ] No content is clipped by `overflow: hidden` (compare against static review findings)
- [ ] Form inputs are usable (labels visible, fields not too narrow to type in)

Record each breakpoint result in the review report's Viewport Verification Checklist
section, converting checkboxes to pass/fail with notes on any discrepancies from the
static analysis predictions.

## Browser Console Log Analysis

Visual bugs often have corresponding console warnings or errors that point to the root
cause. Check the browser console as part of runtime verification.

### What to Look For

1. **Layout-related warnings:**
   - `ResizeObserver loop limit exceeded` — often indicates a resize-triggered re-render
     loop; can cause jank or layout instability
   - Image dimension warnings (missing `width`/`height` attributes causing layout shift)
   - Font loading failures (FOUT/FOIT causing text reflow)

2. **React/framework-specific warnings:**
   - `Warning: Each child in a list should have a unique "key" prop` — can cause
     unexpected re-renders that affect visual state
   - Hydration mismatch warnings (SSR) — server and client rendering different layouts
   - `Warning: validateDOMNesting` — invalid HTML nesting that may cause browser layout
     quirks

3. **CSS-related errors:**
   - Failed asset loads (404 for stylesheets, fonts, images) — broken visual elements
   - CORS errors on font or stylesheet loads

4. **Performance indicators visible in console:**
   - Layout thrashing warnings (if using performance monitoring)
   - Long task warnings

### Procedure

1. Open DevTools Console before loading the page (to catch warnings during initial render)
2. Clear console, reload the page, note any warnings or errors
3. Perform the key interactions identified above (open modals, submit forms, resize)
4. Note any new console output after each interaction
5. Cross-reference console findings with static review issues — console errors often
   confirm suspected layout problems

Include console findings in the review report under a "Console Analysis" subsection.

## Visual Regression Detection

When modifying existing UI (not building new), compare the current state against a
baseline to catch unintended changes. This is most valuable when fixing issues found
during static review — confirming the fix works without breaking adjacent elements.

### Manual Workflow (no tooling required)

1. Before making changes, capture baseline screenshots at all breakpoints
2. Implement the fixes
3. Capture new screenshots at the same breakpoints and states
4. Compare side-by-side: verify the fix resolved the issue and no new regressions appeared
5. Pay special attention to:
   - Adjacent components (did fixing one element shift its neighbors?)
   - Different breakpoints (did a mobile fix break the desktop layout?)
   - Interaction states (did the fix hold up when modals open, content loads, etc.?)

### Automated Workflow (when project has visual regression tooling)

If the project uses a visual regression tool (Playwright visual comparisons, Percy,
Chromatic, BackstopJS), integrate with the existing workflow:

1. Run the baseline snapshot suite before changes
2. Implement fixes
3. Run the snapshot suite again
4. Review the diff report — approve intentional changes, investigate unexpected diffs
5. Update baseline snapshots for approved changes

### When to Add Visual Regression Tooling (recommendation, not requirement)

Consider recommending visual regression setup when:

- The project has >5 pages or >10 distinct components
- UI changes are frequent (multiple PRs per week touching visual code)
- The team has experienced "fix one thing, break another" visual regressions
- The project already uses Playwright or Cypress for E2E tests (low marginal cost to add)

## Runtime Verification in the Review Report

When runtime verification is performed, extend the main report with:

```
## Runtime Verification Results

**Dev server:** [command used to start]
**Browser:** [browser and version]
**Verification mode:** [manual | automated | hybrid]

### Cross-Resolution Results

| Breakpoint | Status | Issues Found | Static Review Match? |
|-----------|--------|-------------|---------------------|
| 360px mobile | PASS/FAIL | [description] | [confirmed/new/contradicted] |
| 768px tablet | PASS/FAIL | [description] | [confirmed/new/contradicted] |
| 1366px laptop | PASS/FAIL | [description] | [confirmed/new/contradicted] |
| 1920px desktop | PASS/FAIL | [description] | [confirmed/new/contradicted] |

### Console Analysis

[List of console warnings/errors found and their relevance to visual issues]

### Visual Regression Summary

[If applicable: list of before/after comparisons, regressions found, regressions avoided]

### Runtime vs. Static Analysis Reconciliation

- **Confirmed by runtime:** [issues predicted by static analysis and verified in browser]
- **New issues (runtime only):** [issues not caught by static analysis]
- **False positives (static only):** [issues predicted by static analysis but not present]
```

The "Static Review Match?" column and the reconciliation section are important for
calibrating the static analysis. Over time, patterns that consistently produce false
positives or false negatives in static analysis should inform updates to the main
checklist.
