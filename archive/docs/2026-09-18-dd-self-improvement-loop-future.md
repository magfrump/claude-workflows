# DD — What should become of the self-improvement loop?

**Goal**: Decide what should become of `scripts/self-improvement.sh` (1,819 lines), its three `scripts/lib/si-*.sh` modules (2,449 lines), and the ~197 bats tests across 14 SI-coupled suites — without assuming that unattended autonomous self-improvement of this repo is worth having at all.

**Project state**: `main`, working tree shared with a concurrent agent · standalone decision, not part of a larger initiative · not blocked.

**Task status**: `complete` (DD run end-to-end; decision recorded below; no step-5 record written to `docs/decisions/` and nothing committed, per the task brief).

---

## Framing note — the motive is the first question, not the fourth

This DD deliberately does **not** open from "the loop should continue in some form; in what form?"
The first question is whether unattended autonomous self-improvement of *this* repo is a thing worth
having. `[1] Retire entirely` and `[4] Keep exactly as is` are both scored as live candidates, and the
generation health check below is run specifically against the risk that the option-generating machinery
manufactures a false middle out of "extract the good bit."

The step-4 stress-test pass includes an *Invert the thesis* move whose whole job is to argue that the
recommended candidate **is** that false middle.

---

## Evidence base (verified in-tree on 2026-09-17)

Everything load-bearing below was checked against the repo rather than taken from the brief. Where the
brief and the repo disagree, the repo wins and the discrepancy is noted.

| # | Claim | Verified how | Verdict |
|---|-------|--------------|---------|
| E1 | The loop is mechanically intact and its gates are real | `scripts/self-improvement.sh` carries Gates 1a–1h at lines 1113, 1129, 1145, 1172, 1193, 1225, 1253, 1357 | **confirmed** |
| E2 | Last actual run was 2026-06-23, not 2026-08-06 | `docs/working/archive/2026-08-06-round-1-report.json` → `"timestamp": "2026-06-23T16:33:23Z"`. The `2026-08-06` prefix is the *archival* date. | **confirmed — ~3 months dormant** |
| E3 | 143 commits since 2026-08-07, none from the loop | `git log --oneline --since=2026-08-07 \| wc -l` → 143; `git branch -a` shows no `feat/r*` branch | **confirmed** |
| E4 | The loop's output shape is prose sections in markdown workflows | `docs/working/archive/2026-08-06-tasks-round-1.json` — all four tasks are "add a subsection to workflows/*.md"; `wc -l workflows/*.md` → 3,811 | **confirmed** |
| E5 | The loop's own falsifiable hypothesis is refuted and nobody recorded it | The last run shipped `docs/working/incident-journal.md` with hypothesis *"will accumulate at least 3 entries within 3 rounds"*. The file is 10 lines: header, preamble, and an empty table. **0 entries.** | **confirmed — REFUTED, unrecorded** |
| E6 | 50 deferred hypothesis questions were never answered | `docs/working/archive/2026-08-06-morning-summary.md` — "**Answer the 50 matured deferred hypothesis questions**… That is the one action that needs you this cycle." Open hypotheses: 50, nearly all tagged `[planner-authored — review framing]` | **confirmed** |
| E7 | The loop's maintenance tripped its own gates | Same run: task `hypothesis-evaluator-target-rule` rejected with `"shellcheck failed: scripts/self-improvement.sh"` | **confirmed** |
| E8 | The test-baseline gate earns its keep | `guides/validation-gates.md` + `test/test-baseline-gate.bats` (11 tests); the archived `all_rejected`-on-`tests` rounds are the incident it exists for | **confirmed** |
| E9 | The DD-output scraping is self-admittedly brittle | `scripts/self-improvement.sh:473-485` — "DD Output Format Contract: Survivors Section", `sed` between `### Survivors` and the next `### `, then `grep '^- \*\*#[0-9]'` | **confirmed** |
| E10 | The SI loop is referenced from ~17 doc sites | `rg -n "self-improvement\|SI loop" workflows/ guides/ skills/ patterns/` → `guides/validation-gates.md` (×7), `guides/subtraction-checklist.md`, `guides/cross-project-setup.md`, `guides/test-hermeticity.md`, `guides/devcontainer-setup.md`, `guides/README.md` (×2), `skills/code-review/SKILL.md:573`, `patterns/requesting-user-input.md:93`, `workflows/divergent-design.md` (×5: Path C, Round claim, two acceptance-checklist lines) | **confirmed** |
| E11 | "~141 bats tests" undercounts | 14 strictly-SI suites total **197** `@test` cases (`precondition-gate` 26, `round-log-functions` 22, `morning-summary-clusters` 19, `code-review-gate` 19, `rubric-selection` 17, `validate-task-json` 15, `claude-headless-flags` 13, `si-input-rejected-history` 12, `test-baseline-gate` 11, `append-approved-hypotheses` 11, `round-report-schema` 10, `parse-si-priority-hypotheses` 10, `convergence-detection` 8, `worktree-cleanup-functions` 4). Two more suites (`cc-isolated-functions` 81, `hermeticity-lint` 49, `function-inventory` 10) *mention* SI files but are not SI-owned. | **corrected upward: 197, not 141** |
| E12 | The "state-management bug" is a dead resume path | `START_ROUND=1` is assigned once at `:432` and read only at `:143` to label the morning summary. The loop is `for ROUND in $(seq 1 $MAX_ROUNDS)` at `:434` — it **cannot resume**. A crash in round 2 restarts at round 1 against an already-appended `round-history.json`. Separately, the header at `:18-23` documents `MAX_ROUNDS` as an env var but `:326` hardcodes `MAX_ROUNDS=3` with no `${…:-}` default, so the documented override does not work. | **confirmed — two defects, both latent** |
| E13 | Decision 010's design bet has itself been falsified | 010's stated feedback loop is *"user reads summary, updates si-input.md, runs next overnight session."* Observed: summary read (or not), si-input not updated, next session never run, 50 questions unanswered, three months elapsed. | **confirmed** |

Two further rows were produced by the step-4 stress-test pass and are recorded here so the evidence base
is in one place:

| # | Claim | Verified how | Verdict |
|---|-------|--------------|---------|
| E14 | Documented-but-unforced steps do not get executed in this repo | `workflows/pr-prep.md:18-66` instructs "Do not skip this step" for appending `FP-NNN` entries. `grep -c '^- \*\*FP-[0-9]' docs/thoughts/failure-patterns.md` → **0**; `git log --since=2026-05-18 --grep='^fix' \| wc -l` → **104** | **confirmed — 104 fix commits, 0 entries, 4 months** |
| E15 | No validation gate earns extraction on measured data | 343 task validations across 55 archived round reports; full table in §4.2 | **confirmed — see §4.2** |

E13 is the single most important row. The loop's current architecture rests on a human closing the
evaluation loop asynchronously. That mechanism has now been run as a live experiment for three months
and it did not close. E14 explains *why* it did not, and generalises: the mechanism that failed is not
specific to the loop, so no candidate may rely on it.

---

## 1. Diverge

### 1.0 Pre-generation grep — carry forward prior pruning

    grep -rn -B2 -A12 "Pruned candidates" docs/decisions/*.md | rg -i "loop|self-improvement|gate|worktree|orchestrat|autonom|round"

`Prior pruning grep: no matches found for [loop, self-improvement, gate, worktree, orchestration, autonomy, round].`

The three SI-governing decision records — `005-validation-step-self-improvement.md`,
`010-si-rewrite-three-phase.md`, `020-self-improvement-loop-dogfoods-repo-process.md` — all predate the
`Pruned candidates` convention (introduced around 017/021) and carry no such section. The grep returned
hits only from unrelated decisions (015, 017, 028, 030, 031, 035, 036), none of which pruned a candidate
in this decision's space.

One near-miss is worth recording as a **soft carry-forward**, since it is prior pruning in substance if
not in form: **decision 010's "What was removed"** list deleted autonomous hypothesis evaluation, six
satellite scripts, and per-task hypothesis fields, on the explicit ground that *"the evaluations were
unreliable and produced misleading signal."* That pruning is carried forward: **no candidate in this DD
re-proposes autonomous in-loop hypothesis evaluation.** Candidate `[7]` below deliberately tests the
boundary by proposing a *measurement* harness rather than an *evaluation* one, and is pruned partly on
010's rationale.

### 1.1 Candidates

Candidate `[0]` is the status quo per decision 020 (keep the loop as built, Tiers A/B/C), included per the
workflow's adjacent-prior-decision rule.

| # | Candidate | One line |
|---|-----------|----------|
| 0 | **Keep, don't run** | Leave every file exactly where it is, keep maintaining it, and accept that it stays dormant — retained as option value. |
| 1 | **Retire entirely** | Delete the script, the three lib modules, all 14 SI-owned bats suites, and sweep the ~17 doc references. Keep nothing. |
| 2 | **Extract the gates** | Reimplement Gates 1a–1h as a standalone `scripts/si-gates.sh <branch>` → JSON verdict; delete the round driver; wire the gates into `pr-prep` / `review-fix-loop`. |
| 3 | **Extract the gates + prose driver** | `[2]`, plus a `workflows/self-improvement.md` prose workflow that an agent follows in place of the bash driver. |
| 4 | **Keep and resume** | Fix the `START_ROUND` / `MAX_ROUNDS` defects (E12), then actually run it again on the existing three-round, 80%-convergence design. |
| 5 | **Archive it** | `git mv` the whole SI surface into `archive/`, delete the tests, keep the code readable as history. |
| 6 | **Keep the code, drop the tests** | Stop maintaining the 197 tests; leave the script in place unverified. |
| 7 | **Outcome ledger first** *(ideal if effort were free)* | Build real measurement — per-change token cost, review rounds to clean, gate-fail rate, workflow-invocation counts — and re-enable the loop only once "did it help" is answerable. |
| 8 | **Retarget, don't retire** | Keep the driver but forbid it from touching `workflows/`; point it exclusively at `scripts/` and `test/`, where shellcheck and tests-vs-baseline actually have teeth. |
| 9 | **Replace with a scheduled prompt** | Delete the bash entirely; use the `/loop` or `schedule` skill to run one DD→implement pass on a cadence, with no orchestration code at all. |
| 10 | **Keep only the worktree harness** | Extract the parallel-worktree spin-up/cleanup as a general fan-out tool for CLAUDE.md row-2 batch work; drop gates and driver. |
| 11 | **Extract gates *and* worktree harness** | `[2]` + `[10]` as two standalone scripts; delete driver and idea generation. |
| 12 | **Keep the evaluation half only** | Delete generation and implementation; keep the morning summary, hypothesis ledger and incident journal, so the repo retains its evaluation surface. |
| 13 | **Repoint it at another repo** | The loop is roughly generic; run it against a consumer project where the output would be code, not prose. |
| 14 | **Probe first, decide after** | Run it once tonight, timeboxed, and let the result decide — no structural change yet. |

15 candidates.

### Lens coverage

Technical `[2] [10] [11]`; Interface `[2]`; Procedural `[3] [9] [14]`; Social/organizational `[7] [12]`;
Time-shifted `[5] [14]`; Reframe `[1] [8] [13]`. Six of six lenses represented.

### Generation health check

- **Candidate clustering — TRIGGERED.** `[2] [3] [10] [11]` are four variants of one assumption: *that
  something inside the loop is worth extracting*. Named. The counter-candidates that violate it —
  `[1]`, `[5]`, `[6]`, `[13]` — were generated explicitly to break the cluster, and `[1]` is carried into
  step 3 as a survivor rather than being used as a strawman floor. This is the exact false-middle risk the
  framing note flags, and it is why `[1]` gets an honest step-4 row.
- **Missing perspectives — clear.** Do-nothing present twice, in two genuinely different forms (`[0]` keep
  and don't run; `[4]` keep and resume). Naive option present (`[6]`, `[14]`). Ideal-if-free present (`[7]`).
- **Excessive vagueness — clear.** Every candidate names specific files, specific deletions, or a specific
  invocation site.
- **Dimensional anchoring — clear.** Four distinct dimensions moved: *artifact set* (what exists at all —
  1, 2, 5, 10, 11), *who orchestrates* (bash vs. agent prose vs. human cadence — 3, 9, 14), *what it targets*
  (workflows vs. scripts vs. another repo — 8, 13), and *when* (now vs. after measurement — 7, 14).

**Console line:**

```
◇ step 1 diverge    15 candidates → docs/working/dd-self-improvement-loop-future.md
                      0 keep-dont-run  1 retire  2 extract-gates  3 gates+prose  4 keep-resume  …
```

---

## 2. Diagnose

### Hard constraints

**H1 — Whatever survives must be exercised by the repo's real work within 30 days of the decision.**
This is the constraint the current state fails. Three months of maintenance with zero invocations is the
defect being fixed, and any candidate that produces a *new* artifact nothing invokes reproduces it.
`success:` on 2026-10-17, `git log --since=2026-09-17` shows ≥3 commits whose diff touches the surviving
artifact's invocation path, **or** the surviving artifact's own output/log file has ≥3 dated entries. A
candidate that deletes everything satisfies this vacuously and that counts.

**H2 — No surviving artifact may carry a maintenance obligation without a corresponding exercise site.**
`success:` for every surviving `scripts/*.sh` or `workflows/*.md`, `rg -l '<artifact>' workflows/ test/ scripts/`
returns ≥1 hit that is not the artifact itself and is reachable from a command a session actually runs
(a `workflows/*.md` numbered step, a bats suite, or another script's call site). A doc that merely *mentions*
the artifact does not count.

**H3 — The test-baseline isolation property must survive in whatever form validation takes.**
This is the single most expensively-learned property in the SI surface (E8): three full rounds went
`all_rejected` on `tests` from one pre-existing failure before Gate 1e scored against a baseline.
`success:` `test/test-baseline-gate.bats` (11 cases) passes against the surviving implementation, **or**
its 11 assertions are migrated verbatim to a suite that does. Deleting the property is allowed — but only
as a stated forfeit, never as an oversight.

**H4 — The decision must not silently orphan the ~17 doc sites that reference the loop (E10).**
`success:` at close-out, `rg -n "self-improvement|SI loop" workflows/ guides/ skills/ patterns/ docs/decisions/`
is run once and every hit is either (a) still accurate, (b) rewritten, or (c) explicitly annotated as
historical. Zero hits describing a mechanism that no longer exists.

**H5 — No candidate may claim a benefit it cannot demonstrate within one cycle.**
The repo's stated evaluation stance is real-world value over by-construction metrics, with living-ledger
denominators. E5 is the cautionary precedent: a shipped artifact carried a falsifiable hypothesis, the
hypothesis was refuted by observation, and nothing recorded it. `success:` the candidate names one
observable, recorded within 30 days, that **could come out negative** — and the place it gets recorded is
named too. "Volume of changes merged" is explicitly not such an observable.

**H6 — Solo-dev, local-merge-only.** No candidate may depend on GitHub PRs, CI runners, a second
reviewer, or any egress this sandbox lacks. `success:` the candidate's operating instructions contain no
`gh pr` / CI step and run to completion from one local shell.

**H7 — Reversibility.** `success:` whatever is deleted lands as a single commit on `main`, so
`git show <sha>^:<path>` restores any file and `git revert <sha>` restores all of them; no history rewrite,
no force-push, no out-of-tree move that git cannot follow.

### Soft constraints

- **S1** — Prefer keeping the worktree-isolation know-how reachable for CLAUDE.md row-2 batch fan-out.
- **S2** — Prefer reducing total bash under maintenance (currently 4,268 lines across four SI files, plus 197 tests).
- **S3** — Prefer a decision that *serves* the repo's eval stance rather than contradicting it.
- **S4** — Prefer one artifact over two.

> **Constraint revision, recorded here for the re-reader.** H3 was demoted from **hard to soft (S5)**
> during the step-4 stress-test pass, after the gate-rejection measurement in §4.2 showed the
> test-baseline property is loop-shaped (its originating incident was 14 unattended branches validated
> against one dirty baseline) and partially duplicated by `workflows/pr-prep.md:332-343`. It was written
> as hard on the brief's framing that it was the most expensively-learned property in the surface; that
> framing is half-right — the lesson was expensive, but it was a lesson about *batch* validation. The
> step-3 matrix below is left as originally scored, with H3 still in the hard columns, so the revision is
> visible rather than retrofitted. Final constraint set: **6 hard (H1, H2, H4, H5, H6, H7) · 5 soft
> (S1–S5)**.

**Console line:**

```
◇ step 2 diagnose    11 constraints (7 hard · 4 soft) → docs/working/dd-self-improvement-loop-future.md
                      (H3 → soft S5 in step 4 on measured evidence; final 6 hard · 5 soft)
```

---

## 3. Match and prune

Key: ✓ addresses well · ~ partial or uncertain · ✗ doesn't address · ⚠ actively makes worse

| # | Candidate | H1 exercised | H2 no idle upkeep | H3 baseline prop | H4 doc sweep | H5 demonstrable | H6 solo/local | H7 reversible | hard met |
|---|-----------|----|----|----|----|----|----|----|-----|
| 0 | Keep, don't run | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ✓ | 4/7 |
| 1 | Retire entirely | ✓ | ✓ | ✗ | ~ | ✓ | ✓ | ✓ | 5/7 |
| 2 | Extract the gates | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | **6/7** |
| 3 | Gates + prose driver | ~ | ~ | ✓ | ✓ | ~ | ✓ | ✓ | 4/7 |
| 4 | Keep and resume | ~ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | 5/7 |
| 5 | Archive it | ✓ | ✓ | ✗ | ~ | ✓ | ✓ | ~ | 4/7 |
| 6 | Keep code, drop tests | ✗ | ⚠ | ⚠ | ✓ | ✗ | ✓ | ✓ | 2/7 |
| 7 | Outcome ledger first | ✗ | ✗ | ✓ | ✓ | ~ | ~ | ✓ | 3/7 |
| 8 | Retarget at `scripts/` | ~ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | 5/7 |
| 9 | Scheduled prompt | ~ | ✗ | ✗ | ~ | ~ | ✓ | ✓ | 2/7 |
| 10 | Worktree harness only | ✗ | ✗ | ✗ | ~ | ~ | ✓ | ✓ | 2/7 |
| 11 | Gates + worktree harness | ✓ | ~ | ✓ | ~ | ✓ | ✓ | ✓ | 5/7 |
| 12 | Evaluation half only | ✗ | ⚠ | ✗ | ~ | ⚠ | ✓ | ✓ | 2/7 |
| 13 | Repoint at another repo | ✗ | ✗ | ✓ | ✗ | ~ | ✗ | ✓ | 2/7 |
| 14 | Probe first | ~ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | 4/7 |

### Pruning rationale

- **`[0]` discarded** — ✗ on H1, H2 and H5 simultaneously. It is the present state, and the present state
  is what the decision exists to change: three months of upkeep for zero invocations, claiming an option
  value it cannot demonstrate. Surfaced rather than hidden, because "do nothing" has to be scored, and it
  scores badly on the three constraints that matter most.
- **`[6]` discarded** — ⚠ on H2 and H3. Keeping 4,268 lines of bash whose only correctness evidence is
  197 tests, and then deleting the tests, is strictly worse than either keeping both or deleting both.
- **`[7]` discarded** — ✗ on H1 and H2. It is the ideal-if-free space-widener and it did its job: the idea
  of an outcome observable survives as `[2]`'s falsifiable hypothesis. As a *candidate* it proposes building
  new unexercised infrastructure to justify existing unexercised infrastructure, and it rebuilds the class
  of thing decision 010 deleted for producing misleading signal. `~` on H6 because usage measurement of
  human workflow behavior is precisely what 010 found this environment cannot capture.
- **`[5]` discarded — dominated.** Same forfeit as `[1]` on H3, worse than `[1]` on S2 (the lines stay in
  the tree), and only `~` on H7 (an out-of-tree move is followable by git but the tests are gone either way).
  `[1]` does the same job more honestly.
- **`[9]` discarded — dominated by `[1]`.** It is `[1]` plus a calendar entry, and calendar discipline is
  the exact mechanism E13 falsified. A scheduled prompt that generates prose sections nobody evaluates is
  the current failure with a cron expression attached.
- **`[10]` and `[11]`'s worktree half discarded** — ✗ on H1/H2. CLAUDE.md row 2 already gets worktree
  isolation from the Agent tool's own `isolation: "worktree"` parameter, not from a bash script. Extracting
  a second mechanism for a capability the harness already provides creates an artifact with no invocation
  site by construction. `[11]` therefore collapses into `[2]`, and S1 is satisfied without any code.
- **`[12]` discarded** — ⚠ on H5. It preserves exactly the surface that provably accrued zero incident-journal
  entries (E5) and 50 unanswered questions (E6), while deleting the only thing that fed it. More ledger, no
  producer.
- **`[13]` discarded** — ✗ on H4/H6 and out of scope. No consumer repo lives in this tree, and the standing
  convention is that benchmark and cross-repo work goes to the SWRBench fork, not here.
- **`[14]` absorbed, not discarded** — it is not a destination, it is evidence-gathering. It survives as the
  Trigger-bound decision rule attached to the chosen candidate (step 4), where one timeboxed probe run is
  the named Revisit path.

### Fix sketches for survivors

- **`[1]`'s H3 gap** is not fixable within the candidate — forfeiting the test-baseline property *is* the
  candidate. The honest framing is that `[1]` trades a real, cheaply-held property for a smaller tree, and
  it must be scored on that trade rather than credited with a fix it cannot make.
- **`[2]`'s H4 gap** is fixable and cheap: the same commit that deletes the driver rewrites
  `guides/validation-gates.md` to point at `scripts/si-gates.sh`, annotates `guides/subtraction-checklist.md`
  and the `workflows/divergent-design.md` Path-C / Round-claim passages as historical, and drops the
  `guides/cross-project-setup.md` do-not-copy list entry. One grep, one pass, ~1 hour.
- **`[3]`'s H1/H2 gap** is not cheaply fixable: nothing mechanically forces a `workflows/*.md` to be read,
  and the evidence (E4) is that this repo's marginal markdown section does not change behavior. A partial
  fix — adding a CLAUDE.md decision-tree row that routes to it — makes it discoverable but not exercised.
- **`[4]`'s H1 gap** is fixable only by the user's own behavior, which is the variable E13 measured and
  found wanting. Its H5 gap is fixable by a narrower rule: require every merged task to name a non-prose
  observable. That is a real mitigation and it raises `[4]`'s ceiling; it does not change H1.
- **`[8]`'s H1 gap** is the same as `[4]`'s, with one genuine improvement: pointing the loop at `scripts/`
  makes Gates 1e/1f load-bearing instead of `skip`, so a merged change at least has mechanical evidence
  behind it. That is why `[8]` is the strongest keep-the-loop candidate, not `[4]`.

**Console line:**

```
◇ step 3 match       5 of 15 survived → [2] [1] [4] [8] [3]
```

### Survivors

- **#2 Extract the gates** — reimplement Gates 1a–1h as a standalone `scripts/si-gates.sh <branch>` emitting a JSON verdict, delete the round driver and the three lib modules, wire the gates into `pr-prep` and `review-fix-loop`.
- **#1 Retire entirely** — delete the script, the lib modules, all 14 SI-owned bats suites and sweep the doc references; keep nothing, and forfeit the test-baseline property explicitly.
- **#4 Keep and resume** — fix the `START_ROUND` / `MAX_ROUNDS` defects and run the loop again unchanged in design.
- **#8 Retarget, don't retire** — keep the driver but forbid it from touching `workflows/`, pointing it exclusively at `scripts/` and `test/` where the mechanical gates have teeth.
- **#3 Gates + prose driver** — `#2` plus a `workflows/self-improvement.md` prose workflow replacing the bash orchestration.

---

## 4. Tradeoff matrix and decision

### 4.0 Per-criterion calibration via `matrix-analysis` (engaged)

Five candidates survived step 3 and the effort/risk axes turn on judgment rather than a known number, so
the optional calibration path was taken: `matrix-analysis` ran with the three scorecard axes passed as
*given* criteria (effort, risk, coverage — each framed higher-is-better so Strong→●, Adequate→◐,
Weak→○), one sub-agent per axis, each seeing all five candidates on one dimension only. Its Stage-1
criteria-confirmation step was pre-satisfied, so no prompt fired. The falsifiable hypotheses,
stress-test pass, key downsides and decision path stayed with DD.

**Returned ratings** (`++` Strong, `+` Adequate, `−` Weak):

| | effort | risk | coverage |
|---|---|---|---|
| [1] Retire entirely | + 4–7h, terminal | + forfeits a validated property | + clean on H1/H2/H5, lone hard ✗ on H3 |
| [2] Extract gates only | + 10–14h, terminal | ++ separates the validated half from the zero-output half | ++ only candidate whose H1 is structural, not aspirational |
| [3] Gates + prose driver | − 13–18h | + prose half risks false closure | + gate half carries it |
| [4] Keep and resume | − 2–4h + unbounded per-round carry | − diagnosis contradicted by the evidence | − every ✓ rests on "this time we'll run it" |
| [8] Retarget, don't retire | − 6–10h + the same carry | + sound premise, unvalidated bet | − same structural H1 problem as [4] |

Per-criterion rankings: **effort** [1] < [2] < [3] < [8] ≈ [4] · **risk** [2] > [3] ≈ [8] > [1] > [4] ·
**coverage** [2] > [1] ≳ [3] > [8] > [4].

Three observations from the pass, all adopted:

1. **Terminal vs. perpetual is the real effort axis.** Every one-time candidate lands in a 4–18h band;
   `[4]` and `[8]` are cheapest to start and keep paying per round (≈8 generated tasks to triage, a
   50-question backlog already unworked). Recurring carry was deliberately included in the criterion —
   excluding it flips the order and makes `[4]` Strong, and three months of carry for zero output is the
   phenomenon under decision.
2. **Reversibility does not discriminate** — all five are H7 ✓. What discriminates on risk is whether a
   candidate separates the validated component from the unvalidated one. `[1]` and `[4]`/`[8]` both
   refuse to separate, in opposite directions.
3. **`[8]` puts the script inside its own blast radius.** Pointing the loop at `scripts/` makes Gate 1f
   apply to the 4,268 un-clean SI lines. E7 is this already having happened once.

Three caveats were escalated for resolution — whether the gates decouple at all, the true live doc-site
count, and whether H3's `✗` on `[1]` should dominate. **All three are resolved in the stress-test pass
below, and resolving the third changed the recommendation.**

### 4.1 Stress-test pass

Five moves were selected: **Boring alternative**, **Revealed preferences**, **Invert the thesis**,
**Organizational survival**, and a **Failure-driven** pass run as a `what-if-analysis` sub-procedure on
the then-leading candidate `[2]` with `[1]` as the named alternative. Three of the five changed the
matrix, and one of them changed the recommendation twice.

#### Move 1 — Boring alternative (applied to `[2]`) — **CHANGED THE MATRIX**

*Is there a simpler approach that gets 80% of the benefit?* Tracing all eight gates for whether each is
(a) portable off the loop and (b) not already available elsewhere in this repo:

| Gate | Portable? | Already exists elsewhere? | Verdict |
|------|-----------|---------------------------|---------|
| 1a commits on branch | yes, trivial | one `git rev-list --count` line | not worth extracting; off-loop you are standing on the branch |
| 1b diff cap 500 lines | yes | **yes** — `workflows/pr-prep.md` Phase 1 already computes and checks branch size | **loop policy, not a validation property**, and it *contradicts* pr-prep's version: pr-prep advises splitting, this hard-rejects |
| 1c file scope | **no** | — | reads `files_touched` from the round's task JSON at `:1147`. No producer off-loop |
| 1d critical-file protection | yes | — | list at `:1180` protects `scripts/self-improvement.sh` itself — circular under every candidate but `[4]`/`[8]` |
| 1e tests vs. baseline | **yes, fully** | partially — `workflows/pr-prep.md:332-343` already carries a *richer* three-class triage (caused-by-branch / pre-existing / flaky) | `tap_failing_names` + `tap_new_failures`, `scripts/lib/si-functions.sh:515-538` — **25 lines, pure functions, zero loop state** |
| 1f shellcheck | yes | **yes** — `scripts/health-check.sh` check 6 already shellchecks every `.sh`/`.bash` in the repo | duplicate |
| 1g self-eval | yes | **yes** — pr-prep step 3 already lists `/self-eval`; costs two headless `claude -p` per changed file (`:1278-1291`) | duplicate + expensive |
| 1h multi-critic code-review | yes, branch-scoped (closes the decoupling caveat — it takes `$WT_DIR` as cwd, not round state) | **yes** — `workflows/pr-prep.md:232` already calls `/code-review` "required, not optional" | duplicate + expensive + see Move 5 |

**Finding: `[2]` is over-built by roughly an order of magnitude.** The brief's "the mechanical gates are
genuinely good and separable" is true of the *code* but not of the *value*: what is unique, portable and
not already wired somewhere exercised reduces to **one property, 25 lines, and its 11 tests**
(`test/test-baseline-gate.bats` sources only `si-functions.sh` and is already `@category fast`, so it runs
in `scripts/run-tests.sh --fast` today). A new 8-gate `si-gates.sh` would recreate health-check's
shellcheck, re-pay for pr-prep's code-review, and carry two gates with no off-loop meaning.

A new candidate `[16]` was therefore entered at step 4, per the workflow's rule that this move may surface
a candidate that should have been generated from the start. **Note the direction: toward `[1]`, not
toward a middle.**

> **[16] Retire with a carve-out.** Do `[1]` in full, with one exception: relocate `tap_failing_names`
> and `tap_new_failures` (25 lines) into `scripts/run-tests.sh` (or a small `scripts/lib/tap-utils.sh`),
> repoint `test/test-baseline-gate.bats`'s single `source` line, and have `run-tests.sh` report which
> failures are new against a baseline. No new top-level artifact. Cost: `[1]` + about one hour.

#### Move 2 — Revealed preferences — **CHANGED THE MATRIX**

*What do the humans and agents here actually do, versus what the docs say?* Run against `[2]`'s and
`[3]`'s load-bearing assumption — that wiring a step into a workflow causes it to be executed.

`workflows/pr-prep.md:18-66` already contains a documented, mandatory-sounding advisory: *"Do not skip
this step — the library's value compounds only if it's appended to."* It instructs the author to append an
`FP-NNN` entry to `docs/thoughts/failure-patterns.md` for every non-trivial `fix(...)` commit.

    $ grep -c '^- \*\*FP-[0-9]' docs/thoughts/failure-patterns.md      → 0
    $ git log --oneline --since=2026-05-18 --grep='^fix' | wc -l        → 104

**104 fix commits. Zero entries. Four months.** This is a third independent instance of the same shape as
E5 (incident journal, 0 entries) and E6 (50 unanswered questions). And it is structurally guaranteed here:
the repo never pushes, so there is **no CI and no mechanical forcing function anywhere** — the only
trigger for any documented step is the human typing the command.

Matrix changes:

- `[3]`'s risk revised **◐ → ○** and `[3]` is **pruned by the stress test**. Its prose-driver half does
  not merely "risk false closure"; the repo has three recorded instances of that exact outcome, and a
  `.md` added to an already-3,811-line `workflows/` has strictly weaker pull-to-execution than the
  runnable script that already went 86 days unrun.
- `[2]`'s H1 is revised **✓ → ~**. Its structural-exercise claim rests on pr-prep invoking it, and the
  measurement above says pr-prep's own unforced steps are not invoked. `[16]` is unaffected, because
  `run-tests.sh` is already the command sessions run — the property rides an existing invocation rather
  than needing a new one.

#### Move 3 — Invert the thesis (argue sincerely for `[4]` and `[8]`)

The honest case for keeping the loop: this repo's subject *is* workflows for agentic development, and a
repo about self-improving agent processes that cannot self-improve is a cobbler's-children problem. It has
197 tests and is green; dormancy is a *usage* failure, not a *code* failure. `[8]` sharpens this — the
output was bad (prose sections) precisely because it was pointed at prose, where Gates 1e/1f record `skip`.
Point it at `scripts/` and every merged change carries mechanical evidence.

**What survives:** `[8]`'s diagnosis is correct and is the best argument in the field against retirement;
it is why `[8]` is the pre-named Reverse fallback in §4.6. **What does not:** the inversion assumes the
binding constraint is *what the loop produces*. E13 says the binding constraint is *whether anyone closes
the loop*. Decision 010 deliberately removed autonomous evaluation, making a human the only evaluator; that
human has had 50 questions outstanding for three months. Retargeting changes the numerator and leaves the
denominator at zero.

#### Move 4 — Organizational survival

*Does this survive the maintainer's attention shifting?* Solo repo, so "turnover" is the same person three
months later — which is the observed history. The test is whether a candidate degrades loudly or silently.

- `[0]`, `[4]`, `[8]` degrade **silently**: nothing signals dormancy; the artifact stays green and
  unexercised, which is the state the decision exists to end.
- `[2]` degrades **quietly**, exactly as the FP-library advisory did — and worse, a rarely-invoked gate
  script bit-rots (hard-coded `main`, the `/opt/claude-workflows` payload path, a stubbed task-JSON path)
  until its first real invocation months later emits a **false pass**. Gate 1h's own comment names this:
  *"a weak reviewer's 'no findings' is a false attestation."* A false pass is worse than no gate.
- `[1]`, `[16]` **cannot degrade** — nothing is left to leave unattended.

#### Move 5 — Failure-driven (`what-if-analysis` sub-procedure on `[2]`)

Run as a full prospective consequence pass. Its findings that changed the analysis:

- **The gates' own guide states a loop-specific rationale.** `guides/validation-gates.md:3`:
  *"A single bad merge poisons subsequent rounds (later branches fork from main), so validation is the
  highest-leverage quality control."* Every hardening detail — the nonce, the root-owned baked skill
  payload, fail-closed parsing, opus pinning, critical-file protection, the `files_touched` contract —
  exists because **an unsupervised agent wrote the branch and could subvert its own reviewer.** In a solo
  interactive session where the human reads the diff before merging, that adversary is absent.
- **`[2]` ships a measured regression.** Gate 1h rejects on `red_count > 0` with no tier mapping and no
  amber-ack path. Decision 031, validated at 612k tokens across E1–E3, deliberately demoted exactly the
  marginal red classes 1h would re-block, and decision 030 measured the deep agentic path at ~$14.6 per
  instance as "prohibitive for review-fix looping" — which is why `scripts/lite-review.py` is the live
  path. Porting 1h into pr-prep un-decides two measured decisions with older code.
- **Decision 020 makes `[2]` circular.** Gate 1h exists *so the loop obeys pr-prep's rule*. Wiring it back
  into pr-prep is pr-prep enforcing its own pre-existing rule through a mechanism invented to make
  something else obey it.
- **`[2]` cannot pass its own gates.** The migration diff exceeds Gate 1b's 500-line cap by roughly 10×
  and deletes `scripts/self-improvement.sh`, which is on Gate 1d's protected list.
- **Three couplings the candidate set missed**, all of which any retiring candidate must handle:
  `test/hermeticity-lint.bats:806-818` carries two *anchor* tests pinning the layer-2 hermeticity gate's
  correctness to `round-log-functions.bats` + `self-improvement.sh` (commit `4d39475` is the indirect-closure
  incident they regress-test — these need a **replacement fixture, not a deletion**);
  `skills/code-review/SKILL.md:573` documents `self-improvement.sh` as the consumer of the
  `Replication:`/`Commit:` header fields and becomes factually false; and
  `guides/subtraction-checklist.md` (plus `scripts/skill-usage-report.sh` and health-check check 7) is
  triggered by "Step 5 of the self-improvement loop" and is orphaned by **every** retiring candidate.
- **The test inventory in the brief is incomplete.** Beyond the 14 SI-owned suites,
  `test/function-inventory.bats` `source`s `self-improvement.sh` in `setup()` and breaks entirely, and
  `test/claude-headless-flags.bats` tests a helper both 1g and 1h need.
- **Its decisive recommendation — and the move that settled this DD:** *the historical gate-rejection
  record exists and has never been queried.* `docs/working/archive/*round-*-report.json` holds per-gate
  pass/fail/skip for every task the loop ever validated. Extract only gates with a measured nonzero reject
  rate on a class nothing else catches. That converts the decision from taste to measurement — which is
  this repo's own standing rule. **It was run. See §4.2.**

### 4.2 The measurement that settled it — **CHANGED THE RECOMMENDATION**

343 task validations across 55 archived round reports:

| Gate | pass | **fail** | skip | What the failures actually were |
|------|-----:|---------:|-----:|---------------------------------|
| schema | 303 | 16 | 0 | loop-only (task JSON) |
| 1a commits | 275 | **9** | 0 | agent produced no commits — **loop-only by threat model** |
| 1b diff cap | 269 | **6** | 0 | all marginal: 528, 533, 569, 579 lines — the cap is noise, and pr-prep already checks size |
| 1c file scope | 255 | **14** | 0 | **loop-only by data dependency** — needs a declared `files_touched` |
| 1d critical files | 255 | **0** | 0 | **never fired. Not once in the loop's entire history.** |
| 1e tests vs. baseline | 247 | **8** | 0 | 8 real catches (2.3%) |
| 1f shellcheck | 35 | **17** | 195 | **5 of 17 were `scripts/self-improvement.sh` itself** and 3 were `health-check.sh` — i.e. ~half the catches exist *because the loop exists*. Skipped 79% of the time. Already covered repo-wide by health-check check 6 |
| 1g self-eval | 98 | **41** | 91 | the largest rejecter by far — **every single one is "N Weak automated scores" on a markdown workflow or skill**, i.e. the exact output class being retired |

**Read against the extraction criterion — a nonzero reject rate on a class nothing else catches — no gate
earns extraction.** 1d never fired. 1a and 1c are loop-shaped by threat model and data dependency. 1b and
1f are duplicated (and 1f's largest single catch class is the loop's own file). 1g's 41 catches are all
prose-quality checks on the output the retirement is aimed at. That leaves 1e.

**And 1e's origin story is batch-shaped.** Commit `8430f7f` records it verbatim: *"On 2026-05-19 a single
regression (commit `5f7140d` deleted bug-diagnosis.md but left it referenced in `pivot-consistency.bats`)
made the whole suite red, and all 14 tasks across 3 rounds were rejected for a failure none of them
caused."* That confirms the brief's claim — but it also characterises it: the property earns its keep when
**14 branches are validated against one baseline nobody is watching.** With one branch and a human who
notices a red suite in five seconds, and with `workflows/pr-prep.md:332-343` already carrying a richer
three-class triage (caused-by-branch / pre-existing / flaky) *with an explicit procedure for
distinguishing them*, the residual value is small. Note also that `guides/validation-gates.md`'s Gate 1e
section does not mention the baseline at all — the guide has already drifted from the code it documents.

**Constraint revision (this is the resolution of the escalated caveat 3): H3 is demoted from hard to
soft.** Step 2 made "the test-baseline isolation property must survive" a hard constraint on the brief's
framing that it was the most expensively-learned property in the surface. The measurement shows the
property is loop-shaped and partially duplicated. It remains a *soft* preference — S5, prefer to retain it
if cheap — and `[1]`'s ✗ no longer costs it a hard constraint.

**The recommendation moved twice**: `[2]` → `[16]` on Move 1, then `[16]` → `[1]` here. Both moves went the
same direction — toward less surviving surface — which is the opposite of a manufactured middle.

### 4.3 Tradeoff matrix (post-stress-test, post-measurement)

Hard constraints are now H1, H2, H4, H5, H6, H7 (6); H3 is soft (S5).

| Approach | Effort | Risk | Core problem coverage | Key downside |
|----------|--------|------|----------------------|--------------|
| **[1] Retire entirely** | 5–9h, terminal | low | **6/6 hard** (S5 forfeited) | Forfeits the baseline property outright; the doc sweep and the three couplings found in Move 5 are real, manual work |
| [16] Retire with a carve-out | 6–10h, terminal | low | 6/6 hard + S5 | Buys a property the measurement says is loop-shaped; 25 lines and 11 tests that may never fire (mitig.) |
| [2] Extract the gates | 10–14h, terminal | med-high | 5/6 hard (~ H1) | 7 of 8 gates fail the extraction criterion on measured data; ships a regression against decisions 030/031; cannot pass its own Gates 1b/1d |
| [8] Retarget, don't retire | 6–10h + unbounded carry | med | 4/6 hard | Changes what the loop produces, not whether it is run; pulls 4,268 un-clean lines into its own Gate 1f |
| [4] Keep and resume | 2–4h + unbounded carry | high | 4/6 hard | Its stated diagnosis (a state bug, E12) is real but is not the failure; E13 is |
| ~~[3] Gates + prose driver~~ | ~~13–18h~~ | ~~high~~ | — | **Pruned by Move 2** — 104 fix commits / 0 FP entries |

### 4.4 Falsifiable hypotheses

- **[1]** — If we retire entirely, we expect that by 2026-10-17 no session has needed any part of the loop,
  `scripts/run-tests.sh --all` and `scripts/health-check.sh` both still pass, and the live doc sites grep
  clean. **Counter-evidence:** any session reconstructing part of the driver or the gates from `git show`;
  or any branch wrongly blocked / wrongly waved through because a pre-existing test failure was
  mis-attributed.
- **[16]** — as `[1]`, plus: ≥1 session consults the new-vs-baseline output while working against a dirty
  suite. **Counter-evidence:** the baseline output is never consulted in 30 days, making the carve-out the
  same unexercised upkeep in miniature.
- **[2]** — If we build `si-gates.sh`, we expect ≥3 recorded invocations within 30 days and ≥1 branch
  caught by a gate nothing else would have caught. **Counter-evidence:** fewer than 3 invocations (the
  FP-library outcome), or every catch being one health-check or `/code-review` already makes — which the
  §4.2 measurement predicts for 7 of the 8 gates.
- **[8]** — If we retarget at `scripts/`, we expect ≥1 round run within 30 days and ≥1 merged task attested
  by a mechanical gate rather than a self-report. **Counter-evidence:** zero rounds (the 90-day base rate),
  or the first round blocked by shellcheck on the loop's own lines — E7 and the five `self-improvement.sh`
  shellcheck rejections in §4.2 are this having already happened six times.
- **[4]** — If we fix the defects and resume, we expect ≥2 rounds and ≥10 of the 50 open questions answered
  within 30 days. **Counter-evidence:** zero rounds, or rounds run with the backlog still growing — which
  is what the last three months already measured.

### 4.5 Decision presentation block

```
┌─ DECISION: What should become of scripts/self-improvement.sh and its 4,268 lines? ─┐
│ 5 candidates survived step-3 pruning (+1 entered by the stress test, −1 pruned)     │
│ scored on the step-4 axes, recalibrated after the gate-rejection measurement        │
└─────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                 effort          risk       coverage       key downside
  ───  ─────────────────────   ────────────   ──────────  ────────────  ───────────────────────────
    1 ★ Retire entirely          ● 5–9h         ● low       ● 6/6 hard    ◐ forfeits the baseline
                                                                             property outright
   16   Retire with carve-out    ● 6–10h        ● low       ● 6/6 hard    ◐ buys a loop-shaped
                                                                             property (mitig.)
    2   Extract the gates        ◐ 10–14h       ○ med-high  ◐ 5/6 hard    ○ 7 of 8 gates fail the
                                                                             measured criterion
    8   Retarget, don't retire   ○ 6–10h+carry  ◐ med       ○ 4/6 hard    ○ changes output, not
                                                                             whether it is run
    4   Keep and resume          ○ 2–4h+carry   ○ high      ○ 4/6 hard    ○ diagnosis is not the
                                                                             failure
```

```
╭─ [1] Retire entirely   ★ recommended ────────────────────────────────────╮
│ effort    5–9h (doc sweep 4–7h + the 3 couplings Move 5 found)   risk  low│
│ coverage  6/6 hard · 3/5 soft (S5 knowingly forfeited)                    │
│ hypothesis  "If chosen, by 2026-10-17 no session has needed any part of   │
│             the loop, run-tests.sh --all and health-check.sh pass, and    │
│             the live doc sites grep clean; counter-evidence = any session │
│             reconstructing the driver or gates from git show, or any      │
│             branch wrongly blocked or waved through on a mis-attributed   │
│             pre-existing test failure."                                   │
│ stress-tests applied                                                      │
│   · Boring alternative → cut [2] from 8 gates to 1 property; entered [16] │
│   · Revealed preferences → 104 fix commits / 0 FP entries; pruned [3] and │
│     revised [2]'s H1 from ✓ to ~                                          │
│   · Failure-driven (what-if) → [2] ships a regression vs decisions        │
│     030/031 and cannot pass its own Gates 1b/1d; surfaced 3 couplings     │
│   · Measurement (§4.2) → no gate earns extraction on 343 validations;     │
│     demoted H3 to soft and moved the pick from [16] to [1]                │
│ key downside  The baseline property is forfeited. Mitigated by being      │
│               restorable in ~1 hour from git (= [16]) and by pr-prep's    │
│               existing 3-class triage at :332-343 (Stress-test            │
│               mitigations, step 5)                                        │
╰───────────────────────────────────────────────────────────────────────────╯
```

```
▶ recommend [1] Retire entirely · confidence 75% · runner-up [16], axis = does the baseline property have a non-batch use?
```

Expand any other candidate's card by naming its `#`; the grid above is the index.

### 4.6 Decision — Path C (non-interactive)

This DD ran in a non-interactive sub-agent with no human at the keyboard, and the leading candidate sits at
75% — below Path A's >80% bar. Per the workflow, **no `AskUserQuestion` was issued**; the static block above
is the decision surface, and the unresolved axis is handed to the user asynchronously via the
`## Round claim` subsection in step 5.

**Chosen approach: `[1]` Retire entirely.** Delete `scripts/self-improvement.sh`, the three
`scripts/lib/si-*.sh` modules and the SI-owned bats suites; handle the three couplings Move 5 found
(`hermeticity-lint.bats` anchors need a *replacement fixture*, `skills/code-review/SKILL.md:573` needs
correcting, `guides/subtraction-checklist.md` + `scripts/skill-usage-report.sh` + health-check check 7 need
retargeting or retiring); sweep the 9 live doc sites (the 9 decision records are historical archives and are
annotated, not rewritten). Land it as three reviewable commits — (a) delete driver + modules, (b) delete and
replace tests, (c) doc sweep — and land the in-flight `archive-working-docs.sh` / `validation-gates.md` edits
separately **first**, so the round-report corpus is not pruned while it is still the evidence base.

**Axis of disagreement: does the test-baseline property have a non-batch use?** `[1]` and `[16]` are within
one cell and differ by one hour and 25 lines. The project's stated preference resolves it: real-world value
over by-construction metrics, and *establish the motive — test whether the benefit is real*. The measurement
says the property's demonstrated benefit came from validating 14 unattended branches against one baseline, a
mode retirement removes, and that `pr-prep:332-343` already covers the residual case by judgment. Keeping it
anyway would be preserving the most carefully engineered thing rather than the thing with a demonstrated
catch — which is the failure mode this whole decision is about. **If the user's preference is instead "keep
the cheap insurance", `[16]` is a fully defensible call and the delta is one hour.**

### 4.7 Trigger-bound decision rule

The variant is engaged: the evidence that settles whether retirement was right arrives only *after* the
deletion commit.

| Branch | Trigger condition | Action |
|--------|------------------|--------|
| **Continue** | By 2026-10-17: zero sessions have wanted the loop or the gates back; `run-tests.sh --all` and `health-check.sh` pass; the 9 live doc sites grep clean | Retirement stands; write the `docs/decisions/037` record |
| **Revisit** | Exactly one branch is wrongly blocked or wrongly waved through on a mis-attributed pre-existing test failure, **or** one session reconstructs a gate from `git show` | Take the **`[16]`** carve-out: restore `tap_failing_names` / `tap_new_failures` and their 11 tests into `scripts/run-tests.sh`. ~1 hour, no re-litigation |
| **Reverse** | Two or more sessions in 30 days want unattended multi-branch generation, **or** a concrete task arrives that genuinely needs parallel autonomous rounds | `git revert` the deletion and adopt **`[8]` Retarget, don't retire** — the loop returns pointed at `scripts/` and `test/`, never at `workflows/` |

Both fallbacks are pre-named so that a reversal under pressure does not default to `[4]`, the version whose
output shape is the documented problem.

---

## 5. Decision record (drafted, not written)

Per the task brief, **no file was written to `docs/decisions/` and nothing was committed.** When ratified,
the record is `docs/decisions/037-retire-the-self-improvement-loop.md`, superseding the operative halves of
005, 010 and 020 (which stay as historical records) and carrying: Context (E1–E14 plus §4.2), Options
considered (the 15 candidates), Decision and rationale, Pruned candidates, Stress-test mitigations,
Consequences, and Revisit triggers (§4.7's three branches, already thresholded).

*See alternatives considered →* **Pruned candidates and why**, immediately below.

### Pruned candidates and why

*How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can
grep this section to avoid regenerating already-pruned approaches.*

`[0 keep, don't run]: ✗ on H1, H2 and H5 at once — it is the present state, and three months of upkeep for zero invocations is the thing being decided.` `[3 gates + prose driver]: survived step 3, discarded by the step-4 Revealed-preferences move — 104 fix commits and 0 failure-pattern entries against an explicit "do not skip this step" make a prose driver the most likely form of false closure.` `[5 archive it]: dominated by [1] — same property forfeit, worse on S2, and ~ on H7.` `[6 keep code, drop tests]: ⚠ on H2 and H3 — 4,268 lines whose only correctness evidence is the tests, minus the tests.` `[7 outcome ledger first]: ✗ on H1/H2 and ~ on H6 — new unexercised infrastructure to justify existing unexercised infrastructure, rebuilding the class of thing decision 010 deleted for producing misleading signal. Served as the ideal-if-free space-widener; its outcome-observable idea survives in every step-4 hypothesis and in the §4.2 measurement.` `[9 scheduled prompt]: dominated by [1] — it is [1] plus a calendar entry, and calendar discipline is the mechanism E13 falsified.` `[10 worktree harness only] / [11 gates + worktree harness]: ✗ on H1/H2 for the worktree half — CLAUDE.md row 2 already gets worktree isolation from the Agent tool's own isolation parameter, so a bash equivalent has no invocation site by construction; [11] collapses into [2] and S1 is met with no code.` `[12 evaluation half only]: ⚠ on H5 — preserves the surface that accrued 0 incident-journal entries and 50 unanswered questions while deleting its only producer.` `[13 repoint at another repo]: ✗ on H4/H6 — no consumer repo in this tree; cross-repo and benchmark work goes to the SWRBench fork.` `[14 probe first]: absorbed, not discarded — it is evidence-gathering, and it survives as §4.7's Revisit path.` `[2 extract the gates]: the brief's leading candidate, discarded on measurement — across 343 archived validations, Gate 1d never fired at all, 1a/1c are loop-shaped by threat model and data dependency, 1b and 1f duplicate pr-prep and health-check check 6 (and 8 of 1f's 17 catches were on the SI infrastructure itself), and all 41 of 1g's catches are prose-quality scores on the output class being retired; it additionally ships a regression against decisions 030/031 (Gate 1h's binary red rule vs the measured T-tier 0R+0A-with-ack standard) and cannot pass its own Gates 1b/1d.` `[16 retire with a carve-out]: the runner-up, losing by one hour and 25 lines; the pre-named Revisit fallback in §4.7 and a fully defensible call if the preference is cheap insurance over minimal surface.` `[4 keep and resume]: bottom on all three calibrated axes; its stated diagnosis (a state-management bug) is real (E12) but is not the failure — E13 is.` `[8 retarget, don't retire]: the strongest keep-the-loop candidate and the pre-named Reverse fallback; ○ on H1 because narrowing scope changes what the loop does when run, not whether it is run, and it pulls the loop's own 4,268 un-clean lines into Gate 1f's blast radius — a failure with six recorded instances.` `Prior pruning grep: no matches found for [loop, self-improvement, gate, worktree, orchestration, autonomy, round] — decisions 005, 010 and 020 predate the Pruned-candidates convention. Decision 010's "What was removed" list is carried forward in substance: no candidate re-proposes autonomous in-loop hypothesis evaluation.`

### Stress-test mitigations

- *How to read:* **Boring alternative** mitigation — tracing all eight gates found six duplicate or
  loop-only, which replaced `[2]`'s 8-gate `si-gates.sh` (10–14h) with `[16]`'s 25-line relocation (~1h)
  and moved the recommendation from `[2]` to `[16]`.
- *How to read:* **Revealed preferences** mitigation — the 104-fix-commits / 0-FP-entries measurement
  revised `[3]`'s risk from ◐ to ○ and pruned it, revised `[2]`'s H1 from ✓ to ~, and established the
  standing requirement that any surviving mechanism ride a command sessions already run.
- *How to read:* **Failure-driven / what-if** mitigation — surfaced that `[2]` re-blocks the marginal red
  classes decision 031 spent 612k tokens demoting, and that the migration diff fails its own Gates 1b and
  1d; also surfaced the three couplings (`hermeticity-lint.bats` anchors, `skills/code-review/SKILL.md:573`,
  the subtraction-checklist cluster) now folded into `[1]`'s scope and effort estimate.
- *How to read:* **Measurement** mitigation — the 343-validation gate-rejection query demoted H3 from hard
  to soft and moved the recommendation from `[16]` to `[1]`. It also resolved the matrix pass's escalated
  caveat 3 by answering it with data rather than calibration judgment.
- *How to read:* **Invert the thesis** produced no mitigation — it conceded `[8]`'s diagnosis about the
  loop's output and is recorded instead as the strongest argument against the recommendation.

### Consequences

**Easier:** the repo stops paying for 4,268 lines and roughly 197 tests nothing runs; `scripts/` drops from
16 entries to 12; `guides/validation-gates.md`, `guides/subtraction-checklist.md` and
`guides/cross-project-setup.md` stop describing a mechanism that does not run (and `validation-gates.md`'s
already-drifted Gate 1e section stops being wrong); health-check check 10 (si-functions.sh orphan detection)
and Gate 1d's circular self-protection both become moot; and the repo's evaluation stance stops being
contradicted by its own largest artifact.

**Harder:** there is no unattended multi-branch generation capability — restoring it is a `git revert` plus
the re-familiarisation cost of a 1,819-line script. The `/away`-mode autonomy vocabulary in CLAUDE.md
(MAX_ROUNDS, convergence, round claims) loses its only mechanical consumer and becomes aspirational prose —
this should be stated in the record rather than left silent. `workflows/divergent-design.md`'s Path C and
`patterns/requesting-user-input.md:93` lose their motivating example and need rewording to "any
non-interactive run" rather than deletion (Path C remains correct — it governs `/away` batches and
sub-agent runs like this one). Decision 012's hypothesis grammar loses its only consumer and should be
annotated historical rather than deleted, since `## Round claim` is still referenced by DD step 5. And the
`hermeticity-lint.bats` anchors need a replacement fixture, or decisions 014/017's indirect-closure
detection loses its only regression coverage.

### Revisit triggers

*How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision.
Future readers can grep this section when their context changes.*

`if any branch is wrongly blocked or waved through on a mis-attributed pre-existing test failure → take the [16] carve-out (§4.7 Revisit).` `if ≥2 sessions in 30 days want unattended multi-branch generation → git revert and adopt [8] (§4.7 Reverse).` `if a consumer repo ever lives in this tree and produces code rather than prose → [13] revives.` `if a mechanical forcing function appears (a git hook, or CI) → [2]'s H1 objection dissolves and gate extraction is worth re-deriving, though §4.2 says only 1e is a candidate.` `if scripts/ or test/ ever exceed ~10k lines such that a human can no longer eyeball a dirty suite → S5 becomes hard again.`

### Round claim

- `evaluator:` user
- `requires:` the deletion commits have landed on `main`; ≥30 days elapsed; `scripts/run-tests.sh --all` has
  been run at least once against a suite with ≥1 pre-existing failure
- `evaluation_window:` 30 days from the deletion commit
- **hypothesis (framed as the predicted failure, per decision 012 pillar 2):** *The most likely failure of
  retiring entirely is not that the loop is missed — it is that the **doc sweep is done badly**, leaving
  `guides/validation-gates.md`, `guides/subtraction-checklist.md` and the `hermeticity-lint.bats` anchors
  describing or depending on a mechanism that no longer exists. That failure is silent: nothing invokes those
  artifacts, so nothing fails, and the repo ends up with orphaned process docs instead of orphaned code —
  the same disease with a smaller footprint. The counter-evidence is a single grep at day 30; if it finds a
  stale live reference, the sweep, not the deletion, was the wrong-sized piece of work.*

---

## Console trail

```
◇ step 1 diverge    15 candidates → docs/working/dd-self-improvement-loop-future.md
                      0 keep-dont-run  1 retire  2 extract-gates  3 gates+prose  4 keep-resume
                      5 archive  6 drop-tests  7 ledger-first  8 retarget  9 scheduled-prompt
                      10 worktree-only  11 gates+worktree  12 eval-half  13 other-repo  14 probe
◇ step 2 diagnose    11 constraints (7 hard · 4 soft) → docs/working/dd-self-improvement-loop-future.md
                      (H3 demoted hard → soft in step 4 on measured evidence; final 6 hard · 5 soft)
◇ step 3 match       5 of 15 survived → [2] [1] [4] [8] [3]
◇ step 4 decide      +[16] entered by stress test, −[3] pruned; measurement moved the pick
                      [2] → [16] → [1] · recommend [1] at 75%, runner-up [16]
```
