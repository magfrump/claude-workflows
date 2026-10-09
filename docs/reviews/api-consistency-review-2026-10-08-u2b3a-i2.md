Commit: c9197fd2

# API Consistency Review: feat/build-loop-u2b3a, iteration 2 (U2b3a fix range)

**Scope:** partial, `git diff 5516c6e6..HEAD -- scripts test` (fix commits 4dba56dc, c9197fd2): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`. The surface is the lib's internal API, which `scripts/dev-cycle.sh` (--check-fix) and `scripts/build-loop.sh` share, plus the gate caller contract that U2b3b will code against.
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3a-i2.md` (Commit c9197fd2; 33 claims: 0 Incorrect, 1 Stale (Claim 9, `:679`), 7 Mostly accurate). Also the shared brief `u2b3a-i2/shared.md`, the iteration-1 rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md`, my iteration-1 report `docs/reviews/api-consistency-review-2026-10-08-u2b3a.md`, and override rows 425, 431, 432, 437, 477 plus this branch's G8, G9, G11 and G12 rows.
**Review pass:** iteration 2 (--loop-pass). Probe: `bats -f 'U2b3a|sourcing the reader lib'` over `build-loop-check.bats` and `dev-cycle.bats` at c9197fd2, run in a `mktemp -d /tmp/u2b3a2-api-XXXX` TMPDIR (removed afterwards): 9/9 ok. The fact-check's P6 reports both full suites at 192/192.

## Iteration-1 findings: status

| i1 | Finding | Status at c9197fd2 | Evidence |
|---|---|---|---|
| F1 | `IMPORT_READERS_FOR` broke the `*_DONE` key naming | Resolved: renamed `IMPORT_READERS_DONE` | `:873` |
| F2 | `reader_set` dropped the `import_` prefix | Resolved: renamed `import_readers`, call sites `:1039`, `:1088`. The new helper `readers_key` repeats the pattern in a small way (N2) | `:881` |
| F3 | Own HOME holding a newline failed every walk | Resolved: read as empty, so it fails only a `~/` name, as a relative one does. Tested in both walks (fact-check Claims 14, 23; red on 5516c6e6) | `:911`; `build-loop-check.bats:1789-1801` |
| F4 | `/` alone rechecked after realpath for roots only | Resolved: roots and caller homes go through one check, on the spelling (`:896`) and on the realpath (`:903`). `T_READER_HOMES=/x/..` is now refused (test 111) | `:894-903` |
| F5 | Standalone import_targets reused stale lists | Resolved: import_targets now uses the lists only under a current `READERS_KEY` (fact-check Claim 8) | `:922-923` |
| F6 | Caller inputs missing from the contract; two parser comments described one root | Mostly resolved. Item 9 is added, item 4 names the registry, and `:667` and `:704` are rewritten. Residue: the superset statement at `:679` still says "longest" (N1), item 4's new clause overstates the reset rule (N3), and the Inputs paragraph `:34-41` still does not name the worktree registry (N4) | see N1, N3, N4 |
| F7 | Sourcing test omitted the new names | Resolved: it lists `import_readers`, `readers_key` and the five globals (fact-check Claim 25) | `dev-cycle.bats:1110`, `:1114` |
| F8 | `IT_ROOT` redundant beside `IT_ROOTS` | Resolved: dropped, and exit 2 now keys on an empty first `IT_ROOTS` entry (fact-check Claim 12) | `:810` |
| F9 | Projection made isimported depend on the registry | Won't-Fix (override row, api i1 F9); not re-flagged | n/a |

## Baseline Conventions

These carry over from iteration 1 and still hold on the branch:

- **Function names.** The import subsystem's helpers use the `import_` prefix: `import_reset`, `import_home`, `import_readers`, `import_targets`, `import_work` (`scripts/lib/dev-cycle-read.sh:615`, `:841`, `:881`, `:918`, `:950`). The generic helpers have no prefix: `lower`, `nul_list`, `need_root`.
- **Result globals.** A function that publishes one result names a global after itself: `open_shared` sets `OPEN_SHARED` (`:481`), `skipped` sets `SKIP_AT` (`:160`), `truthrule` sets `TRUTH_WHY` (`:1205`), `floor` sets `FLOOR_WHY` (`:1253`), `import_home` sets `IMPORT_HOME*` (`:840`).
- **Memo keys.** A `*_DONE` global holds the inputs its result was computed for: `IMPORTED_DONE`, `IMPORTED_MAIN_DONE` (`:613`), `IMPORT_HOME_DONE` (`:840`), and now `IMPORT_READERS_DONE` (`:873`). `import_reset` clears the keys the contract makes per-decision (`:615`).
- **Caller knobs.** Upper-case `IMPORT_*` variables. The lib gives them a default at source time (`IMPORT_OUT_MAX`, `IMPORT_WORK_MAX`, `:621`, `:635`) or reads them with `${VAR:-default}` (`IMPORT_LEFT`). Gate-caller duties go in the numbered contract (`:43-86`), which calls itself "the one statement of it".
- **Errors.** Walk inputs fail silently with return 1. The walk then reads as `error`, which isimported treats as fail-closed. Own-home defects fail lazily, only when a `~/` name needs that home.
- **Tests.** Lib inputs that the lib reads from the shell are passed to the `imps`/`floors` subshell as env prefixes on the call (`PATH=`, `HOME=`: `build-loop-check.bats:672`, `:691`, `:1784`), and the lib reads them directly.

## Name-Pattern Audit

New or renamed public names in 5516c6e6..HEAD:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `import_readers` | function | `import_home`, `import_targets`, `import_reset` | `scripts/lib/dev-cycle-read.sh:615,841,918` | Consistent (i1 F2 resolved) |
| `IMPORT_READERS_DONE` | global (memo key) | `IMPORT_HOME_DONE`, `IMPORTED_DONE`, `IMPORTED_MAIN_DONE` | `scripts/lib/dev-cycle-read.sh:613,840` | Consistent (i1 F1 resolved) |
| `readers_key` | function (helper) | `import_home` (import-specific, prefixed); `lower`, `nul_list` (generic, unprefixed) | `scripts/lib/dev-cycle-read.sh:642,841,968` | Informational: import-specific but unprefixed (N2) |
| `READERS_KEY` | global (helper result) | `OPEN_SHARED`, `TRUTH_WHY`, `IMPORT_HOME` | `scripts/lib/dev-cycle-read.sh:481,840,1205` | Consistent with result-named-after-function, but the only import-subsystem global without `IMPORT`; folded into N2 |
| `IMPORT_READER_ROOTS`, `IMPORT_READER_HOMES` (now declared, cleared at source) | caller knob | `IMPORT_OUT_MAX`, `IMPORT_WORK_MAX` (defaulted at source) | `scripts/lib/dev-cycle-read.sh:621,635` | Consistent: declared with a default at source like the budgets, and documented in contract item 9 (i1 F6) |
| `show` (awk) | parser function | `emit`, `put`, `splice` | `scripts/lib/dev-cycle-read.sh` IMPORT_AWK | Consistent: a bare verb like its siblings |
| `dotnest` (awk array) | parser table | `seen`, `tried`, `pre` | IMPORT_AWK | Consistent: a bare lower-case noun |
| `T_READER_ROOTS`, `T_READER_HOMES` | test-helper knob | `PATH=`/`HOME=` prefixes on `imps` | `test/scripts/build-loop-check.bats:672,691,1784`; none with a `T_` prefix in `test/` | New convention, forced by contract item 9 (N5) |

## Findings

#### N1. The superset statement still says names are printed relative to "the longest" root

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:677-680`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claim 9, Stale, executed)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:677-680
# leaves the repo and re-enters it is kept; it is kept only when it lies below
# a reader root (import_readers: ROOT_REAL, every registered worktree, the
# caller's IMPORT_READER_ROOTS), and printed relative to the longest one
# holding it. A relative name is resolved against each root's copy of its
```
(excerpt ends inside the IMPORT_AWK header comment, which continues to `:701`; read whole)
```awk
# scripts/lib/dev-cycle-read.sh:746-750 (put)
  nho = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i])) h[++nho] = i
  for (i = 1; i <= nho; i++) {
    for (j = 1; j <= nho; j++) if ((h[i], h[j]) in dotnest) break
    if (j > nho) show(substr(out, length(pre[h[i]]) + 1))
  }
```

This comment is the lib's one statement of what the walks yield, so it is the walks' consumer contract. It describes the projection that A1 replaced. The fix rewrote import_readers' own comment (`:861-863`: "relative to every root holding it but a dot-nested outer one") and put's comment (`:738-744`), but here it only did the rename. A reader who trusts `:679` expects `sub/x.md` to be hidden by a stale `sub/` entry, which is the exact behaviour test 110 now pins as wrong. `rg -n longest` hits only this line.

**Recommendation:** Use the fact-check's wording: "printed relative to every root holding it but an outer one whose path down to a nested holding root has a dot component (put)".

#### N3. Contract item 4 says the registry is re-read "only after a reset", but any change to the memo key re-reads it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:64-67` (against item 9 `:83-86` and the memo `:874-888`)
**Move:** 3 (consumer contract), 7 (asymmetry between items 4 and 9)
**Confidence:** High (fact-check Claim 1, Mostly accurate, executed: git shim counted 3 listings after `IMPORT_READER_ROOTS=/zz` with no reset)
**Legibility-target:** for-orchestrator

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:64-67
#     change (rows 372, 439), or when IMPORT_OUT_MAX or IMPORT_WORK_MAX
#     changes: neither walk's cache key holds them (both hold import_readers'
#     roots and homes, so HOME and IMPORT_READER_* need no reset, but the
#     worktree registry is read again only after a reset).
```
```bash
# scripts/lib/dev-cycle-read.sh:877-888
readers_key() {
  local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES"
  READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d"
}
import_readers() {
  local p i k n t rs_l=() rs_r=() rs_h=() rs_x=() rs_real=() rs_ro=() rs_ho=(); local -A rs_seen=()
  import_home || return 1
  readers_key
  [[ "$IMPORT_READERS_DONE" != "$READERS_KEY" ]] || return 0
  k="$READERS_KEY"
  IMPORT_READERS_DONE=""
  nul_list rs_l git worktree list --porcelain -z || return 1
```
(excerpt ends `:888`; import_readers continues to `:917`, read; `k` is stored into IMPORT_READERS_DONE at `:916`)

Item 4 tells the gate caller that HOME and IMPORT_READER_* need no reset, and that the registry is read again "only after a reset". Item 9 tells that caller to set IMPORT_READER_* after sourcing. A caller that sets the lists between two walks of one decision (or changes HOME) re-reads the registry, so the decision can see two root sets. That breaks the "one decision sees one root set" guarantee at `:867-870`, which item 4 implies holds. The order is harmless today, because no caller sets the lists. It matters for U2b3b, the first caller, which will set them from main's settings.

**Recommendation:** Say "read again only after a reset or a change to ROOT_REAL, HOME or IMPORT_READER_*". Either add to item 9 "before the decision's first walk", or move the per-decision guarantee at `:867-870` to that conditional form.

#### N4. The header's Inputs paragraph still omits the worktree registry (i1 F6 residue)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:34-41`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:38-41
# working tree as it goes, and then reads the working tree's own files (the
# checkout's start files and imported files main lacks, which can only add
# imports or fail it; it needs resolve_main to have found main by name);
# imported_names, checkout_md and main_checkout read the working tree at ROOT_REAL.
```
(excerpt ends with the paragraph at `:41`)

Item 4 now mentions the registry, and import_readers documents it. But the paragraph that lists what each entry point reads still says the walks read main's commit and the working tree only. Both walks also run `git worktree list` (`:888`), whose output decides which names they yield. The residual for that input is named only at `:871-872`.

**Recommendation:** Add a clause: "both walks also read `git worktree list` (import_readers)".

#### N2. `readers_key` / `READERS_KEY` sit outside the import subsystem's prefix

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:874-880` (callers `:884`, `:922`)
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `import_<noun>` helpers and `IMPORT_*`/`IMPORTED_*` globals for the import walks, used in `scripts/lib/dev-cycle-read.sh:613-615,621,635,840-841,873,881,918,950`

Iteration 1's F2 renamed `reader_set` to `import_readers` so the subsystem's entry points could be found by grepping `import_`. The fix adds a helper that is import-specific (it keys on `IMPORT_HOME_DONE` and `IMPORT_READER_*`) and is called from two import functions, but it carries neither prefix. Its global is the only import-subsystem global without `IMPORT`. It does follow the lib's result-named-after-function pattern (`open_shared`/`OPEN_SHARED`). Nothing outside the lib or tests reads it, and `dev-cycle.bats:1110` lists it only as a defined function, so this is Informational, not Minor.

**Recommendation:** Optional. Rename to `import_readers_key`/`IMPORT_READERS_KEY`, which fits beside `IMPORT_READERS_DONE`, or leave it as is.

#### N5. The test helper's `T_READER_*` knobs set a new test convention

**Severity:** Informational (floor: no precedent, already at Informational)
**Location:** `test/scripts/build-loop-check.bats:16-22`
**Move:** 2 (naming), 3 (test drift)
**Confidence:** High
**Legibility-target:** for-author

No existing precedent in `test/**/*.bats` and `test/lib/*.bash` (searched for `T_[A-Z_]+` names and `${X+set}` reads)

Evidence:
```bash
# test/scripts/build-loop-check.bats:16-22
# T_READER_ROOTS and T_READER_HOMES, when set, become the caller's
# IMPORT_READER_ROOTS and IMPORT_READER_HOMES after the lib is sourced (it clears them).
imps() {
    # timeout: a walk that never ends (an import cycle it does not stop) fails the test.
    run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; shift
        [[ -z "${T_READER_ROOTS+set}" ]] || IMPORT_READER_ROOTS="$T_READER_ROOTS"
        [[ -z "${T_READER_HOMES+set}" ]] || IMPORT_READER_HOMES="$T_READER_HOMES"
```
(excerpt ends inside imps, which continues to `:25`; read whole)

Every other lib input the tests vary is passed as an env prefix that the lib reads itself (`PATH=`, `HOME=`). Contract item 9 makes that impossible for the reader lists, because the lib clears them when sourced. So the helper needs a second name, and an inherited `IMPORT_READER_*` now tests item 9 itself (`:1751`). The convention is sound and documented in the helper's comment. Only `imps` honours it, though: `floors` (`:30-34`) ignores `T_READER_*`, so a future floor test that sets them would silently get the default reader set. The test at `:1812-1833` sets the lists inside its own `bash -c` and is consistent with item 9.

**Recommendation:** None needed now. If a floor test needs caller lists (U2b3b), give `floors` the same two lines.

## What Looks Good

- **Every iteration-1 naming finding is fixed in line with the precedent cited.** `import_readers` and `IMPORT_READERS_DONE` now sit with `import_home`/`IMPORT_HOME_DONE`, and the rename reaches all walk-header comments and both call sites (`:1039`, `:1088`). `rg reader_set|IMPORT_READERS_FOR scripts test` finds nothing.
- **Contract item 9 matches the lib's existing knob pattern.** It declares the lists with a value at source time, as `IMPORT_OUT_MAX` and `IMPORT_WORK_MAX` are declared, which also makes the bare `$IMPORT_READER_ROOTS` reads safe under `set -u` (`:890`, `:891`). No consumer breaks: neither `build-loop.sh` nor `dev-cycle.sh` sets the lists, and both call `scrub_reexec` right after sourcing (`build-loop.sh:184`, `dev-cycle.sh:96`), so a U2b3b caller that sets them later is not cleared by the re-exec.
- **import_reset keeps its contract wording true.** "The next call of either walk walks again" (`:614`) now also means a fresh registry read, and `build-loop.sh:704` needs no change.
- **Error semantics are now uniform.** Roots and caller homes share one refusal list, applied to the spelling and to realpath's reading of it. The own home follows the lazy rule for both of its defects (relative, newline). Each refusal is tested in both walks with `want docs/other.md imported` (fail-closed).
- **The memo key is unambiguous.** The length prefixes keep any part from running into the next (fact-check Claim 16). import_targets uses the same key, so its standalone and in-walk modes cannot disagree about whether the lists are current.
- **The parser env contract got smaller, not larger.** `IT_ROOT` is gone, and exit 2 keeps its meaning ("no root") through `IT_ROOTS`' first entry.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| N1 | Superset statement still says "relative to the longest" root | Minor | `scripts/lib/dev-cycle-read.sh:679` | High |
| N3 | Contract item 4: registry re-read "only after a reset", though a key change also re-reads it | Minor | `scripts/lib/dev-cycle-read.sh:64-67` | High |
| N4 | Inputs paragraph omits the worktree registry (i1 F6 residue) | Informational | `scripts/lib/dev-cycle-read.sh:34-41` | High |
| N2 | `readers_key`/`READERS_KEY` lack the import prefix | Informational | `scripts/lib/dev-cycle-read.sh:874-880` | Medium |
| N5 | `T_READER_*` is a new test convention that only `imps` honours | Informational | `test/scripts/build-loop-check.bats:16-22` | High |

## Overall Assessment

The fixes resolve iteration 1's F1-F5, F7 and F8 in line with the precedents those findings cited. F6 is mostly resolved, and F9 is Won't-Fix by override. The fixes introduce no Breaking or Inconsistent change. The new surface (import_readers, IMPORT_READERS_DONE, contract item 9, import_reset's wider clear) follows the lib's memo-key, knob and fail-closed conventions, and no consumer in `scripts/` is affected. What remains is contract wording. N1 and N3 are one-line comment edits. Both matter mostly to U2b3b, the first caller to set the reader lists: N1 states the wrong projection rule, and N3 omits the mid-decision re-read. N2, N4 and N5 are optional.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/api-consistency-review-2026-10-08-u2b3a-i2.md, structured per the api-consistency-reviewer skill, with `Commit: c9197fd2` as its first line.
- Answered: yes
- Out of scope: Override rows G8, G9 (U2b3b), G11 (F9, Won't-Fix) and G12 were not re-flagged. Test 110's caller-root half not exercising its named case is the fact-check's Claim 21 and is not repeated here. The work-bound figures (Claims 6, 7b) belong to the performance critic.
- Escalate: (1) N1 and N3 duplicate fact-check Claims 9 and 1, so the synthesis should merge them, not count them twice. (2) Plan `docs/working/plan-build-loop-handoff.md:289-290` still names the function `reader_roots` and says "relative to the longest root holding it". It is outside this diff's `scripts test` scope, but U2b3b's planner will read it.
- Decisions I made: I rated N2 Informational, not Minor like i1 F2, because `readers_key` is a private helper that nothing outside the lib reads. I took N5's no-precedent downgrade at the floor.
