# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1a1 (branch `feat/build-loop-u2b1a1`)
**Scope:** `git diff main...HEAD` at ae08688c (docs/working/plan-build-loop-handoff.md, docs/working/questions.md, scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats) plus commit ae08688c's message; merged from replicates r1, r2, r3 (`docs/reviews/code-fact-check-report-build-loop-u2b1a1-r{1,2,3}.md`) by most-severe-wins
**Checked:** 2026-10-08
**Total claims checked:** 32
**Summary:** 29 verified, 2 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable
**Commit:** ae08688c
**Replication:** k=3

Merge notes: this report is a mechanical collation of the three replicate reports; it adds no claims or evidence. Each claim's evidence and prose are carried from the replicate named as winner. Where any replicate split a compound claim, the merged report carries one claim per part, and a replicate that verdicted only the compound is recorded as `(compound)`. Execution provenance for every `executed` claim is in the winning replicate's report header (r1: captured output under `/tmp/fcu2b1a1-r1-dutz/`; r2: `/tmp/fcu2b1a1-r2-work/`; r3: `/tmp/fcu2b1a1-r3-logs/`; all git 2.39.5). All three replicates read the hallucination-pattern log; none found a recurrence (the suite-count pattern was checked and held, Claim 29).

---

## Claim 1: "with a state gate after `devcontainer-config/install.sh`'s `git_state_gate`"

**Location:** `docs/working/plan-build-loop-handoff.md:84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of `git_state_gate` in `devcontainer-config/install.sh`. It does not establish that U2b1a2's `state_gate` mirrors that function key for key.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: "does not establish that U2b1a2's `state_gate` mirrors that function key for key" / "how closely U2b1a2's `state_gate` follows it" · r3 (compound, Claim 24): "does not establish ... the D7 and `--state`/`--check` plan lines beyond the facts named"

The function exists: `devcontainer-config/install.sh:209` reads `git_state_gate() {` (winner r1). r2 adds its comment at `:193`: `# git_state_gate: exit the script, naming each entry, when the checkout's own git`.

**Evidence:** `devcontainer-config/install.sh:193`, `devcontainer-config/install.sh:209`

---

## Claim 2: "`--state` → `ok`, or `refuse state WHAT: WHY` for each planted `.git` state the gate refuses (exit 2), as `--check` prints them (U2b1a's `state_gate`)"

**Location:** `docs/working/plan-build-loop-handoff.md:207`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line format and the exit-2 behaviour of `state_gate` on `feat/build-loop-u2b1a2`. It does not establish `--state` itself, which is a later unit (U3b).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: "does not establish `--state` itself, which is a later unit (U3b)" / "unbuilt (U3b)" · r3 (compound, Claim 24): "does not establish ... the D7 and `--state`/`--check` plan lines beyond the facts named"; r3 cites u2b1a2's state_gate `refuse state …` lines at build-loop.sh:184-185 on that branch

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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r1+r2: "does not establish U2b1b's future per-path lines" · r2: also checked at c66988b6, where the state gate exits 2 before `read_settings` and the brief loop

`feat/build-loop-u2b1a2:scripts/build-loop.sh:484-486` reads `0) echo "ok $a $sha $tree" ;;` / `1) echo "refuse $a: $br conflicts with the default branch" ;;`. Skip lines pass through from status_line: `[[ "$out" == "ok "* ]] || { echo "$out"; return; }` (:472). The exit is `[[ "$fails" -eq 0 ]] || exit 2` (:509), so the run already exits 2 on any non-ok line.

**Evidence:** `feat/build-loop-u2b1a2:scripts/build-loop.sh:209`, `:470-510`

---

## Claim 4: "git 2.39 reads `.gitattributes` from the current directory even under `--work-tree`, so an untracked or `.git`-planted `* merge=union` turned a conflict into a clean merge: reproduced"

**Location:** `docs/working/plan-build-loop-handoff.md:281`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's `merge-tree --write-tree` exit status with `* merge=union` in the cwd: in the toplevel, under `--work-tree` pointing at an empty directory, and planted in `.git` with cwd `.git`. It does not establish other git versions.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "It does not establish other git versions."

Command: `bash /tmp/fcu2b1a1-r1-dutz/exp6.sh`, cwd `/tmp`, exit 0, at 2026-10-08T19:02:10Z. Output: `no attrs: rc=1`, `untracked .gitattributes in toplevel cwd: rc=0`, `cwd toplevel, --work-tree=empty: rc=0`, `cwd .git with planted .gitattributes, --work-tree=empty: rc=0`, `cwd empty dir: rc=1`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:281`; `/tmp/fcu2b1a1-r1-dutz/exp6.log`

---

## Claim 5: "merge-tree run from a fresh empty directory against the common git dir"

**Location:** `docs/working/plan-build-loop-handoff.md:281`
**Type:** Reference / Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how U2b1a's merge-tree is run at d0199be6, at c66988b6 and on feat/build-loop-u2b1a2. It does not judge the rest of the U2b1a bullet (harden's list and the state-gate key list are incomplete against c66988b6, which adds commit-graph, shallow, partial clone and origin/HEAD, but they are not wrong).
**Replicate verdicts:** r1=Stale · r2=Stale · r3=—
**Replicate annotations:** r1+r2: the bullet's state-gate list omits what U2b1a2 now refuses (partial clone `extensions\.partialclone$|remote\..*\.promisor$` :179, `shallow` :192, `origin/HEAD` :198-201; r2 adds commit-graph and harden's list) — "an omission, not a contradiction" · r1: "does not establish whether the U2b1a bullet is meant as history (the next bullet, :282, names `gate_repo` and `merge_result`)" · r2: "This bullet is new in this diff. It describes U2b1a2's code, which is not in this unit. The split note on the next line is accurate." · r1+r2: Legibility-target for-author

The text was accurate at d0199be6, where merge_result ran `out="$(cd "$t" && git --git-dir="$common" merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)"` with `common="$(git rev-parse --path-format=absolute --git-common-dir)"` (`git show d0199be6:scripts/build-loop.sh:433-437`). Iteration 2 (c66988b6, "merge-tree in a gate-owned repository") replaced that. merge-tree now runs under a gate-owned git dir: `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` (`git show feat/build-loop-u2b1a2:scripts/build-loop.sh:456`; r1 cites the same line at :458), so it no longer runs against the common git dir.

**Evidence:** `git show d0199be6:scripts/build-loop.sh:424-437`, `git show feat/build-loop-u2b1a2:scripts/build-loop.sh:445-456`, `docs/working/plan-build-loop-handoff.md:281`

---

## Claim 6: "fixes for the iteration-2 findings brought U2b1a to 439 lines. U2b1a1 (`feat/build-loop-u2b1a1`, lands first) is the reader side ... U2b1a2 (`feat/build-loop-u2b1a2`, on U2b1a1) is `--check` itself: `harden`, the state gate, `gate_repo` and `merge_result`, check_line. `feat/build-loop-u2b1a` keeps both units' review history ... and is not merged."

**Location:** `docs/working/plan-build-loop-handoff.md:282`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 439 count (main...c66988b6, docs/ excluded, as the commit message counts), the stacking, each named function's presence on u2b1a2, and the contents of U2b1a1. It does not establish the count under any other counting rule.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the count under any other counting rule" · r2: "does not establish what the split note says about U2b1a1's content beyond what claims 12-17 check"; results "transcribed from the terminal and not saved to a file" · r3 (compound, Claim 24): "does not establish the U2b1b/U2b2/U2b3 descriptions, which are plans for future units"; the count "was 396 at 9e5d92df, before the iteration-2 fixes"; u2b1a2 is one commit (63ea50e7) over ae08688c; git output not saved to a file

Command: the git block in `/tmp/fcu2b1a1-r1-dutz/exp-git.log`, cwd the worktree, exit 0, at 2026-10-08T19:02:55Z. The output gives `439` for main...c66988b6, and `git merge-base feat/build-loop-u2b1a1 feat/build-loop-u2b1a2` gives `ae08688c...`.

On u2b1a2, `harden() {` (:158), `state_gate() {` (:181), `gate_repo() {` (:448), `merge_result() {` (:461) and `check_line() {` (:470) all exist. `git branch --merged main --list '*u2b1a*'` printed nothing, so no u2b1a branch is merged. The rubric at `feat/build-loop-u2b1a:docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md` has iteration 1 and iteration 2 sections.

**Evidence:** `docs/working/plan-build-loop-handoff.md:282`; `/tmp/fcu2b1a1-r1-dutz/exp-git.log`

---

## Claim 7: Q-119 "Update 2026-10-08: ... commit d0199be6 on `feat/build-loop-u2b1a`. At review iteration 2 U2b1a split again for size (439 lines): U2b1a1 (the reader side `--status` uses) lands first, then U2b1a2 (`--check`); plan step 5's note."

**Location:** `docs/working/questions.md:346`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the entry's identity (Q-119, heading at :329), d0199be6 carrying the plan's U2b split note, and the 439 and order statements. It does not establish anything about 93655b47, the commit that first wrote the update.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish anything about 93655b47, the commit that first wrote the update" · r2: "does not establish anything about the Q-119 judgment itself" · r3 (compound, Claim 24): git output not saved to a file

The update sits under `### Q-119 · u2a-split-at-cap` (:329). `git show d0199be6 -- docs/working/plan-build-loop-handoff.md` adds `+   - **U2b split (2026-10-08, before code; ...`. The 439 count and the stacking are as in Claim 6.

**Evidence:** `docs/working/questions.md:329`, `docs/working/questions.md:346`; d0199be6

---

## Claim 8: --status help, skip clause: "its branch name is refused (as --check-branch) or its commit count or date cannot be read"

**Location:** `scripts/build-loop.sh:71-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path from check_branch's new skip through status_line's `*) echo "skip $a: Branch: ${out#*: }"`. It does not establish marker_kind's new failed-read answer, which reaches the user as `skip BRIEF: the tip of BR starts "handoff:" but is not a marker: its commit could not be read`. The help names no "commit cannot be read" reason, and that wording claims a `handoff:` subject was read. In practice this path is all but unreachable, because check_branch has already peeled `sha^{commit}` and read its date.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: marker_kind's failed-read answer renders as "starts \"handoff:\" but is not a marker: its commit could not be read", a wording that claims a `handoff:` subject was read; all but unreachable (escalation note, see Escalations E2) · r2: "does not establish every config that breaks `git log`. Under `grep.patternType bogus` the skip comes from open_shared instead."; main's script under `log.date bogus` printed LOOP `working` for a `ready` tip and an empty DATE · r3: "does not establish anything about the rest of the help paragraph, which this diff does not change"

`scripts/build-loop.sh:323-327` (status_line, :309-346 read) reads `*) echo "skip $a: Branch: ${out#*: }"; return ;;`. The new test (Claim 27) shows `skip $B: Branch: its commit count or date could not be read` under `log.date bogus`. Command: `bats test/scripts/build-loop-check.bats`, cwd the worktree, exit 0, at 2026-10-08T18:58:48Z: 81 ok.

**Evidence:** `scripts/build-loop.sh:68-76`, `scripts/build-loop.sh:331-336`, `scripts/build-loop.sh:340-341`; `/tmp/fcu2b1a1-r1-dutz/suite-build-loop-check.log`

---

## Claim 9: "the message is the raw object's text after its first empty line (no header holds one)"

**Location:** `scripts/build-loop.sh:284-285`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git-shaped commit objects, including a multi-line `gpgsig` header whose blank line is stored as a single space, and an empty message. It does not establish behaviour for a hand-forged object whose header holds an empty line. Git's own `%B` splits at the same first empty line, so the new reading matches the old one.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish behaviour for a hand-forged object whose header holds an empty line" · r3: "does not establish behaviour on objects git itself would reject with fsck" · r2 (compound, Claim 8): "does not establish behaviour under other config families (such as core.*), which the comment does not claim"; "Git prefixes every continuation line with a space, so no header line is empty"

Code (marker_kind, :281-311 read): `if [[ "$msg" == *$'\n\n'* ]]; then msg="${msg#*$'\n\n'}"; else msg=""; fi` (:292). Command: `bash /tmp/fcu2b1a1-r1-dutz/exp2.sh`, cwd `/tmp`, exit 0, at 2026-10-08T18:59:43Z. Output: `4 gpgsig header: blocked ; log %B first line: handoff: blocked`, `5 empty message: working`.

**Evidence:** `scripts/build-loop.sh:281-311`; `/tmp/fcu2b1a1-r1-dutz/exp2.log`

---

## Claim 10: "read with cat-file so no log.* or i18n.* config can change or break it"

**Location:** `scripts/build-loop.sh:285-286`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `log.date`, `log.decorate`, `log.showSignature`, `i18n.logOutputEncoding` and `i18n.commitEncoding` set to broken values, plus `grep.patternType bogus`. It does not establish replace refs, which cat-file honours exactly as `git log` did (unchanged by this diff).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r3: does not establish replace refs / immunity outside log.* and i18n.* ("replace refs, for example; build-loop.sh exports GIT_NO_REPLACE_OBJECTS") · r2 (compound, Claim 8): "does not establish behaviour under other config families (such as core.*), which the comment does not claim"

Command: `bash /tmp/fcu2b1a1-r1-dutz/exp1.sh`, cwd `/tmp`, exit 0, at 2026-10-08T18:59:17Z. For every config, `cat-file rc=0` and `cat-file msg: handoff: ready`. `git log -1 --format=%cs` fails (`rc=128`) under `log.date bogus` and under `grep.patternType bogus`. `rev-list --count` and `rev-list --parents` succeed under all six.

**Evidence:** `scripts/build-loop.sh:284-289`; `/tmp/fcu2b1a1-r1-dutz/exp1.log`

---

## Claim 11: "A failed read answers bad, never working (row 307)"

**Location:** `scripts/build-loop.sh:286-287`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a failed `rev-list` (missing object) and a failed `cat-file` with `rev-list` succeeding (shimmed), under the script's `set -euo pipefail` (:85, inherited by the `$(marker_kind ...)` subshell). It does not hold without pipefail: run that way, the same shim answers `working`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: does not hold in a shell without pipefail (r1/r2: the cat-file failure answers `working`; r3: answers `ready`) · r2: "The function sets no local pipefail, unlike brief_fields' `local -; set -o pipefail`." · r3: "does not establish the status_line consequence beyond its `bad\ *` arm, which maps to a skip (`:340`)"

Code: `if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then` / `echo "bad its commit could not be read"; return` (:289-290). Command: `bash /tmp/fcu2b1a1-r1-dutz/exp2.sh` (as Claim 9). Output: `6 cat-file fails: bad its commit could not be read`, `7 same, pipefail off: working`, `8 missing object: bad its commit could not be read`. Row 307 (`docs/reviews/override-log.md:307`) asks for exactly this: "make marker_kind answer bad on a failed read".

**Evidence:** `scripts/build-loop.sh:85`, `scripts/build-loop.sh:289-291`; `docs/reviews/override-log.md:307`; `/tmp/fcu2b1a1-r1-dutz/exp2.log`

---

## Claim 12: "NULs are dropped here (bash would warn on stderr); the NUL check below reads the raw object."

**Location:** `scripts/build-loop.sh:288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a NUL in a `handoff:` subject (caught by the raw check) and a NUL in a non-`handoff:` message (answers `working`, no stderr). It does not establish that a NUL in a non-handoff tip is ever reported, because the raw check runs only after the `handoff:` test (unchanged order).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: a NUL in a commit whose subject does not start `handoff:` answers `working` before the NUL check; pre-existing, unchanged by this diff · r2+r3: stderr held only the sandbox's setlocale warning

Raw check: `if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi` (:295). exp2 output: `2 NUL in subject: bad it holds a NUL byte`, `stderr bytes: 0`; `3 NUL, non-handoff: working`, `stderr bytes: 0`. Bash's warning without `tr` was confirmed separately: `bash -c 'x="$(printf "a\0b")"'` prints `warning: command substitution: ignored null byte in input`.

**Evidence:** `scripts/build-loop.sh:288-295`; `/tmp/fcu2b1a1-r1-dutz/exp2.log`, `/tmp/fcu2b1a1-r1-dutz/exp2.nul.err`

---

## Claim 13: --check-branch help: "or a branch whose count or date cannot be read (a broken log.* config)"

**Location:** `scripts/dev-cycle.sh:48-49`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip line and its causes. It does not establish every config that triggers it.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: the parenthetical is narrower than the behaviour — `grep.patternType bogus` (not a log.* key) breaks the same read; only the date read fails; "A precise version would read \"(a broken git config, such as log.date)\"" (for-author) · r2: "does not establish other broken configs" · r3: "does not establish that log.* is the only cause; the help gives log.* as its example"

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
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish callers on other branches (u2b1a2 adds none, per grep of its build-loop.sh)" · r2+r3: does not establish isbrief's or isclosed's own correctness (unchanged)

Definition: `anybrief() { isbrief "$1" || isclosed "$1"; }` (:201). The three call sites are `]] || anybrief "$1"` (writable, :204), `if ! anybrief "$a"; then` (check_brief, :392) and `if ! anybrief "$f" || ! brief_fields "$f"; then continue; fi` (open_shared, :471). Grep across `scripts/*.sh scripts/lib/*.sh test/scripts/*.bats` finds no other. Row 323 named the same three sites (with shared_branches, now open_shared).

**Evidence:** `scripts/lib/dev-cycle-read.sh:201-205`, `:392`, `:471`; `docs/reviews/override-log.md:323`

---

## Claim 15: "--no-textconv: -G greps the diff, and a repo-local textconv driver would run."

**Location:** `scripts/lib/dev-cycle-read.sh:421-422`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_brief's one `git log -G` call. Without the flag, a repo-local `diff.x.textconv` driver plus a checkout `*.md diff=x` runs; with the flag, it does not. It does not establish that no other `--status` git call can run a repo-local command (the state gate that would cover this is U2b1a2's).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish that no other `--status` git call can run a repo-local command (the state gate that would cover this is U2b1a2's)" · r1 (compound): "does not establish behaviour for external diff drivers (`diff.*.command`), which `-G` does not invoke" · r2 (compound): "does not cover a brief that attributes mark binary or `-diff`: -G skips those with or without the flag, and none exists"

```
# scripts/lib/dev-cycle-read.sh:421-422
  # --no-textconv: -G greps the diff, and a repo-local textconv driver would run.
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv -G'^Status: ' "$MAIN_SHA" -- "$a")"
```

(excerpt ends :422; enclosing check_brief() continues to :424, read: `[[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"` and `echo "ok $a ${st#Status: } $c"`. The fallback `git log` has no `-G`, so it computes no diff.)

Probe result: `without: ran=yes` and then `with: ran=no`, with the same commit id printed both times. The suite test at build-loop-check.bats:1261 passes at HEAD and fails ("textconv ran") with main's scripts.

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z. Mutant run: `bats -f 'U2b1a1' test/scripts/build-loop-check.bats` on a copy of the tree with main's scripts/, exit 1, 2026-10-08T19:02:08Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:417-424`; /tmp/fcu2b1a1-r3-logs/probe.log; /tmp/fcu2b1a1-r3-logs/mutant-main-scripts.tap

---

## Claim 16: --no-textconv does not change which commit -G finds for an ordinary brief

**Location:** `scripts/lib/dev-cycle-read.sh:422`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordinary text briefs with no diff driver: the found commit is the same with and without the flag, for all 3 briefs on this repo's main and for the probe's driver-attributed brief. It does not establish equality for a brief that git classifies as binary or that has a textconv driver set, where changing the output is the point of the flag.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish equality for a brief that git classifies as binary or that has a textconv driver set" · r1 (compound): a textconv that rewrites `Status` makes the unflagged search find nothing (`''`), "which is the misreading the flag prevents" · r2 (compound): 3-brief comparison "terminal run 19:00Z, not saved to a file"

The command ran both ways for every path under `docs/working/briefs/` at main and printed `briefs=3 differing=0`. In the probe, both forms printed `90a6ac089de8ddfe52d5e841b926e7190c32a746`.

Paraphrased — no quote available because this is git's documented behaviour, not repo code: `--no-textconv` only takes effect when a textconv driver is configured for the path, so a path without one is diffed the same way.

Command: a `for f in $(git ls-tree -r --name-only $M -- docs/working/briefs/)` loop comparing the two `git log` forms, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:16Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:422`; /tmp/fcu2b1a1-r3-logs/textconv-compare.log; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 17: "and so is a branch whose count or date cannot be read (a broken log.* config, say: row 307)"

**Location:** `scripts/lib/dev-cycle-read.sh:433-435`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_branch's new else-branch under `log.date bogus` (whole function :436-451 read). It does not establish check_brief under the same config: `dev-cycle.sh --check-brief` aborts there with `fatal: unknown date format bogus` and rc 128, printing no line. That is pre-existing, outside row 307's named sites; see the Goal-Alignment Note.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: check_brief under the same config aborts with rc 128 and no line; pre-existing, outside row 307's named sites (escalation note, see Escalations E1) · r2 (compound, Claim 14): "does not establish that rev-list fails under any log.* config. In practice it is the date read that fails" · r3 (compound, Claim 4): "does not establish which other configs break the count read: rev-list was not broken by any log.* key tried"; "Row 307 asked for \"refuse on failure\" in --check; here the lib skips and --status passes the skip on. That outcome is settled under row 307"

Code: `else echo "skip $a: its commit count or date could not be read"; fi` (:449). exp5 output: `log.date bogus: [fatal: unknown date format bogus rc=128] | skip feat/x: its commit count or date could not be read`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:436-451`; `/tmp/fcu2b1a1-r1-dutz/exp5.log`

---

## Claim 18: check_branch's regex checks of the count and the date

**Location:** `scripts/lib/dev-cycle-read.sh:447-448`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that an `ok` line carries a digits-only count and a `DDDD-DD-DD` date (DIGIT is `[0123456789]`, :197), and that a failed `$(...)` assignment falls to the skip. It does not establish date plausibility, since a future date is allowed by the comment at :432.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish date plausibility, since a future date is allowed by the comment at :432" · r2 (compound): "the `^$DIGIT+$` check guards only odd output" · r3 (compound): "A failed read and a malformed value both reach the `skip` arm"

Code: `elif n="$(git rev-list --count "$MAIN_SHA..$sha" 2>/dev/null)" && [[ "$n" =~ ^$DIGIT+$ ]] \` / `&& d="$(git log -1 --format=%cs "$sha" 2>/dev/null)" && [[ "$d" =~ ^$DIGIT{4}-$DIGIT{2}-$DIGIT{2}$ ]]; then echo "ok $a $sha $n $d"`. The clean run in exp5 printed `ok feat/x ... 1 2026-10-08`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:197`, `:447-449`; `/tmp/fcu2b1a1-r1-dutz/exp5.log`

---

## Claim 19: "open_shared computes it once per process, from MAIN_SHA."

**Location:** `scripts/lib/dev-cycle-read.sh:455`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guard and the only call site (status_line, run in the main shell for --status). It does not establish once-per-process for a future caller that runs open_shared first inside a `$(...)`; the comment's "Call it in the caller's shell" (Claim 23) covers that case.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2+r3: a caller that ran open_shared inside `$(...)` would recompute it; "call it in the caller's shell" names that duty · r1 (compound, Claim 18): "does not establish anything about BRIEF_ODD: the local covers only BRIEF, so a caller's BRIEF_ODD is overwritten. The comment does not claim otherwise." · r2 (compound): "does not establish behaviour for U2b1a2's `--check` caller, which is not in this unit"

```
# scripts/lib/dev-cycle-read.sh:465
  [[ -z "$OPEN_SHARED" ]] || return 0
# scripts/lib/dev-cycle-read.sh:467
  list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?
# scripts/build-loop.sh:351
    for a in "${ARGS[@]}"; do status_line "$a"; done
```

Both the `error` result and the newline-delimited list are non-empty, so either one stops recomputation.

**Evidence:** `scripts/lib/dev-cycle-read.sh:461-477`; `scripts/build-loop.sh:309-311`, `:351`

---

## Claim 20: "brief_fields then reads only those, so every brief is still read through main_entry"

**Location:** `scripts/lib/dev-cycle-read.sh:457-458`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every listed path goes through anybrief and brief_fields, and that brief_fields reads a blob only after main_entry answers `blob`. It does not establish that the git grep list is complete; the comment calls it a superset and "fences are not modelled".
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish that the git grep list is complete; the comment calls it a superset and \"fences are not modelled\"" · r1 (compound): BRIEF_ODD overwritten (see Claim 19)

```
# scripts/lib/dev-cycle-read.sh:471
    if ! anybrief "$f" || ! brief_fields "$f"; then continue; fi
# scripts/lib/dev-cycle-read.sh:360
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:355-385`, `:471`

---

## Claim 21: "Exit 1 is "none"; any exit above 1, a corrupt object's included, fails closed."

**Location:** `scripts/lib/dev-cycle-read.sh:458-459`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git grep's exit codes on git 2.39.5: 1 when nothing matches, 128 when a loose object is corrupt. It also covers the code mapping any exit above 1 to OPEN_SHARED=error, and status_line skipping every open brief on error. It does not establish exit codes for packed-object corruption.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish exit codes for packed-object corruption" · r2 (compound): under `grep.patternType bogus`, `--status` printed `skip ...: the open briefs on the default branch could not be listed`

```
# scripts/lib/dev-cycle-read.sh:467-468
  list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?
  if [[ "$rc" -gt 1 ]]; then OPEN_SHARED=error; return; fi
# scripts/build-loop.sh:326
  if [[ "$st" == open && "$OPEN_SHARED" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed"; return; fi
```

Probe output: `none exit=1` and `corrupt exit=128` ("fatal: loose object … is corrupt").

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:467-468`; `scripts/build-loop.sh:326`; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 22: "A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293)."

**Location:** `scripts/lib/dev-cycle-read.sh:459-460`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing loose blob: git grep prints `error: … unable to read …` and exits 1, so the file is not listed and not counted. It does not establish the exit-0 case, where another brief matches; static reading shows that case also lists only readable matches. Row 293 is the Won't-Fix row for this behaviour.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2+r3: the exit-0 case (a missing blob beside a matching one) was not run; it follows from git grep's documented exit 0 on any match / static reading · r1 (compound): with a missing object git grep exits 0 with a warning and the brief is not counted, while shared detection still works via the other briefs (exp4)

Probe output: `error: 'main:docs/working/briefs/2026-10-01-x.md': unable to read 07a167f1…` followed by `missing exit=1`. Row 293 reads "An unreadable open brief is not counted for F31 (iteration 2 C21) | 🟢 Consider | Won't-Fix" (`docs/reviews/override-log.md:293`).

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:459-460`; `docs/reviews/override-log.md:293`; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 23: "Call it in the caller's shell."

**Location:** `scripts/lib/dev-cycle-read.sh:460`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that open_shared's result is the global OPEN_SHARED, which a subshell call would discard, and that the one caller follows the rule. It does not cover U2b1a2's caller.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2+r3: does not cover U2b1a2's caller · r1 (compound): on u2b1a2 the caller reads `open_shared  # once, in this shell` (:501)

```
# scripts/lib/dev-cycle-read.sh:461, :475
OPEN_SHARED=""
  OPEN_SHARED=$'\n'
# scripts/build-loop.sh:311 (inside status_line, itself called at :351 outside any $(...))
  open_shared
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:461-477`; `scripts/build-loop.sh:309-311`, `:351`

---

## Claim 24: open_shared is main's shared_branches moved into the lib with unchanged behaviour ("build-loop.sh's shared_branches moved in (row 298)"; status_line uses open_shared)

**Location:** `scripts/lib/dev-cycle-read.sh:461-477`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every line-level difference between `git show main:scripts/build-loop.sh:306-325` and open_shared, as reached from `--status`. It does not establish behaviour for a future caller that runs open_shared without a default branch found by name. There the new guard gives `error`, where main's body would have run git grep on an empty or fallback MAIN_SHA.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: for a future lib caller without a default branch found by name (e.g. U2b1a2's check mode) the new `main_by_name` guard is a real change, toward fail-closed; unobservable from build-loop.sh, which exits at :120 first · r1: executed old-vs-new `--status` outputs for shared, mixed-case, CRLF, corrupt-object and missing-object briefs were line-for-line identical (exp4); r1 located the claim at `scripts/build-loop.sh:311` · r3: build-loop-read.bats (untouched, holds the F31 tests) passes 19/19 at HEAD

The differences are:
- The cache test moved from the caller (`[[ -n "$SHARED_BRANCHES" ]] || shared_branches`) into the function (`[[ -z "$OPEN_SHARED" ]] || return 0`).
- A new `if ! main_by_name; then OPEN_SHARED=error; return; fi` (`:466`). build-loop.sh cannot reach it with main_by_name false, because the script exits first: `main_by_name || { echo "build-loop.sh needs a default branch found by name ..." >&2; exit 1; }`.
- `{ isbrief "$f" || isclosed "$f"; }` became `anybrief "$f"`.
- The array `n` was renamed to `count`, and the variable SHARED_BRANCHES to OPEN_SHARED.

The grep, the loop body, the error rule and the list format are character-for-character the same otherwise. The suites build-loop-read (19) and build-loop-check (81), which hold the F31 tests, pass.

**Evidence:** `git show main:scripts/build-loop.sh:306-327`, `scripts/lib/dev-cycle-read.sh:461-477`, `scripts/build-loop.sh:311`, `/tmp/fcu2b1a1-r2-work/suites.log`

---

## Claim 25: "show: what a failed test prints, the history included (the plan's test spec; row 223)."

**Location:** `test/scripts/build-loop-check.bats:1249-1250`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helper's body, the plan spec (`docs/working/plan-build-loop-handoff.md:331`) and row 223. It does not establish that the history prints in the row-307 test: under that test's `log.date bogus`, `git log --oneline --graph --all` itself fails.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r3: in the row-307 test `log.date bogus` is still set when show runs, so the history line prints `fatal: unknown date format bogus` instead of the graph (for-author) · r3: suggested fix "show could run `git -c log.date=default log …`. This is not a code finding." (escalation note, see Escalations E3) · r2: "does not establish that older tests in the file use it (they do not, and the comment does not say they do)"

Body: `show() { echo "status $status"; echo "$output"; echo "$stderr"; git log --oneline --graph --all; }`. The plan reads "On failure, each test prints the script's whole output and `git log --oneline --graph --all`", and row 223 defers exactly that to "U2's build-loop-check.bats".

The two new tests were run against main's code (command `bats -f 'U2b1a1' test/scripts/build-loop-check.bats`, cwd `/tmp/fcu2b1a1-r1-dutz/old`, exit 1, 2026-10-08T19:00:40Z). In the failing row-307 test, show printed `fatal: unknown date format bogus` where the graph should be. A precise version would note the history is lost when the test's own config breaks `git log`.

**Evidence:** `test/scripts/build-loop-check.bats:1249-1250`, `test/scripts/build-loop-check.bats:1254-1259`; `docs/reviews/override-log.md:223`; `/tmp/fcu2b1a1-r1-dutz/old-tests.log`

---

## Claim 26: "gated BRANCH: brief x, open and naming BRANCH (B is its path), and BRANCH with one commit."

**Location:** `test/scripts/build-loop-check.bats:1251-1252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `gated`, `brief` and `work` in `test/lib/build-loop-fixtures.bash`. It does not establish anything beyond the fixture.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: does not cover later `tip` calls / what the tests add on top, which add commits (r2: test 80 adds a second one)

`gated() { brief x "Status: open" "Branch: $1"; work "$1"; }`. brief sets `B="docs/working/briefs/2026-10-01-$s.md"` and commits. work runs `git branch -q "$1" main` and then one `commit_all "work on $1"`.

**Evidence:** `test/scripts/build-loop-check.bats:1252`; `test/lib/build-loop-fixtures.bash:49-62`

---

## Claim 27: test title "under a broken log.* config --status skips the branch instead of reading LOOP or DATE wrong (row 307, U2b1a1)"

**Location:** `test/scripts/build-loop-check.bats:1254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing on HEAD and failing on main's code with a wrong LOOP and an empty DATE. It does not establish that other log.* keys behave the same (exp1: `log.decorate bogus` and `log.showSignature` do not break the reads).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: does not establish other broken log.* keys (r1: `log.decorate bogus` and `log.showSignature` do not break the reads) · r3: "does not establish coverage of the marker_kind cat-file path on its own, because the check_branch skip fires first in this test"

On main's code, the ready tip read as working with no date: `ok docs/working/briefs/2026-10-01-x.md open review feat/x working f9edad63...  0` (old-tests.log). On HEAD the suite passes (81 ok).

**Evidence:** `test/scripts/build-loop-check.bats:1254-1259`; `/tmp/fcu2b1a1-r1-dutz/old-tests.log`, `/tmp/fcu2b1a1-r1-dutz/suite-build-loop-check.log`

---

## Claim 28: test title "--status runs no repo-local textconv driver while it finds a brief's Status commit (U2b1a1)"

**Location:** `test/scripts/build-loop-check.bats:1261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's sensitivity: on main's code it fails with `textconv ran`, and on HEAD it passes. It does not establish other attribute-driven commands (filters), which are U2b1a2's or U2b2's.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish other attribute-driven commands (filters), which are U2b1a2's or U2b2's" · r2+r3: does not establish that no other `--status` git call honours a textconv driver (r2: "none of which diff")

Old-code run: `not ok 2 ... # textconv ran`. On HEAD, build-loop-check passes 81 of 81.

**Evidence:** `test/scripts/build-loop-check.bats:1261-1268`; `/tmp/fcu2b1a1-r1-dutz/old-tests.log`

---

## Claim 29: "Suites: build-loop-check 81, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit ae08688c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pass counts at ae08688c in this sandbox. It does not establish runs under another TMPDIR layout or host.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish runs under another TMPDIR layout or host" · r2+r3: does not establish the other suites in test/ (r3: hermeticity-lint was not named and not run) · r1+r2+r3: resembles the logged hallucination pattern (suite counts in a commit message), but the counts hold

Commands: `TMPDIR=$(mktemp -d /tmp/fcu2b1a1-r1-tmp-XXXX) timeout 900 bats <suite>` for `test/scripts/{build-loop-check,build-loop-read,dev-cycle,fixture-git-env}.bats` and `test/fixture-hermeticity.bats`, cwd the worktree, all exit 0, started 2026-10-08T18:58:48Z. Results: 81, 19, 78, 2 and 2 ok, with 0 not ok in each.

**Evidence:** `/tmp/fcu2b1a1-r1-dutz/suite-build-loop-check.log`, `/tmp/fcu2b1a1-r1-dutz/suite-build-loop-read.log`, `/tmp/fcu2b1a1-r1-dutz/suite-dev-cycle.log`, `/tmp/fcu2b1a1-r1-dutz/suite-fixture-git-env.log`, `/tmp/fcu2b1a1-r1-dutz/suite-fixture-hermeticity.log`

---

## Claim 30: "115 code lines against main."

**Location:** commit ae08688c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` summed as added plus deleted. It does not establish other counting rules.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: does not establish other counting rules · r2: result "transcribed from the terminal and not saved to a file" · r3 (compound, Claim 22): "does not establish what \"code lines\" means beyond \"everything outside docs/, tests included\", which matches the plan's cap (\"tests count toward the cap\")"

Output: `15 31 scripts/build-loop.sh`, `2 1 scripts/dev-cycle.sh`, `38 7 scripts/lib/dev-cycle-read.sh`, `21 0 test/scripts/build-loop-check.bats`, which sum to 76 + 39 = 115.

**Evidence:** `/tmp/fcu2b1a1-r1-dutz/exp-git.log`

---

## Claim 31: "the file contents are those of feat/build-loop-u2b1a at c66988b6 for the lib and dev-cycle.sh, and its --status-side hunks of build-loop.sh."

**Location:** commit ae08688c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte equality of the lib and dev-cycle.sh, and that the only build-loop.sh differences from c66988b6 are `--check`-side removals plus main's own replace-ref block restored. It does not establish anything about the test file, which the claim does not cover.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the unchanged parts of build-loop.sh outside those hunks, which differ by design (the --check code is U2b1a2's)" · r2: "does not establish anything about the test file, which the claim does not cover" · r3 (compound): c66988b6 is the tip of feat/build-loop-u2b1a

- `git diff --stat c66988b6 ae08688c -- scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh` printed nothing (exit 0).
- `git diff c66988b6 ae08688c -- scripts/build-loop.sh` removes only the `--check` usage, its help block, `harden`, `state_gate`, `gate_repo`, `merge_result`, `check_line` and the `check)` arm. It puts back main's `cfg=...core.useReplaceRefs...` / `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1` lines.
- marker_kind, status_line and the `--status` help skip clause do not differ.

**Evidence:** `git diff c66988b6 ae08688c -- scripts/` (cwd the worktree, 2026-10-08T19:00Z)

---

## Claim 32: commit message row and rubric references: "anybrief (row 323); open_shared/OPEN_SHARED, build-loop.sh's shared_branches moved in (row 298); check_branch skips ... (row 307); ... --no-textconv ... (iteration 1 C3, pre-existing)"; "rubric code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md"

**Location:** commit ae08688c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's subject and C3's iteration and pre-existing status. It does not re-verdict the rows' decisions.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: does not re-verdict the rows' decisions / the rubric's contents / the iteration 1-2 review content · r3: "The behavioural halves rest on Claims 1, 2, 4, 10 and 13-16" (r3 numbering; here Claims 8-24)

Row 298 reads "F31's candidate list is a second read path ... Revisit trigger: U2, which moves brief enumeration into the lib". Row 307 reads "Under a broken git config (`log.date bogus`, ...) ... make marker_kind answer bad on a failed read, and test with `log.date bogus`". Row 323 is the anybrief row. The rubric's C3, under `## Iteration 1 of 3`, reads "`--status` has no state gate: a repo-local `diff.x.textconv` ... Pre-existing on main. ... Fixed: `--no-textconv`".

**Evidence:** `docs/reviews/override-log.md:298`, `:307`, `:323`; `feat/build-loop-u2b1a:docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:78`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 5** (`docs/working/plan-build-loop-handoff.md:281`): the U2b1a bullet still says merge-tree runs "from a fresh empty directory against the common git dir". That was true at d0199be6; since c66988b6 (and on u2b1a2) merge-tree runs under a gate-owned `GIT_DIR` and shares only the object store. The bullet's harden and state-gate lists also predate iterations 1-2 (omit partial clone, shallow, origin/HEAD, commit-graph).

### Mostly Accurate
- **Claim 13** (`scripts/dev-cycle.sh:48-49`): "(a broken log.* config)" is narrower than the behaviour. `grep.patternType bogus` also triggers the skip, and only the date read fails. A precise version would be "a broken git config, such as log.date".
- **Claim 25** (`test/scripts/build-loop-check.bats:1249`): show's "history included" fails in the row-307 test, where `log.date bogus` makes `git log --oneline --graph --all` print `fatal: unknown date format bogus`.

### Unverifiable
(none)

## Escalations

All three replicates' Goal-Alignment `Escalate:` lines read `nothing`. The entries below come from claim-prose escalation notes, r3's Escalations section, and Out-of-scope bullets that hand off a concrete risk. None names a critic, so each is addressed to `orchestrator`.

- **E1** · `scripts/lib/dev-cycle-read.sh:422-423` · raised by r1 (Claim 17 scope; Goal-Alignment Out of scope) and r2 (Observation outside the claims; Goal-Alignment Out of scope) · addressee: orchestrator — check_brief's Status-commit read under a broken config (`log.date bogus`): `dev-cycle.sh --check-brief` aborts with `fatal: unknown date format bogus`, rc 128, printing no line; inside `--status` the check_brief subshell returns `ok BRIEF open ` with an empty commit field, which status_line discards, and `--status` writes two `fatal:` lines to stderr. The commit subject's "reads that fail under a broken config skip instead of misreading" holds for check_branch and marker_kind but not for this read. Pre-existing, outside row 307's named sites.
- **E2** · `scripts/build-loop.sh:289-290` (rendered via status_line `:340-341`) · raised by r1 (Claim 8 scope; Goal-Alignment Out of scope) · addressee: orchestrator — marker_kind's new failed-read answer renders to the user as `skip BRIEF: the tip of BR starts "handoff:" but is not a marker: its commit could not be read`, wording that claims a `handoff:` subject was read; the `--status` help names no "commit cannot be read" reason. All but unreachable after check_branch's reads.
- **E3** · `test/scripts/build-loop-check.bats:1250` · raised by r3 (Escalations section, for-author note); r1 records the same residue as for-author tightening (Claim 25; its Escalate line names "the two Mostly-accurate comments" as for-author) · addressee: orchestrator (for-author) — in the row-307 test show's `git log` fails under `log.date bogus`; if the history matters there, show needs a config override such as `git -c log.date=default`.

## Verdict stability

- Total clusters: 32 (sub-claim rows; Claims 4 and 5 split by r1, Claims 15/16 split by r3, Claims 17/18 split by r1, Claims 19-23 split by r3, Claims 9/10 split by r1 and r3)
- Clusters where all reporting replicates agreed: 30 (including one single-replicate detection, Claim 4, and two clusters reported by two replicates, Claims 3 and 5)
- Clusters where verdicts disagreed: 2
  - Claim 13 (`scripts/dev-cycle.sh:48-49`): r1=Mostly accurate · r2=Verified · r3=Verified → Mostly accurate
  - Claim 25 (`test/scripts/build-loop-check.bats:1249-1250`): r1=Mostly accurate · r2=Verified · r3=Mostly accurate → Mostly accurate
- Agreement rate: 30/32 = 93.75%
- Merged verdicts: 29 Verified, 2 Mostly accurate, 1 Stale, 0 Incorrect, 0 Unverifiable. In both disagreements the minority or majority that called Mostly accurate won under most-severe-wins; no replicate called anything Incorrect.
