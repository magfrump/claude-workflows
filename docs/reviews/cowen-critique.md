# Cowen-Style Critique: UI Visual Review Skill

**Reviewed:** 2026-04-04
**Document:** Skill definition for `ui-visual-review` — an AI agent instruction set for reviewing UI code for visual/layout issues
**Fact-check report:** 10 claims checked; 6 accurate, 2 mostly accurate, 1 inaccurate, 1 unverified

---

## The Argument, Decomposed

The skill bundles several distinct sub-claims:

1. **Mechanical bug-finding (layout breakage at different viewport sizes) is the core value of this skill.** The checklist in Step 2 is the main tool. (Value-priority claim.)

2. **Affordance review is a secondary, conditional job** grounded in WCAG 2.2, NNGroup research, and European accessibility law. (Scope claim.)

3. **When minimalist aesthetics conflict with discoverability, prefer discoverability** — especially in tool-like web applications. (Priority claim.)

4. **There is a canonical checklist of 7 visual issues ordered by frequency** — unbounded content, trapped controls, wrong flex usage, absolute positioning, excessive spacing, visibility/affordance, responsive concerns. (Empirical claim about what goes wrong most often.)

5. **Three viewport width ranges (320-480px, 768-1024px, 1920px+) constitute adequate review coverage.** (Sufficiency claim.)

6. **Project-local guidelines are the primary authority**, overriding the skill's own defaults. (Governance claim.)

7. **The agent can reason about viewport behavior by reading CSS, without running a browser.** (Capability claim.)

Claims 1 and 6 are the load-bearing structural decisions. Claim 4 is a practical heuristic. The interesting questions live in claims 2-3, 5, and 7.

---

## What Survives the Inversion

**Inverting claim 3: "When discoverability conflicts with minimalist aesthetics, prefer minimalism."** This is, in practice, the position that Apple, Google, and most major design systems have taken for over a decade. The minimalist camp argues that visible affordances create visual noise, that users have internalized touch/swipe/hover conventions, and that clean interfaces improve comprehension by reducing clutter. This is not a straw man — it is the dominant professional consensus in consumer design.

What survives from the original? The skill now explicitly scopes this preference to "tool-like web applications where task completion matters more than first impressions." This is a genuinely defensible narrowing. Enterprise and productivity software is where discoverability failures are most expensive. The skill's instinct is sound within its stated scope.

**Inverting claim 1: "Affordance review is the core value; mechanical bug-finding is secondary."** This inversion does not survive well. Affordance judgments are inherently subjective and context-dependent, while "does this container overflow at 360px?" is a near-binary question. An AI agent will be more reliably useful at the mechanical work. The skill correctly identifies where its comparative advantage lies.

**Inverting claim 7: "You cannot meaningfully reason about viewport behavior without running a browser."** This partially survives. Static CSS analysis catches many layout issues — wrong flex properties, missing overflow constraints, absolute positioning bugs. But it cannot catch issues arising from dynamic content, JS-driven layout changes, font rendering differences, or subtle interaction between CSS properties that behave differently across browser engines. The skill acknowledges this ("Note: you are reviewing code, not running a browser") but could be more explicit about the class of bugs this approach will miss.

---

## Factual Foundation

The fact-check report surfaces issues that affect the skill's credibility as an instruction set:

**The WCAG 2.4.11 reference is wrong.** The skill cites "2.4.11" for focus appearance, but WCAG 2.4.11 is actually "Focus Not Obscured (Minimum)." The correct criterion for focus appearance is 2.4.13, which is Level AAA. An agent that web-searches 2.4.11 expecting focus appearance guidance will find different content than expected. This matters because the skill positions itself as grounded in standards — getting the standard numbers wrong undermines the authority claim.

**The touch target recommendation conflates two criteria.** The "44x44px recommended" figure comes from WCAG 2.5.5 (Level AAA), not from 2.5.8. The skill cites 2.5.8 correctly for the 24x24px minimum but attributes the 44px recommendation to the same source. This is a minor mixing, but in a document whose authority rests on precise standards citations, precision matters.

**The NNGroup scroll-bar quote is unverified.** "Show scrollbars when content is scrollable" could not be confirmed as a direct quotation. This is low-stakes — NNGroup has published extensively on scroll affordances — but a fabricated quote is worse than a paraphrased finding.

**Core technical content is solid.** The flex behavior recommendations, overflow handling patterns, docked footer pattern, and general CSS guidance are all accurate and practical.

---

## The Boring Explanation

The most mundane account of why this skill exists: someone built web apps, encountered real layout bugs repeatedly (content overflowing modals, submit buttons scrolling away, things breaking on small screens), and codified their debugging checklist into an AI agent instruction set. The WCAG and NNGroup citations are post-hoc grounding of a practical preference — they wanted visible scroll bars because they had been bitten by hidden ones, and accessibility standards are a legitimate way to justify that preference.

This boring explanation accounts for nearly everything in the document. The Step 2 checklist reads like a real developer's bug log, ordered by how often they personally encountered each problem. The code examples (modal with capped height, docked footer pattern) are clearly patterns extracted from actual fixes.

What the boring explanation does not fully account for: the governance structure (project-local guidelines as primary authority, conditional web search, deference to existing codebase patterns) is more sophisticated than a personal checklist. Someone thought carefully about how an AI agent should handle conflicting advice. The answer — defer to project context, then standards, then heuristic defaults — is well-designed and suggests experience with AI agent design, not just CSS debugging.

---

## Revealed vs. Stated

**Stated preference:** Mechanical bug-finding is primary; affordance review is secondary.

**Revealed preference:** The Affordance Principles Reference section is 8 items long with detailed rationale and citations. The mechanical checklist has 7 items. The affordance section occupies comparable document real estate and is positioned as a standalone reference at the end — the natural place for a reader to look for "what does this skill care about?" The document says mechanical is primary but gives roughly equal weight to both.

**Stated preference:** The skill applies to "any framework with visual elements: React/JSX/TSX, Unity/C#, Vue, Svelte, native mobile, etc."

**Revealed preference:** Every code example is Tailwind/React JSX. The checklist items reference CSS-specific concepts (flex-1, min-h-0, overflow-auto, viewport meta tags, media queries). The Step 3 research sources are all web-focused (MDN, Can I Use). A Unity/C# developer receiving this review would find the principles relevant but the specifics inapplicable. The skill is a web app review tool with aspirational cross-platform claims.

**Stated preference:** "Search the web when uncertain — not for every issue."

**Revealed preference:** Step 3 and Step 5 both elaborate on when and how to search, and search guidance appears in the Mandatory Execution Rules as well. The skill mentions web search four separate times. For something described as conditional, it gets a lot of instruction space. The revealed concern is that the agent will either search too much (wasting time) or too little (missing important context), and the skill is trying to thread that needle. Reasonable, but the repeated emphasis suggests the author has seen agents get this wrong.

---

## The Analogy

**Building inspection checklists and property appraisals.**

A property inspector works from a standard checklist: foundation, roof, plumbing, electrical, HVAC, structural integrity. The checklist is ordered by severity (foundation problems before cosmetic issues). The inspector does not design the house — they find defects against known standards. They produce a report grouped by severity. They note when something is "within acceptable parameters but suboptimal." They defer to local building codes as primary authority.

This is exactly what the UI visual review skill is. It is a building inspection protocol for web app interfaces. The Step 2 checklist is the inspection checklist. The severity grouping (Critical/Major/Minor) is the inspection report format. The deference to project-local guidelines is deference to local building codes.

What this analogy reveals: building inspectors are useful precisely because they are mechanical and consistent, not because they have taste. The skill is strongest when it stays in inspector mode (does this container overflow? is this button trapped in a scroll region?) and weakest when it drifts into architect mode (should this design prefer visible affordances?). The skill seems to understand this — the primary/secondary distinction maps exactly onto inspector/architect — but the document's structure gives the architect role more prominence than a secondary concern warrants.

The analogy also reveals a gap: building inspectors have a known false-negative rate. They miss things that require invasive testing (opening walls, running water for extended periods). The skill's equivalent is layout bugs that only manifest with dynamic content, JS interactions, or browser-specific rendering. The skill should be honest about this limitation in its report template — something like "Issues that static code review cannot catch" as a standing section.

---

## Contingent Assumptions

1. **CSS/layout code is readable in isolation.** The skill assumes an agent can determine layout behavior by reading CSS and markup. This works for static layouts but fails when layout depends on JavaScript state, server-rendered conditional classes, or CSS-in-JS that generates class names at build time. The skill does not address how to handle layout that is computed rather than declared.

2. **The issue frequency ordering is stable across app types.** "Unbounded content without scroll caps" is listed as "most common." This is plausible for data-heavy dashboard-style apps but may not hold for content sites, e-commerce, or animation-heavy interfaces. The ordering is contingent on app category.

3. **Three viewport ranges are sufficient.** The ranges (320-480, 768-1024, 1920+) leave a notable gap at 1024-1920px, which includes the extremely common 1366x768 laptop resolution. The skill instructs the agent to "reason about" these three ranges, but the most common desktop viewport (1920x1080) sits right at the boundary of the third range, and the very common laptop range (1280-1440px) falls between ranges two and three.

4. **The agent's CSS knowledge is "sufficient" for well-understood patterns.** The skill explicitly says "for well-understood CSS patterns... your training data is sufficient." This is a bet on the agent's training data remaining current as CSS evolves. Container queries, `dvh` units, and `scrollbar-gutter` are mentioned as things to search for — but the boundary between "well-understood" and "search-worthy" will shift over time, and the skill provides no mechanism for updating that boundary.

5. **The report format serves the consumer.** The skill produces a structured Markdown report with severity grouping and code fixes. This assumes the consumer is a developer who will implement fixes directly. If the consumer is a design team, product manager, or accessibility auditor, the format may not match their needs. Reasonable for a code-review tool, but the universality of the report format is assumed rather than argued.

---

## What the Market Says

If mechanical CSS review were clearly high-value, we would expect to see it reflected in tooling markets. What do we see?

**Linting tools partially validate the approach.** Stylelint, ESLint with JSX-a11y, and similar tools catch a subset of what this skill targets — but they operate on syntactic rules, not layout reasoning. The gap between "this CSS property is misused" and "this layout breaks at 480px" is exactly where this skill sits. The existence of the gap suggests the skill is targeting a real unmet need.

**Design system adoption suggests the market prefers prevention over detection.** Tailwind, Chakra, Material UI, and similar component libraries are the market's answer to layout bugs — constrained primitives that make it harder to write broken layouts in the first place. The skill operates downstream of this: reviewing code that uses these systems but still manages to break. This is a real use case (you can absolutely write broken layouts in Tailwind), but the market's energy is flowing toward prevention rather than review.

**Accessibility auditing tools are a growing market.** axe-core, Lighthouse accessibility audits, and paid services like Deque validate the appetite for automated accessibility review. This skill's affordance review component aligns with market demand — but those tools actually run in a browser, which gives them access to computed styles and real DOM. The skill's code-only approach is faster but less reliable. The market signal is: people will pay for accessibility review, but they expect runtime validation, not static analysis.

**The most telling signal:** no major IDE or CI/CD pipeline includes automated viewport-aware layout review as a standard feature. If this were easy or obviously valuable, someone would have built it. Either the problem is harder than it looks (likely — layout reasoning requires understanding context that static analysis struggles with), or the demand is lower than assumed (less likely — layout bugs are common and expensive to fix post-deployment).

---

## Overall Assessment

**Strongest element:** The Step 2 checklist (claim 4). This is a genuinely useful debugging heuristic grounded in real bugs. The code examples are practical and correct. The docked footer pattern, the viewport-capped modal, the flex sizing guidance — these are patterns a developer can apply immediately. The checklist alone justifies the skill's existence. High confidence.

**Second strongest:** The governance structure (claim 6) — project-local guidelines as primary authority, with conditional web search and standards-based defaults as fallbacks. This shows real thought about how an AI agent should navigate conflicting sources of truth. High confidence this is well-designed.

**Most improved from prior version:** The skill has dropped the Windows 98 framing and now grounds its affordance preferences in WCAG 2.2 and NNGroup research. This is a significant improvement. The authority basis is now standards and research rather than aesthetic nostalgia. The scoping to "tool-like web applications where task completion matters more than first impressions" is an honest and defensible narrowing.

**Needs attention:** The WCAG citation errors (2.4.11 vs. 2.4.13, conflating 2.5.5 and 2.5.8 for the 44px recommendation) should be corrected. A skill that derives authority from standards citations needs to get the citations right. The unverified NNGroup quote should be paraphrased rather than presented as a direct quotation. These are easy fixes that would meaningfully improve credibility. High confidence.

**Interesting tension:** The cross-platform claim ("any framework with visual elements") vs. the web-only specifics. The principles are genuinely universal — overflow handling, control placement, and affordance matter everywhere. But the implementation guidance is CSS/Tailwind-specific. The skill could either narrow its claim ("web UI code") or add framework-specific guidance for its other claimed targets. Moderate confidence this matters — in practice, 90%+ of uses will likely be web code.

**What the skill is more right about than it realizes:** The emphasis on mechanical bug-finding as primary value is strategically correct for an AI agent. AI agents are much more reliable at objective questions ("does this overflow?") than subjective ones ("is this discoverable enough?"). By explicitly ranking mechanical over aesthetic, the skill plays to the agent's strengths. The skill does not articulate *why* this ranking is right in terms of agent capabilities — it frames it as a value judgment about what matters more. But the real reason it works is that it directs the agent toward tasks where it can be reliably useful. This is a good decision that could be made even better by being explicit about the reasoning.

**Calibration note:** I am moderately confident in the structural critiques (cross-platform gap, viewport range gaps, static-analysis limitations) and highly confident in the factual corrections needed. I am less confident about whether the affordance review section's prominence is a problem in practice — it may serve as useful reference material even if it gets more space than "secondary" warrants.
