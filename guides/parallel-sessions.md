# Parallel Sessions Guide (Human Orchestration)

This is a guide for the human developer, not instructions for the AI agent. It describes how to run multiple Claude Code sessions concurrently for maximum throughput.

## When to use
- You have 2+ tasks that are genuinely independent (no shared files being modified)
- End of your work day when you want to queue work for async review overnight
- During meetings or other low-attention time where you can review outputs but not actively pair
- A large feature decomposes cleanly into independent branches

## Setup: git worktrees

Each parallel session needs its own working directory to avoid file conflicts. Git worktrees are the cleanest way to do this:

```bash
# From the repo root, create isolated workspaces branching from main
git worktree add ../project-task-1 -b feat/task-1 main
git worktree add ../project-task-2 -b feat/task-2 main
```

Then open a separate Claude Code session in each worktree directory.

## Writing good task prompts

Each session gets a self-contained prompt. The session for task 2 should not need to know about task 1. Include:

- What to implement (specific and concrete)
- Which workflow to follow (usually "follow the research-plan-implement workflow in ~/.claude/workflows/")
- What "done" looks like (acceptance criteria)
- Any constraints ("don't modify files outside of `app/components/features/context-input/`")

Example:
```
Follow the research-plan-implement workflow. 

Task: Add a /api/formalize endpoint that accepts text input and context, 
calls the OpenRouter API, and returns a formalized version.

Acceptance criteria:
- Endpoint handles POST with JSON body {text, context}
- Calls OpenRouter with the prompt template in docs/working/research-formalize-api.md
- Returns {formalized_text, model_used}
- Error handling for API failures
- npm run lint passes

Do not modify any frontend components.
```

## How many sessions

2-3 concurrent sessions is the practical sweet spot. More than that and your review quality drops — you become a bottleneck approving plans you haven't really read.

## Monitoring

Check in on each session periodically:
- Has it produced a research doc? Does it look right?
- Has it produced a plan? Does the plan make sense?
- Is it stuck or going off track?

Course-correct early. A wrong research doc caught in 5 minutes saves 20 minutes of wrong implementation.

## Merging

When sessions complete:
1. Review each branch independently (use the pr-prep workflow)
2. Run full CI on each
3. Merge sequentially into main, rebasing each onto updated main:
   ```bash
   git checkout main
   git merge feat/task-1
   git checkout feat/task-2
   git rebase main
   # resolve any conflicts
   git checkout main
   git merge feat/task-2
   ```
4. If there are integration conflicts, they indicate a decomposition mistake — the tasks weren't truly independent. Fix the conflicts and note what was coupled for next time.

## Async handoff for timezone-offset collaboration

This is where parallel sessions are most valuable:

1. Before signing off: push all branches, open draft PRs with descriptions
2. Your coworker reviews during their day, leaves comments on each PR independently
3. You address feedback when you wake up

Queuing 2-3 PRs before end-of-day means your coworker has a full day of review work instead of waiting for a single serial PR. This effectively doubles your throughput across the timezone gap.

## Cleanup

```bash
# After merging, remove worktrees
git worktree remove ../project-task-1
git worktree remove ../project-task-2
```

## Quick reference

| Action | Command |
|---|---|
| Create a worktree | `git worktree add ~/wt-name -b branch-name main` |
| List worktrees | `git worktree list` |
| Remove a worktree after merge | `git worktree remove ~/wt-name` |
