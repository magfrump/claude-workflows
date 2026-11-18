# Design notes: `audience-profiles` and `reader-testing`

**Status:** working notes for drafting the two skills, 2026-11-17. **Inputs:** the hand pilots,
`docs/audiences/mais.md` and `docs/working/reader-testing/o20-2026-11-17/`, and the author's survey,
`docs/working/Skill survey exposition, structure, tutorials, simulated-reader testing.md` (24 skills from 21 repos).
Each rule below names where it came from.

## What the pilot already does that the survey backs

- **One fresh subagent per reader, given file paths only.** (survey: dify, haowjy cold-reader)
- **Tasks are observable, goal-level questions graded against a key written from the source of truth.** (survey:
  GameForge, doc-coauthoring, reader-comprehension-pass) This is the survey's own lean (60%): pass/fail per
  question, testimony for the rest, no composite score.
- **Readers report and don't prescribe.** The revision brief is written from the author's chair. (survey:
  first-reader round 6, rampstack)
- **A pattern in three or more readers counts as systemic.** (survey: GameForge) See the caution below.
- **Calibrate against a real reader**, and pre-register predictions first. Done for the author's session,
  `c94fed18`. (survey: muna's control persona, GameForge's validation of summarizers)

## What changes, survey rules the pilot broke or lacked

| # | Change | Pilot evidence | Source |
|---|---|---|---|
| 1 | **The synthesizer and grader is a fresh agent**, not the orchestrator. The orchestrator wrote the key, the briefs and the draft's history, so it is warm. It marks findings KEEP, GENERIC or DUPLICATE. | I graded my own test. | muna, jezweb |
| 2 | **Run the convergent-reasons test before counting convergence.** All four readers are the same model, so four hits can be one prior in four vocabularies. A finding counts as convergent only if the readers' *reasons* can't be swapped between their entries. | F2 and F6 hit all four readers; not yet tested for swappable reasons. | muna |
| 3 | **Staged, no-lookahead reading, with written expectations before each section.** The instruction-only blind cut failed once (the pilot loaded the whole post). Order carries the argument in mathematics, which is the case where staging pays. | Pilot first take not blind. | muna Step A, first-reader feed server, plimeor |
| 4 | **Add to the profile:** a stake sentence, a patience budget, pain triggers (what makes them close the tab), wins. Readers are told that quitting is a finding. | Readers finished everything; only the enthusiast volunteered a quit point. | first-reader, jezweb |
| 5 | **Recall from memory before the tasks**: retell the problem, insight, key move and finding. Behaviour over words: a section called clear and then misrecalled is the finding. | Added to the author's session; not yet in the simulated protocol. | first-reader, reader-comprehension-pass, GameForge |
| 6 | **A knowledge limit names documents, not a hand-written notation list.** | The conjecturer marked PA_bin and Bud-terms unknown. | pilot; plimeor's Knows/Does-not-know, made concrete |
| 7 | **Claim-preservation gate on every revision:** a plain-language rewrite may not change a claim. Only Part A corrections may, and each is listed. | The revision is pending, and Part A changes claims on purpose. | reader-comprehension-pass, clarity hard gates |
| 8 | **Every revision goes to new readers, who aren't told what changed.** | Planned for the re-run. | dify |
| 9 | **The profile interview needs a non-interactive branch.** If nobody can answer, draft the profile and put the questions in the document. | Pilot used an interactive question tool. | anthropics/skills #1718 |
| 10 | **The skill text holds contracts** (paths, orderings, thresholds, output locations), not common knowledge. Keep the interface small. | — | #2139, first-reader round 4, muna's report card |
| 11 | **Fixtures:** two opposite math expositions, one hollow but clean, one specific but rough. The readers must separate them. The O20 run is the first real fixture, and real thread replies later become ground truth. | — | first-reader |
| 12 | **The register comes from the venue's style guide** (MAIS `STYLE.md`), selected by the profile, not built into the skill. | MAIS declared its own reader and style. | survey, Lessons: mathematical exposition |
| 13 | **Stop rule:** re-run only failed tasks. Stop when results stop moving, or after 3 rounds without improvement. | — | first-reader, vigiles, GameForge |

## What the pilot found that the survey doesn't cover

- **A correctness lane.** The simulated maintainer and builder found real errors in the draft. One: the Bud-term
  claim about PB^A_k's certificates, checked against A1. None of the surveyed skills reads the source against an
  external standard (the agenda, the Lean, the attachment). `reader-testing` should route those findings to a
  verify-then-block lane, separate from exposition.
- **Attachment testing.** The builder ran the zip from scratch and found a build-time mismatch. The survey's
  walkthrough skills test UIs, not attachments.
- **Profiles from venue evidence.** Thread behaviour produced an archetype the author hadn't named (the builder).
  The survey's profile sources are the author's brief, or docs the designer agent reads. Add thread and
  comment history as a source.
