# Code Fact-Check Report

**Commit:** cf6e7c9
**Repository:** `/workspace` (claude-workflows)
**Scope:** commit `cf6e7c9` only (`git diff HEAD~1..HEAD`) on `feat/crb-direction1-harness` — 9 files, +851/-95. Partial scope: the rest of the branch is context, not under review.
**Checked:** 2026-08-19
**Total claims checked:** 45
**Summary:** 32 verified, 6 mostly accurate, 0 stale, 6 incorrect, 1 unverifiable

Prior-run hallucination patterns (`docs/reviews/hallucination-patterns.md`) were read before checking. The one logged pattern — *`total_golden` 11 vs 13 claimed in CRB evaluations.json but no PR has more than 9 goldens* — is a fabricated-quantitative-artifact-claim pattern. It is directly relevant here: this commit's docstrings make several exact quantitative claims about checked-in artifacts (Claims 24–28, 42), so each of those was recomputed from the artifacts rather than trusted. Claims 25, 26 and 28 are the same *shape* as the logged pattern (a specific measured range quoted from a corpus that does not support it); Claim 28 is a recurrence of that shape, though not of the same values.

Execution logs for this run are under `docs/reviews/execution-logs/` and are referenced from the claims that used them.

---

## Claim 1: "`--verify <slug>` # re-assert containment (read-only)" / "`--reset <slug>` # restore to materialized state, then verify"

**Location:** `docs/working/crb-direction1-setup.md:28-29`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two flags' documented effect and their read-only/mutating split; does not establish that `--verify` is free of side effects inside git's own object store (e.g. index refresh).

`--verify` reaches only `verify_containment()`, whose git invocations are all read-only queries:

```python
# scripts/crb-materialize.py:184-193
stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
...
remotes = sh(["git", "remote"], cwd=dst)
...
n_commits = int(sh(["git", "rev-list", "--count", "main..review"], cwd=dst))
stat = sh(["git", "diff", "--shortstat", "main", "review"], cwd=dst)
```

`--reset` runs the restore first and the same verification second:

```python
# scripts/crb-materialize.py:373-374
note = reset_clone(dst, slug, head, base) if resetting else ""
n_commits, stat = verify_containment(dst, slug, head)
```

**Evidence:** `scripts/crb-materialize.py:184-196`, `scripts/crb-materialize.py:347-374`

---

## Claim 2: "The clone is reset with `crb-materialize.py --reset <slug>` after harvesting, so re-runs start from the same state."

**Location:** `docs/working/crb-direction1-setup.md:89-90`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the ordering of harvest and reset in `run-host.sh`; does not establish that the harvest captures every artifact the reviewer wrote.

The artifact-harvest `while` loop ends at `run-host.sh:344`, and the reset call is the next statement:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:359
if ! python3 "$ROOT/scripts/crb-materialize.py" --reset "$id"; then
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:324-344`, `runs/review-arms/crb-pipeline/run-host.sh:359`

---

## Claim 3: "Containment is re-asserted before and after every cell via `crb-materialize.py --reset <slug>` … A pre-run failure skips the cell. A post-run failure **voids** it"

**Location:** `docs/working/crb-direction1-setup.md:94-103`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two call sites and their failure branches; does not establish that the void marker is honoured downstream by `crb-pipeline-to-benchmark.py` (out of this commit's scope).

Pre-run:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:262-264
python3 "$ROOT/scripts/crb-materialize.py" --reset "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2
    skipped_bad=$((skipped_bad+1)); continue; }
```

Post-run, the failure branch writes the marker and rewrites the result:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:359-369
if ! python3 "$ROOT/scripts/crb-materialize.py" --reset "$id"; then
    echo "$id: POST-RUN containment check FAILED — voiding this cell" >&2
    : > "$dest/CONTAINMENT_FAILED"
...
d["is_error"] = True
d["subtype"] = "containment_failed"
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:262-264`, `runs/review-arms/crb-pipeline/run-host.sh:359-371`

---

## Claim 4: "a commit on top of the reviewed head cannot contain the answer key — there is no remote to fetch it from — so it is **reset**"

**Location:** `docs/working/crb-direction1-setup.md:104-108`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the stated impossibility mechanism ("no remote ⇒ no route to fetch") and the resulting classification; does not establish that any real cell has been contaminated this way, and does not weigh the residual risk (that is `security-reviewer`'s call).

Absence of a configured remote does not prevent fetching: `git fetch <URL> <refspec>` takes a URL directly. Reproduced on a synthetic clone built the same way `materialize()` builds one (scrubbed refs, `git remote remove origin`, `gc --prune=now`):

```
# docs/reviews/execution-logs/r1-fetch-without-remote.txt
+ git fetch file:///workspace/cfcr1/cl/../src main:refs/heads/upstream
From file:///workspace/cfcr1/cl/../src
 * [new branch]      main       -> upstream
+ git show upstream:fix.txt
ANSWER KEY: the upstream fix
```

The reviewing container has unrestricted network (no `--network` argument on the `docker run`) and runs the agent with `--dangerously-skip-permissions`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:274-285
docker run --rm -u node -w /repo \
    -e ANTHROPIC_API_KEY \
    -v "$clone":/repo \
...
      --dangerously-skip-permissions \
```

Content fetched that way and then committed on top of the head classifies as *safe* — the same synthetic clone, after deleting the fetched ref and committing the answer-key file, returns `foreign == []` and is silently reset rather than voided:

```
# docs/reviews/execution-logs/r1-classify-strays-blindspot.txt
classify_strays: (['bf6fa02de83dc228b3a07cade85c307f2755c87d'], [])
reset_clone note: 1 agent commit(s) on top of the head, reset
verify_containment: (1, '1 file changed, 1 insertion(+)')
```

A fetch that leaves its commits reachable *is* caught (they are not descendants of head — Claim 31), so the gap is narrow; but the claim as written asserts impossibility, and impossibility does not hold.

Commands (cwd `/workspace/cfcr1`, 2026-08-19T02:48Z): the shell transcript in `docs/reviews/execution-logs/r1-fetch-without-remote.txt` (exit 0) and the Python driver in `docs/reviews/execution-logs/r1-classify-strays-blindspot.txt` (exit 0).

**Evidence:** `docs/reviews/execution-logs/r1-fetch-without-remote.txt`, `docs/reviews/execution-logs/r1-classify-strays-blindspot.txt`, `scripts/crb-materialize.py:199-215`, `runs/review-arms/crb-pipeline/run-host.sh:274-285`

---

## Claim 5: "A surviving **remote**, or any commit reachable outside the reviewed head's ancestry, still **voids**."

**Location:** `docs/working/crb-direction1-setup.md:108-110`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the wording of the voiding condition; does not dispute that the intended condition (non-descendant commits) is what the code implements.

An agent commit on top of `review` *is* "reachable outside the reviewed head's ancestry" — it is exactly what `git rev-list --all --not head` lists — yet it does not void. The implemented condition is narrower: only strays that are **not descendants** of head void.

```python
# scripts/crb-materialize.py:210-214
strays = [l for l in sh(["git", "rev-list", "--all", "--not", head],
                        cwd=dst).splitlines() if l]
foreign = [c for c in strays
           if subprocess.run(["git", "merge-base", "--is-ancestor", head, c],
                             cwd=dst, capture_output=True).returncode != 0]
```

The precise phrasing is "a commit not descended from the reviewed head". The preceding sentence in the same paragraph disambiguates, so a reader is unlikely to be misled in practice.

**Evidence:** `scripts/crb-materialize.py:210-215`, `scripts/crb-materialize.py:235-239`

---

## Claim 6: "The old reset (`git checkout -- . && git clean -qfdx`) restored tracked files *from the index*, so it undid neither a commit nor a `git add`"

**Location:** `docs/working/crb-direction1-setup.md:110-114`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git's `checkout -- .` semantics and the previous version of the reset in `run-host.sh`; does not establish how often either survival actually occurred in past sweeps.

The previous version of the file did exactly those two commands:

```bash
# git show HEAD~1:runs/review-arms/crb-pipeline/run-host.sh (removed hunk)
-  git -C "$clone" checkout -- . 2>/dev/null || true
-  git -C "$clone" clean -qfdx 2>/dev/null || true
```

Executed demonstration — a staged, uncommitted edit survives `git checkout -- .` and is only removed by `reset --hard`:

```
# docs/reviews/execution-logs/r1-old-reset-semantics.txt
--- worktree content after old reset ---
STAGED AGENT EDIT
--- vs the new reset (git reset --hard HEAD) ---
original
```

and a commit plus its staged content both survive:

```
# docs/reviews/execution-logs/r1-old-reset-semantics.txt
--- after the OLD reset (git checkout -- . && git clean -qfdx) ---
AGENT EDIT
f.txt
g.txt
e012d12 agent commit
300a29e base
```

Commands: shell transcripts, cwd `/workspace/cfcr1`, exit 0, 2026-08-19T02:50Z.

**Evidence:** `docs/reviews/execution-logs/r1-old-reset-semantics.txt`, `runs/review-arms/crb-pipeline/run-host.sh:345-353`

---

## Claim 7: "Guarded by `test/crb-containment-reset.bats`, whose load-bearing cases are the two that must still void."

**Location:** `docs/working/crb-direction1-setup.md:114-116`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence and passing status of the two negative cases; does not establish that they are sufficient coverage for the contamination space (Claim 4 shows one uncovered path).

The suite's own header names the same two:

```
# test/crb-containment-reset.bats:14-17
# The fix has to cut a fine line: undo agent work, but still VOID for the thing
# the control exists to catch. So the load-bearing assertions here are the two
# negatives — a re-added remote and a commit outside the reviewed ancestry must
# still fail, or the fix has quietly disarmed the answer-key guard.
```

Both pass, along with a third case (a tag pointing outside the ancestry) that is a variant of the second:

```
# docs/reviews/execution-logs/r1-bats-crb.txt
ok 24 a re-added remote still VOIDS the cell
ok 25 a commit outside the reviewed ancestry still VOIDS the cell
ok 26 a tag pointing outside the reviewed ancestry still VOIDS the cell
```

Command: `bats test/crb-cell-status.bats test/crb-containment-reset.bats test/crb-subset-attrition.bats`, cwd `/workspace`, exit 0, 2026-08-19T02:44:59Z.

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `test/crb-containment-reset.bats:14-17`

---

## Claim 8: "two pilot instances are auth-domain (`keycloak-PR36880`, `cal_com-PR11059`)"

**Location:** `docs/working/crb-direction1-setup.md:122-124`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two named slugs, their PR titles and the pilot size; does not establish that no other pilot PR touches auth code incidentally.

The manifest holds exactly five instances, of which those two carry auth PR titles (paraphrased — no quote available because the source is a 5-entry JSON manifest and reads more clearly as the extracted mapping below than as a raw fragment):

```
cal_com-PR11059  | OAuth credential sync and app integration enhancements | cal.com
keycloak-PR36880 | Add Client resource type and scopes to authorization schema | keycloak
(plus discourse-graphite-PR4, grafana-PR79265, sentry-greptile-PR5)
```

**Evidence:** `runs/review-arms/crb/instances.json`

---

## Claim 9: "8 real cells in this repo are genuine successes with `num_turns == 0` and 3–7 KB of review text"

**Location:** `docs/working/crb-direction1-setup.md:127-129`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the count, the turns value and the size range of the eight `e5-cc-builtin` cells; does not re-verify that their bodies are substantively reviews rather than long non-review text.

The count and `num_turns == 0` hold for all eight; the size range is 2,733–7,121 characters, so the low end is 2.7 KB, not 3 KB (paraphrased — no quote available because the values were computed across eight JSON files; the per-file dump is in the execution log):

```
runs/review-arms/e5-cc-builtin/mfc-postfix/result.json | subtype=success is_error=False turns=0 len=2733
runs/review-arms/e5-cc-builtin/mfc-corpus/result.json  | subtype=success is_error=False turns=0 len=7121
```

Precise version: "2.7–7 KB". Command: `python3` corpus dump, cwd `/workspace`, exit 0, 2026-08-19T02:44Z (output captured in `docs/reviews/execution-logs/r1-corpus-dump.txt`).

**Evidence:** `docs/reviews/execution-logs/r1-corpus-dump.txt`, `runs/review-arms/e5-cc-builtin/*/result.json`

---

## Claim 10: "**On `--all`, expect to hit it** — the 50-PR estimate is $500–2000"

**Location:** `docs/working/crb-direction1-setup.md:142-143`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the arithmetic relation between the default sweep ceiling and the doc's own 50-PR estimate; does not assess whether the estimate itself is right.

The doc's own cost table gives the figure quoted:

```markdown
# docs/working/crb-direction1-setup.md:247
| All 50 | **~$500–2000** | do not commit to this before a pilot |
```

and the default ceiling sits below its lower bound:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:68
SWEEP_BUDGET="${SWEEP_BUDGET:-250.00}"
```

**Evidence:** `docs/working/crb-direction1-setup.md:247`, `runs/review-arms/crb-pipeline/run-host.sh:68`

---

## Claim 11a: "`run-meta.json` is written from an `EXIT` trap, so the budget halt … still leave[s] the provenance file"

**Location:** `docs/working/crb-direction1-setup.md:143-146`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `exit 2` path from inside the loop; does not establish that the written file is complete when the halt lands mid-cell.

The gate exits from inside the loop, and the EXIT trap installed before the loop calls the writer:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:404
python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:220
trap 'write_run_meta; rm -rf "$PAYLOAD_SRC"' EXIT
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:159-220`, `runs/review-arms/crb-pipeline/run-host.sh:404`

---

## Claim 11b: "… a `Ctrl-C` … still leave[s] the provenance file"

**Location:** `docs/working/crb-direction1-setup.md:144-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers bash's EXIT-trap behaviour when SIGINT is delivered to the foreground process group during a tolerated child command; does not establish that `write_run_meta`'s own Python succeeds under interruption.

A structural analogue of the loop (EXIT trap, `sleep` child guarded by `|| { … }`), interrupted with SIGINT to the foreground process group under a pty:

```
# docs/reviews/execution-logs/r1-sigint-exit-trap.txt
--- captured output ---
cell 1 start
EXIT TRAP RAN (write_run_meta analogue)
```

Note for the author, not a defect in the claim: the same probe shows that SIGINT delivered to the *bash process alone* (not the group) is discarded once the child exits normally — the script then runs to completion. That is the background-job case, not Ctrl-C.

Command: `python3 ptytest.py`, cwd `/workspace/cfcr1`, exit 0, 2026-08-19T02:48:29Z.

**Evidence:** `docs/reviews/execution-logs/r1-sigint-exit-trap.txt`, `runs/review-arms/crb-pipeline/run-host.sh:220`

---

## Claim 11c: "… and a docker failure all still leave the provenance file"

**Location:** `docs/working/crb-direction1-setup.md:144-145`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the two docker invocations that can fail before/inside the loop; does not cover docker failures in the preflight `docker run`, which is already `|| true`-guarded.

There are two distinct docker-failure cases, and neither behaves as the sentence implies.

The per-cell `docker run` failure is explicitly tolerated, so it never triggers an exit at all — the sweep continues and `run-meta.json` is written by the normal end-of-script path, EXIT trap or not:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:286-287
    > "$dest/transcript.jsonl" 2> "$dest/stderr.log" || {
      echo "$id: claude exited non-zero — see $dest/stderr.log" >&2; }
```

The docker failure that *does* abort the script — the unguarded cache-chown run — happens at line 113, **before** the EXIT trap is installed at line 220, so it still leaves no `run-meta.json`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:113-114
docker run --rm -v cc-review-npm-cache:/home/node/.npm node:22 \
  chown -R node:node /home/node/.npm
```

(There is nothing to write at that point — no cell has run — so the practical harm is nil; the sentence is still wrong about the mechanism.)

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:113-114`, `runs/review-arms/crb-pipeline/run-host.sh:220`, `runs/review-arms/crb-pipeline/run-host.sh:286-287`

---

## Claim 12: "it previously sat after the loop and the halt skipped it"

**Location:** `docs/working/crb-direction1-setup.md:145-146`
**Type:** Staleness / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the previous placement of the run-meta writer relative to the loop; does not establish that a halt was ever actually observed in a real sweep.

The removed hunk sits after `done`:

```bash
# git diff HEAD~1..HEAD -- runs/review-arms/crb-pipeline/run-host.sh
 done
 
-# Sweep-level provenance: which payload actually ran (review-canon section 3).
-python3 - "$OUT/run-meta.json" "$PAYLOAD_REF" ... <<'EOF'
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:430-432`

---

## Claim 13: "The script now cross-checks the judged subset against `run-meta.json`'s `requested_instances`, names every missing cell with its reason, and repeats the warning inside `--markdown` … If it prints `attrition NOT checked`, the run-meta was not found"

**Location:** `docs/working/crb-direction1-setup.md:230-239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three documented behaviours of `attrition()` and its output surfaces; does not establish that the reasons assigned to each missing cell are always the true cause.

```python
# scripts/crb-subset-leaderboard.py:59-73
requested = meta.get("requested_instances") or sorted(cells)
...
        why = "voided by a post-run containment failure"
...
        why = "no cell produced (missing clone, or pre-run containment failure)"
```

```python
# scripts/crb-subset-leaderboard.py:168-172
    if args.markdown:
...
        for note in ([warn] if warn else []) + ([("\n".join(att_lines))] if att_lines else []):
            print("> " + note.replace("\n", "\n> ") + "\n")
```

and the missing-run-meta message:

```python
# scripts/crb-subset-leaderboard.py:52
        return ([f"!! subset attrition NOT checked: no run-meta.json at {run_meta_path} "
```

All four behaviours are pinned by passing tests:

```
# docs/reviews/execution-logs/r1-bats-crb.txt
ok 28 cells that never reached the judge are named, with a reason
ok 29 a containment-voided cell is reported as voided, not as unjudged
ok 31 attrition appears in the markdown body, not only on stderr
ok 32 a missing run-meta says attrition was NOT checked rather than staying silent
```

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `scripts/crb-subset-leaderboard.py:40-79`, `scripts/crb-subset-leaderboard.py:164-172`

---

## Claim 14: "the SWEEP_BUDGET gate below exits 2 from INSIDE the loop, so the halt … wrote no run-meta.json at all"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:153-158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pre-change control flow; does not cover the "Ctrl-C and a docker failure" sentence that follows (Claims 15a/15b).

Duplicate of Claim 11a's mechanism, verified against the same two lines plus the removed hunk's position after `done`.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:404`, `runs/review-arms/crb-pipeline/run-host.sh:430-432`

---

## Claim 15a: "Ctrl-C … had the same hole."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether a Ctrl-C under the old (trap-less) arrangement would have skipped the post-loop writer; does not re-derive bash's signal semantics beyond the probe in Claim 11b.

Under the old arrangement the writer sat after `done` and no EXIT trap covered it; the probe in `docs/reviews/execution-logs/r1-sigint-exit-trap.txt` shows the script terminates at the interrupted cell, so a post-loop statement is never reached. Same command/provenance as Claim 11b.

**Evidence:** `docs/reviews/execution-logs/r1-sigint-exit-trap.txt`, `runs/review-arms/crb-pipeline/run-host.sh:430-432`

---

## Claim 15b: "…and a docker failure had the same hole."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:158`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Same scope as Claim 11c — this is the in-code twin of that doc sentence.

See Claim 11c: the per-cell `docker run` is `||`-guarded (line 286-287) so it never exited the old script, and the one unguarded docker call (line 113) precedes the new trap's installation, so the fix does not close it either.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:113-114`, `runs/review-arms/crb-pipeline/run-host.sh:220`, `runs/review-arms/crb-pipeline/run-host.sh:286-287`

---

## Claim 16: "A slug that never got far enough to write a result.json … appears here and nowhere else"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:202-205`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers where such a slug appears within `run-meta.json`; does not dispute the comment's point about the leaderboard needing it.

Such a slug appears in two fields of the very JSON being written, not one — `missing_cells` is computed from `req` three lines below the comment:

```python
# runs/review-arms/crb-pipeline/run-host.sh:209-210
           "requested_instances": req,
           "missing_cells": [s for s in req if s not in cells],
```

Precise version: "appears in `requested_instances` (and, derived from it, `missing_cells`) and in no per-cell record".

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:202-212`

---

## Claim 17: "Replaces the payload-only trap set above: both jobs, one handler."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers trap replacement and `PAYLOAD_SRC` cleanup on every exit path; does not cover `PF_HOME`/`INST_HOME` temp dirs, which no trap covers (a code-review matter, not a claim).

Bash replaces a signal's trap on re-`trap`, and both handlers include the payload cleanup, so no path loses it:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:97
trap 'rm -rf "$PAYLOAD_SRC"' EXIT
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:220
trap 'write_run_meta; rm -rf "$PAYLOAD_SRC"' EXIT
```

The only early exits between the two — the DRY_RUN return and the missing-API-key check — occur while the first trap is installed:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:105-109
if [ -n "$DRY_RUN" ]; then
  echo "DRY_RUN=1 — payload built and verified, no container started, \$0 spent."
  exit 0
fi
[ -n "${ANTHROPIC_API_KEY:-}" ] || { echo "ANTHROPIC_API_KEY not set" >&2; exit 1; }
```

`write_run_meta` is idempotent, so the explicit call at line 432 plus the trap does not double-write:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:160-162
write_run_meta() {
  if [ -n "$META_WRITTEN" ]; then return 0; fi
  META_WRITTEN=1
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:97`, `runs/review-arms/crb-pipeline/run-host.sh:105-109`, `runs/review-arms/crb-pipeline/run-host.sh:160-162`, `runs/review-arms/crb-pipeline/run-host.sh:219-220`

---

## Claim 18: "The rules … live in scripts/crb-cell-status.py — extracted from here so they have fixtures … It prints its reason either way; capture it so the re-run message says WHY."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:227-230`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the extraction, the reason capture, and its use in the re-run message; does not cover whether `cell_status` is populated when `result.json` is absent (it is unused on that path).

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

The script prints on both branches:

```python
# scripts/crb-cell-status.py:82-84
    ok, reason = status(d)
    print(reason)
    return 0 if ok else 1
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:227-251`, `scripts/crb-cell-status.py:70-85`

---

## Claim 19: "--reset (not --verify): the cell must START from the materialized state, so anything a previous run left behind is undone here rather than reviewed."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:260-262`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the pre-run call is `--reset` and that a reset clone re-verifies on the following cell; does not establish that every possible leftover shape is undone.

```bash
# runs/review-arms/crb-pipeline/run-host.sh:262
  python3 "$ROOT/scripts/crb-materialize.py" --reset "$id" || {
```

```
# docs/reviews/execution-logs/r1-bats-crb.txt
ok 18 the clone still verifies on the NEXT cell after an agent commit
ok 19 a staged edit to a tracked file is undone
ok 20 an unstaged edit and an untracked file are undone
ok 21 a gitignored file the review created is removed
```

Same command/provenance as Claim 7.

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `runs/review-arms/crb-pipeline/run-host.sh:262`

---

## Claim 20: "a commit (which this repo's own CLAUDE.md, mounted into every container, instructs the agent to make) voided the cell AND left the clone permanently failing its pre-run check"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:345-353`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that CLAUDE.md reaches the container as user memory and instructs committing, and that the old checker voided on any stray commit; does not establish that any historical cell was actually voided this way.

`CLAUDE.md` is part of the archived payload and the payload is mounted as the container's `~/.claude`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:98-99
git -C "$ROOT" archive "$PAYLOAD_REF" skills workflows guides patterns CLAUDE.md \
  | tar -x -C "$PAYLOAD_SRC"
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:277
    -v "$INST_HOME":/home/node/.claude \
```

That CLAUDE.md instructs committing, and the default operating mode makes it autonomous:

```markdown
# CLAUDE.md (General Principles)
  - When in doubt, commit. Small commits are cheap; large unstaged changes are expensive to review and recover.
```

The old checker had no descendant exemption — any stray commit raised:

```python
# scripts/crb-materialize.py:184-187
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
    stray_n = len([l for l in stray.splitlines() if l])
    if stray_n:
        raise RuntimeError(f"{slug}: {stray_n} stray commit(s) reachable outside the reviewed head")
```

and since the old reset did not remove the commit (Claim 6), the failure persisted into the next attempt.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:98-99`, `runs/review-arms/crb-pipeline/run-host.sh:277`, `CLAUDE.md`, `scripts/crb-materialize.py:184-187`

---

## Claim 21: "Exit 0 = complete (run-host.sh skips the cell); exit 1 = incomplete (re-run)."

**Location:** `scripts/crb-cell-status.py:3-4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit-code contract and the caller's branch; does not cover the `MAX_ATTEMPTS` interaction that can turn a "re-run" into a permanent skip.

```python
# scripts/crb-cell-status.py:84
    return 0 if ok else 1
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:233-235
    if cell_status=$(python3 "$ROOT/scripts/crb-cell-status.py" "$dest/result.json" 2>&1); then
      echo "=== $id — completed result exists, skipping (delete to re-run)"
```

**Evidence:** `scripts/crb-cell-status.py:76-88`, `runs/review-arms/crb-pipeline/run-host.sh:232-237`

---

## Claim 22: "Both directions have already happened in this repo's arms"

**Location:** `scripts/crb-cell-status.py:9-12`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether both failure directions are attested by an arm script plus its artifacts; does not dispute that both directions are real risks prospectively (the false-complete one is attested).

The false-*complete* direction is attested: `e7-fable-3x`'s resume predicate is turns-only, and the budget-exhausted cell has `num_turns == 1`, so it was banked.

```python
# runs/review-arms/e7-fable-3x/run-host.sh:123
sys.exit(0 if d.get("num_turns", 0) > 0 else 1)
```

The false-*incomplete* direction has no in-repo instance: the eight `num_turns == 0` real reviews live in `e5-cc-builtin`, whose runner has no resume/skip predicate at all — a grep for a `result.json` completeness test in `runs/review-arms/e5-cc-builtin/run-host.sh` returns only the summary printer (paraphrased — no quote available because the claim covers the *absence* of code; the only `num_turns` hit in that file is the per-cell `print`). So the eight cells were never re-paid; the argument is prospective, not historical.

Precise version: "one direction has already happened in this repo's arms; the other is what applying that predicate to the e5 artifacts would produce."

**Evidence:** `runs/review-arms/e7-fable-3x/run-host.sh:118-124`, `runs/review-arms/e5-cc-builtin/run-host.sh:40-62`

---

## Claim 23: "Measured against the 32 result.json files under runs/review-arms/"

**Location:** `scripts/crb-cell-status.py:14-15`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the file count under `runs/review-arms/` at this commit; does not establish the count is pinned against future additions (the bats corpus test does that).

```
# docs/reviews/execution-logs/r1-corpus-dump.txt
32 files
```

Command: `python3` glob over `runs/review-arms/**/result.json`, cwd `/workspace`, exit 0, 2026-08-19T02:44Z.

**Evidence:** `docs/reviews/execution-logs/r1-corpus-dump.txt`

---

## Claim 24: "e7-fable-3x/mfc-hygiene/rep1: subtype=error_max_budget_usd, $15.24"

**Location:** `scripts/crb-cell-status.py:16-18`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the named file's subtype and cost; does not establish that it is the only budget-exhausted cell in the corpus (it is — see Claim 42's incomplete list).

```
# docs/reviews/execution-logs/r1-corpus-dump.txt
runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json | subtype=error_max_budget_usd is_error=True turns=1 len=0 cost=15.240262000000001
```

Same command/provenance as Claim 23.

**Evidence:** `docs/reviews/execution-logs/r1-corpus-dump.txt`, `runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json`

---

## Claim 25: "8 e5-cc-builtin cells are genuine successes with num_turns == 0 and 3-7 KB of real review text"

**Location:** `scripts/crb-cell-status.py:19-20`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Same subject as Claim 9 (the docstring and the setup doc state it twice); covers count, turns and size range.

Count and turns hold; the range is 2,733–7,121 characters, i.e. 2.7–7 KB, not 3–7 KB. Same evidence and command as Claim 9. Same *shape* as the logged hallucination pattern (`total_golden` 11 vs 13 …): a quantitative range quoted from a corpus whose low end does not match — though here the drift is 10%, not a fabrication.

**Evidence:** `docs/reviews/execution-logs/r1-corpus-dump.txt`

---

## Claim 26: "2 e7 cells report subtype=success, is_error=false, num_turns=0 with a 51-56 char body that is actually 'You've hit your weekly limit'"

**Location:** `scripts/crb-cell-status.py:21-23`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the two cells' fields, body lengths and body text; does not affect the predicate, which rejects both on length before any substring is consulted.

The fields, the count and the lengths are exact. The body text is right for one cell and wrong for the other — the 51-char one is a *session* limit, not a weekly limit:

```
# docs/reviews/execution-logs/r1-corpus-dump.txt (bodies)
runs/review-arms/e7-fable-3x/mfc-postfix/rep2/result.json "You've hit your weekly limit · resets Aug 18, 12am (UTC)"
runs/review-arms/e7-fable-3x/mfc-postfix/rep3/result.json "You've hit your session limit · resets 5:10am (UTC)"
```

Precise version: "…a 51–56 char body that is actually a quota stub ('You've hit your weekly limit' / 'You've hit your session limit')". Both spellings are already in `NON_REVIEW`, so nothing in the code depends on the imprecision.

**Evidence:** `docs/reviews/execution-logs/r1-corpus-dump.txt`, `scripts/crb-cell-status.py:33-34`

---

## Claim 27: "the two in-repo examples are 51 and 56 characters … two of the five pilot instances are auth-domain … The 32-file corpus that validated this predicate contains no auth-domain reviews"

**Location:** `scripts/crb-cell-status.py:27-35`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stub lengths, the pilot instance count/titles, and the absence of `NON_REVIEW` substrings in the corpus's real reviews; "auth-domain" as a topical judgement about the mfc-* corpus is asserted on the substring evidence, hence Medium confidence.

Lengths and pilot instances: see Claims 26 and 8. For the corpus property, a substring sweep over all 32 bodies matches only the two stubs — no real review contains "log in" or "logged in":

```
# docs/reviews/execution-logs/r1-corpus-dump.txt
---- substring scan over all 32 ----
runs/review-arms/e7-fable-3x/mfc-postfix/rep2/result.json 56 ['hit your weekly limit', 'limit · resets']
runs/review-arms/e7-fable-3x/mfc-postfix/rep3/result.json 51 ['hit your session limit', 'limit · resets']
```

Same command/provenance as Claim 23.

**Evidence:** `docs/reviews/execution-logs/r1-corpus-dump.txt`, `runs/review-arms/crb/instances.json`

---

## Claim 28: "The stubs run to ~56 chars and the shortest real review in the corpus is over 3 KB, so anywhere in between works; 1000 sits an order of magnitude clear of both."

**Location:** `scripts/crb-cell-status.py:36-40`
**Type:** Configuration / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the stated corpus minimum and the margin claim that justifies `STUB_MAX_LEN = 1000`; does not claim that 1000 is the wrong threshold, only that the stated headroom does not exist.

Not split: both refuted parts share one verdict, and the second is an inference from the first. The corpus minimum for a real review is **1,208 characters**, not "over 3 KB" — the sub-2 KB band is populated by 15 e7 reviews:

```
# docs/reviews/execution-logs/r1-corpus-dump.txt
runs/review-arms/e7-fable-3x/mfc-fscompat/rep1/result.json | subtype=success is_error=False turns=9 len=1208
runs/review-arms/e7-fable-3x/mfc-deploy/rep2/result.json   | subtype=success is_error=False turns=7 len=1246
runs/review-arms/e7-fable-3x/mfc-csp/rep1/result.json      | subtype=success is_error=False turns=6 len=1261
```

Consequently `STUB_MAX_LEN = 1000` is an order of magnitude clear of the stubs (56 chars) but only ~1.2× clear of the shortest real review — a real review of auth code shorter than 1,000 characters would be rejected by `NON_REVIEW`, which is the failure mode the constant exists to prevent. This is the same shape as the logged hallucination pattern (a corpus statistic quoted that the corpus does not support), and it is the load-bearing quantity for the pre-mortem-N5 fix.

Precise version: "the stubs run to ~56 chars and the shortest real review in the corpus is ~1.2 KB, so 1000 sits an order of magnitude clear of the stubs and ~20% clear of the shortest real review."

Same command/provenance as Claim 23.

**Evidence:** `docs/reviews/execution-logs/r1-corpus-dump.txt`, `scripts/crb-cell-status.py:36-40`

---

## Claim 29: "This floor is what actually rejects both stubs in the corpus (51 and 56 chars) — NON_REVIEW is never consulted for them. The substring list therefore only governs the 200-1000 char band … asserted in test/crb-cell-status.bats"

**Location:** `scripts/crb-cell-status.py:41-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the division of labour between the length floor and the substring list, and that tests pin it; does not cover whether the 200-char floor is itself well-chosen.

The control flow returns before the substring check for anything under 200 chars:

```python
# scripts/crb-cell-status.py:63-72
    if len(r) < MIN_REVIEW_LEN:
        return False, f"body is {len(r)} chars, under the {MIN_REVIEW_LEN}-char floor"
    if len(r) < STUB_MAX_LEN:
        low = r.lower()
        hit = next((s for s in NON_REVIEW if s in low), None)
```

and the corpus run confirms both stubs are rejected by the floor, with the reason printed:

```
# docs/reviews/execution-logs/r1-bats-crb.txt
ok 5 the short auth stub is rejected — by the length floor
ok 6 the short quota stub is rejected — by the length floor
ok 7 a mid-length auth stub is rejected by the substring rule
ok 8 a mid-length quota stub is rejected by the substring rule
```

Same command/provenance as Claim 7.

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `scripts/crb-cell-status.py:63-74`

---

## Claim 30: "`scripts/crb-materialize.py --reset  grafana-PR79265   # restore, then re-check`"

**Location:** `scripts/crb-materialize.py:28-29`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the usage block's two lines match the implemented flags and their order of operations; does not check the other usage lines (unchanged by this commit).

Same evidence as Claim 1 — `reset_clone()` runs before `verify_containment()` at `scripts/crb-materialize.py:373-374`, and `grafana-PR79265` is a real manifest slug.

**Evidence:** `scripts/crb-materialize.py:373-374`, `runs/review-arms/crb/instances.json`

---

## Claim 31: "the merged upstream fix is not a descendant of the PR head in this clone"

**Location:** `scripts/crb-materialize.py:205-207`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the ancestry relation between an upstream post-PR commit and the reviewed head, and its presence in a freshly materialized clone; does not cover what happens after the agent has run (Claim 4).

On a synthetic clone built by the same sequence `materialize()` uses, the upstream fix commit is not merely a non-descendant — it is absent from the object store entirely after the ref scrub and `gc --prune=now`:

```
# docs/reviews/execution-logs/r1-fetch-without-remote.txt
--- clone state: remotes / refs / does the answer key exist? ---
+ git for-each-ref --format=%(refname)
refs/heads/main
refs/heads/review
+ git log --all --oneline
b3b4faf base
d5f3f96 pr head
+ ls
f
```

Command: shell transcript, cwd `/workspace/cfcr1`, exit 0, 2026-08-19T02:48:43Z.

**Evidence:** `docs/reviews/execution-logs/r1-fetch-without-remote.txt`, `scripts/crb-materialize.py:280-301`

---

## Claim 32: "It cannot contain the answer key: … with no remote there is no route to fetch it."

**Location:** `scripts/crb-materialize.py:204-208`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** In-code twin of Claim 4; covers the impossibility mechanism only.

See Claim 4: `git fetch <URL>` needs no configured remote, the container has unrestricted network, and a descendant commit carrying fetched content classifies as `foreign == []` (safe) and is reset without a void or a warning. The rest of the docstring — that a *fetch-shaped* stray (non-descendant) is treated as contamination — holds (Claim 33 covers the wording).

Precise version: "It cannot contain the answer key *from this clone's own history*; a fetch from the network is still possible and is only caught when it leaves non-descendant commits reachable."

**Evidence:** `docs/reviews/execution-logs/r1-fetch-without-remote.txt`, `docs/reviews/execution-logs/r1-classify-strays-blindspot.txt`, `scripts/crb-materialize.py:199-215`

---

## Claim 33: "Raises RuntimeError — i.e. VOIDS the cell — only for contamination: a surviving remote, or a commit reachable outside the reviewed head's ancestry."

**Location:** `scripts/crb-materialize.py:222-224`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the wording of the raise conditions; the immediately following sentence ("Agent-authored commits on top of the head are reset, not voided") disambiguates, so the docstring is not self-contradictory in practice.

Same imprecision as Claim 5 — the implemented condition is "not descended from head", and there is a third raise path the sentence omits: `sh()` itself raises on any failing git command, e.g. a corrupt clone.

```python
# scripts/crb-materialize.py:67-69
    if check and r.returncode != 0:
        raise RuntimeError(f"{' '.join(args)} failed ({r.returncode}): "
                           f"{(r.stderr or '').strip()[:500]}")
```

**Evidence:** `scripts/crb-materialize.py:63-70`, `scripts/crb-materialize.py:231-239`

---

## Claim 34: "it replaced `git checkout -- .` + `git clean -qfdx`, which restored *tracked files from the index* and so undid neither a commit nor a `git add`. Both survivals were silent: the containment check inspects refs and remotes, not the index."

**Location:** `scripts/crb-materialize.py:226-229`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the git semantics, the replaced commands, and that `verify_containment()` reads no index state; does not quantify how often this occurred.

The git semantics are demonstrated in Claim 6's log. `verify_containment()` consults `rev-list`, `remote`, and `diff main review` only — no `git status`, no index read:

```python
# scripts/crb-materialize.py:184-193
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
...
    remotes = sh(["git", "remote"], cwd=dst)
...
    stat = sh(["git", "diff", "--shortstat", "main", "review"], cwd=dst)
```

(The commit half was *not* silent, though: a commit did raise the stray-commit error — the docstring's own next paragraph and `run-host.sh:349-352` describe that. Read as "silent with respect to the index", which is what the sentence says, the claim holds.)

**Evidence:** `docs/reviews/execution-logs/r1-old-reset-semantics.txt`, `scripts/crb-materialize.py:182-196`

---

## Claim 35: "-B moves `review` back onto the pinned head from wherever HEAD now is; --force discards worktree state; the explicit reset --hard then guarantees the index matches too"

**Location:** `scripts/crb-materialize.py:241-243`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three commands' combined effect on ref, worktree and index; does not establish behaviour when the clone is in a detached-HEAD-with-conflicts state.

```python
# scripts/crb-materialize.py:244-246
    sh(["git", "checkout", "--force", "--quiet", "-B", "review", head], cwd=dst)
    sh(["git", "reset", "--hard", "--quiet", head], cwd=dst)
    sh(["git", "branch", "--quiet", "-f", "main", base], cwd=dst)
```

The index and worktree effects are pinned by passing fixtures:

```
# docs/reviews/execution-logs/r1-bats-crb.txt
ok 17 an agent commit on top of the reviewed head is reset, not voided
ok 19 a staged edit to a tracked file is undone
ok 23 main is restored if the agent deletes or moves it
```

Same command/provenance as Claim 7.

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `scripts/crb-materialize.py:244-246`

---

## Claim 36: "Same scrub materialize() performs, so a branch or tag the agent created cannot linger into the next cell"

**Location:** `scripts/crb-materialize.py:247-248`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the two ref-scrub loops are equivalent; does not cover the reflog/gc steps, which `materialize()` performs and `reset_clone()` does not (unreachable objects therefore linger, though no ref points at them).

The loops are textually identical apart from formatting:

```python
# scripts/crb-materialize.py:249-252 (reset_clone)
    for ref in sh(["git", "for-each-ref", "--format=%(refname)",
                   "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines():
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
```

```python
# scripts/crb-materialize.py:293-297 (materialize)
    refs = sh(["git", "for-each-ref", "--format=%(refname)",
               "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines()
    for ref in refs:
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
```

```
# docs/reviews/execution-logs/r1-bats-crb.txt
ok 22 a branch the agent created is pruned
```

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `scripts/crb-materialize.py:249-252`, `scripts/crb-materialize.py:293-297`

---

## Claim 37: "--verify … (read-only)" / "--reset … undoes agent commits/edits, voids only on contamination (used by run-host.sh before and after each review cell)"

**Location:** `scripts/crb-materialize.py:335-341`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the help strings against the implementation and against which flag `run-host.sh` calls; does not evaluate the CLI's mutual-exclusion behaviour when both flags are passed (argparse rejects it — both are in the same group).

`run-host.sh` calls `--reset` at both sites (`run-host.sh:262`, `run-host.sh:359`) and `--verify` nowhere:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:262
  python3 "$ROOT/scripts/crb-materialize.py" --reset "$id" || {
```

Read-only-ness of `--verify` is established in Claim 1.

**Evidence:** `scripts/crb-materialize.py:335-341`, `runs/review-arms/crb-pipeline/run-host.sh:262`, `runs/review-arms/crb-pipeline/run-host.sh:359`

---

## Claim 38: "The subset is defined as 'PRs our tool has a judged row for', which means a cell that produced nothing injectable removes itself from the denominator without appearing anywhere in this table."

**Location:** `scripts/crb-subset-leaderboard.py:40-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers how `urls` is derived and the resulting silent-drop property; does not evaluate the statistical bias argument (a claim about inference, not code).

```python
# scripts/crb-subset-leaderboard.py:138-140
    our_urls = sorted(u for u, tools in evals.items() if args.tool in tools)
    urls = sorted(evals) if args.all_prs else our_urls
```

A PR with no row for `args.tool` never enters `our_urls`, so it contributes to neither numerator nor denominator.

**Evidence:** `scripts/crb-subset-leaderboard.py:136-141`

---

## Claim 39: "Attrition is always measured against the PRs OUR tool was judged on, even under --all-prs"

**Location:** `scripts/crb-subset-leaderboard.py:136-138`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers which variable is passed to `attrition()`; does not cover the display scoping of the table itself.

```python
# scripts/crb-subset-leaderboard.py:169
    att_lines, _checked = attrition(our_urls, Path(args.run_meta))
```

```
# docs/reviews/execution-logs/r1-bats-crb.txt
ok 30 attrition is reported under --all-prs too (subset scope is not the question)
```

Same command/provenance as Claim 7.

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `scripts/crb-subset-leaderboard.py:169`

---

## Claim 40: "Attrition goes to stderr like the skew warning AND into the markdown body"

**Location:** `scripts/crb-subset-leaderboard.py:164-167`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both output surfaces; does not cover whether the markdown quoting survives every downstream renderer.

```python
# scripts/crb-subset-leaderboard.py:169-172
    att_lines, _checked = attrition(our_urls, Path(args.run_meta))
    for line in att_lines:
        print(line, file=sys.stderr)
```

plus the `> `-quoted block inside `if args.markdown:` (quoted in Claim 13), pinned by `ok 31` in the same bats log.

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `scripts/crb-subset-leaderboard.py:169-176`

---

## Claim 41: "Written by run-host.sh. The leaderboard reads it to tell 'we ranked on 3 PRs' apart from 'we asked for 5 and 2 fell out'"

**Location:** `scripts/crb_common.py:28-32`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the path agreement between writer and reader and the field names each side uses; does not cover the case where a sweep is run with a non-default `OUT`.

The constant and the writer resolve to the same path:

```python
# scripts/crb_common.py:32
RUN_META = WORKSPACE / "runs/review-arms/crb-pipeline/run-meta.json"
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:54
OUT="$ROOT/runs/review-arms/crb-pipeline"
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:163
  python3 - "$OUT/run-meta.json" "$PAYLOAD_REF" "$PAYLOAD_SHA" "$MODEL" \
```

Field names agree in both directions — the writer emits `cells`, `requested_instances`, `voided_cells`, `missing_cells` (`run-host.sh:207-212`) and the reader consumes `cells`, `requested_instances`, `voided_cells`:

```python
# scripts/crb-subset-leaderboard.py:58-61
    cells = meta.get("cells") or {}
    requested = meta.get("requested_instances") or sorted(cells)
    voided = set(meta.get("voided_cells") or [])
```

`missing_cells` is written but not read — the reader recomputes the same set as `slug not in cells`, so there is no silent under-report.

**Evidence:** `scripts/crb_common.py:28-32`, `runs/review-arms/crb-pipeline/run-host.sh:54`, `runs/review-arms/crb-pipeline/run-host.sh:207-212`, `scripts/crb-subset-leaderboard.py:58-73`

---

## Claim 42: "32 cells, of which exactly 3 are known-bad: one budget exhaustion and two quota stubs" (`complete=29 incomplete=3`)

**Location:** `test/crb-cell-status.bats:170-175`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the split and the identity of the three incomplete cells at this commit; does not establish that the split is correct as a matter of judgement (only that the assertion matches the predicate's actual output).

Running the predicate over the corpus independently of the test harness reproduces the split and names the same three:

```
# docs/reviews/execution-logs/r1-corpus-dump.txt
complete 29 incomplete 3
  ('runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json', "is_error=true subtype='error_max_budget_usd'")
  ('runs/review-arms/e7-fable-3x/mfc-postfix/rep2/result.json', 'body is 56 chars, under the 200-char floor')
  ('runs/review-arms/e7-fable-3x/mfc-postfix/rep3/result.json', 'body is 51 chars, under the 200-char floor')
```

and the bats assertion passes (`ok 15 verdicts on all checked-in result.json files are unchanged`).

Command: `python3` driver invoking `scripts/crb-cell-status.py` per file, cwd `/workspace`, exit 0, 2026-08-19T02:44Z.

**Evidence:** `docs/reviews/execution-logs/r1-corpus-dump.txt`, `docs/reviews/execution-logs/r1-bats-crb.txt`, `test/crb-cell-status.bats:170-175`

---

## Claim 43: "Hermetic: builds throwaway git repos in BATS_TEST_TMPDIR, no network, no clones, and never touches external/crb-eval or the real manifest."

**Location:** `test/crb-containment-reset.bats:19-20`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers absence of manifest/clone references and of network calls in the suite; does not prove hermeticity under a different `git` config (e.g. a global `url.insteadOf`).

A grep for `crb-eval`, `instances.json`, `MANIFEST`, `curl`, and `http` in this file returns one hit only — a remote *added* to a fixture and never fetched from (paraphrased — no quote available because the claim covers the absence of matches; the single positive hit is quoted below):

```bash
# test/crb-containment-reset.bats:146
  git -C "$CLONE" remote add origin https://example.invalid/x.git
```

Fixtures are built under `BATS_TEST_TMPDIR`:

```bash
# test/crb-containment-reset.bats:28-29
  export CLONE="$BATS_TEST_TMPDIR/clone"
  rm -rf "$CLONE"; mkdir -p "$CLONE"
```

The suite passes offline (tests 16–26 in the bats log; same command/provenance as Claim 7).

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `test/crb-containment-reset.bats:19-20`, `test/crb-containment-reset.bats:28-29`, `test/crb-containment-reset.bats:146`

---

## Claim 44: "the load-bearing assertions here are the two negatives — a re-added remote and a commit outside the reviewed ancestry must still fail"

**Location:** `test/crb-containment-reset.bats:14-17`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both named negatives exist and pass; does not assert they are exhaustive (Claim 4 identifies an uncovered contamination path).

Same evidence as Claim 7 (`ok 24`, `ok 25`, plus the `ok 26` tag variant).

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `test/crb-containment-reset.bats:14-17`

---

## Claim 45: "Hermetic: synthetic evaluations/run-meta in BATS_TEST_TMPDIR. It does read the real runs/review-arms/crb/instances.json for the slug -> PR-url mapping, which is the same coupling the script has in production and is read-only."

**Location:** `test/crb-subset-attrition.bats:15-17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the declared manifest coupling and that it is read-only; does not establish the suite still passes if the manifest's slug set changes.

The manifest is exported and passed as an input to two Python generators:

```bash
# test/crb-subset-attrition.bats:22
  export MANIFEST="$REPO_ROOT/runs/review-arms/crb/instances.json"
```

```bash
# test/crb-subset-attrition.bats:29
  python3 - "$MANIFEST" "$1" "$TOOL" "$BATS_TEST_TMPDIR/evaluations.json" <<'PY'
```

and the script itself reads the same file (`scripts/crb-subset-leaderboard.py:57`, `MANIFEST.read_text()`), so the coupling claim holds. Tests 27–32 pass; same command/provenance as Claim 7.

**Evidence:** `docs/reviews/execution-logs/r1-bats-crb.txt`, `test/crb-subset-attrition.bats:15-29`, `scripts/crb-subset-leaderboard.py:57`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`docs/working/crb-direction1-setup.md:104-108`): "a commit on top of the reviewed head cannot contain the answer key — there is no remote to fetch it from" — `git fetch <URL>` needs no configured remote, the review container has unrestricted network and `--dangerously-skip-permissions`, and a descendant commit carrying fetched content is classified safe and silently reset. Restate as a narrower guarantee, or add a control (e.g. `--network none` on the review container, or content-level diffing against the pinned head's tree).
- **Claim 11c** (`docs/working/crb-direction1-setup.md:144-145`): "a docker failure" still leaves the provenance file — the per-cell `docker run` failure is `||`-guarded (never exits), and the one unguarded docker call (line 113) precedes the trap's installation. Drop the docker case or name the specific failure it means.
- **Claim 15b** (`runs/review-arms/crb-pipeline/run-host.sh:158`): in-code twin of 11c — "a docker failure had the same hole" is not true of either docker call site.
- **Claim 22** (`scripts/crb-cell-status.py:9-12`): "Both directions have already happened in this repo's arms" — only the false-complete direction is attested; `e5-cc-builtin`'s runner has no resume predicate, so its eight `num_turns == 0` cells were never re-paid.
- **Claim 28** (`scripts/crb-cell-status.py:36-40`): "the shortest real review in the corpus is over 3 KB … 1000 sits an order of magnitude clear of both" — the corpus minimum is 1,208 chars, so `STUB_MAX_LEN = 1000` has ~20% headroom, not 10×. This is the quantity that justifies the pre-mortem-N5 fix; restate it, and decide deliberately whether 1000 is still the right threshold given a 1.2 KB floor.
- **Claim 32** (`scripts/crb-materialize.py:204-208`): in-code twin of Claim 4 — "with no remote there is no route to fetch it".

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`docs/working/crb-direction1-setup.md:108-110`): "any commit reachable outside the reviewed head's ancestry still voids" — the implemented condition is "not descended from head"; agent commits are reachable outside head's ancestry and do not void.
- **Claim 9** (`docs/working/crb-direction1-setup.md:127-129`): "3–7 KB" — actual range 2.7–7.1 KB.
- **Claim 16** (`runs/review-arms/crb-pipeline/run-host.sh:202-205`): "appears here and nowhere else" — such a slug also appears in `missing_cells` in the same file.
- **Claim 25** (`scripts/crb-cell-status.py:19-20`): same 3–7 KB imprecision as Claim 9.
- **Claim 26** (`scripts/crb-cell-status.py:21-23`): the 51-char stub is a *session* limit, not a weekly limit; both spellings are already handled in code.
- **Claim 33** (`scripts/crb-materialize.py:222-224`): same ancestry-wording imprecision as Claim 5, plus an unmentioned third raise path (`sh()` raising on any failing git command).

### Unverifiable
- **Claim 27** (`scripts/crb-cell-status.py:27-35`), partially: "the 32-file corpus contains no auth-domain reviews" is verdicted Verified on substring evidence (no real review contains "log in"/"logged in"), but "auth-domain" as a topical property of the mfc-* corpus cannot be settled from the artifacts alone — the reviewed diffs are not checked in. Confirming it would need the per-instance prompts (gitignored).

---

## Goal-Alignment Note
- Answered: yes — 45 claims verdicted across all 9 files in cf6e7c9, with all 12 orchestrator-nominated claims covered.
- Out of scope: code-quality observations noticed while tracing (unrapped `PF_HOME`/`INST_HOME` temp dirs; `reset_clone()` skipping the `reflog expire`/`gc` that `materialize()` runs, so unreachable agent objects linger) — set aside as reviewer, not fact-checker, concerns.
- Escalate: (1) Claim 4/32 is a security-relevant invariant that the code does not establish — hand to `security-reviewer`, alongside the still-open R3 (no `--network` restriction on the review container); (2) Claim 28's 1.2 KB corpus floor may warrant re-picking `STUB_MAX_LEN`, not just re-wording the comment; (3) this report overwrote the previous `docs/reviews/code-fact-check-report-r1.md` (a fact-check of the same branch at 90de392, recoverable at commit `ae3362b`) — if both are wanted, rename one.

