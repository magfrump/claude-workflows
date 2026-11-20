# Code-review rubric: fix/lever3-followons (14d450d9..c8b5d77b)

Reviewer: one lightweight pass (fact-check + consistency + test critic, no sub-agents). Checkout
`/workspace/.worktrees/wt-2026-11-19-lever3-followons`, HEAD c8b5d77b.

## Verdict

**Approve: no Must-Fix.** Every factual claim the diff adds checks out against the repo. Two
Should-Fix ambers (one wording gap against the model rule, one overstated word) and three nits.
Both refuted claims are gone from all five target files. The new test is hermetic, armed per file,
and has no skip.

## Findings

| # | Sev | File:line | Finding | Evidence |
|---|---|---|---|---|
| 1 | 🟡 Should-fix | `skills/draft-review/SKILL.md:171-174`, `:233-235` | Draft-review's by-path steps leave out the code-review model's "not `cat`" clause. The A8 evidence that motivates this change had 2 of 9 agents hit the Bash output cap with `cat`. The brief says to use the code-review skill's rule, and that rule carries the clause for this reason. | code-review `SKILL.md:468-469`: "Tell it to read that whole file with the Read tool, not `cat` (the Bash output cap cuts a skill-sized file to a preview)". Draft-review :173: "tell it to read that whole file with the Read tool before anything else and follow it". Lever-3 research :99-101: "2 (`a1a8fdb7` …, `a474bd6c` …) with `cat`, which overflowed the Bash output cap … So the skill now says to use the Read tool, not `cat`." (code-review's Stage 2 :891 also leaves out "not cat", so draft-review matches one of the two model sites. The point still holds, but this is a minor fix.) |
| 2 | 🟡 Should-fix | `docs/reviews/code-review-rubric-2026-08-07-main.md:34` (A7 note) | "contract test 10 was replaced in the lever #3 correction (d383a484)" overstates what happened. d383a484 only retitled test 10. Its two assertions are byte-identical before and after, so the row's Resolution text "pinned by contract test 10" is still literally true. Suggest "retitled (its 'second-to-last' framing dropped; assertions unchanged)". | `git diff d383a484^1 d383a484 -- test/skills/code-review-context-delivery.bats`: only `-@test "mutable diff/enclosing part sits second-to-last in the shared block (part 5 of 6)"` → `+@test "shared block still lists the diff (part 5) and the fact-check summary (part 6)"`; the body lines `grep -qE '^5\. \*\*The unified diff itself\*\*'` / `'^6\. The Stage-1 merged fact-check summary'` are unchanged context. |
| 3 | ⚪ Nit | `test/skills/subagent-context-delivery.bats:48-53` | Test 4 checks "only when the agent cannot reach the path" for the critic range but not for the fact-check range. The fact-check step 3 (:175) carries the same wording, so a regression there would go uncaught. Also, if `^4\.` disappears, the awk range runs silently to EOF. code-review's contract test added a guard for exactly this failure in d383a484. | `awk '/^For each fact-check agent, you MUST:/,/^4\./' "$f" \| grep -q 'read that whole file with the Read tool'` (no paste-rule check). Compare `code-review-context-delivery.bats`: "assert it exists so a reword cannot let the range run silently to end of file." |
| 4 | ⚪ Nit | `test/skills/subagent-context-delivery.bats:35` | The claim regex misses the spellings "subagents cannot read" (no hyphen) and "can't read your files". The repo uses both spellings elsewhere. It does catch every old instance (see row 8). | `'sub-agents? cannot read\|cannot read (your\|the orchestrator.s) (files\|filesystem)\|…'`. The `can't` miss is defensible because guide :78's kept exception says "can't read your filesystem". |
| 5 | ⚪ Nit | `guides/sub-agent-briefing.md:78` | The kept first exception, "when the sub-agent can't read your filesystem (e.g., reviewing draft text that exists only in conversation)", frames a conversation-only case as a filesystem limit. It is true and outside this brief, and the research doc lists it as kept. Optional rewording: "when the material isn't on disk". | Line 78 as shown. |
| 6 | 🟢 | `skills/draft-review/SKILL.md:175-177`, `:569` | The A8 claim is accurate: 9 agents (3 fact-check replicates, 5 critics, Stage 2.5) and 9 of 9 read the whole file by path. | Lever-3 research :95-108: "The A8 pass's 9 agents … were told their skill file's absolute path … each one read the whole file … 9 of 9 in the pass read the whole file." |
| 7 | 🟢 | `guides/sub-agent-briefing.md:78`, `patterns/orchestrated-review.md:151`, rubric A7 | The cache-probe finding is cited accurately: one content block, no breakpoint at the end of the shared block, no cross-agent cache read, and cross-pass marked as inferred. Merge commit 9e89a31e added `runs/review-arms/a8-2026-11-19/cache-probe.md`. | cache-probe.md :69 "The Agent tool takes the prompt as one string and sends it as one content block"; :85 "yields no cross-agent cache reads on the Agent-tool path"; :94-95 "no breakpoint ends there either … That is inferred from the records, not measured." |
| 8 | 🟢 | `docs/decisions/log.md:55` | "13 tests as of 2026-11-19; 10 when this row was written" is correct. | `grep -c '@test'`: 13 at 14d450d9 and HEAD; 10 at 65df1b84 (the 2026-08-07 commit that wrote "(10 tests)"). |
| 9 | 🟢 | `skills/draft-review/SKILL.md:238-241` | The personas.md claim is accurate. | `skills/ai-personas-critique/SKILL.md:58`: "Read `personas.md` in this skill's own directory (sibling to this SKILL.md file)"; `personas.md` exists beside it. |
| 10 | 🟢 | `workflows/divergent-design.md:213` | The anchor `../patterns/orchestrated-review.md#context-curation` resolves: there is one `#### Context curation` heading at :145, and the section's stated point is "**drift prevention**". The new reason (curation keeps each axis-agent on its axis) is real and is the rationale already in that section. | orchestrated-review.md :147. |
| 11 | 🟢 | Cross-refs | "same rule as Stage 1 step 3" (draft-review :238) and "Stage 1 step 3 has the evidence" (:569) both point at the paste-only-when rule and the A8 evidence at :175-177. The wording matches the code-review rule "pass the path; paste only when the agent cannot reach it (no file tools, or outside its sandbox)". matrix-analysis :115-119 and :424-427 follow the same rule and keep conversation-only material inline. | code-review `SKILL.md:472`, `:892`, `:1306-1308`. |
| 12 | 🟢 | Five target files | No refuted claim remains. `rg -i 'paste\|filesystem\|cannot read\|cacheable\|cache'` over the five files shows only the new by-path wording, orchestrator-text pastes (intent, success criterion) and orchestrated-review's Fallback ("Sub-agents share the filesystem"). | grep output. Outside scope, historical: `docs/decisions/log.md:55` row 35 body still says "the tail of the cacheable prefix", `docs/decisions/032…:106,124`, `docs/thoughts/code-review-evaluation-state.md:191`, and `docs/roadmap.md:110-120` (the brief forbids roadmap edits). |
| 13 | 🟢 | `test/skills/subagent-context-delivery.bats` | Hermetic: it loads `../lib/hermetic-env`, spawns nothing on the network, and `scripts/hermeticity-lint --root .` passes (146 files). No skip: a missing file is a failure (test 1 is `[ -f ] \|\| return 1`). Armed: run against the 14d450d9 versions of the five files, tests 2, 3 and 4 fail. Per-file claim/cache match counts on the old text are 4, 2, 1, 1, 1 (draft-review, matrix-analysis, DD, orchestrated-review, guide), which matches the research doc. The new files pass 4/4. | Scratch: `bats-old.txt`, `bats-new.txt`, `lint.txt`. |
| 14 | 🟢 | Tests | All 12 bats files under `test/skills/` that name a changed doc pass, 164/164. The research doc's "77 cases" for its 8 listed files checks out (sum of `@test` counts = 77). | Scratch: `bats-all.txt`. |

## Brief coverage

- AC2 (the five files): done. The kept pastes and their reasons are recorded in the research doc.
- AC3 (A7 note dated, status untouched; row 35 count): done. Wording nit in row 2 above.
- AC4 (tests + lint): pass. No old test pinned the wording.
- AC5 (research doc force-added, lines changed and kept): present and accurate.
- AC6 (commit the review-fix-loop rubric under `docs/reviews/`) and the brief status open→done:
  **still outstanding.** Both are expected at merge time, not defects in this diff.

## Must-Fix

None.
