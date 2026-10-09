Commit: 1f4f7a21

# Performance Review — feat/build-loop-u2b2, final confirming pass (U2b2, the gate's checkout)

**Scope:** full branch main...1f4f7a21 (`scripts/build-loop.sh` help text, `callervar`, `gate_repo`, `checkout_gate` :626-692 read whole, `check_line` :699-758 read whole, the `check)` mode block :769-780; `scripts/lib/dev-cycle-read.sh` contract item 3 and `import_reset` :608; the five new bats tests read for context)
**Date:** 2026-10-08
**Based on:** final code-fact-check k=3 (docs/reviews/code-fact-check-report-build-loop-u2b2-final-r1..r3.md, as summarized in the brief); my iteration reports docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b2.md and -i2.md; override-log row 528

## Data Flow and Hot Paths

`--check BRIEF...` runs once per merge decision by the orchestrator and as a loop's advisory dry run. It is a cold path; nothing calls it per request. The `check)` block sets up `GATE_TMP` and the gate repository once. It then runs `check_line` once per argument in a `$(...)` subshell. The branch adds two things to each `check_line`:

1. `import_reset`, which is two variable assignments (`dev-cycle-read.sh:608`).
2. For a brief whose own policy is self-merge, and only after status, branch, `--expect`, merge and diff-tree have passed, one `checkout_gate` pass. That pass runs these steps:
   - `rev-parse --local-env-vars`, plus an env scan
   - a HEAD check, which a loop's advisory run from its own branch fails at, so that run stops after two `rev-parse` calls
   - three `git config` reads
   - `ls-files -v | tr | awk`
   - `git status` to a file
   - `ls-files --others` to a file, then `tr | awk`
   - `ls-tree -r -z` to a file
   - a bash read loop over every tree record
   - one `hash-object --no-filters --stdin-paths` over every regular file main stores, compared as one string

N inside the gate is the tracked-file count and tracked bytes (3,174 files here). K, the number of passes per `--check`, is the number of self-merge briefs in ARGS that reach the gate. The fact-check notes that nothing caps K at the slot count: `--check` takes any number of briefs.

Since my i2 pass (368a3194), the only commit, 1f4f7a21, changes comments, help text, the plan and the lib header. The `checkout_gate` and `check_line` code is byte-identical. This pass still read the whole branch fresh.

Probe (git 2.39.5; temp dir /tmp/perffu2b2-*, created and entered in the probe script, removed afterwards and confirmed gone; `GIT_OPTIONAL_LOCKS=0` so `git status` wrote no index refresh). `checkout_gate` and `callervar` were extracted verbatim from build-loop.sh and run against this worktree with MAIN_SHA = HEAD. Load average was 0.33-0.39 before and after. The only other busy process was one `claude` session at 5% CPU, with no leftover loops.

| Measurement | Time |
|---|---|
| Whole gate, one pass, clean (5 runs) | 0.274, 0.275, 0.274, 0.280, 0.479 s (one outlier) |
| Nine passes back to back | 2.554 s |
| `git ls-files -z --others` (no excludes) in /workspace's main checkout | 0.007 s, 1,011 records |

## Findings

No findings.

Two recorded items still stand, and their basis has not changed, so neither is raised again:

- **Per-brief multiplication (override row 528, Accepted, revisit trigger 10 s).** Re-measured at 0.27-0.28 s per pass and 2.55 s for nine, against 0.24-0.25 s and 2.39 s at i2. The difference fits noise plus 4 more files. That leaves it about 4x below the trigger at nine briefs on this repo. The brief says the fact-check found K is not enforced, which changes the comment's wording but not the price: cost is linear in K, and the path is cold.
- **i1's scaling notes (Informational): full rehash, record loop, unexcluded `--others` listing.** The code is unchanged. In this repo's main checkout the unexcluded listing costs 7 ms, because nested worktrees are listed as one `dir/` record each and are not descended.

## Endorsements

- `import_reset` added to every `check_line` costs two assignments. Each brief's walk cache is cleared inside its own subshell, so no walk work moves into the hot loop. [read: scripts/build-loop.sh:701, scripts/lib/dev-cycle-read.sh:608]
- The gate runs only for a self-merge brief, and only after the brief's status, branch, `--expect`, merge and diff-record checks have passed. A brief refused earlier, or any review brief, pays nothing for it. [read: scripts/build-loop.sh:703-740]
- The claim to check: hashing is one `hash-object --stdin-paths` process for all regular files, not one per path. The process count per gate pass is fixed (about 10 git/tr/awk processes plus one `ls -A` per gitlink) and does not grow with the tracked-file count. [unverified — submitted as claim]
- `git status`, `ls-files --others` and `ls-tree` write to files under `GATE_TMP` instead of `$(...)` captures. The bash-held state is the `ps`/`ids` arrays and one hash string, linear in tracked files (3,174 here). [read: scripts/build-loop.sh:651-692]
- The claim to check: the gate's per-pass cost on this repo is 0.27-0.28 s at load ~0.35 (5 runs), and 2.55 s for nine passes. This agrees with the comment's "about 0.25 s here" to within about 10%, and with the fact-check's 0.28-0.36 s under load ~3. [unverified — submitted as claim] (my probe above)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings (row 528 and i1's notes stand, with no change in basis) | — | — | — |

## Overall Assessment

This is a cold, bounded change, and its performance posture is the same as at i2. The final commit changes no code. The per-pass cost re-measured within noise of the earlier passes, and the one structural cost, the gate re-run per self-merge brief, is already accepted with a 10 s revisit trigger that this repo is far from. Nothing needs fixing before merge, and no further profiling is needed.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b2-final.md (first line `Commit: 1f4f7a21`), structured per the critic skill.
- Answered: yes. I reviewed the whole branch fresh, re-measured the gate's cost against the recorded basis, and found no new performance issues.
- Out of scope, noted for the orchestrator and not raised here:
  - /workspace's main checkout currently holds 19+ agent worktrees under `.claude/` (`.claude/wt-build-loop-*`, `.claude/worktrees/*`). `ls-files --others` lists them as `dir/`, so `checkout_gate` would refuse every self-merge brief run from there ("untracked nested repository"). This is the intended fail-closed behavior (override row 432; fact-check claim 8), but it means self-merge `--check` needs a checkout with no nested worktrees.
  - In this shell, where the caller's LC_ALL names a locale that is not installed (en_US.UTF-8), each gate pass printed a bash `setlocale` warning on stderr when `local -x LC_ALL=C` was restored on return. It is cosmetic, and the bats suite runs with an installed locale.
- Escalate: nothing.
- Decisions I made:
  - I timed the gate by sourcing the verbatim `checkout_gate`/`callervar` against this worktree with MAIN_SHA = HEAD, rather than running `--check` end to end with a self-merge fixture.
  - I set `GIT_OPTIONAL_LOCKS=0` (not a repo-local variable, so the gate's env scan ignores it) so the probe wrote nothing into the worktree's git dir.
