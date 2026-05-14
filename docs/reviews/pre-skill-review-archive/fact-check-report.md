# Fact-Check Report: UI Visual Review Skill

**Draft author:** (skill document, no named author)
**Checked:** 2026-04-04
**Total claims checked:** 10
**Summary:** 6 accurate, 2 mostly accurate, 0 disputed, 1 inaccurate, 1 unverified

---

## Claim 1: "visible focus indicators (2.4.7, 2.4.11)"

The draft states that WCAG 2.2 criteria 2.4.7 and 2.4.11 concern "visible focus indicators."

**Verdict:** Inaccurate
**Confidence:** High

WCAG 2.4.7 (Focus Visible, Level AA) does concern visible focus indicators -- it requires that keyboard focus indicators are visible. However, WCAG 2.4.11 in the final WCAG 2.2 specification is "Focus Not Obscured (Minimum)" (Level AA), which requires that focused elements are not entirely hidden by author-created content. It is not about focus indicator appearance. The criterion the draft appears to mean is **2.4.13 (Focus Appearance)**, which was originally numbered 2.4.11 in earlier drafts but was renumbered to 2.4.13 and downgraded to Level AAA in the final WCAG 2.2 recommendation. The draft references 2.4.11 in three separate places as if it concerns focus appearance, which reflects the outdated draft numbering.

**Sources:**
- [W3C Understanding SC 2.4.7: Focus Visible](https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html)
- [W3C Understanding SC 2.4.11: Focus Not Obscured (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html)
- [W3C Understanding SC 2.4.13: Focus Appearance](https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html)

---

## Claim 2: "minimum target sizes (2.5.8)"

The draft references WCAG 2.5.8 for minimum target sizes.

**Verdict:** Accurate
**Confidence:** High

WCAG 2.5.8 is "Target Size (Minimum)" (Level AA), introduced in WCAG 2.2. It requires interactive targets to be at least 24x24 CSS pixels, with exceptions for spacing, inline targets, and user-agent-controlled elements. The criterion number and its subject matter are correctly identified.

**Sources:**
- [W3C Understanding SC 2.5.8: Target Size (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html)

---

## Claim 3: "content reflow (1.4.10)"

The draft references WCAG 1.4.10 for content reflow.

**Verdict:** Accurate
**Confidence:** High

WCAG 1.4.10 is "Reflow" (Level AA). It requires content to be presented without loss of information or functionality and without scrolling in two dimensions, at widths equivalent to 320 CSS pixels (for vertical scrolling content). The criterion number and description are correct.

**Sources:**
- [W3C Understanding SC 1.4.10: Reflow](https://www.w3.org/WAI/WCAG21/Understanding/reflow.html)

---

## Claim 4: "WCAG 2.5.8: 24x24px minimum, 44x44px recommended"

The draft states the minimum target size is 24x24px per WCAG 2.5.8, with 44x44px recommended.

**Verdict:** Mostly accurate
**Confidence:** High

WCAG 2.5.8 (Target Size Minimum, Level AA) does require 24x24 CSS pixels minimum. However, the "44x44px recommended" framing is imprecise. The 44x44 figure comes from WCAG 2.5.5 (Target Size Enhanced, Level AAA), which is a separate success criterion at a higher conformance level -- not a "recommendation" within 2.5.8 itself. The 44x44 figure also appears in Apple's Human Interface Guidelines (as 44x44 points). Google Material Design recommends 48x48dp. The draft's phrasing could mislead readers into thinking 44x44 is a recommendation within 2.5.8.

**Sources:**
- [W3C Understanding SC 2.5.8: Target Size (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html)
- [W3C Understanding SC 2.5.5: Target Size (Enhanced)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html)

---

## Claim 5: "WCAG 1.4.11: non-text contrast -- UI components must have 3:1 contrast against adjacent colors"

**Verdict:** Accurate
**Confidence:** High

WCAG 1.4.11 (Non-text Contrast, Level AA) requires a contrast ratio of at least 3:1 against adjacent colors for visual information required to identify user interface components and states. The draft's description is correct.

**Sources:**
- [W3C Understanding SC 1.4.11: Non-text Contrast](https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html)

---

## Claim 6: "WCAG 4.1.3: status messages must be programmatically determinable"

**Verdict:** Accurate
**Confidence:** High

WCAG 4.1.3 (Status Messages, Level AA) requires that status messages can be programmatically determined through role or properties such that they can be presented to the user by assistive technologies without receiving focus. The draft's description is accurate.

**Sources:**
- [W3C Understanding SC 4.1.3: Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)

---

## Claim 7: "European Accessibility Act (2025) -- legal requirements for discoverable UI elements"

**Verdict:** Mostly accurate
**Confidence:** Medium

The European Accessibility Act did come into effect on 28 June 2025, so the "(2025)" date reference is correct. It does impose legal requirements for digital accessibility. However, the draft's specific characterization of "legal requirements for discoverable UI elements" is a simplification. The EAA references EN 301 549, which incorporates WCAG 2.1 Level AA. The EAA's requirements are broad (perceivable, operable, understandable, robust) rather than specifically targeting "discoverable UI elements" as a named requirement. The claim is directionally correct but imprecise.

**Sources:**
- [AccessibleEU: EAA comes into effect June 2025](https://accessible-eu-centre.ec.europa.eu/content-corner/news/eaa-comes-effect-june-2025-are-you-ready-2025-01-31_en)
- [Level Access: European Accessibility Act Compliance Guide](https://www.levelaccess.com/compliance-overview/european-accessibility-act-eaa/)

---

## Claim 8: "NNGroup: flat UI elements with weak signifiers require more user effort"

**Verdict:** Accurate
**Confidence:** High

NNGroup published eyetracking research showing that UIs with weak clickability signifiers required 22% more time and 25% more fixations compared to strong-signifier versions. The draft's attribution is accurate and correctly summarizes the finding.

**Sources:**
- [NNGroup: Flat UI Elements Attract Less Attention and Cause Uncertainty](https://www.nngroup.com/articles/flat-ui-less-attention-cause-uncertainty/)
- [NNGroup: Long-Term Exposure to Flat Design](https://www.nngroup.com/articles/flat-design-long-exposure/)

---

## Claim 9: "NNGroup: 'Show scrollbars when content is scrollable.'"

The draft attributes this quoted recommendation to NNGroup.

**Verdict:** Unverified
**Confidence:** Low

NNGroup does recommend visible scrollbars and has published on the topic of scroll discoverability, but I could not find the exact quoted sentence "Show scrollbars when content is scrollable" in NNGroup's published articles. The sentiment aligns with NNGroup's general recommendations, but the specific quote could not be verified as a direct NNGroup quotation. It may be a paraphrase presented as a quote.

**Sources:**
- [NNGroup scrollbar and scrolling topic page](https://www.nngroup.com/topic/flat-design/) (general topic area; exact quote not located)

---

## Claim 10: "WCAG 2.4.7: focus visible. WCAG 2.4.11: focus appearance -- minimum area and contrast."

In the Affordance Principles Reference section, the draft describes 2.4.11 as concerning "focus appearance -- minimum area and contrast."

**Verdict:** Inaccurate
**Confidence:** High

This is a repeat of the error identified in Claim 1. WCAG 2.4.11 is "Focus Not Obscured (Minimum)" -- it concerns whether focused elements are hidden behind other content, not focus indicator appearance, area, or contrast. The criterion about minimum focus indicator area and contrast is 2.4.13 (Focus Appearance, Level AAA). This is the same numbering error appearing in a different section of the draft.

**Sources:**
- [W3C Understanding SC 2.4.11: Focus Not Obscured (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html)
- [W3C Understanding SC 2.4.13: Focus Appearance](https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html)

---

## Claims Requiring Author Attention

1. **Claim 1 & 10 (Inaccurate):** All references to "2.4.11" as "Focus Appearance" should be changed to "2.4.13". WCAG 2.4.11 is "Focus Not Obscured (Minimum)" in the final WCAG 2.2 spec. This error appears in the introduction, the visibility/affordance checklist (Step 2, item 6), and the Affordance Principles Reference (item 7). Also note that 2.4.13 is Level AAA, not AA -- this affects what level of conformance the skill is recommending.

2. **Claim 4 (Mostly Accurate):** The "44x44px recommended" should clarify that this comes from WCAG 2.5.5 (Level AAA) or from platform guidelines (Apple HIG), not from 2.5.8 itself.

3. **Claim 7 (Mostly Accurate):** The EAA description as "legal requirements for discoverable UI elements" is a simplification. Consider rephrasing to reference the EAA's broader accessibility requirements via EN 301 549 / WCAG 2.1 AA.

4. **Claim 9 (Unverified):** The quoted NNGroup recommendation "Show scrollbars when content is scrollable" could not be verified as a direct quote. Consider removing the quotation marks or finding the exact source.
