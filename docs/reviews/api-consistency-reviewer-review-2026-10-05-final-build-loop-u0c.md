Commit: d8da1fba

# API Consistency Review — feat/build-loop-u0c, final confirming pass

**Scope:** `git diff feat/build-loop-u0b..feat/build-loop-u0c` (41065ce6, 1c7373d3, d8da1fba), including the plan amendment in docs/working/plan-build-loop-handoff.md, and their commit messages. Consumers: dev-cycle.sh's `--check-fix` and `--check-answer` now; build-loop.sh's `--status`, `check_answer` on main's commit (U1) and the floor (U2) later.
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0c.md (merged k=3, Commit d8da1fba); override-log rows dated 2026-10-05 for feat/build-loop-u0c (202-207, 210)

Known items from the fact-check report are not re-filed here:
- the header's exiting list omits check_answer (Claim 1);
- "F11's row below" (Claim 2);
- the worktree at MAIN_SHA lacks "no untracked instruction files" (Claim 3);
- the rollback line (Claim 4);
- commit 1c7373d3 (Claim 5).

Rows 203 (`isimported`) and 206 (check_answer reads the working tree) are settled deferrals.

## Baseline Conventions

- The U0a and U0b baselines still hold.
- Functions that compute lib state set globals and return a status. In U0b's naming, that is `resolve_main`, a verb plus a noun, which sets `MAIN`, `MAIN_SHA` and `MAIN_BY_NAME`.
- The header names each exiting function by its identifier: "inrepo, dirok, skipped, check_brief …" (`:12`).
- Check functions print one answer line per argument and return 0.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `imported_names` (moved into the lib's public surface) | function (fills a global) | `resolve_main` (fills `MAIN*`), `skipped` (fills `SKIP_AT`/`SKIPPED`) | `scripts/lib/dev-cycle-read.sh:305,113` | Inconsistent shape. It is a noun phrase for a side-effecting call, and the header calls it "the import walk" (Finding 2) |
| `check_answer`, `ANSWER_AWK` | moved | `check_brief`, `check_branch`, `FENCE_AWK` | `scripts/lib/dev-cycle-read.sh:239,286,173` | Consistent: names unchanged by the move |
| `lower` | moved helper | `red`, `bold`; `oddwhy` | `scripts/lib/log-format.sh:6-14`, `scripts/lib/dev-cycle-read.sh:217` | Consistent with the short unprefixed lib style. dev-cycle.sh's `check_fix` still lowercases with its own inline `tr` (`scripts/dev-cycle.sh:172`), as it did on main. That duplication predates the move and is not filed |
| `INSTRUCTION_FILE`, `IMPORT_RE`, `IMPORTED`, `IMPORTED_DONE` (now the root path) | globals | `FENCE_AWK`, `NAMECHARS`, `SKIP_AT` | `scripts/lib/dev-cycle-read.sh:173,127,94` | Consistent: UPPER_SNAKE and initialised when the lib is sourced. No caller outside the lib reads `IMPORTED_DONE` |

## Findings

#### 1. check_answer appends to the lib's `SKIPPED` on each blocked call; check_brief does not

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:457-476` (the `skipped` call at `:461`)
**Move:** #7 asymmetry; #3 consumer contract
**Confidence:** High
**Legibility-target:** for-author

Evidence (at d8da1fba):
```
    if skipped "$f"; then echo "skip $a: $SKIP_AT is not a plain file or directory, so $f is not read"; return; fi
```
In a repo where `docs/working` is a symlink, two calls to `check_answer` under `set -euo pipefail` print their skip lines and leave `SKIPPED` holding `[docs/working/] [docs/working/]` (it was empty before). That is one entry per call (probe run in this pass).

`check_brief` detects the same kind of block with `blocker` directly (`:247`) and leaves `SKIPPED` alone. The two check functions now share one lib, but only one of them writes the digest's section-8 accumulator. On main this was invisible, because check mode never printed section 8. For a caller that both answers questions and reports what it skipped, it matters. Row 206 moves check_answer to main's commit in U1, which may remove the `skipped` call altogether, so this should be settled there.

**Recommendation:** When U1 rewrites check_answer, use `blocker` as check_brief does, or document that the function appends to `SKIPPED`. Either choice also discharges U0a's Finding 1 for this function.

#### 2. The walk's function is named like a value, and the header names it only as "the import walk"

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:12-14`, `:347`
**Move:** #2 naming against the grain
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: verb-plus-noun for a function that fills lib globals (`resolve_main`), and functions named by identifier in the header's contract, used in `scripts/lib/dev-cycle-read.sh:305` and `:12-13`

Evidence (at d8da1fba):
```
# calling any file check. inrepo, dirok, skipped, check_brief and the import
# walk exit 1 (need_root) when ROOT_REAL is unset or is not the current
```
```
imported_names() {
```
`imported_names` prints nothing and returns no data. It fills `IMPORTED` and `IMPORTED_DONE`, the same shape as `resolve_main`, but its name reads like a getter. A consumer who reads the header's list of exiting functions and greps it for an identifier will find every name except this one. The name predates the move (it is dev-cycle.sh's on main), and the move kept it, which is right for a pure move. Severity stays at Informational because nothing in this unit can break a consumer.

**Recommendation:** Name `imported_names` in the header now: "… check_brief and the import walk (imported_names) …". When U2 adds `isimported` (row 203), consider a verb name such as `walk_imports` for the filler, so the pair reads as command and query.

#### 3. The plan's Approach list still says U0 extracts `brief_fields`

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:183-190`
**Move:** #3 consumer contract (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence (at d8da1fba):
```
U0 extracts dev-cycle.sh's reader into `scripts/lib/dev-cycle-read.sh`, as revision 2 described:
```
```
- `brief_fields`.
```
The amendment rewrote the item at `:187` of this list to say what U0 does not extract. The `brief_fields` item three lines below still lists a function that U0 does not provide: it does not exist on main, and step 3 (`:270`) builds it in U1. The Approach list is the lib's interface specification for build-loop.sh. A U1 author who checks the lib against it will look for `brief_fields` and not find it. The code-fact-check r3 replicate noted this line as pre-existing plan text and did not verdict it. It is filed here because the amendment edited the same list.

**Recommendation:** Mark the item "(written in U1, step 3)" in the same way the `:187` item carries its own note.

## What Looks Good

- **dev-cycle.sh's CLI, `--help` and exit codes match main apart from U0a's documented Exit line.** I ran the same 13 invocations against the same checkout with this tip's copy. They covered `--check-fix README.md AGENTS.md docs/x.md skills/code-review/SKILL.md` and `--check-answer Q-001 Q-999 nope`, and stdout, stderr and exit codes were identical. In a `trunk` repo with no main or master, `--check-answer` and the digest match main too. `route: code-fact-check`
- **`--check-fix` and `--check-answer` stay dev-cycle.sh flags.** Both now find their predicates through the lib. This matches the plan's "dev-cycle.sh keeps its flag" (`:221`), and the CLI flag set is unchanged.
- **The walk is safe to call from a second caller.** `need_root` is its first statement, outside any substitution. The cache is keyed on `ROOT_REAL`, so a different root recomputes it and resets `IMPORTED`. The header's "Inputs:" sentence (`:19-22`) states which functions read main's commit and which read the working tree. That is the contract fact build-loop.sh most needs.
- **The amendment is consistent with the interface.** It keeps check_fix's allowlist in dev-cycle.sh and assigns the floor, `isimported` and the MAIN_SHA precondition to U2. So the lib's public surface after U0 is exactly what is moved, and no half-split predicate is left behind.
- bats at this tip: 59/59 ok, run in this pass.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | check_answer appends to `SKIPPED`; check_brief does not | Informational | `scripts/lib/dev-cycle-read.sh:457-476` | High |
| 2 | `imported_names` is named like a value and is not named in the header | Informational | `scripts/lib/dev-cycle-read.sh:12-14,347` | Medium |
| 3 | Plan's Approach list still lists `brief_fields` as part of U0 | Informational | `docs/working/plan-build-loop-handoff.md:190` | High |

## Overall Assessment

U0c completes the extraction consistently. Every name moved verbatim. dev-cycle.sh's flags, help text and exit codes match main apart from U0a's documented Exit line. The walk's new guard and per-root cache make it safe for a second caller. All three findings are Informational and concern how build-loop.sh's author will read the contract: a side effect on `SKIPPED`, a function name missing from the header's list, and one stale plan line. Each is a small in-place edit, and each fits naturally in U1 or U2, which already own the related deferrals (rows 203 and 206). Nothing blocks the land.

## Goal-Alignment Note

The goal is to finish U0 with dev-cycle.sh unchanged and with a lib that build-loop.sh can call directly. The probes and 59/59 bats confirm the first part. The second part holds for the functions that have moved, and the plan amendment explicitly hands the remaining gaps (the floor, `isimported`, the commit-reading walk) to U2. The findings here keep the next consumer from misreading what the lib does. None of them asks for scope beyond U0, and none of the settled rows 202-207 or 210 became worse.
