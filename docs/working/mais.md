# Audience profile: MAIS issue posts

**Status:** ratified by the author 2026-11-17 (interview answers at the end). Drafted by the agent from evidence.
**Last verified:** 2026-11-17. **Venue:** issue threads on github.com/Math-for-AI-Safety/MAIS
(candidate solutions, progress, corrections). **Evidence read:** MAIS at `1cb9f00` (`STYLE.md`, `MAINTAINING.md`,
`CONTRIBUTING.md`, `contributing/{solutions,discussion}.md`, `open-problems/MAIS-O20.md`,
`open-problems/O62/MAIS-O62-progress-1.md`, `agendas/A1/PROVENANCE.md`); all 46 issues and their comments through
2026-11-17 (GitHub API); the saved C23 page and its comments
(`docs/human-author/papers/Modal Fixpoint Cooperation without Löb's Theorem — LessWrong.html`);
`docs/human-author/My Questions About Agency.md`; the author's questions in the 42 session transcripts still on
disk; memory notes `comprehension-questions-no-edits`, `mais-onramp-2026-10-09`.

**Refresh this profile when** MAIS changes `STYLE.md` or `MAINTAINING.md`, a reader on a thread does something
this profile did not predict, a reader-testing run's simulated reader disagrees with a real one, or the author's
own background moves (the enthusiast's knowledge boundary is the author's, and it shifts as they learn).

This profile describes **archetypes, never named people.** Named people appear only as cited evidence of what a
reader in that role has asked or done in public. A simulated reader is never briefed to be one of them.

## The venue

**What a post is for.** A post asks for a verdict and supplies the text of a record. A maintainer turns
verified progress into a page in the problem's folder, "stating what is proved, what is numerical, and what
remains open" (`MAINTAINING.md` §5), and a resolution page "sketches the argument so the page stands without
external links". So some paragraph of the post should be liftable into that page as it stands.

**The venue declares its own reader.** `STYLE.md` rule 2: "Write for one reader: a friendly colleague, curious but
slightly skeptical, smart but not in this field … For `open-problems/` in this repo, the one reader is an ILIAD
attendee: mathematically fluent and alignment-literate. Skip the safety catechism; spell out the mathematics."
And: "When guidelines collide, the reader wins." **Rule for this venue: write for the declared reader, and test
against the four archetypes below.** The declared reader is close to a blend of the maintainer (a fluent
mathematician) and the enthusiast (not in this field). When two archetypes' needs conflict, the declared reader
decides, and the other need moves to a layer (a footnote, a later section, the attachment) rather than being
dropped.

**Enthusiast material goes in the post**, as a short plain-terms paragraph (three to five sentences) near the top:
what the problem means in human terms and the intuition behind the result. This is what `STYLE.md` rules 3, 13
and 14 already ask for (open with a question, oscillate registers, a prose gloss for every formal statement).

**Norms that change how a post is read.**

- **The ten-minute screen** (`MAINTAINING.md` §2; `discussion.md` §2): good faith; "could a mathematician follow
  what is being claimed"; "does it bear on the problem *as stated* on its page". A post that fails the screen
  gets a short reply and waits. The opening is what the screen reads.
- **Status on every claim.** `solutions.md`: "label their status (e.g. 'numerical, not yet proved')". §3:
  "Silence is never verification: every claim … either gets a disposition or is listed as unchecked." `STYLE.md`
  rules 15–16: say where every statement stands; label heuristics.
- **Quantifiers.** "A counterexample must meet the statement's quantifiers … Read the verbatim statement on the
  problem page, not the summary in the issue."
- **Queue order** (`MAINTAINING.md`, "What to do first"): human-authored work with an external artifact comes
  first; work on which a machine check has already been posted comes second; "AI-generated candidate solutions
  with no independent check" come last and are screened first. A Lean attachment moves a post up the queue.
- **Negative outcomes go to the author privately first.** Positive ones are public.
- **The house avoid-list** (`STYLE.md` 17, 25, 26, 36): words over symbols in prose; no private jargon; no
  reflexive "gap", "clean", "load-bearing", "exactly"; no bullet-point prose outside genuine lists.

**What has actually happened on threads** (2026-11-17): 46 issues, 2 recorded (#1 O60, #2 O62), 42 or more
unscreened. Verdicts so far are short public notes by Lionel Levine, with an AI referee's confirmation and the
referee report sent by email (#1, #2). A volunteer formalizer posts a per-claim disposition table on many threads
(#3–#9, #12, #30): "✅ machine-checked, at print's quantifiers", "⚠️ architecture followed, final step replaced",
"❔ assumed", plus a count of the Lean lines "a human must read and judge". A contributor on #2 asked for the
p=7 code that the author's own 2026-10-16 comment promised and the zip lacked. Another (#42) wrote "I am working
on full understanding of the proof, whose methodology is a bit off my expertise."

## Archetype 1: the conjecturer

**Who.** The people whose question the problem is. For agenda problems there are two groups. The **posers**: MAIS-A1
was written by Claude Fable 5 under Lionel Levine's direction and audited by GPT 5.6 Sol (`agendas/A1/PROVENANCE.md`),
and the O20 page likewise. The **originators** of the underlying question: for O20, Critch (C19's bounded Löb
theorem; C23's write-up of Payor's lemma, and a comment there conjecturing "If ShortProof(x ↔ LongProof(ShortProof(x)
→ x)), then MediumProof(x)"), James Payor (the lemma, and a bounded agent sketched in C23's comments), Garrabrant
(who inspired C23's group-cooperation theorem), and BCFH+14 (FairBot).

**The question they bring.** The problem's own, in its own notation, and its motivating line. For O20: "Does the
cheaper route give a smaller cooperation threshold?", then the three parts (conditions on f, g with explicit
k̂; whether the certificates bλ ≤* g and f + bλ ≤* g suffice; PB_k's threshold and its comparison with k̂*),
and "a short, self-contained note tabulating the comparison against the bounded Löb route … would be a complete
first paper". On C23, a commenter asked Critch exactly this: "How does this affect your quest for bounded
analogues of Löbian reasoning?"

**What they know.** Everything in the agenda, and its notation. They need no background. They do need every new
object the post introduces defined at first use: structures, Lean names, new budgets, new agents.

**How they read.** Title, opening, theorem statements. They stop once they know the answer to each part and its
status. They read further only where the answer surprises them.

**What they do next.** Cite it, update the agenda or the problem page, or pose the follow-up as a new problem
(after O60, Levine posed O92 from the open question the resolution left).

**The worst misreading.** Taking a status for a different one: a conditional result read as unconditional, or a
negative result about one route read as a negative answer to the question. For O20, "no Payor-only argument proves
PB_k cooperates" read as "PB_k does not cooperate".

**Success test.** From the opening alone, they can answer each part of the problem as posed, give each answer's
status, and answer the motivating question.

**Task templates.**

- State the answer to each part of the problem, in the problem's notation, with its status.
- Answer the problem's motivating question in one sentence.
- Which of the problem's hypotheses or certificates did the post weaken, strengthen or reject?
- What follow-up problem does the post leave, and is it stated precisely enough to pose?

**Real readers available before posting.** None. After posting, their replies are evidence for the next refresh.

## Archetype 2: the maintainer

**Who.** Anyone who has to give each claim a disposition: the A1 area editor, Levine for the verdict, the
automated referee pipeline (an AI reader, `MAINTAINING.md` §3), and volunteer verifiers who formalize claims
independently.

**The question they bring.** Is this in good faith, can a mathematician follow it, does it bear on the problem as
stated? Then: what exactly is claimed, what is each claim's status, what is assumed, and can I check it?

**What they know.** The mathematics, fluently. Not necessarily Lean, and not this repo's library or its
abstractions. The volunteer verifier's tables count the Lean a human must still read, which says that Lean
statements are read and judged, not taken on trust.

**How they read.** In three passes. The **screen** reads the opening and the claim list for ten minutes. The
**verify** pass reads everything against the verbatim problem statement and its quantifiers, opens the
attachment, and runs it. The **record** pass lifts a stand-alone summary of what is proved, what is numerical
and what is open.

**What they do next.** Label the issue, ask for revisions on the thread, write the progress or resolution page.

**The worst misreading.** Over-reading scope (a claim taken to cover more than was proved), missing an
assumption because it sits in a different section, or an attachment that does not contain what the post says it
does (the #2 p=7 code request).

**Success test.** They can list every claim with its status and every hypothesis it rests on, from one place.
They can say which claims the attachment alone checks. They can write the progress page's three lists (proved,
numerical, open) without asking anything.

**Task templates.**

- List every claim and its status label.
- List every assumption the main theorem rests on that is not checked, and where each is stated.
- Which claims can be checked from the attachment alone, and how?
- Does each claim meet the verbatim problem statement's quantifiers? Name any that do not.
- Write the progress page's "proved / numerical / open" lists.

**Real readers available before posting.** None human. The automated referee is reproducible in spirit by an
adversarial subagent. That is a stand-in, not a calibration.

## Archetype 3: the enthusiast

**In this repo, the enthusiast is the author.** This section is per-repo, because who the author is as a reader
differs between repos.

**Who.** A trained mathematician outside logic, provability and agent foundations: an algebraic number theorist
(Hida families, per the MAIS on-ramp notes), who comes to MAIS problems through the questions in
`My Questions About Agency.md`. Those include which strategies achieve Pareto improvements over Nash equilibria,
and how finite agents behave ("our *selves* are also finite, needing to approximate profinite limits with some
limited precision"). The author also signs the post and answers on the thread.

**The question they bring.** What does this tell me about a question I care about? For O20: can two finite
agents that read each other's code cooperate, what does finiteness cost, and does Payor's shorter argument make
it cheaper? Also: do I understand this well enough to put my name on it and answer questions about it?

**What they know.** Graduate algebra and number theory. Definitions from other fields remembered only vaguely
("Remind me what an augmentation ideal is", 2026-10-29). Not, without a gloss: provability-logic notation (□ₐ,
Löb, Payor, necessitation), A1's cost model (λ, ≤*, d_S, 𝓔_S), the repo's Lean structures. As of 2026-11-17 the
author has read C23, Demski's probabilistic Payor post and the Kripke-frames post, so the Payor and Löb ideas are
newly familiar, but the bounded cost model is not.

**How they read.** Line by line, precisely. Evidence from their own questions:

- They stop at symbols that are not defined locally: "what is the variable 'c' in condition (16)?" (2026-10-22).
- They catch notation changes: "This is a change of notation; what are t and g?" (2026-10-29), and abuse of
  notation ("the letter p for a non-prime").
- They test the logic as they read: "doesn't that make it *not* a valid counterexample?" (2026-10-29); "Why is it
  *the* unit, rather than *a* unit?".
- They want each object's meaning: "is there a straightforward writeup of what λ is, and why it measures
  'simplicity'?".
- They build their own examples to test a claim against a human situation (the "billionaire game", 2026-10-23).
- They ask whether the writeup covers each case of a classification ("Does the writeup follow examples that are
  missing each one of the four options?", 2026-11-08).
- They ask definition questions even when the text states the definition, to be sure of what goes out under their
  name (memory `comprehension-questions-no-edits`). Those questions are a check on the author's own
  understanding, not edit requests.

**What they do next.** Decide whether to sign and post. Answer follow-up questions on the thread. Carry the result
back to their own questions.

**The worst misreading.** Carrying away a plain-language summary that is false (for O20: "the agents don't
cooperate"), or signing a claim they could not explain if asked on the thread.

**Success test.** They can explain the result in two or three sentences of their own words, say which human
question it bears on and how, name the claims they could check themselves, and answer the likely first question
on the thread.

**Task templates.**

- Explain the result to a mathematician friend outside the field, in two or three sentences.
- Which of your own questions does this bear on, and what does it say about it?
- Pick one symbol in the main theorem and say what it means and why it is there.
- What is the first question a reader on the thread is likely to ask, and what is the answer?
- Name one claim you could check yourself, and how.

**Real readers available before posting.** The author. Theirs is the session the simulated enthusiast is
calibrated against.

## Archetype 4: the builder

**Who.** A contributor who wants to extend the post: another solver, a volunteer formalizer, a student. Evidence:
on #2 a contributor asked for the p=7 code the author's comment promised, to build on it; #12 grew from one
contributor's Lean development into another's generalization to depth above 2.

**The question they bring.** What can I build on, and where do I start?

**What they know.** Varies: often in the field, sometimes adjacent ("a bit off my expertise", #42). Assume the
declared reader's background.

**How they read.** The open questions and the attachment first. Then the statements of the lemmas they might
reuse, and their exact hypotheses.

**What they do next.** Download and run the code, import the Lean, post a follow-up on the thread.

**The worst misreading.** Building on a claim whose status they misjudged. Or finding that the attachment does
not contain what the post promises (the #2 p=7 code).

**Success test.** They can name the open questions precisely enough to work on one, find each reusable lemma by
name with its hypotheses, and run the attachment from a fresh unzip.

**Task templates.**

- State one open question precisely enough to start work on it.
- Which named results could you reuse, and what are their exact hypotheses?
- From a fresh unzip, what do you run, and what output tells you it worked?
- Does the attachment contain everything the post says it does?

**Real readers available before posting.** None human. A subagent working from a fresh unzip with no repo access
is a reasonable stand-in for the attachment tasks.

**Not an archetype: the AI referee.** It is folded into the maintainer. It asks the maintainer's questions, only
more exhaustively, and a post written for it alone would be one no human could screen in ten minutes.

## Interview answers (2026-11-17)

1. **Primary reader:** write for `STYLE.md`'s declared reader (the ILIAD attendee), and test against the
   archetypes.
2. **Enthusiast content:** a short plain-terms paragraph in the post itself, near the top.
3. **The builder:** adopted as a fourth archetype.
4. **The enthusiast's knowledge boundary:** accurate as written, as of 2026-11-17.

## Notes for the skill

What this first run showed, for `audience-profiles` v1:

- **Check whether the venue declares its own reader before profiling anyone.** MAIS's `STYLE.md` does, and it
  sets the relationship between the write-for reader and the test readers.
- **The conjecturer may not be a person.** O20 was written by an AI under direction. The researchers who
  originated the question are a separate group, with different evidence (their papers and comments).
- **Thread behaviour is better evidence than stated norms.** The request for the missing p=7 code, and the
  disposition tables, say more about how posts are read than `MAINTAINING.md` does. Cheap to get: the
  unauthenticated GitHub API was enough.
- **The author's own questions are thin on disk.** Only 42 transcripts survive, and the 2026-10-15 O62
  proofreading session is not among them. `reader-testing` should append real readers' questions to this
  profile's evidence as they happen, rather than relying on transcripts.
- **The enthusiast's boundary moves.** It is the author's, and it shifts as they read. The profile needs a dated
  "as of" line, and a refresh trigger for it.
- **The interview was four multiple-choice questions, and the author took every recommended option.** That is
  some evidence the evidence-first draft got the recommendations right. It is also a warning: a draft can anchor
  the author. v1 of the skill should offer at least one option that departs from the draft, which this run did
  (for example, "leave the builder out").
- **The venue's evidence produced an archetype the author hadn't named** (the builder). The skill should always
  look at thread behaviour for readers missing from the author's list, not only check the author's list.
