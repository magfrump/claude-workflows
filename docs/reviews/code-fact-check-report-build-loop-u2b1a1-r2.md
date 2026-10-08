Commit: ae08688c

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1a1 (branch feat/build-loop-u2b1a1)
**Scope:** `git diff main...HEAD` at ae08688c (6 files), plus commit ae08688c's message; replicate r2 of the final confirming pass
**Checked:** 2026-10-08
**Total claims checked:** 25
**Summary:** 24 verified, 0 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. None of its five patterns recurs: the one class that could (a specific measured value quoted from an artifact set, as in "All 85 tests" or "mode1-equiv 33") was checked by execution for every number in the commit message (claims 22, 23), and each one matched. No Incorrect verdict, so nothing is appended. The brief also says to write only this file.

Execution provenance (all runs with git 2.39.5, bash, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, 2026-10-08 between 18:58Z and 19:01Z):
- Suites: `TMPDIR=$(mktemp -d /tmp/fcu2b1a1-r2-tmp-XXXX) bats <file>` for each of the five suites, cwd `/workspace/.claude/wt-build-loop-u2b1a1`, all exit 0, run 18:58:21Z to 18:59:41Z. Output in `/tmp/fcu2b1a1-r2-work/suites.log` and `/tmp/fcu2b1a1-r2-work/<suite>.log`.
- Probe repo `/tmp/fcu2b1a1-r2-p1-rQ4a/r`: main holds one open brief `docs/working/briefs/2026-01-01-x.md` naming `feat/x`, and `feat/x` has one empty `handoff: ready` commit. Git-level probes are in `/tmp/fcu2b1a1-r2-work/exec-gitprobe.log`. Script-level probes are in `/tmp/fcu2b1a1-r2-work/exec-helpclaims.log` and `/tmp/fcu2b1a1-r2-work/exec-checkbrief.log`.
- marker_kind harness: `bash /tmp/fcu2b1a1-r2-p1-rQ4a/run.sh` (it sources marker_kind as extracted from build-loop.sh under `set -euo pipefail`), cwd the probe repo, exit 0. Output is at the end of `exec-gitprobe.log`.

All claims below carry **Legibility-target: for-orchestrator-synthesis** unless they say otherwise.

---

## Claim 1: "with a state gate after `devcontainer-config/install.sh`'s `git_state_gate`"

**Location:** `docs/working/plan-build-loop-handoff.md:84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that a function named `git_state_gate` exists in `devcontainer-config/install.sh`. It does not establish how closely U2b1a2's `state_gate` follows it.
**Legibility-target:** for-orchestrator-synthesis

The function exists: `devcontainer-config/install.sh:209` reads `git_state_gate() {`, and its comment at `:193` reads `# git_state_gate: exit the script, naming each entry, when the checkout's own git`.

**Evidence:** `devcontainer-config/install.sh:193`, `devcontainer-config/install.sh:209`

---

## Claim 2: "`--state` → `ok`, or `refuse state WHAT: WHY` for each planted `.git` state the gate refuses (exit 2), as `--check` prints them (U2b1a's `state_gate`)"

**Location:** `docs/working/plan-build-loop-handoff.md:207`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line form `state_gate` prints on feat/build-loop-u2b1a2 (and c66988b6). It does not establish anything about `--state`, which is unbuilt (U3b).
**Legibility-target:** for-orchestrator-synthesis

c66988b6's `state_gate` (the same function is on feat/build-loop-u2b1a2 at `scripts/build-loop.sh:181`) prints, for example, `echo "refuse state $line: set in $f, it can make the gate's git run a command or change its merge"` and `echo "refuse state $f: present and not empty"`. Its `--check` caller runs `if [[ "$MODE" == check ]]; then state_gate || exit 2; fi`.

**Evidence:** `git show c66988b6:scripts/build-loop.sh` (state_gate and its caller), `git show feat/build-loop-u2b1a2:scripts/build-loop.sh:181`

---

## Claim 3: "Output (U2b1a): `refuse state WHAT: WHY` lines (exit 2 before any brief), then per brief `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY`"

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the output forms that `check_line` and the state gate print on c66988b6 and u2b1a2. It does not establish U2b1b's future per-path lines.
**Legibility-target:** for-orchestrator-synthesis

At c66988b6, `check_line` prints `echo "ok $a $sha $tree"`, `echo "refuse $a: ..."`, or passes status_line's skip line through with `[[ "$out" == "ok "* ]] || { echo "$out"; return; }`. The state gate runs and exits 2 before `read_settings` and the brief loop.

**Evidence:** `git show c66988b6:scripts/build-loop.sh` (check_line, the `check)` arm), `git diff c66988b6 ae08688c -- scripts/build-loop.sh`

---

## Claim 4: "merge-tree run from a fresh empty directory against the common git dir"

**Location:** `docs/working/plan-build-loop-handoff.md:281`
**Type:** Reference / Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how U2b1a's merge-tree is run at d0199be6, at c66988b6 and on feat/build-loop-u2b1a2. It does not judge the rest of the U2b1a bullet (harden's list and the state-gate key list are incomplete against c66988b6, which adds commit-graph, shallow, partial clone and origin/HEAD, but they are not wrong).
**Legibility-target:** for-author

The text was accurate at d0199be6, where merge_result ran `out="$(cd "$t" && git --git-dir="$common" merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)"` with `common="$(git rev-parse --path-format=absolute --git-common-dir)"` (`git show d0199be6:scripts/build-loop.sh:433-437`). Iteration 2 (c66988b6, "merge-tree in a gate-owned repository") replaced that. merge-tree now runs under a gate-owned git dir: `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` (`git show feat/build-loop-u2b1a2:scripts/build-loop.sh:456`), so it no longer runs against the common git dir. This bullet is new in this diff. It describes U2b1a2's code, which is not in this unit. The split note on the next line is accurate.

**Evidence:** `git show d0199be6:scripts/build-loop.sh:424-437`, `git show feat/build-loop-u2b1a2:scripts/build-loop.sh:445-456`, `docs/working/plan-build-loop-handoff.md:281`

---

## Claim 5: "fixes for the iteration-2 findings brought U2b1a to 439 lines. U2b1a1 (`feat/build-loop-u2b1a1`, lands first) ... U2b1a2 (`feat/build-loop-u2b1a2`, on U2b1a1) is `--check` itself: `harden`, the state gate, `gate_repo` and `merge_result`, check_line. `feat/build-loop-u2b1a` keeps both units' review history (iterations 1-2, rubric ...) and is not merged."

**Location:** `docs/working/plan-build-loop-handoff.md:282`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 439 count (by the same numstat formula the commit message uses), the branch stacking, the four named functions on u2b1a2, the rubric on u2b1a, and that u2b1a is not merged into main. It does not establish what the split note says about U2b1a1's content beyond what claims 12-17 check.
**Legibility-target:** for-orchestrator-synthesis

- `git diff --numstat main...c66988b6 -- ':(top)' ':(top,exclude)docs/'` sums to `389 50 439`. feat/build-loop-u2b1a's tip is c66988b6, so the count is the same there.
- `git merge-base --is-ancestor ae08688c feat/build-loop-u2b1a2` exits 0.
- feat/build-loop-u2b1a2's `scripts/build-loop.sh` defines `harden()` at `:158`, `state_gate()` at `:181`, `gate_repo()` at `:448`, `merge_result()` at `:461` and `check_line()` at `:470`.
- `git merge-base --is-ancestor feat/build-loop-u2b1a main` fails, so the branch is not merged.
- The rubric's C3 row is readable on that branch.

Command, cwd `/workspace/.claude/wt-build-loop-u2b1a1`, exit 0, 2026-10-08T19:00Z. These results were transcribed from the terminal and not saved to a file (they are short, deterministic git queries anyone can rerun).

**Evidence:** `docs/working/plan-build-loop-handoff.md:282`, `git show feat/build-loop-u2b1a2:scripts/build-loop.sh:158,181,448,461,470`

---

## Claim 6: Q-119 update 2026-10-08: "U2b was split the same way before any code ... commit d0199be6 on `feat/build-loop-u2b1a`. At review iteration 2 U2b1a split again for size (439 lines): U2b1a1 (the reader side `--status` uses) lands first, then U2b1a2 (`--check`)"

**Location:** `docs/working/questions.md:346`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the entry the line sits in, that d0199be6 is on feat/build-loop-u2b1a and holds the plan's split note, and the 439 figure. It does not establish anything about the Q-119 judgment itself.
**Legibility-target:** for-orchestrator-synthesis

- The nearest heading above line 346 is `### Q-119 · u2a-split-at-cap` (`docs/working/questions.md:329`).
- `git merge-base --is-ancestor d0199be6 feat/build-loop-u2b1a` exits 0.
- `git show --stat d0199be6` lists `docs/working/plan-build-loop-handoff.md | 5 +`, which is the split note.
- 439 matches claim 5.

**Evidence:** `docs/working/questions.md:329`, `docs/working/questions.md:346`

---

## Claim 7: "its branch name is refused (as --check-branch) or its commit count or date cannot be read"

**Location:** `scripts/build-loop.sh:71-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--status` under `log.date bogus`: it prints a skip line, and main's code under the same config misread the brief. It does not establish every config that breaks `git log`. Under `grep.patternType bogus` the skip comes from open_shared instead.
**Legibility-target:** for-orchestrator-synthesis

The script maps check_branch's skip with `*) echo "skip $a: Branch: ${out#*: }"; return ;;` (`scripts/build-loop.sh:334`).

- Executed under `git config log.date bogus`, `bash build-loop.sh --status docs/working/briefs/2026-01-01-x.md` printed `skip docs/working/briefs/2026-01-01-x.md: Branch: its commit count or date could not be read`, exit 0.
- main's script under the same config printed `ok ... open review feat/x working d051f0f4...  0`: LOOP `working` for a `ready` tip, and DATE empty. This is the row 307 misread the change removes.

**Evidence:** `scripts/build-loop.sh:68-76`, `scripts/build-loop.sh:330-335`, `/tmp/fcu2b1a1-r2-work/exec-helpclaims.log`

---

## Claim 8: "git parses the parents; the message is the raw object's text after its first empty line (no header holds one), read with cat-file so no log.* or i18n.* config can change or break it."

**Location:** `scripts/build-loop.sh:283-286`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parse in marker_kind (`:281-308`, read whole) against a plain commit and a commit with a multi-line `gpgsig` header holding a blank-looking line, under `log.date bogus` and `i18n.logOutputEncoding bogus`. It does not establish behaviour under other config families (such as core.*), which the comment does not claim.
**Legibility-target:** for-orchestrator-synthesis

The code reads `p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)"` and `msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"`, then `if [[ "$msg" == *$'\n\n'* ]]; then msg="${msg#*$'\n\n'}"; else msg=""; fi` (`scripts/build-loop.sh:288-291`).

- Under `log.date bogus`, `git log -1 --format=%B` exited 128 (`fatal: unknown date format bogus`), while `git cat-file commit` exited 0 and printed the raw object.
- Under both bogus configs, the harness printed `ready: ready` and `gpgsig: blocked`.
- The gpgsig commit's header has a continuation line of a single space (` \n`). Git prefixes every continuation line with a space, so no header line is empty, and the first `\n\n` is the header/message boundary.

**Evidence:** `scripts/build-loop.sh:281-308`, `/tmp/fcu2b1a1-r2-work/exec-gitprobe.log`

---

## Claim 9: "A failed read answers bad, never working (row 307)."

**Location:** `scripts/build-loop.sh:285-286`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing commit and a failing `git cat-file`, with pipefail on as build-loop.sh sets it (`set -euo pipefail`, `:85`), the only shell marker_kind runs in. It does not hold in a shell without pipefail: there a failing cat-file answers `working` (executed). The function sets no local pipefail, unlike brief_fields' `local -; set -o pipefail`.
**Legibility-target:** for-orchestrator-synthesis

The code is `... || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then echo "bad its commit could not be read"; return` (`scripts/build-loop.sh:288-289`). The harness ran under `set -euo pipefail` and printed:
- `missing: bad its commit could not be read` (an absent id), and
- `catfail: bad its commit could not be read` (with `git cat-file` shadowed to fail).

After `set +o pipefail` it printed `catfail-nopipefail: working`. The only caller, `kind="$(marker_kind "$sha")"` (`:338`), inherits the script's pipefail.

**Evidence:** `scripts/build-loop.sh:85`, `scripts/build-loop.sh:288-290`, `scripts/build-loop.sh:338`, `/tmp/fcu2b1a1-r2-work/exec-gitprobe.log`

---

## Claim 10: "NULs are dropped here (bash would warn on stderr); the NUL check below reads the raw object."

**Location:** `scripts/build-loop.sh:287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a commit whose message holds a NUL after a `handoff: ready` subject: no bash warning, and the answer is `bad it holds a NUL byte`. It does not cover a NUL commit whose subject does not start `handoff:`. That one answers `working` before the NUL check (`:293` comes before `:294`), which is pre-existing and not claimed otherwise.
**Legibility-target:** for-orchestrator-synthesis

The pipe is `git cat-file commit "$1" 2>/dev/null | tr -d '\000'` (`:288`). The NUL check is `if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"` (`:294`). The harness printed `nul: bad it holds a NUL byte`. Its stderr held only the environment's setlocale warning and no `ignored null byte` warning.

**Evidence:** `scripts/build-loop.sh:287-294`, `/tmp/fcu2b1a1-r2-work/exec-gitprobe.log`

---

## Claim 11: "or a branch whose count or date cannot be read (a broken log.* config)"

**Location:** `scripts/dev-cycle.sh:48-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-branch` under `log.date bogus`. It does not establish other broken configs.
**Legibility-target:** for-orchestrator-synthesis

`--check-branch` dispatches to `check_branch "$a"` (`scripts/dev-cycle.sh:200`). Executed under `log.date bogus`, it printed `skip feat/x: its commit count or date could not be read` with exit 0. With a clean config it printed `ok feat/x d051f0f4... 1 2026-10-08`.

**Evidence:** `scripts/dev-cycle.sh:43-50`, `scripts/dev-cycle.sh:200`, `/tmp/fcu2b1a1-r2-work/exec-helpclaims.log`

---

## Claim 12: `anybrief() { isbrief "$1" || isclosed "$1"; }` and its three call sites (writable, check_brief, open_shared; rows 323 and 298)

**Location:** `scripts/lib/dev-cycle-read.sh:201`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the predicate equals the old `isbrief X || isclosed X` at all three sites, and that no other `isbrief ... || isclosed` pair remains in scripts/. It does not establish isbrief's or isclosed's own correctness (unchanged).
**Legibility-target:** for-orchestrator-synthesis

The three call sites are:
- `|| anybrief "$1"` (`:204`, was `|| isbrief "$1" || isclosed "$1"`)
- `if ! anybrief "$a"; then` (`:392`, was `if ! isbrief "$a" && ! isclosed "$a"`, the same by De Morgan)
- `if ! anybrief "$f" || ! brief_fields "$f"` (`:471`, was `if ! { isbrief "$f" || isclosed "$f"; } || ...`)

A grep of scripts/ for `anybrief` finds only these three uses and the definition. Row 323 named exactly these three sites.

**Evidence:** `scripts/lib/dev-cycle-read.sh:199-205`, `scripts/lib/dev-cycle-read.sh:392`, `scripts/lib/dev-cycle-read.sh:471`, `docs/reviews/override-log.md:323`

---

## Claim 13: "--no-textconv: -G greps the diff, and a repo-local textconv driver would run." (and that the flag does not change which commit -G finds for an ordinary brief)

**Location:** `scripts/lib/dev-cycle-read.sh:421-422`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the driver runs without the flag and not with it, and that the found commit is equal for the probe brief and for all 3 briefs on this repo's main. It does not cover a brief that attributes mark binary or `-diff`: -G skips those with or without the flag, and none exists.
**Legibility-target:** for-orchestrator-synthesis

The changed line is `c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv -G'^Status: ' "$MAIN_SHA" -- "$a")"` (`:422`). The probe set `diff.x.textconv "touch .../tc-ran; cat"` and an uncommitted `*.md diff=x`:
- with `--no-textconv`: commit c88c00ac, driver ran: no
- without the flag: the same commit c88c00ac, driver ran: yes

Over every brief on this repo's main (3), the two forms gave equal commits (`differing: 0`, terminal run 19:00Z, not saved to a file). The new bats test 81 passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:416-425`, `/tmp/fcu2b1a1-r2-work/exec-gitprobe.log`, `/tmp/fcu2b1a1-r2-work/build-loop-check.bats.log`

---

## Claim 14: "and so is a branch whose count or date cannot be read (a broken log.* config, say: row 307)", with the count and date regex checks

**Location:** `scripts/lib/dev-cycle-read.sh:433-435`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_branch (`:436-451`, read whole) under `log.date bogus`: rev-list still succeeds, `git log %cs` fails, and the skip is printed. It does not establish that rev-list fails under any log.* config. In practice it is the date read that fails, and the `^$DIGIT+$` check guards only odd output.
**Legibility-target:** for-orchestrator-synthesis

The code is `elif n="$(git rev-list --count "$MAIN_SHA..$sha" 2>/dev/null)" && [[ "$n" =~ ^$DIGIT+$ ]] && d="$(git log -1 --format=%cs "$sha" 2>/dev/null)" && [[ "$d" =~ ^$DIGIT{4}-$DIGIT{2}-$DIGIT{2}$ ]]; then echo "ok $a $sha $n $d"` / `else echo "skip $a: its commit count or date could not be read"; fi` (`:447-449`). `DIGIT='[0123456789]'` (`:197`).

- Under `log.date bogus`, `git rev-list --count main..T` printed `1` with exit 0, and `git log -1 --format=%cs T` exited 128.
- The function then printed the skip (claim 11).
- The row 307 test (bats 80) passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:426-451`, `/tmp/fcu2b1a1-r2-work/exec-gitprobe.log`, `/tmp/fcu2b1a1-r2-work/exec-helpclaims.log`

---

## Claim 15: "in OPEN_SHARED: a caller skips an open brief whose branch is listed (F31), and every open brief when it reads error. open_shared computes it once per process, from MAIN_SHA. ... brief_fields then reads only those, so every brief is still read through main_entry. ... Call it in the caller's shell."

**Location:** `scripts/lib/dev-cycle-read.sh:452-460`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers open_shared (`:461-477`, read whole), its one caller status_line, and the loop that calls status_line in the script's own shell. "Once per process" holds for that caller. A caller that ran open_shared inside `$(...)` would recompute it each time, and the "call it in the caller's shell" line names that duty. It does not establish behaviour for U2b1a2's `--check` caller, which is not in this unit.
**Legibility-target:** for-orchestrator-synthesis

- The cache is checked before any work: `[[ -z "$OPEN_SHARED" ]] || return 0` (`:465`).
- git grep reads `"$MAIN_SHA"` (`:467`).
- Each candidate goes through `brief_fields "$f"` (`:471`), which runs `[[ "$(main_entry "$1")" != blob ]]` before reading (`:360`).
- status_line calls `open_shared` (`scripts/build-loop.sh:311`) and skips with `if [[ "$st" == open && "$OPEN_SHARED" == error ]]` and `== *$'\n'"$(lower "$br")"$'\n'*` (`:326-327`).
- status_line runs as `for a in "${ARGS[@]}"; do status_line "$a"; done` (`scripts/build-loop.sh:351`), not in a subshell.

**Evidence:** `scripts/lib/dev-cycle-read.sh:355-378`, `scripts/lib/dev-cycle-read.sh:452-477`, `scripts/build-loop.sh:309-351`

---

## Claim 16: "Exit 1 is \"none\"; any exit above 1, a corrupt object's included, fails closed. A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293)."

**Location:** `scripts/lib/dev-cycle-read.sh:458-460`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git grep's exit codes for no match, a missing blob and a corrupt blob (git 2.39.5), and the error path through `--status`. It does not establish the exit 0 case with a missing blob beside a matching one (not run; it follows from git grep's documented exit 0 on any match).
**Legibility-target:** for-orchestrator-synthesis

The code is `list="$(git grep ... "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?` and `if [[ "$rc" -gt 1 ]]; then OPEN_SHARED=error; return; fi` (`:467-468`). Executed:

| Case | git grep result |
|---|---|
| No match | exit 1 |
| Blob missing | `error: ... unable to read 07a167f1...`, exit 1 |
| Blob corrupt | `fatal: loose object ... is corrupt`, exit 128 |

Under `grep.patternType bogus`, `--status` printed `skip ...: the open briefs on the default branch could not be listed`. Row 293 reads "An unreadable open brief is not counted for F31", which matches the comment.

**Evidence:** `scripts/lib/dev-cycle-read.sh:466-468`, `docs/reviews/override-log.md:293`, `/tmp/fcu2b1a1-r2-work/exec-gitprobe.log`, `/tmp/fcu2b1a1-r2-work/exec-helpclaims.log`

---

## Claim 17: open_shared is main's shared_branches moved into the lib with unchanged behaviour ("build-loop.sh's shared_branches moved in (row 298)")

**Location:** `scripts/lib/dev-cycle-read.sh:461-477`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every line-level difference between `git show main:scripts/build-loop.sh:306-325` and open_shared, as reached from `--status`. It does not establish behaviour for a future caller that runs open_shared without a default branch found by name. There the new guard gives `error`, where main's body would have run git grep on an empty or fallback MAIN_SHA.
**Legibility-target:** for-orchestrator-synthesis

The differences are:
- The cache test moved from the caller (`[[ -n "$SHARED_BRANCHES" ]] || shared_branches`) into the function (`[[ -z "$OPEN_SHARED" ]] || return 0`).
- A new `if ! main_by_name; then OPEN_SHARED=error; return; fi` (`:466`). build-loop.sh cannot reach it with main_by_name false, because the script exits first: `main_by_name || { echo "build-loop.sh needs a default branch found by name ..." >&2; exit 1; }`.
- `{ isbrief "$f" || isclosed "$f"; }` became `anybrief "$f"`.
- The array `n` was renamed to `count`, and the variable SHARED_BRANCHES to OPEN_SHARED.

The grep, the loop body, the error rule and the list format are character-for-character the same otherwise. The suites build-loop-read (19) and build-loop-check (81), which hold the F31 tests, pass.

**Evidence:** `git show main:scripts/build-loop.sh:306-327`, `scripts/lib/dev-cycle-read.sh:461-477`, `scripts/build-loop.sh:311`, `/tmp/fcu2b1a1-r2-work/suites.log`

---

## Claim 18: "show: what a failed test prints, the history included (the plan's test spec; row 223)."

**Location:** `test/scripts/build-loop-check.bats:1249-1250`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper body and both references. It does not establish that older tests in the file use it (they do not, and the comment does not say they do).
**Legibility-target:** for-author

The helper body is `show() { echo "status $status"; echo "$output"; echo "$stderr"; git log --oneline --graph --all; }` (`:1250`). The plan's test spec reads "On failure, each test prints the script's whole output and `git log --oneline --graph --all`" (`docs/working/plan-build-loop-handoff.md:331`). Row 223 reads "Tests do not print `git log --oneline --graph --all` on failure, which the plan's test spec asks for".

**Evidence:** `test/scripts/build-loop-check.bats:1249-1250`, `docs/working/plan-build-loop-handoff.md:331`, `docs/reviews/override-log.md:223`

---

## Claim 19: "gated BRANCH: brief x, open and naming BRANCH (B is its path), and BRANCH with one commit."

**Location:** `test/scripts/build-loop-check.bats:1251-1252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the state gated leaves, as read from the fixture helpers. It does not cover later `tip` calls, which add commits (test 80 adds a second one).
**Legibility-target:** for-author

- gated is `gated() { brief x "Status: open" "Branch: $1"; work "$1"; }` (`:1252`).
- brief sets `B="docs/working/briefs/2026-10-01-$s.md"` and commits on the current branch (`test/lib/build-loop-fixtures.bash:51-53`).
- work is "BRANCH from main with one commit that changes a file": `git branch -q "$1" main` then `commit_all "work on $1"` (`test/lib/build-loop-fixtures.bash:56-60`).

**Evidence:** `test/scripts/build-loop-check.bats:1251-1252`, `test/lib/build-loop-fixtures.bash:47-60`

---

## Claim 20: test title "under a broken log.* config --status skips the branch instead of reading LOOP or DATE wrong (row 307, U2b1a1)"

**Location:** `test/scripts/build-loop-check.bats:1254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing at HEAD, and main's code misreading the same setup (LOOP `working` for a ready tip, DATE empty). It does not establish other broken log.* keys.
**Legibility-target:** for-orchestrator-synthesis

The test sets `git config log.date bogus` and asserts `[ "$output" = "skip $B: Branch: its commit count or date could not be read" ]` (`:1256-1258`). It passes as `ok 80` in build-loop-check (81 tests, 0 failures). On main's script, the same setup printed `ok ... working d051f0f4...  0` (claim 7).

**Evidence:** `test/scripts/build-loop-check.bats:1254-1259`, `/tmp/fcu2b1a1-r2-work/build-loop-check.bats.log`, `/tmp/fcu2b1a1-r2-work/exec-helpclaims.log`

---

## Claim 21: test title "--status runs no repo-local textconv driver while it finds a brief's Status commit (U2b1a1)"

**Location:** `test/scripts/build-loop-check.bats:1261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing, and its plant being live: the same plant runs the driver when the flag is absent (claim 13). It does not cover drivers reached from other git calls in --status, none of which diff.
**Legibility-target:** for-orchestrator-synthesis

The test sets `git config diff.x.textconv "touch $BATS_TEST_TMPDIR/textconv-ran; cat"` and `printf '*.md diff=x\n' > .gitattributes`, then asserts `[ ! -e "$BATS_TEST_TMPDIR/textconv-ran" ]` (`:1263-1267`). It passes as `ok 81`. Without `--no-textconv`, the same plant ran the driver in the probe repo.

**Evidence:** `test/scripts/build-loop-check.bats:1261-1268`, `/tmp/fcu2b1a1-r2-work/build-loop-check.bats.log`, `/tmp/fcu2b1a1-r2-work/exec-gitprobe.log`

---

## Claim 22: "Suites: build-loop-check 81, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit ae08688c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the pass/fail result of each named suite at ae08688c in this sandbox. It does not establish the other suites in test/.
**Legibility-target:** for-orchestrator-synthesis

`bats --count` gave 81, 19, 78, 2 and 2. Each run exited 0 with 0 `not ok` lines. The command was `TMPDIR=$(mktemp -d /tmp/fcu2b1a1-r2-tmp-XXXX) bats <file>`, cwd `/workspace/.claude/wt-build-loop-u2b1a1`, run 2026-10-08T18:58:21Z to 18:59:41Z.

**Evidence:** `/tmp/fcu2b1a1-r2-work/suites.log`

---

## Claim 23: "115 code lines against main."

**Location:** commit ae08688c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sum of added and deleted lines outside docs/, by the brief's formula. It does not establish any other way of counting.
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` gave the rows `15 31` build-loop.sh, `2 1` dev-cycle.sh, `38 7` lib and `21 0` bats. awk summed them to `76 39 115`. The command ran in cwd `/workspace/.claude/wt-build-loop-u2b1a1`, exit 0, at 2026-10-08T18:58Z. The result was transcribed from the terminal and not saved to a file (it is a short, deterministic query anyone can rerun).

**Evidence:** `git diff --numstat main...ae08688c -- ':(top)' ':(top,exclude)docs/'`

---

## Claim 24: "the file contents are those of feat/build-loop-u2b1a at c66988b6 for the lib and dev-cycle.sh, and its --status-side hunks of build-loop.sh."

**Location:** commit ae08688c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte equality of the lib and dev-cycle.sh, and that the only build-loop.sh differences from c66988b6 are `--check`-side removals plus main's own replace-ref block restored. It does not establish anything about the test file, which the claim does not cover.
**Legibility-target:** for-orchestrator-synthesis

- `git diff --stat c66988b6 ae08688c -- scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh` printed nothing (exit 0).
- `git diff c66988b6 ae08688c -- scripts/build-loop.sh` removes only the `--check` usage, its help block, `harden`, `state_gate`, `gate_repo`, `merge_result`, `check_line` and the `check)` arm. It puts back main's `cfg=...core.useReplaceRefs...` / `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1` lines.
- marker_kind, status_line and the `--status` help skip clause do not differ.

**Evidence:** `git diff c66988b6 ae08688c -- scripts/` (cwd the worktree, 2026-10-08T19:00Z)

---

## Claim 25: the other atoms of the commit body: "check_brief's git log -G takes --no-textconv ... (iteration 1 C3, pre-existing)"; "reviewed there in iterations 1-2 on feat/build-loop-u2b1a (rubric code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md)"; "dev-cycle.sh: --check-branch help names the new skip"; "Tests: --status under log.date bogus (row 307), --status under a textconv plant; the show and gated helpers."

**Location:** commit ae08688c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each reference resolving to what the message says. It does not re-verdict the rubric's contents.
**Legibility-target:** for-orchestrator-synthesis

- The rubric exists on feat/build-loop-u2b1a. Its row 78 reads "| C3 | `--status` has no state gate: a repo-local `diff.x.textconv` with a checkout `*.md diff=x` runs a command through check_brief's `git log -G` (P7). Pre-existing on main. |".
- The dev-cycle.sh help is claim 11.
- The tests and helpers are claims 18-21.

**Evidence:** `git show feat/build-loop-u2b1a:docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:78`, `scripts/dev-cycle.sh:48-49`, `test/scripts/build-loop-check.bats:1249-1268`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 4** (`docs/working/plan-build-loop-handoff.md:281`): The U2b1a bullet says merge-tree runs "from a fresh empty directory against the common git dir". That was true at d0199be6. Since c66988b6 (and on u2b1a2) merge-tree runs under a gate-owned `GIT_DIR` with `GIT_OBJECT_DIRECTORY` set to the repo's object store. The bullet's harden and state-gate lists also predate iterations 1-2. Legibility-target: for-author.

### Mostly Accurate
(none)

### Unverifiable
(none)

## Observation outside the claims (not a finding)

Under `log.date bogus`, check_brief's `git log -G` and its fallback `git log` (`scripts/lib/dev-cycle-read.sh:422-423`) both fail. `dev-cycle.sh --check-brief` exits 128 with `fatal: unknown date format bogus` (`/tmp/fcu2b1a1-r2-work/exec-checkbrief.log`). `--status` writes two `fatal:` lines to stderr, and its check_brief subshell returns `ok BRIEF open ` with an empty commit field. status_line discards that field (`read -r _ _ st _`), so no LOOP or DATE is misread, and the skip comes from check_branch. The commit subject's "reads that fail under a broken config skip instead of misreading" is borne out for check_branch and marker_kind, which the body names, and not for check_brief's Status-commit read. That read predates this unit and is outside row 307's named scope. Legibility-target: for-orchestrator-synthesis.

## Goal-Alignment Note
- Success criterion (restated verbatim): Success criterion: a markdown report saved at the path your task names, structured per your skill, with a `Commit: ae08688c` line at the top.
- Answered: yes
- Out of scope: the check_brief read under a broken log.* config (observation above; pre-existing, not row 307's named scope); U2b1a2's code beyond the plan text that names it
- Escalate: nothing
