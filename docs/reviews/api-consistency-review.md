# API Consistency Review — feat/crb-direction1-harness, fix commits `c98343b..HEAD`

**Scope:** `git diff c98343b..HEAD -- scripts runs test docs/decisions docs/working` — commits `1d8ea67`, `4624c5d` (13 files, +912/−201). `197eec6` is context only.
**Date:** 2026-08-19
**Based on:** `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness-r2.md` (R1–R4, A1–A14, C1–C14) and this file's predecessor revision (F1–F12), which this revision replaces.
**Position:** TERMINAL pass of a review-fix loop at its 3-iteration cap.

> ⚠️ **No code fact-check report provided for THIS pass.** The iteration-2 fact-check
> (referenced throughout the diff's own comments) covered `197eec6`; the two commits under
> review here are its answer. Documentation claims in the new code have therefore been
> verified by reading only, not by an independent fact-check pass.

---

## Baseline Conventions

Surveyed to establish what "consistent" means here: `scripts/crb-cell-status.py`,
`scripts/crb-harvest-artifacts.py`, `scripts/crb-audit-clone.sh`, `scripts/crb_common.py`,
`scripts/crb-materialize.py`, `runs/review-arms/crb-pipeline/run-host.sh`,
`runs/review-arms/e7-fable-3x/run-host.sh`.

1. **Extracted-decider scripts take positional argv, return a small integer verdict, and
   reserve `2` for "not a verdict".** `crb-cell-status.py:90-97` names this explicitly with
   `EXIT_COMPLETE, EXIT_INCOMPLETE, EXIT_USAGE = 0, 1, 2` and a comment calling the exit codes
   "a consumed contract". `crb-audit-clone.sh:30` is `0 = nothing detected · 1 = VOID · 2 =
   could not check`. `crb-harvest-artifacts.py:32` is `0 harvested · 2 usage/invocation error`
   — it has no `1`, i.e. the family reserves 2 for invocation failure even where 1 is unused.
2. **The consumer is obliged to distinguish "could not run" from a verdict, and to abort
   rather than guess.** `run-host.sh:465-473` (cell-status → `exit 4`) and `:610-611`
   (harvest → `exit 4`) both do this, with comments saying why.
3. **Verdict text goes to stdout; usage/diagnostics go to stderr.** `crb-audit-clone.sh:41`
   vs `:109-110`; `crb-cell-status.py:101-105` vs `:116`.
4. **Argument values are validated before a verdict is rendered.** `crb-audit-clone.sh:45-47`
   rejects a non-hex head-sha with exit 2 rather than auditing against garbage.
5. **A shared definition gets one owner and is imported, not restated.** `crb_common.py`'s
   docstring names the exact trigger: "a review-fix pass hand-copied them into a second file,
   where they are held in agreement by a comment."
6. **Runner knobs are `SCREAMING_SNAKE` env vars with `${X:-default}` and a why-comment**
   (`MODEL`, `BUDGET`, `SWEEP_BUDGET`, `MAX_ATTEMPTS`, `DRY_RUN`, `CC_VERSION`; `REPS` in
   `e7-fable-3x/run-host.sh:47`).
7. **`crb-materialize.py`'s modes are imperative verbs in a mutually-exclusive group**
   (`--list`, `--verify`, `--restore`, `--all`, `--per-repo`, `--slug`), each documented in
   the module docstring's Usage block and in `--help`.
8. **Script naming is `crb-<domain>-<noun>.<ext>`**: `crb-cell-status.py`,
   `crb-audit-clone.sh`, `crb-harvest-artifacts.py`, `crb-subset-leaderboard.py`.

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `scripts/crb-egress-verdict.sh` | file/module | `crb-cell-status.py`, `crb-audit-clone.sh`, `crb-harvest-artifacts.py` | `scripts/crb-*.{py,sh}` | Consistent — `crb-<domain>-<noun>`, same extraction move as `crb-cell-status.py` |
| `crb-egress-verdict.sh <leg> <observed>` | argv contract | `crb-audit-clone.sh <clone-dir> <expected-head-sha>`, `crb-cell-status.py <result.json>` | `scripts/crb-audit-clone.sh:41-47`, `scripts/crb-cell-status.py:99-106` | **Inconsistent** — `<observed>` is polymorphic (an HTTP code for 4 legs, a shell command line for 1) and is not validated at all; both siblings validate every argument. → F3, F4 |
| exit `0/1/2` of `crb-egress-verdict.sh` | error code | `crb-cell-status.py` `0/1/2`, `crb-audit-clone.sh` `0/1/2` | `scripts/crb-cell-status.py:96`, `scripts/crb-audit-clone.sh:30` | Consistent as **published**; the consumer collapses `2` into `1`. → F1 |
| `api-reachable` | enum variant (leg) | *(no existing leg/mode-string enum in the repo)* | none — searched `scripts/*.sh` for `case "$1" in`-style dispatch; only hit is this new file | New category |
| `filter-blocks` / `plain-http` | enum variant (leg) | each other; `api-reachable`, `no-direct-route`, `internal-net` | none — searched `scripts/*.sh` | **Inconsistent within the new set** — two legs share one verdict predicate but are named from different vocabularies (assertion vs transport). → F6 |
| `no-direct-route` | enum variant (leg) | `api-reachable`, `internal-net` | none — searched `scripts/*.sh` | Mixed grammar within the set (negated-noun vs adjective-phrase vs subject-verb) → folded into F6 |
| `internal-net` | enum variant (leg) | the four http legs | none — searched `scripts/*.sh` | Consistent name; **inconsistent kind** — it is a static string assertion, not an observation. → F4 |
| `PREFLIGHT_ONLY` | env var (config) | `DRY_RUN`, `MAX_ATTEMPTS`, `SWEEP_BUDGET` | `runs/review-arms/crb-pipeline/run-host.sh:96-110`; `runs/review-arms/e7-fable-3x/run-host.sh:47` | Consistent — same `${X:-}` + `[ -n "$X" ]` shape as `DRY_RUN`, same why-comment style |
| `--baseline-paths SLUG` | CLI flag | `--verify SLUG`, `--restore SLUG`, `--list` | `scripts/crb-materialize.py:493-513` | Minor deviation — every other mode is an imperative verb; this is a noun-phrase query. Documented in `--help`; **absent from the module docstring's Usage block**. → F8 |
| `baseline_paths(slug)` | function | `snapshot_baseline`, `restore_clone`, `artifact_index`, `verify_containment` | `scripts/crb-materialize.py:193-380` | Consistent — bare `noun_noun` returning a tuple, matching `artifact_index`'s naming |
| `baseline_index_sha256` | manifest field | `baseline_sha256`, `baseline_tar`, `baseline_mb`, `baseline_files_indexed` | `scripts/crb-materialize.py:311-334` | Consistent name; **not added to the documented manifest field list**. → F7 |
| `egress_leg` | shell function | `in_cell_net`, `setup_egress`, `teardown_egress`, `write_run_meta` | `runs/review-arms/crb-pipeline/run-host.sh:170-215, 337, 398` | Consistent — `verb_noun` / `noun_noun` lowercase snake, same as siblings |
| `sweep_spend_ok` | shell function | `in_cell_net`, `write_run_meta` | `runs/review-arms/crb-pipeline/run-host.sh:170-215` | Consistent — and `_ok` predicate suffix reads correctly against its `|| { ... exit 2; }` use |
| `NET_CREATE_CMD` | shell var | `PROXY_URL`, `EGRESS_NET`, `EGRESS_SUBNET`, `REVIEW_IMAGE` | `runs/review-arms/crb-pipeline/run-host.sh:110-116` | Consistent |
| `run-host.sh` exit `4` | error code | `exit 4` already used for cell-status and harvest invocation failure | `runs/review-arms/crb-pipeline/run-host.sh:465-473`, `:610-611` | Consistent — `4` now means "a tool could not run" in all three places |
| `run-host.sh` exit `6` | error code | `1`, `2`, `3`, `5` in the same file | `runs/review-arms/crb-pipeline/run-host.sh` | Consistent value choice; **undocumented, and its condition scans cells outside the sweep**. → F2, F5 |
| `--snapshot` (REMOVED) | CLI flag | — | `scripts/crb-materialize.py` @ `197eec6` | Removed cleanly; every remediation string, `--help`, the docstring and both consumers were updated together. See What Looks Good. |

---

## Findings

#### F1. `crb-egress-verdict.sh` publishes a 0/1/2 contract; `run-host.sh` consumes it as 0/nonzero — F1's exact shape, in the new file

**Severity:** Inconsistent
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:216-234` against `scripts/crb-egress-verdict.sh:18, 27-34`
**Move:** #3 (consumer contract) / #4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

The new script documents and tests a three-valued contract:

```
# Exit:   0 = leg passed · 1 = leg FAILED (do not spend) · 2 = usage error.
```

and `test/crb-egress-verdict.bats` pins it with a case whose own comment says the distinction
must survive:

```
# Exit 2 is not a verdict. The runner treats a nonzero as "do not spend", so a
# usage error failing closed is right — but it must be distinguishable.
@test "usage errors exit 2, distinct from a failed leg" {
```

The sole consumer does not distinguish it:

```
  local out rc=0
  out=$(bash "$VERDICT" "$1" "$2") || rc=$?
  printf '%s\n' "$out" | sed 's/^/  /'
  [ "$rc" -eq 0 ] || { echo "  (refusing to spend — egress leg '$1' failed)" >&2; exit 5; }
```

A typo'd leg name, a missing argument, or a `$VERDICT` path that does not resolve all report
`egress leg 'X' failed` and exit **5** — the code documented in
`docs/working/crb-direction1-setup.md:98` as "the allowlist is not filtering". The same file
maps exit 2 to `exit 4` ("a tool could not run") in three other places, each with a comment
explaining why guessing is wrong (`:465-473`, `:610-611`, `:637-641`). This is R2/F1's shape
reproduced inside the fix for R2/F1, one abstraction layer down. Consequence is far milder —
$0, fails closed, before any cell — which is why this is Inconsistent, not Breaking.

**Recommendation:** In `egress_leg`, branch: `[ "$rc" -ne 2 ] || { echo "egress verdict tool
invoked wrongly for leg '$1' — not a verdict" >&2; exit 4; }` before the existing `exit 5`.
Five lines, and it makes the bats case's stated intent ("must be distinguishable") true of the
system rather than only of the script.

---

#### F2. `exit 6` fires on void markers left by cells this sweep never touched

**Severity:** Inconsistent
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:686-699` vs `:503-506`
**Move:** #3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

The new sweep-level status counts sentinels by scanning the whole arm directory:

```
voided=$(python3 - "$OUT" <<'EOF' || echo 0
import os, sys
out = sys.argv[1]
print(sum(1 for n in os.listdir(out)
          if os.path.isfile(os.path.join(out, n, "CONTAINMENT_FAILED"))))
EOF
)
```

`$OUT` is the arm root (`runs/review-arms/crb-pipeline`), not this sweep's `INSTANCES`. The
staleness guard added in `4624c5d` is per-cell and only on the path that actually re-runs a
cell:

```
  # A void marker from an EARLIER sweep must not make this sweep exit 6: nothing
  # else ever deletes it, so the status would be sticky forever once any cell had
  # ever voided. This cell is about to be re-decided, so its old verdict goes.
  rm -f "$dest/CONTAINMENT_FAILED"
```

Three documented paths reach `continue` *before* that line — the baseline gate (`:449-455`),
the already-complete skip (`:465-467`), and `MAX_ATTEMPTS` (`:498-501`) — and the runner
explicitly supports subset invocation (`... run-host.sh discourse-graphite-PR4
grafana-PR79265`, Usage block `:71`). So `bash run-host.sh grafana-PR79265` returns 6 —
"cell(s) VOIDED by the containment audit" — when the void belongs to a different slug from a
prior sweep. A caller (CI, a wrapper, a human reading `$?`) cannot tell "this sweep voided
something" from "this arm directory has ever voided anything". `run-meta.json`'s
`voided_cells` has the same scope and is at least *named* as an accumulating artifact; the
process exit code is not.

**Recommendation:** Count sentinels over `"${INSTANCES[@]}"` rather than `os.listdir(out)`,
or pass the requested slugs in as argv the way `write_run_meta` already passes `requested`.
Alternatively state in the Usage block that 6 is an arm-level, not sweep-level, status.

---

#### F3. `crb-egress-verdict.sh` renders a definite verdict on an unvalidated `<observed>`

**Severity:** Inconsistent
**Location:** `scripts/crb-egress-verdict.sh:36-38, 44-78`
**Move:** #3 (consumer contract) / #4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

The leg name is validated; the observation is not:

```
[ $# -eq 2 ] || usage
leg=$1; observed=$2
[ -n "$leg" ] || usage
```

An empty or non-numeric `<observed>` is a reachable state. `egress_leg`'s arguments are
command substitutions, and a failing `docker run` yields an empty string without tripping
`set -e` (a failed substitution in a simple command's *arguments* does not set the command's
status):

```
egress_leg no-direct-route "$(docker run --rm --network "$EGRESS_NET" --entrypoint bash "$REVIEW_IMAGE" \
  -c 'curl -s -o /dev/null -w "%{http_code}" --max-time 20 https://github.com/ || echo 000')"
```

If that `docker run` fails to start, the verdict script sees `""`, takes the `!= "000"` branch,
and prints `FAIL no-direct-route: reached a non-allowlisted host (HTTP ) with NO proxy env —
the network is not internal.` That is a positive assertion about containment derived from an
absent observation — the identical error class R2 was raised for, inverted. The sibling
validates exactly this:

```
case "$HEAD_SHA" in
  *[!0-9a-fA-F]*|"") echo "expected-head-sha is not a hex sha: $HEAD_SHA" >&2; exit 2 ;;
esac
```
(`scripts/crb-audit-clone.sh:45-47`)

**Recommendation:** For the four http legs, reject anything not matching `[0-9][0-9][0-9]`
with `usage`/exit 2 (not a verdict). One `case` before the dispatch. Add a bats case
mirroring `crb-audit-clone.bats`'s bad-sha case.

---

#### F4. The `<leg> <observed>` contract carries two argument types, and one leg's "observation" cannot fail at runtime

**Severity:** Minor
**Location:** `scripts/crb-egress-verdict.sh:21-23, 79-88`; `runs/review-arms/crb-pipeline/run-host.sh:174-177, 236-238`
**Move:** #7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

The published usage says so in as many words:

```
# `<observed>` is the curl `%{http_code}` for the http legs ("000" when curl
# could not connect at all), or the literal network-create command line for the
# `internal-net` leg.
```

Four legs are observations of behaviour; the fifth is a string the runner itself composes as a
literal one line before:

```
  NET_CREATE_CMD="docker network create --internal --subnet $EGRESS_SUBNET $EGRESS_NET"
  $NET_CREATE_CMD >/dev/null
```
```
egress_leg internal-net "$NET_CREATE_CMD"
```

At runtime `*--internal*` matches unconditionally. Its only real enforcement is
`test/crb-egress-verdict.bats`'s "the runner's own network create really carries `--internal`"
case, which is a static grep. `docs/decisions/034:...` concedes the point ("whether docker
honours `--internal` is itself only observable at runtime"), but the runner presents the leg
inline with four genuine probes and prints `ok  network created --internal` in the same
indented stream, where an operator reads all five identically. That is a legibility asymmetry
in the preflight's own output contract, not just in the argv type.

**Recommendation:** Either observe it (`docker network inspect "$EGRESS_NET" --format
'{{.Internal}}'` → `true`, which is a real runtime observation and keeps the leg honest), or
label the printed line differently from the probes, e.g. `asserted  network create carries
--internal (static)`. The former is one command and closes the gap 034 documents as residual.

---

#### F5. `run-host.sh` now publishes six exit codes and documents none of them (F8, restated and larger)

**Severity:** Minor
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:68-73` (Usage block), `:118`, `:127`, `:146`, `:152`, `:233`, `:274`, `:437`, `:472`, `:528`, `:611`, `:641`, `:684`, `:699`
**Move:** #4 (error consistency) / #6 (versioning impact)
**Confidence:** High
**Legibility-target:** for-author

Prior F8 flagged five undocumented exit codes. These commits added two more conditions —
`exit 4` for "the containment audit could not run" and `exit 6` for "a cell voided" — and
documented neither. A grep over the runner, `docs/working/crb-direction1-setup.md` and
`docs/decisions/034-...` for an exit legend returns nothing; the only exit-code documentation
in the repo is `scripts/crb-cell-status.py:90-97` and `scripts/crb-audit-clone.sh:30-38`,
which both do it well, and `scripts/crb-egress-verdict.sh:18`, which is new in this diff and
also does it well. The runner is the only member of the family that publishes a status to a
human/CI caller and never says what it means. Current set: `0` ok · `1` bad invocation or
failed auth preflight · `2` sweep budget exceeded · `3` no cell ran · `4` a tool could not run
· `5` egress control failed · `6` a cell voided. The docs state three of these in prose in
three separate files (`034:79` "exits 3", `setup:98` "exits 5", and the `PREFLIGHT_ONLY` block
"exit 0"), which is how the set drifted in the first place.

**Recommendation:** Seven lines in the Usage block at `:68-73`, mirroring
`crb-cell-status.py`'s `--help`. This is the cheapest item in the report and the one an
operator reading `$?` after an unattended overnight sweep depends on most.

---

#### F6. The five leg names come from four different vocabularies, and the two legs sharing a verdict do not share a name stem

**Severity:** Minor *(downgraded from Inconsistent — no precedent; see the line below)*
**Location:** `scripts/crb-egress-verdict.sh:29-33, 44-88`; `runs/review-arms/crb-pipeline/run-host.sh:236-249`
**Move:** #2 (naming against the grain)
**Confidence:** High
**Legibility-target:** for-author

No existing precedent in `scripts/*.sh` — grepped for `case "$1" in`-style mode/leg dispatch
across every shell script in `scripts/`; the only match is this new file. Severity downgraded
one tier accordingly; the finding is kept so the convention being established is deliberate.

The set is `api-reachable` (subject + adjective), `filter-blocks` (subject + verb),
`no-direct-route` (negated noun), `plain-http` (a transport name, no assertion at all),
`internal-net` (adjective + noun). The sharpest consequence is that the two legs which are
literally the same assertion over two transports share a verdict arm but not a name stem:

```
  filter-blocks|plain-http)
    ...
      403|000)
        echo "ok  non-allowlisted host refused ($leg, HTTP $observed)" ;;
```

The printed line is `ok  non-allowlisted host refused (plain-http, HTTP 403)` versus `ok
non-allowlisted host refused (filter-blocks, HTTP 403)`. A reader of the preflight output —
the artifact the whole extraction exists to make legible — cannot tell that `filter-blocks` is
the HTTPS one; nothing in either name says `https`. `docs/working/crb-direction1-setup.md`
and `tinyproxy.conf` both go to some length to explain that the HTTPS/plain-HTTP split is the
whole point of leg 2b, and the names hide it.

**Recommendation:** Rename to `filter-blocks-https` / `filter-blocks-http` (the two callers,
the `case` arm, `usage()`, and the leg lists in `test/crb-egress-verdict.bats` and
`test/crb-egress-config.bats` — all textual, ~8 sites). Optionally rename `internal-net` →
`net-internal` for uniform adjective placement, but that is taste; the http pair is not.

---

#### F7. The manifest schema gained a required field and its documented field list did not

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:43-46` vs `:326-336`, `:388-402`
**Move:** #3 (consumer contract — documentation drift) / #8 (nullability contract)
**Confidence:** High
**Legibility-target:** for-author

The module docstring enumerates the manifest record, and this is the documented schema two
other modules bind to:

```
Writes/updates runs/review-arms/crb/instances.json. Each record carries: url,
source_repo, pr_title, fork, fork_url, head, base, commits, n_goldens,
files_changed, insertions, deletions, clone_mb, depth, baseline_tar,
baseline_sha256, baseline_mb, baseline_files_indexed. The runner
(runs/review-arms/crb-pipeline/run-host.sh) and the injector
(scripts/crb-pipeline-to-benchmark.py) both read that manifest, so the PR
identity travels with the artifacts instead of being re-derived.
```

`baseline_index_sha256` is missing from that list even though `snapshot_baseline` now writes
it and `restore_clone` treats its **absence as a hard failure**:

```
    if not idx_want:
        raise RuntimeError(
            f"manifest has no baseline_index_sha256 (baseline predates the index "
            f"pin) — rebuild with `--slug {slug} --force`")
```

That is a new required field in a persisted contract — by move #6's rules, a breaking change
to the manifest — landing in the one place a consumer would look to find out. It is handled
correctly at runtime (explicit error naming the field and the remedy, pinned by
`test/crb-disposable-clone.bats` "a manifest with no index hash refuses to restore"), so the
defect is purely that the schema doc did not move with the schema. Note this is the same
docstring that F12 corrected for the disk figure in these very commits.

**Recommendation:** Add `baseline_index_sha256` to the docstring list and mark it, plus
`baseline_sha256`, as required-for-restore. One line.

---

#### F8. `--baseline-paths` is absent from the module docstring's Usage block, which is where every other mode is advertised

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:34-41` vs `:497-500`
**Move:** #2 (naming against the grain) / #3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `every mode appears in both the docstring Usage block and --help` used in
`scripts/crb-materialize.py:34-41` (`--list`, `--per-repo`, `--slug`, `--all`, `--dry-run`,
`--verify`, `--restore` all appear in both), and the same commits *maintained* that invariant
when deleting `--snapshot` and when adding the `--slug ... --force` line.

```
  scripts/crb-materialize.py --verify   grafana-PR79265 # re-check the baseline
  scripts/crb-materialize.py --restore  grafana-PR79265 # wipe + re-extract (per cell)
  scripts/crb-materialize.py --slug grafana-PR79265 --force  # rebuild + baseline
```

`--baseline-paths` — the newest and the only machine-consumed mode — is documented only in
`--help`. It is also the only mode named as a noun phrase rather than an imperative verb
(`--list`/`--verify`/`--restore`); given the two-line stdout protocol it defines, a reader
finding it in the Usage block would learn about that contract at the same time they learn the
mode exists.

**Recommendation:** Add one Usage line, e.g.
`scripts/crb-materialize.py --baseline-paths grafana-PR79265  # print tar path, then index path`.
The comment naming the output order is the part that matters — see F9.

---

#### F9. The `--baseline-paths` two-line protocol has no failure channel, and the runner reports a tool crash as "no baseline"

**Severity:** Inconsistent
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:444-455`; `scripts/crb-materialize.py:512-516`
**Move:** #3 (consumer contract) / #4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

The protocol itself is sound in the happy path — two absolute paths, positional, tar then
index, single owner, pinned by `test/crb-disposable-clone.bats` "baseline_paths is the single
definition of the layout, and the runner uses it". The consumption is where it slips:

```
  mapfile -t _bl < <(python3 "$ROOT/scripts/crb-materialize.py" --baseline-paths "$id")
  if [ ! -f "${_bl[0]:-/nonexistent}" ] || [ ! -f "${_bl[1]:-/nonexistent}" ]; then
    echo "$id: no baseline — rebuild the clone and its baseline with:" >&2
```

`mapfile < <(...)` discards the producer's exit status, and process substitution does not
trip `set -e`. If `crb-materialize.py` cannot run at all — wrong `python3` on PATH, an import
error, a syntax error introduced by a later edit — `_bl` is empty, both tests fall through to
`/nonexistent`, and **every slug in the sweep** is reported as `no baseline` with a remedy
(`--slug $id --force`) that invokes the same broken script. The sweep then exits 3, "NO CELL
RAN and N instance(s) were unusable". The operator is told the baselines are missing when the
truth is that the path-publishing tool is broken. This is the same "collapse could-not-run
into a definite verdict" shape as F1/R2, and the runner's own convention (`:465-473`,
`:610-611`, `:637-641`) is to exit 4 instead. It fails safe at $0, hence Inconsistent.

Secondary: the protocol is positional with no labels and no count check — `${_bl[1]}` is later
passed straight to the harvest as the index path (`:610`), so a future third output line, or a
warning printed to stdout by an imported module, silently shifts the meaning of both slots.

**Recommendation:** Capture the status and the line count:

```
  _blout=$(python3 "$ROOT/scripts/crb-materialize.py" --baseline-paths "$id") || {
    echo "$id: crb-materialize.py --baseline-paths failed — not a baseline verdict" >&2; exit 4; }
  mapfile -t _bl <<<"$_blout"
  [ "${#_bl[@]}" -eq 2 ] || { echo "$id: --baseline-paths returned ${#_bl[@]} line(s), expected 2" >&2; exit 4; }
```

---

#### F10. The preflight's section header still says "three ways"

**Severity:** Minor
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:208`
**Move:** #3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

```
# ── Egress preflight: PROVE the allowlist, three ways ───────────────────────
```

Five legs now run below it. `docs/decisions/034`, `docs/working/crb-direction1-setup.md`,
`test/crb-egress-config.bats` ("runs all five legs") and `scripts/crb-egress-verdict.sh` were
all updated to five in these commits; this one banner was not. It is the first line an
operator reads when the preflight block is what they came to check, and A12/F12 in the prior
round were exactly this class ("the tree reset below", the `~6-7 GB` figure) — both of which
*were* fixed here.

**Recommendation:** `# ── Egress preflight: PROVE the allowlist, five ways ──`. One word.

---

#### F11. `|| echo 0` on a command substitution — the exact double-value hazard the file documents avoiding 200 lines earlier

**Severity:** Minor
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:686-694` vs `:493-501`
**Move:** #4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

At `:493-495` the file spends three lines on this hazard, in a comment `1d8ea67` deliberately
preserved while moving the code:

```
  # `grep -c` prints 0 AND exits 1 on no match, so `|| echo 0` would append a
  # SECOND zero — `attempts` becomes "0\n0", the -ge test errors, and bash
  # abandons the rest of this cell's loop body without running it.
```

The new void counter at `:686` uses the shape the comment forbids:

```
voided=$(python3 - "$OUT" <<'EOF' || echo 0
...
print(sum(1 for n in os.listdir(out)
          if os.path.isfile(os.path.join(out, n, "CONTAINMENT_FAILED"))))
EOF
)
if [ "${voided:-0}" -gt 0 ]; then
```

If the heredoc prints and *then* fails, `voided` is `"0\n0"` and `[ ... -gt 0 ]` errors under
`set -e`, exiting the sweep with status 2 — the code that means "SWEEP BUDGET EXCEEDED".
Reachability is low (`os.listdir` on a directory that exists by then rarely fails), so this is
Minor on impact; it is High-confidence as a **convention inconsistency**, and the convention is
one this file states in its own words.

**Recommendation:** `voided=$(python3 ... ) || voided=0`, matching the `|| rc=$?` guard the
same commit adopted in `egress_leg` for the same reason.

---

#### F12. F5 re-checked and standing: `ARTIFACT_SUFFIXES` vs `SUFFIXES`, held in agreement by a comment

**Severity:** Minor *(carried; not claimed fixed by these commits)*
**Location:** `scripts/crb-materialize.py:75`, `:277`; `scripts/crb-harvest-artifacts.py:42`, `:70`
**Move:** #2 (naming against the grain) / #7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `one definition, imported by both` used in `scripts/crb_common.py`, consumed at
`scripts/crb-subset-leaderboard.py` and `scripts/crb-pipeline-to-benchmark.py`. Its docstring
names the trigger for extraction verbatim: "a review-fix pass hand-copied them into a second
file, where they are held in agreement by a comment."

Unchanged at HEAD:

```
scripts/crb-harvest-artifacts.py:42:SUFFIXES = (".md", ".json")
scripts/crb-materialize.py:75:ARTIFACT_SUFFIXES = (".md", ".json")
```

Two names for one contract, plus the walk-exclusion predicate duplicated verbatim, in two
Python modules in the same directory where the import path is available. Rubric C6 carries it
as 🟢 Consider; the finding is unchanged and restated here per scope. Worth noting these
commits made the *sibling* half of this problem better — the `.baselines/` layout got exactly
the single-owner treatment (`baseline_paths`) that this pair still lacks — which is evidence
the fix is cheap and the pattern is understood.

**Recommendation:** Move `ARTIFACT_SUFFIXES` and the exclusion predicate into `crb_common.py`;
import in both. Keep the `ARTIFACT_` prefix — it names the domain, matching `crb_common`'s
style.

---

#### F13. F6 re-checked and standing: `EGRESS_SUBNET` is an invited override that takes effect on one side only — and the new `internal-net` leg does not help

**Severity:** Minor *(carried; not claimed fixed)*
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:110-114`, `:176`, `:196`; `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:16`; `test/crb-egress-config.bats:53`
**Move:** #3 (consumer contract) / #7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Unchanged at HEAD:

```
EGRESS_SUBNET="${EGRESS_SUBNET:-172.31.250.0/24}"
```
```
Allow 172.31.250.0/24
```

The scope brief asks whether the new `internal-net` leg changes this. It does not: the leg
asserts the create command contains `--internal`, and says nothing about whether `--subnet`
agrees with the value baked into the proxy image. An operator who overrides `EGRESS_SUBNET`
now gets `ok  network created --internal` immediately followed by `FAIL api-reachable:
api.anthropic.com unreachable through the proxy — every cell would fail` — a message pointing
at the API, the proxy image or DNS, never at the override they just set. If anything the new
leg makes the misdiagnosis slightly more confident, because the operator has just been told
the network is correct. `test/crb-egress-config.bats:53` still greps the runner for the
literal default, protecting the default and nothing else.

**Recommendation:** Unchanged from the prior round — either template the `Allow` line off
`$EGRESS_SUBNET` at build time, or delete the `${EGRESS_SUBNET:-...}` indirection and make it
a pinned constant like `EGRESS_NET`, with a comment saying it is spelled in two files. If
neither, add the subnet to the `internal-net` leg's assertion so the leg that reads the create
command checks both flags it carries.

---

#### F14. A9 re-checked: the void protocol got clearer at the edges and muddier in the middle

**Severity:** Informational
**Location:** `scripts/crb-audit-clone.sh:30-38`; `runs/review-arms/crb-pipeline/run-host.sh:355-356`, `:506`, `:637-660`, `:686-699`; `scripts/crb-subset-leaderboard.py:71`; `scripts/crb-pipeline-to-benchmark.py:242`
**Move:** #7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The scope brief asks whether `rm -f CONTAINMENT_FAILED` — a fifth interaction with the
protocol — clarified or muddied it. Both, in different places.

**Clearer.** F1/R2's fix removes the largest source of *false* entries: exit 2 and docker's
125/126/127 no longer write any of the encodings. And the two derived readers now share one
source of truth — `voided_cells` (`:355-356`) and the exit-6 count (`:691-693`) both key off
`os.path.isfile(.../CONTAINMENT_FAILED)`, so they cannot disagree with each other. Prior F10
noted three readers with no test; `test/crb-egress-config.bats:177` now at least greps for the
sentinel.

**Muddier.** The count of representations went from four to six: audit exit code, the sentinel
file, the `result.json` `subtype` rewrite, `run-meta.json`'s `voided_cells`, the sweep's exit
6, and now a *clear* operation. They are not co-maintained. Specifically:

- The rewrite is still best-effort — `python3 - "$dest/result.json" <<'EOF' || true` — so
  `subtype: "containment_failed"` can be absent while the sentinel is present, and
  `crb-cell-status.py` (which reads only `result.json`) structurally cannot see the sentinel.
- The clear at `:506` deletes the sentinel but not the `subtype` rewrite; they are re-synced
  only because a re-run overwrites `result.json` wholesale. That is an ordering coincidence,
  not an invariant, and nothing states it.
- The clear is per-cell and on one code path, while two readers are arm-wide — the mismatch
  F2 makes concrete.

The protocol still has no single function or file that owns "mark void" / "is void" / "clear
void", which is the move this repo already made twice in this diff's own commits
(`crb-egress-verdict.sh`, `baseline_paths`).

**Recommendation:** Out of scope to fix in a terminal pass. Record it as the carried coupling
item: three shell helpers (`mark_void`, `is_void`, `clear_void`) in `run-host.sh` and one
`crb_common.py` constant for the sentinel filename would collapse six encodings to one owner
and make F2 unrepresentable.

---

## What Looks Good

- **The `--snapshot` removal is complete and coherent.** Every consumer moved together: the
  argparse mode, the `--help` epilog, the module docstring Usage block, `verify_containment`'s
  and `snapshot_baseline`'s docstrings, both `RuntimeError` remediation strings, the harvest's
  "no baseline index" message, `run-host.sh`'s two operator messages, `docs/decisions/034`,
  `docs/working/crb-direction1-setup.md`, and a bats case asserting the mode is gone from
  *both* the CLI and the runner. Deleting a flag this cleanly across nine files is the
  hard version of this operation, and it closes F4 (`--force` no longer carries a second
  meaning; `--help`'s "rebuild existing clones" is now exactly true).
- **F1/R2 is genuinely closed, and the three-way branch is complete.** `audit_rc=0` +
  `|| audit_rc=$?` + `-gt 1` → exit 4 + `-eq 1` → void + implicit 0 → clean covers the whole
  integer range; docker's 125/126/127 land in the abort arm, as does the audit's own exit 2.
  The audit's header now names the caller's obligation, which makes the contract readable from
  the producer side.
- **F2 is closed correctly and honestly.** `scripts/crb-audit-clone.sh:30-38` now reads
  `2 = could not check (usage/no repo)` and then names the `git fsck` asymmetry as deliberate,
  with the reason (fail-closed) and where the distinction survives (the VOID trace text). That
  is better than silently changing the exit code, which `test/crb-audit-clone.bats:122` pins.
- **F3 is closed on both halves.** The index now gets atomic publish
  (`idx_part.replace(idx_path)`), a manifest hash, and a pre-cell gate — the tar's exact
  treatment. Four bats cases pin it, including the "manifest predates the pin" case, which is
  the state a half-upgraded arm is actually in.
- **F7 is closed by construction.** `baseline_paths()` is a single owner, `snapshot_baseline`
  derives its `.part` siblings from it rather than respelling, and the bats case greps
  `run-host.sh` to assert the layout is *not* restated there.
- **F9 and F12 are closed.** The audit header's `docker run` example now carries `-u node` and
  `--entrypoint bash` and matches `run-host.sh:634-637` verbatim in shape; the disk figure is
  `~13 GB` in both the setup doc and the CLI docstring.
- **`crb-egress-verdict.sh` is a well-formed member of the extracted-decider family** — argv
  positional, `0/1/2`, verdicts to stdout and usage to stderr (matching `crb-audit-clone.sh`
  and `crb-cell-status.py`), a `usage()` that lists the legs, and a test file whose cases are
  written as the mutations they must catch rather than as a restatement of the implementation.
  The `403 passes filter-blocks and FAILS no-direct-route` case is the sharpest thing in the
  diff: it pins that the two "refusal" legs must *not* share a predicate.
- **`PREFLIGHT_ONLY` is honest about its cost.** Both the runner's own output and the two docs
  say "one billed auth turn, not zero", which is the kind of claim this loop has repeatedly
  had to walk back and did not have to this time.
- **`egress_leg`'s `|| rc=$?` comment** documents the `set -euo pipefail` interaction that
  broke the obvious form, and the same commit applied that lesson to `mapfile`'s neighbours —
  though not, per F11, to the void counter.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Verdict script's exit 2 collapsed into "leg failed" by its only consumer | Inconsistent | `run-host.sh:216-234` | High |
| F2 | `exit 6` counts void markers from cells outside this sweep | Inconsistent | `run-host.sh:686-699` | High |
| F3 | Verdict rendered on an unvalidated (possibly empty) `<observed>` | Inconsistent | `crb-egress-verdict.sh:36-38` | High |
| F9 | `--baseline-paths` failure reported as "no baseline"; no status or count check | Inconsistent | `run-host.sh:444-455` | High |
| F4 | `<observed>` is polymorphic; `internal-net` cannot fail at runtime | Minor | `crb-egress-verdict.sh:79-88` | High |
| F5 | Six exit codes, no legend anywhere (F8 restated, larger) | Minor | `run-host.sh:68-73` | High |
| F6 | Five leg names, four vocabularies; HTTPS/HTTP pair shares no stem | Minor | `crb-egress-verdict.sh:29-33` | High |
| F7 | `baseline_index_sha256` required at restore, absent from the documented schema | Minor | `crb-materialize.py:43-46` | High |
| F8 | `--baseline-paths` missing from the docstring Usage block | Minor | `crb-materialize.py:34-41` | High |
| F10 | Preflight banner still says "three ways" | Minor | `run-host.sh:208` | High |
| F11 | `|| echo 0` double-value hazard the same file documents avoiding | Minor | `run-host.sh:686` | High |
| F12 | `ARTIFACT_SUFFIXES` vs `SUFFIXES` — carried, unchanged | Minor | `crb-materialize.py:75` | High |
| F13 | `EGRESS_SUBNET` one-sided override — carried; new leg does not help | Minor | `run-host.sh:114` | High |
| F14 | Void protocol: six encodings, no owner (A9 re-check) | Informational | `run-host.sh:355,506,645,693` | High |

---

## Overall Assessment

The two commits are a real improvement to the interface surface, not a paper one. The one
Breaking finding from the prior pass (the audit's tri-state exit read as contamination) is
closed with a complete three-way branch that puts docker's own 125/126/127 in the right arm;
the baseline contract's unprotected half is now pinned, atomic and gated before spend; the
`.baselines/` layout has a single owner; and `--snapshot` was deleted across nine files
without leaving a dangling reference — including in the tests, which now assert its absence
from both the CLI and the runner. Four of the eight prior findings claimed fixed are fixed,
and the two that were not claimed (F5, F6) are correctly still open rather than quietly
papered over. **No Breaking finding remains, and nothing here should block the sweep on
correctness grounds.**

What the pass did not do is generalize its own lesson. R2's defect was "a consumer collapsed
a three-valued contract into two". The fix introduces a new three-valued contract
(`crb-egress-verdict.sh` 0/1/2), documents it, writes a bats case whose comment says the
values "must be distinguishable" — and then consumes it as 0/nonzero (F1). The same shape
recurs in the new `--baseline-paths` consumption, where a tool crash is reported as a missing
baseline (F9), and in the unvalidated `<observed>` that lets a failed `docker run` produce the
sentence "the network is not internal" (F3). All three fail closed at $0, which is why none is
Breaking — but all three are the *legibility* failure this arm exists to avoid: an operator
reading a confident message about the wrong thing. They are cheap and local: roughly fifteen
lines across three call sites.

The remaining Minors are documentation-contract drift of the kind this loop has now produced
in every round (a banner that still says "three", a schema doc that did not follow its schema,
a mode missing from the Usage block, six exit codes with no legend). The exit-code legend is
the one to take before an unattended sweep — it is seven lines, and `$?` is the only thing an
overnight run communicates. Consumer impact is confined to operators and to CI wrappers; no
persisted artifact format changes incompatibly except `instances.json`, which now requires
`baseline_index_sha256` and says so loudly at the point of failure.

---

## Goal-Alignment Note
- Answered: yes — all prior findings re-checked, new surfaces reviewed, report saved
- Out of scope: `197eec6` (already reviewed, read as context only); non-API concerns (security exploitability, performance, test coverage) left to their own critics; the docker-shaped behaviour, which no static review can verify
- Escalate: F1, F3 and F9 are one pattern — "could not run" collapsed into a definite verdict — recurring inside the fix for that same pattern, for the third consecutive round. At a terminal pass with the loop cap reached, the orchestrator should decide whether the ~15-line fix lands before the sweep or the pattern is accepted and recorded in `docs/decisions/`. F5 (exit-code legend, 7 lines) is worth taking regardless. F2 will misreport `$?` on any subset re-run of an arm directory that has ever voided
