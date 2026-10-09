Commit: f7a96eed

# API Consistency Review — feat/build-loop-u2b3b2a (U2b3b2a, iteration 2)

**Scope:** fix range `55490d15..f7a96eed` (`git diff 55490d15..HEAD -- scripts test`): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats
**Date:** 2026-10-09
**Based on:** shared brief u2b3b2a-i2/shared.md; Stage-1 fact-check summary (docs/reviews/code-fact-check-report-build-loop-u2b3b2a-i2.md, k=1); iteration-1 report docs/reviews/api-consistency-review-2026-10-09-u2b3b2a.md (F1-F6).

## Baseline Conventions

Unchanged from iteration 1. The points that matter for this range:
- Parser-family helpers carry the `import_` prefix (`import_reset`, `import_home`, `import_readers_key`, `import_readers`, `import_targets`, `import_work`). Predicates elsewhere in the lib are short words with no `is_`/`_ok` split pattern: `dirok` (:187), `inrepo_here` (:184), `plaindir` (:159), `isstart` (:653), `writable` (:223).
- Function contracts sit in a leading `name ARGS: ...` comment that states when the function returns 1.
- The walks set `IMPORT_WORK_LEFT`. With it unset or empty, `import_targets` prints no `/N` trailer (header :793-796). `import_work` returns 1 when the trailer is missing.
- Reader-set globals are newline-separated with no trailing newline. The lib clears them when it is sourced, and the sourcing inventory in test/scripts/dev-cycle.bats:1107-1114 lists them.

## Iteration-1 fixes checked

| i1 | Fix | State |
|---|---|---|
| F1 (A4) | renamed `import_file`. DIRS reach `import_outside` (`"${@:3}"`). The header says DIR is replaced by the file's own directory | **Partly fixed.** DIR/DIRS half done and tested. The trailer half is still undocumented in `import_file`'s header, and `import_outside`'s header words it as a condition, not a requirement. See F1 below |
| F2 | inventory gains `import_outside import_file outside_ok` and `IMPORT_DOTNEST IMPORT_WHOLE` | Fixed |
| F3 | `outside_targets`/`file_targets` → `import_outside`/`import_file`. No caller of the old names is left in scripts/, test/ or non-review docs (rg, and fact-check verified) | Fixed |
| F4 | IMPORT_DOTNEST moved into its own sentence (:1007-1008). The build site says `"I J" lines by 1-based index`. Trailing newline stripped (:1092) like IMPORT_ROOTS/HOMES. The awk still parses it (fact-check verified) | Fixed |
| F6 | walk header :736-737 says the lists also hold lower-cased `//` names that no repo path can match | Fixed (isimported's whole-line match `*$'\n'"$lp"$'\n'*` means a repo-relative `$2` cannot hit a `//` line) |
| F5 | declined (override row) | Not re-raised |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `import_outside` | function | `import_targets`, `import_work`, `import_readers` | scripts/lib/dev-cycle-read.sh:1023-1160 | Consistent (i1 F3 resolved) |
| `import_file` | function | `import_targets`, `import_outside` | scripts/lib/dev-cycle-read.sh:1104-1148 | Consistent |
| `outside_ok` | predicate | `dirok`, `inrepo_here`, `plaindir` | scripts/lib/dev-cycle-read.sh:159-187 | Minor drift: a walk-only helper outside the `import_` family, and `_ok` with an underscore where `dirok` has none (F3) |
| `IMPORT_WHOLE` (now declared at source) | knob/global | `IMPORT_READER_ROOTS`, `IMPORT_READER_HOMES` (cleared at source), `IMPORT_LEFT`, `IMPORT_WORK_LEFT` (not cleared) | scripts/lib/dev-cycle-read.sh:1029-1032 | Consistent with the reader knobs. Not consistent with the per-call budget knobs (F2, Informational) |

## Findings

#### F1. import_file's two contracts are still only half-documented: an absolute FILE returns 1 without IMPORT_WORK_LEFT, and neither header says so

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:1123-1148`
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** import_file's header (the entry U2b3b2b's outside seeds will call), and import_outside's header sentence at :1130

Evidence (verbatim, :1130-1132 and :1144-1148):
```
# its real path. For a walk, which sets IMPORT_WORK_LEFT: the two trailers
# are summed into one, and each call may spend all that a walk has left, so
# the walk's own import_work check is what bounds the pair. It returns 1 on
...
# import_file FILE DIR [DIRS...]: import_targets over FILE as the file system
# holds it, for both walks: a repo path (DIR and DIRS as import_targets takes
# them), or an absolute one through import_outside (its own directory in
# place of DIR, and DIRS).
import_file() { if [[ "$1" == /* ]]; then import_outside "$1" "${@:3}"; else capped_read < "$1" | import_targets "${@:2}"; fi; }
```

Probe (fixture repo under my mktemp dir, `import_file F docs`): IMPORT_WORK_LEFT unset gave `$T/out/p.md: rc=1` with no output, and `docs/r.md` printed names with rc=0 and no trailer. IMPORT_WORK_LEFT=100000 gave both rc=0, each ending in `/N`. So the asymmetry i1 F1 reported is still there for the trailer: a repo FILE prints a trailer only when IMPORT_WORK_LEFT is set, and an absolute FILE needs it. `import_file`'s header says nothing about it. `import_outside`'s "For a walk, which sets IMPORT_WORK_LEFT:" reads as "when called by a walk", not "IMPORT_WORK_LEFT is required, or it returns 1". Its returns-1 list (:1132-1135) names a failed read and a newline real path, but not an unset IMPORT_WORK_LEFT (fact-check Claim 12, Mostly accurate). Commit 18fba03d says "both headers say a walk sets IMPORT_WORK_LEFT", which the fact-check verdicts Incorrect (Claim 24). The new direct-call test (build-loop-check.bats:665) sets `IMPORT_WORK_LEFT=100000` before `import_file`, so it would fail without it. The tests already follow the requirement, but the contract does not state it. Both walks set the variable, so nothing breaks today. A misuse fails closed (rc=1 → error). The cost is a later caller's bare rc=1 that looks like a parse failure.

**Recommendation:** Add one clause to each header. In import_outside's: "needs IMPORT_WORK_LEFT (returns 1 without it) and always prints one trailer". In import_file's: "an absolute FILE needs IMPORT_WORK_LEFT, as import_outside does".

#### F2. IMPORT_WHOLE is cleared at source, unlike the other per-call import_targets knobs

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1029-1032`
**Move:** 1 (baseline), 8 (inherited-value contract)
**Confidence:** Medium
**Legibility-target:** the declaration comment at :1030-1031

Evidence (verbatim):
```
# Set only for one import_targets call (import_outside's projection); cleared here, so an inherited
# one cannot make every walk read its text as whole names (U2b3b2a i1 architecture A1).
IMPORT_WHOLE=""
```

Of the three per-call knobs import_targets reads with `${X:-}` (IMPORT_WHOLE, IMPORT_LEFT, IMPORT_WORK_LEFT), only IMPORT_WHOLE is cleared at source. That choice is correct. The walks always set IMPORT_LEFT/IMPORT_WORK_LEFT themselves on each call, so an inherited value for those two cannot reach a walk. Nothing ever sets IMPORT_WHOLE for a walk, so only clearing protects it. The probe confirmed an inherited `IMPORT_WHOLE=1` reads empty after sourcing. A caller that sources the lib and then sets IMPORT_WHOLE in its own shell would still turn it on for every walk, but no caller in scripts/ does (grep: only :1141 sets it, as a command prefix). The declaration also sits among the reader-set globals under import_readers' header, which the variable does not belong to. A reader may read it as one of that set.

**Recommendation:** Optional. Add "(the walks set IMPORT_LEFT and IMPORT_WORK_LEFT on every call, so only this one needs clearing)" so the asymmetry reads as deliberate.

#### F3. outside_ok sits outside both the import_ family and the lib's predicate spelling

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1149-1152`
**Move:** 2 (naming)
**Confidence:** Low
**Legibility-target:** the function name, for a reader grepping `import_` for the walks' surface

Evidence (verbatim): `outside_ok() { [[ -f "$1" && -r "$1" ]]; }`

Precedent: `import_<noun>` for walk helpers in scripts/lib/dev-cycle-read.sh:732-1160 (`import_reset`, `import_readers`, `import_outside`). Path predicates spelled as one word in scripts/lib/dev-cycle-read.sh:159-187 (`dirok`, `plaindir`, `inrepo_here`).

`outside_ok` serves only the two walks' `//` arms, next to `import_outside`. Its name matches neither neighbour pattern: no `import_` prefix, and `_ok` with an underscore where `dirok` has none. The name does read clearly next to `import_outside`, and the inventory test lists it, so the cost is small. It would be Minor, but I lowered it because the lib's predicates have no single convention (`isstart`, `writable`, `inrepo_here`, `dirok`).

**Recommendation:** None required. If the name is touched in U2b3b2b, `import_outside_ok` would put it in the family.

## What Looks Good

- The rename is complete. No caller of `outside_targets`/`file_targets` is left outside docs/reviews/, and the new names sit in the `import_` family beside `import_targets` and `import_work`.
- The rewritten `//` arms put the admission rule in one place (`outside_ok`) and keep 55490d15's order: the main walk checks seen first, the tree walk after (fact-check verified). The two walks no longer each spell `-f && -r`.
- `import_file` now passes DIRS on for an absolute FILE. Its header says its own directory replaces DIR. The new test pins both the own-directory and the DIRS output (`docs/n.md` and `//$o/docs/n.md`).
- IMPORT_DOTNEST now matches its siblings in documentation (its own sentence in the header, the format at the build site) and in shape (no trailing newline).
- The sourcing inventory covers every new function and global of the unit, including IMPORT_WHOLE.
- `import_outside`'s real-path read uses the lib's existing `nul_list` helper rather than a new idiom.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | import_file/import_outside: absolute FILE returns 1 without IMPORT_WORK_LEFT; neither header states it (i1 F1 residue; fact-check Claim 24 Incorrect) | Inconsistent | `scripts/lib/dev-cycle-read.sh:1123-1148` | High |
| F2 | IMPORT_WHOLE cleared at source, unlike IMPORT_LEFT/IMPORT_WORK_LEFT; declared among the reader-set globals | Informational | `scripts/lib/dev-cycle-read.sh:1029-1032` | Medium |
| F3 | `outside_ok` outside the `import_` family and the `dirok` spelling | Informational | `scripts/lib/dev-cycle-read.sh:1149-1152` | Low |

## Overall Assessment

The fixes are consistent with the lib's conventions. i1 F2, F3, F4 and F6 are fully resolved, the rename left no stale callers, and the new admission predicate unifies the two walks without changing behaviour. One residue remains: the trailer half of i1 F1. `import_file`'s header still does not say that an absolute FILE needs IMPORT_WORK_LEFT, and the commit message says it does. That is a two-clause comment fix. It matters because U2b3b2b's outside seeds are the next callers of `import_file`. F2 and F3 are observations only.

## Goal-Alignment Note

The goal is to land U2b3b2a through its review-fix loop with the walks' superset and fail-closed properties intact. No finding here is a false negative. F1's misuse returns 1, which every walk turns into `error`. F2 describes a protection that works, and F3 is naming only. F1 is the one to fix before U2b3b2b, since that unit's outside seeds will call `import_file` directly. It can be fixed in this unit's fix pass or carried to U2b3b2b's first commit without risk to the floor's answers.
