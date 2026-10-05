Commit: c143b929

# Performance Review — feat/build-loop-u1c, final pass (iteration 2)

**Scope:** `git diff feat/build-loop-u1b...feat/build-loop-u1c` at c143b929 (scripts/build-loop.sh `--status`, CONSTRAINTS_AWK, marker_kind, shared_branches; test fixtures)
**Date:** 2026-10-05
**Based on:** Stage-1 merged code-fact-check summary (docs/reviews/code-fact-check-report-build-loop-u1c.md, 32 Verified / 0 Incorrect); override rows 266-269; fix diff c143b929.

## Data Flow and Hot Paths

`build-loop.sh --status BRIEF...` is called by the dev cycle's orchestrator (U4's skill) to read each brief's loop state; `--settings` once per dispatch decision. Neither is a request handler: each is one CLI process per orchestrator iteration (cold-to-warm path). The cost driver is process forks: every git call is ~1.5-3 ms on this host. Per run, `read_settings` reads two blobs (dev-cycle.md, constraints.md) through `main_file` (ls-tree + cat-file|awk each, linear in file size, cheap). Per brief argument, `status_line` runs check_brief, brief_fields, check_branch and, for a tip ahead of main, marker_kind. Once per run (lazily, at the first brief that passes the Branch:/Dispatched: checks), `shared_branches` reads every brief on main.

What c143b929 changed for cost:
- `shared_branches` (`scripts/build-loop.sh:298-309`) now lists `docs/working/briefs/closed/` as well as `briefs/`, and calls `brief_fields` (one `main_entry` ls-tree -t + one cat-file|awk) for every file in both. It dropped the extra `main_entry` call per brief that 553a50d5 made, so per-brief cost fell, but N is now the lifetime brief count.
- `marker_kind` (`:273-293`) now forks `rev-list --parents`, `log -1 --format=%B` on every ahead tip, and for a `handoff:` subject also `cat-file|tr|wc` and two `rev-parse`.
- `shared_branches` is computed on first use from `status_line` (`:326`), so runs whose arguments are all new or skipped no longer pay for it.

Data sizes: this repo's main has 3 entries under `docs/working/briefs/` and no `closed/` (measured: `git ls-tree --name-only main -- docs/working/briefs/ docs/working/briefs/closed/ | wc -l` → 3). The dev-cycle skill moves every done or dropped brief into `closed/` (`skills/dev-cycle/SKILL.md:284`: "`git mv` the brief there") and nothing removes them, so `closed/` grows monotonically. Verify data size: the rate briefs are written per cycle is not documented.

## Findings

#### F1. shared_branches now scans every closed brief on each `--status` run: cost grows superlinearly with the project's lifetime brief count (premise of row 266 changed)

**Severity:** Medium
**Location:** `scripts/build-loop.sh:298-309` (with `:326`, and `scripts/lib/dev-cycle-read.sh:258-274`, `:289-312`)
**Move:** Ask "what's the size of N?" / hidden multiplication
**Classification:** Macro (per-brief ls-tree -t that lists all of briefs/ and closed/, times every brief ever closed) / Cold-to-warm path (one CLI call per orchestrator iteration, but over data that only grows)
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** `--status` with one argument and 3 open briefs, median of 3 runs on this host, 2026-10-05, scratch repos built by `mk.sh` (closed/ holding N done briefs): 553a50d5 → 70 / 70 / 69 / 70 ms at N = 0 / 50 / 200 / 500; c143b929 → 63 / 346 / 1,910 / 8,084 ms.

Evidence:
```
  list="$(git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/ docs/working/briefs/closed/)"
  while IFS= read -r f; do
    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
    b="$(lower "${BASH_REMATCH[1]}")"; n[$b]=$(( ${n[$b]-0} + 1 ))
  done <<<"$list"
```
and brief_fields' guard, per file: `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then ...` where main_entry runs `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"` (the `want` list names `docs/working/briefs/closed`, so each call lists every child of `briefs/` and `closed/`).

Row 266 deferred iteration 1's C1 because "Done briefs move to closed/, and this repo has 3 open", i.e. the scanned set was bounded by open briefs. c143b929 (A4) now reads `closed/` too, so the scanned set is every brief the project has ever had, and every done brief stays in it forever. Each closed brief costs two processes plus a pipeline (measured: 100 `ls-tree -t` lookups at N=500 took 173 ms; 100 `cat-file|awk` reads took 155 ms), and the ls-tree output itself grows with N, so the pass is ~5.6 ms per brief at N=50, ~9.5 ms at N=200, ~16 ms at N=500. Row 266's own revisit trigger ("more than 50 briefs on main") counts closed briefs once they live on main, so ordinary use now reaches it; at 50 lifetime briefs every `--status` call already costs ~5x what it did. Only the open ones matter for F31, but the status line is inside the file, so every one is read.

**Recommendation:** Read all briefs in one pass instead of per file: one `git ls-tree -r --full-tree "$MAIN_SHA" -- docs/working/briefs/` (it gives each entry's mode, so the regular-file test needs no per-file main_entry) piped to one `git cat-file --batch`, with FENCE_AWK applied per blob. A rough probe (ls-tree -r | cat-file --batch over 503 briefs, no awk parse) took 24 ms against 8.1 s. If that is deferred, update row 266: its "done briefs move to closed/" rationale no longer holds, and the trigger should name the lifetime count.

#### F2. marker_kind forks five more processes per `handoff:` tip than before

**Severity:** Informational
**Location:** `scripts/build-loop.sh:276-282`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (fixed per tip) / Cold (at most one per brief; loops at once are capped by slots, 1-9)
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** 50 iterations of each fork set on a ready-marker tip, this host, 2026-10-05: 553a50d5's set (cat-file + rev-parse) 112 ms (2.2 ms/tip); c143b929's set for a handoff tip (rev-list, log, cat-file|tr|wc, rev-parse x2) 342 ms (6.8 ms/tip); for a working tip (rev-list, log) 123 ms (2.5 ms/tip). End-to-end `--status` medians differed within run-to-run noise (~96-110 ms).

Evidence:
```
  read -ra p <<<"$(git rev-list --parents -n 1 "$1")"
  msg="$(git log -1 --format=%B "$1")"; subj="${msg%%$'\n'*}"
  [[ "$subj" == handoff:* ]] || { echo working; return; }
  if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi
  ...
  if [[ "$(git rev-parse --verify "$1^{tree}")" != "$(git rev-parse --verify "${p[1]}^{tree}")" ]]; then echo "bad it changes files"; return; fi
```
(function continues to `:293`: subject checks and the stopped-reason grep, one more fork for a stopped tip.)

About +4.6 ms per marked tip, at most ~9 per run: ≤ ~40 ms. The cost buys git-parsed parents/tree (A1), so this is noted, not a request. One `git log -1 --format='%P%x00%T%x00%B'` measured 53 ms per 50 (1.1 ms/tip) if it is ever wanted, though the NUL check would still need the raw object.

## Endorsements

- c143b929 removed the second `main_entry` per brief from shared_branches (brief_fields' own guard now does the blob check), halving that pass's tree lookups per brief. `[read: scripts/build-loop.sh:303, scripts/lib/dev-cycle-read.sh:289-312]`
- `shared_branches` runs at most once per process and only after a brief passes its Branch:/Dispatched: checks; a `--status` run whose arguments are all new or skipped does not pay for it. `[read: scripts/build-loop.sh:297, :310-326]`
- CONSTRAINTS_AWK is one awk pass, linear in the constraints file, with constant work per line. `[read: scripts/build-loop.sh:161-183]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | shared_branches scans closed/ per run; 8.1 s at 500 lifetime briefs (row 266 premise changed) | Medium | `scripts/build-loop.sh:298-309` | High |
| F2 | marker_kind +5 forks per handoff tip (~+4.6 ms) | Informational | `scripts/build-loop.sh:276-282` | High |

Not re-filed (settled, premise unchanged): rows 267 (repeated parses, tr per brief: still one `tr` per open brief, now including any open brief in closed/), 268 (constraints read under --status), 269 (U4 should call --status once; F1 makes that more important, since a per-brief call repeats the 8 s pass each time).

## Overall Assessment

The fix commit trades one cost for another: it halved the per-brief tree lookups in shared_branches but widened the scan from open briefs to every brief ever closed, so `--status` cost now grows with the project's age rather than its work in progress. At today's 3 briefs it costs nothing extra; at 50 lifetime briefs it is ~350 ms, at 500 ~8 s, and done briefs never leave closed/. That is fixable in place with a single ls-tree -r | cat-file --batch pass, or deferred with row 266 reworded so its trigger counts closed briefs. The marker_kind change is a small fixed cost per marked tip and not worth acting on. Measurements were wall-clock on a shared, loaded WSL host; the shape (superlinear in N) is clear, absolute numbers vary by ~20%.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path your task names, structured per your skill, with a `Commit: c143b929` first line.
- Answered: performance review of the unit diff at c143b929, with measured baselines for the two changed premises the task named (closed/ in shared_branches, marker_kind forks) and the lazy shared_branches path.
- Out of scope: C1-C5 of iteration 1 except where c143b929 changed a premise (F1 re row 266); review-artifact docs under docs/reviews/; U3/U4 callers.
- Escalate: F1 to the orchestrator: row 266's deferral rationale ("Done briefs move to closed/") no longer holds after A4, so the row needs a new decision (fix now, or re-defer with a trigger on lifetime brief count).
