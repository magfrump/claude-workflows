Commit: 5c57d367

# API Consistency Review — feat/build-loop-u2a3 (loop 2, iteration 1, after the split)

**Scope:** `git diff main...HEAD` on `feat/build-loop-u2a3` (base main 62d366a7): the public surface of `scripts/lib/dev-cycle-read.sh` (`main_imports`, `isimported main`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`, the lib header contract), with the doc copies in A5, F11 and the plan bullets
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3-L2.md` (summary `factcheck-summary-L2i1.md`); this critic's earlier passes on this branch (`api-consistency-reviewer-review-2026-10-06-build-loop-u2a3.md`, `...-final-build-loop-u2a3.md`)

## Baseline Conventions

- **Readers of main's commit are named `main_*`** (`main_by_name` :253, `main_entry` :269) and read through `git cat-file`/`ls-tree` at `$MAIN_SHA`. They need `resolve_main` first and refuse when main is not found by name.
- **Working-tree readers** (`imported_names` :518, `inrepo`, `dirok`) exit through `need_root`. The header (:12-35) is the one place that lists each function's inputs and precondition. It is the contract later units read.
- **Failure state lives in a global that holds a sentinel**: `BRIEF_ODD=error`, `IMPORTED_MAIN=error`. Predicates answer the refusing value on failure, so `if` in the caller refuses. `isimported`'s `*)` arm already answers imported.
- **Result globals come in pairs, with a cache key**: `IMPORTED`/`IMPORTED_DONE` (key: root) and now `IMPORTED_MAIN`/`IMPORTED_MAIN_DONE` (key: commit, by-name flag, root). Lists are newline-framed and lower-cased.
- **Small listing helpers are noun phrases with a one-line usage comment**: `lower`, `instruction_names`, `untracked_md`. Nameref helpers use a prefixed local (`local -n`; precedent `scripts/lib/si-morning-summary.sh`).
- **Every lib function and global is listed in `test/scripts/dev-cycle.bats`'s sourcing inventory** (:1083-1090). That test is the lib's public-surface manifest.
- **Gaps are listed in three copies**: the lib's block comment, known issue A5 and plan row F11. Override rows record that the three copies are meant to agree (architecture F4-F6 Won't-Fix).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_imports` | function | `main_entry`, `main_by_name`, `imported_names` | `scripts/lib/dev-cycle-read.sh:253,269,518` | Consistent: joins the `main_*` family of commit readers. Its pairing with `imported_names` is a noun-order asymmetry, accepted in earlier passes and not re-filed |
| `isimported main` | subcommand word | `isimported tree`, the `*)` arm | `scripts/lib/dev-cycle-read.sh:615-624` | Consistent: same predicate shape and same refusing answer on failure as `*)` |
| `nul_list` | function | `untracked_md`, `instruction_names`, `lower` | `scripts/lib/dev-cycle-read.sh:482,512,515` | Consistent name. Its nameref style matches `scripts/lib/si-morning-summary.sh`. Missing from the inventory (finding 4) |
| `IMPORTED_MAIN` | global | `IMPORTED`, `BRIEF_ODD`, `MAIN_SHA` | `scripts/lib/dev-cycle-read.sh:252,474` | Consistent: `IMPORTED` plus a qualifier, with an `error` sentinel as in `BRIEF_ODD` |
| `IMPORTED_MAIN_DONE` | global | `IMPORTED_DONE`, `SKIP_AT` | `scripts/lib/dev-cycle-read.sh:109,474` | Consistent: same `_DONE` cache-key shape |
| `U2a3c` (plan unit) | doc name | `U2a3b`, `U2a4` | `docs/working/plan-build-loop-handoff.md:273-281` | Consistent with the stacked-unit lettering |

No naming findings.

## Status of earlier findings (this critic)

- **Final pass 1 (an untracked start can remove a refusal):** fixed by the split. An untracked start now fails the walk (:569), so the checkout can no longer turn a refusal into ok. The fact-check probed this against both the current lib and cc1aa864.
- **Final pass 2 (what `nul_list` leaves on failure):** fixed. It now empties the array (:517). One clause is still missing; see finding 3.
- **Final pass 3 (refusal-list copies):** mostly fixed. The block comment, return-1 comment, A5, F11 and the U2a3 bullet now agree on "anything but a plain directory". The header and the not-covered list have drifted again; see findings 1 and 2.
- **Iteration 2, finding 1 (no reason word):** deferred to U2a4 by an override row. Not re-filed, but finding 5 adds evidence for that row's trigger.

## Findings

#### 1. The interim refusal fires in this repo's own primary checkout: 35 ignored instruction files make `isimported main` answer imported for every path

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:32-34` (header), `:462-465` (block comment), `:569` (the untracked-start refusal), `:513-515` (`untracked_md` includes ignored files); `docs/working/known-issues-dev-cycle.md:18` (A5); `docs/working/plan-build-loop-handoff.md:126` (F11)
**Move:** 3 (consumer contract), 6 (behaviour change between units)
**Confidence:** High (executed)
**Legibility-target:** the authors of U2a4 (the floor) and U2b (which names the checkout `--check` runs in), and whoever reads 2b22a082 as the reason the interim is harmless

Evidence. I sourced the worktree's lib, ran `resolve_main`, then `main_imports` and `isimported main scripts/lib/dev-cycle-read.sh`, in two checkouts (scratch `/tmp/u2a3-api2-i1-bS94`; read-only git calls):
```
/workspace (primary checkout):           walk FAILED (error)   lib: imported
/workspace/.claude/wt-build-loop-u2a3:   walk ok: 3 entries    lib: -
```
`git -C /workspace ls-files --others` lists 35 instruction-shaped `.md` files, for example `devcontainer-config/claude-home/CLAUDE.md` and `devcontainer-config/claude-home/skills/*/SKILL.md`, and `check-ignore` reports them as ignored. `untracked_md` (:513-515) lists ignored files on purpose. The lib's own tree walk says why (:446-447: "CLAUDE.local.md is usually gitignored"). The interim refusal at :569 therefore covers every ignored `CLAUDE.local.md` and `SKILL.md` as well.

The contract text says "an untracked start file". That is correct by the lib's own usage, but a reader using git's meaning (untracked excludes ignored) will not expect it to fire on ignored files. Commit 2b22a082's rationale ("The gate worktree D13 creates is clean at MAIN_SHA, so the refusal should not fire there") is the only place that addresses how often the refusal fires, and the fact-check marks it Mostly accurate: D13's worktree is the orchestrator's, and F11 leaves the gate's checkout to U2b. The direction is safe: the gate refuses. The consumer consequence is that between U2a3 and U2a3c, a floor built on this walk refuses every path from any checkout holding a local `CLAUDE.local.md` or ignored skills, and that includes this repo's primary checkout today. U2a4 cannot be exercised end to end there. If U2b picks the primary checkout, the self-merge gate is closed until U2a3c lands.

This does not block U2a3c from extending the contract, because it only turns some refusals into walks (see What Looks Good). It is a sequencing fact that later units should not have to rediscover.

**Recommendation:** Add "(ignored ones included, such as CLAUDE.local.md)" after "an untracked start file" in the header (:33) and in A5. In F11 or the U2b bullet, add one sentence: until U2a3c, any checkout holding an ignored instruction file fails the walk, so U2b's checkout (or U2a4's tests) must be a fresh worktree. Record 2b22a082's D13 sentence in an override row, as the fact-check already suggests.

#### 2. The header contract says "anything at an imported path main lacks" fails the walk; the code and every other copy allow a plain directory

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:32-34`; compare `:460-462`, `:544-545`, A5 (`known-issues-dev-cycle.md:18`), F11 (`plan-build-loop-handoff.md:126`), U2a3 bullet (`:276`)
**Move:** 3 (documentation drift in the contract)
**Confidence:** High (fact-check summary item 3, and confirmed by reading the plain-directory arm at :606)
**Legibility-target:** the U2a3c author, who extends the header sentence, and the U2a4 author, who reasons from it

Evidence, header (:32-34):
```
# writes), and so does main_imports (it reads the checkout only to fail: an
# untracked start file, or anything at an imported path main lacks, fails it
# until U2a3c walks them; it needs resolve_main to have found main by name);
```
The code (`[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || fail`) lets a plain directory below the root pass. The other five copies say "anything but a plain directory". The header also leaves out the link-text loop's checkout `-L` probe. That probe only makes the walk stricter, so "reads the checkout only to fail" still holds. The header is the copy that the other units cite as the contract, and it is now the only one that is stricter than the code. A U2a3c author who extends it ("...walks them") would carry the error forward.

**Recommendation:** Change "anything at" to "anything but a plain directory at" (:33). Optionally add "or whether link text passes through a checkout symlink" to the inputs.

#### 3. `nul_list`'s usage line omits its second refusal: output not ending in NUL

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:516-517`
**Move:** 3 (consumer contract), 8 (what the result holds)
**Confidence:** High (fact-check summary item 3; the `${nl_a[-1]} == rc=0` test merges a final unterminated record with the sentinel)
**Legibility-target:** the U2a3b author, who reuses `nul_list` (the plan names it as shared)

Evidence (whole unit):
```
# nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0.
nul_list() { local -n nl_a="$1"; shift; mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'; }
```
A command that exits 0 but whose last record lacks a NUL also returns 1. This is what "listed whole" means in the return-1 comment (:538), and it is a good property. A caller that passes a non-`-z` command (such as `git ls-files` without `-z`, or a `printf '%s'` producer) will always see a refusal. The usage line does not warn about that.

**Recommendation:** Change the usage line to "...or is emptied and 1 unless CMD exited 0 and its output ends in a NUL (each record NUL-terminated)."

#### 4. The not-covered list has drifted across its three copies again: A5 names a fourth gap the lib comment and F11 omit

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:466-469`, `docs/working/plan-build-loop-handoff.md:126` (F11 "Gaps"), against `docs/working/known-issues-dev-cycle.md:18` (A5)
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claims 7 and 24, probe P1: walk ok, `sub/x.md` answers `-`)
**Legibility-target:** whoever relies on the override row (architecture F4-F6, Won't-Fix) that says the copies agree

A5 lists "an instruction file the checkout tracks but main lacks (not a start)". The lib's "Not covered" and F11's "Gaps" stop at the untraced shapes. The behaviour is unchanged from before the split, and only the copies differ. A U2a4 or U2a3c author who reads the lib comment alone will not learn that a branch-added `CLAUDE.md` is not a start. (U2a4's floor names start files by its own rules, :466, which may cover this. That is a design question for U2a4, not this unit.)

**Recommendation:** Add the clause to the lib comment and to F11, or have both point to A5 as the full list.

#### 5. The sourcing inventory omits `nul_list`

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:1084-1086`
**Move:** 3 (test drift)
**Confidence:** High (read; fact-check summary item 3)
**Legibility-target:** the U2a3b author, whose reuse makes `nul_list` shared surface

The inventory lists every lib function, including small helpers (`lower`, `untracked_md`, `instruction_names`), and this diff added `main_imports`, `IMPORTED_MAIN` and `IMPORTED_MAIN_DONE` to it. It did not add `nul_list`, which the plan names as reused by U2a3b. If `nul_list` were missing, the walk tests would still fail, so nothing goes unpinned. The gap is only in the manifest's completeness.

**Recommendation:** Add `nul_list` to the function loop at :1086.

## What Looks Good

- **U2a3c can extend the interim contract without breaking callers.** The return shape (0 or 1, `IMPORTED_MAIN` as either `error` or a newline-framed lower-cased list) does not need to change for a second phase that only appends. Every interim refusal that U2a3c removes turns a failure into a walk, which loosens the contract and never tightens it for a caller that refuses on failure. `isimported main` already maps failure to "imported", as `*)` does. Both tests that pin the interim refusals say so in their names ("...fails it until U2a3c", build-loop-check.bats :46, :223), so U2a3c's test diff is expected. The comment at :569 marks the one line U2a3c replaces.
- **The fail-closed direction holds.** The fact-check probed it against the current lib and cc1aa864: every checkout read leads only to return 1, and every `return 1` after `IMPORTED_MAIN=$'\n'` resets to `error` (all pinned). My own run in the primary checkout (finding 1) is a live instance of the refusal answering imported.
- **Nothing main alone would catch is lost.** A path main lacks was never read from main before the split. The only thing the split removed is walking checkout content, which now fails instead.
- **`nul_list` is a sound shared helper.** It empties the array on failure (the final pass's finding 2 is fixed) and refuses a listing that does not end in NUL.
- **The naming fits the lib's families** (`main_*`, `IMPORTED*`/`_DONE`, noun-phrase helpers). The cache contract, including the `IMPORTED_MAIN_DONE=""` reset, is stated in one place (:470-472).
- **No existing consumer changes.** `check_fix` still calls `isimported tree`, and `isimported main` has no caller before U2a4.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Interim untracked-start refusal includes ignored files, so it fires in this repo's primary checkout (35 ignored instruction files; walk fails, every path "imported"); 2b22a082's "should not fire" premise is not stated in the contract | Minor | `scripts/lib/dev-cycle-read.sh:32-34, 462-465, 513-515, 569`; A5; F11 | High |
| 2 | Header says "anything at" a path main lacks fails; code and the five other copies allow a plain directory | Minor | `scripts/lib/dev-cycle-read.sh:32-34` | High |
| 3 | `nul_list` usage line omits the refusal of output not ending in NUL | Informational | `scripts/lib/dev-cycle-read.sh:516-517` | High |
| 4 | Not-covered list: A5's "tracked in the checkout but not on main" gap is missing from the lib comment and F11 | Informational | `scripts/lib/dev-cycle-read.sh:466-469`; F11 | High |
| 5 | Sourcing inventory omits `nul_list` | Informational | `test/scripts/dev-cycle.bats:1086` | High |

## Overall Assessment

The public surface is consistent with the lib's conventions, and the split resolved the one contract break from the previous loop (an untracked start could remove a refusal). The interim fail-closed contract is one U2a3c can extend without breaking callers: the return shape stays the same, U2a3c only removes refusals, and the tests that pin the interim behaviour are labelled as interim. Everything left is wording. The one finding with a consequence beyond this unit is finding 1: the interim refusal is not rare. Because ignored instruction files count, it fires in this repo's own primary checkout today. U2a4 and U2b should be told so in A5 and F11, not left to find it out. All five fixes are one-phrase or one-line edits.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-06-L2-build-loop-u2a3.md, structured per the api-consistency-reviewer skill."
- **Answered:** The public surface is consistent with the lib's conventions (no naming findings). The interim fail-closed contract is extendable by U2a3c without breaking callers (What Looks Good, first bullet). Nothing main alone would catch is now missed. Two Minor contract-wording findings (1, 2) and three Informational ones (3-5).
- **Out of scope:** behaviours U2a3b changes (`import_targets`, failing sed/grep/lower); settled override rows (cache ignoring the checkout, no reason word, the unsearchable checkout directory, the D13 claim beyond noting it); the `@.git` linked-worktree case (fact-check P3, which fails closed, so a security or U2b concern, not a consistency one).
- **Escalate:** (a) U2b's author: the gate's checkout must hold no ignored or untracked instruction files until U2a3c (finding 1, executed in `/workspace`). This joins the fact-check's D13 override-row candidate. (b) The deferred `IMPORTED_MAIN_WHY` row (U2a4 trigger): the commonest interim failure on a developer checkout will be an ignored start file, which a reason word would make actionable. (c) The author: the one-phrase fixes in findings 2-5.
