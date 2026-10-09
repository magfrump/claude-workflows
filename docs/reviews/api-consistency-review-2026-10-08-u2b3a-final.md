Commit: 3d2d8c44

# API Consistency Review: feat/build-loop-u2b3a, final confirming pass

**Scope:** the full branch, `git diff main...HEAD -- scripts test`: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`. The plan's U2b3 bullet (`docs/working/plan-build-loop-handoff.md:289-299`) is in scope for claims only. The surface is the lib's internal API, which `scripts/dev-cycle.sh` (check_fix through `truthwalk tree`, `:181`) and `scripts/build-loop.sh` (`import_reset` at `:704`) share, plus the gate caller contract U2b3b and U2c will code against.
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3a-final.md` (k=3, Commit 3d2d8c44: 34 Verified, 2 Mostly accurate, 0 Incorrect). Also the shared brief `u2b3a-i3/shared.md`, the rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md` (iterations 1-2), my i1 and i2 reports, and `overrides.txt` (rows 425, 431, 432, 437, 477 and this branch's nine rows).
**Review pass:** final confirming pass (--loop-pass). Probes: `bats -f 'U2b3a|sourcing'` over both suites at 3d2d8c44, TMPDIR `mktemp -d /tmp/u2b3a3-api-XXXX` (removed): 9/9 ok. One probe script (`set -eu`, own mktemp dir, pwd check before `git init`, removed afterwards) for F1 and the source-time clear.

## Iteration-2 findings: status

| i2 | Finding | Status at 3d2d8c44 | Evidence |
|---|---|---|---|
| N1 | Superset statement said "the longest" root | Resolved: names dotnest and cross-references truthrule (`:686-689`); truthrule's dot line points back (`:1220`); test 4 pins truthrule's `dot` answer for two dot-nested spellings | `rg -n longest scripts/` finds nothing |
| N2 | `readers_key`/`READERS_KEY` unprefixed | Resolved: `import_readers_key`/`IMPORT_READERS_KEY` (`:884-890`) | `rg 'readers_key\b' scripts test` hits only the prefixed name |
| N3 | Item 4 said the registry is re-read "only after a reset" | Resolved: "read again after a reset or when one of those changes, so set them before a decision's first walk: item 9" (`:67-69`); item 9 says "before a decision's first walk" (`:86`) | fact-check final Claim cluster on the memo key: Verified, executed (r3 P4: 0 forks on a hit, 2 after a list change) |
| N4 | Inputs paragraph omitted the registry | Resolved: "Both walks also read the repository's worktree registry (import_readers)." (`:42`) | |
| N5 | `T_READER_*` honoured only by `imps` | Deferred (override row, revisit at U2c floor tests / U2b3b); not re-flagged | |

## Baseline Conventions

- **Function names.** Import-subsystem helpers carry the `import_` prefix: `import_reset` (`:618`), `import_home` (`:851`), `import_readers` (`:891`), `import_readers_key` (`:887`), `import_targets` (`:928`), `import_work` (`:960`). Generic helpers have none: `lower`, `nul_list`, `need_root`.
- **Result globals.** A function publishes into a global named after itself or its subsystem: `import_home` sets `IMPORT_HOME`/`IMPORT_HOME_REAL` (`:856`), `truthrule` sets `TRUTH_WHY`, `floor` sets `FLOOR_WHY`, `open_shared` sets `OPEN_SHARED`.
- **Memo keys.** A `*_DONE` global holds the inputs its result was computed for (`IMPORTED_DONE`, `IMPORTED_MAIN_DONE` `:616`, `IMPORT_HOME_DONE` `:850`, `IMPORT_READERS_DONE` `:883`); `import_reset` clears the per-decision ones (`:618`).
- **Caller knobs.** Upper-case `IMPORT_*`, given a value at source time (`IMPORT_OUT_MAX` `:624`, `IMPORT_WORK_MAX` `:642`, now `IMPORT_READER_ROOTS`/`_HOMES` `:883`); gate-caller duties live in the numbered contract (`:44-89`), "the one statement of it".
- **Errors.** Walk inputs fail with return 1; the walk then reads `error`, which isimported answers fail-closed. Own-home defects fail lazily (only a `~/` name). Bad caller roots and homes are refused (`:906`, `:913`).
- **Parser env.** `IT_*` names passed through `env` (never `awk -v`), list values newline-separated (`IT_XDIRS` `:817`).
- **Tests.** Test names end with a parenthesised provenance tag (`(U2b3a; rows 425, 432)`); lib inputs are passed to the `imps`/`floors` subshell as env prefixes.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `import_readers` | function | `import_home`, `import_targets`, `import_reset` | `scripts/lib/dev-cycle-read.sh:618,851,928` | Consistent |
| `import_readers_key` | function (helper) | `import_home`, `import_readers` | `scripts/lib/dev-cycle-read.sh:851,891` | Consistent (i2 N2 resolved) |
| `IMPORT_READERS_KEY` | global (helper result) | `IMPORT_READERS_DONE`, `IMPORT_HOME_DONE` | `scripts/lib/dev-cycle-read.sh:850,883` | Consistent; missing from the sourcing test's list (F2) |
| `IMPORT_READERS_DONE` | global (memo key) | `IMPORT_HOME_DONE`, `IMPORTED_DONE`, `IMPORTED_MAIN_DONE` | `scripts/lib/dev-cycle-read.sh:616,850` | Consistent |
| `IMPORT_ROOTS`, `IMPORT_HOMES` | global (result) | `IMPORT_HOME`, `IMPORT_HOME_REAL` | `scripts/lib/dev-cycle-read.sh:850-856` | Consistent with the `IMPORT_HOME*` family; their lib-owned status is unstated (F3) |
| `IMPORT_READER_ROOTS`, `IMPORT_READER_HOMES` | caller knob | `IMPORT_OUT_MAX`, `IMPORT_WORK_MAX` | `scripts/lib/dev-cycle-read.sh:624,642` | Consistent: set at source, documented in contract item 9 |
| `IT_ROOTS`, `IT_HOMES` (replace `IT_ROOT`, `IT_HOME`, `IT_HOME_REAL`) | parser env | `IT_DIR`, `IT_XDIRS`, `IT_LEFT`, `IT_WORK` | `scripts/lib/dev-cycle-read.sh:817-826,953-954` | Consistent: plural for a newline list, as `IT_XDIRS` |
| `show`, `dotnest`, `roots`, `homes`, `pre[]` (awk) | parser internals | `emit`, `put`, `splice`, `seen`, `dirs` | IMPORT_AWK `:711-838` | Consistent: bare lower-case names |
| `T_READER_ROOTS`, `T_READER_HOMES` | test-helper knob | `PATH=`/`HOME=` prefixes on `imps` | `test/scripts/build-loop-check.bats:16-25`; none with a `T_` prefix in `test/` | New convention, deferred row (i2 N5) |

## Findings

#### F1. import_readers skips an empty ROOT_REAL instead of refusing it, so "ROOT_REAL first" and import_targets' "returns 1 when ROOT_REAL is empty" both fail after it runs

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:899-909` (against `:863-864`, `:701-702`, `:819-820`)
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** High (executed; same root as fact-check final Claim 1, Mostly accurate, r3 P5)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:899-909
  rs_r=("$ROOT_REAL"); for p in "${rs_l[@]}"; do [[ "$p" != "worktree "* ]] || rs_r+=("${p#worktree }"); done
  [[ -z "$IMPORT_READER_ROOTS" ]] || mapfile -t -O "${#rs_r[@]}" rs_r <<<"$IMPORT_READER_ROOTS"
  [[ -z "$IMPORT_READER_HOMES" ]] || mapfile -t rs_h <<<"$IMPORT_READER_HOMES"
  # The roots and the caller's homes, blank lines dropped, checked and then
  # resolved in one realpath call (a fork per root cost 14 ms over 24 roots).
  for p in "${rs_r[@]}" "${rs_h[@]}"; do
    [[ -n "$p" ]] || continue
    [[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1
    rs_x+=("$p")
  done
  n=${#rs_r[@]}; for p in "${rs_r[@]}"; do [[ -n "$p" ]] || n=$((n - 1)); done
```
(excerpt ends inside import_readers, which continues to `:927`; read whole: IMPORT_ROOTS is built from `rs_ro`, and the key `k`, which holds the empty ROOT_REAL, is stored at `:926`)
```bash
# scripts/lib/dev-cycle-read.sh:863-864
# IMPORT_READER_HOMES. Each is newline-separated, ROOT_REAL or this process's
# home first, and lists every entry as written and as realpath -m reads it,
# scripts/lib/dev-cycle-read.sh:701-702
# It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is
# empty, when a ~/ name appears and the home is not absolute, or when the
```

The blank-line skip, meant for the caller's lists ("blank lines skipped", `:866`), also swallows ROOT_REAL, which is `rs_r[0]`. So import_readers has two error answers for one kind of bad root: a relative ROOT_REAL is refused, an empty one is dropped and the registry's first worktree takes its place. Probe at 3d2d8c44, in a fresh repo with `ROOT_REAL=""`: `P1 readers rc=0 roots=[/tmp/u2b3a3-api-61A9/repo]`, then `import_targets ""` on `@a.md` printed `a`, `a.`, `a.m`, `a.md` and `P1 it rc=0`; with `ROOT_REAL=rel`, `P1b rel readers rc=1`. No walk reaches this (both call need_root first, `:1048`, `:1098`), so the impact is on the next direct caller: U2b3b's outside-seed caller, which the deferred row already says must run import_readers before import_targets.

**Recommendation:** Add `[[ -n "${ROOT_REAL:-}" ]] || return 1` before `:898` (the refusal list at `:872-874` then covers it as "not absolute"), or reword `:701-702` to "an empty first reader root". The guard is the smaller contract.

#### F2. The sourcing test's globals list omits IMPORT_READERS_KEY

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:1114` (the global at `scripts/lib/dev-cycle-read.sh:886`)
**Move:** 3 (test drift)
**Confidence:** High (fact-check final r2, the sourced-definitions cluster's scope line: "It does not list `IMPORT_READERS_KEY`")
**Legibility-target:** for-author

Evidence:
```bash
# test/scripts/dev-cycle.bats:1114
        for v in SKIPPED SKIP_AT MAIN MAIN_SHA MAIN_BY_NAME IMPORTED IMPORTED_DONE IMPORTED_MAIN IMPORTED_MAIN_DONE IMPORT_ROOTS IMPORT_HOMES IMPORT_READERS_DONE IMPORT_READER_ROOTS IMPORT_READER_HOMES BRIEF BRIEF_ODD; do declare -p "$v" >/dev/null 2>&1 || echo "unset $v"; done
```
(one line of the test, which runs `:1106-1118`; read whole)

Iteration 1's G10 fix added the branch's names to this list. `IMPORT_READERS_KEY` came later, in the i2 rename of `READERS_KEY`, and was not added; its function `import_readers_key` was (`:1110`). The list was already incomplete (`IMPORT_HOME*` are absent), and the global is written before it is read, so nothing breaks under `set -u`.

**Recommendation:** Optional: add `IMPORT_READERS_KEY` to `:1114` so the list matches the functions line.

#### F3. IMPORT_ROOTS and IMPORT_HOMES are lib-owned results, but nothing says so, and a write to them between walks reaches the parser unchecked

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:883`, `:895`, `:933`, `:1051`, `:1100`
**Move:** 3 (consumer contract), 8 (who may set a field)
**Confidence:** Medium (read, not executed)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:895
  [[ "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || return 0
# scripts/lib/dev-cycle-read.sh:933
  [[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
# scripts/lib/dev-cycle-read.sh:1051
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED" != error ]]; return; }
```
(three single lines from import_readers `:891-927`, import_targets `:928-955` and imported_names; each read whole)

The caller's inputs (`IMPORT_READER_ROOTS`, `_HOMES`) and the lib's results (`IMPORT_ROOTS`, `_HOMES`) differ by one token. The memo key holds the inputs, not the results, so a caller that assigns `IMPORT_ROOTS` after a walk gets a memo hit at `:895`, a walk-key miss at `:1051`, and a fresh walk whose parser roots skipped every check at `:906` and `:913` (e.g. `/`, which projects every absolute path). The lib states the matching rule for the walk results (contract item 6: read a walk only through isimported or truthwalk) but not for these. No caller writes them, and the honest-loop threat model holds; this is a guard against a U2b3b author who reaches for the shorter name.

**Recommendation:** Optional: one clause in contract item 9 ("IMPORT_ROOTS and IMPORT_HOMES are import_readers' results: read them, never set them").

## What Looks Good

- **Every i2 finding is fixed as recommended**, in the precedent each cited; the rename reached every comment and call site (`rg 'reader_set|READERS_FOR|\breaders_key' scripts test` is empty).
- **The caller contract reads as one coherent statement.** Item 4 now says exactly when the registry is re-read; item 9 says who sets the lists, when, and that sourcing clears them. Probe: with `IMPORT_ROOTS=/evil IMPORT_READER_ROOTS=/evil` inherited, both read empty after sourcing.
- **The parser's env interface shrank and stayed uniform.** `IT_ROOTS`/`IT_HOMES` replace three variables, ride through `env` like `IT_XDIRS`, and keep exit 2's meaning ("no root").
- **Error semantics are uniform for caller input.** Roots and caller homes share one refusal list, applied to the spelling and to realpath's reading; the own home keeps the lazy rule for both of its defects; every refusal is tested in both walks with the fail-closed `want docs/other.md imported` (test 5, 6, 7).
- **Both walk caches key on the same derived value** (`IMPORT_ROOTS`, a blank line, `IMPORT_HOMES`), so the two walks cannot disagree about which reader set a cached answer belongs to; test 8 pins the key and the reset.
- **Consumers are unaffected.** No signature changed: `isimported`, `truthwalk`, `import_reset` and the walks keep their arguments and return codes; `dev-cycle.sh:181` and `build-loop.sh:704` need no change.
- **Tests follow the suite's conventions**: provenance tags in names, both walks in every loop, `want` assertions, fail-closed reads of a failed walk.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | import_readers skips an empty ROOT_REAL instead of refusing it | Minor | `scripts/lib/dev-cycle-read.sh:899-909` | High |
| F2 | Sourcing test omits `IMPORT_READERS_KEY` | Informational | `test/scripts/dev-cycle.bats:1114` | High |
| F3 | `IMPORT_ROOTS`/`IMPORT_HOMES` lib-owned but unmarked; a write bypasses the root checks | Informational | `scripts/lib/dev-cycle-read.sh:883,895,1051` | Medium |

## Overall Assessment

The branch's surface is consistent with the lib's conventions: the new function, memo key, knobs and parser variables follow the `import_`/`IMPORT_*`/`*_DONE`/`IT_*` patterns, the caller contract states the new duties in one place, and no consumer in `scripts/` changes. Nothing is Breaking or Inconsistent. F1 is the one real contract gap, an asymmetric error answer that no walk reaches today; it duplicates fact-check Claim 1 and is a one-line guard. F2 and F3 are optional. From the API side this pass finds no red and no amber.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/api-consistency-review-2026-10-08-u2b3a-final.md, structured per the api-consistency-reviewer skill, with `Commit: 3d2d8c44` as its first line.
- Answered: yes
- Out of scope: settled override rows (T_READER_* in floors, the import_targets fallback including fact-check Claim 4's newline-HOME split outside a walk, the host alias, the second output channel, isimported on dot paths, dotnest rebuild cost, check_fix's reader lists, the immutable commit messages); work-bound figures (performance's); U2b3b and U2c.
- Escalate: (1) F1 and fact-check final Claim 1 are one root; the synthesis should merge them, not count them twice. (2) The plan's parent U2b bullet (`docs/working/plan-build-loop-handoff.md:279`) still prescribes "project a name under the longest matching root", which the U2b3a sub-bullet (`:290`) records as the rule iteration 1 replaced; it is outside the U2b3 bullet's claim scope, but U2b3b's planner reads both.
- Decisions I made: rated F1 Minor, not Inconsistent, because no walk can reach it (need_root runs first); rated F3 Medium confidence because I traced it by reading, not by probe.
