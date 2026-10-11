# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3d (feat/build-loop-u3d)
**Scope:** branch diff `git diff main...HEAD` (scripts/build-loop.sh, test/scripts/build-loop-dispatch.bats) plus the commit messages of 525f947a and aff39758 (`git log main..HEAD`); the plan's D1/D2/D3/D11/D14, "Script interface" → Dispatch and "Prompt content" as the reference for prompt coverage
**Checked:** 2026-10-10
**Commit:** aff39758
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 31
**Summary:** 21 verified, 6 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): no claim below matches a logged pattern (all logged entries are measured values quoted from artifact sets; this diff's claims are behavioural).

Execution provenance (every executed claim cites these). All probes ran under `set -eu` in their own `mktemp -d /tmp/claude-1000/u3d-rev-cfc-XXXX` directory with the fixtures' hermetic env (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, fixture HOME, `LC_ALL=C`), running `/workspace/.claude/wt-build-loop-u3d/scripts/build-loop.sh` against a throwaway repo; git 2.39.5. Scripts and captured output are in `/tmp/claude-1000/-workspace/a5f5e272-7757-42c2-8d1d-5c819728d807/scratchpad/u3d-i1-cfc/` (abbreviated `$CFC` below):
- **bats:** `TMPDIR=$(mktemp -d /tmp/claude-1000/u3d-rev-cfc-XXXX) timeout 600 bats test/scripts/build-loop-dispatch.bats`, cwd the worktree, 2026-10-11T02:01:26Z, exit 0, 4/4 ok → `$CFC/bats.log`
- **p1:** porcelain `-z` records for main, linked, locked-with-reason, `--lock` without reason, prunable, locked-and-missing worktrees; `update-ref ... ""` on an existing ref → `$CFC/p1.sh`, `$CFC/p1.log` (exit 128 by design: the last command is the expected update-ref failure)
- **p2:** skip line under --start; locked missing worktree under --prompt/--steal; failed add after update-ref → `$CFC/p2.sh`, `$CFC/p2.log`, exit 0
- **p3:** a hand-written lock reason ending " UTC TIME" under --steal; a bare repo run from a linked worktree → `$CFC/p3.sh`, `$CFC/p3.log`, exit 0
- **p4:** three mutations of a copy of scripts/ + test/ run against the dispatch suite → `$CFC/p4.sh`, `$CFC/mut.log`, 2026-10-11T02:01:49Z, exit 0
- **p5:** branch reflog after --start; a self-merge brief's --check from the loop's worktree and from the main checkout → `$CFC/p5.sh`, `$CFC/p5.log`, 2026-10-11T02:03:12Z, exit 0
- **p6:** `TMPDIR` pointing at a missing directory for --start and --prompt → `$CFC/p6.sh`, `$CFC/p6.log`, 2026-10-11T02:03:46Z, exit 0

---

## Claim 1: "--start dispatches a build loop for BRIEF (D1): after --check's state gate, with --settings' constraints line ok and --status reading the brief open, dispatched under 4 times and its branch absent"

**Location:** `scripts/build-loop.sh:279-281`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order and presence of the state gate (top-level `state_gate`, then gate_start's `default_gate` and `store_check`) and the four preconditions in `dispatch`; does not establish what happens when `status_fields` itself skips the brief (Claim 4) or the --prompt variant (Claim 6).

The state gate runs before any dispatch for these modes: `GATED=""; [[ "$MODE" == settings || "$MODE" == status ]] || GATED=1` and `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`scripts/build-loop.sh:460-461`); the mode block then calls `gate_start` before `dispatch` (diff hunk `start|prompt) gate_start; dispatch "${ARGS[0]}" > "$GATE_TMP/line" || ...`, `scripts/build-loop.sh:1372-1376`). In `dispatch` the checks run in the header's order:

```bash
# scripts/build-loop.sh:1283-1287
  if [[ "$CONSTRAINTS" != ok ]]; then x="no loop is dispatched until --settings reads the constraints as ok (${CONSTRAINTS_LINE#constraints })"
  elif [[ "${STATUS[state]}" != open ]]; then x="the brief is ${STATUS[state]} on the default branch; only an open brief is dispatched"
  elif [[ "${STATUS[dispatched]}" -ge 4 ]]; then x="it was dispatched ${STATUS[dispatched]} times, and the cap is 4"
  elif [[ "$MODE" == start && "${STATUS[loop]}" != absent ]]; then x="its branch $br exists; --prompt re-dispatches it"
```
(excerpt ends :1287; enclosing dispatch() continues to :1312 — read)

Executed: bats test 3 refuses each of missing, none-hard, `Dispatched: 4`, `Status: done` and `filter.x.clean` (the last with `refuse state ...`, exit 2), and test 1 refuses a second --start with "its branch feat/x exists" (`$CFC/bats.log`, ok 1 and ok 3).

**Evidence:** `scripts/build-loop.sh:460-461`, `scripts/build-loop.sh:989-996`, `scripts/build-loop.sh:1277-1312`, `scripts/build-loop.sh:1372-1376`, `test/scripts/build-loop-dispatch.bats:25-67`, `$CFC/bats.log`

---

## Claim 2: "it creates the branch at the default branch's commit and adds a worktree for it at DIR (absolute; default .claude/wt-STEM in the main worktree), locked with the reason "build-loop dispatch of STEM, UTC TIME""

**Location:** `scripts/build-loop.sh:282-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch's commit, the default DIR in a non-bare repo, the bare-repo refusal, --dir's absform rule and the lock reason text; does not establish that DIR is canonicalised (a symlinked spelling of an existing worktree is compared as a string, which matters only for --prompt's `--dir`).

```bash
# scripts/build-loop.sh:1282, 1298, 1302-1303
  reason="build-loop dispatch of $stem, UTC $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    [[ -n "$DIR" || -z "$MAINWT" ]] || DIR="$MAINWT/.claude/wt-$stem"
    elif [[ "$MODE" == start ]] && ! git update-ref "refs/heads/$br" "$MAIN_SHA" "" 2>/dev/null; then x="its branch $br could not be created"
    elif ! git worktree add -q --lock --reason "$reason" "$DIR" "$br" > "$GATE_TMP/add" 2>&1; then
```
(non-contiguous lines of dispatch(), which runs :1277-1312 — read)

Executed: bats test 1 asserts the worktree HEAD, its symbolic ref and `feat/x` all equal main's commit and the porcelain `locked build-loop dispatch of 2026-10-01-x, UTC ...Z` line; test 2 asserts --dir's rules. p3 (bare repo, run from a linked worktree, no --dir) refuses with "the default worktree directory (.claude/wt-2026-10-01-x in the main worktree) is not an absolute path ...; give --dir" (`$CFC/p3.log`).

**Evidence:** `scripts/build-loop.sh:333`, `scripts/build-loop.sh:356-365`, `scripts/build-loop.sh:1282-1307`, `$CFC/bats.log`, `$CFC/p3.log`

---

## Claim 3: "Prints ok BRIEF BRANCH DIR / dispatched N — N: the brief's Dispatched: count plus one ...; then the loop's prompt, every line after."

**Location:** `scripts/build-loop.sh:285-289`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two fixed lines and the prompt following; does not establish anything about the prompt's content (Claims 17-23).

```bash
# scripts/build-loop.sh:1281, 1309-1311
  br="${STATUS[branch]}"; stem="${a##*/}"; stem="${stem%.md}"; n=$(( ${STATUS[dispatched]} + 1 ))
  printf 'ok %s %s %s\ndispatched %s\n' "$a" "$br" "$DIR" "$n"
  loop_prompt "$a" "$stem" "$ct" "$n"
```
(non-contiguous lines of dispatch() :1277-1312 — read)

Executed: test 1 (`dispatched 1`), test 3 (`Dispatched: 3` → `dispatched 4`), test 4 (`--prompt --steal` → `dispatched 1`) all pass (`$CFC/bats.log`).

**Evidence:** `scripts/build-loop.sh:1277-1312`, `test/scripts/build-loop-dispatch.bats:27-28,66,84`, `$CFC/bats.log`

---

## Claim 4: "or refuse BRIEF: WHY (as --status skips it, or a rule above, or DIR exists or the worktree could not be added)"

**Location:** `scripts/build-loop.sh:290-291`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Legibility-target:** the orchestrator (U4's skill step 10) and any reader who parses the first word of --start/--prompt output
**Scope:** Covers the line printed when `status_fields` skips the brief; does not establish anything about the other refusals in the parenthesis, which do print `refuse BRIEF: WHY`.

When --status would skip the brief, dispatch prints --status's skip line verbatim, not a `refuse` line:

```bash
# scripts/build-loop.sh:1279-1280
  status_fields "$a"
  [[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return 1; }
```
(excerpt ends :1280; enclosing dispatch() continues to :1312 — read)

Executed (p2, two open briefs naming `feat/x` and `Feat/X`): `--start ... -> rc=2` printing `skip docs/working/briefs/2026-10-01-x.md: another open brief on the default branch names the same branch (compared ignoring case)` (`$CFC/p2.log`). The function's own comment says it correctly ("one refuse or skip line", :1275), and --check's header lists `skip BRIEF: WHY` as a separate form (:168-169). The header should list `skip BRIEF: WHY (as --status skips it)` as a third output form beside `refuse BRIEF: WHY`. Exit 2 is the same for both.

**Evidence:** `scripts/build-loop.sh:290-291`, `scripts/build-loop.sh:1274-1280`, `scripts/build-loop.sh:168-169`, `$CFC/p2.log`

---

## Claim 5: "... leaving no branch or worktree it made." (--start header)

**Location:** `scripts/build-loop.sh:291-292`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Legibility-target:** header reader
**Scope:** Covers every --start refusal path: the only one reached after `update-ref` created the branch is a failed `worktree add`, and no refusal follows a successful add. Does not establish that a failed `update-ref -d` leaves nothing (it does not; see below), or the clean-up of a partially created worktree inside git (git's own).

The only refusal after the branch exists is the failed add, which deletes it by compare-and-swap:

```bash
# scripts/build-loop.sh:1303-1306
    elif ! git worktree add -q --lock --reason "$reason" "$DIR" "$br" > "$GATE_TMP/add" 2>&1; then
      x="the worktree $DIR could not be added"
      [[ "$MODE" != start ]] || git update-ref -d "refs/heads/$br" "$MAIN_SHA" 2>/dev/null || x+="; its new branch $br could not be removed"
    fi
```
(excerpt ends :1306; enclosing dispatch() continues to :1312 — read)

After a successful add `x` stays empty and the function only prints (`:1308-1311`), so there is no refusal after `git worktree add` succeeded. Executed: p2's add into a path under a regular file refuses and leaves `feat/z absent` (`$CFC/p2.log`); bats test 3 asserts `none` after the same; p4's mutation that drops the `update-ref -d` turns test 3 red (`$CFC/mut.log`). The qualifier missing: when the `update-ref -d` itself fails the branch stays, and the refusal says so ("; its new branch ... could not be removed"); the header's unconditional "leaving no branch" should carry that exception.

**Evidence:** `scripts/build-loop.sh:1300-1311`, `test/scripts/build-loop-dispatch.bats:60-62`, `$CFC/p2.log`, `$CFC/mut.log`

---

## Claim 6: "--prompt re-dispatches a brief whose branch exists, under the same rules but the branch's: prints the same lines. It adds a locked worktree at DIR when no worktree has the branch, and locks the one that has it (DIR, if given, must be that one)."

**Location:** `scripts/build-loop.sh:293-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch-present rule, the add path (same default DIR, `--lock --reason`), the lock of an unlocked existing worktree and the `--dir` mismatch refusal; does not establish the locked-and-missing case (Claim 8b).

```bash
# scripts/build-loop.sh:1288, 1291-1296
  elif [[ "$MODE" == prompt && "${STATUS[loop]}" == absent ]]; then x="its branch $br does not exist; --start creates it"
  elif [[ "$WT_N" -eq 1 ]]; then
    if [[ -n "$DIR" && "$DIR" != "$WT" ]]; then x="its branch $br is checked out in $WT, not in --dir's directory"
    elif [[ -n "$WT_PRUNE" ]]; then x="its branch $br is checked out in $WT, which is missing (git worktree prune drops it)"
    elif [[ -n "$WT_LOCK" ]] && ! steal; then x="$STEAL_WHY"
    elif ! { [[ -z "$WT_LOCK" ]] || git worktree unlock "$WT"; } || ! git worktree lock --reason "$reason" "$WT"; then x="its worktree $WT could not be locked"
```
(non-contiguous lines of dispatch() :1277-1312 — read)

Executed: bats test 4 covers "does not exist", the `--dir` mismatch, locking an unlocked worktree, and re-adding a worktree after `git worktree prune` with HEAD at the tip (`$CFC/bats.log`).

**Evidence:** `scripts/build-loop.sh:1277-1312`, `test/scripts/build-loop-dispatch.bats:69-95`, `$CFC/bats.log`

---

## Claim 7: "A locked one refuses unless --steal is given, its lock reason ends "UTC TIME", and that time and the tip's commit time are both over 2 hours ago; then it is locked again with a new reason."

**Location:** `scripts/build-loop.sh:296-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --steal flag, the trailing-time regex, the max(lock, tip) test against 7200 s, and the relock; does not establish that the reason was written by build-loop.sh (any reason ending " UTC TIME" qualifies, as the header says; see Claim 26b for the commit message's narrower wording).

```bash
# scripts/build-loop.sh:1264-1272
  [[ -n "$STEAL" ]] || return 1
  if ! [[ "$WT_LOCK" =~ \ UTC\ ([0123456789]{4}-[0123456789]{2}-[0123456789]{2}T[0123456789]{2}:[0123456789]{2}:[0123456789]{2}Z)$ ]] \
    || ! l="$(date -u -d "${BASH_REMATCH[1]}" +%s)" \
    || ! t="$(git cat-file commit "${STATUS[sha]}" | LC_ALL=C awk 'h { next } /^$/ { h = 1; next } /^committer / { print $(NF - 1) }')" \
    || [[ ! "$t" =~ ^[0123456789]+$ ]]; then
    STEAL_WHY="its worktree $WT is locked, and --steal cannot read the time its lock reason ends with or the tip's commit time"; return 1
  fi
  [[ "$t" -le "$l" ]] || l="$t"
  [[ $(( $(date -u +%s) - l )) -gt 7200 ]] || { STEAL_WHY="its worktree $WT is locked, and its lock or tip is under 2 hours old"; return 1; }
```
(excerpt ends :1272, the function's last body line; steal() :1261-1273 — read)

Executed: test 4 covers no --steal, a new lock, an old lock on a new tip, a reason "by hand", a lock 1 h old on an old tip, and both old → ok with the 2020 reason replaced (`$CFC/bats.log`); p4's mutation that ignores the tip time turns test 4 red (`$CFC/mut.log`).

**Evidence:** `scripts/build-loop.sh:1257-1273`, `scripts/build-loop.sh:1294-1296`, `test/scripts/build-loop-dispatch.bats:72-85`, `$CFC/bats.log`, `$CFC/mut.log`

---

## Claim 8a: "Also refused: the branch in two worktrees"

**Location:** `scripts/build-loop.sh:299-300`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the WT_N > 1 refusal for both modes; does not establish it under test (no test forces a branch into two worktrees, which needs `worktree add --force`).

```bash
# scripts/build-loop.sh:1290
  elif [[ "$WT_N" -gt 1 ]]; then x="its branch $br is checked out in $WT_N worktrees"
```
(single line of dispatch() :1277-1312 — read)

WT_N counts every record whose `branch refs/heads/$1` line matches (`scripts/build-loop.sh:1250, 1253`).

**Evidence:** `scripts/build-loop.sh:1241-1256`, `scripts/build-loop.sh:1290`

---

## Claim 8b: "Also refused: ... or in one that is missing."

**Location:** `scripts/build-loop.sh:300`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Medium
**Legibility-target:** header reader and the orchestrator deciding whether to --steal after a restart
**Scope:** Covers an unlocked missing worktree (refused) and a locked missing one (not refused as missing); does not establish what a loop launched into the missing DIR then does.

The refusal keys on git's `prunable` attribute (`scripts/build-loop.sh:1293`), and git 2.39 does not mark a **locked** worktree prunable. p1's listing for a locked worktree whose directory was removed ends `branch refs/heads/e|locked x||`, with no `prunable` field (`$CFC/p1.log`). Because --start always locks the worktree it adds, a dead loop's missing worktree is normally a locked one. p2 (worktree locked with a 2020 build-loop reason, tip committed 2020, directory moved away): `--prompt` refuses as a live lock ("a live loop may hold it"), and `--prompt --steal` exits 0 printing `ok ... feat/x /tmp/.../r/.claude/wt-2026-10-01-x`, with `ls` then reporting "No such file or directory" for that DIR and the porcelain showing a new lock (`$CFC/p2.log`). Only the unlocked-and-missing case is refused, as test 4 checks after its `git worktree unlock "$W"; rm -rf "$W"` (`test/scripts/build-loop-dispatch.bats:89-90`). The header should say "or in one that is missing and unlocked", or the code should test the directory itself (`[[ -d "$WT" ]]`), not only `prunable`.

**Evidence:** `scripts/build-loop.sh:300`, `scripts/build-loop.sh:1252`, `scripts/build-loop.sh:1293-1296`, `test/scripts/build-loop-dispatch.bats:89-90`, `$CFC/p1.log`, `$CFC/p2.log`

---

## Claim 9: "Writes nothing but ... --start's branch and the worktrees and locks --start and --prompt make, and its own temporary directory"

**Location:** `scripts/build-loop.sh:303-308`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Legibility-target:** header reader
**Scope:** Covers the files and refs that --start and --prompt write; does not establish anything about --check or --merge, whose part of the sentence is unchanged.

The list misses three writes. (1) The new branch's reflog: after --start, p5 lists `.git/logs/refs/heads/` as `feat` and `main` (`$CFC/p5.log`), and the same sentence names "that branch's reflog" for --merge. (2) --prompt removes an existing lock before relocking: `{ [[ -z "$WT_LOCK" ]] || git worktree unlock "$WT"; }` (`scripts/build-loop.sh:1295`). (3) The `update-ref -d` on a failed add (`:1305`), which removes a write rather than adding one. A precise wording would be "--start's branch and its reflog, and the worktrees and locks --start and --prompt make or replace". `git worktree add` also creates a missing `.claude/` parent (paraphrased — no quote available because the parent directory is made by git's leading-directory creation, not by a line of the script; p5 shows `.claude` present after the first --start in a repo that had none).

**Evidence:** `scripts/build-loop.sh:303-308`, `scripts/build-loop.sh:1295-1305`, `$CFC/p5.log`

---

## Claim 10: "Exit: 0 ... for --start and --prompt ok; 2 any other ... --start or --prompt verdict line, or the state gate not ok ... 1 ... a failed mktemp (--check, --merge, --start, --prompt; no line printed)"

**Location:** `scripts/build-loop.sh:311-317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit codes for ok, refuse, skip, the state gate and a failed mktemp; does not establish exits after an unexpected failed command inside `dispatch` (it runs as the left side of `||`, so `set -e` is off there and such a failure falls through to the next line rather than exiting).

```bash
# scripts/build-loop.sh:1372-1376
  start|prompt)
    gate_start
    dispatch "${ARGS[0]}" > "$GATE_TMP/line" || { cat "$GATE_TMP/line"; exit 2; }
    cat "$GATE_TMP/line"
    ;;
```
(the whole case arm)

Executed: ok → 0, refuse and skip → 2, planted `filter.x.clean` → 2 (`$CFC/bats.log`, `$CFC/p2.log`); `TMPDIR` pointing at a missing directory → `--start rc=1 stdout_bytes=0` and `--prompt rc=1 stdout_bytes=0`, with mktemp's error on stderr and no branch left (`$CFC/p6.log`).

**Evidence:** `scripts/build-loop.sh:311-317`, `scripts/build-loop.sh:989-991`, `scripts/build-loop.sh:1372-1376`, `$CFC/bats.log`, `$CFC/p2.log`, `$CFC/p6.log`

---

## Claim 11: "CONSTRAINTS (its word: ok, missing, none-hard or unreadable)"

**Location:** `scripts/build-loop.sh:530-533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the derivation from every CONSTRAINTS_LINE form read_settings sets; does not establish CONSTRAINTS for a mode that never calls read_settings (--settings and --status print the line, not the word; both dispatch modes call it through gate_start).

```bash
# scripts/build-loop.sh:592
  CONSTRAINTS="${CONSTRAINTS_LINE#constraints }"; CONSTRAINTS="${CONSTRAINTS%%[ :]*}"  # row 270: the line's own word
```
(last line of read_settings() :536-593 — read)

The lines read_settings sets start `constraints ok N-hard`, `constraints missing:`, `constraints none-hard:` or `constraints unreadable:` (`:580-589`), so cutting at the first space or colon leaves exactly the four words. Executed: test 3's missing and none-hard refusals (`$CFC/bats.log`).

**Evidence:** `scripts/build-loop.sh:578-592`, `scripts/build-loop.sh:995`, `$CFC/bats.log`

---

## Claim 12: "wt_of BRANCH: the worktrees git lists. MAINWT is the first (the main worktree; empty when bare); WT_N counts those with BRANCH checked out, and WT, WT_LOCK ("locked", or "locked REASON") and WT_PRUNE (set when git calls it prunable) describe the last. Returns 1 when git cannot list them."

**Location:** `scripts/build-loop.sh:1237-1240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's porcelain `-z` output for main, linked, locked with a reason, `--lock` with no reason, prunable, locked-and-missing, and bare; does not establish other git versions' fields, or a worktree whose path holds a NUL (impossible).

```bash
# scripts/build-loop.sh:1248-1253
      "worktree "*) p="${x#worktree }"; b=""; lk=""; pr=""; n=$((n + 1)); [[ "$n" -ne 1 ]] || MAINWT="$p" ;;
      bare) [[ "$n" -ne 1 ]] || MAINWT="" ;;
      "branch refs/heads/$1") b=1 ;;
      locked|"locked "*) lk="$x" ;;
      prunable|"prunable "*) pr=1 ;;
      "") [[ -z "$b" ]] || { WT_N=$((WT_N + 1)); WT="$p"; WT_LOCK="$lk"; WT_PRUNE="$pr"; } ;;
```
(excerpt ends :1253; enclosing wt_of() continues to :1256 — read)

p1's `-z` output (NULs shown as `|`): `...|locked build-loop dispatch of s, UTC 2020-01-01T00:00:00Z||`, `...|locked added with --lock||` (git 2.39 writes that reason when `add --lock` gets none), `...|prunable gitdir file points to non-existent location||`; the bare listing in p3 is `worktree .../bare.git|bare||worktree .../lw|...`, and the bare run refused for an empty default DIR, so MAINWT was empty (`$CFC/p1.log`, `$CFC/p3.log`). A bare `locked` (`git worktree lock` with no reason) is matched by the first alternative.

**Evidence:** `scripts/build-loop.sh:1237-1256`, `$CFC/p1.log`, `$CFC/p3.log`

---

## Claim 13: "NUL-ended fields; an empty field ends each record."

**Location:** `scripts/build-loop.sh:1245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5, including the last record; does not establish a git that omits the terminating empty field (none observed).

Every record in p1's and p3's listings ends `||`, the last one included (`...|locked x||`, `...|branch refs/heads/main||`), so the `""` arm at `scripts/build-loop.sh:1253` fires for the final record too (`$CFC/p1.log`, `$CFC/p3.log`).

**Evidence:** `scripts/build-loop.sh:1245-1255`, `$CFC/p1.log`, `$CFC/p3.log`

---

## Claim 14: "steal: whether --prompt may take the locked worktree WT (D1, F44): --steal given, and both the time WT_LOCK's reason ends with and the tip's commit time over 2 hours ago (a loop dispatched on an old tip has a new lock). A lock without that time is never taken. Sets STEAL_WHY and returns 1 when not."

**Location:** `scripts/build-loop.sh:1257-1260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both times (max taken), the parse of the committer timestamp from the raw commit headers only, and the no-time refusal; does not establish behaviour for a lock time in the future (refused, since now − l is negative) or a non-GNU `date`.

The code is quoted under Claim 7 (`scripts/build-loop.sh:1264-1272`). The awk reads only header lines (`h { next } /^$/ { h = 1; next }`) and prints `$(NF - 1)` of the `committer` line, the epoch before the zone, which holds whatever spaces the name has. Executed: test 4's "by hand" lock → "cannot read the time" and the both-old case → ok; p4's tip-time mutation is caught (`$CFC/bats.log`, `$CFC/mut.log`).

**Evidence:** `scripts/build-loop.sh:1257-1273`, `$CFC/bats.log`, `$CFC/mut.log`

---

## Claim 15: "dispatch BRIEF: ... Prints "ok BRIEF BRANCH DIR", "dispatched N" and the loop prompt, or one refuse or skip line and returns 1, leaving no branch or worktree it made."

**Location:** `scripts/build-loop.sh:1274-1276`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Severity:** Low
**Legibility-target:** maintainers of dispatch, and the shared brief's "leave nothing behind on a refusal"
**Scope:** Covers each refusal path's side effects; does not establish git's own clean-up inside a failed `worktree add`.

The output forms and the no-branch/no-worktree part hold (Claims 4 and 5). Two refusals do leave a change, though not a branch or worktree. (1) On --prompt with a locked worktree that `steal` accepts, the lock is removed before the new one is taken; if `git worktree lock` then fails the refusal leaves the worktree **unlocked**, and the old lock is not restored:

```bash
# scripts/build-loop.sh:1295
    elif ! { [[ -z "$WT_LOCK" ]] || git worktree unlock "$WT"; } || ! git worktree lock --reason "$reason" "$WT"; then x="its worktree $WT could not be locked"
```
(single line of dispatch() :1277-1312 — read)

(2) A failed `update-ref -d` leaves the branch, and the refusal says so (Claim 5). The comment is literally true ("it made"), but a reader taking it as "a refusal changes nothing" would miss (1). It was not executed: forcing `lock` to fail right after a successful `unlock` needs a race or a fault injected between the two calls.

**Evidence:** `scripts/build-loop.sh:1274-1312`

---

## Claim 16: "The branch is made here (the empty old value: it must not exist), so a failed add removes only it."

**Location:** `scripts/build-loop.sh:1301`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39's create-only meaning of an empty old value and the compare-and-swap delete; does not establish that the suite guards it (p4's mutation that drops the `""` survives all four tests, since no test races a branch creation).

`git update-ref refs/heads/a <sha> ""` on an existing ref fails with "cannot lock ref 'refs/heads/a': reference already exists" (`$CFC/p1.log`). The delete passes `$MAIN_SHA` as the old value (`:1305`), so it removes the branch only while it is still where --start put it. The p4 mutation `emptyold` left all four tests ok (`$CFC/mut.log`).

**Evidence:** `scripts/build-loop.sh:1301-1306`, `$CFC/p1.log`, `$CFC/mut.log`

---

## Claim 17: "It says "send your branch to a remote": T20 holds this file to never naming git's command."

**Location:** `scripts/build-loop.sh:1314-1315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T20's grep and the prompt's wording; does not establish anything beyond the word test.

T20 is `run grep -nwi push "$BL" "$LIB"` expecting status 1 (`test/scripts/build-loop-check.bats:1667-1669`). The same grep on the branch's two files exits 1 with no output (run 2026-10-11, cwd the worktree), and the prompt line reads "never send your branch to a remote, merge, open a pull request or publish" (`scripts/build-loop.sh:1334`).

**Evidence:** `scripts/build-loop.sh:1314-1315`, `scripts/build-loop.sh:1334`, `test/scripts/build-loop-check.bats:1667-1669`

---

## Claim 18: "Your own "scripts/build-loop.sh --check $a" is advisory: run from your branch, it refuses a self-merge brief for the checkout and skips the self-merge floor."

**Location:** `scripts/build-loop.sh:1322`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a self-merge brief checked from the loop's worktree, with commits on the branch; does not establish a review brief (which reads no checkout, as the sentence's "self-merge" implies).

`checkout_gate` refuses a checkout whose HEAD is not MAIN_SHA (`scripts/build-loop.sh:917-918`); `check_line` then sets `co` (`:1071`), and `srules` runs the floor only when `$5`, which is `co`, is empty (`if [[ -z "$5" ]] && floor ...`, `:878`). Executed (p5, self-merge settings, `Paths: src/ .envrc`, the loop committing `src/a.txt` and the dot path `.envrc`): from the loop's worktree --check prints "refuse ...: a self-merge brief needs --check run from a clean checkout ...; the checkout's HEAD is 3ed15e39..., not the default branch's commit 6b31893a...", followed by `path ... A .envrc` (not denied: floor skipped), exit 2 (`$CFC/p5.log`).

**Evidence:** `scripts/build-loop.sh:875-888`, `scripts/build-loop.sh:906-918`, `scripts/build-loop.sh:1071`, `scripts/build-loop.sh:1089`, `$CFC/p5.log`

---

## Claim 19: "The orchestrator's run, from the default branch's commit, decides and applies the floor (instruction files and what they import, dot paths, the gate's own code, the cycle's records): keep every change within your brief's Paths: line and off those paths."

**Location:** `scripts/build-loop.sh:1322`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Severity:** Low
**Legibility-target:** the build loop reading its prompt
**Scope:** Covers the parenthesis against `floor`'s branches and when the floor runs; does not re-raise row 622 (that the prompt says the orchestrator's run applies the floor), only its precision.

`floor` refuses more than the parenthesis lists: the constraints doc (truthrule's `user`), `docs/thoughts/*` (`record`), working docs and reviews that are not the brief's own, and paths below an instruction file's or imported .md's name:

```bash
# scripts/lib/dev-cycle-read.sh:1958-1961
  elif [[ "$lp" == docs/thoughts/* ]]; then FLOOR_WHY=record
  elif [[ "$lp" == docs/working/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY=working
  elif [[ "$lp" == docs/reviews/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY=review
  elif truthwalk main "$lp"; then FLOOR_WHY="$TRUTH_WHY"  # walk (TRUTH_WHERE says where) or imported
```
(excerpt ends :1961; enclosing floor() continues to :1971 — read)

The floor also runs only for a brief --status reads as self-merge (`[[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1`, `scripts/build-loop.sh:1029`); for a review brief the orchestrator's `--merge --approved` runs the N rules alone, and the user's review takes the floor's place. The build-loop.sh header's own list (`:191-197`, "the user's and the cycle's records, a working doc or review that is not the brief's own") is the complete one. Since "the cycle's records" can be read to cover thoughts and other briefs' working docs, this is imprecise rather than wrong; "keep every change within Paths:" already bounds a careful loop.

**Evidence:** `scripts/build-loop.sh:1322`, `scripts/build-loop.sh:191-201`, `scripts/build-loop.sh:1029`, `scripts/lib/dev-cycle-read.sh:1953-1971`

---

## Claim 20: "Force-add your research doc (git add -f docs/working/research-$s.md), so your design records land with your work."

**Location:** `scripts/build-loop.sh:1329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path against `ownfile` and `.gitignore`; does not establish that the S rules land it when the diff spells it in upper case (it never does here: `$s` is the brief's lower-case stem in practice, and srules takes own files only when the whole path is lower case).

`$s` is the brief's full stem (`stem="${a##*/}"; stem="${stem%.md}"`, `:1281`), and ownfile takes `^docs/working/(research|plan|checkpoint|handoff|test-strategy)-(.+)\.md$` when the group equals that stem (`scripts/lib/dev-cycle-read.sh:1916`). `git check-ignore -v docs/working/research-x.md` prints `.gitignore:27:docs/working/research-*.md`, so the force-add is needed.

**Evidence:** `scripts/build-loop.sh:1281`, `scripts/build-loop.sh:1329`, `scripts/lib/dev-cycle-read.sh:1913-1918`, `.gitignore:27`

---

## Claim 21a: "End with one marker, an empty commit at your branch tip whose first line is exactly one of: "handoff: ready" ...; "handoff: blocked", with the question after a blank line ..."

**Location:** `scripts/build-loop.sh:1330-1332`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the subject and the blank second line against `marker_kind`; does not establish the single-parent and ahead-of-main conditions, which the prompt leaves out but which an `git commit --allow-empty` on the loop's branch meets.

`marker_kind` matches the subject exactly (`"handoff: ready") echo ready`, `"handoff: blocked") echo blocked`, `:617-620`) and refuses a subject that runs onto a second line (`[[ "$msg" == *$'\n'* && -n "${rest%%$'\n'*}" ]]`, `:616`), so the body must follow a blank line; it refuses a tree change ("bad it changes files", `:614`), so the commit must be empty.

**Evidence:** `scripts/build-loop.sh:598-625`, `scripts/build-loop.sh:1330-1332`

---

## Claim 21b: ""handoff: stopped: REASON" (1 to 120 printable ASCII characters)"

**Location:** `scripts/build-loop.sh:1333`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Severity:** Low
**Legibility-target:** the build loop writing its marker
**Scope:** Covers REASON's grammar; does not establish what the orchestrator does with a `bad` marker (--status skips the brief).

`marker_kind` also refuses a blank at either end of REASON:

```bash
# scripts/build-loop.sh:623
  if [[ "$subj" == "handoff: stopped: "* ]] && printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'; then echo "stopped $r"
```
(excerpt ends :623; enclosing marker_kind() continues to :625 — read)

Its own refusal text says "(REASON: 1 to 120 printable ASCII characters, no blank at either end)" (`:624`), as does the header (`:77-78`). The prompt omits "no blank at either end". A loop writing "handoff: stopped: stalled " would get a skip, not a stop.

**Evidence:** `scripts/build-loop.sh:77-79`, `scripts/build-loop.sh:621-624`, `scripts/build-loop.sh:1333`

---

## Claim 21c: "... and an options table: no heading, no line starting **Needs:**, **Status:** or **Answer, and no line starting Q- and a digit"

**Location:** `scripts/build-loop.sh:1332`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Severity:** Low
**Legibility-target:** the build loop writing a blocked body
**Scope:** Covers the prompt's body grammar against the plan; does not establish it against code, since the reader of the body (`--marker`, D11) is not built (U3b).

`grep -n -- '--marker' scripts/build-loop.sh` finds nothing (paraphrased — no quote available because the claim's checker is absent code). Against the plan: D11 says `--marker` "refuses a body line that starts (after blanks, `>` and list markers) with `#`, `**Needs:**`, `**Status:**`, `**Answer` or `Q-` and a digit" (`docs/working/plan-build-loop-handoff.md:92`). The prompt's "no line starting" leaves out the "after blanks, `>` and list markers" part, so a body line like `- **Needs:** ...` or `> # x` follows the prompt's wording and still breaks D11's rule. To verify: U3b's `--marker`, then compare the two.

**Evidence:** `scripts/build-loop.sh:1332`, `docs/working/plan-build-loop-handoff.md:92`

---

## Claim 22: "Never write the questions files, the roadmap, docs/dev-cycle.md or any other brief. In your own brief change only the Status line, from open to done, in your final change."

**Location:** `scripts/build-loop.sh:1335`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the N rules, which deny these paths under both policies; does not establish that the loop obeys it.

`nrules` denies the cycle's files ("one of the dev cycle's own files": truthrule's `cycle|settings`, and `docs/working/(briefs|cycles)`) and lets the brief's own file change only from `Status: open` to `Status: done` (`scripts/build-loop.sh:819-832`).

**Evidence:** `scripts/build-loop.sh:814-838`, `scripts/build-loop.sh:1335`

---

## Claim 23: "loop_prompt BRIEF STEM CONSTRAINTS N: the loop's prompt (plan, "Prompt content"; D2, D3, D11, D14; row 622)": every "Prompt content" item is present

**Location:** `scripts/build-loop.sh:1313-1337`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the plan's 12 "Prompt content" bullets (`docs/working/plan-build-loop-handoff.md:222-234`) and T19's named lines; does not establish the precision of the marker and floor lines (Claims 19, 21b, 21c).

Each bullet maps to a line: the evidence line (`:1319`); the `cd ABS-PATH &&` rule and "Your shell starts outside any checkout" (`:1320`); `git show $MAIN_SHA:$a` (`:1321`); `Merge policy: ${STATUS[policy]}` (`:1322`); the constraints quoted with `> ` and the DD rule with Path A and the three blocked cases (`:1324-1328`); the force-add (`:1329`); the three markers and the body grammar (`:1330-1333`); subagents only for research and review, scratch under `$s/`, and the never list (`:1334`); never write the cycle's files (`:1335`); own brief's Status only (`:1335`); "Run research-plan-implement with no plan-approval gate ... a question goes in a blocked marker" (`:1323`); --check advisory (`:1322`). Executed: test 1 greps 15 of these strings in the printed prompt, including `cd $W &&`, `under 2026-10-01-x/ in your scratchpad directory`, `no plan-approval gate`, `is advisory` and `applies the floor` (`$CFC/bats.log`).

**Evidence:** `scripts/build-loop.sh:1313-1337`, `docs/working/plan-build-loop-handoff.md:222-234`, `test/scripts/build-loop-dispatch.bats:31-37`, `$CFC/bats.log`

---

## Claim 24: Test names and comments (T-ids; "leaving nothing"; helpers' comments)

**Location:** `test/scripts/build-loop-dispatch.bats:13-23,25,41,50,60,69`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four test names against what each test asserts and the T-id rows (T19, T40, T41, T44 in the plan's table; T24 from revision 2's table at 3a005378, which revision 4 keeps), and the helper comments; does not establish that test 1's existing-branch refusal leaves nothing (T24's "nothing left behind" is checked with `none` only in test 3).

T24 in revision 2: "`--start` with brief not open or branch existing → refuse, nothing left behind; `--prompt` on an existing branch" (`git show 3a005378:docs/working/plan-build-loop-handoff.md`, line 181). Test 3 checks the not-open case with `none` and test 4 the --prompt case. T41's two halves are split: `Dispatched: 3` → `dispatched 4` through --start in test 3, and `Dispatched: 4` refused under --prompt in test 4. "leaving nothing": `none` asserts no `feat/x` and one listed worktree (`:20-21`) after every refusal in test 3. Helpers: `ready` sets M and W as stated (`:13-16`), `refused` checks exit 2 and the whole output (`:18-19`), `lock` relocks with the reason alone (`:22-23`). All four pass (`$CFC/bats.log`).

**Evidence:** `test/scripts/build-loop-dispatch.bats:1-95`, `docs/working/plan-build-loop-handoff.md:371-386`, `$CFC/bats.log`

---

## Claim 25a: Commit 525f947a: "build-loop-dispatch.bats, four tests: the prompt's required lines, the worktree at main's commit and its lock; --dir rules; refusals that leave no branch or worktree (constraints, state, cap, a failed add, planted state); --prompt's lock, --steal at two hours, a missing worktree."

**Location:** `525f947a` (commit message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the summary of each test; does not establish the "missing worktree" coverage beyond the unlocked case (see Claim 8b).

The file has four `@test` blocks (`test/scripts/build-loop-dispatch.bats:25,41,50,69`), matching the four groups listed. "state" is the `Status: done` case and "planted state" the `filter.x.clean` case (`:57-65`). Its Notes ("a new suite file rather than build-loop-merge.bats (plan step 6 named merge.bats)") match `docs/working/plan-build-loop-handoff.md:314`.

**Evidence:** `test/scripts/build-loop-dispatch.bats:25-95`, `docs/working/plan-build-loop-handoff.md:314`, `$CFC/bats.log`

---

## Claim 25b: Commit 525f947a: "Mutation-checked against the code commit that follows."

**Location:** `525f947a` (commit message body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Severity:** Low
**Legibility-target:** reviewer weighing the suite's strength
**Scope:** Covers three mutations this review ran; does not establish which mutations the author ran (the claim names none, and no record of them is committed).

p4 applied three mutations to a copy of the code commit's script: dropping the failed-add `update-ref -d` → test 3 `not ok`; ignoring the tip's commit time in `steal` → test 4 `not ok`; dropping the empty old value from the create `update-ref` → all four `ok` (`$CFC/mut.log`). The suite therefore kills two of the three, and the create-only property (Claim 16) is untested. To verify the claim itself: the author's list of mutations and their results.

**Evidence:** `$CFC/p4.sh`, `$CFC/mut.log`

---

## Claim 26a: Commit aff39758 body: "after the state gate and store_check, with the constraints ok and the brief open, under 4 dispatches and its branch absent, it creates the branch at MAIN_SHA (update-ref with an empty old value, so a failed add removes only what it made) and a worktree locked at add time ... a locked one is taken only with --steal when both the lock's time and the tip's commit time are over 2 hours old. CONSTRAINTS as a value (row 270); the prompt tells the loop the orchestrator's run applies the floor (row 622)."

**Location:** `aff39758` (commit message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each behavioural clause, verified under Claims 1, 2, 7, 11, 16 and 19; does not repeat those claims' qualifiers (Claim 19's floor list).

"store_check" is gate_start's `store_check --main "$MAIN_SHA"` (`scripts/build-loop.sh:993`), run before `dispatch` (`:1373-1374`); "locked at add time" is `worktree add -q --lock --reason` (`:1303`). The Notes' "--prompt also needs the constraints ok" holds: the CONSTRAINTS test comes first for both modes (`:1283`).

**Evidence:** `scripts/build-loop.sh:989-996`, `scripts/build-loop.sh:1277-1312`, `scripts/build-loop.sh:1372-1376`, `$CFC/bats.log`

---

## Claim 26b: Commit aff39758 Notes: "--steal also weighs the lock's own time, so a loop just dispatched on an old tip is not stolen, and a lock without a build-loop time is never taken"

**Location:** `aff39758` (commit message Notes)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Low
**Legibility-target:** reviewer judging the author's undocumented --steal decision
**Scope:** Covers which lock reasons --steal can take; does not establish whether taking a hand-written lock that ends in a UTC time is wanted.

The regex requires only a trailing ` UTC YYYY-MM-DDTHH:MM:SSZ`, not the `build-loop dispatch of` prefix (`scripts/build-loop.sh:1265`). p3 locks the worktree with "held by hand by alice UTC 2020-01-01T00:00:00Z" on a 2020 tip, and `--prompt --steal` exits 0 and takes it (`$CFC/p3.log`). Precise version: "a lock whose reason does not end with a UTC time is never taken". The header (`:297`) already says it this way.

**Evidence:** `scripts/build-loop.sh:1265`, `scripts/build-loop.sh:297`, `$CFC/p3.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`scripts/build-loop.sh:290-291`): a brief --status skips prints `skip BRIEF: WHY`, not `refuse BRIEF: WHY`; list the skip form in the --start header.
- **Claim 8b** (`scripts/build-loop.sh:300`): a **locked** missing worktree, the normal state of a dead loop's worktree since --start always locks it, is not refused as missing: git does not mark it prunable, and `--prompt --steal` prints ok for a DIR that does not exist (p2). Either qualify the header ("missing and unlocked") or test the directory.

### Stale
- none

### Mostly Accurate
- **Claim 5** (`scripts/build-loop.sh:291-292`): a failed `update-ref -d` leaves the branch (and says so); add that exception.
- **Claim 9** (`scripts/build-loop.sh:303-308`): add the new branch's reflog and --prompt's lock replacement (an unlock) to "Writes nothing but".
- **Claim 15** (`scripts/build-loop.sh:1274-1276`): a relock that fails after the unlock leaves the worktree unlocked; "leaving no branch or worktree it made" does not cover that.
- **Claim 19** (`scripts/build-loop.sh:1322`): the prompt's floor list omits non-own working docs and reviews, docs/thoughts, the constraints doc and below-name paths, and the floor applies only to self-merge briefs.
- **Claim 21b** (`scripts/build-loop.sh:1333`): add "no blank at either end" to REASON.
- **Claim 26b** (aff39758 Notes): any reason ending " UTC TIME" can be stolen, not only a build-loop one.

### Unverifiable
- **Claim 21c** (`scripts/build-loop.sh:1332`): blocked-body grammar; needs U3b's `--marker`. Against D11 the prompt's "no line starting" is narrower than "after blanks, `>` and list markers".
- **Claim 25b** (525f947a): "Mutation-checked" names no mutations; of three run here, the empty-old-value one survives.

## Goal-Alignment Note

The PR's goal (shared brief): --start/--prompt dispatch with the documented gates, "leave nothing behind on a refusal", and a prompt carrying the plan's required content. Most of the documentation matches the code, checked by execution; every "Prompt content" item is present (Claim 23). Two documentation mismatches bear on the goal. Claim 8b is the more consequential: the re-dispatch path most likely after an orchestrator restart (a dead loop's locked worktree whose directory is gone) is the one the header says is refused, and with --steal it hands a loop a nonexistent DIR. Claim 4 affects any caller that parses the first word of the output. Out of this skill's scope, recorded for the other critics without a verdict: in p5, after --start put the loop's worktree at the default `.claude/wt-STEM` inside the main worktree, a self-merge `--check` run **from the main checkout** refused with "the checkout holds an untracked nested repository" (`checkout_gate`, `scripts/build-loop.sh:941-943`; `$CFC/p5.log`). D13 has the orchestrator run from its own fresh worktree, which would not contain the loop's, so this matters only if the gate is ever run from the main checkout. No Incorrect verdict here is a fabricated symbol or API, so `docs/reviews/hallucination-patterns.md` is unchanged.
