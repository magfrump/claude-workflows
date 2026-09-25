Commit: feba07d

# Performance Review: copy-install Q-058, pass 2 (fix commits c7c4e34..feba07d)

**Scope:** the 9 fix commits `24ce814`..`feba07d` on skill-fixtures, which answer `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md`. Code read at feba07d in `/workspace/.claude/wt-q058p2`. The earlier history is context only.
**Date:** 2026-09-25
**Based on:** no code-fact-check report for this pass. The pass-1 review is `docs/reviews/performance-review-2026-09-24-copy-install-q058.md`. This reviewer's timings are in `docs/reviews/execution-logs/q058p2-perf-feba07d-suite-timing.log`. They are baseline measurements only, not behaviour verdicts.

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

`install.sh` runs once per install, driven by a human at a terminal. **Every path in it is cold.** Only two stretches are latency-sensitive: the wait before the first output, and the wait between a `y` and the writes. The payload at feba07d is 122 files and 2,126,325 bytes. The claude-home part is 107 files and 1,932,602 bytes (`micro.sh` in the log).

What the fix commits add to a run:

| Change | Where | Measured cost (this sandbox, page cache warm) |
|---|---|---|
| `tree_hash` over PAYLOAD (A1) | `install.sh:576-584`; called at `:448`, `:483`, `:502` | 51–53 ms per call (one outlier at 89 ms) |
| Host copy into `$dest/.cw-new.*` before the review (R2) | `:710-757` | `cp -Rp` of claude-home 12–14 ms; `rm -rf` 4 ms |
| `payload_hash` = `tree_hash` + manifest (R2) | `:590-597`; called at `:756`, `:866` | about the same as `tree_hash` of claude-home |
| `git_state_gate` (R1) | `:172-211`; called from `assemble` at `:291` | 6–8 ms per call on a clean checkout (≈3 `git` forks at 2–3 ms each) |
| `vis_or_die` wrapping (C3) | `:138-145` and 14 call sites | 5–6 ms per call, the same as bare `vis` (5–6 ms) |
| A 4th `agent_gate` (A2) and a progress line before `docker ps` (C1) | `:677`, `:1004` | not measurable here (docker and pgrep are stubbed; no docker in the sandbox) |

**How often the payload is hashed or read per run.** An interactive run that answers y to both targets reads the claude-home payload about 14 times:

- Devcontainer target (y), 8–9 reads:
  - two NUL scans (`assemble`, then `:430` over the whole stage);
  - the mirror copy (`:439`);
  - `tree_hash` before the review (`:448`);
  - `review_diff`;
  - `tree_hash` after the y (`:483`);
  - the copy into `$DEST` (`:497`);
  - `tree_hash` of `$DEST` (`:502`);
  - whatever `cc-isolated.sh --bless` reads (not opened by this reviewer).
- Host target (y), 5 reads:
  - the NUL scan;
  - the copy into `.cw-new.*`;
  - `payload_hash` before the review (`:756`);
  - the review diff or ADD `cat`;
  - `payload_hash` after the y (`:866`).

Before the fix the devcontainer target had no hash. The host target had two: the stage before the review, and the copies after the y. That count is unchanged. The new hashes add about 3 × 52 ms = 0.16 s to a y/y run. A decline adds one `tree_hash` (about 52 ms) plus the host copy and `rm` (about 16 ms).

**Tests:** 10 new tests (T65–T74) in `test/install-host.bats` (`@category slow`). `path_without` was rewritten for C2.

## Findings

#### 1. Two back-to-back docker probes when target 1 is accepted: the 4th gate raises the worst-case docker wait to about 80 s, now visible

**Severity:** Low
**Location:** `devcontainer-config/install.sh:677` (new gate), `:481`, `:864`, `:1093`; probe at `:1004-1007`
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed per-call timeout) / Cold, but it blocks a human waiting at the terminal. Escalated from Informational for that reason, as in pass 1.
**Confidence:** High for the count (read). Low for how often docker hangs on the real host (not measured).
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** the user running `install.sh` on the bare WSL host, and whoever maintains `agent_gate`

**Evidence:**
```bash
  # Q-058, review A2: the startup check ran before target 1's review and
  # prompt, which can wait for minutes. Check again before this target stages.
  agent_gate "Nothing was installed into the host target."
```
```bash
    # Review C1: a hung docker is otherwise up to 20 s of silence per check.
    echo "Checking for running cc-isolated containers (docker ps; up to 20 s)..."
    errf="$(mktemp "${TMPDIR:-/tmp}/cw-docker-err.XXXXXX")"
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
```

C1 is answered: every probe now prints a line first, so a stall is no longer silent.

A2 adds a fourth gate, so a y/y run now probes docker four times: at startup, after the devcontainer y, before host staging, and after the host y. On a host where docker hangs, the worst case goes from about 60 s to about 80 s.

When target 1 is accepted, the gate after its y (`:481`) and the host pre-stage gate (`:677`) are separated only by the copy, the hash and the bless. That is seconds, not the minutes of review the A2 comment justifies. In that case the second probe re-samples almost the same instant, at a worst case of another 20 s. When target 1 is declined, the `:677` gate is what A2 needs, because a human prompt sits between it and the startup gate.

The progress line's "up to 20 s" is also only as true as pass 1's C6 (the `$( … )` pipe held by a docker grandchild), which these commits did not address.

**Recommendation:** Not a merge blocker. Optionally skip the `:677` probe when a gate passed within the last few seconds (for example, record `$SECONDS` in `agent_gate`). Re-probing costs little when docker is healthy, so leaving it as it is is also fine. The real-host `docker ps` timing asked for in pass 1 still decides whether the 20 s bound should shrink.

#### 2. `path_without` (C2) is 2.4–3.3× faster per call, but still about 1.2 s per call inside bats, against 55 ms in plain bash

**Severity:** Low
**Location:** `test/install-host.bats:62-80` (`path_without`); called by T52 (`:873`), T53 (`:900`) and T57 (`:954`)
**Move:** Count the hidden multiplications
**Classification:** Micro (a per-entry shell loop over about 2,000 PATH entries) / Cold (test suite, but it runs in every slow-suite and `health-check.sh` run)
**Confidence:** High for the numbers (measured). Medium for the mechanism.
**Baseline:** `path_without pgrep` takes 1,167 / 1,304 / 1,187 ms inside a bats test, and 54–59 ms (1,033 links) in plain bash. T53, which is `path_without` plus a gate refusal, takes 1,142–1,319 ms; T51, the same refusal without `path_without`, takes 77–87 ms. Measured 2026-09-25 in this sandbox (log above).
**Legibility-target:** the author of `install-host.bats`, and whoever owns slow-suite runtime

**Evidence:**
```bash
  for dir in $PATH; do
    [ "$dir" = "$STUB" ] && continue
    exe=()
    for f in "$dir"/*; do
      if [ -x "$f" ] && [ ! -d "$f" ]; then exe+=("$f"); fi
    done
    if [ "${#exe[@]}" -gt 0 ]; then ln -s "${exe[@]}" "$farm/" 2>/dev/null || true; fi
  done
```

C2 removed the fork per executable. Over two alternated runs each, T52 + T53 + T57 went from 11,199 ms to 4,282 ms, a saving of 6.9 s.

The per-entry `[ -x ] && [ ! -d ]` loop is left, and it costs about 1.1 s more inside a bats test than in plain bash. The extra cost comes from running under bats's instrumentation. A bare `trap … DEBUG` did not reproduce it (70 ms), so the exact mechanism is unverified. Three calls leave about 3.5 s per slow-suite run.

**Recommendation:** Drop the loop. Either `ln -s "$dir"/* "$farm/"` (a non-executable in a PATH directory is harmless in the farm), or build the farm once in `setup_file` and copy it per test. Either brings each call to tens of milliseconds. Not a merge blocker.

#### 3. The new tests add about 18.3 s to the suite (+19% net). About 10.5 s of that is fixed `sleep`

**Severity:** Low
**Location:** `test/install-host.bats` T67 (`:520`), T68 (`:552`), T69 (`:1055`), T72 (`:1121`), plus `FEED_TAMPER` (`:168-170`)
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed waits) / Cold (test suite)
**Confidence:** High for the totals (two alternated runs per commit). Medium for per-test attribution, since the run-to-run noise is up to ±2.5 s on single tests (T37 is bimodal at 2.6 s or 4.9 s on both commits).
**Baseline:** Suite sums from `bats --timing test/install-host.bats`, mean of 2 runs:

| Commit | Sum | Tests |
|---|---|---|
| c7c4e34 (base) | 83,682 ms | 64 |
| feba07d (fix) | 99,732 ms | 74 |

- Net: +16,050 ms (+19.2%).
- New tests T65–T74: 18,267 ms.
- The 64 common tests: −2,217 ms, the C2 saving net of noise.

Measured 2026-09-25 in this sandbox (log above).
**Legibility-target:** the author of `install-host.bats`

**Evidence:**
```bash
FEED_TAMPER='printf "n\n"
  for _i in $(seq 200); do compgen -G "$TMPDIR/cw-host-stage.*/payload/.manifest" >/dev/null && break; sleep 0.1; done
  sleep 2; eval "$TAMPER"; printf "y\n"'
```
T67 (`:539`):
```bash
  export TAMPER="sleep 1.5"
```
T72 (`:1125`):
```bash
    sleep 1; touch '$S/agent-up'; printf 'n\n'; sleep 3; touch '$S/agent-down'; printf 'y\n'"
```

The tests are 4,357 ms (T67), 4,267 ms (T72), 3,344 ms (T69) and 2,379 ms (T68). Their fixed waits come to 3.5 + 4 + 1 + 2 = 10.5 s.

T72 pays its full `sleep 3` even though `install.sh` exits at the `:677` gate before reading the `y`. `run_pty_feed` pipes the feed into `script`, and the pipeline waits for the feed to finish.

T16 is also consistently about 1.5 s slower at feba07d (2,079–2,083 ms against 594–601 ms, three isolated runs each). Its copy failure now happens before the review (R2), so `install.sh` exits with the `n\ny\n` input unread. The extra time seems to come from how `script` handles that input, but this is inferred, not verified.

None of this affects `install.sh` itself.

**Recommendation:**
- Shorten T72's post-refusal `sleep 3`. The agent only needs to stay "up" until the `:677` gate has sampled it, so the feed could wait for the refusal text instead of sleeping.
- Keep T67's and FEED_TAMPER's waits: they exist to order a race. Not a merge blocker.

#### 4. The host lock and about 1.9 MB of `.cw-new.*` copies now last through the review and prompt; after a SIGKILL they persist until removed by hand

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:713-757` (lock and copies taken before the review); `:615-626` (`host_cleanup`)
**Move:** Trace the resource lifecycle / Find the contention point
**Classification:** Micro / Cold
**Confidence:** High for the window (read). High that SIGHUP and SIGTERM run bash's EXIT trap and SIGKILL does not (tested with a bare `bash -c "trap … EXIT"`, not with `install.sh`).
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** the maintainer of `install_claude_home`, and the user who may meet the lock message

**Evidence:**
```bash
    if mkdir "$dest/.claude-workflows-lock" 2>/dev/null; then
      HOST_LOCK="$dest/.claude-workflows-lock"
      HOST_NEW_IN="$dest"   # this run owns $dest/.cw-new.* from here on
```

Before R2, the lock and copies existed only between the `y` and the swap: milliseconds. Now they span the review and `[y/N]`, which a human can leave open for minutes.

Closing the terminal (SIGHUP) or a `kill` (SIGTERM) still runs `host_cleanup`. A SIGKILL, an OOM kill or a WSL shutdown during that window leaves both behind:
- a stale `.claude-workflows-lock`, which refuses every later run with the "remove that directory" message;
- about 1.9 MB of `.cw-new.*` copies in `~/.claude`, which the next successful run deletes (`rm -rf "$dest/.cw-new.$name"` before each copy).

A concurrent second install is now refused at once rather than after its own review. That is a better outcome, not a cost.

**Recommendation:** None required. This is the cost of Q-061 [1]. If Q-061 stays [1], consider saying in the lock message that a leftover lock after a killed run is expected and safe to remove. That text already exists, so this is only a wording check.

#### 5. `git_state_gate`, `vis_or_die` and the new hashes cost well under a second per run

**Severity:** Informational
**Location:** `install.sh:172-211`, `:138-145`, `:576-584`
**Move:** Check the asymptotic behavior
**Classification:** Micro / Cold
**Confidence:** High (measured on the real feba07d payload)
**Baseline:**
- `tree_hash` of PAYLOAD: 51–53 ms per call.
- `git_state_gate` on a clean checkout: 6–8 ms per call.
- `vis_or_die`: 5–6 ms per call, the same as `vis`.

Measured 2026-09-25 with `micro.sh`; log above.
**Legibility-target:** the maintainer of `install.sh`

**Evidence:**
```bash
tree_hash() {
  local dir="$1" pfx="$2" name
  shift 2
  for name in "$@"; do
    echo "== $name"
    find "$dir/$pfx$name" -printf '%P\t%y\t%m\t%l\n' | LC_ALL=C sort
    find "$dir/$pfx$name" -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum | cut -d' ' -f1
  done | sha256sum | cut -d' ' -f1
}
```

**`tree_hash`**
- Per name, it runs two `find` passes and one batched `sha256sum`: O(files · log files) for the sorts, O(bytes) for the hash.
- It makes about 7 forks per name, so about 57 per PAYLOAD call, and it does not fork per file.
- It runs 3× on a devcontainer y (about 0.16 s) and 2× on a host y (unchanged from pre-fix).

**`git_state_gate`**
- It runs twice per interactive run, once per `assemble`, and makes 3–5 git forks each time.
- Its `head -n 20 | sed` runs only on the refusal path.
- The `-c core.fsmonitor=false` on both `git status` calls costs nothing and removes a possible external-command spawn.

**`vis_or_die`**
- It adds one `local` and one test to `vis`'s perl fork.
- In a pipeline it was already a subshell, so it adds no process.
- The per-line `echo … | vis_or_die` in the host pre-pass (`:767`, `:773`, `:792`) is one perl per REPLACE/MOVE line. That count is unchanged from the pre-fix `| vis`. A migration with N foreign files pays about N × 6 ms, as it did before.

**Recommendation:** None.

## Endorsements

- **The host target hashes the same number of times as before R2 (two per y run), and the review now reads the copy it installs instead of a separate stage read.** The only added work is on the decline and nothing-to-install paths: one copy (12–14 ms) and one `rm` (4 ms). `[read: devcontainer-config/install.sh:710-757,843-871]`
- **`payload_hash` now delegates to `tree_hash` rather than duplicating the loop, so the host and devcontainer hashes share one implementation and one cost profile.** `[read: devcontainer-config/install.sh:576-597]`
- **`tree_hash` hashes file contents with one batched `xargs -0 sha256sum` per entry name, not one fork per file.** `[read: devcontainer-config/install.sh:576-584]`
- **The C2 rewrite cut the three `path_without` tests from 11.2 s to 4.3 s over two alternated runs.** `[unverified — submitted as claim]` (measured by this reviewer, not by a fact-check stage)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | 4th gate: back-to-back docker probes after a target-1 y; worst case about 80 s, now with a progress line (C1 answered) | Low | `install.sh:677`, `:481`, `:1004-1007` | High (count) / Low (frequency) |
| 2 | `path_without` still about 1.2 s per call under bats (55 ms in plain bash); about 3.5 s per run left | Low | `test/install-host.bats:62-80` | High / Medium (mechanism) |
| 3 | T65–T74 add 18.3 s; net suite +16.1 s (+19%); about 10.5 s is fixed sleeps; T72's `sleep 3` is wasted | Low | `test/install-host.bats:520,552,1055,1121,168` | High (totals) / Medium (attribution) |
| 4 | Host lock and about 1.9 MB of copies now span the review; after a SIGKILL they persist | Informational | `install.sh:713-757`, `:615-626` | High |
| 5 | `git_state_gate` 6–8 ms, `tree_hash` about 52 ms, `vis_or_die` = `vis`: all negligible | Informational | `install.sh:172-211`, `:576-584`, `:138-145` | High |

## Overall Assessment

The fix commits keep a sound performance posture for a once-per-install CLI. Every new cost is on a cold path and bounded by the 2.1 MB payload.

The A1 hashes add about 0.16 s to a devcontainer y. R2 keeps the host at two hashes and adds about 16 ms to a decline. R1's `git_state_gate` is about 15 ms per run, and `vis_or_die` costs the same as `vis`.

C1 is answered: the probe is visible. A2 makes it four probes, one of them usually redundant when target 1 is accepted. C2 is about 60% answered: the fork per executable is gone, but the per-entry loop still costs about 1.2 s per call under bats.

The suite grew by 19% net, mostly fixed sleeps in race-ordering tests. That is acceptable, and T72 can be trimmed. Nothing here blocks the merge. The one measurement still owed is the real-host `docker ps` timing from pass 1, which decides whether the 20 s bound should shrink.

## Goal-Alignment Note
- Success criterion (restated verbatim): "a markdown report saved to /workspace/docs/reviews/performance-review-2026-09-25-copy-install-q058-pass2.md, per the skill."
- Answered:
  - **New hashing.** `tree_hash` is about 52 ms per call on the real payload. It runs 3× on a devcontainer y and 1× on a decline. The host target is unchanged at 2× per y. claude-home is read about 14× per y/y run, sub-second in total.
  - **Copy into `$dest` before the review.** It costs 12–14 ms + 4 ms `rm` on the decline and no-change paths. Its lifecycle cost is Finding 4.
  - **R1 git-config checks.** 6–8 ms per call, twice per run.
  - **`vis_or_die`.** Same cost as `vis`.
  - **Test runtime** (`bats --timing`, measured in the worktree against a c7c4e34 extract): 83.7 s → 99.7 s (+19%). T65–T74 add 18.3 s. C2 saved 6.9 s on T52, T53 and T57.
- Out of scope:
  - whether R1's key list, R2's copy placement or A1's hash close their security gaps (security reviewer);
  - the correctness of the new tests;
  - the docs changes (context only);
  - the real docker and pgrep behaviour, since both are stubbed and there is no docker in the sandbox.
- Escalate:
  - To the fact-check stage: the endorsement "C2 cut the three `path_without` tests from 11.2 s to 4.3 s", and Finding 2's mechanism (bats instrumentation, not a plain DEBUG trap).
  - To the user (you: terminal), carried from pass 1: time `docker ps --filter label=cc-project` on the bare host with Docker Desktop stopped and started. Pass 1's C6, the `timeout` pipe bound, is still open and unaddressed by these commits.
  - To the test author: T67's race uses fixed 1.5 s and 2 s windows. That is a flake risk on a loaded host, not a cost.
