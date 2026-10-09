Commit: 82bb5281

# Architecture Review — feat/build-loop-u2b3b2a (U2b3b2a, outside chains), final confirming pass

**Scope:** whole branch, `git diff main...HEAD -- scripts test` (55490d15, 18fba03d, f7a96eed, 82bb5281): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2a-i3/shared.md`; Stage-1 fact-check `docs/reviews/code-fact-check-report-build-loop-u2b3b2a-final.md` (k=3: 0 Incorrect, 1 Stale, 4 Mostly accurate, 1 Unverifiable); earlier reports `architecture-review-2026-10-09-u2b3b2a.md` and `-i2.md`; override rows dated 2026-10-09 for this branch

Trigger categories: module structure no (one file, one block); public APIs **yes** (import_outside, import_file, outside_ok are new lib functions; import_targets' reader-set contract changed); data models **yes** (the parser's output stream gains the `//` second channel; new globals IMPORT_DOTNEST, IMPORT_WHOLE); cross-cutting **yes** (one admission rule shared by both walks). In scope.

## Dependency Map

Both walks (`imported_names`, `main_imports`) → `import_file` → {`capped_read | import_targets` for a repo path; `import_outside` for an absolute one} → `import_targets` → `import_readers` (memoized: IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST) → IMPORT_AWK (`emit`/`put`/`show`). Beside them: walks → `outside_ok` (leaf predicate, the outside admission) and walks → `import_work` (trailer). `import_outside` → `nul_list realpath -ez`, `capped_read`, and `IMPORT_WHOLE=1 import_targets /` (its projection). Dependencies point one way, from the walks down to the parser. There is no cycle. The main walk's blob arm still calls `import_targets` directly, which is right, because a blob is not a file-system path.

The H5/A1 change leaves one source of the reader set and its refusal: `import_targets` calls `import_readers || return 1` and passes `IT_ROOTS="$IMPORT_ROOTS"`, so the ROOT_REAL-only fallback and its second refusal check are gone. H2 moves the dotnest computation from the parser process to `import_readers`, which owns the root list the pairs index. The data now lives with its owner.

Trust-boundary cross-reference: the most recent security review is `docs/reviews/security-review-2026-10-09-u2b3b2a-i2.md` (Commit: `f7a96eed`). It predates this diff's last commit, so its boundaries may be stale, but 82bb5281 changes only comments and a test title. Finding F1 below sits on its `B1` (`outside_ok (-f && -r), then import_outside's ... realpath -ez`) and `B2` (`IMPORT_WHOLE=1 import_targets / (put)`).

## Ruling check: "no third path resolver"

The ruling in plan step 5's U2a3c note is: `no third path resolver (IMPORT_AWK's put and the symlink arm's realpath -ms are the two)`. **The branch holds it in substance.** The new `realpath -ez` in `import_outside` (`nul_list rl realpath -ez -- "$1"`) does not map names to repo paths. It asks the kernel one question, "what is this existing file's physical path", which neither existing resolver can answer: `put` is lexical, and `-ms` does not follow links, by design, because it models git symlink text. The answer goes back through `put`, as `printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /`, so `put` still classifies every name as repo-relative, `//` outside, or dotnest-dropped. The absolute-base join (`if (substr(dirs[i], 1, 1) == "/") put(dirs[i] "/" c)`) also goes through `put`. U2b3b2b should keep this shape: any new spelling (seeds, ancestors) reaches the walks' lists only through `put`.

## Shape check for U2b3b2b (plan step 5 split note)

- **Outside seeds as absolute items.** These work as-is through `import_file` (probed in i2; still true at HEAD). A seed's own skip rule is `outside_ok`.
- **C1 seeds (another root's untracked start file, an absolute path *below* a reader root).** Probed at HEAD: `IMPORT_WORK_LEFT=100000 import_file "$r/cfg/CLAUDE.md" ignored` with ROOT_REAL=`$r` printed `docs/x.md`, `cfg/y.md` and a work trailer, with rc=0. `put` maps the absolute base back to repo names, so C1 needs no new reader. `import_outside`'s header names a narrower precondition, though (F3).
- **Main walk phase.** The header pins outside files to phase 2: `tq's checkout files and outside files (absolute paths, never main's) then join it`. U2b3b2b's seeding must push onto `tq`, not `queue`. A seed on phase-1 `queue` would still read correctly, through the checkout arm, but would break the stated phase invariant (F4).

## Findings

#### F1. Outside admission is decided before the projection, so a `//` name whose real path lies in a reader root is admitted by the file-system rule, not the repo rule

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1278` (tree walk `//` arm), `:1386` (main walk `//` arm), `:1158` (outside_ok), `:1140-1147` (import_outside)
**Move:** 2 (responsibility boundaries), 3 (module boundary)
**Confidence:** High (fact-check Claim 2, executed by r2; probe here: `outside_ok` on a dangling link into the repo answers `skipped`)
**Evidence:** `[[ "$p" != //* ]] || { p="${p#/}"; [[ -z "${seen[$p]+set}" ]] && outside_ok "$p" && seen[$p]=1 && tq+=("$p"); continue; }` and `outside_ok() { [[ -f "$1" && -r "$1" ]]; }`. The projection that would identify the target as a repo path (`IMPORT_WHOLE=1 import_targets /`) runs only inside `import_outside`, after admission. Fact-check: "an outside symlink into a reader root whose target that checkout lacks while main has it is skipped by outside_ok as missing, so the main walk answers ok and `docs/t.md: -`."

The branch splits a `//` name's handling into three steps: admit (file system), read, then project (repo or outside). For a link into a reader root, the projection step is the one that knows which admission applies. The main walk's truth for a repo path is main's tree, through `main_checkout`. Because admission comes first, a name that projects into the repo is judged by a rule written for files with no git model. The defect stays narrow here: the gate's own checkout is clean at MAIN_SHA, so only another root's checkout or a dangling directory component shows it. The ordering matters more for U2b3b2b, whose seeds (user memory, `rules/`) are the files most likely to be symlinks into a repo. Security owns the severity of the fail-open (escalated by the fact-check). This finding covers only where the decision lives.

**Recommendation:** Either project before admitting in the `//` arms (`realpath -m`, physical and missing-tolerant, on the name; a result under a reader root goes to the repo admission, and only a truly outside one goes to `outside_ok`), or name the case in the walk header's exception list and carry it into U2b3b2b's plan as a precondition for symlinked seeds.
**Security implication:** moving the projection ahead of `outside_ok` reorders `B1` and `B2` (`docs/reviews/security-review-2026-10-09-u2b3b2a-i2.md`, Commit: `f7a96eed`; the security review predates this diff, so the boundary may be stale). Decide it jointly with security.
**Legibility-target:** for-author (U2b3b2b's planner)

#### F2. Two comments state opposite outcomes for an outside file that changes during the walk

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:732-733` (walk header), `:1135-1139` (import_outside)
**Move:** 3
**Confidence:** High (fact-check Claim 3, all three replicates)
**Evidence:** Walk header: `The walk reads outside files as they are when it runs: one changed or removed during the walk is read as it then is (i2 security F2).` import_outside: `so a file that changed after the walk admitted it fails the walk rather than being skipped.` The fact-check found that a removed, unreadable or directory-swapped file fails the walk, an edited one is read, and a FIFO stalls the read. The returns-1 list also omits the summed IMPORT_WORK_MAX case (Claims 3 and 4), although 82bb5281 calls it complete.

Each comment is half right, and they disagree on "removed". The walk header says it is read as it then is. import_outside says it fails the walk. For a reader learning the outside reader's contract, these are the two places they would look. U2b3b2b's seeds enter through the same function.

**Recommendation:** State the rule once, in import_outside's header (removed, unreadable or not regular: fails; edited: read as it is; FIFO: stalls, per the walk header's exception), add the summed-budget reason, and make the walk header refer to it.
**Legibility-target:** for-author

#### F3. import_outside's header precondition is narrower than its behaviour, and U2b3b2b's C1 seeds rely on the wider behaviour

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1126-1127` (import_outside header), `:1154` (import_file)
**Move:** 3, 8 (extension point)
**Confidence:** High (probed at HEAD, output above)
**Evidence:** `# import_outside FILE [DIRS...]: import_targets' output for FILE, an absolute path below no reader root`. `import_file` dispatches on `[[ "$1" == /* ]]` alone, and an absolute FILE below ROOT_REAL yields repo names (`docs/x.md`, `cfg/y.md`) with rc=0.

The function is a general "read an absolute file-system path" reader, because `put` re-maps an absolute base that lies under a root. The header documents it as outside-only. The plan routes C1 seeds (other roots' untracked start files, which lie under a reader root) "through U2b3b2a's reader". As written, that would call the function outside its stated precondition, even though the call works.

**Recommendation:** In U2b3b2b, when C1 lands, widen the header to "an absolute path (below no reader root, or a file only another root's checkout holds)". Nothing needs to change in this unit.
**Legibility-target:** for-author (U2b3b2b)

#### F4. The phase-2-only rule for outside files is enforced only at the `//` arm, by convention

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1297-1298`, `:1386`
**Move:** 4 (layering of the two phases)
**Confidence:** Medium
**Evidence:** `# Phase 2 begins when queue empties: tq's checkout files and outside files (absolute paths, never main's) then join it`. The arm is `... outside_ok "$p" && seen[$p]=1 && tq+=("$p")`. Nothing in the drain loop rejects an absolute item that arrives on `queue`, which would go through `${ent[$f]-checkout}` to the checkout arm.

The invariant is correct today, because the `//` arm is the one producer. U2b3b2b adds a second producer: the seeding loop. If that loop pushes seeds onto phase-1 `queue`, outside files are read before main's fixpoint, against the header's statement. The answers would not change (the checkout arm reads the same file through `import_file`), so this is a legibility point and not a correctness one.

**Recommendation:** U2b3b2b's seeding pushes onto `tq`, and its test pins that an outside seed is read in phase 2. A guard is optional.
**Legibility-target:** for-author (U2b3b2b)

Not re-raised (declined, or carried with unchanged substance): i2 N2 (import_file ignores DIR on its absolute branch, row Won't-Fix), i2 N3 (IMPORT_WHOLE as a global mode; 82bb5281's H3 comment now states it as a one-call prefix only), outside_ok naming (row), the absent reader home (row, deferred to U2b3b2b). i2 N1 and N4 are resolved by 82bb5281 (B1, H4): import_file's header now reads `An absolute FILE needs IMPORT_WORK_LEFT set, as every walk sets it, and returns 1 without it`, and the failure list reads `a blob, checkout file or outside file cannot be read (import_outside)`.

## What Looks Good

- **One reader-set owner (H5/A1).** `import_targets` no longer has a second path to roots or a second refusal check. A refused or missing memo is one state.
- **Dotnest data moved to its owner (H2).** `import_readers` builds the pairs over the same array it prints as IMPORT_ROOTS, and the parser only reads `IT_DOTNEST`. truthrule's and put's comments point at the new owner.
- **The second channel is in-band but cannot be misread.** `//` names, `/N` trailers and repo names cannot collide (fact-check Claim 1 verified, including digit-ending names and the summed trailer), and the walks' lists document the extra namespace.
- **Resolver discipline.** `put` still classifies every name. The kernel's real path enters only as data (see "Ruling check").
- **Seam for U2b3b2b.** `import_file` gives both walks one entry for any file-system path, `outside_ok` gives seeding sites a named rule, DIRS flow through to the parser, and the probe shows C1 seeds need no new reader.
- **Sourcing inventory** (dev-cycle.bats) lists the three new functions and two new globals, so a dropped definition fails a test.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Outside admission (`outside_ok`, file system) runs before the projection that would route a link-into-root name to the repo admission | Minor | `scripts/lib/dev-cycle-read.sh:1278,1386,1158,1140-1147` | High |
| F2 | Walk header and import_outside give opposite outcomes for a removed outside file; returns-1 list misses the summed-budget case | Informational | `scripts/lib/dev-cycle-read.sh:732-733,1135-1139` | High |
| F3 | import_outside's "below no reader root" precondition is narrower than its behaviour, which C1 seeds will use | Informational | `scripts/lib/dev-cycle-read.sh:1126-1127,1154` | High |
| F4 | Phase-2-only rule for outside files is held by the one producer; U2b3b2b's seeding must push onto `tq` | Informational | `scripts/lib/dev-cycle-read.sh:1297-1298,1386` | Medium |

## Overall Assessment

Over the whole branch, the change improves the import reader's structure. The reader set has one owner, the dotnest table lives with the roots it indexes, both walks share one file entry and one outside admission rule, and the "no third path resolver" ruling holds because the new `realpath -ez` supplies a fact that `put` classifies. Nothing is Structural or Coupling. The one structural observation worth carrying forward is F1: admission is decided before projection, so a `//` name that is really a repo path is judged by the file-system rule. It is narrow here, but U2b3b2b's symlinked seeds will meet it, and fixing it reorders security's B1/B2. Decide it jointly with security, or record it as a U2b3b2b precondition. F2-F4 are comment-level or for U2b3b2b.

## Goal-Alignment Note

- Success criterion (verbatim): "your report saved at the path your own tail names, structured per your skill file, with a `Commit: 82bb5281` line at the top."
- Answered: yes. Saved at `docs/reviews/architecture-review-2026-10-09-u2b3b2a-final.md`, with first line `Commit: 82bb5281`.
- Serves U2b3b2b: yes. Absolute seeds and C1 seeds both go through `import_file` with no new reader (probed). The items for its plan are F1 (symlinked seeds into a root), F3 (widen import_outside's precondition) and F4 (seed onto `tq`).
- Out of scope: the fail-open severities (Claims 1 and 2) belong to security, and the bind-mount alias belongs to the orchestrator.
- Nothing here blocks landing.
