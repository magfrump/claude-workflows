# Research: lines that tell a subagent to write a report file

Brief: `docs/working/briefs/2026-11-19-subagent-report-files-listing.md` (at a4509413). Branch: `docs/subagent-report-files-listing`. Research only: no skill, workflow, script, pattern or guide changes.

Failure-pattern grep: none relevant (`rg -i 'subagent|sub-agent|report|scratch|write tool|dispatch'` over the `**FP-NNN**` entry lines of `docs/failure-patterns.md` matches FP-125, FP-137, FP-170, FP-172, FP-177 and FP-181, each only on the word "report"; none is about a subagent's file write)

## Inputs read (criterion 1)

- Triage group G and F-010 (`docs/working/research-2026-11-19-herald-friction-triage.md`, lines 134-148 and 206-232): four approaches, (1) a line in the build-loop prompt, (2) a "(a subagent returns it as text)" clause in each review skill's save line plus code-review's dispatch, (3) one rule in `global-instructions/CLAUDE.md` or a linked guide, (4) the status quo.
- `docs/working/feedback/belegarth-herald.md` F-010: two review subagents of a build loop, each given its own scratch directory, were refused writing their reports there (2 writes, 2026-11-07). File names not recorded.
- `docs/working/feedback/philosophy-research.md` F-011: a parallel-worktrees subagent refused writing a report under `docs/thoughts/`; its handoff under `docs/working/` was accepted. File name not recorded.
- cd019457, `workflows/parallel-worktrees.md` lines 38 and 51: a report item returns its report as text and the parent writes and commits it.
- `docs/constraints.md` (H1-H4, S1-S11).

## New evidence: the refusals in this repo's own transcripts

The repo records name only the two other-repo events, so I read this machine's Claude Code transcripts (`~/.claude/projects/-workspace/**/*.jsonl`, 2026-10-20 to 2026-11-19) with `rg`, matching each subagent Write call to its tool result by `tool_use_id`. (Commands were `rg`, `git` and shell text filters over their output; nothing was written outside the scratchpad.)

| Subagent Write target | Calls | Refused |
|---|---|---|
| a file named `report.md` in a scratchpad subdirectory | 13 | 13 |
| other scratchpad files (61 review reports among them, e.g. `code-fact-check-report.md`, `security-review.md`, `code-fact-check-report-r1.md`) | 448 | 0 |
| `docs/reviews/*.md` in a loop's worktree (critic and fact-check replicates dispatched per code-review, rubrics) | 95 | 0 |
| `docs/working/` or `docs/thoughts/` (unique tool_use ids whose path contains either) | 79 | 0 |

Every refusal returned "Subagents should return findings as text, not write report files. Include this content in your final response instead." The 13 came from five dispatchers: four build loops, whose scratch directories carry their brief's stem (`2026-11-06-free-merged-loop-worktrees`, 3; `2026-11-10-dev-cycle-skill-held-fixes`, 1; `2026-11-11-self-answer-measure`, 3; `2026-11-13-review-gap-audit`, 1), and one main session (`q106-*`, 5, 2026-10-30). In the two refused subagents' prompts I read, the dispatcher named the path ("Save it to …/fc-r3/report.md", "Write your report to …/test-strategy/report.md"); the other eleven prompts were not read. No file in `skills/`, `workflows/`, `patterns/`, `guides/` or `scripts/` names a scratch `report.md`; the dispatchers made the name up, starting from `scripts/build-loop.sh` line 1978's "its own scratch directory".

The clearest contrast is in one session (47403b7b, 2026-11-06): that loop's first review pass wrote `fact-check/code-fact-check-report.md` and `security/security-review.md` in its scratchpad, accepted; its final pass's three replicates wrote `final/fc-r{1,2,3}/report.md`, all refused.

What this does and does not show:
- Observed: in this repo the refusal fired only on a subagent's `report.md`, every time, and never on a review file under `docs/reviews/` or a review-named scratch file. So the lines that tell a dispatched critic to save to `docs/reviews/` (code-review 485, 901, 1039; draft-review 174, 243) are **known accepted**, 95 times out of 95.
- Inferred, not confirmed: Claude Code's check seems to key on the file name (or on something that goes with it). Herald F-010 and philosophy-research F-011 did not record their file names, so they neither confirm nor refute this.
- Not known: whether a later Claude Code version widens the check. Nothing here should bet on the name heuristic (see candidate F below).

## The listing (criteria 2 and 3)

Search: `rg -n -i` over `skills/ workflows/ patterns/ guides/ scripts/` for "save … report|critique|review|output|analysis", "write … findings|report … to", "output … at", "scratch directory|scratchpad" and `report\.md`, then read each hit in context. Columns: **Writer** is who performs the write when the line is followed; **Refused?** comes from the transcript table above and the two feedback entries; **Class**: gate = `scripts/build-loop.sh`, `d6.sh`, `dev-cycle.sh`, `questions.sh`, `scripts/lib/`, `skills/dev-cycle/` (GATE_CODE, `scripts/lib/dev-cycle-read.sh:1037`); wf = a `workflows/` file; neither. Every `SKILL.md` is also on the self-merge floor as an instruction file (`INSTRUCTION_FILE`, `dev-cycle-read.sh:655`), so a change to any of them needs the owner's review merge.

### A. A dispatcher hands a subagent a scratch directory

| file:line | Quoted text | Writer | Refused? | Class |
|---|---|---|---|---|
| `scripts/build-loop.sh:1978` | "Start subagents only for research and review, each with its own scratch directory under $s/ in your scratchpad directory." | a build loop's own subagent, writing where the loop's brief tells it | **yes**: 8 of 8 `report.md` writes from four loops here, plus herald F-010 (2); review-named files in the same directories accepted | gate |

### B. A dispatcher tells its subagent to save to a named file

| file:line | Quoted text | Writer | Refused? | Class |
|---|---|---|---|---|
| `skills/code-review/SKILL.md:485` | "Instruct the agent to save its report as `docs/reviews/code-fact-check-report-r<N>.md`" | fact-check replicate subagent of code-review (run by a main session or a build loop) | no: accepted (43 writes to `docs/reviews/` whose name contains `code-fact-check-report`, 0 refused) | neither |
| `skills/code-review/SKILL.md:901` | "Instruct the agent to save its critique as `docs/reviews/{critic-name}-review-{date}.md`" | critic subagent of code-review | no: accepted (security, performance, API, architecture reviews, 0 refused) | neither |
| `skills/code-review/SKILL.md:1039` | "Instruct it to save the report as `docs/reviews/code-fact-check-submitted-claims.md`" | Stage 2.5 fact-check subagent | not known separately; same directory as above, accepted | neither |
| `skills/draft-review/SKILL.md:174` | "Instruct the agent to save its report as `docs/reviews/fact-check-report.md`" | fact-check subagent of draft-review | not known (no run in the transcripts); same directory class as code-review's | neither |
| `skills/draft-review/SKILL.md:243` | "Instruct the agent to save its critique as `docs/reviews/<skill-name>.md`" | critic subagent of draft-review | not known; same directory class | neither |
| `patterns/orchestrated-review.md:66` | "Success criterion: A markdown report saved to docs/reviews/security-review.md, structured per the security-reviewer skill." (worked example) | critic subagent of any orchestrator following the pattern | not known; same directory class | neither |
| `skills/code-review/SKILL.md:995` | "Success criterion: A markdown report saved to docs/reviews/security-review-<date>.md, structured per the security-reviewer skill." (dispatch example) | critic subagent of code-review | no: accepted, as line 901 | neither |
| `skills/draft-review/SKILL.md:146` | "Success criterion: A fact-check report saved to docs/reviews/fact-check-report.md, structured per the fact-check skill." (dispatch example) | fact-check subagent of draft-review | not known; same directory class | neither |
| `guides/sub-agent-briefing.md:29` | "**Output:** Write findings to the **Auth** section of `docs/working/research-api-endpoint.md`." (worked example) | research subagent | no: `docs/working/` writes accepted (81 of 81 here; philosophy-research F-011's handoff) | neither |
| `workflows/task-decomposition.md:86` | "Tell it to write findings to a specific section of the research doc, or to a separate research doc per area" | research subagent | no, as the row above | wf |

### C. A skill's own save line, qualified "when run standalone"

The writer is whoever runs the skill: a main session run standalone, or a subagent that loads the skill without an orchestrator's path (a build loop's ad hoc reviewer). Under an orchestrator the dispatch line (group B) names the path, and several of these skills say so (e.g. `ui-visual-review` 342: "When run via an orchestrator, the orchestrator specifies the output path"). Refused? Not known for these exact lines; every recorded write to these paths was accepted.

| file:line | Quoted text (abridged) | Class |
|---|---|---|
| `skills/code-fact-check/SKILL.md:477` | "When run standalone, save your report as `docs/reviews/code-fact-check-report.md`" | neither |
| `skills/security-reviewer/SKILL.md:574` | "When run standalone, save your critique as `docs/reviews/security-review-{date}.md`" | neither |
| `skills/performance-reviewer/SKILL.md:316` | "When run standalone, save your critique as `docs/reviews/performance-review.md`" | neither |
| `skills/api-consistency-reviewer/SKILL.md:387` | "When run standalone, save your critique as `docs/reviews/api-consistency-review.md`" | neither |
| `skills/architecture-review/SKILL.md:489` | "When run standalone, save your critique as `docs/reviews/architecture-review.md`" | neither |
| `skills/ui-visual-review/SKILL.md:340` | "When run standalone, output your review as a Markdown document at `docs/reviews/ui-visual-review.md`." | neither |
| `skills/fact-check/SKILL.md:588` | "When run standalone (not via the draft-review orchestrator), save your report as" … | neither |
| `skills/cowen-critique/SKILL.md:160` | "Run standalone (not via draft-review orchestrator): save the critique as `docs/reviews/cowen-critique.md`" | neither |
| `skills/yglesias-critique/SKILL.md:164` | "When run standalone (…), save your critique as `docs/reviews/yglesias-critique.md`" | neither |
| `skills/business-plan-critique-market-sizing/SKILL.md:338` | "When run standalone (…), save your critique as" … | neither |
| `skills/business-plan-critique-moat/SKILL.md:256` | "When run standalone (…), save your critique as" … | neither |
| `skills/business-plan-critique-unit-economics/SKILL.md:176` | "When run standalone (…), save your critique as `docs/reviews/business-plan-critique-unit-economics.md`" | neither |

### D. Unqualified save lines in a skill

| file:line | Quoted text | Writer | Refused? | Class |
|---|---|---|---|---|
| `skills/what-if-analysis/SKILL.md:239` | "Save your analysis as `docs/reviews/what-if-analysis.md`" | whoever runs it; no orchestrator here dispatches it as a subagent | not known | neither |
| `skills/pre-mortem/SKILL.md:238` | "Save your analysis as `docs/reviews/pre-mortem.md`" | as above | not known | neither |
| `skills/matrix-analysis/SKILL.md:327`, `:401` | "Save this as `docs/reviews/matrix-analysis.md`" / "Save the matrix document to `docs/reviews/matrix-analysis.md`" | the matrix-analysis runner (main session, or a loop running DD); its criterion subagents return text (168, 196) | not known | neither |
| `skills/ai-personas-critique/SKILL.md:257` | "Save as `docs/reviews/ai-personas-critique.md`." | usually a draft-review critic subagent (`draft-review/SKILL.md:89`, `:231-232`) | not known | neither |
| `skills/test-strategy/SKILL.md:230` | "save to `docs/working/test-strategy-{topic}.md`" (when the user asks for an artifact) | the runner; code-review dispatches it as a contextual critic | not known for this path; one loop's improvised `test-strategy/report.md` was refused | neither |
| `skills/dependency-upgrade/SKILL.md:204` | "If the user requests a persisted artifact, save to `docs/working/dep-upgrade-{package}-{version}.md`." | the runner; code-review can dispatch it as a critic | not known | neither |
| `skills/self-eval/SKILL.md:233` | "Save the evaluation report to `docs/reviews/self-eval-{target-name}.md`." | the runner; 2 subagent writes of `self-eval-*.md` to `docs/reviews/` here, both accepted | no (2 of 2 accepted) | neither |

### E. The main session (or the loop itself) writes

These are written by the session that runs the skill or workflow. A build loop is itself a subagent of the cycle, so its writes are subagent writes; the transcripts show its `docs/working/` and `docs/reviews/` writes accepted (this research doc is one more). None is a report a dispatched subagent writes.

| file:line | Quoted text (abridged) | Class |
|---|---|---|
| `skills/code-review/SKILL.md:1247` | "Save all review artifacts to `docs/reviews/` in the project root." | neither |
| `skills/draft-review/SKILL.md:540` | "Save all review artifacts to `docs/reviews/` in the project root." | neither |
| `skills/code-review/SKILL.md:1236`, `skills/code-review/references/rubric.md:9` | "Save as `docs/reviews/code-review-rubric-<YYYY-MM-DD>-<branch-slug>.md`" (the rubric) | neither |
| `skills/draft-review/SKILL.md:437` | "Save this as `docs/reviews/verification-rubric.md`." | neither |
| `skills/design-space-situating/SKILL.md:185` | "Save to `docs/working/situating-<decision-slug>.md`." | neither |
| `workflows/research-plan-implement.md:482` | "Save it to `docs/working/handoff-{topic}.md`" (session handoff) | wf |
| `workflows/divergent-design.md:38` | "write each step's full output to `docs/working/dd-{topic}.md`" | wf |
| `workflows/pr-prep.md:145`, `:150` | "Run /pre-mortem on the diff and save the output to … `docs/working/pre-mortem-<branch-slug>.md`" | wf |
| `workflows/user-testing-workflow.md:404` | "Save the report as `docs/working/testing-findings-{topic}.md`" | wf |
| `workflows/spike.md:207` | "Save this to `docs/spikes/` in the project if the findings are relevant long-term" | wf |
| `workflows/research-plan-implement.md:233` | "invoke `/pre-mortem` on the plan doc and cite the output path (`docs/reviews/pre-mortem.md` by default)" | wf |
| `workflows/divergent-design.md:220` | "pass it a per-decision output path, `docs/reviews/matrix-analysis-{topic}.md`" (to matrix-analysis, run by the DD session) | wf |
| `guides/subtraction-checklist.md:101` | "Write findings to `docs/working/subtraction-proposals-round-N.md`" (the self-improvement loop's session) | neither |
| `guides/validation-gates.md:80` | "Ensure review outputs go to `docs/working/` during implementation" | neither |
| `scripts/self-improvement.sh:1528` | "Write the rubric to docs/reviews/ as usual." (a headless top-level `claude -p`, not a subagent) | neither |
| `skills/dev-cycle/SKILL.md:222-224` | steps 2, 3, 4 and 4b run "as subagents … and write their results into the record": the cycle writes the record from what they return | gate |

### F. Already return-as-text (prior art, no change needed)

`workflows/parallel-worktrees.md:38` and `:51` (cd019457); `skills/constraints-builder/SKILL.md:153-157` and `references/reader-brief.md:5-6` ("the running agent saves each one … so a reader needs no write access"); `skills/reader-testing/SKILL.md:161`, `:197-198` and `references/grader-brief.md:5-6`; `skills/reader-testing/references/reader-brief.md:32` ("Write no files"); `skills/matrix-analysis/SKILL.md:168`, `:196`.

### Counts

49 lines in all (groups A-E: 1, 10, 12, 8 and 18). Gate code: 2 (`build-loop.sh:1978`, `dev-cycle/SKILL.md:222`). `workflows/`: 9 lines in 7 files. Known refused: 1 line, `build-loop.sh:1978`, and only through the `report.md` names loops give their reviewers. Known accepted: the code-review dispatch lines (485, 901, 995), the 2 `docs/working/` research-subagent lines, and self-eval's line. Not known: the rest, none of which has a recorded refusal; three of them are run by subagents (ai-personas-critique 257 under draft-review, test-strategy 230 and dependency-upgrade 204 under code-review), so "not known" there is not "accepted". The triage counted 12 skills and 2 workflows; the listing adds the draft-review dispatch lines (174, 243), code-review 485 and 901, the pattern and guide examples, and the main-session lines, and moves code-review 1039 from "nearest match to F-010" to "same class as 95 accepted writes".

## Design choice: which of group G's approaches (criterion 4)

Motive (S5). Each refused write costs one tool call and one model turn, and the report still arrives, because the refusal tells the subagent to return it. 15 such calls are recorded in about a month (13 here, 2 in herald), almost all from build-loop reviewers. Nothing is lost and no gate is misled, so the status quo is a real option. The listing changes the question: the refusals come from a scratch `report.md` that a dispatcher improvises, not from the skills' `docs/reviews/` lines, which are accepted every time.

Candidates (divergent design, seeded with the constraints above):

- **A. Status quo.** No change; about one refused call per loop reviewer per pass continues.
- **B. One line in the build-loop prompt** (`scripts/build-loop.sh:1978`): a research or review subagent returns its report in its final message, not as a file in its scratch directory; the loop saves what it needs. Gate code, so a review merge.
- **C. Edit every skill save line and dispatch line** (triage option 2, about 17 `SKILL.md` files). Pruned on S5: no recorded refusal on any of those lines, 95 accepted writes on the dispatch lines; also S3 (one rule restated 17 times) and 17 floor files for the owner to review.
- **D. One rule in `global-instructions/CLAUDE.md`**: "a subagent returns its report as text". Covers main-session dispatchers too (the q106 run's 5 refusals). An instruction file on the floor, always-loaded (S2: one line, within budget), and it restates what the platform's own refusal message already says (S3).
- **E. A rule in `patterns/orchestrated-review.md`**, changing the success-criterion example. Pruned: the observed refusals came from ad hoc loop dispatches that do not follow the pattern, and the pattern's `docs/reviews/` example is in the accepted class; it would also contradict code-review's dispatch lines unless those changed too (C).
- **F. Tell dispatchers not to name a report `report.md`.** Pruned: it leans on an inferred, unconfirmed name heuristic of the platform that a later version could widen, and it works against the platform's stated rule rather than with it.

| Candidate | Hard constraints | Reaches the observed cause | Owner attention (S10) | Always-loaded cost (S2) | One source (S3) |
|---|---|---|---|---|---|
| A status quo | ok | no | none | none | ok |
| B build-loop line | ok (H3: a bats case can assert the prompt line) | 8 of 13 here, plus herald's 2 | one review merge, which can ride with group F's (also `build-loop.sh` / dev-cycle gate code) | none | matches parallel-worktrees' wording |
| D global rule | ok | all 13, plus herald's 2 | one floor review | 1 line in every session | restates the platform message |

**Pick: B (Path A, one option dominates).** B removes the cause in the place most refusals come from, arrives in the prompt at the moment a loop dispatches (S4), adds nothing to always-loaded context, and reuses the parallel-worktrees wording (S3). D reaches the remaining main-session case (5 refusals in one run on 2026-10-30, none since on this machine; other repos' main sessions are not seen here), but every session pays its always-loaded line for it, and the platform's refusal already tells that subagent what to do. A loses to B on a one-sentence change that can share a review merge already due for group F. Recorded so the cycle does not edit the skills: approach C (triage option 2) and code-review 1039 are closed as not refused.

Proposed wording for B (for the later brief, not applied here): "Start subagents only for research and review, each with its own scratch directory under $s/ in your scratchpad directory for its working files; each returns its report in its final message, not as a file (Claude Code refuses a subagent's report file), and you save what you need." `test/scripts/build-loop-dispatch.bats` pins line 1978: line 35 asserts "under 2026-10-01-x/ in your scratchpad directory", and lines 50-54 grep the prompt for "Start subagents only for research and review" and assert that line's later clauses. The wording above keeps both pinned substrings, so the brief extends that file with an assertion of the new clause rather than adding a new one.

Other choices in this unit (fewer than three options, one line each):
- Whether to read transcripts beyond the repo's records: yes. The brief asks for repo evidence and allows "not known", but the transcripts turn three "not known" rows into "accepted" and show where the refusal fires; reading them used `rg` and shell text filters over its output, and wrote only to the scratchpad.
- Whether the refusal mechanism (name-based) is settled: no; recorded as inferred, and candidate F is pruned because of it.

## For the dev cycle

Suggested brief (one):

1. **Build-loop prompt: research and review subagents return reports as text (herald F-010 remainder).**
   Goal: change `scripts/build-loop.sh` line 1978 so a loop's research and review subagents return their reports in their final message rather than writing them into their scratch directory, and extend `test/scripts/build-loop-dispatch.bats` (which already pins that line) to assert the new clause in the `--prompt` output. Motive: 13 of 13 subagent `report.md` writes here were refused (8 from build loops), plus herald's 2. Paths: `scripts/build-loop.sh`, `test/scripts/build-loop-dispatch.bats`. Needs a review merge (gate code). It could share one review merge with the group F brief (build loops starting in a removed worktree, herald F-008), whose paths are also gate code.

Close, with reason, the rest of the roadmap Now item "Review subagents are told to write report files Claude Code refuses": the review skills' save lines and code-review's and draft-review's dispatch lines are not refused in practice. All 95 recorded subagent writes to `docs/reviews/` were accepted, and the only refused name was a scratch `report.md` that dispatchers improvise. Three subagent-run save lines have no recorded outcome (ai-personas-critique 257, test-strategy 230, dependency-upgrade 204), and the evidence is one machine's transcripts; neither earns a change before a refusal is seen. Revisit if a refusal is recorded on a `docs/reviews/` path or on a name other than `report.md`.

## Review

Round 1 (one independent general-purpose reviewer, read-only, report returned as text). It reproduced the core evidence: 13 of 13 `report.md` writes refused, 95 of 95 `docs/reviews/` writes accepted, the 8/5 split. Fixed: `build-loop-dispatch.bats` does pin line 1978, so the suggested brief extends that file; line numbers for orchestrated-review (66) and pr-prep (150); missed lines added (ai-personas-critique 257, test-strategy 230, dependency-upgrade 204, the code-review 995 and draft-review 146 dispatch examples, and six main-session save lines), with counts redone; GATE_CODE named in full; the dispatcher-named-the-path claim narrowed to the two prompts read; counts given with their filters (79 and 43, where the reviewer got 76 and 38 with its own filters; conclusions unchanged); the close reason now names the three subagent-run lines with no recorded outcome and the one-machine scope. Delta re-checked by hand against the files. No `fix(...)` commits, so no failure-pattern entry is due.
