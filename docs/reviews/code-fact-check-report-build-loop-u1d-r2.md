Commit: ab71bce5

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u1d, branch feat/build-loop-u1d)
**Scope:** `git diff main...HEAD -- scripts test` (scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats) and the commit messages of 83cdb005, 6c83af2a and 07c354c5. Replicate 2 of 3, final confirming pass.
**Checked:** 2026-10-06
**Total claims checked:** 38
**Summary:** 35 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim here matches a logged pattern, and none is a fabrication.

**Execution provenance (shared by every `executed` claim).** `S` = `/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/f-fc2`. The mutant harness is `bash $S/runmut.sh NAME SUITE FILTER [FILE OLD NEW]...`. It copies `$S/base` (a `git archive HEAD` of scripts/, test/lib, the two suites and docs/dev-cycle.md) to `$S/mut/NAME`, which is also its cwd. It applies each exact one-occurrence replacement with `$S/mut.py` (which aborts if OLD does not occur exactly once), then runs `timeout 600 bats -f FILTER test/scripts/SUITE`. The log goes to `$S/logs/NAME.log`. Each mutant's exit code, UTC timestamp and cwd are in `$S/mutants-summary.log`, which runs from 2026-10-06T05:25:54Z to 05:26:11Z. Unmutated baseline: `baseline-bl` exited 0 at 05:24:45Z. Full suites at HEAD: `bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/fixture-hermeticity.bats` in the worktree exited 0 at 2026-10-06T05:21:26Z with 94/94 ok (`$S/head-suite.log`). In this report, "fails" means bats exited 1 at the step named, read from that mutant's log, and "survives" means bats exited 0.

---

## Claim 1: "Self-merge also needs one valid never line. A never list in markup the copy count sees (bold, a list marker, an unchecked task box) counts as a copy, so self-merge is off; one it misses (a checked task box, a fence) is ignored, so self-merge rests on the valid line alone."

**Location:** `scripts/build-loop.sh:16-21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `**…:**` bold, `- `, `- [ ]`, `- [x]` and a fenced copy, each with and without an exact `Self-merge never: none` line, under `Build-loop policy: self-merge`. Does not establish other markup (e.g. `- [X]`, `* [x]`, HTML tags), which the help's "best effort" paragraph (`:41-44`) already concedes.

The copy count strips every non-letter and folds case (`build-loop.sh:156`: `s = tolower($0); gsub(/[^a-z]/, "", s); k = ""`), so `- [x] …` becomes `xselfmergenever…` and is missed. Probe results:

| markup line | no exact line | with exact line |
|---|---|---|
| `**Self-merge never:** none` | policy unset; never malformed: line 3 is not exactly… | policy unset; never malformed: more than one line (3 and 5) |
| `- Self-merge never: none` | same | same |
| `- [ ] Self-merge never: none` | same | same |
| `- [x] Self-merge never: none` | policy unset; never none: no line starts… | **policy self-merge set**; never none: line 3 |
| fenced copy | policy unset; never none: no line starts… | **policy self-merge set**; never none: line 3 |

**Evidence:** `scripts/build-loop.sh:150-166`, `:209-260`; command `timeout 300 bash $S/never-probe.sh` (cwd `$S/probe1`, exit 0, 2026-10-06T05:23Z), output `$S/never-probe.log`

---

## Claim 2: "A tip on a branch level with main, or whose subject does not start "handoff:", is working. DISPATCHED: the brief's "Dispatched: N" (0-99), or 0 without one."

**Location:** `scripts/build-loop.sh:64-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 0-ahead arm, the non-handoff subject arm and the 0/99 bounds. Does not establish anything about a branch behind main: it is also "0 ahead" and is therefore also read as working.

`loop=working` is set first, and `marker_kind` runs only `if [[ "$ahead" -gt 0 ]]` (`build-loop.sh:353-354`). `marker_kind` echoes `working` when `[[ "$subj" == handoff:* ]]` fails (`:287`). In the probe, a done brief whose branch sat at main's tip, which was the subject `handoff: bogus`, printed `ok … done review feat/d working …`. With the branch one ahead under the same subject, it printed the marker skip. The Dispatched regex `^Dispatched:\ (0|[123456789][0123456789]?)$` (`:338`) is pinned by M10a/M10b (Claim 22).

**Evidence:** `scripts/build-loop.sh:281-305`, `:326-366`; `timeout 300 bash $S/status-probe.sh` (cwd `$S/probe2`, exit 0, 2026-10-06T05:23Z), output `$S/status-probe.log`

---

## Claim 3: "skip BRIEF: … on a branch ahead of main the tip's subject (its message's first line) starts "handoff:" but it is not a marker, or, for an open brief only, another open brief on main (in briefs/ or closed/) names the same branch (ignoring case) or the open briefs on main could not be listed."

**Location:** `scripts/build-loop.sh:67-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which states each skip applies to. Does not establish the full list of `skip` reasons beyond those the sentence names; the earlier clauses (unreadable brief, bad Branch/Dispatched, refused branch name) were not re-probed here.

The marker check has no state guard. Only `ahead` gates it (`:354`): a **done** brief with a branch one ahead and tip `handoff: bogus` printed `skip …: the tip of feat/d starts "handoff:" but is not a marker: …`. Both F31 skips test `"$st" == open` first (`:343`, `:344`). In the probe, a done brief on a branch that two open briefs share (`feat/o`, `FEAT/O`) printed `ok`, and both open briefs skipped "(compared ignoring case)". Under `grep.patternType=bogus`, the done brief printed `ok` and the open one printed `skip …: the open briefs on the default branch could not be listed`.

**Evidence:** `scripts/build-loop.sh:333-366`; `$S/status-probe.log` (as Claim 2)

---

## Claim 4: "# The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale)." (build-loop.sh), and the identical comment in dev-cycle.sh

**Location:** `scripts/build-loop.sh:102`, `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sed range `2,/^[^#]/` with the `/^#/p` filter in both scripts. Does not establish behaviour for a header with no terminating line (the range would then run to EOF).

`sed -n '2,/^[^#]/{/^#/p}' "$0"`: an empty line has no first character, so `^[^#]` cannot match it, and the range ends at the first non-empty line not starting with `#`. In both scripts that line is `set -euo pipefail` (build-loop.sh:84, after the empty line 83; dev-cycle.sh:83, after the empty line 82). Replacing the range with a fixed `2,70` (build-loop) or `2,79` (dev-cycle) fails each help test at its last-line assertion (M21b, M21d). The two comments are textually identical, and each sits on its own line.

**Evidence:** `scripts/build-loop.sh:102-103`, `scripts/dev-cycle.sh:111-112`; `$S/logs/M21b-bl-fixed-range.log`, `$S/logs/M21d-dc-fixed-range.log`

---

## Claim 5: "…the first two line numbers, whether the next line outside a fence after the first is blank or the end of the file (NEXT 1) or not…"

**Location:** `scripts/build-loop.sh:144-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fence skipping, the end-of-file default and whitespace-only lines as blank. Does not establish CR handling beyond the `sub(/\r$/, "")` that runs first.

```awk
# scripts/build-loop.sh:152-160
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
  ...
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0; nx[k] = 1; pk = k } ...
```
(excerpt ends :160; the program continues to its END block at :162-166, which was read.)

`nx[k] = 1` is the end-of-file default. Fence lines, and the lines inside a fence, `next` before the `pk` update. Moving the `pk` update above `fence()` fails the U1d settings test at `:425` (M19). Narrowing blank to `/^ *$/` fails it at `:429` (M06).

**Evidence:** `scripts/build-loop.sh:150-166`; `$S/logs/M19-fence-nextline.log`, `$S/logs/M06-tab-blank.log`

---

## Claim 6: "an exit above 1, a corrupt object's included, fails closed (SHARED_BRANCHES=error: every open brief skips). A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293)."

**Location:** `scripts/build-loop.sh:309-316`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a loose blob made missing or corrupt, under git 2.39.5. Does not establish packed-object corruption, or other git versions.

`if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi` (`:316`). In probe repos, brief z (open, `feat/x`) had its blob object deleted or overwritten:
- missing, with no other open brief: git grep printed `error: … unable to read …` and exited **1**; a's line read `ok`.
- missing, with open brief a on the same branch: git grep exited **0** and listed only a. a printed `ok … open review feat/x … 1`, not a skip, so z was not counted.
- corrupt: `fatal: loose object … is corrupt`, exit **128**. With a open, a printed `skip …: the open briefs on the default branch could not be listed`.

Override-log row 293 is "An unreadable open brief is not counted for F31 … Won't-Fix" (`docs/reviews/override-log.md:293`), which matches the clause it is cited for.

**Evidence:** `scripts/build-loop.sh:305-324`; `timeout 300 bash $S/grep-probe.sh` (cwd `$S/probe3`, exit 0, 2026-10-06T05:24Z), output `$S/grep-probe.log`

---

## Claim 7: "--status' "could not be listed" skip drops "(git grep failed)", matching the other reasons" (83cdb005, U1c C38)

**Location:** `scripts/build-loop.sh:343`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed text. Does not establish anything about consumers that matched the old suffix; no file outside docs/ references "(git grep failed)".

`echo "skip $a: the open briefs on the default branch could not be listed"; return` (`:343`). T28 asserts the exact string at `build-loop-read.bats:400`, and the U1d test asserts it at `:478`. Both pass at HEAD.

**Evidence:** `scripts/build-loop.sh:343`; `$S/head-suite.log`

---

## Claim 8: "(an answer only in the working tree is not seen: it reads what main's copy says until it lands there)"

**Location:** `scripts/dev-cycle.sh:57-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_answer's read source. Does not establish behaviour for an answer that has landed on a branch that is not the default branch.

check_answer reads `r="$(git cat-file blob "$MAIN_SHA:$f" | …)"` (`dev-cycle-read.sh:564`), after `main_entry "$f"` against `$MAIN_SHA`. It never reads the working tree.

**Evidence:** `scripts/lib/dev-cycle-read.sh:551-583`

---

## Claim 9: "caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves)"

**Location:** `scripts/lib/dev-cycle-read.sh:13-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `set` in the lib. Does not establish that callers do set `-euo pipefail` (both scripts do, at line 83).

`grep -n 'set -\|set +\|shopt'` over the lib finds exactly `:296 local - out l; set -o pipefail` (brief_fields) and `:552 … set -o pipefail  # as brief_fields` (check_answer), plus a comment at :28.

**Evidence:** `scripts/lib/dev-cycle-read.sh:293-296`, `:551-552`

---

## Claim 10: "(main_entry and brief_fields answer error)" without main found by name (lib header), and "check_brief, check_branch, check_answer, main_entry and brief_fields read its commit, so they answer only when it was found by name, never for the current branch's fallback or before resolve_main has succeeded (main_entry and brief_fields answer error)." (MAIN comment)

**Location:** `scripts/lib/dev-cycle-read.sh:23-25`, `:244-247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_entry's printed `error` and brief_fields' `BRIEF_ODD=error` with return 1, both before resolve_main and under the current-branch fallback. Does not establish check_brief, check_branch or check_answer's skip lines, which this branch did not change.

In a probe repo with `docs/x.md` on main, the sourced lib printed `main_entry=error` and `brief_fields rc=1 BRIEF_ODD=error` before resolve_main, and `blob` after it. On a `trunk`-only repo (fallback: `MAIN=trunk`, `MAIN_BY_NAME` empty) it printed `main_entry=error` and `BRIEF_ODD=error`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:249`, `:262-265`, `:298`; command `bash -c 'set -euo pipefail; source LIB; …'` (cwd `$S/probe4/r`, exit 0, 2026-10-06T05:27:59Z), output `$S/lib-probe.log`

---

## Claim 11: main_entry's comment: "error (no default branch found by name, a path pathform refuses, ls-tree failed, or the tree lists a name twice …). It runs main_by_name and pathform itself, before any read (pathform also means ls-tree prints the name unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:250-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard's position and effect. Does not establish the duplicate-name arm, which this branch did not change.

```bash
# scripts/lib/dev-cycle-read.sh:262-265
main_entry() {
  local p="" rest="$1" out mode path dup="" want=()
  local -A m=()
  if ! main_by_name || ! pathform "$1"; then echo error; return; fi
```
(excerpt ends :265; enclosing main_entry() continues to :279 — read.) The guard is the first statement, ahead of the `git ls-tree` at `:267`. pathform admits only `[A-Za-z0-9._/-]` (`:141-144`), none of which git's quotePath escapes. Deleting `|| ! pathform "$1"` (M15) makes the dev-cycle.bats U1d test print `absent / error / absent / absent`, so it fails at `:1336`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:141-152`, `:262-279`; `$S/logs/M15-main-entry-guard.log`

---

## Claim 12: Behaviour changes are only (a) main_entry's error for a refused path form and (b) the shorter could-not-be-listed text. Checked by enumerating main_entry's callers.

**Location:** `scripts/lib/dev-cycle-read.sh:298`, `:336`, `:556`; `scripts/build-loop.sh:128`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every caller in the tree outside docs/ (via `git grep -n main_entry -- ':!docs'`) and the full suites. Does not establish behaviour for out-of-tree callers (none known).

The callers are:
- brief_fields (`:298`): `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]`. pathform already ran, so nothing changes.
- check_brief (`:336`): `if ! pathform "$a"; then echo "skip …: not an allowed path form"` already ran at `:329`, so nothing changes.
- check_answer (`:556`): it passes only the constants `docs/working/questions.md` and `docs/working/questions-archive.md`, which pathform accepts.
- build-loop.sh main_file (`:128`): it passes only `docs/dev-cycle.md` and `docs/constraints.md`.

pathform has no side effects and calls no external commands (`:142-152`). The remaining hits are comments and tests (dev-cycle.bats:1078, :1234-1235, :1332). The diff's only other non-comment script change is `:343`. The full suites pass at HEAD (94/94).

**Evidence:** `scripts/lib/dev-cycle-read.sh:293-298`, `:325-336`, `:551-556`; `scripts/build-loop.sh:125-128`; `$S/head-suite.log`

---

## Claim 13: T3's new step asserts the slots line for a file that is not read (6c83af2a A10: "T3 asserts the slots line for an unread file")

**Location:** `test/scripts/build-loop-read.bats:55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unread-file (unbalanced-fence) arm only. Does not establish the other not-read reasons.

`[ "$(line slots)" = "slots 3 default: the code fence opened at line 1 of docs/dev-cycle.md is never closed, so the file is not read" ]`. Mutant M05 changes SLOTS_LINE only when `FILE_WHY` is not `absent`, and T3 fails at `:55`.

**Evidence:** `scripts/build-loop.sh:216`; `$S/logs/M05-unread-slots.log`

---

## Claim 14: "# A never list the copy count misses (a checked task box) is skipped; with no exact never line beside it, self-merge is off."

**Location:** `test/scripts/build-loop-read.bats:118-119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `- [x]` line with no exact line (the step at :120). Does not establish the "beside an exact line" case, which this step does not assert (Claim 1's probe does).

The step at :120 is `settings 'Build-loop policy: self-merge' '- [x] Self-merge never: b/'; settings_is policy "$no"`. The probe's `- [x]` / no-exact row printed `never none: no line starts "Self-merge never:"` (skipped) and policy unset.

**Evidence:** `test/scripts/build-loop-read.bats:118-120`; `$S/never-probe.log`

---

## Claim 15: "a bare "success:" line" (6c83af2a C9), the T44 step `constraints '- S1: a' '- H1: b' '  success:'`

**Location:** `test/scripts/build-loop-read.bats:185-186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a success regex that accepts a bare `success:`. Does not establish `success:` followed by blanks only.

Mutant M07 (`/^[ \t]*(- )?success:/`) makes the file read `constraints ok 1-hard 1-soft`, and T44 fails at `:186`. Without the added `'  success:'` line the old step could not see this mutant.

**Evidence:** `scripts/build-loop.sh:184`; `$S/logs/M07-bare-success.log`

---

## Claim 16: "a fenced H2 (constraints ok)" (6c83af2a C9)

**Location:** `test/scripts/build-loop-read.bats:189-190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fence skipping ahead of the constraint-ID rule. Does not establish that the step is the only one guarding fence handling: deleting `fence($0) { next }` outright (M08) already fails an earlier pre-existing step at `:178`.

Mutant M08b moves `fence($0) { next }` below the constraint-ID rule, so fenced IDs count while fence lines are still skipped elsewhere. It prints `constraints unreadable: hard constraint H2 (line 4) has no success: line …`, and T44 fails at the new step's assertion, `:190`.

**Evidence:** `scripts/build-loop.sh:170-181`; `$S/logs/M08b-fenced-H2-moved.log`, `$S/logs/M08-fenced-H2.log`

---

## Claim 17: "a 1-char stopped reason" (6c83af2a C9), T6 step `tip feat/a "handoff: stopped: x"`

**Location:** `test/scripts/build-loop-read.bats:257-259`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lower length bound of REASON. Does not establish the 120/121 bound, which pre-existing steps cover.

Mutant M09 (`'[!-~][ -~]{0,118}[!-~]'`, at least 2 chars) makes T6 fail at `:259` with the "is not exactly" skip.

**Evidence:** `scripts/build-loop.sh:300`; `$S/logs/M09-1char-reason.log`

---

## Claim 18: "T7 commits a marker whose body holds a NUL (written with hash-object --literally); deleting marker_kind's NUL check now fails T7 (row 291 C17 closed)" (6c83af2a A11/G1), and the comment "# A marker whose message body holds a NUL byte (one commit ahead, same tree)."

**Location:** `test/scripts/build-loop-read.bats:297-301`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit-object NUL check and row 291's C17. Does not establish a NUL in the subject line, which this fixture does not use.

The fixture is `printf 'tree %s\nparent %s\n…\n\nhandoff: ready\n\n\0x\n' "$(git rev-parse "$base^{tree}")" "$base" | git hash-object -t commit --literally -w --stdin`: one parent (base) and base's own tree. With `if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]…` deleted (M01), T7 fails at `:301`, and its output reads `ok … feat/a ready …`. At 83cdb005 the same deletion leaves the whole suite green (`old83-M01`, exit 0). Row 291 is "NUL refusal and F31's open-only filter … (iteration 2 C17, C18)", and U1c's iteration-1 rubric row C17 is "the NUL-byte refusal (`:279`) is untested … a hash-object NUL marker in T7".

**Evidence:** `scripts/build-loop.sh:288`; `docs/reviews/override-log.md:291`; `$S/logs/M01-nulcheck-del.log`; `$S/logs/old83-M01.log` (cwd `$S/old83-M01`, `timeout 600 bats test/scripts/build-loop-read.bats`, exit 0, 2026-10-06T05:29:00Z)

---

## Claim 19: "T7's NUL-marker step is no longer one && chain, so a fixture that fails to build fails the test instead of skipping its check (… checked: with --literally broken and the NUL check deleted, T7 now fails)." (07c354c5 C13, first part)

**Location:** `test/scripts/build-loop-read.bats:298-301`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the T7 NUL step. Does not establish the other new `&&` chains (Claim 34).

At HEAD, `--literally` → `--literallyX` fails T7 at `:299` (`failed with status 129`), with the NUL check present (M02a) or deleted (M02b). In a 6c83af2a copy with the same two edits (`$S/old6c`), T7 passes. That is the vacuous pass the split removed.

**Evidence:** `$S/logs/M02a-fixture-broken.log`, `$S/logs/M02b-fixture-broken+nulcheck-del.log`; `$S/logs/old6c-M02b.log` (cwd `$S/old6c`, `timeout 300 bats -f T7 …`, exit 0, 2026-10-06T05:27:08Z)

---

## Claim 20: U1d --settings test: title "reasons, review with a malformed never line, the next-line rule, an absent file, a caller's config" and its comments ":420 Under review a malformed never line leaves the policy as written.", ":423 The next line outside a fence decides; a whitespace-only line is blank.", ":432-433 A caller's own GIT_CONFIG_COUNT does not stop the guard (that the caller's pairs still reach git is asserted in the --status deferred-cases test)."

**Location:** `test/scripts/build-loop-read.bats:414-439`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one mutant per named case. Does not establish that the caller's pair reaches git from this test: as the comment says, `cfg=0` survives here.

Each mutant fails this test at the step named:
- M17a: entry index starting at 1 fails at `:417` (`lists entry 2, which is not an allowed glob form`).
- M17b: dropping the seen check fails at `:419` (`twice`).
- M18: `if [[ -z "$never_ok" ]]` fails at `:422` (review stays `set`).
- M19: the fence order fails at `:425`.
- M06: tab not blank fails at `:429`.
- M20: absent slots text fails at `:431`.
- M04c: `GIT_CONFIG_COUNT=${GIT_CONFIG_COUNT:-1}`, so the guard is ignored when the caller has a count, fails at `:438` with `policy self-merge set`.
- M04b (`cfg=0`) **survives** this test, which matches the comment's hand-off to the --status test (Claim 27).

**Evidence:** `scripts/build-loop.sh:116`, `:209-260`; `$S/logs/M17a-entry-index.log`, `M17b-twice-drop.log`, `M18-review-malformed.log`, `M19-fence-nextline.log`, `M06-tab-blank.log`, `M20-absent-slots.log`, `M04c-count-kept-settings.log`, `M04b-cfg0-settings.log`

---

## Claim 21: "build-loop.sh -h and --help print the header from its first line through its last (U1d)"

**Location:** `test/scripts/build-loop-read.bats:441-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0 and the first and last lines for both flags. Does not establish the lines in between, which the test does not compare.

The test loops `for h in -h --help`. Dropping `-h` from the case (M21a) fails it (`-h:` with empty output), and so does a fixed `2,70` range (M21b). The last header line is `# lib/dev-cycle-read.sh, or no default branch found by name.` (`build-loop.sh:82`).

**Evidence:** `$S/logs/M21a-bl-h-only.log`, `$S/logs/M21b-bl-fixed-range.log`

---

## Claim 22: "Dispatched 0 and 99" (6c83af2a C9), via briefs d (`Dispatched: 0`) and o (`Dispatched: 99`)

**Location:** `test/scripts/build-loop-read.bats:453-462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dropping `0|` and dropping the second digit. Does not establish leading-zero refusal (`00`).

M10a (no `0|`) fails at `:455` with the Dispatched skip. M10b (one digit) fails at `:462`.

**Evidence:** `scripts/build-loop.sh:338`; `$S/logs/M10a-dispatched0.log`, `$S/logs/M10b-dispatched99.log`

---

## Claim 23: "# No open brief on main at all (git grep exits 1): a done brief reads normally. # (A done brief never reads F31's answer, so this cannot tell exit 1 from a failure.)" (also 07c354c5 A13: "A done brief never reads F31's answer (F31 still runs).")

**Location:** `test/scripts/build-loop-read.bats:451-452`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment's own limit. Does not establish any test of the exit-1 arm, which remains unpinned (as the comment says).

`status_line` always runs `[[ -n "$SHARED_BRANCHES" ]] || shared_branches` (`:328`), but both reads of it are gated by `"$st" == open` (`:343-344`). Mutant M23 (`rc -gt 0`, so exit 1 fails closed) **survives** the whole test, exactly as the parenthesis says.

**Evidence:** `scripts/build-loop.sh:316`, `:326-346`; `$S/logs/M23-grep-rc-gt0.log`

---

## Claim 24: "# A done brief sharing an open brief's branch does not make the open one skip, even with a later "Status: open" line that git grep lists (F31's own filter)." / 6c83af2a A1/G2: "dropping that filter now fails the U1d test (row 291 C18 closed)"

**Location:** `test/scripts/build-loop-read.bats:456-462`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `BRIEF[status] == "Status: open"` term in shared_branches. Does not establish that T28 also guards it (it does not: M03b survives T28).

M03 drops the term, and the test fails at `:462` with `skip …-o.md: another open brief … names the same branch`. That output shows d was listed by git grep and counted. At 83cdb005 the same mutant leaves the suite green (`old83-M03`, exit 0), so C18 was opened then and is closed now.

**Evidence:** `scripts/build-loop.sh:320`; `$S/logs/M03-f31-status-filter-drop.log`, `$S/logs/M03b-f31-status-filter-drop-T28.log`, `$S/logs/old83-M03.log`

---

## Claim 25: "# Another open brief (CRLF line endings) on the same branch counts." and "# A directory whose name merely contains "closed" is not closed/."

**Location:** `test/scripts/build-loop-read.bats:463-470`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `\r?` in the git grep pattern and the `#` anchor of the closed/ substitution. Does not establish these steps' robustness to a failed fixture build (Claim 34).

M11 (`'^Status: open$'`) fails at `:466` because o is no longer skipped. M12 (`${f/closed\//}`) fails at `:471` because o is skipped.

**Evidence:** `scripts/build-loop.sh:315`, `:319`; `$S/logs/M11-crlf.log`, `$S/logs/M12-closed-unanchored.log`

---

## Claim 26: "# Another open brief on another branch, read by F31 after o, leaves o's fields alone." (title: "BRIEF kept")

**Location:** `test/scripts/build-loop-read.bats:472-474`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call order together with the local BRIEF. Does not establish the local BRIEF alone (deferred, U2/U3b row): dropping only the local (M13c) survives, and so does moving only the call (M13b).

M13a drops `BRIEF=()` from `local -A n=() BRIEF=()` and moves the shared_branches call below `brief_fields "$a"`. The test then fails at `:475` with `ok … open review feat/q absent - - 3`: q's fields, read last by F31.

**Evidence:** `scripts/build-loop.sh:309`, `:328-330`; `$S/logs/M13a-brief-local-drop+move.log`, `M13b-move-only.log`, `M13c-local-drop-only.log`

---

## Claim 27: "# A caller's own GIT_CONFIG_COUNT pair still reaches git beside the guard pair." (6c83af2a A6)

**Location:** `test/scripts/build-loop-read.bats:476-478`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `cfg="${GIT_CONFIG_COUNT:-0}"` index. Does not establish zero-padded or malformed caller counts.

M04a (`cfg=0`, so the guard overwrites the caller's KEY_0) fails at `:478` with `ok … open review feat/x … 99`: the caller's `grep.patternType=bogus` never reached git.

**Evidence:** `scripts/build-loop.sh:116`; `$S/logs/M04a-cfg0-status.log`

---

## Claim 28: "# A NUL byte refuses the brief, naming the line."

**Location:** `test/scripts/build-loop-read.bats:479-482`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers FENCE_AWK's NUL refusal on the --status path. Does not establish marker_kind's commit NUL (Claim 18).

M14 disables `if (index(l, "\0")) { refuse("nul"); return 1 }`, and the test fails at `:482` with `ok …-n.md open review feat/nx …`: the NUL was dropped into the value. The `\x01` placeholder in the first `brief n` line means a failed overwrite would print a branch-name skip, not this line.

**Evidence:** `scripts/lib/dev-cycle-read.sh:218`; `$S/logs/M14-fence-nul-del.log`

---

## Claim 29: "--check-brief, --check-branch and --check-answer need a default branch found by name; the others do not"

**Location:** `test/scripts/dev-cycle.bats:813-824`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script-level guard for the three modes. Does not establish "the others" beyond `--check-path`, the only other mode the test runs.

The guard is `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name` (`dev-cycle.sh:193`). Dropping `--check-answer` from it (M16) fails the test at `:818` (`[ "$status" -eq 1 ]`): check_answer then answers "not a question ID" with exit 0.

**Evidence:** `scripts/dev-cycle.sh:193-194`; `$S/logs/M16-check-answer-guard.log`

---

## Claim 30: "-h and --help print the header from its first line through its last" (dev-cycle.bats; 07c354c5 C16)

**Location:** `test/scripts/dev-cycle.bats:1322-1328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0 and the first and last lines for both flags. Does not establish the lines in between.

M21c (`--help)` only) and M21d (fixed `2,79`) each fail it at `:1326`.

**Evidence:** `$S/logs/M21c-dc-h-only.log`, `$S/logs/M21d-dc-fixed-range.log`

---

## Claim 31: "main_entry answers error for a path pathform refuses (U1d)"

**Location:** `test/scripts/dev-cycle.bats:1330-1337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard with main found by name (setup's `make_repo "$R" main`). Does not establish that every input exercises the guard: `../x` gives `error` even without it (ls-tree fails), so only `a"b.md`, `-x` and `docs//x.md` distinguish.

Without the guard (M15) the output is `absent / error / absent / absent`, which fails the test.

**Evidence:** `$S/logs/M15-main-entry-guard.log`

---

## Claim 32: 83cdb005 Code and Wording bullets: "main_entry checks the path's form itself (pathform) as well as main_by_name; either failing is error"; the --check-answer title/loop; "until it lands there"; the help range; main_entry's comment; the pipefail note; "with no exact never line beside it"; NEXT; the help-range comment; the marker skip "on a branch ahead of main"; "could not be listed" in the skip list; the F31 exit-above-1 comment.

**Location:** commit 83cdb005 (message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against 83cdb005's own diff and against HEAD. Does not establish the exact 83cdb005 wording of the never-line rule at HEAD: 6c83af2a and 07c354c5 rewrote it (Claim 1).

At 83cdb005 the help read `Self-merge also needs a valid never line, so a never list hidden in markup, with no exact never line beside it, turns it off.` (`git show 83cdb005:scripts/build-loop.sh`, lines 17-18). Each other bullet is present at HEAD as described in Claims 3-11 and 29 (paraphrased — no quote available because the bullets span the five files already quoted in those claims).

**Evidence:** `scripts/build-loop.sh:16-21`, `:71-75`, `:102`, `:144-149`, `:309-316`; `scripts/dev-cycle.sh:59`, `:111`; `scripts/lib/dev-cycle-read.sh:13-14`, `:250-265`

---

## Claim 33: 83cdb005 Tests bullet "(U1b C10-C12, U1c C17, C18, C26, C28, C39, and U1a C16)" with "a NUL byte in a brief" and "a done brief sharing an open brief's branch"

**Location:** commit 83cdb005 (message)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers U1c C17 and C18 as of 83cdb005. Does not reopen them: 6c83af2a closes both (Claims 18, 24), and iteration 1 recorded this as A11/A1.

At 83cdb005 neither gap was closed. Deleting marker_kind's NUL check (C17) and dropping F31's status filter (C18) each leave the full build-loop-read suite green (`old83-M01`, `old83-M03`, exit 0). The "NUL byte in a brief" step tests FENCE_AWK, not marker_kind. Iteration 1 already filed this, and it is fixed, so it is not a new finding.

**Evidence:** `$S/logs/old83-M01.log`, `$S/logs/old83-M03.log` (cwd `$S/old83-M01`, `$S/old83-M03`; `timeout 600 bats test/scripts/build-loop-read.bats`; exit 0; 2026-10-06T05:29Z)

---

## Claim 34: "The two other new && chains are split too." (07c354c5 C13, second part)

**Location:** commit 07c354c5 (message); `test/scripts/build-loop-read.bats:257`, `:458-459`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two chains 07c354c5 split, and three of the eight new fixture-building `&&` chains that remain. Does not establish the other five remaining chains (not mutated).

The two chains it names were split: `tip … "handoff: stopped: x"` is no longer chained to `run`, and `printf … > "$d"` is no longer chained to `commit_all d-later-open`. But "the two other" reads as if no other new chain remains. Eight new fixture chains remain in the branch, for example `:465 brief p … && printf 'Status: open\r\n…' > "$B" && commit_all crlf`. At least three have the same vacuous-pass shape C13 fixed in T7: when a fixture step fails, the next assertion passes on stale state, so the mutant it targets survives.
- V1: `git replace --bogus …` at `:436` together with guard mutant M04c survives (exit 0). Without the replace ref, main's blob already reads `review`.
- V2: the odd-dir `printf` redirected to a missing directory (`:469`) together with the unanchor mutant M12 survives.
- V3: the CRLF overwrite redirected to `"$B/no"` (`:465`) together with the CRLF mutant M11 survives. The LF copy brief p wrote first still makes o skip.

These need a fixture command to fail, so the risk is Low. It is the same class as the iteration-2 security Low.

**Evidence:** `test/scripts/build-loop-read.bats:436`, `:465`, `:469`; `$S/logs/V1-replace-broken+guard-mutant.log` (exit 0, 2026-10-06T05:27:17Z), `$S/logs/V2-odddir-broken+unanchor-mutant.log` (exit 0, 05:27:07Z), `$S/logs/V3-crlf-overwrite-broken+crlf-mutant.log` (exit 0, 05:27:24Z); cwd `$S/mut/V*`

---

## Claim 35: 83cdb005 "Mutants that drop the local BRIEF (moving the call), or un-anchor the closed/ prefix, fail the new --status test." and "Notes: 118 changed code lines."

**Location:** commit 83cdb005 (message)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both mutants at 83cdb005 and at HEAD, and the count by pr-prep step 1a. Does not establish the local-only mutant (deferred).

In an 83cdb005 copy, M13a fails the then-titled test "deferred cases: NUL, …" at `:457`, and M12 fails it at `:453`. Both also fail at HEAD (Claims 25, 26). `git diff --numstat main...83cdb005 -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` prints **118**.

**Evidence:** `$S/logs/old83-M12.log`, `$S/logs/old83-M13a.log` (exit 1, 2026-10-06T05:29:52-53Z); `workflows/pr-prep.md:86-92`

---

## Claim 36: 6c83af2a's remaining bullets: A6, A7/A10, C9, Wording A3, A4, A5, C1, C8, C7, A2/A8/A9; "Mutants checked by hand …: marker_kind's NUL line deleted fails T7; F31's status term dropped fails the U1d test."; "151 changed code lines (cap 400). Tests: build-loop-read 19, dev-cycle 73, hermeticity lint green"

**Location:** commit 6c83af2a (message)
**Type:** Reference / Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the code (Claims 1, 3, 6, 10-11, 13, 15-18, 20-22, 24, 27) and the counts. Does not establish the shellcheck clause (Claim 37).

The pr-prep 1a count against 6c83af2a's base (merge-base 9f78df7e) prints **151**. `bats --count` on 6c83af2a's suites prints 19 and 73. At 6c83af2a the build-loop help test already looped `for h in -h --help` (line 437). The hermeticity lint passes at HEAD (`$S/head-suite.log`, tests 93-94 ok).

**Evidence:** `git diff --numstat main...6c83af2a …` (cwd worktree, exit 0); `$S/c6c` counts; `$S/head-suite.log`

---

## Claim 37: "shellcheck clean" (6c83af2a and 07c354c5 Notes)

**Location:** commits 6c83af2a, 07c354c5 (messages)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the changed `.sh`/`.bash` files, which are clean, and the changed `.bats` files, which are not. Does not establish health-check's whole-repo run.

`shellcheck` exits 0 on scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh and test/lib/build-loop-fixtures.bash. That is the scope of the repo gate: `scripts/health-check.sh:34` is "shellcheck passes on all .sh/.bash files". The two changed `.bats` files exit 1. Against main they add exactly one finding: SC2016 (info) at `test/scripts/dev-cycle.bats:1331`, the new main_entry test's `bash -c '…'`, which is intentional single quoting. The other 20 findings predate the branch. The claim holds for the gated scope but is unqualified.

**Evidence:** `scripts/health-check.sh:34`, `:427-455`; `$S/shellcheck.log` (2026-10-06T05:28Z), `$S/sc-main.txt`, `$S/sc-head.txt`

---

## Claim 38: 07c354c5 A12, C14, C15, C17 and Notes: "names an unchecked task box as counted (a copy, so self-merge off) and only a checked one as missed; "valid" never line, matching the printed reason"; ":118 says a checked task box is skipped"; the help-range comment "moves to its own line"; "the MAIN comment names main_entry and brief_fields; the header paragraph is re-wrapped"; "build-loop-read 19, dev-cycle 73, hermeticity lint green"

**Location:** commit 07c354c5 (message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet at HEAD. Does not establish A13 and C13, which are in Claims 23, 19 and 34.

The printed reason is `… there is no valid Self-merge never: line …` (`build-loop.sh:255`), matching "valid". The task-box behaviour matches Claim 1's probe. The comment at :118 is Claim 14. `build-loop.sh:102` is a comment on its own line. The MAIN comment is Claim 10. The counts are 19 and 73 (`bats --count`), and 94/94 pass.

**Evidence:** `scripts/build-loop.sh:16-21`, `:102`, `:255`; `scripts/lib/dev-cycle-read.sh:244-247`; `$S/head-suite.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 33** (commit 83cdb005): it listed U1c C17/C18 as tested, but at that commit neither mutant was killed. Already filed in iteration 1 (A11, A1) and fixed by 6c83af2a; recorded for completeness, not new.
- **Claim 34** (commit 07c354c5; `test/scripts/build-loop-read.bats:436`, `:465`, `:469`): "the two other new && chains are split" is true of those two, but eight new fixture `&&` chains remain. Three of them (git replace; the CRLF overwrite; the odd-dir file) let their target mutant survive if the fixture step fails, which is the same vacuous-pass shape as C13 (Low). To tighten, split those three onto their own lines, or say "two of the new chains".
- **Claim 37** (commits 6c83af2a, 07c354c5): "shellcheck clean" holds for the gated `.sh`/`.bash` files. The new dev-cycle.bats test adds one info-level SC2016 (`:1331`, intentional), which is outside the gate. To tighten, scope the note to "shellcheck clean (.sh/.bash)".

### Unverifiable
(none)

---

## Goal-Alignment Note

The goal was to fact-check every claim in U1d's comments, help, test titles and commit messages against the code, and to execute where possible. All seven focus items were covered:
- the never-line rule, probed 5×2;
- the skip list and "level with main";
- shared_branches' exit codes, with missing and corrupt objects;
- the lib's main_entry guard and comments, plus every caller;
- both help ranges and help tests;
- every new test step, with a targeted mutant: 35 mutants and 3 fixture-vacuity probes;
- the commit-message counts, the row-291 reference and the mutant claims.

Every comment and help claim at HEAD is exact. Every new test step fails on the regression it names, and the mutants the comments say survive (cfg=0 in the settings test, rc>0, local BRIEF alone) do survive. The two stated behaviour changes are the only ones: every main_entry caller already passes a pathform-clean path. The residue is three Mostly-accurate commit-message items. Only Claim 34 is new: three remaining fixture `&&` chains can pass vacuously, the same Low class as iteration 2's T7 finding. Nothing found blocks landing. Whether to split those three chains is the orchestrator's call.
