# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3d (feat/build-loop-u3d)
**Scope:** the iteration-1 fix commits only: `git diff aff39758..e3781a2c -- scripts test` (commits 23ba4511 and e3781a2c) and those two commit messages. The rest of the branch (525f947a, aff39758, bdf61b16) is context, covered by docs/reviews/code-fact-check-report-u3d-i1.md. References: scripts/lib/dev-cycle-read.sh (truthrule, floor, GATE_CODE), marker_kind, plan D11.
**Checked:** 2026-10-10
**Commit:** e3781a2c
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 13
**Summary:** 10 verified, 2 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 8 entries): no claim below matches a logged pattern. The logged entries are measured values quoted from artifact sets, and this diff's claims are about behaviour.

Execution logs: `/tmp/claude-1000/-workspace/a5f5e272-7757-42c2-8d1d-5c819728d807/scratchpad/u3d-i2/cfc2-execution-logs/` (called `$LOGS` below). Every run used a throwaway copy made with `git archive e3781a2c scripts test`, extracted under `/tmp/claude-1000/u3d-rev-cfc2-zmGj/` (now removed). Nothing in the worktree was edited. Git version: 2.39.5.

---

## Claim 1: "Also refused: the branch in two worktrees, or in one whose directory is missing or a symbolic link (locked or not)."

**Location:** `scripts/build-loop.sh:303-304`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --prompt with the branch in one listed worktree whose path is missing (locked, with --steal and an old lock and tip) or is a symbolic link (unlocked). It does not establish refusal when an ancestor of the worktree path is a symlink (`-L` tests only the last component). A locked symlink was not executed: the probe could not lock through git once the path was a link, and the static argument is in the text.

The check:

```bash
# scripts/build-loop.sh:1297-1302
    if [[ -n "$DIR" && "$DIR" != "$WT" ]]; then x="its branch $br is checked out in $WT, not in --dir's directory"
    # git never calls a locked worktree prunable, and dispatch always locks: test the directory too.
    elif [[ -n "$WT_PRUNE" || ! -d "$WT" || -L "$WT" ]]; then x="its branch $br is checked out in $WT, which is missing or a symbolic link (git worktree unlock, then git worktree prune, drop a missing one)"
    elif [[ -n "$WT_LOCK" ]] && ! steal; then x="$STEAL_WHY"
    elif ! { [[ -z "$WT_LOCK" ]] || git worktree unlock "$WT"; } || ! git worktree lock --reason "$reason" "$WT"; then x="its worktree $WT could not be locked (it may be left unlocked)"
    else DIR="$WT"; fi
```

(excerpt is the `WT_N -eq 1` arm. The enclosing dispatch() runs from :1282 to :1320 and was read in full.)

The test does not read `WT_LOCK`, so locked and unlocked worktrees are treated the same. Executed results:
- The suite at e3781a2c passes 4/4 (`$LOGS/baseline.log`). Its test 4 removes a locked worktree with a 2020 lock and a 2020 tip and gets the "missing or a symbolic link" refusal under `--steal`.
- Mutant M1 cuts the condition to `[[ -n "$WT_PRUNE" ]]` (the pre-fix behaviour). Test 4 then fails with `# status 0` and `# ok docs/working/briefs/2026-10-01-x.md feat/x …/.claude/wt-2026-10-01-x` (`$LOGS/m1.log`). Without the fix, --steal prints ok for a missing DIR.
- A probe moved an unlocked worktree's directory and replaced the path with a symlink to it. The base copy refused: `unlocked: 2 refuse docs/working/briefs/2026-10-01-x.md: its branch feat/x is checked out in …/.claude/wt-2026-10-01-x, which is missing or a symbolic link (…)` (`$LOGS/probe-symlink.log`). Under M1 the same probe printed `unlocked: 0 ok …` and the full prompt (`$LOGS/probe-symlink-m1.log`).

Commands: `TMPDIR=$T/tmp-<name> timeout 600 bats test/scripts/build-loop-dispatch.bats` in `$T/base` and `$T/m1`, exit 0 and 1, 2026-10-11T02:15:04Z–02:15:15Z. Probe: `bats test/scripts/probe-cfc2b.bats` in `$T/base` and `$T/m1`, 2026-10-11T02:15:58Z. Each probe run exited 1. In base, the first (unlocked) assertion passed and its later locked-symlink setup step failed (`lock` status 128). In m1, the first assertion failed.

**Evidence:** `scripts/build-loop.sh:1282-1320`, `test/scripts/build-loop-dispatch.bats:95-98`, `$LOGS/baseline.log`, `$LOGS/m1.log`, `$LOGS/probe-symlink.log`, `$LOGS/probe-symlink-m1.log`

---

## Claim 2: "# git never calls a locked worktree prunable, and dispatch always locks: test the directory too."

**Location:** `scripts/build-loop.sh:1298`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's porcelain listing for a locked worktree whose directory was removed. It does not establish other git versions. "dispatch always locks" covers dispatch's own success paths only: a hand-unlocked worktree, which test 4 makes, is unlocked.

A probe in a throwaway repo did three things: added a locked worktree w1 and an unlocked worktree w2, removed both directories, then ran `git worktree list --porcelain`. The output:

```
worktree …/w1
…
branch refs/heads/b1
locked x

worktree …/w2
…
branch refs/heads/b2
prunable gitdir file points to non-existent location
```

w1 gets no `prunable` line, so `wt_of`'s `prunable|"prunable "*) pr=1` (`scripts/build-loop.sh:1258`) leaves `WT_PRUNE` empty for it. Dispatch's success paths do lock. The add path uses `git worktree add -q --lock --reason "$reason"` (`:1309`), and the existing-worktree path uses `git worktree lock --reason "$reason" "$WT"` (`:1301`). Probe run at 2026-10-11T02:15Z, exit 0. Its output was inspected in the session and not saved to a file (paraphrased — no quote available because the probe printed to the terminal only; the lines above are its verbatim stdout).

**Evidence:** `scripts/build-loop.sh:1246-1260`, `scripts/build-loop.sh:1301`, `scripts/build-loop.sh:1309`

---

## Claim 3: Ordering and race (brief item 1): the missing/symlink check sits before the steal and lock branches, and nothing between the listing and the use races it in an honest run.

**Location:** `scripts/build-loop.sh:1294-1302`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the ordering in dispatch() and the honest-run window from `wt_of` to the printed prompt. It does not establish behaviour against a concurrent same-uid writer that removes or swaps the directory after the test (a Q-103 residual). The test suite also does not pin the order relative to `steal`.

`elif ! wt_of "$br"` (`:1294`) lists the worktrees. The directory test (`:1299`) comes before `steal` (`:1300`) and before the unlock/lock (`:1301`). Between the listing and the test there is only the `--dir` comparison. Between the test and the prompt there are `steal` (reads only `WT_LOCK`, `STATUS[sha]` and the clock), `git worktree unlock` and `git worktree lock`. None of these touches the worktree's directory (paraphrased — no quote available because the claim is about the absence of directory writes across three functions, steal at :1266-1278 and dispatch at :1282-1320, read in full).

An honest `git worktree prune` from elsewhere removes only worktrees git lists as prunable. Claim 2 shows a locked missing one is not listed that way, and an existing directory is not prunable at all. So no honest actor deletes the directory in the window.

Mutant M3 moves the directory check below the `steal` arm. The suite still passes (`$LOGS/m3.log`, 4/4), because in test 4 `steal` succeeds (the lock and tip are both 2020) and the moved check then refuses. The order changes only which message prints when steal would refuse anyway. It never changes whether a missing directory is dispatched into, so the placement is not load-bearing for safety and is not pinned by a test.

**Evidence:** `scripts/build-loop.sh:1266-1278`, `scripts/build-loop.sh:1282-1320`, `$LOGS/m3.log`

---

## Claim 4: The refusal's advice: "(git worktree unlock, then git worktree prune, drop a missing one)"

**Location:** `scripts/build-loop.sh:1299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-directory case, which is what the test does next. It does not claim that prune removes a symlinked worktree, and the "a missing one" wording does not claim that either.

Test 4 follows the refusal with `git worktree unlock "$W"; git worktree prune` and then gets `--prompt` to add a fresh locked worktree (`test/scripts/build-loop-dispatch.bats:98-99`). The suite passes (`$LOGS/baseline.log`). For a symlink to an existing directory, git's listing shows no `prunable` line (probe output under Claim 2's run: the w3 symlink record has no prunable line), so prune would not drop it. The message's "a missing one" restricts the advice to the case where it works.

**Evidence:** `scripts/build-loop.sh:1299`, `test/scripts/build-loop-dispatch.bats:95-99`, `$LOGS/baseline.log`

---

## Claim 5: "or skip BRIEF: WHY as --status skips it, or refuse BRIEF: WHY (a rule above, DIR exists, or the worktree could not be added), leaving no branch or worktree it made (unless removing the branch fails; the refusal then says so)."

**Location:** `scripts/build-loop.sh:290-293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the forms of the line and the failed-removal exception. It does not establish the exit code of a skip (outside this diff) or git's own cleanup of a partly added worktree directory, which was checked in iteration 1.

Dispatch passes through any non-ok status line: `[[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return 1; }` (`:1285`). Every non-ok `STATUS[line]` that status_fields sets starts with `skip`, for example `STATUS[line]="skip $a: the brief is not read"` (`:653`). check_brief's non-ok outputs are all `echo "skip …"` (paraphrased — no quote available because there are nine echo sites in check_brief in scripts/lib/dev-cycle-read.sh, and every one was grepped and starts `skip`).

The exception: `[[ "$MODE" != start ]] || git update-ref -d "refs/heads/$br" "$MAIN_SHA" 2>/dev/null || x+="; its new branch $br could not be removed"` (`:1311`).

**Evidence:** `scripts/build-loop.sh:642-684`, `scripts/build-loop.sh:1285`, `scripts/build-loop.sh:1307-1313`, `scripts/lib/dev-cycle-read.sh` (check_brief)

---

## Claim 6: "a lock is replaced by unlocking first, and a failed relock says the worktree may be left unlocked"

**Location:** `scripts/build-loop.sh:297-299`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message on either failure (unlock or lock). It does not establish whether an unlock failure leaves the old lock in place: the message says "may", which covers both outcomes. A failed relock was not reproduced.

```bash
# scripts/build-loop.sh:1301
    elif ! { [[ -z "$WT_LOCK" ]] || git worktree unlock "$WT"; } || ! git worktree lock --reason "$reason" "$WT"; then x="its worktree $WT could not be locked (it may be left unlocked)"
```

The unlock runs only when `WT_LOCK` is set, before the lock. Either failure gives the one message, which includes "(it may be left unlocked)". The success relock (new reason, the 2020 reason gone) is tested: `! git worktree list --porcelain | grep -q "UTC 2020"` (`test/scripts/build-loop-dispatch.bats:90`).

**Evidence:** `scripts/build-loop.sh:1301`, `test/scripts/build-loop-dispatch.bats:88-90`

---

## Claim 7: "Writes nothing but … --start's branch and its reflog, and the worktrees and locks --start and --prompt make or replace, and its own temporary directory"

**Location:** `scripts/build-loop.sh:306-313`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the write sites in dispatch(): update-ref, update-ref -d, worktree add, unlock and lock. It does not establish what git writes inside `.git/worktrees/NAME/` beyond those commands, which "the worktrees" covers as a whole. The reflog depends on `core.logAllRefUpdates`, which defaults to true in a non-bare repository.

dispatch()'s writes are `git update-ref "refs/heads/$br" "$MAIN_SHA" ""` (`:1308`; creates the branch and, with logAllRefUpdates, its reflog), `git worktree add -q --lock --reason …` (`:1309`), `git update-ref -d` (`:1311`), and `git worktree unlock`/`lock` (`:1301`). "make or replace" matches the unlock-then-lock replacement at `:1301`. loop_prompt only prints (`cat <<PROMPT`, `printf`, `sed` to stdout; `:1322-1344`).

**Evidence:** `scripts/build-loop.sh:1282-1344`

---

## Claim 8: The prompt's floor list: "for a self-merge brief applies the floor (instruction and prompt files and what they import, dot paths, the gate's own code, the user's and the cycle's records such as docs/constraints.md, docs/decisions/ and docs/thoughts/, and working docs or reviews not your own)"

**Location:** `scripts/build-loop.sh:1328`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the match between the listed categories and floor()'s refusal words, and the self-merge-only claim. It does not establish what the walk reaches in any particular repo.

"For a self-merge brief" is right. floor runs only from srules: `if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then` (`scripts/build-loop.sh:883`). srules runs only when `sm` is set: `[[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules …` (`:1094`).

floor's words:

```bash
# scripts/lib/dev-cycle-read.sh:1957-1966
  if truthrule "$lp"; then FLOOR_WHY="$TRUTH_WHY"; [[ "$FLOOR_WHY" != settings ]] || FLOOR_WHY=cycle
  elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate
  elif [[ "$lp" == docs/thoughts/* ]]; then FLOOR_WHY=record
  elif [[ "$lp" == docs/working/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY=working
  elif [[ "$lp" == docs/reviews/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY=review
  elif truthwalk main "$lp"; then FLOOR_WHY="$TRUTH_WHY"  # walk (TRUTH_WHERE says where) or imported
  else
    # A directory at a start's name, or at an imported .md name …
    d="$lp"; while [[ "$d" == */* ]]; do
      d="${d%/*}"; ! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY=below; return 0; }
```

(excerpt ends :1966; floor() continues to :1970 — read.)

truthrule (`dev-cycle-read.sh:1873-1883`) supplies instr, dot, cycle (writable: roadmap, the questions files, the idea log, cycle logs, any brief), settings (docs/dev-cycle.md), user (docs/constraints.md) and record (`^docs/(decisions|human-author)/`). The prompt now names instr+imported, dot, gate, user, cycle and record (with docs/thoughts) and working/review. These are the gaps iteration 1's Claim 19 named, and all but one are fixed.

One category is still missing: `below`, meaning a path under the name of a start file or of an imported `.md` (for example, a new `CLAUDE.md/x`). "instruction and prompt files and what they import" does not tell a loop that such paths are refused. A loop that makes one gets a refusal at the orchestrator's run, not unsafe landing. The "case" word only fires when lowering fails, so it is not a category a loop can steer by.

**Evidence:** `scripts/build-loop.sh:880-891`, `scripts/build-loop.sh:1094`, `scripts/build-loop.sh:1328`, `scripts/lib/dev-cycle-read.sh:243-246`, `scripts/lib/dev-cycle-read.sh:1873-1883`, `scripts/lib/dev-cycle-read.sh:1951-1970`

---

## Claim 9: "\"handoff: stopped: REASON\" (1 to 120 printable ASCII characters, no blank at either end)"

**Location:** `scripts/build-loop.sh:1339`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the REASON grammar against marker_kind. It does not establish the other subject checks (NUL byte, parents, tree), which the prompt words only as "an empty commit".

```bash
# scripts/build-loop.sh:635-636 (inside marker_kind, :603-641 read)
  if [[ "$subj" == "handoff: stopped: "* ]] && printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'; then echo "stopped $r"
  else echo 'bad its subject is not exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (REASON: 1 to 120 printable ASCII characters, no blank at either end)'; fi
```

The pattern requires 1 to 120 characters from 0x20–0x7E, with a non-space first and last character. Space is the only blank in that range, so "no blank at either end" is exact.

**Evidence:** `scripts/build-loop.sh:603-641`

---

## Claim 10: "\"handoff: blocked\", … no line that starts, after blanks, \">\" and list markers, with \"#\", **Needs:**, **Status:**, **Answer, or Q- and a digit"

**Location:** `scripts/build-loop.sh:1338`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with plan D11's text, which matches item for item. It does not establish agreement with code: `--marker`, the reader that enforces it, is not on this branch (U3b).

Plan D11: "`--marker` refuses a body line that starts (after blanks, `>` and list markers) with `#`, `**Needs:**`, `**Status:**`, `**Answer` or `Q-` and a digit" (`docs/working/plan-build-loop-handoff.md:92`). The prompt's list is the same five prefixes with the same lead-in. `grep -n -- '--marker' scripts/build-loop.sh` returns nothing (paraphrased — no quote available because the claim is about absent code). The text has no implementation to verify against until U3b. D11's 100-line, 300-byte cap is not in the prompt; it is the reader's to enforce, and the prompt makes no claim about it.

**Evidence:** `scripts/build-loop.sh:1338`, `docs/working/plan-build-loop-handoff.md:92`

---

## Claim 11: Test comments: "# Create-only: a branch another writer makes after the check is not taken over (i1 A5)." and "# A dead loop's worktree, gone but still locked (git never calls it prunable), even with old times (i1 A1)."

**Location:** `test/scripts/build-loop-dispatch.bats:63`, `test/scripts/build-loop-dispatch.bats:95`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests killing the mutant that removes the property each comment names. It does not establish a real concurrent writer: the shim injects the other writer just before the update-ref, inside the same call.

The create-only shim matches `"$*"` beginning `update-ref refs/heads/feat/x `. It first runs the real `update-ref refs/heads/feat/x $o`, then `exec`s the real git with the original arguments (`:64-65`). dispatch calls `git update-ref "refs/heads/$br" …` with no prefix options, so the match fires. `-d` cleanup (`update-ref -d …`) does not match.

Mutant M2 drops the `""` old value. Test 3 then fails with `# want: its branch feat/x could not be created`, `# status 0`, `# ok … feat/x …` (`$LOGS/m2.log`). Without create-only, the branch is overwritten and dispatched. The test then checks `[ "$(git rev-parse feat/x)" = "$o" ]` (`:68`), proving the other writer's branch survived.

The A1 test's "even with old times" holds: the tip `t` was committed with `GIT_COMMITTER_DATE=2020-01-01T00:00:00Z` (`:83`), and the lock reason ends `UTC 2020-01-01T00:00:00Z` (`:96`). So under M1, `steal` succeeds and the run prints ok, which is the A1 defect (`$LOGS/m1.log`).

Commands: as in Claim 1. m2 exit 1, 2026-10-11T02:15Z.

**Evidence:** `test/scripts/build-loop-dispatch.bats:60-71`, `test/scripts/build-loop-dispatch.bats:83-99`, `$LOGS/m2.log`, `$LOGS/m1.log`

---

## Claim 12: 23ba4511's message: "A1: --prompt refuses when the branch's worktree directory is missing, locked or not … so --steal no longer prints ok for a missing DIR; tested. A2: the header names the skip line. A3: the header names the failed branch removal, the new branch's reflog and --prompt's relock; a failed relock says the worktree may be left unlocked. A4: the prompt's floor list, the stopped REASON's blanks and the blocked-body rule (D11) match the code and plan. A5: a test pins update-ref's create-only old value … Notes: A6 … is corrected in the merge message; A7 … is D13's design, left to U4."

**Location:** commit 23ba4511
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each lettered item against the diff and the runs above. It does not establish the U3d merge message, which does not exist yet.

A1 is verified (Claim 1, M1). A2 is verified (Claim 5). A3 is verified (Claims 6 and 7). A5 is verified (Claim 11, M2). The REASON half of A4 is verified (Claim 9).

A4's "the prompt's floor list … match[es] the code" overstates by one category. The `below` rule is still unnamed (Claim 8). Its "blocked-body rule (D11) match[es] … plan" holds against the plan only (Claim 10).

The Notes' "corrected in the merge message" is a forward reference. No `docs/working/merge-msg-build-loop-u3d.md` exists at e3781a2c (`ls docs/working | grep merge-msg` lists u2a3 through u3a3 only). The override row added in e3781a2c records the intent: "Corrected in the merge message's \"Corrections to branch commit bodies\"" (`docs/reviews/override-log.md`, row for A6).

A7's characterization matches its override row: "By design: D13 runs the gate from the orchestrator's own worktree … Revisit trigger: U4's orchestrator steps".

**Evidence:** `git show 23ba4511`, `docs/reviews/override-log.md` (last two rows), `$LOGS/m1.log`, `$LOGS/m2.log`

---

## Claim 13: e3781a2c's message: "Lite fix-drift over 23ba4511 found the refusal also covers a symlink at the worktree path. Rows for the two declined iteration-1 items."

**Location:** commit e3781a2c
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit's own diff and its two rows. It does not establish that the symlink case is tested: it is not, though this review executed it (Claim 1).

23ba4511 already had `elif [[ -n "$WT_PRUNE" || ! -d "$WT" || -L "$WT" ]]; then x="… which is missing (git worktree unlock, then git worktree prune, drop it)"`. e3781a2c changes only the wording to "missing or a symbolic link … drop a missing one", in the code, the header (`is missing or a symbolic link (locked or not).`) and the test's expected string (`git show e3781a2c -- scripts test`). It also adds exactly two override-log rows, for A6 (Won't-Fix) and A7 (Defer).

**Evidence:** `git show e3781a2c`, `scripts/build-loop.sh:304`, `scripts/build-loop.sh:1299`, `test/scripts/build-loop-dispatch.bats:97`, `docs/reviews/override-log.md`

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 8** (`scripts/build-loop.sh:1328`)
  - **Severity:** Low
  - **Evidence:** `elif truthwalk main "$lp" …` then `{ FLOOR_WHY=below; return 0; }` (`scripts/lib/dev-cycle-read.sh:1962-1966`), against a prompt list that names no below-a-name rule.
  - **Problem:** the prompt's floor list still omits floor's `below` word: a path under the name of a start file or of an imported `.md`.
  - **Fix:** add e.g. "or a path under one's name".
  - **Confidence:** High.
  - **Legibility-target:** the loop prompt.
- **Claim 12** (commit 23ba4511)
  - **Severity:** Low
  - **Problem:** A4 says the floor list matches the code, but it does not quite (Claim 8). The D11 rule matches the plan only, since `--marker` is U3b. "Corrected in the merge message" is a future act: the U3d merge message is not written yet.
  - **Fix:** the merge message's corrections section should carry A6 as the override row promises.
  - **Confidence:** High.
  - **Legibility-target:** the merge message.

### Unverifiable
- **Claim 10** (`scripts/build-loop.sh:1338`)
  - **Severity:** Informational
  - **Problem:** the blocked-body rule matches plan D11 word for word. Checking it against code needs U3b's `--marker`.
  - **Confidence:** High.
  - **Legibility-target:** U3b's review.

### Observations (no verdict change)
- The symlink branch of the A1 fix (`-L "$WT"`) has no test. This review executed it for an unlocked worktree, and M1 shows it is load-bearing (`$LOGS/probe-symlink-m1.log`: the run prints ok).
  - **Severity:** Low
  - **Location:** `test/scripts/build-loop-dispatch.bats:95-98`
  - **Confidence:** High.
  - **Legibility-target:** the test suite.
- No test pins the order of the directory check before `steal` (M3 survives). This is harmless: the order changes only the message when steal would refuse anyway (Claim 3).
  - **Severity:** Informational
  - **Location:** `scripts/build-loop.sh:1299-1300`.

## Goal-Alignment Note

The PR's goal (shared brief) is that --start and --prompt dispatch only under the documented gates, leave nothing behind on a refusal, and print a prompt carrying the plan's content. The fix commits close iteration 1's behavioural red (A1). Executed against the pre-fix condition (M1), `--prompt --steal` printed ok into a missing directory. At e3781a2c it refuses, and it also refuses a symlinked path. The check precedes steal and lock, and no honest actor can remove a locked worktree's directory in the window. The create-only test (A5) kills the mutant it targets. The header's revised refusal, write-set and relock wording all match the code. What remains is documentation precision:
- one floor category (`below`) missing from the loop prompt;
- a blocked-body rule that can only be checked against the plan until U3b;
- a commit Note that defers a correction to a merge message not yet written.

No Incorrect verdict, so `docs/reviews/hallucination-patterns.md` is unchanged.
