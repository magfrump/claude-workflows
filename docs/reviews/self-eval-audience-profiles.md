# Self-Evaluation: audience-profiles

**Target:** `skills/audience-profiles/SKILL.md`, plus `skills/audience-profiles/references/profile-template.md` | **Type:** Skill | **Evaluated:** 2026-11-17
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

The skill is new (uncommitted on `feat/audience-skills`) and has never been run by a user. Its only evidence is the hand-made pilot it generalizes, `docs/working/mais.md`, which was written before the skill existed. Where a dimension depends on use, this report says there is none rather than guessing.

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | Much of the output can be checked by machine: every template field is present per archetype, the Status, Last verified, Refresh and Evidence read lines exist, archetype headings are roles rather than names, each "What they know" names files, and a non-interactive run fills "Calls for the author" and stays "draft". Whether the cast is the right one can only be judged against real thread behaviour later (notes change 11; fixtures not built). |
| Trigger clarity | Adequate | The description names the output path, the draft-review and reader-testing boundaries, and a strong machine trigger (reader-testing finds no profile; reader-testing's `requires` names this skill). "who reads this" and "who are the readers of" are broad enough to fire on a casual question about any document, and nothing says a profile is per venue, not per post, until the body. |
| Overlap and redundancy | Strong | No other skill writes a persistent reader profile. draft-review captures one line of intended audience per run (`skills/draft-review/SKILL.md:100`); user-testing-workflow tests UIs with real users; constraints-builder shares the draft-from-evidence-then-interview shape but writes a different artifact. The overlap with reader-testing is a clean producer/consumer split. |
| Test coverage | Weak | No bats tests (`test/skills/` has none for it; only the repo-wide frontmatter test, which passes), no `docs/audiences/` output, no git history beyond the pilot-inputs commit `e4ddf3c8`. The MAIS pilot is evidence the method works once by hand, not that this skill text produces it. Probationary. |
| Pipeline readiness | Adequate | Standalone viable (a profile helps an author write even without a test run), and reader-testing declares it in `requires`. But that consumer is equally new and un-run, so the pipeline is drafted, not working. |

---

## Flagged for Human Review

### Counterfactual Gap

- **What the tool does:** Builds a per-venue file of 2-5 reader archetypes from the venue's rules and, preferably, its thread history. Each archetype gets a document-based knowledge limit, a stake, a patience budget with quit triggers, a worst misreading, a success test and task templates. It checks for a reader the venue itself declares and sets the conflict rule from it, keeps archetypes rather than named people, treats venue text as evidence and never as instructions, and has a non-interactive branch that puts the author's calls in the document.
- **What generic prompting achieves:** Asked to "profile the audience for this forum", Claude would likely produce plausible personas from the author's description. The likely gaps: no thread-history mining (so no archetype the author hadn't named, as the builder was in the pilot); knowledge limits written as term lists, not documents; no stake or quit point (so simulated readers later read politely to the end); no check for a declared reader; and an interactive interview that writes nothing when nobody answers.
- **What built-in tools cover:** Nothing comparable.
- **Questions for the reviewer:**
  - Is the value mostly the four failure-prone fields (document knowledge limits, stake, patience, declared reader), or the evidence-first casting? The first is a template; the second is the analytical move.
  - Would you get most of this by handing Claude `docs/working/mais.md` and saying "do this for venue X"?
  - Is the gap largest only when reader-testing follows, and small when the profile is just for writing?

### User-Specific Fit

- **Triggering situations:** Before posting to a venue with a distinct readership (MAIS issue threads are the one real case); reader-testing finding no profile; refreshing after a thread reply the profile did not predict, or after the venue's guides change.
- **Questions for the reviewer:**
  - How many venues do you post to that would get a profile? One (MAIS), or several (other issue trackers, a journal, a docs site)?
  - Is posting to MAIS a sustained activity, or the O20 post alone?
  - Would you reach for this directly, or only reach it through reader-testing?

### Failure Mode Gracefulness

- **Output structure:** A fixed template with an Evidence read line, cited thread evidence per archetype, a Status line ("draft" or "ratified by the author <date>"), and either interview answers or calls for the author with interim answers. Missing fields and an unratified status are easy to see.
- **Potential silent failures:**
  - A cast that looks complete but misses the reader who matters, because thread history was thin or not reachable (the sandbox has no egress; the skill assumes the GitHub API works). The Done-when checklist accepts "says why it couldn't" without lowering the profile's standing.
  - A knowledge limit that names documents the agent assumed the reader knows. Nothing checks these against the reader's real background except the author interview.
  - The author confirming the draft by default (the pilot's 4 of 4 recommended options). The skill names the risk and offers one departing option, which cannot show whether it worked.
  - Downstream amplification: reader-testing briefs every simulated reader from this file, so a wrong stake or patience budget shapes every finding without being seen.
- **Pipeline mitigations:** reader-testing's real-reader calibration and its "simulated disagrees with real" refresh trigger are the only checks, and both need a real reader.
- **Questions for the reviewer:**
  - Which is likelier for your venues: a missing archetype, or a wrong knowledge limit?
  - Is a profile built without thread history worth keeping as "draft", or should the skill refuse it?

### Condition for Value

- **Stated or inferred conditions:** (1) You post to venues whose readers differ from you in a way that matters; (2) the venue has readable thread history; (3) reader-testing is run on it, or the profile is used while writing; (4) the profile gets refreshed, otherwise its cast goes stale.
- **Automated findings:** reader-testing: EXISTS as text, never run. `docs/audiences/`: DOES NOT EXIST in this repo; the pilot sits at `docs/working/mais.md`. Fixtures (notes change 11): NOT BUILT. The worked example the skill points to sits in `docs/working/` of claude-workflows, so it cannot be read from other repos once the skill is installed.
- **Questions for the reviewer:**
  - Is condition 1 met beyond MAIS today?
  - Should this skill ship before reader-testing has had one run, given that its main value is as reader-testing's input?
  - Is this an investment (MAIS posts continue, and each run refines the profile) or inventory built for one post?

---

## Key Questions

1. **One venue, one pilot, two new skills.** The skill generalizes a single hand-made profile for a single venue (MAIS). Is there a second venue in view that would test the generalization, or should the skill ship labelled as pilot-stage until one appears?
2. **The worked example doesn't match the template and isn't portable.** `mais.md` lacks the stake, patience budget, pain trigger and wins fields that the template requires and lives in `docs/working/` of this repo, so an agent copying it in another repo either can't reach it or drops four fields. Should a template-conformant example ship in `references/` before merge?
3. **Is "ratified by the author" a real check?** The pilot author took every recommended option. If the interview mostly confirms, the profile's quality rests on the evidence pass alone. What would show the departing option is doing its job?
