# Cowen-Style Critique: UI Visual Review Skill

**Reviewed:** 2026-04-03
**Document:** Skill definition for `ui-visual-review` — an AI agent instruction set for reviewing web app UI code for layout and visual issues

---

## 1. The Argument, Decomposed

The skill document bundles several distinct claims:

1. **UI review should be grounded in research.** The agent must web-search for current best practices and check authoritative guidelines (Apple HIG, Material Design, MDN) before recommending fixes. (Procedural claim.)

2. **Classic desktop UI principles (visible affordances, always-visible scroll bars, buttons that look like buttons) are the right default philosophy for web app UIs in 2026.** (Aesthetic/design claim.)

3. **When classic affordances conflict with modern minimalist design, classic should win.** "An ugly scroll bar that works is better than a hidden one that users never find." (Priority claim.)

4. **There is a canonical checklist of visual issues ordered by frequency** — unbounded content, trapped controls, wrong flex usage, etc. (Empirical claim about what goes wrong most often.)

5. **Three viewport breakpoints (1024x768, 1440x900, 1920x1080) constitute adequate testing coverage.** (Sufficiency claim.)

6. **Project-local guidelines are the primary authority**, overriding the skill's own defaults. (Governance claim.)

Claims 1 and 6 are sensible procedural hygiene. Claim 4 is a useful heuristic even if the ordering is debatable. The interesting tension lives in claims 2, 3, and 5.

---

## 2. What Survives the Inversion

**Inverting claim 3: "When classic affordances conflict with modern minimalist design, modern should win."** This is essentially the position that Apple, Google, and most major design systems have taken for the past decade. The minimalist camp argues that visible affordances create visual noise, that users have learned touch/swipe/hover conventions, and that clean interfaces improve comprehension by reducing clutter. This inversion is not a straw man — it is the dominant professional consensus.

What survives from the original? The skill is specifically targeting *web apps*, not marketing sites or content pages. Web apps are tool-like: users perform repeated tasks, often under time pressure, and discoverability failures are more costly than in casual browsing. The case for visible affordances is genuinely stronger for web apps than for the broader web. The skill's instinct here is defensible — but it is a narrower claim than the skill makes. The skill states its preference as a universal principle rather than a context-dependent one.

**Inverting claim 2: "Windows 98 UI principles are the wrong frame for 2026 web development."** This partially survives. The Windows 98 reference is doing double duty: it is both a concrete set of design principles (visible borders, explicit affordances) and a rhetorical signal (nostalgia as authority). The concrete principles are defensible. The rhetorical framing is counterproductive — a developer receiving this review will pattern-match "Windows 98" to "outdated" and discount the advice. The same principles reframed as "WCAG accessibility requirements" or "Nielsen Norman Group recommendations" would be harder to dismiss and would carry more professional authority.

---

## 3. Factual Foundation

The fact-check report surfaces findings that matter for the skill's credibility as an instruction set:

**The viewport checklist is empirically wrong.** 1024x768 has approximately 0% desktop market share, making it a poor choice for "minimum supported." 1440x900 sits at roughly 4% market share — not "typical laptop" by any current measure. The actual common resolutions are 1920x1080 (desktop) and 1366x768 or 1920x1080 (laptop). An agent following these instructions will test against viewports that almost nobody uses while potentially missing the ones that matter.

**The Windows 98 hover-state claim is slightly inaccurate.** The skill's Classic UI Principles Reference lists "hover/active states" for buttons, but Windows 98 had active states without hover states. This is a small point, but it is ironic: the skill is invoking Windows 98 as an authority while getting the details of Windows 98 wrong. An agent that web-searches this will find conflicting information and may lose confidence in its own instructions.

**Core CSS and design-system references are accurate.** The technical recommendations about flex behavior, overflow handling, and named guidelines are all solid.

---

## 4. The Boring Explanation

The most mundane account of why this skill exists: someone built a web app, encountered real layout bugs (content overflowing, controls hidden behind scroll containers, things breaking at certain viewport sizes), and codified their debugging checklist into an AI agent instruction set. The Windows 98 framing is post-hoc rationalization of a practical preference — they wanted visible scroll bars because they had been bitten by hidden ones, and "Windows 98 philosophy" is a memorable way to express "make things visible."

This boring explanation accounts for nearly everything in the document. The issue checklist in Step 2 reads like a real developer's bug log, ordered by how often they personally encountered each problem. The viewport checklist reflects the resolutions of monitors they have actually used, not a statistical sample. The "classic vs. modern" framing is a story told after the fact to give a debugging checklist the dignity of a design philosophy.

What the boring explanation does not account for: the governance structure (project-local guidelines as primary authority, mandatory web search) is more sophisticated than a personal checklist. Someone thought carefully about how an AI agent should handle conflicting advice, and the answer — defer to project context, then research, then defaults — is well-designed.

---

## 5. Revealed vs. Stated

**Stated preference:** "Your guiding philosophy combines two traditions" — classic desktop and modern responsive design. Equal billing.

**Revealed preference:** The conflict-resolution rule ("prefer the classic approach") plus the eight-item Classic UI Principles Reference, with no corresponding Modern Design Principles Reference, reveals that this is not a synthesis of two traditions. It is the classic tradition with modern techniques (flexbox, media queries) as implementation tools. The stated frame is "both/and." The revealed frame is "one, using the other's tools."

**Stated preference:** The skill claims to prioritize discoverability.

**Revealed preference:** The viewport checklist does not include any mobile-first breakpoint below 320px, and the "three viewport scenarios" are all desktop-to-tablet range. A skill that truly prioritized discoverability would spend more time on the viewports where discoverability is hardest — small touch screens where affordances are most likely to be hidden or off-screen. The revealed preference is for desktop-like environments where the Windows 98 philosophy is most natural.

**Stated preference:** "MUST check for project-local UI guidelines document first, treating it as primary authority."

**Revealed preference:** This is the single most important rule in the document, and it is tucked into a numbered list of six mandatory rules, visually equal to "MUST NOT introduce CSS requiring vendor prefixes without noting browser needs." The de-emphasis suggests the author views it as procedural boilerplate rather than the load-bearing design decision it actually is.

---

## 6. The Analogy

**Building codes and architectural aesthetics.**

Building codes specify minimum stair-tread depth, maximum riser height, required handrail dimensions, minimum door widths. These requirements are not stylistically neutral — they push architecture toward certain forms and away from others. An architect can still design a beautiful staircase within code, but the code is not trying to be beautiful. It is trying to prevent people from falling.

The UI visual review skill is essentially proposing a building code for web app interfaces. Visible scroll bars are handrails. Button borders are stair treads. The philosophy is: safety and usability are not optional, and the constraints they impose on aesthetics are a cost worth paying.

What this analogy reveals: building codes are written by committees that study injury data, not by individual architects nostalgic for older buildings. The skill would be stronger if it grounded its requirements in accessibility research and usability data rather than in the aesthetic preference of a particular era. "Windows 98 had visible scroll bars" is the equivalent of "old buildings had wide stairs." The real argument is: "people fall when stairs are too narrow." The skill is making the right argument from the wrong evidence.

The analogy also reveals a limitation: building codes are *minima*, not *ideals*. Nobody aspires to build exactly to code. The skill's framing — "prefer the classic approach" — risks turning a minimum into a ceiling. The best web app UIs satisfy the building code (everything is discoverable) while also being well-designed. The skill does not leave room for that aspiration.

---

## 7. Contingent Assumptions

1. **The relevant user is a desktop user with a mouse.** The Classic UI Principles Reference (scroll bars, resize handles, hover states, menus with visible arrows) describes a mouse-driven interface. Touch interfaces, voice interfaces, and screen readers have different affordance requirements. The skill assumes the dominant interaction mode of the 1990s without noting that it is now one of several.

2. **Developers are the audience for the review output.** The skill produces severity-grouped fixes with before/after code. This assumes the recipient is a developer who can implement CSS changes, not a designer or product manager who might need a different framing. Reasonable assumption for a code-review tool, but worth noting.

3. **Web search will return good results for CSS best practices.** This is mostly true today, but web search quality for technical topics is not guaranteed to remain stable. More importantly, an AI agent's web search may surface outdated advice (CSS tricks from 2018, pre-flexbox workarounds) alongside current best practices. The skill does not instruct the agent how to evaluate the freshness or authority of search results.

4. **The issue checklist's frequency ordering is stable.** The ordering (unbounded content first, responsive concerns last) reflects a particular kind of web app — likely one with complex data-display panels, not a media-heavy or animation-heavy app. The frequency ordering is contingent on the app category.

5. **"Visible affordance" and "discoverability" are the same thing.** The skill conflates these. A visible scroll bar is a visible affordance. But discoverability also includes things like onboarding flows, tooltips, progressive disclosure, and consistent placement — none of which the skill addresses. The skill cares about one kind of discoverability (can you see the control?) while ignoring others (do you know what the control does?).

---

## 8. What the Market Says

If visible-affordance-first design were clearly superior for web apps, we would expect the market to reflect this. What do we actually see?

**The major design systems disagree with the skill.** Material Design, Apple HIG, and Microsoft's Fluent Design all moved toward minimalist affordances over the past decade. These are not marginal players — they are the platforms that most web apps target. If visible scroll bars and bordered buttons were strictly better, the platforms with the most user research data would not have moved away from them.

**But enterprise software partially agrees.** Salesforce Lightning, SAP Fiori, and other enterprise design systems retain more visible affordances than consumer-facing systems. Enterprise users perform repetitive, high-stakes tasks where discoverability failures are expensive. This aligns with the skill's implicit context (web apps as tools) but suggests the skill should explicitly scope itself to enterprise-style applications rather than claiming universal applicability.

**Accessibility regulations are moving toward the skill's position.** WCAG 2.2 introduced requirements for visible focus indicators and minimum target sizes that push toward more visible affordances. The European Accessibility Act (2025) creates legal requirements for discoverable UI elements. The regulatory market is partially vindicating the skill's instincts — but through accessibility law, not through Windows 98 nostalgia.

**The most interesting market signal:** the recent trend of "neobrutalist" and "anti-design" web aesthetics, which deliberately use visible borders, high-contrast colors, and obvious affordances. This movement treats visible affordances as a *stylistic choice*, not a usability requirement. The skill could be more interesting if it acknowledged that its preferred aesthetic is having a cultural moment for reasons unrelated to usability.

---

## 9. Overall Assessment

**Strongest sub-claim:** The governance structure (claim 6) — project-local guidelines as primary authority, with web search as a check against stale defaults — is well-designed and shows real thought about how an AI agent should handle conflicting sources of truth. High confidence.

**Second strongest:** The issue checklist (claim 4) is a genuinely useful debugging heuristic. Even if the frequency ordering is debatable, the items themselves cover real, common problems. The checklist alone justifies the skill's existence. High confidence.

**Weakest sub-claim:** The viewport checklist (claim 5) contains empirically incorrect resolutions and omits the most common ones. This is the easiest thing to fix and the most likely to produce wrong results if left as-is. An agent testing at 1440x900 and 1024x768 is testing for ghosts while potentially missing bugs at 1366x768. High confidence this needs fixing.

**Most interesting tension:** The classic-over-modern priority (claim 3) is defensible for enterprise web apps but overstated as a universal principle. The skill would be stronger if it scoped this preference explicitly ("for tool-like web applications where task completion matters more than first impressions") rather than presenting it as always correct. Moderate confidence — this is a judgment call about how prescriptive a skill document should be.

**The single most important thing to address:** Reframe the authority basis. The Windows 98 reference is memorable but counterproductive. The same principles, grounded in WCAG accessibility requirements and enterprise UX research, would be harder to dismiss and more persuasive to the developers receiving the reviews. The skill is making a reasonable argument from an unnecessarily weak rhetorical position. The building code is good; the justification needs to cite injury data, not architectural nostalgia.

**What the skill is more right about than it realizes:** The instinct to make everything visible and discoverable is increasingly supported by accessibility regulation, and enterprise design systems never fully abandoned it. The skill is swimming with a current it does not seem aware of. Citing WCAG 2.2 and the European Accessibility Act would transform the skill's philosophy from "retro preference" to "regulatory compliance" — a much stronger position that happens to arrive at the same design recommendations.
