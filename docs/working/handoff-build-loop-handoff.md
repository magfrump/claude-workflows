# Handoff: build-loop handoff (dev cycle v2 flow)
Date: 2026-10-03
Branch: feat/build-loop-handoff (worktree `/workspace/.claude/wt-build-loop-handoff`)

Read this first when you return. It records the design conversation of 2026-10-02/03, which replaced most of plan revision 2's human gates. The flowchart that the conversation converged on is in the approval doc "Dev cycle skill — for your approval" (https://claude.ai/code/artifact/78a2f851-e696-4a86-bfe8-474212e5e645). Its diagram was redrawn on 2026-10-03, and the table under it maps your 12 answers to changes.

## Project state
- **Branch purpose**: the dev cycle hands settled roadmap items to autonomous build loops and collects their results, with a tested gate script (`scripts/build-loop.sh`) deciding what may merge.
- **Position in larger initiative**: roadmap In flight "Build-loop handoff" (brief `docs/working/briefs/2026-10-02-build-loop-handoff.md`). The scope widened on 2026-10-03, and the cycle itself becomes an orchestrator loop (below). Q-103 waits on this unit.
- **Blocked on**: confirmations C1–C4 below (defaults are given, so a new session can proceed on them), then plan revision 3.

## Accomplished so far
- `3a005378`: research doc, plan revision 2 and checkpoint, plus three plan-time reviews in `docs/reviews/`: `pre-mortem-build-loop-handoff.md` (F25–F31, L1–L3), `architecture-review-build-loop-handoff.md`, `test-strategy-build-loop-handoff.md` (G1–G20).
- The approval doc's flowchart was redrawn twice: first with every input point in revision 2, then as the v2 flow. The mapping table sits under it.
- No code has been written.

## The conversation, decision by decision

### Your questions on plan revision 2
- **D1, "why doesn't the cycle launch loops itself?"** It should. Revision 2's reasons don't hold:
  - "You read each brief before a loop starts" came from the brief's acceptance criteria. Those turned a chore-review finding (A6) into a rule; you never asked for it. Your comment in the approval doc on 2026-10-01 asked for "handoff to autonomous build loops" as part of the standard loop.
  - Launch mechanics aren't a blocker. Headless `claude -p --bare` can't use subscription auth, and Agent-tool worktree isolation fails here. But by-hand worktrees plus background subagents ran 6 agents cleanly (HC1, memory `agent-worktrees-stall-and-stale-base`).
  - The one real constraint is lifetime: subagent loops live only as long as the orchestrator session, so the orchestrator stays running.
- **D4, "why a shell-script merge? why not let the agent merge?"** The agent does merge. The script exists to make check and merge one atomic step: it judges the exact merge result (`merge-tree`) and moves main by compare-and-swap. A separate check followed by `git merge` judges something other than what lands (pre-mortem L1, F15).
  - Under `self-merge`, the loop runs it, with no human.
  - Under `review`, you approve and an agent runs it.
  - Revision 2 had you run it only to avoid a new answer parser. That was a bad trade.
  - PR-based repos merge on GitHub, and the PR is the handoff (answer 10).
- **D2, "highlight every point where you expect my input; we haven't converged."** Revision 2 asked for you at 12 points (flowchart pub 3). Your answers to each, in your words where short:
  1. "start a cycle should be kick off a loop, not assumed stopping after one cycle"
  2. Health and cleanup is not gated on you: "safe branch deletion doesn't need to wait", and async delete commands in questions.md are also fine, as long as nothing blocks on your response.
  3. "audits should have an explicit trigger and a menu of audit dimensions (similar to the review critic personas?) that can be expanded per project (e.g. specific libraries)"
  4. Brainstorm uses "a persistent set of hard constraints per project in addition to feature specific constraints". Features with no downsides at 90%+ confidence go to the roadmap; less confident ones (~70%) go to questions.md for async consideration.
  5. Briefs are built from the roadmap. Slots are features or tasks settled for RPI. Plan questions go async to questions.md. Slots are capped so parallel work and budget consumption can be controlled.
  6. "I don't know what the in-flight checks step even is, also I don't know why there's any 14-day measure anywhere"; the "In flight" step also duplicated the step-6 number.
  7. "I don't need an approval gate for pr-prep"
  8. "next loop should start autonomously; the point is to work through all threads until they are blocked on questions, all surfaced via questions.md"
  9. Loop questions are surfaced async to questions.md, "then tasks deferred rather than blocking the loop"
  10. "for PR review, the pull request is a correct handoff to me"
  11. "correct handoff, policy is blocked on me"
  12. Rebuild and bless applies only to this workflows repo. It is not one-time, since the repo keeps changing and must propagate changes. It stays manual: "version releases hand off to me".

### The v2 flow (flowchart pub 4)
- **Orchestrator (the dev cycle)**, repeated:
  - 0 digest;
  - 1 health and cleanup: fixes, and deletes merged branches without waiting;
  - 2–4b checks in parallel: triggers, answered questions, spot-check, and an audit when its trigger fires, picking dimensions from a per-project menu;
  - 5 brainstorm (conditional), checked against per-project hard constraints, with confidence routing;
  - 6 roadmap: items settled for RPI are ready;
  - 7 dispatch: a brief per settled item, into free slots (the cap bounds parallel work and budget);
  - 8 collect results: merged → Done; blocked → its questions filed and the slot freed; ready for review → a PR, or a merge entry where the repo has no PRs;
  - 9 record, and land via pr-prep with no gate.
  - Then: is any thread not blocked? If yes, go again. If no, wait, and wake when an entry is answered.
- **Build loop**: own worktree; reads its brief from main's commit; RPI research and plan with **no plan-approval gate**. A question → the task is deferred (marker `handoff: blocked`, with its questions). Otherwise: implement, run pr-prep, then the gate decides: self-merge and the gate passes → `build-loop.sh --merge`; otherwise hand off for review.
- **You, asynchronously** (nothing waits on you):
  1. start the loop;
  2. answer `questions.md` entries; an answered task re-enters the queue;
  3. review PRs or merge entries under `review`;
  4. choose the policy once per repo (Q-103);
  5. this repo only: cut releases (rebuild and bless the image).

### What changes in plan revision 2
- **Survives**:
  - D5 (the allowlist gate over a `check_fix` floor);
  - D7 (merge-tree → diff-tree rules → commit-tree → CAS, hardened git);
  - the F1–F31 bypass table;
  - `--policy`, `--status`, `--check` and `--merge`;
  - the lib extraction (architecture review);
  - test rows T1–T31, minus those for removed modes.
- **Changed**:
  - D6: the gate runs **main's committed copy** of `build-loop.sh` (extracted to a temp dir), not the image copy, so it never waits for a release. Open detail: in other repos, main has no such script, so the installed copy is used there.
  - Markers: `ready`, `blocked` (carrying questions) and `stopped: reason`; `plan` is gone.
  - Review merges: a PR where the repo uses them, otherwise one merge entry; the orchestrator merges once it is answered.
- **Dropped**:
  - D1 (the user starts loops; `--start`/`--prompt` printing a prompt for you);
  - D2 (plan approval);
  - D3 (early keep-or-drop entries);
  - the user-run merge;
  - the bless prerequisite;
  - the 14-day idle timer and the keep-or-drop questions in the dev-cycle skill's step 6 (In flight checks 2–3), which step 8 "Collect results" replaces;
  - the brief's acceptance criterion "the user still reads each brief before a loop starts". You overrode it here. The brief asked for that decision as a questions entry, so revision 3 records it as a decision-log row instead.
- **Risk that grows** (for the revision 3 pre-mortem):
  - With no human read of briefs, repo text drives autonomous loops directly. F21, brief/plan injection, moves from "partly" toward the gate being the only guard.
  - F28, forged answers in the shared working tree, matters more, because an answer now unblocks autonomous work. Read answers from main's commit, not the working tree.
  - Re-run the bypass-family pass on these two before code.

## Open questions: confirmations with defaults
C1–C4 were asked on 2026-10-03 and not answered. Revision 3 proceeds on the defaults unless you say otherwise. They are kept here rather than filed in `questions.md` on this branch, to avoid Q-ID collisions with main before the branch merges. File them when the branch lands, or answer here as `C2: [2]`.

| ID | Question | [1] default | [2] | If the default is wrong |
|---|---|---|---|---|
| C1 | Who writes `questions.md`? | The orchestrator only; loops carry their questions in the `blocked` marker on their own branch | Loops write it directly | Concurrent edits to one file on main from up to cap+1 sessions |
| C2 | Does a blocked task keep its slot? | No: it frees the slot and re-enters the queue on its existing branch once answered | Yes: it holds the slot | Blocked work starves the cap |
| C3 | How does the loop wait when everything is blocked? | It sleeps and checks for answered entries every 20–30 min (`/loop` dynamic) | It stops; you restart it | Polling spends a little; stopping needs you to come back |
| C4 | Deleting merged branches without asking contradicts global CLAUDE.md ("deleting branches" needs approval regardless of mode) | Narrow the global rule to "merged branches, `git branch -d` only, no approval" | Record it as a rule for this project only | Other projects keep asking |

## Scope split
- **This unit** (handoff / orchestrator): answers 1, 5, 6, 7, 8, 9, 10, 11 and 12; the gate script and lib; dev-cycle skill steps 6→7/8/9 and the loop; `docs/dev-cycle.md`; onboarding step 13 wording; decision-log row; Q-103 re-route. Still stacked units under the ~400-line cap (log 62).
- **Separate roadmap items**, independent of this unit. Not yet added to `docs/roadmap.md`, which is cycle-owned; add them in the next cycle or the next session:
  - (a) health step: delete merged branches without waiting (answer 2; needs C4);
  - (b) audit dimension menu, extendable per project (answer 3);
  - (c) brainstorm hard-constraints file and confidence routing (answer 4).

## Key file paths
- This handoff; `docs/working/checkpoint-build-loop-handoff.md` (revised 2026-10-03).
- `docs/working/plan-build-loop-handoff.md`: revision 2. Its header points here; the gate parts still apply.
- `docs/working/research-build-loop-handoff.md`
- `docs/reviews/pre-mortem-build-loop-handoff.md`, `architecture-review-build-loop-handoff.md`, `test-strategy-build-loop-handoff.md`
- `skills/dev-cycle/SKILL.md` (steps 6–7 are what v2 rewrites), `scripts/dev-cycle.sh`

## Next steps
1. Fresh session on this branch: read this handoff, then write **plan revision 3**. Start from revision 2's gate sections and replace the lifecycle (D1–D4, In flight, keep-or-drop) with the v2 flow above, using C1–C4's defaults unless answered.
2. Re-run the bypass-family pre-mortem on what changed: no human read of briefs (F21), answers unblocking autonomous work (F28), the orchestrator as the single writer, and dispatch inside the orchestrator session.
3. Bring revision 3 to you for approval. RPI's plan gate still applies to this session's own work: the v2 "no plan gate" is for dispatched loops.

## Task status
- **Lifecycle**: superseded by plan revision 3 (2026-10-04); read `docs/working/checkpoint-build-loop-handoff.md` first
- **Last commit**: the commit that adds this file (`git log -1 --oneline` on `feat/build-loop-handoff`)
- **Verify command**: `git -C /workspace/.claude/wt-build-loop-handoff ls-files docs/working/handoff-build-loop-handoff.md`
- **Expected result**: `docs/working/handoff-build-loop-handoff.md`
