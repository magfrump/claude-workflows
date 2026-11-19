# Research: A8 post-restructure token measurement (one canon cell)

Brief: `docs/working/briefs/2026-11-19-a8-token-measurement.md` (at 4330e303). Branch: `measure/a8-token-measurement`.
Results: `runs/review-arms/a8-2026-11-19/results.md`.

## Question

Rubric row A8 (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`) says the code-review
skill's "leave it on because it is free / 0% of token count" claim for inlining the shared
review context (decision 032 lever #3) rests on a pre-change projection (~5.3%,
`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`), and that inlining the
enclosing files adds prompt tokens each agent previously fetched selectively. One measured
cell under today's skill answers part of that.

## What I know (context)

- Baseline cell csp: range `d86d2dc..d90d6bb` in meta-formalism-copilot
  (`/workspace/external/meta-formalism-copilot`, reachable here), 2 files, +72/-1.
  Baseline per-cell core = 358,626 tokens (fc k=1 74,274 + security 77,879 + performance
  67,010 + api 68,604 + architecture 70,859). The test-strategy gap-fix (65,894) ran later
  and is NOT in the 359k per-cell figure, but is in the 2.99M canon total.
- Baseline delivery was self-read: critics got a scope spec and read the diff and files
  with tools (levers-3-4 doc: shared prefix ~330 tokens).
- Today's skill (`skills/code-review/SKILL.md`, last changed 44724747; 82accdd7, 2026-11-14, its child, touched only `references/rubric.md`) inlines
  diff + enclosing files as a byte-identical shared prefix within a 25k-token budget,
  runs k=3 fact-check on a terminal pass, and adds Stage 2.5 (submitted-claims fact-check)
  when critics route endorsement claims; Stage 2.5 did not exist on 2026-08-06.
- Canon labels for csp: `docs/working/canon-issue-ledger.md:92-97` (R1 connect-src/data:,
  R2 Edge-runtime comment, A1 dead x-nonce plumbing, A2 style-src/Tailwind
  misattribution, A3 await-headers comment, A4 no CSP directive tests).

## Method

1. Scratch worktree of the benchmark repo at `d90d6bb`, created in this session's
   scratchpad (`git -C /workspace/external/meta-formalism-copilot worktree add --detach`),
   never in this repository's tree; removed at the end.
2. One terminal pass (no `--loop-pass`): k=3 fact-check (opus), Stage 1.5 gating, the gated
   critic panel (opus), Stage 2.5 if routed claims exist, Stage 3 synthesis inline by the
   orchestrator (as the baseline did; not part of the core total).
3. Tokens: the `subagent_tokens` each Agent task notification reports, appended to
   `runs/review-arms/a8-2026-11-19/token-ledger.md` as each arrives, and registered in
   `manifest.json` (review-canon.md §3 convention, incl. the 2026-08-18 amendment).
4. Comparison split three ways so the k=3 change is not read as lever #3's effect:
   fact-check (k=3 vs k=1, and per replicate vs the baseline's single replicate),
   the four baseline-comparable critics (security, performance, api, architecture),
   and stages new since the baseline (test-strategy as a first-wave critic; Stage 2.5).

## Differences from the baseline setup

- Delivery: inline (today's skill) vs self-read (baseline). This is the lever under test.
- Fact-check k=3 (terminal pass, decision log 63) vs k=1 (decision 031 as of 2026-08-06).
- test-strategy auto-selected at Step 5 (source without tests); the baseline missed it and
  ran it later as a gap-fix.
- Skill text delivery: each agent's prompt opens with the byte-identical shared block and
  its per-agent tail tells it to read its own skill file by absolute path, instead of my
  pasting 14.5-34 KB of skill text into each prompt. The skill text enters each agent's
  context either way (prompt vs first tool result), so the token count differs by a tool
  call's overhead (a few hundred tokens), and the shared block, the thing A8 is about,
  stays the cacheable first part of every prompt. Recorded as a deviation.
- Artifacts go to `runs/review-arms/a8-2026-11-19/csp/`, not `docs/reviews/` (brief AC2).
  The override-log read (Step 3.5) targets the reviewed repo, which has no
  `docs/reviews/override-log.md`; I did not create one there (no writes to the benchmark
  repo beyond the scratch worktree).
- Skill versions: today's critic skills from this branch's tree (= main at 4330e303), vs the
  2026-08-06 skills.

## Design choices

- Cell: csp (brief default). No reason to pick another: it is small (shared block well
  inside budget, so the inline mode is exercised), and it carries the gold cross-file red.
- Worktree location: scratchpad, so nothing lands in this repo's tree (brief AC1).
- Skill-text delivery: three options (paste verbatim, read-by-path in the tail, inline
  everything into a file the agent reads). Path A: read-by-path in the tail. Pasting is
  the skill's literal instruction but costs ~60k orchestrator output tokens and risks
  transcription drift over ~250 KB across the 9 prompts; reading the whole prompt from a file would remove the
  inline shared prefix that A8 measures. Read-by-path keeps the prefix and the content.
- ui-visual: not selected, same as the baseline (the layout.tsx hunks are header/nonce
  plumbing; the className line is unchanged context).

## Gotchas

Failure-pattern grep: FP-071, FP-108, FP-110
- FP-071 (ledger write has no owner at the moment it is possible): write each ledger row
  at notification time, by the orchestrator, not afterwards.
- FP-108 / FP-110 (provenance sums results, not the attempt ledger; failed cells drop out of
  the denominator): the totals must include every dispatched agent, including any that
  fails or is re-dispatched.

## What the run found about the method (added after the run)

- The instrument: for all 9 agents the notified `subagent_tokens` equals the transcript's
  last API call's input + cache-creation + cache-read + output. It is a final-context figure,
  not a sum over calls. I assume the baseline's figures came from the same field.
- Every agent's first call read 18,900 cached tokens (system + tools) and wrote 32.8k-33.8k
  fresh, so no agent read the inlined shared block from another agent's cache; the first
  request's breakpoints are `system[0]`, `system[1]` and the end of the first user turn
  (results §2).
- Fact-check replicate r3 found a pre-installed `node_modules` for this exact commit at
  `/workspace/external/cc-review-eval/mfc-csp` and ran `next build`/`next start` in its own
  copy; the Stage 2.5 agent reused that copy. The baseline had no executed verdicts. The copy
  was deleted after the run; its logs are kept under `csp/fc-r3-logs/` and `csp/stage25-logs/`.
- Total 852,285 tokens over 9 agents, under the 2M stop line.

## Plan

1. Ledger + manifest skeleton; shared block assembled and saved as `csp/shared-block.md`.
2. Stage 1 (3 fc), merge, Stage 1.5, Stage 2 (5 critics), Stage 2.5 if needed, Stage 3.
3. results.md; remove the scratch worktree; status line done; review-fix loop; marker.
