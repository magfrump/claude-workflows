# Skill survey: exposition, structure, tutorials, simulated-reader testing

Nov 17, 2026 · @Mitchell Owen

The most useful finding: a group of nine simulated-reader skills already exists, and their development notes record which isolation and calibration rules survived contact with real use. Those rules matter more than any of the exposition style guides.

## Scope and method

This survey supports writing one skill of your own; nothing here is meant to be installed as-is. I cloned 21 repositories and read each SKILL.md with its reference files. I also mined `git log` bodies for developer notes, recovered deleted planning files from history, pulled issue threads through the GitHub search API, and read third-party reviews (tessl, a skillpacks report card).

- **Coverage:** the skills from the first search, plus a second group found by searching specifically for simulated-reader and persona-testing skills.
- **Model scratchpads:** I found two agent-authored working documents: haowjy's literature-review note ("I did not edit any repo source files") and first-reader's development ledger. Neither repo shares raw transcripts.
- **Gaps:** `meriley/claude-code-skills` (tutorial-writer) is a private repo. Issue comment threads are nearly empty: every relevant issue had 0 comments, so the discussion lives in issue bodies and commit messages. tessl doesn't publish its eval scenarios.
- **Confidence:** quotes and numbers come from files I read. Judgments marked with a percentage are my own hunches. Reported results (first-reader's fixture separation, #1718's 15/15) are the authors' own, not replicated by me.

## Corpus

I surveyed 26 skills (24 table rows) from 21 repositories. The richest source of lessons was rarely the SKILL.md itself; it was the development ledgers, commit bodies, deleted planning files, issue threads and third-party reviews.

| Skill | Area | Material beyond SKILL.md | Value to you |
| --- | --- | --- | --- |
| [first-reader](https://github.com/Shubhamsaboo/awesome-llm-apps/tree/main/agent_skills/first-reader) | Simulated readers | `evals/first-reader/ledger.md`: 6 dated dev rounds, fixtures, a cross-experiment against clarity | Highest |
| [reader-panel-review](https://github.com/tachyon-beep/skillpacks/tree/main/plugins/muna-panel-review) | Simulated readers | `ARCHITECTURE.md`, a 58 KB third-party review with behavioral tests, a report card, the pre-consolidation `process.md` in git | Highest |
| [dify-docs-reader-test](https://github.com/langgenius/dify-docs/tree/main/.claude/skills/dify-docs-reader-test) | Simulated readers | PR bodies #1041 and #1145 (dispatch scoping, translation test) | High |
| [review-docs](https://github.com/zernie/vigiles/blob/main/.claude/skills/review-docs/SKILL.md) | Simulated readers | A trigger eval in `examples/harness/dogfood/` | Medium |
| [writing-reader-feedback](https://github.com/plimeor/agent-skills/tree/main/skills/writing-reader-feedback) | Simulated readers | Sibling skill `writing-blog`, with the split stated explicitly | Medium |
| [reader-sim, cold-reader](https://github.com/haowjy/creative-writing-skills) | Simulated readers | `docs/research/reader-interest-second-pass.md`, an agent-written literature review that revised the skill | Medium |
| [doc-coauthoring](https://github.com/anthropics/skills/blob/main/skills/doc-coauthoring/SKILL.md) | Simulated readers, structure | Issues [#1718](https://github.com/anthropics/skills/issues/1718) (non-interactive failure) and [#2139](https://github.com/anthropics/skills/issues/2139) (knowledge map) | High |
| [reader-comprehension-pass](https://github.com/shubham0704/claude-skills/blob/main/reader-comprehension-pass/SKILL.md) | Simulated readers, math | Clearly distilled from one user's repeated complaints; README persona notes | High |
| [rigorous-paper-author](https://github.com/shubham0704/claude-skills/tree/main/rigorous-paper-author) | Math | `researcher_persona_loop.md`, `before_after_review_protocol.md` | High |
| [paper-discourse-graph](https://github.com/shubham0704/claude-skills/tree/main/paper-discourse-graph) | Math, structure | Audit CLI, per-audience profile JSONs, `paragraph_refinement_tasks.md` | High |
| [write-math](https://github.com/cboone/agent-harness-plugins/tree/main/plugins/write-math) | Math | 7 deep-dive references (\~120 KB), migration plan, repo-wide routing-description guide | Medium |
| [long-form-math](https://github.com/dashed/claude-marketplace/tree/master/plugins/long-form-math) | Math | 2 references (\~74 KB); commit history is housekeeping only | Medium |
| [diataxis (keithpatton)](https://github.com/keithpatton/diataxis-agent-skill) | Structure | Deleted `plans/*.plan.md` (Cursor planning file) recovered from git; tessl analysis issue #1 | Medium |
| [diataxis (oxide)](https://github.com/oxidecomputer/claude-plugins/tree/main/eng/skills/diataxis) | Structure | PR #2 body with test plan; `sync-upstream.sh` | Medium |
| [diataxis (joshuadavidthomas)](https://github.com/joshuadavidthomas/agent-skills/tree/main/diataxis) | Structure | 14 reference files; tessl eval summary (no scenario detail is public) | Low |
| [llm-wiki, cross-linker](https://github.com/Ar9av/obsidian-wiki/tree/main/skills) | Hypertext | `docs/adr/` (4 ADRs), lint tooling for provenance and dated claims | Medium |
| [obsidian-links](https://github.com/ericgandrade/obsidian-superskills/tree/main/skills/obsidian-links) | Hypertext | `evals/evals.json`, `evals/trigger-eval.json` | Medium |
| [code-walkthrough](https://github.com/dashed/claude-marketplace/tree/master/plugins/code-walkthrough) | Tutorials | Commit bodies (prose rules, dark-mode pitfalls), a "learned the hard way" section | High |
| [game-playtest (GameForge)](https://github.com/AlterLab-IEU/AlterLab_GameForge/tree/main/skills/workflows/game-playtest) | Playtests | v1.2 and v3.0 release notes; consent and remote-play references | High |
| [ux-audit](https://github.com/jezweb/claude-skills/tree/main/plugins/dev-tools/skills/ux-audit) | Walkthroughs | \~25 commits with reasons, `persona-lock.md`, `audit-output-discipline.md` | High |
| [cognitive-walkthrough](https://github.com/mastepanoski/claude-skills/tree/main/skills/cognitive-walkthrough) | Walkthroughs | Issue #9 and the fix diff that removed made-up percentages | Medium |
| [usability-testing](https://github.com/rampstackco/claude-skills/tree/main/skills/usability-testing) | Walkthroughs | PR #115 body (the honesty contract across 60 skills) | Medium |
| [clarity](https://github.com/addyosmani/clarity) | Editing (comparison) | `evals/JUDGE.md`, `cases.json`, `prose_stats.py` rationale | High |
| [game-playtest (OpenAI)](https://github.com/openai/plugins/tree/main/plugins/game-studio/skills/game-playtest) | Playtests | None; dangling references | Low |

## Lessons: audience profiling and simulated-reader testing

At least nine published skills already do some version of "profile readers, then test the draft against simulated ones." They agree that each reader needs a fresh context. They disagree on whether readers score the draft, suggest fixes, or only report what happened to them. The developer notes make clear that writing personas is the easy part; the hard problems are contamination and calibration.

| Skill | Profile input | Reading protocol | Output | Most transferable rule |
| --- | --- | --- | --- | --- |
| [first-reader](https://github.com/Shubhamsaboo/awesome-llm-apps/tree/main/agent_skills/first-reader) | 2 casts (sympathetic + skeptic), each with priors, patience budget and a one-sentence stake | Skim gate, then a no-lookahead feed server that releases one \~85-word passage per logged reaction, then a recall quiz from the log alone, then a trust ledger | Testimony only: attention strip, quit points, what survived recall. No scores, no fixes | "Quitting is a finding, not a failure"; without that framing, readers finish out of politeness |
| [reader-panel-review](https://github.com/tachyon-beep/skillpacks/tree/main/plugins/muna-panel-review) (muna) | A designer agent builds personas from the docs; tension archetypes | Per chapter: A = expectations saved *before* exposure, B = observations after, C = continue / skip / stop | Editorial *hypotheses*, each graded by confidence tier | A control persona with pre-registered predictions, plus an "unreliable narrator" who starts with a planted misconception |
| [dify-docs-reader-test](https://github.com/langgenius/dify-docs/tree/main/.claude/skills/dify-docs-reader-test) | Persona copied verbatim from the writing rule pack | Fresh subagent; gets file paths only, never pasted content | Got stuck at / Didn't understand / Missing context / Wanted but didn't get / Verdict | Never send a revised draft to the same reader; never tell a reader what changed |
| [review-docs](https://github.com/zernie/vigiles/blob/main/.claude/skills/review-docs/SKILL.md) (vigiles) | 5–6 fixed personas (newcomer, power user, skeptical staff engineer, decision-maker…) | Parallel cold reads on a cheap model | x/5 score, a 30-second test, a jargon check, what works, the one change | "Lowest score is the ceiling"; capped at about 3 rounds of fixes |
| [writing-reader-feedback](https://github.com/plimeor/agent-skills/tree/main/skills/writing-reader-feedback) (plimeor) | A Reader Model block with Knows / Does not know, written before any body text | Section by section; never use later content to repair an earlier reaction | Per section: expectation, expectation shift, confusion, lack of interest, emotion | "It is better to be too confused than too understanding" |
| [reader-sim + cold-reader](https://github.com/haowjy/creative-writing-skills) (haowjy) | Persona plus an explicit knowledge boundary | Five "reader reward channels", revised by a literature-review note in `docs/research/` | Moment-by-moment felt experience | cold-reader runs on Haiku and gets "only the paths and who reads each one … no labels from \[the work\], even as examples" |
| [doc-coauthoring](https://github.com/anthropics/skills/blob/main/skills/doc-coauthoring/SKILL.md) (Anthropic) | Stage 1 asks who the audience is and what the desired impact is | Predicts 5–10 questions readers would ask; one fresh subagent per question | What "Reader Claude" got right or wrong | Exit when answers are consistently correct and no new gaps appear |
| [reader-comprehension-pass](https://github.com/shubham0704/claude-skills/blob/main/reader-comprehension-pass/SKILL.md) | An audience brief | The fresh reader retells the problem, insight, essential operation and finding | Where the text supplied each prerequisite | Repair the *first causal gap* before adding more definitions |
| [ux-audit Persona Lock](https://github.com/jezweb/claude-skills/blob/main/plugins/dev-tools/skills/ux-audit/references/persona-lock.md) (jezweb) | Persona file: who / goals / constraints / pain triggers / wins / how to audit AS them | One persona per pass, then a synthesis pass | Findings marked KEEP / DUPLICATE / GENERIC by a fresh agent | Watch for drift: "a developer would know…" means the persona has slipped |

**Profiling**

- **Your goals/failure/success framing already exists as a schema.** jezweb's persona file has *Goals*, *Pain triggers (what makes them close the tab)*, *Wins (what makes them come back)*, plus concrete audit moves ("read every label out loud: would she say this word?"). Add plimeor's Knows / Does not know and first-reader's patience budget and stake sentence, and you have the full profile.
- **The stake sentence needs teeth.** From first-reader's ledger, round 1: without one, a sympathetic reader's "wanting it to be good decays into rating it good."
- **Cast for tension, not coverage.** muna's priority archetypes: the person talked *about* but not *to*, the decision-maker, the hostile reader, the technical validator. Its claim: four personas built this way beat thirteen that sit in similar positions.
- **Keep the cast fixed across drafts.** first-reader writes `audience.json` so reader "S" is the same person next month. That is what makes "last time S left at passage 4; this time she finished" a meaningful comparison.
- **Always add a first-time reader as well.** jezweb calls it "the single biggest blind spot for AI / internal tooling"; the commit adding it came from raw internal identifiers left exposed in a form.

**Contamination**

- **The reader gets the text and the persona, nothing else.** dify lists what invalidates the test: what the page covers or why it was written, source material, links to other docs or the glossary, and the orchestrator's own concerns about the draft.
- **No-lookahead takes mechanism, not politeness.** Three levels of enforcement exist. plimeor relies on instructions. muna adds the Step A gate (a reader who has already read ahead cannot write a genuine prediction) and restricts readers to Read/Write tools. first-reader adds a loopback server that holds the text in memory and won't serve faster than a person could read.
- **The orchestrator gets contaminated too.** first-reader's round 2 found that running its own skim script exposed draft fragments to the coordinator. The fix: subagents run the scripts, or the output goes to a file nobody opens.
- **The counter-lesson.** jezweb's execution-discipline commit says to run the audit from the main session because "sub-agents start cold and miss second-order findings." My resolution (hunch, 75%): use cold readers for comprehension, where ignorance is the point, and the warm session for anything stateful.

**Calibration**

- **Fixtures with known ground truth.** first-reader built two opposite drafts: `hollow-clean.md` passes every anti-slop rule but commits to nothing; `human-tells.md` is full of surface tells but specific. The readers separated them, and nobody flagged an em dash. A cold end-to-end run then recovered a hidden "strong open, marketing middle" construction that the orchestrator never saw.
- **Reruns and miscasts.** An independent rerun of the skeptic quit at the same passage for the same class of reason. A deliberately miscast reader skimmed the math but finished, which tells you a problem is about audience fit rather than the draft.
- **Pre-registered control persona** (muna). Predict the target reader's path, main concern and verdict before the run. A match raises confidence in the panel. A plausible divergence may be the most valuable finding. An implausible one means you should downweight similar personas.
- **Convergent reasons, not just conclusions.** If one persona's justification could be swapped into another's entry and still read naturally, the agreement "is likely a single model prior expressed in different vocabulary."
- **Confidence tiers.** Text-surface findings (vocabulary, structure, broken expectations) are the most reliable; affective findings are the space of possible reactions, not predictions; institutional findings are prompts for human judgment. Key observation: "LLM personas are more articulate about confusion than real readers, who simply stop reading."
- **Symmetric prompts.** Never hint to a reader that the draft is bad or that it is good; the persona and patience budget should be the only pressure (first-reader, round 1).

**Output, numbers and stopping**

- **Scores split the field.** vigiles scores x/5 with a harsh-grader prior ("most READMEs are a 3"). first-reader and clarity refuse composite scores; clarity's stylometric composite came out *inverted* on a human control. mastepanoski removed made-up success percentages after [issue #9](https://github.com/mastepanoski/claude-skills/issues/9). For your preference for explicit probabilities: state them as the evaluator's credence about this run, never as population rates. muna: "Counts describe this run's outputs only."
- **Readers report; they don't prescribe.** first-reader added fixes in round 4 and removed them in round 6, because "every fix path put the skill in the writer's chair." Readers now answer "what would have had to be true for it to go differently." dify filters fixes that add text with one test: would this reader, at this point, do anything differently with it? That test also guards against bloat from reader feedback.
- **Stop rules.** doc-coauthoring stops when answers stay correct; vigiles after about 3 rounds without improvement; first-reader "when the peak, the recall, and the quit points stop moving" (it converged by read 4 of 5 on a 2,100-word essay, about 8 minutes per read).
- **Ask goal-level questions.** Pose tasks as user goals rather than system actions (rampstack), ask for a retelling rather than a lookup (reader-comprehension-pass), and write questions the reader would actually bring (doc-coauthoring). GameForge's per-question *positive signals*, *negative signals* and *observation window* is the cleanest format for a success/failure spec.
- **The outside skeptics.** UX practitioners frame synthetic users as preparation for real testing, not a substitute; agents follow tidy paths where people wander. GameForge: AI agents "have no expectations to violate … They cannot measure first impressions." first-reader is effectively an attempt to rebut this for text; its evidence is suggestive, not conclusive (my estimate: 60%).

## Lessons: mathematical exposition

The math skills agree on content (example before generality, typed variables, words between equations) but contradict each other on register, because each bakes in one fixed reader. That is the strongest argument for making the audience profile a parameter rather than a constant.

- **Register conflict is real and specific.** `long-form-math` targets an intro-proofs student: direct address ("You will thank me later"), enthusiasm, and a rule to *vary* connectives (therefore / thus / hence). `write-math` targets "a graduate student beginning studies in the field" and says "repetition beats synonym-hunting." `code-walkthrough` independently sides with write-math: "Do not change the word for variety, because the reader will think that a new word is a new thing." Hunch (70%): for research-level readers the write-math rule wins; for novices the variation rule is mostly harmless, so let the profile select it.
- **Audience calibration vs detail calibration** (write-math, `reader-centered-writing.md`). Who you write for and how much you expand each step are separate decisions. The second fails more often: "authors tend to overexpose the material they know best and skim the material they consider obvious." This is a directly testable failure mode for a simulated reader.
- **Ledgers before prose** (`rigorous-paper-author`). It builds a claim graph and a notation ledger before drafting sections, and its persona loop keeps four ledgers: claim, reader-state, formal, evidence. The reader-state ledger ("what the reader knows now, what question they are carrying, what payoff they need next") is the closest existing thing to a per-paragraph reader model.
- **The formal-block loop** (`paper-discourse-graph`): paragraph motivates the need → notation names the object → the equation commits → a paragraph interprets what changed. Its risk labels make the loop checkable: `premature_notation`, `missing_formal_setup`, `missing_formal_payoff`, `symbol_scope_debt`, `symbol_alias_confusion`. Thresholds (16 symbols per block, 7 new symbols) live in a per-audience profile JSON, not in the engine.
- **Three-phase proofs** (`long-form-math`): scratch work and technique choice → the proof → the "moral", a simpler proof, or how the polished version came from the scratch work. Two devices worth stealing: the *almost-correct proof* (show a failing attempt and diagnose it) and *investigation tables* with "???" cells filled in as the text goes on.
- **Counterexamples justify hypotheses** (write-math, after Pak): show what breaks without each assumption. This doubles as a test: a simulated reader who can't say why a hypothesis is there has found a gap.
- **Plain language must not change the claim** (`reader-comprehension-pass`). Simplifying for a reader is not allowed to weaken or shift the mathematical or empirical statement. Write this in as an explicit invariant for any rewrite loop.
- **Low value for you:** `lingzhi227/math-reasoning` is LaTeX scaffolding (notation tables, proof templates) with no reader model.

## Lessons: structure, hypertext, Diátaxis

The Diátaxis compass works as a two-question reader-state classifier: does the reader need to act or to know, and are they studying or working? That makes it a ready-made axis for an audience profile, not just a filing system for documents.

- **The compass as profiling questions.** keithpatton's deleted planning file (recovered from git history) lists "Content Shaping Questions" to ask before generating: "Is the reader at study or at work? Is the goal learning or task completion? Should content inform action or cognition?" These are audience questions, asked before any writing.
- **Classify first, with confidence and evidence.** keithpatton won't generate until the target type is either stated by the user or inferred and confirmed. Every classification reports high, medium or low confidence and quotes the phrases it rests on. It also counts "refusal with explanation" as a success when a request would blend types.
- **Dogfooding catches leaks.** keithpatton's third commit: "Self-audit identified Reference documents with How-to bleed; now pure Reference." The skill was run against its own reference files and found mode mixing. Run your skill on its own docs.
- **Ship the primary source, not a summary of it** (oxide). The skill prompt is about 2k characters (the compass and one paragraph per type), then sends the agent to read the relevant page of the Diátaxis RST source, vendored as a git subtree with a `sync-upstream.sh`. The key line: "Study the source not just for what it says, but for how it's written." The Diátaxis site follows its own rules, so it works as a style exemplar as well as a spec. For you, the equivalent would be bundling a few exemplar expositions alongside the rules.
- **Progressive disclosure by type** (joshuadavidthomas): one reference file per type plus separate files for the confusable pairs (tutorials vs how-to, reference vs explanation). The confusions get their own files because that's where agents err.
- **Links as typed claims** (Ar9av/obsidian-wiki `llm-wiki`). Plain `[[wikilinks]]` mean only "related". An optional `relationships:` block adds direction and a type (`extends`, `implements`, `contradicts`, `derived_from`, `uses`, `replaces`), and the rule is: only declare a type when the source makes it clear. `obsidian-links` frames linking as information architecture: every link is an intentional relationship.
- **Provenance markers per claim** (`llm-wiki`). Each claim is unmarked (extracted from a source), `^[inferred]` (LLM synthesis) or `^[ambiguous]` (sources disagree), with an optional per-page fraction in frontmatter that a linter recomputes. Also: "Date anything that changes"; undated counts are flagged as `undated_claims`. This maps directly onto your confidence-level and wiki-summary conventions.
- **Split, don't cut** (`code-walkthrough`). When a document gets too long, split it into a cross-linked series; don't shorten the explanations. Each part gets a chain-map diagram with the current part highlighted.
- **Evals for a hypertext skill exist** (`obsidian-links/evals/`): `evals.json` holds prompt, expected output and checkable expectations ("No other text is modified"), and `trigger-eval.json` holds should-trigger and should-not-trigger queries. Of the skills surveyed here, only ericgandrade's Obsidian skills ship eval sets; \`rigorous-paper-reviewer\` has unit tests for its notation-checker script only.

## Lessons: tutorials, walkthroughs and playtests

The playtest and walkthrough skills carry the most mature method for *testing against an audience*, because usability research had protocols long before LLMs. Most of their rules carry over to reading with one substitution: a passage is a screen.

**Tutorials and code walkthroughs**

- **Verify before teaching** (`code-walkthrough`, dashed). Its Phase 2 exists because agent reports "are leads, not facts." The two classic failures it names: a plausible but wrong mechanism ("the setting lives in an org option", actually a model column) and an unverified count ("12 tests", actually 7).
- **Trace one real value end to end.** Follow one request, row or event through every mechanism, using test values where they exist.
- **Restate facts; don't trust the reader's memory.** When a section reuses an earlier fact, restate it in one sentence and link to where it was taught. This is the hypertext version of write-math's "distant-definition problem."
- **Spiral order:** hero → a 30-second version → foundations → per-unit walkthroughs → end-to-end flows → scope boundaries (what the change deliberately does *not* do) → reviewer checklist → glossary.
- **"A style rule must not delete a fact"** (added on 2026-11-16 with the Simplified Technical English rules). Short-sentence rules make sentences shorter, not explanations: "If an explanation needs 60 words, write three sentences of 20 words."
- **Look at the rendered output.** "Rendering bugs hide in screenshots, not in DOM assertions": take screenshots in light and dark mode and look at them. Also: never edit a file the user currently has open; write a new one and cross-link.
- **Diátaxis tutorial rules** (joshuadavidthomas): one path, no alternatives, visible results early and often, "aspire to perfect reliability." The `tutorial-docs` skill builds everything around "you should see …" checkpoints. I couldn't retrieve `meriley/tutorial-writer`: its repo needed authentication.

**Playtests and walkthroughs (map "screen" to "passage")**

- **Questions before testers** (AlterLab GameForge). Every round answers 3–5 questions, each observable, actionable and scoped. Each question gets positive signals, negative signals and an observation window. "Is it fun?" is not a question; "do players use the dodge roll unprompted in the first two encounters?" is.
- **Behavior outranks words.** "'The controls feel fine' plus 11 wrong-button presses in ten minutes is a controls finding." The reading equivalent: a reader who calls a section clear but then misstates its claim in recall has given you the finding.
- **A hint contaminates what follows.** One neutral hint is allowed; log it and mark all later data as contaminated. Apply the same rule to any clarification given to a simulated reader.
- **The team is not the sample.** "The team cannot un-know the game." This is the playtest version of the fresh-context rule.
- **Analysis rules.** Wait until every session is done so the last tester doesn't dominate. Build a moments × testers matrix. A pattern in 3 or more testers is systemic; a single tester gives you a lead. Track each finding across rounds as Fixed / Improved / Unchanged / Regressed. "Problems that survive two fix attempts are structural."
- **Validate a summarizer before trusting it.** Hand-code 50–100 real items, run the tool, and compare which themes it missed and which it invented. This is the template for validating your simulated readers against a few real ones.
- **Cognitive walkthrough's four questions** (mastepanoski) apply to each action: will the user try for the right effect, notice the action, connect it to the effect, and see that they made progress? For each paragraph, read them as: does the reader know what this passage is for, see the move, connect it to their goal, and feel they've advanced?
- **Guard against faked audits** (jezweb `ux-audit`). It requires an Interaction Manifest. A meta-check sets the verdict to *Incomplete* if entries are clustered under 0.5 s apart or there are fewer than 2 screenshots per route. A PASS needs proof; "It looked OK" is not Pass. The reading equivalent: require each reader's log entry to quote the passage it reacts to.
- **Self-critique goes to a fresh agent.** "Self-critique done in-context tends to defend rather than prune." A fresh subagent marks each finding KEEP / GENERIC / DUPLICATE, where GENERIC means it would apply to any app and any persona.
- **Loop to exhaustion, with variation.** Each pass uses a different persona, workflow or input. Stop only when a full pass finds nothing new.
- **Failure patterns** (rampstack `usability-testing`): tasks that reveal the path, defending the design when participants struggle, and "treating participant suggestions as features." The last one is the same lesson as first-reader's "readers never say what to write."
- **Weak example:** OpenAI's `game-playtest` is a 3 KB checklist whose References section points outside the bundle (tessl flags this). It has no method to borrow.

## Cross-cutting lessons about skill design

The developer notes agree on one pattern: skills get better when a failure is written down as a rule with its provenance, and worse when instruments pile up faster than the runnable path. Two outside measurements suggest much of a writing skill's text restates what the model already knows.

- **Interactive workflows fail silently when nobody can answer.** [anthropics/skills #1718](https://github.com/anthropics/skills/issues/1718) ran doc-coauthoring 30 times. In all 15 runs where the skill engaged, no file was written; in all 15 where it didn't, the file was written. A closing paragraph that asks for a file also halved how often the skill engaged. The proposed fix: when the context is already supplied or a destination is named, write a draft and put the open questions *inside the document*. Your skill will ask audience questions first, so it needs this branch.
- **Spend tokens on contracts, not common knowledge.** [anthropics/skills #2139](https://github.com/anthropics/skills/issues/2139) probed 398 facts from 16 SKILL.md files. Without the skill, Haiku 5.5 answered 54% and Sonnet 5.5 answered 64%. doc-coauthoring was 72% known to both. What the models lacked were *contracts*: file names, thresholds, orderings, output locations. Caveat from the author: this measures knowledge, not behavior. The Diátaxis skills' tessl impact numbers (1.08× and 1.10×) fit the same story; my estimate is 65% that this means "the model already knows Diátaxis".
- **Routing descriptions are their own craft** (cboone `docs/plugin-development.md`): open with the primary action, name trigger phrases, state a negative boundary against neighboring skills, and keep it short (a warning above 240 characters, a failure above 1,024). They over-tightened once and then had to "restore situational triggers to implicitly used skill descriptions." Test routing with should-trigger and should-not-trigger cases (`obsidian-links/evals/trigger-eval.json`).
- **Record rules with provenance.** first-reader's ledger: "feedback stays feedback until it generalizes into a rule, and rules carry their provenance so stale ones can be found and pruned." jezweb's commit: "Fix landed there; rule lands here so it doesn't reopen." Your Claude Code self-improvement loop could adopt this ledger format directly.
- **Keep the interface small however rich the engine is.** first-reader, round 4: "every instrument you add will try to climb into the user's lap. The engine can be arbitrarily rich only if the interface stays two phrases and one page." muna's roughly 1,130-line `process.md` was faulted in its own report card for "surface area that exceeds the runnable path" and was cut in the 2026-10-09 consolidation.
- **Separate the chairs, with different contamination rules.** Editor and reader are different roles: clarity versus first-reader, and plimeor's `writing-blog` versus `writing-reader-feedback`. In muna the persona designer and synthesizer may read the full text but are "explicitly barred from *predicting behaviour* from it."
- **Disclose when you degrade.** rampstack added one identical "If required data is unavailable" block to 60 skills: "Fabricating, estimating, or interpolating a required number … is never sanctioned. A stated gap is a complete answer." Without subagents, first-reader says "I played both readers myself here, so treat the findings as slightly softer," and muna labels the run a single-context review.
- **A blinded eval protocol exists to copy** (clarity `evals/JUDGE.md`). Freeze the model and settings, use a fresh context per case, run at least 2 times in random order, strip condition names, keep a holdout set, and report hard gates (invented or strengthened facts, wrong mode) separately: "A fluent fabrication must not win on an average score." Never use an AI-text detector as the judge.
- **Dogfood on your own artifacts.** keithpatton audited its own reference files and found how-to mixed into reference. first-reader ran its readers on clarity's before/after samples and caught a leaked editorial sentence ("The source draft does not explain …") that clarity's own process had shipped.
- **Use scripts for objective checks, framed as triage.** rigorous-paper-reviewer ships a notation checker with unit tests; paper-discourse-graph says "treat the graph as triage, not truth"; code-walkthrough flags sentences over 25 words with a script. Keep judgment calls for the model and countable things for code.

## Implications for your skill

Your two-stage model (profile the audience, then write against simulated readers) is the same shape as first-reader and muna, which both iterated their way to it. The parts worth taking from them are the isolation mechanisms, the calibration controls and the testimony-only output, more than any particular persona. Below is a proposed skeleton; each step names its source.

**Roles and what each may see**

- **Profiler and Author** (warm session): may read everything.
- **Readers** (fresh subagents): get only the persona and the text, released one section at a time.
- **Synthesizer** (fresh): may read everything, but may not predict reader behavior from the text (muna).
- **Claim checker**: confirms that every rewrite keeps the original claim (reader-comprehension-pass, clarity hard gates).

**Loop**

1. **Mode check.** If nobody can answer questions, or the context is already supplied, draft right away and put the open audience questions inside the document (#1718).
2. **Profile each segment** as a persona file with these fields: knows / does not know; the question they bring; a stake sentence with teeth; patience budget; pain triggers (failure modes); wins (success modes); register. Register selects which math-writing rule set applies (write-math vs long-form-math). Optionally add a planted misconception.
3. **Cast for tension.** Pick 2–4 personas from muna's archetypes, plus one control persona whose path, concern and verdict you pre-register, plus a first-time-reader lens. Persist the cast to a file so readers stay the same across drafts.
4. **Write the success spec before drafting.** Per persona: 3–5 observable questions, each with positive signals, negative signals and the sections where it should be answered (GameForge). Also state the intended gist that recall will be judged against (first-reader).
5. **Draft with ledgers.** Keep a claim graph, a notation ledger and a reader-state ledger (rigorous-paper-author). Follow the formal-block loop: need, name, commit, interpret (paper-discourse-graph). Give an example before any general statement.
6. **Run the cold read.** Readers get file paths only and go section by section. Before each section they write expectations (Step A). Every log entry must quote the passage it reacts to. They are told quitting is a finding, and the prompt never hints whether the draft is good or bad. Then: recall from the log alone, plus a retell of problem, insight, operation and finding.
7. **Synthesize.** A fresh agent marks findings KEEP / GENERIC / DUPLICATE, runs the convergent-reasons test, tags each finding text-surface, affective or speculative, and checks the control persona against its prediction. Findings are hypotheses; any probability is credence about this run.
8. **Revise as the author.** Readers only testify. Admit added text only if "this reader, here, would do something differently." Repair the first causal gap first. Use new readers after every revision. Track each finding as Fixed / Improved / Unchanged / Regressed.
9. **Stop.** Stop when quit points, the peak and recall stop moving, or after 3 rounds without improvement. Then check one or two real readers against the simulation, using GameForge's summarizer-validation template.

**For building the skill itself**

- Keep a dated ledger, with provenance, for every rule you add.
- Build two opposite fixtures, a hollow-but-clean exposition and a specific-but-rough one, and require the readers to separate them.
- Adopt clarity's blinded protocol to evaluate the skill.
- Your case study can serve as the first fixture: the result you're posting, the simulated readers' transcripts, and later the real readers' comments as ground truth.

**Open questions**

- Scores or testimony? My lean (60%): pass/fail per observable question, since your questions are observable, and testimony for everything else, with no composite score.
- Staged no-lookahead or whole-document reads? Staged costs more but is the only way to measure broken expectations and quit points. Mathematical exposition, where order carries the argument, seems like the case where it pays (70%).
- How many real readers do you need to calibrate? GameForge's rule of thumb: about 5 per homogeneous segment for qualitative problems; below about 20, report counts, not percentages.

## Sources

Primary files read directly (cloned, at HEAD as of 2026-11-17):

- [first-reader SKILL.md](https://github.com/Shubhamsaboo/awesome-llm-apps/blob/main/agent_skills/first-reader/SKILL.md) and [development ledger](https://github.com/Shubhamsaboo/awesome-llm-apps/blob/main/agent_skills/evals/first-reader/ledger.md)
- [reader-panel-review SKILL.md](https://github.com/tachyon-beep/skillpacks/blob/main/plugins/muna-panel-review/skills/reader-panel-review/SKILL.md), [ARCHITECTURE.md](https://github.com/tachyon-beep/skillpacks/blob/main/plugins/muna-panel-review/ARCHITECTURE.md), [review](https://github.com/tachyon-beep/skillpacks/blob/main/reviews/muna-panel-review.md), [report card](https://github.com/tachyon-beep/skillpacks/blob/main/reviews/report-cards/muna-panel-review.md)
- [dify-docs-reader-test](https://github.com/langgenius/dify-docs/blob/main/.claude/skills/dify-docs-reader-test/SKILL.md)
- [vigiles review-docs](https://github.com/zernie/vigiles/blob/main/.claude/skills/review-docs/SKILL.md)
- [plimeor writing-reader-feedback](https://github.com/plimeor/agent-skills/blob/main/skills/writing-reader-feedback/SKILL.md)
- [haowjy reader-sim](https://github.com/haowjy/creative-writing-skills/blob/main/plugin/claude/skills/reader-sim/SKILL.md), [cold-reader](https://github.com/haowjy/creative-writing-skills/blob/main/plugin/claude/agents/cold-reader.md), [research note](https://github.com/haowjy/creative-writing-skills/blob/main/docs/research/reader-interest-second-pass.md)
- [doc-coauthoring](https://github.com/anthropics/skills/blob/main/skills/doc-coauthoring/SKILL.md); issues [#1718](https://github.com/anthropics/skills/issues/1718) and [#2139](https://github.com/anthropics/skills/issues/2139) (bodies read via the GitHub search API)
- [shubham0704/claude-skills](https://github.com/shubham0704/claude-skills): `reader-comprehension-pass`, `rigorous-paper-author` (with `references/researcher_persona_loop.md` and `before_after_review_protocol.md`), `paper-discourse-graph`
- [write-math](https://github.com/cboone/agent-harness-plugins/tree/main/plugins/write-math), [plugin-development.md](https://github.com/cboone/agent-harness-plugins/blob/main/docs/plugin-development.md)
- [long-form-math](https://github.com/dashed/claude-marketplace/blob/master/plugins/long-form-math/skills/long-form-math/SKILL.md), [code-walkthrough](https://github.com/dashed/claude-marketplace/blob/master/plugins/code-walkthrough/skills/code-walkthrough/SKILL.md)
- Diátaxis: [keithpatton](https://github.com/keithpatton/diataxis-agent-skill) (plus its deleted plan file, from git history, and [issue #1](https://github.com/keithpatton/diataxis-agent-skill/issues/1)), [oxide](https://github.com/oxidecomputer/claude-plugins/tree/main/eng/skills/diataxis), [joshuadavidthomas](https://github.com/joshuadavidthomas/agent-skills/tree/main/diataxis)
- [llm-wiki](https://github.com/Ar9av/obsidian-wiki/blob/main/skills/llm-wiki/SKILL.md), [obsidian-links + evals](https://github.com/ericgandrade/obsidian-superskills/tree/main/skills/obsidian-links)
- [GameForge game-playtest](https://github.com/AlterLab-IEU/AlterLab_GameForge/blob/main/skills/workflows/game-playtest/SKILL.md), [OpenAI game-playtest](https://github.com/openai/plugins/blob/main/plugins/game-studio/skills/game-playtest/SKILL.md)
- [ux-audit](https://github.com/jezweb/claude-skills/blob/main/plugins/dev-tools/skills/ux-audit/SKILL.md), [persona-lock.md](https://github.com/jezweb/claude-skills/blob/main/plugins/dev-tools/skills/ux-audit/references/persona-lock.md)
- [cognitive-walkthrough](https://github.com/mastepanoski/claude-skills/blob/main/skills/cognitive-walkthrough/SKILL.md), [issue #9](https://github.com/mastepanoski/claude-skills/issues/9)
- [rampstack usability-testing](https://github.com/rampstackco/claude-skills/blob/main/skills/usability-testing/SKILL.md)
- [clarity](https://github.com/addyosmani/clarity): [JUDGE.md](https://github.com/addyosmani/clarity/blob/main/evals/JUDGE.md), `scripts/prose_stats.py`

Secondary sources (the first two seen only as search snippets; the tessl page opened, but it shows no scenario detail): [userbrain synthetic-users experiment](https://userbrain.com/blog/synthetic-users-experiment/) (the source of the UXAgent / CHI 2025 summary), [What Would GPT Click (arXiv 2605.18302)](https://arxiv.org/pdf/2605.18302), the [tessl diataxis evals page](https://tessl.io/registry/skills/github/joshuadavidthomas/agent-skills/diataxis/evals).
