Commit: 5c57d367
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` at 5c57d367 (base main 62d366a7), loop 2 iteration 1: comments in `scripts/lib/dev-cycle-read.sh`, test names and comments in `test/scripts/build-loop-check.bats` and `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` A5, `docs/working/plan-build-loop-handoff.md` (F11, U2a3/U2a3c/U2b bullets), the rubric's split section and the three override rows added in 2b22a082, and the messages of 2b22a082 and 5c57d367 (earlier commits: pointers only)
**Checked:** 2026-10-06
**Replication:** k=1 (loop pass, decision 031)
**Role:** cfc2, pass i1 (scratch `/tmp/u2a3-cfc2-i1-3N4c`)
**Total claims checked:** 33
**Summary:** 20 verified, 11 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Execution provenance common to every `executed` claim (all runs in cwd `/workspace/.claude/wt-build-loop-u2a3` unless noted, TMPDIR=`/tmp/u2a3-cfc2-i1-3N4c`, timestamps UTC on 2026-10-07, which is 2026-10-06 local):

- E1 `TMPDIR=$S timeout 900 bats test/scripts/build-loop-check.bats` at 03:07:21Z, exit 0, 16/16 ok: `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`
- E2 `TMPDIR=$S timeout 1500 bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/build-loop-check.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` at 03:07:38Z, exit 0, 114 ok, 0 not ok: `/tmp/u2a3-cfc2-i1-3N4c/bats-five.txt`
- E3 mutants: `/tmp/u2a3-cfc2-i1-3N4c/mutate.sh NAME LINE SUBST` copies `scripts/` and `test/` to `$S/m-NAME/`, edits the copy's lib with perl, runs the copy's build-loop-check.bats (cwd `$S`), at 03:08:44Z (named six plus here-string) and 03:11:07Z (error resets, untracked newline). Diffs `$S/m-NAME.diff`, outputs `$S/m-NAME.out`. Results: untracked (exit 1: tests 3, 9, 11), probe (exit 1: 3, 9, 12), gitlink (exit 1: 12), parent1 (exit 1: 15), plaindir (exit 1: 9), split-none (exit 1: 15), split-herestring (exit 0, survives), reset578 (exit 1: 4, 14), reset583 (exit 1: 9), reset585 (exit 1: 7, 12), reset590 (exit 1: 15), reset595 (exit 1: 7), reset605 (exit 1: 12, 15), reset606 (exit 1: 3, 9, 12), untrnl (exit 0, survives).
- E4 probes: `$S/probes/run.sh` (probe repos under `$S/probes/`) at 03:09:52Z, exit 0: `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`; the same probes against `git show cc1aa864:scripts/lib/dev-cycle-read.sh` (`$S/probes/run-pre.sh`), exit 0: `/tmp/u2a3-cfc2-i1-3N4c/probes/out-pre.txt`
- E5 `git diff --numstat main...HEAD -- scripts test` (111+9, 266+2, 2+2): output captured in this report's Claim 21 quote
- E6 `TMPDIR=$S bash $S/perf.sh` ×3 at 03:11:56Z, exit 0: `/tmp/u2a3-cfc2-i1-3N4c/perf.txt`

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): the relevant suspect is the test-tally pattern ("All 85 tests ... but the suites hold 97", "mode1-equiv 33 ... holds 25"); Claim 19's tally was executed and matches.

---

## Claim 1: "inrepo, dirok, skipped, check_brief, isimported and the import walks exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:14-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main_imports' and isimported's first statements; does not establish anything about nul_list (which needs no root and makes no such claim).

`main_imports` declares its locals and then runs `need_root` before anything else (`scripts/lib/dev-cycle-read.sh:547-549`: `local - rec f d p i c lk out queue=() ...; set -o pipefail` / `local -A ent=() seen=()` / `need_root`), and `isimported` does the same (`:616-617`: `local lp` / `need_root`). `need_root` (`:94-98`) exits 1 on each of the three conditions.

**Evidence:** `scripts/lib/dev-cycle-read.sh:94-98`, `scripts/lib/dev-cycle-read.sh:546-549`, `scripts/lib/dev-cycle-read.sh:615-617`

---

## Claim 2: "and so does main_imports (it reads the checkout only to fail: an untracked start file, or anything at an imported path main lacks, fails it until U2a3c walks them; ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:32-34`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every checkout read in main_imports can only fail the walk; does not establish the header's enumeration, which is both too broad ("anything at" a missing path) and short (the checkout `-L` read in the link-text loop).

"Reads the checkout only to fail" holds: the three checkout reads are the untracked listing (`:561-570`, any start fails), the probe (`:606`) and `! -L "$p"` in the link-text loop (`:592`), and each can only end in `return 1`. Two imprecisions: (a) a plain directory at an imported path main lacks does not fail:

```bash
# scripts/lib/dev-cycle-read.sh:606
      [[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }
```

(test 9 at `test/scripts/build-loop-check.bats:191-192` asserts `walk ok` for `mkdir docs/lt.md`, and the plaindir mutant in E3 fails it), so "anything at" should read "anything but a plain directory at", as the block comment, A5 and the commit say; (b) a checkout symlink before a `..` in followed link text also fails the walk (`:592`, test 15's last case), which the parenthesis omits.

**Evidence:** `scripts/lib/dev-cycle-read.sh:32-34`, `scripts/lib/dev-cycle-read.sh:561-570`, `scripts/lib/dev-cycle-read.sh:588-593`, `scripts/lib/dev-cycle-read.sh:606`, `test/scripts/build-loop-check.bats:191-192`, `/tmp/u2a3-cfc2-i1-3N4c/m-plaindir.out`, `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`

---

## Claim 3: "it needs resolve_main to have found main by name"

**Location:** `scripts/lib/dev-cycle-read.sh:34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_by_name gate and its cache key; does not establish behavior when MAIN_SHA names a commit that is not main's tip (callers' concern).

`main_by_name || return 1` (`:552`) after the cache key is set to `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:551`); `main_by_name` is `[[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]` (`:253`). Test 4 (branch `main` deleted → `walk failed`) and test 16 (`MAIN_BY_NAME=""; w y.sh` → `y.sh`) pass in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:253`, `scripts/lib/dev-cycle-read.sh:550-552`, `test/scripts/build-loop-check.bats:63-79`, `test/scripts/build-loop-check.bats:300-309`, `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`

---

## Claim 4: "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth, which Claude Code also loads) and follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names"

**Location:** `scripts/lib/dev-cycle-read.sh:452-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start selection over main's ls-tree records (any case, nested `.claude/rules/` dirs and nested files under them) and following into 100644/100755/120000 entries; does not establish that Claude Code loads exactly this set (the three untraced shapes in A5), nor starts under a symlinked directory or gitlink (documented not covered).

Starts: `[[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")` (`:559`), then `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]` on the lower-cased name (`:567`); inside `[[ ]]`, `*` matches `/`, so files at any depth under `rules/` and `.claude/` at any depth both match. Following: `if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); continue; fi` (`:603`) with the 100644/100755 and 120000 arms at `:578-595`. Test 6 (symlinked start, two-link chain, `.github/instr.md`, nested `pkg/.claude/rules/`, 100755) passes in E1; probe P5 follows `docs//a.md`, `docs/` and `./docs/a.md` link text (E4: `walk: ok docs/b.md: imported docs/a.md: imported docs: imported`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:556-571`, `scripts/lib/dev-cycle-read.sh:574-603`, `test/scripts/build-loop-check.bats:114-136`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`

---

## Claim 5: "An imported path main lacks is recorded and not read." / commit 2b22a082: "a path main lacks that the checkout does not hold is recorded and not walked (nothing there to load)"

**Location:** `scripts/lib/dev-cycle-read.sh:457-458`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record-before-seen order and the absent arm of the probe; does not establish behavior when the path is present but unreadable to `-e` (an unsearchable parent reads as absent: settled override row, Defer to U2a3c).

`IMPORTED_MAIN+="$(lower "$p")"$'\n'` runs before the seen/ent checks (`:600-603`); a path with no `ent` entry is never queued, and `[[ ! -e "$p" && ! -L "$p" ]]` lets an absent one through (`:606`). Test 3: `docs/new.md` (absent) answers `imported` with `walk ok` (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:598-607`, `test/scripts/build-loop-check.bats:46-61`, `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`

---

## Claim 6: block-comment refusal list: "a doubled name, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink (on main or in the checkout), an imported path main lacks that lies under a directory main stores as a symlink or gitlink, or that the checkout holds as anything but a plain directory (the root itself included), and an untracked start file in the checkout fail the walk, so isimported main answers imported for every path"

**Location:** `scripts/lib/dev-cycle-read.sh:458-465`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape failing the walk and the imported-for-every-path consequence; does not establish that the list is everything Claude Code could load (Claim 7), and does not cover shapes U2a3b changes (a failing `lower`/grep inside import_targets: fixed in U2a3b, stacked).

Each listed shape maps to a `return 1` (`:557` doubled/newline in main's tree; `:562` newline in the untracked list; `:569` untracked start; `:585` empty/newline/absolute; `:582-583` NUL; `:590` `..` after `lk`; `:595` leaves the repo; `:605` symlink/gitlink parent; `:606` checkout probe). The root: `@./` (P2) and link text `..` in `sub/` (P4) both give `walk: failed` in E4, because `blocker . dir` prints `./` (`plaindir .` compares `$ROOT_REAL` with `$ROOT_REAL/.`). P6/P7 (`ld//../evil.md`, `ld/./../evil.md`, `ld/..` with `ld` a link on main) fail. Every listed arm's mutant or reset mutant fails a test except none (E3). isimported: `main) main_imports || return 0` (`:620`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-606`, `scripts/lib/dev-cycle-read.sh:110-121`, `scripts/lib/dev-cycle-read.sh:620`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`, `/tmp/u2a3-cfc2-i1-3N4c/m-untracked.out`, `/tmp/u2a3-cfc2-i1-3N4c/m-probe.out`, `/tmp/u2a3-cfc2-i1-3N4c/m-gitlink.out`

---

## Claim 7: "Checkout files are not walked until U2a3c, so the walk fails closed on them. ... Not covered (known issue A5): start files under a symlinked directory or in a submodule or untracked nested repo, other names one file has on a case-insensitive checkout, absolute imports, and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:465-470`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked starts and paths main lacks (fail closed, verified) and the listed gaps; does not establish fail-closed for an instruction file the checkout's index tracks but main lacks, which passes unwalked and is missing from this list though A5 names it.

P1 (E4): main holds only `CLAUDE.md`; a branch commits `sub/CLAUDE.md` importing `@x.md`; in that checkout `main_imports` answers `walk: ok sub/x.md: -`. The start loop takes candidates only from main's tree and `untracked_md` (`git ls-files -z --others`, `:515`), so a file the index tracks is neither a start nor a failure. Claude Code running in that checkout loads it. A5 lists this ("an instruction file the checkout tracks but main lacks (not a start)"); this comment's "Not covered" list, which presents itself as A5's, omits it. Not a regression: the pre-split lib gives the same `walk: ok sub/x.md: -` (`out-pre.txt`), and main alone cannot see it. P10 confirms the listed nested-repo gap (`walk: ok nest/y.md: -`). Tracked paths whose checkout content differs from main (e.g. P8: main stores `sub` as a gitlink, the checkout holds a file `sub` importing `@secret.md`: `walk: ok ... secret.md: -`) are outside "checkout files" by the design statement "a working-tree edit does not count" and behave identically pre-split.

**Evidence:** `scripts/lib/dev-cycle-read.sh:465-470`, `scripts/lib/dev-cycle-read.sh:515`, `scripts/lib/dev-cycle-read.sh:561-571`, `docs/working/known-issues-dev-cycle.md:18`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out-pre.txt`

---

## Claim 8: "A start file answers imported only when an import reaches it (U2a4's floor names start files by its own rules)."

**Location:** `scripts/lib/dev-cycle-read.sh:466-467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers IMPORTED_MAIN's contents; does not establish U2a4's floor (not yet written).

Starts set `seen[...]=1; queue+=(...)` (`:570`) and are never appended to `IMPORTED_MAIN`, which grows only at `:600` inside the import loop. Test 3 asserts `CLAUDE.md: -`; test 13's self-import (`@CLAUDE.md`) is recorded.

**Evidence:** `scripts/lib/dev-cycle-read.sh:570`, `scripts/lib/dev-cycle-read.sh:598-600`, `test/scripts/build-loop-check.bats:46-61`, `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`

---

## Claim 9: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again."

**Location:** `scripts/lib/dev-cycle-read.sh:471-473`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key, the reset to error before the walk and on every in-loop failure, and cached-failure replay; does not establish that IMPORTED_MAIN is "error" mid-walk (it holds the partial list from `:573` until return, observable only inside the call).

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` then `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=...` (`:550-551`). Every return-1 after `:573` resets to error (`:578, 583, 585, 590, 595, 605, 606`); all seven reset-removal mutants fail a test (E3). Test 16 passes (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-551`, `scripts/lib/dev-cycle-read.sh:573-606`, `test/scripts/build-loop-check.bats:300-309`, `/tmp/u2a3-cfc2-i1-3N4c/m-reset605.out`, `/tmp/u2a3-cfc2-i1-3N4c/m-reset606.out`

---

## Claim 10: "nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0."

**Location:** `scripts/lib/dev-cycle-read.sh:516`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit-status and emptying behavior for terminated, empty and failing output; does not establish success for every exit-0 CMD (one whose output does not end in NUL also returns 1).

```bash
# scripts/lib/dev-cycle-read.sh:517
nul_list() { local -n nl_a="$1"; shift; mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'; }
```

P13 (E4): `printf "a\0b"` exiting 0 → `rc=1 n=0` (the trailing `b` fuses with `rc=0`), empty exit 0 → `rc=0 n=0`, `printf "a\0"; return 1` → `rc=1 n=0`; the pre-split lib left `n=2` on failure (C10 fixed). Both callers (`git ls-tree -r -z`, `git ls-files -z`) NUL-terminate every record, so the extra arm fails closed in practice. Precise version: "...or is emptied and 1 unless CMD exited 0 and its output ends in a NUL (or is empty)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:516-517`, `scripts/lib/dev-cycle-read.sh:553`, `scripts/lib/dev-cycle-read.sh:561`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out-pre.txt`

---

## Claim 11: return-1 comment: "returns 1, with IMPORTED_MAIN set to "error", ... when main is not found by name, the commit's tree or the untracked list cannot be listed whole (nul_list), a tree record does not parse, a name is listed twice ... or holds a newline, the lower-cased start list comes back short, an untracked start file exists, a blob cannot be read, symlink text it follows is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink, or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root; need_root exits instead."

**Location:** `scripts/lib/dev-cycle-read.sh:536-545`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a one-to-one match between the listed causes and every `return 1` in main_imports at 5c57d367, with IMPORTED_MAIN "error" on each; does not cover failures inside import_targets/lower that do not reach a return (U2a3b's subject, stacked).

Code returns: `:552` main_by_name; `:553`/`:561` nul_list; `:555` record parse; `:557` doubled or newline (tree); `:562` newline (untracked); `:565` short `low`; `:569` untracked start; `:578` blob read (pipefail is set locally, `:547`); `:583` NUL or unreadable symlink blob; `:585` empty/newline/absolute; `:590` `..` after a symlink; `:595` leaves the repo; `:605` symlink/gitlink parent; `:606` probe (root included, P2/P4). Before `:573` IMPORTED_MAIN is still "error" from `:551`; after it each return sets it (Claim 9). The cached replay (`:550`) is the only other non-zero path and returns the earlier verdict. No listed cause lacks a code path, and no code path lacks a listed cause.

**Evidence:** `scripts/lib/dev-cycle-read.sh:536-609`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`, `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`

---

## Claim 12: link-text split and its comment: "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails." (with `mapfile -t -d / parts < <(printf '%s' "$out")`)

**Location:** `scripts/lib/dev-cycle-read.sh:586-593`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the split for `//`, trailing `/`, `.`, `..`, text exactly `..`, `./x` and the lk ordering; does not establish the kernel-vs-lexical question for `..` in an @ token (A5's third untraced shape, settled row).

E4 P14 split shapes: `a//b → [a][][b]`, `a/ → [a]`, `. → [.]`, `.. → [..]`, `../ → [..]`, `a/./b → [a][.][b]` (a leading `/` cannot reach here: `:585` refuses it). An empty or `.` component leaves `p` in place (`realpath -ms` of `p/` or `p/.`), so `ld//..` and `ld/./..` still see `lk` set (P6 fail). Text exactly `..`: `lk` is empty, the component passes, and the final resolve gives `..` at the top level (`:595` fails) or the parent (P4: `sub/CLAUDE.md -> ..` names the root and fails at `:606`). `ld/..` with `ld` a link on main fails (P7). The split-none mutant (`parts=("$out")`) fails test 15 (E3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:584-595`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`, `/tmp/u2a3-cfc2-i1-3N4c/m-split-none.out`

---

## Claim 13a: parent loop `c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || ...; done`, "Main lacks p: under a link or gitlink main stores ... fail."

**Location:** `scripts/lib/dev-cycle-read.sh:604-605`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every proper prefix of p and the two modes 120000/160000; does not establish anything for prefixes main stores as a blob (`CLAUDE.md/x`: passes, and the kernel's ENOTDIR loads nothing either).

`${c%/*}` strips one component per pass until no `/` remains, so every ancestor of p is tested; `^1[26]0000$` matches exactly `120000` and `160000`. The gitlink mutant (`^120000$`) fails test 12, the immediate-parent-only mutant fails test 15 (E3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:605`, `/tmp/u2a3-cfc2-i1-3N4c/m-gitlink.out`, `/tmp/u2a3-cfc2-i1-3N4c/m-parent1.out`

---

## Claim 13b: "... or held in the checkout, fail."

**Location:** `scripts/lib/dev-cycle-read.sh:604`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe on line 606; does not establish failure for a plain directory held in the checkout, which passes.

A plain directory held in the checkout passes (`:606`'s first clause; test 9's `mkdir docs/lt.md` → `walk ok`). Precise version: "or held in the checkout as anything but a plain directory, fail".

**Evidence:** `scripts/lib/dev-cycle-read.sh:604-606`, `test/scripts/build-loop-check.bats:191-192`, `/tmp/u2a3-cfc2-i1-3N4c/m-plaindir.out`

---

## Claim 14: "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs main_imports first. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:610-614`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main/tree/other arms; does not establish anything about the tree walk's own refusals (unchanged here).

`main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;` and `*) return 0 ;;` (`:620-622`). Tests 2, 8 and 14 (failed walk under `if`, with and without pipefail) pass (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:615-624`, `test/scripts/build-loop-check.bats:40-44`, `test/scripts/build-loop-check.bats:162-172`, `test/scripts/build-loop-check.bats:265-273`, `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`

---

## Claim 15: commit 2b22a082: "Interim direction: fail closed. ... So an untracked start file, or anything but a plain directory at an imported path main lacks, fails the walk (the floor refuses every path)" (subject: "main_imports walks main's commit only and fails closed on the checkout until U2a3c")

**Location:** commit 2b22a082 (subject and body paragraph 2)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named checkout inputs (verified: P11, P12, test 3, test 11) and that checkout state can only add failures relative to main alone; does not establish fail-closed for a start file the checkout's index tracks but main lacks (Claim 7, P1).

Named inputs: verified (P11 untracked start under an ignored dir and P12 nested untracked `.claude/rules/a/b/deep.md` fail; pre-split both walked: `out-pre.txt`). Against main alone: every checkout read leads only to `return 1` (Claim 2), so no checkout state makes the walk answer ok where main alone would refuse. Against the pre-split walk: each checkout input it walked now fails, so nothing it caught is now answered ok. The headline "fails closed on the checkout" is broader than the mechanism: P1's tracked-in-checkout start answers `walk: ok` (same as pre-split). The tracked-path-divergence class (P8) is excluded by the design's "a working-tree edit does not count".

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-571`, `scripts/lib/dev-cycle-read.sh:606`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out-pre.txt`

---

## Claim 16: commit 2b22a082: "The gate worktree D13 creates is clean at MAIN_SHA, so the refusal should not fire there."

**Location:** commit 2b22a082 (body paragraph 2); `docs/working/plan-build-loop-handoff.md:97-104`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers D13's wording and a fresh linked worktree at main; does not establish where U2b runs `--check` (the plan leaves it open), nor the worktree's state after the iteration's own edits.

D13 says: "Each iteration works in a fresh worktree, `.claude/wt-dev-cycle-<date>-<HHMM>`, on `chore/dev-cycle-<date>-<HHMM>` from `MAIN_SHA`" (`plan-build-loop-handoff.md:99`). That is the orchestrator's iteration worktree; D13 does not call it the gate's checkout, and F11 says "U2b names the checkout `--check` runs in" (`:126`), so "the gate worktree D13 creates" assumes a U2b choice not yet made. The iteration also writes and commits in that worktree before the land. One shape fires in a clean linked worktree at main: there `.git` is a file, so an instruction file importing `@.git` fails the walk (P3: `walk: failed` in the linked worktree; `walk: ok` in a normal checkout and with the pre-split lib in both). "Should not" is hedged and the shape is unlikely.

**Evidence:** `docs/working/plan-build-loop-handoff.md:97-104`, `docs/working/plan-build-loop-handoff.md:126`, `docs/working/plan-build-loop-handoff.md:279`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out-pre.txt`

---

## Claim 17: commit 2b22a082 loop-1 rows: "C1 removed ... C2 fixed: an imported path under a gitlink main stores fails ... C4 fixed: the link-text split is mapfile -d / from a process substitution (no here-string left in main_imports) ... C7: test 15 asks the path after each failure and covers a one-letter link two levels up. C8: the parent loop steps over "/" (was O(L^2)). C10: nul_list empties its array on failure. C11: test 9's comment."

**Location:** commit 2b22a082 (body, "Loop 1's open rows"); `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:5-17`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named change in the code and tests; does not establish that C4's fix is pinned by a test (reverting the split to the here-string survives the suite).

C1: `:569` refuses an untracked start (untracked mutant fails 3, 9, 11). C2: `^1[26]0000$` (gitlink mutant fails 12). C4: `grep -n '<<<'` finds no line in `:546-609`; the split is `mapfile -t -d / parts < <(printf '%s' "$out")` (`:588`); the here-string revert mutant passes all 16 tests (E3 `m-split-herestring.out`). C7: test 15 follows each `want walk failed` with `want ... imported`, and adds `ln -s deep l` / `@l/inner/i.md` (`build-loop-check.bats:290-293`). C8: `${c%/*}` per `/` versus the pre-split per-character `${p:c:1}`/`${p:0:c}` loop (`git diff cc1aa864 2b22a082`). C10: P13. C11: test 9's first comment now reads "An import through a directory link main stores (the parent-link refusal)" (`:180`), matching loop-1 C11's complaint.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569`, `scripts/lib/dev-cycle-read.sh:588`, `scripts/lib/dev-cycle-read.sh:605`, `test/scripts/build-loop-check.bats:180`, `test/scripts/build-loop-check.bats:275-298`, `/tmp/u2a3-cfc2-i1-3N4c/m-split-herestring.out`, `/tmp/u2a3-cfc2-i1-3N4c/m-untracked.out`

---

## Claim 18: commit 2b22a082: "Tests: the untracked-start and checkout-target cases now expect a failed walk; the untracked parts of the "follows", cycle and .MD tests move to U2a3c; new cases for a gitlink parent and a checkout file at a path main lacks."

**Location:** commit 2b22a082 (body, Tests paragraph)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test diff cc1aa864→2b22a082; does not establish that U2a3c will carry the removed cases (no `feat/build-loop-u2a3c` branch exists at review time; "move to" is a plan commitment).

`git diff cc1aa864 2b22a082 -- test/scripts/build-loop-check.bats`: test 3 drops `CLAUDE.local.md`/`docs/private.md` from the ok case and adds `printf 'x\n' > docs/new.md ... want walk failed` and the `CLAUDE.local.md ... want walk failed` line; test 6 drops `.claude/rules/mine.md`, `pkg/.claude/rules/x.md`, `CLAUDE.local.md`, `docs/local-notes.md`; test 11 now expects `walk failed` for `docs/AGENTS.MD`; test 13 drops the `CLAUDE.local.md`/`docs/u.md`/`docs/w.md` cycle; test 12 adds the `160000 commit` case. `git branch -a --list '*u2a3*'` lists `feat/build-loop-u2a3`, `-u2a3-src`, `-u2a3b` only.

**Evidence:** `test/scripts/build-loop-check.bats:46-61`, `test/scripts/build-loop-check.bats:114-136`, `test/scripts/build-loop-check.bats:223-263`

---

## Claim 19: commit 2b22a082: "build-loop-check.bats 16; 114 across the five suites."

**Location:** commit 2b22a082 (body, Tests paragraph)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and pass state at 5c57d367 (2b22a082's code and tests are unchanged since: 5c57d367 touches one docs file); does not establish shellcheck cleanliness.

`grep -c '^@test' test/scripts/build-loop-check.bats` → 16. E2 over dev-cycle (75), build-loop-read (19), build-loop-check (16), fixture-git-env (2) and `test/fixture-hermeticity.bats` (2), the five suites prior reports name: 114 `ok`, 0 `not ok`, exit 0. Matches no logged hallucination pattern (the test-tally pattern's counts were wrong; this one is right).

**Evidence:** `test/scripts/build-loop-check.bats:26-309`, `/tmp/u2a3-cfc2-i1-3N4c/bats-five.txt`, `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`

---

## Claim 20: commit 2b22a082: "Mutants of the untracked-start refusal, the checkout probe, the gitlink match, the parent loop (immediate parent only), the plain-directory allowance and the link-text split each fail."

**Location:** commit 2b22a082 (body, Tests paragraph)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers my constructions of the six mutants (diffs in `$S/m-*.diff`); does not establish that every plausible "link-text split" mutant fails (the here-string revert survives, Claim 17).

E3: untracked (`|| return 1` → `|| true` at `:569`) fails 3, 9, 11; probe (`:606` deleted) fails 3, 9, 12; gitlink fails 12; parent1 (`while` → `if`) fails 15; plaindir (first clause of `:606` removed) fails 9; split-none fails 15.

**Evidence:** `/tmp/u2a3-cfc2-i1-3N4c/m-untracked.diff`, `/tmp/u2a3-cfc2-i1-3N4c/m-probe.diff`, `/tmp/u2a3-cfc2-i1-3N4c/m-gitlink.diff`, `/tmp/u2a3-cfc2-i1-3N4c/m-parent1.diff`, `/tmp/u2a3-cfc2-i1-3N4c/m-plaindir.diff`, `/tmp/u2a3-cfc2-i1-3N4c/m-split-none.diff`, the matching `.out` files

---

## Claim 21: commit 2b22a082: "392 changed code lines against main."

**Location:** commit 2b22a082 (body, Tests paragraph)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers insertions plus deletions outside `docs/` (the convention prior reports used); does not establish any other counting convention.

E5 output: `111 9 scripts/lib/dev-cycle-read.sh`, `266 2 test/scripts/build-loop-check.bats`, `2 2 test/scripts/dev-cycle.bats` → 120 + 268 + 4 = 392. Unchanged at 5c57d367.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1`, `test/scripts/build-loop-check.bats:1`, `test/scripts/dev-cycle.bats:1083-1091`

---

## Claim 22: commit 5c57d367 "docs(reviews): fix-drift output for the U2a3 split commit (no findings)"

**Location:** commit 5c57d367; `docs/reviews/lite-review-fix-drift-build-loop-u2a3-split.txt:1`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file's content against the subject; does not establish the drift review's correctness or its token count.

The one-line file reads `lite-review [fix-drift]: FINDINGS: NONE (18488 out-tokens)`, and the commit adds only that file. This is the only docs(reviews) commit after 0170f16a.

**Evidence:** `docs/reviews/lite-review-fix-drift-build-loop-u2a3-split.txt:1`

---

## Claim 23: A5: "Until U2a3c the walk reads main's commit only and fails closed on the checkout: an untracked start file, or anything but a plain directory at an imported path main lacks, fails the walk (so the floor refuses every path), and a path main lacks that the checkout does not hold is recorded but not walked. Not covered: start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one), ..., and an instruction file the checkout tracks but main lacks (not a start)."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal list, the interim contract and the Not-covered list against the code and probes P1, P10-P12; does not establish the three "untraced against Claude Code" shapes (host probe needed, as A5 says).

The refusal list matches Claims 6 and 11, including "under a directory main stores as a symlink or gitlink". The interim contract matches Claims 5 and 15. The Not-covered items are confirmed by P10 (nested repo: `walk: ok nest/y.md: -`) and P1 (tracked-in-checkout start: `walk: ok sub/x.md: -`). "Absolute imports" are dropped by import_targets (`[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue`, `:500`). Unlike Claims 7 and 24, A5 names the tracked-in-checkout gap.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:493-509`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`

---

## Claim 24: plan F11: "... Until U2a3c it fails closed on the checkout: an untracked start file, or anything but a plain directory at an imported path main lacks, fails the walk; U2a3c walks them as a second phase that only appends. Gaps: known issue A5 (start files under a symlinked directory or in a submodule or untracked nested repo, case-insensitive names, absolute imports, and three shapes untraced against Claude Code)."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row's refusal list and interim contract (verified); does not establish completeness of its Gaps parenthesis, which omits A5's tracked-in-checkout start.

The refusal list and interim contract match Claims 6 and 15. The Gaps parenthesis presents itself as A5's contents but leaves out "an instruction file the checkout tracks but main lacks (not a start)" (P1). "U2a3c walks them as a second phase that only appends" is a plan commitment (matches the U2a3c bullet at `:277`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `docs/working/known-issues-dev-cycle.md:18`, `/tmp/u2a3-cfc2-i1-3N4c/probes/out.txt`

---

## Claim 25: plan U2a3 and U2a3c bullets: "started from main's instruction files and `.claude/rules/`. It refuses ... (a doubled name, ..., an imported path main lacks under a directory main stores as a symlink or gitlink), as FENCE_AWK does, and fails closed on the checkout (an untracked start, or anything but a plain directory at an imported path main lacks). ... Split at its own cap (2026-10-06, the user chose split): the checkout-side reads moved to U2a3c." / "U2a3c ... Stacks above U2a3b."

**Location:** `docs/working/plan-build-loop-handoff.md:276-277`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the U2a3 bullet's description of the code and the split's record in the rubric; does not establish U2a3c's future behavior (no branch yet) or "fails closed on the checkout" beyond the two named inputs (parenthesized here, so the bullet is precise).

The bullet's parenthesis names exactly the two checkout inputs, which `:569` and `:606` refuse; the refusal list matches Claim 11. The rubric's split section records the decision ("Decision: **split**. The user answered the gate in session on 2026-10-06").

**Evidence:** `docs/working/plan-build-loop-handoff.md:276-277`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:4-6`, `scripts/lib/dev-cycle-read.sh:569`, `scripts/lib/dev-cycle-read.sh:606`

---

## Claim 26: plan U2b bullet: "It names the checkout `--check` runs from (the walk reads its untracked starts, targets main lacks, and checkout symlinks)."

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what main_imports inspects in the checkout; does not establish U2b's choice of checkout.

After the split the walk lists untracked starts (`:561`), probes targets main lacks (`:606`) and tests `-L` in link text (`:592`), but it reads none of them as content; each only fails the walk (Claim 2). "Reads" holds only in the sense of "inspects"; until U2a3c the precise version is "the walk fails on its untracked starts, on anything but a plain directory at targets main lacks, and on checkout symlinks before a `..`".

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:561-569`, `scripts/lib/dev-cycle-read.sh:592`, `scripts/lib/dev-cycle-read.sh:606`

---

## Claim 27: test 7 comment: "An untracked name holding a newline fails the walk."

**Location:** `test/scripts/build-loop-check.bats:146`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted outcome (the walk fails); does not establish that the test pins the untracked-list newline check at `:562`, which it no longer isolates.

The fixture name is `".claude/rules/zz"$'\n'"docs.md"`, which after the split is also an untracked `.claude/rules/` start. Removing the newline check (`for f in "${recs[@]}"; do cand+=("t:$f"); done`, E3 `m-untrnl.diff`) leaves all 16 tests passing: the walk still fails at `:569`. The comment's stated cause is not what the test now detects. A non-start untracked name (for example `docs/zz\nx.md`) would isolate it.

**Evidence:** `test/scripts/build-loop-check.bats:146-150`, `scripts/lib/dev-cycle-read.sh:562`, `scripts/lib/dev-cycle-read.sh:569`, `/tmp/u2a3-cfc2-i1-3N4c/m-untrnl.out`

---

## Claim 28: test 9 name "... and on a checkout symlink it would read" and comment "An untracked start file the walk cannot read."

**Location:** `test/scripts/build-loop-check.bats:174`, `test/scripts/build-loop-check.bats:189`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two phrases' fit to the post-split code; does not dispute the test's assertions, which pass.

After the split the walk reads no checkout file. The `chmod 000 CLAUDE.local.md` case fails because any untracked start fails (`:569`), whether readable or not. The untracked mutant kills test 9 (E3), and the case would fail identically with mode 644. "A checkout symlink it would read" likewise describes the pre-split `t:` arm. The symlink cases now fail at the `:606` probe (`docs/lt.md`) or at `:569` (`CLAUDE.local.md` symlink). Precise wording: "an untracked start file (any, readable or not)" and "a checkout symlink at a path main lacks".

**Evidence:** `test/scripts/build-loop-check.bats:174-200`, `scripts/lib/dev-cycle-read.sh:569`, `scripts/lib/dev-cycle-read.sh:606`, `/tmp/u2a3-cfc2-i1-3N4c/m-untracked.out`

---

## Claim 29: test 10 name: "... reads a list past 64 KiB under ulimit -f 0"

**Location:** `test/scripts/build-loop-check.bats:202`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the import list size and the ok outcome; does not establish behavior with SIGXFSZ ignored (settled Accepted-immutable row on c42f017f).

The import_targets output for 320 tokens `@docs/%0200d.md` plus `@docs/last.md` is 320 × 209 + 13 = 66,893 bytes (python3), more than 65,536. The test passes (E1). `docs/last.md`, the final line, is asserted.

**Evidence:** `test/scripts/build-loop-check.bats:216-220`, `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`

---

## Claim 30: remaining U2a3 test names (tests 3, 4, 5, 6, 8, 11, 12, 13, 14, 15, 16) assert what they say

**Location:** `test/scripts/build-loop-check.bats:46-309`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name's listed cases against its assertions and the E3 kill map; does not cover tests 7 and 9 (Claims 27, 28) or test 10 (Claim 29).

Each named case has a matching `want`. Test 3: start, working-tree edit, untracked start, checkout file. Test 4: missing blob, no main by name. Test 5: doubled start, doubled other, newline names, with `ls-tree` NUL count 2 asserted. Test 6: the follows list. Test 8: NUL-in-file and the failed walk under `if`. Test 11: `.MD` tracked and untracked. Test 12: dangling link, dir under link, empty text, gitlink. Test 13: cycle and self-import. Test 14: no pipefail. Test 15: `..` after a link on main and checkout-only, one-letter link. Test 16: cache. The E3 kills land on the tests whose names cover the mutated arm (e.g. gitlink → 12, parent1 → 15, reset578 → 4 and 14).

**Evidence:** `test/scripts/build-loop-check.bats:46-309`, `/tmp/u2a3-cfc2-i1-3N4c/bats-blc.txt`, `/tmp/u2a3-cfc2-i1-3N4c/m-gitlink.out`, `/tmp/u2a3-cfc2-i1-3N4c/m-parent1.out`, `/tmp/u2a3-cfc2-i1-3N4c/m-reset578.out`

---

## Claim 31: dev-cycle.bats test "sourcing the reader lib defines its functions and calls neither git nor perl" (list extended with `main_imports`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`)

**Location:** `test/scripts/dev-cycle.bats:1077`, `test/scripts/dev-cycle.bats:1084-1090`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function list against the lib's definitions; does not establish anything about the git/perl stubs (unchanged).

The `declare -F` list names every function the lib defines except the new `nul_list` (`:517`). The diff adds `main_imports` and the two variables only. Precise version: add `nul_list` to the list, or the name over-claims by one function.

**Evidence:** `test/scripts/dev-cycle.bats:1084-1090`, `scripts/lib/dev-cycle-read.sh:517`

---

## Claim 32: override row (C3, Defer): "After the split U2a3 reads no checkout content (a path there is only probed and fails the walk if present), so nothing it would read is lost; the file is unreadable to a same-uid Claude Code too."

**Location:** `docs/reviews/override-log.md:383`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "reads no checkout content" and the probe's behavior; does not establish the same-uid claim for a root-run Claude Code.

"Reads no checkout content" holds (Claim 2). "Fails the walk if present" is too broad: a plain directory that is present passes (`:606`, plaindir mutant). An unsearchable parent makes `-e` false, so the path reads as absent and the walk answers ok. The row's Defer rests on that, and it is consistent.

**Evidence:** `docs/reviews/override-log.md:383`, `scripts/lib/dev-cycle-read.sh:606`, `/tmp/u2a3-cfc2-i1-3N4c/m-plaindir.out`

---

## Claim 33: override rows (C9, C12): "Process substitution adds ~0.3-0.6 ms per queued file over the here-string" and "Taken as the split: U2a3 is the main-only phase and fails closed on the checkout"

**Location:** `docs/reviews/override-log.md:384-385`
**Type:** Performance / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-substitution cost on this host and the C12 contract (Mostly accurate by Claim 15's residue); does not establish the original measurement's host or method, so the C9 range cannot be reproduced exactly.

E6 (three runs): here-string 0.0155-0.0160 ms per loop, process substitution 0.2738-0.2877 ms, delta 0.258-0.272 ms per substitution. A plain queued file pays one (`:607`), a symlink pays two (`:588`, `:607`), so about 0.27-0.54 ms on this host, the same order as the row's ~0.3-0.6 ms. The original measurement is not linked, hence Unverifiable rather than Verified. C12's "fails closed on the checkout" carries the P1 residue (Claim 15).

**Evidence:** `docs/reviews/override-log.md:384-385`, `scripts/lib/dev-cycle-read.sh:588`, `scripts/lib/dev-cycle-read.sh:607`, `/tmp/u2a3-cfc2-i1-3N4c/perf.txt`

---

## Earlier commits (pointers only)

- fbeae280, 4f087967, e7b5d7ed, c42f017f, 2a3e499f, 34edec56: verdicted in `docs/reviews/code-fact-check-report-build-loop-u2a3-f-r3.md` (Claims 31-35 and neighbors) and `-final.md`; the commit-message errors there have Accepted-immutable rows at `docs/reviews/override-log.md` (rows naming 4f087967/34edec56 and e7b5d7ed/c42f017f).
- 45ad17b0, 277b2fab, cb4ebbc8, cc1aa864, 0170f16a: docs commits covered by the iteration-1/2/3 reports (`code-fact-check-report-build-loop-u2a3.md`, `-i2.md`, `-final.md`).

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 28** (`test/scripts/build-loop-check.bats:174`, `:189`): the test name says "a checkout symlink it would read" and a comment says "an untracked start file the walk cannot read", but after the split any untracked start fails, readable or not, and the walk reads no checkout file.

### Mostly Accurate
- **Claim 2** (`scripts/lib/dev-cycle-read.sh:33`): "anything at an imported path main lacks" should say "anything but a plain directory at"; also, a checkout symlink before a `..` in link text fails the walk and the header does not list it.
- **Claim 7** (`scripts/lib/dev-cycle-read.sh:465-470`): the Not-covered list omits A5's "instruction file the checkout tracks but main lacks", which passes unwalked (P1).
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:516`): exit 0 with output not ending in NUL also returns 1 (fails closed).
- **Claim 13b** (`scripts/lib/dev-cycle-read.sh:604`): "held in the checkout" should say "held in the checkout as anything but a plain directory".
- **Claim 15** (commit 2b22a082): the headline "fails closed on the checkout" is broader than the two named inputs (P1 residue).
- **Claim 16** (commit 2b22a082): D13's worktree is the orchestrator's iteration worktree, and the plan leaves the gate's checkout to U2b. `@.git` fires the refusal in a linked worktree (P3).
- **Claim 24** (`docs/working/plan-build-loop-handoff.md:126`): the F11 Gaps list omits the tracked-in-checkout start.
- **Claim 26** (`docs/working/plan-build-loop-handoff.md:279`): "the walk reads" should be "fails on" until U2a3c.
- **Claim 27** (`test/scripts/build-loop-check.bats:146`): the untracked-list newline check (`:562`) is unpinned, because the fixture name is also an untracked start (the mutant survives).
- **Claim 31** (`test/scripts/dev-cycle.bats:1084`): `nul_list` is missing from the defined-functions list.
- **Claim 32** (`docs/reviews/override-log.md:383`): "fails the walk if present" misses the plain-directory allowance.

### Unverifiable
- **Claim 33** (`docs/reviews/override-log.md:384`): the original C9 measurement is not linked. This host measures about 0.27 ms per substitution, the same order as the row.

## Escalations

- `scripts/lib/dev-cycle-read.sh:465-470` and `docs/working/plan-build-loop-handoff.md:126` (Claims 7, 24): add A5's tracked-in-checkout start to the Not-covered and Gaps lists. Addressee: coordinator, for routing to the author (wording only; behavior matches the pre-split walk).
- Commit 2b22a082 body (Claims 15, 16): commit message, immutable. Addressee: coordinator (override-log candidate). The D13 attribution matters to U2b, which picks the gate's checkout, and the linked-worktree `.git` refusal (P3) is new in the split.
- `test/scripts/build-loop-check.bats:146` and `:174/:189` (Claims 27, 28): the comment/name no longer matches what the test detects, and the `:562` check is unpinned. Addressee: test-strategy critic and author.
- `scripts/lib/dev-cycle-read.sh:588` (Claim 17 residue): reverting C4's fix to the here-string passes all 16 tests. Addressee: test-strategy critic.
- `scripts/lib/dev-cycle-read.sh:33`, `:516`, `:604` (Claims 2, 10, 13b): one-phrase wording fixes. Addressee: author.

## Goal-Alignment Note

**Success criterion (verbatim):** A code-fact-check report saved to docs/reviews/code-fact-check-report-build-loop-u2a3-L2.md verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages.

**Answered:** Yes, for the lib comments, the test names and comments, A5, F11, the U2a3/U2a3c/U2b bullets, the rubric split section, the three new override rows, and the messages of 2b22a082 and 5c57d367. Earlier commit messages get pointers per the brief. Fail-closed was probed against the current lib and the pre-split lib (cc1aa864). No checkout state makes the walk answer ok where main alone or the pre-split walk would refuse. The one checkout input that passes unwalked, a start file the checkout's index tracks but main lacks (P1), behaves the same pre-split and is documented in A5 but not in the code comment or F11. All six named mutants fail, and 16/114 tests pass. 392 lines confirmed.

**Out of scope:** The three Claude Code shapes A5 lists as untraced (they need a host probe). U2a3b's import_targets and lower failure handling (fixed in U2a3b, stacked). Settled rows (unsearchable checkout directory, token `..`, cache ignoring checkout state). The hallucination-pattern log was read but not edited: the shared context permits writing only this report, and no Incorrect fabrication was found.

**Escalate:** The five items under Escalations. None is blocking-grade: no Incorrect verdict, and every gap found fails closed or matches the pre-split behavior.
