# Running questions

Questions raised during autonomous work that did not justify stopping.

**To answer:** write `Q-0NN: <your answer>` anywhere — a reply, a file, a commit.
The ID is the whole handle; you never have to restate the question. Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.

**Needs** is the route — who or what actually discharges the item, from
`docs/working/triage-2026-09-17-backlog.md` §3.1:

| Route | Meaning |
|---|---|
| `you: judgment` | Needs your taste or authority. The only real attention spend. |
| `you: terminal` | Needs your machine, not your mind. Collected into one paste below. |
| `agent` | Mechanical. Should not be here long. |
| `trigger` | Not a question yet — a condition being watched. Costs you nothing. |
| `deferred` | Scheduled behind an event that has not happened. |

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-059](#q-059--arith-eval-bash-grant) | you: judgment | Should arithmetic-eval's LLM fixture runs get a restricted Bash tool so the model can actually run the eval... | 2026-09-24 |
| [Q-060](#q-060--orchestrator-fixture-depth) | you: judgment | How far should batch 4 go for code-review and draft-review? | 2026-09-24 |
<!-- index:end -->

## Open



### Q-059 · arith-eval-bash-grant
**Needs:** you: judgment · **Opened:** 2026-09-24 · **Status:** OPEN

Should arithmetic-eval's LLM fixture runs get a restricted Bash tool so the model can actually run the evaluator?

- **Why it's yours:** it's the first fixture run that can execute shell, which breaks the harness's "no Write" rule unless it's constrained. That's a trust-boundary call.
- **Read:** docs/working/plan-skill-fixtures-batch4.md step 5; research-skill-fixtures-batch4.md Gotchas

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Gate tests only** | Deterministic tests of the extracted Mode 1 evaluator and check.py (step 4). No LLM set, so "does the model use the evaluator" stays untested. | None | The skill's main risk (mental math instead of the evaluator) stays unmeasured |
| **[2] Restricted Bash set** | Adds step 5: repo mode, `--allowedTools` limited to python3 invocations, transcript check that python3 ran. A /pre-mortem runs first. | Review one pre-mortem | A too-loose allow pattern lets a fixture run write or read outside the temp repo |

- **Blocks:** step 5 only
- **Interim:** [1]. Step 4's gate tests land either way.
- **If the answer differs:** add step 5 after step 2; nothing is redone.

### Q-060 · orchestrator-fixture-depth
**Needs:** you: judgment · **Opened:** 2026-09-24 · **Status:** OPEN

How far should batch 4 go for code-review and draft-review?

- **Why it's yours:** it trades compute and your review time against coverage. Each fixture run costs about 8 (code-review) or 4-6 (draft-review) agent runs, and draft-review's fact-check needs web egress this sandbox lacks.
- **Read:** docs/working/plan-skill-fixtures-batch4.md step 9; research doc "Feasibility spike"

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Defer** | No sets. The parent plan records why. The existing contract/format suites stay the coverage. | None | Orchestration regressions (skipped stage, silent gap) stay invisible until a real review misfires |
| **[2] One smoke fixture each** | tree-mode repo with critic SKILL.md copies. Checks `subagents_min` and one planted defect surfacing in the rubric. draft-review's prompt says web is unavailable. | Generating costs ~15 agent runs total, when you choose to run it | Smoke passes while per-critic behavior regresses |
| **[3] Full sets (5-7 each)** | Batch 1-3 shape | ~80+ agent runs per full generation, plus longer review | Spend is out of proportion to the signal, since the critics already have their own sets |

- **Blocks:** step 9 only
- **Interim:** [1]
- **If the answer differs:** step 9 is built after step 3; nothing is redone.
