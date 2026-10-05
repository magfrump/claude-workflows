Commit: 27e38dc4

# API Consistency Review — feat/build-loop-u0c (U0c: INSTRUCTION_FILE, the @-import walk, ANSWER_AWK/check_answer into the lib)

**Scope:** `git diff feat/build-loop-u0b..feat/build-loop-u0c` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats); consumer = dev-cycle.sh and the planned scripts/build-loop.sh (floor item 1 in D5; `--check-answer` reading main's commit in U1, D8)
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0c.md (Stage 1; its Claim 2 on the ROOT_REAL directive wording, Claim 8 on T29, and Claim 10b on check_fix's predicate staying out of the lib contrary to plan line 187 are not re-filed)

## Baseline Conventions

As in the U0a/U0b reviews. Relevant here:

- The lib's checks print one answer line per argument (`ok …`, `skip X: why`), and dev-cycle.sh's check modes exit 0 when every argument is answered (header line 76).
- Lib-owned state is initialised at source time and cached where noted: `IMPORTED=$'\n'; IMPORTED_DONE=""` (`scripts/lib/dev-cycle-read.sh:316`) joins `SKIPPED=(); SKIP_AT=""` (`:75`).
- U0b's `check_brief`/`check_branch` read the default branch's commit (`$MAIN_SHA`). The file rules (`rawfile`, `plaindir`, `blocker`, `inrepo`, `dirok`) read `$PWD`'s working tree.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `INSTRUCTION_FILE`, `IMPORT_RE`, `ANSWER_AWK`, `IMPORTED`, `IMPORTED_DONE` | moved globals | `FENCE_AWK`, `NAMECHARS`, `SKIPPED` | `scripts/lib/dev-cycle-read.sh:106-124,154,75` | Consistent — UPPER_SNAKE, names unchanged |
| `lower` | moved function | `red`, `green`, `bold` | `scripts/lib/log-format.sh:6-14` | Consistent: short unprefixed lib names have precedent, and there is no collision with dev-cycle.sh's definitions (checked) |
| `imported_names`, `check_answer` | moved functions | `check_brief`, `check_branch`, `extract_skill_name` | `scripts/lib/dev-cycle-read.sh:215,259`, `scripts/lib/skill-paths.sh:21` | Consistent |

## Findings

#### 1. The lib's readers now take their input from two sources, and neither the names nor the header says which

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1-12`, `:316-346`, `:428-447`
**Move:** #7 asymmetry / #3 consumer contract
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (at 27e38dc4):
```
# The dev cycle's reader, shared by scripts/dev-cycle.sh and scripts/build-loop.sh:
# the output scrub, the plain-file and path-form rules, the cycle's own file
# names, the Markdown shapes the readers refuse (FENCE_AWK), the brief, branch
# and answer checks, the instruction-file import walk, and the default branch.
```
```
imported_names() {
  local f t d p seen=$'\n' queue=()
  [[ -n "$IMPORTED_DONE" ]] && return; IMPORTED_DONE=1
```
(excerpt ends :321; imported_names continues to :346, walking `git ls-files -z` / `--others` and reading each file with `grep -oE "$IMPORT_RE" -- "$f"` — read)
```
    r="$(env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f")"
```
(from check_answer, :428-447 — read whole)

After this unit, `check_brief` and `check_branch` read `MAIN_SHA`, while `check_answer` and `imported_names` read the working tree under `$PWD`. `imported_names` also caches its result for the whole process, keyed on nothing. Within dev-cycle.sh that split is the established, documented behaviour, and the move is verbatim. For build-loop.sh it is a hazard. The plan's gate decides on main's commit or the merge result (D6, D7, D8), and the U0c commit says build-loop.sh "will need … the walk and INSTRUCTION_FILE (floor item 1)". A consumer calling `imported_names` from the orchestrator's worktree would get that worktree's imports, computed once. Nothing in the function's name, signature or the header contract says so. U1 already plans to move check_answer to `MAIN_SHA` (FC Claim 11), so the mix is transitional, but the import walk has no planned counterpart.

**Recommendation:** Add one sentence to the header saying which functions read the working tree and which read `MAIN_SHA`, and that `imported_names` computes once per process. Before U2 uses the walk for floor item 1, decide whether it takes a tree or commit argument. That is U2's design call, not U0c's.

## What Looks Good

- dev-cycle.sh's CLI is unchanged at this tip: header lines 1-79 are byte-identical to feat/build-loop-handoff's. `--help`, `--bogus`, `--check-path` with no argument, `--sample=x` and `--since` with no value give the same output and exit code as the base (probes run from a detached worktree of 27e38dc4, since removed). `route: code-fact-check`
- `test/scripts/dev-cycle.bats`: 56/56 ok at this tip (53 pre-existing plus T29, T30 and the resolve_main test), run in this pass. `route: code-fact-check`
- `--check-fix` stays a dev-cycle.sh flag and still finds `INSTRUCTION_FILE`, `IMPORTED` and `imported_names` through the lib. That leaves the CLI's flag set unchanged, as the plan's "dev-cycle.sh keeps its flag" asks for `--check-answer`. Whether check_fix's predicate should have moved is FC Claim 10b's and is not re-filed.
- The `# shellcheck disable=SC2034` on `ROOT_REAL` (`scripts/dev-cycle.sh:114`) arrives in the unit that moved its last in-script reader. The lib's header already names `ROOT_REAL` as a caller-set global, so the contract and the directive agree. `route: code-fact-check` (FC Claim 2 refines the wording).
- T29 now asserts the lib's variables as well as its functions (`for v in FENCE_AWK ANSWER_AWK INSTRUCTION_FILE IMPORT_RE`). That gives the lib's exported surface one test that lists it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Readers mix working-tree and `MAIN_SHA` sources; the import walk caches per process; neither is in the contract | Informational | `scripts/lib/dev-cycle-read.sh:1-12,316-346,428-447` | Medium |

## Overall Assessment

U0c moves its names verbatim and keeps dev-cycle.sh's CLI and output identical, so it is consistent for the existing consumer. The one observation is forward-looking. The lib now exposes two families of readers, one on the working tree and one on main's commit, and the import walk caches its result. The next consumer needs to know both facts, and one header sentence would tell it. Whether the walk needs a tree parameter belongs to U2. Nothing blocks the land.

## Goal-Alignment Note

The unit's goal is to finish the U0 extraction without changing dev-cycle.sh. That holds: the CLI probes match, the bats suite passes 56/56, and FC's digest and check-mode comparisons agree. The goal behind the extraction is a lib build-loop.sh can call directly. Two things stand between this lib and that goal. The first is FC Claim 10b's: check_fix's predicate stays in dev-cycle.sh although plan line 187 lists it, and this review does not re-file it. The second is Finding 1, the unstated read source of the walk this unit hands to floor item 1. Both are best settled before U2 writes the gate, not in this move.
