# Proposal: an agent first-pass playtest before each `you: walkthrough`

**Date:** 2026-11-12 · **Status:** proposal, nothing implemented · **Source:** owner conversation 2026-11-11/12. The owner named "dogfooding/playtesting to keep up with project status" as one of two real pain points.

## Motive (S5)

A `you: walkthrough` entry spends the most expensive thing the owner has: sitting down with the build. The suspected waste is the first stretch of that session. The owner meets problems an agent could have found:

- the launch command fails;
- the README skips a step;
- a page renders empty;
- a feature named in the entry isn't reachable.

Those findings are real, but they don't need the owner. Once they're found, the owner fixes them and has to come back later for the playtest they came to do.

This is a hunch, not a measurement. S7 says measure before budgeting a saving, so step 1 is the measurement, and the proposal stops there if the hunch is wrong.

## Plan

### 1. Measure first (docs-only unit)

Read every answered `you: walkthrough` entry in the archives of the repos that run these workflows. Classify each answer's first reported problem:

- **(a) mechanical:** crash, missing step, wrong path, empty render;
- **(b) a usability or taste finding only a person could make;**
- **(c) none.**

The decision rule:

- If (a) is under ~20% of answers with any finding, stop and record that. Walkthroughs are already clean enough, and the pain is elsewhere (likely scheduling, which the [cross-project board](proposal-2026-11-12-cross-project-board.md) addresses).
- If there are too few archived walkthroughs to tell (fewer than ~8), say so and treat steps 2–4 as a trial.

### 2. A playtest script per project: `docs/playtest.md`

This is a human-authored file, a few lines per task:

```
launch: <one command, from a fresh clone>
reset:  <command that returns state to a clean start, if any>

## T1 · <task name>
do:     <what a player/user tries, in their words>
expect: <what should visibly happen>
judge:  agent | owner     # agent = mechanically checkable; owner = taste/fun/clarity
```

The `judge:` column is the point of the format. It splits each walkthrough, ahead of time, into what an agent can settle and what only the owner can. An entry whose tasks are all `judge: owner` skips the pre-pass entirely.

### 3. The pre-pass: a `playtest` skill

The skill is invoked when a `you: walkthrough` entry is about to be filed, and only then:

- **Who runs it.** One fresh-context subagent in the project's cc-isolated container.
- **What it sees.** Only `README.md` and `docs/playtest.md`. It is told not to read source, the way a new user can't. That's an honest-slip boundary, not an enforced one (S1). The report lists every file the agent opened, so a source read is visible.
- **What it does.** Runs `launch`, then each task:
  - CLIs and TUIs: it drives them with commands and captures the terminal output.
  - Web UIs: it uses Playwright. Chromium isn't in the cc-isolated image today, and S8 says no new image package without a decision, so web support waits on that decision. CLI-only projects work without it.
- **Personas.** For tasks marked `judge: agent`, it may run the task as 1–2 personas from `ai-personas-critique`'s catalog: a newcomer reading only the README, and a returning user who skips the README. This targets the "missing step" class specifically.
- **Output.** `docs/working/playtest-YYYY-MM-DD.md`, one row per task:

| Task | Verdict | Evidence |
|---|---|---|
| T1 | pass / fail / friction / skipped (owner) | the command run and the verbatim output lines, or a screenshot path |

### 4. Routing the findings

- **`fail` or `friction` on a `judge: agent` task** becomes a roadmap Now item (agent work), and the walkthrough entry is held until it passes. The owner never sees a build that fails to launch.
- **All `judge: agent` tasks pass.** The walkthrough entry is filed with one added line: `Pre-checked: YYYY-MM-DD · N/N agent tasks pass · <link to report>`. Its script is trimmed to the `judge: owner` tasks.
- **The report is advisory (H4).** It never closes or answers an entry, and it never blocks a merge. A pass means "the agent didn't trip"; it does not mean "works".

## Sandbox constraints (from belegarth-herald feedback, 2026-11-12)

Four entries in `docs/working/feedback/belegarth-herald.md` change how step 3 has to run:

- **F-010: subagents can't write report files.** The Write tool refuses them and says to return findings as text. So the subagent returns the task table as text, and the dispatching session writes `docs/working/playtest-YYYY-MM-DD.md` from it. The "files opened" list also comes back in that text.
- **F-009: Agent worktree isolation fails** ("could not confirm the repository's `.git`"). A pre-pass that needs a clean tree uses a worktree made by hand, or a fresh clone in `$TMPDIR`. A fresh clone matches `launch: <from a fresh clone>` better anyway.
- **F-008: a subagent's first Bash call is lost** when its starting directory was already removed. The runner's first call should be a harmless `cd`/`pwd`, and a refused first call is retried once, not counted as a `fail`.
- **F-003 / F-011: prompts outside `auto` mode.** Each runner call that no allow rule matches prompts the owner. That spends the attention this proposal is trying to save. The runner gets an allow rule in the same change, as one command shape (`bash <runner> <task-id>`), not one rule per task command.

Step 1 also crosses repos: reading other projects' walkthrough archives runs into the board proposal's host-vs-container problem. Run step 1 per project, in each project's own session, and collect the counts by hand. Or wait for that decision.

## Cost (S2, S8)

- **Dispatch:** one subagent per walkthrough entry, not per cycle or per pass. At today's walkthrough rate that is a handful of dispatches a month. No always-loaded context is added.
- **Code:** a skill file plus a small runner script that executes `launch`/`reset`/task commands with a timeout and captures output. The runner gets bats coverage with a fixture project (H3). Both are under the ~400-line cap.
- **Owner cost:** writing `docs/playtest.md` once per project, about 10–20 minutes, then a line per new feature.

## Observable (S6, can come out negative)

Over the next ~8 walkthroughs after landing, the owner answers one extra field: `blocked-before-interesting: yes/no`.

- **It's working** if fewer than 2 of 8 come back `yes`. Compare that to the step-1 baseline share of class (a).
- **It's false-greening** if any walkthrough the pre-pass marked all-pass is blocked by a mechanical failure in a `judge: agent` task. One instance means fixing the runner; two means retiring the skill (one revert).

## What it can't do

- It can't judge whether something is fun, clear or good. A TTRPG or game project will be mostly `judge: owner`, and for those the pre-pass only guarantees that the prep tooling launches and that the files the session needs exist.
- It can't tell the README is wrong when the README and the behavior agree on something the owner didn't intend. Only the `expect:` lines, which the owner writes, catch that.
- Hunch, ~50%: it catches about half of the first-contact blockers the owner would otherwise hit. Step 1 replaces this guess with a number.

## Relation to existing pieces

- `workflows/user-testing-workflow.md` Phase 0 requires naming the decision a test informs. `docs/playtest.md`'s `expect:` lines are a lighter form of that, for solo dogfooding rather than recruited participants.
- The walkthrough-ready gate from the same conversation (idea 4: a `you: walkthrough` entry needs a one-command launch and a short script) is what step 2 formalizes. If that gate lands first, this proposal is the gate plus an automated check of it.
- Phone tie-in: the report's evidence (verbatim output, screenshot paths) can be read away from the laptop, so a walkthrough can be triaged before the owner sits down.

## Open questions for the owner

These are not filed as Q entries yet.

1. Which project is the first trial? It should have a CLI or TUI surface, so that it doesn't wait on the Chromium decision.
2. Should the pre-pass run automatically when the dev cycle is about to file a `you: walkthrough` entry, or only when the owner asks?
3. Should Chromium/Playwright go into the cc-isolated image? This is a separate decision under S8 and only matters for web projects.
