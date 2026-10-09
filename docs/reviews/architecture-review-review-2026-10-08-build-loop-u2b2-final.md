Commit: 1f4f7a21

# Architecture Review — feat/build-loop-u2b2 (final confirming pass, full branch)

**Scope:** `git diff main...HEAD` on `feat/build-loop-u2b2` at 1f4f7a21: `scripts/build-loop.sh` (`callervar`, `gate_repo`, `checkout_gate`, `check_line`, help text), `scripts/lib/dev-cycle-read.sh` header (contract item 3), `test/scripts/build-loop-check.bats`, plan U2b2/U2c bullets, known issue A5
**Date:** 2026-10-08
**Based on:** final code-fact-check (k=3) non-Verified items as relayed by the orchestrator; override-log rows 459/465, 439, 366/373, 425/431/432/437/477, 530; this critic's iteration-1 and iteration-2 reports

## Dependency Map

- `build-loop.sh` sources `scripts/lib/dev-cycle-read.sh` (one direction: caller to lib). U2b2 adds no new edge in either direction. `check_line` calls `import_reset` (a lib function), and `checkout_gate` calls only git, `tr`, `awk` and `ls`.
- Inside `build-loop.sh` the order is: `harden` and the exported git environment (process-wide), then `gate_repo` (once per run, uses `callervar`), then per brief `out="$(check_line "$a")"`. `check_line` runs `status_line`, `check_branch`, `merge_result`, the `diff-tree` read, then `checkout_gate` (self-merge only), then the missing-blob check, `nrules` per path, and the verdict.
- `checkout_gate` reads the globals `MAIN_SHA` and `GATE_TMP` and writes `CHECKOUT_WHY`. It has the same shape as `nrules`, which writes `DENY`. `callervar` is shared by `gate_repo` (which variables to keep) and `checkout_gate` (which variables to tolerate).
- The contract stays in the lib header (items 1-8). Item 3's note now gives each duty an owner: harden and the state gate, `checkout_gate`, the walk, and U2c for item 1. The plan's U2c bullet carries the two forward obligations: floor runs only when `co` is empty, and the walk runs under `LC_ALL=C`.

Security cross-reference: `ls docs/reviews/security-review-*.md` matches only two unrelated egress reviews (2026-08-29, 2026-09-19). This branch's security reports are named `security-reviewer-review-*`. This pass produces no module-boundary (move 3) findings, so the cross-reference is a no-op.

## Findings

#### 1. `check_line` runs inside `$(...)`, so the floor walk U2b2 places "per path below" will run where the lib says its exiting checks must not

**Severity:** Informational
**Location:** `scripts/build-loop.sh:774` (`out="$(check_line "$a")"`), `:732-738` (the placement comment); lib `dev-cycle-read.sh:24-25`, `:66` (item 5)
**Move:** 1 (dependency direction / control flow), 7 (coupling)
**Confidence:** Medium

The lib header says: "Call the exiting checks in the caller's shell, not inside $(...) or `local x="$(...)"`, where an exit ends only the subshell". Contract item 5 says "Ask floor about each changed path, in this shell". `floor` calls `need_root`, which `exit 1`s. U2b2's comment fixes floor's future location: "before U2c's floor walk, which runs per path below and only when co is empty". "Below" is inside `check_line`, and `--check` calls `check_line` as `out="$(check_line "$a")"`. Today this fails closed. Under `set -euo pipefail` (line 172), a subshell exit makes the assignment fail and ends `--check` with exit 1, and it prints nothing for that brief or any later one. That is a different shape from the documented `refuse` line per brief. The same subshell boundary is why the green `import_reset` mutant is green: every decision already starts with fresh walk caches. Item 4 holds twice over, and nothing observes the explicit call.

This is not a defect in U2b2, which adds no floor call. It is a gap in the handoff. U2b2 is the unit that chose where the walk goes, but U2c's bullet names only the `co` and locale obligations.

**Recommendation:** Add one clause to the plan's U2c bullet: floor runs in `check_line`'s subshell, so either accept that a `need_root` exit aborts the whole `--check` (and test it), or call floor's `need_root` precondition once in the parent shell before the loop. Keep `import_reset` at the top of `check_line`, since it is the right anchor if U3's `--merge` ever calls `check_line` in the parent shell. Let U2c's first walk test make it observable.

#### 2. The cost note bounds per-brief `checkout_gate` runs by "the slot count", which is a caller property that neither `--check` nor plan D9 provides

**Severity:** Informational
**Location:** `scripts/build-loop.sh:737-738`; plan `docs/working/plan-build-loop-handoff.md:90` (D9)
**Move:** 7 (coupling surface: a cross-unit assumption stated in the callee)
**Confidence:** Medium

Evidence: "Run per brief, so each decision sees the checkout as it is: about 0.25 s here, times the self-merge briefs in one --check (at most the slot count)." `--check` takes any number of BRIEF arguments (fact-check: not enforced). D9 says "Only a live dispatched loop holds a slot. A `blocked`, `ready`-awaiting-review or `stopped` item holds none". Briefs that are ready to merge, which are the ones `--check` gates, are therefore not bounded by slots in the plan's own terms. The accepted performance row does not depend on the bound, because its revisit trigger is "a repo where --check passes 10 s". The harm is limited to a comment that states, as a guarantee, a property owned by an unbuilt caller (U3's collect step).

**Recommendation:** Change the wording to "times the self-merge briefs passed to one --check", or name U3's collect step as the owner of any bound. No code change.

## What Looks Good

- **The precondition runs at the decision's granularity and before its consumer.** `checkout_gate` runs per self-merge brief inside `check_line`, after the merge's paths are read and before the N rules and the future floor. Item 2's "final before the walk" now has a single place where it holds. The remaining gap between the check and the walk's read is recorded honestly in A5 as "a checkout file swapped between the gate's check and the walk's read".
- **The refusal composes with the existing verdict shape.** `co` replaces only the verdict line (`echo "${co:-ok ...}"` and the final if-chain), so path and deny lines still print for a loop's advisory run from its branch. The test at bats `:295-308` pins this. The merge's own refusals keep precedence, as the help states.
- **Item 3 is checked by its effect, not by predicting it.** Hashing every regular file main stores with `--no-filters` against main's blob covers filters, encodings, ident and eol from any attributes source, including the global ones `harden` hides. The config refusals are a diagnostic layer over effect checks, not the only line of defense. Executed probe: a symlink checked out as a file through a non-local `core.symlinks=false` (`git -c core.symlinks=false checkout`) leaves the hardened `git config --get core.symlinks` empty, and the hardened `git status` reports ` T link.md`, so the status rule still refuses it. The reason names `git status` rather than `core.symlinks`, which is acceptable for a fail-closed fallback.
- **`checkout_gate` follows the established `nrules`/`DENY` shape** (return code plus a WHY global computed where it is read). The iteration-1 sentinel problem is gone.
- **One `callervar` predicate** replaces the two diverged copies. Its dual role is recorded and deferred (row 530).
- **Ownership is now stated once, in the lib header.** Item 3's note splits item 2 among harden and the state gate, `checkout_gate` and the walk, and names U2c as item 1's owner. The U2c bullet repeats only the two obligations that U2c inherits.
- **No new cross-module edge.** The lib gains no knowledge of `build-loop.sh`'s internals in code, only in the contract's ownership prose. Its placement is already deferred (row 530).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Floor will run inside `check_line`'s `$(...)`, against the lib's "exiting checks in the caller's shell" and item 5's "in this shell"; a `need_root` exit aborts the whole `--check` (fail-closed, unlisted); the subshell is also why `import_reset` is unobservable; U2c's bullet does not say so | Informational | `build-loop.sh:774`, `:732-738`; lib `:24-25`, `:66` | Medium |
| 2 | "At most the slot count" cost bound is a caller property neither `--check` nor D9 provides | Informational | `build-loop.sh:737-738`; plan `:90` | Medium |

## Overall Assessment

The full branch maintains the system's structural integrity. U2b2 adds one focused function (`checkout_gate`) and a one-line predicate (`callervar`), places the checkout precondition at the right granularity and position in `check_line`, and leaves the verdict and path-line shapes intact. It adds no dependency edge. Every iteration-1 and iteration-2 architecture finding is either resolved in place or deferred with a trigger (row 530). This pass found no Structural or Coupling issue. Both new findings are Informational and concern how U2b2 hands off to later units: (1) the floor walk U2b2 places inside `check_line` will run in a command substitution, which the lib's own calling rules warn against, and (2) the cost comment assumes a bound that only the future loop could provide. The most useful of the two is finding 1, a one-clause addition to the U2c bullet. Neither blocks landing.

## Goal-Alignment Note

**User goal:** land build-loop handoff unit U2b2 through its review-fix loop.
**Alignment:** The branch serves the goal. It delivers contract items 2-4 for self-merge briefs as the unit's statement promises ("so U2c's floor walk can rely on it"), within scope and with no new cross-module coupling. This final pass has no Structural or Coupling finding, so nothing here blocks the merge. The two Informational findings are handoff notes for U2c and U3. Finding 1 can be recorded in the U2c bullet or as an override row with trigger U2c. Finding 2 is a wording change, or an Accept that points at the existing performance row.
