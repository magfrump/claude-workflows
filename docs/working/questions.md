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
| [Q-063](#q-063--arith-eval-evaluator-check) | you: judgment | How should arithmetic-eval's LLM fixtures check that the model uses the evaluator? (Replaces Q-059, per you... | 2026-09-25 |
<!-- index:end -->

## Open



### Q-063 · arith-eval-evaluator-check
**Needs:** you: judgment · **Opened:** 2026-09-25 · **Status:** OPEN

How should arithmetic-eval's LLM fixtures check that the model uses the evaluator? (Replaces Q-059, per your equivalence suggestion.)

- **Why it's yours:** [2] adds a component that decides whether a shell command runs. [1] and [3] execute nothing.
- **Read:** `docs/working/dd-arith-eval-bash-grant.md` (13 candidates, matrix). Q-059's old [2] was pruned there: an allow rule loose enough for the Mode 1 command also allows any `python3 -c` program.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Deny-and-record + static equivalence** | Bash is listed, but every call is denied. The harness takes the denied command from the transcript, checks it is exactly SKILL.md's Mode 1 program, and runs the extracted expression through its own copy of the evaluator. If any Bash call actually executes, a tripwire fails the run. | None. No pre-mortem needed, since nothing runs. | What the model does after seeing a real result goes unmeasured. It rests on denied calls being recorded; if they aren't, it falls back to `permission_denials`, and if that fails too it drops to [3]. |
| **[2] Equivalence-gated live approval** | The same check runs live as the permission handler, so only an exact Mode 1 match on a numbers-only expression runs | One pre-mortem, about 2 days of work | A matching bug in the handler opens a shell. It is also unverified whether `--safe-mode` keeps the MCP server the handler needs. |
| **[3] Dry-run disclosure** | No Bash. The prompt asks the model to print the command it would run, and that command is checked for equivalence | None | It tests whether the model knows the procedure, not whether it reaches for the evaluator unprompted |

- **Blocks:** plan step 5 only
- **Interim:** nothing built. Step 4's gate tests already cover the evaluator itself. [1] needs one cheap-model probe (the command is in the DD doc) to confirm that denied calls are recorded. It waits for your answer, per the no-compute-before-A8 memory.
- **If the answer differs:** [2] can be added later on top of [1]; nothing is redone.

