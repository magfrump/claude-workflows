# Code Fact-Check Report

Commit: cf6e7c9

**Repository:** /workspace (branch `feat/crb-direction1-harness`)
**Scope:** commit `cf6e7c9` only (`git diff HEAD~1..HEAD`) — docs/working/crb-direction1-setup.md, runs/review-arms/crb-pipeline/run-host.sh, scripts/crb-cell-status.py, scripts/crb-materialize.py, scripts/crb-subset-leaderboard.py, scripts/crb_common.py, test/crb-cell-status.bats, test/crb-containment-reset.bats, test/crb-subset-attrition.bats. **Partial scope:** work on the branch outside this commit is context, not under review.
**Checked:** 2026-08-18
**Total claims checked:** 30
**Summary:** 21 verified, 5 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

Hallucination-pattern log read before starting (`docs/reviews/hallucination-patterns.md`, one entry: fabricated `total_golden` denominators in a CRB doc caveat). No claim in this commit matches that pattern; the quantitative corpus claims here were all re-derived from the checked-in artifacts rather than restated, and the ones that are wrong are wrong by measurement drift, not by fabrication.

Execution logs for the `executed` claims:
`docs/reviews/execution-logs/r2-corpus-survey.txt`,
`docs/reviews/execution-logs/r2-bats-crb.txt`,
`docs/reviews/execution-logs/r2-trap-semantics.txt`,
`docs/reviews/execution-logs/r2-fetch-without-remote.txt`.

---

## Claim 1: "The clone is reset with `crb-materialize.py --reset <slug>` after harvesting, so re-runs start from the same state"

**Location:** `docs/working/crb-direction1-setup.md:89-90`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the post-harvest reset in run-host.sh is the `--reset` call; does not establish that `reset_clone()` restores every possible piece of state (see Claim 20).
**Legibility-target:** for-orchestrator-synthesis

The post-harvest step is exactly that call, and it runs after the artifact-harvest loop:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:359
if ! python3 "$ROOT/scripts/crb-materialize.py" --reset "$id"; then
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:324-359`

---

## Claim 2: "a commit on top of the reviewed head cannot contain the answer key — there is no remote to fetch it from"

**Location:** `docs/working/crb-direction1-setup.md:106-108`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated mechanism (absence of a configured remote ⇒ no fetch route); does not establish that contamination actually occurred in any run, nor that the container's egress is unrestricted in the user's docker configuration.
**Legibility-target:** for-author

This is the doc-side statement of the same mechanism as Claim 18b; see that claim for the executed refutation. Removing the remote does not remove the fetch route: `git fetch <url> <ref>` works in a repository with zero configured remotes, and the fetched history lands in `FETCH_HEAD` — invisible to both `git remote` and `git rev-list --all`:

```
# docs/reviews/execution-logs/r2-fetch-without-remote.txt
remotes: []
fetch-by-URL exit=0
FETCH_HEAD content visible:
c637faa the answer key
THE MERGED FIX
rev-list --all --not HEAD => []
git remote after fetch: []
```

The container is started with no `--network` flag and with `--dangerously-skip-permissions`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:274-285
docker run --rm -u node -w /repo \
    -e ANTHROPIC_API_KEY \
    -v "$clone":/repo \
...
      --dangerously-skip-permissions \
```

so the default bridge network (with egress) applies. The practical conclusion — that the *expected* case, an agent committing its own rubric, is benign — is not what this claim says; it asserts an impossibility that the code does not enforce. A commit that merges fetched upstream history would still descend from the head and would therefore be classified as agent work.

**Evidence:** `docs/working/crb-direction1-setup.md:106-108`, `runs/review-arms/crb-pipeline/run-host.sh:274-285`, `docs/reviews/execution-logs/r2-fetch-without-remote.txt` (cwd `$TMPDIR/fetchtest`, exit 0, 2026-08-18T19:45:30-07:00)

---

## Claim 3: "The old reset (`git checkout -- . && git clean -qfdx`) restored tracked files *from the index*, so it undid neither a commit nor a `git add`"

**Location:** `docs/working/crb-direction1-setup.md:110-114`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the pre-cf6e7c9 reset did and git's documented semantics for `checkout -- .`; does not establish that a commit was in fact left behind by any historical run.
**Legibility-target:** for-orchestrator-synthesis

The previous version of the file did exactly those two commands and nothing else:

```bash
# git show HEAD~1:runs/review-arms/crb-pipeline/run-host.sh (removed hunk)
  git -C "$clone" checkout -- . 2>/dev/null || true
  git -C "$clone" clean -qfdx 2>/dev/null || true
```

`git checkout -- <paths>` copies from the index to the worktree, and `git clean` only removes untracked files, so neither touches `HEAD`, a branch tip, or staged content (paraphrased — no quote available because the claim is about documented git semantics, not about a snippet in this repo). The follow-on assertion that the containment check "reads refs and remotes, not the index" is borne out by `verify_containment`, which consults only `rev-list`, `git remote`, and a diff:

```python
# scripts/crb-materialize.py:184-193
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
...
    remotes = sh(["git", "remote"], cwd=dst)
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:345-353` (the replacement comment), `scripts/crb-materialize.py:184-196`, `git show HEAD~1:runs/review-arms/crb-pipeline/run-host.sh`

---

## Claim 4: "two pilot instances are auth-domain (`keycloak-PR36880`, `cal_com-PR11059`)"

**Location:** `docs/working/crb-direction1-setup.md:123-125` (same claim at `scripts/crb-cell-status.py:33-38`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named slugs' presence and PR titles in the checked-in manifest; does not establish that the reviews of those PRs would in fact contain the phrase "logged in".
**Legibility-target:** for-orchestrator-synthesis

The manifest holds exactly five instances, two of which are auth-domain by title:

```
# runs/review-arms/crb/instances.json, read via python3 (see log)
cal_com-PR11059  | OAuth credential sync and app integration enhancements
keycloak-PR36880 | Add Client resource type and scopes to authorization schema
```

**Evidence:** `runs/review-arms/crb/instances.json`, `docs/reviews/execution-logs/r2-corpus-survey.txt` (manifest read run in cwd `/workspace`, exit 0, 2026-08-18T19:43-07:00)

---

## Claim 5: "8 real cells in this repo are genuine successes with `num_turns == 0` and 3–7 KB of review text"

**Location:** `docs/working/crb-direction1-setup.md:127-129` (same claim at `scripts/crb-cell-status.py:20-21`)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, the `num_turns` value, and the body-length range of the e5-cc-builtin cells; does not establish that those bodies are substantively good reviews.
**Legibility-target:** for-author

The count (8), `num_turns == 0`, and `is_error=false`/`subtype=success` all hold. The range is slightly wider at the bottom than stated — one cell is 2733 chars (2.7 KB), not ≥3 KB:

```
# docs/reviews/execution-logs/r2-corpus-survey.txt
e5-cc-builtin cells: 8 lengths: [2733, 3435, 3720, 3758, 4381, 4651, 4918, 7121]
```

Precise version: "2.7–7 KB". Nothing downstream depends on the low end (the floor is 200 chars), so this is imprecision, not a mechanism error.

**Evidence:** `docs/reviews/execution-logs/r2-corpus-survey.txt` (cmd: inline `python3` survey, cwd `/workspace`, exit 0, 2026-08-18T19:50-07:00)

---

## Claim 6: "`runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json`: `is_error: true`, `subtype: "error_max_budget_usd"`, `num_turns: 1`, `$15.24` spent"

**Location:** `docs/working/crb-direction1-setup.md:130-133` (same claim, minus `num_turns`, at `scripts/crb-cell-status.py:18-19`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named field values in that one file; does not establish the claim in the same sentence that "the old turns-only predicate banked exactly that" (no such predicate is present in the tree to run).
**Legibility-target:** for-orchestrator-synthesis

```
# docs/reviews/execution-logs/r2-corpus-survey.txt
INCOMPLETE runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json | is_error=True subtype='error_max_budget_usd' turns=1 len=0 cost=15.240262000000001
```

$15.240262 rounds to $15.24.

**Evidence:** `runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json`, `docs/reviews/execution-logs/r2-corpus-survey.txt`

---

## Claim 7a: "`run-meta.json` is written from an `EXIT` trap, so the budget halt and a `Ctrl-C` still leave the provenance file"

**Location:** `docs/working/crb-direction1-setup.md:143-146`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2 EXIT-trap execution on `exit 2` from inside a loop and on an uncaught SIGINT; does not establish behaviour under `SIGKILL`, nor that `write_run_meta`'s python body succeeds (it is `|| true`-guarded and would fail silently).
**Legibility-target:** for-orchestrator-synthesis

The budget gate does exit from inside the loop, and the writer is now a trapped function:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:404
python3 - "$OUT" "$SWEEP_BUDGET" <<'EOF' || { echo "SWEEP BUDGET EXCEEDED — stopping. Raise SWEEP_BUDGET to continue." >&2; exit 2; }
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:220
trap 'write_run_meta; rm -rf "$PAYLOAD_SRC"' EXIT
```

Both cases were executed against a minimal reproduction on the same bash (5.2.15):

```
# docs/reviews/execution-logs/r2-trap-semantics.txt
started
TRAP-B
...
cell 1
budget exceeded
TRAP-RAN
t2 exit=2
```

`TRAP-B` printed after `kill -INT`, i.e. the EXIT trap does run when bash is terminated by an untrapped SIGINT; `TRAP-RAN` printed on the `exit 2`-from-inside-a-loop case. `META_WRITTEN` guards the double-write when the loop completes normally and `write_run_meta` is also called at line 432.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:159-162,220,404,432`, `docs/reviews/execution-logs/r2-trap-semantics.txt` (cwd `$TMPDIR`, exit 0, 2026-08-18T19:44:44-07:00)

---

## Claim 7b: "... and a docker failure all still leave the provenance file"

**Location:** `docs/working/crb-direction1-setup.md:143-146`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which docker invocations are inside vs outside the trap's lifetime; does not establish what a partially-written `run-meta.json` would contain.
**Legibility-target:** for-author

True for the per-cell docker call, which is failure-tolerant and happens after the trap is installed:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:286-287
    > "$dest/transcript.jsonl" 2> "$dest/stderr.log" || {
      echo "$id: claude exited non-zero — see $dest/stderr.log" >&2; }
```

Not true for the two docker invocations that run *before* the trap is replaced at line 220 — the npm-cache chown at line 113 (unguarded, so `set -e` aborts) and the preflight at lines 124-131 (whose failure path is `exit 1` at line 132). Those exits fire only the payload-only trap installed at line 97, which does not write run-meta:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:97
trap 'rm -rf "$PAYLOAD_SRC"' EXIT
```

Precise version: "a docker failure *during a cell*". No cells have run at the earlier point, so nothing is lost in practice — the imprecision is in the scope of "all", not in the mechanism.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:97,113,124-132,220,286-287`

---

## Claim 8: "The script now cross-checks the judged subset against `run-meta.json`'s `requested_instances`, names every missing cell with its reason, and repeats the warning inside `--markdown`"

**Location:** `docs/working/crb-direction1-setup.md:234-239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three asserted behaviours as exercised by the checked-in bats suite; does not establish behaviour on a real sweep's run-meta (none exists yet at `runs/review-arms/crb-pipeline/run-meta.json`).
**Legibility-target:** for-orchestrator-synthesis

The cross-check reads that exact field and emits one line per lost slug:

```python
# scripts/crb-subset-leaderboard.py:56-73
    requested = meta.get("requested_instances") or sorted(cells)
...
        lost.append(f"     {slug:28} {why}")
```

and the markdown branch re-emits the same lines as a blockquote:

```python
# scripts/crb-subset-leaderboard.py:174-177
        for note in ([warn] if warn else []) + ([("\n".join(att_lines))] if att_lines else []):
            print("> " + note.replace("\n", "\n> ") + "\n")
```

All six attrition tests pass, including the markdown one (`> !! SUBSET ATTRITION`) and the `--all-prs` one:

```
# docs/reviews/execution-logs/r2-bats-crb.txt
ok 31 attrition appears in the markdown body, not only on stderr
ok 32 a missing run-meta says attrition was NOT checked rather than staying silent
```

**Evidence:** `scripts/crb-subset-leaderboard.py:40-79,164-177`, `docs/reviews/execution-logs/r2-bats-crb.txt` (cmd `bats test/crb-cell-status.bats test/crb-containment-reset.bats test/crb-subset-attrition.bats`, cwd `/workspace`, exit 0, 2026-08-18T19:43-07:00)

---

## Claim 9: "it used to sit inline after the loop: the SWEEP_BUDGET gate below exits 2 from INSIDE the loop, so ... wrote no run-meta.json at all"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:152-158`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pre-cf6e7c9 placement of the run-meta writer and the gate's exit path; does not establish that a real sweep ever hit the ceiling.
**Legibility-target:** for-orchestrator-synthesis

The prior version had the writer as a bare heredoc after `done`, with the same `exit 2` gate inside the loop:

```bash
# git show HEAD~1:runs/review-arms/crb-pipeline/run-host.sh (removed hunk)
done

# Sweep-level provenance: which payload actually ran (review-canon section 3).
python3 - "$OUT/run-meta.json" "$PAYLOAD_REF" ... <<'EOF'
```

The accompanying sub-claim that the default ceiling "sits under the setup doc's own $500-2000 estimate" also holds: `SWEEP_BUDGET="${SWEEP_BUDGET:-250.00}"` (`run-host.sh:68`) versus the doc's `| All 50 | **~$500–2000** |` (`docs/working/crb-direction1-setup.md:247`).

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:68,404`, `docs/working/crb-direction1-setup.md:247`, `git show HEAD~1:runs/review-arms/crb-pipeline/run-host.sh`

---

## Claim 10: "Replaces the payload-only trap set above: both jobs, one handler."

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:219-220`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers trap replacement semantics and `PAYLOAD_SRC` cleanup on every exit path in this script; does not cover cleanup of the per-instance `INST_HOME` temp dir, which is removed inline and is not part of either trap.
**Legibility-target:** for-orchestrator-synthesis

A second `trap ... EXIT` replaces rather than appends — the reproduction registered two handlers and only the second ran:

```
# docs/reviews/execution-logs/r2-trap-semantics.txt
started
TRAP-B
```

`PAYLOAD_SRC` cleanup survives on every path: the first trap (`run-host.sh:97`) is installed on the line after `PAYLOAD_SRC=$(mktemp -d)` and covers the `DRY_RUN` exit (line 108), the missing-key exit (line 109) and the preflight exit (line 132); from line 220 onward the replacement handler still ends with `rm -rf "$PAYLOAD_SRC"`.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:96-97,105-109,132,220`, `docs/reviews/execution-logs/r2-trap-semantics.txt`

---

## Claim 11: "requested_instances is what the sweep was ASKED to do. A slug that never got far enough to write a result.json (missing clone, pre-run containment failure) appears here and nowhere else"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:202-205`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where a never-run slug does and does not appear in the emitted JSON; does not establish that `INSTANCES` is always whitespace-safe (slugs from `$@` are not charset-validated by this script).
**Legibility-target:** for-author

The mechanism holds: a missing clone `continue`s before `mkdir -p "$dest"` (`run-host.sh:224-225`), so no `result.json` exists and the slug is absent from `cells`. But the same slug also appears in a second field of the same file, `missing_cells`, which is derived from `req` in the very next line:

```python
# runs/review-arms/crb-pipeline/run-host.sh:209-210
           "requested_instances": req,
           "missing_cells": [s for s in req if s not in cells],
```

Precise version: "appears in `requested_instances`/`missing_cells` and in no per-cell record".

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:202-213,224-225,253`

---

## Claim 12: "`git checkout -- .` restores tracked files FROM THE INDEX: neither a commit nor a `git add` was undone by it ... a commit ... voided the cell AND left the clone permanently failing its pre-run check"

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:345-353`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure mode of the removed reset and the fact that the new one clears it; does not establish that the historical failure was observed in a real sweep.
**Legibility-target:** for-orchestrator-synthesis

The "permanently failing" half is directly testable and is pinned by the new suite: with the old reset an agent commit left a stray, and `verify_containment` raises on any stray (`scripts/crb-materialize.py:184-187`). The new path resets it, and re-running the pre-run check on the following cell passes:

```
# docs/reviews/execution-logs/r2-bats-crb.txt
ok 18 the clone still verifies on the NEXT cell after an agent commit
```

The "CLAUDE.md instructs the agent to make [a commit]" sub-claim also holds — the payload includes the repo's `CLAUDE.md`, mounted at `/home/node/.claude` (`run-host.sh:98,277`), and that file says:

```
# CLAUDE.md:255
  - When in doubt, commit. Small commits are cheap; large unstaged changes are expensive to review and recover.
```

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:98,277,345-359`, `scripts/crb-materialize.py:184-187`, `CLAUDE.md:255`, `docs/reviews/execution-logs/r2-bats-crb.txt`

---

## Claim 13: "Exit 0 = complete (run-host.sh skips the cell); exit 1 = incomplete (re-run)."

**Location:** `scripts/crb-cell-status.py:4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's exit codes and the runner's branch on them; does not cover the `MAX_ATTEMPTS` path that can turn "incomplete" into "skipped as unusable" rather than a re-run.
**Legibility-target:** for-orchestrator-synthesis

```python
# scripts/crb-cell-status.py:79-80
    ok, reason = status(d)
    print(reason)
    return 0 if ok else 1
```

and the runner branches on the exit status, skipping on 0:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:233-236
    if cell_status=$(python3 "$ROOT/scripts/crb-cell-status.py" "$dest/result.json" 2>&1); then
      echo "=== $id — completed result exists, skipping (delete to re-run)"
```

Observed exit codes over all 32 checked-in artifacts are 0/1 as described (see log).

**Evidence:** `scripts/crb-cell-status.py:70-84`, `runs/review-arms/crb-pipeline/run-host.sh:231-251`, `docs/reviews/execution-logs/r2-corpus-survey.txt`

---

## Claim 14: "Measured against the 32 result.json files under runs/review-arms/ (see test/crb-cell-status.bats, which asserts this script's verdict on all of them)"

**Location:** `scripts/crb-cell-status.py:14-16`; the corresponding assertion is `test/crb-cell-status.bats:172-175` ("complete=29 incomplete=3" plus the three named cells)
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file count, the 29/3 split, and the identity of the three incomplete cells; does not establish that the corpus is representative of the CRB PRs the sweep will run.
**Legibility-target:** for-orchestrator-synthesis

```
# docs/reviews/execution-logs/r2-corpus-survey.txt
total result.json: 32
...
complete 29 incomplete 3
```

The three incomplete ones are exactly the cells the test names — `e7-fable-3x/mfc-hygiene/rep1` (is_error), `e7-fable-3x/mfc-postfix/rep2` (56 chars), `e7-fable-3x/mfc-postfix/rep3` (51 chars) — and the bats corpus-pin test passes:

```
# docs/reviews/execution-logs/r2-bats-crb.txt
ok 15 verdicts on all checked-in result.json files are unchanged
```

**Evidence:** `test/crb-cell-status.bats:148-176`, `docs/reviews/execution-logs/r2-corpus-survey.txt`, `docs/reviews/execution-logs/r2-bats-crb.txt`

---

## Claim 15: "2 e7 cells report subtype=success, is_error=false, num_turns=0 with a 51-56 char body that is actually 'You've hit your weekly limit'"

**Location:** `scripts/crb-cell-status.py:22-24`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the field values and exact bodies of the two `mfc-postfix` cells; does not establish that the quota wording is stable across CLI versions.
**Legibility-target:** for-author

The count, fields and lengths are exact (56 and 51 chars, `subtype='success'`, `is_error=False`, `turns=0`). The quoted body is right for one of the two; the other is a *session* limit:

```
# docs/reviews/execution-logs/r2-corpus-survey.txt (bodies printed during the survey)
"You've hit your weekly limit · resets Aug 18, 12am (UTC)"
"You've hit your session limit · resets 5:10am (UTC)"
```

`NON_REVIEW` covers both spellings (`"hit your weekly limit", "hit your session limit"`, `scripts/crb-cell-status.py:40-41`), so only the docstring's summary is imprecise.

**Evidence:** `runs/review-arms/e7-fable-3x/mfc-postfix/rep2/result.json`, `runs/review-arms/e7-fable-3x/mfc-postfix/rep3/result.json`, `scripts/crb-cell-status.py:40-41`, `docs/reviews/execution-logs/r2-corpus-survey.txt`

---

## Claim 16: "the two in-repo examples are 51 and 56 characters" / "The 32-file corpus that validated this predicate contains no auth-domain reviews"

**Location:** `scripts/crb-cell-status.py:31-39`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the two stub lengths exactly, and the absence of any `log in`/`logged in` occurrence in the 32 corpus bodies; "auth-domain" is a judgement about subject matter, so the second half is verified only in the operational sense that matters here (no body would trip `NON_REVIEW`).
**Legibility-target:** for-orchestrator-synthesis

Lengths 51/56 are confirmed above. Scanning all 32 bodies for the substrings the predicate keys on returns no hits at all; the single near-miss is the token `auth` inside one 1246-char review:

```
# inline scan, see docs/reviews/execution-logs/r2-corpus-survey.txt for the same corpus
runs/review-arms/e7-fable-3x/mfc-deploy/rep2/result.json ['auth'] 1246
```

(paraphrased — no quote available because the claim covers the *absence* of matches across 32 files, i.e. an empty grep result.)

**Evidence:** `scripts/crb-cell-status.py:31-45`, `docs/reviews/execution-logs/r2-corpus-survey.txt`

---

## Claim 17: "The stubs run to ~56 chars and the shortest real review in the corpus is over 3 KB, so anywhere in between works; 1000 sits an order of magnitude clear of both."

**Location:** `scripts/crb-cell-status.py:42-45`
**Type:** Configuration / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the corpus's actual minimum real-review length against the stated safety margin for `STUB_MAX_LEN = 1000`; does not establish that any real review would in fact contain a `NON_REVIEW` substring, nor that the current threshold has ever misfired.
**Legibility-target:** for-author

The shortest real review in the corpus is 1208 characters, not "over 3 KB", and 22 of the 32 bodies fall in the 1000–3000 char band:

```
# docs/reviews/execution-logs/r2-corpus-survey.txt
shortest body >=200 chars: (1208, 'runs/review-arms/e7-fable-3x/mfc-fscompat/rep1/result.json')
bodies in [1000,3000): 22
```

That body is review prose, not a stub:

```
# runs/review-arms/e7-fable-3x/mfc-fscompat/rep1/result.json (result field, first line)
Review of `main..review` complete — 3 findings reported (1 correctness, 1 docs, 1 test-coverage), ranked above.
```

So `STUB_MAX_LEN = 1000` clears the shortest observed real review by a factor of 1.2, not "an order of magnitude". The threshold's *conclusion* (that no corpus review is currently affected) still holds, but the stated margin does not exist, and the margin is the reason a reader would leave the constant alone. The precise version: "the shortest real review in the corpus is 1208 chars, so 1000 has roughly 20% headroom on the upper side and 5× on the stub side."

**Evidence:** `scripts/crb-cell-status.py:42-45`, `runs/review-arms/e7-fable-3x/mfc-fscompat/rep1/result.json`, `docs/reviews/execution-logs/r2-corpus-survey.txt`

---

## Claim 18: "This floor is what actually rejects both stubs in the corpus (51 and 56 chars) — NON_REVIEW is never consulted for them. The substring list therefore only governs the 200-1000 char band ... asserted in test/crb-cell-status.bats"

**Location:** `scripts/crb-cell-status.py:47-53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the control flow that decides which rule rejects the two corpus stubs and the tests that pin it; does not cover whether the 200-char floor is the right value.
**Legibility-target:** for-orchestrator-synthesis

The floor is checked first and returns before the substring branch:

```python
# scripts/crb-cell-status.py:62-70
    if len(r) < MIN_REVIEW_LEN:
        return False, f"body is {len(r)} chars, under the {MIN_REVIEW_LEN}-char floor"
    if len(r) < STUB_MAX_LEN:
        low = r.lower()
        hit = next((s for s in NON_REVIEW if s in low), None)
```

Both stubs are rejected with the floor's reason string, not the substring one:

```
# docs/reviews/execution-logs/r2-corpus-survey.txt
INCOMPLETE runs/review-arms/e7-fable-3x/mfc-postfix/rep2/result.json | ... | body is 56 chars, under the 200-char floor
```

and the tests assert the reason, not just the verdict (`test/crb-cell-status.bats:78,84,96,105`), all passing.

**Evidence:** `scripts/crb-cell-status.py:56-72`, `test/crb-cell-status.bats:70-106`, `docs/reviews/execution-logs/r2-corpus-survey.txt`, `docs/reviews/execution-logs/r2-bats-crb.txt`

---

## Claim 19a: "the merged upstream fix is not a descendant of the PR head in this clone"

**Location:** `scripts/crb-materialize.py:200-208`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ref/object state `materialize()` leaves behind; does not establish anything about history added to the clone after materialization.
**Legibility-target:** for-orchestrator-synthesis

`materialize()` fetches only `refs/pull/1/head` into `review`, sets `main` to the merge-base, deletes every other ref, drops the remote, and prunes:

```python
# scripts/crb-materialize.py:281-301
    sh(["git", "fetch", "--quiet", f"--depth={depth}", "origin",
        "refs/pull/1/head:refs/heads/review"], cwd=dst)
...
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    subprocess.run(["git", "remote", "remove", "origin"], cwd=dst, ...)
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
```

A post-PR merged upstream fix is by construction *not* an ancestor-descendant relation the clone contains after that scrub, so any locally-created descendant of `head` cannot be the merged fix (paraphrased — no quote available because the claim is about the absence of objects after `gc --prune=now`, not about a snippet).

**Evidence:** `scripts/crb-materialize.py:280-303`

---

## Claim 19b: "with no remote there is no route to fetch it"

**Location:** `scripts/crb-materialize.py:206-207`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether removing remotes removes the fetch route, and whether a URL-fetch is visible to the guards this file implements; does not establish that any real cell has been contaminated, and does not measure the container's actual egress policy on the user's docker host.
**Legibility-target:** for-author

`git fetch <url> <ref>` succeeds in a repository with zero remotes, and the result is reachable via `FETCH_HEAD` while remaining invisible to both guards used here (`git remote`, `git rev-list --all`):

```
# docs/reviews/execution-logs/r2-fetch-without-remote.txt
remotes: []
fetch-by-URL exit=0
FETCH_HEAD content visible:
c637faa the answer key
THE MERGED FIX
rev-list --all --not HEAD => []
refs: [refs/heads/master]
```

The guards this claim underwrites are exactly those two:

```python
# scripts/crb-materialize.py:210-214
    strays = [l for l in sh(["git", "rev-list", "--all", "--not", head],
                            cwd=dst).splitlines() if l]
```

Because the container runs with network egress and `--dangerously-skip-permissions` (`runs/review-arms/crb-pipeline/run-host.sh:274-285`), the premise "no remote ⇒ no route" does not hold, and therefore the docstring's stronger conclusion — that a descendant stray "cannot contain the answer key" — is not established by the stated mechanism. A reader acting on this comment (e.g. deciding the descendant case needs no further guard) is misled. The narrower true statement: "a descendant commit cannot contain the answer key *unless the agent fetched it by URL*, which neither `classify_strays()` nor `verify_containment()` detects."

**Evidence:** `scripts/crb-materialize.py:199-215`, `runs/review-arms/crb-pipeline/run-host.sh:274-285`, `docs/reviews/execution-logs/r2-fetch-without-remote.txt` (cmd: git init/fetch reproduction, cwd `$TMPDIR/fetchtest`, exit 0, 2026-08-18T19:45:30-07:00)

---

## Claim 20: "Raises RuntimeError — i.e. VOIDS the cell — only for contamination: a surviving remote, or a commit reachable outside the reviewed head's ancestry. Agent-authored commits on top of the head are reset, not voided."

**Location:** `scripts/crb-materialize.py:218-229`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `reset_clone()`'s own raise conditions and the reset of commits/staged edits/branches/tags/`main`; does not cover exceptions raised by the `sh()` git calls themselves (a git failure would also propagate and void), nor `verify_containment()`'s separate raises.
**Legibility-target:** for-orchestrator-synthesis

The only two `raise` sites are the remote check and the `foreign` check:

```python
# scripts/crb-materialize.py:231-239
    remotes = sh(["git", "remote"], cwd=dst)
    if remotes:
        raise RuntimeError(...)
    strays, foreign = classify_strays(dst, head)
    if foreign:
        raise RuntimeError(...)
```

The bats suite exercises both directions and all 14 cases pass, including the three "must still VOID" negatives:

```
# docs/reviews/execution-logs/r2-bats-crb.txt
ok 17 an agent commit on top of the reviewed head is reset, not voided
ok 24 a re-added remote still VOIDS the cell
ok 25 a commit outside the reviewed ancestry still VOIDS the cell
ok 26 a tag pointing outside the reviewed ancestry still VOIDS the cell
```

**Evidence:** `scripts/crb-materialize.py:218-259`, `test/crb-containment-reset.bats:63-178`, `docs/reviews/execution-logs/r2-bats-crb.txt`

---

## Claim 21: "-B moves `review` back onto the pinned head from wherever HEAD now is; --force discards worktree state; the explicit reset --hard then guarantees the index matches too (a staged edit is what `checkout -- .` used to keep)."

**Location:** `scripts/crb-materialize.py:241-245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the three commands restore ref, worktree and index for the tested shapes (staged edit, unstaged edit, untracked file, side branch); does not establish behaviour for exotic states such as an in-progress merge or a detached-HEAD bisect.
**Legibility-target:** for-orchestrator-synthesis

```python
# scripts/crb-materialize.py:244-246
    sh(["git", "checkout", "--force", "--quiet", "-B", "review", head], cwd=dst)
    sh(["git", "reset", "--hard", "--quiet", head], cwd=dst)
    sh(["git", "branch", "--quiet", "-f", "main", base], cwd=dst)
```

The staged-edit case is asserted end-to-end (worktree content restored *and* `git status --porcelain` empty):

```
# docs/reviews/execution-logs/r2-bats-crb.txt
ok 19 a staged edit to a tracked file is undone
ok 22 a branch the agent created is pruned
ok 23 main is restored if the agent deletes or moves it
```

**Evidence:** `scripts/crb-materialize.py:240-259`, `test/crb-containment-reset.bats:92-140`, `docs/reviews/execution-logs/r2-bats-crb.txt`

---

## Claim 22: "Same scrub materialize() performs, so a branch or tag the agent created cannot linger into the next cell and read as a stray commit there."

**Location:** `scripts/crb-materialize.py:247-252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ref-deletion loop's equivalence to materialize()'s; does not claim reflog expiry or `gc`, which materialize() also does and `reset_clone()` deliberately does not (neither is consulted by `rev-list --all`).
**Legibility-target:** for-orchestrator-synthesis

The two loops are textually the same predicate:

```python
# scripts/crb-materialize.py:249-252 (reset_clone)
    for ref in sh(["git", "for-each-ref", "--format=%(refname)",
                   "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines():
        if ref not in ("refs/heads/review", "refs/heads/main"):
```

```python
# scripts/crb-materialize.py:293-297 (materialize)
    refs = sh(["git", "for-each-ref", "--format=%(refname)",
               "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines()
    for ref in refs:
        if ref not in ("refs/heads/review", "refs/heads/main"):
```

The "does not linger into the next cell" half is pinned by the repeat-verify test (`ok 18` above) and the branch-prune test (`ok 22`).

**Evidence:** `scripts/crb-materialize.py:247-253,293-297`, `docs/reviews/execution-logs/r2-bats-crb.txt`

---

## Claim 23: "run-host.sh calls this via `--verify`."

**Location:** `scripts/crb-materialize.py:174`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which CLI flag run-host.sh uses to reach `verify_containment()`; does not affect the function's behaviour.
**Legibility-target:** for-author

This commit changed both call sites in the runner from `--verify` to `--reset`, leaving no `--verify` caller:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:262
  python3 "$ROOT/scripts/crb-materialize.py" --reset "$id" || {
```

```bash
# runs/review-arms/crb-pipeline/run-host.sh:359
  if ! python3 "$ROOT/scripts/crb-materialize.py" --reset "$id"; then
```

`verify_containment()` is still reached — `--reset` calls it after `reset_clone()` (`scripts/crb-materialize.py:373-374`) — so the function's role is unchanged; only the named flag is wrong. Precise version: "run-host.sh reaches this via `--reset`; `--verify` is the read-only manual entry point."

**Evidence:** `scripts/crb-materialize.py:168-181,373-374`, `runs/review-arms/crb-pipeline/run-host.sh:262,359`

---

## Claim 24: "`--verify ...` re-assert answer-key containment on existing clone(s) and exit (read-only)" / "`--reset ...` restore clone(s) to the materialized state, then verify — undoes agent commits/edits, voids only on contamination (used by run-host.sh before and after each review cell)"

**Location:** `scripts/crb-materialize.py:335-341` (help text), `scripts/crb-materialize.py:28-29` (module docstring usage block)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether each flag's help matches the implemented dispatch and which one the runner calls; does not cover the `--dry-run`/`--depth` flags, which this commit did not touch.
**Legibility-target:** for-orchestrator-synthesis

Dispatch matches: `resetting` is set only for `--reset`, and `reset_clone()` runs only then, followed by the same `verify_containment()` in both modes:

```python
# scripts/crb-materialize.py:347-349,373-374
    if args.verify or args.reset:
        slugs = args.verify or args.reset
        resetting = bool(args.reset)
...
                note = reset_clone(dst, slug, head, base) if resetting else ""
                n_commits, stat = verify_containment(dst, slug, head)
```

`--verify` is read-only: `verify_containment()` issues only `rev-parse`, `rev-list`, `remote`, and `diff` (`scripts/crb-materialize.py:182-195`). "used by run-host.sh before and after each review cell" is true of `--reset` (lines 262 and 359 of the runner), and the docstring usage block lists both flags (`scripts/crb-materialize.py:28-29`).

**Evidence:** `scripts/crb-materialize.py:28-29,182-196,335-341,347-383`, `runs/review-arms/crb-pipeline/run-host.sh:262,359`

---

## Claim 25: "no manifest entry — cannot pin the reviewed head, so containment is unverifiable"

**Location:** `scripts/crb-materialize.py:366-371`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that a missing `head` (or, under `--reset`, a missing `base`) fails the slug rather than falling through to a weak self-referential check; does not cover the case where the manifest entry exists but records a head the clone has never contained (that fails later, inside `reset_clone`/`verify_containment`).
**Legibility-target:** for-orchestrator-synthesis

The new `base` requirement is guarded in the same branch, and the slug is added to `bad`, which makes the process exit non-zero:

```python
# scripts/crb-materialize.py:364-371
            rec = manifest.get(slug) or {}
            head, base = rec.get("head"), rec.get("base")
            if not head or (resetting and not base):
                print(f"  !! {slug}: no manifest entry — cannot pin the reviewed head, "
...
                bad.append(slug)
                continue
```

```python
# scripts/crb-materialize.py:381-382
        if bad:
            sys.exit(f"containment check failed for: {', '.join(bad)}")
```

Both runner call sites treat a non-zero exit as a skip/void, so the honest-failure path is preserved.

**Evidence:** `scripts/crb-materialize.py:352-383`, `runs/review-arms/crb-pipeline/run-host.sh:262-264,359-371`

---

## Claim 26: "The subset is defined as 'PRs our tool has a judged row for', which means a cell that produced nothing injectable removes itself from the denominator without appearing anywhere in this table."

**Location:** `scripts/crb-subset-leaderboard.py:40-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how `urls`/`our_urls` are derived from the evaluations file; does not establish the causal claim in the same docstring that failing cells are non-randomly the harder PRs (that is a statistical judgement, not a code property, and is presented as rationale).
**Legibility-target:** for-orchestrator-synthesis

```python
# scripts/crb-subset-leaderboard.py:113-114
    our_urls = sorted(u for u, tools in evals.items() if args.tool in tools)
    urls = sorted(evals) if args.all_prs else our_urls
```

A PR with no row for `args.tool` is therefore absent from `our_urls` entirely — nothing else in the ranking path re-introduces it (paraphrased — no quote available because the claim covers the absence of any other insertion point across the `main()` body).

**Evidence:** `scripts/crb-subset-leaderboard.py:40-79,107-120`

---

## Claim 27: "Attrition is always measured against the PRs OUR tool was judged on, even under --all-prs" / "Attrition goes to stderr like the skew warning AND into the markdown body"

**Location:** `scripts/crb-subset-leaderboard.py:110-112,165-177`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both output sinks and the `--all-prs` invariance; does not establish that a results doc's author will read the blockquote.
**Legibility-target:** for-orchestrator-synthesis

`attrition()` is called with `our_urls`, not `urls`:

```python
# scripts/crb-subset-leaderboard.py:169
    att_lines, _checked = attrition(our_urls, Path(args.run_meta))
```

and the markdown path re-emits the same lines. Both are pinned by passing tests:

```
# docs/reviews/execution-logs/r2-bats-crb.txt
ok 30 attrition is reported under --all-prs too (subset scope is not the question)
ok 31 attrition appears in the markdown body, not only on stderr
```

**Evidence:** `scripts/crb-subset-leaderboard.py:110-120,164-177`, `test/crb-subset-attrition.bats:94-108`, `docs/reviews/execution-logs/r2-bats-crb.txt`

---

## Claim 28: "`RUN_META` — Written by run-host.sh. The leaderboard reads it to tell 'we ranked on 3 PRs' apart from 'we asked for 5 and 2 fell out'"

**Location:** `scripts/crb_common.py:28-32`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path constant and the field names both sides use; does not establish that a run-meta.json currently exists at that path (none is checked in).
**Legibility-target:** for-orchestrator-synthesis

Path agreement: the constant is

```python
# scripts/crb_common.py:32
RUN_META = WORKSPACE / "runs/review-arms/crb-pipeline/run-meta.json"
```

and the writer targets `"$OUT/run-meta.json"` with `OUT="$ROOT/runs/review-arms/crb-pipeline"` (`runs/review-arms/crb-pipeline/run-host.sh:54,163`).

Field agreement — every key `attrition()` reads is a key the writer emits (`cells`, `requested_instances`, `voided_cells`):

```python
# scripts/crb-subset-leaderboard.py:54-57
    cells = meta.get("cells") or {}
    requested = meta.get("requested_instances") or sorted(cells)
    voided = set(meta.get("voided_cells") or [])
```

```python
# runs/review-arms/crb-pipeline/run-host.sh:207-212
json.dump({"arm": "crb-pipeline", ... "cells": cells,
           "requested_instances": req,
           "missing_cells": [s for s in req if s not in cells],
           "retried_cells": retried, "voided_cells": voided,
```

No name mismatch — the silent-under-report failure mode this claim guards against is not present.

**Evidence:** `scripts/crb_common.py:28-32`, `scripts/crb-subset-leaderboard.py:52-73`, `runs/review-arms/crb-pipeline/run-host.sh:54,163,193-213`

---

## Claim 29: "a `git branch -f review` here would fail exactly the way materialize() warns about at crb-materialize.py:221-223"

**Location:** `test/crb-containment-reset.bats:114-115`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited line range only; the substantive point (git refuses to force-update a checked-out branch, which is why materialize checks out `review` first) is correct and documented elsewhere in the file.
**Legibility-target:** for-author

`scripts/crb-materialize.py:221-223` is inside `reset_clone()`'s docstring, not a warning about `branch -f`:

```python
# scripts/crb-materialize.py:221-223

    Raises RuntimeError — i.e. VOIDS the cell — only for contamination:
    a surviving remote, or a commit reachable outside the reviewed head's
```

The warning the test means is at lines 285-287:

```python
# scripts/crb-materialize.py:285-287
    # Check out `review` FIRST: on forks whose default branch is itself named
    # `main`, HEAD still points at it after --no-checkout, and git refuses to
    # force-update the branch that is checked out.
```

Both files were added/edited in this same commit, so the reference was wrong when written rather than drifted.

**Evidence:** `test/crb-containment-reset.bats:113-117`, `scripts/crb-materialize.py:218-223,285-287`

---

## Claim 30: "Hermetic: builds throwaway git repos in BATS_TEST_TMPDIR, no network, no clones, and never touches external/crb-eval or the real manifest." (containment suite) / "Hermetic: synthetic evaluations/run-meta in BATS_TEST_TMPDIR. It does read the real runs/review-arms/crb/instances.json ... read-only." (attrition suite)

**Location:** `test/crb-containment-reset.bats:19-20`, `test/crb-subset-attrition.bats:15-17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the suites ran to completion with no network and left the manifest and `external/crb-eval` untouched in this run; does not prove hermeticity under all environments (e.g. a differently-configured global git).
**Legibility-target:** for-orchestrator-synthesis

All three suites pass in one invocation, and the run left the working tree clean apart from the new report/log files:

```
# docs/reviews/execution-logs/r2-bats-crb.txt
ok 32 a missing run-meta says attrition was NOT checked rather than staying silent
EXIT=0
```

The containment suite's fixtures are built under `BATS_TEST_TMPDIR` and the module is loaded directly rather than through the CLI, so `DST_ROOT`/`MANIFEST` are never consulted:

```bash
# test/crb-containment-reset.bats:28-30
  export CLONE="$BATS_TEST_TMPDIR/clone"
  rm -rf "$CLONE"; mkdir -p "$CLONE"
  git -C "$CLONE" init -q
```

```bash
# test/crb-containment-reset.bats:53-54
    note = m.reset_clone(dst, "fixture", head, base)
    n, stat = m.verify_containment(dst, "fixture", head)
```

The attrition suite's stated exception (reading the real manifest read-only) matches `test/crb-subset-attrition.bats:22` (`export MANIFEST="$REPO_ROOT/runs/review-arms/crb/instances.json"`), used only as input to `json.load`.

**Evidence:** `test/crb-containment-reset.bats:19-61`, `test/crb-subset-attrition.bats:15-42`, `docs/reviews/execution-logs/r2-bats-crb.txt` (cmd `bats test/crb-cell-status.bats test/crb-containment-reset.bats test/crb-subset-attrition.bats`, cwd `/workspace`, exit 0, 2026-08-18T19:43-07:00)

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/working/crb-direction1-setup.md:106-108`): "there is no remote to fetch it from" — removing the remote does not remove the fetch route; `git fetch <url>` works with zero remotes and lands in `FETCH_HEAD`, which no guard inspects. Same defect as Claim 19b, doc-side.
- **Claim 17** (`scripts/crb-cell-status.py:42-45`): "the shortest real review in the corpus is over 3 KB … 1000 sits an order of magnitude clear of both" — the shortest real review is 1208 chars and 22 of 32 corpus bodies are in the 1000–3000 band; `STUB_MAX_LEN=1000` has ~20% headroom, not 10×.
- **Claim 19b** (`scripts/crb-materialize.py:206-207`): the load-bearing security rationale for treating descendant strays as benign rests on "no remote ⇒ no route to fetch", which is false in a network-enabled container; a URL-fetch is invisible to `git remote` and `git rev-list --all`.
- **Claim 29** (`test/crb-containment-reset.bats:114-115`): cites `crb-materialize.py:221-223` for a warning that lives at `285-287`; the cited lines are `reset_clone()`'s docstring.

### Stale
- **Claim 23** (`scripts/crb-materialize.py:174`): "run-host.sh calls this via `--verify`" — this commit switched both runner call sites to `--reset`; nothing calls `--verify` any more.

### Mostly Accurate
- **Claim 5** (`docs/working/crb-direction1-setup.md:127-129` and `scripts/crb-cell-status.py:20-21`): "3–7 KB" — actual e5 range is 2.7–7.1 KB.
- **Claim 7b** (`docs/working/crb-direction1-setup.md:143-146`): "a docker failure" still leaves run-meta — true only for the per-cell docker call; the chown and preflight docker calls exit before the trap is installed.
- **Claim 11** (`runs/review-arms/crb-pipeline/run-host.sh:202-205`): "appears here and nowhere else" — a never-run slug also appears in `missing_cells`.
- **Claim 15** (`scripts/crb-cell-status.py:22-24`): the two stubs are a *weekly* and a *session* limit; only one matches the quoted string.

### Unverifiable
- None.

No new hallucination-pattern entries: none of the Incorrect verdicts asserts a symbol, method, or API that does not exist. Claim 29 is a stale/wrong line reference, Claims 2/17/19b are refuted mechanisms and a miscounted margin — all excluded from the log by its own criteria.

## Goal-Alignment Note
- Answered: yes — all 12 requested claim families checked, plus 18 further claims from the commit.
- Out of scope: code-quality judgement on the new reset/attrition logic (owned by the critic skills); prior-review items R2/R3/A16 were used only as hints — R3's credential exposure is not verdicted here, though Claim 19b's execution result is direct evidence bearing on it.
- Escalate: (1) the `FETCH_HEAD` gap — an agent can fetch the merged upstream fix by URL and neither `classify_strays()` nor `verify_containment()` would see it, so the "descendant strays are benign" rule is unenforced rather than merely undocumented; this is a containment question before a $50–2000 sweep, and the cheap mitigations (`--network none` for the review container, or adding `FETCH_HEAD`/`git count-objects` to the post-run check) belong to security-reviewer. (2) `STUB_MAX_LEN=1000` sits 1.2× above the shortest observed real review, so the substring rule is one short review away from rejecting genuine work — the comment's claimed margin does not exist.
