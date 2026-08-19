# Architecture Review — feat/crb-direction1-harness (iteration 2 of the review-fix loop)

**Scope:** `git diff 59733d8..HEAD -- . ':!docs/reviews'` — commits cf6e7c9, 5bd0b09, 46a5f17; 10 files, +1294/−102
**Date:** 2026-08-18
**Based on:** the orchestrator's fact-check summary for this pass (five Incorrect findings, all doc/comment mechanism errors, closed in 46a5f17). No `code-fact-check` report file for *this* scope was supplied; `docs/reviews/code-fact-check-report-r3.md` exists but predates 46a5f17.
**Partial scope:** this is narrower than the branch. Work outside it is already committed and is context only. Every "missing" claim below was checked against `git log main..HEAD` / the current file contents, not against the diff alone.

⚠️ **No code fact-check report was provided for this exact diff.** The orchestrator's prose summary of the fact-check was used instead. Architectural claims in the new docstrings were spot-checked against code where load-bearing, but not systematically re-verified.

**Trust-boundary cross-reference:** ran the scan. `docs/reviews/security-review-*.md` matches four files, the most recent being `security-review-2026-07-31-r2.md` — a review of `exp/cross-model-openrouter-sweep`, whose Trust Boundary Map (B1–B5: OpenRouter egress, dry-run prompt files, judge prompts, committed findings) describes a different subsystem entirely. No security-reviewer output exists for the CRB harness. The cross-reference is therefore treated as a **no-op**; the module-boundary findings below carry no boundary labels. This is a gap worth escalating, not a clean bill: the harness's central invariant *is* a containment/trust property, and it has never been through `security-reviewer`.

## Dependency Map

The arm is a four-stage pipeline. Dependencies should flow forward (each stage reads the previous stage's artifacts) and all four stages should depend on the shared identity module, never on each other's internals.

```
stage 1  scripts/crb-materialize.py     ──writes──▶ external/crb-eval/<slug>/  (clones)
                                        ──writes──▶ runs/review-arms/crb/instances.json  (MANIFEST)
stage 2  runs/.../crb-pipeline/run-host.sh
             ├─ calls  crb-materialize.py --reset       (pre-run and post-run)
             ├─ calls  scripts/crb-cell-status.py       (resume predicate)   [new, extracted]
             └─ writes $OUT/<slug>/{result.json, review.md, artifacts/, attempts.jsonl,
                                     CONTAINMENT_FAILED}
                       $OUT/run-meta.json                                    [now trap-written]
stage 3  scripts/crb-pipeline-to-benchmark.py  reads run cells + MANIFEST → benchmark_data.json
stage 4  scripts/crb-subset-leaderboard.py     reads evaluations
             └─ NEW: also reads run-meta.json (stage 2) + MANIFEST (stage 1)   ◀── back-edge

shared   scripts/crb_common.py  — imported by stages 3 and 4 only. Stages 1 and 2 do not
                                  import it (stage 2 cannot: it is bash).
```

Two structural facts frame everything below:

1. **Stage 4 gained a back-edge over stage 3.** Before this diff, the leaderboard depended only on the benchmark's evaluations file. `attrition()` now reaches back past the injector to the run-host provenance file and the materializer's manifest, and reconstructs — by inference — outcomes that the injector observed directly and did not persist.
2. **`crb_common.py` is shared by the Python stages but not by the bash stage.** `RUN_META` is a constant naming a file that only bash writes. The module's stated charter ("one definition, imported by both") is structurally unattainable for this particular constant.

The direction of the containment work is the opposite and is good: logic moved *out* of `run-host.sh` heredocs and *into* importable, fixture-backed Python (`crb-cell-status.py`, four new functions in `crb-materialize.py`). That is the right way for this arm to pay down A20.

## Findings

#### `run-meta.json` is a cross-module contract that no module defines, and both of its reader-side defenses fail open

**Severity:** Structural
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:160-217`, `scripts/crb-subset-leaderboard.py:40-79`, `scripts/crb_common.py:28-32`
**Move:** #1 (dependency direction), #2 (responsibility boundaries)
**Confidence:** High

`run-meta.json` is now a real inter-stage contract — one bash writer, one Python reader, with a third module (`crb_common`) owning only its *path*. Its schema exists solely as a `json.dump` literal inside a heredoc, and the reader defends against schema mismatch by falling back rather than by failing:

```python
    requested = meta.get("requested_instances") or sorted(cells)
```

`cells` is built by scanning `os.listdir(out)` for directories that contain a `result.json`. So on any run-meta that lacks `requested_instances` — one written by a pre-cf6e7c9 checkout, a hand-edited file, or a future schema rename — `requested` becomes, by construction, exactly the set of cells that *did* produce output. `attrition()` then iterates that set and reports zero attrition. The control silently reports "nothing was lost" precisely on the inputs it cannot parse.

The second fail-open is on a **documented usage pattern**, not a hypothetical. `run-host.sh:45-48` advertises subset invocation (`... run-host.sh discourse-graphite-PR4 grafana-PR79265`), and `write_run_meta` records only the current invocation's instances:

```bash
  python3 - "$OUT/run-meta.json" "$PAYLOAD_REF" "$PAYLOAD_SHA" "$MODEL" \
           "$CC_VERSION" "$OUT" "${INSTANCES[*]}" <<'EOF' || true
```
```python
req = requested.split()
json.dump({... "requested_instances": req,
           "missing_cells": [s for s in req if s not in cells], ...
```

`cells` accumulates across invocations (it rescans `$OUT`), but `requested_instances` does not — it is overwritten on every run. A 50-PR sweep executed as several subset invocations, or resumed after the `SWEEP_BUDGET` halt the trap was added to survive, ends with `requested_instances` naming only the final batch. Attrition is then measured against 2 slugs instead of 50 and reports clean. The failure mode and the recovery mode collide: the very scenario the EXIT trap exists to serve (a partial sweep that halts and is resumed) is the scenario that empties the attrition denominator.

Both defects share one cause: the schema has no owner. Nothing declares its fields, nothing versions it, and the reader's compatibility shim is a bare `or`. Because this is the file that backs the "our recall is not selected for pipeline success" caveat on a $50–2000 sweep, a silent clean read here is the most expensive quiet failure in the diff.

**Recommendation:** Give the file an owning module — `scripts/crb-run-meta.py` with a `write(out, **provenance)` and a `read(path)` that raises on a missing `schema_version` or missing `requested_instances` — and have `run-host.sh` call it as a subprocess instead of carrying the writer inline. Make `requested_instances` accumulate (union with the existing file's value) rather than overwrite, and make `attrition()` refuse to report "clean" when the key is absent, exactly as it already refuses when the whole file is absent (`crb-subset-leaderboard.py:52-57` is the correct pattern — apply it one level deeper).

#### The leaderboard reaches back over the injector to re-derive outcomes the injector observed and discarded

**Severity:** Coupling
**Location:** `scripts/crb-subset-leaderboard.py:59-76`; the discarded knowledge is at `scripts/crb-pipeline-to-benchmark.py:233-248`
**Move:** #4 (layer violations), #7 (coupling surface)
**Confidence:** High

`attrition()` explains each lost cell by re-deriving the reason from two upstream artifacts:

```python
        if slug in voided:
            why = "voided by a post-run containment failure"
        elif slug not in cells:
            why = "no cell produced (missing clone, or pre-run containment failure)"
        elif not url:
            why = f"not in {MANIFEST.name} — cannot map the slug to a PR"
        else:
            why = "ran, but has no judged row (no reviewable output, or not injected)"
```

The disjunctions in the second and fourth branches are the tell: the leaderboard is guessing between causes it cannot distinguish. The injector *can* — it prints each one exactly, per cell, at `crb-pipeline-to-benchmark.py:235/239/242/247` (`not in MANIFEST`, `not in benchmark_data.json`, `cell voided`, `no reviewable output (prov)`) — and then throws the information away to stderr. So stage 4 has been coupled to stage 1's manifest schema and stage 2's provenance schema in order to reconstruct, lossily, something stage 3 already knew. Three modules now change together whenever an outcome category is added: run-host's `voided_cells`, the injector's skip branches, and this if/elif chain, with nothing forcing them to stay in agreement.

There is also a category the chain cannot express at all: a cell the injector rejected because `url not in data` (benchmark_data.json) lands in the catch-all "no reviewable output, or not injected", which reads to a human as a pipeline failure when it is a data-mapping failure.

**Recommendation:** Have the injector write an `injection-report.json` next to the work dir (`{slug: {url, status, reason, n_comments}}`) — it already computes every field — and have `attrition()` read that plus the run-meta requested list, dropping the manifest dependency and the inference chain. That restores forward-only dependency flow and puts each reason where it was observed.

#### `crb_common.RUN_META` is not a single definition, and the same directory is now defined twice more

**Severity:** Coupling
**Location:** `scripts/crb_common.py:28-32`; `scripts/crb-pipeline-to-benchmark.py:63`; `runs/review-arms/crb-pipeline/run-host.sh:54`
**Move:** #2 (responsibility boundaries), #3 (module boundary)
**Confidence:** High

`crb_common.py`'s docstring justifies its own existence on a specific ground: a value was "hand-copied into a second file, where [it is] held in agreement by a comment", so "one definition, imported by both". `RUN_META` does not satisfy that test. Its *writer* is bash and cannot import the module:

```bash
OUT="$ROOT/runs/review-arms/crb-pipeline"        # run-host.sh:54
```
```python
RUN_META = WORKSPACE / "runs/review-arms/crb-pipeline/run-meta.json"   # crb_common.py:32
DEFAULT_RUNS = WORKSPACE / "runs/review-arms/crb-pipeline"             # injector:63
```

The path is now stated three times in three languages, held in agreement by nothing. Worse, the two Python statements are in a module and its *own importer*: the injector imports `crb_common` on the next line and still re-derives the same directory. `RUN_META` and `DEFAULT_RUNS` are the same fact.

On the boundary question the answer is split. In *kind*, the boundary is holding — `RUN_META` is a path constant with no behaviour, which is what the docstring scopes the module to. In *effect*, it is the first constant admitted that the module cannot actually unify, which turns the docstring's justification into an unearned claim about it. The consequence is concrete: change `OUT` in `run-host.sh` and the leaderboard's `--run-meta` default silently points at a file nobody writes — at which point finding #1's fail-open path activates and attrition reports clean.

**Recommendation:** Define `RUNS_DIR` in `crb_common` once, derive `RUN_META = RUNS_DIR / "run-meta.json"` and `DEFAULT_RUNS = RUNS_DIR` from it, and have `run-host.sh` obtain `OUT` from `python3 -c 'import crb_common; print(crb_common.RUNS_DIR)'` at startup rather than restating the literal. If that shell round-trip is judged too clever, keep the literal in bash but add a startup assertion that it equals the Python constant — that converts a silent divergence into a loud one.

#### The post-run containment gate calls the mutating mode where its job is detection, leaving `--verify` unexercised

**Severity:** Coupling
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:262`, `:359`; `scripts/crb-materialize.py:451-457`, `:489`
**Move:** #5 (interface segregation), #8 (extension points)
**Confidence:** Medium-High

The API separation is right: `--verify` is read-only, `--reset` repairs-then-asserts, and `verify_containment`'s own docstring states the split ("`--verify` is the read-only form for a human"). The problem is that the pipeline calls the fused form at *both* gates:

```bash
  python3 "$ROOT/scripts/crb-materialize.py" --reset "$id" || {     # pre-run, :262
```
```bash
  if ! python3 "$ROOT/scripts/crb-materialize.py" --reset "$id"; then   # post-run, :359
```

Two consequences. First, the two gates are now the same operation run twice per cell, ~1.5 times more than needed: the pre-run reset already guarantees a clean start, so the post-run call's only remaining job is *detection* of what this cell did. Calling `--reset` there means the assertion (`verify_containment`) runs against a tree that `reset_clone` has just normalised, so on the benign path the post-run verify is tautological — its entire discriminating power comes from `reset_clone`'s three `raise RuntimeError` branches, and `verify_containment` at that point can only pass. Second, `--verify` is now called by no automated caller and by no test path that mirrors production, so the read-only assertion can rot without any suite going red — it is documented as "for a human", which in practice means "for nobody".

On the direct question — should detection and repair be separable for a control whose job is to detect tampering: they *are* separable in the API, but only one-directionally (you can detect without repairing; you cannot repair without also asserting), and the pipeline uses only the fused direction. For a tamper-detection control that is the wrong default: the detecting call should not be the one holding the power to change the evidence.

**Recommendation:** Make the post-run gate `--verify` (pure detection → void on failure) and move the between-cells restoration to the pre-run `--reset` only, which already runs. That is one fewer mutation per cell, gives each gate one job, and puts `--verify` back on the exercised path. If a post-run reset is wanted for disk hygiene, run it *after* the verify verdict is recorded, not as the verdict.

#### The void protocol has three encodings, three separate readers, and no module or test that asserts they agree

**Severity:** Coupling
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:359-372`; readers at `scripts/crb-pipeline-to-benchmark.py:241`, `scripts/crb-cell-status.py:65-79`, `scripts/crb-subset-leaderboard.py:60`
**Move:** #2 (responsibility boundaries), #7 (coupling surface)
**Confidence:** Medium-High

Voiding a cell writes the fact in three places, and each downstream consumer reads a different one: the injector reads the `CONTAINMENT_FAILED` sentinel file, the resume predicate reads the rewritten `result.json`, and attrition reads `run-meta.json`'s `voided_cells`. Redundancy here is defensible — a void must be sticky — but nothing owns the protocol. In particular the rewrite is best-effort:

```bash
    python3 - "$dest/result.json" <<'EOF' || true
...
d["is_error"] = True
d["subtype"] = "containment_failed"
```

and `crb-cell-status.py` — the module the diff *specifically extracted so this predicate would have fixtures* — cannot see the sentinel at all, because its interface takes a `result.json` path rather than a cell directory:

```python
    if len(argv) != 2:
        sys.exit("usage: crb-cell-status.py <result.json>")
```

So the newly-testable predicate rejects a voided cell only *coincidentally*, via an `is_error` flag that an unrelated, `|| true`-guarded heredoc happened to write. `test/crb-cell-status.bats`'s 14 cases cover budget exhaustion, quota stubs, the length floor and malformed JSON, but none covers a containment-voided cell — the extraction moved the predicate to where it could be tested and then left this case untested, which is the one whose failure mode is "bank a contaminated cell and ship it".

**Recommendation:** Change the predicate's interface to take the cell directory, check `CONTAINMENT_FAILED` first, and add a bats case asserting a voided cell is rejected by the sentinel alone (result.json untouched) — that makes the sticky-void property a property of the predicate rather than a side effect of the rewrite succeeding.

#### `write_run_meta` became a function but not a mode — provenance is still not re-derivable

**Severity:** Minor
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:159-218`, `:220`, `:432`
**Move:** #8 (extension points)
**Confidence:** High

The trap conversion is the right fix and closes the pre-mortem's hole. But the function is reachable only from inside a live invocation:

```bash
META_WRITTEN=""
write_run_meta() {
  if [ -n "$META_WRITTEN" ]; then return 0; fi
```

Everything it computes is derived from `$OUT` on disk plus five scalars, so there is no reason regeneration must ride along with a sweep. After a lost or truncated run-meta — the exact aftermath of the crash cases the trap was added for — the only way to get provenance back is to re-run cells that already cost money. This is A20's "harvest and run-meta are not re-runnable after a partial sweep" item, and the diff got within three lines of closing it.

**Recommendation:** Add `RUN_META_ONLY=1` (or a `--meta-only` first argument) that runs the payload resolution, calls `write_run_meta`, and exits before the docker preflight. Cheap, and it also gives the run-meta writer a test seam it currently has none of.

#### `attrition()` returns a flag nobody reads; `missing_cells` is written and never read

**Severity:** Minor
**Location:** `scripts/crb-subset-leaderboard.py:40`, `:169`; `runs/review-arms/crb-pipeline/run-host.sh:210`
**Move:** #5 (interface segregation)
**Confidence:** High

```python
def attrition(urls, run_meta_path: Path):
    """(lines, checked) — sweep cells that are NOT in the judged subset.
```
```python
    att_lines, _checked = attrition(our_urls, Path(args.run_meta))
```

`checked` distinguishes "attrition was measured and was zero" from "attrition could not be measured" — the most decision-relevant bit in the function — and the sole caller discards it. Symmetrically, `missing_cells` is written into run-meta and read by nobody; `attrition()` recomputes the same set with more nuance. Two halves of one contract, each carrying a field the other side ignores.

**Recommendation:** Either consume `checked` (a non-zero exit, or an explicit "attrition: checked, none" line so a silent report is distinguishable from an unchecked one) or drop it from the signature. Same for `missing_cells`: read it or stop writing it.

#### A20's deliberate carry is *more* defensible after this diff, with one item that should be un-carried

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh` (7 heredocs), `scripts/crb-materialize.py` (+212)
**Move:** #2, #8
**Confidence:** Medium

The +180 lines to `crb-materialize.py` do not weaken A20's reasoning; they strengthen it. A20 was carried on the argument that a refactor's risk lands inside the sweep window while its benefit lands in a maintenance phase that will not occur. This diff moved logic in the direction that argument endorses: the resume predicate left a heredoc and became a fixture-backed script, and the containment mechanism grew inside the module that already owned it (`crb-materialize.py`) rather than being smeared into new ones. Growth concentrated in the module with the best test coverage in the arm (17 bats cases) is not the growth A20 warned about.

The heredoc count in `run-host.sh` is still 7, and the cell-layout duplication A20 names — layout in bash, re-derived by the injector — is untouched by this diff and remains a reasonable carry inside the sweep window. The one item that should *not* stay carried is the run-meta re-runnability half (see the previous finding): the trap conversion already did the hard part, and finishing it is a three-line change with no sweep-window risk.

## What Looks Good

- **The containment mechanism has one owner.** `verify_containment` / `fetch_traces` / `classify_strays` / `scrub_object_store` / `reset_clone` all live in `crb-materialize.py`, the module that establishes the invariant in the first place. On the direct question — is the invariant smeared across three modules — no: the *mechanism* is properly consolidated (this closes R2's "fifteen lines welded inside `materialize()`" properly, not cosmetically), and what `run-host.sh` and the injector hold is *policy* (skip vs. void) and *enforcement*, which correctly belong at the call sites. The seam that is genuinely unowned is the narrower void-protocol encoding, above.
- **The extraction of `crb-cell-status.py` is the right module split.** A predicate that gates $10–40 of spend per cell, with a measured corpus behind every constant and a bats case per rule, is exactly the thing that should not live in a heredoc. The `STUB_MAX_LEN` comment recording *why the value was wrong before* — and that all three fact-check replicates caught it — is unusually good practice.
- **`scrub_object_store` was made load-bearing rather than deleted.** Discovering that a check could not fire and responding by tightening the check (`--no-reflogs`) plus adding a non-vacuity test (`"scrub_object_store is load-bearing — benign sequence VOIDS without it"`) is the correct resolution; deleting the call would have removed the evidence that anything was wrong.
- **Attrition is measured against `our_urls` even under `--all-prs`.** The comment states the reasoning exactly — the question is what happened to the cells we ran, not how the table is scoped — and this is the kind of scoping mistake that would otherwise silently disable the control under the flag most likely to be used for a write-up.
- **The trap-based provenance write.** Recognising that the `SWEEP_BUDGET` halt was the *designed* outcome of an `--all` run and that it wrote no provenance is a good catch, and the `META_WRITTEN` idempotence guard makes the explicit call and the trap call safely coexist.
- **Remote removal was reordered before ref pruning** in `materialize()`, with the dangling-symref mechanism documented and a bats case pinning it. That is a correct dependency-ordering fix, not a workaround.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `run-meta.json` contract has no owning module; both reader defenses fail open (schema fallback; per-invocation overwrite) | Structural | `run-host.sh:160-217`, `crb-subset-leaderboard.py:59` | High |
| 2 | Leaderboard reaches back over the injector and re-derives skip reasons the injector observed and discarded | Coupling | `crb-subset-leaderboard.py:59-76` | High |
| 3 | `crb_common.RUN_META` is not single-definition; same dir stated 3× across bash/injector/common | Coupling | `crb_common.py:32`, `crb-pipeline-to-benchmark.py:63`, `run-host.sh:54` | High |
| 4 | Post-run gate uses mutating `--reset` where detection is the job; `--verify` unexercised | Coupling | `run-host.sh:359`, `crb-materialize.py:451-457` | Medium-High |
| 5 | Void protocol has 3 encodings, 3 readers, no owner; predicate structurally cannot see the sentinel and has no test for it | Coupling | `run-host.sh:359-372`, `crb-cell-status.py:65-79` | Medium-High |
| 6 | `write_run_meta` is a function but not a mode — provenance not re-derivable after a lost run | Minor | `run-host.sh:159-218` | High |
| 7 | `attrition()`'s `checked` flag discarded; `missing_cells` written and never read | Minor | `crb-subset-leaderboard.py:169`, `run-host.sh:210` | High |
| 8 | A20's carry is more defensible after this diff; one sub-item should be un-carried | Informational | `run-host.sh`, `crb-materialize.py` | Medium |

## Overall Assessment

This diff improves the arm's structural integrity on the axis that matters most for the sweep: the containment invariant now lives in one module, behind five named functions with seventeen bats cases, instead of inline in a bash loop. The `crb-cell-status.py` extraction is the same move applied to the resume predicate, and both are the right direction for the A20 carry rather than a violation of it. Nothing in the diff reverses a dependency, breaks a layer the arm actually maintains, or introduces a cycle.

The one structural problem is on the *reporting* side, not the containment side, and it is the single most important concern: `run-meta.json` became a real inter-module contract in this diff without acquiring an owner, and the module that reads it defends against every schema mismatch by falling back to a value that reports "no attrition". Combined with `requested_instances` being overwritten per invocation, the attrition control — the thing standing between this sweep and a recall number silently selected for pipeline success — reports clean in exactly the two operational shapes most likely to occur: a subset invocation and a resumed sweep. That is fixable in place (findings 1 and 3 are a single afternoon: give the schema an owner, make `requested_instances` accumulate, refuse rather than fall back) and does not require restructuring. It should be fixed before money is spent, because unlike the containment controls, this one fails without saying anything.

## Goal-Alignment Note
- Answered: yes — all five judgement questions addressed (seam coherence in "What Looks Good" + finding 5; `crb_common` boundary in finding 3; run-meta location in finding 1; `--reset` shape in finding 4; A20 in finding 8).
- Out of scope: correctness of the containment *mechanism* itself (fact-check's domain, and reported closed); the egress-allowlist gap tracked as R3; test adequacy beyond the two structural gaps named in findings 5 and 6; everything under `docs/` in the diff.
- Escalate: (a) **no `security-reviewer` output has ever been produced for this harness** — its central invariant is a trust-boundary property and the trust-boundary cross-reference was a forced no-op; consider running it before the sweep. (b) Finding 1 is blocking-worthy in my judgement: it silently disables the attrition caveat under two likely operating patterns, and the sweep's headline recall claim rests on that caveat.
