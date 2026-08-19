# Architecture Review — `feat/crb-direction1-harness` (pass 2, fix adjudication)

**Commit:** ed68ced
**Scope:** `git diff 529ecd2..ed68ced` — 7 files (+445/−60). `529ecd2` and earlier are context
only. This is the **fix pass** for the pass-1 review at `Commit: 529ecd2`.
**Date:** 2026-08-18
**Based on:** pass-1 `docs/reviews/architecture-review.md` (findings 1–10), the rubric at
`docs/reviews/code-review-rubric-2026-08-18-feat-crb-direction1-harness.md` (R1–R3, A1–A26,
C1–C11), and the fix commit's own claim ledger.
**Calibration:** research/experiment harness, small expert-user population, finite lifetime, run
by hand a handful of times. A finding correct for a shared library may be noise here; I have
deliberately down-ranked several.

> ⚠️ **No code fact-check report was produced for `ed68ced`.** The Stage-1 fact-check reports in
> `docs/reviews/` are pinned to `529ecd2`. Claims in comments/docstrings *added by this commit*
> are therefore unverified except where I read the code directly. Everything below rests on
> read-only inspection of the working tree; no git-mutating verification was attempted.

**Trust-boundary cross-reference:** no-op. `docs/reviews/security-review.md` exists but is pinned
to `529ecd2` and carries no Trust Boundary Map covering `ed68ced`; module-boundary findings below
carry no `B*` labels.

---

## Verdict Table — pass-1 findings

The primary output of this pass. Detail for anything not "closed" is in the Findings section.

| Pass-1 finding | Severity (pass 1) | Verdict | One-line reason |
|---|---|---|---|
| 1 — containment asserted once, no seam | Structural | **Partially closed** | Seam built and called both sides; post-run verdict is advisory-only and is not recorded in the cell dir, as the recommendation required (→ A1) |
| 2 — rubric markdown parsed by substring | Coupling | **Partially closed** | Consumer side anchored + guarded by a test; the producer (`skills/code-review/SKILL.md`) still carries no declaration (→ A3) |
| 3 — leaderboard hand-copies injector defaults | Coupling | **Closed on harm, regressed on mechanism** | Runtime desync fixed by flags; the hand-copy went from one derived path to three duplicated constants + a duplicated function (→ A2) |
| 4 — cell layout in bash heredocs | Coupling | **Not closed; marginally worse** | A fifth heredoc added; harvest grew in complexity while staying inline and unrunnable standalone (→ A4) |
| 5 — two writers of `review_comments` | Coupling | **Not closed** | Deliberately deferred; untouched |
| 6 — manifest has no schema marker / validating reader | Minor | **Partially closed** | Docstring key list synced to the writer; `--verify` adds a *third* consumer that reads the manifest unguarded and degrades silently (→ A5) |
| 7 — arm split `crb/` vs `crb-pipeline/`; undeclared divergence from `prep-cc-review-clones.sh` | Minor | **Not closed; legibility regressed** | Split unexplained; "guard (b)" now means three different things across two files (→ A6) |
| 8 — variant identity spread across `--sections`/`--tool-name`/`--out` | Minor | **Not closed (doc-only mitigation)** | Setup doc now explains the separate work dir; no coupling check in code |
| 9 — lossy `slug` primary key | Informational | **Not closed (not claimed)** | Charset validation added for a different reason (A6/security); collision semantics unchanged |
| 10 — undeclared cwd-relative `RESULTS_DIR`; `/workspace` hardcoded in the runbook | Informational | **Split verdict** | `judge.sh` encodes the cwd dependency mechanically and interpolates paths correctly; `RUN.md` still hardcodes `/workspace` twice — the two runbooks now disagree (→ A7) |

**New surface reviewed fresh:** `verify_containment()` + `--verify` (A1, A2, A5), `judge.sh`
(A7, A8), `SWEEP_BUDGET` (see api-consistency review), `normalize_section()` (A3),
`test/crb-injector-sections.bats` (What Looks Good + A9).

---

## Dependency Map (delta only)

Pass 1 described a four-stage line coupled *only* through the filesystem: "no stage imports
another." That is no longer true. This commit adds one process-level edge and one generated
artifact:

```
scripts/crb-materialize.py
  ├─ verify_containment(dst, slug, head)          [NEW public-ish function]
  └─ --verify SLUG ...                            [NEW CLI mode, read-only, early-return]
        ▲
        │ exec (2x per cell: pre-run, post-run)   [NEW EDGE — runner depends on stage-1 CLI]
        │
runs/review-arms/crb-pipeline/run-host.sh
        │ reads MANIFEST (keys) — unchanged
        │
scripts/crb-pipeline-to-benchmark.py
  ├─ normalize_section()                          [NEW public function]
  └─ writes  <out>/RUN.md      (prose runbook, pre-existing)
     writes  <out>/judge.sh    [NEW generated executable, 0755, absolute host paths baked in]
        │
scripts/crb-subset-leaderboard.py
  ├─ DEFAULT_OUT / DEFAULT_JUDGE                  [NEW — literal duplicates of the injector's]
  └─ sanitize_model()                             [NEW — 2nd in-repo copy, 5th overall]
```

Direction of the new edge is **downstream → upstream** in pipeline order (stage 2 calls stage 1),
which is the correct direction and introduces no cycle: `crb-materialize.py` still knows nothing
about the runner beyond one comment. The concern is not the direction but the *granularity* —
the runner now depends on a whole CLI whose other modes clone, `shutil.rmtree`, and `git gc`
(A2).

---

## Findings

#### A1. The containment guard now has a seam and is called, but its post-run verdict is advisory prose with no artifact and no enforcement

**Severity:** Coupling (down from pass-1's Structural — the seam exists and the pre-run arm is
enforcing)
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:177-178`, `:236-237`;
`scripts/crb-materialize.py:167-195`
**Move:** #2 (responsibility boundaries) / #3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence** — the two call sites are not symmetric:

```bash
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2; continue; }
```

```bash
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" \
    || echo "$id: POST-RUN containment check FAILED — treat this cell's result as void" >&2
```

The pre-run arm enforces. The post-run arm emits a sentence to a scrollback and then falls
through to the per-cell summary and the sweep-budget gate as if nothing happened. Concretely,
after a post-run failure:

- `$dest/result.json` is written and stays. The resume predicate
  (`run-host.sh:150-159`) tests `num_turns > 0 AND NOT is_error AND subtype == "success"` —
  containment is not part of it — so the **next** sweep prints
  `completed result exists, skipping` and banks the void cell as good.
- `run-meta.json` (unchanged by this commit) records model, payload ref and cost but carries no
  containment field, so nothing in the sweep's provenance says the check ever ran, let alone
  what it said.
- The injector (`crb-pipeline-to-benchmark.py:load_cell`) reads `review.md` / `artifacts/` and has
  no way to learn the cell was void.

Pass 1's recommendation was explicit on this point: "*aborting the cell on failure. Record the
verdict in the cell dir so provenance travels with the result.*" Half the recommendation landed.
The half that did not is the half that survives the terminal session — and "the pilot's recall
is suspiciously high" is still not a failure mode you can diagnose after the fact, because the
only record that containment broke is a line of stderr that nobody keeps.

There is also a mass-skip shape worth naming: a containment break that *persists* (e.g. a remote
re-added and left in place) makes every subsequent cell's **pre-run** check fail, each one
`continue`s, and the sweep exits 0 having reviewed nothing. That is the same exit-0-after-skipping
-everything hole the api-consistency review's F5 named, now with a second trigger.

**Recommendation:** Write the verdict where the result lives — one `$dest/containment.json`
(`{"pre": "ok", "post": "failed", "detail": "..."}`), have the resume predicate refuse to skip a
cell whose `post` is not `ok`, and fold a `containment` roll-up into `run-meta.json`. If a
post-run failure should not abort the sweep (reasonable — one bad cell shouldn't kill 49 good
ones), then at minimum `mv "$dest" "$dest.void-$(date +%s)"` so the next run cannot inherit it.
Separately, track a skip counter and exit non-zero if every requested instance was skipped.

---

#### A2. Finding 3's harm is closed, but its mechanism was made worse: the fix commit added a second in-repo `sanitize_model` and two duplicated constants, held together by a comment

**Severity:** Coupling
**Location:** `scripts/crb-subset-leaderboard.py:30-35` vs `scripts/crb-pipeline-to-benchmark.py:57-60,80-81`
**Move:** #7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence** — the leaderboard now holds its own copies:

```python
# Kept in sync with crb-pipeline-to-benchmark.py's defaults. --judge/--out
# there change where evaluations land, so both are flags here too rather than
# a hard-coded path that silently misses and reports "run step 3 first".
DEFAULT_OUT = WORKSPACE / "runs/review-arms/crb/offline-work-50"
DEFAULT_JUDGE = "claude-opus-4-5-20251101"


def sanitize_model(model: str) -> str:
    return model.strip().replace("/", "_")
```

against the injector, unchanged:

```python
DEFAULT_OUT = WORKSPACE / "runs/review-arms/crb/offline-work-50"
MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"
DEFAULT_JUDGE = "claude-opus-4-5-20251101"
```

```python
def sanitize_model(model: str) -> str:
    return model.strip().replace("/", "_")
```

**Assessed honestly, as asked:** the *runtime* failure pass-1 finding 3 described is genuinely
gone. `--out`/`--judge` compose on both sides, the constructed path
(`Path(args.out) / "results" / sanitize_model(args.judge) / "evaluations.json"`) is
character-for-character what the injector writes to `jdir`, and `--evaluations` still short-
circuits both. That is a real close, and the flag design is right.

But the *mechanism* the finding named — "a hand-copied projection … nothing says its default is
derived from another file's defaults" — is now larger, not smaller. Before: one derived path.
After: two duplicated literals plus a duplicated four-token function, with a prose comment
("Kept in sync with…") as the only linkage. A comment is documentation, not a mechanism; nothing
fails if `DEFAULT_JUDGE` moves in one file, and the resulting breakage is the exact
"no evaluations at … — run step 3 first" misdiagnosis this commit set out to eliminate.

**On the deferral of the shared `crb_*` module:** partially defensible. For rubric item C7 — the
full module absorbing the manifest loader, the cell-layout names, and the benchmark review
constructor (findings 4, 5, 6) — the tech-debt lifetime evidence is good and I would not overrule
it inside a sweep window. But that argument does not cover the three constants *this commit
chose to hand-copy*. A ~10-line `scripts/crb_paths.py` holding `WORKSPACE`, `DEFAULT_OUT`,
`DEFAULT_JUDGE`, `sanitize_model` is not the C7 refactor; it is smaller than the comment that
replaced it, touches two files, and is the one place where the fix commit supplied its own
counter-evidence about drift.

**Recommendation:** Either extract the four names into `scripts/crb_paths.py` and import from
both, or — if even that is unwanted mid-sweep — add three assert lines to
`test/crb-injector-sections.bats` (which already loads the injector as a module) that import both
scripts and assert `DEFAULT_OUT`, `DEFAULT_JUDGE`, and `sanitize_model("a/b")` agree. Three lines
turn the comment into a mechanism at zero refactor risk.

---

#### A3. Finding 2's failure mode is closed and now tested; the contract is still declared on only one side

**Severity:** Minor (down from Coupling)
**Location:** `scripts/crb-pipeline-to-benchmark.py:63-78,114-121`; producer
`skills/code-review/SKILL.md`; test `test/crb-injector-sections.bats`
**Move:** #3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```python
def normalize_section(title: str) -> str:
    """Rubric heading -> comparable key. Strips the emoji and punctuation the
    template decorates headings with ("## 🔴 Must Fix" -> "must fix")."""
    return re.sub(r"[^a-z ]", "", title.lower()).strip()
```

```python
    wanted = {normalize_section(s) for s in sections}
    for section, header, rows in md_tables(md):
        if normalize_section(section) not in wanted:
            continue
```

**Does the test constitute declaring the contract?** Partly, and more than I expected. The
substring hole is genuinely gone — `normalize_section("↩️ Considered Overrides")` is
`"considered overrides"`, which is not in the wanted set, so the exclusion no longer depends on a
column name owned by another file. And
`test/crb-injector-sections.bats:"renaming the Considered Overrides column to Finding is inert"`
converts the original silent-injection scenario into a red test. I confirmed the fixture at
`test/skills/code-review/rubric-current-format.md:47-48` really does contain
`| Prior finding |` and one data row beneath it, so that test is non-vacuous, and the suite passes
8/8.

What is still missing is producer-side discoverability, which is what "declared" meant. Nothing
in `skills/code-review/SKILL.md` says its rubric headings are a published interface. An author
editing that template gets a CI failure (good) but no signal at the point of edit about *why*
their cosmetic rename broke a benchmark harness — and the failure surfaces in a test file whose
name (`crb-injector-sections`) does not obviously belong to them. The cheap half of pass-1's
recommendation — a one-line `<!-- consumers: scripts/crb-pipeline-to-benchmark.py -->` next to the
template — was not done and costs one line.

`parse_location()` remains dead for two of the three target sections (pass-1 finding 2's second
bullet); unaddressed and unclaimed, still harmless.

**Recommendation:** Add the consumer comment to `skills/code-review/SKILL.md` next to the rubric
table template, naming both `scripts/crb-pipeline-to-benchmark.py` and
`test/crb-injector-sections.bats`. One line closes this finding.

---

#### A4. Finding 4 is untouched and slightly worse: a fifth inline heredoc, and a harvest that grew logic while staying unrunnable standalone

**Severity:** Coupling
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:216-231`, `:246-263`
**Move:** #2 (responsibility boundaries) / #7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence** — the sweep-budget gate is a new sixth embedded Python program:

```bash
  python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
import json, os, sys
out, cap = sys.argv[1], float(sys.argv[2])
total = 0.0
for name in os.listdir(out):
    rp = os.path.join(out, name, "result.json")
```

and the harvest gained three non-obvious behaviours while remaining inline:

```bash
  (cd "$clone" && git status --porcelain=v1 -z --untracked-files=all) \
    | tr '\0' '\n' | cut -c4- | grep -E '\.(md|json)$' \
```

The budget gate is *re-derivable sweep state* — it walks `$OUT/*/result.json` and sums
`total_cost_usd`, which is exactly the roll-up `run-meta.json` performs, computed a second time,
inline, with no way to ask "what has this sweep spent?" without starting a sweep. That is
finding 4's shape reproduced in a new place: pure JSON transforms of files on disk, needing
neither docker nor bash, unavailable to the injector, and unexercisable without a live container.
The `-z`/`cut -c4-`/`--no-dereference` harvest changes are all correct fixes (A16/A7) but they
raise the amount of untested logic living in a heredoc rather than lowering it.

Calibrated down from a stronger call because the fixes themselves are right and the alternative
(three new script files mid-sweep) carries its own risk. This is a "the debt grew while you were
paying other debt" note, not a blocker.

**Recommendation:** When the sweep window closes, lift the budget gate and the roll-up into one
`scripts/crb-sweep-status.py <out-dir>` that both the loop and a human can run. Doing that alone
also gives the operator the "how much have I spent" answer that currently requires finishing.

---

#### A5. `--verify` makes the manifest a third-consumer contract and reads it unguarded, degrading silently to a vacuous check

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:273-295`, `:167-195`
**Move:** #3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```python
        manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
```

```python
                # Pin to the manifest's recorded head where we have it, so a
                # clone whose `review` ref was moved fails instead of passing
                # against its own new tip.
                head = (manifest.get(slug) or {}).get("head")
                n_commits, stat = verify_containment(dst, slug, head)
```

```python
    if head is None:
        head = sh(["git", "rev-parse", "review"], cwd=dst)
```

The comment states the reason the pinned head matters: an agent that moved the `review` ref must
fail. The code then supplies the fallback that defeats exactly that, whenever the manifest is
absent or lacks the slug — and does so **silently**, printing `containment ok` either way. Guard
(a) becomes `git rev-list --all --not <current review tip>`, which cannot fail on commits the
agent itself added to `review`.

On the happy path this is unreachable: `run-host.sh:63` hard-exits without a manifest and derives
`INSTANCES` from its keys. But it is precisely pass-1 finding 6's harm (a durable cross-stage
contract with no validating reader) landing in the *new* code, and this is now the third consumer
binding to a different subset of the manifest. A verification routine that can quietly weaken
itself is the wrong kind of routine to be permissive.

**Recommendation:** Make the fallback loud — `print(f"  !! {slug}: no manifest head; verifying
against the clone's own review tip (weaker check)", file=sys.stderr)` — or refuse: require a
manifest head unless an explicit `--unpinned` is passed. Sync this with finding 6's
`load_manifest()` helper whenever that lands.

---

#### A6. "Guard (b)" now names three different checks across two files, and the divergence from `prep-cc-review-clones.sh` is larger and still undeclared

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:167-195` vs `scripts/prep-cc-review-clones.sh:40-58`
**Move:** #2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-author

**Evidence** — the new docstring re-letters the guards:

```python
    Guard (a) nothing reachable outside the reviewed head's ancestry;
    (b) no remote survives (a re-added remote is the route by which a reviewing
        agent could fetch the merged upstream fix — the answer key);
    (c) the review range is non-empty and the blobs its diff touches are present
        locally, so a partial/broken clone fails here rather than mid-review.
```

`prep-cc-review-clones.sh` calls its guard (b) a **tree-contents check for `docs/reviews/`
answer-key leakage**. Pre-fix `crb-materialize.py` called its guard (b) the **non-empty-range**
check. Post-fix, guard (b) is **no remotes**, and the non-empty-range check has been renamed (c).
So the shared vocabulary between the two scripts — which pass-1 finding 7 already flagged as
undeclared divergence — now has one label with three referents, and a reader comparing the two
files will silently mis-map them. The prior art's actual guard (b) is still absent, still
unjustified.

Pass-1 finding 7's other half (why the manifest lives in `crb/` while cells live in
`crb-pipeline/`) is likewise unaddressed; the setup doc's new content covers the per-cell guards
but not the directory split.

Honest counterweight: the new guard (b) is a genuinely good addition. "No remote survives" is a
sharper statement of the invariant than the ref-scrub alone, and the commit message reports it
was proven non-vacuous by adding a remote. That is the right kind of verification.

**Recommendation:** Rename the guards to what they check (`no_stray_refs`, `no_remotes`,
`nonempty_range`) rather than letters, and add two sentences to the setup doc's stage table:
which `prep-cc-review-clones.sh` guards were deliberately not carried over, and why `crb/` vs
`crb-pipeline/`.

---

#### A7. Two runbooks now describe the same four steps, and they disagree on portability and on the endpoint guard

**Severity:** Minor
**Location:** `scripts/crb-pipeline-to-benchmark.py:305-330` (`RUN.md`) vs `:332-371` (`judge.sh`)
**Move:** #4 (layer violations) / #8 (extension points)
**Confidence:** High
**Legibility-target:** for-author

**Evidence** — `RUN.md`, unchanged by this commit apart from the `--tool` cost note:

```python
export PYTHONPATH=/workspace/external/code-review-benchmark/offline   # or: uv sync in offline/
export MARTIAN_API_KEY="$ANTHROPIC_API_KEY"
export MARTIAN_BASE_URL=https://api.anthropic.com/v1/
```

```python
python3 /workspace/scripts/crb-subset-leaderboard.py \\
```

versus `judge.sh`, generated in the same function:

```python
export PYTHONPATH="${{PYTHONPATH:-{BENCH}}}"
```

```python
python3 {WORKSPACE}/scripts/crb-subset-leaderboard.py \\
```

`judge.sh` is the better artifact on every axis pass-1 finding 10 raised. It interpolates the
computed `WORKSPACE`/`BENCH` instead of a literal `/workspace`; its `cd "$(dirname "$0")"`
*mechanically encodes* the vendored benchmark's undeclared cwd-relative `RESULTS_DIR` convention
rather than leaving it as a step a human must not skip; and its `case`-guard on
`MARTIAN_BASE_URL` fails closed where `RUN.md` can only advise. So one of the two runbooks fixed
finding 10 and the other still contains it.

That is the divergence risk. Two files, same steps, generated side by side, one hardened and one
not — and the setup doc now points at `judge.sh` as "preferred" while keeping the hand version as
"equivalent by hand (both footguns are on you)", which is honest but leaves a wrong `/workspace`
in the artifact a reader is most likely to open first (`RUN.md` is a `.md`; `judge.sh` is not).

Neither runbook, incidentally, names the `RESULTS_DIR = Path("results")` dependency or the
benchmark commit it was verified against — pass-1 finding 10's actual recommendation.

**Recommendation:** Make `RUN.md` a thin pointer — "run `./judge.sh`; the commands it runs are
below for reference" — generated from the same f-string variables so `/workspace` cannot survive,
and add the one-line `RESULTS_DIR` note above the template. If the two must stay independent,
derive both from one dict of interpolated values.

---

#### A8. `judge.sh` is a machine-specific generated executable written into a tracked directory

**Severity:** Informational
**Location:** `scripts/crb-pipeline-to-benchmark.py:368-371`; output path
`runs/review-arms/crb/offline-work-50/judge.sh`
**Move:** #3 (module boundary)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**

```python
    judge_path = out / "judge.sh"
    judge_path.write_text(judge_sh)
    judge_path.chmod(0o755)
```

`.gitignore` has no entry covering `runs/review-arms/crb/offline-work-50/` (I checked: no `crb`
or `offline-work` pattern exists). The generated script bakes in absolute host paths — `{BENCH}`
and `{WORKSPACE}` resolve to `/workspace/...` on this machine — and the judge model id. So the
work dir's contract now includes a checked-in, mode-0755, host-specific artifact alongside
`RUN.md`, and re-running the injector on a different checkout produces a diff that is pure
environment noise.

This is genuinely minor for a finite-lifetime harness on one machine, and the artifact's value
(the `MARTIAN_BASE_URL` fail-closed guard, `--tool` on all three steps) clearly exceeds the cost.
Recorded so the choice is conscious.

**Recommendation:** Either `.gitignore` the generated pair (`runs/review-arms/crb/offline-work-*/judge.sh`)
or add a `# Generated — machine-specific paths; do not review the diff` header line making its
churn expected. No action required before the pilot.

---

#### A9. The new containment guard is placed inside the payload copy's lifetime, so a skipped cell leaks a temp dir

**Severity:** Minor
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:168-178`, `:195`
**Move:** #2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-author

**Evidence** — order of operations in the cell body:

```bash
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
```

```bash
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2; continue; }
```

```bash
  rm -rf "$INST_HOME"
```

`continue` jumps past the only `rm -rf "$INST_HOME"`, so every pre-run containment failure leaves
a full copy of `skills/ workflows/ guides/ patterns/ CLAUDE.md` in `$TMPDIR` for the life of the
session. The same `continue` also leaves an empty `$dest` behind (`mkdir -p "$dest"` runs earlier
at `:158`). Both are cheap individually; the persistent-break scenario in A1 multiplies them by
N.

Structurally the point is placement: a cheap read-only precondition was inserted *after* the
expensive resource acquisition it should gate. Moving it above `mkdir -p "$dest"` costs nothing
and makes the guard a true precondition.

**Recommendation:** Move the pre-run `--verify` call above `mkdir -p "$dest"` (line 163), before
`INST_HOME` is created. Optionally add `trap 'rm -rf "$INST_HOME"' RETURN`-equivalent discipline
if the loop body grows more early exits.

---

## What Looks Good

- **The seam is real and it is called from both sides.** `verify_containment(dst, slug, head)`
  raising `RuntimeError` and returning `(n_commits, stat)` fits both call sites cleanly:
  `materialize()` consumes the return value to populate the manifest's `files_changed`/
  `insertions`/`deletions`, and the `--verify` path consumes it for the human-readable
  `containment ok — N commit(s), <stat>` line. One function, two consumers, no flag arguments
  steering internal behaviour — that is a well-shaped extraction, and it removed fifteen lines of
  welded logic from `materialize()` without changing its behaviour.
- **Adding "no remote survives" as a guard is a better statement of the invariant than the
  ref-scrub was.** The ref scrub proves what is *reachable now*; the remote check proves what is
  *fetchable next*. Pass 1 asked for the guard to be re-assertable; the author additionally
  sharpened what it asserts, and the commit message reports proving it non-vacuous by adding a
  remote. That is the discipline this arm needs.
- **`normalize_section()` is the right size of abstraction.** One regex, one docstring naming the
  concrete input and output, applied symmetrically to both the wanted set and the observed
  headings. It fixes the substring hole without inventing a schema.
- **`test/crb-injector-sections.bats` follows the repo's conventions closely.** `# @category fast`
  on line 2 matches 20+ sibling suites; it reuses the already-drift-guarded golden at
  `test/skills/code-review/rubric-current-format.md` rather than minting a fixture (exactly what
  rubric item C1 asked for); it is hermetic (no network, no repo mutation, `$BATS_TEST_TMPDIR` for
  the sed output); and the `probe()` helper loading the injector via `importlib` is the cleanest
  way to unit-test a `main()`-only CLI without introducing pytest — which rubric item C4
  explicitly warned against. I ran it: 8/8 pass, and the rename test is non-vacuous against the
  fixture.
- **`judge.sh` turns two documentation-only controls into mechanical ones.** The
  `MARTIAN_BASE_URL` `case` guard and `--tool` on all three steps were previously "things the
  operator must remember" under a ~2233-paid-call and a credential-exfiltration exposure
  respectively. Encoding them, with a named override (`CRB_ALLOW_FOREIGN_ENDPOINT=1`) rather than
  no escape hatch, is the right trade.
- **The resume predicate now means what its name means.** `num_turns > 0 AND NOT is_error AND
  subtype == "success"`, plus the `prior result was incomplete/errored, re-running` line so the
  operator sees the retry rather than inferring it. Small change, closes a real money hole.
- **Judge seeding now fails closed** (`sys.exit` instead of `print`) with an error naming both the
  cost consequence and the deliberate escape (`--no-seed`). The three-branch loop is correct on
  the subtle case: a missing seed source with an already-present destination is *kept*, not
  rejected.
- **The doc corrections are unusually honest.** The golden-denominator caveat carries an explicit
  `*(Corrected 2026-08-18: this caveat previously read … which understated the effect ~12×)*`
  parenthetical, and caveat 2b names a bias running in *our own favour*. Recording a correction
  and a self-flattering asymmetry in the same edit is the behaviour that makes the rest of the
  numbers believable.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| A1 | Post-run containment verdict is advisory-only; not recorded in the cell dir, not in the resume predicate, not in `run-meta.json` | Coupling | `run-host.sh:236-237`, `:150-159` | High |
| A2 | Finding 3's harm closed but mechanism worsened — 2nd in-repo `sanitize_model` + duplicated `DEFAULT_OUT`/`DEFAULT_JUDGE` linked only by a comment | Coupling | `crb-subset-leaderboard.py:30-35` | High |
| A3 | Rubric contract anchored and tested on the consumer side; producer `SKILL.md` still carries no declaration | Minor | `crb-pipeline-to-benchmark.py:63-78`; `skills/code-review/SKILL.md` | High |
| A4 | Finding 4 untouched and marginally worse — a fifth inline heredoc (sweep-budget roll-up) not re-runnable standalone | Coupling | `run-host.sh:246-263` | High |
| A5 | `--verify` reads the manifest unguarded and silently falls back to a vacuous self-referential head | Minor | `crb-materialize.py:273-295`, `:178-179` | High |
| A6 | "Guard (b)" now names three different checks across two files; `prep-cc-review-clones.sh` divergence still undeclared | Minor | `crb-materialize.py:167-195` | High |
| A7 | `judge.sh` and `RUN.md` describe the same steps and disagree — `/workspace` hardcoded and no endpoint guard in the latter | Minor | `crb-pipeline-to-benchmark.py:305-371` | High |
| A8 | Generated 0755 `judge.sh` with absolute host paths lands in a tracked directory | Informational | `crb-pipeline-to-benchmark.py:368-371` | High |
| A9 | Pre-run guard placed after `mktemp -d`, so a skipped cell leaks the payload copy and an empty `$dest` | Minor | `run-host.sh:168-178`, `:195` | High |

---

## Overall Assessment

The fix pass improves the system's structural integrity, and the single most important pass-1
concern moved in the right direction: the answer-key invariant now has a callable seam, that seam
is invoked around every cell, its guard set is *stronger* than what it replaced, and the extraction
left `materialize()` cleaner than it found it. The seam's contract — raise on failure, return
`(n_commits, stat)` — genuinely fits both call sites without steering flags. `--verify` as a CLI
mode is a defensible addition to that module's role in the sense that verification is the natural
inverse of materialization; my reservation is granularity, not concept (A2's cousin: the runner
now execs a binary whose other modes `rmtree` and `git gc`, which in *this* repo, three commits
after a ref-destruction incident, is worth one sentence of thought — a `scripts/crb-verify-clone.py`
would carry the same seam with a fraction of the blast radius).

The honest disappointment is A1 and A2, which share a shape: the fix commit did the enforcing half
and left the recording half. Containment is checked but the verdict evaporates; the leaderboard's
defaults compose but the constants were copied. In both cases the pass-1 recommendation named the
missing half explicitly. Neither is expensive — a `containment.json` per cell and a ten-line
`crb_paths.py` (or three assertions in the bats suite that already loads these modules) would close
both.

On the deferred shared module: defensible for C7's full scope, not for what this commit actually
did. The tech-debt lifetime evidence argues against *refactoring* inside the sweep window; it does
not argue for *adding* a third `sanitize_model` and two duplicated constants, which is a net
increase in the very projection surface finding 3 measured. Take the deferral, but do not let it
launder new duplication.

Nothing here needs restructuring and nothing blocks the pilot. Sequence: A1's `containment.json`
before any paid sweep (it is the only finding whose absence corrupts results silently), A9 alongside
it (one line move), A3 and A2's three-line assertion whenever the file is next open, and the rest
after the sweep window closes.

---

## Goal-Alignment Note
- Answered: yes — per-finding closure verdicts for pass-1 findings 1–10 plus nine findings on the new surface
- Out of scope: correctness/security/performance of the new docker, git and `judge.sh` invocations (other critics); re-verification of Stage-1's `529ecd2` findings; the contract findings, which are in `docs/reviews/api-consistency-review.md` under the same commit; no git-mutating verification was attempted per the safety constraint, so all claims rest on read-only inspection plus one read-only `bats` run of `test/crb-injector-sections.bats`
- Escalate: **A1 is the one to action before any paid sweep** — pass-1 finding 1 is only half closed, and the unclosed half (no per-cell containment record, containment absent from the resume predicate) means a void cell is silently re-banked as complete on the next sweep, which is the same silent-success failure mode the original Structural finding was about. Also escalate the **mass-skip exit-0** shape shared by A1 and the api-consistency review's F5 — a persistent containment break makes the sweep skip all 50 cells and exit 0. A2's three-line assertion and A9's one-line move are cheap enough to fold into the same edit.
