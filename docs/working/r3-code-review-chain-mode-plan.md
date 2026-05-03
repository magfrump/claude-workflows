# R3 — code-review chain mode plan

## Goal

Document an opt-in `chain` dispatch mode for `skills/code-review.md` Stage 2,
covering 2 named scenarios where one critic's findings genuinely change the
next critic's scope. Default remains parallel.

## Named chain pairs

1. **`security-reviewer → api-consistency-reviewer`** — When the diff shifts
   auth/trust boundaries, the API surface around them is the next thing to
   examine. Security runs first; its auth/boundary findings are passed to
   api-consistency-reviewer as scope hints so it can check whether the new
   auth contract is consistent across endpoints, schemas, and exported
   handlers.
2. **`test-strategy → tech-debt-triage`** — When test-strategy identifies
   coverage gaps, the gap list often points at a poorly-modeled subsystem.
   tech-debt-triage runs second with the gap list as priority targets — it
   inspects modules with both missing tests AND structural complexity
   instead of blanket-scanning the diff.

## Edits

1. **Step 5 (User overrides)** — add `--chain <pair>` flag and list the two
   supported pairs. One-line decision: presence of the flag selects chain
   mode; absence keeps parallel default.
2. **New `### Stage 2 dispatch modes` subsection**, placed between
   `### Core critic relevance check` and `### Stage 2: Critic Agents`.
   Documents:
   - Default: parallel (existing behavior).
   - Opt-in: chain — run the upstream critic, await results, then dispatch
     the downstream critic with a "Chain context" block citing upstream
     findings. Non-chained critics still run in parallel alongside the chain.
   - Both supported pairs with trigger and what the upstream → downstream
     handoff carries.
   - Trade-off: slower (sequential within the pair) but enables narrowed
     scope. Use only when the trigger applies.
3. **Between-stage status banner spec** — extend `<key counts>` to include
   `dispatch mode: <mode>` so the Stage 2-complete (synthesis-introducing)
   banner names the mode that produced the findings. Update Stage 1 banner's
   `<next action>` example to flex between "in parallel" and
   "in chain (security→api-consistency) + N in parallel".

## Out of scope

- Auto-detecting when chain mode applies (defer; orchestrator decision is
  manual via flag).
- Chain pairs beyond the two named.
- Updating `patterns/orchestrated-review.md` (file-scope constraint).
