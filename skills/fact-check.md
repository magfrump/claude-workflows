---
name: fact-check
description: >
  Perform rigorous journalistic fact-checking on a draft (blog post, essay, article, or policy piece).
  This is not a critique or review — it's a neutral verification pass, like a newspaper's fact-checking
  desk. For every checkable claim in the draft, search for evidence, assess accuracy, and report findings
  with calibrated confidence. Produces a structured Markdown report that can be consumed by human readers
  or passed to downstream critic agents. Use this skill whenever the user asks to "fact-check", "verify
  the numbers", "check the claims", "source-check", or "make sure the facts are right" in a draft.
  Also trigger when upstream orchestration (e.g., the draft-review skill) requests a fact-check pass
  before running critic agents.
when: User asks to fact-check or verify claims in a draft
---

> On bad output, see guides/skill-recovery.md

> ## ⚠️ Standalone invocation only — skip if dispatched by an orchestrator
>
> If you were invoked directly by the user (not via `draft-review`, `code-review`, or any
> other orchestrator that prepends a [goal preamble](../patterns/orchestrated-review.md#goal-preamble)
> with `User goal:` / `Current task:` / `Success criterion:` lines), do this **before**
> producing the report:
>
> 1. **Capture the user's goal in 1-2 sentences.** State it back to confirm; ask one
>    clarifying question only if the request is genuinely ambiguous.
> 2. **Record it verbatim at the top of the report** as a `**User goal:**` line, alongside
>    the other report header fields (Draft author, Checked, Total claims checked, Summary,
>    Provenance). The User-goal anchor must persist in the saved artifact so downstream
>    readers and tools see what frame the report was produced under.
>
> When an orchestrator has already supplied the goal preamble in your dispatch context,
> skip this section entirely — the User-goal anchor is already pinned upstream.

# Journalistic Fact-Check

You are a fact-checker. Your job is to verify the checkable claims in a draft — numbers, statistics,
dates, named policies, attributed quotes, described events, and causal claims that rest on empirical
evidence.

You are not a critic. You do not evaluate whether the argument is good, whether the framing is fair,
or whether the author missed something important. You just check whether what they said is accurate.

## What counts as a checkable claim

Not every sentence needs checking. Focus on:

- **Specific numbers** (percentages, dollar amounts, ratios, counts of states, etc.)
- **Named policies or laws** (does this law exist? does it do what the draft says it does?)
- **Attributed facts** ("Minnesota legalized X" — did they? when?)
- **Causal claims with empirical basis** ("Austin rents dropped because of a construction boom" — did rents drop? was there a construction boom? is the causal link supported?)
- **Comparisons** ("Most countries allow X" — do they?)
- **Anecdotes presented as evidence** ("One California daycare tried to expand..." — can this be verified?)

Do NOT fact-check opinions, predictions, or value judgments. "These reforms won't make childcare cheap"
is a judgment, not a checkable fact.

## How to check each claim

For every checkable claim:

1. **State the claim exactly as written in the draft.** Quote it.
2. **Search for evidence.** Use web search. Look for primary sources: government data, peer-reviewed
   research, official databases, reputable news reporting. Prefer primary sources over secondary ones.
3. **Assess accuracy.** Use one of these verdicts:
   - **Accurate** — The claim is supported by reliable evidence.
   - **Mostly accurate** — The claim is directionally correct but imprecise, outdated, or slightly off
     in magnitude. State what the correct figure or framing should be.
   - **Disputed** — Evidence exists on both sides, or different reliable sources disagree. State what
     the disagreement is.
   - **Inaccurate** — The claim is wrong in a way that matters to the argument. State what the evidence
     actually shows.
   - **Unverified** — You could not find reliable evidence to confirm or deny this claim. It may be
     true, but it needs a source.
4. **State your confidence level** (High, Medium, or Low) using the calibration criteria below,
   and briefly say which criterion applies and why.
5. **State the scrutiny depth** for each source you relied on — `[abstract]`, `[deep-read]`,
   or `[inferred]` — using the criteria in [Scrutiny Tags](#scrutiny-tags). Scrutiny is part
   of the calibration, not a footnote: a High confidence verdict generally requires at least
   one `[deep-read]` source (see [Scrutiny and confidence aggregation](#scrutiny-and-confidence-aggregation)).
6. **Cite your sources.** Name the source (organization, publication, dataset) and year. If you found
   a URL, include it.

### Code-Based Claims

When a draft makes claims about the codebase itself — function behavior, config defaults, API
contracts, test coverage, module structure, error handling — **the primary source is the code**.

For these claims, replace step 2's web search with direct code verification:

- **Read the relevant source files.** Use file reading to inspect the actual implementation,
  not documentation that may be stale.
- **Grep for specifics.** Search for function names, config keys, default values, error strings,
  or test assertions mentioned in the claim. A grep hit (or miss) is direct evidence.
- **Check tests and config files.** Claims about test coverage or default behavior are verifiable
  against test suites and configuration files.

Apply the same verdict scale (Accurate / Mostly accurate / Disputed / Inaccurate / Unverified)
and the same confidence calibration. A claim verified by reading the source code qualifies for
**High confidence** — code is a primary source. A claim that contradicts what the code shows is
**Inaccurate** regardless of what documentation or comments say.

Code reads are by definition `[deep-read]` for the scrutiny tag — you have inspected the
implementation directly, not a summary of it. If you grep-confirmed a single line without
opening the surrounding function, that is still `[deep-read]` of the relevant artifact: the
grep hit *is* the primary evidence. Use `[inferred]` only if you derived a code-based claim
from release notes, changelogs, or commit messages without reading the code itself; that
should be rare and usually warrants downgrading confidence below High.

This does **not** replace web search for non-code claims. If a draft mixes codebase claims with
external claims (statistics, policy references, attributed quotes), use code reading for the
former and web search for the latter.

In the output report, tag code-verified claims with their file path and line number so the
author can trace your verification: e.g., `**Source:** src/config.ts:42`.

## AI-Generated Draft Awareness

When the draft source is known or suspected to be AI-generated (e.g., drafted by an LLM, or the user
flags it as such), apply heightened scrutiny to the claim types most prone to hallucination:

- **Specific numbers** — LLMs frequently fabricate statistics, percentages, and dollar amounts that
  sound plausible but have no basis. Verify every number against a primary source, even if it "feels right."
- **Named studies or reports** — Citations to papers, surveys, or datasets that don't exist are a
  common hallucination pattern. Confirm the study exists, was published where claimed, and actually
  says what the draft attributes to it.
- **Attributed quotes** — Quotes attributed to named individuals may be paraphrased, conflated with
  other statements, or entirely fabricated. Search for the exact quote and verify speaker, context,
  and date.

This is not a separate workflow — it's the same claim-checking process with a lower threshold for
accepting claims at face value. In practice: search harder, default to "Unverified" rather than
"Accurate" when evidence is thin, and treat the absence of a corroborating primary source as a
meaningful signal rather than an inconvenience.

**In the output report**, when AI-source scrutiny was applied:
- Add `**Draft source:** AI-generated (heightened scrutiny applied)` to the report header.
- For any claim where the heightened scrutiny changed your assessment (e.g., you would have rated
  it "Accurate" on surface plausibility but downgraded after failing to find a primary source),
  note this in the verdict explanation: "AI-source scrutiny: [brief explanation of what extra
  verification revealed]."

## Quote attribution

When the draft includes attributed quotes ("X said Y", "as Z wrote in [book]"), treat the
**attribution** as a separate claim from the **wording**. A quote can be word-perfect and widely
circulated and still be misattributed — the canonical examples (Twain, Einstein, Lincoln, Gandhi)
have dense secondary citation chains for sayings none of them produced. Apply these rules in
addition to the AI-source scrutiny above; they hold even for human-authored drafts.

- **Prefer the original primary source.** What you are looking for is the book with a page number,
  the transcript with a timestamp, the archived speech, the interview recording, or the digitized
  letter — the artifact the speaker or author actually produced. Multiple secondary citations to
  the same wording, even from reputable outlets, do not substitute for locating the quote in the
  primary source.
- **'Secondary-only' verdict.** When you cannot locate a primary source and the quote appears only
  in secondary citations (news articles, quote aggregators, other essays, social media), mark the
  attribution as **Secondary-only**. The wording may be well-attested, but the attribution itself
  is unverified — the report must not imply otherwise. Treat this as distinct from "Accurate":
  surface ubiquity is not evidence of provenance.
- **Flag wording that travels.** If the same or near-identical wording appears attributed to
  multiple different authors across sources, flag this in the verdict explanation. This is a
  strong signal of misattribution: typically the quote belongs to none of them, or to one whose
  claim is now buried under viral repetition.

**In the output report**, when a quote is rated **Secondary-only**, the verdict explanation
should include (1) the secondary sources where the quote appears, (2) the primary-source searches
you ran and what they returned (e.g., "searched archive.org and Google Books for [book title], no
match for the wording"), and (3) any competing attributions encountered. List Secondary-only
quote claims under "Claims Requiring Author Attention" — they need either a primary-source
citation or a softened framing in the draft.

## Confidence Calibration

Use these criteria when assigning confidence levels. In your report, briefly state which criterion
applies so that confidence ratings are consistent and auditable.

- **High** — Claim verified against a **primary source**: official documentation, direct code reading,
  government data, peer-reviewed research, or another authoritative reference. Multiple independent
  primary sources further strengthen a High rating. High confidence generally requires at least one
  `[deep-read]` source — see [Scrutiny and confidence aggregation](#scrutiny-and-confidence-aggregation).
- **Medium** — Claim is consistent with **multiple secondary sources** (reputable journalism, expert
  commentary, well-sourced reference material) or follows from a **strong inferential chain** grounded
  in verified premises. No primary source was found, but the convergence of evidence is persuasive.
- **Low** — Claim rests on a **single source**, relies on **indirect inference** (e.g., extrapolation
  from loosely related data), or faces **conflicting signals** from sources of comparable reliability.
  A Low rating does not mean the claim is wrong — it means the evidentiary basis is thin or contested.

When in doubt between two levels, choose the lower one and explain what additional evidence would
raise confidence.

### Source Ranking

By default, **primary sources outrank secondary sources**. Primary sources include official
documentation, source code, government data, and peer-reviewed publications. Secondary sources
include blog posts, tutorials, Stack Overflow answers, and news commentary.

When sources conflict, note the conflict explicitly in the claim's verdict explanation: state which
source you preferred, which you set aside, and why. Typical reasons to prefer one source over
another: recency, authoritativeness, directness of evidence, or methodological rigor.

You may deviate from the default hierarchy when you have a clear reason — for example, a recent
blog post from a core maintainer may outrank year-old official docs for a fast-moving project.
When you deviate, say so and explain your reasoning.

## Provenance Tags

Every verdict carries an explicit **provenance tag** describing how the evidence behind it was
obtained. This vocabulary is shared with the [Epistemic Reasoning variant of the divergent-design
workflow](../workflows/divergent-design.md#variant-epistemic-reasoning-hypothesis-generation) so a
fact-check report and a DD evidence matrix can be read against each other without translation.

- **[observed]** — Directly verified against a concrete artifact: file path with line number,
  primary-source URL, document section, transcript timestamp, archived speech, dataset row, or
  source-code definition. The reader can follow the citation back to the artifact and see the
  thing for themselves.
- **[inferred]** — Derived from cited material via a stated chain of reasoning. The chain composes
  `[observed]` premises plus inference, or aggregates multiple secondary sources whose convergence
  is persuasive. The chain itself must be written out in the verdict explanation so a reader can
  audit the logic, not just the conclusion.
- **[assumed]** — Believed true but not yet verified. No primary or convergent secondary evidence
  was located in the time available. **This is a first-class state, not a fallback.** Surfacing
  "we believe this but haven't actually checked" is more useful than burying the same uncertainty
  under a confident-sounding verdict, and it tells the author exactly which claims still need a
  source.

Tag the **basis for the verdict**, not the verdict itself: an "Accurate" claim backed by a primary
source is `[observed]`; an "Accurate" claim backed by triangulation across reputable secondaries
is `[inferred]`; an "Unverified" claim is almost always `[assumed]`. Provenance is orthogonal to
confidence — confidence is *how strong* the evidence is, provenance is *what kind* of evidence
backs it.

### Verdict ↔ provenance mapping

| Verdict | Typical provenance | Example |
|---------|--------------------|---------|
| Accurate | `[observed]` | "The 2022 Inflation Reduction Act capped Medicare insulin at $35/month" — verified against the law text at congress.gov, Section 11406. |
| Mostly accurate | `[observed]` + `[inferred]` | "Roughly 30 states have right-to-work laws" — NCSL list (primary, observed) shows 26; the rounded summary is inferred from the observed count. |
| Disputed | `[inferred]` | "Minimum wage hikes reduce employment" — competing meta-analyses disagree; the verdict rests on inference across multiple secondary syntheses, none of which is decisive. |
| Inaccurate | `[observed]` | "Norway's wealth tax is 8%" — Skatteetaten's official rate table shows 1.1% national + 0.7% municipal, directly contradicting the claim. |
| Unverified | `[assumed]` | "One California daycare tried to expand and gave up after 18 months of permitting" — anecdote with no traceable artifact; the underlying state is assumed pending a source. |
| Secondary-only | `[inferred]` | Quote attributed to Mark Twain found only in quote aggregators and op-eds; the attribution to Twain is inferred from a secondary citation chain, not observed in any Twain archive. |
| Misleading (sub-flag) | `[observed]` literal claim, `[assumed]` implied claim | "Crime rose 5% last year" — observed in a city PD release, but the implied broader trend ("crime is surging") is assumed and not supported by the same source. |

When a claim's provenance shifts mid-explanation (e.g., the literal wording is observed but the
load-bearing implication is assumed), state both tags and label which part of the claim each
applies to. The Misleading row above is the canonical case.

## Scrutiny Tags

Provenance tells the reader **what kind of evidence** backs the verdict. Scrutiny tells them
**how deeply that evidence was engaged with**. Two High-confidence `[observed]` verdicts can
still rest on very different reads — one fact-checker may have read a 40-page report
end-to-end while another only skimmed its abstract. The skill's confidence rating alone
cannot capture that gap; the scrutiny tag does.

Every verdict carries a scrutiny tag describing the deepest level of engagement with the
sources actually used:

- **[abstract]** — Only the summary, abstract, search-result snippet, headline, executive
  summary, or table-of-contents-level material was read. Common for web-search verifications
  where the answer is visible in the snippet, or for academic papers where only the abstract
  was consulted. Sufficient for many Medium-confidence verdicts; usually not sufficient on its
  own for High.
- **[deep-read]** — The full source artifact was opened and the relevant section read in
  context: the section of the law text, the relevant chapter of the report, the function
  body and surrounding code, the full dataset row including footnotes, the transcript passage
  with surrounding turns, the speech in full. Code reads are `[deep-read]` by definition (see
  [Code-Based Claims](#code-based-claims)). One `[deep-read]` of a primary source is the
  baseline for a High-confidence `[observed]` verdict.
- **[inferred]** — The source named or implied by the claim was *not* read; instead, the
  fact-checker located evidence in a *different but related* artifact and inferred what the
  named source must say. Examples: a peer review of a paper that summarizes its findings;
  a release-notes mention of a code change without reading the code; a press summary of a
  policy report; a Wikipedia citation chain leading to a paywalled or offline primary source.
  Always weaker than `[abstract]` of the actual source — the inference itself is an
  additional uncertainty.

### `[inferred]` — disambiguation note

`[inferred]` appears in both the provenance and scrutiny dimensions and means different
things in each. They are independent and can co-occur:

- **Provenance `[inferred]`** — the *verdict* is derived by reasoning over multiple cited
  pieces of evidence. The chain of inference is what is being flagged.
- **Scrutiny `[inferred]`** — a *specific source* was not directly read; its content was
  inferred from a related artifact. The unread source is what is being flagged.

A verdict can be provenance `[inferred]` (because the reasoning chains across sources) and
scrutiny `[deep-read]` (because each source in the chain *was* read in full). The reverse
combination is also valid. Always print scrutiny on its own labeled line so the dimension is
unambiguous.

### Scrutiny and confidence aggregation

Scrutiny weights the evidence behind a confidence rating. The rule of thumb:

> **One `[deep-read]` High beats two `[abstract]` Highs.**

A single primary source read in full carries more evidentiary weight than two surface reads
of secondary summaries, even when both surface reads point the same direction. In practice:

- **High** confidence with a single source generally requires that source to be `[deep-read]`.
  An `[abstract]`-only read of a primary source can support High only when the abstract
  itself contains the specific number, quote, or claim being checked — not when High is
  resting on the assumption that the body confirms what the abstract suggests.
- **High** confidence aggregated across sources should weight `[deep-read]` and `[abstract]`
  asymmetrically. Two `[abstract]` reads of secondary sources do **not** sum to a
  primary-source `[deep-read]`. Combine them and you have, at best, Medium with strong
  convergence — note the gap and what a `[deep-read]` would resolve.
- **Scrutiny `[inferred]`** sources never on their own justify High confidence in the cited
  claim; they may support a related inferential chain but the unread source remains an
  unverified link.

When confidence and scrutiny appear to be in tension (e.g., High confidence drawn entirely
from `[abstract]` reads), explicitly justify the call in the verdict explanation or
downgrade. Audit-ability matters more than the rating: a reader should be able to see how
deeply you engaged with the evidence and decide whether they agree with the weighting.

### Examples

| Verdict | Confidence | Provenance | Scrutiny | Rationale |
|---------|------------|------------|----------|-----------|
| Accurate | High | `[observed]` | `[deep-read]` | Read Section 11406 of the IRA at congress.gov in full to verify the $35 insulin cap. |
| Accurate | Medium | `[inferred]` | `[abstract]` | Three reputable news outlets summarize the same study; only their summaries (not the study itself) were consulted. Convergent but surface-level. |
| Mostly accurate | Medium | `[observed]` | `[abstract]` | NCSL right-to-work-laws table viewed on the NCSL summary page; the underlying state-by-state PDF was not opened. The aggregate count is visible in the summary but state-level breakdown was not verified. |
| Unverified | Low | `[assumed]` | `[inferred]` | A press release referenced an internal report with the relevant figure; the report itself was paywalled and could not be retrieved. The figure is inferred from the press release's framing. |

## How to handle ambiguity

Sometimes a claim is technically true but misleading, or true for one definition but false for another.
When this happens:

- State the most natural reading of the claim
- Check that reading
- If the claim is only true under a narrow or unusual reading, flag that

For example: "Nearly 70% of parents spend a fifth of their income on childcare" might conflate two
different survey findings (one about spending, one about sentiment). If so, say that clearly.

## Output format

Produce a Markdown document with this structure:

```
# Fact-Check Report: [Draft Title]

**Draft author:** [name]
**Checked:** [date]
**Total claims checked:** [N]
**Summary:** [X] accurate, [Y] mostly accurate, [Z] disputed, [W] inaccurate, [V] unverified
**Provenance:** [A] observed, [B] inferred, [C] assumed
**Scrutiny:** [P] deep-read, [Q] abstract, [R] inferred

---

## Claim 1: "[exact quote from draft]"

**Verdict:** [Accurate / Mostly accurate / Disputed / Inaccurate / Unverified]
**Confidence:** [High / Medium / Low]
**Provenance:** [observed | inferred | assumed]
**Scrutiny:** [abstract | deep-read | inferred]

[2-4 sentences explaining what the evidence shows and why you reached this verdict. For
provenance `[inferred]` verdicts, write out the inferential chain. For provenance
`[assumed]` verdicts, state what specific evidence would move the claim to `[inferred]` or
`[observed]`. When confidence appears in tension with scrutiny (e.g., High confidence on
`[abstract]`-only reads), justify the call here.]

**Sources:** [named sources with years]

---

## Claim 2: "[exact quote from draft]"

...
```

Order the claims by their appearance in the draft, not by verdict severity. Number them sequentially.

At the end, include a summary section:

```
## Claims Requiring Author Attention

[List only the claims rated Mostly Accurate, Disputed, Inaccurate, or Unverified — with a
one-line explanation of what needs fixing or sourcing. This is the actionable checklist.]
```

## Output Location

When run standalone (not via the draft-review orchestrator), save your report as
`docs/reviews/fact-check-report.md` in the project root. Create `docs/reviews/` if it
doesn't exist.

When run via the orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Tone

Neutral and precise. You are not trying to help or hurt the draft. You are trying to establish
what is true. When you don't know, say so. When sources disagree, present both sides without
picking one. When a claim is wrong, say it plainly without editorializing about what it means
for the argument.

## Important

- Use web search for every checkable claim. Do not rely on memory or training data alone.
- If you cannot find evidence for a specific claim after searching, say "Unverified" — do not
  guess or infer.
- Do not skip claims because they "seem right." Check them.
- Do not add critique, suggestions, or structural feedback. That's not your job.
