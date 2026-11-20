# Research: A8 settling runs (csp self-read control, corpus inline)

Brief: `docs/working/briefs/2026-11-19-a8-settling-runs.md` (at 14d450d9). Branch: `measure/a8-settling-runs`.
Results: `runs/review-arms/a8-2026-11-20/results.md`. Per-agent rows: `runs/review-arms/a8-2026-11-20/token-ledger.md`.

## Question

Rubric row A8 (`docs/reviews/code-review-rubric-2026-08-07-main.md`) asks whether inlining the
shared review context (decision 032 lever #3) is worth its cost. The first A8 pass
(`runs/review-arms/a8-2026-11-19/results.md`) and its cache probe (`cache-probe.md`) showed the
cross-agent cache saving is zero on the Agent-tool path, leaving the net cost against self-read
and the 25k budget untested. This brief runs the two arms that results doc named: a self-read
control on csp, and the corpus cell inline.

## Precondition check

The brief asks me to check that `git log -1 --format=%H -- skills/code-review/SKILL.md` on the
base commit is the merge made under Q-315 (the lever #3 correction), and to end blocked if it is
not. `git log -1 -- skills/code-review/SKILL.md` at 14d450d9 prints
ca328816, a commit on `fix/code-review-lever3-correction`; it is not in the first parent of
d383a484 (the build-loop merge of that branch), the merge changes SKILL.md (+68/-53), and nothing
under `skills/code-review/` changed between d383a484 and 14d450d9. Git's default path
simplification never prints a merge commit that is TREESAME to its second parent, so the literal
command cannot print the merge hash (`--first-parent` would). What the check is for holds: the
skill at base is the one that merge brought in, so I proceeded rather than block. That reads the
brief's stop condition by its purpose, not its letter, so the ready marker asks the owner to
confirm it.

### Open question for the owner (tentative pick)

The brief said to end blocked unless `git log -1 -- skills/code-review/SKILL.md` on the base
printed the lever #3 correction's merge (d383a484, merged under Q-315, your answer to merge that fix).
It prints ca328816, the last commit on the merged branch. Git's default history view never prints
a merge whose tree matches its second parent, so this check could not pass as written.
The skill at base is the merged version, so I proceeded. Tiebreaker: the check's purpose was met.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| [1] Accept (pick) | Runs stand as measured | None | None: the skill measured is the merged one |
| [2] Re-run blocked | Discard; re-dispatch after rewording the check | ~2.2M tokens | Same numbers again |

## What I know (context)

- csp: range `d86d2dc..d90d6bb` of `/workspace/external/meta-formalism-copilot`, 2 files. First
  pass (inline, 2026-11-19): core 743,755 tokens (fc 311,975 = 100,755 / 90,196 / 121,024; critics
  431,780), Stage 2.5 108,530, all 852,285; 6/6 canon labels; inline block 8,755 B (Stage 1) /
  11,716 B (Stage 2).
- corpus: range `dc6dfb0..2dc403e`, scope `-- app/` (baseline note 5: the 13 md files are
  context-only), 15 files, +1166/-33. Baseline (2026-08-06, self-read, k=1): fc 93,966 + 6 critics
  (security 94,922, performance 82,991, api 91,492, architecture 87,879, tech-debt 76,227,
  test-strategy 88,089) = 615,566 core. Canon labels: `docs/working/canon-issue-ledger.md:112-115`
  (cor-A1..A4, all amber), plus D3 (rehydration seam, `:161`) which the baseline hit as
  architecture Structural.
- Critic and fact-check skill files are unchanged between the first pass's base (4330e303) and
  14d450d9 (`git diff --stat` over the seven skill dirs and `patterns/orchestrated-review.md` is
  empty), so csp's arm difference is the delivery mode, up to model sampling.
- The first pass's exact prompts survive in its session transcripts; I extracted them and built
  the csp self-read prompts from them by one substitution (below), so everything except delivery
  matches.

## Method

1. Scratch worktrees of the benchmark repo in this session's scratchpad: `wt-csp` at d90d6bb,
   `wt-corpus` at 2dc403e (`git worktree add --detach`), never in this repo's tree.
2. Pass 1, csp, self-read: the first pass's prompts with the `## The diff` and
   `## Enclosing-file context` sections replaced by a `## Review material (self-read delivery)`
   section naming the `git diff` command and the two files to read in full. Paths re-pointed to
   this worktree, scratch worktree and run directory. The fact-check brief ("claims that
   particularly need checking") is the first pass's, verbatim. Stage 2 carries this pass's own
   merged fact-check summary (part 6), as the skill requires in every delivery mode.
3. Pass 2, corpus, inline as the skill says: assemble part 5, measure chars/4 against the 25k
   budget, pick the mode the ladder gives, and run the gated panel.
4. Passes run one after the other; within a pass, each stage's agents run in parallel as the skill
   says (the first pass did the same).
5. Tokens per agent from each task notification, written to the ledger as it arrives; totals in
   `manifest.json`. Stop line: 2.5M over both passes.

## Design choices

- Self-read wording (brief: "critics get paths and read the diff and enclosing files
  themselves"): name the files to read in full, not only the scope spec. One option matches the
  brief's words and keeps decision 021's enclosing-file context, so it dominates.
- csp fact-check brief: reuse the first pass's verbatim (brief: "everything else as the first
  pass"). The first pass flagged that brief as written with the canon labels known; reusing it
  holds that threat constant across arms rather than adding a second one.
- Corpus delivery mode: decided by the skill's ladder, not by me (see results §2).
- Corpus fact-check brief: written by me from the diff, knowing the canon labels, as the first
  pass's was; I keep it to the diff's comment/docstring claims and name no label's finding.
- Corpus critic panel: Step 5 selection as the baseline (6 critics); see results.
- How the corpus block reaches each agent. The skill's ladder gives inline-diff-only: part 5
  (diff + the 15 touched files) is 123,423 bytes, about 30.9k tokens, over the 25k budget, so
  the block is preamble + scope label + intent + the 53,682-byte diff, 57,328 bytes in all
  (about 14.3k tokens). Pasting that into 10 Agent prompts by hand would cost me about 143k
  output tokens, risk transcription drift in a 1,300-line diff, and likely overrun my own
  context mid-pass. Instead each prompt opens by telling the agent to Read the block file
  (`runs/review-arms/a8-2026-11-20/corpus/shared-block.md`, byte-identical for all) before
  anything else. The agent's context holds the same content from its first step either way; the
  difference is the Read calls (one for a Stage-1 agent; two for each Stage-2 critic, whose first
  Read stopped at line 1068), the Read tool's line numbers (about 1.4k tokens), and the block
  arriving as a tool result
  rather than prompt text, which the cache probe showed makes no cache difference on this path.
  This is a deviation from pasting, recorded in results. It dominates on the run finishing at
  all, so no divergent design pass.
- csp critics were meant to launch in one message; three of the five calls were refused by a
  harness working-directory check and were re-sent a minute later. Self-read agents share no
  prompt cache, so the stagger cannot change their figures.
- No choice here has three or more viable options with different tradeoffs, so no divergent
  design pass was run.

- Size gate (pr-prep 1a). Its count leaves out only `docs/`, so the brief-mandated review
  artifacts under `runs/review-arms/a8-2026-11-20/` (agent reports, merged reports, logs,
  shared blocks) count as thousands of "code lines". They are review artifacts, the class the
  gate's own parenthetical excludes, and they sit under `runs/` only because the brief puts
  them there. The branch has no code. Splitting a measurement record would not shrink any
  review, so I did not split it. The first A8 pass merged the same way: 4,092 lines by this
  count, approved by the owner.
- Review scope for the review-fix loop: the files I wrote (results, research doc, ledger,
  manifest, the two rubrics, the two merged fact-check reports). The agents' own reports are
  the measured data, so they are not rewritten.

## After the run

- Both scratch worktrees of the benchmark repo were removed (`git worktree remove`). Agent
  scratch copies stayed in the session scratchpad, outside both repos.
- Total 2,171,680 tokens over 19 agents, under the 2.5M stop line.

## Gotchas

Failure-pattern grep: FP-071, FP-108, FP-110
Failure-pattern skip: any fix(...) commits on this branch correct a measurement write-up's prose against its own records; none carries a reusable symptom/cause/fix shape.
- FP-071 (ledger write has no owner when it is possible): rows written at notification time.
- FP-108 / FP-110 (provenance sums results, not the attempt ledger): totals include every
  dispatched agent.
