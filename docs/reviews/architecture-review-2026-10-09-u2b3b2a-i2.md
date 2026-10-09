Commit: f7a96eed

# Architecture Review — feat/build-loop-u2b3b2a (U2b3b2a, outside chains), iteration 2

**Scope:** fix range `55490d15..HEAD` (18fba03d, f7a96eed; 261ecd96 is review context): `scripts/lib/dev-cycle-read.sh` (IMPORT_WHOLE init, import_outside/import_file renames and signatures, outside_ok, comments), `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2a-i2/shared.md`; Stage-1 fact-check `docs/reviews/code-fact-check-report-build-loop-u2b3b2a-i2.md` (summary: 27 Verified, 2 Mostly accurate, 1 Incorrect); iteration 1 report `docs/reviews/architecture-review-2026-10-09-u2b3b2a.md`

Trigger categories: module structure no; public APIs **yes** (two lib functions renamed, import_outside gains DIRS, new outside_ok, a new source-time global); data models no change since i1; cross-cutting **yes** (the admission rule shared by both walks). In scope.

## Dependency Map

Unchanged in direction from iteration 1: walks (imported_names, main_imports) → import_file → import_outside → import_targets → import_readers / IMPORT_AWK, plus walks → outside_ok (new leaf predicate) and walks → import_work. import_outside now also depends on nul_list (for `realpath -ez`). No cycle; the new predicate sits beside the repo admissions (inrepo_here, main_checkout) at the walk layer. outside_ok sits on the security review's `B1` transition (`[-f && -r test, realpath -e, capped_read]`) from `docs/reviews/security-review-2026-10-09-u2b3b2a.md` (Commit: `55490d15`) — security review predates this diff; boundary may be stale. Naming it moves no crossing: the same test runs at the same two points.

## Iteration-1 findings: status

| i1 | Status | Evidence |
|---|---|---|
| A1 ambient IMPORT_WHOLE | Resolved (the one-line option) | `IMPORT_WHOLE=""` at source time (:1032), pinned by `IMPORT_WHOLE=1 imps "$w" docs/x.md; want walk ok; want docs/x.md imported` (build-loop-check.bats:656) and the sourcing inventory (dev-cycle.bats:1114). Fact-check: an inherited value is empty after sourcing; the mutant fails a test. Residual: N3. |
| A2 DIRS dropped for an absolute FILE | Resolved | `import_file() { if [[ "$1" == /* ]]; then import_outside "$1" "${@:3}"; ...` and `import_targets "${d:-/}" "${@:2}"`; the new test checks both `docs/n.md` (from the DIRS `""`) and `//$o/docs/n.md`. |
| A3 inline admission policy | Resolved | `outside_ok() { [[ -f "$1" && -r "$1" ]]; }` (:1152), called at :1272 and :1380; fact-check: the arms keep 55490d15's order. |
| A4 budget per sub-call unstated | Resolved in import_outside; see N1 for import_file | `each call may spend all that a walk has left, so the walk's own import_work check is what bounds the pair` |
| A5 two namespaces in the lists | Resolved | walk header: `The walks' lists (IMPORTED, IMPORTED_MAIN) also hold the second channel's lower-cased // names, which no repo path isimported asks for can match.` |
| A6 dotnest pointers, phase-2 header | Mostly resolved | truthrule `import_readers' dotnest pairs omit only such paths`, put `(dotnest, from import_readers)`, phase-2 sentence names outside files. The failure-list half is not done: N4. |

## Shape check for U2b3b2b

- **Outside seeds as absolute items.** A seed pushed onto `queue` (tree walk) or `tq` (main walk) as an absolute path reaches `import_file` through the `checkout` arm (`${ent[$f]-checkout}` cannot match an absolute key), is read by import_outside, and its imports re-enter through the normal admission. The seeding sites can call `outside_ok` for the same skip rule the import arms use. No walk change needed beyond the seeding loop.
- **Prompt seeds with DIRS.** Probed: for `p=/home/node/.claude/commands/x.md`, `prompt_dir` sets `pdir[$p]` and `prompt_bases` yields `[]` and `[/home/node]`; the walks pass these as `"${xs[@]}"`, import_file now forwards them, and import_targets joins `""` under every reader root (a session at a repo's top level) and `/home/node` as absolute. That is the superset a user command needs. The seeding code must call prompt_dir with the lower-cased path (contract item 8), as the repo seeds do.

## Findings

#### N1. import_file has a branch-dependent precondition its header does not state

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1144-1148` (import_file), `:1131-1141` (import_outside)
**Move:** 3 (module boundary), 6 (substitutability of the two branches)
**Confidence:** High (fact-check Claim 24, executed: unset_rc=1)
**Evidence:** import_file's header: `# import_file FILE DIR [DIRS...]: import_targets over FILE as the file system holds it, for both walks: a repo path (DIR and DIRS as import_targets takes them), or an absolute one through import_outside (its own directory in place of DIR, and DIRS).` import_outside: `For a walk, which sets IMPORT_WORK_LEFT: the two trailers are summed into one` and `a="$(capped_read < "$1" | import_targets "${d:-/}" "${@:2}")" && import_work a w || return 1` (import_work: `It returns 1 when the trailer is missing`).

The relative branch works with IMPORT_WORK_LEFT unset (no trailer printed, none required); the absolute branch returns 1 in the same environment, because import_outside unconditionally consumes a trailer. So import_file's two branches do not accept the same preconditions, and only the callee's header says so. Commit 18fba03d claims "both headers say a walk sets IMPORT_WORK_LEFT", which the fact-check found Incorrect. Today the only callers are the two walks, which always set it, so nothing breaks; the risk is U2b3b2b or a test calling import_file directly on an outside seed (e.g. a one-off read before queueing) and getting a bare 1 that reads as a read failure. It fails closed, so this is a legibility gap, not a defect.

**Recommendation:** Add one clause to import_file's header: "an absolute FILE needs IMPORT_WORK_LEFT set (a walk's call), and its output ends in the work trailer". Optionally make import_outside skip the summing when IMPORT_WORK_LEFT is unset, so both branches have the same contract.
**Legibility-target:** U2b3b2b's author learns from import_file's header alone what its absolute branch needs.

#### N2. import_file takes a DIR that its absolute branch ignores

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1148`, `:1263`, `:1339`
**Move:** 5 (interface segregation)
**Confidence:** High
**Evidence:** `import_file() { if [[ "$1" == /* ]]; then import_outside "$1" "${@:3}"; ...` while both walks compute `if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi` and pass `"$d"`; import_outside recomputes `local d="${1%/*}"`.

For an absolute FILE the walks' `d` equals import_outside's own `d` except for a file directly under `/` (walk: `""`, import_outside: `/`), and the header says the slot is replaced (`its own directory in place of DIR`). So the slot is documented and harmless; it is a positional that one branch drops, which the new test exercises by passing `ignored`. Worth knowing only if U2b3b2b's seeds pass something other than `${f%/*}` there expecting it to take effect.

**Recommendation:** None required; the header already says it. If the signature is touched again, the absolute branch could use `$2` when given, removing the duplicate derivation.
**Legibility-target:** a caller sees from the signature which arguments each branch honours.

#### N3. IMPORT_WHOLE is still a global mode, now safe against inheritance only

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1030-1032`, `:1102`, `:1121`, `:1141`
**Move:** 7 (control coupling through a global)
**Confidence:** High
**Evidence:** `# Set only for one import_targets call (import_outside's projection); cleared here, so an inherited one cannot make every walk read its text as whole names (U2b3b2a i1 architecture A1).` / `IMPORT_WHOLE=""`; the one setter is `IMPORT_WHOLE=1 import_targets /`.

The fix took i1 A1's one-line option, which closes the reported path (an exported value from a caller's environment). A caller that sources the lib and then assigns IMPORT_WHOLE (not as a per-command prefix) would still flip every later walk into whole mode, a false negative. Only one in-tree setter exists and it is per-call (bash scopes the prefix to the function call), so this is a convention, now stated in the comment, rather than an enforced boundary.

**Recommendation:** None for this unit. If U2b3b2b needs whole-mode projection elsewhere, route it through import_outside or a wrapper rather than a second assignment site.
**Legibility-target:** the comment's "set only for one import_targets call" stays true as a rule a reader can check by grep.

#### N4. main_imports' failure list does not name an outside file

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1285`
**Move:** 2
**Confidence:** High
**Evidence:** `# import main lacks, a blob or checkout file cannot be read, symlink text it` while import_outside's header says `It returns 1 on a failed read or a real path holding a newline ... so a file that changed after the walk admitted it fails the walk rather than being skipped.`

The second half of i1 A6 (add "an outside file" to the read-failure clause) was not taken; the phase-2 sentence was. The walk does fail on an outside read failure or a newline real path (the new test pins both walks failing), so the list under-states the refusals. The tree walk's header defers to its general statement, so only the main walk's enumerated list is short.

**Recommendation:** Extend the clause to "a blob, checkout or outside file cannot be read (or an outside file's real path holds a newline)".
**Legibility-target:** the main walk's failure list stays complete as U2b3b2b adds outside seeds to tq.

## What Looks Good

- **A2 fixed at the seam, not at the callers.** DIRS flow through import_file to import_outside to import_targets, so U2b3b2b's prompt seeds need no special handling; the parser's existing absolute-directory join does the work.
- **One admission rule.** outside_ok names the reader-model decision once, beside the repo admissions; the two walks keep their prior evaluation order (verified by the fact-check), and U2b3b2b's seeds have a named rule to reuse.
- **Fail-closed preserved on the new read.** The `realpath -ez` + one-record + no-newline check makes the projection's one-name-per-line assumption an explicit refusal, not a silent split; the test pins it in both walks.
- **Renames match the lib's `import_*` family** (import_targets, import_work, import_readers) and the sourcing inventory now lists the new functions and globals, so a dropped definition fails a test.
- **Budget ownership is stated** in import_outside's header, closing i1 A4 at the component that has the two sub-calls.
- Size stays well inside the cap (commit reports 213 code lines against main).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| N1 | import_file's absolute branch needs IMPORT_WORK_LEFT; its header does not say so (commit claim Incorrect) | Minor | `scripts/lib/dev-cycle-read.sh:1144-1148` | High |
| N2 | import_file's DIR is ignored by its absolute branch (documented) | Informational | `scripts/lib/dev-cycle-read.sh:1148,1263,1339` | High |
| N3 | IMPORT_WHOLE remains a global mode; inheritance closed, post-source assignment not | Informational | `scripts/lib/dev-cycle-read.sh:1030-1032,1141` | High |
| N4 | main_imports' failure list omits outside-file read failures (i1 A6 half) | Informational | `scripts/lib/dev-cycle-read.sh:1285` | High |

## Overall Assessment

The fixes resolve all six iteration-1 findings in substance, at the right owners, and add no new dependency direction or cycle. Nothing is Structural or Coupling. The most useful remaining item is N1: a one-clause header addition so import_file's absolute branch's IMPORT_WORK_LEFT precondition is visible at the seam U2b3b2b will call through. N2-N4 are comment-level and may be taken or declined.

## Goal-Alignment Note

The goal is to land U2b3b2a so that U2b3b2b can queue outside seeds (user memory, rules/ and prompt files under reader homes) as absolute items through this unit's reader. The shape now serves that: absolute items enter `queue`/`tq` and route to import_file through the checkout arm, outside_ok gives the seeding sites the same skip rule, and a probed absolute prompt path yields session bases (`""`, `/home/node`) that import_file now forwards rather than dropping. Nothing here blocks landing; N1 is the one item that would save U2b3b2b's author a read of import_outside's body.
