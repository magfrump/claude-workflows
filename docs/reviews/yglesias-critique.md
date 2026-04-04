# Yglesias-Style Critique: UI Visual Review Skill

**Reviewed:** 2026-04-03
**Document:** `ui-visual-review` skill definition (draft)

---

## 1. The Goal vs. the Mechanism

The goal is correct: AI agents reviewing UI code should catch real usability problems — elements that overflow, controls that vanish, layouts that collapse at different viewport sizes. That is a genuine failure mode in AI-assisted front-end development, and having a structured skill for it is sensible.

The mechanism, though, is fighting a war on two fronts and losing both.

**Front one: cross-resolution robustness.** The checklist (unbounded content, wrong flex usage, absolute positioning, scroll containers) is genuinely useful. These are real bugs that a code-review agent can catch by reading CSS and HTML. This is the boring, high-value core of the skill.

**Front two: an aesthetic philosophy.** The skill declares that Windows 98-era visible affordances should be preferred over modern minimalist design. This is not a review heuristic; it is an opinion about what good UI looks like. And it is an opinion that conflicts with what virtually every design system the skill itself cites (Apple HIG, Material Design) actually recommends. The skill tells the agent to validate recommendations against tech company guidelines, and then tells it to override those guidelines when they conflict with a preference for always-visible scroll bars and buttons that "look like buttons." The agent is being told to consult the authorities and then ignore them.

The two fronts are not complementary. The cross-resolution robustness work is objective: does this layout break at 320px? The aesthetic philosophy is subjective: should this scroll bar be visible? Bundling them together means the objective findings will be discounted because they arrive packaged with stylistic opinions the team may not share. The skill's credibility on "your flex container collapses at mobile widths" is undermined by "also, your scroll bars should look like Windows 98."

## 2. The Boring Lever

The boring lever nobody is pulling: **just run the checklist against the code without the web searches or the aesthetic philosophy.**

The seven-item issue checklist in Step 2 is the highest-value part of this skill by a wide margin. Unbounded content without scroll caps, controls trapped inside scroll containers, wrong flex/shrink usage — these are mechanical bugs that can be detected by reading the code. They do not require web searches. They do not require consulting Apple HIG. They require pattern-matching against known CSS failure modes.

An agent that reads the code, runs through that checklist, and reports findings with severity ratings and fix suggestions would be fast, reliable, and useful. That is the 80% version. The other 20% — mandatory web searches for every issue type, cross-referencing tech company guidelines, viewport simulation against three specific resolutions — is ceremony that slows the agent down without proportionally improving output quality.

## 3. Follow the Money (or Effort)

Trace where the agent's time and token budget actually goes under this skill:

1. **Check for project-local UI guidelines:** Fast, useful. Read one file.
2. **Read the code against the issue checklist:** This is the core work. Medium effort, high value.
3. **Web search for current best practices for each issue type:** This is where the budget explodes. "Each issue type" means potentially seven separate web searches. Each search returns results that need to be read and synthesized. For well-understood CSS patterns (flex shrink behavior, overflow handling), this is looking up things the agent already knows from training data. For "current best practices," the search results will be a mix of MDN documentation (accurate, stable) and blog posts (variable quality, possibly outdated). The agent is spending significant effort to arrive at recommendations it could have made directly.
4. **Check tech company UI guidelines:** Another round of searches. Material Design and Apple HIG are extensive documents. Searching them for guidance on, say, scroll container behavior will return general design philosophy, not specific CSS fixes. The translation from "Material Design says use persistent scroll indicators for long lists" to "add `overflow-y: auto` with a max-height" is work the agent has to do anyway.
5. **Test against three viewport scenarios:** The skill says "test" but the agent is reviewing code, not running a browser. What this actually means is "reason about what happens at these widths," which is useful but does not require a specific resolution checklist — it requires understanding the CSS.
6. **Produce a structured report with before/after code:** High value. This is the deliverable.

Steps 3 and 4 consume most of the effort budget and contribute the least to the output. The agent will spend more time searching and reading than it spends analyzing the actual code. That is backwards.

## 4. Factual Foundation

Key findings from the fact-check report:

- The Windows 98 characterization claims hover and active states; Win98 actually had active states but not hover states. Minor, but it undermines the skill's positioning of Win98 as the gold standard of "explicit affordances" — even Win98 did not get everything right.
- **1024x768 as "minimum supported"** is not defensible. This resolution has approximately 0% desktop market share. Including it as a mandatory verification target means the agent is spending effort on a viewport that essentially no users will encounter. If the goal is catching real-world layout bugs, the minimum should be a resolution people actually use.
- **1440x900 as "typical laptop"** has roughly 4% market share. The actual typical laptop resolution is 1920x1080 or, for older hardware, 1366x768. The viewport checklist is wrong about what "typical" means, which means the agent's verification work is calibrated to viewports that do not match the actual user population.
- Core technical claims about CSS behavior, named guidelines, and MDN references are all accurate. The skill knows its CSS.

The viewport errors matter because the skill makes viewport verification mandatory. If the verification targets are wrong, the mandatory work is wasted.

## 5. The Scale Test

What happens when this skill is used across many projects by many teams?

**Teams with a design system** will immediately hit friction. The skill says "prefer classic desktop UI principles" but the team's design system says "use our component library, which follows Material Design." The skill has a rule to check for project-local UI guidelines and treat them as primary authority, which is good — but then the entire Windows 98 philosophy section becomes dead letter for any team that has a design system. That is most professional teams. The philosophy section is load-bearing in the skill's identity but irrelevant in practice for its target users.

**Teams without a design system** are the ones who might benefit from opinionated defaults. But these teams are also the ones most likely to be building internal tools or prototypes where "make it work at all viewport sizes" matters more than "make scroll bars always visible." The aesthetic philosophy is solving a problem these teams do not have.

**At scale across a codebase:** the mandatory web searches become redundant fast. The best practices for "unbounded content without scroll caps" do not change between files. The agent will search for the same guidance repeatedly, burning tokens on the same MDN articles every time. There is no caching or "search once, apply many times" mechanism.

## 6. The Org Chart

This skill is executed by an AI agent, not a human. That matters for three reasons:

1. **The agent cannot actually test viewports.** It can reason about CSS behavior at different widths, but "test recommendations against three viewport scenarios" implies running code in a browser, which the agent cannot do. The instruction is aspirational, not operational. The agent will either skip it or fake it by narrating what it thinks would happen.

2. **Web search quality is unpredictable.** The skill makes web search mandatory, but the agent has no way to evaluate whether a search returned useful results. It will dutifully cite whatever it finds, even if the top result is a 2019 blog post recommending techniques that have since been superseded. The mandatory search rule means the agent cannot use its training knowledge directly even when that knowledge is more reliable than search results.

3. **The agent has no visual perception of the running app.** It is reviewing code, not screenshots. The skill is written as though the reviewer can see the UI, but the reviewer is reading CSS classes and HTML structure. This is fine for the mechanical checklist items but problematic for the aesthetic judgments. "Buttons look like buttons" is a visual assessment that cannot be made from code alone — especially with utility-class frameworks like Tailwind where the visual output is not obvious from the markup.

## 7. Political Survival (Adoption and Resistance)

**What will be adopted:** The issue checklist. Developers will appreciate an agent that catches flex container bugs and overflow problems. This is the kind of tedious, detail-oriented review work that humans skip and agents are good at.

**What will be resisted:** The aesthetic philosophy. The first time the agent tells a team using a modern design system to make their scroll bars always visible, someone will disable or fork the skill. The Windows 98 framing is memorable but polarizing — it will be read as the agent having opinions about design rather than catching bugs, and developers do not want their code review tool to have design opinions.

**What will be ignored:** The mandatory web searches. Teams that care about speed will either remove the requirement or accept that the agent takes longer without questioning whether the searches improve output quality. The searches will become invisible overhead rather than a valued part of the process.

## 8. The Cost Disease Check

The skill has eight mandatory rules, a seven-item checklist, a three-resolution viewport verification, an eight-item "classic UI principles" reference, and requirements for web search, tech company guideline consultation, and structured reporting with before/after code. For a single-purpose skill (review CSS for layout bugs), this is a lot of process.

Each mandatory web search has a fixed cost in time and tokens. That cost does not decrease as the agent gets better at CSS review — it is a floor, not a ceiling. As the agent's training data improves and its ability to reason about CSS gets stronger, the mandatory search requirement becomes pure overhead: the agent already knows the answer but is forced to look it up anyway. The skill has no mechanism to skip searches when the agent is confident, because confidence assessment is not part of the process.

The trajectory is familiar: a tool that starts as "catch layout bugs" accumulates philosophy, research requirements, and verification checklists until the overhead dominates the core function. The skill is already there on its first draft.

## 9. Overall Assessment

This is a useful tool buried inside an overengineered process. The issue checklist is genuinely good. The structured report format is helpful. The instinct to catch layout bugs through code review is sound and addresses a real gap.

**Sound parts:**
- The seven-item issue checklist is well-prioritized and covers real CSS failure modes.
- Checking for project-local UI guidelines first is the right default.
- Structured reporting with severity levels and before/after code is exactly what developers want from a review tool.
- The prohibition on recommending solutions that hide content is a reasonable heuristic (even if "always-visible scroll bars" takes it too far).

**Wish-fulfillment parts:**
- The Windows 98 aesthetic philosophy assumes the agent's design opinions will be welcomed. They will not.
- Mandatory web searches for every issue type assume search results are more reliable than training data. They frequently are not.
- Viewport testing assumes the agent can run code in a browser. It cannot.
- The specific viewport resolutions in the checklist are factually wrong about what users actually use.

**Most important revision:**
Strip the skill down to its core: read code, run the checklist, report findings with fixes. Make the aesthetic philosophy optional guidance rather than a governing principle. Replace mandatory web searches with a "search when uncertain" heuristic. Update the viewport checklist to reflect actual market share data (320-480px mobile, 768-1024px tablet, 1920x1080 desktop). The result would be a faster, more credible tool that teams actually keep enabled.

The skill's own instinct is right: an ugly scroll bar that works is better than a hidden one users never find. But an agent that quickly catches real bugs is better than one that slowly delivers bug reports wrapped in design philosophy nobody asked for.
