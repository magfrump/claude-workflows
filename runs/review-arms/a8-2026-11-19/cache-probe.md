# A8 cache probe: two agents, one shared block, dispatched in sequence (2026-11-19)

Brief: `docs/working/briefs/2026-11-19-a8-cache-probe.md`. Question from `results.md` §4
("Three things would tell", first item): when two review agents carry the same inlined shared
block and the second starts inside the cache lifetime, does the second read the block from the
prompt cache? If it does, the A8 pass missed only because its agents launched within
milliseconds of each other. If not, cache breakpoints are the cause.

## Method

- Shared block: `csp/shared-block.md` (8,755 bytes, the A8 pass's Stage-1 block), pasted
  verbatim as the start of each prompt.
- Tail: a one-line minimal tail after the block, differing only in the agent's letter
  ("Cache probe agent A." / "Cache probe agent B.", then: do no work, use no tool, hand back
  `OK`). That is how a real pass differs too: one block, then a per-agent tail.
- Dispatch: two `general-purpose` Agent-tool subagents from the same orchestrator session,
  same model (claude-opus-5-5), B dispatched after A had finished.
- Readout: each agent's transcript (`~/.claude/projects/-workspace/<session>/subagents/agent-<id>.jsonl`),
  which holds the request records the A8 run read: `api-request-blob` (per-message content
  blocks), `api-request` (`cacheControl` breakpoint paths, timestamp) and the first
  `assistant` record's `usage`. The script checked that each prompt starts with the block file
  byte for byte, then hashed each content block.

## Result

| | Agent A | Agent B |
|---|---|---|
| First request sent | 19:39:13.000Z | 19:39:44.554Z (28.5 s after A's reply at 19:39:16.055Z) |
| Prompt starts with `shared-block.md` byte for byte | yes | yes |
| Breakpoints | `system[0]`, `system[1]`, `messages[1].content[3]` | same |
| `cache_read_input_tokens` | 18,900 | **18,900** |
| `cache_creation_input_tokens` | 31,731 | 31,731 |
| `input_tokens` / `output_tokens` | 2 / 52 | 2 / 52 |
| Notified `subagent_tokens` | 50,685 | 50,685 |

B started 28.5 s after A, well inside the 5-minute lifetime (`promptCacheRequested: 5m`). Its
cache read did not rise at all. **Timing was not the cause.** The A8 pass's zero cross-agent
reads are structural on this path, as `results.md` §2 inferred.

## Why: where the breakpoints sit

The request records show the layout of each agent's first request:

- `system[0]`, `system[1]`: the agent's system prompt. Breakpoints 1 and 2 sit here, and tools
  and system are what the 18,900 cached tokens are.
- `messages[0]` (user), five text blocks: [0] the instruction files, [1] git status,
  [2] commit attribution, **[3] the whole prompt (shared block + tail)**, [4] the hand-off
  reminder. Blocks 0-2 and 4 hash the same in A and B; only block 3 differs.
- `messages[1]` (a system-role message), four blocks: [0] the tool, deferred-tool-name,
  environment and skill listings; [1]-[3] the definitions of three tools that became ready to
  use (the Claude Docs connector). Breakpoint 3 is on its last block, `messages[1].content[3]`:
  the end of the request.

A small correction to `results.md` §2, which reads this path as "the end of the first user
turn": `messages[1]` is the system-role message after the user turn, so breakpoint 3 is the
last block of the request. The conclusion stands: the breakpoint sits after the per-agent tail.

Prompt caching matches on whole content blocks. On each breakpoint the API checks earlier
content-block boundaries (up to about 20 blocks back) for an entry an earlier request wrote
there. (Source: Anthropic's prompt-caching page, platform.claude.com/docs/en/build-with-claude/prompt-caching,
seen through a web-search summary only; this sandbox cannot fetch it, so treat the wording as
unverified.) A's entries end at `system[1]` and at the end of its own request. B's request
differs from A's inside `messages[0].content[3]`, so the longest entry B can match is
`system[1]`: 18,900 tokens. Nothing ever ends at the shared block's last byte, since the block
and the tail are one text block.

## Does any prompt order put a breakpoint at the end of the shared block?

No. The Agent tool takes the prompt as one string and sends it as one content block. The
breakpoints are placed by Claude Code on the system prompt and on the request's last block.
The orchestrator controls neither. Reordering text inside the prompt cannot make a block
boundary at the shared block's end, so no order of the "Inline shared-context prefix"
section makes the block cacheable across agents. Per the brief (criterion 2), the skill is
unchanged.

Only a byte-identical whole prompt would match, with the per-agent part delivered some other
way. That is a different mechanism, not a prompt order, and it is outside this brief.
Matching would serve more than the block: B would read its whole request from cache, about
50.6k tokens (18,900 + 31,731) instead of 18,900, instruction files and listings included. It is noted here for whoever
weighs lever #3 next, not proposed.

## What this means for A8

Decision 032 lever #3 (inline the shared review context so the agents share it from the cache)
yields no cross-agent cache reads on the Agent-tool path, parallel or sequential. The skill's
"This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a pass" and
"Leave it on because it is free" (`skills/code-review/SKILL.md:274-277`, `:352-354`) describe a
saving that does not occur. What remains is each agent's own reuse within its run, which
happens with or without inlining (`results.md` §2). The probe did not test reuse across
loop passes. By the same mechanism, a later pass's agent hits only if its whole prompt is
byte-identical to an earlier one's, and every fix commit changes the block's diff part. This
also bears on rubric row A7 of `docs/reviews/code-review-rubric-2026-08-07-main.md` (marked
Fixed): its stable-parts-first order (`SKILL.md:347-351`) keeps parts 1-4 a common prefix, but
no breakpoint ends there either, so by this mechanism it buys no cross-pass cache hit. That is
inferred from the records, not measured. The net inline cost and the recall effect remain Q-308's (the owner's open question
on two larger settling runs).

Cost of the probe: 2 × 50,685 = 101,370 tokens by the notified figure. Nearly all of that is
the harness context every agent starts with, not the tail. These two agents are not rows in
`token-ledger.md` or `manifest.json`: the brief's file list for this change (the probe doc,
the rubric row, any skill change and the research doc) leaves those files out, so the table
above is the probe's per-agent record, and this paragraph states the omission.
