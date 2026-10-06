Commit: 7f295cdb

# API Consistency Review — feat/build-loop-u2a2 (iteration 2, full branch)

**Scope:** `git diff main...HEAD` (main 20347279, HEAD 7f295cdb): the lib's function contract (`scripts/lib/dev-cycle-read.sh`), `--check-fix` in `scripts/dev-cycle.sh`, and the test-helper conventions across `test/scripts/build-loop-*.bats`
**Date:** 2026-10-06
**Based on:** `/home/node/.claude/jobs/814a541d/tmp/rv/fc-summary.md` (iteration 1 report `docs/reviews/code-fact-check-report-build-loop-u2a2.md`, iteration 2 report `-i2.md`); U2a3's consumer shape read from `feat/build-loop-u2a2-full` 6c41aea2 (context only)

## Baseline Conventions

Read: the lib header (`dev-cycle-read.sh:1-33`), `need_root`/`rawfile`/`plaindir`/`blocker`/`inrepo`/`dirok`/`skipped` (:87-129), `isbrief`/`isclosed` (:161-162), `main_by_name`/`main_entry`/`entry_why` (:251-311), `resolve_main` (:414-440), `imported_names` (:498-514), `main_imports` (:516-587), `isimported` (:588-603); `check_fix` (`dev-cycle.sh:165-184`) and its help text (:50-55); `build-loop-read.bats`, `build-loop-check.bats`, `test/lib/build-loop-fixtures.bash`; U2a3's `floor` (6c41aea2 lib :605-630).

- **Exit vs return.** Checks that need the root exit 1 through `need_root` (listed in the header); everything else answers through its return code or one printed word. A function that cannot read what it needs fails closed: `rawfile`/`plaindir` read nothing as plain while `ROOT_REAL` is unset; `main_entry` answers `error`; `check_*` skip every argument unless `main_by_name`.
- **Initial state fails closed.** `MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""` at source time (:250) make every main-reading check refuse until `resolve_main` succeeds.
- **Names.** `is*` predicates return 0/1 (`isbrief`, `isclosed`); `main_*` reads main's commit (`main_by_name`, `main_entry`); globals are UPPER_SNAKE (`FENCE_AWK`, `IMPORT_RE`, `INSTRUCTION_FILE`) with a `*_DONE` cache key beside a cached result (`IMPORTED`/`IMPORTED_DONE`).
- **Argument order.** Mixed: path first with an optional mode word second (`blocker`, `skipped`, `pathform`), but `entry_why` takes the word first and the path second.
- **Unknown mode words.** `blocker` treats any word but `dir` as `file` (the stricter read); `skipped` defaults to `file`.
- **Tests.** `bl_setup` + `commit_all` fixtures; tests named by plan ID (`(T1)`) or by unit (`(U1d)`, `(U2a1)`); each file defines small local assertion helpers (`settings_is`, `line`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_imports` | function | `main_entry`, `main_by_name`, `imported_names` | `scripts/lib/dev-cycle-read.sh:251,267,498` | Consistent with the `main_*` prefix; the asymmetry with `imported_names` is settled (override row `feat/build-loop-u2a`, "Walk names ... do not mirror each other") |
| `isimported tree\|main` | function | `isbrief`, `isclosed` | `dev-cycle-read.sh:161-162` | Consistent `is*` predicate; mode-word-first order matches `entry_why` but not `blocker`/`skipped` (Informational I-2) |
| `inrepo_here` | function | `inrepo`, `rawfile`, `dirok` | `dev-cycle-read.sh:98,123,128` | New `_here` suffix meaning "caller already ran need_root"; documented at its definition (:124) and not in the header list. Acceptable |
| `import_targets` | function | `instruction_names`, `brief_fields`, `oddwhy` | `dev-cycle-read.sh:235,316,494` | Consistent noun-phrase reader name |
| `instruction_names` | function | `imported_names` | `dev-cycle-read.sh:498` | Consistent (`*_names` returns a name list) |
| `untracked_md` | function | none closer than `instruction_names` | none — searched function names in `scripts/lib/dev-cycle-read.sh` | New, plain and private-feeling; fine |
| `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE` | global | `IMPORTED`, `IMPORTED_DONE` | `dev-cycle-read.sh:468` | Consistent result/cache-key pair; the initial value is not fail-closed (Finding 2) |
| `UNI_SPACES` | global (array) | `IMPORT_RE`, `INSTRUCTION_FILE`, `FENCE_AWK` | `dev-cycle-read.sh:440,470` | Consistent UPPER_SNAKE constant; the only array constant (the source test's `${!v}` checks its first element, which suffices) |
| `imps`, `want` | test helper | `settings_is`, `settings_like`, `line` | `test/lib/build-loop-fixtures.bash:40-45` | Consistent local-helper style; `want walk ok` reuses the `PATH: WORD` shape for the walk line, readable |

## Findings

#### 1. main_imports neither returns 1 nor fails closed when a checkout file it would read is unreadable: under `if` the walk says ok and drops that file's imports

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:561` (contract at :516-526, :588-593)
**Move:** 4 (error consistency), 7 (asymmetry)
**Confidence:** High (executed)

Evidence (the `t:` branch; the `m:` branch beside it guards its read):
```
      if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")"
...
        100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | import_targets "$d")" || { IMPORTED_MAIN=error; return 1; } ;;
```
The header contract says the walk "returns 1, with IMPORTED_MAIN set to "error", when ... a blob cannot be read ... so a caller refuses rather than reading a partial list", and `isimported` promises "A failed main walk ... answers imported". The checkout read has no `|| { IMPORTED_MAIN=error; return 1; }`, so its failure takes the errexit path instead: a plain call exits the caller (not the lib's return convention), and a call under `if`/`elif` (errexit suppressed) continues with `out=""`. Probe in a scratch repo, untracked `CLAUDE.local.md` holding `@docs/secret.md`, mode 000:
```
.../dev-cycle-read.sh: line 561: CLAUDE.local.md: Permission denied
walk ok
-                       # isimported main docs/secret.md
---
(plain `main_imports;`) rc=1, "after plain" never printed
```
U2a3's floor calls exactly the `if` form (`elif ! main_imports; then FLOOR_WHY=...`, 6c41aea2 lib :624), so the consumer this unit exists for gets a partial list with a success code. Practical exposure is small (Claude Code running as the same user cannot read the file either, so its imports also do not load until the mode changes back), which is why this is Inconsistent and not higher; but it is the one read in the walk whose failure is not mapped to the documented return, and fact-check iteration 2 recorded it only as informational E2.

**Recommendation:** Guard the read like its `m:` sibling: `out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }` (the redirect failure then makes the substitution fail), and add an unreadable-untracked-start case to the A2 test in `build-loop-check.bats` asserting `walk failed` under `if`.

#### 2. IMPORTED_MAIN starts as a successful empty walk, unlike the lib's fail-closed initial state

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:468`
**Move:** 8 (nullability / absent-state contract)
**Confidence:** High

Evidence: `IMPORTED=$'\n'; IMPORTED_DONE=""; IMPORTED_MAIN=$'\n'; IMPORTED_MAIN_DONE=""`. The sentinel for failure is `error`, but the never-walked state is `$'\n'`, which reads as "walked, nothing imported". A caller that reads the global (it is listed among the lib's globals and the source test asserts it is declared) without calling `main_imports` first answers every path "not imported". The lib's own baseline is the opposite: `MAIN_SHA=""`/`MAIN_BY_NAME=""` at :250 make every main reader refuse until `resolve_main` succeeds, and the walk itself sets `IMPORTED_MAIN=error` before doing anything (:531). `isimported` is safe because it always calls the walk; the exposure is only to a direct reader such as a future U2b/U2c helper.

**Recommendation:** Initialise `IMPORTED_MAIN=error` at :468 (the cache key `""` never matches, so the first call still walks), or state in the header that `IMPORTED_MAIN` is meaningful only after `main_imports` returned 0.

#### 3. The token rules' documentation stayed with the tree walk after the parser became shared

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:441-451`, `:476-477`; `scripts/dev-cycle.sh:50-55`
**Move:** 3 (documentation drift)
**Confidence:** High

Evidence: the tree block still describes the token as ending "at a blank, \, #, a backtick, ( ) [ or ]", while `import_targets` (:476 "The import targets in the text on stdin, for a file in directory $1") now also ends it at the `UNI_SPACES` characters, follows `..x` names (`[[ "$p" != .. && "$p" != ../* ]]`, previously `..*` dropped), and reads NUL-holding text (`grep -a`). These change `--check-fix` answers in the refusing direction (a `@docs/nb.md` followed by U+00A0 is now `skip`, previously `ok`), which is backward-compatible for a fail-closed gate, but the authoritative description of the shared rule is split between the tree block and the `UNI_SPACES` comment, and `import_targets` (now the one parser both walks use) states none of it. The new behaviour is tested only through `isimported tree` (`build-loop-check.bats` "tree walk shares the token rules"), not through `--check-fix` output.

**Recommendation:** Move the token-rule sentence to `import_targets`' comment (adding the Unicode-space, `..x` and NUL clauses) and have the tree block point to it; optionally one `--check-fix` case in `dev-cycle.bats` pinning the U+00A0 refusal at the CLI.

#### 4. The A5 "not covered" wording understates the gap (carried from fact-check iteration 2, E1)

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:463-466`; `docs/working/known-issues-dev-cycle.md:18`; `docs/working/plan-build-loop-handoff.md:126`
**Move:** 3 (documentation drift)
**Confidence:** High (per fact-check Claims 2b, 9, 10; not re-verified)

The three contract descriptions list "a directory main stores as a symlink when the checkout lacks that link" as the uncovered case, but start files under a symlinked directory that is present (main's `.claude/rules` as a link to a real directory; an untracked symlinked directory holding an instruction file) also give walk ok with imports answering `-`, because start discovery uses only names `ls-tree -r` / `ls-files --others` list. The gap itself is settled under the `feat/build-loop-u2a` A5 row; this is only that the consumer-facing description of what `isimported main` covers now says less than the truth.

**Recommendation:** Widen the "Not covered" sentence in all three places to "paths through a symlinked directory (a start file under one, or an import through one the checkout lacks)".

#### I-1. An unknown walk word answers imported silently

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:601`
**Move:** 4
**Confidence:** High

`*) return 0 ;;` fails closed, as documented, and is tested (`isimported bogus`). It differs from `blocker`, where any word but `dir` means `file` (the stricter read) — both are fail-closed, so no change is needed; a typo in a caller (`isimported Main`) would make `--check-fix` skip every path with the import reason, which is visible, not silent harm.

#### I-2. isimported puts the mode word before the path

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:594-602`
**Move:** 2 (parameter order)
**Confidence:** Medium

Precedent: mode word first, path second used in `scripts/lib/dev-cycle-read.sh:291` (`entry_why "$w" "$path"`); path first, mode second used in `scripts/lib/dev-cycle-read.sh:109,129,144` (`blocker`, `skipped`, `pathform`).

The lib has both orders; `isimported`'s required word fits `entry_why`'s shape, and the optional-word functions put the path first. No change recommended; noted so U2a3's `floor PATH ...` and any later `is*` helper pick deliberately.

## What Looks Good

- `isimported tree|main` is one public predicate over both walks, with the documented "run main_imports first to word a failure" rule; U2a3's floor uses exactly that sequence, so the contract fits its intended consumer.
- `main_imports`' return-1 paths after 7f295cdb set `IMPORTED_MAIN=error` explicitly on every guarded branch, and the listing reads use `cmd && printf rc=0 || printf rc=1`, so listing failures return instead of exiting (test "returns, not exits").
- The cache key `"$MAIN_SHA $ROOT_REAL"` mirrors `IMPORTED_DONE`'s per-root key and correctly recomputes after a new `resolve_main`; a cached failure keeps returning 1.
- The header's need_root list and Inputs paragraph were updated with the new functions; `inrepo_here` documents why it skips `need_root`.
- `--check-fix`'s output lines are byte-for-byte unchanged; only its refusal set grew (fail-closed direction), so existing consumers' parsing still works.
- `build-loop-check.bats` follows `build-loop-read.bats`' fixture and naming conventions (`bl_setup`, `commit_all`, `@category fast`, unit tags), and `dev-cycle.bats`' source test lists every new function and global.
- `fixture-git-env.bats` now unsets `--local-env-vars` in its own setup and compares the victim's index byte for byte (carried row C12).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Unreadable checkout file: plain call exits, `if` call reports ok with imports dropped | Inconsistent | `scripts/lib/dev-cycle-read.sh:561` | High |
| 2 | `IMPORTED_MAIN` initial value reads as a successful empty walk | Minor | `scripts/lib/dev-cycle-read.sh:468` | High |
| 3 | Shared token rules documented on the tree walk, not on `import_targets`; no CLI test | Minor | `scripts/lib/dev-cycle-read.sh:441-451,476` | High |
| 4 | A5 "not covered" understates the symlinked-directory gap (fact-check E1) | Minor | `dev-cycle-read.sh:463-466`; known-issues :18; plan :126 | High |
| I-1 | Unknown walk word answers imported | Informational | `scripts/lib/dev-cycle-read.sh:601` | High |
| I-2 | Mode-word-first argument order (mixed precedent) | Informational | `scripts/lib/dev-cycle-read.sh:594-602` | Medium |

## Overall Assessment

The new surface is consistent with the lib's conventions: `main_*` for main-reading, `is*` for predicates, a result/`*_DONE` cache pair, need_root exits listed in the header, and fail-closed answers through `isimported`. `--check-fix` keeps its output contract and only refuses more. The one real contract gap is Finding 1: the walk's checkout read is the only read whose failure is not mapped to the documented `return 1`/`error`, and under the `if` form U2a3's floor uses, it silently returns success with a partial list. It is a one-line fix in place, plus a test. Findings 2-4 are documentation and initial-state tidying; none blocks U2a3.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7f295cdb` as its first line."
- **Answered:** yes, saved at `docs/reviews/api-consistency-reviewer-review-2026-10-06-build-loop-u2a2.md`, line 1 `Commit: 7f295cdb`, skill sections in order.
- **Out of scope:** the settled override rows (walk-name asymmetry, A5 gaps themselves, per-blob cost, start-file rule in both walks, FLOOR_WHY wording) were not re-filed; Finding 4 is about the wording of A5's description, not the gap, and cites fact-check E1. The prior U2a loop's review artifacts were not reviewed.
- **Escalate:** Finding 1 is behavioural (fail-open under `if` for an unreadable checkout file), raised from fact-check's informational E2; the orchestrator may want the security critic's view on whether an autonomous loop can produce that shape usefully.
- **Probe cleanup:** one scratch repo under `/tmp/u2a2-api-P4Yo`, commands run under `timeout 20`; no processes left running; nothing written to the repo but this report.
