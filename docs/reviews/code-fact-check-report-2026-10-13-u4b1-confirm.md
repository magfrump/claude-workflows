Commit: 923f7d26

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u4b1, branch feat/build-loop-u4b1)
**Scope:** fix range `git diff ea59b0c3..923f7d26 -- scripts skills test` (scripts/build-loop.sh, scripts/health-check.sh, skills/dev-cycle/SKILL.md, test/scripts/health-check-lock.bats) and commit 923f7d26's message. Note: the brief's "Changed:" list (pr-prep.md, dev-cycle-read.sh, d6-snippet.bash, build-loop-orchestrator.bats) describes earlier branch commits, not this range; those files were read as context only.
**Checked:** 2026-10-13
**Replication:** k=1 (confirming pass)
**Total claims checked:** 18
**Summary:** 12 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`, 30 lines) read; no claim below matches a logged pattern.

Execution logs live in the session scratchpad `/tmp/claude-1000/-workspace/5f7c1a26-c882-447d-bbc1-af5199ac916b/scratchpad/u4b1-fcc/` (abbreviated `$S` below). Probes ran in `/tmp/u4b1-fcc-XXXX` temp dirs or clones, all removed after.

---

## Claim 1: "(any key of the lib's HARDEN list, which git_harden's comment explains; a git -c pair would win over it)"

**Location:** `scripts/build-loop.sh:136-137`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that caller_gate refuses a caller pair for every HARDEN key by name and that git_harden's comment explains each key; does not establish that every future HARDEN key gets a comment line (nothing pins comment to array).

`caller_gate` iterates the lib's array: `for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done` (`scripts/build-loop.sh:666`), and the array is `HARDEN=(core.useReplaceRefs=false … log.showSignature=false commit.gpgSign=false)` (`scripts/lib/dev-cycle-read.sh:354`). The comment above it explains each key, ending "and no commit signing (commit.gpgSign runs gpg.program on a commit or merge …)" (`scripts/lib/dev-cycle-read.sh:336-343`).

Executed: in a clone of /workspace, `GIT_CONFIG_PARAMETERS="'commit.gpgSign'='false'" bash $W/scripts/build-loop.sh --state` printed `refuse state commit.gpgsign: set by the caller's git -c or GIT_CONFIG_COUNT pairs, …` with exit 2; same for `log.date` and `core.multiPackIndex`; plain `--state` printed `ok`, exit 0. cwd: `/tmp/u4b1-fcc-XXXX/r`; 2026-10-13T23:07:23Z.

**Evidence:** `scripts/build-loop.sh:133-138`, `scripts/build-loop.sh:650-672`, `scripts/lib/dev-cycle-read.sh:336-366`, `$S/probe-state.sh`, `$S/probe-state.log`

---

## Claim 2a: "Seconds to wait for another run's lock … past it the run exits 75, having run nothing … Unset: wait for as long as it takes."

**Location:** `scripts/health-check.sh:32-35`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers values 1, 2, 007, 08, 4294967296 and the unset case against a held lock; does not establish values beyond flock's timer limit (Claim 2b) or a payload that itself exits 75 (Claim 4).

Code: `w=(-w "$HEALTH_CHECK_LOCK_WAIT")` then `flock "${w[@]}" -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?` and `[[ "$rc" -ne 75 ]] || red "gave up waiting for health-check.lock after ${HEALTH_CHECK_LOCK_WAIT}s: nothing was checked"`, then `exit "$rc"` (`scripts/health-check.sh:1116-1129`, whole take_lock read, :1108-1130).

Executed (copy of health-check.sh in a temp repo, stub runner logging "in RUN", lock held 4 s by `flock … sleep 4`): value 2 → rc=75 after 2.01 s, stub never ran, message present; 007 and 08 → waited until the holder released (decimal, not octal), then ran; 4294967296 → waited and ran. After a timed-out run and the holder's exit, `flock -n .git/health-check.lock true` succeeded (no lock left held). Unset: the existing T43 test 1 (second run waits, then runs) passes. Started 2026-10-13T22:54:45Z, cwd `/tmp/u4b1-fcc-4ll1/r`, script exit 0.

**Evidence:** `scripts/health-check.sh:32-35`, `scripts/health-check.sh:1108-1130`, `$S/probe-wait.sh`, `$S/probe-wait.log`, `$S/hcl-bats.log`

---

## Claim 2b: "(plain decimal)" read as: any plain decimal is a usable wait

**Location:** `scripts/health-check.sh:32-33`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the edges 0, 00 and values past flock's timer range; does not establish where exactly the limit lies (somewhere above 4294967296).

The regex `^[0123456789]+$` (`scripts/health-check.sh:1118`) admits every plain decimal, but two edges do not behave as "seconds to wait": `0`/`00` exit 75 at once (0.01 s; "gave up waiting … after 0s"), and `99999999999999999999` and `9223372036854775807` exit **71** with `flock: cannot set up timer: Invalid argument` after the "waiting" line, nothing run. That 71 is neither the documented 75 nor the 1 for a bad value. Precise version: "a plain decimal up to flock's timer limit; 0 means do not wait". The skill's 3600 is well inside the range. Same run as Claim 2a.

**Evidence:** `scripts/health-check.sh:1117-1119`, `$S/probe-wait.log`

---

## Claim 3: a value that is not a number exits 1 before any wait (header "plain decimal"; message "HEALTH_CHECK_LOCK_WAIT is not a plain number of seconds")

**Location:** `scripts/health-check.sh:1117-1119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers -1, " 3", "3 ", 1.5, 1s and abc, with and without a held lock; does not establish behaviour when HEALTH_CHECK_LOCK_HELD=1 (that run returns before the check, :1110, by design).

`[[ "$HEALTH_CHECK_LOCK_WAIT" =~ ^[0123456789]+$ ]] || { red "…not a plain number of seconds"; exit 1; }` (`scripts/health-check.sh:1118`) runs before the first `flock -n` (:1122). Executed: each bad value → rc=1, 0.01 s, stub not run; `abc` with no lock contention → rc=1, not run. The empty string counts as unset (`-n "${HEALTH_CHECK_LOCK_WAIT:-}"`, :1117).

**Evidence:** `scripts/health-check.sh:1110-1122`, `$S/probe-wait.log`

---

## Claim 4: "-E 75 also names a -w timeout: the run never started, so 75 is safe to report as such." (relies on the :1104 "its own exits are 0 or 1")

**Location:** `scripts/health-check.sh:1125-1127`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the timeout path (flock's own 75); does not establish that the payload can never exit 75, since no execution produced one.

flock does return the -E code on a -w timeout (Claim 2a, executed). But the payload is this script under `set -euo pipefail` (`scripts/health-check.sh:53`), whose `main` ends `exit "$FAIL"` with `FAIL=1` from `fail()` (:74, :1155-1160). An unguarded failing command exits with that command's own status instead (paraphrased — no quote available because the claim is about every unguarded command across ~1,100 lines of checks, not one snippet). A payload exit of 75 would then be reported as "gave up waiting … nothing was checked". With the variable **unset**, the same 75 hits `${HEALTH_CHECK_LOCK_WAIT}` under `set -u`, and the shell exits 1 with "unbound variable". A one-line bash reproduction of that pattern gave rc=1 (`$S/probe-unbound` inline: `bash -euc 'f(){ local rc=75; [[ "$rc" -ne 75 ]] || echo "x ${XYZ_UNSET_Q}s"; exit "$rc"; }; f'` → "unbound variable", rc=1, 2026-10-13T23:08Z). Precise version: "safe while the payload's exits are 0 or 1 (it is set -e, so a stray 75 would read as a timeout)". Both cases are improbable. The timeout path itself is right.

**Evidence:** `scripts/health-check.sh:53`, `scripts/health-check.sh:74`, `scripts/health-check.sh:1101-1130`, `scripts/health-check.sh:1132-1160`

---

## Claim 5: new test "HEALTH_CHECK_LOCK_WAIT bounds the wait …"; commit: "Test in health-check-lock.bats; it fails on the old script."

**Location:** `test/scripts/health-check-lock.bats:41-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the suite passing at 923f7d26 and test 3 failing on ea59b0c3's health-check.sh; does not establish coverage of 0, huge values or a payload exit of 75.

At HEAD, `TMPDIR=$(mktemp -d /tmp/u4b1-fcc-XXXX) bats test/scripts/health-check-lock.bats` in the worktree gave `ok 1..3`, exit 0, at 2026-10-13T22:53:43Z. With `git show ea59b0c3:scripts/health-check.sh` swapped into a temp tree, tests 1-2 pass. Test 3 fails at line 46 (`[ "$status" -eq 75 ] …`): the old script waited, then ran the whole check (2026-10-13T22:57:13Z).

**Evidence:** `test/scripts/health-check-lock.bats:41-52`, `$S/hcl-bats.log`, `$S/probe-old.sh`, `$S/probe-old.log`

---

## Claim 6: "but a call of either script that the Bash tool timed out, and a `refuse d6:` line, are stops too"

**Location:** `skills/dev-cycle/SKILL.md:58-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-agent
**Scope:** Covers that the sentence agrees with the Rule's earlier lines and closes the gap api-consistency 1 named; does not establish the D6 block's own refusals (the block is unwritten, Q-140).

The same Rule says "`refuse d6: WHY` (exit 2) means nothing ran" and "any other exit (1 included), or a call the Bash tool timed out, means nothing was decided" (`skills/dev-cycle/SKILL.md:52-57`). The new clause carries both into `dev-cycle.sh`'s check modes, which otherwise "follow the paths rule below" (:58).

**Evidence:** `skills/dev-cycle/SKILL.md:48-66`

---

## Claim 7: "is filed once: in the `you: judgment` entry the step names, if it names one (step 0's `--state` refusals and `--main-log` lines), else the line and stderr go in one `agent` entry"

**Location:** `skills/dev-cycle/SKILL.md:60-63`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-agent
**Scope:** Covers the filing route for step 0.1's refusals and its other exits, and step 0.2's lines; does not establish whether step 0.2's `other`/refusal lines end the iteration or only block dispatch.

The filing is consistent. Step 0.1: "refuse lines … are a stop, quoted in one `you: judgment` entry … Any other exit is a stop as the Rules say" (`skills/dev-cycle/SKILL.md:228-231`). Step 0.2: "Any `other` line, or a `refuse main-log:` line other than the bootstrap's own … blocks this iteration's dispatch and gets one `you: judgment` entry" (:242-246).

The parenthetical's classification is not. The Rule lists "`--main-log` lines" among stops, and "Each stop ends the iteration there, with no record" (:59-60). Step 0.2 calls the same lines a dispatch block, and the plan says "Any `other` stops dispatch" (`docs/working/plan-build-loop-handoff.md:103`). The Rule's own exit-2 sentence also counts "`--main-log`'s `other` lines" as an answer, not a stop (:53-54). An orchestrator following the Rule ends the iteration without a record. One following step 0.2 goes on and writes a record whose `Main at:` moves SINCE past the commit. Precise version: name `--main-log` in the parenthetical only for the stop step 0.2 actually names (a newest record without `Main at:`), or make step 0.2 say its block is a stop. Low urgency: until Q-140 the by-hand fallback replaces this Rule (:64-65), and no `build-loop.sh` call runs.

**Evidence:** `skills/dev-cycle/SKILL.md:52-66`, `skills/dev-cycle/SKILL.md:226-246`, `docs/working/plan-build-loop-handoff.md:101-103`

---

## Claim 8: "A stop after step 0.3 removes WT."

**Location:** `skills/dev-cycle/SKILL.md:64`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-agent
**Scope:** Covers the one remove command the skill names, run on a modified WT; does not establish what happens to the branch `chore/dev-cycle-DATE-HHMM` (the sentence does not say).

The only removal command the skill gives is "`hg -C MAIN_WT worktree remove WT`" (`skills/dev-cycle/SKILL.md:250`). A stop part-way through steps 1-6 usually leaves WT modified. Executed with the skill's `hg` on a temp repo: a worktree at `.claude/wt-dev-cycle-2026-10-13-2300` with an edited file → `fatal: '…' contains modified or untracked files, use --force to delete it`, rc=128 (2026-10-13T23:08:18Z, cwd `/tmp/u4b1-fcc-k5ig/m`). Precise version: say how (e.g. `worktree remove --force WT`, WT being this iteration's own), or note the branch stays behind.

**Evidence:** `skills/dev-cycle/SKILL.md:64`, `skills/dev-cycle/SKILL.md:247-251`, `$S/probe-wtremove.sh`, `$S/probe-wtremove.log`

---

## Claim 9: "Until the D6 block is written, the by-hand fallback above replaces this Rule."; commit: "D9: the D6 Rule points at the by-hand fallback (U4c deletes both)."

**Location:** `skills/dev-cycle/SKILL.md:64-65`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-user
**Scope:** Covers that the fallback exists above the Rule and that U4c's plan entry deletes both; does not establish the fallback's content (reviewed in earlier passes).

`**Until the D6 block is written** (below; Q-140), no script can run as the Rules require. Run the cycle by hand instead: …` (`skills/dev-cycle/SKILL.md:18-28`). Plan: U4c "deletes U4b1's by-hand fallback paragraph and the D6 Rule's pointer to it (U4b1 final architecture 3)" (`docs/working/plan-build-loop-handoff.md:344`).

**Evidence:** `skills/dev-cycle/SKILL.md:18-28`, `docs/working/plan-build-loop-handoff.md:344`

---

## Claim 10: "The same goes for every command that writes a commit, the merge of main into WT included, written as `GIT_AUTHOR_NAME="$N" … hg …` (not `env … hg`, which would run another program named `hg`)."

**Location:** `skills/dev-cycle/SKILL.md:88-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-agent
**Scope:** Covers bash (default and --posix) passing a prefix assignment to a function's child processes, the identity reaching a commit and a merge commit made through `hg`, and `env … hg` running Mercurial on this image; does not establish other shells (the Rule runs `bash -s`).

Executed (`$S/probe-misc.sh`, 2026-10-13T22:56:56Z, exit 0). `GIT_AUTHOR_NAME="$N" hg` with `hg` as a function → child saw `[Probe Name]`, and the shell's own value was unchanged afterwards; same under `bash --posix`. Commit and `hg merge --no-edit side` with the four identity variables on the command, in a repo with planted `user.name planted` → `author=Probe Name <n@e> committer=Probe Name <n@e>` on both, the merge having two parents. `env GIT_AUTHOR_NAME=x hg --version` printed `Mercurial Distributed SCM (version 6.3.2)`. The environment also carries a `GIT_AUTHOR_NAME` of its own, so the "environment's own values" route (:86) is live here.

**Evidence:** `skills/dev-cycle/SKILL.md:70-93`, `$S/probe-misc.sh`, `$S/probe-misc.log`

---

## Claim 11: "SINCE is the newest `Main at:` line of the newest record on the default branch (listed with `hg -C MAIN_WT ls-tree` and read with `hg -C MAIN_WT show`…)"

**Location:** `skills/dev-cycle/SKILL.md:232-234`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-agent
**Scope:** Covers whether "newest record" is defined; does not establish the record template's `Main at:` placement (U4b2's).

"Newest record" is well defined only by reference to text step 0.2 does not cite. Records are `docs/working/cycles/cycle-YYYY-MM-DD.md`, one per day ("if one exists for today, update it in place", `skills/dev-cycle/SKILL.md:497`). The digest orders them by the date in the name over the glob `docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:225-226`). Step 0.2 names neither the directory, the glob nor the date order, and `ls-tree` lists every entry, including names off that glob and non-blob modes. "Newest `Main at:` line" within a record (several iterations per day) is left to U4b2's template (`docs/working/plan-build-loop-handoff.md:343`, "newest line named"). Precise version: "the newest by name of main's `docs/working/cycles/cycle-YYYY-MM-DD.md` blobs (mode 100644)".

**Evidence:** `skills/dev-cycle/SKILL.md:232-234`, `skills/dev-cycle/SKILL.md:497`, `scripts/dev-cycle.sh:225-246`, `docs/working/plan-build-loop-handoff.md:343`

---

## Claim 12: "Only when no record there holds a `Main at:` line, pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap."

**Location:** `skills/dev-cycle/SKILL.md:234-236`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-agent
**Scope:** Covers --main-log's output for 40 zeros and that it prints no class lines; does not establish that the D6 block passes the same output through.

In a clone of /workspace, `bash $W/scripts/build-loop.sh --main-log 0000000000000000000000000000000000000000` printed `main 596966f015a5f3d061b12f0761b041f3acfdca54 -` then `refuse main-log: 0000… is not on the default branch's first-parent history at 596966f0…`, exit 2, with no class lines; `main` was `596966f0…`. For contrast, `--main-log $(git rev-parse main~3)` printed `main … 3` and three `other` lines, exit 2. 2026-10-13T22:57Z, cwd `/tmp/u4b1-fcc-1ISi/r`.

**Evidence:** `skills/dev-cycle/SKILL.md:232-246`, `$S/probe-mainlog.sh`, `$S/probe-mainlog.log`

---

## Claim 13: "A newest record without one while an older record has one is a stop, with one `you: judgment` entry … bootstrapping would skip the check of what moved main."; commit/rubric D3 "Fixed"

**Location:** `skills/dev-cycle/SKILL.md:236-239`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-user
**Scope:** Covers the rule's text, its rationale and whether it closes security F1; does not establish the attack's cost (it needs a direct move of main, which is the event `other` exists to report).

The rationale holds: the bootstrap answer has no class lines (Claim 12, executed), so the bootstrap reports nothing. The rule closes F1's stated routes, "add a newer-dated record with no `Main at:` line, or delete the line from the newest one" (`docs/reviews/security-review-2026-10-13-u4b1-final.md:45`): an older record still has the line, so it is a stop. It does not close the same move done to every record. The condition is "Only when no record there holds a `Main at:` line" (:234-235), a property of repo text. So a direct commit to main that deletes `Main at:` from every record, or deletes every record, meets it: the next iteration bootstraps, prints no `other` line for that commit, and dispatch goes on. Rubric D3 says "Fixed" (`docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4b1.md:106`). Precise version: "narrowed: fails open only when a commit removes the line from every record". Another option is to tie the bootstrap to the absence of any `chore/dev-cycle-*` merge on main.

**Evidence:** `skills/dev-cycle/SKILL.md:232-246`, `docs/reviews/security-review-2026-10-13-u4b1-final.md:34-45`, `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4b1.md:106`

---

## Claim 14: "in claude-workflows run it with `HEALTH_CHECK_LOCK_WAIT=3600`, so a wait past an hour ends it with exit 75 having checked nothing: record that and skip the step's check (row 750)."

**Location:** `skills/dev-cycle/SKILL.md:279-283`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-agent
**Scope:** Covers the mechanism at 1-2 s scale and that 3600 is inside flock's timer range; does not establish an actual one-hour wait (not run), or how the orchestrator reads the background job's exit status (the skill does not say).

Mechanism executed under Claims 2a and 5: 75, no payload, message "gave up waiting … nothing was checked". 3600 < 4294967296, which flock accepted (Claim 2a). "it says so once" holds: one `yellow "waiting for another health check …"` before the bounded flock (`scripts/health-check.sh:1124`). Row 750 is the deferred "health-check.sh's wait for the lock is unbounded" row (`docs/reviews/override-log.md:750`). Dropping `setsid … kill -- -PGID` is sound: past the wait, flock exits and leaves no waiting child. The lock was free once the holder exited (`$S/probe-wait.log`, last lines).

**Evidence:** `skills/dev-cycle/SKILL.md:274-285`, `scripts/health-check.sh:1116-1129`, `docs/reviews/override-log.md:750`, `$S/probe-wait.log`, `$S/hcl-bats.log`

---

## Claim 15: commit: "re-implementing take_lock's process handling (setsid forks when its caller leads a group)"

**Location:** commit 923f7d26 message, D4
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers util-linux setsid on this image; does not establish other setsid implementations.

Executed (`$S/probe-setsid.sh`, 2026-10-13T23:07:12Z). Run in the background from a non-leader shell, setsid ran in place: `bg $!=2009833 / payload pid 2009833`. Exec'd from a group leader (`outer pid 2009837 pgid 2009837`), it forked: `inner pid 2009841`. So `$!` can miss the payload.

**Evidence:** `$S/probe-setsid.sh`, `$S/probe-setsid.log`

---

## Claim 16: commit: "Suites: health-check-lock 3, health-check 32, orchestrator 27; shellcheck clean."

**Location:** commit 923f7d26 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the three suites at HEAD and shellcheck at the health check's own settings on the changed scripts; does not establish shellcheck at default (info) severity.

In the worktree with TMPDIR set to a fresh `/tmp/u4b1-fcc-XXXX`: `bats test/scripts/health-check-lock.bats` 3/3 ok (22:53:43Z); `bats test/scripts/build-loop-orchestrator.bats` 27/27 ok, exit 0 (22:57:49Z); `bats test/scripts/health-check.bats` 32/32 ok, exit 0 (22:58:06Z). `shellcheck -x -e SC1091 -s bash -S warning scripts/health-check.sh scripts/build-loop.sh test/scripts/health-check-lock.bats` gave exit 0 with no output (22:57:43Z). These are health-check.sh's own flags: `shellcheck -x -e SC1091 -s bash -S warning "$f"` (`scripts/health-check.sh:489`). At default severity there are info notes (SC2015/SC2016/SC2153), none on lines in this range.

**Evidence:** `scripts/health-check.sh:489`, `$S/hcl-bats.log`, `$S/orch-bats.log`, `$S/hc-bats.log`, `$S/shellcheck-warning.log`, `$S/shellcheck.log`

---

## Claim 17: commit: "D8: build-loop.sh's header refers to the lib's HARDEN list instead of an unpinned copy of its keys."

**Location:** commit 923f7d26 message; `scripts/build-loop.sh:136`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the diff of the header; does not establish other copies of the key list elsewhere (SKILL.md's hg line is pinned by the orchestrator test, which passed, Claim 16).

The diff removes the nine-key list and adds "(any key of the lib's HARDEN list, which git_harden's comment explains; a git -c pair would win over it)" (`git diff ea59b0c3..923f7d26 -- scripts/build-loop.sh`, header hunk at :133-138).

**Evidence:** `scripts/build-loop.sh:133-138`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2b** (`scripts/health-check.sh:32-33`): "plain decimal" admits values past flock's timer limit, which exit 71 ("cannot set up timer"), and 0 means no wait. Say "up to flock's limit; 0 = do not wait", or cap the value.
- **Claim 4** (`scripts/health-check.sh:1125`): "75 is safe" rests on payload exits being 0 or 1, but the payload is `set -e`. A stray 75 would read as a timeout, or exit 1 via "unbound variable" when the variable is unset.
- **Claim 7** (`skills/dev-cycle/SKILL.md:60-63`): the parenthetical classes `--main-log` lines as iteration stops (no record). Step 0.2 and D13 call them a dispatch block, and the Rule's exit-2 sentence calls them an answer.
- **Claim 8** (`skills/dev-cycle/SKILL.md:64`): the only remove command the skill names, `worktree remove WT`, refuses a modified WT (rc 128, executed). Name `--force`, and the branch's fate.
- **Claim 11** / **Claim 13** (`skills/dev-cycle/SKILL.md:232-239`): "newest record" rests on the naming at :497 and the digest's glob, which step 0.2 does not cite. D3 narrows F1 but does not close it: a direct main commit that drops `Main at:` from every record, or deletes every record, still bootstraps silently.

### Unverifiable
(none)

---

## Goal-Alignment Note

The user's goal is to land U4b1 on main after a clean review-fix loop, and this pass merges unless it finds a new Must Fix (a high-confidence behavioural Incorrect). It found none. The new lock bound works as the skill uses it (3600 s → exit 75, nothing run, no lock left). The old script fails its test. The identity and `env hg` claims hold by execution, and the bootstrap output matches. The five Mostly-accurate items are routable, not blocking. Two of them sit in SKILL.md, which is behavioural text: the `--main-log` stop-versus-dispatch-block wording (Claim 7) and the plain `worktree remove` on a dirty WT (Claim 8). Both bite only once the D6 block lands (U4c, Q-140), because until then the by-hand fallback replaces the Rule. Claim 13 is the one with security weight: F1's fail-open is narrowed to "every record loses its line", not closed. It deserves an override row or a note in U4b2's record-template work rather than a "Fixed" status. Nothing found here argues against merging.
