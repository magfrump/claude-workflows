# Performance Review — `c98343b..HEAD` (feat/crb-direction1-harness)

**Scope:** commits `1d8ea67` and `4624c5d` (13 files, +912/−201), evaluated on the resulting
code: `runs/review-arms/crb-pipeline/run-host.sh`, `scripts/crb-materialize.py`,
`scripts/crb-egress-verdict.sh`, `scripts/crb-audit-clone.sh`,
`scripts/crb-harvest-artifacts.py`, `runs/review-arms/crb-pipeline/docker/*`, four bats suites.
Parent `197eec6` is context only.
**Date:** 2026-08-19
**Based on:** `docs/reviews/code-fact-check-report.md` (k=1, covers `1d8ea67` only — see warning),
`docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness-r2.md`, and the
predecessor performance review of `197eec6` (this file's prior contents).
**Performance frame:** dollars and sweep throughput, not milliseconds. A cell is a $10–40
headless review; a sweep is 5–50 cells under a `SWEEP_BUDGET` ceiling.
**Loop position:** terminal pass of a review-fix loop at its 3-iteration cap.

> ⚠️ **Partial code fact-check coverage.** `docs/reviews/code-fact-check-report.md` is scoped
> to `1d8ea67`. The second commit, `4624c5d` — which moved the attempt ledger above the audit —
> has no fact-check. Claims about that move below are my own reading, marked as such.

---

## Data Flow and Hot Paths

`run-host.sh` is a serial, operator-launched sweep. **Once per invocation** it builds two
images, creates an `--internal` docker network plus a tinyproxy sidecar, runs a five-leg egress
preflight and one paid auth/skill preflight. **Once per cell** it now: checks the sweep-budget
gate → resolves baseline paths via a `crb-materialize.py --baseline-paths` subprocess → checks
cell status → checks `MAX_ATTEMPTS` → `--restore` (rmtree + two sha256 verifications + tar
extract) → **probes proxy liveness in a throwaway container** → copies the payload → runs the
paid review container → reduces the transcript → **appends the attempt ledger** → harvests
artifacts → runs the audit in a second throwaway container.

**Path temperature.** Nothing here is a request handler. The per-cell loop body is the hottest
path and executes at most 50 times, each iteration gated by a review costing $10–40 and
4.5–10.8 minutes. Severity is driven by *dollars per occurrence* and by *cells lost from the
denominator*, not by CPU.

**What these commits add to the per-cell critical path, measured on this host today:**

| new per-cell step | cost | 50-cell sweep total |
|---|---|---|
| `sweep_spend_ok` (`:407-434`) — 50 cell dirs × 2 ledger lines | **15 ms** | 0.71 s |
| `crb-materialize.py --baseline-paths` (`:448`) — replaces a bash `[ -f ]` | **27 ms** | 1.4 s |
| index sha256 in `restore_clone` (`crb-materialize.py:387-400`) | <5 ms | <0.3 s |
| `in_cell_net` liveness probe (`:525`) — one `docker run` + curl | **~1–3 s** (carried) | ~1–2 min |

Measured by me: `sweep_spend_ok`'s python body against a 50-cell × 2-attempt fixture, 50
sequential invocations timed at 0.71 s wall; `--baseline-paths` timed at 5 invocations /
0.135 s. Container launch (~1 s) is carried from the predecessor's measurement, not re-measured
— this host has no docker (`docker version` → command not found).

**So: the earlier 2–3 s/cell figure stands and grows by roughly one container launch, to
≈ 3–5 s per cell.** Against 4.5–10.8 minutes and $10–40 per cell that is **0.5–1.9% of one
cell**, or about 3 minutes across a 50-cell sweep. Nothing in these commits changes the disk
or clone-size analysis the predecessor measured, and no addition sits on the critical path in a
way the earlier measurement missed — the only new step above millisecond scale is the liveness
probe, priced above.

**Once-per-sweep, not per-cell:** the egress preflight went from **3 containers to 4**, not
five. The scope brief says five; leg 0 (`internal-net`, `:238`) asserts the captured
`NET_CREATE_CMD` string and launches nothing. The four container legs are `api-reachable`,
`filter-blocks`, `plain-http` (new) and `no-direct-route`. One extra container launch plus five
`bash crb-egress-verdict.sh` forks, once per invocation: ~1–2 s, immaterial.

**Test state:** `bats test/crb-{egress-config,egress-verdict,disposable-clone,audit-clone}.bats`
→ 55/55 ok, exit 0, executed on this host today.

---

## Verdict on the three claimed closures

**A6 — closed, mechanically.** The guard is unnested (`:493-496`, above the `result.json` test
at `:497`), and I verified by execution that the no-`result.json` path still reaches the ledger:
I ran the transcript reducer (`:567-585`) against a transcript with no `result` event — it exits
0 and writes no `result.json` — then ran the ledger heredoc (`:591-601`) against the missing
file; it appended `{"cost_usd": 0, "turns": null, "is_error": false, "subtype": null}` and
`grep -c .` returned 1. The counter grows, so `MAX_ATTEMPTS` bounds it. The retry is no longer
unbounded. What did *not* get fixed is the `$0` half — Finding 1.

**A7 — closed.** `sweep_spend_ok` is the first statement of the loop body (`:437`), ahead of
every `continue`. Its cost is 15 ms per call, measured; the "is it still free at 50 cells with
retries" question is answered yes with three orders of magnitude of headroom. It also fails
closed: a python error inside the heredoc exits nonzero and is read as "over budget".

**A6-new (proxy liveness) — closed, correctly placed.** The probe sits at `:525`, after
`--restore` and before both the payload copy and the paid container, i.e. immediately before the
spend it protects. It converts "the proxy died at cell 7 and all 43 remaining cells fail into
the A6 state" into "stop at cell 8". That is the failure it targets and it does prevent it. Its
residual is Finding 3.

**New in `4624c5d` (ledger before audit) — closed for the audit, one path left.** The ledger
append at `:591-601` now precedes the harvest's `exit 4` (`:611`) and the audit's `exit 4`
(`:641`), closing the gap the fact-check's Claim 20 scope note named. On the write-once
question: the append is the only `attempts.jsonl` writer in the file, it is unconditional
(`|| true`) and it is not inside any nested loop, so no path double-appends. One path still
*skips* it — Finding 4.

---

## Findings

#### Un-measurable spend is still ledgered as `$0`, and `SWEEP_BUDGET` is blind to it

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:591-601`, consumed by `:407-434` and `:335-352`
**Move:** Price the deployment environment / count the hidden multiplications
**Classification:** Macro (the money ceiling cannot see a whole class of spend) / Hot path (the per-cell loop body, the only path that spends)
**Confidence:** High
**Baseline:** `BUDGET` default $25.00 (`run-host.sh:87`); `SWEEP_BUDGET` default $250.00
(`:94`); `MAX_ATTEMPTS` default 2 (`:98`); $10–40 per cell
(`docs/working/crb-direction1-setup.md:324`).

The predecessor's A6 recommendation had two halves — bound the retry, *and* record unmeasurable
spend as unmeasurable. Only the first was taken. A container that is OOM-killed or loses its API
connection mid-review has already been billed by Anthropic for every token it consumed, up to
`--max-budget-usd $BUDGET`, but writes no `result.json`; the ledger row is then
`{"cost_usd": 0}` (verified by execution above), which `sweep_spend_ok` adds as zero and
`write_run_meta` counts as zero. The worst case is now *bounded* where it used to be unbounded —
50 cells × `MAX_ATTEMPTS` 2 × `BUDGET` $25 = **up to $2,500 of real spend against a
`SWEEP_BUDGET` reading $0.00** — and the liveness probe (`:525`) makes the systemic version of
this unlikely, so the realistic exposure is the scattered per-cell case. But the number the
operator authorizes the *next* sweep against is still wrong in the unsafe direction.

**Recommendation:** Write `{"cost_usd": null, "subtype": "no_result_event"}` on the
no-`result.json` path and have `sweep_spend_ok` / `write_run_meta` surface a
`unmeasured_attempts` count next to the total, so an operator reading `$180 / $250` can see
whether that number is complete. Three lines, $0 to verify on this host.

---

#### `MAX_ATTEMPTS` cannot tell a paid failure from a container that never started

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:546-560` (unguarded `docker run` failure), `:591-601` (ledger), `:488-496` (guard)
**Move:** Find the work that moved to the wrong place
**Classification:** Macro (a cell is permanently retired from the judged denominator by a non-spending event) / Hot path (per-cell)
**Confidence:** Medium
**Baseline:** `MAX_ATTEMPTS` default 2 (`run-host.sh:98`); 5–50 cells per sweep
(`docs/working/crb-direction1-setup.md:324` frame); no measurement exists for docker-level
failure rate on this host — that part is `no baseline available — flagged as speculative`.

Closing A6 gave the attempt counter authority it did not have before, and the counter is
type-blind. The paid `docker run` failure is swallowed:

```
559:    > "$dest/transcript.jsonl" 2> "$dest/stderr.log" || {
560:      echo "$id: claude exited non-zero — see $dest/stderr.log" >&2; }
```

so docker's own 125/126/127 (image gone, daemon hiccup, exec failure) produces an empty
transcript, no result event, and a `cost_usd: 0` ledger row that is indistinguishable from a
$25 death. Two such events retire a $10–40 cell from the sweep permanently — it becomes
`skipped_bad` on every subsequent resume, and the only remedy is an operator noticing the
counter and running `rm -rf $OUT/$id`. The window is narrow, because the liveness probe at
`:525` catches a dead daemon or proxy first and exits 5 before consuming an attempt; what
remains is "docker served the probe container but not the review container". Note also that
`:559-560` is the same shape as the `|| true` swallows the rubric flags at A8/A14 — this is that
pattern reaching the retry budget.

**Recommendation:** Capture the `docker run` status into a variable and, when it is 125/126/127
or the transcript is zero-length, either abort like the probe does (`exit 5`, consistent with
the sibling failure it resembles) or ledger a row that `MAX_ATTEMPTS` does not count. Pair it
with Finding 1's `subtype` field — one record shape answers both.

---

#### The per-cell liveness probe is a single un-retried sample that stops the whole sweep

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:521-529`, using `in_cell_net` at `:201-206`
**Move:** Find the contention point / trace the resource lifecycle
**Classification:** Micro (one container launch + one curl per cell) / Hot path (per-cell)
**Confidence:** Medium
**Baseline:** container launch ~1 s, carried from the predecessor's measurement of the audit
container; `--max-time 15` at `:525`; 4.5–10.8 min per cell
(`docs/working/archive/2026-08-19-canon-issue-ledger.md:331`). Its own latency is
`no baseline available — flagged as speculative` — this host has no docker.

The probe's cost is right: ~1–3 s against a 4.5–10.8 min cell is under 1%, about 1–2 minutes
across a full sweep, and it buys back the whole remaining sweep in the failure case, so the
trade is strongly positive. The exposure is on the other side. It is one sample, with no retry,
and its failure is `exit 5` — an abort of a multi-hour, possibly $200 sweep. A 15-second
transient (docker pulling under load, a momentary DNS blip inside the proxy container, the
sidecar mid-restart) is indistinguishable from a dead proxy. Nothing is *lost* when it
misfires — no cell is paid for, the sweep resumes cleanly and `sweep_spend_ok` now makes the
resume safe — so the cost is operator wall-clock and the risk of the abort landing overnight
with nobody to restart it.

**Recommendation:** Retry the probe once or twice with a short sleep before `exit 5`. Two extra
container launches on the failure path only; the happy path is unchanged. Optionally add
`--restart unless-stopped` to the sidecar (`:178-179`) so the common cause self-heals — the
`EXIT` trap at `:195`/`:396` already tears it down either way.

---

#### One remaining path drops an attempt's spend before it is ledgered

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:567-585` (transcript reducer, no `||` guard) preceding the ledger at `:591`
**Move:** Trace the resource lifecycle
**Classification:** Macro (spend for a paid cell leaves no record) / Hot path (per-cell)
**Confidence:** High for the mechanism, Low for reachability
**Baseline:** `no baseline available — flagged as speculative` — no run of this harness has
produced a transcript at all.

`4624c5d` moved the ledger above the audit so `exit 4` cannot drop an attempt's spend. One
statement still sits between the paid container and the ledger and is not guarded: the
transcript reducer at `:567` runs under this file's `set -euo pipefail` with no `|| true` and no
`||` handler, so a nonzero exit from it kills the script *after* the money was spent and
*before* `:591` records it. Its only realistic failure is the initial `open(sys.argv[1])`, and
`:559` creates that file by redirection, so reachability is limited to disk-full / redirect
failure. Recorded because the commit's stated invariant is "no path can drop an attempt's
spend", and this is the one remaining counterexample to it — the same class of gap the fact
check's Claim 20 caught one commit ago.

**Recommendation:** Append `|| true` to the reducer heredoc, matching the ledger step and the
result-rewrite step immediately below it (`:591`, `:646`). One token.

---

#### `PREFLIGHT_ONLY=1` bills a turn that no artifact records, on a command designed to be re-run

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:262-300`; trap at `:195` vs `write_run_meta` trap at `:396`
**Move:** Price the deployment environment
**Classification:** Micro (one short model turn) / Cold path (once per invocation)
**Confidence:** High
**Baseline:** the payload carries **25 `SKILL.md` files, ~50.6 KB of frontmatter descriptions**
(measured today via `git archive main skills`), i.e. roughly 13k tokens of skill descriptions in
the system prompt before Claude Code's own preamble, for a one-turn reply. Fact-check Claim 9
prices the turn at "~$0.01 against a $10–40 cell". Sweep totals for reference: $50–200 pilot,
$500–2000 `--all` (`docs/working/crb-direction1-setup.md:324` frame).

The paid auth/skill preflight (`:264-271`) runs *before* the `PREFLIGHT_ONLY` exit (`:294-300`),
so the command exists to be run repeatedly and bills every time. Decision 034 now discloses this
in prose ("which bills one turn, not zero") and `:298` says it on stdout — the honesty gap the
predecessor's finding 4 raised is closed. The *accounting* gap is not, and this commit widened
it: `write_run_meta` is only trapped at `:396`, below the `PREFLIGHT_ONLY` exit at `:299`, so
that path writes **no `run-meta.json` at all**, and `$OUT/preflight.json` is a top-level file
that neither `write_run_meta`'s `os.listdir` scan (`:327-330`, requires `name/result.json`) nor
`sweep_spend_ok`'s (`:412-430`, requires `name/attempts.jsonl` or `name/result.json`) can see.
A debugging session that runs `PREFLIGHT_ONLY=1` ten times while getting docker right pays ten
unledgered turns, all outside any number a results doc will quote. Cents, not dollars — but the
arm's whole claim is that its cost is auditable from `run-meta.json`.

**Recommendation:** Parse `total_cost_usd` out of `$OUT/preflight.json` into a `preflight/`
pseudo-cell `attempts.jsonl` row, so it flows into both `run-meta.json` and `sweep_spend_ok`
without either learning a new file shape. Move the `write_run_meta` trap installation above the
`PREFLIGHT_ONLY` exit so that path leaves provenance too.

---

#### The audit still forks one `git merge-base` per stray commit, unbounded

**Severity:** Low
**Location:** `scripts/crb-audit-clone.sh:88-99`
**Move:** Ask "what's the size of N?"
**Classification:** Macro (per-item subprocess over an unbounded collection) / Cold path (once per cell, post-review)
**Confidence:** High
**Baseline:** `git rev-list --all --not HEAD` measured at 0.00 s on all five pilot clones
(predecessor, this host, 2026-08-19) — N is 0 in the clean case.

Carried unchanged. `1d8ea67` edited exactly this loop — to hoist the `note` out so the count is
printed rather than only tallied — and left the fork-per-commit structure in place:

```
88: for c in $strays; do
89:   n_strays=$((n_strays+1))
90:   if ! git merge-base --is-ancestor "$HEAD_SHA" "$c" >/dev/null 2>&1; then
```

The case the loop exists for is a cell that ran `git fetch` against the upstream repo, which
brings in the fork's entire remaining history, so N goes to thousands and the audit forks one
process per commit — inside a container, on the cell that just cost $10–40, at the exact moment
the operator most wants a fast verdict. The commit's own change makes the loop *more* clearly
count-only: the reporting value now fully saturates at the first foreign commit
(`:96` sets `first_foreign` once; `:100` prints one line), so every additional fork buys nothing
but an integer.

**Recommendation:** Cap the examined set (`head -500`, report ">500 stray commits") or replace
the loop with a set difference computed in two `git rev-list` processes. The audit's contract is
tri-state and this changes neither the exit code nor the reported count's usefulness.

---

#### Deleting `--snapshot` makes a full re-clone the mandatory setup step

**Severity:** Low
**Location:** `scripts/crb-materialize.py:515-528`, `:371-374`; remedy printed at `runs/review-arms/crb-pipeline/run-host.sh:450-454`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (constant-factor setup cost) / Cold path (once per slug, before any sweep)
**Confidence:** High
**Baseline:** the five materialized pilot clones total **670 MB on disk** (`clone_mb` sum over
`runs/review-arms/crb/instances.json`, per fact-check Claim 1 — Mostly Accurate); depth-50
shallow clones; `--all` projected ~13 GB with baselines against 280 GB free (predecessor,
measured this host).

R1's fix was correct and I am not relitigating it — the security argument for deleting the
in-place baseline path is sound. Its throughput consequence should be stated where the sweep is
scheduled: every one of the five existing pilot clones now has to be **re-downloaded from its
fork**, not re-baselined locally, because that is the only remedy `run-host.sh:450-454` and
`restore_clone` will name. That converts a few seconds of local tar work into a network fetch of
five repos (33–195 MB each on disk), and for `--all` it is the full initial materialization.
Cold path, once, and it must complete before the pilot — so it belongs in the sweep window's
schedule, not in its budget.

**Recommendation:** No code change. Run the re-materialization before the sweep window opens
rather than inside it, and note the wall-clock in the setup doc so the next operator sizes it.

---

#### The sweep-budget gate is O(N²) over the sweep, and it is now free with measured headroom

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:407-434`
**Move:** Count the hidden multiplications
**Classification:** Micro (repeated small file reads) / Hot path (per-cell)
**Confidence:** High
**Baseline:** **15 ms per call** against a 50-cell × 2-attempt fixture; **0.71 s for 50
sequential calls** — measured by me on this host, 2026-08-19.

The gate re-scans `os.listdir($OUT)` and re-parses every cell's `attempts.jsonl` on every
iteration, so a 50-cell sweep does ~2,550 ledger-line parses instead of 100. This is the cost
question the scope asked about A7's fix, and the answer is that it is free with four orders of
magnitude of headroom against a 4.5–10.8 minute cell. Two structural notes for the future: it
now runs on *skipped* iterations too (in the current no-baseline state all 50 iterations would
call it, ~0.7 s total), and it prints a "sweep spend so far" line on each, so a 50-cell sweep
gains 50 lines of stdout. Neither is worth changing.

**Recommendation:** No action. If `attempts.jsonl` ever grows to per-turn records, keep a
running total in the shell and re-derive from disk only on resume.

---

## Endorsements

- The no-`result.json` path reaches the ledger, so `MAX_ATTEMPTS` at `:493` can actually bound
  it: I ran the transcript reducer (`:567-585`) against a result-free transcript and then the
  ledger heredoc (`:591-601`) against the resulting missing file — one row appended,
  `grep -c .` → 1. `[fact-check: claim 17 — Verified]`
- The liveness probe is placed after `--restore` and before the paid container, and the sidecar
  it guards really is `--restart no`, so the probe's premise holds.
  `[fact-check: claim 18 — Verified]`
- `sweep_spend_ok` is the first statement of the loop body, ahead of all five `continue`s in
  it, and its 15 ms cost at 50 cells × 2 attempts leaves the money gate's placement free.
  `[read: runs/review-arms/crb-pipeline/run-host.sh:407-455, 462-496, 515-520 + the heredoc body
  timed against a 50-cell fixture]`
- Moving the ledger to `:591` puts it above both `exit 4` aborts (harvest `:611`, audit `:641`),
  and `attempts.jsonl` has exactly one writer in the file, unconditional and outside any nested
  loop — so no path double-appends. `[read: runs/review-arms/crb-pipeline/run-host.sh:591-601,
  609-611, 632-656 + `grep -n attempts.jsonl` over the whole file]`
- Extracting the preflight verdicts into `scripts/crb-egress-verdict.sh` adds five short bash
  forks once per sweep and nothing per cell, so the testability win is bought at no
  throughput cost. `[read: scripts/crb-egress-verdict.sh:1-94 +
  runs/review-arms/crb-pipeline/run-host.sh:216-252]`

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Unmeasurable spend still ledgered `$0`; `SWEEP_BUDGET` blind to up to $2,500 | Medium | `run-host.sh:591-601` | High |
| 2 | `MAX_ATTEMPTS` counts non-spending docker failures, retiring cells | Medium | `run-host.sh:546-560,591-601` | Medium |
| 3 | Liveness probe is one un-retried sample that aborts the sweep | Low | `run-host.sh:521-529` | Medium |
| 4 | Transcript reducer is the one unguarded step above the ledger | Low | `run-host.sh:567-585` | High / Low reach |
| 5 | `PREFLIGHT_ONLY=1` bills a turn no artifact records; writes no `run-meta.json` | Low | `run-host.sh:262-300,396` | High |
| 6 | Audit forks one `merge-base` per stray commit, unbounded | Low | `crb-audit-clone.sh:88-99` | High |
| 7 | `--snapshot` deletion makes a full re-clone the mandatory setup step | Low | `crb-materialize.py:515-528` | High |
| 8 | Budget gate is O(N²) — measured free (15 ms/call, 0.71 s/sweep) | Informational | `run-host.sh:407-434` | High |

---

## Overall Assessment

**All three claimed closures hold.** A6's guard is genuinely reachable on the path that
matters — I executed the two-step reduce/ledger sequence against a result-free transcript and
watched the counter increment. A7's gate is the first statement of the loop body and costs
15 ms per call at full sweep size, so the "is it still free at 50 cells" question is answered
with three orders of magnitude to spare. The liveness probe is placed exactly where it prevents
the failure it targets, and it converts the sidecar's death from "43 remaining cells fail
silently" into "stop at the next one" for about 1% of a cell. `4624c5d`'s ledger move closes the
abort-path leak the fact-check's Claim 20 scope note named, with one writer, no double-append,
and one remaining unguarded statement above it (Finding 4, a single `|| true`). The measured
per-cell overhead rises from ≈2–3 s to ≈3–5 s — still 0.5–1.9% of a $10–40, 4.5–10.8 minute
cell, about 3 minutes across a full sweep. On compute, disk and sweep throughput these commits
are free.

What is left is narrower than what came in, and it is one theme: **the harness now bounds bad
attempts but still cannot price them.** A cell that dies mid-review ledgers `$0`, so the
ceiling that stops the sweep is reading a number that can be low by up to $2,500 (Finding 1);
and because the counter is type-blind, a docker-level failure that spent nothing consumes the
same budget as one that spent $25, so two infrastructure hiccups can quietly drop a cell from
the judged denominator (Finding 2). Both are the same three-line fix — a `cost_usd: null` plus a
`subtype` on the no-result row, read by `sweep_spend_ok` and `write_run_meta` — and both are
verifiable on this host at $0 with no docker. Neither is a structural problem; nothing here
argues for restructuring. **Nothing in my domain blocks the paid sweep**, but I would take
Findings 1, 2 and 4 before it, because they are cheap and because they are precisely the
instruments an operator will read when deciding whether the pilot's number is trustworthy
enough to authorize `--all`. No profiling is needed for any finding: the numbers that matter
are measured, and what remains unmeasurable is the docker layer, which the design deliberately
defers to its own preflight.

## Goal-Alignment Note
- Answered: yes — all three closures verified (A6 by execution), residual cost exposure narrowed to a `$0`-ledger accounting gap
- Out of scope: security properties of the allowlist and the audit's detection coverage; correctness of the fact-check's Incorrect verdicts (accepted as given); anything requiring docker execution (no docker on this host); commit `197eec6` (already reviewed)
- Escalate: (a) Findings 1+2 are one three-line, $0-verifiable change and are what makes the pilot's cost number trustworthy — worth taking before the sweep rather than carrying a fourth time; (b) the scope brief says the egress preflight now launches **five** containers — it launches **four** (leg 0 asserts a string, no container), so any doc quoting five should be corrected; (c) `4624c5d` has no fact-check coverage at all — the ledger-move claims above are my reading, not a verified verdict.
