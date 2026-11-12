# Research: the token cost of a dev-cycle iteration

- **Goal**: Put a number on what one dev-cycle iteration costs in tokens and wall time, the orchestrator's share and the build loops' share, from the session transcripts that already exist.
- **Problem framing**: The light-pass rule the owner chose (Q-270 [2]) was weighed without token counts, because no cycle record holds them. Considered and discarded: "the checking steps run as subagents, so their cost is the subagent transcripts" (they mostly ran in the orchestrator's own thread; see section 4).
- **Project state**: this branch delivers one research doc, docs only · the measurement half of the owner's Q-270 answer ([4]) · not blocked (cite: docs/working/briefs/2026-11-11-cycle-token-cost.md)
- **Task status**: complete (one review round; see Review)

Brief: `docs/working/briefs/2026-11-11-cycle-token-cost.md` (self-merge, docs only).
Read first, and not repeated here: `docs/working/research-2026-11-10-cycle-overhead-numbers.md`
(called "the overhead doc" below). Its Appendix A supplies the kind (full, light, stopped) and
outcome (caught, re-fire only, quiet) of each iteration up to 2026-11-10-1902; this doc joins
on the iteration name and does not reclassify anything.

Words used below, beyond the overhead doc's.

- **Orchestrator**: the interactive Claude Code session that runs `/dev-cycle`. Its transcript
  is one JSONL file under `~/.claude/projects/-workspace/`.
- **Window**: the stretch of an orchestrator transcript this doc assigns to one iteration
  (section 1).
- **Raw tokens**: the four usage counts summed as they are: uncached input, cache write
  (`cache_creation_input_tokens`), cache read (`cache_read_input_tokens`) and output.
- **Weighted tokens**: the same counts weighted by Anthropic's usual price ratios relative to
  uncached input: cache read 0.1, cache write 1.25, output 5. [assumed] These are API list-price
  ratios, used only to stop cache reads, which are 98% of the raw count, from drowning the rest.
  How a subscription's usage limits weigh them is not published, so the weighted figure is a
  comparison scale, not a bill. Every table gives the raw parts too.
- **Q-270**: the archived owner entry asking whether to run light passes between full cycles.
  The owner answered [2] (full when main moved or a new day starts, light otherwise) and [4]
  (measure tokens first); this doc is [4]. **Q-154** is the older answer it replaced (a full
  cycle every iteration, revisited "once the costs are visible").
- **M** is a million tokens, **k** a thousand.

## Summary

1. **107 of the 108 iterations since 2026-10-16 were matched to a transcript window.** One
   (2026-11-02-0532, a light pass) was not. Every build loop dispatched in that period (58
   dispatches) was found and tied to the iteration that dispatched it. [observed]
2. **An iteration's orchestrator costs a median of 3.8M raw tokens, 0.51M weighted**, of which
   18.5k are output tokens. The middle half runs 0.33M to 0.77M weighted and the range is
   0.05M to 2.17M. Wall time from its first to last message: median 8.3 minutes. [observed]
3. **Build loops cost three times the orchestrator.** Over the 107 windows: orchestrator
   65.5M weighted (22.7%), build loops 216.9M (75.3%), checking-step subagents 5.7M (2.0%).
   One build-loop dispatch costs a median of 1.88M weighted (9.4M raw), about 3.7 orchestrator
   iterations. [observed]
4. **A full iteration costs about what a light one does.** Median orchestrator cost: full
   0.52M weighted, light 0.50M; a quiet full one 0.41M, less than the light median. Full
   iterations that caught something cost 1.01M. By means, full exceeds light by 0.19M per
   iteration (29%). [observed]
5. **So the steps a light pass skips (2 to 4b) cost little on the iterations where they find
   nothing.** If [2] had turned the 28 extra iterations its replay makes light (overhead doc
   section 7) from the full mean to the light mean, it would have saved about 5.3M weighted,
   1.8% of the 288.0M spent in all windows. [inferred]
6. **The numbers do not argue against the light-pass rule**, and they do not argue for it on
   tokens: its saving is small either way. Its case rests on wall time and on the repeated
   verdict lines, which the overhead doc already counted. No new owner entry. (Section 6.)
7. **For the weekly digest:** iterations 2026-10-16 to 2026-11-12, orchestrator median 0.51M
   weighted (3.8M raw) per iteration; build loops 75% of all cycle tokens; full against light
   0.52M against 0.50M (medians); a light pass would have saved about 2%.

## 1. Method

**Source.** Every `*.jsonl` under `~/.claude/projects/*/` (71 session transcripts) and every
`*/subagents/*.jsonl` (676 subagent transcripts, each with a `.meta.json`), dated 2026-10-12
to 2026-11-12 UTC. They were read in place, read-only; nothing from them is in the repo but
the counts below. Lines stamped after 2026-11-12 00:40 UTC are ignored, so a re-run gives
the same figures while sessions go on; the one dispatch still running then (this build loop,
dispatched by 2026-11-12-0024) is counted only to that minute. The scripts are in Appendix B.
[observed]

**What a transcript line carries.** An assistant line has a `timestamp`, `cwd`, `gitBranch`,
the message's `id` and `model`, and `message.usage` with `input_tokens`,
`cache_creation_input_tokens`, `cache_read_input_tokens` and `output_tokens` kept apart. One
API response is written as several lines (one per content block) that repeat the same usage,
so usage is counted once per message `id`, taking each field's maximum, and once across
files (a resumed session copies earlier lines). A subagent's own lines are in its own file,
not the parent's; its `.meta.json` names the parent's tool-use id (`toolUseId`), its depth and,
below depth 1, its parent agent (`parentAgentId`). [observed]

**Matching a transcript to an iteration.** The key is the iteration's name, `DATE-HHMM`.

1. The orchestrator session for an iteration is the main transcript that mentions
   `dev-cycle-NAME` (the worktree `wt-dev-cycle-NAME` or branch `chore/dev-cycle-NAME`) in a
   line stamped from 10 minutes before the name's minute to 15 minutes after it, the earliest
   such mention winning. That is the moment step 0.3 creates the worktree. The record's typed
   name 2026-11-02-1438 is read as 06:47 UTC, as the overhead doc does.
2. The window starts at the last `build-loop.sh --state` call (step 0.1) in the 15 minutes
   before that mention (found for 104 of 107; otherwise one minute before the mention). It
   ends 20 minutes after the iteration's last land commit on main (so step 10's dispatch is
   inside), or at the next iteration's start in the same session if that comes first.
3. Every orchestrator message in the window, not already counted, is the iteration's.
4. A subagent belongs to the iteration whose window holds the tool call that launched its
   depth-1 ancestor. It is a **build loop** when its first prompt names a brief ("You are the
   build loop for docs/working/briefs/…") or its launch label starts "Build loop"; a
   **checking-step subagent** when its label names step 2, 3, 4 or 4b, a spot-check, triggers
   or watched questions. Labels are the orchestrator's own Agent-tool descriptions, matched by
   pattern and not reproduced here. Every depth-1 subagent launched from a window fell in one
   of those two classes. A build loop's cost includes its own review subagents, and is charged
   whole to the iteration that dispatched it, however long it ran.

Matching on the `cwd` or `gitBranch` field alone was tried first and rejected (section 7,
design choices): it missed 14 iterations whose orchestrator never entered the worktree, and it
charged step 10's dispatches to the next iteration.

**Coverage.** 108 iterations are named from 2026-10-16-0510 to 2026-11-12-0024 (the overhead
doc's 100 plus 8 since). 107 matched; 2026-11-02-0532 did not: its name first appears 20 minutes
before the name's own minute, outside the matching span. The three iterations of 2026-10-15 are left out, as the overhead doc did. The
107 windows lie in 24 orchestrator sessions. Those sessions also hold 77.3M raw (14.8M
weighted) tokens outside any window: between iterations, waiting on loops, and other work in
the same session. 264 other root subagents (1,540M raw) were launched outside any window (from
other sessions, or from orchestrator sessions between iterations); none is labelled a build loop and one is labelled like a checking
step. [observed]

**Sensitivity.** Moving the window's end from 20 minutes after the last land to 5 or to 40
minutes changes the medians by at most 0.05M weighted and leaves the build-loop totals
unchanged (table in section 3). [observed]

## 2. Totals over the 107 matched iterations

| Part | Uncached input M | Cache write M | Cache read M | Output M | Raw M | Weighted M | Share, weighted |
|---|---|---|---|---|---|---|---|
| Orchestrator | under 0.01 | 4.88 | 455.29 | 2.77 | 462.94 | 65.49 | 22.7% |
| Checking-step subagents (22, in 10 iterations) | under 0.01 | 1.71 | 29.09 | 0.13 | 30.92 | 5.68 | 2.0% |
| Build loops (58 dispatches, in 33 iterations) | 0.02 | 51.02 | 1,059.03 | 9.44 | 1,119.50 | 216.87 | 75.3% |
| **All** | | | | | 1,613.37 | 288.04 | |

- Uncached input is close to nothing: no iteration's orchestrator sent more than 156 uncached
  input tokens. Everything else is cache traffic. [observed]
- In the orchestrator's weighted cost, cache reads are 69.5%, output 21.2% and cache writes
  9.3%. [observed]
- The orchestrator ran on `claude-opus-5-5` for 91% of its raw tokens and `claude-fable-5-2`
  for 9% (counted over all 110 matched windows, the three of 2026-10-15 included). [observed]

## 3. Per iteration

Appendix A lists every iteration. The groups, from it: [observed]

| Group | n | Orch raw M, median | Orch weighted M: median (middle half; range) | Orch output k, median | Orch wall min, median | Iteration incl. loops, weighted M median |
|---|---|---|---|---|---|---|
| All matched | 107 | 3.83 | 0.51 (0.33–0.77; 0.05–2.17) | 18.5 | 8.3 | 0.56 |
| Full | 72 | 4.07 | 0.52 (0.32–0.87; 0.05–2.17) | 18.3 | 11.1 | 0.60 |
| Light (collect, brief, dispatch, land) | 23 | 3.71 | 0.50 (0.25–0.60; 0.05–1.13) | 17.7 | 4.3 | 0.51 |
| Stopped at the start check | 4 | 2.30 | 0.43 (0.20–0.69; 0.14–0.77) | 29.8 | 12.9 | 0.43 |
| Since 2026-11-10-2013 (not classified) | 8 | 4.93 | 0.61 (0.48–1.07; 0.42–1.20) | 18.8 | 6.5 | 1.40 |
| Full, quiet | 40 | 3.26 | 0.41 (0.26–0.58; 0.05–0.88) | 15.2 | 7.1 | 0.49 |
| Full, re-fire only | 10 | 3.79 | 0.60 (0.36–1.10; 0.05–1.41) | 22.0 | 13.4 | 0.61 |
| Full, caught something | 22 | 6.68 | 1.01 (0.59–1.45; 0.16–2.17) | 43.7 | 15.7 | 2.04 |

"Middle half" is the first to third quartile by Python's `statistics.quantiles`. Wall here
is first to last orchestrator message in the window, so it includes step 0 and step 10 and
runs longer than the overhead doc's name-to-land time (median 5.6 minutes).

**Build loops**, per dispatch (58): median 9.39M raw, 1.88M weighted (middle half 0.91M to
4.63M; range 0.18M to 18.58M); wall median 30.2 minutes (range 1.7 to 374); a median of 1
review subagent each (up to 13). The loop's own thread is 63.6% of its raw tokens (57.0%
weighted), its subagents the rest. In the 33 iterations that dispatched, the orchestrator was
a median of 22% of the iteration's weighted total (range 2% to 78%). [observed]

**Sensitivity to the window's end** (weighted M, medians): [observed]

| Window ends after the last land | All | Full | Light | Full, quiet | Full, caught | Mean full minus mean light |
|---|---|---|---|---|---|---|
| 5 minutes | 0.49 | 0.50 | 0.47 | 0.40 | 0.99 | 0.21 |
| 20 minutes (used) | 0.51 | 0.52 | 0.50 | 0.41 | 1.01 | 0.19 |
| 40 minutes | 0.55 | 0.57 | 0.51 | 0.46 | 1.01 | 0.16 |

## 4. The share spent on steps 2 to 4b

The skill says steps 2, 3, 4 and 4b run as parallel subagents. In practice they did so in 10
of the 72 full iterations (22 subagents, 5.7M weighted, 2.0% of all cycle tokens), all before
2026-11-08. In the other 62 the orchestrator ran them in its own thread. [observed]

The main thread's share of steps 2 to 4b cannot be cut out by marker: the step-7 marker
(`build-loop.sh --status`) appears as a literal command in too few windows, and often right at
the start, where step 0 reads loop state. So the share is estimated by comparison instead:
what a full iteration costs over a light one, which skips exactly those steps. [inferred]

| Comparison (orchestrator, weighted M) | Full | Light | Difference | Share of full |
|---|---|---|---|---|
| Medians | 0.52 | 0.50 | 0.01 | 2.3% |
| Means | 0.65 | 0.47 | 0.19 | 28.7% |
| Medians, quiet full only | 0.41 | 0.50 | −0.09 | none |

Read: on a typical iteration the checking steps cost close to nothing extra, and on a quiet
one nothing measurable; the mean difference comes from the 22 iterations that caught
something, whose orchestrator cost a median of twice a light one. Most of that extra is the
work that followed a catch (a fix, a filed entry), not the checking that found it. [inferred]

**Against Q-270 [2].** The overhead doc's replay of [2] makes 52 of 96 iterations light where
24 were, so 28 more. At the mean difference, 28 × 0.19M is about 5.3M weighted, 1.8% of the
288.0M in all windows. Even if all 50 quiet or re-fire-only full iterations had cost nothing,
the saving would be their 23.9M, 8.3%. [inferred]

## 5. What the numbers cannot show

- **A price.** The weighted figure uses API price ratios; the owner's subscription meters
  usage by rules that are not published, and the transcripts carry no cost field. [assumed]
- **Cache write duration.** The transcripts split cache writes into 5-minute and 1-hour
  writes (`usage.cache_creation`), which price differently; this doc counts them together at
  1.25. [observed: the field is present; not broken out]
- **Steps inside the main thread.** No line says which step it serves, so step 2 to 4b work
  done in the orchestrator's thread is estimated by comparison (section 4), not measured.
- **Whether the light passes were really light.** The overhead doc found many "full"
  iterations carried verdicts forward with one line. If the skill's text were held to (every
  trigger decided again), full iterations would cost more than measured here, by an unknown
  amount.
- **Anything outside the transcripts.** The health check and other shell work cost no model
  tokens and show only as wall time. A headless `claude -p` run started by a script would
  write its own session, which this matching would not tie to an iteration. [inferred]
- **Value.** The cost of a catch is here; what a missed catch would have cost is not.
- **Retention.** The oldest transcript is from 2026-10-12. If Claude Code's transcript
  cleanup (30 days by default) runs, the early iterations' counts cannot be re-derived after
  mid-November. [assumed] The method in Appendix B can be re-run on whatever is kept.

## 6. Do the numbers argue against the light-pass rule?

No. The rule (Q-270 [2]) costs some catches a wait (overhead doc: 2 real waits of 1 and 3.8
hours in 26 days) and saves, by these numbers, about 2% of the cycle's tokens. Tokens neither
justify nor sink it: the orchestrator's checking steps are cheap next to build loops, which
are three quarters of the spend and which the rule does not touch. Nothing here calls for a
new owner entry; the numbers go in the weekly digest (Summary item 7).

What they do suggest, for the cycle to weigh without the owner: if token cost becomes the
concern, the lever is the build loops (a median 1.88M weighted per dispatch, with review
subagents 36% of its raw tokens and 43% weighted), not the light pass.

## Research notes

### What exists

- Transcripts: `~/.claude/projects/-workspace/*.jsonl` and `*/subagents/*.jsonl` with
  `.meta.json`; two more project directories hold 3 small sessions, none an orchestrator.
- The overhead doc's Appendix A (kind and outcome per iteration) and section 7 (the replay).
- Land commit times from `git log --first-parent` at 163ad165 (the brief's commit), as the
  overhead doc computed its wall times.
- `skills/dev-cycle/SKILL.md` Flow: steps 2 to 4b "run them in parallel as subagents".

### Invariants

- Read-only on the transcripts; quote no message content; aggregates only (the brief).
- Every figure from python3 (the brief; FP-153 below).
- The deliverable is this file; the brief's Status line is the only other change.

### Prior art

The overhead doc's section 6 named the transcripts as the likely source and left three
questions open: whether a script can total usage between an iteration's first and last
message (yes, by window, section 1), whether an orchestrator can name its own transcript (not
needed: matching by the worktree name works after the fact), and whether checking-step
subagents' usage is in the same file (no: in `subagents/`, tied back by `toolUseId`).

### Gotchas

Failure-pattern grep: FP-077, FP-078, FP-099, FP-108, FP-110, FP-114, FP-153, FP-176 (see Prior failures section)

- Streaming writes one response as several lines with the same usage; summing lines would
  count it two to five times. Deduplicated by message `id`.
- `gitBranch` reflects whatever the shared checkout `/workspace` has checked out, so other
  sessions' lines carry a cycle branch name they have nothing to do with.
- Two iterations can be named within a minute of each other (2026-11-06-0630 and -0631);
  the window boundary between them is the second one's start.

#### Prior failures

The grep (`grep -inE 'transcript|usage-field|token-count|cycle-cost|wrong-denominator|counts-written|double-count|dedup' docs/failure-patterns.md`)
returned eight entries, all on measurement:

- FP-077, FP-078, FP-176: a denominator that inflates or a degenerate case scored high. Here:
  the medians are over all matched iterations of a kind, quiet ones included.
- FP-099: a cost that becomes untrackable when it is not billed. Here: the weighted figure is
  labelled a scale, not a bill (section 5).
- FP-108, FP-110, FP-114: the denominator shrinking to the cases that produced output. Here:
  the unmatched iteration is named, not dropped, and the 264 subagents outside windows and
  the 77.3M orchestrator tokens outside windows are reported.
- FP-153: counts written from recollection. Here: every figure is printed by Appendix B.

### Design choices

**How to match a transcript to an iteration** (3 options; divergent design, Path A).

| Option | What it does | Result | Constraints |
|---|---|---|---|
| A. `cwd` is the iteration's worktree | Key each line by `wt-dev-cycle-NAME` in `cwd` | 14 iterations unmatched; step 10's dispatches charged to the next iteration (a launch at 00:00:33 from `/workspace`, seven minutes before the next worktree existed) | none broken; fails the brief's "how many could be matched" honestly but needlessly |
| B. `gitBranch` is the cycle branch | Key by `chore/dev-cycle-NAME` | Wrong: the shared checkout's branch leaks into unrelated sessions | fails the brief (misattribution) |
| C. Name mention plus time window | Section 1 | 107 of 108 matched; dispatches charged to the dispatching iteration | none broken |

C dominates: it matches more and charges correctly, at the cost of a window rule, whose
sensitivity is shown in section 3. Path A: decided.

**How to estimate the share of steps 2 to 4b** (3 options; Path A). (a) Split each window at
step markers: rejected, the step-7 marker is missing or misplaced in most windows. (b) Count
only checking-step subagents: undercounts, since 62 of 72 full iterations ran the steps
inline. (c) Full against light, plus (b) reported apart: kept, since a light pass is defined
as skipping exactly those steps (S7, measure before budgeting a saving).

**Weighting** (one line): raw and weighted both reported; no single "cost" claimed.

**Iteration kinds** (one line): taken from the overhead doc's Appendix A, not reclassified;
the 8 later iterations are left unclassified rather than classified by a new rule.

### Plan and verification

1. Probe transcript field names only (no content). Done.
2. Collect, attribute and total with the scripts in Appendix B, from a scratch directory
   outside the repo. Done; run twice more with the window end at 5 and 40 minutes.
3. Write this doc from the scripts' output. Tests: none; docs-only, none run.

### Review

One reviewer subagent checked the doc's figures and claims against the scripts' output and
code (round 1). Findings and fixes are listed under the marker commit's review line in the
branch log.

## Appendix A: every iteration

Orch: the orchestrator's window. Weighted M uses the ratios above. Checking subagents and
loops dispatched: count of root subagents, then their weighted tokens including descendants.
Kind and outcome are the overhead doc's (`·`: not in it, or not applicable).

| Iteration (UTC) | Kind | Outcome | Orch cache read M | Orch cache write M | Orch output k | Orch weighted M | Orch wall min | Checking subagents (n, weighted M) | Loops dispatched (n, weighted M) |
|---|---|---|---|---|---|---|---|---|---|
| 2026-10-16-0510 | stopped | · | 2.42 | 0.047 | 31.1 | 0.46 | 35.1 | – | – |
| 2026-10-17-1846 | stopped | · | 4.32 | 0.071 | 49.8 | 0.77 | 22.0 | – | – |
| 2026-10-17-1912 | full | caught | 13.73 | 0.189 | 111.4 | 2.17 | 35.7 | 3, 1.11 | 2, 1.87 |
| 2026-10-17-1948 | light | · | 7.57 | 0.068 | 57.0 | 1.13 | 8.6 | – | 1, 0.31 |
| 2026-10-17-1956 | light | · | 5.02 | 0.039 | 30.3 | 0.70 | 4.3 | – | – |
| 2026-10-20-0346 | stopped | · | 2.03 | 0.040 | 28.4 | 0.40 | 3.8 | – | – |
| 2026-10-20-1923 | stopped | · | 0.79 | 0.013 | 8.9 | 0.14 | 1.3 | – | – |
| 2026-10-20-1938 | full | caught | 6.65 | 0.115 | 63.3 | 1.13 | 16.9 | 4, 1.05 | – |
| 2026-10-20-2344 | full | caught | 11.21 | 0.179 | 111.0 | 1.90 | 21.7 | 4, 0.74 | 2, 6.60 |
| 2026-10-21-0006 | full | quiet | 4.00 | 0.042 | 29.6 | 0.60 | 4.1 | – | – |
| 2026-10-21-0044 | full | quiet | 1.94 | 0.024 | 17.9 | 0.31 | 2.4 | – | – |
| 2026-10-26-0002 | full | caught | 11.16 | 0.177 | 103.0 | 1.85 | 25.4 | 4, 1.28 | 3, 12.32 |
| 2026-10-26-0027 | full | caught | 7.05 | 0.060 | 38.1 | 0.97 | 17.8 | 1, 0.12 | – |
| 2026-10-26-0045 | full | quiet | 3.70 | 0.028 | 19.9 | 0.50 | 3.1 | – | – |
| 2026-10-26-0139 | full | quiet | 2.98 | 0.024 | 17.1 | 0.41 | 2.7 | – | – |
| 2026-10-28-2136 | full | caught | 10.03 | 0.154 | 81.6 | 1.60 | 15.7 | 1, 0.38 | 3, 5.26 |
| 2026-10-28-2155 | full | quiet | 4.35 | 0.032 | 22.5 | 0.59 | 12.2 | – | – |
| 2026-10-28-2205 | full | quiet | 4.27 | 0.028 | 18.1 | 0.55 | 13.2 | – | – |
| 2026-10-28-2223 | full | caught | 3.70 | 0.024 | 17.4 | 0.49 | 7.0 | – | – |
| 2026-10-28-2302 | full | quiet | 4.04 | 0.030 | 22.2 | 0.55 | 11.2 | – | 1, 0.82 |
| 2026-10-28-2314 | full | quiet | 3.65 | 0.021 | 16.3 | 0.47 | 10.7 | – | – |
| 2026-10-28-2325 | full | quiet | 3.44 | 0.017 | 8.4 | 0.41 | 7.4 | – | – |
| 2026-10-29-0133 | full | quiet | 4.76 | 0.053 | 28.6 | 0.68 | 10.2 | – | 1, 3.33 |
| 2026-10-29-0217 | full | quiet | 5.67 | 0.045 | 25.9 | 0.75 | 17.5 | – | 1, 0.38 |
| 2026-10-29-0235 | full | caught | 1.94 | 0.011 | 7.1 | 0.24 | 5.4 | – | – |
| 2026-10-29-0240 | full | quiet | 2.05 | 0.012 | 8.1 | 0.26 | 6.5 | – | – |
| 2026-10-29-1937 | full | quiet | 4.17 | 0.048 | 23.9 | 0.60 | 25.5 | – | 1, 2.09 |
| 2026-10-29-2003 | full | caught | 8.86 | 0.061 | 36.8 | 1.15 | 41.7 | – | 2, 3.40 |
| 2026-10-29-2045 | full | quiet | 4.86 | 0.036 | 23.3 | 0.65 | 23.2 | – | 1, 1.92 |
| 2026-10-29-2108 | full | quiet | 2.05 | 0.013 | 7.4 | 0.26 | 18.0 | – | – |
| 2026-10-29-2126 | full | quiet | 2.18 | 0.016 | 11.8 | 0.30 | 1.8 | – | – |
| 2026-10-29-2212 | full | caught | 4.08 | 0.018 | 14.6 | 0.50 | 11.0 | – | – |
| 2026-10-29-2223 | full | quiet | 4.08 | 0.023 | 15.4 | 0.51 | 9.9 | – | 1, 0.60 |
| 2026-10-29-2248 | full | quiet | 6.90 | 0.033 | 24.9 | 0.86 | 17.7 | – | 2, 4.27 |
| 2026-10-29-2306 | full | quiet | 4.08 | 0.020 | 13.5 | 0.50 | 20.0 | – | – |
| 2026-10-30-0035 | full | caught | 9.82 | 0.117 | 55.2 | 1.40 | 25.9 | – | 2, 1.36 |
| 2026-10-30-0100 | full | caught | 8.32 | 0.051 | 31.9 | 1.06 | 15.7 | – | 1, 0.85 |
| 2026-10-30-0116 | full | quiet | 7.28 | 0.034 | 22.0 | 0.88 | 19.2 | – | – |
| 2026-10-30-0136 | full | quiet | 3.24 | 0.015 | 10.6 | 0.40 | 1.9 | – | – |
| 2026-10-30-0708 | light | · | 3.18 | 0.025 | 16.9 | 0.43 | 8.3 | – | – |
| 2026-10-30-0730 | light | · | 0.97 | 0.031 | 3.9 | 0.15 | 12.7 | – | – |
| 2026-10-30-0731 | full | caught | 6.21 | 0.045 | 20.6 | 0.78 | 7.5 | – | – |
| 2026-10-30-0800 | full | quiet | 5.15 | 0.037 | 21.9 | 0.67 | 30.0 | – | 2, 3.09 |
| 2026-10-30-0841 | full | quiet | 2.79 | 0.014 | 8.2 | 0.34 | 6.7 | – | – |
| 2026-10-30-0848 | full | quiet | 2.26 | 0.009 | 6.6 | 0.27 | 1.9 | – | – |
| 2026-10-31-0316 | full | quiet | 7.39 | 0.041 | 18.5 | 0.88 | 19.0 | – | – |
| 2026-10-31-2256 | full | quiet | 4.12 | 0.023 | 13.6 | 0.51 | 17.7 | – | 1, 2.41 |
| 2026-10-31-2325 | light | · | 4.42 | 0.016 | 8.4 | 0.50 | 3.6 | – | – |
| 2026-11-01-2056 | full | quiet | 3.17 | 0.050 | 27.7 | 0.52 | 5.6 | – | – |
| 2026-11-01-2101 | light | · | 1.29 | 0.015 | 10.2 | 0.20 | 1.4 | – | – |
| 2026-11-01-2104 | light | · | 6.00 | 0.050 | 35.9 | 0.84 | 28.0 | – | – |
| 2026-11-01-2142 | light | · | 3.63 | 0.047 | 35.6 | 0.60 | 5.7 | – | 3, 11.66 |
| 2026-11-01-2222 | light | · | 4.07 | 0.036 | 20.5 | 0.55 | 13.8 | – | – |
| 2026-11-01-2237 | light | · | 3.78 | 0.027 | 19.2 | 0.51 | 6.4 | – | – |
| 2026-11-01-2243 | light | · | 2.96 | 0.021 | 11.9 | 0.38 | 1.7 | – | – |
| 2026-11-01-2346 | light | · | 1.92 | 0.010 | 8.3 | 0.25 | 0.9 | – | – |
| 2026-11-01-2347 | light | · | 5.23 | 0.021 | 17.7 | 0.64 | 8.3 | – | – |
| 2026-11-02-0326 | full | caught | 5.72 | 0.078 | 43.2 | 0.89 | 10.1 | – | – |
| 2026-11-02-0337 | light | · | 0.50 | 0.007 | 5.2 | 0.09 | 0.4 | – | – |
| 2026-11-02-0340 | light | · | 3.07 | 0.039 | 27.4 | 0.49 | 7.1 | – | 2, 1.29 |
| 2026-11-02-0420 | light | · | 5.19 | 0.045 | 29.4 | 0.72 | 61.5 | – | – |
| 2026-11-02-0532 | light | · | not matched | | | | | | |
| 2026-11-02-1438 | light | · | 0.26 | 0.004 | 4.8 | 0.05 | 0.0 | – | – |
| 2026-11-02-0649 | light | · | 3.65 | 0.035 | 26.7 | 0.54 | 3.8 | – | – |
| 2026-11-02-0718 | full | refire | 9.06 | 0.128 | 69.3 | 1.41 | 13.6 | 2, 0.40 | 1, 4.58 |
| 2026-11-02-0808 | light | · | 2.94 | 0.029 | 19.4 | 0.43 | 2.9 | – | – |
| 2026-11-02-1757 | light | · | 0.79 | 0.008 | 5.2 | 0.12 | 0.6 | – | – |
| 2026-11-02-1758 | light | · | 3.96 | 0.028 | 21.9 | 0.54 | 2.8 | – | – |
| 2026-11-02-1803 | full | refire | 9.19 | 0.122 | 61.2 | 1.38 | 29.5 | 1, 0.10 | 2, 4.20 |
| 2026-11-02-1833 | light | · | 3.98 | 0.026 | 15.9 | 0.51 | 12.6 | – | – |
| 2026-11-02-1846 | light | · | 2.69 | 0.018 | 11.1 | 0.35 | 1.6 | – | – |
| 2026-11-02-2027 | full | caught | 5.28 | 0.078 | 37.0 | 0.81 | 16.8 | – | – |
| 2026-11-03-2329 | full | refire | 6.91 | 0.094 | 39.8 | 1.01 | 13.2 | – | 2, 8.53 |
| 2026-11-04-0017 | full | quiet | 4.03 | 0.029 | 14.9 | 0.51 | 14.3 | – | – |
| 2026-11-04-0031 | full | quiet | 1.77 | 0.011 | 7.3 | 0.23 | 1.5 | – | – |
| 2026-11-05-2347 | full | caught | 6.19 | 0.272 | 59.0 | 1.25 | 196.3 | 1, 0.39 | 3, 11.31 |
| 2026-11-06-0310 | full | quiet | 1.62 | 0.026 | 17.2 | 0.28 | 6.6 | – | – |
| 2026-11-06-0317 | full | caught | 2.05 | 0.019 | 10.8 | 0.28 | 7.8 | – | – |
| 2026-11-06-0400 | full | quiet | 0.56 | 0.007 | 1.2 | 0.07 | 0.2 | – | – |
| 2026-11-06-0630 | full | quiet | 0.29 | 0.005 | 3.6 | 0.05 | 0.0 | – | – |
| 2026-11-06-0631 | full | quiet | 2.77 | 0.029 | 16.8 | 0.40 | 6.8 | – | 1, 11.72 |
| 2026-11-06-0753 | full | refire | 0.34 | 0.007 | 1.3 | 0.05 | 0.0 | – | – |
| 2026-11-06-0851 | full | quiet | 2.26 | 0.028 | 12.0 | 0.32 | 6.5 | – | 1, 8.76 |
| 2026-11-06-0956 | full | caught | 1.23 | 0.008 | 4.7 | 0.16 | 5.5 | – | – |
| 2026-11-07-0115 | full | caught | 2.37 | 0.087 | 53.2 | 0.61 | 9.6 | – | – |
| 2026-11-07-0145 | full | quiet | 0.36 | 0.014 | 13.3 | 0.12 | 0.7 | – | – |
| 2026-11-07-0148 | full | refire | 2.69 | 0.068 | 50.1 | 0.60 | 15.0 | – | – |
| 2026-11-07-0500 | full | caught | 3.49 | 0.101 | 44.1 | 0.70 | 12.0 | – | 2, 11.21 |
| 2026-11-07-0534 | full | quiet | 1.00 | 0.014 | 6.3 | 0.15 | 1.1 | – | – |
| 2026-11-07-0603 | full | quiet | 2.44 | 0.018 | 12.7 | 0.33 | 16.7 | – | – |
| 2026-11-07-0620 | full | quiet | 0.46 | 0.012 | 6.8 | 0.09 | 0.6 | – | – |
| 2026-11-07-0621 | full | refire | 2.06 | 0.032 | 22.1 | 0.36 | 12.6 | – | 2, 7.52 |
| 2026-11-07-0650 | full | quiet | 2.00 | 0.017 | 7.4 | 0.26 | 9.9 | – | – |
| 2026-11-07-0745 | full | quiet | 0.60 | 0.008 | 5.0 | 0.10 | 0.7 | – | – |
| 2026-11-07-2324 | full | caught | 12.62 | 0.159 | 85.8 | 1.89 | 28.0 | 1, 0.11 | 3, 6.56 |
| 2026-11-07-2353 | full | refire | 4.70 | 0.026 | 18.2 | 0.59 | 23.0 | – | – |
| 2026-11-08-0016 | full | refire | 4.91 | 0.027 | 17.1 | 0.61 | 14.7 | – | – |
| 2026-11-08-0036 | full | refire | 2.80 | 0.019 | 14.0 | 0.37 | 2.0 | – | – |
| 2026-11-08-0600 | full | refire | 2.04 | 0.040 | 21.9 | 0.36 | 3.1 | – | – |
| 2026-11-10-1902 | full | caught | 8.30 | 0.157 | 68.4 | 1.37 | 14.5 | – | 3, 38.60 |
| 2026-11-10-2013 | · | · | 3.54 | 0.025 | 14.0 | 0.46 | 2.7 | – | – |
| 2026-11-10-2131 | · | · | 9.34 | 0.063 | 36.4 | 1.20 | 10.1 | – | 1, 18.58 |
| 2026-11-10-2337 | · | · | 5.18 | 0.030 | 15.4 | 0.63 | 8.3 | – | – |
| 2026-11-11-0810 | · | · | 2.98 | 0.027 | 16.7 | 0.42 | 2.8 | – | 1, 17.32 |
| 2026-11-11-0812 | · | · | 8.83 | 0.050 | 34.5 | 1.12 | 8.3 | – | – |
| 2026-11-11-0947 | · | · | 4.61 | 0.023 | 14.8 | 0.56 | 2.6 | – | – |
| 2026-11-12-0006 | · | · | 6.21 | 0.097 | 35.6 | 0.92 | 17.5 | – | 3, 3.02 |
| 2026-11-12-0024 | · | · | 4.47 | 0.035 | 20.8 | 0.59 | 4.7 | – | 1, 1.09 |

## Appendix B: the scripts

Run from an empty scratch directory, in this order, with `REPO` the repo root at 163ad165:

```sh
rg -o -N -I '^## Iteration \S+' "$REPO/docs/working/cycles/" > names.txt
git -C "$REPO" log --first-parent --format='%ct %s' 163ad165 \
  | sed -n "s/^\([0-9]*\) Merge branch 'chore\/dev-cycle-\([0-9-]*\)'.*/\2 \1/p" > lands.txt
python3 -I collect.py names.txt agg.json
python3 -I analyse.py agg.json lands.txt "$REPO/docs/working/research-2026-11-10-cycle-overhead-numbers.md" res4.json 600 1200 > rows.out
python3 -I stats.py     # reads agg.json and res4.json
python3 -I table.py     # Appendix A
```

`collect.py` keeps the first user prompt of each subagent only to match the build-loop
pattern, and the launch labels are read only to match patterns; neither is written out.

`collect.py`:

```python
# Aggregates token usage from Claude Code transcripts per dev-cycle iteration.
# Prints/writes counts, timestamps and matching keys only; never message text.
import json,glob,os,re,sys,collections,datetime
R='/home/node/.claude/projects/'
names=sorted(set(l.split()[2] for l in open(sys.argv[1]) if l.strip()))
F=('input_tokens','cache_creation_input_tokens','cache_read_input_tokens','output_tokens')
MEN=re.compile(r'dev-cycle-(\d{4}-\d\d-\d\d-\d{4})')
WT=re.compile(r'/wt-dev-cycle-(\d{4}-\d\d-\d\d-\d{4})(?:/|$)')
BL=re.compile(r'You are the build loop for docs/working/briefs/(\S+?)\.md')
def ts(s): return datetime.datetime.fromisoformat(s.replace('Z','+00:00')).timestamp()
# Lines stamped after this are ignored, so a re-run gives the same figures while sessions still run.
CUTOFF=ts('2026-11-12T00:40:00Z')
def text_of(m):
    c=m.get('content') if isinstance(m,dict) else None
    if isinstance(c,str): return c
    if isinstance(c,list): return ' '.join(b.get('text','') for b in c if isinstance(b,dict))
    return ''
def read(p):
    msgs={}; tools=[]; first_prompt=None; first=last=None; mentions={}
    for line in open(p,errors='replace'):
        try:o=json.loads(line)
        except:continue
        t=o.get('timestamp')
        if t and ts(t)>CUTOFF: continue
        if t:
            for nm in set(MEN.findall(line)): mentions.setdefault(nm,[]).append(ts(t))
        if o.get('type')=='user' and first_prompt is None:
            first_prompt=text_of(o.get('message'))
        if o.get('type')!='assistant' or not t: continue
        m=o.get('message') or {}
        u=m.get('usage'); k=m.get('id') or o.get('requestId') or o.get('uuid')
        tt=ts(t); first=tt if first is None else min(first,tt); last=tt if last is None else max(last,tt)
        mm=WT.search(o.get('cwd',''))
        if u:
            r=msgs.setdefault(k,{'id':k,'t':tt,'key':mm.group(1) if mm else None,'model':m.get('model'),**{f:0 for f in F}})
            for f in F: r[f]=max(r[f],u.get(f) or 0)
        for b in m.get('content') or []:
            if isinstance(b,dict) and b.get('type')=='tool_use':
                inp=b.get('input') or {}; cmd=inp.get('command','') if isinstance(inp,dict) else ''
                mark=None
                if b.get('name') in ('Agent','Task'): mark='agent'
                elif 'build-loop.sh' in cmd and '--state' in cmd: mark='state'
                elif 'build-loop.sh' in cmd and '--status' in cmd: mark='status'
                elif '--land-cycle' in cmd: mark='land'
                elif 'health-check.sh' in cmd: mark='health'
                elif 'dev-cycle.sh' in cmd and not re.search(r'--(state|main-log|check|cycle-diff|land-cycle|record)',cmd): mark='digest'
                tools.append((tt,b.get('id'),mark,mm.group(1) if mm else None))
    return msgs,tools,first_prompt,first,last,mentions
out={'names':names,'main':{},'sub':{}}
seen=set()
for p in sorted(glob.glob(R+'*/*.jsonl')):
    sid=os.path.basename(p)[:-6]
    msgs,tools,_,f,l,men=read(p)
    out['main'][sid]={'proj':p.split('/')[-2],'msgs':list(msgs.values()),'tools':tools,'first':f,'last':l,'dups':0,
      'mentions':{k:sorted(v)[:200] for k,v in men.items()}}
for p in sorted(glob.glob(R+'*/*/subagents/*.jsonl')):
    sid=p.split('/')[-3]; aid=os.path.basename(p)[:-6]
    meta={}
    mp=p[:-6]+'.meta.json'
    if os.path.exists(mp): meta=json.load(open(mp))
    msgs,tools,fp,f,l,_=read(p)
    m=BL.search(fp or '')
    disp=re.search(r'\(dispatch (\d+) of',fp or '')
    out['sub'][sid+'/'+aid]={'session':sid,'agent':aid.replace('agent-',''),'parent':meta.get('parentAgentId'),
      'toolUseId':meta.get('toolUseId'),'depth':meta.get('spawnDepth'),'type':meta.get('agentType'),
      'buildloop':m.group(1) if m else None,'dispatch':int(disp.group(1)) if disp else None,
      'msgs':list(msgs.values()),'tools':[(t[0],t[1]) for t in tools if t[2]=='agent'],'first':f,'last':l}
json.dump(out,open(sys.argv[2],'w'))
print(len(names),len(out['main']),len(out['sub']),sum(len(v['msgs']) for v in out['main'].values()),sum(v['dups'] for v in out['main'].values()))
```

`analyse.py`:

```python
# Attributes transcript usage to dev-cycle iterations by time window. Counts only.
# argv: agg.json lands.txt appendixA-doc out.json [LEAD seconds] [TAIL seconds]
import json,sys,re,collections,datetime
A=json.load(open(sys.argv[1])); LEAD=int(sys.argv[5]) if len(sys.argv)>5 else 600; TAIL=int(sys.argv[6]) if len(sys.argv)>6 else 1200
F=('input_tokens','cache_creation_input_tokens','cache_read_input_tokens','output_tokens')
FIX={'2026-11-02-1438':'2026-11-02-0647'}  # the record says this name is mistyped
def nt(n): return datetime.datetime.strptime(FIX.get(n,n),'%Y-%m-%d-%H%M').replace(tzinfo=datetime.timezone.utc).timestamp()
names=sorted(A['names'],key=nt)
land=collections.defaultdict(list)
for l in open(sys.argv[2]): n,t=l.split(); land[n].append(int(t))
kind={}
for l in open(sys.argv[3]):
    c=[x.strip() for x in l.split('|')[1:-1]]
    if len(c)>10 and re.match(r'\d+$',c[0]): kind[c[1]]=(c[3],c[10])
def z(): return {f:0 for f in F}|{'n':0}
def add(a,m):
    for f in F: a[f]+=m[f]
    a['n']+=1
# matching: the main session that mentions dev-cycle-NAME in a line stamped within [name-LEAD, name+15 min]
owner={}; STARTMARK={}
for n in names:
    best=None
    for sid,s in A['main'].items():
        for t in s['mentions'].get(n,[]):
            if nt(n)-LEAD<=t<=nt(n)+900 and (best is None or t<best[0]): best=(t,sid)
    if best: owner[n]=best[1]
win={}
first_mention={}
for n,sid in owner.items():
    first_mention[n]=min(t for t in A['main'][sid]['mentions'][n] if t>=nt(n)-LEAD)
bysess=collections.defaultdict(list)
for n,sid in owner.items(): bysess[sid].append(n)
start={}
for n,sid in owner.items():
    fm=first_mention[n]
    st_=[t[0] for t in A['main'][sid]['tools'] if t[2]=='state' and fm-900<=t[0]<=fm]
    start[n]=max(st_) if st_ else fm-60
    STARTMARK[n]=bool(st_)
for sid,its in bysess.items():
    its.sort(key=lambda n:start[n])
    for i,n in enumerate(its):
        lo=start[n]
        hi=(max(land[n]) if land.get(n) else max(t for t in A['main'][sid]['mentions'][n] if t<lo+6*3600))+TAIL
        if i+1<len(its): hi=min(hi,start[its[i+1]])
        win[n]=(sid,lo,hi)
seen=set(); subs=A['sub']; byagent={v['agent']:k for k,v in subs.items()}
def root(k):
    v=subs[k]; d=0
    while v.get('parent') and v['parent'] in byagent and d<5: k=byagent[v['parent']]; v=subs[k]; d+=1
    return k
import glob as _g
DESC={}
for _k in subs:
    _sid,_aid=_k.split('/')
    _mp=_g.glob('/home/node/.claude/projects/*/'+_sid+'/subagents/'+_aid+'.meta.json')
    DESC[_k]=(json.load(open(_mp[0])).get('description') or '') if _mp else ''
def isbl(k): return bool(subs[k]['buildloop']) or bool(re.match(r'(?i)build[- ]loop\b',DESC[k]))
def ischk(k): return bool(re.search(r'(?i)\bstep ?(2|3|4|4b)\b|spot-check|trigger|watched question|deep-audit check',DESC[k]))
launch={}; rows=[]; MODELS=collections.Counter(); BLITER={}
for n in names:
    r={'name':n,'matched':n in win,'kind':kind.get(n,('',''))[0],'outcome':kind.get(n,('',''))[1],'landed':bool(land.get(n))}
    for p in ('orch','ph16','ph710','chk','oth','bl'): r[p]=z()
    r['chkn']=r['othn']=r['bln']=0; r['blbriefs']=set(); r['wall']=None; r['marks']={}
    rows.append(r)
    if n not in win: continue
    sid,lo,hi=win[n]; s=A['main'][sid]
    tl=[t for t in s['tools'] if lo<=t[0]<hi]
    sta=[t[0] for t in tl if t[2]=='status']
    lands_=[t[0] for t in tl if t[2]=='land']
    l0=min(lands_) if lands_ else None
    pre=[x for x in sta if l0 is None or x<l0]
    st0=max(pre) if pre else None
    r['marks']={'state':STARTMARK[n],'status':st0 is not None}
    ts=[]
    for m in s['msgs']:
        if not(lo<=m['t']<hi) or m['id'] in seen: continue
        seen.add(m['id']); add(r['orch'],m); ts.append(m['t']); MODELS[('orch',m['model'])]+=sum(m[f] for f in F)
        if st0 is not None:
            add(r['ph16'] if m['t']<st0 else r['ph710'],m)
    if ts: r['wall']=(max(ts)-min(ts))/60; r['t0']=min(ts); r['t1']=max(ts)
    for t in tl:
        if t[2]=='agent': launch[t[1]]=(n,t[0],st0)
R={r['name']:r for r in rows}
unassigned=z(); un_roots=set(); seen_sub=set()
for k,v in subs.items():
    rt=root(k); rv=subs[rt]; h=launch.get(rv['toolUseId'])
    a=z(); SUBMODEL=collections.Counter()
    for m in v['msgs']:
        if m['id'] in seen_sub: continue
        seen_sub.add(m['id']); add(a,m); SUBMODEL[m['model']]+=sum(m[f] for f in F)
    if not h:
        for f in F: unassigned[f]+=a[f]
        un_roots.add(rt); continue
    n,t0,st0=h; r=R[n]
    for mo,v2 in SUBMODEL.items(): MODELS[('bl' if isbl(rt) else 'sub',mo)]+=v2
    if isbl(rt):
        tgt='bl'
        if k==rt: BLITER[rt]=n; r['bln']+=1; r['blbriefs'].add(rv['buildloop'] or DESC[rt])
    elif ischk(rt):
        tgt='chk'; r['chkn']+=(k==rt)
    else:
        tgt='oth'; r['othn']+=(k==rt)
    for f in F: r[tgt][f]+=a[f]
    r[tgt]['n']+=a['n']
for r in rows: r['blbriefs']=sorted(r['blbriefs'])
# orchestrator-session tokens that fell in no window (between iterations, other work)
orch_sessions=set(owner.values())
rest=z()
for sid in orch_sessions:
    for m in A['main'][sid]['msgs']:
        if m['id'] not in seen: add(rest,m)
allmain=z(); [add(allmain,m) for s in A['main'].values() for m in s['msgs']]
json.dump({'rows':rows,'unassigned_sub':unassigned,'unassigned_roots':len(un_roots),
  'unassigned_bl_roots':sum(1 for x in un_roots if isbl(x)),'unassigned_chk_roots':sum(1 for x in un_roots if ischk(x)),
  'roots':sum(1 for v in subs.values() if not (v.get('parent') and v['parent'] in byagent)),
  'orch_sessions':len(orch_sessions),'orch_rest':rest,'allmain':allmain,'LEAD':LEAD,'TAIL':TAIL,
  'models':[[a,b,c] for (a,b),c in MODELS.items()],'blroots_all':sum(1 for k,v in subs.items() if isbl(k) and v['depth']==1),'blroots':[k for k,v in subs.items() if isbl(k) and v['depth']==1],
  'blroot_iter':BLITER,
  'main_files':len(A['main']),'sub_files':len(subs),
  'span':[min(s['first'] for s in A['main'].values() if s['first']),max(s['last'] for s in A['main'].values() if s['last'])]},open(sys.argv[4],'w'))
T=lambda a:sum(a[f] for f in F)
for r in rows: print(r['name'],r['matched'],r['kind'] or '?',r['outcome'] or '-',T(r['orch'])//1000,'ph',T(r['ph16'])//1000,T(r['ph710'])//1000,'chk',T(r['chk'])//1000,r['chkn'],'oth',T(r['oth'])//1000,r['othn'],'bl',T(r['bl'])//1000,r['bln'],'w',round(r['wall'] or 0,1),r['marks'])
print('unassigned sub',T(unassigned)//1000,len(un_roots),'rest',T(rest)//1000)
```

`stats.py`:

```python
# Figures for docs/working/research-2026-11-11-cycle-token-cost.md. Counts only.
import json,sys,statistics as st,collections,datetime
A=json.load(open('agg.json')); R=json.load(open('res4.json'))
F=('input_tokens','cache_creation_input_tokens','cache_read_input_tokens','output_tokens')
W={'input_tokens':1,'cache_creation_input_tokens':1.25,'cache_read_input_tokens':0.1,'output_tokens':5}
T=lambda a:sum(a[f] for f in F); Wt=lambda a:sum(a[f]*W[f] for f in F)
M=lambda x:round(x/1e6,2)
d=lambda t:datetime.datetime.fromtimestamp(t,datetime.timezone.utc).strftime('%Y-%m-%d')
print('corpus: main files',R['main_files'],'subagent files',R['sub_files'],'span',d(R['span'][0]),d(R['span'][1]),'orchestrator sessions',R['orch_sessions'])
rows=[r for r in R['rows'] if r['name']>='2026-10-16']
print('iterations since 2026-10-16:',len(rows),'matched',sum(r['matched'] for r in rows),'unmatched',[r['name'] for r in rows if not r['matched']])
print('start marker found',sum(r['marks'].get('state',False) for r in rows if r['matched']),'landed',sum(r['landed'] for r in rows))
early=[r for r in R['rows'] if r['name']<'2026-10-16']; print('excluded earlier',[r['name'] for r in early])
m=[r for r in rows if r['matched']]
def agg(key,rs):
    a={f:sum(r[key][f] for r in rs) for f in F}; return a
for key in ('orch','chk','oth','bl'):
    a=agg(key,m); print('total',key,{f:M(a[f]) for f in F},'all',M(T(a)),'weighted',M(Wt(a)))
print('orch rest outside windows',M(T(R['orch_rest'])),'weighted',M(Wt(R['orch_rest'])),'all main transcripts',M(T(R['allmain'])),'unassigned subs',M(T(R['unassigned_sub'])),R['unassigned_roots'])
tot={f:sum(r[k][f] for r in m for k in ('orch','chk','oth','bl')) for f in F}
for k in ('orch','chk','oth','bl'): print('share',k,round(100*T(agg(k,m))/T(tot),1),'% raw',round(100*Wt(agg(k,m))/Wt(tot),1),'% weighted')
def desc(lbl,vals):
    vals=sorted(vals)
    if not vals: print(lbl,'n 0'); return
    q=st.quantiles(vals,n=4) if len(vals)>3 else [None,None,None]
    print(lbl,'n',len(vals),'median',round(st.median(vals),2),'min',round(vals[0],2),'max',round(vals[-1],2),'q1',q[0] and round(q[0],2),'q3',q[2] and round(q[2],2))
groups=[('all matched',m),('full',[r for r in m if r['kind']=='full']),('light',[r for r in m if r['kind']=='light']),
 ('stopped',[r for r in m if r['kind']=='stopped']),('after 2026-11-10-1902 (not classified)',[r for r in m if not r['kind']]),
 ('full quiet',[r for r in m if r['kind']=='full' and r['outcome']=='quiet']),('full refire',[r for r in m if r['kind']=='full' and r['outcome']=='refire']),
 ('full caught',[r for r in m if r['kind']=='full' and r['outcome']=='caught'])]
for lbl,rs in groups:
    desc('orch M raw | '+lbl,[T(r['orch'])/1e6 for r in rs])
    desc('orch M weighted | '+lbl,[Wt(r['orch'])/1e6 for r in rs])
    desc('orch output k | '+lbl,[r['orch']['output_tokens']/1e3 for r in rs])
    desc('orch wall min | '+lbl,[r['wall'] for r in rs if r['wall'] is not None])
    desc('iteration total incl loops M weighted | '+lbl,[Wt({f:sum(r[k][f] for k in ('orch','chk','oth','bl')) for f in F})/1e6 for r in rs])
    print('  sum orch raw',M(sum(T(r['orch']) for r in rs)),'weighted',M(sum(Wt(r['orch']) for r in rs)),'n with loops',sum(1 for r in rs if r['bln']))
# shares of cache reads in orchestrator
a=agg('orch',m); print('orch category shares raw',{f:round(100*a[f]/T(a),2) for f in F},'weighted',{f:round(100*a[f]*W[f]/Wt(a),1) for f in F})
# full minus light
fu=[Wt(r['orch'])/1e6 for r in m if r['kind']=='full']; li=[Wt(r['orch'])/1e6 for r in m if r['kind']=='light']
fr=[T(r['orch'])/1e6 for r in m if r['kind']=='full']; lr=[T(r['orch'])/1e6 for r in m if r['kind']=='light']
print('median full-light weighted',round(st.median(fu)-st.median(li),2),'share of full median',round(100*(st.median(fu)-st.median(li))/st.median(fu),1),
      '| raw',round(st.median(fr)-st.median(lr),2),round(100*(st.median(fr)-st.median(lr))/st.median(fr),1))
print('mean full-light weighted',round(st.mean(fu)-st.mean(li),2),round(100*(st.mean(fu)-st.mean(li))/st.mean(fu),1))
fq=[Wt(r['orch'])/1e6 for r in m if r['kind']=='full' and r['outcome']=='quiet']
print('median quiet full - light weighted',round(st.median(fq)-st.median(li),2))
# checking subagents
print('iterations with checking-step subagents',[(r['name'],r['chkn'],M(T(r['chk']))) for r in m if r['chkn']])
print('iterations with other subagents',[(r['name'],r['othn'],M(T(r['oth']))) for r in m if r['othn']])
# build loops per root
BLR=set(k for k,n in R['blroot_iter'].items() if n>='2026-10-16'); subs=A['sub']; byagent={v['agent']:k for k,v in subs.items()}
def root(k):
    v=subs[k]; dd=0
    while v.get('parent') and v['parent'] in byagent and dd<5: k=byagent[v['parent']]; v=subs[k]; dd+=1
    return k
per=collections.defaultdict(lambda:{f:0 for f in F}); span={}; ndesc=collections.Counter(); seen=set()
for k,v in subs.items():
    r=root(k)
    if r not in BLR: continue
    ndesc[r]+=(k!=r)
    for mm in v['msgs']:
        if mm['id'] in seen: continue
        seen.add(mm['id'])
        for f in F: per[r][f]+=mm[f]
    if v['first']: a0,b0=span.get(r,(v['first'],v['last'])); span[r]=(min(a0,v['first']),max(b0,v['last']))
desc('build loop M raw per dispatch',[T(x)/1e6 for x in per.values()])
desc('build loop M weighted per dispatch',[Wt(x)/1e6 for x in per.values()])
desc('build loop wall min per dispatch',[(b-a)/60 for a,b in span.values()])
desc('build loop descendants per dispatch',[ndesc[r] for r in per])
own={f:sum(subs[r]['msgs'] and sum(mm[f] for mm in subs[r]['msgs']) or 0 for r in per) for f in F}
allbl={f:sum(x[f] for x in per.values()) for f in F}
print('build loop own thread share of loop tokens raw',round(100*T(own)/T(allbl),1),'weighted',round(100*Wt(own)/Wt(allbl),1))
print('build loops',len(per),'first',d(min(a for a,b in span.values())),'last',d(max(a for a,b in span.values())))
print('models',R['models']); print('unassigned bl roots',R['unassigned_bl_roots'],'unassigned chk roots',R['unassigned_chk_roots'],'bl roots all',R['blroots_all'])
# per local day? per iteration with loops: share orch of iteration total weighted
sh=[Wt(r['orch'])/(Wt(r['orch'])+Wt(r['bl'])+Wt(r['chk'])+Wt(r['oth'])) for r in m if r['bln']]
desc('orch share of iteration weighted, iterations that dispatched',[100*x for x in sh])
print('dispatching iterations',len(sh))
```

`table.py`:

```python
# Appendix A table for the research doc. Counts only.
import json
R=json.load(open('res4.json'))
F=('input_tokens','cache_creation_input_tokens','cache_read_input_tokens','output_tokens')
W={'input_tokens':1,'cache_creation_input_tokens':1.25,'cache_read_input_tokens':0.1,'output_tokens':5}
Wt=lambda a:sum(a[f]*W[f] for f in F)
print('| Iteration (UTC) | Kind | Outcome | Orch cache read M | Orch cache write M | Orch output k | Orch weighted M | Orch wall min | Checking subagents (n, weighted M) | Loops dispatched (n, weighted M) |')
print('|---|---|---|---|---|---|---|---|---|---|')
for r in R['rows']:
    if r['name']<'2026-10-16': continue
    if not r['matched']:
        print(f"| {r['name']} | {r['kind'] or '·'} | {r['outcome'] or '·'} | not matched | | | | | | |"); continue
    o=r['orch']
    print(f"| {r['name']} | {r['kind'] or '·'} | {r['outcome'] or '·'} | {o['cache_read_input_tokens']/1e6:.2f} | {o['cache_creation_input_tokens']/1e6:.3f} | {o['output_tokens']/1e3:.1f} | {Wt(o)/1e6:.2f} | {r['wall']:.1f} | {str(r['chkn'])+', '+format(Wt(r['chk'])/1e6,'.2f') if r['chkn'] else '–'} | {str(r['bln'])+', '+format(Wt(r['bl'])/1e6,'.2f') if r['bln'] else '–'} |")
```
