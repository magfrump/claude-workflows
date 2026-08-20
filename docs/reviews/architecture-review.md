# Architecture Review — `197eec6` on `feat/crb-direction1-harness`

**Scope:** commit `197eec6` (`feat(crb): egress allowlist + disposable clones (decision 034)`) — 16 files, +1676/−757. Sibling branch commits are context, not under review.
**Date:** 2026-08-19
**Based on:** `docs/reviews/code-fact-check-report.md` (k=3 merged, 28 clusters), `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md`, `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md` (decision: `escalate`)
**Position:** answers the `escalate` recorded when the 2026-08-19 review-fix loop hit its 3-iteration cap without converging. The escalation's stated question — *should host-side git commands ever run against a `.git` a `--dangerously-skip-permissions` container had write access to?* — is architectural, so this review is the loop's designated tiebreaker.

**Scope check:** in scope on three of four trigger categories. Module structure (new `docker/` subsystem; `crb-audit-clone.sh` and `crb-harvest-artifacts.py` split out of `crb-materialize.py` and `run-host.sh`; `test/crb-containment-reset.bats` deleted with the code it pinned). Public APIs (`--reset`/`--heal` → `--restore`/`--snapshot`; two new CLI contracts with documented exit codes). Data models (the baseline tar + `index.json` + four new manifest fields are a new persisted inter-module contract). Cross-cutting concerns (the egress network and proxy sit under every paid cell).

**Trust-boundary cross-reference:** activated against `docs/reviews/security-review.md` (2026-08-18, commit `46a5f17`, this branch), which carries the Trust Boundary Map `B1`–`B6`. Note the path deviates from the skill's `security-review-*.md` glob — the files that match that glob (`security-review-2026-07-31-r2.md` and siblings) are for `exp/cross-model-openrouter-sweep` and are irrelevant here. I used the branch-relevant map rather than the glob-matching one; findings F1 and F4 below carry `Security implication:` lines against `B1`/`B2`/`B3`.

---

## Dependency Map

Before this commit the arm was two modules with one direction of flow: `run-host.sh` (host orchestration) called `crb-materialize.py` (clone lifecycle), and both ran host `git` against the work clone. This commit splits containment into five participants:

```
   crb-materialize.py  ── owns ──▶  external/crb-eval/<slug>/            (work clone)
   (host, python)                   external/crb-eval/.baselines/<slug>.tar        (hash-pinned)
                                    external/crb-eval/.baselines/<slug>.index.json (NOT pinned)
                                    runs/review-arms/crb/instances.json  (manifest: head, baseline_sha256)
                          ▲
                          │ --restore (subprocess)
                          │
   run-host.sh  ─────────┼──▶ docker/Dockerfile.review ─▶ review cell   (EGRESS_NET + proxy)
   (host, bash)          │        │
                         │        └──▶ crb-audit-clone.sh (bash, in a throwaway container, --network none)
                         │
                         ├──▶ crb-harvest-artifacts.py (host, python) ◀── baseline index path passed as argv
                         └──▶ run-meta.json ──▶ crb-subset-leaderboard.py, crb-pipeline-to-benchmark.py
```

Direction is mostly correct: the volatile orchestrator depends on the stable clone-lifecycle module, never the reverse, and the two extracted scripts are leaves with no back-edges. The dependency that is *not* correct is on storage layout: `run-host.sh` builds `"$CLONES/.baselines/$id.tar"` and `"$CLONES/.baselines/$id.index.json"` itself rather than asking the module that defines them (F5), so `crb-materialize.py` cannot move or rename its own private storage without breaking a bash file two directories away. The shared-identity module that exists to prevent exactly this, `crb_common.py`, cannot serve the bash side at all, and this commit adds a fourth restatement of the run-dir path (F6).

Layering is otherwise the clearest thing the commit does: it draws a real line between *host* and *container*, puts detection on the container side of it, and leaves nothing on the cell path that reads a used `.git`. The findings below are almost all about where that line is not actually continuous.

---

## Findings

#### F1. The central invariant is structural on the cell path and operator-discipline on the migration path — and the runner routes operators onto the migration path

**Severity:** Structural
**Location:** `scripts/crb-materialize.py:509-521`, `scripts/crb-materialize.py:225-241`, `runs/review-arms/crb-pipeline/run-host.sh:412-418`
**Move:** #4 (layer violations), #3 (module boundary)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Decision 034 states the invariant as "**The host never reads a container-written `.git`.**" On the cell path that is now true by construction. On the `--snapshot` path it is true only if a human is right about a fact nothing checks. `--snapshot` runs `scrub_object_store()` (`git symbolic-ref -d`, `git reflog expire`, `git gc --prune=now`) and then `verify_containment()` (`git rev-list`, `git remote`, `git diff`) as **host** git against *whatever clone is at `DST_ROOT / slug`* — including one a review container has already written:

```python
                    scrub_object_store(dst)
                    n_commits, stat = verify_containment(dst, slug, head)
```

`scrub_object_store`'s own docstring asserts the opposite, and the k=3 fact-check marks the claim **Incorrect**:

```python
    Runs on a clone this script just built from the fork, before any container
    has seen it, which is the only reason it is safe to run host `git` here.
```

The guard against misuse is a sentence in `--snapshot`'s help text ("ONLY on a clone no container has run against") plus a `--force` prompt that fires only when a baseline *already* exists — which is never true for the clones that need snapshotting. And `run-host.sh` prints the invitation itself, on the failure path every pre-2026-08-19 clone takes:

```bash
    echo "    A clone materialized before 2026-08-19 has no baseline yet. If no" >&2
    echo "    container has ever run against it, build one once:" >&2
    echo "      python3 scripts/crb-materialize.py --snapshot $id" >&2
```

This matters more than a normal documentation-vs-code gap because it is the *only* migration route for the five clones that exist, and because the escalation this commit answers was specifically about whether host git may touch a container-written `.git`. The answer chosen was "no"; the code says "no, except here, where a comment says it is fine." The five host-side code-execution paths the 2026-08-19 reviewer executed are all reachable from `git gc` and `git rev-list` on a hostile config.

**Security implication:** this is `B1` and `B2` from `docs/reviews/security-review.md` — `[RW bind mount of $clone INCLUDING .git] → [host-side git subprocesses] → [host user account]`, with "NO validation — nothing inspects `.git` before running git." The disposable-clone design removes `B1`/`B2` from the cell path; it does not remove them from `--snapshot`. Any recommendation here relocates a trust-boundary crossing and should be confirmed against a security re-review before the sweep.

**Recommendation:** make the invariant structural on this path too — either run `--snapshot`'s inspection inside the same throwaway container `crb-audit-clone.sh` uses, or refuse to snapshot a clone that has no `.pristine` marker written by `materialize()` (so migrating an old clone means re-materializing it, which is what the five pilot clones need anyway per F3). Failing that, at minimum make the refusal the default and `--force` the escape, instead of the reverse.

---

#### F2. The baseline is a two-part contract; one part is hash-pinned and gated, the other is neither — and the gap costs a paid cell to discover

**Severity:** Structural
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:366-370` vs `:477-481`; `scripts/crb-materialize.py:305-324`; `scripts/crb-harvest-artifacts.py:100-105`
**Move:** #7 (coupling surface), #2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-author

`snapshot_baseline()` publishes two artifacts and the manifest records provenance for both:

```python
    part.replace(tar)
    index = artifact_index(dst)
    (BASELINE_ROOT / f"{slug}.index.json").write_text(
        json.dumps(index, indent=0, sort_keys=True) + "\n")
```

The tar is published atomically via `.part` → `replace`, hashed, recorded as `baseline_sha256`, and re-checked on every restore. The index is written non-atomically, hashed never, and `baseline_files_indexed` is recorded in the manifest and read by nobody. The runner's pre-run gate then checks only the half that is already protected:

```bash
  [ -f "$CLONES/.baselines/$id.tar" ] || {
    echo "$id: no baseline — run scripts/crb-materialize.py --slug $id (or --snapshot $id" >&2
```

while the half that is unprotected is required 110 lines later, *after* the container has run and the money is spent:

```bash
  python3 "$ROOT/scripts/crb-harvest-artifacts.py" \
    "$clone" "$CLONES/.baselines/$id.index.json" "$dest/artifacts" || {
      echo "$id: HARVEST invocation failed — see above" >&2; exit 4; }
```

`crb-harvest-artifacts.py` is right to exit 2 on a missing index (its comment explains why treating "no baseline" as "everything is new" is worse), and `run-host.sh` is right to escalate that to a sweep-stopping `exit 4`. The defect is that the precondition is validated at the wrong end: a missing or truncated index aborts the sweep at $10–40 already spent, per cell, and a *stale* index — tar from snapshot N, index from snapshot N−1, which the non-atomic write and the absent hash both permit — is not detected at all and silently mis-reports which files the pipeline produced. Since artifacts are the arm's output, that failure lands directly in the published numbers.

**Recommendation:** treat the baseline as one versioned object with one owner. Hash the index into the manifest alongside the tar, verify it where the tar hash is verified, write it through a `.part` rename, and move the existence check for both into the same pre-run gate (better: have `--restore` verify and report both, so `run-host.sh` checks nothing itself — see F5).

---

#### F3. R6 is relocated, not dissolved: the pre-run gate still fails closed for every clone that exists

**Severity:** Structural
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:363-370`; `runs/review-arms/crb/instances.json`; `docs/decisions/034-...:70-71`
**Move:** #2 (responsibility boundaries), #8 (extension points)
**Confidence:** High (corroborated — the k=3 fact-check marks the decision record's claim **Incorrect**)
**Legibility-target:** for-orchestrator-synthesis

The decision record claims:

```
- `--reset` and `--heal` are gone; `--restore` and `--snapshot` replace them.
  R6 (no existing clone could pass the pre-run gate) dissolves with them.
```

It does not dissolve; the gate's predicate changed from "the clone passes containment" to "a baseline tar exists," and all five materialized clones fail the new one. `instances.json` carries no `baseline_sha256` for any of `cal_com-PR11059`, `discourse-graphite-PR4`, `grafana-PR79265`, `keycloak-PR36880`, `sentry-greptile-PR5`, and all five directories exist under `external/crb-eval/`. Run the sweep today and every instance takes the `skipped_bad` branch, `ran` stays 0, and the script exits 3 — R6's exact symptom under a new mechanism.

This is the observation the escalation asked for. The commit's structural moves are real and mostly good, but on this specific point the pattern the loop was stopped over — *the same region producing a new mechanism error every round* — reproduced once more inside the change that was supposed to end it. It is cheap to fix (F1's re-materialize path, or a migration mode), and it is worth fixing *before* the sweep precisely because it is the fourth instance.

**Recommendation:** close it in code rather than in prose. Either give `crb-materialize.py` a `--migrate` mode that re-materializes any manifest entry lacking `baseline_sha256`, or have `run-host.sh` fail the whole sweep once, up front, with the list of slugs needing migration — instead of discovering it 50 times inside the loop. Correct the decision record's consequence line either way.

---

#### F4. `crb-audit-clone.sh` publishes a three-state exit contract; its only consumer implements two, and the third state is published as contamination

**Severity:** Coupling
**Location:** `scripts/crb-audit-clone.sh:23`, `:26-32`; `runs/review-arms/crb-pipeline/run-host.sh:492-508`; `test/crb-audit-clone.bats:133`
**Move:** #5 (interface segregation), #6 (substitutability)
**Confidence:** High
**Legibility-target:** for-author

The new audit module defines its interface explicitly:

```bash
# Exit: 0 = nothing detected · 1 = VOID (contamination) · 2 = could not check.
```

and `test/crb-audit-clone.bats` pins the distinction with a test named `"usage errors exit 2, distinct from a void"`. The sole consumer erases it:

```bash
  if ! docker run --rm --network none -u node \
        -v "$clone":/repo \
        -v "$ROOT/scripts/crb-audit-clone.sh":/audit.sh:ro \
        --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha"; then
    echo "$id: POST-RUN containment audit FAILED — voiding this cell" >&2
    : > "$dest/CONTAINMENT_FAILED"
```

Everything non-zero becomes `CONTAINMENT_FAILED` and `subtype = "containment_failed"`. That bucket now holds: a missing `.git`, a bad head sha, a `docker run` that failed because the daemon hiccuped or `$REVIEW_IMAGE` lacks `git`, and actual evidence of contamination. Failing safe is the right default, but the *encoding* is wrong: an infrastructure failure is recorded in `run-meta.json`'s `voided_cells` and read downstream by `crb-subset-leaderboard.py` as "voided by a post-run containment failure" and by `crb-pipeline-to-benchmark.py` as a cell to drop. A published attrition number that mixes "the agent fetched the answer key" with "docker was busy" is exactly the class of discriminator error the escalation was about — the reset's benign-vs-contaminated split was deleted, and a coarser version of it reappeared at the consumer.

**Security implication:** `B3` (`[agent network egress + git object store] → [verdict] → [benchmark score / published recall number]`). The interpretation of `voided_cells` is the security-relevant output; conflating two causes inside it weakens the same claim `voided_cells_meaning` was added to protect.

**Recommendation:** branch on the exit code — 1 → void as today; 2 → a distinct `AUDIT_INCONCLUSIVE` sentinel with its own key in `run-meta.json`, treated as unusable-but-not-contaminated. Fail the cell either way; report them apart.

---

#### F5. `run-host.sh` constructs `crb-materialize.py`'s private storage paths itself

**Severity:** Coupling
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:366`, `:479`; `scripts/crb-materialize.py:70-76`, `:305-307`
**Move:** #3 (module boundary), #7 (coupling surface — content coupling)
**Confidence:** High
**Legibility-target:** for-author

`crb-materialize.py` owns the baseline store and names it privately:

```python
BASELINE_ROOT = DST_ROOT / ".baselines"
```

`run-host.sh` re-derives the same layout in bash, twice, from its own `CLONES` root — `"$CLONES/.baselines/$id.tar"` and `"$CLONES/.baselines/$id.index.json"`. The dot-prefix, the `.tar`/`.index.json` suffixes, and the per-slug flat layout are now a public contract that no module declares and no test pins. Change the directory name, add a per-slug subdirectory, or compress the tar, and the failure surfaces as F3's silent all-cells-skipped or F2's post-payment `exit 4` — not as an import error. This is the same failure shape as A12 and the same one `crb_common.py`'s docstring says it exists to prevent ("a review-fix pass hand-copied them into a second file, where they are held in agreement by a comment").

**Recommendation:** invert the dependency. Give `crb-materialize.py` a `--baseline-paths SLUG` mode that prints tar and index paths (and verifies both), and have `run-host.sh` call it for the gate and pass the result to the harvest — which already takes the index as an argument, and is the one place in this commit where the boundary is drawn correctly.

---

#### F6. A12 widened: the run-dir path is now stated four times, twice inside one file

**Severity:** Coupling
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:72` and `:92`; `scripts/crb_common.py:32`; `scripts/crb-pipeline-to-benchmark.py:63`
**Move:** #3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

The prior rubric's A12 recorded three statements of `runs/review-arms/crb-pipeline`. This commit adds a fourth, and puts it two lines of context away from an existing one in the same file:

```bash
OUT="$ROOT/runs/review-arms/crb-pipeline"
...
DOCKER_DIR="$ROOT/runs/review-arms/crb-pipeline/docker"
```

`DOCKER_DIR="$OUT/docker"` is a one-token fix and is the whole finding at the local level. The structural point is the one A12 already made and this commit confirms: `crb_common.py` can only serve Python consumers, the orchestrator is bash, so every shared constant it holds gets hand-copied at the language boundary. That is not a naming problem, it is a missing accessor — the same gap F5 names.

**Recommendation:** `DOCKER_DIR="$OUT/docker"` now; longer term, expose `crb_common.py` to bash via a `python3 -m crb_common --path RUN_META` style accessor so the boundary holds in effect and not only in kind.

---

#### F7. A9 unaddressed and now four-valued: the void protocol gained an encoding without gaining a test

**Severity:** Coupling
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:496-508`, `:318-323`, `:350`; `scripts/crb-pipeline-to-benchmark.py:242`; `scripts/crb-subset-leaderboard.py:71-79`
**Move:** #7 (coupling surface), #2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-author

A9 recorded three encodings of "this cell is void" (`CONTAINMENT_FAILED` sentinel, rewritten `result.json`, `voided_cells`), three readers, one `|| true` writer, and no test asserting they agree. This commit adds the audit's exit code as a fourth upstream encoding (F4) and leaves the rest as they were, including the writer:

```bash
    python3 - "$dest/result.json" <<'EOF' || true
```

If that heredoc fails — unreadable `result.json`, a full disk — the sentinel exists and `result.json` still says `subtype: "success"`. `crb-cell-status.py` takes a `result.json` path and so structurally cannot see the sentinel; on a retry it would read the un-rewritten result as complete and bank a voided cell. Four writers-and-readers of one boolean, agreeing by convention, with 37 new tests around them and none asserting the agreement.

**Recommendation:** make the sentinel the single source of truth and derive the other two from it, or add one test that voids a cell and asserts all four views agree. The second is cheap and closes the amber; the first closes the class.

---

#### F8. The containment invariant is now expressed twice, in two languages, with deliberately different semantics and no shared fixture

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:192-222` (`verify_containment`) vs `scripts/crb-audit-clone.sh:44-88`
**Move:** #6 (substitutability), #2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** for-author

The brief asks whether deleting the Python detection in favour of a bash reimplementation created a duplicated-invariant problem. Mostly no, and the divergence is defensible: both check "no remote" and both run `rev-list --all --not <head>`, but `verify_containment` treats *any* stray commit as fatal (correct for a pristine clone) while the audit treats descent from the head as expected agent work and only reports non-descendants (correct for an outgoing clone). Two jobs, two predicates, each documented at its own site. The audit also adds three checks the Python never had (`FETCH_HEAD`, `fsck --no-reflogs`, nested repos), so this is a net gain in coverage, not a translation.

What is missing is any statement that the two *shared* clauses must stay in agreement. `scrub_object_store`'s job — clearing `FETCH_HEAD` and reflog-reachable objects so their later presence is evidence — is a coupling between the Python and the bash that exists only in prose, and the k=3 fact-check notes the migrated suite dropped the non-vacuity case that pinned it while confirming the function is still load-bearing. Delete `scrub_object_store` and the bash audit does not fail; it voids every cell, which reads as contamination.

**Recommendation:** carry the dropped non-vacuity case into `test/crb-disposable-clone.bats` (snapshot without scrubbing → assert the audit voids), which pins the cross-language coupling from the side that would otherwise fail silently.

---

#### F9. Build inputs live inside the arm's output directory

**Severity:** Minor
**Location:** `runs/review-arms/crb-pipeline/docker/` (4 new files); `runs/review-arms/crb-pipeline/run-host.sh:300-303`; `scripts/crb-pipeline-to-benchmark.py:219-220`
**Move:** #1 (dependency direction), #2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-author

Every other executable piece of this commit went to `scripts/`. The Dockerfiles and proxy config went to `runs/review-arms/crb-pipeline/docker/` — inside the directory the runner writes per-cell results into and that two downstream consumers enumerate as cells:

```python
for name in sorted(os.listdir(out)):
    rp = os.path.join(out, name, "result.json")
```

```python
    cells = sorted(p for p in runs.glob("*/") if (p / "review.md").exists()
                   or (p / "artifacts").exists())
```

Neither misfires today (`docker/` has no `result.json`, `review.md`, or `artifacts/`), so this is latent rather than broken — but a `docker/artifacts/` directory would make `docker` a cell in the leaderboard's denominator. The general point is that the containment mechanism is now spread across three homes (`scripts/`, `runs/.../docker/`, and 200 lines inline in `run-host.sh`) on no stated rule, which makes "where does the next piece go?" a coin flip.

**Recommendation:** move `docker/` beside the other executable pieces (`scripts/crb-docker/` or a sibling of `runs/`), or — if colocation with the runner is deliberate — say so in the runner header and make both enumerators skip non-cell names explicitly.

---

#### F10. Two smaller structural observations

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:94`, `:492-495`
**Move:** #7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

(a) `PROXY_IMAGE="crb-egress-proxy:$(git -C "$ROOT" rev-parse --short HEAD)"` keys the allowlist image's identity to the whole repo commit rather than to the contents of `docker/`. Every unrelated commit invalidates the tag, and two different allowlists can share a tag if the sweep runs from a dirty tree. A hash over `docker/` would name what actually varies.

(b) The audit runs inside `$REVIEW_IMAGE` — the same image as the thing it audits. It is convenient (git is present, no second build) and safe today, but it couples the auditor's runtime to the reviewed cell's runtime: slimming the review image or moving off `node:22` breaks the audit into exit 2, which F4 currently publishes as contamination.

---

## What Looks Good

- **Prevention over detection is the right axis, and the commit picks it deliberately.** Decision 034's rejected-alternatives table shows the enumeration options (sanitize `.git/config`, hardened `-c` overrides) were considered and rejected for the correct reason — they require enumerating every config key that can execute code, and two were already missed once. Choosing "do not read it at all" removes the class rather than the instance. This is the single best structural judgement in the change.
- **Wiping deletes the classification problem, not just the state.** `restore_clone()`'s docstring makes the strongest architectural argument in the diff: agent commit, staged edit, created branch, deleted `main`, nested clone all stop being questions that a heuristic has to answer. That is what makes the disposable-clone design a genuine answer to "the same region generated a new mechanism error every round" rather than a fourth patch — the residue in F1–F4 is at the seams, not in the core move.
- **Baking the CLI is load-bearing for the allowlist and the commit knows it.** `Dockerfile.review`'s header states the coupling explicitly: `npx` at run time forces `registry.npmjs.org` into the allowlist for every paid cell. One reachable host is what makes the control meaningful, and the image exists to preserve that property.
- **The proxy image fails closed at build time.** The three `grep -qE` assertions in `Dockerfile.proxy` catch the specific misconfiguration the runtime preflight cannot — a filter that silently matches nothing while `FilterDefaultDeny` is mistyped, which would allow everything. Asserting a config invariant at build time, in the artifact that carries the config, is the right place for it.
- **The harvest boundary is drawn correctly.** `crb-harvest-artifacts.py` takes the baseline index as an argument instead of deriving it, so it is testable in isolation with fixtures and has no opinion about where baselines live. It is the model the rest of F5 should follow.
- **The preflight tests the thing that runs.** `in_cell_net()` runs the three egress legs in the same image, on the same network, with the same proxy env a cell gets, rather than re-describing the configuration — and the three legs fail for genuinely different reasons.
- **The extraction of `crb-cell-status.py` and `crb-audit-clone.sh` gave two previously untestable predicates fixtures** (37 new tests across four suites). The module split itself is sound; the findings above are about the contracts between the new pieces, not about the decision to make them.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | "Host never reads a container-written `.git`" is structural on the cell path, operator-discipline on `--snapshot`; the runner routes operators there | Structural | `scripts/crb-materialize.py:509-521`, `run-host.sh:412-418` | High |
| F2 | Baseline is a two-part contract; only the tar is pinned and gated — a missing/stale index costs a paid cell or corrupts artifact reporting | Structural | `run-host.sh:366-370` vs `:477-481` | High |
| F3 | R6 relocated, not dissolved: all five existing clones fail the new pre-run gate; sweep exits 3 | Structural | `run-host.sh:363-370`, `runs/review-arms/crb/instances.json` | High |
| F4 | Audit's 3-state exit contract collapsed to 2 by its only consumer; infrastructure failure published as contamination | Coupling | `scripts/crb-audit-clone.sh:23`, `run-host.sh:492-508` | High |
| F5 | `run-host.sh` constructs `crb-materialize.py`'s private baseline layout (content coupling) | Coupling | `run-host.sh:366`, `:479`, `crb-materialize.py:70` | High |
| F6 | A12 widened: run-dir path stated four times, twice in one file | Coupling | `run-host.sh:72`, `:92` | High |
| F7 | A9 unaddressed, now four encodings of "void", still no agreement test, still a `\|\| true` writer | Coupling | `run-host.sh:496-508` + 3 readers | High |
| F8 | Containment invariant expressed in two languages; the `scrub_object_store` coupling is prose-only and its non-vacuity test was dropped | Minor | `crb-materialize.py:192-222` vs `crb-audit-clone.sh:44-88` | Medium |
| F9 | Build inputs (`docker/`) live inside the arm's output directory, which two consumers enumerate | Minor | `runs/review-arms/crb-pipeline/docker/` | High |
| F10 | Proxy image tag keyed to repo HEAD, not `docker/` contents; audit shares the review image | Informational | `run-host.sh:94`, `:492-495` | High |

---

## Overall Assessment

This change improves the system's structural integrity, and it is the right answer to the question the escalation asked. Moving detection into a throwaway container and making a cell a wipe-and-extract rather than a repair does not merely relocate the containment problem — it deletes the discriminator that produced three consecutive mechanism errors, which is why the core move should survive review. The module split (`crb-audit-clone.sh`, `crb-harvest-artifacts.py`, `crb-cell-status.py` as leaves; `crb-materialize.py` as the clone-lifecycle owner; `run-host.sh` as orchestration) is the right decomposition, the python/bash/docker boundaries follow the host/container line rather than cutting across it, and the harvest shows the contract done properly.

The problems are all at seams, and they cluster: **the baseline tar + index is a new persisted inter-module contract that has no single owner.** `crb-materialize.py` writes it, `run-host.sh` re-derives its paths and gates on half of it, `crb-harvest-artifacts.py` consumes the other half, and no module validates it as a unit (F2, F5) — which is also why the mandatory migration path was left as a documented human obligation (F1) and why the gate fails closed for every clone that currently exists (F3). Every one of these is fixable in place; none requires restructuring, and the fixes are small (a `--baseline-paths` accessor, an index hash in the manifest, a `--migrate` mode, an exit-code branch).

The single most important structural concern is **F1**: the invariant this whole commit exists to establish is enforced by construction everywhere except the one path all five existing clones must take, and the runner's own error message points operators down it. That is the same shape as the pattern the loop was halted over, appearing once more inside the change meant to end it — not in the core mechanism this time, but at its migration seam. F1, F2, and F3 are one work item in practice (make migration a code path instead of a comment) and should close before any paid cell. F4 should close with them, because it is the finding that decides whether the sweep's published attrition number means anything.

## Goal-Alignment Note
- Answered: yes — the escalated design question is answered, with four seam-level structural residues
- Out of scope: docker execution (deliberate, per brief); security verdicts on egress (security-reviewer owns `B1`–`B6`; F1/F4 flag implications only); implementation quality, test coverage depth, and performance
- Escalate: F1+F2+F3 are one work item (make baseline migration a code path, not an operator instruction) and gate the paid sweep; the `--snapshot` host-git hole in F1 relocates a trust boundary and warrants a security re-read before the sweep, since decision 034's headline invariant is currently false on that path
