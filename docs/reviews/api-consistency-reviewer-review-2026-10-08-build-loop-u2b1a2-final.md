Commit: 63ea50e7

# API Consistency Review — feat/build-loop-u2b1a2 (final confirming pass)

**Scope:** `git diff feat/build-loop-u2b1a1...HEAD` at 63ea50e7: `scripts/build-loop.sh` (`--check` surface), `test/scripts/build-loop-check.bats`; plan `docs/working/plan-build-loop-handoff.md` Script interface lines 207, 212-213
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check r1-r3 summary in the shared brief; iteration-2 API review `docs/reviews/api-consistency-reviewer-review-2026-10-08-build-loop-u2b1a.md` (F1-F8), its rubric rows (A13, A14, C4-C6) and override-log rows 497-498

## Baseline Conventions

- **Modes** are `--<word>` flags dispatched by one `case` (`--settings`, `--status`); dev-cycle.sh's single-input readers are a `--check-<noun>` family (`--check-answer`, `--check-branch`, `--check-brief`, `--check-fix`, `--check-path`, `--check-write`), implemented in the lib as `check_<noun>()` (`scripts/lib/dev-cycle-read.sh:387,436,1238`).
- **Line grammar** (stdout): `ok ARG FIELD...`, `skip ARG: WHY`, `refuse ARG: WHY`; one line per argument, in argument order. `skip` means "could not be read", `refuse` is a verdict.
- **Exit**: 0 every line printed; 1 bad usage or environment (not a repo, no perl/lib, no default branch), usage messages on stderr via `usage()`; `--check` adds 2 for any non-ok line.
- **Unreadable inputs** in `state_gate` say so in the WHY: "its path could not be read", "it could not be read (git config exit N)", "could not be listed".

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--check BRIEF... [--expect SHA]` | CLI mode | `--status BRIEF...`; `--check-brief`, `--check-branch`, `--check-answer` | `scripts/build-loop.sh:7-8`; `scripts/dev-cycle.sh` | Consistent with the plan (D7 names it); shares a prefix with the `--check-<noun>` family (Finding 6) |
| `--expect SHA` | CLI option | none in either script (no other option takes a value) | none — searched `scripts/build-loop.sh`, `scripts/dev-cycle.sh` case arms | New category; the plan (`:212-213`, F15) fixes its spelling for `--merge` too |
| `refuse state WHAT: WHY` | output line | `refuse BRIEF: WHY`, `skip BRIEF: WHY` | `scripts/build-loop.sh:84-100` | Consistent (the `state` token keeps it apart from brief lines; plan `:207` now matches) |
| `refuse state gate: …` | output line | `refuse state info/attributes: …` | `scripts/build-loop.sh:194-196` | Inconsistent — "gate" is not repo state (Finding 1) |
| `ok BRIEF TIP TREE` | output line | `ok BRIEF STATE POLICY …` | `scripts/build-loop.sh:46` | Consistent (`ok ARG FIELD...`) |
| `harden`, `state_gate`, `gate_repo`, `merge_result` | functions | `resolve_main`, `main_by_name`, `read_settings` | `scripts/lib/dev-cycle-read.sh:483`; `scripts/build-loop.sh:299` | Consistent (lower snake case, verb or noun phrase) |
| `check_line` | function | `status_line`; `check_brief`, `check_branch`, `check_answer` | `scripts/build-loop.sh:400`; `scripts/lib/dev-cycle-read.sh:387,436,1238` | Consistent with `<mode>_line`; reads like the lib's `check_<noun>` (Finding 6) |
| `EXPECT`, `GATE_TMP`, `GATE_ENV`, `STATE_KEYS_RE` | globals | `MAIN_SHA`, `OPEN_SHARED`, `POLICY_LINE` | `scripts/lib/dev-cycle-read.sh`; `scripts/build-loop.sh` | Consistent (upper snake case) |

## Findings

#### 1. `refuse state gate: its merge repository could not be set up` uses the state-line form for a gate fault, and neither the help nor the plan lists it

**Severity:** Minor
**Location:** `scripts/build-loop.sh:503`; help `:78-100`; plan `:207,212`
**Move:** 4 (error consistency), 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
```
```
#             info/grafts, or a replace ref prints "refuse state WHAT: WHY"
#             per finding and exits 2 before any brief is read. Then one line
```
Probe (a PATH `mkdir` that exits 1): `refuse state gate: its merge repository could not be set up`, rc=2. Every other `refuse state` WHAT names a planted key, file or ref that the user could remove; "gate" names the script's own scratch repository, a fault in this run (mktemp dir, object format). The help's list of `refuse state` causes and the plan's `--state` line ("for each planted `.git` state") do not include it, and U3b's `--state`, which prints `state_gate`'s lines (plan `:207`), will never print it. An orchestrator quoting this line in a D4 entry would steer the user to clean `.git`. No test covers the line.

**Recommendation:** Give it its own form, e.g. `refuse gate: its merge repository could not be set up` (still exit 2, fails closed), or route it to stderr with exit 1 like the other environment failures (Finding 2). Add it to the help's `--check` block and the plan's `--check` line, plus a stubbed-`mkdir` test.

#### 2. The same gate-setup step exits 1 or 2 depending on which half fails

**Severity:** Minor
**Location:** `scripts/build-loop.sh:502-503`; exit text `:107-109`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
    GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
    gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
```
```
# Exit: 0 every line printed (or help), and for --check every line ok; 2 any
# --check line or the state gate not ok; 1 bad usage, not a git repo, no perl
# or lib/dev-cycle-read.sh, or no default branch found by name.
```
Probe: `TMPDIR=<missing dir>` gives mktemp's own message on stderr and rc=1 (set -e), with no stdout line; a failing `mkdir` inside `gate_repo` gives the stdout `refuse state gate:` line and rc=2. The exit text lists neither cause under 1. Both fail closed, so nothing merges, but a consumer that reads 1 as "my invocation was wrong" and 2 as "the gate said no" gets both answers for one fault.

**Recommendation:** Pick one class for "the gate's scratch space could not be made": fold `mktemp -d` into the same `|| { …; exit N; }` as `gate_repo`, and list it in the Exit text.

#### 3. An unreadable origin/HEAD is reported as "names a branch other than origin/main or origin/master", and git's error leaks to stderr

**Severity:** Minor
**Location:** `scripts/build-loop.sh:198-201`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
  rc=0; p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || rc=$?
  if [[ "$rc" -gt 1 ]] || [[ -n "$p" && "$p" != refs/remotes/origin/main && "$p" != refs/remotes/origin/master ]]; then
    echo "refuse state origin/HEAD: it names a branch other than origin/main or origin/master"; bad=1
  fi
  return "$bad"
}
```
(`state_gate` ends at `:203`.) Probe: `.git/refs/remotes/origin/HEAD` holding `garbage` gives `fatal: No such ref: refs/remotes/origin/HEAD` on stderr, then `refuse state origin/HEAD: it names a branch other than origin/main or origin/master`, rc=2. The ref names nothing. Every sibling unreadable case in the function says so in the WHY ("its path could not be read", "it could not be read (git config exit N)", "could not be listed") and silences git's own stderr (`2>/dev/null` on the `rev-parse` calls). The verdict is right; only the WHY is misleading.

**Recommendation:** Split the `rc -gt 1` arm: `refuse state origin/HEAD: it could not be read (git symbolic-ref exit $rc)`, and add `2>/dev/null` to the call.

#### 4. The `--check` help's state-gate list omits shallow and origin/HEAD (consumer-facing side of the fact-check's finding)

**Severity:** Minor
**Location:** `scripts/build-loop.sh:78-85`; plan `:281`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check r1-r3, "Mostly accurate")
**Legibility-target:** for-author

**Evidence:**
```
#             remote.*.promisor (a partial clone), a non-empty info/attributes or
#             info/grafts, or a replace ref prints "refuse state WHAT: WHY"
```
The two lines added since iteration 2 (`refuse state shallow: present and not empty`, `refuse state origin/HEAD: …`) are tested (bats `:1333-1341`) and printed in the same form as their siblings, which is good. The help is the one consumer contract the orchestrator reads, and it still lists only the iteration-2 set. Not re-verified here; see the fact-check.

**Recommendation:** Add "a non-empty shallow, and an origin/HEAD naming a branch other than origin/main or origin/master" to the help list; plan line 281's U2b1a bullet with it.

#### 5. "every line ok" as the stated exit rule constrains U2b1b's per-path lines to start with `ok`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:107`; plan `:212`
**Move:** 3 (consumer contract, forward compatibility)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# Exit: 0 every line printed (or help), and for --check every line ok; 2 any
```
```
- `--check BRIEF… [--expect SHA]` → … then per brief `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY`; U2b1b adds per-path lines and must make the exit status "every line ok".
```
This matches deferred row 497 (iteration-2 F4, rubric A13), which is not reopened. The new point is the wording the deferral left as the contract: read literally, a path line that is not a refusal must itself start `ok`, which puts `ok PATH …` beside `ok BRIEF TIP TREE` and leaves them distinguishable only by field count. That is the outcome F4 recommended against (a distinct leading word such as `path BRIEF MODE PATH` / `deny BRIEF PATH: WHY`). The D4 merge entry quotes this output, so the per-path grammar becomes a contract when U2b1b ships.

**Recommendation:** Reword the plan line and the Exit text before U2b1b codes it: "exit 0 when every brief's line is `ok` and no `deny` line is printed", and fix the path-line leading words in U2b1b's plan bullet (`:283`).

#### 6. `--check` and `check_line` sit beside the `--check-<noun>` / `check_<noun>` family with a different meaning

**Severity:** Informational
**Location:** `scripts/build-loop.sh:8,470`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `--check-<noun>` single-input reader modes used in `scripts/dev-cycle.sh` (`--check-answer`, `--check-branch`, `--check-brief`, `--check-fix`, `--check-path`, `--check-write`), implemented as `check_<noun>()` in `scripts/lib/dev-cycle-read.sh:387,436,1238`

**Evidence:**
```
#        scripts/build-loop.sh --check BRIEF... [--expect SHA]
```
```
check_line() {
```
In the family, `--check-X` reads one X and `check_X` is its reader; bare `--check` is the merge gate, and `check_line` prints a line rather than checking one. The plan gives build-loop.sh `--check-answer` as well (T34, `:221`), so both spellings will live in one usage line. The names are the plan's (D7) and `check_line` follows `status_line` (`:400`), so this is a note, not a request.

**Recommendation:** Optional: when `--check-answer` arrives in build-loop.sh, add one help sentence that `--check` is the gate and `--check-*` are readers. No rename needed.

#### 7. Iteration-2 F7 and F8 have no recorded disposition, and the help still lacks the sentence F7 asked for

**Severity:** Informational
**Location:** `scripts/build-loop.sh:98-99,107-109,129-140`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
#             skip BRIEF: WHY
#                 As --status skips it.
```
Neither the rubric (C-rows stop at C6 for api-consistency) nor the override log (`:497-498`) records iteration-2 F7 (inside `--check`, "could not be read" appears under `refuse state`, `refuse BRIEF` and `skip`, all exit 2) or F8 (`--check --bogus` → `skip --bogus: not an allowed path form`, rc=2; re-probed, unchanged). Both were Informational and the behaviour is right (fails closed); only the record is missing.

**Recommendation:** Add a Won't-Fix or Fixed row for each, or add F7's one help sentence ("in --check every non-ok line blocks the merge; skip lines and the 'could not be read' refusals mean the input was unreadable, not judged").

#### 8. Extending to U3's `--merge`: the argument loop and the success line need deciding first

**Severity:** Informational
**Location:** `scripts/build-loop.sh:128-140`; plan `:213`
**Move:** 3 (consumer contract, forward compatibility), 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  --check)
    MODE=check; shift
    while [[ $# -gt 0 ]]; do
      if [[ "$1" == --expect ]]; then
```
(the arm continues to `:140`, ending with the one-brief rule for `--expect`.) `--merge BRIEF --expect SHA [--approved Q-NNN]` makes `--expect` required and adds a second value option; the loop is inlined in the `--check` arm, so U3 either copies it or lifts it into a function. The plan says `--merge` prints "as `--check`, then commit-tree and CAS" but gives no success line; reusing `ok BRIEF TIP TREE` for "merged" would make a `--check` and a `--merge` transcript indistinguishable in a D4 entry. The gate also narrows the header's "default branch found by name (origin/HEAD, main or master)": under `--check` (and `--merge`) an origin/HEAD naming any other branch is a state refusal, which the header does not say.

**Recommendation:** In U3's plan bullet, name `--merge`'s success line with its own leading word (e.g. `merged BRIEF TIP NEWMAIN`), share one option parser between `--check` and `--merge`, and note the origin/HEAD narrowing beside the "found by name" sentence.

## What Looks Good

- Iteration-2 F1 fixed: `state_gate` assigns `--git-path` output to `p` and keeps `$f` for WHAT (`:184,193`).
- Iteration-2 F2 fixed: plan `:207` now gives `--state` the shipped `refuse state WHAT: WHY` form and `:212` lists `--check`'s line forms and exit duty.
- `--expect` validation is consistent with the usage-error convention: bad, short, named, upper-case, repeated or multi-brief forms exit 1 through `usage()`, and either argument order works (bats `:1275-1290`); a stale full id is a per-brief `refuse` naming both ids (re-probed).
- The new state lines (`shallow`, `origin/HEAD`) follow the existing WHAT naming (git-dir-relative file path, ref short name) and are printed in a fixed order, all before any brief line, then exit 2.
- `ok BRIEF TIP TREE` keeps the `ok ARG FIELD...` shape, and the `refuse BRIEF:` reasons name the branch and the cause in the same tone as `--status`'s skips.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `refuse state gate:` is a gate fault in the state-line form; undocumented, untested | Minor | `scripts/build-loop.sh:503` | High |
| 2 | Gate setup exits 1 (mktemp) or 2 (gate_repo) for one fault | Minor | `scripts/build-loop.sh:502-503` | High |
| 3 | Unreadable origin/HEAD reported as "names a branch other than…"; stderr leaks | Minor | `scripts/build-loop.sh:198-201` | High |
| 4 | Help's state-gate list omits shallow and origin/HEAD | Minor | `scripts/build-loop.sh:78-85` | High |
| 5 | "every line ok" wording pins U2b1b's path lines to `ok` | Minor | `scripts/build-loop.sh:107`; plan `:212` | Medium |
| 6 | `--check`/`check_line` beside the `--check-<noun>` family | Informational | `scripts/build-loop.sh:8,470` | Medium |
| 7 | Iteration-2 F7/F8 have no disposition row | Informational | `scripts/build-loop.sh:98-99` | High |
| 8 | `--merge` needs a shared parser and its own success word; origin/HEAD narrowing undocumented | Informational | `scripts/build-loop.sh:128-140`; plan `:213` | Medium |

## Overall Assessment

`--check`'s surface is consistent with the script's established grammar: modes, `ok`/`skip`/`refuse` lines, usage errors at exit 1, and the `refuse state` prefix the plan now matches. Iteration 2's F1 and F2 are fixed, and F3, F4 and F5 are settled rows. Nothing is Breaking or Inconsistent. The five Minor items are wording and error-class fixes that can be made in place: the new `refuse state gate:` line, the 1-vs-2 exit split for gate setup, origin/HEAD's misleading WHY, the help list, and the "every line ok" wording U2b1b inherits. The consumer most exposed is the orchestrator quoting `--check`'s output in a D4 entry. Findings 1 and 5 are the ones that change what that reader is told.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 63ea50e7` line at the top.
- Answered: yes
- Out of scope: merge_result's exit-0-on-missing-tree, the vacuous submodule and partial-clone tests, and system config reach (fact-check's; not re-reported); security F3 (deferred row).
- Escalate: nothing
