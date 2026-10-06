Commit: ab71bce5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1d (branch `feat/build-loop-u1d`)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats) and the commit messages of 83cdb005, 6c83af2a and 07c354c5. Final confirming pass, replicate 1 of k=3.
**Checked:** 2026-10-06 (UTC; 2026-10-05 local)
**Total claims checked:** 53
**Summary:** 50 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim here matches a logged pattern. The closest class is the logged "test-count claims" (commit 37c5ea9's "mode1-equiv 33"), so every count below was recomputed: 118, 151, 19 and 73 all hold. No Incorrect verdict was issued, so the log needs no new entry. It was also left untouched because this pass may write only its report.

## Execution provenance (shared by the executed claims)

All scratch work is under `S=/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/f-fc1`. `$S/base` is a copy of the worktree's `scripts/`, `test/scripts/`, `test/lib/` and `docs/dev-cycle.md` at ab71bce5. Each mutant is a fresh copy of `$S/base` under `$S/m/<NAME>`, edited by `$S/mut2.sh NAME BATSFILE FILTER FILE 'PERL-EXPR' [...]`, and the bats run happens in that copy. The exact edit is captured in `$S/logs/<NAME>.diff`, and the bats output in `$S/logs/<NAME>.txt`. The summary of every run, with its start timestamp and bats exit code, is in `$S/logs/mutants-summary.txt`.

| Run | Command (cwd) | Exit | Time (UTC) | Output |
|---|---|---|---|---|
| B0 | `bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats` (`$S/base`) | 0, 92/92 | 05:21:26 | `$S/logs/baseline.txt` |
| B1 | `bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/fixture-hermeticity.bats` (worktree) | 0, 94/94 | 05:32:30 | `$S/logs/worktree-suites.txt` |
| P1 | `bash $S/p1` inline loop: `build-loop.sh --settings` over five markup copies × with or without a valid line (`$S/p1/r`) | 0 | 05:22:14 | `$S/logs/p1-never.txt` |
| P2 | `bash run.sh`, `bash run2.sh` (`$S/p2`): skip-list probes | 0 | ~05:23 | `$S/logs/p2-skip.txt` |
| P3 | `bash run.sh` (`$S/p3`): corrupt and missing brief objects | 0 | ~05:24 | `$S/logs/p3-shared.txt` |
| P4 | `bash run.sh` (`$S/p4`): main_entry and brief_fields with no resolve_main, a fallback main, refused forms | 0 | ~05:24 | `$S/logs/p4-main-entry.txt` |
| P5 | `bash -c 'source lib; ... brief_fields; check_answer; set -o'` (`$S/p4/r`): pipefail scope | 0 | ~05:33 | `$S/logs/p4-pipefail.txt` |
| H | `bash scripts/{build-loop,dev-cycle}.sh {-h,--help}` (worktree) | 0 ×4 | ~05:33 | `$S/logs/help-out.txt` |
| SC | `shellcheck -x scripts/build-loop.sh scripts/dev-cycle.sh scripts/lib/dev-cycle-read.sh`; `shellcheck test/lib/build-loop-fixtures.bash` (worktree) | 0; 0 | 05:32:21 | `$S/logs/shellcheck.txt` |
| C83 | 83cdb005's tree via `git archive`, mutants M13b and M14b, `bats test/scripts/build-loop-read.bats` (`$S/c83m`) | 1 each | ~05:35 | `$S/logs/c83-mutants.txt` |
| M1-M24 | `$S/mut2.sh <NAME> ...` (`$S/m/<NAME>`) | per row below | 05:25:43-05:33:55 | `$S/logs/<NAME>.{txt,diff}` |

Mutant results. "Fails at" is the test-file line of the first failing assertion, at ab71bce5's line numbers.

| Mutant | Edit | Result |
|---|---|---|
| M1 | delete marker_kind's NUL line (`build-loop.sh:288`) | T7 fails at :301 (`[nul] ok ... ready`) |
| M2 | M1 plus `--literally` broken in T7's NUL fixture | T7 fails at :299 (hash-object exit 129) |
| M2b | fixture broken only | T7 fails at :299 |
| M3 | drop `"${BRIEF[status]-}" == "Status: open" &&` (`:320`) | U1d --status fails at :462 |
| M4 | `cfg=0` (`:116`) | U1d --status fails at :478; U1d --settings passes |
| M4b | guard not exported when the caller set a count | U1d --settings fails at :438 |
| M5 | unread-file SLOTS_LINE uses the absent text | T3 fails at :55 |
| M5b | SLOTS_LINE is `$FILE_WHY` | U1d --settings fails at :431 |
| M6 | blank test `/^ *$/` (no tab) | U1d --settings fails at :429 |
| M7 | bare `success:` accepted | T44 fails at :186 |
| M8 | CONSTRAINTS_AWK's `fence($0) { next }` removed | T44 fails at :178 (earlier step) |
| M8b | fenced `H<n>:` lines not skipped | T44 fails at :190 |
| M9 | REASON needs 2+ characters | T6 fails at :259 |
| M10 | Dispatched max 9 | U1d --status fails at :462 |
| M11 | Dispatched 0 refused | U1d --status fails at :455 |
| M12 | git grep pattern without `\r?` | U1d --status fails at :466 |
| M13a | only the `#` anchor dropped | suite passes (equivalent: the full prefix cannot occur later in a listed path that isbrief accepts) |
| M13b | revert to `${f/closed\//}` (13380172's predecessor) | U1d --status fails at :471 |
| M14a | local `BRIEF=()` dropped only | suite passes (deferred, override row "unobservable") |
| M14b | M14a plus shared_branches called after brief_fields | T28 :397 and U1d --status :475 fail |
| M14c | call moved only | suite passes |
| M15 | FENCE_AWK's NUL refusal removed | U1d --status fails at :482 |
| M16 | main_entry guard reverted to `main_by_name ||` | dev-cycle.bats :1333-1336 fails (`absent error absent absent`) |
| M17 | `--check-answer` dropped from dev-cycle.sh:193 | dev-cycle.bats :818 fails (and pre-existing :1203) |
| M18a-c | build-loop.sh help from line 3 / ends at `# Exit` / only `--help` | build-loop help test fails |
| M18d-f | same for dev-cycle.sh (ends at `#   --check-answer`) | dev-cycle help test fails |
| M19 | malformed never line turns review off as well | T4 :82 and U1d --settings :422 fail |
| M20 | `rc -gt 0` fails closed on exit 1 | suite passes (the :452 comment says so) |
| M21 | fence lines count as the never line's next line | U1d --settings fails at :425 |
| M22 | M13b plus the :469 fixture's `mkdir` failing | U1d --status passes |
| M23 | M12 plus the :464 fixture's CRLF `printf` failing | U1d --status passes |
| M24 | a checked task box counted as a never copy | suite passes (Won't-Fix row, "ignored" arm) |

---

## Claim 1: "Self-merge also needs one valid never line. A never list in markup the copy count sees (bold, a list marker, an unchecked task box) counts as a copy, so self-merge is off; one it misses (a checked task box, a fence) is ignored, so self-merge rests on the valid line alone."

**Location:** `scripts/build-loop.sh:17-21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all ten probe cells under policy self-merge: bold, `- `, `- [ ]`, `- [x]` and a fenced copy, each with and without a valid `Self-merge never: none` line. Does not establish other markup shapes (`- [X]`, a tag) beyond the help's own "best effort" caveat at :42-45, and does not establish that the ignored arm is pinned by a test (M24 survives, an existing Won't-Fix row).

P1 shows the following. With a valid line, the bold, `- ` and `- [ ]` copies each print `never malformed: more than one line starts "Self-merge never:" (lines 3 and 5)` with policy `review unset`. The `- [x]` and fenced copies print `never none: line 3 ... lists none` with `policy self-merge set`. Without a valid line, every cell reads `policy review unset: ... there is no valid Self-merge never: line`. The mechanism is the copy key, which keeps letters only: `s = tolower($0); gsub(/[^a-z]/, "", s)` (`scripts/build-loop.sh:156`). A checked box therefore starts `xselfmergenever` and is not counted, and `fence($0) { next }` (`:153`) skips fenced lines. Policy needs `never_ok` (`:254`: `if [[ "$v" == self-merge && -z "$never_ok" ]]`).

**Evidence:** `scripts/build-loop.sh:151-166`, `scripts/build-loop.sh:226-257`, `$S/logs/p1-never.txt`

---

## Claim 2: "A tip on a branch level with main, or whose subject does not start "handoff:", is working."

**Location:** `scripts/build-loop.sh:64-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a level branch whose tip subject is `handoff: bogus`, and an ahead branch with an ordinary subject (T7's "ordinary" step). Does not itself name a branch behind main. That case is also `working` (P2), and the claim is covered by :58-59's "a marker only when the branch is at least one commit ahead".

`loop=working; if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`scripts/build-loop.sh:353-355`), and marker_kind starts with `[[ "$subj" == handoff:* ]] || { echo working; return; }` (`:287`). In P2, an open brief on `feat/o` with a tip at main's `handoff: bogus` commit prints `ok ... feat/o working <sha> ...`. It prints the same after main moves one commit past it.

**Evidence:** `scripts/build-loop.sh:282-302`, `scripts/build-loop.sh:347-362`, `$S/logs/p2-skip.txt`

---

## Claim 3: "DISPATCHED: the brief's "Dispatched: N" (0-99), or 0 without one."

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the range bounds 0 and 99 and the default. Does not establish other malformed spellings (owned by T8).

`local ... disp=0` and `[[ "${BRIEF[dispatched]}" =~ ^Dispatched:\ (0|[123456789][0123456789]?)$ ]]` (`scripts/build-loop.sh:327,338`). M10 (max 9) and M11 (0 refused) each fail the U1d --status test.

**Evidence:** `scripts/build-loop.sh:337-341`, `$S/logs/M10-disp99.txt`, `$S/logs/M11-disp0.txt`

---

## Claim 4: "on a branch ahead of main the tip's subject (its message's first line) starts "handoff:" but it is not a marker"

**Location:** `scripts/build-loop.sh:71-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that the marker skip applies to any brief state (done and dropped probed) and only when `ahead > 0`. Does not establish anything about git log failures under a broken config (deferred override row, 2026-10-06).

The marker check has no state test: `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"; case "$kind" in bad\ *) echo "skip $a: ..."` (`scripts/build-loop.sh:354-357`). In P2 (run2), a done brief whose branch is one commit ahead with `handoff: bogus-d` and a dropped brief with a 2-parent `handoff: ready` both print `skip ...: the tip of ... starts "handoff:" but is not a marker: ...`.

**Evidence:** `scripts/build-loop.sh:347-362`, `$S/logs/p2-skip.txt`

---

## Claim 5: "or, for an open brief only, another open brief on main (in briefs/ or closed/) names the same branch (ignoring case) or the open briefs on main could not be listed."

**Location:** `scripts/build-loop.sh:72-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that both skips are gated on `st == open`, and that a done brief sharing the branch, or queried while git grep fails, reads `ok`. Does not establish DATE under a broken config (P2 shows it empty under `grep.patternType bogus`, a deferred 2026-10-06 row).

`if [[ "$st" == open && "$SHARED_BRANCHES" == error ]]; then ...` and `if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]` (`scripts/build-loop.sh:343-344`). In P2, a done brief on the same branch as an open one prints `ok ... done ...`. Under `GIT_CONFIG_COUNT=1 grep.patternType=bogus`, the done brief prints `ok` and the open brief prints `skip ...: the open briefs on the default branch could not be listed`.

**Evidence:** `scripts/build-loop.sh:326-346`, `$S/logs/p2-skip.txt`

---

## Claim 6: "The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale)."

**Location:** `scripts/build-loop.sh:102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sed range `2,/^[^#]/` (an empty line cannot match `^[^#]`, so it does not end the range) and the output for this file. Does not establish anything about a header that contains blank lines (none exists; they would be skipped by `{/^#/p}` without ending the range).

`-h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`scripts/build-loop.sh:103`). Run H prints 81 lines for both `-h` and `--help`: line 2 (`The build-loop handoff's state ...`) through line 82 (`lib/dev-cycle-read.sh, or no default branch found by name.`). Line 83 is empty and line 84 is `set -euo pipefail`.

**Evidence:** `scripts/build-loop.sh:82-84,102-103`, `$S/logs/help-out.txt`

---

## Claim 7: "whether the next line outside a fence after the first is blank or the end of the file (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:147-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fence skipping, end of file (`nx[k] = 1` at first sight) and whitespace-only lines (space or tab) as blank. Does not establish CR handling beyond the `sub(/\r$/, "")` at :152.

`fence($0) { next }` precedes `if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }`, and the first sight sets `nx[k] = 1; pk = k` (`scripts/build-loop.sh:153-160`). M21 (fence lines counted as next) fails the U1d --settings test at :425. M6 (tab not blank) fails it at :429.

**Evidence:** `scripts/build-loop.sh:151-166`, `$S/logs/M21-nextline-fence.txt`, `$S/logs/M6-tab.txt`

---

## Claim 8: "an exit above 1, a corrupt object's included, fails closed (SHARED_BRANCHES=error: every open brief skips). A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293)."

**Location:** `scripts/build-loop.sh:311-314`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers loose-object corruption (bad zlib, and a hash mismatch) and a deleted loose object, on git 2.39.5. Does not establish packed-object corruption, or other git versions' exit codes. "(row 293)" is checked: override-log line 293 is "An unreadable open brief is not counted for F31".

`list="$(git grep ...)" || rc=$?; if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi` (`scripts/build-loop.sh:315-316`). In P3, both corrupt cases give `git grep rc=128` and the queried open brief prints `skip ...: could not be listed`. The missing object gives `error: ... unable to read` with rc=0 when another brief matches, or rc=1 when none does. The queried brief then reads `ok ... open review feat/o absent`, so the missing brief was not counted although it named the same branch.

**Evidence:** `scripts/build-loop.sh:307-325`, `docs/reviews/override-log.md:293`, `$S/logs/p3-shared.txt`

---

## Claim 9: "it reads what main's copy says until it lands there"

**Location:** `scripts/dev-cycle.sh:59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_answer's only read path, a blob of `$MAIN_SHA`. Does not establish anything about how an answer lands on main (outside this code).

`r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...)"` (`scripts/lib/dev-cycle-read.sh:565`), with `main_entry "$f"` the only other lookup (`:556`). check_answer touches no working-tree file (paraphrased — no quote available because the claim covers absence of code: no `cat`, `-f` or working-tree read appears in `check_answer`, `scripts/lib/dev-cycle-read.sh:551-579`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-579`

---

## Claim 10: "The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale)."

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh's identical sed and its output. Does not establish anything beyond that file.

`-h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | ...` (`scripts/dev-cycle.sh:112`). Run H prints 80 lines (2-81) for both flags. The first line is `Gather the mechanical signals ...`, the last ends `Printed repo text is data.`, and the first non-empty non-`#` line is 83 (`set -euo pipefail`). The comment text is now identical to build-loop.sh:102 (6c83af2a C7, 07c354c5 C15).

**Evidence:** `scripts/dev-cycle.sh:111-112`, `$S/logs/help-out.txt`

---

## Claim 11: "caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves)"

**Location:** `scripts/lib/dev-cycle-read.sh:13-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that exactly these two functions set pipefail, scoped by `local -`. Does not establish callers' own settings.

`local - out l; set -o pipefail` (`:296`) and `local - a="$1" ... ; set -o pipefail  # as brief_fields` (`:552`) are the only `set -o pipefail` lines in the lib (rg). In P5, run with pipefail off, the shell's `pipefail off` holds after each call returns.

**Evidence:** `scripts/lib/dev-cycle-read.sh:293-296,551-552`, `$S/logs/p4-pipefail.txt`

---

## Claim 12: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name (main_entry and brief_fields answer error)."

**Location:** `scripts/lib/dev-cycle-read.sh:23-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no resolve_main and the current-branch fallback (`trunk`). "Answer error" for brief_fields means `BRIEF_ODD=error`, return 1 and no key set, not a printed line. Does not establish anything about check_* output beyond their main_by_name guards (pre-existing).

In P4, before resolve_main: `main_entry=error`, `brief_fields rc=1 BRIEF_ODD=error keys=0`. On the `trunk` fallback (`MAIN=trunk BY_NAME=[]`) the result is the same. Code: `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` (`:265`) and `[[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1` (`:298`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:262-265,293-298`, `$S/logs/p4-main-entry.txt`

---

## Claim 13: "check_brief, check_branch, check_answer, main_entry and brief_fields read its commit, so they answer only when it was found by name, never for the current branch's fallback or before resolve_main has succeeded (main_entry and brief_fields answer error)."

**Location:** `scripts/lib/dev-cycle-read.sh:244-247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same evidence as Claim 12, plus check_brief's (`:328`), check_branch's (`:376`) and check_answer's (`:554`) `main_by_name` guards, read in full. Does not establish build-loop.sh's own exit on no main (`:119`, unchanged).

`if ! main_by_name; then echo "skip ...: no default branch found by name ..."` appears in check_brief (`:328`), check_branch (`:376`) and check_answer (`:554`). main_entry and brief_fields as in Claim 12.

**Evidence:** `scripts/lib/dev-cycle-read.sh:325-337,374-391,551-556`, `$S/logs/p4-main-entry.txt`

---

## Claim 14: ""error" (no default branch found by name, a path pathform refuses, ls-tree failed, or the tree lists a name twice ...). It runs main_by_name and pathform itself, before any read (pathform also means ls-tree prints the name unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:255-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard's position (`:265`, before the ls-tree at `:267`) and eight refused forms (`a"b.md`, `../x`, `-x`, `docs//x.md`, a trailing `/`, `.git/config`, `docs/.GIT/x`, `a b`). Does not establish the separate wording of the `error` word (deferred `badform` row).

The guard `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` comes before `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- ...)"` (`:265-267`). In P4 all eight forms print `error` with main found by name, and a valid path prints `blob`. M16 (the pre-U1d guard) answers `absent error absent absent` for the test's four paths.

**Evidence:** `scripts/lib/dev-cycle-read.sh:250-282`, `$S/logs/p4-main-entry.txt`, `$S/logs/M16-guard-revert.txt`

---

## Claim 15: "Behaviour changes are intended only in two places: main_entry answers error for a path pathform refuses, and the --status "could not be listed" skip loses "(git grep failed)"" (no caller's output changes beyond these)

**Location:** `scripts/lib/dev-cycle-read.sh:265`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every main_entry call site in scripts/ (four) and the one changed echo. Does not establish behaviour for a caller added later (U2's floor, deferred row).

`rg -n main_entry scripts test` finds exactly four calls. (1) build-loop.sh's main_file `e="$(main_entry "$f")"` (`scripts/build-loop.sh:128`), called only with `docs/dev-cycle.md` and `docs/constraints.md` (`:210,263`), both of which pathform accepts. (2) brief_fields `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]` (`lib:298`), where pathform already short-circuits. (3) check_brief, where `if ! pathform "$a"; then echo "skip ...: not an allowed path form"; return; fi` (`lib:331`) runs before `e="$(main_entry "$a")"` (`lib:336`). (4) check_answer `for f in docs/working/questions.md docs/working/questions-archive.md; do e="$(main_entry "$f")"` (`lib:555-556`), constant paths that pathform accepts. dev-cycle.sh has no direct call (rg). No caller can therefore reach the new arm. The only other output change is `echo "skip $a: the open briefs on the default branch could not be listed"` (`scripts/build-loop.sh:343`). B1 passes 94/94.

**Evidence:** `scripts/build-loop.sh:125-142,343`, `scripts/lib/dev-cycle-read.sh:293-298,325-337,551-557`, `$S/logs/worktree-suites.txt`

---

## Claim 16: T3's added step asserts the slots line for a file that is not read

**Location:** `test/scripts/build-loop-read.bats:55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unbalanced-fence reason reaching SLOTS_LINE. Does not cover the other unread reasons (shared code path `:215-216`).

`[ "$(line slots)" = "slots 3 default: the code fence opened at line 1 of docs/dev-cycle.md is never closed, so the file is not read" ]` (`:55`). M5 (SLOTS_LINE always "no docs/dev-cycle.md") fails T3 at :55.

**Evidence:** `test/scripts/build-loop-read.bats:53-55`, `scripts/build-loop.sh:214-218`, `$S/logs/M5-slots-unread.txt`

---

## Claim 17: "A never list the copy count misses (a checked task box) is skipped; with no exact never line beside it, self-merge is off."

**Location:** `test/scripts/build-loop-read.bats:118-119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code behaviour the comment states (P1: `- [x]` alone → `never none: no line starts`, policy off). Does not establish that the step tells "skipped" from "counted and malformed": it asserts only the policy line, and M24 (box counted) passes. This is the existing Won't-Fix row for the "ignored" arm, so it is not re-filed.

`settings 'Build-loop policy: self-merge' '- [x] Self-merge never: b/'; settings_is policy "$no"` (`:120`). P1's `valid=no [- [x] ...]` cell prints `never none: no line starts "Self-merge never:"` and policy `review unset`.

**Evidence:** `test/scripts/build-loop-read.bats:118-120`, `$S/logs/p1-never.txt`, `$S/logs/M24-checkedbox-counted.txt`

---

## Claim 18: A bare "success:" line does not satisfy a hard constraint (6c83af2a C9)

**Location:** `test/scripts/build-loop-read.bats:185-186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `success: [^ \t]` requirement. Does not cover a `success:` followed only by blanks (same regex, not run).

`constraints '- S1: a' '- H1: b' '  success:'` expects `nosuccess` (`:185-186`). Code: `/^[ \t]*(- )?success: [^ \t]/ { pend = "" }` (`scripts/build-loop.sh:184`). M7 fails at :186.

**Evidence:** `test/scripts/build-loop-read.bats:185-186`, `$S/logs/M7-bare-success.txt`

---

## Claim 19: A fenced H2 is skipped, so constraints are ok (6c83af2a C9)

**Location:** `test/scripts/build-loop-read.bats:189-190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fenced `H<n>:` line. Does not establish that this step is the first to catch total removal of the fence skip: M8 fails earlier, at :178.

M8b, which counts fenced `H<n>:` lines only, fails at :190 (`constraints ok 1-hard 0-soft` expected).

**Evidence:** `test/scripts/build-loop-read.bats:189-190`, `scripts/build-loop.sh:170-192`, `$S/logs/M8b-fenced-Hline-counts.txt`, `$S/logs/M8-fenced-H2.txt`

---

## Claim 20: A 1-character stopped reason is read (6c83af2a C9)

**Location:** `test/scripts/build-loop-read.bats:257-259`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the optional group in `[!-~]([ -~]{0,118}[!-~])?`. Does not cover the 120 bound (existing `${r120}` steps).

M9 (2+ characters required) fails at :259 with `skip ... not a marker`.

**Evidence:** `test/scripts/build-loop-read.bats:257-259`, `scripts/build-loop.sh:300`, `$S/logs/M9-1char.txt`

---

## Claim 21: "A marker whose message body holds a NUL byte (one commit ahead, same tree)." Its fixture, update-ref and check are separate lines, so a broken fixture fails T7

**Location:** `test/scripts/build-loop-read.bats:297-301`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the deleted NUL check (M1), a broken fixture together with the deleted check (M2), and a broken fixture alone (M2b). Does not establish any NUL position other than the body.

The fixture is built with `tree <base tree>` and `parent <base>`, so it is the same tree and one commit ahead (`:298`). M1 fails at :301 with `[nul] ok ... ready`. M2 and M2b fail at :299: `git hash-object ... --literallyX` exits 129 and set -e stops the test.

**Evidence:** `test/scripts/build-loop-read.bats:269-301`, `scripts/build-loop.sh:288`, `$S/logs/M1-nulcheck.txt`, `$S/logs/M2-nul+fixture.txt`, `$S/logs/M2b-fixture-only.txt`

---

## Claim 22: U1d --settings title: "reasons, review with a malformed never line, the next-line rule, an absent file, a caller's config"; ":420 Under review a malformed never line leaves the policy as written."

**Location:** `test/scripts/build-loop-read.bats:414,420`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title item through a failing mutant (M19, M21, M6, M5b, M4b). The two reason strings are checked statically against `scripts/build-loop.sh:241-242`. Does not establish anything beyond the asserted lines.

`why="lists entry $i, which is not an allowed glob form"` and `why="lists entry $i twice"` (`scripts/build-loop.sh:241-242`) match the expected strings at :417 and :419. M19 (malformed never turns review off) fails at :422.

**Evidence:** `test/scripts/build-loop-read.bats:414-422`, `$S/logs/M19-review-malformed.txt`

---

## Claim 23: "The next line outside a fence decides; a whitespace-only line is blank."

**Location:** `test/scripts/build-loop-read.bats:423`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both fence halves (blank after the fence, so set; `b/` after the fence, so malformed) and the ` \t ` line. Does not cover CRLF blanks.

M21 fails at :425 and M6 (no tab) fails at :429.

**Evidence:** `test/scripts/build-loop-read.bats:423-429`, `$S/logs/M21-nextline-fence.txt`, `$S/logs/M6-tab.txt`

---

## Claim 24: The absent file's slots line

**Location:** `test/scripts/build-loop-read.bats:430-431`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `why="no $f on the default branch"` reaching SLOTS_LINE. Does not cover anything else.

M5b (`SLOTS_LINE="slots 3 default: $FILE_WHY"`) fails at :431.

**Evidence:** `test/scripts/build-loop-read.bats:430-431`, `scripts/build-loop.sh:215-216`, `$S/logs/M5b-slots-absent.txt`

---

## Claim 25: "A caller's own GIT_CONFIG_COUNT does not stop the guard (that the caller's pairs still reach git is asserted in the --status deferred-cases test)."

**Location:** `test/scripts/build-loop-read.bats:432-433`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the split exactly: M4b (no guard when the caller set a count) fails this test at :438. M4 (`cfg=0`, which overwrites the caller's pair) passes this test and fails the --status test at :478. Does not establish the zero-padded or `git -c` routes the code comment at `scripts/build-loop.sh:114-115` mentions.

`cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))` (`scripts/build-loop.sh:116`).

**Evidence:** `test/scripts/build-loop-read.bats:432-438,476-478`, `$S/logs/M4-cfg0.txt`, `$S/logs/M4b-caller-stops-guard.txt`

---

## Claim 26: "build-loop.sh -h and --help print the header from its first line through its last (U1d)"

**Location:** `test/scripts/build-loop-read.bats:441-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first and last lines and both flags. Does not assert the middle lines (a dropped middle line would pass).

M18a (from line 3), M18b (ends at `# Exit`) and M18c (`-h` removed) each fail. Run H confirms that `lines[0]` and the last line match the asserted prefix and suffix.

**Evidence:** `test/scripts/build-loop-read.bats:441-447`, `$S/logs/M18a-bl-help-start3.txt`, `$S/logs/M18b-bl-help-stopExit.txt`, `$S/logs/M18c-bl-help-onlylong.txt`

---

## Claim 27: "No open brief on main at all (git grep exits 1): a done brief reads normally. (A done brief never reads F31's answer, so this cannot tell exit 1 from a failure.)"

**Location:** `test/scripts/build-loop-read.bats:451-452`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment's own admission: M20 (`rc -gt 0` fails closed) passes the whole suite. Does not establish that exit 1 is pinned anywhere (it is not).

At this step the only brief is done, so git grep lists nothing (exit 1). shared_branches still runs (`[[ -n "$SHARED_BRANCHES" ]] || shared_branches`, `scripts/build-loop.sh:328`), but both readers of its answer are gated on `st == open` (`:343-344`), which supports "never reads F31's answer (F31 still runs)" (07c354c5 A13).

**Evidence:** `test/scripts/build-loop-read.bats:449-455`, `scripts/build-loop.sh:326-346`, `$S/logs/M20-rc-gt0.txt`

---

## Claim 28: "A done brief sharing an open brief's branch does not make the open one skip, even with a later "Status: open" line that git grep lists (F31's own filter)."

**Location:** `test/scripts/build-loop-read.bats:456-457`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers F31's `BRIEF[status] == "Status: open"` term. Does not establish anything else about the loop's filters.

M3 fails at :462 with `skip ...: another open brief`.

**Evidence:** `test/scripts/build-loop-read.bats:456-462`, `scripts/build-loop.sh:320`, `$S/logs/M3-f31-filter.txt`

---

## Claim 29: Dispatched 0 and 99 (6c83af2a C9)

**Location:** `test/scripts/build-loop-read.bats:453,460`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 3.

M11 fails at :455 and M10 fails at :462.

**Evidence:** `$S/logs/M10-disp99.txt`, `$S/logs/M11-disp0.txt`

---

## Claim 30: "Another open brief (CRLF line endings) on the same branch counts."

**Location:** `test/scripts/build-loop-read.bats:463-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git grep's `\r?` arm (M12 fails at :466). Does not establish that a fixture failure is caught: the step is still `brief p ... && printf '...\r\n...' > "$B" && commit_all crlf`, and with the `printf` failing plus M12, the test passes (M23), because brief p's LF copy counts instead. See Claim 50.

**Evidence:** `test/scripts/build-loop-read.bats:463-466`, `scripts/build-loop.sh:315`, `$S/logs/M12-crlf.txt`, `$S/logs/M23-crlf-fixturefail+nocrlf.txt`

---

## Claim 31: "A directory whose name merely contains "closed" is not closed/."

**Location:** `test/scripts/build-loop-read.bats:468-471`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the revert to `${f/closed\//}` (M13b fails at :471). Does not catch dropping only the `#` (M13a passes, a behaviour-equivalent mutant for listed paths). The step is a `mkdir && printf && commit_all` chain, and with `mkdir` failing plus M13b it passes (M22). See Claim 50.

`isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"` (`scripts/build-loop.sh:319`). The dir `2026-10-0closed` + `1-x.md` becomes `2026-10-01-x.md` under the unanchored strip, which isbrief accepts.

**Evidence:** `test/scripts/build-loop-read.bats:468-471`, `$S/logs/M13b-strip-closed.txt`, `$S/logs/M13a-drop-hash.txt`, `$S/logs/M22-closeddir-fixturefail+unanchor.txt`

---

## Claim 32: "Another open brief on another branch, read by F31 after o, leaves o's fields alone."

**Location:** `test/scripts/build-loop-read.bats:472-475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the observable property: o's own fields after F31 has read q. M14b (no local BRIEF and the call moved after brief_fields) fails at :475 with `feat/q ... 3`. Does not pin the local `BRIEF=()` alone (M14a passes), which is the deferred 2026-10-06 row.

**Evidence:** `test/scripts/build-loop-read.bats:472-475`, `scripts/build-loop.sh:309,328,333`, `$S/logs/M14a-nolocalBRIEF.txt`, `$S/logs/M14b-nolocal+move.txt`, `$S/logs/M14c-move-only.txt`

---

## Claim 33: "A caller's own GIT_CONFIG_COUNT pair still reaches git beside the guard pair."

**Location:** `test/scripts/build-loop-read.bats:476-478`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 25 (M4 fails at :478).

**Evidence:** `$S/logs/M4-cfg0.txt`

---

## Claim 34: "A NUL byte refuses the brief, naming the line."

**Location:** `test/scripts/build-loop-read.bats:479-482`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers FENCE_AWK's NUL refusal through --status. Does not establish anything new about marker NULs (Claim 21).

M15 (the refusal removed) fails at :482. The output becomes `ok ... feat/nx ...`, with the NUL dropped into the value.

**Evidence:** `test/scripts/build-loop-read.bats:479-482`, `scripts/lib/dev-cycle-read.sh:218`, `$S/logs/M15-fence-nul.txt`

---

## Claim 35: "--check-brief, --check-branch and --check-answer need a default branch found by name; the others do not"

**Location:** `test/scripts/dev-cycle.bats:813-821`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh's gate at :193 for all three modes. "The others do not" is shown by --check-path only.

M17 (`--check-answer` dropped from `if [[ "$CHECK" == --check-brief || ... || "$CHECK" == --check-answer ]] && ! main_by_name`) fails at :818.

**Evidence:** `scripts/dev-cycle.sh:193`, `$S/logs/M17-checkanswer-gate.txt`

---

## Claim 36: "-h and --help print the header from its first line through its last"

**Location:** `test/scripts/dev-cycle.bats:1322-1328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 26, for dev-cycle.sh.

M18d, M18e and M18f each fail.

**Evidence:** `$S/logs/M18d-dc-help-start3.txt`, `$S/logs/M18e-dc-help-stopExit.txt`, `$S/logs/M18f-dc-help-onlylong.txt`

---

## Claim 37: "main_entry answers error for a path pathform refuses (U1d)"

**Location:** `test/scripts/dev-cycle.bats:1330-1337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four forms the test passes. `../x` already answered error before U1d, while the other three did not. Does not establish `.git` parts (P4 covers those outside the suite).

M16 fails (`absent error absent absent`).

**Evidence:** `$S/logs/M16-guard-revert.txt`

---

## Claim 38: 83cdb005 Code: "main_entry checks the path's form itself (pathform) as well as main_by_name; either failing is error (U1a C16). --status' "could not be listed" skip drops "(git grep failed)""

**Location:** `scripts/lib/dev-cycle-read.sh:265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claims 14-15. `rg 'git grep failed'` outside docs/reviews finds no remaining copy.

**Evidence:** `scripts/build-loop.sh:343`, `$S/logs/p4-main-entry.txt`

---

## Claim 39: 83cdb005 Wording bullets (U1a A19-A22, C19; U1b A25-A27; U1c A24, A25, C37)

**Location:** `scripts/build-loop.sh:14-75`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against 83cdb005's own text (`git show 83cdb005:scripts/build-loop.sh`: "with no exact never line beside it, turns it off") and the HEAD text it led to. The never-line wording was later rewritten (6c83af2a A3, 07c354c5 A12); the phrase survives in the test comment at :118-119.

**Evidence:** `scripts/dev-cycle.sh:59,111`, `scripts/lib/dev-cycle-read.sh:13-14,252-261`, `scripts/build-loop.sh:71-75,147-149,311-314`

---

## Claim 40: 83cdb005 "Tests (U1b C10-C12, U1c C17, C18, C26, C28, C39, and U1a C16)"

**Location:** commit 83cdb005 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** True of the branch at HEAD. At 83cdb005 itself, U1c C17 (marker_kind's commit-NUL check) and C18 (F31's own filter) were not reached: iteration-1 rubric rows A11 and A1, fixed in 6c83af2a. Not a new finding.

`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u1d.md:68` (A11: "`marker_kind`'s commit-NUL check ... can be deleted with the suite green") and `:58` (A1: "git grep never lists that brief"). At HEAD, M1 and M3 fail the suite.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u1d.md:58,68`, `$S/logs/M1-nulcheck.txt`, `$S/logs/M3-f31-filter.txt`

---

## Claim 41: 83cdb005 "Mutants that drop the local BRIEF (moving the call), or un-anchor the closed/ prefix, fail the new --status test."

**Location:** commit 83cdb005 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers M14b and M13b, the pre-13380172 `${f/closed\//}`, run on 83cdb005's own tree (C83) and on HEAD. Does not cover a mutant that drops only `#` (M13a, equivalent).

C83: `M13b@83cdb005: not ok 19 --status: deferred cases ...` and `M14b@83cdb005: not ok 16 ... not ok 19 ...`.

**Evidence:** `$S/logs/c83-mutants.txt`, `$S/logs/M13b-strip-closed.txt`, `$S/logs/M14b-nolocal+move.txt`

---

## Claim 42: 83cdb005 "118 changed code lines."

**Location:** commit 83cdb005 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Measured with pr-prep step 1a's command (`git diff --numstat BASE...C -- ':(top)' ':(top,exclude)docs/'`, both columns summed).

Results: 83cdb005 gives 118, 6c83af2a gives 151, 07c354c5 gives 180, and HEAD ab71bce5 against main gives 180 (the merge adds 0). HEAD's 180 is under the 400 cap.

**Evidence:** `workflows/pr-prep.md:86-92`

---

## Claim 43: 6c83af2a "A11/G1: T7 commits a marker whose body holds a NUL ... deleting marker_kind's NUL check now fails T7 (row 291 C17 closed)."

**Location:** commit 6c83af2a message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The row reference is checked: override-log line 291 is "The NUL refusal and F31's open-only filter are untested in build-loop-read.bats (... iteration 2 C17, C18)", and C17 is identified as marker_kind's check by rubric A11. "Closed" means the gap is covered; the append-only row itself still reads Defer.

M1 fails T7.

**Evidence:** `docs/reviews/override-log.md:291`, `$S/logs/M1-nulcheck.txt`

---

## Claim 44: 6c83af2a "A1/G2: brief d gets a later "Status: open" line ... dropping that filter now fails the U1d test (row 291 C18 closed)."

**Location:** commit 6c83af2a message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 28.

**Evidence:** `$S/logs/M3-f31-filter.txt`

---

## Claim 45: 6c83af2a A6, A7/A10, C9 test bullets

**Location:** commit 6c83af2a message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** A6 is Claim 33. A7/A10 are Claims 16, 23 and 26 (at 6c83af2a the build-loop help test already looped `-h --help`). C9 is Claims 18-20 and 29.

**Evidence:** see the cited claims

---

## Claim 46: 6c83af2a Wording bullets A3, A4, A5, C1, C8, C7, "A2, A8, A9, A7: test comments and titles say only what they assert"

**Location:** commit 6c83af2a message
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** A4, A5, C1 and C8 hold at 6c83af2a and at HEAD. Three bullets were inexact at 6c83af2a and are exact only at HEAD, so this is history only. (1) A3's text listed "a task box" among the copies the count misses, but an unchecked box is counted (P1). Fixed by 07c354c5 A12. (2) C7's build-loop comment was a trailing `# the header: from line 2 ...` without "(no fixed range to go stale)". Fixed by 07c354c5 C15. (3) "Say only what they assert": iteration 2 then found "never consults F31" and the :118 comment. Fixed by 07c354c5 A13 and C14. At HEAD, the residues are only the dispositioned ones (Claims 17 and 32).

`git show 6c83af2a:scripts/build-loop.sh` line 18-19: `(bold, a list marker) is a second copy and turns self-merge off; one it misses (a task box, a fence) is ignored`.

**Evidence:** `scripts/build-loop.sh:17-21,102`, `$S/logs/p1-never.txt`

---

## Claim 47: 6c83af2a Notes: "151 changed code lines (cap 400). Tests: build-loop-read 19, dev-cycle 73, hermeticity lint green; shellcheck clean." Also the claim that mutants were checked by hand.

**Location:** commit 6c83af2a message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The counts come from `grep -c '^@test'` at 6c83af2a (19 and 73) and from step 1a (151). The hermeticity and shellcheck results were re-run at HEAD, not at 6c83af2a. The shellcheck scope is the project's (`.sh`/`.bash`, health-check step 6). A `.bats` run shows one pre-existing SC2016 info at build-loop-read.bats:134 (from 1d79ffef, not this branch).

**Evidence:** `$S/logs/worktree-suites.txt`, `$S/logs/shellcheck.txt`, `scripts/health-check.sh:34`

---

## Claim 48: 07c354c5 A12, A13, C14, C15, C16, C17

**Location:** commit 07c354c5 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** A12 is Claim 1, A13 is Claim 27, C14 is Claim 17 (line 118 is correct), C15 is Claims 6 and 10, C16 is Claim 36, and C17 is Claims 12-13.

**Evidence:** see the cited claims

---

## Claim 49: 07c354c5 C13: "T7's NUL-marker step is no longer one && chain, so a fixture that fails to build fails the test instead of skipping its check (security F1; checked: with --literally broken and the NUL check deleted, T7 now fails)."

**Location:** commit 07c354c5 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 21 (M2, M2b).

**Evidence:** `$S/logs/M2-nul+fixture.txt`, `$S/logs/M2b-fixture-only.txt`

---

## Claim 50: 07c354c5 C13: "The two other new && chains are split too."

**Location:** commit 07c354c5 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Two chains were split: :257-258's `... && run` (the `update-ref && tip` pair remains) and :458-459's `printf && commit_all`. The sentence reads as if no new `&&` chain remains, but the U1d diff still adds fixture chains at :430, :436, :453, :460, :464, :467, :469 and :480. Two of these carry the same hazard as the one split at :458: a non-last command failing lets the check that follows pass on the wrong fixture. Demonstrated: M22 (the :469 `mkdir` fails, plus the closed/ regression) and M23 (the :464 `printf` fails, plus the CRLF regression) both pass. The probability is low, because the failing commands are `mkdir` and `printf` into the bats temp dir.

`brief p ... && printf 'Status: open\r\nBranch: feat/x\r\n' > "$B" && commit_all crlf` (`test/scripts/build-loop-read.bats:464`) and `mkdir -p docs/working/briefs/2026-10-0closed && printf ... && commit_all odd-dir` (`:469`).

**Evidence:** `test/scripts/build-loop-read.bats:430,436,453,460,464,467,469,480`, `$S/logs/M22-closeddir-fixturefail+unanchor.txt`, `$S/logs/M23-crlf-fixturefail+nocrlf.txt`

---

## Claim 51: 07c354c5 Notes: "build-loop-read 19, dev-cycle 73, hermeticity lint green; shellcheck clean."

**Location:** commit 07c354c5 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** 19 and 73 are from `grep -c '^@test'` at 07c354c5. The test run and shellcheck were run at HEAD (B1 94/94, SC exit 0). The merge ab71bce5 changes no code under scripts/ or test/ (`git diff 07c354c5 ab71bce5 --stat -- scripts test` is empty).

**Evidence:** `$S/logs/worktree-suites.txt`, `$S/logs/shellcheck.txt`

---

## Claim 52: Shared-context "94/94 pass at 07c354c5"

**Location:** test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, test/fixture-hermeticity.bats
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Run at ab71bce5, whose scripts/ and test/ match 07c354c5.

**Evidence:** `$S/logs/worktree-suites.txt`

---

## Claim 53: shared_branches' "(a superset: fences are not modelled); brief_fields then reads only those"

**Location:** `scripts/build-loop.sh:310-311`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the claim that git grep's `^Status: open\r?$` matches fenced lines too, and that the loop calls brief_fields only for listed files. Does not establish that every non-listed file is truly not open. A brief whose first Status line is `Status: open ` (trailing blank) is not listed, but its own status is not exactly open either.

The loop is `while IFS= read -r f; do ... brief_fields "$f" ... done <<<"$list"` (`scripts/build-loop.sh:317-322`).

**Evidence:** `scripts/build-loop.sh:315-322`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 50** (07c354c5 message, C13): "The two other new && chains are split too" reads as exhaustive. The U1d tests still add `&&` fixture chains, and those at `build-loop-read.bats:464` and `:469` let a regression pass if a non-last fixture command fails (M22, M23 pass). Tighten the wording (it was "two of the new chains"), or split :464 and :469 as :458-459 was. Low probability, test-strength class.
- **Claim 40** (83cdb005 message): listed U1c C17 and C18 as tested before they were. Already dispositioned as iteration-1 A11 and A1, and true at HEAD. History only.
- **Claim 46** (6c83af2a message): A3 ("a task box" missed), C7 (comment form) and "say only what they assert" were exact only after 07c354c5. History only.

### Unverifiable
(none)

## Goal-Alignment Note

The goal is to land U1d: every claim in the branch's comments, help, test titles and commit messages exact, and every test failing on the regression it names. All code-side claims (help, lib header, MAIN and main_entry comments, the shared_branches comment, every new test step and title) verified, most by execution. Of the 36 mutant runs (plus 2 on 83cdb005's tree), every one that a step's title, comment or commit message names fails that step. The survivors are M13a (equivalent), M14a (deferred), M14c (a control: the call moved, with the local BRIEF kept), M20 (the comment says so) and M24 (Won't-Fix), plus M22 and M23, which were built to show the remaining && hazard. main_entry has four callers, all of which pre-validate the path's form or pass constants, so the guard changes no caller's output. One wording item is new: 07c354c5's "the two other new && chains are split too" overstates. Two remaining fixture chains (:464 and :469) have the same skip-on-failure shape as the split one (Mostly accurate, low severity, test-strength class). The other two Mostly-accurate items are history already dispositioned. Nothing here blocks landing. U2 follows, and the deferred `badform` word and the main_entry error-as-refusal rule stay on its rows.
