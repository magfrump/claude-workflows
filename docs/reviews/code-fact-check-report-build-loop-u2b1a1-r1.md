Commit: ae08688c

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1a1 (branch `feat/build-loop-u2b1a1`)
**Scope:** `git diff main...HEAD` at ae08688c (plan, questions.md, build-loop.sh, dev-cycle.sh, lib/dev-cycle-read.sh, build-loop-check.bats) plus commit ae08688c's message; replicate r1 of 3
**Checked:** 2026-10-08
**Total claims checked:** 27
**Summary:** 24 verified, 2 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read before checking. One logged pattern is relevant by class: suite counts quoted in a commit message that do not match the suites ("All 85 tests ...", "mode1-equiv 33"). Claim 23 checks this commit's counts against executed runs; they match, so no recurrence.

Execution provenance: every executed claim ran on git 2.39.5, bash 5.2.15, in the cwd named in the claim. Raw output is captured under `/tmp/fcu2b1a1-r1-dutz/` (named per claim). The throwaway repos were removed after each script, and no background process was left running. Per the shared brief, this report is the only file written in the repo, so `docs/reviews/hallucination-patterns.md` is not updated. No claim was a fabrication in any case.

---

## Claim 1: "with a state gate after `devcontainer-config/install.sh`'s `git_state_gate`"

**Location:** `docs/working/plan-build-loop-handoff.md:84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of `git_state_gate` in `devcontainer-config/install.sh`. It does not establish that U2b1a2's `state_gate` mirrors that function key for key.
**Legibility-target:** for-orchestrator-synthesis

The function exists: `devcontainer-config/install.sh:209` reads `git_state_gate() {`.

**Evidence:** `devcontainer-config/install.sh:193`, `devcontainer-config/install.sh:209`

---

## Claim 2: "`--state` → `ok`, or `refuse state WHAT: WHY` for each planted `.git` state the gate refuses (exit 2), as `--check` prints them (U2b1a's `state_gate`)"

**Location:** `docs/working/plan-build-loop-handoff.md:207`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line format and the exit-2 behaviour of `state_gate` on `feat/build-loop-u2b1a2`. It does not establish `--state` itself, which is a later unit (U3b).
**Legibility-target:** for-orchestrator-synthesis

On `feat/build-loop-u2b1a2` (scripts/build-loop.sh), the comment reads `# switch off. Prints one "refuse state WHAT: WHY" line per finding, returns 1` (:169), and the call is `if [[ "$MODE" == check ]]; then state_gate || exit 2; fi` (:209).

**Evidence:** `feat/build-loop-u2b1a2:scripts/build-loop.sh:169-209`

---

## Claim 3: "Output (U2b1a): `refuse state WHAT: WHY` lines (exit 2 before any brief), then per brief `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY`"

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `check_line` and the `check` mode case on `feat/build-loop-u2b1a2` (whole functions read, :470-510). It does not establish U2b1b's future per-path lines.
**Legibility-target:** for-orchestrator-synthesis

`feat/build-loop-u2b1a2:scripts/build-loop.sh:484-486` reads `0) echo "ok $a $sha $tree" ;;` / `1) echo "refuse $a: $br conflicts with the default branch" ;;`. Skip lines pass through from status_line: `[[ "$out" == "ok "* ]] || { echo "$out"; return; }` (:472). The exit is `[[ "$fails" -eq 0 ]] || exit 2` (:509), so the run already exits 2 on any non-ok line.

**Evidence:** `feat/build-loop-u2b1a2:scripts/build-loop.sh:209`, `:470-510`

---

## Claim 4a: "git 2.39 reads `.gitattributes` from the current directory even under `--work-tree`, so an untracked or `.git`-planted `* merge=union` turned a conflict into a clean merge: reproduced"

**Location:** `docs/working/plan-build-loop-handoff.md:281`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's `merge-tree --write-tree` exit status with `* merge=union` in the cwd: in the toplevel, under `--work-tree` pointing at an empty directory, and planted in `.git` with cwd `.git`. It does not establish other git versions.
**Legibility-target:** for-orchestrator-synthesis

Command: `bash /tmp/fcu2b1a1-r1-dutz/exp6.sh`, cwd `/tmp`, exit 0, at 2026-10-08T19:02:10Z. Output: `no attrs: rc=1`, `untracked .gitattributes in toplevel cwd: rc=0`, `cwd toplevel, --work-tree=empty: rc=0`, `cwd .git with planted .gitattributes, --work-tree=empty: rc=0`, `cwd empty dir: rc=1`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:281`; `/tmp/fcu2b1a1-r1-dutz/exp6.log`

---

## Claim 4b: "merge-tree run from a fresh empty directory against the common git dir"

**Location:** `docs/working/plan-build-loop-handoff.md:281`
**Type:** Architectural
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how U2b1a2's `merge_result` reaches the repository. It does not establish whether the U2b1a bullet is meant as history (the next bullet, :282, names `gate_repo` and `merge_result`).
**Legibility-target:** for-author

This was true at d0199be6, whose message says "merge_result: merge-tree --write-tree from a fresh empty directory against the common git dir". Iteration 2 (c66988b6, "merge-tree in a gate-owned repository") changed it. U2b1a2 now runs merge-tree in its own git dir and shares only the object store. The code reads `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` (`feat/build-loop-u2b1a2:scripts/build-loop.sh:458`, end of `gate_repo`, :448-459 read), and its comment reads `# merge-tree reads none of the repo's config ... and only the repo's # object store` (:441-445).

The bullet's state-gate list is also a subset of what U2b1a2 now refuses: `extensions\.partialclone$|remote\..*\.promisor$` (:179), `shallow` (:192) and `origin/HEAD` (:198-201). That is an omission, not a contradiction.

**Evidence:** `docs/working/plan-build-loop-handoff.md:281`; `feat/build-loop-u2b1a2:scripts/build-loop.sh:179`, `:192`, `:198-201`, `:438-459`

---

## Claim 5: "fixes for the iteration-2 findings brought U2b1a to 439 lines. U2b1a1 (`feat/build-loop-u2b1a1`, lands first) is the reader side ... U2b1a2 (`feat/build-loop-u2b1a2`, on U2b1a1) is `--check` itself: `harden`, the state gate, `gate_repo` and `merge_result`, check_line. `feat/build-loop-u2b1a` keeps both units' review history ... and is not merged."

**Location:** `docs/working/plan-build-loop-handoff.md:282`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 439 count (main...c66988b6, docs/ excluded, as the commit message counts), the stacking, each named function's presence on u2b1a2, and the contents of U2b1a1. It does not establish the count under any other counting rule.
**Legibility-target:** for-orchestrator-synthesis

Command: the git block in `/tmp/fcu2b1a1-r1-dutz/exp-git.log`, cwd the worktree, exit 0, at 2026-10-08T19:02:55Z. The output gives `439` for main...c66988b6, and `git merge-base feat/build-loop-u2b1a1 feat/build-loop-u2b1a2` gives `ae08688c...`.

On u2b1a2, `harden() {` (:158), `state_gate() {` (:181), `gate_repo() {` (:448), `merge_result() {` (:461) and `check_line() {` (:470) all exist. `git branch --merged main --list '*u2b1a*'` printed nothing, so no u2b1a branch is merged. The rubric at `feat/build-loop-u2b1a:docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md` has iteration 1 and iteration 2 sections.

**Evidence:** `docs/working/plan-build-loop-handoff.md:282`; `/tmp/fcu2b1a1-r1-dutz/exp-git.log`

---

## Claim 6: Q-119 "Update 2026-10-08: ... commit d0199be6 on `feat/build-loop-u2b1a`. At review iteration 2 U2b1a split again for size (439 lines): U2b1a1 (the reader side `--status` uses) lands first, then U2b1a2 (`--check`); plan step 5's note."

**Location:** `docs/working/questions.md:346`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the entry's identity (Q-119, heading at :329), d0199be6 carrying the plan's U2b split note, and the 439 and order statements. It does not establish anything about 93655b47, the commit that first wrote the update.
**Legibility-target:** for-orchestrator-synthesis

The update sits under `### Q-119 · u2a-split-at-cap` (:329). `git show d0199be6 -- docs/working/plan-build-loop-handoff.md` adds `+   - **U2b split (2026-10-08, before code; ...`. The 439 count and the stacking are as in Claim 5.

**Evidence:** `docs/working/questions.md:329`, `docs/working/questions.md:346`; d0199be6

---

## Claim 7: --status help, skip clause: "its branch name is refused (as --check-branch) or its commit count or date cannot be read"

**Location:** `scripts/build-loop.sh:71-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path from check_branch's new skip through status_line's `*) echo "skip $a: Branch: ${out#*: }"`. It does not establish marker_kind's new failed-read answer, which reaches the user as `skip BRIEF: the tip of BR starts "handoff:" but is not a marker: its commit could not be read`. The help names no "commit cannot be read" reason, and that wording claims a `handoff:` subject was read. In practice this path is all but unreachable, because check_branch has already peeled `sha^{commit}` and read its date.
**Legibility-target:** for-author

`scripts/build-loop.sh:323-327` (status_line, :309-346 read) reads `*) echo "skip $a: Branch: ${out#*: }"; return ;;`. The new test (Claim 21) shows `skip $B: Branch: its commit count or date could not be read` under `log.date bogus`. Command: `bats test/scripts/build-loop-check.bats`, cwd the worktree, exit 0, at 2026-10-08T18:58:48Z: 81 ok.

**Evidence:** `scripts/build-loop.sh:68-76`, `scripts/build-loop.sh:331-336`, `scripts/build-loop.sh:340-341`; `/tmp/fcu2b1a1-r1-dutz/suite-build-loop-check.log`

---

## Claim 8: "the message is the raw object's text after its first empty line (no header holds one)"

**Location:** `scripts/build-loop.sh:284-285`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git-shaped commit objects, including a multi-line `gpgsig` header whose blank line is stored as a single space, and an empty message. It does not establish behaviour for a hand-forged object whose header holds an empty line. Git's own `%B` splits at the same first empty line, so the new reading matches the old one.
**Legibility-target:** for-orchestrator-synthesis

Code (marker_kind, :281-311 read): `if [[ "$msg" == *$'\n\n'* ]]; then msg="${msg#*$'\n\n'}"; else msg=""; fi` (:292). Command: `bash /tmp/fcu2b1a1-r1-dutz/exp2.sh`, cwd `/tmp`, exit 0, at 2026-10-08T18:59:43Z. Output: `4 gpgsig header: blocked ; log %B first line: handoff: blocked`, `5 empty message: working`.

**Evidence:** `scripts/build-loop.sh:281-311`; `/tmp/fcu2b1a1-r1-dutz/exp2.log`

---

## Claim 9: "read with cat-file so no log.* or i18n.* config can change or break it"

**Location:** `scripts/build-loop.sh:285-286`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `log.date`, `log.decorate`, `log.showSignature`, `i18n.logOutputEncoding` and `i18n.commitEncoding` set to broken values, plus `grep.patternType bogus`. It does not establish replace refs, which cat-file honours exactly as `git log` did (unchanged by this diff).
**Legibility-target:** for-orchestrator-synthesis

Command: `bash /tmp/fcu2b1a1-r1-dutz/exp1.sh`, cwd `/tmp`, exit 0, at 2026-10-08T18:59:17Z. For every config, `cat-file rc=0` and `cat-file msg: handoff: ready`. `git log -1 --format=%cs` fails (`rc=128`) under `log.date bogus` and under `grep.patternType bogus`. `rev-list --count` and `rev-list --parents` succeed under all six.

**Evidence:** `scripts/build-loop.sh:284-289`; `/tmp/fcu2b1a1-r1-dutz/exp1.log`

---

## Claim 10: "A failed read answers bad, never working (row 307)"

**Location:** `scripts/build-loop.sh:286-287`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a failed `rev-list` (missing object) and a failed `cat-file` with `rev-list` succeeding (shimmed), under the script's `set -euo pipefail` (:85, inherited by the `$(marker_kind ...)` subshell). It does not hold without pipefail: run that way, the same shim answers `working`.
**Legibility-target:** for-orchestrator-synthesis

Code: `if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then` / `echo "bad its commit could not be read"; return` (:289-290). Command: `bash /tmp/fcu2b1a1-r1-dutz/exp2.sh` (as Claim 8). Output: `6 cat-file fails: bad its commit could not be read`, `7 same, pipefail off: working`, `8 missing object: bad its commit could not be read`. Row 307 (`docs/reviews/override-log.md:307`) asks for exactly this: "make marker_kind answer bad on a failed read".

**Evidence:** `scripts/build-loop.sh:85`, `scripts/build-loop.sh:289-291`; `docs/reviews/override-log.md:307`; `/tmp/fcu2b1a1-r1-dutz/exp2.log`

---

## Claim 11: "NULs are dropped here (bash would warn on stderr); the NUL check below reads the raw object."

**Location:** `scripts/build-loop.sh:288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a NUL in a `handoff:` subject (caught by the raw check) and a NUL in a non-`handoff:` message (answers `working`, no stderr). It does not establish that a NUL in a non-handoff tip is ever reported, because the raw check runs only after the `handoff:` test (unchanged order).
**Legibility-target:** for-orchestrator-synthesis

Raw check: `if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi` (:295). exp2 output: `2 NUL in subject: bad it holds a NUL byte`, `stderr bytes: 0`; `3 NUL, non-handoff: working`, `stderr bytes: 0`. Bash's warning without `tr` was confirmed separately: `bash -c 'x="$(printf "a\0b")"'` prints `warning: command substitution: ignored null byte in input`.

**Evidence:** `scripts/build-loop.sh:288-295`; `/tmp/fcu2b1a1-r1-dutz/exp2.log`, `/tmp/fcu2b1a1-r1-dutz/exp2.nul.err`

---

## Claim 12: "status_line uses open_shared"; behaviour unchanged from main's `shared_branches`

**Location:** `scripts/build-loop.sh:311`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the observable `--status` output for shared, mixed-case, CRLF, corrupt-object and missing-object briefs, old against new. It also covers the one body difference: open_shared's new `if ! main_by_name; then OPEN_SHARED=error` cannot be observed, because build-loop.sh exits at :120 when `main_by_name` fails. It does not establish behaviour for other future callers of open_shared, such as U2b1a2's check mode.
**Legibility-target:** for-orchestrator-synthesis

Apart from that guard and the `[[ -z "$OPEN_SHARED" ]] || return 0` cache (the old caller wrote it as `[[ -n "$SHARED_BRANCHES" ]] || shared_branches`), the bodies differ only in names: `n`→`count` and `isbrief || isclosed`→`anybrief`. Command: `bash /tmp/fcu2b1a1-r1-dutz/exp4.sh <BL>` for HEAD's build-loop.sh and for main's (in `/tmp/fcu2b1a1-r1-dutz/old`), cwd `/tmp`, exit 0, at 2026-10-08T19:00:55Z. The two outputs are line-for-line identical: shared → `skip ...: another open brief ... names the same branch`, corrupt (grep rc 128) → `the open briefs on the default branch could not be listed`, missing (grep rc 0) → shared still detected via a/b, and c skips as unreadable.

**Evidence:** `scripts/build-loop.sh:119-120`, `scripts/build-loop.sh:309-346`, `scripts/lib/dev-cycle-read.sh:461-477`, `main:scripts/build-loop.sh` (shared_branches); `/tmp/fcu2b1a1-r1-dutz/exp4.log`

---

## Claim 13: --check-branch help: "or a branch whose count or date cannot be read (a broken log.* config)"

**Location:** `scripts/dev-cycle.sh:48-49`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip line and its causes. It does not establish every config that triggers it.
**Legibility-target:** for-author

The skip exists, `skip feat/x: its commit count or date could not be read` under `log.date bogus` (exp5; command `bash /tmp/fcu2b1a1-r1-dutz/exp5.sh`, cwd `/tmp`, exit 0, 2026-10-08T19:01:42Z). The parenthetical is narrower than the behaviour, though. `grep.patternType bogus`, which is not a log.* key, breaks the same `git log -1 --format=%cs` read (exp1: `log %cs rc=128`). Under both configs only the date read fails, because `rev-list --count` succeeds. The lib's own comment hedges with "a broken log.* config, say" (`scripts/lib/dev-cycle-read.sh:435`). A precise version would read "(a broken git config, such as log.date)".

**Evidence:** `scripts/dev-cycle.sh:45-50`, `scripts/lib/dev-cycle-read.sh:447-449`; `/tmp/fcu2b1a1-r1-dutz/exp5.log`, `/tmp/fcu2b1a1-r1-dutz/exp1.log`

---

## Claim 14: anybrief (row 323) and its three call sites

**Location:** `scripts/lib/dev-cycle-read.sh:201`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the predicate's equivalence to `isbrief X || isclosed X` and its call sites in scripts/. It does not establish callers on other branches (u2b1a2 adds none, per grep of its build-loop.sh).
**Legibility-target:** for-automated-gate

Definition: `anybrief() { isbrief "$1" || isclosed "$1"; }` (:201). The three call sites are `]] || anybrief "$1"` (writable, :204), `if ! anybrief "$a"; then` (check_brief, :392) and `if ! anybrief "$f" || ! brief_fields "$f"; then continue; fi` (open_shared, :471). Grep across `scripts/*.sh scripts/lib/*.sh test/scripts/*.bats` finds no other. Row 323 named the same three sites (with shared_branches, now open_shared).

**Evidence:** `scripts/lib/dev-cycle-read.sh:201-205`, `:392`, `:471`; `docs/reviews/override-log.md:323`

---

## Claim 15: "--no-textconv: -G greps the diff, and a repo-local textconv driver would run." (and the flag does not change which commit -G finds for an ordinary brief)

**Location:** `scripts/lib/dev-cycle-read.sh:421-422`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a planted `diff.x.textconv` with a checkout `*.md diff=x` (it runs without the flag and not with it), the same commit found with and without the flag when no textconv applies, and this repo's 3 briefs on main (0 differ). It does not establish behaviour for external diff drivers (`diff.*.command`), which `-G` does not invoke.
**Legibility-target:** for-orchestrator-synthesis

Command: `bash /tmp/fcu2b1a1-r1-dutz/exp3.sh` plus a loop over `git ls-tree -r --name-only main -- docs/working/briefs/`, cwd `/tmp` and the worktree, exit 0, at 2026-10-08T19:00:01Z. Output: `without flag: 7a60... ran=yes`, `with flag: 7a60... ran=no`, `repo briefs compared: 3 differ: 0`. A textconv that rewrites `Status` makes the unflagged search find nothing (`''`), which is the misreading the flag prevents.

**Evidence:** `scripts/lib/dev-cycle-read.sh:416-424`; `/tmp/fcu2b1a1-r1-dutz/exp3.log`

---

## Claim 16: "and so is a branch whose count or date cannot be read (a broken log.* config, say: row 307)"

**Location:** `scripts/lib/dev-cycle-read.sh:433-435`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_branch's new else-branch under `log.date bogus` (whole function :436-451 read). It does not establish check_brief under the same config: `dev-cycle.sh --check-brief` aborts there with `fatal: unknown date format bogus` and rc 128, printing no line. That is pre-existing, outside row 307's named sites; see the Goal-Alignment Note.
**Legibility-target:** for-orchestrator-synthesis

Code: `else echo "skip $a: its commit count or date could not be read"; fi` (:449). exp5 output: `log.date bogus: [fatal: unknown date format bogus rc=128] | skip feat/x: its commit count or date could not be read`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:436-451`; `/tmp/fcu2b1a1-r1-dutz/exp5.log`

---

## Claim 17: check_branch's regex checks of the count and the date

**Location:** `scripts/lib/dev-cycle-read.sh:447-448`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that an `ok` line carries a digits-only count and a `DDDD-DD-DD` date (DIGIT is `[0123456789]`, :197), and that a failed `$(...)` assignment falls to the skip. It does not establish date plausibility, since a future date is allowed by the comment at :432.
**Legibility-target:** for-automated-gate

Code: `elif n="$(git rev-list --count "$MAIN_SHA..$sha" 2>/dev/null)" && [[ "$n" =~ ^$DIGIT+$ ]] \` / `&& d="$(git log -1 --format=%cs "$sha" 2>/dev/null)" && [[ "$d" =~ ^$DIGIT{4}-$DIGIT{2}-$DIGIT{2}$ ]]; then echo "ok $a $sha $n $d"`. The clean run in exp5 printed `ok feat/x ... 1 2026-10-08`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:197`, `:447-449`; `/tmp/fcu2b1a1-r1-dutz/exp5.log`

---

## Claim 18: open_shared comment: "computes it once per process, from MAIN_SHA ... brief_fields then reads only those, so every brief is still read through main_entry. Exit 1 is "none"; any exit above 1, a corrupt object's included, fails closed. A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293). Call it in the caller's shell."

**Location:** `scripts/lib/dev-cycle-read.sh:452-460`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache guard, the main_by_name guard, the rc handling, brief_fields' main_entry gate, and the corrupt and missing cases (whole function :462-477 read). It does not establish anything about BRIEF_ODD: the local covers only BRIEF, so a caller's BRIEF_ODD is overwritten. The comment does not claim otherwise.
**Legibility-target:** for-orchestrator-synthesis

Code: `[[ -z "$OPEN_SHARED" ]] || return 0` (:465), `if [[ "$rc" -gt 1 ]]; then OPEN_SHARED=error; return; fi` (:468). brief_fields gates on main_entry: `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (:360). exp4 (Claim 12) shows corrupt → git grep rc 128 → error, and missing → git grep rc 0 with a warning → the brief is not counted. Row 293 (`docs/reviews/override-log.md:293`) is "An unreadable open brief is not counted for F31". Both callers call it in the caller's shell: `open_shared` at status_line :311, and on u2b1a2 `open_shared  # once, in this shell` (:501).

**Evidence:** `scripts/lib/dev-cycle-read.sh:355-378`, `:452-477`; `docs/reviews/override-log.md:293`; `/tmp/fcu2b1a1-r1-dutz/exp4.log`

---

## Claim 19: "show: what a failed test prints, the history included (the plan's test spec; row 223)."

**Location:** `test/scripts/build-loop-check.bats:1249-1250`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helper's body, the plan spec (`docs/working/plan-build-loop-handoff.md:331`) and row 223. It does not establish that the history prints in the row-307 test: under that test's `log.date bogus`, `git log --oneline --graph --all` itself fails.
**Legibility-target:** for-author

Body: `show() { echo "status $status"; echo "$output"; echo "$stderr"; git log --oneline --graph --all; }`. The plan reads "On failure, each test prints the script's whole output and `git log --oneline --graph --all`", and row 223 defers exactly that to "U2's build-loop-check.bats".

The two new tests were run against main's code (command `bats -f 'U2b1a1' test/scripts/build-loop-check.bats`, cwd `/tmp/fcu2b1a1-r1-dutz/old`, exit 1, 2026-10-08T19:00:40Z). In the failing row-307 test, show printed `fatal: unknown date format bogus` where the graph should be. A precise version would note the history is lost when the test's own config breaks `git log`.

**Evidence:** `test/scripts/build-loop-check.bats:1249-1250`, `test/scripts/build-loop-check.bats:1254-1259`; `docs/reviews/override-log.md:223`; `/tmp/fcu2b1a1-r1-dutz/old-tests.log`

---

## Claim 20: "gated BRANCH: brief x, open and naming BRANCH (B is its path), and BRANCH with one commit."

**Location:** `test/scripts/build-loop-check.bats:1251-1252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `gated`, `brief` and `work` in `test/lib/build-loop-fixtures.bash`. It does not establish anything beyond the fixture.
**Legibility-target:** for-automated-gate

`gated() { brief x "Status: open" "Branch: $1"; work "$1"; }`. brief sets `B="docs/working/briefs/2026-10-01-$s.md"` and commits. work runs `git branch -q "$1" main` and then one `commit_all "work on $1"`.

**Evidence:** `test/scripts/build-loop-check.bats:1252`; `test/lib/build-loop-fixtures.bash:49-62`

---

## Claim 21: test title "under a broken log.* config --status skips the branch instead of reading LOOP or DATE wrong (row 307, U2b1a1)"

**Location:** `test/scripts/build-loop-check.bats:1254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing on HEAD and failing on main's code with a wrong LOOP and an empty DATE. It does not establish that other log.* keys behave the same (exp1: `log.decorate bogus` and `log.showSignature` do not break the reads).
**Legibility-target:** for-orchestrator-synthesis

On main's code, the ready tip read as working with no date: `ok docs/working/briefs/2026-10-01-x.md open review feat/x working f9edad63...  0` (old-tests.log). On HEAD the suite passes (81 ok).

**Evidence:** `test/scripts/build-loop-check.bats:1254-1259`; `/tmp/fcu2b1a1-r1-dutz/old-tests.log`, `/tmp/fcu2b1a1-r1-dutz/suite-build-loop-check.log`

---

## Claim 22: test title "--status runs no repo-local textconv driver while it finds a brief's Status commit (U2b1a1)"

**Location:** `test/scripts/build-loop-check.bats:1261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's sensitivity: on main's code it fails with `textconv ran`, and on HEAD it passes. It does not establish other attribute-driven commands (filters), which are U2b1a2's or U2b2's.
**Legibility-target:** for-automated-gate

Old-code run: `not ok 2 ... # textconv ran`. On HEAD, build-loop-check passes 81 of 81.

**Evidence:** `test/scripts/build-loop-check.bats:1261-1268`; `/tmp/fcu2b1a1-r1-dutz/old-tests.log`

---

## Claim 23: "Suites: build-loop-check 81, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit ae08688c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pass counts at ae08688c in this sandbox. It does not establish runs under another TMPDIR layout or host.
**Legibility-target:** for-automated-gate

Commands: `TMPDIR=$(mktemp -d /tmp/fcu2b1a1-r1-tmp-XXXX) timeout 900 bats <suite>` for `test/scripts/{build-loop-check,build-loop-read,dev-cycle,fixture-git-env}.bats` and `test/fixture-hermeticity.bats`, cwd the worktree, all exit 0, started 2026-10-08T18:58:48Z. Results: 81, 19, 78, 2 and 2 ok, with 0 not ok in each.

**Evidence:** `/tmp/fcu2b1a1-r1-dutz/suite-build-loop-check.log`, `/tmp/fcu2b1a1-r1-dutz/suite-build-loop-read.log`, `/tmp/fcu2b1a1-r1-dutz/suite-dev-cycle.log`, `/tmp/fcu2b1a1-r1-dutz/suite-fixture-git-env.log`, `/tmp/fcu2b1a1-r1-dutz/suite-fixture-hermeticity.log`

---

## Claim 24: "115 code lines against main."

**Location:** commit ae08688c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` summed as added plus deleted. It does not establish other counting rules.
**Legibility-target:** for-automated-gate

Output: `15 31 scripts/build-loop.sh`, `2 1 scripts/dev-cycle.sh`, `38 7 scripts/lib/dev-cycle-read.sh`, `21 0 test/scripts/build-loop-check.bats`, which sum to 76 + 39 = 115.

**Evidence:** `/tmp/fcu2b1a1-r1-dutz/exp-git.log`

---

## Claim 25: "the file contents are those of feat/build-loop-u2b1a at c66988b6 for the lib and dev-cycle.sh, and its --status-side hunks of build-loop.sh."

**Location:** commit ae08688c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte identity of the two files, the identity of marker_kind and status_line, and the --status skip clause. It does not establish the unchanged parts of build-loop.sh outside those hunks, which differ by design (the --check code is U2b1a2's).
**Legibility-target:** for-orchestrator-synthesis

`git diff --stat c66988b6 HEAD -- scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh` is empty. The extracted `marker_kind` and `status_line` are the same at c66988b6 and HEAD. The help's 9-line `skip BRIEF: WHY` clause is identical, and c66988b6 only appends its `--check` section after it.

**Evidence:** `/tmp/fcu2b1a1-r1-dutz/exp-git.log`, `/tmp/fcu2b1a1-r1-dutz/a.marker_kind`, `/tmp/fcu2b1a1-r1-dutz/b.marker_kind`

---

## Claim 26: commit message row and rubric references: "anybrief (row 323); open_shared/OPEN_SHARED, build-loop.sh's shared_branches moved in (row 298); check_branch skips ... (row 307); ... --no-textconv ... (iteration 1 C3, pre-existing)"; "rubric code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md"

**Location:** commit ae08688c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's subject and C3's iteration and pre-existing status. It does not re-verdict the rows' decisions.
**Legibility-target:** for-orchestrator-synthesis

Row 298 reads "F31's candidate list is a second read path ... Revisit trigger: U2, which moves brief enumeration into the lib". Row 307 reads "Under a broken git config (`log.date bogus`, ...) ... make marker_kind answer bad on a failed read, and test with `log.date bogus`". Row 323 is the anybrief row. The rubric's C3, under `## Iteration 1 of 3`, reads "`--status` has no state gate: a repo-local `diff.x.textconv` ... Pre-existing on main. ... Fixed: `--no-textconv`".

**Evidence:** `docs/reviews/override-log.md:298`, `:307`, `:323`; `feat/build-loop-u2b1a:docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:78`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 4b** (`docs/working/plan-build-loop-handoff.md:281`): the U2b1a bullet still says merge-tree runs "against the common git dir". Since c66988b6, U2b1a2 runs it in `gate_repo`'s own git dir (GIT_DIR in GATE_TMP) and shares only the object store. The bullet's state-gate list also omits partial clone, shallow and origin/HEAD.

### Mostly Accurate
- **Claim 13** (`scripts/dev-cycle.sh:48-49`): "(a broken log.* config)" is narrower than the behaviour. `grep.patternType bogus` also triggers the skip, and only the date read fails. A precise version would be "a broken git config, such as log.date".
- **Claim 19** (`test/scripts/build-loop-check.bats:1249`): show's "history included" fails in the row-307 test, where `log.date bogus` makes `git log --oneline --graph --all` print `fatal: unknown date format bogus`.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: ae08688c` line at the top.
- Answered: yes
- Out of scope: check_brief under a broken config (pre-existing, not in this diff and not one of row 307's named sites). Under `log.date bogus`, `dev-cycle.sh --check-brief` aborts with rc 128 and prints no line (exp5). Inside `--status`, check_brief's Status-commit read silently yields an empty commit, which `--status` does not print. Also out of scope: the marker_kind failed-read answer renders through status_line as "starts \"handoff:\" but is not a marker: its commit could not be read" (Claim 7's residue), a path that is all but unreachable after check_branch's reads.
- Escalate: nothing. No claim is Incorrect. The Stale plan sentence (4b) and the two Mostly-accurate comments are for-author tightening.
