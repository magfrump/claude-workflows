---
value-justification: "Turns the inline Batch fan-out procedure (CLAUDE.md row 2) into a full workflow: orchestrating parallel subagents across isolated git worktrees and reviewing and merging each item on its own as soon as it passes."
---

# Parallel Worktrees (agent-orchestrated batch fan-out)

The agent-facing workflow for decision-tree **row 2**: a single message bundles 2+ independent tasks, and the main agent orchestrates one subagent per item, each implementing in an isolated git worktree, then reviews and merges each item on its own.

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

Manual fallback. Use it for human-driven sessions, when Agent-tool isolation is not available, or when it **fails or misbehaves**. In the cc-isolated sandbox it has failed outright since 2026-09-18 ("Could not read the repository git config…"). Before that it branched from a stale base and left subagents stalled. The by-hand version has run 6 parallel agents cleanly:

```bash
git worktree add .claude/wt-item-1 -b feat/item-1 main   # inside the project, so sandbox writes are allowed
git worktree add .claude/wt-item-2 -b feat/item-2 main
```

Dispatch each agent **without** `isolation`, and tell it to work and commit only under its absolute worktree path. Put the shared brief in one scratch file and give each agent only its item-specific notes. Then poll `git log main..<branch>` rather than waiting on the agents.

### 4. Review and merge each item

The review unit is the item (or the shared-state group from step 1), not the batch. Each one runs its own `pr-prep` — review-fix loop, iteration cap and all — and merges as soon as it is clean:

1. **Review per item.** Run `pr-prep` on each item branch against the integration target (usually `main`; respect the project's branch strategy). Review loops for different items can run in parallel; each has its own iteration counter.
2. **Merge when green, in the order items finish.** An item that converges merges to the target without waiting for the others. A slow or contested item never holds a finished one.
3. **Gate on what will land.** Before an item's final test gate, merge the current target into its branch, so the gate runs on the tree that will land. Items that passed individually can still conflict semantically; a failure here belongs to the item being merged. If two items turn out to touch the same file after all, the later one merges the target in, resolves the conflict on its own branch (never by rewriting the earlier item), and re-runs its gate.
4. **Cross-item context, not a combined review.** When an item changes behaviour another already-merged item relies on, name the merged item in the later item's review brief so the reviewers check the interaction. That replaces a combined review; it does not re-review the merged item.
5. Clean up: `git worktree prune` and delete merged item branches (branch deletion needs user approval per Operating Modes).

**Why per item.** Small, separately reviewed changes are standard review practice: a reviewer reads a small diff more carefully, and a change blocks nothing but itself. The batch rule this replaces ("review the combined diff as one pass") had no recorded rationale, and it failed in practice: in the Q-076/077/078/080 batch (2026-09-27), every Incorrect finding in all three iterations was in Q-076, yet Q-077/078/080 rode through every iteration, re-reviewed unchanged, and waited ~3h20m for a split that came only at the loop cap. The fixed cost of a review run is cut by re-reviewing only the delta (pr-prep 3d), not by bundling.

## Failure modes this workflow exists to prevent

- **Sequential collapse**: grinding through the batch one item at a time in the main agent. That's the default failure; fan out instead.
- **Shared-tree collisions**: parallel subagents editing one working tree. Worktree isolation is not optional for implementing items.
- **Batch-held review**: reviewing the batch as one unit, so the hardest item sets everyone's iteration count and merge time, and each re-review re-reads items that did not change. Review and merge per item (step 4).
- **Lost work**: subagents finishing without committing in their worktree.
- **Stale base / stalled agents**: harness-created worktrees can branch from a commit behind `main`, which makes every merge a conflict, and an agent can hang on a tool call. Branch from `main` yourself. If an agent goes quiet for more than about 10 minutes with a dirty tree, check what is still running (a long test suite is not a hang) before stopping it. Then `git merge main` into its worktree and finish its remaining edits by hand.

## When to pivot

- Items reveal a shared root cause or ordering mid-flight → collapse the affected items into one sequential RPI task; keep the rest parallel.
- An item balloons into a design fork → that item pivots to `divergent-design.md` on its own; don't hold the other merges hostage.
- An item's implementation is committed → `pr-prep.md` for that item (review-fix loop, then merge); the other items proceed independently.
