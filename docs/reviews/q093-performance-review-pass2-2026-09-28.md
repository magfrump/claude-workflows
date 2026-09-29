# Performance Review — q093-cc-push-self-commondir, pass 2

**Scope:** `git diff 2c8163f..b9f6cc4` (`devcontainer-config/cc-push.sh`, `test/cc-push.bats`, `docs/working/plan-q093-cc-push-self-commondir.md`); pass 1 (`q093-performance-review-2026-09-28.md`) is context only
**Date:** 2026-09-28
**Based on:** `docs/reviews/q093-code-fact-check-report-pass2.md` (12 Verified, 1 Mostly accurate; Claim 1 executed the FIFO-swap race)

## Data Flow and Hot Paths

`commondir_is_self` runs at most once per `cc-push` invocation, from `check_checkout`, and only when `.git/commondir` exists. It is a cold path: a one-shot CLI precondition run by hand on the host. The only runtime change in this delta is on `cc-push.sh:276`: the read is now `timeout 5 head -c 2 -- "$c" 2>/dev/null | od -An -tx1`. That is one extra `timeout` process per call, plus a worst case of about 5 s if a FIFO is swapped in after the `-L`/`-f` test. Before this change, the worst case was an unbounded hang. The script runs under `set -euo pipefail` (`:112`), so a kill (exit 124) fails the pipeline, `|| return 1` fires, and the file is refused. The fact-check (Claim 1, executed) confirms that the swapped-in FIFO is refused after about 5 s. The test and plan changes do not affect runtime.

Pass-1 finding 1 (Low: the helper's own `head` could block on a swapped-in FIFO) is resolved by this delta.

## Findings

#### A timed-out read is reported as an ordinary commondir refusal

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:276, 295`
**Move:** Contention point / resource lifecycle (blocking read)
**Classification:** Micro (a bounded 5 s stall, only when a race is lost) / Cold path (one-shot CLI precondition)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

When the timeout fires, the operator waits about 5 s with no output. They then get the generic "`.git/commondir` exists … it can name another repository" message, which does not mention the stall or the FIFO. The sibling bounded call (`timeout 20 docker ps`, `:228`) reports its failure separately ("docker did not answer"). This path is only reachable if something swaps a FIFO in between two adjacent syscalls, and that is the B11 residual that `check_no_container` already guards. So the missing detail costs almost nothing in practice.

**Recommendation:** No change needed. If anyone ever asks why cc-push paused for 5 s, add a distinct refusal when the pipeline exits 124.

## Endorsements

- The 5 s bound is proportionate next to the sibling `timeout 20 docker ps` (`cc-push.sh:228`, also mirrored in `install.sh:1239`). A local read of at most 2 bytes needs far less headroom than a docker daemon round trip. `timeout` is already a dependency at `:228`, so this adds no new requirement. [read: devcontainer-config/cc-push.sh:228,271-279]
- With `pipefail` set, a killed `head` makes the pipeline fail, so a timeout refuses the file rather than accepting it. An empty `od` output would fail the hex compare anyway. [fact-check: claim 1 — Verified (executed)]
- The type test (`-L`, `-f`) and the `stat` size gate still run before the timed read, so the normal case costs the same as in pass 1 plus one `timeout` fork. [read: devcontainer-config/cc-push.sh:271-279]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A timed-out read is reported as an ordinary commondir refusal | Informational | `devcontainer-config/cc-push.sh:276, 295` | Medium |

## Overall Assessment

This delta closes the one pass-1 performance finding with a one-token change that matches existing practice in the script. Nothing new is on a hot path. The only residual is a cosmetic gap in diagnostics on a race path that should essentially never happen. No profiling is needed. From a performance standpoint, the branch is clear to merge.
