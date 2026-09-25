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
| [Q-061](#q-061--host-stage-review-copies) | you: judgment | The host target's stage can be swapped for the review and swapped back before y (the re-review's R2, 6/6 ru... | 2026-09-25 |
| [Q-062](#q-062--leftover-helper-is-agent) | you: judgment | Under Q-058 [2], does a background process an agent session left running (a detached helper, a loop driver ... | 2026-09-25 |
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
- **Update 2026-09-24:** since a75ba3e, fixture runs pass `--restricted --safe-mode`, and runner-contract.bash allows only Read, Grep, Glob, WebSearch, WebFetch and Agent. [2] therefore also means adding a scoped Bash entry to that allowlist. `--restricted` confines the file tools to the temp dir, but per the CLI help it does not sandbox shell commands, so the pre-mortem in [2] still applies. [1] is unaffected.
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

### Q-061 · host-stage-review-copies
**Needs:** you: judgment · **Opened:** 2026-09-25 · **Status:** OPEN

The host target's stage can be swapped for the review and swapped back before y (the re-review's R2, 6/6 runs). Do we move the review onto the copies under `~/.claude`, or accept this under your Q-058 answer?

- **Why it's yours:** Q-058 [2] made "no agent runs during the install" the trust model. [1] adds option [1] from Q-058 (sandbox-protected staging) on top of it for the host target. That goes past what you chose, even though it only adds protection.
- **Read:** `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md` R2; `docs/reviews/security-review-2026-09-24-copy-install-q058.md` F1 (with the SP1 probe) and F8

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Review the installed copies** | Stage into `~/.claude/.cw-new.*` (denyWrite) before the review, review those, then hash-check and swap them. The host target stops depending on the gate. | Nothing now. The review diff reads from a different path. | About 15 extra installer lines to maintain, guarding a case the gate is meant to prevent |
| **[2] Accept it; correct decision 037** | 037:66 is rewritten to say the hash only catches edits that persist, and a writer that swaps and restores is caught only if the gate sees it at y | None | An unsandboxed or unseen writer can get an unreviewed hook into `~/.claude`, which runs in every session |

- **Blocks:** merging `skill-fixtures` to main (you asked for merge after review; R2 is red until this is settled)
- **Interim:** [1] is implemented with the other review fixes, so the merge isn't blocked. It hardens the installer and doesn't loosen anything. 037 records it as provisional pending this answer.
- **If the answer differs:** [2] reverts that one commit and applies the 037:66 rewrite. Nothing else depends on it.

### Q-062 · leftover-helper-is-agent
**Needs:** you: judgment · **Opened:** 2026-09-25 · **Status:** OPEN

Under Q-058 [2], does a background process an agent session left running (a detached helper, a loop driver between `claude` iterations) count as "an agent"?

- **Why it's yours:** it sets the scope of your own trust-model answer. The gate only recognizes Claude-shaped command lines, so "yes" needs a broader, noisier check.
- **Read:** the re-review's A2; security review F3 (SP2 and P4 probes)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] No; document it** | 037 lists leftover non-Claude processes as a residual. Stopping them before an install is on you. | Remember to kill loop drivers before installing | A leftover helper writes during the install, unseen |
| **[2] Yes; widen the gate** | Also refuse any other process of your uid whose working directory is inside the checkout, and name it | Occasional refusals naming an editor or shell sitting in the repo; close it and re-run | Nuisance refusals every time a terminal is open in the repo |

- **Blocks:** nothing (A2 carries this entry as its author note)
- **Interim:** [1]. The cheap fail-closed fixes land either way: a gate before host staging, and a wider regex covering the versioned native path and the Agent SDK CLI.
- **If the answer differs:** [2] adds one detector to `agent_gate` and a test. Nothing is redone.
