# Performance Review — `feat/crb-direction1-harness` (pass 2, fix commit)

**Commit:** ed68ced
**Scope:** `git diff 529ecd2..ed68ced` — code under review: `runs/review-arms/crb-pipeline/run-host.sh`,
`scripts/crb-materialize.py`, `scripts/crb-pipeline-to-benchmark.py`, `scripts/crb-subset-leaderboard.py`,
`.gitignore`, `test/crb-injector-sections.bats`. Everything at or before `529ecd2` is context only.
**Date:** 2026-08-18
**Based on:** the pass-1 performance review at this same path (`Commit: 529ecd2`) and the rubric
`docs/reviews/code-review-rubric-2026-08-18-feat-crb-direction1-harness.md`

> ⚠️ **No code fact-check report provided for this pass.** Pass 1 was based on a merged k=3
> fact-check of `529ecd2`; the fix commit's own comments and doc claims have not been independently
> re-verified. Where a claim in this diff is contradicted by the code, I say so and show the
> verbatim lines, but treat that as a performance reviewer's incidental catch, not a fact-check.

## Calibration note (unchanged from pass 1)

Batch research tooling. CPU time is irrelevant; **money and failure economics dominate**. A sweep is
projected at $500–2000. Micro-optimization is noise and I record it as such rather than padding the
list. Two things changed the evidence base since pass 1 and both are used below:

1. `runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json` is a **real budget-exhausted cell**
   already in this repo — `is_error: true`, `subtype: "error_max_budget_usd"`, `num_turns: 1`,
   `total_cost_usd: 15.24`, `result` empty. Pass 1 flagged the budget-exhaustion payload as
   unverifiable; it is verifiable, and it settles A2.
2. `docs/working/crb-direction1-setup.md:192-194` now states the pilot estimate as **$50–200**,
   which is the number the new `SWEEP_BUDGET` default has to be judged against.

## Data Flow and Hot Paths

Unchanged in shape. The one stage that costs money is `run-host.sh`'s `for` loop; the fix commit
adds four things inside that loop (pre-run containment guard, post-run containment guard, a tightened
resume predicate, an aggregate budget gate) and rewrites the harvest pipeline. Everything else in the
diff is $0 setup, plus a generated `judge.sh` that fronts the paid judging steps. N is 5 (pilot) or 50.

---

## Verdicts on prior findings

| Prior | Claim | Verdict |
|---|---|---|
| A1 | Sweep-level budget ceiling | **Partially closed** — gate is correctly wired, but the default halts the pilot, the sum forgets retried spend, and `exit 2` skips `run-meta.json` (F3, F4, F6) |
| A2 | Errored cells banked as complete | **Closed** — verified against a real `error_max_budget_usd` payload in-repo. Residual: no retry cap (F3) |
| A3 | Judge seeding fails open | **Closed** — all three paths verified |
| A17 | Failed materialization leaks a clone | **Not closed** — untouched by this commit |
| A18 | First-instance canary | **Not closed** — still a sentence in the setup doc |
| A19 | `--tool` confinement mechanical | **Partially closed** — `judge.sh` exists and the doc points at it; the script's own stdout and `RUN.md` still lead with the hand-typed commands |
| pass-1 #5 | Sequential sweep | Not addressed (correctly — pass 1 said pilot-first) |
| pass-1 #8 | `git clean` without `-x` | **Closed** (`-qfdx`), no meaningful re-run cost — see F9 |
| pass-1 #9 | Unbounded transcripts | **Partially closed** — now gitignored, size still unreported |
| pass-1 #10 | `npx` per container | Unchanged; still Informational |

Detail on each below, interleaved with the new findings by severity.

---

## Findings

### F1. A post-run containment failure only warns — and the cell it contaminates is then banked as a success by A2's own predicate

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:236-237`, interacting with `:150-159` and `:177-178`
**Move:** Find the work that moved to the wrong place (failure detection moved after banking)
**Classification:** Macro (silent contamination of the arm's measurement) / Cold path (batch sweep)
**Confidence:** High — this is a control-flow ordering fact, readable off the file
**Baseline:** $10–40 per instance (`docs/working/crb-direction1-setup.md:192`); the one measured
failed cell in-repo cost $15.24
**Legibility-target:** whoever writes up the arm's numbers — a contaminated cell must not be
indistinguishable from a clean one by the time it reaches `crb-pipeline-to-benchmark.py`

**Evidence:**

```
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" \
    || echo "$id: POST-RUN containment check FAILED — treat this cell's result as void" >&2
```

```
  if [ -s "$dest/result.json" ] && python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
ok = (d.get("num_turns", 0) > 0
      and not d.get("is_error")
      and d.get("subtype", "success") == "success")
sys.exit(0 if ok else 1)' "$dest/result.json" 2>/dev/null; then
    echo "=== $id — completed result exists, skipping (delete to re-run)"
    continue
  fi
```

and the doc's claim about the same code:

```
  materialize time but the clone is then mounted read-write into an agent
  container, so it is re-checked rather than assumed. A pre-run failure skips
  the cell; a post-run failure marks that cell's result void.
```

Nothing is marked. The post-run check emits a stderr line and the loop proceeds; `result.json` and
`review.md` are already on disk from `:199-217`, they satisfy the new success predicate (containment
is orthogonal to `is_error`/`subtype`), and the injector has no notion of a void cell. Worse, the
ordering means resume can never re-detect it: the skip predicate at `:150` runs **before** the
pre-run `--verify` at `:177`, so a contaminated-but-successful cell is `continue`d out at the top of
the loop and the pre-run guard never executes on it again. So this is the exact shape A2 was opened
about — paid work whose failure is recorded as success — reintroduced through a different door, and
the setup doc asserts the fix that the code does not implement.

The economics are the point: the failure mode being guarded against is "the reviewing agent fetched
the merged upstream fix", i.e. the answer key. A cell that did that does not just waste $20 — it
produces a *plausible high score* that silently invalidates the arm's headline result.

**Recommendation:** On post-run failure, `mv "$dest/result.json" "$dest/result.void.json"` (and the
same for `review.md`) before the warning, so the cell fails the skip predicate, is retried, and
cannot reach the injector. If a retry would just re-contaminate, write a `$dest/CONTAMINATED` marker
and have `crb-pipeline-to-benchmark.py` refuse to inject any cell that has one. Either way, move the
pre-run `--verify` above the skip predicate so resume re-checks banked cells at $0.

---

### F2. The rewritten harvest pipeline aborts the entire sweep, silently, on the first cell that produced no `.md`/`.json` output

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:222-231` (with `:49`)
**Move:** Count the hidden multiplications (one cell's non-result multiplied into N-cells-not-run)
**Classification:** Macro (loses the remainder of the sweep) / Cold path
**Confidence:** High — reproduced in an isolated bash script, see below
**Baseline:** $500–2000 for the 50-PR sweep (`docs/working/crb-direction1-setup.md:194`); the loss
is every cell after the aborting one, plus `run-meta.json` for the ones already paid for
**Legibility-target:** the unattended operator — a sweep that stops early must say why, and must
still leave the aggregate provenance file for the cells it did pay for

**Evidence:**

```
set -euo pipefail
```
```
  (cd "$clone" && git status --porcelain=v1 -z --untracked-files=all) \
    | tr '\0' '\n' | cut -c4- | grep -E '\.(md|json)$' \
    | while read -r f; do
```

`grep` exits 1 when it matches nothing. Under `pipefail` that becomes the pipeline's status, and
under `errexit` that terminates the script. Reproduced verbatim:

```
$ cat t.sh
#!/usr/bin/env bash
set -euo pipefail
for i in 1 2 3; do
  echo "cell $i"
  printf "a.txt\n" | grep -E "\.(md|json)$" | while read -r f; do echo "got $f"; done
  echo "  after harvest $i"
done
echo "REACHED END"
$ bash t.sh; echo "exit=$?"
cell 1
exit=1
```

No message, no `run-meta.json` (the meta block at `:271-290` is after the loop), remaining instances
never attempted. The structure predates this commit, but the fix commit rewrote these exact lines
and did not fix it, so it is in scope. What makes it more than a papercut is *which* cell triggers
it: "the pipeline ran, cost $20, and wrote no rubric" is the single failure mode the setup doc calls
the highest risk (`:249-253`) and the one A18's canary was supposed to catch. The harness's current
response to it is to die with a bare non-zero exit. That is an accidental canary with the worst
possible legibility.

**Recommendation:** `|| true` the grep, or restructure as
`mapfile -t files < <( ... | grep -E ... || true )` and iterate the array. Then, separately, make the
empty-artifact case explicit: if the harvest produced zero files **and** `review.md` is empty, print
`$id: produced no artifacts` and (per F5) count it toward a failed-cell tally.

---

### F3. Re-running a failed cell overwrites its `result.json`, so the new sweep-budget sum forgets money already spent — and there is no attempt cap

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:254-267`, `:199-217`, `:160-162`
**Move:** Question the cache (the on-disk `result.json` set *is* the spend ledger the gate reads)
**Classification:** Macro (unbounded aggregate spend survives the ceiling that was added to bound it) / Cold path
**Confidence:** High
**Baseline:** **measured** — `runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json`:
`total_cost_usd: 15.24`, `is_error: true`, `subtype: "error_max_budget_usd"`, `result` empty. That
is one real cell that cost $15.24 and produced nothing.
**Legibility-target:** the operator who re-invokes `run-host.sh` after a partial sweep — the running
total must be cumulative billed spend, not "spend currently represented on disk"

**Evidence:**

```
+  if [ -s "$dest/result.json" ]; then
+    echo "=== $id — prior result was incomplete/errored, re-running"
+  fi
```
```
json.dump(res, open(sys.argv[2], "w"))
```
```
for name in os.listdir(out):
    rp = os.path.join(out, name, "result.json")
    if os.path.isfile(rp):
        try:
            total += json.load(open(rp)).get("total_cost_usd") or 0
```

A2's fix is correct and I verify it as closed below — but it converts permanently-banked failures
into **repeatedly re-paid** failures, and A1's fix reads its running total from exactly the files
those retries clobber. Concretely, with the measured cell above: attempt 1 burns $15.24 and writes
`result.json`; the gate sees $15.24. Attempt 2 (a fresh `run-host.sh` invocation) re-runs the same
cell, burns another $15.24, and `json.dump` overwrites the file — the gate again sees $15.24. Ten
invocations against a deterministically-failing instance is $152 of real billing that `SWEEP_BUDGET`
never observes rising above $15.24. There is no attempt counter anywhere in the loop, and the two
cheap failure modes most likely to be deterministic (a diff too large for `--max-budget-usd $25`; an
instance whose review always errors) are precisely the ones that will be retried forever.

This is the one place where the two High fixes interact badly enough that fixing them independently
is not enough.

**Recommendation:** Never overwrite. Have the harvester write to `result.json` on success and
`result.attempt-N.json` on failure, and have the budget gate sum **every** `result*.json` under each
cell dir. Add an attempt cap (`[ "$(ls "$dest"/result.attempt-*.json 2>/dev/null | wc -l)" -lt 2 ] ||
{ echo "$id: 2 failed attempts, skipping"; continue; }`) so a deterministic failure costs at most
2 × `BUDGET`, not unbounded × `BUDGET`.

---

### F4. `SWEEP_BUDGET` defaults to $75 against the project's own $50–200 pilot estimate, and the abort path skips `run-meta.json`

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:62-65`, `:254`, `:271-290`
**Move:** Ask "what's the size of N?" (the ceiling has to be sized against the smallest legitimate unit of work)
**Classification:** Macro (mis-sized gate on the only paid loop) / Cold path
**Confidence:** High on the arithmetic; Medium on whether the halt is actually unwanted (it is
defensible as a deliberate speed bump — but then it should say so)
**Baseline:** `docs/working/crb-direction1-setup.md:192-194` — $10–40/instance, **5-PR pilot
$50–200**, all 50 $500–2000. `BUDGET` defaults to $25.00 (`:61`).
**Legibility-target:** the operator launching the pilot — hitting the ceiling should read as a
decision they made, not as a failure

**Evidence:**

```
SWEEP_BUDGET="${SWEEP_BUDGET:-75.00}"
```
```
| 5-PR pilot | **~$50–200** | above × 5, wide because of the keycloak-vs-sentry spread |
```
```
python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
```

Three separate sizing problems, in descending importance:

1. **The default lands inside the pilot's own estimate range.** At the doc's $10–40/instance, $75
   buys 1.9–7.5 cells. At the E8-derived $19–44, it buys 1.7–3.9. The 5-PR pilot — the smallest run
   anyone would sensibly do, and the run the whole plan is gated on — halts partway in most of the
   estimated range. The operator's remedy is to raise the variable and re-invoke, which per F3 also
   re-pays for any failed cell. A ceiling that fires on the expected path trains the operator to
   raise it reflexively, which is how ceilings stop working.
2. **The sum is lifetime-scoped, not sweep-scoped.** `os.listdir(out)` walks every cell dir ever
   written under `runs/review-arms/crb-pipeline/`, so a later 1-instance re-run inherits the pilot's
   accumulated $70 and trips immediately. That is arguably the intent ("survives a resumed sweep")
   but it is not what "sweep budget" reads as, and it is not documented.
3. **`exit 2` skips `run-meta.json`.** The meta block at `:271-290` is after the loop, so the abort
   path — the exact path where you most want the per-cell cost table — leaves you with no aggregate
   artifact for the cells you already paid for. The `trap` at `:88` only removes the payload tmpdir.

The gate itself is **correctly wired** and I want that on the record: `<<'EOF'` is part of the
`python3` command, `||` binds to it, `set -e` does not pre-empt the left side of `||`, the `{ ... }`
group is not a subshell, and the loop is not in a pipeline — so `exit 2` really does terminate the
script. Placement after the cell (rather than before) is right: with per-cell granularity the worst
overshoot is one `BUDGET`, making the effective hard ceiling `SWEEP_BUDGET + BUDGET` = $100 by
default. That should be stated in the comment, since $75 is not the number that bounds you.

**Recommendation:** Default `SWEEP_BUDGET` to something above the pilot's upper estimate (e.g. $250)
or derive it as `${#INSTANCES[@]} × 40` with an explicit `echo` of the computed ceiling at startup.
Move the `run-meta.json` block into an `EXIT` trap (or call it before `exit 2`). Scope the sum to
`"${INSTANCES[@]}"` rather than `os.listdir`, or rename the knob to reflect that it is a lifetime cap
on the output dir.

---

### F5. A pre-run guard failure `continue`s every cell — a fully broken sweep runs nothing and exits 0

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:177-178`, `:145`, `:268-290`
**Move:** Find the work that moved to the wrong place (validation added, but its failure has no aggregate)
**Classification:** Macro (whole-sweep no-op indistinguishable from success) / Cold path
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative (no measured rate of containment-guard
failures; the guard is new and has never run against a real post-review clone)
**Legibility-target:** anyone scripting around `run-host.sh` or reading its exit status — "0 cells
ran" must not exit 0

**Evidence:**

```
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2; continue; }
```
```
  [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/crb-materialize.py --slug $id" >&2; continue; }
```

Answering the specific questions asked: the `continue` does **not** create an infinite re-run loop —
it is a single forward pass per invocation, and skipping the budget gate on that path is correct
because no money was spent. The problem is the aggregate. `--verify` pins `head` to the manifest
value, so a clone whose `review` ref moved (which is exactly what a post-run contamination looks
like) fails the pre-run check on **every subsequent invocation, forever**, with no automatic
remediation and no remediation command in the message — unlike the sibling guard one line up at
`:145`, which does print the exact `crb-materialize.py --slug` fix. And if the guard fails
systematically (manifest/clone drift, a `--verify` bug, a `git` version difference), all N cells are
skipped, the loop ends, `run-meta.json` is written with zero or stale cells, and the script prints
`Next: ...` and exits **0**. An unattended operator or a wrapping script cannot tell that apart from
a clean resume.

**Recommendation:** Count skips and failures in the loop (`skipped=$((skipped+1))`), print
`ran=$ok skipped=$skipped of ${#INSTANCES[@]}` before `Next:`, and `exit 1` when `ok` is 0. Add the
remedy to the message: `run scripts/crb-materialize.py --force --slug $id to rebuild`.

---

### F6. The budget gate's `||` also fires on any Python exception, reporting it as "SWEEP BUDGET EXCEEDED"

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:254-267`
**Move:** Question the cache (a cache-read failure must not be indistinguishable from a cache hit)
**Classification:** Micro (one misleading message) / Cold path — but on the abort path, where
legibility is worth the most
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** the operator at 2am reading why the sweep stopped

**Evidence:**

```
python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
import json, os, sys
out, cap = sys.argv[1], float(sys.argv[2])
```

`SWEEP_BUDGET=none` (or any non-numeric), an unreadable `$OUT`, or a Python-not-found all exit
non-zero and print the budget message with a remedy ("raise SWEEP_BUDGET") that cannot possibly
help. Failing closed is the right economics — a gate that cannot evaluate should stop the spend —
but the message should not lie about why. Note the per-file `try/except: pass` inside the loop
already fails *open* on a corrupt `result.json` (that cell's cost silently drops out of the total),
which is the opposite bias to the outer handler; worth one line of thought about which you want.

**Recommendation:** Validate `SWEEP_BUDGET` once at the top (`[[ $SWEEP_BUDGET =~ ^[0-9.]+$ ]] || exit 1`)
and have the Python exit with distinct codes (1 = over budget, 3 = could not evaluate) so the shell
can print the right message.

---

### F7. `judge.sh` closes the transcription risk but does not replace the hand-run path in the script's own output

**Severity:** Low
**Location:** `scripts/crb-pipeline-to-benchmark.py:346-388` (generated `judge.sh`), `:305-330`
(`RUN.md`), `:389-393` (stdout "Next:" block)
**Move:** Find the contention point (which artifact the operator actually copies from)
**Classification:** Macro-in-consequence (the ~2233-call step 2.5 risk) / Cold path
**Confidence:** High
**Baseline:** ~2233 paid LLM calls at step 2.5 if `--tool` is dropped, per this commit's own
corrected comment (`:296-303`); ~$13–22 for the correctly-scoped 50-PR judge pass
(`docs/working/crb-direction1-setup.md:196`)
**Legibility-target:** the operator running stage 4 — there should be one obviously-correct thing to
type, not three sources of truth

**Evidence:**

```
+    judge_path = out / "judge.sh"
+    judge_path.write_text(judge_sh)
+    judge_path.chmod(0o755)
+    print(f"Wrote {judge_path} (executable — prefer it over hand-running the steps)")
     print(f"\nNext (from {out}, with MARTIAN_* env set — see "
           f"docs/working/crb-direction1-setup.md):")
     for step in ("step2_extract_comments", "step2_5_dedup_candidates", "step3_judge_comments"):
```

A19 is genuinely mostly closed: `judge.sh` bakes `--tool "{args.tool_name}"` into all three steps,
runs under `set -euo pipefail`, is chmod 755, and the setup doc now leads with it
(`crb-direction1-setup.md:145-150`). The human step is removed for anyone who runs it. What is left
is that the script's own last words are still the three hand-typed commands, and `RUN.md` — written
*before* `judge.sh` and unchanged by this commit — is still a bash block to copy. Three artifacts
now describe the same paid operation, and the two an operator sees first are the risky ones.

Two smaller things inside `judge.sh` itself, both cheap and both fail-fast (so Low, not higher):
`export PYTHONPATH="${{PYTHONPATH:-{BENCH}}}"` silently declines to add `BENCH` for anyone who
already has `PYTHONPATH` set for something else, and the steps invoke `python`, not `python3`.
Neither costs money — they fail before the first API call — but they turn a $0 setup error into a
confusing one.

Also worth verifying before the first paid judge run, because `judge.sh` is a `set -e` script that
always starts from step 2: **is step 2.5 resumable?** The commit's own comment says no
`dedup_groups.json` is checked in. If step 2.5 does not skip pairs it has already deduped, then a
`judge.sh` that dies in step 3 re-pays for step 2.5 on the next invocation. Steps 2 and 3 are
protected by the seeded files; 2.5 is the one with no cache, and it is the one with the 2233-call
worst case.

**Recommendation:** Replace the "Next:" stdout block and `RUN.md`'s bash block with
`bash {out}/judge.sh` (keep the individual commands below, under a "if you need to run a step by
hand" heading). Use `python3` and `export PYTHONPATH="{BENCH}${{PYTHONPATH:+:$PYTHONPATH}}"`. Confirm
step 2.5's resume behaviour and, if it is not resumable, note it in the generated header.

---

### F8. A17 (leaked clone on failed materialization) and A18 (first-instance canary) are not addressed

**Severity:** Medium (carried forward at pass-1 severity)
**Location:** `scripts/crb-materialize.py:197-202`, `:320-325`; `runs/review-arms/crb-pipeline/run-host.sh:143`
**Move:** Trace the memory lifecycle (disk) / validation before payment
**Classification:** Macro / Cold path
**Confidence:** High — these lines are byte-identical to `529ecd2`
**Baseline:** 670 MB across the 5-PR pilot, 33–195 MB per clone (`runs/review-arms/crb/instances.json`);
~6.7 GB for `--all`. $500–2000 for a 50-PR sweep.
**Legibility-target:** the pass-3 reviewer and the orchestrator's rubric — these should not be marked
green

**Evidence:**

```
    if dst.exists():
        if not force:
            print(f"{slug}: exists, skipping (use --force to rebuild)")
            return None
        shutil.rmtree(dst)
```
```
        except Exception as e:  # keep going; one bad fork shouldn't stop a sweep
            print(f"{slug}: FAILED — {e}", file=sys.stderr)
            failures.append(slug)
            continue
```

**A17: not closed.** The commit refactored the guards out of `materialize()` into
`verify_containment()` — which is a good change and is what makes the per-cell `--verify` possible —
but it moved the raise site without adding cleanup. A clone that fails `verify_containment` (now at
`:282` of the old numbering) still leaves 33–195 MB on disk, and `dst.exists()` still masks it on the
next run. The `failures` list is at least printed and now `sys.exit(1)`s, so the *slug* is visible;
the disk and the "plain re-run does nothing" behaviour are unchanged. Note this now compounds with
F5: a clone left in a broken state also fails the new pre-run guard on every future sweep.

**A18: not closed.** `run-host.sh` still goes straight to all instances with no arguments, and the
setup doc still carries the instruction as prose (`crb-direction1-setup.md:249-253`, "Run one
instance first ... and read `review.md` + `artifacts/` before launching a sweep"). Nothing asserts
that instance 1 produced a non-empty `review.md` or any artifacts. The `SWEEP_BUDGET` gate is a
partial accidental substitute — at $75 it halts after ~2–4 cells — but it gates on *money spent*, not
on *output produced*, so the specific failure it was raised for (the pipeline runs, registers skills,
costs $20, writes no rubric) still burns the whole ceiling before anyone looks. And per F2, the
harness's current reaction to a zero-artifact cell is a bare `exit 1` with no message.

**Recommendation:** A17 — wrap the post-clone body of `materialize()` so any exception does
`shutil.rmtree(dst, ignore_errors=True)` before re-raising; that also stops F5's permanent-skip
interaction. A18 — after the first cell, assert `[ -s "$dest/review.md" ]` and at least one harvested
artifact, and `exit 1` if not. It composes with F4's counter and is ~4 lines.

---

### F9. Closed, verified, or deliberately left alone

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:150-159`, `:235`, `:177`/`:236`, `:254-267`,
`:222-231`; `scripts/crb-pipeline-to-benchmark.py:275-295`; `.gitignore:43-49`
**Move:** Asymptotic behaviour vs. constant (and deciding the constant does not matter)
**Classification:** Micro / Cold path
**Confidence:** High
**Baseline:** measured budget-exhausted cell `total_cost_usd: 15.24`
(`runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json`); $10–40/instance for the comparisons
below
**Legibility-target:** the pass-3 reviewer — recorded as considered-and-declined so the same cycles
are not spent twice

**A2 is closed, with in-repo proof.** The question posed was what Claude Code actually puts in
`subtype` on budget exhaustion. It is knowable and it is already in this repo:

```
{'type': 'result', 'subtype': 'error_max_budget_usd', 'is_error': True,
 'num_turns': 1, 'total_cost_usd': 15.24}
```

The old predicate (`num_turns > 0`) banks that as complete; the new one rejects it on **both** the
`is_error` clause and the `subtype` clause. On the `d.get("subtype", "success")` default: it is
technically fail-*unsafe* (a result event with no `subtype` at all is treated as success), and I
would prefer `d.get("subtype") == "success"` so an unrecognised payload retries rather than banks.
But every observed failure carries `is_error: True`, which the predicate independently catches, so
the default is belt-and-braces rather than a hole. Not worth a finding on its own — worth one word
in the code comment.

**A3 is closed.** All three paths verified by reading `:275-295`: `--no-seed` prints and continues
(the deliberate escape still works); `src` missing → `sys.exit`; `src` present but one of the two
files missing → `sys.exit` via the new `elif not s.exists()` branch, with the `elif (jdir/name).exists()`
branch correctly ordered ahead of it so a previously-seeded dir is kept rather than rejected. The
only residual is that an existing-but-truncated seed file passes on name alone; that is a $0-to-check
integrity question, not a cost gate.

**Two `--verify` subprocesses per cell: correctly trivial.** Each spawns Python plus ~4 `git`
plumbing calls against a shallow clone — call it a second or two against a multi-minute, $10–40
agent run. Well under 0.1% overhead. The right call, and I would not trade it for anything.

**Re-summing every cell's `result.json` after every instance is not an O(n²) problem.** At n=50 the
whole sweep does ~1275 reads of few-KB JSON files, page-cache-warm, spread over hours of container
time. Milliseconds total. Explicitly *not* a finding — the correctness properties it buys (survives a
resumed sweep, counts failed cells' spend) are worth far more than the reads cost. The real defect in
that code is F3's overwrite, not the file count.

**`git clean -qfdx` does not raise per-cell cost.** The question was whether `-x` deletes something
expensive to recreate. Nothing the materializer writes is gitignored, and `/code-review` is a static
review — if the agent does run an install (it can; it has network and `--dangerously-skip-permissions`),
the re-creation cost on a retry is wall-clock inside a container, not billed tokens, and it is
recreated only on the ~2 retries F3 should be capping anyway. Weighed against monotonic
`node_modules`-scale growth across 50 clones, `-x` is clearly the right side of the trade. Closed,
no follow-up.

**Transcript growth is now bounded where it mattered.** `.gitignore` adds `runs/**/transcript.jsonl`
and `runs/**/stderr.log`, so 50 verbose stream-json transcripts no longer land in a tracked directory
— which was the actual concern in pass-1 #9. Size is still not reported in the per-cell summary at
`:246-248`; that remains a one-line nicety, not a finding.

**The harvest rewrite's rename handling is still not right, but the guard covers it.** In
`--porcelain=v1 -z`, a rename is `XY <to>\0<from>\0` and the second field carries no status prefix, so
`cut -c4-` truncates three characters off the `<from>` path — the comment claims the rewrite fixed
what `awk $2` broke, and it did not. It is inert in practice: renames only appear for *staged*
changes and the reviewing agent does not `git add`, and the new `[ -f "$clone/$f" ] || continue`
turns a mangled path into a silent skip rather than a bad copy. Recorded rather than raised.

**Recommendation:** No action on the items in this section beyond the two one-line comment fixes
noted (the `subtype` default rationale, and the rename claim in the harvest comment).

---

## What Looks Good

- **The A2 fix is exactly right and is now backed by evidence that was sitting in the repo.** A cell
  that burned $15.24 and returned an empty result used to be banked as complete forever; it now
  retries. That is the single highest-value change in the commit.
- **`verify_containment()` as an extracted, re-callable function** is a better design than the
  inline guards it replaced. Establishing an invariant at creation and re-asserting it around every
  read-write mount is the correct treatment for a property the arm's validity depends on, and pinning
  `head` to the manifest (rather than the clone's own tip) is the detail that makes it actually
  detect a moved ref.
- **The seeding fix is the cheapest large-dollar win in the branch** — two `print(..., stderr)` calls
  became `sys.exit`, and that is the difference between a $17 and an $850 judge pass.
- **`judge.sh` converts a documented foot-gun into a mechanical one**, and it went further than
  asked: the `MARTIAN_BASE_URL` fail-closed check catches a credential-exfiltration path that no
  amount of `--tool` discipline would have.
- **The budget gate's bash is correct**, which is not a given for `heredoc || { ...; exit; }` under
  `set -euo pipefail`. Checking after the cell (accepting one `BUDGET` of overshoot) is the right
  granularity choice.
- **`.gitignore`ing transcripts with an explicit note that the 16 already-committed ones stay
  tracked** is the right call — it stops the bleeding without inviting a history rewrite.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Post-run containment failure only warns; contaminated cell banked as success and never re-checked | High | `run-host.sh:236-237` | High |
| F2 | Harvest `grep` under `pipefail` aborts the whole sweep on a zero-artifact cell, silently, before `run-meta.json` | High | `run-host.sh:222-231` | High |
| F3 | Retry overwrites `result.json`, so the sweep-budget sum forgets prior spend; no attempt cap | High | `run-host.sh:254-267` | High |
| F4 | `SWEEP_BUDGET=$75` halts the $50–200 pilot; sum is lifetime-scoped; `exit 2` skips `run-meta.json` | Medium | `run-host.sh:62-65,254,271` | High |
| F5 | Pre-run guard failure `continue`s every cell → whole sweep no-ops and exits 0 | Medium | `run-host.sh:177-178` | High |
| F6 | Budget gate reports any Python exception as "SWEEP BUDGET EXCEEDED" | Low | `run-host.sh:254` | High |
| F7 | `judge.sh` correct, but stdout and `RUN.md` still lead with the hand-typed steps | Low | `crb-pipeline-to-benchmark.py:346-393` | High |
| F8 | A17 (leaked clone) and A18 (canary) not addressed | Medium | `crb-materialize.py:197-202`; `run-host.sh:143` | High |
| F9 | Closed / verified / deliberately-declined (A2, A3, `--verify` cost, O(n²) re-sum, `-x`, transcripts, renames) | Informational | multiple | High |

## Overall Assessment

Three of the six claimed fixes land cleanly (A2, A3, and the mechanical half of A19), and A2 in
particular is now provable rather than speculative — the budget-exhausted payload it guards against is
sitting in this repo with `is_error: true` and a $15.24 price tag. Two claimed fixes were not
attempted at all (A17, A18) and should not be marked green. A1 is the interesting one: the gate is
built correctly and wired correctly, and it still does not do its job, for three unrelated reasons —
its default halts the only run anyone is going to make, its ledger is erased by the retries that A2's
fix introduced, and its abort path throws away the cost report.

The pattern across F1, F2, F3 and F5 is the same one pass 1 named, one layer further in: this commit
added four new guards to the paid loop, and **each one's failure path is cheaper to write than its
success path is to bank**. A pre-run failure `continue`s with no tally; a post-run failure warns into
a stderr stream nobody reads while the contaminated result is banked as a success; a harvest with
nothing to harvest kills the process without a word. The fix commit moved the harness from "failures
recorded as successes" to "failures recorded as stderr lines" — better, but still not to "failures
recorded as failures, in a file, with an exit code."

None of it is structural. F1 is a `mv` plus reordering two blocks; F2 is `|| true`; F3 is a filename
and a two-line counter; F4 is a default and moving one block into a trap; F5 is a counter and an
`exit 1`. Call it 40 lines. I would fix **F1, F2 and F3 before any paid sweep** — F1 because it can
silently invalidate the arm's headline number, F2 because it turns the most-anticipated failure into
the least legible one, F3 because it defeats the ceiling this commit was written to add. F4 and F5
before the *unattended* sweep specifically. F7 and F8 are pilot-informed follow-ups.

Measurement still needed, and the pilot still produces it for free: per-instance cost (settles whether
`SWEEP_BUDGET` should be $250 or $2000) and per-instance wall-clock (settles pass-1 finding #5, which
this commit correctly did not touch). One new item for the list: whether benchmark step 2.5 is
resumable, since `judge.sh` restarts from step 2 every time and step 2.5 is the step with no cache.

## Goal-Alignment Note
- Answered: yes — per-prior-finding verdicts delivered (3 closed, 2 partially, 2 not closed), plus 6 new findings on the surface the fix introduced
- Out of scope: correctness/security of the new guards (the security critic owns the `MARTIAN_BASE_URL` and `--no-dereference` additions); pass-1 finding #5 (sequential sweep), correctly deferred to the pilot by this commit; whether `crb-pipeline-to-benchmark.py` *should* refuse contaminated cells is a design call I flagged but did not decide; I did not run `crb-materialize.py --verify` against a real clone
- Escalate: (1) **F1 is a validity risk, not just a cost risk** — a contaminated cell reaching the leaderboard produces a plausible high score, so the orchestrator should decide whether the pilot is gated on it. (2) **The setup doc asserts a fix the code does not implement** — `crb-direction1-setup.md:97` says "a post-run failure marks that cell's result void"; either the code or the doc has to change before anyone relies on it. (3) **F3 is a cross-fix interaction**: A2's fix and A1's fix are individually correct and jointly leak money; fixing them in separate passes will not catch it. (4) `SWEEP_BUDGET`'s $75 default vs. the doc's own $50–200 pilot estimate is a one-character decision someone should make deliberately.
