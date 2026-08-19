# API Consistency Review — feat/crb-direction1-harness, commit 197eec6

**Scope:** `git show 197eec6` — egress allowlist + disposable clones (decision 034)
**Date:** 2026-08-19
**Based on:** the merged k=3 code fact-check at `docs/reviews/code-fact-check-report.md`. Its
verdicts on `crb-materialize.py`'s docstring, the audit script's header, `scrub_object_store`'s
"pristine clone" claim and `run-host.sh:425` are taken as given and not re-verified here; where a
Stale/Mostly-Accurate verdict is a *contract* problem it is expanded into a Finding below.
**Partial scope:** everything else on the branch is already committed and is context only. Every
"missing"/"nobody reads this" claim below was checked against `git log main..HEAD` and a repo-wide
grep before being written.
**Churn note:** `scripts/crb-materialize.py` (481/619) and `run-host.sh` (251/582) exceed 40%
churn; both are evaluated on the resulting code, not on the diff hunks.

Surfaces under review: the `crb-materialize.py` CLI (`--restore`, `--snapshot`, changed `--verify`,
overloaded `--force`, four new manifest fields), the new `crb-audit-clone.sh` argv/exit contract,
the new `crb-harvest-artifacts.py` argv/exit contract, `run-host.sh`'s env knobs and exit codes,
and the inter-module file contracts under `external/crb-eval/.baselines/`.

---

## Baseline Conventions

Surveyed: `scripts/crb-cell-status.py`, `scripts/crb_common.py`, `scripts/crb-subset-leaderboard.py`,
`scripts/crb-pipeline-to-benchmark.py`, `scripts/crb-materialize.py` (pre-image), and the sibling
runners `runs/review-arms/e7-fable-3x/run-host.sh` and `runs/review-arms/e5-cc-builtin/run-host.sh`.

1. **Helper-script exit codes are a three-valued contract: `0` = verdict A, `1` = verdict B,
   `2` = usage/invocation error, never a verdict.** Established by amber A2 of the prior review and
   written down in `crb-cell-status.py:88-92` ("Exit codes are a consumed contract … Usage errors
   therefore exit 2"). The convention exists because conflating "you invoked me wrong" with a
   verdict silently re-pays or silently banks a $10-40 cell.
2. **The runner honours that contract by branching on the code, and *stops* on `2`.**
   `run-host.sh:380-388` maps cell-status `0 → skip`, `1 → retry`, `* → exit 4`.
3. **Flags are single-meaning, and `--help` states the meaning.** Every flag in
   `crb-materialize.py`, `crb-subset-leaderboard.py` and `crb-pipeline-to-benchmark.py` has one
   help string covering its whole behaviour.
4. **Manifest records are provenance: mostly write-only fields are normal.** `clone_mb`, `depth`,
   `insertions`, `pr_title` are recorded and read by nobody. Names are `snake_case`, with
   `<subject>_<unit>` (`clone_mb`, `n_goldens`) and `<noun>_<participle>` (`files_changed`).
5. **One definition, imported by both, when two Python modules share an identity value.**
   `crb_common.py`'s docstring draws that boundary explicitly: shared *identity* is imported;
   shared *logic* is not extracted. Its stated trigger is "a review-fix pass hand-copied them into
   a second file, where they are held in agreement by a comment."
6. **Runner env knobs are `${NAME:-default}` and self-contained** — the value takes effect wherever
   it is read, with no second copy elsewhere (`CC_VERSION`, `PAYLOAD_REF`, `MODEL`, `BUDGET`,
   `SWEEP_BUDGET`, `MAX_ATTEMPTS`, `REPS` in e7).
7. **Failure/diagnostic lines are prefixed `!!` and go to stderr** (`crb-materialize.py:124`,
   `crb-harvest-artifacts.py:112`, `crb-subset-leaderboard.py:52`).

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--restore SLUG ...` | CLI flag | `--verify`, `--reset` (removed), `--list` | `scripts/crb-materialize.py:452-471` | Consistent — verb, `nargs="+" metavar=SLUG`, matches `--verify`'s shape |
| `--snapshot SLUG ...` | CLI flag | `--verify`, `--restore` | `scripts/crb-materialize.py:457-468` | Consistent in shape; but it is the only *writing* member of a group whose other members are read-only/destructive-to-a-derivative — see F4 |
| `--verify` (changed target) | CLI flag | its own prior meaning; `--restore` | `scripts/crb-materialize.py:457-460` | Silent semantic change — now verifies the baseline, not the work clone. Deliberate and documented; noted under Versioning |
| `--force` (2nd meaning) | CLI flag | `--force` (1st meaning), `--dry-run` | `scripts/crb-materialize.py:470` | Inconsistent — one flag, two behaviours, one help string — F4 |
| `crb-audit-clone.sh` | script | `crb-cell-status.py`, `crb-materialize.py`, `crb-harvest-artifacts.py` | `scripts/crb-*` | Consistent — `crb-<verb>-<noun>`, matches `crb-materialize`; `.sh` justified (runs inside `node:22`, no python3) |
| `crb-harvest-artifacts.py` | script | `crb-cell-status.py`, `crb-subset-leaderboard.py` | `scripts/crb-*` | Consistent |
| `baseline_tar` / `baseline_sha256` / `baseline_mb` / `baseline_files_indexed` | manifest field | `clone_mb`, `depth`, `files_changed`, `n_goldens` | `scripts/crb-materialize.py:432-446` | Consistent — `<subject>_<unit>` and `<noun>_<participle>` both match the existing family |
| `EGRESS_SUBNET` | env var | `SWEEP_BUDGET`, `MAX_ATTEMPTS`, `CC_VERSION`, `REPS` | `run-host.sh:76-96`, `runs/review-arms/e7-fable-3x/run-host.sh:47` | Name consistent; the *knob* is not self-contained — F6 |
| `EGRESS_NET`, `PROXY_NAME`, `PROXY_URL`, `PROXY_IMAGE`, `REVIEW_IMAGE`, `DOCKER_DIR` | shell constant | `CLONES`, `OUT`, `ROOT`, `MANIFEST` | `run-host.sh:69-102` | Consistent — non-overridable derived constants, same as the existing block |
| `exit 5` (egress preflight) | exit code | `exit 2` (sweep budget), `exit 3` (nothing ran), `exit 4` (helper misinvoked) | `run-host.sh:544,580,386` | Consistent in spirit (one class per code); undocumented, and the adjacent auth preflight still uses `exit 1` — F8 |
| `CONTAINMENT_FAILED` (sentinel, retained) | file sentinel | `attempts.jsonl`, `result.json`, `preflight.json` | `run-host.sh:498` | Pre-existing; unchanged. Fourth encoding of the same state now exists — F10 |
| `<slug>.index.json` | file contract | `<slug>.tar`, `instances.json`, `run-meta.json` | `scripts/crb-materialize.py:307`, `run-host.sh:479` | Name consistent; the *contract* is asymmetric with its `.tar` sibling — F3 |
| `SUFFIXES` (harvest) | module constant | `ARTIFACT_SUFFIXES` (materialize), `NON_REVIEW`, `STUB_MAX_LEN` | `scripts/crb-materialize.py:75`, `scripts/crb-harvest-artifacts.py:39` | Inconsistent — same contract, two names, two definitions — F5 |
| `MAX_FILE_BYTES` / `MAX_TOTAL_BYTES` / `MAX_FILES` | module constant | `STUB_MAX_LEN`, `MIN_REVIEW_LEN` | `scripts/crb-cell-status.py:52,60` | Consistent — `MAX_`/`MIN_` prefixed caps with a measured rationale comment |
| `changed_artifacts()`, `artifact_index()`, `snapshot_baseline()`, `restore_clone()` | function | `verify_containment()`, `scrub_object_store()`, `materialize()` | `scripts/crb-materialize.py` | Consistent — verb-noun, matching the module's existing family |

---

## Findings

#### F1. `run-host.sh` collapses the audit's three-valued exit contract to two, so "could not check" is recorded as detected contamination

**Severity:** Breaking
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:493-509`, against `scripts/crb-audit-clone.sh:23-32`
**Move:** #3 (trace the consumer contract) / #4 (error consistency)
**Confidence:** High

The producer defines three outcomes, in its own header and in its own test suite:

```
# Exit: 0 = nothing detected · 1 = VOID (contamination) · 2 = could not check.
usage() { echo "usage: crb-audit-clone.sh <clone-dir> <expected-head-sha>" >&2; exit 2; }
[ -d "$CLONE/.git" ] || { echo "no .git in $CLONE" >&2; exit 2; }
  *[!0-9a-fA-F]*|"") echo "expected-head-sha is not a hex sha: $HEAD_SHA" >&2; exit 2 ;;
```

`test/crb-audit-clone.bats:133` pins it: `@test "usage errors exit 2, distinct from a void"`. The
sole consumer erases that distinction:

```
  if ! docker run --rm --network none -u node \
        -v "$clone":/repo \
        -v "$ROOT/scripts/crb-audit-clone.sh":/audit.sh:ro \
        --entrypoint bash "$REVIEW_IMAGE" /audit.sh /repo "$head_sha"; then
    echo "$id: POST-RUN containment audit FAILED — voiding this cell" >&2
    : > "$dest/CONTAINMENT_FAILED"
```

Any non-zero status voids the cell: exit 2 (`.git` absent, `head_sha` not hex, wrong argc), and
also docker's own 125/126/127 (image gone, mount refused, `bash` missing from a changed base
image). Each of those writes `CONTAINMENT_FAILED`, rewrites `result.json` with
`subtype="containment_failed"`, and lands the slug in `voided_cells` — a *published* claim that
contamination was detected on a $10-40 cell that was in fact never checked. The `.git`-absent path
is not hypothetical: the clone is handed to a `--dangerously-skip-permissions` agent, and an agent
that removes or relocates `.git` produces exit 2, which is reported as an answer-key breach.

The same file already handles this correctly twice, which is what makes the omission a
consistency defect rather than an open design question: `run-host.sh:380-388` maps
`crb-cell-status.py`'s exit 2 to `exit 4` ("Exit 2 is a usage error, NOT a verdict"), and
`run-host.sh:478-481` maps the harvest's exit 2 to `exit 4`.

**Recommendation:** Capture the status and branch three ways, matching the cell-status block ten
lines up: `0` → continue, `1` → void, anything else → `echo "$id: audit could not run ($rc)" >&2;
exit 4`. If a "could not check" outcome should be *recorded* rather than fatal, give it its own
sentinel (`AUDIT_UNAVAILABLE`) so it never enters `voided_cells`.

---

#### F2. The audit's documented exit legend and its `git fsck` branch disagree about which code means "could not check"

**Severity:** Inconsistent
**Location:** `scripts/crb-audit-clone.sh:23`, `:63-68`, `:91-94`
**Move:** #4 (error consistency)
**Confidence:** High

The header promises `2 = could not check`. The one branch whose message literally says it cannot
check routes to `note`, and every `note` exits 1:

```
if printf '%s\n' "$fsck_out" | grep -q '^error:'; then
  note "git fsck errored ($(printf '%s\n' "$fsck_out" | grep -m1 '^error:' | cut -c1-160)) — cannot certify containment"
fi
```

```
if [ "${#traces[@]}" -gt 0 ]; then
  echo "CONTAINMENT VOID:"
```

The fact-check reached the same place from the documentation side (Mostly Accurate: "the audit's
documented exit-code legend calls 2 'could not check' while a `git fsck` error exits 1"). Treated
as a contract rather than a comment, the effect is that consumers cannot use exit 2 to mean
"inconclusive" — the one inconclusive condition the script actually detects does not produce it.
Fail-closed is defensible here (a corrupt object store is itself suspicious, and
`test/crb-audit-clone.bats:122` deliberately pins status 1 for it); the legend is what is wrong.

**Recommendation:** Reword line 23 to `2 = could not run (bad invocation / no repo)` and add one
clause noting that an unreadable object store deliberately voids rather than abstains. Do not
change the exit behaviour — the test that pins it names the reason.

---

#### F3. The baseline is one artifact with two halves and only one of them is pinned

**Severity:** Inconsistent
**Location:** `scripts/crb-materialize.py:296-324`, `:345-361`; `runs/review-arms/crb-pipeline/run-host.sh:366`, `:478-481`
**Move:** #7 (asymmetry) / #8 (nullability & integrity contract)
**Confidence:** High

`snapshot_baseline()` publishes two files as one unit:

```
    part.replace(tar)
    index = artifact_index(dst)
    (BASELINE_ROOT / f"{slug}.index.json").write_text(
        json.dumps(index, indent=0, sort_keys=True) + "\n")
```

The `.tar` half gets the full integrity treatment — atomic publish via `.part`, a sha256 in the
manifest, a refusal to restore on mismatch, and a path that `restore_clone()` derives from the slug
precisely "so a hand-edited manifest cannot redirect an extraction". The `.index.json` half gets
none of it: no atomic write, no hash, and its path is supplied by the caller as argv
(`"$CLONES/.baselines/$id.index.json"`). `crb-harvest-artifacts.py` consumes it with a bare
`baseline = json.loads(index_path.read_text())`.

The manifest even records the number that would close this and nothing compares against it:

```
        "baseline_files_indexed": len(index),
```

Consumer impact is on the arm's *output*, not its safety: the index defines what "the pipeline
wrote this" means. A truncated, stale, or half-written index silently reclassifies pre-existing
repo files as pipeline artifacts (inflating the injector's finding count) or, in the other
direction, hides a rubric. Both are invisible — the harvest reports "harvested N artifact(s)"
either way. `test/crb-harvest-artifacts.bats` pins the missing-index case (exit 2) but no case for
a *wrong* index, so nothing keeps the halves in agreement.

**Recommendation:** Give the index the same treatment as the tar — write via `.part` + `replace`,
record `baseline_index_sha256` next to `baseline_sha256`, and have the harvest verify it (it
already receives the manifest's sibling data path). At minimum, assert
`len(baseline) == rec["baseline_files_indexed"]` at harvest time and exit 2 on mismatch — that is
one line and uses a field that is already written.

---

#### F4. `--force` carries a second, unrelated meaning under `--snapshot`, and its help string documents only the first

**Severity:** Inconsistent
**Location:** `scripts/crb-materialize.py:470`, `:517-524`, `:373`
**Move:** #2 (naming against the grain) / #3 (consumer contract)
**Confidence:** High

Precedent: one flag, one meaning, fully stated in `help=` — used in `scripts/crb-materialize.py:452-471`,
`scripts/crb-subset-leaderboard.py` (`--tool`, `--all-prs`, `--judge`, `--markdown`, `--run-meta`),
and `scripts/crb-pipeline-to-benchmark.py` (`--slug`, `--tool-name`, `--runs`, `--stats`, `--no-seed`).

```
    ap.add_argument("--force", action="store_true", help="rebuild existing clones")
```

Under the materialize modes that is accurate (`:373`). Under `--snapshot` it means something else
entirely — overwrite an existing baseline:

```
                            "on a clone NO container has run against — pass --force if "
                            "that is true, or re-materialize with --slug --force.")
```

A consumer reading `--help` sees a flag about *clones* and is given a flag that also governs
*baselines*. The two meanings are not merely different, they are opposed in risk: rebuilding a
clone is idempotent and cheap, while re-snapshotting is the one operation the module's own
docstring calls out as capable of "laundering a used clone into the baseline" — i.e. of quietly
redefining "clean" for every subsequent cell. The runner's own error text at `:413-418` tells an
operator to run `--snapshot`, so the path is reachable by someone who never read the source.

**Recommendation:** Either extend the help string to name both meanings explicitly
(`"rebuild existing clones; with --snapshot, overwrite an existing baseline (only on a clone no container has run against)"`),
or split the second meaning into `--force-baseline`. The one-line help extension preserves the
existing single-flag surface and closes the drift.

---

#### F5. One shared contract, two names, two definitions, held in agreement by a comment — the exact case `crb_common.py` exists to prevent

**Severity:** Inconsistent
**Location:** `scripts/crb-materialize.py:75`, `:270-285`; `scripts/crb-harvest-artifacts.py:39`, `:59-83`
**Move:** #2 (naming against the grain) / #7 (asymmetry)
**Confidence:** High

Precedent: `one definition, imported by both` used in `scripts/crb_common.py:1-20`, consumed at
`scripts/crb-subset-leaderboard.py:30` and `scripts/crb-pipeline-to-benchmark.py:58`. Its docstring
names the trigger for extraction: "a review-fix pass hand-copied them into a second file, where
they are held in agreement by a comment."

That is precisely the state of the artifact-set definition. Two names for one thing:

```
ARTIFACT_SUFFIXES = (".md", ".json")      # crb-materialize.py:75
SUFFIXES = (".md", ".json")               # crb-harvest-artifacts.py:39
```

and the walk-exclusion rule duplicated verbatim, with a comment as the only enforcement:

```
        # Same exclusions as artifact_index() in crb-materialize.py, and they
        # must stay the same: a directory skipped there but walked here reports
        # every file inside it as "new" on the first cell.
        dirs[:] = [d for d in dirs
                   if d != ".git" and not (Path(root) / d).is_symlink()]
```

Unlike A12 (`crb_common.py`'s boundary broken because the *bash* writer cannot import Python), both
sides here are Python modules in `scripts/`, so the import path the precedent uses is available.
The comment itself states the consumer-visible failure of divergence — every file under a
newly-excluded directory reported as a pipeline artifact on the first cell — and no test asserts
the two walks agree.

**Recommendation:** Move the pair (`ARTIFACT_SUFFIXES` and the walk-exclusion predicate) into
`crb_common.py` and import it in both, or have `crb-harvest-artifacts.py` import
`artifact_index`'s helpers from `crb-materialize.py`. Keep the name `ARTIFACT_SUFFIXES` — it is the
more specific of the two and matches the `crb_common` style of naming the domain, not the type.

---

#### F6. `EGRESS_SUBNET` is presented as an operator knob, but half its value is baked into an image

**Severity:** Inconsistent
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:96-99`, `:159`; `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:16`
**Move:** #3 (consumer contract) / #7 (asymmetry)
**Confidence:** High

```
# Pinned so tinyproxy.conf's Allow line can name the subnet exactly rather than
# proxying for whatever else is on this host's default bridge. Override only if
# it collides with something already on the machine.
EGRESS_SUBNET="${EGRESS_SUBNET:-172.31.250.0/24}"
```

The comment explicitly invites an override, and the value flows to exactly one place —
`docker network create --internal --subnet "$EGRESS_SUBNET"`. The proxy's matching half is a
literal in a file copied into the image at build time:

```
Allow 172.31.250.0/24
```

Every other knob in this runner and in `runs/review-arms/e7-fable-3x/run-host.sh:47` (`REPS`) takes
effect wherever it is read. This one takes effect on one side only: an operator who takes the
comment's advice gets a network the proxy refuses to serve, and the failure is reported as
`FAIL: api.anthropic.com unreachable through the proxy — every cell would fail` (`run-host.sh:203`)
— a message that points at the API, the proxy image, or DNS, and never at the override the operator
just set. `test/crb-egress-config.bats:45-56` pins the two literals in agreement, which protects the
default but is silent on the override path (it greps the runner for the literal default string).

The failure is at least loud and free (`exit 5`, before any paid cell), which is why this is
Inconsistent rather than Breaking.

**Recommendation:** Make the knob whole or remove it. Whole: template the `Allow` line via a
`--build-arg`/`sed` at build time, keyed off `$EGRESS_SUBNET`, and extend the bats test to the
templated form. Remove: drop the `${EGRESS_SUBNET:-...}` indirection, make it a plain constant like
`EGRESS_NET`, and change the comment to say the subnet is pinned in two places that must be edited
together.

---

#### F7. The `.baselines/<slug>.{tar,index.json}` layout is stated in two modules — A12's shape, recurring in the new design

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:73`, `:302`, `:307`, `:345`; `runs/review-arms/crb-pipeline/run-host.sh:366`, `:479`
**Move:** #3 (consumer contract)
**Confidence:** High

Prior-review amber A12 observed that `crb_common.py`'s boundary is broken in effect because the
bash writer cannot import it, so the run-dir path is stated three times. The new baseline layout
reproduces that shape rather than avoiding it: `crb-materialize.py` owns `BASELINE_ROOT` and the
`{slug}.tar` / `{slug}.index.json` naming, and `run-host.sh` restates both independently —
`[ -f "$CLONES/.baselines/$id.tar" ]` as its precondition gate, and
`"$CLONES/.baselines/$id.index.json"` as the harvest's argv.

The `.tar` restatement is the more consequential of the two: it is a *precondition check* on a path
whose authority lives elsewhere, so if `BASELINE_ROOT` ever moves, the gate passes or fails on a
path nothing else uses, and the failure surfaces as `--restore` errors inside a cell rather than as
the skip the gate is there to produce. The harvest restatement is milder — the path is passed *to*
the consumer, which is the right direction — but it is still derived by the wrong module.

This is Minor rather than Inconsistent because the constraint A12 names is real: bash cannot import
`crb_common.py`, and the repo has already decided (2026-08-18 tech-debt triage, quoted in
`crb_common.py`'s docstring) not to build a shared module for this arm's logic.

**Recommendation:** Have `crb-materialize.py` grow a `--baseline-path SLUG` (or `--print-paths`)
mode that emits the tar and index paths on stdout, and let `run-host.sh` consume that instead of
rebuilding the paths. One authority, one restatement removed, no new module.

---

#### F8. `exit 5` joins four other undocumented exit codes, and the preflight ten lines below it still exits 1

**Severity:** Minor
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:60-66` (Usage block), `:204`, `:213`, `:222`, `:245`
**Move:** #4 (error consistency)
**Confidence:** High

`run-host.sh` now returns five distinct non-zero codes — `1` (missing manifest, no instances, bad
payload, no key, *auth/skills preflight failure*), `2` (sweep budget), `3` (nothing ran, something
unusable), `4` (helper misinvoked), `5` (egress preflight). The new `5` is a good choice: it gives
the egress control its own signal, which is what makes an unattended wrapper able to distinguish
"the allowlist is broken" from "you forgot the key". But the Usage block documents none of them,
and the *other* preflight in the same section — auth and skill registration, a failure with
identical operational meaning ("do not spend money") — keeps `exit 1`, shared with four argument
errors:

```
python3 - "$OUT/preflight.json" <<'EOF' || { echo "PREFLIGHT FAILED — see $OUT/preflight.json" >&2; exit 1; }
```

`test/crb-egress-config.bats:110-118` asserts `grep -c 'exit 5' >= 3`, so the new code is pinned;
nothing pins or documents the rest.

**Recommendation:** Add a four-line `# Exit:` legend to the header Usage block (`1` precondition ·
`2` sweep budget · `3` nothing usable · `4` helper misinvoked · `5` egress preflight), and consider
moving the auth/skills preflight to its own code (`6`) so the two preflights are symmetric.

---

#### F9. The audit script's header shows an invocation that would not run, for a brand-new argv contract

**Severity:** Minor
**Location:** `scripts/crb-audit-clone.sh:8-13` vs `runs/review-arms/crb-pipeline/run-host.sh:493-496`
**Move:** #3 (documentation drift)
**Confidence:** High

The fact-check rates the header's example Mostly Accurate; as a *contract* document for a new
consumer-facing script it is the only usage documentation that exists, and it does not match the
one real caller. The header shows:

```
#   docker run --rm --network none -v "$clone":/repo -v .../crb-audit-clone.sh:/audit.sh:ro \
#     <image> bash /audit.sh /repo <head-sha>
```

The real call adds `-u node` and `--entrypoint bash`; without the latter the image's
`ENTRYPOINT ["claude"]` (`docker/Dockerfile.review:29`) consumes `bash /audit.sh ...` as arguments
to the CLI. Anyone copying the header to re-run an audit on a saved clone — the natural reason to
read this file — gets a confusing failure from `claude`, not from the audit.

**Recommendation:** Copy the runner's actual flags into the header block (`-u node`,
`--entrypoint bash`), or replace the example with a pointer to `run-host.sh:493-496` as the
canonical invocation so the two cannot drift again.

---

#### F10. A9 re-checked: the void protocol now has a fourth encoding and still no test asserting the four agree

**Severity:** Informational
**Location:** `scripts/crb-audit-clone.sh:23`; `runs/review-arms/crb-pipeline/run-host.sh:497-509`, `:319`, `:349-350`; `scripts/crb-subset-leaderboard.py:71`; `scripts/crb-pipeline-to-benchmark.py:242`
**Move:** #7 (asymmetry)
**Confidence:** High

Prior amber A9 counted three encodings of "this cell is void" — the `CONTAINMENT_FAILED` sentinel,
the rewritten `result.json`, and `voided_cells` — with three readers and one `|| true` writer. The
new design does not reduce that; it adds the audit's tri-state exit code as a fourth. The writer is
still best-effort:

```
    python3 - "$dest/result.json" <<'EOF' || true
```

so a cell can carry the sentinel (read by the injector at `crb-pipeline-to-benchmark.py:242`) and
appear in `voided_cells` (read by the leaderboard at `crb-subset-leaderboard.py:71`) while its
`result.json` still reports `subtype="success"` — which is what `crb-cell-status.py` reads, and it
structurally cannot see the sentinel. A repo-wide grep finds no test referencing
`CONTAINMENT_FAILED` at all, so nothing pins the four representations in agreement. F1 makes this
worse in one specific way: it lets a *non*-void condition enter three of the four encodings.

**Recommendation:** Out of scope for this commit to fix, but worth one bats case in
`test/crb-egress-config.bats` (which already parses `run-host.sh` textually): assert that the
sentinel write, the `result.json` rewrite and the `voided_cells` derivation all key off the same
condition. Note also that fixing F1 shrinks the surface this amber covers.

---

#### F11. A12 and A13 re-checked: unchanged by this commit

**Severity:** Informational
**Location:** `scripts/crb-materialize.py:66-82`; `runs/review-arms/crb-pipeline/run-host.sh:349`; `scripts/crb-subset-leaderboard.py:56-80`
**Move:** #1 (baseline conventions)
**Confidence:** High

A12: `crb-materialize.py` still declares its own `WORKSPACE`, `BENCH`, `BENCH_DATA` and `MANIFEST`
rather than importing the identical values from `crb_common.py` — and this commit edited that exact
constants block (inserting `BASELINE_ROOT` and `ARTIFACT_SUFFIXES` between them at `:73-75`), so it
was the natural moment to close it. `crb_common.MANIFEST` and `crb-materialize.MANIFEST` are the
same path, defined twice. This is a Python↔Python duplication, so unlike the bash case the
precedent's import path is available; see F5 for the same pattern in the new code.

A13: `missing_cells` is still written at `run-host.sh:349` and read by nobody —
`crb-subset-leaderboard.py:73-80` re-derives it from `requested_instances` minus `cells`. Untouched
by this commit and correctly out of its scope; recorded here only because the brief asked for a
re-check.

**Recommendation:** Bundle both into a separate small cleanup commit rather than expanding this
one. A12 is a four-line import change; A13 is a delete-or-consume choice already spelled out in the
prior review.

---

#### F12. The setup doc's disk figure for `--all` disagrees with the CLI's own help

**Severity:** Minor
**Location:** `docs/working/crb-direction1-setup.md:27` vs `scripts/crb-materialize.py:39`
**Move:** #3 (documentation drift)
**Confidence:** High

The fact-check flags this as Stale; as an interface problem it is a two-place contract where only
one place was updated by this commit. The script's own usage block was corrected —
`--all # all 50 (~13 GB w/ baselines)` — while the operator-facing runbook still says:

```
scripts/crb-materialize.py --all           # all 50 (~6-7 GB)
```

The doubling is the direct, intended consequence of the disposable-clone design
(`crb-materialize.py:440-443` states it), and the runbook is what an operator reads before
provisioning disk for a 50-PR sweep. A `--all` that fills the disk halfway through is a failure
during, not before, a paid pilot.

**Recommendation:** Update line 27 to `~13 GB (clones + baselines)`. The same doc's `--restore` /
`--snapshot` lines were correctly updated in this commit, so this is a single missed line rather
than a stale section.

---

## What Looks Good

- **`crb-harvest-artifacts.py`'s exit contract is exactly right, and its consumer honours it.**
  `0` = harvested (possibly nothing) · `2` = invocation error, with the reasoning stated where a
  future editor will see it ("Exit 2, never 1: the caller distinguishes 'nothing to harvest' from
  'this invocation is broken'"), and `run-host.sh:478-481` maps non-zero to `exit 4`. It matches
  `crb-cell-status.py`'s convention without copying its shape blindly — the harvest genuinely has
  only two outcomes, so it declares two.
- **`--restore` correctly opted *out* of the `head`-in-manifest precondition, and said why**
  (`crb-materialize.py:495-503`). Requiring a field the operation does not use is the easy mistake
  here; the code names the field it *does* depend on (`baseline_sha256`) and checks it in the
  function that uses it.
- **`--dry-run` now applies to the mode flags.** Prior finding F1 of the 2026-08-18 review was that
  `--reset SLUG --dry-run` ran the destructive reset anyway; the replacement handles all three
  modes at `:481-486` and `test/crb-disposable-clone.bats:168` pins it.
- **New manifest fields match the existing provenance family** in both naming (`baseline_mb`
  alongside `clone_mb`; `baseline_files_indexed` alongside `files_changed`) and in being additive —
  no existing field changed type or meaning, so the injector and leaderboard read old manifests
  unchanged.
- **`baseline_tar` is documented as provenance-only and the code refuses to trust it**
  (`crb-materialize.py:314-318`): the restore derives the path from the slug. Recording a value and
  then not depending on it is the right call for a manifest that a human may edit.
- **The egress preflight tests the thing that runs, not a description of it.** `in_cell_net()`
  reuses the same image, network and proxy env the paid cell gets, and the three legs fail for three
  different reasons — the positive leg alone would pass with a broken filter, and the two negative
  legs alone would pass with a dead proxy.
- **`crb-audit-clone.sh` being the only `.sh` in the `crb-*` family is justified, not accidental** —
  it executes inside the `node:22` review image where `python3` is not guaranteed. The hardened
  `git()` wrapper (`safe.directory`, `core.hooksPath=/dev/null`, `core.fsmonitor=`,
  `protocol.ext.allow=never`) is defence-in-depth on top of the container boundary, and says so.

## Versioning Impact

No consumer outside this repo binds to these surfaces. Within it:

- **Breaking for operators, deliberately:** `--reset` and `--heal` are removed rather than
  deprecated, and `--verify` changed target (work clone → baseline). Both are correct — a
  deprecation shim for `--reset` would keep alive the exact host-git-against-container-`.git`
  arrangement the commit exists to delete. `test/crb-egress-config.bats:101-108` asserts the modes
  are gone from the runner, not merely unused.
- **Breaking for pre-existing state, and the fact-check is right that it bites:** the five existing
  clones carry no baseline, so `run-host.sh:366` skips every one and the sweep exits 3 until an
  operator runs `--snapshot`. The runner's skip message names the remedy (`:413-418`) and the setup
  doc documents it (`:30`), which is the right handling for a one-time migration — but it does mean
  the first post-merge sweep is a no-op unless the operator reads stderr.
- **Additive and safe:** the four `baseline_*` manifest fields, `exit 5`, `EGRESS_SUBNET`,
  `crb-audit-clone.sh`, `crb-harvest-artifacts.py`, the `docker/` build context. No reader of
  `instances.json` or `run-meta.json` requires the new fields.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Runner collapses the audit's 3-value exit contract; "could not check" and docker failures are recorded as detected contamination | Breaking | `run-host.sh:493-509` | High |
| 2 | Audit's exit legend says 2 = "could not check"; the one inconclusive branch exits 1 | Inconsistent | `crb-audit-clone.sh:23,63-68` | High |
| 3 | Baseline `.tar` is hash-pinned and path-derived; its `.index.json` half is neither, and `baseline_files_indexed` is never checked | Inconsistent | `crb-materialize.py:296-324`, `crb-harvest-artifacts.py:102` | High |
| 4 | `--force` has a second meaning under `--snapshot`; `--help` documents only the first | Inconsistent | `crb-materialize.py:470,517-524` | High |
| 5 | `ARTIFACT_SUFFIXES` / `SUFFIXES` — one contract, two names, two definitions, agreed by comment | Inconsistent | `crb-materialize.py:75`, `crb-harvest-artifacts.py:39` | High |
| 6 | `EGRESS_SUBNET` is overridable on one side only; the proxy's `Allow` is baked into the image | Inconsistent | `run-host.sh:96-99`, `docker/tinyproxy.conf:16` | High |
| 7 | `.baselines/<slug>.{tar,index.json}` layout restated in `run-host.sh` (A12's shape, recurring) | Minor | `run-host.sh:366,479`, `crb-materialize.py:73` | High |
| 8 | `exit 5` joins four undocumented codes; the adjacent auth preflight still exits 1 | Minor | `run-host.sh:60-66,245` | High |
| 9 | Audit header's `docker run` example omits `-u node`/`--entrypoint bash`; would be eaten by `ENTRYPOINT ["claude"]` | Minor | `crb-audit-clone.sh:8-13` | High |
| 10 | Void protocol gains a fourth encoding; still no test asserting the encodings agree (A9) | Informational | `run-host.sh:497-509` | High |
| 11 | A12 (duplicate constants) and A13 (`missing_cells`) unchanged | Informational | `crb-materialize.py:66-82`, `run-host.sh:349` | High |
| 12 | Setup doc still says `--all ~6-7 GB`; the CLI now says ~13 GB | Minor | `crb-direction1-setup.md:27` | High |

## Overall Assessment

The new surfaces are, with one exception, well-matched to the conventions this harness has built up
over the prior review passes: the exit-code convention that amber A2 established is understood and
correctly instantiated in `crb-harvest-artifacts.py`, the new manifest fields slot into the existing
provenance family without changing anything a reader already binds to, and the removals (`--reset`,
`--heal`) are clean breaks with tests pinning them rather than deprecation shims that would keep the
dangerous arrangement alive. The author clearly surveyed the existing code — several of the
comments cite the sibling conventions by name.

The exception is F1, and it is the one finding that costs money. `crb-audit-clone.sh` defines a
three-valued contract, documents it, and pins it with a test; `run-host.sh` — which honours exactly
that contract for `crb-cell-status.py` ten lines earlier and for the harvest ten lines later —
reduces it to a boolean, so a broken audit invocation and a missing `docker` are both published as
"contamination was DETECTED" on a paid cell. That is a five-line fix in place, and it also shrinks
the A9 surface. F3 is the second one worth doing before a sweep: the index half of the baseline is
what defines the arm's *output*, and it is the only unpinned link in an otherwise carefully pinned
chain. F4, F5 and F6 are cheap in-place fixes that keep the next reader from having to re-derive
the intent. Nothing here suggests the author needs to re-survey the codebase; the misses are local,
and F1 in particular reads as the one consumer that was written before the producer's contract had
settled.

## Goal-Alignment Note
- Answered: yes — full API-consistency pass on 197eec6, report saved to `docs/reviews/api-consistency-review.md`
- Out of scope: everything docker-shaped was not executed (per brief, not reported as a defect); prior ambers A9/A12/A13 were re-checked but their *fixes* are left to a separate commit (F10, F11); non-API concerns (security exploitability, performance, architecture) belong to the sibling critics
- Escalate: F1 is a money-losing defect in a new inter-module contract and should be fixed before any paid sweep — it is independent of the rest of the review-fix loop and could be dispatched on its own. F3 is second priority for the same reason (it corrupts the arm's output record, silently)
