Commit: ae08688c

# API Consistency Review: feat/build-loop-u2b1a1 (final confirming pass)

**Scope:** `git diff main...HEAD` at ae08688c (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, test/scripts/build-loop-check.bats, plan and questions docs)
**Date:** 2026-10-08
**Based on:** Stage 1 code-fact-check replicates r1-r3 (docs/reviews/code-fact-check-report-build-loop-u2b1a1-r{1,2,3}.md), as summarized in the shared brief

## Baseline Conventions

Surveyed in scripts/lib/dev-cycle-read.sh and its two callers.

- **Predicates** are short lower-case words with no underscore, most with an `is` prefix (`isbrief`, `isclosed`, `isstart`, `isimported`), some noun-adjective (`rawfile`, `plaindir`, `ownfile`, `writable`). `scripts/lib/dev-cycle-read.sh:135-201, 522, 1059, 1108`.
- **Lazily computed state** is a lower_snake function paired with an UPPER_SNAKE global it sets (`import_home`/`IMPORT_HOME`, `main_imports`/`IMPORTED_MAIN`, `floor`/`FLOOR_WHY`, `truthrule`/`TRUTH_WHY`), declared and initialized next to the function. A walk that fails stores the word `error` (`IMPORTED=error; IMPORTED_MAIN=error`, :592).
- **Memoization keys the cache to its inputs**: `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (:965-966), `IMPORT_HOME_DONE` keyed to HOME (:788-796), with `import_reset` (:594) as the explicit invalidation the header's item 4 tells callers to use.
- **The header (:15-85) is the one caller contract**: it names which functions exit (need_root), which to call in the caller's shell, which skip until `resolve_main` has found main by name, and states "a second call re-reads main".
- **Reader output** is one line per argument: `ok ...`, `absent ...`, or `skip ARG: WHY`. WHY is a lower-case clause, often starting "its" (check_brief: "its first Branch: line is not exactly ..."). build-loop.sh `--status` passes check_branch's WHY through as `skip BRIEF: Branch: WHY` (build-loop.sh:337).
- **Help texts** are the script headers, printed by `-h`. build-loop.sh's header wraps at 80 columns everywhere but the new line; dev-cycle.sh's header already has several lines over 80.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `anybrief` | function (predicate) | `isbrief`, `isclosed`, `isstart` | `scripts/lib/dev-cycle-read.sh:199-200, 522` | Consistent in shape (one lower-case word, no underscore); leaves out the `is` prefix its two parts carry. Settled: override row 323 proposed this name. Informational only |
| `open_shared` | function (lazy computer) | `import_home`, `main_imports`, `resolve_main` | `scripts/lib/dev-cycle-read.sh:483, 791, 960` | Consistent: lower_snake, paired with a global of the same name in upper case, like `import_home`/`IMPORT_HOME` |
| `OPEN_SHARED` | global | `IMPORT_HOME`, `IMPORTED_MAIN`, `SKIPPED` | `scripts/lib/dev-cycle-read.sh:145, 592, 790` | Consistent in name and in the `error` sentinel (`IMPORTED_MAIN=error`). Its cache rule differs from its neighbors' (F2) |
| `count` (local; was `n`) | local | n/a | n/a | Private local; not audited |
| `skip NAME: its commit count or date could not be read` | output line (check_branch) | `skip NAME: not an allowed branch name`, `skip NAME: the default branch` | `scripts/lib/dev-cycle-read.sh:438-442` | Consistent: same `skip NAME: WHY` shape. Under `--status` it reads `skip BRIEF: Branch: its commit count or date could not be read`, matching the other passed-through reasons |
| `bad its commit could not be read` | marker_kind answer | `bad it holds a NUL byte`, `bad it has no parent` | `scripts/build-loop.sh:287-288` | Consistent as a word. Inconsistent as `--status` prints it (F1) |
| removed `shared_branches`/`SHARED_BRANCHES` | build-loop.sh internal | n/a | `rg 'shared_branches\|SHARED_BRANCHES'` outside docs/reviews: no hits | Not a break: script-internal, with no callers or tests left |

## Findings

#### F1. `--status` prints a failed commit read as "starts "handoff:" but is not a marker", a premise it never established

**Severity:** Minor
**Location:** `scripts/build-loop.sh:281-283` (marker_kind), `scripts/build-loop.sh:343` (status_line), help text `scripts/build-loop.sh:68-73`
**Move:** 4 (error consistency), 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
  if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then
    echo "bad its commit could not be read"; return
  fi
```
```
      bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"; return ;;
```

status_line has one branch for every `bad` answer. Its fixed prefix asserts that the tip's subject starts "handoff:". That was true of every `bad` reason before this unit, because each one was reached only after the `[[ "$subj" == handoff:* ]]` test. The new failed-read `bad` comes before the subject is read, so the line becomes `skip B: the tip of feat/x starts "handoff:" but is not a marker: its commit could not be read` whatever the tip's subject is. The help text likewise names only "the tip's subject ... starts "handoff:" but it is not a marker". Row 307 settles that a failed read answers bad, never working. It does not settle the wording. The reader most likely to hit this path (a corrupt or racing tip) is the one that needs the true reason. Reachability is narrow: under `log.date bogus`, check_branch skips first (test :251), so this mainly covers object-read failures.

**Recommendation:** In status_line, give the failed read its own case before `bad\ *` (for example `skip B: the tip of BR could not be read`), or make the `bad` prefix neutral. Add that clause to the `skip BRIEF: WHY` list in the help.

#### F2. `open_shared` memoizes without a key and caches `error`, unlike the lib's other memoized walks

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:457-481`
**Move:** 1/3 (baseline convention, consumer contract)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: input-keyed memo (`IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"`, `IMPORT_HOME_DONE` keyed to HOME, invalidated by `import_reset`) used in `scripts/lib/dev-cycle-read.sh:592-594, 788-796, 965-966`

**Evidence:**
```
# it reads error. open_shared computes it once per process, from MAIN_SHA.
```
```
  [[ -z "$OPEN_SHARED" ]] || return 0
  if ! main_by_name; then OPEN_SHARED=error; return; fi
```

The header tells callers that "a second call [of resolve_main] re-reads main". After such a call, OPEN_SHARED still holds the old MAIN_SHA's answer. A first call made before main is found by name also pins `error` for the rest of the process, while check_brief and check_branch re-test `main_by_name` on every call. Neither case can happen today: both build-loop.sh and U2b1a2's `--check` run `resolve_main` once before `open_shared` (build-loop.sh:119; u2b1a2 :210, :501). The comment states the once-per-process rule, so this is a convention divergence, not a bug. It is an easy trap for the U2b/U2c callers that re-read main around `--expect`.

**Recommendation:** Key the cache the way `main_imports` does (store `$MAIN_SHA $MAIN_BY_NAME` beside it and recompute on mismatch), or clear it in `import_reset` / `resolve_main`. If you do neither, name the once-per-process rule in the header beside "a second call re-reads main".

#### F3. The lib header's caller contract does not mention `open_shared`/`OPEN_SHARED`

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1-7, 15-33` (header) versus `:457-466`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
# readers refuse (FENCE_AWK), the brief, branch and answer checks, the
```
```
# check_answer skip every argument unless it returned 0 with main found by name
```
```
# warns, exits 0 or 1) is not counted (row 293). Call it in the caller's shell.
```

The header says it is the one statement of what callers must do. It lists which functions need resolve_main, which to call in the caller's shell, and which globals they set (SKIPPED, SKIP_AT). The new public function and global appear only in their own comment. That comment's "Call it in the caller's shell" uses the header's wording for exiting checks, but here the reason is different: the memo persists only in the caller's shell (U2b1a2 :501 says so: "check_line runs in a subshell"). `open_shared` never exits. A reader of the header could take it for an exiting check, or miss it altogether.

**Recommendation:** Add one header sentence: open_shared needs resolve_main to have found main by name (else OPEN_SHARED=error). Say that it is called in the caller's shell so the result persists, not because it exits. Add "brief enumeration" to the opening summary.

#### F4. The `--status` help line that grew in this diff is over-long and blurs the list it extends

**Severity:** Minor
**Location:** `scripts/build-loop.sh:69-73`
**Move:** 3 (documentation)
**Confidence:** High
**Legibility-target:** for-author

Precedent: 80-column wrapping used in `scripts/build-loop.sh:1-83` (every other header line; awk finds only line 72 over 80, at 120)

**Evidence:**
```
#                 malformed, its branch name is refused (as --check-branch)
#                 or its commit count or date cannot be read, on a branch ahead of main the tip's subject (its message's
#                 first line) starts "handoff:" but it is not a marker, or, for
```

The new clause joins the list with "or" partway through, while the list continues after it (", on a branch ahead of main ..., or, for an open brief only ..."). The line now reads as if the enumeration ends at "date cannot be read". `-h` prints the header verbatim, so the 120-column line is what users see.

**Recommendation:** Reflow to the header's width and make the clause a comma item: "its branch name is refused or its commit count or date cannot be read (both as --check-branch), ...".

#### F5. `--check-branch`'s help names "a broken log.* config" as the cause, which is narrower than the code's rule

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:48-49`; `scripts/lib/dev-cycle-read.sh:434-435`
**Move:** 3 (documentation drift; builds on fact-check r1 "Mostly accurate")
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
#             (HEAD, refs/...) or the default branch, or a branch whose count
#             or date cannot be read (a broken log.* config). The commit is
```

The lib comment says "a broken log.* config, say". The help says "(a broken log.* config)" with no "say", which reads as the only cause. Fact-check r1 shows `grep.patternType bogus` triggers it too. The output contract itself, `skip <name>: <reason>`, is unchanged and consistent.

**Recommendation:** Write "(a broken git config, for example log.date)" in the help, to match the lib's "say".

#### F6. `anybrief` leaves out the `is` prefix of the two predicates it combines

**Severity:** Informational (floor; settled)
**Location:** `scripts/lib/dev-cycle-read.sh:201`
**Move:** 2 (naming)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Precedent: `is`-prefixed path predicates (`isbrief`, `isclosed`, `isstart`) used in `scripts/lib/dev-cycle-read.sh:199-200, 522`

**Evidence:**
```
anybrief() { isbrief "$1" || isclosed "$1"; }
```

Override row 323 proposed the name `anybrief`, so this matches a settled row and needs no change. It is recorded only so the next predicate does not copy either form by accident. The lib already mixes `is`-prefixed names with names like `ownfile` and `rawfile`.

**Recommendation:** None (settled, row 323).

## What Looks Good

- The rename `shared_branches`/`SHARED_BRANCHES` → `open_shared`/`OPEN_SHARED` matches the lib's function/global pairing and its `error` sentinel. The old names were script-internal, with no other callers or tests, so nothing breaks.
- `anybrief` replaces all three earlier `isbrief || isclosed` call sites (writable, check_brief, open_shared), which closes row 323's revisit trigger.
- check_branch's new reason keeps the `skip NAME: WHY` contract. Its wording ("its ...") matches the other readers' reasons, and `--status` passes it through as `skip BRIEF: Branch: ...` like the existing name refusals. The new test pins the exact line, and the help texts of both scripts were updated alongside.
- marker_kind's failed read returns a `bad` word, the existing vocabulary, as row 307 settles. It does not invent a new answer kind for the caller's `case`.
- `--no-textconv` changes no output contract (fact-check verified the same commits are found).
- The `--status` output grammar is unchanged: no new fields, no new line kinds.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Failed-read `bad` printed under a "starts "handoff:"" prefix; help omits it | Minor | `scripts/build-loop.sh:281-283, 343, 68-73` | High |
| F2 | `open_shared` memo not keyed to MAIN_SHA and caches `error`, unlike `main_imports`/`import_home` | Minor | `scripts/lib/dev-cycle-read.sh:457-481` | Medium |
| F3 | Header caller contract omits `open_shared`/`OPEN_SHARED`; "caller's shell" reason differs | Minor | `scripts/lib/dev-cycle-read.sh:1-33, 457-466` | High |
| F4 | `--status` help line at 120 columns; "or" mid-list | Minor | `scripts/build-loop.sh:69-73` | High |
| F5 | `--check-branch` help names log.* as the only cause | Informational | `scripts/dev-cycle.sh:48-49` | High |
| F6 | `anybrief` has no `is` prefix (settled, row 323) | Informational | `scripts/lib/dev-cycle-read.sh:201` | High |

## Overall Assessment

The unit is consistent with the lib's API conventions. The new names follow the function/global pairing and the `error` sentinel. The new skip reason keeps the one-line `skip ARG: WHY` contract, and no output grammar changes for `--status` or `--check-branch` consumers. Nothing is Breaking or Inconsistent. The four Minor findings are wording and documentation. F1 can mislead a user about why a brief was skipped. F2 is a latent divergence from the lib's input-keyed memo convention, safe for today's callers, which call resolve_main once. Each can be fixed in place in a line or two.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: ae08688c` line at the top.
- Answered: yes
- Out of scope: the plan's stale :281 bullet (fact-check's finding; not an API surface); `--check` (U2b1a2), except to confirm how it calls open_shared
- Escalate: nothing
