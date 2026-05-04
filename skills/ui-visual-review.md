---
name: ui-visual-review
description: >
  Review and fix visual/layout issues in UI code (web or native), with a focus on cross-resolution
  compatibility, scrollability, overflow handling, and robust sizing. Validates recommendations
  against accessibility standards (WCAG 2.2), usability research (NNGroup), and platform UI
  guidance. Use this skill when the user reports visual elements that are cut off,
  overlapping, invisible at certain resolutions, or otherwise broken across screen sizes. Also
  trigger when the user asks to "fix the layout", "make this responsive", "review the UI",
  "check visual elements", or "audit the CSS". Applies to any framework with visual elements:
  React/JSX/TSX with Tailwind or CSS-in-JS, Unity/C# UI, Vue, Svelte, etc. Also covers 3D
  viewport rendering (three.js, react-three-fiber, Babylon, model-viewer, Unity WebGL,
  Unreal Pixel Streaming, .glb/.gltf assets) — see Step 2 item 8. Produces concrete
  code fixes plus a structured report of findings. NOTE: This skill can be invoked standalone
  or by a code-review orchestrator. If a code-fact-check report is provided, use it as your
  foundation for understanding what the code actually does and do not re-verify documented
  behavior.
when: User asks to review, audit, or fix visual/layout issues in UI code, or diff touches UI rendering code
requires:
  - name: code-fact-check
    description: >
      A code fact-check report covering claims in comments, docstrings, and documentation
      against actual code behavior. Typically produced by the code-fact-check skill. Without
      this input, the UI visual review proceeds on code analysis only — comments about layout
      behavior are not independently verified.
---

> On bad output, see guides/skill-recovery.md

# UI Visual Review

You review UI code for visual and layout problems — elements that disappear, overflow,
overlap, or become unusable at different screen sizes. You produce concrete fixes grounded in
accessibility standards and usability research. The core principles (overflow handling, control
placement, sizing, affordance) apply across frameworks — React/JSX/TSX, Unity/C#, Vue, Svelte,
native mobile, etc. — though most examples below use web/Tailwind conventions. For non-web
frameworks, adapt the patterns to the equivalent layout system (e.g., Unity's RectTransform
and LayoutGroup, SwiftUI's GeometryReader).

Your primary job is **mechanical bug-finding**: catching CSS and layout patterns that break at
different viewport sizes. This is objective work — does this layout break? — and it is the
core value of this skill. The checklist in Step 2 is your main tool.

Your secondary job, when relevant, is **affordance review**: checking that interactive elements
are discoverable and distinguishable. This work is grounded in:

- **WCAG 2.2** — visible focus indicators (2.4.7), focus not obscured (2.4.11),
  focus appearance (2.4.13, Level AAA), minimum target sizes (2.5.8),
  content reflow (1.4.10)
- **NNGroup research** — flat UI elements with weak signifiers require more user effort;
  interactive elements must be visually distinguishable from static content
- **European Accessibility Act (2025)** — EU law requiring digital accessibility via
  EN 301 549 / WCAG 2.1 AA, covering perceivable, operable, and understandable interfaces

The guiding principle: **users should never have to guess** whether they can scroll, click,
or interact with an element. When minimalist aesthetics conflict with discoverability, prefer
discoverability — especially in tool-like web applications where task completion matters more
than first impressions.

---

## Mandatory Execution Rules

1. **Project-local guidelines are your primary authority.** Before doing anything else, check
   for a project-local UI guidelines document (e.g., `docs/UI_LAYOUT_GUIDELINES.md`). If one
   exists, it captures patterns already validated in this codebase — follow it. Everything
   below fills gaps where the project has no guidance.

2. You MUST NOT recommend solutions that hide content or affordances. If content overflows,
   make the overflow visible and scrollable — do not clip it silently.

3. You MUST reason about your recommendations at three viewport widths:
   - Small mobile (320px–480px)
   - Tablet/small laptop (768px–1024px)
   - Large desktop (1920px+)

   Note: you are reviewing code, not running a browser. "Reason about" means analyzing the
   CSS to determine what will happen at each width, not visually testing.

4. You MUST NOT introduce CSS that requires vendor prefixes without noting which browsers
   need them.

5. **Search the web when uncertain** — not for every issue. For well-understood CSS patterns
   (flex overflow, scroll containers, positioning), your training data is sufficient. Search
   when you encounter unfamiliar properties, need to check browser compatibility for newer
   CSS features, or when the project lacks local guidelines. When you do search, prioritize:
   - MDN Web Docs (CSS property behavior and browser compatibility)
   - WCAG 2.2 guidelines (accessibility requirements)
   - Apple Human Interface Guidelines / Google Material Design (layout and sizing)
   - NNGroup articles (usability research)

---

## Step 1: Determine Scope

Ask the user or infer from context:
- Which files contain the UI code to review? (HTML, CSS, JSX/TSX, Vue, Svelte, C#/Unity, etc.)
- Is there a specific visual problem reported, or is this a general audit?
- What is the target platform? (Default for web: modern evergreen browsers + mobile Safari.
  For Unity: target resolutions from player settings. For native: platform design guidelines.)

If the user points to a specific problem (e.g., "the sidebar disappears on small screens"),
focus there first, then scan for related issues in the same component tree.

If this is a general audit, read all relevant layout and styling files.

---

## Review Modes

This skill operates in two modes. The mode determines which checklist items to run.

**Mechanical review (default)** — Runs checklist items 1-5 only. These are objective layout
bug checks with clear right/wrong answers. This is the default when triggered by the
code-review orchestrator or when reviewing a specific diff. No web search unless genuinely
uncertain about a CSS property. Fast and low-noise.

**Full audit** — Runs all checklist items (1-7), including affordance review and responsive/
cross-browser checks. Use this mode when the user explicitly asks for a "UI audit", "review
the UI", "check accessibility", or "audit the CSS". Also use when the user reports a
discoverability or affordance problem specifically.

The mode split exists because items 1-5 are mechanical pattern-matching where AI agents are
reliably accurate, while items 6-7 involve subjective judgment that can generate false
positives in projects using modern component libraries. Bundling both by default risks noise
that causes developers to disable the tool entirely.

**Runtime verification (Step 6)** — an optional add-on to either mode. When the project is a
web application with a runnable dev server, Step 6 validates static analysis findings in an
actual browser. This catches issues that code analysis alone misses (e.g., font rendering,
actual scrollbar behavior, runtime-injected styles). Activate when the user says "test in
browser", "check it visually", "run the app and verify", or when the project has browser
automation tooling available.

---

## Step 2: Read the Code

Read the relevant files completely. Look for the following issues, ordered by how frequently
they cause real bugs:

### 1. Unbounded content without scroll caps (most common)
- Containers whose children can grow without limit (lists, error output, file uploads) but
  lack a `max-h-*` constraint + `overflow-auto`
- `overflow: hidden` that silently clips content — should usually be `overflow: auto` or
  `overflow-y: auto` with visible scroll indicators
- Missing `max-width` or `max-height` constraints on images or media

Example fix pattern:
```tsx
// Modal or overlay — cap at viewport percentage
<div className="max-h-[85vh] flex flex-col">
  <div className="shrink-0">Header</div>
  <div className="overflow-y-auto">Scrollable content</div>
</div>
```

### 2. Controls trapped inside scroll containers
- Buttons, toggles, or action bars inside an `overflow-auto` container — they scroll away
  and become inaccessible
- Fix: use a two-layer structure with controls pinned outside the scroll region

```tsx
// WRONG: button scrolls away
<div className="overflow-auto">
  {longContent}
  <button>Submit</button>
</div>

// CORRECT: docked footer pattern
<div className="flex flex-1 min-h-0 flex-col overflow-hidden">
  <div className="flex-1 min-h-0 overflow-auto p-6">{longContent}</div>
  <div className="shrink-0 border-t px-4 py-3">
    <button>Submit</button>
  </div>
</div>
```

### 3. Wrong `shrink-0` vs `flex-1 min-h-0` usage
- **`shrink-0`** — sizes to content, never shrinks. For: headers, footers, control bars, buttons.
- **`flex-1 min-h-0`** — fills remaining space. For: content areas, editors, scrollable regions.
- Mixing these up causes layout stretch (content area given `shrink-0`) or collapse
  (header given `flex-1`)

Ask for each element: "Should this size to its content or fill available space?"

### 4. Absolute positioning anchored to wrong parent
- An `absolute`-positioned element attaches to its nearest `relative` ancestor
- When multiple sections exist side-by-side, verify the element is inside the correct section
- Common bug: floating bar in outer div overlaps all sections instead of just its target
- Unity equivalent: a RectTransform anchored to the wrong parent Canvas or Panel, causing
  elements to scale or position relative to the full screen instead of their intended container

### 5. Excessive vertical spacing
- Padding and gaps that waste vertical space, pushing controls below the fold on small viewports
- Prefer compact defaults: `p-4` over `p-6`, `gap-3` over `gap-4`, `rows={3}` over `rows={8}`
- Test: at `1366x768` viewport, are action buttons visible without scrolling?

### 6. Visibility and affordance *(full audit mode only)*
- Interactive elements that look like static text (missing cursor, border, or background)
- Controls that disappear after completion (`{status !== "done" && <button>}`) — should
  update label instead (`status === "done" ? "Re-run" : "Run"`)
- Scroll indicators that only appear on hover (not discoverable on touch devices)
- Form inputs without visible borders (indistinguishable from labels)
- Disabled states that are invisible or insufficiently dimmed
- Missing focus indicators for keyboard navigation (WCAG 2.4.7; 2.4.13 Level AAA)
- Touch targets smaller than minimum sizes (WCAG 2.5.8: 24x24px minimum Level AA;
  WCAG 2.5.5: 44x44px Level AAA)

Note: discoverability is not only about making elements visible. Also consider:
- **Progressive disclosure** — showing controls in context when relevant, rather than
  displaying everything at once (which creates its own discoverability problem through clutter)
- **Consistent placement** — controls that appear in predictable locations are more
  discoverable than prominently styled controls in unexpected places
- **Redesigning to avoid overflow** — the best scroll bar is one you don't need. Before
  adding scroll indicators, ask whether the layout can be restructured to fit the content

### 7. Responsive and cross-browser concerns *(full audit mode only)*
- Fixed dimensions (`width: 500px`) that won't adapt to viewport changes
- Missing viewport meta tag
- Media queries that leave gaps between breakpoints
- Text that doesn't reflow on narrow viewports (missing `overflow-wrap: break-word`)
- CSS properties with incomplete browser support (check via web search when relevant)

### 8. 3D viewport rendering *(when 3D content is present)*

**Activation trigger.** Run this section when the diff or scope includes any of:
- TSX/JSX containing `three`, `@react-three/fiber`, `babylonjs` / `@babylonjs/core`,
  `<model-viewer>`, or a `<canvas>` paired with WebGL/WebGPU context creation
  (`getContext('webgl'|'webgl2'|'webgpu')`)
- Unity WebGL builds (e.g., `Build/UnityLoader.js`, `unityInstance`, a `#unity-canvas` host)
  or Unreal Pixel Streaming pages (`PixelStreaming` client, signaling-server URLs)
- `.glb` or `.gltf` URL references in code, configs, or asset manifests

3D viewports fail in ways that the 2D layout checklist does not catch. The model can be
loaded, the canvas can be sized correctly, and the page can still appear blank or wrong.
The checks below are mechanical pattern checks against the rendering setup; runtime
verification (Step 6) is strongly recommended for 3D content because static analysis cannot
predict whether the camera ends up framing the model.

- **Camera controls (orbit/pan/zoom respond, no gimbal lock).** Verify the chosen controls
  module receives the actual canvas DOM element, not the window or a wrapper div
  (`new OrbitControls(camera, canvas)` for three.js; `scene.activeCamera.attachControl(canvas)`
  for Babylon). If the render loop uses `requestAnimationFrame`, `controls.update()` must be
  called inside it for damped controls to respond. Watch for orbit code that integrates Euler
  angles directly — at pitch ±90° this hits gimbal lock and pan/zoom can stop working at
  certain orientations. Prefer quaternion or spherical-coordinate orbit math; built-in
  `OrbitControls` already does this correctly.

- **Clipping plane behavior (near/far cull doesn't crop expected geometry).** Inspect
  `camera.near` and `camera.far`. Three.js defaults of `0.1` / `2000` (or Babylon's `1` /
  `10000`) clip large architectural models from the back and tiny inspection models from
  the front. After loading an asset, compute its bounding box and size the planes to it
  (e.g., `near = bbox.diagonal * 0.001`, `far = bbox.diagonal * 100`). Symptom of a too-tight
  far plane: the back of the model disappears as the camera dollies out. Symptom of a too-
  loose near plane: small parts vanish when the camera gets close, or z-fighting on
  coplanar faces from depth buffer precision loss.

- **Lighting adequacy (subject not silhouetted on dark background).** A scene that uses
  only `MeshStandardMaterial` / `MeshPhysicalMaterial` (or Babylon's `PBRMaterial`) with no
  lights renders as solid black. A dark subject on `scene.background = black` renders as
  invisible. Verify at least one directional or point light is added to the scene, or the
  material is explicitly unlit (`MeshBasicMaterial`, `unlit` extension on glTF). Check
  contrast between the subject's expected color range and `scene.background` /
  `renderer.setClearColor`. For HDR/IBL setups, confirm the environment map actually loaded
  (loader errors are silent — the scene just goes dark).

- **Transparency and depth ordering.** Translucent meshes need `material.transparent = true`
  and the renderer's transparency-sort pass; opaque meshes should not have `transparent: true`
  (it disables the depth-write fast path and causes flicker). Common bugs: a transparent UI
  plane renders behind opaque scene geometry because of default `renderOrder`; cutout
  textures (foliage, decals) show square outlines because `alphaTest` is missing — set
  `material.alphaTest = 0.5` (or comparable) for binary cutouts. For order-dependent
  effects (glass, particles), check `depthWrite` is `false` on the transparent layer and
  `renderOrder` is set explicitly.

- **Gizmo presence and orientation when relevant.** When the viewport is an editor / debug
  view (transform gizmos, axis helpers, grid, bone overlays, bounding-box wireframes),
  verify the helpers are added to the scene and are oriented in the expected handedness
  (three.js: right-handed, X=red right, Y=green up, Z=blue toward camera; Unity / Unreal:
  left-handed; glTF assets are right-handed Y-up). A gizmo that draws but is occluded by
  the model usually wants `depthTest = false` and a high `renderOrder` so it stays on top.
  If the user reports "I can see the model but can't grab the handles," check whether the
  raycaster is being intersected with the helpers layer (some setups exclude helpers from
  picking by default).

- **Asset bounds vs. viewport (model not centered, larger than far-clip).** After load,
  compute the model's bounding box and verify (a) it is finite (a NaN or zero-extent box
  means the loader returned an empty scene), (b) the camera's distance is sized to it
  (`distance ≈ bbox.diagonal * 1.5` is a reasonable default), and (c) the model is
  re-centered if the artist exported it offset from origin (`model.position.sub(bbox.center)`).
  Without an explicit framing pass, models commonly load off-camera (you see a black canvas
  but the model is rendering 50 units to the side) or too small to see (camera at default
  `(0,0,5)`, model is 0.001 units across). Models larger than `camera.far` will be culled
  entirely — relink to the clipping-plane check above.

- **Runtime perf indicators (FPS / draw calls when overlay is present).** When the project
  surfaces a perf overlay (`stats.js`, r3f's `<Perf />`, Babylon Inspector, the Unity WebGL
  stats panel, Pixel Streaming's bitrate HUD), check that frame time stays under the
  project's stated target (16.7ms for 60fps desktop; 33.3ms for 30fps mobile) and that
  draw-call counts are not unexpectedly high — a model with N parts emitting N draw calls
  signals missing instancing or mesh merging. Do not fail a review purely because no perf
  overlay exists; flag missing instrumentation only when the project's stated goals
  (e.g., real-time rendering, mobile target) make perf material. When the overlay is
  visible in screenshots, include the FPS / draw-call values in the runtime verification
  results table.

Common 3D-viewport failure modes that look like "the page is broken":
- Black canvas → no lights, or background and material both dark, or model off-camera
- Single-color silhouette → unlit material with default color, or environment map failed
  to load
- Model "missing" but no console error → camera near/far culls it, or model is smaller/
  larger than the camera's framing assumes
- Controls dead → controls attached to wrong DOM element, or `controls.update()` missing
  from the loop, or Euler-based orbit hit gimbal lock

### 9. Accessibility serialization *(when HTML structure, ARIA, or content extraction changes)*

**Activation trigger.** Run this section when the diff touches HTML/JSX semantic structure
(headings `h1`–`h6`, landmarks like `<nav>`/`<main>`/`<aside>`/`<header>`/`<footer>`), ARIA
attributes (`aria-label`, `aria-labelledby`, `aria-describedby`, `role`), `alt` text on
images, or any code that extracts visible content for non-visual consumers (screen readers,
AI agents, summarization pipelines, RSS/Atom serializers).

The visible UI and the serialized accessibility tree are two views of the same content and
must agree. Check that ARIA labels reflect visible text — a button labeled "Submit" with
`aria-label="Cancel"` lies to screen readers and to any consumer reading the accessibility
tree. Every non-decorative image needs descriptive `alt` text; purely decorative images use
`alt=""` (empty, not missing — a missing `alt` makes screen readers fall back to the
filename). Semantic structure must be preserved through changes: don't swap `<h2>` for a
styled `<div>`, don't drop landmark elements, and keep heading levels sequential (no jumping
`<h2>` to `<h4>` for visual sizing). Tab/focus order must match visible reading order — flex
`order`, `flex-direction: row-reverse`, and absolute positioning can desynchronize them;
verify by tabbing through the modified component. Color must never be the sole signal:
error states need icons or text, required fields need asterisks or "(required)", status
changes need labels — not just a red border, green check, or color swap. This is a
lightweight equivalence check, not a full accessibility audit; for WCAG conformance review
use a dedicated accessibility skill.

### 10. Interactive element state matrix *(when diff touches interactive elements)*

**Activation trigger.** Run this section when the diff modifies markup or styles for
interactive elements: `<button>`, `<a>`, `<input>`, `<select>`, `<textarea>`, `<details>`,
custom interactive components (anything with `role="button"`, `role="link"`,
`role="checkbox"`, `role="switch"`, `role="tab"`, etc.), or styling that targets `:hover`,
`:focus`, `:focus-visible`, `:active`, `:disabled`, `[aria-invalid]`, or equivalent
class-based state selectors (`.is-active`, `.is-disabled`, `.has-error`). **Apply the
matrix only to elements actually changed in the diff** — do not audit untouched
interactive elements elsewhere in the file. PRs that touch only static markup
(paragraphs, headings, layout containers) skip this section entirely.

For each interactive element changed in the diff, verify all six states are defined and
convey the right meaning:

| State | What to verify | Common failure |
|-------|----------------|----------------|
| **Default** | Element looks interactive (border, background, or cursor signals affordance — see item 6); non-text contrast meets WCAG 1.4.11 (3:1 against adjacent colors) | Borderless input indistinguishable from a label; flat button mistaken for static text |
| **Hover** | Visible style change distinct from default; never the *only* affordance, since keyboard-only and touch users won't see it | Hover-only scroll indicators or action buttons; hover styles missing entirely |
| **Focus** | Visible focus ring (WCAG 2.4.7); minimum area and ≥3:1 contrast against both element and adjacent colors (WCAG 2.4.13 Level AAA); not obscured by sticky headers/footers (WCAG 2.4.11). Prefer `:focus-visible` over `:focus` so mouse users don't see rings on click | `outline: none` without replacement; focus ring same color as background; focus hidden behind a sticky toolbar |
| **Active** | Pressed/clicked feedback distinct from hover and default; signals "I received your click" before the action completes. Note: CSS `:active` means *currently being pressed*, not "currently selected" or "current page" — those use `aria-current` or class-based state | Active state visually identical to default — user re-clicks; `:active` confused with selected state |
| **Disabled** | Visibly disabled (reduced opacity or grayscale shift, plus `cursor: not-allowed`); the `disabled` attribute or `aria-disabled="true"` is set so the accessibility tree agrees with the visual; disabled controls remain perceivable (≥3:1 contrast for the icon/text per WCAG 1.4.11 is recommended though not strictly required for disabled controls) | Disabled buttons that look enabled; `pointer-events: none` without any visual change; styled-disabled with no `aria-disabled` |
| **Error** | Error is signaled through icon + text, not color alone (WCAG 1.4.1); `aria-invalid="true"` is set on the field and `aria-describedby` links to the error message so screen readers announce it | Red border as sole error signal — invisible to colorblind users and absent from the accessibility tree |

Cross-references: item 6 covers the underlying affordance principles; the *Affordance
Principles Reference* section near the end of this skill lists the WCAG citations in full.
This section is the diff-scoped, per-element matrix that ensures the principles are
applied to the specific elements being changed.

For static analysis, verify the relevant CSS rules / className variants exist for each
state the element needs. For runtime confirmation that hover/active/error styles actually
fire under interaction, defer to Step 6 (runtime verification) when available — static
analysis cannot predict whether a CSS class actually triggers under user input.

---

## Step 3: Research When Uncertain

You do not need to search for every issue. For well-understood CSS patterns (flex overflow,
scroll containers, positioning ancestry), apply your knowledge directly.

**Search the web when:**
- You encounter a CSS property or browser behavior you're unsure about
- You need to verify browser compatibility for newer features (e.g., `scrollbar-gutter`,
  container queries, `dvh` units)
- The project lacks local guidelines and you need to determine current best practices for
  a specific pattern
- You're unsure whether a recommendation aligns with WCAG 2.2 requirements

**When you do search, prioritize:**
1. **MDN Web Docs** — CSS property behavior, browser compatibility tables
2. **WCAG 2.2 specification** — accessibility requirements
3. **Can I Use** — browser support data
4. **NNGroup articles** — usability research on specific patterns

When you find conflicting guidance (e.g., "always show scroll bars" vs. "auto-hide"), note
both perspectives and recommend the more discoverable option, citing the accessibility or
usability rationale.

---

## Step 4: Produce Fixes

For each issue found, provide:

1. **The problem** — what's wrong and when it manifests (which viewport sizes, which browsers)
2. **The evidence** — what best practice or guideline supports the fix (cite the source)
3. **The fix** — exact code changes, using Edit-style before/after blocks
4. **The tradeoff** — if the fix has any downsides (e.g., "always-visible scrollbars take up
   ~15px of horizontal space"), state them honestly

Group fixes by severity:
- **Critical** — Content is inaccessible or invisible at common viewport sizes
- **Major** — Content is accessible but hard to discover or use
- **Minor** — Cosmetic issues or suboptimal patterns that work but could be better

---

## Step 5: Produce the Report

Write a structured Markdown report:

```
# UI Visual Review: [Component/Page Name]

## Summary

[1-3 sentence overview: what was reviewed, how many issues found, overall assessment]

## Environment

- **Files reviewed:** [list]
- **Target viewports:** [small/medium/large or specific breakpoints]
- **Target browsers:** [list]

## Critical Issues

### [Issue title]

**Problem:** [description]
**Viewport:** [which sizes are affected]
**Best practice:** [source and recommendation]
**Fix:**
\`\`\`css
/* Before */
[old code]

/* After */
[new code]
\`\`\`
**Tradeoff:** [any downsides]

## Major Issues

[same format]

## Minor Issues

[same format]

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| [e.g., Visible scroll affordances] | [e.g., NNGroup, WCAG 1.4.10] | [e.g., Changed overflow:hidden to overflow:auto with visible scrollbar] |

## Viewport Verification Checklist

- [ ] 360px mobile: content reachable, no horizontal overflow, touch targets adequate
- [ ] 1366x768 (common laptop): all action buttons visible without scrolling
- [ ] 1920x1080 (standard desktop): layout fills space without excessive whitespace

## Post-Implementation Visual Fix Tracking

**Issues found after this review that required manual visual fixes:** [count]
**Issues caught by this review before they shipped:** [count]
```

---

## Step 6: Runtime Verification (Web Applications)

Steps 1–5 review code statically — analyzing CSS and layout logic to predict what will happen
at different viewport sizes. This step validates those predictions by running the application
in a browser. **This step is optional** and only applies when: (a) the project is a web
application with a runnable dev server, and (b) you have access to browser automation or
screenshot tools (Puppeteer, Playwright, Cypress, or manual browser access).

Skip this step if the project has no runnable frontend or if you are operating as a sub-critic
within the code-review orchestrator (where runtime access is typically unavailable).

### 6a. Screenshot Capture Procedures

Capture screenshots at each verification breakpoint to create a visual record of the current
state. This serves two purposes: documenting what the UI looks like *now* (for comparison
after future changes) and providing evidence for issues found in the static review.

**Procedure:**

1. Start the dev server (`npm run dev`, `yarn dev`, or project-equivalent)
2. Capture screenshots at each breakpoint defined in the cross-resolution checklist (6b)
3. For each page or component under review, capture:
   - Default state (page load, no interaction)
   - Key interaction states (modal open, dropdown expanded, form with validation errors,
     long content that triggers scroll)
   - Edge cases flagged during the static review (Steps 2–4)
4. Save screenshots to `docs/reviews/screenshots/` with naming convention:
   `{component}-{viewport}-{state}.png` (e.g., `sidebar-360px-collapsed.png`)

**Automation example (Playwright):**
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

**When doing this manually:** Use browser DevTools device toolbar to set exact viewport
dimensions. Take screenshots with the OS screenshot tool or DevTools capture. The key is
consistency — same viewports, same states, every time.

**3D viewport content** (Step 2 item 8): wait for the scene to stabilize before capturing.
Asset load is asynchronous, and the first frame typically renders before the model is in
the scene or before the camera-framing pass has run — the screenshot will show a blank
canvas that does not reflect the steady state. Wait for a load-complete signal
(`gltfLoader.load` callback, `<model-viewer load>` event, or a configurable `await
nextFrame()` after `scene.onReadyObservable`) and capture one or two frames after that.
For perf-overlay screenshots, let the FPS counter settle for ~2 seconds so the displayed
value reflects steady-state cost, not first-frame compile/upload spikes.

### 6b. Cross-Resolution Verification Checklist

Run through this checklist at each breakpoint. This is the runtime counterpart to the static
analysis in Step 2 — you are confirming (or refuting) what the code review predicted.

**Breakpoints:**

| Category | Width | Represents | Key concerns |
|----------|-------|-----------|--------------|
| Small mobile | 360px | Typical Android phone | Touch targets, horizontal overflow, text truncation |
| Large mobile | 428px | iPhone Pro Max / large Android | Same as above, catches tight-but-not-broken layouts |
| Tablet portrait | 768px | iPad portrait | Sidebar collapse behavior, grid reflow |
| Small laptop | 1366px | Most common laptop | Action buttons above fold, no dead space |
| Desktop | 1920px | Standard monitor | Layout fills space, no extreme stretching |

**At each breakpoint, verify:**

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

**Record each breakpoint result** in the review report (Step 5) under the
"Viewport Verification Checklist" section, converting checkboxes to pass/fail with notes
on any discrepancies from the static analysis predictions.

### 6c. Browser Console Log Analysis

Visual bugs often have corresponding console warnings or errors that point to the root cause.
Check the browser console as part of runtime verification.

**What to look for:**

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

**Procedure:**

1. Open DevTools Console before loading the page (to catch warnings during initial render)
2. Clear console, reload the page, note any warnings or errors
3. Perform the key interactions identified in 6a (open modals, submit forms, resize)
4. Note any new console output after each interaction
5. Cross-reference console findings with static review issues — console errors often confirm
   suspected layout problems

Include console findings in the review report under a "Console Analysis" subsection.

### 6d. Visual Regression Detection Workflow

When modifying existing UI (not building new), compare the current state against a baseline
to catch unintended changes. This is most valuable when fixing issues found in Steps 2–4 —
confirming the fix works without breaking adjacent elements.

**Manual workflow (no tooling required):**

1. Before making changes, capture baseline screenshots at all breakpoints (6a)
2. Implement the fixes from Step 4
3. Capture new screenshots at the same breakpoints and states
4. Compare side-by-side: verify the fix resolved the issue and no new regressions appeared
5. Pay special attention to:
   - Adjacent components (did fixing one element shift its neighbors?)
   - Different breakpoints (did a mobile fix break the desktop layout?)
   - Interaction states (did the fix hold up when modals open, content loads, etc.?)

**Automated workflow (when project has visual regression tooling):**

If the project uses a visual regression tool (Playwright visual comparisons, Percy,
Chromatic, BackstopJS), integrate with the existing workflow:

1. Run the baseline snapshot suite before changes
2. Implement fixes
3. Run the snapshot suite again
4. Review the diff report — approve intentional changes, investigate unexpected diffs
5. Update baseline snapshots for approved changes

**When to add visual regression tooling (recommendation, not requirement):**

Consider recommending visual regression setup when:
- The project has >5 pages or >10 distinct components
- UI changes are frequent (multiple PRs per week touching visual code)
- The team has experienced "fix one thing, break another" visual regressions
- The project already uses Playwright or Cypress for E2E tests (low marginal cost to add)

### Runtime Verification and the Review Report

When runtime verification is performed, extend the Step 5 report with:

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
positives or false negatives in static analysis should inform updates to the Step 2 checklist.

---

## Affordance Principles Reference

These principles are grounded in accessibility standards (WCAG 2.2), NNGroup usability
research, and the enduring lessons of desktop UI design. Use them as defaults when project
guidelines are silent and modern design-system guidance is ambiguous:

1. **Scroll indicators are visible** when content exceeds its container. The user should never
   have to guess whether more content exists. Use `overflow-y: auto` with visible scroll bars;
   consider `scrollbar-gutter: stable` to prevent layout shift when scroll bars appear/disappear.
   (NNGroup recommends visible scroll affordances when content is scrollable.)

2. **Interactive elements are visually distinct.** Buttons have borders, backgrounds, and
   active/pressed states that make them obviously clickable. (NNGroup: flat UI elements with
   weak signifiers require more user effort. WCAG 2.5.8: minimum target size 24x24px
   Level AA; WCAG 2.5.5: 44x44px Level AAA.)

3. **Form inputs have visible borders.** A borderless text field is indistinguishable from a
   label. (WCAG 1.4.11: non-text contrast — UI components must have 3:1 contrast against
   adjacent colors.)

4. **Menus and dropdowns have visible affordances** (arrows, chevrons) indicating they can be
   opened.

5. **Disabled elements are visibly disabled** — grayed out, not just slightly faded.

6. **Loading and progress states are communicated.** Never leave the user staring at a blank
   screen during a load. (WCAG 4.1.3: status messages must be programmatically determinable.)

7. **Focus indicators are obvious.** Keyboard users must always know which element is focused.
   (WCAG 2.4.7: focus visible. WCAG 2.4.13: focus appearance — minimum area and contrast,
   Level AAA.)

8. **Prefer redesigning layout over adding scroll.** If content can be restructured to fit
   without scrolling, that is better than a visible scroll bar. Scroll bars are a fallback,
   not a first choice.

When searching for guidance, include terms like "WCAG", "UI affordance", "visible feedback",
"discoverability" alongside the specific CSS or layout question.

---

## Suppressing Known Findings

When a project intentionally deviates from the checklist (e.g., borderless inputs as a design
choice, auto-hiding scrollbars per design system), findings will recur on every diff. To
prevent noise:

1. **Project-local guidelines** — the primary suppression mechanism. If
   `docs/UI_LAYOUT_GUIDELINES.md` (or equivalent) documents an intentional pattern, the skill
   respects it and does not flag it.
2. **Inline suppression comments** — if a component intentionally uses a pattern the checklist
   would flag, an inline comment like `// ui-review: intentional overflow-hidden` signals that
   this was a deliberate choice. Do not flag code with such comments.
3. **Report deduplication** — if a prior review report exists in `docs/reviews/` and a finding
   matches one already acknowledged by the author (status updated to "acknowledged" or
   "won't fix"), do not re-report it.
