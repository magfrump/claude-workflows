# Yglesias-Style Critique: UI Visual Review Skill

**Reviewed:** 2026-04-04
**Document:** `ui-visual-review` skill definition (current draft on `feat/ui-visual-review`)
**Fact-check report:** 2026-04-04 (10 claims, 6 accurate, 2 mostly accurate, 1 inaccurate, 1 unverified)

---

## The Goal vs. the Mechanism

The goal is sound: an AI agent that catches real layout bugs in UI code during review. Elements that overflow, collapse, or vanish at different viewport sizes are genuine, common defects. Automating their detection is a good idea.

The mechanism has improved significantly from the earlier draft. The Windows 98 aesthetic philosophy is gone. Mandatory web searches are gone. The viewport resolutions are now realistic (320-480px, 768-1024px, 1920px+). The skill explicitly acknowledges that the agent is "reviewing code, not running a browser." These were the right revisions.

But the skill still fights on two fronts, and the fronts still undermine each other. The **mechanical bug-finding** (the seven-item checklist) is objective, verifiable, and high-value. The **affordance review** (the eight affordance principles) is subjective, context-dependent, and will generate false positives in any project that uses a modern component library. Bundling them into one skill means every invocation pays the cost of affordance review whether or not the project wants it. The skill says affordance review is "secondary" and "when relevant," but the affordance principles section is 30+ lines of detailed guidance with specific citations — that is not how you signal "secondary." If it were truly secondary, it would be a separate skill or a flag the orchestrator can omit.

The mechanism undermines the goal in a specific way: an agent that delivers five accurate flex-container bug reports alongside three debatable affordance opinions will be perceived as noisy. The developer response to noise is to disable the tool. The accurate findings get thrown out with the subjective ones.

## The Boring Lever

The boring lever is still the same one the earlier critique identified, and the revised skill is closer to pulling it but not all the way there: **just run the seven-item checklist.**

Items 1-5 (unbounded content, trapped controls, flex sizing, absolute positioning, excessive spacing) are mechanical CSS pattern-matching. They can be checked by reading the code, they have clear right/wrong answers, and the fix patterns are well-defined. This is the kind of tedious, systematic work that agents are better at than humans.

Items 6 (visibility and affordance) and 7 (responsive and cross-browser) are where the skill transitions from bug-finding to design review. Item 6 in particular is where most of the false positives will come from. "Interactive elements that look like static text" is a visual judgment that cannot reliably be made from code, especially in Tailwind where visual appearance is not obvious from class names.

The boring lever: make items 1-5 the default mode, and items 6-7 opt-in when explicitly requested. The skill already has the machinery for this (severity tiers, scope determination in Step 1). It just needs to make the split explicit rather than running everything every time.

## Follow the Money

In an AI agent context, "follow the money" means follow the attention and compute. Trace where the agent's token budget goes under this skill:

1. **Step 1: Determine Scope** — Cheap. Ask or infer which files. Good.
2. **Step 2: Read the Code** — This is the core work. The seven-item checklist is well-structured. Reading files completely is expensive but necessary. The example fix patterns are helpful because they give the agent concrete output templates rather than forcing it to generate fixes from scratch. Net positive.
3. **Step 3: Research When Uncertain** — The "search when uncertain" heuristic is a major improvement over mandatory searches. But "uncertain" is poorly calibrated. The skill says to search for "unfamiliar CSS properties" and "browser compatibility for newer features" — both reasonable. But it also says to search when "you need to determine current best practices for a specific pattern" and when "you're unsure whether a recommendation aligns with WCAG 2.2 requirements." These are broad enough to be triggered on most issues. An agent that is trying to be thorough (and they all are) will interpret "uncertain" expansively. Without a stronger signal — something like "search only when you would be guessing without it" — the heuristic will drift toward mandatory searches in practice.
4. **Step 4: Produce Fixes** — High value. Before/after code blocks are exactly what developers want.
5. **Step 5: Produce the Report** — The structured report format is good but heavy. The Viewport Verification Checklist at the bottom is three checkboxes the agent will always check (because it wrote the report to satisfy them). It is process theater unless someone else verifies. If the report is the final artifact, those checkboxes are unchecked items for the developer, which is useful. If the agent checks them itself, they are meaningless.

The biggest hidden cost: the `requires` block says this skill takes a `code-fact-check` report as input. That means every invocation potentially triggers a separate skill run first. The skill-on-skill dependency chain means the total cost of a "UI visual review" is (fact-check run) + (visual review run). For a diff that touches a CSS file, that is a lot of agent work. The skill says "without this input, the UI visual review proceeds on code analysis only," which is the right escape valve — but the orchestrator needs to know this is optional, not required.

## Factual Foundation

The fact-check report found one clear error and one unverified claim in the skill:

- **WCAG 2.4.11 is not "Focus Appearance."** The skill cites 2.4.11 twice (in the intro and in the affordance principles). The actual criterion at 2.4.11 is "Focus Not Obscured (Minimum)." The correct criterion for focus appearance is 2.4.13, which is Level AAA — meaning it is an aspirational target, not a baseline requirement. This matters because the skill presents focus appearance as a standard the agent should enforce. If it is AAA, most projects will not be targeting it, and enforcing it will generate false positives.

- **The "44x44px recommended" target size** comes from WCAG 2.5.5 (Level AAA), not from 2.5.8 itself. The skill conflates the 24x24px minimum (2.5.8, Level AA) with the 44x44px recommendation from a different, higher-level criterion. Again, citing a AAA criterion as a general recommendation inflates the standard the agent enforces.

- **The NNGroup quote** ("Show scrollbars when content is scrollable") could not be verified as a direct quotation. This is minor but relevant because the skill wraps it in quotation marks, giving it the authority of a citation rather than a paraphrase.

The pattern: the skill consistently rounds up to the stricter standard without flagging that it is doing so. This is a form of authority inflation — citing WCAG but using the AAA criteria rather than the AA ones most projects target. An honest framing would be "WCAG 2.5.8 requires 24x24px minimum; WCAG 2.5.5 recommends 44x44px for AAA compliance."

## The Scale Test

What happens when this skill runs on every diff that touches UI code across a busy project?

**Redundancy:** The same affordance findings will appear repeatedly. If a project uses borderless text inputs as a design pattern, the agent will flag them on every diff that includes a text input. There is no memory between runs — no way to say "we already decided borderless inputs are fine for this project." The skill checks for project-local guidelines, which is the right mechanism, but most projects will not have a `docs/UI_LAYOUT_GUIDELINES.md` file. The skill needs a lighter-weight suppression mechanism (inline comments, `.ui-review-ignore`, something).

**Fatigue:** If the skill triggers on every diff that "touches UI rendering code" (per the `when` clause and the code-review integration), developers will see UI review reports on routine changes. A diff that adds a new list item to a sidebar will trigger a full seven-item checklist review. The report will likely find nothing, but the developer still has to read "no issues found" reports. Over time, they stop reading.

**False positive accumulation:** The affordance principles will generate a steady trickle of findings that the team disagrees with but cannot suppress without editing the skill. This is the adoption-killing dynamic: the tool is right often enough to keep but wrong often enough to annoy, and there is no middle ground.

## The Org Chart

The skill is executed by an AI agent within a prompt-engineering framework. The relevant "org chart" questions:

**Who maintains the skill?** If the WCAG citations are wrong (and one is), who fixes them? The skill is a text file in a repo, so the answer is "whoever notices." But the people running the skill are developers reviewing UI code, not accessibility specialists. They are unlikely to notice that 2.4.11 should be 2.4.13. The wrong citations will persist.

**Who decides when affordance findings are false positives?** The skill has no escalation path. When the agent says "this button lacks visible affordances" and the developer disagrees, there is no mechanism to record the disagreement and prevent recurrence. The developer's options are: ignore the finding (repeatedly), edit the skill to remove the principle, or add a project-local guideline that overrides it. None of these are low-friction.

**What authority does the skill have?** It produces a report. It does not block merges or fail CI. This is correct — a tool with this many subjective judgments should not be a gate. But it means adoption depends entirely on perceived value, which circles back to the noise problem.

## Political Survival

**What will be adopted:** The mechanical checklist (items 1-5). Developers want an agent that catches flex container bugs and overflow problems. This is tedious review work that humans skip. The fix patterns with before/after code are genuinely helpful.

**What will be tolerated:** The responsive and cross-browser checks (item 7). These are somewhat subjective but close enough to "real bugs" that developers will accept them.

**What will cause friction:** The affordance review (item 6) and the affordance principles section. The first time the agent tells a team to add visible borders to their Material UI text fields, someone will want to disable the skill. The skill's defense — "project-local guidelines override" — requires the team to write a guidelines document to shut up a review tool, which is backwards.

**What will survive a year?** A stripped-down version that runs the mechanical checklist and produces the structured report. The affordance principles will either be removed or moved to a separate opt-in skill. This is the natural selection pressure of developer tooling: accuracy and speed survive; opinions get forked out.

## The Cost Disease Check

The skill is not in a cost-diseased sector in the traditional sense, but there is an analogous dynamic: **process accumulation in AI agent instructions.**

The skill has: 5 mandatory execution rules, 7 checklist items with example fix patterns, 4 search-priority sources, a structured report template with 6 sections, 8 affordance principles with citations, and a dependency on another skill. For a tool whose core function is "read CSS, find bugs," that is a lot of instruction surface area.

Each piece of guidance was presumably added for a reason, but the total cost is not the sum of the parts. Every additional instruction the agent must consider is a decision point that consumes attention and increases the chance of the agent spending time on low-value work. The skill is already long enough that an agent executing it will need to prioritize internally, which means some instructions will be de facto ignored anyway — the agent just will not tell you which ones.

The cost disease analogy: as the skill accumulates more guidance, the agent does not get faster at the core task. It gets slower. The guidance is overhead that scales linearly with invocations but provides diminishing returns after the first one. The fix patterns are load-bearing (the agent uses them). The affordance principles are overhead (the agent reads them, considers them, and mostly generates findings the developer ignores).

## Overall Assessment

This is a meaningfully improved skill from the earlier draft. The Windows 98 philosophy is gone. The mandatory web searches are gone. The viewport targets are realistic. The explicit acknowledgment that the agent reviews code, not running UIs, is honest and helpful.

**What works:**
- The seven-item issue checklist is well-prioritized and covers real CSS failure modes.
- The example fix patterns give the agent concrete templates, reducing hallucination risk.
- Project-local guidelines as primary authority is the right default.
- The "search when uncertain" heuristic is better than mandatory search, though it needs tighter calibration.
- The structured report format with severity tiers and before/after code is what developers want.

**What still needs work:**
- The WCAG citations need fixing (2.4.11 -> 2.4.13, and the 44x44px attribution needs to distinguish AA from AAA). Incorrect citations undermine the skill's authority on the things it gets right.
- The affordance review should be explicitly opt-in or a separate skill. Bundling subjective design review with objective bug-finding hurts the credibility of both.
- The NNGroup quote should either be verified or rewritten as a paraphrase.
- The skill needs a lightweight suppression mechanism for repeated false positives — something lighter than "write a project-local guidelines document."
- The `requires` dependency on code-fact-check should be clearly marked as optional to orchestrators, not just in the description text.

**Most important single revision:** Split the skill into two modes — a fast "mechanical review" (checklist items 1-5, no affordance analysis, no web search) and a full "visual audit" (all items, affordance principles, search when uncertain). Make mechanical review the default when triggered by the code-review orchestrator. Make visual audit the mode when a user explicitly asks for "UI review" or "audit the CSS." This gives teams the high-value bug-finding without the noise, while preserving the full capability for when someone actually wants it.

The skill's instinct is right: catch the layout bugs nobody else catches. Now let it do that without also trying to be a design consultant.
