Commit: 09cb3764

# API Consistency Review — feat/build-loop-u0b, iteration 2 (fix 09cb3764)

> ⚠️ **No code fact-check report provided for iteration 2.** The fix's header and comment claims were checked against the code here, by reading and by running it. The iteration-1 report (docs/reviews/code-fact-check-report-build-loop-u0b.md) covers the move commit.

**Scope:** `git diff feat/build-loop-u0b~1 feat/build-loop-u0b` (fix 09cb3764), plus `git range-diff 7cbbe8d2^! feat/build-loop-u0b~1^!`. The rebase only changed header comments and T29's list; the range-diff shows nothing else. Consumers: dev-cycle.sh now, the planned scripts/build-loop.sh later.
**Date:** 2026-10-05
**Based on:** docs/reviews/api-consistency-reviewer-review-2026-10-04-build-loop-u0b.md (iteration 1), docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0b.md, override-log row 201

## Prior findings

| Iteration-1 item | Status | Evidence |
|---|---|---|
| API Finding 1 / rubric A1: the default-branch globals had two failure modes for one mistake (unset aborts, empty misreports `ok`) | **Closed** | The globals are initialised at source time (`scripts/lib/dev-cycle-read.sh:218`, `MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""`). `main_by_name` (`:219`) gates both checks (`:229`, `:275`). Forgetting resolve_main, ignoring its 1 and the current-branch fallback now all give the same `skip … no default branch found by name` line, never `ok`. The new bats test covers the before-resolve and fallback cases. Removing the two guard lines makes it fail; I ran that mutation in this pass. |

## Baseline Conventions

These are unchanged from iteration 1. Points that bear on the fix:

- Check output is one line per argument. `skip X: why` means unreadable; `refuse X: why` is a verdict (plan, "Output follows dev-cycle.sh's check-mode conventions"). A skip line that may echo raw input sanitises newlines with `${a//$'\n'/ }` (e.g. `check_brief`'s pathform skip, `:230`).
- dev-cycle.sh's own wording for this condition: "$CHECK needs a default branch (origin/HEAD, main or master); found none" (`scripts/dev-cycle.sh:188`).
- From U0a, a missing caller precondition (ROOT_REAL) exits 1 through `need_root` with a message that names the caller's mistake (`:71`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_by_name` | function (predicate) | `inrepo`, `dirok`, `isbrief` | `scripts/lib/dev-cycle-read.sh:97,100,133` | Consistent: an unprefixed status-returning predicate. It is named after the `MAIN_BY_NAME` global it reads. |
| skip text `no default branch found by name (origin/HEAD, main or master)` | message | "… needs a default branch (origin/HEAD, main or master); found none", "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" | `scripts/dev-cycle.sh:183,188` | Consistent: the same parenthetical list as the CLI refusal, in `skip X: why` form |
| `MAIN`, `MAIN_SHA`, `MAIN_BY_NAME` initial values | globals | `SKIPPED=(); SKIP_AT=""` | `scripts/lib/dev-cycle-read.sh:82` | Consistent: lib-owned globals are now all initialised when the lib is sourced |

## Findings

#### 1. Two missing caller preconditions, two failure policies, and the skip names the wrong cause

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:71`, `:215-219`, `:229`, `:275`
**Move:** #4 error consistency
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (at 09cb3764):
```
need_root() { [[ -n "${ROOT_REAL:-}" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not set; the caller sets it before any file check" >&2; exit 1; }; }
```
```
  if ! main_by_name; then echo "skip ${a//$'\n'/ }: no default branch found by name (origin/HEAD, main or master)"; return; fi
```

A caller that forgets ROOT_REAL gets an exit and a message naming its own mistake. A caller that forgets resolve_main gets one `skip` line per argument saying the repo has no default branch. That is a statement about the repo, and it is false in that case. Both outcomes fail safe: neither prints `ok`. The skip is also right for a repo with no main. The cost is debugging: the first author of build-loop.sh who misses the resolve_main call will look for a repo problem. dev-cycle.sh never reaches these skips, because it refuses the two modes first (`scripts/dev-cycle.sh:187-189`), so no current output changes.

**Recommendation:** No change needed to land. If you want the two failures to match, `main_by_name` could tell "never resolved" (an empty `MAIN`) apart from "resolved, not by name", and only the latter would skip. The other option is one header clause saying that the skip also covers a missing resolve_main call.

#### 2. The header's resolve_main clause has an unclear subject

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:10-14`
**Move:** #3 consumer contract (documentation)
**Confidence:** High
**Legibility-target:** for-author

Evidence (at 09cb3764):
```
# cds to the repo root and sets ROOT_REAL (that root, symlinks resolved) before
# calling any file check; a check run without it exits 1 (need_root). It calls
# resolve_main once per process (a second call re-reads main); check_brief and
# check_branch skip every argument unless main was found by name. Every script
```

The "It" in "It calls resolve_main" follows "a check run without it", where "it" is ROOT_REAL. The intended subject is the caller, two clauses back. "Once per process" also reads as a rule, while the parenthesis says a second call is allowed. iteration 1 noted that resolve_main resets its outputs and can be re-run, so that parenthesis is accurate. This is the contract build-loop.sh's author will read first.

**Recommendation:** Say "The caller runs resolve_main before check_brief or check_branch (it may run it again to re-read main)."

## What Looks Good

- **dev-cycle.sh's CLI, `--help` and exit codes are unchanged apart from the documented missing-lib exit.** I ran the same nine probes as for U0a at this tip and at feat/build-loop-handoff. Exit codes were identical. The only output difference was `--help` line 75, the Exit wording. In a repo on `trunk` with no main or master, `--check-brief` and `--check-branch` print the base's refusal and exit 1, so the lib's new skip lines cannot be reached from the CLI. `route: code-fact-check`
- The guard comes before `pathform` and sanitises the echoed argument (`${a//$'\n'/ }`), the same way the existing pre-validation skips do. A raw newline in an argument therefore cannot split the answer line.
- Dropping the stale `SC2034` from FENCE_AWK's directive (`:160`) leaves it disabling only SC2016, which matches what that line needs. The resolve_main test now asserts the return code (`none 1:`), which pins return-not-exit more tightly.
- bats at this tip: 58/58 ok, run in this pass.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Missing ROOT_REAL exits naming the caller; missing resolve_main skips naming the repo | Informational | `scripts/lib/dev-cycle-read.sh:71,215-219,229,275` | Medium |
| 2 | Header's "It calls resolve_main once per process" has an unclear subject and reads as a rule | Informational | `scripts/lib/dev-cycle-read.sh:10-14` | High |

## Overall Assessment

The fix closes iteration 1's Minor finding and the rubric's A1. The lib's default-branch state is now initialised when the lib is sourced, and every way of reaching check_brief or check_branch without a by-name main gives the same safe skip. The new predicate and the skip wording follow existing neighbours. dev-cycle.sh's consumer surface is unchanged. Both new findings are wording notes for the next consumer, and either can be addressed in U1 if not now.

## Goal-Alignment Note

The goal is a verbatim move plus the one deliberate API change, returning instead of exiting, made safe for a caller that is not dev-cycle.sh. The fix moves the by-name rule from dev-cycle.sh's caller code into the lib, so build-loop.sh inherits it without having to copy it. It does this without changing dev-cycle.sh's output, which still refuses before the lib is reached. The findings above concern how clearly the contract is worded, not whether the code behaves correctly. Deferred row 201 (check_brief's history walk) is unaffected.
