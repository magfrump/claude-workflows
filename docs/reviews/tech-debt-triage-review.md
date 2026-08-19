# Tech Debt Triage — CRB direction-1 harness

Commit: 529ecd2
Branch: `feat/crb-direction1-harness` (vs `main`)
Scope: `git diff main...HEAD` — 7 files, +1209, all newly added
Stage: 2 of 3 (advisory — informs but does not block merge)

---

## 0. Framing: what is this code's expected lifetime?

The brief asks me not to assume either "experiment code, so debt is free" or "new code, so
production standards". Here is what the repo's own history says.

**Finding: arms in this repo are single-use as *code*, multi-use as *evidence*.**

Evidence I ran:

1. **Arm directories are built and finished inside one day.** Across the 15 directories under
   `runs/review-arms/`, 13 have an identical first-commit and last-commit date
   (`git log --diff-filter=A` vs `git log -1` per directory). Only `e7-fable-3x` spans more
   than a day of commits (11 commits, 2026-08-17 → 2026-08-18).
2. **But arms *are* re-run.** E7 produced `e7-rep1-results-2026-08-15.md`,
   `e7-rep2-results-2026-08-17.md`, `e7-rep3-results-2026-08-18.md` — three sweeps over four
   days, with auth-fix commits (`9fab1b5`, `765fa6b`, `df46486`) landing *between* reps
   because the runner broke mid-arm. So the runner's active window is days, not hours, and
   in-sweep bugs demonstrably do get paid for in rework.
3. **Every arm forks its own runner. None has ever shared a library.**
   `e2/run-live.sh`, `e4-opus-k3/run-live.sh`, `e5-cc-builtin/run-host.sh` (66 lines),
   `e6-ultra/run-host.sh` (49), `e7-fable-3x/run-host.sh` (181), `crb/run-cubic.sh` (126),
   and now `crb-pipeline/run-host.sh` (237). `git diff --no-index` between the E7 and
   CRB runners reports 201 insertions / 145 deletions — a fork with a shared skeleton,
   which is exactly the established pattern.
4. **No arm runner has ever carried a test.**
   `rg -l 'prep-cc-review-clones|run-host|run-cubic|run-live' test/` returns nothing.
   `test/scripts/` covers only durable utilities (`health-check`, `archive-working-docs`,
   `skill-usage-report`, `failure-analysis`). Untested arm runners are the norm here, not a
   deviation introduced by this branch.
5. **"Zero results" is only half true.** The commit message says the arm is set up but not
   run, but `docs/working/crb-direction1-setup.md:186-203` records what *was* executed at
   $0: all 5 pilot clones materialized with both guards passing (and
   `runs/review-arms/crb/instances.json` carries 5 real records with real SHAs and measured
   `clone_mb`), the injector run against a real E8 rubric fixture, and the full
   extract → dedup → judge chain run end-to-end against stub shims. The unverified surface is
   narrow and *named*: skill registration inside the container, the real judge endpoint, and
   real per-instance cost.

**What this implies for triage.** Maintainability debt (duplication, missing abstraction,
heredocs) has a near-zero carrying cost here, because there is no maintenance phase — the
runner is written, run over a window of days, and frozen. That inverts the usual weighting:

- Debt that can **burn a sweep** (wrong money, wrong condition, silently-mislabelled arm) is
  the expensive class, and its cost is concentrated in a window that has not opened yet.
- Debt that costs **future readers** is cheap for `runs/review-arms/` — but *not* cheap for
  the three new files in `scripts/`, which sit in the durable directory alongside
  `canon-to-crb.py`, `cross-model-review.py`, and `review-arms.py`, several of which have
  bats coverage. 678 lines of arm-specific Python landing in the durable directory is itself
  a classification choice with a real (if small) carry cost.

I use that split throughout: `run-host.sh` is judged on sweep-safety, `scripts/crb-*.py` on
sweep-safety *plus* a modest readability budget.

---

## 1. Preflight auth check regressed against its own prior art

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:126`
**Nature:** Correctness regression against a sibling that was fixed the hard way
**Cost of Deferral:** `+0 — inert until the sweep runs; then one whole sweep per bad credential`
**Failure Cost:** `Med × Med — a silently unauthenticated sweep produces 50 empty cells and a wasted operator day, but no data corruption (num_turns=0 cells are detectable after the fact)`
**Confidence:** High — verified against the sibling source
**Legibility-target:** for-author

**Evidence** — the new check:

```python
if d.get("num_turns", 0) < 1 or "log in" in r.lower():
    sys.exit(f"  auth failed: {r[:200]!r}")
```

and the prior art it was forked from, `runs/review-arms/e7-fable-3x/run-host.sh:103`:

```python
sys.exit(0 if d.get("num_turns", 0) > 0 and "log in" not in r.lower() and "logged in" not in r.lower() else 1)
```

E7 checks **both** `"log in"` and `"logged in"`. The new runner dropped the second. The
documented failure string in its own comment block (`run-host.sh:105`) is
`"Not logged in"` — and `"logged in"` does not contain the substring `"log in"`
(`l-o-g-g-e-d-␣-i-n` vs `l-o-g-␣-i-n`). So the exact string the comment says it is guarding
against is the one string this test does not match.

The `num_turns < 1` clause is a real backstop and E7's comment (`e7-fable-3x/run-host.sh:87-89`)
records that a bad credential returns `num_turns=0`, so this is very likely still caught. But
the branch that was added deliberately, after being "learned the hard way, 2026-08-14", was
silently dropped in the fork.

### Carrying Cost: Low
Inert while nobody runs the arm. The moment someone does, it is a coin-flip on whether the
`num_turns` backstop alone holds. The whole point of the preflight is that it is the cheap
guard in front of a $50–$2000 sweep.

### Fix Cost
- **Scope:** localized — one boolean clause in one file
- **Effort:** minutes
- **Risk:** low — strictly widens an existing guard; cannot cause a false pass
- **Incremental?** yes

### Urgency Triggers
- Anyone runs `run-host.sh` for real. That is the intended next action per the commit message.

### Recommendation

**Recommendation:** Fix now

Trivial fix (single file, one clause, well under 50 LOC) so it is fixed in place rather than
routed through RPI. This is the one item where the fix cost is minutes and the failure cost is
a whole sweep, which is the classic fix-now shape. It also restores parity with the sibling
whose comment block this file inherited, so the code and its own documentation stop
disagreeing.

---

## 2. Doc/code contradictions shipped inside a single commit

**Severity:** Medium
**Location:** `scripts/crb-materialize.py:26`; `docs/working/crb-direction1-setup.md:27`, `:117-120`, `:172-176`; `scripts/crb-pipeline-to-benchmark.py:13-15` vs `scripts/crb-subset-leaderboard.py:4-8`
**Nature:** Documentation drift — but drift that exists at birth, not from decay
**Cost of Deferral:** `+1 contradicted claim per follow-on doc` — every results doc written from this runbook inherits the wrong numbers, and results docs are the durable artifact
**Confidence:** High — the contradicting pairs are both in this diff
**Legibility-target:** for-author

**Evidence** — the disk estimate, `scripts/crb-materialize.py:26`:

```
  scripts/crb-materialize.py --all                      # all 50 (~15-25GB)
```

against `docs/working/crb-direction1-setup.md:27`, in the same commit:

```
scripts/crb-materialize.py --all           # all 50 (~6-7 GB)
```

The doc is right. `runs/review-arms/crb/instances.json` — also in this diff — records
`clone_mb` for the 5 materialized pilot clones as 190 + 33 + 125 + 127 + 195 = 670 MB,
i.e. ~6.7 GB extrapolated to 50. The script's `--all` help text overstates by 2–4×.

**Evidence** — the leaderboard claim, `scripts/crb-pipeline-to-benchmark.py:13-15`:

```
      Untouched PRs and every other tool's reviews are preserved verbatim, so
      the aggregate table at the end of step 3 is a real leaderboard.
```

against `scripts/crb-subset-leaderboard.py:4-8`, whose entire reason for existing is that
this is false:

```
Step 3's own aggregate table sums each tool over every PR it has results for.
When our arm covers a 5-PR pilot and the other 49 tools cover all 50, that table
compares our row on 5 PRs against theirs on 50 — different denominators, not a
ranking.
```

Stage 1 also placed the golden-denominator caveat (`crb-direction1-setup.md:172-176`,
"`total_golden` 11 vs 13") and the "same judge pass" claim (`:117-120`, contradicted by the
doc's own `--out runs/review-arms/crb/offline-work-50-ra` example at `:100`) in this cluster.
I have not re-derived those two — Stage 1 owns them — but they belong to the same debt.

### Carrying Cost: Medium
This is the one class of debt in the diff whose cost does *not* end when the sweep ends. The
repo's durable output is `docs/working/*-results-*.md` and `docs/working/canon-issue-ledger.md`
— an archaeology that later sessions read as fact. A results doc written from this runbook will
quote the runbook's numbers. The 15-25 GB figure could also cause someone to decline `--all` on
a disk-space judgement that is wrong by 3×.

### Fix Cost
- **Scope:** localized but spread — 4–5 comment/prose edits across 4 files
- **Effort:** under an hour, and Stage 1 already did the diagnosis
- **Risk:** low — comment and prose edits only; no executable path changes
- **Incremental?** yes

### Urgency Triggers
- The first results doc is written from this runbook. That is the very next step after the
  sweep, so this is one step behind item 1.

### Recommendation

**Recommendation:** Fix now

Not because any of it breaks a run, but because the fix is prose editing with the diagnosis
already handed over by Stage 1, and because this repo's product *is* documentation. Wrong
numbers that propagate into the ledger are the specific harm this codebase is least able to
absorb. Multi-file but trivially scoped — no RPI needed; edit and commit.

---

## 3. Identity constants replicated across four files with no shared module

**Severity:** Low
**Location:** `scripts/crb-materialize.py:44-56`, `scripts/crb-pipeline-to-benchmark.py:50-56,170,172`, `scripts/crb-subset-leaderboard.py:25-26,38`, `runs/review-arms/crb-pipeline/run-host.sh:51-54`
**Nature:** Structural — duplicated configuration surface
**Cost of Deferral:** `+2 files to edit per new arm variant` (a second tool name, a different judge, or a relocated work dir each requires consistent edits in at least two files)
**Confidence:** High
**Legibility-target:** for-author

**Evidence** — `WORKSPACE` is defined identically three times. In `crb-materialize.py:44-51`:

```python
WORKSPACE = Path(__file__).resolve().parent.parent
BENCH = WORKSPACE / "external/code-review-benchmark/offline"
BENCH_DATA = BENCH / "results/benchmark_data.json"
DST_ROOT = WORKSPACE / "external/crb-eval"
...
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"
```

in `crb-pipeline-to-benchmark.py:50-56`:

```python
WORKSPACE = Path(__file__).resolve().parent.parent
BENCH = WORKSPACE / "external/code-review-benchmark/offline"
BENCH_DATA = BENCH / "results/benchmark_data.json"
DEFAULT_RUNS = WORKSPACE / "runs/review-arms/crb-pipeline"
DEFAULT_OUT = WORKSPACE / "runs/review-arms/crb/offline-work-50"
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"
DEFAULT_JUDGE = "claude-opus-4-5-20251101"
```

and in `crb-subset-leaderboard.py:25-26`, where the injector's `DEFAULT_OUT` and
`DEFAULT_JUDGE` are re-spelled as one concatenated literal:

```python
WORKSPACE = Path(__file__).resolve().parent.parent
DEFAULT_EVALS = (WORKSPACE / "runs/review-arms/crb/offline-work-50/results"
                 / "claude-opus-4-5-20251101/evaluations.json")
```

`MANIFEST` is then re-derived a fourth time, in shell, at `run-host.sh:53`:

```bash
MANIFEST="$ROOT/runs/review-arms/crb/instances.json"
```

The tool name `"mfc-pipeline-e8"` is likewise the default in both
`crb-pipeline-to-benchmark.py:170` and `crb-subset-leaderboard.py:38`.

The couplings are currently *correct* — I checked that `DEFAULT_EVALS` and `DEFAULT_OUT`
agree, and that the existing `runs/review-arms/crb/offline-work/` (from the cubic arm) is a
deliberately different directory from `offline-work-50/`. The debt is that nothing enforces
that agreement.

### Carrying Cost: Low
Four files is small, the couplings are correct today, and — per the framing section — nobody
maintains an arm after its sweep. The one live scenario is the doc's own
`--sections fix address` red+amber variant (`crb-direction1-setup.md:100`), which needs a
second tool name and a second `--out`; both are already exposed as CLI flags, so even that
path does not require touching the constants.

### Fix Cost
- **Scope:** cross-cutting across the four new files (a `scripts/lib/crb_paths.py` plus a
  shell equivalent, or emitting paths from the manifest)
- **Effort:** hours, plus the design question of how shell reads a Python module
- **Risk:** medium — touches every entry point during the window before the sweep, for no
  behavioural gain; a bad refactor here is exactly the "arm broke mid-sweep" failure E7 hit
- **Incremental?** yes, but not usefully — partial extraction leaves two sources of truth

### Urgency Triggers
- None identified. The variant the runbook already plans for is handled by existing flags.

### Recommendation

**Recommendation:** Carry intentionally

The fix costs more than the debt, and it costs it at the worst moment — immediately before a
sweep whose whole value depends on the harness not changing mid-run. Four correct duplicated
constants across four files that will be frozen in days is textbook carry-forever debt. Revisit
only if a *third* arm reuses these scripts, which the repo's history says is unlikely.

---

## 4. Four `python3 - <<'EOF'` heredocs embedded in the bash driver

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:119-132`, `:138-141`, `:174-192`, `:203-213`, `:217-236`
**Nature:** Structural — language mixing; logic outside the tested/lintable surface
**Cost of Deferral:** `+0 — inert; cost is flat`
**Confidence:** High
**Legibility-target:** for-author

**Evidence** — the harvest step, `run-host.sh:174-176`, is representative:

```bash
  python3 - "$dest/transcript.jsonl" "$dest/result.json" "$dest/review.md" <<'EOF'
import json, sys
res = None
```

There are five such blocks (four heredocs plus the inline `python3 -c` at `:69-71`), sitting
in the same branch as three standalone Python modules totalling 678 lines. The obvious
objection is: why is JSON parsing in a heredoc when there is already a Python codebase here?

Two things blunt it. First, the blocks are genuinely driver-shaped — extract the result event,
check `num_turns > 0`, print a cost line, write `run-meta.json` — each is 10–20 lines of glue
inside the per-instance loop, not reusable logic. Second, this is exactly the prior art:
`e7-fable-3x/run-host.sh:96-104` and `:120-124` use the identical
`python3 -c`-embedded-in-bash idiom, and the `num_turns > 0` skip check at
`crb-pipeline/run-host.sh:138-141` is a verbatim copy of E7's at `:120-124`. Deviating from
the established shape would make cross-arm comparison harder, not easier.

### Carrying Cost: Low
It is ugly and it is unlintable — `bash -n` (which the doc says was run,
`crb-direction1-setup.md:194`) does not syntax-check heredoc contents, so a Python typo in the
run-meta block at `:217` would surface only at the *end* of a completed sweep. That is the one
real bite. But the blocks are short, the failure is loud, and the sweep artifacts
(`transcript.jsonl`, `result.json`) survive to be re-processed by hand.

### Fix Cost
- **Scope:** localized — one new `scripts/crb-harvest.py` absorbing the harvest + run-meta blocks
- **Effort:** hours
- **Risk:** medium — same objection as item 3: it is a rewrite of the driver's inner loop, for
  readability, immediately before the run that matters
- **Incremental?** yes — the run-meta block at `:217-236` is separable from the loop and is
  the one most worth extracting, since it is the block whose failure costs the most

### Urgency Triggers
- None identified.

### Recommendation

**Recommendation:** Carry intentionally

The idiom is the house style for arm runners across E5/E6/E7 and deviating has a real cost in
cross-arm comparability. If anything is done here, the minimal defensible version is a
pre-sweep smoke of the run-meta block alone (feed it a hand-written `result.json`), which buys
most of the protection for none of the refactor risk. I am deliberately not making a coverage
recommendation — the parallel test-strategy critic owns that call.

---

## 5. `↩️ Considered Overrides` is excluded from injection only by accident

**Severity:** Low
**Location:** `scripts/crb-pipeline-to-benchmark.py:58-60`, `:97-113`
**Nature:** Latent correctness — a coupling to an external file's column name
**Cost of Deferral:** `+0 — inert; cost is flat` (it only fires if `skills/code-review/SKILL.md` renames a column)
**Failure Cost:** `Low × Med — silently injects non-findings as findings, understating the pipeline's precision in a published benchmark row`
**Confidence:** High — traced through both files
**Legibility-target:** for-author

**Evidence** — the section filter, `crb-pipeline-to-benchmark.py:58-60`:

```python
# Rubric section headers we treat as findings. "Confirmed Good" and "Considered
# Overrides" are deliberately absent.
FINDING_SECTIONS = ("Must Fix", "Must Address", "Consider")
```

matched by substring at `:98`:

```python
        if not any(s.lower() in section.lower() for s in sections):
```

The comment claims `Considered Overrides` is excluded. It is not excluded by this filter:
the real rubric heading is `## ↩️ Considered Overrides` (`skills/code-review/SKILL.md:1137`),
whose lowercase form contains `"consider"`, so it passes. What actually excludes it is two
lines later, at `:105-108`:

```python
        idx = {h.lower(): i for i, h in enumerate(header)}
        f_i = idx.get("finding")
        if f_i is None:
            continue
```

The overrides table's header is `| Override (PR ref / Date) | Prior finding | ... |`
(`SKILL.md:1142`). `"prior finding"` is not `"finding"`, so the lookup misses and the section
is skipped. Correct outcome, wrong mechanism — and the mechanism lives in a *different file
in a different skill*, so a future rubric edit renaming that column to `Finding` would silently
start injecting inherited override rows as if they were fresh findings, each one counting
against precision.

`✅ Confirmed Good` really is excluded by the section filter as the comment claims — its
heading contains none of the three strings. So the comment is half right.

### Carrying Cost: Low
Zero today. The rubric column is named `Prior finding` deliberately (it refers to a *prior*
run's call) and there is no pressure to rename it.

### Fix Cost
- **Scope:** localized — one line
- **Effort:** minutes
- **Risk:** low
- **Incremental?** yes

The minimal fix is an explicit exclusion list checked before the substring match, so the
comment's claim becomes true of the code that implements it:

```python
EXCLUDED_SECTIONS = ("Considered Overrides", "Confirmed Good")
```

### Urgency Triggers
- Any edit to `skills/code-review/SKILL.md`'s rubric table headers. Given this repo iterates on
  that skill constantly (`f3c8e3d`, `82f85ce`, `4ed98ff` in the last two weeks), that is not
  remote.

### Recommendation

**Recommendation:** Fix opportunistically

Batch it with item 2's edits to the same file. It is a one-line change that converts a
load-bearing accident into a stated invariant, and the skill it depends on is under active
weekly churn — which is the specific condition that makes an accidental exclusion worth
converting into a deliberate one. Not fix-now, because it cannot fire without a separate
deliberate edit elsewhere.

---

## 6. `git clean -qfd` omits `-x`, so gitignored artifacts survive between re-runs

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:200-201`
**Nature:** Hygiene — incomplete state reset
**Cost of Deferral:** `+0 — inert; cost is flat`
**Confidence:** Medium — the harm depends on whether the reviewing agent runs builds, which is unknown until the arm runs
**Legibility-target:** for-author

**Evidence:**

```bash
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfd 2>/dev/null || true
```

with the harvest immediately above it at `:194-195`:

```bash
  (cd "$clone" && git status --porcelain --untracked-files=all) \
    | awk '{print $2}' | grep -E '\.(md|json)$' \
```

Both halves share the blind spot. `git status --untracked-files=all` does not list gitignored
files, and `git clean -fd` without `-x` does not remove them. So anything the reviewing agent
writes to a gitignored path is neither harvested nor cleaned.

One correction to how this was framed upstream: this does **not** leak *across instances*.
Each instance gets its own clone directory (`clone="$CLONES/$id"`, `:135`), and the payload
home is a fresh `mktemp -d` per instance (`:150`). The leak is across **re-runs of the same
instance** — and re-runs are the documented workflow, since the skip guard at `:138-144` says
"delete to re-run", which deletes `$dest`, not the clone.

Realistically the artifact at risk is the rubric, which the code-review skill writes to
`docs/reviews/` (`:147-148` comment) — not a gitignored path in these upstream repos. The
bigger residue is build output (`node_modules/`, `target/`) if the agent runs a build while
navigating grafana or keycloak, which would then persist and inflate disk across re-runs.

### Carrying Cost: Low
Costs disk, and at worst a confusing second run. It cannot corrupt a first-run measurement,
which is the measurement the pilot is for.

### Fix Cost
- **Scope:** localized — add `-x`, and optionally widen the harvest to
  `--ignored` so a rubric written to a gitignored path is still captured
- **Effort:** minutes
- **Risk:** low-medium — `clean -qfdx` is more destructive by design; it is confined to
  `$clone` under `external/crb-eval/`, which is gitignored scratch that
  `crb-materialize.py --force` already rebuilds from scratch
- **Incremental?** yes

### Urgency Triggers
- A pilot instance is re-run after a failure — plausible, since the doc's own advice
  (`crb-direction1-setup.md:200-201`) is to run one instance first and inspect it.

### Recommendation

**Recommendation:** Fix opportunistically

Add `-x` when item 1 is fixed in the same file; the two edits are 40 lines apart. Standalone it
does not justify a commit, and I would not widen the harvest to `--ignored` without first
seeing one real run's output — that is a change made on speculation about where the agent
writes, and the pilot will answer it for free.

---

## 7. Unguarded step-2.5 judge cost is documented nowhere

**Severity:** Low
**Location:** `scripts/crb-pipeline-to-benchmark.py:268-271`, `docs/working/crb-direction1-setup.md:143-147`
**Nature:** Operational — a cost hazard the runbook names imprecisely
**Cost of Deferral:** `+0 — inert; cost is flat`
**Failure Cost:** `Low × Med — an unbudgeted paid API run that also overwrites the published scores this arm's whole comparison depends on`
**Confidence:** Medium — Stage 1 derived the ~2233-call figure; I did not re-derive it
**Legibility-target:** for-author

**Evidence** — the warning the injector writes into every generated `RUN.md`:

```python
    # The work dir carries its own runbook: the --tool flag is not optional
    # decoration. Without it step 2 re-extracts the ~52 (PR, tool) pairs the
    # checked-in candidates file happens to be missing, and step 3 would re-judge
    # them — paid work that overwrites published numbers with ours.
```

and the same claim in prose at `crb-direction1-setup.md:143-145`. Stage 1 found the count is
50, not ~52, and that the genuinely unguarded expense is step **2.5**, not step 2 — around
2233 paid calls if `--tool` is omitted, a number that appears in neither the comment, the
prose, nor the generated `RUN.md`.

The important structural point: the warning is *correct in its instruction* (`--tool` is
mandatory on all three steps, and the generated `RUN.md` at `:284-288` says so in capitals).
Only the magnitude is wrong, and wrong in the safe direction of understating. This is a
labelling defect on a guard that works, not a missing guard.

### Carrying Cost: Low
The instruction that prevents the harm is present, repeated three times (script comment,
setup doc, generated `RUN.md`), and enforced by muscle memory of copying the runbook block.

### Fix Cost
- **Scope:** localized — one comment and one prose paragraph, plus the generated `RUN.md`
  string at `:284-285`
- **Effort:** minutes
- **Risk:** low
- **Incremental?** yes

### Urgency Triggers
- Someone runs the judge steps by hand instead of pasting the `RUN.md` block.

### Recommendation

**Recommendation:** Fix opportunistically

Fold into item 2 — it is the same class (a number in a comment that does not match reality) in
the same file. Worth stating the real magnitude because "~52 pairs" reads as a rounding error
while "~2233 paid calls" reads as a stop sign, and the guard's effectiveness depends entirely
on the operator taking it seriously.

---

## 8. Strictly sequential instance loop

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:134-214`
**Nature:** Throughput — no parallelism across instances
**Cost of Deferral:** `+0 — inert; cost is flat`
**Confidence:** Medium — wall-clock depends on per-instance duration, which is unmeasured
**Legibility-target:** for-author

**Evidence:**

```bash
for id in "${INSTANCES[@]}"; do
  clone="$CLONES/$id"
```

with one `docker run` per iteration (`:155-167`) and no backgrounding. A 50-instance `--all`
sweep runs 50 containers end to end. Per-instance duration is one of the explicitly
unverified quantities (`crb-direction1-setup.md:203`, "the real per-instance cost"), but at a
$10–40 cost band the runs are clearly long, and an overnight-to-multi-day `--all` wall clock
is the realistic shape.

### Carrying Cost: Low
Costs operator wall-clock only, on a mode (`--all`) the runbook explicitly says not to commit
to before a pilot (`crb-direction1-setup.md:158`, "do not commit to this before a pilot"). The
5-PR pilot — the only mode anyone is running next — is unaffected. Every prior arm is
sequential too (E7 ran 8 instances × 3 reps serially), so this matches house behaviour.

### Fix Cost
- **Scope:** localized, but the loop body is entangled — shared `$OUT` writes, per-instance
  `mktemp` homes, and a shared npm cache volume that would now see concurrent writers
- **Effort:** hours, plus real risk of interleaved output making a failed cell hard to diagnose
- **Risk:** medium-high — concurrent API calls also invite rate-limiting, which produces
  partial cells that look like model failures rather than infrastructure failures. That is
  precisely the confound this whole benchmark arm exists to avoid.
- **Incremental?** no — safe parallelism needs per-instance log isolation and a concurrency cap

### Urgency Triggers
- A decision to run `--all` on a deadline. Not imminent; the runbook forbids it pre-pilot.

### Recommendation

**Recommendation:** Defer and monitor

Re-evaluate specifically **after the 5-PR pilot reports a real per-instance duration**. If a
pilot instance takes under ~20 minutes, `--all` is an overnight job and sequential is fine
forever. If it takes over an hour, `--all` is a multi-day job and parallelism becomes worth
its confound risk. That number is one pilot away and there is no reason to guess it now.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| 1 | Preflight drops E7's `"logged in"` check (`run-host.sh:126`) | Low | +0 inert; then 1 sweep per bad credential | Med × Med — 50 empty cells, wasted operator day | Minutes | Imminent | Fix now |
| 2 | Doc/code contradictions born in-commit (disk GB, leaderboard claim, denominators) | Medium | +1 contradicted claim per follow-on results doc | | <1 hour | Imminent | Fix now |
| 3 | `WORKSPACE`/`BENCH`/`MANIFEST`/tool-name duplicated across 4 files | Low | +2 files to edit per arm variant | | Hours | None | Carry intentionally |
| 4 | Four Python heredocs in the bash driver | Low | +0 inert | | Hours | None | Carry intentionally |
| 5 | `↩️ Considered Overrides` excluded only by a column-name accident | Low | +0 inert | Low × Med — non-findings injected, understating precision | Minutes | On next rubric edit | Fix opportunistically |
| 6 | `git clean -qfd` missing `-x` (`run-host.sh:201`) | Low | +0 inert | | Minutes | On first re-run | Fix opportunistically |
| 7 | Step-2.5 unguarded cost magnitude undocumented | Low | +0 inert | Low × Med — unbudgeted run overwrites published scores | Minutes | None | Fix opportunistically |
| 8 | Sequential instance loop | Low | +0 inert | | Hours | After pilot | Defer and monitor |

Failure Cost is populated only on 1, 5, and 7 — the three items where the blast radius
(a burned sweep, a corrupted precision number, an unbudgeted paid run that overwrites the
comparison baseline) is materially worse than the carrying cost suggests. Items 2, 3, 4, 6,
and 8 are ergonomic or throughput debt where guessing an incident probability would add noise.

### Recommended Order

**Before the arm is run at all — one commit, ~1 hour total:**

1. **Item 1** (preflight `"logged in"`). First because it is the only item that can waste
   money, it takes minutes, and the very next intended action is running the sweep.
2. **Item 6** (`clean -qfdx`). Batched with item 1 — same file, 75 lines apart, so it costs
   nothing extra to land together.
3. **Item 2** (doc/code contradictions). Second commit, separate from the shell edits because
   it touches four files and is purely prose. Do this before the sweep, not after, because the
   results doc is written straight from this runbook and inherits its numbers.
4. **Item 7** (step-2.5 magnitude) and **Item 5** (explicit `EXCLUDED_SECTIONS`). Both live in
   `crb-pipeline-to-benchmark.py`; fold them into item 2's commit rather than opening a third.

That is the whole pre-sweep list: two commits, well under a working morning, and it clears
every item whose cost is denominated in money or in ledger accuracy.

**After the pilot reports:**

5. **Item 8** — revisit with a real per-instance duration in hand.

**Never, unless a third arm reuses these scripts:**

6. **Items 3 and 4.**

### What I would not fix

Stating these explicitly, because the default instinct on a 1209-line diff is to fix all of it:

- **The duplicated constants (item 3) and the embedded heredocs (item 4).** These are the two
  items a reviewer is most tempted to flag on general principle, and they are the two I am most
  confident about leaving. They are the house pattern across E5/E6/E7 and `run-cubic.sh`; the
  repo has never once shared code between arm runners; and refactoring the driver's inner loop
  immediately before the run it exists to perform is how E7 ended up with three auth-fix commits
  interleaved with its reps. The refactor's risk lands in the sweep window; its benefit lands in
  a maintenance phase that history says will not occur.
- **Missing test coverage.** No arm runner in this repo has ever had a bats test, and the
  parallel test-strategy critic owns this call. I note only the triage-relevant asymmetry: the
  three `scripts/crb-*.py` files sit in the *durable* directory next to tested utilities, so if
  any coverage is added, that is where it earns its keep — not in `run-host.sh`.
- **Re-siting `scripts/crb-*.py` into `runs/review-arms/`.** It is a defensible classification
  complaint (678 lines of single-arm code in the shared scripts directory), but
  `scripts/canon-to-crb.py` and `scripts/review-arms.py` already set that precedent, and moving
  files breaks every path reference in the runbook, the generated `RUN.md`, and `run-host.sh`
  for zero functional gain.
- **The destructive git sequence in `crb-materialize.py:176-184`.** Worth an explicit
  non-finding given what happened in this session. That code runs the exact
  `update-ref -d` → `reflog expire` → `gc --prune=now` chain that destroyed this repo's refs
  earlier today — but every call passes `cwd=dst` explicitly through `subprocess`, with no
  `cd` and no shell interpolation, so the "leading `cd` failed silently and the rest ran in the
  wrong directory" failure mode is structurally impossible here. This is *safer* than its bash
  prior art. Do not "simplify" it back into a shell block.

---

## Goal-Alignment Note
- Answered: yes — 8 items triaged with carry/fix/urgency, ranked, with explicit non-fixes
- Out of scope: test coverage design (owned by the parallel test-strategy critic — I referenced
  the absence of arm-runner tests only as lifetime evidence, and made no coverage
  recommendation); re-verification of Stage 1's fact-check findings 1, 5, 8, and the ~2233-call
  derivation, which I costed rather than re-derived
- Escalate: item 1 is the only finding I would want landed before anyone spends money on this
  arm — the preflight regression against `e7-fable-3x/run-host.sh:103` is a sweep-burning
  defect that Stage 1 surfaced only as a doc/string mismatch, and the sibling comparison
  upgrades it. Items 1 + 6 are a single-file, minutes-long commit.
