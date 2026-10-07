Commit: 4828727d

# Performance Review: feat/build-loop-u2a3b (loop 2, confirming pass)

**Scope:** `git diff main...4828727d -- . ':!docs/reviews'`, focused on aa379ee9 (the work charge and `tried` memo in `put`, import_home's raw-HOME key)
**Date:** 2026-10-07
**Based on:** the Stage 1 summary (`u2a3b-L2confirm-stage1.md`; its measurements are not repeated here) and my previous report `performance-reviewer-review-2026-10-07-L2final-build-loop-u2a3b.md`

I ran all measurements on 2026-10-07 between 09:02 and 09:20, using `git archive` copies of main, e1654266 and 4828727d in `/tmp/u2a3bperfc-ZzJl/{main,e165,br}`. The awk is mawk 1.3.4. I ran the parser directly through `awkrun.sh`, which extracts `IMPORT_AWK` from each lib and reports rc, wall time and the child's max RSS. The root was `/tmp/u2a3bperfc-ZzJl/root` (25 characters). The host was shared with other agents (load average 0.2-4.8), so the interleaved pairs are the numbers to compare.

## Prior findings: do the fixes hold?

| Prior | Disposition in aa379ee9 | Holds? | Evidence (executed) |
|---|---|---|---|
| F1: the work bound ignored depth, so a depth-50 4 MiB file ran 22-59 s and succeeded | `put` charges `length(c)` and memoises on `c` | **Yes** | 4 MiB of `@a `, depth 50: rc=3 in 0.40 s (21.86 s and rc=0 at e1654266). The densest prior shape (`@` + 23 random characters + blank, 4 MiB), depth 50: rc=3 in 0.65 s (59 s and rc=0 before). The same shape at depth 0: rc=3 in 1.81 s (8.0 s and rc=0 before). |
| F2: the 50M bound had no test | test added | **Yes** (Stage 1: the no-charge mutant fails its test) | not re-run |
| F3: getent was forked per file with HOME unset | key on raw `HOME` | **Yes** | `/workspace --check-fix README.md`, 3 interleaved runs. e1654266: HOME set 1.10/1.10/1.12 s, unset 1.27/1.29/1.37 s. Branch: set 1.16/1.14/1.11 s, unset 1.08/1.12/1.16 s. The +0.17-0.25 s penalty is gone. |
| F4: per-file fixed cost of 4-5 ms | Informational, re-pricing only | unchanged | see the --check-fix row below |

## Cost of --check-fix against main (executed)

| Run | main | e1654266 | 4828727d |
|---|---|---|---|
| worktree, `--check-fix README.md`, 5 interleaved | 0.39-0.41 s | 0.58-0.67 s | 0.57-0.66 s |
| worktree, all 3,053 tracked paths through xargs, 3 interleaved | 12.63 / 12.11 / 7.94 s | — | 14.97 / 9.08 / 7.32 s |

On the all-paths row, the outputs are byte-identical (`cmp` passes). Load rose from 0.2 to 4.8 during that row, so it is noise-dominated. The one-path row is the clean measurement. aa379ee9 adds nothing measurable over e1654266. The unit's gap against main is still about +0.2 s per walk in the worktree, which is the per-file fixed cost already priced in F4.

## Findings

#### P1. `tried` holds up to about 140 MB on the main walk's uncapped blob, and about 50 MB under the tree walk's 4 MiB cap

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:557-563` (`put`)
**Move:** Resource lifecycle (memory growth of a per-file memo)
**Classification:** Macro (memory linear in distinct candidates) / Cold path (one walk per CLI run), adversarial data only
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** 18.2 MB file of 2.6M distinct `@/xxxx` tokens: branch rc=3 in 4.75 s with max RSS 139,852 KB; e1654266 rc=0 in 9.35 s with 10,440 KB. The same file capped at 4 MiB: branch rc=0 in 1.64 s with 51,056 KB; e1654266 rc=0 in 2.12 s with 10,384 KB.

Evidence (verbatim):
```
  work += length(c); if (work > 50000000) exit 3
  if (c in tried) return
  tried[c] = 1
```
(`put` continues by splitting, resolving, and checking `seen` and `printed`.)

Each new key is charged its length before it is stored. The work bound therefore caps the memo, so memory cannot grow without bound. The cheapest key per unit of charge is a 4-byte absolute name outside the repo, at about 20 work units per token across `emit` and `put`. That gives at most about 2.5M entries before `exit 3`. mawk spends about 55 bytes per entry, so the ceiling is roughly 140 MB. Names outside the repo never reach `printed`, so IMPORT_LEFT and IMPORT_OUT_MAX do not stop this shape. Only the 50M bound does. The memo is per awk process, so it is freed when each file finishes and does not accumulate across files. The trade buys the F1 fix and is faster on this input (4.75 s against 9.35 s). This is not a defect. I am recording the ceiling so that a future bound change (for example, raising 50M) is priced on memory as well as time.

**Recommendation:** None before merge. If the bound is ever raised, scale this ceiling with it, at about 2.8 MB of RSS per 1M work units.

#### P2. The per-file ceiling is now about 5 s, and there is still no work bound across files

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:557-577` (`put`'s resolve loop); `:489-495` (IMPORT_OUT_MAX counts only printed output)
**Move:** Asymptotic behaviour (the worst shape the bounds do not stop)
**Classification:** Macro (resolve cost O(components × path length) against a charge of O(path length)) / Cold path, adversarial data
**Confidence:** High for the per-file numbers (executed). Medium for the cross-file total (reasoned; the end-to-end run was masked, see Deferred items).
**Legibility-target:** for-author
**Baseline:** one line of `@` + `./`×2,300 with `$1` 2,000 components deep (a path of about 4,000 characters, within PATH_MAX): rc=0 in 3.54 s. Depth 4,000 (main walk only), `./`×2,000: rc=0 in 4.85 s. One token of `/a`×3,500 at depth 0: rc=0 in 3.46 s.

Evidence (verbatim):
```
  n = split(c, part, "/"); k = 0
  for (i = 1; i <= n; i++) {
    if (part[i] == "" || part[i] == ".") continue
    if (part[i] == "..") { if (k > 0) k--; continue }
    st[++k] = part[i]
  }
  out = ""; for (i = 1; i <= k; i++) out = out "/" st[i]
```
(`put` then checks the prefix and `seen`, then prints.)

`put` now charges `length(c)`, but the join loop copies `out` once per kept component. mawk has no in-place append, so one put costs O(k × length(c)) and is charged O(length(c)). Each candidate is distinct under `tried`, so the memo does not help. A token whose components are all `./` or `a/..` resolves every prefix to the same `out`, which `seen` dedups. It prints nothing, so only the 50M bound applies. I searched the shapes (distinct short names, long `/a/a` tokens, `./` runs, relative names at depths 0-4,000). Every one either tripped a bound in 0.4-5.5 s or succeeded in 5 s or less. At e1654266 the same `./` input took 6.54 s at depth 2,000, so this is not a regression. It is the residue of F1. The per-file case is now bounded, and the comment's "fails the walk rather than stalling it" is fair for a single file.

The cross-file case is not bounded. The 50M bound and the 4 MiB head cap reset per file, and IMPORT_OUT_MAX sees only printed bytes. N deep instruction files therefore cost up to about N × 4-5 s and can still print `ok`. The bound's comment at `:489-492` says it is per file, so this is documented, not hidden.

**Recommendation:** Not needed for merge. If U2a3c builds the shared reader, a walk-wide work counter (pass the remaining work in, as IMPORT_LEFT is passed) would close it. Joining with `out = out "/" st[i]` is the hot spot. Building `out` once with a single `sprintf` or a join over `st` would not change the O(k × len) cost in mawk, so the walk-wide counter is the fix that matters.

## Deferred items re-checked

- **A deep start directory is dominated by `inrepo_here`/`blocker`, not the parser (pre-existing, outside the diff):** I built a scratch repo with four CLAUDE.md files 1,900-1,903 directories deep. `--check-fix docs/guide.md` timed out at 300 s on both e1654266 and the branch, and at 60 s on main. A `bash -x` trace shows the time is in `plaindir`'s `realpath -e` fork per path component, run per prefix, which is quadratic in depth. `blocker`, `plaindir` and `inrepo_here` (`:106`, `:131`) are not changed by this unit. The diff only moves `-f` ahead of `inrepo_here` (`:690`), which reduces calls. So this is the "blocker per directory prefix" deferred item, and its cost is unchanged by aa379ee9. It also hid any parser contribution in that end-to-end run, which is why P2's cross-file figure is reasoned. The scratch repo has been removed.
- **The main walk's uncapped blob read:** still routed to U2a3c (override row). P1's 140 MB figure applies only to that path.
- **IMPORT_LEFT on a single long token** (`@` + 7,000 `a`): rc=3 in 0.04 s on both versions, unchanged.

## Endorsements

- aa379ee9's charge and memo turn every F1 shape I re-ran from a 22-59 s success into a failure in under 1 s at depth 50 (`@a` 0.40 s, the 23-character shape 0.65 s). `[unverified — submitted as claim]` Location: `scripts/lib/dev-cycle-read.sh:561-563`
- `import_home`'s raw-HOME key removes the HOME-unset penalty: branch unset 1.08-1.16 s against set 1.11-1.16 s in /workspace. `[unverified — submitted as claim]` Location: `scripts/lib/dev-cycle-read.sh:617-622`
- aa379ee9 adds no measurable cost on real repo files. `--check-fix README.md` in the worktree took 0.57-0.66 s on the branch and 0.58-0.67 s on e1654266, 5 interleaved runs. `[unverified — submitted as claim]` Location: `scripts/lib/dev-cycle-read.sh:541-604`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| P1 | `tried` memo memory ceiling of about 140 MB (main walk, uncapped blob) and about 50 MB (tree walk), bounded by the 50M charge | Informational | `scripts/lib/dev-cycle-read.sh:557-563` | High |
| P2 | `put`'s join is O(components × len) against an O(len) charge: per-file ceiling of about 5 s succeeding; still no cross-file work bound | Low | `scripts/lib/dev-cycle-read.sh:557-577`, `:489-495` | High (per file) / Medium (cross-file) |

## Overall Assessment

aa379ee9 does what my previous report asked. F1's shapes now fail in under a second, F3's getent penalty is gone, and the real-repo cost is unchanged from e1654266, about +0.2 s per walk against main from the per-file fork overhead already priced. The memo's memory is bounded by the same charge that bounds time, with a ceiling of about 140 MB reachable only on the main walk's uncapped blob (routed). The remaining worst case is about 5 s per adversarial file and is additive across files, because no counter spans the walk. That is a cold-path, fail-closed residue (no `ok` is printed while a walk runs), documented in the bound's comment. It fits U2a3c's shared reader. I found nothing that blocks merge on performance grounds. The pre-existing quadratic `blocker`/`plaindir` cost on very deep directories dominates any parser worst case and is outside this diff.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 4828727d` line at the top.
- **Answered:** whether F1-F3's fixes hold (executed: yes). The memo's memory growth (P1: bounded, measured ceiling). The worst cases that the 50M bound and IMPORT_OUT_MAX do not stop (P2: about 5 s per file, unbounded across files). Time on real repo files (no change from e1654266). import_home's caching (executed). --check-fix cost against main (+0.2 s per walk, identical output).
- **Out of scope:** the main walk's uncapped blob (U2a3c override row). The `blocker`/`plaindir` per-component forks (pre-existing, unchanged; noted under Deferred items). Correctness and wording (Stage 1 S1-S7).
- **Escalate:** nothing. P2's cross-file bound is a routing candidate for U2a3c, for the orchestrator to place.
- **Decisions I made:** I rated P2 Low rather than Medium. It is cold-path and fail-closed, it is not a regression (e1654266 was slower on the same input), and the bound's comment already says it is per file. I did not count the deep-directory e2e timeout against this unit, because main times out on it too and the trace places the cost in unchanged code.
