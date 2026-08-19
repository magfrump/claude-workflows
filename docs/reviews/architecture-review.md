# Architecture Review — `feat/crb-direction1-harness`

**Commit:** 529ecd2
**Scope:** `git diff main...HEAD` — 7 files, +1209, all newly added (evaluated greenfield)
**Date:** 2026-08-18
**Based on:** Stage-1 code-fact-check (k=3, merged, most-severe-wins) supplied by the orchestrator
**Calibration:** research/experiment harness, small expert-user population, run by hand a
handful of times. Findings are scored on *what breaks the experiment's numbers or the next
person's ability to change a stage*, not on library-grade hygiene.

**Trust-boundary cross-reference:** no-op. `docs/reviews/security-review-*.md` files exist but
are pinned to commit `fbd8597` and a different diff (`scripts/cross-model-review.py`); no Trust
Boundary Map covers this branch, so module-boundary findings below carry no `B*` labels.

---

## Dependency Map

Four stages, coupled **only** through the filesystem — no stage imports another, and no
stage's Python is importable by another (all three scripts are `main()`-only CLIs). The
dependency graph is a straight line with a single shared key (`slug`) and a single shared
contract (the manifest):

```
scripts/crb-materialize.py
  reads   external/code-review-benchmark/offline/results/benchmark_data.json   (vendored, external)
  writes  external/crb-eval/<slug>/                     (clone: branches review + main only)
  writes  runs/review-arms/crb/instances.json           (MANIFEST — slug -> url/fork/head/base/...)
        │
        ├─ runs/review-arms/crb-pipeline/run-host.sh
        │    reads  MANIFEST (keys only), external/crb-eval/<slug>/ (mounted READ-WRITE)
        │    reads  git archive $PAYLOAD_REF -- skills workflows guides patterns CLAUDE.md
        │    writes runs/review-arms/crb-pipeline/<slug>/{transcript.jsonl,result.json,review.md,artifacts/**}
        │    writes runs/review-arms/crb-pipeline/{preflight.json,run-meta.json}
        │           │
        │           └─ scripts/crb-pipeline-to-benchmark.py
        │                reads  MANIFEST (url, fork), the runner's <slug>/ layout,
        │                       artifacts/**/*rubric*.md  ← markdown emitted by skills/code-review/SKILL.md
        │                reads  benchmark_data.json + the benchmark's checked-in judge results
        │                writes runs/review-arms/crb/offline-work-50/{results/benchmark_data.json,results/<judge>/*,RUN.md}
        │                       │
        │                       └─ (vendored) code_review_benchmark.step2/2_5/3   [paid]
        │                            writes results/<judge>/evaluations.json
        │                              └─ scripts/crb-subset-leaderboard.py  (reads that file)
```

Direction is correct and acyclic: each stage depends only on artifacts produced upstream of it,
and nothing upstream knows about anything downstream except as a `print("Next: ...")` hint.
There are no import cycles because there are no imports at all — which is also the source of
most findings below: every contract in the graph is implicit, discovered at runtime, and
duplicated at both ends.

Three couplings cross the repo boundary and deserve naming up front:

1. **To the vendored benchmark** (`external/code-review-benchmark/offline/`): its
   `benchmark_data.json` shape, its `results/<sanitized-model>/` layout, its
   `sanitize_model_name` rule, and — undeclared anywhere in this diff — its
   `RESULTS_DIR = Path("results")` *cwd-relative* convention, which is the only reason the
   "write a work dir and `cd` into it" design functions at all.
2. **To GitHub fork naming** (`slug_for()`), concentrated in five lines — the best-isolated of
   the three.
3. **To this repo's own `skills/code-review/SKILL.md` rubric template** — parsed as markdown by
   `comments_from_rubric()`. This is the seam that worries me most (Finding 2).

---

## Findings

#### 1. The experiment's core validity invariant is asserted once, in the wrong module, and never re-checked after the stage that can violate it

**Severity:** Structural
**Location:** `scripts/crb-materialize.py:186-196`, `runs/review-arms/crb-pipeline/run-host.sh:155-159,200-201`
**Move:** #2 (responsibility boundaries) / #7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

The whole arm rests on one property: the clone under review contains no route to the answer
key. `crb-materialize.py` establishes it and then *proves* it:

```python
    # Guard (a): nothing reachable outside the reviewed head's ancestry.
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
    stray_n = len([l for l in stray.splitlines() if l])
    if stray_n:
        raise RuntimeError(f"{slug}: {stray_n} stray commit(s) survived the scrub")
```

The next stage then mounts that same directory read-write into a container running an agent
with `--dangerously-skip-permissions`, and restores it with a reset that is weaker than the
mutation it undoes:

```bash
  docker run --rm -u node -w /repo \
    -e ANTHROPIC_API_KEY \
    -v "$clone":/repo \
```

```bash
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfd 2>/dev/null || true
```

The materialized clone is therefore simultaneously a *verified experimental artifact* and a
*scratch workspace*, and the module that owns the invariant is not the module that can break
it. Concretely: `clean -qfd` has no `-x` (Stage-1 finding 7), both resets are `|| true`, and
nothing re-runs guard (a) before the next instance or the next sweep. Instance N+1, or a
re-run of instance N months later, reviews whatever instance N left behind — including a
fetched remote, an unpacked stash, or notes an agent wrote into `.git/` — and no artifact
records that the invariant still held at review time. Every number the arm produces inherits
that gap silently, and "the pilot's recall is suspiciously high" is not a failure mode you can
diagnose after the fact.

This clears the Structural bar rather than the Coupling bar because the fix is not a tighter
`clean` flag — it is that the invariant has no seam. There is no callable
`verify_clone_clean(slug)`; guard (a) is fifteen lines welded inside `materialize()`, reachable
only by re-cloning.

**Recommendation:** Extract guards (a)/(b) into a function (or a `scripts/crb-verify-clone.py`
entry point) that takes a clone path and the expected head, call it from `materialize()` as
today, and call it from `run-host.sh` immediately *before* each `docker run` and again after the
reset — aborting the cell on failure. Record the verdict in the cell dir so provenance travels
with the result.

---

#### 2. Stage 3 parses Stage 2's markdown by section-substring and column-name, with no declared contract on either side

**Severity:** Coupling
**Location:** `scripts/crb-pipeline-to-benchmark.py:58-60,97-129`; contract owner
`skills/code-review/SKILL.md:1098-1150`
**Move:** #3 (module boundary) / #7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

```python
FINDING_SECTIONS = ("Must Fix", "Must Address", "Consider")
```

```python
        if not any(s.lower() in section.lower() for s in sections):
            continue
        idx = {h.lower(): i for i, h in enumerate(header)}
        f_i = idx.get("finding")
        if f_i is None:
            continue
```

This is content coupling to a *document template that lives in this same repo and is itself
under active development* — the payload being measured is the very artifact whose output format
the scorer parses. Two concrete leaks confirm the binding is accidental rather than designed:

- `## ↩️ Considered Overrides` passes the substring filter ("Consider" ⊂ "Considered
  Overrides"). It is excluded solely because its column is named `Prior finding`, not
  `Finding` (Stage-1 finding 9). Renaming that column upstream — a cosmetic edit to a
  markdown template — silently injects *prior* findings as *this run's* findings, inflating
  both the candidate count and the FP denominator, with no error anywhere.
- `parse_location()` is dead code for two of the three target sections: only `## 🔴 Must Fix`
  carries a `Location` column; `## 🟡 Must Address` and `## 🟢 Consider` do not
  (`SKILL.md:1114,1125`). The `Location: ...` suffix and `path`/`line` fields will be empty
  for ~90% of rows, which is fine for scoring (judging is text-only) but means the code reads
  as if it handles a case it never sees.

Neither side declares the relationship. `SKILL.md` has no "this table is consumed by
`crb-pipeline-to-benchmark.py`" note, so a future rubric-template edit has no reason to know
it is a published interface.

**Recommendation:** Make the seam explicit in one of two ways. Cheap: add a `<!-- consumers:
scripts/crb-pipeline-to-benchmark.py -->` note next to the rubric template in `SKILL.md`, and
in the parser replace the substring test with an exact match against the three known headings
plus a loud `stderr` warning when a rubric yields zero rows from a section that exists. Right:
have the code-review skill also emit a machine-readable `findings.json` alongside the rubric,
and parse that — the markdown then stays a human artifact and the harness stops being a
downstream consumer of prose.

---

#### 3. Stage 4's default input is a hand-copied projection of Stage 3's defaults; changing `--out` or `--judge` desynchronizes them silently

**Severity:** Coupling
**Location:** `scripts/crb-subset-leaderboard.py:25-27` vs `scripts/crb-pipeline-to-benchmark.py:53-56`
**Move:** #7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

```python
WORKSPACE = Path(__file__).resolve().parent.parent
DEFAULT_EVALS = (WORKSPACE / "runs/review-arms/crb/offline-work-50/results"
                 / "claude-opus-4-5-20251101/evaluations.json")
```

```python
DEFAULT_OUT = WORKSPACE / "runs/review-arms/crb/offline-work-50"
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"
DEFAULT_JUDGE = "claude-opus-4-5-20251101"
```

The leaderboard's default path is `DEFAULT_OUT / "results" / sanitize_model(DEFAULT_JUDGE) /
"evaluations.json"` — recomputed by hand, in a different file, from constants it cannot see
(Stage-1 finding 10). The tool name `mfc-pipeline-e8` is likewise a default in two scripts plus
the runbook the injector generates plus the setup doc. The documented second variant
(`--sections fix address --tool-name ... --out ...-ra`) is exactly the case that breaks this:
run it and the leaderboard's default silently points at the *other* work dir. The failure is
not loud — it exits with "no evaluations at ..." if the dir is missing, or, worse, ranks the
wrong sweep if both exist.

For a three-script harness I would not ask for a config framework. But the projection is
currently *invisible*: nothing in `crb-subset-leaderboard.py` says its default is derived from
another file's defaults.

**Recommendation:** Add a ~15-line `scripts/crb_paths.py` holding `WORKSPACE`, `BENCH`,
`BENCH_DATA`, `MANIFEST`, `DEFAULT_OUT`, `DEFAULT_JUDGE`, `DEFAULT_TOOL`, and
`sanitize_model()`, and import it from all three scripts (the leaderboard then composes its
default instead of restating it). Failing that, at minimum have the injector print — and write
into `RUN.md`, which it already generates — the fully-resolved `--evaluations` path for the
leaderboard, so the two never have to agree by memory.

---

#### 4. The runner's cell layout is a contract, but it lives as four inline heredocs that the consumer re-derives independently

**Severity:** Coupling
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:174-192,203-213,217-236` vs `scripts/crb-pipeline-to-benchmark.py:147-162`
**Move:** #2 (responsibility boundaries) / #7 (coupling surface)
**Confidence:** Medium-High
**Legibility-target:** for-author

The runner writes the cell layout from embedded Python:

```bash
  python3 - "$dest/transcript.jsonl" "$dest/result.json" "$dest/review.md" <<'EOF'
```

and the injector reads it back, restating the same three facts (`review.md`, `artifacts/`,
`result.json`) with no shared definition:

```python
    rubrics = sorted(cell_dir.glob("artifacts/**/*rubric*.md"))
```

```python
    cells = sorted(p for p in runs.glob("*/") if (p / "review.md").exists()
                   or (p / "artifacts").exists())
```

Given that three sibling Python modules already exist in this change, the bash-with-heredocs
factoring buys nothing: the harvest, the per-cell summary, and the `run-meta.json` roll-up are
all pure JSON transforms of files on disk, none of them need docker or bash, and as heredocs
they cannot be imported by the injector, cannot be re-run after a partially-failed sweep, and
cannot be exercised without a live container. `run-meta.json` in particular is sweep-level
provenance that a re-run *should* be able to regenerate standalone — today it is reachable only
by completing a full sweep.

Note also the ambiguity this leaves in the contract: `rubrics[0]` takes the lexicographically
first match of `*rubric*.md`. The code-review skill names its output
`code-review-rubric-<date>-<branch-slug>.md`, but nothing declares that exactly one such file
exists per cell, and the harvest copies *every* changed `.md`/`.json` in the repo under review.

**Recommendation:** Move the harvest + roll-up into `scripts/crb-harvest.py <cell-dir>` and
`scripts/crb-run-meta.py <out-dir>`, called from the loop and re-runnable afterwards. Keep the
cell-layout constants (`review.md`, `result.json`, `artifacts/`, the rubric glob) in the shared
paths module from Finding 3 so the injector consumes the same names rather than re-typing them,
and make the rubric-selection rule explicit (error, or warn, on more than one match).

---

#### 5. Two independent writers of the same vendored `review_comments` contract, with divergent field sets

**Severity:** Coupling
**Location:** `scripts/crb-pipeline-to-benchmark.py:123-128,227-233` vs `scripts/canon-to-crb.py:116-135,199-206`
**Move:** #3 (module boundary) / #8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author

`canon-to-crb.py` (already on `main`) writes the *same* external schema for the reverse
direction, and already carries two converters (`findings_to_comments`, `cubic_to_comments`) that
emit `{"path", "line", "body", "created_at"}`. The new injector adds a third converter shape and
drops/adds fields:

```python
            out.append({
                "path": path,
                "line": line,
                "body": (f"[{prefix}] " if prefix else "") + body
```

```python
        entry["reviews"].append({
            "tool": args.tool_name,
            "repo_name": rec["fork"],
            "pr_url": url,
            "review_comments": comments,
            "source_provenance": prov,
        })
```

`created_at` is present in one writer and absent in the other; `source_provenance` is a
non-schema field this repo invented and injects into a file the vendored steps read. Neither is
harmful today (the extraction step reads `body`), and `source_provenance` is genuinely useful
provenance. The structural point is that "how we express a review in benchmark form" is now
knowledge held in two places that have already drifted, with a third converter (cubic) landing
soon per `run-cubic.sh:125-126`. The next benchmark bump edits two files or breaks one.

**Recommendation:** Extract `make_review(tool, repo_name, pr_url, comments, **extra)` and a
common comment constructor into one module (the same `scripts/crb_*` module as Finding 3) and
have both `canon-to-crb.py` and `crb-pipeline-to-benchmark.py` call it. Decide once whether
`created_at: None` is part of our emitted shape, and put the answer in that module's docstring
alongside a pointer to the vendored consumer.

---

#### 6. The manifest is a persisted cross-stage contract with no schema marker and no validating reader

**Severity:** Minor
**Location:** `runs/review-arms/crb/instances.json`; writer `scripts/crb-materialize.py:210-216`; readers `scripts/crb-pipeline-to-benchmark.py:216-217`, `runs/review-arms/crb-pipeline/run-host.sh:69-71`
**Move:** #3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

```python
    return {
        "url": url, "source_repo": entry["source_repo"], "pr_title": entry["pr_title"],
        "fork": fork, "fork_url": remote, "head": head, "base": base,
```

Three consumers bind to this file, each to a different subset: the runner uses only the keys,
the injector does `rec["url"]` / `rec["fork"]` unguarded, and the docstring at
`crb-materialize.py:29-31` advertises 9 of the 14 fields actually written (Stage-1 finding 13).
The file is tracked, long-lived, and explicitly justified as surviving a clone wipe — i.e. it is
the one durable data contract this branch introduces — yet it carries no version field, and a
manifest written by an older/newer materializer fails as a `KeyError` deep inside the injector's
loop rather than as a diagnosable error. Partial-run behaviour is otherwise good: the manifest
is rewritten after every successful instance, so a sweep interrupted mid-way leaves a valid file.

**Recommendation:** Wrap it: `{"schema": 1, "instances": {...}}`, or at minimum add a
`load_manifest()` helper in the shared module that checks required keys and exits with the
missing slug and field named. Sync the docstring field list to the writer while you are there.

---

#### 7. One conceptual arm split across two sibling directories, and a materializer that diverges from its stated prior art without saying so

**Severity:** Minor
**Location:** `runs/review-arms/crb/instances.json` vs `runs/review-arms/crb-pipeline/`; `scripts/crb-materialize.py:15-16` vs `scripts/prep-cc-review-clones.sh:27-59`
**Move:** #2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** for-author

`runs/review-arms/crb/` already exists and holds the *other* CRB work (`run-cubic.sh`,
`cubic-cli/`, `offline-work/`). This change puts the manifest and the 50-PR work dir there, but
the runner and its cells in a new sibling `crb-pipeline/`. The docstring justifies `runs/` over
`external/`:

```python
# The manifest lives under runs/ (tracked) rather than beside the clones:
# external/ is gitignored, and the slug -> PR mapping is provenance the
# results depend on, so it must survive a clone wipe.
```

which is a good reason for `runs/` — but not an explanation of `crb/` vs `crb-pipeline/`. The
result is that direction-1's four stages read from three directories, and a reader has to know
that `crb/` means "shared CRB state + judge work dirs" while `crb-pipeline/` means "this arm's
cells". Likewise, `crb-materialize.py` says it "mirrors `scripts/prep-cc-review-clones.sh`" and
does mirror the scrub faithfully — but it drops that script's guard (b) (a tree-contents check
for `docs/reviews/` answer-key leakage) in favour of a different guard (b) (non-empty diff), and
switches language, config style (manifest-driven vs. hardcoded table), and idempotency flag
(`--force` vs `$1`). Deliberate divergence is fine; undeclared divergence reads as drift, and
the dropped tree-contents guard is the one a reader would most want justified (the benchmark
forks plausibly contain reviewer artifacts of their own).

**Recommendation:** Add two sentences to the `crb-direction1-setup.md` stage table: why the
manifest lives in `crb/` while cells live in `crb-pipeline/`, and which
`prep-cc-review-clones.sh` guards were intentionally *not* carried over and why.

---

#### 8. The output identity of a scoring variant is spread across three independent flags with no coupling check

**Severity:** Minor
**Location:** `scripts/crb-pipeline-to-benchmark.py:168-183`
**Move:** #8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author

```python
    ap.add_argument("--out", default=str(DEFAULT_OUT), help="benchmark work dir to write")
    ap.add_argument("--tool-name", default="mfc-pipeline-e8",
```

The documented red+amber variant (`crb-direction1-setup.md:99-101`) requires all three of
`--sections`, `--tool-name`, and `--out` to be changed together; nothing enforces that. Running
`--sections fix address` alone overwrites the all-sections work dir *and* replaces the
`mfc-pipeline-e8` review rows in it (the injector deliberately drops the existing same-named
tool at line 226), destroying the comparison the doc asks for. Cheap guard, real consequence
given the stage upstream of it costs $50–200.

**Recommendation:** When `--sections` is not the default, either derive a suffixed
`--tool-name`/`--out` automatically or refuse to run without explicit overrides. This overlaps
the API-consistency critic's territory — treat whichever framing lands first as canonical.

---

#### 9. `slug` is the pipeline's primary key and is derived lossily from a fork name

**Severity:** Informational
**Location:** `scripts/crb-materialize.py:69-74`
**Move:** #7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

```python
def slug_for(repo_name: str) -> str:
    """keycloak__keycloak__claude-code__PR37429__20260310 -> keycloak-PR37429."""
    parts = repo_name.split("__")
    if len(parts) < 4:
        raise ValueError(f"unexpected fork repo name: {repo_name}")
    return f"{parts[1]}-{parts[3]}".replace(".", "_")
```

Good news first: the GitHub-naming coupling is genuinely *concentrated* — five lines, one
function, one failure mode, and it raises rather than guesses. Worth recording only that the
slug discards `parts[0]` (the upstream org), so two forks of same-named repos at the same PR
number would collide, and manifest writes are last-write-wins (`manifest[slug] = rec`) — a
collision would silently merge two PRs into one cell. At 50 known instances this cannot
currently happen; it is a note for whoever extends this to the online half.

**Recommendation:** No action now. If the dataset ever grows, assert slug uniqueness in
`load_prs()` rather than at write time.

---

#### 10. The work-dir design depends on an undeclared cwd-relative convention in the vendored benchmark

**Severity:** Informational
**Location:** `scripts/crb-pipeline-to-benchmark.py:272-296` (generated runbook); vendored contract at `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py` (`RESULTS_DIR = Path("results")`)
**Move:** #4 (layer violations)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```bash
cd {out}
export PYTHONPATH=/workspace/external/code-review-benchmark/offline   # or: uv sync in offline/
```

The entire "write a parallel work dir and let the vendored steps run against it" strategy — the
best structural idea in this change, since it keeps paid judge work and our injected rows out of
the vendored tree — works only because every benchmark step resolves `results/` relative to the
process cwd. That is load-bearing and stated nowhere in this diff; a benchmark bump that
introduces a `--results-dir` flag or an absolute path would break the arm in a way that looks
like a data problem. The generated runbook also hardcodes `/workspace` twice, so it is wrong for
any clone of this repo at another path even though the emitting script computes `WORKSPACE`
itself.

**Recommendation:** One comment above the runbook template naming the `RESULTS_DIR =
Path("results")` dependency and the benchmark commit it was verified against; and interpolate
`WORKSPACE` into the runbook instead of literal `/workspace`.

---

## What Looks Good

- **The stage decomposition is right, and the seams are the right seams.** Materialize / run /
  inject / rank are separable by cost and by execution environment (sandbox vs host vs paid),
  and each has a $0 rehearsal path (`--dry-run`, `DRY_RUN=1`, `--stats`, `--list`). For an
  experiment harness that is the property that matters most, and it was clearly designed for
  rather than stumbled into.
- **Dependency direction is clean and acyclic.** The injector depends on the runner's directory
  layout; the runner knows nothing about the injector beyond a `print("Next: ...")`. No stage
  reaches backwards. Finding 4 is about that layout being restated rather than shared — not
  about the direction being wrong.
- **The manifest is the right artifact in the right place.** Writing provenance to a tracked
  path *because* the clones are gitignored, and writing it incrementally so an interrupted sweep
  leaves a valid file, is exactly the call I would want, and the reason is in the code.
- **The system under test is isolated from the harness by construction.** `git archive
  $PAYLOAD_REF` instead of a bind mount (`run-host.sh:79-87`), a fresh writable `~/.claude` copy
  per instance, and `run-meta.json` recording the payload commit — the arm cannot be
  contaminated by a mid-sweep edit, and the condition that ran is recoverable afterwards.
- **The preflight validates the harness's own identity assumption before spending money**
  (`run-host.sh:119-132`): a mounted-but-unregistered payload would silently measure the E5 arm
  under this arm's name, and the check refuses to proceed. That is a structurally unusual and
  correct thing to build.
- **`crb-subset-leaderboard.py` exists because the author read the vendored tool rather than
  trusting it.** Recomputing every tool over our PR subset instead of accepting step 3's
  mismatched-denominator table is a correct decomposition, and it faithfully reproduces step 3's
  own `tp/(tp+fp)` micro-average convention (verified against
  `step3_judge_comments.py`) — the docstring's claim on that point holds.
- **Judge-cost confinement via seeding** (`crb-pipeline-to-benchmark.py:249-266`) keeps the
  external tool's expensive behaviour on our side of the boundary, and the generated `RUN.md`
  puts the `--tool` requirement next to the commands rather than only in a doc.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Answer-key invariant asserted only in the materializer; runner mutates the same clone and never re-checks | Structural | `scripts/crb-materialize.py:186-196`, `run-host.sh:155-159,200-201` | High |
| 2 | Rubric markdown parsed by section-substring + column-name; contract undeclared on both sides | Coupling | `scripts/crb-pipeline-to-benchmark.py:58-60,97-129` | High |
| 3 | Leaderboard default path hand-copies the injector's `--out`/`--judge` defaults | Coupling | `scripts/crb-subset-leaderboard.py:25-27` | High |
| 4 | Cell layout defined in bash heredocs, re-derived by the injector; harvest/roll-up not re-runnable | Coupling | `run-host.sh:174-236`, `crb-pipeline-to-benchmark.py:147-162` | Medium-High |
| 5 | Two independent writers of the vendored `review_comments` shape, already divergent | Coupling | `crb-pipeline-to-benchmark.py:123-128,227-233` vs `canon-to-crb.py:116-135` | Medium |
| 6 | Manifest is a durable contract with no schema marker or validating reader | Minor | `runs/review-arms/crb/instances.json`, `crb-materialize.py:210-216` | High |
| 7 | Arm split across `crb/` and `crb-pipeline/`; undeclared divergence from `prep-cc-review-clones.sh` | Minor | `runs/review-arms/crb*`, `crb-materialize.py:15-16` | Medium |
| 8 | Scoring-variant identity spread across `--sections`/`--tool-name`/`--out` with no coupling check | Minor | `crb-pipeline-to-benchmark.py:168-183` | Medium |
| 9 | `slug` primary key is lossy; collisions would silently merge cells | Informational | `crb-materialize.py:69-74` | Medium |
| 10 | Work-dir strategy depends on the benchmark's undeclared cwd-relative `RESULTS_DIR` | Informational | `crb-pipeline-to-benchmark.py:272-296` | High |

---

## Overall Assessment

Structurally this is a good harness. The four-stage split is drawn along the axes that actually
matter for an experiment (cost, execution environment, reversibility), dependencies flow one way
with no cycles, the system under test is properly isolated from the thing measuring it, and the
author verified the vendored benchmark's behaviour rather than assuming it. Nothing here needs
restructuring; every finding is fixable in place, and findings 3–6 collapse into roughly one
afternoon of work — a small shared `scripts/crb_*` module holding the paths, the manifest
loader, the cell-layout names, and the benchmark review constructor, which would remove four
separate hand-copied projections at once.

The single most important structural concern is Finding 1. The arm's entire output is a claim
about recall on uncontaminated inputs, and the guard that makes that claim true lives in a
module that runs once, months before the stage that can invalidate it, with no seam by which the
runner can re-assert it. Everything else on this list costs a future maintainer some time; that
one costs the numbers their meaning, silently, in a direction that looks like success. Fix it
before the pilot spends money, not after — and given the setup doc already names skill
registration as "the single highest-risk assumption in the chain," per-cell clone verification
belongs in the same preflight discipline that assumption already earned.

---

## Goal-Alignment Note
- Answered: yes — structural critique of the branch diff, saved to `docs/reviews/architecture-review.md`
- Out of scope: test coverage recommendations (deferred to the parallel test-strategy critic — Finding 4 names only the *structure* that makes the harvest/roll-up untestable, not what tests to write); correctness/security/perf of the docker and git invocations; re-verification of Stage-1's 16 documented findings
- Escalate: Finding 1 (per-cell clone re-verification) should be actioned before any paid sweep, not merged as follow-up; Finding 8 overlaps the API-consistency critic's CLI-contract territory and should be de-duplicated at synthesis
