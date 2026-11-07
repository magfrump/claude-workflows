# Plan: write the first trial set's practices into the dev cycle

**Goal**: as the research doc.
**Project state**: as the research doc.
**Task status**: in-progress (implementing)
Research: docs/working/research-2026-11-06-codify-trial-practices.md

## Approach

Edit `skills/dev-cycle/SKILL.md` at each writer's step (research D2); add `isweekly` to `writable()` and a `skipdir` line (D1); pin both with hermetic tests.

## Steps

1. Lib and digest: `isweekly`, `writable()`, `skipdir docs/working/weekly`, `--check-write` header. About 6 lines.
2. Tests: truthrule word, `--check-write`, section 8, `--cycle-diff` and `--land-cycle` carry a digest, N rule. About 30 lines.
3. Skill: T1 to T7 at their steps. About 35 lines net.
4. A prose pin test for the load-bearing rules. About 15 lines.
5. Log row 85.
6. Review-fix loop, then the brief's Status line.

Implementation order: 1 → 2 → [3, 5] → 4 → 6.
Estimated context cost: research ~90k, implementation ~30k, review ~30k.

## Test specification

| Test case | Expected behavior | Level | Diagnostic expectation |
|---|---|---|---|
| `truthrule` on a dated digest (G1) | word `cycle` | unit | prints each path's word |
| `--check-write` (G2) | ok for a dated digest; skip for an undated name, another case, and a symlinked directory | integration | full output |
| digest section 8 (G3) | lists a symlinked `docs/working/weekly` | integration | full output |
| `--cycle-diff`, `--land-cycle` (G4) | a digest beside the record lands as chore; another case refuses | integration | refusal line |
| `--check` N rule (G5) | a loop's branch writing a digest refuses | integration | `deny` line |
| prose pin (G6) | T1 to T7's rules stay at their steps; the attacker line excludes the author; "never inferred" stays | unit | the missing string |

Failure modes considered:

| Failure mode | Guard |
|---|---|
| A rewrite of step 0.1 drops the self-merge list or the paths line | G6 pins both |
| A digest lands as `other`, reappearing as a commit for the owner | G4 asserts the chore class |
| T3's rule reads "yes" as a batched answer | "never inferred" stays in the sentence; G6 pins it |
| The marker is used loosely | G6 pins "never for anything else" |

`/pre-mortem`: not triggered (no enforcement-file pattern in `hooks/live-verify-gate.sh`, one revert, under 500 lines). `/architecture-review`: not triggered (one small predicate; `scripts/lib` and `skills/dev-cycle` are one gate module).

Risks: the skill's sentences are long and pinned by several tests; run the affected suites after each edit.

## Rollback

`git revert -m 1` of this branch's merge commit on main. It touches no schema, data or service; the release paste (`install.sh`) carries the revert to the image. Digests already written stay as plain `.md` files and still land through `--cycle-diff`'s `.md` rule.
