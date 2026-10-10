Commit: 65007bf8

# API Consistency Review — feat/build-loop-u3a1 (iteration 1)

**Scope:** `git diff main...HEAD` (base d5736445): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`; public surface = `--check`'s output lines, exit codes and `--help` header; internal API = `STATUS` (U3a2's `--merge` consumer)
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1.md` (k=1; 0 Incorrect, 2 Stale, 3 Mostly accurate; `--status` byte-identical to main's over 14 briefs; full check suite 144/144)

## Baseline Conventions

- **State refusals** (`scripts/build-loop.sh:291-327`, `:821`): `refuse state WHAT: WHY`, exit 2, before any verdict. WHAT is a git path or a concept noun (`config`, `info/attributes`, `refs/replace`, `origin/HEAD`, `default-branch`, `gate`); WHY is a short clause, often with `its`/`it` pointing back at WHAT ("its path could not be read", "could not be listed", "its merge repository could not be set up"). Failure clauses use past tense "could not be read/listed/set up".
- **Per-brief refusals** (`:846-900`): `refuse BRIEF: WHY`. The branch is named by the `the X of $br` construction: "the tip of $br is ...", "the merge of $br names a blob ...", "the paths the merge of $br changes could not be ..."; --status's skip uses the same: "the tip of $br starts \"handoff:\"" (`:540`). "the default branch" names main in every message.
- **Help header** (`:1-217`): describes each refusal's condition in prose, quoting the runtime text when it is fixed (blob-lacks, K of N, checkout). Exit section: 0 all ok; 2 any verdict or the state gate not ok; anything else "nothing decided".
- **Globals as values**: the lib's `BRIEF` (`scripts/lib/dev-cycle-read.sh:380-391`), an associative array keyed by the lower-cased line name, each value the *whole line* ("Branch: feat/x"), keys absent when the brief has no such line; `*_WHY` scalars (`CHECKOUT_WHY`, `FLOOR_WHY`, `PATHS_WHY`, `LIST_WHY`, `TRUTH_WHY`) for reasons; functions that fill values are named `NOUN_fields` (`brief_fields`) and print-only wrappers `NOUN_line`.
- **Function naming**: gates over the repository are `NOUN_gate` (`state_gate`, `default_gate`, `checkout_gate`); the gate's own repository helpers are `gate_NOUN` (`gate_repo`, `gate_git`, `GATE_TMP`); the lib's line-printing checks are `check_NOUN` (`check_brief`, `check_branch`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `refuse state objects: ...` | output line (state refusal) | `refuse state gate: ...`, `refuse state default-branch: ...`, `refuse state refs/replace: ...` | `scripts/build-loop.sh:306,322,821` | Consistent — WHAT is a noun naming the thing refused; WHY ends "could not be read" as siblings do |
| `refuse BRIEF: an object of BRANCH's tip or of its merge ...` | output line (per-brief refusal) | "the tip of $br is ...", "the merge of $br names a blob ...", skip "the tip of $br starts ..." | `scripts/build-loop.sh:540,849,876` | Inconsistent — possessive `$br's tip` where every sibling says `the tip of $br` (Finding 1) |
| `status_fields` | function | `brief_fields`, `status_line`, `read_settings` | `scripts/lib/dev-cycle-read.sh:391`, `scripts/build-loop.sh:549` | Consistent — `NOUN_fields` fills a global array; `status_line` kept as its printer |
| `STATUS` (+ keys `line state policy branch loop sha date dispatched reason ahead`) | global assoc array | `BRIEF` (`status branch policy paths asked dispatched`) | `scripts/lib/dev-cycle-read.sh:380-391` | Keys match --status's column names lower-cased (good); same key names as BRIEF carry a different value shape (Finding 3) |
| `store_check` | function | `checkout_gate`, `state_gate`, `default_gate`; `check_brief`, `check_branch` | `scripts/build-loop.sh:291,319,742`; `scripts/lib/dev-cycle-read.sh:423-496` | Off-pattern — `NOUN_check` matches neither family (Finding 2) |
| `gate_start` | function | `gate_repo`, `gate_git` | `scripts/build-loop.sh:566,579` | Acceptable — `gate_` prefix elsewhere means "the gate's merge repository"; here it means "the gate's startup". Noted under Finding 2 |

## Findings

#### 1. The new per-brief refusal names the branch as `$br's tip`; every sibling says `the tip of $br` / `the merge of $br`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:879` (and its help quote at `:123-124`)
**Move:** 2 (naming against the grain), 4 (error-message consistency)
**Confidence:** High
**Legibility-target:** for-author

Precedent: "the tip of $br" / "the merge of $br" used in `scripts/build-loop.sh:540,849,853-876`

Evidence:
```
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of $br's tip or of its merge does not hash to its id, or could not be read"; return; fi
  if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
```
Every other per-brief message (and --status's marker skip) puts the branch after "of", so the BRANCH token sits in the same slot a reader or a quoted-refusal entry (D4: "the refusal quoted in the entry") scans for. The possessive also glues `'s` onto a slash-bearing name (`feat/x's`), the only place a branch name is not space- or end-delimited in the gate's output, which matters if anyone ever extracts the branch from a refusal. The line directly above it (`:876`) already shows the house form.

**Recommendation:** e.g. "refuse BRIEF: an object of the tip of $br or of the merge of $br does not hash to its id, or could not be read" (or "the tip or the merge of $br names an object that ..."), and update the help quote at `:123-124` and the test's expected string at `test/scripts/build-loop-check.bats:1876` together.

#### 2. `store_check` introduces a third naming family beside `NOUN_gate` and `check_NOUN`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:594` (also `gate_start`, `:818`)
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `NOUN_gate` for predicates that refuse repository state, used in `scripts/build-loop.sh:291` (`state_gate`), `:319` (`default_gate`), `:742` (`checkout_gate`); `check_NOUN` for line-printing checks in `scripts/lib/dev-cycle-read.sh:423-496` (`check_brief`, `check_branch`)

Evidence:
```
store_check() {
checkout_gate() {
gate_repo() {
gate_start() {
```
`store_check` is closest in kind to `checkout_gate` (both compare bytes against object ids and return 1 for a refusal the caller words), yet takes the noun-first `_check` suffix used nowhere else. `gate_start` reuses the `gate_` prefix, which so far meant the gate's merge repository (`gate_repo`, `gate_git`, `GATE_TMP`), for the gate's startup sequence. Neither is consumer-visible; they are internal names U3a2/U3b will call, so the cost is only a reader's search pattern. Severity left at Informational because these are internal helpers, not the CLI surface.

**Recommendation:** Consider `store_gate` (or `objects_gate`, matching the "refuse state objects" WHAT) for symmetry with `checkout_gate`; leave `gate_start` or rename to `check_start` only if U3a2 adds a `merge_start`. Not worth a rename on its own.

#### 3. `STATUS` and `BRIEF` share key names with different value shapes and absence rules

**Severity:** Minor
**Location:** `scripts/build-loop.sh:499-505, 514, 546-547`
**Move:** 7 (asymmetry), 8 (nullability)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `BRIEF[branch]`, `BRIEF[policy]`, `BRIEF[dispatched]` hold the whole stored line and stay unset when absent, used in `scripts/lib/dev-cycle-read.sh:380-383`

Evidence:
```
# Sets BRIEF[status], BRIEF[branch], BRIEF[policy], BRIEF[paths], BRIEF[asked]
# and BRIEF[dispatched] (a key with no such line stays unset), each the line as
# stored but for that CR
    STATUS=([line]="ok $a new review - absent - - 0" [state]=new [policy]=review [branch]=- [loop]=absent [sha]=- [ahead]=0 [date]=- [dispatched]=0 [reason]="")
  STATUS=([line]="ok $a $st $pol $br $loop $sha $date $disp${reason:+ $reason}" [state]="$st" [policy]="$pol" [branch]="$br"
```
In the same `check_line` scope a U3a2 author will now hold `BRIEF[branch]` = `Branch: feat/x` and `STATUS[branch]` = `feat/x`; `BRIEF[policy]` = `Policy: self-merge` and `STATUS[policy]` = `self-merge` (or `review`, after the settings gate); `BRIEF[dispatched]` = `Dispatched: 5` and `STATUS[dispatched]` = `5`. Absence also differs: BRIEF leaves a key unset, STATUS fills the printed line's sentinels (`-` for sha/date/branch, `""` for reason, `0` for ahead). Both are defensible (STATUS mirrors --status's columns, which is the right baseline for its own keys), but the identical key names invite `${BRIEF[branch]}` where `${STATUS[branch]}` was meant, and the `-` sentinel means `--merge` must compare `"${STATUS[sha]}" == -` rather than test for unset. Nothing in the diff is wrong today: `check_line` reads only `STATUS[state|policy|branch|sha|loop|ahead]`, after the `ok ` guard.

**Recommendation:** Add one sentence to the STATUS comment: values are --status's printed fields (bare, "-" when absent, never unset on an ok line), unlike BRIEF's whole lines. That is the contract U3a2 will code against.

#### 4. STATUS's non-ok shape and BRIEF's staleness are implicit in the comment

**Severity:** Informational
**Location:** `scripts/build-loop.sh:499-504, 509-515`
**Move:** 8 (nullability)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
# --status for one brief, as values (rows 496, 512): STATUS[line] is the line
# --status prints, and for an "ok" line STATUS holds its fields by name
# (state, policy, branch, loop, sha, date, dispatched, reason) and ahead, the
# branch's commit count past main. brief_fields' BRIEF is the brief as read
# here (check_line takes Paths: from it, so no second read). Call it in the
# caller's own shell.
  [[ "$out" == "ok "* ]] || { STATUS[line]="$out"; return; }
```
On every skip/refuse path STATUS holds `line` alone, so `${STATUS[state]}` aborts under the script's `set -u`; there is no discriminator key, and a consumer must prefix-match `STATUS[line]` against `"ok "` (as `check_line` does at `:844`). And "BRIEF is the brief as read here" holds only past `brief_fields`: for a `new` brief (and the check_brief-refused paths) status_fields returns before calling it, so BRIEF keeps the previous brief's fields (fact-check Claim 8 scope note; harmless today because `check_line` refuses `new` at `:846` before `read_paths`). Both are traps for the second consumer, `--merge`.

**Recommendation:** State in the comment that on any non-ok line only `STATUS[line]` is set and BRIEF is this brief's only on an ok line with state other than `new` (or clear `BRIEF=()` on the early returns). Optionally add a `STATUS[verdict]` (ok/skip) key; not required.

#### 5. The plan's U3a1/U3a2 text no longer matches the as-built contract

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:317-318` (not in the diff)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
... main's commit and every tree and blob of its tree (3,691 objects, 68 MB here: 0.3 s), at the start of each check_line, and then the tip's commit and every object of the merge's result tree. A mismatch refuses the verdict.
... A fault-injection shim for the CAS race (G17) also reaches the failed brief re-read (row 625).
```
As built, main's objects are checked once in `gate_start` and a mismatch is a run-wide `refuse state objects` with exit 2 and no verdict lines (a better fit with the state-refusal family than a per-verdict refusal, but a different consumer contract from the plan's). And U3a1 deleted the brief re-read, so U3a2's planned shim has no re-read branch to reach; override row 625's revisit trigger is now moot. The plan's "collect / judge steps returning TIP, TREE and the verdict as values" is deferred by the commit body ("Verdict values for --merge wait for U3a2"), which is fine but also not in the plan.

**Recommendation:** In the merge's plan as-built note: main's re-hash is a startup state refusal; row 625 closed by removal; verdict values moved to U3a2.

#### 6. A missing subtree under main's tree prints git's own error on stderr beside `refuse state objects`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:600`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
      git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" | awk '$1 != "commit" { print $2 }' || exit 1
    [ "$status" -eq 2 ] && [ "$output" = "refuse state objects: the default branch's commit or an object of its tree does not hash to its id, or could not be read" ] \
        && [ -z "$stderr" ] || { show; return 1; }
```
The fact-check executed a missing subtree: rc=1 with "error: Could not read a1dffc7a…" on stderr (Claim 11). The new test pins empty stderr only for the forged-blob case; the missing-blob case is unasserted on stderr. The script is mixed here (marker_kind's `git cat-file` does not silence stderr either), so this matches some precedent and violates none stated in the help; it is noted only because the forged case sets an empty-stderr expectation the missing-tree case does not meet.

**Recommendation:** Either `2>/dev/null` on the ls-tree (the refusal already says "or could not be read") or leave it; no consumer reads stderr.

## What Looks Good

- **Removed refusals are not a breaking change.** "its branch BRANCH moved or could not be read again" and "the brief could not be read again from the default branch" are gone from the code, the help (`:116-117`, `:161`, `:188-189`) and srules' doc (`:705`); no script, doc or test outside `docs/reviews/` and historical merge messages matches either text (grep over the worktree), and both were untested (fact-check Claim 21). Consumers read any non-ok verdict as refuse, so fewer distinct texts cost them nothing.
- **"refuse state objects"** follows the state family exactly: `refuse state WHAT: WHY`, exit 2, one line, before any verdict; its WHY ends with the family's "could not be read", and the per-brief refusal ends with the same "does not hash to its id, or could not be read" tail, so the two read as one condition at two scopes.
- **Help ordering statement** now matches code: the old carve-out for `refuse state gate` (after settings) is gone because `gate_repo` moved into `gate_start` before `read_settings`; the list's order (state gate → default branch → gate repo → objects) is `state_gate`, `default_gate`, `gate_repo`, `store_check` (`:336`, `:819-822`), verified by fact-check Claim 2. The per-brief help lists blob-lacks, then the hash refusal, then K of N, then checkout, which is the code's order (`:876`, `:879`, `:900`, `:887`).
- **Exit codes unchanged** in meaning: the new state refusal and per-brief refusal map to the documented 2.
- **`status_fields`/`status_line`** reuse the lib's `brief_fields` naming and keep `--status` byte-identical (fact-check Claim 8); STATUS keys are --status's documented column names lower-cased (`:61` `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]`), and `STATUS[reason]` drops the print-format leading space, so values are clean.
- **Stale comments** (`:628`, `:830` still name `status_line`) are the fact-check's Claims 12 and 16; not repeated here.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `$br's tip` breaks the `the tip of $br` / `the merge of $br` form | Minor | `scripts/build-loop.sh:879`, `:123-124` | High |
| 3 | STATUS and BRIEF share key names with different value shapes and absence rules | Minor | `scripts/build-loop.sh:499-505, 514, 546-547` | High |
| 2 | `store_check` (and `gate_start`) off the `NOUN_gate` / `gate_NOUN` patterns | Informational | `scripts/build-loop.sh:594, 818` | Medium |
| 4 | STATUS non-ok shape and BRIEF staleness implicit | Informational | `scripts/build-loop.sh:499-515` | High |
| 5 | Plan U3a1/U3a2 text drifted from as-built contract | Informational | `docs/working/plan-build-loop-handoff.md:317-318` | High |
| 6 | git stderr beside `refuse state objects` on a missing subtree | Informational | `scripts/build-loop.sh:600` | Medium |

## Overall Assessment

The change is consistent with the gate's existing output contract: the new state refusal fits the `refuse state WHAT: WHY` family and its exit-2 semantics, the removed refusals break no consumer, and the help's ordering statement now matches the code. Exit codes keep their meaning. One wording slip in the new per-brief refusal is user-visible (Finding 1, a one-line fix plus the help quote and the test string). The rest concerns STATUS as the internal API U3a2 will consume. It is well named and mirrors --status's columns, but its value shapes and its non-ok shape should be written down before a second consumer codes against them (Findings 3-4). Everything is fixable in place; nothing is Breaking.

## Goal-Alignment Note

**Success criterion (restated verbatim):** "a markdown report saved at the path your dispatch names, structured per your skill."
**Answered:** Yes. Saved at `docs/reviews/api-consistency-reviewer-review-2026-10-10-build-loop-u3a1.md` with `Commit: 65007bf8` at the top, and structured per the api-consistency-reviewer skill (baseline, name-pattern audit, findings with Severity/Location/Evidence/Confidence/Legibility-target, summary table). Every focus area the dispatch named is covered: the two new refusal texts (audit rows, Finding 1, What Looks Good), the removed refusals (What Looks Good), the help's ordering statement (What Looks Good), and STATUS as U3a2's internal API (Findings 3-4).
**Out of scope:** Whether the unchecked ancestor and merge-base reads matter (security/architecture; fact-check Claim 9), the stale `status_line` comments (fact-check Claims 12, 16), and performance of the per-brief re-hash.
**Escalate:** None blocking. Legibility targets: Findings 1-4 → for-author; Findings 5-6 → for-orchestrator-synthesis.
