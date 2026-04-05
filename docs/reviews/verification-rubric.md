# Draft Verification Rubric

**Draft:** ui-visual-review skill | **Checked:** 2026-04-04 | **Status: ✅ PASSES VERIFICATION**

---

## 🔴 Must Fix

Factual errors identified by fact-check. Draft cannot pass verification with any red items unresolved.

| # | Claim in draft | Issue | Status |
|---|---|---|---|
| R1 | "visible focus indicators (2.4.7, 2.4.11)" / "WCAG 2.4.11: focus appearance — minimum area and contrast" | WCAG 2.4.11 is "Focus Not Obscured (Minimum)", not "Focus Appearance." The correct criterion is 2.4.13 (Level AAA, not AA). Error appears in three locations: intro, Step 2 item 6, and Affordance Principles item 7. | ✅ Fixed — all three references updated to 2.4.13 with AAA noted |

---

## 🟡 Must Address

Imprecise/unverified claims, plus structural issues flagged by multiple critics (high-signal). Each must be fixed or acknowledged by author with a note explaining why it stands.

| # | Item | Type | Status | Author note |
|---|---|---|---|---|
| A1 | "WCAG 2.5.8: 24x24px minimum, 44x44px recommended" conflates two criteria — 44px comes from 2.5.5 (Level AAA), not 2.5.8 | Imprecise claim (fact-check) | ✅ Fixed — separated 2.5.8 (24px AA) from 2.5.5 (44px AAA) | — |
| A2 | NNGroup quote "Show scrollbars when content is scrollable" could not be verified as a direct quotation — should be paraphrased | Unverified claim (fact-check) | ✅ Fixed — rewritten as paraphrase | — |
| A3 | Affordance review bundled with mechanical bug-finding will generate noise that undermines adoption — both critics independently recommend splitting into two modes (fast mechanical default + full audit on request) | Both critics | ✅ Fixed — added Review Modes section, items 6-7 marked full-audit-only | — |
| A4 | No suppression mechanism for repeated false positives across runs — both critics flag this as an adoption-killing dynamic at scale | Both critics | ✅ Fixed — added Suppressing Known Findings section | — |
| A5 | Cross-platform claim ("any framework with visual elements") is not substantiated — all examples are Tailwind/React, all search sources are web-focused | Both critics | ✅ Fixed — intro acknowledges web/Tailwind focus, Unity example added to item 4 | — |
| A6 | "European Accessibility Act (2025) — legal requirements for discoverable UI elements" oversimplifies — EAA references EN 301 549 / WCAG 2.1 AA broadly, not "discoverable UI elements" specifically | Imprecise claim (fact-check) | ✅ Fixed — references EN 301 549 / WCAG 2.1 AA | — |

---

## 🟢 Consider

Ideas from one critic or tensions between critics. Not required to pass. For the author's consideration only.

| # | Idea | Source |
|---|---|---|
| C1 | Viewport ranges leave a gap at 1024-1920px (includes common 1366x768 laptop resolution) — consider adding a fourth range or adjusting boundaries | Cowen |
| C2 | The primary/secondary ranking (mechanical over affordance) is strategically correct because agents are more reliable at objective questions — consider making this reasoning explicit in the skill document | Cowen |
| C3 | The `requires` dependency on code-fact-check should be more clearly marked as optional to orchestrators | Yglesias |
| C4 | "Search when uncertain" heuristic may drift toward mandatory searches — consider tighter calibration like "search only when you would be guessing without it" | Yglesias |
| C5 | The Viewport Verification Checklist is process theater if the agent checks its own boxes — useful only if it produces unchecked items for the developer | Yglesias |
| C6 | Static CSS analysis has known blind spots (dynamic content, JS-driven layout, browser-specific rendering) — consider a standing "Issues static review cannot catch" section in the report template | Cowen |
| C7 | Building inspector analogy: the skill is strongest in inspector mode (objective checks) and weakest in architect mode (design opinions) — the document structure gives architect mode more prominence than "secondary" warrants | Cowen |

---

## Verified ✅

Claims confirmed accurate by the fact-check. No action needed.

| Claim | Verdict |
|---|---|
| "minimum target sizes (2.5.8)" — WCAG 2.5.8 is Target Size (Minimum), 24x24px | ✅ Accurate |
| "content reflow (1.4.10)" — WCAG 1.4.10 is Reflow | ✅ Accurate |
| "WCAG 1.4.11: non-text contrast — UI components must have 3:1 contrast" | ✅ Accurate |
| "WCAG 4.1.3: status messages must be programmatically determinable" | ✅ Accurate |
| "NNGroup: flat UI elements with weak signifiers require more user effort" | ✅ Accurate |
| "WCAG 2.4.7: focus visible" | ✅ Accurate |

---

To pass verification: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
