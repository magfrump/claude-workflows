# Performance Review — `feat/crb-direction1-harness`

**Commit:** 529ecd2
**Scope:** `git diff main...HEAD` — 7 files, +1209 lines, all newly added
**Date:** 2026-08-18
**Based on:** Stage-1 code-fact-check (k=3, merged, most-severe-wins), supplied by the orchestrator

## Calibration note

This is batch research tooling: a materializer, a container-per-instance sweep runner, a JSON
injector, and a re-ranker. None of it sits in a request path. CPU time in the Python is
irrelevant next to what dominates, so I am deliberately **not** flagging the micro-inefficiencies
that a generic perf pass would list first (`dir_mb()`'s `os.walk`, the per-iteration manifest
rewrite, re-serializing the full `benchmark_data.json`). Those are named once, together, at the
bottom as explicit non-findings so a later reviewer does not re-litigate them.

The resources that actually scale here are **money** (a 50-PR sweep is projected at $500–2000),
**wall-clock** (50 sequential containerised agent runs), and **disk** (~6.7 GB of clones plus
stream transcripts). Every finding below is about one of those, and the highest-severity ones are
all the same shape: *paid work that is not gated, or paid work whose failure is recorded as
success.*

## Data Flow and Hot Paths

Four stages, run manually and in order:

1. `scripts/crb-materialize.py` — clones 5 or 50 GitHub forks at `--depth=50`, scrubs refs, runs
   two integrity guards, appends to `runs/review-arms/crb/instances.json`. Cold path, network- and
   disk-bound. Measured: 670 MB for the 5-PR pilot (33–195 MB per clone, `instances.json`).
2. `runs/review-arms/crb-pipeline/run-host.sh` — **this is the only stage that costs money.** A
   `for` loop over instances; each iteration is one `docker run` of headless Claude Code executing
   `/code-review main` against a read-write clone, capped at `--max-budget-usd $BUDGET`
   (default 25.00). Cold path by the skill's taxonomy, but it is the whole budget.
3. `scripts/crb-pipeline-to-benchmark.py` — loads the full benchmark (2449 (PR, tool) pairs),
   injects our tool's comments, writes a work dir, seeds the judge dir from checked-in results.
   $0 itself, but **it determines the cost of stage 4** — the seeding is what confines paid judging
   to our arm.
4. Benchmark steps 2/2.5/3 + `scripts/crb-subset-leaderboard.py` — ~$1.5 (5 PRs) to ~$17 (50) when
   `--tool` is passed; ~50× that if seeding or `--tool` is missed.

Call frequency is 1 per instance for everything; N is 5 (pilot) or 50 (full). Nothing here runs
per-request, so severity is driven by dollars and hours, not by latency.

## Findings

#### No sweep-level budget ceiling and no early-abort — the only cap is per-instance

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:61`, `:134`, `:166`
**Move:** What's the size of N? / hidden multiplication (cost, not CPU)
**Classification:** Macro (unbounded aggregate spend) / Cold path (unattended batch sweep — but the sweep *is* the budget)
**Confidence:** High
**Baseline:** $14.60/instance on the canon ledger and ~$19–44/instance re-derived on the E8 Fable
sweep, per `docs/working/crb-direction1-setup.md:156`; projected $500–2000 for all 50
(`:158`)
**Legibility-target:** the operator launching an unattended sweep — they must be able to see the
running total and a hard stop in the script itself, not only in `run-meta.json` afterwards

**Evidence:**

```
BUDGET="${BUDGET:-25.00}"
```
```
for id in "${INSTANCES[@]}"; do
```
```
      --max-budget-usd "$BUDGET" \
```

`--max-budget-usd` bounds one instance. The loop has no aggregate counter, no `--max-total-usd`,
and no check of accumulated `total_cost_usd` between iterations. `run-meta.json` sums cost only
*after* the last instance exits (`:217-236`), which is exactly the moment the number stops being
actionable. With the default settings, `run-host.sh` with no arguments over a 50-instance manifest
can spend up to 50 × $25 = $1250 unattended before anyone sees a total, and the script is
explicitly documented for unattended host use.

**Recommendation:** Accumulate `total_cost_usd` from each harvested `result.json` inside the loop
and `exit 1` when the running total crosses a `MAX_TOTAL_USD` (default it to something like 1.5×
the pilot-derived projection). Print the running total after every cell so a watching operator can
kill the sweep on the third cell rather than the fiftieth.

---

#### An errored or budget-exhausted instance is recorded as complete and permanently skipped on resume

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:138-144`, `:167-168`, `:186-191`
**Move:** Find the work that moved to the wrong place (failure detection moved after payment)
**Classification:** Macro (systematic loss of paid work across the sweep) / Cold path (batch)
**Confidence:** Medium-High — the exact `result` payload Claude Code emits on budget exhaustion is
not verifiable here without a paid run, so the severity rests on the skip predicate, which is
verifiable
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** anyone re-invoking `run-host.sh` to resume — "skipping" in the sweep log
must mean "succeeded", not "has turns"

**Evidence:**

```
  if [ -s "$dest/result.json" ] && python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
sys.exit(0 if d.get("num_turns", 0) > 0 else 1)' "$dest/result.json" 2>/dev/null; then
    echo "=== $id — completed result exists, skipping (delete to re-run)"
```
```
    > "$dest/transcript.jsonl" 2> "$dest/stderr.log" || {
      echo "$id: claude exited non-zero — see $dest/stderr.log" >&2; }
```

The resume predicate is `num_turns > 0` — presence of turns, not success. A cell that hit
`--max-budget-usd` mid-review, or errored after some turns, still emits a `result` event with
`num_turns > 0`; the harvester writes it (`:190`), and every subsequent invocation of the script
treats that cell as done. The non-zero exit from `docker run` is swallowed with a log line
(`:167-168`), and `is_error` / `subtype` are never inspected anywhere in the file. The economics
are the point: the expensive thing (the agent run) has already been paid for, and the cheap thing
(noticing it failed) is skipped, so the money is spent *and* the cell is locked out of retry
without a manual `rm`.

**Recommendation:** Tighten the skip predicate to also require `is_error` falsy and a non-empty
`result` string, and have the harvester rename a failed cell's `result.json` to
`result.failed.json` so resume retries it. Separately, surface `subtype` in the per-cell summary
line at `:210-212` so a budget-exhausted cell is visible in the sweep log.

---

#### Judge-dir seeding fails open: a missing or partial seed silently multiplies judge cost ~50×

**Severity:** High
**Location:** `scripts/crb-pipeline-to-benchmark.py:249-266`
**Move:** Question the cache (the seeded `evaluations.json` *is* a cache of paid judge work)
**Classification:** Macro (cost scales with the 49 unrelated tools) / Cold path (one-shot setup)
**Confidence:** High
**Baseline:** ~$13–22 for the 50-PR judge pass on our arm alone, per
`docs/working/crb-direction1-setup.md:159`; the script's own `--no-seed` help puts the unseeded
case at "~50x the judge cost" (`:186`)
**Legibility-target:** the person running stage 4 — the difference between a $17 and an $850 judge
pass must be visible in the script's exit status, not in a stderr line above the success output

**Evidence:**

```
    src = BENCH / "results" / sanitize_model(args.judge)
```
```
        for name in ("candidates.json", "evaluations.json"):
            s = src / name
            if s.exists() and not (jdir / name).exists():
                shutil.copy2(s, jdir / name)
```
```
        print(f"  !! no checked-in results for judge {args.judge} — "
              f"nothing to seed; the judge run will score every tool.", file=sys.stderr)
```

Seeding is the single mechanism that keeps stage 4 at ~$17 instead of ~$850. Three ways it
degrades, all of them non-fatal: (a) `--judge` names a model with no checked-in dir, which prints a
stderr warning and continues, writing a work dir that looks complete; (b) only one of the two files
exists in `src`, so `candidates.json` is seeded and `evaluations.json` is not — the per-file `if`
has no coupling between them, and step 3 then re-judges everything; (c) `--no-seed` is passed
deliberately. In every case the script exits 0 and prints its normal "Next:" instructions, and the
cost only becomes visible on the API bill. The seed is the expensive-work cache; a cache miss here
is not a slow path, it is a 50× paid path.

**Recommendation:** Make an unseeded work dir an error unless `--no-seed` was passed explicitly
(`sys.exit`, not `print(..., file=sys.stderr)`), and treat "seeded one file but not the other" as
the same failure. Also stop emitting `RUN.md` when the dir is unseeded, or emit a version whose
first line is the warning — right now the runbook it writes (`:272-295`) reads identically in the
cheap and the expensive case.

---

#### `--tool` confinement is enforced by documentation only, on both the runbook and the doc path

**Severity:** Medium
**Location:** `scripts/crb-pipeline-to-benchmark.py:268-295`
**Move:** Find the contention point / failure economics (guard exists but is not mechanical)
**Classification:** Macro (cost scales with all 50 tools) / Cold path
**Confidence:** High
**Baseline:** Stage-1 fact-check finding 6 — omitting `--tool` at step 2.5 costs ~2233 unnecessary
paid judge calls; the code comment's own "~52 (PR, tool) pairs" figure is Stage-1-Incorrect (the
real count is 50)
**Legibility-target:** the operator copying commands out of `RUN.md` — correctness of the paid step
should not depend on transcription

**Evidence:**

```
    # The work dir carries its own runbook: the --tool flag is not optional
    # decoration. Without it step 2 re-extracts the ~52 (PR, tool) pairs the
```
```
# --tool IS REQUIRED on all three: it confines paid work to our arm and leaves
# the other tools' checked-in scores untouched.
python -m code_review_benchmark.step2_extract_comments   --tool {args.tool_name}
```

The script correctly identifies the most expensive foot-gun in the whole chain and then addresses
it with a comment and a shell snippet the operator is expected to copy correctly. This is the one
place in the branch where a few lines of generated shell would convert a documented $850 risk into
a mechanical one. Note also that the runbook's stated rationale is partly wrong per Stage 1 — the
uncapped cost lives at step 2.5, which the comment does not name — so an operator reasoning from
the comment could conclude `--tool` matters less than it does.

**Recommendation:** Write an executable `judge.sh` into the out dir alongside `RUN.md`, with
`--tool "$TOOL"` baked into all three invocations and `set -euo pipefail`, and have `RUN.md` tell
the operator to run *that* rather than to retype the commands. Fix the comment to name step 2.5 as
the unguarded one.

---

#### The sweep is strictly sequential though instances are fully independent

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:134-214`
**Move:** Count the hidden multiplications (wall-clock × N)
**Classification:** Macro (total time is Θ(N × per-instance duration) with no overlap) / Cold path
**Confidence:** High that it is sequential; Medium that parallelism is safe (see caveats)
**Baseline:** no baseline available — flagged as speculative. No per-instance duration has been
measured; `run-host.sh` records `t1-t0` per cell (`:154`, `:169`, `:210-212`), so the pilot will
produce this number.
**Legibility-target:** whoever schedules the 50-PR sweep — they need the pilot's per-cell duration
in hand to decide whether serial execution is a multi-day commitment

**Evidence:**

```
for id in "${INSTANCES[@]}"; do
```
```
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
```

Each iteration is a full containerised agent review of a 1–106-file diff in a 33–195 MB repo. The
loop body already isolates everything that would collide: a fresh `mktemp -d` payload copy per
instance, a per-instance `$dest`, a per-instance clone mount, `docker run --rm`. The only shared
mutable resources are the `cc-review-npm-cache` volume and the append-only `$OUT` tree. So the
serialization looks like an unexamined default rather than a constraint — the 50-PR sweep's
wall-clock is 50 × (whatever one review takes), and since this is an unattended host run, that
elapsed time is also the window during which finding #1's uncapped spend accumulates unobserved.

Two real caveats before parallelising: concurrent `npx -y` installs would race on the shared npm
cache volume (pre-warm it in the existing `chown` container at `:100-101`, which already runs once
as root), and concurrency multiplies the API rate-limit and per-minute spend rate.

**Recommendation:** Measure one instance first, then, if it is slow, factor the loop body into a
function and drive it with a bounded `xargs -P` (start at 2–4). Pre-install the pinned CLI version
into the npm cache volume in the existing root container so parallel workers hit a warm cache.

---

#### A failed materialization leaves a full-size clone behind that masks itself on the next run

**Severity:** Medium
**Location:** `scripts/crb-materialize.py:152-157`, `:258-263`, `:128-136`
**Move:** Trace the memory lifecycle (disk lifecycle) + failure economics
**Classification:** Macro (leaked bytes scale with the number of failed instances) / Cold path
**Confidence:** High
**Baseline:** 670 MB measured across the 5-PR pilot, 33–195 MB per clone
(`runs/review-arms/crb/instances.json`); `--all` measured at ~6.7 GB per Stage-1 finding 2
**Legibility-target:** whoever re-runs materialization after a partial failure — a plain re-run
should either retry or say clearly that `--force` is required

**Evidence:**

```
    if dst.exists():
        if not force:
            print(f"{slug}: exists, skipping (use --force to rebuild)")
            return None
```
```
        except Exception as e:  # keep going; one bad fork shouldn't stop a sweep
            print(f"{slug}: FAILED — {e}", file=sys.stderr)
            failures.append(slug)
            continue
```

`materialize()` clones first and raises later — the guards at `:186-196` and `resolve_base()`'s
"could not find merge-base" at `:135-136` both fire *after* the full clone plus, in the
`resolve_base` case, after two deepening fetches. The `except` handler records the slug and moves
on but never removes `dst`. On the next invocation the `dst.exists()` check short-circuits with
"exists, skipping" and returns `None`, so the broken clone is neither rebuilt nor added to the
manifest — it just occupies 33–195 MB and silently stays absent from every downstream stage. Over
`--all` with a handful of odd forks this is both a disk leak and a confusing resume story.

Worth noting on the same lines: the deepening ladder at `:128` fetches `depth*4` then `depth*20`
extra commits — on grafana/keycloak-scale repos the third attempt pulls ~1000 commits of history
onto an already-125 MB clone, so the failure path is the *expensive* path. That is acceptable
(it is bounded and network-only), but it makes the leaked directory correspondingly larger.

**Recommendation:** Wrap `materialize()`'s post-clone work so any exception `shutil.rmtree(dst)`
before re-raising, leaving the filesystem in a state where a plain re-run retries the instance.
Failing that, print the failed slugs with the `--force --slug ...` command needed to retry them.

---

#### Preflight covers the cheap failure modes but there is no first-instance canary gate

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:103-132`
**Move:** Find the work that moved to the wrong place (validation before payment vs. after)
**Classification:** Macro (a systematically-broken sweep costs the full budget) / Cold path
**Confidence:** High
**Baseline:** $500–2000 for a 50-PR sweep (`docs/working/crb-direction1-setup.md:158`)
**Legibility-target:** the sweep operator — the doc's "run one instance first" instruction should
be enforced by the script rather than depend on having read section 2 of the runbook

**Evidence:**

```
# Two failure modes cost a whole sweep if unchecked:
#  (a) bad credential — the CLI exits 0 with result "Not logged in" (E7 note);
#  (b) payload mounted but skills not registered — the run then silently
#      measures Claude Code's built-in review, i.e. the E5 arm under a wrong
```
```
if "code-review" not in r:
    sys.exit("  payload skills NOT registered — the run would measure the "
```

The preflight design is right and I want to be clear that it is the strongest cost control in the
branch — it catches the two failure modes that would invalidate an entire sweep, and it does so
for the price of one short model call. What it cannot catch is the failure mode the setup doc
itself calls the highest risk: that the pipeline runs, registers its skills, costs $20, and
produces no rubric artifact — because the preflight container has no repo mounted and never
exercises `/code-review`. The doc's answer is a human instruction ("Run one instance first …
`run-host.sh keycloak-PR36880`", `docs/working/crb-direction1-setup.md:200-203`), which the script
does not enforce; invoking `run-host.sh` with no arguments goes straight to all 50.

Related and cheap to fix: the preflight's `"log in" in r.lower()` test does not match the
documented `"Not logged in"` string (Stage-1 finding 4) — `"Not logged in".lower()` contains
`"logged in"`, not `"log in"` — so auth detection currently rests on the `num_turns < 1` branch
alone.

**Recommendation:** After the first instance completes, assert it produced a non-empty `review.md`
and at least one harvested artifact, and abort the sweep if not — the cheapest possible circuit
breaker, and it composes with finding #1's running total. Fix the auth substring to `"logged in"`
while touching this block.

---

#### `git clean -qfd` without `-x` leaves ignored build artifacts to accumulate in the clones

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:200-201`
**Move:** Trace the memory lifecycle (disk)
**Classification:** Micro (bounded per instance) / Cold path — but the bytes persist across sweeps
**Confidence:** Medium — depends on whether an agent actually installs or builds, which is possible
under `--dangerously-skip-permissions`
**Baseline:** 670 MB of clones measured for the pilot (`runs/review-arms/crb/instances.json`);
a `node_modules` in a repo the size of `cal_com` is routinely several hundred MB
**Legibility-target:** anyone auditing `external/crb-eval/` disk usage against the manifest's
`clone_mb` figures — the two should not silently diverge across sweeps

**Evidence:**

```
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfd 2>/dev/null || true
```

Stage 1 already flagged the `-x` omission. The performance consequence is that anything the
reviewing agent installs or builds is gitignored, therefore neither harvested (the harvest at
`:194-199` uses `--untracked-files=all`, which excludes ignored paths) nor cleaned — it just stays
in `external/crb-eval/<slug>/` and inflates the on-disk footprint monotonically across re-runs.
The clones are already the largest thing this branch puts on disk.

**Recommendation:** Use `git clean -qfdx` and note in the comment that the clone is disposable
(`crb-materialize.py --force --slug <id>` rebuilds it). If ignored artifacts are ever wanted for
debugging, harvest them explicitly before cleaning rather than by leaving them behind.

---

#### `--output-format stream-json --verbose` writes an unbounded transcript per instance

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:164`, `:167`
**Move:** Identify the serialization tax
**Classification:** Micro (per-instance constant) / Cold path
**Confidence:** Medium — transcript size for a `/code-review` run of a 106-file diff has not been
measured
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** whoever commits the sweep's outputs — transcript size should appear in the
per-cell summary before 50 of them land in a tracked directory

**Evidence:**

```
      --output-format stream-json --verbose \
```
```
    > "$dest/transcript.jsonl" 2> "$dest/stderr.log" || {
```

Verbose stream-json captures every tool call and result, including file reads, for an orchestrated
multi-critic review of diffs up to 106 files. Fifty of those accumulate in `runs/`, which is a
tracked directory, next to ~6.7 GB of gitignored clones. The transcripts are genuinely valuable
provenance and I am not suggesting dropping them — only that nothing in the harness reports or
bounds their size, and `runs/` being tracked makes that worth knowing before the full sweep.

**Recommendation:** Report transcript bytes in the per-cell summary at `:210-212` alongside cost
and duration, and confirm `runs/review-arms/crb-pipeline/*/transcript.jsonl` is gitignored (or
gzip it in the harvest step) before running all 50.

---

#### `npx -y @anthropic-ai/claude-code@$CC_VERSION` re-resolves and installs the CLI in every container

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:100-101`, `:161`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (tens of seconds per instance) / Cold path
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** a future reader deciding whether to parallelise — this is the prerequisite,
not an independent optimization

**Evidence:**

```
docker run --rm -v cc-review-npm-cache:/home/node/.npm node:22 \
  chown -R node:node /home/node/.npm
```
```
    npx -y @anthropic-ai/claude-code@"$CC_VERSION" \
```

The shared npm cache volume already removes the network cost, so what remains is per-container
resolve-and-unpack — negligible against a multi-minute agent run, and I would not change it for a
sequential sweep. It becomes worth doing only as a prerequisite for finding #5's parallelism, where
concurrent installs would race on the same cache volume.

**Recommendation:** None on its own. If parallelising, bake a small image (`FROM node:22` +
`npm i -g @anthropic-ai/claude-code@$CC_VERSION`) or pre-warm the volume in the existing root
container, and reference the pinned version from one place.

---

#### Explicit non-findings: the micro-costs that would be noise here

**Severity:** Informational
**Location:** `scripts/crb-materialize.py:139-148`, `:266`; `scripts/crb-pipeline-to-benchmark.py:196`, `:246`; `scripts/crb-subset-leaderboard.py:54-72`
**Move:** Asymptotic behaviour vs. constant (and deciding the constant does not matter)
**Classification:** Micro / Cold path
**Confidence:** High
**Baseline:** 670 MB across 5 clones measured (`runs/review-arms/crb/instances.json`); benchmark
covers 2449 (PR, tool) pairs across 50 PRs
**Legibility-target:** a later performance reviewer — these are recorded as considered-and-declined
so the same cycles are not spent twice

**Evidence:**

```
def dir_mb(path: Path) -> int:
    total = 0
    for root, _dirs, files in os.walk(path):
```
```
            MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
```

Recording each for the record, with why none is worth changing:

- `dir_mb()` stats every file in a 33–195 MB clone once per instance. It runs immediately after
  `git clone` + `git gc` have touched the same tree, so it is page-cache-warm and costs a fraction
  of a second against a multi-second network clone. Replacing it with `du -sm` would save nothing
  observable.
- The manifest is rewritten in full inside the per-instance loop (`:266`), which is O(N²) bytes —
  N=50 over a ~20 KB file is ~500 KB of total writes. The pattern is deliberate crash-safety: a
  sweep interrupted at instance 40 keeps 40 records. Keep it.
- `crb-pipeline-to-benchmark.py` loads and re-serializes the entire benchmark (`:196`, `:246`).
  It runs once per scoring variant, and the output must be a complete `benchmark_data.json` for the
  benchmark's own steps to read, so streaming or patching would buy nothing and lose the "other 49
  tools preserved verbatim" property that the arm's validity depends on.
- `crb-subset-leaderboard.py` aggregates O(PRs × tools) ≈ 2449 dicts in memory. Trivial.

**Recommendation:** No action. Recorded so a later reviewer does not spend a cycle on them.

## What Looks Good

- **Judge-cost confinement by seeding.** Copying the checked-in `candidates.json` /
  `evaluations.json` so steps 2/3 skip already-judged pairs is the correct design: it turns an
  ~$850 re-judge of 49 tools into ~$17 of work on our arm. Stage 1 verified the mechanism. My
  finding #3 is about it failing open, not about the approach.
- **The preflight exists at all.** Two paid-sweep-invalidating failure modes are checked for the
  price of one short call, before any instance starts, and `DRY_RUN=1` exits before even that
  (`:92-95`) so the payload path can be validated at literally $0. This is the right instinct
  applied at the right point in the pipeline.
- **`git archive` instead of a bind mount** (`:83-88`). Beyond the integrity argument in the
  comment, it means the payload is materialized once and `cp -r`'d per instance from a local temp
  dir rather than re-extracted — the cheap thing is done once and the expensive thing is not done
  at all.
- **Per-instance resume exists.** Even with finding #2's predicate problem, the fact that a
  47-instance sweep interrupted at 40 does not re-pay for the first 40 is the single most important
  cost property in the runner.
- **`--per-repo N` selects most-goldens-first** (`crb-materialize.py:111-122`). Selecting on
  measurable signal per dollar of review is exactly the right optimization target for a pilot, and
  the tie-break on slug keeps it deterministic.
- **Shallow clones with a bounded deepening ladder** rather than full clones — the comment's
  "~1 order of magnitude smaller on disk" framing (`:18-20`) is the correct tradeoff for a corpus
  that is about to be replicated 50 times.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | No sweep-level budget ceiling or early abort | High | `run-host.sh:61,134,166` | High |
| 2 | Errored/budget-exhausted cells recorded as complete, skipped forever | High | `run-host.sh:138-144` | Medium-High |
| 3 | Judge-dir seeding fails open → ~50× judge cost | High | `crb-pipeline-to-benchmark.py:249-266` | High |
| 4 | `--tool` confinement enforced by docs, not mechanically | Medium | `crb-pipeline-to-benchmark.py:268-295` | High |
| 5 | Strictly sequential sweep over independent instances | Medium | `run-host.sh:134-214` | High / Medium |
| 6 | Failed materialization leaks a clone that masks itself | Medium | `crb-materialize.py:152-157` | High |
| 7 | Preflight has no first-instance canary gate | Medium | `run-host.sh:103-132` | High |
| 8 | `git clean -qfd` without `-x` accumulates ignored artifacts | Low | `run-host.sh:200-201` | Medium |
| 9 | Unbounded verbose transcript per instance | Low | `run-host.sh:164,167` | Medium |
| 10 | `npx` install per container | Informational | `run-host.sh:161` | High |
| 11 | Explicit non-findings (micro-costs) | Informational | multiple | High |

## Overall Assessment

The performance posture of this branch is good in the places that were thought about and thin in
one specific place: **the transition from "validated, $0" to "spending, unattended."** Every $0
stage is carefully bounded — dry runs, guards, preflights, seeding, deterministic selection — and
the moment the sweep starts, all the cost controls become per-instance and all the failure handling
becomes advisory (`|| true`, stderr warnings, log lines). That is the pattern behind findings 1, 2,
3 and 7: the expensive operation is well-designed but its aggregate is unmonitored and its failures
are recorded as successes.

None of this is structural. Findings 1, 2 and 7 are perhaps 30 lines of bash inside a loop that
already computes everything they need (`t1-t0`, `result.json`, `total_cost_usd`); finding 3 is
turning two `print(..., stderr)` calls into `sys.exit`; finding 6 is a `try/except` around one
function. I would fix 1, 2, 3 and 7 before any paid sweep, and treat 4, 5 and 6 as follow-ups
informed by the pilot.

Measurement is needed for exactly two things, and the pilot produces both for free: per-instance
wall-clock (settles whether finding 5 is worth acting on) and per-instance cost (settles whether
finding 1's ceiling should be $600 or $2000). Run the single-instance canary the setup doc already
prescribes — `run-host.sh keycloak-PR36880` — before the pilot, since it is the only cheap test of
the branch's own highest-risk unverified assumption.

## Goal-Alignment Note
- Answered: yes — money, wall-clock, disk, and failure economics each covered with located findings
- Out of scope: correctness and security of the harness (Stage 1 and the security critic own those); micro-optimization of the Python, which I recorded as explicit non-findings rather than silently dropping; verifying Claude Code's exact `result` payload on budget exhaustion, which needs a paid run
- Escalate: findings 1, 2, 3 and 7 are pre-sweep blockers by my read — the orchestrator should decide whether the pilot is gated on them, since a sweep launched today can spend up to $1250 with no aggregate cap and silently bank failed cells. Also worth a separate decision: `runs/` is tracked and will receive 50 verbose transcripts.
