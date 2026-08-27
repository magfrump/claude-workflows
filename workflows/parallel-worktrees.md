---
value-justification: "Turns the inline Batch fan-out procedure (CLAUDE.md row 2) into a full workflow: orchestrating parallel subagents across isolated git worktrees and merging their branches back into one reviewable unit."
---

# Parallel Worktrees (agent-orchestrated batch fan-out)

The agent-facing workflow for decision-tree **row 2**: a single message bundles 2+ independent tasks, and the main agent orchestrates one subagent per item, each implementing in an isolated git worktree, then merges the branches back.

**Not this workflow:**
- *One* task whose research fans out but whose implementation stays sequential → `task-decomposition.md` (row 7).
- A human running multiple concurrent Claude Code sessions in separate worktrees → `guides/parallel-sessions.md` (human-facing).
- Managing many long-lived feature branches with async review → `branch-strategy.md` (row 11).

## When to use

Any of these is enough to recognize a batch: a numbered or bulleted list of asks; enumeration phrasing ("a few things", "couple of bugs", "here's the feedback"); or several distinct imperatives in one message. The bar is deliberately low — when in doubt whether two asks are independent, treat them as independent and fan out. Merging back N small worktrees is cheap; re-running a sequential pass is not.

**When NOT to fan out:** the items are one task wearing several hats — sequential dependencies, or all edits to the same function. Ask: "do these share files or an order?" Yes → RPI (row 6) or task-decomposition (row 7). No → this workflow.

## The procedure

### 1. Split

Restate the batch as an explicit numbered task list. This doubles as the user's confirmation that you parsed their feedback correctly. Group items that genuinely share files or state into one unit — those go to a single subagent so they don't collide.

### 2. Classify each item

Route each item back through the decision tree *individually*. One item might be an RPI feature, another a one-line bug fix, another a DD decision. The batch row is a pre-pass, not a destination — it does not pick the workflow for the items. Include the chosen per-item workflow in each subagent's brief.

### 3. Dispatch

Send the subagents in parallel — one Agent call per item (or per shared-state group), all in a single message so they run concurrently. For each subagent:

- **Focused brief**: the item, its workflow, acceptance criteria, and any constraints ("don't modify files outside X"). Each brief must be self-contained — subagent N should not need to know about item M. See `guides/sub-agent-briefing.md`.
- **Worktree isolation for any item that writes code**: pass `isolation: "worktree"` on the Agent call so parallel implementations never touch the same working tree. The harness creates the worktree and auto-cleans it if unchanged.
- Read-only/triage items don't need a worktree.
- Instruct each implementing subagent to **commit its work inside its worktree** before finishing (conventional prefixes; autonomous commit format in /away mode). Uncommitted worktree changes are what get lost.

Manual fallback (no Agent-tool worktree isolation available, or human-driven sessions):

```bash
git worktree add ../proj-item-1 -b feat/item-1 main
git worktree add ../proj-item-2 -b feat/item-2 main
```

### 4. Merge and reconcile

Collect the subagent reports, then merge the branches back into one unit:

1. Merge each item's branch into the integration target (usually the current branch or `main` — respect the project's branch strategy). Merge the smallest/most-isolated items first; conflicts surface earliest where they're cheapest.
2. If two items turn out to touch the same file after all: sequence those two (merge one, rebase/re-run the other on top), keep the rest parallel. Resolve conflicts in the integration branch, not by rewriting the item branches.
3. Run the project's tests/build on the **combined** result — items that pass individually can still conflict semantically.
4. Run the combined diff through `pr-prep` / `code-review` as **one pass**, not per-item.
5. Clean up: `git worktree prune` and delete merged item branches (branch deletion needs user approval per Operating Modes).

## Failure modes this workflow exists to prevent

- **Sequential collapse**: grinding through the batch one item at a time in the main agent. That's the default failure; fan out instead.
- **Shared-tree collisions**: parallel subagents editing one working tree. Worktree isolation is not optional for implementing items.
- **Per-item review fragmentation**: N tiny review passes instead of one combined pass. Review the merged diff once.
- **Lost work**: subagents finishing without committing in their worktree.

## When to pivot

- Items reveal a shared root cause or ordering mid-flight → collapse the affected items into one sequential RPI task; keep the rest parallel.
- An item balloons into a design fork → that item pivots to `divergent-design.md` on its own; don't hold the other merges hostage.
- All work merged and reconciled → `pr-prep.md` (which embeds the review-fix loop).
