# Code Fact-Check Report

**Repository:** `/workspace` (claude-workflows)
**Commit:** cf6e7c9
**Scope:** `git diff HEAD~1..HEAD` on `feat/crb-direction1-harness` — 9 files (docs/working/crb-direction1-setup.md, runs/review-arms/crb-pipeline/run-host.sh, scripts/crb-cell-status.py, scripts/crb-materialize.py, scripts/crb-subset-leaderboard.py, scripts/crb_common.py, test/crb-cell-status.bats, test/crb-containment-reset.bats, test/crb-subset-attrition.bats)
**Checked:** 2026-08-18
**Total claims checked:** 30
**Summary:** 24 verified, 2 mostly accurate, 2 stale, 2 incorrect, 0 unverifiable

> **Partial scope.** This report covers commit `cf6e7c9` only. Sibling commits on
> `feat/crb-direction1-harness` are context, not subject. No finding below is a
> "this work is missing" claim.

> **Prior-run hallucination patterns.** `docs/reviews/hallucination-patterns.md`
> logs one pattern (`total_golden` 11 vs 13 claimed in CRB evaluations.json but no
> PR has more than 9 goldens). Every quantitative claim below was compared against
> it; the recurring shape — *a doc quoting specific measured values out of a
> checked-in artifact without re-measuring* — recurs in Claims 14 and 17 of this
> report, both of which quote corpus statistics that the corpus does not support.

---

## Claim 1: "The clone is reset with `crb-materialize.py --reset <slug>` after harvesting" / "Containment is re-asserted before and after every cell via `crb-materialize.py --reset <slug>`"

**Location:** `docs/working/crb-direction1-setup.md:89`, `docs/working/crb-direction1-setup.md:95`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which subcommand run-host.sh invokes at the two per-cell containment points; does not establish that the reset succeeds against a real materialized clone (no clones exist under `external/crb-eval` in this sandbox).

The runner invokes `--reset` at both points. Pre-run:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:262-264
  python3 "$ROOT/scripts/crb-materialize.py" --reset "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2
    skipped_bad=$((skipped_bad+1)); continue; }
```

Post-run, after artifact harvesting:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:359-361
  if ! python3 "$ROOT/scripts/crb-materialize.py" --reset "$id"; then
    echo "$id: POST-RUN containment check FAILED — voiding this cell" >&2
    : > "$dest/CONTAINMENT_FAILED"
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:262-264`, `runs/review-arms/crb-pipeline/run-host.sh:359-361`, `docs/working/crb-direction1-setup.md:89-96`

---

## Claim 2: "`--reset` … it is **reset**, along with staged edits, created branches/tags, and a deleted `main`. A surviving **remote**, or any commit reachable outside the reviewed head's ancestry, still **voids**."

**Location:** `docs/working/crb-direction1-setup.md:104-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the five reset cases and the two void cases as exercised by the checked-in bats fixtures; does not establish behavior against a shallow real clone, nor that the void set is *complete* (see Claim 21b).

`reset_clone()` performs each named restoration:

```python
# scripts/crb-materialize.py:244-253
    sh(["git", "checkout", "--force", "--quiet", "-B", "review", head], cwd=dst)
    sh(["git", "reset", "--hard", "--quiet", head], cwd=dst)
    sh(["git", "branch", "--quiet", "-f", "main", base], cwd=dst)
    ...
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    sh(["git", "clean", "-qfdx"], cwd=dst)
```

and voids on the two named contamination shapes:

```python
# scripts/crb-materialize.py:231-239
    remotes = sh(["git", "remote"], cwd=dst)
    if remotes:
        raise RuntimeError(f"{slug}: remote(s) present ({remotes.split()!r}) — "
                           "answer-key containment is broken")
    strays, foreign = classify_strays(dst, head)
    if foreign:
        raise RuntimeError(
            f"{slug}: {len(foreign)} commit(s) reachable outside the reviewed head "
```

All 14 cases in `test/crb-containment-reset.bats` pass, including the two void cases (`ok 24 a re-added remote still VOIDS the cell`, `ok 25 a commit outside the reviewed ancestry still VOIDS the cell`).

Command: `bats test/crb-cell-status.bats test/crb-containment-reset.bats test/crb-subset-attrition.bats`; cwd `/workspace`; exit code 0; 2026-08-18T19:44:22-07:00; 32/32 ok.

**Evidence:** `scripts/crb-materialize.py:231-259`, `test/crb-containment-reset.bats:63-178`, `docs/reviews/execution-logs/r3-bats-crb.txt`

---

## Claim 3: "The old reset (`git checkout -- . && git clean -qfdx`) restored tracked files *from the index*, so it undid neither a commit nor a `git add`: a commit voided the cell and left the clone failing its pre-run check on every later attempt"

**Location:** `docs/working/crb-direction1-setup.md:110-114` (same claim at `runs/review-arms/crb-pipeline/run-host.sh:345-353`, `scripts/crb-materialize.py:226-229`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the parent commit's reset sequence did and the consequence for the pre-run check; does not re-derive git's documented `checkout -- <path>` semantics by execution.

The parent commit's reset was exactly the quoted pair:

```bash
# git show HEAD~1:runs/review-arms/crb-pipeline/run-host.sh (pre-cf6e7c9)
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfdx 2>/dev/null || true
```

`git checkout -- <paths>` with no tree-ish argument copies from the index, so a `git add` is preserved rather than undone, and neither form touches refs (paraphrased — no quote available because the claim is about documented git semantics, not about a snippet in this repo).

The "failing forever" half follows from the check's own stray rule: with `review` advanced past the manifest head by an agent commit, `rev-list --all --not head` is non-empty and the check raises:

```python
# scripts/crb-materialize.py:184-187
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
    stray_n = len([l for l in stray.splitlines() if l])
    if stray_n:
        raise RuntimeError(f"{slug}: {stray_n} stray commit(s) reachable outside the reviewed head")
```

`test/crb-containment-reset.bats:81-89` ("the clone still verifies on the NEXT cell after an agent commit") pins the fix for that case and passes.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:345-353`, `scripts/crb-materialize.py:184-187`, `test/crb-containment-reset.bats:81-89`

---

## Claim 4: "The non-review signatures apply **only below 1000 chars** … two pilot instances are auth-domain (`keycloak-PR36880`, `cal_com-PR11059`)"

**Location:** `docs/working/crb-direction1-setup.md:122-126`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the length gate on `NON_REVIEW` and the auth-domain characterization of the two named manifest entries; does not establish that no *other* pilot instance touches auth code.

The substring list is consulted only inside the sub-`STUB_MAX_LEN` band:

```python
# scripts/crb-cell-status.py:64-70
    if len(r) < MIN_REVIEW_LEN:
        return False, f"body is {len(r)} chars, under the {MIN_REVIEW_LEN}-char floor"
    if len(r) < STUB_MAX_LEN:
        low = r.lower()
        hit = next((s for s in NON_REVIEW if s in low), None)
```

with `STUB_MAX_LEN = 1000` (`scripts/crb-cell-status.py:46`).

The manifest holds exactly 5 instances, of which the two named carry auth-domain titles (paraphrased — no quote available because the values were read out of a 5-record JSON manifest rather than a source line): `keycloak-PR36880` → *"Add Client resource type and scopes to authorization schema"*, `cal_com-PR11059` → *"OAuth credential sync and app integration enhancements"*.

**Evidence:** `scripts/crb-cell-status.py:40-53`, `scripts/crb-cell-status.py:64-70`, `runs/review-arms/crb/instances.json`

---

## Claim 5: "8 real cells in this repo are genuine successes with `num_turns == 0` and 3–7 KB of review text"

**Location:** `docs/working/crb-direction1-setup.md:127-129`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count, the `num_turns` value, and the stated size band for the eight `e5-cc-builtin` cells; does not affect the predicate, which uses a 200-char floor well below either bound.

There are exactly 8 `e5-cc-builtin` cells, all with `num_turns == 0` and `is_error` false, but their bodies span **2733–7121 chars (2.7–7.1 KB)**, not 3–7 KB — `mfc-postfix` is 2733 chars (paraphrased — no quote available because the figures were computed by iterating the 32 checked-in `result.json` artifacts, which are data files with no quotable comment line). The precise version is "2.7–7 KB". Same wording appears at `scripts/crb-cell-status.py:20-21` (Claim 14).

**Evidence:** `runs/review-arms/e5-cc-builtin/*/result.json`, `docs/working/crb-direction1-setup.md:127-129`

---

## Claim 6: "`run-meta.json` is written from an `EXIT` trap, so the budget halt, a `Ctrl-C`, and a docker failure all still leave the provenance file"

**Location:** `docs/working/crb-direction1-setup.md:143-146`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three named termination paths for a shell that has reached the `trap` at line 220; does not establish behavior for SIGKILL, for a failure before line 220 (where no cell has run and no meta is expected), or for a host crash.

The handler is installed as an `EXIT` trap before the loop:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:219-220
# Replaces the payload-only trap set above: both jobs, one handler.
trap 'write_run_meta; rm -rf "$PAYLOAD_SRC"' EXIT
```

- **Budget halt**: the gate exits from inside the loop, which fires the EXIT trap: `python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }` (`runs/review-arms/crb-pipeline/run-host.sh:404`).
- **Ctrl-C**: executed. A `set -euo pipefail` script with only an `EXIT` trap, sent SIGINT while sleeping, printed `EXIT TRAP RAN`.
- **Docker failure**: the `docker run` is guarded and does not terminate the shell at all — `> "$dest/transcript.jsonl" 2> "$dest/stderr.log" || { echo "$id: claude exited non-zero — see $dest/stderr.log" >&2; }` (`runs/review-arms/crb-pipeline/run-host.sh:286-287`) — so the sweep continues to the normal `write_run_meta` at line 432.

Command: `bash sigint.sh & kill -INT $!` (exp1 in the log); cwd `$TMPDIR/r3exp`; exit code 0; 2026-08-18T19:46:13-07:00.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:219-220`, `runs/review-arms/crb-pipeline/run-host.sh:286-287`, `runs/review-arms/crb-pipeline/run-host.sh:404`, `runs/review-arms/crb-pipeline/run-host.sh:432`, `docs/reviews/execution-logs/r3-bash-git-semantics.txt`

---

## Claim 7: "**On `--all`, expect to hit it** — the 50-PR estimate is $500–2000"

**Location:** `docs/working/crb-direction1-setup.md:142-143`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the internal consistency of the ceiling against the doc's own cost table; does not validate the cost estimate itself against real sweep spend.

The default ceiling is `SWEEP_BUDGET="${SWEEP_BUDGET:-250.00}"` (`runs/review-arms/crb-pipeline/run-host.sh:68`), and the doc's own cost table gives `| All 50 | **~$500–2000** | do not commit to this before a pilot |` (`docs/working/crb-direction1-setup.md:247`). $250 < $500, so an `--all` run halts. The parallel comment inside the script — "the default ceiling (which sits under the setup doc's own $500-2000 estimate)" (`runs/review-arms/crb-pipeline/run-host.sh:155-156`) — is consistent with this, as is the separate header claim that the default sits *above* the $50–200 pilot estimate (`docs/working/crb-direction1-setup.md:246`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:62-68`, `docs/working/crb-direction1-setup.md:246-247`

---

## Claim 8: "The script now cross-checks the judged subset against `run-meta.json`'s `requested_instances`, names every missing cell with its reason, and repeats the warning inside `--markdown` … If it prints `attrition NOT checked`, the run-meta was not found"

**Location:** `docs/working/crb-direction1-setup.md:230-239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cross-check source field, the per-cell reason strings, the markdown duplication, and the missing-run-meta message; does not establish that the reason assigned to a given cell is the *true* cause of its loss (the reasons are inferred from run-meta fields, not from cell logs).

```python
# scripts/crb-subset-leaderboard.py:56-58
    cells = meta.get("cells") or {}
    requested = meta.get("requested_instances") or sorted(cells)
    voided = set(meta.get("voided_cells") or [])
```

Markdown duplication:

```python
# scripts/crb-subset-leaderboard.py:175-177
        # Same reasoning for the skew warning: it belongs where the table is read.
        for note in ([warn] if warn else []) + ([("\n".join(att_lines))] if att_lines else []):
            print("> " + note.replace("\n", "\n> ") + "\n")
```

The missing-run-meta branch returns `f"!! subset attrition NOT checked: no run-meta.json at {run_meta_path} …"` (`scripts/crb-subset-leaderboard.py:52-54`). All six cases in `test/crb-subset-attrition.bats` pass (tests 27–32 in the captured run), including `attrition appears in the markdown body, not only on stderr` and `a missing run-meta says attrition was NOT checked rather than staying silent`.

Command: `bats test/crb-cell-status.bats test/crb-containment-reset.bats test/crb-subset-attrition.bats`; cwd `/workspace`; exit 0; 2026-08-18T19:44:22-07:00.

**Evidence:** `scripts/crb-subset-leaderboard.py:40-80`, `scripts/crb-subset-leaderboard.py:165-177`, `test/crb-subset-attrition.bats:68-117`, `docs/reviews/execution-logs/r3-bats-crb.txt`

---

## Claim 9: "the SWEEP_BUDGET gate below exits 2 from INSIDE the loop, so the halt … wrote no run-meta.json at all"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:152-158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pre-cf6e7c9 control flow that produced the missing provenance file; does not re-run the parent commit's script.

The gate is inside the `for id in "${INSTANCES[@]}"` body and exits:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:404
  python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
```

and in the parent commit the meta writer was a bare inline block placed *after* `done`, with no trap (paraphrased — no quote available because the claim is about the position of a ~40-line block relative to the loop terminator in the deleted version; the deletion is visible in `git diff HEAD~1..HEAD` at the `-# Sweep-level provenance` hunk).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:152-158`, `runs/review-arms/crb-pipeline/run-host.sh:404`, `git diff HEAD~1..HEAD -- runs/review-arms/crb-pipeline/run-host.sh`

---

## Claim 10: "Replaces the payload-only trap set above: both jobs, one handler."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers trap replacement and `PAYLOAD_SRC` cleanup on the exit paths that exist in this script; does not cover SIGKILL or an `exec`-replaced shell.

A second `trap … EXIT` replaces the first rather than appending — executed: `bash -c 'trap "echo FIRST" EXIT; trap "echo SECOND" EXIT; echo body'` printed `body` then `SECOND` only (exp3 in the log; cwd `$TMPDIR/r3exp`; exit 0; 2026-08-18T19:46:13-07:00).

`PAYLOAD_SRC` cleanup survives on every path because both traps remove it — the first from creation (`trap 'rm -rf "$PAYLOAD_SRC"' EXIT`, `runs/review-arms/crb-pipeline/run-host.sh:97`) until line 220, covering the payload check `exit 1` (line 103), the `DRY_RUN` `exit 0` (line 108), the missing-key `exit 1` (line 109) and the preflight `exit 1` (line 132); the replacement (line 220) removes it thereafter. The replacement's first command cannot abort the handler under `errexit`, since `write_run_meta` ends in `python3 … || true` or an early `return 0`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:160-164
write_run_meta() {
  if [ -n "$META_WRITTEN" ]; then return 0; fi
  META_WRITTEN=1
  python3 - "$OUT/run-meta.json" "$PAYLOAD_REF" "$PAYLOAD_SHA" "$MODEL" \
           "$CC_VERSION" "$OUT" "${INSTANCES[*]}" <<'EOF' || true
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:96-109`, `runs/review-arms/crb-pipeline/run-host.sh:160-164`, `runs/review-arms/crb-pipeline/run-host.sh:219-220`, `docs/reviews/execution-logs/r3-bash-git-semantics.txt`

---

## Claim 11: "It prints its reason either way; capture it so the re-run message says WHY."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:227-230`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the capture of the predicate's reason line into the re-run log message; does not cover the case where `result.json` is absent (then `cell_status` stays empty and the message ends with a bare colon, which is unreachable because the enclosing branch requires a non-empty `result.json`).

`crb-cell-status.py` prints on both paths — `print(reason); return 0 if ok else 1` (`scripts/crb-cell-status.py:86-87`) — and the runner captures stdout+stderr regardless of exit status, then uses it:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:231-236
  cell_status=""
  if [ -s "$dest/result.json" ]; then
    if cell_status=$(python3 "$ROOT/scripts/crb-cell-status.py" "$dest/result.json" 2>&1); then
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:251
    echo "=== $id — prior result was incomplete/errored, re-running (attempt $((attempts+1))): $cell_status"
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:227-251`, `scripts/crb-cell-status.py:85-87`

---

## Claim 12: "Checked BEFORE the payload copy below, so a skipped cell leaks no temp dir."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:259`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering of the pre-run containment call relative to the per-instance `mktemp -d`; does not cover the payload `mktemp` at line 96 or the preflight `mktemp` at line 123.

The containment call precedes the per-instance temp dir, and its failure path `continue`s before it:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:262-268
  python3 "$ROOT/scripts/crb-materialize.py" --reset "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2
    skipped_bad=$((skipped_bad+1)); continue; }
  ...
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:255-268`

---

## Claim 13: "Measured against the 32 result.json files under runs/review-arms/ … e7-fable-3x/mfc-hygiene/rep1: subtype=error_max_budget_usd, $15.24"

**Location:** `scripts/crb-cell-status.py:14-19`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the corpus size, the named cell's subtype and cost, and the existence of the whole-corpus assertion in the bats suite; does not establish that a turns-only predicate historically banked that cell (a claim about a past predicate version, not checked here).

Enumerating `runs/review-arms/**/result.json` yields exactly 32 files, and `runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json` carries `is_error=True subtype='error_max_budget_usd' turns=1 len=0 cost=15.240262` (paraphrased — no quote available because these are data files, read by iterating and printing fields rather than by quoting a source line). $15.240262 rounds to $15.24.

The bats suite does assert the verdict on all of them:

```bash
# test/crb-cell-status.bats:157-158
for p in sorted(glob.glob(os.path.join(root, "runs/review-arms/**/result.json"),
                          recursive=True)):
```

Command: `bats test/crb-cell-status.bats …`; cwd `/workspace`; exit 0; 2026-08-18T19:44:22-07:00 — `ok 14 verdicts on all checked-in result.json files are unchanged`.

**Evidence:** `scripts/crb-cell-status.py:14-25`, `test/crb-cell-status.bats:150-176`, `docs/reviews/execution-logs/r3-bats-crb.txt`

---

## Claim 14: "8 e5-cc-builtin cells are genuine successes with num_turns == 0 and 3-7 KB of real review text"

**Location:** `scripts/crb-cell-status.py:20-21`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count, the `num_turns` value and the size band; does not change the predicate's behavior, which never consults these numbers.

Eight `e5-cc-builtin` cells exist, all `is_error=False subtype='success' turns=0`, with body lengths 7121, 4918, 4651, 4381, 3758, 3720, 3435 and **2733** chars (paraphrased — no quote available because the figures come from iterating the 32 checked-in `result.json` data files). The lower bound is 2.7 KB, not 3 KB; the precise version is "2.7–7 KB". Compare the logged hallucination pattern *"`total_golden` 11 vs 13 claimed … but no PR has more than 9 goldens"* — same shape (a quoted corpus statistic that re-measurement does not reproduce), though here the miss is a rounding of one endpoint rather than a fabricated value.

**Evidence:** `runs/review-arms/e5-cc-builtin/*/result.json`, `scripts/crb-cell-status.py:20-21`

---

## Claim 15: "2 e7 cells report subtype=success, is_error=false, num_turns=0 with a 51-56 char body"

**Location:** `scripts/crb-cell-status.py:22-23`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and the four stated fields for the two stub cells; does not verify that the bodies' text is literally "You've hit your weekly limit".

Exactly two cells in the corpus match: `e7-fable-3x/mfc-postfix/rep2` (`is_error=False subtype='success' turns=0 len=56 cost=0`) and `e7-fable-3x/mfc-postfix/rep3` (`… len=51 cost=0`) (paraphrased — no quote available because the values were read out of `result.json` data files). No other cell in the corpus has a body under 1208 chars.

**Evidence:** `runs/review-arms/e7-fable-3x/mfc-postfix/rep2/result.json`, `runs/review-arms/e7-fable-3x/mfc-postfix/rep3/result.json`

---

## Claim 16: "the two in-repo examples are 51 and 56 characters … The 32-file corpus that validated this predicate contains no auth-domain reviews"

**Location:** `scripts/crb-cell-status.py:31-39`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the stub lengths (exact) and the absence of auth-domain instances in the corpus (inferred from instance naming, not from reading all 32 review bodies).

The 51/56-char figures reproduce exactly (see Claim 15). The corpus's eight instance names — `mfc-corpus`, `mfc-csp`, `mfc-deploy`, `mfc-fscompat`, `mfc-hygiene`, `mfc-lean`, `mfc-postfix`, `mfc-secdeps` — are meta-formalism-copilot canon instances, none of which is an auth-domain change (paraphrased — no quote available because the claim covers the absence of a category across a directory of artifacts; `mfc-secdeps` is dependency-security, not authentication). Confidence is Medium because this rests on instance identity rather than on scanning each body for auth prose.

**Evidence:** `runs/review-arms/e5-cc-builtin/`, `runs/review-arms/e7-fable-3x/`, `scripts/crb-cell-status.py:31-41`

---

## Claim 17: "The stubs run to ~56 chars and the shortest real review in the corpus is over 3 KB, so anywhere in between works; 1000 sits an order of magnitude clear of both."

**Location:** `scripts/crb-cell-status.py:42-46`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the stated corpus bounds that justify `STUB_MAX_LEN = 1000`; does not establish that any real review would actually be misclassified (none in the corpus is), only that the stated safety margin does not exist.

The shortest real (non-stub) review in the corpus is **1208 chars**, not "over 3 KB": `e7-fable-3x/mfc-fscompat/rep1` at 1208, `mfc-hygiene/rep2` at 1236, `mfc-deploy/rep2` at 1246, `mfc-csp/rep1` at 1261, `mfc-secdeps/rep3` at 1287, `mfc-lean/rep2` at 1289 — twenty of the twenty-two e7 review cells are between 1.2 and 3.0 KB (paraphrased — no quote available because the lengths were computed by iterating the 32 `result.json` data files). Only the eight `e5-cc-builtin` cells reach 2.7–7.1 KB.

Consequently `STUB_MAX_LEN = 1000` is *not* "an order of magnitude clear of both": it is ~18× the stub length but only **1.2× below the shortest real review**, a margin of 208 characters. A reader acting on the stated margin — e.g. concluding it is safe to raise `STUB_MAX_LEN` toward the "3 KB" floor the comment asserts — would put roughly twenty of the corpus's own review bodies inside the substring-matching band, which is exactly the failure the constant exists to prevent. The precise version: "the shortest real review in the corpus is ~1.2 KB, so 1000 clears the stubs by ~18× but the real reviews by only ~20%".

**Evidence:** `runs/review-arms/e7-fable-3x/*/rep*/result.json`, `scripts/crb-cell-status.py:42-46`

---

## Claim 18: "This floor is what actually rejects both stubs in the corpus (51 and 56 chars) — NON_REVIEW is never consulted for them. The substring list therefore only governs the 200-1000 char band … asserted in test/crb-cell-status.bats"

**Location:** `scripts/crb-cell-status.py:47-53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering of the length floor ahead of the substring test and the presence of tests pinning that division; does not cover Claim 17's separate assertion about where the upper bound sits relative to real reviews.

The floor is checked first and returns before `NON_REVIEW` is reachable:

```python
# scripts/crb-cell-status.py:64-70
    if len(r) < MIN_REVIEW_LEN:
        return False, f"body is {len(r)} chars, under the {MIN_REVIEW_LEN}-char floor"
    if len(r) < STUB_MAX_LEN:
        low = r.lower()
        hit = next((s for s in NON_REVIEW if s in low), None)
```

and the tests assert the *reason*, not just the verdict:

```bash
# test/crb-cell-status.bats:75-79
@test "the short auth stub is rejected — by the length floor" {
  check '{"subtype":"success","is_error":false,"result":"Not logged in · Please run /login"}'
  [ "$status" -eq 1 ]
  [[ "$output" == *floor* ]]
```

Command: `bats test/crb-cell-status.bats …`; cwd `/workspace`; exit 0; 2026-08-18T19:44:22-07:00 — tests 5–9 pass.

**Evidence:** `scripts/crb-cell-status.py:56-71`, `test/crb-cell-status.bats:70-106`, `docs/reviews/execution-logs/r3-bats-crb.txt`

---

## Claim 19: "`--verify … re-check containment (read-only)` / `--reset … restore, then re-check`" (usage block and argparse help)

**Location:** `scripts/crb-materialize.py:28-29`, `scripts/crb-materialize.py:335-341`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether each flag's documented behavior matches its implementation and which one run-host.sh calls; does not cover the flags' behavior on a slug missing from the manifest beyond the code path read.

`--verify` runs only read commands (`rev-parse`, `rev-list`, `remote`, `diff --shortstat`) via `verify_containment` and never mutates:

```python
# scripts/crb-materialize.py:373-374
                note = reset_clone(dst, slug, head, base) if resetting else ""
                n_commits, stat = verify_containment(dst, slug, head)
```

`--reset`'s help matches `reset_clone`'s contract, including the "voids only on contamination" and "used by run-host.sh" parts:

```python
# scripts/crb-materialize.py:338-341
    g.add_argument("--reset", nargs="+", metavar="SLUG",
                   help="restore clone(s) to the materialized state, then verify — "
                        "undoes agent commits/edits, voids only on contamination "
                        "(used by run-host.sh before and after each review cell)")
```

run-host.sh calls `--reset` at both cell boundaries (Claim 1) and calls `--verify` nowhere: `grep -n 'crb-materialize.py' runs/review-arms/crb-pipeline/run-host.sh` returns only the two `--reset` lines and the "clone missing" hint (paraphrased — no quote available because this is an absence-of-match result).

**Evidence:** `scripts/crb-materialize.py:22-29`, `scripts/crb-materialize.py:335-383`, `runs/review-arms/crb-pipeline/run-host.sh:224`, `runs/review-arms/crb-pipeline/run-host.sh:262`, `runs/review-arms/crb-pipeline/run-host.sh:359`

---

## Claim 20: "run-host.sh calls this via `--verify`."

**Location:** `scripts/crb-materialize.py:174`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the named caller path of `verify_containment`; does not imply the function is uncalled — `--reset` calls it after resetting.

This line in `verify_containment`'s docstring was accurate before `cf6e7c9`; the same commit switched both call sites to `--reset`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:262
  python3 "$ROOT/scripts/crb-materialize.py" --reset "$id" || {
```

What the code now does: run-host.sh calls `verify_containment` **via `--reset`**, which runs `reset_clone()` first and `verify_containment()` second (`scripts/crb-materialize.py:373-374`). `--verify` remains implemented and user-facing but has no caller inside the harness.

**Evidence:** `scripts/crb-materialize.py:168-181`, `scripts/crb-materialize.py:373-374`, `runs/review-arms/crb-pipeline/run-host.sh:262`, `runs/review-arms/crb-pipeline/run-host.sh:359`

---

## Claim 21a: "A stray that DESCENDS from the reviewed head … cannot contain the answer key: the merged upstream fix is not a descendant of the PR head in this clone"

**Location:** `scripts/crb-materialize.py:205-208`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the answer key is a descendant of the reviewed head *as the clone is materialized*; does not cover what an agent can add to the clone during a cell (Claim 21b), and does not enumerate the benchmark's merge strategies.

As materialized, the clone holds no upstream future at all: `materialize()` deletes every ref but `review`/`main`, removes the remote, expires reflogs and prunes:

```python
# scripts/crb-materialize.py:293-301
    refs = sh(["git", "for-each-ref", "--format=%(refname)",
               "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines()
    for ref in refs:
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    subprocess.run(["git", "remote", "remove", "origin"], cwd=dst,
                   capture_output=True, text=True)
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
```

and a fork whose default branch already contained the merged PR could not materialize at all, because `merge-base(review, origin/HEAD)` would equal the head and `verify_containment` rejects an empty range: `if n_commits == 0 or not stat: raise RuntimeError(f"{slug}: empty review range …")` (`scripts/crb-materialize.py:194-195`).

The imprecision is the word "not a descendant". A merge commit that lands PR #1 on the base branch has the PR head as a parent and therefore *does* descend from it (paraphrased — no quote available because this is git DAG semantics, not a snippet in this repo). The claim holds because such a commit is absent from the clone, not because descent fails — so descent-from-head is not, on its own, evidence that a commit is agent-authored. The precise version: "the merged upstream fix is *absent from* this clone, and (per Claim 21b) the routes that could introduce it are the ones the checks below must catch."

**Evidence:** `scripts/crb-materialize.py:194-196`, `scripts/crb-materialize.py:199-215`, `scripts/crb-materialize.py:280-301`

---

## Claim 21b: "with no remote there is no route to fetch it"

**Location:** `scripts/crb-materialize.py:207-208`
**Type:** Invariant / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the absence of a configured remote prevents fetching, and whether such a fetch is visible to the harness's containment checks; does not assert that any agent has done this, nor quantify likelihood.

`git fetch` accepts a URL directly and needs no configured remote. Executed in a scratch repo with zero remotes: `git fetch <path-to-other-repo> master` exited 0, wrote `FETCH_HEAD`, and made the "answer key" commit reachable (`git show FETCH_HEAD` printed it) while `git remote` stayed empty.

Both harness checks miss this. The remote check reads the config only — `remotes = sh(["git", "remote"], cwd=dst)` (`scripts/crb-materialize.py:231`) — and the stray check enumerates refs only:

```python
# scripts/crb-materialize.py:210-211
    strays = [l for l in sh(["git", "rev-list", "--all", "--not", head],
                            cwd=dst).splitlines() if l]
```

`git rev-list --all` walks `refs/`, which does not include `FETCH_HEAD`; the executed run confirms `git rev-list --all --not HEAD` printed nothing while the fetched commit was reachable by name. The container the claim protects has an unrestricted network, `--dangerously-skip-permissions` and a read-write `/repo` mount (`runs/review-arms/crb-pipeline/run-host.sh:274-285`), so the route is available in the arm as configured. The precise version: "no *configured* remote survives, and a re-added remote voids the cell; a URL-argument fetch leaves no remote and no ref, and is therefore not detected."

Command: `git fetch "$PWD/up" master` in a clone with `origin` removed (exp2 in the log); cwd `$TMPDIR/r3exp`; exit 0; 2026-08-18T19:46:13-07:00.

**Evidence:** `scripts/crb-materialize.py:199-215`, `scripts/crb-materialize.py:231-234`, `runs/review-arms/crb-pipeline/run-host.sh:274-285`, `docs/reviews/execution-logs/r3-bash-git-semantics.txt`

---

## Claim 22: "Raises RuntimeError — i.e. VOIDS the cell — only for contamination: a surviving remote, or a commit reachable outside the reviewed head's ancestry."

**Location:** `scripts/crb-materialize.py:222-225`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the two explicit `raise` sites in `reset_clone` and the caller's handling; does not cover incidental `RuntimeError`s from `sh(..., check=True)` when a git command fails for unrelated reasons (e.g. a locked index), which the caller also treats as a containment failure.

The only explicit raises are the two named (quoted under Claim 2). Note the "only" is qualified in practice: every `sh()` call in `reset_clone` uses `check=True` and so raises on any git failure —

```python
# scripts/crb-materialize.py:67-69
    if check and r.returncode != 0:
        raise RuntimeError(f"{' '.join(args)} failed ({r.returncode}): "
                           f"{(r.stderr or '').strip()[:500]}")
```

— and the caller catches `Exception` broadly and reports "CONTAINMENT CHECK FAILED" (`scripts/crb-materialize.py:375-377`). This fails safe (a git error voids rather than passes), so the claim's practical direction holds.

**Evidence:** `scripts/crb-materialize.py:63-70`, `scripts/crb-materialize.py:218-259`, `scripts/crb-materialize.py:372-378`

---

## Claim 23: "`-B` moves `review` back onto the pinned head from wherever HEAD now is; `--force` discards worktree state; the explicit `reset --hard` then guarantees the index matches too"

**Location:** `scripts/crb-materialize.py:241-243`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three stated effects as exercised by the bats fixtures (moved branch, dirty worktree, staged edit); does not cover a clone left with a detached HEAD mid-rebase or an in-progress merge.

```python
# scripts/crb-materialize.py:244-245
    sh(["git", "checkout", "--force", "--quiet", "-B", "review", head], cwd=dst)
    sh(["git", "reset", "--hard", "--quiet", head], cwd=dst)
```

The index claim is directly pinned: `test/crb-containment-reset.bats:92-100` stages a contaminated edit and asserts both the restored content and `[ -z "$(git -C "$CLONE" status --porcelain)" ]`; it passes (`ok 19 a staged edit to a tracked file is undone`). The branch-move and worktree claims are pinned by `ok 20`, `ok 22` and `ok 23` in the same captured run.

Command: `bats test/crb-containment-reset.bats …`; cwd `/workspace`; exit 0; 2026-08-18T19:44:22-07:00.

**Evidence:** `scripts/crb-materialize.py:241-253`, `test/crb-containment-reset.bats:92-140`, `docs/reviews/execution-logs/r3-bats-crb.txt`

---

## Claim 24: "(lines, checked) — sweep cells that are NOT in the judged subset … Reporting the count is not enough — the reader needs to know which PRs left and why."

**Location:** `scripts/crb-subset-leaderboard.py:41-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the return shape and the per-slug reason strings; does not establish that the four reason branches are exhaustive of real-world loss causes.

The function returns a `(list, bool)` pair on all three exits (`return ([...], False)`, `return ([], True)`, `return ([...], True)` at `scripts/crb-subset-leaderboard.py:52-80`) and names each lost slug with a reason:

```python
# scripts/crb-subset-leaderboard.py:66-73
        if slug in voided:
            why = "voided by a post-run containment failure"
        elif slug not in cells:
            why = "no cell produced (missing clone, or pre-run containment failure)"
        elif not url:
            why = f"not in {MANIFEST.name} — cannot map the slug to a PR"
        else:
            why = "ran, but has no judged row (no reviewable output, or not injected)"
        lost.append(f"     {slug:28} {why}")
```

**Evidence:** `scripts/crb-subset-leaderboard.py:40-80`

---

## Claim 25: "Attrition is always measured against the PRs OUR tool was judged on, even under `--all-prs` where the displayed subset is everything"

**Location:** `scripts/crb-subset-leaderboard.py:110-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argument passed to `attrition()` under both scoping modes; does not cover the correctness of the ranking rows themselves.

`our_urls` is computed independently of `--all-prs` and is what `attrition()` receives:

```python
# scripts/crb-subset-leaderboard.py:113-114
    our_urls = sorted(u for u, tools in evals.items() if args.tool in tools)
    urls = sorted(evals) if args.all_prs else our_urls
```

```python
# scripts/crb-subset-leaderboard.py:169
    att_lines, _checked = attrition(our_urls, Path(args.run_meta))
```

Pinned by `ok 30 attrition is reported under --all-prs too (subset scope is not the question)` in the captured run (cwd `/workspace`; exit 0; 2026-08-18T19:44:22-07:00).

**Evidence:** `scripts/crb-subset-leaderboard.py:110-114`, `scripts/crb-subset-leaderboard.py:165-170`, `test/crb-subset-attrition.bats:94-99`, `docs/reviews/execution-logs/r3-bats-crb.txt`

---

## Claim 26: "Written by run-host.sh. The leaderboard reads it to tell 'we ranked on 3 PRs' apart from 'we asked for 5 and 2 fell out'"

**Location:** `scripts/crb_common.py:28-32`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path agreement and the field names shared between writer and reader; does not cover fields written but unread (`missing_cells`, `retried_cells` are written and only `missing_cells`'s information is recomputed by the reader).

Path agreement: `RUN_META = WORKSPACE / "runs/review-arms/crb-pipeline/run-meta.json"` (`scripts/crb_common.py:32`) matches the writer, whose `OUT="$ROOT/runs/review-arms/crb-pipeline"` (`runs/review-arms/crb-pipeline/run-host.sh:54`) and which writes `"$OUT/run-meta.json"` (`runs/review-arms/crb-pipeline/run-host.sh:163`).

Field agreement — the writer emits:

```python
# runs/review-arms/crb-pipeline/run-host.sh:207-212
json.dump({"arm": "crb-pipeline", "payload_ref": ref, "payload_commit": sha,
           "model": model, "cc_version": ccv, "cells": cells,
           "requested_instances": req,
           "missing_cells": [s for s in req if s not in cells],
           "retried_cells": retried, "voided_cells": voided,
```

and the reader consumes exactly `cells`, `requested_instances`, `voided_cells` (quoted under Claim 8) — no name mismatch, so attrition cannot silently under-report through a typo'd field.

**Evidence:** `scripts/crb_common.py:28-32`, `runs/review-arms/crb-pipeline/run-host.sh:54`, `runs/review-arms/crb-pipeline/run-host.sh:163`, `runs/review-arms/crb-pipeline/run-host.sh:207-212`, `scripts/crb-subset-leaderboard.py:56-58`

---

## Claim 27: "32 cells, of which exactly 3 are known-bad: one budget exhaustion and two quota stubs" (`complete=29 incomplete=3`)

**Location:** `test/crb-cell-status.bats:170-175`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the corpus split and the identity of the three incomplete cells as of the checked-in artifacts; does not establish that the split is *correct* in the sense of matching a human's judgment of each body.

Independent enumeration of the 32 artifacts gives exactly three failures of the predicate: `e7-fable-3x/mfc-hygiene/rep1` (`is_error=True`, `error_max_budget_usd`), `e7-fable-3x/mfc-postfix/rep2` (56-char body) and `e7-fable-3x/mfc-postfix/rep3` (51-char body) — every other cell has `is_error=False`, `subtype='success'` and a body ≥ 1208 chars (paraphrased — no quote available because the split was computed by iterating data files). The suite's own assertions agree:

```bash
# test/crb-cell-status.bats:172-175
  [[ "$output" == *"complete=29 incomplete=3"* ]]
  [[ "$output" == *"mfc-hygiene/rep1"* ]]
  [[ "$output" == *"mfc-postfix/rep2"* ]]
  [[ "$output" == *"mfc-postfix/rep3"* ]]
```

Command: `bats test/crb-cell-status.bats test/crb-containment-reset.bats test/crb-subset-attrition.bats`; cwd `/workspace`; exit 0; 2026-08-18T19:44:22-07:00; `ok 14 verdicts on all checked-in result.json files are unchanged`.

**Evidence:** `test/crb-cell-status.bats:148-176`, `runs/review-arms/`, `docs/reviews/execution-logs/r3-bats-crb.txt`

---

## Claim 28: "a `git branch -f review` here would fail exactly the way materialize() warns about at crb-materialize.py:221-223"

**Location:** `test/crb-containment-reset.bats:114-115`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited line range only; the substantive point (materialize() warns about force-updating a checked-out branch) is still true at the new location.

`crb-materialize.py:221-223` in the *parent* commit held the warning the test cites:

```python
# git show HEAD~1:scripts/crb-materialize.py, lines 221-223
    # Check out `review` FIRST: on forks whose default branch is itself named
    # `main`, HEAD still points at it after --no-checkout, and git refuses to
    # force-update the branch that is checked out.
```

The same commit that added this test inserted `classify_strays`/`reset_clone` above it, so at `cf6e7c9` those lines are inside `reset_clone`'s docstring:

```python
# scripts/crb-materialize.py:221-223
    Raises RuntimeError — i.e. VOIDS the cell — only for contamination:
    a surviving remote, or a commit reachable outside the reviewed head's
    ancestry. Agent-authored commits on top of the head are reset, not voided.
```

The warning now lives at `scripts/crb-materialize.py:285-287`.

**Evidence:** `test/crb-containment-reset.bats:113-116`, `scripts/crb-materialize.py:218-230`, `scripts/crb-materialize.py:285-289`

---

## Claim 29: "Hermetic: synthetic evaluations/run-meta in BATS_TEST_TMPDIR. It does read the real runs/review-arms/crb/instances.json … which is read-only."

**Location:** `test/crb-subset-attrition.bats:15-17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite's writes and its one real-file read; does not cover the other two suites' hermeticity claims beyond the observed clean tree.

The suite writes only under `$BATS_TEST_TMPDIR`:

```bash
# test/crb-subset-attrition.bats:29, 48
  python3 - "$MANIFEST" "$1" "$TOOL" "$BATS_TEST_TMPDIR/evaluations.json" <<'PY'
  python3 - "$MANIFEST" "$BATS_TEST_TMPDIR/run-meta.json" "${1:-}" <<'PY'
```

and reads the manifest via `export MANIFEST="$REPO_ROOT/runs/review-arms/crb/instances.json"` (`test/crb-subset-attrition.bats:22`) without writing it. After the full 32-test run, `git status --porcelain` showed no modification to `runs/review-arms/crb/instances.json` or any tracked file (paraphrased — no quote available because this is an absence-of-output observation).

Command: `bats … test/crb-subset-attrition.bats`; cwd `/workspace`; exit 0; 2026-08-18T19:44:22-07:00.

**Evidence:** `test/crb-subset-attrition.bats:15-60`, `docs/reviews/execution-logs/r3-bats-crb.txt`

---

## Claim 30: "the load-bearing assertions here are the two negatives — a re-added remote and a commit outside the reviewed ancestry must still fail, or the fix has quietly disarmed the answer-key guard"

**Location:** `test/crb-containment-reset.bats:15-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the two named negative cases exist and fail-as-required; does not establish that they are *sufficient* to detect every contamination route (Claim 21b names one they do not cover).

Both negatives exist and assert a void:

```bash
# test/crb-containment-reset.bats:145-151
@test "a re-added remote still VOIDS the cell" {
  git -C "$CLONE" remote add origin https://example.invalid/x.git
  reset_and_verify
  [ "$status" -eq 1 ]
  [[ "$output" == *VOID* ]]
  [[ "$output" == *remote* ]]
```

plus a third (`a tag pointing outside the reviewed ancestry still VOIDS the cell`, `test/crb-containment-reset.bats:167-178`). All three pass (`ok 24`, `ok 25`, `ok 26`).

Command: `bats test/crb-containment-reset.bats …`; cwd `/workspace`; exit 0; 2026-08-18T19:44:22-07:00.

**Evidence:** `test/crb-containment-reset.bats:142-178`, `docs/reviews/execution-logs/r3-bats-crb.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 17** (`scripts/crb-cell-status.py:42-46`): "the shortest real review in the corpus is over 3 KB … 1000 sits an order of magnitude clear of both" — the shortest real review is 1208 chars and twenty corpus reviews sit between 1.2 and 3.0 KB, so the margin above `STUB_MAX_LEN` is ~20%, not an order of magnitude. Legibility-target: for-author.
- **Claim 21b** (`scripts/crb-materialize.py:207-208`): "with no remote there is no route to fetch it" — `git fetch <URL>` needs no configured remote, leaves no remote and no ref, and is invisible to both `git remote` and `git rev-list --all`; executed proof in `docs/reviews/execution-logs/r3-bash-git-semantics.txt`. Legibility-target: for-author (and see Escalate — this is the same trust boundary as the still-open R3).

### Stale
- **Claim 20** (`scripts/crb-materialize.py:174`): "run-host.sh calls this via `--verify`" — both call sites became `--reset` in this same commit; `verify_containment` is now reached through `--reset`. Legibility-target: for-author.
- **Claim 28** (`test/crb-containment-reset.bats:114-115`): the cited `crb-materialize.py:221-223` pointed at the pre-commit line numbers; the warning is now at `:285-287`, and `:221-223` is `reset_clone`'s docstring. Legibility-target: for-author.

### Mostly Accurate
- **Claim 5** (`docs/working/crb-direction1-setup.md:127-129`) and **Claim 14** (`scripts/crb-cell-status.py:20-21`): "3–7 KB" understates the range's floor — the eight e5 cells span 2.7–7.1 KB. Legibility-target: for-author.
- **Claim 21a** (`scripts/crb-materialize.py:205-208`): "the merged upstream fix is not a descendant of the PR head" — true because the fix is absent from the clone, not because descent fails; a merge commit of the PR does descend from its head, so descent alone is not evidence of agent authorship. Legibility-target: for-author.

### Verified (for-orchestrator-synthesis)
Claims 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 18, 19, 22, 23, 24, 25, 26, 27, 29, 30. Notably: the four pre-mortem narratives this commit claims to close (reset semantics, attrition reporting, EXIT-trap provenance, the 1000-char stub band) each check out against the code and against the 32 executed tests.

### Unverifiable
None.

---

## Goal-Alignment Note
- Answered: yes — 30 claims in `cf6e7c9` verdicted, report saved.
- Out of scope: code-quality and security judgments (e.g. whether `reset_clone`'s void policy is *the right* policy, and the still-open R3 credential/network exposure) — those belong to `security-reviewer`; commits outside `cf6e7c9` were read as context only.
- Escalate: Claim 21b is a factual refutation of a load-bearing containment claim, not just a comment fix — the answer-key guard does not detect a URL-argument `git fetch`, which the arm's container (unrestricted network, `--dangerously-skip-permissions`, read-write `/repo`) permits. Route it to `security-reviewer` alongside the open R3 before the sweep spends money. Claim 17's margin error should be fixed in the same pass, since a later reader raising `STUB_MAX_LEN` on the strength of the stated "3 KB" floor would re-introduce pre-mortem narrative 5.
