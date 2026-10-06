Commit: 83cdb005

# Architecture Review — feat/build-loop-u1d

**Scope:** `git diff main...feat/build-loop-u1d` at 83cdb005. Structural focus: `scripts/lib/dev-cycle-read.sh:247-302` (`main_by_name`, `main_entry`, `brief_fields`), the lib header (`:1-33`), and every `main_entry` caller (`check_brief` `:323-345`, `check_answer` `:549-560`, `main_file` in `scripts/build-loop.sh:120-130`).
**Date:** 2026-10-06
**Based on:** the merged Stage-1 fact-check (`docs/reviews/code-fact-check-report-build-loop-u1d.md`, Claims 11, 12 and 21), override rows 228, 233, 238, 284, 292 and 298, and plan D5 (`docs/working/plan-build-loop-handoff.md:66-76`).

Scope check: in scope, under trigger category 2 (public APIs). `main_entry` is a lib function with three callers in two scripts. The diff moves its path-form precondition from the callers into the function, which changes its contract. Everything else in the diff (wording, help text, tests, one skip-reason string) is implementation-only, and I did not review it structurally.

Trust-boundary cross-reference: active. Sorted by name, the most recent `docs/reviews/security-review-*.md` is `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`). Its `B5` reads "[default-branch tree entry at a brief path] → [check_brief() ls-tree mode gate] → [brief Status read / slot decision]", and `main_entry` is that ls-tree gate. F1 sits on `B5`. That security review predates this diff, so the boundary may be stale. The diff moves no crossing. It tightens the gate in place, and no recommendation below moves it either.

## Dependency Map

- The dependency direction is unchanged: `scripts/dev-cycle.sh` and `scripts/build-loop.sh` source `scripts/lib/dev-cycle-read.sh`, and the lib depends on neither script. Inside the lib, `main_entry` now calls `pathform` (`:141`), which is a pure string predicate. It is defined in the same file, has no globals, and does not depend on the locale. No new module edge is added.
- The `main_entry` callers at 83cdb005:
  - `brief_fields` (`:296`) runs `pathform` and then `main_entry`.
  - `check_brief` (`:327`, `:334`) runs `main_by_name`, then `pathform`, `isbrief`, `blocker` (a working-tree read), and then `main_entry`.
  - `check_answer` (`:554`) passes two fixed names.
  - `main_file` (`build-loop.sh:124`) passes fixed names.
  - `dev-cycle.sh` has no direct call.
- The next caller downstream is U2's floor function. According to the goal preamble, it will call `main_entry` on a branch's changed paths, which are arbitrary repo names rather than fixed or pre-checked ones. Override row 228 asks it to share one mapping from `main_entry`'s result words to reasons.

## Findings

#### F1. `error` now has two meanings, path-form refusal and an unreadable tree, and every caller's `error` arm names only the second

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:250-263`; caller arms `:339`, `:559`, `scripts/build-loop.sh:129`
**Move:** 3 (module boundary: what the result vocabulary tells a caller), 7 (control coupling: callers must know the cause to word the reason)
**Confidence:** High on the behaviour (probe), Medium on the severity
**Legibility-target:** for-author (U2's floor and the row-228 shared mapping)

**Evidence:**
```
   250	# "absent", "notfile" (the path is some other kind of entry), "notdir PART"
   251	# (PART, a directory above the path, is stored as something else) or "error"
   252	# (no default branch found by name, ls-tree failed, or the tree lists a name
   253	# twice; git's own reads would take the first copy, which may not be the one a
   254	# check saw, so this answers error instead; never read as absent). One ls-tree
   ...
   257	# paths from the top level, whatever the current directory). It checks
   258	# main_by_name and the path's form itself (pathform, so ls-tree prints it
   259	# unquoted): either failing is error.
   260	main_entry() {
   261	  local p="" rest="$1" out mode path dup="" want=()
   262	  local -A m=()
   263	  if ! main_by_name || ! pathform "$1"; then echo error; return; fi
   (excerpt ends :263; enclosing main_entry() continues to :276 — read: ls-tree, duplicate check, then absent/notdir/blob/notfile)
```
What callers do with `error`:
```
scripts/lib/dev-cycle-read.sh:339:    error) echo "skip $a: the tree of the default branch could not be read"; return ;;
scripts/lib/dev-cycle-read.sh:559:      error) echo "skip $a: the tree of the default branch could not be read, so $f is not read"; return ;;
scripts/build-loop.sh:129:    error) FILE_WHY="the default branch's tree could not be read for $f"; return 1 ;;
```
A probe (`.../scratchpad/review-u1d/arch/probe.sh`, log `probe.log`) ran on a scratch repo with `main`, comparing main's lib with 83cdb005's:
```
== old-lib.sh                       == 83cdb005 lib
.github/x.yml -> blob               .github/x.yml -> error
docs/My Notes.md -> blob            docs/My Notes.md -> error
.gitattributes -> blob              .gitattributes -> error
docs/nope.md -> absent              docs/nope.md -> absent
```

Moving the guard inward is right, and it closes row 284: a quoted path can no longer read as `absent`. The guard reuses the existing `error` word, though, so the vocabulary no longer tells a caller *why* the read failed. Today this is harmless, because every caller either checks `pathform` first or passes fixed names that pass it (FC Claim 12), so the new arm never fires for them. That makes the callers' own `pathform` checks load-bearing for **accurate reasons**, not just for safety. The defence-in-depth framing is therefore only half right. U2's floor is the first caller that will pass unvetted names. Ordinary repo files with a space, a `.github/` part or a `.git*` name (all of them blob on main before this diff, per the probe) will come back `error`. Under the row-228 shared mapping, they would be reported as "the tree of the default branch could not be read", which points the reader at repo corruption. It fails closed, so no path slips the floor: D5 item 2 already refuses every `.`-prefixed component, and a `Paths:` entry must pass the form rules. The cost is a misleading refusal reason plus an ordering rule (check `pathform` first) that is written down nowhere.

**Recommendation:** Do not change U1d. Record one of these for U2, at the point where row 228's shared mapping is built:
- (a) `main_entry` answers a distinct word for a form refusal (for example `badform`), and the shared mapping gives it its own reason; or
- (b) state in `main_entry`'s comment that a caller wanting a specific reason runs `pathform` first, and that `error` from an unchecked name may mean either cause.

(a) is cleaner, because it removes the ordering rule. It touches three case blocks that row 228 already plans to merge.

#### F2. The callers' pre-checks: `brief_fields`' is now strictly redundant, `check_brief`'s is not

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:296`, `:327-334`
**Move:** 2 (responsibility: who owns the precondition)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis (answers the focus question on duplication versus defence in depth)

**Evidence:**
```
   296	  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
```
```
   327	  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
   ...
   332	  if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi
   ...
   334	  e="$(main_entry "$a")"
   (excerpt ends :334; enclosing check_brief() continues past :345 — read: the case arms and brief_fields)
```
In `brief_fields`, both branches of the `||` set `BRIEF_ODD=error` and return 1, so its own `pathform` call changes no outcome now. At most it saves one subshell, and its comment (`:286-288`) lists "a path pathform refuses" beside "any main_entry answer but blob", which is still accurate. In `check_brief` the pre-check does real work for two reasons. It gives the specific reason ("not an allowed path form"). It also runs before `blocker`, which reads the working tree at that path, and `main_entry`'s guard cannot protect that read. So these are not duplicates of the moved precondition. This is the arrangement F1 relies on: the boundary owns safety, and callers own wording and the order of their other reads.

**Recommendation:** Keep both. `brief_fields`' copy is cheap defence in depth, and removing it would be churn. If F1 option (a) lands in U2, `brief_fields` can then be left as it is or simplified with no change in behaviour.

#### F3. The lib header's caller contract is consistent after the change, but it still lists only three functions as needing `resolve_main`

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:13-14`, `:22-24`, `:30`
**Move:** 3 (the module's stated public contract)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    13	# caller sets -euo pipefail (check_answer and brief_fields also set pipefail
    14	# for themselves),
   ...
    22	# and SKIP_AT. The caller runs resolve_main once per process (a second call
    23	# re-reads main); check_brief, check_branch and check_answer skip every
    24	# argument unless it returned 0 with main found by name. check_brief,
   ...
    30	# Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields
```
The diff leaves no stale "the caller checks pathform" text in the header or in any non-review doc (`rg main_entry` outside `docs/reviews/`). The pipefail note is complete (FC Claim 11). The header names no `main_entry` precondition at all, and now none is needed, because the function owns both of its checks. One gap remains, and it predates this diff: `:23-24` names three functions that refuse without `resolve_main`, while `main_entry` (answers `error`) and `brief_fields` (returns 1) behave the same way. Their own comments state this (`:252`, `:287`).

**Recommendation:** None for U1d. If U2 edits the header to add the floor function, list all five readers in that `resolve_main` sentence.

## Deferred rows

- **Row 284** ("main_entry does not run pathform itself; a path ls-tree quotes reads absent"): **resolved.** The guard is at `:263`, and the U1d test at `test/scripts/dev-cycle.bats:1328-1335` fails with the guard removed for 3 of its 4 paths (FC Claim 21). "Before any read" in that title is not asserted (FC Claim 21). Ordering does not matter architecturally, because ls-tree is the only read and an early `error` wins either way.
- **Row 233** (untested bypass candidates; rationale "./x fails pathform before any read"): the rationale now holds inside `main_entry` itself rather than depending on each caller, so it is **strengthened**. The trigger (U2's T12/T26) is unchanged.
- **Row 228** (one shared mapping for `main_entry`'s result words, trigger U2's floor): **affected.** The mapping must now tell form refusal apart from an unreadable tree. See F1.
- **Row 238** (globform copies pathform's rule; trigger U2): not affected by the diff. Note for U2: never globs allow `.git*` parts that `pathform`, and so `main_entry`, refuse. A floor that resolves a never-glob-matched path through `main_entry` gets `error` (F1).
- **Rows 292 and 298** (the closed/ rule spelled three ways; F31's second read path; trigger U2): not affected. `shared_branches` still reaches main through `brief_fields`, which is guarded twice now.

## What Looks Good

- **The precondition sits at the boundary that needs it.** `main_entry` is the `B5` gate. Before this diff, its safety (an unquoted ls-tree path, and so no false `absent`) depended on every caller remembering `pathform`. Now the gate enforces its own input rule, which is the right place before U2 adds a caller that passes arbitrary names. Because `pathform` excludes `:`, `*` and `?`, the guard also keeps pathspec magic from reaching ls-tree whatever the caller's environment. Both scripts export `GIT_LITERAL_PATHSPECS=1` (`dev-cycle.sh:126`, `build-loop.sh:113`), but a direct sourcer of the lib, such as the bats tests or a future script, need not.
- **No new dependency or global.** The guard is a same-file, locale-independent pure predicate called in the function's own shell. No dependency, global or ordering rule is added.
- **The comment is updated with the code.** `:257-259` now states the contract the function enforces, which retires the stale "the caller has checked" text (A22).
- **The test hits the lib directly.** The U1d test sources the lib and calls `main_entry` with no script in between, so it pins the lib's own contract rather than one caller's behaviour.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `error` now has two meanings, form refusal and an unreadable tree, and every caller's `error` arm names only the second. Callers' `pathform` pre-checks are load-bearing for accurate reasons, and U2's floor and row 228's mapping must handle this | Minor | `scripts/lib/dev-cycle-read.sh:250-263`, `:339`, `:559`; `scripts/build-loop.sh:129` | High (behaviour) / Medium (severity) |
| F2 | `brief_fields`' pre-check is now redundant. `check_brief`'s is not: it gives the specific reason and guards a working-tree read | Informational | `scripts/lib/dev-cycle-read.sh:296`, `:327-334` | High |
| F3 | Header contract is consistent after the change; the `resolve_main` sentence still omits `main_entry` and `brief_fields` (pre-existing) | Informational | `scripts/lib/dev-cycle-read.sh:22-24` | High |

## Overall Assessment

U1d improves the structure. `main_entry`, the `B5` gate, now owns both of its preconditions. Row 284 is closed, the comment matches the code, and no dependency or global is added. On the duplication question, the callers' remaining `pathform` checks are mostly not duplication. `check_brief`'s gives a specific reason and protects a working-tree read the gate cannot. `brief_fields`' is harmless redundancy. The one structural concern is forward-looking (F1). The guard reuses the `error` word, so form refusal and an unreadable tree look the same to callers. Every current caller's reason text assumes the second. This becomes visible when U2's floor passes unvetted changed paths, and it fails closed with a misleading reason rather than failing open. It can be fixed in place in U2 together with row 228's shared mapping, and U1d needs no change.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/architecture-review-review-2026-10-06-build-loop-u1d.md (first line `Commit: 83cdb005`), structured per the architecture-review skill.
- Answered: yes. The boundary is right (What Looks Good). Duplication versus defence in depth: `check_brief`'s pre-check is load-bearing, `brief_fields`' is redundant but harmless (F2). The header contract is consistent (F3). Row 284 is resolved, row 233 is strengthened, and row 228 is affected (F1). Rows 238, 292 and 298 are not affected.
- Out of scope: wording and test-strength claims (fact-check owns these: Claims 1, 3, 17, 18, 21); r3's broken-config ahead-count escalation (security-reviewer).
- Escalate: F1 should become a U2 precondition beside row 228 (a distinct form-refusal word, or a documented pre-check rule) if the orchestrator records Minor findings as deferrals. Nothing blocks U1d.
- Decisions I made: I rated F1 Minor rather than Coupling, because it fails closed, no current caller can trigger it, and the cost is the wording of a reason. I treated the preamble's statement that U2's floor calls `main_entry` on changed paths as given. The plan text I read (`D5`, the `:192` amendment) does not spell this out.
