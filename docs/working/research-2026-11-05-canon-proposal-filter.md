# Research: the canon-instance proposal filter (Q-079)

- **Goal**: Record a divergent-design decision for (a) a script that turns a commit or range into a canon instance and (b) the heuristic that decides which candidates get proposed, so the canon stays compact and grows for coverage only.
- **Problem framing**: The canon's 8 instances all come from one TypeScript repo, so a recall run says nothing about some issue types reviews now handle, and nothing decides which new instance is worth its sweep cost. Considered and discarded: "the ledger stopped being fed, so feed it from every new rubric", the original Q-072 framing, which the owner rejected on 2026-09-27 (`docs/human-author/answers-9-27-26.txt`).
- **Project state**: design record for Q-079 · dev-cycle iteration 2026-11-05-2347 unit, no code · not blocked (cite: docs/working/briefs/2026-11-05-canon-proposal-filter.md)
- **Task status**: complete (Path C tentative pick; the owner's confirmation comes through the final marker)

Tags: [observed] checked by reading or running; [inferred] derived from observed facts; [assumed] not checked. The step-by-step DD output is folded in here, as DD allows inside RPI. No plan doc: the only deliverable is this file plus the brief's status line. `docs/decisions/` is on the self-merge floor, so nothing is written there; if the owner confirms a pick, the dev cycle can lift the Decision section into a log row.

## 1. Result in brief

- **Motive test: conditional.** No review work now scheduled needs a new instance. A gap exists for harness work: 12% to 20% of the in-scope sampled findings, all from this repo, fall in three issue classes the canon has no row for (section 4). Whether it exists for the owner's real repos is unmeasured.
- **Tentative pick: [11] scheduled coverage pass.** Nothing is built now. When a recall run is next briefed, one pass applies the rule in section 8, proposes at most 3 instances, and the script is built at that point.
- **Confidence 55%, Path C.** Runner-up [15] (do the same pass now); the axis is when to pay the adjudication cost, and S5 alone decides it. The owner's question is in section 11.

## 2. What exists

- **Canon** (`docs/working/review-canon.md` §1): 8 instances, all meta-formalism-copilot (TS/Next.js), sizes 2 to 28 files. Rows are append-only. §4 names two expansion sources: the nd2/nd3 cells (unreachable) and this repo's own review history [observed].
- **Ledger** (`docs/working/canon-issue-ledger.md`, `.csv`): 56 confirmed issues plus 13 candidate or refuted rows, 69 CSV rows. N17 to N26 are still ungraduated. Last changed 2026-08-18 [observed].
- **Owner's rule** (Q-072, 2026-09-27): not every review adds an entry; the canon stays compact so it can run more often than a large benchmark, with broad issue-type coverage; a script converts, a higher-level heuristic proposes, and a simple trigger will not do [observed].
- **Review cost per instance**: E5 about $0.88, E8 about $19 to $44 (ledger recall table). Each added instance is 12.5% more sweep on an 8-row canon [observed].
- **Runner**: `review-arms.py`, `canon-to-crb.py` and `prep-cc-review-clones.sh` were archived on 2026-08-20; `archive/benchmark/README.md` says to migrate them to the SWRBench fork, not revive them here. So no canon runner is in active `scripts/` [observed].
- **Forks**: `external/SWRBench2` last committed 2026-08-24, `external/SWRench` 2026-07-31 [observed]. Whether either is the fork's final home was not checked [assumed: SWRBench2].

## 3. Motive test (S5)

| Planned review work | Needs new instances? | Evidence |
|---|---|---|
| A8 token measurement (roadmap Next, item 2) | No. It re-runs an existing cell against the 2.99M baseline; a new cell has no baseline | `docs/roadmap.md`; rubric row A8 |
| Review k and lite re-evaluation under Opus 5.5 | Would benefit, but deferred (ask before running). The one lite data point is a false Critical about a shell wrapper, a kind of input the TS canon cannot exercise | roadmap item 2; the data point is only in the session memory note `review-k-and-lite-reeval-deferred`, not in the repo |
| A future review cost cut (S7 recall gate) | Yes if it touches shell or instruction files. None is on the roadmap | `docs/roadmap.md` |

Revealed use: the last commit under `runs/review-arms` is the 2026-08-20 archive, and the ledger last moved 2026-08-18, so the canon has been evaluated 0 times in about 11 weeks [observed]. That is not evidence the owner dropped it: A8 and the re-evaluations are deferred for compute, on purpose. It does mean the binding limit on "evaluated more often" is not instance count.

**Verdict.** Do-nothing stays a live option, and "build the filter now" does not pass. A design record has value because a next recall run on harness work would want it; building ahead of that run has no observable to point at. The motive is weaker for S5's purposes: the pool is 100% this repo, while the real repos are TS/TSX (dayplanner-web, nature_photographer) and Python (threadwork), kinds much closer to what the canon covers.

## 4. Candidate pool: sample and coverage

**Sample.** Pool: about 330 distinct non-log `docs/reviews/` artifacts added in September (about 1,110 with execution logs; Q-072's 112 was an earlier count). Rubrics are the synthesis layer, so I took all 29 September rubrics, extracted 340 red and amber rows mechanically (43 red, 297 amber, after dropping 3 header rows), then classified **all 43 red rows and every fifth amber row by file order (59 rows): 102 rows**. Red is a census; amber is a systematic sample with no selection by content. One rubric (`q093`) was read in full, the others as row text cut to about 300 characters.

**Limits of the numbers.** Classification is from cut text. A second rater (the review agent) agreed on about 95% of the reds by column totals and about 90% of the 59 ambers row by row (it differs on rows 61, 81, 146, 281 and arguably 76). It had these labels in view, so both are upper bounds. Only row 76 touches a gap class, so the gap share stays near 20%. Red rows count rows, not distinct issues: `ans-copy-install` holds 12 reds across 3 rubrics, many one issue across passes. The pool is review findings in this harness, not defects that reached use, so the mix shows what reviews looked for as much as what breaks.

**Issue classes.** Adapted from the ledger's found-by vocabulary, with three added for what the canon lacks; a few rows sit differently from the ledger's own labels (`pf-A7` is enumeration there, T3 here), with no effect on the gap.

| Class | Canon rows (of 56) | Pool red (of 43) | Pool amber (of 59) |
|---|---|---|---|
| T1 in-diff behaviour | 6 | 2 | 2 |
| T2 cross-file contract | 4 | 2 | 0 |
| T3 doc, comment or claim accuracy | 13 | 1 | 24 |
| T4 enumeration, convention, duplicated source | 4 | 6 | 5 |
| T5 test strategy, vacuous tests | 4 | 1 | 1 |
| T6 deployment or runtime model | 5 | 0 | 3 |
| T7 fail-open guard or boundary | 9 | 12 | 6 |
| T8 structural seam | 2 | 0 | 0 |
| T9 concurrency, atomicity | 1 | 2 | 0 |
| T10 error handling, masking | 6 | 0 | 4 |
| T11 dependency, CI | 2 | 0 | 0 |
| **T12 hostile-shaped text: option-like names, newline, NUL, control bytes** | **0** | 5 | 3 |
| **T15 instruction prose as behaviour: skill or workflow steps that contradict code or themselves** | **0** | 1 | 5 |
| **T16 performance, resources** | **0** | 0 | 4 |
| T13H planted-content attack (symlink swap, planted hook, TOCTOU) | 0 | 11 | 2 |

**Reading.**

- T13H is out of scope under S1 (gates defend against honest slips, not a hostile same-uid loop). That removes 13 of 102 rows, including 26% of the reds, which a volume or severity trigger would have promoted.
- The gap classes T12, T15 and T16 hold 18 of the 89 in-scope rows: 20% unweighted, 21% with ambers weighted by 5 for the sampling stride. If every T12 row fell to S1, it would be 10 of 81, or 12%.
- "No canon row" depends on where the class lines fall. `dep-R1` and `N10` (instruction-file prose contradicting code) sit in T6 and T3 here and `fsc-A3` (cache hit-rate cost) in T6; moved, T15 and T16 would not be empty, and T12 would be the only gap. The full map is in the appendix.
- This is a gap for harness work only as far as measured. The 17 review files in the non-canon real repos were counted, not classified.
- Artifact kind differs too: where ranges resolved, changed non-doc files are mostly `.bats`, `.md`, `.sh` and `.py`, never `.ts` [observed, 7 of 29 rubrics].
- T12 sits on the S1 line. Some rows are honest slips (a `PERLIO` value in the environment), others read as hostile (forged digest lines from a crafted file name). A pass decides this only for the row it proposes, under S1 as written.

**Mechanical feasibility** [observed]. These decide what the script can do alone.

- Only 7 of 29 rubrics yield a usable range by regex. An eighth (`q087`, `main...182d143`) is empty today: 182d143 is now an ancestor of main, so a three-dot range gives 0 files, silently.
- Nearly all name a commit SHA in the header, but the reviewed commit is not the merge. Findings are fixed in-branch, so the merge head no longer holds the defect.
- 26 of 29 rubrics have `Finding` as the second column. The other 3 do not, so column position is not a grammar.
- Merge ranges overstate size. `feat/dev-cycle` merged at 7 non-doc files, +2,255, but its first reviewed state, `4225753a..89a3d3b7`, is 6 non-doc files, +342/-1. Q-076 merged at 11, +3,593; Q-085 at 4, +24/-12.

## 5. Invariants

- Canon rows are append-only; re-adjudication updates provenance only (`review-canon.md` §1) [observed].
- An instance's clone holds no descendant commits and no review of itself: guards (a) and (b) in `prep-cc-review-clones.sh`, from §5.4 traps 1 and 3 [observed].
- The recall denominator is the living ledger, with no by-construction 100% for the pipeline (ledger framing rule, 2026-08-14) [observed].
- Instrument and subject stay separate: benchmark implementation belongs in the fork (`archive/docs/2026-08-03-handoff-swrbench-fork.md`, `archive/benchmark/README.md`) [observed].

## 6. Prior art

`prep-cc-review-clones.sh` already builds scrubbed clones, hard-coded to meta-formalism-copilot. `crb-materialize.py` does the same for the external benchmark and adds disposable hash-pinned baselines, because a review clone's `.git` is hostile input to host-side git. `canon-to-crb.py` reads the ledger in the opposite direction. `review-canon.md` §1 is the row format, and the ledger CSV's header is the label format. The earlier selection doc, `review-arms-instance-selection.md`, is cited by the canon but no longer tracked [observed].

## 7. Divergent design: the proposal heuristic

### Step 1: diverge

`Prior pruning grep: no matches found for [canon, ledger, instance]` (the only hits are the word "canonical" and unrelated records 030, 035, 036). Candidate 0 comes from log row 31, the hand-canonized set.

0. Status quo: the canon grows by hand; nothing proposes.
1. Freeze and rename it the 8-instance canon, dropping "living" (Q-072 [3]).
2. Standing coverage-gap scan: each dev cycle, a script classifies new rubrics and files a proposal when a class is under-covered.
3. Fixed size with one-in-one-out: a new instance must evict one.
4. Escape-first: propose only defects that reached main and were fixed later.
5. Ideal if free: run every arm over every reviewed range and keep the ranges that most separate the processes.
6. Trigger: every rubric with a red row becomes a proposal (naive).
7. Stratified random monthly draw from the pool (naive).
8. LLM novelty judge scores each rubric against the canon (detector).
9. Owner nominates, tagging a commit "canon-worthy" at review time.
10. Outside-repo only: take instances only from the owner's real project repos.
11. Scheduled coverage pass: the rule runs once, only when a recall run is briefed.
12. Seeded defects: inject one defect per class into clean code (feels wrong).
13. Source from `docs/harness-feedback.md` entries in real repos.
14. Reframe: keep the canon fixed and leave breadth to the fork's benchmark.
15. One-shot now: apply the rule today with this repo as the subject, since no run exists yet to supply one, name the instances, then stop.

Health check: 2, 6, 7, 8 all assume a scan of new rubrics. 11 and 15 move the time dimension, 9 the owner, 10 and 13 the source, 3 the structure, 14 reframes, 0 and 1 are the minimal options.

### Step 2: diagnose

Hard:

- **L1 compact.** success: at most 12 rows in `review-canon.md` §1 (12 is my number, 50% above today; the owner set no figure), so sweep cost grows at most 50%.
- **L2 coverage, not volume.** success: each proposal names a class with no canon instance and at least one pool row in that class, and every such class with an eligible, relevant row gets a proposal when the mechanism runs.
- **L3 no simple trigger.** success: no count or severity threshold alone produces a proposal.
- **L4 real-world denominator (repo framing rule).** success: every label is a defect in code that was really written and reviewed; none exists by construction.
- **L5 re-checkable evidence (repo H4).** success: each proposal cites rubric file and row, plus an executed proof or a fix commit; an LLM score alone admits nothing.
- **L6 no big compute now.** success: the design needs no arm run to choose an instance.
- **Repo H3**, for the script. success: `bats` cases with a local fixture repo, no network, and `scripts/hermeticity-lint --root .` passes.

Soft: S1 (exclude T13H), S2 (no new mandatory dispatch), S3 (reuse the scrub logic), S5 (motive; real use outranks loop metrics), S6 (call site and a negative-capable observable), S8 (small, stdlib), S10 (no recurring owner chore).

Not bearing: H1, H2's gate clause (a proposal is not a gate, though the script's input checks follow H2's spirit), S7, S11.

### Step 3: match and prune

| # | Approach | L1 | L2 | L3 | L4 | L5 | L6 | S5 | S6 | S10 |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Status quo | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 1 | Freeze and rename | ✓ | ✗ | ✓ | ⚠ | ✓ | ✓ | ~ | ✓ | ✓ |
| 2 | Standing scan | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ~ | ⚠ |
| 3 | One-in-one-out | ✓ | ~ | ✓ | ⚠ | ✓ | ✓ | ~ | ~ | ~ |
| 4 | Escape-first | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ |
| 5 | Max separation | ✓ | ~ | ✓ | ✓ | ✓ | ⚠ | ~ | ~ | ✓ |
| 6 | Any red | ⚠ | ⚠ | ⚠ | ✓ | ~ | ✓ | ✗ | ✓ | ⚠ |
| 7 | Random draw | ⚠ | ⚠ | ⚠ | ✓ | ~ | ✓ | ✗ | ✓ | ~ |
| 8 | LLM novelty | ~ | ~ | ✓ | ✓ | ⚠ | ✓ | ~ | ~ | ~ |
| 9 | Owner nominates | ✓ | ~ | ✓ | ✓ | ~ | ✓ | ~ | ~ | ⚠ |
| 10 | Outside-repo only | ✓ | ✗ | ✓ | ✓ | ~ | ✓ | ✓ | ~ | ✓ |
| 11 | Scheduled pass | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 12 | Seeded defects | ✓ | ✓ | ✓ | ⚠ | ✓ | ✓ | ✗ | ~ | ✓ |
| 13 | Harness feedback | ✓ | ✗ | ✓ | ✓ | ~ | ✓ | ✓ | ~ | ✓ |
| 14 | Leave to fork | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ✓ |
| 15 | One-shot now | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ |

S1, S2, S3 and S8 separate the field only at [8] (S2, a new dispatch), [2] (S8, a standing classifier) and the T13H rows every survivor excludes. H3 binds the script in section 10, not the rule, so step-4 coverage counts L1 to L6.

[2] carries ⚠ on soft S10 only and stays in as the closest match to a filter that runs by itself. [0] and [11] are both ~ on L2, not a failure: neither proposes anything now, and [11] meets L2 only if its trigger fires. Only S5 separates [11] from [15], and [11] differs from [0] only in the recorded rule and one watch line. Survivors: **[11], [15], [2], [0]**. Parts of pruned candidates survive as rule terms: [4]'s fix evidence is the evidence gate, [10] is the tiebreak, [9] is a nomination line in the pass.

### Step 4: tradeoffs

| # | Effort | Risk | Coverage | Key downside | Hypothesis |
|---|---|---|---|---|---|
| 11 | Now 0. At trigger: about 2 hours of agent time plus a script under 400 lines; owner about 10 minutes | Low | 5/6 hard (L2 only if triggered) | Trigger may never fire, and then nothing differs from [0] | If chosen, the next recall run's brief carries at most 3 proposals and the run's decision differs between the first 8 rows and all rows; counter-evidence: the same decision on both. Window: that one run |
| 15 | Same work, now; owner about 10 minutes now | Low | 6/6 hard | Pays for harness-only instances no run may ever use | If chosen, the canon reaches 10 or 11 rows within two weeks and a recall run uses them within 6 months; counter-evidence: no run by 2027-05 |
| 2 | 1 to 2 days, plus a recurring classifier | Medium | 6/6 hard | Files triage against a canon that saturates after one pass | If chosen, at most 3 proposals in 90 days, each adopted; counter-evidence: any proposal left unanswered 30 days |
| 0 | None | Low | 5/6 hard (L2 partial) | Recall stays blind to shell and prose work | If chosen, a recall run on non-TS work would have to pick instances ad hoc; counter-evidence: no such run in 6 months, which would vindicate it |

Stress tests:

- **Boring alternative** (all). The rule fires about once, then stops: the gap is 3 classes and each closes with one instance, so the canon ends at 11 rows at most, inside the cap, until a new class appears. A recurring mechanism has almost nothing to do. [2] drops; [11] and [15] need no classifier script, so the pass is by hand using the section 4 table.
- **Revealed preferences** ([2]). The failure-pattern harvest went unfed as an advisory step (Q-074: 1 entry in about 128 fix commits) and was wired into build loops only after that (Q-226 [5], f91d7d09), so a scan a cycle really runs could work. But it would run against zero canon runs in 11 weeks, for a canon that closes after one pass. [2]'s risk moves from low to medium.
- **Invert the thesis** ([11], argue for [15]). Doing it now while memory is fresh is cheaper, but rubrics and SHAs do not decay, so the saving is small. Argue for [0]: if no recall run ever happens, [11] costs nothing either, and the two differ by one watch line. What [11] adds is what the Q-072 answer asked for: proposals exist at the moment they can matter.
- **Scale test** ([11]). If a new class appears later, the rule still works; at 12 rows it stops and asks the owner, because eviction would break the append-only rule.
- **What-if on the assumption "a recall run will come".** If none does, the only loss is this record and one watch entry.

```
┌─ DECISION: how canon instances get proposed ───────────────────────────┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes       │
└────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach              effort        risk      coverage     key downside
  ───  ───────────────────  ────────────  ────────  ───────────  ─────────────────────────
   11 ★ scheduled pass       ● 0 now       ● low     ◐ 5/6 hard   ◐ trigger may never fire
   15   one-shot now         ◐ ~2h + script ● low    ● 6/6 hard   ◐ may never be used
    2   standing scan        ○ 1-2 days    ◐ med     ● 6/6 hard   ○ triage for a saturating canon
    0   status quo           ● none        ● low     ◐ 5/6 hard   ○ recall blind to shell, prose

╭─ [11] scheduled pass   ★ recommended ───────────────────────────────────╮
│ effort    0 now; ~2h + small script at trigger      risk   low          │
│ coverage  5/6 hard · 7/7 soft                                           │
│ hypothesis  If chosen, the next recall run's brief carries at most 3    │
│             proposals and the run's decision differs between the first  │
│             8 rows and all rows; counter-evidence: the same decision on │
│             both. Window: that one run.                                 │
│ stress-tests applied                                                    │
│   · Boring alternative → no classifier script; the pass is by hand      │
│   · Invert the thesis → differs from [0] by one watch line, kept        │
│ key downside  the trigger may never fire; then it equals status quo     │
╰─────────────────────────────────────────────────────────────────────────╯
```

To expand another card, name its `#`.

```
▶ recommend [11] scheduled pass · confidence 55% · runner-up [15], axis = pay the adjudication cost now or when used
```

## 8. Decision (tentative, Path C)

Axis of disagreement: when to pay the adjudication cost. There is no stated owner preference on that axis, so the tiebreaker is S5: no motive exists until a run needs the instances, and the gap is unproven for real repos. Against that, [15] scores higher on hard coverage, which is why this is Path C at 55%.

**The rule** a pass applies, in order:

1. **Trigger.** A brief or owner answer schedules a recall-measuring run. A8 does not count, because it re-uses an existing cell.
2. **Gap.** List classes with no canon instance: T12, T15 and T16 today. A class in one instance is covered; the canon is compact, not balanced.
3. **Relevance.** Take the last 20 fix commits that correct code already merged after review, in the repos the run is about, and classify them by hand. A gap class with none of the 20 is theoretical for this run: propose nothing for it.
4. **Eligibility**, all required:
   - A range a rubric really reviewed, given as its base and reviewed commit, with base an ancestor of head. No invented sub-ranges.
   - At most about 10 non-doc files and about 500 changed lines. An over-limit range is out.
   - At least one red or amber row in the gap class, with an executed proof or a fix commit.
   - Not T13H, and in scope under S1.
5. **Rank.** Prefer a red over an amber; then a repo outside this one (S5), which limits overfitting to harness code. The owner's nominations join at this step.
6. **Limits.** One instance per class, so at most 3 per pass. Stop at 12 rows and ask the owner. Leave a gap open rather than pad it.

**Dry run on this pool (hand, skipping step 3, which needs a run's subject).**

| Class | Candidate | Range | Evidence | Result |
|---|---|---|---|---|
| T12 | `feat/dev-cycle` R1: option-like branch name truncates a file | `4225753a..89a3d3b7`, 6 non-doc files, +342/-1 | Probe-confirmed; fixed in d8b0cca9 with a regression test | Eligible, S1 call needed |
| T15 | `feat/dev-cycle-skill` A1: skill commits without the Operating Modes gate | `65bd4336..e438cd1`, the reviewed upper unit, 4 non-doc files, +129/-1 | Fix commit 6ee33e35 | Eligible, amber only; the one T15 red is unresolved across two branches, so it fails evidence |
| T16 | None found: no red rows; of the 4 sampled ambers, Q-076 and the egress range are over the limit and 2 are unsized | - | - | Stays open |

Result: 1 or 2 proposals, depending on the S1 call on T12 (a crafted branch name reads close to hostile); canon 8 to 9 or 10, sweep cost up 12.5% to 25%. Both are this repo, so step 3 could remove them for a run about the real repos. The dry run did not rebuild either clone or check the defect at the head.

See alternatives considered → next section.

## 9. Pruned candidates and why

Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[1 freeze]`: the Q-072 answer chose between [1] and [2], and that entry records a frozen metric as already ruled out. `[3 one-in-one-out]`: breaks the append-only rule and past-run comparability; the 12-row stop replaces it. `[4 escape-first]`: no class signal, and a merged-versus-in-branch fix split is unmeasured; kept as the evidence gate. `[5 max separation]`: needs arm runs, against L6. `[6 any red]`: the simple trigger the owner refused; 11 of 43 reds are out of scope anyway. `[7 random]`: volume with no coverage reason. `[8 LLM novelty]`: rests admission on a judgment against H4 and adds a dispatch for a once-only job. `[9 owner nominates]`: a recurring chore under S10; kept as an optional input. `[10 outside-repo only]`: 17 review files across the three non-canon real repos, likely too thin to fill a class [inferred from the count; not classified]; kept as a rank term. `[12 seeded]`: labels by construction, against L4. `[13 harness feedback]`: friction reports, not code defects in a range. `[14 leave to fork]`: the fork's benchmark is large and dormant, the opposite of a compact frequent canon. `[2 standing scan]`: survived the prune, kept for the owner as an option; the stress tests rank it third. Prior pruning grep: no matches found for [canon, ledger, instance].

## 10. The conversion script (a)

Not built here. Spec for the trigger moment.

**Interface.** `canon-instance --repo PATH --base SHA --head SHA --id NAME --rubric PATH`. The caller states the range, because section 4 shows the rubric cannot supply it. Python stdlib, under 400 lines, one file.

**It does:**

- Check that both commits resolve, base is a strict ancestor of head, the two-dot range is not empty, and size is within the limit; refuse with a named reason otherwise (the Q-085 R1 lesson, and the `q087` empty range in section 4).
- Print a `review-canon.md` §1 row and skeleton ledger CSV rows to stdout. It writes neither file, so the append-only canon changes only by a reviewed commit.
- Parse rubric rows by header name, never column position, and refuse a table with no `Finding` column.
- Build the scrubbed clone with guards (a) and (b), and report any `docs/reviews/` file naming the reviewed head.

**It does not** classify, rank, propose or run an arm.

**Home.** Four options: `scripts/` here; the SWRBench fork; un-archive `prep-cc-review-clones.sh` with parameters; a checklist with no script. Path A: **the fork.** The archive README and the handoff doc both put instrument code there, and the recall runner must move there anyway, so the clone step sits with its consumer. Keeping it here would couple instrument to subject and revive archived code; a checklist fails S4, because the scrub is the step a person gets wrong. One caveat: the fork has been idle since 2026-08-24, so the trigger's first step is confirming it is the live home.

**Observable that could come out negative (S6).** The call site is the recall run the watch names.

- **At the run:** compare the decision the run exists to make, computed on the first 8 rows and on all rows. Under [0] there is no second view, so this measures the added rows themselves, not whether the classes matter in general.
- **Helped:** the decision differs. **Did not help:** the same decision on both. Then the rule is not applied again until a new class appears, and the added rows stay as history. Window: that one run.
- **Rule step 3 is the real-use check.** It can come out negative before anything is built. It is coarse and applies per class: 0 of 20 still happens 12% of the time at a true share of 10%, and 36% at 5%. No baseline exists, because the 20% in section 4 is review findings, not escapes.

## 11. The owner's question

How should canon instances get proposed? Pick: [1], tiebreaker S5: no motive exists until a run needs the instances, and the gap is measured only on this repo's harness work.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Scheduled pass** | Nothing is built now. When a recall run is briefed, one pass applies the section 8 rule and proposes at most 3 instances | About 10 minutes, once, at that run | No run comes, and nothing differs from [4] |
| **[2] One pass now** | Same rule today with this repo as the subject: build the script, add 1 or 2 dev-cycle candidates as rows | About 10 minutes now | Effort goes into harness-only instances no run may use |
| **[3] Standing scan** | A script checks new rubrics each cycle and files proposals | A triage entry when one fires | A standing script for a rule that closes after one pass |
| **[4] Leave it** | No proposals; the canon grows only by hand | None | A recall run on shell or prose work has no instance and picks ad hoc |

Also yours inside any of these: the 12-row cap is my number.

- **Interim:** [1]; the canon and ledger are unchanged.
- **If the answer differs:** [2] starts a build brief; [3] adds a classifier; [4] drops the watch. Nothing here needs undoing.
- **For the cycle under [1]:** a `deferred` watch on "a recall run is briefed", naming section 8.

## Gotchas

Failure-pattern grep: FP-064, FP-071, FP-108 (see Prior failures section)

- The reviewed commit is not the merge commit: the defect is gone by merge. Taking the merge head would make an instance with no findable labels.
- `git diff main...X` goes empty once X is merged, silently; pin both ends by SHA.
- `review-canon.md` §1 still says 43 issues; the ledger says 56. Trust the ledger.
- Reviewing this repo's own ranges is self-referential: the reviewer's skills may be in the range, and older rubrics sit in the tree. Guard (b) covers only a review of the head itself. A pass drawing from this repo should say so in the instance's provenance.

## Prior failures

- **FP-064** rubric overwritten each run destroyed prior findings: a rubric path is not a stable label source, so an instance pins the rubric by commit.
- **FP-071** a ledger write had no owner at the moment it was possible: the pass owns its row writes, so nothing depends on a later step remembering.
- **FP-108** a provenance record used the wrong denominator: a looser fit, but an added instance also rebases recall, so published figures stay dated to the ledger revision they used.

## Revisit triggers

Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.

If a recall run is briefed. If the owner re-opens k or lite re-evaluation. If a roadmap item proposes a review cost cut (S7). If no recall run is briefed by 2027-05, ask whether the canon still earns its place. If the canon reaches 12 rows. If rule step 3 finds a gap class in 2 or more of 20 escapes in a real repo. A person re-classes any row before it is admitted on a T-class label.

## Appendix: class maps

Canon, 56 rows:

- T1: csp-A1, pf-A5, pf-A6, D6, N14, N15.
- T2: csp-R1, D3, N3, N8.
- T3: csp-R2, csp-A2, csp-A3, lean-R1, hyg-R1, dep-R2, fsc-R1, cor-A3, cor-A4, pf-A7, pf-A8, D4, N10.
- T4: hyg-A1, fsc-A2, cor-A1, cor-A2.
- T5: csp-A4, fsc-A4, pf-A2, D1.
- T6: dep-R1, fsc-A1, fsc-A3, C1, C3.
- T7: sec-R1, sec-A1, pf-A1, pf-A3, C2, C4, D2, N1, N11.
- T8: pf-R1, pf-A4.
- T9: D5.
- T10: lean-R2, lean-A1, N4, N5, N12, N13.
- T11: N2, N9.

Pool reds, by rubric in file order (the digest rubric restarts its numbering each pass): digest: R1 T12, R2 T7, R3 T1, R1 T12, R2 T15, R1 T12. dev-cycle: R1 T12. q094: R1 T7, R2 T7. q085: R1 T7. q076: R1 T13H, R2 T7. skill-fixtures-q062: R1 T5, R2 T7, R3 T7, R4 T12, R5 T7. q058: R1, R2, P2-R1, P2-R2, P2-R3 all T13H. copy-install-final: R1 T13H, R2 T7. copy-install: R1 to R3 T13H, R4 T9, R5 T3. answers iter3: R6 T2. answers: R1 T7, R2 T13H, R3 T4, R4 T7, R5 T1. questions-closeout: R1 T4. prompt-audit: R1 T2. egress: R1 T4, R2 T4, R3 T9, R4 T7, R5 T4, R6 T4.

Pool ambers, by position n in file order counting table rows, headers included (n = 1, 6, 11 ... 296; 136 is a header and dropped): T1: 36, 206. T3: 1, 6, 21, 26, 56, 66, 71, 86, 91, 96, 101, 111, 121, 126, 151, 191, 211, 216, 221, 226, 236, 241, 276, 281. T4: 116, 231, 246, 256, 296. T5: 146. T6: 61, 81, 266. T7: 156, 166, 176, 181, 196, 271. T10: 46, 51, 161, 171. T12: 76, 141, 201. T13H: 186, 286. T15: 11, 16, 31, 41, 106. T16: 131, 251, 261, 291.

## Files read

Last verified: 2026-11-05
docs/working/briefs/2026-11-05-canon-proposal-filter.md
docs/working/canon-issue-ledger.md
docs/working/canon-issue-ledger.csv
docs/working/review-canon.md
docs/working/questions-archive.md
docs/human-author/answers-9-27-26.txt
docs/roadmap.md
docs/decisions/log.md
docs/decisions/*.md (Pruned candidates grep)
docs/failure-patterns.md
docs/thoughts/code-review-evaluation-state.md
docs/reviews/q093-code-review-rubric-2026-09-28.md
docs/reviews/*rubric* (the 29 September rubrics, by extraction)
docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md
docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle.md
docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-skill.md
archive/benchmark/README.md
archive/benchmark/scripts/canon-to-crb.py
archive/benchmark/scripts/prep-cc-review-clones.sh
archive/benchmark/scripts/crb-materialize.py
archive/benchmark/scripts/review-arms.py
archive/docs/2026-08-03-handoff-swrbench-fork.md
workflows/divergent-design.md
workflows/research-plan-implement.md
workflows/pr-prep.md
workflows/review-fix-loop.md
