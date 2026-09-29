---
name: dev-cycle
description: >
  Run one maintenance cycle: signal digest, health and cleanup, revisit triggers, spot-check audit, brainstorm, roadmap. Not for landing one change (pr-prep). Triggers: "run the dev cycle", "maintenance pass", "what next", "update the roadmap".
---

> On bad output, see guides/skill-recovery.md

# Dev Cycle

The outer loop. The inner loop (`research-plan-implement` → `pr-prep` → `review-fix-loop`)
lands one change at a time; this skill steps back over everything that landed since the last
cycle, checks that the repo is healthy and its past decisions still hold, and decides what
comes next. It runs when the user starts it; there is no timer.

**Attention is the budget.** A cycle succeeds when it turns signals into triage, not when it
produces a long report. Everything mechanical is fixed or routed to `agent`; only decisions
that need the user become `you: judgment` entries in `docs/working/questions.md`, using the
entry grammar in the global instructions ("Running questions document").

## Steps

Run them in order. Every step ends with a line in the cycle record, including "skipped:
<reason>". A skipped step is recorded, never silently dropped.

### 0. Digest

Run `scripts/dev-cycle.sh` (installed copy: `~/.claude/scripts/dev-cycle.sh`) from the repo
root and keep its output. It is read-only and gives the window (since the last cycle record),
merges in it, every revisit trigger, the watched questions, the spot-check sample and the
roadmap's Next section. If the repo has no `docs/working/questions.md`, run `questions.sh
init` first.

### 1. Health and cleanup

- Start the project's full check in the background, output to a file (in claude-workflows:
  `scripts/health-check.sh`). Quiesce first: no subagents running, no stray probe processes.
  Read failures from the file and triage them as pr-prep step 5a does (caused by recent work,
  pre-existing, flaky).
- `questions.sh archive` then `questions.sh index`, so answered entries leave the live file.
- `git worktree list` and `git worktree prune`. List merged branches; deleting them needs the
  user's approval, so put the list in one `you: terminal` entry rather than deleting.
- Stale working docs: in claude-workflows, `scripts/archive-working-docs.sh -n` lists what
  would move. Archive working docs whose task has merged; leave anything still cited.
- Fix what is mechanical now, one commit per concern. File the rest.

### 2. Revisit triggers

For every trigger in the digest, decide **fired / not fired / cannot tell** and write the
evidence (a command and its output, a count, a commit). "Cannot tell" names what would tell.
A fired trigger becomes a questions.md entry that links the decision record; route it
`agent` when the trigger itself names the response, `you: judgment` when it reopens a choice.
Do not reopen a decision on a trigger that has not fired.

### 3. Watched questions

For each open `trigger` or `deferred` entry, check its own condition. If it has been met,
change its route and say why in the entry; if its entry names an observation, it stays open
until that observation has been made. Also list any `agent` entry older than two weeks: it
is either done now or explained.

### 4. Spot-check audit

For each sampled merge, pick the one or two claims the merge rests on (from its commit
message, decision-log row, or plan) and re-verify them against today's code: run the test
it cites, reproduce the number, read the code path. Use `code-fact-check` at k=1 for a
merge with many claims. A claim that no longer holds is a finding: fix it if mechanical,
otherwise file it. Record what was checked even when everything held.

### 5. Brainstorm

Generate 3–8 candidate features or improvements. Each must name the **signal** that
motivates it (a failing health warning, a fired trigger, a repeated friction seen in this
cycle, a never-used skill, a spot-check finding) and what it would change. An idea without
a signal is dropped. Where a candidate is really a choice among 3+ approaches, note it for
`divergent-design` instead of picking here. "Do nothing" is a valid outcome.

### 6. Roadmap

Update `docs/roadmap.md` (create it from its own template if missing):

- **Now**: work in progress, with its branch or plan doc.
- **Next**: at most five items, ranked. Each names its motive and its first concrete step.
- **Ideas**: this cycle's surviving brainstorm items, unranked, each with its signal.
- **Done**: items finished since the last cycle, with the merge.

Re-ranking Next is yours when it follows from this cycle's evidence. When a change would
reorder the user's stated priorities, propose it as one `you: judgment` entry instead.

### 7. Close

Write `docs/working/cycles/cycle-YYYY-MM-DD.md`: the window, one line per step (done /
skipped and why), the questions filed by ID, and the roadmap diff. Commit it with the
roadmap and questions changes. In the final message, list the new `you: judgment` entries by
ID and name; do not make the user open the file to find them.
