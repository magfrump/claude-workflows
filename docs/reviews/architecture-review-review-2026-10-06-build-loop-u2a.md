Commit: 36b79f72

# Architecture Review — feat/build-loop-u2a (iteration 2)

**Scope:** full branch diff `git diff main...HEAD` (merge base 900c47d0, HEAD 36b79f72), with whole-function reads of `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh` (main_file, sourcing), `scripts/dev-cycle.sh` (check_fix), `test/scripts/build-loop-check.bats`, plan amendment (plan:192) and the U2 split note (plan:273-277), override-log rows 203-205, 214, 218, 228, 292, 306, 308.
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a.md` (Commit b9ffe7a8, iteration 1; predates the fix commit 36b79f72, so its Claim 11a/5/16/21/22 are read against the fixed code here, not re-verified).
**Trust boundaries:** `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`) — security review predates this diff; boundary may be stale. Its `B2` is the import walk's refusal set.

> ⚠️ Scan note: the newest file matching the skill's `security-review-*.md` glob is pass 38. The U1d reviews are named `security-reviewer-review-*` and do not match the glob; they were not used as the map.

## Dependency Map

- `scripts/build-loop.sh` → lib: `main_entry`, `entry_why` (main_file), `isbrief`/`isclosed` (shared_branches); `floor` from U2c.
- `scripts/dev-cycle.sh` → lib: `isimported tree` (check_fix), `writable`, `INSTRUCTION_FILE`, `pathform`.
- Inside the lib: `floor` (policy, D5 items 1-4) → `isimported main` → `main_imports` → {`main_entry`, `import_targets`, `instruction_names`, `untracked_md`, `plainfile`} → git. `isimported tree` → `imported_names` → the same three shared helpers + `plainfile`. `floor` also → `writable` → `isbrief`/`isclosed`, and `ownfile`.
- Direction is correct: both scripts depend on the lib, the lib depends only on git and coreutils, and no lib function calls back into a script. No cycle. The one upward reference is data: `GATE_CODE` (lib:561) names the caller scripts' paths.

## Findings

#### 1. `isimported` takes a string selector whose default is the working-tree walk, and answers a three-valued result with a boolean

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:541-546`, `:580-582`
**Evidence:**
> `  if [[ "$1" == main ]]; then main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]`
> `  else imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]; fi`
> `    if [[ "$IMPORTED_MAIN" == error ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports"`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

The selector is control coupling with an unchecked value: anything but the exact string `main` (`Main`, `commit`, a typo in U2c) silently runs the working-tree walk, which is the walk the gate must not decide on (plan amendment: the gate decides on main's commit). And because `isimported main` returns 0 both for "imported" and "walk failed", `floor` has to read the `IMPORTED_MAIN` cache sentinel to word its refusal, which is the cache-format read that row 203's `isimported` was added to remove. Row 203 is met for dev-cycle.sh but only moved inside the lib for floor.

**Recommendation:** `case "$1" in tree) ...;; main) ...;; *) return 0;; esac` (unknown selector fails closed), and have `isimported main` return 2 on a failed walk so floor branches on the status instead of the sentinel. Alternatively two predicates (`isimported_tree`, `isimported_main`) with no selector.

#### 2. Two walks: the grammar is shared, but the start-set authority, the BFS and the cache invariants are duplicated and can drift

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:474-491`, `:496-537`; `test/scripts/build-loop-check.bats:99-101`
**Evidence:**
> `    if [[ ! "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]] || ! plainfile "$f"; then continue; fi`
> `    if [[ "$mode" == 100644 || "$mode" == 100755 ]] && [[ "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]]; then seen+="$f"$'\n'; queue+=("m:$f"); fi`
> `    if [[ "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]] && plainfile "$f"; then queue+=("t:$f"); fi`
> `  [[ -n "$IMPORTED_MAIN_DONE" && "$IMPORTED_MAIN_DONE" == "$MAIN_SHA" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }`
**Move:** 2 (responsibility), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author

Two walks rather than one parametrised walk is the right call: the walks differ in start enumeration, follow predicate (`plainfile` vs `main_entry blob`), read source and, above all, failure semantics (best-effort vs fail-closed), and a strategy-parametrised bash walk would force the tree walk to carry the fail-closed machinery or a mode flag. The part that must agree for the two refusal sets to match, the import grammar, is shared (`import_targets`, `instruction_names`, `untracked_md`). What remains duplicated is the start-file rule (spelled three times above) and the queue/seen/lower loop. The concrete cost: the known-issues A2 fix (start from `.claude/rules/**/*.md`, start from a symlinked instruction file) now has to change both walks, and `build-loop-check.bats:99-101` pins the A2 symlink gap as expected floor behaviour (`want docs/b.md -`), so that fix is also a test rewrite. Nothing asserts the two walks agree on a clean checkout at main (the fact-check's `agree.log` was a one-off probe). The cache keys also differ: `imported_names` recomputes per `ROOT_REAL`, `main_imports` keys on `MAIN_SHA` only though its untracked start files come from `ROOT_REAL`.

**Recommendation:** Keep two walks; extract the start-file test into one predicate (e.g. `isinstruction PATH`), add a lib test that a clean checkout at main yields equal `IMPORTED` and `IMPORTED_MAIN`, key `IMPORTED_MAIN_DONE` on `"$MAIN_SHA $ROOT_REAL"`, and mark the :99-101 assertion as the A2 gap (a comment naming known-issues A2) so it is not read as intended contract.

#### 3. check_fix and floor keep the common part of their read-as-truth lists in two spellings

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:180-181`; `scripts/lib/dev-cycle-read.sh:583-585`
**Evidence:**
> `  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \`
> `    || "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then`
> `  elif writable "$lp" || [[ "$lp" == docs/dev-cycle.md ]]; then FLOOR_WHY="one of the dev cycle's own files"`
> `  elif [[ "$lp" == docs/constraints.md ]]; then FLOOR_WHY="the user's constraints doc, which every loop prompt carries"`
> `  elif [[ "$lp" =~ ^docs/(decisions|thoughts|human-author)/ ]]; then FLOOR_WHY="a record later runs read as truth"`
**Move:** 7 (coupling), 2
**Confidence:** High
**Legibility-target:** for-author

The deliberate difference (`docs/thoughts/` fixable in-cycle, refused by the floor) is sound and recorded at plan:273. But the shared part (`decisions/`, `human-author/`, `dev-cycle.md`, `constraints.md`, the dot rule, which now has two spellings `*/.*` and `/"$lp" == */.*`) lives in two modules, so the next user-owned doc needs edits in both; this branch shows the cost, adding `constraints.md` in four places (check_fix code, its comment, its help text, SKILL.md). This is the change-propagation that row 204's "share one list" option targeted. The amendment's "not extracted later" covers check_fix's predicate, not a shared constant.

**Recommendation:** A lib constant for the common denials (e.g. `USER_DOCS='^docs/(constraints|dev-cycle)\.md$|^docs/(decisions|human-author)/'`) used by both, with `thoughts/`, `working/` and `reviews/` staying local to each caller. Record the thoughts/ divergence as a `docs/decisions/log.md` row (it is a decision, currently only in a plan bullet), and fix F10 (plan:125), which still says the floor "keeps the docs `check_fix` denied (`docs/decisions/`, `docs/thoughts/`, ...)".

#### 4. `entry_why`'s catch-all re-creates row 306's misreport for the next word main_entry gains

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:284-290`
**Evidence:**
> `    *) echo "the tree of the default branch could not be read" ;;`
**Move:** 8 (extension points)
**Confidence:** High
**Legibility-target:** for-author

Row 228's single mapping is in place and all three callers (check_brief :353, check_answer :685, build-loop.sh main_file :133) use it. But the default arm words every word it does not know as a read failure. Row 306 was exactly that misreport (a form refusal worded as an unreadable tree); with the default arm doing double duty as `error)`, the next word added to main_entry (U2b's mode rule is the likely one) inherits it silently.

**Recommendation:** Give `error` its own arm and make the default name the word (`"$2: unexpected main_entry answer $1"`), so a new word shows up in output and tests rather than as a plausible message.

#### 5. The lib header's shared-caller contract does not name the floor as a responsibility or its main-branch precondition

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:2-6`, `:21-24`, `:30-34`
**Evidence:**
> `# The dev cycle's reader, used by scripts/dev-cycle.sh and kept apart so`
> `# instruction-file import walk, and the default branch.`
> `# re-reads main); check_brief, check_branch and check_answer skip every`
> `# writes), and so does floor (its import walk also starts from the checkout's`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

The header is the contract both callers code against. Its responsibility list (:2-6) still describes a dev-cycle reader; it does not say the lib now holds build-loop policy (`floor`, `ownfile`, `GATE_CODE`, `FLOOR_WHY`), which is what a reader deciding where U2b/U2c code goes needs. The resolve_main sentence (:21-24) lists the checks that skip without main; floor's behaviour without main (refuse every path the walk arm reaches, tested at build-loop-check.bats:92-95) is a different contract and is not stated. ":33 and so does floor" grammatically attaches floor to check_brief's working-tree refusal as well as to "read the default branch's commit". The A1 fix holds: floor now calls need_root first (:575), matching :15-16.

**Recommendation:** Add the floor to :2-6, add one sentence on floor's output contract (status, `FLOOR_WHY`, caller's shell, refuses without main), and reword :33 to "floor reads main's commit too (its walk also starts from ...)".

#### 6. floor in the shared lib: defensible, with the D5 floor split across two modules

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:559-589`
**Evidence:**
> `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/'`
> `# lower-cased (a case-insensitive checkout reads Docs/Roadmap.md as`
> `# docs/roadmap.md). Floor item 5, symlinks and gitlinks, is the caller's mode`
**Move:** 1, 2, 4
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Placement in the lib is the right boundary today: floor needs `main_imports`, `main_entry`, `writable`, `INSTRUCTION_FILE` and the walk failure state, so in build-loop.sh it would read lib internals across the boundary (finding 1's sentinel), and the lib is itself `GATE_CODE`, so floor changes land only through a merge-gate review either way. Costs: dev-cycle.sh now sources build-loop-only policy, and the lib (702 lines, growing in U2b with brief enumeration, row 298) is drifting from "the dev cycle's reader". D5 is split: items 1-4 here, item 5 (modes) and the brief's own Status rule in U2c's caller. That is a reasonable seam (floor is path policy, modes come from diff-tree), but it means `floor docs/guide.md` returning 1 does not mean "the floor passes".

**Recommendation:** No change for U2a. U2c should test a symlink/gitlink at a path floor passes; if U2b grows the lib further, consider a `scripts/lib/build-loop-floor.sh` sourced only by build-loop.sh (still under `^scripts/lib/`).

#### 7. Plan and known-issues records lag the code; the untracked start set depends on where U2b runs --check

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:126`, `:192`; `scripts/lib/dev-cycle-read.sh:517-519`
**Evidence:**
> `| F11 | Files an instruction file `@`-imports | **partly** | Floor item 1 reuses `check_fix`'s import walk (its known-issues A2/A3 remain). The walk reads the working tree, so the gate runs it in a worktree at `MAIN_SHA` or through a commit-reading variant (amendment 2026-10-05). Listed in Q-103 |`
> `  done < <(untracked_md | instruction_names)`
**Move:** 3 (module boundary; trust boundary cross-reference)
**Confidence:** Medium
**Legibility-target:** for-author

The amendment's conditions are met in code (commit-reading variant, untracked start files from the checkout, tested with `CLAUDE.local.md`), but F11 still offers the worktree option and still says the floor "reuses check_fix's import walk", and known-issues A2/A3 (`docs/working/known-issues-dev-cycle.md:16-17`) still name only `imported_names`. Confirmed rather than inherited: A2 (no `.claude/rules/**` start, symlinked instruction file starts nothing) and A3 (absolute-path imports, imports through symlinks not followed) apply to `main_imports` and so to floor, on `B2` from `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`) — security review predates this diff; boundary may be stale. The floor is now a second consumer of B2. Separately, the untracked start set is "the checkout's" (ROOT_REAL); the amendment also says "The gate's worktree must have no untracked instruction files of its own". If U2b runs --check in a gate worktree, the orchestrator checkout's `CLAUDE.local.md` is not in the start set.

**Recommendation:** Update F11 to name `main_imports` and the start set, extend A2/A3 to name floor, and make U2b's brief state which checkout --check runs from (orchestrator checkout, or pass its root's untracked files explicitly). **Security implication:** none from this recommendation; it records where B2's consumers are.

## Plan-amendment conditions

| Row | Condition | Status at 36b79f72 |
|---|---|---|
| 203 | `isimported` so no caller reads the cache format | Partly: dev-cycle.sh:183 uses `isimported tree`; floor still reads the `IMPORTED_MAIN` sentinel (finding 1) |
| 204 | Share one list or file a `you: judgment` entry | Met by a third route: a reasoned decision in plan:273 (thoughts/ differs on purpose; constraints.md now refused by both). No shared list, no judgment entry, no decisions-log row; F10 stale (finding 3) |
| 205 | Worktree at MAIN_SHA or a commit-reading variant | Met: `main_imports` (lib:496-537). F11 not updated (finding 7) |
| 214 | Unguarded internal helper after need_root | Met: `plainfile` (lib:154), used by both walks |
| 218 | Verb name with `isimported` | Met in effect: no caller outside the lib calls `imported_names`; the name stays |
| 228 | One mapping for main_entry's words | Met: `entry_why`, three callers; floor's walk needs only blob/error. Catch-all caveat (finding 4) |
| 292 | One spelling of the closed/ rule | Met: `isclosed` (lib:161) in check_brief, writable, shared_branches |
| 306 | `badform` word or pathform first | Met: `badform` (lib:269), worded by entry_why |
| 308 | main_entry `error` is a refusal for floor | Met: lib:533 fails the walk, isimported returns 0, floor refuses (test build-loop-check.bats:82-96) |
| plan:192 | Untracked start files in the gate's start set, tested | Met in the lib (test :40-49); depends on U2b's checkout (finding 7) |
| plan:192 | Review confirms A2/A3 rather than inheriting | Confirmed inherited by main_imports (finding 7); A2's symlink case is pinned by test :99-101 (finding 2) |

## What Looks Good

- The import grammar is factored once (`import_targets`, lib:454-464), so the refusal sets of the two walks cannot disagree on what an `@` token is; this is the part that must not drift.
- `main_imports` fails closed as a whole (one `error` state, lib:500, :524, :533) instead of returning a partial list, and the fix commit closes R1's start-set split/duplicate cases at the record level (lib:511-513).
- `entry_why`, `isclosed` and `plainfile` each replace several hand-copied spellings with one definition; three callers now share the refusal words.
- Dependency direction stays one-way (scripts → lib → git), and `floor` composes existing predicates (`writable`, `INSTRUCTION_FILE`) instead of restating them.
- The thoughts/ divergence is a decision with a reason, not an accident, and `constraints.md` now refuses in both callers.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `isimported` selector defaults to the tree walk; boolean conflates imported and walk failure | Minor | `scripts/lib/dev-cycle-read.sh:541-546` | High |
| 2 | Two walks duplicate start-set rule and BFS; no agreement test; A2 gap pinned by test; cache keys differ | Minor | `scripts/lib/dev-cycle-read.sh:474-537` | Medium |
| 3 | check_fix and floor spell the common read-as-truth list twice | Minor | `scripts/dev-cycle.sh:180-181`, `scripts/lib/dev-cycle-read.sh:583-585` | High |
| 4 | `entry_why` default arm words unknown words as a read failure | Minor | `scripts/lib/dev-cycle-read.sh:289` | High |
| 5 | Lib header omits floor's responsibility and contract | Minor | `scripts/lib/dev-cycle-read.sh:2-6`, `:21-34` | High |
| 6 | floor in the lib is defensible; D5 split across lib and U2c | Informational | `scripts/lib/dev-cycle-read.sh:559-589` | Medium |
| 7 | F11 and known-issues A2/A3 lag; untracked start set depends on U2b's checkout | Informational | `docs/working/plan-build-loop-handoff.md:126` | Medium |

## Overall Assessment

The branch maintains the system's structure: dependencies still flow one way, the floor sits where its inputs live, and four of the U2 override triggers (214, 228, 292, 306) are closed by single definitions that remove copies. No Structural or Coupling finding. The two-walk design is the right one given their different failure semantics, and the grammar they must share is shared. The most important structural concern is finding 1: `isimported`'s fail-open default selector and two-valued answer are the interface U2c will build `--check` on, and both are cheap to fix now and harder after a second caller exists. Findings 2-5 are fixable in place; finding 7 is record-keeping that U2b should pick up, including which checkout supplies the untracked start set.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/architecture-review-review-2026-10-06-build-loop-u2a.md (first line `Commit: 36b79f72`), structured per the architecture-review skill with its own severity mapping (Structural/Coupling/Minor/Informational).
- Answered: yes — module boundary, two-walk design, header contract, dependency direction and each named override row assessed.
- Out of scope: whether the A2/A3 gaps are exploitable (security-reviewer); the cost of the per-target `main_entry` fork (performance).
- Escalate: finding 1's fail-open selector and finding 7's U2b checkout question to the U2b/U2c briefs; A2 now applies to the gate (security-reviewer, B2).
- Decisions I made: used pass 38 as the trust-boundary map because it is the newest file the skill's glob matches, not the U1d `security-reviewer-review-*` file; rated finding 1 Minor (intra-lib today, no caller passes a bad selector) rather than Coupling.
