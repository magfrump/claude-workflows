Commit: 809df345

# API Consistency Review — feat/build-loop-u2b1b (iteration 1)

**Scope:** `git diff main...HEAD` (base 0e4596ce, HEAD 809df345): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `docs/reviews/override-log.md`, `docs/working/plan-build-loop-handoff.md`
**Date:** 2026-10-08
**Based on:** Stage 1 summary `scratchpad/u2b1b-i1/factcheck-summary.md` and `docs/reviews/code-fact-check-report-build-loop-u2b1b.md` (43 claims, 0 Incorrect/Stale)
**Public surface:** `build-loop.sh --check`'s output lines and exit status, its help text, and the plan's interface section (lines 207-213) and D4.

## Baseline Conventions

Surveyed: `build-loop.sh --status` / `--settings` / `--check` (main's copy), `dev-cycle.sh --check-path/-write/-brief/-branch/-fix/-answer` (`scripts/dev-cycle.sh:22-82`), `state_gate` (`scripts/build-loop.sh:210-233`), the lib's `skip` lines (`scripts/lib/dev-cycle-read.sh:390,443,1246`).

- **Line shape.** First word is the line type; a fixed-field line is `WORD ARG FIELD...` (`ok BRIEF STATE ...`, `ok <name> <commit> <n> <date>`); a prose-reason line is `WORD ARG: WHY` (`skip`, `refuse`). Prose after the colon is for humans, not fields.
- **Cardinality.** Every check mode in both scripts prints exactly one line per argument, in argument order. `--check` on main did too.
- **State lines.** `refuse state WHAT: WHY`, with WHAT the git key, file or ref a user can inspect or remove (`config`, a config key name, `info/attributes`, `refs/replace`, `origin/HEAD`), one line per finding, all findings printed before exit 2 (`state_gate` accumulates `bad`). One pre-existing exception: `refuse state gate:` (`:609`), the gate's own setup.
- **Exit.** 0 when every argument answered (dev-cycle) / every line ok (`--check`); 2 for a `--check` refusal; 1 for usage or environment.
- **Printed repo text** passes the scrub; names outside a safe set are not echoed (the lib's `skip ${a//$'\n'/ }`, pathform).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `path BRIEF S PATH` | output line type | `ok BRIEF TIP TREE`, `ok <path>` (--check-path), `ok BRIEF STATE ...` | `scripts/build-loop.sh:94`, `scripts/dev-cycle.sh:22-25` | Consistent in shape (fixed fields, BRIEF second so multi-brief output stays attributable). New: a non-verdict first word, and the first sub-line under an argument; both were planned (main's plan `:212`, `:283`: "one line per changed path and deny lines"). |
| `deny BRIEF S PATH: WHY` | output line type | `refuse BRIEF: WHY`, `skip BRIEF: WHY`, `refuse state WHAT: WHY` | `scripts/build-loop.sh:101,109`; main's plan `:283` | Consistent: `WORD ARG ...: WHY`. A distinct verb from `refuse` keeps path-level and brief-level refusals apart; named in the plan before this branch. |
| `refuse BRIEF: K of N changed paths refused` | verdict variant | other `refuse BRIEF: WHY` reasons | `scripts/build-loop.sh:563-591` | Consistent in shape; drops TIP and TREE the `ok` sibling carries (Finding 1). |
| `refuse state default-branch: WHY` | state line WHAT | `origin/HEAD`, `refs/replace`, `info/attributes`, `gate` | `scripts/build-loop.sh:213-229,609` | Inconsistent in placement and cardinality (Finding 2). |
| status letter `S` ∈ {A, M, D, T} | field | git's own diff-tree letters | `git diff-tree --raw` | Consistent: git's letters unchanged, `--no-renames` removes R/C. |
| `PATH` = `?` placeholder | field value | lib's `skip ${a//$'\n'/ }` (rewrite, not suppress) | `scripts/lib/dev-cycle-read.sh:390,443` | New convention (suppress, not rewrite); safe since `?` is outside NAMECHARS and appears only on deny lines. |
| `gate_git`, `own_blob`, `nrules`, `DENY` | internal helpers | `gate_repo`, `merge_result`, `check_line`, `FILE_WHY` | `scripts/build-loop.sh:463-560` | Consistent (verb/noun lower-case helpers; upper-case result globals). Not public. |

## Findings

#### 1. A K-of-N refusal drops the TIP (and TREE) that D4's merge entry quotes from `--check`'s output

**Severity:** Minor
**Location:** `scripts/build-loop.sh:592` (help `:108`; plan `docs/working/plan-build-loop-handoff.md:59`, F48 `:166`)
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** the help's `refuse BRIEF: WHY` paragraph (`:101-108`) and plan D4 (`:59`)

Evidence (`check_line`, which ends at `:594`):
```
  if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of $i changed paths refused"; fi
  [[ "$i" -eq 0 ]] || printf '%s\n' "${rows[@]}"
```
Plan D4: "The entry body is `--check`'s output: the full 40-hex TIP, every changed path, and each S-rule refusal flagged". The `ok` verdict carries TIP and TREE; its refusing sibling, which is followed by the same path/deny listing, carries neither, so an orchestrator quoting `--check` for a refused branch (D4's "falls through to review, with the refusal quoted in the entry") gets the full path list but no pinned TIP. Not a break today (no consumer exists until U3; `rg build-loop.sh` outside its own tests finds none), but U2c's S-rule refusals will reuse this verdict line, and the entry it feeds pins TIP (L2, `:148`). Other refuse reasons that know the tip already print it (`:569` "the tip of $br is $sha").

**Recommendation:** Either print `refuse BRIEF TIP TREE: K of N changed paths refused` (fields before the colon, as `ok`), or state in D4/the help that the entry takes TIP from `--status`/`--expect`, not from `--check`'s output. Decide before U2c adds S-rule refusals to this line.

#### 2. `refuse state default-branch:` lives outside `state_gate`: two WHAT keys for origin/HEAD, one finding per run, and not covered by the planned `--state`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:244-252` (help `:88-90`; plan `:207`)
**Move:** 2 (naming), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the plan's `--state` interface line (`:207`) and the help's state paragraph (`:88-91`)

Precedent: WHAT names the inspected git key, file or ref, and every finding prints before exit 2, used in `scripts/build-loop.sh:210-233` (`state_gate`; `bad=1` accumulates, `return "$bad"`).

Evidence:
```
  if git show-ref --verify --quiet refs/heads/main && git show-ref --verify --quiet refs/heads/master; then
    echo "refuse state default-branch: both main and master exist"; exit 2
  fi
  p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || true
  if [[ -n "$p" && "$p" != "refs/remotes/origin/$MAIN" ]]; then
    echo "refuse state default-branch: origin/HEAD names ${p#refs/remotes/}, but the default branch taken is $MAIN"; exit 2
```
and `state_gate`'s `:229` `echo "refuse state origin/HEAD: it names a branch other than origin/main or origin/master"`.

Three consumer-visible inconsistencies with the existing state lines: (a) an origin/HEAD problem is reported under WHAT `origin/HEAD` by one check and `default-branch` by the other, so a consumer keying on WHAT sees one ref under two names; (b) the first `default-branch` finding exits, so a repo with both main and master *and* a disagreeing origin/HEAD shows one line, where the help says "Each finding prints" and `state_gate` prints all; (c) the plan specifies `--state` as "`refuse state WHAT: WHY` ... as `--check` prints them (U2b1a's `state_gate`)" (`:207`), so a `--state` built on `state_gate` will pass a repo `--check` refuses. The placement is forced (the check needs `$MAIN`, which `resolve_main` sets after `state_gate`), so this is wording and a U3b note, not a redesign.

**Recommendation:** Accumulate the two default-branch findings before `exit 2`; amend plan `:207` to say `--state` also runs the default-branch check (or factor it as `default_branch_gate` beside `state_gate`); optionally key the origin/HEAD case as `refuse state origin/HEAD: ...` to keep one WHAT per ref.

#### 3. Two deny reasons misdescribe their rule

**Severity:** Minor
**Location:** `scripts/build-loop.sh:547-548`
**Move:** 4 (error consistency)
**Confidence:** High (fact-check claim 22, Mostly Accurate)
**Legibility-target:** the deny WHY strings, which D4's entry quotes to the user

Evidence:
```
  if ! pathform "$6"; then DENY="not an allowed path form (letters, digits and . _ - / only, no .git part)"
  elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]; then DENY="not a regular file on both sides (only modes 100644 and 100755 land)"
```
The test pins `deny $B A -x.md: $NFORM` (`test/scripts/build-loop-check.bats`, T13): `-x.md` uses only the listed characters and has no .git part, so the printed reason does not explain the refusal (pathform also refuses a leading `-` or `/`, and empty, `.` or `..` parts). The mode reason says "on both sides" while an absent side (`000000`, an add or delete) passes. These strings are the user-facing explanation in a merge entry; `--settings`' help (`:27-30`) states the same glob rules in full and is the precedent for complete wording.

**Recommendation:** e.g. "not an allowed path form (letters, digits and . _ - /; no leading - or /, no empty, ., .. or .git part)" and "not a regular file (only modes 100644 and 100755 land)".

#### 4. `--status` does not refuse an ambiguous default branch that `--check` now refuses

**Severity:** Informational
**Location:** `scripts/build-loop.sh:241-252` (the `[[ "$MODE" == check ]]` guard)
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** the help's `--status` paragraph (`:45-80`)

Evidence: `if [[ "$MODE" == check ]]; then` wraps both default-branch refusals; `--status` and `--settings` run `resolve_main` with no such check. D4 collects results by `--status`, so under R7's condition (loop-made local master plus origin/HEAD) the orchestrator's collection reads state from the branch `--check` declines to trust. Consistent with the plan scoping the state gate to `--check`, so not a contract break; whether `--status` should also refuse is a security-reviewer question (honest path vs Q-103 residual), noted here for the asymmetry only.

**Recommendation:** Say in the help that `--status`/`--settings` do not run the default-branch check, or extend it to them when U3b's snippet runs `--status` as gate code.

## What Looks Good

- **Exit status follows the verdict line, robustly.** `out="$(check_line "$a")"; ... [[ "$out" == "ok "* ]] || fails=1` (`:613-614`) tests only the multi-line output's first line; since the verdict line is always first and no `path`/`deny` line can start with `ok `, the "every verdict line ok" contract holds. Help (`:134-135`), plan (`:212`) and the override row 497 update all say "verdict line" consistently, closing U2b1a's api-consistency F4 deferral.
- **Every sub-line carries BRIEF**, so multi-brief output stays attributable by field 2, matching the per-argument convention of both scripts.
- **`deny` reasons are fixed strings** (five of them), so a consumer can match them exactly; fact-check confirmed the help's rule list matches `nrules`.
- **PATH is never echoed outside NAMECHARS** (`:586`), and `?` cannot collide with a real printed name (it is outside NAMECHARS) and occurs only on deny lines (pathform refuses any such path first). No field can hold a blank or a colon, so `path`/`deny` lines split cleanly.
- **Status letters are git's own**, closed to {A, M, D, T} with any other record refused, as the help says.
- **`refuse state gate:`** (pre-existing) is now documented in the help (`:91`); the `info/attributes` reason correction ("not an empty file") matches the `-L`/non-regular test and its test was updated (`build-loop-check.bats:1339-1341`).
- The verdict variant `K of N changed paths refused` and the line names were fixed in the plan before this branch, so the surface was built to the planned interface.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | K-of-N refusal drops TIP/TREE that D4's entry quotes | Minor | `scripts/build-loop.sh:592` | Medium |
| 2 | `default-branch` state lines outside `state_gate`: two WHATs for origin/HEAD, one finding per run, not in planned `--state` | Minor | `scripts/build-loop.sh:244-252` | High |
| 3 | Path-form and mode deny reasons misdescribe their rules | Minor | `scripts/build-loop.sh:547-548` | High |
| 4 | `--status` lacks the default-branch refusal `--check` has | Informational | `scripts/build-loop.sh:241-252` | Medium |

## Overall Assessment

The new surface matches the plan's interface and both scripts' line grammar: first-word line types, `WORD ARG ...: WHY` for prose reasons, BRIEF on every line, git's status letters, and an exit status redefined (and documented in three places) around the verdict line. No consumer exists yet, so nothing breaks. The findings are fixable in place: one field-asymmetry decision to make before U2c reuses the refusing verdict line (Finding 1), the default-branch check's cardinality and its omission from the planned `--state` (Finding 2), and two reason strings (Finding 3). R8 (the GATE_TMP race) has no API surface and is left to the security reviewer.

## Goal-Alignment Note

The user's goal is to land U2b1b after a clean review-fix loop. From the API side this branch is landable: no Breaking or Inconsistent findings, three Minor and one Informational, all wording or contract-documentation fixes that need no new design. Finding 1 is the one worth settling now, because U2c and U3's merge entries will build on the refusing verdict line's fields.
