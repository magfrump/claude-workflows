Commit: ab71bce5

# Code Fact-Check Report

**Commit:** ab71bce5
**Replication:** k=3
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u1d, branch feat/build-loop-u1d)
**Scope:** final confirming pass: `git diff main...HEAD -- scripts test` (83cdb005, 6c83af2a, 07c354c5, merged with main at ab71bce5) and those three commit messages. Merged by the orchestrator (most severe verdict wins) from `code-fact-check-report-build-loop-u1d-r{1,2,3}.md`, all `Commit: ab71bce5`; r1 checked 53 claims, r2 38, r3 34. Clusters are at the finest granularity any replicate used where verdicts differ, and coarser where all three agreed. Probes and mutant logs are under `.../scratchpad/review-u1d/f-fc{1,2,3}/`.
**Checked:** 2026-10-06
**Total claims checked:** 22
**Summary:** 16 verified, 5 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Baseline: 94/94 at HEAD in every replicate. Across the three replicates, 93 mutant runs covered every named regression. The only survivors are the ones a comment or override row already names: the local BRIEF dropped alone (row 312), the "ignored" arm (row 313), the exit-1-fails-closed mutant (the `:452` comment), and dropping only the `#` anchor (equivalent).

---

## Claim 1: build-loop.sh never-line rule: bold, a list marker and an unchecked task box count as a copy (self-merge off); a checked task box and a fence are missed, so self-merge rests on the valid line alone

**Location:** `scripts/build-loop.sh:16-21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bold, `- `, `- [ ]`, `- [x]`/`- [X]` and a fenced copy, each alone and beside a valid never line in both orders.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:16-21`, `:150-157`, `:222-251`

---

## Claim 2: header: "A tip on a branch level with main, or whose subject does not start "handoff:", is working. DISPATCHED: ... (0-99), or 0 without one."

**Location:** `scripts/build-loop.sh:62-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers level-with-main `handoff:` tips (working) and the Dispatched default. A branch behind main also reads working, which the sentence does not name.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "a branch behind main also reads working; the sentence does not name it"

**Evidence:** `scripts/build-loop.sh:62-65`, `:346-352`

---

## Claim 3: skip list: the marker skip for any brief on a branch ahead of main; the shared-branch and could-not-be-listed skips for open briefs only

**Location:** `scripts/build-loop.sh:66-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers open, done and dropped briefs on an ahead branch, and both open-only skips.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:66-76`, `:340-352`

---

## Claim 4: both help-range comments, and -h/--help printing the header from its first line through its last

**Location:** `scripts/build-loop.sh:101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both scripts' sed ranges (81 and 80 header lines), and six mutants (start at line 3, stop early, `-h` dropped) failing both help tests.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:101-102`; `scripts/dev-cycle.sh:111-112`; `test/scripts/build-loop-read.bats:442`; `test/scripts/dev-cycle.bats:1322`

---

## Claim 5: SETTINGS_AWK NEXT comment (the next line outside a fence; blank or the end of the file)

**Location:** `scripts/build-loop.sh:145-147`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fences, space and tab lines, and EOF.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:145-153`

---

## Claim 6: shared_branches: "an exit above 1, a corrupt object's included, fails closed ... A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293)"; "a superset: fences are not modelled"

**Location:** `scripts/build-loop.sh:308-312`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a corrupt loose object (bad zlib and hash mismatch: exit 128, every open brief skips) and a missing object (exit 0/1, not counted).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:308-320`

---

## Claim 7: dev-cycle.sh --check-answer help: "it reads what main's copy says until it lands there"

**Location:** `scripts/dev-cycle.sh:58-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T34's working-tree, side-branch and merged cases.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-577`

---

## Claim 8: lib header and MAIN comment: pipefail note; main_entry and brief_fields answer error without main found by name

**Location:** `scripts/lib/dev-cycle-read.sh:13-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no resolve_main and the current-branch fallback (main_entry prints error; brief_fields sets BRIEF_ODD=error and returns 1), and every `set -o pipefail` in the lib.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/lib/dev-cycle-read.sh:13-26`, `:244-248`, `:296`, `:550`

---

## Claim 9: main_entry's comment and guard; the only behaviour changes are the two stated

**Location:** `scripts/lib/dev-cycle-read.sh:250-265`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 8 refused path forms answering error before ls-tree, and the four callers (brief_fields and check_brief check pathform first; check_answer and main_file pass fixed names pathform accepts). dev-cycle.sh has no direct caller.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/lib/dev-cycle-read.sh:250-265`; `scripts/build-loop.sh:124`

---

## Claim 10: the --settings and T3/T44/T6 test steps (unread-file slots line, tab blank, bare `success:`, fenced H2, 1-char stopped reason, the checked-task-box comment, the caller's-config comment)

**Location:** `test/scripts/build-loop-read.bats:55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each step failing on its targeted mutant. `cfg=0` fails the --status test but not the --settings test, as the --settings comment says.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:55`, `:118-119`, `:184-189`, `:256-257`, `:418-440`

---

## Claim 11: the U1d --status test (no open brief, F31's own filter, CRLF, closed directory, BRIEF kept, a caller's config pair, a NUL in a brief, Dispatched 0 and 99)

**Location:** `test/scripts/build-loop-read.bats:450-484`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each step failing on its targeted mutant with the fixtures intact. The fixture-failure path is Claim 18.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:450-484`

---

## Claim 12: T7's NUL-marker step, with its own update-ref and check lines, fails on a broken fixture or a deleted NUL check

**Location:** `test/scripts/build-loop-read.bats:296-300`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL check deleted, the fixture build broken, both together, and update-ref broken. All fail at `:299`-`:300`, and the same broken fixture passed at 6c83af2a.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound, with Claim 13)
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:296-300`; `scripts/build-loop.sh:286`

---

## Claim 13: T7 comment: "A marker whose message body holds a NUL byte (one commit ahead, same tree)."

**Location:** `test/scripts/build-loop-read.bats:296`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's parent and tree. It is one commit on top of `base`, with base's tree; the branch is two commits ahead of main.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r3: "precise wording: 'one commit on top of base, with its tree'"

**Evidence:** `test/scripts/build-loop-read.bats:290-300`

---

## Claim 14: dev-cycle.bats: the --check-answer default-branch test and the main_entry test

**Location:** `test/scripts/dev-cycle.bats:813-823`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-answer removed from the gate (fails) and main_entry's guard reverted (fails).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/dev-cycle.bats:813-823`, `:1330-1337`

---

## Claim 15: 83cdb005 "Tests (U1b C10-C12, U1c C17, C18, C26, C28, C39, and U1a C16)"

**Location:** commit message 83cdb005
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers C17 and C18: both mutants survived the suite at 83cdb005. Fixed in 6c83af2a (iteration 1, A1 and A11). The message cannot be edited without rewriting the branch.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "already filed in iteration 1 (A1, A11) and fixed by 6c83af2a; history only"

**Evidence:** `test/scripts/build-loop-read.bats:296-300`, `:458-460`

---

## Claim 16: 83cdb005's other claims (Code and Wording bullets; mutants that drop the local BRIEF (moving the call) or un-anchor closed/; 118 changed code lines)

**Location:** commit message 83cdb005
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers re-runs on 83cdb005's own tree and pr-prep 1a's count.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `workflows/pr-prep.md:86-92`

---

## Claim 17: 6c83af2a's claims (row 291 C17/C18 closed; A6, A7/A10, C9; wording bullets; 151 lines; 19 and 73 tests)

**Location:** commit message 6c83af2a
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every test bullet (verified) and the counts. "A3, C7 ... test comments and titles say only what they assert" became exact only at 07c354c5 (task box, never-consults).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: "A3, C7 and 'say only what they assert' became exact at 07c354c5; history, correct at HEAD"

**Evidence:** `scripts/build-loop.sh:16-21`; `test/scripts/build-loop-read.bats:452`

---

## Claim 18: 07c354c5 C13: "The two other new && chains are split too."

**Location:** commit message 07c354c5
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two chains split (true), and the new fixture chains that remain. Three of these let their target mutant pass when a fixture step fails:
- `:436` (`git replace … && git config`, with the guard-count mutant)
- `:464` (the CRLF overwrite)
- `:469` (the closed-directory file)
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "same vacuous-pass shape as T7's (fixed in 07c354c5); a failing printf/mkdir/replace in the temp repo is unlikely; split the lines or word it 'two of the new chains'" · r2: "8 new fixture && chains remain; 3 matter"

**Evidence:** `test/scripts/build-loop-read.bats:436`, `:464`, `:469`

---

## Claim 19: "shellcheck clean" (6c83af2a, 07c354c5 Notes)

**Location:** commit message 07c354c5
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `.sh`/`.bash` files the repo's gate checks (clean). The `.bats` files are outside the gate, and the new main_entry test adds an info-level SC2016 at `dev-cycle.bats:1331` (intentional single quotes).
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "build-loop-read.bats:134 SC2016 info is from 1d79ffef, not this branch"

**Evidence:** `test/scripts/dev-cycle.bats:1331`

---

## Claim 20: 07c354c5's other claims (A12, A13, C14-C17; 19 and 73 tests; the T7 fixture check)

**Location:** commit message 07c354c5
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against HEAD.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:16-21`, `:101`; `scripts/lib/dev-cycle-read.sh:244-248`

---

## Submitted Claims

## Claim 21: "main_entry refuses (answers `error`, before any git call) every path form pathform refuses, in the C, C.UTF-8 and en_US.UTF-8 locales: empty, trailing slash, `.GIT`/`.Git`, `:(top)`, `*`, newline, tab, non-ASCII, full-width, absolute, `.` and `..` components, `--`. `docs/a.md` reads blob and `x` reads absent."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:265`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_entry at HEAD for the 22 refused forms probed (every class the claim lists, plus `.git/x`, `docs/..`, `-x` and `docs//a.md`) and the two accepted paths, with git calls counted by a PATH shim, in `LC_ALL=C` and `C.UTF-8`, plus a requested `en_US.UTF-8`. It does not establish behaviour in a real installed `en_US.UTF-8`: that locale is missing here, so bash warned and fell back to C. Locale independence in a real UTF-8 locale rests on the `C.UTF-8` run and on the literal `NAMECHARS` list. It also does not establish that "every" refused form beyond the probed classes behaves the same; that rests on the static reading below. Nor does it cover callers that skip main_entry (U2's floor does not exist yet).

Static reading of the whole unit, `main_entry` (`scripts/lib/dev-cycle-read.sh:262-276`, read to its last line). The guard is the first statement after the locals:

```bash
# scripts/lib/dev-cycle-read.sh:262-266
main_entry() {
  local p="" rest="$1" out mode path dup="" want=()
  local -A m=()
  if ! main_by_name || ! pathform "$1"; then echo error; return; fi
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
```
(excerpt ends :266; enclosing main_entry() continues to :276 — read)

The first git call is `git ls-tree` at `:267`, which comes after the guard. Neither guard function calls git. `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` is at `:247`. pathform (`:142-151`) uses only bash tests: `[[ "$p" =~ $set && "$p" != /* && "$p" != -* ]] || return 1` (`:145`), then a per-component check, `[[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]] || return 1` (`:149`). The allowed set is the literal `NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'` (`:141`). It contains no ranges, so the locale cannot widen it.

Execution, part 1: the probe. Command: `timeout 60 env -i HOME=$S PATH=/usr/bin:/bin GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null LC_ALL=$loc bash $S/probe1.sh <lib> $S/shim $S/logs $loc`, for loc in C, C.UTF-8 and en_US.UTF-8. cwd `$S/repo`, a repo with `docs/a.md` committed on `main`. Exit 0 for all three. Run at 2026-10-06T05:49:58Z. The probe sources the lib and runs `resolve_main`. It then puts `$S/shim` first on PATH. That shim is a `git` wrapper that logs each call and then execs `/usr/bin/git`. The probe calls `main_entry` once per path with a fresh log for each call. The result was the same in all three locales: all 22 refused forms answered `error gitcalls=0`; `docs/a.md` answered `blob gitcalls=1` and `x` answered `absent gitcalls=1`. The log for the accepted path shows the shim records real calls: `git ls-tree -t --full-tree 09c86e5a… -- docs docs/a.md`. The en_US.UTF-8 run printed `bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)`, which shows the C fallback.

Execution, part 2: a control and a cross-check.
- Mutant control. A copy of the lib with `:265` reverted to main's `main_by_name || { echo error; return; }` went through the same probe in `LC_ALL=C` (exit 0). Every path made 1 git call. Most refused forms then answered `absent` (`docs/` answered `absent`, `docs/a.md/` answered `notdir docs/a.md`, and `--`, `:(top)docs/a.md` and `docs/café.md` all answered `absent`). Only `''`, `/docs/a.md` and `..` still answered `error`, because ls-tree itself refused them. So the probe tells the guard apart from its absence.
- GIT_TRACE cross-check. `export GIT_TRACE=$S/logs/s1-gittrace.txt` was set after `resolve_main`, and then main_entry ran on `--`, `:(top)docs/a.md` and `docs/../docs/a.md`. It printed three `error` lines and wrote `no trace file`, so git was never started.

**Evidence:** `scripts/lib/dev-cycle-read.sh:141-151`, `scripts/lib/dev-cycle-read.sh:247`, `scripts/lib/dev-cycle-read.sh:262-276`. Logs: `$S/logs/s1-output.txt`, `$S/logs/s1-mutant-output.txt`, `$S/logs/s1-gittrace-output.txt`, `$S/logs/s1-timestamp.txt`, the per-call shim logs `$S/logs/<locale>-<n>.log`, and the probe script `$S/probe1.sh`.

---

## Claim 22: "`--status` prints the could-not-be-listed skip for every open brief whenever git grep exits above 1."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:313-314`, `:340` as submitted. At HEAD the comment is `:310-314`, the exit test `:316` and the skip line `:343`.
**Type:** Error-handling / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--status` at HEAD when git grep exits 128, caused three ways: a repo-config `grep.patternType=bogus`, the same pair passed through the caller's `GIT_CONFIG_COUNT`, and a corrupt loose object (one blob, and separately the `briefs/closed` tree). It also covers open, done, dropped, new and malformed briefs, all in one invocation. The skip is printed for every open brief that passes check_brief and the Branch:/Dispatched: parsing. An open brief that fails one of those earlier checks gets its own earlier skip line instead, and that line is still a refusal. It does not establish git exit codes for failure causes not tried, such as a promisor or partial clone.

The mechanism is correct, and so is the fail-closed conclusion. Its two parts:
- shared_branches sets the sentinel on any exit above 1. `list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?` (`scripts/build-loop.sh:315`), then `if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi` (`:316`).
- status_line computes the sentinel once (`[[ -n "$SHARED_BRANCHES" ]] || shared_branches`, `:328`). The dispatch loop `for a in "${ARGS[@]}"; do status_line "$a"; done` (`:368`) calls status_line in the main shell, so every brief sees `error`. The skip is `if [[ "$st" == open && "$SHARED_BRANCHES" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed"; return; fi` (`:343`).

"Every open brief" needs a qualifier. Reading status_line in full (`:326-363`) shows four earlier returns that come before `:343`, each with its own line:
- check_brief not `ok` (`:330`)
- `skip $a: the brief is not read` (`:334`)
- `no Branch: line` (`:335`)
- the malformed Branch:/Dispatched: skips (`:336`, `:339-340`)

So an open brief that fails any of these prints its own skip, not the could-not-be-listed one. The submitted line numbers are also 2-3 lines early. The security report's own body cites `:315-316` and `:343`, which are correct.

Execution. Command: `timeout 60 bash /workspace/.claude/wt-build-loop-u1d/scripts/build-loop.sh --status <11 briefs>`, run via `$S/run-s2.sh`. cwd `$S/repo2` (and copies of it). `LC_ALL=C`. Exit 0 for every run. Start time 2026-10-06T05:50:29Z.
- Control. With no fault, four open briefs printed `ok … open …`; this group includes a CRLF brief and one in `closed/`. Also in that run: a done brief printed `ok`, a dropped brief printed `ok`, and a new brief printed `ok … new`. Four malformed briefs printed their own skips: bad Branch, Dispatched 100, no Branch, and `Status: Open`.
- `git config grep.patternType bogus`, with git grep's rc confirmed as 128. All four valid open briefs printed `skip <a>: the open briefs on the default branch could not be listed`. Done, dropped and new still printed `ok`. The open briefs with a bad Branch, a bad Dispatched or no Branch line printed their earlier skips, not the could-not-be-listed one.
- The caller pair `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=grep.patternType GIT_CONFIG_VALUE_0=bogus` gave identical output.
- A corrupt loose blob (the dropped brief's) gave git grep rc 128, and all four open briefs printed the skip. A corrupt `briefs/closed` tree also gave rc 128: the three open briefs in `briefs/` printed the skip, and the brief inside the corrupt tree printed check_brief's `the tree of the default branch could not be read`. This closes the security report's "Not verified: a corrupt tree object" hop.

Outside the claim and not verdicted: under the bogus `grep.patternType`, git printed `fatal: bad grep.patterntype argument` twice per brief from calls other than shared_branches' git grep. These look like check_brief's `git log -G` lookups (`scripts/lib/dev-cycle-read.sh:361-362`). That is the already-deferred family of git log failures under a broken config, so it is not filed here.

**Evidence:** `scripts/build-loop.sh:306-325`, `scripts/build-loop.sh:326-363`, `scripts/build-loop.sh:365-369`, `scripts/lib/dev-cycle-read.sh:325-364`. Logs: `$S/logs/s2-output.txt`, `$S/logs/s2-corrupt-output.txt`, `$S/logs/s2-timestamp.txt`, and the runner `$S/run-s2.sh`.

---

---

## Escalations

None.

## Claims Requiring Attention

### Incorrect
- **Claim 15** (commit 83cdb005): credits U1c C17/C18 as tested before they were. Fixed by 6c83af2a; the message is history (Accepted-immutable).

### Mostly Accurate
- **Claim 22** (submitted, security): "every open brief" skips on a git grep exit above 1; open briefs that fail check_brief or Branch/Dispatched parsing print their own earlier skip (still a refusal).
- **Claim 13** (`test/scripts/build-loop-read.bats:296`): "one commit ahead" is one commit on top of base.
- **Claim 17** (commit 6c83af2a): the wording bullets became exact only at 07c354c5 (history).
- **Claim 18** (commit 07c354c5): three new fixture `&&` chains (`:436`, `:464`, `:469`) can still pass on a failed fixture step.
- **Claim 19** (commits): shellcheck is clean for the gated files; there is one SC2016 info in a `.bats` file.

## Verdict stability

- Clusters: 20, all surfaced by all three replicates.
- Agreement: 16 of 20 (80%).
- Disagreements (4): Claim 13 (V / V(c) / MA), Claim 15 (MA / MA / **I**), Claim 17 (MA / V / V), Claim 19 (V / MA / V).

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to docs/reviews/code-fact-check-report-build-loop-u1d-rN.md (overwriting the iteration-1 file of that name), with first line `Commit: ab71bce5`, structured per the code-fact-check skill.
- Answered: yes (merged from 3 of 3 replicates)
- Out of scope: none
- Escalate: nothing
