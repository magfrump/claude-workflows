Commit: cc75db98

# Code Fact-Check Report

**Commit:** cc75db98
**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u1d, branch feat/build-loop-u1d)
**Scope:** partial scope (loop pass), `83cdb005..cc75db98` limited to scripts/ and test/, which is fix commit 6c83af2a: its new comments, help text, test titles and test comments in scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats and test/scripts/dev-cycle.bats, plus its commit message. The rest of the branch is context only. The iteration-1 merged report (k=3, `Commit: 83cdb005`) is in git history.
**Checked:** 2026-10-06
**Total claims checked:** 23
**Summary:** 21 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution notes. All logs are under `/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/i2fc/logs/` (`$L` below). Baseline: `bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/fixture-hermeticity.bats` in the worktree gave exit 0 and 94/94 at 2026-10-06T05:02:13Z (`$L/suite-head.log`). Mutants: `git archive HEAD` into `i2fc/base`. For each mutant, `i2fc/bin/mut.sh` copies the tree, applies one edit (diff in `$L/<name>-<set>.diff`), and runs `bats test/scripts/build-loop-read.bats` (log in `$L/<name>-<set>.log`). Set `head` runs 6c83af2a's tests. Set `pre` runs 83cdb005's test files against the same mutant, which shows whether the new step is the one that kills it. Mutant runs: 2026-10-06T05:04:27Z to 05:09:00Z. Probes: `i2fc/bin/p1.sh`, `p2.sh`, `p3.sh` and `p3b.sh`, each in its own fresh repo under `i2fc/`. Every process ran under `timeout` and has exited. Hallucination-pattern log read: the test-count entries (an "85 tests" claim and "mode1-equiv 33") match claim class 22. That claim was checked with `bats --count` and holds.

Mutant table (exit 1 = killed; exit 0 = survives):

| Mutant | Edit | head (6c83af2a tests) | pre (83cdb005 tests) |
|---|---|---|---|
| nul | delete marker_kind's NUL line (`build-loop.sh:286`) | killed, T7 at `:296` | survives |
| f31status | drop `"${BRIEF[status]-}" == "Status: open" &&` (`:318`) | killed, U1d --status at `:456` | survives |
| cfg0 | `cfg="${GIT_CONFIG_COUNT:-0}"` → `cfg=0` (`:114`) | killed, U1d --status at `:472` | survives |
| guardskip | export the guard pair only when the caller set no GIT_CONFIG_COUNT | killed, U1d --settings at `:433` | not run |
| noh | `-h\|--help)` → `--help)` | killed, help test (`-h:` empty) | survives |
| slots | every not-set slots line → `x` | killed, T3 `:55` and U1d --settings | killed, U1d --settings (absent arm) |
| slotsunread | only the not-read arm's slots line changed | killed, T3 `:55` only | survives |
| tabblank | next-line blank regex `^[ \t]*$` → `^ *$` | killed, U1d --settings `:424` | survives |
| baresuccess | `success: [^ \t]` → `success:` | killed, T44 `:185` | survives |
| fencedh2 | CONSTRAINTS_AWK `fence($0) { next }` line deleted | killed, T44 `:177` (an earlier step) | killed (`:177`) |
| fencedh2n | CONSTRAINTS_AWK `fence($0) { next }` → `fence($0) { }` | killed, T44 `:189` | survives |
| onechar | stopped REASON needs 2+ characters | killed, T6 `:257` | survives |
| disp0 | Dispatched regex drops `0` | killed, U1d --status `:450` | survives |
| disp99 | Dispatched regex drops the second digit | killed, U1d --status `:456` | survives |
| brieflocal | drop shared_branches' `local ... BRIEF=()` alone | survives | not run |
| moved+local | drop the local BRIEF and move the F31 call after `brief_fields "$a"` | killed, T28 `:392` and U1d --status | not run |
| exit1 | `rc -gt 1` → `rc -ge 1` (exit 1 fails closed) | survives | not run |

---

## Claim 1a: "Self-merge also needs one exact never line. A never list in markup the copy count sees (bold, a list marker) is a second copy and turns self-merge off"

**Location:** `scripts/build-loop.sh:16-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bold (`**Self-merge never:** b/`, `**Self-merge never: b/**`) and list-marker (`- `, `* `, `1. `) copies, each with and without an exact `Self-merge never: a/` line, and an exact line required for self-merge. Does not establish other markup shapes (a tag, a link) beyond the ones probed.

The copy count drops everything but letters and folds case before it compares a line with the key (`build-loop.sh:154-158`):

```
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  ...
  else if (index(s, "selfmergenever") == 1) k = "never"
  if (k != "") { c[k]++; ...
```

When there is more than one copy, the never line is malformed (`:226`, `elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: ..."`). Self-merge then turns off (`:252-253`, `if [[ "$v" == self-merge && -z "$never_ok" ]]; then POLICY_LINE="policy review unset: ... so self-merge is off"`). The probe gave the same result for all five shapes. With an exact line, each printed `never malformed: more than one line starts "Self-merge never:" (lines 3 and 5)` and `policy review unset`. Without one, each printed `never malformed: line 3 is not exactly ...` and `policy review unset`.

Command: `timeout 300 i2fc/bin/p1.sh`, cwd `i2fc/p1`, exit 0, 2026-10-06T05:07:04Z.

**Evidence:** `scripts/build-loop.sh:149-163`, `scripts/build-loop.sh:207-262`, `$L/p1-never-markup.log`

---

## Claim 1b: "one it misses (a task box, a fence) is ignored, so self-merge rests on the exact line alone"

**Location:** `scripts/build-loop.sh:19-21`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers checked task boxes (`- [x]`, `- [X]`), an unchecked task box (`- [ ]`), and backtick and tilde fences, each with and without an exact line. Does not establish other letter-adding markup.

A fence is skipped before counting (`build-loop.sh:151`, `fence($0) { next }`). A checked task box adds a letter (`x`) in front of the key, so `index(s, "selfmergenever") == 1` fails (`:157`). Both are ignored, as the comment says. With an exact `a/` line the probe printed `policy self-merge set` and `never a/ set: line 3` for `[x]`, `[X]`, a backtick fence and a tilde fence. Without the exact line each printed `never none` and `policy review unset`.

The unchecked task box `- [ ] Self-merge never: b/` is not missed. It adds no letters, so the copy count sees it as a second copy. With an exact line the probe printed `never malformed: more than one line starts "Self-merge never:" (lines 3 and 5)` and `policy review unset`. The result is fail-closed, so self-merge stays off rather than coming on. The help's own later sentence already gives the precise condition: "Markup that adds letters (a task box, a tag) can still hide a copy" (`:41-44`). The precise version of this comment would say "a checked task box". An unchecked box behaves like the bold and list-marker cases.

Command: `timeout 300 i2fc/bin/p1.sh`, cwd `i2fc/p1`, exit 0, 2026-10-06T05:07:04Z.

**Evidence:** `scripts/build-loop.sh:16-21`, `scripts/build-loop.sh:41-44`, `scripts/build-loop.sh:149-158`, `$L/p1-never-markup.log`

---

## Claim 2: skip list order: the marker skip applies "on a branch ahead of main" to every brief; "for an open brief only", the shared-branch and could-not-be-listed skips

**Location:** `scripts/build-loop.sh:66-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers done and open briefs on the marker skip, the shared-branch skip and the could-not-be-listed skip. Does not establish dropped-brief behavior beyond reading the code: dropped takes the same non-open path as done.

The two F31 skips test the state (`build-loop.sh:341-342`):

```
  if [[ "$st" == open && "$SHARED_BRANCHES" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed"; return; fi
  if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
```

The marker skip has no state test (`:352-357`, `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"; case "$kind" in bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" ..."`).

Probes: a done brief and an open brief, each on a branch whose tip is `handoff: bogus`, both printed `skip ...: the tip of feat/x starts "handoff:" but is not a marker`. A done brief that shares feat/y with two open briefs printed `ok ... done ...`, and both open briefs skipped. With a caller's `grep.patternType=bogus` pair, the done brief printed `ok` and the open brief printed `skip ...: the open briefs on the default branch could not be listed`.

Command: `timeout 300 i2fc/bin/p2.sh`, cwd `i2fc/p2`, exit 0, 2026-10-06T05:07:25Z.

**Evidence:** `scripts/build-loop.sh:324-360`, `$L/p2-skips-objects.log`

---

## Claim 3: help-case comment "the header: from line 2 to the first non-empty line not starting with #" (C7: matches dev-cycle.sh's)

**Location:** `scripts/build-loop.sh:101`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sed range and the wording match with dev-cycle.sh. Does not establish that the header ends exactly where a reader expects, beyond the help test's first and last lines.

`sed -n '2,/^[^#]/{/^#/p}'` ends the range at the first line matching `^[^#]`, which is a non-empty line not starting with `#`. An empty line cannot match. dev-cycle.sh's comment reads `# The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale).` (`scripts/dev-cycle.sh:111`), so the wording matches apart from the parenthetical. The help test passes for `-h` and `--help`, and its first and last lines are the header's.

**Evidence:** `scripts/build-loop.sh:101`, `scripts/dev-cycle.sh:111-112`, `test/scripts/build-loop-read.bats:436-442`, `$L/suite-head.log`

---

## Claim 4: "an exit above 1, a corrupt object's included, fails closed (SHARED_BRANCHES=error: every open brief skips). A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293)."

**Location:** `scripts/build-loop.sh:309-311`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a corrupt loose object (garbage bytes) and a deleted loose object for another open brief, and a deleted object with nothing else matching. Does not establish corrupt packed objects, or git versions other than 2.39.5.

The code is `list="$(git grep ... "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?`, then `if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi` (`:313-314`).

- Corrupt object: git grep printed `fatal: loose object ... is corrupt` and exited 128. The open brief printed `skip ...: the open briefs on the default branch could not be listed`.
- Missing object of another open brief that names the same branch: git grep printed `error: ... unable to read` and exited 0. The queried open brief printed `ok ... open review feat/y absent - - 0`, so the missing brief was not counted.
- Missing objects with nothing else matching: git grep warned and exited 1.

Command: `timeout 300 i2fc/bin/p2.sh`, cwd `i2fc/p2`, exit 0, 2026-10-06T05:07:25Z.

**Evidence:** `scripts/build-loop.sh:304-322`, `$L/p2-skips-objects.log`

---

## Claim 5: lib header "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name (main_entry and brief_fields answer error)"

**Location:** `scripts/lib/dev-cycle-read.sh:22-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_entry and brief_fields with resolve_main never called, and after resolve_main fell back to the current branch. Does not re-verify the check_* halves, which 6c83af2a did not change.

main_entry's first line is `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` (`lib:264`). brief_fields answers `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`lib:297`). The probe ran with no resolve_main call at all: main_entry printed `error`, and brief_fields returned 1 with `BRIEF_ODD=error` and no keys set. On a repo with no main or master, resolve_main fell back to `MAIN=other BY_NAME=[]`, and both again answered error. After a by-name resolve_main, the same path gave `blob`.

Command: `timeout 120 i2fc/bin/p3.sh`, cwd `i2fc/p3`, exit 0, 2026-10-06T05:07:45Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:244-248`, `scripts/lib/dev-cycle-read.sh:261-319`, `$L/p3-lib-no-resolve.log`

---

## Claim 6: main_entry: "error (no default branch found by name, a path pathform refuses, ls-tree failed, or the tree lists a name twice ...). It runs main_by_name and pathform itself, before any read (pathform also means ls-tree prints the name unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:254-260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four error causes as code paths and "before any read", the latter by tracing git calls for four refused paths. Does not establish ls-tree's quoting for names outside NAMECHARS, since those cannot reach it.

Each error cause has its own `echo error` path in the function:

- the guard (`lib:264`);
- ls-tree failing (`lib:266`, `|| { echo error; return; }`);
- a duplicate name (`lib:272`, `[[ -z "$dup" ]] || { echo error; return; }`).

The guard sits before the only git call. With `GIT_TRACE` written to a file, `a"b.md`, `../x`, `-x` and `docs//x.md` each answered `error` with 0 git calls. A valid path made 1 call. NAMECHARS holds only `a-zA-Z0-9._/-` (`lib:141`), none of which ls-tree quotes.

Command: `timeout 60 i2fc/bin/p3b.sh`, cwd `i2fc/p3/repo`, exit 0, 2026-10-06T05:07:53Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:141-151`, `scripts/lib/dev-cycle-read.sh:261-278`, `$L/p3b-pathform-trace.log`

---

## Claim 7: T3 asserts the slots line for an unread file (commit A7/A10)

**Location:** `test/scripts/build-loop-read.bats:55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the not-read arm's slots line. Does not establish the absent arm, which the U1d --settings test covers.

The new assertion is `[ "$(line slots)" = "slots 3 default: the code fence opened at line 1 of docs/dev-cycle.md is never closed, so the file is not read" ]`. Mutant slotsunread changes only the not-read arm. It fails T3 at `:55` (`slots 3 default: unread`) and survives 83cdb005's tests.

**Evidence:** `scripts/build-loop.sh:212-215`, `$L/slotsunread-head.log`, `$L/slotsunread-pre.log`, `$L/slotsunread-head.diff`

---

## Claim 8: C9 "a bare "success:" line"

**Location:** `test/scripts/build-loop-read.bats:184-185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a bare `  success:` under H1 being refused. Does not establish a `success:` followed only by blanks.

The step is `constraints '- S1: a' '- H1: b' '  success:'`, which expects `hard constraint H1 (line 2) has no success: line`. Mutant baresuccess changes `success: [^ \t]` to `success:`. It fails at `:185` with `constraints ok 1-hard 1-soft` and survives 83cdb005's tests.

**Evidence:** `scripts/build-loop.sh:182`, `$L/baresuccess-head.log`, `$L/baresuccess-pre.log`

---

## Claim 9: C9 "a fenced H2 (constraints ok)"

**Location:** `test/scripts/build-loop-read.bats:188-189`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fenced `H2: hidden` being skipped by CONSTRAINTS_AWK. Does not establish that this step is the only one that kills a removed fence call: deleting the whole line also disables FENCE_AWK's refusals and is caught earlier, at `:177`.

The narrow mutant fencedh2n changes `fence($0) { next }` to `fence($0) { }` in CONSTRAINTS_AWK. It fails at `:189` and survives 83cdb005's tests, so this step is the one that pins the fence skip.

**Evidence:** `scripts/build-loop.sh:168-170`, `$L/fencedh2n-head.log`, `$L/fencedh2n-pre.log`, `$L/fencedh2-head.log`

---

## Claim 10: C9 "a 1-char stopped reason"

**Location:** `test/scripts/build-loop-read.bats:256-257`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-character arm of the REASON regex. Does not establish other lengths, which the existing r120 steps cover.

Mutant onechar requires 2 or more characters. It fails T6 at `:257` (`skip ... its subject is not exactly`) and survives 83cdb005's tests.

**Evidence:** `scripts/build-loop.sh:298`, `$L/onechar-head.log`, `$L/onechar-pre.log`

---

## Claim 11: commit A11/G1: "T7 commits a marker whose body holds a NUL (written with hash-object --literally); deleting marker_kind's NUL check now fails T7 (row 291 C17 closed)"

**Location:** `test/scripts/build-loop-read.bats:295-296`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit-object NUL check in marker_kind and the C17 gap in row 291 ("NUL refusal and F31 open-only filter untested"; test-strategy's row-291 table names C17 as marker_kind's NUL refusal). Does not establish a NUL in the subject line, which this fixture does not use.

The fixture's message is `handoff: ready\n\n\0x\n`, piped to `git hash-object -t commit --literally -w --stdin`. Mutant nul deletes `build-loop.sh:286`. It fails T7 at `:296`, where the output is `ok ... ready`, and survives 83cdb005's tests.

**Evidence:** `scripts/build-loop.sh:280-301`, `docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1c.md:148`, `docs/reviews/test-strategy-review-2026-10-06-build-loop-u1d.md:27`, `$L/nul-head.log`, `$L/nul-pre.log`

---

## Claim 12: whitespace-only blank line "includes a tab" (commit A7/A10)

**Location:** `test/scripts/build-loop-read.bats:423`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tab arm of the next-line blank regex. Does not establish other whitespace characters (for example CR, which is stripped earlier).

The step uses `$' \t '`. Mutant tabblank changes `^[ \t]*$` to `^ *$`. It fails at `:424` (`never malformed: line 2 is followed by a non-blank line`) and survives 83cdb005's tests.

**Evidence:** `scripts/build-loop.sh:153`, `$L/tabblank-head.log`, `$L/tabblank-pre.log`

---

## Claim 13: "A caller's own GIT_CONFIG_COUNT does not stop the guard (that the caller's pairs still reach git is asserted in the --status deferred-cases test)."

**Location:** `test/scripts/build-loop-read.bats:427-428`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both halves: the guard surviving a caller count (this test), and the caller's pair reaching git (the --status test). Does not establish zero-padded counts or `git -c`, which the script's comment leaves to the caller.

Mutant guardskip skips the guard when the caller set a count. It fails this test at `:433` with `policy self-merge set`. Mutant cfg0 overwrites the caller's pair. It passes this test, because the guard still applies, and fails the --status deferred-cases test at `:472`, which shows `ok ... - - 99`. So each half is asserted where the comment says.

**Evidence:** `scripts/build-loop.sh:110-114`, `test/scripts/build-loop-read.bats:429-433`, `test/scripts/build-loop-read.bats:470-472`, `$L/guardskip-head.log`, `$L/cfg0-head.log`

---

## Claim 14: test title "build-loop.sh -h and --help print the header from its first line through its last (U1d)"

**Location:** `test/scripts/build-loop-read.bats:436`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0 and the first and last header lines, for both flags. Does not establish that no middle line is dropped, and the title does not claim that.

The loop is `for h in -h --help`. It asserts `"${lines[0]}" == "The build-loop handoff's state and checks"*` and a last line ending `or no default branch found by name.`. Mutant noh fails with `-h:` and empty output, and survives 83cdb005's tests.

**Evidence:** `test/scripts/build-loop-read.bats:436-442`, `$L/noh-head.log`, `$L/noh-pre.log`

---

## Claim 15: test title "--status: deferred cases: no open brief, F31's open-only filter, CRLF, an unanchored closed, BRIEF kept, a caller's config pair, a NUL in a brief (U1d)"

**Location:** `test/scripts/build-loop-read.bats:444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case as a step that runs and asserts. Does not establish that "BRIEF kept" detects dropping shared_branches' local BRIEF on its own: mutant brieflocal survives because status_line's own `brief_fields "$a"` runs after F31. Dropping the local together with moving the call is killed. This matches the settled test-strategy G12 and iteration-1 Claim 22.

Each case is a step: no open brief (`:446-450`), F31's filter (`:451-456`, mutant f31status), CRLF (`:457-460`), the unanchored closed (`:462-465`), BRIEF kept (`:466-469`), the caller's pair (`:470-472`, mutant cfg0), and a NUL in a brief (`:473-476`). The title's case names match the steps.

**Evidence:** `test/scripts/build-loop-read.bats:444-477`, `scripts/build-loop.sh:324-332`, `$L/brieflocal-head.log`, `$L/moved-local-head.log`

---

## Claim 16: "No open brief on main at all (git grep exits 1): a done brief reads normally. (A done brief never consults F31, so this cannot tell exit 1 from a failure.)"

**Location:** `test/scripts/build-loop-read.bats:446-447`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conclusion: this step cannot tell exit 1 from a failure. Does not support the literal reading that F31 does not run for a done brief.

The conclusion holds. Mutant exit1 (`rc -ge 1`) survives the whole build-loop-read suite. F31 does run for a done brief, though. status_line's first statement is `[[ -n "$SHARED_BRANCHES" ]] || shared_branches` (`build-loop.sh:326`), before any state is known. Only the result is ignored, through the `"$st" == open` tests at `:341-342`. The precise wording would be "a done brief never reads F31's answer".

**Evidence:** `scripts/build-loop.sh:324-342`, `$L/exit1-head.log`

---

## Claim 17: C9 "Dispatched 0 and 99"

**Location:** `test/scripts/build-loop-read.bats:448-450`, `test/scripts/build-loop-read.bats:454-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an explicit `Dispatched: 0` and `Dispatched: 99` being accepted. Does not establish refusal of 100 or `00`, which this commit does not claim.

Mutant disp0 fails at `:450` and mutant disp99 fails at `:456`, each with `skip ...: its first Dispatched: line is not exactly`. Both survive 83cdb005's tests.

**Evidence:** `scripts/build-loop.sh:335-338`, `$L/disp0-head.log`, `$L/disp99-head.log`, `$L/disp0-pre.log`, `$L/disp99-pre.log`

---

## Claim 18: "A done brief sharing an open brief's branch does not make the open one skip, even with a later "Status: open" line that git grep lists (F31's own filter)." / commit A1/G2 "(row 291 C18 closed)"

**Location:** `test/scripts/build-loop-read.bats:451-456`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers F31's `Status: open` term on the first Status line, and row 291's C18. Does not establish the term's CR handling, which brief_fields owns.

d becomes `Status: done\nBranch: feat/x\nStatus: open\n`, which git grep's `^Status: open\r?$` lists. Mutant f31status drops `"${BRIEF[status]-}" == "Status: open" &&` (`build-loop.sh:318`). It fails at `:456` with `skip ...: another open brief ... names the same branch` and survives 83cdb005's tests.

**Evidence:** `scripts/build-loop.sh:313-318`, `$L/f31status-head.log`, `$L/f31status-pre.log`

---

## Claim 19: "Another open brief (CRLF line endings) on the same branch counts."

**Location:** `test/scripts/build-loop-read.bats:457`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reworded comment, which now claims only the skip. Does not re-run the CRLF mutant from iteration 1.

The step asserts `[[ "$output" == "skip $o: another open brief"* ]]` after p is written with `\r\n` endings. The removed Dispatched clause (A2) is no longer claimed here. The suite passes.

**Evidence:** `test/scripts/build-loop-read.bats:457-460`, `$L/suite-head.log`

---

## Claim 20: "A caller's own GIT_CONFIG_COUNT pair still reaches git beside the guard pair." / commit A6

**Location:** `test/scripts/build-loop-read.bats:470-472`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the caller's pair reaching git through `GIT_CONFIG_KEY_0`. Does not assert the guard pair in this step: the --settings test asserts that (Claim 13).

With `grep.patternType=bogus`, git grep fails and the open brief prints `the open briefs on the default branch could not be listed`. Under mutant cfg0 the caller's KEY_0 is overwritten and the step prints `ok`, so it fails at `:472`.

**Evidence:** `scripts/build-loop.sh:114`, `$L/cfg0-head.log`

---

## Claim 21: test title "main_entry answers error for a path pathform refuses (U1d)"

**Location:** `test/scripts/dev-cycle.bats:1328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four-path output assertion. Does not cover "before any read": the title no longer claims it, and Claim 6 verifies it separately.

The test asserts `"$output" = "error\nerror\nerror\nerror"` for `a"b.md`, `../x`, `-x` and `docs//x.md`. That is all the new title says.

**Evidence:** `test/scripts/dev-cycle.bats:1328-1334`, `$L/suite-head.log`

---

## Claim 22: commit Notes: "Mutants checked by hand on the patched suite: marker_kind's NUL line deleted fails T7; F31's status term dropped fails the U1d test. 151 changed code lines (cap 400). Tests: build-loop-read 19, dev-cycle 73, hermeticity lint green; shellcheck clean."

**Location:** commit `6c83af2a` message
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure and each gate as run at HEAD (scripts/ and test/ are unchanged since 6c83af2a). Does not establish shellcheck on .bats files: the one info-level SC2016 at `build-loop-read.bats:133` predates this commit and is outside the repo's `.sh`/`.bash` rule.

- The size gate, pr-prep step 1a's command (`git diff --numstat main...6c83af2a -- ':(top)' ':(top,exclude)docs/'`), prints 151, and `main...HEAD` prints 151.
- `bats --count` prints 19 for build-loop-read and 73 for dev-cycle.
- The hermeticity lint is part of the 94/94 run.
- `shellcheck -x scripts/build-loop.sh scripts/lib/dev-cycle-read.sh` exits 0 (2026-10-06T05:09:26Z).
- The two named mutants are in the table above (nul, f31status).

**Evidence:** `workflows/pr-prep.md:86-91`, `$L/suite-head.log`, `$L/shellcheck.log`, `$L/nul-head.log`, `$L/f31status-head.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1b** (`scripts/build-loop.sh:19-21`): an unchecked task box (`- [ ] Self-merge never: b/`) is seen by the copy count, so it turns self-merge off, which is fail-closed. Only a checked box (`[x]`) is missed. The comment should say "a checked task box".
- **Claim 16** (`test/scripts/build-loop-read.bats:447`): F31 runs for a done brief (`build-loop.sh:326`); only its answer goes unread. "Never reads F31's answer" would be exact. The conclusion holds: mutant exit1 survives.

### Unverifiable
(none)

## Goal-Alignment Note

The goal was to fact-check 6c83af2a's claims, executing where possible. Every claim the brief singled out was checked: all seven numbered items and each named mutant. All 23 claims rest on execution. The fix does what its message says. Each named test kills its named regression, and in every case the pre-fix (83cdb005) suite does not, so the new steps are what kill them. Row 291's C17 and C18 are closed.

Two wording imprecisions remain, both at Mostly-accurate level and neither one fail-open: Claim 1b's "a task box" and Claim 16's "never consults".

Out of scope, observed in passing: in probe p2, under the caller's `grep.patternType=bogus` pair, a done brief's `ok` line had an empty DATE field. `git log` reads grep config too. The script trusts the caller's environment, as its own comment says, so this is noted, not filed.
