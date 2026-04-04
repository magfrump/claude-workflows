# Draft Verification Rubric

**Draft:** skills/ui-visual-review.md | **Checked:** 2026-04-03 | **Status: 🟡 CONDITIONAL PASS** — 0 red items, 7 amber items awaiting resolution or justification

---

## 🔴 Must Fix

No factual claims were rated Inaccurate. Nothing in this tier.

---

## 🟡 Must Address

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | Viewport checklist uses wrong resolutions: 1024x768 (~0% share), 1440x900 (~4% share). Should use 1366x768 / 1920x1080 / 320-480px mobile | Fact-check (Disputed) + Both critics | 🟡 Open | — |
| A2 | Windows 98 framing is counterproductive — same principles grounded in WCAG 2.2 / NNGroup / European Accessibility Act would be harder to dismiss and more professionally authoritative | Both critics + HCI research | 🟡 Open | — |
| A3 | Mandatory web searches for every issue type burn token budget on things the agent already knows. Should be "search when uncertain" or when no project-local guidelines exist | Both critics | 🟡 Open | — |
| A4 | Skill bundles objective bug-finding (checklist) with subjective aesthetic preference (Win98 philosophy) — objective findings get discounted when packaged with design opinions teams may not share | Both critics | 🟡 Open | — |
| A5 | "Test recommendations against three viewport scenarios" implies running a browser, but the agent reviews code. Rewrite as "reason about CSS behavior at these widths" | Both critics | 🟡 Open | — |
| A6 | Win98 buttons claim lists "hover/active states" — Win98 had active states but not hover highlighting (became standard in XP) | Fact-check (Mostly accurate) | 🟡 Open | — |
| A7 | Skill conflates "visible affordance" with "discoverability" — progressive disclosure, tooltips, consistent placement are also discoverability techniques the skill ignores | Cowen critique + HCI research (UXPin) | 🟡 Open | — |

---

## 🟢 Consider

| # | Idea | Source |
|---|---|---|
| C1 | Explicitly scope the classic-affordance preference to "tool-like web applications" rather than claiming universality — enterprise design systems agree, consumer ones don't | Cowen critique |
| C2 | Add `scrollbar-gutter: stable` as a recommended CSS pattern — addresses layout shift from scrollbar appearance without requiring always-visible scrollbars | HCI web research |
| C3 | The strongest accessibility argument is "redesign to avoid overflow" rather than "make overflow visible" — consider adding as a principle above "make scroll bars visible" | HCI web research (Cerovac) |
| C4 | The governance structure (project-local guidelines as primary authority) is the skill's best design decision — consider promoting it from buried in a numbered list to a prominent position | Cowen critique (revealed preferences) |
| C5 | At scale, mandatory searches become redundant (same MDN articles fetched repeatedly). Consider a "search once, apply to all similar issues" pattern | Yglesias critique |
| C6 | Building code analogy: the skill proposes safety minimums but risks turning them into a ceiling — leave room for design quality above the minimum | Cowen critique |
| C7 | The skill is swimming with a regulatory current (WCAG 2.2, European Accessibility Act) it doesn't seem aware of — citing these transforms "retro preference" into "regulatory compliance" | Cowen critique + HCI research |
| C8 | Neo-skeuomorphism / semi-flat design is the HCI-recommended middle ground — selective depth signals rather than full Windows 98 chrome | HCI research (IJRISS paper) |

---

## Verified ✅

| Claim | Verdict |
|---|---|
| Apple Human Interface Guidelines cover layout and sizing principles | ✅ Accurate |
| Google Material Design covers responsive breakpoints and touch targets | ✅ Accurate |
| MDN Web Docs covers CSS property behavior and browser compatibility | ✅ Accurate |
| Responsive breakpoint ranges (320-480px mobile, 768-1024px tablet, 1440px+ desktop) | ✅ Accurate |
| CSS vendor prefix documentation recommendation | ✅ Accurate |
| Windows 98 scroll bars appeared when content overflowed (not hidden like macOS) | ✅ Mostly accurate (auto, not unconditional, but never hidden when needed) |

---

To pass verification: all 🟡 items must be either fixed or carry an author note explaining why they stand as-is. 🟢 items are optional but recommended.
