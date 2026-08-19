# Performance Review — CRB direction-1 harness, iteration 2 (`59733d8..HEAD`)

**Scope:** `git diff 59733d8..HEAD -- . ':!docs/reviews'` — commits cf6e7c9, 5bd0b09, 46a5f17
**Date:** 2026-08-18
**Based on:** the k=3 code-fact-check of this pass (`docs/reviews/code-fact-check-report-r{1,2,3}.md`, summarised in the review brief); all Incorrect findings were doc/comment mechanism errors closed in 46a5f17.
**Measurements taken for this review:** all timings below were executed by me on this machine against the five real pilot clones in `external/crb-eval/` (33–243 MB on disk, 8.5–74 MiB packs) and the 32 `result.json` files under `runs/review-arms/`. Where I state a number, I ran it; where I could not, the finding carries the speculative disclaimer.

## Data Flow and Hot Paths

`run-host.sh` iterates `INSTANCES` (5 for the pilot, 50 for the full sweep), one **cell** per iteration. Per cell:

1. `crb-cell-status.py` decides whether an existing `result.json` counts as complete (skip vs re-pay).
2. `crb-materialize.py --reset <slug>` — pre-run containment reset (`reset_clone` + `verify_containment`).
3. `docker run … claude -p "/code-review main"` — **the only expensive step**. Measured on the 32 in-repo `result.json` files: min 80 s, **median 161 s**, max 327 s wall, $8–18 billed each; the brief budgets $10–40 per cell.
4. Harvest (`git status --porcelain=v1 -z` walk + copy), post-run `--reset` (identical work to step 2), attempt ledger append, sweep-budget gate.

The **only hot path in this diff is the per-cell loop body**, and it is hot in the cost sense (dollars per iteration), not the latency sense — 50 iterations total, each dominated by a ~3-minute container. Everything else (`attrition()`, `write_run_meta`) is a cold, once-per-invocation path. That asymmetry is what drives the calibration below: findings that waste a *cell* are severe; findings that waste *seconds* are not, however many times they repeat.

Data sizes: 50 clones, 33–243 MB on disk, 3.8k–17.1k tracked files, packs 8.5–74 MiB. Manifest and `run-meta.json` are ≤50 records.

---

## Findings

#### Every existing clone fails the new pre-run containment reset — sweep throughput is zero, and recovery costs a 6–7 GB re-clone

**Severity:** High
**Location:** `scripts/crb-materialize.py:329-338` (`reset_clone` order), `scripts/crb-materialize.py:289-312` (`scrub_object_store`), `scripts/crb-materialize.py:399-417` (materialize ordering fix), `runs/review-arms/crb-pipeline/run-host.sh:262-264`
**Move:** Price the deployment environment (move 10) — the platform here is the on-disk clone population the sweep is deployed against
**Classification:** Macro (structural — a guard that rejects 100% of the input population) / Cold path (per-cell setup) — **escalated to High** because the observable outcome is zero paid throughput on a $50–2000 operation, and the recovery cost is bandwidth-bound, not code-bound
**Confidence:** High — reproduced by execution on all five clones
**Baseline:** measured — **5 of 5 pilot clones fail**; `python3 scripts/crb-materialize.py --reset <slug>` exits 1 in 0.06 s for every slug in `external/crb-eval/`

`reset_clone()` runs `fetch_traces()` *before* `scrub_object_store()`, by design (scrubbing first would erase the evidence the check looks for). But `fetch_traces()` now voids on two conditions that every clone materialized before this diff already carries: a leftover `.git/FETCH_HEAD`, and the dangling `refs/remotes/origin/HEAD` symref that the pre-fix ref-pruning order left behind. Verbatim, from `scripts/crb-materialize.py:240-263`:

```python
    traces = []
    if (dst / ".git" / "FETCH_HEAD").exists():
        traces.append("FETCH_HEAD present — something fetched into this clone")
    …
    errors = [l for l in out.splitlines() if l.startswith("error:")]
    if errors:
        traces.append(f"git fsck reported {len(errors)} error(s), first: "
                      f"{errors[0][:160]} — cannot certify containment")
```

Executed against the real clones:

```
$ python3 scripts/crb-materialize.py --reset sentry-greptile-PR5
  !! sentry-greptile-PR5: CONTAINMENT CHECK FAILED — sentry-greptile-PR5: FETCH_HEAD present
  — something fetched into this clone; git fsck reported 1 error(s), first: error:
  refs/remotes/origin/HEAD: invalid sha1 pointer 0000…0000 — cannot certify containment
  — containment is broken
```

All five clones show both conditions (`FETCH_HEAD present` + the same `invalid sha1 pointer`). In `run-host.sh:262-264` the pre-run `--reset` failure `continue`s the cell as `skipped_bad`, so **every cell is skipped, `ran=0`, and the script exits 3** ("NO CELL RAN"). The sweep spends $0 and produces nothing — which is the safe direction, but it means the pilot cannot start.

The sharper point is that the healer already exists and is unreachable. `scrub_object_store()` at `scripts/crb-materialize.py:305-312` opens with:

```python
    # Heals a clone materialized before the remote-removal ordering fix, whose
    # refs/remotes/origin/HEAD symref was left dangling. for-each-ref does not
    # list a broken ref, so the ref-pruning loop cannot reach it.
    subprocess.run(["git", "symbolic-ref", "-d", "refs/remotes/origin/HEAD"], …)
```

I verified by execution that calling `scrub_object_store()` directly on a copy of `cal_com-PR11059` in the broken state clears both the fsck error and `FETCH_HEAD` in one call — but `reset_clone()` raises before ever reaching it, so the heal fires only for clones that do not need it.

**Recommendation:** Do **not** reorder the scrub ahead of the check — that would defeat the containment guard. Add an explicit one-shot migration instead: a `--heal-legacy SLUG…` mode (or a documented `--force` re-materialize) that recognises the two pre-fix signatures specifically, plus a preflight in `run-host.sh` that runs `--verify` over all requested slugs *before* the first container starts, so the operator learns this at $0 rather than after 50 skipped cells. Re-materializing instead costs ~1 GB of clone traffic for the pilot and 6–7 GB for the full 50; budget that before the sweep, not during it.

---

#### A cell that dies before emitting a `result` event retries without bound, and its spend is ledgered as $0

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:238-252` (the `MAX_ATTEMPTS` guard), `:294-312` (harvest), `:389-399` (attempt ledger), `:404-429` (sweep gate)
**Move:** Count the hidden multiplications — the multiplier here is sweep restarts, and each unit of work costs $10–40
**Classification:** Macro (unbounded retry with no terminating condition) / Hot path (the per-cell loop body, the only path that spends money)
**Confidence:** High for the control-flow trace; Medium for how often a cell actually dies this way
**Baseline:** measured — per-cell billed spend on the 32 in-repo results is $8.01–$18.24, so one un-metered retry is worth roughly one median cell; `no baseline available — flagged as speculative` for the *frequency* of result-event-less exits, which has not been observed in this repo's arms

The retry ceiling is nested inside an existence test for `result.json`:

```bash
  if [ -s "$dest/result.json" ]; then
    …
    if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
      echo "=== $id — $attempts failed attempt(s), at MAX_ATTEMPTS — skipping …" >&2
```

But the harvester only writes `result.json` when it finds a `result` event:

```python
if res is None:
    print("  !! no result event — treat this instance as failed", file=sys.stderr)
    sys.exit(0)
json.dump(res, open(sys.argv[2], "w"))
```

So a container killed mid-run (OOM, host reboot, `docker` failure, a stream truncated before the final event) leaves no `result.json`. `attempts.jsonl` still grows — the ledger step tolerates the missing file and writes `{"cost_usd": 0, …}` — but nothing ever reads it, because the guard that would is gated on the file that was never written. Every subsequent sweep re-runs that cell from scratch, forever. Two costs compound: the tokens are paid each time, and the sweep-budget gate sums `cost_usd` from that same ledger, so the spend is recorded as **$0** and does not count toward `SWEEP_BUDGET`. The one class of failure that can burn money repeatedly is exactly the class the aggregate ceiling cannot see.

Note on scope: the enclosing `if [ -s "$dest/result.json" ]` guard predates this diff. It is raised here because this diff reworks the completion predicate that sits directly above it and inherits the same gate, and because it is the sharpest answer to "anything that makes a retried sweep re-pay for work already done."

**Recommendation:** Hoist the attempt-count check out of the `result.json` existence test so it runs whenever `attempts.jsonl` exists. Separately, have the harvester write a minimal `result.json` (`{"is_error": true, "subtype": "no_result_event"}`) when `res is None`, so the cell is visible to both the predicate and the ledger; and record the container's non-zero exit in the attempt record so a $0 cost is distinguishable from an unmeasured one.

---

#### `SWEEP_BUDGET` is a lifetime-of-directory ceiling, not a per-invocation one — a resumed sweep pays one extra cell before halting again

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:404-429`, `:62-68`
**Move:** Find the work that moved to the wrong place — the aggregate moved from "this run" to "this directory", which is the right place for auditing and the wrong place for a ceiling
**Classification:** Macro (cost-governance semantics, not a constant factor) / Hot path (evaluated after every paid cell)
**Confidence:** High
**Baseline:** measured — the gate is exact and cheap; a synthetic 50-cell `$OUT` at $12.50/cell sums to `$625.00` in **0.021 s** per invocation

The gate walks every directory under `$OUT`, not the cells of this run:

```python
out, cap = sys.argv[1], float(sys.argv[2])
total = 0.0
for name in sorted(os.listdir(out)):
    ledger = os.path.join(out, name, "attempts.jsonl")
```

That is deliberate ("survives both a resumed sweep and re-run cells") and correct for the audit trail, but it makes the ceiling monotonic in the directory's whole history. Two consequences with real money attached. First, the $50–200 pilot's spend counts against the default `SWEEP_BUDGET=250` when the operator later runs `--all` into the same `$OUT` — the full sweep halts almost immediately unless the ceiling is raised, which is survivable but silently converts the "raise it for `--all`" instruction into "raise it by pilot-spend + full-sweep estimate". Second, and worse: cells that are *skipped* as already-complete `continue` before the gate, so on a resume the gate is first evaluated only after the first genuinely-new cell has already been paid for. If the historical total already exceeds the cap, each resume attempt costs one more cell ($8–18 measured, $10–40 budgeted) before halting again. Restarting a halted sweep three times to nudge the ceiling costs three cells.

**Recommendation:** Evaluate the gate once *before* the first container of the run as well as after each cell, so a resume that is already over the ceiling halts at $0 instead of at one cell. Consider reporting both numbers in the gate's log line — `spend this run: $X (directory total $Y) / $cap` — so the operator can see which one is binding.

---

#### A post-run containment void leaves the clone un-reset, so the cell is permanently dead and the PR silently leaves the denominator

**Severity:** Medium
**Location:** `scripts/crb-materialize.py:329-343` (raises before any reset work), `runs/review-arms/crb-pipeline/run-host.sh:359-372`
**Move:** Trace the resource lifecycle — the resource is a 33–243 MB clone whose only reset path is the code that just refused to run
**Classification:** Macro (a per-instance resource enters an absorbing failed state) / Hot path (per-cell)
**Confidence:** High for the control flow; Medium for how often real agent behaviour trips `foreign` or a fetch trace
**Baseline:** measured — one lost cell is $8.01–$18.24 of already-billed spend (32 in-repo results), plus a 33–243 MB re-clone to recover; `no baseline available — flagged as speculative` for the void rate

`reset_clone()` raises on a surviving remote, a fetch trace, or a foreign commit *before* it performs any of the `checkout --force` / `reset --hard` / `clean -qfdx` / `scrub_object_store()` work. So when the post-run `--reset` voids a cell, the contaminated clone is left exactly as the agent left it. The next sweep's pre-run `--reset` re-reads the same state, raises the same error, and the cell is counted `skipped_bad` — permanently, across every future sweep, with no message telling the operator that `rm -rf` plus a re-materialize is the fix (the `MAX_ATTEMPTS` path does say "delete `$dest` to reset"; this path says nothing equivalent about the clone).

The money is already sunk, so this is not a re-pay finding — it is a denominator finding. The PR drops out of the judged subset, which the new `attrition()` block does now surface (good), but the sweep silently loses capacity it cannot regain in-place.

**Recommendation:** On a post-run void, either quarantine the clone (rename it aside) or emit an explicit remediation line naming the exact command — `scripts/crb-materialize.py --slug <id> --force`. If quarantining, note that this reintroduces the disk cost of a second copy; the cheaper option is the message.

---

#### Per-cell containment machinery costs ~1.6 s against a 161 s median cell — immaterial, and `--connectivity-only` does earn its keep

**Severity:** Low
**Location:** `scripts/crb-materialize.py:243-248`, `:289-312`, `:315-367`; `runs/review-arms/crb-pipeline/run-host.sh:262-264`, `:359`
**Move:** Count the hidden multiplications — and then check the product against the real denominator
**Classification:** Micro (fixed per-call host-side git work) / Hot path (twice per cell)
**Confidence:** High — measured directly
**Baseline:** measured — full `reset_clone()` + `verify_containment()` on the two largest pilot clones: **0.61 s** (`cal_com-PR11059`, 74 MiB pack, 206 MB tree) and **0.75 s** (`sentry-greptile-PR5`, 30 MiB pack, 17k files); against a **median cell duration of 161 s** across the 32 in-repo `result.json` files

Component breakdown (`cal_com` / `sentry`, seconds):

| op | cal_com | sentry |
|---|---|---|
| `fsck --unreachable --no-reflogs --connectivity-only` | 0.013 | 0.024 |
| *(same fsck **without** `--connectivity-only`)* | *0.724* | *0.814* |
| `status --porcelain` | 0.259 | 0.442 |
| `gc --quiet --prune=now` | 0.301 | 0.188 |
| everything else combined | 0.037 | 0.093 |
| **total per `--reset`** | **0.610** | **0.747** |

Two calls per cell puts the containment tax at **1.2–1.5 s on a 161 s median cell, ≈0.9%**, and ~75 s across a full 50-cell sweep. It costs no API dollars. The `git gc --prune=now` concern in the brief does not survive measurement: the clones' *packs* are 8.5–74 MiB even though the directories are 33–243 MB (the working tree is the bulk), so the repack is 0.19–0.30 s, not the minutes a 195 MB object store would imply. A post-agent reset (12 new files, 480 KB, one commit) measured **0.37 s** — cheaper than the clean-clone case, since `gc` had already run.

On the specific question: **`--connectivity-only` is doing what the comment claims.** It cuts the fsck from 0.72–0.81 s to 0.013–0.024 s — a 30–55x reduction, consistent with skipping per-object SHA-1 content validation. The saving is real and the reasoning is sound; it is simply saving 1.6 s per cell out of 161 s, so it is a correctness-preserving nicety rather than a load-bearing optimisation.

**Recommendation:** No change. If the redundancy still grates, the pre-run `--reset` could be skipped when the immediately-preceding post-run `--reset` on the same slug succeeded within the same process — but that would trade a verified invariant for ~0.7 s per cell and is not worth it.

---

#### Three per-cell/per-sweep overheads flagged in the brief, all measured and all immaterial

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:233` (cell-status subprocess), `:404-429` (sweep gate), `scripts/crb-subset-leaderboard.py:646-687` and `:734` (`attrition`)
**Move:** Ask "what's the size of N?" — N is 50, and every structure here is linear or quadratic in 50 over kilobyte files
**Classification:** Micro / Cold-to-warm (all three sit beside a 161 s container or in a once-per-run CLI)
**Confidence:** High — measured
**Baseline:** measured, individually below, against the 161 s median cell duration

- **`crb-cell-status.py` as a subprocess instead of inline:** **0.020 s** per invocation, once per cell, ≤1 s across a 50-cell sweep. That is 0.012% of a median cell. The extraction bought fixtures (`test/crb-cell-status.bats`) for the predicate that decides whether to re-pay $10–40; the trade is overwhelmingly correct.
- **Sweep-budget gate re-summing every cell's `attempts.jsonl` after every cell (O(cells²)):** **0.021 s** per invocation on a synthetic 50-cell `$OUT`; **0.71 s** for all 50 invocations of a full sweep, python startup included. At N=50 the quadratic term is 2500 reads of 1–2-line files. It would need N in the thousands to matter, and the sweep is capped at 50 PRs by the dataset.
- **`attrition()` reading run-meta and the manifest on every invocation:** it is called **once**, from `main()` (`att_lines, _checked = attrition(our_urls, Path(args.run_meta))`), in a CLI that runs once per results write-up. Both files are ≤50 records. There is no per-row re-read to eliminate.

**Recommendation:** No action on any of the three. If a future variant ever fans the leaderboard out per-PR, hoist the manifest read out of `attrition()` then — not now.

---

## Endorsements

- The completion predicate's two length constants sit in an empirically empty band with wide margin on both sides: `MIN_REVIEW_LEN = 200` and `STUB_MAX_LEN = 300` against a corpus whose stubs are 51 and 56 characters and whose shortest genuine review is 1,208 — 4x above the stub ceiling and 4x below the shortest real body, so neither the false-complete nor the re-pay direction is close to firing on the measured corpus. `[read: scripts/crb-cell-status.py:278-300 plus the 32 result.json bodies under runs/review-arms/, whose lengths I enumerated]`
- Cost is summed over `attempts.jsonl` rather than the overwritable `result.json` in both the sweep gate and `run-meta.json`, which is the arrangement that makes a retried cell's earlier paid attempts visible to the ceiling rather than silently forgotten. `[read: runs/review-arms/crb-pipeline/run-host.sh:176-199, 389-399, 404-419]`
- Moving `write_run_meta` into an `EXIT` trap means the `SWEEP_BUDGET` halt — which exits 2 from inside the loop — still writes the provenance file the operator needs to decide whether to raise the ceiling. `[read: runs/review-arms/crb-pipeline/run-host.sh:159-220, 404, 432]`
- The `--reset` code path returns from `main()` before `load_prs()`, so a per-cell reset never parses the benchmark dataset — the per-cell python cost is manifest-only. `[read: scripts/crb-materialize.py:463-501]`
- Skipping already-complete cells `continue`s before both the container and the budget gate, so a resumed sweep pays nothing for work it recognises as done. `[unverified — submitted as claim]` — claim: on a resume, a cell whose `result.json` passes `crb-cell-status.py` starts no container and appends no ledger line.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Every existing clone fails the pre-run reset; zero cells run, recovery is a 6–7 GB re-clone | High | `scripts/crb-materialize.py:329-338` | High |
| 2 | Cell with no `result` event retries unboundedly and is ledgered as $0 | High | `run-host.sh:238-252, 294-312` | High |
| 3 | `SWEEP_BUDGET` is a directory-lifetime ceiling; a resume pays one cell before re-halting | Medium | `run-host.sh:404-429` | High |
| 4 | Post-run void leaves the clone un-reset; cell permanently dead, no remediation message | Medium | `crb-materialize.py:329-343` | High |
| 5 | Containment machinery ≈1.4 s/cell vs 161 s median (0.9%); `--connectivity-only` saves 30–55x | Low | `crb-materialize.py:243-248` | High |
| 6 | cell-status subprocess (0.020 s), O(cells²) gate (0.71 s/sweep), `attrition()` (called once) | Informational | `run-host.sh:233, 404` | High |

## Overall Assessment

The performance posture of the *changed code itself* is good, and the three overheads the brief was most worried about are, on measurement, noise: the containment machinery costs about 0.9% of a cell, the extracted status predicate costs 0.02 s, and the quadratic budget gate costs 0.71 seconds across an entire 50-cell sweep. `--connectivity-only` is genuinely load-bearing for keeping fsck cheap (30–55x), and the `git gc` worry rests on a size confusion — the packs are 8.5–74 MiB, not the 33–243 MB of the directories. None of that should hold up the sweep.

What should hold up the sweep is finding 1: **the harness as committed cannot run a single cell against any clone that currently exists on disk.** All five pilot clones carry the two pre-fix signatures (`FETCH_HEAD`, dangling `refs/remotes/origin/HEAD`) that `fetch_traces()` now treats as contamination, and the healer written for exactly that case is unreachable because the check that fires precedes it. The failure is safe — $0 spent, exit 3 — but it is discovered only after the operator has set up a sweep, and the fix is bandwidth (6–7 GB) rather than code. Fix that first, and add the `--verify`-all preflight so the next such migration surfaces at $0.

The two cost-governance findings (2 and 3) are the ones that matter for a $500–2000 operation: the aggregate ceiling cannot see spend from cells that die before emitting a result event, and those same cells retry without limit; and the ceiling's directory-lifetime semantics make each resume attempt cost a cell. Both are fixable in place with a few lines — hoist the attempt check out of the `result.json` guard, write a stub result on `res is None`, and evaluate the gate once before the first container. No profiling is needed to confirm anything here; every number in this review was measured, and the remaining uncertainty is frequency (how often a cell dies without a result event, how often a cell voids), not magnitude.

## Goal-Alignment Note
- Answered: yes — all five questions in the brief answered with measured numbers, plus one blocking issue found by execution.
- Out of scope: container/npx startup cost per cell and the `INST_HOME` payload copy (unchanged by this diff); the judge and injector stages downstream of `run-meta.json`; the egress-allowlist control (R3) referenced in `fetch_traces()`, which is a security not a performance control.
- Escalate: finding 1 blocks the pilot outright and is not a code fix — the orchestrator should decide between a one-shot `--heal-legacy` mode and a `--force` re-materialize of all clones, and should budget the 6–7 GB before scheduling the sweep. Findings 2 and 3 are small edits but touch cost governance, so they belong in the same pass as any other budget-gate change rather than being split across iterations. Working copies I made under `/workspace/.scratch/perf/` (two clone copies, ~450 MB) can be deleted.
