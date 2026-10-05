Commit: a57e5d27

# Architecture Review — feat/build-loop-u0c, iteration 2 (fix a57e5d27)

**Scope:** `git diff feat/build-loop-u0c~1 feat/build-loop-u0c` (plan amendment, lib, dev-cycle.sh directive, bats); `git range-diff 27e38dc4^! feat/build-loop-u0c~1^!` (commit message and header comments)
**Date:** 2026-10-05
**Based on:** iteration-1 report `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0c.md`; rubric `docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0c.md`; plan `docs/working/plan-build-loop-handoff.md` at the U0c tip; override-log rows 202–207.

> ⚠️ **No code fact-check report provided for iteration 2.** Architectural claims in the amendment and the new comments were checked against the code and plan by this reviewer only.

Scope check: in scope. The fix changes the walk's cache contract (now keyed by root), its failure contract (`need_root`), and the plan's module-boundary list. Trust-boundary cross-reference: active. The walk is **B2**'s source, and `check_fix` is **B1**'s gate (`docs/reviews/security-review-2026-10-02-digest-pass38.md`, Commit: `90364c73` — security review predates this diff; boundary may be stale).

## Status of iteration-1 items

| Item | Status |
|---|---|
| Rubric A1 (commit message vs plan :187) | Partly. The plan is amended. The reworded commit messages still describe the decision differently from the amendment (finding 2). |
| Rubric A2 (walk caches an empty set without ROOT_REAL) | **Closed.** `need_root` sits at the top of `imported_names` (lib `:339`), in the caller's shell. |
| Arch Minor 1 (where `check_fix`'s predicate goes) | **Amended in the plan, mostly faithfully** (plan `:187`, `:192`). Three gaps are listed in finding 1. |
| Arch Minor 2 (`isimported`) | Deferred to U2 (override row 203). The amendment commits U2 to it: "adds an `isimported` predicate so neither caller reads the walk's cache format". Faithful. |
| Arch I3 (two read-as-truth lists) | Deferred (row 204). The amendment says "either shares one read-as-truth list with `check_fix` or files the difference as a `you: judgment` entry". Faithful. |
| Arch I4 (walk bound to the working tree) | Deferred (row 205). The precondition is stated in the amendment and in the lib header (`:15-17`), but the amendment's pointer to F11 is wrong (finding 1c). |

## Dependency Map

```
dev-cycle.sh check_fix ──▶ lib imported_names ──need_root──▶ exit 1 if ROOT_REAL unset
                                         └──cache keyed by ROOT_REAL (IMPORTED_DONE = root path)
dev-cycle.sh check_fix ──reads──▶ IMPORTED (unchanged; still the cross-boundary encoding, deferred)
```

The effect on `check_fix` is nil: dev-cycle.sh sets ROOT_REAL once (`scripts/dev-cycle.sh:116`) and never changes it, so the walk runs once per process as before, and `check_fix` reads only `IMPORTED`, never `IMPORTED_DONE`. Keying by root is the extension point the amendment's "run it in a worktree checked out at `MAIN_SHA`" needs, so the fix moves toward the planned design rather than away from it. The cache is single-slot (A→B→A recomputes A). That is cheap and correct.

## Findings

#### 1. The plan amendment states the recommendation faithfully except for three omissions, one of which cites text that does not exist

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:192` (amendment), `:126` (F11 row)
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility target:** for-author

Evidence (tip a57e5d27):

```
The import walk reads the working tree at `ROOT_REAL`, so the gate must run it in a worktree checked out at `MAIN_SHA` or use a commit-reading variant (F11's Q-103 text says so).
```
(plan `:192`, the amendment's fifth sentence)

```
| F11 | Files an instruction file `@`-imports | **partly** | Floor item 1 reuses `check_fix`'s import walk (its known-issues A2/A3 remain). Listed in Q-103 |
```
(plan `:126`, whole row)

The core is stated accurately: `check_fix` stays whole, the reason (allowlist vs denylist, with the differing paths listed), the floor as its own lib function built from `INSTRUCTION_FILE`, the walk and `writable`, `isimported`, the read-as-truth choice, and the tree binding. Three parts of the iteration-1 recommendation are missing or misstated:

- **(a) The leading-dot test.** Iteration 1 asked that the floor's dot-component test "also covers a leading dot", because `check_fix`'s `"$a" == */.*` misses `.envrc`. The amendment lists "top-level dotfiles" only as a difference between the two policies. It does not say the floor must catch them. A U2 author reusing the inline test would inherit the miss.
- **(b) The security note.** Iteration 1 tagged this: putting floor item 1 on B2 gives the `IMPORTED` set a second sink (the gate), so the combined architecture and security pass on U2 should confirm F11's gap rather than inherit it. The amendment omits this.
- **(c) A wrong pointer.** "(F11's Q-103 text says so)" asserts that F11 already records the working-tree binding. The F11 row (`:126`) does not mention the working tree or `MAIN_SHA`, and Q-103 is not re-routed until U5 (step 13). Iteration 1 recommended *adding* this to F11's Q-103 text. The amendment reports it as done.

**Recommendation:** Edit plan `:126` to add "the walk reads the working tree at ROOT_REAL, not MAIN_SHA (U0 amendment)", or change the parenthetical to "add to F11's Q-103 text". Add a half-sentence to `:192`: "its dot test also refuses a leading-dot top-level path; U2's combined architecture/security pass confirms F11's B2 gap now reaches the gate". These are doc edits only.

#### 2. Both move-commit messages call it "deferred extraction" of `check_fix`'s predicate; the amendment says it is never extracted

**Severity:** Minor
**Location:** commit `0f37224e` (U0c move) message lines 6-7; commit `d7ea20b9` (U0a move) message lines 18-20
**Move:** 3
**Confidence:** High
**Legibility target:** for-author

Evidence:

```
check_fix, check_path and check_write stay in dev-cycle.sh; extracting
check_fix's predicate, which the plan lists, is deferred to U2.
```
(`git log -1 --format=%B feat/build-loop-u0c~1`, lines 6-7)

```
dev-cycle.sh. The plan's lib list also names check_fix's predicate; its
extraction is deferred to U2 (plan amendment in U0c's fix commit).
```
(`git log -1 --format=%B d7ea20b9`, lines 19-20)

The amendment (plan `:187`, `:192`) decides that `check_fix`'s predicate *stays* in dev-cycle.sh and that U2 writes a *different* predicate, the floor. "Extraction … deferred to U2" tells a future reader of `git log` that U2 will move `check_fix` into the lib, which is exactly the control-coupled split that iteration 1 and the amendment rejected. Override-log row 202 ("Defer") has the same framing. Commit messages are permanent once merged, and these two are the record a U2 author will find with `git log -S check_fix`.

**Recommendation:** Before merge, reword both to match the amendment: "check_fix's predicate stays in dev-cycle.sh; U2 writes the floor as its own lib predicate (plan amendment 2026-10-05)". Optionally change row 202's decision text to say the plan was amended rather than the move deferred.

#### 3. The cache key is ROOT_REAL, but the walk reads the cwd

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:337-340` (and the walk body to its close)
**Move:** 7
**Confidence:** Medium
**Legibility target:** for-orchestrator-synthesis

Evidence (tip a57e5d27):

```bash
imported_names() {
  local f t d p seen=$'\n' queue=()
  need_root
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'
```
(excerpt ends inside imported_names. I read the rest: it lists files with `git ls-files` relative to the cwd and filters them with `inrepo`, which compares `realpath` with `$ROOT_REAL/$1`.)

The key is correct only under the header's "cds to the repo root and sets ROOT_REAL" contract. If a caller changes one without the other, `inrepo` rejects every instruction file, and the walk caches an empty set under a valid-looking key. For B2 that is fail-open. The behaviour predates this fix and the header states the contract, so this is not a regression. It matters for U2, whose amendment plans to run the walk "in a worktree checked out at MAIN_SHA", which means the gate must `cd` and reset ROOT_REAL together.

**Recommendation:** In U2, either derive the key from `pwd -P` and `need_root`-check that it equals ROOT_REAL, or have the gate's worktree helper set both in one function. No change in U0c.

## What Looks Good

- **One error convention.** `need_root` in the walk reuses U0a's caller-bug exit instead of inventing another, and it runs in the caller's shell (`check_fix` calls `imported_names` directly at `scripts/dev-cycle.sh:174`, not inside `$(…)`), so the guard actually stops the process.
- **A fix that moves toward the plan.** Keying by root turns the iteration-1 "process-cached, first tree wins" limit into the extension point that the amendment's worktree-at-`MAIN_SHA` design needs.
- **The header names each reader's source.** Lib `:15-17` ("check_brief and check_branch read the default branch's commit; check_answer and the import walk read the working tree at ROOT_REAL") makes the tree binding visible at the module boundary, which addresses most of I4 in code.
- **The tests can fail.** I made three mutations in a scratch worktree, and each made "the import walk stops without ROOT_REAL and recomputes for another repo root" fail: (i) restoring the `IMPORTED_DONE=1` flag, (ii) removing `need_root` from the walk, (iii) turning `need_root` into a no-op. The full suite is 59/59 at this tip. T29 now checks that every lib global is declared.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Plan amendment omits the leading-dot requirement and the B2 security note, and cites F11 text that does not exist | Minor | plan `:192`, `:126` | High |
| 2 | Move-commit messages say "extraction deferred to U2"; the amendment says the predicate stays | Minor | commits `0f37224e`, `d7ea20b9` (messages) | High |
| 3 | Cache keyed by ROOT_REAL while the walk reads the cwd; U2's worktree use must keep them together | Informational | lib `:337-340` | Medium |

## Overall Assessment

The fix is structurally sound. The walk's guard and root-keyed cache add no coupling, leave `check_fix` unaffected, and point the module toward the design the amendment describes. The plan and the code now agree on the module boundary, which was iteration 1's most important item. What remains is the fidelity of the written record. The amendment cites F11 text that is not there and drops two U2 obligations, and both move commits frame the decision as a deferred extraction rather than a rejected one. All three items are doc and commit-message edits with no code change, and none of them blocks the move.

## Goal-Alignment Note

The goal is to land U0c after a clean loop. Both rubric Must Address items are addressed: A2 is closed, and A1 is resolved in the plan, though finding 2 shows the commit messages still frame it differently. No Structural or Coupling finding remains. Findings 1 and 2 are Minor (🟢 Consider), but both are cheapest to fix before merge: one plan sentence plus one row, and two commit-message rewords on branches that have not landed yet. If the loop prefers to land now, record them in the override log so U2's author reads the corrected framing.
