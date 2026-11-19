# Research: code-review lever #3 correction (2026-11-19)

Brief: `docs/working/briefs/2026-11-19-code-review-lever3-correction.md` (at 57711a66).
Branch: `fix/code-review-lever3-correction`. Workflow: research-plan-implement, no plan gate;
then pr-prep Step 0 and its review-fix loop.

Failure-pattern grep: FP-091, cause:environment-divergence, cause:unverified-claim
Failure-pattern skip: the branch has no fix(...) commit (docs only); the defect's shape, a saving estimated on one transport (the API harness) and carried unmeasured to another (the Agent tool), is already covered by FP-091 (stale pricing note inverting a premise) and the `environment-divergence` and `unverified-claim` cause categories, and is recorded in full by the A8 results and probe docs.

- FP-091 (stale premise inverted a cheap-arm choice): the lesson applies directly. Every rule
  whose stated reason was the cache is checked below for a second reason before it stays.

## What was read (criterion 1)

- `runs/review-arms/a8-2026-11-19/results.md` §2/§4: 9 of 9 agents read only 18,900 cached
  tokens (system prompt and tools) on their first call; the shared block was written fresh
  by every agent. Breakpoints: `system[0]`, `system[1]`, end of request.
- `runs/review-arms/a8-2026-11-19/cache-probe.md`: two agents, same block byte for byte, B
  28.5 s after A: B's cache read stayed 18,900. The Agent tool sends the whole prompt as one
  content block (`messages[0].content[3]`), so no cache entry ends at the shared block's end,
  and no order of the prompt's parts changes that. Cross-pass: same mechanism, inferred.
- Decision 032 (lever #3 on a 20-40% estimate from the cross-model harness, revised to ~5%
  projection by row 34), decision 021 (Stage-1 context: full changeset plus inlined
  enclosing files kills the misattribution FP class), log rows 33-35 (row 35 added the 25k
  budget, the degrade ladder and the stable-first reorder, the last for cache warmth only).
- `guides/sub-agent-briefing.md` anti-pattern 4: pass the path, not the contents; its
  exception names code-review's "byte-identical cacheable prompt prefix".
- The skill's "Inline shared-context prefix" section (:268-359), Stage 1 dispatch
  (:455-489), Stage 2 dispatch (:872-900), Stage 2.5 dispatch (:1026), reminders (:1293, :1301).

## Claims rewritten (criterion 2)

| Where (at 57711a66) | Claim | Now says |
|---|---|---|
| :274-277 | prompt cache serves the block to all ~8 agents, and next pass | no cross-agent saving on the Agent-tool path, citing both docs; cross-pass inferred none |
| :280-283 | benefit "only captured when inlined as one cacheable prefix" | removed (cache rationale) |
| :284-285 | "keep the order so the cached prefix stays stable" | order is a reading order; preamble first for its own reason |
| :307-310 | part 5 "where the saving comes from", second-to-last for cache warmth | removed |
| :311-316 | part 6 "changes every pass, so it is last" | reason removed |
| :318-320 | "so it can be cached" | "so they do not re-fetch it, and all see the same" |
| :322-324 | inlining "trades window for cache reuse" | inlining spends each agent's window |
| :344-354 | stability rules; "single-digit-%... Leave it on because it is free" | removed; cross-model fence bullet kept |
| :137, :1301 | "shared cacheable prefix" | "same shared block in every prompt" |

Rubric row A7 (`docs/reviews/code-review-rubric-2026-08-07-main.md`, marked Fixed) is a
review record not my own and is not in this brief's change list; the skill no longer makes
A7's cross-pass claim. Left for the cycle: A7's status could note that its premise (cache
warmth across passes) does not hold on this path.

## Divergent design: the rules that exist for the cache (criterion 3)

Rules under review: (R1) shared block byte-identical across agents; (R2) shared block first,
verbatim; (R3) fixed stable-first part order; (R4) "only the tail varies"; (R5) fact-check
replicates differ only in output path.

Reason each stands on, apart from the cache:

- R5: decision 031's disagreement measurement (any other variation confounds it). **Keep.**
- R1, as "build once, include verbatim": every critic reviews the same material, so Stage 3's
  convergence detection compares like with like, and no per-agent re-assembly drifts (a diff
  truncated for one critic). This is a consistency reason, not the cache. It does not need
  *byte* identity of the whole block: the security critic's threat-model lines already go
  under the intent heading (Stage 2 step 4), inside the block.
- R2: the goal preamble opens every dispatch (the orchestrated-review goal-preamble pattern,
  `patterns/orchestrated-review.md#goal-preamble`; Stage 2 "Each critic dispatch is prepended
  with the goal preamble"), and the preamble is part 1, so the block still opens the prompt,
  now for the preamble's reason.
- R3: no reason beyond the cache. The listed order is a sensible reading order.
- R4: no reason beyond the cache (and it already conflicts with the threat-model paste).

Candidates:

| Option | What | Constraint read |
|---|---|---|
| A. Status quo, claims only | keep R1-R4, re-label their reason | keeps rules with no reason (S5, S3: a rule must have one); keeps the R4/threat-model conflict |
| B. Keep what has a reason | keep R5, R1 as build-once-verbatim with role-specific additions allowed, R2 via the preamble; drop R3's stability requirement and R4 | each surviving rule names its reason; smallest change (S8); no measured claim needed (S7) |
| C. Drop all structure | orchestrator composes each prompt freely | loses the same-material guarantee convergence detection leans on; R5 must stay anyway (decision 031) |
| D. Reorder per-agent part first | role and skill path first, material after | a change with no measured motive (S5, S7); churns the contract test |

Path A: **B dominates** (A keeps reasonless rules, C drops a rule with a real reason, D
changes behaviour on no evidence). The list keeps its numbering (parts 1-6) so links and the
contract test stay valid; the order is described as a reading order, not a requirement.

## Inlining and the 25k budget (criterion 4)

Kept. Re-grounded: inlining delivers decision 021's Stage-1 context (full changeset plus the
enclosing files of touched hunks, against cross-boundary misattribution; adopted as the
review-quality default by log row 30) the same to every agent, and spares each agent
re-fetching it. The budget is a context-window guard. Its recall effect on this path is
unmeasured (A8 §4 could not tell); the cost-versus-recall test is Q-308 (the owner's open
question on two larger settling runs, after the release).

## The pasting rule (criterion 5)

Evidence. The A8 pass's 9 agents (3 fact-check replicates, 5 critics, Stage 2.5) were told
their skill file's absolute path instead of being given its text (A8 research doc, "Skill
text delivery"). Their transcripts
(`~/.claude/projects/-workspace/711f86df-*/subagents/agent-*.jsonl`, script in this run's
scratchpad) show each one's first skill-file tool call read the file: 8 via Read or `cat` of the whole
file, 1 (`a6a0ebd8`, Stage 2.5) via `head -400` then `sed -n 400,600p` (the whole 535-line
file). The A8 write-up's review agents (fact-check replicates, prompts ~3-4k bytes) also
read `skills/code-fact-check/SKILL.md` by path. 9 of 9 in the pass, no failure seen. Every
critic skill is under 2,000 lines and ~35 KB (largest `ui-visual-review` 34,440 bytes), so
one Read returns it whole. Sub-agents of the Agent tool share the orchestrator's filesystem;
`patterns/orchestrated-review.md` (Context curation, Fallback) already says so.

Options: (1) keep pasting; (2) path plus "read the whole file first"; (3) path plus a
read-receipt line in the report; (4) path, with pasting as the fallback when the agent cannot
reach the path. (1) costs the orchestrator ~60k output tokens a pass and risks transcription
drift across ~250 KB (A8 research doc), against S2 and against the guide (S3: one rule). (3)
adds a ceremony with no failure to guard against yet. (2) and (4) combine without conflict:
**pick (2) with (4)'s fallback clause** (Path A). The path is the copy the session loaded
(`~/.claude/skills/<name>/SKILL.md` when installed). R5 is kept: the three replicates get the
same path, so they still differ only in output path.

Who else shares the rule (for the cycle to file; not changed here):

- `skills/draft-review/SKILL.md` :172, :231-233 (personas.md), :560: shares it.
- `skills/matrix-analysis/SKILL.md` :116, :422: shares it (for items' context).
- `workflows/divergent-design.md` :213: says sub-agents cannot read the DD working doc.
- `patterns/orchestrated-review.md`: does not share it (its Fallback says sub-agents share the
  filesystem), but :151 calls the code-review exception a "byte-identical cacheable prefix",
  the same cache claim.
- `guides/sub-agent-briefing.md` :78: the same "cacheable prompt prefix" claim in
  anti-pattern 4's exception.

## Other choices (one line each)

- Decision 032 amendment: a dated section appended, not edits to the original text (records stay as written).
- Contract test: test 10 (part 5 second-to-last, a cache-only rule) replaced by guards that
  the cache-saving claims and the "cannot read your files" rule stay out; parts 5/6 still exist.
- Section heading kept ("Inline shared-context prefix (decision 032 #3)") so the anchor links
  at :137, :463, :881 stay valid.

## Plan

1. Rewrite the section and the dispatch steps in `skills/code-review/SKILL.md`.
2. Amend decision 032. 3. Update `test/skills/code-review-context-delivery.bats`.
4. Run code-review bats under `test/skills/` and the health check. 5. Review-fix loop.
