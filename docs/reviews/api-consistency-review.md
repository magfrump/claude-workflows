# API Consistency Review — `feat/crb-direction1-harness` (pass 2, fix adjudication)

**Commit:** ed68ced
**Scope:** `git diff 529ecd2..ed68ced` — 7 files (+445/−60). `529ecd2` and earlier are context
only. This is the **fix pass** for the pass-1 review at `Commit: 529ecd2`.
**Date:** 2026-08-18
**Based on:** pass-1 `docs/reviews/api-consistency-review.md` (F1–F14) and the rubric at
`docs/reviews/code-review-rubric-2026-08-18-feat-crb-direction1-harness.md` (A13, A14, A19, A22–A25).
**Calibration:** research tooling, small expert user base, finite lifetime. Several pass-1
Informational items are re-confirmed as "not closed" without being re-argued — for this audience
they were advisory the first time and remain so.

> ⚠️ **No code fact-check report was produced for `ed68ced`.** The Stage-1 fact-check reports are
> pinned to `529ecd2`. Documentation claims *added by this commit* are unverified except where I
> read the code directly. All claims below rest on read-only inspection plus one read-only `bats`
> run.

**Line-number note:** all citations are against the **committed blob** at `ed68ced`
(`git show ed68ced:<path>`). A concurrent agent has uncommitted edits to
`runs/review-arms/crb-pipeline/run-host.sh` in the working tree; those are out of scope and their
line numbers do not match this report (see Escalate).

The consumer-facing surfaces reviewed: (a) three Python CLIs plus one env-var-driven shell
surface, driven in sequence as one toolchain; (b) the inter-script manifest contract; (c) the
vendored benchmark's `benchmark_data.json` record schema; (d) the rubric-markdown parsing contract;
(e) the judge-directory naming chain; and, new in this commit, (f) the generated `judge.sh`
executable as a second work-dir runbook.

---

## Verdict Table — pass-1 findings

The primary output of this pass.

| Pass-1 finding | Severity (pass 1) | Verdict | One-line reason |
|---|---|---|---|
| F1 — `--tool-name` vs `--tool` | Inconsistent | **Closed on tolerance, not on documentation** | Alias added with the right `dest`; the module `Usage:` block and the setup-doc example still teach `--tool-name` (→ G1) |
| F2 — judge parameterized upstream, hard-coded downstream | Inconsistent | **Closed** | `--out`/`--judge` added to the leaderboard; constructed path verified identical to what the injector writes; `--evaluations` still overrides both |
| F3 — `--judge` bare vs provider-prefixed | Inconsistent | **Not closed; surface widened** | Untouched, and the new leaderboard `--judge` inherits the same ambiguity — though the two now agree by construction, so no new bug (→ G2) |
| F4 — three names for "rehearse, write nothing" | Inconsistent | **Not closed** | `--stats` unchanged at `crb-pipeline-to-benchmark.py:208`; and the new `--verify` is a fourth non-writing mode in a group that means "what to materialize" (→ G3) |
| F5 — three behaviours for an unknown instance | Inconsistent | **Not closed; a second silent-skip trigger added** | Pre-run containment failure `continue`s, so the sweep can now skip every cell for a second reason and still exit 0 (→ G4) |
| F6 — relative `--out` resolves against CWD | Minor | **Not closed; widened to a second script** | The new leaderboard `--out` is also `Path(args.out)`, so two of three scripts now disagree with `canon-to-crb.py` (→ G5) |
| F7 — `created_at` dropped from emitted comments | Minor | **Not closed** | `comments_from_rubric` and the `load_cell` fallback still emit 3 keys |
| F8 — `source_provenance` extends a foreign schema | Informational | **Not closed** | Recommendation was one doc line in `crb-direction1-setup.md` §3; `source_provenance` appears nowhere in that file |
| F9 — `sanitize_model` clones the vendored helper | Minor | **Regressed** | A second in-repo copy added at `crb-subset-leaderboard.py:34`; still unrenamed, still undocstringed (→ G6) |
| F10 — `--per-repo 0` gives the wrong error | Minor | **Not closed** | The truthiness guard is unchanged; only the message text grew a `--verify` item |
| F11 — `--all-prs` vs `--all` denominators | Minor | **Closed** | Usage line now reads "every PR in the evals file"; help text expanded to name the seeding precondition |
| F12 — `--no-seed` is the only negative flag | Informational | **Not closed** | Untouched; recommendation was explicitly optional |
| F13 — `BUDGET` vs `--max-usd`; `MODEL=opus` example | Informational | **Not closed; entrenched** | New `SWEEP_BUDGET` repeats the unit-less money name and is absent from the Usage header; `MODEL=opus` example unchanged (→ G7) |
| F14 — single auth mode vs E7's two | Informational | **Not closed** | Error message at `:100` unchanged |

**New surface reviewed fresh:** `--verify` (G3), `judge.sh` + `CRB_ALLOW_FOREIGN_ENDPOINT` (G8),
`SWEEP_BUDGET` (G7), `--out`/`--judge` on the leaderboard (F2 close, G5), `normalize_section`,
`verify_containment`, `test/crb-injector-sections.bats`.

---

## Baseline Conventions (delta only)

Pass 1's baseline still holds; two additions relevant to this commit:

- **Shell env knobs** across `runs/review-arms/*/*.sh` are exactly eight: `BUDGET`, `CC_VERSION`,
  `CUBIC_BIN`, `DRY_RUN`, `MODEL`, `PAYLOAD_REF`, `REPS`, and now `SWEEP_BUDGET` — all
  `UPPER_SNAKE` with `${VAR:-default}`. Tool-scoped prefixes exist (`CUBIC_BIN`,
  `CUBIC_LOG_LEVEL`), so a `CRB_` prefix has precedent in *shape* if not in name.
- **No `--verify` CLI flag exists anywhere in `scripts/`.** Grepped `scripts/*.py`,
  `scripts/*.sh`, `runs/review-arms/**/*.sh`: the only occurrences of the string are
  `git rev-parse --verify` / `git show-ref --verify` internals in `review-arms.py:173` and
  `self-improvement.sh:69,1674`. `--verify` on a repo-tooling CLI is first of its kind here.

---

## Name-Pattern Audit

Every new public name introduced by `ed68ced`.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--tool` (injector alias) | CLI flag | `--tool` (leaderboard), `--tool` (vendored steps 2/2.5/3) | `scripts/crb-subset-leaderboard.py:51`, `external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:168` | **Consistent** — closes F1's tolerance half |
| `--verify SLUG ...` (materialize) | CLI flag | `--list`, `--dry-run`, `--force` (same file); no `--verify` anywhere in `scripts/` | none — searched `scripts/*.py`, `scripts/*.sh`, `runs/review-arms/**/*.sh` | New category; **placement** in the mutually-exclusive selector group is the issue → G3 |
| `--out` (leaderboard) | CLI flag | `--out` (injector), `--out` (`canon-to-crb.py`) | `scripts/crb-pipeline-to-benchmark.py:187`, `scripts/canon-to-crb.py:178` | Name **consistent**; resolution semantics inherit the injector's CWD-relative form → G5 |
| `--judge` (leaderboard) | CLI flag | `--judge` (injector), `--judge` (`review-arms.py`, `cross-model-review.py`) | `scripts/crb-pipeline-to-benchmark.py:193`, `scripts/review-arms.py:125` | Name **consistent**; value shape inherits F3 → G2 |
| `SWEEP_BUDGET` | env var | `BUDGET`, `REPS`, `CC_VERSION`, `DRY_RUN` | `runs/review-arms/crb-pipeline/run-host.sh:61`, `runs/review-arms/e7-fable-3x/run-host.sh:47` | Shape **consistent** (`UPPER_SNAKE` + `${VAR:-default}`); unit-less money name repeats F13 and is missing from the Usage block → G7 |
| `CRB_ALLOW_FOREIGN_ENDPOINT` | env var | `CUBIC_BIN`, `CUBIC_LOG_LEVEL`, `CLAUDE_CREDENTIALS`, `MARTIAN_*` | `runs/review-arms/crb/run-cubic.sh:37,101`, `runs/review-arms/e7-fable-3x/run-host.sh:63` | Prefix shape has precedent; **first `CRB_`-prefixed knob**, and it exists only inside a generated file → G8 |
| `verify_containment(dst, slug, head)` | function | `materialize`, `slug_for`, `resolve_base`, `dir_mb`, `select` (same module) | `scripts/crb-materialize.py:72-164` | **Consistent** — verb-phrase module-level helper, raises like its neighbours |
| `normalize_section(title)` | function | `md_tables`, `comments_from_rubric`, `parse_location`, `load_cell` | `scripts/crb-pipeline-to-benchmark.py:84-181` | **Consistent** — verb-phrase, docstring states input→output concretely |
| `sanitize_model()` (leaderboard) | function | `sanitize_model` (injector), `sanitize_model_name` (vendored ×3) | `scripts/crb-pipeline-to-benchmark.py:80`, `external/…/step2_extract_comments.py:64` | **Inconsistent (regressed)** — 2nd in-repo copy of a helper pass-1 already flagged as a renamed clone → G6 |
| `DEFAULT_OUT`, `DEFAULT_JUDGE` (leaderboard) | constant | identically-named constants in the injector | `scripts/crb-pipeline-to-benchmark.py:58,60` | Names **consistent**; the duplication is an architecture finding (see `architecture-review.md` A2) |
| `judge.sh` (generated artifact) | artifact | `RUN.md` (same dir), `run-host.sh`, `run-cubic.sh` | `runs/review-arms/crb/run-cubic.sh`, `runs/review-arms/*/run-host.sh` | Name **consistent**; being a *second* runbook for the same steps is the issue → G8 |
| `containment.json`-equivalent | artifact | `preflight.json`, `run-meta.json`, `result.json` | `runs/review-arms/crb-pipeline/run-host.sh` | _(not created — see `architecture-review.md` A1)_ |
| `test/crb-injector-sections.bats`, `probe()` | test | `test/cross-model-review-stage1.bats`, `test/rubric-selection.bats` | `test/*.bats` (`# @category fast` on 20+ suites) | **Consistent** — `# @category fast` on line 2, `$BATS_TEST_TMPDIR` for scratch, no network |

---

## Findings

#### G1 — F1 is closed as tolerance, not as consistency: the documented flow still teaches `--tool-name`

**Severity:** Minor (down from pass-1's Inconsistent)
**Location:** `scripts/crb-pipeline-to-benchmark.py:191`, `:35` (module `Usage:` block);
`docs/working/crb-direction1-setup.md` §3 variant example
**Move:** #2 (naming against the grain) / #3 (consumer contract)
**Confidence:** High
**Legibility-target:** the operator running the four stages back-to-back from the setup doc.

Precedent: `--tool` used in `scripts/crb-subset-leaderboard.py:51` and
`external/code-review-benchmark/offline/code_review_benchmark/step{2_extract_comments.py:168,2_5_dedup_candidates.py:224,3_judge_comments.py:388}`

**Evidence** — the alias is correctly wired:

```python
    # --tool is the spelling used by crb-subset-leaderboard.py AND by all three
    # vendored benchmark steps; --tool-name is kept as the original spelling so
    # existing invocations keep working.
    ap.add_argument("--tool-name", "--tool", dest="tool_name", default="mfc-pipeline-e8",
                    help="tool name in benchmark_data.json (default mfc-pipeline-e8)")
```

The `dest="tool_name"` is right (without it argparse would derive `tool_name` from the first
option string anyway, but stating it makes the binding explicit and survives a future reorder),
and `--help` will render `--tool-name TOOL_NAME, --tool TOOL_NAME`, so both spellings are
discoverable from the help output even though the `help=` string names neither.

What did not change is which spelling the *documentation* teaches. The module's own `Usage:`
block still reads `scripts/crb-pipeline-to-benchmark.py --tool-name mfc-pipeline-main --runs
<dir>`, and the setup doc's red+amber variant example still passes `--tool-name
mfc-pipeline-e8-redamber`. So a user reading either artifact still learns the outlier spelling and
still meets the near-miss when they reach the three vendored steps — the alias saves them only if
they guess `--tool` first. That is tolerance, not consistency, and it is the difference this
finding was about: `--tool` is the cost-confinement lever (rubric A11: ~2233 paid calls if
omitted at step 2.5), so the goal was one spelling in the operator's muscle memory, not two.

**Recommendation:** Swap the option order to `ap.add_argument("--tool", "--tool-name",
dest="tool_name", …)` so `--tool` becomes the primary in `--help`, and update the module `Usage:`
block and the setup doc's variant example to `--tool`. Three lines; `--tool-name` keeps working.

---

#### G2 — F3 is untouched and the new leaderboard `--judge` inherits the same value ambiguity

**Severity:** Minor (down from Inconsistent — the two scripts now agree by construction, so the
remaining cost is learnability only)
**Location:** `scripts/crb-subset-leaderboard.py:31`, `:49`, `:58-59` vs
`scripts/crb-pipeline-to-benchmark.py:60`, `:193`
**Move:** #2 (naming — value convention) / #7 (asymmetry)
**Confidence:** High
**Legibility-target:** a user scoring a second judge for a judge-variance check.

Precedent: provider-prefixed judge ids (`anthropic/claude-sonnet-4.5`) in `scripts/review-arms.py:125`
and `scripts/cross-model-review.py:372`; `openai/gpt-4o-mini` as `MARTIAN_MODEL` default in
`external/…/code_review_benchmark/step{2,2_5,3}*.py`

**Evidence:**

```python
DEFAULT_JUDGE = "claude-opus-4-5-20251101"
```

```python
    path = (Path(args.evaluations) if args.evaluations
            else Path(args.out) / "results" / sanitize_model(args.judge) / "evaluations.json")
```

The bare-vs-prefixed question pass-1 raised is unchanged, and there is now a second flag carrying
it. Checked for a new bug and found none: the injector names its destination
`out / "results" / sanitize_model(args.judge)` and the leaderboard computes the identical
expression from identical `sanitize_model` bodies, so whichever shape the user supplies, both
scripts land on the same directory. The injector's `anthropic/`-prefixed fallback applies only to
locating the *seed source* in the vendored tree, which is correct and unaffected.

So the exposure is exactly what it was: a user who copies the shape their neighbours teach
(`--judge anthropic/claude-opus-4-5-20251101`) gets a work dir named
`anthropic_claude-opus-4-5-20251101`, which then has to match whatever they export as
`MARTIAN_MODEL` — and `judge.sh` now defaults `MARTIAN_MODEL` to `{args.judge}` verbatim, which
actually *helps*, because the generated script propagates whichever shape was used. Worth noting
as a partial mitigation the commit did not claim.

**Recommendation:** Unchanged from pass 1, now applied to both flags: strip a leading
`<provider>/` on entry in one place, and say in both `--judge` help strings that the value is the
bare `MARTIAN_MODEL` id.

---

#### G3 — `--verify` is a fourth non-writing mode with a fourth name, placed in a mutually-exclusive group whose other members all mean "what to materialize"

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:259-270`
**Move:** #2 (naming against the grain) / #3 (consumer contract)
**Confidence:** High
**Legibility-target:** a reader of `--help` deciding which flag rehearses and which acts.

Precedent: the group's existing members `--all` / `--per-repo N` / `--slug ...` / `--list` all
answer "which PRs", in `scripts/crb-materialize.py:260-264`; the repo's rehearsal flag is
`--dry-run` in `scripts/crb-materialize.py:270`, `scripts/review-arms.py:131`,
`scripts/cross-model-review.py:388`

**Evidence:**

```python
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--all", action="store_true", help="materialize all 50 PRs")
    g.add_argument("--per-repo", type=int, metavar="N",
                   help="N PRs per source repo, most-goldens-first (N=1 -> 5-PR pilot)")
    g.add_argument("--slug", nargs="+", help="explicit slugs (see --list)")
    g.add_argument("--list", action="store_true", help="list available PRs and exit")
    g.add_argument("--verify", nargs="+", metavar="SLUG",
                   help="re-assert answer-key containment on existing clone(s) and exit "
                        "(used by run-host.sh before and after each review cell)")
    ap.add_argument("--depth", type=int, default=50, help="shallow clone depth (default 50)")
    ap.add_argument("--force", action="store_true", help="rebuild existing clones")
    ap.add_argument("--dry-run", action="store_true", help="print the selection, clone nothing")
```

Two contract problems, both small:

1. **Group semantics.** `--list` was already a mild stretch (it selects nothing, it prints), but
   it at least operates on the same *dataset* the other three select from. `--verify` operates on
   the **clone tree** (`DST_ROOT / slug`), never calls `load_prs()`, and returns before any
   selection happens. A user reading `--help` sees five mutually-exclusive options and reasonably
   infers all five are ways of naming PRs; only three are. `--verify` and `--list` are modes, not
   selectors, and the group is doing double duty.
2. **Silently ignored siblings.** `--depth`, `--force` and `--dry-run` are all accepted alongside
   `--verify` and all silently do nothing, because the verify branch returns at `:295`. The
   `--dry-run` case is the one that matters for consistency: `--dry-run` promises "clone nothing"
   and `--verify --dry-run` does in fact write nothing, but for the unrelated reason that verify
   never writes — so the flag's contract is satisfied by accident rather than honoured. Worse in
   principle is `--force --verify`, where a user has asked for the destructive mode and is given
   the read-only one with no warning.

The underlying F4 problem is untouched: `--dry-run` (materialize), `DRY_RUN=1` (runner), `--stats`
(injector, still at `:208`), and now `--verify` are four names in one chain for operations that
write nothing. `--verify` is *not* the same concept as the other three — it asserts rather than
rehearses, so a distinct name is right — but its arrival is a good moment to collapse `--stats`
into `--dry-run`, which is a two-line change with an alias.

**Recommendation:** Split the group: keep `--all`/`--per-repo`/`--slug` mutually exclusive as the
selector, and make `--list`/`--verify` a second mutually-exclusive "mode" group. Reject
`--force`/`--depth` alongside `--verify` with `ap.error("--verify is read-only; --force/--depth do
not apply")`. Separately, rename `--stats` to `--dry-run` with `--stats` as an alias, closing F4.

---

#### G4 — F5 is unclosed and the pre-run containment check adds a second way for a sweep to skip every cell and exit 0

**Severity:** Inconsistent
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:145`, `:177-178`, `:236-237`
**Move:** #4 (error consistency) / #9 (safety semantics)
**Confidence:** High
**Legibility-target:** an operator wrapping the sweep in a shell `&&` chain, or reading only the
exit status of an unattended run.

**Evidence** — three `continue`-shaped outcomes now share one exit status:

```bash
  [ -d "$clone/.git" ] || { echo "$id: clone missing — run scripts/crb-materialize.py --slug $id" >&2; continue; }
```

```bash
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2; continue; }
```

```bash
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" \
    || echo "$id: POST-RUN containment check FAILED — treat this cell's result as void" >&2
```

against the sibling runner `runs/review-arms/e7-fable-3x/run-host.sh:115`, which hard-exits on the
first of these conditions.

**Is the pre-run `continue` a fourth behaviour for "this instance is not usable"?** Not a fourth
*kind* — it is the same warn-and-continue shape as the existing clone-missing path in the same
file, so internally `run-host.sh` is consistent with itself. But it is a second *trigger* for that
shape, and it is a trigger that can fire for **every** instance at once: a containment break that
persists (a remote re-added and left in place, which is precisely the failure guard (b) exists to
catch) makes cell 1's post-run check fail, then cells 2..50's pre-run checks fail, and the sweep
exits **0** having reviewed nothing and produced no `run-meta.json` totals worth reading. Pass-1's
F5 said "a wrapper cannot distinguish 'reviewed 5 PRs' from 'reviewed 0 PRs because you typo'd the
slugs'"; the fix commit added a second, more likely way to reach the same undistinguishable state.

The post-run arm is separately inconsistent with itself: it names a consequence ("treat this
cell's result as void") that the script does not implement — the cell's `result.json` remains and
the resume predicate at `:150-159` will bank it as complete next sweep. That is the contract
half of `architecture-review.md` A1; I do not duplicate the structural argument here.

Worth crediting: the new `SWEEP_BUDGET` gate does introduce a distinct exit code (`exit 2`), which
is exactly the right instinct — the runner now has a three-value exit vocabulary (0 = ran, 1 =
preflight/manifest refusal, 2 = budget stop). It is undocumented in the header `Usage:` block.

**Recommendation:** Track `skipped` and `ran` counters in the loop; `exit 3` (documented) if
`ran == 0`, and `exit 4` if any post-run containment check failed. Add the exit-code table to the
header comment alongside the `Usage:` lines. If a hard error on an unknown slug is still wanted
(pass-1's recommendation, matching E7), do it in the `INSTANCES` resolution before the loop rather
than per-cell.

---

#### G5 — F6 is unclosed and now has two offenders: the new leaderboard `--out` is also CWD-relative

**Severity:** Minor
**Location:** `scripts/crb-subset-leaderboard.py:47`, `:58-59`; `scripts/crb-pipeline-to-benchmark.py:187`, `:215`
**Move:** #3 (consumer contract) / #7 (asymmetry)
**Confidence:** High
**Legibility-target:** a user who copies the `--out` example from `canon-to-crb.py` or from
`docs/working/crb-direction1-setup.md`.

**Evidence** — the new flag repeats the pattern pass 1 flagged rather than the one it recommended:

```python
    ap.add_argument("--out", default=str(DEFAULT_OUT),
                    help=f"benchmark work dir written by the injector (default {DEFAULT_OUT})")
```

```python
    path = (Path(args.evaluations) if args.evaluations
            else Path(args.out) / "results" / sanitize_model(args.judge) / "evaluations.json")
```

against `scripts/canon-to-crb.py:178-181`, this repo's other work-dir writer:

```python
    ap.add_argument("--out", default="runs/review-arms/crb/offline-work")
    args = ap.parse_args()

    out = WORKSPACE / args.out
```

Three scripts now write or read a work dir under `runs/review-arms/crb/` behind a flag named
`--out`; two resolve it against the CWD and one against `WORKSPACE`. The setup doc's own variant
example (`--out runs/review-arms/crb/offline-work-50-ra`) is a workspace-relative path, so the
documented off-default flow is wrong from any CWD but `/workspace` — and it is now wrong twice,
once when injecting and once when ranking, with the second failure surfacing as
`no evaluations at … — run step 3 first`, the exact misdiagnosis F2's fix was written to
eliminate.

The fix is the same one-line change pass 1 named, now needed in two places. `Path.__truediv__`
leaves absolute values untouched, so the absolute defaults keep working.

**Recommendation:** `out = WORKSPACE / args.out` in both scripts (and apply it to `--runs` and
`--evaluations` for symmetry), matching `canon-to-crb.py:181`.

---

#### G6 — F9 regressed: `sanitize_model` now has a second in-repo copy, still renamed from the vendored original and still without the docstring that explains why it must match

**Severity:** Minor
**Location:** `scripts/crb-subset-leaderboard.py:34-35`
**Move:** #2 (naming against the grain)
**Confidence:** High
**Legibility-target:** a reader checking that our judge-directory naming really matches what the
benchmark will compute.

Precedent: `sanitize_model_name` used in
`external/code-review-benchmark/offline/code_review_benchmark/step2_extract_comments.py:64`,
`step2_5_dedup_candidates.py:82`, `step3_judge_comments.py:88`; the repo's own first copy at
`scripts/crb-pipeline-to-benchmark.py:80`

**Evidence:**

```python
def sanitize_model(model: str) -> str:
    return model.strip().replace("/", "_")
```

character-identical to `scripts/crb-pipeline-to-benchmark.py:80-81`, which is in turn
character-identical to the vendored:

```python
def sanitize_model_name(model: str) -> str:
    """Sanitize model name for use as directory name."""
    return model.strip().replace("/", "_")
```

Pass 1 rated one clone Minor and defensible ("importing from the vendored package would add a
dependency the script otherwise avoids") with the ask being a rename and a one-line docstring.
Neither happened, and a fifth copy of the body now exists — the second inside `scripts/`. The
correctness argument for the whole judge-dir chain is "these functions all produce the same
string"; there are now five of them, none of which says so, and two of which the repo owns and
could keep honest with one assertion.

This is a small finding held at Minor deliberately — nothing breaks today and every copy is four
tokens. It is listed because the commit's own claim ledger cites tech-debt's lifetime evidence to
defer the shared module, and this is the one place that reasoning produced *new* duplication
rather than merely carrying old duplication. The structural framing is in
`architecture-review.md` A2.

**Recommendation:** Rename both in-repo copies to `sanitize_model_name` with a one-line docstring
naming the vendored function they mirror, and add an assertion to
`test/crb-injector-sections.bats` (which already loads these modules via `importlib`) that the two
in-repo copies agree on `"anthropic/x"`.

---

#### G7 — `SWEEP_BUDGET` matches the env-var shape but repeats `BUDGET`'s unit-less money name and is absent from the Usage block that documents its four siblings

**Severity:** Minor
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:62-65`, `:44-48`
**Move:** #2 (naming against the grain) / #1 (baseline)
**Confidence:** High
**Legibility-target:** an operator setting a ceiling before an unattended `--all` sweep.

Precedent: spend cap named `--max-usd` in `scripts/review-arms.py:128` and
`scripts/cross-model-review.py:374`; env-knob shape `UPPER_SNAKE` + `${VAR:-default}` in
`runs/review-arms/e7-fable-3x/run-host.sh:47` (`REPS`), `runs/review-arms/crb/run-cubic.sh:37`
(`CUBIC_BIN`)

**Evidence:**

```bash
# Sweep-level ceiling. BUDGET caps ONE instance; without an aggregate the loop
# will happily spend BUDGET x 50 unattended before run-meta.json first reports a
# total. Checked after every cell, so the worst overshoot is one instance.
SWEEP_BUDGET="${SWEEP_BUDGET:-75.00}"
```

against the Usage block four lines above it, which documents every *other* tunable:

```bash
#   ANTHROPIC_API_KEY=sk-ant-... bash runs/review-arms/crb-pipeline/run-host.sh
#   ... run-host.sh discourse-graphite-PR4 grafana-PR79265     # subset
#   MODEL=opus BUDGET=10 ... run-host.sh                       # cheaper sweep
#   DRY_RUN=1 ... run-host.sh                                  # plan only, $0
```

Three small things. (a) The `UPPER_SNAKE`/`${VAR:-default}` shape and the "why" comment are
exactly right and match every sibling arm — no complaint there. (b) The name repeats F13's issue:
`SWEEP_BUDGET=250` is ambiguous between dollars and a token or turn count, where the repo's Python
arms carry the unit (`--max-usd`). Adding a second unit-less money knob entrenches the deviation
rather than leaving it a single legacy name. (c) It is the one env knob not advertised in the
Usage block, and it is the one an operator most needs to know exists before an unattended `--all`
run — the default of `$75` against a `BUDGET` of `$25` means a 50-instance sweep **stops after
roughly three cells**, which will read as a bug rather than as a ceiling to anyone who has not
read line 65.

`MODEL=opus` in the same Usage block is unchanged; F13's second half is not closed either.

**Recommendation:** Rename to `SWEEP_BUDGET_USD` with a fallback
(`SWEEP_BUDGET_USD="${SWEEP_BUDGET_USD:-${SWEEP_BUDGET:-75.00}}"`), add a Usage line
(`SWEEP_BUDGET_USD=400 ... run-host.sh   # full 50-PR sweep ceiling`), and change the `MODEL=opus`
example to an exact pinned id.

---

#### G8 — `judge.sh` is a second runbook for the same four steps, and it disagrees with `RUN.md`; its `CRB_ALLOW_FOREIGN_ENDPOINT` escape hatch is undocumented and prints a refusal it does not perform

**Severity:** Inconsistent
**Location:** `scripts/crb-pipeline-to-benchmark.py:305-330` (`RUN.md`) vs `:332-371` (`judge.sh`)
**Move:** #7 (asymmetry) / #3 (consumer contract) / #4 (error consistency)
**Confidence:** High
**Legibility-target:** an operator opening the work dir and choosing which artifact to follow.

**Evidence** — the two artifacts, generated four lines apart, differ on three contract points:

```python
export PYTHONPATH=/workspace/external/code-review-benchmark/offline   # or: uv sync in offline/
export MARTIAN_API_KEY="$ANTHROPIC_API_KEY"
export MARTIAN_BASE_URL=https://api.anthropic.com/v1/
```

versus

```python
: "${{MARTIAN_BASE_URL:=https://api.anthropic.com/v1/}}"
```
```python
export PYTHONPATH="${{PYTHONPATH:-{BENCH}}}"
```
```python
case "$MARTIAN_BASE_URL" in
  *api.anthropic.com*) ;;
  *) echo "MARTIAN_BASE_URL is '$MARTIAN_BASE_URL', not an api.anthropic.com endpoint." >&2
     echo "Refusing to send MARTIAN_API_KEY there. Set CRB_ALLOW_FOREIGN_ENDPOINT=1 to override." >&2
     [ "${{CRB_ALLOW_FOREIGN_ENDPOINT:-}}" = "1" ] || exit 1 ;;
esac
```

Three contract issues:

1. **Divergence risk, answered: yes.** `RUN.md` hardcodes `/workspace` (twice — also in the
   leaderboard invocation) while `judge.sh` interpolates the computed `BENCH`/`WORKSPACE`;
   `judge.sh` fails closed on a non-Anthropic endpoint while `RUN.md` can only assert the export;
   `judge.sh` defaults `MARTIAN_MODEL` from `{args.judge}` while `RUN.md` writes it literally. The
   setup doc handles this honestly — `judge.sh` is "Preferred", the manual block is "Equivalent by
   hand (both footguns are on you)" — but they are *not* equivalent, and the file a reader opens
   first is the `.md`. Two runbooks that drift is exactly the failure this arm's own rubric-parsing
   finding (A15) was about, reproduced in the work-dir contract.
2. **New env knob, documented only inside a generated file.**
   `CRB_ALLOW_FOREIGN_ENDPOINT` appears nowhere in `docs/working/crb-direction1-setup.md` or in
   any tracked script — only in the f-string that generates `judge.sh`. It is the first
   `CRB_`-prefixed variable in the repo. The shape has precedent (`CUBIC_BIN`,
   `CUBIC_LOG_LEVEL`), so the name is fine; its discoverability is not.
3. **The refusal message fires even when the override is honoured.** With
   `CRB_ALLOW_FOREIGN_ENDPOINT=1` set, the two `echo … >&2` lines still run — including
   "Refusing to send MARTIAN_API_KEY there." — and then the script proceeds to do exactly that.
   An error message that states the opposite of what happens is worse than none, and this one sits
   on a credential-egress decision.

**Recommendation:** (a) Reduce `RUN.md` to a pointer at `judge.sh` plus a reference listing
generated from the same interpolated variables, so `/workspace` cannot survive in one and not the
other. (b) Move the override check above the messages: `if [ "${CRB_ALLOW_FOREIGN_ENDPOINT:-}" =
"1" ]; then echo "… allowing non-Anthropic endpoint by CRB_ALLOW_FOREIGN_ENDPOINT=1" >&2; else
<refuse>; fi`. (c) Add one line to the setup doc §4 naming the variable and what it disables.

---

#### G9 — F7 and F8 unchanged: emitted `review_comments` still drop `created_at`, and `source_provenance` is still undocumented

**Severity:** Minor (F7) / Informational (F8)
**Location:** `scripts/crb-pipeline-to-benchmark.py:123-128`, `:160`, `:227-233`;
`docs/working/crb-direction1-setup.md` §3
**Move:** #7 (asymmetry) / #6 (versioning impact)
**Confidence:** High
**Legibility-target:** anyone diffing our injected rows against the benchmark's own rows.

Precedent: `path`/`line`/`body`/`created_at` written together in
`external/code-review-benchmark/offline/code_review_benchmark/step1_download_prs.py:135-140` and
`scripts/canon-to-crb.py:127-132`

**Evidence:** neither hunk appears in `git diff 529ecd2..ed68ced -- scripts/crb-pipeline-to-benchmark.py`;
`rg -n "source_provenance" docs/working/crb-direction1-setup.md` returns no matches.

Both were correctly rated low in pass 1 and neither is claimed by the fix commit, so this is a
status row rather than a new argument. F7's one-line fix (`"created_at": None` in both
`comments_from_rubric` and the `load_cell` fallback) is worth taking whenever that function is next
open, because it is the only thing making our rows structurally distinguishable from every other
tool's in a file this arm intends to publish a number from. F8's fix is one sentence of prose.

The commit *did* substantially expand the setup doc's caveats section (§ caveats 2, 2b) with the
golden-denominator correction and the dedup asymmetry — good work — which makes the omission of
the one-line schema-extension note more conspicuous than it was, since the surrounding paragraph
now reads as a complete "known deltas" list and is not one.

**Recommendation:** Emit `"created_at": None` in both writers; add the `source_provenance`
sentence to the caveats list next to caveats 2/2b rather than to §3, since that is where the
"known deltas from the published rows" content now lives.

---

#### G10 — F10, F12, F14 remain open as advisories

**Severity:** Informational
**Location:** `scripts/crb-materialize.py:306`; `scripts/crb-pipeline-to-benchmark.py:205-207`;
`runs/review-arms/crb-pipeline/run-host.sh:100`
**Move:** #4 (error consistency) / #2 (naming)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Precedent (F12, the only naming item here): affirmative `store_true` flags throughout —
`--force` (`scripts/crb-materialize.py:269`, `scripts/prep-cc-review-clones.sh:30`),
`--all-files`/`--include-plugins`/`--summary` (`scripts/claude_config_audit.py:197-199`)

**Evidence** — F10's guard is unchanged apart from its message:

```python
    if not (args.all or args.per_repo or args.slug):
        ap.error("pick one of --list / --per-repo N / --slug ... / --all / --verify SLUG ...")
```

`--per-repo 0` still tests as falsy and is still told to pick a selector it just picked. Note the
message now advertises `--verify` while `args.verify` is deliberately absent from the truthiness
test — correct, because the verify branch returns at `:295` before this line, but it does mean the
error text lists an option that can never reach it.

F12 (`--no-seed` as the only negative flag) and F14 (`ANTHROPIC_API_KEY`-only auth with a bare
error message) are untouched. Both were rated Informational with explicitly optional
recommendations in pass 1 and neither is claimed; for a harness with this lifetime and audience I
would not spend the edit on either now.

**Recommendation:** F10 only, when the file is next open: test `args.per_repo is not None` and
reject `< 1` with `--per-repo must be >= 1`. F12 and F14: no action.

---

## What Looks Good

- **F2 is closed properly, not cosmetically.** The leaderboard did not just gain flags — it gained
  the *same* two flags as the injector, with the same names, the same defaults, and a derived path
  that I verified is character-identical to the injector's `jdir`. `--evaluations` was correctly
  kept as an explicit-path escape hatch with `default=None` so it only wins when supplied, and the
  failure message now names all three ways to fix it (`--out/--judge/--evaluations`) instead of
  misdiagnosing as "run step 3 first". That is the shape a two-stage flag contract should have.
- **The `--tool` alias uses `dest=` explicitly.** Not required by argparse, but it pins the
  attribute name against a future reorder of the option strings — the kind of small defensive
  choice that keeps an alias from becoming a rename by accident.
- **`judge.sh` converts two documentation-only contracts into enforced ones.** `--tool` on all
  three steps and the `MARTIAN_BASE_URL` guard were previously operator memory under a ~2233-call
  and a credential-egress exposure. Making them mechanical, with a named override rather than no
  escape hatch, is the right trade even with G8's three defects.
- **The `--all-prs` help text now carries its own precondition** ("that is all 50 only when the
  file was seeded from the benchmark's checked-in results") rather than deferring to a usage
  comment that contradicted it. F11 closed exactly as recommended, including the usage line.
- **The `GOLDEN-DENOMINATOR SKEW` warning goes to stderr, not stdout.** It is emitted before the
  `--markdown` branch, so a piped `> table.md` gets a clean table and the operator still sees the
  caveat. Small thing, correct thing — and it puts a measurement caveat in the output path rather
  than in a runbook nobody re-reads at write-up time.
- **Judge seeding's error messages name the consequence and the deliberate escape.** "refusing to
  continue: the judge run would score every tool (~50x cost). Pass `--no-seed` to do that
  deliberately" tells the user what will happen, what it costs, and how to ask for it on purpose.
  That is the house style (`sys.exit("message")` for hard user error) applied well.
- **`normalize_section` is applied symmetrically.** Both the wanted set and the observed headings
  go through the same function, so the contract cannot drift between the two sides of the
  comparison — the mistake the substring version made.
- **The new test suite follows the repo's contract-testing conventions.** `# @category fast` on
  line 2 matching 20+ siblings, reuse of the drift-guarded golden at
  `test/skills/code-review/rubric-current-format.md` rather than a new fixture, hermetic
  (`$BATS_TEST_TMPDIR`, no network, no repo mutation), and no pytest introduced — which rubric
  item C4 explicitly warned against. I ran it read-only: 8/8 pass, and I confirmed the
  column-rename test is non-vacuous (the fixture really does contain `| Prior finding |` with a
  data row under it).

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| G4 | F5 unclosed; pre-run containment `continue` gives the sweep a second way to skip everything and exit 0; post-run message names a consequence the script does not implement | Inconsistent | `run-host.sh:145,177-178,236-237` | High |
| G8 | `judge.sh` and `RUN.md` disagree; `CRB_ALLOW_FOREIGN_ENDPOINT` undocumented and its refusal message prints when the override is honoured | Inconsistent | `crb-pipeline-to-benchmark.py:305-371` | High |
| G1 | F1 closed as tolerance only — `Usage:` block and setup doc still teach `--tool-name` | Minor | `crb-pipeline-to-benchmark.py:191,35` | High |
| G2 | F3 untouched; new leaderboard `--judge` inherits the bare-vs-prefixed ambiguity (no new bug — the two agree by construction) | Minor | `crb-subset-leaderboard.py:31,49,58-59` | High |
| G3 | `--verify` sits in the "what to materialize" mutually-exclusive group and silently ignores `--depth`/`--force`/`--dry-run`; F4's four-name problem unclosed | Minor | `crb-materialize.py:259-270` | High |
| G5 | F6 widened — the new leaderboard `--out` is CWD-relative like the injector's, against `canon-to-crb.py`'s workspace-relative | Minor | `crb-subset-leaderboard.py:47,58-59` | High |
| G6 | F9 regressed — second in-repo copy of `sanitize_model`, still renamed and undocstringed | Minor | `crb-subset-leaderboard.py:34-35` | High |
| G7 | `SWEEP_BUDGET` repeats the unit-less money name and is the only env knob missing from the Usage block; its `$75` default stops a 50-PR sweep after ~3 cells | Minor | `run-host.sh:62-65,44-48` | High |
| G9 | F7 (`created_at`) and F8 (`source_provenance` doc line) unchanged | Minor / Informational | `crb-pipeline-to-benchmark.py:123-128,227-233` | High |
| G10 | F10, F12, F14 remain open as advisories | Informational | `crb-materialize.py:306`; `crb-pipeline-to-benchmark.py:205-207`; `run-host.sh:100` | High |

---

## Overall Assessment

The fix pass closed the two contract findings that mattered most and left the rest of the list
approximately where it was. F2 — the only pass-1 finding with a money consequence on a plausible
path — is closed cleanly and symmetrically, with the derived path verified identical to what the
injector writes and the escape hatch preserved. F11 is closed as recommended. F1 is half closed:
the tool now *accepts* `--tool`, but the module's `Usage:` block and the setup doc still teach
`--tool-name`, so the operator's muscle memory still learns the outlier for the flag that gates
~2233 paid calls. That is a three-line finish, not a redesign.

Nine of fourteen pass-1 findings are unchanged, which for this audience is largely fine — F12, F14
and F8 were advisory the first time and should stay unspent. Three, though, moved the wrong way,
and they share a cause: the new surface was written against the *new* code's local conventions
rather than against the conventions the pass-1 review had just named. The leaderboard's `--out`
copied the injector's CWD-relative resolution instead of `canon-to-crb.py`'s workspace-relative
one (G5); its `sanitize_model` copied the injector's renamed clone instead of the vendored
original (G6); `SWEEP_BUDGET` copied `BUDGET`'s unit-less name instead of `--max-usd`'s (G7). Each
is one line. Together they are the same lesson pass 1's Overall Assessment drew — the surfaces are
locally coherent and never read side by side as one user session — repeated inside the fix for
that exact observation.

The genuinely new contract concerns are G4 and G8, and both sit on the same theme: a control that
*says* more than it *does*. The post-run containment check tells the operator to treat a cell as
void and then leaves the cell where the resume predicate will bank it; `judge.sh` prints "Refusing
to send MARTIAN_API_KEY there" and then sends it. Neither is a bug on the happy path, and both are
in code that is otherwise a clear net improvement in fail-closed discipline — but a message that
misstates the behaviour is worse than silence on a credential and worse than silence on a
measurement invariant, and both are a few lines to align.

Consumer impact before the first paid sweep: G4's mass-skip-exit-0 is the one an unattended run
can actually meet, and G7's `$75` default is the one an operator will meet within the first hour
and misread as a crash. Everything else is off-default exposure or advisory.

---

## Goal-Alignment Note
- Answered: yes — closure verdicts for all fourteen pass-1 contract findings plus ten findings covering the new CLI, env-var, and generated-artifact surface
- Out of scope: structural/dependency-direction critique of `verify_containment`, the `--verify` seam, the duplicated constants, and the `judge.sh`/`RUN.md` split — those are in `docs/reviews/architecture-review.md` at the same commit (A1–A9), and I have cross-referenced rather than duplicated the argument; correctness, security and performance of the new docker/git/`judge.sh` invocations (other critics); re-verification of Stage-1's `529ecd2` findings. No git-mutating verification was attempted per the safety constraint; the only execution was a read-only `bats test/crb-injector-sections.bats`.
- Escalate: (1) **A concurrent agent has uncommitted edits to `runs/review-arms/crb-pipeline/run-host.sh`** (and to `docs/reviews/{performance,security}-review.md`) in the working tree — `SWEEP_BUDGET` reads `250.00` on disk versus `75.00` at `ed68ced`, and line numbers have shifted by ~60. This report is pinned to the committed blob. The orchestrator should decide whether pass-2 critics are permitted to modify production code mid-review, and re-check any finding whose line numbers matter. (2) **G4 is the one to action before an unattended sweep** — a persistent containment break makes all 50 cells skip and the script exit 0; pair it with `architecture-review.md` A1, which owns the other half. (3) G1, G5, G6, G7 are four one-line edits that should land in a single pass; they are the residue of pass 1's central observation and will otherwise be re-found by pass 3.
