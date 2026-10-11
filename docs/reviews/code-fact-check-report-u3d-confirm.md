# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3d (feat/build-loop-u3d)
**Commit:** d4d178d9
**Replication:** k=1 (confirming pass over the final fix batch)
**Scope:** `git diff 4b863735..d4d178d9 -- scripts test` (scripts/build-loop.sh, test/scripts/build-loop-dispatch.bats) and commit d4d178d9's message; plus four submitted endorsement claims from docs/reviews/security-review-2026-10-10-u3d-final.md
**Checked:** 2026-10-10 (probes ran 2026-10-11T02:59Z-03:03Z UTC)
**Total claims checked:** 32 (Claim 21 split into 21a and 21b)
**Summary:** 28 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). None matches a claim here. The nearest family is miscounted tallies in commit messages; d4d178d9's message has no counts.

Execution provenance, shared by every `executed` claim. Probes ran from a `git archive d4d178d9 scripts test` export at `/tmp/claude-1000/u3d-rev-cfc-confirm-rGgS/src`, each in its own throwaway repo under that directory, with git 2.39.5 and bash 5.2.15 as uid 1000. Each probe script is kept next to its log, and every log is in `/tmp/claude-1000/u3d-rev-cfc-confirm-rGgS/logs/`. The brief binds this agent to write only this report, so the logs are not in `docs/reviews/execution-logs/`.

| Log | Command (cwd `/tmp/claude-1000/u3d-rev-cfc-confirm-rGgS` unless named) | Exit | UTC start |
|---|---|---|---|
| suite.log | `TMPDIR=$(mktemp -d …) timeout 600 bats test/scripts/build-loop-dispatch.bats` (cwd the worktree) | 0 (4/4 ok) | 2026-10-11T02:59:44Z |
| mut-M1…M6.log | `bash mut.sh`: six one-line mutations of the copy, the suite run on each | see Claim 26 | 2026-10-11T02:59:50Z |
| p1-lockfile.log | `timeout 200 bash p1.sh`: the lock path as a FIFO, a dangling link, a directory, a link to a file, a mode-000 file, a held lock, and the normal case | 0 | 2026-10-11T03:00:40Z |
| p2-fd9.log | `timeout 120 bash p2.sh`: a git shim that records the lock fds and the lock state, and leaves a `setsid sleep 6` on `worktree add` (src vs M6) | 0 | 2026-10-11T03:00:53Z |
| p3-tips.log | `timeout 300 bash p3.sh`: the recorded tip on each dispatch path, and the `ended` cases | 0 | 2026-10-11T03:01:24Z |
| p4-s1s2s4.log | `timeout 500 bash p4.sh`: the unborn refusal, S1 (6 rounds), S2, S4 | 0 | 2026-10-11T03:01:45Z |
| p5-submodule.log | `timeout 200 bash p5.sh`: S3 and a positive control | 0 | 2026-10-11T03:02:02Z |
| p6-retry.log | `timeout 100 bash p6.sh`: a "could not be added" refusal that clears with no repository change | 0 | 2026-10-11T03:02:22Z |
| p7-pre-c3.log | `timeout 60 bash p7.sh`: the FIFO and dangling-link cases with C3's type test removed | 0 | 2026-10-11T03:02:52Z |

---

## Claim 1: "locked with the reason "build-loop dispatch of STEM at TIP, UTC TIME" (TIP: the tip the loop starts from)"

**Location:** `scripts/build-loop.sh:284-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the recorded TIP on all three dispatch paths: --start (main's commit), --prompt relocking an existing worktree, and --prompt adding a worktree (the branch tip). Does not establish TIP when the branch moves between status_fields' read and `worktree add` (a writer outside the dispatch lock).

Code that sets it:

```bash
# scripts/build-loop.sh:1312-1314
  br="${STATUS[branch]}"; stem="${a##*/}"; stem="${stem%.md}"; n=$(( ${STATUS[dispatched]} + 1 )); tip="${STATUS[sha]}"
  [[ "$MODE" == prompt ]] || tip="$MAIN_SHA"
  reason="build-loop dispatch of $stem at $tip, UTC $(date -u +%Y-%m-%dT%H:%M:%SZ)"
```
(excerpt ends :1314; the enclosing dispatch() continues to :1348, read)

The same `$reason` is used at both lock sites, `git worktree lock --reason "$reason" "$WT"` (:1332) and `git worktree add -q --lock --reason "$reason" "$DIR" "$br"` (:1340). --start creates the branch at `$MAIN_SHA` (:1339), so on that path the tip and the start point are the same commit. In p3-tips.log:
- (A) --start: `locked build-loop dispatch of 2026-10-01-x at 0a0f9959…` with `main=0a0f9959…`.
- (B) --prompt on an existing worktree: `at d5651f7b…` with `tip=d5651f7b…`.
- (E) --prompt with no worktree: `at eb82805b…` with `tip=eb82805b… wt HEAD=eb82805b…`.

The mutation that removes :1313 (M5) fails suite test 1 at :30 (`mut-M5-starttipsha.log`).

**Evidence:** `scripts/build-loop.sh:1312-1314`, `scripts/build-loop.sh:1332`, `scripts/build-loop.sh:1339-1340`, logs/p3-tips.log, logs/mut-M5-starttipsha.log

---

## Claim 2: --start's refusal list: "a rule above; a worktree already has the branch checked out, unborn; DIR, or the default, exists or is not a path --dir takes; constraints.md, the worktrees or the branch could not be read, listed or created; or the worktree could not be added"

**Location:** `scripts/build-loop.sh:291-295`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `x=` assignment dispatch can reach under --start, matched against the list. Does not establish the lock-file refusals: they print a refuse line but are documented in the --prompt paragraph's "Both refuse" sentence (:312-315), not in this list.

Under --start, dispatch reaches these refusals: the constraints, the brief's state, the cap and "branch exists" (:1315-1318, the "rule above"); constraints.md (:1320); the listing (:1321); unborn (:1323); the default DIR failing readerform (:1336); DIR exists (:1337); the branch could not be created (:1339); and the add (:1340-1341). The `WT_N -gt 1` and `WT_N -eq 1` arms cannot be reached under --start, because :1323 already refuses any `WT_N -gt 0`:

```bash
# scripts/build-loop.sh:1323-1325
  elif [[ "$MODE" == start && "$WT_N" -gt 0 ]]; then x="its branch $br does not exist, but a worktree has it checked out (unborn)"
  elif [[ "$WT_N" -gt 1 ]]; then x="its branch $br is checked out in $WT_N worktrees"
  elif [[ "$WT_N" -eq 1 ]]; then
```
(excerpt ends :1325; the arm continues to :1333 and dispatch() to :1348, read)

So the list matches one for one, with one exception. The phrase "DIR … is not a path --dir takes" is not a refusal for a given `--dir`. The argument parser rejects such a DIR with a usage error and exit 1 (`[[ $# -ge 2 && -z "$DIR" ]] && readerform "$2" || usage "--dir takes one absolute path …"`, :376). In p3-tips.log (F), `--start "$B" --dir "/a b"` printed the usage text and exited 1. Only the default DIR can produce this refuse line (:1336). A precise version: "DIR exists, or the default is not a path --dir takes".

**Evidence:** `scripts/build-loop.sh:376`, `scripts/build-loop.sh:1315-1343`, logs/p3-tips.log (case F)

---

## Claim 3: "A locked one is taken when the loop under that lock has ended: the tip is a handoff marker and the lock reason names another tip ("... at TIP, UTC TIME"; a lock taken at this marker is a newer, live dispatch). Else it refuses unless --steal is given, its lock reason ends "UTC TIME", and that time and the tip's commit time are both over 2 hours ago. A taken lock is replaced with a new reason."

**Location:** `scripts/build-loop.sh:303-309`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each marker kind (ready, blocked, stopped), a lock reason at another tip vs this tip, a reason without " at TIP,", a hand reason, a bare `locked`, and the steal path. Does not establish a lock reason whose stem contains a blank (`[^\ ]+`), which never ends; readerform-shaped brief names make that unreachable on the honest path.

```bash
# scripts/build-loop.sh:1299-1303
ended() {
  [[ "${STATUS[loop]}" == ready || "${STATUS[loop]}" == blocked || "${STATUS[loop]}" == stopped ]] || return 1
  [[ "$WT_LOCK" =~ ^locked\ build-loop\ dispatch\ of\ [^\ ]+\ at\ ([0123456789abcdef]{40}|[0123456789abcdef]{64}),\ UTC\  ]] || return 1
  [[ "${BASH_REMATCH[1]}" != "${STATUS[sha]}" ]]
}
```

The caller is `elif [[ -n "$WT_LOCK" ]] && ! ended && ! steal; then x="$STEAL_WHY"` (:1331). The relock with the new `$reason` follows at :1332. Results in p3-tips.log:

| Case | Result |
|---|---|
| (C) ready marker, lock at the previous tip, no --steal | `ok` |
| (C2) the same command again (lock at this marker) | `refuse … is locked (… at e2cac51d…, …)`, exit 2 |
| (C3) lock at this marker with a 2020 time, --steal | `its lock or tip is under 2 hours old`; the fresh marker's commit time decides |
| (D) stopped marker, reason without " at TIP," | refuse |
| (D2) stopped marker, lock at another tip | `ok` |
| (D3) hand reason at a marker | refuse |
| (D4) bare `locked` at a marker | refuse |

Suite test 4 covers the blocked marker (:108-111) and a working tip (:97-98).

**Evidence:** `scripts/build-loop.sh:1283-1303`, `scripts/build-loop.sh:1331-1333`, logs/p3-tips.log, logs/suite.log

---

## Claim 4: "Both refuse while another --start or --prompt holds the repository's dispatch lock …, or when that file is not a plain file or cannot be opened."

**Location:** `scripts/build-loop.sh:312-315`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a FIFO, a dangling symlink, a directory, a symlink to a regular file, a mode-000 file (uid 1000, not root) and a held lock, each refusing with exit 2 within the 10 s timeout, with no branch made. Does not establish a file whose type changes between the test and the open (a same-uid `.git` writer racing; Q-103 residual).

```bash
# scripts/build-loop.sh:1415-1419
    lk="$(git rev-parse --path-format=absolute --git-common-dir)/build-loop-dispatch.lock"
    if [[ -L "$lk" || ( -e "$lk" && ! -f "$lk" ) ]] || ! { exec 9>> "$lk"; } 2>/dev/null; then
      echo "refuse ${ARGS[0]}: the dispatch lock file (build-loop-dispatch.lock in the git directory) is not a plain file or cannot be opened"; exit 2
    fi
    flock -n 9 || { echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository; retry once it ends"; exit 2; }
```
(excerpt ends :1419; the case arm continues to :1422, read)

In p1-lockfile.log, the cases fifo, dangling, dir, linkfile and mode000 each printed the "not a plain file or cannot be opened" line and `exit 2`. None of them blocked: the exit was 2, not timeout's 124. The dangling link's target was not created (`ls: cannot access …/nowhere`). The held case printed "… retry once it ends", exit 2. The normal case printed `ok` and left a regular lock file.

**Evidence:** `scripts/build-loop.sh:1415-1419`, logs/p1-lockfile.log

---

## Claim 5: "Only two refusals can clear with no change to the repository: "another --start or --prompt is running ..." and "... under 2 hours old"."

**Location:** `scripts/build-loop.sh:315-317`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers every rule refusal (state gate, constraints, state, cap, branch existence, unborn, worktree count, path form, --dir mismatch, missing or symlinked directory, locked without --steal, unreadable steal times, DIR exists, lock-file type), each of which needs a change to the repository (or to the command line) before a rerun can pass. It does not hold for refusals that wrap a failed git command, which can clear with no repository change.

The two named refusals do clear with time alone. The flock is released when its holder exits, and the age check at :1294 compares against the clock. The sentence's "only" is too strong. The refusals that print a failed command's outcome can come from conditions outside the repository: "could not be read" (:1320), "could not be listed" (:1321), "could not be locked" (:1332), "could not be created" (:1339) and "could not be added (git's reason)" (:1340-1341). In p6-retry.log:

1. `--start "$B" --dir "$P/ro/wt"` with `$P/ro` at mode 555 printed `refuse …: the worktree …/ro/wt could not be added (fatal: could not create leading directories of '…/ro/wt/.git': Permission denied)`, exit 2, and left no branch.
2. `chmod 755` on that directory outside the repository changed nothing in the repository.
3. The same command then printed `ok`.

A precise version: "Of the rule refusals, only two can clear …; a refusal naming a failed git command may clear on a retry too."

**Evidence:** `scripts/build-loop.sh:1294`, `scripts/build-loop.sh:1315-1345`, `scripts/build-loop.sh:1415-1419`, logs/p6-retry.log

---

## Claim 6: STEAL_WHY and the age refusal print "over $(( STEAL_AGE / 3600 )) hours" / "under $(( STEAL_AGE / 3600 )) hours" (C6: STEAL_AGE in messages)

**Location:** `scripts/build-loop.sh:1285`, `scripts/build-loop.sh:1294`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the messages at STEAL_AGE=7200 ("2 hours", the header's and tests' wording). Does not establish the wording for a STEAL_AGE that is not a whole number of hours: integer division would print a rounded-down count (for example "1 hours" for 5400).

`DISPATCH_CAP=4; STEAL_AGE=7200` (:1277). The two messages are `… --steal takes it once the lock and the tip are over $(( STEAL_AGE / 3600 )) hours old"` (:1285) and `STEAL_WHY="its worktree $WT is locked, and its lock or tip is under $(( STEAL_AGE / 3600 )) hours old"` (:1294). Suite test 4 asserts both texts with "2 hours" (:91, :92) and passed. p3-tips.log (C2, C3) printed the same.

**Evidence:** `scripts/build-loop.sh:1277`, `scripts/build-loop.sh:1285`, `scripts/build-loop.sh:1294`, logs/suite.log, logs/p3-tips.log

---

## Claim 7: "ended: whether the loop under WT's lock has ended (D3): the tip is a handoff marker and the lock reason names the tip it was dispatched at, another one. A lock taken at this marker is a newer, live dispatch"

**Location:** `scripts/build-loop.sh:1296-1298`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function's three tests (marker kind, reason form, tip inequality) and their effect through :1331. Does not establish anything about lock reasons written by hand in the dispatch form (a same-uid writer can forge one; Q-103 residual).

The function is quoted under Claim 3 (`scripts/build-loop.sh:1299-1303`). The mutations show that each test is load-bearing. Without the marker-kind test (M1), suite test 4 fails at :98, the working tip under a lock at another tip. Without the inequality (M2), it fails at :111, the second re-dispatch at the same marker (`mut-M1-noloopstate.log`, `mut-M2-nosha.log`). p3-tips.log cases C, C2, D, D2, D3 and D4 run each branch.

**Evidence:** `scripts/build-loop.sh:1296-1303`, logs/mut-M1-noloopstate.log, logs/mut-M2-nosha.log, logs/p3-tips.log

---

## Claim 8: "dispatch BRIEF: … under the dispatch lock its caller holds. … leaving no branch or worktree it made (unless removing the branch fails; the line says so)."

**Location:** `scripts/build-loop.sh:1304-1307`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the lock stays held for all of dispatch's git calls, and the branch-removal wording on a failed add. Does not establish cleanup after a crash or signal mid-dispatch (no trap removes the branch).

p2-fd9.log ("src"): a git shim's `flock -n` on the lock file reported `lock:held` for every git call inside dispatch (`worktree list`, `cat-file blob`, `update-ref`, `worktree add`). The lock survives `9>&-` because bash moves fd 9 to a saved descriptor for the call rather than closing the open file. On a failed add, the cleanup is

```bash
# scripts/build-loop.sh:1340-1342
    elif ! git worktree add -q --lock --reason "$reason" "$DIR" "$br" > "$GATE_TMP/add" 2>&1; then
      x="the worktree $DIR could not be added ($(head -n 1 "$GATE_TMP/add"))"
      [[ "$MODE" != start ]] || git update-ref -d "refs/heads/$br" "$MAIN_SHA" 2>/dev/null || x+="; its new branch $br could not be removed"
```
(excerpt ends :1342; the enclosing dispatch() continues to :1348, read)

p6-retry.log shows no branch left after the failed add (`git show-ref feat/x | wc -l` gives `0`).

**Evidence:** `scripts/build-loop.sh:1304-1348`, logs/p2-fd9.log, logs/p6-retry.log

---

## Claim 9: "An unborn checkout of the absent branch: --start would relock it and create nothing" (and the refusal is reached before any write)

**Location:** `scripts/build-loop.sh:1322-1323`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unborn refusal's position before the only writes dispatch makes (`worktree lock`, `update-ref`, `worktree add`) and the counterfactual the comment states. Does not count the lock file the case arm creates before dispatch, which the header lists among the script's writes (:325).

All of dispatch's writes come after :1323 (lines 1332, 1339 and 1340). Before :1323 there are only reads, and `wt_of`'s temp file (`$GATE_TMP/wts`, :1263). p4-s1s2s4.log (U): with a detached worktree's HEAD pointed at the unborn `refs/heads/feat/x`, --start printed the unborn refusal, exit 2, `0` locked worktrees and `0` refs. The counterfactual is shown by the mutation that removes :1323 (M3). It printed `ok … feat/x …/test/3/u`, and the listing showed the unborn worktree `u` `locked build-loop dispatch of 2026-10-01-x at 03888e36…`. It created no branch, and test 3 failed at :73 (`mut-M3-nounborn.log`).

**Evidence:** `scripts/build-loop.sh:1260-1275`, `scripts/build-loop.sh:1320-1340`, logs/p4-s1s2s4.log, logs/mut-M3-nounborn.log

---

## Claim 10: "The path first: the lines below print it." (C5: readerform before any line prints the path)

**Location:** `scripts/build-loop.sh:1326-1327`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every line dispatch prints that holds `$WT` or `$DIR` after a worktree listing: the --dir mismatch, the missing or symlinked directory, STEAL_WHY, the lock failure, `ok`, and the prompt. Does not establish anything about lines printed before dispatch.

Within the `WT_N -eq 1` arm, `readerform "$WT"` (:1327) is the first test. Every later message in that arm interpolates `$WT` (:1328, :1330, :1331, :1332), and none of the earlier arms prints a path (:1321, :1323, :1324). The add arm checks `readerform "$DIR"` (:1336) before `"$DIR already exists"` (:1337). In p4-s1s2s4.log (S2), a worktree path `my wt;$(touch INJ)` and a path holding a newline both refused with the fixed path-form message. That held with no flag, with `--dir` elsewhere, with `--steal`, and with the directory removed. None of them locked the worktree (`0`).

**Evidence:** `scripts/build-loop.sh:1321-1337`, logs/p4-s1s2s4.log

---

## Claim 11: the loop prompt's floor list: "paths below the name of an instruction or prompt file or of an imported .md file" (C6: floor "below" with prompt files)

**Location:** `scripts/build-loop.sh:1359`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement between the prompt's floor list and the header's description of the self-merge floor. Does not establish the lib's floor implementation (`scripts/lib`), which is outside this batch's diff and was reviewed in the final pass.

The header's floor reads `instruction and prompt files and what they import with @, a path below the name of an instruction or prompt file or of an imported .md file, dot paths, the gate's own code` (:192-194). The prompt now reads `instruction and prompt files and what they import, dot paths, paths below the name of an instruction or prompt file or of an imported .md file, the gate's own code` (:1359). The two lists hold the same items.

**Evidence:** `scripts/build-loop.sh:187-196`, `scripts/build-loop.sh:1359`

---

## Claim 12: "One dispatch at a time in the repository …: held for all of dispatch, until exit; a second run refuses. Only a plain file is opened (a FIFO would block); dispatch's children do not inherit the descriptor (9>&-), so none outlives the run holding it."

**Location:** `scripts/build-loop.sh:1411-1414`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commands dispatch execs (git, date and the rest): none holds a descriptor on the lock file, and a background process started by one of them does not keep the lock. It also covers the FIFO counterfactual. Does not establish forked bash subshells (`$(...)` of a function), which hold bash's saved copy until they exit within the run, and does not cover `cat` at :1421, which runs after dispatch with fd 9 open and exits at once.

The arm runs `dispatch "${ARGS[0]}" 9>&- > "$GATE_TMP/line"` (:1420). In p2-fd9.log, with the code as committed ("src"), every shimmed git call inside dispatch showed `lockfds:[]` and `lock:held`. A `setsid sleep 6` started from the `worktree add` shim had `0` lock descriptors, and after the script exited, with that sleep still alive, the lock was free. With `9>&-` removed (the "mut-M6-no9close" case), the same calls showed `lockfds:[ 9]`, the sleep held `1` lock descriptor, and the log ended with `after exit: lock STILL HELD`.

For the FIFO counterfactual, p7-pre-c3.log removes only the type test. With a FIFO at the lock path, `--start` hit the timeout (`fifo exit 124`). With a dangling link, it printed `ok` and created the link's target (`-rw-r--r--`).

**Evidence:** `scripts/build-loop.sh:1411-1422`, logs/p2-fd9.log, logs/p7-pre-c3.log, logs/mut-M6-no9close.log

---

## Claim 13: test 3 comment "An unborn checkout of the absent branch is not taken over (final r3, security 2)."

**Location:** `test/scripts/build-loop-dispatch.bats:71-74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test sets up an unborn checkout and asserts the refusal, and that it catches the missing check. Does not establish that the test checks that the unborn worktree stays unlocked: `none` (:21) counts refs and worktrees, not locks. p4 (U) checked the locks separately.

The test runs `git worktree add -q --detach "$BATS_TEST_TMPDIR/u" && git -C "$BATS_TEST_TMPDIR/u" symbolic-ref HEAD refs/heads/feat/x`, then `dsp --start "$B"; refused "its branch feat/x does not exist, but a worktree has it checked out (unborn)"` (:72-73). M3 fails at :73 (`mut-M3-nounborn.log`).

**Evidence:** `test/scripts/build-loop-dispatch.bats:21`, `test/scripts/build-loop-dispatch.bats:71-74`, logs/mut-M3-nounborn.log

---

## Claim 14: test 3's lock-path assertions (held lock "retry once it ends"; a dangling symlink "not a plain file or cannot be opened")

**Location:** `test/scripts/build-loop-dispatch.bats:64-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the held-lock and dangling-symlink cases the test runs. The FIFO, directory, link-to-file and mode-000 cases are not in the suite; Claim 4's probe covers them.

The test runs `rm "$f"; ln -s "$BATS_TEST_TMPDIR/nowhere" "$f"; dsp --start "$B"; rm "$f"` (:69) and then the `refused` assertion (:70). It passed in suite.log. M4, which drops `-L "$lk" ||`, fails at :70 (`mut-M4-nosymlinkcheck.log`).

**Evidence:** `test/scripts/build-loop-dispatch.bats:64-70`, logs/suite.log, logs/mut-M4-nosymlinkcheck.log

---

## Claim 15: test 4's name: "--prompt locks the branch's worktree, refuses a locked one unless its loop ended on a marker or --steal finds it over 2 hours old, and adds one when none has the branch (T24, T40, T41's cap, U3d)"

**Location:** `test/scripts/build-loop-dispatch.bats:87`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the body exercises each named behavior. Does not establish the plan's T24/T40/T41 rows' wording, which is outside this batch.

The body covers each named behavior:
- the marker take: `dsp --prompt "$B"; [ "$status" -eq 0 ] …` after `handoff: blocked` (:108-109)
- the steal take: `dsp --prompt "$B" --steal` with a 2020 lock and tip, which prints `ok` (:103-105)
- the refusals (:91-102, :111)
- the add when no worktree has the branch, after `git worktree prune` (:118-119)
- the cap: `refused "it was dispatched 4 times, and the cap is 4"` (:121)

The test passed in suite.log.

**Evidence:** `test/scripts/build-loop-dispatch.bats:87-122`, logs/suite.log

---

## Claim 16: "A working tip under a lock taken at another tip: only a marker ends the loop."

**Location:** `test/scripts/build-loop-dispatch.bats:96-98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test's tip is a working (non-marker) commit that differs from the lock's recorded tip, and that the run refuses. The lock's time is current, so this test alone does not separate `ended` from `steal`: no `--steal` is given.

The test runs `lock "$W" "build-loop dispatch of 2026-10-01-x at $M, UTC $(date -u …)"` with the tip at the `old` commit (:95, :97), then `dsp --prompt "$B"`, which must refuse (:98). M1, which drops the marker-kind test, fails here.

**Evidence:** `test/scripts/build-loop-dispatch.bats:95-98`, logs/mut-M1-noloopstate.log

---

## Claim 17: "That lock names this marker: a second re-dispatch before the new loop commits is a live one (final security 1)."

**Location:** `test/scripts/build-loop-dispatch.bats:110-111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the blocked-marker case in the suite; p3 (C2) repeats it for a ready marker. Does not establish the --steal variant of the second run (p3 C3: refused because the marker's commit time is fresh).

The test asserts `… is locked (locked build-loop dispatch of 2026-10-01-x at $t, UTC "*`, where `$t` is the marker (:108, :111). M2 fails here.

**Evidence:** `test/scripts/build-loop-dispatch.bats:107-111`, logs/mut-M2-nosha.log, logs/p3-tips.log

---

## Claim 18: "A dead loop's worktree, gone but still locked (git never calls it prunable), even with an old lock (i1 A1)."

**Location:** `test/scripts/build-loop-dispatch.bats:115-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old lock time (2020) and the refusal the test sees. Does not establish the tip's age: the tip is the fresh marker from :108, which is why "old lock" is accurate where the previous wording "old times" was not.

The test runs `lock "$W" "build-loop dispatch of 2026-10-01-x, UTC 2020-01-01T00:00:00Z"; rm -rf "$W"`, then `dsp --prompt "$B" --steal; refused "… which is missing or a symbolic link …"` (:116-117). The test passed.

**Evidence:** `test/scripts/build-loop-dispatch.bats:108`, `test/scripts/build-loop-dispatch.bats:115-117`, logs/suite.log

---

## Claim 19: commit d4d178d9, C1: "the lock reason records the tip a loop was dispatched at (…); a handoff marker ends the loop only when it differs from that tip, so a second --prompt after a marker re-dispatch refuses (two agents in one worktree, F44)."

**Location:** commit d4d178d9 message, C1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 1, 3 and 7. Does not establish a forged dispatch-form reason (Q-103).

See Claims 1, 3 and 7. The second-run refusal is p3 (C2) and suite :111.

**Evidence:** `scripts/build-loop.sh:1299-1303`, `scripts/build-loop.sh:1312-1314`, logs/p3-tips.log

---

## Claim 20: commit d4d178d9, C2: "--start refuses when a worktree has the absent branch checked out unborn, and the exemption names ready, blocked and stopped."

**Location:** commit d4d178d9 message, C2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unborn refusal (Claim 9) and that `ended` lists exactly those three loop values (before this commit, any value but `working` was exempt). Does not establish any other refusal.

The exemption is `[[ "${STATUS[loop]}" == ready || "${STATUS[loop]}" == blocked || "${STATUS[loop]}" == stopped ]] || return 1` (:1300). The removed line was `elif [[ -n "$WT_LOCK" && "${STATUS[loop]}" == working ]] && ! steal` (diff 4b863735..d4d178d9).

**Evidence:** `scripts/build-loop.sh:1300`, `scripts/build-loop.sh:1323`, logs/p4-s1s2s4.log

---

## Claim 21a: commit d4d178d9, C3: "a dispatch lock path that is not absent or a plain file refuses with its own reason (a FIFO would block, a dangling link would be followed); the held lock says "retry once it ends""

**Location:** commit d4d178d9 message, C3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new refusal, the two counterfactuals, and the new held-lock text. Does not establish the race between the type test and the open.

See Claims 4 and 12. The counterfactuals are in p7-pre-c3.log: the FIFO hit the timeout (`fifo exit 124`), and the dangling link was followed (its target was created).

**Evidence:** `scripts/build-loop.sh:1415-1419`, logs/p1-lockfile.log, logs/p7-pre-c3.log

---

## Claim 21b: commit d4d178d9, C3: "and the header names the two retryable refusals."

**Location:** commit d4d178d9 message, C3
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the header names two refusals that clear by waiting. It does not hold that no other refusal is retryable, the same residue as Claim 5.

See Claim 5. A "could not be added" refusal cleared with no repository change (p6-retry.log).

**Evidence:** `scripts/build-loop.sh:315-317`, logs/p6-retry.log

---

## Claim 22: commit d4d178d9, C4: "dispatch runs with 9>&-."

**Location:** commit d4d178d9 message, C4
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the redirection and its effect (Claim 12). Does not establish that a test guards it: M6, which removes `9>&-`, passes the suite (`mut-M6-no9close.log`, 4/4 ok), and the commit does not claim a test for C4.

The arm runs `dispatch "${ARGS[0]}" 9>&- > "$GATE_TMP/line" || { cat "$GATE_TMP/line"; exit 2; }` (:1420).

**Evidence:** `scripts/build-loop.sh:1420`, logs/p2-fd9.log, logs/mut-M6-no9close.log

---

## Claim 23: commit d4d178d9, C5: "readerform before any line prints the path."

**Location:** commit d4d178d9 message, C5
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 10.

See Claim 10.

**Evidence:** `scripts/build-loop.sh:1326-1337`, logs/p4-s1s2s4.log

---

## Claim 24: commit d4d178d9, C6: "header, comments, STEAL_AGE in messages, floor "below" with prompt files, test 4's name."

**Location:** commit d4d178d9 message, C6
**Type:** Staleness / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each named item changed in the diff: the header at :284-317, the comments at :1296-1307, :1322, :1326 and :1411-1414, the messages at :1285 and :1294, the prompt at :1359, and the test name at bats:87. Their accuracy is verdicted in Claims 1-18.

Each item is a hunk of `git diff 4b863735..d4d178d9 -- scripts test` (paraphrased — no quote available because the claim is a list of six diff hunks already quoted in Claims 1-15).

**Evidence:** `scripts/build-loop.sh:284-317`, `scripts/build-loop.sh:1285`, `scripts/build-loop.sh:1294-1307`, `scripts/build-loop.sh:1359`, `test/scripts/build-loop-dispatch.bats:87`

---

## Claim 25: commit d4d178d9, C7: "the plan's as-built note supersedes the older dispatch text."

**Location:** commit d4d178d9 message, C7; `docs/working/plan-build-loop-handoff.md` U3d bullet
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the note now says it supersedes the older text and carries the new lock reason and the ended rule. Does not check the rest of the note against the code (docs are out of this pass's scope).

The d4d178d9 diff changes the bullet to `**As built (2026-10-10, \`feat/build-loop-u3d\`; supersedes D1's lock and steal text, the "Script interface" Dispatch bullets, F44 and T40 where they differ):**`. It also adds `"build-loop dispatch of STEM at TIP, UTC TIME"` and the rule `the lock reason … names another tip`.

**Evidence:** `git show d4d178d9 -- docs/working/plan-build-loop-handoff.md` (plan line 320)

---

## Claim 26: commit d4d178d9: "Tests for C1, C2, C3 and a working tip under an old lock; each mutation-checked."

**Location:** commit d4d178d9 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the tests exist and that a mutation of each fix fails the suite (rerun here; the author's own mutation runs are not visible). It does not hold for "old lock" read as an old time: the lock in that test has the current time.

The tests are bats:30 and :91 (C1 reason), :110-111 (C1 second run), :71-74 (C2), :64-70 (C3), and :96-98 (working tip). Mutation results from mut.sh:

| Mutation | Change | Result |
|---|---|---|
| M1 | no marker-kind test | test 4 fails at :98 |
| M2 | no tip comparison | test 4 fails at :111 |
| M3 | no unborn refusal | test 3 fails at :73 |
| M4 | no `-L` test | test 3 fails at :70 |
| M5 | --start records `STATUS[sha]` | test 1 fails at :30 |

The working-tip test's lock is `lock "$W" "build-loop dispatch of 2026-10-01-x at $M, UTC $(date -u +%Y-%m-%dT%H:%M:%SZ)"` (bats:97). That is a fresh lock recorded at an earlier tip. Its own comment (:96) says this precisely: "under a lock taken at another tip". A precise version of the message: "a working tip under a lock taken at an earlier tip".

**Evidence:** `test/scripts/build-loop-dispatch.bats:96-98`, logs/mut-M1-noloopstate.log, logs/mut-M2-nosha.log, logs/mut-M3-nounborn.log, logs/mut-M4-nosymlinkcheck.log, logs/mut-M5-starttipsha.log

---

## Claim 27: commit d4d178d9 Notes: "C1 takes the security critic's recorded-tip design over a commit-time comparison (no clock, no 1-second ties)."

**Location:** commit d4d178d9 message, Notes
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the critic proposed recording the tip, and that `ended` reads no clock. Does not judge the design choice.

The security review's Overall Assessment says: "tie the exemption to the lock having been taken before the marker, for example by recording the dispatched tip in the lock reason" (docs/reviews/security-review-2026-10-10-u3d-final.md:205). `ended` (:1299-1303, quoted in Claim 3) compares ids only and makes no `date` or commit-time read.

**Evidence:** `scripts/build-loop.sh:1299-1303`, `docs/reviews/security-review-2026-10-10-u3d-final.md:205`

---

## Submitted Claims

## Claim 28: "Two concurrent --prompt runs that would each add a worktree for the same branch: exactly one prints ok, the other refuses (the dispatch flock)."

**Submitted by:** security-reviewer (S1)
**Location:** `scripts/build-loop.sh:1409-1422`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 6 rounds of two concurrent `--prompt --dir` adds from the main worktree at d4d178d9: one `ok` (exit 0) and one "another --start or --prompt is running …; retry once it ends" (exit 2) each round, with the branch in 1 worktree afterwards. Does not establish two concurrent `--steal` runs, or runs from two different linked worktrees of one repository.

In p4-s1s2s4.log (S1), rounds 1-6 gave exits `2/0`, `0/2`, `0/2`, `0/2`, `0/2` and `2/0`, each with `wts with feat/x=1`. The mechanism is the flock at :1419 (quoted in Claim 4), held across dispatch (Claim 8).

**Evidence:** `scripts/build-loop.sh:1415-1420`, logs/p4-s1s2s4.log

---

## Claim 29: "--prompt refuses an existing worktree whose path fails readerform before it locks it or prints its path."

**Submitted by:** security-reviewer (S2)
**Location:** `scripts/build-loop.sh:1327`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers paths holding a blank, `;` and `$(...)`, and a path holding a newline. Each was run with no flag, with `--dir` elsewhere, with `--steal`, and with the directory removed: a fixed one-line refusal, exit 2, no lock, path not printed. Does not establish readerform's own character class beyond these inputs.

See Claim 10. In p4-s1s2s4.log (S2), every run printed one line (`lines=1`), the fixed message, and exit 2. The lock count was `0`. The `INJ` count of `1` in the first case is the directory's own name, `my wt;$(touch INJ)`, matched by `grep INJ`, not a created file. The second case, whose name has no "INJ", shows `0`.

**Evidence:** `scripts/build-loop.sh:1325-1333`, logs/p4-s1s2s4.log

---

## Claim 30: "With submodule.recurse=true, an active submodule, submodule.s.update=!cmd and an initialised module git dir carrying a smudge filter, --prompt's worktree add ran no command under git 2.39.5."

**Submitted by:** security-reviewer (S3)
**Location:** `scripts/build-loop.sh:1340`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 with this exact setup, run against a positive control:
- the config: `submodule.recurse`, `submodule.s.active`, `submodule.s.url`, and `submodule.s.update=!touch …/UPDATE-RAN`
- `.git/modules/s` as a non-bare clone config, with `filter.x.smudge` (required) and `core.hooksPath` holding a post-checkout hook
- the loop branch's `.gitmodules` and gitlink `s`, whose tree has `* filter=x`

Does not establish other git versions, `--start`'s add, or the module's hook: the positive control did not run that hook either, so the hook leg has no positive control.

In p5-submodule.log, `--prompt "$B" --dir "$P/wA"` printed `ok` and exit 0, `wA/s` was empty (`[]`), and no marker file was found. The positive control, an unhardened `git checkout -q --detach feat/x` in the main worktree with the same config, populated `s` (`.git .gitattributes f.txt`) and created `SMUDGE-RAN`.

**Evidence:** `scripts/build-loop.sh:1340`, logs/p5-submodule.log

---

## Claim 31: "A newline in a lock reason is printed as a blank inside the single refuse line."

**Submitted by:** security-reviewer (S4)
**Location:** `scripts/build-loop.sh:1285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-`--steal` refusal, which prints the reason, for an LF-separated reason and a CR-only reason. Does not apply to the `--steal` refusal: it prints no reason at all ("cannot read the time …"), and was one line in both cases.

The flattening is `STEAL_WHY="its worktree $WT is locked (${WT_LOCK//[$'\n\r']/ }): …"` (:1285). In p4-s1s2s4.log (S4), the reason `x\nok fake line\ndispatched 1` printed one line, `… is locked (locked x ok fake line dispatched 1): a live loop may hold it; …`. The reason `y\rcr only` printed one line, `(locked y cr only)`, with no `\r` in the output. Every run gave `lines=1` and exit 2.

**Evidence:** `scripts/build-loop.sh:1283-1295`, logs/p4-s1s2s4.log

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`scripts/build-loop.sh:291-295`): a given `--dir` that is not a path --dir takes is a usage error (exit 1), not a refuse line. Only the default DIR gives the refuse line (:1336). Suggested wording: "DIR exists, or the default is not a path --dir takes".
- **Claim 5** (`scripts/build-loop.sh:315-317`): "Only two refusals can clear with no change to the repository" holds for the rule refusals only. A refusal that names a failed git command ("could not be added", read, listed, created or locked) can clear on a retry (p6: a `--dir` parent at mode 555, fixed outside the repository). Scope the sentence to the rule refusals.
- **Claim 21b** (commit d4d178d9, C3): "the two retryable refusals" carries Claim 5's residue.
- **Claim 26** (commit d4d178d9): "a working tip under an old lock". The test's lock has the current time and was taken at an earlier tip, as its own comment (bats:96) says. The mutation checks hold (M1-M5 each fail the suite).

### Unverifiable
(none)

Note for the rubric, not a mismatch: no test guards C4. M6 (`9>&-` removed) passes the suite 4/4, and only probe p2 shows its effect. The commit does not claim a C4 test.

**Goal-Alignment Note:** The goal is to land U3d after a clean review-fix loop. Every behavior the fix batch claims holds when executed: the C1 recorded tip and `ended` rule, the C2 unborn refusal before any write, the C3 lock-file refusals with no blocking, the C4 fd isolation and the C5 path check. All four submitted security endorsements verify. The four Mostly-accurate items are wording only: two header sentences and two commit-message phrases. None changes behavior, and none blocks the merge.
