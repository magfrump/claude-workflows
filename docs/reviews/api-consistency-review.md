# API Consistency Review — feat/crb-direction1-harness, commits cf6e7c9..46a5f17

**Scope:** `git diff 59733d8..HEAD -- . ':!docs/reviews'` (cf6e7c9, 5bd0b09, 46a5f17)
**Date:** 2026-08-18
**Based on:** the k=3 code-fact-check from this pass (all five Incorrect findings were doc/comment
mechanism errors, closed in 46a5f17). Per that report, `crb-materialize.py`'s module docstring,
the `--verify`/`--reset` help text, and the `run-meta.json` field names were verified against
implemented behavior; this review does not re-verify them.
**Partial scope:** work outside these three commits is already committed and is context only.
Every "missing" claim below was checked against `git log main..HEAD` before being written.

Surfaces under review: the `crb-materialize.py` CLI (`--reset` added), the new
`scripts/crb-cell-status.py` CLI, the `crb-subset-leaderboard.py` CLI (`--run-meta` added),
`crb_common.py`'s exported constants (`RUN_META` added), and the `run-meta.json` JSON contract
(`requested_instances`, `missing_cells` added).

---

## Baseline Conventions

Surveyed: `scripts/crb-materialize.py`, `scripts/crb-pipeline-to-benchmark.py`,
`scripts/crb-subset-leaderboard.py`, `scripts/crb_common.py`, `scripts/claude_config_audit.py`,
`scripts/hermeticity-lint`, `scripts/review-arms.py`, `runs/review-arms/crb-pipeline/run-host.sh`.

1. **Every CLI in `scripts/` is argparse-driven**, with `description=__doc__` and
   `formatter_class=argparse.RawDescriptionHelpFormatter`
   (`crb-materialize.py:443-444`, `crb-subset-leaderboard.py:85-86`,
   `crb-pipeline-to-benchmark.py:183-184`, `review-arms.py:113-114`). Even the two
   predicate-shaped tools follow it: `claude_config_audit.py:195-197` and
   `hermeticity-lint:785`.
2. **Flags are kebab-case, long-form only**: `--per-repo`, `--dry-run`, `--all-prs`,
   `--tool-name`, `--no-seed`, `--run-meta`. No short flags anywhere in the `crb-*` family.
3. **Exit-status convention.** `sys.exit("message")` is the error form (prints to stderr,
   exit 1); argparse supplies exit 2 for usage errors for free. `claude_config_audit.py:237`
   is the repo's precedent for exit-status-as-verdict:
   `sys.exit(1 if sev["HIGH"] else 0)` — a *verdict* on 1, with usage errors landing on 2
   because argparse handles them. `run-host.sh:404` and `scripts/confine-tests.sh:68,150,173`
   likewise reserve exit 2 for "the harness itself could not proceed".
4. **stdout/stderr discipline.** Machine-consumable or reportable output goes to stdout
   (`crb-materialize.py:495` "containment ok", the leaderboard's table); diagnostics and
   failures go to stderr with a `!!` marker (`crb-materialize.py:471,483,492`;
   `crb-subset-leaderboard.py:52,80` `!! SUBSET ATTRITION:`).
5. **Path/identity constants are centralized in `crb_common.py`** precisely to stop
   hand-copying. Its own docstring (`crb_common.py:9-17`) states the rule: these values "are the
   identity of the work dir the injector writes and the leaderboard reads, and a review-fix pass
   hand-copied them into a second file, where they are held in agreement by a comment. So: one
   definition, imported by both."
6. **`run-meta.json` field naming.** The pre-existing keys are `arm`, `payload_ref`,
   `payload_commit`, `model`, `cc_version`, `cells`, `retried_cells`, `voided_cells`,
   `total_cost_usd` — snake_case, and the per-cell collections form a `<state>_cells` family.
7. **Module-level function names** are domain-qualified: `verify_containment`, `load_prs`,
   `resolve_base`, `comments_from_rubric`, `load_cell`, `normalize_section`. Bare-noun accessors
   also exist (`family`, `dir_mb`, `attrition`), so noun-shaped names are not themselves a
   deviation. `main()` is uniformly zero-arg and terminates via `sys.exit`.
8. **Docstring `Usage:` blocks.** Every `crb-*` CLI carries one
   (`crb-materialize.py:22`, `crb-subset-leaderboard.py:13`, `crb-pipeline-to-benchmark.py:32`),
   and it is kept in step with the flag set — `--reset` was added to materialize's block in
   this very diff.

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--reset SLUG ...` | CLI flag | `--verify SLUG ...`, `--slug`, `--all` | `scripts/crb-materialize.py:446-457` | Consistent — kebab-case, `nargs="+"`, same mutually-exclusive group, metavar matches `--verify` |
| `--run-meta PATH` | CLI flag | `--evaluations`, `--out`, `--judge`, `--all-prs` | `scripts/crb-subset-leaderboard.py:87-97` | Consistent shape; but absent from the docstring `Usage:` block every sibling maintains — F7 |
| `scripts/crb-cell-status.py` | script/CLI | `crb-materialize.py`, `crb-subset-leaderboard.py`, `crb-pipeline-to-benchmark.py`; predicate analog `claude_config_audit.py` | `scripts/crb-*.py`, `scripts/claude_config_audit.py` | Filename consistent (`crb-<noun-phrase>.py`); **invocation surface is not** — hand-rolled `argv` instead of argparse, and exit 1 means both "incomplete" and "you called me wrong" — F2 |
| `<result.json>` positional | CLI arg | `paths` positional on `claude_config_audit.py`; `--slug`/`--evaluations` on the `crb-*` family | `scripts/claude_config_audit.py:196`, `scripts/crb-materialize.py:449` | Acceptable — a positional path has precedent for predicate scripts; noted, not a finding |
| `RUN_META` | exported constant | `DEFAULT_OUT`, `MANIFEST`, `BENCH_DATA`, `DEFAULT_JUDGE`; and `DEFAULT_RUNS` | `scripts/crb_common.py:22-34`, `scripts/crb-pipeline-to-benchmark.py:63` | Naming consistent (SCREAMING_SNAKE, `Path`); composition is not — re-hardcodes the `runs/review-arms/crb-pipeline` string that `DEFAULT_RUNS` already holds — F6 |
| `NON_REVIEW`, `STUB_MAX_LEN`, `MIN_REVIEW_LEN` | module constants | `DEFAULT_TOOL`, `FINDING_SECTIONS`, `SECTION_ALIASES` | `scripts/crb_common.py:33-34`, `scripts/crb-pipeline-to-benchmark.py` | Consistent — SCREAMING_SNAKE tunables at module top with rationale comments |
| `requested_instances` | JSON field | `retried_cells`, `voided_cells`, `missing_cells`, `cells` | `runs/review-arms/crb-pipeline/run-host.sh:206-212` | Inconsistent — the only `*_instances` key in a file whose collections are all `*_cells` — F4 |
| `missing_cells` | JSON field | `retried_cells`, `voided_cells` | `runs/review-arms/crb-pipeline/run-host.sh:210-211` | Name consistent; the field itself is written and read by nobody — F3 |
| `attrition(urls, run_meta_path)` | function | `f1`, `verify_containment`, `load_cell` | `scripts/crb-subset-leaderboard.py:36`, `scripts/crb-materialize.py:168` | Consistent — bare-noun accessors have precedent (`family`, `dir_mb`) |
| `fetch_traces(dst)` | function | `verify_containment`, `classify_strays`, `scrub_object_store`, `reset_clone` | `scripts/crb-materialize.py:168-315` | Consistent by convention (noun accessors exist), but the name reads as the imperative "fetch the traces" in a module about git fetching — F15 |
| `classify_strays`, `scrub_object_store`, `reset_clone` | function | `verify_containment`, `resolve_base`, `load_prs` | `scripts/crb-materialize.py:91-168` | Consistent — verb_noun, domain-qualified |
| `status(d)` | function | `verify_containment`, `load_cell`, `comments_from_rubric`, `normalize_section` | `scripts/crb-materialize.py:168`, `scripts/crb-pipeline-to-benchmark.py:113-164` | Inconsistent — the only undomain-qualified module-level name in the family; `cell_status` would match the filename — F16 |
| `main(argv)` | function | `main()` in all four sibling CLIs | `scripts/crb-materialize.py:442`, `crb-subset-leaderboard.py:84`, `crb-pipeline-to-benchmark.py:182`, `review-arms.py:112` | Inconsistent — the only `main` taking argv and returning an int rather than terminating — F16 |
| `write_run_meta()`, `META_WRITTEN` | bash function/var | `SWEEP_BUDGET`, `MAX_ATTEMPTS`, `PAYLOAD_SRC` (vars); no prior function in this script | `runs/review-arms/crb-pipeline/run-host.sh:51-72` | New category — first function in the script; SCREAMING_SNAKE var + snake_case function matches shell norms elsewhere in `scripts/lib/*.sh` |

---

## Findings

#### F1. `--dry-run` is accepted by, and silently ignored in, the destructive `--reset` mode

**Severity:** Inconsistent
**Location:** `scripts/crb-materialize.py:460-499`, esp. `461-465` and `518`
**Move:** #9 (safety semantics) + #7 (asymmetry)
**Confidence:** High

`--dry-run` is a top-level (non-grouped) flag documented as `"print the selection, clone
nothing"`. `--reset` is the only *destructive-to-existing-state* mode in the script: it runs
`git checkout --force`, `reset --hard`, `update-ref -d`, `clean -qfdx`, `reflog expire
--expire=now`, and `gc --prune=now`. The verify/reset branch returns at line 499 and
`args.dry_run` is first consulted at line 518, so the flag is unreachable from that path.

```python
    ap.add_argument("--dry-run", action="store_true", help="print the selection, clone nothing")
    args = ap.parse_args()

    if args.verify or args.reset:
        slugs = args.verify or args.reset
        resetting = bool(args.reset)
```

and, 20 lines after that branch has already `return`ed:

```python
    if args.dry_run:
```

A cautious operator typing `crb-materialize.py --reset <slug> --dry-run` before an unattended
$50–2000 sweep gets the full destructive reset with no warning — the exact opposite of what the
flag advertises. `--force` and `--depth` are ignored on this path too, but they are inert rather
than misleading.

**Recommendation:** In the `args.verify or args.reset` branch, either honor `--dry-run` (print
what `reset_clone` would undo — `classify_strays` and `git status --porcelain` already compute
it, and `fetch_traces` is read-only) or `ap.error("--dry-run does not apply to --reset/--verify")`.
The second is a two-line change and closes the trap.

---

#### F2. `crb-cell-status.py` returns exit 1 for both "cell incomplete" and "you invoked me wrong", against the repo's own predicate precedent

**Severity:** Inconsistent
**Location:** `scripts/crb-cell-status.py:90-107`; consumer at `runs/review-arms/crb-pipeline/run-host.sh:236-240`
**Move:** #4 (error consistency) + #1 (baseline)
**Confidence:** High

Precedent: argparse-supplied usage exit 2 with verdict on exit 1, used in `scripts/claude_config_audit.py:195-237` and `scripts/hermeticity-lint:785`

The script's whole contract is its exit status. But three distinct conditions collapse onto 1:

```python
def main(argv):
    if len(argv) != 2:
        sys.exit("usage: crb-cell-status.py <result.json>")
    try:
        d = json.load(open(argv[1]))
    except Exception as e:
        print(f"unreadable result.json ({e})")
        return 1
```

`sys.exit("usage: ...")` exits 1 — indistinguishable from the "this cell is incomplete" verdict.
The repo's other exit-status predicate, `claude_config_audit.py`, avoids this for free by using
argparse: `sys.exit(1 if sev["HIGH"] else 0)` for the verdict, argparse's exit 2 for misuse. The
same file is also the reason `--help` misbehaves here: `crb-cell-status.py --help` is treated as a
filename, prints `unreadable result.json (...)` on **stdout**, and exits 1 — while every sibling
CLI prints help. A missing script (wrong `$ROOT`) likewise surfaces as python's exit 2, which the
consumer already treats as "incomplete".

The consumer is bash and cannot tell the difference:

```bash
    if cell_status=$(python3 "$ROOT/scripts/crb-cell-status.py" "$dest/result.json" 2>&1); then
      echo "=== $id — completed result exists, skipping (delete to re-run)"
```

An invocation bug therefore reads as "re-run this cell" and re-pays $10–40, per cell, silently.
That is the same false-incomplete direction the script's own docstring names as a cost risk.

**Recommendation:** Switch to argparse with a positional `result` (matching
`claude_config_audit.py:196`), which puts usage errors on exit 2 for free and gives `--help`. Then
have `run-host.sh` treat exit 2 (and anything >1) as a harness error rather than an incomplete
cell — `run-host.sh:404` already reserves 2 for exactly this meaning.

---

#### F3. `missing_cells` is written by the producer and read by no consumer; the leaderboard re-derives it instead

**Severity:** Inconsistent
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:210`; consumer `scripts/crb-subset-leaderboard.py:56-70`
**Move:** #3 (consumer contract) + #7 (asymmetry)
**Confidence:** High

The writer emits the field:

```python
           "requested_instances": req,
           "missing_cells": [s for s in req if s not in cells],
```

The only reader in the repo never opens it, and computes the same set independently:

```python
    cells = meta.get("cells") or {}
    requested = meta.get("requested_instances") or sorted(cells)
    voided = set(meta.get("voided_cells") or [])
...
        elif slug not in cells:
            why = "no cell produced (missing clone, or pre-run containment failure)"
```

Two definitions of the same set in two languages, with no test binding them. The test fixture
already demonstrates the drift is unpoliced — `test/crb-subset-attrition.bats:57` writes
`"missing_cells": []` while requesting slugs that have no cells, and the suite passes, because
nothing reads it. `voided_cells` and `retried_cells` do not have this problem: both are read
(`voided_cells` at leaderboard line 60) or are the only record of their state.

The consumer impact is the reverse of the usual: a later provenance reader (the docstring at
`crb_common.py:28-31` anticipates "anything reading provenance later") will reasonably trust
`missing_cells`, and it has no test keeping it truthful.

**Recommendation:** Pick one. Either delete `missing_cells` from the writer and let the reader
derive it (fewest moving parts), or have `attrition()` read `meta.get("missing_cells")` and drop
the `slug not in cells` re-derivation. Do not ship both.

---

#### F4. `requested_instances` breaks the `*_cells` naming family inside `run-meta.json`

**Severity:** Inconsistent
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:206-212`
**Move:** #2 (naming against the grain)
**Confidence:** High

Precedent: `<state>_cells` used in `runs/review-arms/crb-pipeline/run-host.sh:210-211` (`missing_cells`, `retried_cells`, `voided_cells`) and the `cells` map at line 208

Every other per-slug collection in this JSON object is `*_cells`, and the members of all of them
are the same kind of thing — a slug:

```python
json.dump({"arm": "crb-pipeline", "payload_ref": ref, "payload_commit": sha,
           "model": model, "cc_version": ccv, "cells": cells,
           "requested_instances": req,
           "missing_cells": [s for s in req if s not in cells],
           "retried_cells": retried, "voided_cells": voided,
```

`requested_instances` is the odd one out, and the mismatch is not accidental: it tracks the
*producer's* internal variable name (`INSTANCES` in `run-host.sh:78-84`) rather than the
vocabulary of the file it is writing. The reader then has to translate — `attrition()` binds it to
a variable called `requested` and describes its members as "attempted cell(s)" in the user-facing
warning at line 66. This is the fourth name for one entity across the harness ("instance",
"cell", "slug", "PR"); see F15.

**Recommendation:** Rename to `requested_cells` to match its three siblings, keeping
`meta.get("requested_instances")` as a fallback read for one release if any run-meta already
exists on disk. If the distinction between "requested" and "ran" is meant to be carried by the
noun, say so in a comment — right now nothing marks it as deliberate.

---

#### F5. The `run-meta.json` contract is declared nowhere it can be checked — only its path is shared

**Severity:** Inconsistent
**Location:** `scripts/crb_common.py:28-32`; writer `run-host.sh:160-220`; reader `scripts/crb-subset-leaderboard.py:40-70`
**Move:** #3 (consumer contract)
**Confidence:** High

`crb_common.py` exists specifically to stop this shape. Its docstring is explicit:

```python
It does not hold for these four values. They are not a refactor: they are the
identity of the work dir the injector writes and the leaderboard reads, and a
review-fix pass hand-copied them into a second file, where they are held in
agreement by a comment.
...
So: one definition, imported by both. No behaviour lives here.
```

`RUN_META` centralizes the *path*, but the eight key names that make the file useful are
hand-agreed between a python heredoc embedded in bash and a python reader that imports nothing
from it. The reader defends itself field-by-field with `.get(...) or <fallback>`:

```python
    cells = meta.get("cells") or {}
    requested = meta.get("requested_instances") or sorted(cells)
    voided = set(meta.get("voided_cells") or [])
```

Those fallbacks are what make a typo in the writer *silent*: misspell `requested_instances` and
`requested` quietly falls back to `sorted(cells)`, which is exactly the pre-`--run-meta` behavior
— the attrition check reports zero attrition and the harness's headline anti-bias control turns
itself off with no message. `test/crb-subset-attrition.bats` constructs its own run-meta by hand
(`:47-58`) rather than exercising the real writer, so no test would catch it.

**Recommendation:** Move the key names into `crb_common.py` as a small frozen tuple or dict of
required fields, have the reader assert them present (loudly, like the existing
`attrition NOT checked` line) rather than `.get(...) or`, and have `run-host.sh`'s heredoc import
`crb_common` for them — it already runs `python3` with the repo root available. Failing that, at
minimum add a bats case that runs `write_run_meta` for real and asserts the reader accepts its
output.

---

#### F6. `RUN_META` re-hardcodes the run-dir path that `DEFAULT_RUNS` already holds

**Severity:** Minor
**Location:** `scripts/crb_common.py:32`; `scripts/crb-pipeline-to-benchmark.py:63`; `runs/review-arms/crb-pipeline/run-host.sh:54`
**Move:** #1 (baseline) + #3
**Confidence:** High

Precedent: `DEFAULT_RUNS = WORKSPACE / "runs/review-arms/crb-pipeline"` at `scripts/crb-pipeline-to-benchmark.py:63`, and the one-definition rule in `scripts/crb_common.py:9-17`

```python
RUN_META = WORKSPACE / "runs/review-arms/crb-pipeline/run-meta.json"
```

The literal `runs/review-arms/crb-pipeline` now appears in three files: here, in the injector's
`DEFAULT_RUNS`, and as `OUT` in `run-host.sh:54`. The new constant was added to the shared module
(right instinct) but did not compose with the existing constant for the same directory — which
lives in a non-shared module. If the arm's output dir is ever repointed, two of the three move and
one does not, and the failure is a leaderboard that silently reports "attrition NOT checked".

**Recommendation:** Promote `DEFAULT_RUNS` into `crb_common.py`, define
`RUN_META = DEFAULT_RUNS / "run-meta.json"`, and import `DEFAULT_RUNS` in the injector. Three
lines, and it puts the new constant on the footing `crb_common.py`'s docstring describes.

---

#### F7. `--run-meta` is missing from the leaderboard's docstring `Usage:` block, which `--reset` was correctly added to in the same diff

**Severity:** Minor
**Location:** `scripts/crb-subset-leaderboard.py:13-19`
**Move:** #3 (documentation drift)
**Confidence:** High

`crb-materialize.py:22-29` had its `Usage:` block updated for the new mode in this diff:

```
  scripts/crb-materialize.py --verify grafana-PR79265   # re-check containment
  scripts/crb-materialize.py --reset  grafana-PR79265   # restore, then re-check
```

The leaderboard's was not:

```
Usage:
  scripts/crb-subset-leaderboard.py                       # subset = our tool's PRs
  scripts/crb-subset-leaderboard.py --tool mfc-pipeline-e8-redamber
  scripts/crb-subset-leaderboard.py --all-prs             # every PR in the evals file
  scripts/crb-subset-leaderboard.py --judge claude-sonnet-4-5-20250929
  scripts/crb-subset-leaderboard.py --markdown > table.md
```

Because `description=__doc__`, this block *is* the `--help` output's preamble, so the flag whose
absence turns off the attrition check is the one flag not shown by example. `docs/working/
crb-direction1-setup.md:261-270` documents the behavior but not the flag.

**Recommendation:** Add
`scripts/crb-subset-leaderboard.py --run-meta <dir>/run-meta.json  # attrition vs. a non-default sweep`
to the block.

---

#### F8. `crb-cell-status.py` sends failure reasons to stdout unmarked, against the `!!`-on-stderr convention its siblings use

**Severity:** Minor
**Location:** `scripts/crb-cell-status.py:94-105`
**Move:** #4 (error consistency)
**Confidence:** High

Precedent: `  !! <slug>: <reason>` on stderr at `scripts/crb-materialize.py:471,483,492` and `!! SUBSET ATTRITION:` at `scripts/crb-subset-leaderboard.py:52,80`

```python
        print(f"unreadable result.json ({e})")
...
    ok, reason = status(d)
    print(reason)
    return 0 if ok else 1
```

Both the success reason and the failure reason go to stdout, unprefixed. Sibling scripts put
failure diagnostics on stderr with a greppable `!!` marker. The current consumer merges the
streams (`2>&1` at `run-host.sh:233`) so nothing breaks today, but the sweep's own logs become
un-greppable for failures, and a second consumer that separates the streams gets the opposite of
what the family convention implies.

**Recommendation:** Print the complete reason to stdout (the consumer wants it in the log line
either way) but prefix failure reasons with `!!`, or emit failures on stderr and keep the
success line on stdout. Either matches the family; the current shape matches neither.

---

#### F9. `attrition()` computes a `checked` flag that its only caller discards

**Severity:** Minor
**Location:** `scripts/crb-subset-leaderboard.py:40-70, 169`
**Move:** #7 (asymmetry)
**Confidence:** High

The function's contract is a 2-tuple, `(lines, checked)`, and the second element is the answer to
"did the anti-bias control actually run?" — the single most important bit for a reader about to
quote a recall number. The caller throws it away:

```python
    att_lines, _checked = attrition(our_urls, Path(args.run_meta))
    for line in att_lines:
        print(line, file=sys.stderr)
```

The consequence is that a run with no run-meta at all still exits 0 and still prints a ranking
table. `docs/working/crb-direction1-setup.md:269-270` tells the reader to treat
`attrition NOT checked` as "fix that before believing the table" — but nothing in the interface
enforces it, and the warning is one line above a table that looks authoritative.

**Recommendation:** Either drop the second tuple element (honest: the function returns lines) or
use it — e.g. exit non-zero, or require `--allow-unchecked-attrition`, when `checked` is false
and `--markdown` was requested. The markdown path is the one whose output gets pasted into a
results doc.

---

#### F10. "no manifest entry" is reported when the entry exists but lacks `base`, a field only `--reset` needs

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:480-487`
**Move:** #4 (error consistency)
**Confidence:** High

```python
            rec = manifest.get(slug) or {}
            head, base = rec.get("head"), rec.get("base")
            if not head or (resetting and not base):
                print(f"  !! {slug}: no manifest entry — cannot pin the reviewed head, "
                      f"so containment is unverifiable. Re-materialize this slug.",
                      file=sys.stderr)
```

`--reset` added a second precondition (`base`) but reused the message written for the first. A
manifest record that has `head` but not `base` — the shape produced by any clone materialized
before `base` was recorded — reports "no manifest entry" and "cannot pin the reviewed head", both
of which are false. This is the same failure class as prior finding A14: an error message that
misdiagnoses its own cause. The remediation ("re-materialize this slug") happens to be right, so
the impact is operator confusion during a sweep, not a wrong action.

**Recommendation:** Split the branch and name the missing field, e.g.
`f"  !! {slug}: manifest entry has no {'head' if not head else 'base'} — ..."`.

---

#### F11. `--verify`/`--reset` have no `--all` analog, unlike every other selection in the script

**Severity:** Minor
**Location:** `scripts/crb-materialize.py:445-457`
**Move:** #7 (asymmetry)
**Confidence:** Medium

Materialization supports three selection shapes — `--all`, `--per-repo N`, `--slug ...` — and the
mutually-exclusive group means `--reset` cannot combine with any of them; it carries its own
operand list. So "reset every clone after an aborted sweep", the natural operator action when a
50-cell run is interrupted, has no expression short of shelling out the slug list from
`instances.json`. `run-host.sh` is unaffected (it resets per cell), so this is human-ergonomics
only — but it is the mode a human reaches for after a `SWEEP BUDGET EXCEEDED` halt.

**Recommendation:** Optional. Either accept a bare `--reset` (no operands, `nargs="*"`) meaning
"every slug in the manifest with a clone on disk", or document the one-liner in
`docs/working/crb-direction1-setup.md` next to the existing `--reset <slug>` example at line 29.

---

#### F12. `write_run_meta` swallows every failure with `|| true`

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:160-220`
**Move:** #3 (consumer contract)
**Confidence:** High

```bash
  python3 - "$OUT/run-meta.json" "$PAYLOAD_REF" "$PAYLOAD_SHA" "$MODEL" \
           "$CC_VERSION" "$OUT" "${INSTANCES[*]}" <<'EOF' || true
```

Moving the writer into an EXIT trap is the right fix for the reported bug (the budget halt used to
produce no provenance at all), and `|| true` inside a trap is defensible — a failing trap can mask
the real exit code. The cost is that the provenance file on which the leaderboard's attrition
check depends can now fail to be written with no signal at all. The mitigation is real and
deliberate: the reader's `attrition NOT checked` line (`crb-subset-leaderboard.py:51-55`) is
exactly the downstream alarm for this. Recording it here so the pairing is visible rather than
accidental.

Related and worth one line of thought: `"${INSTANCES[*]}"` is space-joined and re-split with
`.split()` in the heredoc. Every slug in `instances.json` matches `<repo>-PR<number>`, so this is
safe today; it is a latent constraint on slug format that nothing states.

**Recommendation:** No change required. If you want a signal, `|| echo "run-meta write FAILED" >&2`
instead of bare `|| true` keeps the trap safe and makes the failure visible.

---

#### F13. `--verify` is now unreferenced by any caller — but it should stay

**Severity:** Informational
**Location:** `scripts/crb-materialize.py:451-453`; docs at `docs/working/crb-direction1-setup.md:28`
**Move:** #3 (consumer contract)
**Confidence:** High

Directly answering the orchestrator's question. Grep confirms `--verify` has no remaining
programmatic consumer: `run-host.sh` now calls `--reset` at both the pre-run
(`run-host.sh:262`) and post-run (`:359`) sites, and the only other reference is the
setup doc's operator table. That is not dead code — it is the *read-only* form, and its help text
and docstring already say so:

```python
    at creation. run-host.sh calls this via --reset, which resets first and
    then asserts this; --verify is the read-only form for a human.
```

The surface is coherent because the two modes differ on a property an operator cares about before
a $50–2000 sweep: whether running the command destroys evidence. Investigating a suspected
contamination with `--reset` would erase what you are trying to look at. Keep it.

The one thing that would make the pair unmistakable is naming the safety property in the mode
list rather than only in the help strings — the `ap.error` at line 510-511 currently lists all
five modes flat:

```python
        ap.error("pick one of --list / --per-repo N / --slug ... / --all / "
                 "--verify SLUG ... / --reset SLUG ...")
```

**Recommendation:** Keep `--verify`. Consider annotating the two containment modes in that error
string (`--verify SLUG ... (read-only) / --reset SLUG ... (destructive)`), which is where a
confused operator lands.

---

#### F14. Four names for one entity across the harness: instance / cell / slug / PR

**Severity:** Informational
**Location:** `run-host.sh:78-84,206-213,433`; `crb-materialize.py:449-457`; `crb-subset-leaderboard.py:59-70`
**Move:** #2 (naming against the grain)
**Confidence:** High

Precedent: all four terms are pre-existing on this branch — `INSTANCES` at `runs/review-arms/crb-pipeline/run-host.sh:78`, `Cells: $ran ran` at `:433`, `--slug` at `scripts/crb-materialize.py:449`, "PRs" throughout `scripts/crb-subset-leaderboard.py`

This diff did not create the ambiguity, but `requested_instances` (F4) is the first place where
two of the four terms sit in the same JSON object, and the reader's user-facing string translates
between them mid-sentence: `f"{len(lost)} of {len(requested)} attempted cell(s)"` reads
`requested_instances`. Since the report this produces is meant to be pasted into a results doc and
read by someone deciding whether to spend $500–2000, the vocabulary is part of the interface.

**Recommendation:** No code change needed for the sweep. Pick one term per layer and state the
mapping once in `docs/working/crb-direction1-setup.md` — e.g. "a *slug* names a materialized
clone; a *cell* is one review of one slug; a *PR* is the upstream artifact a slug points at;
*instance* is the benchmark's word and is avoided elsewhere." F4's rename is the cheap first step.

---

#### F15. `fetch_traces()` reads as an imperative in a module about git fetching

**Severity:** Informational
**Location:** `scripts/crb-materialize.py:200-266`
**Move:** #2 (naming against the grain)
**Confidence:** Medium

Precedent: noun-shaped accessors `family` (`scripts/crb-materialize.py:107`), `dir_mb` (`:156`), `attrition` (`scripts/crb-subset-leaderboard.py:40`); verb-shaped siblings `verify_containment` (`:168`), `classify_strays` (`:267`), `scrub_object_store` (`:289`), `reset_clone` (`:315`)

The convention permits both shapes, so this is not a violation — but `fetch_traces` is
specifically ambiguous here, because the module's subject matter is `git fetch` and its siblings
in the same commit are all imperative. A reader scanning the four new functions sees three
commands and one that looks like a fourth command ("fetch the traces") when it is in fact a query
("traces of fetching"). The docstring resolves it immediately, so impact is a moment's
double-take.

**Recommendation:** Optional rename to `fetch_evidence`, `traces_of_fetch`, or `find_fetch_traces`.
Low priority; do not churn the call sites during the sweep window.

---

#### F16. `status(d)` and `main(argv)` in `crb-cell-status.py` deviate from the family's function conventions

**Severity:** Informational
**Location:** `scripts/crb-cell-status.py:72, 90, 106-107`
**Move:** #2 (naming against the grain)
**Confidence:** High

Precedent: domain-qualified module functions `verify_containment` (`scripts/crb-materialize.py:168`), `load_cell`/`comments_from_rubric` (`scripts/crb-pipeline-to-benchmark.py:113-164`); zero-arg `main()` terminating via `sys.exit` in `scripts/crb-materialize.py:442`, `crb-subset-leaderboard.py:84`, `crb-pipeline-to-benchmark.py:182`, `review-arms.py:112`

```python
def status(d):
    """(complete: bool, reason: str)"""
...
def main(argv):
...
if __name__ == "__main__":
    sys.exit(main(sys.argv))
```

`status` is the only unqualified module-level name in the `crb-*` family; if anything ever does
`from crb_cell_status import status` (the file's own docstring frames it as an extracted, testable
predicate, so import is the intended use), the name carries no domain. `main(argv)` returning an
int is a fine pattern on its own but is the only one of five `main`s in `scripts/` shaped that
way. Neither costs anything today.

**Recommendation:** Rename `status` → `cell_status` (matches the filename and the bash variable
`cell_status` at `run-host.sh:231`). Leave `main(argv)` alone unless F2's argparse change is made,
in which case fold it into the family's zero-arg shape at the same time.

---

## What Looks Good

- **`--reset` is a textbook-consistent flag addition.** Kebab-case, `nargs="+"`, same `metavar="SLUG"`
  as `--verify`, placed in the existing mutually-exclusive group, added to the docstring `Usage:`
  block *and* to the `ap.error` mode list at `crb-materialize.py:510-511` (the `ap.error` mode list). Nothing about it
  requires a consumer to learn a new convention.
- **The mode-dispatch refactor is minimal and safe.** `slugs = args.verify or args.reset` +
  `resetting = bool(args.reset)` works precisely because the mutually-exclusive group makes both
  being set impossible — the two-line implementation is correct rather than lucky.
- **`RUN_META` was put in `crb_common.py` rather than hand-copied into the leaderboard.** That is
  the right instinct and the right file; F6 is about composing with `DEFAULT_RUNS`, not about the
  placement.
- **Extracting the resume predicate into a file with fixtures is a real interface improvement.**
  The predicate used to be an inline `python3 -c` heredoc in bash with no test surface; it is now a
  named, importable, 15-case-tested contract (`test/crb-cell-status.bats`). Capturing its reason
  string and putting it in the re-run log line (`run-host.sh:251`) turns an opaque retry into a
  diagnosable one.
- **The attrition warning is repeated into the markdown body, not just stderr.** The reasoning at
  `crb-subset-leaderboard.py:165-168` — "the markdown is what gets pasted into a results doc, and a
  caveat that only ever existed on a terminal is a caveat that will not survive to the place the
  number is quoted" — is exactly right, and applying the same treatment to the pre-existing skew
  warning in the same change is good consistency work.
- **The run-meta EXIT trap is a genuine contract fix.** Provenance now exists on the budget halt,
  on Ctrl-C, and on a docker failure — the three paths where a spend decision most needs it. The
  `META_WRITTEN` guard makes it idempotent against the explicit call at line 432.
- **Backward compatibility of the JSON contract is clean.** `requested_instances` and
  `missing_cells` are additive, and the reader falls back (`or sorted(cells)`) so an old run-meta
  still ranks. No version bump needed; nothing was removed or retyped. (The fallback's silence is
  F5's concern, not a compatibility one.)

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--dry-run` accepted and silently ignored by the destructive `--reset` mode | Inconsistent | `scripts/crb-materialize.py:460-499` | High |
| 2 | `crb-cell-status.py` exit 1 means both "incomplete" and "misinvoked"; `--help` is read as a path | Inconsistent | `scripts/crb-cell-status.py:90-107` | High |
| 3 | `missing_cells` written by nobody's reader; leaderboard re-derives it | Inconsistent | `run-host.sh:210`, `crb-subset-leaderboard.py:56-70` | High |
| 4 | `requested_instances` breaks the `*_cells` family in `run-meta.json` | Inconsistent | `run-host.sh:206-213` | High |
| 5 | `run-meta.json` key contract declared nowhere checkable; reader's `.get(... ) or` hides typos | Inconsistent | `crb_common.py:28-32`, `crb-subset-leaderboard.py:56-60` | High |
| 6 | `RUN_META` re-hardcodes the path `DEFAULT_RUNS` already holds | Minor | `crb_common.py:32`, `crb-pipeline-to-benchmark.py:63` | High |
| 7 | `--run-meta` missing from the leaderboard's `Usage:` docstring | Minor | `crb-subset-leaderboard.py:13-19` | High |
| 8 | Failure reasons on stdout, unmarked, against the `!!`-on-stderr convention | Minor | `scripts/crb-cell-status.py:94-105` | High |
| 9 | `attrition()`'s `checked` flag computed and discarded | Minor | `crb-subset-leaderboard.py:40-70,169` | High |
| 10 | "no manifest entry" reported when only `base` is missing | Minor | `crb-materialize.py:480-487` | High |
| 11 | `--verify`/`--reset` have no `--all` analog | Minor | `crb-materialize.py:445-457` | Medium |
| 12 | `write_run_meta` swallows all failures with `\|\| true` | Informational | `run-host.sh:160-220` | High |
| 13 | `--verify` has no programmatic caller — keep it anyway (read-only form) | Informational | `crb-materialize.py:451-453` | High |
| 14 | Four names for one entity: instance / cell / slug / PR | Informational | harness-wide | High |
| 15 | `fetch_traces()` reads as an imperative in a fetch-centric module | Informational | `crb-materialize.py:200-266` | Medium |
| 16 | `status(d)` unqualified; `main(argv)` unlike the family's four other `main`s | Informational | `scripts/crb-cell-status.py:72,90` | High |

---

## Overall Assessment

The diff is broadly consistent with the conventions this harness has already established, and in
two places it actively strengthens them: `RUN_META` went into the shared module rather than being
hand-copied, and `--reset` was added with the same care (metavar, group membership, docstring
`Usage:` line, `ap.error` mode list) that the existing flags show. The author clearly read the
surrounding code. There is no breaking change here: the `run-meta.json` additions are additive and
the reader tolerates their absence, so an old sweep's provenance still ranks.

The pattern in the amber findings is narrower than "didn't survey the conventions" — it is that the
**new interfaces are missing their failure-mode consistency**, specifically the ability to tell
"the thing under test failed" apart from "the check itself could not run". F2 (exit 1 means both
incomplete and misinvoked), F5 (a mistyped key silently disables the attrition control), F9 (the
`checked` flag discarded) and F1 (`--dry-run` silently inert on the destructive mode) are the same
shape four times, and it is the shape this branch's own history keeps producing — A14 was an error
message that misdiagnosed its cause, and `crb-cell-status.py`'s docstring names false-incomplete as
a $10–40-per-cell cost. Each of the four is a small, local, in-place fix; none needs a redesign.

For a sweep about to spend $50–2000 on 50 third-party repos, I would gate on F1, F2, and F5. F1 is
two lines and closes a trap where the safety flag does the unsafe thing. F2 is an argparse swap that
stops an invocation bug from reading as "re-pay for this cell". F5 is the one whose failure is
invisible: if a key name drifts, the attrition check — the harness's headline defense against
reporting a recall number biased in its own favour — turns itself off and prints a clean table. F3
and F4 should be resolved together and are cheap. Everything from F6 down is fine to carry.

## Goal-Alignment Note
- Answered: yes — all four judgement questions addressed (F13 on `--verify`'s place; F3/F4/F5 on the run-meta contract; F2/F8/F16 on `crb-cell-status.py`'s shape; F4/F7/F14 plus the audit table on cross-script naming)
- Out of scope: the `docs/human-author/LLM Code Review.md` addition and the `docs/working/crb-direction1-setup.md` prose edits (no consumer-facing interface); the three new bats files were read for what they assert about the contracts but not reviewed as a test surface; the containment/security properties of `reset_clone`/`fetch_traces` (security-reviewer's lane — I only assessed their names and call signatures)
- Escalate: F5 is the only finding whose failure mode is silent and whose blast radius is the headline number the sweep exists to produce — if only one thing is fixed before spending, make it that one. Separately, `test/crb-subset-attrition.bats:47-58` hand-builds its run-meta fixture rather than invoking `run-host.sh`'s `write_run_meta`, so no test binds the writer to the reader; that is a test-strategy gap the orchestrator may want routed to `test-strategy` rather than fixed here.
