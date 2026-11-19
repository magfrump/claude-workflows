# Research: A8 cache probe and the closing note for rubric row A8

Brief: `docs/working/briefs/2026-11-19-a8-cache-probe.md` (at 8b060877). Branch: `measure/a8-cache-probe`.
Probe record: `runs/review-arms/a8-2026-11-19/cache-probe.md`.

## Question

The A8 measurement (`runs/review-arms/a8-2026-11-19/results.md` §2) found that no review agent
read the inlined shared block from another agent's cache, and inferred from the request records
that breakpoints sit after the per-agent tail. Stages 1 and 2 could not separate that from
timing (agents launched within milliseconds). A two-agent sequential probe can.

## What I know (context)

- Request records live in each subagent's transcript,
  `~/.claude/projects/-workspace/<session>/subagents/agent-<id>.jsonl`: `api-request-shape`
  (system and tools), `api-request-blob` (per-message content blocks), `api-request` (`cacheControl`
  paths, `tail` blob hashes, timestamp). This is how the A8 run read them.
- In an A8 record (Stage 2.5's agent), the first request is: system (2 blocks, breakpoints on
  both); `messages[0]` user with 5 text blocks (instructions, git status, attribution, the
  prompt, the hand-off reminder); `messages[1]` a system-role message with the tool, deferred-name,
  environment and skill listings, then three newly ready tool definitions, breakpoint on its last block.
- Skill section under test: `skills/code-review/SKILL.md` "Inline shared-context prefix
  (decision 032 #3)", lines 268-358.
- Rubric row: `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `🟡 Open`; status
  words in `skills/code-review/references/rubric.md` "Status words".
- Q-306: the owner approved merging the A8 results. Q-308: the owner's open question on the
  two larger settling runs (self-read control, corpus cell). Out of scope here.

Failure-pattern grep: FP-089, FP-091
- FP-089 (count claims drift across citing documents): the probe doc and the rubric cell cite
  the same figures (18,900; 28.5 s); keep them copied from the probe output, not retyped.
- FP-091 (a stale note inverts a premise): the web source for cache matching was seen only
  through a search summary (no egress), so the docs say it is unverified and the verdict rests
  on the records, not on it.

## Method

Two `general-purpose` subagents, the A8 Stage-1 block (`csp/shared-block.md`) pasted first,
then a one-line tail differing in one letter; B dispatched after A finished. A stdlib script
(scratchpad, `probe.py`) checked each recorded prompt starts with the block file byte for byte,
hashed each content block, and printed breakpoints and first-call usage.

## Findings

- Both prompts start with the block byte for byte. All user content blocks except [3] (the
  prompt) hash the same; the system-role message hashes the same.
- A: read 18,900, created 31,731. B, 28.5 s after A's reply: read 18,900, created 31,731.
  Timing was not the cause; the zero cross-agent reads are structural.
- Breakpoints are fixed by Claude Code at `system[0]`, `system[1]` and the request's last
  block. The prompt is a single content block, and cache matching is by whole block (Anthropic
  prompt-caching docs via a search summary, unverified here). So no ordering inside the prompt
  puts a block boundary, let alone a breakpoint, at the shared block's end. Criterion 2's
  "no" branch: the skill stays unchanged.
- Minor correction to `results.md` §2: breakpoint 3 is on the system-role message after the
  user turn, not on the user turn's end; still after the tail. Recorded in the probe doc,
  not edited into the merged results (outside the brief's doc list).

## Design choices

- Change the skill or not: not a choice; criterion 2 decides on the probe result (no order works).
- Rubric status word for A8: `Split`, naming Q-308 (net cost, recall) and the skill-text
  correction this branch's `handoff: ready` marker asks the cycle to file (the brief keeps the
  questions files and roadmap off limits, and a marker body is the build loop's channel for
  what the cycle files). Review pass 1 caught a first Split that named only Q-308; pass 2
  caught the interim `🟡 Open` cell, which named Q-IDs and so read as closed to
  `scripts/lib/rubric-check.sh` while the file's status line said open. `Acknowledged` was
  the other viable word and needs a tracked follow-up or a revisit trigger.
- The rubric file's status line takes the template's all-resolved form, since every other
  red and amber row there is fixed.
- Not proposed: a byte-identical whole prompt with the role sent another way would let a
  sibling read its whole request (~50.6k) from cache. That is a pipeline change, out of scope; noted in the
  probe doc for whoever weighs lever #3 next.

## Follow-up for the cycle

For the cycle to file as a roadmap item: "code-review: correct the lever #3 cache-saving text". The skill still says the
cache "serve[s] the shared block to all ~8 agents" and "Leave it on because it is free"
(`SKILL.md:274-277`, `:352-354`); the probe shows that saving does not occur on the Agent-tool
path. The same claim recurs at `:307-310` and `:322-323`, and the stable-parts-first rule's
cross-pass warmth (`:347-351`, rubric row A7) fails by the same mechanism (inferred, not
measured). Correcting that text is a pipeline change the brief puts out of scope. The
handoff marker carries this line, and row A8's Split names the title.

## Plan

1. Probe (done), probe doc.
2. Rubric row A8 Status cell, rubric status line.
3. Review-fix loop over the doc changes; brief Status line to done; marker.
