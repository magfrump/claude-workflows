Commit: 7cbbe8d2

# API Consistency Review — feat/build-loop-u0b (U0b: FENCE_AWK/oddwhy, check_brief, check_branch, resolve_main into the lib)

**Scope:** `git diff feat/build-loop-u0a..feat/build-loop-u0b` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats); consumer = dev-cycle.sh and the planned scripts/build-loop.sh ("resolves `MAIN_SHA` once and calls the lib directly")
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0b.md (Stage 1; its Claim 5 on the resolve_main precondition, Claim 6 on the redundant SC2034, Claim 7 on the by-name rule living in the caller, and Claim 10 on the test's "1" are not re-filed)

## Baseline Conventions

Same baseline as the U0a review (scripts/lib/*.sh and their callers), plus the lib's own conventions as U0a set them:

- Lib functions communicate by return status and by setting documented globals: `skipped` sets `SKIP_AT`, appends to `SKIPPED` and returns 1 when nothing blocks (`scripts/lib/dev-cycle-read.sh:94` at this tip).
- Globals the lib owns are initialised at source time: `SKIPPED=(); SKIP_AT=""` (`:75`), `NAMECHARS`, `DIGIT`, `SLUG`.
- Preconditions are stated once in the header's caller contract (`:7-12`).
- Repo-wide, precondition failures in lib helpers `exit 1` (`require_command`, `scripts/lib/preflight.sh:6-12`); the plan asks this one to return instead.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `resolve_main` | function | `require_command`, `classify_skill_path`, `skipped` | `scripts/lib/{preflight,skill-paths}.sh`, `scripts/lib/dev-cycle-read.sh:94` | Consistent: snake_case verb_noun; "set globals, return status" matches `skipped` |
| `MAIN`, `MAIN_SHA`, `MAIN_BY_NAME` (now lib-owned outputs) | globals | `SKIPPED`, `SKIP_AT` | `scripts/lib/dev-cycle-read.sh:75` | Name consistent (UPPER_SNAKE); initialisation not — see Finding 1 |
| `FENCE_AWK`, `oddwhy`, `check_brief`, `check_branch` | moved | (verbatim from dev-cycle.sh) | `git show feat/build-loop-u0a:scripts/dev-cycle.sh` | Consistent — names unchanged |

## Findings

#### 1. The lib's default-branch globals have two failure modes for one mistake

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:7-12`, `:259-271`, `:278-300`
**Move:** #8 nullability / #3 consumer contract
**Confidence:** High
**Legibility-target:** for-author

Evidence (at 7cbbe8d2):
```
SKIPPED=(); SKIP_AT=""
```
```
resolve_main() {
  local c sha cur origin_head candidates=()
  MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""
```
(excerpt ends :280; resolve_main continues to :300, ending `[[ -n "$MAIN_SHA" ]]` — read)
```
  elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"
```
(from check_branch, :259-271 — read whole)

Unlike `SKIPPED`/`SKIP_AT` (and, from U0c, `IMPORTED`), `MAIN`/`MAIN_SHA`/`MAIN_BY_NAME` are not initialised when the lib is sourced; only `resolve_main` sets them. So a caller that forgets resolve_main gets one behaviour and a caller that runs it and ignores a 1 gets another. Probe at the U0c tip (same code): `bash -c 'set -euo pipefail; source scripts/lib/dev-cycle-read.sh; check_branch foo'` → `scripts/lib/dev-cycle-read.sh: line 264: MAIN: unbound variable`, exit 1, a loud abort. But after `resolve_main` returns 1 the globals are empty strings, and FC Claim 5's E5 shows check_brief and check_branch then print plausible `ok` lines (a landed brief read as `new`, a branch counted against HEAD). For build-loop.sh, which the plan says resolves once and calls the lib directly, the safe failure depends on which mistake the author makes. FC Claim 5 recommends wording; this finding is about the inconsistent contract, not the wording, and does not re-file it. No existing consumer is affected: dev-cycle.sh exits on a 1 (or refuses the two modes when `MAIN_BY_NAME` is empty).

**Recommendation:** Make the two mistakes fail the same way. Either have check_brief/check_branch emit a `skip` (or return non-zero) when `MAIN_SHA` is empty, which is the lib's existing "a skip is an answer" convention, or state in the header that a 1 from resolve_main forbids both checks. The guard is the stronger choice because build-loop.sh is the consumer that will rely on it.

## What Looks Good

- `resolve_main` returns 1 instead of exiting, as the plan asks, and dev-cycle.sh keeps its exact message and exit (`resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }`, `scripts/dev-cycle.sh:328`). `route: code-fact-check` (FC Claim 2, 12).
- Moving the block into a function made its scratch variables (`c`, `sha`, `cur`, `origin_head`, `candidates`) local. I checked that nothing at dev-cycle.sh top level read them afterwards: at the U0c tip no `$sha`, `$cur`, `$origin_head` or `$candidates` reference remains, and every `$c` hit is inside an awk program. So narrowing their scope changes no consumer.
- The function resets all three outputs on entry (`:280`), so a second call (build-loop.sh resolving after a fetch, say) cannot see a stale `MAIN_BY_NAME=1`. That makes it idempotent in the sense move #9 asks for.
- dev-cycle.sh CLI unchanged: header byte-identical to the base, and `--help` and the usage errors match the base output and exit codes (probe at the U0c tip). `route: code-fact-check`
- The new test exercises the return-not-exit contract through `set -euo pipefail` (`test/scripts/dev-cycle.bats:1048-1057`), the mode a consumer runs in.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Default-branch globals: unset aborts, empty silently misreports | Minor | `scripts/lib/dev-cycle-read.sh:7-12,259-300` | High |

## Overall Assessment

U0b's new name (`resolve_main`) and its status-plus-globals shape match the lib's existing pattern, and dev-cycle.sh's CLI is unchanged. The one consistency gap is in the contract the next consumer will lean on. The lib now owns MAIN/MAIN_SHA/MAIN_BY_NAME but neither initialises them nor guards their emptiness, so the two easy caller mistakes fail in opposite ways. It can be fixed in place with a small guard, and fixing it before U1 means build-loop.sh never depends on the silent mode. Not blocking for a pure-move unit.

## Goal-Alignment Note

The goal is a verbatim move with one deliberate API change (exit → return) so build-loop.sh can handle a missing default branch itself. The change does what the plan asks and keeps dev-cycle.sh identical (56/56 bats at the U0c tip in this pass; FC's digest and check-mode comparisons). Finding 1 is the cost of that change: once the function returns, the lib needs a stated policy for calls made after a failed resolve. It is raised here because this unit created the returning API. Findings stay inside this unit's diff.
