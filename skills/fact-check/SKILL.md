---
name: fact-check
description: >
  Perform rigorous journalistic fact-checking on a draft (blog post, essay, article, policy piece, or
  any prose with checkable assertions). This is not a critique or review — it's a neutral verification
  pass, like a newspaper's fact-checking desk. For every checkable claim in the draft, search for
  evidence, assess accuracy, and report findings with calibrated confidence. Produces a structured
  Markdown report that can be consumed by human readers or passed to downstream critic agents. Use
  this skill whenever the user asks to "fact-check this", "verify the numbers", "check the claims",
  "source-check", "is this true", "did this actually happen", "make sure the facts are right",
  "verify this draft", or any phrasing that asks for factual verification rather than judgment.
  Also trigger when upstream orchestration (e.g., the draft-review skill) requests a fact-check pass
  before running critic agents — the orchestrator will supply a goal preamble.
when: User asks to fact-check or verify factual claims in a draft
non-goals:
  - Not a critic — do not evaluate argument quality, framing, persuasiveness, or what the author missed; sibling critics (cowen-critique, yglesias-critique) own those concerns.
  - Not a copy-editor — opinions, predictions, value judgments, and rhetorical framing are not checkable claims; skip them rather than verdicting them.
  - Not an inferential reasoner — when no primary or convergent secondary source can be located in the time available, return Unverified rather than guessing from training data or surface plausibility.
  - Not a stylistic editor — state what the evidence shows without proposing rewrites, softened phrasings, or suggested edits to the draft.
requires:
  - A draft (prose or document) containing claims to verify
---

> On bad output, see guides/skill-recovery.md

> ## ⚠️ Standalone invocation only — skip if dispatched by an orchestrator
>
> If you were invoked directly by the user (not via `draft-review`, `code-review`, or any
> other orchestrator that prepends a [goal preamble](../../patterns/orchestrated-review.md#goal-preamble)
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

## Pass 1: Enumerate claims before verifying any of them

Fact-checking is a **two-pass process**. Do not interleave enumeration with verification — the
two passes serve different functions and mixing them lets claims slip past unchecked.

- **Pass 1 (this section)** — walk the draft front to back and enumerate every checkable claim,
  assigning each a stable ID (`C1`, `C2`, …) and a location. Produces the `## Claims identified`
  section of the report.
- **Pass 2 (next section)** — verify each enumerated claim, keyed by its ID. Produces the
  per-claim verdict sections.

The reason for the split: when enumeration and verification are interleaved, the model tends to
stop short, conflate adjacent claims, or quietly skip claims that turn out to be hard to verify.
An upfront enumeration produces a fixed checklist that the verification pass must traverse
completely, and it makes the claim set auditable independently of the verdicts.

### How to enumerate

1. **Read the entire draft first.** Do not start verifying anything yet.
2. **Walk the draft top to bottom** and, for each sentence or clause that meets the
   [checkable-claim criteria](#what-counts-as-a-checkable-claim), emit one enumeration entry.
3. **Assign a sequential ID.** Number claims `C1`, `C2`, … in the order they appear in the
   draft. IDs are stable — Pass 2 verdicts will reference them by ID.
4. **Record a draft location.** Either a paragraph reference (`paragraph 3`, `§ "Methodology",
   paragraph 2`) or a short quoted snippet (≤ 15 words) that anchors the claim in the draft.
   The location must be specific enough that a reader can find the claim in the original draft
   without rereading the whole thing.
5. **Capture the claim's surface form**, paraphrased to its load-bearing assertion. The exact
   quote will appear again in the Pass 2 verdict heading — Pass 1's job is to make the set of
   things being checked visible at a glance, not to repeat the full wording.
6. **One claim per ID.** If a sentence contains two distinct checkable assertions (e.g., a
   statistic *and* an attribution), split them into separate IDs.

The enumeration must be complete before any verdict is written. If you discover a missed claim
while running Pass 2, append it to the Claims identified section with a new ID and then verify
it — never quietly insert it into the verdict stream without a corresponding enumeration entry.

### Prioritize claims: load-bearing vs. peripheral

Enumeration produces a flat list, but not all claims carry the same weight. A long draft can
have dozens of checkable claims, and verifying them uniformly in appearance order spends the
same scrutiny budget on a throwaway aside as on the keystone statistic the whole argument rests
on. The final act of Pass 1 is to **tag each enumerated claim** so Pass 2 can spend its deepest
verification effort where it matters most.

Tag every claim with exactly one of:

- **`[load-bearing]`** — the draft's central thesis collapses, or is materially undermined, if
  this claim is false. These are the keystone facts: the headline statistic, the named policy
  the argument turns on, the causal link the recommendation depends on. Ask: "if a reader
  learned only that *this one claim* was wrong, would they stop believing the draft's main
  point?" If yes, it is load-bearing.
- **`[peripheral]`** — everything else: supporting color, illustrative asides, background
  context, secondary statistics, claims whose falsity would dent but not topple the argument.
  Peripheral does **not** mean unimportant or unchecked — it means checked *later* (see Pass 2).

**Load-bearing claims must be a minority, by construction.** Cap the count of `[load-bearing]`
tags at **`floor(N/3)`**, where `N` is the total number of enumerated claims. This ceiling is a
strict minority for every `N` (e.g. N=6 → at most 2 load-bearing, N=9 → at most 3, N=12 → at
most 4). The cap is the whole point of the tag: if most claims were load-bearing, the tag would
no longer discriminate and the budget dilution it exists to prevent would return. When more
claims feel load-bearing than the cap allows, keep only the *most* load-bearing — the ones whose
falsity would most directly topple the thesis — and tag the rest peripheral. They are still
verified; they are just verified after the keystones.

**Small drafts skip prioritization.** When `floor(N/3)` is 0 (fewer than 3 enumerated claims),
do not tag anything load-bearing — triage earns nothing on a 1–2-claim draft. Verify all claims
at full depth in appearance order, and omit the `**Prioritization:**` header tally line.

Record the tag inline on each `## Claims identified` entry (see [Output format](#output-format)).
The tag is assigned during Pass 1 alongside the ID and location; it does not change the ID or
the appearance order — it only governs the *verification sequence and depth* in Pass 2.

## Pass 2: Verify each enumerated claim

**Verify load-bearing claims first and most deeply.** Pass 2 has two distinct ordering axes,
and they must not be conflated:

- **Processing order (governed by priority).** Verify all `[load-bearing]` claims *before* any
  `[peripheral]` claim. Spend the deepest scrutiny here: target a `[deep-read]` of a primary
  source and aim for the High-confidence bar (≥2 independent primary sources) wherever the
  evidence allows. These are the claims whose verification budget the prioritization step exists
  to protect, so they get the budget first, while attention and time are freshest. Verify
  `[peripheral]` claims afterward; a lighter scrutiny depth (e.g. `[abstract]`) is acceptable for
  them when budget is constrained — but they are **never skipped**. Every enumerated ID, load-
  bearing and peripheral alike, must receive a verdict (the [claim-ID integrity self-check](#self-check-claim-id-integrity)
  rejects any enumerated claim with no verdict).
- **Report order (always appearance order).** The processing order above changes only *when* and
  *how deeply* you verify each claim — it does **not** change how the report is rendered. The
  per-claim verdict sections are still emitted in `C1, C2, …` appearance order (see
  [Output format](#output-format)). Do not reorder the report by priority or by verdict severity.

For every claim ID:

1. **State the claim exactly as written in the draft.** Quote it.
2. **Search for evidence.** Use web search. Look for primary sources: government data, peer-reviewed
   research, official databases, reputable news reporting. Prefer primary sources over secondary ones.
3. **Assess accuracy.** Use one of these verdicts:
   - **Accurate** — The claim is supported by reliable evidence.
   - **Mostly accurate** — The claim is directionally correct but imprecise, outdated, or slightly off
     in magnitude. State what the correct figure or framing should be.
   - **Disputed** — Evidence exists on both sides, or different reliable sources disagree. State what
     the disagreement is. Every Disputed verdict **must** include a one-sentence
     `**Sources disagree:**` line in the report that names at least two source positions
     (who claims X vs. who claims Y), so the structure of the disagreement is visible at a
     glance, not only the fact that one exists. See [Output format](#output-format) for placement.
   - **Inaccurate** — The claim is wrong in a way that matters to the argument. State what the evidence
     actually shows.
   - **Unverified** — You could not find reliable evidence to confirm or deny this claim. It may be
     true, but it needs a source.
   - **Secondary-only** — Used for attributed quotes whose wording is well-attested in secondary
     citations but cannot be located in a primary source. See [Quote attribution](#quote-attribution)
     for when this verdict applies and what its verdict explanation must contain.
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
and the same confidence calibration. Code is a **primary source**, so the derivation rule in
[Confidence Calibration](#confidence-calibration) applies: a single code-read on its own
qualifies for **Medium** confidence; reaching **High** requires a second independent primary
source — typically a test that exercises the behavior, a spec or design doc the code implements,
a related code path that corroborates the claim, or a referenced commit message documenting
the original intent. A claim that contradicts what the code shows is **Inaccurate** regardless
of what documentation or comments say, and the verdict's confidence still follows the
derivation rule from whichever sources back the contradiction.

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

Confidence is **derivable from the cited sources**, not a free-floating self-rating. Mirror the
discipline that [Provenance Tags](#provenance-tags) apply to the *kind* of evidence: an auditor
reading the verdict's `Sources` line should be able to compute the Confidence value mechanically
from the count and type of sources cited, then inspect the [scrutiny tag](#scrutiny-tags) to
confirm or downgrade.

### Derivation rule

- **High** — Backed by **≥2 independent primary sources**. "Independent" means different
  organizations, methodologies, or datasets — not the same finding reported by two outlets, and
  not two pages of the same publication. At least one of the cited primary sources must be
  `[deep-read]` (see [Scrutiny and confidence aggregation](#scrutiny-and-confidence-aggregation)).
- **Medium** — Backed by **exactly 1 primary source**, OR by **≥2 convergent secondary sources**
  (reputable journalism, expert commentary, well-sourced reference material) whose evidence
  aligns. A single primary source `[deep-read]` in full is the canonical Medium evidence; two
  secondaries that triangulate without disagreement are the alternate path.
- **Low** — Backed by **secondary sources only** — a single secondary citation, conflicting
  signals across comparable sources, or evidence that rests on indirect inference from loosely
  related data. A Low rating does not mean the claim is wrong — it means the evidentiary basis
  is thin and a stronger source would lift the rating.

When in doubt between two levels, choose the lower one and state in the verdict what additional
evidence would lift it. **Never assign a confidence value that cannot be defended by pointing at
the Sources line.** If the rule and the rating disagree, the rule wins — or the Sources line is
incomplete and the rating needs to be recomputed.

Primary sources are defined in [Source Ranking](#source-ranking) below.

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
  baseline scrutiny depth for any `[observed]` verdict; reaching High confidence additionally
  requires a second independent primary source per the [derivation rule](#derivation-rule).
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

The [derivation rule](#derivation-rule) sets the **floor**: confidence is computed mechanically
from the count and type of cited sources. Scrutiny modulates that floor — it cannot lift it,
but it can require a downgrade. In practice:

- **At least one cited source per verdict must be `[deep-read]`.** If every cited source is
  `[abstract]` or scrutiny `[inferred]`, downgrade by one tier (High → Medium, Medium → Low,
  Low → Unverified with provenance `[assumed]`).
- **An `[abstract]`-only read of a primary source** can count toward the derivation rule's
  primary-source count only when the abstract itself contains the specific number, quote, or
  claim being checked — not when the rating rests on the assumption that the body confirms
  what the abstract suggests. Otherwise treat it as scrutiny `[inferred]` for aggregation.
- **Scrutiny `[inferred]` sources** (where the named source was not directly read but its
  content was inferred from a related artifact) do not count toward the primary-source tally
  on their own. Two scrutiny-`[inferred]` secondaries do **not** satisfy the "≥2 secondary"
  path for Medium until at least one is opened.
- **One `[deep-read]` primary source still does not lift Medium to High.** The derivation rule
  requires the *count* of independent primary sources, regardless of how deeply any single one
  was read. State in the verdict what a second independent primary source would resolve.

When confidence and scrutiny appear to be in tension (e.g., High confidence drawn from two
primary sources both read only at `[abstract]` depth), apply the downgrade in the report and
justify the call in the verdict explanation. Audit-ability matters more than the rating: a
reader should be able to recompute the tier from the Sources line and see how scrutiny
modulated the result.

### Examples

| Verdict | Confidence | Provenance | Scrutiny | Rationale |
|---------|------------|------------|----------|-----------|
| Accurate | High | `[observed]` | `[deep-read]` | Two independent primary sources: Section 11406 of the IRA at congress.gov (read in full) and CMS's official Medicare Part D rule implementing the cap. Both confirm $35/month — derivation rule's ≥2-primary threshold met, with at least one `[deep-read]`. |
| Accurate | Medium | `[observed]` | `[deep-read]` | Single primary source: Section 11406 of the IRA read in full. No second independent primary located; a CMS implementation rule or Treasury enforcement memo would lift this to High. |
| Accurate | Medium | `[inferred]` | `[abstract]` | Three reputable news outlets (≥2 secondary) summarize the same study and agree; only their summaries (not the study itself) were consulted. Convergent secondaries satisfy the "≥2 secondary" path for Medium, but surface-level — `[deep-read]` of the study would lift to High once it counts as a second primary. |
| Mostly accurate | Medium | `[observed]` | `[abstract]` | NCSL right-to-work-laws table viewed on the NCSL summary page (1 primary, `[abstract]`); the underlying state-by-state PDF was not opened. The aggregate count is visible in the summary but state-level breakdown was not verified. |
| Low | Low | `[inferred]` | `[abstract]` | Single secondary source: a Vox explainer summarizing what a Treasury report supposedly says. No primary located, no convergent second secondary — derivation rule places this at Low until a primary or a second independent secondary is added. |
| Unverified | Low | `[assumed]` | `[inferred]` | A press release referenced an internal report with the relevant figure; the report itself was paywalled and could not be retrieved. The figure is inferred from the press release's framing. |

## Citation Requirement

Naming a source is not the same as citing it. Every verdict must include an **inline citation**
that lets a reader land on the exact evidence behind the verdict without re-running your search.
Choose one of these three formats:

1. **URL with anchor.** A link that resolves to the specific section, paragraph, or row that
   supports the claim — not just the document's homepage. Use the publisher's stable fragment
   (`#section-id`) when available; otherwise use a fragment text directive (`#:~:text=...`),
   a page-anchored PDF URL (`...report.pdf#page=12`), or the deepest URL the source provides.
   For code, the file path with a line number — `src/config.ts:42` — is the equivalent of a
   URL+anchor and counts as this format.
2. **Quoted span (≤25 words) from the source.** A verbatim excerpt, in quotation marks, of
   the sentence or clause that supports the claim. Keep it under 25 words: the cap forces you
   to identify the load-bearing sentence rather than copying paragraphs. If the relevant
   evidence cannot be expressed in 25 words (e.g., a multi-row table), use one of the other
   formats instead.
3. **`[source: title, page/timestamp]` tag** for unlinkable sources — paywalled articles,
   printed books without a digitized edition, offline interview transcripts, archived
   broadcasts, or proprietary databases. Include enough locator detail that a reader with
   the same access could find the passage: `[source: Piketty, Capital in the 21st Century,
   pp. 304–306]` or `[source: NPR Morning Edition, 2024-03-12, 07:42]`.

A single citation usually suffices. When a verdict rests on multiple sources, cite the
load-bearing one with one of the formats above and list the rest in the `Sources` line.
For Secondary-only quote verdicts, the citation should point to the strongest secondary
citation encountered, and the verdict explanation must still document the primary-source
searches that failed.

When no valid citation can be produced — the URL no longer resolves, the source is hearsay,
or you only have a general impression that the claim is right — do not invent one. Mark the
verdict **Unverified** with provenance `[assumed]` and say in the explanation what source
would be needed.

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
**Summary:** [X] accurate, [Y] mostly accurate, [Z] disputed, [W] inaccurate, [V] unverified, [U] secondary-only
**Provenance:** [A] observed, [B] inferred, [C] assumed
**Scrutiny:** [P] deep-read, [Q] abstract, [R] inferred
**Prioritization:** [L] load-bearing, [M] peripheral  (omit this line when N < 3 — see Pass 1 prioritization)

---

## Claims identified

The complete list of checkable claims extracted from the draft (Pass 1). Every verdict in the
sections below must reference one of these IDs; every ID listed here must have a matching
verdict section. Each entry carries its prioritization tag — `[load-bearing]` or `[peripheral]`
(see [Prioritize claims](#prioritize-claims-load-bearing-vs-peripheral)) — immediately after the
ID, except on drafts with fewer than 3 claims where prioritization is skipped and the tag is
omitted.

- **C1** `[load-bearing]` — "[short quoted snippet, ≤ 15 words]" (paragraph N / § "Section title")
- **C2** `[peripheral]` — "[short quoted snippet]" (paragraph N)
- **C3** `[peripheral]` — "[short quoted snippet]" (§ "Section title", paragraph M)
- …

---

## Verdict for C1: "[exact quote from draft]"

**Verdict:** [Accurate / Mostly accurate / Disputed / Inaccurate / Unverified / Secondary-only]
**Confidence:** [High / Medium / Low]
**Provenance:** [observed | inferred | assumed]
**Scrutiny:** [abstract | deep-read | inferred]

[2-4 sentences explaining what the evidence shows and why you reached this verdict. For
provenance `[inferred]` verdicts, write out the inferential chain. For provenance
`[assumed]` verdicts, state what specific evidence would move the claim to `[inferred]` or
`[observed]`. When confidence appears in tension with scrutiny (e.g., High confidence on
`[abstract]`-only reads), justify the call here.]

**Sources:** [named sources with years]
**Citation:** [exactly one of: URL with anchor | "verbatim ≤25-word span" | [source: title, page/timestamp]]
**Sources disagree:** [REQUIRED only when Verdict is Disputed — one sentence naming at least two source positions, e.g., "OECD's 2023 employment review reports a small negative effect, while CBPP's 2022 meta-analysis reports no measurable effect." Omit the line for all other verdicts.]

---

## Verdict for C2: "[exact quote from draft]"

...
```

Order the claims by their appearance in the draft, not by verdict severity and not by
prioritization tag. The load-bearing-first rule in Pass 2 governs the *verification sequence and
depth*, not the *report layout*: a `[load-bearing]` claim that appears as C5 is verified before a
`[peripheral]` C2, but it is still rendered fifth, after C2, in the report. Claim IDs (`C1`,
`C2`, …) are assigned during Pass 1 and reused verbatim as the keys of the verdict headings;
once assigned, they do not change.

At the end, include a summary section:

```
## Claims Requiring Author Attention

[List only the claims rated Mostly Accurate, Disputed, Inaccurate, or Unverified — each entry
references its claim ID (e.g., "**C3** — …") with a one-line explanation of what needs fixing
or sourcing. This is the actionable checklist.]
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

## Self-check: citation completeness

Before finalizing the report, scan every verdict for its **Citation** line and confirm each
one matches exactly one of the three formats defined in [Citation Requirement](#citation-requirement):

1. A URL with a section/anchor/page fragment (or a `path:line` for code claims).
2. A verbatim quoted span of 25 words or fewer, in quotation marks.
3. A `[source: title, page/timestamp]` tag with a locator concrete enough for an
   equivalently-resourced reader to find the passage.

A verdict that lacks a Citation line, carries a bare publisher name with no anchor, quotes a
span over 25 words, or uses a `[source: ...]` tag without locator detail is **rejected** —
rewrite it before the report goes out. If no valid citation can be produced for a claim,
change the verdict to **Unverified** with provenance `[assumed]` and explain in the verdict
body what source would be required.

This self-check applies to every verdict, including Secondary-only quote verdicts and
verdicts derived from code reads. Do not exempt any class of claim.

Also confirm the report header `**Summary:**` line tallies all six verdict types — accurate, mostly accurate, disputed, inaccurate, unverified, and **secondary-only** — so the prevalence of unsourced attributions is visible at a glance, not only inside "Claims Requiring Author Attention".

## Self-check: Disputed claims name both sides

Before finalizing the report, scan every verdict rated **Disputed** and confirm each one
carries a `**Sources disagree:**` line that:

1. Is a single sentence.
2. Names **at least two distinct source positions** (organization, study, or author on
   each side) — not just "sources disagree" or "evidence is mixed".
3. States, at minimum, who claims X and who claims Y, so the *structure* of the disagreement
   is visible, not only its existence.

A Disputed verdict missing this line, or carrying a `Sources disagree:` line that names
only one side or hand-waves with "various sources", is **rejected** — rewrite it before the
report goes out. If you cannot identify two distinct positions, the verdict is not
Disputed: re-rate it as **Unverified** with provenance `[assumed]` and explain what
evidence would be needed to establish the disagreement.

## Self-check: claim ID integrity

Before finalizing the report, audit the relationship between the `## Claims identified`
section and the per-claim verdict sections. The two-pass discipline only works if the IDs
on both sides line up exactly.

1. **Order:** the `## Claims identified` section must appear **before** any `## Verdict for
   C…` heading in the document. A report that emits a verdict before listing the claim is
   **rejected** — restructure so enumeration precedes verification.
2. **Every verdict references a claim ID.** Each verdict heading must take the form
   `## Verdict for C<N>: "[exact quote]"` where `C<N>` matches an entry in `## Claims
   identified`. A verdict heading that omits the `C<N>` reference, uses a different
   numbering scheme, or references an ID not present in the Claims identified list is
   **rejected**.
3. **No orphan IDs in verdicts.** Scan every `Verdict for C<N>` heading and confirm `C<N>`
   appears in the Claims identified list. If a verdict references an ID that was never
   enumerated, either add the missing entry to Claims identified (and re-number nothing —
   IDs are stable) or remove the spurious verdict.
4. **No missing verdicts.** Scan every ID in Claims identified and confirm it has a
   corresponding `Verdict for C<N>` section. An enumerated claim with no verdict is
   **rejected** — either produce the verdict (even if Unverified with provenance
   `[assumed]`) or strike the entry from Claims identified with a one-line rationale.
5. **IDs are stable.** Do not renumber claims after Pass 1. If a missed claim is found
   during Pass 2, append it with the next unused ID — never reshuffle existing IDs, since
   downstream readers and orchestrators may already be referencing them.

If any of these checks fail, fix the report before delivering it. ID integrity is the
spine of the two-pass approach; a report that breaks it is no more auditable than a
single-pass interleaved verdict stream.

## Self-check: load-bearing claims are a minority

Before finalizing the report, audit the prioritization tags assigned in Pass 1. The tag only
buys concentrated scrutiny if it actually discriminates — a report that tags most claims
load-bearing has re-created the uniform-budget problem prioritization exists to solve.

1. **Count the tags.** Let `N` be the total number of enumerated claims, `L` the number tagged
   `[load-bearing]`, and `M` the number tagged `[peripheral]`. Confirm `L + M = N` (every claim
   is tagged exactly once) — unless `N < 3`, in which case prioritization is skipped, no tags
   are present, and the `**Prioritization:**` header line is omitted.
2. **Enforce the minority cap.** Confirm `L ≤ floor(N/3)`. A report with more load-bearing
   claims than the cap allows is **rejected** — re-examine the over-cap tags, keep only the most
   thesis-critical as load-bearing, and re-tag the rest peripheral. `L` must also be a strict
   minority (`L < M`); if `L ≥ M`, the cap was miscomputed or the tags are miscalibrated.
3. **Confirm peripheral claims were still verified.** Every `[peripheral]` claim must have a
   `## Verdict for C<N>` section, exactly like load-bearing claims. "Verified later" never means
   "verified never." If a peripheral claim has no verdict, the [claim-ID integrity
   self-check](#self-check-claim-id-integrity) already rejects the report; this check is the
   reminder that the prioritization step does not license dropping the tail.
4. **Confirm the header tally matches.** The `**Prioritization:**` line's `[L]` and `[M]` counts
   must equal the tag counts in `## Claims identified`. A mismatch means tags were added or
   changed after the header was written.

If any check fails, fix the report before delivering it. The minority cap is what makes the
load-bearing tag a *signal* rather than a label everyone wears.
