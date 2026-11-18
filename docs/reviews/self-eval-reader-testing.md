# Self-Evaluation: reader-testing

**Target:** `skills/reader-testing/SKILL.md` (with `references/reader-brief.md`, `references/grader-brief.md`, `references/run-templates.md`) | **Type:** Skill | **Evaluated:** 2026-11-17
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | The output is structured: pass/partial/fail per task against a ●/○ key, S1–S4 severities, KEEP/GENERIC/DUPLICATE marks, and CONFIRMED/PLAUSIBLE/CLEARED for Part A. So a fixture with planted defects (an undefined term, an overreaching claim, a wrong build time) can be checked mechanically for detection. But whether the findings are useful, and whether the convergent-reasons test is applied honestly, still need human judgment. Each run is also expensive: about 530k subagent tokens in the pilot (SKILL.md:114-115). The planned fixture pair (change 11 in `audience-skill-notes.md`) is not built. |
| Trigger clarity | Adequate | The description names concrete phrases ("reader-test this", "simulated readers", "re-run the reader test") and draws the line against `draft-review`. But "would a maintainer follow this" is close to `ai-personas-critique`'s "what am I missing / multiple angles" ground, and nothing separates it from `user-testing-workflow` ("user test"). A plain "will readers understand this post?" would probably route to `draft-review`. |
| Overlap and redundancy | Strong | No other skill runs task-based comprehension tests against a key written from the source of truth, with staged release, recall, calibration against a real reader and a correctness lane that blocks posting. `ai-personas-critique` gives objections, not task pass/fail. `draft-review` critiques the argument. `fact-check` and `code-fact-check` are reused as verifiers, not duplicated. |
| Test coverage | Weak | The skill has never been run. There are no tests under `test/` and no artifact under `docs/reviews/`. The only git hit is the pilot-inputs commit `e4ddf3c8`. The O20 hand pilot (`docs/working/o20-2026-11-17/`) is evidence for its predecessor protocol, not for this text: the fresh grader, the fresh verifier, staged release by `SendMessage`, recall and the claim-preservation gate are all new and unexercised. The notes say so (`audience-skill-notes.md:19-21`). |
| Pipeline readiness | Adequate | It runs on its own once a profile exists, and its one `requires`, `audience-profiles`, ships alongside it. But that sibling is also unrun, `docs/audiences/` does not exist anywhere yet (the MAIS profile is still at `docs/working/mais.md`), and no orchestrator composes either skill. It relies on `fact-check`/`code-fact-check` as verifiers without a mapping of their verdicts (see Key Questions). |

---

## Flagged for Human Review

### Counterfactual Gap

- **What the tool does:** It freezes a draft and splits it at its headings. It writes goal-level tasks per archetype from a venue profile, and a key from the source of truth rather than the draft. It pre-registers predictions for real readers, then runs one fresh subagent per archetype with staged release (blind cut first, then each section copied in, with the agent continued by `SendMessage`). Readers do recall before the tasks, quote the passages they relied on, and flag answers they assembled. A fresh grader grades the run, applies a convergent-reasons test, gives S1–S4 severities and calibrates against real readers. Correctness findings go to a fresh verifier and land in a Part A that blocks posting. The run ends with a revision brief from the author's chair, a claim-preservation gate, and re-runs with new readers and a stop rule.
- **What generic prompting achieves:** Asked "have a few simulated readers read my post," Claude would likely give whole-post persona reactions from one context. It would have no key, no blind cut and no isolation, it would count "four personas agree" as convergence, and it would fold correctness errors into style feedback. The things most likely to go missing are the key written from the source rather than the draft, staging by mechanism, the convergent-reasons test, the separate verify-then-block lane, the claim-preservation gate and calibration against a real reader. The pilot's own experience is the evidence: v0 failed blindness, and the orchestrator graded its own test.
- **What built-in tools cover:** Nothing built in does comprehension testing. The Agent tool and `SendMessage` are the mechanism the skill uses, not a competitor.
- **Questions for the reviewer:**
  - How much of the value is the protocol's discipline (freshness, keys, staging), and how much is the correctness lane, which the pilot says doubles as a referee pass?
  - Would you get most of the value from just the maintainer and builder sessions plus the verifier, at a fraction of the 530k tokens?
  - The gap is largest for order-dependent technical exposition with an attachment (the MAIS case). How often do you write anything else for a venue?

### User-Specific Fit

- **Triggering situations:** before posting a draft to a venue that has a profile (MAIS posts first); re-running after a revision; checking whether a specific archetype (maintainer, builder) could do their job from the post.
- **Questions for the reviewer:**
  - How many venue posts a month will go through this? Is MAIS the only venue for now?
  - At about 530k tokens and several staged round-trips per reader, would you run it on every post or only on high-stakes ones?
  - Will you be available as the real reader (Step 5) often enough that findings get calibrated, or will most archetypes stay "uncalibrated"?
  - Would you reach for "reader-test this", or ask `draft-review` out of habit?

### Failure Mode Gracefulness

- **Output structure:** Task results are tied to key elements and quoted passages. Findings carry session citations, severities and a calibration status. Part A carries verifier verdicts and the line checked. A "Degraded" header discloses shortfalls (SKILL.md:185-189). Much of this is inspectable.
- **Potential silent failures:**
  - **Leaked lookahead.** Isolation is advisory (SKILL.md:89-90), and only *writes* outside the folder are checked. A reader that read `post.md` or `key.md` in the run folder, which lives in the repo it can reach, would yield confident, unflagged "pass" results.
  - **One-model convergence.** The convergent-reasons test (SKILL.md:136-139) depends on the grader judging swappability honestly. A lenient grader reports "systemic" findings that are one prior.
  - **A key inheriting framing.** If "source of truth" is actually derived from the draft, everything grades the draft against itself.
  - **Verifier polarity.** `code-fact-check`'s "Verified" means the *claim* holds, while this skill's "CONFIRMED" means the *defect* holds. A mis-mapped verdict clears a real error from Part A, the one lane that blocks posting.
  - **Uncalibrated findings read as calibrated** if the real session never arrives and nobody re-grades.
- **Pipeline mitigations:** The fresh grader and fresh verifier separate checking from authorship. Pre-registered predictions plus the real reader catch simulated priors. The claim-change list is checked against a diff of the two `post.md` files. None of these has run yet.
- **Questions for the reviewer:**
  - In the pilot, did any simulated finding turn out wrong when you read the post yourself?
  - Is "advisory isolation plus a write check" enough, or should the run folder (with `key.md`) live outside any path a reader can reach?
  - Is a missed Part A error acceptable at all, given that Part A is the posting gate?

### Condition for Value

- **Stated or inferred conditions:** a ratified profile at `docs/audiences/<venue>.md`; a source of truth separate from the draft (research notes, a problem page, code); subagents with `SendMessage` available, or the run degrades to instruction-only staging; a budget of hundreds of thousands of tokens per round; a real reader, at least the author, for calibration.
- **Automated findings:**
  - `audience-profiles` skill: EXISTS (unrun).
  - `docs/audiences/`: DOES NOT EXIST in this repo; the MAIS profile is at `docs/working/mais.md`.
  - `fact-check` and `code-fact-check`: EXIST, but their verdict vocabularies (Verified / Mostly accurate / Stale / Incorrect / Unverifiable) are not mapped to CONFIRMED / PLAUSIBLE / CLEARED.
  - The planned fixtures (change 11): NOT BUILT.
  - `SendMessage` can resume a finished agent from its transcript by name or agentId, so the staging mechanism is possible in this harness. The skill does not say to record the agent ID.
- **Questions for the reviewer:**
  - Is the O20 re-run (the revision brief's step 7, `findings.md:114-115`) the first real use? If so, should merging wait for it?
  - Is this an investment that pulls toward a venue-posting pipeline (profile, then test, then post), or inventory until the next MAIS post?

---

## Key Questions

1. **The staged-release mechanism is the skill's main departure from the pilot, and it is untested and under-specified.** Resuming by `SendMessage` works in this harness, but the brief never sends the tasks (part 5) to a reader that quits early, never says what "skim" releases, never says how opening-alone answers are collected, and never says to keep each reader's agent ID. Should the first O20 re-run be treated as the skill's acceptance test before merge?
2. **The correctness lane is the posting gate, but its verifier has no brief and no verdict mapping.** The pilot's Part A was checked by the orchestrator against Lean, the zip and measured build times, none of which is prose or code comments. Should the skill ship a `verifier-brief.md` with an explicit mapping (claim Verified → CLEARED; Incorrect/Stale → CONFIRMED; Unverifiable → PLAUSIBLE) before anyone relies on Part A?
3. **The orchestrator's "must not judge findings" sits against the jobs it is given.** It writes the revision brief, prioritises the first causal gap, decides which added text a reader would act on, fills Part A and writes "Notes for the skill". Is the author's chair meant to be the orchestrator, the human author, or a further fresh agent?
