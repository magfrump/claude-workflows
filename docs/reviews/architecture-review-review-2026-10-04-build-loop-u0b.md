Commit: 7cbbe8d2

# Architecture Review — feat/build-loop-u0b (U0b: FENCE_AWK, brief and branch checks, resolve_main into the lib)

**Scope:** `git diff feat/build-loop-u0a..feat/build-loop-u0b` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats), read at tip 7cbbe8d2 with `git show`
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0b.md (Stage 1); plan rev 4 "Approach"; docs/reviews/architecture-review-build-loop-handoff.md

Scope check: in scope. The diff changes module structure (four functions and an awk program move into the shared lib). It also adds a public function, `resolve_main`, with a new contract: it returns instead of exiting and outputs `MAIN`, `MAIN_SHA` and `MAIN_BY_NAME` as globals.

Trust-boundary cross-reference: active. The most recent security review is `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73` — security review predates this diff; boundary may be stale). Finding 1 sits on its **B5**: `[default-branch tree entry at a brief path] → [check_brief() ls-tree mode gate] → [brief Status read / slot decision]`.

Not re-filed (already in the fact-check report): the contract text "runs resolve_main before check_brief or check_branch" being insufficient (Claim 5, with the E5 probe), check_branch's "(the check modes that read it need it found by name)" pointing at dev-cycle.sh (Claim 7), the redundant SC2034 on FENCE_AWK (Claim 6), and "moved verbatim" (Claim 11). Finding 1 below covers the structural side of Claims 5 and 7: where the invariant lives, not how the comment words it.

## Dependency Map

```
dev-cycle.sh ──source──▶ lib: scrub · file rules · pathform · writable/isbrief      (U0a)
                              FENCE_AWK/oddwhy · check_brief · check_branch · resolve_main   (U0b)
dev-cycle.sh ──reads globals──▶ MAIN, MAIN_SHA, MAIN_BY_NAME (written by resolve_main)
dev-cycle.sh ──reads FENCE_AWK──▶ for its own ANSWER_AWK reader (moves in U0c)
lib check_brief/check_branch ──read globals──▶ MAIN, MAIN_SHA ; ──▶ git
```

The lib is no longer only pure predicates. With `check_brief`, `check_branch` and `resolve_main` it now holds stateful git readers. The plan-stage review drew a "channel rule": pure predicates go in the lib, stateful verdicts go through dev-cycle.sh's CLI as a subprocess. Rev 4 deliberately replaced that rule with "`build-loop.sh` resolves `MAIN_SHA` once and calls the lib directly, with no subprocess". So this unit implements the approved design, and the consequence is that more of the correctness contract now crosses the lib boundary as globals. The direction is still right: the scripts depend on the lib, and the lib names no script in code.

## Findings

#### 1. The precondition that makes check_brief/check_branch correct is enforced only by one caller

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:215-250` (check_brief), `:259-271` (check_branch), `:9-12` (contract); `scripts/dev-cycle.sh:328-334`
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** High
**Legibility target:** for-author

Evidence (tip 7cbbe8d2). The lib functions read the globals without checking them:

```bash
  case "$(git ls-tree "$MAIN_SHA" -- "$a" | cut -c1-6)" in
    '') echo "ok $a new"; return ;;
```
(`scripts/lib/dev-cycle-read.sh:224-225`; excerpt ends inside check_brief, which continues to `:250` — read: the remainder reads `$MAIN_SHA` again at `:232` and `:247`, with no guard)

```bash
  elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"
  else
    sha="$(git show-ref --verify --hash "refs/heads/$a" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -n "$sha" ]]; then echo "ok $a $sha $(git rev-list --count "$MAIN_SHA..$sha") $(git log -1 --format=%cs "$sha")"
```
(`scripts/lib/dev-cycle-read.sh:264-268`; check_branch continues to `:271` — read)

The guard that makes them correct is in the caller:

```bash
resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }
...
if [[ ( "$CHECK" == --check-brief || "$CHECK" == --check-branch ) && -z "$MAIN_BY_NAME" ]]; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
```
(`scripts/dev-cycle.sh:328`, `:332-334`)

Before U0b, the guard and the functions sat in one file and one control flow, so the invariant was local. After the move, the lib exports two verdict functions whose answers are only valid under a condition that the lib neither checks nor fully states. The lib computes `MAIN_BY_NAME` and its contract mentions only "runs resolve_main". A second consumer that follows the written contract gets silently wrong verdicts. Stage 1's E5 probe showed this: with `MAIN_SHA` empty, a landed brief reads `ok … new`, and the branch count is taken against HEAD. This sits on B5 from `security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`; predates this diff, so the boundary may be stale): `check_brief`'s ls-tree gate drives the slot decision. `build-loop.sh` will use the same read for `--status`, `--start` ("the brief must be `open` on main") and the gate, so a wrong `new` verdict there feeds dispatch.

**Recommendation:** Move the precondition into the module that owns the verdict. Give `check_brief` and `check_branch` a fail-closed first line, for example `[[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]] || { echo "skip $a: no default branch found by name"; return; }`, or add a single `main_by_name` helper that both call. dev-cycle.sh already exits at `:332-334` before either function runs, so the guard cannot be reached from dev-cycle.sh and its output is unchanged. That makes the guard safe to add in U0b without breaking the pure-move property. At the latest it must land in U1 code, before `build-loop.sh`'s first call, with a lib-level test (source the lib, leave `MAIN_SHA` empty, expect `skip`). **Security implication:** this does not move the B5 crossing. It adds a fail-closed check at B5's existing transition point, so a gate-side consumer inherits it automatically. The security reviewer should confirm that the `skip` wording matches B5's rule.

#### 2. `resolve_main` overwrites a process-wide snapshot; say so in the contract

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:272-299`
**Move:** 7
**Confidence:** Medium
**Legibility target:** for-orchestrator-synthesis

Evidence (tip 7cbbe8d2):

```bash
resolve_main() {
  local c sha cur origin_head candidates=()
  MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""
```
(`:278-280`; the function continues to `:299` and ends `[[ -n "$MAIN_SHA" ]]` — read)

Because the check functions read `MAIN_SHA` as a global, the globals are the "one snapshot of main" that rev 4 relies on. That resolves the plan-stage review's finding 3: there are no two independent resolutions in two processes. It holds only while each process calls `resolve_main` once, before any check. `build-loop.sh --merge` will resolve main, run the rules, and then compare-and-swap against `MAIN_SHA`. A second `resolve_main` partway through, for example from a helper that "makes sure main is resolved", would silently move the snapshot under the gate between the rules and the CAS.

**Recommendation:** Add one clause to the lib header's caller contract: "call resolve_main once per process; it resets and overwrites MAIN, MAIN_SHA and MAIN_BY_NAME, which every check reads". In U3, have `--merge` pass its `--expect`/CAS value from a local copy rather than re-reading the global. This can be done in U1; there is nothing to change in U0b's code.

## What Looks Good

- **Resolution returns; the caller keeps the policy.** `resolve_main` returns 1 and reports which path it took (`MAIN_BY_NAME`), and dev-cycle.sh keeps its own exit and message (`:328`). This is exactly the plan-stage review's finding-2 recommendation: the lib reports facts, and each script chooses its exit policy. Stage 1 verified that the `||`-context errexit change is inert.
- **Locals are scoped.** Five former top-level globals (`c`, `sha`, `cur`, `origin_head`, `candidates`) became locals, so the lib's global namespace is smaller than the code it replaced.
- **One copy of FENCE_AWK.** The lib's `check_brief` and dev-cycle.sh's answer reader still concatenate the same program, which keeps decision log 69's single-reader property.
- **Brief state has a single reader.** `check_brief` moving into the lib (rather than `build-loop.sh` getting a subprocess or its own reader) is the precondition for the plan's `brief_fields` (plan-stage finding 1) living next to it in U1.
- **The test exercises the new contract.** The new test covers the returns-not-exits contract on the current-branch fallback. That is the path a second caller would otherwise misread.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | check_brief/check_branch's correctness precondition (`MAIN_SHA` set, found by name) is enforced only in dev-cycle.sh (B5) | Coupling | `scripts/lib/dev-cycle-read.sh:215-271`; `scripts/dev-cycle.sh:332-334` | High |
| 2 | `resolve_main` overwrites the process-wide main snapshot; the contract should say "once per process" | Informational | `scripts/lib/dev-cycle-read.sh:278-280` | Medium |

## Overall Assessment

U0b keeps the system's structure intact and implements the approved rev 4 design: brief and branch state get one in-process reader, and main gets one snapshot. The single real structural concern is finding 1. Moving the functions split the invariant from the verdicts, so the lib now exports checks that answer wrongly and silently unless the caller repeats a guard that only dev-cycle.sh knows about. dev-cycle.sh is unaffected, so this is not a bug for this unit. It is a boundary defect the second consumer will hit. The fix is a few lines that dev-cycle.sh cannot reach and that fail closed. It belongs in the lib, either now or at the latest before U1's first call. Finding 2 is a one-line contract note.

## Goal-Alignment Note

The goal is a pure move with dev-cycle.sh's behaviour unchanged. Stage 1's executed evidence (digest, six check modes and four edge repos all byte-identical; 56/56 tests) supports that, and nothing here contradicts it. Finding 1 does not block U0b as a pure move. It is the one item from this unit that must be closed before the lib gets a second caller. If the loop prefers to keep U0b strictly verbatim, record it as a U1 must-do (for example as a line in the U1 build brief) so it is not lost between units.
