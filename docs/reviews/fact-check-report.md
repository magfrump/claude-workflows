# Fact-Check Report: UI Visual Review Skill

**Draft:** skills/ui-visual-review.md (proposed)
**Date:** 2026-04-03
**Total claims checked:** 9
**Summary:** 4 accurate, 2 mostly accurate, 2 disputed, 0 inaccurate, 0 unverified

---

## Claims Checked

### Claim 1: Windows 98 scroll bars were always visible when content overflows
> "Scroll bars are always visible when content overflows."

**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** In Windows 98, scroll bars appeared automatically when window content exceeded the visible area — "at the right side or the bottom of a window when all of the information in that window cannot be seen at the same time." The behavior was technically "auto" (appear when needed) rather than "always visible regardless," but scroll bars were never hidden when content did overflow. The key contrast with modern UIs (where scroll bars may be hidden even when content overflows, as on macOS) is valid and is the real point being made.
**Source:** [GCFGlobal Windows 98 Tutorial](https://edu.gcfglobal.org/en/windows98/moving-and-sizing-windows/1/), [98.css design system](https://jdan.github.io/98.css/)

---

### Claim 2: Windows 98 buttons had borders, backgrounds, and hover/active states
> "Buttons look like buttons. They have borders, backgrounds, and hover/active states."

**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** Windows 98 buttons had strong visible affordances — 3D beveled borders and distinct backgrounds that made them look "pushable." The active (pressed) state was prominent. However, hover states were not a standard feature of Windows 98 buttons; hover highlighting became more prominent in Windows XP and later. The claim about borders and backgrounds is accurate; including "hover states" as a Windows 98-era characteristic is slightly anachronistic.
**Source:** [98.css design system](https://jdan.github.io/98.css/), [Microsoft Windows Interface Guidelines (PDF)](https://ics.uci.edu/~kobsa/courses/ICS104/course-notes/Microsoft_WindowsGuidelines.pdf)

---

### Claim 3: Apple Human Interface Guidelines cover layout and sizing principles
> "Apple Human Interface Guidelines (for layout and sizing principles)"

**Verdict:** Accurate
**Confidence:** High
**Evidence:** Apple's Human Interface Guidelines have dedicated sections on layout, including guidance on safe areas, adaptive layouts using size classes, minimum touch targets (44pt), and responsive text sizing.
**Source:** [Apple HIG - Layout](https://developer.apple.com/design/human-interface-guidelines/layout)

---

### Claim 4: Google Material Design covers responsive breakpoints and touch targets
> "Google Material Design (for responsive breakpoints and touch targets)"

**Verdict:** Accurate
**Confidence:** High
**Evidence:** Material Design defines responsive breakpoints at 480, 600, 840, 960, 1280, 1440, and 1600dp, and specifies minimum touch target sizing (48dp in Material Design 2/3).
**Source:** [Material Design Responsive UI](https://m1.material.io/layout/responsive-ui.html), [Material Design 3 Layout](https://m3.material.io/foundations/layout/understanding-layout/overview)

---

### Claim 5: MDN Web Docs covers CSS property behavior and browser compatibility
> "MDN Web Docs (for CSS property behavior and browser compatibility)"

**Verdict:** Accurate
**Confidence:** High
**Evidence:** MDN provides detailed documentation for every CSS property including syntax, behavior, examples, and browser compatibility tables sourced from the browser-compat-data project (over 15,000 features tracked).
**Source:** [MDN Browser Compatibility Data](https://developer.mozilla.org/en-US/docs/MDN/Writing_guidelines/Page_structures/Compatibility_tables)

---

### Claim 6: Viewport categories — small mobile 320px-480px, tablet 768px-1024px, large desktop 1440px+
> "Small mobile (320px-480px wide) / Tablet/small laptop (768px-1024px wide) / Large desktop (1440px+ wide)"

**Verdict:** Accurate
**Confidence:** High
**Evidence:** These ranges align with industry-standard responsive breakpoints. Common mobile breakpoints are 320px-480px, tablet breakpoints are 768px-1024px, and large desktop starts at 1280px-1440px. Bootstrap uses similar ranges (sm: 576px, md: 768px, lg: 992px, xl: 1200px). The draft's ranges are reasonable and consistent with widely used frameworks.
**Source:** [BrowserStack Responsive Design Breakpoints](https://www.browserstack.com/guide/responsive-design-breakpoints), [Bootstrap Breakpoints](https://getbootstrap.com/docs/5.0/layout/breakpoints/)

---

### Claim 7: 1024x768 as "minimum supported" resolution
> "1024x768 (minimum supported): all action buttons visible without scrolling"

**Verdict:** Disputed
**Confidence:** Medium
**Evidence:** 1024x768 was historically a common minimum design target but is no longer standard for desktop web design. As of 2025, the most common desktop resolution is 1920x1080 (24%), followed by 1536x864 (11%) and 1366x768 (10%). 1024x768 does not appear in the top desktop resolutions. It remains relevant for tablets in landscape mode, but calling it "minimum supported" without qualification is outdated. Whether this is appropriate depends on the specific project's audience — for internal tools or kiosk applications it may be reasonable — but the draft presents it as a general guideline.
**Source:** [StatCounter Screen Resolution Stats](https://gs.statcounter.com/screen-resolution-stats/desktop/worldwide), [BrowserStack Common Screen Resolutions 2026](https://www.browserstack.com/guide/common-screen-resolutions)

---

### Claim 8: 1440x900 as "typical laptop" resolution
> "1440x900 (typical laptop): layout fills space without excessive whitespace"

**Verdict:** Disputed
**Confidence:** Medium
**Evidence:** As of March 2025, 1440x900 accounts for only ~4% of desktop screen resolutions worldwide. The most common laptop resolutions are 1920x1080, 1536x864, and 1366x768. Calling 1440x900 "typical laptop" is misleading — it is a legacy resolution associated with older MacBook Airs and mid-range monitors. A more typical laptop resolution today would be 1366x768 or 1920x1080.
**Source:** [StatCounter Screen Resolution Stats](https://gs.statcounter.com/screen-resolution-stats/desktop/worldwide), [BrowserStack Common Screen Resolutions 2026](https://www.browserstack.com/guide/common-screen-resolutions)

---

### Claim 9: CSS vendor prefix requirement
> "You MUST NOT introduce CSS that requires vendor prefixes without noting which browsers need them."

**Verdict:** Accurate (as a practice recommendation)
**Confidence:** High
**Evidence:** While most CSS properties no longer need vendor prefixes, some (e.g., `-webkit-appearance`, `-webkit-text-stroke`) still require them. A 2026 CSS audit found the median website still has 140 vendor-prefixed properties, many unnecessary. Documenting which browsers need prefixes is sound practice, aligned with the recommendation to use tools like Autoprefixer rather than hand-authoring prefixes.
**Source:** [Vendor Prefixes in 2026 - Max Glenister](https://blog.omgmog.net/post/why-vendor-prefixes-are-still-in-your-css/), [MDN Vendor Prefix Glossary](https://developer.mozilla.org/en-US/docs/Glossary/Vendor_Prefix)

---

## Claims Requiring Author Attention

1. **Claim 2 (Mostly accurate):** Windows 98 buttons did not have prominent hover states. Consider changing "hover/active states" to just "active states" or "press states" to be historically accurate for the Windows 98 era.

2. **Claim 7 (Disputed):** 1024x768 is no longer a standard "minimum supported" resolution for general web design. Consider updating to 1280x720 or 1366x768 as the minimum, or qualifying the 1024x768 target as applicable to specific use cases (tablets, legacy hardware).

3. **Claim 8 (Disputed):** 1440x900 is not a "typical laptop" resolution by current statistics. Consider updating to 1366x768 (budget laptops) or 1920x1080 (standard laptops), or relabeling this breakpoint.
