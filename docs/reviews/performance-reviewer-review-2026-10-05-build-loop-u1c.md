Commit: 553a50d5

# Performance Review — feat/build-loop-u1c (U1c: constraints line and --status)

**Scope:** `git diff feat/build-loop-u1b...feat/build-loop-u1c` (commits 859e29e8, aaae80c6, 553a50d5); lib functions it calls read as context
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1c.md (Commit 553a50d5) and the shared Stage-2 context

All numbers below are my own measurements, taken in /home/node/.claude/jobs/989f3e5a/tmp/review-u1c/performance/ on 2026-10-05, git 2.39.5, bash 5.2.15, 16 cores, load average about 2. They are medians of 3 to 11 runs, and wall times include the scrub re-exec. The synthetic repos were built with `gen.py`/`mk.sh` in that directory. Each one holds N briefs directly under `docs/working/briefs/`, of which 1 in 5 is open and 4 in 5 were flipped to done or dropped. Each has about 2,000 filler commits interleaved, so main has 2,019 / 2,181 / 2,901 commits at N = 10 / 100 / 500. Each open brief has a branch, and half of those carry a `handoff: ready` marker. A 20-hard/20-soft `docs/constraints.md` and a self-merge settings file are included. Process counts come from PATH shims (`shim/`, `count.sh`) that log each exec of git, awk, env, tr, realpath, perl, sed and cat.

## Data Flow and Hot Paths

- **`--settings`**: `read_settings` now runs `main_file` a second time over `docs/constraints.md` with `CONSTRAINTS_AWK`. That is one extra `main_entry` (one `git ls-tree`), `git cat-file`, `env` and `awk`. The run goes from 12 to 16 execs and from 18 to 23 ms (r10) or 21 to 23 ms (r500), measured against U1b's script on the same repo. On this repo it takes 20 ms. The awk pass is linear in the file's line count, and its `seen[]` array is bounded by the number of constraint IDs. This is a fixed cost per run, not per item.
- **`--status BRIEF...`**: the work is `read_settings` (16 execs), then `shared_branches` (one pass over every entry on main's `docs/working/briefs/`), then one `status_line` per argument.
  - Each brief that `shared_branches` reads costs `main_entry` plus `brief_fields`, and `brief_fields` calls `main_entry` again before its `cat-file | env awk`. An open brief adds one `lower` (`tr`). In all that is about 5.2 execs per brief on main.
  - Each `status_line` costs `check_brief` (`need_root`, `blocker` with 4 `realpath`, `main_entry`, `brief_fields`, `git log -G`), then `brief_fields` again, `lower`, `check_branch` (6 git) and `marker_kind` (2 git), plus about 15 `$(...)` forks.
  - Measured totals: 92 execs for one argument at N=10, 560 at N=100 and 2,640 at N=500 (1,523 of them git). Three arguments add about 39 execs to each.
- **Temperature**: this path is cold. It is a CLI the orchestrator calls once per collect step or fallback wakeup (plan D1/D4), not a request handler. N is bounded in practice, because the cycle `git mv`s done and dropped briefs into `briefs/closed/` (skills/dev-cycle/SKILL.md:284, plan :256). That leaves N at roughly the open and queued briefs. This repo has 3 today. On it, `--status` takes 71 ms for 1 brief and 111 ms for all 3.

| Briefs on main (N) | `--status` 1 arg | `--status` all open (N/5) | `--status` all N | `main_entry` per call | `shared_branches` alone |
|---|---|---|---|---|---|
| 10 | 132 ms (126–146) | 164 ms | 369 ms | 2.2 ms | 72 ms |
| 30 | 300 ms | — | — | — | — |
| 100 | 1,262 ms | 2,071 ms | 4,594 ms | 4.3 ms | 1,164 ms |
| 500 | 15,233 ms | 23,687 ms | 49,596 ms | 12.9 ms | 15,733 ms |

Marginal cost per extra `--status` argument: 26 ms at N=10, 34 ms at N=100 and 69 ms at N=500.

## Findings

#### F1. shared_branches is quadratic in the number of briefs on main: two `main_entry` calls per brief, each listing every sibling

**Severity:** Low
**Location:** `scripts/build-loop.sh:287-291` (calls into `scripts/lib/dev-cycle-read.sh:263-264` and `:292`)
**Move:** Count the hidden multiplications / asymptotic behaviour
**Classification:** Macro (O(N²) in briefs/ entries) / Cold path (once per orchestrator `--status` call; N bounded by the move to `closed/`)
**Confidence:** High (measured)
**Baseline:** `shared_branches` alone took 15,733 ms at N=500 and 1,164 ms at N=100 (in-process timing, `proto.sh`). `--status` with one argument took 15,233 ms at N=500, median of 5 runs, synthetic repo r500, 2026-10-05.
**Evidence:**
```
scripts/build-loop.sh:287:  list="$(git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/)"
scripts/build-loop.sh:288:  while IFS= read -r f; do
scripts/build-loop.sh:289:    if ! isbrief "$f" || [[ "$(main_entry "$f")" != blob ]] || ! brief_fields "$f"; then continue; fi
scripts/build-loop.sh:290:    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
scripts/build-loop.sh:291:    b="$(lower "${BASH_REMATCH[1]}")"; n[$b]=$(( ${n[$b]-0} + 1 ))
scripts/lib/dev-cycle-read.sh:263:  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
scripts/lib/dev-cycle-read.sh:264:  while IFS=$'\t' read -r mode path; do
scripts/lib/dev-cycle-read.sh:292:  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
```
(The excerpt ends at :291. The enclosing `shared_branches()` continues to :295, where it closes the loop and builds `SHARED_BRANCHES`, and I read all of it. The excerpt at lib :264 ends inside `main_entry()`, which continues to :277 and which I also read. Lib :292 is `brief_fields()`'s first check, and `brief_fields()` continues to :308.)

`main_entry` passes every parent directory, `docs/working/briefs` included, to `ls-tree -t`. So each call prints every entry in `briefs/`: 15, 105 and 505 lines at N = 10, 100 and 500. It then reads them one by one in a bash `while read` loop. A call costs 2.2, 4.3 and 12.9 ms, of which the `ls-tree` process is only about 1.2–1.3 ms. The rest is the bash loop.

`shared_branches` makes two such calls per brief on main: one directly at :289 and one inside `brief_fields` at lib :292. That makes the pass O(N²). It accounts for nearly all of a one-argument `--status` run: 15.7 s of 15.2–15.7 s at N=500. The `--name-only` listing at :287 already holds every entry, and without `--name-only` it would also give each entry's mode. That is everything the per-file `main_entry` re-derives, except the parent-directory check, which is the same for every file.

A rough probe (`proto.sh`) takes the mode from that one listing, checks the parents once, and reads each blob with `cat-file | awk` and no `main_entry`. It ran in 21 / 181 / 977 ms at N = 10 / 100 / 500, against 72 / 1,164 / 15,733 ms shipped. That is linear at about 2 ms per brief. The probe is not semantically equivalent: it drops `main_entry`'s duplicate-name `error` and the `lower` call. It shows the size of the cost, not a drop-in fix.

At realistic N (3 on this repo today, 10–30 plausible), the absolute cost is 72–300 ms per call. That is why this is Low and not higher. The cliff comes only if `briefs/` fills up, for example if the move to `closed/` lags or the backlog of open briefs grows.

**Override-log row 220 (main_entry's ls-tree cost):** this diff changes that row's premise. The row was decided on "49 entries from one ls-tree process per lookup", with one lookup per run. `--status` now makes 2N + 3k lookups per run, where k is the number of arguments, and each lists every entry in `docs/working/briefs/`. The row's revisit trigger names per-path calls ("or U2's floor calling it per changed path"), and `shared_branches` is exactly such a per-path loop. So I read the trigger as met, with the numbers above. The row's Won't-Fix reasoning, that per-component ls-tree calls would cost more forks, still holds for `main_entry` itself. The fix belongs in the caller, not in `main_entry`.

**Recommendation:** in `shared_branches`, drop `--name-only` at :287 and take each entry's mode from that listing. Check `docs/working/briefs`' parents with one `main_entry` before the loop. Then read each blob without a second `main_entry`. That needs a `brief_fields` variant, or a flag, for a path the caller has already proven is a blob. A further option is one `git cat-file --batch` over all briefs, which would make the process count constant. Record the decision against row 220 either way.

#### F2. status_line reads each brief's tree entry three times and its blob twice

**Severity:** Low
**Location:** `scripts/build-loop.sh:298-302` (with `scripts/lib/dev-cycle-read.sh:330` and `:338`)
**Move:** Find the work that moved to the wrong place (repeated per item)
**Classification:** Micro (a constant factor of 3× per argument) / Cold path, but it scales with N through `main_entry` (F1)
**Confidence:** High (measured)
**Baseline:** marginal cost per extra `--status` argument was 26 ms at N=10, 34 ms at N=100 and 69 ms at N=500 (`(all N − 1 arg)/(N−1)` from the table above, synthetic repos, 2026-10-05). `brief_fields` alone measured 4.4, 6.9 and 16.0 ms per call in-process (`unit.sh`).
**Evidence:**
```
scripts/build-loop.sh:298:  out="$(check_brief "$a")"
scripts/build-loop.sh:302:  brief_fields "$a" || { echo "skip $a: the brief is not read"; return; }
scripts/lib/dev-cycle-read.sh:330:  e="$(main_entry "$a")"
scripts/lib/dev-cycle-read.sh:338:  if ! brief_fields "$a"; then
```
(The excerpt ends at :302. The enclosing `status_line()` continues to :330, through `check_branch` at :315, `marker_kind` at :323 and the final echo, and I read all of it. Lib :330 and :338 sit inside `check_brief()`, which continues to :358 and which I read.)

`check_brief` runs in a `$(...)` subshell at :298. Its `BRIEF` array, filled by its own `brief_fields` at lib :338, is lost when the subshell exits. So `status_line` reads the brief again at :302.

Per argument that comes to three `main_entry` calls (lib :330, inside lib :338's `brief_fields`, and inside :302's `brief_fields`) and two `cat-file | env awk` passes. With F1's per-call cost of 12.9 ms at N=500, the `main_entry` calls alone are about 39 ms of the 69 ms marginal cost. At N=10 they are about 7 of 26 ms.

The rest of the per-argument cost is fixed and was already settled: `blocker` at 4.5 ms (4 `realpath` execs), `git log -G` at 2–13 ms, `check_branch` at 7.5–10.5 ms (6 git) and `marker_kind` (2 git). The number of arguments is bounded by in-flight briefs (slots 1–9 plus the queue).

**Recommendation:** have `status_line` reuse `check_brief`'s read. One way is to call a non-printing core of `check_brief` in the caller's own shell, so `BRIEF` survives. Another is to parse `check_brief`'s output and skip the second `brief_fields`. If F1's fix adds a "known blob" path to `brief_fields`, the remaining duplicate `main_entry` goes away too. Low priority on its own; worth doing alongside F1.

#### F3. --status pays for the constraints read it never uses

**Severity:** Informational
**Location:** `scripts/build-loop.sh:335` (with `:237-238`)
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (one fixed file read per run) / Cold path
**Confidence:** High (measured)
**Baseline:** `--settings` went from 12 execs and 18 ms (U1b's script, r10) to 16 execs and 23 ms (U1c), median of 11 runs, 2026-10-05. The difference, 4 execs and about 2–5 ms, is the constraints read, and `--status` pays the same.
**Evidence:**
```
scripts/build-loop.sh:335:    read_settings; shared_branches
scripts/build-loop.sh:237:  f=docs/constraints.md
scripts/build-loop.sh:238:  if ! main_file "$f" "$CONSTRAINTS_AWK"; then
```
(The excerpt at :237-238 ends inside `read_settings()`, which continues to :250, and I read all of it. The `status)` arm at :334-337 is quoted in full at :335-336, and :336 is the per-argument loop.)

`status_line` reads only `POLICY`. The fact-check, Claim 17, also notes that `--status` never reads `NEVER`. `CONSTRAINTS_LINE` is computed and dropped on every `--status` run.

**Recommendation:** none required, since the cost is fixed and about 3 ms. If U2 or U3 add more `read_settings` sections, consider splitting the constraints read into its own function that only `--settings` (and later the dispatcher) calls.

#### F4. `lower` forks a `tr` per open brief, twice over

**Severity:** Informational
**Location:** `scripts/build-loop.sh:291`, `:312`
**Move:** Count the hidden multiplications
**Classification:** Micro / Cold path
**Confidence:** High (measured)
**Baseline:** `lower` took 0.89–0.91 ms per call in-process (`unit.sh`, 20 calls, 2026-10-05). The shim counted 101 `tr` execs for one argument at N=500 (100 open briefs).
**Evidence:**
```
scripts/build-loop.sh:291:    b="$(lower "${BASH_REMATCH[1]}")"; n[$b]=$(( ${n[$b]-0} + 1 ))
scripts/build-loop.sh:312:  if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
```
(:291 is inside `shared_branches()`, which runs :284-295, and :312 is inside `status_line()`, which runs :296-331. I read both in full.)

The cost is about 90 ms of 15.2 s at N=500 and about 2 ms at N=10. It is negligible next to F1. `lower` avoids `${x,,}` on purpose (the locale), so it is a deliberate choice, and I am noting it only for completeness.

**Recommendation:** none needed. If F1 is reworked, lower-case the branch names in one `tr` over the collected list rather than one per brief.

#### F5. Calling --status once per brief would multiply F1 by the number of briefs (forward note for U4)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:335-336`
**Move:** Count the hidden multiplications (at the caller)
**Classification:** Macro (k × N) / Cold path
**Confidence:** Medium (depends on how U4's skill text calls it; not yet written)
**Baseline:** no baseline available — flagged as speculative. The component numbers are measured: one-argument `--status` takes 132 ms at N=10 and 300 ms at N=30. Calling it once for each of 30 briefs would be about 9 s, against one call with all of them.
**Evidence:**
```
scripts/build-loop.sh:335:    read_settings; shared_branches
scripts/build-loop.sh:336:    for a in "${ARGS[@]}"; do status_line "$a"; done
```
`shared_branches` and `read_settings` run once per process. Plan D4 says "Collect results (skill step 7), per brief, by `--status`". If U4's skill reads that as one `--status` call per brief, the O(N) or O(N²) pass from F1 repeats k times.

**Recommendation:** U4's skill text should say to call `--status` once, with every in-flight brief as an argument. This is a revisit point for U4, not a change here.

#### F6. The locale restore after marker_kind can print a setlocale warning on stderr (no performance cost)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:277` (the warning surfaces at :323)
**Move:** Resource lifecycle (process-wide state restored on return)
**Classification:** Micro / Cold path
**Confidence:** High (reproduced)
**Baseline:** reproduced in scratch dir `loc/` on 2026-10-05. Under `LC_ALL=en_US.UTF-8`, which is not installed here, `--status` with one stopped tip and one working tip printed 5 stderr lines. Four were bash's own startup warnings, two per bash process (outer plus scrub re-exec), and one was `build-loop.sh: line 323: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)`. Stdout and the exit status (0) were identical to the run under `LC_ALL=C.UTF-8`, which printed nothing on stderr. `--settings` under the same locale printed 4 startup warnings.
**Evidence:**
```
scripts/build-loop.sh:277:  local LC_ALL=C
```
(The excerpt ends inside `marker_kind()`, which continues to :280, and I read all of it. The value flows to :323, `kind="$(marker_kind "$sha")"`.)

Restoring the caller's locale when the function returns calls setlocale with that locale. If it is not installed, bash warns, once per stopped or bad-subject tip. The time cost is nil. In an environment with a broken locale, every bash run already prints the same warning at startup, so this adds one line of a kind already present. This confirms the fact-check's Claim 21 escalation. Whether stderr noise matters to the orchestrator is for api-consistency to judge, not a performance concern.

**Recommendation:** none for performance. If the stderr line is unwanted, run the length and regex test in a subshell, or save and restore the locale explicitly with `2>/dev/null` around the restore.

## Settled override-log rows with revisit triggers

- **Row 201 (check_brief's `git log -G` walk; trigger: "U1's `--status` calls check_brief per brief; measure there")**: the trigger is met, and here are the measurements. On this repo (2,137 commits) the walk takes 2 ms per brief for all 3 briefs. In the synthetic repos it takes 4.4 / 5.2 / 12.7 ms per call at 2,019 / 2,181 / 2,901 commits. That is for brief b0, which was added at the start of history, so the walk runs almost the whole first-parent history. The walk stops at the most recent commit that touched a "Status: " line. For an open brief that is when the brief was added; for a closed one it is the move to `closed/`. It is a minority of the per-brief cost, below `main_entry` at N ≥ 100 and below `blocker`. No action.
- **Row 212 (`need_root` forks `$(pwd -P)`; trigger: "U1/U2 calling the checks per path in a loop")**: the trigger is nominally met, because `--status` calls `check_brief` once per argument. Measured: `need_root` takes 0.36 ms per call, once per argument (`shared_branches` does not call it). `blocker`'s walk takes 4.5 ms per argument (4 `realpath` execs; shim counts were 4 for 1 argument and 12 for 3). Together that is about 19% of the 26 ms per-argument cost at N=10. The number of arguments is bounded by in-flight briefs. The row's decision still holds, and nothing here changes its premise.
- **Row 220 (`main_entry`'s `ls-tree -t` cost; trigger: "a docs/ or docs/working/ with thousands of entries, or U2's floor calling it per changed path")**: the premise has changed and the trigger is met in substance. See F1: `main_entry` is now called 2N + 3k times per `--status` run, and each call lists every entry in `briefs/`. It costs 2.2 / 4.3 / 12.9 ms per call at N = 10 / 100 / 500, and the pass totals 15.7 s at N=500. The fix belongs in the caller.

## Endorsements

- Done and dropped history in `docs/working/briefs/closed/` does not slow `--status` for briefs directly under `briefs/`. With 1,000 files added under `closed/` (scratch repo `rc/`), one-argument `--status` measured 130 ms against 126 ms without them. The non-recursive `ls-tree` lists `closed` as one entry. A `closed/` argument itself cost 147 ms, since its `main_entry` lists `closed/`'s 1,000 entries. [unverified — submitted as claim]
- `CONSTRAINTS_AWK` makes one pass over `docs/constraints.md` with state bounded by the number of distinct constraint IDs. It adds a fixed 4 execs (12 → 16) and about 2–5 ms to `--settings`, with no growth across the r10 and r500 repos. [unverified — submitted as claim]
- `marker_kind` costs 2 git execs (`cat-file commit`, `rev-parse ^{tree}`), and only when the branch is at least one commit ahead. It parses the header with bash string operations, with no extra process per header line. [read: scripts/build-loop.sh:255-280]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `shared_branches` is O(N²): 2 `main_entry` per brief on main, each listing all of `briefs/`; 72 ms / 1.16 s / 15.7 s at N = 10 / 100 / 500; changes row 220's premise | Low | `scripts/build-loop.sh:287-291` | High |
| F2 | `status_line` reads each brief's entry 3× and blob 2× (`check_brief` runs in a subshell); 26 / 34 / 69 ms marginal per argument | Low | `scripts/build-loop.sh:298-302` | High |
| F3 | `--status` reads `docs/constraints.md` and never uses it; +4 execs, about 2–5 ms | Informational | `scripts/build-loop.sh:335` | High |
| F4 | `lower` forks `tr` per open brief (0.9 ms each) | Informational | `scripts/build-loop.sh:291`, `:312` | High |
| F5 | One `--status` call per brief would repeat F1 k times; U4 should call it once | Informational | `scripts/build-loop.sh:335-336` | Medium |
| F6 | Locale restore warns on stderr under an uninstalled locale; no time cost | Informational | `scripts/build-loop.sh:277` | High |

## Overall Assessment

U1c's performance is acceptable at the sizes this repo will see. `--settings` gains a fixed 2–5 ms. `--status` costs about 70 ms plus 20–35 ms per brief at today's 3 to roughly 30 briefs, and nothing is on a hot path. The one structural issue is F1. `shared_branches` calls `main_entry` twice per brief on main, and `main_entry`'s `ls-tree -t` lists every sibling, so the pass is quadratic: 15.7 s at 500 briefs, against under 1 s for a linear probe. What keeps it bounded is the cycle moving finished briefs to `closed/`, not the code. It can be fixed in place in the caller, using the modes from the one listing it already makes, and F2's duplicate brief read could go in the same change. This diff changes override-log row 220's premise, and that should be recorded either way. Rows 201 and 212 have their measurements above and need no action. No profiling beyond these measurements is needed. Re-run `bench.sh` if F1 is changed.

## Goal-Alignment Note
- Success criterion (restated verbatim): Your report saved at the path given in your task tail, structured per your skill, with every finding carrying a verbatim Evidence quote at a `path:line` in this worktree.
- Answered: yes. The report is saved, and all six findings quote verbatim lines at `path:line` with measured baselines (F5 is partly speculative and says so).
- Out of scope: whether stderr noise (F6) breaks the orchestrator's parsing, which is for api-consistency; the cost of check_branch and blocker themselves (U0 code, already settled).
- Escalate: row 220's premise has changed (F1), so the orchestrator should record an override-log decision for it in this unit. U4 should call --status once with every brief (F5).
- Questions I would have asked: what is the expected ceiling on open and queued briefs in `docs/working/briefs/` between cycles? It decides whether F1 should stay at Low.
- Decisions I made: I counted 2,000 filler commits per synthetic repo and 1 in 5 briefs open. I timed with medians of 3–11 runs under a load average of about 2. I treated `--status` as a cold path, per plan D1/D4.
